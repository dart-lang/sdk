// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/context_manager.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BazelChangesTest);
  });
}

@reflectiveTest
class BazelChangesTest extends AbstractAnalysisTest {
  Map<String, List<AnalysisError>> filesErrors = {};
  Completer<void> processedNotification;

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_ERRORS) {
      var decoded = AnalysisErrorsParams.fromNotification(notification);
      filesErrors[decoded.file] = decoded.errors;
      processedNotification?.complete();
    }
  }

  @override
  void setUp() {
    super.setUp();

    experimentalEnableBazelWatching = true;

    projectPath = convertPath('/workspaceRoot/third_party/dart/project');
    testFile =
        convertPath('/workspaceRoot/third_party/dart/project/lib/test.dart');
    newFile('/workspaceRoot/WORKSPACE');
    newFolder('/workspaceRoot/bazel-lib/project');
    newFolder('/workspaceRoot/bazel-genfiles/project');
  }

  @override
  void tearDown() {
    // Make sure to destroy all the contexts and cancel all subscriptions to
    // file watchers.
    server.contextManager.setRoots([], []);

    experimentalEnableBazelWatching = false;

    super.tearDown();
  }

  Future<void> test_findingFileInGenfiles() async {
    processedNotification = Completer();

    newFile(testFile, content: r'''
import 'generated.dart';
void main() { fun(); }
''');
    createProject();

    // We should have some errors since the `generated.dart` is not there yet.
    await processedNotification.future;
    expect(filesErrors[testFile], isNotEmpty);

    // Clear errors, so that we'll notice new results.
    filesErrors.clear();
    processedNotification = Completer();

    // Simulate the creation of a generated file.
    newFile(
        '/workspaceRoot/bazel-genfiles/'
        'third_party/dart/project/lib/generated.dart',
        content: 'fun() {}');

    // No errors.
    await processedNotification.future;
    expect(filesErrors[testFile], isEmpty);
  }
}
