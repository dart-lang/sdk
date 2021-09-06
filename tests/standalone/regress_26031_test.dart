// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

import 'dart:io';
import 'dart:isolate';

import "package:expect/expect.dart";

void checkResolvedExecutable(Object reObj) {
  String re = reObj as String;
  Expect.equals(Platform.resolvedExecutable, re);
}

main() {
  var exitPort = new ReceivePort();
  Isolate.spawn(checkResolvedExecutable, Platform.resolvedExecutable,
      onExit: exitPort.sendPort);
  exitPort.listen((_) => exitPort.close());
}
