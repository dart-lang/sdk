// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/refactoring/legacy/inline_method.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_refactoring.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InlineMethodEnumTest);
    defineReflectiveTests(InlineMethodTest);
  });
}

@reflectiveTest
class InlineMethodEnumTest extends _InlineMethodTest {
  Future<void> test_getter_classMember_instance() async {
    await indexTestUnit(r'''
enum E {
  v;
  final int f = 0;
  int get result => f + 1;
}
void f(E e) {
  print(e.result);
}
''');
    _createRefactoring('result =>');
    // validate change
    return _assertSuccessfulRefactoring(r'''
enum E {
  v;
  final int f = 0;
}
void f(E e) {
  print(e.f + 1);
}
''');
  }

  Future<void> test_getter_classMember_static() async {
    await indexTestUnit(r'''
enum E {
  v;
  static int get result => 1 + 2;
}
void f() {
  print(E.result);
}
''');
    _createRefactoring('result =>');
    // validate change
    return _assertSuccessfulRefactoring(r'''
enum E {
  v;
}
void f() {
  print(1 + 2);
}
''');
  }

  Future<void> test_method_singleStatement() async {
    await indexTestUnit(r'''
enum E {
  v;
  void test() {
    print(0);
  }
  void foo() {
    test();
  }
}
''');
    _createRefactoring('test() {');
    // validate change
    return _assertSuccessfulRefactoring(r'''
enum E {
  v;
  void foo() {
    print(0);
  }
}
''');
  }
}

@reflectiveTest
class InlineMethodTest extends _InlineMethodTest {
  Future<void> test_access_FunctionElement() async {
    await indexTestUnit(r'''
test(a, b) {
  return a + b;
}
void f() {
  var res = test(1, 2);
}
''');
    _createRefactoring('test(1, 2)');
    // validate state
    await refactoring.checkInitialConditions();
    expect(refactoring.refactoringName, 'Inline Function');
    expect(refactoring.className, isNull);
    expect(refactoring.methodName, 'test');
    expect(refactoring.isDeclaration, isFalse);
  }

  Future<void> test_access_MethodElement() async {
    await indexTestUnit(r'''
class A {
  test(a, b) {
    return a + b;
  }
  void f() {
    var res = test(1, 2);
  }
}
''');
    _createRefactoring('test(a, b)');
    // validate state
    await refactoring.checkInitialConditions();
    expect(refactoring.refactoringName, 'Inline Method');
    expect(refactoring.className, 'A');
    expect(refactoring.methodName, 'test');
    expect(refactoring.isDeclaration, isTrue);
  }

  Future<void> test_bad_async_intoSyncStar() async {
    await indexTestUnit(r'''
import 'dart:async';
class A {
  Future<int> get test async => 42;
  Iterable<Future<int>> foo() sync* {
    yield test;
  }
}
''');
    _createRefactoring('test async');
    // error
    return _assertConditionsFatal('Cannot inline async into sync*.');
  }

  Future<void> test_bad_async_targetIsSync_doesNotReturnFuture() async {
    await indexTestUnit(r'''
import 'dart:async';
class A {
  Future<int> get test async => 42;
  double foo() {
    test;
    return 1.2;
  }
}
''');
    _createRefactoring('test async');
    // error
    return _assertConditionsFatal(
        'Cannot inline async into a function that does not return a Future.');
  }

  Future<void> test_bad_asyncStar() async {
    await indexTestUnit(r'''
import 'dart:async';
class A {
  Stream<int> test() async* {
    yield 1;
    yield 2;
  }
  foo() {
    test();
  }
}
''');
    _createRefactoring('test() async*');
    // error
    return _assertConditionsFatal('Cannot inline a generator.');
  }

  Future<void> test_bad_cascadeInvocation() async {
    await indexTestUnit(r'''
class A {
  foo() {}
  bar() {}
  test() {}
}
void f() {
 A a = new A();
 a..foo()..test()..bar();
}
''');
    _createRefactoring('test() {');
    // error
    var status = await refactoring.checkAllConditions();
    var location = SourceRange(findOffset('..test()'), '..test()'.length);
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: 'Cannot inline cascade invocation.',
        expectedContextRange: location);
  }

  Future<void> test_bad_constructor() async {
    await indexTestUnit(r'''
class A {
  A.named() {}
}
''');
    _createRefactoring('named() {}');
    // error
    return _assertInvalidSelection();
  }

  Future<void> test_bad_deleteSource_inlineOne() async {
    await indexTestUnit(r'''
test(a, b) {
  return a + b;
}
void f() {
  var res1 = test(1, 2);
  var res2 = test(10, 20);
}
''');
    _createRefactoring('test(1, 2)');
    // initial conditions
    var status = await refactoring.checkInitialConditions();
    assertRefactoringStatusOK(status);
    refactoring.deleteSource = true;
    refactoring.inlineAll = false;
    // final conditions
    status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            'All references must be inlined to remove the source.');
  }

  Future<void> test_bad_notExecutableElement() async {
    await indexTestUnit(r'''
void f() {
}
''');
    _createRefactoring(') {');
    // error
    return _assertInvalidSelection();
  }

  Future<void> test_bad_notSimpleIdentifier() async {
    await indexTestUnit(r'''
void f() {
  var test = 42;
  var res = test;
}
''');
    _createRefactoring('test;');
    // error
    return _assertInvalidSelection();
  }

  Future<void> test_bad_operator() async {
    await indexTestUnit(r'''
class A {
  operator -(other) => this;
}
''');
    _createRefactoring('-(other)');
    // error
    return _assertConditionsFatal('Cannot inline operator.');
  }

  Future<void> test_bad_propertyAccessor_synthetic() async {
    await indexTestUnit(r'''
class A {
  int fff = 0;
}

void f(A a) {
  print(a.fff);
}
''');
    _createRefactoring('fff);');
    // error
    return _assertInvalidSelection();
  }

  Future<void> test_bad_reference_toClassMethod() async {
    await indexTestUnit(r'''
class A {
  test(a, b) {
    print(a);
    print(b);
  }
}
void f() {
  print(new A().test);
}
''');
    _createRefactoring('test(a, b)');
    // error
    return _assertConditionsFatal('Cannot inline class method reference.');
  }

  Future<void> test_bad_severalReturns() async {
    await indexTestUnit(r'''
test() {
  if (true) {
    return 1;
  }
  return 2;
}
void f() {
  var res = test();
}
''');
    _createRefactoring('test() {');
    // error
    return _assertConditionsError('Ambiguous return value.');
  }

  Future<void> test_cascadeInCascade() async {
    await indexTestUnit(r'''
class Inner {
  String a = '';
  String b = '';
}

class Outer {
  Inner inner = Inner();
}

void f() {
  Inner createInner() => new Inner()
      ..a = 'a'
      ..b = 'b';

  final value = new Outer()
      ..inner = createInner();
}
''');
    _createRefactoring('createInner();');
    // validate change
    return _assertSuccessfulRefactoring(r'''
class Inner {
  String a = '';
  String b = '';
}

class Outer {
  Inner inner = Inner();
}

void f() {
  Inner createInner() => new Inner()
      ..a = 'a'
      ..b = 'b';

  final value = new Outer()
      ..inner = (new Inner()
      ..a = 'a'
      ..b = 'b');
}
''');
  }

  Future<void> test_fieldAccessor_getter() async {
    await indexTestUnit(r'''
class A {
  var f;
  get foo {
    return f * 2;
  }
}
void f() {
  A a = new A();
  print(a.foo);
}
''');
    _createRefactoring('foo {');
    // validate change
    return _assertSuccessfulRefactoring(r'''
class A {
  var f;
}
void f() {
  A a = new A();
  print(a.f * 2);
}
''');
  }

  Future<void> test_fieldAccessor_getter_PropertyAccess() async {
    await indexTestUnit(r'''
class A {
  var f;
  get foo {
    return f * 2;
  }
}
class B {
  A a = new A();
}
void f() {
  B b = new B();
  print(b.a.foo);
}
''');
    _createRefactoring('foo {');
    // validate change
    return _assertSuccessfulRefactoring(r'''
class A {
  var f;
}
class B {
  A a = new A();
}
void f() {
  B b = new B();
  print(b.a.f * 2);
}
''');
  }

  Future<void> test_fieldAccessor_setter() async {
    await indexTestUnit(r'''
class A {
  var f;
  set foo(x) {
    f = x;
  }
}
void f() {
  A a = new A();
  a.foo = 0;
}
''');
    _createRefactoring('foo(x) {');
    // validate change
    return _assertSuccessfulRefactoring(r'''
class A {
  var f;
}
void f() {
  A a = new A();
  a.f = 0;
}
''');
  }

  Future<void> test_fieldAccessor_setter_PropertyAccess() async {
    await indexTestUnit(r'''
class A {
  var f;
  set foo(x) {
    f = x;
  }
}
class B {
  A a = new A();
}
void f() {
  B b = new B();
  b.a.foo = 0;
}
''');
    _createRefactoring('foo(x) {');
    // validate change
    return _assertSuccessfulRefactoring(r'''
class A {
  var f;
}
class B {
  A a = new A();
}
void f() {
  B b = new B();
  b.a.f = 0;
}
''');
  }

  Future<void> test_function_expressionFunctionBody() async {
    await indexTestUnit(r'''
test(a, b) => a + b;
void f() {
  print(test(1, 2));
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  print(1 + 2);
}
''');
  }

  Future<void> test_function_hasReturn_assign() async {
    await indexTestUnit(r'''
test(a, b) {
  print(a);
  print(b);
  return a + b;
}
void f() {
  var v;
  v = test(1, 2);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  var v;
  print(1);
  print(2);
  v = 1 + 2;
}
''');
  }

  Future<void> test_function_hasReturn_hasReturnType() async {
    await indexTestUnit(r'''
int test(a, b) {
  return a + b;
}
void f() {
  var v = test(1, 2);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  var v = 1 + 2;
}
''');
  }

  Future<void> test_function_hasReturn_hasReturnType_hasTypeParameters() async {
    await indexTestUnit(r'''
num test<T extends num>(T a, T b) {
  return a + b;
}
void f() {
  print(test(1, 2));
}
''');
    _createRefactoring('test');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  print(1 + 2);
}
''');
  }

  Future<void> test_function_hasReturn_noExpression() async {
    await indexTestUnit(r'''
test(a, b) {
  print(a);
  print(b);
  return;
}
void f() {
  test(1, 2);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  print(1);
  print(2);
}
''');
  }

  Future<void> test_function_hasReturn_noVars_oneUsage() async {
    await indexTestUnit(r'''
test(a, b) {
  print(a);
  print(b);
  return a + b;
}
void f() {
  var v = test(1, 2);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  print(1);
  print(2);
  var v = 1 + 2;
}
''');
  }

  Future<void> test_function_multilineString() async {
    await indexTestUnit(r"""
void f() {
  {
    test();
  }
}
test() {
  print('''
first line
second line
    ''');
}
""");
    _createRefactoring('test() {');
    // validate change
    return _assertSuccessfulRefactoring(r"""
void f() {
  {
    print('''
first line
second line
    ''');
  }
}
""");
  }

  Future<void>
      test_function_noReturn_hasVars_hasConflict_fieldSuperClass() async {
    await indexTestUnit(r'''
class A {
  var c;
}
class B extends A {
  foo() {
    test(1, 2);
  }
}
test(a, b) {
  var c = a + b;
  print(c);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
class A {
  var c;
}
class B extends A {
  foo() {
    var c2 = 1 + 2;
    print(c2);
  }
}
''');
  }

  Future<void>
      test_function_noReturn_hasVars_hasConflict_fieldThisClass() async {
    await indexTestUnit(r'''
class A {
  var c;
  foo() {
    test(1, 2);
  }
}
test(a, b) {
  var c = a + b;
  print(c);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
class A {
  var c;
  foo() {
    var c2 = 1 + 2;
    print(c2);
  }
}
''');
  }

  Future<void> test_function_noReturn_hasVars_hasConflict_localAfter() async {
    await indexTestUnit(r'''
test(a, b) {
  var c = a + b;
  print(c);
}
void f() {
  test(1, 2);
  var c = 0;
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  var c2 = 1 + 2;
  print(c2);
  var c = 0;
}
''');
  }

  Future<void> test_function_noReturn_hasVars_hasConflict_localBefore() async {
    await indexTestUnit(r'''
test(a, b) {
  var c = a + b;
  print(c);
}
void f() {
  var c = 0;
  test(1, 2);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  var c = 0;
  var c2 = 1 + 2;
  print(c2);
}
''');
  }

  Future<void> test_function_noReturn_hasVars_noConflict() async {
    await indexTestUnit(r'''
test(a, b) {
  var c = a + b;
  print(c);
}
void f() {
  test(1, 2);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  var c = 1 + 2;
  print(c);
}
''');
  }

  Future<void> test_function_noReturn_noVars_oneUsage() async {
    await indexTestUnit(r'''
test(a, b) {
  print(a);
  print(b);
}
void f() {
  test(1, 2);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  print(1);
  print(2);
}
''');
  }

  Future<void> test_function_noReturn_noVars_useIndentation() async {
    await indexTestUnit(r'''
test(a, b) {
  print(a);
  print(b);
}
void f() {
  {
    test(1, 2);
  }
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  {
    print(1);
    print(2);
  }
}
''');
  }

  Future<void> test_function_noReturn_voidReturnType() async {
    await indexTestUnit(r'''
void test(a, b) {
  print(a + b);
}
void f() {
  test(1, 2);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  print(1 + 2);
}
''');
  }

  Future<void> test_function_notStatement_oneStatement_assign() async {
    await indexTestUnit(r'''
test(int p) {
  print(p * 2);
}
void f() {
  var v;
  v = test(0);
}
''');
    _createRefactoring('test(int p)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  var v;
  v = (int p) {
    print(p * 2);
  }(0);
}
''');
  }

  Future<void>
      test_function_notStatement_oneStatement_variableDeclaration() async {
    await indexTestUnit(r'''
test(int p) {
  print(p * 2);
}
void f() {
  var v = test(0);
}
''');
    _createRefactoring('test(int p)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  var v = (int p) {
    print(p * 2);
  }(0);
}
''');
  }

  Future<void> test_function_notStatement_severalStatements() async {
    await indexTestUnit(r'''
test(int p) {
  print(p);
  print(p * 2);
}
void f() {
  var v = test(0);
}
''');
    _createRefactoring('test(int p)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  var v = (int p) {
    print(p);
    print(p * 2);
  }(0);
}
''');
  }

  Future<void> test_function_notStatement_zeroStatements() async {
    await indexTestUnit(r'''
test(int p) {
}
void f() {
  var v = test(0);
}
''');
    _createRefactoring('test(int p)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  var v = (int p) {
  }(0);
}
''');
  }

  Future<void> test_function_singleStatement() async {
    await indexTestUnit(r'''
var topLevelField = 0;
test() {
  print(topLevelField);
}
void f() {
  test();
}
''');
    _createRefactoring('test() {');
    // validate change
    return _assertSuccessfulRefactoring(r'''
var topLevelField = 0;
void f() {
  print(topLevelField);
}
''');
  }

  Future<void> test_function_startOfParameterList() async {
    await indexTestUnit(r'''
test(a, b) {
  print(a);
  print(b);
}
void f() {
  test(1, 2);
}
''');
    _createRefactoring('(a, b) {');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  print(1);
  print(2);
}
''');
  }

  Future<void> test_function_startOfTypeParameterList() async {
    await indexTestUnit(r'''
test<T>(a, b) {
  print(a);
  print(b);
}
void f() {
  test(1, 2);
}
''');
    _createRefactoring('<T>');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  print(1);
  print(2);
}
''');
  }

  Future<void> test_getter_async_targetIsAsync() async {
    await indexTestUnit(r'''
import 'dart:async';
class A {
  Future<int> get test async => 42;
  Future<int> foo() async {
    return test;
  }
}
''');
    _createRefactoring('test async');
    // validate change
    return _assertSuccessfulRefactoring(r'''
import 'dart:async';
class A {
  Future<int> foo() async {
    return 42;
  }
}
''');
  }

  Future<void> test_getter_async_targetIsAsyncStar() async {
    await indexTestUnit(r'''
import 'dart:async';
class A {
  Future<int> get test async => 42;
  Stream<int> foo() async* {
    yield await test;
  }
}
''');
    _createRefactoring('test async');
    // validate change
    return _assertSuccessfulRefactoring(r'''
import 'dart:async';
class A {
  Stream<int> foo() async* {
    yield await 42;
  }
}
''');
  }

  Future<void> test_getter_async_targetIsSync() async {
    await indexTestUnit(r'''
import 'dart:async';
class A {
  Future<int> get test async => 42;
  Future<int> foo() {
    return test;
  }
}
''');
    _createRefactoring('test async');
    // validate change
    return _assertSuccessfulRefactoring(r'''
import 'dart:async';
class A {
  Future<int> foo() async {
    return 42;
  }
}
''');
  }

  Future<void> test_getter_async_targetIsSync2() async {
    await indexTestUnit(r'''
import 'dart:async';
class A {
  Future<int> get test async => 42;
  Future<int> foo1() {
    return test;
  }
  Future<int> foo2() {
    return test;
  }
}
''');
    _createRefactoring('test async');
    // validate change
    return _assertSuccessfulRefactoring(r'''
import 'dart:async';
class A {
  Future<int> foo1() async {
    return 42;
  }
  Future<int> foo2() async {
    return 42;
  }
}
''');
  }

  Future<void> test_getter_classMember_instance() async {
    await indexTestUnit(r'''
class A {
  int f = 0;
  int get result => f + 1;
}
void f(A a) {
  print(a.result);
}
''');
    _createRefactoring('result =>');
    // validate change
    return _assertSuccessfulRefactoring(r'''
class A {
  int f = 0;
}
void f(A a) {
  print(a.f + 1);
}
''');
  }

  Future<void> test_getter_classMember_static() async {
    await indexTestUnit(r'''
class A {
  static int get result => 1 + 2;
}
void f() {
  print(A.result);
}
''');
    _createRefactoring('result =>');
    // validate change
    return _assertSuccessfulRefactoring(r'''
class A {
}
void f() {
  print(1 + 2);
}
''');
  }

  Future<void> test_getter_topLevel() async {
    await indexTestUnit(r'''
String get message => 'Hello, World!';
void f() {
  print(message);
}
''');
    _createRefactoring('message =>');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  print('Hello, World!');
}
''');
  }

  Future<void> test_initialMode_all() async {
    await indexTestUnit(r'''
test(a, b) {
  return a + b;
}
void f() {
  var res = test(1, 2);
}
''');
    _createRefactoring('test(a, b)');
    // validate state
    await refactoring.checkInitialConditions();
    expect(refactoring.deleteSource, true);
    expect(refactoring.inlineAll, true);
  }

  Future<void> test_initialMode_single() async {
    await indexTestUnit(r'''
test(a, b) {
  return a + b;
}
void f() {
  var res1 = test(1, 2);
  var res2 = test(10, 20);
}
''');
    _createRefactoring('test(1, 2)');
    deleteSource = false;
    // validate state
    await refactoring.checkInitialConditions();
    expect(refactoring.deleteSource, false);
    expect(refactoring.inlineAll, false);
  }

  Future<void> test_method_async() async {
    await indexTestUnit(r'''
import 'dart:async';
class A {
  Future<int> test() async => 42;
  Future<int> foo() {
    return test();
  }
}
''');
    _createRefactoring('test() async');
    // validate change
    return _assertSuccessfulRefactoring(r'''
import 'dart:async';
class A {
  Future<int> foo() async {
    return 42;
  }
}
''');
  }

  Future<void> test_method_async2() async {
    await indexTestUnit(r'''
import 'dart:async';
class A {
  Future<int> foo() async => 42;
  Future<int> test() async => await foo();
  Future bar() {
    return new Future.value([test(), test()]);
  }
}
''');
    _createRefactoring('test() async');
    // validate change
    return _assertSuccessfulRefactoring(r'''
import 'dart:async';
class A {
  Future<int> foo() async => 42;
  Future bar() async {
    return new Future.value([(await foo()), (await foo())]);
  }
}
''');
  }

  Future<void> test_method_emptyBody() async {
    await indexTestUnit(r'''
abstract class A {
  test();
}
void f(A a) {
  print(a.test());
}
''');
    _createRefactoring('test();');
    // error
    return _assertConditionsFatal('Cannot inline method without body.');
  }

  Future<void> test_method_fieldInstance() async {
    await indexTestUnit(r'''
class A {
  var fA;
}
class B extends A {
  var fB;
  test() {
    print(fA);
    print(fB);
    print(this.fA);
    print(this.fB);
  }
}
void f() {
  B b = new B();
  b.test();
}
''');
    _createRefactoring('test() {');
    // validate change
    return _assertSuccessfulRefactoring(r'''
class A {
  var fA;
}
class B extends A {
  var fB;
}
void f() {
  B b = new B();
  print(b.fA);
  print(b.fB);
  print(b.fA);
  print(b.fB);
}
''');
  }

  Future<void> test_method_fieldStatic() async {
    await indexTestUnit(r'''
class A {
  static var FA = 1;
}
class B extends A {
  static var FB = 2;
  test() {
    print(FB);
    print(A.FA);
    print(B.FB);
  }
}
void f() {
  B b = new B();
  b.test();
}
''');
    _createRefactoring('test() {');
    // validate change
    return _assertSuccessfulRefactoring(r'''
class A {
  static var FA = 1;
}
class B extends A {
  static var FB = 2;
}
void f() {
  B b = new B();
  print(B.FB);
  print(A.FA);
  print(B.FB);
}
''');
  }

  Future<void> test_method_fieldStatic_sameClass() async {
    await indexTestUnit(r'''
class A {
  static var F = 1;
  foo() {
    test();
  }
  test() {
    print(A.F);
  }
}
''');
    _createRefactoring('test() {');
    // validate change
    return _assertSuccessfulRefactoring(r'''
class A {
  static var F = 1;
  foo() {
    print(A.F);
  }
}
''');
  }

  Future<void> test_method_methodInstance() async {
    await indexTestUnit(r'''
class A {
  ma() {}
}
class B extends A {
  test() {
    ma();
    mb();
  }
  mb() {}
}
void f(B b) {
  b.test();
}
''');
    _createRefactoring('test();');
    // validate change
    return _assertSuccessfulRefactoring(r'''
class A {
  ma() {}
}
class B extends A {
  test() {
    ma();
    mb();
  }
  mb() {}
}
void f(B b) {
  b.ma();
  b.mb();
}
''');
  }

  Future<void> test_method_methodStatic() async {
    await indexTestUnit(r'''
class A {
  static ma() {}
}
class B extends A {
  static mb() {}
  test() {
    mb();
    A.ma();
    B.mb();
  }
}
void f(B b) {
  b.test();
}
''');
    _createRefactoring('test();');
    // validate change
    return _assertSuccessfulRefactoring(r'''
class A {
  static ma() {}
}
class B extends A {
  static mb() {}
  test() {
    mb();
    A.ma();
    B.mb();
  }
}
void f(B b) {
  B.mb();
  A.ma();
  B.mb();
}
''');
  }

  Future<void> test_method_singleStatement() async {
    await indexTestUnit(r'''
class A {
  test() {
    print(0);
  }
  foo() {
    test();
  }
}
''');
    _createRefactoring('test() {');
    // validate change
    return _assertSuccessfulRefactoring(r'''
class A {
  foo() {
    print(0);
  }
}
''');
  }

  Future<void> test_method_this() async {
    await indexTestUnit(r'''
class A {
  accept(B b) {}
}
class B {
  test(A a) {
    print(this);
    a.accept(this);
  }
}
void f() {
  B b = new B();
  A a = new A();
  b.test(a);
}
''');
    _createRefactoring('test(A a) {');
    // validate change
    return _assertSuccessfulRefactoring(r'''
class A {
  accept(B b) {}
}
class B {
}
void f() {
  B b = new B();
  A a = new A();
  print(b);
  a.accept(b);
}
''');
  }

  Future<void> test_method_unqualifiedInvocation() async {
    await indexTestUnit(r'''
class A {
  test(a, b) {
    print(a);
    print(b);
    return a + b;
  }
  foo() {
    var v = test(1, 2);
  }
}
''');
    _createRefactoring('test(a, b) {');
    // validate change
    return _assertSuccessfulRefactoring(r'''
class A {
  foo() {
    print(1);
    print(2);
    var v = 1 + 2;
  }
}
''');
  }

  Future<void> test_namedArgument_inBody() async {
    await indexTestUnit(r'''
fa(pa) => fb(pb: true);
fb({pb = false}) {}
void f() {
  fa(null);
}
''');
    _createRefactoring('fa(null)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
fa(pa) => fb(pb: true);
fb({pb = false}) {}
void f() {
  fb(pb: true);
}
''');
  }

  Future<void> test_namedArguments() async {
    await indexTestUnit(r'''
test({a = 0, b = 2}) {
  print(a + b);
}
void f() {
  test(a: 10, b: 20);
  test(b: 20, a: 10);
}
''');
    _createRefactoring('test({');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  print(10 + 20);
  print(10 + 20);
}
''');
  }

  Future<void> test_noArgument_named_hasDefault() async {
    verifyNoTestUnitErrors = false;
    await indexTestUnit(r'''
test({a: 42}) {
  print(a);
}
void f() {
  test();
}
''');
    _createRefactoring('test(');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  print(42);
}
''');
  }

  Future<void> test_noArgument_positional_hasDefault() async {
    verifyNoTestUnitErrors = false;
    await indexTestUnit(r'''
test([a = 42]) {
  print(a);
}
void f() {
  test();
}
''');
    _createRefactoring('test(');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  print(42);
}
''');
  }

  Future<void> test_noArgument_positional_noDefault() async {
    verifyNoTestUnitErrors = false;
    await indexTestUnit(r'''
test([a]) {
  print(a);
}
void f() {
  test();
}
''');
    _createRefactoring('test(');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  print(null);
}
''');
  }

  Future<void> test_noArgument_required() async {
    verifyNoTestUnitErrors = false;
    await indexTestUnit(r'''
test(a) {
  print(a);
}
void f() {
  test();
}
''');
    _createRefactoring('test();');
    // error
    var status = await refactoring.checkAllConditions();
    var location = SourceRange(findOffset('test();'), 'test()'.length);
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: 'No argument for the parameter "a".',
        expectedContextRange: location);
  }

  Future<void> test_reference_expressionBody() async {
    await indexTestUnit(r'''
String message() => 'Hello, World!';
void f() {
  print(message);
}
''');
    _createRefactoring('message()');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  print(() => 'Hello, World!');
}
''');
  }

  Future<void> test_reference_noStatement() async {
    await indexTestUnit(r'''
test(a, b) {
  return a || b;
}
foo(p1, p2, p3) => p1 && test(p2, p3);
bar() => {
  'name' : baz(test)
};
baz(x) {}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
foo(p1, p2, p3) => p1 && (p2 || p3);
bar() => {
  'name' : baz((a, b) {
    return a || b;
  })
};
baz(x) {}
''');
  }

  Future<void> test_reference_toLocal() async {
    await indexTestUnit(r'''
void f() {
  test(a, b) {
    print(a);
    print(b);
  }
  print(test);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  print((a, b) {
    print(a);
    print(b);
  });
}
''');
  }

  Future<void> test_reference_toTopLevel() async {
    await indexTestUnit(r'''
test(a, b) {
  print(a);
  print(b);
}
void f() {
  print(test);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  print((a, b) {
    print(a);
    print(b);
  });
}
''');
  }

  Future<void> test_removeEmptyLinesBefore_method() async {
    await indexTestUnit(r'''
class A {
  before() {
  }


  test() {
    print(0);
  }

  foo() {
    test();
  }
}
''');
    _createRefactoring('test() {');
    // validate change
    return _assertSuccessfulRefactoring(r'''
class A {
  before() {
  }

  foo() {
    print(0);
  }
}
''');
  }

  Future<void> test_setter_classMember_instance() async {
    await indexTestUnit(r'''
class A {
  int f = 0;
  void set result(x) {
    f = x + 1;
  }
}
void f(A a) {
  a.result = 5;
}
''');
    _createRefactoring('result(x)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
class A {
  int f = 0;
}
void f(A a) {
  a.f = 5 + 1;
}
''');
  }

  Future<void> test_setter_topLevel() async {
    await indexTestUnit(r'''
void set result(x) {
  print(x + 1);
}
void f() {
  result = 5;
}
''');
    _createRefactoring('result(x)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  print(5 + 1);
}
''');
  }

  Future<void> test_singleExpression_oneUsage() async {
    await indexTestUnit(r'''
test(a, b) {
  return a + b;
}
void f() {
  var res = test(1, 2);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  var res = 1 + 2;
}
''');
  }

  Future<void> test_singleExpression_oneUsage_keepMethod() async {
    await indexTestUnit(r'''
test(a, b) {
  return a + b;
}
void f() {
  var res = test(1, 2);
}
''');
    _createRefactoring('test(a, b)');
    deleteSource = false;
    // validate change
    return _assertSuccessfulRefactoring(r'''
test(a, b) {
  return a + b;
}
void f() {
  var res = 1 + 2;
}
''');
  }

  Future<void> test_singleExpression_twoUsages() async {
    await indexTestUnit(r'''
test(a, b) {
  return a + b;
}
void f() {
  var res1 = test(1, 2);
  var res2 = test(10, 20);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  var res1 = 1 + 2;
  var res2 = 10 + 20;
}
''');
  }

  Future<void> test_singleExpression_twoUsages_inlineOne() async {
    await indexTestUnit(r'''
test(a, b) {
  return a + b;
}
void f() {
  var res1 = test(1, 2);
  var res2 = test(10, 20);
}
''');
    _createRefactoring('test(1, 2)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
test(a, b) {
  return a + b;
}
void f() {
  var res1 = 1 + 2;
  var res2 = test(10, 20);
}
''');
  }

  Future<void>
      test_singleExpression_wrapIntoParenthesized_alreadyInMethod() async {
    await indexTestUnit(r'''
test(a, b) {
  return a * (b);
}
void f() {
  var res = test(1, 2 + 3);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  var res = 1 * (2 + 3);
}
''');
  }

  Future<void> test_singleExpression_wrapIntoParenthesized_asNeeded() async {
    await indexTestUnit(r'''
test(a, b) {
  return a * b;
}
void f() {
  var res1 = test(1, 2 + 3);
  var res2 = test(1, (2 + 3));
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f() {
  var res1 = 1 * (2 + 3);
  var res2 = 1 * (2 + 3);
}
''');
  }

  Future<void> test_singleExpression_wrapIntoParenthesized_bool() async {
    await indexTestUnit(r'''
test(bool a, bool b) {
  return a || b;
}
void f(bool p, bool p2, bool p3) {
  var res1 = p && test(p2, p3);
  var res2 = p || test(p2, p3);
}
''');
    _createRefactoring('test(bool a, bool b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
void f(bool p, bool p2, bool p3) {
  var res1 = p && (p2 || p3);
  var res2 = p || p2 || p3;
}
''');
  }

  Future<void> test_target_topLevelVariable() async {
    await indexTestUnit(r'''
int get test => 42;
var a = test;
''');
    _createRefactoring('test =>');
    return _assertSuccessfulRefactoring(r'''
var a = 42;
''');
  }
}

class _InlineMethodTest extends RefactoringTest {
  @override
  late InlineMethodRefactoringImpl refactoring;
  bool? deleteSource;
  bool? inlineAll;

  Future<void> _assertConditionsError(String message) async {
    var status = await refactoring.checkAllConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: message);
  }

  Future<void> _assertConditionsFatal(String message) async {
    var status = await refactoring.checkAllConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL,
        expectedMessage: message);
  }

  Future<void> _assertInvalidSelection() {
    return _assertConditionsFatal(
        'Method declaration or reference must be selected to activate this refactoring.');
  }

  Future<void> _assertSuccessfulRefactoring(String expectedCode) async {
    var status = await refactoring.checkInitialConditions();
    assertRefactoringStatusOK(status);
    // configure
    final deleteSource = this.deleteSource;
    if (deleteSource != null) {
      refactoring.deleteSource = deleteSource;
    }
    final inlineAll = this.inlineAll;
    if (inlineAll != null) {
      refactoring.inlineAll = inlineAll;
    }
    // final conditions
    status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
    // change
    var change = await refactoring.createChange();
    refactoringChange = change;
    assertTestChangeResult(expectedCode);
  }

  void _createRefactoring(String search) {
    var offset = findOffset(search);
    refactoring = InlineMethodRefactoringImpl(
      searchEngine,
      testAnalysisResult,
      offset,
    );
  }
}
