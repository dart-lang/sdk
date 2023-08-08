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
    defineReflectiveTests(TypeDefinitionTest);
  });
}

@reflectiveTest
class TypeDefinitionTest extends LspOverLegacyTest {
  Future<void> test_typeDefinition() async {
    final content = '''
class [!A!] {}

final a^ = A();
''';
    final code = TestCode.parse(content);
    newFile(testFilePath, code.code);
    final results = await getTypeDefinitionAsLocation(
      testFileUri,
      code.position.position,
    );
    final result = results.single;

    expect(result.range, code.range.range);
    expect(result.uri, testFileUri);
  }
}
