// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to not resolve instance
// fields when a class is only instantiated through mirrors.

library lib;

import "package:expect/expect.dart";

@MirrorsUsed(targets: "lib")
import 'dart:mirrors';

class A {
  static const int _STATE_INITIAL = 0;
  int _state = _STATE_INITIAL;
  A();
}

main() {
  var mirrors = currentMirrorSystem();
  var classMirror = reflectClass(A);
  var instanceMirror = classMirror.newInstance(Symbol.empty, []);
  Expect.equals(A._STATE_INITIAL, instanceMirror.reflectee._state);
}
