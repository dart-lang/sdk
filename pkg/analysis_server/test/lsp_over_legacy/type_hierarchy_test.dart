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
    defineReflectiveTests(TypeHierarchyTest);
  });
}

@reflectiveTest
class TypeHierarchyTest extends LspOverLegacyTest {
  Future<void> test_incoming() async {
    final content = '''
class Ba^se {}
class [!Sub!] extends Base {}
''';
    final code = TestCode.parse(content);
    newFile(testFilePath, code.code);
    final prepareResults = await prepareTypeHierarchy(
      testFileUri,
      code.position.position,
    );
    final prepareResult = prepareResults!.single;

    final incomingResults = await typeHierarchySubtypes(prepareResult);
    final incomingResult = incomingResults!.single;

    expect(incomingResult.name, 'Sub');
    expect(incomingResult.selectionRange, code.range.range);
  }

  Future<void> test_outgoing() async {
    final content = '''
class [!Base!] {}
class Su^b extends Base {}
''';
    final code = TestCode.parse(content);
    newFile(testFilePath, code.code);
    final prepareResults = await prepareTypeHierarchy(
      testFileUri,
      code.position.position,
    );
    final prepareResult = prepareResults!.single;

    final outgoingResults = await typeHierarchySupertypes(prepareResult);
    final outgoingResult = outgoingResults!.single;

    expect(outgoingResult.name, 'Base');
    expect(outgoingResult.selectionRange, code.range.range);
  }

  Future<void> test_prepare() async {
    final content = '''
class A^ {}
''';
    final code = TestCode.parse(content);
    newFile(testFilePath, code.code);
    final results = await prepareTypeHierarchy(
      testFileUri,
      code.position.position,
    );
    final result = results!.single;

    expect(result.name, 'A');
  }
}
