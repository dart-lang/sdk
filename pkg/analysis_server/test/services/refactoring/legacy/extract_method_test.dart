// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/refactoring/legacy/extract_method.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/src/utilities/string_utilities.dart';
import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../abstract_single_unit.dart';
import 'abstract_refactoring.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddLibraryImportsTest);
    defineReflectiveTests(ExtractMethodTest_Enum);
    defineReflectiveTests(ExtractMethodTest_Extension);
    defineReflectiveTests(ExtractMethodTest_ExtensionType);
    defineReflectiveTests(ExtractMethodTest_Mixin);
    defineReflectiveTests(ExtractMethodTest);
  });
}

@reflectiveTest
class AddLibraryImportsTest extends AbstractSingleUnitTest {
  @override
  void setUp() {
    useLineEndingsForPlatform = false;
    super.setUp();
  }

  Future<void> test_dart_doubleQuotes() async {
    registerLintRules();
    newAnalysisOptionsYamlFile(
      testPackageRootPath,
      analysisOptionsContent(rules: ['prefer_double_quotes']),
    );

    await resolveTestCode('''
/// Comment.

class A {}
''');
    var newLibrary1 = _getDartSource('dart:math');
    var newLibrary2 = _getDartSource('dart:async');
    await _assertAddLibraryImport(
      [newLibrary1, newLibrary2],
      '''
/// Comment.

import "dart:async";
import "dart:math";

class A {}
''',
    );
  }

  Future<void> test_dart_hasImports_between() async {
    await resolveTestCode('''
import 'dart:async';
import 'dart:math';
''');
    var newLibrary = _getDartSource('dart:collection');
    await _assertAddLibraryImport(
      [newLibrary],
      '''
import 'dart:async';
import 'dart:collection';
import 'dart:math';
''',
    );
  }

  Future<void> test_dart_hasImports_first() async {
    await resolveTestCode('''
import 'dart:collection';
import 'dart:math';
''');
    var newLibrary = _getDartSource('dart:async');
    await _assertAddLibraryImport(
      [newLibrary],
      '''
import 'dart:async';
import 'dart:collection';
import 'dart:math';
''',
    );
  }

  Future<void> test_dart_hasImports_last() async {
    await resolveTestCode('''
import 'dart:async';
import 'dart:collection';
''');
    var newLibrary = _getDartSource('dart:math');
    await _assertAddLibraryImport(
      [newLibrary],
      '''
import 'dart:async';
import 'dart:collection';
import 'dart:math';
''',
    );
  }

  Future<void> test_dart_hasImports_multiple() async {
    await resolveTestCode('''
import 'dart:collection';
import 'dart:math';
''');
    var newLibrary1 = _getDartSource('dart:async');
    var newLibrary2 = _getDartSource('dart:html');
    await _assertAddLibraryImport(
      [newLibrary1, newLibrary2],
      '''
import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:math';
''',
    );
  }

  Future<void> test_dart_hasImports_multiple_first() async {
    await resolveTestCode('''
import 'dart:html';
import 'dart:math';
''');
    var newLibrary1 = _getDartSource('dart:async');
    var newLibrary2 = _getDartSource('dart:collection');
    await _assertAddLibraryImport(
      [newLibrary1, newLibrary2],
      '''
import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:math';
''',
    );
  }

  Future<void> test_dart_hasImports_multiple_last() async {
    await resolveTestCode('''
import 'dart:async';
import 'dart:collection';
''');
    var newLibrary1 = _getDartSource('dart:html');
    var newLibrary2 = _getDartSource('dart:math');
    await _assertAddLibraryImport(
      [newLibrary1, newLibrary2],
      '''
import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:math';
''',
    );
  }

  Future<void> test_dart_hasLibraryDirective() async {
    await resolveTestCode('''
library test;

class A {}
''');
    var newLibrary1 = _getDartSource('dart:math');
    var newLibrary2 = _getDartSource('dart:async');
    await _assertAddLibraryImport(
      [newLibrary1, newLibrary2],
      '''
library test;

import 'dart:async';
import 'dart:math';

class A {}
''',
    );
  }

  Future<void> test_dart_noDirectives_hasComment() async {
    await resolveTestCode('''
/// Comment.

class A {}
''');
    var newLibrary1 = _getDartSource('dart:math');
    var newLibrary2 = _getDartSource('dart:async');
    await _assertAddLibraryImport(
      [newLibrary1, newLibrary2],
      '''
/// Comment.

import 'dart:async';
import 'dart:math';

class A {}
''',
    );
  }

  Future<void> test_dart_noDirectives_hasShebang() async {
    await resolveTestCode('''
#!/bin/dart

class A {}
''');
    var newLibrary1 = _getDartSource('dart:math');
    var newLibrary2 = _getDartSource('dart:async');
    await _assertAddLibraryImport(
      [newLibrary1, newLibrary2],
      '''
#!/bin/dart

import 'dart:async';
import 'dart:math';

class A {}
''',
    );
  }

  Future<void> test_dart_noDirectives_noShebang() async {
    await resolveTestCode('''
class A {}
''');
    var newLibrary1 = _getDartSource('dart:math');
    var newLibrary2 = _getDartSource('dart:async');
    await _assertAddLibraryImport(
      [newLibrary1, newLibrary2],
      '''
import 'dart:async';
import 'dart:math';

class A {}
''',
    );
  }

  Future<void> test_package_hasDart_hasPackages_insertAfter() async {
    newFile('$workspaceRootPath/aaa/lib/aaa.dart', '');
    newFile('$workspaceRootPath/bbb/lib/bbb.dart', '');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()
            ..add(name: 'aaa', rootPath: '$workspaceRootPath/aaa')
            ..add(name: 'bbb', rootPath: '$workspaceRootPath/bbb'),
    );

    await resolveTestCode('''
import 'dart:async';

import 'package:aaa/aaa.dart';
''');
    var newLibrary = _getSource('/lib/bbb.dart', 'package:bbb/bbb.dart');
    await _assertAddLibraryImport(
      [newLibrary],
      '''
import 'dart:async';

import 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';
''',
    );
  }

  Future<void> test_package_hasDart_hasPackages_insertBefore() async {
    newFile('$workspaceRootPath/aaa/lib/aaa.dart', '');
    newFile('$workspaceRootPath/bbb/lib/bbb.dart', '');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()
            ..add(name: 'aaa', rootPath: '$workspaceRootPath/aaa')
            ..add(name: 'bbb', rootPath: '$workspaceRootPath/bbb'),
    );

    await resolveTestCode('''
import 'dart:async';

import 'package:bbb/bbb.dart';
''');
    var newLibrary = _getSource('/lib/aaa.dart', 'package:aaa/aaa.dart');
    await _assertAddLibraryImport(
      [newLibrary],
      '''
import 'dart:async';

import 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';
''',
    );
  }

  Future<void> test_package_hasImports_between() async {
    newFile('$workspaceRootPath/aaa/lib/aaa.dart', '');
    newFile('$workspaceRootPath/bbb/lib/bbb.dart', '');
    newFile('$workspaceRootPath/ccc/lib/ccc.dart', '');
    newFile('$workspaceRootPath/ddd/lib/ddd.dart', '');

    writeTestPackageConfig(
      config:
          PackageConfigFileBuilder()
            ..add(name: 'aaa', rootPath: '$workspaceRootPath/aaa')
            ..add(name: 'bbb', rootPath: '$workspaceRootPath/bbb')
            ..add(name: 'ccc', rootPath: '$workspaceRootPath/ccc')
            ..add(name: 'ddd', rootPath: '$workspaceRootPath/ddd'),
    );

    await resolveTestCode('''
import 'package:aaa/aaa.dart';
import 'package:ddd/ddd.dart';
''');
    var newLibrary1 = _getSource('/lib/bbb.dart', 'package:bbb/bbb.dart');
    var newLibrary2 = _getSource('/lib/ccc.dart', 'package:ccc/ccc.dart');
    await _assertAddLibraryImport(
      [newLibrary1, newLibrary2],
      '''
import 'package:aaa/aaa.dart';
import 'package:bbb/bbb.dart';
import 'package:ccc/ccc.dart';
import 'package:ddd/ddd.dart';
''',
    );
  }

  Future<void> _assertAddLibraryImport(
    List<Source> newLibraries,
    String expectedCode,
  ) async {
    var change = SourceChange('');
    await addLibraryImports(
      testAnalysisResult.session,
      change,
      testLibraryElement,
      newLibraries.toSet(),
    );
    var testEdit = change.getFileEdit(testFile.path);
    var resultCode = SourceEdit.applySequence(testCode, testEdit!.edits);
    expect(resultCode, expectedCode);
  }

  Source _getDartSource(String uri) {
    var path = removeStart(uri, 'dart:');
    return _SourceMock('/sdk/lib/$path.dart', Uri.parse(uri));
  }

  Source _getSource(String path, String uri) {
    return _SourceMock(path, Uri.parse(uri));
  }
}

@reflectiveTest
class ExtractMethodTest extends _ExtractMethodTest {
  Future<void> test_bad_assignmentLeftHandSide() async {
    await _createRefactoring('''
void f() {
  int aaa;
  [!aaa !]= 0;
}
''');
    return _assertConditionsFatal(
      'Cannot extract the left-hand side of an assignment.',
    );
  }

  Future<void> test_bad_comment_selectionEndsInside() async {
    await _createRefactoring('''
void f() {
  [!print(0); /* !] */
}
''');
    return _assertConditionsFatal('Selection ends inside a comment.');
  }

  Future<void> test_bad_comment_selectionStartsInside() async {
    await _createRefactoring('''
void f() {
/* [! */ print(0); !]
}
''');
    return _assertConditionsFatal('Selection begins inside a comment.');
  }

  Future<void> test_bad_conflict_method_alreadyDeclaresMethod() async {
    await _createRefactoring('''
class A {
  void res() {}
  void f() {
    [!print(0);!]
  }
}
''');
    return _assertConditionsError(
      "Class 'A' already declares method with name 'res'.",
    );
  }

  Future<void> test_bad_conflict_method_shadowsSuperDeclaration() async {
    await _createRefactoring('''
class A {
  void res() {} // marker
}
class B extends A {
  void f() {
    res();
    [!print(0);!]
  }
}
''');
    return _assertConditionsError("Created method will shadow method 'A.res'.");
  }

  Future<void> test_bad_conflict_topLevel_alreadyDeclaresFunction() async {
    await _createRefactoring('''
library my.lib;

void res() {}
void f() {
  [!print(0);!]
}
''');
    return _assertConditionsError(
      "Library already declares function with name 'res'.",
    );
  }

  Future<void> test_bad_conflict_topLevel_willHideInheritedMemberUsage() async {
    await _createRefactoring('''
class A {
  void res() {}
}
class B extends A {
  foo() {
    res(); // marker
  }
}
void f() {
  [!print(0);!]
}
''');
    return _assertConditionsError(
      "Created function will shadow method 'A.res'.",
    );
  }

  Future<void> test_bad_constructor_initializer() async {
    await _createRefactoring('''
class A {
  int f;
  A() : [!f = 0!] {}
}
''');
    return _assertConditionsFatal(
      'Cannot extract a constructor initializer. Select expression part of initializer.',
    );
  }

  Future<void> test_bad_constructor_redirectingConstructor() async {
    await _createRefactoring('''
class A {
  A() : [!this.named()!];
  A.named() {}
}
''');
    return _assertConditionsFatal(
      'Cannot extract a constructor initializer. Select expression part of initializer.',
    );
  }

  Future<void> test_bad_constructor_superConstructor() async {
    await _createRefactoring('''
class A {}
class B extends A {
  B() : [!super()!];
}
''');
    return _assertConditionsFatal(
      'Cannot extract a constructor initializer. Select expression part of initializer.',
    );
  }

  Future<void> test_bad_directive_combinator() async {
    await _createRefactoring('''
import 'dart:async' [!show!] FutureOr;
''');
    return _assertConditionsFatal('Cannot extract a directive.');
  }

  Future<void> test_bad_directive_combinatorNames() async {
    await _createRefactoring('''
import 'dart:async' show [!FutureOr!];
''');
    return _assertConditionsFatal('Cannot extract a directive.');
  }

  Future<void> test_bad_directive_import() async {
    await _createRefactoring('''
// Dummy comment ("The selection offset must be greater than zero")
[!import!] 'dart:async';
''');
    return _assertConditionsFatal('Cannot extract a directive.');
  }

  Future<void> test_bad_directive_prefixAs() async {
    await _createRefactoring('''
import 'dart:core' [!as!] core;
''');
    return _assertConditionsFatal('Cannot extract a directive.');
  }

  Future<void> test_bad_directive_prefixName() async {
    await _createRefactoring('''
import 'dart:async' as [!prefixName!];
''');
    return _assertConditionsFatal('Cannot extract a directive.');
  }

  Future<void> test_bad_directive_uriString() async {
    await _createRefactoring('''
import '[!dart:async!]';
''');
    return _assertConditionsFatal('Cannot extract a directive.');
  }

  Future<void> test_bad_doWhile_body() async {
    await _createRefactoring('''
void f() {
  do
  [!{
  }!]
  while (true);
}
''');
    return _assertConditionsFatal(
      "Operation not applicable to a 'do' statement's body and expression.",
    );
  }

  Future<void> test_bad_emptySelection() async {
    await _createRefactoring('''
void f() {
  [! !]
  print(0);
}
''');
    return _assertConditionsFatal(
      'Can only extract a single expression or a set of statements.',
    );
  }

  Future<void> test_bad_forLoop_conditionAndUpdaters() async {
    await _createRefactoring('''
void f() {
  for (
    int i = 0;
    [!i < 10;
    i++!]
  ) {}
}
''');
    return _assertConditionsFatal(
      "Operation not applicable to a 'for' statement's condition and updaters.",
    );
  }

  Future<void> test_bad_forLoop_init() async {
    await _createRefactoring('''
void f() {
  for (
    [!int i = 0!]
    ; i < 10;
    i++
  ) {}
}
''');
    return _assertConditionsFatal(
      "Cannot extract initialization part of a 'for' statement.",
    );
  }

  Future<void> test_bad_forLoop_initAndCondition() async {
    await _createRefactoring('''
void f() {
  for (
    [!int i = 0;
    i < 10;!]
    i++
  ) {}
}
''');
    return _assertConditionsFatal(
      "Operation not applicable to a 'for' statement's initializer and condition.",
    );
  }

  Future<void> test_bad_forLoop_updaters() async {
    await _createRefactoring('''
void f() {
  for (
    int i = 0;
    i < 10;
    [!i++!]
  ) {}
}
''');
    return _assertConditionsFatal(
      "Cannot extract increment part of a 'for' statement.",
    );
  }

  Future<void> test_bad_forLoop_updatersAndBody() async {
    await _createRefactoring('''
void f() {
  for (
    int i = 0;
    i < 10;
    [!i++
  ) {}!]
}
''');
    return _assertConditionsFatal(
      'Not all selected statements are enclosed by the same parent statement.',
    );
  }

  Future<void> test_bad_function_prefix() async {
    await _createRefactoring('''
import 'dart:io' as io;
void f() {
  [!io!].exit(1);
}
''');
    return _assertConditionsFatal('Cannot extract an import prefix.');
  }

  Future<void> test_bad_functionDeclaration_beforeParameters() async {
    await _createRefactoring('''
int test^() => 42;
''');
    return _assertConditionsFatal(
      'Can only extract a single expression or a set of statements.',
    );
  }

  Future<void> test_bad_functionDeclaration_inParameters() async {
    await _createRefactoring('''
int test(^) => 42;
''');
    return _assertConditionsFatal(
      'Can only extract a single expression or a set of statements.',
    );
  }

  Future<void> test_bad_functionDeclaration_name() async {
    await _createRefactoring('''
int te^st() => 42;
''');
    return _assertConditionsFatal(
      'Can only extract a single expression or a set of statements.',
    );
  }

  Future<void> test_bad_methodName_reference() async {
    await _createRefactoring('''
void f() {
  [!f!]();
}
''');
    return _assertConditionsFatal('Cannot extract a single method name.');
  }

  Future<void> test_bad_namePartOfDeclaration_function() async {
    await _createRefactoring('''
void [!f!]() {}
''');
    return _assertConditionsFatal(
      'The selection does not cover a set of statements or an expression. '
      'Extend selection to a valid range.',
    );
  }

  Future<void> test_bad_namePartOfDeclaration_variable() async {
    await _createRefactoring('''
void f() {
  int [!vvv!] = 0;
}
''');
    return _assertConditionsFatal(
      'Can only extract a single expression or a set of statements.',
    );
  }

  Future<void> test_bad_namePartOfQualified() async {
    await _createRefactoring('''
class A {
  var fff;
}

void f(A a) {
  a.[!fff!] = 1;
}
''');
    return _assertConditionsFatal(
      'Cannot extract name part of a property access.',
    );
  }

  Future<void> test_bad_newMethodName_notIdentifier() async {
    await _createRefactoring('''
void f() {
  [!print(0);!]
}
''');
    refactoring.name = 'bad-name';
    // check conditions
    return _assertConditionsFatal("Method name must not contain '-'.");
  }

  Future<void> test_bad_notSameParent() async {
    await _createRefactoring('''
void f() {
  while (false)
  [!{
  }
  print(0);!]
}
''');
    return _assertConditionsFatal(
      'Not all selected statements are enclosed by the same parent statement.',
    );
  }

  Future<void> test_bad_parameterName_duplicate() async {
    await _createRefactoring('''
void f() {
  int v1 = 1;
  int v2 = 2;
  [!int a = v1 + v2; // marker !]
}
''');
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
    await _createRefactoring('''
void g() {
  int v1 = 1;
  int v2 = 2;
  [!f(v1, v2);!]
}
f(a, b) {}
''');
    // update parameters
    await refactoring.checkInitialConditions();
    {
      var parameters = _getParametersCopy();
      expect(parameters, hasLength(2));
      parameters[0].name = 'f';
      refactoring.parameters = parameters;
    }
    return _assertFinalConditionsError(
      "'f' is already used as a name in the selected code",
    );
  }

  Future<void> test_bad_parameterName_inUse_localVariable() async {
    await _createRefactoring('''
void f() {
  int v1 = 1;
  int v2 = 2;
  [!int a = v1 + v2; // marker!]
}
''');
    // update parameters
    await refactoring.checkInitialConditions();
    {
      var parameters = _getParametersCopy();
      expect(parameters, hasLength(2));
      parameters[0].name = 'a';
      refactoring.parameters = parameters;
    }
    return _assertFinalConditionsError(
      "'a' is already used as a name in the selected code",
    );
  }

  Future<void> test_bad_parameterName_inUse_method() async {
    await _createRefactoring('''
class A {
  void f() {
    int v1 = 1;
    int v2 = 2;
    [!m(v1, v2);!]
  }
  m(a, b) {}
}
''');
    // update parameters
    await refactoring.checkInitialConditions();
    {
      var parameters = _getParametersCopy();
      expect(parameters, hasLength(2));
      parameters[0].name = 'm';
      refactoring.parameters = parameters;
    }
    return _assertFinalConditionsError(
      "'m' is already used as a name in the selected code",
    );
  }

  Future<void> test_bad_selectionEndsInSomeNode() async {
    await _createRefactoring('''
void f() {
  [!print(0);
  print(1)!];
}
''');
    return _assertConditionsFatal(
      'The selection does not cover a set of statements or an expression. '
      'Extend selection to a valid range.',
    );
  }

  Future<void> test_bad_statements_exit_notAllExecutionFlows() async {
    await _createRefactoring('''
void f(int p) {
  [!if (p == 0) {
    return;
  }!]
  print(p);
}
''');
    return _assertConditionsError(ExtractMethodRefactoringImpl.errorExits);
  }

  Future<void> test_bad_statements_return_andAssignsVariable() async {
    await _createRefactoring('''
int f() {
  [!var v = 0;
  return 42;!]
  print(v);
}
''');
    return _assertConditionsFatal(
      'Ambiguous return value: Selected block contains assignment(s) to '
      'local variables and return statement.',
    );
  }

  Future<void> test_bad_switchCase() async {
    await _createRefactoring('''
void f() {
  switch (1) {
    [!case 0: break;!]
  }
}
''');
    return _assertConditionsFatal(
      'Selection must either cover whole switch statement '
      'or parts of a single case block.',
    );
  }

  Future<void> test_bad_tokensBetweenLastNodeAndSelectionEnd() async {
    await _createRefactoring('''
void f() {
  [!print(0);
  print(1);
}!]
''');
    return _assertConditionsFatal(
      'The end of the selection contains characters that do not belong to a statement.',
    );
  }

  Future<void> test_bad_tokensBetweenSelectionStartAndFirstNode() async {
    await _createRefactoring('''
void f() {
  print(0[!); // marker
  print(1);!]
}
''');
    return _assertConditionsFatal(
      'The beginning of the selection contains characters that do not belong to a statement.',
    );
  }

  Future<void> test_bad_try_catchBlock_block() async {
    await _createRefactoring('''
void f() {
  try
  {}
  catch (e)
  [!{}!]
}
''');
    return _assertConditionsFatal(
      'Selection must either cover whole try statement or '
      'parts of try, catch, or finally block.',
    );
  }

  Future<void> test_bad_try_catchBlock_complete() async {
    await _createRefactoring('''
void f() {
  try
  {}
  [!catch (e)
  {}!]
}
''');
    return _assertConditionsFatal(
      'Selection must either cover whole try statement or '
      'parts of try, catch, or finally block.',
    );
  }

  Future<void> test_bad_try_catchBlock_exception() async {
    await _createRefactoring('''
void f() {
  try {
  } catch (
  [!e!]
  ) {
  }
}
''');
    return _assertConditionsFatal(
      'Cannot extract the name part of a declaration.',
    );
  }

  Future<void> test_bad_try_finallyBlock() async {
    await _createRefactoring('''
void f() {
  try
  {}
  finally
  [!{}!]
}
''');
    return _assertConditionsFatal(
      'Selection must either cover whole try statement or '
      'parts of try, catch, or finally block.',
    );
  }

  Future<void> test_bad_try_tryBlock() async {
    await _createRefactoring('''
void f() {
  try
  [!{}!]
  finally
  {}
}
''');
    return _assertConditionsFatal(
      'Selection must either cover whole try statement or '
      'parts of try, catch, or finally block.',
    );
  }

  Future<void> test_bad_typeReference() async {
    await _createRefactoring('''
void f() {
  [!int!] a = 0;
}
''');
    return _assertConditionsFatal('Cannot extract a single type reference.');
  }

  Future<void> test_bad_typeReference_nullable() async {
    await _createRefactoring('''
// Dummy comment ("The selection offset must be greater than zero")
[!int!]? f;
''');
    return _assertConditionsFatal('Cannot extract a single type reference.');
  }

  Future<void> test_bad_typeReference_prefix() async {
    await _createRefactoring('''
import 'dart:io' as io;
void f() {
  [!io!].File f = io.File('');
}
''');
    return _assertConditionsFatal('Cannot extract an import prefix.');
  }

  Future<void> test_bad_variableDeclarationFragment() async {
    await _createRefactoring('''
void f() {
  int
    [!a = 1!]
    ,b = 2;
}
''');
    return _assertConditionsFatal(
      'Cannot extract a variable declaration fragment. Select whole declaration statement.',
    );
  }

  Future<void> test_bad_while_conditionAndBody() async {
    await _createRefactoring('''
void f() {
  while
    [!(false)
  {
  }!]
}
''');
    return _assertConditionsFatal(
      "Operation not applicable to a while statement's expression and body.",
    );
  }

  Future<void> test_canExtractGetter_false_closure() async {
    await _createRefactoring('''
void f() {
  useFunction([!(_) => true!]);
}
useFunction(filter(String p)) {}
''');
    // apply refactoring
    await assertRefactoringConditionsOK();
    expect(refactoring.canCreateGetter, false);
    expect(refactoring.createGetter, false);
  }

  Future<void> test_canExtractGetter_false_fieldAssignment() async {
    await _createRefactoring('''
class A {
  var f;
  void m() {
    [!f = 1;!]
  }
}
''');
    // apply refactoring
    await assertRefactoringConditionsOK();
    expect(refactoring.canCreateGetter, false);
    expect(refactoring.createGetter, false);
  }

  Future<void> test_canExtractGetter_false_hasParameters() async {
    await _createRefactoring('''
void f(int p) {
  int a = [!p + 1!];
}
''');
    // apply refactoring
    await assertRefactoringConditionsOK();
    expect(refactoring.canCreateGetter, false);
    expect(refactoring.createGetter, false);
  }

  Future<void> test_canExtractGetter_false_returnNotUsed_assignment() async {
    await _createRefactoring('''
var topVar = 0;
void f(int p) {
  [!topVar = 5!];
}
''');
    // apply refactoring
    await assertRefactoringConditionsOK();
    expect(refactoring.canCreateGetter, false);
    expect(refactoring.createGetter, false);
  }

  Future<void> test_canExtractGetter_false_returnNotUsed_noReturn() async {
    await _createRefactoring('''
var topVar = 0;
void f() {
  [!int a = 1;
  int b = 2;
  topVar = a + b;!]
}
''');
    // apply refactoring
    await assertRefactoringConditionsOK();
    expect(refactoring.canCreateGetter, false);
    expect(refactoring.createGetter, false);
  }

  Future<void> test_canExtractGetter_true() async {
    await _createRefactoring('''
void f() {
  int a = [!1 + 2!];
}
''');
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
    _createRefactoringForRange(0, 1 << 20);
    var status = await refactoring.checkAllConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL);
  }

  Future<void> test_checkInitialCondition_outOfRange_offset() async {
    await indexTestUnit('''
void f() {
  1 + 2;
}
''');
    _createRefactoringForRange(-10, 20);
    var status = await refactoring.checkAllConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL);
  }

  Future<void> test_checkName() async {
    await _createRefactoring('''
void f() {
  int a = [!1 + 2!];
}
''');
    // empty
    refactoring.name = '';
    assertRefactoringStatus(
      refactoring.checkName(),
      RefactoringProblemSeverity.FATAL,
      expectedMessage: 'Method name must not be empty.',
    );
    // incorrect casing
    refactoring.name = 'Aaa';
    assertRefactoringStatus(
      refactoring.checkName(),
      RefactoringProblemSeverity.WARNING,
      expectedMessage: 'Method name should start with a lowercase letter.',
    );
    // starts with digit
    refactoring.name = '0aa';
    assertRefactoringStatus(
      refactoring.checkName(),
      RefactoringProblemSeverity.FATAL,
      expectedMessage:
          'Method name must begin with a lowercase letter or underscore.',
    );
    // invalid name (quote)
    refactoring.name = '"';
    assertRefactoringStatus(
      refactoring.checkName(),
      RefactoringProblemSeverity.FATAL,
      expectedMessage: "Method name must not contain '\"'.",
    );
    // OK
    refactoring.name = 'res';
    assertRefactoringStatusOK(refactoring.checkName());
  }

  Future<void> test_closure_asFunction_singleExpression() async {
    await _createRefactoring('''
process(f(x)) {}
void f() {
  process([!(x) => x * 2!]);
}
''');
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
    await _createRefactoring('''
process(f(x)) {}
void f() {
  process([!(x) {
    print(x);
    return x * 2;
  }!]);
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
process(f(x)) {}
void f() {
  process(res);
}

res(x) {
  print(x);
  return x * 2;
}
''');
  }

  Future<void> test_closure_asMethod_statements() async {
    await _createRefactoring('''
process(f(x)) {}
class A {
  int k = 2;
  void f() {
    process([!(x) {
      print(x);
      return x * k;
    }!]);
  }
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
process(f(x)) {}
class A {
  int k = 2;
  void f() {
    process(res);
  }

  res(x) {
    print(x);
    return x * k;
  }
}
''');
  }

  Future<void> test_closure_atArgumentName() async {
    await _createRefactoring('''
void process({int fff(int x)?}) {}
class C {
  void f() {
    process(f^ff: (int x) => x * 2);
  }
}
''');
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
    await _createRefactoring('''
void process(num f(int x)) {}
class C {
  void f() {
    process((int ^x) => x * 2);
  }
}
''');
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
    await _createRefactoring('''
process(f(x)) {}
void f() {
  int k = 2;
  int a = 3;
  process([!(x) => x * k * a!]);
}
''');
    // check
    var status = await refactoring.checkInitialConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.FATAL,
      expectedMessage:
          'Cannot extract the closure as a method,'
          'it references the external variables \'k\' and \'a\'.',
    );
  }

  Future<void> test_closure_bad_referencesParameter() async {
    await _createRefactoring('''
process(f(x)) {}
void f(int k) {
  process([!(x) => x * k!]);
}
''');
    // check
    var status = await refactoring.checkInitialConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.FATAL,
      expectedMessage:
          'Cannot extract the closure as a method,'
          'it references the external variable \'k\'.',
    );
  }

  Future<void> test_fromTopLevelVariableInitializerClosure() async {
    await _createRefactoring('''
var X = 1;

dynamic Y = () {
  return [!1 + X!];
};
''');
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
    await _createRefactoring('''
void f() {
  print([!1 + 2!]);
}
''');
    // apply refactoring
    await assertRefactoringConditionsOK();
    expect(refactoring.createGetter, true);
  }

  Future<void> test_getExtractGetter_expression_true_literal() async {
    await _createRefactoring('''
void f() {
  print([!42!]);
}
''');
    // apply refactoring
    await assertRefactoringConditionsOK();
    expect(refactoring.createGetter, true);
  }

  Future<void>
  test_getExtractGetter_expression_true_prefixedExpression() async {
    await _createRefactoring('''
void f() {
  print([!!true!]);
}
''');
    // apply refactoring
    await assertRefactoringConditionsOK();
    expect(refactoring.createGetter, true);
  }

  Future<void>
  test_getExtractGetter_expression_true_prefixedIdentifier() async {
    await _createRefactoring('''
void f() {
  print([!myValue.isEven!]);
}
int get myValue => 42;
''');
    // apply refactoring
    await assertRefactoringConditionsOK();
    expect(refactoring.createGetter, true);
  }

  Future<void> test_getExtractGetter_expression_true_propertyAccess() async {
    await _createRefactoring('''
void f() {
  print([!1.isEven!]);
}
''');
    // apply refactoring
    await assertRefactoringConditionsOK();
    expect(refactoring.createGetter, true);
  }

  Future<void> test_getExtractGetter_statements() async {
    await _createRefactoring('''
void f() {
  [!int v = 0;!]
  print(v);
}
''');
    // apply refactoring
    await assertRefactoringConditionsOK();
    expect(refactoring.createGetter, false);
  }

  Future<void> test_getRefactoringName_function() async {
    await _createRefactoring('''
void f() {
  print([!1 + 2!]);
}
''');
    expect(refactoring.refactoringName, 'Extract Function');
  }

  Future<void> test_getRefactoringName_method() async {
    await _createRefactoring('''
class A {
  void f() {
    print([!1 + 2!]);
  }
}
''');
    expect(refactoring.refactoringName, 'Extract Method');
  }

  Future<void> test_isAvailable_false_functionName() async {
    await _createRefactoring('''
void [!f!]() {}
''');
    expect(refactoring.isAvailable(), isFalse);
  }

  Future<void> test_isAvailable_true() async {
    await _createRefactoring('''
void f() {
  [!1 + 2!];
}
''');
    expect(refactoring.isAvailable(), isTrue);
  }

  Future<void> test_names_singleExpression() async {
    await _createRefactoring('''
class TreeItem {}
TreeItem getSelectedItem() => throw 0;
process(my) {}
void f() {
  process([!getSelectedItem()!]); // marker
  int treeItem = 0;
}
''');
    // check names
    await refactoring.checkInitialConditions();
    expect(
      refactoring.names,
      unorderedEquals(['selectedItem', 'item', 'my', 'treeItem2']),
    );
  }

  Future<void> test_offsets_lengths() async {
    await _createRefactoring('''
void f() {
  int a = 1 + 2;
  int b = [!1 +  2!];
}
''');
    // apply refactoring
    await refactoring.checkInitialConditions();
    expect(
      refactoring.offsets,
      unorderedEquals([findOffset('1 + 2'), findOffset('1 +  2')]),
    );
    expect(refactoring.lengths, unorderedEquals([5, 6]));
  }

  Future<void> test_parameterType_nullableTypeWithTypeArguments() async {
    await _createRefactoring('''
abstract class C {
  List<int>? get x;
}
class D {
  f(C c) {
    var x = c.x;
    [!print(x);!]
  }
}
''');
    // do check
    await refactoring.checkInitialConditions();
    expect(refactoring.parameters[0].type, 'List<int>?');
  }

  Future<void> test_parameterType_prefixed() async {
    await _createRefactoring('''
import 'dart:core' as core;
class C {
  f(core.String p) {
    [!p;!]
  }
}
''');
    await refactoring.checkInitialConditions();
    expect(refactoring.parameters[0].type, 'core.String');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/55254')
  Future<void> test_parameterType_typeParameterOfEnclosingClass() async {
    await _createRefactoring('''
class C<T> {
  f(T p) {
    [!p;!]
  }
}
''');
    await refactoring.checkInitialConditions();
    expect(refactoring.parameters[0].type, 'T');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/55254')
  Future<void> test_parameterType_typeParameterOfEnclosingFunction() async {
    await _createRefactoring('''
class C {
  f<T>(T p) {
    [!p;!]
  }
}
''');
    await refactoring.checkInitialConditions();
    expect(refactoring.parameters[0].type, 'T');
  }

  Future<void> test_prefixPartOfQualified() async {
    await _createRefactoring('''
class A {
  var fff;
}
void f(A a) {
  ^a.fff = 5;
}
''');
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
    await _createRefactoring('''
process(f(x)) {}
void f() {
  process([!(x) => x * 2!]);
}
''');
    // do check
    await refactoring.checkInitialConditions();
    expect(refactoring.returnType, '');
  }

  Future<void> test_returnType_expression() async {
    await _createRefactoring('''
void f() {
  int a = [!1 + 2!];
}
''');
    // do check
    await refactoring.checkInitialConditions();
    expect(refactoring.returnType, 'int');
  }

  Future<void> test_returnType_mixInterfaceFunction() async {
    await _createRefactoring('''
Object f() {
  [!if (true) {
    return 1;
  } else {
    return () {};
  }!]
}
''');
    // do check
    await refactoring.checkInitialConditions();
    expect(refactoring.returnType, 'Object');
  }

  Future<void> test_returnType_statements() async {
    await _createRefactoring('''
void f() {
  [!double v = 5.0;!]
  print(v);
}
''');
    // do check
    await refactoring.checkInitialConditions();
    expect(refactoring.returnType, 'double');
  }

  Future<void> test_returnType_statements_nullMix() async {
    await _createRefactoring('''
f(bool p) {
  [!if (p) {
    return 42;
  }
  return null;!]
}
''');
    // do check
    await refactoring.checkInitialConditions();
    expect(refactoring.returnType, 'int?');
  }

  Future<void> test_returnType_statements_void() async {
    await _createRefactoring('''
void f() {
  [!print(42);!]
}
''');
    // do check
    await refactoring.checkInitialConditions();
    expect(refactoring.returnType, 'void');
  }

  Future<void> test_setExtractGetter() async {
    await _createRefactoring('''
void f() {
  int a = [!1 + 2!];
}
''');
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
    await _createRefactoring('''
void f() {
  int a = [!1 + 2!];
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  int a = res();
}

int res() => 1 + 2;
''');
  }

  Future<void> test_singleExpression_cascade() async {
    await _createRefactoring('''
void f() {
  String s = '';
  var v = [!s..length!];
}
''');
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
    await _createRefactoring('''
void f(int n) {
  var v = new Foo^Bar(n);
}

class FooBar {
  FooBar(int count);
}
''');
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
    await _createRefactoring('''
dynaFunction() {}
void f() {
  var v = [!dynaFunction()!];
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
dynaFunction() {}
void f() {
  var v = res();
}

res() => dynaFunction();
''');
  }

  Future<void> test_singleExpression_hasAwait() async {
    await _createRefactoring('''
import 'dart:async';
Future<int> getValue() async => 42;
void f() async {
  int v = [!await getValue()!];
  print(v);
}
''');
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
    await _createRefactoring('''
void f() {
  getButton().text = 'txt';
  print([!getButton().text!]);
}
getButton() {}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  getButton().text = 'txt';
  print(res());
}

res() => getButton().text;
getButton() {}
''');
  }

  Future<void> test_singleExpression_occurrences() async {
    await _createRefactoring('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int v3 = 3;
  int positiveA = [!v1 + v2!];
  int positiveB = v2 + v3;
  int positiveC = v1 +  v2;
  int positiveD = v1/*abc*/ + v2;
  int negA = 1 + 2;
  int negB = 1 + v2;
  int negC = v1 + 2;
  int negD = v1 * v2;
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int v3 = 3;
  int positiveA = res(v1, v2);
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
    await _createRefactoring('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int v3 = 3;
  int a = [!v1 + v2!];
  int b = v2 + v3;
}
''');
    refactoring.extractAll = false;
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int v3 = 3;
  int a = res(v1, v2);
  int b = v2 + v3;
}

int res(int v1, int v2) => v1 + v2;
''');
  }

  Future<void> test_singleExpression_occurrences_inClassOnly() async {
    await _createRefactoring('''
class A {
  myMethod() {
    int v1 = 1;
    int v2 = 2;
    int positiveA = [!v1 + v2!];
  }
}
void f() {
  int v1 = 1;
  int v2 = 2;
  int negA = v1 + v2;
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
class A {
  myMethod() {
    int v1 = 1;
    int v2 = 2;
    int positiveA = res(v1, v2);
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
    await _createRefactoring('''
void f() {
  int x = 1;
  String y = 'foo';
  print([!x.toString()!]);
  print(y.toString());
}
''');
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
    await _createRefactoring('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int positiveA = [!v1 + v2!];
}
class A {
  myMethod() {
    int v1 = 1;
    int v2 = 2;
    int positiveB = v1 + v2;
  }
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int positiveA = res(v1, v2);
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
    await _createRefactoring('''
typedef R Foo<S, R>(S s);
void f(Foo<String, int> foo, String s) {
  int a = [!foo(s)!];
}
''');
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
    await _createRefactoring('''
void f() {
  var r = [!(f1: 0, f2: true)!];
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  var r = res();
}

({int f1, bool f2}) res() => (f1: 0, f2: true);
''');
  }

  Future<void> test_singleExpression_recordType_positional() async {
    await _createRefactoring('''
void f() {
  var r = [!(0, true)!];
}
''');
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
    await _createRefactoring('''
import 'asyncLib.dart';
void f() {
  var a = [!newCompleter()!];
}
''');
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
    await _createRefactoring('''
void f() {
  var v = [!<String>[]!];
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  var v = res();
}

List<String> res() => <String>[];
''');
  }

  Future<void> test_singleExpression_returnTypePrefix() async {
    await _createRefactoring('''
import 'dart:math' as pref;
void f() {
  var v = [!new pref.Random()!];
}
''');
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
    await _createRefactoring('''
class A {
  A(int v) {}
}
class B extends A {
  B() : super([!1 + 2!]) {}
}
''');
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
    await _createRefactoring('''
class A {
  instanceMethodA() {
    int v1 = 1;
    int v2 = 2;
    int positiveA = [!v1 + v2!];
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
    // apply refactoring
    return _assertSuccessfulRefactoring('''
class A {
  instanceMethodA() {
    int v1 = 1;
    int v2 = 2;
    int positiveA = res(v1, v2);
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

  Future<void>
  test_singleExpression_staticContext_extractFromStaticField() async {
    await _createRefactoring('''
class A {
  static String x(String Function(String) f) => '';

  static String test = x([!(v) => v.toString()!]);
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
class A {
  static String x(String Function(String) f) => '';

  static String test = x(res);

  static String res(v) => v.toString();
}
''');
  }

  Future<void>
  test_singleExpression_staticContext_extractFromStaticMethod() async {
    await _createRefactoring('''
class A {
  static staticMethodA() {
    int v1 = 1;
    int v2 = 2;
    int positiveA = [!v1 + v2!];
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
    // apply refactoring
    return _assertSuccessfulRefactoring('''
class A {
  static staticMethodA() {
    int v1 = 1;
    int v2 = 2;
    int positiveA = res(v1, v2);
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
    await _createRefactoring('''
class A {
  A(int v) {}
}
class B extends A {
  B() : super(1 + 2) {}
  foo() {
    print([!1 + 2!]);
  }
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
class A {
  A(int v) {}
}
class B extends A {
  B() : super(res()) {}
  foo() {
    print(res());
  }

  static int res() => 1 + 2;
}
''');
  }

  Future<void> test_singleExpression_unresolved() async {
    verifyNoTestUnitErrors = false;
    await _createRefactoring('''
Object f() {
  return [!unresolved!];
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
Object f() {
  return res();
}

dynamic res() => unresolved;
''');
  }

  Future<void> test_singleExpression_usesParameter() async {
    await _createRefactoring('''
fooA(int a1) {
  int a2 = 2;
  int a = [!a1 + a2!];
}
fooB(int b1) {
  int b2 = 2;
  int b = b1 + b2;
}
''');
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
    await _createRefactoring('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int a = [!v1 + v2 + v1!];
}
''');
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
    await _createRefactoring('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int v3 = 3;
  int a = [!v1 + v2 + v1!]; // marker
  int b = v2 + v3 + v2;
}
''');
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
    await _createRefactoring('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int v3 = 3;
  int a = [!v1 + v2!]; // marker
  int b = v2 + v3;
}
''');
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
    await _createRefactoring('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int a = [!process(arg: v1 + v2)!];
}
process({arg}) {}
''');
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
    await _createRefactoring('''
void f() {
  int v1 = 1;
  int v2 = 2;
  int v3 = 3;
  int a = [!v1 + v2 + v3!];
}
''');
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
    await _createRefactoring('''
void f() {
  var v1 = 1;
  var v2 = 2;
  var a = [!v1 + v2 + v1!]; // marker
}
''');
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
    await _createRefactoring('''
void f() {
  int v;
  [!v = 5;!]
  print(v);
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  int v;
  v = res(v);
  print(v);
}

int res(int v) {
  v = 5;
  return v;
}
''');
  }

  Future<void> test_statements_changeIndentation() async {
    await _createRefactoring('''
void f() {
  {
    [!if (true) {
      print(0);
    }!]
  }
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  {
    res();
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
    await _createRefactoring('''
void f() {
  {
    [!print("""
first line
second line
    """);!]
  }
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  {
    res();
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
    await _createRefactoring('''
void f() {
  int a = 1;
  int b = 1;
  [!int v = a + b;
  print(v);!]
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  int a = 1;
  int b = 1;
  res(a, b);
}

void res(int a, int b) {
  int v = a + b;
  print(v);
}
''');
  }

  Future<void>
  test_statements_definesVariable_oneUsedOutside_assignment() async {
    await _createRefactoring('''
myFunctionA() {
  int a = 1;
  [!a += 10;!]
  print(a);
}
myFunctionB() {
  int b = 2;
  b += 10;
  print(b);
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
myFunctionA() {
  int a = 1;
  a = res(a);
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
    await _createRefactoring('''
myFunctionA() {
  int a = 1;
  int b = 2;
  [!int v1 = a + b;!]
  print(v1);
}
myFunctionB() {
  int a = 3;
  int b = 4;
  int v2 = a + b;
  print(v2);
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
myFunctionA() {
  int a = 1;
  int b = 2;
  int v1 = res(a, b);
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
    await _createRefactoring('''
void f() {
  [!int varA = 1;
  int varB = 2;!]
  int v = varA + varB;
}
''');
    // check conditions
    var status = await refactoring.checkInitialConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL);
  }

  Future<void> test_statements_dotShorthand() async {
    await _createRefactoring('''
class A {
  static A get getter => A();
}

void f() {
  A a;
  [!a = .getter;!]
  print(a);
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
class A {
  static A get getter => A();
}

void f() {
  A a;
  a = res(a);
  print(a);
}

A res(A a) {
  a = .getter;
  return a;
}
''');
  }

  Future<void> test_statements_duplicate_absolutelySame() async {
    await _createRefactoring('''
myFunctionA() {
  print(0);
  print(1);
}
myFunctionB() {
  [!print(0);
  print(1);!]
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
myFunctionA() {
  res();
}
myFunctionB() {
  res();
}

void res() {
  print(0);
  print(1);
}
''');
  }

  Future<void>
  test_statements_duplicate_declaresDifferentlyNamedVariable() async {
    await _createRefactoring('''
myFunctionA() {
  int varA = 1;
  print(varA);
}
myFunctionB() {
  [!int varB = 1;
  print(varB);!]
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
myFunctionA() {
  res();
}
myFunctionB() {
  res();
}

void res() {
  int varB = 1;
  print(varB);
}
''');
  }

  Future<void> test_statements_dynamic() async {
    await _createRefactoring('''
dynaFunction(p) => 0;
void f() {
  [!var a = 1;
  var v = dynaFunction(a);!]
  print(v);
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
dynaFunction(p) => 0;
void f() {
  var v = res();
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
    await _createRefactoring('''
void f() {
  [!if (true) {
    print(0);
  }!]
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  res();
}

void res() {
  if (true) {
    print(0);
  }
}
''');
  }

  Future<void> test_statements_exit_throws() async {
    await _createRefactoring('''
void f(int p) {
  [!if (p == 0) {
    return;
  }
  throw 'boo!';!]
}
''');
    await assertRefactoringConditionsOK();
  }

  Future<void> test_statements_functionPrefix() async {
    await _createRefactoring('''
import 'dart:io' as io;
void f() {
  [!io.exit(1)!];
}
''');
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
    await _createRefactoring('''
import 'dart:async';
Future getValue() async => 42;
void f() async {
  [!var v = await getValue();!]
  print(v);
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
import 'dart:async';
Future getValue() async => 42;
void f() async {
  var v = await res();
  print(v);
}

Future<dynamic> res() async {
  var v = await getValue();
  return v;
}
''');
  }

  Future<void> test_statements_hasAwait_expression() async {
    await _createRefactoring('''
import 'dart:async';
Future<int> getValue() async => 42;
void f() async {
  [!int v = await getValue();
  v += 2;!]
  print(v);
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
import 'dart:async';
Future<int> getValue() async => 42;
void f() async {
  int v = await res();
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
    await _createRefactoring('''
import 'dart:async';
Stream<int> getValueStream() => throw 0;
void f() async {
  [!int sum = 0;
  await for (int v in getValueStream()) {
    sum += v;
  }!]
  print(sum);
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
import 'dart:async';
Stream<int> getValueStream() => throw 0;
void f() async {
  int sum = await res();
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
    await _createRefactoring('''
void g(Future<void> Function() func) {}
void f() {
  [!g(() async {
    await null;
  });!]
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void g(Future<void> Function() func) {}
void f() {
  res();
}

void res() {
  g(() async {
    await null;
  });
}
''');
  }

  Future<void> test_statements_hasAwait_voidReturnType() async {
    await _createRefactoring('''
import 'dart:async';
Future<int> getValue() async => 42;
void f() async {
  [!int v = await getValue();
  print(v);!]
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
import 'dart:async';
Future<int> getValue() async => 42;
void f() async {
  await res();
}

Future<void> res() async {
  int v = await getValue();
  print(v);
}
''');
  }

  Future<void> test_statements_inSwitchMember() async {
    await _createRefactoring('''
class A {
  foo(int p) {
    switch (p) {
      case 0:
        [!print(0);!]
        break;
      default:
        break;
    }
  }
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
class A {
  foo(int p) {
    switch (p) {
      case 0:
        res();
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
    await _createRefactoring('''
void f() {
  [!void g() {}
  g();!]
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  res();
}

void res() {
  void g() {}
  g();
}
''');
  }

  Future<void> test_statements_method() async {
    await _createRefactoring('''
class A {
  foo() {
    [!print(0);!]
  }
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
class A {
  foo() {
    res();
  }

  void res() {
    print(0);
  }
}
''');
  }

  Future<void> test_statements_noDuplicates() async {
    await _createRefactoring('''
void f() {
  int a = 1;
  int b = 1;
  [!print(a);!]
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  int a = 1;
  int b = 1;
  res(a);
}

void res(int a) {
  print(a);
}
''');
  }

  Future<void> test_statements_parameters_ignoreInnerPropagatedType() async {
    await _createRefactoring('''
void f(Object x) {
  [!if (x is int) {
    print('int');
  }
  if (x is bool) {
    print('bool');
  }!]
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f(Object x) {
  res(x);
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
    await _createRefactoring('''
import 'asyncLib.dart';
void f() {
  var v = newCompleter();
  [!print(v);!]
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
import 'asyncLib.dart';
import 'dart:async';
void f() {
  var v = newCompleter();
  res(v);
}

void res(Completer<int> v) {
  print(v);
}
''');
  }

  Future<void> test_statements_parameters_localFunction() async {
    await _createRefactoring('''
class C {
  int f(int a) {
    int callback(int x, int y) => x + a;
    int b = a + 1;
    [!int c = callback(b, 2);!]
    int d = c + 1;
    return d;
  }
}''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
class C {
  int f(int a) {
    int callback(int x, int y) => x + a;
    int b = a + 1;
    int c = res(callback, b);
    int d = c + 1;
    return d;
  }

  int res(int Function(int x, int y) callback, int b) {
    int c = callback(b, 2);
    return c;
  }
}''');
  }

  Future<void> test_statements_parameters_noLocalVariableConflict() async {
    await _createRefactoring('''
int f(int x) {
  int y = x + 1;
  [!if (y % 2 == 0) {
    int y = x + 2;
    return y;
  } else {
    return y;
  }!]
}
''');
    await assertRefactoringConditionsOK();
  }

  Future<void> test_statements_return_last() async {
    await _createRefactoring('''
int f() {
  [!int v = 5;
  return v + 1;!]
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
int f() {
  return res();
}

int res() {
  int v = 5;
  return v + 1;
}
''');
  }

  Future<void> test_statements_return_multiple_ifElse() async {
    await _createRefactoring('''
num f(bool b) {
  [!if (b) {
    return 1;
  } else {
    return 2.0;
  }!]
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
num f(bool b) {
  return res(b);
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
    await _createRefactoring('''
num f(bool b) {
  [!if (b) {
    return 1;
  }
  return 2.0;!]
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
num f(bool b) {
  return res(b);
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
    await _createRefactoring('''
int f() {
  [!localFunction() {
    return 'abc';
  }
  return 42;!]
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
int f() {
  return res();
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
    await _createRefactoring('''
f(bool b) {
  [!if (b) {
    return 1;
  }
  return () {};!]
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
f(bool b) {
  return res(b);
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
    await _createRefactoring('''
f(bool b) {
  [!if (b) {
    print(true);
    return <int>[];
  } else {
    print(false);
    return <String>[];
  }!]
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
f(bool b) {
  return res(b);
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
    await _createRefactoring('''
int f() {
  [!return 42;!]
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
int f() {
  return res();
}

int res() {
  return 42;
}
''');
  }

  Future<void> test_statements_topFunction_parameters_function() async {
    await _createRefactoring('''
Future<void> f(void f(String x), String a) async {
  [!f(a);!]
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
Future<void> f(void f(String x), String a) async {
  res(f, a);
}

void res(void Function(String x) f, String a) {
  f(a);
}
''');
  }

  Future<void>
  test_statements_topFunction_parameters_function_functionSyntax() async {
    await _createRefactoring('''
Future<void> f(void Function(String) f, String a) async {
  [!f(a);!]
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
Future<void> f(void Function(String) f, String a) async {
  res(f, a);
}

void res(void Function(String) f, String a) {
  f(a);
}
''');
  }

  Future<void> test_statements_topFunction_parameters_recordType() async {
    await _createRefactoring('''
void f((int, String) r) {
  [!print(r);!]
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f((int, String) r) {
  res(r);
}

void res((int, String) r) {
  print(r);
}
''');
  }

  /// We have 3 identical statements, but select only 2.
  /// This should not cause problems.
  Future<void> test_statements_twoOfThree() async {
    await _createRefactoring('''
void f() {
  [!print(0);
  print(0);!]
  print(0);
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
void f() {
  res();
  print(0);
}

void res() {
  print(0);
  print(0);
}
''');
  }

  Future<void> test_string() async {
    await _createRefactoring('''
void f() {
  var a = '[!test!]';
}
''');
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

@reflectiveTest
class ExtractMethodTest_Enum extends _ExtractMethodTest {
  Future<void> test_bad_conflict_method_alreadyDeclaresMethod() async {
    await _createRefactoring('''
enum E {
  v;
  void res() {}
  void foo() {
    [!print(0);!]
  }
}
''');
    return _assertConditionsError(
      "Enum 'E' already declares method with name 'res'.",
    );
  }

  Future<void> test_bad_conflict_method_shadowsSuperDeclaration() async {
    await _createRefactoring('''
mixin M {
  void res() {}
}

enum E with M {
  v;
  void foo() {
    res();
    [!print(0);!]
  }
}
''');
    return _assertConditionsError("Created method will shadow method 'M.res'.");
  }

  Future<void> test_bad_conflict_topLevel_willHideInheritedMemberUsage() async {
    await _createRefactoring('''
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
  [!print(0);!]
}
''');
    return _assertConditionsError(
      "Created function will shadow method 'M.res'.",
    );
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/61146')
  Future<void> test_const_singleExpression() async {
    await _createRefactoring('''
enum E {
  v;
  void foo() {
    const e = [!E.v!];
  }
}
''');
    return _assertConditionsError(
      "'E.v' is in a constant context and can't be extracted to a function.",
    );
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/61146')
  Future<void> test_const_singleExpression_dotShorthand() async {
    await _createRefactoring('''
enum E {
  v;
  void foo() {
    const E e = [!.v!];
  }
}
''');
    return _assertConditionsError(
      "'.v' is in a constant context and can't be extracted to a function.",
    );
  }

  Future<void> test_singleExpression_dotShorthand() async {
    await _createRefactoring('''
enum E {
  v;
  void foo() {
    E e = [!.v!];
  }
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
enum E {
  v;
  void foo() {
    E e = res();
  }

  E res() => .v;
}
''');
  }

  Future<void> test_singleExpression_dotShorthand_inferred() async {
    await _createRefactoring('''
T f<T>(T arg) => arg;
enum E {
  v;
  void foo() {
    E e = [!f(.v)!];
  }
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
T f<T>(T arg) => arg;
enum E {
  v;
  void foo() {
    E e = res();
  }

  E res() => f(.v);
}
''');
  }

  Future<void> test_singleExpression_method() async {
    await _createRefactoring('''
enum E {
  v;
  void foo() {
    int a = [!1 + 2!];
  }
}
''');
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
    await _createRefactoring('''
enum E {
  v;
  void foo() {
    [!print(0);!]
  }
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
enum E {
  v;
  void foo() {
    res();
  }

  void res() {
    print(0);
  }
}
''');
  }
}

@reflectiveTest
class ExtractMethodTest_Extension extends _ExtractMethodTest {
  Future<void> test_singleExpression_method() async {
    await _createRefactoring('''
extension E on int {
  void foo() {
    int a = [!1 + 2!];
  }
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
extension E on int {
  void foo() {
    int a = res();
  }

  int res() => 1 + 2;
}
''');
  }

  Future<void> test_statements_method() async {
    await _createRefactoring('''
extension E on int {
  void foo() {
    [!print(0);!]
  }
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
extension E on int {
  void foo() {
    res();
  }

  void res() {
    print(0);
  }
}
''');
  }
}

@reflectiveTest
class ExtractMethodTest_ExtensionType extends _ExtractMethodTest {
  Future<void> test_bad_conflict_method_alreadyDeclaresMethod() async {
    await _createRefactoring('''
extension type E(int it) {
  void res() {}
  void foo() {
    [!print(0);!]
  }
}
''');
    return _assertConditionsError(
      "Extension type 'E' already declares method with name 'res'.",
    );
  }

  Future<void> test_bad_conflict_method_shadowsSuperDeclaration() async {
    await _createRefactoring('''
class A {
  void res() {}
}

extension type E(A it) implements A {
  void foo() {
    res();
    [!print(0);!]
  }
}
''');
    return _assertConditionsError("Created method will shadow method 'A.res'.");
  }

  Future<void> test_singleExpression_dotShorthand() async {
    await _createRefactoring('''
extension type E(int it) {
  static E get getter => E(1);
  void foo() {
    E a = [!.getter!];
    print(a);
  }
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
extension type E(int it) {
  static E get getter => E(1);
  void foo() {
    E a = res();
    print(a);
  }

  E res() => .getter;
}
''');
  }

  Future<void> test_singleExpression_dotShorthand_inferred() async {
    await _createRefactoring('''
T f<T>(T arg) => arg;
extension type E(int it) {
  static E get getter => E(1);
  void foo() {
    E a = [!f(.getter)!];
    print(a);
  }
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
T f<T>(T arg) => arg;
extension type E(int it) {
  static E get getter => E(1);
  void foo() {
    E a = res();
    print(a);
  }

  E res() => f(.getter);
}
''');
  }

  Future<void> test_singleExpression_method() async {
    await _createRefactoring('''
extension type E(int it) {
  void foo() {
    int a = [!1 + 2!];
  }
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
extension type E(int it) {
  void foo() {
    int a = res();
  }

  int res() => 1 + 2;
}
''');
  }

  Future<void> test_statements_method() async {
    await _createRefactoring('''
extension type E(int it) {
  void foo() {
    [!print(0);!]
  }
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
extension type E(int it) {
  void foo() {
    res();
  }

  void res() {
    print(0);
  }
}
''');
  }
}

@reflectiveTest
class ExtractMethodTest_Mixin extends _ExtractMethodTest {
  Future<void> test_bad_conflict_method_alreadyDeclaresMethod() async {
    await _createRefactoring('''
mixin A {
  void res() {}
  void foo() {
    [!print(0);!]
  }
}
''');
    return _assertConditionsError(
      "Mixin 'A' already declares method with name 'res'.",
    );
  }

  Future<void> test_bad_conflict_method_shadowsSuperDeclaration() async {
    await _createRefactoring('''
class A {
  void res() {}
}

mixin B implements A {
  void foo() {
    res();
    [!print(0);!]
  }
}
''');
    return _assertConditionsError("Created method will shadow method 'A.res'.");
  }

  Future<void> test_singleExpression_dotShorthand() async {
    await _createRefactoring('''
class A {}

class B extends A with AMixin {}

mixin AMixin on A {
  static AMixin get getter => B();
  void foo() {
    AMixin a = [!.getter!];
  }
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
class A {}

class B extends A with AMixin {}

mixin AMixin on A {
  static AMixin get getter => B();
  void foo() {
    AMixin a = res();
  }

  AMixin res() => .getter;
}
''');
  }

  Future<void> test_singleExpression_dotShorthand_inferred() async {
    await _createRefactoring('''
class A {}

class B extends A with AMixin {}

T f<T>(T arg) => arg;

mixin AMixin on A {
  static AMixin get getter => B();
  void foo() {
    AMixin a = [!f(.getter)!];
  }
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
class A {}

class B extends A with AMixin {}

T f<T>(T arg) => arg;

mixin AMixin on A {
  static AMixin get getter => B();
  void foo() {
    AMixin a = res();
  }

  AMixin res() => f(.getter);
}
''');
  }

  Future<void> test_singleExpression_method() async {
    await _createRefactoring('''
mixin A {
  void foo() {
    int a = [!1 + 2!];
  }
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
mixin A {
  void foo() {
    int a = res();
  }

  int res() => 1 + 2;
}
''');
  }

  Future<void> test_statements_method() async {
    await _createRefactoring('''
mixin A {
  void foo() {
    [!print(0);!]
  }
}
''');
    // apply refactoring
    return _assertSuccessfulRefactoring('''
mixin A {
  void foo() {
    res();
  }

  void res() {
    print(0);
  }
}
''');
  }
}

class _ExtractMethodTest extends RefactoringTest {
  @override
  late ExtractMethodRefactoringImpl refactoring;

  Future<void> _assertConditionsError(String message) async {
    var status = await refactoring.checkAllConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage: message,
    );
  }

  Future<void> _assertConditionsFatal(String message) async {
    var status = await refactoring.checkAllConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.FATAL,
      expectedMessage: message,
    );
  }

  Future<void> _assertFinalConditionsError(String message) async {
    var status = await refactoring.checkFinalConditions();
    assertRefactoringStatus(
      status,
      RefactoringProblemSeverity.ERROR,
      expectedMessage: message,
    );
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

  Future<void> _createRefactoring(String code) async {
    await indexTestUnit(code);
    if (parsedTestCode.ranges.isNotEmpty) {
      if (parsedTestCode.positions.isNotEmpty) {
        fail('Tests cannot specify both a range and a position.');
      }
      var range = parsedTestCode.range.sourceRange;
      _createRefactoringForRange(range.offset, range.length);
    } else if (parsedTestCode.positions.isNotEmpty) {
      _createRefactoringForRange(parsedTestCode.position.offset, 0);
    } else {
      fail('Tests must specify either a range or a position.');
    }
  }

  void _createRefactoringForRange(int offset, int length) {
    refactoring = ExtractMethodRefactoringImpl(
      searchEngine,
      testAnalysisResult,
      offset,
      length,
    );
    refactoring.name = 'res';
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

class _SourceMock implements Source {
  @override
  final String fullName;

  @override
  final Uri uri;

  _SourceMock(this.fullName, this.uri);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
