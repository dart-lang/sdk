// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test to see if resolving a hidden native class's method interferes with
// subsequent resolving the subclass's method.  This might happen if the
// superclass caches the method in the prototype, so shadowing the dispatcher
// stored on Object.prototype.

// Version 1: It might be possible to call foo directly.
@native("*A1")
class A1 {
  @native foo();
}

@native("*B1")
class B1 extends A1  {
  @native foo();
}

@native makeA1();
@native makeB1();


// Version 2: foo needs some kind of trampoline.
@native("*A2")
class A2 {
  @native foo([a=99]);
}

@native("*B2")
class B2 extends A2  {
  @native foo([z=1000]);
}

@native makeA2();
@native makeB2();

@native("""
// This code is all inside 'setup' and so not accesible from the global scope.
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
A1.prototype.foo = function(){return 100;}
B1.prototype.foo = function(){return 200;}

makeA1 = function(){return new A1};
makeB1 = function(){return new B1};

function A2(){}
function B2(){}
inherits(B2, A2);
A2.prototype.foo = function(a){return a + 10000;}
B2.prototype.foo = function(z){return z + 20000;}

makeA2 = function(){return new A2};
makeB2 = function(){return new B2};
""")
void setup();


main() {
  setup();

  var a1 = makeA1();
  var b1 = makeB1();
  Expect.equals(100, a1.foo());
  Expect.equals(200, b1.foo());

  var a2 = makeA2();
  var b2 = makeB2();
  Expect.equals(10000 + 99, a2.foo());
  Expect.equals(20000 + 1000, b2.foo());

  Expect.equals(10000 + 1, a2.foo(1));
  Expect.equals(20000 + 2, b2.foo(2));

  bool caught = false;
  try {
    a1.foo(20);
  } catch (ex) {
    caught = true;
    Expect.isTrue(ex is NoSuchMethodError);
  }
  Expect.isTrue(caught, 'a1.foo(20) should throw');

  caught = false;
  try {
    var x = 123;
    x.foo(20);
  } catch (ex) {
    caught = true;
    Expect.isTrue(ex is NoSuchMethodError);
  }
  Expect.isTrue(caught, "x.foo(20) should throw");
}
