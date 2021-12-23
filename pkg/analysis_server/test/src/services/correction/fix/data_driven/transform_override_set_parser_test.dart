// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/base/errors.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_override_set.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_override_set_parser.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_error_code.dart';
import 'package:analyzer/error/listener.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../../mocks.dart';
import '../../../../../utils/test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TransformOverrideSetParserTest);
  });
}

/// Utilities shared between tests of the [TransformOverrideSetParser].
abstract class AbstractTransformOverrideSetParserTest {
  /// The listener to which errors will be reported.
  late GatheringErrorListener errorListener;

  /// The result of parsing the test file's content.
  TransformOverrideSet? result;

  void assertErrors(String code, List<ExpectedError> expectedErrors) {
    parse(code);
    errorListener.assertErrors(expectedErrors);
  }

  void assertNoErrors(String content) {
    parse(content);
    errorListener.assertNoErrors();
  }

  void assertOverride(String title, {bool? bulkApply}) {
    var override = result!.overrideForTransform(title)!;
    if (bulkApply != null) {
      expect(override.bulkApply, bulkApply);
    }
  }

  ExpectedError error(ErrorCode code, int offset, int length,
          {String? text,
          Pattern? messageContains,
          List<ExpectedContextMessage> contextMessages =
              const <ExpectedContextMessage>[]}) =>
      ExpectedError(code, offset, length,
          message: text,
          messageContains: messageContains,
          expectedContextMessages: contextMessages);

  void parse(String content) {
    errorListener = GatheringErrorListener();
    var errorReporter =
        ErrorReporter(errorListener, MockSource(fullName: 'data.yaml'));
    var parser = TransformOverrideSetParser(errorReporter);
    result = parser.parse(content);
  }
}

@reflectiveTest
class TransformOverrideSetParserTest
    extends AbstractTransformOverrideSetParserTest {
  void test_emptyFile() {
    assertErrors('''
''', [error(TransformSetErrorCode.invalidValue, 0, 0)]);
    expect(result, isNull);
  }

  void test_oneTransform() {
    assertNoErrors('''
"transform one":
  bulkApply: true
''');
    assertOverride('transform one', bulkApply: true);
  }

  void test_twoTransforms() {
    assertNoErrors('''
"transform one":
  bulkApply: false
"transform two":
  bulkApply: true
''');
    assertOverride('transform one', bulkApply: false);
    assertOverride('transform two', bulkApply: true);
  }
}
