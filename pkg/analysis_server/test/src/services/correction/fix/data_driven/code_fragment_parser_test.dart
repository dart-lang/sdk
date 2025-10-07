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
  // ignore:unreachable_from_main
  List<Accessor>? assertErrors(
    String content,
    List<ExpectedError> expectedErrors,
  ) {
    var diagnosticListener = GatheringDiagnosticListener();
    var accessors = _parser(diagnosticListener).parseAccessors(content, 0);
    diagnosticListener.assertErrors(expectedErrors);
    return accessors;
  }

  List<Accessor> assertNoErrors(String content) {
    var diagnosticListener = GatheringDiagnosticListener();
    var accessors = _parser(diagnosticListener).parseAccessors(content, 0)!;
    diagnosticListener.assertNoErrors();
    return accessors;
  }

  Expression assertNoErrorsInCondition(
    String content, {
    List<String>? variables,
  }) {
    var diagnosticListener = GatheringDiagnosticListener();
    var expression = _parser(
      diagnosticListener,
      variables: variables,
    ).parseCondition(content, 0)!;
    diagnosticListener.assertNoErrors();
    return expression;
  }

  // ignore:unreachable_from_main
  ExpectedError error(
    DiagnosticCode code,
    int offset,
    int length, {
    String? message,
    Pattern? messageContains,
    List<ExpectedContextMessage> contextMessages =
        const <ExpectedContextMessage>[],
  }) => ExpectedError(
    code,
    offset,
    length,
    message: message,
    messageContains: messageContains,
    expectedContextMessages: contextMessages,
  );

  CodeFragmentParser _parser(
    GatheringDiagnosticListener listener, {
    List<String>? variables,
  }) {
    var diagnosticReporter = DiagnosticReporter(listener, MockSource());
    var map = <String, ValueGenerator>{};
    if (variables != null) {
      for (var variableName in variables) {
        map[variableName] = CodeFragment([]);
      }
    }
    var scope = VariableScope(null, map);
    return CodeFragmentParser(diagnosticReporter, scope: scope);
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
    var expression =
        assertNoErrorsInCondition("'a' != 'b' && 'c' != 'd'")
            as BinaryExpression;
    expect(expression.leftOperand, isA<BinaryExpression>());
    expect(expression.operator, Operator.and);
    expect(expression.rightOperand, isA<BinaryExpression>());
  }

  void test_equal() {
    var expression =
        assertNoErrorsInCondition('a == b', variables: ['a', 'b'])
            as BinaryExpression;
    expect(expression.leftOperand, isA<VariableReference>());
    expect(expression.operator, Operator.equal);
    expect(expression.rightOperand, isA<VariableReference>());
  }

  void test_notEqual() {
    var expression =
        assertNoErrorsInCondition("a != 'b'", variables: ['a'])
            as BinaryExpression;
    expect(expression.leftOperand, isA<VariableReference>());
    expect(expression.operator, Operator.notEqual);
    expect(expression.rightOperand, isA<LiteralString>());
  }
}
