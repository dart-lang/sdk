// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The error should be reported on the field, not the constructor.

class A {
  late final int foo = 42;
  const A();
}

class B {
  late final int foo = 42;
  late final String bar = "foobar";
  const B();
}

class C {
  late final int foo = 42;
  const C();
  const C.another();
}

class D {
  late final int foo = 42;
  late final String bar = "foobar";
  const D();
  const D.another();
}

main() {}
