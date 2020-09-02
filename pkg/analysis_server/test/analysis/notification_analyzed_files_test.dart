// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisNotificationAnalyzedFilesTest);
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

  void assertHasNoFile(String filePath) {
    expect(analyzedFilesReceived, isTrue);
    expect(analyzedFiles, isNot(contains(filePath)));
  }

  Future<void> prepareAnalyzedFiles() async {
    addGeneralAnalysisSubscription(GeneralAnalysisService.ANALYZED_FILES);
    await pumpEventQueue(times: 5000);
  }

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_ANALYZED_FILES) {
      var params = AnalysisAnalyzedFilesParams.fromNotification(notification);
      analyzedFilesReceived = true;
      analyzedFiles = params.directories;
    }
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
  }

  Future<void> test_afterAnalysis() async {
    addTestFile('''
class A {}
''');
    await waitForTasksFinished();
    await prepareAnalyzedFiles();
    assertHasFile(testFile);
  }

  Future<void> test_beforeAnalysis() async {
    addTestFile('''
class A {}
''');
    await prepareAnalyzedFiles();
    assertHasFile(testFile);
  }

  Future<void> test_beforeAnalysis_excludeYamlFiles() async {
    var yamlFile = getFolder(projectPath).getChildAssumingFile('sample.yaml');
    yamlFile.writeAsStringSync('');
    addTestFile('''
class A {}
''');
    await prepareAnalyzedFiles();
    assertHasFile(testFile);
    assertHasNoFile(yamlFile.path);
  }

  Future<void> test_insignificant_change() async {
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

  Future<void> test_resubscribe_no_changes() async {
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

  Future<void> test_significant_change() async {
    // Making a change that *does* affect the set of reachable files should
    // trigger the notification to be re-sent.
    addTestFile('class A {}');
    newFile('/foo.dart', content: 'library foo;');
    await prepareAnalyzedFiles();
    expect(analyzedFilesReceived, isTrue);

    analyzedFilesReceived = false;
    modifyTestFile('import "${toUriStr('/foo.dart')}";');
    await prepareAnalyzedFiles();
    assertHasFile(convertPath('/foo.dart'));
  }

  void unsubscribeAnalyzedFiles() {
    removeGeneralAnalysisSubscription(GeneralAnalysisService.ANALYZED_FILES);
  }
}
