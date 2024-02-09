// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/snippets/dart/switch_statement.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SwitchStatementTest);
  });
}

@reflectiveTest
class SwitchStatementTest extends DartSnippetProducerTest {
  @override
  final generator = SwitchStatement.new;

  @override
  String get label => SwitchStatement.label;

  @override
  String get prefix => SwitchStatement.prefix;

  Future<void> test_switch() async {
    final code = TestCode.parse(r'''
void f() {
  sw^
}
''');
    final snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));
    var result = code.code;
    for (var edit in snippet.change.edits) {
      result = SourceEdit.applySequence(result, edit.edits);
    }
    expect(result, '''
void f() {
  switch (expression) {
    case value:
      
      break;
    default:
  }
}
''');
    expect(snippet.change.selection!.file, testFile.path);
    expect(snippet.change.selection!.offset, 57);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      // expression
      {
        'positions': [
          {'file': testFile.path, 'offset': 21},
        ],
        'length': 10,
        'suggestions': []
      },
      // value
      {
        'positions': [
          {'file': testFile.path, 'offset': 44},
        ],
        'length': 5,
        'suggestions': []
      },
    ]);
  }

  Future<void> test_switch_indentedInsideBlock() async {
    final code = TestCode.parse(r'''
void f() {
  if (true) {
    sw^
  }
}
''');
    final snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));
    var result = code.code;
    for (var edit in snippet.change.edits) {
      result = SourceEdit.applySequence(result, edit.edits);
    }
    expect(result, '''
void f() {
  if (true) {
    switch (expression) {
      case value:
        
        break;
      default:
    }
  }
}
''');
    expect(snippet.change.selection!.file, testFile.path);
    expect(snippet.change.selection!.offset, 77);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      // expression
      {
        'positions': [
          {'file': testFile.path, 'offset': 37},
        ],
        'length': 10,
        'suggestions': []
      },
      // value
      {
        'positions': [
          {'file': testFile.path, 'offset': 62},
        ],
        'length': 5,
        'suggestions': []
      },
    ]);
  }
}
