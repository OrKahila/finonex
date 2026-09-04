import 'dart:convert';

import 'package:finonex/data/feed/sse/sse_message.dart';
import 'package:finonex/data/feed/sse/sse_parser.dart';
import 'package:finonex/data/feed/tick.dart';
import 'package:finonex/data/feed/tick_codec.dart';
import 'package:flutter_test/flutter_test.dart';

/// Feeds lines in and collects whatever comes out.
List<SseMessage> run(SseParser parser, List<String> lines) {
  return <SseMessage>[
    for (final String line in lines)
      if (parser.addLine(line) case final SseMessage message) message,
  ];
}

void main() {
  group('SseParser', () {
    test('parses the server\'s tick frame', () {
      final SseParser parser = SseParser();

      final List<SseMessage> messages = run(parser, <String>[
        'id: 1042',
        'event: tick',
        'data: {"s":"EURUSD","b":1.08123,"a":1.08141,"ts":1752912000123}',
        '',
      ]);

      expect(messages, <SseMessage>[
        const SseEvent(
          id: 1042,
          event: 'tick',
          data: '{"s":"EURUSD","b":1.08123,"a":1.08141,"ts":1752912000123}',
        ),
      ]);
      expect(parser.lastEventId, 1042);
    });

    test('heartbeat comments come through as comments, not events', () {
      final SseParser parser = SseParser();

      expect(run(parser, <String>[': ping', '']), <SseMessage>[
        const SseComment('ping'),
      ]);
    });

    test('an event is only dispatched on the blank line', () {
      final SseParser parser = SseParser();

      expect(parser.addLine('event: tick'), isNull);
      expect(parser.addLine('data: {}'), isNull);
      expect(parser.addLine(''), isA<SseEvent>());
    });

    test('multiple data lines join with newlines, trailing one stripped', () {
      final SseParser parser = SseParser();

      final List<SseMessage> messages =
          run(parser, <String>['data: one', 'data: two', '']);

      expect((messages.single as SseEvent).data, 'one\ntwo');
    });

    test('exactly one space after the colon is stripped', () {
      final SseParser parser = SseParser();

      final List<SseMessage> messages = run(parser, <String>['data:  padded', '']);

      expect((messages.single as SseEvent).data, ' padded');
    });

    test('a field with no colon is treated as an empty value', () {
      final SseParser parser = SseParser();

      final List<SseMessage> messages = run(parser, <String>['data', '']);

      expect((messages.single as SseEvent).data, '');
    });

    test('missing event field defaults to message', () {
      final SseParser parser = SseParser();

      final List<SseMessage> messages =
          run(parser, <String>['data: ###garbage-not-json###', '']);

      expect((messages.single as SseEvent).event, 'message');
    });

    test('id persists across events that omit it', () {
      final SseParser parser = SseParser();

      // The server omits `id` on gap notices and on malformed lines. Per spec
      // the last id stays in force, which is what Last-Event-ID needs.
      final List<SseMessage> messages = run(parser, <String>[
        'id: 7',
        'event: tick',
        'data: {}',
        '',
        'event: gap',
        r'data: {"resumeFrom":900}',
        '',
      ]);

      expect((messages[0] as SseEvent).id, 7);
      expect((messages[1] as SseEvent).id, 7);
      expect((messages[1] as SseEvent).event, 'gap');
    });

    test('an unparseable id is ignored rather than clearing the last one', () {
      final SseParser parser = SseParser();

      run(parser, <String>['id: 5', 'data: a', '']);
      final List<SseMessage> messages =
          run(parser, <String>['id: not-a-number', 'data: b', '']);

      expect((messages.single as SseEvent).id, 5);
    });

    test('a blank line with nothing buffered dispatches nothing', () {
      final SseParser parser = SseParser();

      expect(run(parser, <String>['', '', '']), isEmpty);
    });

    test('an event type left dangling by a blank line does not leak', () {
      final SseParser parser = SseParser();

      run(parser, <String>['event: tick', '']);
      final List<SseMessage> messages = run(parser, <String>['data: x', '']);

      expect((messages.single as SseEvent).event, 'message');
    });
  });

  group('decodeSseStream', () {
    test('reassembles events split across arbitrary chunk boundaries', () async {
      const String frame =
          'id: 1\nevent: tick\ndata: {"s":"EURUSD","b":1.0,"a":1.1,"ts":5}\n\n'
          ': ping\n\n'
          'id: 2\nevent: tick\ndata: {"s":"GBPUSD","b":1.2,"a":1.3,"ts":6}\n\n';

      // One byte at a time: the worst boundary case a socket can hand us.
      final Stream<List<int>> bytes = Stream<List<int>>.fromIterable(
        utf8.encode(frame).map((int b) => <int>[b]),
      );

      final List<SseMessage> messages = await decodeSseStream(bytes).toList();

      expect(messages.whereType<SseEvent>().length, 2);
      expect(messages.whereType<SseComment>().length, 1);
      expect((messages.last as SseEvent).id, 2);
    });

    test('handles CRLF line endings', () async {
      final Stream<List<int>> bytes = Stream<List<int>>.value(
        utf8.encode('id: 3\r\nevent: tick\r\ndata: {"s":"X"}\r\n\r\n'),
      );

      final List<SseMessage> messages = await decodeSseStream(bytes).toList();

      expect((messages.single as SseEvent).id, 3);
    });

    test('survives a multi-byte character split across chunks', () async {
      final List<int> encoded = utf8.encode('data: café\n\n');
      // Split in the middle of the two-byte 'é'.
      final int cut = encoded.length - 3;

      final Stream<List<int>> bytes = Stream<List<int>>.fromIterable(
        <List<int>>[encoded.sublist(0, cut), encoded.sublist(cut)],
      );

      final List<SseMessage> messages = await decodeSseStream(bytes).toList();

      expect((messages.single as SseEvent).data, 'café');
    });
  });

  group('decodeTick', () {
    Tick? decode(String data, {String event = 'tick', int? id}) =>
        decodeTick(SseEvent(event: event, data: data, id: id));

    test('decodes a well-formed tick', () {
      final Tick? tick = decode(
        '{"s":"EURUSD","b":1.08123,"a":1.08141,"ts":1752912000123}',
        id: 42,
      );

      expect(
        tick,
        const Tick(
          symbol: 'EURUSD',
          bid: 1.08123,
          ask: 1.08141,
          ts: 1752912000123,
          eventId: 42,
        ),
      );
    });

    test('the server\'s garbage payload yields null, not an exception', () {
      // Exactly what the server emits: no event field, unparseable data.
      expect(decode('###garbage-not-json###', event: 'message'), isNull);
      expect(decode('###garbage-not-json###'), isNull);
    });

    test('non-tick events are not ticks', () {
      expect(decode(r'{"resumeFrom":900}', event: 'gap'), isNull);
    });

    test('rejects payloads with missing or wrongly typed fields', () {
      expect(decode(r'{"s":"EURUSD","b":1.0,"a":1.1}'), isNull);
      expect(decode(r'{"b":1.0,"a":1.1,"ts":5}'), isNull);
      expect(decode(r'{"s":"","b":1.0,"a":1.1,"ts":5}'), isNull);
      expect(decode(r'{"s":"EURUSD","b":"1.0","a":1.1,"ts":5}'), isNull);
      expect(decode('[1,2,3]'), isNull);
      expect(decode('null'), isNull);
    });

    test('accepts integer-valued prices', () {
      // JPN225 has 0 decimals, so whole numbers do show up on the wire.
      expect(decode(r'{"s":"JPN225","b":41190,"a":41192,"ts":5}')?.bid, 41190.0);
    });

    test('isGapEvent recognises the resume notice', () {
      expect(isGapEvent(const SseEvent(event: 'gap', data: '{}')), isTrue);
      expect(isGapEvent(const SseEvent(event: 'tick', data: '{}')), isFalse);
    });
  });
}
