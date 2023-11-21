// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../utils/test_code_extensions.dart';
import 'integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DiagnosticTest);
  });
}

@reflectiveTest
class DiagnosticTest extends AbstractLspAnalysisServerIntegrationTest {
  Future<void> test_contextMessage() async {
    final code = TestCode.parse('''
void f() {
  x = 0;
  int [!x!] = 1;
  print(x);
}
''');
    newFile(mainFilePath, code.code);

    final diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    final diagnostics = (await diagnosticsUpdate)!;

    expect(diagnostics, hasLength(1));
    final diagnostic = diagnostics.first;
    expect(
        diagnostic.message,
        startsWith(
            "Local variable 'x' can't be referenced before it is declared"));

    final relatedInformation = diagnostic.relatedInformation!;
    expect(relatedInformation, hasLength(1));
    final relatedInfo = relatedInformation.first;
    expect(relatedInfo.message, equals("The declaration of 'x' is here."));
    expect(relatedInfo.location.uri, equals(mainFileUri));
    expect(relatedInfo.location.range, equals(code.range.range));
  }

  Future<void> test_initialAnalysis() async {
    newFile(mainFilePath, 'String a = 1;');

    final diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    final diagnostics = (await diagnosticsUpdate)!;
    expect(diagnostics, hasLength(1));
    final diagnostic = diagnostics.first;
    expect(diagnostic.code, equals('invalid_assignment'));
    expect(diagnostic.range.start.line, equals(0));
    expect(diagnostic.range.start.character, equals(11));
    expect(diagnostic.range.end.line, equals(0));
    expect(diagnostic.range.end.character, equals(12));
  }

  Future<void> test_lints() async {
    newFile(mainFilePath, '''void f() async => await 1;''');
    newFile(analysisOptionsPath, '''
linter:
  rules:
    - await_only_futures
    ''');

    final diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    final diagnostics = (await diagnosticsUpdate)!;
    expect(diagnostics, hasLength(1));
    final diagnostic = diagnostics.first;
    expect(diagnostic.code, equals('await_only_futures'));
    expect(diagnostic.range.start.line, equals(0));
    expect(diagnostic.range.start.character, equals(18));
    expect(diagnostic.range.end.line, equals(0));
    expect(diagnostic.range.end.character, equals(23));
  }

  /// Ensure we get diagnostics for a project even if the workspace contains
  /// another folder that does not exist.
  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/54116')
  Future<void> test_workspaceFolders_existsAndDoesNotExist() async {
    if (!Platform.isWindows) {
      // IF THIS TEST STARTS FAILING...
      //
      // This test is (at the time of writing) expected to fail on Windows. It
      // passes on other platforms so we explicitly fail here for consistency.
      //
      // If the Windows bot start failing (because the issue is fixed and the
      // test is now passing on Windows), this conditional code block should be
      // removed, along with the .timeout() further down.
      fail('Forced failure for non-Windows so we can detect when the Windows '
          'issue is fixed');
    }

    final rootPath = projectFolderUri.toFilePath();
    final existingFolderUri = Uri.file(pathContext.join(rootPath, 'exists'));
    final existingFileUri =
        Uri.file(pathContext.join(rootPath, 'exists', 'main.dart'));
    final nonExistingFolderUri =
        Uri.file(pathContext.join(rootPath, 'does_not_exist'));

    newFolder(existingFolderUri.toFilePath());
    newFile(existingFileUri.toFilePath(), 'NotAClass a;');

    final diagnosticsFuture = waitForDiagnostics(existingFileUri);

    await initialize(
        workspaceFolders: [existingFolderUri, nonExistingFolderUri]);

    // The .timeout() is to ensure this test fails in a way that @FailingTest
    //  supports and does not just time out. This timeout should be removed
    //  when the test is passing.
    final diagnostics =
        await diagnosticsFuture.timeout(const Duration(seconds: 10));
    expect(diagnostics, hasLength(1));
    expect(diagnostics!.single.code, 'undefined_class');
  }
}
