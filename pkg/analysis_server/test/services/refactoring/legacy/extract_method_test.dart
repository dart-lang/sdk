// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/refactoring/legacy/extract_method.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_refactoring.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtractMethodEnumTest);
    defineReflectiveTests(ExtractMethodTest);
  });
}

@reflectiveTest
class ExtractMethodEnumTest extends _ExtractMethodTest {
  Future<void> test_bad_conflict_method_alreadyDeclaresMethod() async {
    await indexTestUnit('''
enum E {
  v;
  void res() {}
  void foo() {
// start
    print(0);
// end
  }
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsError(
        "Enum 'E' already declares method with name 'res'.");
  }

  Future<void> test_bad_conflict_method_shadowsSuperDeclaration() async {
    await indexTestUnit('''
mixin M {
  void res() {}
}

enum E with M {
  v;
  void foo() {
    res();
// start
    print(0);
// end
  }
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsError("Created method will shadow method 'M.res'.");
  }

  Future<void> test_bad_conflict_topLevel_willHideInheritedMemberUsage() async {
    await indexTestUnit('''
mixin M {
  void res() {}
}

enum E with M {
  v;
  void foo() {
    res();
  }
}

void f() {
// start
  print(0);
// end
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsError(
        "Created function will shadow method 'M.res'.");
  }

  Future<void> test_singleExpression_method() async {
    await indexTestUnit('''
enum E {
  v;
  void foo() {
    int a = 1 + 2;
  }
}
''');
    _createRefactoringForString('1 + 2');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
enum E {
  v;
  void foo() {
    int a = res();
  }

  int res() => 1 + 2;
}
''');
  }

  Future<void> test_statements_method() async {
    await indexTestUnit('''
enum E {
  v;
  void foo() {
// start
    print(0);
// end
  }
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
enum E {
  v;
  void foo() {
// start
    res();
// end
  }

  void res() {
    print(0);
  }
}
''');
  }
}

@reflectiveTest
class ExtractMethodTest extends _ExtractMethodTest {
  Future<void> test_bad_assignmentLeftHandSide() async {
    await indexTestUnit('''
void f() {
  int aaa;
  aaa = 0;
}
''');
    _createRefactoringForString('aaa ');
    return _assertConditionsFatal(
        'Cannot extract the left-hand side of an assignment.');
  }

  Future<void> test_bad_comment_selectionEndsInside() async {
    await indexTestUnit('''
void f() {
// start
  print(0);
/*
// end
*/
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsFatal('Selection ends inside a comment.');
  }

  Future<void> test_bad_comment_selectionStartsInside() async {
    await indexTestUnit('''
void f() {
/*
// start
*/
  print(0);
// end
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsFatal('Selection begins inside a comment.');
  }

  Future<void> test_bad_conflict_method_alreadyDeclaresMethod() async {
    await indexTestUnit('''
class A {
  void res() {}
  void f() {
// start
    print(0);
// end
  }
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsError(
        "Class 'A' already declares method with name 'res'.");
  }

  Future<void> test_bad_conflict_method_shadowsSuperDeclaration() async {
    await indexTestUnit('''
class A {
  void res() {} // marker
}
class B extends A {
  void f() {
    res();
// start
    print(0);
// end
  }
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsError("Created method will shadow method 'A.res'.");
  }

  Future<void> test_bad_conflict_topLevel_alreadyDeclaresFunction() async {
    await indexTestUnit('''
library my.lib;

void res() {}
void f() {
// start
  print(0);
// end
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsError(
        "Library already declares function with name 'res'.");
  }

  Future<void> test_bad_conflict_topLevel_willHideInheritedMemberUsage() async {
    await indexTestUnit('''
class A {
  void res() {}
}
class B extends A {
  foo() {
    res(); // marker
  }
}
void f() {
// start
  print(0);
// end
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsError(
        "Created function will shadow method 'A.res'.");
  }

  Future<void> test_bad_constructor_initializer() async {
    await indexTestUnit('''
class A {
  int f;
  A() : f = 0 {}
}
''');
    _createRefactoringForString('f = 0');
    return _assertConditionsFatal(
        'Cannot extract a constructor initializer. Select expression part of initializer.');
  }

  Future<void> test_bad_constructor_redirectingConstructor() async {
    await indexTestUnit('''
class A {
  A() : this.named();
  A.named() {}
}
''');
    _createRefactoringForString('this.named()');
    return _assertConditionsFatal(
        'Cannot extract a constructor initializer. Select expression part of initializer.');
  }

  Future<void> test_bad_constructor_superConstructor() async {
    await indexTestUnit('''
class A {}
class B extends A {
  B() : super();
}
''');
    _createRefactoringForString('super()');
    return _assertConditionsFatal(
        'Cannot extract a constructor initializer. Select expression part of initializer.');
  }

  Future<void> test_bad_directive_combinator() async {
    await indexTestUnit('''
import 'dart:async' show FutureOr;
''');
    _createRefactoringForString('show');
    return _assertConditionsFatal('Cannot extract a directive.');
  }

  Future<void> test_bad_directive_combinatorNames() async {
    await indexTestUnit('''
import 'dart:async' show FutureOr;
''');
    _createRefactoringForString('FutureOr');
    return _assertConditionsFatal('Cannot extract a directive.');
  }

  Future<void> test_bad_directive_import() async {
    await indexTestUnit('''
// Dummy comment ("The selection offset must be greater than zero")
import 'dart:async';
''');
    _createRefactoringForString('import');
    return _assertConditionsFatal('Cannot extract a directive.');
  }

  Future<void> test_bad_directive_prefixAs() async {
    await indexTestUnit('''
import 'dart:core' as core;
''');
    _createRefactoringForString('as');
    return _assertConditionsFatal('Cannot extract a directive.');
  }

  Future<void> test_bad_directive_prefixName() async {
    await indexTestUnit('''
import 'dart:async' as prefixName;
''');
    _createRefactoringForString('prefixName');
    return _assertConditionsFatal('Cannot extract a directive.');
  }

  Future<void> test_bad_directive_uriString() async {
    await indexTestUnit('''
import 'dart:async';
''');
    _createRefactoringForString('dart:async');
    return _assertConditionsFatal('Cannot extract a directive.');
  }

  Future<void> test_bad_doWhile_body() async {
    await indexTestUnit('''
void f() {
  do
// start
  {
  }
// end
  while (true);
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsFatal(
        "Operation not applicable to a 'do' statement's body and expression.");
  }

  Future<void> test_bad_emptySelection() async {
    await indexTestUnit('''
void f() {
// start
// end
  print(0);
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsFatal(
        'Can only extract a single expression or a set of statements.');
  }

  Future<void> test_bad_forLoop_conditionAndUpdaters() async {
    await indexTestUnit('''
void f() {
  for (
    int i = 0;
// start
    i < 10;
    i++
// end
  ) {}
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsFatal(
        "Operation not applicable to a 'for' statement's condition and updaters.");
  }

  Future<void> test_bad_forLoop_init() async {
    await indexTestUnit('''
void f() {
  for (
// start
    int i = 0
// end
    ; i < 10;
    i++
  ) {}
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsFatal(
        "Cannot extract initialization part of a 'for' statement.");
  }

  Future<void> test_bad_forLoop_initAndCondition() async {
    await indexTestUnit('''
void f() {
  for (
// start
    int i = 0;
    i < 10;
// end
    i++
  ) {}
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsFatal(
        "Operation not applicable to a 'for' statement's initializer and condition.");
  }

  Future<void> test_bad_forLoop_updaters() async {
    await indexTestUnit('''
void f() {
  for (
    int i = 0;
    i < 10;
// start
    i++
// end
  ) {}
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsFatal(
        "Cannot extract increment part of a 'for' statement.");
  }

  Future<void> test_bad_forLoop_updatersAndBody() async {
    await indexTestUnit('''
void f() {
  for (
    int i = 0;
    i < 10;
// start
    i++
  ) {}
// end
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsFatal(
        'Not all selected statements are enclosed by the same parent statement.');
  }

  Future<void> test_bad_function_prefix() async {
    await indexTestUnit('''
import 'dart:io' as io;
void f() {
  io.exit(1);
}
''');
    _createRefactoringWithSuffix('io', '.exit');
    return _assertConditionsFatal('Cannot extract an import prefix.');
  }

  Future<void> test_bad_functionDeclaration_beforeParameters() async {
    await indexTestUnit('''
int test() => 42;
''');
    _createRefactoringForStringOffset('(');
    return _assertConditionsFatal(
        "Can only extract a single expression or a set of statements.");
  }

  Future<void> test_bad_functionDeclaration_inParameters() async {
    await indexTestUnit('''
int test() => 42;
''');
    _createRefactoringForStringOffset(')');
    return _assertConditionsFatal(
        "Can only extract a single expression or a set of statements.");
  }

  Future<void> test_bad_functionDeclaration_name() async {
    await indexTestUnit('''
int test() => 42;
''');
    _createRefactoringForStringOffset('st()');
    return _assertConditionsFatal(
        "Can only extract a single expression or a set of statements.");
  }

  Future<void> test_bad_methodName_reference() async {
    await indexTestUnit('''
void f() {
  f();
}
''');
    _createRefactoringWithSuffix('f', '();');
    return _assertConditionsFatal('Cannot extract a single method name.');
  }

  Future<void> test_bad_namePartOfDeclaration_function() async {
    await indexTestUnit('''
void f() {
}
''');
    _createRefactoringForString('f');
    return _assertConditionsFatal(
        'The selection does not cover a set of statements or an expression. '
        'Extend selection to a valid range.');
  }

  Future<void> test_bad_namePartOfDeclaration_variable() async {
    await indexTestUnit('''
void f() {
  int vvv = 0;
}
''');
    _createRefactoringForString('vvv');
    return _assertConditionsFatal(
        'Can only extract a single expression or a set of statements.');
  }

  Future<void> test_bad_namePartOfQualified() async {
    await indexTestUnit('''
class A {
  var fff;
}

void f(A a) {
  a.fff = 1;
}
''');
    _createRefactoringWithSuffix('fff', ' = 1');
    return _assertConditionsFatal(
        'Cannot extract name part of a property access.');
  }

  Future<void> test_bad_newMethodName_notIdentifier() async {
    await indexTestUnit('''
void f() {
// start
  print(0);
// end
}
''');
    _createRefactoringForStartEndComments();
    refactoring.name = 'bad-name';
    // check conditions
    return _assertConditionsFatal("Method name must not contain '-'.");
  }

  Future<void> test_bad_notSameParent() async {
    await indexTestUnit('''
void f() {
  while (false)
// start
  {
  }
  print(0);
// end
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsFatal(
        'Not all selected statements are enclosed by the same parent statement.');
  }

  Future<void> test_bad_parameterName_duplicate() async {
    await indexTestUnit('''
void f() {
  int v1 = 1;
  int v2 = 2;
// start
  int a = v1 + v2; // marker
// end
}
''');
    _createRefactoringForStartEndComments();
    // update parameters
    await refactoring.checkInitialConditions();
    {
      var parameters = _getParametersCopy();
      expect(parameters, hasLength(2));
      parameters[0].name = 'dup';
      parameters[1].name = 'dup';
      refactoring.parameters = parameters;
    }
    return _assertFinalConditionsError("Parameter 'dup' already exists");
  }

  Future<void> test_bad_parameterName_inUse_function() async {
    await indexTestUnit('''
void g() {
  int v1 = 1;
  int v2 = 2;
// start
  f(v1, v2);
// end
}
f(a, b) {}
''');
    _createRefactoringForStartEndComments();
    // update parameters
    await refactoring.checkInitialConditions();
    {
      var parameters = _getParametersCopy();
      expect(parameters, hasLength(2));
      parameters[0].name = 'f';
      refactoring.parameters = parameters;
    }
    return _assertFinalConditionsError(
        "'f' is already used as a name in the selected code");
  }

  Future<void> test_bad_parameterName_inUse_localVariable() async {
    await indexTestUnit('''
void f() {
  int v1 = 1;
  int v2 = 2;
// start
  int a = v1 + v2; // marker
// end
}
''');
    _createRefactoringForStartEndComments();
    // update parameters
    await refactoring.checkInitialConditions();
    {
      var parameters = _getParametersCopy();
      expect(parameters, hasLength(2));
      parameters[0].name = 'a';
      refactoring.parameters = parameters;
    }
    return _assertFinalConditionsError(
        "'a' is already used as a name in the selected code");
  }

  Future<void> test_bad_parameterName_inUse_method() async {
    await indexTestUnit('''
class A {
  void f() {
    int v1 = 1;
    int v2 = 2;
  // start
    m(v1, v2);
  // end
  }
  m(a, b) {}
}
''');
    _createRefactoringForStartEndComments();
    // update parameters
    await refactoring.checkInitialConditions();
    {
      var parameters = _getParametersCopy();
      expect(parameters, hasLength(2));
      parameters[0].name = 'm';
      refactoring.parameters = parameters;
    }
    return _assertFinalConditionsError(
        "'m' is already used as a name in the selected code");
  }

  Future<void> test_bad_selectionEndsInSomeNode() async {
    await indexTestUnit('''
void f() {
// start
  print(0);
  print(1);
// end
}
''');
    _createRefactoringForStartEndString('print(0', 'rint(1)');
    return _assertConditionsFatal(
        'The selection does not cover a set of statements or an expression. '
        'Extend selection to a valid range.');
  }

  Future<void> test_bad_statements_exit_notAllExecutionFlows() async {
    await indexTestUnit('''
void f(int p) {
// start
  if (p == 0) {
    return;
  }
// end
  print(p);
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsError(ExtractMethodRefactoringImpl.ERROR_EXITS);
  }

  Future<void> test_bad_statements_return_andAssignsVariable() async {
    await indexTestUnit('''
int f() {
// start
  var v = 0;
  return 42;
// end
  print(v);
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsFatal(
        'Ambiguous return value: Selected block contains assignment(s) to '
        'local variables and return statement.');
  }

  Future<void> test_bad_switchCase() async {
    await indexTestUnit('''
void f() {
  switch (1) {
// start
    case 0: break;
// end
  }
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsFatal(
        'Selection must either cover whole switch statement '
        'or parts of a single case block.');
  }

  Future<void> test_bad_tokensBetweenLastNodeAndSelectionEnd() async {
    await indexTestUnit('''
void f() {
// start
  print(0);
  print(1);
}
// end
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsFatal(
        'The end of the selection contains characters that do not belong to a statement.');
  }

  Future<void> test_bad_tokensBetweenSelectionStartAndFirstNode() async {
    await indexTestUnit('''
void f() {
// start
  print(0); // marker
  print(1);
// end
}
''');
    _createRefactoringForStartEndString('); // marker', '// end');
    return _assertConditionsFatal(
        'The beginning of the selection contains characters that do not belong to a statement.');
  }

  Future<void> test_bad_try_catchBlock_block() async {
    await indexTestUnit('''
void f() {
  try
  {}
  catch (e)
// start
  {}
// end
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsFatal(
        'Selection must either cover whole try statement or '
        'parts of try, catch, or finally block.');
  }

  Future<void> test_bad_try_catchBlock_complete() async {
    await indexTestUnit('''
void f() {
  try
  {}
// start
  catch (e)
  {}
// end
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsFatal(
        'Selection must either cover whole try statement or '
        'parts of try, catch, or finally block.');
  }

  Future<void> test_bad_try_catchBlock_exception() async {
    await indexTestUnit('''
void f() {
  try {
  } catch (
// start
  e
// end
  ) {
  }
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsFatal(
        'Cannot extract the name part of a declaration.');
  }

  Future<void> test_bad_try_finallyBlock() async {
    await indexTestUnit('''
void f() {
  try
  {}
  finally
// start
  {}
// end
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsFatal(
        'Selection must either cover whole try statement or '
        'parts of try, catch, or finally block.');
  }

  Future<void> test_bad_try_tryBlock() async {
    await indexTestUnit('''
void f() {
  try
// start
  {}
// end
  finally
  {}
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsFatal(
        'Selection must either cover whole try statement or '
        'parts of try, catch, or finally block.');
  }

  Future<void> test_bad_typeReference() async {
    await indexTestUnit('''
void f() {
  int a = 0;
}
''');
    _createRefactoringForString('int');
    return _assertConditionsFatal('Cannot extract a single type reference.');
  }

  Future<void> test_bad_typeReference_nullable() async {
    await indexTestUnit('''
// Dummy comment ("The selection offset must be greater than zero")
int? f;
''');
    _createRefactoringForString('int');
    return _assertConditionsFatal('Cannot extract a single type reference.');
  }

  Future<void> test_bad_typeReference_prefix() async {
    await indexTestUnit('''
import 'dart:io' as io;
void f() {
  io.File f = io.File('');
}
''');
    _createRefactoringWithSuffix('io', '.File f');
    return _assertConditionsFatal('Cannot extract an import prefix.');
  }

  Future<void> test_bad_variableDeclarationFragment() async {
    await indexTestUnit('''
void f() {
  int
// start
    a = 1
// end
    ,b = 2;
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsFatal(
        'Cannot extract a variable declaration fragment. Select whole declaration statement.');
  }

  Future<void> test_bad_while_conditionAndBody() async {
    await indexTestUnit('''
void f() {
  while
// start
    (false)
  {
  }
// end
}
''');
    _createRefactoringForStartEndComments();
    return _assertConditionsFatal(
        "Operation not applicable to a while statement's expression and body.");
  }

  Future<void> test_canExtractGetter_false_closure() async {
    await indexTestUnit('''
void f() {
  useFunction((_) => true);
}
useFunction(filter(String p)) {}
''');
    _createRefactoringForString('(_) => true');
    // apply refactoring
    await assertRefactoringConditionsOK();
    expect(refactoring.canCreateGetter, false);
    expect(refactoring.createGetter, false);
  }

  Future<void> test_canExtractGetter_false_fieldAssignment() async {
    await indexTestUnit('''
class A {
  var f;
  void m() {
// start
    f = 1;
// end
  }
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    await assertRefactoringConditionsOK();
    expect(refactoring.canCreateGetter, false);
    expect(refactoring.createGetter, false);
  }

  Future<void> test_canExtractGetter_false_hasParameters() async {
    await indexTestUnit('''
void f(int p) {
  int a = p + 1;
}
''');
    _createRefactoringForString('p + 1');
    // apply refactoring
    await assertRefactoringConditionsOK();
    expect(refactoring.canCreateGetter, false);
    expect(refactoring.createGetter, false);
  }

  Future<void> test_canExtractGetter_false_returnNotUsed_assignment() async {
    await indexTestUnit('''
var topVar = 0;
void f(int p) {
  topVar = 5;
}
''');
    _createRefactoringForString('topVar = 5');
    // apply refactoring
    await assertRefactoringConditionsOK();
    expect(refactoring.canCreateGetter, false);
    expect(refactoring.createGetter, false);
  }

  Future<void> test_canExtractGetter_false_returnNotUsed_noReturn() async {
    await indexTestUnit('''
var topVar = 0;
void f() {
// start
  int a = 1;
  int b = 2;
  topVar = a + b;
// end
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    await assertRefactoringConditionsOK();
    expect(refactoring.canCreateGetter, false);
    expect(refactoring.createGetter, false);
  }

  Future<void> test_canExtractGetter_true() async {
    await indexTestUnit('''
void f() {
  int a = 1 + 2;
}
''');
    _createRefactoringForString('1 + 2');
    // apply refactoring
    await assertRefactoringConditionsOK();
    expect(refactoring.canCreateGetter, true);
    expect(refactoring.createGetter, true);
  }

  Future<void> test_checkInitialCondition_false_outOfRange_length() async {
    await indexTestUnit('''
void f() {
  1 + 2;
}
''');
    _createRefactoring(0, 1 << 20);
    var status = await refactoring.checkAllConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL);
  }

  Future<void> test_checkInitialCondition_outOfRange_offset() async {
    await indexTestUnit('''
void f() {
  1 + 2;
}
''');
    _createRefactoring(-10, 20);
    var status = await refactoring.checkAllConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL);
  }

  Future<void> test_checkName() async {
    await indexTestUnit('''
void f() {
  int a = 1 + 2;
}
''');
    _createRefactoringForString('1 + 2');
    // empty
    refactoring.name = '';
    assertRefactoringStatus(
        refactoring.checkName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: 'Method name must not be empty.');
    // incorrect casing
    refactoring.name = 'Aaa';
    assertRefactoringStatus(
        refactoring.checkName(), RefactoringProblemSeverity.WARNING,
        expectedMessage: 'Method name should start with a lowercase letter.');
    // starts with digit
    refactoring.name = '0aa';
    assertRefactoringStatus(
        refactoring.checkName(), RefactoringProblemSeverity.FATAL,
        expectedMessage:
            'Method name must begin with a lowercase letter or underscore.');
    // invalid name (quote)
    refactoring.name = '"';
    assertRefactoringStatus(
        refactoring.checkName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: "Method name must not contain '\"'.");
    // OK
    refactoring.name = 'res';
    assertRefactoringStatusOK(refactoring.checkName());
  }

  Future<void> test_closure_asFunction_singleExpression() async {
    await indexTestUnit('''
process(f(x)) {}
void f() {
  process((x) => x * 2);
}
''');
    _createRefactoringForString('(x) => x * 2');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
process(f(x)) {}
void f() {
  process(res);
}

res(x) => x * 2;
''');
  }

  Future<void> test_closure_asFunction_statements() async {
    await indexTestUnit('''
process(f(x)) {}
void f() {
  process((x) {
    print(x);
    return x * 2;
  }); // marker
}
''');
    _createRefactoringForStartEndString('(x) {', '); // marker');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
process(f(x)) {}
void f() {
  process(res); // marker
}

res(x) {
  print(x);
  return x * 2;
}
''');
  }

  Future<void> test_closure_asMethod_statements() async {
    await indexTestUnit('''
process(f(x)) {}
class A {
  int k = 2;
  void f() {
    process((x) {
      print(x);
      return x * k;
    }); // marker
  }
}
''');
    _createRefactoringForStartEndString('(x) {', '); // marker');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
process(f(x)) {}
class A {
  int k = 2;
  void f() {
    process(res); // marker
  }

  res(x) {
    print(x);
    return x * k;
  }
}
''');
  }

  Future<void> test_closure_atArgumentName() async {
    await indexTestUnit('''
void process({int fff(int x)?}) {}
class C {
  void f() {
    process(fff: (int x) => x * 2);
  }
}
''');
    _createRefactoring(findOffset('ff: (int x)'), 0);
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void process({int fff(int x)?}) {}
class C {
  void f() {
    process(fff: res);
  }

  int res(int x) => x * 2;
}
''');
  }

  Future<void> test_closure_atParameters() async {
    await indexTestUnit('''
void process(num f(int x)) {}
class C {
  void f() {
    process((int x) => x * 2);
  }
}
''');
    _createRefactoring(findOffset('x) =>'), 0);
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void process(num f(int x)) {}
class C {
  void f() {
    process(res);
  }

  num res(int x) => x * 2;
}
''');
  }

  Future<void> test_closure_bad_referencesLocalVariable() async {
    await indexTestUnit('''
process(f(x)) {}
void f() {
  int k = 2;
  process((x) => x * k);
}
''');
    _createRefactoringForString('(x) => x * k');
    // check
    var status = await refactoring.checkInitialConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL,
        expectedMessage:
            'Cannot extract closure as method, it references 1 external variable.');
  }

  Future<void> test_closure_bad_referencesParameter() async {
    await indexTestUnit('''
process(f(x)) {}
void f(int k) {
  process((x) => x * k);
}
''');
    _createRefactoringForString('(x) => x * k');
    // check
    var status = await refactoring.checkInitialConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL,
        expectedMessage:
            'Cannot extract closure as method, it references 1 external variable.');
  }

  Future<void> test_fromTopLevelVariableInitializerClosure() async {
    await indexTestUnit('''
var X = 1;

dynamic Y = () {
  return 1 + X;
};
''');
    _createRefactoringForString('1 + X');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
var X = 1;

dynamic Y = () {
  return res();
};

int res() => 1 + X;
''');
  }

  Future<void> test_getExtractGetter_expression_true_binaryExpression() async {
    await indexTestUnit('''
void f() {
  print(1 + 2);
}
''');
    _createRefactoringForString('1 + 2');
    // apply refactoring
    await assertRefactoringConditionsOK();
    expect(refactoring.createGetter, true);
  }

  Future<void> test_getExtractGetter_expression_true_literal() async {
    await indexTestUnit('''
void f() {
  print(42);
}
''');
    _createRefactoringForString('42');
    // apply refactoring
    await assertRefactoringConditionsOK();
    expect(refactoring.createGetter, true);
  }

  Future<void>
      test_getExtractGetter_expression_true_prefixedExpression() async {
    await indexTestUnit('''
void f() {
  print(!true);
}
''');
    _createRefactoringForString('!true');
    // apply refactoring
    await assertRefactoringConditionsOK();
    expect(refactoring.createGetter, true);
  }

  Future<void>
      test_getExtractGetter_expression_true_prefixedIdentifier() async {
    await indexTestUnit('''
void f() {
  print(myValue.isEven);
}
int get myValue => 42;
''');
    _createRefactoringForString('myValue.isEven');
    // apply refactoring
    await assertRefactoringConditionsOK();
    expect(refactoring.createGetter, true);
  }

  Future<void> test_getExtractGetter_expression_true_propertyAccess() async {
    await indexTestUnit('''
void f() {
  print(1.isEven);
}
''');
    _createRefactoringForString('1.isEven');
    // apply refactoring
    await assertRefactoringConditionsOK();
    expect(refactoring.createGetter, true);
  }

  Future<void> test_getExtractGetter_statements() async {
    await indexTestUnit('''
void f() {
// start
  int v = 0;
// end
  print(v);
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    await assertRefactoringConditionsOK();
    expect(refactoring.createGetter, false);
  }

  Future<void> test_getRefactoringName_function() async {
    await indexTestUnit('''
void f() {
  print(1 + 2);
}
''');
    _createRefactoringForString('1 + 2');
    expect(refactoring.refactoringName, 'Extract Function');
  }

  Future<void> test_getRefactoringName_method() async {
    await indexTestUnit('''
class A {
  void f() {
    print(1 + 2);
  }
}
''');
    _createRefactoringForString('1 + 2');
    expect(refactoring.refactoringName, 'Extract Method');
  }

  Future<void> test_isAvailable_false_functionName() async {
    await indexTestUnit('''
void f() {}
''');
    _createRefactoringForString('f');
    expect(refactoring.isAvailable(), isFalse);
  }

  Future<void> test_isAvailable_true() async {
    await indexTestUnit('''
void f() {
  1 + 2;
}
''');
    _createRefactoringForString('1 + 2');
    expect(refactoring.isAvailable(), isTrue);
  }

  Future<void> test_names_singleExpression() async {
    await indexTestUnit('''
class TreeItem {}
TreeItem getSelectedItem() => throw 0;
process(my) {}
void f() {
  process(getSelectedItem()); // marker
  int treeItem = 0;
}
''');
    _createRefactoringWithSuffix('getSelectedItem()', '); // marker');
    // check names
    await refactoring.checkInitialConditions();
    expect(refactoring.names,
        unorderedEquals(['selectedItem', 'item', 'my', 'treeItem2']));
  }

  Future<void> test_offsets_lengths() async {
    await indexTestUnit('''
void f() {
  int a = 1 + 2;
  int b = 1 +  2;
}
''');
    _createRefactoringForString('1 +  2');
    // apply refactoring
    await refactoring.checkInitialConditions();
    expect(refactoring.offsets,
        unorderedEquals([findOffset('1 + 2'), findOffset('1 +  2')]));
    expect(refactoring.lengths, unorderedEquals([5, 6]));
  }

  Future<void> test_parameterType_nullableTypeWithArguments() async {
    await indexTestUnit('''
abstract class C {
  List<int>? get x;
}
class D {
  f(C c) {
    var x = c.x;
// start
    if (x != null) {
      print(x);
    }
// end
  }
}
''');
    _createRefactoringForStartEndComments();
    // do check
    await refactoring.checkInitialConditions();
    expect(refactoring.parameters[0].type, 'List<int>?');
  }

  Future<void> test_prefixPartOfQualified() async {
    await indexTestUnit('''
class A {
  var fff;
}
void f(A a) {
  a.fff = 5;
}
''');
    _createRefactoringForStringOffset('a.fff');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
class A {
  var fff;
}
void f(A a) {
  res(a).fff = 5;
}

A res(A a) => a;
''');
  }

  Future<void> test_returnType_closure() async {
    await indexTestUnit('''
process(f(x)) {}
void f() {
  process((x) => x * 2);
}
''');
    _createRefactoringForString('(x) => x * 2');
    // do check
    await refactoring.checkInitialConditions();
    expect(refactoring.returnType, '');
  }

  Future<void> test_returnType_expression() async {
    await indexTestUnit('''
void f() {
  int a = 1 + 2;
}
''');
    _createRefactoringForString('1 + 2');
    // do check
    await refactoring.checkInitialConditions();
    expect(refactoring.returnType, 'int');
  }

  Future<void> test_returnType_mixInterfaceFunction() async {
    await indexTestUnit('''
Object f() {
// start
  if (true) {
    return 1;
  } else {
    return () {};
  }
// end
}
''');
    _createRefactoringForStartEndComments();
    // do check
    await refactoring.checkInitialConditions();
    expect(refactoring.returnType, 'Object');
  }

  Future<void> test_returnType_statements() async {
    await indexTestUnit('''
void f() {
// start
  double v = 5.0;
// end
  print(v);
}
''');
    _createRefactoringForStartEndComments();
    // do check
    await refactoring.checkInitialConditions();
    expect(refactoring.returnType, 'double');
  }

  Future<void> test_returnType_statements_nullMix() async {
    await indexTestUnit('''
f(bool p) {
// start
  if (p) {
    return 42;
  }
  return null;
// end
}
''');
    _createRefactoringForStartEndComments();
    // do check
    await refactoring.checkInitialConditions();
    expect(refactoring.returnType, 'int?');
  }

  Future<void> test_returnType_statements_void() async {
    await indexTestUnit('''
void f() {
// start
  print(42);
// end
}
''');
    _createRefactoringForStartEndComments();
    // do check
    await refactoring.checkInitialConditions();
    expect(refactoring.returnType, 'void');
  }

  Future<void> test_setExtractGetter() async {
    await indexTestUnit('''
void f() {
  int a = 1 + 2;
}
''');
    _createRefactoringForString('1 + 2');
    // apply refactoring
    await assertRefactoringConditionsOK();
    expect(refactoring.canCreateGetter, true);
    expect(refactoring.createGetter, true);
    refactoringChange = await refactoring.createChange();
    assertTestChangeResult('''
void f() {
  int a = res;
}

int get res => 1 + 2;
''');
  }

  Future<void> test_singleExpression() async {
    await indexTestUnit('''
void f() {
  int a = 1 + 2;
}
''');
    _createRefactoringForString('1 + 2');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  int a = res();
}

int res() => 1 + 2;
''');
  }

  Future<void> test_singleExpression_cascade() async {
    await indexTestUnit('''
void f() {
  String s = '';
  var v = s..length;
}
''');
    _createRefactoringForString('s..length');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  String s = '';
  var v = res(s);
}

String res(String s) => s..length;
''');
  }

  Future<void> test_singleExpression_coveringExpression() async {
    await indexTestUnit('''
void f(int n) {
  var v = new FooBar(n);
}

class FooBar {
  FooBar(int count);
}
''');
    _createRefactoringForStringOffset('Bar(n);');
    return _assertSuccessfulRefactoring('''
void f(int n) {
  var v = res(n);
}

FooBar res(int n) => new FooBar(n);

class FooBar {
  FooBar(int count);
}
''');
  }

  Future<void> test_singleExpression_dynamic() async {
    await indexTestUnit('''
dynaFunction() {}
void f() {
  var v = dynaFunction(); // marker
}
''');
    _createRefactoringWithSuffix('dynaFunction()', '; // marker');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
dynaFunction() {}
void f() {
  var v = res(); // marker
}

res() => dynaFunction();
''');
  }

  Future<void> test_singleExpression_hasAwait() async {
    await indexTestUnit('''
import 'dart:async';
Future<int> getValue() async => 42;
void f() async {
  int v = await getValue();
  print(v);
}
''');
    _createRefactoringForString('await getValue()');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
import 'dart:async';
Future<int> getValue() async => 42;
void f() async {
  int v = await res();
  print(v);
}

Future<int> res() async => await getValue();
''');
  }

  Future<void> test_singleExpression_ignore_assignmentLeftHandSize() async {
    await indexTestUnit('''
void f() {
  getButton().text = 'txt';
  print(getButton().text); // marker
}
getButton() {}
''');
    _createRefactoringWithSuffix('getButton().text', '); // marker');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  getButton().text = 'txt';
  print(res()); // marker
}

res() => getButton().text;
getButton() {}
''');
  }

  Future<void> test_singleExpression_occurrences() async {
    await indexTestUnit('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int v3 = 3;
  int positiveA = v1 + v2; // marker
  int positiveB = v2 + v3;
  int positiveC = v1 +  v2;
  int positiveD = v1/*abc*/ + v2;
  int negA = 1 + 2;
  int negB = 1 + v2;
  int negC = v1 + 2;
  int negD = v1 * v2;
}
''');
    _createRefactoringWithSuffix('v1 + v2', '; // marker');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int v3 = 3;
  int positiveA = res(v1, v2); // marker
  int positiveB = res(v2, v3);
  int positiveC = res(v1, v2);
  int positiveD = res(v1, v2);
  int negA = 1 + 2;
  int negB = 1 + v2;
  int negC = v1 + 2;
  int negD = v1 * v2;
}

int res(int v1, int v2) => v1 + v2;
''');
  }

  Future<void> test_singleExpression_occurrences_disabled() async {
    await indexTestUnit('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int v3 = 3;
  int a = v1 + v2; // marker
  int b = v2 + v3;
}
''');
    _createRefactoringWithSuffix('v1 + v2', '; // marker');
    refactoring.extractAll = false;
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int v3 = 3;
  int a = res(v1, v2); // marker
  int b = v2 + v3;
}

int res(int v1, int v2) => v1 + v2;
''');
  }

  Future<void> test_singleExpression_occurrences_inClassOnly() async {
    await indexTestUnit('''
class A {
  myMethod() {
    int v1 = 1;
    int v2 = 2;
    int positiveA = v1 + v2; // marker
  }
}
void f() {
  int v1 = 1;
  int v2 = 2;
  int negA = v1 + v2;
}
''');
    _createRefactoringWithSuffix('v1 + v2', '; // marker');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
class A {
  myMethod() {
    int v1 = 1;
    int v2 = 2;
    int positiveA = res(v1, v2); // marker
  }

  int res(int v1, int v2) => v1 + v2;
}
void f() {
  int v1 = 1;
  int v2 = 2;
  int negA = v1 + v2;
}
''');
  }

  Future<void> test_singleExpression_occurrences_incompatibleTypes() async {
    await indexTestUnit('''
void f() {
  int x = 1;
  String y = 'foo';
  print(x.toString());
  print(y.toString());
}
''');
    _createRefactoringForString('x.toString()');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  int x = 1;
  String y = 'foo';
  print(res(x));
  print(y.toString());
}

String res(int x) => x.toString();
''');
  }

  Future<void> test_singleExpression_occurrences_inWholeUnit() async {
    await indexTestUnit('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int positiveA = v1 + v2; // marker
}
class A {
  myMethod() {
    int v1 = 1;
    int v2 = 2;
    int positiveB = v1 + v2;
  }
}
''');
    _createRefactoringWithSuffix('v1 + v2', '; // marker');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int positiveA = res(v1, v2); // marker
}

int res(int v1, int v2) => v1 + v2;
class A {
  myMethod() {
    int v1 = 1;
    int v2 = 2;
    int positiveB = res(v1, v2);
  }
}
''');
  }

  Future<void> test_singleExpression_parameter_functionTypeAlias() async {
    await indexTestUnit('''
typedef R Foo<S, R>(S s);
void f(Foo<String, int> foo, String s) {
  int a = foo(s);
}
''');
    _createRefactoringForString('foo(s)');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
typedef R Foo<S, R>(S s);
void f(Foo<String, int> foo, String s) {
  int a = res(foo, s);
}

int res(Foo<String, int> foo, String s) => foo(s);
''');
  }

  Future<void> test_singleExpression_recordType_named() async {
    await indexTestUnit('''
void f() {
  var r = (f1: 0, f2: true);
}
''');
    _createRefactoringForString('(f1: 0, f2: true)');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  var r = res();
}

({int f1, bool f2}) res() => (f1: 0, f2: true);
''');
  }

  Future<void> test_singleExpression_recordType_positional() async {
    await indexTestUnit('''
void f() {
  var r = (0, true);
}
''');
    _createRefactoringForString('(0, true)');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  var r = res();
}

(int, bool) res() => (0, true);
''');
  }

  Future<void> test_singleExpression_returnType_importLibrary() async {
    _addLibraryReturningAsync();
    await indexTestUnit('''
import 'asyncLib.dart';
void f() {
  var a = newCompleter();
}
''');
    _createRefactoringForString('newCompleter()');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
import 'asyncLib.dart';
import 'dart:async';
void f() {
  var a = res();
}

Completer<int> res() => newCompleter();
''');
  }

  Future<void> test_singleExpression_returnTypeGeneric() async {
    await indexTestUnit('''
void f() {
  var v = <String>[];
}
''');
    _createRefactoringForString('<String>[]');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  var v = res();
}

List<String> res() => <String>[];
''');
  }

  Future<void> test_singleExpression_returnTypePrefix() async {
    await indexTestUnit('''
import 'dart:math' as pref;
void f() {
  var v = new pref.Random();
}
''');
    _createRefactoringForString('new pref.Random()');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
import 'dart:math' as pref;
void f() {
  var v = res();
}

pref.Random res() => new pref.Random();
''');
  }

  Future<void>
      test_singleExpression_staticContext_extractFromInitializer() async {
    await indexTestUnit('''
class A {
  A(int v) {}
}
class B extends A {
  B() : super(1 + 2) {}
}
''');
    _createRefactoringForString('1 + 2');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
class A {
  A(int v) {}
}
class B extends A {
  B() : super(res()) {}

  static int res() => 1 + 2;
}
''');
  }

  Future<void> test_singleExpression_staticContext_extractFromInstance() async {
    await indexTestUnit('''
class A {
  instanceMethodA() {
    int v1 = 1;
    int v2 = 2;
    int positiveA = v1 + v2; // marker
  }
  instanceMethodB() {
    int v1 = 1;
    int v2 = 2;
    int positiveB = v1 + v2;
  }
  static staticMethodA() {
    int v1 = 1;
    int v2 = 2;
    int positiveA = v1 + v2;
  }
}
''');
    _createRefactoringWithSuffix('v1 + v2', '; // marker');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
class A {
  instanceMethodA() {
    int v1 = 1;
    int v2 = 2;
    int positiveA = res(v1, v2); // marker
  }

  static int res(int v1, int v2) => v1 + v2;
  instanceMethodB() {
    int v1 = 1;
    int v2 = 2;
    int positiveB = res(v1, v2);
  }
  static staticMethodA() {
    int v1 = 1;
    int v2 = 2;
    int positiveA = res(v1, v2);
  }
}
''');
  }

  Future<void> test_singleExpression_staticContext_extractFromStatic() async {
    await indexTestUnit('''
class A {
  static staticMethodA() {
    int v1 = 1;
    int v2 = 2;
    int positiveA = v1 + v2; // marker
  }
  static staticMethodB() {
    int v1 = 1;
    int v2 = 2;
    int positiveB = v1 + v2;
  }
  instanceMethodA() {
    int v1 = 1;
    int v2 = 2;
    int positiveA = v1 + v2;
  }
}
''');
    _createRefactoringWithSuffix('v1 + v2', '; // marker');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
class A {
  static staticMethodA() {
    int v1 = 1;
    int v2 = 2;
    int positiveA = res(v1, v2); // marker
  }

  static int res(int v1, int v2) => v1 + v2;
  static staticMethodB() {
    int v1 = 1;
    int v2 = 2;
    int positiveB = res(v1, v2);
  }
  instanceMethodA() {
    int v1 = 1;
    int v2 = 2;
    int positiveA = res(v1, v2);
  }
}
''');
  }

  Future<void> test_singleExpression_staticContext_hasInInitializer() async {
    await indexTestUnit('''
class A {
  A(int v) {}
}
class B extends A {
  B() : super(1 + 2) {}
  foo() {
    print(1 + 2); // marker
  }
}
''');
    _createRefactoringWithSuffix('1 + 2', '); // marker');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
class A {
  A(int v) {}
}
class B extends A {
  B() : super(res()) {}
  foo() {
    print(res()); // marker
  }

  static int res() => 1 + 2;
}
''');
  }

  Future<void> test_singleExpression_usesParameter() async {
    await indexTestUnit('''
fooA(int a1) {
  int a2 = 2;
  int a = a1 + a2;
}
fooB(int b1) {
  int b2 = 2;
  int b = b1 + b2;
}
''');
    _createRefactoringForString('a1 + a2');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
fooA(int a1) {
  int a2 = 2;
  int a = res(a1, a2);
}

int res(int a1, int a2) => a1 + a2;
fooB(int b1) {
  int b2 = 2;
  int b = res(b1, b2);
}
''');
  }

  Future<void> test_singleExpression_withVariables() async {
    await indexTestUnit('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int a = v1 + v2 + v1;
}
''');
    _createRefactoringForString('v1 + v2 + v1');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int a = res(v1, v2);
}

int res(int v1, int v2) => v1 + v2 + v1;
''');
  }

  Future<void> test_singleExpression_withVariables_doRename() async {
    await indexTestUnit('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int v3 = 3;
  int a = v1 + v2 + v1; // marker
  int b = v2 + v3 + v2;
}
''');
    _createRefactoringForString('v1 + v2 + v1');
    // apply refactoring
    await refactoring.checkInitialConditions();
    {
      var parameters = _getParametersCopy();
      expect(parameters, hasLength(2));
      expect(parameters[0].name, 'v1');
      expect(parameters[1].name, 'v2');
      parameters[0].name = 'par1';
      parameters[1].name = 'param2';
      refactoring.parameters = parameters;
    }
    await assertRefactoringFinalConditionsOK();
    refactoring.createGetter = false;
    return _assertRefactoringChange('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int v3 = 3;
  int a = res(v1, v2); // marker
  int b = res(v2, v3);
}

int res(int par1, int param2) => par1 + param2 + par1;
''');
  }

  Future<void> test_singleExpression_withVariables_doReorder() async {
    await indexTestUnit('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int v3 = 3;
  int a = v1 + v2; // marker
  int b = v2 + v3;
}
''');
    _createRefactoringForString('v1 + v2');
    // apply refactoring
    await refactoring.checkInitialConditions();
    {
      var parameters = _getParametersCopy();
      expect(parameters, hasLength(2));
      expect(parameters[0].name, 'v1');
      expect(parameters[1].name, 'v2');
      var parameter = parameters.removeAt(1);
      parameters.insert(0, parameter);
      refactoring.parameters = parameters;
    }
    await assertRefactoringFinalConditionsOK();
    refactoring.createGetter = false;
    return _assertRefactoringChange('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int v3 = 3;
  int a = res(v2, v1); // marker
  int b = res(v3, v2);
}

int res(int v2, int v1) => v1 + v2;
''');
  }

  Future<void> test_singleExpression_withVariables_namedExpression() async {
    await indexTestUnit('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int a = process(arg: v1 + v2);
}
process({arg}) {}
''');
    _createRefactoringForString('process(arg: v1 + v2)');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int a = res(v1, v2);
}

res(int v1, int v2) => process(arg: v1 + v2);
process({arg}) {}
''');
  }

  Future<void> test_singleExpression_withVariables_newType() async {
    await indexTestUnit('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int v3 = 3;
  int a = v1 + v2 + v3;
}
''');
    _createRefactoringForString('v1 + v2 + v3');
    // apply refactoring
    await refactoring.checkInitialConditions();
    {
      var parameters = _getParametersCopy();
      expect(parameters, hasLength(3));
      expect(parameters[0].name, 'v1');
      expect(parameters[1].name, 'v2');
      expect(parameters[2].name, 'v3');
      parameters[0].type = 'num';
      parameters[1].type = 'dynamic';
      parameters[2].type = '';
      refactoring.parameters = parameters;
    }
    await assertRefactoringFinalConditionsOK();
    refactoring.createGetter = false;
    return _assertRefactoringChange('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int v3 = 3;
  int a = res(v1, v2, v3);
}

int res(num v1, v2, v3) => v1 + v2 + v3;
''');
  }

  Future<void> test_singleExpression_withVariables_useBestType() async {
    await indexTestUnit('''
void f() {
  var v1 = 1;
  var v2 = 2;
  var a = v1 + v2 + v1; // marker
}
''');
    _createRefactoringForString('v1 + v2 + v1');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  var v1 = 1;
  var v2 = 2;
  var a = res(v1, v2); // marker
}

int res(int v1, int v2) => v1 + v2 + v1;
''');
  }

  Future<void> test_statements_assignment() async {
    await indexTestUnit('''
void f() {
  int v;
// start
  v = 5;
// end
  print(v);
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  int v;
// start
  v = res(v);
// end
  print(v);
}

int res(int v) {
  v = 5;
  return v;
}
''');
  }

  Future<void> test_statements_changeIndentation() async {
    await indexTestUnit('''
void f() {
  {
// start
    if (true) {
      print(0);
    }
// end
  }
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  {
// start
    res();
// end
  }
}

void res() {
  if (true) {
    print(0);
  }
}
''');
  }

  Future<void> test_statements_changeIndentation_multilineString() async {
    await indexTestUnit('''
void f() {
  {
// start
    print("""
first line
second line
    """);
// end
  }
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  {
// start
    res();
// end
  }
}

void res() {
  print("""
first line
second line
    """);
}
''');
  }

  Future<void> test_statements_definesVariable_notUsedOutside() async {
    await indexTestUnit('''
void f() {
  int a = 1;
  int b = 1;
// start
  int v = a + b;
  print(v);
// end
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  int a = 1;
  int b = 1;
// start
  res(a, b);
// end
}

void res(int a, int b) {
  int v = a + b;
  print(v);
}
''');
  }

  Future<void>
      test_statements_definesVariable_oneUsedOutside_assignment() async {
    await indexTestUnit('''
myFunctionA() {
  int a = 1;
// start
  a += 10;
// end
  print(a);
}
myFunctionB() {
  int b = 2;
  b += 10;
  print(b);
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
myFunctionA() {
  int a = 1;
// start
  a = res(a);
// end
  print(a);
}

int res(int a) {
  a += 10;
  return a;
}
myFunctionB() {
  int b = 2;
  b = res(b);
  print(b);
}
''');
  }

  Future<void>
      test_statements_definesVariable_oneUsedOutside_declaration() async {
    await indexTestUnit('''
myFunctionA() {
  int a = 1;
  int b = 2;
// start
  int v1 = a + b;
// end
  print(v1);
}
myFunctionB() {
  int a = 3;
  int b = 4;
  int v2 = a + b;
  print(v2);
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
myFunctionA() {
  int a = 1;
  int b = 2;
// start
  int v1 = res(a, b);
// end
  print(v1);
}

int res(int a, int b) {
  int v1 = a + b;
  return v1;
}
myFunctionB() {
  int a = 3;
  int b = 4;
  int v2 = res(a, b);
  print(v2);
}
''');
  }

  Future<void> test_statements_definesVariable_twoUsedOutside() async {
    await indexTestUnit('''
void f() {
// start
  int varA = 1;
  int varB = 2;
// end
  int v = varA + varB;
}
''');
    _createRefactoringForStartEndComments();
    // check conditions
    var status = await refactoring.checkInitialConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL);
  }

  Future<void> test_statements_duplicate_absolutelySame() async {
    await indexTestUnit('''
myFunctionA() {
  print(0);
  print(1);
}
myFunctionB() {
// start
  print(0);
  print(1);
// end
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
myFunctionA() {
  res();
}
myFunctionB() {
// start
  res();
// end
}

void res() {
  print(0);
  print(1);
}
''');
  }

  Future<void>
      test_statements_duplicate_declaresDifferentlyNamedVariable() async {
    await indexTestUnit('''
myFunctionA() {
  int varA = 1;
  print(varA);
}
myFunctionB() {
// start
  int varB = 1;
  print(varB);
// end
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
myFunctionA() {
  res();
}
myFunctionB() {
// start
  res();
// end
}

void res() {
  int varB = 1;
  print(varB);
}
''');
  }

  Future<void> test_statements_dynamic() async {
    await indexTestUnit('''
dynaFunction(p) => 0;
void f() {
// start
  var a = 1;
  var v = dynaFunction(a);
// end
  print(v);
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
dynaFunction(p) => 0;
void f() {
// start
  var v = res();
// end
  print(v);
}

res() {
  var a = 1;
  var v = dynaFunction(a);
  return v;
}
''');
  }

  /// We should always add ";" when invoke method with extracted statements.
  Future<void> test_statements_endsWithBlock() async {
    await indexTestUnit('''
void f() {
// start
  if (true) {
    print(0);
  }
// end
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
// start
  res();
// end
}

void res() {
  if (true) {
    print(0);
  }
}
''');
  }

  Future<void> test_statements_exit_throws() async {
    await indexTestUnit('''
void f(int p) {
// start
  if (p == 0) {
    return;
  }
  throw 'boo!';
// end
}
''');
    _createRefactoringForStartEndComments();
    await assertRefactoringConditionsOK();
  }

  Future<void> test_statements_functionPrefix() async {
    await indexTestUnit('''
import 'dart:io' as io;
void f() {
  io.exit(1);
}
''');
    _createRefactoringForString('io.exit(1)');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
import 'dart:io' as io;
void f() {
  res();
}

Never res() => io.exit(1);
''');
  }

  Future<void> test_statements_hasAwait_dynamicReturnType() async {
    await indexTestUnit('''
import 'dart:async';
Future getValue() async => 42;
void f() async {
// start
  var v = await getValue();
// end
  print(v);
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
import 'dart:async';
Future getValue() async => 42;
void f() async {
// start
  var v = await res();
// end
  print(v);
}

Future<dynamic> res() async {
  var v = await getValue();
  return v;
}
''');
  }

  Future<void> test_statements_hasAwait_expression() async {
    await indexTestUnit('''
import 'dart:async';
Future<int> getValue() async => 42;
void f() async {
// start
  int v = await getValue();
  v += 2;
// end
  print(v);
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
import 'dart:async';
Future<int> getValue() async => 42;
void f() async {
// start
  int v = await res();
// end
  print(v);
}

Future<int> res() async {
  int v = await getValue();
  v += 2;
  return v;
}
''');
  }

  Future<void> test_statements_hasAwait_forEach() async {
    await indexTestUnit('''
import 'dart:async';
Stream<int> getValueStream() => throw 0;
void f() async {
// start
  int sum = 0;
  await for (int v in getValueStream()) {
    sum += v;
  }
// end
  print(sum);
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
import 'dart:async';
Stream<int> getValueStream() => throw 0;
void f() async {
// start
  int sum = await res();
// end
  print(sum);
}

Future<int> res() async {
  int sum = 0;
  await for (int v in getValueStream()) {
    sum += v;
  }
  return sum;
}
''');
  }

  /// `await` in a nested function should not result in `await` at the call to
  /// the new function.
  Future<void> test_statements_hasAwait_functionExpression() async {
    await indexTestUnit('''
void g(Future<void> Function() func) {}
void f() {
// start
  g(() async {
    await null;
  });
// end
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void g(Future<void> Function() func) {}
void f() {
// start
  res();
// end
}

void res() {
  g(() async {
    await null;
  });
}
''');
  }

  Future<void> test_statements_hasAwait_voidReturnType() async {
    await indexTestUnit('''
import 'dart:async';
Future<int> getValue() async => 42;
void f() async {
// start
  int v = await getValue();
  print(v);
// end
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
import 'dart:async';
Future<int> getValue() async => 42;
void f() async {
// start
  await res();
// end
}

Future<void> res() async {
  int v = await getValue();
  print(v);
}
''');
  }

  Future<void> test_statements_inSwitchMember() async {
    await indexTestUnit('''
class A {
  foo(int p) {
    switch (p) {
      case 0:
// start
        print(0);
// end
        break;
      default:
        break;
    }
  }
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
class A {
  foo(int p) {
    switch (p) {
      case 0:
// start
        res();
// end
        break;
      default:
        break;
    }
  }

  void res() {
    print(0);
  }
}
''');
  }

  Future<void> test_statements_localFunction() async {
    await indexTestUnit('''
void f() {
// start
  void g() {}
  g();
// end
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
// start
  res();
// end
}

void res() {
  void g() {}
  g();
}
''');
  }

  Future<void> test_statements_method() async {
    await indexTestUnit('''
class A {
  foo() {
// start
    print(0);
// end
  }
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
class A {
  foo() {
// start
    res();
// end
  }

  void res() {
    print(0);
  }
}
''');
  }

  Future<void> test_statements_noDuplicates() async {
    await indexTestUnit('''
void f() {
  int a = 1;
  int b = 1;
// start
  print(a);
// end
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  int a = 1;
  int b = 1;
// start
  res(a);
// end
}

void res(int a) {
  print(a);
}
''');
  }

  Future<void> test_statements_parameters_ignoreInnerPropagatedType() async {
    await indexTestUnit('''
void f(Object x) {
// start
  if (x is int) {
    print('int');
  }
  if (x is bool) {
    print('bool');
  }
// end
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f(Object x) {
// start
  res(x);
// end
}

void res(Object x) {
  if (x is int) {
    print('int');
  }
  if (x is bool) {
    print('bool');
  }
}
''');
  }

  Future<void> test_statements_parameters_importType() async {
    _addLibraryReturningAsync();
    await indexTestUnit('''
import 'asyncLib.dart';
void f() {
  var v = newCompleter();
// start
  print(v);
// end
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
import 'asyncLib.dart';
import 'dart:async';
void f() {
  var v = newCompleter();
// start
  res(v);
// end
}

void res(Completer<int> v) {
  print(v);
}
''');
  }

  Future<void> test_statements_parameters_localFunction() async {
    await indexTestUnit('''
class C {
  int f(int a) {
    int callback(int x, int y) => x + a;
    int b = a + 1;
// start
    int c = callback(b, 2);
// end
    int d = c + 1;
    return d;
  }
}''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
class C {
  int f(int a) {
    int callback(int x, int y) => x + a;
    int b = a + 1;
// start
    int c = res(callback, b);
// end
    int d = c + 1;
    return d;
  }

  int res(int callback(int x, int y), int b) {
    int c = callback(b, 2);
    return c;
  }
}''');
  }

  Future<void> test_statements_parameters_noLocalVariableConflict() async {
    await indexTestUnit('''
int f(int x) {
  int y = x + 1;
// start
  if (y % 2 == 0) {
    int y = x + 2;
    return y;
  } else {
    return y;
  }
// end
}
''');
    _createRefactoringForStartEndComments();
    await assertRefactoringConditionsOK();
  }

  Future<void> test_statements_return_last() async {
    await indexTestUnit('''
int f() {
// start
  int v = 5;
  return v + 1;
// end
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
int f() {
// start
  return res();
// end
}

int res() {
  int v = 5;
  return v + 1;
}
''');
  }

  Future<void> test_statements_return_multiple_ifElse() async {
    await indexTestUnit('''
num f(bool b) {
// start
  if (b) {
    return 1;
  } else {
    return 2.0;
  }
// end
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
num f(bool b) {
// start
  return res(b);
// end
}

num res(bool b) {
  if (b) {
    return 1;
  } else {
    return 2.0;
  }
}
''');
  }

  Future<void> test_statements_return_multiple_ifThen() async {
    await indexTestUnit('''
num f(bool b) {
// start
  if (b) {
    return 1;
  }
  return 2.0;
// end
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
num f(bool b) {
// start
  return res(b);
// end
}

num res(bool b) {
  if (b) {
    return 1;
  }
  return 2.0;
}
''');
  }

  Future<void> test_statements_return_multiple_ignoreInFunction() async {
    await indexTestUnit('''
int f() {
// start
  localFunction() {
    return 'abc';
  }
  return 42;
// end
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
int f() {
// start
  return res();
// end
}

int res() {
  localFunction() {
    return 'abc';
  }
  return 42;
}
''');
  }

  Future<void> test_statements_return_multiple_interfaceFunction() async {
    await indexTestUnit('''
f(bool b) {
// start
  if (b) {
    return 1;
  }
  return () {};
// end
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
f(bool b) {
// start
  return res(b);
// end
}

Object res(bool b) {
  if (b) {
    return 1;
  }
  return () {};
}
''');
  }

  Future<void>
      test_statements_return_multiple_sameElementDifferentTypeArgs() async {
    await indexTestUnit('''
f(bool b) {
// start
  if (b) {
    print(true);
    return <int>[];
  } else {
    print(false);
    return <String>[];
  }
// end
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
f(bool b) {
// start
  return res(b);
// end
}

List<Object> res(bool b) {
  if (b) {
    print(true);
    return <int>[];
  } else {
    print(false);
    return <String>[];
  }
}
''');
  }

  Future<void> test_statements_return_single() async {
    await indexTestUnit('''
int f() {
// start
  return 42;
// end
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
int f() {
// start
  return res();
// end
}

int res() {
  return 42;
}
''');
  }

  Future<void> test_statements_topFunction_parameters_recordType() async {
    await indexTestUnit('''
void f((int, String) r) {
// start
  print(r);
// end
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f((int, String) r) {
// start
  res(r);
// end
}

void res((int, String) r) {
  print(r);
}
''');
  }

  /// We have 3 identical statements, but select only 2.
  /// This should not cause problems.
  Future<void> test_statements_twoOfThree() async {
    await indexTestUnit('''
void f() {
// start
  print(0);
  print(0);
// end
  print(0);
}
''');
    _createRefactoringForStartEndComments();
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
// start
  res();
// end
  print(0);
}

void res() {
  print(0);
  print(0);
}
''');
  }

  Future<void> test_string() async {
    await indexTestUnit('''
void f() {
  var a = 'test';
}
''');
    _createRefactoringForString('test');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  var a = res();
}

String res() => 'test';
''');
  }

  void _addLibraryReturningAsync() {
    newFile('$testPackageLibPath/asyncLib.dart', r'''
import 'dart:async';

Completer<int> newCompleter() => null;
''');
  }
}

class _ExtractMethodTest extends RefactoringTest {
  @override
  late ExtractMethodRefactoringImpl refactoring;

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

  Future<void> _assertFinalConditionsError(String message) async {
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR,
        expectedMessage: message);
  }

  Future<void> _assertRefactoringChange(String expectedCode) async {
    var refactoringChange = await refactoring.createChange();
    this.refactoringChange = refactoringChange;
    assertTestChangeResult(expectedCode);
  }

  /// Checks that all conditions are OK and the result of applying the [Change]
  /// to [testUnit] is [expectedCode].
  Future<void> _assertSuccessfulRefactoring(String expectedCode) async {
    await assertRefactoringConditionsOK();
    refactoring.createGetter = false;
    return _assertRefactoringChange(expectedCode);
  }

  void _createRefactoring(int offset, int length) {
    refactoring = ExtractMethodRefactoringImpl(
        searchEngine, testAnalysisResult, offset, length);
    refactoring.name = 'res';
  }

  void _createRefactoringForStartEndComments() {
    final eol = testCode.contains('\r\n') ? '\r\n' : '\r';
    var offset = findEnd('// start') + eol.length;
    var end = findOffset('// end');
    _createRefactoring(offset, end - offset);
  }

  void _createRefactoringForStartEndString(
      String startSearch, String endSearch) {
    var offset = findOffset(startSearch);
    var end = findOffset(endSearch);
    _createRefactoring(offset, end - offset);
  }

  /// Creates a new refactoring in [refactoring] for the selection range of the
  /// given [search] pattern.
  void _createRefactoringForString(String search) {
    var offset = findOffset(search);
    var length = search.length;
    _createRefactoring(offset, length);
  }

  /// Creates a new refactoring in [refactoring] at the offset of the given
  /// [search] pattern, and with `0` length.
  void _createRefactoringForStringOffset(String search) {
    var offset = findOffset(search);
    _createRefactoring(offset, 0);
  }

  void _createRefactoringWithSuffix(String selectionSearch, String suffix) {
    var offset = findOffset(selectionSearch + suffix);
    var length = selectionSearch.length;
    _createRefactoring(offset, length);
  }

  /// Returns a deep copy of [refactoring] parameters.
  /// There was a bug masked by updating parameter instances shared between the
  /// refactoring and the test.
  List<RefactoringMethodParameter> _getParametersCopy() {
    return refactoring.parameters.map((p) {
      return RefactoringMethodParameter(p.kind, p.type, p.name, id: p.id);
    }).toList();
  }
}
