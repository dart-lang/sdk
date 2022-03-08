// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/snippets/dart/dart_snippet_producers.dart';
import 'package:analysis_server/src/services/snippets/dart/snippet_manager.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../abstract_single_unit.dart';
import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartMainFunctionSnippetProducerTest);
  });
}

@reflectiveTest
class DartMainFunctionSnippetProducerTest extends DartSnippetProducerTest {
  @override
  final generator = DartMainFunctionSnippetProducer.newInstance;

  @override
  String get label => DartMainFunctionSnippetProducer.label;

  @override
  String get prefix => DartMainFunctionSnippetProducer.prefix;

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
        testFile,
        code: '$prefix^',
        expectArgsParameter: true,
      );

  Future<void> testInFile(
    String file, {
    String code = '^',
    required bool expectArgsParameter,
  }) async {
    testFile = file;
    final snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));
    code = withoutMarkers(code);
    snippet.change.edits
        .forEach((edit) => code = SourceEdit.applySequence(code, edit.edits));
    final expectedParams = expectArgsParameter ? 'List<String> args' : '';
    expect(code, '''
void main($expectedParams) {
  
}''');
    expect(snippet.change.selection!.file, file);
    expect(snippet.change.selection!.offset, 16 + expectedParams.length);
    expect(snippet.change.linkedEditGroups, isEmpty);
  }
}

abstract class DartSnippetProducerTest extends AbstractSingleUnitTest {
  SnippetProducerGenerator get generator;
  String get label;
  String get prefix;

  /// Override the package root because it usually contains /test/ and some
  /// snippets behave differently for test files.
  @override
  String get testPackageRootPath => '$workspaceRootPath/my_package';

  @override
  bool get verifyNoTestUnitErrors => false;

  Future<void> expectNotValidSnippet(
    String code,
  ) async {
    await resolveTestCode(withoutMarkers(code));
    final request = DartSnippetRequest(
      unit: testAnalysisResult,
      offset: offsetFromMarker(code),
    );

    final producer = generator(request);
    expect(await producer.isValid(), isFalse);
  }

  Future<Snippet> expectValidSnippet(String code) async {
    await resolveTestCode(withoutMarkers(code));
    final request = DartSnippetRequest(
      unit: testAnalysisResult,
      offset: offsetFromMarker(code),
    );

    final producer = generator(request);
    expect(await producer.isValid(), isTrue);
    return producer.compute();
  }
}
