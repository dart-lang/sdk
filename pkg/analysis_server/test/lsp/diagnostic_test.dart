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

    await initialize();
    final initialDiagnostics = await waitForDiagnostics(mainFileUri);
    expect(initialDiagnostics, hasLength(0));

    await openFile(mainFileUri, initialContents);
    await replaceFile(222, mainFileUri, 'String a = 1;');
    final updatedDiagnostics = await waitForDiagnostics(mainFileUri);
    expect(updatedDiagnostics, hasLength(1));
  }

  test_initialAnalysis() async {
    newFile(mainFilePath, content: 'String a = 1;');

    await initialize();
    final diagnostics = await waitForDiagnostics(mainFileUri);
    expect(diagnostics, hasLength(1));
    final diagnostic = diagnostics.first;
    expect(diagnostic.code, equals('invalid_assignment'));
    expect(diagnostic.range.start.line, equals(0));
    expect(diagnostic.range.start.character, equals(11));
    expect(diagnostic.range.end.line, equals(0));
    expect(diagnostic.range.end.character, equals(12));
  }
}
