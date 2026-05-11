import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:expect/expect.dart';

Future<void> main() async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final got = Completer<List<int>>();

  server.listen((sock) {
    got.complete(sock.expand((v) => v).toList());
  });

  final c = RawSynchronousSocket.connectSync(
    InternetAddress.loopbackIPv4,
    server.port,
  );

  final buf = Uint8List.fromList(List.generate(16, (i) => i));

  c.writeFromSync(buf, 5, 10);
  c.closeSync();

  final received = await got.future.timeout(const Duration(seconds: 5));
  await server.close();

  Expect.equals(5, received.length);
  Expect.listEquals(<int>[5, 6, 7, 8, 9], received);
}
