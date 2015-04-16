// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.edit.format;

import 'dart:async';

import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analyzer/src/plugin/plugin_impl.dart';
import 'package:unittest/unittest.dart' hide ERROR;

import '../analysis_abstract.dart';
import '../reflective_tests.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(FormatTest);
}

@reflectiveTest
class FormatTest extends AbstractAnalysisTest {
  @override
  void setUp() {
    super.setUp();
    createProject();
    ExtensionManager manager = new ExtensionManager();
    ServerPlugin plugin = new ServerPlugin();
    manager.processPlugins([plugin]);
    handler = new EditDomainHandler(server, plugin);
  }

  Future test_formatNoOp() {
    // Already formatted source
    addTestFile('''
main() {
  int x = 3;
}
''');
    return waitForTasksFinished().then((_) {
      EditFormatResult formatResult = _formatAt(0, 3);
      expect(formatResult.edits, isNotNull);
      expect(formatResult.edits, hasLength(0));
    });
  }

  Future test_formatNoSelection() async {
    addTestFile('''
main() { int x = 3; }
''');
    await waitForTasksFinished();
    EditFormatResult formatResult = _formatAt(0, 0);

    expect(formatResult.edits, isNotNull);
    expect(formatResult.edits, hasLength(1));

    SourceEdit edit = formatResult.edits[0];
    expect(edit.replacement, equals('''
main() {
  int x = 3;
}
'''));
    expect(formatResult.selectionOffset, equals(0));
    expect(formatResult.selectionLength, equals(0));
  }

  Future test_formatSimple() {
    addTestFile('''
main() { int x = 3; }
''');
    return waitForTasksFinished().then((_) {
      EditFormatResult formatResult = _formatAt(0, 3);

      expect(formatResult.edits, isNotNull);
      expect(formatResult.edits, hasLength(1));

      SourceEdit edit = formatResult.edits[0];
      expect(edit.replacement, equals('''
main() {
  int x = 3;
}
'''));
      expect(formatResult.selectionOffset, equals(0));
      expect(formatResult.selectionLength, equals(3));
    });
  }

  EditFormatResult _formatAt(int selectionOffset, int selectionLength) {
    Request request = new EditFormatParams(
        testFile, selectionOffset, selectionLength).toRequest('0');
    Response response = handleSuccessfulRequest(request);
    return new EditFormatResult.fromResponse(response);
  }
}
