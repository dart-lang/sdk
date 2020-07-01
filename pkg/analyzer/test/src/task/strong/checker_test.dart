// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/package_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'strong_test_helper.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CheckerTest);
  });
}

@reflectiveTest
class CheckerTest extends AbstractStrongTest with PackageMixin {
  test_awaitForInCastsStreamElementToVariable() async {
    await checkFile('''
import 'dart:async';

abstract class MyStream<T> extends Stream<T> {
  factory MyStream() => throw 0;
}

main() async {
  // Don't choke if sequence is not stream.
  await for (var i in /*error:FOR_IN_OF_INVALID_TYPE*/1234) {}

  // Dynamic cast.
  await for (String s in new MyStream<dynamic>()) {}

  // Identity cast.
  await for (String s in new MyStream<String>()) {}

  // Untyped.
  await for (var s in new MyStream<String>()) {}

  // Downcast.
  await for (int i in new MyStream<num>()) {}
}
''');
  }

  test_awaitForInCastsSupertypeSequenceToStream() async {
    await checkFile('''
main() async {
  dynamic d;
  await for (var i in d) {}

  Object o;
  await for (var i in o) {}
}
''');
  }

  test_binaryAndIndexOperators() async {
    await checkFile('''
class A {
  A operator *(B b) => null;
  A operator /(B b) => null;
  A operator ~/(B b) => null;
  A operator %(B b) => null;
  A operator +(B b) => null;
  A operator -(B b) => null;
  A operator <<(B b) => null;
  A operator >>(B b) => null;
  A operator &(B b) => null;
  A operator ^(B b) => null;
  A operator |(B b) => null;
  A operator[](B b) => null;
}

class B {
  A operator -(B b) => null;
}

foo() => new A();

test() {
  A a = new A();
  B b = new B();
  var c = foo();
  a = a * b;
  a = a * c;
  a = a / b;
  a = a ~/ b;
  a = a % b;
  a = a + b;
  a = a + /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/a;
  a = a - b;
  b = /*error:INVALID_ASSIGNMENT*/b - b;
  a = a << b;
  a = a >> b;
  a = a & b;
  a = a ^ b;
  a = a | b;
  c = (c + b);

  String x = 'hello';
  int y = 42;
  x = x + x;
  x = x + c;
  x = x + /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/y;

  bool p = true;
  p = p && p;
  p = p && c;
  p = (c) && p;
  p = (c) && c;
  p = /*error:NON_BOOL_OPERAND*/y && p;
  p = c == y;

  a = a[b];
  a = a[c];
  c = (c[b]);
  a[/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/y];
}
''');
  }

  test_callMethodOnFunctions() async {
    await checkFile(r'''
void f(int x) => print(x);
main() {
  f.call(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/'hi');
}
    ''');
  }

  test_castsInConditions() async {
    await checkFile('''
main() {
  bool b = true;
  num x = b ? 1 : 2.3;
  int y = b ? 1 : 2.3;
  String z = !b ? "hello" : null;
  z = b ? null : "hello";
}
''');
  }

  test_castsInConstantContexts() async {
    await checkFile('''
class A {
  static const num n = 3.0;
  // The severe error is from constant evaluation where we know the
  // concrete type.
  static const int i = /*error:VARIABLE_TYPE_MISMATCH*/n;
  final int fi;
  const A(num a) : this.fi = a;
}
class B extends A {
  const B(Object a) : super(a);
}
void foo(Object o) {
  var a = const A(/*error:CONST_WITH_NON_CONSTANT_ARGUMENT*/o);
}
''');
  }

  test_classOverrideOfGrandInterface_interfaceOfAbstractSuperclass() async {
    await checkFile('''
class A {}
class B {}

abstract class I1 {
    m(A a);
}
abstract class Base implements I1 {}

class T1 extends Base {
  /*error:INVALID_OVERRIDE*/m(B a) {}
}
''');
  }

  test_classOverrideOfGrandInterface_interfaceOfConcreteSuperclass() async {
    await checkFile('''
class A {}
class B {}

abstract class I1 {
    m(A a);
}

class /*error:NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER*/Base
    implements I1 {}

class T1 extends Base {
    /*error:INVALID_OVERRIDE*/m(B a) {}
}
''');
  }

  test_classOverrideOfGrandInterface_interfaceOfInterfaceOfChild() async {
    await checkFile('''
class A {}
class B {}

abstract class I1 {
    m(A a);
}
abstract class I2 implements I1 {}

class T1 implements I2 {
  /*error:INVALID_OVERRIDE*/m(B a) {}
}
''');
  }

  test_classOverrideOfGrandInterface_mixinOfInterfaceOfChild() async {
    await checkFile('''
class A {}
class B {}

abstract class M1 {
    m(A a);
}
abstract class I2 extends Object with M1 {}

class T1 implements I2 {
  /*error:INVALID_OVERRIDE*/m(B a) {}
}
''');
  }

  test_classOverrideOfGrandInterface_superclassOfInterfaceOfChild() async {
    await checkFile('''
class A {}
class B {}

abstract class I1 {
    m(A a);
}
abstract class I2 extends I1 {}

class T1 implements I2 {
  /*error:INVALID_OVERRIDE*/m(B a) {}
}
''');
  }

  test_compoundAssignment_returnsDynamic() async {
    await checkFile(r'''
class Foo {
  operator +(other) => null;
}

main() {
  var foo = new Foo();
  foo = foo + 1;
  foo += 1;
}
    ''');
  }

  test_compoundAssignments() async {
    await checkFile('''
class A {
  A operator *(B b) => null;
  A operator /(B b) => null;
  A operator ~/(B b) => null;
  A operator %(B b) => null;
  A operator +(B b) => null;
  A operator -(B b) => null;
  A operator <<(B b) => null;
  A operator >>(B b) => null;
  A operator &(B b) => null;
  A operator ^(B b) => null;
  A operator |(B b) => null;
  D operator [](B index) => null;
  void operator []=(B index, D value) => null;
}

class B {
  A operator -(B b) => null;
}

class D {
  D operator +(D d) => null;
}

class SubA extends A {}
class SubSubA extends SubA {}

foo() => new A();

test() {
  int x = 0;
  x += 5;
  x += /*error:INVALID_ASSIGNMENT*/3.14;

  double y = 0.0;
  y += 5;
  y += 3.14;

  num z = 0;
  z += 5;
  z += 3.14;

  x = x + z;
  x += z;
  y = y + z;
  y += z;

  dynamic w = 42;
  x += w;
  y += w;
  z += w;

  A a = new A();
  B b = new B();
  var c = foo();
  a = a * b;
  a *= b;
  a *= c;
  a /= b;
  a ~/= b;
  a %= b;
  a += b;
  a += /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/a;
  a -= b;
  b -= /*error:INVALID_ASSIGNMENT*/b;
  a <<= b;
  a >>= b;
  a &= b;
  a ^= b;
  a |= b;
  c += b;

  SubA sa;
  sa += b;
  SubSubA ssa = sa += b;

  var d = new D();
  a[b] += d;
  a[c] += d;
  a[/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/z] += d;
  a[b] += c;
  a[b] += /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/z;
  c[b] += d;
}
''');
  }

  @failingTest // See dartbug.com/33440
  test_constantGenericTypeArg_explicit() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26141
    await checkFile('''
abstract class Equality<R> {}
abstract class EqualityBase<R> implements Equality<R> {
  final C<R> c = const C<R>();
  const EqualityBase();
}
class DefaultEquality<S> extends EqualityBase<S> {
  const DefaultEquality();
}
class SetEquality<T> implements Equality<T> {
  final Equality<T> field = const DefaultEquality<T>();
  const SetEquality([Equality<T> inner = const DefaultEquality<T>()]);
}
class C<Q> {
  final List<Q> list = const <Q>[];
  final Map<Q, Iterable<Q>> m =  const <Q, Iterable<Q>>{};
  const C();
}
main() {
  const SetEquality<String>();
}
    ''');
  }

  test_constantGenericTypeArg_infer() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26141
    await checkFile('''
abstract class Equality<Q> {}
abstract class EqualityBase<R> implements Equality<R> {
  final C<R> c = const C();
  const EqualityBase();
}
class DefaultEquality<S> extends EqualityBase<S> {
  const DefaultEquality();
}
class SetEquality<T> implements Equality<T> {
  final Equality<T> field = const DefaultEquality();
  const SetEquality([Equality<T> inner = const DefaultEquality()]);
}
class C<Q> {
  final List<Q> list = const [];
  final Map<Q, Iterable<Q>> m =  const {};
  const C();
}
main() {
  const SetEquality<String>();
}
    ''');
  }

  test_constructorInvalid() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26695
    await checkFile('''
class A {
  B({ /*error:FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR*/this.test: 1.0 }) {}
  final double test = 0.0;
}
''');
  }

  test_constructors() async {
    await checkFile('''
const num z = 25;
Object obj = "world";

class A {
  int x;
  String y;

  A(this.x) : this.y = /*error:FIELD_INITIALIZER_NOT_ASSIGNABLE*/42;

  A.c1(p): this.x = z, this.y = p;

  A.c2(this.x, this.y);

  A.c3(/*error:INVALID_PARAMETER_DECLARATION*/num this.x, String this.y);
}

class B extends A {
  B() : super(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/"hello");

  B.c2(int x, String y) : super.c2(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/y,
                                   /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/x);

  B.c3(num x, Object y) : super.c3(x, y);
}

void main() {
   A a = new A.c2(z, /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/z);
   var b = new B.c2(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/"hello", obj);
}
''');
  }

  test_conversionAndDynamicInvoke() async {
    addFile('''
dynamic toString = (int x) => x + 42;
dynamic hashCode = "hello";
''', name: '/helper.dart');
    await checkFile('''
import 'helper.dart' as helper;

class A {
  String x = "hello world";

  void baz1(y) { x + y; }
  static baz2(y) => y + y;
}

void foo(String str) {
  print(str);
}

class B {
  String toString([int arg]) => arg.toString();
}

void bar(a) {
  foo(a.x);
}

baz() => new B();

typedef DynFun(x);
typedef StrFun(String x);

var bar1 = bar;

void main() {
  var a = new A();
  bar(a);
  (bar1(a));
  var b = bar;
  (b(a));
  var f1 = foo;
  f1("hello");
  dynamic f2 = foo;
  (f2("hello"));
  DynFun f3 = /*error:INVALID_CAST_FUNCTION*/foo;
  (f3("hello"));
  (f3(42));
  StrFun f4 = foo;
  f4("hello");
  a.baz1("hello");
  var b1 = a.baz1;
  (b1("hello"));
  A.baz2("hello");
  var b2 = A.baz2;
  (b2("hello"));

  dynamic a1 = new B();
  (a1.x);
  a1.toString();
  (a1.toString(42));
  var toStringClosure = a1.toString;
  (a1.toStringClosure());
  (a1.toStringClosure(42));
  (a1.toStringClosure("hello"));
  a1.hashCode;

  dynamic toString = () => null;
  (toString());

  (helper.toString());
  var toStringClosure2 = helper.toString;
  (toStringClosure2());
  int hashCode = helper.hashCode;

  baz().toString();
  baz().hashCode;
}
''');
  }

  test_covariantOverride() async {
    await checkFile(r'''
class C {
  num f(num x) => x;
}
class D extends C {
  int f(covariant int x) => x;
}
class E extends D {
  int f(Object x) => x;
}
class F extends E {
  int f(covariant int x) => x;
}
class G extends E implements D {}

class D_error extends C {
  int /*error:INVALID_OVERRIDE*/f(int x) => x;
}
class E_error extends D {
  int /*error:INVALID_OVERRIDE*/f(covariant double x) => 0;
}
class F_error extends E {
  int /*error:INVALID_OVERRIDE*/f(covariant double x) => 0;
}
class G_error extends E implements D {
  int /*error:INVALID_OVERRIDE*/f(covariant double x) => 0;
}
    ''');
  }

  @failingTest
  test_covariantOverride_fields() async {
    await checkFile(r'''
class A {
  get foo => '';
  set foo(_) {}
}

class B extends A {
  covariant num foo;
}
class C extends A {
  covariant num foo;
}
class D extends C {
  int foo;
}
class E extends D {
  num foo;
}
    ''');
  }

  test_covariantOverride_leastUpperBound() async {
    await checkFile(r'''
abstract class Top {}
abstract class Left implements Top {}
abstract class Right implements Top {}
abstract class Bottom implements Left, Right {}

abstract class TakesLeft {
  void m(Left x);
}
abstract class TakesRight {
  void m(Right x);
}
abstract class TakesTop implements TakesLeft, TakesRight {
  void m(Top x); // works today
}
abstract class TakesBottom implements TakesLeft, TakesRight {
  // LUB(Left, Right) == Top, so this is an implicit cast from Top to Bottom.
  void m(covariant Bottom x);
}
    ''');
  }

  test_covariantOverride_markerIsInherited() async {
    await checkFile(r'''
class C {
  num f(covariant num x) => x;
}
class D extends C {
  int f(int x) => x;
}
class E extends D {
  int f(Object x) => x;
}
class F extends E {
  int f(int x) => x;
}
class G extends E implements D {}

class D_error extends C {
  int /*error:INVALID_OVERRIDE*/f(String x) => 0;
}
class E_error extends D {
  int /*error:INVALID_OVERRIDE*/f(double x) => 0;
}
class F_error extends E {
  int /*error:INVALID_OVERRIDE*/f(double x) => 0;
}
class G_error extends E implements D {
  int /*error:INVALID_OVERRIDE*/f(double x) => 0;
}
    ''');
  }

  test_dynamicInvocation() {
    return checkFile(r'''
typedef dynamic A(dynamic x);
class B {
  int call(int x) => x;
  bool col(bool x) => x;
}
void main() {
  {
    B f = new B();
    int x;
    bool y;
    x = f(3);
    x = /*error:INVALID_ASSIGNMENT*/f.col(true);
    y = /*error:INVALID_ASSIGNMENT*/f(3);
    y = f.col(true);
    f(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/true);
    f.col(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/3);
  }
  {
    Function f = new B();
    int x;
    bool y;
    x = f(3);
    x = f./*error:UNDEFINED_METHOD*/col(true);
    y = f(3);
    y = f./*error:UNDEFINED_METHOD*/col(true);
    f(true);
    // Through type propagation, we know f is actually a B, hence the
    // hint.
    f./*error:UNDEFINED_METHOD*/col(3);
  }
  {
    A f = /*error:INVALID_ASSIGNMENT*/new B();
    B b = new B();
    f = /* error:INVALID_ASSIGNMENT*/b;
    int x;
    bool y;
    x = f(3);
    y = f(3);
    f(true);
  }
  {
    dynamic g = new B();
    g.call(true);
    g.col(true);
    g.foo(true);
    g.x;
    A f = /* error:INVALID_ASSIGNMENT*/new B();
    B b = new B();
    f = /*error:INVALID_ASSIGNMENT*/b;
    f./*error:UNDEFINED_METHOD*/col(true);
    f./*error:UNDEFINED_METHOD*/foo(true);
    f./*error:UNDEFINED_GETTER*/x;
  }
}
''');
  }

  test_factoryConstructorDowncast() async {
    await checkFile(r'''
class Animal {
  Animal();
  factory Animal.cat() => new Cat();
}

class Cat extends Animal {}

void main() {
  Cat c = new Animal.cat();
  c = /*error:INVALID_CAST_NEW_EXPR*/new Animal();
}''');
  }

  test_fieldFieldOverride() async {
    await checkFile('''
class A {}
class B extends A {}
class C extends B {}

class Base {
  B f1;
  B f2;
  B f3;
  B f4;
}

class Child extends Base {
  A /*error:INVALID_OVERRIDE*/f1; // invalid for getter
  C /*error:INVALID_OVERRIDE*/f2; // invalid for setter
  var f3;
  dynamic /*error:INVALID_OVERRIDE*/f4;
}

class Child2 implements Base {
  A /*error:INVALID_OVERRIDE*/f1; // invalid for getter
  C /*error:INVALID_OVERRIDE*/f2; // invalid for setter
  var f3;
  dynamic /*error:INVALID_OVERRIDE*/f4;
}
''');
  }

  test_fieldGetterOverride() async {
    await checkFile('''
class A {}
class B extends A {}
class C extends B {}

abstract class Base {
  B f1;
  B f2;
  B f3;
  B f4;
}

class Child extends Base {
  A get /*error:INVALID_OVERRIDE*/f1 => null;
  C get f2 => null;
  get f3 => null;
  dynamic get /*error:INVALID_OVERRIDE*/f4 => null;
}

class /*error:NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER*/Child2 implements Base {
  A get /*error:INVALID_OVERRIDE*/f1 => null;
  C get f2 => null;
  get f3 => null;
  dynamic get /*error:INVALID_OVERRIDE*/f4 => null;
}
''');
  }

  test_fieldOverride() async {
    await checkFile('''
typedef void ToVoid<T>(T x);
class F {
  final ToVoid<dynamic> f = null;
  final ToVoid<int> g = null;
}

class G extends F {
  final ToVoid<int> /*error:INVALID_OVERRIDE*/f = null;
  final ToVoid<dynamic> g = null;
}

class H implements F {
  final ToVoid<int> /*error:INVALID_OVERRIDE*/f = null;
  final ToVoid<dynamic> g = null;
}
 ''');
  }

  test_fieldSetterOverride() async {
    await checkFile('''
class A {}
class B extends A {}
class C extends B {}

class Base {
  B f1;
  B f2;
  B f3;
  B f4;
  B f5;
}

class Child extends Base {
  B get f1 => null;
  B get f2 => null;
  B get f3 => null;
  B get f4 => null;
  B get f5 => null;

  void set f1(A value) {}
  void set /*error:INVALID_OVERRIDE*/f2(C value) {}
  void set f3(value) {}
  void set f4(dynamic value) {}
  set f5(B value) {}
}

class Child2 implements Base {
  B get f1 => null;
  B get f2 => null;
  B get f3 => null;
  B get f4 => null;
  B get f5 => null;

  void set f1(A value) {}
  void set /*error:INVALID_OVERRIDE*/f2(C value) {}
  void set f3(value) {}
  void set f4(dynamic value) {}
  set f5(B value) {}
}
''');
  }

  test_forInCastsIterateElementToVariable() async {
    await checkFile('''
main() {
  // Don't choke if sequence is not iterable.
  for (var i in /*error:FOR_IN_OF_INVALID_TYPE*/1234) {}

  // Dynamic cast.
  for (String s in <dynamic>[]) {}

  // Identity cast.
  for (String s in <String>[]) {}

  // Untyped.
  for (var s in <String>[]) {}

  // Downcast.
  for (int i in <num>[]) {}
}
''');
  }

  test_forInCastsSupertypeSequenceToIterate() async {
    await checkFile('''
main() {
  dynamic d;
  for (var i in d) {}

  Object o;
  for (var i in o) {}
}
''');
  }

  test_forLoopVariable() async {
    await checkFile('''
foo() {
  for (int i = 0; i < 10; i++) {
    i = /*error:INVALID_ASSIGNMENT*/"hi";
  }
}
bar() {
  for (var i = 0; i < 10; i++) {
    int j = i + 1;
  }
}
''');
  }

  test_functionModifiers_async() async {
    await checkFile('''
import 'dart:async';
import 'dart:math' show Random;

dynamic x;

foo1() async => x;
Future foo2() async => x;
Future<int> foo3() async => x;
Future<int> foo4() async => new Future<int>.value(x);
Future<int> foo5() async =>
    /*error:RETURN_OF_INVALID_TYPE*/new Future<String>.value(
        x);

bar1() async { return x; }
Future bar2() async { return x; }
Future<int> bar3() async { return x; }
Future<int> bar4() async {
  return new Future<int>.value(x);
}
Future<int> bar5() async {
  return /*error:RETURN_OF_INVALID_TYPE*/new Future<String>.value(
      x);
}

int y;
Future<int> z;

baz() async {
  int a = await x;
  int b = await y;
  int c = await z;
  String d = /*error:INVALID_ASSIGNMENT*/await z;
}

Future<bool> get issue_ddc_264 async {
  await 42;
  if (new Random().nextBool()) {
    return true;
  } else {
    return new Future<bool>.value(false);
  }
}


Future<String> issue_sdk_26404() async {
  return ((1 > 0) ? new Future<String>.value('hello') : "world");
}
''');
  }

  test_functionTypingAndSubtyping_classes() async {
    await checkFile('''
class A {}
class B extends A {}

typedef A Top(B x);   // Top of the lattice
typedef B Left(B x);  // Left branch
typedef B Left2(B x); // Left branch
typedef A Right(A x); // Right branch
typedef B Bot(A x);   // Bottom of the lattice

B left(B x) => x;
B bot_(A x) => x;
B bot(A x) => x as B;
A top(B x) => x;
A right(A x) => x;

void main() {
  { // Check typedef equality
    Left f = left;
    Left2 g = f;
  }
  {
    Top f;
    f = top;
    f = left;
    f = right;
    f = bot;
  }
  {
    Left f;
    f = /*error:INVALID_CAST_FUNCTION*/top;
    f = left;
    f = /*error:INVALID_ASSIGNMENT*/right;
    f = bot;
  }
  {
    Right f;
    f = /*error:INVALID_CAST_FUNCTION*/top;
    f = /*error:INVALID_ASSIGNMENT*/left;
    f = right;
    f = bot;
  }
  {
    Bot f;
    f = /*error:INVALID_CAST_FUNCTION*/top;
    f = /*error:INVALID_CAST_FUNCTION*/left;
    f = /*error:INVALID_CAST_FUNCTION*/right;
    f = bot;
  }
}
''');
  }

  test_functionTypingAndSubtyping_dynamic() async {
    await checkFile('''
class A {}

typedef dynamic Top(Null x);     // Top of the lattice
typedef dynamic Left(A x);          // Left branch
typedef A Right(Null x);         // Right branch
typedef A Bottom(A x);              // Bottom of the lattice

void main() {
  Top top;
  Left left;
  Right right;
  Bottom bot;
  {
    Top f;
    f = top;
    f = left;
    f = right;
    f = bot;
  }
  {
    Left f;
    f = top;
    f = left;
    f = /*error:INVALID_ASSIGNMENT*/right;
    f = bot;
  }
  {
    Right f;
    f = top;
    f = /*error:INVALID_ASSIGNMENT*/left;
    f = right;
    f = bot;
  }
  {
    Bottom f;
    f = top;
    f = left;
    f = right;
    f = bot;
  }
}
''');
  }

  test_functionTypingAndSubtyping_dynamic_knownFunctions() async {
    // Our lattice should look like this:
    //
    //
    //           Bot -> Top
    //          /        \
    //      A -> Top    Bot -> A
    //       /     \      /
    // Top -> Top   A -> A
    //         \      /
    //         Top -> A
    //
    // Note that downcasts of known functions are promoted to
    // static type errors, since they cannot succeed.
    // This makes some of what look like downcasts turn into
    // type errors below.
    await checkFile('''
class A {}

typedef dynamic BotTop(Null x);
typedef dynamic ATop(A x);
typedef A BotA(Null x);
typedef A AA(A x);
typedef A TopA(Object x);
typedef dynamic TopTop(Object x);

dynamic aTop(A x) => x;
A aa(A x) => x;
dynamic topTop(dynamic x) => x;
A topA(dynamic x) => x;
void apply<T>(T f0, T f1, T f2,
                  T f3, T f4, T f5) {}
void main() {
  BotTop botTop;
  BotA botA;
  {
    BotTop f;
    f = topA;
    f = topTop;
    f = aa;
    f = aTop;
    f = botA;
    f = botTop;
    apply<BotTop>(
        topA,
        topTop,
        aa,
        aTop,
        botA,
        botTop
                      );
    apply<BotTop>(
        (dynamic x) => new A(),
        (dynamic x) => (x as Object),
        (A x) => x,
        (A x) => null,
        botA,
        botTop
                      );
  }
  {
    ATop f;
    f = topA;
    f = topTop;
    f = aa;
    f = aTop;
    f = /*error:INVALID_ASSIGNMENT*/botA;
    f = botTop;
    apply<ATop>(
        topA,
        topTop,
        aa,
        aTop,
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/botA,
        botTop
                    );
    apply<ATop>(
        (dynamic x) => new A(),
        (dynamic x) => (x as Object),
        (A x) => x,
        (A x) => null,
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/botA,
        botTop
                    );
  }
  {
    BotA f;
    f = topA;
    f = /*error:INVALID_ASSIGNMENT*/topTop;
    f = aa;
    f = /*error:INVALID_ASSIGNMENT*/aTop;
    f = botA;
    f = botTop;
    apply<BotA>(
        topA,
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/topTop,
        aa,
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/aTop,
        botA,
        botTop
                    );
    apply<BotA>(
        (dynamic x) => new A(),
        (dynamic x) => (x as Object),
        (A x) => x,
        (A x) => (/*info:UNNECESSARY_CAST*/x as Object),
        botA,
        botTop
                    );
  }
  {
    AA f;
    f = topA;
    f = /*error:INVALID_ASSIGNMENT*/topTop;
    f = aa;
    f = /*error:INVALID_CAST_FUNCTION*/aTop; // known function
    f = botA;
    f = botTop;
    apply<AA>(
        topA,
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/topTop,
        aa,
        /*error:INVALID_CAST_FUNCTION*/aTop, // known function
        botA,
        botTop
                  );
    apply<AA>(
        (dynamic x) => new A(),
        (dynamic x) => (x as Object),
        (A x) => x,
        (A x) => (/*info:UNNECESSARY_CAST*/x as Object), // known function
        botA,
        botTop
                  );
  }
  {
    TopTop f;
    f = topA;
    f = topTop;
    f = /*error:INVALID_ASSIGNMENT*/aa;
    f = /*error:INVALID_CAST_FUNCTION*/aTop; // known function
    f = /*error:INVALID_ASSIGNMENT*/botA;
    f = botTop;
    apply<TopTop>(
        topA,
        topTop,
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/aa,
        /*error:INVALID_CAST_FUNCTION*/aTop, // known function
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/botA,
        botTop
                      );
    apply<TopTop>(
        (dynamic x) => new A(),
        (dynamic x) => (x as Object),
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/(A x) => x,
        /*error:INVALID_CAST_FUNCTION_EXPR*/(A x) => (/*info:UNNECESSARY_CAST*/x as Object), // known function
        /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/botA,
        botTop
                      );
  }
  {
    TopA f;
    f = topA;
    f = /*error:INVALID_CAST_FUNCTION*/topTop; // known function
    f = /*error:INVALID_CAST_FUNCTION*/aa; // known function
    f = /*error:INVALID_CAST_FUNCTION*/aTop; // known function
    f = botA;
    f = botTop;
    apply<TopA>(
        topA,
        /*error:INVALID_CAST_FUNCTION*/topTop, // known function
        /*error:INVALID_CAST_FUNCTION*/aa, // known function
        /*error:INVALID_CAST_FUNCTION*/aTop, // known function
        botA,
        botTop
                    );
    apply<TopA>(
        (dynamic x) => new A(),
        (dynamic x) => (x as Object), // known function
        /*error:INVALID_CAST_FUNCTION_EXPR*/(A x) => x, // known function
        /*error:INVALID_CAST_FUNCTION_EXPR*/(A x) => (/*info:UNNECESSARY_CAST*/x as Object), // known function
        botA,
        botTop
                    );
  }
}
''');
  }

  test_functionTypingAndSubtyping_functionLiteralVariance() async {
    await checkFile('''
class A {}
class B extends A {}

typedef T Function2<S, T>(S z);

A top(B x) => x;
B left(B x) => x;
A right(A x) => x;
B bot(A x) => x as B;

void main() {
  {
    Function2<B, A> f;
    f = top;
    f = left;
    f = right;
    f = bot;
  }
  {
    Function2<B, B> f; // left
    f = /*error:INVALID_CAST_FUNCTION*/top;
    f = left;
    f = /*error:INVALID_ASSIGNMENT*/right;
    f = bot;
  }
  {
    Function2<A, A> f; // right
    f = /*error:INVALID_CAST_FUNCTION*/top;
    f = /*error:INVALID_ASSIGNMENT*/left;
    f = right;
    f = bot;
  }
  {
    Function2<A, B> f;
    f = /*error:INVALID_CAST_FUNCTION*/top;
    f = /*error:INVALID_CAST_FUNCTION*/left;
    f = /*error:INVALID_CAST_FUNCTION*/right;
    f = bot;
  }
}
''');
  }

  test_functionTypingAndSubtyping_functionVariableVariance() async {
    await checkFile('''
class A {}
class B extends A {}

typedef T Function2<S, T>(S z);

void main() {
  {
    Function2<B, A> top;
    Function2<B, B> left;
    Function2<A, A> right;
    Function2<A, B> bot;

    top = right;
    top = bot;
    top = top;
    top = left;

    left = top;
    left = left;
    left = /*error:INVALID_ASSIGNMENT*/right;
    left = bot;

    right = top;
    right = /*error:INVALID_ASSIGNMENT*/left;
    right = right;
    right = bot;

    bot = top;
    bot = left;
    bot = right;
    bot = bot;
  }
}
''');
  }

  test_functionTypingAndSubtyping_higherOrderFunctionLiteral1() async {
    await checkFile('''
class A {}
class B extends A {}

typedef T Function2<S, T>(S z);

typedef A BToA(B x);  // Top of the base lattice
typedef B AToB(A x);  // Bot of the base lattice

BToA top(AToB f) => f;
AToB left(AToB f) => f;
BToA right(BToA f) => f;
AToB bot_(BToA f) => f;
AToB bot(BToA f) => f as AToB;

void main() {
  {
    Function2<AToB, BToA> f; // Top
    f = top;
    f = left;
    f = right;
    f = bot;
  }
  {
    Function2<AToB, AToB> f; // Left
    f = /*error:INVALID_CAST_FUNCTION*/top;
    f = left;
    f = /*error:INVALID_ASSIGNMENT*/right;
    f = bot;
  }
  {
    Function2<BToA, BToA> f; // Right
    f = /*error:INVALID_CAST_FUNCTION*/top;
    f = /*error:INVALID_ASSIGNMENT*/left;
    f = right;
    f = bot;
  }
  {
    Function2<BToA, AToB> f; // Bot
    f = bot;
    f = /*error:INVALID_CAST_FUNCTION*/left;
    f = /*error:INVALID_CAST_FUNCTION*/top;
    f = /*error:INVALID_CAST_FUNCTION*/right;
  }
}
''');
  }

  test_functionTypingAndSubtyping_higherOrderFunctionLiteral2() async {
    await checkFile('''
class A {}
class B extends A {}

typedef T Function2<S, T>(S z);

typedef A BToA(B x);  // Top of the base lattice
typedef B AToB(A x);  // Bot of the base lattice

Function2<B, A> top(AToB f) => f;
Function2<A, B> left(AToB f) => f;
Function2<B, A> right(BToA f) => f;
Function2<A, B> bot_(BToA f) => f;
Function2<A, B> bot(BToA f) => f as Function2<A, B>;

void main() {
  {
    Function2<AToB, BToA> f; // Top
    f = top;
    f = left;
    f = right;
    f = bot;
  }
  {
    Function2<AToB, AToB> f; // Left
    f = /*error:INVALID_CAST_FUNCTION*/top;
    f = left;
    f = /*error:INVALID_ASSIGNMENT*/right;
    f = bot;
  }
  {
    Function2<BToA, BToA> f; // Right
    f = /*error:INVALID_CAST_FUNCTION*/top;
    f = /*error:INVALID_ASSIGNMENT*/left;
    f = right;
    f = bot;
  }
  {
    Function2<BToA, AToB> f; // Bot
    f = bot;
    f = /*error:INVALID_CAST_FUNCTION*/left;
    f = /*error:INVALID_CAST_FUNCTION*/top;
    f = /*error:INVALID_CAST_FUNCTION*/right;
  }
}
''');
  }

  test_functionTypingAndSubtyping_higherOrderFunctionLiteral3() async {
    await checkFile('''
class A {}
class B extends A {}

typedef T Function2<S, T>(S z);

typedef A BToA(B x);  // Top of the base lattice
typedef B AToB(A x);  // Bot of the base lattice

BToA top(Function2<A, B> f) => f;
AToB left(Function2<A, B> f) => f;
BToA right(Function2<B, A> f) => f;
AToB bot_(Function2<B, A> f) => f;
AToB bot(Function2<B, A> f) => f as AToB;

void main() {
  {
    Function2<AToB, BToA> f; // Top
    f = top;
    f = left;
    f = right;
    f = bot;
  }
  {
    Function2<AToB, AToB> f; // Left
    f = /*error:INVALID_CAST_FUNCTION*/top;
    f = left;
    f = /*error:INVALID_ASSIGNMENT*/right;
    f = bot;
  }
  {
    Function2<BToA, BToA> f; // Right
    f = /*error:INVALID_CAST_FUNCTION*/top;
    f = /*error:INVALID_ASSIGNMENT*/left;
    f = right;
    f = bot;
  }
  {
    Function2<BToA, AToB> f; // Bot
    f = bot;
    f = /*error:INVALID_CAST_FUNCTION*/left;
    f = /*error:INVALID_CAST_FUNCTION*/top;
    f = /*error:INVALID_CAST_FUNCTION*/right;
  }
}
''');
  }

  test_functionTypingAndSubtyping_higherOrderFunctionVariables() async {
    await checkFile('''
class A {}
class B extends A {}

typedef T Function2<S, T>(S z);

void main() {
  {
    Function2<Function2<A, B>, Function2<B, A>> top;
    Function2<Function2<B, A>, Function2<B, A>> right;
    Function2<Function2<A, B>, Function2<A, B>> left;
    Function2<Function2<B, A>, Function2<A, B>> bot;

    top = right;
    top = bot;
    top = top;
    top = left;

    left = top;
    left = left;
    left =
        /*error:INVALID_ASSIGNMENT*/right;
    left = bot;

    right = top;
    right =
        /*error:INVALID_ASSIGNMENT*/left;
    right = right;
    right = bot;

    bot = top;
    bot = left;
    bot = right;
    bot = bot;
  }
}
''');
  }

  test_functionTypingAndSubtyping_instanceMethodVariance() async {
    await checkFile('''
class A {}
class B extends A {}

class C {
  A top(B x) => x;
  B left(B x) => x;
  A right(A x) => x;
  B bot(A x) => x as B;
}

typedef T Function2<S, T>(S z);

void main() {
  C c = new C();
  {
    Function2<B, A> f;
    f = c.top;
    f = c.left;
    f = c.right;
    f = c.bot;
  }
  {
    Function2<B, B> f;
    f = c.top;
    f = c.left;
    f = /*error:INVALID_ASSIGNMENT*/c.right;
    f = c.bot;
  }
  {
    Function2<A, A> f;
    f = c.top;
    f = /*error:INVALID_ASSIGNMENT*/c.left;
    f = c.right;
    f = c.bot;
  }
  {
    Function2<A, B> f;
    f = c.top;
    f = c.left;
    f = c.right;
    f = c.bot;
  }
}
''');
  }

  test_functionTypingAndSubtyping_intAndObject() async {
    await checkFile('''
typedef Object Top(int x);      // Top of the lattice
typedef int Left(int x);        // Left branch
typedef int Left2(int x);       // Left branch
typedef Object Right(Object x); // Right branch
typedef int Bot(Object x);      // Bottom of the lattice

Object globalTop(int x) => x;
int globalLeft(int x) => x;
Object globalRight(Object x) => x;
int bot_(Object x) => x;
int globalBot(Object x) => x as int;

void main() {
  // Note: use locals so we only know the type, not that it's a specific
  // function declaration. (we can issue better errors in that case.)
  var top = globalTop;
  var left = globalLeft;
  var right = globalRight;
  var bot = globalBot;

  { // Check typedef equality
    Left f = left;
    Left2 g = f;
  }
  {
    Top f;
    f = top;
    f = left;
    f = right;
    f = bot;
  }
  {
    Left f;
    f = top;
    f = left;
    f = /*error:INVALID_ASSIGNMENT*/right;
    f = bot;
  }
  {
    Right f;
    f = top;
    f = /*error:INVALID_ASSIGNMENT*/left;
    f = right;
    f = bot;
  }
  {
    Bot f;
    f = top;
    f = left;
    f = right;
    f = bot;
  }
}
''');
  }

  test_functionTypingAndSubtyping_namedAndOptionalParameters() async {
    await checkFile('''
class A {}

typedef A FR(A x);
typedef A FO([A x]);
typedef A FN({A x});
typedef A FRR(A x, A y);
typedef A FRO(A x, [A y]);
typedef A FRN(A x, {A n});
typedef A FOO([A x, A y]);
typedef A FNN({A x, A y});
typedef A FNNN({A z, A y, A x});

void main() {
   FR r;
   FO o;
   FN n;
   FRR rr;
   FRO ro;
   FRN rn;
   FOO oo;
   FNN nn;
   FNNN nnn;

   r = r;
   r = o;
   r = /*error:INVALID_ASSIGNMENT*/n;
   r = /*error:INVALID_ASSIGNMENT*/rr;
   r = ro;
   r = rn;
   r = oo;
   r = /*error:INVALID_ASSIGNMENT*/nn;
   r = /*error:INVALID_ASSIGNMENT*/nnn;

   o = r;
   o = o;
   o = /*error:INVALID_ASSIGNMENT*/n;
   o = /*error:INVALID_ASSIGNMENT*/rr;
   o = /*error:INVALID_ASSIGNMENT*/ro;
   o = /*error:INVALID_ASSIGNMENT*/rn;
   o = oo;
   o = /*error:INVALID_ASSIGNMENT*/nn;
   o = /*error:INVALID_ASSIGNMENT*/nnn;

   n = /*error:INVALID_ASSIGNMENT*/r;
   n = /*error:INVALID_ASSIGNMENT*/o;
   n = n;
   n = /*error:INVALID_ASSIGNMENT*/rr;
   n = /*error:INVALID_ASSIGNMENT*/ro;
   n = /*error:INVALID_ASSIGNMENT*/rn;
   n = /*error:INVALID_ASSIGNMENT*/oo;
   n = nn;
   n = nnn;

   rr = /*error:INVALID_ASSIGNMENT*/r;
   rr = /*error:INVALID_ASSIGNMENT*/o;
   rr = /*error:INVALID_ASSIGNMENT*/n;
   rr = rr;
   rr = ro;
   rr = /*error:INVALID_ASSIGNMENT*/rn;
   rr = oo;
   rr = /*error:INVALID_ASSIGNMENT*/nn;
   rr = /*error:INVALID_ASSIGNMENT*/nnn;

   ro = r;
   ro = /*error:INVALID_ASSIGNMENT*/o;
   ro = /*error:INVALID_ASSIGNMENT*/n;
   ro = rr;
   ro = ro;
   ro = /*error:INVALID_ASSIGNMENT*/rn;
   ro = oo;
   ro = /*error:INVALID_ASSIGNMENT*/nn;
   ro = /*error:INVALID_ASSIGNMENT*/nnn;

   rn = r;
   rn = /*error:INVALID_ASSIGNMENT*/o;
   rn = /*error:INVALID_ASSIGNMENT*/n;
   rn = /*error:INVALID_ASSIGNMENT*/rr;
   rn = /*error:INVALID_ASSIGNMENT*/ro;
   rn = rn;
   rn = /*error:INVALID_ASSIGNMENT*/oo;
   rn = /*error:INVALID_ASSIGNMENT*/nn;
   rn = /*error:INVALID_ASSIGNMENT*/nnn;

   oo = r;
   oo = o;
   oo = /*error:INVALID_ASSIGNMENT*/n;
   oo = rr;
   oo = ro;
   oo = /*error:INVALID_ASSIGNMENT*/rn;
   oo = oo;
   oo = /*error:INVALID_ASSIGNMENT*/nn;
   oo = /*error:INVALID_ASSIGNMENT*/nnn;

   nn = /*error:INVALID_ASSIGNMENT*/r;
   nn = /*error:INVALID_ASSIGNMENT*/o;
   nn = n;
   nn = /*error:INVALID_ASSIGNMENT*/rr;
   nn = /*error:INVALID_ASSIGNMENT*/ro;
   nn = /*error:INVALID_ASSIGNMENT*/rn;
   nn = /*error:INVALID_ASSIGNMENT*/oo;
   nn = nn;
   nn = nnn;

   nnn = /*error:INVALID_ASSIGNMENT*/r;
   nnn = /*error:INVALID_ASSIGNMENT*/o;
   nnn = n;
   nnn = /*error:INVALID_ASSIGNMENT*/rr;
   nnn = /*error:INVALID_ASSIGNMENT*/ro;
   nnn = /*error:INVALID_ASSIGNMENT*/rn;
   nnn = /*error:INVALID_ASSIGNMENT*/oo;
   nnn = nn;
   nnn = nnn;
}
''');
  }

  test_functionTypingAndSubtyping_objectsWithCallMethods() async {
    await checkFile('''
typedef int I2I(int x);
typedef num N2N(num x);
class A {
   int call(int x) => x;
}
class B {
   num call(num x) => x;
}
int i2i(int x) => x;
num n2n(num x) => x;
void main() {
   {
     I2I f;
     f = new A();
     f = /*error:INVALID_ASSIGNMENT*/new B();
     f = i2i;
     f = /*error:INVALID_ASSIGNMENT*/n2n;
     f = /*info:UNNECESSARY_CAST*/i2i as Object;
     f = /*info:UNNECESSARY_CAST*/n2n as Function;
   }
   {
     N2N f;
     f = /*error:INVALID_ASSIGNMENT*/new A();
     f = new B();
     f = /*error:INVALID_ASSIGNMENT*/i2i;
     f = n2n;
     f = /*info:UNNECESSARY_CAST*/i2i as Object;
     f = /*info:UNNECESSARY_CAST*/n2n as Function;
   }
   {
     A f;
     f = new A();
     f = /*error:INVALID_ASSIGNMENT*/new B();
     f = /*error:INVALID_ASSIGNMENT*/i2i;
     f = /*error:INVALID_ASSIGNMENT*/n2n;
     f = /*info:UNNECESSARY_CAST*/i2i as Object;
     f = /*info:UNNECESSARY_CAST,error:INVALID_ASSIGNMENT*/n2n as Function;
   }
   {
     B f;
     f = /*error:INVALID_ASSIGNMENT*/new A();
     f = new B();
     f = /*error:INVALID_ASSIGNMENT*/i2i;
     f = /*error:INVALID_ASSIGNMENT*/n2n;
     f = /*info:UNNECESSARY_CAST*/i2i as Object;
     f = /*info:UNNECESSARY_CAST,error:INVALID_ASSIGNMENT*/n2n as Function;
   }
   {
     Function f;
     f = new A();
     f = new B();
     f = i2i;
     f = n2n;
     f = /*info:UNNECESSARY_CAST*/i2i as Object;
     f = /*info:UNNECESSARY_CAST*/n2n as Function;
   }
}
''');
  }

  test_functionTypingAndSubtyping_staticMethodVariance() async {
    await checkFile('''
class A {}
class B extends A {}

class C {
  static A top(B x) => x;
  static B left(B x) => x;
  static A right(A x) => x;
  static B bot(A x) => x as B;
}

typedef T Function2<S, T>(S z);

void main() {
  {
    Function2<B, A> f;
    f = C.top;
    f = C.left;
    f = C.right;
    f = C.bot;
  }
  {
    Function2<B, B> f;
    f = /*error:INVALID_CAST_METHOD*/C.top;
    f = C.left;
    f = /*error:INVALID_ASSIGNMENT*/C.right;
    f = C.bot;
  }
  {
    Function2<A, A> f;
    f = /*error:INVALID_CAST_METHOD*/C.top;
    f = /*error:INVALID_ASSIGNMENT*/C.left;
    f = C.right;
    f = C.bot;
  }
  {
    Function2<A, B> f;
    f = /*error:INVALID_CAST_METHOD*/C.top;
    f = /*error:INVALID_CAST_METHOD*/C.left;
    f = /*error:INVALID_CAST_METHOD*/C.right;
    f = C.bot;
  }
}
''');
  }

  test_functionTypingAndSubtyping_subtypeOfUniversalType() async {
    await checkFile('''
void main() {
  nonGenericFn(x) => null;
  {
    R f<P, R>(P p) => null;
    T g<S, T>(S s) => null;

    var local = f;
    local = g; // valid

    // Non-generic function cannot subtype a generic one.
    local = /*error:INVALID_ASSIGNMENT*/(x) => null;
    local = /*error:INVALID_ASSIGNMENT*/nonGenericFn;
  }
  {
    Iterable<R> f<P, R>(List<P> p) => null;
    List<T> g<S, T>(Iterable<S> s) => null;

    var local = f;
    local = g; // valid

    var local2 = g;
    local = local2;
    local2 = /*error:INVALID_CAST_FUNCTION*/f;
    local2 = local;

    // Non-generic function cannot subtype a generic one.
    local = /*error:INVALID_ASSIGNMENT*/(x) => null;
    local = /*error:INVALID_ASSIGNMENT*/nonGenericFn;
  }
}
''');
  }

  test_functionTypingAndSubtyping_uninferredClosure() async {
    await checkFile('''
typedef num Num2Num(num x);
void main() {
  Num2Num g = /*error:INVALID_ASSIGNMENT*/(int x) { return x; };
  print(g(42));
}
''');
  }

  test_functionTypingAndSubtyping_void() async {
    await checkFile('''
class A {
  void bar() => null;
  void foo() => bar(); // allowed
}
''');
  }

  test_genericClassMethodOverride() async {
    await checkFile('''
class A {}
class B extends A {}

class Base<T extends B> {
  T foo() => null;
}

class Derived<S extends A> extends Base<B> {
  S /*error:INVALID_OVERRIDE*/foo() => null;
}

class Derived2<S extends B> extends Base<B> {
  S foo() => null;
}
''');
  }

  test_genericFunctionWrongNumberOfArguments() async {
    await checkFile(r'''
T foo<T>(T x, T y) => x;
T bar<T>({T x, T y}) => x;

main() {
  String x;
  // resolving these shouldn't crash.
  foo/*error:EXTRA_POSITIONAL_ARGUMENTS*/(1, 2, 3);
  x = foo/*error:EXTRA_POSITIONAL_ARGUMENTS*/('1', '2', '3');
  foo/*error:NOT_ENOUGH_POSITIONAL_ARGUMENTS*/(1);
  x = foo/*error:NOT_ENOUGH_POSITIONAL_ARGUMENTS*/('1');
  x = foo/*error:EXTRA_POSITIONAL_ARGUMENTS*/(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/1, /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/2, 3);
  x = foo/*error:NOT_ENOUGH_POSITIONAL_ARGUMENTS*/(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/1);

  // named arguments
  bar(y: 1, x: 2, /*error:UNDEFINED_NAMED_PARAMETER*/z: 3);
  x = bar(/*error:UNDEFINED_NAMED_PARAMETER*/z: '1', x: '2', y: '3');
  bar(y: 1);
  x = bar(x: '1', /*error:UNDEFINED_NAMED_PARAMETER*/z: 42);
  x = bar(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/y: 1, /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/x: 2, /*error:UNDEFINED_NAMED_PARAMETER*/z: 3);
  x = bar(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/x: 1);
}
''');
  }

  test_genericMethodOverride() async {
    await checkFile('''
class Future<T> {
  S then<S>(S onValue(T t)) => null;
}

class DerivedFuture<T> extends Future<T> {
  S then<S>(S onValue(T t)) => null;
}

class DerivedFuture2<A> extends Future<A> {
  B then<B>(B onValue(A a)) => null;
}

class DerivedFuture3<T> extends Future<T> {
  S then<S>(Object onValue(T t)) => null;
}

class DerivedFuture4<A> extends Future<A> {
  B then<B>(Object onValue(A a)) => null;
}
''');
  }

  test_genericMethodSuper() async {
    await checkFile(r'''
class A<T> {
  A<S> create<S extends T>() => new A<S>();
}
class B extends A {
  A<S> create<S>() => super.create<S>();
}
class C extends A {
  A<S> create<S>() => super.create();
}
class D extends A<num> {
  A<S> create<S extends num>() => super.create<S>();
}
class E extends A<num> {
  A<S> create<S extends num>() => /*error:RETURN_OF_INVALID_TYPE*/super.create<int>();
}
class F extends A<num> {
  create2<S>() => super.create</*error:TYPE_ARGUMENT_NOT_MATCHING_BOUNDS*/S>();
}
    ''');
  }

  test_genericMethodSuperSubstitute() async {
    await checkFile(r'''
class Cloneable<T> {}
class G<T> {
  create<A extends Cloneable<T>, B extends Iterable<A>>() => null;
}
class H extends G<num> {
  create2() => super.create<Cloneable<int>, List<Cloneable<int>>>();
}
    ''');
  }

  test_getterGetterOverride() async {
    await checkFile('''
class A {}
class B extends A {}
class C extends B {}

abstract class Base {
  B get f1;
  B get f2;
  B get f3;
  B get f4;
}

class Child extends Base {
  A get /*error:INVALID_OVERRIDE*/f1 => null;
  C get f2 => null;
  get f3 => null;
  dynamic get /*error:INVALID_OVERRIDE*/f4 => null;
}
''');
  }

  test_getterOverride() async {
    await checkFile('''
typedef void ToVoid<T>(T x);

class F {
  ToVoid<dynamic> get f => null;
  ToVoid<int> get g => null;
}

class G extends F {
  ToVoid<int> get /*error:INVALID_OVERRIDE*/f => null;
  ToVoid<dynamic> get g => null;
}

class H implements F {
  ToVoid<int> get /*error:INVALID_OVERRIDE*/f => null;
  ToVoid<dynamic> get g => null;
}
''');
  }

  test_ifForDoWhileStatementsUseBooleanConversion() async {
    await checkFile('''
main() {
  dynamic dyn = 42;
  Object obj = 42;
  int i = 42;
  bool b = false;

  if (b) {}
  if (dyn) {}
  if (obj) {}
  if (/*error:NON_BOOL_CONDITION*/i) {}

  while (b) {}
  while (dyn) {}
  while (obj) {}
  while (/*error:NON_BOOL_CONDITION*/i) {}

  do {} while (b);
  do {} while (dyn);
  do {} while (obj);
  do {} while (/*error:NON_BOOL_CONDITION*/i);

  for (;b;) {}
  for (;dyn;) {}
  for (;obj;) {}
  for (;/*error:NON_BOOL_CONDITION*/i;) {}
}
''');
  }

  test_implicitCasts_assignment() async {
    addFile('num n; int i; void main() { i = n;}//yy');
    await check();

    addFile(
        'num n; int i; void main() { i = /*error:INVALID_ASSIGNMENT*/n;}//ny');
    await check(implicitCasts: false);
  }

  test_implicitCasts_compoundAssignment() async {
    addFile('''f(num n, int i) {
               i += n;}//yy''');
    await check();

    addFile('''f(num n, int i) {
               i += /*error:INVALID_ASSIGNMENT*/n;}//ny''');
    await check(implicitCasts: false);
  }

  test_implicitCasts_constructorInitializer() async {
    addFile('class A { int i; A(num n) : i = n;}//yy');
    await check();

    addFile(
        'class A { int i; A(num n) : i = /*error:FIELD_INITIALIZER_NOT_ASSIGNABLE*/n;}//ny');
    await check(implicitCasts: false);
  }

  test_implicitCasts_defaultValue() async {
    addFile('''const num n = 0;
               f({int i = n}) => i;//yy''');
    await check();

    addFile('''const num n = 0;
               f({int i = /*error:INVALID_ASSIGNMENT*/n}) => i;//ny''');
    await check(implicitCasts: false);
  }

  test_implicitCasts_fieldInitializer() async {
    addFile('class A { static num n; int i = n;}//yy');
    await check();

    addFile(
        'class A { static num n; int i = /*error:INVALID_ASSIGNMENT*/n;}//nn');
    await check(implicitCasts: false);
  }

  test_implicitCasts_forEach() async {
    addFile(r'''
main(dynamic a) {
  for (int v in a) {
    v;
  }
}
''');
    await check();

    addFile(r'''
main(dynamic a) {
  for (int v in /*error:FOR_IN_OF_INVALID_ELEMENT_TYPE*/a) {
    v;
  }
}
''');
    await check(implicitCasts: false);
  }

  test_implicitCasts_forEach_async() async {
    addFile(r'''
main(dynamic a) async {
  await for (int v in a) {
    v;
  }
}
''');
    await check();

    addFile(r'''
main(dynamic a) async {
  await for (int v in /*error:FOR_IN_OF_INVALID_ELEMENT_TYPE*/a) {
    v;
  }
}
''');
    await check(implicitCasts: false);
  }

  test_implicitCasts_functionCall() async {
    addFile('''num n;
               f(int i) => i;
               var i = f(n);//yy''');
    await check();

    addFile('''num n;
             f(int i) => i;
             var i = f(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/n);//nn''');
    await check(implicitCasts: false);
  }

  test_implicitCasts_genericMethods() async {
    addFile('''
var x = <String>[].map<String>((x) => "");
''');
    await check(implicitCasts: false);
  }

  test_implicitCasts_initializer() async {
    addFile('num n; int i = n;//yy');
    await check();

    addFile('num n; int i = /*error:INVALID_ASSIGNMENT*/n;//nn');
    await check(implicitCasts: false);
  }

  test_implicitCasts_numericOps() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26912
    addFile(r'''
void f() {
  int x = 0;
  int y = 0;
  x += y;
}
    ''');
    await check(implicitCasts: false);
  }

  test_implicitCasts_operator() async {
    addFile('''num n;
             int i;
             var r = i & n;//yy''');
    await check();

    addFile('''num n;
             int i;
             var r = i & /*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/n;//nn''');
    await check(implicitCasts: false);
  }

  test_implicitCasts_return() async {
    addFile('int f(num n) => n;//yy');
    await check();

    addFile('int f(num n) => /*error:RETURN_OF_INVALID_TYPE*/n;//nn');
    await check(implicitCasts: false);
  }

  test_implicitCasts_return_async() async {
    addFile(r'''
import 'dart:async';

Future<List<String>> foo() async {
  List<Object> x = <Object>["hello", "world"];
  return x;
}
    ''');
    await check();
  }

  test_implicitDynamic_field() async {
    addFile(r'''
class C {
  var /*error:IMPLICIT_DYNAMIC_FIELD*/x0;
  var /*error:IMPLICIT_DYNAMIC_FIELD*/x1 = (<dynamic>[])[0];
  var /*error:IMPLICIT_DYNAMIC_FIELD*/x2,
      x3 = 42,
      /*error:IMPLICIT_DYNAMIC_FIELD*/x4;
  dynamic y0;
  dynamic y1 = (<dynamic>[])[0];
}
    ''');
    await check(implicitDynamic: false);
  }

  test_implicitDynamic_function() async {
    addFile(r'''
T a<T>(T t) => t;
T b<T>() => null;

void main<S>() {
  dynamic d;
  int i;
  /*error:IMPLICIT_DYNAMIC_FUNCTION*/a(d);
  a(42);
  /*error:IMPLICIT_DYNAMIC_FUNCTION*/b();
  d = /*error:IMPLICIT_DYNAMIC_FUNCTION*/b();
  i = b();

  void f<T>(T t) {};
  T g<T>() => null;

  /*error:IMPLICIT_DYNAMIC_FUNCTION*/f(d);
  f(42);
  /*error:IMPLICIT_DYNAMIC_FUNCTION*/g();
  d = /*error:IMPLICIT_DYNAMIC_FUNCTION*/g();
  i = g();

  /*error:IMPLICIT_DYNAMIC_INVOKE*/(<T>(T t) => t)(d);
  (<T>(T t) => t)(42);
  (<T>() => /*info:UNNECESSARY_CAST*/null as T)<int>();
}
    ''');
    await check(implicitDynamic: false);
  }

  test_implicitDynamic_listLiteral() async {
    addFile(r'''

var l0 = /*error:IMPLICIT_DYNAMIC_LIST_LITERAL*/[];
List l1 = /*error:IMPLICIT_DYNAMIC_LIST_LITERAL*/[];
List<dynamic> l2 = /*error:IMPLICIT_DYNAMIC_LIST_LITERAL*/[];
dynamic d = 42;
var l3 = /*error:IMPLICIT_DYNAMIC_LIST_LITERAL*/[d, d];

var l4 = <dynamic>[];
var l5 = <int>[];
List<int> l6 = [];
var l7 = [42];
    ''');
    await check(implicitDynamic: false);
  }

  test_implicitDynamic_mapLiteral() async {
    addFile(r'''
var m0 = /*error:IMPLICIT_DYNAMIC_MAP_LITERAL*/{};
Map m1 = /*error:IMPLICIT_DYNAMIC_MAP_LITERAL*/{};
Map<dynamic, dynamic> m2 = /*error:IMPLICIT_DYNAMIC_MAP_LITERAL*/{};
dynamic d = 42;
var m3 = /*error:IMPLICIT_DYNAMIC_MAP_LITERAL*/{d: d};
var m4 = /*error:IMPLICIT_DYNAMIC_MAP_LITERAL*/{'x': d, 'y': d};
var m5 = /*error:IMPLICIT_DYNAMIC_MAP_LITERAL*/{d: 'x'};

var m6 = <dynamic, dynamic>{};
var m7 = <String, String>{};
Map<String, String> m8 = {};
var m9 = {'hi': 'there'};
    ''');
    await check(implicitDynamic: false);
  }

  test_implicitDynamic_method() async {
    addFile(r'''
class C {
  T m<T>(T s) => s;
  T n<T>() => null;
}
class D<E> {
  T m<T>(T s) => s;
  T n<T>() => null;
}
void f() {
  dynamic d;
  int i;
  new C()./*error:IMPLICIT_DYNAMIC_METHOD*/m(d);
  new C().m(42);
  new C()./*error:IMPLICIT_DYNAMIC_METHOD*/n();
  d = new C()./*error:IMPLICIT_DYNAMIC_METHOD*/n();
  i = new C().n();

  new D<int>()./*error:IMPLICIT_DYNAMIC_METHOD*/m(d);
  new D<int>().m(42);
  new D<int>()./*error:IMPLICIT_DYNAMIC_METHOD*/n();
  d = new D<int>()./*error:IMPLICIT_DYNAMIC_METHOD*/n();
  i = new D<int>().n();
}
    ''');
    await check(implicitDynamic: false);
  }

  test_implicitDynamic_parameter() async {
    addFile(r'''
const dynamic DYNAMIC_VALUE = 42;

// simple formal
void f0(/*error:IMPLICIT_DYNAMIC_PARAMETER*/x) {}
void f1(dynamic x) {}

// default formal
void df0([/*error:IMPLICIT_DYNAMIC_PARAMETER*/x = DYNAMIC_VALUE]) {}
void df1([dynamic x = DYNAMIC_VALUE]) {}

// https://github.com/dart-lang/sdk/issues/25794
void df2([/*error:IMPLICIT_DYNAMIC_PARAMETER*/x = 42]) {}

// default formal (named)
void nf0({/*error:IMPLICIT_DYNAMIC_PARAMETER*/x: DYNAMIC_VALUE}) {}
void nf1({dynamic x: DYNAMIC_VALUE}) {}

// https://github.com/dart-lang/sdk/issues/25794
void nf2({/*error:IMPLICIT_DYNAMIC_PARAMETER*/x: 42}) {}

// field formal
class C {
  var /*error:IMPLICIT_DYNAMIC_FIELD*/x;
  C(this.x);
}

// function typed formal
void ftf0(void x(/*error:IMPLICIT_DYNAMIC_PARAMETER*/y)) {}
void ftf1(void x(int y)) {}
    ''');
    await check(implicitDynamic: false);
  }

  test_implicitDynamic_return() async {
    addFile(r'''
// function
/*error:IMPLICIT_DYNAMIC_RETURN*/f0() {return f0();}
dynamic f1() { return 42; }

// nested function
void main() {
  /*error:IMPLICIT_DYNAMIC_RETURN*/g0() {return g0();}
  dynamic g1() { return 42; }
}

// methods
class B {
  int m1() => 42;
}
class C extends B {
  /*error:IMPLICIT_DYNAMIC_RETURN*/m0() => 123;
  m1() => 123;
  dynamic m2() => 'hi';
}

// accessors
set x(int value) {}
get /*error:IMPLICIT_DYNAMIC_RETURN*/y0 => 42;
dynamic get y1 => 42;

// function typed formals
void ftf0(/*error:IMPLICIT_DYNAMIC_RETURN*/f(int x)) {}
void ftf1(dynamic f(int x)) {}

// function expressions
var fe0 = (int x) => x as dynamic;
var fe1 = (int x) => x;
    ''');
    await check(implicitDynamic: false);
  }

  test_implicitDynamic_static() async {
    addFile(r'''
class C {
  static void test(int body()) {}
}

void main() {
  C.test(()  {
    return 42;
  });
}
''');
    await check(implicitDynamic: false);
  }

  test_implicitDynamic_type() async {
    addFile(r'''
class C<T> {}
class M1<T extends /*error:IMPLICIT_DYNAMIC_TYPE*/List> {}
class M2<T> {}
class I<T> {}
class D<T, S> extends /*error:IMPLICIT_DYNAMIC_TYPE*/C
    with M1, /*error:IMPLICIT_DYNAMIC_TYPE*/M2
    implements /*error:IMPLICIT_DYNAMIC_TYPE*/I {}
class D2<T, S> = /*error:IMPLICIT_DYNAMIC_TYPE*/C
    with M1, /*error:IMPLICIT_DYNAMIC_TYPE*/M2
    implements /*error:IMPLICIT_DYNAMIC_TYPE*/I;

C f(D d) {
  D x = new /*error:IMPLICIT_DYNAMIC_TYPE*/D();
  D<int, dynamic> y = new /*error:IMPLICIT_DYNAMIC_TYPE*/D();
  D<dynamic, int> z = new /*error:IMPLICIT_DYNAMIC_TYPE*/D();
  return new /*error:IMPLICIT_DYNAMIC_TYPE*/C();
}

class A<T extends num> {}
class N1<T extends List<int>> {}
class N2<T extends Object> {}
class J<T extends Object> {}
class B<T extends Object> extends A with N1, N2 implements J {}
A g(B b) {
  B y = new B();
  return new A();
}
    ''');
    await check(implicitDynamic: false);
  }

  test_implicitDynamic_variable() async {
    addFile(r'''
var /*error:IMPLICIT_DYNAMIC_VARIABLE*/x0;
var /*error:IMPLICIT_DYNAMIC_VARIABLE*/x1 = (<dynamic>[])[0];
var /*error:IMPLICIT_DYNAMIC_VARIABLE*/x2,
    x3 = 42,
    /*error:IMPLICIT_DYNAMIC_VARIABLE*/x4;
dynamic y0;
dynamic y1 = (<dynamic>[])[0];
    ''');
    await check(implicitDynamic: false);
  }

  test_interfaceOverridesAreAllChecked() {
    // Regression test for https://github.com/dart-lang/sdk/issues/29766
    return checkFile(r'''
class B {
  set x(int y) {}
}
class C {
  set x(Object y) {}
}
class D implements B, C {
  int /*error:INVALID_OVERRIDE*/x;
}
    ''');
  }

  test_interfacesFromMixinsAreChecked() {
    // Regression test for https://github.com/dart-lang/sdk/issues/29782
    return checkFile(r'''
abstract class I {
  set x(int v);
}
abstract class M implements I {}

class C extends Object with M {
  String /*error:INVALID_OVERRIDE*/x;
}

abstract class M2 = Object with M;

class C2 extends Object with M2 {
  String /*error:INVALID_OVERRIDE*/x;
}
    ''');
  }

  test_interfacesFromMixinsOnlyConsiderMostDerivedMember() {
    // Regression test for dart2js interface pattern in strong mode.
    return checkFile(r'''
abstract class I1 { num get x; }
abstract class I2 extends I1 { int get x; }

class M1 { num get x => 0; }
class M2 { int get x => 0; }

class Base extends Object with M1 implements I1 {}
class Child extends Base with M2 implements I2 {}

class C extends Object with M1, M2 implements I1, I2 {}
    ''');
  }

  test_interfacesFromMixinsUsedTwiceAreChecked() {
    // Regression test for https://github.com/dart-lang/sdk/issues/29782
    return checkFile(r'''
abstract class I<E> {
  set x(E v);
}
abstract class M<E> implements I<E> {}

class C extends Object with M<int> {
  String /*error:INVALID_OVERRIDE*/x;
}

abstract class D extends Object with M<num> {}
/*error:CONFLICTING_GENERIC_INTERFACES*/
/*error:CONFLICTING_GENERIC_INTERFACES*/class E extends D with M<int> {
  int /*error:INVALID_OVERRIDE*/x;
}
/*error:CONFLICTING_GENERIC_INTERFACES*/
/*error:CONFLICTING_GENERIC_INTERFACES*/class F extends D with M<int> {
  num x;
}
    ''');
  }

  test_invalidOverrides_baseClassOverrideToChildInterface() async {
    await checkFile('''
class A {}
class B {}

abstract class I {
    m(A a);
}

class Base {
    m(B a) {}
}

class /*error:INCONSISTENT_INHERITANCE*/T1
    extends Base implements I {}
''');
  }

  test_invalidOverrides_childOverride() async {
    await checkFile('''
class A {}
class B {}

class Base {
    A f;
}

class T1 extends Base {
  B get /*error:INVALID_OVERRIDE, error:GETTER_NOT_ASSIGNABLE_SETTER_TYPES*/f => null;
}

class T2 extends Base {
  set /*error:INVALID_OVERRIDE, error:GETTER_NOT_ASSIGNABLE_SETTER_TYPES*/f(
      B b) => null;
}

class T3 extends Base {
  final B
      /*error:FINAL_NOT_INITIALIZED, error:INVALID_OVERRIDE, error:GETTER_NOT_ASSIGNABLE_SETTER_TYPES*/f;
}
class T4 extends Base {
  // two: one for the getter one for the setter.
  B /*error:INVALID_OVERRIDE, error:INVALID_OVERRIDE*/f;
}

class /*error:NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER*/T5 implements Base {
  /**/B get /*error:INVALID_OVERRIDE, error:GETTER_NOT_ASSIGNABLE_SETTER_TYPES*/f => null;
}

class /*error:NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER*/T6 implements Base {
  set /*error:INVALID_OVERRIDE, error:GETTER_NOT_ASSIGNABLE_SETTER_TYPES*/f(B b) => null;
}

class /*error:NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER*/T7 implements Base {
  final B /*error:INVALID_OVERRIDE, error:GETTER_NOT_ASSIGNABLE_SETTER_TYPES*/f = null;
}
class T8 implements Base {
  // two: one for the getter one for the setter.
  B /*error:INVALID_OVERRIDE, error:INVALID_OVERRIDE*/f;
}
''');
  }

  test_invalidOverrides_childOverride2() async {
    await checkFile('''
class A {}
class B {}

class Base {
    m(A a) {}
}

class Test extends Base {
  /*error:INVALID_OVERRIDE*/m(B a) {}
}
''');
  }

  test_invalidOverrides_classOverrideOfInterface() async {
    await checkFile('''
class A {}
class B {}

abstract class I {
    m(A a);
}

class T1 implements I {
  /*error:INVALID_OVERRIDE*/m(B a) {}
}
''');
  }

  test_invalidOverrides_doubleOverride() async {
    await checkFile('''
class A {}
class B {}

class Grandparent {
    m(A a) {}
}
class Parent extends Grandparent {
    m(A a) {}
}

class Test extends Parent {
    // Reported only once
    /*error:INVALID_OVERRIDE*/m(B a) {}
}
''');
  }

  test_invalidOverrides_doubleOverride2() async {
    await checkFile('''
class A {}
class B {}

class Grandparent {
    m(A a) {}
}
class Parent extends Grandparent {
  /*error:INVALID_OVERRIDE*/m(B a) {}
}

class Test extends Parent {
    m(B a) {}
}
''');
  }

  test_invalidOverrides_grandChildOverride() async {
    await checkFile('''
class A {}
class B {}

class Grandparent {
    m(A a) {}
    int x;
}
class Parent extends Grandparent {
}

class Test extends Parent {
    /*error:INVALID_OVERRIDE*/m(B a) {}
    int x;
}
''');
  }

  test_invalidOverrides_mixinOverrideOfInterface() async {
    await checkFile('''
class A {}
class B {}

abstract class I {
    m(A a);
}

class M {
    m(B a) {}
}

class /*error:INCONSISTENT_INHERITANCE*/T1
    extends Object with M
    implements I {}

class /*error:INCONSISTENT_INHERITANCE*/U1 = Object
    with M implements I;
''');
  }

  test_invalidOverrides_mixinOverrideToBase() async {
    await checkFile('''
class A {}
class B {}

class Base {
    m(A a) {}
    int x;
}

class M1 {
    m(B a) {}
}

class M2 {
    int x;
}

class T1 extends Base with /*error:INVALID_OVERRIDE*/M1 {}
class T2 extends Base with /*error:INVALID_OVERRIDE*/M1, M2 {}
class T3 extends Base with M2, /*error:INVALID_OVERRIDE*/M1 {}

class U1 = Base with /*error:INVALID_OVERRIDE*/M1;
class U2 = Base with /*error:INVALID_OVERRIDE*/M1, M2;
class U3 = Base with M2, /*error:INVALID_OVERRIDE*/M1;
''');
  }

  test_invalidOverrides_mixinOverrideToMixin() async {
    await checkFile('''
class A {}
class B {}

class Base {
}

class M1 {
    m(B a) {}
    int x;
}

class M2 {
    m(A a) {}
    int x;
}

class T1 extends Base with M1, /*error:INVALID_OVERRIDE*/M2 {}

class U1 = Base with M1, /*error:INVALID_OVERRIDE*/M2;
''');
  }

  @failingTest
  test_invalidOverrides_noDuplicateMixinOverride() async {
    // This is a regression test for a bug in an earlier implementation were
    // names were hiding errors if the first mixin override looked correct,
    // but subsequent ones did not.
    await checkFile('''
class A {}
class B {}

class Base {
    m(A a) {}
}

class M1 {
    m(A a) {}
}

class M2 {
    m(B a) {}
}

class M3 {
    m(B a) {}
}

class /*error:INCONSISTENT_INHERITANCE*/T1 extends Base
    with M1, /*error:INVALID_OVERRIDE_FROM_MIXIN*/M2, M3 {}

class /*error:INCONSISTENT_INHERITANCE*/U1 = Base
    with M1, /*error:INVALID_OVERRIDE_FROM_MIXIN*/M2, M3;
''');
  }

  test_invalidOverrides_noErrorsIfSubclassCorrectlyOverrideBaseAndInterface() async {
    // This is a case were it is incorrect to say that the base class
    // incorrectly overrides the interface.
    await checkFile('''
class A {}
class B {}

class Base {
  void m(A a) {}
}

class I1 {
  void m(B a) {}
}

class /*error:INCONSISTENT_INHERITANCE*/T1
    extends Base
    implements I1 {}

class T2 extends Base implements I1 {
  void m(dynamic a) {}
}

class /*error:INCONSISTENT_INHERITANCE*/T3
    extends Object with Base
    implements I1 {}

class /*error:INCONSISTENT_INHERITANCE*/U3
    = Object with Base
    implements I1;

class T4 extends Object with Base implements I1 {
  void m(dynamic a) {}
}
''');
  }

  test_invalidRuntimeChecks() async {
    await checkFile('''
typedef int I2I(int x);
typedef int D2I(x);
typedef int II2I(int x, int y);
typedef int DI2I(x, int y);
typedef int ID2I(int x, y);
typedef int DD2I(x, y);

typedef I2D(int x);
typedef D2D(x);
typedef II2D(int x, int y);
typedef DI2D(x, int y);
typedef ID2D(int x, y);
typedef DD2D(x, y);

int foo(int x) => x;
int bar(int x, int y) => x + y;

void main() {
  bool b;
  b = foo is I2I;
  b = foo is D2I;
  b = foo is I2D;
  b = foo is D2D;

  b = bar is II2I;
  b = bar is DI2I;
  b = bar is ID2I;
  b = bar is II2D;
  b = bar is DD2I;
  b = bar is DI2D;
  b = bar is ID2D;
  b = bar is DD2D;

  // For as, the validity of checks is deferred to runtime.
  Function f;
  f = /*info:UNNECESSARY_CAST*/foo as I2I;
  f = foo as D2I;
  f = /*info:UNNECESSARY_CAST*/foo as I2D;
  f = foo as D2D;

  f = /*info:UNNECESSARY_CAST*/bar as II2I;
  f = bar as DI2I;
  f = bar as ID2I;
  f = /*info:UNNECESSARY_CAST*/bar as II2D;
  f = bar as DD2I;
  f = bar as DI2D;
  f = bar as ID2D;
  f = bar as DD2D;
}
''');
  }

  test_leastUpperBounds() async {
    await checkFile('''
typedef T Returns<T>();

// regression test for https://github.com/dart-lang/sdk/issues/26094
class A <S extends Returns<S>, T extends Returns<T>> {
  int test(bool b) {
    S s;
    T t;
    if (b) {
      return /*error:RETURN_OF_INVALID_TYPE*/b ? s : t;
    } else {
      return /*error:RETURN_OF_INVALID_TYPE*/s ?? t;
    }
  }
}

class B<S, T extends S> {
  T t;
  S s;
  int test(bool b) {
    return /*error:RETURN_OF_INVALID_TYPE*/b ? t : s;
  }
}

class C {
  // Check that the least upper bound of two types with the same
  // class but different type arguments produces the pointwise
  // least upper bound of the type arguments
  int test1(bool b) {
    List<int> li;
    List<double> ld;
    return /*error:RETURN_OF_INVALID_TYPE*/b ? li : ld;
  }
  // TODO(leafp): This case isn't handled yet.  This test checks
  // the case where two related classes are instantiated with related
  // but different types.
  Iterable<num> test2(bool b) {
    List<int> li;
    Iterable<double> id;
    int x = b ? li : id;
    return b ? li : id;
  }
}
''');
  }

  test_list_ifElement_dynamicCondition_disableImplicitCasts() async {
    addFile(r'''
dynamic c;
void main() {
  <int>[if (/*error:NON_BOOL_CONDITION*/c) 0];
}
''');
    await check(implicitCasts: false);
  }

  test_list_ifElement_dynamicCondition_implicitCasts() async {
    addFile(r'''
dynamic c;
void main() {
  <int>[if (c) 0];
}
''');
    await check();
  }

  test_list_ifElement_falseBranch_dynamic_disableImplicitCasts() async {
    addFile(r'''
bool c;
dynamic dyn;
void main() {
  <int>[if (c) 0 else /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/dyn];
}
''');
    await check(implicitCasts: false);
  }

  test_list_ifElement_falseBranch_dynamic_implicitCasts() async {
    addFile(r'''
bool c;
dynamic dyn;
void main() {
  <int>[if (c) 0 else dyn];
}
''');
    await check();
  }

  test_list_ifElement_falseBranch_supertype_disableImplicitCasts() async {
    addFile(r'''
bool c;
num someNum;
void main() {
  <int>[if (c) 0 else /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/someNum];
}
''');
    await check(implicitCasts: false);
  }

  test_list_ifElement_falseBranch_supertype_implicitCasts() async {
    addFile(r'''
bool c;
num someNum;
void main() {
  <int>[if (c) 0 else someNum];
}
''');
    await check();
  }

  test_list_ifElement_objectCondition_disableImplicitCasts() async {
    addFile(r'''
Object c;
void main() {
  <int>[if (/*error:NON_BOOL_CONDITION*/c) 0];
}
''');
    await check(implicitCasts: false);
  }

  test_list_ifElement_objectCondition_implicitCasts() async {
    addFile(r'''
Object c;
void main() {
  <int>[if (c) 0];
}
''');
    await check();
  }

  test_list_ifElement_trueBranch_dynamic_disableImplicitCasts() async {
    addFile(r'''
bool c;
dynamic dyn;
void main() {
  <int>[if (c) /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/dyn];
}
''');
    await check(implicitCasts: false);
  }

  test_list_ifElement_trueBranch_dynamic_implicitCasts() async {
    addFile(r'''
bool c;
dynamic dyn;
void main() {
  <int>[if (c) dyn];
}
''');
    await check();
  }

  test_list_ifElement_trueBranch_supertype_disableImplicitCasts() async {
    addFile(r'''
bool c;
num someNum;
void main() {
  <int>[if (c) /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/someNum];
}
''');
    await check(implicitCasts: false);
  }

  test_list_ifElement_trueBranch_supertype_implicitCasts() async {
    addFile(r'''
bool c;
num someNum;
void main() {
  <int>[if (c) someNum];
}
''');
    await check();
  }

  test_loadLibrary() async {
    addFile('''library lib1;''', name: '/lib1.dart');
    await checkFile(r'''
import 'lib1.dart' deferred as lib1;
import 'dart:async' show Future;
main() {
  Future f = lib1.loadLibrary();
}''');
  }

  test_map_ifElement_dynamicCondition_disableImplicitCasts() async {
    addFile(r'''
dynamic c;
void main() {
  <int, int>{if (/*error:NON_BOOL_CONDITION*/c) 0: 0};
}
''');
    await check(implicitCasts: false);
  }

  test_map_ifElement_dynamicCondition_implicitCasts() async {
    addFile(r'''
dynamic c;
void main() {
  <int, int>{if (c) 0: 0};
}
''');
    await check();
  }

  test_map_ifElement_falseBranch_dynamicKey_disableImplicitCasts() async {
    addFile(r'''
bool c;
dynamic dyn;
void main() {
  <int, int>{if (c) 0:0 else /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/dyn:0};
}
''');
    await check(implicitCasts: false);
  }

  test_map_ifElement_falseBranch_dynamicKey_implicitCasts() async {
    addFile(r'''
bool c;
dynamic dyn;
void main() {
  <int, int>{if (c) 0:0 else dyn:0};
}
''');
    await check();
  }

  test_map_ifElement_falseBranch_dynamicValue_disableImplicitCasts() async {
    addFile(r'''
bool c;
dynamic dyn;
void main() {
  <int, int>{if (c) 0:0 else 0:/*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/dyn};
}
''');
    await check(implicitCasts: false);
  }

  test_map_ifElement_falseBranch_dynamicValue_implicitCasts() async {
    addFile(r'''
bool c;
dynamic dyn;
void main() {
  <int, int>{if (c) 0:0 else 0:dyn};
}
''');
    await check();
  }

  test_map_ifElement_falseBranch_supertypeKey_disableImplicitCasts() async {
    addFile(r'''
bool c;
num someNum;
void main() {
  <int, int>{if (c) 0:0 else /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/someNum:0};
}
''');
    await check(implicitCasts: false);
  }

  test_map_ifElement_falseBranch_supertypeKey_implicitCasts() async {
    addFile(r'''
bool c;
num someNum;
void main() {
  <int, int>{if (c) 0:0 else someNum:0};
}
''');
    await check();
  }

  test_map_ifElement_falseBranch_supertypeValue_disableImplicitCasts() async {
    addFile(r'''
bool c;
num someNum;
void main() {
  <int, int>{if (c) 0:0 else 0:/*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/someNum};
}
''');
    await check(implicitCasts: false);
  }

  test_map_ifElement_falseBranch_supertypeValue_implicitCasts() async {
    addFile(r'''
bool c;
num someNum;
void main() {
  <int, int>{if (c) 0:0 else 0:someNum};
}
''');
    await check();
  }

  test_map_ifElement_objectCondition_disableImplicitCasts() async {
    addFile(r'''
Object c;
void main() {
  <int, int>{if (/*error:NON_BOOL_CONDITION*/c) 0: 0};
}
''');
    await check(implicitCasts: false);
  }

  test_map_ifElement_objectCondition_implicitCasts() async {
    addFile(r'''
Object c;
void main() {
  <int, int>{if (c) 0: 0};
}
''');
    await check();
  }

  test_map_ifElement_trueBranch_dynamicKey_disableImplicitCasts() async {
    addFile(r'''
bool c;
dynamic dyn;
void main() {
  <int, int>{if (c) /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/dyn:0 else 0:0};
}
''');
    await check(implicitCasts: false);
  }

  test_map_ifElement_trueBranch_dynamicKey_implicitCasts() async {
    addFile(r'''
bool c;
dynamic dyn;
void main() {
  <int, int>{if (c) dyn:0 else 0:0};
}
''');
    await check();
  }

  test_map_ifElement_trueBranch_dynamicValue_disableImplicitCasts() async {
    addFile(r'''
bool c;
dynamic dyn;
void main() {
  <int, int>{if (c) 0:/*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/dyn else 0:0};
}
''');
    await check(implicitCasts: false);
  }

  test_map_ifElement_trueBranch_dynamicValue_implicitCasts() async {
    addFile(r'''
bool c;
dynamic dyn;
void main() {
  <int, int>{if (c) 0:dyn else 0:0};
}
''');
    await check();
  }

  test_map_ifElement_trueBranch_supertypeKey_disableImplicitCasts() async {
    addFile(r'''
bool c;
num someNum;
void main() {
  <int, int>{if (c) /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/someNum:0 else 0:0};
}
''');
    await check(implicitCasts: false);
  }

  test_map_ifElement_trueBranch_supertypeKey_implicitCasts() async {
    addFile(r'''
bool c;
num someNum;
void main() {
  <int, int>{if (c) someNum:0 else 0:0};
}
''');
    await check();
  }

  test_map_ifElement_trueBranch_supertypeValue_disableImplicitCasts() async {
    addFile(r'''
bool c;
num someNum;
void main() {
  <int, int>{if (c) 0:/*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/someNum else 0:0};
}
''');
    await check(implicitCasts: false);
  }

  test_map_ifElement_trueBranch_supertypeValue_implicitCasts() async {
    addFile(r'''
bool c;
num someNum;
void main() {
  <int, int>{if (c) 0:someNum else 0:0};
}
''');
    await check();
  }

  test_methodOverride() async {
    await checkFile('''
class A {}
class B extends A {}
class C extends B {}

class Base {
  B m1(B a) => null;
  B m2(B a) => null;
  B m3(B a) => null;
  B m4(B a) => null;
  B m5(B a) => null;
  B m6(B a) => null;
}

class Child extends Base {
  A /*error:INVALID_OVERRIDE*/m1(A value) => null;
  C /*error:INVALID_OVERRIDE*/m2(C value) => null;
  A /*error:INVALID_OVERRIDE*/m3(C value) => null;
  C m4(A value) => null;
  m5(value) => null;
  dynamic /*error:INVALID_OVERRIDE*/m6(dynamic value) => null;
}
''');
  }

  test_methodOverride_contravariant() async {
    await checkFile('''
abstract class A {
  bool operator ==(Object object);
}

class B implements A {}

class F {
  void f(x) {}
  void g(int x) {}
}

class G extends F {
  void /*error:INVALID_OVERRIDE*/f(int x) {}
  void g(dynamic x) {}
}

class H implements F {
  void /*error:INVALID_OVERRIDE*/f(int x) {}
  void g(dynamic x) {}
}
''');
  }

  test_methodTearoffStrictArrow() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26393
    await checkFile(r'''
class A {
  void foo(dynamic x) {}
  void test(void f(int x)) {
    test(foo);
  }
}
    ''');
  }

  test_mixinApplicationIsConcrete() {
    return checkFile(r'''
class A {
  int get foo => 3;
}

class B {
  num get foo => 3.0;
}

class C = Object with B;

class /*error:INVALID_OVERRIDE*/D extends Object with C implements A {}
    ''');
  }

  test_mixinOverrideOfGrandInterface_interfaceOfAbstractSuperclass() async {
    await checkFile('''
class A {}
class B {}

abstract class I1 {
    m(A a);
}
abstract class Base implements I1 {}

class M {
    m(B a) {}
}

class T1 extends Base with /*error:INVALID_OVERRIDE*/M {}

class U1 = Base with /*error:INVALID_OVERRIDE*/M;
''');
  }

  test_mixinOverrideOfGrandInterface_interfaceOfConcreteSuperclass() async {
    await checkFile('''
class A {}
class B {}

abstract class I1 {
    m(A a);
}

class /*error:NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER*/Base
    implements I1 {}

class M {
    m(B a) {}
}

class T1 extends Base with /*error:INVALID_OVERRIDE*/M {}

class U1 = Base with /*error:INVALID_OVERRIDE*/M;
''');
  }

  test_mixinOverrideOfGrandInterface_interfaceOfInterfaceOfChild() async {
    await checkFile('''
class A {}
class B {}

abstract class I1 {
    m(A a);
}
abstract class I2 implements I1 {}

class M {
    m(B a) {}
}

class /*error:INCONSISTENT_INHERITANCE*/T1
    extends Object with M
    implements I2 {}

class /*error:INCONSISTENT_INHERITANCE*/U1
    = Object with M
    implements I2;
''');
  }

  test_mixinOverrideOfGrandInterface_mixinOfInterfaceOfChild() async {
    await checkFile('''
class A {}
class B {}

abstract class M1 {
    m(A a);
}
abstract class I2 extends Object with M1 {}

class M {
    m(B a) {}
}

class /*error:INCONSISTENT_INHERITANCE*/T1
    extends Object with M
    implements I2 {}

class /*error:INCONSISTENT_INHERITANCE*/U1
    = Object with M
    implements I2;
''');
  }

  test_mixinOverrideOfGrandInterface_superclassOfInterfaceOfChild() async {
    await checkFile('''
class A {}
class B {}

abstract class I1 {
    m(A a);
}
abstract class I2 extends I1 {}

class M {
    m(B a) {}
}

class /*error:INCONSISTENT_INHERITANCE*/T1
    extends Object with M
    implements I2 {}

class /*error:INCONSISTENT_INHERITANCE*/U1
    = Object with M
    implements I2;
''');
  }

  test_noDuplicateReports_baseTypeAndMixinOverrideSameMethodInInterface() async {
    await checkFile('''
class A {}
class B {}

abstract class I1 {
    m(A a);
}

class Base {
    m(B a) {}
}

class M {
    m(B a) {}
}

// TODO(jmesserly): the `INCONSISTENT_METHOD_INHERITANCE` message is from the
// Dart 1 checking logic (using strong mode type system), it is not produced
// by the strong mode OverrideChecker.
class /*error:INCONSISTENT_INHERITANCE*/T1
    extends Base
    with M
    implements I1 {}

class /*error:INCONSISTENT_INHERITANCE*/U1 =
    Base
    with M
    implements I1;
''');
  }

  test_noDuplicateReports_twoGrandTypesOverrideSameMethodInInterface() async {
    await checkFile('''
class A {}
class B {}

abstract class I1 {
    m(A a);
}

class Grandparent {
    m(B a) {}
}

class Parent1 extends Grandparent {
    m(B a) {}
}
class Parent2 extends Grandparent {}

// Note: otherwise both errors would be reported on this line
class /*error:INCONSISTENT_INHERITANCE*/T1
    extends Parent1
    implements I1 {}
class /*error:INCONSISTENT_INHERITANCE*/T2
    extends Parent2
    implements I1 {}
''');
  }

  test_noDuplicateReports_twoMixinsOverrideSameMethodInInterface() async {
    await checkFile('''
class A {}
class B {}

abstract class I1 {
    m(A a);
}

class M1 {
    m(B a) {}
}

class M2 {
    m(B a) {}
}

class /*error:INCONSISTENT_INHERITANCE*/T1 extends Object
    with M1, M2
    implements I1 {}
''');
  }

  test_noDuplicateReports_typeAndBaseTypeOverrideSameMethodInInterface() async {
    await checkFile('''
class A {}
class B {}

abstract class I1 {
  void m(A a);
}

class Base {
  void m(B a) {}
}

class T1 extends Base implements I1 {
  void /*error:INVALID_OVERRIDE*/m(B a) {}
}

class /*error:INCONSISTENT_INHERITANCE*/T2
    extends Base
    implements I1 {}
''');
  }

  test_noDuplicateReports_typeAndMixinOverrideSameMethodInInterface() async {
    await checkFile('''
class A {}
class B {}

abstract class I1 {
  void m(A a);
}

class M {
  void m(B a) {}
}

class T1 extends Object with M implements I1 {
  void /*error:INVALID_OVERRIDE*/m(B a) {}
}

class /*error:INCONSISTENT_INHERITANCE*/T2
    extends Object with M
    implements I1 {}

class /*error:INCONSISTENT_INHERITANCE*/U2
    = Object with M
    implements I1;
''');
  }

  test_noDuplicateReports_typeOverridesSomeMethodInMultipleInterfaces() async {
    await checkFile('''
class A {}
class B {}

abstract class I1 {
    m(A a);
}
abstract class I2 implements I1 {
    m(A a);
}

class Base {}

class T1 implements I2 {
  /*error:INVALID_OVERRIDE*/m(B a) {}
}
''');
  }

  test_nullCoalescingOperator() async {
    await checkFile('''
class A {}
class C<T> {}
main() {
  A a, b;
  a ??= new A();
  b = b ?? new A();

  // downwards inference
  C<int> c, d;
  c ??= new C();
  d = d ?? new C();
}
''');
  }

  test_nullCoalescingStrictArrow() async {
    await checkFile(r'''
bool _alwaysTrue(x) => true;
typedef bool TakesA<T>(T t);
class C<T> {
  TakesA<T> g;
  C(TakesA<T> f)
    : g = f ?? _alwaysTrue;
  C.a() : g = _alwaysTrue;
}
    ''');
  }

  test_optionalParams() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26155
    await checkFile(r'''
void takesF(void f(int x)) {
  takesF(([x]) { bool z = x.isEven; });
  takesF((y) { bool z = y.isEven; });
}
    ''');
  }

  test_overrideNarrowsType() async {
    addFile(r'''
class A {}
class B extends A {}

abstract class C {
  m(A a);
  n(B b);
}
abstract class D extends C {
  /*error:INVALID_OVERRIDE*/m(B b);
  n(A a);
}
    ''');
    await check(implicitCasts: false);
  }

  test_overrideNarrowsType_legalWithChecked() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/25232
    await checkFile(r'''
abstract class A { void test(A arg) { } }
abstract class B extends A { void test(covariant B arg) { } }
abstract class X implements A { }
class C extends B with X { }
class D extends B implements A { }
    ''');
  }

  test_overrideNarrowsType_noDuplicateError() {
    // Regression test for https://github.com/dart-lang/sdk/issues/25232
    return checkFile(r'''
abstract class A { void test(A arg) { } }
abstract class B extends A {
  void /*error:INVALID_OVERRIDE*/test(B arg) { }
}
abstract class X implements A { }

class C extends B {}

class /*error:INVALID_OVERRIDE*/D extends B with X { }

class /*error:INVALID_OVERRIDE*/E extends B implements A { }
    ''');
  }

  test_privateOverride() async {
    addFile('''
import 'main.dart' as main;

class Base {
  var f1;
  var _f2;
  var _f3;
  get _f4 => null;

  int _m1() => null;
}

class GrandChild extends main.Child {
  var _f2;
  var _f3;
  var _f4;

  String /*error:INVALID_OVERRIDE*/_m1() => null;
}
''', name: '/helper.dart');
    await checkFile('''
import 'helper.dart' as helper;

class Child extends helper.Base {
  var f1;
  var _f2;
  var _f4;

  String _m1() => null;
}
''');
  }

  test_proxy() {
    return checkFile(r'''
@proxy class C {}
@proxy class D {
  var f;
  m() => null;
  operator -() => null;
  operator +(int other) => null;
  operator [](int index) => null;
  call() => null;
}
@proxy class F implements Function { noSuchMethod(i) => 42; }


m() {
  D d = new D();
  d.m();
  d.m;
  d.f;
  -d;
  d + 7;
  d[7];
  d();

  C c = new C();
  c./*error:UNDEFINED_METHOD*/m();
  c./*error:UNDEFINED_GETTER*/m;
  /*error:UNDEFINED_OPERATOR*/-c;
  c /*error:UNDEFINED_OPERATOR*/+ 7;
  c /*error:UNDEFINED_OPERATOR*/[7];
  /*error:INVOCATION_OF_NON_FUNCTION_EXPRESSION*/c();

  F f = new F();
  /*error:INVOCATION_OF_NON_FUNCTION_EXPRESSION*/f();
}
    ''');
  }

  test_redirectingConstructor() async {
    await checkFile('''
class A {
  A(A x) {}
  A.two() : this(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/3);
}
''');
  }

  test_relaxedCasts() async {
    await checkFile('''
class A {}

class L<T> {}
class M<T> extends L<T> {}
//     L<dynamic|Object>
//    /              \
// M<dynamic|Object>  L<A>
//    \              /
//          M<A>
// In normal Dart, there are additional edges
//  from M<A> to M<dynamic>
//  from L<A> to M<dynamic>
//  from L<A> to L<dynamic>
void main() {
  L lOfDs;
  L<Object> lOfOs;
  L<A> lOfAs;

  M mOfDs;
  M<Object> mOfOs;
  M<A> mOfAs;

  {
    lOfDs = mOfDs;
    lOfDs = mOfOs;
    lOfDs = mOfAs;
    lOfDs = lOfDs;
    lOfDs = lOfOs;
    lOfDs = lOfAs;
    lOfDs = new L(); // Reset type propagation.
  }
  {
    lOfOs = mOfDs;
    lOfOs = mOfOs;
    lOfOs = mOfAs;
    lOfOs = lOfDs;
    lOfOs = lOfOs;
    lOfOs = lOfAs;
    lOfOs = new L<Object>(); // Reset type propagation.
  }
  {
    lOfAs = /*error:INVALID_ASSIGNMENT*/mOfDs;
    lOfAs = /*error:INVALID_ASSIGNMENT*/mOfOs;
    lOfAs = mOfAs;
    lOfAs = lOfDs;
    lOfAs = lOfOs;
    lOfAs = lOfAs;
    lOfAs = new L<A>(); // Reset type propagation.
  }
  {
    mOfDs = mOfDs;
    mOfDs = mOfOs;
    mOfDs = mOfAs;
    mOfDs = lOfDs;
    mOfDs = lOfOs;
    mOfDs = /*error:INVALID_ASSIGNMENT*/lOfAs;
    mOfDs = new M(); // Reset type propagation.
  }
  {
    mOfOs = mOfDs;
    mOfOs = mOfOs;
    mOfOs = mOfAs;
    mOfOs = lOfDs;
    mOfOs = lOfOs;
    mOfOs = /*error:INVALID_ASSIGNMENT*/lOfAs;
    mOfOs = new M<Object>(); // Reset type propagation.
  }
  {
    mOfAs = mOfDs;
    mOfAs = mOfOs;
    mOfAs = mOfAs;
    mOfAs = lOfDs;
    mOfAs = lOfOs;
    mOfAs = lOfAs;
  }
}
''');
  }

  test_set_ifElement_dynamicCondition_disableImplicitCasts() async {
    addFile(r'''
dynamic c;
void main() {
  <int>{if (/*error:NON_BOOL_CONDITION*/c) 0};
}
''');
    await check(implicitCasts: false);
  }

  test_set_ifElement_dynamicCondition_implicitCasts() async {
    addFile(r'''
dynamic c;
void main() {
  <int>{if (c) 0};
}
''');
    await check();
  }

  test_set_ifElement_falseBranch_dynamic_disableImplicitCasts() async {
    addFile(r'''
bool c;
dynamic dyn;
void main() {
  <int>{if (c) 0 else /*error:SET_ELEMENT_TYPE_NOT_ASSIGNABLE*/dyn};
}
''');
    await check(implicitCasts: false);
  }

  test_set_ifElement_falseBranch_dynamic_implicitCasts() async {
    addFile(r'''
bool c;
dynamic dyn;
void main() {
  <int>{if (c) 0 else dyn};
}
''');
    await check();
  }

  test_set_ifElement_falseBranch_supertype_disableImplicitCasts() async {
    addFile(r'''
bool c;
num someNum;
void main() {
  <int>{if (c) 0 else /*error:SET_ELEMENT_TYPE_NOT_ASSIGNABLE*/someNum};
}
''');
    await check(implicitCasts: false);
  }

  test_set_ifElement_falseBranch_supertype_implicitCasts() async {
    addFile(r'''
bool c;
num someNum;
void main() {
  <int>{if (c) 0 else someNum};
}
''');
    await check();
  }

  test_set_ifElement_objectCondition_disableImplicitCasts() async {
    addFile(r'''
Object c;
void main() {
  <int>{if (/*error:NON_BOOL_CONDITION*/c) 0};
}
''');
    await check(implicitCasts: false);
  }

  test_set_ifElement_objectCondition_implicitCasts() async {
    addFile(r'''
Object c;
void main() {
  <int>{if (c) 0};
}
''');
    await check();
  }

  test_set_ifElement_trueBranch_dynamic_disableImplicitCasts() async {
    addFile(r'''
bool c;
dynamic dyn;
void main() {
  <int>{if (c) /*error:SET_ELEMENT_TYPE_NOT_ASSIGNABLE*/dyn};
}
''');
    await check(implicitCasts: false);
  }

  test_set_ifElement_trueBranch_dynamic_implicitCasts() async {
    addFile(r'''
bool c;
dynamic dyn;
void main() {
  <int>[if (c) dyn];
}
''');
    await check();
  }

  test_set_ifElement_trueBranch_supertype_disableImplicitCasts() async {
    addFile(r'''
bool c;
num someNum;
void main() {
  <int>{if (c) /*error:SET_ELEMENT_TYPE_NOT_ASSIGNABLE*/someNum};
}
''');
    await check(implicitCasts: false);
  }

  test_set_ifElement_trueBranch_supertype_implicitCasts() async {
    addFile(r'''
bool c;
num someNum;
void main() {
  <int>{if (c) someNum};
}
''');
    await check();
  }

  test_setterOverride() async {
    await checkFile('''
typedef void ToVoid<T>(T x);
class F {
  void set f(ToVoid<dynamic> x) {}
  void set g(ToVoid<int> x) {}
  void set h(dynamic x) {}
  void set i(int x) {}
}

class G extends F {
  void set f(ToVoid<int> x) {}
  void set /*error:INVALID_OVERRIDE*/g(ToVoid<dynamic> x) {}
  void set /*error:INVALID_OVERRIDE*/h(int x) {}
  void set i(dynamic x) {}
}

class H implements F {
  void set f(ToVoid<int> x) {}
  void set /*error:INVALID_OVERRIDE*/g(ToVoid<dynamic> x) {}
  void set /*error:INVALID_OVERRIDE*/h(int x) {}
  void set i(dynamic x) {}
}
 ''');
  }

  test_setterReturnTypes() async {
    await checkFile('''
void voidFn() => null;
class A {
  set a(y) => 4;
  set b(y) => voidFn();
  void set c(y) => 4;
  void set d(y) => voidFn();
  /*error:NON_VOID_RETURN_FOR_SETTER*/int set e(y) => 4;
  /*error:NON_VOID_RETURN_FOR_SETTER*/int set f(y) =>
    /*error:RETURN_OF_INVALID_TYPE*/voidFn();
  set g(y) {return /*error:RETURN_OF_INVALID_TYPE*/4;}
  void set h(y) {return /*error:RETURN_OF_INVALID_TYPE*/4;}
  /*error:NON_VOID_RETURN_FOR_SETTER*/int set i(y) {return 4;}
}
''');
  }

  test_setterSetterOverride() async {
    await checkFile('''
class A {}
class B extends A {}
class C extends B {}

abstract class Base {
  void set f1(B value);
  void set f2(B value);
  void set f3(B value);
  void set f4(B value);
  void set f5(B value);
}

class Child extends Base {
  void set f1(A value) {}
  void set /*error:INVALID_OVERRIDE*/f2(C value) {}
  void set f3(value) {}
  void set f4(dynamic value) {}
  set f5(B value) {}
}
''');
  }

  @failingTest
  test_spread_dynamicInList_disableImplicitCasts() async {
    // TODO(mfairhurst) fix this, see https://github.com/dart-lang/sdk/issues/36267
    addFile(r'''
dynamic dyn;
void main() {
  [.../*error:INVALID_ASSIGNMENT*/dyn];
}
''');
    await check(implicitCasts: false);
  }

  test_spread_dynamicInList_implicitCasts() async {
    addFile(r'''
dynamic dyn;
void main() {
  [...dyn];
}
''');
    await check();
  }

  @failingTest
  test_spread_dynamicInMap_disableImplicitCasts() async {
    // TODO(mfairhurst) fix this, see https://github.com/dart-lang/sdk/issues/36267
    addFile(r'''
dynamic dyn;
void main() {
  <dynamic, dynamic>{.../*error:INVALID_ASSIGNMENT*/dyn};
}
''');
    await check(implicitCasts: false);
  }

  test_spread_dynamicInMap_implicitCasts() async {
    addFile(r'''
dynamic dyn;
void main() {
  <dynamic, dynamic>{...dyn};
}
''');
    await check();
  }

  @failingTest
  test_spread_dynamicInSet_disableImplicitCasts() async {
    // TODO(mfairhurst) fix this, see https://github.com/dart-lang/sdk/issues/36267
    addFile(r'''
dynamic dyn;
void main() {
  <dynamic>{.../*error:INVALID_ASSIGNMENT*/dyn};
}
''');
    await check(implicitCasts: false);
  }

  test_spread_dynamicInSet_implicitCasts() async {
    addFile(r'''
dynamic dyn;
void main() {
  <dynamic>{...dyn};
}
''');
    await check();
  }

  test_spread_listElement_disableImplicitCasts() async {
    addFile(r'''
Iterable<num> i;
void main() {
  <int>[.../*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/i];
}
''');
    await check(implicitCasts: false);
  }

  test_spread_listElement_implicitCasts() async {
    addFile(r'''
Iterable<num> i;
void main() {
  <int>[...i];
}
''');
    await check();
  }

  test_spread_mapKey_disableImplicitCasts() async {
    addFile(r'''
Map<num, dynamic> map;
void main() {
  <int, dynamic>{1: 2, .../*error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/map};
}
''');
    await check(implicitCasts: false);
  }

  test_spread_mapKey_implicitCasts() async {
    addFile(r'''
Map<num, dynamic> map;
void main() {
  <int, dynamic>{1: 2, ...map};
}
''');
    await check();
  }

  test_spread_mapValue_disableImplicitCasts() async {
    addFile(r'''
Map<dynamic, num> map;
void main() {
  <dynamic, int>{1: 2, .../*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/map};
}
''');
    await check(implicitCasts: false);
  }

  test_spread_mapValue_implicitCasts() async {
    addFile(r'''
Map<dynamic, num> map;
void main() {
  <dynamic, int>{1: 2, ...map};
}
''');
    await check();
  }

  test_spread_setElement_disableImplicitCasts() async {
    addFile(r'''
Iterable<num> i;
void main() {
  <int>{.../*error:SET_ELEMENT_TYPE_NOT_ASSIGNABLE*/i};
}
''');
    await check(implicitCasts: false);
  }

  test_spread_setElement_implicitCasts() async {
    addFile(r'''
Iterable<num> i;
void main() {
  <int>{...i};
}
''');
    await check();
  }

  test_strictInference_instanceCreation() async {
    addFile(r'''
class C<T> {
  C([T t]);
  C.of(T t);
  factory C.from(Object e) => C();
}

main() {
  // These should be allowed:
  C<int> downwardsInferenceIsOK = C();
  C<dynamic> downwardsInferenceDynamicIsOK = C();
  var inferredFromConstructorParameterIsOK = C(42);
  var explicitDynamicIsOK = C<dynamic>(42);

  var rawConstructorCall = /*info:INFERENCE_FAILURE_ON_INSTANCE_CREATION*/C();
  var factoryConstructor = /*info:INFERENCE_FAILURE_ON_INSTANCE_CREATION*/C.from(42);
  var upwardsInfersDynamic = C(42 as dynamic);
  var namedConstructor = C.of(42 as dynamic);
}
    ''');
    await check(strictInference: true);
  }

  test_superCallPlacement() async {
    await checkFile('''
class Base {
  var x;
  Base() : x = print('Base.1') { print('Base.2'); }
}

class Derived extends Base {
  var y, z;
  Derived()
      : y = print('Derived.1'),
        /*error:INVALID_SUPER_INVOCATION*/super(),
        z = print('Derived.2') {
    print('Derived.3');
  }
}

class Valid extends Base {
  var y, z;
  Valid()
      : y = print('Valid.1'),
        z = print('Valid.2'),
        super() {
    print('Valid.3');
  }
}

class AlsoValid extends Base {
  AlsoValid() : super();
}

main() => new Derived();
''');
  }

  test_superclassOverrideOfGrandInterface_interfaceOfAbstractSuperclass() async {
    await checkFile('''
class A {}
class B {}

abstract class I1 {
    m(A a);
}

abstract class Base implements I1 {
  /*error:INVALID_OVERRIDE*/m(B a) {}
}

class T1 extends Base {
    m(B a) {}
}
''');
  }

  test_superclassOverrideOfGrandInterface_interfaceOfConcreteSuperclass() async {
    await checkFile('''
class A {}
class B {}

abstract class I1 {
    m(A a);
}

class Base implements I1 {
  /*error:INVALID_OVERRIDE*/m(B a) {}
}

class T1 extends Base {
    m(B a) {}
}
''');
  }

  test_superclassOverrideOfGrandInterface_interfaceOfInterfaceOfChild() async {
    await checkFile('''
class A {}
class B {}

abstract class I1 {
    m(A a);
}
abstract class I2 implements I1 {}

class Base {
    m(B a) {}
}

class /*error:INCONSISTENT_INHERITANCE*/T1
    extends Base implements I2 {}
''');
  }

  test_superclassOverrideOfGrandInterface_mixinOfInterfaceOfChild() async {
    await checkFile('''
class A {}
class B {}

abstract class M1 {
    m(A a);
}
abstract class I2 extends Object with M1 {}

class Base {
    m(B a) {}
}

class /*error:INCONSISTENT_INHERITANCE*/T1
    extends Base
    implements I2 {}
''');
  }

  test_superclassOverrideOfGrandInterface_superclassOfInterfaceOfChild() async {
    await checkFile('''
class A {}
class B {}

abstract class I1 {
    m(A a);
}
abstract class I2 extends I1 {}

class Base {
    m(B a) {}
}

class /*error:INCONSISTENT_INHERITANCE*/T1
    extends Base
    implements I2 {}
''');
  }

  test_superConstructor() async {
    await checkFile('''
class A { A(A x) {} }
class B extends A {
  B() : super(/*error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/3);
}
''');
  }

  test_tearOffTreatedConsistentlyAsStrictArrow() async {
    await checkFile(r'''
void foo(void f(String x)) {}

class A {
  Null bar1(dynamic x) => null;
  void bar2(dynamic x) => null;
  Null bar3(String x) => null;
  void test() {
    foo(bar1);
    foo(bar2);
    foo(bar3);
  }
}


Null baz1(dynamic x) => null;
void baz2(dynamic x) => null;
Null baz3(String x) => null;
void test() {
  foo(baz1);
  foo(baz2);
  foo(baz3);
}
    ''');
  }

  test_tearOffTreatedConsistentlyAsStrictArrowNamedParam() async {
    await checkFile(r'''
typedef void Handler(String x);
void foo({Handler f}) {}

class A {
  Null bar1(dynamic x) => null;
  void bar2(dynamic x) => null;
  Null bar3(String x) => null;
  void test() {
    foo(f: bar1);
    foo(f: bar2);
    foo(f: bar3);
  }
}


Null baz1(dynamic x) => null;
void baz2(dynamic x) => null;
Null baz3(String x) => null;
void test() {
  foo(f: baz1);
  foo(f: baz2);
  foo(f: baz3);
}
    ''');
  }

  test_ternaryOperator() async {
    await checkFile('''
abstract class Comparable<T> {
  int compareTo(T other);
  static int compare(Comparable a, Comparable b) => a.compareTo(b);
}
typedef int Comparator<T>(T a, T b);

typedef bool _Predicate<T>(T value);

class SplayTreeMap<K, V> {
  Comparator<K> _comparator;
  _Predicate _validKey;

  // The warning on assigning to _comparator is legitimate. Since K has
  // no bound, all we know is that it's object. _comparator's function
  // type is effectively:              (Object, Object) -> int
  // We are assigning it a fn of type: (Comparable, Comparable) -> int
  // There's no telling if that will work. For example, consider:
  //
  //     new SplayTreeMap<Uri>();
  //
  // This would end up calling .compareTo() on a Uri, which doesn't
  // define that since it doesn't implement Comparable.
  SplayTreeMap([int compare(K key1, K key2),
                bool isValidKey(potentialKey)])
    : _comparator = (compare == null) ? Comparable.compare : compare,
      _validKey = (isValidKey != null) ? isValidKey : ((v) => true) {

    _Predicate<Object> v = (isValidKey != null)
        ? isValidKey : ((_) => true);

    v = (isValidKey != null)
         ? v : ((_) => true);
  }
}
void main() {
  Object obj = 42;
  dynamic dyn = 42;
  int i = 42;

  // Check the boolean conversion of the condition.
  print(/*error:NON_BOOL_CONDITION*/i ? false : true);
  print((obj) ? false : true);
  print((dyn) ? false : true);
}
''');
  }

  test_typeCheckingLiterals() async {
    await checkFile('''
test() {
  num n = 3;
  int i = 3;
  String s = "hello";
  {
     List<int> l = <int>[i];
     l = <int>[/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/s];
     l = <int>[n];
     l = <int>[i, n, /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/s];
  }
  {
     List l = [i];
     l = [s];
     l = [n];
     l = [i, n, s];
  }
  {
     Map<String, int> m = <String, int>{s: i};
     m = <String, int>{s: /*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/s};
     m = <String, int>{s: n};
     m = <String, int>{s: i,
                       s: n,
                       s: /*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/s};
  }
 // TODO(leafp): We can't currently test for key errors since the
 // error marker binds to the entire entry.
  {
     Map m = {s: i};
     m = {s: s};
     m = {s: n};
     m = {s: i,
          s: n,
          s: s};
     m = {i: s,
          n: s,
          s: s};
  }
}
''');
  }

  test_typePromotionFromDynamic() async {
    await checkFile(r'''
f() {
  dynamic x;
  if (x is int) {
    int y = x;
    String z = /*error:INVALID_ASSIGNMENT*/x;
  }
}
g() {
  Object x;
  if (x is int) {
    int y = x;
    String z = /*error:INVALID_ASSIGNMENT*/x;
  }
}
''');
  }

  test_typePromotionFromTypeParameter() async {
    // Regression test for:
    // https://github.com/dart-lang/sdk/issues/26965
    // https://github.com/dart-lang/sdk/issues/27040
    await checkFile(r'''
void f<T>(T object) {
  if (object is String) print(object.substring(1));
}
void g<T extends num>(T object) {
  if (object is int) print(object.isEven);
  if (object is String) print(object./*error:UNDEFINED_METHOD*/substring(1));
}
class Cloneable<T> {}
class SubCloneable<T> extends Cloneable<T> {
  T m(T t) => t;
}
void takesSubCloneable<A>(SubCloneable<A> t) {}

void h<T extends Cloneable<T>>(T object) {
  if (object is SubCloneable<T>) {
    print(object.m(object));

    SubCloneable<T> s = object;
    takesSubCloneable<T>(object);
    // Issue #35799: According to the language team, this should work, but both
    // analyzer and CFE currently reject it, likely due to a strange
    // representation of promoted type variables.
    // h(object);
  }
}
''');
  }

  test_typePromotionFromTypeParameterAndInference() async {
    // Regression test for:
    // https://github.com/dart-lang/sdk/issues/27040
    await checkFile(r'''
void f<T extends num>(T x, T y) {
  var z = x;
  var f = () => x;
  f = () => y;
  if (x is int) {
    z./*error:UNDEFINED_GETTER*/isEven;
    var q = x;
    q = z;
    f()./*error:UNDEFINED_GETTER*/isEven;

    // This captures the type `T extends int`.
    var g = () => x;
    g = f;
    g()./*error:UNDEFINED_GETTER*/isEven;
    q = g();
    int r = x;
  }
}
    ''');
  }

  test_typeSubtyping_assigningClass() async {
    await checkFile('''
class A {}
class B extends A {}

void main() {
   dynamic y;
   Object o;
   int i = 0;
   double d = 0.0;
   num n;
   A a;
   B b;
   y = a;
   o = a;
   i = /*error:INVALID_ASSIGNMENT*/a;
   d = /*error:INVALID_ASSIGNMENT*/a;
   n = /*error:INVALID_ASSIGNMENT*/a;
   a = a;
   b = a;
}
''');
  }

  test_typeSubtyping_assigningSubclass() async {
    await checkFile('''
class A {}
class B extends A {}
class C extends A {}

void main() {
   dynamic y;
   Object o;
   int i = 0;
   double d = 0.0;
   num n;
   A a;
   B b;
   C c;
   y = b;
   o = b;
   i = /*error:INVALID_ASSIGNMENT*/b;
   d = /*error:INVALID_ASSIGNMENT*/b;
   n = /*error:INVALID_ASSIGNMENT*/b;
   a = b;
   b = b;
   c = /*error:INVALID_ASSIGNMENT*/b;
}
''');
  }

  test_typeSubtyping_dynamicDowncasts() async {
    await checkFile('''
class A {}
class B extends A {}

void main() {
   dynamic y;
   Object o;
   int i = 0;
   double d = 0.0;
   num n;
   A a;
   B b;
   o = y;
   i = y;
   d = y;
   n = y;
   a = y;
   b = y;
}
''');
  }

  test_typeSubtyping_dynamicIsTop() async {
    await checkFile('''
class A {}
class B extends A {}

void main() {
   dynamic y;
   Object o;
   int i = 0;
   double d = 0.0;
   num n;
   A a;
   B b;
   y = o;
   y = i;
   y = d;
   y = n;
   y = a;
   y = b;
}
''');
  }

  test_typeSubtyping_interfaces() async {
    await checkFile('''
class A {}
class B extends A {}
class C extends A {}
class D extends B implements C {}

void main() {
   A top;
   B left;
   C right;
   D bot;
   {
     top = top;
     top = left;
     top = right;
     top = bot;
   }
   {
     left = top;
     left = left;
     left = /*error:INVALID_ASSIGNMENT*/right;
     left = bot;
   }
   {
     right = top;
     right = /*error:INVALID_ASSIGNMENT*/left;
     right = right;
     right = bot;
   }
   {
     bot = top;
     bot = left;
     bot = right;
     bot = bot;
   }
}
''');
  }

  test_unaryOperators() async {
    await checkFile('''
class A {
  A operator ~() => null;
  A operator +(int x) => null;
  A operator -(int x) => null;
  A operator -() => null;
}
class B extends A {}
class C extends B {}

foo() => new A();

test() {
  A a = new A();
  B b = new B();
  var c = foo();
  dynamic d;

  ~a;
  (~d);

  !/*error:NON_BOOL_NEGATION_EXPRESSION*/a;
  !d;

  -a;
  (-d);

  ++a;
  --a;
  (++d);
  (--d);

  a++;
  a--;
  (d++);
  (d--);

  ++b;
  --b;
  b++;
  b--;

  takesC(C c) => null;
  takesC(++b);
  takesC(--b);
  takesC(b++);
  takesC(b--);
}''');
  }

  test_unboundRedirectingConstructor() async {
    // This is a regression test for https://github.com/dart-lang/sdk/issues/25071
    await checkFile('''
class Foo {
  Foo() : /*error:REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR*/this.init();
}
 ''');
  }

  test_unboundTypeName() async {
    await checkFile('''
void main() {
   /*error:UNDEFINED_CLASS*/AToB y;
}
''');
  }

  test_unboundVariable() async {
    await checkFile('''
void main() {
   dynamic y = /*error:UNDEFINED_IDENTIFIER*/unboundVariable;
}
''');
  }

  test_universalFunctionSubtyping() async {
    await checkFile(r'''
dynamic foo<T>(dynamic x) => x;

void takesDtoD(dynamic f(dynamic x)) {}

void test() {
  // here we currently infer an instantiation.
  takesDtoD(/*pass should be error:INVALID_ASSIGNMENT*/foo);
}

class A {
  dynamic method(dynamic x) => x;
}

class B extends A {
  T /*error:INVALID_OVERRIDE*/method<T>(T x) => x;
}
    ''');
  }

  test_voidSubtyping() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/25069
    await checkFile('''
typedef int Foo();
void foo() {}
void main () {
  Foo x = /*error:USE_OF_VOID_RESULT*/foo();
}
''');
  }
}
