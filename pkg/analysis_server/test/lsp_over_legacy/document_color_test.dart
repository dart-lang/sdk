// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocumentColorTest);
  });
}

@reflectiveTest
class DocumentColorTest extends LspOverLegacyTest {
  @override
  Future<void> setUp() async {
    await super.setUp();
    writeTestPackageConfig(flutter: true);
  }

  Future<void> test_color() async {
    final content = '''
import 'package:flutter/material.dart';

const red = [!Colors.red!];
''';
    final code = TestCode.parse(content);
    newFile(testFilePath, code.code);
    final results = await getDocumentColors(testFileUri);
    final result = results.single;

    expect(result.color.alpha, 1);
    expect(result.color.red, 1);
    expect(result.color.green, 0);
    expect(result.color.blue, 0);
    expect(result.range, code.range.range);
  }

  Future<void> test_presentation() async {
    final content = '''
import 'package:flutter/material.dart';

const red = [!Colors.red!];
''';
    final code = TestCode.parse(content);
    newFile(testFilePath, code.code);
    final colorResults = await getDocumentColors(testFileUri);
    final colorResult = colorResults.single;

    final colors = await getColorPresentation(
        testFileUri, code.range.range, colorResult.color);
    expect(
      colors.map((c) => c.label),
      containsAll([
        'Color.fromARGB(255, 255, 0, 0)',
        'Color.fromRGBO(255, 0, 0, 1.0)',
        'Color(0xFFFF0000)',
      ]),
    );
  }
}
