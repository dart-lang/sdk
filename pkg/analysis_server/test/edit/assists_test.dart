// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.edit.assists;

import 'dart:async';

import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/correction/change.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart' hide ERROR;

import '../analysis_abstract.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(AssistsTest);
}


@ReflectiveTestCase()
class AssistsTest extends AbstractAnalysisTest {
  List<Change> changes;

  void prepareAssists(String search, [int length = 0]) {
    int offset = findOffset(search);
    prepareAssistsAt(offset, length);
  }

  void prepareAssistsAt(int offset, int length) {
    Request request = new Request('0', EDIT_GET_ASSISTS);
    request.setParameter(FILE, testFile);
    request.setParameter(OFFSET, offset);
    request.setParameter(LENGTH, length);
    Response response = handleSuccessfulRequest(request);
    List<Map<String, dynamic>> changeJsonList = response.getResult(ASSISTS);
    // TODO(scheglov) consider using generated classes and decoders
    changes = changeJsonList.map((Map<String, dynamic> changeJson) {
      Change change = new Change(changeJson[MESSAGE]);
      changeJson[EDITS].forEach((Map<String, dynamic> fileEditJson) {
        FileEdit fileEdit = new FileEdit(fileEditJson[FILE]);
        change.fileEdits.add(fileEdit);
        fileEditJson[EDITS].forEach((Map<String, dynamic> json) {
          Edit edit = new Edit(json[OFFSET], json[LENGTH], json[REPLACEMENT]);
          fileEdit.edits.add(edit);
        });
      });
      return change;
    }).toList();
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
    for (Change change in changes) {
      if (change.message == message) {
        String resultCode =
            Edit.applySequence(testCode, change.fileEdits[0].edits);
        expect(resultCode, expectedCode);
        return;
      }
    }
    fail("Expected to find |$message| in\n" + changes.join('\n'));
  }
}
