// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we cannot reflect on elements not covered by the `MirrorsUsed`
// annotation.

library test;

@MirrorsUsed(targets: 'C.foo')
import 'dart:mirrors';

import 'package:expect/expect.dart';

class C {
  var foo;
  var bar;
}

class D {
  get bar {}
  set bar(x) {}
}

int inscrutable(int x) => x == 0 ? 0 : x | inscrutable(x & (x - 1));

main() {
  var c = inscrutable(1) == 1 ? new C() : new D();

  c.bar = 1;
  var local = c.bar;

  var mirror = reflect(c);
  Expect.equals(1, mirror.setField(const Symbol('foo'), 1).reflectee);
  Expect.equals(1, mirror.getField(const Symbol('foo')).reflectee);
  Expect.throws(() => mirror.setField(const Symbol('bar'),  2),
                (e) => e is UnsupportedError);
  Expect.throws(() => mirror.getField(const Symbol('bar')),
                (e) => e is UnsupportedError);
}
