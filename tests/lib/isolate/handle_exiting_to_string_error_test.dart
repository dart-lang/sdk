// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library handle_throwing_to_string_error_test;

import "dart:async";
import "dart:isolate";

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

class ExitingToStringError {
  @override
  String toString() => Isolate.exit();
}

void isolateMain() {
  throw ExitingToStringError();
}

void main() async {
  asyncStart();
  final errorPort = ReceivePort();
  final exitPort = ReceivePort();
  Isolate.spawn(
    (_) => isolateMain(),
    null,
    onError: errorPort.sendPort,
    onExit: exitPort.sendPort,
  );

  exitPort.listen((_) {
    exitPort.close();

    // Give the (hopefully inexistent) error message time to arrive.
    Timer(Duration(seconds: 1), () {
      errorPort.close();
    });
  });

  Expect.isTrue(await errorPort.isEmpty);

  asyncEnd();
}
