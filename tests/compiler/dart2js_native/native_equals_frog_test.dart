// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_testing.dart';

@Native("A")
class A {}

int calls = 0;

@Native("B")
class B {
  bool operator ==(other) {
    ++calls;
    return other is B;
  }

  int get hashCode => 1;
}

makeA() native;
makeB() native;

void setup() native """
function A() {}
function B() {}
makeA = function(){return new A;};
makeB = function(){return new B;};

self.nativeConstructor(B);
""";

main() {
  nativeTesting();
  setup();
  var a = makeA();
  Expect.isTrue(a == a);
  Expect.isTrue(identical(a, a));

  Expect.isFalse(a == makeA());
  Expect.isFalse(identical(a, makeA()));

  var b = makeB();
  Expect.isTrue(b == b);
  Expect.isTrue(identical(b, b));

  Expect.isTrue(b == makeB());
  Expect.isFalse(identical(b, makeB()));

  Expect.equals(2, calls);
}
