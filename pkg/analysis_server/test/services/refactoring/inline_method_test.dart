// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/inline_method.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_refactoring.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InlineMethodTest);
  });
}

@reflectiveTest
class InlineMethodTest extends RefactoringTest {
  InlineMethodRefactoringImpl refactoring;
  bool deleteSource;
  bool inlineAll;

  test_access_FunctionElement() async {
    await indexTestUnit(r'''
test(a, b) {
  return a + b;
}
main() {
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

  test_access_MethodElement() async {
    await indexTestUnit(r'''
class A {
  test(a, b) {
    return a + b;
  }
  main() {
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

  test_bad_async_intoSyncStar() async {
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

  test_bad_async_targetIsSync_doesNotReturnFuture() async {
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

  test_bad_asyncStar() async {
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

  test_bad_cascadeInvocation() async {
    await indexTestUnit(r'''
class A {
  foo() {}
  bar() {}
  test() {}
}
main() {
 A a = new A();
 a..foo()..test()..bar();
}
''');
    _createRefactoring('test() {');
    // error
    RefactoringStatus status = await refactoring.checkAllConditions();
    var location = new SourceRange(findOffset('..test()'), '..test()'.length);
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: 'Cannot inline cascade invocation.',
        expectedContextRange: location);
  }

  test_bad_constructor() async {
    await indexTestUnit(r'''
class A {
  A.named() {}
}
''');
    _createRefactoring('named() {}');
    // error
    return _assertInvalidSelection();
  }

  test_bad_deleteSource_inlineOne() async {
    await indexTestUnit(r'''
test(a, b) {
  return a + b;
}
main() {
  var res1 = test(1, 2);
  var res2 = test(10, 20);
}
''');
    _createRefactoring('test(1, 2)');
    // initial conditions
    RefactoringStatus status = await refactoring.checkInitialConditions();
    assertRefactoringStatusOK(status);
    refactoring.deleteSource = true;
    refactoring.inlineAll = false;
    // final conditions
    status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage:
            'All references must be inlined to remove the source.');
  }

  test_bad_notExecutableElement() async {
    await indexTestUnit(r'''
main() {
}
''');
    _createRefactoring(') {');
    // error
    return _assertInvalidSelection();
  }

  test_bad_notSimpleIdentifier() async {
    await indexTestUnit(r'''
main() {
  var test = 42;
  var res = test;
}
''');
    _createRefactoring('test;');
    // error
    return _assertInvalidSelection();
  }

  test_bad_operator() async {
    await indexTestUnit(r'''
class A {
  operator -(other) => this;
}
''');
    _createRefactoring('-(other)');
    // error
    return _assertConditionsFatal('Cannot inline operator.');
  }

  test_bad_propertyAccessor_synthetic() async {
    await indexTestUnit(r'''
class A {
  int fff;
}

main(A a) {
  print(a.fff);
}
''');
    _createRefactoring('fff);');
    // error
    return _assertInvalidSelection();
  }

  test_bad_reference_toClassMethod() async {
    await indexTestUnit(r'''
class A {
  test(a, b) {
    print(a);
    print(b);
  }
}
main() {
  print(new A().test);
}
''');
    _createRefactoring('test(a, b)');
    // error
    return _assertConditionsFatal('Cannot inline class method reference.');
  }

  test_bad_severalReturns() async {
    await indexTestUnit(r'''
test() {
  if (true) {
    return 1;
  }
  return 2;
}
main() {
  var res = test();
}
''');
    _createRefactoring('test() {');
    // error
    return _assertConditionsError('Ambiguous return value.');
  }

  test_cascadeInCascade() async {
    await indexTestUnit(r'''
class Inner {
  String a;
  String b;
}

class Outer {
  Inner inner;
}

void main() {
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
  String a;
  String b;
}

class Outer {
  Inner inner;
}

void main() {
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

  test_fieldAccessor_getter() async {
    await indexTestUnit(r'''
class A {
  var f;
  get foo {
    return f * 2;
  }
}
main() {
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
main() {
  A a = new A();
  print(a.f * 2);
}
''');
  }

  test_fieldAccessor_getter_PropertyAccess() async {
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
main() {
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
main() {
  B b = new B();
  print(b.a.f * 2);
}
''');
  }

  test_fieldAccessor_setter() async {
    await indexTestUnit(r'''
class A {
  var f;
  set foo(x) {
    f = x;
  }
}
main() {
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
main() {
  A a = new A();
  a.f = 0;
}
''');
  }

  test_fieldAccessor_setter_PropertyAccess() async {
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
main() {
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
main() {
  B b = new B();
  b.a.f = 0;
}
''');
  }

  test_function_expressionFunctionBody() async {
    await indexTestUnit(r'''
test(a, b) => a + b;
main() {
  print(test(1, 2));
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  print(1 + 2);
}
''');
  }

  test_function_hasReturn_assign() async {
    await indexTestUnit(r'''
test(a, b) {
  print(a);
  print(b);
  return a + b;
}
main() {
  var v;
  v = test(1, 2);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  var v;
  print(1);
  print(2);
  v = 1 + 2;
}
''');
  }

  test_function_hasReturn_hasReturnType() async {
    await indexTestUnit(r'''
int test(a, b) {
  return a + b;
}
main() {
  var v = test(1, 2);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  var v = 1 + 2;
}
''');
  }

  test_function_hasReturn_noVars_oneUsage() async {
    await indexTestUnit(r'''
test(a, b) {
  print(a);
  print(b);
  return a + b;
}
main() {
  var v = test(1, 2);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  print(1);
  print(2);
  var v = 1 + 2;
}
''');
  }

  test_function_multilineString() async {
    await indexTestUnit(r"""
main() {
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
main() {
  {
    print('''
first line
second line
    ''');
  }
}
""");
  }

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

  test_function_noReturn_hasVars_hasConflict_localAfter() async {
    await indexTestUnit(r'''
test(a, b) {
  var c = a + b;
  print(c);
}
main() {
  test(1, 2);
  var c = 0;
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  var c2 = 1 + 2;
  print(c2);
  var c = 0;
}
''');
  }

  test_function_noReturn_hasVars_hasConflict_localBefore() async {
    await indexTestUnit(r'''
test(a, b) {
  var c = a + b;
  print(c);
}
main() {
  var c = 0;
  test(1, 2);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  var c = 0;
  var c2 = 1 + 2;
  print(c2);
}
''');
  }

  test_function_noReturn_hasVars_noConflict() async {
    await indexTestUnit(r'''
test(a, b) {
  var c = a + b;
  print(c);
}
main() {
  test(1, 2);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  var c = 1 + 2;
  print(c);
}
''');
  }

  test_function_noReturn_noVars_oneUsage() async {
    await indexTestUnit(r'''
test(a, b) {
  print(a);
  print(b);
}
main() {
  test(1, 2);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  print(1);
  print(2);
}
''');
  }

  test_function_noReturn_noVars_useIndentation() async {
    await indexTestUnit(r'''
test(a, b) {
  print(a);
  print(b);
}
main() {
  {
    test(1, 2);
  }
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  {
    print(1);
    print(2);
  }
}
''');
  }

  test_function_noReturn_voidReturnType() async {
    await indexTestUnit(r'''
void test(a, b) {
  print(a + b);
}
main() {
  test(1, 2);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  print(1 + 2);
}
''');
  }

  test_function_notStatement_oneStatement_assign() async {
    await indexTestUnit(r'''
test(int p) {
  print(p * 2);
}
main() {
  var v;
  v = test(0);
}
''');
    _createRefactoring('test(int p)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  var v;
  v = (int p) {
    print(p * 2);
  }(0);
}
''');
  }

  test_function_notStatement_oneStatement_variableDeclaration() async {
    await indexTestUnit(r'''
test(int p) {
  print(p * 2);
}
main() {
  var v = test(0);
}
''');
    _createRefactoring('test(int p)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  var v = (int p) {
    print(p * 2);
  }(0);
}
''');
  }

  test_function_notStatement_severalStatements() async {
    await indexTestUnit(r'''
test(int p) {
  print(p);
  print(p * 2);
}
main() {
  var v = test(0);
}
''');
    _createRefactoring('test(int p)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  var v = (int p) {
    print(p);
    print(p * 2);
  }(0);
}
''');
  }

  test_function_notStatement_zeroStatements() async {
    await indexTestUnit(r'''
test(int p) {
}
main() {
  var v = test(0);
}
''');
    _createRefactoring('test(int p)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  var v = (int p) {
  }(0);
}
''');
  }

  test_function_singleStatement() async {
    await indexTestUnit(r'''
var topLevelField = 0;
test() {
  print(topLevelField);
}
main() {
  test();
}
''');
    _createRefactoring('test() {');
    // validate change
    return _assertSuccessfulRefactoring(r'''
var topLevelField = 0;
main() {
  print(topLevelField);
}
''');
  }

  test_getter_async_targetIsAsync() async {
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

  test_getter_async_targetIsAsyncStar() async {
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

  test_getter_async_targetIsSync() async {
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

  test_getter_async_targetIsSync2() async {
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

  test_getter_classMember_instance() async {
    await indexTestUnit(r'''
class A {
  int f;
  int get result => f + 1;
}
main(A a) {
  print(a.result);
}
''');
    _createRefactoring('result =>');
    // validate change
    return _assertSuccessfulRefactoring(r'''
class A {
  int f;
}
main(A a) {
  print(a.f + 1);
}
''');
  }

  test_getter_classMember_static() async {
    await indexTestUnit(r'''
class A {
  static int get result => 1 + 2;
}
main() {
  print(A.result);
}
''');
    _createRefactoring('result =>');
    // validate change
    return _assertSuccessfulRefactoring(r'''
class A {
}
main() {
  print(1 + 2);
}
''');
  }

  test_getter_topLevel() async {
    await indexTestUnit(r'''
String get message => 'Hello, World!';
main() {
  print(message);
}
''');
    _createRefactoring('message =>');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  print('Hello, World!');
}
''');
  }

  test_initialMode_all() async {
    await indexTestUnit(r'''
test(a, b) {
  return a + b;
}
main() {
  var res = test(1, 2);
}
''');
    _createRefactoring('test(a, b)');
    // validate state
    await refactoring.checkInitialConditions();
    expect(refactoring.deleteSource, true);
    expect(refactoring.inlineAll, true);
  }

  test_initialMode_single() async {
    await indexTestUnit(r'''
test(a, b) {
  return a + b;
}
main() {
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

  test_method_async() async {
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

  test_method_async2() async {
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

  test_method_emptyBody() async {
    await indexTestUnit(r'''
abstract class A {
  test();
}
main(A a) {
  print(a.test());
}
''');
    _createRefactoring('test();');
    // error
    return _assertConditionsFatal('Cannot inline method without body.');
  }

  test_method_fieldInstance() async {
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
main() {
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
main() {
  B b = new B();
  print(b.fA);
  print(b.fB);
  print(b.fA);
  print(b.fB);
}
''');
  }

  test_method_fieldStatic() async {
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
main() {
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
main() {
  B b = new B();
  print(B.FB);
  print(A.FA);
  print(B.FB);
}
''');
  }

  test_method_fieldStatic_sameClass() async {
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

  test_method_methodInstance() async {
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
main(B b) {
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
main(B b) {
  b.ma();
  b.mb();
}
''');
  }

  test_method_methodStatic() async {
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
main(B b) {
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
main(B b) {
  B.mb();
  A.ma();
  B.mb();
}
''');
  }

  test_method_singleStatement() async {
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

  test_method_this() async {
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
main() {
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
main() {
  B b = new B();
  A a = new A();
  print(b);
  a.accept(b);
}
''');
  }

  test_method_unqualifiedInvocation() async {
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

  test_namedArgument_inBody() async {
    await indexTestUnit(r'''
fa(pa) => fb(pb: true);
fb({pb: false}) {}
main() {
  fa(null);
}
''');
    _createRefactoring('fa(null)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
fa(pa) => fb(pb: true);
fb({pb: false}) {}
main() {
  fb(pb: true);
}
''');
  }

  test_namedArguments() async {
    await indexTestUnit(r'''
test({a: 0, b: 2}) {
  print(a + b);
}
main() {
  test(a: 10, b: 20);
  test(b: 20, a: 10);
}
''');
    _createRefactoring('test({');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  print(10 + 20);
  print(10 + 20);
}
''');
  }

  test_noArgument_named_hasDefault() async {
    verifyNoTestUnitErrors = false;
    await indexTestUnit(r'''
test({a: 42}) {
  print(a);
}
main() {
  test();
}
''');
    _createRefactoring('test(');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  print(42);
}
''');
  }

  test_noArgument_positional_hasDefault() async {
    verifyNoTestUnitErrors = false;
    await indexTestUnit(r'''
test([a = 42]) {
  print(a);
}
main() {
  test();
}
''');
    _createRefactoring('test(');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  print(42);
}
''');
  }

  test_noArgument_positional_noDefault() async {
    verifyNoTestUnitErrors = false;
    await indexTestUnit(r'''
test([a]) {
  print(a);
}
main() {
  test();
}
''');
    _createRefactoring('test(');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  print(null);
}
''');
  }

  test_noArgument_required() async {
    verifyNoTestUnitErrors = false;
    await indexTestUnit(r'''
test(a) {
  print(a);
}
main() {
  test();
}
''');
    _createRefactoring('test();');
    // error
    RefactoringStatus status = await refactoring.checkAllConditions();
    var location = new SourceRange(findOffset('test();'), 'test()'.length);
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: 'No argument for the parameter "a".',
        expectedContextRange: location);
  }

  test_reference_expressionBody() async {
    await indexTestUnit(r'''
String message() => 'Hello, World!';
main() {
  print(message);
}
''');
    _createRefactoring('message()');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  print(() => 'Hello, World!');
}
''');
  }

  test_reference_noStatement() async {
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

  test_reference_toLocal() async {
    await indexTestUnit(r'''
main() {
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
main() {
  print((a, b) {
    print(a);
    print(b);
  });
}
''');
  }

  test_reference_toTopLevel() async {
    await indexTestUnit(r'''
test(a, b) {
  print(a);
  print(b);
}
main() {
  print(test);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  print((a, b) {
    print(a);
    print(b);
  });
}
''');
  }

  test_removeEmptyLinesBefore_method() async {
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

  test_setter_classMember_instance() async {
    await indexTestUnit(r'''
class A {
  int f;
  void set result(x) {
    f = x + 1;
  }
}
main(A a) {
  a.result = 5;
}
''');
    _createRefactoring('result(x)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
class A {
  int f;
}
main(A a) {
  a.f = 5 + 1;
}
''');
  }

  test_setter_topLevel() async {
    await indexTestUnit(r'''
void set result(x) {
  print(x + 1);
}
main() {
  result = 5;
}
''');
    _createRefactoring('result(x)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  print(5 + 1);
}
''');
  }

  test_singleExpression_oneUsage() async {
    await indexTestUnit(r'''
test(a, b) {
  return a + b;
}
main() {
  var res = test(1, 2);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  var res = 1 + 2;
}
''');
  }

  test_singleExpression_oneUsage_keepMethod() async {
    await indexTestUnit(r'''
test(a, b) {
  return a + b;
}
main() {
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
main() {
  var res = 1 + 2;
}
''');
  }

  test_singleExpression_twoUsages() async {
    await indexTestUnit(r'''
test(a, b) {
  return a + b;
}
main() {
  var res1 = test(1, 2);
  var res2 = test(10, 20);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  var res1 = 1 + 2;
  var res2 = 10 + 20;
}
''');
  }

  test_singleExpression_twoUsages_inlineOne() async {
    await indexTestUnit(r'''
test(a, b) {
  return a + b;
}
main() {
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
main() {
  var res1 = 1 + 2;
  var res2 = test(10, 20);
}
''');
  }

  test_singleExpression_wrapIntoParenthesized_alreadyInMethod() async {
    await indexTestUnit(r'''
test(a, b) {
  return a * (b);
}
main() {
  var res = test(1, 2 + 3);
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  var res = 1 * (2 + 3);
}
''');
  }

  test_singleExpression_wrapIntoParenthesized_asNeeded() async {
    await indexTestUnit(r'''
test(a, b) {
  return a * b;
}
main() {
  var res1 = test(1, 2 + 3);
  var res2 = test(1, (2 + 3));
}
''');
    _createRefactoring('test(a, b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main() {
  var res1 = 1 * (2 + 3);
  var res2 = 1 * (2 + 3);
}
''');
  }

  test_singleExpression_wrapIntoParenthesized_bool() async {
    await indexTestUnit(r'''
test(bool a, bool b) {
  return a || b;
}
main(bool p, bool p2, bool p3) {
  var res1 = p && test(p2, p3);
  var res2 = p || test(p2, p3);
}
''');
    _createRefactoring('test(bool a, bool b)');
    // validate change
    return _assertSuccessfulRefactoring(r'''
main(bool p, bool p2, bool p3) {
  var res1 = p && (p2 || p3);
  var res2 = p || p2 || p3;
}
''');
  }

  Future _assertConditionsError(String message) async {
    RefactoringStatus status = await refactoring.checkAllConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: message);
  }

  Future _assertConditionsFatal(String message) async {
    RefactoringStatus status = await refactoring.checkAllConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL,
        expectedMessage: message);
  }

  Future _assertInvalidSelection() {
    return _assertConditionsFatal(
        'Method declaration or reference must be selected to activate this refactoring.');
  }

  Future _assertSuccessfulRefactoring(String expectedCode) async {
    RefactoringStatus status = await refactoring.checkInitialConditions();
    assertRefactoringStatusOK(status);
    // configure
    if (deleteSource != null) {
      refactoring.deleteSource = deleteSource;
    }
    if (inlineAll != null) {
      refactoring.inlineAll = inlineAll;
    }
    // final conditions
    status = await refactoring.checkFinalConditions();
    assertRefactoringStatusOK(status);
    // change
    SourceChange change = await refactoring.createChange();
    this.refactoringChange = change;
    assertTestChangeResult(expectedCode);
  }

  void _createRefactoring(String search) {
    int offset = findOffset(search);
    refactoring = new InlineMethodRefactoring(
        searchEngine, astProvider, testUnit, offset);
  }
}
