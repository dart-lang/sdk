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
}
