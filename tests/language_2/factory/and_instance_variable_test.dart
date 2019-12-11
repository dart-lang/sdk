// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

abstract class A {
  var bar;
  factory A.bar() = B.bar;

  get foo => bar;
  static get baz => bar;
  //                ^^^
  // [analyzer] COMPILE_TIME_ERROR.INSTANCE_MEMBER_ACCESS_FROM_STATIC
  // [cfe] Getter not found: 'bar'.
}

class B implements A {
  var bar;
  factory B.bar() => new C.bar();

  get foo => bar;
  static get baz => bar;
  //                ^^^
  // [analyzer] COMPILE_TIME_ERROR.INSTANCE_MEMBER_ACCESS_FROM_STATIC
  // [cfe] Getter not found: 'bar'.

  B() {}
}

class C extends B {
  C.bar() {
    bar = "foo";
  }

  static get baz => bar;
  //                ^^^
  // [analyzer] COMPILE_TIME_ERROR.INSTANCE_MEMBER_ACCESS_FROM_STATIC
  // [cfe] Getter not found: 'bar'.
}

main() {
  assert(new A.bar().foo == "foo");
  assert(new B.bar().foo == "foo");
  assert(new C.bar().foo == "foo");
  assert(new A.bar().bar == "foo");
  assert(new B.bar().bar == "foo");
  assert(new C.bar().bar == "foo");
}
