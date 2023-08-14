// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/snippets/dart/test_group_definition.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TestGroupDefinitionTest);
  });
}

@reflectiveTest
class TestGroupDefinitionTest extends DartSnippetProducerTest {
  @override
  final generator = TestGroupDefinition.new;

  @override
  String get label => TestGroupDefinition.label;

  @override
  String get prefix => TestGroupDefinition.prefix;

  Future<void> test_inTestFile() async {
    testFilePath = convertPath('$testPackageLibPath/test/foo_test.dart');
    var code = r'''
void f() {
  group^
}''';
    final snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));
    code = withoutMarkers(code);
    for (var edit in snippet.change.edits) {
      code = SourceEdit.applySequence(code, edit.edits);
    }
    expect(code, '''
void f() {
  group('group name', () {
    
  });
}''');
    expect(snippet.change.selection!.file, testFile.path);
    expect(snippet.change.selection!.offset, 42);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile.path, 'offset': 20},
        ],
        'length': 10,
        'suggestions': []
      }
    ]);
  }

  Future<void> test_notTestFile() async {
    var code = r'''
void f() {
  group^
}''';
    await expectNotValidSnippet(code);
  }
}
