// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Helper server program for socket_sigpipe_test.dart

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";

main() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    print(server.port);
    server.listen((request) {
      WebSocketTransformer.upgrade(request).then((websocket) async {
        websocket.add('bar');
        await websocket.close();
        await server.close();
        print('closed');
      });
    });
  });
}
