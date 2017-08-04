// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../mocks.dart';
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
  List<ClosingLabel> lastLabels;

  Completer _labelsReceived;

  void subscribeForLabels() {
    addAnalysisSubscription(AnalysisService.CLOSING_LABELS, testFile);
  }

  Future waitForLabels(action()) {
    _labelsReceived = new Completer();
    action();
    return _labelsReceived.future;
  }

  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_CLOSING_LABELS) {
      var params =
          new AnalysisClosingLabelsParams.fromNotification(notification);
      if (params.file == testFile) {
        lastLabels = params.labels;
        _labelsReceived.complete(null);
      }
    }
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
  }

  static const sampleCode = '''
Widget build(BuildContext context) {
  return /*1*/new Row(
    children: /*2*/<Widget>[
      new Text('a'),
      new Text('b'),
    ]/*2:List<Widget>*/,
  )/*1:Row*/;
}
''';

  test_afterAnalysis() async {
    addTestFile(sampleCode);
    await waitForTasksFinished();
    expect(lastLabels, isNull);

    await waitForLabels(() => subscribeForLabels());
    _compareLastResultsWithTestFileComments(2);
  }

  test_afterUpdate() async {
    addTestFile('');
    // TODO(dantup) currently required to get notifications on updates
    setPriorityFiles([testFile]);

    // Before subscribing, we shouldn't have had any labels.
    await waitForTasksFinished();
    expect(lastLabels, isNull);

    // With no content, there should be zero labels.
    await waitForLabels(() => subscribeForLabels());
    expect(lastLabels, hasLength(0));

    // With sample code there will be labels.
    await waitForLabels(() => modifyTestFile(sampleCode));
    _compareLastResultsWithTestFileComments(2);
  }

  test_multiple_nested() async {
    addTestFile('''
Widget build(BuildContext context) {
  return /*1*/new Row(
    children: /*2*/<Widget>[
      /*3*/new RaisedButton(
        onPressed: increment,
        child: /*4*/new Text(
          'Increment'
        )/*4:Text*/,
      )/*3:RaisedButton*/,
      /*5*/_makeWidget(
        'a',
        'b'
      )/*5:_makeWidget*/,
      new Text('Count: \$counter'),
    ]/*2:List<Widget>*/,
  )/*1:Row*/;
}
''');
    await waitForTasksFinished();
    expect(lastLabels, isNull);

    await waitForLabels(() {
      subscribeForLabels();
    });
    _compareLastResultsWithTestFileComments(5);
  }

  /// Compares the latest received closing labels with expected
  /// labels extracted from the comments in the test file.
  _compareLastResultsWithTestFileComments(int expectedLabelCount) {
    // Require the test pass us the expected count to guard
    // against expected annotations being mistyped and not
    // extracted by the regex.
    expect(lastLabels, hasLength(expectedLabelCount));

    // Find all numeric markers for label starts.
    var regex = new RegExp("/\\*(\\d+)\\*/");
    var expectedLabels = regex.allMatches(testCode);

    // Check we didn't get more than expected, since the loop below only
    // checks for the presence of matches, not absence.
    expect(lastLabels, hasLength(expectedLabels.length));

    // Go through each marker, find the expected label/end and
    // ensure it's in the results.
    expectedLabels.forEach((m) {
      var i = m.group(1);
      // Find the end marker.
      var endMatch = new RegExp("/\\*$i:(.+)\\*/").firstMatch(testCode);

      var expectedStart = m.end;
      var expectedLength = endMatch.start - expectedStart;
      var expectedLabel = endMatch.group(1);

      expect(
          lastLabels,
          contains(
              new ClosingLabel(expectedStart, expectedLength, expectedLabel)));
    });
  }
}
