// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../util/ast_type_matchers.dart';
import 'parser_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ComplexParserTest);
  });
}

/// The class `ComplexParserTest` defines parser tests that test the parsing of
/// more complex code fragments or the interactions between multiple parsing
/// methods. For example, tests to ensure that the precedence of operations is
/// being handled correctly should be defined in this class.
///
/// Simpler tests should be defined in the class [SimpleParserTest].
@reflectiveTest
class ComplexParserTest extends FastaParserTestCase {
  void test_additiveExpression_normal() {
    BinaryExpression expression = parseExpression("x + y - z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_additiveExpression_noSpaces() {
    BinaryExpression expression = parseExpression("i+1");
    expect(expression.leftOperand, isSimpleIdentifier);
    expect(expression.rightOperand, isIntegerLiteral);
  }

  void test_additiveExpression_precedence_multiplicative_left() {
    BinaryExpression expression = parseExpression("x * y + z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_additiveExpression_precedence_multiplicative_left_withSuper() {
    BinaryExpression expression = parseExpression("super * y - z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_additiveExpression_precedence_multiplicative_right() {
    BinaryExpression expression = parseExpression("x + y * z");
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_additiveExpression_super() {
    BinaryExpression expression = parseExpression("super + y - z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_assignableExpression_arguments_normal_chain() {
    PropertyAccess propertyAccess1 = parseExpression("a(b)(c).d(e).f");
    expect(propertyAccess1.propertyName.name, "f");
    //
    // a(b)(c).d(e)
    //
    MethodInvocation invocation2 = propertyAccess1.target;
    expect(invocation2.methodName.name, "d");
    expect(invocation2.typeArguments, isNull);
    ArgumentList argumentList2 = invocation2.argumentList;
    expect(argumentList2, isNotNull);
    expect(argumentList2.arguments, hasLength(1));
    //
    // a(b)(c)
    //
    FunctionExpressionInvocation invocation3 = invocation2.target;
    expect(invocation3.typeArguments, isNull);
    ArgumentList argumentList3 = invocation3.argumentList;
    expect(argumentList3, isNotNull);
    expect(argumentList3.arguments, hasLength(1));
    //
    // a(b)
    //
    MethodInvocation invocation4 = invocation3.function;
    expect(invocation4.methodName.name, "a");
    expect(invocation4.typeArguments, isNull);
    ArgumentList argumentList4 = invocation4.argumentList;
    expect(argumentList4, isNotNull);
    expect(argumentList4.arguments, hasLength(1));
  }

  void test_assignableExpression_arguments_normal_chain_typeArguments() {
    _validate_assignableExpression_arguments_normal_chain_typeArguments(
        "a<E>(b)<F>(c).d<G>(e).f");
  }

  void test_assignmentExpression_compound() {
    AssignmentExpression expression = parseExpression("x = y = 0");
    expect(expression.leftHandSide, isSimpleIdentifier);
    expect(expression.rightHandSide, isAssignmentExpression);
  }

  void test_assignmentExpression_indexExpression() {
    AssignmentExpression expression = parseExpression("x[1] = 0");
    expect(expression.leftHandSide, isIndexExpression);
    expect(expression.rightHandSide, isIntegerLiteral);
  }

  void test_assignmentExpression_prefixedIdentifier() {
    AssignmentExpression expression = parseExpression("x.y = 0");
    expect(expression.leftHandSide, isPrefixedIdentifier);
    expect(expression.rightHandSide, isIntegerLiteral);
  }

  void test_assignmentExpression_propertyAccess() {
    AssignmentExpression expression = parseExpression("super.y = 0");
    expect(expression.leftHandSide, isPropertyAccess);
    expect(expression.rightHandSide, isIntegerLiteral);
  }

  void test_binary_operator_written_out_expression() {
    var expression = parseExpression('x xor y', errors: [
      expectedError(ParserErrorCode.BINARY_OPERATOR_WRITTEN_OUT, 2, 3),
    ]) as BinaryExpression;
    var lhs = expression.leftOperand as SimpleIdentifier;
    expect(lhs.name, 'x');
    expect(expression.operator.lexeme, '^');
    var rhs = expression.rightOperand as SimpleIdentifier;
    expect(rhs.name, 'y');
  }

  void test_bitwiseAndExpression_normal() {
    BinaryExpression expression = parseExpression("x & y & z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseAndExpression_precedence_equality_left() {
    BinaryExpression expression = parseExpression("x == y && z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseAndExpression_precedence_equality_right() {
    BinaryExpression expression = parseExpression("x && y == z");
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_bitwiseAndExpression_super() {
    BinaryExpression expression = parseExpression("super & y & z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseOrExpression_normal() {
    BinaryExpression expression = parseExpression("x | y | z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseOrExpression_precedence_xor_left() {
    BinaryExpression expression = parseExpression("x ^ y | z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseOrExpression_precedence_xor_right() {
    BinaryExpression expression = parseExpression("x | y ^ z");
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_bitwiseOrExpression_super() {
    BinaryExpression expression = parseExpression("super | y | z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseXorExpression_normal() {
    BinaryExpression expression = parseExpression("x ^ y ^ z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseXorExpression_precedence_and_left() {
    BinaryExpression expression = parseExpression("x & y ^ z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_bitwiseXorExpression_precedence_and_right() {
    BinaryExpression expression = parseExpression("x ^ y & z");
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_bitwiseXorExpression_super() {
    BinaryExpression expression = parseExpression("super ^ y ^ z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_cascade_withAssignment() {
    CascadeExpression cascade =
        parseExpression("new Map()..[3] = 4 ..[0] = 11");
    Expression target = cascade.target;
    for (Expression section in cascade.cascadeSections) {
      expect(section, isAssignmentExpression);
      Expression lhs = (section as AssignmentExpression).leftHandSide;
      expect(lhs, isIndexExpression);
      IndexExpression index = lhs as IndexExpression;
      expect(index.isCascaded, isTrue);
      expect(index.realTarget, same(target));
    }
  }

  void test_conditionalExpression_precedence_ifNullExpression() {
    ConditionalExpression expression = parseExpression('a ?? b ? y : z');
    expect(expression.condition, isBinaryExpression);
  }

  void test_conditionalExpression_precedence_logicalOrExpression() {
    ConditionalExpression expression = parseExpression("a | b ? y : z");
    expect(expression.condition, isBinaryExpression);
  }

  void test_conditionalExpression_precedence_nullableType_as() {
    ExpressionStatement statement = parseStatement('x as bool ? (x + y) : z;');
    ConditionalExpression expression = statement.expression;
    Expression condition = expression.condition;
    expect(condition, isAsExpression);
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, isParenthesizedExpression);
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, isSimpleIdentifier);
  }

  void test_conditionalExpression_precedence_nullableType_as2() {
    var statement =
        parseStatement('x as bool? ? (x + y) : z;') as ExpressionStatement;
    var expression = statement.expression as ConditionalExpression;
    var asExpression = expression.condition as AsExpression;
    var type = asExpression.type as TypeName;
    expect(type.question.lexeme, '?');
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, isParenthesizedExpression);
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, isSimpleIdentifier);
    assertNoErrors();
  }

  void test_conditionalExpression_precedence_nullableType_as3() {
    var statement =
        parseStatement('(x as bool?) ? (x + y) : z;') as ExpressionStatement;
    var expression = statement.expression as ConditionalExpression;
    var condition = expression.condition as ParenthesizedExpression;
    var asExpression = condition.expression as AsExpression;
    var type = asExpression.type as TypeName;
    expect(type.question.lexeme, '?');
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, isParenthesizedExpression);
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, isSimpleIdentifier);
    assertNoErrors();
  }

  void test_conditionalExpression_precedence_nullableType_is() {
    ExpressionStatement statement =
        parseStatement('x is String ? (x + y) : z;');
    ConditionalExpression expression = statement.expression;
    Expression condition = expression.condition;
    expect(condition, isIsExpression);
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, isParenthesizedExpression);
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, isSimpleIdentifier);
  }

  void test_conditionalExpression_precedence_nullableType_is2() {
    var statement =
        parseStatement('x is String? ? (x + y) : z;') as ExpressionStatement;
    var expression = statement.expression as ConditionalExpression;
    var isExpression = expression.condition as IsExpression;
    var type = isExpression.type as TypeName;
    expect(type.question.lexeme, '?');
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, isParenthesizedExpression);
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, isSimpleIdentifier);
    assertNoErrors();
  }

  void test_conditionalExpression_precedence_nullableType_is3() {
    var statement =
        parseStatement('(x is String?) ? (x + y) : z;') as ExpressionStatement;
    var expression = statement.expression as ConditionalExpression;
    var condition = expression.condition as ParenthesizedExpression;
    var isExpression = condition.expression as IsExpression;
    var type = isExpression.type as TypeName;
    expect(type.question.lexeme, '?');
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, isParenthesizedExpression);
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, isSimpleIdentifier);
    assertNoErrors();
  }

  void test_conditionalExpression_precedence_nullableTypeWithTypeArg1_is() {
    ExpressionStatement statement =
        parseStatement('x is String<S> ? (x + y) : z;');
    ConditionalExpression expression = statement.expression;
    Expression condition = expression.condition;
    expect(condition, TypeMatcher<IsExpression>());
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, TypeMatcher<ParenthesizedExpression>());
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, TypeMatcher<SimpleIdentifier>());
  }

  void test_conditionalExpression_precedence_nullableTypeWithTypeArg1GFT_is() {
    ExpressionStatement statement =
        parseStatement('x is String<S> Function() ? (x + y) : z;');
    ConditionalExpression expression = statement.expression;
    Expression condition = expression.condition;
    expect(condition, TypeMatcher<IsExpression>());
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, TypeMatcher<ParenthesizedExpression>());
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, TypeMatcher<SimpleIdentifier>());
  }

  void test_conditionalExpression_precedence_nullableTypeWithTypeArg2_is() {
    ExpressionStatement statement =
        parseStatement('x is String<S,T> ? (x + y) : z;');
    ConditionalExpression expression = statement.expression;
    Expression condition = expression.condition;
    expect(condition, TypeMatcher<IsExpression>());
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, TypeMatcher<ParenthesizedExpression>());
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, TypeMatcher<SimpleIdentifier>());
  }

  void test_conditionalExpression_precedence_prefixedNullableType_is() {
    ExpressionStatement statement = parseStatement('x is p.A ? (x + y) : z;');
    ConditionalExpression expression = statement.expression;

    Expression condition = expression.condition;
    expect(condition, TypeMatcher<IsExpression>());
    Expression thenExpression = expression.thenExpression;
    expect(thenExpression, TypeMatcher<ParenthesizedExpression>());
    Expression elseExpression = expression.elseExpression;
    expect(elseExpression, TypeMatcher<SimpleIdentifier>());
  }

  void test_conditionalExpression_precedence_withAssignment() {
    ExpressionStatement statement = parseStatement('b ? c = true : g();');
    ConditionalExpression expression = statement.expression;
    expect(expression.condition, TypeMatcher<SimpleIdentifier>());
    expect(expression.thenExpression, TypeMatcher<AssignmentExpression>());
  }

  void test_conditionalExpression_precedence_withAssignment2() {
    ExpressionStatement statement = parseStatement('b.x ? c = true : g();');
    ConditionalExpression expression = statement.expression;
    expect(expression.condition, TypeMatcher<PrefixedIdentifier>());
    expect(expression.thenExpression, TypeMatcher<AssignmentExpression>());
  }

  void test_conditionalExpression_prefixedValue() {
    ExpressionStatement statement = parseStatement('a.b ? y : z;');
    ConditionalExpression expression = statement.expression;
    expect(expression.condition, TypeMatcher<PrefixedIdentifier>());
    expect(expression.thenExpression, TypeMatcher<SimpleIdentifier>());
  }

  void test_conditionalExpression_prefixedValue2() {
    ExpressionStatement statement = parseStatement('a.b ? x.y : z;');
    ConditionalExpression expression = statement.expression;
    expect(expression.condition, TypeMatcher<PrefixedIdentifier>());
    expect(expression.thenExpression, TypeMatcher<PrefixedIdentifier>());
  }

  void test_constructor_initializer_withParenthesizedExpression() {
    CompilationUnit unit = parseCompilationUnit(r'''
class C {
  C() :
    this.a = (b == null ? c : d) {
  }
}''');
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
  }

  void test_equalityExpression_normal() {
    BinaryExpression expression = parseExpression("x == y != z",
        codes: [ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND]);
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_equalityExpression_precedence_relational_left() {
    BinaryExpression expression = parseExpression("x is y == z");
    expect(expression.leftOperand, isIsExpression);
  }

  void test_equalityExpression_precedence_relational_right() {
    BinaryExpression expression = parseExpression("x == y is z");
    expect(expression.rightOperand, isIsExpression);
  }

  void test_equalityExpression_super() {
    BinaryExpression expression = parseExpression("super == y != z",
        codes: [ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND]);
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_ifNullExpression() {
    BinaryExpression expression = parseExpression('x ?? y ?? z');
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_ifNullExpression_precedence_logicalOr_left() {
    BinaryExpression expression = parseExpression('x || y ?? z');
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_ifNullExpression_precedence_logicalOr_right() {
    BinaryExpression expression = parseExpression('x ?? y || z');
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_logicalAndExpression() {
    BinaryExpression expression = parseExpression("x && y && z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_logicalAndExpression_precedence_bitwiseOr_left() {
    BinaryExpression expression = parseExpression("x | y < z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_logicalAndExpression_precedence_bitwiseOr_right() {
    BinaryExpression expression = parseExpression("x < y | z");
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_logicalAndExpressionStatement() {
    // Assert that `<` and `>` are not interpreted as type arguments.
    ExpressionStatement statement = parseStatement("C<T && T>U;");
    BinaryExpression expression = statement.expression;
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_logicalOrExpression() {
    BinaryExpression expression = parseExpression("x || y || z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_logicalOrExpression_precedence_logicalAnd_left() {
    BinaryExpression expression = parseExpression("x && y || z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_logicalOrExpression_precedence_logicalAnd_right() {
    BinaryExpression expression = parseExpression("x || y && z");
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_methodInvocation1() {
    // Assert that `<` and `>` are not interpreted as type arguments.
    ExpressionStatement statement = parseStatement("f(a < b, c > 3);");
    assertNoErrors();
    MethodInvocation method = statement.expression;
    expect(method.argumentList.arguments, hasLength(2));
  }

  void test_methodInvocation2() {
    // Assert that `<` and `>` are not interpreted as type arguments.
    ExpressionStatement statement = parseStatement("f(a < b, c >> 3);");
    assertNoErrors();
    MethodInvocation method = statement.expression;
    expect(method.argumentList.arguments, hasLength(2));
  }

  void test_methodInvocation3() {
    // Assert that `<` and `>` are not interpreted as type arguments.
    ExpressionStatement statement = parseStatement("f(a < b, c < d >> 3);");
    assertNoErrors();
    MethodInvocation method = statement.expression;
    expect(method.argumentList.arguments, hasLength(2));
  }

  void test_multipleLabels_statement() {
    LabeledStatement statement = parseStatement("a: b: c: return x;");
    expect(statement.labels, hasLength(3));
    expect(statement.statement, isReturnStatement);
  }

  void test_multiplicativeExpression_normal() {
    BinaryExpression expression = parseExpression("x * y / z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_multiplicativeExpression_precedence_unary_left() {
    BinaryExpression expression = parseExpression("-x * y");
    expect(expression.leftOperand, isPrefixExpression);
  }

  void test_multiplicativeExpression_precedence_unary_right() {
    BinaryExpression expression = parseExpression("x * -y");
    expect(expression.rightOperand, isPrefixExpression);
  }

  void test_multiplicativeExpression_super() {
    BinaryExpression expression = parseExpression("super * y / z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_relationalExpression_precedence_shift_right() {
    IsExpression expression = parseExpression("x << y is z");
    expect(expression.expression, isBinaryExpression);
  }

  void test_shiftExpression_normal() {
    BinaryExpression expression = parseExpression("x >> 4 << 3");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_shiftExpression_precedence_additive_left() {
    BinaryExpression expression = parseExpression("x + y << z");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_shiftExpression_precedence_additive_right() {
    BinaryExpression expression = parseExpression("x << y + z");
    expect(expression.rightOperand, isBinaryExpression);
  }

  void test_shiftExpression_super() {
    BinaryExpression expression = parseExpression("super >> 4 << 3");
    expect(expression.leftOperand, isBinaryExpression);
  }

  void test_topLevelFunction_nestedGenericFunction() {
    parseCompilationUnit('''
void f() {
  void g<T>() {
  }
}
''');
  }

  void _validate_assignableExpression_arguments_normal_chain_typeArguments(
      String code,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    PropertyAccess propertyAccess1 = parseExpression(code, codes: errorCodes);
    expect(propertyAccess1.propertyName.name, "f");
    //
    // a<E>(b)<F>(c).d<G>(e)
    //
    MethodInvocation invocation2 = propertyAccess1.target;
    expect(invocation2.methodName.name, "d");
    expect(invocation2.typeArguments, isNotNull);
    ArgumentList argumentList2 = invocation2.argumentList;
    expect(argumentList2, isNotNull);
    expect(argumentList2.arguments, hasLength(1));
    //
    // a<E>(b)<F>(c)
    //
    FunctionExpressionInvocation invocation3 = invocation2.target;
    expect(invocation3.typeArguments, isNotNull);
    ArgumentList argumentList3 = invocation3.argumentList;
    expect(argumentList3, isNotNull);
    expect(argumentList3.arguments, hasLength(1));
    //
    // a(b)
    //
    MethodInvocation invocation4 = invocation3.function;
    expect(invocation4.methodName.name, "a");
    expect(invocation4.typeArguments, isNotNull);
    ArgumentList argumentList4 = invocation4.argumentList;
    expect(argumentList4, isNotNull);
    expect(argumentList4.arguments, hasLength(1));
  }
}
