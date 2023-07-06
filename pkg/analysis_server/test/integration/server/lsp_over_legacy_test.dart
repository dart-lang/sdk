// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../utils/test_code_extensions.dart';
import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LspOverLegacyTest);
  });
}

@reflectiveTest
class LspOverLegacyTest extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_hover() async {
    final testFile = sourcePath('lib/test.dart');
    final code = TestCode.parse('''
/// This is my class.
class [!A^aa!] {}
''');

    writeFile(testFile, code.code);
    await standardAnalysisSetup();
    await analysisFinished;

    final result = await _sendHover(
      HoverParams(
        position: code.position.position,
        textDocument: TextDocumentIdentifier(uri: Uri.file(testFile)),
      ),
    );

    expect(result.range, code.range.range);
    _expectMarkdown(
      result.contents,
      '''
```dart
class Aaa
```
*package:test/test.dart*

---
This is my class.
''',
    );
  }

  void _expectMarkdown(
    Either2<MarkupContent, String> contents,
    String expected,
  ) {
    final markup = contents.map(
      (t1) => t1,
      (t2) => throw 'Hover contents were String, not MarkupContent',
    );

    expect(markup.kind, MarkupKind.Markdown);
    expect(markup.value.trimRight(), expected.trimRight());
  }

  Future<Hover> _sendHover(HoverParams params) async {
    final response = await server.send(
      Method.textDocument_hover.toString(),
      params.toJson(),
    );

    return Hover.fromJson(response!);
  }
}
