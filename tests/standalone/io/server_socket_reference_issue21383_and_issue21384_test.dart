// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:async_helper/async_helper.dart';


testBothListen() {
  asyncStart();
  ServerSocket.bind('127.0.0.1', 0).then((mainServer) {
    mainServer.reference.create().then((refServer) {
      refServer.listen((_) {});
      mainServer.listen((_) {});
      Timer.run(() {
        mainServer.close();
        refServer.close();
        asyncEnd();
      });
    });
  });
}

testRefServerListen() {
  asyncStart();
  ServerSocket.bind('127.0.0.1', 0).then((mainServer) {
    mainServer.reference.create().then((refServer) {
      refServer.listen((_) {});
      Timer.run(() {
        mainServer.close();
        refServer.close();
        asyncEnd();
      });
    });
  });
}

testMainServerListen() {
  asyncStart();
  ServerSocket.bind('127.0.0.1', 0).then((mainServer) {
    mainServer.reference.create().then((refServer) {
      mainServer.listen((_) {});
      Timer.run(() {
        mainServer.close();
        refServer.close();
        asyncEnd();
      });
    });
  });
}

testNoneListen() {
  asyncStart();
  ServerSocket.bind('127.0.0.1', 0).then((mainServer) {
    mainServer.reference.create().then((refServer) {
      Timer.run(() {
        mainServer.close();
        refServer.close();
        asyncEnd();
      });
    });
  });
}

main() {
  testNoneListen();
  testMainServerListen();
  testRefServerListen();
  testBothListen();
}

