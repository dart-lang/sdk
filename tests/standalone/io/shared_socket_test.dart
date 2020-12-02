// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:http/http.dart' as http;

void main() async {
  // Start a server to obtain a randomly assigned, free port.
  final mainServer = await HttpServer.bind('::1', 0, shared: true);
  final sharedPort = mainServer.port;

  final workers =
      List<ServerWorker>.generate(4, (i) => ServerWorker(i, sharedPort));
  await Future.wait(workers.map((w) => w.start()));
  mainServer.close();

  await Future.delayed(Duration(seconds: 1));
  // spawn client isolate
  final clientisolate = await Isolate.spawn(client, sharedPort);
  // Wait for 20 secs. It used to crash within 10 seconds.
  await Future.delayed(Duration(seconds: 20));

  workers.forEach((w) {
    w.respawn = false;
    w.terminate();
  });
  print('kill client isolates');
  clientisolate.kill();
}

class ServerWorker {
  final int workerid;
  final int port;
  Isolate? _isolate;
  bool respawn = true;

  ServerWorker(this.workerid, this.port);

  Future<void> start() async {
    final onExit = ReceivePort();
    onExit.listen((_) {
      onExit.close();
      // Respawn another isolate
      if (respawn) start();
    });
    final ready = ReceivePort();
    _isolate = await Isolate.spawn(_main, [workerid, port, ready.sendPort],
        errorsAreFatal: true, onExit: onExit.sendPort);
    await ready.first;
    if (workerid == 0) terminate();
  }

  void terminate() {
    Future.delayed(Duration(seconds: 1), () {
      print('terminate ${workerid}');
      _isolate?.kill();
      _isolate = null;
    });
  }

  static _main(List args) async {
    final workerid = args[0] as int;
    final port = args[1] as int;
    final readyPort = args[2] as SendPort;

    final server = await HttpServer.bind('::1', port, shared: true);
    readyPort.send(null);
    server.listen((HttpRequest request) {
      print('from worker ${workerid}');
      final response = request.response;
      response.statusCode = HttpStatus.ok;
      response.write('server worker ${workerid}');
      response.close();
    });
  }
}

Future<String> get(String url) async {
  while (true) {
    try {
      await http.get(url);
      return '';
    } catch (err) {}
  }
}

void client(int port) async {
  while (true) {
    final futures = <Future>[];
    final numAtOnce = 16; // enough to keep the server busy
    for (int i = 0; i < numAtOnce; ++i) {
      futures.add(get('http://localhost:$port').then((_) {}));
    }
    await Future.wait(futures);
  }
}
