// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.edit.fixes;

import 'dart:async';

import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/protocol2.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart' hide ERROR;

import '../analysis_abstract.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(FixesTest);
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
      Request request = new EditGetFixesParams(testFile,
          findOffset('print')).toRequest('0');
      Response response = handleSuccessfulRequest(request);
      List<Map<String, Object>> errorFixesJsonList = response.getResult(FIXES);
      expect(errorFixesJsonList, hasLength(1));
      {
        Map<String, Object> fixes = errorFixesJsonList[0];
        Map<String, Object> error = fixes[ERROR];
        expect(error[SEVERITY], 'ERROR');
        expect(error[TYPE], 'SYNTACTIC_ERROR');
        expect(fixes[FIXES], hasLength(1));
      }
    });
  }
}
