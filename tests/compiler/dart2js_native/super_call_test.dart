// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "native_testing.dart";

// Test to see if resolving a hidden native class's method interferes with
// subsequent resolving the subclass's method.  This might happen if the
// superclass caches the method in the prototype, so shadowing the dispatcher
// stored on Object.prototype.

@Native("A")
class A {
  foo() => 'A.foo ${bar()}';
  bar() => 'A.bar';
}

@Native("B")
class B extends A {
  bar() => 'B.bar';
}

@Native("C")
class C extends B {
  foo() => 'C.foo; super.foo = ${super.foo()}';
  bar() => 'C.bar';
}

@Native("D")
class D extends C {
  bar() => 'D.bar';
}

makeA() native;
makeB() native;
makeC() native;
makeD() native;

void setup() native """
// This code is all inside 'setup' and so not accessible from the global scope.
function inherits(child, parent) {
  if (child.prototype.__proto__) {
    child.prototype.__proto__ = parent.prototype;
  } else {
    function tmp() {};
    tmp.prototype = parent.prototype;
    child.prototype = new tmp();
    child.prototype.constructor = child;
  }
}

function A(){}
function B(){}
inherits(B, A);
function C(){}
inherits(C, B);
function D(){}
inherits(D, C);

makeA = function(){return new A};
makeB = function(){return new B};
makeC = function(){return new C};
makeD = function(){return new D};

self.nativeConstructor(A);
self.nativeConstructor(B);
self.nativeConstructor(C);
self.nativeConstructor(D);
""";

main() {
  nativeTesting();
  setup();

  var a = makeA();
  var b = makeB();
  var c = makeC();
  var d = makeD();

  Expect.equals('A.foo A.bar', a.foo());
  Expect.equals('A.foo B.bar', b.foo());
  Expect.equals('C.foo; super.foo = A.foo C.bar', c.foo());
  Expect.equals('C.foo; super.foo = A.foo D.bar', d.foo());
}
