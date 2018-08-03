// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_testing.dart';

// Additional Dart code may be 'placed on' hidden native classes.

@Native("A")
class A {
  var _field;

  int get X => _field;
  void set X(int x) {
    _field = x;
  }

  int method(int z) => _field + z;
}

A makeA() native;

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

  var a = makeA();

  a.X = 100;
  Expect.equals(100, a.X);
  Expect.equals(150, a.method(50));
}
