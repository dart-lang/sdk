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

  test_multipleNested() async {
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

  test_newConstructor() async {
    await _testCode(
        1,
        '''
void myMethod() {
  return /*1*/new Class(
    1,
    2
  )/*1:Class*/;
}
    ''');
  }

  test_newNamedConstructor() async {
    await _testCode(
        1,
        '''
void myMethod() {
  return /*1*/new Class.fromThing(
    1,
    2
  )/*1:Class.fromThing*/;
}
    ''');
  }

  test_constConstructor() async {
    await _testCode(
        1,
        '''
void myMethod() {
  return /*1*/const Class(
    1,
    2
  )/*1:Class*/;
}
    ''');
  }

  test_constNamedConstructor() async {
    await _testCode(
        1,
        '''
void myMethod() {
  return /*1*/const Class.fromThing(
    1,
    2
  )/*1:Class.fromThing*/;
}
    ''');
  }

  test_prefixedIndentifier() async {
    await _testCode(
        1,
        '''
import 'dart:async' as a;
Object myMethod() {
  return /*1*/new a.Future.delayed(
    new Duration(seconds: 1)
    
  )/*1:a.Future.delayed*/;
}
    ''');
  }

  test_instanceMethod() async {
    await _testCode(
        1,
        '''
void myMethod() {
  return /*1*/createWidget(
    1,
    2
  )/*1:createWidget*/;
}
    ''');
  }

  test_staticMethod() async {
    await _testCode(
        1,
        '''
void myMethod() {
  return /*1*/Widget.createWidget(
    1,
    2
  )/*1:createWidget*/;
}
    ''');
  }

  test_sameLineExcluded() async {
    await _testCode(
        0,
        '''
void myMethod() {
  return new Thing();
}
    ''');
  }

  test_adjacentLinesExcluded() async {
    await _testCode(
        0,
        '''
void myMethod() {
  return new Thing(1,
    2);
}
    ''');
  }

  test_listLiterals() async {
    await _testCode(
        2,
        '''
void myMethod() {
  return /*1*/Widget.createWidget(/*2*/<Widget>[
    1,
    2
  ]/*2:List<Widget>*/)/*1:createWidget*/;
}
    ''');
  }

  test_knownBadCode1() async {
    // This code crashed during testing when I accidentally inserted a test snippet.
    await _testCode(
        0,
        '''
@override
Widget build(BuildContext context) {
  new SliverGrid(
            gridDelegate: gridDelegate,
            delegate: myMethod(<test('', () {
              
            });>[
              "a",
              'b',
              "c",
            ]),
          ),
        ),
      ],
    ),
  );
}
      ''',
        // TODO(dantup) Results here are currently bad so this test is just checking that we
        // dont crash. Need to confirm what to do here; the bad labels might not be fixed
        // until the code is using the new shared parser.
        // https://github.com/dart-lang/sdk/issues/30370
        checkResults: false);
  }

  /// Helper that updates files and waits for server notifications before performing checks.
  _testCode(int labelCount, String code, {bool checkResults = true}) async {
    addTestFile(code);
    await waitForTasksFinished();
    expect(lastLabels, isNull);

    await waitForLabels(() => subscribeForLabels());
    if (checkResults) {
      _compareLastResultsWithTestFileComments(labelCount);
    }
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
      var endMatch = new RegExp("/\\*$i:(.+?)\\*/").firstMatch(testCode);

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
