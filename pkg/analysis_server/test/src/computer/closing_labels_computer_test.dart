// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/computer/computer_closing_labels.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClosingLabelsComputerTest);
  });
}

@reflectiveTest
class ClosingLabelsComputerTest extends AbstractContextTest {
  late String sourcePath;

  @override
  void setUp() {
    super.setUp();
    sourcePath = convertPath('$testPackageLibPath/test.dart');
  }

  Future<void> test_adjacentLinesExcluded() async {
    var content = '''
void myMethod() {
  return /*[0*/new Wrapper(
    /*[1*/new Thing(1,
      2)/*1]*/
  )/*0]*/;
}
''';

    await _compareLabels(content, ['Wrapper', 'Thing']);
  }

  /// When constructors span many like this, the node's start position is on the first line
  /// of the expression and not where the opening paren is, so this test ensures we
  /// don't end up with lots of unwanted labels on each line here.
  Future<void> test_chainedConstructorOverManyLines() async {
    var content = '''
void f() {
  return new thing
    .whatIsSplit
    .acrossManyLines(1, 2);
}
    ''';

    await _compareLabels(content, []);
  }

  /// When chaining methods like this, the node's start position is on the first line
  /// of the expression and not where the opening paren is, so this test ensures we
  /// don't end up with lots of unwanted labels on each line here.
  Future<void> test_chainedMethodsOverManyLines() async {
    var content = '''
List<ClosingLabel> compute() {
  _unit.accept(new _DartUnitClosingLabelsComputerVisitor(this));
  return _closingLabelsByEndLine.values
      .where((l) => l.any((cl) => cl.spannedLines >= 2))
      .expand((cls) => cls)
      .map((clwlc) => clwlc.label)
      .toList();
}
    ''';

    await _compareLabels(content, []);
  }

  Future<void> test_constConstructor() async {
    var content = '''
void myMethod() {
  return /*[0*/new Wrapper(
    /*[1*/const Class(
      1,
      2
    )/*1]*/
  )/*0]*/;
}
''';

    await _compareLabels(content, ['Wrapper', 'Class']);
  }

  Future<void> test_constNamedConstructor() async {
    var content = '''
void myMethod() {
  return /*[0*/new Wrapper(
    /*[1*/const Class.fromThing(
      1,
      2
    )/*1]*/
  )/*0]*/;
}
''';

    await _compareLabels(content, ['Wrapper', 'Class.fromThing']);
  }

  Future<void> test_knownBadCode1() async {
    // This code crashed during testing when I accidentally inserted a test snippet.
    var content = """
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

    // TODO(dantup): Results here are currently bad so this test is just checking
    // that we don't crash. Need to confirm what to do here; the bad labels
    // might not be fixed until the code is using the new shared parser.
    // https://github.com/dart-lang/sdk/issues/30370
    await _computeLabels(content);
  }

  Future<void> test_labelsShownForMultipleElements() async {
    var content = '''
Widget build(BuildContext context) {
  return /*[0*/new Row(
    child: new RaisedButton(),
  )/*0]*/;
}
''';

    await _compareLabels(content, ['Row']);
  }

  Future<void> test_labelsShownForMultipleElements_2() async {
    var content = '''
Widget build(BuildContext context) {
  return /*[0*/new Row(
    child: /*[1*/new RaisedButton(
      onPressed: increment,
    )/*1]*/,
  )/*0]*/;
}
''';

    await _compareLabels(content, ['Row', 'RaisedButton']);
  }

  Future<void> test_listLiterals() async {
    var content = '''
void myMethod() {
  return /*[0*/new Wrapper(
    Widget.createWidget(/*[1*/<Widget>[
      1,
      2
    ]/*1]*/)
  )/*0]*/;
}
''';

    await _compareLabels(content, ['Wrapper', '<Widget>[]']);
  }

  /// When a line contains the end of a label, we need to ensure we also include any
  /// other labels that end on the same line, even if they are 1-2 lines, otherwise
  /// it isn't obvious which closing bracket goes with the label.
  Future<void> test_mixedLineSpanning() async {
    var content = '''
void f() {
    /*[0*/new Foo((m) {
      /*[1*/new Bar(
          labels,
          /*[2*/new Padding(
              new ClosingLabel(expectedStart, expectedLength, expectedLabel))/*2]*/)/*1]*/;
    })/*0]*/;
  }
}
  ''';

    await _compareLabels(content, ['Foo', 'Bar', 'Padding']);
  }

  Future<void> test_multipleNested() async {
    var content = """
Widget build(BuildContext context) {
  return /*[0*/new Row(
    children: /*[1*/<Widget>[
      /*[2*/new RaisedButton(
        onPressed: increment,
        child: /*[3*/new Text(
          'Increment'
        )/*3]*/,
      )/*2]*/,
      _makeWidget(
        'a',
        'b'
      ),
      new Text('Count: \$counter'),
    ]/*1]*/,
  )/*0]*/;
}
""";

    await _compareLabels(content, [
      'Row',
      '<Widget>[]',
      'RaisedButton',
      'Text',
    ]);
  }

  Future<void> test_newConstructor() async {
    var content = '''
void myMethod() {
  return /*[0*/new Wrapper(
    /*[1*/new Class(
      1,
      2
    )/*1]*/
  )/*0]*/;
}
''';

    await _compareLabels(content, ['Wrapper', 'Class']);
  }

  Future<void> test_newNamedConstructor() async {
    var content = '''
void myMethod() {
  return /*[0*/new Wrapper(
    /*[1*/new Class.fromThing(
      1,
      2
    )/*1]*/
  )/*0]*/;
}
''';

    await _compareLabels(content, ['Wrapper', 'Class.fromThing']);
  }

  Future<void> test_noLabelsForOneElement() async {
    var content = '''
Widget build(BuildContext context) {
  return new Row(
  );
}
''';

    await _compareLabels(content, []);
  }

  Future<void> test_NoLabelsFromInterpolatedStrings() async {
    var content = """
void f(HighlightRegionType type, int offset, int length) {
  /*[0*/new Wrapper(
    /*[1*/new Fail(
        'Not expected to find (offset=\$offset; length=\$length; type=\$type) in\\n'
        '\${regions.join('\\n')}')/*1]*/
      )/*0]*/;
}
    """;

    await _compareLabels(content, ['Wrapper', 'Fail']);
  }

  Future<void> test_nullAwareElement_inList() async {
    var content = '''
void myMethod() {
  return /*[0*/new Wrapper(
    Widget.createWidget(/*[1*/<Widget>[
      1,
      ?null,
      2
    ]/*1]*/)
  )/*0]*/;
}
''';

    await _compareLabels(content, ['Wrapper', '<Widget>[]']);
  }

  Future<void> test_nullAwareElement_inList_containingList() async {
    var content = '''
void myMethod() {
  return /*[0*/new Wrapper(
    Widget.createWidget(/*[1*/<Widget>[
      1,
      ?Widget.createWidget(/*[2*/<Widget>[
        3
      ]/*2]*/),
      2
    ]/*1]*/)
  )/*0]*/;
}
''';

    await _compareLabels(content, ['Wrapper', '<Widget>[]', '<Widget>[]']);
  }

  Future<void> test_prefixedConstConstructor() async {
    var content = """
import 'dart:async' as a;
void myMethod() {
  return /*[0*/new Wrapper(
    /*[1*/const a.Future(
      1,
      2
    )/*1]*/
  )/*0]*/;
}
""";

    await _compareLabels(content, ['Wrapper', 'a.Future']);
  }

  Future<void> test_prefixedConstNamedConstructor() async {
    var content = """
import 'dart:async' as a;
void myMethod() {
  return /*[0*/new Wrapper(
    /*[1*/const a.Future.delayed(
      1,
      2
    )/*1]*/
  )/*0]*/;
}
""";

    await _compareLabels(content, ['Wrapper', 'a.Future.delayed']);
  }

  Future<void> test_prefixedNewConstructor() async {
    var content = """
import 'dart:async' as a;
void myMethod() {
  return /*[0*/new Wrapper(
    /*[1*/new a.Future(
      1,
      2
    )/*1]*/
  )/*0]*/;
}
""";

    await _compareLabels(content, ['Wrapper', 'a.Future']);
  }

  Future<void> test_prefixedNewNamedConstructor() async {
    var content = """
import 'dart:async' as a;
void myMethod() {
  return /*[0*/new Wrapper(
    /*[1*/new a.Future.delayed(
      1,
      2
    )/*1]*/
  )/*0]*/;
}
""";

    await _compareLabels(content, ['Wrapper', 'a.Future.delayed']);
  }

  Future<void> test_sameLineExcluded() async {
    var content = '''
void myMethod() {
  return new Thing();
}
''';

    await _compareLabels(content, []);
  }

  /// Compares provided closing labels with expected
  /// labels extracted from the comments in the provided content.
  Future<void> _compareLabels(String content, List<String> texts) async {
    var testCode = TestCode.parseNormalized(content);

    var ranges = testCode.ranges;
    expect(
      ranges,
      hasLength(texts.length),
      reason:
          'Marked code should have the same number of ranges as the expected label texts',
    );

    // Check we got the expected number of labels.
    var labels = await _computeLabels(testCode.code);
    expect(labels, hasLength(ranges.length));

    // Go through each range and ensure it's in the results with the correct text.
    for (var i = 0; i < ranges.length; i++) {
      var range = ranges[i].sourceRange;
      var expectedLabel = texts[i];

      expect(
        labels,
        contains(ClosingLabel(range.offset, range.length, expectedLabel)),
      );
    }
  }

  Future<List<ClosingLabel>> _computeLabels(String sourceContent) async {
    var file = newFile(sourcePath, sourceContent);
    var result = await getResolvedUnit(file);
    var computer = DartUnitClosingLabelsComputer(result.lineInfo, result.unit);
    return computer.compute();
  }
}
