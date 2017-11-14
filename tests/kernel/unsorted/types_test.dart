// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class TypeTester<T> {
  const TypeTester();
  bool isCorrectType(object) => object is T;
}

class ClosureTypeTester<T> {
  const ClosureTypeTester();
  bool isCorrectType(object) => (() => object is T)();
}

class Base<A, B> {
  final A a;
  final B b;
  const Base(this.a, this.b);
  const factory Base.fac(A a, B b) = Base<A, B>;
}

class Sub1<C, D> extends Base<C, C> {
  final D d;
  const Sub1(C a, this.d) : super(a, a);
  const factory Sub1.fac(C a, D d) = Sub1<C, D>;
}

class Sub2<C, D> extends Base<D, C> {
  const Sub2(C a, D b) : super(b, a);
  const factory Sub2.fac(C a, D b) = Sub2<C, D>;
}

class G<T> {}

class I {}

class A implements I {}

class B extends A {}

class C {}

testConstantLiteralTypes() {
  Expect.isTrue(const [1] is List);
  Expect.isTrue(const [1] is List<int>);
  Expect.isTrue(const [1] is List<String>);
  Expect.isTrue(const <int>[1] is List);
  Expect.isTrue(const <int>[1] is List<int>);
  Expect.isTrue(!(const <int>[1] is List<String>));
  Expect.isTrue(const {"a": 1} is Map);
  Expect.isTrue(const {"a": 1} is Map<String, int>);
  Expect.isTrue(const {"a": 1} is Map<int, String>);
  Expect.isTrue(const <String, int>{"a": 1} is Map);
  Expect.isTrue(const <String, int>{"a": 1} is Map<String, int>);
  Expect.isTrue(!(const <String, int>{"a": 1} is Map<int, String>));
}

testNonConstantLiteralTypes() {
  Expect.isTrue([1] is List);
  Expect.isTrue([1] is List<int>);
  Expect.isTrue([1] is List<String>);
  Expect.isTrue(<int>[1] is List);
  Expect.isTrue(<int>[1] is List<int>);
  Expect.isTrue(!(<int>[1] is List<String>));
}

testParametrizedClass() {
  Expect.isTrue(new Base<int, int>(1, 1) is Base<int, int>);
  Expect.isTrue(new Base<int, int>(1, 1) is Base);
  Expect.isTrue(new Base<int, int>(1, 1) is Base<Object, Object>);
  Expect.isTrue(!(new Base<int, int>(1, 1) is Base<int, String>));
  Expect.isTrue(!(new Base<int, int>(1, 1) is Base<String, int>));
  Expect.isTrue(new Sub1<int, String>(1, "1") is Base<int, int>);
  Expect.isTrue(new Sub1<int, String>(1, "1") is Base);
  Expect.isTrue(new Sub1<int, String>(1, "1") is Sub1<int, String>);
  Expect.isTrue(new Sub1<int, String>(1, "1") is Sub1);
  Expect.isTrue(!(new Sub1<int, String>(1, "1") is Base<String, int>));
  Expect.isTrue(!(new Sub1<int, String>(1, "1") is Base<int, String>));
  Expect.isTrue(!(new Sub1<int, String>(1, "1") is Sub1<String, String>));
  Expect.isTrue(new Sub2<int, String>(1, "1") is Base<String, int>);
  Expect.isTrue(new Sub2<int, String>(1, "1") is Base);
  Expect.isTrue(new Sub2<int, String>(1, "1") is Sub2<int, String>);
  Expect.isTrue(new Sub2<int, String>(1, "1") is Sub2);
  Expect.isTrue(!(new Sub2<int, String>(1, "1") is Base<int, int>));
  Expect.isTrue(!(new Sub2<int, String>(1, "1") is Base<int, String>));
  Expect.isTrue(!(new Sub2<int, String>(1, "1") is Sub2<String, String>));
}

testTypeTester() {
  Expect.isTrue(new TypeTester<int>().isCorrectType(10));
  Expect.isTrue(!new TypeTester<int>().isCorrectType("abc"));
  Expect.isTrue(new TypeTester<List<int>>().isCorrectType([1]));
  Expect.isTrue(new TypeTester<List<int>>().isCorrectType(<int>[1]));
  Expect.isTrue(!new TypeTester<List<int>>().isCorrectType(<String>["1"]));
  Expect.isTrue(new TypeTester<Base<String, int>>()
      .isCorrectType(new Sub2<int, String>(1, "1")));
  Expect.isTrue(new TypeTester<Sub2<int, String>>()
      .isCorrectType(new Sub2<int, String>(1, "1")));
}

testClosureTypeTester() {
  Expect.isTrue(new ClosureTypeTester<int>().isCorrectType(10));
  Expect.isTrue(!new ClosureTypeTester<int>().isCorrectType("abc"));
  Expect.isTrue(new ClosureTypeTester<List<int>>().isCorrectType([1]));
  Expect.isTrue(new ClosureTypeTester<List<int>>().isCorrectType(<int>[1]));
  Expect
      .isTrue(!new ClosureTypeTester<List<int>>().isCorrectType(<String>["1"]));
  Expect.isTrue(new ClosureTypeTester<Base<String, int>>()
      .isCorrectType(new Sub2<int, String>(1, "1")));
  Expect.isTrue(new ClosureTypeTester<Sub2<int, String>>()
      .isCorrectType(new Sub2<int, String>(1, "1")));
}

testConstTypeArguments() {
  Expect.isTrue(const Sub1<int, String>(1, "1") is Sub1<int, String>);
  Expect.isTrue(const Sub1<int, String>.fac(1, "1") is Sub1<int, String>);
  Expect.isTrue(!(const Sub1<int, String>(1, "1") is Sub1<String, String>));
  Expect.isTrue(!(const Sub1<int, String>.fac(1, "1") is Sub1<String, String>));

  Expect.isTrue(const ClosureTypeTester<List<Base<int, String>>>()
      .isCorrectType(
          const <Base<int, String>>[const Base<int, String>(1, "2")]));
  Expect.isTrue(const ClosureTypeTester<List<Base<int, String>>>()
      .isCorrectType(
          const <Base<int, String>>[const Base<int, String>.fac(1, "2")]));
  Expect.isTrue(!const ClosureTypeTester<List<Base<int, String>>>()
      .isCorrectType(
          const <Base<String, String>>[const Base<String, String>("1", "2")]));
  Expect.isTrue(!const ClosureTypeTester<List<Base<int, String>>>()
      .isCorrectType(const <Base<String, String>>[
    const Base<String, String>.fac("1", "2")
  ]));

  Expect.isTrue(const TypeTester<Sub2<int, String>>()
      .isCorrectType(const Sub2<int, String>(1, "1")));
  Expect.isTrue(const TypeTester<Sub2<int, String>>()
      .isCorrectType(const Sub2<int, String>.fac(1, "1")));
  Expect.isTrue(!const TypeTester<Sub2<int, String>>()
      .isCorrectType(const Sub2<String, String>("a", "b")));
  Expect.isTrue(!const TypeTester<Sub2<int, String>>()
      .isCorrectType(const Sub2<String, String>.fac("a", "b")));
}

testNoBound() {
  new G<int>();
  new G<num>();
  new G<Function>();
  new G<Object>();
  new G();
  new G();
  new G<G>();
}

testSubtypeChecker() {
  Expect.isTrue(new TypeTester<num>().isCorrectType(1));
  Expect.isTrue(new TypeTester<num>().isCorrectType(1.0));
  Expect.isTrue(new TypeTester<A>().isCorrectType(new B()));
  Expect.isTrue(new TypeTester<Object>().isCorrectType(new C()));
  Expect.isTrue(new TypeTester<I>().isCorrectType(new A()));
}

testFunctionTypes() {
  fun(int x, String y) => "${x}${y}";
  Expect.isTrue(fun is FunctionType);
  Expect.isTrue(nan is FunctionType);
  Expect.isTrue(nan is Function);
}

num nan(double d, Pattern p) => double.nan;

typedef int FunctionType(num _, Pattern __);

testLiteralTypeArguments() {
  Expect.isTrue(new Foo<String, int>().foo() is List<String>);
  Expect.isTrue(new Foo<int, String>().bar() is Map<int, String>);
}

class Foo<T1, T2> {
  foo() => <T1>[];
  bar() => <T1, T2>{};
}

regressionTest1() {
  Expect.isTrue(!StaticTypeTester.isInt('abc'));
}

class StaticTypeTester<T> {
  static isInt(x) => x is int;
}

main() {
  testConstantLiteralTypes();
  testNonConstantLiteralTypes();
  testParametrizedClass();
  testTypeTester();
  testClosureTypeTester();
  testConstTypeArguments();
  testNoBound();
  testSubtypeChecker();
  testFunctionTypes();
  testLiteralTypeArguments();
  regressionTest1();
}
