// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/snippets/dart/main_function.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MainFunctionTest);
  });
}

@reflectiveTest
class MainFunctionTest extends DartSnippetProducerTest {
  @override
  final generator = MainFunction.new;

  @override
  String get label => MainFunction.label;

  @override
  String get prefix => MainFunction.prefix;

  Future<void> test_noParams_testFolder() => testInFile(
        convertPath('$testPackageLibPath/test/foo_test.dart'),
        expectArgsParameter: false,
      );

  Future<void> test_params_binFolder() => testInFile(
        convertPath('$testPackageLibPath/bin/main.dart'),
        expectArgsParameter: true,
      );

  Future<void> test_params_projectRoot() => testInFile(
        convertPath('$testPackageRootPath/foo.dart'),
        expectArgsParameter: true,
      );

  Future<void> test_params_toolFolder() => testInFile(
        convertPath('$testPackageLibPath/tool/tool.dart'),
        expectArgsParameter: true,
      );

  Future<void> test_typedPrefix() => testInFile(
        testFile.path,
        code: '$prefix^',
        expectArgsParameter: true,
      );

  Future<void> testInFile(
    String file, {
    String code = '^',
    required bool expectArgsParameter,
  }) async {
    testFilePath = file;
    final snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));
    code = withoutMarkers(code);
    for (var edit in snippet.change.edits) {
      code = SourceEdit.applySequence(code, edit.edits);
    }
    final expectedParams = expectArgsParameter ? 'List<String> args' : '';
    expect(code, '''
void main($expectedParams) {
  
}''');
    expect(snippet.change.selection!.file, file);
    expect(snippet.change.selection!.offset, 16 + expectedParams.length);
    expect(snippet.change.linkedEditGroups, isEmpty);
  }
}
