// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';
import "package:expect/expect.dart";

main(List<String> args, message) {
  var sendPort1 = args[0] as SendPort;
  var sendPort2 = args[1] as SendPort;
  sendPort2.send(sendPort1);
}
