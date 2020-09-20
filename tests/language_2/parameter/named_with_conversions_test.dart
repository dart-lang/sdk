// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test named arguments work as expected regardless of whether the function or
// method is called via function call syntax or method call syntax.
// VMOptions=--optimization-counter-threshold=10

import "package:expect/expect.dart";

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
  int calls = 0;

  HasMethod();

  foo(tag, [a = 10, b = 20]) {
    calls += 1;
    Validate(tag, a, b);
  }

  foo2(tag, {a: 10, b: 20}) {
    calls += 1;
    Validate(tag, a, b);
  }
}

class HasField {
  int calls = 0;
  dynamic foo, foo2;

  HasField() {
    foo = makeFoo(this);
    foo2 = makeFoo2(this);
  }

  makeFoo(owner) {
    // This function is closed-over 'owner'.
    return (tag, [a = 10, b = 20]) {
      owner.calls += 1;
      Validate(tag, a, b);
    };
  }

  makeFoo2(owner) {
    // This function is closed-over 'owner'.
    return (tag, {a: 10, b: 20}) {
      owner.calls += 1;
      Validate(tag, a, b);
    };
  }
}

class NamedParametersWithConversionsTest {
  static testMethodCallSyntax(a) {
    a.foo('');
    a.foo('a', 111);
    a.foo('ab', 111, 222);
    a.foo2('a', a: 111);
    a.foo2('b', b: 222);
    a.foo2('ab', a: 111, b: 222);
    a.foo2('ab', b: 222, a: 111);

    Expect.equals(7, a.calls);

    Expect.throwsNoSuchMethodError(() => a.foo()); // Too few arguments.
    Expect.throwsNoSuchMethodError(
        () => a.foo('abc', 1, 2, 3)); //              Too many arguments.
    Expect.throwsNoSuchMethodError(() => a.foo2('c', c: 1)); // Bad name.
    Expect.throwsNoSuchMethodError(
        () => a.foo2('c', a: 111, c: 1)); //                    Bad name.

    Expect.equals(7, a.calls);
  }

  static testFunctionCallSyntax(a) {
    var f = a.foo;
    var f2 = a.foo2;
    f('');
    f('a', 111);
    f('ab', 111, 222);
    f2('a', a: 111);
    f2('b', b: 222);
    f2('ab', a: 111, b: 222);
    f2('ab', b: 222, a: 111);

    Expect.equals(7, a.calls);

    Expect.throwsNoSuchMethodError(() => f()); // Too few arguments.
    Expect.throwsNoSuchMethodError(
        () => f('abc', 1, 2, 3)); //              Too many arguments.
    Expect.throwsNoSuchMethodError(() => f2('c', c: 1)); //         Bad name.
    Expect.throwsNoSuchMethodError(() => f2('c', a: 111, c: 1)); // Bad name.

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
  for (var i = 0; i < 20; i++) {
    NamedParametersWithConversionsTest.testMain();
  }
}
