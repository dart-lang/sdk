// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/snippets/dart/if_statement.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IfStatementTest);
  });
}

@reflectiveTest
class IfStatementTest extends DartSnippetProducerTest {
  @override
  final generator = IfStatement.new;

  @override
  String get label => IfStatement.label;

  @override
  String get prefix => IfStatement.prefix;

  Future<void> test_if() async {
    var code = r'''
void f() {
  if^
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
  if (condition) {
    
  }
}''');
    expect(snippet.change.selection!.file, testFile.path);
    expect(snippet.change.selection!.offset, 34);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile.path, 'offset': 17},
        ],
        'length': 9,
        'suggestions': []
      }
    ]);
  }

  Future<void> test_if_indentedInsideBlock() async {
    var code = r'''
void f() {
  if (true) {
    if^
  }
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
  if (true) {
    if (condition) {
      
    }
  }
}''');
    expect(snippet.change.selection!.file, testFile.path);
    expect(snippet.change.selection!.offset, 52);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile.path, 'offset': 33},
        ],
        'length': 9,
        'suggestions': []
      }
    ]);
  }
}
