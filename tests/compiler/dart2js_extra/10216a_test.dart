// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests codegen of methods reached only via mixin.

class A {
  foo(x, [y]) => '$x;$y';
}

class B extends A with M1, M2, M3 {}

class M1 {}

class M2 {
  // These methods are only defined in this non-first, non-last mixin.
  plain(x) => 'P $x';
  // Check arity stubs are also available.
  bar(x, [y]) => '$y,$x';
}

class M3 {}

makeB() {
  return [new A(), new B()].last as B;
}

main() {
  // makeB enters the compilation worklist after main, so the selectors are
  // registered before the classes.
  var b = makeB();
  Expect.equals('1;2', b.foo(1, 2));
  Expect.equals('2;null', b.foo(2));
  Expect.equals('P 3', b.plain(3));
  Expect.equals('100,4', b.bar(4, 100));
  Expect.equals('null,5', b.bar(5));
}
