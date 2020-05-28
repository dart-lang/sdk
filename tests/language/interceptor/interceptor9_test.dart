// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js whose codegen in some cases did not take is
// tests into account when computing the set of classes for interceptors.
// See http://dartbug.com/17325

import "package:expect/expect.dart";
import "dart:typed_data";

confuse(x, [y = null]) => new DateTime.now().day == 42 ? y : x;

boom() {
  var x = confuse(new Uint8List(22), "");
  Expect.isTrue(x is Uint8List);
  x.startsWith("a");
  x.endsWith("u");
}

main() {
  try {
    var f;
    if (confuse(true)) {
      // prevent inlining
      f = boom;
    }
    f();
  } catch (e) {
    if (e is ExpectException) throw e;
  }
}
