// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.edit.fixes;

import 'dart:async';

import 'package:analysis_server/src/computer/element.dart';
import 'package:analysis_server/src/computer/error.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analysis_server/src/edit/fix.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_services/constants.dart';
import 'package:analysis_services/correction/change.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';

import '../analysis_abstract.dart';


main() {
  groupSep = ' | ';
  group('getFixes', () {
    runReflectiveTests(FixesTest);
  });
}


@ReflectiveTestCase()
class FixesTest extends AbstractAnalysisTest {
  @override
  void setUp() {
    super.setUp();
    createProject();
    handler = new EditDomainHandler(server);
  }

  Future test_hasFixes() {
    addTestFile('''
main() {
  print(42)
}
''');
    return waitForTasksFinished().then((_) {
      Request request = new Request('0', EDIT_GET_FIXES);
      request.setParameter(FILE, testFile);
      request.setParameter(OFFSET, findOffset('print'));
      Response response = handleSuccessfulRequest(request);
      List<Map<String, Object>> errorFixesJsonList = response.getResult(FIXES);
      List<ErrorFixes> errorFixesList = errorFixesJsonList.map(ErrorFixes.fromJson).toList();
      expect(errorFixesList, hasLength(1));
      {
         ErrorFixes errorFixes = errorFixesList[0];
         {
           AnalysisError error = errorFixes.error;
           expect(error.severity, 'ERROR');
           expect(error.type, 'SYNTACTIC_ERROR');
           expect(error.message, "Expected to find ';'");
           {
             Location location = error.location;
             expect(location.file, testFile);
             expect(location.offset, 19);
             expect(location.length, 1);
             expect(location.startLine, 2);
             expect(location.startColumn, 11);
           }
         }
         expect(errorFixes.fixes, hasLength(1));
         {
           Change change = errorFixes.fixes[0];
           expect(change.message, "Insert ';'");
           expect(change.edits, hasLength(1));
           {
             FileEdit fileEdit = change.edits[0];
             expect(fileEdit.file, testFile);
             expect(
                 fileEdit.edits.toString(),
                 "[Edit(offset=20, length=0, replacement=:>;<:)]");
           }
         }
      }
    });
  }
}
