// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FormatTest);
  });
}

@reflectiveTest
class FormatTest extends AbstractAnalysisServerIntegrationTest {
  String formatTestSetup({bool withErrors: false}) {
    String pathname = sourcePath('test.dart');

    if (withErrors) {
      String text = r'''
class Class1 {
  int field
  void foo() {
  }
}
''';
      writeFile(pathname, text);
    } else {
      String text = r'''
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
    standardAnalysisSetup();
    return pathname;
  }

  test_format() async {
    String pathname = formatTestSetup();

    EditFormatResult result = await sendEditFormat(pathname, 0, 0);
    expect(result.edits, isNotEmpty);
    expect(result.selectionOffset, 0);
    expect(result.selectionLength, 0);
  }

  test_format_preserve_selection() async {
    String pathname = formatTestSetup();

    // format with 'bar' selected
    int initialPosition = readFile(pathname).indexOf('bar()');
    EditFormatResult result =
        await sendEditFormat(pathname, initialPosition, 'bar'.length);
    expect(result.edits, isNotEmpty);
    expect(result.selectionOffset, initialPosition - 3);
    expect(result.selectionLength, 'bar'.length);
  }

  test_format_with_errors() async {
    String pathname = formatTestSetup(withErrors: true);

    try {
      await sendEditFormat(pathname, 0, 0);
      fail('expected FORMAT_WITH_ERRORS');
    } on ServerErrorMessage catch (message) {
      expect(message.error['code'], 'FORMAT_WITH_ERRORS');
    }
  }
}
