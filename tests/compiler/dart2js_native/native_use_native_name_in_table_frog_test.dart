// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_testing.dart';

// Test that we put native names and not Dart names into the dynamic
// dispatch table.

@Native("NativeA")
class A {
  foo() native;
}

@Native("NativeB")
class B extends A {}

A makeA() native;
B makeB() native;

void setup() {
  JS('', r"""
(function(){
  function inherits(child, parent) {
    if (child.prototype.__proto__) {
      child.prototype.__proto__ = parent.prototype;
    } else {
      function tmp() {};
      tmp.prototype = parent.prototype;
      child.prototype = new tmp();
      child.prototype.constructor = child;
    }
  }
  function NativeA() {}
  function NativeB() {}
  inherits(NativeB, NativeA);
  NativeA.prototype.foo = function() { return 42; };

  makeA = function(){return new NativeA()};
  makeB = function(){return new NativeB()};

  self.nativeConstructor(NativeA);
  self.nativeConstructor(NativeB);
})()""");
}

main() {
  nativeTesting();
  setup();

  Expect.equals(42, makeA().foo());
  Expect.equals(42, confuse(makeA()).foo());

  Expect.equals(42, makeB().foo());
  Expect.equals(42, confuse(makeB()).foo());
}
