// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "native_testing.dart";

// Test for correct simple is-checks on hidden native classes.

abstract class I {
  I read();
  write(I x);
}

// Native implementation.

@Native("A")
class A implements I {
  // The native class accepts only other native instances.
  A read() native;
  write(A x) native;
}

makeA() native;

void setup() native """
// This code is all inside 'setup' and so not accessible from the global scope.
function A(){}
A.prototype.read = function() { return this._x; };
A.prototype.write = function(x) { this._x = x; };
makeA = function(){return new A};
self.nativeConstructor(A);
""";

class B {}

main() {
  nativeTesting();
  setup();

  var a1 = makeA();
  var ob = new Object();

  Expect.isFalse(ob is I);
  Expect.isFalse(ob is A);
  Expect.isFalse(ob is B);

  Expect.isTrue(a1 is I);
  Expect.isTrue(a1 is A);
  Expect.isTrue(a1 is! B);
}
