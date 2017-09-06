// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.non_error_resolver_test;

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
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
  fail_undefinedEnumConstant() async {
    Source source = addSource(r'''
enum E { ONE }
E e() {
  return E.TWO;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_abstractSuperMemberReference_superHasConcrete_mixinHasAbstract_method() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_abstractSuperMemberReference_superHasNoSuchMethod() async {
    Source source = addSource('''
abstract class A {
  int m();
  noSuchMethod(_) => 42;
}

class B extends A {
  int m() => super.m();
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_abstractSuperMemberReference_superSuperHasConcrete_getter() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_abstractSuperMemberReference_superSuperHasConcrete_method() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_abstractSuperMemberReference_superSuperHasConcrete_setter() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_ambiguousExport() async {
    Source source = addSource(r'''
library L;
export 'lib1.dart';
export 'lib2.dart';''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class M {}''');
    addNamedSource("/lib2.dart", r'''
library lib2;
class N {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_ambiguousExport_combinators_hide() async {
    Source source = addSource(r'''
library L;
export 'lib1.dart';
export 'lib2.dart' hide B;''');
    addNamedSource("/lib1.dart", r'''
library L1;
class A {}
class B {}''');
    addNamedSource("/lib2.dart", r'''
library L2;
class B {}
class C {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_ambiguousExport_combinators_show() async {
    Source source = addSource(r'''
library L;
export 'lib1.dart';
export 'lib2.dart' show C;''');
    addNamedSource("/lib1.dart", r'''
library L1;
class A {}
class B {}''');
    addNamedSource("/lib2.dart", r'''
library L2;
class B {}
class C {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_ambiguousExport_sameDeclaration() async {
    Source source = addSource(r'''
library L;
export 'lib.dart';
export 'lib.dart';''');
    addNamedSource("/lib.dart", r'''
library lib;
class N {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_ambiguousImport_hideCombinator() async {
    Source source = addSource(r'''
import 'lib1.dart';
import 'lib2.dart';
import 'lib3.dart' hide N;
main() {
  new N1();
  new N2();
  new N3();
}''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class N {}
class N1 {}''');
    addNamedSource("/lib2.dart", r'''
library lib2;
class N {}
class N2 {}''');
    addNamedSource("/lib3.dart", r'''
library lib3;
class N {}
class N3 {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_ambiguousImport_showCombinator() async {
    Source source = addSource(r'''
import 'lib1.dart';
import 'lib2.dart' show N, N2;
main() {
  new N1();
  new N2();
}''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class N {}
class N1 {}''');
    addNamedSource("/lib2.dart", r'''
library lib2;
class N {}
class N2 {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_SHOWN_NAME]);
  }

  test_annotated_partOfDeclaration() async {
    Source source = addSource('library L; part "part.dart";');
    addNamedSource('/part.dart', '@deprecated part of L;');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_argumentTypeNotAssignable_classWithCall_Function() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_argumentTypeNotAssignable_fieldFormalParameterElement_member() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_argumentTypeNotAssignable_invocation_functionParameter_generic() async {
    Source source = addSource(r'''
class A<K> {
  m(f(K k), K v) {
    f(v);
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_argumentTypeNotAssignable_invocation_typedef_generic() async {
    Source source = addSource(r'''
typedef A<T>(T p);
f(A<int> a) {
  a(1);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_argumentTypeNotAssignable_Object_Function() async {
    Source source = addSource(r'''
main() {
  process(() {});
}
process(Object x) {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_argumentTypeNotAssignable_typedef_local() async {
    Source source = addSource(r'''
typedef A(int p1, String p2);
A getA() => null;
f() {
  A a = getA();
  a(1, '2');
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_argumentTypeNotAssignable_typedef_parameter() async {
    Source source = addSource(r'''
typedef A(int p1, String p2);
f(A a) {
  a(1, '2');
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_assert_with_message_await() async {
    Source source = addSource('''
import 'dart:async';
f() async {
  assert(false, await g());
}
Future<String> g() => null;
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_assert_with_message_dynamic() async {
    Source source = addSource('''
f() {
  assert(false, g());
}
g() => null;
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_assert_with_message_non_string() async {
    Source source = addSource('''
f() {
  assert(false, 3);
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_assert_with_message_null() async {
    Source source = addSource('''
f() {
  assert(false, null);
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_assert_with_message_string() async {
    Source source = addSource('''
f() {
  assert(false, 'message');
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_assert_with_message_suppresses_unused_var_hint() async {
    Source source = addSource('''
f() {
  String message = 'msg';
  assert(true, message);
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_assignability_function_expr_rettype_from_typedef_cls() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_assignability_function_expr_rettype_from_typedef_typedef() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_assignmentToFinal_prefixNegate() async {
    Source source = addSource(r'''
f() {
  final x = 0;
  -x;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_assignmentToFinalNoSetter_prefixedIdentifier() async {
    Source source = addSource(r'''
class A {
  int get x => 0;
  set x(v) {}
}
main() {
  A a = new A();
  a.x = 0;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_assignmentToFinalNoSetter_propertyAccess() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_assignmentToFinals_importWithPrefix() async {
    Source source = addSource(r'''
library lib;
import 'lib1.dart' as foo;
main() {
  foo.x = true;
}''');
    addNamedSource("/lib1.dart", r'''
library lib1;
bool x = false;''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_async_dynamic_with_return() async {
    Source source = addSource('''
dynamic f() async {
  return;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_async_dynamic_with_return_value() async {
    Source source = addSource('''
dynamic f() async {
  return 5;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_async_dynamic_without_return() async {
    Source source = addSource('''
dynamic f() async {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_async_expression_function_type() async {
    Source source = addSource('''
import 'dart:async';
typedef Future<int> F(int i);
main() {
  F f = (int i) async => i;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_async_flattened() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_async_future_dynamic_with_return() async {
    Source source = addSource('''
import 'dart:async';
Future<dynamic> f() async {
  return;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_async_future_dynamic_with_return_value() async {
    Source source = addSource('''
import 'dart:async';
Future<dynamic> f() async {
  return 5;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_async_future_dynamic_without_return() async {
    Source source = addSource('''
import 'dart:async';
Future<dynamic> f() async {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_async_future_int_with_return_future_int() async {
    Source source = addSource('''
import 'dart:async';
Future<int> f() async {
  return new Future<int>.value(5);
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_async_future_int_with_return_value() async {
    Source source = addSource('''
import 'dart:async';
Future<int> f() async {
  return 5;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_async_future_null_with_return() async {
    Source source = addSource('''
import 'dart:async';
Future<Null> f() async {
  return;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_async_future_null_without_return() async {
    Source source = addSource('''
import 'dart:async';
Future<Null> f() async {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_async_future_object_with_return() async {
    Source source = addSource('''
import 'dart:async';
Future<Object> f() async {
  return;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_async_future_object_with_return_value() async {
    Source source = addSource('''
import 'dart:async';
Future<Object> f() async {
  return 5;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_async_future_with_return() async {
    Source source = addSource('''
import 'dart:async';
Future f() async {
  return;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_async_future_with_return_value() async {
    Source source = addSource('''
import 'dart:async';
Future f() async {
  return 5;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_async_future_without_return() async {
    Source source = addSource('''
import 'dart:async';
Future f() async {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_async_return_flattens_futures() async {
    Source source = addSource('''
import 'dart:async';
Future<int> f() async {
  return g();
}
Future<Future<int>> g() => null;
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_async_with_return() async {
    Source source = addSource('''
f() async {
  return;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_async_with_return_value() async {
    Source source = addSource('''
f() async {
  return 5;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_async_without_return() async {
    Source source = addSource('''
f() async {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_asyncForInWrongContext_async() async {
    Source source = addSource(r'''
f(list) async {
  await for (var e in list) {
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_asyncForInWrongContext_asyncStar() async {
    Source source = addSource(r'''
f(list) async* {
  await for (var e in list) {
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_await_flattened() async {
    Source source = addSource('''
import 'dart:async';
Future<Future<int>> ffi() => null;
f() async {
  int b = await ffi();
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_await_simple() async {
    Source source = addSource('''
import 'dart:async';
Future<int> fi() => null;
f() async {
  int a = await fi();
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_awaitInWrongContext_async() async {
    Source source = addSource(r'''
f(x, y) async {
  return await x + await y;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_awaitInWrongContext_asyncStar() async {
    Source source = addSource(r'''
f(x, y) async* {
  yield await x + await y;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_breakWithoutLabelInSwitch() async {
    Source source = addSource(r'''
class A {
  void m(int i) {
    switch (i) {
      case 0:
        break;
    }
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_bug_24539_getter() async {
    Source source = addSource('''
class C<T> {
  List<Foo> get x => null;
}

typedef Foo(param);
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_bug_24539_setter() async {
    Source source = addSource('''
class C<T> {
  void set x(List<Foo> value) {}
}

typedef Foo(param);
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_builtInIdentifierAsType_dynamic() async {
    Source source = addSource(r'''
f() {
  dynamic x;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_caseBlockNotTerminated() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_caseBlockNotTerminated_lastCase() async {
    Source source = addSource(r'''
f(int p) {
  switch (p) {
    case 0:
      p = p + 1;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_caseExpressionTypeImplementsEquals() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_caseExpressionTypeImplementsEquals_int() async {
    Source source = addSource(r'''
f(int i) {
  switch(i) {
    case(1) : return 1;
    default: return 0;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_caseExpressionTypeImplementsEquals_Object() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_caseExpressionTypeImplementsEquals_String() async {
    Source source = addSource(r'''
f(String s) {
  switch(s) {
    case('1') : return 1;
    default: return 0;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_class_type_alias_documentationComment() async {
    Source source = addSource('''
/**
 * Documentation
 */
class C = D with E;

class D {}
class E {}''');
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    ClassElement classC =
        resolutionMap.elementDeclaredByCompilationUnit(unit).getType('C');
    expect(classC.documentationComment, isNotNull);
  }

  test_commentReference_beforeConstructor() async {
    String code = r'''
abstract class A {
  /// [p]
  A(int p) {}
}''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    {
      SimpleIdentifier ref =
          EngineTestCase.findSimpleIdentifier(unit, code, "p]");
      expect(ref.staticElement, new isInstanceOf<ParameterElement>());
    }
  }

  test_commentReference_beforeEnum() async {
    String code = r'''
/// This is the [Samurai] kind.
enum Samurai {
  /// Use [int].
  WITH_SWORD,
  /// Like [WITH_SWORD], but only without one.
  WITHOUT_SWORD
}''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
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

  test_commentReference_beforeFunction_blockBody() async {
    String code = r'''
/// [p]
foo(int p) {
}''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    SimpleIdentifier ref =
        EngineTestCase.findSimpleIdentifier(unit, code, 'p]');
    expect(ref.staticElement, new isInstanceOf<ParameterElement>());
  }

  test_commentReference_beforeFunction_expressionBody() async {
    String code = r'''
/// [p]
foo(int p) => null;''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    SimpleIdentifier ref =
        EngineTestCase.findSimpleIdentifier(unit, code, 'p]');
    expect(ref.staticElement, new isInstanceOf<ParameterElement>());
  }

  test_commentReference_beforeFunctionTypeAlias() async {
    String code = r'''
/// [p]
typedef Foo(int p);
''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    SimpleIdentifier ref =
        EngineTestCase.findSimpleIdentifier(unit, code, 'p]');
    expect(ref.staticElement, new isInstanceOf<ParameterElement>());
  }

  test_commentReference_beforeGetter() async {
    String code = r'''
abstract class A {
  /// [int]
  get g => null;
}''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    {
      SimpleIdentifier ref =
          EngineTestCase.findSimpleIdentifier(unit, code, 'int]');
      expect(ref.staticElement, isNotNull);
    }
  }

  test_commentReference_beforeMethod() async {
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
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
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

  test_commentReference_class() async {
    String code = r'''
/// [foo]
class A {
  foo() {}
}''';
    Source source = addSource(code);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
    SimpleIdentifier ref =
        EngineTestCase.findSimpleIdentifier(unit, code, 'foo]');
    expect(ref.staticElement, new isInstanceOf<MethodElement>());
  }

  test_commentReference_setter() async {
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
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = analysisResult.unit;
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

  test_concreteClassWithAbstractMember() async {
    Source source = addSource(r'''
abstract class A {
  m();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_concreteClassWithAbstractMember_inherited() async {
    Source source = addSource(r'''
class A {
  m() {}
}
class B extends A {
  m();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_conflictingConstructorNameAndMember_setter() async {
    Source source = addSource(r'''
class A {
A.x() {}
set x(_) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_conflictingInstanceGetterAndSuperclassMember_instance() async {
    Source source = addSource(r'''
class A {
  get v => 0;
}
class B extends A {
  get v => 1;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_conflictingStaticGetterAndInstanceSetter_thisClass() async {
    Source source = addSource(r'''
class A {
  static get x => 0;
  static set x(int p) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_conflictingStaticSetterAndInstanceMember_thisClass_method() async {
    Source source = addSource(r'''
class A {
  static x() {}
  static set x(int p) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_const_constructor_with_named_generic_parameter() async {
    Source source = addSource('''
class C<T> {
  const C({T t});
}
const c = const C(t: 1);
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_const_dynamic() async {
    Source source = addSource('''
const Type d = dynamic;
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_const_imported_defaultParameterValue_withImportPrefix() async {
    resetWith(options: new AnalysisOptionsImpl()..strongMode = true);
    Source source = addNamedSource("/a.dart", r'''
import 'b.dart';
const b = const B();
''');
    addNamedSource("/b.dart", r'''
import 'c.dart' as ccc;
class B {
  const B([p = ccc.value]);
}
''');
    addNamedSource("/c.dart", r'''
const int value = 12345;
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constConstructorWithNonConstSuper_explicit() async {
    Source source = addSource(r'''
class A {
  const A();
}
class B extends A {
  const B(): super();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constConstructorWithNonConstSuper_redirectingFactory() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constConstructorWithNonConstSuper_unresolved() async {
    Source source = addSource(r'''
class A {
  A.a();
}
class B extends A {
  const B(): super();
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT]);
    verify([source]);
  }

  test_constConstructorWithNonFinalField_finalInstanceVar() async {
    Source source = addSource(r'''
class A {
  final int x = 0;
  const A();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constConstructorWithNonFinalField_mixin() async {
    Source source = addSource(r'''
class A {
  a() {}
}
class B extends Object with A {
  const B();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN]);
    verify([source]);
  }

  test_constConstructorWithNonFinalField_static() async {
    Source source = addSource(r'''
class A {
  static int x;
  const A();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constConstructorWithNonFinalField_syntheticField() async {
    Source source = addSource(r'''
class A {
  const A();
  set x(value) {}
  get x {return 0;}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constDeferredClass_new() async {
    await resolveWithErrors(<String>[
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

  test_constEval_functionTypeLiteral() async {
    Source source = addSource(r'''
typedef F();
const C = F;''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constEval_propertyExtraction_fieldStatic_targetType() async {
    addNamedSource("/math.dart", r'''
library math;
const PI = 3.14;''');
    Source source = addSource(r'''
import 'math.dart' as math;
const C = math.PI;''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constEval_propertyExtraction_methodStatic_targetType() async {
    Source source = addSource(r'''
class A {
  const A();
  static m() {}
}
const C = A.m;''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constEval_symbol() async {
    addNamedSource("/math.dart", r'''
library math;
const PI = 3.14;''');
    Source source = addSource(r'''
const C = #foo;
foo() {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constEvalThrowsException_assertInitializer_notConst() async {
    resetWith(
        options: new AnalysisOptionsImpl()..enableAssertInitializer = true);
    Source source = addSource(r'''
class A {
  A(int p) : assert(p != 0);
}
var a = new A(0);
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constEvalThrowsException_assertInitializer_true() async {
    resetWith(
        options: new AnalysisOptionsImpl()..enableAssertInitializer = true);
    Source source = addSource(r'''
class A {
  const A(int p) : assert(p != 0);
}
const a = const A(1);
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constEvalTypeBoolNumString_equal() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_constEvalTypeBoolNumString_notEqual() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constEvelTypeNum_String() async {
    Source source = addSource(r'''
const String A = 'a';
const String B = A + 'b';
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constMapKeyExpressionTypeImplementsEquals_abstract() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constNotInitialized_field() async {
    Source source = addSource(r'''
class A {
  static const int x = 0;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constNotInitialized_local() async {
    Source source = addSource(r'''
main() {
  const int x = 0;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constRedirectSkipsSupertype() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constructorDeclaration_scope_signature() async {
    Source source = addSource(r'''
const app = 0;
class A {
  A(@app int app) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constWithNonConstantArgument_constField() async {
    Source source = addSource(r'''
class A {
  const A(x);
}
main() {
  const A(double.INFINITY);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constWithNonConstantArgument_literals() async {
    Source source = addSource(r'''
class A {
  const A(a, b, c, d);
}
f() { return const A(true, 0, 1.0, '2'); }''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constWithTypeParameters_direct() async {
    Source source = addSource(r'''
class A<T> {
  static const V = const A<int>();
  const A();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constWithUndefinedConstructor() async {
    Source source = addSource(r'''
class A {
  const A.name();
}
f() {
  return const A.name();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constWithUndefinedConstructorDefault() async {
    Source source = addSource(r'''
class A {
  const A();
}
f() {
  return const A();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_defaultValueInFunctionTypeAlias() async {
    Source source = addSource("typedef F([x]);");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_defaultValueInFunctionTypedParameter_named() async {
    Source source = addSource("f(g({p})) {}");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_defaultValueInFunctionTypedParameter_optional() async {
    Source source = addSource("f(g([p])) {}");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_deprecatedMemberUse_hide() async {
    Source source = addSource(r'''
library lib;
import 'lib1.dart' hide B;
A a = new A();''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class A {}
@deprecated
class B {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_duplicateDefinition_emptyName() async {
    // Note: This code has two FunctionElements '() {}' with an empty name,
    // this tests that the empty string is not put into the scope
    // (more than once).
    Source source = addSource(r'''
Map _globalMap = {
  'a' : () {},
  'b' : () {}
};''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_duplicateDefinition_getter() async {
    Source source = addSource("bool get a => true;");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_duplicatePart() async {
    addNamedSource('/part1.dart', 'part of lib;');
    addNamedSource('/part2.dart', 'part of lib;');
    Source source = addSource(r'''
library lib;
part 'part1.dart';
part 'part2.dart';
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_dynamicIdentifier() async {
    Source source = addSource(r'''
main() {
  var v = dynamic;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_empty_generator_async() async {
    Source source = addSource('''
import 'dart:async';
Stream<int> f() async* {
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_empty_generator_sync() async {
    Source source = addSource('''
Iterable<int> f() sync* {
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_expectedOneListTypeArgument() async {
    Source source = addSource(r'''
main() {
  <int> [];
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_expectedTwoMapTypeArguments() async {
    Source source = addSource(r'''
main() {
  <int, int> {};
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_exportDuplicatedLibraryUnnamed() async {
    Source source = addSource(r'''
library test;
export 'lib1.dart';
export 'lib2.dart';''');
    addNamedSource("/lib1.dart", "");
    addNamedSource("/lib2.dart", "");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_exportOfNonLibrary_libraryDeclared() async {
    Source source = addSource(r'''
library L;
export 'lib1.dart';''');
    addNamedSource("/lib1.dart", "library lib1;");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_exportOfNonLibrary_libraryNotDeclared() async {
    Source source = addSource(r'''
library L;
export 'lib1.dart';''');
    addNamedSource("/lib1.dart", "");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_extraPositionalArguments_function() async {
    Source source = addSource(r'''
f(p1, p2) {}
main() {
  f(1, 2);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_extraPositionalArguments_Function() async {
    Source source = addSource(r'''
f(Function a) {
  a(1, 2);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_extraPositionalArguments_implicitConstructor() async {
    Source source = addSource(r'''
class A<E extends num> {
  A(E x, E y);
}
class M {}
class B<E extends num> = A<E> with M;
void main() {
   B<int> x = new B<int>(0,0);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_extraPositionalArguments_typedef_local() async {
    Source source = addSource(r'''
typedef A(p1, p2);
A getA() => null;
f() {
  A a = getA();
  a(1, 2);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_extraPositionalArguments_typedef_parameter() async {
    Source source = addSource(r'''
typedef A(p1, p2);
f(A a) {
  a(1, 2);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_fieldFormalParameter_functionTyped_named() async {
    Source source = addSource(r'''
class C {
  final Function field;

  C({String this.field(int value)});
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_fieldInitializedByMultipleInitializers() async {
    Source source = addSource(r'''
class A {
  int x;
  int y;
  A() : x = 0, y = 0 {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_fieldInitializedInInitializerAndDeclaration_fieldNotFinal() async {
    Source source = addSource(r'''
class A {
  int x = 0;
  A() : x = 1 {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_fieldInitializedInInitializerAndDeclaration_finalFieldNotSet() async {
    Source source = addSource(r'''
class A {
  final int x;
  A() : x = 1 {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_fieldInitializerOutsideConstructor() async {
    Source source = addSource(r'''
class A {
  int x;
  A(this.x) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_fieldInitializerOutsideConstructor_defaultParameters() async {
    Source source = addSource(r'''
class A {
  int x;
  A([this.x]) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_fieldInitializerRedirectingConstructor_super() async {
    Source source = addSource(r'''
class A {
  A() {}
}
class B extends A {
  int x;
  B(this.x) : super();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_finalInitializedInDeclarationAndConstructor_initializer() async {
    Source source = addSource(r'''
class A {
  final x;
  A() : x = 1 {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_finalInitializedInDeclarationAndConstructor_initializingFormal() async {
    Source source = addSource(r'''
class A {
  final x;
  A(this.x) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_finalNotInitialized_atDeclaration() async {
    Source source = addSource(r'''
class A {
  final int x = 0;
  A() {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_finalNotInitialized_fieldFormal() async {
    Source source = addSource(r'''
class A {
  final int x = 0;
  A() {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_finalNotInitialized_functionTypedFieldFormal() async {
    Source source = addSource(r'''
class A {
  final Function x;
  A(int this.x(int p)) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_finalNotInitialized_hasNativeClause_hasConstructor() async {
    Source source = addSource(r'''
class A native 'something' {
  final int x;
  A() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.NATIVE_CLAUSE_IN_NON_SDK_CODE]);
    verify([source]);
  }

  test_finalNotInitialized_hasNativeClause_noConstructor() async {
    Source source = addSource(r'''
class A native 'something' {
  final int x;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.NATIVE_CLAUSE_IN_NON_SDK_CODE]);
    verify([source]);
  }

  test_finalNotInitialized_initializer() async {
    Source source = addSource(r'''
class A {
  final int x;
  A() : x = 0 {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_finalNotInitialized_redirectingConstructor() async {
    Source source = addSource(r'''
class A {
  final int x;
  A(this.x);
  A.named() : this (42);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_functionDeclaration_scope_returnType() async {
    Source source = addSource("int f(int) { return 0; }");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_functionDeclaration_scope_signature() async {
    Source source = addSource(r'''
const app = 0;
f(@app int app) {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_functionTypeAlias_scope_returnType() async {
    Source source = addSource("typedef int f(int);");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_functionTypeAlias_scope_signature() async {
    Source source = addSource(r'''
const app = 0;
typedef int f(@app int app);''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_functionWithoutCall() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_functionWithoutCall_doesNotImplementFunction() async {
    Source source = addSource("class A {}");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_functionWithoutCall_staticCallMethod() async {
    Source source = addSource(r'''
class A { }
class B extends A {
  static call() { }
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_functionWithoutCall_withNoSuchMethod() async {
    // 16078
    Source source = addSource(r'''
class A implements Function {
  noSuchMethod(inv) {
    return 42;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_functionWithoutCall_withNoSuchMethod_mixin() async {
    Source source = addSource(r'''
class A {
  noSuchMethod(inv) {}
}
class B extends Object with A implements Function {
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_functionWithoutCall_withNoSuchMethod_superclass() async {
    Source source = addSource(r'''
class A {
  noSuchMethod(inv) {}
}
class B extends A implements Function {
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_genericTypeAlias_castsAndTypeChecks_hasTypeParameters() async {
    Source source = addSource('''
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_genericTypeAlias_castsAndTypeChecks_noTypeParameters() async {
    Source source = addSource('''
typedef Foo = T Function<T>(T x);

main(Object p) {
  (p as Foo)<int>(3);
  if (p is Foo) {
    p<int>(3);
  }
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_genericTypeAlias_fieldAndReturnType_noTypeParameters() async {
    Source source = addSource(r'''
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_genericTypeAlias_fieldAndReturnType_typeParameters_arguments() async {
    Source source = addSource(r'''
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_genericTypeAlias_fieldAndReturnType_typeParameters_noArguments() async {
    Source source = addSource(r'''
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_genericTypeAlias_invalidGenericFunctionType() async {
    Source source = addSource('''
typedef F = int;
main(p) {
  p is F;
}
''');
    await computeAnalysisResult(source);
    // There is a parse error, but no crashes.
    assertErrors(source, [ParserErrorCode.INVALID_GENERIC_FUNCTION_TYPE]);
    verify([source]);
  }

  test_genericTypeAlias_noTypeParameters() async {
    Source source = addSource(r'''
typedef Foo = int Function<T>(T x);
int foo<T>(T x) => 3;
void test1() {
  Foo y = foo;
  // These two should be equivalent
  foo<String>("hello");
  y<String>("hello");
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_genericTypeAlias_typeParameters() async {
    Source source = addSource(r'''
typedef Foo<S> = S Function<T>(T x);
int foo<T>(T x) => 3;
void test1() {
  Foo<int> y = foo;
  // These two should be equivalent
  foo<String>("hello");
  y<String>("hello");
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_implicitConstructorDependencies() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_implicitThisReferenceInInitializer_constructorName() async {
    Source source = addSource(r'''
class A {
  A.named() {}
}
class B {
  var v;
  B() : v = new A.named();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_implicitThisReferenceInInitializer_prefixedIdentifier() async {
    Source source = addSource(r'''
class A {
  var f;
}
class B {
  var v;
  B(A a) : v = a.f;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_implicitThisReferenceInInitializer_qualifiedMethodInvocation() async {
    Source source = addSource(r'''
class A {
  f() {}
}
class B {
  var v;
  B() : v = new A().f();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_implicitThisReferenceInInitializer_qualifiedPropertyAccess() async {
    Source source = addSource(r'''
class A {
  var f;
}
class B {
  var v;
  B() : v = new A().f;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_implicitThisReferenceInInitializer_staticField_thisClass() async {
    Source source = addSource(r'''
class A {
  var v;
  A() : v = f;
  static var f;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_implicitThisReferenceInInitializer_staticGetter() async {
    Source source = addSource(r'''
class A {
  var v;
  A() : v = f;
  static get f => 42;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_implicitThisReferenceInInitializer_staticMethod() async {
    Source source = addSource(r'''
class A {
  var v;
  A() : v = f();
  static f() => 42;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_implicitThisReferenceInInitializer_topLevelField() async {
    Source source = addSource(r'''
class A {
  var v;
  A() : v = f;
}
var f = 42;''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_implicitThisReferenceInInitializer_topLevelFunction() async {
    Source source = addSource(r'''
class A {
  var v;
  A() : v = f();
}
f() => 42;''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_implicitThisReferenceInInitializer_topLevelGetter() async {
    Source source = addSource(r'''
class A {
  var v;
  A() : v = f;
}
get f => 42;''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_implicitThisReferenceInInitializer_typeParameter() async {
    Source source = addSource(r'''
class A<T> {
  var v;
  A(p) : v = (p is T);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_importDuplicatedLibraryName() async {
    Source source = addSource(r'''
library test;
import 'lib.dart';
import 'lib.dart';''');
    addNamedSource("/lib.dart", "library lib;");
    await computeAnalysisResult(source);
    assertErrors(source, [
      HintCode.UNUSED_IMPORT,
      HintCode.UNUSED_IMPORT,
      HintCode.DUPLICATE_IMPORT
    ]);
    verify([source]);
  }

  test_importDuplicatedLibraryUnnamed() async {
    Source source = addSource(r'''
library test;
import 'lib1.dart';
import 'lib2.dart';''');
    addNamedSource("/lib1.dart", "");
    addNamedSource("/lib2.dart", "");
    await computeAnalysisResult(source);
    assertErrors(source, [
      // No warning on duplicate import (https://github.com/dart-lang/sdk/issues/24156)
      HintCode.UNUSED_IMPORT,
      HintCode.UNUSED_IMPORT
    ]);
    verify([source]);
  }

  test_importOfNonLibrary_libraryDeclared() async {
    Source source = addSource(r'''
library lib;
import 'part.dart';
A a;''');
    addNamedSource("/part.dart", r'''
library lib1;
class A {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_importOfNonLibrary_libraryNotDeclared() async {
    Source source = addSource(r'''
library lib;
import 'part.dart';
A a;''');
    addNamedSource("/part.dart", "class A {}");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_importPrefixes_withFirstLetterDifference() async {
    Source source = addSource(r'''
library L;
import 'lib1.dart' as math;
import 'lib2.dart' as path;
main() {
  math.test1();
  path.test2();
}''');
    addNamedSource("/lib1.dart", r'''
library lib1;
test1() {}''');
    addNamedSource("/lib2.dart", r'''
library lib2;
test2() {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_inconsistentCaseExpressionTypes() async {
    Source source = addSource(r'''
f(var p) {
  switch (p) {
    case 1:
      break;
    case 2:
      break;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_inconsistentMethodInheritance_accessors_typeParameter2() async {
    Source source = addSource(r'''
abstract class A<E> {
  E get x {return null;}
}
class B<E> {
  E get x {return null;}
}
class C<E> extends A<E> implements B<E> {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_inconsistentMethodInheritance_accessors_typeParameters1() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_inconsistentMethodInheritance_accessors_typeParameters_diamond() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_inconsistentMethodInheritance_methods_typeParameter2() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_inconsistentMethodInheritance_methods_typeParameters1() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_inconsistentMethodInheritance_overrideTrumpsInherits_getter() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_inconsistentMethodInheritance_overrideTrumpsInherits_method() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_inconsistentMethodInheritance_overrideTrumpsInherits_setter() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_inconsistentMethodInheritance_simple() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_initializingFormalForNonExistentField() async {
    Source source = addSource(r'''
class A {
  int x;
  A(this.x) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_instance_creation_inside_annotation() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_instanceAccessToStaticMember_fromComment() async {
    Source source = addSource(r'''
class A {
  static m() {}
}
/// [A.m]
main() {
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_instanceAccessToStaticMember_topLevel() async {
    Source source = addSource(r'''
m() {}
main() {
  m();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_instanceMemberAccessFromStatic_fromComment() async {
    Source source = addSource(r'''
class A {
  m() {}
  /// [m]
  static foo() {
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_instanceMethodNameCollidesWithSuperclassStatic_field() async {
    Source source = addSource(r'''
import 'lib.dart';
class B extends A {
  _m() {}
}''');
    addNamedSource("/lib.dart", r'''
library L;
class A {
  static var _m;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_instanceMethodNameCollidesWithSuperclassStatic_method() async {
    Source source = addSource(r'''
import 'lib.dart';
class B extends A {
  _m() {}
}''');
    addNamedSource("/lib.dart", r'''
library L;
class A {
  static _m() {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidAnnotation_constantVariable_field() async {
    Source source = addSource(r'''
@A.C
class A {
  static const C = 0;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidAnnotation_constantVariable_field_importWithPrefix() async {
    addNamedSource("/lib.dart", r'''
library lib;
class A {
  static const C = 0;
}''');
    Source source = addSource(r'''
import 'lib.dart' as p;
@p.A.C
main() {
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidAnnotation_constantVariable_topLevel() async {
    Source source = addSource(r'''
const C = 0;
@C
main() {
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidAnnotation_constantVariable_topLevel_importWithPrefix() async {
    addNamedSource("/lib.dart", r'''
library lib;
const C = 0;''');
    Source source = addSource(r'''
import 'lib.dart' as p;
@p.C
main() {
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidAnnotation_constConstructor_importWithPrefix() async {
    addNamedSource("/lib.dart", r'''
library lib;
class A {
  const A(int p);
}''');
    Source source = addSource(r'''
import 'lib.dart' as p;
@p.A(42)
main() {
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidAnnotation_constConstructor_named_importWithPrefix() async {
    addNamedSource("/lib.dart", r'''
library lib;
class A {
  const A.named(int p);
}''');
    Source source = addSource(r'''
import 'lib.dart' as p;
@p.A.named(42)
main() {
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidAssignment() async {
    Source source = addSource(r'''
f() {
  var x;
  var y;
  x = y;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidAssignment_compoundAssignment() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidAssignment_defaultValue_named() async {
    Source source = addSource(r'''
f({String x: '0'}) {
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidAssignment_defaultValue_optional() async {
    Source source = addSource(r'''
f([String x = '0']) {
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidAssignment_ifNullAssignment_compatibleType() async {
    Source source = addSource('''
void f(int i) {
  num n;
  n ??= i;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidAssignment_ifNullAssignment_sameType() async {
    Source source = addSource('''
void f(int i) {
  int j;
  j ??= i;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidAssignment_implicitlyImplementFunctionViaCall_1() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidAssignment_implicitlyImplementFunctionViaCall_2() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidAssignment_implicitlyImplementFunctionViaCall_3() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
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
    Source source = addSource(r'''
class I {
  int call([int x]) => 0;
}
class C implements I {
  noSuchMethod(_) => null;
}
typedef int VoidToInt();
VoidToInt f = new C();''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidAssignment_toDynamic() async {
    Source source = addSource(r'''
f() {
  var g;
  g = () => 0;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidFactoryNameNotAClass() async {
    Source source = addSource(r'''
class A {
  factory A() => null;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidIdentifierInAsync() async {
    Source source = addSource(r'''
class A {
  m() {
    int async;
    int await;
    int yield;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidMethodOverrideNamedParamType() async {
    Source source = addSource(r'''
class A {
  m({int a}) {}
}
class B implements A {
  m({int a, int b}) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidOverrideDifferentDefaultValues_named() async {
    Source source = addSource(r'''
class A {
  m({int p : 0}) {}
}
class B extends A {
  m({int p : 0}) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidOverrideDifferentDefaultValues_named_function() async {
    Source source = addSource(r'''
nothing() => 'nothing';
class A {
  thing(String a, {orElse : nothing}) {}
}
class B extends A {
  thing(String a, {orElse : nothing}) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidOverrideDifferentDefaultValues_positional() async {
    Source source = addSource(r'''
class A {
  m([int p = 0]) {}
}
class B extends A {
  m([int p = 0]) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidOverrideDifferentDefaultValues_positional_changedOrder() async {
    Source source = addSource(r'''
class A {
  m([int a = 0, String b = '0']) {}
}
class B extends A {
  m([int b = 0, String a = '0']) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidOverrideDifferentDefaultValues_positional_function() async {
    Source source = addSource(r'''
nothing() => 'nothing';
class A {
  thing(String a, [orElse = nothing]) {}
}
class B extends A {
  thing(String a, [orElse = nothing]) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidOverrideNamed_unorderedNamedParameter() async {
    Source source = addSource(r'''
class A {
  m({a, b}) {}
}
class B extends A {
  m({b, a}) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidOverrideRequired_less() async {
    Source source = addSource(r'''
class A {
  m(a, b) {}
}
class B extends A {
  m(a, [b]) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidOverrideRequired_same() async {
    Source source = addSource(r'''
class A {
  m(a) {}
}
class B extends A {
  m(a) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidOverrideReturnType_returnType_interface() async {
    Source source = addNamedSource("/test.dart", r'''
abstract class A {
  num m();
}
class B implements A {
  int m() { return 1; }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidOverrideReturnType_returnType_interface2() async {
    Source source = addNamedSource("/test.dart", r'''
abstract class A {
  num m();
}
abstract class B implements A {
}
class C implements B {
  int m() { return 1; }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidOverrideReturnType_returnType_mixin() async {
    Source source = addNamedSource("/test.dart", r'''
class A {
  num m() { return 0; }
}
class B extends Object with A {
  int m() { return 1; }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidOverrideReturnType_returnType_parameterizedTypes() async {
    Source source = addSource(r'''
abstract class A<E> {
  List<E> m();
}
class B extends A<dynamic> {
  List<dynamic> m() { return new List<dynamic>(); }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidOverrideReturnType_returnType_sameType() async {
    Source source = addNamedSource("/test.dart", r'''
class A {
  int m() { return 0; }
}
class B extends A {
  int m() { return 1; }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidOverrideReturnType_returnType_superclass() async {
    Source source = addNamedSource("/test.dart", r'''
class A {
  num m() { return 0; }
}
class B extends A {
  int m() { return 1; }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidOverrideReturnType_returnType_superclass2() async {
    Source source = addNamedSource("/test.dart", r'''
class A {
  num m() { return 0; }
}
class B extends A {
}
class C extends B {
  int m() { return 1; }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidOverrideReturnType_returnType_void() async {
    Source source = addSource(r'''
class A {
  void m() {}
}
class B extends A {
  int m() { return 0; }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidReferenceToThis_constructor() async {
    Source source = addSource(r'''
class A {
  A() {
    var v = this;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidReferenceToThis_instanceMethod() async {
    Source source = addSource(r'''
class A {
  m() {
    var v = this;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidTypeArgumentForKey() async {
    Source source = addSource(r'''
class A {
  m() {
    return const <int, int>{};
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidTypeArgumentInConstList() async {
    Source source = addSource(r'''
class A<E> {
  m() {
    return <E>[];
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invalidTypeArgumentInConstMap() async {
    Source source = addSource(r'''
class A<E> {
  m() {
    return <String, E>{};
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invocationOfNonFunction_dynamic() async {
    Source source = addSource(r'''
class A {
  var f;
}
class B extends A {
  g() {
    f();
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invocationOfNonFunction_functionTypeTypeParameter() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invocationOfNonFunction_getter() async {
    Source source = addSource(r'''
class A {
  var g;
}
f() {
  A a;
  a.g();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invocationOfNonFunction_localVariable() async {
    Source source = addSource(r'''
f() {
  var g;
  g();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invocationOfNonFunction_localVariable_dynamic() async {
    Source source = addSource(r'''
f() {}
main() {
  var v = f;
  v();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invocationOfNonFunction_localVariable_dynamic2() async {
    Source source = addSource(r'''
f() {}
main() {
  var v = f;
  v = 1;
  v();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invocationOfNonFunction_Object() async {
    Source source = addSource(r'''
main() {
  Object v = null;
  v();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_invocationOfNonFunction_proxyOnFunctionClass() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_issue_24191() async {
    Source source = addSource('''
import 'dart:async';

abstract class S extends Stream {}
f(S s) async {
  await for (var v in s) {
    print(v);
  }
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_listElementTypeNotAssignable() async {
    Source source = addSource(r'''
var v1 = <int> [42];
var v2 = const <int> [42];''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_loadLibraryDefined() async {
    await resolveWithErrors(<String>[
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

  test_local_generator_async() async {
    Source source = addSource('''
f() {
  return () async* { yield 0; };
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_local_generator_sync() async {
    Source source = addSource('''
f() {
  return () sync* { yield 0; };
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_mapKeyTypeNotAssignable() async {
    Source source = addSource("var v = <String, int > {'a' : 1};");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_memberWithClassName_setter() async {
    Source source = addSource(r'''
class A {
  set A(v) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_methodDeclaration_scope_signature() async {
    Source source = addSource(r'''
const app = 0;
class A {
  foo(@app int app) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_misMatchedGetterAndSetterTypes_instance_sameTypes() async {
    Source source = addSource(r'''
class C {
  int get x => 0;
  set x(int v) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_misMatchedGetterAndSetterTypes_instance_unspecifiedGetter() async {
    Source source = addSource(r'''
class C {
  get x => 0;
  set x(String v) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_misMatchedGetterAndSetterTypes_instance_unspecifiedSetter() async {
    Source source = addSource(r'''
class C {
  int get x => 0;
  set x(v) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_misMatchedGetterAndSetterTypes_topLevel_sameTypes() async {
    Source source = addSource(r'''
int get x => 0;
set x(int v) {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_misMatchedGetterAndSetterTypes_topLevel_unspecifiedGetter() async {
    Source source = addSource(r'''
get x => 0;
set x(String v) {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_misMatchedGetterAndSetterTypes_topLevel_unspecifiedSetter() async {
    Source source = addSource(r'''
int get x => 0;
set x(v) {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_missingEnumConstantInSwitch_all() async {
    Source source = addSource(r'''
enum E { A, B, C }

f(E e) {
  switch (e) {
    case E.A: break;
    case E.B: break;
    case E.C: break;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_missingEnumConstantInSwitch_default() async {
    Source source = addSource(r'''
enum E { A, B, C }

f(E e) {
  switch (e) {
    case E.B: break;
    default: break;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_mixedReturnTypes_differentScopes() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_mixedReturnTypes_ignoreImplicit() async {
    Source source = addSource(r'''
f(bool p) {
  if (p) return 42;
  // implicit 'return;' is ignored
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_mixedReturnTypes_ignoreImplicit2() async {
    Source source = addSource(r'''
f(bool p) {
  if (p) {
    return 42;
  } else {
    return 42;
  }
  // implicit 'return;' is ignored
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_mixedReturnTypes_sameKind() async {
    Source source = addSource(r'''
class C {
  m(int x) {
    if (x < 0) {
      return 1;
    }
    return 0;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_mixinDeclaresConstructor() async {
    Source source = addSource(r'''
class A {
  m() {}
}
class B extends Object with A {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_mixinDeclaresConstructor_factory() async {
    Source source = addSource(r'''
class A {
  factory A() => null;
}
class B extends Object with A {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_mixinInheritsFromNotObject_classDeclaration_extends() async {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.enableSuperMixins = true;
    resetWith(options: options);
    Source source = addSource(r'''
class A {}
class B extends A {}
class C extends Object with B {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_mixinInheritsFromNotObject_classDeclaration_mixTypeAlias() async {
    Source source = addSource(r'''
class A {}
class B = Object with A;
class C extends Object with B {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_mixinInheritsFromNotObject_classDeclaration_with() async {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.enableSuperMixins = true;
    resetWith(options: options);
    Source source = addSource(r'''
class A {}
class B extends Object with A {}
class C extends Object with B {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_mixinInheritsFromNotObject_typeAlias_extends() async {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.enableSuperMixins = true;
    resetWith(options: options);
    Source source = addSource(r'''
class A {}
class B extends A {}
class C = Object with B;''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_mixinInheritsFromNotObject_typeAlias_with() async {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.enableSuperMixins = true;
    resetWith(options: options);
    Source source = addSource(r'''
class A {}
class B extends Object with A {}
class C = Object with B;''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_mixinInheritsFromNotObject_typedef_mixTypeAlias() async {
    Source source = addSource(r'''
class A {}
class B = Object with A;
class C = Object with B;''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_mixinReferencesSuper() async {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.enableSuperMixins = true;
    resetWith(options: options);
    Source source = addSource(r'''
class A {
  toString() => super.toString();
}
class B extends Object with A {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_multipleSuperInitializers_no() async {
    Source source = addSource(r'''
class A {}
class B extends A {
  B() {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_multipleSuperInitializers_single() async {
    Source source = addSource(r'''
class A {}
class B extends A {
  B() : super() {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nativeConstConstructor() async {
    Source source = addSource(r'''
import 'dart-ext:x';
class Foo {
  const Foo() native 'Foo_Foo';
  const factory Foo.foo() native 'Foo_Foo_foo';
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    // Cannot verify the AST because the import's URI cannot be resolved.
  }

  test_nativeFunctionBodyInNonSDKCode_function() async {
    Source source = addSource(r'''
import 'dart-ext:x';
int m(a) native 'string';''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    // Cannot verify the AST because the import's URI cannot be resolved.
  }

  test_newWithAbstractClass_factory() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_newWithUndefinedConstructor() async {
    Source source = addSource(r'''
class A {
  A.name() {}
}
f() {
  new A.name();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_newWithUndefinedConstructorDefault() async {
    Source source = addSource(r'''
class A {
  A() {}
}
f() {
  new A();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_abstractsDontOverrideConcretes_getter() async {
    Source source = addSource(r'''
class A {
  int get g => 0;
}
abstract class B extends A {
  int get g;
}
class C extends B {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_abstractsDontOverrideConcretes_method() async {
    Source source = addSource(r'''
class A {
  m(p) {}
}
abstract class B extends A {
  m(p);
}
class C extends B {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_abstractsDontOverrideConcretes_setter() async {
    Source source = addSource(r'''
class A {
  set s(v) {}
}
abstract class B extends A {
  set s(v);
}
class C extends B {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_interface() async {
    // 15979
    Source source = addSource(r'''
abstract class M {}
abstract class A {}
abstract class I {
  m();
}
abstract class B = A with M implements I;''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_mixin() async {
    // 15979
    Source source = addSource(r'''
abstract class M {
  m();
}
abstract class A {}
abstract class B = A with M;''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_classTypeAlias_superclass() async {
    // 15979
    Source source = addSource(r'''
class M {}
abstract class A {
  m();
}
abstract class B = A with M;''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_mixin_getter() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_mixin_method() async {
    Source source = addSource(r'''
class A {
  m() {}
}
abstract class M {
  m();
}
class B extends A with M {}
class C extends B {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_mixin_setter() async {
    Source source = addSource(r'''
class A {
  var a;
}
abstract class M {
  set a(dynamic v);
}
class B extends A with M {}
class C extends B {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_noSuchMethod_accessor() async {
    Source source = addSource(r'''
abstract class A {
  int get g;
}
class B extends A {
  noSuchMethod(v) => '';
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_noSuchMethod_method() async {
    Source source = addSource(r'''
abstract class A {
  m(p);
}
class B extends A {
  noSuchMethod(v) => '';
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_noSuchMethod_mixin() async {
    Source source = addSource(r'''
class A {
  noSuchMethod(v) => '';
}
class B extends Object with A {
  m(p);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_noSuchMethod_superclass() async {
    Source source = addSource(r'''
class A {
  noSuchMethod(v) => '';
}
class B extends A {
  m(p);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonAbstractClassInheritsAbstractMemberOne_overridesMethodInObject() async {
    Source source = addSource(r'''
class A {
  String toString([String prefix = '']) => '${prefix}Hello';
}
class C {}
class B extends A with C {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonBoolExpression_functionType() async {
    Source source = addSource(r'''
bool makeAssertion() => true;
f() {
  assert(makeAssertion);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonBoolExpression_interfaceType() async {
    Source source = addSource(r'''
f() {
  assert(true);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonBoolNegationExpression() async {
    Source source = addSource(r'''
f(bool pb, pd) {
  !true;
  !false;
  !pb;
  !pd;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonBoolNegationExpression_dynamic() async {
    Source source = addSource(r'''
f1(bool dynamic) {
  !dynamic;
}
f2() {
  bool dynamic = true;
  !dynamic;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonBoolOperand_and_bool() async {
    Source source = addSource(r'''
bool f(bool left, bool right) {
  return left && right;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonBoolOperand_and_dynamic() async {
    Source source = addSource(r'''
bool f(left, dynamic right) {
  return left && right;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonBoolOperand_or_bool() async {
    Source source = addSource(r'''
bool f(bool left, bool right) {
  return left || right;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonBoolOperand_or_dynamic() async {
    Source source = addSource(r'''
bool f(dynamic left, right) {
  return left || right;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonConstantDefaultValue_constField() async {
    Source source = addSource(r'''
f([a = double.INFINITY]) {
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonConstantDefaultValue_function_named() async {
    Source source = addSource("f({x : 2 + 3}) {}");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonConstantDefaultValue_function_positional() async {
    Source source = addSource("f([x = 2 + 3]) {}");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonConstantDefaultValue_inConstructor_named() async {
    Source source = addSource(r'''
class A {
  A({x : 2 + 3}) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonConstantDefaultValue_inConstructor_positional() async {
    Source source = addSource(r'''
class A {
  A([x = 2 + 3]) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonConstantDefaultValue_method_named() async {
    Source source = addSource(r'''
class A {
  m({x : 2 + 3}) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonConstantDefaultValue_method_positional() async {
    Source source = addSource(r'''
class A {
  m([x = 2 + 3]) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonConstantDefaultValue_typedConstList() async {
    Source source = addSource(r'''
class A {
  m([p111 = const <String>[]]) {}
}
class B extends A {
  m([p222 = const <String>[]]) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonConstantValueInInitializer_namedArgument() async {
    Source source = addSource(r'''
class A {
  final a;
  const A({this.a});
}
class B extends A {
  const B({b}) : super(a: b);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonConstCaseExpression_constField() async {
    Source source = addSource(r'''
f(double p) {
  switch (p) {
    case double.INFINITY:
      return true;
    default:
      return false;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS]);
    verify([source]);
  }

  test_nonConstCaseExpression_typeLiteral() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonConstListElement_constField() async {
    Source source = addSource(r'''
main() {
  const [double.INFINITY];
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonConstMapAsExpressionStatement_const() async {
    Source source = addSource(r'''
f() {
  const {'a' : 0, 'b' : 1};
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonConstMapAsExpressionStatement_notExpressionStatement() async {
    Source source = addSource(r'''
f() {
  var m = {'a' : 0, 'b' : 1};
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonConstMapAsExpressionStatement_typeArguments() async {
    Source source = addSource(r'''
f() {
  <String, int> {'a' : 0, 'b' : 1};
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonConstMapKey_constField() async {
    Source source = addSource(r'''
main() {
  const {double.INFINITY: 0};
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS]);
    verify([source]);
  }

  test_nonConstMapValue_constField() async {
    Source source = addSource(r'''
main() {
  const {0: double.INFINITY};
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonConstValueInInitializer_binary_bool() async {
    Source source = addSource(r'''
class A {
  final v;
  const A.a1(bool p) : v = p && true;
  const A.a2(bool p) : v = true && p;
  const A.b1(bool p) : v = p || true;
  const A.b2(bool p) : v = true || p;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  test_nonConstValueInInitializer_binary_dynamic() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    // operations on "p" are not resolved
  }

  test_nonConstValueInInitializer_binary_int() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonConstValueInInitializer_binary_num() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonConstValueInInitializer_field() async {
    Source source = addSource(r'''
class A {
  final int a;
  const A() : a = 5;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonConstValueInInitializer_redirecting() async {
    Source source = addSource(r'''
class A {
  const A.named(p);
  const A() : this.named(42);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonConstValueInInitializer_super() async {
    Source source = addSource(r'''
class A {
  const A(p);
}
class B extends A {
  const B() : super(42);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonConstValueInInitializer_unary() async {
    Source source = addSource(r'''
class A {
  final v;
  const A.a(bool p) : v = !p;
  const A.b(int p) : v = ~p;
  const A.c(num p) : v = -p;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonGenerativeConstructor() async {
    Source source = addSource(r'''
class A {
  A.named() {}
  factory A() => null;
}
class B extends A {
  B() : super.named();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonTypeInCatchClause_isClass() async {
    Source source = addSource(r'''
f() {
  try {
  } on String catch (e) {
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonTypeInCatchClause_isFunctionTypeAlias() async {
    Source source = addSource(r'''
typedef F();
f() {
  try {
  } on F catch (e) {
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonTypeInCatchClause_isTypeParameter() async {
    Source source = addSource(r'''
class A<T> {
  f() {
    try {
    } on T catch (e) {
    }
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonTypeInCatchClause_noType() async {
    Source source = addSource(r'''
f() {
  try {
  } catch (e) {
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonVoidReturnForOperator_no() async {
    Source source = addSource(r'''
class A {
  operator []=(a, b) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonVoidReturnForOperator_void() async {
    Source source = addSource(r'''
class A {
  void operator []=(a, b) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonVoidReturnForSetter_function_no() async {
    Source source = addSource("set x(v) {}");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonVoidReturnForSetter_function_void() async {
    Source source = addSource("void set x(v) {}");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonVoidReturnForSetter_method_no() async {
    Source source = addSource(r'''
class A {
  set x(v) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_nonVoidReturnForSetter_method_void() async {
    Source source = addSource(r'''
class A {
  void set x(v) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_null_callMethod() async {
    Source source = addSource(r'''
main() {
  null.m();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_null_callOperator() async {
    Source source = addSource(r'''
main() {
  null + 5;
  null == 5;
  null[0];
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_optionalParameterInOperator_required() async {
    Source source = addSource(r'''
class A {
  operator +(p) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_parameterDefaultDoesNotReferToParameterName() async {
    // The final "f" should refer to the toplevel function "f", not to the
    // parameter called "f".  See dartbug.com/13179.
    Source source = addSource('void f([void f([x]) = f]) {}');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_parameterScope_local() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_parameterScope_method() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_parameterScope_toplevel() async {
    // Parameter names shouldn't conflict with the name of the function they
    // are enclosed in.
    Source source = addSource(r'''
g(g) {
  h(g);
}
h(x) {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_prefixCollidesWithTopLevelMembers() async {
    addNamedSource("/lib.dart", r'''
library lib;
class A {}''');
    Source source = addSource(r'''
import 'lib.dart' as p;
typedef P();
p2() {}
var p3;
class p4 {}
p.A a;''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_propagateTypeArgs_intoBounds() async {
    Source source = addSource(r'''
abstract class A<E> {}
abstract class B<F> implements A<F>{}
abstract class C<G, H extends A<G>> {}
class D<I> extends C<I, B<I>> {}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_propagateTypeArgs_intoSupertype() async {
    Source source = addSource(r'''
class A<T> {
  A(T p);
  A.named(T p);
}
class B<S> extends A<S> {
  B(S p) : super(p);
  B.named(S p) : super.named(p);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_proxy_annotation_prefixed() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_proxy_annotation_prefixed2() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_proxy_annotation_prefixed3() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_proxy_annotation_proxyHasPrefixedIdentifier() async {
    Source source = addSource(r'''
library L;
import 'dart:core' as core;
@core.proxy class PrefixProxy {}
main() {
  new PrefixProxy().foo;
  new PrefixProxy().foo();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_proxy_annotation_simple() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_proxy_annotation_superclass() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_proxy_annotation_superclass_mixin() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_proxy_annotation_superinterface() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_proxy_annotation_superinterface_infiniteLoop() async {
    addSource(r'''
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
    // Test is that a stack overflow isn't reached in resolution
    // (previous line), no need to assert error set.
  }

  test_recursiveConstructorRedirect() async {
    Source source = addSource(r'''
class A {
  A.a() : this.b();
  A.b() : this.c();
  A.c() {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_recursiveFactoryRedirect() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_redirectToInvalidFunctionType() async {
    Source source = addSource(r'''
class A implements B {
  A(int p) {}
}
class B {
  factory B(int p) = A;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_redirectToInvalidReturnType() async {
    Source source = addSource(r'''
class A {
  A() {}
}
class B extends A {
  factory B() = A;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_redirectToNonConstConstructor() async {
    Source source = addSource(r'''
class A {
  const A.a();
  const factory A.b() = A.a;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_referencedBeforeDeclaration_cascade() async {
    Source source = addSource(r'''
testRequestHandler() {}

main() {
  var s1 = null;
  testRequestHandler()
    ..stream(s1);
  var stream = 123;
  print(stream);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_referenceToDeclaredVariableInInitializer_constructorName() async {
    Source source = addSource(r'''
class A {
  A.x() {}
}
f() {
  var x = new A.x();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_referenceToDeclaredVariableInInitializer_methodName() async {
    Source source = addSource(r'''
class A {
  x() {}
}
f(A a) {
  var x = a.x();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_referenceToDeclaredVariableInInitializer_propertyName() async {
    Source source = addSource(r'''
class A {
  var x;
}
f(A a) {
  var x = a.x;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_rethrowOutsideCatch() async {
    Source source = addSource(r'''
class A {
  void m() {
    try {} catch (e) {rethrow;}
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_return_in_generator_async() async {
    Source source = addSource('''
import 'dart:async';
Stream<int> f() async* {
  return;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_return_in_generator_sync() async {
    Source source = addSource('''
Iterable<int> f() sync* {
  return;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_returnInGenerativeConstructor() async {
    Source source = addSource(r'''
class A {
  A() { return; }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_returnInGenerator_async() async {
    Source source = addSource(r'''
f() async {
  return 0;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_returnInGenerator_sync() async {
    Source source = addSource(r'''
f() {
  return 0;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_returnOfInvalidType_async() async {
    Source source = addSource(r'''
import 'dart:async';
class A {
  Future<int> m() async {
    return 0;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_returnOfInvalidType_async_future_int_mismatches_future_null() async {
    Source source = addSource(r'''
import 'dart:async';
Future<Null> f() async {
  return 5;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_returnOfInvalidType_dynamic() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_returnOfInvalidType_dynamicAsTypeArgument() async {
    Source source = addSource(r'''
class I<T> {
  factory I() => new A<T>();
}
class A<T> implements I {
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_returnOfInvalidType_subtype() async {
    Source source = addSource(r'''
class A {}
class B extends A {}
A f(B b) { return b; }''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_returnOfInvalidType_supertype() async {
    Source source = addSource(r'''
class A {}
class B extends A {}
B f(A a) { return a; }''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
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
    Source source = addSource(r'''
class Foo<T> {
  Type get t => T;
}''');
    await computeAnalysisResult(source);
    assertErrors(source);
    verify([source]);
  }

  test_returnOfInvalidType_void() async {
    Source source = addSource(r'''
void f1() {}
void f2() { return; }
void f3() { return null; }
void f4() { return g1(); }
void f5() { return g2(); }
void f6() => throw 42;
g1() {}
void g2() {}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_returnWithoutValue_noReturnType() async {
    Source source = addSource("f() { return; }");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_returnWithoutValue_void() async {
    Source source = addSource("void f() { return; }");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_reversedTypeArguments() async {
    Source source = addSource(r'''
class Codec<S1, T1> {
  Codec<T1, S1> get inverted => new _InvertedCodec<T1, S1>(this);
}
class _InvertedCodec<T2, S2> extends Codec<T2, S2> {
  _InvertedCodec(Codec<S2, T2> codec);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_sharedDeferredPrefix() async {
    await resolveWithErrors(<String>[
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

  test_staticAccessToInstanceMember_annotation() async {
    Source source = addSource(r'''
class A {
  const A.name();
}
@A.name()
main() {
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_staticAccessToInstanceMember_method() async {
    Source source = addSource(r'''
class A {
  static m() {}
}
main() {
  A.m;
  A.m();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_staticAccessToInstanceMember_propertyAccess_field() async {
    Source source = addSource(r'''
class A {
  static var f;
}
main() {
  A.f;
  A.f = 1;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_staticAccessToInstanceMember_propertyAccess_propertyAccessor() async {
    Source source = addSource(r'''
class A {
  static get f => 42;
  static set f(x) {}
}
main() {
  A.f;
  A.f = 1;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_superInInvalidContext() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typeAliasCannotReferenceItself_returnClass_withTypeAlias() async {
    Source source = addSource(r'''
typedef B A();
class B {
  A a;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typeArgumentNotMatchingBounds_const() async {
    Source source = addSource(r'''
class A {}
class B extends A {}
class G<E extends A> {
  const G();
}
f() { return const G<B>(); }''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typeArgumentNotMatchingBounds_new() async {
    Source source = addSource(r'''
class A {}
class B extends A {}
class G<E extends A> {}
f() { return new G<B>(); }''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typeArgumentNotMatchingBounds_ofFunctionTypeAlias_hasBound() async {
    Source source = addSource(r'''
class A {}
class B extends A {}
typedef F<T extends A>();
F<A> fa;
F<B> fb;
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typeArgumentNotMatchingBounds_ofFunctionTypeAlias_hasBound2() async {
    Source source = addSource(r'''
class MyClass<T> {}
typedef MyFunction<T, P extends MyClass<T>>();
class A<T, P extends MyClass<T>> {
  MyFunction<T, P> f;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typeArgumentNotMatchingBounds_ofFunctionTypeAlias_noBound() async {
    Source source = addSource(r'''
typedef F<T>();
F<int> f1;
F<String> f2;
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typeArgumentNotMatchingBounds_typeArgumentList_0() async {
    Source source = addSource("abstract class A<T extends A>{}");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typeArgumentNotMatchingBounds_typeArgumentList_1() async {
    Source source = addSource("abstract class A<T extends A<A>>{}");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typeArgumentNotMatchingBounds_typeArgumentList_20() async {
    Source source = addSource(
        "abstract class A<T extends A<A<A<A<A<A<A<A<A<A<A<A<A<A<A<A<A<A<A<A<A>>>>>>>>>>>>>>>>>>>>>{}");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typePromotion_booleanAnd_useInRight() async {
    Source source = addSource(r'''
main(Object p) {
  p is String && p.length != 0;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typePromotion_booleanAnd_useInRight_accessedInClosureRight_noAssignment() async {
    Source source = addSource(r'''
callMe(f()) { f(); }
main(Object p) {
  (p is String) && callMe(() { p.length; });
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typePromotion_conditional_issue14655() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typePromotion_conditional_useInThen() async {
    Source source = addSource(r'''
main(Object p) {
  p is String ? p.length : 0;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typePromotion_conditional_useInThen_accessedInClosure_noAssignment() async {
    Source source = addSource(r'''
callMe(f()) { f(); }
main(Object p) {
  p is String ? callMe(() { p.length; }) : 0;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typePromotion_functionType_arg_ignoreIfNotMoreSpecific() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typePromotion_functionType_return_ignoreIfNotMoreSpecific() async {
    Source source = addSource(r'''
class A {}
typedef FuncAtoDyn(A a);
typedef FuncDynToDyn(x);
main(FuncAtoDyn f) {
  if (f is FuncDynToDyn) {
    A a = f(new A());
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typePromotion_functionType_return_voidToDynamic() async {
    Source source = addSource(r'''
typedef FuncDynToDyn(x);
typedef void FuncDynToVoid(x);
class A {}
main(FuncDynToVoid f) {
  if (f is FuncDynToDyn) {
    A a = f(null);
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typePromotion_if_accessedInClosure_noAssignment() async {
    Source source = addSource(r'''
callMe(f()) { f(); }
main(Object p) {
  if (p is String) {
    callMe(() {
      p.length;
    });
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typePromotion_if_extends_moreSpecific() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typePromotion_if_hasAssignment_outsideAfter() async {
    Source source = addSource(r'''
main(Object p) {
  if (p is String) {
    p.length;
  }
  p = 0;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typePromotion_if_hasAssignment_outsideBefore() async {
    Source source = addSource(r'''
main(Object p, Object p2) {
  p = p2;
  if (p is String) {
    p.length;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typePromotion_if_implements_moreSpecific() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typePromotion_if_inClosure_assignedAfter_inSameFunction() async {
    Source source = addSource(r'''
main() {
  f(Object p) {
    if (p is String) {
      p.length;
    }
    p = 0;
  };
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typePromotion_if_is_and_left() async {
    Source source = addSource(r'''
bool tt() => true;
main(Object p) {
  if (p is String && tt()) {
    p.length;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typePromotion_if_is_and_right() async {
    Source source = addSource(r'''
bool tt() => true;
main(Object p) {
  if (tt() && p is String) {
    p.length;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typePromotion_if_is_and_subThenSuper() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typePromotion_if_is_parenthesized() async {
    Source source = addSource(r'''
main(Object p) {
  if ((p is String)) {
    p.length;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typePromotion_if_is_single() async {
    Source source = addSource(r'''
main(Object p) {
  if (p is String) {
    p.length;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typePromotion_parentheses() async {
    Source source = addSource(r'''
main(Object p) {
  (p is String) ? p.length : 0;
  (p) is String ? p.length : 0;
  ((p)) is String ? p.length : 0;
  ((p) is String) ? p.length : 0;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typeType_class() async {
    Source source = addSource(r'''
class C {}
f(Type t) {}
main() {
  f(C);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typeType_class_prefixed() async {
    addNamedSource("/lib.dart", r'''
library lib;
class C {}''');
    Source source = addSource(r'''
import 'lib.dart' as p;
f(Type t) {}
main() {
  f(p.C);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typeType_functionTypeAlias() async {
    Source source = addSource(r'''
typedef F();
f(Type t) {}
main() {
  f(F);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typeType_functionTypeAlias_prefixed() async {
    addNamedSource("/lib.dart", r'''
library lib;
typedef F();''');
    Source source = addSource(r'''
import 'lib.dart' as p;
f(Type t) {}
main() {
  f(p.F);
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_undefinedConstructorInInitializer_explicit_named() async {
    Source source = addSource(r'''
class A {
  A.named() {}
}
class B extends A {
  B() : super.named();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_undefinedConstructorInInitializer_explicit_unnamed() async {
    Source source = addSource(r'''
class A {
  A() {}
}
class B extends A {
  B() : super();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_undefinedConstructorInInitializer_hasOptionalParameters() async {
    Source source = addSource(r'''
class A {
  A([p]) {}
}
class B extends A {
  B();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_undefinedConstructorInInitializer_implicit() async {
    Source source = addSource(r'''
class A {
  A() {}
}
class B extends A {
  B();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_undefinedConstructorInInitializer_implicit_typeAlias() async {
    Source source = addSource(r'''
class M {}
class A = Object with M;
class B extends A {
  B();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_undefinedConstructorInInitializer_redirecting() async {
    Source source = addSource(r'''
class Foo {
  Foo.ctor();
}
class Bar extends Foo {
  Bar() : this.ctor();
  Bar.ctor() : super.ctor();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_undefinedGetter_static_conditionalAccess() async {
    // The conditional access operator '?.' can be used to access static
    // fields.
    Source source = addSource('''
class A {
  static var x;
}
var a = A?.x;
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_undefinedGetter_typeSubstitution() async {
    Source source = addSource(r'''
class A<E> {
  E element;
}
class B extends A<List> {
  m() {
    element.last;
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_undefinedIdentifier_synthetic_whenExpression() async {
    Source source = addSource(r'''
print(x) {}
main() {
  print(is String);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.MISSING_IDENTIFIER]);
  }

  test_undefinedIdentifier_synthetic_whenMethodName() async {
    Source source = addSource(r'''
print(x) {}
main(int p) {
  p.();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.MISSING_IDENTIFIER]);
  }

  test_undefinedMethod_functionExpression_callMethod() async {
    Source source = addSource(r'''
main() {
  (() => null).call();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    // A call to verify(source) fails as '.call()' isn't resolved.
  }

  test_undefinedMethod_functionExpression_directCall() async {
    Source source = addSource(r'''
main() {
  (() => null)();
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    // A call to verify(source) fails as '(() => null)()' isn't resolved.
  }

  test_undefinedMethod_static_conditionalAccess() async {
    // The conditional access operator '?.' can be used to access static
    // methods.
    Source source = addSource('''
class A {
  static void m() {}
}
f() { A?.m(); }
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_undefinedOperator_index() async {
    Source source = addSource(r'''
class A {
  operator [](a) {}
  operator []=(a, b) {}
}
f(A a) {
  a[0];
  a[0] = 1;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_undefinedOperator_tilde() async {
    Source source = addSource(r'''
const A = 3;
const B = ~((1 << A) - 1);''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_undefinedSetter_importWithPrefix() async {
    addNamedSource("/lib.dart", r'''
library lib;
set y(int value) {}''');
    Source source = addSource(r'''
import 'lib.dart' as x;
main() {
  x.y = 0;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_undefinedSetter_static_conditionalAccess() async {
    // The conditional access operator '?.' can be used to access static
    // fields.
    Source source = addSource('''
class A {
  static var x;
}
f() { A?.x = 1; }
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_undefinedSuperMethod_field() async {
    Source source = addSource(r'''
class A {
  var m;
}
class B extends A {
  f() {
    super.m();
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_undefinedSuperMethod_method() async {
    Source source = addSource(r'''
class A {
  m() {}
}
class B extends A {
  f() {
    super.m();
  }
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unqualifiedReferenceToNonLocalStaticMember_fromComment_new() async {
    Source source = addSource(r'''
class A {
  A() {}
  A.named() {}
}
/// [new A] or [new A.named]
main() {
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_unusedShownName_unresolved() async {
    Source source = addSource(r'''
import 'dart:math' show max, FooBar;
main() {
  print(max(1, 2));
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNDEFINED_SHOWN_NAME]);
  }

  test_uriDoesNotExist_dll() async {
    addNamedSource("/lib.dll", "");
    Source source = addSource("import 'dart-ext:lib';");
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_uriDoesNotExist_dylib() async {
    addNamedSource("/lib.dylib", "");
    Source source = addSource("import 'dart-ext:lib';");
    await computeAnalysisResult(source);
    assertNoErrors(source);
  }

  test_uriDoesNotExist_so() async {
    addNamedSource("/lib.so", "");
    Source source = addSource("import 'dart-ext:lib';");
    await computeAnalysisResult(source);
    assertNoErrors(source);
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
    Source source = addSource(r'''
class A {
  operator []=(a, b) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_wrongNumberOfParametersForOperator_minus() async {
    await _check_wrongNumberOfParametersForOperator("-", "");
    await _check_wrongNumberOfParametersForOperator("-", "a");
  }

  test_wrongNumberOfParametersForSetter() async {
    Source source = addSource(r'''
class A {
  set x(a) {}
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_yield_async_to_dynamic_type() async {
    Source source = addSource('''
dynamic f() async* {
  yield 3;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_yield_async_to_generic_type() async {
    Source source = addSource('''
import 'dart:async';
Stream f() async* {
  yield 3;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_yield_async_to_parameterized_type() async {
    Source source = addSource('''
import 'dart:async';
Stream<int> f() async* {
  yield 3;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_yield_async_to_untyped() async {
    Source source = addSource('''
f() async* {
  yield 3;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_yield_each_async_dynamic_to_dynamic() async {
    Source source = addSource('''
f() async* {
  yield* g();
}
g() => null;
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_yield_each_async_dynamic_to_stream() async {
    Source source = addSource('''
import 'dart:async';
Stream f() async* {
  yield* g();
}
g() => null;
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_yield_each_async_dynamic_to_typed_stream() async {
    Source source = addSource('''
import 'dart:async';
Stream<int> f() async* {
  yield* g();
}
g() => null;
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_yield_each_async_stream_to_dynamic() async {
    Source source = addSource('''
import 'dart:async';
f() async* {
  yield* g();
}
Stream g() => null;
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_yield_each_async_typed_stream_to_dynamic() async {
    Source source = addSource('''
import 'dart:async';
f() async* {
  yield* g();
}
Stream<int> g() => null;
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_yield_each_async_typed_stream_to_typed_stream() async {
    Source source = addSource('''
import 'dart:async';
Stream<int> f() async* {
  yield* g();
}
Stream<int> g() => null;
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_yield_each_sync_dynamic_to_dynamic() async {
    Source source = addSource('''
f() sync* {
  yield* g();
}
g() => null;
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_yield_each_sync_dynamic_to_iterable() async {
    Source source = addSource('''
Iterable f() sync* {
  yield* g();
}
g() => null;
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_yield_each_sync_dynamic_to_typed_iterable() async {
    Source source = addSource('''
Iterable<int> f() sync* {
  yield* g();
}
g() => null;
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_yield_each_sync_iterable_to_dynamic() async {
    Source source = addSource('''
f() sync* {
  yield* g();
}
Iterable g() => null;
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_yield_each_sync_typed_iterable_to_dynamic() async {
    Source source = addSource('''
f() sync* {
  yield* g();
}
Iterable<int> g() => null;
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_yield_each_sync_typed_iterable_to_typed_iterable() async {
    Source source = addSource('''
Iterable<int> f() sync* {
  yield* g();
}
Iterable<int> g() => null;
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_yield_sync_to_dynamic_type() async {
    Source source = addSource('''
dynamic f() sync* {
  yield 3;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_yield_sync_to_generic_type() async {
    Source source = addSource('''
Iterable f() sync* {
  yield 3;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_yield_sync_to_parameterized_type() async {
    Source source = addSource('''
Iterable<int> f() sync* {
  yield 3;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_yield_sync_to_untyped() async {
    Source source = addSource('''
f() sync* {
  yield 3;
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_yieldInNonGenerator_asyncStar() async {
    Source source = addSource(r'''
f() async* {
  yield 0;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_yieldInNonGenerator_syncStar() async {
    Source source = addSource(r'''
f() sync* {
  yield 0;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  Future<Null> _check_wrongNumberOfParametersForOperator(
      String name, String parameters) async {
    Source source = addSource("""
class A {
  operator $name($parameters) {}
}""");
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    reset();
  }

  Future<Null> _check_wrongNumberOfParametersForOperator1(String name) async {
    await _check_wrongNumberOfParametersForOperator(name, "a");
  }
}
