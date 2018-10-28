// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LintFixTest);
  });
}

typedef bool AnalysisErrorFilter(AnalysisError error);

/**
 * Base class for fix processor tests.
 */
class BaseFixProcessorTest extends AbstractSingleUnitTest {
  AnalysisErrorFilter errorFilter = (AnalysisError error) {
    return error.errorCode != HintCode.UNUSED_CATCH_CLAUSE &&
        error.errorCode != HintCode.UNUSED_CATCH_STACK &&
        error.errorCode != HintCode.UNUSED_ELEMENT &&
        error.errorCode != HintCode.UNUSED_FIELD &&
        error.errorCode != HintCode.UNUSED_LOCAL_VARIABLE;
  };

  String myPkgLibPath = '/packages/my_pkg/lib';

  String flutterPkgLibPath = '/packages/flutter/lib';

  Fix fix;

  SourceChange change;
  String resultCode;

  assertHasFix(FixKind kind, String expected, {String target}) async {
    AnalysisError error = await _findErrorToFix();
    fix = await _assertHasFix(kind, error);
    change = fix.change;

    // apply to "file"
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));

    String fileContent = testCode;
    if (target != null) {
      expect(fileEdits.first.file, convertPath(target));
      fileContent = getFile(target).readAsStringSync();
    }

    resultCode = SourceEdit.applySequence(fileContent, change.edits[0].edits);
    // verify
    expect(resultCode, expected);
  }

  assertHasFixAllFix(ErrorCode errorCode, FixKind kind, String expected,
      {String target}) async {
    AnalysisError error = await _findErrorToFixOfType(errorCode);
    fix = await _assertHasFix(kind, error, hasFixAllFix: true);
    change = fix.change;

    // apply to "file"
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));

    String fileContent = testCode;
    if (target != null) {
      expect(fileEdits.first.file, convertPath(target));
      fileContent = getFile(target).readAsStringSync();
    }

    resultCode = SourceEdit.applySequence(fileContent, change.edits[0].edits);
    // verify
    expect(resultCode, expected);
  }

  assertNoFix(FixKind kind) async {
    AnalysisError error = await _findErrorToFix();
    await _assertNoFix(kind, error);
  }

  List<LinkedEditSuggestion> expectedSuggestions(
      LinkedEditSuggestionKind kind, List<String> values) {
    return values.map((value) {
      return new LinkedEditSuggestion(value, kind);
    }).toList();
  }

  void setUp() {
    super.setUp();
    verifyNoTestUnitErrors = false;
  }

  /**
   * Computes fixes and verifies that there is a fix of the given kind.
   */
  Future<Fix> _assertHasFix(FixKind kind, AnalysisError error,
      {bool hasFixAllFix: false}) async {
    if (hasFixAllFix && !kind.canBeAppliedTogether()) {
      fail('Expected to find and return fix-all FixKind for $kind, '
          'but kind.canBeAppliedTogether is ${kind.canBeAppliedTogether}');
    }

    // Compute the fixes for this AnalysisError
    final List<Fix> fixes = await _computeFixes(error);

    // If hasFixAllFix is false, assert that none of the fixes are a fix-all fix
    if (!hasFixAllFix) {
      for (Fix fix in fixes) {
        if (fix.isFixAllFix()) {
          fail('The boolean hasFixAllFix is false, but such a fix was found '
              'in the computed set of fixes: $fixes, error: $error.');
        }
      }
    }
    // If hasFixAllFix is true, assert that there exists such a fix in the list
    else {
      bool foundFixAllFix = false;
      for (Fix fix in fixes) {
        if (fix.isFixAllFix()) {
          foundFixAllFix = true;
          break;
        }
      }
      if (!foundFixAllFix) {
        fail('The boolean hasFixAllFix is true, but no fix-all fix was found '
            'in the computed set of fixes: $fixes, error: $error.');
      }
    }

    Fix foundFix = null;
    if (!hasFixAllFix) {
      foundFix = fixes.firstWhere(
        (fix) => fix.kind == kind && !fix.isFixAllFix(),
        orElse: () => null,
      );
    } else {
      foundFix = fixes.lastWhere(
        (fix) => fix.kind == kind && fix.isFixAllFix(),
        orElse: () => null,
      );
    }
    if (foundFix == null) {
      fail('Expected to find fix $kind in\n${fixes.join('\n')}, hasFixAllFix = '
          '$hasFixAllFix');
    }
    return foundFix;
  }

  Future _assertNoFix(FixKind kind, AnalysisError error) async {
    List<Fix> fixes = await _computeFixes(error);
    for (Fix fix in fixes) {
      if (fix.kind == kind) {
        fail('Unexpected fix $kind in\n${fixes.join('\n')}');
      }
    }
  }

  Future<List<AnalysisError>> _computeErrors() async {
    return (await driver.getResult(convertPath(testFile))).errors;
  }

  /**
   * Computes fixes for the given [error] in [testUnit].
   */
  Future<List<Fix>> _computeFixes(AnalysisError error) async {
    var fixContext = new DartFixContextImpl(testAnalysisResult, error);
    return await new DartFixContributor().computeFixes(fixContext);
  }

  Future<AnalysisError> _findErrorToFix() async {
    List<AnalysisError> errors = await _computeErrors();
    List<AnalysisError> filteredErrors = errors;
    if (errorFilter != null) {
      filteredErrors = filteredErrors.where(errorFilter).toList();
    }
    if (filteredErrors.length != 1) {
      StringBuffer buffer = new StringBuffer();
      buffer.writeln('Expected one error, found:');
      for (AnalysisError error in errors) {
        buffer.writeln('  $error [${error.errorCode}]');
      }
      fail(buffer.toString());
    }
    return filteredErrors[0];
  }

  Future<AnalysisError> _findErrorToFixOfType(ErrorCode errorCode) async {
    List<AnalysisError> errors = await _computeErrors();
    if (errorFilter != null) {
      errors = errors.where(errorFilter).toList();
    }
    return errors.firstWhere((error) => errorCode == error.errorCode);
  }
}

@reflectiveTest
class LintFixTest extends BaseFixProcessorTest {
  AnalysisError error;

  Future applyFix(FixKind kind) async {
    fix = await _assertHasFix(kind, error);
    change = fix.change;
    // apply to "file"
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    resultCode = SourceEdit.applySequence(testCode, change.edits[0].edits);
  }

  @override
  assertNoFix(FixKind kind) async {
    await _assertNoFix(kind, error);
  }

  Future<void> findLint(String src, String lintCode, {int length: 1}) async {
    int errorOffset = src.indexOf('/*LINT*/');
    await resolveTestUnit(src.replaceAll('/*LINT*/', ''));
    error = new AnalysisError(
        resolutionMap.elementDeclaredByCompilationUnit(testUnit).source,
        errorOffset,
        length,
        new LintCode(lintCode, '<ignored>'));
  }

  test_addRequiredAnnotation() async {
    String src = '''
void function({String /*LINT*/param}) {
  assert(param != null);
}
''';
    await findLint(src, LintNames.always_require_non_null_named_parameters);
    await applyFix(DartFixKind.LINT_ADD_REQUIRED);
    verifyResult('''
void function({@required String param}) {
  assert(param != null);
}
''');
  }

  test_isNotEmpty() async {
    String src = '''
f(c) {
  if (/*LINT*/!c.isEmpty) {}
}
''';
    await findLint(src, LintNames.prefer_is_not_empty);

    await applyFix(DartFixKind.USE_IS_NOT_EMPTY);

    verifyResult('''
f(c) {
  if (c.isNotEmpty) {}
}
''');
  }

  test_lint_addMissingOverride_field() async {
    String src = '''
class abstract Test {
  int get t;
}
class Sub extends Test {
  int /*LINT*/t = 42;
}
''';
    await findLint(src, LintNames.annotate_overrides);

    await applyFix(DartFixKind.LINT_ADD_OVERRIDE);

    verifyResult('''
class abstract Test {
  int get t;
}
class Sub extends Test {
  @override
  int t = 42;
}
''');
  }

  test_lint_addMissingOverride_getter() async {
    String src = '''
class Test {
  int get t => null;
}
class Sub extends Test {
  int get /*LINT*/t => null;
}
''';
    await findLint(src, LintNames.annotate_overrides);

    await applyFix(DartFixKind.LINT_ADD_OVERRIDE);

    verifyResult('''
class Test {
  int get t => null;
}
class Sub extends Test {
  @override
  int get t => null;
}
''');
  }

  test_lint_addMissingOverride_method() async {
    String src = '''
class Test {
  void t() { }
}
class Sub extends Test {
  void /*LINT*/t() { }
}
''';
    await findLint(src, LintNames.annotate_overrides);

    await applyFix(DartFixKind.LINT_ADD_OVERRIDE);

    verifyResult('''
class Test {
  void t() { }
}
class Sub extends Test {
  @override
  void t() { }
}
''');
  }

  test_lint_addMissingOverride_method_with_doc_comment() async {
    String src = '''
class Test {
  void t() { }
}
class Sub extends Test {
  /// Doc comment.
  void /*LINT*/t() { }
}
''';
    await findLint(src, LintNames.annotate_overrides);

    await applyFix(DartFixKind.LINT_ADD_OVERRIDE);

    verifyResult('''
class Test {
  void t() { }
}
class Sub extends Test {
  /// Doc comment.
  @override
  void t() { }
}
''');
  }

  test_lint_addMissingOverride_method_with_doc_comment_2() async {
    String src = '''
class Test {
  void t() { }
}
class Sub extends Test {
  /**
   * Doc comment.
   */
  void /*LINT*/t() { }
}
''';
    await findLint(src, LintNames.annotate_overrides);

    await applyFix(DartFixKind.LINT_ADD_OVERRIDE);

    verifyResult('''
class Test {
  void t() { }
}
class Sub extends Test {
  /**
   * Doc comment.
   */
  @override
  void t() { }
}
''');
  }

  test_lint_addMissingOverride_method_with_doc_comment_and_metadata() async {
    String src = '''
class Test {
  void t() { }
}
class Sub extends Test {
  /// Doc comment.
  @foo
  void /*LINT*/t() { }
}
''';
    await findLint(src, LintNames.annotate_overrides);

    await applyFix(DartFixKind.LINT_ADD_OVERRIDE);

    verifyResult('''
class Test {
  void t() { }
}
class Sub extends Test {
  /// Doc comment.
  @override
  @foo
  void t() { }
}
''');
  }

  test_lint_addMissingOverride_method_with_non_doc_comment() async {
    String src = '''
class Test {
  void t() { }
}
class Sub extends Test {
  // Non-doc comment.
  void /*LINT*/t() { }
}
''';
    await findLint(src, LintNames.annotate_overrides);

    await applyFix(DartFixKind.LINT_ADD_OVERRIDE);

    verifyResult('''
class Test {
  void t() { }
}
class Sub extends Test {
  // Non-doc comment.
  @override
  void t() { }
}
''');
  }

  test_lint_removeInterpolationBraces() async {
    String src = r'''
main() {
  var v = 42;
  print('v: /*LINT*/${ v}');
}
''';
    await findLint(src, LintNames.unnecessary_brace_in_string_interp,
        length: 4);
    await applyFix(DartFixKind.LINT_REMOVE_INTERPOLATION_BRACES);
    verifyResult(r'''
main() {
  var v = 42;
  print('v: $v');
}
''');
  }

  test_makeFieldFinal_noKeyword() async {
    String src = '''
class C {
  /*LINT*/f = 2;
}
''';
    await findLint(src, LintNames.prefer_final_fields);

    await applyFix(DartFixKind.MAKE_FINAL);

    verifyResult('''
class C {
  final f = 2;
}
''');
  }

  test_makeFieldFinal_type() async {
    String src = '''
class C {
  int /*LINT*/f = 2;
}
''';
    await findLint(src, LintNames.prefer_final_fields);

    await applyFix(DartFixKind.MAKE_FINAL);

    verifyResult('''
class C {
  final int f = 2;
}
''');
  }

  test_makeFieldFinal_var() async {
    String src = '''
class C {
  var /*LINT*/f = 2;
}
''';
    await findLint(src, LintNames.prefer_final_fields);

    await applyFix(DartFixKind.MAKE_FINAL);

    verifyResult('''
class C {
  final f = 2;
}
''');
  }

  test_makeLocalFinal_type() async {
    String src = '''
bad() {
  int /*LINT*/x = 2;
}
''';
    await findLint(src, LintNames.prefer_final_locals);

    await applyFix(DartFixKind.MAKE_FINAL);

    verifyResult('''
bad() {
  final int x = 2;
}
''');
  }

  test_makeLocalFinal_var() async {
    String src = '''
bad() {
  var /*LINT*/x = 2;
}
''';
    await findLint(src, LintNames.prefer_final_locals);

    await applyFix(DartFixKind.MAKE_FINAL);

    verifyResult('''
bad() {
  final x = 2;
}
''');
  }

  test_removeAwait_intLiteral() async {
    String src = '''
bad() async {
  print(/*LINT*/await 23);
}
''';
    await findLint(src, LintNames.await_only_futures);

    await applyFix(DartFixKind.REMOVE_AWAIT);

    verifyResult('''
bad() async {
  print(23);
}
''');
  }

  test_removeAwait_StringLiteral() async {
    String src = '''
bad() async {
  print(/*LINT*/await 'hola');
}
''';
    await findLint(src, LintNames.await_only_futures);

    await applyFix(DartFixKind.REMOVE_AWAIT);

    verifyResult('''
bad() async {
  print('hola');
}
''');
  }

  test_removeEmptyCatch_newLine() async {
    String src = '''
void foo() {
  try {}
  catch (e) {/*LINT*/}
  finally {}
}
''';
    await findLint(src, LintNames.empty_catches);

    await applyFix(DartFixKind.REMOVE_EMPTY_CATCH);

    verifyResult('''
void foo() {
  try {}
  finally {}
}
''');
  }

  test_removeEmptyCatch_sameLine() async {
    String src = '''
void foo() {
  try {} catch (e) {/*LINT*/} finally {}
}
''';
    await findLint(src, LintNames.empty_catches);

    await applyFix(DartFixKind.REMOVE_EMPTY_CATCH);

    verifyResult('''
void foo() {
  try {} finally {}
}
''');
  }

  test_removeEmptyConstructorBody() async {
    String src = '''
class C {
  C() {/*LINT*/}
}
''';
    await findLint(src, LintNames.empty_constructor_bodies);

    await applyFix(DartFixKind.REMOVE_EMPTY_CONSTRUCTOR_BODY);

    verifyResult('''
class C {
  C();
}
''');
  }

  test_removeEmptyElse_newLine() async {
    String src = '''
void foo(bool cond) {
  if (cond) {
    //
  }
  else /*LINT*/;
}
''';
    await findLint(src, LintNames.avoid_empty_else);

    await applyFix(DartFixKind.REMOVE_EMPTY_ELSE);

    verifyResult('''
void foo(bool cond) {
  if (cond) {
    //
  }
}
''');
  }

  test_removeEmptyElse_sameLine() async {
    String src = '''
void foo(bool cond) {
  if (cond) {
    //
  } else /*LINT*/;
}
''';
    await findLint(src, LintNames.avoid_empty_else);

    await applyFix(DartFixKind.REMOVE_EMPTY_ELSE);

    verifyResult('''
void foo(bool cond) {
  if (cond) {
    //
  }
}
''');
  }

  test_removeEmptyStatement_insideBlock() async {
    String src = '''
void foo() {
  while(true) {
    /*LINT*/;
  }
}
''';
    await findLint(src, LintNames.empty_statements);

    await applyFix(DartFixKind.REMOVE_EMPTY_STATEMENT);

    verifyResult('''
void foo() {
  while(true) {
  }
}
''');
  }

  test_removeEmptyStatement_outOfBlock_otherLine() async {
    String src = '''
void foo() {
  while(true)
  /*LINT*/;
  print('hi');
}
''';
    await findLint(src, LintNames.empty_statements);

    await applyFix(DartFixKind.REPLACE_WITH_BRACKETS);

    verifyResult('''
void foo() {
  while(true) {}
  print('hi');
}
''');
  }

  test_removeEmptyStatement_outOfBlock_sameLine() async {
    String src = '''
void foo() {
  while(true)/*LINT*/;
  print('hi');
}
''';
    await findLint(src, LintNames.empty_statements);

    await applyFix(DartFixKind.REPLACE_WITH_BRACKETS);

    verifyResult('''
void foo() {
  while(true) {}
  print('hi');
}
''');
  }

  test_removeInitializer_field() async {
    String src = '''
class Test {
  int /*LINT*/x = null;
}
''';
    await findLint(src, LintNames.avoid_init_to_null);

    await applyFix(DartFixKind.REMOVE_INITIALIZER);

    verifyResult('''
class Test {
  int x;
}
''');
  }

  test_removeInitializer_listOfVariableDeclarations() async {
    String src = '''
String a = 'a', /*LINT*/b = null, c = 'c';
''';
    await findLint(src, LintNames.avoid_init_to_null);

    await applyFix(DartFixKind.REMOVE_INITIALIZER);

    verifyResult('''
String a = 'a', b, c = 'c';
''');
  }

  test_removeInitializer_topLevel() async {
    String src = '''
var /*LINT*/x = null;
''';
    await findLint(src, LintNames.avoid_init_to_null);

    await applyFix(DartFixKind.REMOVE_INITIALIZER);

    verifyResult('''
var x;
''');
  }

  test_removeMethodDeclaration_getter() async {
    String src = '''
class A {
  int x;
}
class B extends A {
  @override
  int get /*LINT*/x => super.x;
}
''';
    await findLint(src, LintNames.unnecessary_override);

    await applyFix(DartFixKind.REMOVE_METHOD_DECLARATION);

    verifyResult('''
class A {
  int x;
}
class B extends A {
}
''');
  }

  test_removeMethodDeclaration_method() async {
    String src = '''
class A {
  @override
  String /*LINT*/toString() => super.toString();
}
''';
    await findLint(src, LintNames.unnecessary_override);

    await applyFix(DartFixKind.REMOVE_METHOD_DECLARATION);

    verifyResult('''
class A {
}
''');
  }

  test_removeMethodDeclaration_setter() async {
    String src = '''
class A {
  int x;
}
class B extends A {
  @override
  set /*LINT*/x(int other) {
    this.x = other;
  }
}
''';
    await findLint(src, LintNames.unnecessary_override);

    await applyFix(DartFixKind.REMOVE_METHOD_DECLARATION);

    verifyResult('''
class A {
  int x;
}
class B extends A {
}
''');
  }

  test_removeThisExpression_methodInvocation_oneCharacterOperator() async {
    String src = '''
class A {
  void foo() {
    /*LINT*/this.foo();
  }
}
''';
    await findLint(src, LintNames.unnecessary_this);

    await applyFix(DartFixKind.REMOVE_THIS_EXPRESSION);

    verifyResult('''
class A {
  void foo() {
    foo();
  }
}
''');
  }

  test_removeThisExpression_methodInvocation_twoCharactersOperator() async {
    String src = '''
class A {
  void foo() {
    /*LINT*/this?.foo();
  }
}
''';
    await findLint(src, LintNames.unnecessary_this);

    await applyFix(DartFixKind.REMOVE_THIS_EXPRESSION);

    verifyResult('''
class A {
  void foo() {
    foo();
  }
}
''');
  }

  test_removeThisExpression_notAThisExpression() async {
    String src = '''
void foo() {
  final /*LINT*/this.id;
}
''';
    await findLint(src, LintNames.unnecessary_this);

    await assertNoFix(DartFixKind.REMOVE_THIS_EXPRESSION);
  }

  test_removeThisExpression_propertyAccess_oneCharacterOperator() async {
    String src = '''
class A {
  int x;
  void foo() {
    /*LINT*/this.x = 2;
  }
}
''';
    await findLint(src, LintNames.unnecessary_this);

    await applyFix(DartFixKind.REMOVE_THIS_EXPRESSION);

    verifyResult('''
class A {
  int x;
  void foo() {
    x = 2;
  }
}
''');
  }

  test_removeThisExpression_propertyAccess_twoCharactersOperator() async {
    String src = '''
class A {
  int x;
  void foo() {
    /*LINT*/this?.x = 2;
  }
}
''';
    await findLint(src, LintNames.unnecessary_this);

    await applyFix(DartFixKind.REMOVE_THIS_EXPRESSION);

    verifyResult('''
class A {
  int x;
  void foo() {
    x = 2;
  }
}
''');
  }

  test_removeTypeAnnotation_avoidAnnotatingWithDynamic_InsideFunctionTypedFormalParameter() async {
    String src = '''
bad(void foo(/*LINT*/dynamic x)) {
  return null;
}
''';
    await findLint(src, LintNames.avoid_annotating_with_dynamic);

    await applyFix(DartFixKind.REMOVE_TYPE_NAME);

    verifyResult('''
bad(void foo(x)) {
  return null;
}
''');
  }

  test_removeTypeAnnotation_avoidAnnotatingWithDynamic_NamedParameter() async {
    String src = '''
bad({/*LINT*/dynamic defaultValue}) {
  return null;
}
''';
    await findLint(src, LintNames.avoid_annotating_with_dynamic);

    await applyFix(DartFixKind.REMOVE_TYPE_NAME);

    verifyResult('''
bad({defaultValue}) {
  return null;
}
''');
  }

  test_removeTypeAnnotation_avoidAnnotatingWithDynamic_NormalParameter() async {
    String src = '''
bad(/*LINT*/dynamic defaultValue) {
  return null;
}
''';
    await findLint(src, LintNames.avoid_annotating_with_dynamic);

    await applyFix(DartFixKind.REMOVE_TYPE_NAME);

    verifyResult('''
bad(defaultValue) {
  return null;
}
''');
  }

  test_removeTypeAnnotation_avoidAnnotatingWithDynamic_OptionalParameter() async {
    String src = '''
bad([/*LINT*/dynamic defaultValue]) {
  return null;
}
''';
    await findLint(src, LintNames.avoid_annotating_with_dynamic);

    await applyFix(DartFixKind.REMOVE_TYPE_NAME);

    verifyResult('''
bad([defaultValue]) {
  return null;
}
''');
  }

  test_removeTypeAnnotation_avoidReturnTypesOnSetters_void() async {
    String src = '''
/*LINT*/void set speed2(int ms) {}
''';
    await findLint(src, LintNames.avoid_return_types_on_setters);

    await applyFix(DartFixKind.REMOVE_TYPE_NAME);

    verifyResult('''
set speed2(int ms) {}
''');
  }

  test_removeTypeAnnotation_avoidTypesOnClosureParameters_FunctionTypedFormalParameter() async {
    String src = '''
var functionWithFunction = (/*LINT*/int f(int x)) => f(0);
''';
    await findLint(src, LintNames.avoid_types_on_closure_parameters);

    await applyFix(DartFixKind.REPLACE_WITH_IDENTIFIER);

    verifyResult('''
var functionWithFunction = (f) => f(0);
''');
  }

  test_removeTypeAnnotation_avoidTypesOnClosureParameters_NamedParameter() async {
    String src = '''
var x = ({/*LINT*/Future<int> defaultValue}) {
  return null;
};
''';
    await findLint(src, LintNames.avoid_types_on_closure_parameters);

    await applyFix(DartFixKind.REMOVE_TYPE_NAME);

    verifyResult('''
var x = ({defaultValue}) {
  return null;
};
''');
  }

  test_removeTypeAnnotation_avoidTypesOnClosureParameters_NormalParameter() async {
    String src = '''
var x = (/*LINT*/Future<int> defaultValue) {
  return null;
};
''';
    await findLint(src, LintNames.avoid_types_on_closure_parameters);

    await applyFix(DartFixKind.REMOVE_TYPE_NAME);

    verifyResult('''
var x = (defaultValue) {
  return null;
};
''');
  }

  test_removeTypeAnnotation_avoidTypesOnClosureParameters_OptionalParameter() async {
    String src = '''
var x = ([/*LINT*/Future<int> defaultValue]) {
  return null;
};
''';
    await findLint(src, LintNames.avoid_types_on_closure_parameters);

    await applyFix(DartFixKind.REMOVE_TYPE_NAME);

    verifyResult('''
var x = ([defaultValue]) {
  return null;
};
''');
  }

  test_removeTypeAnnotation_typeInitFormals_void() async {
    String src = '''
class C {
  int f;
  C(/*LINT*/int this.f);
}
''';
    await findLint(src, LintNames.type_init_formals);

    await applyFix(DartFixKind.REMOVE_TYPE_NAME);

    verifyResult('''
class C {
  int f;
  C(this.f);
}
''');
  }

  test_renameToCamelCase_BAD_parameter_optionalNamed() async {
    String src = '''
foo({int /*LINT*/my_integer_variable}) {
  print(my_integer_variable);
}
''';
    await findLint(src, LintNames.non_constant_identifier_names);
    await assertNoFix(DartFixKind.RENAME_TO_CAMEL_CASE);
  }

  test_renameToCamelCase_OK_localVariable() async {
    String src = '''
main() {
  int /*LINT*/my_integer_variable = 42;
  int foo;
  print(my_integer_variable);
  print(foo);
}
''';
    await findLint(src, LintNames.non_constant_identifier_names);

    await applyFix(DartFixKind.RENAME_TO_CAMEL_CASE);

    verifyResult('''
main() {
  int myIntegerVariable = 42;
  int foo;
  print(myIntegerVariable);
  print(foo);
}
''');
  }

  test_renameToCamelCase_OK_parameter_closure() async {
    String src = '''
main() {
  [0, 1, 2].forEach((/*LINT*/my_integer_variable) {
    print(my_integer_variable);
  });
}
''';
    await findLint(src, LintNames.non_constant_identifier_names);

    await applyFix(DartFixKind.RENAME_TO_CAMEL_CASE);

    verifyResult('''
main() {
  [0, 1, 2].forEach((myIntegerVariable) {
    print(myIntegerVariable);
  });
}
''');
  }

  test_renameToCamelCase_OK_parameter_function() async {
    String src = '''
main(int /*LINT*/my_integer_variable) {
  print(my_integer_variable);
}
''';
    await findLint(src, LintNames.non_constant_identifier_names);

    await applyFix(DartFixKind.RENAME_TO_CAMEL_CASE);

    verifyResult('''
main(int myIntegerVariable) {
  print(myIntegerVariable);
}
''');
  }

  test_renameToCamelCase_OK_parameter_method() async {
    String src = '''
class A {
  main(int /*LINT*/my_integer_variable) {
    print(my_integer_variable);
  }
}
''';
    await findLint(src, LintNames.non_constant_identifier_names);

    await applyFix(DartFixKind.RENAME_TO_CAMEL_CASE);

    verifyResult('''
class A {
  main(int myIntegerVariable) {
    print(myIntegerVariable);
  }
}
''');
  }

  test_renameToCamelCase_OK_parameter_optionalPositional() async {
    String src = '''
main([int /*LINT*/my_integer_variable]) {
  print(my_integer_variable);
}
''';
    await findLint(src, LintNames.non_constant_identifier_names);

    await applyFix(DartFixKind.RENAME_TO_CAMEL_CASE);

    verifyResult('''
main([int myIntegerVariable]) {
  print(myIntegerVariable);
}
''');
  }

  test_replaceFinalWithConst_method() async {
    String src = '''
/*LINT*/final int a = 1;
''';
    await findLint(src, LintNames.prefer_const_declarations);

    await applyFix(DartFixKind.REPLACE_FINAL_WITH_CONST);

    verifyResult('''
const int a = 1;
''');
  }

  test_replaceWithConditionalAssignment_withCodeBeforeAndAfter() async {
    String src = '''
class Person {
  String _fullName;
  void foo() {
    print('hi');
    /*LINT*/if (_fullName == null) {
      _fullName = getFullUserName(this);
    }
    print('hi');
  }
}
''';
    await findLint(src, LintNames.prefer_conditional_assignment);

    await applyFix(DartFixKind.REPLACE_WITH_CONDITIONAL_ASSIGNMENT);

    verifyResult('''
class Person {
  String _fullName;
  void foo() {
    print('hi');
    _fullName ??= getFullUserName(this);
    print('hi');
  }
}
''');
  }

  test_replaceWithConditionalAssignment_withOneBlock() async {
    String src = '''
class Person {
  String _fullName;
  void foo() {
    /*LINT*/if (_fullName == null) {
      _fullName = getFullUserName(this);
    }
  }
}
''';
    await findLint(src, LintNames.prefer_conditional_assignment);

    await applyFix(DartFixKind.REPLACE_WITH_CONDITIONAL_ASSIGNMENT);

    verifyResult('''
class Person {
  String _fullName;
  void foo() {
    _fullName ??= getFullUserName(this);
  }
}
''');
  }

  test_replaceWithConditionalAssignment_withoutBlock() async {
    String src = '''
class Person {
  String _fullName;
  void foo() {
    /*LINT*/if (_fullName == null)
      _fullName = getFullUserName(this);
  }
}
''';
    await findLint(src, LintNames.prefer_conditional_assignment);

    await applyFix(DartFixKind.REPLACE_WITH_CONDITIONAL_ASSIGNMENT);

    verifyResult('''
class Person {
  String _fullName;
  void foo() {
    _fullName ??= getFullUserName(this);
  }
}
''');
  }

  test_replaceWithConditionalAssignment_withTwoBlock() async {
    String src = '''
class Person {
  String _fullName;
  void foo() {
    /*LINT*/if (_fullName == null) {{
      _fullName = getFullUserName(this);
    }}
  }
}
''';
    await findLint(src, LintNames.prefer_conditional_assignment);

    await applyFix(DartFixKind.REPLACE_WITH_CONDITIONAL_ASSIGNMENT);

    verifyResult('''
class Person {
  String _fullName;
  void foo() {
    _fullName ??= getFullUserName(this);
  }
}
''');
  }

  test_replaceWithLiteral_linkedHashMap_withCommentsInGeneric() async {
    String src = '''
import 'dart:collection';

final a = /*LINT*/new LinkedHashMap<int,/*comment*/int>();
''';
    await findLint(src, LintNames.prefer_collection_literals);

    await applyFix(DartFixKind.REPLACE_WITH_LITERAL);

    verifyResult('''
import 'dart:collection';

final a = <int,/*comment*/int>{};
''');
  }

  test_replaceWithLiteral_linkedHashMap_withDynamicGenerics() async {
    String src = '''
import 'dart:collection';

final a = /*LINT*/new LinkedHashMap<dynamic,dynamic>();
''';
    await findLint(src, LintNames.prefer_collection_literals);

    await applyFix(DartFixKind.REPLACE_WITH_LITERAL);

    verifyResult('''
import 'dart:collection';

final a = <dynamic,dynamic>{};
''');
  }

  test_replaceWithLiteral_linkedHashMap_withGeneric() async {
    String src = '''
import 'dart:collection';

final a = /*LINT*/new LinkedHashMap<int,int>();
''';
    await findLint(src, LintNames.prefer_collection_literals);

    await applyFix(DartFixKind.REPLACE_WITH_LITERAL);

    verifyResult('''
import 'dart:collection';

final a = <int,int>{};
''');
  }

  test_replaceWithLiteral_linkedHashMap_withoutGeneric() async {
    String src = '''
import 'dart:collection';

final a = /*LINT*/new LinkedHashMap();
''';
    await findLint(src, LintNames.prefer_collection_literals);

    await applyFix(DartFixKind.REPLACE_WITH_LITERAL);

    verifyResult('''
import 'dart:collection';

final a = {};
''');
  }

  test_replaceWithLiteral_list_withGeneric() async {
    String src = '''
final a = /*LINT*/new List<int>();
''';
    await findLint(src, LintNames.prefer_collection_literals);

    await applyFix(DartFixKind.REPLACE_WITH_LITERAL);

    verifyResult('''
final a = <int>[];
''');
  }

  test_replaceWithLiteral_list_withoutGeneric() async {
    String src = '''
final a = /*LINT*/new List();
''';
    await findLint(src, LintNames.prefer_collection_literals);

    await applyFix(DartFixKind.REPLACE_WITH_LITERAL);

    verifyResult('''
final a = [];
''');
  }

  test_replaceWithLiteral_map_withGeneric() async {
    String src = '''
final a = /*LINT*/new Map<int,int>();
''';
    await findLint(src, LintNames.prefer_collection_literals);

    await applyFix(DartFixKind.REPLACE_WITH_LITERAL);

    verifyResult('''
final a = <int,int>{};
''');
  }

  test_replaceWithLiteral_map_withoutGeneric() async {
    String src = '''
final a = /*LINT*/new Map();
''';
    await findLint(src, LintNames.prefer_collection_literals);

    await applyFix(DartFixKind.REPLACE_WITH_LITERAL);

    verifyResult('''
final a = {};
''');
  }

  test_replaceWithTearOff_function_oneParameter() async {
    String src = '''
final x = /*LINT*/(name) {
  print(name);
};
''';
    await findLint(src, LintNames.unnecessary_lambdas);

    await applyFix(DartFixKind.REPLACE_WITH_TEAR_OFF);

    verifyResult('''
final x = print;
''');
  }

  test_replaceWithTearOff_function_zeroParameters() async {
    String src = '''
void foo(){}
Function finalVar() {
  return /*LINT*/() {
    foo();
  };
}
''';
    await findLint(src, LintNames.unnecessary_lambdas);

    await applyFix(DartFixKind.REPLACE_WITH_TEAR_OFF);

    verifyResult('''
void foo(){}
Function finalVar() {
  return foo;
}
''');
  }

  test_replaceWithTearOff_lambda_asArgument() async {
    String src = '''
void foo() {
  bool isPair(int a) => a % 2 == 0;
  final finalList = <int>[];
  finalList.where(/*LINT*/(number) =>
    isPair(number));
}
''';
    await findLint(src, LintNames.unnecessary_lambdas);

    await applyFix(DartFixKind.REPLACE_WITH_TEAR_OFF);

    verifyResult('''
void foo() {
  bool isPair(int a) => a % 2 == 0;
  final finalList = <int>[];
  finalList.where(isPair);
}
''');
  }

  test_replaceWithTearOff_method_oneParameter() async {
    String src = '''
var a = /*LINT*/(x) => finalList.remove(x);
''';
    await findLint(src, LintNames.unnecessary_lambdas);

    await applyFix(DartFixKind.REPLACE_WITH_TEAR_OFF);

    verifyResult('''
var a = finalList.remove;
''');
  }

  test_replaceWithTearOff_method_zeroParameter() async {
    String src = '''
final Object a;
Function finalVar() {
  return /*LINT*/() {
    return a.toString();
  };
}
''';
    await findLint(src, LintNames.unnecessary_lambdas);

    await applyFix(DartFixKind.REPLACE_WITH_TEAR_OFF);

    verifyResult('''
final Object a;
Function finalVar() {
  return a.toString;
}
''');
  }

  void verifyResult(String expectedResult) {
    expect(resultCode, expectedResult);
  }
}
