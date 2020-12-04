// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OrganizeDirectivesTest);
  });
}

@reflectiveTest
class OrganizeDirectivesTest extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_organize_directives() async {
    var pathname = sourcePath('test.dart');
    var text = r'''
import 'dart:math';
import 'dart:async';

Completer foo;
int minified(int x, int y) => min(x, y);
''';
    writeFile(pathname, text);
    standardAnalysisSetup();

    var result = await sendEditOrganizeDirectives(pathname);
    var edit = result.edit;
    expect(edit.edits, hasLength(1));
    expect(edit.edits.first.replacement,
        "import 'dart:async';\nimport 'dart:math");
  }

  Future<void> test_organize_directives_no_changes() async {
    var pathname = sourcePath('test.dart');
    var text = r'''
import 'dart:async';
import 'dart:math';

Completer foo;
int minified(int x, int y) => min(x, y);
''';
    writeFile(pathname, text);
    standardAnalysisSetup();

    var result = await sendEditOrganizeDirectives(pathname);
    var edit = result.edit;
    expect(edit.edits, isEmpty);
  }

  Future<void> test_organize_directives_with_errors() async {
    var pathname = sourcePath('test.dart');
    var text = r'''
import 'dart:async'
import 'dart:math';

Completer foo;
int minified(int x, int y) => min(x, y);
''';
    writeFile(pathname, text);
    standardAnalysisSetup();

    try {
      await sendEditOrganizeDirectives(pathname);
    } on ServerErrorMessage catch (message) {
      expect(message.error['code'], 'ORGANIZE_DIRECTIVES_ERROR');
    }
  }
}
