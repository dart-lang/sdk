// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../integration_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SortMembersTest);
  });
}

@reflectiveTest
class SortMembersTest extends AbstractAnalysisServerIntegrationTest {
  test_sort() async {
    String pathname = sourcePath('test.dart');
    String text = r'''
int foo;
int bar;
''';
    writeFile(pathname, text);
    standardAnalysisSetup();

    EditSortMembersResult result = await sendEditSortMembers(pathname);
    SourceFileEdit edit = result.edit;
    expect(edit.edits, hasLength(1));
    expect(edit.edits.first.replacement, "bar;\nint foo");
  }

  test_sort_no_changes() async {
    String pathname = sourcePath('test.dart');
    String text = r'''
int bar;
int foo;
''';
    writeFile(pathname, text);
    standardAnalysisSetup();

    EditSortMembersResult result = await sendEditSortMembers(pathname);
    SourceFileEdit edit = result.edit;
    expect(edit.edits, isEmpty);
  }

  test_sort_with_errors() async {
    String pathname = sourcePath('test.dart');
    String text = r'''
int foo
int bar;
''';
    writeFile(pathname, text);
    standardAnalysisSetup();

    try {
      await sendEditSortMembers(pathname);
    } on ServerErrorMessage catch (message) {
      expect(message.error['code'], 'SORT_MEMBERS_PARSE_ERRORS');
    }
  }

  @override
  bool get enableNewAnalysisDriver => true;
}
