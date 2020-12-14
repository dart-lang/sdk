// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/base/errors.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/accessor.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/code_fragment_parser.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/expression.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/value_generator.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/variable_scope.dart';
import 'package:analyzer/error/listener.dart';
import 'package:matcher/matcher.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../../mocks.dart';
import '../../../../../utils/test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AccessorsTest);
    defineReflectiveTests(ConditionTest);
  });
}

abstract class AbstractCodeFragmentParserTest {
  List<Accessor> assertErrors(
      String content, List<ExpectedError> expectedErrors) {
    var errorListener = GatheringErrorListener();
    var accessors = _parser(errorListener).parseAccessors(content, 0);
    errorListener.assertErrors(expectedErrors);
    return accessors;
  }

  Expression assertErrorsInCondition(String content, List<String> variables,
      List<ExpectedError> expectedErrors) {
    var errorListener = GatheringErrorListener();
    var expression =
        _parser(errorListener, variables: variables).parseCondition(content, 0);
    errorListener.assertErrors(expectedErrors);
    return expression;
  }

  List<Accessor> assertNoErrors(String content) {
    var errorListener = GatheringErrorListener();
    var accessors = _parser(errorListener).parseAccessors(content, 0);
    errorListener.assertNoErrors();
    return accessors;
  }

  Expression assertNoErrorsInCondition(String content,
      {List<String> variables}) {
    var errorListener = GatheringErrorListener();
    var expression =
        _parser(errorListener, variables: variables).parseCondition(content, 0);
    errorListener.assertNoErrors();
    return expression;
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

  CodeFragmentParser _parser(GatheringErrorListener listener,
      {List<String> variables}) {
    var errorReporter = ErrorReporter(listener, MockSource());
    var map = <String, ValueGenerator>{};
    if (variables != null) {
      for (var variableName in variables) {
        map[variableName] = CodeFragment([]);
      }
    }
    var scope = VariableScope(null, map);
    return CodeFragmentParser(errorReporter, scope: scope);
  }
}

@reflectiveTest
class AccessorsTest extends AbstractCodeFragmentParserTest {
  void test_arguments_arguments_arguments() {
    var accessors = assertNoErrors('arguments[0].arguments[1].arguments[2]');
    expect(accessors, hasLength(3));
    expect(accessors[0], isA<ArgumentAccessor>());
    expect(accessors[1], isA<ArgumentAccessor>());
    expect(accessors[2], isA<ArgumentAccessor>());
  }

  void test_arguments_named() {
    var accessors = assertNoErrors('arguments[foo]');
    expect(accessors, hasLength(1));
    expect(accessors[0], isA<ArgumentAccessor>());
  }

  void test_arguments_positional() {
    var accessors = assertNoErrors('arguments[0]');
    expect(accessors, hasLength(1));
    expect(accessors[0], isA<ArgumentAccessor>());
  }

  void test_arguments_typeArguments() {
    var accessors = assertNoErrors('arguments[0].typeArguments[0]');
    expect(accessors, hasLength(2));
    expect(accessors[0], isA<ArgumentAccessor>());
    expect(accessors[1], isA<TypeArgumentAccessor>());
  }

  void test_typeArguments() {
    var accessors = assertNoErrors('typeArguments[0]');
    expect(accessors, hasLength(1));
    expect(accessors[0], isA<TypeArgumentAccessor>());
  }
}

@reflectiveTest
class ConditionTest extends AbstractCodeFragmentParserTest {
  void test_and() {
    var expression = assertNoErrorsInCondition("'a' != 'b' && 'c' != 'd'")
        as BinaryExpression;
    expect(expression.leftOperand, isA<BinaryExpression>());
    expect(expression.operator, Operator.and);
    expect(expression.rightOperand, isA<BinaryExpression>());
  }

  void test_equal() {
    var expression = assertNoErrorsInCondition('a == b', variables: ['a', 'b'])
        as BinaryExpression;
    expect(expression.leftOperand, isA<VariableReference>());
    expect(expression.operator, Operator.equal);
    expect(expression.rightOperand, isA<VariableReference>());
  }

  void test_notEqual() {
    var expression = assertNoErrorsInCondition("a != 'b'", variables: ['a'])
        as BinaryExpression;
    expect(expression.leftOperand, isA<VariableReference>());
    expect(expression.operator, Operator.notEqual);
    expect(expression.rightOperand, isA<LiteralString>());
  }
}
