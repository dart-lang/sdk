// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.non_error_resolver_test;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:analyzer/src/generated/source_io.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'resolver_test_case.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonErrorResolverTest);
  });
}

@reflectiveTest
class NonErrorResolverTest extends ResolverTestCase {
  void fail_undefinedEnumConstant() {
    Source source = addSource(r'''
enum E { ONE }
E e() {
  return E.TWO;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void
      test_abstractSuperMemberReference_superHasConcrete_mixinHasAbstract_method() {
    Source source = addSource('''
class A {
  void method() {}
}

abstract class B {
  void method();
}

class C extends A with B {
  void method() {
    super.method();
  }
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_abstractSuperMemberReference_superHasNoSuchMethod() {
    Source source = addSource('''
abstract class A {
  int m();
  noSuchMethod(_) => 42;
}

class B extends A {
  int m() => super.m();
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_abstractSuperMemberReference_superSuperHasConcrete_getter() {
    Source source = addSource('''
abstract class A {
  int get m => 0;
}

abstract class B extends A {
  int get m;
}

class C extends B {
  int get m => super.m;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_abstractSuperMemberReference_superSuperHasConcrete_method() {
    Source source = addSource('''
void main() {
  print(new C().m());
}

abstract class A {
  int m() => 0;
}

abstract class B extends A {
  int m();
}

class C extends B {
  int m() => super.m();
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_abstractSuperMemberReference_superSuperHasConcrete_setter() {
    Source source = addSource('''
abstract class A {
  void set m(int v) {}
}

abstract class B extends A {
  void set m(int v);
}

class C extends B {
  void set m(int v) {
    super.m = 0;
  }
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_ambiguousExport() {
    Source source = addSource(r'''
library L;
export 'lib1.dart';
export 'lib2.dart';''');
    addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
class M {}''');
    addNamedSource(
        "/lib2.dart",
        r'''
library lib2;
class N {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_ambiguousExport_combinators_hide() {
    Source source = addSource(r'''
library L;
export 'lib1.dart';
export 'lib2.dart' hide B;''');
    addNamedSource(
        "/lib1.dart",
        r'''
library L1;
class A {}
class B {}''');
    addNamedSource(
        "/lib2.dart",
        r'''
library L2;
class B {}
class C {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_ambiguousExport_combinators_show() {
    Source source = addSource(r'''
library L;
export 'lib1.dart';
export 'lib2.dart' show C;''');
    addNamedSource(
        "/lib1.dart",
        r'''
library L1;
class A {}
class B {}''');
    addNamedSource(
        "/lib2.dart",
        r'''
library L2;
class B {}
class C {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_ambiguousExport_sameDeclaration() {
    Source source = addSource(r'''
library L;
export 'lib.dart';
export 'lib.dart';''');
    addNamedSource(
        "/lib.dart",
        r'''
library lib;
class N {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_ambiguousImport_hideCombinator() {
    Source source = addSource(r'''
import 'lib1.dart';
import 'lib2.dart';
import 'lib3.dart' hide N;
main() {
  new N1();
  new N2();
  new N3();
}''');
    addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
class N {}
class N1 {}''');
    addNamedSource(
        "/lib2.dart",
        r'''
library lib2;
class N {}
class N2 {}''');
    addNamedSource(
        "/lib3.dart",
        r'''
library lib3;
class N {}
class N3 {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_ambiguousImport_showCombinator() {
    Source source = addSource(r'''
import 'lib1.dart';
import 'lib2.dart' show N, N2;
main() {
  new N1();
  new N2();
}''');
    addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
class N {}
class N1 {}''');
    addNamedSource(
        "/lib2.dart",
        r'''
library lib2;
class N {}
class N2 {}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNUSED_SHOWN_NAME]);
  }

  void test_annotated_partOfDeclaration() {
    Source source = addSource('library L; part "part.dart";');
    addNamedSource('/part.dart', '@deprecated part of L;');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_classWithCall_Function() {
    Source source = addSource(r'''
  caller(Function callee) {
    callee();
  }

  class CallMeBack {
    call() => 0;
  }

  main() {
    caller(new CallMeBack());
  }''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_fieldFormalParameterElement_member() {
    Source source = addSource(r'''
class ObjectSink<T> {
  void sink(T object) {
    new TimestampedObject<T>(object);
  }
}
class TimestampedObject<E> {
  E object2;
  TimestampedObject(this.object2);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_invocation_functionParameter_generic() {
    Source source = addSource(r'''
class A<K> {
  m(f(K k), K v) {
    f(v);
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_invocation_typedef_generic() {
    Source source = addSource(r'''
typedef A<T>(T p);
f(A<int> a) {
  a(1);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_Object_Function() {
    Source source = addSource(r'''
main() {
  process(() {});
}
process(Object x) {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_typedef_local() {
    Source source = addSource(r'''
typedef A(int p1, String p2);
A getA() => null;
f() {
  A a = getA();
  a(1, '2');
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_typedef_parameter() {
    Source source = addSource(r'''
typedef A(int p1, String p2);
f(A a) {
  a(1, '2');
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_assert_with_message_await() {
    resetWithOptions(new AnalysisOptionsImpl()..enableAssertMessage = true);
    Source source = addSource('''
import 'dart:async';
f() async {
  assert(false, await g());
}
Future<String> g() => null;
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_assert_with_message_dynamic() {
    resetWithOptions(new AnalysisOptionsImpl()..enableAssertMessage = true);
    Source source = addSource('''
f() {
  assert(false, g());
}
g() => null;
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_assert_with_message_non_string() {
    resetWithOptions(new AnalysisOptionsImpl()..enableAssertMessage = true);
    Source source = addSource('''
f() {
  assert(false, 3);
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_assert_with_message_null() {
    resetWithOptions(new AnalysisOptionsImpl()..enableAssertMessage = true);
    Source source = addSource('''
f() {
  assert(false, null);
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_assert_with_message_string() {
    resetWithOptions(new AnalysisOptionsImpl()..enableAssertMessage = true);
    Source source = addSource('''
f() {
  assert(false, 'message');
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_assert_with_message_suppresses_unused_var_hint() {
    resetWithOptions(new AnalysisOptionsImpl()..enableAssertMessage = true);
    Source source = addSource('''
f() {
  String message = 'msg';
  assert(true, message);
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_assignability_function_expr_rettype_from_typedef_cls() {
    // In the code below, the type of (() => f()) has a return type which is
    // a class, and that class is inferred from the return type of the typedef
    // F.
    Source source = addSource('''
class C {}
typedef C F();
F f;
main() {
  F f2 = (() => f());
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_assignability_function_expr_rettype_from_typedef_typedef() {
    // In the code below, the type of (() => f()) has a return type which is
    // a typedef, and that typedef is inferred from the return type of the
    // typedef F.
    Source source = addSource('''
typedef G F();
typedef G();
F f;
main() {
  F f2 = (() => f());
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_assignmentToFinal_prefixNegate() {
    Source source = addSource(r'''
f() {
  final x = 0;
  -x;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_assignmentToFinalNoSetter_prefixedIdentifier() {
    Source source = addSource(r'''
class A {
  int get x => 0;
  set x(v) {}
}
main() {
  A a = new A();
  a.x = 0;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_assignmentToFinalNoSetter_propertyAccess() {
    Source source = addSource(r'''
class A {
  int get x => 0;
  set x(v) {}
}
class B {
  static A a;
}
main() {
  B.a.x = 0;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_assignmentToFinals_importWithPrefix() {
    Source source = addSource(r'''
library lib;
import 'lib1.dart' as foo;
main() {
  foo.x = true;
}''');
    addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
bool x = false;''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_async_dynamic_with_return() {
    Source source = addSource('''
dynamic f() async {
  return;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_async_dynamic_with_return_value() {
    Source source = addSource('''
dynamic f() async {
  return 5;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_async_dynamic_without_return() {
    Source source = addSource('''
dynamic f() async {}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_async_expression_function_type() {
    Source source = addSource('''
import 'dart:async';
typedef Future<int> F(int i);
main() {
  F f = (int i) async => i;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_async_flattened() {
    Source source = addSource('''
import 'dart:async';
typedef Future<int> CreatesFutureInt();
main() {
  CreatesFutureInt createFutureInt = () async => f();
  Future<int> futureInt = createFutureInt();
  futureInt.then((int i) => print(i));
}
Future<int> f() => null;
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_async_future_dynamic_with_return() {
    Source source = addSource('''
import 'dart:async';
Future<dynamic> f() async {
  return;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_async_future_dynamic_with_return_value() {
    Source source = addSource('''
import 'dart:async';
Future<dynamic> f() async {
  return 5;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_async_future_dynamic_without_return() {
    Source source = addSource('''
import 'dart:async';
Future<dynamic> f() async {}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_async_future_int_with_return_future_int() {
    Source source = addSource('''
import 'dart:async';
Future<int> f() async {
  return new Future<int>.value(5);
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_async_future_int_with_return_value() {
    Source source = addSource('''
import 'dart:async';
Future<int> f() async {
  return 5;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_async_future_null_with_return() {
    Source source = addSource('''
import 'dart:async';
Future<Null> f() async {
  return;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_async_future_null_without_return() {
    Source source = addSource('''
import 'dart:async';
Future<Null> f() async {}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_async_future_object_with_return() {
    Source source = addSource('''
import 'dart:async';
Future<Object> f() async {
  return;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_async_future_object_with_return_value() {
    Source source = addSource('''
import 'dart:async';
Future<Object> f() async {
  return 5;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_async_future_object_without_return() {
    Source source = addSource('''
import 'dart:async';
Future<Object> f() async {}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_async_future_with_return() {
    Source source = addSource('''
import 'dart:async';
Future f() async {
  return;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_async_future_with_return_value() {
    Source source = addSource('''
import 'dart:async';
Future f() async {
  return 5;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_async_future_without_return() {
    Source source = addSource('''
import 'dart:async';
Future f() async {}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_async_return_flattens_futures() {
    Source source = addSource('''
import 'dart:async';
Future<int> f() async {
  return g();
}
Future<Future<int>> g() => null;
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_async_with_return() {
    Source source = addSource('''
f() async {
  return;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_async_with_return_value() {
    Source source = addSource('''
f() async {
  return 5;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_async_without_return() {
    Source source = addSource('''
f() async {}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_asyncForInWrongContext_async() {
    Source source = addSource(r'''
f(list) async {
  await for (var e in list) {
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_asyncForInWrongContext_asyncStar() {
    Source source = addSource(r'''
f(list) async* {
  await for (var e in list) {
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_await_flattened() {
    Source source = addSource('''
import 'dart:async';
Future<Future<int>> ffi() => null;
f() async {
  int b = await ffi();
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_await_simple() {
    Source source = addSource('''
import 'dart:async';
Future<int> fi() => null;
f() async {
  int a = await fi();
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_awaitInWrongContext_async() {
    Source source = addSource(r'''
f(x, y) async {
  return await x + await y;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_awaitInWrongContext_asyncStar() {
    Source source = addSource(r'''
f(x, y) async* {
  yield await x + await y;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_breakWithoutLabelInSwitch() {
    Source source = addSource(r'''
class A {
  void m(int i) {
    switch (i) {
      case 0:
        break;
    }
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_bug_24539_getter() {
    Source source = addSource('''
class C<T> {
  List<Foo> get x => null;
}

typedef Foo(param);
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_bug_24539_setter() {
    Source source = addSource('''
class C<T> {
  void set x(List<Foo> value) {}
}

typedef Foo(param);
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_builtInIdentifierAsType_dynamic() {
    Source source = addSource(r'''
f() {
  dynamic x;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_caseBlockNotTerminated() {
    Source source = addSource(r'''
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
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_caseBlockNotTerminated_lastCase() {
    Source source = addSource(r'''
f(int p) {
  switch (p) {
    case 0:
      p = p + 1;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_caseExpressionTypeImplementsEquals() {
    Source source = addSource(r'''
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
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_caseExpressionTypeImplementsEquals_int() {
    Source source = addSource(r'''
f(int i) {
  switch(i) {
    case(1) : return 1;
    default: return 0;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_caseExpressionTypeImplementsEquals_Object() {
    Source source = addSource(r'''
class IntWrapper {
  final int value;
  const IntWrapper(this.value);
}

f(IntWrapper intWrapper) {
  switch(intWrapper) {
    case(const IntWrapper(1)) : return 1;
    default: return 0;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_caseExpressionTypeImplementsEquals_String() {
    Source source = addSource(r'''
f(String s) {
  switch(s) {
    case('1') : return 1;
    default: return 0;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_class_type_alias_documentationComment() {
    Source source = addSource('''
/**
 * Documentation
 */
class C = D with E;

class D {}
class E {}''');
    computeLibrarySourceErrors(source);
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = _getResolvedLibraryUnit(source);
    ClassElement classC = unit.element.getType('C');
    expect(classC.documentationComment, isNotNull);
  }

  void test_commentReference_beforeConstructor() {
    String code = r'''
abstract class A {
  /// [p]
  A(int p) {}
}''';
    Source source = addSource(code);
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = _getResolvedLibraryUnit(source);
    {
      SimpleIdentifier ref =
          EngineTestCase.findSimpleIdentifier(unit, code, "p]");
      expect(ref.staticElement, new isInstanceOf<ParameterElement>());
    }
  }

  void test_commentReference_beforeEnum() {
    String code = r'''
/// This is the [Samurai] kind.
enum Samurai {
  /// Use [int].
  WITH_SWORD,
  /// Like [WITH_SWORD], but only without one.
  WITHOUT_SWORD
}''';
    Source source = addSource(code);
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = _getResolvedLibraryUnit(source);
    {
      SimpleIdentifier ref =
          EngineTestCase.findSimpleIdentifier(unit, code, 'Samurai]');
      ClassElement refElement = ref.staticElement;
      expect(refElement, isNotNull);
      expect(refElement.name, 'Samurai');
    }
    {
      SimpleIdentifier ref =
          EngineTestCase.findSimpleIdentifier(unit, code, 'int]');
      ClassElement refElement = ref.staticElement;
      expect(refElement, isNotNull);
      expect(refElement.name, 'int');
    }
    {
      SimpleIdentifier ref =
          EngineTestCase.findSimpleIdentifier(unit, code, 'WITH_SWORD]');
      PropertyAccessorElement refElement = ref.staticElement;
      expect(refElement, isNotNull);
      expect(refElement.name, 'WITH_SWORD');
    }
  }

  void test_commentReference_beforeFunction_blockBody() {
    String code = r'''
/// [p]
foo(int p) {
}''';
    Source source = addSource(code);
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = _getResolvedLibraryUnit(source);
    SimpleIdentifier ref =
        EngineTestCase.findSimpleIdentifier(unit, code, 'p]');
    expect(ref.staticElement, new isInstanceOf<ParameterElement>());
  }

  void test_commentReference_beforeFunction_expressionBody() {
    String code = r'''
/// [p]
foo(int p) => null;''';
    Source source = addSource(code);
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = _getResolvedLibraryUnit(source);
    SimpleIdentifier ref =
        EngineTestCase.findSimpleIdentifier(unit, code, 'p]');
    expect(ref.staticElement, new isInstanceOf<ParameterElement>());
  }

  void test_commentReference_beforeFunctionTypeAlias() {
    String code = r'''
/// [p]
typedef Foo(int p);
''';
    Source source = addSource(code);
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = _getResolvedLibraryUnit(source);
    SimpleIdentifier ref =
        EngineTestCase.findSimpleIdentifier(unit, code, 'p]');
    expect(ref.staticElement, new isInstanceOf<ParameterElement>());
  }

  void test_commentReference_beforeGetter() {
    String code = r'''
abstract class A {
  /// [int]
  get g => null;
}''';
    Source source = addSource(code);
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = _getResolvedLibraryUnit(source);
    {
      SimpleIdentifier ref =
          EngineTestCase.findSimpleIdentifier(unit, code, 'int]');
      expect(ref.staticElement, isNotNull);
    }
  }

  void test_commentReference_beforeMethod() {
    String code = r'''
abstract class A {
  /// [p1]
  ma(int p1) {}
  /// [p2]
  mb(int p2);
  /// [p3] and [p4]
  mc(int p3, p4());
  /// [p5]
  md(int p5, {int p6});
}''';
    Source source = addSource(code);
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = _getResolvedLibraryUnit(source);
    assertIsParameter(String search) {
      SimpleIdentifier ref =
          EngineTestCase.findSimpleIdentifier(unit, code, search);
      expect(ref.staticElement, new isInstanceOf<ParameterElement>());
    }

    assertIsParameter('p1');
    assertIsParameter('p2');
    assertIsParameter('p3');
    assertIsParameter('p4');
    assertIsParameter('p5');
    assertIsParameter('p6');
  }

  void test_commentReference_class() {
    String code = r'''
/// [foo]
class A {
  foo() {}
}''';
    Source source = addSource(code);
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = _getResolvedLibraryUnit(source);
    SimpleIdentifier ref =
        EngineTestCase.findSimpleIdentifier(unit, code, 'foo]');
    expect(ref.staticElement, new isInstanceOf<MethodElement>());
  }

  void test_commentReference_setter() {
    String code = r'''
class A {
  /// [x] in A
  mA() {}
  set x(value) {}
}
class B extends A {
  /// [x] in B
  mB() {}
}
''';
    Source source = addSource(code);
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = _getResolvedLibraryUnit(source);
    {
      SimpleIdentifier ref =
          EngineTestCase.findSimpleIdentifier(unit, code, "x] in A");
      expect(ref.staticElement, new isInstanceOf<PropertyAccessorElement>());
    }
    {
      SimpleIdentifier ref =
          EngineTestCase.findSimpleIdentifier(unit, code, 'x] in B');
      expect(ref.staticElement, new isInstanceOf<PropertyAccessorElement>());
    }
  }

  void test_concreteClassWithAbstractMember() {
    Source source = addSource(r'''
abstract class A {
  m();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_concreteClassWithAbstractMember_inherited() {
    Source source = addSource(r'''
class A {
  m() {}
}
class B extends A {
  m();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_conflictingInstanceGetterAndSuperclassMember_instance() {
    Source source = addSource(r'''
class A {
  get v => 0;
}
class B extends A {
  get v => 1;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_conflictingStaticGetterAndInstanceSetter_thisClass() {
    Source source = addSource(r'''
class A {
  static get x => 0;
  static set x(int p) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_conflictingStaticSetterAndInstanceMember_thisClass_method() {
    Source source = addSource(r'''
class A {
  static x() {}
  static set x(int p) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_const_constructor_with_named_generic_parameter() {
    Source source = addSource('''
class C<T> {
  const C({T t});
}
const c = const C(t: 1);
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_const_dynamic() {
    Source source = addSource('''
const Type d = dynamic;
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_constConstructorWithNonConstSuper_explicit() {
    Source source = addSource(r'''
class A {
  const A();
}
class B extends A {
  const B(): super();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_constConstructorWithNonConstSuper_redirectingFactory() {
    Source source = addSource(r'''
class A {
  A();
}
class B implements C {
  const B();
}
class C extends A {
  const factory C() = B;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_constConstructorWithNonConstSuper_unresolved() {
    Source source = addSource(r'''
class A {
  A.a();
}
class B extends A {
  const B(): super();
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source,
        [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT]);
    verify([source]);
  }

  void test_constConstructorWithNonFinalField_finalInstanceVar() {
    Source source = addSource(r'''
class A {
  final int x = 0;
  const A();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_constConstructorWithNonFinalField_mixin() {
    Source source = addSource(r'''
class A {
  a() {}
}
class B extends Object with A {
  const B();
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN]);
    verify([source]);
  }

  void test_constConstructorWithNonFinalField_static() {
    Source source = addSource(r'''
class A {
  static int x;
  const A();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_constConstructorWithNonFinalField_syntheticField() {
    Source source = addSource(r'''
class A {
  const A();
  set x(value) {}
  get x {return 0;}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_constDeferredClass_new() {
    resolveWithErrors(<String>[
      r'''
library lib1;
class A {
  const A.b();
}''',
      r'''
library root;
import 'lib1.dart' deferred as a;
main() {
  new a.A.b();
}'''
    ], <ErrorCode>[]);
  }

  void test_constEval_functionTypeLiteral() {
    Source source = addSource(r'''
typedef F();
const C = F;''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_constEval_propertyExtraction_fieldStatic_targetType() {
    addNamedSource(
        "/math.dart",
        r'''
library math;
const PI = 3.14;''');
    Source source = addSource(r'''
import 'math.dart' as math;
const C = math.PI;''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_constEval_propertyExtraction_methodStatic_targetType() {
    Source source = addSource(r'''
class A {
  const A();
  static m() {}
}
const C = A.m;''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_constEval_symbol() {
    addNamedSource(
        "/math.dart",
        r'''
library math;
const PI = 3.14;''');
    Source source = addSource(r'''
const C = #foo;
foo() {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_constEvalTypeBoolNumString_equal() {
    Source source = addSource(r'''
class A {
  const A();
}
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
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_constEvalTypeBoolNumString_notEqual() {
    Source source = addSource(r'''
class A {
  const A();
}
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
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_constEvelTypeNum_String() {
    Source source = addSource(r'''
const String A = 'a';
const String B = A + 'b';
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_constMapKeyExpressionTypeImplementsEquals_abstract() {
    Source source = addSource(r'''
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

Map getMap() {
  return const { const C(0): 'Map: 0' };
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_constNotInitialized_field() {
    Source source = addSource(r'''
class A {
  static const int x = 0;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_constNotInitialized_local() {
    Source source = addSource(r'''
main() {
  const int x = 0;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_constRedirectSkipsSupertype() {
    // Since C redirects to C.named, it doesn't implicitly refer to B's
    // unnamed constructor.  Therefore there is no cycle.
    Source source = addSource('''
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_constructorDeclaration_scope_signature() {
    Source source = addSource(r'''
const app = 0;
class A {
  A(@app int app) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_constWithNonConstantArgument_constField() {
    Source source = addSource(r'''
class A {
  const A(x);
}
main() {
  const A(double.INFINITY);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_constWithNonConstantArgument_literals() {
    Source source = addSource(r'''
class A {
  const A(a, b, c, d);
}
f() { return const A(true, 0, 1.0, '2'); }''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_constWithTypeParameters_direct() {
    Source source = addSource(r'''
class A<T> {
  static const V = const A<int>();
  const A();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_constWithUndefinedConstructor() {
    Source source = addSource(r'''
class A {
  const A.name();
}
f() {
  return const A.name();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_constWithUndefinedConstructorDefault() {
    Source source = addSource(r'''
class A {
  const A();
}
f() {
  return const A();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_defaultValueInFunctionTypeAlias() {
    Source source = addSource("typedef F([x]);");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_defaultValueInFunctionTypedParameter_named() {
    Source source = addSource("f(g({p})) {}");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_defaultValueInFunctionTypedParameter_optional() {
    Source source = addSource("f(g([p])) {}");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deprecatedMemberUse_hide() {
    Source source = addSource(r'''
library lib;
import 'lib1.dart' hide B;
A a = new A();''');
    addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
class A {}
@deprecated
class B {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_duplicateDefinition_emptyName() {
    // Note: This code has two FunctionElements '() {}' with an empty name,
    // this tests that the empty string is not put into the scope
    // (more than once).
    Source source = addSource(r'''
Map _globalMap = {
  'a' : () {},
  'b' : () {}
};''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_duplicateDefinition_getter() {
    Source source = addSource("bool get a => true;");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_duplicatePart() {
    addNamedSource('/part1.dart', 'part of lib;');
    addNamedSource('/part2.dart', 'part of lib;');
    Source source = addSource(r'''
library lib;
part 'part1.dart';
part 'part2.dart';
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_dynamicIdentifier() {
    Source source = addSource(r'''
main() {
  var v = dynamic;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_empty_generator_async() {
    Source source = addSource('''
import 'dart:async';
Stream<int> f() async* {
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_empty_generator_sync() {
    Source source = addSource('''
Iterable<int> f() sync* {
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_expectedOneListTypeArgument() {
    Source source = addSource(r'''
main() {
  <int> [];
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_expectedTwoMapTypeArguments() {
    Source source = addSource(r'''
main() {
  <int, int> {};
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_exportDuplicatedLibraryUnnamed() {
    Source source = addSource(r'''
library test;
export 'lib1.dart';
export 'lib2.dart';''');
    addNamedSource("/lib1.dart", "");
    addNamedSource("/lib2.dart", "");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_exportOfNonLibrary_libraryDeclared() {
    Source source = addSource(r'''
library L;
export 'lib1.dart';''');
    addNamedSource("/lib1.dart", "library lib1;");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_exportOfNonLibrary_libraryNotDeclared() {
    Source source = addSource(r'''
library L;
export 'lib1.dart';''');
    addNamedSource("/lib1.dart", "");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_extraPositionalArguments_function() {
    Source source = addSource(r'''
f(p1, p2) {}
main() {
  f(1, 2);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_extraPositionalArguments_Function() {
    Source source = addSource(r'''
f(Function a) {
  a(1, 2);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_extraPositionalArguments_implicitConstructor() {
    Source source = addSource(r'''
class A<E extends num> {
  A(E x, E y);
}
class M {}
class B<E extends num> = A<E> with M;
void main() {
   B<int> x = new B<int>(0,0);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_extraPositionalArguments_typedef_local() {
    Source source = addSource(r'''
typedef A(p1, p2);
A getA() => null;
f() {
  A a = getA();
  a(1, 2);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_extraPositionalArguments_typedef_parameter() {
    Source source = addSource(r'''
typedef A(p1, p2);
f(A a) {
  a(1, 2);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldInitializedByMultipleInitializers() {
    Source source = addSource(r'''
class A {
  int x;
  int y;
  A() : x = 0, y = 0 {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldInitializedInInitializerAndDeclaration_fieldNotFinal() {
    Source source = addSource(r'''
class A {
  int x = 0;
  A() : x = 1 {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldInitializedInInitializerAndDeclaration_finalFieldNotSet() {
    Source source = addSource(r'''
class A {
  final int x;
  A() : x = 1 {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldInitializerOutsideConstructor() {
    Source source = addSource(r'''
class A {
  int x;
  A(this.x) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldInitializerOutsideConstructor_defaultParameters() {
    Source source = addSource(r'''
class A {
  int x;
  A([this.x]) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldInitializerRedirectingConstructor_super() {
    Source source = addSource(r'''
class A {
  A() {}
}
class B extends A {
  int x;
  B(this.x) : super();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_finalInitializedInDeclarationAndConstructor_initializer() {
    Source source = addSource(r'''
class A {
  final x;
  A() : x = 1 {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_finalInitializedInDeclarationAndConstructor_initializingFormal() {
    Source source = addSource(r'''
class A {
  final x;
  A(this.x) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_finalNotInitialized_atDeclaration() {
    Source source = addSource(r'''
class A {
  final int x = 0;
  A() {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_finalNotInitialized_fieldFormal() {
    Source source = addSource(r'''
class A {
  final int x = 0;
  A() {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_finalNotInitialized_functionTypedFieldFormal() {
    Source source = addSource(r'''
class A {
  final Function x;
  A(int this.x(int p)) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_finalNotInitialized_hasNativeClause_hasConstructor() {
    Source source = addSource(r'''
class A native 'something' {
  final int x;
  A() {}
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [ParserErrorCode.NATIVE_CLAUSE_IN_NON_SDK_CODE]);
    verify([source]);
  }

  void test_finalNotInitialized_hasNativeClause_noConstructor() {
    Source source = addSource(r'''
class A native 'something' {
  final int x;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [ParserErrorCode.NATIVE_CLAUSE_IN_NON_SDK_CODE]);
    verify([source]);
  }

  void test_finalNotInitialized_initializer() {
    Source source = addSource(r'''
class A {
  final int x;
  A() : x = 0 {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_finalNotInitialized_redirectingConstructor() {
    Source source = addSource(r'''
class A {
  final int x;
  A(this.x);
  A.named() : this (42);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_functionDeclaration_scope_returnType() {
    Source source = addSource("int f(int) { return 0; }");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_functionDeclaration_scope_signature() {
    Source source = addSource(r'''
const app = 0;
f(@app int app) {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_functionTypeAlias_scope_returnType() {
    Source source = addSource("typedef int f(int);");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_functionTypeAlias_scope_signature() {
    Source source = addSource(r'''
const app = 0;
typedef int f(@app int app);''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_functionWithoutCall() {
    Source source = addSource(r'''
abstract class A implements Function {
}
class B implements A {
  void call() {}
}
class C extends A {
  void call() {}
}
class D extends C {
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_functionWithoutCall_doesNotImplementFunction() {
    Source source = addSource("class A {}");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_functionWithoutCall_staticCallMethod() {
    Source source = addSource(r'''
class A { }
class B extends A {
  static call() { }
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_functionWithoutCall_withNoSuchMethod() {
    // 16078
    Source source = addSource(r'''
class A implements Function {
  noSuchMethod(inv) {
    return 42;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_functionWithoutCall_withNoSuchMethod_mixin() {
    Source source = addSource(r'''
class A {
  noSuchMethod(inv) {}
}
class B extends Object with A implements Function {
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_functionWithoutCall_withNoSuchMethod_superclass() {
    Source source = addSource(r'''
class A {
  noSuchMethod(inv) {}
}
class B extends A implements Function {
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_implicitConstructorDependencies() {
    // No warning should be generated for the code below; this requires that
    // implicit constructors are generated for C1 before C2, even though C1
    // follows C2 in the file.  See dartbug.com/21600.
    Source source = addSource(r'''
class B {
  B(int i);
}
class M1 {}
class M2 {}

class C2 = C1 with M2;
class C1 = B with M1;

main() {
  new C2(5);
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_implicitThisReferenceInInitializer_constructorName() {
    Source source = addSource(r'''
class A {
  A.named() {}
}
class B {
  var v;
  B() : v = new A.named();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_implicitThisReferenceInInitializer_importPrefix() {
    Source source = addSource(r'''
import 'dart:async' as abstract;
class A {
  var v = new abstract.Completer();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_implicitThisReferenceInInitializer_prefixedIdentifier() {
    Source source = addSource(r'''
class A {
  var f;
}
class B {
  var v;
  B(A a) : v = a.f;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_implicitThisReferenceInInitializer_qualifiedMethodInvocation() {
    Source source = addSource(r'''
class A {
  f() {}
}
class B {
  var v;
  B() : v = new A().f();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_implicitThisReferenceInInitializer_qualifiedPropertyAccess() {
    Source source = addSource(r'''
class A {
  var f;
}
class B {
  var v;
  B() : v = new A().f;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_implicitThisReferenceInInitializer_staticField_thisClass() {
    Source source = addSource(r'''
class A {
  var v;
  A() : v = f;
  static var f;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_implicitThisReferenceInInitializer_staticGetter() {
    Source source = addSource(r'''
class A {
  var v;
  A() : v = f;
  static get f => 42;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_implicitThisReferenceInInitializer_staticMethod() {
    Source source = addSource(r'''
class A {
  var v;
  A() : v = f();
  static f() => 42;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_implicitThisReferenceInInitializer_topLevelField() {
    Source source = addSource(r'''
class A {
  var v;
  A() : v = f;
}
var f = 42;''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_implicitThisReferenceInInitializer_topLevelFunction() {
    Source source = addSource(r'''
class A {
  var v;
  A() : v = f();
}
f() => 42;''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_implicitThisReferenceInInitializer_topLevelGetter() {
    Source source = addSource(r'''
class A {
  var v;
  A() : v = f;
}
get f => 42;''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_implicitThisReferenceInInitializer_typeParameter() {
    Source source = addSource(r'''
class A<T> {
  var v;
  A(p) : v = (p is T);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_importDuplicatedLibraryName() {
    Source source = addSource(r'''
library test;
import 'lib.dart';
import 'lib.dart';''');
    addNamedSource("/lib.dart", "library lib;");
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      HintCode.UNUSED_IMPORT,
      HintCode.UNUSED_IMPORT,
      HintCode.DUPLICATE_IMPORT
    ]);
    verify([source]);
  }

  void test_importDuplicatedLibraryUnnamed() {
    Source source = addSource(r'''
library test;
import 'lib1.dart';
import 'lib2.dart';''');
    addNamedSource("/lib1.dart", "");
    addNamedSource("/lib2.dart", "");
    computeLibrarySourceErrors(source);
    assertErrors(source, [
      // No warning on duplicate import (https://github.com/dart-lang/sdk/issues/24156)
      HintCode.UNUSED_IMPORT,
      HintCode.UNUSED_IMPORT
    ]);
    verify([source]);
  }

  void test_importOfNonLibrary_libraryDeclared() {
    Source source = addSource(r'''
library lib;
import 'part.dart';
A a;''');
    addNamedSource(
        "/part.dart",
        r'''
library lib1;
class A {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_importOfNonLibrary_libraryNotDeclared() {
    Source source = addSource(r'''
library lib;
import 'part.dart';
A a;''');
    addNamedSource("/part.dart", "class A {}");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_importPrefixes_withFirstLetterDifference() {
    Source source = addSource(r'''
library L;
import 'lib1.dart' as math;
import 'lib2.dart' as path;
main() {
  math.test1();
  path.test2();
}''');
    addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
test1() {}''');
    addNamedSource(
        "/lib2.dart",
        r'''
library lib2;
test2() {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_inconsistentCaseExpressionTypes() {
    Source source = addSource(r'''
f(var p) {
  switch (p) {
    case 1:
      break;
    case 2:
      break;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_inconsistentMethodInheritance_accessors_typeParameter2() {
    Source source = addSource(r'''
abstract class A<E> {
  E get x {return null;}
}
class B<E> {
  E get x {return null;}
}
class C<E> extends A<E> implements B<E> {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_inconsistentMethodInheritance_accessors_typeParameters1() {
    Source source = addSource(r'''
abstract class A<E> {
  E get x;
}
abstract class B<E> {
  E get x;
}
class C<E> implements A<E>, B<E> {
  E get x => null;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_inconsistentMethodInheritance_accessors_typeParameters_diamond() {
    Source source = addSource(r'''
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
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_inconsistentMethodInheritance_methods_typeParameter2() {
    Source source = addSource(r'''
class A<E> {
  x(E e) {}
}
class B<E> {
  x(E e) {}
}
class C<E> extends A<E> implements B<E> {
  x(E e) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_inconsistentMethodInheritance_methods_typeParameters1() {
    Source source = addSource(r'''
class A<E> {
  x(E e) {}
}
class B<E> {
  x(E e) {}
}
class C<E> implements A<E>, B<E> {
  x(E e) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_inconsistentMethodInheritance_overrideTrumpsInherits_getter() {
    // 16134
    Source source = addSource(r'''
class B<S> {
  S get g => null;
}
abstract class I<U> {
  U get g => null;
}
class C extends B<double> implements I<int> {
  num get g => null;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_inconsistentMethodInheritance_overrideTrumpsInherits_method() {
    // 16134
    Source source = addSource(r'''
class B<S> {
  m(S s) => null;
}
abstract class I<U> {
  m(U u) => null;
}
class C extends B<double> implements I<int> {
  m(num n) => null;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_inconsistentMethodInheritance_overrideTrumpsInherits_setter() {
    // 16134
    Source source = addSource(r'''
class B<S> {
  set t(S s) {}
}
abstract class I<U> {
  set t(U u) {}
}
class C extends B<double> implements I<int> {
  set t(num n) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_inconsistentMethodInheritance_simple() {
    Source source = addSource(r'''
abstract class A {
  x();
}
abstract class B {
  x();
}
class C implements A, B {
  x() {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_initializingFormalForNonExistentField() {
    Source source = addSource(r'''
class A {
  int x;
  A(this.x) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_instance_creation_inside_annotation() {
    Source source = addSource('''
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
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_instanceAccessToStaticMember_fromComment() {
    Source source = addSource(r'''
class A {
  static m() {}
}
/// [A.m]
main() {
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_instanceAccessToStaticMember_topLevel() {
    Source source = addSource(r'''
m() {}
main() {
  m();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_instanceMemberAccessFromStatic_fromComment() {
    Source source = addSource(r'''
class A {
  m() {}
  /// [m]
  static foo() {
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_instanceMethodNameCollidesWithSuperclassStatic_field() {
    Source source = addSource(r'''
import 'lib.dart';
class B extends A {
  _m() {}
}''');
    addNamedSource(
        "/lib.dart",
        r'''
library L;
class A {
  static var _m;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_instanceMethodNameCollidesWithSuperclassStatic_method() {
    Source source = addSource(r'''
import 'lib.dart';
class B extends A {
  _m() {}
}''');
    addNamedSource(
        "/lib.dart",
        r'''
library L;
class A {
  static _m() {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidAnnotation_constantVariable_field() {
    Source source = addSource(r'''
@A.C
class A {
  static const C = 0;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidAnnotation_constantVariable_field_importWithPrefix() {
    addNamedSource(
        "/lib.dart",
        r'''
library lib;
class A {
  static const C = 0;
}''');
    Source source = addSource(r'''
import 'lib.dart' as p;
@p.A.C
main() {
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidAnnotation_constantVariable_topLevel() {
    Source source = addSource(r'''
const C = 0;
@C
main() {
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidAnnotation_constantVariable_topLevel_importWithPrefix() {
    addNamedSource(
        "/lib.dart",
        r'''
library lib;
const C = 0;''');
    Source source = addSource(r'''
import 'lib.dart' as p;
@p.C
main() {
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidAnnotation_constConstructor_importWithPrefix() {
    addNamedSource(
        "/lib.dart",
        r'''
library lib;
class A {
  const A(int p);
}''');
    Source source = addSource(r'''
import 'lib.dart' as p;
@p.A(42)
main() {
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidAnnotation_constConstructor_named_importWithPrefix() {
    addNamedSource(
        "/lib.dart",
        r'''
library lib;
class A {
  const A.named(int p);
}''');
    Source source = addSource(r'''
import 'lib.dart' as p;
@p.A.named(42)
main() {
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidAssignment() {
    Source source = addSource(r'''
f() {
  var x;
  var y;
  x = y;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidAssignment_compoundAssignment() {
    Source source = addSource(r'''
class byte {
  int _value;
  byte(this._value);
  byte operator +(int val) { return this; }
}

void main() {
  byte b = new byte(52);
  b += 3;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidAssignment_defaultValue_named() {
    Source source = addSource(r'''
f({String x: '0'}) {
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidAssignment_defaultValue_optional() {
    Source source = addSource(r'''
f([String x = '0']) {
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidAssignment_ifNullAssignment_compatibleType() {
    Source source = addSource('''
void f(int i) {
  num n;
  n ??= i;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidAssignment_ifNullAssignment_sameType() {
    Source source = addSource('''
void f(int i) {
  int j;
  j ??= i;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidAssignment_implicitlyImplementFunctionViaCall_1() {
    // 18341
    //
    // This test and
    // 'test_invalidAssignment_implicitlyImplementFunctionViaCall_2()'
    // are closely related: here we see that 'I' checks as a subtype of
    // 'IntToInt'.
    Source source = addSource(r'''
class I {
  int call(int x) => 0;
}
class C implements I {
  noSuchMethod(_) => null;
}
typedef int IntToInt(int x);
IntToInt f = new I();''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidAssignment_implicitlyImplementFunctionViaCall_2() {
    // 18341
    //
    // Here 'C' checks as a subtype of 'I', but 'C' does not
    // check as a subtype of 'IntToInt'. Together with
    // 'test_invalidAssignment_implicitlyImplementFunctionViaCall_1()' we see
    // that subtyping is not transitive here.
    Source source = addSource(r'''
class I {
  int call(int x) => 0;
}
class C implements I {
  noSuchMethod(_) => null;
}
typedef int IntToInt(int x);
IntToInt f = new C();''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidAssignment_implicitlyImplementFunctionViaCall_3() {
    // 18341
    //
    // Like 'test_invalidAssignment_implicitlyImplementFunctionViaCall_2()',
    // but uses type 'Function' instead of more precise type 'IntToInt' for 'f'.
    Source source = addSource(r'''
class I {
  int call(int x) => 0;
}
class C implements I {
  noSuchMethod(_) => null;
}
typedef int IntToInt(int x);
Function f = new C();''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidAssignment_implicitlyImplementFunctionViaCall_4() {
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
    Source source = addSource(r'''
class I {
  int call([int x]) => 0;
}
class C implements I {
  noSuchMethod(_) => null;
}
typedef int VoidToInt();
VoidToInt f = new C();''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidAssignment_toDynamic() {
    Source source = addSource(r'''
f() {
  var g;
  g = () => 0;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidFactoryNameNotAClass() {
    Source source = addSource(r'''
class A {
  factory A() => null;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidIdentifierInAsync() {
    Source source = addSource(r'''
class A {
  m() {
    int async;
    int await;
    int yield;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidMethodOverrideNamedParamType() {
    Source source = addSource(r'''
class A {
  m({int a}) {}
}
class B implements A {
  m({int a, int b}) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidOverrideDifferentDefaultValues_named() {
    Source source = addSource(r'''
class A {
  m({int p : 0}) {}
}
class B extends A {
  m({int p : 0}) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidOverrideDifferentDefaultValues_named_function() {
    Source source = addSource(r'''
nothing() => 'nothing';
class A {
  thing(String a, {orElse : nothing}) {}
}
class B extends A {
  thing(String a, {orElse : nothing}) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidOverrideDifferentDefaultValues_positional() {
    Source source = addSource(r'''
class A {
  m([int p = 0]) {}
}
class B extends A {
  m([int p = 0]) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidOverrideDifferentDefaultValues_positional_changedOrder() {
    Source source = addSource(r'''
class A {
  m([int a = 0, String b = '0']) {}
}
class B extends A {
  m([int b = 0, String a = '0']) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidOverrideDifferentDefaultValues_positional_function() {
    Source source = addSource(r'''
nothing() => 'nothing';
class A {
  thing(String a, [orElse = nothing]) {}
}
class B extends A {
  thing(String a, [orElse = nothing]) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidOverrideNamed_unorderedNamedParameter() {
    Source source = addSource(r'''
class A {
  m({a, b}) {}
}
class B extends A {
  m({b, a}) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidOverrideRequired_less() {
    Source source = addSource(r'''
class A {
  m(a, b) {}
}
class B extends A {
  m(a, [b]) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidOverrideRequired_same() {
    Source source = addSource(r'''
class A {
  m(a) {}
}
class B extends A {
  m(a) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidOverrideReturnType_returnType_interface() {
    Source source = addNamedSource(
        "/test.dart",
        r'''
abstract class A {
  num m();
}
class B implements A {
  int m() { return 1; }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidOverrideReturnType_returnType_interface2() {
    Source source = addNamedSource(
        "/test.dart",
        r'''
abstract class A {
  num m();
}
abstract class B implements A {
}
class C implements B {
  int m() { return 1; }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidOverrideReturnType_returnType_mixin() {
    Source source = addNamedSource(
        "/test.dart",
        r'''
class A {
  num m() { return 0; }
}
class B extends Object with A {
  int m() { return 1; }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidOverrideReturnType_returnType_parameterizedTypes() {
    Source source = addSource(r'''
abstract class A<E> {
  List<E> m();
}
class B extends A<dynamic> {
  List<dynamic> m() { return new List<dynamic>(); }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidOverrideReturnType_returnType_sameType() {
    Source source = addNamedSource(
        "/test.dart",
        r'''
class A {
  int m() { return 0; }
}
class B extends A {
  int m() { return 1; }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidOverrideReturnType_returnType_superclass() {
    Source source = addNamedSource(
        "/test.dart",
        r'''
class A {
  num m() { return 0; }
}
class B extends A {
  int m() { return 1; }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidOverrideReturnType_returnType_superclass2() {
    Source source = addNamedSource(
        "/test.dart",
        r'''
class A {
  num m() { return 0; }
}
class B extends A {
}
class C extends B {
  int m() { return 1; }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidOverrideReturnType_returnType_void() {
    Source source = addSource(r'''
class A {
  void m() {}
}
class B extends A {
  int m() { return 0; }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidReferenceToThis_constructor() {
    Source source = addSource(r'''
class A {
  A() {
    var v = this;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidReferenceToThis_instanceMethod() {
    Source source = addSource(r'''
class A {
  m() {
    var v = this;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidTypeArgumentForKey() {
    Source source = addSource(r'''
class A {
  m() {
    return const <int, int>{};
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidTypeArgumentInConstList() {
    Source source = addSource(r'''
class A<E> {
  m() {
    return <E>[];
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invalidTypeArgumentInConstMap() {
    Source source = addSource(r'''
class A<E> {
  m() {
    return <String, E>{};
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invocationOfNonFunction_dynamic() {
    Source source = addSource(r'''
class A {
  var f;
}
class B extends A {
  g() {
    f();
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invocationOfNonFunction_functionTypeTypeParameter() {
    Source source = addSource(r'''
typedef void Action<T>(T x);
class C<T, U extends Action<T>> {
  T value;
  U action;
  C(this.value, [this.action]);
  void act() {
    action(value);
  }
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invocationOfNonFunction_getter() {
    Source source = addSource(r'''
class A {
  var g;
}
f() {
  A a;
  a.g();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invocationOfNonFunction_localVariable() {
    Source source = addSource(r'''
f() {
  var g;
  g();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invocationOfNonFunction_localVariable_dynamic() {
    Source source = addSource(r'''
f() {}
main() {
  var v = f;
  v();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invocationOfNonFunction_localVariable_dynamic2() {
    Source source = addSource(r'''
f() {}
main() {
  var v = f;
  v = 1;
  v();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invocationOfNonFunction_Object() {
    Source source = addSource(r'''
main() {
  Object v = null;
  v();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invocationOfNonFunction_proxyOnFunctionClass() {
    // 16078
    Source source = addSource(r'''
@proxy
class Functor implements Function {
  noSuchMethod(inv) {
    return 42;
  }
}
main() {
  Functor f = new Functor();
  f();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_issue_24191() {
    Source source = addSource('''
import 'dart:async';

class S extends Stream {}
f(S s) async {
  await for (var v in s) {
    print(v);
  }
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_listElementTypeNotAssignable() {
    Source source = addSource(r'''
var v1 = <int> [42];
var v2 = const <int> [42];''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_loadLibraryDefined() {
    resolveWithErrors(<String>[
      r'''
library lib1;
foo() => 22;''',
      r'''
import 'lib1.dart' deferred as other;
main() {
  other.loadLibrary().then((_) => other.foo());
}'''
    ], <ErrorCode>[]);
  }

  void test_local_generator_async() {
    Source source = addSource('''
f() {
  return () async* { yield 0; };
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_local_generator_sync() {
    Source source = addSource('''
f() {
  return () sync* { yield 0; };
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_mapKeyTypeNotAssignable() {
    Source source = addSource("var v = <String, int > {'a' : 1};");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_memberWithClassName_setter() {
    Source source = addSource(r'''
class A {
  set A(v) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_methodDeclaration_scope_signature() {
    Source source = addSource(r'''
const app = 0;
class A {
  foo(@app int app) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_misMatchedGetterAndSetterTypes_instance_sameTypes() {
    Source source = addSource(r'''
class C {
  int get x => 0;
  set x(int v) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_misMatchedGetterAndSetterTypes_instance_unspecifiedGetter() {
    Source source = addSource(r'''
class C {
  get x => 0;
  set x(String v) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_misMatchedGetterAndSetterTypes_instance_unspecifiedSetter() {
    Source source = addSource(r'''
class C {
  int get x => 0;
  set x(v) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_misMatchedGetterAndSetterTypes_topLevel_sameTypes() {
    Source source = addSource(r'''
int get x => 0;
set x(int v) {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_misMatchedGetterAndSetterTypes_topLevel_unspecifiedGetter() {
    Source source = addSource(r'''
get x => 0;
set x(String v) {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_misMatchedGetterAndSetterTypes_topLevel_unspecifiedSetter() {
    Source source = addSource(r'''
int get x => 0;
set x(v) {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_missingEnumConstantInSwitch_all() {
    Source source = addSource(r'''
enum E { A, B, C }

f(E e) {
  switch (e) {
    case E.A: break;
    case E.B: break;
    case E.C: break;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_missingEnumConstantInSwitch_default() {
    Source source = addSource(r'''
enum E { A, B, C }

f(E e) {
  switch (e) {
    case E.B: break;
    default: break;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_mixedReturnTypes_differentScopes() {
    Source source = addSource(r'''
class C {
  m(int x) {
    f(int y) {
      return;
    }
    f(x);
    return 0;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_mixedReturnTypes_ignoreImplicit() {
    Source source = addSource(r'''
f(bool p) {
  if (p) return 42;
  // implicit 'return;' is ignored
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_mixedReturnTypes_ignoreImplicit2() {
    Source source = addSource(r'''
f(bool p) {
  if (p) {
    return 42;
  } else {
    return 42;
  }
  // implicit 'return;' is ignored
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_mixedReturnTypes_sameKind() {
    Source source = addSource(r'''
class C {
  m(int x) {
    if (x < 0) {
      return 1;
    }
    return 0;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_mixinDeclaresConstructor() {
    Source source = addSource(r'''
class A {
  m() {}
}
class B extends Object with A {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_mixinDeclaresConstructor_factory() {
    Source source = addSource(r'''
class A {
  factory A() => null;
}
class B extends Object with A {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_mixinInheritsFromNotObject_classDeclaration_extends() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.enableSuperMixins = true;
    resetWithOptions(options);
    Source source = addSource(r'''
class A {}
class B extends A {}
class C extends Object with B {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_mixinInheritsFromNotObject_classDeclaration_mixTypeAlias() {
    Source source = addSource(r'''
class A {}
class B = Object with A;
class C extends Object with B {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_mixinInheritsFromNotObject_classDeclaration_with() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.enableSuperMixins = true;
    resetWithOptions(options);
    Source source = addSource(r'''
class A {}
class B extends Object with A {}
class C extends Object with B {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_mixinInheritsFromNotObject_typeAlias_extends() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.enableSuperMixins = true;
    resetWithOptions(options);
    Source source = addSource(r'''
class A {}
class B extends A {}
class C = Object with B;''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_mixinInheritsFromNotObject_typeAlias_with() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.enableSuperMixins = true;
    resetWithOptions(options);
    Source source = addSource(r'''
class A {}
class B extends Object with A {}
class C = Object with B;''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_mixinInheritsFromNotObject_typedef_mixTypeAlias() {
    Source source = addSource(r'''
class A {}
class B = Object with A;
class C = Object with B;''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_mixinReferencesSuper() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.enableSuperMixins = true;
    resetWithOptions(options);
    Source source = addSource(r'''
class A {
  toString() => super.toString();
}
class B extends Object with A {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_multipleSuperInitializers_no() {
    Source source = addSource(r'''
class A {}
class B extends A {
  B() {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_multipleSuperInitializers_single() {
    Source source = addSource(r'''
class A {}
class B extends A {
  B() : super() {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nativeConstConstructor() {
    Source source = addSource(r'''
import 'dart-ext:x';
class Foo {
  const Foo() native 'Foo_Foo';
  const factory Foo.foo() native 'Foo_Foo_foo';
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    // Cannot verify the AST because the import's URI cannot be resolved.
  }

  void test_nativeFunctionBodyInNonSDKCode_function() {
    Source source = addSource(r'''
import 'dart-ext:x';
int m(a) native 'string';''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    // Cannot verify the AST because the import's URI cannot be resolved.
  }

  void test_newWithAbstractClass_factory() {
    Source source = addSource(r'''
abstract class A {
  factory A() { return new B(); }
}
class B implements A {
  B() {}
}
A f() {
  return new A();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_newWithUndefinedConstructor() {
    Source source = addSource(r'''
class A {
  A.name() {}
}
f() {
  new A.name();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_newWithUndefinedConstructorDefault() {
    Source source = addSource(r'''
class A {
  A() {}
}
f() {
  new A();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void
      test_nonAbstractClassInheritsAbstractMemberOne_abstractsDontOverrideConcretes_getter() {
    Source source = addSource(r'''
class A {
  int get g => 0;
}
abstract class B extends A {
  int get g;
}
class C extends B {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void
      test_nonAbstractClassInheritsAbstractMemberOne_abstractsDontOverrideConcretes_method() {
    Source source = addSource(r'''
class A {
  m(p) {}
}
abstract class B extends A {
  m(p);
}
class C extends B {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void
      test_nonAbstractClassInheritsAbstractMemberOne_abstractsDontOverrideConcretes_setter() {
    Source source = addSource(r'''
class A {
  set s(v) {}
}
abstract class B extends A {
  set s(v);
}
class C extends B {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void
      test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_interface() {
    // 15979
    Source source = addSource(r'''
abstract class M {}
abstract class A {}
abstract class I {
  m();
}
abstract class B = A with M implements I;''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_mixin() {
    // 15979
    Source source = addSource(r'''
abstract class M {
  m();
}
abstract class A {}
abstract class B = A with M;''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void
      test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_superclass() {
    // 15979
    Source source = addSource(r'''
class M {}
abstract class A {
  m();
}
abstract class B = A with M;''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_mixin_getter() {
    // 17034
    Source source = addSource(r'''
class A {
  var a;
}
abstract class M {
  get a;
}
class B extends A with M {}
class C extends B {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_mixin_method() {
    Source source = addSource(r'''
class A {
  m() {}
}
abstract class M {
  m();
}
class B extends A with M {}
class C extends B {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_mixin_setter() {
    Source source = addSource(r'''
class A {
  var a;
}
abstract class M {
  set a(dynamic v);
}
class B extends A with M {}
class C extends B {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_noSuchMethod_accessor() {
    Source source = addSource(r'''
abstract class A {
  int get g;
}
class B extends A {
  noSuchMethod(v) => '';
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_noSuchMethod_method() {
    Source source = addSource(r'''
abstract class A {
  m(p);
}
class B extends A {
  noSuchMethod(v) => '';
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonAbstractClassInheritsAbstractMemberOne_noSuchMethod_mixin() {
    Source source = addSource(r'''
class A {
  noSuchMethod(v) => '';
}
class B extends Object with A {
  m(p);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void
      test_nonAbstractClassInheritsAbstractMemberOne_noSuchMethod_superclass() {
    Source source = addSource(r'''
class A {
  noSuchMethod(v) => '';
}
class B extends A {
  m(p);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void
      test_nonAbstractClassInheritsAbstractMemberOne_overridesMethodInObject() {
    Source source = addSource(r'''
class A {
  String toString([String prefix = '']) => '${prefix}Hello';
}
class C {}
class B extends A with C {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonBoolExpression_functionType() {
    Source source = addSource(r'''
bool makeAssertion() => true;
f() {
  assert(makeAssertion);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonBoolExpression_interfaceType() {
    Source source = addSource(r'''
f() {
  assert(true);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonBoolNegationExpression() {
    Source source = addSource(r'''
f(bool pb, pd) {
  !true;
  !false;
  !pb;
  !pd;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonBoolNegationExpression_dynamic() {
    Source source = addSource(r'''
f1(bool dynamic) {
  !dynamic;
}
f2() {
  bool dynamic = true;
  !dynamic;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonBoolOperand_and_bool() {
    Source source = addSource(r'''
bool f(bool left, bool right) {
  return left && right;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonBoolOperand_and_dynamic() {
    Source source = addSource(r'''
bool f(left, dynamic right) {
  return left && right;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonBoolOperand_or_bool() {
    Source source = addSource(r'''
bool f(bool left, bool right) {
  return left || right;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonBoolOperand_or_dynamic() {
    Source source = addSource(r'''
bool f(dynamic left, right) {
  return left || right;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonConstantDefaultValue_constField() {
    Source source = addSource(r'''
f([a = double.INFINITY]) {
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonConstantDefaultValue_function_named() {
    Source source = addSource("f({x : 2 + 3}) {}");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonConstantDefaultValue_function_positional() {
    Source source = addSource("f([x = 2 + 3]) {}");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonConstantDefaultValue_inConstructor_named() {
    Source source = addSource(r'''
class A {
  A({x : 2 + 3}) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonConstantDefaultValue_inConstructor_positional() {
    Source source = addSource(r'''
class A {
  A([x = 2 + 3]) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonConstantDefaultValue_method_named() {
    Source source = addSource(r'''
class A {
  m({x : 2 + 3}) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonConstantDefaultValue_method_positional() {
    Source source = addSource(r'''
class A {
  m([x = 2 + 3]) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonConstantDefaultValue_typedConstList() {
    Source source = addSource(r'''
class A {
  m([p111 = const <String>[]]) {}
}
class B extends A {
  m([p222 = const <String>[]]) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonConstantValueInInitializer_namedArgument() {
    Source source = addSource(r'''
class A {
  final a;
  const A({this.a});
}
class B extends A {
  const B({b}) : super(a: b);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonConstCaseExpression_constField() {
    Source source = addSource(r'''
f(double p) {
  switch (p) {
    case double.INFINITY:
      return true;
    default:
      return false;
  }
}''');
    computeLibrarySourceErrors(source);
    assertErrors(
        source, [CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS]);
    verify([source]);
  }

  void test_nonConstCaseExpression_typeLiteral() {
    Source source = addSource(r'''
f(Type t) {
  switch (t) {
    case bool:
    case int:
      return true;
    default:
      return false;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonConstListElement_constField() {
    Source source = addSource(r'''
main() {
  const [double.INFINITY];
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonConstMapAsExpressionStatement_const() {
    Source source = addSource(r'''
f() {
  const {'a' : 0, 'b' : 1};
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonConstMapAsExpressionStatement_notExpressionStatement() {
    Source source = addSource(r'''
f() {
  var m = {'a' : 0, 'b' : 1};
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonConstMapAsExpressionStatement_typeArguments() {
    Source source = addSource(r'''
f() {
  <String, int> {'a' : 0, 'b' : 1};
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonConstMapKey_constField() {
    Source source = addSource(r'''
main() {
  const {double.INFINITY: 0};
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source,
        [CompileTimeErrorCode.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS]);
    verify([source]);
  }

  void test_nonConstMapValue_constField() {
    Source source = addSource(r'''
main() {
  const {0: double.INFINITY};
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonConstValueInInitializer_binary_bool() {
    Source source = addSource(r'''
class A {
  final v;
  const A.a1(bool p) : v = p && true;
  const A.a2(bool p) : v = true && p;
  const A.b1(bool p) : v = p || true;
  const A.b2(bool p) : v = true || p;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_nonConstValueInInitializer_binary_dynamic() {
    Source source = addSource(r'''
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
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    // operations on "p" are not resolved
  }

  void test_nonConstValueInInitializer_binary_int() {
    Source source = addSource(r'''
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
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonConstValueInInitializer_binary_num() {
    Source source = addSource(r'''
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
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonConstValueInInitializer_field() {
    Source source = addSource(r'''
class A {
  final int a;
  const A() : a = 5;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonConstValueInInitializer_redirecting() {
    Source source = addSource(r'''
class A {
  const A.named(p);
  const A() : this.named(42);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonConstValueInInitializer_super() {
    Source source = addSource(r'''
class A {
  const A(p);
}
class B extends A {
  const B() : super(42);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonConstValueInInitializer_unary() {
    Source source = addSource(r'''
class A {
  final v;
  const A.a(bool p) : v = !p;
  const A.b(int p) : v = ~p;
  const A.c(num p) : v = -p;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonGenerativeConstructor() {
    Source source = addSource(r'''
class A {
  A.named() {}
  factory A() => null;
}
class B extends A {
  B() : super.named();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonTypeInCatchClause_isClass() {
    Source source = addSource(r'''
f() {
  try {
  } on String catch (e) {
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonTypeInCatchClause_isFunctionTypeAlias() {
    Source source = addSource(r'''
typedef F();
f() {
  try {
  } on F catch (e) {
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonTypeInCatchClause_isTypeParameter() {
    Source source = addSource(r'''
class A<T> {
  f() {
    try {
    } on T catch (e) {
    }
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonTypeInCatchClause_noType() {
    Source source = addSource(r'''
f() {
  try {
  } catch (e) {
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonVoidReturnForOperator_no() {
    Source source = addSource(r'''
class A {
  operator []=(a, b) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonVoidReturnForOperator_void() {
    Source source = addSource(r'''
class A {
  void operator []=(a, b) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonVoidReturnForSetter_function_no() {
    Source source = addSource("set x(v) {}");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonVoidReturnForSetter_function_void() {
    Source source = addSource("void set x(v) {}");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonVoidReturnForSetter_method_no() {
    Source source = addSource(r'''
class A {
  set x(v) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_nonVoidReturnForSetter_method_void() {
    Source source = addSource(r'''
class A {
  void set x(v) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_null_callMethod() {
    Source source = addSource(r'''
main() {
  null.m();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_null_callOperator() {
    Source source = addSource(r'''
main() {
  null + 5;
  null == 5;
  null[0];
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_optionalParameterInOperator_required() {
    Source source = addSource(r'''
class A {
  operator +(p) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_parameterDefaultDoesNotReferToParameterName() {
    // The final "f" should refer to the toplevel function "f", not to the
    // parameter called "f".  See dartbug.com/13179.
    Source source = addSource('void f([void f([x]) = f]) {}');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_parameterScope_local() {
    // Parameter names shouldn't conflict with the name of the function they
    // are enclosed in.
    Source source = addSource(r'''
f() {
  g(g) {
    h(g);
  }
}
h(x) {}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_parameterScope_method() {
    // Parameter names shouldn't conflict with the name of the function they
    // are enclosed in.
    Source source = addSource(r'''
class C {
  g(g) {
    h(g);
  }
}
h(x) {}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_parameterScope_toplevel() {
    // Parameter names shouldn't conflict with the name of the function they
    // are enclosed in.
    Source source = addSource(r'''
g(g) {
  h(g);
}
h(x) {}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_prefixCollidesWithTopLevelMembers() {
    addNamedSource(
        "/lib.dart",
        r'''
library lib;
class A {}''');
    Source source = addSource(r'''
import 'lib.dart' as p;
typedef P();
p2() {}
var p3;
class p4 {}
p.A a;''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_propagateTypeArgs_intoBounds() {
    Source source = addSource(r'''
abstract class A<E> {}
abstract class B<F> implements A<F>{}
abstract class C<G, H extends A<G>> {}
class D<I> extends C<I, B<I>> {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_propagateTypeArgs_intoSupertype() {
    Source source = addSource(r'''
class A<T> {
  A(T p);
  A.named(T p);
}
class B<S> extends A<S> {
  B(S p) : super(p);
  B.named(S p) : super.named(p);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_proxy_annotation_prefixed() {
    Source source = addSource(r'''
library L;
@proxy
class A {}
f(A a) {
  a.m();
  var x = a.g;
  a.s = 1;
  var y = a + a;
  a++;
  ++a;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_proxy_annotation_prefixed2() {
    Source source = addSource(r'''
library L;
@proxy
class A {}
class B {
  f(A a) {
    a.m();
    var x = a.g;
    a.s = 1;
    var y = a + a;
    a++;
    ++a;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_proxy_annotation_prefixed3() {
    Source source = addSource(r'''
library L;
class B {
  f(A a) {
    a.m();
    var x = a.g;
    a.s = 1;
    var y = a + a;
    a++;
    ++a;
  }
}
@proxy
class A {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_proxy_annotation_proxyHasPrefixedIdentifier() {
    Source source = addSource(r'''
library L;
import 'dart:core' as core;
@core.proxy class PrefixProxy {}
main() {
  new PrefixProxy().foo;
  new PrefixProxy().foo();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_proxy_annotation_simple() {
    Source source = addSource(r'''
library L;
@proxy
class B {
  m() {
    n();
    var x = g;
    s = 1;
    var y = this + this;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_proxy_annotation_superclass() {
    Source source = addSource(r'''
library L;
class B extends A {
  m() {
    n();
    var x = g;
    s = 1;
    var y = this + this;
  }
}
@proxy
class A {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_proxy_annotation_superclass_mixin() {
    Source source = addSource(r'''
library L;
class B extends Object with A {
  m() {
    n();
    var x = g;
    s = 1;
    var y = this + this;
  }
}
@proxy
class A {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_proxy_annotation_superinterface() {
    Source source = addSource(r'''
library L;
class B implements A {
  m() {
    n();
    var x = g;
    s = 1;
    var y = this + this;
  }
}
@proxy
class A {}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_proxy_annotation_superinterface_infiniteLoop() {
    Source source = addSource(r'''
library L;
class C implements A {
  m() {
    n();
    var x = g;
    s = 1;
    var y = this + this;
  }
}
class B implements A{}
class A implements B{}''');
    computeLibrarySourceErrors(source);
    // Test is that a stack overflow isn't reached in resolution
    // (previous line), no need to assert error set.
  }

  void test_recursiveConstructorRedirect() {
    Source source = addSource(r'''
class A {
  A.a() : this.b();
  A.b() : this.c();
  A.c() {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_recursiveFactoryRedirect() {
    Source source = addSource(r'''
class A {
  factory A() = B;
}
class B implements A {
  factory B() = C;
}
class C implements B {
  factory C() => null;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_redirectToInvalidFunctionType() {
    Source source = addSource(r'''
class A implements B {
  A(int p) {}
}
class B {
  factory B(int p) = A;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_redirectToInvalidReturnType() {
    Source source = addSource(r'''
class A {
  A() {}
}
class B extends A {
  factory B() = A;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_redirectToNonConstConstructor() {
    Source source = addSource(r'''
class A {
  const A.a();
  const factory A.b() = A.a;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_referencedBeforeDeclaration_cascade() {
    Source source = addSource(r'''
testRequestHandler() {}

main() {
  var s1 = null;
  testRequestHandler()
    ..stream(s1);
  var stream = 123;
  print(stream);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_referenceToDeclaredVariableInInitializer_constructorName() {
    Source source = addSource(r'''
class A {
  A.x() {}
}
f() {
  var x = new A.x();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_referenceToDeclaredVariableInInitializer_methodName() {
    Source source = addSource(r'''
class A {
  x() {}
}
f(A a) {
  var x = a.x();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_referenceToDeclaredVariableInInitializer_propertyName() {
    Source source = addSource(r'''
class A {
  var x;
}
f(A a) {
  var x = a.x;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_rethrowOutsideCatch() {
    Source source = addSource(r'''
class A {
  void m() {
    try {} catch (e) {rethrow;}
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_return_in_generator_async() {
    Source source = addSource('''
import 'dart:async';
Stream<int> f() async* {
  return;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_return_in_generator_sync() {
    Source source = addSource('''
Iterable<int> f() sync* {
  return;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_returnInGenerativeConstructor() {
    Source source = addSource(r'''
class A {
  A() { return; }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_returnInGenerator_async() {
    Source source = addSource(r'''
f() async {
  return 0;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_returnInGenerator_sync() {
    Source source = addSource(r'''
f() {
  return 0;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_returnOfInvalidType_async() {
    Source source = addSource(r'''
import 'dart:async';
class A {
  Future<int> m() async {
    return 0;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_returnOfInvalidType_dynamic() {
    Source source = addSource(r'''
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
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_returnOfInvalidType_dynamicAsTypeArgument() {
    Source source = addSource(r'''
class I<T> {
  factory I() => new A<T>();
}
class A<T> implements I {
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_returnOfInvalidType_subtype() {
    Source source = addSource(r'''
class A {}
class B extends A {}
A f(B b) { return b; }''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_returnOfInvalidType_supertype() {
    Source source = addSource(r'''
class A {}
class B extends A {}
B f(A a) { return a; }''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_returnOfInvalidType_typeParameter_18468() {
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
    Source source = addSource(r'''
class Foo<T> {
  Type get t => T;
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source);
    verify([source]);
  }

  void test_returnOfInvalidType_void() {
    Source source = addSource(r'''
void f1() {}
void f2() { return; }
void f3() { return null; }
void f4() { return g1(); }
void f5() { return g2(); }
g1() {}
void g2() {}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_returnWithoutValue_noReturnType() {
    Source source = addSource("f() { return; }");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_returnWithoutValue_void() {
    Source source = addSource("void f() { return; }");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_reversedTypeArguments() {
    Source source = addSource(r'''
class Codec<S1, T1> {
  Codec<T1, S1> get inverted => new _InvertedCodec<T1, S1>(this);
}
class _InvertedCodec<T2, S2> extends Codec<T2, S2> {
  _InvertedCodec(Codec<S2, T2> codec);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_sharedDeferredPrefix() {
    resolveWithErrors(<String>[
      r'''
library lib1;
f1() {}''',
      r'''
library lib2;
f2() {}''',
      r'''
library lib3;
f3() {}''',
      r'''
library root;
import 'lib1.dart' deferred as lib1;
import 'lib2.dart' as lib;
import 'lib3.dart' as lib;
main() { lib1.f1(); lib.f2(); lib.f3(); }'''
    ], <ErrorCode>[]);
  }

  void test_staticAccessToInstanceMember_annotation() {
    Source source = addSource(r'''
class A {
  const A.name();
}
@A.name()
main() {
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_staticAccessToInstanceMember_method() {
    Source source = addSource(r'''
class A {
  static m() {}
}
main() {
  A.m;
  A.m();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_staticAccessToInstanceMember_propertyAccess_field() {
    Source source = addSource(r'''
class A {
  static var f;
}
main() {
  A.f;
  A.f = 1;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_staticAccessToInstanceMember_propertyAccess_propertyAccessor() {
    Source source = addSource(r'''
class A {
  static get f => 42;
  static set f(x) {}
}
main() {
  A.f;
  A.f = 1;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_superInInvalidContext() {
    Source source = addSource(r'''
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
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typeAliasCannotReferenceItself_returnClass_withTypeAlias() {
    Source source = addSource(r'''
typedef B A();
class B {
  A a;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_const() {
    Source source = addSource(r'''
class A {}
class B extends A {}
class G<E extends A> {
  const G();
}
f() { return const G<B>(); }''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_new() {
    Source source = addSource(r'''
class A {}
class B extends A {}
class G<E extends A> {}
f() { return new G<B>(); }''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_ofFunctionTypeAlias_hasBound() {
    Source source = addSource(r'''
class A {}
class B extends A {}
typedef F<T extends A>();
F<A> fa;
F<B> fb;
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_ofFunctionTypeAlias_hasBound2() {
    Source source = addSource(r'''
class MyClass<T> {}
typedef MyFunction<T, P extends MyClass<T>>();
class A<T, P extends MyClass<T>> {
  MyFunction<T, P> f;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_ofFunctionTypeAlias_noBound() {
    Source source = addSource(r'''
typedef F<T>();
F<int> f1;
F<String> f2;
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_typeArgumentList_0() {
    Source source = addSource("abstract class A<T extends A>{}");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_typeArgumentList_1() {
    Source source = addSource("abstract class A<T extends A<A>>{}");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_typeArgumentList_20() {
    Source source = addSource(
        "abstract class A<T extends A<A<A<A<A<A<A<A<A<A<A<A<A<A<A<A<A<A<A<A<A>>>>>>>>>>>>>>>>>>>>>{}");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typePromotion_booleanAnd_useInRight() {
    Source source = addSource(r'''
main(Object p) {
  p is String && p.length != 0;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void
      test_typePromotion_booleanAnd_useInRight_accessedInClosureRight_noAssignment() {
    Source source = addSource(r'''
callMe(f()) { f(); }
main(Object p) {
  (p is String) && callMe(() { p.length; });
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typePromotion_conditional_issue14655() {
    Source source = addSource(r'''
class A {}
class B extends A {}
class C extends B {
  mc() {}
}
print(_) {}
main(A p) {
  (p is C) && (print(() => p) && (p is B)) ? p.mc() : p = null;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typePromotion_conditional_useInThen() {
    Source source = addSource(r'''
main(Object p) {
  p is String ? p.length : 0;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void
      test_typePromotion_conditional_useInThen_accessedInClosure_noAssignment() {
    Source source = addSource(r'''
callMe(f()) { f(); }
main(Object p) {
  p is String ? callMe(() { p.length; }) : 0;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typePromotion_functionType_arg_ignoreIfNotMoreSpecific() {
    Source source = addSource(r'''
typedef FuncB(B b);
typedef FuncA(A a);
class A {}
class B {}
main(FuncA f) {
  if (f is FuncB) {
    f(new A());
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typePromotion_functionType_return_ignoreIfNotMoreSpecific() {
    Source source = addSource(r'''
class A {}
typedef FuncAtoDyn(A a);
typedef FuncDynToDyn(x);
main(FuncAtoDyn f) {
  if (f is FuncDynToDyn) {
    A a = f(new A());
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typePromotion_functionType_return_voidToDynamic() {
    Source source = addSource(r'''
typedef FuncDynToDyn(x);
typedef void FuncDynToVoid(x);
class A {}
main(FuncDynToVoid f) {
  if (f is FuncDynToDyn) {
    A a = f(null);
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typePromotion_if_accessedInClosure_noAssignment() {
    Source source = addSource(r'''
callMe(f()) { f(); }
main(Object p) {
  if (p is String) {
    callMe(() {
      p.length;
    });
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typePromotion_if_extends_moreSpecific() {
    Source source = addSource(r'''
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
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typePromotion_if_hasAssignment_outsideAfter() {
    Source source = addSource(r'''
main(Object p) {
  if (p is String) {
    p.length;
  }
  p = 0;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typePromotion_if_hasAssignment_outsideBefore() {
    Source source = addSource(r'''
main(Object p, Object p2) {
  p = p2;
  if (p is String) {
    p.length;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typePromotion_if_implements_moreSpecific() {
    Source source = addSource(r'''
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
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typePromotion_if_inClosure_assignedAfter_inSameFunction() {
    Source source = addSource(r'''
main() {
  f(Object p) {
    if (p is String) {
      p.length;
    }
    p = 0;
  };
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typePromotion_if_is_and_left() {
    Source source = addSource(r'''
bool tt() => true;
main(Object p) {
  if (p is String && tt()) {
    p.length;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typePromotion_if_is_and_right() {
    Source source = addSource(r'''
bool tt() => true;
main(Object p) {
  if (tt() && p is String) {
    p.length;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typePromotion_if_is_and_subThenSuper() {
    Source source = addSource(r'''
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
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typePromotion_if_is_parenthesized() {
    Source source = addSource(r'''
main(Object p) {
  if ((p is String)) {
    p.length;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typePromotion_if_is_single() {
    Source source = addSource(r'''
main(Object p) {
  if (p is String) {
    p.length;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typePromotion_parentheses() {
    Source source = addSource(r'''
main(Object p) {
  (p is String) ? p.length : 0;
  (p) is String ? p.length : 0;
  ((p)) is String ? p.length : 0;
  ((p) is String) ? p.length : 0;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typeType_class() {
    Source source = addSource(r'''
class C {}
f(Type t) {}
main() {
  f(C);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typeType_class_prefixed() {
    addNamedSource(
        "/lib.dart",
        r'''
library lib;
class C {}''');
    Source source = addSource(r'''
import 'lib.dart' as p;
f(Type t) {}
main() {
  f(p.C);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typeType_functionTypeAlias() {
    Source source = addSource(r'''
typedef F();
f(Type t) {}
main() {
  f(F);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typeType_functionTypeAlias_prefixed() {
    addNamedSource(
        "/lib.dart",
        r'''
library lib;
typedef F();''');
    Source source = addSource(r'''
import 'lib.dart' as p;
f(Type t) {}
main() {
  f(p.F);
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_undefinedConstructorInInitializer_explicit_named() {
    Source source = addSource(r'''
class A {
  A.named() {}
}
class B extends A {
  B() : super.named();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_undefinedConstructorInInitializer_explicit_unnamed() {
    Source source = addSource(r'''
class A {
  A() {}
}
class B extends A {
  B() : super();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_undefinedConstructorInInitializer_hasOptionalParameters() {
    Source source = addSource(r'''
class A {
  A([p]) {}
}
class B extends A {
  B();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_undefinedConstructorInInitializer_implicit() {
    Source source = addSource(r'''
class A {
  A() {}
}
class B extends A {
  B();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_undefinedConstructorInInitializer_implicit_typeAlias() {
    Source source = addSource(r'''
class M {}
class A = Object with M;
class B extends A {
  B();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_undefinedConstructorInInitializer_redirecting() {
    Source source = addSource(r'''
class Foo {
  Foo.ctor();
}
class Bar extends Foo {
  Bar() : this.ctor();
  Bar.ctor() : super.ctor();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_undefinedGetter_static_conditionalAccess() {
    // The conditional access operator '?.' can be used to access static
    // fields.
    Source source = addSource('''
class A {
  static var x;
}
var a = A?.x;
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_undefinedGetter_typeSubstitution() {
    Source source = addSource(r'''
class A<E> {
  E element;
}
class B extends A<List> {
  m() {
    element.last;
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_undefinedIdentifier_synthetic_whenExpression() {
    Source source = addSource(r'''
print(x) {}
main() {
  print(is String);
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [ParserErrorCode.MISSING_IDENTIFIER]);
  }

  void test_undefinedIdentifier_synthetic_whenMethodName() {
    Source source = addSource(r'''
print(x) {}
main(int p) {
  p.();
}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [ParserErrorCode.MISSING_IDENTIFIER]);
  }

  void test_undefinedMethod_functionExpression_callMethod() {
    Source source = addSource(r'''
main() {
  (() => null).call();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    // A call to verify(source) fails as '.call()' isn't resolved.
  }

  void test_undefinedMethod_functionExpression_directCall() {
    Source source = addSource(r'''
main() {
  (() => null)();
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    // A call to verify(source) fails as '(() => null)()' isn't resolved.
  }

  void test_undefinedMethod_static_conditionalAccess() {
    // The conditional access operator '?.' can be used to access static
    // methods.
    Source source = addSource('''
class A {
  static void m() {}
}
f() { A?.m(); }
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_undefinedOperator_index() {
    Source source = addSource(r'''
class A {
  operator [](a) {}
  operator []=(a, b) {}
}
f(A a) {
  a[0];
  a[0] = 1;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_undefinedOperator_tilde() {
    Source source = addSource(r'''
const A = 3;
const B = ~((1 << A) - 1);''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_undefinedSetter_importWithPrefix() {
    addNamedSource(
        "/lib.dart",
        r'''
library lib;
set y(int value) {}''');
    Source source = addSource(r'''
import 'lib.dart' as x;
main() {
  x.y = 0;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_undefinedSetter_static_conditionalAccess() {
    // The conditional access operator '?.' can be used to access static
    // fields.
    Source source = addSource('''
class A {
  static var x;
}
f() { A?.x = 1; }
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_undefinedSuperMethod_field() {
    Source source = addSource(r'''
class A {
  var m;
}
class B extends A {
  f() {
    super.m();
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_undefinedSuperMethod_method() {
    Source source = addSource(r'''
class A {
  m() {}
}
class B extends A {
  f() {
    super.m();
  }
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unqualifiedReferenceToNonLocalStaticMember_fromComment_new() {
    Source source = addSource(r'''
class A {
  A() {}
  A.named() {}
}
/// [new A] or [new A.named]
main() {
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedShownName_unresolved() {
    Source source = addSource(r'''
import 'dart:math' show max, FooBar;
main() {
  print(max(1, 2));
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [HintCode.UNDEFINED_SHOWN_NAME]);
  }

  void test_uriDoesNotExist_dll() {
    addNamedSource("/lib.dll", "");
    Source source = addSource("import 'dart-ext:lib';");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_uriDoesNotExist_dylib() {
    addNamedSource("/lib.dylib", "");
    Source source = addSource("import 'dart-ext:lib';");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_uriDoesNotExist_so() {
    addNamedSource("/lib.so", "");
    Source source = addSource("import 'dart-ext:lib';");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
  }

  void test_wrongNumberOfParametersForOperator1() {
    _check_wrongNumberOfParametersForOperator1("<");
    _check_wrongNumberOfParametersForOperator1(">");
    _check_wrongNumberOfParametersForOperator1("<=");
    _check_wrongNumberOfParametersForOperator1(">=");
    _check_wrongNumberOfParametersForOperator1("+");
    _check_wrongNumberOfParametersForOperator1("/");
    _check_wrongNumberOfParametersForOperator1("~/");
    _check_wrongNumberOfParametersForOperator1("*");
    _check_wrongNumberOfParametersForOperator1("%");
    _check_wrongNumberOfParametersForOperator1("|");
    _check_wrongNumberOfParametersForOperator1("^");
    _check_wrongNumberOfParametersForOperator1("&");
    _check_wrongNumberOfParametersForOperator1("<<");
    _check_wrongNumberOfParametersForOperator1(">>");
    _check_wrongNumberOfParametersForOperator1("[]");
  }

  void test_wrongNumberOfParametersForOperator_index() {
    Source source = addSource(r'''
class A {
  operator []=(a, b) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_wrongNumberOfParametersForOperator_minus() {
    _check_wrongNumberOfParametersForOperator("-", "");
    _check_wrongNumberOfParametersForOperator("-", "a");
  }

  void test_wrongNumberOfParametersForSetter() {
    Source source = addSource(r'''
class A {
  set x(a) {}
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_yield_async_to_dynamic_type() {
    Source source = addSource('''
dynamic f() async* {
  yield 3;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_yield_async_to_generic_type() {
    Source source = addSource('''
import 'dart:async';
Stream f() async* {
  yield 3;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_yield_async_to_parameterized_type() {
    Source source = addSource('''
import 'dart:async';
Stream<int> f() async* {
  yield 3;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_yield_async_to_untyped() {
    Source source = addSource('''
f() async* {
  yield 3;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_yield_each_async_dynamic_to_dynamic() {
    Source source = addSource('''
f() async* {
  yield* g();
}
g() => null;
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_yield_each_async_dynamic_to_stream() {
    Source source = addSource('''
import 'dart:async';
Stream f() async* {
  yield* g();
}
g() => null;
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_yield_each_async_dynamic_to_typed_stream() {
    Source source = addSource('''
import 'dart:async';
Stream<int> f() async* {
  yield* g();
}
g() => null;
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_yield_each_async_stream_to_dynamic() {
    Source source = addSource('''
import 'dart:async';
f() async* {
  yield* g();
}
Stream g() => null;
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_yield_each_async_typed_stream_to_dynamic() {
    Source source = addSource('''
import 'dart:async';
f() async* {
  yield* g();
}
Stream<int> g() => null;
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_yield_each_async_typed_stream_to_typed_stream() {
    Source source = addSource('''
import 'dart:async';
Stream<int> f() async* {
  yield* g();
}
Stream<int> g() => null;
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_yield_each_sync_dynamic_to_dynamic() {
    Source source = addSource('''
f() sync* {
  yield* g();
}
g() => null;
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_yield_each_sync_dynamic_to_iterable() {
    Source source = addSource('''
Iterable f() sync* {
  yield* g();
}
g() => null;
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_yield_each_sync_dynamic_to_typed_iterable() {
    Source source = addSource('''
Iterable<int> f() sync* {
  yield* g();
}
g() => null;
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_yield_each_sync_iterable_to_dynamic() {
    Source source = addSource('''
f() sync* {
  yield* g();
}
Iterable g() => null;
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_yield_each_sync_typed_iterable_to_dynamic() {
    Source source = addSource('''
f() sync* {
  yield* g();
}
Iterable<int> g() => null;
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_yield_each_sync_typed_iterable_to_typed_iterable() {
    Source source = addSource('''
Iterable<int> f() sync* {
  yield* g();
}
Iterable<int> g() => null;
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_yield_sync_to_dynamic_type() {
    Source source = addSource('''
dynamic f() sync* {
  yield 3;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_yield_sync_to_generic_type() {
    Source source = addSource('''
Iterable f() sync* {
  yield 3;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_yield_sync_to_parameterized_type() {
    Source source = addSource('''
Iterable<int> f() sync* {
  yield 3;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_yield_sync_to_untyped() {
    Source source = addSource('''
f() sync* {
  yield 3;
}
''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_yieldInNonGenerator_asyncStar() {
    Source source = addSource(r'''
f() async* {
  yield 0;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_yieldInNonGenerator_syncStar() {
    Source source = addSource(r'''
f() sync* {
  yield 0;
}''');
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
  }

  void _check_wrongNumberOfParametersForOperator(
      String name, String parameters) {
    Source source = addSource("""
class A {
  operator $name($parameters) {}
}""");
    computeLibrarySourceErrors(source);
    assertNoErrors(source);
    verify([source]);
    reset();
  }

  void _check_wrongNumberOfParametersForOperator1(String name) {
    _check_wrongNumberOfParametersForOperator(name, "a");
  }

  CompilationUnit _getResolvedLibraryUnit(Source source) =>
      analysisContext.getResolvedCompilationUnit2(source, source);
}
