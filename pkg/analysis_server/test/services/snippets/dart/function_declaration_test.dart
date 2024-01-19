// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/snippets/dart/function_declaration.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionDeclarationTest);
  });
}

@reflectiveTest
class FunctionDeclarationTest extends DartSnippetProducerTest {
  @override
  final generator = FunctionDeclaration.new;

  @override
  String get label => FunctionDeclaration.label;

  @override
  String get prefix => FunctionDeclaration.prefix;

  Future<void> test_classMethod() async {
    final code = TestCode.parse(r'''
class A {
  ^
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
class A {
  void name(params) {
    
  }
}
''');
    expect(snippet.change.selection!.file, testFile.path);
    expect(snippet.change.selection!.offset, 36);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile.path, 'offset': 12},
        ],
        'length': 4,
        'suggestions': []
      },
      {
        'positions': [
          {'file': testFile.path, 'offset': 17},
        ],
        'length': 4,
        'suggestions': []
      },
      {
        'positions': [
          {'file': testFile.path, 'offset': 22},
        ],
        'length': 6,
        'suggestions': []
      },
    ]);
  }

  Future<void> test_nested() async {
    final code = TestCode.parse(r'''
void a() {
  ^
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
void a() {
  void name(params) {
    
  }
}
''');
    expect(snippet.change.selection!.file, testFile.path);
    expect(snippet.change.selection!.offset, 37);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile.path, 'offset': 13},
        ],
        'length': 4,
        'suggestions': []
      },
      {
        'positions': [
          {'file': testFile.path, 'offset': 18},
        ],
        'length': 4,
        'suggestions': []
      },
      {
        'positions': [
          {'file': testFile.path, 'offset': 23},
        ],
        'length': 6,
        'suggestions': []
      },
    ]);
  }

  Future<void> test_topLevel() async {
    final code = TestCode.parse(r'''
class A {}
  
^

class B {}
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
class A {}
  
void name(params) {
  
}

class B {}
''');
    expect(snippet.change.selection!.file, testFile.path);
    expect(snippet.change.selection!.offset, 36);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile.path, 'offset': 14},
        ],
        'length': 4,
        'suggestions': []
      },
      {
        'positions': [
          {'file': testFile.path, 'offset': 19},
        ],
        'length': 4,
        'suggestions': []
      },
      {
        'positions': [
          {'file': testFile.path, 'offset': 24},
        ],
        'length': 6,
        'suggestions': []
      },
    ]);
  }
}
