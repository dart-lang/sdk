// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/edit/edit_domain.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';
import '../mocks.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FormatTest);
  });
}

@reflectiveTest
class FormatTest extends AbstractAnalysisTest {
  @override
  Future<void> setUp() async {
    super.setUp();
    await createProject();
    handler = EditDomainHandler(server);
  }

  Future<void> test_format_longLine() async {
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
main() {
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
main() { int x = 3; }
''');
    await waitForTasksFinished();
    var formatResult = await _formatAt(0, 0);

    expect(formatResult.edits, isNotNull);
    expect(formatResult.edits, hasLength(1));

    var edit = formatResult.edits[0];
    expect(edit.replacement, equals('''
main() {
  int x = 3;
}
'''));
    expect(formatResult.selectionOffset, equals(0));
    expect(formatResult.selectionLength, equals(0));
  }

  Future<void> test_format_simple() async {
    addTestFile('''
main() { int x = 3; }
''');
    await waitForTasksFinished();
    var formatResult = await _formatAt(0, 3);

    expect(formatResult.edits, isNotNull);
    expect(formatResult.edits, hasLength(1));

    var edit = formatResult.edits[0];
    expect(edit.replacement, equals('''
main() {
  int x = 3;
}
'''));
    expect(formatResult.selectionOffset, equals(0));
    expect(formatResult.selectionLength, equals(3));
  }

  Future<void> test_format_withErrors() async {
    addTestFile('''
main() { int x =
''');
    await waitForTasksFinished();
    var request = EditFormatParams(testFile, 0, 3).toRequest('0');
    var response = await waitResponse(request);
    expect(response, isResponseFailure('0'));
  }

  Future<EditFormatResult> _formatAt(int selectionOffset, int selectionLength,
      {int? lineLength}) async {
    var request = EditFormatParams(testFile, selectionOffset, selectionLength,
            lineLength: lineLength)
        .toRequest('0');
    var response = await waitResponse(request);
    return EditFormatResult.fromResponse(response);
  }
}
