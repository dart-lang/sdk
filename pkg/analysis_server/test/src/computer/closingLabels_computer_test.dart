// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/computer/computer_closingLabels.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClosingLabelsComputerTest);
  });
}

@reflectiveTest
class ClosingLabelsComputerTest extends AbstractContextTest {
  String sourcePath;

  setUp() {
    super.setUp();
    sourcePath = provider.convertPath('/p/lib/source.dart');
  }

  test_multipleNested() async {
    String content = """
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
""";
    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 5);
  }

  test_newConstructor() async {
    String content = """
void myMethod() {
  return /*1*/new Class(
    1,
    2
  )/*1:Class*/;
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 1);
  }

  test_newNamedConstructor() async {
    String content = """
void myMethod() {
  return /*1*/new Class.fromThing(
    1,
    2
  )/*1:Class.fromThing*/;
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 1);
  }

  test_constConstructor() async {
    String content = """
void myMethod() {
  return /*1*/const Class(
    1,
    2
  )/*1:Class*/;
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 1);
  }

  test_constNamedConstructor() async {
    String content = """
void myMethod() {
  return /*1*/const Class.fromThing(
    1,
    2
  )/*1:Class.fromThing*/;
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 1);
  }

  test_instanceMethod() async {
    String content = """
void myMethod() {
  return /*1*/createWidget(
    1,
    2
  )/*1:createWidget*/;
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 1);
  }

  test_staticMethod() async {
    String content = """
void myMethod() {
  return /*1*/Widget.createWidget(
    1,
    2
  )/*1:Widget.createWidget*/;
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 1);
  }

  test_prefixedNewConstructor() async {
    String content = """
import 'dart:async' as a;
void myMethod() {
  return /*1*/new a.Future(
    1,
    2
  )/*1:a.Future*/;
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 1);
  }

  test_prefixedNewNamedConstructor() async {
    String content = """
import 'dart:async' as a;
void myMethod() {
  return /*1*/new a.Future.delayed(
    1,
    2
  )/*1:a.Future.delayed*/;
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 1);
  }

  test_prefixedConstConstructor() async {
    String content = """
import 'dart:async' as a;
void myMethod() {
  return /*1*/const a.Future(
    1,
    2
  )/*1:a.Future*/;
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 1);
  }

  test_prefixedConstNamedConstructor() async {
    String content = """
import 'dart:async' as a;
void myMethod() {
  return /*1*/const a.Future.delayed(
    1,
    2
  )/*1:a.Future.delayed*/;
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 1);
  }

  test_prefixedStaticMethod() async {
    String content = """
import 'widgets.dart' as a;
void myMethod() {
  return /*1*/a.Widget.createWidget(
    1,
    2
  )/*1:a.Widget.createWidget*/;
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 1);
  }

  test_sameLineExcluded() async {
    String content = """
void myMethod() {
  return new Thing();
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 0);
  }

  test_adjacentLinesExcluded() async {
    String content = """
void myMethod() {
  return new Thing(1,
    2);
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 0);
  }

  test_listLiterals() async {
    String content = """
void myMethod() {
  return /*1*/Widget.createWidget(/*2*/<Widget>[
    1,
    2
  ]/*2:List<Widget>*/)/*1:Widget.createWidget*/;
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 2);
  }

  test_knownBadCode1() async {
    // This code crashed during testing when I accidentally inserted a test snippet.
    String content = """
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
""";

    var labels = await _computeElements(content);
    // TODO(dantup) Results here are currently bad so this test is just checking that we
    // dont crash. Need to confirm what to do here; the bad labels might not be fixed
    // until the code is using the new shared parser.
    // https://github.com/dart-lang/sdk/issues/30370
  }

  Future<List<ClosingLabel>> _computeElements(String sourceContent) async {
    provider.newFile(sourcePath, sourceContent);
    ResolveResult result = await driver.getResult(sourcePath);
    DartUnitClosingLabelsComputer computer =
        new DartUnitClosingLabelsComputer(result.lineInfo, result.unit);
    return computer.compute();
  }

  /// Compares the latest received closing labels with expected
  /// labels extracted from the comments in the test file.
  _compareLabels(List<ClosingLabel> labels, String content,
      {int expectedLabelCount}) {
    // Require the test pass us the expected count to guard
    // against expected annotations being mistyped and not
    // extracted by the regex.
    expect(labels, hasLength(expectedLabelCount));

    // Find all numeric markers for label starts.
    var regex = new RegExp("/\\*(\\d+)\\*/");
    var expectedLabels = regex.allMatches(content);

    // Check we didn't get more than expected, since the loop below only
    // checks for the presence of matches, not absence.
    expect(labels, hasLength(expectedLabels.length));

    // Go through each marker, find the expected label/end and
    // ensure it's in the results.
    expectedLabels.forEach((m) {
      var i = m.group(1);
      // Find the end marker.
      var endMatch = new RegExp("/\\*$i:(.+?)\\*/").firstMatch(content);

      var expectedStart = m.end;
      var expectedLength = endMatch.start - expectedStart;
      var expectedLabel = endMatch.group(1);

      expect(
          labels,
          contains(
              new ClosingLabel(expectedStart, expectedLength, expectedLabel)));
    });
  }
}
