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
    var content = '''
class Ba^se {}
class [!Sub!] extends Base {}
''';
    var code = TestCode.parse(content);
    newFile(testFilePath, code.code);
    var prepareResults = await prepareTypeHierarchy(
      testFileUri,
      code.position.position,
    );
    var prepareResult = prepareResults!.single;

    var incomingResults = await typeHierarchySubtypes(prepareResult);
    var incomingResult = incomingResults!.single;

    expect(incomingResult.name, 'Sub');
    expect(incomingResult.selectionRange, code.range.range);
  }

  Future<void> test_outgoing() async {
    var content = '''
class [!Base!] {}
class Su^b extends Base {}
''';
    var code = TestCode.parse(content);
    newFile(testFilePath, code.code);
    var prepareResults = await prepareTypeHierarchy(
      testFileUri,
      code.position.position,
    );
    var prepareResult = prepareResults!.single;

    var outgoingResults = await typeHierarchySupertypes(prepareResult);
    var outgoingResult = outgoingResults!.single;

    expect(outgoingResult.name, 'Base');
    expect(outgoingResult.selectionRange, code.range.range);
  }

  Future<void> test_prepare() async {
    var content = '''
class A^ {}
''';
    var code = TestCode.parse(content);
    newFile(testFilePath, code.code);
    var results = await prepareTypeHierarchy(
      testFileUri,
      code.position.position,
    );
    var result = results!.single;

    expect(result.name, 'A');
  }
}
