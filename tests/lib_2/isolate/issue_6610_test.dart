// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-experiment=no-non-nullable --enable-isolate-groups
// VMOptions=--enable-experiment=no-non-nullable --no-enable-isolate-groups

// Testing that Isolate.spawn copies the source code of the parent isolate,
// rather than rereading the parent's source URI.
// https://github.com/dart-lang/sdk/issues/6610

// Isolate structure:
//     Root 1 -> Branch 1 -> Leaf 1
//     /
//  main
//     \
//     Root 2 -> Branch 2 -> Leaf 2

library spawn_tests;

import "dart:io";
import 'dart:isolate';
import 'package:expect/expect.dart';

void main() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    var count = 0;
    server.listen((HttpRequest request) {
      ++count;
      request.response.write("""
        // @dart = 2.9
        import 'dart:isolate';

        void main(_, SendPort port) {
          root(port);
        }

        void root(SendPort port) {
          port.send("Root ${count}");
          Isolate.spawn(branch, port);
        }

        void branch(SendPort port) {
          port.send("Branch ${count}");
          Isolate.spawn(leaf, port);
        }

        void leaf(SendPort port) {
          port.send("Leaf ${count}");
        }
      """);
      request.response.close();
    });

    ReceivePort port = new ReceivePort();
    var messageSet = Set();
    port.listen((message) {
      messageSet.add(message);
      if (messageSet.length >= 6) {
        server.close();
        port.close();
        Expect.setEquals([
          "Root 1",
          "Root 2",
          "Branch 1",
          "Branch 2",
          "Leaf 1",
          "Leaf 2",
        ], messageSet);
      }
    });

    Isolate.spawnUri(
        Uri.parse("http://127.0.0.1:${server.port}"), [], port.sendPort);
    Isolate.spawnUri(
        Uri.parse("http://127.0.0.1:${server.port}"), [], port.sendPort);
  });
}
