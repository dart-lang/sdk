// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_server_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BulkFixesTest);
  });
}

@reflectiveTest
class BulkFixesTest extends PubPackageAnalysisServerTest {
  void assertContains(List<BulkFix> details,
      {required String path, required String code, required int count}) {
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
    var editedSource =
        SourceEdit.applySequence(file.readAsStringSync(), edits[0].edits);
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
    await setRoots(included: [workspaceRootPath], excluded: []);
  }

  Future<void> test_annotateOverrides_excludedFile() async {
    newAnalysisOptionsYamlFile2(testPackageRootPath, '''
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
    newAnalysisOptionsYamlFile2(testPackageRootPath, '''
analyzer:
  exclude:
    - test/data/**
''');

    // Sub-project.
    var subprojectRoot = '$testPackageRootPath/test/data/subproject';
    newAnalysisOptionsYamlFile2(subprojectRoot, '''
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
    newAnalysisOptionsYamlFile2(subprojectRoot, '''
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
    newAnalysisOptionsYamlFile2(testPackageRootPath, '''
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
    assertContains(details,
        path: a.path, code: LintNames.unnecessary_new, count: 2);
    assertContains(details,
        path: a.path, code: LintNames.annotate_overrides, count: 1);
    assertContains(details,
        path: testFile.path, code: LintNames.unnecessary_new, count: 1);
  }

  Future<void> test_unnecessaryNew() async {
    newAnalysisOptionsYamlFile2(testPackageRootPath, '''
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
    newAnalysisOptionsYamlFile2(testPackageRootPath, '''
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
    newAnalysisOptionsYamlFile2(testPackageRootPath, '''
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
    newAnalysisOptionsYamlFile2(testPackageRootPath, '''
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

  Future<List<SourceFileEdit>> _getBulkEdits() async {
    var result = await _getBulkFixes();
    return result.edits;
  }

  Future<List<BulkFix>> _getBulkFixDetails() async {
    var result = await _getBulkFixes();
    return result.details;
  }

  Future<EditBulkFixesResult> _getBulkFixes() async {
    // TODO(scheglov) Remove this, we want to see if lines change.
    var request = EditBulkFixesParams([workspaceRoot.path]).toRequest('0');
    var response = await handleSuccessfulRequest(request);
    return EditBulkFixesResult.fromResponse(response);
  }
}
