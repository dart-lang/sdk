// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_testing.dart';

// Test that native objects cannot accidentally or maliciously be mistaken for
// Dart objects.
// The difference between fake_thing_test and fake_thing_2_test is the
// presence of a used declared native class.

class Thing {}

@Native("NT")
class NativeThing {}

make1() native;
make2() native;
make3() native;

void setup() {
  JS('', r"""
(function(){
  function A() {}
  A.prototype.$isThing = true;
  make1 = function(){return new A()};
  make2 = function(){return {$isThing: true}};
  function NT() {}
  NT.prototype.$isThing = true;
  make3 = function(){return new NT()};

  self.nativeConstructor(NT);
})()""");
}

main() {
  nativeTesting();
  setup();

  var a = new Thing();
  var b = make1();
  var c = make2();
  var d = make3();
  Expect.isTrue(confuse(a) is Thing);
  Expect.isFalse(confuse(b) is Thing);
  Expect.isFalse(confuse(c) is Thing);
  Expect.isFalse(confuse(d) is Thing);
}
