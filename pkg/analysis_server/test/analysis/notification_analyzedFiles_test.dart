// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis.notification.analyzedDirectories;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';
import '../mocks.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisNotificationAnalyzedFilesTest);
    defineReflectiveTests(AnalysisNotificationAnalyzedFilesTest_Driver);
  });
}

@reflectiveTest
class AnalysisNotificationAnalyzedFilesTest extends AbstractAnalysisTest {
  List<String> analyzedFiles;
  bool analyzedFilesReceived = false;

  void assertHasFile(String filePath) {
    expect(analyzedFilesReceived, isTrue);
    expect(analyzedFiles, contains(filePath));
  }

  Future<Null> prepareAnalyzedFiles() async {
    addGeneralAnalysisSubscription(GeneralAnalysisService.ANALYZED_FILES);
    await pumpEventQueue();
  }

  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_ANALYZED_FILES) {
      AnalysisAnalyzedFilesParams params =
          new AnalysisAnalyzedFilesParams.fromNotification(notification);
      analyzedFilesReceived = true;
      analyzedFiles = params.directories;
    }
  }

  void setUp() {
    super.setUp();
    createProject();
  }

  test_afterAnalysis() async {
    addTestFile('''
class A {}
''');
    await waitForTasksFinished();
    await prepareAnalyzedFiles();
    assertHasFile(testFile);
  }

  test_beforeAnalysis() async {
    addTestFile('''
class A {}
''');
    await prepareAnalyzedFiles();
    assertHasFile(testFile);
  }

  test_insignificant_change() async {
    // Making a change that doesn't affect the set of reachable files should
    // not trigger the notification to be re-sent.
    addTestFile('class A {}');
    await prepareAnalyzedFiles();
    expect(analyzedFilesReceived, isTrue);

    analyzedFilesReceived = false;
    modifyTestFile('class B {}');
    await prepareAnalyzedFiles();
    expect(analyzedFilesReceived, isFalse);
  }

  test_resubscribe_no_changes() async {
    // Unsubscribing and resubscribing should cause the notification to be
    // re-sent, even if nothing has changed.
    addTestFile('class A {}');
    await prepareAnalyzedFiles();
    expect(analyzedFilesReceived, isTrue);

    unsubscribeAnalyzedFiles();
    analyzedFilesReceived = false;

    await prepareAnalyzedFiles();
    expect(analyzedFilesReceived, isTrue);
    assertHasFile(testFile);
  }

  test_significant_change() async {
    // Making a change that *does* affect the set of reachable files should
    // trigger the notification to be re-sent.
    addTestFile('class A {}');
    addFile('/foo.dart', 'library foo;');
    await prepareAnalyzedFiles();
    expect(analyzedFilesReceived, isTrue);

    analyzedFilesReceived = false;
    modifyTestFile('import "/foo.dart";');
    await prepareAnalyzedFiles();
    assertHasFile('/foo.dart');
  }

  void unsubscribeAnalyzedFiles() {
    removeGeneralAnalysisSubscription(GeneralAnalysisService.ANALYZED_FILES);
  }
}

@reflectiveTest
class AnalysisNotificationAnalyzedFilesTest_Driver
    extends AnalysisNotificationAnalyzedFilesTest {
  @override
  void setUp() {
    enableNewAnalysisDriver = true;
    generateSummaryFiles = true;
    super.setUp();
  }
}
