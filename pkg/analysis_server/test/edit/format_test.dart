// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart';
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
    var formatResult = await _formatAt(0, 0);

    // Expect no edits, because the last overlay was already formatted.
    expect(formatResult.edits, hasLength(0));
  }

  Future<void> test_format_longLine_analysisOptions() async {
    writeTestPackageAnalysisOptionsFile(r'''
formatter:
  page_width: 100
''');
    var content = '''
fun(firstParam, secondParam, thirdParam, fourthParam) {
  if (firstParam.noNull && secondParam.noNull && thirdParam.noNull && fourthParam.noNull) {}
}
''';
    addTestFile(content);
    await waitForTasksFinished();
    var formatResult = await _formatAt(0, 3);

    expect(formatResult.edits, isNotNull);
    expect(formatResult.edits, hasLength(0));

    expect(formatResult.selectionOffset, equals(0));
    expect(formatResult.selectionLength, equals(3));
  }

  Future<void> test_format_longLine_analysisOptions_overridesParameter() async {
    writeTestPackageAnalysisOptionsFile(r'''
formatter:
  page_width: 100
''');
    var content = '''
fun(firstParam, secondParam, thirdParam, fourthParam) {
  if (firstParam.noNull && secondParam.noNull && thirdParam.noNull && fourthParam.noNull) {}
}
''';
    addTestFile(content);
    await waitForTasksFinished();
    var formatResult = await _formatAt(0, 3, lineLength: 50);

    expect(formatResult.edits, isNotNull);
    expect(formatResult.edits, hasLength(0));

    expect(formatResult.selectionOffset, equals(0));
    expect(formatResult.selectionLength, equals(3));
  }

  Future<void> test_format_longLine_parameter() async {
    var content = '''
fun(firstParam, secondParam, thirdParam, fourthParam) {
  if (firstParam.noNull && secondParam.noNull && thirdParam.noNull && fourthParam.noNull) {}
}
''';
    addTestFile(content);
    await waitForTasksFinished();
    var formatResult = await _formatAt(0, 3, lineLength: 100);

    expect(formatResult.edits, isNotNull);
    expect(formatResult.edits, hasLength(0));

    expect(formatResult.selectionOffset, equals(0));
    expect(formatResult.selectionLength, equals(3));
  }

  Future<void> test_format_noOp() async {
    // Already formatted source
    addTestFile('''
void f() {
  int x = 3;
}
''');
    await waitForTasksFinished();
    var formatResult = await _formatAt(0, 3);
    expect(formatResult.edits, isNotNull);
    expect(formatResult.edits, hasLength(0));
  }

  Future<void> test_format_noSelection() async {
    addTestFile('''
void f() { int x = 3; }
''');
    await waitForTasksFinished();
    var formatResult = await _formatAt(0, 0);

    expect(formatResult.edits, isNotNull);
    expect(formatResult.edits, hasLength(1));

    var edit = formatResult.edits[0];
    expect(
      edit.replacement,
      equals('''
void f() {
  int x = 3;
}
'''),
    );
    expect(formatResult.selectionOffset, equals(0));
    expect(formatResult.selectionLength, equals(0));
  }

  Future<void> test_format_simple() async {
    addTestFile('''
void f() { int x = 3; }
''');
    await waitForTasksFinished();
    var formatResult = await _formatAt(0, 3);

    expect(formatResult.edits, isNotNull);
    expect(formatResult.edits, hasLength(1));

    var edit = formatResult.edits[0];
    expect(
      edit.replacement,
      equals('''
void f() {
  int x = 3;
}
'''),
    );
    expect(formatResult.selectionOffset, equals(0));
    expect(formatResult.selectionLength, equals(3));
  }

  /// Verify version 2.19 is passed to the formatter so it will not produce any
  /// edits for code containing records (since it fails to parse).
  Future<void> test_format_version_2_19() async {
    writeTestPackageConfig(languageVersion: '2.19');
    addTestFile('''
var          a = (1, 2);
''');
    await waitForTasksFinished();
    await _expectFormatError(0, 3);
  }

  /// Verify version 3.0 is passed to the formatter so will produce edits for
  /// code containing records.
  Future<void> test_format_version_3_0() async {
    addTestFile('''
var          a = (1, 2);
''');
    await waitForTasksFinished();
    var formatResult = await _formatAt(0, 3);

    expect(formatResult.edits, isNotNull);
    expect(formatResult.edits, hasLength(1));
  }

  Future<void> test_format_withErrors() async {
    addTestFile('''
void f() { int x =
''');
    await waitForTasksFinished();
    await _expectFormatError(0, 3);
  }

  Future<void> _expectFormatError(
    int selectionOffset,
    int selectionLength, {
    int? lineLength,
  }) async {
    var request = EditFormatParams(
      testFile.path,
      selectionOffset,
      selectionLength,
      lineLength: lineLength,
    ).toRequest('0', clientUriConverter: server.uriConverter);
    var response = await handleRequest(request);
    expect(response, isResponseFailure('0'));
  }

  Future<EditFormatResult> _formatAt(
    int selectionOffset,
    int selectionLength, {
    int? lineLength,
  }) async {
    var request = EditFormatParams(
      testFile.path,
      selectionOffset,
      selectionLength,
      lineLength: lineLength,
    ).toRequest('0', clientUriConverter: server.uriConverter);
    var response = await handleSuccessfulRequest(request);
    return EditFormatResult.fromResponse(
      response,
      clientUriConverter: server.uriConverter,
    );
  }
}
