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
  Future<void> test_minimalEdits() async {
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
