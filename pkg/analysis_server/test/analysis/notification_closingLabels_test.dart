// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(_AnalysisNotificationClosingLabelsTest);
  });
}

@reflectiveTest
class _AnalysisNotificationClosingLabelsTest extends AbstractAnalysisTest {
  static const sampleCode = '''
Widget build(BuildContext context) {
  return /*1*/new Row(
    children: /*2*/<Widget>[
      new Text('a'),
      new Text('b'),
    ]/*/2*/,
  )/*/1*/;
}
''';

  static final expectedResults = [
    new ClosingLabel(51, 96, "Row"),
    new ClosingLabel(79, 57, "<Widget>[]")
  ];

  List<ClosingLabel> lastLabels;

  Completer _labelsReceived;

  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_CLOSING_LABELS) {
      var params =
          new AnalysisClosingLabelsParams.fromNotification(notification);
      if (params.file == testFile) {
        lastLabels = params.labels;
        _labelsReceived.complete(null);
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

  void subscribeForLabels() {
    addAnalysisSubscription(AnalysisService.CLOSING_LABELS, testFile);
  }

  test_afterAnalysis() async {
    addTestFile(sampleCode);
    await waitForTasksFinished();
    expect(lastLabels, isNull);

    await waitForLabels(() => subscribeForLabels());

    expect(lastLabels, expectedResults);
  }

  test_afterUpdate() async {
    addTestFile('');
    // Currently required to get notifications on updates
    setPriorityFiles([testFile]);

    // Before subscribing, we shouldn't have had any labels.
    await waitForTasksFinished();
    expect(lastLabels, isNull);

    // With no content, there should be zero labels.
    await waitForLabels(() => subscribeForLabels());
    expect(lastLabels, hasLength(0));

    // With sample code there will be labels.
    await waitForLabels(() => modifyTestFile(sampleCode));

    expect(lastLabels, expectedResults);
  }

  Future waitForLabels(action()) {
    _labelsReceived = new Completer();
    action();
    return _labelsReceived.future;
  }
}
