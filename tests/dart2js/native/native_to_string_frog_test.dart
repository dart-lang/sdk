// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_testing.dart';

@Native("A")
class A {
  toString() => 'AAA';
}

makeA() native;

void setup() {
  JS('', r"""
(function(){
  function A() {}
  makeA = function(){return new A()};
  self.nativeConstructor(A);
})()""");
}

main() {
  nativeTesting();
  setup();

  Expect.isTrue(makeA().toString() is String);
  Expect.equals('AAA', makeA().toString());

  Expect.isTrue(confuse(makeA()).toString() is String);
  Expect.equals('AAA', confuse(makeA()).toString());
}
