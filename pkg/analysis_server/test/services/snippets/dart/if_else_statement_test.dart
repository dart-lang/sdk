// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/snippets/dart/if_else_statement.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IfElseStatementTest);
  });
}

@reflectiveTest
class IfElseStatementTest extends DartSnippetProducerTest {
  @override
  final generator = IfElseStatement.new;

  @override
  String get label => IfElseStatement.label;

  @override
  String get prefix => IfElseStatement.prefix;

  Future<void> test_ifElse() async {
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
    
  } else {
    
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

  Future<void> test_ifElse_indentedInsideBlock() async {
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
      
    } else {
      
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
