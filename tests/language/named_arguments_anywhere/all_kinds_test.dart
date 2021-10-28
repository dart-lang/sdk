// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that placing a named argument anywhere in the argument list works for
// all kinds of invocations.

// SharedOptions=--enable-experiment=named-arguments-anywhere

import "package:expect/expect.dart";

List<Object?> arguments = [];

X evaluate<X>(X x) {
  arguments.add(x);
  return x;
}

void runAndCheckEvaluationOrder(
    List<Object?> expectedArguments,
    void Function() functionToRun) {
  arguments.clear();
  functionToRun();
  Expect.listEquals(expectedArguments, arguments);
}

class A {
  A(int x, String y, {bool z = false, required double w}) {
    Expect.equals(1, x);
    Expect.equals("2", y);
    Expect.isFalse(z);
    Expect.equals(3.14, w);
  }

  A.redir1() : this(evaluate(1), evaluate("2"), z: evaluate(false), w: evaluate(3.14));

  A.redir2() : this(evaluate(1), z: evaluate(false), evaluate("2"), w: evaluate(3.14));

  A.redir3() : this(z: evaluate(false), evaluate(1), evaluate("2"), w: evaluate(3.14));

  A.redir4() : this(w: evaluate(3.14), evaluate(1), evaluate("2"), z: evaluate(false));

  A.redir5() : this(evaluate(1), w: evaluate(3.14), evaluate("2"), z: evaluate(false));

  A.redir6() : this(evaluate(1), w: evaluate(3.14), evaluate("2"));

  factory A.foo(int x, String y, {bool z = false, required double w}) {
    Expect.equals(1, x);
    Expect.equals("2", y);
    Expect.isFalse(z);
    Expect.equals(3.14, w);
    return A(x, y, z: z, w: w);
  }

  factory A.redirFactory(int x, String y, {bool z, required double w}) = A;

  void Function(int x, String y, {bool z, required double w}) get property {
    return A.foo;
  }

  void bar(int x, String y, {bool z = false, required double w}) {
    Expect.equals(1, x);
    Expect.equals("2", y);
    Expect.isFalse(z);
    Expect.equals(3.14, w);
  }

  void call(int x, String y, {bool z = false, required double w}) {
    Expect.equals(1, x);
    Expect.equals("2", y);
    Expect.isFalse(z);
    Expect.equals(3.14, w);
  }
}

typedef B = A;

foo(int x, String y, {bool z = false, required double w}) {
  Expect.equals(1, x);
  Expect.equals("2", y);
  Expect.isFalse(z);
  Expect.equals(3.14, w);
}

test(dynamic d, Function f, A a) {
  void local(int x, String y, {bool z = false, required double w}) {
    Expect.equals(1, x);
    Expect.equals("2", y);
    Expect.isFalse(z);
    Expect.equals(3.14, w);
  }

  // StaticInvocation.
  runAndCheckEvaluationOrder([1, "2", false, 3.14], () {
      foo(evaluate(1), evaluate("2"), z: evaluate(false), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([1, false, "2", 3.14], () {
      foo(evaluate(1), z: evaluate(false), evaluate("2"), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([false, 1, "2", 3.14], () {
      foo(z: evaluate(false), evaluate(1), evaluate("2"), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([3.14, 1, "2", false], () {
      foo(w: evaluate(3.14), evaluate(1), evaluate("2"), z: evaluate(false));
  });
  runAndCheckEvaluationOrder([1, 3.14, "2", false], () {
      foo(evaluate(1), w: evaluate(3.14), evaluate("2"), z: evaluate(false));
  });
  runAndCheckEvaluationOrder([1, 3.14, "2"], () {
      foo(evaluate(1), w: evaluate(3.14), evaluate("2"));
  });

  // FactoryConstructorInvocation.
  runAndCheckEvaluationOrder([1, "2", false, 3.14], () {
      A.foo(evaluate(1), evaluate("2"), z: evaluate(false), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([1, false, "2", 3.14], () {
      A.foo(evaluate(1), z: evaluate(false), evaluate("2"), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([false, 1, "2", 3.14], () {
      A.foo(z: evaluate(false), evaluate(1), evaluate("2"), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([1, "2", false, 3.14], () {
      B.foo(evaluate(1), evaluate("2"), z: evaluate(false), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([1, false, "2", 3.14], () {
      B.foo(evaluate(1), z: evaluate(false), evaluate("2"), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([false, 1, "2", 3.14], () {
      B.foo(z: evaluate(false), evaluate(1), evaluate("2"), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([3.14, 1, "2", false], () {
      B.foo(w: evaluate(3.14), evaluate(1), evaluate("2"), z: evaluate(false));
  });
  runAndCheckEvaluationOrder([1, 3.14, "2", false], () {
      B.foo(evaluate(1), w: evaluate(3.14), evaluate("2"), z: evaluate(false));
  });
  runAndCheckEvaluationOrder([1, 3.14, "2"], () {
      B.foo(evaluate(1), w: evaluate(3.14), evaluate("2"));
  });

  // ConstructorInvocation.
  runAndCheckEvaluationOrder([1, "2", false, 3.14], () {
      A(evaluate(1), evaluate("2"), z: evaluate(false), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([1, false, "2", 3.14], () {
      A(evaluate(1), z: evaluate(false), evaluate("2"), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([false, 1, "2", 3.14], () {
      A(z: evaluate(false), evaluate(1), evaluate("2"), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([1, "2", false, 3.14], () {
      B(evaluate(1), evaluate("2"), z: evaluate(false), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([1, false, "2", 3.14], () {
      B(evaluate(1), z: evaluate(false), evaluate("2"), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([false, 1, "2", 3.14], () {
      B(z: evaluate(false), evaluate(1), evaluate("2"), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([3.14, 1, "2", false], () {
      B(w: evaluate(3.14), evaluate(1), evaluate("2"), z: evaluate(false));
  });
  runAndCheckEvaluationOrder([1, 3.14, "2", false], () {
      B(evaluate(1), w: evaluate(3.14), evaluate("2"), z: evaluate(false));
  });
  runAndCheckEvaluationOrder([1, 3.14, "2"], () {
      B(evaluate(1), w: evaluate(3.14), evaluate("2"));
  });

  // DynamicInvocation.
  runAndCheckEvaluationOrder([1, "2", false, 3.14], () {
      d(evaluate(1), evaluate("2"), z: evaluate(false), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([1, false, "2", 3.14], () {
      d(evaluate(1), z: evaluate(false), evaluate("2"), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([false, 1, "2", 3.14], () {
      d(z: evaluate(false), evaluate(1), evaluate("2"), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([3.14, 1, "2", false], () {
      d(w: evaluate(3.14), evaluate(1), evaluate("2"), z: evaluate(false));
  });
  runAndCheckEvaluationOrder([1, 3.14, "2", false], () {
      d(evaluate(1), w: evaluate(3.14), evaluate("2"), z: evaluate(false));
  });
  runAndCheckEvaluationOrder([1, 3.14, "2"], () {
      d(evaluate(1), w: evaluate(3.14), evaluate("2"));
  });

  // FunctionInvocation.
  runAndCheckEvaluationOrder([1, "2", false, 3.14], () {
      f(evaluate(1), evaluate("2"), z: evaluate(false), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([1, false, "2", 3.14], () {
      f(evaluate(1), z: evaluate(false), evaluate("2"), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([false, 1, "2", 3.14], () {
      f(z: evaluate(false), evaluate(1), evaluate("2"), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([3.14, 1, "2", false], () {
      f(w: evaluate(3.14), evaluate(1), evaluate("2"), z: evaluate(false));
  });
  runAndCheckEvaluationOrder([1, 3.14, "2", false], () {
      f(evaluate(1), w: evaluate(3.14), evaluate("2"), z: evaluate(false));
  });
  runAndCheckEvaluationOrder([1, 3.14, "2"], () {
      f(evaluate(1), w: evaluate(3.14), evaluate("2"));
  });

  // InstanceGetterInvocation.
  runAndCheckEvaluationOrder([1, "2", false, 3.14], () {
      a.property(evaluate(1), evaluate("2"), z: evaluate(false), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([1, false, "2", 3.14], () {
      a.property(evaluate(1), z: evaluate(false), evaluate("2"), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([false, 1, "2", 3.14], () {
      a.property(z: evaluate(false), evaluate(1), evaluate("2"), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([3.14, 1, "2", false], () {
      a.property(w: evaluate(3.14), evaluate(1), evaluate("2"), z: evaluate(false));
  });
  runAndCheckEvaluationOrder([1, 3.14, "2", false], () {
      a.property(evaluate(1), w: evaluate(3.14), evaluate("2"), z: evaluate(false));
  });
  runAndCheckEvaluationOrder([1, 3.14, "2"], () {
      a.property(evaluate(1), w: evaluate(3.14), evaluate("2"));
  });

  // InstanceInvocation.
  runAndCheckEvaluationOrder([a, 1, "2", false, 3.14], () {
      evaluate(a).bar(evaluate(1), evaluate("2"), z: evaluate(false), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([a, 1, false, "2", 3.14], () {
      evaluate(a).bar(evaluate(1), z: evaluate(false), evaluate("2"), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([a, false, 1, "2", 3.14], () {
      evaluate(a).bar(z: evaluate(false), evaluate(1), evaluate("2"), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([a, 3.14, 1, "2", false], () {
      evaluate(a).bar(w: evaluate(3.14), evaluate(1), evaluate("2"), z: evaluate(false));
  });
  runAndCheckEvaluationOrder([a, 1, 3.14, "2", false], () {
      evaluate(a).bar(evaluate(1), w: evaluate(3.14), evaluate("2"), z: evaluate(false));
  });
  runAndCheckEvaluationOrder([a, 1, 3.14, "2"], () {
      evaluate(a).bar(evaluate(1), w: evaluate(3.14), evaluate("2"));
  });

  // LocalFunctionInvocation.
  runAndCheckEvaluationOrder([1, "2", false, 3.14], () {
      local(evaluate(1), evaluate("2"), z: evaluate(false), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([1, false, "2", 3.14], () {
      local(evaluate(1), z: evaluate(false), evaluate("2"), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([false, 1, "2", 3.14], () {
      local(z: evaluate(false), evaluate(1), evaluate("2"), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([3.14, 1, "2", false], () {
      local(w: evaluate(3.14), evaluate(1), evaluate("2"), z: evaluate(false));
  });
  runAndCheckEvaluationOrder([1, 3.14, "2", false], () {
      local(evaluate(1), w: evaluate(3.14), evaluate("2"), z: evaluate(false));
  });
  runAndCheckEvaluationOrder([1, 3.14, "2"], () {
      local(evaluate(1), w: evaluate(3.14), evaluate("2"));
  });

  // Redirecting generative constructors.
  runAndCheckEvaluationOrder([1, "2", false, 3.14], () {
      A.redir1();
  });
  runAndCheckEvaluationOrder([1, false, "2", 3.14], () {
      A.redir2();
  });
  runAndCheckEvaluationOrder([false, 1, "2", 3.14], () {
      A.redir3();
  });
  runAndCheckEvaluationOrder([3.14, 1, "2", false], () {
      A.redir4();
  });
  runAndCheckEvaluationOrder([1, 3.14, "2", false], () {
      A.redir5();
  });
  runAndCheckEvaluationOrder([1, 3.14, "2"], () {
      A.redir6();
  });

  // Redirecting factory constructors.
  runAndCheckEvaluationOrder([1, "2", false, 3.14], () {
      A.redirFactory(evaluate(1), evaluate("2"), z: evaluate(false), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([1, false, "2", 3.14], () {
      A.redirFactory(evaluate(1), z: evaluate(false), evaluate("2"), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([false, 1, "2", 3.14], () {
      A.redirFactory(z: evaluate(false), evaluate(1), evaluate("2"), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([3.14, 1, "2", false], () {
      A.redirFactory(w: evaluate(3.14), evaluate(1), evaluate("2"), z: evaluate(false));
  });
  runAndCheckEvaluationOrder([1, 3.14, "2", false], () {
      A.redirFactory(evaluate(1), w: evaluate(3.14), evaluate("2"), z: evaluate(false));
  });
  runAndCheckEvaluationOrder([1, 3.14, "2"], () {
      A.redirFactory(evaluate(1), w: evaluate(3.14), evaluate("2"));
  });

  // Constructor super initializers.
  runAndCheckEvaluationOrder([1, "2", false, 3.14], () {
      Test.super1();
  });
  runAndCheckEvaluationOrder([1, false, "2", 3.14], () {
      Test.super2();
  });
  runAndCheckEvaluationOrder([false, 1, "2", 3.14], () {
      Test.super3();
  });
  runAndCheckEvaluationOrder([3.14, 1, "2", false], () {
      Test.super4();
  });
  runAndCheckEvaluationOrder([1, 3.14, "2", false], () {
      Test.super5();
  });
  runAndCheckEvaluationOrder([1, 3.14, "2"], () {
      Test.super6();
  });

  // Implicit .call insertion.
  runAndCheckEvaluationOrder([1, "2", false, 3.14], () {
      a(evaluate(1), evaluate("2"), z: evaluate(false), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([1, false, "2", 3.14], () {
      a(evaluate(1), z: evaluate(false), evaluate("2"), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([false, 1, "2", 3.14], () {
      a(z: evaluate(false), evaluate(1), evaluate("2"), w: evaluate(3.14));
  });
  runAndCheckEvaluationOrder([3.14, 1, "2", false], () {
      a(w: evaluate(3.14), evaluate(1), evaluate("2"), z: evaluate(false));
  });
  runAndCheckEvaluationOrder([1, 3.14, "2", false], () {
      a(evaluate(1), w: evaluate(3.14), evaluate("2"), z: evaluate(false));
  });
  runAndCheckEvaluationOrder([1, 3.14, "2"], () {
      a(evaluate(1), w: evaluate(3.14), evaluate("2"));
  });
}

class Test extends A {
  Test() : super(1, "2", z: false, w: 3.14);

  Test.super1() : super(evaluate(1), evaluate("2"), z: evaluate(false), w: evaluate(3.14));
  Test.super2() : super(evaluate(1), z: evaluate(false), evaluate("2"), w: evaluate(3.14));
  Test.super3() : super(z: evaluate(false), evaluate(1), evaluate("2"), w: evaluate(3.14));
  Test.super4() : super(w: evaluate(3.14), evaluate(1), evaluate("2"), z: evaluate(false));
  Test.super5() : super(evaluate(1), w: evaluate(3.14), evaluate("2"), z: evaluate(false));
  Test.super6() : super(evaluate(1), w: evaluate(3.14), evaluate("2"));

  test() {
    runAndCheckEvaluationOrder([1, "2", false, 3.14], () {
        super.bar(evaluate(1), evaluate("2"), z: evaluate(false), w: evaluate(3.14));
    });
    runAndCheckEvaluationOrder([1, false, "2", 3.14], () {
        super.bar(evaluate(1), z: evaluate(false), evaluate("2"), w: evaluate(3.14));
    });
    runAndCheckEvaluationOrder([false, 1, "2", 3.14], () {
        super.bar(z: evaluate(false), evaluate(1), evaluate("2"), w: evaluate(3.14));
    });
    runAndCheckEvaluationOrder([3.14, 1, "2", false], () {
        super.bar(w: evaluate(3.14), evaluate(1), evaluate("2"), z: evaluate(false));
    });
    runAndCheckEvaluationOrder([1, 3.14, "2", false], () {
        super.bar(evaluate(1), w: evaluate(3.14), evaluate("2"), z: evaluate(false));
    });
    runAndCheckEvaluationOrder([1, 3.14, "2"], () {
        super.bar(evaluate(1), w: evaluate(3.14), evaluate("2"));
    });

    // Using super.call() implicitly.
    runAndCheckEvaluationOrder([1, "2", false, 3.14], () {
        super(evaluate(1), evaluate("2"), z: evaluate(false), w: evaluate(3.14));
    });
    runAndCheckEvaluationOrder([1, false, "2", 3.14], () {
        super(evaluate(1), z: evaluate(false), evaluate("2"), w: evaluate(3.14));
    });
    runAndCheckEvaluationOrder([false, 1, "2", 3.14], () {
        super(z: evaluate(false), evaluate(1), evaluate("2"), w: evaluate(3.14));
    });
    runAndCheckEvaluationOrder([3.14, 1, "2", false], () {
        super(w: evaluate(3.14), evaluate(1), evaluate("2"), z: evaluate(false));
    });
    runAndCheckEvaluationOrder([1, 3.14, "2", false], () {
        super(evaluate(1), w: evaluate(3.14), evaluate("2"), z: evaluate(false));
    });
    runAndCheckEvaluationOrder([1, 3.14, "2"], () {
        super(evaluate(1), w: evaluate(3.14), evaluate("2"));
    });
  }
}

extension E on A {
  test() {
    runAndCheckEvaluationOrder(["1", 2], () {
        method(foo: evaluate("1"), evaluate(2)); // This call.
    });
  }
  method(int bar, {String? foo}) {
    Expect.equals(2, bar);
    Expect.equals("1", foo);
  }
}

main() {
  A a = A(1, "2", z: false, w: 3.14);

  test(A.foo, A.foo, a);
  Test().test();
  a.test();
}
