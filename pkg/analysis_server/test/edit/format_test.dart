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
  void setUp() {
    super.setUp();
    createProject();
    handler = EditDomainHandler(server);
  }

  Future test_format_longLine() {
    var content = '''
fun(firstParam, secondParam, thirdParam, fourthParam) {
  if (firstParam.noNull && secondParam.noNull && thirdParam.noNull && fourthParam.noNull) {}
}
''';
    addTestFile(content);
    return waitForTasksFinished().then((_) {
      var formatResult = _formatAt(0, 3, lineLength: 100);

      expect(formatResult.edits, isNotNull);
      expect(formatResult.edits, hasLength(0));

      expect(formatResult.selectionOffset, equals(0));
      expect(formatResult.selectionLength, equals(3));
    });
  }

  Future test_format_noOp() {
    // Already formatted source
    addTestFile('''
main() {
  int x = 3;
}
''');
    return waitForTasksFinished().then((_) {
      var formatResult = _formatAt(0, 3);
      expect(formatResult.edits, isNotNull);
      expect(formatResult.edits, hasLength(0));
    });
  }

  Future test_format_noSelection() async {
    addTestFile('''
main() { int x = 3; }
''');
    await waitForTasksFinished();
    var formatResult = _formatAt(0, 0);

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

  Future test_format_simple() {
    addTestFile('''
main() { int x = 3; }
''');
    return waitForTasksFinished().then((_) {
      var formatResult = _formatAt(0, 3);

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
    });
  }

  Future test_format_withErrors() {
    addTestFile('''
main() { int x =
''');
    return waitForTasksFinished().then((_) {
      var request = EditFormatParams(testFile, 0, 3).toRequest('0');
      var response = handler.handleRequest(request);
      expect(response, isResponseFailure('0'));
    });
  }

  EditFormatResult _formatAt(int selectionOffset, int selectionLength,
      {int lineLength}) {
    var request = EditFormatParams(testFile, selectionOffset, selectionLength,
            lineLength: lineLength)
        .toRequest('0');
    var response = handleSuccessfulRequest(request);
    return EditFormatResult.fromResponse(response);
  }
}
