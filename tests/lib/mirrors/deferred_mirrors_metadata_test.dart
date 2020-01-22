// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@A(const B())
library main;

@B()
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import "dart:math";

import 'deferred_mirrors_metadata_lib.dart' deferred as lib1;

class A {
  final B b;
  const A(this.b);
  String toString() => "A";
}

class B {
  const B();
  String toString() => "B";
}

class C {
  const C();
  String toString() => "C";
}

class D {
  const D();
  String toString() => "D";
}

void main() {
  asyncStart();
  lib1.loadLibrary().then((_) {
    Expect.equals("ABCD", lib1.foo());
    new C();
    new D();
    asyncEnd();
  });
}
