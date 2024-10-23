// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
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
  Future<void> test_format_version_defaultsToLatest() async {
    // Latest version should parse and format records.
    const startContent = '''
var    a = (1, 2);
''';
    const endContent = '''
var a = (1, 2);
''';
    const expectedEdits = r'''
Delete 1:5-1:8
''';

    await _assertFormatEdits(startContent, endContent, expectedEdits);
  }

  Future<void> test_format_version_languageVersionToken() async {
    // 2.19 will not parse/format records.
    const content = '''
// @dart = 2.19
var    a = (1, 2);
''';

    await _assertNoFormatEdits(content);
  }

  Future<void> test_format_version_packageConfig() async {
    // 2.19 will not parse/format records.
    writeTestPackageConfig(languageVersion: '2.19');
    const content = '''
var    a = (1, 2);
''';

    await _assertNoFormatEdits(content);
  }

  Future<void> test_format_version_versionToken_overridesPackageConfig() async {
    // 2.19 will not parse/format records.
    writeTestPackageConfig(languageVersion: '3.0');
    const content = '''
// @dart = 2.19
var    a = (1, 2);
''';

    await _assertNoFormatEdits(content);
  }

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

  Future<void> test_minimalEdits_commaAndSemicolon_remove() async {
    const startContent = '''
enum SomeEnum { a, b, c,; }
''';
    const endContent = '''
enum SomeEnum { a, b, c }
''';
    const expectedEdits = r'''
Delete 1:24-1:26
''';

    await _assertMinimalEdits(startContent, endContent, expectedEdits);
  }

  /// The formatter removes trailing whitespace from comments which results in
  /// differences in the comment token lexemes. This should
  /// be handled and not result in a full document edit.
  ///
  /// https://github.com/Dart-Code/Dart-Code/issues/5200
  Future<void> test_minimalEdits_comment_multiLine_trailingWhitespace() async {
    // The initial content has a trailing space on the end of the comment.
    const startContent = r'''
/**
 * line with trailing whitespace 
 * line with trailing whitespace 
 */
int? a;
''';
    // We expect the trailing spaces to be removed.
    const endContent = r'''
/**
 * line with trailing whitespace
 * line with trailing whitespace
 */
int? a;
''';

    // Expect the edit to replace the entire comment, minus the common
    // prefix/suffix. That is, it will replace from the end of the first line
    // of the comment (consuming the trailing whitespace) up up until the
    // trailing space of the second line.
    // We do not support minimizing the edits within the comment itself, because
    // we only diff tokens and not the string contents.
    const expectedEdits = r'''
Replace 2:33-3:34 with "\n * line with trailing whitespace"
''';

    await _assertMinimalEdits(
      startContent,
      endContent,
      expectedEdits,
    );
  }

  /// The formatter removes trailing whitespace from comments which results in
  /// differences in the comment token lexemes. This should
  /// be handled and not result in a full document edit.
  ///
  /// https://github.com/Dart-Code/Dart-Code/issues/5200
  Future<void> test_minimalEdits_comment_singleLine_trailingWhitespace() async {
    // The initial content has a trailing space on the end of the comment.
    const startContent = 'const a = 1; // a \nconst b = 2;';
    // We expect the trailing space will be removed.
    const endContent = 'const a = 1; // a\nconst b = 2;';

    // Expect the edit to be only the deletion of that one character, not a
    // full edit (or full replacement of the comment).
    const expectedEdits = r'''
Delete 1:18-1:19
''';

    await _assertMinimalEdits(
      startContent,
      endContent,
      expectedEdits,
    );
  }

  /// Empty collections that are unwrapped produce different tokens. This should
  /// be handled and not result in a full document edit.
  ///
  /// https://github.com/Dart-Code/Dart-Code/issues/5169
  Future<void> test_minimalEdits_emptyCollection() async {
    const startContent = '''
var a = <String>[
];
var b = '';
''';
    const endContent = '''
var a = <String>[];
var b = '';
''';
    // Expect the newline to be deleted.
    const expectedEdits = r'''
Delete 1:18-2:1
''';

    await _assertMinimalEdits(
      startContent,
      endContent,
      expectedEdits,
    );
  }

  Future<void> test_minimalEdits_formatting_shortStyle() async {
    const startContent = '''
// @dart = 3.5

void f({String argument1, String argument2}) {}

void g() {
  f(argument1: 'An argument', argument2: 'Another argument');
}
''';
    const endContent = '''
// @dart = 3.5

void f({String argument1, String argument2}) {}

void g() {
  f(argument1: 'An argument', argument2: 'Another argument');
}
''';
    const expectedEdits = '';

    await _assertMinimalEdits(startContent, endContent, expectedEdits);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/56685')
  Future<void> test_minimalEdits_formatting_tallStyle() async {
    const startContent = '''
void f({String? argument1, String? argument2}) {}

void g() {
  f(argument1: 'An argument', argument2: 'Another argument');
}
''';
    const endContent = '''
void f({String? argument1, String? argument2}) {}

void g() {
  f(argument1: 'An argument',
    argument2: 'Another argument',
  );
}
''';
    const expectedEdits = r'''
Insert "\n    " at 4:31
Insert ",\n" at 4:60
''';

    await _assertMinimalEdits(startContent, endContent, expectedEdits);
  }

  Future<void> test_minimalEdits_gt_2_combined() async {
    const startContent = '''
List<
  List<String>
> a = [];
''';
    const endContent = '''
List<List<String>> a = [];
''';
    const expectedEdits = r'''
Delete 1:6-2:3
Delete 2:15-3:1
''';

    await _assertMinimalEdits(startContent, endContent, expectedEdits);
  }

  Future<void> test_minimalEdits_gt_2_split() async {
    const startContent = '''
List<List<String>> a = [];
''';
    const endContent = '''
List<
  List<String>
> a = [];
''';
    const expectedEdits = r'''
Insert "\n  " at 1:6
Insert "\n" at 1:18
''';

    await _assertMinimalEdits(startContent, endContent, expectedEdits);
  }

  Future<void> test_minimalEdits_gt_3_combined() async {
    const startContent = '''
List<
  List<
    List<String>
  >
> a = [];
''';
    const endContent = '''
List<List<List<String>>> a = [];
''';
    const expectedEdits = r'''
Delete 1:6-2:3
Delete 2:8-3:5
Replace 3:17-5:1 with ">"
''';

    await _assertMinimalEdits(startContent, endContent, expectedEdits);
  }

  Future<void> test_minimalEdits_gt_3_split() async {
    const startContent = '''
List<List<List<String>>> a = [];
''';
    const endContent = '''
List<
  List<
    List<String>
  >
> a = [];
''';
    const expectedEdits = r'''
Insert "\n  " at 1:6
Insert "\n    " at 1:11
Replace 1:23-1:24 with "\n  >\n"
''';

    await _assertMinimalEdits(startContent, endContent, expectedEdits);
  }

  Future<void> test_minimalEdits_semicolon_remove() async {
    const startContent = '''
enum SomeEnum {
  a,
  b,
  c;
}
''';
    const endContent = '''
enum SomeEnum {
  a,
  b,
  c
}
''';
    const expectedEdits = r'''
Delete 4:4-4:5
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

  /// If we fail to compute minimal edits but were formatting the entire doc,
  /// we should just return the entire edit.
  Future<void> test_minimalEdits_withoutRange_wholeDocument() async {
    const startContent = '''
void f() {
}
''';
    // The simulated formatted content is different (`g` instead of `f`) which
    // will fail to produce minimal edits (since it varies by more than
    // whitespace).
    const endContent = '''
void g() {
}
''';
    const expectedEdits = r'''
Replace 1:1-2:2 with "void g() {\n}"
''';

    await _assertMinimalEdits(startContent, endContent, expectedEdits);
  }

  /// If we fail to compute minimal edits but were formatting a range,
  /// we should return no edits (rather than the entire document).
  ///
  /// https://github.com/Dart-Code/Dart-Code/issues/5169
  Future<void> test_minimalEdits_withRange_emptyResult() async {
    const startContent = '''
void f() {
}
''';
    // The simulated formatted content is different (`g` instead of `f`) which
    // will fail to produce minimal edits (since it varies by more than
    // whitespace).
    const endContent = '''
void g() {
}
''';
    const expectedEdits = r''; // No edits.

    await _assertMinimalEdits(
      startContent,
      endContent,
      expectedEdits,
      range: Range(
        start: Position(line: 1, character: 1),
        end: Position(line: 1, character: 1),
      ),
      // We should end with the original content because there was no
      // formatting.
      expectedFormatResult: startContent,
    );
  }

  /// Assert that generating edits to format [start] match those described
  /// in [expected] and when applied, result in [end].
  ///
  /// Edits will be automatically applied and verified. [expected] is to ensure
  /// the edits are minimal and we didn't accidentally produces a single edit
  /// replacing the entire file.
  Future<void> _assertFormatEdits(
    String start,
    String end,
    String expected, {
    String? expectedFormatResult,
    Range? range,
  }) async {
    await parseTestCode(start);
    var edits =
        generateEditsForFormatting(testParsedResult, range: range).result!;
    expect(edits.toText().trim(), expected.trim());
    expect(applyTextEdits(start, edits), expectedFormatResult ?? end);
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
    String expected, {
    String? expectedFormatResult,
    Range? range,
  }) async {
    start = start.trim();
    end = end.trim();
    expected = expected.trim();
    expectedFormatResult = expectedFormatResult?.trim();

    await parseTestCode(start);
    var edits = generateMinimalEdits(testParsedResult, end, range: range);
    expect(edits.toText().trim(), expected);
    expect(applyTextEdits(start, edits.result), expectedFormatResult ?? end);
  }

  /// Assert that formatting [content] produces no edits.
  Future<void> _assertNoFormatEdits(String content) async {
    await parseTestCode(content);
    var edits = generateEditsForFormatting(testParsedResult).result;
    expect(edits, isNull);
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
