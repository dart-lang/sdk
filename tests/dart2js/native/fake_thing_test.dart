// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:_foreign_helper" show JS;

// Test that native objects cannot accidentally or maliciously be mistaken for
// Dart objects.

// This test currently fails because we do not recognize the need for
// interceptors without native *classes*.

class Thing {}

make1() native;
make2() native;

void setup() {
  JS('', r"""
(function(){
  function A() {}
  A.prototype.$isThing = true;
  make1 = function(){return new A();};
  make2 = function(){return {$isThing: true}};
})()""");
}

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
inscrutable(x) => x;

main() {
  setup();

  var a = new Thing();
  var b = make1();
  var c = make2();
  Expect.isTrue(inscrutable(a) is Thing);
  Expect.isFalse(inscrutable(b) is Thing);
  Expect.isFalse(inscrutable(c) is Thing);
}
