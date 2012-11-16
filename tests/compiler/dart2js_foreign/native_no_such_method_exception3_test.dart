// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_metadata.dart';

@Native("*A")
class A {
  bar() => 42;
}

@Native("*B")
class B {
  foo() => 42;
}

class C {
  static create() => new C();
  noSuchMethod(x, y) => "$x:$y";
}

@native makeA();

@Native("""
  function A() {}
  makeA = function() { return new A; }
""")
setup();

main() {
  setup();
  var a = makeA();
  a.bar();
  var exception;
  try {
    a.foo();
  } on NoSuchMethodError catch (e) {
    exception = e;
  }
  Expect.isNotNull(exception);
  var c = C.create();
  Expect.equals("foo:[1, 2]", c.foo(1, 2));
  Expect.equals("foo:[3, 4, 5]", c.foo(3, 4, 5));
}
