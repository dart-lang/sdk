// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';
import "package:expect/expect.dart";

class FromChildIsolate {
  String toString() => 'from child isolate';
}

main(List<String> args, message) {
  var sendPort = message;
  try {
    sendPort.send(new FromChildIsolate());
  } catch (error) {
    Expect.isTrue(error is ArgumentError);
    sendPort.send("Invalid Argument(s).");
  }
}
