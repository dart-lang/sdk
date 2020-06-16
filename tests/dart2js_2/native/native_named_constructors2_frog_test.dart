// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "native_testing.dart";

// Native class with named constructors and static methods.

@Native("A")
class A {
  factory A(int len) => _construct(len);

  factory A.fromString(String s) => _construct(s.length);

  factory A.nativeConstructor() {
    return JS('A|Null', 'makeA(102)');
  }

  static A _construct(v) {
    return makeA(v);
  }

  foo() native;
}

makeA(v) native;

void setup() {
  JS('', r"""
(function(){
  // This code is inside 'setup' and so not accessible from the global scope.
  function A(arg) { this._x = arg; }
  A.prototype.foo = function() { return this._x; };
  makeA = function(arg) { return new A(arg); };
  self.nativeConstructor(A);
})()""");
}

main() {
  nativeTesting();
  setup();
  var a1 = new A(100);
  var a2 = new A.fromString('Hello');
  var a3 = new A.nativeConstructor();

  Expect.equals(100, a1.foo());
  Expect.equals(5, a2.foo());
  Expect.equals(102, a3.foo());
}
