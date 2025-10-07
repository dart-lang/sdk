// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_server_base.dart';
import '../mocks.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FormatTest);
  });
}

@reflectiveTest
class FormatTest extends PubPackageAnalysisServerTest {
  @override
  Future<void> setUp() async {
    super.setUp();
    await setRoots(included: [workspaceRootPath], excluded: []);
  }

  /// Verify that an overlay change is reflected in a format request that
  /// is sent immediately without waiting.
  ///
  /// https://github.com/dart-lang/sdk/issues/57120
  Future<void> test_format_immediatelyAfterOverlayChange() async {
    var initialContentNeedsFormatting = 'void main() {                       }';
    var updatedContentNeedsNoFormatting =
        "void main() {\n  print('hello world');\n}\n";

    // Set the initial content to something that will produce format edits.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFile.path: AddContentOverlay(initialContentNeedsFormatting),
      }).toRequest('1', clientUriConverter: server.uriConverter),
    );
    // Update the content to something that will not produce edits, but do not
    // await, because we are testing that the server is consistent even if it
    // doesn't have time to handle the change.
    unawaited(
      handleSuccessfulRequest(
        AnalysisUpdateContentParams({
          testFile.path: AddContentOverlay(updatedContentNeedsNoFormatting),
        }).toRequest('2', clientUriConverter: server.uriConverter),
      ),
    );
    var formatResult = await _format();

    // Expect no edits, because the last overlay was already formatted.
    expect(formatResult.edits, hasLength(0));
  }

  Future<void> test_format_longLine_analysisOptions() async {
    writeTestPackageAnalysisOptionsFile(r'''
formatter:
  page_width: 100
''');
    await _expectNoFormatting('''
fun(firstParam, secondParam, thirdParam, fourthParam) {
  if (firstParam.noNull && secondParam.noNull && thirdParam.noNull && fourthParam.noNull) {}
}
''');
  }

  Future<void> test_format_longLine_analysisOptions_overridesParameter() async {
    writeTestPackageAnalysisOptionsFile(r'''
formatter:
  page_width: 100
''');
    await _expectNoFormatting('''
fun(firstParam, secondParam, thirdParam, fourthParam) {
  if (firstParam.noNull && secondParam.noNull && thirdParam.noNull && fourthParam.noNull) {}
}
''', lineLength: 50);
  }

  Future<void> test_format_longLine_parameter() async {
    await _expectNoFormatting('''
fun(firstParam, secondParam, thirdParam, fourthParam) {
  if (firstParam.noNull && secondParam.noNull && thirdParam.noNull && fourthParam.noNull) {}
}
''', lineLength: 100);
  }

  Future<void> test_format_noOp() async {
    // Already formatted source
    await _expectNoFormatting('''
void f() {
  int x = 3;
}
''');
  }

  Future<void> test_format_noSelection() async {
    var content = '''
void f() { int x = 3; }
''';

    var expected = '''
void f() {
  int x = 3;
}
''';
    await _expectFormatted(content, expected);
  }

  Future<void> test_format_simple() async {
    var content = '''
void f() { [!int!] x = 3; }
''';
    var expected = '''
void f() {
  [!int!] x = 3;
}
''';
    await _expectFormatted(content, expected);
  }

  Future<void> test_format_trailingCommas_automate() async {
    writeTestPackageAnalysisOptionsFile(r'''
formatter:
  trailing_commas: automate
''');
    var content = '''
enum A {
  a,
  b,
}
''';
    var expected = '''
enum A { a, b }
''';
    await _expectFormatted(content, expected);
  }

  Future<void> test_format_trailingCommas_preserve() async {
    writeTestPackageAnalysisOptionsFile(r'''
formatter:
  trailing_commas: preserve
''');
    var content = '''
enum A { a, b, }
''';
    var expected = '''
enum A {
  a,
  b,
}
''';
    await _expectFormatted(content, expected);
  }

  Future<void> test_format_trailingCommas_unspecified() async {
    var content = '''
enum A {
  a,
  b,
}
''';
    var expected = '''
enum A { a, b }
''';
    await _expectFormatted(content, expected);
  }

  /// Verify version 2.19 is passed to the formatter so it will not produce any
  /// edits for code containing records (since it fails to parse).
  Future<void> test_format_version_2_19() async {
    writeTestPackageConfig(languageVersion: '2.19');
    await _expectFormatError('''
var          a = (1, 2);
''');
  }

  /// Verify version 3.0 is passed to the formatter so will produce edits for
  /// code containing records.
  Future<void> test_format_version_3_0() async {
    var content = '''
var          a = (1, 2);
''';
    var expected = '''
var a = (1, 2);
''';
    await _expectFormatted(content, expected);
  }

  Future<void> test_format_withErrors() async {
    await _expectFormatError('''
void f() { int x =
''');
  }

  Future<void> _expectFormatError(String content) async {
    addTestFile(content);
    await waitForTasksFinished();

    var request = EditFormatParams(
      testFile.path,
      0,
      0,
    ).toRequest('0', clientUriConverter: server.uriConverter);
    var response = await handleRequest(request);
    expect(response, isResponseFailure('0'));
  }

  Future<void> _expectFormatted(String content, String expectedContent) async {
    addTestFile(content);
    var selection = parsedTestCode.ranges.isNotEmpty
        ? parsedTestCode.range.sourceRange
        : SourceRange(0, 0);

    var expectedCode = TestCode.parseNormalized(expectedContent);
    var expectedSelection = expectedCode.ranges.isNotEmpty
        ? expectedCode.range.sourceRange
        : SourceRange(0, 0);

    await waitForTasksFinished();
    var formatResult = await _format(selection: selection);

    expect(formatResult.edits, isNotNull);
    expect(formatResult.edits, hasLength(1));

    var edit = formatResult.edits[0];
    expect(edit.replacement, equals(expectedCode.code));
    expect(formatResult.selectionOffset, equals(expectedSelection.offset));
    expect(formatResult.selectionLength, equals(expectedSelection.length));
  }

  Future<void> _expectNoFormatting(String content, {int? lineLength}) async {
    addTestFile(content);
    await waitForTasksFinished();
    var selection = parsedRanges.isNotEmpty
        ? parsedSourceRange
        : SourceRange(0, 0);
    var formatResult = await _format(
      selection: selection,
      lineLength: lineLength,
    );

    expect(formatResult.edits, isNotNull);
    expect(formatResult.edits, hasLength(0));

    // No change in selection
    expect(formatResult.selectionOffset, equals(selection.offset));
    expect(formatResult.selectionLength, equals(selection.length));
  }

  Future<EditFormatResult> _format({
    SourceRange? selection,
    int? lineLength,
  }) async {
    var request = EditFormatParams(
      testFile.path,
      selection?.offset ?? 0,
      selection?.length ?? 0,
      lineLength: lineLength,
    ).toRequest('0', clientUriConverter: server.uriConverter);
    var response = await handleSuccessfulRequest(request);
    return EditFormatResult.fromResponse(
      response,
      clientUriConverter: server.uriConverter,
    );
  }
}
