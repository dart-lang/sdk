// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DiagnosticTest);
  });
}

@reflectiveTest
class DiagnosticTest extends AbstractLspAnalysisServerTest {
  test_afterDocumentEdits() async {
    const initialContents = 'int a = 1;';
    newFile(mainFilePath, content: initialContents);

    final firstDiagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    final initialDiagnostics = await firstDiagnosticsUpdate;
    expect(initialDiagnostics, hasLength(0));

    await openFile(mainFileUri, initialContents);

    final secondDiagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await replaceFile(222, mainFileUri, 'String a = 1;');
    final updatedDiagnostics = await secondDiagnosticsUpdate;
    expect(updatedDiagnostics, hasLength(1));
  }

  test_deletedFile() async {
    newFile(mainFilePath, content: 'String a = 1;');

    final firstDiagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    final originalDiagnostics = await firstDiagnosticsUpdate;
    expect(originalDiagnostics, hasLength(1));

    // Deleting the file should result in an update to remove the diagnostics.
    final secondDiagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await deleteFile(mainFilePath);
    final updatedDiagnostics = await secondDiagnosticsUpdate;
    expect(updatedDiagnostics, hasLength(0));
  }

  test_initialAnalysis() async {
    newFile(mainFilePath, content: 'String a = 1;');

    final diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    final diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));
    final diagnostic = diagnostics.first;
    expect(diagnostic.code, equals('invalid_assignment'));
    expect(diagnostic.range.start.line, equals(0));
    expect(diagnostic.range.start.character, equals(11));
    expect(diagnostic.range.end.line, equals(0));
    expect(diagnostic.range.end.character, equals(12));
  }
}
