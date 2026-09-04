import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_native/pulse_native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> calls = <MethodCall>[];
  late MethodChannelPulseNative platform;

  void mockHandler(Future<Object?>? Function(MethodCall) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      MethodChannelPulseNative.methodChannel,
      (MethodCall call) async {
        calls.add(call);
        return handler(call);
      },
    );
  }

  setUp(() {
    calls.clear();
    platform = MethodChannelPulseNative();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            MethodChannelPulseNative.methodChannel, null);
  });

  group('secure storage channel', () {
    test('write forwards key and value', () async {
      mockHandler((_) async => null);

      await platform.writeSecret(key: 'pulse.token', value: 'abc123');

      expect(calls.single.method, 'write');
      expect(calls.single.arguments,
          <String, String>{'key': 'pulse.token', 'value': 'abc123'});
    });

    test('read returns the stored value', () async {
      mockHandler((_) async => 'abc123');

      expect(await platform.readSecret('pulse.token'), 'abc123');
      expect(calls.single.method, 'read');
    });

    test('read returns null when the key is absent', () async {
      mockHandler((_) async => null);

      expect(await platform.readSecret('missing'), isNull);
    });

    test('delete and deleteAll forward the right method names', () async {
      mockHandler((_) async => null);

      await platform.deleteSecret('pulse.token');
      await platform.deleteAllSecrets();

      expect(calls.map((MethodCall c) => c.method), <String>['delete', 'deleteAll']);
    });

    test('platform errors surface as SecureStorageException with the code',
        () async {
      mockHandler((_) async {
        throw PlatformException(code: 'keychain_error', message: 'OSStatus -25300');
      });

      await expectLater(
        platform.readSecret('pulse.token'),
        throwsA(isA<SecureStorageException>()
            .having((SecureStorageException e) => e.code, 'code', 'keychain_error')),
      );
    });

    test('a missing native implementation is reported as unavailable', () async {
      // No mock handler registered at all -> MissingPluginException.
      await expectLater(
        platform.readSecret('pulse.token'),
        throwsA(isA<SecureStorageException>()
            .having((SecureStorageException e) => e.code, 'code', 'unavailable')),
      );
    });
  });

  group('NetworkStatus', () {
    test('parses a native payload', () {
      final NetworkStatus status = NetworkStatus.fromMap(
        <Object?, Object?>{'online': true, 'interface': 'wifi', 'expensive': false},
      );

      expect(status.isOnline, isTrue);
      expect(status.interface, NetworkInterfaceKind.wifi);
      expect(status.isExpensive, isFalse);
    });

    test('unknown interface names degrade to other, missing fields to offline',
        () {
      expect(
        NetworkStatus.fromMap(<Object?, Object?>{'online': true, 'interface': 'satellite'})
            .interface,
        NetworkInterfaceKind.other,
      );
      expect(NetworkStatus.fromMap(<Object?, Object?>{}).isOnline, isFalse);
    });

    test('is compared by value so identical repeats can be ignored', () {
      expect(
        const NetworkStatus(
            isOnline: true, interface: NetworkInterfaceKind.wifi, isExpensive: false),
        const NetworkStatus(
            isOnline: true, interface: NetworkInterfaceKind.wifi, isExpensive: false),
      );
    });
  });

  group('in-memory fallback', () {
    test('round-trips and clears secrets', () async {
      final InMemoryPulseNative stub = InMemoryPulseNative();

      await stub.writeSecret(key: 'a', value: '1');
      expect(await stub.readSecret('a'), '1');

      await stub.deleteSecret('a');
      expect(await stub.readSecret('a'), isNull);

      await stub.writeSecret(key: 'b', value: '2');
      await stub.deleteAllSecrets();
      expect(await stub.readSecret('b'), isNull);
    });

    test('reports that it is not real secure storage', () {
      expect(InMemoryPulseNative().hasNativeSecureStorage, isFalse);
    });
  });
}
