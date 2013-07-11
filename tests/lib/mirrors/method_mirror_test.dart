// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";

import "../../../pkg/unittest/lib/unittest.dart";

String _symbolToString(Symbol sym) {
  return MirrorSystem.getName(sym);
}

doNothing42() {}

main() {
  // Regression test for http://www.dartbug.com/6335
  test("NamedMethodName", () {
    var closureMirror = reflect(doNothing42);
    expect(_symbolToString(closureMirror.function.simpleName), "doNothing42");
  });
}
