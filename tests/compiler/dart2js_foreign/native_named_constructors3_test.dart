// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Hidden native class with factory constructors and NO static methods.
// Regression test.


@native("*A")
class A  {

  // No static methods in this class.

  factory A(int len) => makeA(len);

  factory A.fromString(String s)  => makeA(s.length);

  @native(@'return makeA(a+b);')
  factory A.nativeConstructor(int a, int b);

  @native('return this._x;')
  foo();
}

@native makeA(v);

@native("""
// This code is all inside 'setup' and so not accesible from the global scope.
function A(arg) { this._x = arg; }
makeA = function(arg) { return new A(arg); }
""")
void setup();

main() {
  setup();
  var a1 = new A(100);
  var a2 = new A.fromString('Hello');
  var a3 = new A.nativeConstructor(100, 2);

  Expect.equals(100, a1.foo());
  Expect.equals(5, a2.foo());
  Expect.equals(102, a3.foo());
}
