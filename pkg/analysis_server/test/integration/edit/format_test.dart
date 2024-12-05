// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FormatTest);
    defineReflectiveTests(LanguageVersionSpecificFormatTest);
  });
}

@reflectiveTest
class FormatTest extends AbstractAnalysisServerIntegrationTest {
  Future<String> formatTestSetup({bool withErrors = false}) async {
    var pathname = sourcePath('test.dart');

    if (withErrors) {
      var text = r'''
class Class1 {
  int field
  void foo() {
  }
}
''';
      writeFile(pathname, text);
    } else {
      var text = r'''
class Class1 {
  int field;

  void foo() {
  }

  void bar() {
  }
}
''';
      writeFile(pathname, text);
    }
    await standardAnalysisSetup();
    return pathname;
  }

  Future<void> test_format() async {
    var pathname = await formatTestSetup();

    var result = await sendEditFormat(pathname, 0, 0);
    expect(result.edits, isNotEmpty);
    expect(result.selectionOffset, 0);
    expect(result.selectionLength, 0);
  }

  Future<void> test_format_preserve_selection() async {
    var pathname = await formatTestSetup();

    // format with 'bar' selected
    var initialPosition = readFile(pathname).indexOf('bar()');
    var result = await sendEditFormat(pathname, initialPosition, 'bar'.length);
    expect(result.edits, isNotEmpty);
    expect(result.selectionOffset, initialPosition - 3);
    expect(result.selectionLength, 'bar'.length);
  }

  Future<void> test_format_with_errors() async {
    var pathname = await formatTestSetup(withErrors: true);

    try {
      await sendEditFormat(pathname, 0, 0);
      fail('expected FORMAT_WITH_ERRORS');
    } on ServerErrorMessage catch (message) {
      expect(message.error['code'], 'FORMAT_WITH_ERRORS');
    }
  }
}

@reflectiveTest
class LanguageVersionSpecificFormatTest
    extends AbstractAnalysisServerIntegrationTest {
  Future<String> createTestFile(String text) async {
    var pathname = sourcePath('test.dart');
    writeFile(pathname, text);
    await standardAnalysisSetup();
    return pathname;
  }

  Future<void> test_format_short() async {
    var path = await createTestFile('''
// @dart = 3.5

void f({String? argument1, String? argument2}) {}

void g() {
  f(argument1: 'An argument', argument2: 'Another argument');
}
''');

    var result = await sendEditFormat(path, 0, 0);

    // No change in short style.
    expect(result.edits, isEmpty);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/56685')
  Future<void> test_format_tall() async {
    var path = await createTestFile('''
void f({String? argument1, String? argument2}) {}

void g() {
  f(argument1: 'An argument', argument2: 'Another argument');
}
''');

    var result = await sendEditFormat(path, 0, 0);
    expect(result.edits, isNotEmpty);
    // TODO(pq): update expectations when formatter is complete
  }
}
