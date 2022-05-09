// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_server_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisNotificationAnalyzedFilesTest);
  });
}

@reflectiveTest
class AnalysisNotificationAnalyzedFilesTest
    extends PubPackageAnalysisServerTest {
  late List<String> analyzedFiles;
  bool analyzedFilesReceived = false;

  void assertHasFile(File file) {
    expect(analyzedFilesReceived, isTrue);
    expect(analyzedFiles, contains(file.path));
  }

  void assertHasNoFile(String filePath) {
    expect(analyzedFilesReceived, isTrue);
    expect(analyzedFiles, isNot(contains(filePath)));
  }

  Future<void> prepareAnalyzedFiles() async {
    await addGeneralAnalysisSubscription(
      GeneralAnalysisService.ANALYZED_FILES,
    );
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
  Future<void> setUp() async {
    super.setUp();
    await setRoots(included: [workspaceRootPath], excluded: []);
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
    var yamlFile = newFile2('$testPackageRootPath/sample.yaml', '');
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
    var foo = newFile2('/foo.dart', 'library foo;');
    await prepareAnalyzedFiles();
    expect(analyzedFilesReceived, isTrue);

    analyzedFilesReceived = false;
    modifyTestFile('import "${toUriStr('/foo.dart')}";');
    await prepareAnalyzedFiles();
    assertHasFile(foo);
  }

  void unsubscribeAnalyzedFiles() {
    removeGeneralAnalysisSubscription(
      GeneralAnalysisService.ANALYZED_FILES,
    );
  }
}
