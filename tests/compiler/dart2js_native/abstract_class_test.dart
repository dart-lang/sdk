// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "native_testing.dart";

// Native classes can have subclasses that are not declared to the program.  The
// subclasses are indistinguishable from the base class.  This means that
// abstract native classes can appear to have instances.

@Native("A")
abstract class A {}

@Native("B")
abstract class B {
  foo() native;
}

class C {}

makeA() native;
makeB() native;

void setup() native """
// This code is all inside 'setup' and so not accessible from the global scope.
function A(){}
function B(){}
B.prototype.foo = function() { return 'B.foo'; };
makeA = function(){return new A};
makeB = function(){return new B};
self.nativeConstructor(A);
self.nativeConstructor(B);
""";

main() {
  nativeTesting();
  setup();

  var a = makeA();
  var b = makeB();
  var c = confuse(new C());

  Expect.isTrue(a is A);
  Expect.isFalse(b is A);
  Expect.isFalse(c is A);

  Expect.isFalse(a is B);
  Expect.isTrue(b is B);
  Expect.isFalse(c is B);

  Expect.isFalse(a is C);
  Expect.isFalse(b is C);
  Expect.isTrue(c is C);

  Expect.equals('B.foo', b.foo());
}
