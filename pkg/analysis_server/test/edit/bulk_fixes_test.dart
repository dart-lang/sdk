// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:linter/src/rules.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BulkFixesTest);
  });
}

@reflectiveTest
class BulkFixesTest extends AbstractAnalysisTest {
  void assertContains(List<BulkFix> details,
      {@required String path, @required String code, @required int count}) {
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

  Future<void> assertEditEquals(String expectedSource) async {
    await waitForTasksFinished();
    var edits = await _getBulkEdits();
    expect(edits, hasLength(1));
    var editedSource = SourceEdit.applySequence(testCode, edits[0].edits);
    expect(editedSource, expectedSource);
  }

  Future<void> assertNoEdits() async {
    await waitForTasksFinished();
    var edits = await _getBulkEdits();
    expect(edits, isEmpty);
  }

  @override
  void setUp() {
    super.setUp();
    registerLintRules();
    handler = EditDomainHandler(server);
    createProject();
  }

  Future<void> test_annotateOverrides_excludedFile() async {
    addAnalysisOptionsFile('''
analyzer:
  exclude:
    - test/**
linter:
  rules:
    - annotate_overrides
''');

    newFile('$projectPath/test/test.dart', content: '''
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
    addAnalysisOptionsFile('''
analyzer:
  exclude:
    - test/data/**
''');

    // Sub-project.
    var subprojectRoot = '$projectPath/test/data/subproject';
    newFile('$subprojectRoot/${AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE}',
        content: '''
linter:
  rules:
    - annotate_overrides
''');

    newFile('$subprojectRoot/${AnalysisEngine.PUBSPEC_YAML_FILE}', content: '''
name: subproject
''');

    newFile('$subprojectRoot/test.dart', content: '''
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
    var subprojectRoot = '$projectPath/test/data/subproject';
    newFile('$subprojectRoot/${AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE}',
        content: '''
linter:
  rules:
    - annotate_overrides
''');

    newFile('$subprojectRoot/${AnalysisEngine.PUBSPEC_YAML_FILE}', content: '''
name: subproject
''');

    testFile = '$subprojectRoot/test.dart';
    addTestFile('''
class A {
  void f() {}
}
class B extends A {
  void f() { }
}
''');

    await assertEditEquals('''
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
    addAnalysisOptionsFile('''
linter:
  rules:
    - annotate_overrides
    - unnecessary_new
''');

    var fileA = convertPath('$projectPath/a.dart');
    newFile(fileA, content: '''
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
        path: fileA, code: LintNames.unnecessary_new, count: 2);
    assertContains(details,
        path: fileA, code: LintNames.annotate_overrides, count: 1);
    assertContains(details,
        path: testFile, code: LintNames.unnecessary_new, count: 1);
  }

  Future<void> test_unnecessaryNew() async {
    addAnalysisOptionsFile('''
linter:
  rules:
    - unnecessary_new
''');
    addTestFile('''
class A {}
A f() => new A();
''');

    await assertEditEquals('''
class A {}
A f() => A();
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/44080')
  Future<void> test_unnecessaryNew_collectionLiteral_overlap() async {
    // The test case currently drops the 'new' but does not convert the code to
    // use a set literal. The code is no longer mangled, but we need to run the
    // BulkFixProcessor iteratively to solve the second case.
    if (Platform.isWindows) {
      fail('Should not be passing on Windows, but it does');
    }
    addAnalysisOptionsFile('''
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

    await assertEditEquals('''
class A {
  Map<String, Object> _map = {};
  Set<String> _set = <String>{};
}
''');
  }

  Future<void> test_unnecessaryNew_ignoredInOptions() async {
    addAnalysisOptionsFile('''
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
    addAnalysisOptionsFile('''
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
    var request = EditBulkFixesParams([projectPath]).toRequest('0');
    var response = await waitResponse(request);
    return EditBulkFixesResult.fromResponse(response);
  }
}
