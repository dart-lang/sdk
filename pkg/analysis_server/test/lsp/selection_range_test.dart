// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SelectionRangeTest);
  });
}

/// Additional tests are in
///
/// test/src/computer/selection_range_computer_test.dart
@reflectiveTest
class SelectionRangeTest extends AbstractLspAnalysisServerTest {
  Future<void> test_multiple() async {
    final content = '''
class Foo {
  void a() { /*1*/ }
  void b() { /*2*/ }
}
''';

    await initialize();
    await openFile(mainFileUri, content);
    final lineInfo = LineInfo.fromContent(content);

    // Send a request for two positions.
    final regions = await getSelectionRanges(mainFileUri, [
      positionFromOffset(content.indexOf('/*1*/'), content),
      positionFromOffset(content.indexOf('/*2*/'), content),
    ]);
    expect(regions!.length, equals(2));
    final firstTexts =
        _getSelectionRangeText(lineInfo, content, regions[0]).toList();
    final secondTexts =
        _getSelectionRangeText(lineInfo, content, regions[1]).toList();

    expect(
        firstTexts,
        equals([
          '{ /*1*/ }',
          'void a() { /*1*/ }',
          content.trim(), // Whole content minus the trailing newline
        ]));
    expect(
        secondTexts,
        equals([
          '{ /*2*/ }',
          'void b() { /*2*/ }',
          content.trim(), // Whole content minus the trailing newline
        ]));
  }

  Future<void> test_single() async {
    final code = TestCode.parse('''
class Foo<T> {
  void a(String b) {
    print((1 ^+ 2) * 3);
  }
}
''');

    await initialize();
    await openFile(mainFileUri, code.code);
    final lineInfo = LineInfo.fromContent(code.code);

    // The returned List corresponds to the input list of positions, and not
    // the set of ranges - each range within that list has a (recursive) parent
    // to walk up all ranges for that position.
    final regions =
        await getSelectionRanges(mainFileUri, [code.position.position]);
    expect(regions!.length, equals(1)); // Only one position was sent.
    final regionTexts =
        _getSelectionRangeText(lineInfo, code.code, regions.first).toList();

    expect(
        regionTexts,
        equals([
          '1 + 2',
          '(1 + 2)',
          '(1 + 2) * 3',
          '((1 + 2) * 3)',
          'print((1 + 2) * 3)',
          'print((1 + 2) * 3);',
          '{\n    print((1 + 2) * 3);\n  }',
          'void a(String b) {\n    print((1 + 2) * 3);\n  }',
          'class Foo<T> {\n  void a(String b) {\n    print((1 + 2) * 3);\n  }\n}',
        ]));
  }

  Iterable<String> _getSelectionRangeText(
      LineInfo lineInfo, String content, SelectionRange range) sync* {
    yield _rangeOfText(lineInfo, content, range.range);
    final parent = range.parent;
    if (parent != null) {
      yield* _getSelectionRangeText(lineInfo, content, parent);
    }
  }

  String _rangeOfText(LineInfo lineInfo, String content, Range range) {
    final startPos = range.start;
    final endPos = range.end;
    final start = lineInfo.getOffsetOfLine(startPos.line) + startPos.character;
    final end = lineInfo.getOffsetOfLine(endPos.line) + endPos.character;
    return content.substring(start, end);
  }
}
