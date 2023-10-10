// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../abstract_single_unit.dart';
import 'request_helpers_mixin.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SourceEditsTest);
  });
}

@reflectiveTest
class SourceEditsTest extends AbstractSingleUnitTest with LspEditHelpersMixin {
  Future<void> test_minimalEdits_comma_delete() async {
    const startContent = '''
void f(int a,) {}
''';
    const endContent = '''
void f(int a) {}
''';
    const expectedEdits = r'''
Delete 1:13-1:14
''';

    await _assertMinimalEdits(startContent, endContent, expectedEdits);
  }

  Future<void> test_minimalEdits_comma_delete_afterBlockComment() async {
    const startContent = '''
void f(int a /* before */,);
''';
    const endContent = '''
void f(int a /* before */);
''';
    const expectedEdits = r'''
Delete 1:26-1:27
''';

    await _assertMinimalEdits(startContent, endContent, expectedEdits);
  }

  Future<void> test_minimalEdits_comma_delete_afterWhitespace() async {
    const startContent = '''
void f(int a ,) {}
''';
    const endContent = '''
void f(int a ) {}
''';
    const expectedEdits = r'''
Delete 1:14-1:15
''';

    await _assertMinimalEdits(startContent, endContent, expectedEdits);
  }

  Future<void> test_minimalEdits_comma_delete_beforeWhitespace() async {
    const startContent = '''
void f(int a, ) {}
''';
    const endContent = '''
void f(int a ) {}
''';
    const expectedEdits = r'''
Delete 1:13-1:14
''';

    await _assertMinimalEdits(startContent, endContent, expectedEdits);
  }

  Future<void> test_minimalEdits_comma_delete_betweenBlockComments() async {
    const startContent = '''
void f(int a /* before */ , /* after */);
''';
    const endContent = '''
void f(int a /* before */ /* after */);
''';
    const expectedEdits = r'''
Delete 1:27-1:29
''';

    await _assertMinimalEdits(startContent, endContent, expectedEdits);
  }

  Future<void>
      test_minimalEdits_comma_delete_betweenBlockComments_withWrapping() async {
    const startContent = '''
void f(veryLongArgument, argument /* before */ , /* after */ argument);
''';
    const endContent = '''
void f(
  veryLongArgument,
  argument, /* before */
  /* after */ argument,
);
''';
    const expectedEdits = r'''
Insert "\n  " at 1:8
Insert "\n " at 1:25
Insert "," at 1:34
Replace 1:47-1:49 with "\n "
Insert ",\n" at 1:70
''';

    await _assertMinimalEdits(startContent, endContent, expectedEdits);
  }

  Future<void> test_minimalEdits_comma_delete_betweenWhitespace() async {
    const startContent = '''
void f(int a , ) {}
''';
    const endContent = '''
void f(int a  ) {}
''';
    const expectedEdits = r'''
Delete 1:14-1:15
''';

    await _assertMinimalEdits(startContent, endContent, expectedEdits);
  }

  Future<void> test_minimalEdits_comma_insert() async {
    const startContent = '''
void f(int a) {}
''';
    const endContent = '''
void f(int a,) {}
''';
    const expectedEdits = r'''
Insert "," at 1:13
''';

    await _assertMinimalEdits(startContent, endContent, expectedEdits);
  }

  Future<void> test_minimalEdits_comma_insert_afterWhitespace() async {
    const startContent = '''
void f(int a ) {}
''';
    const endContent = '''
void f(int a ,) {}
''';
    const expectedEdits = r'''
Insert "," at 1:14
''';

    await _assertMinimalEdits(startContent, endContent, expectedEdits);
  }

  Future<void> test_minimalEdits_comma_insert_beforeWhitespace() async {
    const startContent = '''
void f(
  int a
) {}
''';
    const endContent = '''
void f(
  int a,
) {}
''';
    const expectedEdits = r'''
Insert "," at 2:8
''';

    await _assertMinimalEdits(startContent, endContent, expectedEdits);
  }

  Future<void> test_minimalEdits_comma_insert_betweenWhitespace() async {
    const startContent = '''
void f(int a  ) {}
''';
    const endContent = '''
void f(int a , ) {}
''';
    const expectedEdits = r'''
Insert "," at 1:14
''';

    await _assertMinimalEdits(startContent, endContent, expectedEdits);
  }

  Future<void>
      test_minimalEdits_comma_insertWithLeadingAndTrailingWhitespace() async {
    const startContent = '''
void f(int a) {}
''';
    const endContent = '''
void f(int a , ) {}
''';
    const expectedEdits = r'''
Insert " , " at 1:13
''';

    await _assertMinimalEdits(startContent, endContent, expectedEdits);
  }

  Future<void> test_minimalEdits_comma_insertWithLeadingWhitespace() async {
    const startContent = '''
void f(int a) {}
''';
    const endContent = '''
void f(int a ,) {}
''';
    const expectedEdits = r'''
Insert " ," at 1:13
''';

    await _assertMinimalEdits(startContent, endContent, expectedEdits);
  }

  Future<void> test_minimalEdits_comma_insertWithTrailingWhitespace() async {
    const startContent = '''
void f(int a) {}
''';
    const endContent = '''
void f(int a, ) {}
''';
    const expectedEdits = r'''
Insert ", " at 1:13
''';

    await _assertMinimalEdits(startContent, endContent, expectedEdits);
  }

  Future<void> test_minimalEdits_comma_move() async {
    const startContent = '''
void f(
  int a // comment
,) {
}
''';
    const endContent = '''
void f(
  int a, // comment
) {
}
''';
    const expectedEdits = r'''
Insert "," at 2:8
Delete 3:1-3:2
''';

    await _assertMinimalEdits(startContent, endContent, expectedEdits);
  }

  Future<void> test_minimalEdits_whitespace() async {
    const startContent = '''
void   f(){}
''';
    const endContent = '''
void f() {
}
''';
    const expectedEdits = r'''
Delete 1:6-1:8
Insert " " at 1:11
Insert "\n" at 1:12
''';

    await _assertMinimalEdits(startContent, endContent, expectedEdits);
  }

  /// Assert that computing minimal edits to convert [start] to [end] produces
  /// the set of edits described in [expected].
  ///
  /// Edits will be automatically applied and verified. [expected] is to ensure
  /// the edits are minimal and we didn't accidentally produces a single edit
  /// replacing the entire file.
  Future<void> _assertMinimalEdits(
    String start,
    String end,
    String expected,
  ) async {
    start = start.trim();
    end = end.trim();
    expected = expected.trim();
    await parseTestCode(start);
    final edits = generateMinimalEdits(testParsedResult, end);
    expect(edits.toText().trim(), expected);
    expect(applyTextEdits(start, edits.result), end);
  }
}

/// Helpers for building simple text representations of edits to verify that
/// minimal diffs were produced.
///
/// Does not include actual content - resulting content should be verified
/// separately.
extension on List<TextEdit> {
  String toText() => map((edit) => edit.toText()).join('\n');
}

/// Helpers for building simple text representations of edits to verify that
/// minimal diffs were produced.
///
/// Does not include actual content - resulting content should be verified
/// separately.
extension on TextEdit {
  String toText() {
    return range.start == range.end
        ? 'Insert ${jsonEncode(newText)} at ${range.start.toText()}'
        : newText.isEmpty
            ? 'Delete ${range.toText()}'
            : 'Replace ${range.toText()} with ${jsonEncode(newText)}';
  }
}

/// Helpers for building simple text representations of edits to verify that
/// minimal diffs were produced.
extension on Range {
  String toText() => '${start.toText()}-${end.toText()}';
}

/// Helpers for building simple text representations of edits to verify that
/// minimal diffs were produced.
extension on Position {
  String toText() => '${line + 1}:${character + 1}';
}

/// Helpers for building simple text representations of edits to verify that
/// minimal diffs were produced.
///
/// Does not include actual content - resulting content should be verified
/// separately.
extension on ErrorOr<List<TextEdit>> {
  String toText() => map(
        (error) => 'Error: ${error.message}',
        (result) => result.toText(),
      );
}
