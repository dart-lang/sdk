// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
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
  final sampleCode = TestCode.parseNormalized('''
import[! 'dart:async';
import 'dart:core';!]

main async() {}
''');

  late final expectedResults = [
    // We don't include the first "import" in the region because
    // we want that to remain visible (not collapse).
    FoldingRegion(
      FoldingKind.DIRECTIVES,
      sampleCode.range.sourceRange.offset,
      sampleCode.range.sourceRange.length,
    ),
  ];

  List<FoldingRegion>? lastRegions;

  late Completer<void> _regionsReceived;

  @override
  void processNotification(Notification notification) {
    if (notification.event == analysisNotificationFolding) {
      var params = AnalysisFoldingParams.fromNotification(
        notification,
        clientUriConverter: server.uriConverter,
      );
      if (params.file == testFile.path) {
        lastRegions = params.regions;
        _regionsReceived.complete();
      }
    } else if (notification.event == serverNotificationError) {
      var params = ServerErrorParams.fromNotification(
        notification,
        clientUriConverter: server.uriConverter,
      );
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
    addTestFile(sampleCode.code);
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
    await waitForFolding(() async => modifyTestFile(sampleCode.code));

    expect(lastRegions, expectedResults);
  }

  Future<void> waitForFolding(Future<void> Function() action) async {
    _regionsReceived = Completer();
    await action();
    return _regionsReceived.future;
  }
}
