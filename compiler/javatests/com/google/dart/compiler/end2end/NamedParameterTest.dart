// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing named parameters.

class A {
  static Function sfn;
  Function fn;

  factory A.make(int a, [int b, int c=3]) {
    return new A(a, b, c);
  }

  A(int a, [int b, int c=3]) { }
  A.named_ctor(int a, [int b, int c=3]) { }

  static int static_method(int a, [int b, int c=3]) { 
    return (a + b) * c;
  }

  static int _private_static_method(int a, [int b, int c=3]) { 
    return (a + b) * c;
  }

  int instance_method(int x, [int y, int z=3]) {
    return (x + y) * z;
  }

  int _private_instance_method(int x, [int y, int z=3]) {
    return (x + y) * z;
  }
}

int global_function(int x, int y, [int z]) {
  return (x + y) * z;
}

Function gfn;

class C {
  int i;
  Function fn;

  C(this.i) {}
}

testCtors() {
  A a = new A(1, 2);
  A a0 = new A(1, b:2);
  A a1 = new A(1, c:3, b:2);

  A a2 = new A.make(1, 2);
  A a3 = new A.make(1, 2, 3);
  A a4 = new A.make(1, 2, c:3);
  A a5 = new A.make(1, b:2, c:3);
}

testCalls() {
  A a = new A(1, 2);

  // global calls
  Expect.equals(9, global_function(1, 2, 3)); 
  Expect.equals(9, global_function(1, 2, z:3));

  // static calls
  Expect.equals(9, A.static_method(1, 2));
  Expect.equals(9, A.static_method(1, 2, 3)); 
  Expect.equals(9, A.static_method(1, 2, c:3));
  Expect.equals(9, A.static_method(1, c:3, b:2));

  // private static calls
  Expect.equals(9, A._private_static_method(1, 2));
  Expect.equals(9, A._private_static_method(1, 2, 3)); 
  Expect.equals(9, A._private_static_method(1, 2, c:3));
  Expect.equals(9, A._private_static_method(1, c:3, b:2));

  // instance calls
  Expect.equals(9, a.instance_method(1, 2));
  Expect.equals(9, a.instance_method(1, 2, 3));
  Expect.equals(9, a.instance_method(1, z:3, y:2));

  // private instance calls
  Expect.equals(9, a._private_instance_method(1, 2));
  Expect.equals(9, a._private_instance_method(1, 2, 3));
  Expect.equals(9, a._private_instance_method(1, z:3, y:2));
}

testCallsThroughVars() {
  A a = new A(1, 2);

  // bound global calls
  Function fn0 = global_function;
  Expect.equals(9, fn0(1, 2, 3)); 
  Expect.equals(9, fn0(1, 2, z:3));

  // bound static calls
  Function fn1 = A.static_method;
  Expect.equals(9, fn1(1, 2));
  Expect.equals(9, fn1(1, 2, 3)); 
  Expect.equals(9, fn1(1, 2, c:3));
  Expect.equals(9, fn1(1, c:3, b:2));

  // bound instance calls
  Function fn2 = a.instance_method;
  Expect.equals(9, fn2(1, 2));
  Expect.equals(9, fn2(1, 2, 3));
  Expect.equals(9, fn2(1, z:3, y:2));

  // call to bound method through instance field
  a.fn = global_function;
  Expect.equals(9, a.fn(1, 2, 3));
  Expect.equals(9, a.fn(1, 2, z:3));

  // call to bound method through static field
  A.sfn = global_function;
  Expect.equals(9, A.sfn(1, 2, 3)); 
  Expect.equals(9, A.sfn(1, 2, z:3));

  // call to bound method through global field
  gfn = global_function;
  Expect.equals(9, gfn(1, 2, 3)); 
  Expect.equals(9, gfn(1, 2, z:3));
}

// ---------------------------------------------------------------------------
testClosures() {
  // call to hoisted closure
  var cfn = int foo(int x, int y, [int z]) { return (x + y) * z; };
  Expect.equals(9, cfn(1, 2, 3));
  Expect.equals(9, cfn(1, 2, z:3));

  // call to local function
  int lfn(int x, int y, [int z]) { return (x + y) * z; }
  Expect.equals(9, lfn(1, 2, 3));
  Expect.equals(9, lfn(1, 2, z:3));

  // fun case with local and this binding
  C c = new C(20);
  Function refc = () => c.i;
  c.fn = refc;
  Expect.equals(20, c.fn());
}

testMultipleClosureScopes() {
  for (int x = 0; x < 1; ++x) {
    int i = 6;
    for (int y = 0; y < 1; ++y) {
      int j = 9;

      var a = new List<Function>(1);
      a[0] = () => i * j;
      Expect.equals(54, a[0]());
    }
  }
}

// ---------------------------------------------------------------------------
class Sup {
  Sup() { }
  int foo() { return 54; }
}

class Sub extends Sup {
  Sub(): super() { }
  int foo() { return 42; }
  Function getSuperFoo() { return super.foo; }
}

testSuperMethodGetter() {
  var sup = new Sup();
  var sub = new Sub();
  Expect.equals(sup.foo(), sub.getSuperFoo()());
}

// ---------------------------------------------------------------------------
class HasGetter {
  HasGetter() { }
  var field;
  get getter() { return field; }
  method() { return field; }
}

void testGetter() {
  HasGetter a = new HasGetter();
  a.field = () => 42;
  Expect.equals(42, a.getter());
  Expect.equals(42, (a.getter)());

  a.field = () => 87;
  Expect.equals(87, a.getter());
  Expect.equals(87, (a.getter)());
}

// ---------------------------------------------------------------------------
expectNSME(Function fn) {
  try {
    fn();
    Expect.fail("Expected NoSuchMethodException");
  } catch (NoSuchMethodException e) {
  }
}

int takesNoArgs() => 42;
int takesOneArg(int x) => 42;
int takesOneNamedArg([int x]) => 42;

testStaticNSM() {
  expectNSME(() => takesNoArgs("I'm ignoring static errors!"));
  expectNSME(() => takesOneArg());
  expectNSME(() => takesOneNamedArg(y:54));
}

// ---------------------------------------------------------------------------
main() {
  testCtors();
  testCalls();
  testCallsThroughVars();
  testMultipleClosureScopes();
  testGetter();
  testStaticNSM();
}
