// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart/test_group_definition.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
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

  Future<void> test_import_dart() async {
    testFilePath = convertPath('$testPackageLibPath/test/foo_test.dart');
    var code = TestCode.parse(r'''
void f() {
  group^
}
''');
    var snippet = await expectValidSnippet(code);
    var result = applySnippet(code, snippet);
    expect(result, '''
import 'package:test/test.dart';

void f() {
  group('group name', () {
    
  });
}
''');
  }

  Future<void> test_import_dart_existing() async {
    testFilePath = convertPath('$testPackageLibPath/test/foo_test.dart');
    var code = TestCode.parse(r'''
import 'package:test/test.dart';

void f() {
  group^
}
''');
    var snippet = await expectValidSnippet(code);
    var result = applySnippet(code, snippet);
    expect(result, '''
import 'package:test/test.dart';

void f() {
  group('group name', () {
    
  });
}
''');
  }

  Future<void> test_import_flutter() async {
    writeTestPackageConfig(flutter_test: true);
    testFilePath = convertPath('$testPackageLibPath/test/foo_test.dart');
    var code = TestCode.parse(r'''
void f() {
  group^
}
''');
    var snippet = await expectValidSnippet(code);
    var result = applySnippet(code, snippet);
    expect(result, '''
import 'package:flutter_test/flutter_test.dart';

void f() {
  group('group name', () {
    
  });
}
''');
  }

  Future<void> test_import_flutter_existing() async {
    writeTestPackageConfig(flutter_test: true);
    testFilePath = convertPath('$testPackageLibPath/test/foo_test.dart');
    var code = TestCode.parse(r'''
import 'package:flutter_test/flutter_test.dart';

void f() {
  group^
}
''');
    var snippet = await expectValidSnippet(code);
    var result = applySnippet(code, snippet);
    expect(result, '''
import 'package:flutter_test/flutter_test.dart';

void f() {
  group('group name', () {
    
  });
}
''');
  }

  /// Ensure we don't import package:flutter_test if package:test is already
  /// imported.
  Future<void> test_import_flutter_existingDart() async {
    writeTestPackageConfig(flutter_test: true);
    testFilePath = convertPath('$testPackageLibPath/test/foo_test.dart');
    var code = TestCode.parse(r'''
import 'package:test/test.dart';

void f() {
  group^
}
''');
    var snippet = await expectValidSnippet(code);
    var result = applySnippet(code, snippet);
    expect(result, '''
import 'package:test/test.dart';

void f() {
  group('group name', () {
    
  });
}
''');
  }

  Future<void> test_inTestFile() async {
    testFilePath = convertPath('$testPackageLibPath/test/foo_test.dart');
    var code = TestCode.parse(r'''
void f() {
  group^
}
''');
    var snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));
    var result = applySnippet(code, snippet);
    expect(result, '''
import 'package:test/test.dart';

void f() {
  group('group name', () {
    
  });
}
''');
    expect(snippet.change.selection!.file, testFile.path);
    expect(snippet.change.selection!.offset, 76);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile.path, 'offset': 54},
        ],
        'length': 10,
        'suggestions': [],
      },
    ]);
  }

  Future<void> test_notTestFile() async {
    var code = r'''
void f() {
  group^
}
''';
    await expectNotValidSnippet(code);
  }
}
