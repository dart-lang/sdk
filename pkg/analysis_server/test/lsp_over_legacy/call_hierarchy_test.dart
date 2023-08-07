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
    defineReflectiveTests(CallHierarchyTest);
  });
}

@reflectiveTest
class CallHierarchyTest extends LspOverLegacyTest {
  Future<void> test_incoming() async {
    final content = '''
String f^() => 'f';
String g() => [!f!]();
''';
    final code = TestCode.parse(content);
    newFile(testFilePath, code.code);
    final prepareResults = await prepareCallHierarchy(
      testFileUri,
      code.position.position,
    );
    final prepareResult = prepareResults!.single;

    final incomingResults = await callHierarchyIncoming(prepareResult);
    final incomingResult = incomingResults!.single;

    expect(incomingResult.from.name, 'g');
    expect(incomingResult.fromRanges, code.ranges.ranges);
  }

  Future<void> test_outgoing() async {
    final content = '''
String f() => 'f';
String g^() => [!f!]();
''';
    final code = TestCode.parse(content);
    newFile(testFilePath, code.code);
    final prepareResults = await prepareCallHierarchy(
      testFileUri,
      code.position.position,
    );
    final prepareResult = prepareResults!.single;

    final outgoingResults = await callHierarchyOutgoing(prepareResult);
    final outgoingResult = outgoingResults!.single;

    expect(outgoingResult.to.name, 'f');
    expect(outgoingResult.fromRanges, code.ranges.ranges);
  }

  Future<void> test_prepare() async {
    final content = '''
void f^() {}
''';
    final code = TestCode.parse(content);
    newFile(testFilePath, code.code);
    final results = await prepareCallHierarchy(
      testFileUri,
      code.position.position,
    );
    final result = results!.single;

    expect(result.name, 'f');
  }
}
