// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis.notification.analyzedDirectories;

import 'dart:async';

import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../analysis_abstract.dart';

main() {
  groupSep = ' | ';
  defineReflectiveTests(AnalysisNotificationAnalyzedFilesTest);
}

@reflectiveTest
class AnalysisNotificationAnalyzedFilesTest extends AbstractAnalysisTest {
  List<String> analyzedFiles;

  void assertHasFile(String filePath) {
    expect(analyzedFiles, contains(filePath));
  }

  Future prepareAnalyzedFiles() {
    addGeneralAnalysisSubscription(GeneralAnalysisService.ANALYZED_FILES);
    return waitForTasksFinished();
  }

  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_ANALYZED_FILES) {
      AnalysisAnalyzedFilesParams params =
          new AnalysisAnalyzedFilesParams.fromNotification(notification);
      analyzedFiles = params.directories;
    }
  }

  void setUp() {
    super.setUp();
    createProject();
  }

  test_afterAnalysis() {
    addTestFile('''
class A {}
''');
    return waitForTasksFinished().then((_) {
      return prepareAnalyzedFiles().then((_) {
        assertHasFile(testFile);
      });
    });
  }

  test_definedInInterface_ofInterface() {
    addTestFile('''
class A {}
''');
    return prepareAnalyzedFiles().then((_) {
      assertHasFile(testFile);
    });
  }
}
