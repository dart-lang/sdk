// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
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
    sourcePath = convertPath('/home/test/lib/test.dart');
  }

  test_adjacentLinesExcluded() async {
    String content = """
void myMethod() {
  return /*1*/new Wrapper(
    /*2*/new Thing(1,
      2)/*2:Thing*/
  )/*1:Wrapper*/;
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 2);
  }

  /// When constructors span many like this, the node's start position is on the first line
  /// of the expression and not where the opening paren is, so this test ensures we
  /// don't end up with lots of unwanted labels on each line here.
  test_chainedConstructorOverManyLines() async {
    String content = """
main() {
  return new thing
    .whatIsSplit
    .acrossManyLines(1, 2);
}
    """;

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 0);
  }

  /// When chaining methods like this, the node's start position is on the first line
  /// of the expression and not where the opening paren is, so this test ensures we
  /// don't end up with lots of unwanted labels on each line here.
  test_chainedMethodsOverManyLines() async {
    String content = """
List<ClosingLabel> compute() {
  _unit.accept(new _DartUnitClosingLabelsComputerVisitor(this));
  return _closingLabelsByEndLine.values
      .where((l) => l.any((cl) => cl.spannedLines >= 2))
      .expand((cls) => cls)
      .map((clwlc) => clwlc.label)
      .toList();
}
    """;

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 0);
  }

  test_constConstructor() async {
    String content = """
void myMethod() {
  return /*1*/new Wrapper(
    /*2*/const Class(
      1,
      2
    )/*2:Class*/
  )/*1:Wrapper*/;
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 2);
  }

  test_constNamedConstructor() async {
    String content = """
void myMethod() {
  return /*1*/new Wrapper(
    /*2*/const Class.fromThing(
      1,
      2
    )/*2:Class.fromThing*/
  )/*1:Wrapper*/;
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

    // TODO(dantup) Results here are currently bad so this test is just checking
    // that we don't crash. Need to confirm what to do here; the bad labels
    // might not be fixed until the code is using the new shared parser.
    // https://github.com/dart-lang/sdk/issues/30370
    await _computeElements(content);
  }

  test_labelsShownForMultipleElements() async {
    String content = """
Widget build(BuildContext context) {
  return /*1*/new Row(
    child: new RaisedButton(),
  )/*1:Row*/;
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 1);
  }

  test_labelsShownForMultipleElements_2() async {
    String content = """
Widget build(BuildContext context) {
  return /*1*/new Row(
    child: /*2*/new RaisedButton(
      onPressed: increment,
    )/*2:RaisedButton*/,
  )/*1:Row*/;
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 2);
  }

  test_listLiterals() async {
    String content = """
void myMethod() {
  return /*1*/new Wrapper(
    Widget.createWidget(/*2*/<Widget>[
      1,
      2
    ]/*2:<Widget>[]*/)
  )/*1:Wrapper*/;
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 2);
  }

  /// When a line contains the end of a label, we need to ensure we also include any
  /// other labels that end on the same line, even if they are 1-2 lines, otherwise
  /// it isn't obvious which closing bracket goes with the label.
  test_mixedLineSpanning() async {
    String content = """
main() {
    /*1*/new Foo((m) {
      /*2*/new Bar(
          labels,
          /*3*/new Padding(
              new ClosingLabel(expectedStart, expectedLength, expectedLabel))/*3:Padding*/)/*2:Bar*/;
    })/*1:Foo*/;
  }
}
  """;

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 3);
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
      _makeWidget(
        'a',
        'b'
      ),
      new Text('Count: \$counter'),
    ]/*2:<Widget>[]*/,
  )/*1:Row*/;
}
""";
    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 4);
  }

  test_newConstructor() async {
    String content = """
void myMethod() {
  return /*1*/new Wrapper(
    /*2*/new Class(
      1,
      2
    )/*2:Class*/
  )/*1:Wrapper*/;
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 2);
  }

  test_newNamedConstructor() async {
    String content = """
void myMethod() {
  return /*1*/new Wrapper(
    /*2*/new Class.fromThing(
      1,
      2
    )/*2:Class.fromThing*/
  )/*1:Wrapper*/;
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 2);
  }

  test_noLabelsForOneElement() async {
    String content = """
Widget build(BuildContext context) {
  return new Row(
  );
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 0);
  }

  test_NoLabelsFromInterpolatedStrings() async {
    String content = """
void main(HighlightRegionType type, int offset, int length) {
  /*1*/new Wrapper(
    /*2*/new Fail(
        'Not expected to find (offset=\$offset; length=\$length; type=\$type) in\\n'
        '\${regions.join('\\n')}')/*2:Fail*/
      )/*1:Wrapper*/;
}
    """;

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 2);
  }

  test_prefixedConstConstructor() async {
    String content = """
import 'dart:async' as a;
void myMethod() {
  return /*1*/new Wrapper(
    /*2*/const a.Future(
      1,
      2
    )/*2:a.Future*/
  )/*1:Wrapper*/;
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 2);
  }

  test_prefixedConstNamedConstructor() async {
    String content = """
import 'dart:async' as a;
void myMethod() {
  return /*1*/new Wrapper(
    /*2*/const a.Future.delayed(
      1,
      2
    )/*2:a.Future.delayed*/
  )/*1:Wrapper*/;
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 2);
  }

  test_prefixedNewConstructor() async {
    String content = """
import 'dart:async' as a;
void myMethod() {
  return /*1*/new Wrapper(
    /*2*/new a.Future(
      1,
      2
    )/*2:a.Future*/
  )/*1:Wrapper*/;
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 2);
  }

  test_prefixedNewNamedConstructor() async {
    String content = """
import 'dart:async' as a;
void myMethod() {
  return /*1*/new Wrapper(
    /*2*/new a.Future.delayed(
      1,
      2
    )/*2:a.Future.delayed*/
  )/*1:Wrapper*/;
}
""";

    var labels = await _computeElements(content);
    _compareLabels(labels, content, expectedLabelCount: 2);
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

  /// Compares provided closing labels with expected
  /// labels extracted from the comments in the provided content.
  void _compareLabels(List<ClosingLabel> labels, String content,
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

  Future<List<ClosingLabel>> _computeElements(String sourceContent) async {
    newFile(sourcePath, content: sourceContent);
    ResolvedUnitResult result = await session.getResolvedUnit(sourcePath);
    DartUnitClosingLabelsComputer computer =
        new DartUnitClosingLabelsComputer(result.lineInfo, result.unit);
    return computer.compute();
  }
}
