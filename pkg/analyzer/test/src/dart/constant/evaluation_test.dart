// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/resolver_test_case.dart';
import '../../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantVisitorTest);
  });
}

@reflectiveTest
class ConstantVisitorTest extends ResolverTestCase {
  test_visitBinaryExpression_questionQuestion_notNull_notNull() async {
    Expression left = AstTestFactory.string2('a');
    Expression right = AstTestFactory.string2('b');
    Expression expression = AstTestFactory.binaryExpression(
        left, TokenType.QUESTION_QUESTION, right);

    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = _evaluate(expression, errorReporter);
    expect(result, isNotNull);
    expect(result.isNull, isFalse);
    expect(result.toStringValue(), 'a');
    errorListener.assertNoErrors();
  }

  test_visitBinaryExpression_questionQuestion_null_notNull() async {
    Expression left = AstTestFactory.nullLiteral();
    Expression right = AstTestFactory.string2('b');
    Expression expression = AstTestFactory.binaryExpression(
        left, TokenType.QUESTION_QUESTION, right);

    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = _evaluate(expression, errorReporter);
    expect(result, isNotNull);
    expect(result.isNull, isFalse);
    expect(result.toStringValue(), 'b');
    errorListener.assertNoErrors();
  }

  test_visitBinaryExpression_questionQuestion_null_null() async {
    Expression left = AstTestFactory.nullLiteral();
    Expression right = AstTestFactory.nullLiteral();
    Expression expression = AstTestFactory.binaryExpression(
        left, TokenType.QUESTION_QUESTION, right);

    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = _evaluate(expression, errorReporter);
    expect(result, isNotNull);
    expect(result.isNull, isTrue);
    errorListener.assertNoErrors();
  }

  test_visitConditionalExpression_false() async {
    Expression thenExpression = AstTestFactory.integer(1);
    Expression elseExpression = AstTestFactory.integer(0);
    ConditionalExpression expression = AstTestFactory.conditionalExpression(
        AstTestFactory.booleanLiteral(false), thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    _assertValue(0, _evaluate(expression, errorReporter));
    errorListener.assertNoErrors();
  }

  test_visitConditionalExpression_nonBooleanCondition() async {
    Expression thenExpression = AstTestFactory.integer(1);
    Expression elseExpression = AstTestFactory.integer(0);
    NullLiteral conditionExpression = AstTestFactory.nullLiteral();
    ConditionalExpression expression = AstTestFactory.conditionalExpression(
        conditionExpression, thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = _evaluate(expression, errorReporter);
    expect(result, isNull);
    errorListener
        .assertErrorsWithCodes([CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL]);
  }

  test_visitConditionalExpression_nonConstantElse() async {
    Expression thenExpression = AstTestFactory.integer(1);
    Expression elseExpression = AstTestFactory.identifier3("x");
    ConditionalExpression expression = AstTestFactory.conditionalExpression(
        AstTestFactory.booleanLiteral(true), thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = _evaluate(expression, errorReporter);
    expect(result, isNull);
    errorListener
        .assertErrorsWithCodes([CompileTimeErrorCode.INVALID_CONSTANT]);
  }

  test_visitConditionalExpression_nonConstantThen() async {
    Expression thenExpression = AstTestFactory.identifier3("x");
    Expression elseExpression = AstTestFactory.integer(0);
    ConditionalExpression expression = AstTestFactory.conditionalExpression(
        AstTestFactory.booleanLiteral(true), thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    DartObjectImpl result = _evaluate(expression, errorReporter);
    expect(result, isNull);
    errorListener
        .assertErrorsWithCodes([CompileTimeErrorCode.INVALID_CONSTANT]);
  }

  test_visitConditionalExpression_true() async {
    Expression thenExpression = AstTestFactory.integer(1);
    Expression elseExpression = AstTestFactory.integer(0);
    ConditionalExpression expression = AstTestFactory.conditionalExpression(
        AstTestFactory.booleanLiteral(true), thenExpression, elseExpression);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter =
        new ErrorReporter(errorListener, _dummySource());
    _assertValue(1, _evaluate(expression, errorReporter));
    errorListener.assertNoErrors();
  }

  test_visitSimpleIdentifier_className() async {
    CompilationUnit compilationUnit = await resolveSource('''
const a = C;
class C {}
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'a', null);
    expect(result.type, typeProvider.typeType);
    expect(result.toTypeValue().name, 'C');
  }

  test_visitSimpleIdentifier_dynamic() async {
    CompilationUnit compilationUnit = await resolveSource('''
const a = dynamic;
''');
    DartObjectImpl result = _evaluateConstant(compilationUnit, 'a', null);
    expect(result.type, typeProvider.typeType);
    expect(result.toTypeValue(), typeProvider.dynamicType);
  }

  test_visitSimpleIdentifier_inEnvironment() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const a = b;
const b = 3;''');
    Map<String, DartObjectImpl> environment = new Map<String, DartObjectImpl>();
    DartObjectImpl six =
        new DartObjectImpl(typeProvider.intType, new IntState(6));
    environment["b"] = six;
    _assertValue(6, _evaluateConstant(compilationUnit, "a", environment));
  }

  test_visitSimpleIdentifier_notInEnvironment() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const a = b;
const b = 3;''');
    Map<String, DartObjectImpl> environment = new Map<String, DartObjectImpl>();
    DartObjectImpl six =
        new DartObjectImpl(typeProvider.intType, new IntState(6));
    environment["c"] = six;
    _assertValue(3, _evaluateConstant(compilationUnit, "a", environment));
  }

  test_visitSimpleIdentifier_withoutEnvironment() async {
    CompilationUnit compilationUnit = await resolveSource(r'''
const a = b;
const b = 3;''');
    _assertValue(3, _evaluateConstant(compilationUnit, "a", null));
  }

  void _assertValue(int expectedValue, DartObjectImpl result) {
    expect(result, isNotNull);
    expect(result.type.name, "int");
    expect(result.toIntValue(), expectedValue);
  }

  NonExistingSource _dummySource() {
    String path = '/test.dart';
    return new NonExistingSource(path, toUri(path), UriKind.FILE_URI);
  }

  DartObjectImpl _evaluate(Expression expression, ErrorReporter errorReporter) {
    TestTypeProvider typeProvider = new TestTypeProvider();
    return expression.accept(new ConstantVisitor(
        new ConstantEvaluationEngine(typeProvider, new DeclaredVariables(),
            typeSystem: new StrongTypeSystemImpl(typeProvider)),
        errorReporter));
  }

  DartObjectImpl _evaluateConstant(CompilationUnit compilationUnit, String name,
      Map<String, DartObjectImpl> lexicalEnvironment) {
    Source source =
        resolutionMap.elementDeclaredByCompilationUnit(compilationUnit).source;
    Expression expression =
        findTopLevelConstantExpression(compilationUnit, name);
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ErrorReporter errorReporter = new ErrorReporter(errorListener, source);
    DartObjectImpl result = expression.accept(new ConstantVisitor(
        new ConstantEvaluationEngine(typeProvider, new DeclaredVariables(),
            typeSystem: typeSystem),
        errorReporter,
        lexicalEnvironment: lexicalEnvironment));
    errorListener.assertNoErrors();
    return result;
  }
}
