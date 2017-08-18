// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "native_testing.dart";

// Test to see if resolving a hidden native class's method to noSuchMethod
// interferes with subsequent resolving of the method.  This might happen if the
// noSuchMethod is cached on Object.prototype.

@Native("A1")
class A1 {}

@Native("B1")
class B1 extends A1 {}

makeA1() native;
makeB1() native;

@Native("A2")
class A2 {
  foo([a = 99]) native;
}

@Native("B2")
class B2 extends A2 {}

makeA2() native;
makeB2() native;

makeObject() native;

void setup() {
  JS('', r"""
(function(){
  // This code is inside 'setup' and so not accessible from the global scope.
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
  function A1(){}
  function B1(){}
  inherits(B1, A1);

  makeA1 = function(){return new A1()};
  makeB1 = function(){return new B1()};

  function A2(){}
  function B2(){}
  inherits(B2, A2);
  A2.prototype.foo = function(a){return 'A2.foo(' + a  + ')';};

  makeA2 = function(){return new A2()};
  makeB2 = function(){return new B2()};

  makeObject = function(){return new Object()};

  self.nativeConstructor(A1);
  self.nativeConstructor(A2);
  self.nativeConstructor(B1);
  self.nativeConstructor(B2);
})()""");
}

main() {
  nativeTesting();
  setup();

  var a1 = makeA1();
  var b1 = makeB1();
  var ob = makeObject();

  // Does calling missing methods in one tree of inheritance forest affect other
  // trees?
  expectNoSuchMethod(() => b1.foo(), 'b1.foo()');
  expectNoSuchMethod(() => a1.foo(), 'a1.foo()');
  expectNoSuchMethod(() => ob.foo(), 'ob.foo()');

  var a2 = makeA2();
  var b2 = makeB2();

  Expect.equals('A2.foo(99)', a2.foo());
  Expect.equals('A2.foo(99)', b2.foo());
  Expect.equals('A2.foo(1)', a2.foo(1));
  Expect.equals('A2.foo(2)', b2.foo(2));

  expectNoSuchMethod(() => b1.foo(3), 'b1.foo(3)');
  expectNoSuchMethod(() => a1.foo(4), 'a1.foo(4)');
}

expectNoSuchMethod(action, note) {
  bool caught = false;
  try {
    action();
  } catch (ex) {
    caught = true;
    Expect.isTrue(ex is NoSuchMethodError, note);
  }
  Expect.isTrue(caught, note);
}
