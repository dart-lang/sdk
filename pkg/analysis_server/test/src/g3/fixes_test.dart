// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/g3/fixes.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(G3FixesTest);
  });
}

@reflectiveTest
class G3FixesTest with ResourceProviderMixin {
  Folder get sdkRoot => newFolder('/sdk');

  void setUp() {
    registerLintRules();
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );
  }

  Future<void> test_awaitOnlyFutures() async {
    await _assertHasLintFix(
      codeWithLint: r'''
void f() async {
  await 0;
}
''',
      lintName: LintNames.await_only_futures,
      fixedCode: r'''
void f() async {
  0;
}
''',
    );
  }

  Future<void> test_awaitOnlyFutures_inFile() async {
    await _assertHasLintFix(
      inFile: true,
      codeWithLint: r'''
void f() async {
  await 0;
  await 1;
}
''',
      lintName: LintNames.await_only_futures,
      fixedCode: r'''
void f() async {
  0;
  1;
}
''',
    );
  }

  Future<void> test_emptyCatches_noFinally() async {
    await _assertNoLintFix(
      codeWithLint: r'''
void f() {
  try {
  } catch (e) {}
}
''',
      lintName: LintNames.empty_catches,
    );
  }

  Future<void> test_emptyConstructorBodies() async {
    await _assertHasLintFix(
      codeWithLint: r'''
class C {
  C() {}
}
''',
      lintName: LintNames.empty_constructor_bodies,
      fixedCode: r'''
class C {
  C();
}
''',
    );
  }

  Future<void> test_invalid_moreThanOneDiagnostic() async {
    expect(() async {
      await _assertHasLintFix(
        codeWithLint: '0 1',
        lintName: LintNames.avoid_empty_else,
        fixedCode: '',
      );
    }, throwsStateError);
  }

  Future<void> test_invalid_noDiagnostics() async {
    expect(() async {
      await _assertHasLintFix(
        codeWithLint: '',
        lintName: LintNames.avoid_empty_else,
        fixedCode: '',
      );
    }, throwsStateError);
  }

  Future<void> test_invalid_notLint() async {
    expect(() async {
      await _assertHasLintFix(
        codeWithLint: '42',
        lintName: LintNames.avoid_empty_else,
        fixedCode: '',
      );
    }, throwsStateError);
  }

  Future<void> _assertHasLintFix({
    required String codeWithLint,
    required String lintName,
    required String fixedCode,
    bool inFile = false,
  }) async {
    _enableLint(lintName);

    var tester = LintFixTester(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
      packageConfigPath: null,
    );

    var path = convertPath('/home/test/lib/test.dart');
    tester.updateFile(
      path: path,
      content: codeWithLint,
    );

    var testerWithFixes = await tester.fixesForSingleLint(
      path: path,
      inFile: inFile,
    );

    var singleFix = testerWithFixes.assertSingleFix();
    singleFix.assertFixedContentOfFile(
      path: path,
      fixedContent: fixedCode,
    );
  }

  Future<void> _assertNoLintFix({
    required String codeWithLint,
    required String lintName,
    bool inFile = false,
  }) async {
    _enableLint(lintName);

    var tester = LintFixTester(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
      packageConfigPath: null,
    );

    var path = convertPath('/home/test/lib/test.dart');
    tester.updateFile(
      path: path,
      content: codeWithLint,
    );

    var testerWithFixes = await tester.fixesForSingleLint(
      path: path,
      inFile: inFile,
    );

    testerWithFixes.assertNoFixes();
  }

  void _enableLint(String lintName) {
    _writeAnalysisOptionsFile(
      lints: [lintName],
    );
  }

  /// Write an analysis options file based on the given arguments.
  /// TODO(scheglov) Use AnalysisOptionsFileConfig
  void _writeAnalysisOptionsFile({
    List<String>? lints,
  }) {
    var buffer = StringBuffer();

    if (lints != null) {
      buffer.writeln('linter:');
      buffer.writeln('  rules:');
      for (var lint in lints) {
        buffer.writeln('    - $lint');
      }
    }

    newFile('/home/test/analysis_options.yaml', content: buffer.toString());
  }
}
