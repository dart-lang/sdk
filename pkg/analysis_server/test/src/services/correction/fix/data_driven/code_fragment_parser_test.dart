// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/base/errors.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/accessor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/code_fragment_parser.dart';
import 'package:analyzer/error/listener.dart';
import 'package:matcher/matcher.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../../mocks.dart';
import '../../../../../utils/test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CodeFragmentParserTest);
  });
}

abstract class AbstractCodeFragmentParserTest {
  List<Accessor> assertErrors(
      String content, List<ExpectedError> expectedErrors) {
    var errorListener = GatheringErrorListener();
    var errorReporter = ErrorReporter(errorListener, MockSource());
    var accessors = CodeFragmentParser(errorReporter).parse(content, 0);
    errorListener.assertErrors(expectedErrors);
    return accessors;
  }

  List<Accessor> assertNoErrors(String content) {
    var errorListener = GatheringErrorListener();
    var errorReporter = ErrorReporter(errorListener, MockSource());
    var accessors = CodeFragmentParser(errorReporter).parse(content, 0);
    errorListener.assertNoErrors();
    return accessors;
  }

  ExpectedError error(ErrorCode code, int offset, int length,
          {String message,
          Pattern messageContains,
          List<ExpectedContextMessage> contextMessages =
              const <ExpectedContextMessage>[]}) =>
      ExpectedError(code, offset, length,
          message: message,
          messageContains: messageContains,
          expectedContextMessages: contextMessages);
}

@reflectiveTest
class CodeFragmentParserTest extends AbstractCodeFragmentParserTest {
  void test_arguments_arguments_arguments() {
    var accessors = assertNoErrors('arguments[0].arguments[1].arguments[2]');
    expect(accessors, hasLength(3));
  }

  void test_arguments_named() {
    var accessors = assertNoErrors('arguments[foo]');
    expect(accessors, hasLength(1));
  }

  void test_arguments_positional() {
    var accessors = assertNoErrors('arguments[0]');
    expect(accessors, hasLength(1));
  }

  void test_arguments_typeArguments() {
    var accessors = assertNoErrors('arguments[0].typeArguments[0]');
    expect(accessors, hasLength(2));
  }

  void test_typeArguments() {
    var accessors = assertNoErrors('typeArguments[0]');
    expect(accessors, hasLength(1));
  }
}
