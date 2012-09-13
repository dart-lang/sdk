// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Hidden native class wwith named constructors and static methods.


class A native "*A" {

  factory A(int len) => _construct(len);

  factory A.fromString(String s)  => _construct(s.length);

  factory A.nativeConstructor(int a, int b) native r'return makeA(a+b);';

  static A _construct(v) { return makeA(v); }

  foo() native 'return this._x;';
}

makeA(v) native;

void setup() native """
// This code is all inside 'setup' and so not accesible from the global scope.
function A(arg) { this._x = arg; }
makeA = function(arg) { return new A(arg); }
""";

main() {
  setup();
  var a1 = new A(100);
  var a2 = new A.fromString('Hello');
  var a3 = new A.nativeConstructor(100, 2);

  Expect.equals(100, a1.foo());
  Expect.equals(5, a2.foo());
  Expect.equals(102, a3.foo());
}
