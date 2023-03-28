// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_server_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisNotificationFoldingTest);
  });
}

@reflectiveTest
class AnalysisNotificationFoldingTest extends PubPackageAnalysisServerTest {
  static const sampleCode = '''
import 'dart:async';
import 'dart:core';

main async() {}
''';

  static final expectedResults = [
    // We don't include the first "import" in the region because
    // we want that to remain visible (not collapse).
    FoldingRegion(FoldingKind.DIRECTIVES, 6, 34)
  ];

  List<FoldingRegion>? lastRegions;

  late Completer<void> _regionsReceived;

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_FOLDING) {
      var params = AnalysisFoldingParams.fromNotification(notification);
      if (params.file == testFile.path) {
        lastRegions = params.regions;
        _regionsReceived.complete();
      }
    } else if (notification.event == SERVER_NOTIFICATION_ERROR) {
      var params = ServerErrorParams.fromNotification(notification);
      throw '${params.message}\n${params.stackTrace}';
    }
  }

  @override
  Future<void> setUp() async {
    super.setUp();
    await setRoots(included: [workspaceRootPath], excluded: []);
  }

  Future<void> subscribeForFolding() async {
    await addAnalysisSubscription(AnalysisService.FOLDING, testFile);
  }

  Future<void> test_afterAnalysis() async {
    addTestFile(sampleCode);
    await waitForTasksFinished();
    expect(lastRegions, isNull);

    await waitForFolding(() async => await subscribeForFolding());

    expect(lastRegions, expectedResults);
  }

  Future<void> test_afterUpdate() async {
    addTestFile('');
    // Currently required to get notifications on updates
    setPriorityFiles([testFile]);

    // Before subscribing, we shouldn't have had any folding regions.
    await waitForTasksFinished();
    expect(lastRegions, isNull);

    // With no content, there should be zero regions.
    await waitForFolding(() async => await subscribeForFolding());
    expect(lastRegions, hasLength(0));

    // With sample code there will be folding regions.
    await waitForFolding(() async => modifyTestFile(sampleCode));

    expect(lastRegions, expectedResults);
  }

  Future<void> waitForFolding(Future<void> Function() action) async {
    _regionsReceived = Completer();
    await action();
    return _regionsReceived.future;
  }
}
