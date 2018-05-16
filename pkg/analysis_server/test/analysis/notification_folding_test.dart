// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(_AnalysisNotificationFoldingTest);
  });
}

@reflectiveTest
class _AnalysisNotificationFoldingTest extends AbstractAnalysisTest {
  static const sampleCode = '''
import 'dart:async';
import 'dart:core';

main async() {}
''';

  static final expectedResults = [
    // We don't include the first "import" in the region because
    // we want that to remain visible (not collapse).
    new FoldingRegion(FoldingKind.DIRECTIVES, 6, 34)
  ];

  List<FoldingRegion> lastRegions;

  Completer _regionsReceived;

  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_FOLDING) {
      var params = new AnalysisFoldingParams.fromNotification(notification);
      if (params.file == testFile) {
        lastRegions = params.regions;
        _regionsReceived.complete(null);
      }
    } else if (notification.event == SERVER_NOTIFICATION_ERROR) {
      var params = new ServerErrorParams.fromNotification(notification);
      throw "${params.message}\n${params.stackTrace}";
    }
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
  }

  void subscribeForFolding() {
    addAnalysisSubscription(AnalysisService.FOLDING, testFile);
  }

  test_afterAnalysis() async {
    addTestFile(sampleCode);
    await waitForTasksFinished();
    expect(lastRegions, isNull);

    await waitForFolding(() => subscribeForFolding());

    expect(lastRegions, expectedResults);
  }

  test_afterUpdate() async {
    addTestFile('');
    // Currently required to get notifications on updates
    setPriorityFiles([testFile]);

    // Before subscribing, we shouldn't have had any folding regions.
    await waitForTasksFinished();
    expect(lastRegions, isNull);

    // With no content, there should be zero regions.
    await waitForFolding(() => subscribeForFolding());
    expect(lastRegions, hasLength(0));

    // With sample code there will be folding regions.
    await waitForFolding(() => modifyTestFile(sampleCode));

    expect(lastRegions, expectedResults);
  }

  Future waitForFolding(action()) {
    _regionsReceived = new Completer();
    action();
    return _regionsReceived.future;
  }
}
