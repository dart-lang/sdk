// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(HoverTest);
  });
}

@reflectiveTest
class HoverTest extends LspOverLegacyTest {
  Future<void> expectHover(String content, String expected) async {
    final code = TestCode.parse(content);
    newFile(testFilePath, code.code);
    await waitForTasksFinished();

    final result = await getHover(testFileUri, code.position.position);
    final markup = _getMarkupContents(result!);
    expect(markup.kind, MarkupKind.Markdown);
    expect(markup.value.trimRight(), expected.trimRight());
    expect(result.range, code.range.range);
  }

  Future<void> test_class_constructor_named() async {
    await expectHover(
      r'''
/// This is my class.
class [!A^aa!] {}
''',
      r'''
```dart
class Aaa
```
*package:test/test.dart*

---
This is my class.
''',
    );
  }

  MarkupContent _getMarkupContents(Hover hover) {
    return hover.contents.map(
      (t1) => t1,
      (t2) => throw 'Hover contents were String, not MarkupContent',
    );
  }
}
