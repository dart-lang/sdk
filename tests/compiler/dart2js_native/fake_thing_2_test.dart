// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_js_helper";
import "package:expect/expect.dart";

// Test that native objects cannot accidentally or maliciously be mistaken for
// Dart objects.
// The difference between fake_thing_test and fake_thing_2_test is the
// presence of a used declared native class.

class Thing {
}

@Native("NT")
class NativeThing {
}

make1() native;
make2() native;
make3() native;

void setup() native r"""
function A() {}
A.prototype.$isThing = true;
make1 = function(){return new A;};
make2 = function(){return {$isThing: true}};
function NT() {}
NT.prototype.$isThing = true;
make3 = function(){return new NT;};
""";

var inscrutable;
main() {
  setup();
  inscrutable = (x) => x;

  var a = new Thing();
  var b = make1();
  var c = make2();
  var d = make3();
  Expect.isTrue(inscrutable(a) is Thing);
  Expect.isFalse(inscrutable(b) is Thing);
  Expect.isFalse(inscrutable(c) is Thing);
  Expect.isFalse(inscrutable(d) is Thing);
}
