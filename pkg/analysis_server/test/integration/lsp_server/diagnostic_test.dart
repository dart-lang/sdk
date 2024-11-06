// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  @override
  Future<void> setUp() async {
    await super.setUp();

    // These tests deliberately generate diagnostics.
    failTestOnErrorDiagnostic = false;
  }

  Future<void> test_contextMessage() async {
    var code = TestCode.parse('''
void f() {
  x = 0;
  int [!x!] = 1;
  print(x);
}
''');
    newFile(mainFilePath, code.code);

    var diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    var diagnostics = (await diagnosticsUpdate)!;

    expect(diagnostics, hasLength(1));
    var diagnostic = diagnostics.first;
    expect(
      diagnostic.message,
      startsWith(
        "Local variable 'x' can't be referenced before it is declared",
      ),
    );

    var relatedInformation = diagnostic.relatedInformation!;
    expect(relatedInformation, hasLength(1));
    var relatedInfo = relatedInformation.first;
    expect(relatedInfo.message, equals("The declaration of 'x' is here."));
    expect(relatedInfo.location.uri, equals(mainFileUri));
    expect(relatedInfo.location.range, equals(code.range.range));
  }

  Future<void> test_initialAnalysis() async {
    newFile(mainFilePath, 'String a = 1;');

    var diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    var diagnostics = (await diagnosticsUpdate)!;
    expect(diagnostics, hasLength(1));
    var diagnostic = diagnostics.first;
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

    var diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    var diagnostics = (await diagnosticsUpdate)!;
    expect(diagnostics, hasLength(1));
    var diagnostic = diagnostics.first;
    expect(diagnostic.code, equals('await_only_futures'));
    expect(diagnostic.range.start.line, equals(0));
    expect(diagnostic.range.start.character, equals(18));
    expect(diagnostic.range.end.line, equals(0));
    expect(diagnostic.range.end.character, equals(23));
  }

  /// Ensure we get diagnostics for a project even if the workspace contains
  /// another folder that does not exist.
  Future<void> test_workspaceFolders_existsAndDoesNotExist() async {
    var rootPath = projectFolderUri.toFilePath();
    var existingFolderUri = Uri.file(pathContext.join(rootPath, 'exists'));
    var existingFileUri = Uri.file(
      pathContext.join(rootPath, 'exists', 'main.dart'),
    );
    var nonExistingFolderUri = Uri.file(
      pathContext.join(rootPath, 'does_not_exist'),
    );

    newFolder(existingFolderUri.toFilePath());
    newFile(existingFileUri.toFilePath(), 'NotAClass a;');

    var diagnosticsFuture = waitForDiagnostics(existingFileUri);

    await initialize(
      workspaceFolders: [existingFolderUri, nonExistingFolderUri],
    );

    var diagnostics = await diagnosticsFuture;
    expect(diagnostics, hasLength(1));
    expect(diagnostics!.single.code, 'undefined_class');
  }
}
