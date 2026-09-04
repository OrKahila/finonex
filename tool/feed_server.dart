import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

class Instrument {
  final String symbol;
  final String name;
  final int decimals;
  final int rate;
  double price;
  double prevPrice;
  int lastTs = 0;

  Instrument(this.symbol, this.name, this.decimals, double base, this.rate)
      : price = base,
        prevPrice = base;
}

class Conn {
  final HttpResponse res;
  final String token;
  StreamSubscription<String>? sub;
  final List<Timer> timers = [];
  bool stalled = false;
  bool closed = false;

  Conn(this.res, this.token);
}

class FeedServer {
  final int port;
  final bool calm;
  final Random rng;

  int seq = 0;
  final List<(int, String)> buffer = [];
  final StreamController<String> feed = StreamController.broadcast();
  final Map<String, DateTime> tokens = {};
  final Set<Conn> conns = {};

  late final List<Instrument> instruments = [
    Instrument('EURUSD', 'Euro / US Dollar', 5, 1.0812, 0),
    Instrument('GBPUSD', 'British Pound / US Dollar', 5, 1.2705, 0),
    Instrument('USDJPY', 'US Dollar / Japanese Yen', 3, 157.42, 1),
    Instrument('USDCHF', 'US Dollar / Swiss Franc', 5, 0.8931, 1),
    Instrument('AUDUSD', 'Australian Dollar / US Dollar', 5, 0.6642, 1),
    Instrument('USDCAD', 'US Dollar / Canadian Dollar', 5, 1.3728, 1),
    Instrument('NZDUSD', 'New Zealand Dollar / US Dollar', 5, 0.6091, 1),
    Instrument('EURGBP', 'Euro / British Pound', 5, 0.8511, 1),
    Instrument('EURJPY', 'Euro / Japanese Yen', 3, 170.21, 1),
    Instrument('GBPJPY', 'British Pound / Japanese Yen', 3, 199.98, 1),
    Instrument('EURCHF', 'Euro / Swiss Franc', 5, 0.9656, 2),
    Instrument('AUDJPY', 'Australian Dollar / Japanese Yen', 3, 104.56, 1),
    Instrument('CADJPY', 'Canadian Dollar / Japanese Yen', 3, 114.68, 2),
    Instrument('CHFJPY', 'Swiss Franc / Japanese Yen', 3, 176.27, 2),
    Instrument('EURAUD', 'Euro / Australian Dollar', 5, 1.6277, 2),
    Instrument('GBPAUD', 'British Pound / Australian Dollar', 5, 1.9127, 2),
    Instrument('XAUUSD', 'Gold', 2, 2418.50, 0),
    Instrument('XAGUSD', 'Silver', 3, 30.84, 1),
    Instrument('XPTUSD', 'Platinum', 2, 968.40, 2),
    Instrument('WTIUSD', 'Crude Oil WTI', 2, 82.14, 1),
    Instrument('BRNUSD', 'Crude Oil Brent', 2, 85.02, 1),
    Instrument('NATGAS', 'Natural Gas', 3, 2.618, 2),
    Instrument('US500', 'S&P 500', 1, 5588.2, 0),
    Instrument('US30', 'Dow Jones 30', 1, 40211.0, 1),
    Instrument('NAS100', 'Nasdaq 100', 1, 20386.5, 1),
    Instrument('GER40', 'DAX 40', 1, 18748.2, 1),
    Instrument('UK100', 'FTSE 100', 1, 8252.9, 2),
    Instrument('JPN225', 'Nikkei 225', 0, 41190.0, 2),
    Instrument('FRA40', 'CAC 40', 1, 7724.3, 2),
    Instrument('BTCUSD', 'Bitcoin', 2, 64230.0, 0),
    Instrument('ETHUSD', 'Ethereum', 2, 3417.5, 1),
    Instrument('SOLUSD', 'Solana', 3, 161.24, 1),
    Instrument('XRPUSD', 'Ripple', 5, 0.5731, 1),
    Instrument('AAPL', 'Apple Inc.', 2, 234.82, 2),
    Instrument('MSFT', 'Microsoft Corp.', 2, 453.55, 2),
    Instrument('AMZN', 'Amazon.com Inc.', 2, 194.49, 2),
    Instrument('GOOGL', 'Alphabet Inc.', 2, 183.66, 2),
    Instrument('TSLA', 'Tesla Inc.', 2, 249.23, 2),
    Instrument('NVDA', 'NVIDIA Corp.', 2, 129.24, 2),
    Instrument('META', 'Meta Platforms Inc.', 2, 494.17, 2),
  ];

  FeedServer(this.port, int seed, this.calm) : rng = Random(seed);

  Future<void> start() async {
    Timer.periodic(const Duration(milliseconds: 100), (_) => tickAll());
    if (!calm) scheduleGlobalChaos();
    final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    stdout.writeln('feed_server listening on :$port  (chaos ${calm ? 'OFF' : 'ON'})');
    await for (final req in server) {
      handle(req);
    }
  }

  void tickAll() {
    for (final inst in instruments) {
      final p = switch (inst.rate) { 0 => 0.8, 1 => 0.12, _ => 0.02 };
      if (rng.nextDouble() < p) tick(inst);
    }
  }

  void tick(Instrument inst) {
    inst.prevPrice = inst.price;
    inst.price *= 1 + (rng.nextDouble() * 2 - 1) * 0.0006;
    inst.lastTs = DateTime.now().millisecondsSinceEpoch;
    emit(inst, inst.price, inst.lastTs);
  }

  void emit(Instrument inst, double mid, int ts) {
    final spread = mid * 0.00012 + 2 * pow(10, -inst.decimals);
    final bid = double.parse((mid - spread / 2).toStringAsFixed(inst.decimals));
    final ask = double.parse((mid + spread / 2).toStringAsFixed(inst.decimals));
    final id = ++seq;
    final data = jsonEncode({'s': inst.symbol, 'b': bid, 'a': ask, 'ts': ts});
    final text = 'id: $id\nevent: tick\ndata: $data\n\n';
    buffer.add((id, text));
    if (buffer.length > 1000) buffer.removeAt(0);
    feed.add(text);
  }

  void scheduleGlobalChaos() {
    Timer(Duration(seconds: 6 + rng.nextInt(9)), () {
      final roll = rng.nextInt(11);
      if (roll < 3) {
        burst();
      } else if (roll < 6) {
        duplicate();
      } else if (roll < 9) {
        outOfOrder();
      } else {
        feed.add('data: ###garbage-not-json###\n\n');
      }
      scheduleGlobalChaos();
    });
  }

  void burst() {
    final hot = instruments.where((i) => i.rate == 0).toList();
    for (var i = 0; i < 220; i++) {
      tick(hot[rng.nextInt(hot.length)]);
    }
  }

  void duplicate() {
    if (buffer.isEmpty) return;
    feed.add(buffer[rng.nextInt(buffer.length)].$2);
  }

  void outOfOrder() {
    final hot = instruments.where((i) => i.rate == 0).toList();
    final inst = hot[rng.nextInt(hot.length)];
    if (inst.lastTs == 0) return;
    emit(inst, inst.prevPrice, inst.lastTs - 3000);
  }

  void handle(HttpRequest req) {
    try {
      switch ((req.method, req.uri.path)) {
        case ('POST', '/login'):
          login(req);
        case ('GET', '/instruments'):
          if (authed(req)) listInstruments(req);
        case ('GET', '/stream'):
          if (authed(req)) stream(req);
        default:
          req.response
            ..statusCode = HttpStatus.notFound
            ..close();
      }
    } catch (_) {
      try {
        req.response
          ..statusCode = HttpStatus.internalServerError
          ..close();
      } catch (_) {}
    }
  }

  Future<void> login(HttpRequest req) async {
    try {
      Object? body;
      try {
        body = jsonDecode(await utf8.decodeStream(req));
      } catch (_) {
        body = null;
      }
      if (body is! Map || body['username'] != 'trader' || body['password'] != 'password123') {
        req.response
          ..statusCode = HttpStatus.unauthorized
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'error': 'invalid credentials'}))
          ..close();
        return;
      }
      final token = List.generate(32, (_) => rng.nextInt(16).toRadixString(16)).join();
      tokens[token] = DateTime.now().add(const Duration(seconds: 60));
      req.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'token': token, 'expiresIn': 60}))
        ..close();
    } catch (_) {
      try {
        req.response
          ..statusCode = HttpStatus.internalServerError
          ..close();
      } catch (_) {}
    }
  }

  String? tokenOf(HttpRequest req) {
    final h = req.headers.value(HttpHeaders.authorizationHeader);
    if (h == null || !h.startsWith('Bearer ')) return null;
    return h.substring(7);
  }

  bool tokenValid(String? t) =>
      t != null && tokens[t] != null && tokens[t]!.isAfter(DateTime.now());

  bool authed(HttpRequest req) {
    if (tokenValid(tokenOf(req))) return true;
    req.response
      ..statusCode = HttpStatus.unauthorized
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'error': 'unauthorized'}))
      ..close();
    return false;
  }

  void listInstruments(HttpRequest req) {
    req.response
      ..headers.contentType = ContentType.json
      ..write(jsonEncode([
        for (final i in instruments)
          {'symbol': i.symbol, 'name': i.name, 'decimals': i.decimals}
      ]))
      ..close();
  }

  void stream(HttpRequest req) {
    final res = req.response;
    res.headers.contentType = ContentType('text', 'event-stream', charset: 'utf-8');
    res.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
    res.bufferOutput = false;

    final conn = Conn(res, tokenOf(req)!);
    conns.add(conn);
    res.done.then((_) => close(conn), onError: (_) => close(conn));

    final lastIdHeader = req.headers.value('Last-Event-ID');
    final lastId = lastIdHeader == null ? null : int.tryParse(lastIdHeader);
    if (lastId != null) {
      if (buffer.isNotEmpty && lastId >= buffer.first.$1 - 1) {
        for (final (id, text) in buffer) {
          if (id > lastId) write(conn, text);
        }
      } else {
        final resumeFrom = buffer.isEmpty ? seq : buffer.first.$1;
        write(conn, 'event: gap\ndata: ${jsonEncode({'resumeFrom': resumeFrom})}\n\n');
      }
    }

    conn.sub = feed.stream.listen((text) => write(conn, text));

    conn.timers.add(Timer.periodic(const Duration(seconds: 5), (_) {
      write(conn, ': ping\n\n');
    }));
    conn.timers.add(Timer.periodic(const Duration(seconds: 1), (_) {
      if (!tokenValid(conn.token)) close(conn);
    }));

    if (!calm) {
      conn.timers.add(Timer(Duration(seconds: 25 + rng.nextInt(31)), () => close(conn)));
      conn.timers.add(Timer(Duration(seconds: 15 + rng.nextInt(31)), () {
        conn.stalled = true;
        conn.timers.add(Timer(const Duration(seconds: 25), () => conn.stalled = false));
      }));
    }
  }

  void write(Conn conn, String text) {
    if (conn.closed || conn.stalled) return;
    try {
      conn.res.write(text);
    } catch (_) {
      close(conn);
    }
  }

  void close(Conn conn) {
    if (conn.closed) return;
    conn.closed = true;
    conns.remove(conn);
    conn.sub?.cancel();
    for (final t in conn.timers) {
      t.cancel();
    }
    try {
      conn.res.close();
    } catch (_) {}
  }
}

void main(List<String> args) {
  var port = 8080;
  var seed = 42;
  var calm = false;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--port':
        port = int.parse(args[++i]);
      case '--seed':
        seed = int.parse(args[++i]);
      case '--calm':
        calm = true;
    }
  }
  FeedServer(port, seed, calm).start();
}
