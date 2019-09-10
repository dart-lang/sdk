// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonErrorResolverTest);
    defineReflectiveTests(NonConstantValueInInitializer);
  });
}

@reflectiveTest
class NonConstantValueInInitializer extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0',
        additionalFeatures: [Feature.constant_update_2018]);

  test_intLiteralInDoubleContext_const_exact() async {
    await assertNoErrorsInCode(r'''
const double x = 0;
class C {
  const C(double y) : assert(y is double), assert(x is double);
}
@C(0)
@C(-0)
@C(0x0)
@C(-0x0)
void main() {
  const C(0);
  const C(-0);
  const C(0x0);
  const C(-0x0);
}
''');
  }

  test_isCheckInConstAssert() async {
    await assertNoErrorsInCode(r'''
class C {
  const C() : assert(1 is int);
}

void main() {
  const C();
}
''');
  }
}

@reflectiveTest
class NonErrorResolverTest extends DriverResolutionTest {
  test_ambiguousExport() async {
    newFile("/test/lib/lib1.dart", content: r'''
library lib1;
class M {}
''');
    newFile("/test/lib/lib2.dart", content: r'''
library lib2;
class N {}
''');
    await assertNoErrorsInCode(r'''
library L;
export 'lib1.dart';
export 'lib2.dart';
''');
  }

  test_ambiguousExport_combinators_hide() async {
    newFile("/test/lib/lib1.dart", content: r'''
library L1;
class A {}
class B {}
''');
    newFile("/test/lib/lib2.dart", content: r'''
library L2;
class B {}
class C {}
''');
    await assertNoErrorsInCode(r'''
library L;
export 'lib1.dart';
export 'lib2.dart' hide B;
''');
  }

  test_ambiguousExport_combinators_show() async {
    newFile("/test/lib/lib1.dart", content: r'''
library L1;
class A {}
class B {}
''');
    newFile("/test/lib/lib2.dart", content: r'''
library L2;
class B {}
class C {}
''');
    await assertNoErrorsInCode(r'''
library L;
export 'lib1.dart';
export 'lib2.dart' show C;
''');
  }

  test_ambiguousExport_sameDeclaration() async {
    newFile("/test/lib/lib.dart", content: r'''
library lib;
class N {}
''');
    await assertNoErrorsInCode(r'''
library L;
export 'lib.dart';
export 'lib.dart';
''');
  }

  test_ambiguousImport_dart_implicitHide() async {
    newFile('/test/lib/lib.dart', content: r'''
class Future {
  static const zero = 0;
}
''');
    await assertNoErrorsInCode(r'''
import 'dart:async';
import 'lib.dart';
main() {
  print(Future.zero);
}
''');
  }

  test_ambiguousImport_hideCombinator() async {
    newFile("/test/lib/lib1.dart", content: r'''
library lib1;
class N {}
class N1 {}
''');
    newFile("/test/lib/lib2.dart", content: r'''
library lib2;
class N {}
class N2 {}
''');
    newFile("/test/lib/lib3.dart", content: r'''
library lib3;
class N {}
class N3 {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart';
import 'lib2.dart';
import 'lib3.dart' hide N;
main() {
  new N1();
  new N2();
  new N3();
}
''');
  }

  test_ambiguousImport_showCombinator() async {
    newFile("/test/lib/lib1.dart", content: r'''
library lib1;
class N {}
class N1 {}
''');
    newFile("/test/lib/lib2.dart", content: r'''
library lib2;
class N {}
class N2 {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart';
import 'lib2.dart' show N, N2;
main() {
  new N1();
  new N2();
}
''', [
      error(HintCode.UNUSED_SHOWN_NAME, 44, 1),
    ]);
  }

  test_annotated_partOfDeclaration() async {
    newFile('/test/lib/part.dart', content: '''
@deprecated part of L;
''');
    await assertNoErrorsInCode('''
library L; part "part.dart";
''');
  }

  test_argumentTypeNotAssignable_classWithCall_Function() async {
    await assertNoErrorsInCode(r'''
caller(Function callee) {
  callee();
}

class CallMeBack {
  call() => 0;
}

main() {
  caller(new CallMeBack());
}
''');
  }

  test_argumentTypeNotAssignable_fieldFormalParameterElement_member() async {
    await assertNoErrorsInCode(r'''
class ObjectSink<T> {
  void sink(T object) {
    new TimestampedObject<T>(object);
  }
}
class TimestampedObject<E> {
  E object2;
  TimestampedObject(this.object2);
}
''');
  }

  test_argumentTypeNotAssignable_invocation_functionParameter_generic() async {
    await assertNoErrorsInCode(r'''
class A<K> {
  m(f(K k), K v) {
    f(v);
  }
}
''');
  }

  test_argumentTypeNotAssignable_invocation_typedef_generic() async {
    await assertNoErrorsInCode(r'''
typedef A<T>(T p);
f(A<int> a) {
  a(1);
}
''');
  }

  test_argumentTypeNotAssignable_Object_Function() async {
    await assertNoErrorsInCode(r'''
main() {
  process(() {});
}
process(Object x) {}''');
  }

  test_argumentTypeNotAssignable_optionalNew() async {
    await assertNoErrorsInCode(r'''
class Widget { }

class MaterialPageRoute {
  final Widget Function() builder;
  const MaterialPageRoute({this.builder});
}

void main() {
  print(MaterialPageRoute(
      builder: () { return Widget(); }
  ));
}
''');
  }

  test_argumentTypeNotAssignable_typedef_local() async {
    await assertNoErrorsInCode(r'''
typedef A(int p1, String p2);
A getA() => null;
f() {
  A a = getA();
  a(1, '2');
}
''');
  }

  test_argumentTypeNotAssignable_typedef_parameter() async {
    await assertNoErrorsInCode(r'''
typedef A(int p1, String p2);
f(A a) {
  a(1, '2');
}
''');
  }

  test_assert_with_message_await() async {
    await assertNoErrorsInCode('''
import 'dart:async';
f() async {
  assert(false, await g());
}
Future<String> g() => null;
''');
  }

  test_assert_with_message_dynamic() async {
    await assertNoErrorsInCode('''
f() {
  assert(false, g());
}
g() => null;
''');
  }

  test_assert_with_message_non_string() async {
    await assertNoErrorsInCode('''
f() {
  assert(false, 3);
}
''');
  }

  test_assert_with_message_null() async {
    await assertNoErrorsInCode('''
f() {
  assert(false, null);
}
''');
  }

  test_assert_with_message_string() async {
    await assertNoErrorsInCode('''
f() {
  assert(false, 'message');
}
''');
  }

  test_assert_with_message_suppresses_unused_var_hint() async {
    await assertNoErrorsInCode('''
f() {
  String message = 'msg';
  assert(true, message);
}
''');
  }

  test_assignability_function_expr_rettype_from_typedef_cls() async {
    // In the code below, the type of (() => f()) has a return type which is
    // a class, and that class is inferred from the return type of the typedef
    // F.
    await assertNoErrorsInCode('''
class C {}
typedef C F();
F f;
main() {
  F f2 = (() => f());
}
''');
  }

  test_assignability_function_expr_rettype_from_typedef_typedef() async {
    // In the code below, the type of (() => f()) has a return type which is
    // a typedef, and that typedef is inferred from the return type of the
    // typedef F.
    await assertNoErrorsInCode('''
typedef G F();
typedef G();
F f;
main() {
  F f2 = (() => f());
}
''');
  }

  test_assignmentToFinal_prefixNegate() async {
    await assertNoErrorsInCode(r'''
f() {
  final x = 0;
  -x;
}
''');
  }

  test_assignmentToFinalNoSetter_prefixedIdentifier() async {
    await assertNoErrorsInCode(r'''
class A {
  int get x => 0;
  set x(v) {}
}
main() {
  A a = new A();
  a.x = 0;
}
''');
  }

  test_assignmentToFinalNoSetter_propertyAccess() async {
    await assertNoErrorsInCode(r'''
class A {
  int get x => 0;
  set x(v) {}
}
class B {
  static A a;
}
main() {
  B.a.x = 0;
}
''');
  }

  test_assignmentToFinals_importWithPrefix() async {
    newFile("/test/lib/lib1.dart", content: r'''
library lib1;
bool x = false;''');
    await assertNoErrorsInCode(r'''
library lib;
import 'lib1.dart' as foo;
main() {
  foo.x = true;
}
''');
  }

  test_async_dynamic_with_return() async {
    await assertNoErrorsInCode('''
dynamic f() async {
  return;
}
''');
  }

  test_async_dynamic_with_return_value() async {
    await assertNoErrorsInCode('''
dynamic f() async {
  return 5;
}
''');
  }

  test_async_dynamic_without_return() async {
    await assertNoErrorsInCode('''
dynamic f() async {}
''');
  }

  test_async_expression_function_type() async {
    await assertNoErrorsInCode('''
import 'dart:async';
typedef Future<int> F(int i);
main() {
  F f = (int i) async => i;
}
''');
  }

  test_async_flattened() async {
    await assertNoErrorsInCode('''
import 'dart:async';
typedef Future<int> CreatesFutureInt();
main() {
  CreatesFutureInt createFutureInt = () async => f();
  Future<int> futureInt = createFutureInt();
  futureInt.then((int i) => print(i));
}
Future<int> f() => null;
''');
  }

  test_async_future_dynamic_with_return() async {
    await assertNoErrorsInCode('''
import 'dart:async';
Future<dynamic> f() async {
  return;
}
''');
  }

  test_async_future_dynamic_with_return_value() async {
    await assertNoErrorsInCode('''
import 'dart:async';
Future<dynamic> f() async {
  return 5;
}
''');
  }

  test_async_future_dynamic_without_return() async {
    await assertNoErrorsInCode('''
import 'dart:async';
Future<dynamic> f() async {}
''');
  }

  test_async_future_int_with_return_future_int() async {
    await assertNoErrorsInCode('''
import 'dart:async';
Future<int> f() async {
  return new Future<int>.value(5);
}
''');
  }

  test_async_future_int_with_return_value() async {
    await assertNoErrorsInCode('''
import 'dart:async';
Future<int> f() async {
  return 5;
}
''');
  }

  test_async_future_null_with_return() async {
    await assertNoErrorsInCode('''
import 'dart:async';
Future<Null> f() async {
  return;
}
''');
  }

  test_async_future_null_without_return() async {
    await assertNoErrorsInCode('''
import 'dart:async';
Future<Null> f() async {}
''');
  }

  test_async_future_object_with_return_value() async {
    await assertNoErrorsInCode('''
import 'dart:async';
Future<Object> f() async {
  return 5;
}
''');
  }

  test_async_future_with_return() async {
    await assertNoErrorsInCode('''
import 'dart:async';
Future f() async {
  return;
}
''');
  }

  test_async_future_with_return_value() async {
    await assertNoErrorsInCode('''
import 'dart:async';
Future f() async {
  return 5;
}
''');
  }

  test_async_future_without_return() async {
    await assertNoErrorsInCode('''
import 'dart:async';
Future f() async {}
''');
  }

  test_async_with_return() async {
    await assertNoErrorsInCode('''
f() async {
  return;
}
''');
  }

  test_async_with_return_value() async {
    await assertNoErrorsInCode('''
f() async {
  return 5;
}
''');
  }

  test_async_without_return() async {
    await assertNoErrorsInCode('''
f() async {}
''');
  }

  test_asyncForInWrongContext_async() async {
    await assertNoErrorsInCode(r'''
f(list) async {
  await for (var e in list) {
  }
}
''');
  }

  test_asyncForInWrongContext_asyncStar() async {
    await assertNoErrorsInCode(r'''
f(list) async* {
  await for (var e in list) {
  }
}
''');
  }

  test_await_flattened() async {
    await assertNoErrorsInCode('''
import 'dart:async';
Future<Future<int>> ffi() => null;
f() async {
  Future<int> b = await ffi();
}
''');
  }

  test_await_simple() async {
    await assertNoErrorsInCode('''
import 'dart:async';
Future<int> fi() => null;
f() async {
  int a = await fi();
}
''');
  }

  test_awaitInWrongContext_async() async {
    await assertNoErrorsInCode(r'''
f(x, y) async {
  return await x + await y;
}
''');
  }

  test_awaitInWrongContext_asyncStar() async {
    await assertNoErrorsInCode(r'''
f(x, y) async* {
  yield await x + await y;
}
''');
  }

  test_breakWithoutLabelInSwitch() async {
    await assertNoErrorsInCode(r'''
class A {
  void m(int i) {
    switch (i) {
      case 0:
        break;
    }
  }
}
''');
  }

  test_bug_24539_getter() async {
    await assertNoErrorsInCode('''
class C<T> {
  List<Foo> get x => null;
}

typedef Foo(param);
''');
  }

  test_bug_24539_setter() async {
    await assertNoErrorsInCode('''
class C<T> {
  void set x(List<Foo> value) {}
}

typedef Foo(param);
''');
  }

  test_builtInIdentifierAsType_dynamic() async {
    await assertNoErrorsInCode(r'''
f() {
  dynamic x;
}
''');
  }

  test_caseBlockNotTerminated() async {
    await assertNoErrorsInCode(r'''
f(int p) {
  for (int i = 0; i < 10; i++) {
    switch (p) {
      case 0:
        break;
      case 1:
        continue;
      case 2:
        return;
      case 3:
        throw new Object();
      case 4:
      case 5:
        return;
      case 6:
      default:
        return;
    }
  }
}
''');
  }

  test_caseBlockNotTerminated_lastCase() async {
    await assertNoErrorsInCode(r'''
f(int p) {
  switch (p) {
    case 0:
      p = p + 1;
  }
}
''');
  }

  test_caseExpressionTypeImplementsEquals() async {
    await assertNoErrorsInCode(r'''
print(p) {}

abstract class B {
  final id;
  const B(this.id);
  String toString() => 'C($id)';
  /** Equality is identity equality, the id isn't used. */
  bool operator==(Object other);
  }

class C extends B {
  const C(id) : super(id);
}

void doSwitch(c) {
  switch (c) {
  case const C(0): print('Switch: 0'); break;
  case const C(1): print('Switch: 1'); break;
  }
}
''');
  }

  test_caseExpressionTypeImplementsEquals_int() async {
    await assertNoErrorsInCode(r'''
f(int i) {
  switch(i) {
    case(1) : return 1;
    default: return 0;
  }
}
''');
  }

  test_caseExpressionTypeImplementsEquals_Object() async {
    await assertNoErrorsInCode(r'''
class IntWrapper {
  final int value;
  const IntWrapper(this.value);
}

f(IntWrapper intWrapper) {
  switch(intWrapper) {
    case(const IntWrapper(1)) : return 1;
    default: return 0;
  }
}
''');
  }

  test_caseExpressionTypeImplementsEquals_String() async {
    await assertNoErrorsInCode(r'''
f(String s) {
  switch(s) {
    case('1') : return 1;
    default: return 0;
  }
}
''');
  }

  test_class_type_alias_documentationComment() async {
    await assertNoErrorsInCode('''
/**
 * Documentation
 */
class C = D with E;

class D {}
class E {}
''');
    CompilationUnit unit = result.unit;
    ClassElement classC = unit.declaredElement.getType('C');
    expect(classC.documentationComment, isNotNull);
  }

  test_closure_in_type_inferred_variable_in_other_lib() async {
    newFile('/test/lib/other.dart', content: '''
var y = (Object x) => x is int && x.isEven;
''');
    await assertNoErrorsInCode('''
import 'other.dart';
var x = y;
''');
  }

  test_concreteClassWithAbstractMember() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  m();
}
''');
  }

  test_concreteClassWithAbstractMember_inherited() async {
    await assertNoErrorsInCode(r'''
class A {
  m() {}
}
class B extends A {
  m();
}
''');
  }

  test_conflictingConstructorNameAndMember_setter() async {
    await assertNoErrorsInCode(r'''
class A {
A.x() {}
set x(_) {}
}
''');
  }

  test_conflictingStaticGetterAndInstanceSetter_thisClass() async {
    await assertNoErrorsInCode(r'''
class A {
  static get x => 0;
  static set x(int p) {}
}
''');
  }

  test_const_constructor_with_named_generic_parameter() async {
    await assertNoErrorsInCode('''
class C<T> {
  const C({T t});
}
const c = const C(t: 1);
''');
  }

  test_const_dynamic() async {
    await assertNoErrorsInCode('''
const Type d = dynamic;
''');
  }

  test_const_imported_defaultParameterValue_withImportPrefix() async {
    newFile('/test/lib/b.dart', content: r'''
import 'c.dart' as ccc;
class B {
  const B([p = ccc.value]);
}
''');
    newFile('/test/lib/c.dart', content: r'''
const int value = 12345;
''');
    await assertNoErrorsInCode(r'''
import 'b.dart';
const b = const B();
''');
  }

  test_constConstructorWithNonConstSuper_explicit() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
}
class B extends A {
  const B(): super();
}
''');
  }

  test_constConstructorWithNonConstSuper_redirectingFactory() async {
    await assertNoErrorsInCode(r'''
class A {
  A();
}
class B implements C {
  const B();
}
class C extends A {
  const factory C() = B;
}
''');
  }

  test_constConstructorWithNonConstSuper_unresolved() async {
    await assertErrorsInCode(r'''
class A {
  A.a();
}
class B extends A {
  const B(): super();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT,
          54, 7),
    ]);
  }

  test_constConstructorWithNonFinalField_finalInstanceVar() async {
    await assertNoErrorsInCode(r'''
class A {
  final int x = 0;
  const A();
}
''');
  }

  test_constConstructorWithNonFinalField_static() async {
    await assertNoErrorsInCode(r'''
class A {
  static int x;
  const A();
}
''');
  }

  test_constConstructorWithNonFinalField_syntheticField() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
  set x(value) {}
  get x {return 0;}
}
''');
  }

  test_constDeferredClass_new() async {
    newFile('/test/lib/lib.dart', content: r'''
class A {
  const A.b();
}
''');
    await assertNoErrorsInCode(r'''
import 'lib.dart' deferred as a;
main() {
  new a.A.b();
}
''');
  }

  test_constEval_functionTypeLiteral() async {
    await assertNoErrorsInCode(r'''
typedef F();
const C = F;
''');
  }

  test_constEval_propertyExtraction_fieldStatic_targetType() async {
    newFile("/test/lib/math.dart", content: r'''
library math;
const PI = 3.14;
''');
    await assertNoErrorsInCode(r'''
import 'math.dart' as math;
const C = math.PI;
''');
  }

  test_constEval_propertyExtraction_methodStatic_targetType() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
  static m() {}
}
const C = A.m;
''');
  }

  test_constEval_symbol() async {
    newFile("/test/lib/math.dart", content: r'''
library math;
const PI = 3.14;
''');
    await assertNoErrorsInCode(r'''
const C = #foo;
foo() {}
''');
  }

  test_constEvalTypeBoolNumString_equal() async {
    await assertNoErrorsInCode(r'''
class B {
  final v;
  const B.a1(bool p) : v = p == true;
  const B.a2(bool p) : v = p == false;
  const B.a3(bool p) : v = p == 0;
  const B.a4(bool p) : v = p == 0.0;
  const B.a5(bool p) : v = p == '';
  const B.b1(int p) : v = p == true;
  const B.b2(int p) : v = p == false;
  const B.b3(int p) : v = p == 0;
  const B.b4(int p) : v = p == 0.0;
  const B.b5(int p) : v = p == '';
  const B.c1(String p) : v = p == true;
  const B.c2(String p) : v = p == false;
  const B.c3(String p) : v = p == 0;
  const B.c4(String p) : v = p == 0.0;
  const B.c5(String p) : v = p == '';
  const B.n1(num p) : v = p == null;
  const B.n2(num p) : v = null == p;
  const B.n3(Object p) : v = p == null;
  const B.n4(Object p) : v = null == p;
}
''');
  }

  test_constEvalTypeBoolNumString_notEqual() async {
    await assertNoErrorsInCode(r'''
class B {
  final v;
  const B.a1(bool p) : v = p != true;
  const B.a2(bool p) : v = p != false;
  const B.a3(bool p) : v = p != 0;
  const B.a4(bool p) : v = p != 0.0;
  const B.a5(bool p) : v = p != '';
  const B.b1(int p) : v = p != true;
  const B.b2(int p) : v = p != false;
  const B.b3(int p) : v = p != 0;
  const B.b4(int p) : v = p != 0.0;
  const B.b5(int p) : v = p != '';
  const B.c1(String p) : v = p != true;
  const B.c2(String p) : v = p != false;
  const B.c3(String p) : v = p != 0;
  const B.c4(String p) : v = p != 0.0;
  const B.c5(String p) : v = p != '';
  const B.n1(num p) : v = p != null;
  const B.n2(num p) : v = null != p;
  const B.n3(Object p) : v = p != null;
  const B.n4(Object p) : v = null != p;
}
''');
  }

  test_constEvAlTypeNum_String() async {
    await assertNoErrorsInCode(r'''
const String A = 'a';
const String B = A + 'b';
''');
  }

  test_constNotInitialized_field() async {
    await assertNoErrorsInCode(r'''
class A {
  static const int x = 0;
}
''');
  }

  test_constNotInitialized_local() async {
    await assertNoErrorsInCode(r'''
main() {
  const int x = 0;
}
''');
  }

  test_constRedirectSkipsSupertype() async {
    // Since C redirects to C.named, it doesn't implicitly refer to B's
    // unnamed constructor.  Therefore there is no cycle.
    await assertNoErrorsInCode('''
class B {
  final x;
  const B() : x = y;
  const B.named() : x = null;
}
class C extends B {
  const C() : this.named();
  const C.named() : super.named();
}
const y = const C();
''');
  }

  test_constructorDeclaration_scope_signature() async {
    await assertNoErrorsInCode(r'''
const app = 0;
class A {
  A(@app int app) {}
}
''');
  }

  test_constWithNonConstantArgument_constField() async {
    await assertNoErrorsInCode(r'''
class A {
  const A(x);
}
main() {
  const A(double.INFINITY);
}
''');
  }

  test_constWithNonConstantArgument_literals() async {
    await assertNoErrorsInCode(r'''
class A {
  const A(a, b, c, d);
}
f() { return const A(true, 0, 1.0, '2'); }
''');
  }

  test_constWithTypeParameters_direct() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  static const V = const A<int>();
  const A();
}
''');
  }

  test_constWithUndefinedConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  const A.name();
}
f() {
  return const A.name();
}
''');
  }

  test_constWithUndefinedConstructorDefault() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
}
f() {
  return const A();
}
''');
  }

  test_defaultValueInFunctionTypeAlias() async {
    await assertNoErrorsInCode('''
typedef F([x]);
''');
  }

  test_defaultValueInFunctionTypedParameter_named() async {
    await assertNoErrorsInCode('''
f(g({p})) {}
''');
  }

  test_defaultValueInFunctionTypedParameter_optional() async {
    await assertNoErrorsInCode("f(g([p])) {}");
  }

  test_deprecatedMemberUse_hide() async {
    newFile("/test/lib/lib1.dart", content: r'''
library lib1;
class A {}
@deprecated
class B {}
''');
    await assertNoErrorsInCode(r'''
library lib;
import 'lib1.dart' hide B;
A a = new A();
''');
  }

  test_duplicateDefinition_emptyName() async {
    // Note: This code has two FunctionElements '() {}' with an empty name,
    // this tests that the empty string is not put into the scope
    // (more than once).
    await assertNoErrorsInCode(r'''
Map _globalMap = {
  'a' : () {},
  'b' : () {}
};
''');
  }

  test_duplicateDefinition_getter() async {
    await assertNoErrorsInCode('''
bool get a => true;
''');
  }

  test_duplicatePart() async {
    newFile('/test/lib/part1.dart', content: '''
part of lib;
''');
    newFile('/test/lib/part2.dart', content: '''
part of lib;
''');
    await assertNoErrorsInCode(r'''
library lib;
part 'part1.dart';
part 'part2.dart';
''');
  }

  test_dynamicIdentifier() async {
    await assertNoErrorsInCode(r'''
main() {
  var v = dynamic;
}
''');
  }

  test_empty_generator_async() async {
    await assertNoErrorsInCode('''
import 'dart:async';
Stream<int> f() async* {
}
''');
  }

  test_empty_generator_sync() async {
    await assertNoErrorsInCode('''
Iterable<int> f() sync* {
}
''');
  }

  test_expectedOneListTypeArgument() async {
    await assertNoErrorsInCode(r'''
main() {
  <int> [];
}
''');
  }

  test_expectedTwoMapTypeArguments() async {
    await assertNoErrorsInCode(r'''
main() {
  <int, int> {};
}
''');
  }

  test_exportDuplicatedLibraryUnnamed() async {
    newFile("/test/lib/lib1.dart");
    newFile("/test/lib/lib2.dart");
    await assertNoErrorsInCode(r'''
library test;
export 'lib1.dart';
export 'lib2.dart';
''');
  }

  test_exportOfNonLibrary_libraryDeclared() async {
    newFile("/test/lib/lib1.dart", content: "library lib1;");
    await assertNoErrorsInCode(r'''
library L;
export 'lib1.dart';
''');
  }

  test_exportOfNonLibrary_libraryNotDeclared() async {
    newFile("/test/lib/lib1.dart");
    await assertNoErrorsInCode(r'''
library L;
export 'lib1.dart';
''');
  }

  test_extraPositionalArguments_function() async {
    await assertNoErrorsInCode(r'''
f(p1, p2) {}
main() {
  f(1, 2);
}
''');
  }

  test_extraPositionalArguments_Function() async {
    await assertNoErrorsInCode(r'''
f(Function a) {
  a(1, 2);
}
''');
  }

  test_extraPositionalArguments_typedef_local() async {
    await assertNoErrorsInCode(r'''
typedef A(p1, p2);
A getA() => null;
f() {
  A a = getA();
  a(1, 2);
}
''');
  }

  test_extraPositionalArguments_typedef_parameter() async {
    await assertNoErrorsInCode(r'''
typedef A(p1, p2);
f(A a) {
  a(1, 2);
}
''');
  }

  test_fieldFormalParameter_functionTyped_named() async {
    await assertNoErrorsInCode(r'''
class C {
  final Function field;

  C({String this.field(int value)});
}
''');
  }

  test_fieldFormalParameter_genericFunctionTyped() async {
    await assertNoErrorsInCode(r'''
class C {
  final Object Function(int, double) field;

  C(String Function(num, Object) this.field);
}
''');
  }

  test_fieldFormalParameter_genericFunctionTyped_named() async {
    await assertNoErrorsInCode(r'''
class C {
  final Object Function(int, double) field;

  C({String Function(num, Object) this.field});
}
''');
  }

  test_fieldInitializedByMultipleInitializers() async {
    await assertNoErrorsInCode(r'''
class A {
  int x;
  int y;
  A() : x = 0, y = 0 {}
}
''');
  }

  test_fieldInitializedInInitializerAndDeclaration_fieldNotFinal() async {
    await assertNoErrorsInCode(r'''
class A {
  int x = 0;
  A() : x = 1 {}
}
''');
  }

  test_fieldInitializedInInitializerAndDeclaration_finalFieldNotSet() async {
    await assertNoErrorsInCode(r'''
class A {
  final int x;
  A() : x = 1 {}
}
''');
  }

  test_fieldInitializerOutsideConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  int x;
  A(this.x) {}
}
''');
  }

  test_fieldInitializerOutsideConstructor_defaultParameters() async {
    await assertNoErrorsInCode(r'''
class A {
  int x;
  A([this.x]) {}
}
''');
  }

  test_fieldInitializerRedirectingConstructor_super() async {
    await assertNoErrorsInCode(r'''
class A {
  A() {}
}
class B extends A {
  int x;
  B(this.x) : super();
}
''');
  }

  test_finalInitializedInDeclarationAndConstructor_initializer() async {
    await assertNoErrorsInCode(r'''
class A {
  final x;
  A() : x = 1 {}
}
''');
  }

  test_finalInitializedInDeclarationAndConstructor_initializingFormal() async {
    await assertNoErrorsInCode(r'''
class A {
  final x;
  A(this.x) {}
}
''');
  }

  test_finalNotInitialized_atDeclaration() async {
    await assertNoErrorsInCode(r'''
class A {
  final int x = 0;
  A() {}
}
''');
  }

  test_finalNotInitialized_fieldFormal() async {
    await assertNoErrorsInCode(r'''
class A {
  final int x = 0;
  A() {}
}
''');
  }

  test_finalNotInitialized_functionTypedFieldFormal() async {
    await assertNoErrorsInCode(r'''
class A {
  final Function x;
  A(int this.x(int p)) {}
}
''');
  }

  test_finalNotInitialized_hasNativeClause_hasConstructor() async {
    await assertErrorsInCode(r'''
class A native 'something' {
  final int x;
  A() {}
}
''', [
      error(ParserErrorCode.NATIVE_CLAUSE_IN_NON_SDK_CODE, 8, 18),
    ]);
  }

  test_finalNotInitialized_hasNativeClause_noConstructor() async {
    await assertErrorsInCode(r'''
class A native 'something' {
  final int x;
}
''', [
      error(ParserErrorCode.NATIVE_CLAUSE_IN_NON_SDK_CODE, 8, 18),
    ]);
  }

  test_finalNotInitialized_initializer() async {
    await assertNoErrorsInCode(r'''
class A {
  final int x;
  A() : x = 0 {}
}
''');
  }

  test_finalNotInitialized_redirectingConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  final int x;
  A(this.x);
  A.named() : this (42);
}
''');
  }

  test_for_in_scope() async {
    await assertNoErrorsInCode('''
main() {
  List<List<int>> x = [[1]];
  for (int x in x.first) {
    print(x.isEven);
  }
}
''');
  }

  test_forEach_genericFunctionType() async {
    await assertNoErrorsInCode(r'''
main() {
  for (Null Function<T>(T, Null) e in <dynamic>[]) {
    e;
  }
}
''');
  }

  test_functionDeclaration_scope_returnType() async {
    await assertNoErrorsInCode('''
int f(int) { return 0; }
''');
  }

  test_functionDeclaration_scope_signature() async {
    await assertNoErrorsInCode(r'''
const app = 0;
f(@app int app) {}
''');
  }

  test_functionTypeAlias_scope_returnType() async {
    await assertNoErrorsInCode('''
typedef int f(int);
''');
  }

  test_functionTypeAlias_scope_signature() async {
    await assertNoErrorsInCode(r'''
const app = 0;
typedef int f(@app int app);
''');
  }

  test_functionWithoutCall() async {
    await assertNoErrorsInCode(r'''
abstract class A implements Function {
}
class B implements A {
  void call() {}
}
class C extends A {
  void call() {}
}
class D extends C {
}
''');
  }

  test_functionWithoutCall_doesNotImplementFunction() async {
    await assertNoErrorsInCode("class A {}");
  }

  test_functionWithoutCall_staticCallMethod() async {
    await assertNoErrorsInCode(r'''
class A { }
class B extends A {
  static call() { }
}
''');
  }

  test_functionWithoutCall_withNoSuchMethod() async {
    // 16078
    await assertNoErrorsInCode(r'''
class A implements Function {
  noSuchMethod(inv) {
    return 42;
  }
}
''');
  }

  test_functionWithoutCall_withNoSuchMethod_mixin() async {
    await assertNoErrorsInCode(r'''
class A {
  noSuchMethod(inv) {}
}
class B extends Object with A implements Function {
}
''');
  }

  test_functionWithoutCall_withNoSuchMethod_superclass() async {
    await assertNoErrorsInCode(r'''
class A {
  noSuchMethod(inv) {}
}
class B extends A implements Function {
}
''');
  }

  test_genericTypeAlias_castsAndTypeChecks_hasTypeParameters() async {
    await assertNoErrorsInCode('''
typedef Foo<S> = S Function<T>(T x);

main(Object p) {
  (p as Foo)<int>(3);
  if (p is Foo) {
    p<int>(3);
  }
  (p as Foo<String>)<int>(3);
  if (p is Foo<String>) {
    p<int>(3);
  }
}
''');
  }

  test_genericTypeAlias_castsAndTypeChecks_noTypeParameters() async {
    await assertNoErrorsInCode('''
typedef Foo = T Function<T>(T x);

main(Object p) {
  (p as Foo)<int>(3);
  if (p is Foo) {
    p<int>(3);
  }
}
''');
  }

  test_genericTypeAlias_fieldAndReturnType_noTypeParameters() async {
    await assertNoErrorsInCode(r'''
typedef Foo = int Function<T>(T x);
int foo<T>(T x) => 3;
Foo bar() => foo;
void test1() {
  bar()<String>("hello");
}

class A {
  Foo f;
  void test() {
    f<String>("hello");
  }
}
''');
  }

  test_genericTypeAlias_fieldAndReturnType_typeParameters_arguments() async {
    await assertNoErrorsInCode(r'''
typedef Foo<S> = S Function<T>(T x);
int foo<T>(T x) => 3;
Foo<int> bar() => foo;
void test1() {
  bar()<String>("hello");
}

class A {
  Foo<int> f;
  void test() {
    f<String>("hello");
  }
}
''');
  }

  test_genericTypeAlias_fieldAndReturnType_typeParameters_noArguments() async {
    await assertNoErrorsInCode(r'''
typedef Foo<S> = S Function<T>(T x);
int foo<T>(T x) => 3;
Foo bar() => foo;
void test1() {
  bar()<String>("hello");
}

class A {
  Foo f;
  void test() {
    f<String>("hello");
  }
}
''');
  }

  test_genericTypeAlias_invalidGenericFunctionType() async {
    // There is a parse error, but no crashes.
    await assertErrorsInCode('''
typedef F = int;
main(p) {
  p is F;
}
''', [
      error(ParserErrorCode.INVALID_GENERIC_FUNCTION_TYPE, 10, 1),
    ]);
  }

  test_genericTypeAlias_noTypeParameters() async {
    await assertNoErrorsInCode(r'''
typedef Foo = int Function<T>(T x);
int foo<T>(T x) => 3;
void test1() {
  Foo y = foo;
  // These two should be equivalent
  foo<String>("hello");
  y<String>("hello");
}
''');
  }

  test_genericTypeAlias_typeParameters() async {
    await assertNoErrorsInCode(r'''
typedef Foo<S> = S Function<T>(T x);
int foo<T>(T x) => 3;
void test1() {
  Foo<int> y = foo;
  // These two should be equivalent
  foo<String>("hello");
  y<String>("hello");
}
''');
  }

  test_importDuplicatedLibraryName() async {
    newFile("/test/lib/lib.dart", content: "library lib;");
    await assertErrorsInCode(r'''
library test;
import 'lib.dart';
import 'lib.dart';
''', [
      error(HintCode.UNUSED_IMPORT, 21, 10),
      error(HintCode.UNUSED_IMPORT, 40, 10),
      error(HintCode.DUPLICATE_IMPORT, 40, 10),
    ]);
  }

  test_importDuplicatedLibraryUnnamed() async {
    newFile("/test/lib/lib1.dart");
    newFile("/test/lib/lib2.dart");
    // No warning on duplicate import (https://github.com/dart-lang/sdk/issues/24156)
    await assertErrorsInCode(r'''
library test;
import 'lib1.dart';
import 'lib2.dart';
''', [
      error(HintCode.UNUSED_IMPORT, 21, 11),
      error(HintCode.UNUSED_IMPORT, 41, 11),
    ]);
  }

  test_importOfNonLibrary_libraryDeclared() async {
    newFile("/test/lib/part.dart", content: r'''
library lib1;
class A {}
''');
    await assertNoErrorsInCode(r'''
library lib;
import 'part.dart';
A a;
''');
  }

  test_importOfNonLibrary_libraryNotDeclared() async {
    newFile("/test/lib/part.dart", content: '''
class A {}
''');
    await assertNoErrorsInCode(r'''
library lib;
import 'part.dart';
A a;
''');
  }

  test_importPrefixes_withFirstLetterDifference() async {
    newFile("/test/lib/lib1.dart", content: r'''
library lib1;
test1() {}
''');
    newFile("/test/lib/lib2.dart", content: r'''
library lib2;
test2() {}
''');
    await assertNoErrorsInCode(r'''
library L;
import 'lib1.dart' as math;
import 'lib2.dart' as path;
main() {
  math.test1();
  path.test2();
}
''');
  }

  test_inconsistentCaseExpressionTypes() async {
    await assertNoErrorsInCode(r'''
f(var p) {
  switch (p) {
    case 1:
      break;
    case 2:
      break;
  }
}
''');
  }

  test_inconsistentMethodInheritance_accessors_typeParameter2() async {
    await assertNoErrorsInCode(r'''
abstract class A<E> {
  E get x {return null;}
}
class B<E> {
  E get x {return null;}
}
class C<E> extends A<E> implements B<E> {}
''');
  }

  test_inconsistentMethodInheritance_accessors_typeParameters1() async {
    await assertNoErrorsInCode(r'''
abstract class A<E> {
  E get x;
}
abstract class B<E> {
  E get x;
}
class C<E> implements A<E>, B<E> {
  E get x => null;
}
''');
  }

  test_inconsistentMethodInheritance_accessors_typeParameters_diamond() async {
    await assertNoErrorsInCode(r'''
abstract class F<E> extends B<E> {}
class D<E> extends F<E> {
  external E get g;
}
abstract class C<E> {
  E get g;
}
abstract class B<E> implements C<E> {
  E get g { return null; }
}
class A<E> extends B<E> implements D<E> {
}
''');
  }

  test_inconsistentMethodInheritance_methods_typeParameter2() async {
    await assertNoErrorsInCode(r'''
class A<E> {
  x(E e) {}
}
class B<E> {
  x(E e) {}
}
class C<E> extends A<E> implements B<E> {
  x(E e) {}
}
''');
  }

  test_inconsistentMethodInheritance_methods_typeParameters1() async {
    await assertNoErrorsInCode(r'''
class A<E> {
  x(E e) {}
}
class B<E> {
  x(E e) {}
}
class C<E> implements A<E>, B<E> {
  x(E e) {}
}
''');
  }

  test_inconsistentMethodInheritance_simple() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  x();
}
abstract class B {
  x();
}
class C implements A, B {
  x() {}
}
''');
  }

  test_infer_mixin_new_syntax() async {
    await assertNoErrorsInCode('''
abstract class A<T> {}

class B {}

mixin M<T> on A<T> {}

class C extends A<B> with M {}
''');
    CompilationUnit unit = result.unit;
    ClassElement classC = unit.declaredElement.getType('C');
    expect(classC.mixins, hasLength(1));
    expect(classC.mixins[0].toString(), 'M<B>');
  }

  test_infer_mixin_with_substitution_functionType_new_syntax() async {
    await assertErrorsInCode('''
abstract class A<T> {}

class B {}

mixin M<T, U> on A<T Function(U)> {}

class C extends A<int Function(String)> with M {}
''', [
      error(
        CompileTimeErrorCode.WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE,
        47,
        1,
      ),
    ]);
    CompilationUnit unit = result.unit;
    ClassElement classC = unit.declaredElement.getType('C');
    expect(classC.mixins, hasLength(1));
    expect(classC.mixins[0].toString(), 'M<int, String>');
  }

  test_infer_mixin_with_substitution_new_syntax() async {
    await assertNoErrorsInCode('''
abstract class A<T> {}

class B {}

mixin M<T> on A<List<T>> {}

class C extends A<List<B>> with M {}
''');
    CompilationUnit unit = result.unit;
    ClassElement classC = unit.declaredElement.getType('C');
    expect(classC.mixins, hasLength(1));
    expect(classC.mixins[0].toString(), 'M<B>');
  }

  test_initializingFormalForNonExistentField() async {
    await assertNoErrorsInCode(r'''
class A {
  int x;
  A(this.x) {}
}
''');
  }

  test_instance_creation_inside_annotation() async {
    await assertNoErrorsInCode('''
class C {
  const C();
}
class D {
  final C c;
  const D(this.c);
}
@D(const C())
f() {}
''');
  }

  test_instanceAccessToStaticMember_fromComment() async {
    await assertNoErrorsInCode(r'''
class A {
  static m() {}
}
/// [A.m]
main() {
}
''');
  }

  test_instanceAccessToStaticMember_topLevel() async {
    await assertNoErrorsInCode(r'''
m() {}
main() {
  m();
}
''');
  }

  test_instanceMemberAccessFromStatic_fromComment() async {
    await assertNoErrorsInCode(r'''
class A {
  m() {}
  /// [m]
  static foo() {
  }
}
''');
  }

  test_instanceMethodNameCollidesWithSuperclassStatic_field() async {
    newFile("/test/lib/lib.dart", content: r'''
library L;
class A {
  static var _m;
}
''');
    await assertNoErrorsInCode(r'''
import 'lib.dart';
class B extends A {
  _m() {}
}
''');
  }

  test_instanceMethodNameCollidesWithSuperclassStatic_method() async {
    newFile("/test/lib/lib.dart", content: r'''
library L;
class A {
  static _m() {}
}
''');
    await assertNoErrorsInCode(r'''
import 'lib.dart';
class B extends A {
  _m() {}
}
''');
  }

  test_integerLiteralOutOfRange_negative_leadingZeros() async {
    await assertNoErrorsInCode('''
int x = -000923372036854775809;
''');
  }

  test_integerLiteralOutOfRange_negative_small() async {
    await assertNoErrorsInCode('''
int x = -42;
''');
  }

  test_integerLiteralOutOfRange_negative_valid() async {
    await assertNoErrorsInCode('''
int x = -9223372036854775808;
''');
  }

  test_integerLiteralOutOfRange_positive_leadingZeros() async {
    await assertNoErrorsInCode('''
int x = 000923372036854775808;
''');
  }

  test_integerLiteralOutOfRange_positive_valid() async {
    await assertNoErrorsInCode('''
int x = 9223372036854775807;
''');
  }

  test_integerLiteralOutOfRange_positive_zero() async {
    await assertNoErrorsInCode('''
int x = 0;
''');
  }

  test_intLiteralInDoubleContext() async {
    await assertNoErrorsInCode(r'''
void takeDouble(double x) {}
void main() {
  takeDouble(0);
  takeDouble(-0);
  takeDouble(0x0);
  takeDouble(-0x0);
}
''');
  }

  test_intLiteralInDoubleContext_const() async {
    await assertNoErrorsInCode(r'''
class C {
  const C(double x)
    : assert((x + 3) / 2 == 1.5)
    , assert(x == 0.0);
}
@C(0)
@C(-0)
@C(0x0)
@C(-0x0)
void main() {
  const C(0);
  const C(-0);
  const C(0x0);
  const C(-0x0);
}
''');
  }

  test_invalidAnnotation_constantVariable_field() async {
    await assertNoErrorsInCode(r'''
@A.C
class A {
  static const C = 0;
}
''');
  }

  test_invalidAnnotation_constantVariable_field_importWithPrefix() async {
    newFile("/test/lib/lib.dart", content: r'''
library lib;
class A {
  static const C = 0;
}
''');
    await assertNoErrorsInCode(r'''
import 'lib.dart' as p;
@p.A.C
main() {
}
''');
  }

  test_invalidAnnotation_constantVariable_topLevel() async {
    await assertNoErrorsInCode(r'''
const C = 0;
@C
main() {
}
''');
  }

  test_invalidAnnotation_constantVariable_topLevel_importWithPrefix() async {
    newFile("/test/lib/lib.dart", content: r'''
library lib;
const C = 0;
''');
    await assertNoErrorsInCode(r'''
import 'lib.dart' as p;
@p.C
main() {
}
''');
  }

  test_invalidAnnotation_constConstructor_importWithPrefix() async {
    newFile("/test/lib/lib.dart", content: r'''
library lib;
class A {
  const A(int p);
}
''');
    await assertNoErrorsInCode(r'''
import 'lib.dart' as p;
@p.A(42)
main() {
}
''');
  }

  test_invalidAnnotation_constConstructor_named_importWithPrefix() async {
    newFile("/test/lib/lib.dart", content: r'''
library lib;
class A {
  const A.named(int p);
}
''');
    await assertNoErrorsInCode(r'''
import 'lib.dart' as p;
@p.A.named(42)
main() {
}
''');
  }

  test_invalidAssignment() async {
    await assertNoErrorsInCode(r'''
f() {
  var x;
  var y;
  x = y;
}
''');
  }

  test_invalidAssignment_compoundAssignment() async {
    await assertNoErrorsInCode(r'''
class byte {
  int _value;
  byte(this._value);
  byte operator +(int val) { return this; }
}

void main() {
  byte b = new byte(52);
  b += 3;
}
''');
  }

  test_invalidAssignment_defaultValue_named() async {
    await assertNoErrorsInCode(r'''
f({String x: '0'}) {
}''');
  }

  test_invalidAssignment_defaultValue_optional() async {
    await assertNoErrorsInCode(r'''
f([String x = '0']) {
}
''');
  }

  test_invalidAssignment_ifNullAssignment_compatibleType() async {
    await assertNoErrorsInCode('''
void f(int i) {
  num n;
  n ??= i;
}
''');
  }

  test_invalidAssignment_ifNullAssignment_sameType() async {
    await assertNoErrorsInCode('''
void f(int i) {
  int j;
  j ??= i;
}
''');
  }

  test_invalidAssignment_implicitlyImplementFunctionViaCall_1() async {
    // 18341
    //
    // This test and
    // 'test_invalidAssignment_implicitlyImplementFunctionViaCall_2()'
    // are closely related: here we see that 'I' checks as a subtype of
    // 'IntToInt'.
    await assertNoErrorsInCode(r'''
class I {
  int call(int x) => 0;
}
class C implements I {
  noSuchMethod(_) => null;
}
typedef int IntToInt(int x);
IntToInt f = new I();
''');
  }

  test_invalidAssignment_implicitlyImplementFunctionViaCall_2() async {
    // 18341
    //
    // Here 'C' checks as a subtype of 'I', but 'C' does not
    // check as a subtype of 'IntToInt'. Together with
    // 'test_invalidAssignment_implicitlyImplementFunctionViaCall_1()' we see
    // that subtyping is not transitive here.
    await assertNoErrorsInCode(r'''
class I {
  int call(int x) => 0;
}
class C implements I {
  noSuchMethod(_) => null;
}
typedef int IntToInt(int x);
IntToInt f = new C();
''');
  }

  test_invalidAssignment_implicitlyImplementFunctionViaCall_3() async {
    // 18341
    //
    // Like 'test_invalidAssignment_implicitlyImplementFunctionViaCall_2()',
    // but uses type 'Function' instead of more precise type 'IntToInt' for 'f'.
    await assertNoErrorsInCode(r'''
class I {
  int call(int x) => 0;
}
class C implements I {
  noSuchMethod(_) => null;
}
typedef int IntToInt(int x);
Function f = new C();
''');
  }

  test_invalidAssignment_implicitlyImplementFunctionViaCall_4() async {
    // 18341
    //
    // Like 'test_invalidAssignment_implicitlyImplementFunctionViaCall_2()',
    // but uses type 'VoidToInt' instead of more precise type 'IntToInt' for
    // 'f'.
    //
    // Here 'C <: IntToInt <: VoidToInt', but the spec gives no transitivity
    // rule for '<:'. However, many of the :/tools/test.py tests assume this
    // transitivity for 'JsBuilder' objects, assigning them to
    // '(String) -> dynamic'. The declared type of 'JsBuilder.call' is
    // '(String, [dynamic]) -> Expression'.
    await assertNoErrorsInCode(r'''
class I {
  int call([int x]) => 0;
}
class C implements I {
  noSuchMethod(_) => null;
}
typedef int VoidToInt();
VoidToInt f = new C();
''');
  }

  test_invalidAssignment_postfixExpression_localVariable() async {
    await assertNoErrorsInCode(r'''
class A {
  A operator+(_) => this;
}

f(A a) {
  a++;
}
''');
  }

  test_invalidAssignment_postfixExpression_property() async {
    await assertNoErrorsInCode(r'''
class A {
  A operator+(_) => this;
}

class C {
  A a;
}

f(C c) {
  c.a++;
}
''');
  }

  test_invalidAssignment_prefixExpression_localVariable() async {
    await assertNoErrorsInCode(r'''
class A {
  A operator+(_) => this;
}

f(A a) {
  ++a;
}
''');
  }

  test_invalidAssignment_prefixExpression_property() async {
    await assertNoErrorsInCode(r'''
class A {
  A operator+(_) => this;
}

class C {
  A a;
}

f(C c) {
  ++c.a;
}
''');
  }

  test_invalidAssignment_toDynamic() async {
    await assertNoErrorsInCode(r'''
f() {
  var g;
  g = () => 0;
}
''');
  }

  test_invalidFactoryNameNotAClass() async {
    await assertNoErrorsInCode(r'''
class A {
  factory A() => null;
}
''');
  }

  test_invalidIdentifierInAsync() async {
    await assertNoErrorsInCode(r'''
class A {
  m() {
    int async;
    int await;
    int yield;
  }
}
''');
  }

  test_invalidMethodOverrideNamedParamType() async {
    await assertNoErrorsInCode(r'''
class A {
  m({int a}) {}
}
class B implements A {
  m({int a, int b}) {}
}
''');
  }

  test_invalidOverrideNamed_unorderedNamedParameter() async {
    await assertNoErrorsInCode(r'''
class A {
  m({a, b}) {}
}
class B extends A {
  m({b, a}) {}
}
''');
  }

  test_invalidOverrideRequired_less() async {
    await assertNoErrorsInCode(r'''
class A {
  m(a, b) {}
}
class B extends A {
  m(a, [b]) {}
}
''');
  }

  test_invalidOverrideRequired_same() async {
    await assertNoErrorsInCode(r'''
class A {
  m(a) {}
}
class B extends A {
  m(a) {}
}
''');
  }

  test_invalidOverrideReturnType_returnType_interface() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  num m();
}
class B implements A {
  int m() { return 1; }
}
''');
  }

  test_invalidOverrideReturnType_returnType_interface2() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  num m();
}
abstract class B implements A {
}
class C implements B {
  int m() { return 1; }
}
''');
  }

  test_invalidOverrideReturnType_returnType_mixin() async {
    await assertNoErrorsInCode(r'''
class A {
  num m() { return 0; }
}
class B extends Object with A {
  int m() { return 1; }
}
''');
  }

  test_invalidOverrideReturnType_returnType_parameterizedTypes() async {
    await assertNoErrorsInCode(r'''
abstract class A<E> {
  List<E> m();
}
class B extends A<dynamic> {
  List<dynamic> m() { return new List<dynamic>(); }
}
''');
  }

  test_invalidOverrideReturnType_returnType_sameType() async {
    await assertNoErrorsInCode(r'''
class A {
  int m() { return 0; }
}
class B extends A {
  int m() { return 1; }
}
''');
  }

  test_invalidOverrideReturnType_returnType_superclass() async {
    await assertNoErrorsInCode(r'''
class A {
  num m() { return 0; }
}
class B extends A {
  int m() { return 1; }
}
''');
  }

  test_invalidOverrideReturnType_returnType_superclass2() async {
    await assertNoErrorsInCode(r'''
class A {
  num m() { return 0; }
}
class B extends A {
}
class C extends B {
  int m() { return 1; }
}
''');
  }

  test_invalidOverrideReturnType_returnType_void() async {
    await assertNoErrorsInCode(r'''
class A {
  void m() {}
}
class B extends A {
  int m() { return 0; }
}
''');
  }

  test_invalidReferenceToThis_constructor() async {
    await assertNoErrorsInCode(r'''
class A {
  A() {
    var v = this;
  }
}
''');
  }

  test_invalidReferenceToThis_instanceMethod() async {
    await assertNoErrorsInCode(r'''
class A {
  m() {
    var v = this;
  }
}
''');
  }

  test_invalidTypeArgumentForKey() async {
    await assertNoErrorsInCode(r'''
class A {
  m() {
    return const <int, int>{};
  }
}
''');
  }

  test_invalidTypeArgumentInConstList() async {
    await assertNoErrorsInCode(r'''
class A<E> {
  m() {
    return <E>[];
  }
}
''');
  }

  test_invalidTypeArgumentInConstMap() async {
    await assertNoErrorsInCode(r'''
class A<E> {
  m() {
    return <String, E>{};
  }
}
''');
  }

  Future test_issue32114() async {
    newFile('/test/lib/a.dart', content: '''
class O {}

typedef T Func<T extends O>(T e);
''');
    newFile('/test/lib/b.dart', content: '''
import 'a.dart';
export 'a.dart' show Func;

abstract class A<T extends O> {
  Func<T> get func;
}
''');
    await assertNoErrorsInCode('''
import 'b.dart';

class B extends A {
  Func get func => (x) => x;
}
''');
  }

  test_issue_24191() async {
    await assertNoErrorsInCode('''
import 'dart:async';

abstract class S extends Stream {}
f(S s) async {
  await for (var v in s) {
    print(v);
  }
}
''');
  }

  test_issue_32394() async {
    await assertErrorsInCode('''
var x = y.map((a) => a.toString());
var y = [3];
var z = x.toList();

void main() {
  String p = z;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 93, 1),
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 97, 1),
    ]);
    var z = result.unit.declaredElement.topLevelVariables
        .where((e) => e.name == 'z')
        .single;
    expect(z.type.toString(), 'List<String>');
  }

  test_issue_35320_lists() async {
    newFile('/test/lib/lib.dart', content: '''
const x = const <String>['a'];
''');
    await assertNoErrorsInCode('''
import 'lib.dart';
const y = const <String>['b'];
int f(v) {
  switch(v) {
    case x:
      return 0;
    case y:
      return 1;
    default:
      return 2;
  }
}
''');
  }

  test_issue_35320_maps() async {
    newFile('/test/lib/lib.dart', content: '''
const x = const <String, String>{'a': 'b'};
''');
    await assertNoErrorsInCode('''
import 'lib.dart';
const y = const <String, String>{'c': 'd'};
int f(v) {
  switch(v) {
    case x:
      return 0;
    case y:
      return 1;
    default:
      return 2;
  }
}
''');
  }

  test_listElementTypeNotAssignable() async {
    await assertNoErrorsInCode(r'''
var v1 = <int> [42];
var v2 = const <int> [42];
''');
  }

  test_loadLibraryDefined() async {
    newFile('/test/lib/lib.dart', content: r'''
library lib;
foo() => 22;''');
    await assertNoErrorsInCode(r'''
import 'lib.dart' deferred as other;
main() {
  other.loadLibrary().then((_) => other.foo());
}
''');
  }

  test_local_generator_async() async {
    await assertNoErrorsInCode('''
f() {
  return () async* { yield 0; };
}
''');
  }

  test_local_generator_sync() async {
    await assertNoErrorsInCode('''
f() {
  return () sync* { yield 0; };
}
''');
  }

  test_mapKeyTypeNotAssignable() async {
    await assertNoErrorsInCode('''
var v = <String, int > {'a' : 1};
''');
  }

  test_metadata_enumConstantDeclaration() async {
    await assertNoErrorsInCode(r'''
const x = 1;
enum E {
  aaa,
  @x
  bbb
}
''');
  }

  test_methodDeclaration_scope_signature() async {
    await assertNoErrorsInCode(r'''
const app = 0;
class A {
  foo(@app int app) {}
}
''');
  }

  test_misMatchedGetterAndSetterTypes_instance_sameTypes() async {
    await assertNoErrorsInCode(r'''
class C {
  int get x => 0;
  set x(int v) {}
}
''');
  }

  test_misMatchedGetterAndSetterTypes_instance_unspecifiedGetter() async {
    await assertNoErrorsInCode(r'''
class C {
  get x => 0;
  set x(String v) {}
}
''');
  }

  test_misMatchedGetterAndSetterTypes_instance_unspecifiedSetter() async {
    await assertNoErrorsInCode(r'''
class C {
  int get x => 0;
  set x(v) {}
}
''');
  }

  test_misMatchedGetterAndSetterTypes_topLevel_sameTypes() async {
    await assertNoErrorsInCode(r'''
int get x => 0;
set x(int v) {}
''');
  }

  test_misMatchedGetterAndSetterTypes_topLevel_unspecifiedGetter() async {
    await assertNoErrorsInCode(r'''
get x => 0;
set x(String v) {}
''');
  }

  test_misMatchedGetterAndSetterTypes_topLevel_unspecifiedSetter() async {
    await assertNoErrorsInCode(r'''
int get x => 0;
set x(v) {}
''');
  }

  test_missingEnumConstantInSwitch_all() async {
    await assertNoErrorsInCode(r'''
enum E { A, B, C }

f(E e) {
  switch (e) {
    case E.A: break;
    case E.B: break;
    case E.C: break;
  }
}
''');
  }

  test_missingEnumConstantInSwitch_default() async {
    await assertNoErrorsInCode(r'''
enum E { A, B, C }

f(E e) {
  switch (e) {
    case E.B: break;
    default: break;
  }
}
''');
  }

  test_mixedReturnTypes_differentScopes() async {
    await assertNoErrorsInCode(r'''
class C {
  m(int x) {
    f(int y) {
      return;
    }
    f(x);
    return 0;
  }
}
''');
  }

  test_mixedReturnTypes_ignoreImplicit() async {
    await assertNoErrorsInCode(r'''
f(bool p) {
  if (p) return 42;
  // implicit 'return;' is ignored
}
''');
  }

  test_mixedReturnTypes_ignoreImplicit2() async {
    await assertNoErrorsInCode(r'''
f(bool p) {
  if (p) {
    return 42;
  } else {
    return 42;
  }
  // implicit 'return;' is ignored
}
''');
  }

  test_mixedReturnTypes_sameKind() async {
    await assertNoErrorsInCode(r'''
class C {
  m(int x) {
    if (x < 0) {
      return 1;
    }
    return 0;
  }
}
''');
  }

  test_mixin_of_mixin_type_argument_inference() async {
    // In the code below, B's superclass constraints don't include A, because
    // superclass constraints are determined from the mixin's superclass, and
    // B's superclass is Object.  So no mixin type inference is attempted, and
    // "with B" is interpreted as "with B<dynamic>".
    await assertNoErrorsInCode('''
class A<T> {}
class B<T> = Object with A<T>;
class C = Object with B;
''');
    var bReference = result.unit.declaredElement.getType('C').mixins[0];
    expect(bReference.typeArguments[0].toString(), 'dynamic');
  }

  test_mixin_of_mixin_type_argument_inference_cascaded_mixin() async {
    // In the code below, B has a single superclass constraint, A1, because
    // superclass constraints are determined from the mixin's superclass, and
    // B's superclass is "Object with A1<T>".  So mixin type inference succeeds
    // (since C's base class implements A1<int>), and "with B" is interpreted as
    // "with B<int>".
    await assertNoErrorsInCode('''
class A1<T> {}
class A2<T> {}
class B<T> = Object with A1<T>, A2<T>;
class Base implements A1<int> {}
class C = Base with B;
''');
    var bReference = result.unit.declaredElement.getType('C').mixins[0];
    expect(bReference.typeArguments[0].toString(), 'int');
  }

  test_mixinDeclaresConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  m() {}
}
class B extends Object with A {}
''');
  }

  test_mixinDeclaresConstructor_factory() async {
    await assertNoErrorsInCode(r'''
class A {
  factory A() => null;
}
class B extends Object with A {}
''');
  }

  test_mixinInference_with_actual_mixins() async {
    await assertNoErrorsInCode('''
class I<X> {}

mixin M0<T> on I<T> {}

mixin M1<T> on I<T> {
  T foo() => null;
}

class A = I<int> with M0, M1;

void main () {
  var x = new A().foo();
}
''');
    var main = result.unit.declarations.last as FunctionDeclaration;
    var mainBody = main.functionExpression.body as BlockFunctionBody;
    var xDecl = mainBody.block.statements[0] as VariableDeclarationStatement;
    var xElem = xDecl.variables.variables[0].declaredElement;
    expect(xElem.type.toString(), 'int');
  }

  test_mixinInheritsFromNotObject_classDeclaration_extends_new_syntax() async {
    await assertNoErrorsInCode(r'''
class A {}
mixin B on A {}
class C extends A with B {}
''');
  }

  test_mixinInheritsFromNotObject_classDeclaration_mixTypeAlias() async {
    await assertNoErrorsInCode(r'''
class A {}
class B = Object with A;
class C extends Object with B {}
''');
  }

  test_mixinInheritsFromNotObject_typeAlias_extends_new_syntax() async {
    await assertNoErrorsInCode(r'''
class A {}
mixin B on A {}
class C = A with B;
''');
  }

  test_mixinInheritsFromNotObject_typedef_mixTypeAlias() async {
    await assertNoErrorsInCode(r'''
class A {}
class B = Object with A;
class C = Object with B;
''');
  }

  test_mixinReferencesSuper_new_syntax() async {
    await assertNoErrorsInCode(r'''
mixin A {
  toString() => super.toString();
}
class B extends Object with A {}
''');
  }

  test_multipleSuperInitializers_no() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {
  B() {}
}
''');
  }

  test_multipleSuperInitializers_single() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {
  B() : super() {}
}
''');
  }

  test_nativeConstConstructor() async {
    await assertErrorsInCode(r'''
import 'dart-ext:x';
class Foo {
  const Foo() native 'Foo_Foo';
  const factory Foo.foo() native 'Foo_Foo_foo';
}
''', [
      error(ParserErrorCode.CONST_CONSTRUCTOR_WITH_BODY, 47, 6),
    ]);
  }

  test_nativeFunctionBodyInNonSDKCode_function() async {
    await assertNoErrorsInCode(r'''
import 'dart-ext:x';
int m(a) native 'string';
''');
  }

  test_newWithAbstractClass_factory() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  factory A() { return new B(); }
}
class B implements A {
  B() {}
}
A f() {
  return new A();
}
''');
  }

  test_newWithUndefinedConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  A.name() {}
}
f() {
  new A.name();
}
''');
  }

  test_newWithUndefinedConstructorDefault() async {
    await assertNoErrorsInCode(r'''
class A {
  A() {}
}
f() {
  new A();
}
''');
  }

  test_nonAbstractClassInheritsAbstractMemberOne_abstractsDontOverrideConcretes_getter() async {
    await assertNoErrorsInCode(r'''
class A {
  int get g => 0;
}
abstract class B extends A {
  int get g;
}
class C extends B {}
''');
  }

  test_nonAbstractClassInheritsAbstractMemberOne_abstractsDontOverrideConcretes_method() async {
    await assertNoErrorsInCode(r'''
class A {
  m(p) {}
}
abstract class B extends A {
  m(p);
}
class C extends B {}
''');
  }

  test_nonAbstractClassInheritsAbstractMemberOne_abstractsDontOverrideConcretes_setter() async {
    await assertNoErrorsInCode(r'''
class A {
  set s(v) {}
}
abstract class B extends A {
  set s(v);
}
class C extends B {}
''');
  }

  test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_interface() async {
    // 15979
    await assertNoErrorsInCode(r'''
abstract class M {}
abstract class A {}
abstract class I {
  m();
}
abstract class B = A with M implements I;
''');
  }

  test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_mixin() async {
    // 15979
    await assertNoErrorsInCode(r'''
abstract class M {
  m();
}
abstract class A {}
abstract class B = A with M;
''');
  }

  test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_superclass() async {
    // 15979
    await assertNoErrorsInCode(r'''
class M {}
abstract class A {
  m();
}
abstract class B = A with M;
''');
  }

  test_nonAbstractClassInheritsAbstractMemberOne_mixin_getter() async {
    // 17034
    await assertNoErrorsInCode(r'''
class A {
  var a;
}
abstract class M {
  get a;
}
class B extends A with M {}
class C extends B {}
''');
  }

  test_nonAbstractClassInheritsAbstractMemberOne_mixin_method() async {
    await assertNoErrorsInCode(r'''
class A {
  m() {}
}
abstract class M {
  m();
}
class B extends A with M {}
class C extends B {}
''');
  }

  test_nonAbstractClassInheritsAbstractMemberOne_mixin_setter() async {
    await assertNoErrorsInCode(r'''
class A {
  var a;
}
abstract class M {
  set a(dynamic v);
}
class B extends A with M {}
class C extends B {}
''');
  }

  test_nonAbstractClassInheritsAbstractMemberOne_noSuchMethod_accessor() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  int get g;
}
class B extends A {
  noSuchMethod(v) => '';
}
''');
  }

  test_nonAbstractClassInheritsAbstractMemberOne_noSuchMethod_method() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  m(p);
}
class B extends A {
  noSuchMethod(v) => '';
}
''');
  }

  test_nonAbstractClassInheritsAbstractMemberOne_noSuchMethod_mixin() async {
    await assertNoErrorsInCode(r'''
class A {
  noSuchMethod(v) => '';
}
class B extends Object with A {
  m(p);
}
''');
  }

  test_nonAbstractClassInheritsAbstractMemberOne_noSuchMethod_superclass() async {
    await assertNoErrorsInCode(r'''
class A {
  noSuchMethod(v) => '';
}
class B extends A {
  m(p);
}
''');
  }

  test_nonAbstractClassInheritsAbstractMemberOne_overridesMethodInObject() async {
    await assertNoErrorsInCode(r'''
class A {
  String toString([String prefix = '']) => '${prefix}Hello';
}
class C {}
class B extends A with C {}
''');
  }

  test_nonBoolExpression_interfaceType() async {
    await assertNoErrorsInCode(r'''
f() {
  assert(true);
}
''');
  }

  test_nonBoolNegationExpression() async {
    await assertNoErrorsInCode(r'''
f(bool pb, pd) {
  !true;
  !false;
  !pb;
  !pd;
}
''');
  }

  test_nonBoolNegationExpression_dynamic() async {
    await assertNoErrorsInCode(r'''
f1(bool dynamic) {
  !dynamic;
}
f2() {
  bool dynamic = true;
  !dynamic;
}
''');
  }

  test_nonBoolOperand_and_bool() async {
    await assertNoErrorsInCode(r'''
bool f(bool left, bool right) {
  return left && right;
}
''');
  }

  test_nonBoolOperand_and_dynamic() async {
    await assertNoErrorsInCode(r'''
bool f(left, dynamic right) {
  return left && right;
}
''');
  }

  test_nonBoolOperand_or_bool() async {
    await assertNoErrorsInCode(r'''
bool f(bool left, bool right) {
  return left || right;
}
''');
  }

  test_nonBoolOperand_or_dynamic() async {
    await assertNoErrorsInCode(r'''
bool f(dynamic left, right) {
  return left || right;
}
''');
  }

  test_nonConstantDefaultValue_constField() async {
    await assertNoErrorsInCode(r'''
f([a = double.INFINITY]) {
}
''');
  }

  test_nonConstantDefaultValue_function_named() async {
    await assertNoErrorsInCode('''
f({x : 2 + 3}) {}
''');
  }

  test_nonConstantDefaultValue_function_positional() async {
    await assertNoErrorsInCode('''
f([x = 2 + 3]) {}
''');
  }

  test_nonConstantDefaultValue_inConstructor_named() async {
    await assertNoErrorsInCode(r'''
class A {
  A({x : 2 + 3}) {}
}
''');
  }

  test_nonConstantDefaultValue_inConstructor_positional() async {
    await assertNoErrorsInCode(r'''
class A {
  A([x = 2 + 3]) {}
}
''');
  }

  test_nonConstantDefaultValue_method_named() async {
    await assertNoErrorsInCode(r'''
class A {
  m({x : 2 + 3}) {}
}
''');
  }

  test_nonConstantDefaultValue_method_positional() async {
    await assertNoErrorsInCode(r'''
class A {
  m([x = 2 + 3]) {}
}
''');
  }

  test_nonConstantDefaultValue_typedConstList() async {
    await assertNoErrorsInCode(r'''
class A {
  m([p111 = const <String>[]]) {}
}
class B extends A {
  m([p222 = const <String>[]]) {}
}
''');
  }

  test_nonConstantValueInInitializer_namedArgument() async {
    await assertNoErrorsInCode(r'''
class A {
  final a;
  const A({this.a});
}
class B extends A {
  const B({b}) : super(a: b);
}
''');
  }

  test_nonConstCaseExpression_constField() async {
    await assertErrorsInCode(r'''
f(double p) {
  switch (p) {
    case double.INFINITY:
      return true;
    default:
      return false;
  }
}
''', [
      error(CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS, 16, 6),
    ]);
  }

  test_nonConstCaseExpression_typeLiteral() async {
    await assertNoErrorsInCode(r'''
f(Type t) {
  switch (t) {
    case bool:
    case int:
      return true;
    default:
      return false;
  }
}
''');
  }

  test_nonConstListElement_constField() async {
    await assertNoErrorsInCode(r'''
main() {
  const [double.INFINITY];
}
''');
  }

  test_nonConstMapAsExpressionStatement_const() async {
    await assertNoErrorsInCode(r'''
f() {
  const {'a' : 0, 'b' : 1};
}
''');
  }

  test_nonConstMapAsExpressionStatement_notExpressionStatement() async {
    await assertNoErrorsInCode(r'''
f() {
  var m = {'a' : 0, 'b' : 1};
}
''');
  }

  test_nonConstMapAsExpressionStatement_typeArguments() async {
    await assertNoErrorsInCode(r'''
f() {
  <String, int> {'a' : 0, 'b' : 1};
}
''');
  }

  test_nonConstMapValue_constField() async {
    await assertNoErrorsInCode(r'''
main() {
  const {0: double.INFINITY};
}
''');
  }

  test_nonConstValueInInitializer_binary_bool() async {
    await assertErrorsInCode(r'''
class A {
  final v;
  const A.a1(bool p) : v = p && true;
  const A.a2(bool p) : v = true && p;
  const A.b1(bool p) : v = p || true;
  const A.b2(bool p) : v = true || p;
}
''', [
      error(HintCode.DEAD_CODE, 170, 1),
    ]);
  }

  test_nonConstValueInInitializer_binary_dynamic() async {
    await assertNoErrorsInCode(r'''
class A {
  final v;
  const A.a1(p) : v = p + 5;
  const A.a2(p) : v = 5 + p;
  const A.b1(p) : v = p - 5;
  const A.b2(p) : v = 5 - p;
  const A.c1(p) : v = p * 5;
  const A.c2(p) : v = 5 * p;
  const A.d1(p) : v = p / 5;
  const A.d2(p) : v = 5 / p;
  const A.e1(p) : v = p ~/ 5;
  const A.e2(p) : v = 5 ~/ p;
  const A.f1(p) : v = p > 5;
  const A.f2(p) : v = 5 > p;
  const A.g1(p) : v = p < 5;
  const A.g2(p) : v = 5 < p;
  const A.h1(p) : v = p >= 5;
  const A.h2(p) : v = 5 >= p;
  const A.i1(p) : v = p <= 5;
  const A.i2(p) : v = 5 <= p;
  const A.j1(p) : v = p % 5;
  const A.j2(p) : v = 5 % p;
}
''');
  }

  test_nonConstValueInInitializer_binary_int() async {
    await assertNoErrorsInCode(r'''
class A {
  final v;
  const A.a1(int p) : v = p ^ 5;
  const A.a2(int p) : v = 5 ^ p;
  const A.b1(int p) : v = p & 5;
  const A.b2(int p) : v = 5 & p;
  const A.c1(int p) : v = p | 5;
  const A.c2(int p) : v = 5 | p;
  const A.d1(int p) : v = p >> 5;
  const A.d2(int p) : v = 5 >> p;
  const A.e1(int p) : v = p << 5;
  const A.e2(int p) : v = 5 << p;
}
''');
  }

  test_nonConstValueInInitializer_binary_num() async {
    await assertNoErrorsInCode(r'''
class A {
  final v;
  const A.a1(num p) : v = p + 5;
  const A.a2(num p) : v = 5 + p;
  const A.b1(num p) : v = p - 5;
  const A.b2(num p) : v = 5 - p;
  const A.c1(num p) : v = p * 5;
  const A.c2(num p) : v = 5 * p;
  const A.d1(num p) : v = p / 5;
  const A.d2(num p) : v = 5 / p;
  const A.e1(num p) : v = p ~/ 5;
  const A.e2(num p) : v = 5 ~/ p;
  const A.f1(num p) : v = p > 5;
  const A.f2(num p) : v = 5 > p;
  const A.g1(num p) : v = p < 5;
  const A.g2(num p) : v = 5 < p;
  const A.h1(num p) : v = p >= 5;
  const A.h2(num p) : v = 5 >= p;
  const A.i1(num p) : v = p <= 5;
  const A.i2(num p) : v = 5 <= p;
  const A.j1(num p) : v = p % 5;
  const A.j2(num p) : v = 5 % p;
}
''');
  }

  test_nonConstValueInInitializer_field() async {
    await assertNoErrorsInCode(r'''
class A {
  final int a;
  const A() : a = 5;
}
''');
  }

  test_nonConstValueInInitializer_redirecting() async {
    await assertNoErrorsInCode(r'''
class A {
  const A.named(p);
  const A() : this.named(42);
}
''');
  }

  test_nonConstValueInInitializer_super() async {
    await assertNoErrorsInCode(r'''
class A {
  const A(p);
}
class B extends A {
  const B() : super(42);
}
''');
  }

  test_nonConstValueInInitializer_unary() async {
    await assertNoErrorsInCode(r'''
class A {
  final v;
  const A.a(bool p) : v = !p;
  const A.b(int p) : v = ~p;
  const A.c(num p) : v = -p;
}
''');
  }

  test_nonGenerativeConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  A.named() {}
  factory A() => null;
}
class B extends A {
  B() : super.named();
}
''');
  }

  test_nonTypeInCatchClause_isClass() async {
    await assertNoErrorsInCode(r'''
f() {
  try {
  } on String catch (e) {
  }
}
''');
  }

  test_nonTypeInCatchClause_isFunctionTypeAlias() async {
    await assertNoErrorsInCode(r'''
typedef F();
f() {
  try {
  } on F catch (e) {
  }
}
''');
  }

  test_nonTypeInCatchClause_isTypeParameter() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  f() {
    try {
    } on T catch (e) {
    }
  }
}
''');
  }

  test_nonTypeInCatchClause_noType() async {
    await assertNoErrorsInCode(r'''
f() {
  try {
  } catch (e) {
  }
}
''');
  }

  test_nonVoidReturnForOperator_no() async {
    await assertNoErrorsInCode(r'''
class A {
  operator []=(a, b) {}
}
''');
  }

  test_nonVoidReturnForOperator_void() async {
    await assertNoErrorsInCode(r'''
class A {
  void operator []=(a, b) {}
}
''');
  }

  test_nonVoidReturnForSetter_function_no() async {
    await assertNoErrorsInCode('''
set x(v) {}
''');
  }

  test_nonVoidReturnForSetter_function_void() async {
    await assertNoErrorsInCode('''
void set x(v) {}
''');
  }

  test_nonVoidReturnForSetter_method_no() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(v) {}
}
''');
  }

  test_nonVoidReturnForSetter_method_void() async {
    await assertNoErrorsInCode(r'''
class A {
  void set x(v) {}
}
''');
  }

  @failingTest
  test_null_callOperator() async {
    await assertErrorsInCode(r'''
main() {
  null + 5;
  null == 5;
  null[0];
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 0, 0),
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 0, 0),
    ]);
  }

  test_optionalNew_rewrite() async {
    newFile("/test/lib/a.dart", content: r'''
class A {
  const A();
  const A.named();
}
''');
    newFile("/test/lib/b.dart", content: r'''
import 'a.dart';
import 'a.dart' as p;

const _a1 = A();
const _a2 = A.named();
const _a3 = p.A();
const _a4 = p.A.named();

class B {
  const B.named1({this.a: _a1}) : assert(a != null);
  const B.named2({this.a: _a2}) : assert(a != null);
  const B.named3({this.a: _a3}) : assert(a != null);
  const B.named4({this.a: _a4}) : assert(a != null);

  final A a;
}
''');
    await assertNoErrorsInCode(r'''
import 'b.dart';
main() {
  const B.named1();
  const B.named2();
  const B.named3();
  const B.named4();
}
''');
  }

  test_optionalNew_rewrite_instantiatesToBounds() async {
    newFile("/test/lib/a.dart", content: r'''
class Unbounded<T> {
  const Unbounded();
  const Unbounded.named();
}
class Bounded<T extends String> {
  const Bounded();
  const Bounded.named();
}
''');
    newFile("/test/lib/b.dart", content: r'''
import 'a.dart';
import 'a.dart' as p;

const unbounded1 = Unbounded();
const unbounded2 = Unbounded.named();
const unbounded3 = p.Unbounded();
const unbounded4 = p.Unbounded.named();
const bounded1 = Bounded();
const bounded2 = Bounded.named();
const bounded3 = p.Bounded();
const bounded4 = p.Bounded.named();

class B {
  const B.named1({this.unbounded: unbounded1}) : bounded = null;
  const B.named2({this.unbounded: unbounded2}) : bounded = null;
  const B.named3({this.unbounded: unbounded3}) : bounded = null;
  const B.named4({this.unbounded: unbounded4}) : bounded = null;
  const B.named5({this.bounded: bounded1}) : unbounded = null;
  const B.named6({this.bounded: bounded2}) : unbounded = null;
  const B.named7({this.bounded: bounded3}) : unbounded = null;
  const B.named8({this.bounded: bounded4}) : unbounded = null;

  final Unbounded unbounded;
  final Bounded bounded;
}
''');
    await assertNoErrorsInCode(r'''
import 'b.dart';

@B.named1()
@B.named2()
@B.named3()
@B.named4()
@B.named5()
@B.named6()
@B.named7()
@B.named8()
main() {}
''');
    expect(result.unit.declarations, hasLength(1));
    final mainDecl = result.unit.declarations[0];
    expect(mainDecl.metadata, hasLength(8));
    mainDecl.metadata.forEach((metadata) {
      final value = metadata.elementAnnotation.computeConstantValue();
      expect(value, isNotNull);
      expect(value.type.toString(), 'B');
      final unbounded = value.getField('unbounded');
      final bounded = value.getField('bounded');
      if (!unbounded.isNull) {
        expect(bounded.isNull, true);
        expect(unbounded.type.name, 'Unbounded');
        expect(unbounded.type.typeArguments, hasLength(1));
        expect(unbounded.type.typeArguments[0].isDynamic, isTrue);
      } else {
        expect(unbounded.isNull, true);
        expect(bounded.type.name, 'Bounded');
        expect(bounded.type.typeArguments, hasLength(1));
        expect(bounded.type.typeArguments[0].name, 'String');
      }
    });
  }

  test_optionalParameterInOperator_required() async {
    await assertNoErrorsInCode(r'''
class A {
  operator +(p) {}
}
''');
  }

  test_parameterScope_local() async {
    // Parameter names shouldn't conflict with the name of the function they
    // are enclosed in.
    await assertNoErrorsInCode(r'''
f() {
  g(g) {
    h(g);
  }
}
h(x) {}
''');
  }

  test_parameterScope_method() async {
    // Parameter names shouldn't conflict with the name of the function they
    // are enclosed in.
    await assertNoErrorsInCode(r'''
class C {
  g(g) {
    h(g);
  }
}
h(x) {}
''');
  }

  test_parameterScope_topLevel() async {
    // Parameter names shouldn't conflict with the name of the function they
    // are enclosed in.
    await assertNoErrorsInCode(r'''
g(g) {
  h(g);
}
h(x) {}
''');
  }

  test_parametricCallFunction() async {
    await assertNoErrorsInCode(r'''
f() {
  var c = new C();
  c<String>().codeUnits;
}

class C {
  T call<T>() => null;
}
''');
  }

  test_prefixCollidesWithTopLevelMembers() async {
    newFile("/test/lib/lib.dart", content: r'''
library lib;
class A {}''');
    await assertNoErrorsInCode(r'''
import 'lib.dart' as p;
typedef P();
p2() {}
var p3;
class p4 {}
p.A a;
''');
  }

  test_propagateTypeArgs_intoBounds() async {
    await assertNoErrorsInCode(r'''
abstract class A<E> {}
abstract class B<F> implements A<F>{}
abstract class C<G, H extends A<G>> {}
class D<I> extends C<I, B<I>> {}
''');
  }

  test_propagateTypeArgs_intoSupertype() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  A(T p);
  A.named(T p);
}
class B<S> extends A<S> {
  B(S p) : super(p);
  B.named(S p) : super.named(p);
}
''');
  }

  test_recursiveConstructorRedirect() async {
    await assertNoErrorsInCode(r'''
class A {
  A.a() : this.b();
  A.b() : this.c();
  A.c() {}
}
''');
  }

  test_recursiveFactoryRedirect() async {
    await assertNoErrorsInCode(r'''
class A {
  factory A() = B;
}
class B implements A {
  factory B() = C;
}
class C implements B {
  factory C() => null;
}
''');
  }

  test_redirectToInvalidFunctionType() async {
    await assertNoErrorsInCode(r'''
class A implements B {
  A(int p) {}
}
class B {
  factory B(int p) = A;
}
''');
  }

  test_redirectToNonConstConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  const A.a();
  const factory A.b() = A.a;
}
''');
  }

  test_referencedBeforeDeclaration_cascade() async {
    await assertNoErrorsInCode(r'''
testRequestHandler() {}

main() {
  var s1 = null;
  testRequestHandler()
    ..stream(s1);
  var stream = 123;
  print(stream);
}
''');
  }

  test_referenceToDeclaredVariableInInitializer_constructorName() async {
    await assertNoErrorsInCode(r'''
class A {
  A.x() {}
}
f() {
  var x = new A.x();
}
''');
  }

  test_referenceToDeclaredVariableInInitializer_methodName() async {
    await assertNoErrorsInCode(r'''
class A {
  x() {}
}
f(A a) {
  var x = a.x();
}
''');
  }

  test_referenceToDeclaredVariableInInitializer_propertyName() async {
    await assertNoErrorsInCode(r'''
class A {
  var x;
}
f(A a) {
  var x = a.x;
}
''');
  }

  test_regress34906() async {
    await assertNoErrorsInCode(r'''
typedef G<X, Y extends Function(X)> = X Function(Function(Y));
G<dynamic, Function(Null)> superBoundedG;
''');
  }

  test_rethrowOutsideCatch() async {
    await assertNoErrorsInCode(r'''
class A {
  void m() {
    try {} catch (e) {rethrow;}
  }
}
''');
  }

  test_return_in_generator_async() async {
    await assertNoErrorsInCode('''
import 'dart:async';
Stream<int> f() async* {
  return;
}
''');
  }

  test_return_in_generator_sync() async {
    await assertNoErrorsInCode('''
Iterable<int> f() sync* {
  return;
}
''');
  }

  test_returnInGenerativeConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  A() { return; }
}
''');
  }

  test_returnInGenerator_async() async {
    await assertNoErrorsInCode(r'''
f() async {
  return 0;
}
''');
  }

  test_returnInGenerator_sync() async {
    await assertNoErrorsInCode(r'''
f() {
  return 0;
}
''');
  }

  test_returnOfInvalidType_async() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';
class A {
  Future<int> m() async {
    return 0;
  }
}
''');
  }

  test_returnOfInvalidType_dynamic() async {
    await assertNoErrorsInCode(r'''
class TypeError {}
class A {
  static void testLogicalOp() {
    testOr(a, b, onTypeError) {
      try {
        return a || b;
      } on TypeError catch (t) {
        return onTypeError;
      }
    }
  }
}
''');
  }

  test_returnOfInvalidType_subtype() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {}
A f(B b) { return b; }
''');
  }

  test_returnOfInvalidType_supertype() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {}
B f(A a) { return a; }
''');
  }

  test_returnOfInvalidType_typeParameter_18468() async {
    // https://code.google.com/p/dart/issues/detail?id=18468
    //
    // This test verifies that the type of T is more specific than Type,
    // where T is a type parameter and Type is the type Type from
    // core, this particular test case comes from issue 18468.
    //
    // A test cannot be added to TypeParameterTypeImplTest since the types
    // returned out of the TestTypeProvider don't have a mock 'dart.core'
    // enclosing library element.
    // See TypeParameterTypeImpl.isMoreSpecificThan().
    await assertNoErrorsInCode(r'''
class Foo<T> {
  Type get t => T;
}
''');
  }

  test_returnOfInvalidType_void() async {
    await assertNoErrorsInCode(r'''
void f1() {}
void f2() { return; }
void f3() { return null; }
void f4() { return g1(); }
void f5() { return g2(); }
void f6() => throw 42;
g1() {}
void g2() {}
''');
  }

  test_returnWithoutValue_noReturnType() async {
    await assertNoErrorsInCode('''
f() { return; }
''');
  }

  test_returnWithoutValue_void() async {
    await assertNoErrorsInCode('''
void f() { return; }
''');
  }

  test_reversedTypeArguments() async {
    await assertNoErrorsInCode(r'''
class Codec<S1, T1> {
  Codec<T1, S1> get inverted => new _InvertedCodec<T1, S1>(this);
}
class _InvertedCodec<T2, S2> extends Codec<T2, S2> {
  _InvertedCodec(Codec<S2, T2> codec);
}
''');
  }

  test_sharedDeferredPrefix() async {
    newFile('/test/lib/lib1.dart', content: r'''
f1() {}
''');
    newFile('/test/lib/lib2.dart', content: r'''
f2() {}
''');
    newFile('/test/lib/lib3.dart', content: r'''
f3() {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' deferred as lib1;
import 'lib2.dart' as lib;
import 'lib3.dart' as lib;
main() { lib1.f1(); lib.f2(); lib.f3(); }
''');
  }

  test_staticAccessToInstanceMember_annotation() async {
    await assertNoErrorsInCode(r'''
class A {
  const A.name();
}
@A.name()
main() {
}
''');
  }

  test_staticAccessToInstanceMember_method() async {
    await assertNoErrorsInCode(r'''
class A {
  static m() {}
}
main() {
  A.m;
  A.m();
}
''');
  }

  test_staticAccessToInstanceMember_propertyAccess_field() async {
    await assertNoErrorsInCode(r'''
class A {
  static var f;
}
main() {
  A.f;
  A.f = 1;
}
''');
  }

  test_staticAccessToInstanceMember_propertyAccess_propertyAccessor() async {
    await assertNoErrorsInCode(r'''
class A {
  static get f => 42;
  static set f(x) {}
}
main() {
  A.f;
  A.f = 1;
}
''');
  }

  test_superInInvalidContext() async {
    await assertNoErrorsInCode(r'''
class A {
  m() {}
}
class B extends A {
  B() {
    var v = super.m();
  }
  n() {
    var v = super.m();
  }
}
''');
  }

  test_typeAliasCannotReferenceItself_returnClass_withTypeAlias() async {
    await assertNoErrorsInCode(r'''
typedef B A();
class B {
  A a;
}
''');
  }

  test_typeArgument_boundToFunctionType() async {
    await assertNoErrorsInCode('''
class A<T extends void Function(T)>{}
''');
  }

  test_typeArgumentNotMatchingBounds_const() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {}
class G<E extends A> {
  const G();
}
f() { return const G<B>(); }
''');
  }

  test_typeArgumentNotMatchingBounds_new() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {}
class G<E extends A> {}
f() { return new G<B>(); }
''');
  }

  test_typeArgumentNotMatchingBounds_ofFunctionTypeAlias_hasBound() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {}
typedef F<T extends A>();
F<A> fa;
F<B> fb;
''');
  }

  test_typeArgumentNotMatchingBounds_ofFunctionTypeAlias_hasBound2() async {
    await assertNoErrorsInCode(r'''
class MyClass<T> {}
typedef MyFunction<T, P extends MyClass<T>>();
class A<T, P extends MyClass<T>> {
  MyFunction<T, P> f;
}
''');
  }

  test_typeArgumentNotMatchingBounds_ofFunctionTypeAlias_noBound() async {
    await assertNoErrorsInCode(r'''
typedef F<T>();
F<int> f1;
F<String> f2;
''');
  }

  test_typedef_not_function() async {
    newFile('/test/lib/a.dart', content: '''
typedef F = int;
''');
    await assertNoErrorsInCode('''
import 'a.dart';
F f;
''');
  }

  test_typePromotion_booleanAnd_useInRight() async {
    await assertNoErrorsInCode(r'''
main(Object p) {
  p is String && p.length != 0;
}
''');
  }

  test_typePromotion_booleanAnd_useInRight_accessedInClosureRight_noAssignment() async {
    await assertNoErrorsInCode(r'''
callMe(f()) { f(); }
main(Object p) {
  (p is String) && callMe(() { p.length; });
}
''');
  }

  test_typePromotion_conditional_issue14655() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {}
class C extends B {
  mc() {}
}
print(_) {}
main(A p) {
  (p is C) && (print(() => p) && (p is B)) ? p.mc() : p = null;
}
''');
  }

  test_typePromotion_conditional_useInThen() async {
    await assertNoErrorsInCode(r'''
main(Object p) {
  p is String ? p.length : 0;
}''');
  }

  test_typePromotion_conditional_useInThen_accessedInClosure_noAssignment() async {
    await assertNoErrorsInCode(r'''
callMe(f()) { f(); }
main(Object p) {
  p is String ? callMe(() { p.length; }) : 0;
}
''');
  }

  test_typePromotion_functionType_arg_ignoreIfNotMoreSpecific() async {
    await assertNoErrorsInCode(r'''
typedef FuncB(B b);
typedef FuncA(A a);
class A {}
class B {}
main(FuncA f) {
  if (f is FuncB) {
    f(new A());
  }
}
''');
  }

  test_typePromotion_functionType_return_ignoreIfNotMoreSpecific() async {
    await assertNoErrorsInCode(r'''
class A {}
typedef FuncAtoDyn(A a);
typedef FuncDynToDyn(x);
main(FuncAtoDyn f) {
  if (f is FuncDynToDyn) {
    A a = f(new A());
  }
}
''');
  }

  test_typePromotion_functionType_return_voidToDynamic() async {
    await assertNoErrorsInCode(r'''
typedef FuncDynToDyn(x);
typedef void FuncDynToVoid(x);
class A {}
main(FuncDynToVoid f) {
  if (f is FuncDynToDyn) {
    A a = f(null);
  }
}
''');
  }

  test_typePromotion_if_accessedInClosure_noAssignment() async {
    await assertNoErrorsInCode(r'''
callMe(f()) { f(); }
main(Object p) {
  if (p is String) {
    callMe(() {
      p.length;
    });
  }
}
''');
  }

  test_typePromotion_if_extends_moreSpecific() async {
    await assertNoErrorsInCode(r'''
class V {}
class VP extends V {}
class A<T> {}
class B<S> extends A<S> {
  var b;
}

main(A<V> p) {
  if (p is B<VP>) {
    p.b;
  }
}
''');
  }

  test_typePromotion_if_hasAssignment_outsideAfter() async {
    await assertNoErrorsInCode(r'''
main(Object p) {
  if (p is String) {
    p.length;
  }
  p = 0;
}
''');
  }

  test_typePromotion_if_hasAssignment_outsideBefore() async {
    await assertNoErrorsInCode(r'''
main(Object p, Object p2) {
  p = p2;
  if (p is String) {
    p.length;
  }
}''');
  }

  test_typePromotion_if_implements_moreSpecific() async {
    await assertNoErrorsInCode(r'''
class V {}
class VP extends V {}
class A<T> {}
class B<S> implements A<S> {
  var b;
}

main(A<V> p) {
  if (p is B<VP>) {
    p.b;
  }
}
''');
  }

  test_typePromotion_if_inClosure_assignedAfter_inSameFunction() async {
    await assertNoErrorsInCode(r'''
main() {
  f(Object p) {
    if (p is String) {
      p.length;
    }
    p = 0;
  };
}
''');
  }

  test_typePromotion_if_is_and_left() async {
    await assertNoErrorsInCode(r'''
bool tt() => true;
main(Object p) {
  if (p is String && tt()) {
    p.length;
  }
}
''');
  }

  test_typePromotion_if_is_and_right() async {
    await assertNoErrorsInCode(r'''
bool tt() => true;
main(Object p) {
  if (tt() && p is String) {
    p.length;
  }
}
''');
  }

  test_typePromotion_if_is_and_subThenSuper() async {
    await assertNoErrorsInCode(r'''
class A {
  var a;
}
class B extends A {
  var b;
}
main(Object p) {
  if (p is B && p is A) {
    p.a;
    p.b;
  }
}
''');
  }

  test_typePromotion_if_is_parenthesized() async {
    await assertNoErrorsInCode(r'''
main(Object p) {
  if ((p is String)) {
    p.length;
  }
}
''');
  }

  test_typePromotion_if_is_single() async {
    await assertNoErrorsInCode(r'''
main(Object p) {
  if (p is String) {
    p.length;
  }
}
''');
  }

  test_typePromotion_parentheses() async {
    await assertNoErrorsInCode(r'''
main(Object p) {
  (p is String) ? p.length : 0;
  (p) is String ? p.length : 0;
  ((p)) is String ? p.length : 0;
  ((p) is String) ? p.length : 0;
}
''');
  }

  test_typeType_class() async {
    await assertNoErrorsInCode(r'''
class C {}
f(Type t) {}
main() {
  f(C);
}
''');
  }

  test_typeType_class_prefixed() async {
    newFile("/test/lib/lib.dart", content: r'''
library lib;
class C {}''');
    await assertNoErrorsInCode(r'''
import 'lib.dart' as p;
f(Type t) {}
main() {
  f(p.C);
}
''');
  }

  test_typeType_functionTypeAlias() async {
    await assertNoErrorsInCode(r'''
typedef F();
f(Type t) {}
main() {
  f(F);
}
''');
  }

  test_typeType_functionTypeAlias_prefixed() async {
    newFile("/test/lib/lib.dart", content: r'''
library lib;
typedef F();''');
    await assertNoErrorsInCode(r'''
import 'lib.dart' as p;
f(Type t) {}
main() {
  f(p.F);
}
''');
  }

  test_undefinedConstructorInInitializer_explicit_named() async {
    await assertNoErrorsInCode(r'''
class A {
  A.named() {}
}
class B extends A {
  B() : super.named();
}
''');
  }

  test_undefinedConstructorInInitializer_explicit_unnamed() async {
    await assertNoErrorsInCode(r'''
class A {
  A() {}
}
class B extends A {
  B() : super();
}
''');
  }

  test_undefinedConstructorInInitializer_hasOptionalParameters() async {
    await assertNoErrorsInCode(r'''
class A {
  A([p]) {}
}
class B extends A {
  B();
}
''');
  }

  test_undefinedConstructorInInitializer_implicit() async {
    await assertNoErrorsInCode(r'''
class A {
  A() {}
}
class B extends A {
  B();
}
''');
  }

  test_undefinedConstructorInInitializer_redirecting() async {
    await assertNoErrorsInCode(r'''
class Foo {
  Foo.ctor();
}
class Bar extends Foo {
  Bar() : this.ctor();
  Bar.ctor() : super.ctor();
}
''');
  }

  @failingTest
  test_undefinedEnumConstant() async {
    await assertNoErrorsInCode(r'''
enum E { ONE }
E e() {
  return E.TWO;
}
''');
  }

  test_undefinedGetter_static_conditionalAccess() async {
    // The conditional access operator '?.' can be used to access static
    // fields.
    await assertNoErrorsInCode('''
class A {
  static var x;
}
var a = A?.x;
''');
  }

  test_undefinedGetter_typeSubstitution() async {
    await assertNoErrorsInCode(r'''
class A<E> {
  E element;
}
class B extends A<List> {
  m() {
    element.last;
  }
}
''');
  }

  test_undefinedIdentifier_synthetic_whenExpression() async {
    await assertErrorsInCode(r'''
print(x) {}
main() {
  print(is String);
}
''', [
      error(ParserErrorCode.MISSING_IDENTIFIER, 29, 2),
    ]);
  }

  test_undefinedIdentifier_synthetic_whenMethodName() async {
    await assertErrorsInCode(r'''
print(x) {}
main(int p) {
  p.();
}
''', [
      error(ParserErrorCode.MISSING_IDENTIFIER, 30, 1),
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 30, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 31, 1),
    ]);
  }

  test_undefinedMethod_functionExpression_callMethod() async {
    await assertNoErrorsInCode(r'''
main() {
  (() => null).call();
}
''');
  }

  test_undefinedMethod_functionExpression_directCall() async {
    await assertNoErrorsInCode(r'''
main() {
  (() => null)();
}
''');
  }

  test_undefinedMethod_static_conditionalAccess() async {
    // The conditional access operator '?.' can be used to access static
    // methods.
    await assertNoErrorsInCode('''
class A {
  static void m() {}
}
f() { A?.m(); }
''');
  }

  test_undefinedOperator_index() async {
    await assertNoErrorsInCode(r'''
class A {
  operator [](a) {}
  operator []=(a, b) {}
}
f(A a) {
  a[0];
  a[0] = 1;
}
''');
  }

  test_undefinedOperator_tilde() async {
    await assertNoErrorsInCode(r'''
const A = 3;
const B = ~((1 << A) - 1);
''');
  }

  test_undefinedSetter_importWithPrefix() async {
    newFile("/test/lib/lib.dart", content: r'''
library lib;
set y(int value) {}''');
    await assertNoErrorsInCode(r'''
import 'lib.dart' as x;
main() {
  x.y = 0;
}
''');
  }

  test_undefinedSetter_static_conditionalAccess() async {
    // The conditional access operator '?.' can be used to access static
    // fields.
    await assertNoErrorsInCode('''
class A {
  static var x;
}
f() { A?.x = 1; }
''');
  }

  test_undefinedSuperMethod_field() async {
    await assertNoErrorsInCode(r'''
class A {
  var m;
}
class B extends A {
  f() {
    super.m();
  }
}
''');
  }

  test_undefinedSuperMethod_method() async {
    await assertNoErrorsInCode(r'''
class A {
  m() {}
}
class B extends A {
  f() {
    super.m();
  }
}
''');
  }

  test_unusedShownName_unresolved() async {
    await assertErrorsInCode(r'''
import 'dart:math' show max, FooBar;
main() {
  print(max(1, 2));
}
''', [
      error(HintCode.UNDEFINED_SHOWN_NAME, 29, 6),
    ]);
  }

  test_uriDoesNotExist_dll() async {
    newFile("/test/lib/lib.dll");
    await assertNoErrorsInCode('''
import 'dart-ext:lib';
''');
  }

  test_uriDoesNotExist_dylib() async {
    newFile("/test/lib/lib.dylib");
    await assertNoErrorsInCode('''
import 'dart-ext:lib';
''');
  }

  test_uriDoesNotExist_so() async {
    newFile("/test/lib/lib.so");
    await assertNoErrorsInCode('''
import 'dart-ext:lib';
''');
  }

  Future test_useDynamicWithPrefix() async {
    await assertNoErrorsInCode('''
import 'dart:core' as core;

core.dynamic dynamicVariable;
''');
  }

  test_wrongNumberOfParametersForOperator1() async {
    await _check_wrongNumberOfParametersForOperator1("<");
    await _check_wrongNumberOfParametersForOperator1(">");
    await _check_wrongNumberOfParametersForOperator1("<=");
    await _check_wrongNumberOfParametersForOperator1(">=");
    await _check_wrongNumberOfParametersForOperator1("+");
    await _check_wrongNumberOfParametersForOperator1("/");
    await _check_wrongNumberOfParametersForOperator1("~/");
    await _check_wrongNumberOfParametersForOperator1("*");
    await _check_wrongNumberOfParametersForOperator1("%");
    await _check_wrongNumberOfParametersForOperator1("|");
    await _check_wrongNumberOfParametersForOperator1("^");
    await _check_wrongNumberOfParametersForOperator1("&");
    await _check_wrongNumberOfParametersForOperator1("<<");
    await _check_wrongNumberOfParametersForOperator1(">>");
    await _check_wrongNumberOfParametersForOperator1("[]");
  }

  test_wrongNumberOfParametersForOperator_index() async {
    await assertNoErrorsInCode(r'''
class A {
  operator []=(a, b) {}
}
''');
  }

  test_wrongNumberOfParametersForOperator_minus() async {
    await _check_wrongNumberOfParametersForOperator("-", "");
    await _check_wrongNumberOfParametersForOperator("-", "a");
  }

  test_wrongNumberOfParametersForSetter() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(a) {}
}
''');
  }

  test_yield_async_to_dynamic_type() async {
    await assertNoErrorsInCode('''
dynamic f() async* {
  yield 3;
}
''');
  }

  test_yield_async_to_generic_type() async {
    await assertNoErrorsInCode('''
import 'dart:async';
Stream f() async* {
  yield 3;
}
''');
  }

  test_yield_async_to_parameterized_type() async {
    await assertNoErrorsInCode('''
import 'dart:async';
Stream<int> f() async* {
  yield 3;
}
''');
  }

  test_yield_async_to_untyped() async {
    await assertNoErrorsInCode('''
f() async* {
  yield 3;
}
''');
  }

  test_yield_each_async_dynamic_to_dynamic() async {
    await assertNoErrorsInCode('''
f() async* {
  yield* g();
}
g() => null;
''');
  }

  test_yield_each_async_dynamic_to_stream() async {
    await assertNoErrorsInCode('''
import 'dart:async';
Stream f() async* {
  yield* g();
}
g() => null;
''');
  }

  test_yield_each_async_dynamic_to_typed_stream() async {
    await assertNoErrorsInCode('''
import 'dart:async';
Stream<int> f() async* {
  yield* g();
}
g() => null;
''');
  }

  test_yield_each_async_stream_to_dynamic() async {
    await assertNoErrorsInCode('''
import 'dart:async';
f() async* {
  yield* g();
}
Stream g() => null;
''');
  }

  test_yield_each_async_typed_stream_to_dynamic() async {
    await assertNoErrorsInCode('''
import 'dart:async';
f() async* {
  yield* g();
}
Stream<int> g() => null;
''');
  }

  test_yield_each_async_typed_stream_to_typed_stream() async {
    await assertNoErrorsInCode('''
import 'dart:async';
Stream<int> f() async* {
  yield* g();
}
Stream<int> g() => null;
''');
  }

  test_yield_each_sync_dynamic_to_dynamic() async {
    await assertNoErrorsInCode('''
f() sync* {
  yield* g();
}
g() => null;
''');
  }

  test_yield_each_sync_dynamic_to_iterable() async {
    await assertNoErrorsInCode('''
Iterable f() sync* {
  yield* g();
}
g() => null;
''');
  }

  test_yield_each_sync_dynamic_to_typed_iterable() async {
    await assertNoErrorsInCode('''
Iterable<int> f() sync* {
  yield* g();
}
g() => null;
''');
  }

  test_yield_each_sync_iterable_to_dynamic() async {
    await assertNoErrorsInCode('''
f() sync* {
  yield* g();
}
Iterable g() => null;
''');
  }

  test_yield_each_sync_typed_iterable_to_dynamic() async {
    await assertNoErrorsInCode('''
f() sync* {
  yield* g();
}
Iterable<int> g() => null;
''');
  }

  test_yield_each_sync_typed_iterable_to_typed_iterable() async {
    await assertNoErrorsInCode('''
Iterable<int> f() sync* {
  yield* g();
}
Iterable<int> g() => null;
''');
  }

  test_yield_sync_to_dynamic_type() async {
    await assertNoErrorsInCode('''
dynamic f() sync* {
  yield 3;
}
''');
  }

  test_yield_sync_to_generic_type() async {
    await assertNoErrorsInCode('''
Iterable f() sync* {
  yield 3;
}
''');
  }

  test_yield_sync_to_parameterized_type() async {
    await assertNoErrorsInCode('''
Iterable<int> f() sync* {
  yield 3;
}
''');
  }

  test_yield_sync_to_untyped() async {
    await assertNoErrorsInCode('''
f() sync* {
  yield 3;
}
''');
  }

  test_yieldInNonGenerator_asyncStar() async {
    await assertNoErrorsInCode(r'''
f() async* {
  yield 0;
}
''');
  }

  test_yieldInNonGenerator_syncStar() async {
    await assertNoErrorsInCode(r'''
f() sync* {
  yield 0;
}
''');
  }

  Future<void> _check_wrongNumberOfParametersForOperator(
      String name, String parameters) async {
    await assertNoErrorsInCode('''
class A {
  operator $name($parameters) {}
}
''');
  }

  Future<void> _check_wrongNumberOfParametersForOperator1(String name) async {
    await _check_wrongNumberOfParametersForOperator(name, "a");
  }
}
