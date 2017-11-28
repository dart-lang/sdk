// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import "package:expect/expect.dart";

main() {
  var ps = ProcessSignal.SIGINT.watch().listen((signal) {
    Expect.fail("Unreachable");
  });
  throw "Death"; //# 01: runtime error
  ps.cancel();
}
