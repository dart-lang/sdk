// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test named arguments work as expected regardless of whether the function or
// method is called via function call syntax or method call syntax.


Validate(tag, a, b) {
  // tag encodes which parameters are passed in with values a: 111, b: 222.
  if (tag == 'ab') {
    Expect.equals(a, 111);
    Expect.equals(b, 222);
  }
  if (tag == 'a') {
    Expect.equals(a, 111);
    Expect.equals(b, 20);
  }
  if (tag == 'b') {
    Expect.equals(a, 10);
    Expect.equals(b, 222);
  }
  if (tag == '') {
    Expect.equals(a, 10);
    Expect.equals(b, 20);
  }
}

class HasMethod {

  int calls;

  HasMethod() : calls = 0 {}

  foo(tag, [a = 10, b = 20]) {
    calls += 1;
    Validate(tag, a, b);
  }
}

class HasField {

  int calls;
  var foo;

  HasField() {
    calls = 0;
    foo = makeFoo(this);
  }

  makeFoo(owner) {
    // This function is closed-over 'owner'.
    return (tag, [a = 10, b = 20]) {
      owner.calls += 1;
      Validate(tag, a, b);
    };
  }
}


class NamedParametersWithConversionsTest {

  static checkException(thunk) {
    bool threw = false;
    try {
      thunk();
    } catch (e) {
      threw = true;
    }
    Expect.isTrue(threw);
  }

  static testMethodCallSyntax(a) {
    a.foo('');
    a.foo('a', 111);
    a.foo('ab', 111, 222);
    a.foo('a', a: 111);
    a.foo('b', b: 222);
    a.foo('ab', a: 111, b: 222);
    a.foo('ab', b: 222, a: 111);

    Expect.equals(7, a.calls);

    checkException(() => a.foo());                 // Too few arguments.
    checkException(() => a.foo('abc', 1, 2, 3));   // Too many arguments.
    checkException(() => a.foo('c', c: 1));        // Bad name.

    Expect.equals(7, a.calls);
  }

  static testFunctionCallSyntax(a) {
    var f = a.foo;
    f('');
    f('a', 111);
    f('ab', 111, 222);
    f('a', a: 111);
    f('b', b: 222);
    f('ab', a: 111, b: 222);
    f('ab', b: 222, a: 111);

    Expect.equals(7, a.calls);

    checkException(() => f());                 // Too few arguments.
    checkException(() => f('abc', 1, 2, 3));   // Too many arguments.
    checkException(() => f('c', c: 1));        // Bad name.

    Expect.equals(7, a.calls);
  }

  static testMain() {
    // 'Plain' calls where the method/field syntax matches the object.
    testMethodCallSyntax(new HasMethod());
    testFunctionCallSyntax(new HasField());

    // 'Conversion' calls where method/field call syntax does not match the
    // object.
    testMethodCallSyntax(new HasField());
    testFunctionCallSyntax(new HasMethod());
  }
}

main() {
  NamedParametersWithConversionsTest.testMain();
}
