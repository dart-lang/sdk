// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the feature where the native string declares the native method's name.

@native("*A")
class A {
  @native('fooA') int foo();
  @native('barA') int bar();
  @native('bazA') int baz();
}

@native A makeA();

class B {
  int bar([x]) => 800;
  int baz() => 900;
}

@native("""
// This code is all inside 'setup' and so not accesible from the global scope.
function A(){}
A.prototype.fooA = function(){return 100;};
A.prototype.barA = function(){return 200;};
A.prototype.bazA = function(){return 300;};

makeA = function(){return new A};
""")
void setup();


testDynamic() {
  setup();

  var things = [makeA(), new B()];
  var a = things[0];
  var b = things[1];

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
