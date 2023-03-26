// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
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
  static const sampleCode = '''
Widget build(BuildContext context) {
  return /*1*/new Row(
    children: /*2*/<Widget>[
      Text('a'),
      Text('b'),
    ]/*/2*/,
  )/*/1*/;
}
''';

  static final expectedResults = [
    ClosingLabel(51, 88, 'Row'),
    ClosingLabel(79, 49, '<Widget>[]')
  ];

  List<ClosingLabel>? lastLabels;

  late Completer<void> _labelsReceived;

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_CLOSING_LABELS) {
      var params = AnalysisClosingLabelsParams.fromNotification(notification);
      if (params.file == testFile.path) {
        lastLabels = params.labels;
        _labelsReceived.complete();
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

  Future<void> subscribeForLabels() async {
    await addAnalysisSubscription(AnalysisService.CLOSING_LABELS, testFile);
  }

  Future<void> test_afterAnalysis() async {
    addTestFile(sampleCode);
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
    await waitForLabels(() async => modifyTestFile(sampleCode));

    expect(lastLabels, expectedResults);
  }

  Future<void> waitForLabels(Future<void> Function() action) async {
    _labelsReceived = Completer();
    await action();
    return _labelsReceived.future;
  }
}
