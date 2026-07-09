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
  void createDefaultFiles() {
    super.createDefaultFiles();
    writeTestPackageConfig(flutter: true);
  }

  Future<void> test_color() async {
    var content = '''
import 'package:flutter/material.dart';

const red = [!Colors.red!];
''';
    var code = TestCode.parse(content);
    newFile(testFilePath, code.code);
    var results = await getDocumentColors(testFileUri);
    var result = results.single;

    // Material red primary value is 0xFFF44336.
    expect(result.color.alpha, equals(1));
    expect(result.color.red, inInclusiveRange(0xF3 / 0xFF, 0xF5 / 0xFF));
    expect(result.color.green, inInclusiveRange(0x42 / 0xFF, 0x44 / 0xFF));
    expect(result.color.blue, inInclusiveRange(0x35 / 0xFF, 0x37 / 0xFF));
    expect(result.range, code.range.range);
  }

  Future<void> test_presentation() async {
    var content = '''
import 'package:flutter/material.dart';

const red = [!Colors.red!];
''';
    var code = TestCode.parse(content);
    newFile(testFilePath, code.code);
    var colorResults = await getDocumentColors(testFileUri);
    var colorResult = colorResults.single;

    var colors = await getColorPresentation(
      testFileUri,
      code.range.range,
      colorResult.color,
    );
    expect(
      colors.map((c) => c.label),
      containsAll([
        'Color.fromARGB(255, 244, 67, 54)',
        'Color.fromRGBO(244, 67, 54, 1.0)',
        'Color(0xFFF44336)',
      ]),
    );
  }
}
