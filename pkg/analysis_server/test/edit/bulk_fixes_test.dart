// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:linter/src/lint_names.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_server_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BulkFixesFromOptionsTest);
    defineReflectiveTests(BulkFixesFromCodesTest);
  });
}

@reflectiveTest
class BulkFixesFromCodesTest extends BulkFixesTest {
  Future<void> test_hint_checkWithNull() async {
    addDiagnosticCode('TYPE_CHECK_WITH_NULL');
    addTestFile('''
void f(p, q) {
  p is Null;
  q is Null;
}
''');

    await assertEditEquals(testFile, '''
void f(p, q) {
  p == null;
  q == null;
}
''');
  }

  Future<void> test_hint_checkWithNull_notSpecified() async {
    addDiagnosticCode('unnecessary_new');
    addTestFile('''
void f(p, q) {
  p is Null;
  q is Null;
}
''');

    await assertNoEdits();
  }

  Future<void> test_hint_unusedImport() async {
    addDiagnosticCode('unused_import');

    newFile('$testPackageLibPath/a.dart', '');

    addTestFile('''
import 'a.dart';
''');

    var details = await _getBulkFixDetails();
    expect(details, hasLength(1));
    var fixes = details.first.fixes;
    expect(fixes, hasLength(1));
    var fix = fixes.first;
    expect(fix.code, 'unused_import');
    expect(fix.occurrences, 1);
  }

  Future<void> test_hint_unusedImport_notSpecified() async {
    addDiagnosticCode('unnecessary_new');

    newFile('$testPackageLibPath/a.dart', '');

    addTestFile('''
import 'a.dart';

class A {
  A f() => new A();
}
''');

    var details = await _getBulkFixDetails();
    expect(details, isEmpty);
  }

  Future<void> test_lint_unnecessaryNew() async {
    newAnalysisOptionsYamlFile(testPackageRootPath, '''
linter:
  rules:
    - annotate_overrides
    - unnecessary_new
''');
    addDiagnosticCode('unnecessary_new');

    addTestFile('''
class A {
  A f() => new A();
}

class B extends A {
  A f() => new B();
}
''');

    var details = await _getBulkFixDetails();
    expect(details, hasLength(1));
    var fixes = details.first.fixes;
    expect(fixes, hasLength(1));
    var fix = fixes.first;
    expect(fix.code, 'unnecessary_new');
    expect(fix.occurrences, 2);
  }

  Future<void> test_lint_unnecessaryNew_ignoreCase() async {
    newAnalysisOptionsYamlFile(testPackageRootPath, '''
linter:
  rules:
    - annotate_overrides
    - unnecessary_new
''');
    addDiagnosticCode('UNNECESSARY_NEW');

    addTestFile('''
class A {
  A f() => new A();
}

class B extends A {
  A f() => new B();
}
''');

    var details = await _getBulkFixDetails();
    expect(details, hasLength(1));
    var fixes = details.first.fixes;
    expect(fixes, hasLength(1));
    var fix = fixes.first;
    expect(fix.code, 'unnecessary_new');
    expect(fix.occurrences, 2);
  }

  Future<void> test_undefinedDiagnostic() async {
    addDiagnosticCode('foo_bar');
    addTestFile('''
''');

    var result = await _getBulkFixes();
    expect(result.details, isEmpty);
    expect(
      result.message,
      "The diagnostic 'foo_bar' is not defined by the analyzer.",
    );
  }

  Future<void> test_undefinedDiagnostic_multiple() async {
    addDiagnosticCode('foo');
    addDiagnosticCode('bar');
    addDiagnosticCode('baz');

    addTestFile('''
''');

    var result = await _getBulkFixes();
    expect(result.details, isEmpty);
    expect(
      result.message,
      "The diagnostics 'foo', 'bar', and 'baz' are not defined by the analyzer.",
    );
  }
}

@reflectiveTest
class BulkFixesFromOptionsTest extends BulkFixesTest {
  Future<void> test_annotateOverrides_excludedFile() async {
    newAnalysisOptionsYamlFile(testPackageRootPath, '''
analyzer:
  exclude:
    - test/**
linter:
  rules:
    - annotate_overrides
''');

    newFile('$testPackageRootPath/test/test.dart', '''
class A {
  void f() {}
}
class B extends A {
  void f() {}
}
''');

    await assertNoEdits();
  }

  Future<void> test_annotateOverrides_excludedSubProject() async {
    // Root project.
    newAnalysisOptionsYamlFile(testPackageRootPath, '''
analyzer:
  exclude:
    - test/data/**
''');

    // Sub-project.
    var subprojectRoot = '$testPackageRootPath/test/data/subproject';
    newAnalysisOptionsYamlFile(subprojectRoot, '''
linter:
  rules:
    - annotate_overrides
''');

    newPubspecYamlFile(subprojectRoot, '''
name: subproject
''');

    newFile('$subprojectRoot/test.dart', '''
class A {
  void f() {}
}
class B extends A {
  void f() { }
}
''');

    await assertNoEdits();
  }

  Future<void> test_annotateOverrides_subProject() async {
    var subprojectRoot = '$testPackageRootPath/test/data/subproject';
    newAnalysisOptionsYamlFile(subprojectRoot, '''
linter:
  rules:
    - annotate_overrides
''');

    newPubspecYamlFile(subprojectRoot, '''
name: subproject
''');

    var file = newFile('$subprojectRoot/test.dart', '''
class A {
  void f() {}
}
class B extends A {
  void f() { }
}
''');

    await waitForTasksFinished();

    await assertEditEquals(file, '''
class A {
  void f() {}
}
class B extends A {
  @override
  void f() { }
}
''');
  }

  Future<void> test_details() async {
    newAnalysisOptionsYamlFile(testPackageRootPath, '''
linter:
  rules:
    - annotate_overrides
    - unnecessary_new
''');

    var a = newFile('$testPackageLibPath/a.dart', '''
class A {
  A f() => new A();
}
class B extends A {
  A f() => new B();
}
''');

    addTestFile('''
import 'a.dart';

A f() => new A();
''');

    var details = await _getBulkFixDetails();
    expect(details, hasLength(2));
    assertContains(
      details,
      path: a.path,
      code: LintNames.unnecessary_new,
      count: 2,
    );
    assertContains(
      details,
      path: a.path,
      code: LintNames.annotate_overrides,
      count: 1,
    );
    assertContains(
      details,
      path: testFile.path,
      code: LintNames.unnecessary_new,
      count: 1,
    );
  }

  Future<void> test_unnecessaryNew() async {
    newAnalysisOptionsYamlFile(testPackageRootPath, '''
linter:
  rules:
    - unnecessary_new
''');
    addTestFile('''
class A {}
A f() => new A();
''');

    await assertEditEquals(testFile, '''
class A {}
A f() => A();
''');
  }

  Future<void> test_unnecessaryNew_collectionLiteral_overlap() async {
    // The test case currently drops the 'new' but does not convert the code to
    // use a set literal. The code is no longer mangled, but we need to run the
    // BulkFixProcessor iteratively to solve the second case.
    newAnalysisOptionsYamlFile(testPackageRootPath, '''
linter:
  rules:
    - prefer_collection_literals
    - unnecessary_new
''');

    addTestFile('''
class A {
  Map<String, Object> _map = {};
  Set<String> _set = new Set<String>();
}
''');

    await assertEditEquals(testFile, '''
class A {
  Map<String, Object> _map = {};
  Set<String> _set = <String>{};
}
''');
  }

  Future<void> test_unnecessaryNew_ignoredInOptions() async {
    newAnalysisOptionsYamlFile(testPackageRootPath, '''
analyzer:
  errors:
    unnecessary_new: ignore
linter:
  rules:
    - unnecessary_new
''');
    addTestFile('''
class A {}
A f() => new A();
''');
    await assertNoEdits();
  }

  Future<void> test_unnecessaryNew_ignoredInSource() async {
    newAnalysisOptionsYamlFile(testPackageRootPath, '''
linter:
  rules:
    - unnecessary_new
''');
    addTestFile('''
class A {}
//ignore: unnecessary_new
A f() => new A();
''');
    await assertNoEdits();
  }

  Future<void> test_unnecessaryNew_macroGenerated() async {
    newAnalysisOptionsYamlFile(testPackageRootPath, '''
linter:
  rules:
    - unnecessary_new
''');
    var macroFilePath = join(testPackageLibPath, 'test.macro.dart');
    newFile(macroFilePath, '''
class A {}
A f() => new A();
''');
    await assertNoEdits();
  }
}

abstract class BulkFixesTest extends PubPackageAnalysisServerTest {
  List<String>? codes;

  void addDiagnosticCode(String code) {
    codes ??= <String>[];
    codes!.add(code);
  }

  void assertContains(
    List<BulkFix> details, {
    required String path,
    required String code,
    required int count,
  }) {
    for (var detail in details) {
      if (detail.path == path) {
        for (var fix in detail.fixes) {
          if (fix.code == code) {
            expect(fix.occurrences, count);
            return;
          }
        }
      }
    }
    fail('No match found for: $path:$code->$count in $details');
  }

  Future<void> assertEditEquals(File file, String expectedSource) async {
    await waitForTasksFinished();
    var edits = await _getBulkEdits();
    expect(edits, hasLength(1));
    var editedSource = SourceEdit.applySequence(
      file.readAsStringSync(),
      edits[0].edits,
    );
    expect(editedSource, expectedSource);
  }

  Future<void> assertNoEdits() async {
    await waitForTasksFinished();
    var edits = await _getBulkEdits();
    expect(edits, isEmpty);
  }

  @override
  Future<void> setUp() async {
    super.setUp();
    registerLintRules();
    registerBuiltInProducers();
    await setRoots(included: [workspaceRootPath], excluded: []);
  }

  Future<List<SourceFileEdit>> _getBulkEdits() async {
    var result = await _getBulkFixes();
    return result.edits;
  }

  Future<List<BulkFix>> _getBulkFixDetails() async {
    var result = await _getBulkFixes();
    return result.details;
  }

  Future<EditBulkFixesResult> _getBulkFixes() async {
    var request = _getRequest();
    var response = await handleSuccessfulRequest(request);
    return EditBulkFixesResult.fromResponse(
      response,
      clientUriConverter: server.uriConverter,
    );
  }

  Request _getRequest() => EditBulkFixesParams([
    workspaceRoot.path,
  ], codes: codes).toRequest('0', clientUriConverter: server.uriConverter);
}
