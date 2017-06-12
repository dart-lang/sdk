// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OrganizeDirectivesTest);
  });
}

@reflectiveTest
class OrganizeDirectivesTest extends AbstractAnalysisServerIntegrationTest {
  test_organize_directives() async {
    String pathname = sourcePath('test.dart');
    String text = r'''
import 'dart:math';
import 'dart:async';

Future foo;
int minified(int x, int y) => min(x, y);
''';
    writeFile(pathname, text);
    standardAnalysisSetup();

    EditOrganizeDirectivesResult result =
        await sendEditOrganizeDirectives(pathname);
    SourceFileEdit edit = result.edit;
    expect(edit.edits, hasLength(1));
    expect(edit.edits.first.replacement,
        "import 'dart:async';\nimport 'dart:math");
  }

  test_organize_directives_no_changes() async {
    String pathname = sourcePath('test.dart');
    String text = r'''
import 'dart:async';
import 'dart:math';

Future foo;
int minified(int x, int y) => min(x, y);
''';
    writeFile(pathname, text);
    standardAnalysisSetup();

    EditOrganizeDirectivesResult result =
        await sendEditOrganizeDirectives(pathname);
    SourceFileEdit edit = result.edit;
    expect(edit.edits, isEmpty);
  }

  test_organize_directives_with_errors() async {
    String pathname = sourcePath('test.dart');
    String text = r'''
import 'dart:async'
import 'dart:math';

Future foo;
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
