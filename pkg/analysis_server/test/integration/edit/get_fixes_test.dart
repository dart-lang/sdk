// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetFixesTest);
  });
}

@reflectiveTest
class GetFixesTest extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_has_fixes() async {
    var pathname = sourcePath('test.dart');
    var text = r'''
FutureOr f;
''';
    writeFile(pathname, text);
    standardAnalysisSetup();

    await analysisFinished;
    expect(currentAnalysisErrors[pathname], isNotEmpty);

    var result = await sendEditGetFixes(pathname, text.indexOf('FutureOr f'));

    expect(result.fixes, hasLength(1));
    var fix = result.fixes.first;
    expect(fix.error.code, 'undefined_class');

    // expect a suggestion to add the dart:async import
    expect(fix.fixes, isNotEmpty);

    var change = fix.fixes.singleWhere(
        (SourceChange change) => change.message.startsWith('Import '));
    expect(change.edits, hasLength(1));
    expect(change.edits.first.edits, hasLength(1));
  }

  Future<void> test_no_fixes() async {
    var pathname = sourcePath('test.dart');
    var text = r'''
import 'dart:async';

FutureOr f;
''';
    writeFile(pathname, text);
    standardAnalysisSetup();

    var result = await sendEditGetFixes(pathname, text.indexOf('FutureOr f'));
    expect(result.fixes, isEmpty);
  }
}
