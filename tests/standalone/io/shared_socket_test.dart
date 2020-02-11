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
  final workers = List<ServerWorker>.generate(4, (i) => ServerWorker(i));
  workers.forEach((w) => w.start());
  await Future.delayed(Duration(seconds: 1));
  // spawn client isolate
  final clientisolate = await Isolate.spawn(client, 0);
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
  Isolate? _isolate;
  bool respawn = true;

  ServerWorker(this.workerid);

  Future<void> start() async {
    final onExit = ReceivePort();
    onExit.listen((_) {
      onExit.close();
      // Respawn another isolate
      if (respawn) start();
    });
    _isolate = await Isolate.spawn(_main, workerid,
        errorsAreFatal: true, onExit: onExit.sendPort);
    if (workerid == 0) terminate();
  }

  void terminate() {
    Future.delayed(Duration(seconds: 1), () {
      print('terminate ${workerid}');
      _isolate?.kill();
      _isolate = null;
    });
  }

  static _main(int workerid) async {
    bool shared = true;
    final server = await HttpServer.bind('::1', 1234, shared: shared);
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

void client(int i) async {
  while (true) {
    final futures = <Future>[];
    final numAtOnce = 16; // enough to keep the server busy
    for (int i = 0; i < numAtOnce; ++i) {
      futures.add(get('http://localhost:1234').then((_) {}));
    }
    await Future.wait(futures);
  }
}
