// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.edit.assists;

import 'dart:async';

import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart' hide ERROR;

import '../analysis_abstract.dart';
import '../reflective_tests.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(AssistsTest);
}


@ReflectiveTestCase()
class AssistsTest extends AbstractAnalysisTest {
  List<SourceChange> changes;

  void prepareAssists(String search, [int length = 0]) {
    int offset = findOffset(search);
    prepareAssistsAt(offset, length);
  }

  void prepareAssistsAt(int offset, int length) {
    Request request =
        new EditGetAssistsParams(testFile, offset, length).toRequest('0');
    Response response = handleSuccessfulRequest(request);
    var result = new EditGetAssistsResult.fromResponse(response);
    changes = result.assists;
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
    handler = new EditDomainHandler(server);
  }

  Future test_removeTypeAnnotation() {
    addTestFile('''
main() {
  int v = 1;
}
''');
    return waitForTasksFinished().then((_) {
      prepareAssists('v =');
      _assertHasChange('Remove type annotation', '''
main() {
  var v = 1;
}
''');
    });
  }

  Future test_splitVariableDeclaration() {
    addTestFile('''
main() {
  int v = 1;
}
''');
    return waitForTasksFinished().then((_) {
      prepareAssists('v =');
      _assertHasChange('Split variable declaration', '''
main() {
  int v;
  v = 1;
}
''');
    });
  }

  Future test_surroundWithIf() {
    addTestFile('''
main() {
  print(1);
  print(2);
}
''');
    return waitForTasksFinished().then((_) {
      int offset = findOffset('  print(1)');
      int length = findOffset('}') - offset;
      prepareAssistsAt(offset, length);
      _assertHasChange("Surround with 'if'", '''
main() {
  if (condition) {
    print(1);
    print(2);
  }
}
''');
    });
  }

  void _assertHasChange(String message, String expectedCode) {
    for (SourceChange change in changes) {
      if (change.message == message) {
        String resultCode =
            SourceEdit.applySequence(testCode, change.edits[0].edits);
        expect(resultCode, expectedCode);
        return;
      }
    }
    fail("Expected to find |$message| in\n" + changes.join('\n'));
  }
}
