// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClosingLabelsTest);
  });
}

@reflectiveTest
class ClosingLabelsTest extends AbstractLspAnalysisServerTest {
  Future<void> test_afterChange() async {
    final initialContent = 'main() {}';
    final updatedContent = '''
Widget build(BuildContext context) {
  return new Row(         // Row       1:9
    children: <Widget>[   // Widget[]  2:14
      new Text('a'),
      new Text('b'),
    ],                    // /Widget[] 5:5
  );                      // /Row      6:3
}
''';
    await initialize(initializationOptions: {'closingLabels': true});

    final labelsUpdateBeforeChange = waitForClosingLabels(mainFileUri);
    openFile(mainFileUri, initialContent);
    final labelsBeforeChange = await labelsUpdateBeforeChange;

    final labelsUpdateAfterChange = waitForClosingLabels(mainFileUri);
    replaceFile(1, mainFileUri, updatedContent);
    final labelsAfterChange = await labelsUpdateAfterChange;

    expect(labelsBeforeChange, isEmpty);
    expect(labelsAfterChange, hasLength(2));

    final first = labelsAfterChange.first;
    final second = labelsAfterChange.last;

    expect(first.label, equals('Row'));
    expect(first.range.start.line, equals(1));
    expect(first.range.start.character, equals(9));
    expect(first.range.end.line, equals(6));
    expect(first.range.end.character, equals(3));

    expect(second.label, equals('<Widget>[]'));
    expect(second.range.start.line, equals(2));
    expect(second.range.start.character, equals(14));
    expect(second.range.end.line, equals(5));
    expect(second.range.end.character, equals(5));
  }

  Future<void> test_initial() async {
    final content = '''
Widget build(BuildContext context) {
  return new Row(         // Row       1:9
    children: <Widget>[   // Widget[]  2:14
      new Text('a'),
      new Text('b'),
    ],                    // /Widget[] 5:5
  );                      // /Row      6:3
}
''';
    await initialize(initializationOptions: {'closingLabels': true});

    final closingLabelsUpdate = waitForClosingLabels(mainFileUri);
    openFile(mainFileUri, content);
    final labels = await closingLabelsUpdate;

    expect(labels, hasLength(2));
    final first = labels.first;
    final second = labels.last;

    expect(first.label, equals('Row'));
    expect(first.range.start.line, equals(1));
    expect(first.range.start.character, equals(9));
    expect(first.range.end.line, equals(6));
    expect(first.range.end.character, equals(3));

    expect(second.label, equals('<Widget>[]'));
    expect(second.range.start.line, equals(2));
    expect(second.range.start.character, equals(14));
    expect(second.range.end.line, equals(5));
    expect(second.range.end.character, equals(5));
  }
}
