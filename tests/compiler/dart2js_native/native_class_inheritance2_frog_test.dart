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
  foo([a = 100]) native;
}

@Native("B")
class B extends A {}

@Native("C")
class C extends B {
  foo([z = 300]) native;
}

@Native("D")
class D extends C {}

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

A.prototype.foo = function(a){return 'A.foo(' + a + ')';}
C.prototype.foo = function(z){return 'C.foo(' + z + ')';}

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

  Expect.equals('A.foo(100)', b.foo());
  Expect.equals('C.foo(300)', d.foo());
  // If the above line fails with C.foo(100) then the dispatch to fill in the
  // default got the wrong one, followed by a second dispatch that resolved to
  // the correct native method.

  Expect.equals('A.foo(1)', a.foo(1));
  Expect.equals('A.foo(2)', b.foo(2));
  Expect.equals('C.foo(3)', c.foo(3));
  Expect.equals('C.foo(4)', d.foo(4));
}
