// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors" show reflect;
import "package:expect/expect.dart";

// Testing InstanceMirror.delegate method; test of issue 7227.

var reachedSetX = 0;
var reachedGetX = 0;
var reachedM = 0;

class A {
  set x(val) {
    reachedSetX = val;
  }

  get x {
    reachedGetX = 1;
  }

  m() {
    reachedM = 1;
  }
}

class B {
  final a = new A();
  noSuchMethod(mirror) => reflect(a).delegate(mirror);
}

main() {
  dynamic b = new B();
  b.x = 10;
  Expect.equals(10, reachedSetX);
  b.x;
  Expect.equals(1, reachedGetX);
  b.m();
  Expect.equals(1, reachedM);
}
