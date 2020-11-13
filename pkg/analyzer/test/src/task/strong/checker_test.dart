// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/test_support.dart';
import '../../dart/resolution/context_collection_resolution.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CheckerTest);
  });
}

@reflectiveTest
class CheckerTest extends PubPackageResolutionTest {
  test_awaitForInCastsStreamElementToVariable() async {
    await assertErrorsInCode('''
abstract class MyStream<T> extends Stream<T> {
  factory MyStream() => throw 0;
}

main() async {
  // Don't choke if sequence is not stream.
  await for (var i in 1234) {}

  // Dynamic cast.
  await for (String s in new MyStream<dynamic>()) {}

  // Identity cast.
  await for (String s in new MyStream<String>()) {}

  // Untyped.
  await for (var s in new MyStream<String>()) {}

  // Downcast.
  await for (int i in new MyStream<num>()) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 159, 1),
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE, 164, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 213, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 287, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 351, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 416, 1),
    ]);
  }

  test_awaitForInCastsSupertypeSequenceToStream() async {
    await assertErrorsInCode('''
main() async {
  dynamic d;
  await for (var i in d) {}

  Object o;
  await for (var i in o) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 45, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 86, 1),
    ]);
  }

  test_binaryAndIndexOperators() async {
    await assertErrorsInCode('''
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
  a = a + a;
  a = a - b;
  b = b - b;
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
  x = x + y;

  bool p = true;
  p = p && p;
  p = p && c;
  p = (c) && p;
  p = (c) && c;
  p = y && p;
  p = c == y;

  a = a[b];
  a = a[c];
  c = (c[b]);
  a[y];
}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 574, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 596, 5),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 758, 1),
      error(CompileTimeErrorCode.NON_BOOL_OPERAND, 845, 1),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 910, 1),
    ]);
  }

  test_callMethodOnFunctions() async {
    await assertErrorsInCode(r'''
void f(int x) => print(x);
main() {
  f.call('hi');
}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 45, 4),
    ]);
  }

  test_castsInConditions() async {
    await assertErrorsInCode('''
main() {
  bool b = true;
  num x = b ? 1 : 2.3;
  int y = b ? 1 : 2.3;
  String z = !b ? "hello" : null;
  z = b ? null : "hello";
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 32, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 55, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 81, 1),
    ]);
  }

  test_castsInConstantContexts() async {
    await assertErrorsInCode('''
class A {
  static const num n = 3.0;
  // The severe error is from constant evaluation where we know the
  // concrete type.
  static const int i = n;
  final int fi;
  const A(num a) : this.fi = a;
}
class B extends A {
  const B(Object a) : super(a);
}
void foo(Object o) {
  var a = const A(o);
}
''', [
      error(CompileTimeErrorCode.VARIABLE_TYPE_MISMATCH, 149, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 283, 1),
      error(CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT, 295, 1),
    ]);
  }

  test_classOverrideOfGrandInterface_interfaceOfAbstractSuperclass() async {
    await assertErrorsInCode('''
class A {}
class B {}

abstract class I1 {
  m(A a);
}
abstract class Base implements I1 {}

class T1 extends Base {
  m(B a) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 119, 1),
    ]);
  }

  test_classOverrideOfGrandInterface_interfaceOfConcreteSuperclass() async {
    await assertErrorsInCode('''
class A {}
class B {}

abstract class I1 {
  m(A a);
}

class Base implements I1 {}

class T1 extends Base {
  m(B a) {}
}
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          62,
          4),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 111, 1),
    ]);
  }

  test_classOverrideOfGrandInterface_interfaceOfInterfaceOfChild() async {
    await assertErrorsInCode('''
class A {}
class B {}

abstract class I1 {
  m(A a);
}
abstract class I2 implements I1 {}

class T1 implements I2 {
  m(B a) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 118, 1),
    ]);
  }

  test_classOverrideOfGrandInterface_mixinOfInterfaceOfChild() async {
    await assertErrorsInCode('''
class A {}
class B {}

abstract class M1 {
  m(A a);
}
abstract class I2 extends Object with M1 {}

class T1 implements I2 {
  m(B a) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 127, 1),
    ]);
  }

  test_classOverrideOfGrandInterface_superclassOfInterfaceOfChild() async {
    await assertErrorsInCode('''
class A {}
class B {}

abstract class I1 {
  m(A a);
}
abstract class I2 extends I1 {}

class T1 implements I2 {
  m(B a) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 115, 1),
    ]);
  }

  test_compoundAssignment_returnsDynamic() async {
    await assertNoErrorsInCode(r'''
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
    await assertErrorsInCode('''
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
  x += 3.14;

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
  a += a;
  a -= b;
  b -= b;
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
  a[z] += d;
  a[b] += c;
  a[b] += z;
  c[b] += d;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 613, 4),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 927, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 947, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1045, 3),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 1110, 1),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 1142, 1),
    ]);
  }

  @FailingTest(issue: 'dartbug.com/33440')
  test_constantGenericTypeArg_explicit() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26141
    await assertNoErrorsInCode('''
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
    await assertNoErrorsInCode('''
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
    await assertErrorsInCode('''
class A {
  B({this.test: 1.0 }) {}
  final double test = 0.0;
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, 15, 9),
    ]);
  }

  test_constructors() async {
    await assertErrorsInCode('''
const num z = 25;
Object obj = "world";

class A {
  int x;
  String y;

  A(this.x) : this.y = 42;

  A.c1(p): this.x = z, this.y = p;

  A.c2(this.x, this.y);

  A.c3(num this.x, String this.y);
}

class B extends A {
  B() : super("hello");

  B.c2(int x, String y) : super.c2(y, x);

  B.c3(num x, Object y) : super.c3(x, y);
}

void main() {
   A a = new A.c2(z, z);
   var b = new B.c2("hello", obj);
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_NOT_ASSIGNABLE, 96, 2),
      error(CompileTimeErrorCode.FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE, 169,
          10),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 234, 7),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 280, 1),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 283, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 352, 1),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 368, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 379, 1),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 392, 7),
    ]);
  }

  test_conversionAndDynamicInvoke() async {
    newFile('$testPackageLibPath/helper.dart', content: r'''
dynamic toString = (int x) => x + 42;
dynamic hashCode = "hello";
''');

    await assertErrorsInCode('''
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
  DynFun f3 = foo;
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
''', [
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 503, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 760, 15),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1039, 8),
    ]);
  }

  test_covariantOverride() async {
    await assertErrorsInCode(r'''
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
  int f(int x) => x;
}
class E_error extends D {
  int f(covariant double x) => 0;
}
class F_error extends E {
  int f(covariant double x) => 0;
}
class G_error extends E implements D {
  int f(covariant double x) => 0;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 252, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 301, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 363, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 438, 1),
    ]);
  }

  @failingTest
  test_covariantOverride_fields() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertErrorsInCode(r'''
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
  int f(String x) => 0;
}
class E_error extends D {
  int f(double x) => 0;
}
class F_error extends E {
  int f(double x) => 0;
}
class G_error extends E implements D {
  int f(double x) => 0;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 242, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 294, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 346, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 411, 1),
    ]);
  }

  test_dynamicInvocation() {
    return assertErrorsInCode(r'''
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
    x = f.col(true);
    y = f(3);
    y = f.col(true);
    f(true);
    f.col(3);
  }
  {
    Function f = new B();
    int x;
    bool y;
    x = f(3);
    x = f.col(true);
    y = f(3);
    y = f.col(true);
    f(true);
    // Through type propagation, we know f is actually a B, hence the
    // hint.
    f.col(3);
  }
  {
    A f = new B();
    B b = new B();
    f = b;
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
    A f = new B();
    B b = new B();
    f = b;
    f.col(true);
    f.foo(true);
    f.x;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 136, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 148, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 173, 11),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 194, 4),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 227, 4),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 244, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 290, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 302, 1),
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 329, 3),
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 364, 3),
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 477, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 503, 7),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 539, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 550, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 562, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 710, 7),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 746, 1),
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 755, 3),
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 772, 3),
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 789, 1),
    ]);
  }

  test_factoryConstructorDowncast() async {
    await assertErrorsInCode(r'''
class Animal {
  Animal();
  factory Animal.cat() => new Cat();
}

class Cat extends Animal {}

void main() {
  Cat c = new Animal.cat();
  c = new Animal();
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 116, 1),
      error(CompileTimeErrorCode.INVALID_CAST_NEW_EXPR, 144, 12),
    ]);
  }

  test_fieldFieldOverride() async {
    await assertErrorsInCode('''
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
  A f1; // invalid for getter
  C f2; // invalid for setter
  var f3;
  dynamic f4;
}

class Child2 implements Base {
  A f1; // invalid for getter
  C f2; // invalid for setter
  var f3;
  dynamic f4;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 133, 2),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 163, 2),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 209, 2),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 251, 2),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 281, 2),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 327, 2),
    ]);
  }

  test_fieldGetterOverride() async {
    await assertErrorsInCode('''
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
  A get f1 => null;
  C get f2 => null;
  get f3 => null;
  dynamic get f4 => null;
}

class Child2 implements Base {
  A get f1 => null;
  C get f2 => null;
  get f3 => null;
  dynamic get f4 => null;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 146, 2),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 210, 2),
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR,
          231,
          6),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 264, 2),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 328, 2),
    ]);
  }

  test_fieldOverride() async {
    await assertErrorsInCode('''
typedef void ToVoid<T>(T x);
class F {
  final ToVoid<dynamic> f = null;
  final ToVoid<int> g = null;
}

class G extends F {
  final ToVoid<int> f = null;
  final ToVoid<dynamic> g = null;
}

class H implements F {
  final ToVoid<int> f = null;
  final ToVoid<dynamic> g = null;
}
 ''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 146, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 236, 1),
    ]);
  }

  test_fieldSetterOverride() async {
    await assertErrorsInCode('''
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
  void set f2(C value) {}
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
  void set f2(C value) {}
  void set f3(value) {}
  void set f4(dynamic value) {}
  set f5(B value) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 275, 2),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 539, 2),
    ]);
  }

  test_forInCastsIterateElementToVariable() async {
    await assertErrorsInCode('''
main() {
  // Don't choke if sequence is not iterable.
  for (var i in 1234) {}

  // Dynamic cast.
  for (String s in <dynamic>[]) {}

  // Identity cast.
  for (String s in <String>[]) {}

  // Untyped.
  for (var s in <String>[]) {}

  // Downcast.
  for (int i in <num>[]) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 66, 1),
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE, 71, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 114, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 170, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 216, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 263, 1),
    ]);
  }

  test_forInCastsSupertypeSequenceToIterate() async {
    await assertErrorsInCode('''
main() {
  dynamic d;
  for (var i in d) {}

  Object o;
  for (var i in o) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 33, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 68, 1),
    ]);
  }

  test_forLoopVariable() async {
    await assertErrorsInCode('''
foo() {
  for (int i = 0; i < 10; i++) {
    i = "hi";
  }
}
bar() {
  for (var i = 0; i < 10; i++) {
    int j = i + 1;
  }
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 49, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 110, 1),
    ]);
  }

  test_functionModifiers_async() async {
    await assertErrorsInCode('''
import 'dart:math' show Random;

dynamic x;

foo1() async => x;
Future foo2() async => x;
Future<int> foo3() async => x;
Future<int> foo4() async => new Future<int>.value(x);
Future<int> foo5() async => new Future<String>.value(x);

bar1() async { return x; }
Future bar2() async { return x; }
Future<int> bar3() async { return x; }
Future<int> bar4() async {
  return new Future<int>.value(x);
}
Future<int> bar5() async {
  return new Future<String>.value(x);
}

int y;
Future<int> z;

baz() async {
  int a = await x;
  int b = await y;
  int c = await z;
  String d = await z;
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
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 203, 27),
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 433, 27),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 508, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 527, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 546, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 568, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 572, 7),
    ]);
  }

  test_functionTypingAndSubtyping_classes() async {
    await assertErrorsInCode('''
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
    f = top;
    f = left;
    f = right;
    f = bot;
  }
  {
    Right f;
    f = top;
    f = left;
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
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 405, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 428, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 503, 1),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 514, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 541, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 579, 1),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 590, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 603, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 653, 1),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 664, 3),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 677, 4),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 691, 5),
    ]);
  }

  test_functionTypingAndSubtyping_dynamic() async {
    await assertErrorsInCode('''
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
    f = right;
    f = bot;
  }
  {
    Right f;
    f = top;
    f = left;
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
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 308, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 383, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 421, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 459, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 483, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 536, 1),
    ]);
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
    await assertErrorsInCode('''
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
    f = botA;
    f = botTop;
    apply<ATop>(
        topA,
        topTop,
        aa,
        aTop,
        botA,
        botTop
    );
    apply<ATop>(
        (dynamic x) => new A(),
        (dynamic x) => (x as Object),
        (A x) => x,
        (A x) => null,
        botA,
        botTop
    );
  }
  {
    BotA f;
    f = topA;
    f = topTop;
    f = aa;
    f = aTop;
    f = botA;
    f = botTop;
    apply<BotA>(
        topA,
        topTop,
        aa,
        aTop,
        botA,
        botTop
    );
    apply<BotA>(
        (dynamic x) => new A(),
        (dynamic x) => (x as Object),
        (A x) => x,
        (A x) => (x as Object),
        botA,
        botTop
    );
  }
  {
    AA f;
    f = topA;
    f = topTop;
    f = aa;
    f = aTop; // known function
    f = botA;
    f = botTop;
    apply<AA>(
        topA,
        topTop,
        aa,
        aTop, // known function
        botA,
        botTop
                  );
    apply<AA>(
        (dynamic x) => new A(),
        (dynamic x) => (x as Object),
        (A x) => x,
        (A x) => (x as Object), // known function
        botA,
        botTop
    );
  }
  {
    TopTop f;
    f = topA;
    f = topTop;
    f = aa;
    f = aTop; // known function
    f = botA;
    f = botTop;
    apply<TopTop>(
        topA,
        topTop,
        aa,
        aTop, // known function
        botA,
        botTop
    );
    apply<TopTop>(
        (dynamic x) => new A(),
        (dynamic x) => (x as Object),
        (A x) => x,
        (A x) => (x as Object), // known function
        botA,
        botTop
    );
  }
  {
    TopA f;
    f = topA;
    f = topTop; // known function
    f = aa; // known function
    f = aTop; // known function
    f = botA;
    f = botTop;
    apply<TopA>(
        topA,
        topTop, // known function
        aa, // known function
        aTop, // known function
        botA,
        botTop
    );
    apply<TopA>(
        (dynamic x) => new A(),
        (dynamic x) => (x as Object), // known function
        (A x) => x, // known function
        (A x) => (x as Object), // known function
        botA,
        botTop
    );
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 401, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 822, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 889, 4),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 992, 4),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 1158, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1203, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 1228, 6),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 1256, 4),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 1331, 6),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 1359, 4),
      error(HintCode.UNNECESSARY_CAST, 1526, 11),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1591, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 1616, 6),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 1644, 4),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 1735, 6),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 1763, 4),
      error(HintCode.UNNECESSARY_CAST, 1960, 11),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2047, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 2088, 2),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 2100, 4),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 2132, 4),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 2211, 2),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 2223, 4),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 2255, 4),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 2380, 10),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION_EXPR, 2400, 22),
      error(HintCode.UNNECESSARY_CAST, 2410, 11),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 2450, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2495, 1),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 2520, 6),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 2554, 2),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 2584, 4),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 2677, 6),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 2711, 2),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 2741, 4),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION_EXPR, 2914, 10),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION_EXPR, 2952, 22),
      error(HintCode.UNNECESSARY_CAST, 2962, 11),
    ]);
  }

  test_functionTypingAndSubtyping_functionLiteralVariance() async {
    await assertErrorsInCode('''
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
    f = top;
    f = left;
    f = right;
    f = bot;
  }
  {
    Function2<A, A> f; // right
    f = top;
    f = left;
    f = right;
    f = bot;
  }
  {
    Function2<A, B> f;
    f = top;
    f = left;
    f = right;
    f = bot;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 181, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 267, 1),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 286, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 313, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 361, 1),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 381, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 394, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 456, 1),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 467, 3),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 480, 4),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 494, 5),
    ]);
  }

  test_functionTypingAndSubtyping_functionVariableVariance() async {
    await assertErrorsInCode('''
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
    left = right;
    left = bot;

    right = top;
    right = left;
    right = right;
    right = bot;

    bot = top;
    bot = left;
    bot = right;
    bot = bot;
  }
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 296, 5),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 349, 4),
    ]);
  }

  test_functionTypingAndSubtyping_higherOrderFunctionLiteral1() async {
    await assertErrorsInCode('''
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
    f = top;
    f = left;
    f = right;
    f = bot;
  }
  {
    Function2<BToA, BToA> f; // Right
    f = top;
    f = left;
    f = right;
    f = bot;
  }
  {
    Function2<BToA, AToB> f; // Bot
    f = bot;
    f = left;
    f = top;
    f = right;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 337, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 436, 1),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 455, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 482, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 536, 1),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 556, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 569, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 637, 1),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 668, 4),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 682, 3),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 695, 5),
    ]);
  }

  test_functionTypingAndSubtyping_higherOrderFunctionLiteral2() async {
    await assertErrorsInCode('''
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
    f = top;
    f = left;
    f = right;
    f = bot;
  }
  {
    Function2<BToA, BToA> f; // Right
    f = top;
    f = left;
    f = right;
    f = bot;
  }
  {
    Function2<BToA, AToB> f; // Bot
    f = bot;
    f = left;
    f = top;
    f = right;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 403, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 502, 1),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 521, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 548, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 602, 1),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 622, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 635, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 703, 1),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 734, 4),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 748, 3),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 761, 5),
    ]);
  }

  test_functionTypingAndSubtyping_higherOrderFunctionLiteral3() async {
    await assertErrorsInCode('''
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
    f = top;
    f = left;
    f = right;
    f = bot;
  }
  {
    Function2<BToA, BToA> f; // Right
    f = top;
    f = left;
    f = right;
    f = bot;
  }
  {
    Function2<BToA, AToB> f; // Bot
    f = bot;
    f = left;
    f = top;
    f = right;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 392, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 491, 1),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 510, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 537, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 591, 1),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 611, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 624, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 692, 1),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 723, 4),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 737, 3),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 750, 5),
    ]);
  }

  test_functionTypingAndSubtyping_higherOrderFunctionVariables() async {
    await assertErrorsInCode('''
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
    left = right;
    left = bot;

    right = top;
    right = left;
    right = right;
    right = bot;

    bot = top;
    bot = left;
    bot = right;
    bot = bot;
  }
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 408, 5),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 461, 4),
    ]);
  }

  test_functionTypingAndSubtyping_instanceMethodVariance() async {
    await assertErrorsInCode('''
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
    f = c.right;
    f = c.bot;
  }
  {
    Function2<A, A> f;
    f = c.top;
    f = c.left;
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
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 218, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 312, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 354, 7),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 406, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 432, 6),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 500, 1),
    ]);
  }

  test_functionTypingAndSubtyping_intAndObject() async {
    await assertErrorsInCode('''
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
    f = right;
    f = bot;
  }
  {
    Right f;
    f = top;
    f = left;
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
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 725, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 748, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 823, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 861, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 899, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 923, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 973, 1),
    ]);
  }

  test_functionTypingAndSubtyping_namedAndOptionalParameters() async {
    await assertErrorsInCode('''
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
   r = n;
   r = rr;
   r = ro;
   r = rn;
   r = oo;
   r = nn;
   r = nnn;

   o = r;
   o = o;
   o = n;
   o = rr;
   o = ro;
   o = rn;
   o = oo;
   o = nn;
   o = nnn;

   n = r;
   n = o;
   n = n;
   n = rr;
   n = ro;
   n = rn;
   n = oo;
   n = nn;
   n = nnn;

   rr = r;
   rr = o;
   rr = n;
   rr = rr;
   rr = ro;
   rr = rn;
   rr = oo;
   rr = nn;
   rr = nnn;

   ro = r;
   ro = o;
   ro = n;
   ro = rr;
   ro = ro;
   ro = rn;
   ro = oo;
   ro = nn;
   ro = nnn;

   rn = r;
   rn = o;
   rn = n;
   rn = rr;
   rn = ro;
   rn = rn;
   rn = oo;
   rn = nn;
   rn = nnn;

   oo = r;
   oo = o;
   oo = n;
   oo = rr;
   oo = ro;
   oo = rn;
   oo = oo;
   oo = nn;
   oo = nnn;

   nn = r;
   nn = o;
   nn = n;
   nn = rr;
   nn = ro;
   nn = rn;
   nn = oo;
   nn = nn;
   nn = nnn;

   nnn = r;
   nnn = o;
   nnn = n;
   nnn = rr;
   nnn = ro;
   nnn = rn;
   nnn = oo;
   nnn = nn;
   nnn = nnn;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 377, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 387, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 431, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 442, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 475, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 485, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 496, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 507, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 529, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 540, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 553, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 563, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 583, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 594, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 605, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 616, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 652, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 663, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 674, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 709, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 733, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 745, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 770, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 781, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 816, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 840, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 852, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 877, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 888, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 899, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 911, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 935, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 947, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 959, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 995, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 1030, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 1054, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 1066, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 1080, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 1091, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 1113, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 1125, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 1137, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 1149, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 1188, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 1200, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 1224, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 1237, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 1250, 2),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 1263, 2),
    ]);
  }

  test_functionTypingAndSubtyping_objectsWithCallMethods() async {
    await assertErrorsInCode('''
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
     f = new B();
     f = i2i;
     f = n2n;
     f = i2i as Object;
     f = n2n as Function;
   }
   {
     N2N f;
     f = new A();
     f = new B();
     f = i2i;
     f = n2n;
     f = i2i as Object;
     f = n2n as Function;
   }
   {
     A f;
     f = new A();
     f = new B();
     f = i2i;
     f = n2n;
     f = i2i as Object;
     f = n2n as Function;
   }
   {
     B f;
     f = new A();
     f = new B();
     f = i2i;
     f = n2n;
     f = i2i as Object;
     f = n2n as Function;
   }
   {
     Function f;
     f = new A();
     f = new B();
     f = i2i;
     f = n2n;
     f = i2i as Object;
     f = n2n as Function;
   }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 192, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 222, 7),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 254, 3),
      error(HintCode.UNNECESSARY_CAST, 268, 13),
      error(HintCode.UNNECESSARY_CAST, 292, 15),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 328, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 340, 7),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 376, 3),
      error(HintCode.UNNECESSARY_CAST, 404, 13),
      error(HintCode.UNNECESSARY_CAST, 428, 15),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 462, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 492, 7),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 510, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 524, 3),
      error(HintCode.UNNECESSARY_CAST, 538, 13),
      error(HintCode.UNNECESSARY_CAST, 562, 15),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 562, 15),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 596, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 608, 7),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 644, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 658, 3),
      error(HintCode.UNNECESSARY_CAST, 672, 13),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 696, 15),
      error(HintCode.UNNECESSARY_CAST, 696, 15),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 737, 1),
      error(HintCode.UNNECESSARY_CAST, 813, 13),
      error(HintCode.UNNECESSARY_CAST, 837, 15),
    ]);
  }

  test_functionTypingAndSubtyping_staticMethodVariance() async {
    await assertErrorsInCode('''
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
    f = C.top;
    f = C.left;
    f = C.right;
    f = C.bot;
  }
  {
    Function2<A, A> f;
    f = C.top;
    f = C.left;
    f = C.right;
    f = C.bot;
  }
  {
    Function2<A, B> f;
    f = C.top;
    f = C.left;
    f = C.right;
    f = C.bot;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 229, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 323, 1),
      error(CompileTimeErrorCode.INVALID_CAST_METHOD, 334, 5),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 365, 7),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 417, 1),
      error(CompileTimeErrorCode.INVALID_CAST_METHOD, 428, 5),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 443, 6),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 511, 1),
      error(CompileTimeErrorCode.INVALID_CAST_METHOD, 522, 5),
      error(CompileTimeErrorCode.INVALID_CAST_METHOD, 537, 6),
      error(CompileTimeErrorCode.INVALID_CAST_METHOD, 553, 7),
    ]);
  }

  test_functionTypingAndSubtyping_subtypeOfUniversalType() async {
    await assertErrorsInCode('''
void main() {
  nonGenericFn(x) => null;
  {
    R f<P, R>(P p) => null;
    T g<S, T>(S s) => null;

    var local = f;
    local = g; // valid

    // Non-generic function cannot subtype a generic one.
    local = (x) => null;
    local = nonGenericFn;
  }
  {
    Iterable<R> f<P, R>(List<P> p) => null;
    List<T> g<S, T>(Iterable<S> s) => null;

    var local = f;
    local = g; // valid

    var local2 = g;
    local = local2;
    local2 = f;
    local2 = local;

    // Non-generic function cannot subtype a generic one.
    local = (x) => null;
    local = nonGenericFn;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 110, 5),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 216, 11),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 241, 12),
      error(CompileTimeErrorCode.INVALID_CAST_FUNCTION, 449, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 543, 11),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 568, 12),
    ]);
  }

  test_functionTypingAndSubtyping_uninferredClosure() async {
    await assertErrorsInCode('''
typedef num Num2Num(num x);
void main() {
  Num2Num g = (int x) { return x; };
  print(g(42));
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 56, 21),
    ]);
  }

  test_functionTypingAndSubtyping_void() async {
    await assertNoErrorsInCode('''
class A {
  void bar() => null;
  void foo() => bar(); // allowed
}
''');
  }

  test_genericClassMethodOverride() async {
    await assertErrorsInCode('''
class A {}
class B extends A {}

class Base<T extends B> {
  T foo() => null;
}

class Derived<S extends A> extends Base<B> {
  S foo() => null;
}

class Derived2<S extends B> extends Base<B> {
  S foo() => null;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 130, 3),
    ]);
  }

  test_genericFunctionWrongNumberOfArguments() async {
    await assertErrorsInCode(r'''
T foo<T>(T x, T y) => x;
T bar<T>({T x, T y}) => x;

main() {
  String x;
  // resolving these shouldn't crash.
  foo(1, 2, 3);
  x = foo('1', '2', '3');
  foo(1);
  x = foo('1');
  x = foo(1, 2, 3);
  x = foo(1);

  // named arguments
  bar(y: 1, x: 2, z: 3);
  x = bar(z: '1', x: '2', y: '3');
  bar(y: 1);
  x = bar(x: '1', z: 42);
  x = bar(y: 1, x: 2, z: 3);
  x = bar(x: 1);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 71, 1),
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 117, 9),
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 137, 15),
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS, 159, 3),
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS, 173, 5),
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 189, 9),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 190, 1),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 193, 1),
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS, 209, 3),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 210, 1),
      error(CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER, 254, 1),
      error(CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER, 271, 1),
      error(CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER, 327, 1),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 345, 4),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 351, 4),
      error(CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER, 357, 1),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 374, 4),
    ]);
  }

  test_genericMethodOverride() async {
    await assertNoErrorsInCode('''
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
    await assertErrorsInCode(r'''
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
  A<S> create<S extends num>() => super.create<int>();
}
class F extends A<num> {
  create2<S>() => super.create</*error:TYPE_ARGUMENT_NOT_MATCHING_BOUNDS*/S>();
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_METHOD, 321, 19),
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 443, 1),
    ]);
  }

  test_genericMethodSuperSubstitute() async {
    await assertNoErrorsInCode(r'''
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
    await assertErrorsInCode('''
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
  A get f1 => null;
  C get f2 => null;
  get f3 => null;
  dynamic get f4 => null;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 162, 2),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 226, 2),
    ]);
  }

  test_getterOverride() async {
    await assertErrorsInCode('''
typedef void ToVoid<T>(T x);

class F {
  ToVoid<dynamic> get f => null;
  ToVoid<int> get g => null;
}

class G extends F {
  ToVoid<int> get f => null;
  ToVoid<dynamic> get g => null;
}

class H implements F {
  ToVoid<int> get f => null;
  ToVoid<dynamic> get g => null;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 143, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 231, 1),
    ]);
  }

  test_ifForDoWhileStatementsUseBooleanConversion() async {
    await assertErrorsInCode('''
main() {
  dynamic dyn = 42;
  Object obj = 42;
  int i = 42;
  bool b = false;

  if (b) {}
  if (dyn) {}
  if (obj) {}
  if (i) {}

  while (b) {}
  while (dyn) {}
  while (obj) {}
  while (i) {}

  do {} while (b);
  do {} while (dyn);
  do {} while (obj);
  do {} while (i);

  for (;b;) {}
  for (;dyn;) {}
  for (;obj;) {}
  for (;i;) {}
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 127, 1),
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 192, 1),
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 275, 1),
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 337, 1),
    ]);
  }

  test_implicitCasts_assignment() async {
    await _assertImplicitCasts(
      'void f(num n, int i) { i = n;}',
      [
        error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 27, 1),
      ],
    );
  }

  test_implicitCasts_compoundAssignment() async {
    await _assertImplicitCasts(
      'void f(num n, int i) { i += n; }',
      [
        error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 28, 1),
      ],
    );
  }

  test_implicitCasts_constructorInitializer() async {
    await _assertImplicitCasts(
      'class A { int i; A(num n) : i = n; }',
      [
        error(CompileTimeErrorCode.FIELD_INITIALIZER_NOT_ASSIGNABLE, 32, 1),
      ],
    );
  }

  test_implicitCasts_defaultValue() async {
    await _assertImplicitCasts(
      'const num n = 0; int f({int i = n}) => i;',
      [
        error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 32, 1),
      ],
    );
  }

  test_implicitCasts_fieldInitializer() async {
    await _assertImplicitCasts(
      'class A { static num n; int i = n; }',
      [
        error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 32, 1),
      ],
    );
  }

  test_implicitCasts_forEach() async {
    await _assertImplicitCasts(r'''
void f(dynamic a) {
  for (int v in a) {
    v;
  }
}
''', [
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 36, 1),
    ]);
  }

  test_implicitCasts_forEach_async() async {
    await _assertImplicitCasts(r'''
void f(dynamic a) async {
  await for (int v in a) {
    v;
  }
}
''', [
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 48, 1),
    ]);
  }

  test_implicitCasts_functionCall() async {
    await _assertImplicitCasts(r'''
int f(int i) => i;
num n = 0;
var v = f(n);
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 40, 1),
    ]);
  }

  test_implicitCasts_genericMethods() async {
    await _assertImplicitCasts(r'''
var x = <String>[].map<String>((x) => '');
''', []);
  }

  test_implicitCasts_initializer() async {
    await _assertImplicitCasts(r'''
num n = 0;
int i = n;
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 19, 1),
    ]);
  }

  test_implicitCasts_list_ifElement_condition_dynamic() async {
    await _assertImplicitCasts(r'''
void f(dynamic c) {
  <int>[if (c) 0];
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 32, 1),
    ]);
  }

  test_implicitCasts_list_ifElement_condition_object() async {
    await _assertImplicitCasts(r'''
void f(Object c) {
  <int>[if (c) 0];
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 31, 1),
    ]);
  }

  test_implicitCasts_list_ifElement_falseBranch_dynamic() async {
    await _assertImplicitCasts(r'''
void f(bool c, dynamic a) {
  <int>[if (c) 0 else a];
}
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 50, 1),
    ]);
  }

  test_implicitCasts_list_ifElement_falseBranch_supertype() async {
    await _assertImplicitCasts(r'''
void f(bool c, num a) {
  <int>[if (c) 0 else a];
}
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 46, 1),
    ]);
  }

  test_implicitCasts_list_ifElement_trueBranch_dynamic() async {
    await _assertImplicitCasts(r'''
void f(bool c, dynamic a) {
  <int>[if (c) a];
}
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 43, 1),
    ]);
  }

  test_implicitCasts_list_ifElement_trueBranch_supertype() async {
    await _assertImplicitCasts(r'''
void f(bool c, num a) {
  <int>[if (c) a];
}
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 39, 1),
    ]);
  }

  test_implicitCasts_map_ifElement_condition_dynamic() async {
    await _assertImplicitCasts(r'''
void f(dynamic c) {
  <int, int>{if (c) 0: 0};
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 37, 1),
    ]);
  }

  test_implicitCasts_map_ifElement_condition_object() async {
    await _assertImplicitCasts(r'''
void f(Object c) {
  <int, int>{if (c) 0: 0};
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 36, 1),
    ]);
  }

  test_implicitCasts_map_ifElement_falseBranch_key_dynamic() async {
    await _assertImplicitCasts(r'''
void f(bool c, dynamic a) {
  <int, int>{if (c) 0: 0 else a: 0};
}
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 58, 1),
    ]);
  }

  test_implicitCasts_map_ifElement_falseBranch_key_supertype() async {
    await _assertImplicitCasts(r'''
void f(bool c, num a) {
  <int, int>{if (c) 0: 0 else a: 0};
}
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 54, 1),
    ]);
  }

  test_implicitCasts_map_ifElement_falseBranch_value_dynamic() async {
    await _assertImplicitCasts(r'''
void f(bool c, dynamic a) {
  <int, int>{if (c) 0: 0 else 0: a};
}
''', [
      error(CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE, 61, 1),
    ]);
  }

  test_implicitCasts_map_ifElement_falseBranch_value_supertype() async {
    await _assertImplicitCasts(r'''
void f(bool c, num a) {
  <int, int>{if (c) 0: 0 else 0: a};
}
''', [
      error(CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE, 57, 1),
    ]);
  }

  test_implicitCasts_map_ifElement_trueBranch_key_dynamic() async {
    await _assertImplicitCasts(r'''
void f(bool c, dynamic a) {
  <int, int>{if (c) a: 0 };
}
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 48, 1),
    ]);
  }

  test_implicitCasts_map_ifElement_trueBranch_key_supertype() async {
    await _assertImplicitCasts(r'''
void f(bool c, num a) {
  <int, int>{if (c) a: 0};
}
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 44, 1),
    ]);
  }

  test_implicitCasts_map_ifElement_trueBranch_value_dynamic() async {
    await _assertImplicitCasts(r'''
void f(bool c, dynamic a) {
  <int, int>{if (c) 0: a};
}
''', [
      error(CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE, 51, 1),
    ]);
  }

  test_implicitCasts_map_ifElement_trueBranch_value_supertype() async {
    await _assertImplicitCasts(r'''
void f(bool c, num a) {
  <int, int>{if (c) 0: a};
}
''', [
      error(CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE, 47, 1),
    ]);
  }

  test_implicitCasts_numericOps() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26912
    await _assertImplicitCasts(r'''
void f(int x, int y) {
  x += y;
}
''', []);
  }

  test_implicitCasts_operator() async {
    await _assertImplicitCasts(r'''
num n = 0;
int i = 0;
var v = i & n;
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 34, 1),
    ]);
  }

  test_implicitCasts_return() async {
    await _assertImplicitCasts('int f(num n) => n;', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 16, 1),
    ]);
  }

  test_implicitCasts_return_async() async {
    await _assertImplicitCasts(r'''
Future<List<String>> f() async {
  List<Object> x = <Object>['hello', 'world'];
  return x;
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 89, 1),
    ]);
  }

  test_implicitCasts_set_ifElement_condition_dynamic() async {
    await _assertImplicitCasts(r'''
void f(dynamic c) {
  <int>{if (c) 0};
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 32, 1),
    ]);
  }

  test_implicitCasts_set_ifElement_condition_object() async {
    await _assertImplicitCasts(r'''
void f(Object c) {
  <int>{if (c) 0};
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 31, 1),
    ]);
  }

  test_implicitCasts_set_ifElement_falseBranch_dynamic() async {
    await _assertImplicitCasts(r'''
void f(bool c, dynamic a) {
  <int>{if (c) 0 else a};
}
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 50, 1),
    ]);
  }

  test_implicitCasts_set_ifElement_falseBranch_supertype() async {
    await _assertImplicitCasts(r'''
void f(bool c, num a) {
  <int>{if (c) 0 else a};
}
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 46, 1),
    ]);
  }

  test_implicitCasts_set_ifElement_trueBranch_dynamic() async {
    await _assertImplicitCasts(r'''
void f(bool c, dynamic a) {
  <int>{if (c) a};
}
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 43, 1),
    ]);
  }

  test_implicitCasts_set_ifElement_trueBranch_supertype() async {
    await _assertImplicitCasts(r'''
void f(bool c, num a) {
  <int>{if (c) a};
}
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 39, 1),
    ]);
  }

  @failingTest
  test_implicitCasts_test_list_spread_dynamic() async {
    // TODO(mfairhurst) fix this, see https://github.com/dart-lang/sdk/issues/36267
    await _assertImplicitCasts(r'''
void f(dynamic a) {
  [...a];
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 26, 1),
    ]);
  }

  test_implicitCasts_test_list_spread_supertype() async {
    await _assertImplicitCasts(r'''
void f(Iterable<num> a) {
  <int>[...a];
}
''', [
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 37, 1),
    ]);
  }

  @failingTest
  test_implicitCasts_test_map_spread_dynamic() async {
    // TODO(mfairhurst) fix this, see https://github.com/dart-lang/sdk/issues/36267
    await _assertImplicitCasts(r'''
void f(dynamic a) {
  <dynamic, dynamic>{...a};
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 44, 1),
    ]);
  }

  test_implicitCasts_test_map_spread_key_supertype() async {
    await _assertImplicitCasts(r'''
void f(Map<num, dynamic> a) {
  <int, dynamic>{...a};
}
''', [
      error(CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE, 50, 1),
    ]);
  }

  test_implicitCasts_test_map_spread_value_supertype() async {
    await _assertImplicitCasts(r'''
void f(Map<dynamic, num> a) {
  <dynamic, int>{...a};
}
''', [
      error(CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE, 50, 1),
    ]);
  }

  @failingTest
  test_implicitCasts_test_set_spread_dynamic() async {
    // TODO(mfairhurst) fix this, see https://github.com/dart-lang/sdk/issues/36267
    await _assertImplicitCasts(r'''
void f(dynamic a) {
  <dynamic>{...a};
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 35, 1),
    ]);
  }

  test_implicitCasts_test_set_spread_supertype() async {
    await _assertImplicitCasts(r'''
void f(Iterable<num> a) {
  <int>{...a};
}
''', [
      error(CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 37, 1),
    ]);
  }

  test_implicitDynamic_field() async {
    _disableTestPackageImplicitDynamic();
    await assertErrorsInCode(r'''
class C {
  var x0;
  var x1 = (<dynamic>[])[0];
  var x2, x3 = 42, x4;
  dynamic y0;
  dynamic y1 = (<dynamic>[])[0];
}
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_FIELD, 16, 2),
      error(LanguageCode.IMPLICIT_DYNAMIC_FIELD, 26, 21),
      error(LanguageCode.IMPLICIT_DYNAMIC_FIELD, 55, 2),
      error(LanguageCode.IMPLICIT_DYNAMIC_FIELD, 68, 2),
    ]);
  }

  test_implicitDynamic_function() async {
    _disableTestPackageImplicitDynamic();
    await assertErrorsInCode(r'''
T a<T>(T t) => t;
T b<T>() => null;

void main<S>() {
  dynamic d;
  int i;
  a(d);
  a(42);
  b();
  d = b();
  i = b();

  void f<T>(T t) {};
  T g<T>() => null;

  f(d);
  f(42);
  g();
  d = g();
  i = g();

  (<T>(T t) => t)(d);
  (<T>(T t) => t)(42);
  (<T>() => null as T)<int>();
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 73, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_FUNCTION, 78, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_FUNCTION, 95, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_FUNCTION, 106, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_FUNCTION, 167, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_FUNCTION, 184, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_FUNCTION, 195, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_INVOKE, 214, 15),
      error(HintCode.UNNECESSARY_CAST, 269, 9),
    ]);
  }

  test_implicitDynamic_listLiteral() async {
    _disableTestPackageImplicitDynamic();
    await assertErrorsInCode(r'''
var l0 = [];
List l1 = [];
List<dynamic> l2 = [];
dynamic d = 42;
var l3 = [d, d];

var l4 = <dynamic>[];
var l5 = <int>[];
List<int> l6 = [];
var l7 = [42];
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_LIST_LITERAL, 9, 2),
      error(LanguageCode.IMPLICIT_DYNAMIC_LIST_LITERAL, 23, 2),
      error(LanguageCode.IMPLICIT_DYNAMIC_LIST_LITERAL, 46, 2),
      error(LanguageCode.IMPLICIT_DYNAMIC_LIST_LITERAL, 75, 6),
    ]);
  }

  test_implicitDynamic_mapLiteral() async {
    _disableTestPackageImplicitDynamic();
    await assertErrorsInCode(r'''
var m0 = {};
Map m1 = {};
Map<dynamic, dynamic> m2 = {};
dynamic d = 42;
var m3 = {d: d};
var m4 = {'x': d, 'y': d};
var m5 = {d: 'x'};

var m6 = <dynamic, dynamic>{};
var m7 = <String, String>{};
Map<String, String> m8 = {};
var m9 = {'hi': 'there'};
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_MAP_LITERAL, 9, 2),
      error(LanguageCode.IMPLICIT_DYNAMIC_MAP_LITERAL, 22, 2),
      error(LanguageCode.IMPLICIT_DYNAMIC_MAP_LITERAL, 53, 2),
      error(LanguageCode.IMPLICIT_DYNAMIC_MAP_LITERAL, 82, 6),
      error(LanguageCode.IMPLICIT_DYNAMIC_MAP_LITERAL, 99, 16),
      error(LanguageCode.IMPLICIT_DYNAMIC_MAP_LITERAL, 126, 8),
    ]);
  }

  test_implicitDynamic_method() async {
    _disableTestPackageImplicitDynamic();
    await assertErrorsInCode(r'''
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
  new C().m(d);
  new C().m(42);
  new C().n();
  d = new C().n();
  i = new C().n();

  new D<int>().m(d);
  new D<int>().m(42);
  new D<int>().n();
  d = new D<int>().n();
  i = new D<int>().n();
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 137, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_METHOD, 150, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_METHOD, 183, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_METHOD, 202, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_METHOD, 242, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_METHOD, 285, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_METHOD, 309, 1),
    ]);
  }

  test_implicitDynamic_parameter() async {
    _disableTestPackageImplicitDynamic();
    await assertErrorsInCode(r'''
const dynamic DYNAMIC_VALUE = 42;

// simple formal
void f0(x) {}
void f1(dynamic x) {}

// default formal
void df0([x = DYNAMIC_VALUE]) {}
void df1([dynamic x = DYNAMIC_VALUE]) {}

// https://github.com/dart-lang/sdk/issues/25794
void df2([x = 42]) {}

// default formal (named)
void nf0({x: DYNAMIC_VALUE}) {}
void nf1({dynamic x: DYNAMIC_VALUE}) {}

// https://github.com/dart-lang/sdk/issues/25794
void nf2({x: 42}) {}

// field formal
class C {
  var x;
  C(this.x);
}

// function typed formal
void ftf0(void x(y)) {}
void ftf1(void x(int y)) {}
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_PARAMETER, 60, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_PARAMETER, 117, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_PARAMETER, 241, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_PARAMETER, 290, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_PARAMETER, 412, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_FIELD, 456, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_PARAMETER, 517, 1),
    ]);
  }

  test_implicitDynamic_return() async {
    _disableTestPackageImplicitDynamic();
    await assertErrorsInCode(r'''
// function
f0() {return f0();}
dynamic f1() { return 42; }

// nested function
void main() {
  g0() {return g0();}
  dynamic g1() { return 42; }
}

// methods
class B {
  int m1() => 42;
}
class C extends B {
  m0() => 123;
  m1() => 123;
  dynamic m2() => 'hi';
}

// accessors
set x(int value) {}
get y0 => 42;
dynamic get y1 => 42;

// function typed formals
void ftf0(f(int x)) {}
void ftf1(dynamic f(int x)) {}

// function expressions
var fe0 = (int x) => x as dynamic;
var fe1 = (int x) => x;
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_RETURN, 12, 2),
      error(LanguageCode.IMPLICIT_DYNAMIC_RETURN, 96, 2),
      error(HintCode.UNUSED_ELEMENT, 96, 2),
      error(HintCode.UNUSED_ELEMENT, 126, 2),
      error(LanguageCode.IMPLICIT_DYNAMIC_RETURN, 212, 12),
      error(LanguageCode.IMPLICIT_DYNAMIC_RETURN, 304, 2),
      error(LanguageCode.IMPLICIT_DYNAMIC_RETURN, 373, 1),
    ]);
  }

  test_implicitDynamic_static() async {
    _disableTestPackageImplicitDynamic();
    await assertNoErrorsInCode(r'''
class C {
  static void test(int body()) {}
}

void main() {
  C.test(()  {
    return 42;
  });
}
''');
  }

  test_implicitDynamic_type() async {
    _disableTestPackageImplicitDynamic();
    await assertErrorsInCode(r'''
class C<T> {}
class M1<T extends List> {}
class M2<T> {}
class I<T> {}
class D<T, S> extends C
    with M1, M2
    implements I {}
class D2<T, S> = C
    with M1, M2
    implements I;

C f(D d) {
  D x = new D();
  D<int, dynamic> y = new D();
  D<dynamic, int> z = new D();
  return new C();
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
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_TYPE, 33, 4),
      error(LanguageCode.IMPLICIT_DYNAMIC_TYPE, 93, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_TYPE, 108, 2),
      error(LanguageCode.IMPLICIT_DYNAMIC_TYPE, 126, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_TYPE, 148, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_TYPE, 163, 2),
      error(LanguageCode.IMPLICIT_DYNAMIC_TYPE, 181, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 200, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_TYPE, 208, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 231, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_TYPE, 239, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 262, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_TYPE, 270, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_TYPE, 288, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 493, 1),
    ]);
  }

  test_implicitDynamic_variable() async {
    _disableTestPackageImplicitDynamic();
    await assertErrorsInCode(r'''
var x0;
var x1 = (<dynamic>[])[0];
var x2, x3 = 42, x4;
dynamic y0;
dynamic y1 = (<dynamic>[])[0];
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_VARIABLE, 4, 2),
      error(LanguageCode.IMPLICIT_DYNAMIC_VARIABLE, 12, 21),
      error(LanguageCode.IMPLICIT_DYNAMIC_VARIABLE, 39, 2),
      error(LanguageCode.IMPLICIT_DYNAMIC_VARIABLE, 52, 2),
    ]);
  }

  test_interfaceOverridesAreAllChecked() {
    // Regression test for https://github.com/dart-lang/sdk/issues/29766
    return assertErrorsInCode(r'''
class B {
  set x(int y) {}
}
class C {
  set x(Object y) {}
}
class D implements B, C {
  int x;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 95, 1),
    ]);
  }

  test_interfacesFromMixinsAreChecked() {
    // Regression test for https://github.com/dart-lang/sdk/issues/29782
    return assertErrorsInCode(r'''
abstract class I {
  set x(int v);
}
abstract class M implements I {}

class C extends Object with M {
  String x;
}

abstract class M2 = Object with M;

class C2 extends Object with M2 {
  String x;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 112, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 197, 1),
    ]);
  }

  test_interfacesFromMixinsOnlyConsiderMostDerivedMember() {
    // Regression test for dart2js interface pattern in strong mode.
    return assertNoErrorsInCode(r'''
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
    return assertErrorsInCode(r'''
abstract class I<E> {
  set x(E v);
}
abstract class M<E> implements I<E> {}

class C extends Object with M<int> {
  String x;
}

abstract class D extends Object with M<num> {}
  
class E extends D with M<int> {
  int x;
}
  
class F extends D with M<int> {
  num x;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 124, 1),
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 180, 42),
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 180, 42),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 218, 1),
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 226, 42),
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 226, 42),
    ]);
  }

  test_invalidOverrides_baseClassOverrideToChildInterface() async {
    await assertErrorsInCode('''
class A {}
class B {}

abstract class I {
  m(A a);
}

class Base {
  m(B a) {}
}

class T1 extends Base implements I {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 89, 2),
    ]);
  }

  test_invalidOverrides_childOverride() async {
    await assertErrorsInCode('''
class A {}
class B {}

class Base {
    A f;
}

class T1 extends Base {
  B get f => null;
}

class T2 extends Base {
  set f(B b) => null;
}

class T3 extends Base {
  final B f;
}
class T4 extends Base {
  // two: one for the getter one for the setter.
  B f;
}

class T5 implements Base {
  B get f => null;
}

class T6 implements Base {
  set f(B b) => null;
}

class T7 implements Base {
  final B f = null;
}
class T8 implements Base {
  // two: one for the getter one for the setter.
  B f;
}
''', [
      error(CompileTimeErrorCode.GETTER_NOT_ASSIGNABLE_SETTER_TYPES, 80, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 80, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 124, 1),
      error(CompileTimeErrorCode.GETTER_NOT_ASSIGNABLE_SETTER_TYPES, 124, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 177, 1),
      error(CompileTimeErrorCode.GETTER_NOT_ASSIGNABLE_SETTER_TYPES, 177, 1),
      error(CompileTimeErrorCode.FINAL_NOT_INITIALIZED, 177, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 259, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 259, 1),
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          271,
          2),
      error(CompileTimeErrorCode.GETTER_NOT_ASSIGNABLE_SETTER_TYPES, 300, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 300, 1),
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          320,
          2),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 347, 1),
      error(CompileTimeErrorCode.GETTER_NOT_ASSIGNABLE_SETTER_TYPES, 347, 1),
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          372,
          2),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 403, 1),
      error(CompileTimeErrorCode.GETTER_NOT_ASSIGNABLE_SETTER_TYPES, 403, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 495, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 495, 1),
    ]);
  }

  test_invalidOverrides_childOverride2() async {
    await assertErrorsInCode('''
class A {}
class B {}

class Base {
  m(A a) {}
}

class Test extends Base {
  m(B a) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 79, 1),
    ]);
  }

  test_invalidOverrides_classOverrideOfInterface() async {
    await assertErrorsInCode('''
class A {}
class B {}

abstract class I {
  m(A a);
}

class T1 implements I {
  m(B a) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 81, 1),
    ]);
  }

  test_invalidOverrides_doubleOverride() async {
    await assertErrorsInCode('''
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
  m(B a) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 162, 1),
    ]);
  }

  test_invalidOverrides_doubleOverride2() async {
    await assertErrorsInCode('''
class A {}
class B {}

class Grandparent {
  m(A a) {}
}

class Parent extends Grandparent {
  m(B a) {}
}

class Test extends Parent {
  m(B a) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 95, 1),
    ]);
  }

  test_invalidOverrides_grandChildOverride() async {
    await assertErrorsInCode('''
class A {}
class B {}

class Grandparent {
  m(A a) {}
  int x;
}

class Parent extends Grandparent {
}

class Test extends Parent {
  m(B a) {}
  int x;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 135, 1),
    ]);
  }

  test_invalidOverrides_mixinOverrideOfInterface() async {
    await assertErrorsInCode('''
class A {}
class B {}

abstract class I {
  m(A a);
}

class M {
  m(B a) {}
}

class T1 extends Object with M implements I {}

class U1 = Object with M implements I;
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 86, 2),
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 134, 2),
    ]);
  }

  test_invalidOverrides_mixinOverrideToBase() async {
    await assertErrorsInCode('''
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

class T1 extends Base with M1 {}
class T2 extends Base with M1, M2 {}
class T3 extends Base with M2, M1 {}

class U1 = Base with M1;
class U2 = Base with M1, M2;
class U3 = Base with M2, M1;
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 144, 2),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 177, 2),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 218, 2),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 246, 2),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 271, 2),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 304, 2),
    ]);
  }

  test_invalidOverrides_mixinOverrideToMixin() async {
    await assertErrorsInCode('''
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

class T1 extends Base with M1, M2 {}

class U1 = Base with M1, M2;
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 148, 2),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 180, 2),
    ]);
  }

  @failingTest
  test_invalidOverrides_noDuplicateMixinOverride() async {
    // This is a regression test for a bug in an earlier implementation were
    // names were hiding errors if the first mixin override looked correct,
    // but subsequent ones did not.
    await assertNoErrorsInCode('''
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

class T1 extends Base with M1, M2, M3 {}

class U1 = Base with M1, M2, M3;
''');
  }

  test_invalidOverrides_noErrorsIfSubclassCorrectlyOverrideBaseAndInterface() async {
    // This is a case were it is incorrect to say that the base class
    // incorrectly overrides the interface.
    await assertErrorsInCode('''
class A {}
class B {}

class Base {
  void m(A a) {}
}

class I1 {
  void m(B a) {}
}

class T1 extends Base implements I1 {}

class T2 extends Base implements I1 {
  void m(dynamic a) {}
}

class T3 extends Object with Base implements I1 {}

class U3 = Object with Base implements I1;

class T4 extends Object with Base implements I1 {
  void m(dynamic a) {}
}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 93, 2),
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 197, 2),
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 249, 2),
    ]);
  }

  test_invalidRuntimeChecks() async {
    await assertErrorsInCode('''
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
  f = foo as I2I;
  f = foo as D2I;
  f = foo as I2D;
  f = foo as D2D;

  f = bar as II2I;
  f = bar as DI2I;
  f = bar as ID2I;
  f = bar as II2D;
  f = bar as DD2I;
  f = bar as DI2D;
  f = bar as ID2D;
  f = bar as DD2D;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 365, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 665, 1),
      error(HintCode.UNNECESSARY_CAST, 674, 10),
      error(HintCode.UNNECESSARY_CAST, 710, 10),
      error(HintCode.UNNECESSARY_CAST, 747, 11),
      error(HintCode.UNNECESSARY_CAST, 804, 11),
    ]);
  }

  test_leastUpperBounds() async {
    await assertErrorsInCode('''
typedef T Returns<T>();

// regression test for https://github.com/dart-lang/sdk/issues/26094
class A <S extends Returns<S>, T extends Returns<T>> {
  int test(bool b) {
    S s;
    T t;
    if (b) {
      return b ? s : t;
    } else {
      return s ?? t;
    }
  }
}

class B<S, T extends S> {
  T t;
  S s;
  int test(bool b) {
    return b ? t : s;
  }
}

class C {
  // Check that the least upper bound of two types with the same
  // class but different type arguments produces the pointwise
  // least upper bound of the type arguments
  int test1(bool b) {
    List<int> li;
    List<double> ld;
    return b ? li : ld;
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
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_METHOD, 214, 9),
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_METHOD, 251, 6),
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_METHOD, 344, 9),
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_METHOD, 617, 11),
      error(TodoCode.TODO, 639, 59),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 878, 1),
    ]);
  }

  test_methodOverride() async {
    await assertErrorsInCode('''
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
  A m1(A value) => null;
  C m2(C value) => null;
  A m3(C value) => null;
  C m4(A value) => null;
  m5(value) => null;
  dynamic m6(dynamic value) => null;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 227, 2),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 252, 2),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 277, 2),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 354, 2),
    ]);
  }

  test_methodOverride_contravariant() async {
    await assertErrorsInCode('''
abstract class A {
  bool operator ==(Object object);
}

class B implements A {}

class F {
  void f(x) {}
  void g(int x) {}
}

class G extends F {
  void f(int x) {}
  void g(dynamic x) {}
}

class H implements F {
  void f(int x) {}
  void g(dynamic x) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 156, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 224, 1),
    ]);
  }

  test_methodTearoffStrictArrow() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/26393
    await assertNoErrorsInCode(r'''
class A {
  void foo(dynamic x) {}
  void test(void f(int x)) {
    test(foo);
  }
}
''');
  }

  test_mixinApplicationIsConcrete() {
    return assertErrorsInCode(r'''
class A {
  int get foo => 3;
}

class B {
  num get foo => 3.0;
}

class C = Object with B;

class D extends Object with C implements A {}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 100, 1),
    ]);
  }

  test_mixinOverrideOfGrandInterface_interfaceOfAbstractSuperclass() async {
    await assertErrorsInCode('''
class A {}
class B {}

abstract class I1 {
  m(A a);
}

abstract class Base implements I1 {}

class M {
  m(B a) {}
}

class T1 extends Base with M {}

class U1 = Base with M;
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 146, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 173, 1),
    ]);
  }

  test_mixinOverrideOfGrandInterface_interfaceOfConcreteSuperclass() async {
    await assertErrorsInCode('''
class A {}
class B {}

abstract class I1 {
  m(A a);
}

class Base implements I1 {}

class M {
  m(B a) {}
}

class T1 extends Base with M {}

class U1 = Base with M;
''', [
      error(
          CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          62,
          4),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 137, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 164, 1),
    ]);
  }

  test_mixinOverrideOfGrandInterface_interfaceOfInterfaceOfChild() async {
    await assertErrorsInCode('''
class A {}
class B {}

abstract class I1 {
  m(A a);
}

abstract class I2 implements I1 {}

class M {
  m(B a) {}
}

class T1 extends Object with M implements I2 {}

class U1 = Object with M implements I2;
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 123, 2),
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 172, 2),
    ]);
  }

  test_mixinOverrideOfGrandInterface_mixinOfInterfaceOfChild() async {
    await assertErrorsInCode('''
class A {}
class B {}

abstract class M1 {
    m(A a);
}

abstract class I2 extends Object with M1 {}

class M {
  m(B a) {}
}

class T1 extends Object with M implements I2 {}

class U1 = Object with M implements I2;
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 134, 2),
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 183, 2),
    ]);
  }

  test_mixinOverrideOfGrandInterface_superclassOfInterfaceOfChild() async {
    await assertErrorsInCode('''
class A {}
class B {}

abstract class I1 {
  m(A a);
}

abstract class I2 extends I1 {}

class M {
  m(B a) {}
}

class T1 extends Object with M implements I2 {}

class U1 = Object with M implements I2;
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 120, 2),
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 169, 2),
    ]);
  }

  test_noDuplicateReports_baseTypeAndMixinOverrideSameMethodInInterface() async {
    await assertErrorsInCode('''
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
class T1 extends Base with M implements I1 {}

class U1 = Base with M implements I1;
''', [
      error(TodoCode.TODO, 112, 74),
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 309, 2),
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 356, 2),
    ]);
  }

  test_noDuplicateReports_twoGrandTypesOverrideSameMethodInInterface() async {
    await assertErrorsInCode('''
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
class T1 extends Parent1 implements I1 {}
class T2 extends Parent2 implements I1 {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 247, 2),
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 289, 2),
    ]);
  }

  test_noDuplicateReports_twoMixinsOverrideSameMethodInInterface() async {
    await assertErrorsInCode('''
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

class T1 extends Object with M1, M2 implements I1 {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 114, 2),
    ]);
  }

  test_noDuplicateReports_typeAndBaseTypeOverrideSameMethodInInterface() async {
    await assertErrorsInCode('''
class A {}
class B {}

abstract class I1 {
  void m(A a);
}

class Base {
  void m(B a) {}
}

class T1 extends Base implements I1 {
  void m(B a) {}
}

class T2 extends Base implements I1 {}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 139, 1),
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 158, 2),
    ]);
  }

  test_noDuplicateReports_typeAndMixinOverrideSameMethodInInterface() async {
    await assertErrorsInCode('''
class A {}
class B {}

abstract class I1 {
  void m(A a);
}

class M {
  void m(B a) {}
}

class T1 extends Object with M implements I1 {
  void m(B a) {}
}

class T2 extends Object with M implements I1 {}

class U2 = Object with M implements I1;
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 145, 1),
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 164, 2),
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 213, 2),
    ]);
  }

  test_noDuplicateReports_typeOverridesSomeMethodInMultipleInterfaces() async {
    await assertErrorsInCode('''
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
  m(B a) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 145, 1),
    ]);
  }

  test_nullCoalescingOperator() async {
    await assertNoErrorsInCode('''
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
    await assertNoErrorsInCode(r'''
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
    await assertErrorsInCode(r'''
void takesF(void f(int x)) {
  takesF(([x]) { bool z = x.isEven; });
  takesF((y) { bool z = y.isEven; });
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 51, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 89, 1),
    ]);
  }

  test_overrideNarrowsType() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {}

abstract class C {
  void m(A a);
  void n(B b);
}

abstract class D extends C {
  void m(B b);
  void n(A a);
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 121, 1),
    ]);
  }

  test_overrideNarrowsType_legalWithChecked() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/25232
    await assertNoErrorsInCode(r'''
abstract class A { void test(A arg) { } }
abstract class B extends A { void test(covariant B arg) { } }
abstract class X implements A { }
class C extends B with X { }
class D extends B implements A { }
''');
  }

  test_overrideNarrowsType_noDuplicateError() {
    // Regression test for https://github.com/dart-lang/sdk/issues/25232
    return assertErrorsInCode(r'''
abstract class A { void test(A arg) { } }
abstract class B extends A {
  void test(B arg) { }
}
abstract class X implements A { }

class C extends B {}

class D extends B with X { }

class E extends B implements A { }
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 78, 4),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 159, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 189, 1),
    ]);
  }

  test_privateOverride() async {
    newFile('$testPackageLibPath/helper.dart', content: r'''
import 'test.dart' as main;

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

  String _m1() => null;
}
''');

    await assertErrorsInCode('''
import 'helper.dart' as helper;

class Child extends helper.Base {
  var f1;
  var _f2;
  var _f4;

  String _m1() => null;
}
''', [
      error(HintCode.UNUSED_FIELD, 83, 3),
      error(HintCode.UNUSED_FIELD, 94, 3),
      error(HintCode.UNUSED_ELEMENT, 109, 3),
    ]);
  }

  test_proxy() {
    return assertErrorsInCode(r'''
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
  c.m();
  c.m;
  -c;
  c + 7;
  c[7];
  c();

  F f = new F();
  f();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 332, 1),
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 341, 1),
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 346, 1),
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 354, 1),
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 362, 3),
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 369, 1),
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 394, 1),
    ]);
  }

  test_redirectingConstructor() async {
    await assertErrorsInCode('''
class A {
  A(A x) {}
  A.two() : this(3);
}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 39, 1),
    ]);
  }

  test_relaxedCasts() async {
    await assertErrorsInCode('''
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
    lOfAs = mOfDs;
    lOfAs = mOfOs;
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
    mOfDs = lOfAs;
    mOfDs = new M(); // Reset type propagation.
  }
  {
    mOfOs = mOfDs;
    mOfOs = mOfOs;
    mOfOs = mOfAs;
    mOfOs = lOfDs;
    mOfOs = lOfOs;
    mOfOs = lOfAs;
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
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 764, 5),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 783, 5),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 1032, 5),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 1202, 5),
    ]);
  }

  test_setterOverride() async {
    await assertErrorsInCode('''
typedef void ToVoid<T>(T x);
class F {
  void set f(ToVoid<dynamic> x) {}
  void set g(ToVoid<int> x) {}
  void set h(dynamic x) {}
  void set i(int x) {}
}

class G extends F {
  void set f(ToVoid<int> x) {}
  void set g(ToVoid<dynamic> x) {}
  void set h(int x) {}
  void set i(dynamic x) {}
}

class H implements F {
  void set f(ToVoid<int> x) {}
  void set g(ToVoid<dynamic> x) {}
  void set h(int x) {}
  void set i(dynamic x) {}
}
 ''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 220, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 255, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 362, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 397, 1),
    ]);
  }

  test_setterReturnTypes() async {
    await assertErrorsInCode('''
void voidFn() => null;
class A {
  set a(y) => 4;
  set b(y) => voidFn();
  void set c(y) => 4;
  void set d(y) => voidFn();
  int set e(y) => 4;
  int set f(y) =>
    voidFn();
  set g(y) {return 4;}
  void set h(y) {return 4;}
  int set i(y) {return 4;}
}
''', [
      error(CompileTimeErrorCode.NON_VOID_RETURN_FOR_SETTER, 127, 3),
      error(CompileTimeErrorCode.NON_VOID_RETURN_FOR_SETTER, 148, 3),
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 168, 8),
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 197, 1),
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 225, 1),
      error(CompileTimeErrorCode.NON_VOID_RETURN_FOR_SETTER, 231, 3),
    ]);
  }

  test_setterSetterOverride() async {
    await assertErrorsInCode('''
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
  void set f2(C value) {}
  void set f3(value) {}
  void set f4(dynamic value) {}
  set f5(B value) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 263, 2),
    ]);
  }

  test_strictInference_instanceCreation() async {
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        strictInference: true,
      ),
    );

    await assertErrorsInCode(r'''
class C<T> {
  C([T t]);
  C.of(T t);
  factory C.from(Object e) => C();
}

void f() {
  // These should be allowed:
  C<int> downwardsInferenceIsOK = C();
  C<dynamic> downwardsInferenceDynamicIsOK = C();
  var inferredFromConstructorParameterIsOK = C(42);
  var explicitDynamicIsOK = C<dynamic>(42);

  var rawConstructorCall = C();
  var factoryConstructor = C.from(42);
  var upwardsInfersDynamic = C(42 as dynamic);
  var namedConstructor = C.of(42 as dynamic);
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 126, 22),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 169, 29),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 212, 36),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 264, 19),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 309, 18),
      error(HintCode.INFERENCE_FAILURE_ON_INSTANCE_CREATION, 330, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 341, 18),
      error(HintCode.INFERENCE_FAILURE_ON_INSTANCE_CREATION, 362, 6),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 380, 20),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 427, 16),
    ]);
  }

  test_superCallPlacement() async {
    await assertErrorsInCode('''
class Base {
  var x;
  Base() : x = print('Base.1') { print('Base.2'); }
}

class Derived extends Base {
  var y, z;
  Derived()
      : y = print('Derived.1'),
        super(),
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
''', [
      error(CompileTimeErrorCode.INVALID_SUPER_INVOCATION, 170, 5),
    ]);
  }

  test_superclassOverrideOfGrandInterface_interfaceOfAbstractSuperclass() async {
    await assertErrorsInCode('''
class A {}
class B {}

abstract class I1 {
    m(A a);
}

abstract class Base implements I1 {
  m(B a) {}
}

class T1 extends Base {
    m(B a) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 96, 1),
    ]);
  }

  test_superclassOverrideOfGrandInterface_interfaceOfConcreteSuperclass() async {
    await assertErrorsInCode('''
class A {}
class B {}

abstract class I1 {
  m(A a);
}

class Base implements I1 {
  m(B a) {}
}

class T1 extends Base {
  m(B a) {}
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 85, 1),
    ]);
  }

  test_superclassOverrideOfGrandInterface_interfaceOfInterfaceOfChild() async {
    await assertErrorsInCode('''
class A {}
class B {}

abstract class I1 {
  m(A a);
}

abstract class I2 implements I1 {}

class Base {
  m(B a) {}
}

class T1 extends Base implements I2 {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 126, 2),
    ]);
  }

  test_superclassOverrideOfGrandInterface_mixinOfInterfaceOfChild() async {
    await assertErrorsInCode('''
class A {}
class B {}

abstract class M1 {
  m(A a);
}

abstract class I2 extends Object with M1 {}

class Base {
  m(B a) {}
}

class T1 extends Base implements I2 {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 135, 2),
    ]);
  }

  test_superclassOverrideOfGrandInterface_superclassOfInterfaceOfChild() async {
    await assertErrorsInCode('''
class A {}
class B {}

abstract class I1 {
  m(A a);
}

abstract class I2 extends I1 {}

class Base {
  m(B a) {}
}

class T1 extends Base implements I2 {}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_INHERITANCE, 123, 2),
    ]);
  }

  test_superConstructor() async {
    await assertErrorsInCode('''
class A { A(A x) {} }
class B extends A {
  B() : super(3);
}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 56, 1),
    ]);
  }

  test_tearOffTreatedConsistentlyAsStrictArrow() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
    await assertErrorsInCode('''
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
  print(i ? false : true);
  print((obj) ? false : true);
  print((dyn) ? false : true);
}
''', [
      error(HintCode.UNUSED_FIELD, 247, 11),
      error(HintCode.UNUSED_FIELD, 273, 9),
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 1311, 1),
    ]);
  }

  test_typeCheckingLiterals() async {
    await assertErrorsInCode('''
test() {
  num n = 3;
  int i = 3;
  String s = "hello";
  {
     List<int> l = <int>[i];
     l = <int>[s];
     l = <int>[n];
     l = <int>[i, n, s];
  }
  {
     List l = [i];
     l = [s];
     l = [n];
     l = [i, n, s];
  }
  {
     Map<String, int> m = <String, int>{s: i};
     m = <String, int>{s: s};
     m = <String, int>{s: n};
     m = <String, int>{s: i, s: n, s: s};
  }
 // TODO(leafp): We can't currently test for key errors since the
 // error marker binds to the entire entry.
  {
     Map m = {s: i};
     m = {s: s};
     m = {s: n};
     m = {s: i, s: n, s: s};
     m = {i: s, n: s, s: s};
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 76, 1),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 105, 1),
      error(CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 149, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 171, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 258, 1),
      error(CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE, 309, 1),
      error(CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE, 381, 1),
      error(TodoCode.TODO, 393, 61),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 512, 1),
    ]);
  }

  test_typePromotionFromDynamic() async {
    await assertErrorsInCode(r'''
f() {
  dynamic x;
  if (x is int) {
    int y = x;
    String z = x;
  }
}
g() {
  Object x;
  if (x is int) {
    int y = x;
    String z = x;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 45, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 63, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 67, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 120, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 138, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 142, 1),
    ]);
  }

  test_typePromotionFromTypeParameter() async {
    // Regression test for:
    // https://github.com/dart-lang/sdk/issues/26965
    // https://github.com/dart-lang/sdk/issues/27040
    await assertErrorsInCode(r'''
void f<T>(T object) {
  if (object is String) print(object.substring(1));
}
void g<T extends num>(T object) {
  if (object is int) print(object.isEven);
  if (object is String) print(object.substring(1));
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
''', [
      error(CompileTimeErrorCode.UNDEFINED_METHOD, 190, 9),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 470, 1),
    ]);
  }

  test_typePromotionFromTypeParameterAndInference() async {
    // Regression test for:
    // https://github.com/dart-lang/sdk/issues/27040
    await assertErrorsInCode(r'''
void f<T extends num>(T x, T y) {
  var z = x;
  var f = () => x;
  f = () => y;
  if (x is int) {
    z.isEven;
    var q = x;
    q = z;
    f().isEven;

    // This captures the type `T extends int`.
    var g = () => x;
    g = f;
    g().isEven;
    q = g();
    int r = x;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 105, 6),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 121, 1),
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 147, 6),
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 243, 6),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 272, 1),
    ]);
  }

  test_typeSubtyping_assigningClass() async {
    await assertErrorsInCode('''
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
   i = a;
   d = a;
   n = a;
   a = a;
   b = a;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 58, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 71, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 81, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 98, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 114, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 130, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 160, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 170, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 180, 1),
    ]);
  }

  test_typeSubtyping_assigningSubclass() async {
    await assertErrorsInCode('''
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
   i = b;
   d = b;
   n = b;
   a = b;
   b = b;
   c = b;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 79, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 92, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 102, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 119, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 135, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 143, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 159, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 189, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 199, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 209, 1),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 239, 1),
    ]);
  }

  test_typeSubtyping_dynamicDowncasts() async {
    await assertErrorsInCode('''
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
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 71, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 81, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 98, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 114, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 122, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 130, 1),
    ]);
  }

  test_typeSubtyping_dynamicIsTop() async {
    await assertErrorsInCode('''
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
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 58, 1),
    ]);
  }

  test_typeSubtyping_interfaces() async {
    await assertErrorsInCode('''
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
     left = right;
     left = bot;
   }
   {
     right = top;
     right = left;
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
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 274, 5),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 339, 4),
    ]);
  }

  test_unaryOperators() async {
    await assertErrorsInCode('''
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

  !a;
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
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 201, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 237, 1),
      error(CompileTimeErrorCode.NON_BOOL_NEGATION_EXPRESSION, 280, 1),
    ]);
  }

  test_unboundRedirectingConstructor() async {
    // This is a regression test for https://github.com/dart-lang/sdk/issues/25071
    await assertErrorsInCode('''
class Foo {
  Foo() : this.init();
}
 ''', [
      error(CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR, 22,
          11),
    ]);
  }

  test_unboundTypeName() async {
    await assertErrorsInCode('''
void main() {
  AToB y;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 16, 4),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 21, 1),
    ]);
  }

  test_unboundVariable() async {
    await assertErrorsInCode('''
void main() {
   dynamic y = unboundVariable;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 25, 1),
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 29, 15),
    ]);
  }

  test_universalFunctionSubtyping() async {
    await assertErrorsInCode(r'''
dynamic foo<T>(dynamic x) => x;

void takesDtoD(dynamic f(dynamic x)) {}

void test() {
  // here we currently infer an instantiation.
  takesDtoD(foo);
}

class A {
  dynamic method(dynamic x) => x;
}

class B extends A {
  T method<T>(T x) => x;
}
''', [
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 227, 6),
    ]);
  }

  test_voidSubtyping() async {
    // Regression test for https://github.com/dart-lang/sdk/issues/25069
    await assertErrorsInCode('''
typedef int Foo();
void foo() {}
void main () {
  Foo x = foo();
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 54, 1),
      error(CompileTimeErrorCode.USE_OF_VOID_RESULT, 58, 3),
    ]);
  }

  Future<void> _assertImplicitCasts(
    String code,
    List<ExpectedError> expectedErrorsWhenImplicitCastsDisabled,
  ) async {
    newFile(testFilePath, content: code);

    await resolveTestFile();
    assertNoErrorsInResult();

    disposeAnalysisContextCollection();

    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        implicitCasts: false,
      ),
    );

    await resolveTestFile();
    assertErrorsInResult(expectedErrorsWhenImplicitCastsDisabled);
  }

  void _disableTestPackageImplicitDynamic() {
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        implicitDynamic: false,
      ),
    );
  }
}
