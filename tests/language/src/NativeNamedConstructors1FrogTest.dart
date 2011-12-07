// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('X');
#native('NativeNamedConstructors1FrogTest.js');  // Defines JS constructor 'A'.

// The native class has several constructors which partition the behaviour of
// the JS constructor function into several well-typed Dart constructors.

class A native "A" {

  // factory constructors allow us to do computation ahead of the allocation.
  factory A(int len) { return _construct(len); }

  factory A.fromString(String s) {
    return _construct(s.length);  // convert string to int.
  }

  // Helper that does the actual allocation and construction.
  static A _construct(v) native @'return new A(v);';

  foo() native 'return this._x;';
}

main() {
  var a1 = new A(100);
  var a2 = new A.fromString('Hello');

  Expect.equals(100, a1.foo());
  Expect.equals(5, a2.foo());
}
