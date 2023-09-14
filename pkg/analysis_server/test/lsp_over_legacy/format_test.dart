// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FormatTest);
  });
}

@reflectiveTest
class FormatTest extends LspOverLegacyTest {
  Future<void> test_format() async {
    const content = 'void     main() {}';
    const expectedContent = 'void main() {}';
    newFile(testFilePath, content);
    await waitForTasksFinished();

    final edits = await formatDocument(testFileUri);
    final formattedContents = applyTextEdits(content, edits!);
    expect(formattedContents.trimRight(), equals(expectedContent));
  }

  Future<void> test_formatOnType() async {
    const content = 'void     main() {}';
    const expectedContent = 'void main() {}';
    newFile(testFilePath, content);
    await waitForTasksFinished();

    final edits = await formatOnType(testFileUri, startOfDocPos, '}');
    final formattedContents = applyTextEdits(content, edits!);
    expect(formattedContents.trimRight(), equals(expectedContent));
  }

  Future<void> test_formatRange() async {
    const content = 'void     main() {}';
    const expectedContent = 'void main() {}';
    newFile(testFilePath, content);
    await waitForTasksFinished();

    final edits = await formatRange(testFileUri, entireRange(content));
    final formattedContents = applyTextEdits(content, edits!);
    expect(formattedContents.trimRight(), equals(expectedContent));
  }
}
