// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetFixesTest);
  });
}

@reflectiveTest
class GetFixesTest extends AbstractAnalysisServerIntegrationTest {
  test_has_fixes() async {
    String pathname = sourcePath('test.dart');
    String text = r'''
Future f;
''';
    writeFile(pathname, text);
    standardAnalysisSetup();

    await analysisFinished;
    expect(currentAnalysisErrors[pathname], isNotEmpty);

    EditGetFixesResult result =
        await sendEditGetFixes(pathname, text.indexOf('Future f'));
    expect(result.fixes, hasLength(1));

    // expect a suggestion to add the dart:async import
    AnalysisErrorFixes fix = result.fixes.first;
    expect(fix.error.code, 'undefined_class');
    expect(fix.fixes, isNotEmpty);

    // apply the fix, expect that the new code has no errors
    SourceChange change = fix.fixes.singleWhere(
        (SourceChange change) => change.message.startsWith('Import '));
    expect(change.edits, hasLength(1));
    expect(change.edits.first.edits, hasLength(1));
    SourceEdit edit = change.edits.first.edits.first;
    text = text.replaceRange(edit.offset, edit.end, edit.replacement);
    writeFile(pathname, text);

    await analysisFinished;
    // The errors (at least sometimes) don't get sent until after analysis has
    // completed. Wait long enough to see whether new errors are reported.
    await new Future.delayed(new Duration(milliseconds: 1000));
    expect(currentAnalysisErrors[pathname], isEmpty);
  }

  test_no_fixes() async {
    String pathname = sourcePath('test.dart');
    String text = r'''
import 'dart:async';

Future f;
''';
    writeFile(pathname, text);
    standardAnalysisSetup();

    EditGetFixesResult result =
        await sendEditGetFixes(pathname, text.indexOf('Future f'));
    expect(result.fixes, isEmpty);
  }
}
