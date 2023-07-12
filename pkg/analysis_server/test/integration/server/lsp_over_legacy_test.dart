// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../lsp/request_helpers_mixin.dart';
import '../../utils/test_code_extensions.dart';
import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LspOverLegacyTest);
  });
}

@reflectiveTest
class LspOverLegacyTest extends AbstractAnalysisServerIntegrationTest
    with LspRequestHelpersMixin {
  @override
  Future<T> expectSuccessfulResponseTo<T, R>(
      RequestMessage request, T Function(R) fromJson) async {
    final resp = await server.send(
      request.method.toString(),
      specToJson(request.params) as Map<String, Object?>,
    );
    return fromJson(resp as R);
  }

  Future<void> test_error() async {
    // This file will not be created.
    final testFile = sourcePath('lib/test.dart');
    await standardAnalysisSetup();
    await analysisFinished;

    try {
      await getHover(Uri.file(testFile), Position(character: 0, line: 0));
      fail('expected INVALID_REQUEST');
    } on ServerErrorMessage catch (message) {
      expect(message.error['code'], 'INVALID_REQUEST');
      expect(message.error['message'], 'File does not exist');
    }
  }

  Future<void> test_hover() async {
    final testFile = sourcePath('lib/test.dart');
    final code = TestCode.parse('''
/// This is my class.
class [!A^aa!] {}
''');

    writeFile(testFile, code.code);
    await standardAnalysisSetup();
    await analysisFinished;

    final result = await getHover(Uri.file(testFile), code.position.position);

    expect(result!.range, code.range.range);
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
}
