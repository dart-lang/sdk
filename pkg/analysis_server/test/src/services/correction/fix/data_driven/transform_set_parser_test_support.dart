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
  /// The listener to which diagnostics are reported.
  GatheringDiagnosticListener diagnosticListener =
      GatheringDiagnosticListener();

  /// The result of parsing the test file's content.
  TransformSet? result;

  void assertErrors(String code, List<ExpectedError> expectedErrors) {
    parse(code);
    diagnosticListener.assertErrors(expectedErrors);
  }

  void assertNoErrors(String content) {
    parse(content);
    diagnosticListener.assertNoErrors();
  }

  ExpectedError error(
    DiagnosticCode code,
    int offset,
    int length, {
    String? text,
    Pattern? messageContains,
    List<ExpectedContextMessage> contextMessages =
        const <ExpectedContextMessage>[],
  }) => ExpectedError(
    code,
    offset,
    length,
    message: text,
    messageContains: messageContains,
    expectedContextMessages: contextMessages,
  );

  void parse(String content) {
    var diagnosticReporter = DiagnosticReporter(
      diagnosticListener,
      MockSource(fullName: 'data.yaml'),
    );
    var parser = TransformSetParser(diagnosticReporter, 'myPackage');
    result = parser.parse(content);
  }
}
