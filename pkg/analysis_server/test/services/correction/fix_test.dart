// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.correction.fix;

import 'dart:async';

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/plugin/edit/fix/fix_dart.dart';
import 'package:analysis_server/plugin/protocol/protocol.dart'
    hide AnalysisError;
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../../abstract_context.dart';
import '../../abstract_single_unit.dart';
import '../../utils.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(FixProcessorTest);
  defineReflectiveTests(LintFixTest);
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

  Fix fix;
  SourceChange change;
  String resultCode;

  assert_undefinedFunction_create_returnType_bool(String lineWithTest) async {
    resolveTestUnit('''
main() {
  bool b = true;
  $lineWithTest
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
main() {
  bool b = true;
  $lineWithTest
}

bool test() {
}
''');
  }

  assertHasFix(FixKind kind, String expected) async {
    AnalysisError error = _findErrorToFix();
    fix = await _assertHasFix(kind, error);
    change = fix.change;
    // apply to "file"
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    resultCode = SourceEdit.applySequence(testCode, change.edits[0].edits);
    // verify
    expect(resultCode, expected);
  }

  assertNoFix(FixKind kind) async {
    AnalysisError error = _findErrorToFix();
    List<Fix> fixes = await _computeFixes(error);
    for (Fix fix in fixes) {
      if (fix.kind == kind) {
        throw fail('Unexpected fix $kind in\n${fixes.join('\n')}');
      }
    }
  }

  Position expectedPosition(String search) {
    int offset = resultCode.indexOf(search);
    return new Position(testFile, offset);
  }

  List<Position> expectedPositions(List<String> patterns) {
    List<Position> positions = <Position>[];
    patterns.forEach((String search) {
      positions.add(expectedPosition(search));
    });
    return positions;
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
  Future<Fix> _assertHasFix(FixKind kind, AnalysisError error) async {
    List<Fix> fixes = await _computeFixes(error);
    for (Fix fix in fixes) {
      if (fix.kind == kind) {
        return fix;
      }
    }
    throw fail('Expected to find fix $kind in\n${fixes.join('\n')}');
  }

  void _assertLinkedGroup(LinkedEditGroup group, List<String> expectedStrings,
      [List<LinkedEditSuggestion> expectedSuggestions]) {
    List<Position> expectedPositions = _findResultPositions(expectedStrings);
    expect(group.positions, unorderedEquals(expectedPositions));
    if (expectedSuggestions != null) {
      expect(group.suggestions, unorderedEquals(expectedSuggestions));
    }
  }

  /**
   * Computes fixes for the given [error] in [testUnit].
   */
  Future<List<Fix>> _computeFixes(AnalysisError error) async {
    DartFixContext dartContext = new DartFixContextImpl(
        new FixContextImpl(provider, context, error), testUnit);
    FixProcessor processor = new FixProcessor(dartContext);
    return processor.compute();
  }

  /**
   * Configures the [SourceFactory] to have the `my_pkg` package in
   * `/packages/my_pkg/lib` folder.
   */
  void _configureMyPkg(String myLibCode) {
    provider.newFile('/packages/my_pkg/lib/my_lib.dart', myLibCode);
    // configure SourceFactory
    Folder myPkgFolder = provider.getResource('/packages/my_pkg/lib');
    UriResolver pkgResolver = new PackageMapUriResolver(provider, {
      'my_pkg': [myPkgFolder]
    });
    context.sourceFactory = new SourceFactory(
        [AbstractContextTest.SDK_RESOLVER, pkgResolver, resourceResolver]);
    // force 'my_pkg' resolution
    addSource('/tmp/other.dart', "import 'package:my_pkg/my_lib.dart';");
  }

  AnalysisError _findErrorToFix() {
    List<AnalysisError> errors = context.computeErrors(testSource);
    if (errorFilter != null) {
      errors = errors.where(errorFilter).toList();
    }
    expect(errors, hasLength(1));
    return errors[0];
  }

  List<Position> _findResultPositions(List<String> searchStrings) {
    List<Position> positions = <Position>[];
    for (String search in searchStrings) {
      int offset = resultCode.indexOf(search);
      positions.add(new Position(testFile, offset));
    }
    return positions;
  }

  void _performAnalysis() {
    while (context.performAnalysisTask().hasMoreWork);
  }
}

@reflectiveTest
class FixProcessorTest extends BaseFixProcessorTest {
  test_addFieldFormalParameters_hasRequiredParameter() async {
    resolveTestUnit('''
class Test {
  final int a;
  final int b;
  final int c;
  Test(this.a);
}
''');
    await assertHasFix(
        DartFixKind.ADD_FIELD_FORMAL_PARAMETERS,
        '''
class Test {
  final int a;
  final int b;
  final int c;
  Test(this.a, this.b, this.c);
}
''');
  }

  test_addFieldFormalParameters_noParameters() async {
    resolveTestUnit('''
class Test {
  final int a;
  final int b;
  final int c;
  Test();
}
''');
    await assertHasFix(
        DartFixKind.ADD_FIELD_FORMAL_PARAMETERS,
        '''
class Test {
  final int a;
  final int b;
  final int c;
  Test(this.a, this.b, this.c);
}
''');
  }

  test_addFieldFormalParameters_noRequiredParameter() async {
    resolveTestUnit('''
class Test {
  final int a;
  final int b;
  final int c;
  Test([this.c]);
}
''');
    await assertHasFix(
        DartFixKind.ADD_FIELD_FORMAL_PARAMETERS,
        '''
class Test {
  final int a;
  final int b;
  final int c;
  Test(this.a, this.b, [this.c]);
}
''');
  }

  test_addMissingParameter_function_positional_hasNamed() async {
    resolveTestUnit('''
test({int a}) {}
main() {
  test(1);
}
''');
    await assertNoFix(DartFixKind.ADD_MISSING_PARAMETER_POSITIONAL);
  }

  test_addMissingParameter_function_positional_hasZero() async {
    resolveTestUnit('''
test() {}
main() {
  test(1);
}
''');
    await assertHasFix(
        DartFixKind.ADD_MISSING_PARAMETER_POSITIONAL,
        '''
test([int i]) {}
main() {
  test(1);
}
''');
  }

  test_addMissingParameter_function_required_hasNamed() async {
    resolveTestUnit('''
test({int a}) {}
main() {
  test(1);
}
''');
    await assertHasFix(
        DartFixKind.ADD_MISSING_PARAMETER_REQUIRED,
        '''
test(int i, {int a}) {}
main() {
  test(1);
}
''');
  }

  test_addMissingParameter_function_required_hasOne() async {
    resolveTestUnit('''
test(int a) {}
main() {
  test(1, 2.0);
}
''');
    await assertHasFix(
        DartFixKind.ADD_MISSING_PARAMETER_REQUIRED,
        '''
test(int a, double d) {}
main() {
  test(1, 2.0);
}
''');
  }

  test_addMissingParameter_function_required_hasZero() async {
    resolveTestUnit('''
test() {}
main() {
  test(1);
}
''');
    await assertHasFix(
        DartFixKind.ADD_MISSING_PARAMETER_REQUIRED,
        '''
test(int i) {}
main() {
  test(1);
}
''');
  }

  test_addMissingParameter_method_positional_hasOne() async {
    resolveTestUnit('''
class A {
  test(int a) {}
  main() {
    test(1, 2.0);
  }
}
''');
    await assertHasFix(
        DartFixKind.ADD_MISSING_PARAMETER_POSITIONAL,
        '''
class A {
  test(int a, [double d]) {}
  main() {
    test(1, 2.0);
  }
}
''');
  }

  test_addMissingParameter_method_required_hasOne() async {
    resolveTestUnit('''
class A {
  test(int a) {}
  main() {
    test(1, 2.0);
  }
}
''');
    await assertHasFix(
        DartFixKind.ADD_MISSING_PARAMETER_REQUIRED,
        '''
class A {
  test(int a, double d) {}
  main() {
    test(1, 2.0);
  }
}
''');
  }

  test_addMissingParameter_method_required_hasZero() async {
    resolveTestUnit('''
class A {
  test() {}
  main() {
    test(1);
  }
}
''');
    await assertHasFix(
        DartFixKind.ADD_MISSING_PARAMETER_REQUIRED,
        '''
class A {
  test(int i) {}
  main() {
    test(1);
  }
}
''');
  }

  test_addPartOfDirective() async {
    String partCode = r'''
// Comment first.
// Comment second.

class A {}
''';
    addSource('/part.dart', partCode);
    resolveTestUnit('''
library my.lib;
part 'part.dart';
''');
    _performAnalysis();
    AnalysisError error = _findErrorToFix();
    fix = await _assertHasFix(DartFixKind.ADD_PART_OF, error);
    change = fix.change;
    // apply to "file"
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = change.edits[0];
    expect(fileEdit.file, '/part.dart');
    expect(
        SourceEdit.applySequence(partCode, fileEdit.edits),
        r'''
// Comment first.
// Comment second.

part of my.lib;

class A {}
''');
  }

  test_addSync_asyncFor() async {
    resolveTestUnit('''
import 'dart:async';
void main(Stream<String> names) {
  await for (String name in names) {
    print(name);
  }
}
''');
    await assertHasFix(
        DartFixKind.ADD_ASYNC,
        '''
import 'dart:async';
Future main(Stream<String> names) async {
  await for (String name in names) {
    print(name);
  }
}
''');
  }

  test_addSync_BAD_nullFunctionBody() async {
    resolveTestUnit('''
var F = await;
''');
    await assertNoFix(DartFixKind.ADD_ASYNC);
  }

  test_addSync_blockFunctionBody() async {
    resolveTestUnit('''
foo() {}
main() {
  await foo();
}
''');
    List<AnalysisError> errors = context.computeErrors(testSource);
    expect(errors, hasLength(2));
    String message1 = "Expected to find ';'";
    String message2 = "Undefined name 'await'";
    expect(errors.map((e) => e.message), unorderedEquals([message1, message2]));
    for (AnalysisError error in errors) {
      if (error.message == message1) {
        List<Fix> fixes = await _computeFixes(error);
        expect(fixes, isEmpty);
      }
      if (error.message == message2) {
        List<Fix> fixes = await _computeFixes(error);
        // has exactly one fix
        expect(fixes, hasLength(1));
        Fix fix = fixes[0];
        expect(fix.kind, DartFixKind.ADD_ASYNC);
        // apply to "file"
        List<SourceFileEdit> fileEdits = fix.change.edits;
        expect(fileEdits, hasLength(1));
        resultCode = SourceEdit.applySequence(testCode, fileEdits[0].edits);
        // verify
        expect(
            resultCode,
            '''
foo() {}
main() async {
  await foo();
}
''');
      }
    }
  }

  test_addSync_expressionFunctionBody() async {
    errorFilter = (AnalysisError error) {
      return error.errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER;
    };
    resolveTestUnit('''
foo() {}
main() => await foo();
''');
    await assertHasFix(
        DartFixKind.ADD_ASYNC,
        '''
foo() {}
main() async => await foo();
''');
  }

  test_addSync_returnFuture() async {
    errorFilter = (AnalysisError error) {
      return error.errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER;
    };
    resolveTestUnit('''
foo() {}
int main() {
  await foo();
  return 42;
}
''');
    await assertHasFix(
        DartFixKind.ADD_ASYNC,
        '''
import 'dart:async';

foo() {}
Future<int> main() async {
  await foo();
  return 42;
}
''');
  }

  test_addSync_returnFuture_alreadyFuture() async {
    errorFilter = (AnalysisError error) {
      return error.errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER;
    };
    resolveTestUnit('''
import 'dart:async';
foo() {}
Future<int> main() {
  await foo();
  return 42;
}
''');
    await assertHasFix(
        DartFixKind.ADD_ASYNC,
        '''
import 'dart:async';
foo() {}
Future<int> main() async {
  await foo();
  return 42;
}
''');
  }

  test_addSync_returnFuture_dynamic() async {
    errorFilter = (AnalysisError error) {
      return error.errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER;
    };
    resolveTestUnit('''
foo() {}
dynamic main() {
  await foo();
  return 42;
}
''');
    await assertHasFix(
        DartFixKind.ADD_ASYNC,
        '''
foo() {}
dynamic main() async {
  await foo();
  return 42;
}
''');
  }

  test_addSync_returnFuture_noType() async {
    errorFilter = (AnalysisError error) {
      return error.errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER;
    };
    resolveTestUnit('''
foo() {}
main() {
  await foo();
  return 42;
}
''');
    await assertHasFix(
        DartFixKind.ADD_ASYNC,
        '''
foo() {}
main() async {
  await foo();
  return 42;
}
''');
  }

  test_boolean() async {
    resolveTestUnit('''
main() {
  boolean v;
}
''');
    await assertHasFix(
        DartFixKind.REPLACE_BOOLEAN_WITH_BOOL,
        '''
main() {
  bool v;
}
''');
  }

  test_canBeNullAfterNullAware_chain() async {
    resolveTestUnit('''
main(x) {
  x?.a.b.c;
}
''');
    await assertHasFix(
        DartFixKind.REPLACE_WITH_NULL_AWARE,
        '''
main(x) {
  x?.a?.b?.c;
}
''');
  }

  test_canBeNullAfterNullAware_methodInvocation() async {
    resolveTestUnit('''
main(x) {
  x?.a.b();
}
''');
    await assertHasFix(
        DartFixKind.REPLACE_WITH_NULL_AWARE,
        '''
main(x) {
  x?.a?.b();
}
''');
  }

  test_canBeNullAfterNullAware_propertyAccess() async {
    resolveTestUnit('''
main(x) {
  x?.a().b;
}
''');
    await assertHasFix(
        DartFixKind.REPLACE_WITH_NULL_AWARE,
        '''
main(x) {
  x?.a()?.b;
}
''');
  }

  test_changeToStaticAccess_method() async {
    resolveTestUnit('''
class A {
  static foo() {}
}
main(A a) {
  a.foo();
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TO_STATIC_ACCESS,
        '''
class A {
  static foo() {}
}
main(A a) {
  A.foo();
}
''');
  }

  test_changeToStaticAccess_method_importType() async {
    addSource(
        '/libA.dart',
        r'''
library libA;
class A {
  static foo() {}
}
''');
    addSource(
        '/libB.dart',
        r'''
library libB;
import 'libA.dart';
class B extends A {}
''');
    resolveTestUnit('''
import 'libB.dart';
main(B b) {
  b.foo();
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TO_STATIC_ACCESS,
        '''
import 'libB.dart';
import 'libA.dart';
main(B b) {
  A.foo();
}
''');
  }

  test_changeToStaticAccess_method_prefixLibrary() async {
    resolveTestUnit('''
import 'dart:async' as pref;
main(pref.Future f) {
  f.wait([]);
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TO_STATIC_ACCESS,
        '''
import 'dart:async' as pref;
main(pref.Future f) {
  pref.Future.wait([]);
}
''');
  }

  test_changeToStaticAccess_property() async {
    resolveTestUnit('''
class A {
  static get foo => 42;
}
main(A a) {
  a.foo;
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TO_STATIC_ACCESS,
        '''
class A {
  static get foo => 42;
}
main(A a) {
  A.foo;
}
''');
  }

  test_changeToStaticAccess_property_importType() async {
    addSource(
        '/libA.dart',
        r'''
library libA;
class A {
  static get foo => null;
}
''');
    addSource(
        '/libB.dart',
        r'''
library libB;
import 'libA.dart';
class B extends A {}
''');
    resolveTestUnit('''
import 'libB.dart';
main(B b) {
  b.foo;
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TO_STATIC_ACCESS,
        '''
import 'libB.dart';
import 'libA.dart';
main(B b) {
  A.foo;
}
''');
  }

  test_changeTypeAnnotation_BAD_multipleVariables() async {
    resolveTestUnit('''
main() {
  String a, b = 42;
}
''');
    await assertNoFix(DartFixKind.CHANGE_TYPE_ANNOTATION);
  }

  test_changeTypeAnnotation_BAD_notVariableDeclaration() async {
    resolveTestUnit('''
main() {
  String v;
  v = 42;
}
''');
    await assertNoFix(DartFixKind.CHANGE_TYPE_ANNOTATION);
  }

  test_changeTypeAnnotation_OK_generic() async {
    resolveTestUnit('''
main() {
  String v = <int>[];
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TYPE_ANNOTATION,
        '''
main() {
  List<int> v = <int>[];
}
''');
  }

  test_changeTypeAnnotation_OK_simple() async {
    resolveTestUnit('''
main() {
  String v = 'abc'.length;
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TYPE_ANNOTATION,
        '''
main() {
  int v = 'abc'.length;
}
''');
  }

  test_createClass() async {
    resolveTestUnit('''
main() {
  Test v = null;
}
''');
    await assertHasFix(
        DartFixKind.CREATE_CLASS,
        '''
main() {
  Test v = null;
}

class Test {
}
''');
    _assertLinkedGroup(change.linkedEditGroups[0], ['Test v =', 'Test {']);
  }

  test_createClass_BAD_hasUnresolvedPrefix() async {
    resolveTestUnit('''
main() {
  prefix.Test v = null;
}
''');
    await assertNoFix(DartFixKind.CREATE_CLASS);
  }

  test_createClass_inLibraryOfPrefix() async {
    String libCode = r'''
library my.lib;

class A {}
''';
    addSource('/lib.dart', libCode);
    resolveTestUnit('''
import 'lib.dart' as lib;

main() {
  lib.A a = null;
  lib.Test t = null;
}
''');
    AnalysisError error = _findErrorToFix();
    fix = await _assertHasFix(DartFixKind.CREATE_CLASS, error);
    change = fix.change;
    // apply to "lib.dart"
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = change.edits[0];
    expect(fileEdit.file, '/lib.dart');
    expect(
        SourceEdit.applySequence(libCode, fileEdit.edits),
        r'''
library my.lib;

class A {}

class Test {
}
''');
    expect(change.linkedEditGroups, isEmpty);
  }

  test_createClass_innerLocalFunction() async {
    resolveTestUnit('''
f() {
  g() {
    Test v = null;
  }
}
''');
    await assertHasFix(
        DartFixKind.CREATE_CLASS,
        '''
f() {
  g() {
    Test v = null;
  }
}

class Test {
}
''');
    _assertLinkedGroup(change.linkedEditGroups[0], ['Test v =', 'Test {']);
  }

  test_createClass_itemOfList() async {
    resolveTestUnit('''
main() {
  var a = [Test];
}
''');
    await assertHasFix(
        DartFixKind.CREATE_CLASS,
        '''
main() {
  var a = [Test];
}

class Test {
}
''');
    _assertLinkedGroup(change.linkedEditGroups[0], ['Test];', 'Test {']);
  }

  test_createClass_itemOfList_inAnnotation() async {
    errorFilter = (AnalysisError error) {
      return error.errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER;
    };
    resolveTestUnit('''
class MyAnnotation {
  const MyAnnotation(a, b);
}
@MyAnnotation(int, const [Test])
main() {}
''');
    await assertHasFix(
        DartFixKind.CREATE_CLASS,
        '''
class MyAnnotation {
  const MyAnnotation(a, b);
}
@MyAnnotation(int, const [Test])
main() {}

class Test {
}
''');
    _assertLinkedGroup(change.linkedEditGroups[0], ['Test])', 'Test {']);
  }

  test_createConstructor_forFinalFields() async {
    errorFilter = (AnalysisError error) {
      return error.message.contains("'a'");
    };
    resolveTestUnit('''
class Test {
  final int a;
  final int b = 2;
  final int c;
}
''');
    await assertHasFix(
        DartFixKind.CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS,
        '''
class Test {
  final int a;
  final int b = 2;
  final int c;

  Test(this.a, this.c);
}
''');
  }

  test_createConstructor_insteadOfSyntheticDefault() async {
    resolveTestUnit('''
class A {
  int field;

  method() {}
}
main() {
  new A(1, 2.0);
}
''');
    await assertHasFix(
        DartFixKind.CREATE_CONSTRUCTOR,
        '''
class A {
  int field;

  A(int i, double d) {
  }

  method() {}
}
main() {
  new A(1, 2.0);
}
''');
  }

  test_createConstructor_named() async {
    resolveTestUnit('''
class A {
  method() {}
}
main() {
  new A.named(1, 2.0);
}
''');
    await assertHasFix(
        DartFixKind.CREATE_CONSTRUCTOR,
        '''
class A {
  A.named(int i, double d) {
  }

  method() {}
}
main() {
  new A.named(1, 2.0);
}
''');
    _assertLinkedGroup(change.linkedEditGroups[0], ['named(int ', 'named(1']);
  }

  test_createConstructorForFinalFields_inTopLevelMethod() async {
    resolveTestUnit('''
main() {
  final int v;
}
''');
    await assertNoFix(DartFixKind.CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS);
  }

  test_createConstructorForFinalFields_topLevelField() async {
    resolveTestUnit('''
final int v;
''');
    await assertNoFix(DartFixKind.CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS);
  }

  test_createConstructorSuperExplicit() async {
    resolveTestUnit('''
class A {
  A(bool p1, int p2, double p3, String p4, {p5});
}
class B extends A {
  B() {}
}
''');
    await assertHasFix(
        DartFixKind.ADD_SUPER_CONSTRUCTOR_INVOCATION,
        '''
class A {
  A(bool p1, int p2, double p3, String p4, {p5});
}
class B extends A {
  B() : super(false, 0, 0.0, '') {}
}
''');
  }

  test_createConstructorSuperExplicit_hasInitializers() async {
    resolveTestUnit('''
class A {
  A(int p);
}
class B extends A {
  int field;
  B() : field = 42 {}
}
''');
    await assertHasFix(
        DartFixKind.ADD_SUPER_CONSTRUCTOR_INVOCATION,
        '''
class A {
  A(int p);
}
class B extends A {
  int field;
  B() : field = 42, super(0) {}
}
''');
  }

  test_createConstructorSuperExplicit_named() async {
    resolveTestUnit('''
class A {
  A.named(int p);
}
class B extends A {
  B() {}
}
''');
    await assertHasFix(
        DartFixKind.ADD_SUPER_CONSTRUCTOR_INVOCATION,
        '''
class A {
  A.named(int p);
}
class B extends A {
  B() : super.named(0) {}
}
''');
  }

  test_createConstructorSuperExplicit_named_private() async {
    resolveTestUnit('''
class A {
  A._named(int p);
}
class B extends A {
  B() {}
}
''');
    await assertNoFix(DartFixKind.ADD_SUPER_CONSTRUCTOR_INVOCATION);
  }

  test_createConstructorSuperExplicit_typeArgument() async {
    resolveTestUnit('''
class A<T> {
  A(T p);
}
class B extends A<int> {
  B();
}
''');
    await assertHasFix(
        DartFixKind.ADD_SUPER_CONSTRUCTOR_INVOCATION,
        '''
class A<T> {
  A(T p);
}
class B extends A<int> {
  B() : super(0);
}
''');
  }

  test_createConstructorSuperImplicit() async {
    resolveTestUnit('''
class A {
  A(p1, int p2, List<String> p3, [int p4]);
}
class B extends A {
  int existingField;

  void existingMethod() {}
}
''');
    await assertHasFix(
        DartFixKind.CREATE_CONSTRUCTOR_SUPER,
        '''
class A {
  A(p1, int p2, List<String> p3, [int p4]);
}
class B extends A {
  int existingField;

  B(p1, int p2, List<String> p3) : super(p1, p2, p3);

  void existingMethod() {}
}
''');
  }

  test_createConstructorSuperImplicit_fieldInitializer() async {
    resolveTestUnit('''
class A {
  int _field;
  A(this._field);
}
class B extends A {
  int existingField;

  void existingMethod() {}
}
''');
    await assertHasFix(
        DartFixKind.CREATE_CONSTRUCTOR_SUPER,
        '''
class A {
  int _field;
  A(this._field);
}
class B extends A {
  int existingField;

  B(int field) : super(field);

  void existingMethod() {}
}
''');
  }

  test_createConstructorSuperImplicit_importType() async {
    addSource(
        '/libA.dart',
        r'''
library libA;
class A {}
''');
    addSource(
        '/libB.dart',
        r'''
library libB;
import 'libA.dart';
class B {
  B(A a);
}
''');
    resolveTestUnit('''
import 'libB.dart';
class C extends B {
}
''');
    await assertHasFix(
        DartFixKind.CREATE_CONSTRUCTOR_SUPER,
        '''
import 'libB.dart';
import 'libA.dart';
class C extends B {
  C(A a) : super(a);
}
''');
  }

  test_createConstructorSuperImplicit_named() async {
    resolveTestUnit('''
class A {
  A.named(p1, int p2);
}
class B extends A {
  int existingField;

  void existingMethod() {}
}
''');
    await assertHasFix(
        DartFixKind.CREATE_CONSTRUCTOR_SUPER,
        '''
class A {
  A.named(p1, int p2);
}
class B extends A {
  int existingField;

  B.named(p1, int p2) : super.named(p1, p2);

  void existingMethod() {}
}
''');
  }

  test_createConstructorSuperImplicit_private() async {
    resolveTestUnit('''
class A {
  A._named(p);
}
class B extends A {
}
''');
    await assertNoFix(DartFixKind.CREATE_CONSTRUCTOR_SUPER);
  }

  test_createConstructorSuperImplicit_typeArgument() async {
    resolveTestUnit('''
class C<T> {
  final T x;
  C(this.x);
}
class D extends C<int> {
}''');
    await assertHasFix(
        DartFixKind.CREATE_CONSTRUCTOR_SUPER,
        '''
class C<T> {
  final T x;
  C(this.x);
}
class D extends C<int> {
  D(int x) : super(x);
}''');
  }

  test_createField_BAD_inEnum() async {
    resolveTestUnit('''
enum MyEnum {
  AAA, BBB
}
main() {
  MyEnum.foo;
}
''');
    await assertNoFix(DartFixKind.CREATE_FIELD);
  }

  test_createField_BAD_inSDK() async {
    resolveTestUnit('''
main(List p) {
  p.foo = 1;
}
''');
    await assertNoFix(DartFixKind.CREATE_FIELD);
  }

  test_createField_getter_multiLevel() async {
    resolveTestUnit('''
class A {
}
class B {
  A a;
}
class C {
  B b;
}
main(C c) {
  int v = c.b.a.test;
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FIELD,
        '''
class A {
  int test;
}
class B {
  A a;
}
class C {
  B b;
}
main(C c) {
  int v = c.b.a.test;
}
''');
  }

  test_createField_getter_qualified_instance() async {
    resolveTestUnit('''
class A {
}
main(A a) {
  int v = a.test;
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FIELD,
        '''
class A {
  int test;
}
main(A a) {
  int v = a.test;
}
''');
  }

  test_createField_getter_qualified_instance_dynamicType() async {
    resolveTestUnit('''
class A {
  B b;
  void f(Object p) {
    p == b.test;
  }
}
class B {
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FIELD,
        '''
class A {
  B b;
  void f(Object p) {
    p == b.test;
  }
}
class B {
  var test;
}
''');
  }

  test_createField_getter_unqualified_instance_asInvocationArgument() async {
    resolveTestUnit('''
class A {
  main() {
    f(test);
  }
}
f(String s) {}
''');
    await assertHasFix(
        DartFixKind.CREATE_FIELD,
        '''
class A {
  String test;

  main() {
    f(test);
  }
}
f(String s) {}
''');
  }

  test_createField_getter_unqualified_instance_assignmentRhs() async {
    resolveTestUnit('''
class A {
  main() {
    int v = test;
  }
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FIELD,
        '''
class A {
  int test;

  main() {
    int v = test;
  }
}
''');
  }

  test_createField_getter_unqualified_instance_asStatement() async {
    resolveTestUnit('''
class A {
  main() {
    test;
  }
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FIELD,
        '''
class A {
  var test;

  main() {
    test;
  }
}
''');
  }

  test_createField_hint() async {
    resolveTestUnit('''
class A {
}
main(A a) {
  var x = a;
  int v = x.test;
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FIELD,
        '''
class A {
  int test;
}
main(A a) {
  var x = a;
  int v = x.test;
}
''');
  }

  test_createField_hint_setter() async {
    resolveTestUnit('''
class A {
}
main(A a) {
  var x = a;
  x.test = 0;
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FIELD,
        '''
class A {
  int test;
}
main(A a) {
  var x = a;
  x.test = 0;
}
''');
  }

  test_createField_importType() async {
    addSource(
        '/libA.dart',
        r'''
library libA;
class A {}
''');
    addSource(
        '/libB.dart',
        r'''
library libB;
import 'libA.dart';
A getA() => null;
''');
    resolveTestUnit('''
import 'libB.dart';
class C {
}
main(C c) {
  c.test = getA();
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FIELD,
        '''
import 'libB.dart';
import 'libA.dart';
class C {
  A test;
}
main(C c) {
  c.test = getA();
}
''');
  }

  test_createField_setter_generic_BAD() async {
    resolveTestUnit('''
class A {
}
class B<T> {
  List<T> items;
  main(A a) {
    a.test = items;
  }
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FIELD,
        '''
class A {
  List test;
}
class B<T> {
  List<T> items;
  main(A a) {
    a.test = items;
  }
}
''');
  }

  test_createField_setter_generic_OK_local() async {
    resolveTestUnit('''
class A<T> {
  List<T> items;

  main(A a) {
    test = items;
  }
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FIELD,
        '''
class A<T> {
  List<T> items;

  List<T> test;

  main(A a) {
    test = items;
  }
}
''');
  }

  test_createField_setter_qualified_instance_hasField() async {
    resolveTestUnit('''
class A {
  int aaa;
  int zzz;

  existingMethod() {}
}
main(A a) {
  a.test = 5;
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FIELD,
        '''
class A {
  int aaa;
  int zzz;

  int test;

  existingMethod() {}
}
main(A a) {
  a.test = 5;
}
''');
  }

  test_createField_setter_qualified_instance_hasMethod() async {
    resolveTestUnit('''
class A {
  existingMethod() {}
}
main(A a) {
  a.test = 5;
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FIELD,
        '''
class A {
  int test;

  existingMethod() {}
}
main(A a) {
  a.test = 5;
}
''');
  }

  test_createField_setter_qualified_static() async {
    resolveTestUnit('''
class A {
}
main() {
  A.test = 5;
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FIELD,
        '''
class A {
  static int test;
}
main() {
  A.test = 5;
}
''');
  }

  test_createField_setter_unqualified_instance() async {
    resolveTestUnit('''
class A {
  main() {
    test = 5;
  }
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FIELD,
        '''
class A {
  int test;

  main() {
    test = 5;
  }
}
''');
  }

  test_createField_setter_unqualified_static() async {
    resolveTestUnit('''
class A {
  static main() {
    test = 5;
  }
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FIELD,
        '''
class A {
  static int test;

  static main() {
    test = 5;
  }
}
''');
  }

  test_createFile_forImport() async {
    testFile = '/my/project/bin/test.dart';
    resolveTestUnit('''
import 'my_file.dart';
''');
    AnalysisError error = _findErrorToFix();
    fix = await _assertHasFix(DartFixKind.CREATE_FILE, error);
    change = fix.change;
    // validate change
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = change.edits[0];
    expect(fileEdit.file, '/my/project/bin/my_file.dart');
    expect(fileEdit.fileStamp, -1);
    expect(fileEdit.edits, hasLength(1));
    expect(fileEdit.edits[0].replacement, contains('library my_file;'));
  }

  test_createFile_forImport_BAD_inPackage_lib_justLib() async {
    provider.newFile('/projects/my_package/pubspec.yaml', 'name: my_package');
    testFile = '/projects/my_package/test.dart';
    resolveTestUnit('''
import 'lib';
''');
    await assertNoFix(DartFixKind.CREATE_FILE);
  }

  test_createFile_forImport_BAD_notDart() async {
    testFile = '/my/project/bin/test.dart';
    resolveTestUnit('''
import 'my_file.txt';
''');
    await assertNoFix(DartFixKind.CREATE_FILE);
  }

  test_createFile_forImport_inPackage_lib() async {
    provider.newFile('/projects/my_package/pubspec.yaml', 'name: my_package');
    testFile = '/projects/my_package/lib/test.dart';
    provider.newFolder('/projects/my_package/lib');
    resolveTestUnit('''
import 'a/bb/c_cc/my_lib.dart';
''');
    AnalysisError error = _findErrorToFix();
    fix = await _assertHasFix(DartFixKind.CREATE_FILE, error);
    change = fix.change;
    // validate change
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = change.edits[0];
    expect(fileEdit.file, '/projects/my_package/lib/a/bb/c_cc/my_lib.dart');
    expect(fileEdit.fileStamp, -1);
    expect(fileEdit.edits, hasLength(1));
    expect(fileEdit.edits[0].replacement,
        contains('library my_package.a.bb.c_cc.my_lib;'));
  }

  test_createFile_forImport_inPackage_test() async {
    provider.newFile('/projects/my_package/pubspec.yaml', 'name: my_package');
    testFile = '/projects/my_package/test/misc/test_all.dart';
    resolveTestUnit('''
import 'a/bb/my_lib.dart';
''');
    AnalysisError error = _findErrorToFix();
    fix = await _assertHasFix(DartFixKind.CREATE_FILE, error);
    change = fix.change;
    // validate change
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = change.edits[0];
    expect(fileEdit.file, '/projects/my_package/test/misc/a/bb/my_lib.dart');
    expect(fileEdit.fileStamp, -1);
    expect(fileEdit.edits, hasLength(1));
    expect(fileEdit.edits[0].replacement,
        contains('library my_package.test.misc.a.bb.my_lib;'));
  }

  test_createFile_forPart() async {
    testFile = '/my/project/bin/test.dart';
    resolveTestUnit('''
library my.lib;
part 'my_part.dart';
''');
    AnalysisError error = _findErrorToFix();
    fix = await _assertHasFix(DartFixKind.CREATE_FILE, error);
    change = fix.change;
    // validate change
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = change.edits[0];
    expect(fileEdit.file, '/my/project/bin/my_part.dart');
    expect(fileEdit.fileStamp, -1);
    expect(fileEdit.edits, hasLength(1));
    expect(fileEdit.edits[0].replacement, contains('part of my.lib;'));
  }

  test_createFile_forPart_inPackageLib() async {
    provider.newFile(
        '/my/pubspec.yaml',
        r'''
name: my_test
''');
    testFile = '/my/lib/test.dart';
    addTestSource(
        '''
library my.lib;
part 'my_part.dart';
''',
        Uri.parse('package:my/test.dart'));
    // configure SourceFactory
    UriResolver pkgResolver = new PackageMapUriResolver(provider, {
      'my': [provider.getResource('/my/lib')],
    });
    context.sourceFactory = new SourceFactory(
        [AbstractContextTest.SDK_RESOLVER, pkgResolver, resourceResolver]);
    // prepare fix
    testUnit = resolveLibraryUnit(testSource);
    AnalysisError error = _findErrorToFix();
    fix = await _assertHasFix(DartFixKind.CREATE_FILE, error);
    change = fix.change;
    // validate change
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = change.edits[0];
    expect(fileEdit.file, '/my/lib/my_part.dart');
    expect(fileEdit.fileStamp, -1);
    expect(fileEdit.edits, hasLength(1));
    expect(fileEdit.edits[0].replacement, contains('part of my.lib;'));
  }

  test_createGetter_BAD_inSDK() async {
    resolveTestUnit('''
main(List p) {
  int v = p.foo;
}
''');
    await assertNoFix(DartFixKind.CREATE_GETTER);
  }

  test_createGetter_hint_getter() async {
    resolveTestUnit('''
class A {
}
main(A a) {
  var x = a;
  int v = x.test;
}
''');
    await assertHasFix(
        DartFixKind.CREATE_GETTER,
        '''
class A {
  int get test => null;
}
main(A a) {
  var x = a;
  int v = x.test;
}
''');
  }

  test_createGetter_location_afterLastGetter() async {
    resolveTestUnit('''
class A {
  int existingField;

  int get existingGetter => null;

  existingMethod() {}
}
main(A a) {
  int v = a.test;
}
''');
    await assertHasFix(
        DartFixKind.CREATE_GETTER,
        '''
class A {
  int existingField;

  int get existingGetter => null;

  int get test => null;

  existingMethod() {}
}
main(A a) {
  int v = a.test;
}
''');
  }

  test_createGetter_multiLevel() async {
    resolveTestUnit('''
class A {
}
class B {
  A a;
}
class C {
  B b;
}
main(C c) {
  int v = c.b.a.test;
}
''');
    await assertHasFix(
        DartFixKind.CREATE_GETTER,
        '''
class A {
  int get test => null;
}
class B {
  A a;
}
class C {
  B b;
}
main(C c) {
  int v = c.b.a.test;
}
''');
  }

  test_createGetter_qualified_instance() async {
    resolveTestUnit('''
class A {
}
main(A a) {
  int v = a.test;
}
''');
    await assertHasFix(
        DartFixKind.CREATE_GETTER,
        '''
class A {
  int get test => null;
}
main(A a) {
  int v = a.test;
}
''');
  }

  test_createGetter_qualified_instance_dynamicType() async {
    resolveTestUnit('''
class A {
  B b;
  void f(Object p) {
    p == b.test;
  }
}
class B {
}
''');
    await assertHasFix(
        DartFixKind.CREATE_GETTER,
        '''
class A {
  B b;
  void f(Object p) {
    p == b.test;
  }
}
class B {
  get test => null;
}
''');
  }

  test_createGetter_setterContext() async {
    resolveTestUnit('''
class A {
}
main(A a) {
  a.test = 42;
}
''');
    await assertNoFix(DartFixKind.CREATE_GETTER);
  }

  test_createGetter_unqualified_instance_asInvocationArgument() async {
    resolveTestUnit('''
class A {
  main() {
    f(test);
  }
}
f(String s) {}
''');
    await assertHasFix(
        DartFixKind.CREATE_GETTER,
        '''
class A {
  String get test => null;

  main() {
    f(test);
  }
}
f(String s) {}
''');
  }

  test_createGetter_unqualified_instance_assignmentLhs() async {
    resolveTestUnit('''
class A {
  main() {
    test = 42;
  }
}
''');
    await assertNoFix(DartFixKind.CREATE_GETTER);
  }

  test_createGetter_unqualified_instance_assignmentRhs() async {
    resolveTestUnit('''
class A {
  main() {
    int v = test;
  }
}
''');
    await assertHasFix(
        DartFixKind.CREATE_GETTER,
        '''
class A {
  int get test => null;

  main() {
    int v = test;
  }
}
''');
  }

  test_createGetter_unqualified_instance_asStatement() async {
    resolveTestUnit('''
class A {
  main() {
    test;
  }
}
''');
    await assertHasFix(
        DartFixKind.CREATE_GETTER,
        '''
class A {
  get test => null;

  main() {
    test;
  }
}
''');
  }

  test_createLocalVariable_functionType_named() async {
    resolveTestUnit('''
typedef MY_FUNCTION(int p);
foo(MY_FUNCTION f) {}
main() {
  foo(bar);
}
''');
    await assertHasFix(
        DartFixKind.CREATE_LOCAL_VARIABLE,
        '''
typedef MY_FUNCTION(int p);
foo(MY_FUNCTION f) {}
main() {
  MY_FUNCTION bar;
  foo(bar);
}
''');
  }

  test_createLocalVariable_functionType_synthetic() async {
    resolveTestUnit('''
foo(f(int p)) {}
main() {
  foo(bar);
}
''');
    await assertNoFix(DartFixKind.CREATE_LOCAL_VARIABLE);
  }

  test_createLocalVariable_read_typeAssignment() async {
    resolveTestUnit('''
main() {
  int a = test;
}
''');
    await assertHasFix(
        DartFixKind.CREATE_LOCAL_VARIABLE,
        '''
main() {
  int test;
  int a = test;
}
''');
  }

  test_createLocalVariable_read_typeCondition() async {
    resolveTestUnit('''
main() {
  if (!test) {
    print(42);
  }
}
''');
    await assertHasFix(
        DartFixKind.CREATE_LOCAL_VARIABLE,
        '''
main() {
  bool test;
  if (!test) {
    print(42);
  }
}
''');
  }

  test_createLocalVariable_read_typeInvocationArgument() async {
    resolveTestUnit('''
main() {
  f(test);
}
f(String p) {}
''');
    await assertHasFix(
        DartFixKind.CREATE_LOCAL_VARIABLE,
        '''
main() {
  String test;
  f(test);
}
f(String p) {}
''');
    _assertLinkedGroup(change.linkedEditGroups[0], ['String test;']);
    _assertLinkedGroup(change.linkedEditGroups[1], ['test;', 'test);']);
  }

  test_createLocalVariable_read_typeInvocationTarget() async {
    resolveTestUnit('''
main() {
  test.add('hello');
}
''');
    await assertHasFix(
        DartFixKind.CREATE_LOCAL_VARIABLE,
        '''
main() {
  var test;
  test.add('hello');
}
''');
    _assertLinkedGroup(change.linkedEditGroups[0], ['test;', 'test.add(']);
  }

  test_createLocalVariable_write_assignment() async {
    resolveTestUnit('''
main() {
  test = 42;
}
''');
    await assertHasFix(
        DartFixKind.CREATE_LOCAL_VARIABLE,
        '''
main() {
  var test = 42;
}
''');
  }

  test_createLocalVariable_write_assignment_compound() async {
    resolveTestUnit('''
main() {
  test += 42;
}
''');
    await assertHasFix(
        DartFixKind.CREATE_LOCAL_VARIABLE,
        '''
main() {
  int test;
  test += 42;
}
''');
  }

  test_createMissingOverrides_field_untyped() async {
    resolveTestUnit('''
class A {
  var f;
}

class B implements A {
}
''');
    await assertHasFix(
        DartFixKind.CREATE_MISSING_OVERRIDES,
        '''
class A {
  var f;
}

class B implements A {
  @override
  var f;
}
''');
  }

  test_createMissingOverrides_functionTypeAlias() async {
    resolveTestUnit('''
typedef int Binary(int left, int right);

abstract class Emulator {
  void performBinary(Binary binary);
}

class MyEmulator extends Emulator {
}
''');
    await assertHasFix(
        DartFixKind.CREATE_MISSING_OVERRIDES,
        '''
typedef int Binary(int left, int right);

abstract class Emulator {
  void performBinary(Binary binary);
}

class MyEmulator extends Emulator {
  @override
  void performBinary(Binary binary) {
    // TODO: implement performBinary
  }
}
''');
  }

  test_createMissingOverrides_functionTypedParameter() async {
    resolveTestUnit('''
abstract class A {
  forEach(int f(double p1, String p2));
}

class B extends A {
}
''');
    await assertHasFix(
        DartFixKind.CREATE_MISSING_OVERRIDES,
        '''
abstract class A {
  forEach(int f(double p1, String p2));
}

class B extends A {
  @override
  forEach(int f(double p1, String p2)) {
    // TODO: implement forEach
  }
}
''');
  }

  test_createMissingOverrides_generics_typeArguments() async {
    resolveTestUnit('''
class Iterator<T> {
}

abstract class IterableMixin<T> {
  Iterator<T> get iterator;
}

class Test extends IterableMixin<int> {
}
''');
    await assertHasFix(
        DartFixKind.CREATE_MISSING_OVERRIDES,
        '''
class Iterator<T> {
}

abstract class IterableMixin<T> {
  Iterator<T> get iterator;
}

class Test extends IterableMixin<int> {
  // TODO: implement iterator
  @override
  Iterator<int> get iterator => null;
}
''');
  }

  test_createMissingOverrides_generics_typeParameters() async {
    resolveTestUnit('''
abstract class ItemProvider<T> {
  List<T> getItems();
}

class Test<V> extends ItemProvider<V> {
}
''');
    await assertHasFix(
        DartFixKind.CREATE_MISSING_OVERRIDES,
        '''
abstract class ItemProvider<T> {
  List<T> getItems();
}

class Test<V> extends ItemProvider<V> {
  @override
  List<V> getItems() {
    // TODO: implement getItems
  }
}
''');
  }

  test_createMissingOverrides_getter() async {
    resolveTestUnit('''
abstract class A {
  get g1;
  int get g2;
}

class B extends A {
}
''');
    await assertHasFix(
        DartFixKind.CREATE_MISSING_OVERRIDES,
        '''
abstract class A {
  get g1;
  int get g2;
}

class B extends A {
  // TODO: implement g1
  @override
  get g1 => null;

  // TODO: implement g2
  @override
  int get g2 => null;
}
''');
  }

  test_createMissingOverrides_importPrefix() async {
    resolveTestUnit('''
import 'dart:async' as aaa;
abstract class A {
  Map<aaa.Future, List<aaa.Future>> g(aaa.Future p);
}

class B extends A {
}
''');
    await assertHasFix(
        DartFixKind.CREATE_MISSING_OVERRIDES,
        '''
import 'dart:async' as aaa;
abstract class A {
  Map<aaa.Future, List<aaa.Future>> g(aaa.Future p);
}

class B extends A {
  @override
  Map<aaa.Future, List<aaa.Future>> g(aaa.Future p) {
    // TODO: implement g
  }
}
''');
  }

  test_createMissingOverrides_mergeToField_getterSetter() async {
    resolveTestUnit('''
class A {
  int ma;
  void mb() {}
  double mc;
}

class B implements A {
}
''');
    await assertHasFix(
        DartFixKind.CREATE_MISSING_OVERRIDES,
        '''
class A {
  int ma;
  void mb() {}
  double mc;
}

class B implements A {
  @override
  int ma;

  @override
  double mc;

  @override
  void mb() {
    // TODO: implement mb
  }
}
''');
  }

  test_createMissingOverrides_method() async {
    resolveTestUnit('''
abstract class A {
  m1();
  int m2();
  String m3(int p1, double p2, Map<int, List<String>> p3);
  String m4(p1, p2);
  String m5(p1, [int p2 = 2, int p3, p4 = 4]);
  String m6(p1, {int p2: 2, int p3, p4: 4});
}

class B extends A {
}
''');
    String expectedCode = '''
abstract class A {
  m1();
  int m2();
  String m3(int p1, double p2, Map<int, List<String>> p3);
  String m4(p1, p2);
  String m5(p1, [int p2 = 2, int p3, p4 = 4]);
  String m6(p1, {int p2: 2, int p3, p4: 4});
}

class B extends A {
  @override
  m1() {
    // TODO: implement m1
  }

  @override
  int m2() {
    // TODO: implement m2
  }

  @override
  String m3(int p1, double p2, Map<int, List<String>> p3) {
    // TODO: implement m3
  }

  @override
  String m4(p1, p2) {
    // TODO: implement m4
  }

  @override
  String m5(p1, [int p2 = 2, int p3, p4 = 4]) {
    // TODO: implement m5
  }

  @override
  String m6(p1, {int p2: 2, int p3, p4: 4}) {
    // TODO: implement m6
  }
}
''';
    await assertHasFix(DartFixKind.CREATE_MISSING_OVERRIDES, expectedCode);
    // end position should be on "m1", not on "m2", "m3", etc
    {
      Position endPosition = change.selection;
      expect(endPosition, isNotNull);
      expect(endPosition.file, testFile);
      int endOffset = endPosition.offset;
      String endString = expectedCode.substring(endOffset, endOffset + 25);
      expect(endString, contains('m1'));
      expect(endString, isNot(contains('m2')));
      expect(endString, isNot(contains('m3')));
      expect(endString, isNot(contains('m4')));
      expect(endString, isNot(contains('m5')));
      expect(endString, isNot(contains('m6')));
    }
  }

  test_createMissingOverrides_operator() async {
    resolveTestUnit('''
abstract class A {
  int operator [](int index);
  void operator []=(int index, String value);
}

class B extends A {
}
''');
    await assertHasFix(
        DartFixKind.CREATE_MISSING_OVERRIDES,
        '''
abstract class A {
  int operator [](int index);
  void operator []=(int index, String value);
}

class B extends A {
  @override
  int operator [](int index) {
    // TODO: implement []
  }

  @override
  void operator []=(int index, String value) {
    // TODO: implement []=
  }
}
''');
  }

  test_createMissingOverrides_setter() async {
    resolveTestUnit('''
abstract class A {
  set s1(x);
  set s2(int x);
  void set s3(String x);
}

class B extends A {
}
''');
    await assertHasFix(
        DartFixKind.CREATE_MISSING_OVERRIDES,
        '''
abstract class A {
  set s1(x);
  set s2(int x);
  void set s3(String x);
}

class B extends A {
  @override
  set s1(x) {
    // TODO: implement s1
  }

  @override
  set s2(int x) {
    // TODO: implement s2
  }

  @override
  void set s3(String x) {
    // TODO: implement s3
  }
}
''');
  }

  test_createNoSuchMethod() async {
    resolveTestUnit('''
abstract class A {
  m1();
  int m2();
}

class B extends A {
  existing() {}
}
''');
    await assertHasFix(
        DartFixKind.CREATE_NO_SUCH_METHOD,
        '''
abstract class A {
  m1();
  int m2();
}

class B extends A {
  existing() {}

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
''');
  }

  test_creationFunction_forFunctionType_cascadeSecond() async {
    resolveTestUnit('''
class A {
  B ma() => null;
}
class B {
  useFunction(int g(double a, String b)) {}
}

main() {
  A a = new A();
  a..ma().useFunction(test);
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
class A {
  B ma() => null;
}
class B {
  useFunction(int g(double a, String b)) {}
}

main() {
  A a = new A();
  a..ma().useFunction(test);
}

int test(double a, String b) {
}
''');
  }

  test_creationFunction_forFunctionType_coreFunction() async {
    resolveTestUnit('''
main() {
  useFunction(g: test);
}
useFunction({Function g}) {}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
main() {
  useFunction(g: test);
}
useFunction({Function g}) {}

test() {
}
''');
  }

  test_creationFunction_forFunctionType_dynamicArgument() async {
    resolveTestUnit('''
main() {
  useFunction(test);
}
useFunction(int g(a, b)) {}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
main() {
  useFunction(test);
}
useFunction(int g(a, b)) {}

int test(a, b) {
}
''');
  }

  test_creationFunction_forFunctionType_function() async {
    resolveTestUnit('''
main() {
  useFunction(test);
}
useFunction(int g(double a, String b)) {}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
main() {
  useFunction(test);
}
useFunction(int g(double a, String b)) {}

int test(double a, String b) {
}
''');
  }

  test_creationFunction_forFunctionType_function_namedArgument() async {
    resolveTestUnit('''
main() {
  useFunction(g: test);
}
useFunction({int g(double a, String b)}) {}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
main() {
  useFunction(g: test);
}
useFunction({int g(double a, String b)}) {}

int test(double a, String b) {
}
''');
  }

  test_creationFunction_forFunctionType_importType() async {
    addSource(
        '/libA.dart',
        r'''
library libA;
class A {}
''');
    addSource(
        '/libB.dart',
        r'''
library libB;
import 'libA.dart';
useFunction(int g(A a)) {}
''');
    resolveTestUnit('''
import 'libB.dart';
main() {
  useFunction(test);
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
import 'libB.dart';
import 'libA.dart';
main() {
  useFunction(test);
}

int test(A a) {
}
''');
  }

  test_creationFunction_forFunctionType_method_enclosingClass_static() async {
    resolveTestUnit('''
class A {
  static foo() {
    useFunction(test);
  }
}
useFunction(int g(double a, String b)) {}
''');
    await assertHasFix(
        DartFixKind.CREATE_METHOD,
        '''
class A {
  static foo() {
    useFunction(test);
  }

  static int test(double a, String b) {
  }
}
useFunction(int g(double a, String b)) {}
''');
  }

  test_creationFunction_forFunctionType_method_enclosingClass_static2() async {
    resolveTestUnit('''
class A {
  var f;
  A() : f = useFunction(test);
}
useFunction(int g(double a, String b)) {}
''');
    await assertHasFix(
        DartFixKind.CREATE_METHOD,
        '''
class A {
  var f;
  A() : f = useFunction(test);

  static int test(double a, String b) {
  }
}
useFunction(int g(double a, String b)) {}
''');
  }

  test_creationFunction_forFunctionType_method_targetClass() async {
    resolveTestUnit('''
main(A a) {
  useFunction(a.test);
}
class A {
}
useFunction(int g(double a, String b)) {}
''');
    await assertHasFix(
        DartFixKind.CREATE_METHOD,
        '''
main(A a) {
  useFunction(a.test);
}
class A {
  int test(double a, String b) {
  }
}
useFunction(int g(double a, String b)) {}
''');
  }

  test_creationFunction_forFunctionType_method_targetClass_hasOtherMember() async {
    resolveTestUnit('''
main(A a) {
  useFunction(a.test);
}
class A {
  m() {}
}
useFunction(int g(double a, String b)) {}
''');
    await assertHasFix(
        DartFixKind.CREATE_METHOD,
        '''
main(A a) {
  useFunction(a.test);
}
class A {
  m() {}

  int test(double a, String b) {
  }
}
useFunction(int g(double a, String b)) {}
''');
  }

  test_creationFunction_forFunctionType_notFunctionType() async {
    resolveTestUnit('''
main(A a) {
  useFunction(a.test);
}
typedef A();
useFunction(g) {}
''');
    await assertNoFix(DartFixKind.CREATE_METHOD);
    await assertNoFix(DartFixKind.CREATE_FUNCTION);
  }

  test_creationFunction_forFunctionType_unknownTarget() async {
    resolveTestUnit('''
main(A a) {
  useFunction(a.test);
}
class A {
}
useFunction(g) {}
''');
    await assertNoFix(DartFixKind.CREATE_METHOD);
  }

  test_expectedToken_semicolon() async {
    resolveTestUnit('''
main() {
  print(0)
}
''');
    await assertHasFix(
        DartFixKind.INSERT_SEMICOLON,
        '''
main() {
  print(0);
}
''');
  }

  test_illegalAsyncReturnType_adjacentNodes() async {
    errorFilter = (AnalysisError error) {
      return error.errorCode == StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE;
    };
    resolveTestUnit('''
import 'dart:async';
var v;int main() async => 0;
''');
    await assertHasFix(
        DartFixKind.REPLACE_RETURN_TYPE_FUTURE,
        '''
import 'dart:async';
var v;Future<int> main() async => 0;
''');
  }

  test_illegalAsyncReturnType_asyncLibrary_import() async {
    errorFilter = (AnalysisError error) {
      return error.errorCode == StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE;
    };
    resolveTestUnit('''
library main;
int main() async {
}
''');
    await assertHasFix(
        DartFixKind.REPLACE_RETURN_TYPE_FUTURE,
        '''
library main;
import 'dart:async';
Future<int> main() async {
}
''');
  }

  test_illegalAsyncReturnType_asyncLibrary_usePrefix() async {
    errorFilter = (AnalysisError error) {
      return error.errorCode == StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE;
    };
    resolveTestUnit('''
import 'dart:async' as al;
int main() async {
}
''');
    await assertHasFix(
        DartFixKind.REPLACE_RETURN_TYPE_FUTURE,
        '''
import 'dart:async' as al;
al.Future<int> main() async {
}
''');
  }

  test_illegalAsyncReturnType_complexTypeName() async {
    errorFilter = (AnalysisError error) {
      return error.errorCode == StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE;
    };
    resolveTestUnit('''
import 'dart:async';
List<int> main() async {
}
''');
    await assertHasFix(
        DartFixKind.REPLACE_RETURN_TYPE_FUTURE,
        '''
import 'dart:async';
Future<List<int>> main() async {
}
''');
  }

  test_illegalAsyncReturnType_void() async {
    errorFilter = (AnalysisError error) {
      return error.errorCode == StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE;
    };
    resolveTestUnit('''
import 'dart:async';
void main() async {
}
''');
    await assertHasFix(
        DartFixKind.REPLACE_RETURN_TYPE_FUTURE,
        '''
import 'dart:async';
Future main() async {
}
''');
  }

  test_importLibraryPackage_withClass() async {
    _configureMyPkg('''
library my_lib;
class Test {}
''');
    // try to find a fix
    resolveTestUnit('''
main() {
  Test test = null;
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT,
        '''
import 'package:my_pkg/my_lib.dart';

main() {
  Test test = null;
}
''');
  }

  test_importLibraryProject_withClass_annotation() async {
    addSource(
        '/lib.dart',
        '''
library lib;
class Test {
  const Test(int p);
}
''');
    resolveTestUnit('''
@Test(0)
main() {
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT,
        '''
import 'lib.dart';

@Test(0)
main() {
}
''');
  }

  test_importLibraryProject_withClass_hasOtherLibraryWithPrefix() async {
    testFile = '/project/bin/test.dart';
    addSource(
        '/project/bin/a.dart',
        '''
library a;
class One {}
''');
    addSource(
        '/project/bin/b.dart',
        '''
library b;
class One {}
class Two {}
''');
    resolveTestUnit('''
import 'b.dart' show Two;
main () {
  new Two();
  new One();
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT,
        '''
import 'b.dart' show Two;
import 'a.dart';
main () {
  new Two();
  new One();
}
''');
  }

  test_importLibraryProject_withClass_inParentFolder() async {
    testFile = '/project/bin/test.dart';
    addSource(
        '/project/lib.dart',
        '''
library lib;
class Test {}
''');
    resolveTestUnit('''
main() {
  Test t = null;
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT,
        '''
import '../lib.dart';

main() {
  Test t = null;
}
''');
  }

  test_importLibraryProject_withClass_inRelativeFolder() async {
    testFile = '/project/bin/test.dart';
    addSource(
        '/project/lib/sub/folder/lib.dart',
        '''
library lib;
class Test {}
''');
    resolveTestUnit('''
main() {
  Test t = null;
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT,
        '''
import '../lib/sub/folder/lib.dart';

main() {
  Test t = null;
}
''');
  }

  test_importLibraryProject_withClass_inSameFolder() async {
    testFile = '/project/bin/test.dart';
    addSource(
        '/project/bin/lib.dart',
        '''
library lib;
class Test {}
''');
    resolveTestUnit('''
main() {
  Test t = null;
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT,
        '''
import 'lib.dart';

main() {
  Test t = null;
}
''');
  }

  test_importLibraryProject_withFunction() async {
    addSource(
        '/lib.dart',
        '''
library lib;
myFunction() {}
''');
    resolveTestUnit('''
main() {
  myFunction();
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT,
        '''
import 'lib.dart';

main() {
  myFunction();
}
''');
  }

  test_importLibraryProject_withFunction_unresolvedMethod() async {
    addSource(
        '/lib.dart',
        '''
library lib;
myFunction() {}
''');
    resolveTestUnit('''
class A {
  main() {
    myFunction();
  }
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT,
        '''
import 'lib.dart';

class A {
  main() {
    myFunction();
  }
}
''');
  }

  test_importLibraryProject_withFunctionTypeAlias() async {
    testFile = '/project/bin/test.dart';
    addSource(
        '/project/bin/lib.dart',
        '''
library lib;
typedef MyFunction();
''');
    resolveTestUnit('''
main() {
  MyFunction t = null;
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT,
        '''
import 'lib.dart';

main() {
  MyFunction t = null;
}
''');
  }

  test_importLibraryProject_withTopLevelVariable() async {
    addSource(
        '/lib.dart',
        '''
library lib;
int MY_VAR = 42;
''');
    resolveTestUnit('''
main() {
  print(MY_VAR);
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT,
        '''
import 'lib.dart';

main() {
  print(MY_VAR);
}
''');
  }

  test_importLibrarySdk_withClass_AsExpression() async {
    resolveTestUnit('''
main(p) {
  p as Future;
}
''');
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_SDK,
        '''
import 'dart:async';

main(p) {
  p as Future;
}
''');
  }

  test_importLibrarySdk_withClass_invocationTarget() async {
    resolveTestUnit('''
main() {
  Future.wait(null);
}
''');
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_SDK,
        '''
import 'dart:async';

main() {
  Future.wait(null);
}
''');
  }

  test_importLibrarySdk_withClass_IsExpression() async {
    resolveTestUnit('''
main(p) {
  p is Future;
}
''');
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_SDK,
        '''
import 'dart:async';

main(p) {
  p is Future;
}
''');
  }

  test_importLibrarySdk_withClass_itemOfList() async {
    resolveTestUnit('''
main() {
  var a = [Future];
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_SDK,
        '''
import 'dart:async';

main() {
  var a = [Future];
}
''');
  }

  test_importLibrarySdk_withClass_itemOfList_inAnnotation() async {
    errorFilter = (AnalysisError error) {
      return error.errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER;
    };
    resolveTestUnit('''
class MyAnnotation {
  const MyAnnotation(a, b);
}
@MyAnnotation(int, const [Future])
main() {}
''');
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_SDK,
        '''
import 'dart:async';

class MyAnnotation {
  const MyAnnotation(a, b);
}
@MyAnnotation(int, const [Future])
main() {}
''');
  }

  test_importLibrarySdk_withClass_typeAnnotation() async {
    resolveTestUnit('''
main() {
  Future f = null;
}
''');
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_SDK,
        '''
import 'dart:async';

main() {
  Future f = null;
}
''');
  }

  test_importLibrarySdk_withClass_typeAnnotation_PrefixedIdentifier() async {
    resolveTestUnit('''
main() {
  Future.wait;
}
''');
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_SDK,
        '''
import 'dart:async';

main() {
  Future.wait;
}
''');
  }

  test_importLibrarySdk_withClass_typeArgument() async {
    resolveTestUnit('''
main() {
  List<Future> futures = [];
}
''');
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_SDK,
        '''
import 'dart:async';

main() {
  List<Future> futures = [];
}
''');
  }

  test_importLibrarySdk_withTopLevelVariable() async {
    resolveTestUnit('''
main() {
  print(PI);
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_SDK,
        '''
import 'dart:math';

main() {
  print(PI);
}
''');
  }

  test_importLibrarySdk_withTopLevelVariable_annotation() async {
    resolveTestUnit('''
@PI
main() {
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_SDK,
        '''
import 'dart:math';

@PI
main() {
}
''');
  }

  test_importLibraryShow() async {
    resolveTestUnit('''
import 'dart:async' show Stream;
main() {
  Stream s = null;
  Future f = null;
}
''');
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_SHOW,
        '''
import 'dart:async' show Future, Stream;
main() {
  Stream s = null;
  Future f = null;
}
''');
  }

  test_isNotNull() async {
    resolveTestUnit('''
main(p) {
  p is! Null;
}
''');
    await assertHasFix(
        DartFixKind.USE_NOT_EQ_NULL,
        '''
main(p) {
  p != null;
}
''');
  }

  test_isNull() async {
    resolveTestUnit('''
main(p) {
  p is Null;
}
''');
    await assertHasFix(
        DartFixKind.USE_EQ_EQ_NULL,
        '''
main(p) {
  p == null;
}
''');
  }

  test_makeEnclosingClassAbstract_declaresAbstractMethod() async {
    resolveTestUnit('''
class A {
  m();
}
''');
    await assertHasFix(
        DartFixKind.MAKE_CLASS_ABSTRACT,
        '''
abstract class A {
  m();
}
''');
  }

  test_makeEnclosingClassAbstract_inheritsAbstractMethod() async {
    resolveTestUnit('''
abstract class A {
  m();
}
class B extends A {
}
''');
    await assertHasFix(
        DartFixKind.MAKE_CLASS_ABSTRACT,
        '''
abstract class A {
  m();
}
abstract class B extends A {
}
''');
  }

  test_makeFieldNotFinal_hasType() async {
    resolveTestUnit('''
class A {
  final int fff = 1;
  main() {
    fff = 2;
  }
}
''');
    await assertHasFix(
        DartFixKind.MAKE_FIELD_NOT_FINAL,
        '''
class A {
  int fff = 1;
  main() {
    fff = 2;
  }
}
''');
  }

  test_makeFieldNotFinal_noType() async {
    resolveTestUnit('''
class A {
  final fff = 1;
  main() {
    fff = 2;
  }
}
''');
    await assertHasFix(
        DartFixKind.MAKE_FIELD_NOT_FINAL,
        '''
class A {
  var fff = 1;
  main() {
    fff = 2;
  }
}
''');
  }

  test_noException_1() async {
    resolveTestUnit('''
main(p) {
  p i s Null;
}''');
    List<AnalysisError> errors = context.computeErrors(testSource);
    for (var error in errors) {
      await _computeFixes(error);
    }
  }

  test_nonBoolCondition_addNotNull() async {
    resolveTestUnit('''
main(String p) {
  if (p) {
    print(p);
  }
}
''');
    await assertHasFix(
        DartFixKind.ADD_NE_NULL,
        '''
main(String p) {
  if (p != null) {
    print(p);
  }
}
''');
  }

  test_removeDeadCode_condition() async {
    resolveTestUnit('''
main(int p) {
  if (true || p > 5) {
    print(1);
  }
}
''');
    await assertHasFix(
        DartFixKind.REMOVE_DEAD_CODE,
        '''
main(int p) {
  if (true) {
    print(1);
  }
}
''');
  }

  test_removeDeadCode_statements_one() async {
    resolveTestUnit('''
int main() {
  print(0);
  return 42;
  print(1);
}
''');
    await assertHasFix(
        DartFixKind.REMOVE_DEAD_CODE,
        '''
int main() {
  print(0);
  return 42;
}
''');
  }

  test_removeDeadCode_statements_two() async {
    resolveTestUnit('''
int main() {
  print(0);
  return 42;
  print(1);
  print(2);
}
''');
    await assertHasFix(
        DartFixKind.REMOVE_DEAD_CODE,
        '''
int main() {
  print(0);
  return 42;
}
''');
  }

  test_removeParentheses_inGetterDeclaration() async {
    resolveTestUnit('''
class A {
  int get foo() => 0;
}
''');
    await assertHasFix(
        DartFixKind.REMOVE_PARAMETERS_IN_GETTER_DECLARATION,
        '''
class A {
  int get foo => 0;
}
''');
  }

  test_removeParentheses_inGetterInvocation() async {
    resolveTestUnit('''
class A {
  int get foo => 0;
}
main(A a) {
  a.foo();
}
''');
    await assertHasFix(
        DartFixKind.REMOVE_PARENTHESIS_IN_GETTER_INVOCATION,
        '''
class A {
  int get foo => 0;
}
main(A a) {
  a.foo;
}
''');
  }

  test_removeUnnecessaryCast_assignment() async {
    resolveTestUnit('''
main(Object p) {
  if (p is String) {
    String v = ((p as String));
  }
}
''');
    await assertHasFix(
        DartFixKind.REMOVE_UNNECESSARY_CAST,
        '''
main(Object p) {
  if (p is String) {
    String v = p;
  }
}
''');
  }

  test_removeUnusedCatchClause() async {
    errorFilter = (AnalysisError error) => true;
    resolveTestUnit('''
main() {
  try {
    throw 42;
  } on int catch (e) {
  }
}
''');
    await assertHasFix(
        DartFixKind.REMOVE_UNUSED_CATCH_CLAUSE,
        '''
main() {
  try {
    throw 42;
  } on int {
  }
}
''');
  }

  test_removeUnusedCatchStack() async {
    errorFilter = (AnalysisError error) => true;
    resolveTestUnit('''
main() {
  try {
    throw 42;
  } catch (e, stack) {
  }
}
''');
    await assertHasFix(
        DartFixKind.REMOVE_UNUSED_CATCH_STACK,
        '''
main() {
  try {
    throw 42;
  } catch (e) {
  }
}
''');
  }

  test_removeUnusedImport() async {
    resolveTestUnit('''
import 'dart:math';
main() {
}
''');
    await assertHasFix(
        DartFixKind.REMOVE_UNUSED_IMPORT,
        '''
main() {
}
''');
  }

  test_removeUnusedImport_anotherImportOnLine() async {
    resolveTestUnit('''
import 'dart:math'; import 'dart:async';

main() {
  Future f;
}
''');
    await assertHasFix(
        DartFixKind.REMOVE_UNUSED_IMPORT,
        '''
import 'dart:async';

main() {
  Future f;
}
''');
  }

  test_removeUnusedImport_severalLines() async {
    resolveTestUnit('''
import
  'dart:math';
main() {
}
''');
    await assertHasFix(
        DartFixKind.REMOVE_UNUSED_IMPORT,
        '''
main() {
}
''');
  }

  test_replaceImportUri_inProject() async {
    testFile = '/project/bin/test.dart';
    addSource('/project/foo/bar/lib.dart', '');
    resolveTestUnit('''
import 'no/matter/lib.dart';
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.REPLACE_IMPORT_URI,
        '''
import '../foo/bar/lib.dart';
''');
  }

  test_replaceImportUri_package() async {
    _configureMyPkg('');
    resolveTestUnit('''
import 'no/matter/my_lib.dart';
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.REPLACE_IMPORT_URI,
        '''
import 'package:my_pkg/my_lib.dart';
''');
  }

  test_replaceVarWithDynamic() async {
    errorFilter = (AnalysisError error) {
      return error.errorCode == ParserErrorCode.VAR_AS_TYPE_NAME;
    };
    resolveTestUnit('''
class A {
  Map<String, var> m;
}
''');
    await assertHasFix(
        DartFixKind.REPLACE_VAR_WITH_DYNAMIC,
        '''
class A {
  Map<String, dynamic> m;
}
''');
  }

  test_replaceWithConstInstanceCreation() async {
    resolveTestUnit('''
class A {
  const A();
}
const a = new A();
''');
    await assertHasFix(
        DartFixKind.USE_CONST,
        '''
class A {
  const A();
}
const a = const A();
''');
  }

  test_undefinedClass_useSimilar_fromImport() async {
    resolveTestUnit('''
main() {
  Stirng s = 'abc';
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TO,
        '''
main() {
  String s = 'abc';
}
''');
  }

  test_undefinedClass_useSimilar_fromThisLibrary() async {
    resolveTestUnit('''
class MyClass {}
main() {
  MyCalss v = null;
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TO,
        '''
class MyClass {}
main() {
  MyClass v = null;
}
''');
  }

  test_undefinedFunction_create_duplicateArgumentNames() async {
    resolveTestUnit('''
class C {
  int x;
}

foo(C c1, C c2) {
  bar(c1.x, c2.x);
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
class C {
  int x;
}

foo(C c1, C c2) {
  bar(c1.x, c2.x);
}

void bar(int x, int x2) {
}
''');
  }

  test_undefinedFunction_create_dynamicArgument() async {
    resolveTestUnit('''
main() {
  dynamic v;
  test(v);
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
main() {
  dynamic v;
  test(v);
}

void test(v) {
}
''');
  }

  test_undefinedFunction_create_dynamicReturnType() async {
    resolveTestUnit('''
main() {
  dynamic v = test();
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
main() {
  dynamic v = test();
}

test() {
}
''');
  }

  test_undefinedFunction_create_fromFunction() async {
    resolveTestUnit('''
main() {
  int v = myUndefinedFunction(1, 2.0, '3');
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
main() {
  int v = myUndefinedFunction(1, 2.0, '3');
}

int myUndefinedFunction(int i, double d, String s) {
}
''');
  }

  test_undefinedFunction_create_fromMethod() async {
    resolveTestUnit('''
class A {
  main() {
    int v = myUndefinedFunction(1, 2.0, '3');
  }
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
class A {
  main() {
    int v = myUndefinedFunction(1, 2.0, '3');
  }
}

int myUndefinedFunction(int i, double d, String s) {
}
''');
  }

  test_undefinedFunction_create_generic_BAD() async {
    resolveTestUnit('''
class A<T> {
  Map<int, T> items;
  main() {
    process(items);
  }
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
class A<T> {
  Map<int, T> items;
  main() {
    process(items);
  }
}

void process(Map items) {
}
''');
  }

  test_undefinedFunction_create_generic_OK() async {
    resolveTestUnit('''
class A {
  List<int> items;
  main() {
    process(items);
  }
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
class A {
  List<int> items;
  main() {
    process(items);
  }
}

void process(List<int> items) {
}
''');
    _assertLinkedGroup(
        change.linkedEditGroups[2],
        ['List<int> items) {'],
        expectedSuggestions(LinkedEditSuggestionKind.TYPE,
            ['List<int>', 'Iterable<int>', 'Object']));
  }

  test_undefinedFunction_create_importType() async {
    addSource(
        '/lib.dart',
        r'''
library lib;
import 'dart:async';
Future getFuture() => null;
''');
    resolveTestUnit('''
import 'lib.dart';
main() {
  test(getFuture());
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
import 'lib.dart';
import 'dart:async';
main() {
  test(getFuture());
}

void test(Future future) {
}
''');
  }

  test_undefinedFunction_create_nullArgument() async {
    resolveTestUnit('''
main() {
  test(null);
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
main() {
  test(null);
}

void test(arg0) {
}
''');
  }

  test_undefinedFunction_create_returnType_bool_expressions() async {
    await assert_undefinedFunction_create_returnType_bool("!test();");
    await assert_undefinedFunction_create_returnType_bool("b && test();");
    await assert_undefinedFunction_create_returnType_bool("test() && b;");
    await assert_undefinedFunction_create_returnType_bool("b || test();");
    await assert_undefinedFunction_create_returnType_bool("test() || b;");
  }

  test_undefinedFunction_create_returnType_bool_statements() async {
    await assert_undefinedFunction_create_returnType_bool("assert ( test() );");
    await assert_undefinedFunction_create_returnType_bool("if ( test() ) {}");
    await assert_undefinedFunction_create_returnType_bool(
        "while ( test() ) {}");
    await assert_undefinedFunction_create_returnType_bool(
        "do {} while ( test() );");
  }

  test_undefinedFunction_create_returnType_fromAssignment_eq() async {
    resolveTestUnit('''
main() {
  int v;
  v = myUndefinedFunction();
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
main() {
  int v;
  v = myUndefinedFunction();
}

int myUndefinedFunction() {
}
''');
  }

  test_undefinedFunction_create_returnType_fromAssignment_plusEq() async {
    resolveTestUnit('''
main() {
  int v;
  v += myUndefinedFunction();
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
main() {
  int v;
  v += myUndefinedFunction();
}

num myUndefinedFunction() {
}
''');
  }

  test_undefinedFunction_create_returnType_fromBinary_right() async {
    resolveTestUnit('''
main() {
  0 + myUndefinedFunction();
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
main() {
  0 + myUndefinedFunction();
}

num myUndefinedFunction() {
}
''');
  }

  test_undefinedFunction_create_returnType_fromInitializer() async {
    resolveTestUnit('''
main() {
  int v = myUndefinedFunction();
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
main() {
  int v = myUndefinedFunction();
}

int myUndefinedFunction() {
}
''');
  }

  test_undefinedFunction_create_returnType_fromInvocationArgument() async {
    resolveTestUnit('''
foo(int p) {}
main() {
  foo( myUndefinedFunction() );
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
foo(int p) {}
main() {
  foo( myUndefinedFunction() );
}

int myUndefinedFunction() {
}
''');
  }

  test_undefinedFunction_create_returnType_fromReturn() async {
    resolveTestUnit('''
int main() {
  return myUndefinedFunction();
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
int main() {
  return myUndefinedFunction();
}

int myUndefinedFunction() {
}
''');
  }

  test_undefinedFunction_create_returnType_void() async {
    resolveTestUnit('''
main() {
  myUndefinedFunction();
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
main() {
  myUndefinedFunction();
}

void myUndefinedFunction() {
}
''');
  }

  test_undefinedFunction_useSimilar_fromImport() async {
    resolveTestUnit('''
main() {
  pritn(0);
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TO,
        '''
main() {
  print(0);
}
''');
  }

  test_undefinedFunction_useSimilar_thisLibrary() async {
    resolveTestUnit('''
myFunction() {}
main() {
  myFuntcion();
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TO,
        '''
myFunction() {}
main() {
  myFunction();
}
''');
  }

  test_undefinedGetter_useSimilar_hint() async {
    resolveTestUnit('''
class A {
  int myField;
}
main(A a) {
  var x = a;
  print(x.myFild);
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TO,
        '''
class A {
  int myField;
}
main(A a) {
  var x = a;
  print(x.myField);
}
''');
  }

  test_undefinedGetter_useSimilar_qualified() async {
    resolveTestUnit('''
class A {
  int myField;
}
main(A a) {
  print(a.myFild);
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TO,
        '''
class A {
  int myField;
}
main(A a) {
  print(a.myField);
}
''');
  }

  test_undefinedGetter_useSimilar_qualified_static() async {
    resolveTestUnit('''
class A {
  static int MY_NAME = 1;
}
main() {
  A.MY_NAM;
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TO,
        '''
class A {
  static int MY_NAME = 1;
}
main() {
  A.MY_NAME;
}
''');
  }

  test_undefinedGetter_useSimilar_unqualified() async {
    resolveTestUnit('''
class A {
  int myField;
  main() {
    print(myFild);
  }
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TO,
        '''
class A {
  int myField;
  main() {
    print(myField);
  }
}
''');
  }

  test_undefinedMethod_create_BAD_inSDK() async {
    resolveTestUnit('''
main() {
  List.foo();
}
''');
    await assertNoFix(DartFixKind.CREATE_METHOD);
  }

  test_undefinedMethod_create_BAD_targetIsEnum() async {
    resolveTestUnit('''
enum MyEnum {A, B}
main() {
  MyEnum.foo();
}
''');
    await assertNoFix(DartFixKind.CREATE_METHOD);
  }

  test_undefinedMethod_create_generic_BAD_argumentType() async {
    resolveTestUnit('''
class A<T> {
  B b;
  Map<int, T> items;
  main() {
    b.process(items);
  }
}

class B {
}
''');
    await assertHasFix(
        DartFixKind.CREATE_METHOD,
        '''
class A<T> {
  B b;
  Map<int, T> items;
  main() {
    b.process(items);
  }
}

class B {
  void process(Map items) {
  }
}
''');
  }

  test_undefinedMethod_create_generic_BAD_returnType() async {
    resolveTestUnit('''
class A<T> {
  main() {
    T t = new B().compute();
  }
}

class B {
}
''');
    await assertHasFix(
        DartFixKind.CREATE_METHOD,
        '''
class A<T> {
  main() {
    T t = new B().compute();
  }
}

class B {
  dynamic compute() {
  }
}
''');
  }

  test_undefinedMethod_create_generic_OK_literal() async {
    resolveTestUnit('''
class A {
  B b;
  List<int> items;
  main() {
    b.process(items);
  }
}

class B {
}
''');
    await assertHasFix(
        DartFixKind.CREATE_METHOD,
        '''
class A {
  B b;
  List<int> items;
  main() {
    b.process(items);
  }
}

class B {
  void process(List<int> items) {
  }
}
''');
  }

  test_undefinedMethod_create_generic_OK_local() async {
    resolveTestUnit('''
class A<T> {
  List<T> items;
  main() {
    process(items);
  }
}
''');
    await assertHasFix(
        DartFixKind.CREATE_METHOD,
        '''
class A<T> {
  List<T> items;
  main() {
    process(items);
  }

  void process(List<T> items) {
  }
}
''');
  }

  test_undefinedMethod_createQualified_fromClass() async {
    resolveTestUnit('''
class A {
}
main() {
  A.myUndefinedMethod();
}
''');
    await assertHasFix(
        DartFixKind.CREATE_METHOD,
        '''
class A {
  static void myUndefinedMethod() {
  }
}
main() {
  A.myUndefinedMethod();
}
''');
  }

  test_undefinedMethod_createQualified_fromClass_hasOtherMember() async {
    resolveTestUnit('''
class A {
  foo() {}
}
main() {
  A.myUndefinedMethod();
}
''');
    await assertHasFix(
        DartFixKind.CREATE_METHOD,
        '''
class A {
  foo() {}

  static void myUndefinedMethod() {
  }
}
main() {
  A.myUndefinedMethod();
}
''');
  }

  test_undefinedMethod_createQualified_fromInstance() async {
    resolveTestUnit('''
class A {
}
main(A a) {
  a.myUndefinedMethod();
}
''');
    await assertHasFix(
        DartFixKind.CREATE_METHOD,
        '''
class A {
  void myUndefinedMethod() {
  }
}
main(A a) {
  a.myUndefinedMethod();
}
''');
  }

  test_undefinedMethod_createQualified_targetIsFunctionType() async {
    resolveTestUnit('''
typedef A();
main() {
  A.myUndefinedMethod();
}
''');
    await assertNoFix(DartFixKind.CREATE_METHOD);
  }

  test_undefinedMethod_createQualified_targetIsUnresolved() async {
    resolveTestUnit('''
main() {
  NoSuchClass.myUndefinedMethod();
}
''');
    await assertNoFix(DartFixKind.CREATE_METHOD);
  }

  test_undefinedMethod_createUnqualified_duplicateArgumentNames() async {
    resolveTestUnit('''
class C {
  int x;
}

class D {
  foo(C c1, C c2) {
    bar(c1.x, c2.x);
  }
}''');
    await assertHasFix(
        DartFixKind.CREATE_METHOD,
        '''
class C {
  int x;
}

class D {
  foo(C c1, C c2) {
    bar(c1.x, c2.x);
  }

  void bar(int x, int x2) {
  }
}''');
  }

  test_undefinedMethod_createUnqualified_parameters() async {
    resolveTestUnit('''
class A {
  main() {
    myUndefinedMethod(0, 1.0, '3');
  }
}
''');
    await assertHasFix(
        DartFixKind.CREATE_METHOD,
        '''
class A {
  main() {
    myUndefinedMethod(0, 1.0, '3');
  }

  void myUndefinedMethod(int i, double d, String s) {
  }
}
''');
    // linked positions
    int index = 0;
    _assertLinkedGroup(
        change.linkedEditGroups[index++], ['void myUndefinedMethod(']);
    _assertLinkedGroup(change.linkedEditGroups[index++],
        ['myUndefinedMethod(0', 'myUndefinedMethod(int']);
    _assertLinkedGroup(
        change.linkedEditGroups[index++],
        ['int i'],
        expectedSuggestions(LinkedEditSuggestionKind.TYPE,
            ['int', 'num', 'Object', 'Comparable<num>']));
    _assertLinkedGroup(change.linkedEditGroups[index++], ['i,']);
    _assertLinkedGroup(
        change.linkedEditGroups[index++],
        ['double d'],
        expectedSuggestions(LinkedEditSuggestionKind.TYPE,
            ['double', 'num', 'Object', 'Comparable<num>']));
    _assertLinkedGroup(change.linkedEditGroups[index++], ['d,']);
    _assertLinkedGroup(
        change.linkedEditGroups[index++],
        ['String s'],
        expectedSuggestions(LinkedEditSuggestionKind.TYPE,
            ['String', 'Object', 'Comparable<String>']));
    _assertLinkedGroup(change.linkedEditGroups[index++], ['s)']);
  }

  test_undefinedMethod_createUnqualified_parameters_named() async {
    resolveTestUnit('''
class A {
  main() {
    myUndefinedMethod(0, bbb: 1.0, ccc: '2');
  }
}
''');
    await assertHasFix(
        DartFixKind.CREATE_METHOD,
        '''
class A {
  main() {
    myUndefinedMethod(0, bbb: 1.0, ccc: '2');
  }

  void myUndefinedMethod(int i, {double bbb, String ccc}) {
  }
}
''');
    // linked positions
    int index = 0;
    _assertLinkedGroup(
        change.linkedEditGroups[index++], ['void myUndefinedMethod(']);
    _assertLinkedGroup(change.linkedEditGroups[index++],
        ['myUndefinedMethod(0', 'myUndefinedMethod(int']);
    _assertLinkedGroup(
        change.linkedEditGroups[index++],
        ['int i'],
        expectedSuggestions(LinkedEditSuggestionKind.TYPE,
            ['int', 'num', 'Object', 'Comparable<num>']));
    _assertLinkedGroup(change.linkedEditGroups[index++], ['i,']);
    _assertLinkedGroup(
        change.linkedEditGroups[index++],
        ['double bbb'],
        expectedSuggestions(LinkedEditSuggestionKind.TYPE,
            ['double', 'num', 'Object', 'Comparable<num>']));
    _assertLinkedGroup(
        change.linkedEditGroups[index++],
        ['String ccc'],
        expectedSuggestions(LinkedEditSuggestionKind.TYPE,
            ['String', 'Object', 'Comparable<String>']));
  }

  test_undefinedMethod_createUnqualified_returnType() async {
    resolveTestUnit('''
class A {
  main() {
    int v = myUndefinedMethod();
  }
}
''');
    await assertHasFix(
        DartFixKind.CREATE_METHOD,
        '''
class A {
  main() {
    int v = myUndefinedMethod();
  }

  int myUndefinedMethod() {
  }
}
''');
    // linked positions
    _assertLinkedGroup(change.linkedEditGroups[0], ['int myUndefinedMethod(']);
    _assertLinkedGroup(change.linkedEditGroups[1],
        ['myUndefinedMethod();', 'myUndefinedMethod() {']);
  }

  test_undefinedMethod_createUnqualified_staticFromField() async {
    resolveTestUnit('''
class A {
  static var f = myUndefinedMethod();
}
''');
    await assertHasFix(
        DartFixKind.CREATE_METHOD,
        '''
class A {
  static var f = myUndefinedMethod();

  static myUndefinedMethod() {
  }
}
''');
  }

  test_undefinedMethod_createUnqualified_staticFromMethod() async {
    resolveTestUnit('''
class A {
  static main() {
    myUndefinedMethod();
  }
}
''');
    await assertHasFix(
        DartFixKind.CREATE_METHOD,
        '''
class A {
  static main() {
    myUndefinedMethod();
  }

  static void myUndefinedMethod() {
  }
}
''');
  }

  test_undefinedMethod_hint_createQualified_fromInstance() async {
    resolveTestUnit('''
class A {
}
main() {
  var a = new A();
  a.myUndefinedMethod();
}
''');
    await assertHasFix(
        DartFixKind.CREATE_METHOD,
        '''
class A {
  void myUndefinedMethod() {
  }
}
main() {
  var a = new A();
  a.myUndefinedMethod();
}
''');
  }

  test_undefinedMethod_parameterType_differentPrefixInTargetUnit() async {
    String code2 = r'''
library test2;
import 'test3.dart' as bbb;
export 'test3.dart';
class D {
}
''';
    addSource('/test2.dart', code2);
    addSource(
        '/test3.dart',
        r'''
library test3;
class E {}
''');
    resolveTestUnit('''
library test;
import 'test2.dart' as aaa;
main(aaa.D d, aaa.E e) {
  d.foo(e);
}
''');
    AnalysisError error = _findErrorToFix();
    fix = await _assertHasFix(DartFixKind.CREATE_METHOD, error);
    change = fix.change;
    // apply to "test2.dart"
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = change.edits[0];
    expect(fileEdit.file, '/test2.dart');
    expect(
        SourceEdit.applySequence(code2, fileEdit.edits),
        r'''
library test2;
import 'test3.dart' as bbb;
export 'test3.dart';
class D {
  void foo(bbb.E e) {
  }
}
''');
  }

  test_undefinedMethod_parameterType_inTargetUnit() async {
    String code2 = r'''
library test2;
class D {
}
class E {}
''';
    addSource('/test2.dart', code2);
    resolveTestUnit('''
library test;
import 'test2.dart' as test2;
main(test2.D d, test2.E e) {
  d.foo(e);
}
''');
    AnalysisError error = _findErrorToFix();
    fix = await _assertHasFix(DartFixKind.CREATE_METHOD, error);
    change = fix.change;
    // apply to "test2.dart"
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));
    SourceFileEdit fileEdit = change.edits[0];
    expect(fileEdit.file, '/test2.dart');
    expect(
        SourceEdit.applySequence(code2, fileEdit.edits),
        r'''
library test2;
class D {
  void foo(E e) {
  }
}
class E {}
''');
  }

  test_undefinedMethod_useSimilar_ignoreOperators() async {
    resolveTestUnit('''
main(Object object) {
  object.then();
}
''');
    await assertNoFix(DartFixKind.CHANGE_TO);
  }

  test_undefinedMethod_useSimilar_qualified() async {
    resolveTestUnit('''
class A {
  myMethod() {}
}
main() {
  A a = new A();
  a.myMehtod();
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TO,
        '''
class A {
  myMethod() {}
}
main() {
  A a = new A();
  a.myMethod();
}
''');
  }

  test_undefinedMethod_useSimilar_unqualified_superClass() async {
    resolveTestUnit('''
class A {
  myMethod() {}
}
class B extends A {
  main() {
    myMehtod();
  }
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TO,
        '''
class A {
  myMethod() {}
}
class B extends A {
  main() {
    myMethod();
  }
}
''');
  }

  test_undefinedMethod_useSimilar_unqualified_thisClass() async {
    resolveTestUnit('''
class A {
  myMethod() {}
  main() {
    myMehtod();
  }
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TO,
        '''
class A {
  myMethod() {}
  main() {
    myMethod();
  }
}
''');
  }

  test_undefinedSetter_useSimilar_hint() async {
    resolveTestUnit('''
class A {
  int myField;
}
main(A a) {
  var x = a;
  x.myFild = 42;
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TO,
        '''
class A {
  int myField;
}
main(A a) {
  var x = a;
  x.myField = 42;
}
''');
  }

  test_undefinedSetter_useSimilar_qualified() async {
    resolveTestUnit('''
class A {
  int myField;
}
main(A a) {
  a.myFild = 42;
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TO,
        '''
class A {
  int myField;
}
main(A a) {
  a.myField = 42;
}
''');
  }

  test_undefinedSetter_useSimilar_unqualified() async {
    resolveTestUnit('''
class A {
  int myField;
  main() {
    myFild = 42;
  }
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TO,
        '''
class A {
  int myField;
  main() {
    myField = 42;
  }
}
''');
  }

  test_useEffectiveIntegerDivision() async {
    resolveTestUnit('''
main() {
  var a = 5;
  var b = 2;
  print((a / b).toInt());
}
''');
    await assertHasFix(
        DartFixKind.USE_EFFECTIVE_INTEGER_DIVISION,
        '''
main() {
  var a = 5;
  var b = 2;
  print(a ~/ b);
}
''');
  }

  test_useImportPrefix_withClass() async {
    resolveTestUnit('''
import 'dart:async' as pref;
main() {
  pref.Stream s = null;
  Future f = null;
}
''');
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PREFIX,
        '''
import 'dart:async' as pref;
main() {
  pref.Stream s = null;
  pref.Future f = null;
}
''');
  }

  test_useImportPrefix_withTopLevelVariable() async {
    resolveTestUnit('''
import 'dart:math' as pref;
main() {
  print(pref.E);
  print(PI);
}
''');
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PREFIX,
        '''
import 'dart:math' as pref;
main() {
  print(pref.E);
  print(pref.PI);
}
''');
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

  void findLint(String src, String lintCode) {
    int errorOffset = src.indexOf('/*LINT*/');
    resolveTestUnit(src.replaceAll('/*LINT*/', ''));
    error = new AnalysisError(testUnit.element.source, errorOffset, 1,
        new LintCode(lintCode, '<ignored>'));
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
    findLint(src, LintNames.annotate_overrides);

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
    findLint(src, LintNames.annotate_overrides);

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
    findLint(src, LintNames.annotate_overrides);

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
    findLint(src, LintNames.annotate_overrides);

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
    findLint(src, LintNames.annotate_overrides);

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
    findLint(src, LintNames.annotate_overrides);

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
    findLint(src, LintNames.annotate_overrides);

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

  void verifyResult(String expectedResult) {
    expect(resultCode, expectedResult);
  }
}
