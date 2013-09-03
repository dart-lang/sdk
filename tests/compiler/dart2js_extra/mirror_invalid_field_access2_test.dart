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

main() {
  var c = new C();

  c.bar = 1;
  var local = c.bar;

  var mirror = reflect(c);
  Expect.equals(1, mirror.setField(const Symbol('foo'), 1).reflectee);
  Expect.equals(1, mirror.getField(const Symbol('foo')).reflectee);
  Expect.throws(() => mirror.setField(const Symbol('bar'),  2),
                (e) => e is NoSuchMethodError);
  Expect.throws(() => mirror.getField(const Symbol('bar')),
                (e) => e is NoSuchMethodError);
}
