// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_testing.dart';

@Native("A")
class A {}

@Native("B")
class B {
  int get hashCode => 1234567;
}

makeA() native;
makeB() native;

void setup() {
  JS('', r"""
(function(){
  function A() {}
  function B() {}
  makeA = function(){return new A()};
  makeB = function(){return new B()};

  self.nativeConstructor(A);
  self.nativeConstructor(B);
})()""");
}

main() {
  nativeTesting();
  setup();
  Expect.isTrue(makeA().hashCode is int);
  Expect.equals(1234567, makeB().hashCode);
}
