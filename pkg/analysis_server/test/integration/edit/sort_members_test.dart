// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SortMembersTest);
  });
}

@reflectiveTest
class SortMembersTest extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_sort() async {
    var pathname = sourcePath('test.dart');
    var text = r'''
int foo;
int bar;
''';
    writeFile(pathname, text);
    standardAnalysisSetup();

    var result = await sendEditSortMembers(pathname);
    var edit = result.edit;
    expect(edit.edits, hasLength(1));
    expect(edit.edits.first.replacement, 'bar;\nint foo');
  }

  Future<void> test_sort_no_changes() async {
    var pathname = sourcePath('test.dart');
    var text = r'''
int bar;
int foo;
''';
    writeFile(pathname, text);
    standardAnalysisSetup();

    var result = await sendEditSortMembers(pathname);
    var edit = result.edit;
    expect(edit.edits, isEmpty);
  }

  Future<void> test_sort_with_errors() async {
    var pathname = sourcePath('test.dart');
    var text = r'''
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
}
