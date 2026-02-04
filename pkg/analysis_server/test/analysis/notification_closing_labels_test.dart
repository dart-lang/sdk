// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_server_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisNotificationClosingLabelsTest);
  });
}

@reflectiveTest
class AnalysisNotificationClosingLabelsTest
    extends PubPackageAnalysisServerTest {
  late final expectedResults = [
    _label(sampleCode.ranges[0], 'Row'),
    _label(sampleCode.ranges[1], '<Widget>[]'),
  ];

  final sampleCode = TestCode.parseNormalized('''
Widget build(BuildContext context) {
  return /*[0*/new Row(
    children: /*[1*/<Widget>[
      Text('a'),
      Text('b'),
    ]/*1]*/,
  )/*0]*/;
}
''');

  List<ClosingLabel>? lastLabels;

  late Completer<void> _labelsReceived;

  @override
  void processNotification(Notification notification) {
    if (notification.event == analysisNotificationClosingLabels) {
      var params = AnalysisClosingLabelsParams.fromNotification(
        notification,
        clientUriConverter: server.uriConverter,
      );
      if (params.file == testFile.path) {
        lastLabels = params.labels;
        _labelsReceived.complete();
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

  Future<void> subscribeForLabels() async {
    await addAnalysisSubscription(AnalysisService.CLOSING_LABELS, testFile);
  }

  Future<void> test_afterAnalysis() async {
    addTestFile(sampleCode.code);
    await waitForTasksFinished();
    expect(lastLabels, isNull);

    await waitForLabels(() async => await subscribeForLabels());

    expect(lastLabels, expectedResults);
  }

  Future<void> test_afterUpdate() async {
    addTestFile('');
    // Currently required to get notifications on updates
    setPriorityFiles([testFile]);

    // Before subscribing, we shouldn't have had any labels.
    await waitForTasksFinished();
    expect(lastLabels, isNull);

    // With no content, there should be zero labels.
    await waitForLabels(() async => await subscribeForLabels());
    expect(lastLabels, hasLength(0));

    // With sample code there will be labels.
    await waitForLabels(() async => modifyTestFile(sampleCode.code));

    expect(lastLabels, expectedResults);
  }

  Future<void> waitForLabels(Future<void> Function() action) async {
    _labelsReceived = Completer();
    await action();
    return _labelsReceived.future;
  }

  ClosingLabel _label(TestCodeRange range, String text) {
    return ClosingLabel(
      range.sourceRange.offset,
      range.sourceRange.length,
      text,
    );
  }
}
