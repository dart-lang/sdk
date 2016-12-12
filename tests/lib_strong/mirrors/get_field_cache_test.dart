// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@MirrorsUsed(targets: const ["A", "B"])
import 'dart:mirrors';

import 'package:expect/expect.dart';

class A {
  toString() => "A";
}

class B {
  int x = 99;
  toString() => "B";
}

void main() {
  var a = new A();
  var am = reflect(a);
  for (int i = 0; i < 10; i++) {
    // Adds a probe function on the symbol.
    am.getField(#toString);
  }
  var b = new B();
  var bm = reflect(b);
  for (int i = 0; i < 10; i++) {
    // Adds a field-cache on the mirror.
    bm.getField(#x);
  }
  // There is a cache now, but the cache should not contain 'toString' from
  // JavaScript's Object.prototype.
  var toString = bm.getField(#toString).reflectee;
  Expect.equals("B", toString());
}
