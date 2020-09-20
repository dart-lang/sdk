// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the feature where the native string declares the native method's name.

import 'native_testing.dart';
import 'dart:_js_helper' show Native, JSName;

@Native("A")
class A {
  @JSName('fooA')
  int foo() native;

  @JSName('barA')
  int bar() native;

  @JSName('bazA')
  int baz() native;
}

A makeA() native;

class B {
  int bar([x]) => 800;
  int baz() => 900;
}

void setup() {
  JS('', r"""
(function(){
  // This code is inside 'setup' and so not accessible from the global scope.
  function A(){}
  A.prototype.fooA = function(){return 100;};
  A.prototype.barA = function(){return 200;};
  A.prototype.bazA = function(){return 300;};

  makeA = function(){return new A()};

  self.nativeConstructor(A);
})()""");
}

testDynamic() {
  var a = confuse(makeA());
  var b = confuse(new B());

  Expect.equals(100, a.foo());
  Expect.equals(200, a.bar());
  Expect.equals(300, a.baz());
  Expect.equals(800, b.bar());
  Expect.equals(900, b.baz());
}

testTyped() {
  A a = makeA();
  B b = new B();

  Expect.equals(100, a.foo());
  Expect.equals(200, a.bar());
  Expect.equals(300, a.baz());
  Expect.equals(800, b.bar());
  Expect.equals(900, b.baz());
}

main() {
  nativeTesting();
  setup();
  testDynamic();
  testTyped();
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
