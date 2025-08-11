// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart/test_definition.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TestDefinitionTest);
    defineReflectiveTests(TestWithFlutterDefinitionTest);
  });
}

@reflectiveTest
class TestDefinitionTest extends DartSnippetProducerTest {
  @override
  final generator = TestDefinition.new;

  @override
  String get label => TestDefinition.label;

  @override
  String get prefix => TestDefinition.prefix;

  Future<void> test_import_dart() async {
    testFilePath = convertPath('$testPackageLibPath/test/foo_test.dart');
    var code = r'''
void f() {
  test^
}
''';
    var expectedCode = '''
import 'package:test/test.dart';

void f() {
  test('[!test name!]', () {
    ^
  });
}
''';
    await assertSnippetResult(code, expectedCode);
  }

  Future<void> test_import_dart_existing() async {
    testFilePath = convertPath('$testPackageLibPath/test/foo_test.dart');
    var code = r'''
import 'package:test/test.dart';

void f() {
  test^
}
''';
    var expectedCode = '''
import 'package:test/test.dart';

void f() {
  test('[!test name!]', () {
    ^
  });
}
''';
    await assertSnippetResult(code, expectedCode);
  }

  Future<void> test_inTestFile() async {
    testFilePath = convertPath('$testPackageLibPath/test/foo_test.dart');
    var code = r'''
void f() {
  test^
}
''';
    var expectedCode = '''
import 'package:test/test.dart';

void f() {
  test('[!test name!]', () {
    ^
  });
}
''';
    await assertSnippetResult(code, expectedCode);
  }

  Future<void> test_notTestFile() async {
    var code = r'''
void f() {
  test^
}
''';
    await expectNotValidSnippet(code);
  }
}

@reflectiveTest
class TestWithFlutterDefinitionTest extends DartSnippetProducerTest {
  @override
  final generator = TestDefinition.new;

  @override
  bool get addFlutterTestPackageDep => true;

  @override
  String get label => TestDefinition.label;

  @override
  String get prefix => TestDefinition.prefix;

  Future<void> test_import_flutter() async {
    testFilePath = convertPath('$testPackageLibPath/test/foo_test.dart');
    var code = r'''
void f() {
  test^
}
''';
    var expectedCode = '''
import 'package:flutter_test/flutter_test.dart';

void f() {
  test('[!test name!]', () {
    ^
  });
}
''';
    await assertSnippetResult(code, expectedCode);
  }

  Future<void> test_import_flutter_existing() async {
    testFilePath = convertPath('$testPackageLibPath/test/foo_test.dart');
    var code = r'''
import 'package:flutter_test/flutter_test.dart';

void f() {
  test^
}
''';
    var expectedCode = '''
import 'package:flutter_test/flutter_test.dart';

void f() {
  test('[!test name!]', () {
    ^
  });
}
''';
    await assertSnippetResult(code, expectedCode);
  }

  /// Ensure we don't import package:flutter_test if package:test is already
  /// imported.
  Future<void> test_import_flutter_existingDart() async {
    testFilePath = convertPath('$testPackageLibPath/test/foo_test.dart');
    var code = r'''
import 'package:test/test.dart';

void f() {
  test^
}
''';
    var expectedCode = '''
import 'package:test/test.dart';

void f() {
  test('[!test name!]', () {
    ^
  });
}
''';
    await assertSnippetResult(code, expectedCode);
  }
}
