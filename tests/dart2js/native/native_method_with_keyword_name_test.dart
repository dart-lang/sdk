// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_testing.dart';

// Make sure we can have a native with a name that is a JavaScript keyword.

@Native("A")
class A {
  int delete() native;
}

A makeA() native;

void setup() {
  JS('', r"""
(function(){
function A() {}
A.prototype.delete = function() { return 87; };

makeA = function(){return new A()};
self.nativeConstructor(A);
})()""");
}

main() {
  nativeTesting();
  setup();

  var a1 = confuse(makeA());
  Expect.equals(87, a1.delete());
  A a2 = makeA();
  Expect.equals(87, a2.delete());
}
