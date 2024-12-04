// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../tool/lsp_spec/matchers.dart';
import '../../utils/test_code_extensions.dart';
import '../support/integration_tests.dart';
import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LspOverLegacyRequestTest);
  });
}

/// Integration tests for sending LSP requests over the Legacy protocol.
///
/// These tests are slow (each test spawns an out-of-process server) so these
/// tests are intended only to ensure the basic functionality is available and
/// not to test all handlers/functionality already covered by LSP tests.
///
/// Additional tests (to verify each expected LSP handler is available over
/// Legacy) are in `test/lsp_over_legacy/` and tests for all handler
/// functionality are in `test/lsp`.
@reflectiveTest
class LspOverLegacyRequestTest extends AbstractLspOverLegacyTest {
  Future<void> test_error_invalidLspRequest() async {
    await standardAnalysisSetup();
    await analysisFinished;

    try {
      await sendLspHandle({'id': '1'});
      fail('expected INVALID_PARAMETER');
    } on ServerErrorMessage catch (message) {
      expect(message.error['code'], 'INVALID_PARAMETER');
      expect(
        message.error['message'],
        "The 'lspMessage' parameter was not a valid LSP request:\n"
        'jsonrpc must not be undefined',
      );
    }
  }

  Future<void> test_error_lspHandlerError() async {
    // testFile will not be created.
    await standardAnalysisSetup();
    await analysisFinished;

    await expectLater(
      getHover(testFileUri, Position(character: 0, line: 0)),
      throwsA(
        isResponseError(
          ServerErrorCodes.InvalidFilePath,
          message: 'File does not exist',
        ),
      ),
    );
  }

  Future<void> test_format() async {
    const content = 'void     main() {}';
    const expectedContent = 'void main() {}';
    writeFile(testFile, content);
    await standardAnalysisSetup();
    await analysisFinished;

    var edits = await formatDocument(testFileUri);
    var formattedContents = applyTextEdits(content, edits!);
    expect(formattedContents.trimRight(), equals(expectedContent));
  }

  Future<void> test_hover() async {
    var code = TestCode.parse('''
/// This is my class.
class [!A^aa!] {}
''');

    writeFile(testFile, code.code);
    await standardAnalysisSetup();
    await analysisFinished;

    var result = await getHover(testFileUri, code.position.position);

    expect(result!.range, code.range.range);
    expectMarkdown(result.contents, '''
```dart
class Aaa
```
*package:test/test.dart*

---
This is my class.
''');
  }

  /// Tests the protocol using JSON instead of helpers.
  ///
  /// This is to verify (and document) the exact payloads for  `lsp.handle`
  /// in a way that is not abstracted by (or affected by refactors to) helper
  /// methods to ensure this never changes in a way that will affect clients.
  Future<void> test_hover_rawProtocol() async {
    var code = TestCode.parse('''
/// This is my class.
class [!A^aa!] {}
''');

    const expectedHover = '''
```dart
class Aaa
```
*package:test/test.dart*

---
This is my class.''';

    writeFile(testFile, code.code);
    await standardAnalysisSetup();
    await analysisFinished;

    var response = await server.send('lsp.handle', {
      'lspMessage': {
        'jsonrpc': '2.0',
        'id': '12345',
        'method': Method.textDocument_hover.toString(),
        'params': {
          'textDocument': {'uri': testFileUri.toString()},
          'position': code.position.position.toJson(),
        },
      },
    });

    expect(response, {
      'lspResponse': {
        'id': '12345',
        'jsonrpc': '2.0',
        'result': {
          'contents': {'kind': 'markdown', 'value': expectedHover},
          'range': code.range.range.toJson(),
        },
      },
    });
  }
}
