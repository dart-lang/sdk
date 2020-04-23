// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DiagnosticTest);
  });
}

@reflectiveTest
class DiagnosticTest extends AbstractLspAnalysisServerIntegrationTest {
  Future<void> test_initialAnalysis() async {
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

  Future<void> test_lints() async {
    newFile(mainFilePath, content: '''main() async => await 1;''');
    newFile(analysisOptionsPath, content: '''
linter:
  rules:
    - await_only_futures
    ''');

    final diagnosticsUpdate = waitForDiagnostics(mainFileUri);
    await initialize();
    final diagnostics = await diagnosticsUpdate;
    expect(diagnostics, hasLength(1));
    final diagnostic = diagnostics.first;
    expect(diagnostic.code, equals('await_only_futures'));
    expect(diagnostic.range.start.line, equals(0));
    expect(diagnostic.range.start.character, equals(16));
    expect(diagnostic.range.end.line, equals(0));
    expect(diagnostic.range.end.character, equals(21));
  }
}
