// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

import 'dart:async';
import 'dart:io';
import "package:expect/expect.dart";

const int NUM_SERVERS = 10;

void main(List<String> args) {
  if (args.isEmpty) {
    for (int i = 0; i < NUM_SERVERS; ++i) {
      makeServer().then((server) {
        runClientProcess(server.port).then((_) => server.close());
      });
    }
  } else if (args[0] == '--client') {
    int port = int.parse(args[1]);
    runClient(port);
  } else {
    Expect.fail('Unknown arguments to raw_socket_cross_process_test.dart');
  }
}

Future makeServer() {
  return RawServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0).then((server) {
    server.listen((connection) {
      connection.writeEventsEnabled = false;
      connection.listen((event) {
        switch (event) {
          case RawSocketEvent.READ:
            Expect.fail("No read event expected");
            break;
          case RawSocketEvent.READ_CLOSED:
            connection.shutdown(SocketDirection.SEND);
            break;
          case RawSocketEvent.WRITE:
            Expect.fail("No write event expected");
            break;
        }
      });
    });
    return server;
  });
}

Future runClientProcess(int port) {
  return Process
      .run(
          Platform.executable,
          []
            ..addAll(Platform.executableArguments)
            ..add(Platform.script.toFilePath())
            ..add('--client')
            ..add(port.toString()))
      .then((ProcessResult result) {
    if (result.exitCode != 0 || !result.stdout.contains('SUCCESS')) {
      print("Client failed, exit code ${result.exitCode}");
      print("  stdout:");
      print(result.stdout);
      print("  stderr:");
      print(result.stderr);
      Expect.fail('Client subprocess exit code: ${result.exitCode}');
    }
  });
}

runClient(int port) {
  RawSocket.connect(InternetAddress.LOOPBACK_IP_V4, port).then((connection) {
    connection.listen((_) {}, onDone: () => print('SUCCESS'));
    connection.shutdown(SocketDirection.SEND);
  });
}
