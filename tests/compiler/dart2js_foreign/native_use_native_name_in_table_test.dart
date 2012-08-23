// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we put native names and not Dart names into the dynamic
// dispatch table.

@native("*NativeA")
class A  {
  @native foo();
}

@native("*NativeB")
class B extends A  {
}

@native A makeA() { return new A(); }
@native B makeB() { return new B(); }

@native("""
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
function NativeA() {}
function NativeB() {}
inherits(NativeB, NativeA);
NativeA.prototype.foo = function() { return 42; };

makeA = function(){return new NativeA;};
makeB = function(){return new NativeB;};
""")
void setup();


main() {
  setup();

  var a = makeA();
  Expect.equals(42, a.foo());
  A aa = a;
  Expect.equals(42, aa.foo());  

  var b = makeB();
  Expect.equals(42, b.foo());
  B bb = b;
  Expect.equals(42, bb.foo());  
}
