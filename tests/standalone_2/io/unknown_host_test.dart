// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests socket exceptions.

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void unknownHostTest() {
  asyncStart();
  Socket
      .connect("hede.hule.hest", 1234)
      .then((socket) => Expect.fail("Connection completed"))
      .catchError((e) => asyncEnd(), test: (e) => e is SocketException);
}

main() {
  asyncStart();
  unknownHostTest();
  asyncEnd();
}
