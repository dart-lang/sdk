// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/plugin/edit/fix/fix_dart.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/dart/analysis/ast_provider_driver.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/element/ast_provider.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';
import 'flutter_util.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FixProcessorTest);
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

  assert_undefinedFunction_create_returnType_bool(String lineWithTest) async {
    await resolveTestUnit('''
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

  assertHasFix(FixKind kind, String expected, {String target}) async {
    AnalysisError error = await _findErrorToFix();
    fix = await _assertHasFix(kind, error);
    change = fix.change;

    // apply to "file"
    List<SourceFileEdit> fileEdits = change.edits;
    expect(fileEdits, hasLength(1));

    if (target != null) {
      expect(target, fileEdits.first.file);
    }

    resultCode = SourceEdit.applySequence(testCode, change.edits[0].edits);
    // verify
    expect(resultCode, expected);
  }

  assertNoFix(FixKind kind) async {
    AnalysisError error = await _findErrorToFix();
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

  Future<List<AnalysisError>> _computeErrors() async {
    if (enableNewAnalysisDriver) {
      return (await driver.getResult(testFile)).errors;
    } else {
      return context.computeErrors(testSource);
    }
  }

  /**
   * Computes fixes for the given [error] in [testUnit].
   */
  Future<List<Fix>> _computeFixes(AnalysisError error) async {
    DartFixContext fixContext = new _DartFixContextImpl(
        provider, driver, new AstProviderForDriver(driver), testUnit, error);
    return await new DefaultFixContributor().internalComputeFixes(fixContext);
  }

  /**
   * Configures the [SourceFactory] to have the `my_pkg` package in
   * `/packages/my_pkg/lib` folder.
   */
  void _configureMyPkg(Map<String, String> pathToCode) {
    pathToCode.forEach((path, code) {
      provider.newFile('$myPkgLibPath/$path', code);
    });
    // configure SourceFactory
    Folder myPkgFolder = provider.getResource(myPkgLibPath);
    UriResolver pkgResolver = new PackageMapUriResolver(provider, {
      'my_pkg': [myPkgFolder]
    });
    SourceFactory sourceFactory = new SourceFactory(
        [new DartUriResolver(sdk), pkgResolver, resourceResolver]);
    if (enableNewAnalysisDriver) {
      driver.configure(sourceFactory: sourceFactory);
    } else {
      context.sourceFactory = sourceFactory;
    }
    // force 'my_pkg' resolution
    addSource(
        '/tmp/other.dart',
        pathToCode.keys
            .map((path) => "import 'package:my_pkg/$path';")
            .join('\n'));
  }

  Future<AnalysisError> _findErrorToFix() async {
    List<AnalysisError> errors = await _computeErrors();
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
}

@reflectiveTest
class FixProcessorTest extends BaseFixProcessorTest {
  test_addFieldFormalParameters_hasRequiredParameter() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
test({int a}) {}
main() {
  test(1);
}
''');
    await assertNoFix(DartFixKind.ADD_MISSING_PARAMETER_POSITIONAL);
  }

  test_addMissingParameter_function_positional_hasZero() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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

  test_addMissingRequiredArg_cons_flutter_children() async {
    addPackageSource(
        'flutter', 'src/widgets/framework.dart', flutter_framework_code);

    _addMetaPackageSource();

    await resolveTestUnit('''
import 'package:flutter/src/widgets/framework.dart';
import 'package:meta/meta.dart';

class MyWidget extends Widget {
  MyWidget({@required List<Widget> children});
}

build() {
  return new MyWidget();
}
''');

    await assertHasFix(
        DartFixKind.ADD_MISSING_REQUIRED_ARGUMENT,
        '''
import 'package:flutter/src/widgets/framework.dart';
import 'package:meta/meta.dart';

class MyWidget extends Widget {
  MyWidget({@required List<Widget> children});
}

build() {
  return new MyWidget(children: <Widget>[],);
}
''',
        target: '/test.dart');
  }

  test_addMissingRequiredArg_cons_single() async {
    _addMetaPackageSource();
    addSource(
        '/libA.dart',
        r'''
library libA;
import 'package:meta/meta.dart';

class A {
  A({@required int a}) {}
}
''');

    await resolveTestUnit('''
import 'libA.dart';

main() {
  A a = new A();
}
''');
    await assertHasFix(
        DartFixKind.ADD_MISSING_REQUIRED_ARGUMENT,
        '''
import 'libA.dart';

main() {
  A a = new A(a: null);
}
''',
        target: '/test.dart');
  }

  test_addMissingRequiredArg_cons_single_closure() async {
    _addMetaPackageSource();

    addSource(
        '/libA.dart',
        r'''
library libA;
import 'package:meta/meta.dart';

typedef void VoidCallback();

class A {
  A({@required VoidCallback onPressed}) {}
}
''');

    await resolveTestUnit('''
import 'libA.dart';

main() {
  A a = new A();
}
''');
    await assertHasFix(
        DartFixKind.ADD_MISSING_REQUIRED_ARGUMENT,
        '''
import 'libA.dart';

main() {
  A a = new A(onPressed: () {});
}
''',
        target: '/test.dart');
  }

  test_addMissingRequiredArg_cons_single_closure_2() async {
    _addMetaPackageSource();

    addSource(
        '/libA.dart',
        r'''
library libA;
import 'package:meta/meta.dart';

typedef void Callback(e);

class A {
  A({@required Callback callback}) {}
}
''');

    await resolveTestUnit('''
import 'libA.dart';

main() {
  A a = new A();
}
''');
    await assertHasFix(
        DartFixKind.ADD_MISSING_REQUIRED_ARGUMENT,
        '''
import 'libA.dart';

main() {
  A a = new A(callback: (e) {});
}
''',
        target: '/test.dart');
  }

  test_addMissingRequiredArg_cons_single_closure_3() async {
    _addMetaPackageSource();

    addSource(
        '/libA.dart',
        r'''
library libA;
import 'package:meta/meta.dart';

typedef void Callback(a,b,c);

class A {
  A({@required Callback callback}) {}
}
''');

    await resolveTestUnit('''
import 'libA.dart';

main() {
  A a = new A();
}
''');
    await assertHasFix(
        DartFixKind.ADD_MISSING_REQUIRED_ARGUMENT,
        '''
import 'libA.dart';

main() {
  A a = new A(callback: (a, b, c) {});
}
''',
        target: '/test.dart');
  }

  test_addMissingRequiredArg_cons_single_closure_4() async {
    _addMetaPackageSource();

    addSource(
        '/libA.dart',
        r'''
library libA;
import 'package:meta/meta.dart';

typedef int Callback(int a, String b,c);

class A {
  A({@required Callback callback}) {}
}
''');

    await resolveTestUnit('''
import 'libA.dart';

main() {
  A a = new A();
}
''');
    await assertHasFix(
        DartFixKind.ADD_MISSING_REQUIRED_ARGUMENT,
        '''
import 'libA.dart';

main() {
  A a = new A(callback: (int a, String b, c) {});
}
''',
        target: '/test.dart');
  }

  test_addMissingRequiredArg_cons_single_list() async {
    _addMetaPackageSource();

    addSource(
        '/libA.dart',
        r'''
library libA;
import 'package:meta/meta.dart';

class A {
  A({@required List<String> names}) {}
}
''');

    await resolveTestUnit('''
import 'libA.dart';

main() {
  A a = new A();
}
''');
    await assertHasFix(
        DartFixKind.ADD_MISSING_REQUIRED_ARGUMENT,
        '''
import 'libA.dart';

main() {
  A a = new A(names: <String>[]);
}
''',
        target: '/test.dart');
  }

  test_addMissingRequiredArg_multiple() async {
    _addMetaPackageSource();

    await resolveTestUnit('''
import 'package:meta/meta.dart';

test({@required int a, @required int bcd}) {}
main() {
  test(a: 3);
}
''');
    await assertHasFix(
        DartFixKind.ADD_MISSING_REQUIRED_ARGUMENT,
        '''
import 'package:meta/meta.dart';

test({@required int a, @required int bcd}) {}
main() {
  test(a: 3, bcd: null);
}
''');
  }

  test_addMissingRequiredArg_multiple_2() async {
    _addMetaPackageSource();

    await resolveTestUnit('''
import 'package:meta/meta.dart';

test({@required int a, @required int bcd}) {}
main() {
  test();
}
''');

    // For now we expect one error per missing arg (dartbug.com/28830).
    List<AnalysisError> errors = await _computeErrors();
    expect(errors, hasLength(2));

    List<AnalysisError> filteredErrors = errors
        .where((e) => e.message == "The parameter 'a' is required.")
        .toList();
    expect(filteredErrors, hasLength(1));

    List<Fix> fixes = await _computeFixes(filteredErrors.first);

    List<Fix> filteredFixes = fixes
        .where((fix) => fix.change.message == "Add required argument 'a'")
        .toList();
    expect(filteredFixes, hasLength(1));
    change = filteredFixes.first.change;
    resultCode = SourceEdit.applySequence(testCode, change.edits[0].edits);
    // verify
    expect(
        resultCode,
        '''
import 'package:meta/meta.dart';

test({@required int a, @required int bcd}) {}
main() {
  test(a: null);
}
''');
  }

  test_addMissingRequiredArg_single() async {
    _addMetaPackageSource();

    await resolveTestUnit('''
import 'package:meta/meta.dart';

test({@required int abc}) {}
main() {
  test();
}
''');
    await assertHasFix(
        DartFixKind.ADD_MISSING_REQUIRED_ARGUMENT,
        '''
import 'package:meta/meta.dart';

test({@required int abc}) {}
main() {
  test(abc: null);
}
''');
  }

  test_addMissingRequiredArg_single_normal() async {
    _addMetaPackageSource();

    await resolveTestUnit('''
import 'package:meta/meta.dart';

test(String x, {@required int abc}) {}
main() {
  test("foo");
}
''');
    await assertHasFix(
        DartFixKind.ADD_MISSING_REQUIRED_ARGUMENT,
        '''
import 'package:meta/meta.dart';

test(String x, {@required int abc}) {}
main() {
  test("foo", abc: null);
}
''');
  }

  test_addMissingRequiredArg_single_with_details() async {
    _addMetaPackageSource();

    await resolveTestUnit('''
import 'package:meta/meta.dart';

test({@Required("Really who doesn't need an abc?") int abc}) {}
main() {
  test();
}
''');
    await assertHasFix(
        DartFixKind.ADD_MISSING_REQUIRED_ARGUMENT,
        '''
import 'package:meta/meta.dart';

test({@Required("Really who doesn't need an abc?") int abc}) {}
main() {
  test(abc: null);
}
''');
  }

  test_addSync_asyncFor() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
var F = await;
''');
    await assertNoFix(DartFixKind.ADD_ASYNC);
  }

  test_addSync_blockFunctionBody() async {
    await resolveTestUnit('''
foo() {}
main() {
  await foo();
}
''');
    List<AnalysisError> errors = await _computeErrors();
    expect(errors, hasLength(2));
    errors.sort((a, b) => a.message.compareTo(b.message));
    // No fix for ";".
    {
      AnalysisError error = errors[0];
      expect(error.message, "Expected to find ';'.");
      List<Fix> fixes = await _computeFixes(error);
      expect(fixes, isEmpty);
    }
    // Has fix for "await".
    {
      AnalysisError error = errors[1];
      expect(error.message, startsWith("Undefined name 'await' in function"));
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

  test_addSync_expressionFunctionBody() async {
    errorFilter = (AnalysisError error) {
      return error.errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER_AWAIT;
    };
    await resolveTestUnit('''
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
      return error.errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER_AWAIT;
    };
    await resolveTestUnit('''
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
      return error.errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER_AWAIT;
    };
    await resolveTestUnit('''
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
      return error.errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER_AWAIT;
    };
    await resolveTestUnit('''
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
      return error.errorCode == StaticWarningCode.UNDEFINED_IDENTIFIER_AWAIT;
    };
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
import 'libB.dart';
main(B b) {
  b.foo();
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TO_STATIC_ACCESS,
        '''
import 'libA.dart';
import 'libB.dart';
main(B b) {
  A.foo();
}
''');
  }

  test_changeToStaticAccess_method_prefixLibrary() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
import 'libB.dart';
main(B b) {
  b.foo;
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TO_STATIC_ACCESS,
        '''
import 'libA.dart';
import 'libB.dart';
main(B b) {
  A.foo;
}
''');
  }

  test_changeTypeAnnotation_BAD_multipleVariables() async {
    await resolveTestUnit('''
main() {
  String a, b = 42;
}
''');
    await assertNoFix(DartFixKind.CHANGE_TYPE_ANNOTATION);
  }

  test_changeTypeAnnotation_BAD_notVariableDeclaration() async {
    await resolveTestUnit('''
main() {
  String v;
  v = 42;
}
''');
    await assertNoFix(DartFixKind.CHANGE_TYPE_ANNOTATION);
  }

  test_changeTypeAnnotation_OK_generic() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
import 'lib.dart' as lib;

main() {
  lib.A a = null;
  lib.Test t = null;
}
''');
    AnalysisError error = await _findErrorToFix();
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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

  A(int i, double d);

  method() {}
}
main() {
  new A(1, 2.0);
}
''');
  }

  test_createConstructor_named() async {
    await resolveTestUnit('''
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
  A.named(int i, double d);

  method() {}
}
main() {
  new A.named(1, 2.0);
}
''');
    _assertLinkedGroup(change.linkedEditGroups[0], ['named(int ', 'named(1']);
  }

  test_createConstructor_named_emptyClassBody() async {
    await resolveTestUnit('''
class A {}
main() {
  new A.named(1);
}
''');
    await assertHasFix(
        DartFixKind.CREATE_CONSTRUCTOR,
        '''
class A {
  A.named(int i);
}
main() {
  new A.named(1);
}
''');
    _assertLinkedGroup(change.linkedEditGroups[0], ['named(int ', 'named(1']);
  }

  test_createConstructorForFinalFields_inTopLevelMethod() async {
    await resolveTestUnit('''
main() {
  final int v;
}
''');
    await assertNoFix(DartFixKind.CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS);
  }

  test_createConstructorForFinalFields_topLevelField() async {
    await resolveTestUnit('''
final int v;
''');
    await assertNoFix(DartFixKind.CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS);
  }

  test_createConstructorSuperExplicit() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
import 'libB.dart';
class C extends B {
}
''');
    await assertHasFix(
        DartFixKind.CREATE_CONSTRUCTOR_SUPER,
        '''
import 'libA.dart';
import 'libB.dart';
class C extends B {
  C(A a) : super(a);
}
''');
  }

  test_createConstructorSuperImplicit_named() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
class A {
  A._named(p);
}
class B extends A {
}
''');
    await assertNoFix(DartFixKind.CREATE_CONSTRUCTOR_SUPER);
  }

  test_createConstructorSuperImplicit_typeArgument() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
main(List p) {
  p.foo = 1;
}
''');
    await assertNoFix(DartFixKind.CREATE_FIELD);
  }

  test_createField_getter_multiLevel() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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

  test_createField_getter_qualified_propagatedType() async {
    await resolveTestUnit('''
class A {
  A get self => this;
}
main() {
  var a = new A();
  int v = a.self.test;
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FIELD,
        '''
class A {
  int test;

  A get self => this;
}
main() {
  var a = new A();
  int v = a.self.test;
}
''');
  }

  test_createField_getter_unqualified_instance_asInvocationArgument() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
import 'libA.dart';
import 'libB.dart';
class C {
  A test;
}
main(C c) {
  c.test = getA();
}
''');
  }

  test_createField_setter_generic_BAD() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
import 'my_file.dart';
''');
    AnalysisError error = await _findErrorToFix();
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
    await resolveTestUnit('''
import 'lib';
''');
    await assertNoFix(DartFixKind.CREATE_FILE);
  }

  test_createFile_forImport_BAD_notDart() async {
    testFile = '/my/project/bin/test.dart';
    await resolveTestUnit('''
import 'my_file.txt';
''');
    await assertNoFix(DartFixKind.CREATE_FILE);
  }

  test_createFile_forImport_inPackage_lib() async {
    provider.newFile('/projects/my_package/pubspec.yaml', 'name: my_package');
    testFile = '/projects/my_package/lib/test.dart';
    provider.newFolder('/projects/my_package/lib');
    await resolveTestUnit('''
import 'a/bb/c_cc/my_lib.dart';
''');
    AnalysisError error = await _findErrorToFix();
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
    await resolveTestUnit('''
import 'a/bb/my_lib.dart';
''');
    AnalysisError error = await _findErrorToFix();
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
    await resolveTestUnit('''
library my.lib;
part 'my_part.dart';
''');
    AnalysisError error = await _findErrorToFix();
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
      'my': <Folder>[provider.getResource('/my/lib')],
    });
    SourceFactory sourceFactory = new SourceFactory(
        [new DartUriResolver(sdk), pkgResolver, resourceResolver]);
    if (enableNewAnalysisDriver) {
      driver.configure(sourceFactory: sourceFactory);
      testUnit = (await driver.getResult(testFile)).unit;
    } else {
      context.sourceFactory = sourceFactory;
      testUnit = await resolveLibraryUnit(testSource);
    }
    // prepare fix
    AnalysisError error = await _findErrorToFix();
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
    await resolveTestUnit('''
main(List p) {
  int v = p.foo;
}
''');
    await assertNoFix(DartFixKind.CREATE_GETTER);
  }

  test_createGetter_hint_getter() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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

  test_createGetter_qualified_propagatedType() async {
    await resolveTestUnit('''
class A {
  A get self => this;
}
main() {
  var a = new A();
  int v = a.self.test;
}
''');
    await assertHasFix(
        DartFixKind.CREATE_GETTER,
        '''
class A {
  A get self => this;

  int get test => null;
}
main() {
  var a = new A();
  int v = a.self.test;
}
''');
  }

  test_createGetter_setterContext() async {
    await resolveTestUnit('''
class A {
}
main(A a) {
  a.test = 42;
}
''');
    await assertNoFix(DartFixKind.CREATE_GETTER);
  }

  test_createGetter_unqualified_instance_asInvocationArgument() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
class A {
  main() {
    test = 42;
  }
}
''');
    await assertNoFix(DartFixKind.CREATE_GETTER);
  }

  test_createGetter_unqualified_instance_assignmentRhs() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
foo(f(int p)) {}
main() {
  foo(bar);
}
''');
    await assertNoFix(DartFixKind.CREATE_LOCAL_VARIABLE);
  }

  test_createLocalVariable_read_typeAssignment() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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

  test_createMissingMethodCall() async {
    await resolveTestUnit('''
class C implements Function {
}
''');
    await assertHasFix(
        DartFixKind.CREATE_MISSING_METHOD_CALL,
        '''
class C implements Function {
  call() {
    // TODO: implement call
  }
}
''');
  }

  test_createMissingOverrides_field_untyped() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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

  test_createMissingOverrides_method_emptyClassBody() async {
    await resolveTestUnit('''
abstract class A {
  void foo();
}

class B extends A {}
''');
    await assertHasFix(
        DartFixKind.CREATE_MISSING_OVERRIDES,
        '''
abstract class A {
  void foo();
}

class B extends A {
  @override
  void foo() {
    // TODO: implement foo
  }
}
''');
  }

  test_createMissingOverrides_method_generic() async {
    await resolveTestUnit('''
class C<T> {}
class V<E> {}

abstract class A {
  E1 foo<E1, E2 extends C<int>>(V<E2> v);
}

class B implements A {
}
''');
    await assertHasFix(
        DartFixKind.CREATE_MISSING_OVERRIDES,
        '''
class C<T> {}
class V<E> {}

abstract class A {
  E1 foo<E1, E2 extends C<int>>(V<E2> v);
}

class B implements A {
  @override
  E1 foo<E1, E2 extends C<int>>(V<E2> v) {
    // TODO: implement foo
  }
}
''');
  }

  test_createMissingOverrides_operator() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
  set s3(String x) {
    // TODO: implement s3
  }
}
''');
  }

  test_createNoSuchMethod() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
import 'libB.dart';
main() {
  useFunction(test);
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
import 'libA.dart';
import 'libB.dart';
main() {
  useFunction(test);
}

int test(A a) {
}
''');
  }

  test_creationFunction_forFunctionType_method_enclosingClass_static() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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

  test_importLibraryPackage_preferDirectOverExport() async {
    _configureMyPkg({'b.dart': 'class Test {}', 'a.dart': "export 'b.dart';"});
    await resolveTestUnit('''
main() {
  Test test = null;
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT1,
        '''
import 'package:my_pkg/b.dart';

main() {
  Test test = null;
}
''');
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT2,
        '''
import 'package:my_pkg/a.dart';

main() {
  Test test = null;
}
''');
  }

  test_importLibraryPackage_preferDirectOverExport_src() async {
    myPkgLibPath = '/my/src/packages/my_pkg/lib';
    _configureMyPkg({'b.dart': 'class Test {}', 'a.dart': "export 'b.dart';"});
    await resolveTestUnit('''
main() {
  Test test = null;
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT1,
        '''
import 'package:my_pkg/b.dart';

main() {
  Test test = null;
}
''');
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT2,
        '''
import 'package:my_pkg/a.dart';

main() {
  Test test = null;
}
''');
  }

  test_importLibraryPackage_preferPublicOverPrivate() async {
    _configureMyPkg(
        {'src/a.dart': 'class Test {}', 'b.dart': "export 'src/a.dart';"});
    await resolveTestUnit('''
main() {
  Test test = null;
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT2,
        '''
import 'package:my_pkg/b.dart';

main() {
  Test test = null;
}
''');
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT3,
        '''
import 'package:my_pkg/src/a.dart';

main() {
  Test test = null;
}
''');
  }

  test_importLibraryProject_BAD_notInLib_BUILD() async {
    testFile = '/aaa/bin/test.dart';
    provider.newFile('/aaa/BUILD', '');
    provider.newFile('/bbb/BUILD', '');
    addSource('/bbb/test/lib.dart', 'class Test {}');
    await resolveTestUnit('''
main() {
  Test t;
}
''');
    performAllAnalysisTasks();
    await assertNoFix(DartFixKind.IMPORT_LIBRARY_PROJECT1);
  }

  test_importLibraryProject_BAD_notInLib_pubspec() async {
    testFile = '/aaa/bin/test.dart';
    provider.newFile('/aaa/pubspec.yaml', 'name: aaa');
    provider.newFile('/bbb/pubspec.yaml', 'name: bbb');
    addSource('/bbb/test/lib.dart', 'class Test {}');
    await resolveTestUnit('''
main() {
  Test t;
}
''');
    performAllAnalysisTasks();
    await assertNoFix(DartFixKind.IMPORT_LIBRARY_PROJECT1);
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
    await resolveTestUnit('''
@Test(0)
main() {
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT1,
        '''
import 'lib.dart';

@Test(0)
main() {
}
''');
  }

  test_importLibraryProject_withClass_constInstanceCreation() async {
    addSource(
        '/lib.dart',
        '''
class Test {
  const Test();
}
''');
    await resolveTestUnit('''
main() {
  const Test();
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT1,
        '''
import 'lib.dart';

main() {
  const Test();
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
    await resolveTestUnit('''
import 'b.dart' show Two;
main () {
  new Two();
  new One();
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT1,
        '''
import 'a.dart';
import 'b.dart' show Two;
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
    await resolveTestUnit('''
main() {
  Test t = null;
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT1,
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
    await resolveTestUnit('''
main() {
  Test t = null;
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT1,
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
    await resolveTestUnit('''
main() {
  Test t = null;
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT1,
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
    await resolveTestUnit('''
main() {
  myFunction();
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT1,
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
    await resolveTestUnit('''
class A {
  main() {
    myFunction();
  }
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT1,
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
    await resolveTestUnit('''
main() {
  MyFunction t = null;
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT1,
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
    await resolveTestUnit('''
main() {
  print(MY_VAR);
}
''');
    performAllAnalysisTasks();
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_PROJECT1,
        '''
import 'lib.dart';

main() {
  print(MY_VAR);
}
''');
  }

  test_importLibrarySdk_withClass_AsExpression() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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

  test_importLibraryShow_project() async {
    testFile = '/project/bin/test.dart';
    addSource(
        '/project/bin/lib.dart',
        '''
class A {}
class B {}
''');
    await resolveTestUnit('''
import 'lib.dart' show A;
main() {
  A a;
  B b;
}
''');
    performAllAnalysisTasks();
    await assertNoFix(DartFixKind.IMPORT_LIBRARY_PROJECT1);
    await assertHasFix(
        DartFixKind.IMPORT_LIBRARY_SHOW,
        '''
import 'lib.dart' show A, B;
main() {
  A a;
  B b;
}
''');
  }

  test_importLibraryShow_sdk() async {
    await resolveTestUnit('''
import 'dart:async' show Stream;
main() {
  Stream s = null;
  Future f = null;
}
''');
    await assertNoFix(DartFixKind.IMPORT_LIBRARY_SDK);
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
main(p) {
  p i s Null;
}''');
    List<AnalysisError> errors = await _computeErrors();
    for (var error in errors) {
      await _computeFixes(error);
    }
  }

  test_nonBoolCondition_addNotNull() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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

  test_replaceVarWithDynamic() async {
    errorFilter = (AnalysisError error) {
      return error.errorCode == ParserErrorCode.VAR_AS_TYPE_NAME;
    };
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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

  test_undefinedClass_useSimilar_BAD_prefixed() async {
    await resolveTestUnit('''
import 'dart:async' as c;
main() {
  c.Fture v = null;
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TO,
        '''
import 'dart:async' as c;
main() {
  c.Future v = null;
}
''');
  }

  test_undefinedClass_useSimilar_fromImport() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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

  test_undefinedFunction_create_bottomArgument() async {
    await resolveTestUnit('''
main() {
  test(throw 42);
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
main() {
  test(throw 42);
}

void test(arg0) {
}
''');
  }

  test_undefinedFunction_create_duplicateArgumentNames() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
import 'lib.dart';
main() {
  test(getFuture());
}
''');
    await assertHasFix(
        DartFixKind.CREATE_FUNCTION,
        '''
import 'dart:async';
import 'lib.dart';
main() {
  test(getFuture());
}

void test(Future future) {
}
''');
  }

  test_undefinedFunction_create_nullArgument() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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

  test_undefinedFunction_useSimilar_prefixed_fromImport() async {
    await resolveTestUnit('''
import 'dart:core' as c;
main() {
  c.prnt(42);
}
''');
    await assertHasFix(
        DartFixKind.CHANGE_TO,
        '''
import 'dart:core' as c;
main() {
  c.print(42);
}
''');
  }

  test_undefinedFunction_useSimilar_prefixed_ignoreLocal() async {
    await resolveTestUnit('''
import 'dart:async' as c;
main() {
  c.main();
}
''');
    await assertNoFix(DartFixKind.CHANGE_TO);
  }

  test_undefinedFunction_useSimilar_thisLibrary() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
main() {
  List.foo();
}
''');
    await assertNoFix(DartFixKind.CREATE_METHOD);
  }

  test_undefinedMethod_create_BAD_targetIsEnum() async {
    await resolveTestUnit('''
enum MyEnum {A, B}
main() {
  MyEnum.foo();
}
''');
    await assertNoFix(DartFixKind.CREATE_METHOD);
  }

  test_undefinedMethod_create_generic_BAD_argumentType() async {
    await resolveTestUnit('''
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
  void process(Map items) {}
}
''');
  }

  test_undefinedMethod_create_generic_BAD_returnType() async {
    await resolveTestUnit('''
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
  dynamic compute() {}
}
''');
  }

  test_undefinedMethod_create_generic_OK_literal() async {
    await resolveTestUnit('''
class A {
  B b;
  List<int> items;
  main() {
    b.process(items);
  }
}

class B {}
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
  void process(List<int> items) {}
}
''');
  }

  test_undefinedMethod_create_generic_OK_local() async {
    await resolveTestUnit('''
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

  void process(List<T> items) {}
}
''');
  }

  test_undefinedMethod_createQualified_emptyClassBody() async {
    await resolveTestUnit('''
class A {}
main() {
  A.myUndefinedMethod();
}
''');
    await assertHasFix(
        DartFixKind.CREATE_METHOD,
        '''
class A {
  static void myUndefinedMethod() {}
}
main() {
  A.myUndefinedMethod();
}
''');
  }

  test_undefinedMethod_createQualified_fromClass() async {
    await resolveTestUnit('''
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
  static void myUndefinedMethod() {}
}
main() {
  A.myUndefinedMethod();
}
''');
  }

  test_undefinedMethod_createQualified_fromClass_hasOtherMember() async {
    await resolveTestUnit('''
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

  static void myUndefinedMethod() {}
}
main() {
  A.myUndefinedMethod();
}
''');
  }

  test_undefinedMethod_createQualified_fromInstance() async {
    await resolveTestUnit('''
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
  void myUndefinedMethod() {}
}
main(A a) {
  a.myUndefinedMethod();
}
''');
  }

  test_undefinedMethod_createQualified_targetIsFunctionType() async {
    await resolveTestUnit('''
typedef A();
main() {
  A.myUndefinedMethod();
}
''');
    await assertNoFix(DartFixKind.CREATE_METHOD);
  }

  test_undefinedMethod_createQualified_targetIsUnresolved() async {
    await resolveTestUnit('''
main() {
  NoSuchClass.myUndefinedMethod();
}
''');
    await assertNoFix(DartFixKind.CREATE_METHOD);
  }

  test_undefinedMethod_createUnqualified_duplicateArgumentNames() async {
    await resolveTestUnit('''
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

  void bar(int x, int x2) {}
}''');
  }

  test_undefinedMethod_createUnqualified_parameters() async {
    await resolveTestUnit('''
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

  void myUndefinedMethod(int i, double d, String s) {}
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
    await resolveTestUnit('''
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

  void myUndefinedMethod(int i, {double bbb, String ccc}) {}
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
    await resolveTestUnit('''
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

  int myUndefinedMethod() {}
}
''');
    // linked positions
    _assertLinkedGroup(change.linkedEditGroups[0], ['int myUndefinedMethod(']);
    _assertLinkedGroup(change.linkedEditGroups[1],
        ['myUndefinedMethod();', 'myUndefinedMethod() {']);
  }

  test_undefinedMethod_createUnqualified_staticFromField() async {
    await resolveTestUnit('''
class A {
  static var f = myUndefinedMethod();
}
''');
    await assertHasFix(
        DartFixKind.CREATE_METHOD,
        '''
class A {
  static var f = myUndefinedMethod();

  static myUndefinedMethod() {}
}
''');
  }

  test_undefinedMethod_createUnqualified_staticFromMethod() async {
    await resolveTestUnit('''
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

  static void myUndefinedMethod() {}
}
''');
  }

  test_undefinedMethod_hint_createQualified_fromInstance() async {
    await resolveTestUnit('''
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
  void myUndefinedMethod() {}
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
    await resolveTestUnit('''
library test;
import 'test2.dart' as aaa;
main(aaa.D d, aaa.E e) {
  d.foo(e);
}
''');
    AnalysisError error = await _findErrorToFix();
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
  void foo(bbb.E e) {}
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
    await resolveTestUnit('''
library test;
import 'test2.dart' as test2;
main(test2.D d, test2.E e) {
  d.foo(e);
}
''');
    AnalysisError error = await _findErrorToFix();
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
  void foo(E e) {}
}
class E {}
''');
  }

  test_undefinedMethod_useSimilar_ignoreOperators() async {
    await resolveTestUnit('''
main(Object object) {
  object.then();
}
''');
    await assertNoFix(DartFixKind.CHANGE_TO);
  }

  test_undefinedMethod_useSimilar_qualified() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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

  test_undefinedParameter_convertFlutterChild_invalidList() async {
    _configureFlutterPkg({
      'src/widgets/framework.dart': flutter_framework_code,
    });
    await resolveTestUnit('''
import 'package:flutter/src/widgets/framework.dart';
build() {
  return new Container(
    child: new Row(
      child: <Widget>[
        new Transform(),
        null,
        new AspectRatio(),
      ],
    ),
  );
}
''');
    await assertNoFix(DartFixKind.CONVERT_FLUTTER_CHILD);
  }

  test_undefinedParameter_convertFlutterChild_OK_hasList() async {
    _configureFlutterPkg({
      'src/widgets/framework.dart': flutter_framework_code,
    });
    await resolveTestUnit('''
import 'package:flutter/src/widgets/framework.dart';
build() {
  return new Container(
    child: new Row(
      child: [
        new Transform(),
        new ClipRect.rect(),
        new AspectRatio(),
      ],
    ),
  );
}
''');
    await assertHasFix(
        DartFixKind.CONVERT_FLUTTER_CHILD,
        '''
import 'package:flutter/src/widgets/framework.dart';
build() {
  return new Container(
    child: new Row(
      children: <Widget>[
        new Transform(),
        new ClipRect.rect(),
        new AspectRatio(),
      ],
    ),
  );
}
''');
  }

  test_undefinedParameter_convertFlutterChild_OK_hasTypedList() async {
    _configureFlutterPkg({
      'src/widgets/framework.dart': flutter_framework_code,
    });
    await resolveTestUnit('''
import 'package:flutter/src/widgets/framework.dart';
build() {
  return new Container(
    child: new Row(
      child: <Widget>[
        new Transform(),
        new ClipRect.rect(),
        new AspectRatio(),
      ],
    ),
  );
}
''');
    await assertHasFix(
        DartFixKind.CONVERT_FLUTTER_CHILD,
        '''
import 'package:flutter/src/widgets/framework.dart';
build() {
  return new Container(
    child: new Row(
      children: <Widget>[
        new Transform(),
        new ClipRect.rect(),
        new AspectRatio(),
      ],
    ),
  );
}
''');
  }

  test_undefinedParameter_convertFlutterChild_OK_multiLine() async {
    _configureFlutterPkg({
      'src/widgets/framework.dart': flutter_framework_code,
    });
    await resolveTestUnit('''
import 'package:flutter/src/widgets/framework.dart';
build() {
  return new Scaffold(
    body: new Row(
      child: new Container(
        width: 200.0,
        height: 300.0,
      ),
    ),
  );
}
''');
    await assertHasFix(
        DartFixKind.CONVERT_FLUTTER_CHILD,
        '''
import 'package:flutter/src/widgets/framework.dart';
build() {
  return new Scaffold(
    body: new Row(
      children: <Widget>[
        new Container(
          width: 200.0,
          height: 300.0,
        ),
      ],
    ),
  );
}
''');
  }

  test_undefinedSetter_useSimilar_hint() async {
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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
    await resolveTestUnit('''
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

  void _addMetaPackageSource() {
    addPackageSource(
        'meta',
        'meta.dart',
        r'''
library meta;

const Required required = const Required();

class Required {
  final String reason;
  const Required([this.reason]);
}
''');
  }

  /**
   * Configures the [SourceFactory] to have the `flutter` package in
   * `/packages/flutter/lib` folder.
   */
  void _configureFlutterPkg(Map<String, String> pathToCode) {
    pathToCode.forEach((path, code) {
      provider.newFile('$flutterPkgLibPath/$path', code);
    });
    // configure SourceFactory
    Folder myPkgFolder = provider.getResource(flutterPkgLibPath);
    UriResolver pkgResolver = new PackageMapUriResolver(provider, {
      'flutter': [myPkgFolder]
    });
    SourceFactory sourceFactory = new SourceFactory(
        [new DartUriResolver(sdk), pkgResolver, resourceResolver]);
    if (enableNewAnalysisDriver) {
      driver.configure(sourceFactory: sourceFactory);
    } else {
      context.sourceFactory = sourceFactory;
    }
    // force 'flutter' resolution
    addSource(
        '/tmp/other.dart',
        pathToCode.keys
            .map((path) => "import 'package:flutter/$path';")
            .join('\n'));
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

  Future<Null> findLint(String src, String lintCode, {int length: 1}) async {
    int errorOffset = src.indexOf('/*LINT*/');
    await resolveTestUnit(src.replaceAll('/*LINT*/', ''));
    error = new AnalysisError(
        resolutionMap.elementDeclaredByCompilationUnit(testUnit).source,
        errorOffset,
        length,
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

  test_removeTypeName_avoidAnnotatingWithDynamic_InsideFunctionTypedFormalParameter() async {
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

  test_removeTypeName_avoidAnnotatingWithDynamic_NamedParameter() async {
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

  test_removeTypeName_avoidAnnotatingWithDynamic_NormalParameter() async {
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

  test_removeTypeName_avoidAnnotatingWithDynamic_OptionalParameter() async {
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

  test_removeTypeName_avoidReturnTypesOnSetters_void() async {
    String src = '''
/*LINT*/void set speed2(int ms) {}
''';
    await findLint(src, LintNames.avoid_return_types_on_setters);

    await applyFix(DartFixKind.REMOVE_TYPE_NAME);

    verifyResult('''
set speed2(int ms) {}
''');
  }

  test_removeTypeName_avoidTypesOnClosureParameters_FunctionTypedFormalParameter() async {
    String src = '''
var functionWithFunction = (/*LINT*/int f(int x)) => f(0);
''';
    await findLint(src, LintNames.avoid_types_on_closure_parameters);

    await applyFix(DartFixKind.REPLACE_WITH_IDENTIFIER);

    verifyResult('''
var functionWithFunction = (f) => f(0);
''');
  }

  test_removeTypeName_avoidTypesOnClosureParameters_NamedParameter() async {
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

  test_removeTypeName_avoidTypesOnClosureParameters_NormalParameter() async {
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

  test_removeTypeName_avoidTypesOnClosureParameters_OptionalParameter() async {
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

class _DartFixContextImpl implements DartFixContext {
  @override
  final ResourceProvider resourceProvider;

  @override
  final AnalysisDriver analysisDriver;

  @override
  final AstProvider astProvider;

  @override
  final CompilationUnit unit;

  @override
  final AnalysisError error;

  _DartFixContextImpl(this.resourceProvider, this.analysisDriver,
      this.astProvider, this.unit, this.error);

  @override
  GetTopLevelDeclarations get getTopLevelDeclarations =>
      analysisDriver.getTopLevelNameDeclarations;
}
