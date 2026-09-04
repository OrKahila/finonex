import Foundation
import Security

/// Thin wrapper over the Keychain's generic-password class.
///
/// One service (the app's bundle id) namespaces every item, so `deleteAll`
/// cannot touch secrets belonging to other apps or to the OS.
struct KeychainStore {
  enum StoreError: Error {
    case unexpectedStatus(OSStatus)
  }

  let service: String

  private func baseQuery(for key: String? = nil) -> [String: Any] {
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
    ]
    if let key = key {
      query[kSecAttrAccount as String] = key
    }
    return query
  }

  /// Update-then-add rather than delete-then-add: the item is never briefly
  /// absent, so a concurrent read can't observe a hole.
  func write(key: String, value: String) throws {
    guard let data = value.data(using: .utf8) else {
      throw StoreError.unexpectedStatus(errSecParam)
    }

    let attributes: [String: Any] = [
      kSecValueData as String: data,
      // Readable while the device is locked but only after the first unlock
      // since boot: the feed must survive the screen turning off.
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
    ]

    let updateStatus = SecItemUpdate(
      baseQuery(for: key) as CFDictionary,
      attributes as CFDictionary
    )

    if updateStatus == errSecSuccess { return }

    guard updateStatus == errSecItemNotFound else {
      throw StoreError.unexpectedStatus(updateStatus)
    }

    var insert = baseQuery(for: key)
    insert.merge(attributes) { current, _ in current }
    let addStatus = SecItemAdd(insert as CFDictionary, nil)
    guard addStatus == errSecSuccess else {
      throw StoreError.unexpectedStatus(addStatus)
    }
  }

  func read(key: String) throws -> String? {
    var query = baseQuery(for: key)
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess else {
      throw StoreError.unexpectedStatus(status)
    }
    guard let data = item as? Data else { return nil }
    return String(data: data, encoding: .utf8)
  }

  func delete(key: String) throws {
    let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
    // Deleting something that was never there is a success, not a failure.
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw StoreError.unexpectedStatus(status)
    }
  }

  func deleteAll() throws {
    let status = SecItemDelete(baseQuery() as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw StoreError.unexpectedStatus(status)
    }
  }
}
