// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests function statements and expressions.

class Bug4089219 {
  int x;
  var f;

  Bug4089219(int i) : this.x = i {
    f = () => x;
  }
}

class Bug4342163 {
  final m;
  Bug4342163(int a) : this.m = (() => a) {}
}

class StaticFunctionDef {
  static const int one = 1;
  static var fn1;
  static var fn2;
  static var fn3;

  static init() {
    fn1 = () {
      return one;
    };
    fn2 = () {
      return (() {
        return one;
      })();
    };
    fn3 = () {
      final local = 1;
      return (() {
        return local;
      })();
    };
  }
}

class A {
  var ma;
  A(a) {
    ma = a;
  }
}

class B1 extends A {
  final mfn;
  B1(int a)
      : super(a),
        this.mfn = (() {
          return a;
        }) {}
}

class B2 extends A {
  final mfn;
  B2(int a)
      : super(2),
        this.mfn = (() {
          return a;
        }) {}
}

class B3 extends A {
  final mfn;
  B3(int a)
      : super(() {
          return a;
        }),
        this.mfn = (() {
          return a;
        }) {}
}

typedef void Fisk();

class FunctionTest {
  FunctionTest() {}

  static void testMain() {
    var test = new FunctionTest();
    test.testForEach();
    test.testVarOrder1();
    test.testVarOrder2();
    test.testLexicalClosureRef1();
    test.testLexicalClosureRef2();
    test.testLexicalClosureRef3();
    test.testLexicalClosureRef4();
    test.testLexicalClosureRef5();
    test.testDefaultParametersOrder();
    test.testParametersOrder();
    test.testFunctionDefaults1();
    test.testFunctionDefaults2();
    test.testEscapingFunctions();
    test.testThisBinding();
    test.testFnBindingInStatics();
    test.testFnBindingInInitLists();
    test.testSubclassConstructorScopeAlias();
  }

  void testSubclassConstructorScopeAlias() {
    var b1 = new B1(10);
    Expect.equals(10, (b1.mfn)());
    Expect.equals(10, b1.ma);

    var b2 = new B2(11);
    Expect.equals(11, (b2.mfn)());
    Expect.equals(2, b2.ma);

    var b3 = new B3(12);
    Expect.equals(12, (b3.mfn)());
    Expect.equals(12, (b3.ma)());
  }

  void testFnBindingInInitLists() {
    Expect.equals(1, (new Bug4342163(1).m)());
  }

  void testFnBindingInStatics() {
    StaticFunctionDef.init();
    Expect.equals(1, ((StaticFunctionDef.fn1)()));
    Expect.equals(1, ((StaticFunctionDef.fn2)()));
    Expect.equals(1, ((StaticFunctionDef.fn3)()));
  }

  Fisk testReturnVoidFunction() {
    void f() {}
    Fisk x = f;
    return f;
  }

  void testVarOrder1() {
    var a = 0, b = a++, c = a++;

    Expect.equals(a, 2);
    Expect.equals(b, 0);
    Expect.equals(c, 1);
  }

  void testVarOrder2() {
    var a = 0;
    f() {
      return a++;
    }

    ;
    var b = f(), c = f();

    Expect.equals(a, 2);
    Expect.equals(b, 0);
    Expect.equals(c, 1);
  }

  void testLexicalClosureRef1() {
    var a = 1;
    var f, g;
    {
      var b = 2;
      f = () {
        return b - a;
      };
    }

    {
      var b = 3;
      g = () {
        return b - a;
      };
    }
    Expect.equals(1, f());
    Expect.equals(2, g());
  }

  void testLexicalClosureRef2() {
    var a = 1;
    var f, g;
    {
      var b = 2;
      f = () {
        return (() {
          return b - a;
        })();
      };
    }

    {
      var b = 3;
      g = () {
        return (() {
          return b - a;
        })();
      };
    }
    Expect.equals(1, f());
    Expect.equals(2, g());
  }

  void testLexicalClosureRef3() {
    var a = new List();
    for (int i = 0; i < 10; i++) {
      var x = i;
      a.add(() {
        return x;
      });
    }

    var sum = 0;
    for (int i = 0; i < a.length; i++) {
      sum += (a[i])();
    }

    Expect.equals(45, sum);
  }

  void testLexicalClosureRef5() {
    {
      var a;
      Expect.equals(null, a);
      a = 1;
      Expect.equals(1, a);
    }

    {
      var a;
      Expect.equals(null, a);
      a = 1;
      Expect.equals(1, a);
    }
  }

  // Make sure labels are preserved, and a second 'i' does influence the first.
  void testLexicalClosureRef4() {
    var a = new List();
    x:
    for (int i = 0; i < 10; i++) {
      a.add(() {
        return i;
      });
      continue x;
    }

    var sum = 0;
    for (int i = 0; i < a.length; i++) {
      sum += (a[i])();
    }

    Expect.equals(45, sum);
  }

  int tempField;

  void testForEach() {
    List<int> vals = [1, 2, 3];
    int total = 0;
    vals.forEach((int v) {
      total += v;
    });
    Expect.equals(6, total);
  }

  void testDefaultParametersOrder() {
    f([a = 1, b = 3]) {
      return a - b;
    }

    Expect.equals(-2, f());
  }

  void testParametersOrder() {
    f(a, b) {
      return a - b;
    }

    Expect.equals(-2, f(1, 3));
  }

  void testFunctionDefaults1() {
    // TODO(jimhug): This return null shouldn't be necessary.
    f() {
      return null;
    }

    ;
    (([a = 10]) {
      Expect.equals(10, a);
    })();
    ((a, [b = 10]) {
      Expect.equals(10, b);
    })(1);
    (([a = 10]) {
      Expect.equals(null, a);
    })(f());
    // FAILS: (([a = 10]) { Expect.equals(null ,a); })( f() );
  }

  void testFunctionDefaults2() {
    Expect.equals(10, helperFunctionDefaults2());
    Expect.equals(1, helperFunctionDefaults2(1));
  }

  num helperFunctionDefaults2([a = 10]) {
    return (() {
      return a;
    })();
  }

  void testEscapingFunctions() {
    f() {
      return 42;
    }

    ;
    (() {
      Expect.equals(42, f());
    })();
    var o = new Bug4089219(42);
    Expect.equals(42, (o.f)());
  }

  void testThisBinding() {
    Expect.equals(this, () {
      return this;
    }());
  }
}

typedef void Foo<A, B>(A a, B b);

class Bar<A, B> {
  Foo<A, B> field;
  Bar(A a, B b) : this.field = ((A a1, B b2) {}) {
    field(a, b);
  }
}

typedef UntypedFunction(arg);
typedef UntypedFunction2(arg);

class UseFunctionTypes {
  void test() {
    Function f = null;
    UntypedFunction uf = null;
    UntypedFunction2 uf2 = null;
    Foo foo = null;
    Foo<int, String> fooIntString = null;

    f = uf;
    f = uf2;
    f = foo;
    f = fooIntString;

    uf = f;
    uf2 = f;
    foo = f;
    fooIntString = f;

    foo = fooIntString;
    fooIntString = foo;

    uf = uf2;
    uf2 = uf;
  }
}

main() {
  FunctionTest.testMain();
}
