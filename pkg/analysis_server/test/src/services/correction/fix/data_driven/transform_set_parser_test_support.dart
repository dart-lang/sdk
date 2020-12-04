// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_parser.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';

import '../../../../../mocks.dart';
import '../../../../../utils/test_support.dart';

/// Utilities shared between tests of the [TransformSetParser].
abstract class AbstractTransformSetParserTest {
  /// The listener to which errors will be reported.
  GatheringErrorListener errorListener;

  /// The result of parsing the test file's content.
  TransformSet result;

  void assertErrors(String code, List<ExpectedError> expectedErrors) {
    parse(code);
    errorListener.assertErrors(expectedErrors);
  }

  void assertNoErrors(String content) {
    parse(content);
    errorListener.assertNoErrors();
  }

  ExpectedError error(ErrorCode code, int offset, int length,
          {String text,
          Pattern messageContains,
          List<ExpectedContextMessage> contextMessages =
              const <ExpectedContextMessage>[]}) =>
      ExpectedError(code, offset, length,
          message: text,
          messageContains: messageContains,
          expectedContextMessages: contextMessages);

  void parse(String content) {
    errorListener = GatheringErrorListener();
    var errorReporter = ErrorReporter(errorListener, MockSource('data.yaml'));
    var parser = TransformSetParser(errorReporter, 'myPackage');
    result = parser.parse(content);
  }
}
