// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.parser_test;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ComplexParserTest);
    defineReflectiveTests(ErrorParserTest);
    defineReflectiveTests(NonErrorParserTest);
    defineReflectiveTests(RecoveryParserTest);
    defineReflectiveTests(SimpleParserTest);
  });
}

/**
 * Instances of the class `AstValidator` are used to validate the correct construction of an
 * AST structure.
 */
class AstValidator extends UnifyingAstVisitor<Object> {
  /**
   * A list containing the errors found while traversing the AST structure.
   */
  List<String> _errors = new List<String>();

  /**
   * Assert that no errors were found while traversing any of the AST structures that have been
   * visited.
   */
  void assertValid() {
    if (!_errors.isEmpty) {
      StringBuffer buffer = new StringBuffer();
      buffer.write("Invalid AST structure:");
      for (String message in _errors) {
        buffer.write("\r\n   ");
        buffer.write(message);
      }
      fail(buffer.toString());
    }
  }

  @override
  Object visitNode(AstNode node) {
    _validate(node);
    return super.visitNode(node);
  }

  /**
   * Validate that the given AST node is correctly constructed.
   *
   * @param node the AST node being validated
   */
  void _validate(AstNode node) {
    AstNode parent = node.parent;
    if (node is CompilationUnit) {
      if (parent != null) {
        _errors.add("Compilation units should not have a parent");
      }
    } else {
      if (parent == null) {
        _errors.add("No parent for ${node.runtimeType}");
      }
    }
    if (node.beginToken == null) {
      _errors.add("No begin token for ${node.runtimeType}");
    }
    if (node.endToken == null) {
      _errors.add("No end token for ${node.runtimeType}");
    }
    int nodeStart = node.offset;
    int nodeLength = node.length;
    if (nodeStart < 0 || nodeLength < 0) {
      _errors.add("No source info for ${node.runtimeType}");
    }
    if (parent != null) {
      int nodeEnd = nodeStart + nodeLength;
      int parentStart = parent.offset;
      int parentEnd = parentStart + parent.length;
      if (nodeStart < parentStart) {
        _errors.add(
            "Invalid source start ($nodeStart) for ${node.runtimeType} inside ${parent.runtimeType} ($parentStart)");
      }
      if (nodeEnd > parentEnd) {
        _errors.add(
            "Invalid source end ($nodeEnd) for ${node.runtimeType} inside ${parent.runtimeType} ($parentStart)");
      }
    }
  }
}

/**
 * The class `ComplexParserTest` defines parser tests that test the parsing of more complex
 * code fragments or the interactions between multiple parsing methods. For example, tests to ensure
 * that the precedence of operations is being handled correctly should be defined in this class.
 *
 * Simpler tests should be defined in the class [SimpleParserTest].
 */
@reflectiveTest
class ComplexParserTest extends ParserTestCase {
  void test_additiveExpression_normal() {
    BinaryExpression expression = parseExpression("x + y - z");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_additiveExpression_noSpaces() {
    BinaryExpression expression = parseExpression("i+1");
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.leftOperand);
    EngineTestCase.assertInstanceOf((obj) => obj is IntegerLiteral,
        IntegerLiteral, expression.rightOperand);
  }

  void test_additiveExpression_precedence_multiplicative_left() {
    BinaryExpression expression = parseExpression("x * y + z");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_additiveExpression_precedence_multiplicative_left_withSuper() {
    BinaryExpression expression = parseExpression("super * y - z");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_additiveExpression_precedence_multiplicative_right() {
    BinaryExpression expression = parseExpression("x + y * z");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.rightOperand);
  }

  void test_additiveExpression_super() {
    BinaryExpression expression = parseExpression("super + y - z");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_assignableExpression_arguments_normal_chain() {
    PropertyAccess propertyAccess1 = parseExpression("a(b)(c).d(e).f");
    expect(propertyAccess1.propertyName.name, "f");
    //
    // a(b)(c).d(e)
    //
    MethodInvocation invocation2 = EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodInvocation,
        MethodInvocation,
        propertyAccess1.target);
    expect(invocation2.methodName.name, "d");
    expect(invocation2.typeArguments, isNull);
    ArgumentList argumentList2 = invocation2.argumentList;
    expect(argumentList2, isNotNull);
    expect(argumentList2.arguments, hasLength(1));
    //
    // a(b)(c)
    //
    FunctionExpressionInvocation invocation3 = EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionExpressionInvocation,
        FunctionExpressionInvocation,
        invocation2.target);
    expect(invocation3.typeArguments, isNull);
    ArgumentList argumentList3 = invocation3.argumentList;
    expect(argumentList3, isNotNull);
    expect(argumentList3.arguments, hasLength(1));
    //
    // a(b)
    //
    MethodInvocation invocation4 = EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodInvocation,
        MethodInvocation,
        invocation3.function);
    expect(invocation4.methodName.name, "a");
    expect(invocation4.typeArguments, isNull);
    ArgumentList argumentList4 = invocation4.argumentList;
    expect(argumentList4, isNotNull);
    expect(argumentList4.arguments, hasLength(1));
  }

  void test_assignableExpression_arguments_normal_chain_typeArgumentComments() {
    enableGenericMethodComments = true;
    _validate_assignableExpression_arguments_normal_chain_typeArguments(
        "a/*<E>*/(b)/*<F>*/(c).d/*<G>*/(e).f");
  }

  void test_assignableExpression_arguments_normal_chain_typeArguments() {
    _validate_assignableExpression_arguments_normal_chain_typeArguments(
        "a<E>(b)<F>(c).d<G>(e).f");
  }

  void test_assignmentExpression_compound() {
    AssignmentExpression expression = parseExpression("x = y = 0");
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.leftHandSide);
    EngineTestCase.assertInstanceOf((obj) => obj is AssignmentExpression,
        AssignmentExpression, expression.rightHandSide);
  }

  void test_assignmentExpression_indexExpression() {
    AssignmentExpression expression = parseExpression("x[1] = 0");
    EngineTestCase.assertInstanceOf((obj) => obj is IndexExpression,
        IndexExpression, expression.leftHandSide);
    EngineTestCase.assertInstanceOf((obj) => obj is IntegerLiteral,
        IntegerLiteral, expression.rightHandSide);
  }

  void test_assignmentExpression_prefixedIdentifier() {
    AssignmentExpression expression = parseExpression("x.y = 0");
    EngineTestCase.assertInstanceOf((obj) => obj is PrefixedIdentifier,
        PrefixedIdentifier, expression.leftHandSide);
    EngineTestCase.assertInstanceOf((obj) => obj is IntegerLiteral,
        IntegerLiteral, expression.rightHandSide);
  }

  void test_assignmentExpression_propertyAccess() {
    AssignmentExpression expression = parseExpression("super.y = 0");
    EngineTestCase.assertInstanceOf((obj) => obj is PropertyAccess,
        PropertyAccess, expression.leftHandSide);
    EngineTestCase.assertInstanceOf((obj) => obj is IntegerLiteral,
        IntegerLiteral, expression.rightHandSide);
  }

  void test_bitwiseAndExpression_normal() {
    BinaryExpression expression = parseExpression("x & y & z");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseAndExpression_precedence_equality_left() {
    BinaryExpression expression = parseExpression("x == y && z");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseAndExpression_precedence_equality_right() {
    BinaryExpression expression = parseExpression("x && y == z");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.rightOperand);
  }

  void test_bitwiseAndExpression_super() {
    BinaryExpression expression = parseExpression("super & y & z");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseOrExpression_normal() {
    BinaryExpression expression = parseExpression("x | y | z");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseOrExpression_precedence_xor_left() {
    BinaryExpression expression = parseExpression("x ^ y | z");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseOrExpression_precedence_xor_right() {
    BinaryExpression expression = parseExpression("x | y ^ z");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.rightOperand);
  }

  void test_bitwiseOrExpression_super() {
    BinaryExpression expression = parseExpression("super | y | z");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseXorExpression_normal() {
    BinaryExpression expression = parseExpression("x ^ y ^ z");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseXorExpression_precedence_and_left() {
    BinaryExpression expression = parseExpression("x & y ^ z");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseXorExpression_precedence_and_right() {
    BinaryExpression expression = parseExpression("x ^ y & z");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.rightOperand);
  }

  void test_bitwiseXorExpression_super() {
    BinaryExpression expression = parseExpression("super ^ y ^ z");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_cascade_withAssignment() {
    CascadeExpression cascade =
        parseExpression("new Map()..[3] = 4 ..[0] = 11;");
    Expression target = cascade.target;
    for (Expression section in cascade.cascadeSections) {
      EngineTestCase.assertInstanceOf(
          (obj) => obj is AssignmentExpression, AssignmentExpression, section);
      Expression lhs = (section as AssignmentExpression).leftHandSide;
      EngineTestCase.assertInstanceOf(
          (obj) => obj is IndexExpression, IndexExpression, lhs);
      IndexExpression index = lhs as IndexExpression;
      expect(index.isCascaded, isTrue);
      expect(index.realTarget, same(target));
    }
  }

  void test_conditionalExpression_precedence_ifNullExpression() {
    ConditionalExpression expression = parseExpression('a ?? b ? y : z');
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.condition);
  }

  void test_conditionalExpression_precedence_logicalOrExpression() {
    ConditionalExpression expression = parseExpression("a | b ? y : z");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.condition);
  }

  void test_conditionalExpression_precedence_nullableType_as() {
    enableNnbd = true;
    Expression expression = parseExpression('x as String ? (x + y) : z');
    expect(expression, isNotNull);
    expect(expression, new isInstanceOf<ConditionalExpression>());
    ConditionalExpression conditional = expression;
    Expression condition = conditional.condition;
    expect(condition, new isInstanceOf<AsExpression>());
    Expression thenExpression = conditional.thenExpression;
    expect(thenExpression, new isInstanceOf<ParenthesizedExpression>());
    Expression elseExpression = conditional.elseExpression;
    expect(elseExpression, new isInstanceOf<SimpleIdentifier>());
  }

  void test_conditionalExpression_precedence_nullableType_is() {
    enableNnbd = true;
    Expression expression = parseExpression('x is String ? (x + y) : z');
    expect(expression, isNotNull);
    expect(expression, new isInstanceOf<ConditionalExpression>());
    ConditionalExpression conditional = expression;
    Expression condition = conditional.condition;
    expect(condition, new isInstanceOf<IsExpression>());
    Expression thenExpression = conditional.thenExpression;
    expect(thenExpression, new isInstanceOf<ParenthesizedExpression>());
    Expression elseExpression = conditional.elseExpression;
    expect(elseExpression, new isInstanceOf<SimpleIdentifier>());
  }

  void test_constructor_initializer_withParenthesizedExpression() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(r'''
class C {
  C() :
    this.a = (b == null ? c : d) {
  }
}''');
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
  }

  void test_equalityExpression_normal() {
    BinaryExpression expression = parseExpression(
        "x == y != z", [ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_equalityExpression_precedence_relational_left() {
    BinaryExpression expression = parseExpression("x is y == z");
    EngineTestCase.assertInstanceOf(
        (obj) => obj is IsExpression, IsExpression, expression.leftOperand);
  }

  void test_equalityExpression_precedence_relational_right() {
    BinaryExpression expression = parseExpression("x == y is z");
    EngineTestCase.assertInstanceOf(
        (obj) => obj is IsExpression, IsExpression, expression.rightOperand);
  }

  void test_equalityExpression_super() {
    BinaryExpression expression = parseExpression("super == y != z",
        [ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_ifNullExpression() {
    BinaryExpression expression = parseExpression('x ?? y ?? z');
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_ifNullExpression_precedence_logicalOr_left() {
    BinaryExpression expression = parseExpression('x || y ?? z');
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_ifNullExpression_precedence_logicalOr_right() {
    BinaryExpression expression = parseExpression('x ?? y || z');
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.rightOperand);
  }

  void test_logicalAndExpression() {
    BinaryExpression expression = parseExpression("x && y && z");
    expect(expression.leftOperand, new isInstanceOf<BinaryExpression>());
  }

  void test_logicalAndExpression_precedence_bitwiseOr_left() {
    BinaryExpression expression = parseExpression("x | y < z");
    expect(expression.leftOperand, new isInstanceOf<BinaryExpression>());
  }

  void test_logicalAndExpression_precedence_bitwiseOr_right() {
    BinaryExpression expression = parseExpression("x < y | z");
    expect(expression.rightOperand, new isInstanceOf<BinaryExpression>());
  }

  void test_logicalAndExpression_precedence_nullableType() {
    enableNnbd = true;
    BinaryExpression expression = parseExpression("x is C? && y is D");
    expect(expression.leftOperand, new isInstanceOf<IsExpression>());
    expect(expression.rightOperand, new isInstanceOf<IsExpression>());
  }

  void test_logicalOrExpression() {
    BinaryExpression expression = parseExpression("x || y || z");
    expect(expression.leftOperand, new isInstanceOf<BinaryExpression>());
  }

  void test_logicalOrExpression_precedence_logicalAnd_left() {
    BinaryExpression expression = parseExpression("x && y || z");
    expect(expression.leftOperand, new isInstanceOf<BinaryExpression>());
  }

  void test_logicalOrExpression_precedence_logicalAnd_right() {
    BinaryExpression expression = parseExpression("x || y && z");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.rightOperand);
  }

  void test_logicalOrExpression_precedence_nullableType() {
    enableNnbd = true;
    BinaryExpression expression = parseExpression("a is X? || (b ? c : d)");
    expect(expression.leftOperand, new isInstanceOf<IsExpression>());
    expect(
        expression.rightOperand, new isInstanceOf<ParenthesizedExpression>());
    expect((expression.rightOperand as ParenthesizedExpression).expression,
        new isInstanceOf<ConditionalExpression>());
  }

  void test_multipleLabels_statement() {
    LabeledStatement statement =
        ParserTestCase.parseStatement("a: b: c: return x;");
    expect(statement.labels, hasLength(3));
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ReturnStatement, ReturnStatement, statement.statement);
  }

  void test_multiplicativeExpression_normal() {
    BinaryExpression expression = parseExpression("x * y / z");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_multiplicativeExpression_precedence_unary_left() {
    BinaryExpression expression = parseExpression("-x * y");
    EngineTestCase.assertInstanceOf((obj) => obj is PrefixExpression,
        PrefixExpression, expression.leftOperand);
  }

  void test_multiplicativeExpression_precedence_unary_right() {
    BinaryExpression expression = parseExpression("x * -y");
    EngineTestCase.assertInstanceOf((obj) => obj is PrefixExpression,
        PrefixExpression, expression.rightOperand);
  }

  void test_multiplicativeExpression_super() {
    BinaryExpression expression = parseExpression("super * y / z");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_relationalExpression_precedence_shift_right() {
    IsExpression expression = parseExpression("x << y is z");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.expression);
  }

  void test_shiftExpression_normal() {
    BinaryExpression expression = parseExpression("x >> 4 << 3");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_shiftExpression_precedence_additive_left() {
    BinaryExpression expression = parseExpression("x + y << z");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_shiftExpression_precedence_additive_right() {
    BinaryExpression expression = parseExpression("x << y + z");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.rightOperand);
  }

  void test_shiftExpression_super() {
    BinaryExpression expression = parseExpression("super >> 4 << 3");
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_topLevelFunction_nestedGenericFunction() {
    parseCompilationUnitWithOptions('''
void f() {
  void g<T>() {
  }
}
''');
  }

  void _validate_assignableExpression_arguments_normal_chain_typeArguments(
      String code) {
    PropertyAccess propertyAccess1 = parseExpression(code);
    expect(propertyAccess1.propertyName.name, "f");
    //
    // a<E>(b)<F>(c).d<G>(e)
    //
    MethodInvocation invocation2 = EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodInvocation,
        MethodInvocation,
        propertyAccess1.target);
    expect(invocation2.methodName.name, "d");
    expect(invocation2.typeArguments, isNotNull);
    ArgumentList argumentList2 = invocation2.argumentList;
    expect(argumentList2, isNotNull);
    expect(argumentList2.arguments, hasLength(1));
    //
    // a<E>(b)<F>(c)
    //
    FunctionExpressionInvocation invocation3 = EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionExpressionInvocation,
        FunctionExpressionInvocation,
        invocation2.target);
    expect(invocation3.typeArguments, isNotNull);
    ArgumentList argumentList3 = invocation3.argumentList;
    expect(argumentList3, isNotNull);
    expect(argumentList3.arguments, hasLength(1));
    //
    // a(b)
    //
    MethodInvocation invocation4 = EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodInvocation,
        MethodInvocation,
        invocation3.function);
    expect(invocation4.methodName.name, "a");
    expect(invocation4.typeArguments, isNotNull);
    ArgumentList argumentList4 = invocation4.argumentList;
    expect(argumentList4, isNotNull);
    expect(argumentList4.arguments, hasLength(1));
  }
}

/**
 * The class `ErrorParserTest` defines parser tests that test the parsing of code to ensure
 * that errors are correctly reported, and in some cases, not reported.
 */
@reflectiveTest
class ErrorParserTest extends ParserTestCase {
  void test_abstractClassMember_constructor() {
    createParser('abstract C.c();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.ABSTRACT_CLASS_MEMBER]);
  }

  void test_abstractClassMember_field() {
    createParser('abstract C f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.ABSTRACT_CLASS_MEMBER]);
  }

  void test_abstractClassMember_getter() {
    createParser('abstract get m;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.ABSTRACT_CLASS_MEMBER]);
  }

  void test_abstractClassMember_method() {
    createParser('abstract m();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.ABSTRACT_CLASS_MEMBER]);
  }

  void test_abstractClassMember_setter() {
    createParser('abstract set m(v);');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.ABSTRACT_CLASS_MEMBER]);
  }

  void test_abstractEnum() {
    ParserTestCase.parseCompilationUnit(
        "abstract enum E {ONE}", [ParserErrorCode.ABSTRACT_ENUM]);
  }

  void test_abstractTopLevelFunction_function() {
    ParserTestCase.parseCompilationUnit(
        "abstract f(v) {}", [ParserErrorCode.ABSTRACT_TOP_LEVEL_FUNCTION]);
  }

  void test_abstractTopLevelFunction_getter() {
    ParserTestCase.parseCompilationUnit(
        "abstract get m {}", [ParserErrorCode.ABSTRACT_TOP_LEVEL_FUNCTION]);
  }

  void test_abstractTopLevelFunction_setter() {
    ParserTestCase.parseCompilationUnit(
        "abstract set m(v) {}", [ParserErrorCode.ABSTRACT_TOP_LEVEL_FUNCTION]);
  }

  void test_abstractTopLevelVariable() {
    ParserTestCase.parseCompilationUnit(
        "abstract C f;", [ParserErrorCode.ABSTRACT_TOP_LEVEL_VARIABLE]);
  }

  void test_abstractTypeDef() {
    ParserTestCase.parseCompilationUnit(
        "abstract typedef F();", [ParserErrorCode.ABSTRACT_TYPEDEF]);
  }

  void test_annotationOnEnumConstant_first() {
    ParserTestCase.parseCompilationUnit("enum E { @override C }",
        [ParserErrorCode.ANNOTATION_ON_ENUM_CONSTANT]);
  }

  void test_annotationOnEnumConstant_middle() {
    ParserTestCase.parseCompilationUnit("enum E { C, @override D, E }",
        [ParserErrorCode.ANNOTATION_ON_ENUM_CONSTANT]);
  }

  void test_breakOutsideOfLoop_breakInDoStatement() {
    createParser('do {break;} while (x);');
    DoStatement statement = parser.parseDoStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
  }

  void test_breakOutsideOfLoop_breakInForStatement() {
    createParser('for (; x;) {break;}');
    Statement statement = parser.parseForStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
  }

  void test_breakOutsideOfLoop_breakInIfStatement() {
    createParser('if (x) {break;}');
    IfStatement statement = parser.parseIfStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertErrorsWithCodes([ParserErrorCode.BREAK_OUTSIDE_OF_LOOP]);
  }

  void test_breakOutsideOfLoop_breakInSwitchStatement() {
    createParser('switch (x) {case 1: break;}');
    SwitchStatement statement = parser.parseSwitchStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
  }

  void test_breakOutsideOfLoop_breakInWhileStatement() {
    createParser('while (x) {break;}');
    WhileStatement statement = parser.parseWhileStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
  }

  void test_breakOutsideOfLoop_functionExpression_inALoop() {
    ParserTestCase.parseStatement(
        "for(; x;) {() {break;};}", [ParserErrorCode.BREAK_OUTSIDE_OF_LOOP]);
  }

  void test_breakOutsideOfLoop_functionExpression_withALoop() {
    ParserTestCase.parseStatement("() {for (; x;) {break;}};");
  }

  void test_classInClass_abstract() {
    ParserTestCase.parseCompilationUnit(
        "class C { abstract class B {} }", [ParserErrorCode.CLASS_IN_CLASS]);
  }

  void test_classInClass_nonAbstract() {
    ParserTestCase.parseCompilationUnit(
        "class C { class B {} }", [ParserErrorCode.CLASS_IN_CLASS]);
  }

  void test_classTypeAlias_abstractAfterEq() {
    // This syntax has been removed from the language in favor of
    // "abstract class A = B with C;" (issue 18098).
    createParser('class A = abstract B with C;');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.EXPECTED_TOKEN, ParserErrorCode.EXPECTED_TOKEN]);
  }

  void test_colonInPlaceOfIn() {
    ParserTestCase.parseStatement(
        "for (var x : list) {}", [ParserErrorCode.COLON_IN_PLACE_OF_IN]);
  }

  void test_constAndFinal() {
    createParser('const final int x;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.CONST_AND_FINAL]);
  }

  void test_constAndVar() {
    createParser('const var x;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.CONST_AND_VAR]);
  }

  void test_constClass() {
    ParserTestCase.parseCompilationUnit(
        "const class C {}", [ParserErrorCode.CONST_CLASS]);
  }

  void test_constConstructorWithBody() {
    createParser('const C() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener
        .assertErrorsWithCodes([ParserErrorCode.CONST_CONSTRUCTOR_WITH_BODY]);
  }

  void test_constEnum() {
    ParserTestCase.parseCompilationUnit(
        "const enum E {ONE}", [ParserErrorCode.CONST_ENUM]);
  }

  void test_constFactory() {
    createParser('const factory C() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.CONST_FACTORY]);
  }

  void test_constMethod() {
    createParser('const int m() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.CONST_METHOD]);
  }

  void test_constructorWithReturnType() {
    createParser('C C() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener
        .assertErrorsWithCodes([ParserErrorCode.CONSTRUCTOR_WITH_RETURN_TYPE]);
  }

  void test_constructorWithReturnType_var() {
    createParser('var C() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener
        .assertErrorsWithCodes([ParserErrorCode.CONSTRUCTOR_WITH_RETURN_TYPE]);
  }

  void test_constTypedef() {
    ParserTestCase.parseCompilationUnit(
        "const typedef F();", [ParserErrorCode.CONST_TYPEDEF]);
  }

  void test_continueOutsideOfLoop_continueInDoStatement() {
    createParser('do {continue;} while (x);');
    DoStatement statement = parser.parseDoStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
  }

  void test_continueOutsideOfLoop_continueInForStatement() {
    createParser('for (; x;) {continue;}');
    Statement statement = parser.parseForStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
  }

  void test_continueOutsideOfLoop_continueInIfStatement() {
    createParser('if (x) {continue;}');
    IfStatement statement = parser.parseIfStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertErrorsWithCodes([ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP]);
  }

  void test_continueOutsideOfLoop_continueInSwitchStatement() {
    createParser('switch (x) {case 1: continue a;}');
    SwitchStatement statement = parser.parseSwitchStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
  }

  void test_continueOutsideOfLoop_continueInWhileStatement() {
    createParser('while (x) {continue;}');
    WhileStatement statement = parser.parseWhileStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
  }

  void test_continueOutsideOfLoop_functionExpression_inALoop() {
    ParserTestCase.parseStatement("for(; x;) {() {continue;};}",
        [ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP]);
  }

  void test_continueOutsideOfLoop_functionExpression_withALoop() {
    ParserTestCase.parseStatement("() {for (; x;) {continue;}};");
  }

  void test_continueWithoutLabelInCase_error() {
    createParser('switch (x) {case 1: continue;}');
    SwitchStatement statement = parser.parseSwitchStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.CONTINUE_WITHOUT_LABEL_IN_CASE]);
  }

  void test_continueWithoutLabelInCase_noError() {
    createParser('switch (x) {case 1: continue a;}');
    SwitchStatement statement = parser.parseSwitchStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
  }

  void test_continueWithoutLabelInCase_noError_switchInLoop() {
    createParser('while (a) { switch (b) {default: continue;}}');
    WhileStatement statement = parser.parseWhileStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
  }

  void test_deprecatedClassTypeAlias() {
    ParserTestCase.parseCompilationUnit(
        "typedef C = S with M;", [ParserErrorCode.DEPRECATED_CLASS_TYPE_ALIAS]);
  }

  void test_deprecatedClassTypeAlias_withGeneric() {
    ParserTestCase.parseCompilationUnit("typedef C<T> = S<T> with M;",
        [ParserErrorCode.DEPRECATED_CLASS_TYPE_ALIAS]);
  }

  void test_directiveAfterDeclaration_classBeforeDirective() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(
        "class Foo{} library l;",
        [ParserErrorCode.DIRECTIVE_AFTER_DECLARATION]);
    expect(unit, isNotNull);
  }

  void test_directiveAfterDeclaration_classBetweenDirectives() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(
        "library l;\nclass Foo{}\npart 'a.dart';",
        [ParserErrorCode.DIRECTIVE_AFTER_DECLARATION]);
    expect(unit, isNotNull);
  }

  void test_duplicatedModifier_const() {
    createParser('const const m;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.DUPLICATED_MODIFIER]);
  }

  void test_duplicatedModifier_external() {
    createParser('external external f();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.DUPLICATED_MODIFIER]);
  }

  void test_duplicatedModifier_factory() {
    createParser('factory factory C() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.DUPLICATED_MODIFIER]);
  }

  void test_duplicatedModifier_final() {
    createParser('final final m;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.DUPLICATED_MODIFIER]);
  }

  void test_duplicatedModifier_static() {
    createParser('static static var m;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.DUPLICATED_MODIFIER]);
  }

  void test_duplicatedModifier_var() {
    createParser('var var m;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.DUPLICATED_MODIFIER]);
  }

  void test_duplicateLabelInSwitchStatement() {
    createParser('switch (e) {l1: case 0: break; l1: case 1: break;}');
    SwitchStatement statement = parser.parseSwitchStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.DUPLICATE_LABEL_IN_SWITCH_STATEMENT]);
  }

  void test_emptyEnumBody() {
    createParser('enum E {}');
    EnumDeclaration declaration =
        parser.parseEnumDeclaration(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(declaration);
    listener.assertErrorsWithCodes([ParserErrorCode.EMPTY_ENUM_BODY]);
  }

  void test_enumInClass() {
    ParserTestCase.parseCompilationUnit(
        r'''
class Foo {
  enum Bar {
    Bar1, Bar2, Bar3
  }
}
''',
        [ParserErrorCode.ENUM_IN_CLASS]);
  }

  void test_equalityCannotBeEqualityOperand_eq_eq() {
    parseExpression(
        "1 == 2 == 3", [ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND]);
  }

  void test_equalityCannotBeEqualityOperand_eq_neq() {
    parseExpression(
        "1 == 2 != 3", [ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND]);
  }

  void test_equalityCannotBeEqualityOperand_neq_eq() {
    parseExpression(
        "1 != 2 == 3", [ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND]);
  }

  void test_expectedCaseOrDefault() {
    createParser('switch (e) {break;}');
    SwitchStatement statement = parser.parseSwitchStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertErrorsWithCodes([ParserErrorCode.EXPECTED_CASE_OR_DEFAULT]);
  }

  void test_expectedClassMember_inClass_afterType() {
    createParser('heart 2 heart');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.EXPECTED_CLASS_MEMBER]);
  }

  void test_expectedClassMember_inClass_beforeType() {
    createParser('4 score');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.EXPECTED_CLASS_MEMBER]);
  }

  void test_expectedExecutable_inClass_afterVoid() {
    createParser('void 2 void');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.EXPECTED_EXECUTABLE]);
  }

  void test_expectedExecutable_topLevel_afterType() {
    createParser('heart 2 heart');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.EXPECTED_EXECUTABLE]);
  }

  void test_expectedExecutable_topLevel_afterVoid() {
    createParser('void 2 void');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.EXPECTED_EXECUTABLE]);
  }

  void test_expectedExecutable_topLevel_beforeType() {
    createParser('4 score');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.EXPECTED_EXECUTABLE]);
  }

  void test_expectedExecutable_topLevel_eof() {
    createParser('x');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertErrors(
        [new AnalysisError(null, 0, 1, ParserErrorCode.EXPECTED_EXECUTABLE)]);
  }

  void test_expectedInterpolationIdentifier() {
    createParser("'\$x\$'");
    StringLiteral literal = parser.parseStringLiteral();
    expectNotNullIfNoErrors(literal);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_IDENTIFIER]);
  }

  void test_expectedInterpolationIdentifier_emptyString() {
    // The scanner inserts an empty string token between the two $'s; we need to
    // make sure that the MISSING_IDENTIFIER error that is generated has a
    // nonzero width so that it will show up in the editor UI.
    createParser("'\$\$foo'");
    StringLiteral literal = parser.parseStringLiteral();
    expectNotNullIfNoErrors(literal);
    listener.assertErrors(
        [new AnalysisError(null, 2, 1, ParserErrorCode.MISSING_IDENTIFIER)]);
  }

  @failingTest
  void test_expectedListOrMapLiteral() {
    // It isn't clear that this test can ever pass. The parser is currently
    // create a synthetic list literal in this case, but isSynthetic() isn't
    // overridden for ListLiteral. The problem is that the synthetic list
    // literals that are being created are not always zero length (because they
    // could have type parameters), which violates the contract of
    // isSynthetic().
    createParser('1');
    TypedLiteral literal = parser.parseListOrMapLiteral(null);
    expectNotNullIfNoErrors(literal);
    listener
        .assertErrorsWithCodes([ParserErrorCode.EXPECTED_LIST_OR_MAP_LITERAL]);
    expect(literal.isSynthetic, isTrue);
  }

  void test_expectedStringLiteral() {
    createParser('1');
    StringLiteral literal = parser.parseStringLiteral();
    expectNotNullIfNoErrors(literal);
    listener.assertErrorsWithCodes([ParserErrorCode.EXPECTED_STRING_LITERAL]);
    expect(literal.isSynthetic, isTrue);
  }

  void test_expectedToken_commaMissingInArgumentList() {
    createParser('(x, y z)');
    ArgumentList list = parser.parseArgumentList();
    expectNotNullIfNoErrors(list);
    listener.assertErrorsWithCodes([ParserErrorCode.EXPECTED_TOKEN]);
  }

  void test_expectedToken_parseStatement_afterVoid() {
    ParserTestCase.parseStatement("void}",
        [ParserErrorCode.EXPECTED_TOKEN, ParserErrorCode.MISSING_IDENTIFIER]);
  }

  void test_expectedToken_semicolonAfterClass() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.CLASS);
    createParser('A = B with C');
    ClassTypeAlias declaration =
        parser.parseClassTypeAlias(emptyCommentAndMetadata(), null, token);
    expectNotNullIfNoErrors(declaration);
    listener.assertErrorsWithCodes([ParserErrorCode.EXPECTED_TOKEN]);
  }

  void test_expectedToken_semicolonMissingAfterExport() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(
        "export '' class A {}", [ParserErrorCode.EXPECTED_TOKEN]);
    ExportDirective directive = unit.directives[0] as ExportDirective;
    Token semicolon = directive.semicolon;
    expect(semicolon, isNotNull);
    expect(semicolon.isSynthetic, isTrue);
  }

  void test_expectedToken_semicolonMissingAfterExpression() {
    ParserTestCase.parseStatement("x", [ParserErrorCode.EXPECTED_TOKEN]);
  }

  void test_expectedToken_semicolonMissingAfterImport() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(
        "import '' class A {}", [ParserErrorCode.EXPECTED_TOKEN]);
    ImportDirective directive = unit.directives[0] as ImportDirective;
    Token semicolon = directive.semicolon;
    expect(semicolon, isNotNull);
    expect(semicolon.isSynthetic, isTrue);
  }

  void test_expectedToken_whileMissingInDoStatement() {
    ParserTestCase
        .parseStatement("do {} (x);", [ParserErrorCode.EXPECTED_TOKEN]);
  }

  void test_expectedTypeName_is() {
    parseExpression("x is", [ParserErrorCode.EXPECTED_TYPE_NAME]);
  }

  void test_exportDirectiveAfterPartDirective() {
    ParserTestCase.parseCompilationUnit("part 'a.dart'; export 'b.dart';",
        [ParserErrorCode.EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE]);
  }

  void test_externalAfterConst() {
    createParser('const external C();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.EXTERNAL_AFTER_CONST]);
  }

  void test_externalAfterFactory() {
    createParser('factory external C();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.EXTERNAL_AFTER_FACTORY]);
  }

  void test_externalAfterStatic() {
    createParser('static external int m();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.EXTERNAL_AFTER_STATIC]);
  }

  void test_externalClass() {
    ParserTestCase.parseCompilationUnit(
        "external class C {}", [ParserErrorCode.EXTERNAL_CLASS]);
  }

  void test_externalConstructorWithBody_factory() {
    createParser('external factory C() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.EXTERNAL_CONSTRUCTOR_WITH_BODY]);
  }

  void test_externalConstructorWithBody_named() {
    createParser('external C.c() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.EXTERNAL_CONSTRUCTOR_WITH_BODY]);
  }

  void test_externalEnum() {
    ParserTestCase.parseCompilationUnit(
        "external enum E {ONE}", [ParserErrorCode.EXTERNAL_ENUM]);
  }

  void test_externalField_const() {
    createParser('external const A f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.EXTERNAL_FIELD]);
  }

  void test_externalField_final() {
    createParser('external final A f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.EXTERNAL_FIELD]);
  }

  void test_externalField_static() {
    createParser('external static A f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.EXTERNAL_FIELD]);
  }

  void test_externalField_typed() {
    createParser('external A f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.EXTERNAL_FIELD]);
  }

  void test_externalField_untyped() {
    createParser('external var f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.EXTERNAL_FIELD]);
  }

  void test_externalGetterWithBody() {
    createParser('external int get x {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.EXTERNAL_GETTER_WITH_BODY]);
  }

  void test_externalMethodWithBody() {
    createParser('external m() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.EXTERNAL_METHOD_WITH_BODY]);
  }

  void test_externalOperatorWithBody() {
    createParser('external operator +(int value) {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener
        .assertErrorsWithCodes([ParserErrorCode.EXTERNAL_OPERATOR_WITH_BODY]);
  }

  void test_externalSetterWithBody() {
    createParser('external set x(int value) {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.EXTERNAL_SETTER_WITH_BODY]);
  }

  void test_externalTypedef() {
    ParserTestCase.parseCompilationUnit(
        "external typedef F();", [ParserErrorCode.EXTERNAL_TYPEDEF]);
  }

  void test_extraCommaInParameterList() {
    createParser('(int a, , int b)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN]);
  }

  void test_extraCommaTrailingNamedParameterGroup() {
    createParser('({int b},)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrorsWithCodes([
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.NORMAL_BEFORE_OPTIONAL_PARAMETERS
    ]);
  }

  void test_extraCommaTrailingPositionalParameterGroup() {
    createParser('([int b],)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrorsWithCodes([
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.NORMAL_BEFORE_OPTIONAL_PARAMETERS
    ]);
  }

  void test_extraTrailingCommaInParameterList() {
    createParser('(a,,)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_IDENTIFIER]);
  }

  void test_factoryTopLevelDeclaration_class() {
    ParserTestCase.parseCompilationUnit(
        "factory class C {}", [ParserErrorCode.FACTORY_TOP_LEVEL_DECLARATION]);
  }

  void test_factoryTopLevelDeclaration_typedef() {
    ParserTestCase.parseCompilationUnit("factory typedef F();",
        [ParserErrorCode.FACTORY_TOP_LEVEL_DECLARATION]);
  }

  void test_factoryWithInitializers() {
    createParser('factory C() : x = 3 {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.FACTORY_WITH_INITIALIZERS]);
  }

  void test_factoryWithoutBody() {
    createParser('factory C();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.FACTORY_WITHOUT_BODY]);
  }

  void test_fieldInitializerOutsideConstructor() {
    createParser('void m(this.x);');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR]);
  }

  void test_finalAndVar() {
    createParser('final var x;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.FINAL_AND_VAR]);
  }

  void test_finalClass() {
    ParserTestCase.parseCompilationUnit(
        "final class C {}", [ParserErrorCode.FINAL_CLASS]);
  }

  void test_finalConstructor() {
    createParser('final C() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.FINAL_CONSTRUCTOR]);
  }

  void test_finalEnum() {
    ParserTestCase.parseCompilationUnit(
        "final enum E {ONE}", [ParserErrorCode.FINAL_ENUM]);
  }

  void test_finalMethod() {
    createParser('final int m() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.FINAL_METHOD]);
  }

  void test_finalTypedef() {
    ParserTestCase.parseCompilationUnit(
        "final typedef F();", [ParserErrorCode.FINAL_TYPEDEF]);
  }

  void test_functionTypedParameter_const() {
    ParserTestCase.parseCompilationUnit(
        "void f(const x()) {}", [ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR]);
  }

  void test_functionTypedParameter_final() {
    ParserTestCase.parseCompilationUnit(
        "void f(final x()) {}", [ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR]);
  }

  void test_functionTypedParameter_var() {
    ParserTestCase.parseCompilationUnit(
        "void f(var x()) {}", [ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR]);
  }

  void test_getterInFunction_block_noReturnType() {
    FunctionDeclarationStatement statement = ParserTestCase.parseStatement(
        "get x { return _x; }", [ParserErrorCode.GETTER_IN_FUNCTION]);
    expect(statement.functionDeclaration.functionExpression.parameters, isNull);
  }

  void test_getterInFunction_block_returnType() {
    ParserTestCase.parseStatement(
        "int get x { return _x; }", [ParserErrorCode.GETTER_IN_FUNCTION]);
  }

  void test_getterInFunction_expression_noReturnType() {
    ParserTestCase
        .parseStatement("get x => _x;", [ParserErrorCode.GETTER_IN_FUNCTION]);
  }

  void test_getterInFunction_expression_returnType() {
    ParserTestCase.parseStatement(
        "int get x => _x;", [ParserErrorCode.GETTER_IN_FUNCTION]);
  }

  void test_getterWithParameters() {
    createParser('int get x() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.GETTER_WITH_PARAMETERS]);
  }

  void test_illegalAssignmentToNonAssignable_postfix_minusMinus_literal() {
    parseExpression(
        "0--", [ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE]);
  }

  void test_illegalAssignmentToNonAssignable_postfix_plusPlus_literal() {
    parseExpression(
        "0++", [ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE]);
  }

  void test_illegalAssignmentToNonAssignable_postfix_plusPlus_parenthesized() {
    parseExpression(
        "(x)++", [ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE]);
  }

  void test_illegalAssignmentToNonAssignable_primarySelectorPostfix() {
    parseExpression(
        "x(y)(z)++", [ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE]);
  }

  void test_illegalAssignmentToNonAssignable_superAssigned() {
    // TODO(brianwilkerson) When the test
    // test_illegalAssignmentToNonAssignable_superAssigned_failing starts to pass,
    // remove this test (there should only be one error generated, but we're
    // keeping this test until that time so that we can catch other forms of
    // regressions).
    parseExpression("super = x;", [
      ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR,
      ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE
    ]);
  }

  @failingTest
  void test_illegalAssignmentToNonAssignable_superAssigned_failing() {
    // TODO(brianwilkerson) When this test starts to pass, remove the test
    // test_illegalAssignmentToNonAssignable_superAssigned.
    parseExpression(
        "super = x;", [ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE]);
  }

  void test_implementsBeforeExtends() {
    ParserTestCase.parseCompilationUnit("class A implements B extends C {}",
        [ParserErrorCode.IMPLEMENTS_BEFORE_EXTENDS]);
  }

  void test_implementsBeforeWith() {
    ParserTestCase.parseCompilationUnit(
        "class A extends B implements C with D {}",
        [ParserErrorCode.IMPLEMENTS_BEFORE_WITH]);
  }

  void test_importDirectiveAfterPartDirective() {
    ParserTestCase.parseCompilationUnit("part 'a.dart'; import 'b.dart';",
        [ParserErrorCode.IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE]);
  }

  void test_initializedVariableInForEach() {
    createParser('for (int a = 0 in foo) {}');
    Statement statement = parser.parseForStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.INITIALIZED_VARIABLE_IN_FOR_EACH]);
  }

  void test_invalidAwaitInFor() {
    createParser('await for (; ;) {}');
    Statement statement = parser.parseForStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertErrorsWithCodes([ParserErrorCode.INVALID_AWAIT_IN_FOR]);
  }

  void test_invalidCodePoint() {
    createParser("'\\u{110000}'");
    StringLiteral literal = parser.parseStringLiteral();
    expectNotNullIfNoErrors(literal);
    listener.assertErrorsWithCodes([ParserErrorCode.INVALID_CODE_POINT]);
  }

  @failingTest
  void test_invalidCommentReference__new_nonIdentifier() {
    // This test fails because the method parseCommentReference returns null.
    createParser('');
    CommentReference reference = parser.parseCommentReference('new 42', 0);
    expectNotNullIfNoErrors(reference);
    listener.assertErrorsWithCodes([ParserErrorCode.INVALID_COMMENT_REFERENCE]);
  }

  @failingTest
  void test_invalidCommentReference__new_tooMuch() {
    createParser('');
    CommentReference reference = parser.parseCommentReference('new a.b.c.d', 0);
    expectNotNullIfNoErrors(reference);
    listener.assertErrorsWithCodes([ParserErrorCode.INVALID_COMMENT_REFERENCE]);
  }

  @failingTest
  void test_invalidCommentReference__nonNew_nonIdentifier() {
    // This test fails because the method parseCommentReference returns null.
    createParser('');
    CommentReference reference = parser.parseCommentReference('42', 0);
    expectNotNullIfNoErrors(reference);
    listener.assertErrorsWithCodes([ParserErrorCode.INVALID_COMMENT_REFERENCE]);
  }

  @failingTest
  void test_invalidCommentReference__nonNew_tooMuch() {
    createParser('');
    CommentReference reference = parser.parseCommentReference('a.b.c.d', 0);
    expectNotNullIfNoErrors(reference);
    listener.assertErrorsWithCodes([ParserErrorCode.INVALID_COMMENT_REFERENCE]);
  }

  void test_invalidHexEscape_invalidDigit() {
    createParser("'\\x0 a'");
    StringLiteral literal = parser.parseStringLiteral();
    expectNotNullIfNoErrors(literal);
    listener.assertErrorsWithCodes([ParserErrorCode.INVALID_HEX_ESCAPE]);
  }

  void test_invalidHexEscape_tooFewDigits() {
    createParser("'\\x0'");
    StringLiteral literal = parser.parseStringLiteral();
    expectNotNullIfNoErrors(literal);
    listener.assertErrorsWithCodes([ParserErrorCode.INVALID_HEX_ESCAPE]);
  }

  void test_invalidInterpolationIdentifier_startWithDigit() {
    createParser("'\$1'");
    StringLiteral literal = parser.parseStringLiteral();
    expectNotNullIfNoErrors(literal);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_IDENTIFIER]);
  }

  void test_invalidLiteralInConfiguration() {
    createParser("if (a == 'x \$y z') 'a.dart'");
    Configuration configuration = parser.parseConfiguration();
    expectNotNullIfNoErrors(configuration);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.INVALID_LITERAL_IN_CONFIGURATION]);
  }

  void test_invalidOperator() {
    createParser('void operator ===(x) {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.INVALID_OPERATOR]);
  }

  void test_invalidOperatorAfterSuper_assignableExpression() {
    createParser('super?.v');
    Expression expression = parser.parseAssignableExpression(false);
    expectNotNullIfNoErrors(expression);
    listener
        .assertErrorsWithCodes([ParserErrorCode.INVALID_OPERATOR_FOR_SUPER]);
  }

  void test_invalidOperatorAfterSuper_primaryExpression() {
    createParser('super?.v');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener
        .assertErrorsWithCodes([ParserErrorCode.INVALID_OPERATOR_FOR_SUPER]);
  }

  void test_invalidOperatorForSuper() {
    createParser('++super');
    Expression expression = parser.parseUnaryExpression();
    expectNotNullIfNoErrors(expression);
    listener
        .assertErrorsWithCodes([ParserErrorCode.INVALID_OPERATOR_FOR_SUPER]);
  }

  void test_invalidStarAfterAsync() {
    createParser('async* => 0;');
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    listener.assertErrorsWithCodes([ParserErrorCode.INVALID_STAR_AFTER_ASYNC]);
  }

  void test_invalidSync() {
    createParser('sync* => 0;');
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    listener.assertErrorsWithCodes([ParserErrorCode.INVALID_SYNC]);
  }

  void test_invalidUnicodeEscape_incomplete_noDigits() {
    createParser("'\\u{'");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertErrorsWithCodes([ParserErrorCode.INVALID_UNICODE_ESCAPE]);
  }

  void test_invalidUnicodeEscape_incomplete_someDigits() {
    createParser("'\\u{0A'");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertErrorsWithCodes([ParserErrorCode.INVALID_UNICODE_ESCAPE]);
  }

  void test_invalidUnicodeEscape_invalidDigit() {
    createParser("'\\u0 a'");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertErrorsWithCodes([ParserErrorCode.INVALID_UNICODE_ESCAPE]);
  }

  void test_invalidUnicodeEscape_tooFewDigits_fixed() {
    createParser("'\\u04'");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertErrorsWithCodes([ParserErrorCode.INVALID_UNICODE_ESCAPE]);
  }

  void test_invalidUnicodeEscape_tooFewDigits_variable() {
    createParser("'\\u{}'");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertErrorsWithCodes([ParserErrorCode.INVALID_UNICODE_ESCAPE]);
  }

  void test_invalidUnicodeEscape_tooManyDigits_variable() {
    createParser("'\\u{12345678}'");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertErrorsWithCodes([
      ParserErrorCode.INVALID_UNICODE_ESCAPE,
      ParserErrorCode.INVALID_CODE_POINT
    ]);
  }

  void test_libraryDirectiveNotFirst() {
    ParserTestCase.parseCompilationUnit("import 'x.dart'; library l;",
        [ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST]);
  }

  void test_libraryDirectiveNotFirst_afterPart() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(
        "part 'a.dart';\nlibrary l;",
        [ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST]);
    expect(unit, isNotNull);
  }

  void test_localFunctionDeclarationModifier_abstract() {
    ParserTestCase.parseStatement("abstract f() {}",
        [ParserErrorCode.LOCAL_FUNCTION_DECLARATION_MODIFIER]);
  }

  void test_localFunctionDeclarationModifier_external() {
    ParserTestCase.parseStatement("external f() {}",
        [ParserErrorCode.LOCAL_FUNCTION_DECLARATION_MODIFIER]);
  }

  void test_localFunctionDeclarationModifier_factory() {
    ParserTestCase.parseStatement("factory f() {}",
        [ParserErrorCode.LOCAL_FUNCTION_DECLARATION_MODIFIER]);
  }

  void test_localFunctionDeclarationModifier_static() {
    ParserTestCase.parseStatement(
        "static f() {}", [ParserErrorCode.LOCAL_FUNCTION_DECLARATION_MODIFIER]);
  }

  void test_method_invalidTypeParameterComments() {
    enableGenericMethodComments = true;
    createParser('void m/*<E, hello!>*/() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([
      ParserErrorCode.EXPECTED_TOKEN /*>*/,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.EXPECTED_TOKEN /*(*/,
      ParserErrorCode.EXPECTED_TOKEN /*)*/,
      ParserErrorCode.MISSING_FUNCTION_BODY
    ]);
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.typeParameters.toString(), '<E, hello>',
        reason: 'parser recovers what it can');
  }

  void test_method_invalidTypeParameterExtends() {
    // Regression test for https://github.com/dart-lang/sdk/issues/25739.

    // TODO(jmesserly): ideally we'd be better at parser recovery here.
    createParser('f<E>(E extends num p);');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([
      ParserErrorCode.MISSING_IDENTIFIER, // `extends` is a keyword
      ParserErrorCode.EXPECTED_TOKEN, // comma
      ParserErrorCode.EXPECTED_TOKEN, // close paren
      ParserErrorCode.MISSING_FUNCTION_BODY
    ]);
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.parameters.toString(), '(E, extends)',
        reason: 'parser recovers what it can');
  }

  void test_method_invalidTypeParameterExtendsComment() {
    // Regression test for https://github.com/dart-lang/sdk/issues/25739.

    // TODO(jmesserly): ideally we'd be better at parser recovery here.
    // Also, this behavior is slightly different from how we would parse a
    // normal generic method, because we "discover" the comment at a different
    // point in the parser. This has a slight effect on the AST that results
    // from error recovery.
    enableGenericMethodComments = true;
    createParser('f/*<E>*/(dynamic/*=E extends num*/p);');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([
      ParserErrorCode.MISSING_IDENTIFIER, // `extends` is a keyword
      ParserErrorCode.EXPECTED_TOKEN, // comma
      ParserErrorCode.MISSING_IDENTIFIER, // `extends` is a keyword
      ParserErrorCode.EXPECTED_TOKEN, // close paren
      ParserErrorCode.MISSING_FUNCTION_BODY
    ]);
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.parameters.toString(), '(E extends, extends)',
        reason: 'parser recovers what it can');
  }

  void test_method_invalidTypeParameters() {
    // TODO(jmesserly): ideally we'd be better at parser recovery here.
    // It doesn't try to advance past the invalid token `!` to find the
    // valid `>`. If it did we'd get less cascading errors, at least for this
    // particular example.
    createParser('void m<E, hello!>() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([
      ParserErrorCode.EXPECTED_TOKEN /*>*/,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.EXPECTED_TOKEN /*(*/,
      ParserErrorCode.EXPECTED_TOKEN /*)*/,
      ParserErrorCode.MISSING_FUNCTION_BODY
    ]);
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.typeParameters.toString(), '<E, hello>',
        reason: 'parser recovers what it can');
  }

  void test_missingAssignableSelector_identifiersAssigned() {
    parseExpression("x.y = y;");
  }

  void test_missingAssignableSelector_prefix_minusMinus_literal() {
    parseExpression("--0", [ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR]);
  }

  void test_missingAssignableSelector_prefix_plusPlus_literal() {
    parseExpression("++0", [ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR]);
  }

  void test_missingAssignableSelector_selector() {
    parseExpression("x(y)(z).a++");
  }

  void test_missingAssignableSelector_superPrimaryExpression() {
    createParser('super');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener
        .assertErrorsWithCodes([ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR]);
    expect(expression, new isInstanceOf<SuperExpression>());
    SuperExpression superExpression = expression;
    expect(superExpression.superKeyword, isNotNull);
  }

  void test_missingAssignableSelector_superPropertyAccessAssigned() {
    parseExpression("super.x = x;");
  }

  void test_missingCatchOrFinally() {
    createParser('try {}');
    TryStatement statement = parser.parseTryStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_CATCH_OR_FINALLY]);
    expect(statement, isNotNull);
  }

  void test_missingClassBody() {
    ParserTestCase.parseCompilationUnit(
        "class A class B {}", [ParserErrorCode.MISSING_CLASS_BODY]);
  }

  @failingTest
  void test_missingClosingParenthesis() {
    // It is possible that it is not possible to generate this error (that it's
    // being reported in code that cannot actually be reached), but that hasn't
    // been proven yet.
    createParser('(int a, int b ;');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener
        .assertErrorsWithCodes([ParserErrorCode.MISSING_CLOSING_PARENTHESIS]);
  }

  void test_missingConstFinalVarOrType_static() {
    ParserTestCase.parseCompilationUnit("class A { static f; }",
        [ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE]);
  }

  void test_missingConstFinalVarOrType_topLevel() {
    createParser('a;');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE]);
  }

  void test_missingEnumBody() {
    createParser('enum E;');
    EnumDeclaration declaration =
        parser.parseEnumDeclaration(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(declaration);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_ENUM_BODY]);
  }

  void test_missingExpressionInThrow_withCascade() {
    createParser('throw;');
    ThrowExpression expression = parser.parseThrowExpression();
    expectNotNullIfNoErrors(expression);
    listener
        .assertErrorsWithCodes([ParserErrorCode.MISSING_EXPRESSION_IN_THROW]);
  }

  void test_missingExpressionInThrow_withoutCascade() {
    createParser('throw;');
    ThrowExpression expression = parser.parseThrowExpressionWithoutCascade();
    expectNotNullIfNoErrors(expression);
    listener
        .assertErrorsWithCodes([ParserErrorCode.MISSING_EXPRESSION_IN_THROW]);
  }

  void test_missingFunctionBody_emptyNotAllowed() {
    createParser(';');
    FunctionBody functionBody = parser.parseFunctionBody(
        false, ParserErrorCode.MISSING_FUNCTION_BODY, false);
    expectNotNullIfNoErrors(functionBody);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_FUNCTION_BODY]);
  }

  void test_missingFunctionBody_invalid() {
    createParser('return 0;');
    FunctionBody functionBody = parser.parseFunctionBody(
        false, ParserErrorCode.MISSING_FUNCTION_BODY, false);
    expectNotNullIfNoErrors(functionBody);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_FUNCTION_BODY]);
  }

  @failingTest
  void test_missingFunctionParameters_local_nonVoid_block() {
    // The parser does not recognize this as a function declaration, so it tries
    // to parse it as an expression statement. It isn't clear what the best
    // error message is in this case.
    ParserTestCase.parseStatement(
        "int f { return x;}", [ParserErrorCode.MISSING_FUNCTION_PARAMETERS]);
  }

  @failingTest
  void test_missingFunctionParameters_local_nonVoid_expression() {
    // The parser does not recognize this as a function declaration, so it tries
    // to parse it as an expression statement. It isn't clear what the best
    // error message is in this case.
    ParserTestCase.parseStatement(
        "int f => x;", [ParserErrorCode.MISSING_FUNCTION_PARAMETERS]);
  }

  void test_missingFunctionParameters_local_void_block() {
    ParserTestCase.parseStatement(
        "void f { return x;}", [ParserErrorCode.MISSING_FUNCTION_PARAMETERS]);
  }

  void test_missingFunctionParameters_local_void_expression() {
    ParserTestCase.parseStatement(
        "void f => x;", [ParserErrorCode.MISSING_FUNCTION_PARAMETERS]);
  }

  void test_missingFunctionParameters_topLevel_nonVoid_block() {
    ParserTestCase.parseCompilationUnit(
        "int f { return x;}", [ParserErrorCode.MISSING_FUNCTION_PARAMETERS]);
  }

  void test_missingFunctionParameters_topLevel_nonVoid_expression() {
    ParserTestCase.parseCompilationUnit(
        "int f => x;", [ParserErrorCode.MISSING_FUNCTION_PARAMETERS]);
  }

  void test_missingFunctionParameters_topLevel_void_block() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(
        "void f { return x;}", [ParserErrorCode.MISSING_FUNCTION_PARAMETERS]);
    FunctionDeclaration funct = unit.declarations[0];
    expect(funct.functionExpression.parameters, hasLength(0));
  }

  void test_missingFunctionParameters_topLevel_void_expression() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(
        "void f => x;", [ParserErrorCode.MISSING_FUNCTION_PARAMETERS]);
    FunctionDeclaration funct = unit.declarations[0];
    expect(funct.functionExpression.parameters, hasLength(0));
  }

  void test_missingIdentifier_afterOperator() {
    createParser('1 *');
    BinaryExpression expression = parser.parseMultiplicativeExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_IDENTIFIER]);
  }

  void test_missingIdentifier_beforeClosingCurly() {
    createParser('int}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN]);
  }

  void test_missingIdentifier_inEnum() {
    createParser('enum E {, TWO}');
    EnumDeclaration declaration =
        parser.parseEnumDeclaration(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(declaration);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_IDENTIFIER]);
  }

  void test_missingIdentifier_inSymbol_afterPeriod() {
    createParser('#a.');
    SymbolLiteral literal = parser.parseSymbolLiteral();
    expectNotNullIfNoErrors(literal);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_IDENTIFIER]);
  }

  void test_missingIdentifier_inSymbol_first() {
    createParser('#');
    SymbolLiteral literal = parser.parseSymbolLiteral();
    expectNotNullIfNoErrors(literal);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_IDENTIFIER]);
  }

  void test_missingIdentifier_number() {
    createParser('1');
    SimpleIdentifier expression = parser.parseSimpleIdentifier();
    expectNotNullIfNoErrors(expression);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.isSynthetic, isTrue);
  }

  void test_missingIdentifierForParameterGroup() {
    createParser('(,)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_IDENTIFIER]);
  }

  void test_missingKeywordOperator() {
    createParser('+(x) {}');
    MethodDeclaration method =
        parser.parseOperator(emptyCommentAndMetadata(), null, null);
    expectNotNullIfNoErrors(method);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_KEYWORD_OPERATOR]);
  }

  void test_missingKeywordOperator_parseClassMember() {
    createParser('+() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_KEYWORD_OPERATOR]);
  }

  void test_missingKeywordOperator_parseClassMember_afterTypeName() {
    createParser('int +() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_KEYWORD_OPERATOR]);
  }

  void test_missingKeywordOperator_parseClassMember_afterVoid() {
    createParser('void +() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_KEYWORD_OPERATOR]);
  }

  void test_missingMethodParameters_void_block() {
    createParser('void m {} }');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_METHOD_PARAMETERS]);
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.parameters, hasLength(0));
  }

  void test_missingMethodParameters_void_expression() {
    createParser('void m => null; }');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_METHOD_PARAMETERS]);
  }

  void test_missingNameInLibraryDirective() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(
        "library;", [ParserErrorCode.MISSING_NAME_IN_LIBRARY_DIRECTIVE]);
    expect(unit, isNotNull);
  }

  void test_missingNameInPartOfDirective() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(
        "part of;", [ParserErrorCode.MISSING_NAME_IN_PART_OF_DIRECTIVE]);
    expect(unit, isNotNull);
  }

  void test_missingPrefixInDeferredImport() {
    ParserTestCase.parseCompilationUnit("import 'foo.dart' deferred;",
        [ParserErrorCode.MISSING_PREFIX_IN_DEFERRED_IMPORT]);
  }

  void test_missingStartAfterSync() {
    createParser('sync {}');
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_STAR_AFTER_SYNC]);
  }

  void test_missingStatement() {
    ParserTestCase.parseStatement("is", [ParserErrorCode.MISSING_STATEMENT]);
  }

  void test_missingStatement_afterVoid() {
    ParserTestCase.parseStatement("void;", [ParserErrorCode.MISSING_STATEMENT]);
  }

  void test_missingTerminatorForParameterGroup_named() {
    createParser('(a, {b: 0)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.MISSING_TERMINATOR_FOR_PARAMETER_GROUP]);
  }

  void test_missingTerminatorForParameterGroup_optional() {
    createParser('(a, [b = 0)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.MISSING_TERMINATOR_FOR_PARAMETER_GROUP]);
  }

  void test_missingTypedefParameters_nonVoid() {
    ParserTestCase.parseCompilationUnit(
        "typedef int F;", [ParserErrorCode.MISSING_TYPEDEF_PARAMETERS]);
  }

  void test_missingTypedefParameters_typeParameters() {
    ParserTestCase.parseCompilationUnit(
        "typedef F<E>;", [ParserErrorCode.MISSING_TYPEDEF_PARAMETERS]);
  }

  void test_missingTypedefParameters_void() {
    ParserTestCase.parseCompilationUnit(
        "typedef void F;", [ParserErrorCode.MISSING_TYPEDEF_PARAMETERS]);
  }

  void test_missingVariableInForEach() {
    createParser('for (a < b in foo) {}');
    Statement statement = parser.parseForStatement();
    expectNotNullIfNoErrors(statement);
    listener
        .assertErrorsWithCodes([ParserErrorCode.MISSING_VARIABLE_IN_FOR_EACH]);
  }

  void test_mixedParameterGroups_namedPositional() {
    createParser('(a, {b}, [c])');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrorsWithCodes([ParserErrorCode.MIXED_PARAMETER_GROUPS]);
  }

  void test_mixedParameterGroups_positionalNamed() {
    createParser('(a, [b], {c})');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrorsWithCodes([ParserErrorCode.MIXED_PARAMETER_GROUPS]);
  }

  void test_mixin_application_lacks_with_clause() {
    ParserTestCase.parseCompilationUnit(
        "class Foo = Bar;", [ParserErrorCode.EXPECTED_TOKEN]);
  }

  void test_multipleExtendsClauses() {
    ParserTestCase.parseCompilationUnit("class A extends B extends C {}",
        [ParserErrorCode.MULTIPLE_EXTENDS_CLAUSES]);
  }

  void test_multipleImplementsClauses() {
    ParserTestCase.parseCompilationUnit("class A implements B implements C {}",
        [ParserErrorCode.MULTIPLE_IMPLEMENTS_CLAUSES]);
  }

  void test_multipleLibraryDirectives() {
    ParserTestCase.parseCompilationUnit(
        "library l; library m;", [ParserErrorCode.MULTIPLE_LIBRARY_DIRECTIVES]);
  }

  void test_multipleNamedParameterGroups() {
    createParser('(a, {b}, {c})');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.MULTIPLE_NAMED_PARAMETER_GROUPS]);
  }

  void test_multiplePartOfDirectives() {
    ParserTestCase.parseCompilationUnit(
        "part of l; part of m;", [ParserErrorCode.MULTIPLE_PART_OF_DIRECTIVES]);
  }

  void test_multiplePositionalParameterGroups() {
    createParser('(a, [b], [c])');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.MULTIPLE_POSITIONAL_PARAMETER_GROUPS]);
  }

  void test_multipleVariablesInForEach() {
    createParser('for (int a, b in foo) {}');
    Statement statement = parser.parseForStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.MULTIPLE_VARIABLES_IN_FOR_EACH]);
  }

  void test_multipleWithClauses() {
    ParserTestCase.parseCompilationUnit("class A extends B with C with D {}",
        [ParserErrorCode.MULTIPLE_WITH_CLAUSES]);
  }

  @failingTest
  void test_namedFunctionExpression() {
    createParser('f() {}');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertErrorsWithCodes([ParserErrorCode.NAMED_FUNCTION_EXPRESSION]);
    expect(expression, new isInstanceOf<FunctionExpression>());
  }

  void test_namedParameterOutsideGroup() {
    createParser('(a, b : 0)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener
        .assertErrorsWithCodes([ParserErrorCode.NAMED_PARAMETER_OUTSIDE_GROUP]);
    expect(list.parameters[0].kind, ParameterKind.REQUIRED);
    expect(list.parameters[1].kind, ParameterKind.NAMED);
  }

  void test_nonConstructorFactory_field() {
    createParser('factory int x;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.NON_CONSTRUCTOR_FACTORY]);
  }

  void test_nonConstructorFactory_method() {
    createParser('factory int m() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.NON_CONSTRUCTOR_FACTORY]);
  }

  void test_nonIdentifierLibraryName_library() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(
        "library 'lib';", [ParserErrorCode.NON_IDENTIFIER_LIBRARY_NAME]);
    expect(unit, isNotNull);
  }

  void test_nonIdentifierLibraryName_partOf() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(
        "part of 'lib';", [ParserErrorCode.NON_IDENTIFIER_LIBRARY_NAME]);
    expect(unit, isNotNull);
  }

  void test_nonPartOfDirectiveInPart_after() {
    ParserTestCase.parseCompilationUnit("part of l; part 'f.dart';",
        [ParserErrorCode.NON_PART_OF_DIRECTIVE_IN_PART]);
  }

  void test_nonPartOfDirectiveInPart_before() {
    ParserTestCase.parseCompilationUnit("part 'f.dart'; part of m;",
        [ParserErrorCode.NON_PART_OF_DIRECTIVE_IN_PART]);
  }

  void test_nonUserDefinableOperator() {
    createParser('operator +=(int x) => x + 1;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener
        .assertErrorsWithCodes([ParserErrorCode.NON_USER_DEFINABLE_OPERATOR]);
  }

  void test_nullableTypeInExtends() {
    enableNnbd = true;
    createParser('extends B?');
    ExtendsClause clause = parser.parseExtendsClause();
    expectNotNullIfNoErrors(clause);
    listener.assertErrorsWithCodes([ParserErrorCode.NULLABLE_TYPE_IN_EXTENDS]);
  }

  void test_nullableTypeInImplements() {
    enableNnbd = true;
    createParser('implements I?');
    ImplementsClause clause = parser.parseImplementsClause();
    expectNotNullIfNoErrors(clause);
    listener
        .assertErrorsWithCodes([ParserErrorCode.NULLABLE_TYPE_IN_IMPLEMENTS]);
  }

  void test_nullableTypeInWith() {
    enableNnbd = true;
    createParser('with M?');
    WithClause clause = parser.parseWithClause();
    expectNotNullIfNoErrors(clause);
    listener.assertErrorsWithCodes([ParserErrorCode.NULLABLE_TYPE_IN_WITH]);
  }

  void test_nullableTypeParameter() {
    enableNnbd = true;
    createParser('T?');
    TypeParameter parameter = parser.parseTypeParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertErrorsWithCodes([ParserErrorCode.NULLABLE_TYPE_PARAMETER]);
  }

  void test_optionalAfterNormalParameters_named() {
    ParserTestCase.parseCompilationUnit(
        "f({a}, b) {}", [ParserErrorCode.NORMAL_BEFORE_OPTIONAL_PARAMETERS]);
  }

  void test_optionalAfterNormalParameters_positional() {
    ParserTestCase.parseCompilationUnit(
        "f([a], b) {}", [ParserErrorCode.NORMAL_BEFORE_OPTIONAL_PARAMETERS]);
  }

  void test_parseCascadeSection_missingIdentifier() {
    createParser('..()');
    MethodInvocation methodInvocation = parser.parseCascadeSection();
    expectNotNullIfNoErrors(methodInvocation);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_IDENTIFIER]);
    expect(methodInvocation.target, isNull);
    expect(methodInvocation.methodName.name, "");
    expect(methodInvocation.typeArguments, isNull);
    expect(methodInvocation.argumentList.arguments, hasLength(0));
  }

  void test_parseCascadeSection_missingIdentifier_typeArguments() {
    createParser('..<E>()');
    MethodInvocation methodInvocation = parser.parseCascadeSection();
    expectNotNullIfNoErrors(methodInvocation);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_IDENTIFIER]);
    expect(methodInvocation.target, isNull);
    expect(methodInvocation.methodName.name, "");
    expect(methodInvocation.typeArguments, isNotNull);
    expect(methodInvocation.argumentList.arguments, hasLength(0));
  }

  void test_positionalAfterNamedArgument() {
    createParser('(x: 1, 2)');
    ArgumentList list = parser.parseArgumentList();
    expectNotNullIfNoErrors(list);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.POSITIONAL_AFTER_NAMED_ARGUMENT]);
  }

  void test_positionalParameterOutsideGroup() {
    createParser('(a, b = 0)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.POSITIONAL_PARAMETER_OUTSIDE_GROUP]);
    expect(list.parameters[0].kind, ParameterKind.REQUIRED);
    expect(list.parameters[1].kind, ParameterKind.POSITIONAL);
  }

  void test_redirectingConstructorWithBody_named() {
    createParser('C.x() : this() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.REDIRECTING_CONSTRUCTOR_WITH_BODY]);
  }

  void test_redirectingConstructorWithBody_unnamed() {
    createParser('C() : this.x() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.REDIRECTING_CONSTRUCTOR_WITH_BODY]);
  }

  void test_redirectionInNonFactoryConstructor() {
    createParser('C() = D;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR]);
  }

  void test_setterInFunction_block() {
    ParserTestCase.parseStatement(
        "set x(v) {_x = v;}", [ParserErrorCode.SETTER_IN_FUNCTION]);
  }

  void test_setterInFunction_expression() {
    ParserTestCase.parseStatement(
        "set x(v) => _x = v;", [ParserErrorCode.SETTER_IN_FUNCTION]);
  }

  void test_staticAfterConst() {
    createParser('final static int f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.STATIC_AFTER_FINAL]);
  }

  void test_staticAfterFinal() {
    createParser('const static int f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.STATIC_AFTER_CONST]);
  }

  void test_staticAfterVar() {
    createParser('var static f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.STATIC_AFTER_VAR]);
  }

  void test_staticConstructor() {
    createParser('static C.m() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.STATIC_CONSTRUCTOR]);
  }

  void test_staticGetterWithoutBody() {
    createParser('static get m;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener
        .assertErrorsWithCodes([ParserErrorCode.STATIC_GETTER_WITHOUT_BODY]);
  }

  void test_staticOperator_noReturnType() {
    createParser('static operator +(int x) => x + 1;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.STATIC_OPERATOR]);
  }

  void test_staticOperator_returnType() {
    createParser('static int operator +(int x) => x + 1;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.STATIC_OPERATOR]);
  }

  void test_staticSetterWithoutBody() {
    createParser('static set m(x);');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener
        .assertErrorsWithCodes([ParserErrorCode.STATIC_SETTER_WITHOUT_BODY]);
  }

  void test_staticTopLevelDeclaration_class() {
    ParserTestCase.parseCompilationUnit(
        "static class C {}", [ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION]);
  }

  void test_staticTopLevelDeclaration_function() {
    ParserTestCase.parseCompilationUnit(
        "static f() {}", [ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION]);
  }

  void test_staticTopLevelDeclaration_typedef() {
    ParserTestCase.parseCompilationUnit(
        "static typedef F();", [ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION]);
  }

  void test_staticTopLevelDeclaration_variable() {
    ParserTestCase.parseCompilationUnit(
        "static var x;", [ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION]);
  }

  void test_string_unterminated_interpolation_block() {
    ParserTestCase.parseCompilationUnit(
        r'''
m() {
 {
 '${${
''',
        [
          ScannerErrorCode.UNTERMINATED_STRING_LITERAL,
          ParserErrorCode.EXPECTED_TOKEN,
          ParserErrorCode.EXPECTED_TOKEN,
          ParserErrorCode.EXPECTED_TOKEN,
          ParserErrorCode.EXPECTED_TOKEN,
          ParserErrorCode.EXPECTED_TOKEN,
          ParserErrorCode.EXPECTED_TOKEN,
        ]);
  }

  void test_switchHasCaseAfterDefaultCase() {
    createParser('switch (a) {default: return 0; case 1: return 1;}');
    SwitchStatement statement = parser.parseSwitchStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE]);
  }

  void test_switchHasCaseAfterDefaultCase_repeated() {
    createParser(
        'switch (a) {default: return 0; case 1: return 1; case 2: return 2;}');
    SwitchStatement statement = parser.parseSwitchStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertErrorsWithCodes([
      ParserErrorCode.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE,
      ParserErrorCode.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE
    ]);
  }

  void test_switchHasMultipleDefaultCases() {
    createParser('switch (a) {default: return 0; default: return 1;}');
    SwitchStatement statement = parser.parseSwitchStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.SWITCH_HAS_MULTIPLE_DEFAULT_CASES]);
  }

  void test_switchHasMultipleDefaultCases_repeated() {
    createParser(
        'switch (a) {default: return 0; default: return 1; default: return 2;}');
    SwitchStatement statement = parser.parseSwitchStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertErrorsWithCodes([
      ParserErrorCode.SWITCH_HAS_MULTIPLE_DEFAULT_CASES,
      ParserErrorCode.SWITCH_HAS_MULTIPLE_DEFAULT_CASES
    ]);
  }

  void test_topLevel_getter() {
    createParser('get x => 7;');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<FunctionDeclaration>());
    FunctionDeclaration function = member;
    expect(function.functionExpression.parameters, isNull);
  }

  void test_topLevelOperator_withoutType() {
    createParser('operator +(bool x, bool y) => x | y;');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.TOP_LEVEL_OPERATOR]);
  }

  void test_topLevelOperator_withType() {
    createParser('bool operator +(bool x, bool y) => x | y;');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.TOP_LEVEL_OPERATOR]);
  }

  void test_topLevelOperator_withVoid() {
    createParser('void operator +(bool x, bool y) => x | y;');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.TOP_LEVEL_OPERATOR]);
  }

  void test_topLevelVariable_withMetadata() {
    ParserTestCase.parseCompilationUnit("String @A string;", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE
    ]);
  }

  void test_typedefInClass_withoutReturnType() {
    ParserTestCase.parseCompilationUnit(
        "class C { typedef F(x); }", [ParserErrorCode.TYPEDEF_IN_CLASS]);
  }

  void test_typedefInClass_withReturnType() {
    ParserTestCase.parseCompilationUnit("class C { typedef int F(int x); }",
        [ParserErrorCode.TYPEDEF_IN_CLASS]);
  }

  void test_unexpectedTerminatorForParameterGroup_named() {
    createParser('(a, b})');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP]);
  }

  void test_unexpectedTerminatorForParameterGroup_optional() {
    createParser('(a, b])');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP]);
  }

  void test_unexpectedToken_endOfFieldDeclarationStatement() {
    ParserTestCase.parseStatement(
        "String s = (null));", [ParserErrorCode.UNEXPECTED_TOKEN]);
  }

  @failingTest
  void test_unexpectedToken_invalidPostfixExpression() {
    // Note: this might not be the right error to produce, but some error should
    // be produced
    parseExpression("f()++", [ParserErrorCode.UNEXPECTED_TOKEN]);
  }

  void test_unexpectedToken_returnInExpressionFuntionBody() {
    ParserTestCase.parseCompilationUnit(
        "f() => return null;", [ParserErrorCode.UNEXPECTED_TOKEN]);
  }

  void test_unexpectedToken_semicolonBetweenClassMembers() {
    createParser('class C { int x; ; int y;}');
    ClassDeclaration declaration =
        parser.parseClassDeclaration(emptyCommentAndMetadata(), null);
    expectNotNullIfNoErrors(declaration);
    listener.assertErrorsWithCodes([ParserErrorCode.UNEXPECTED_TOKEN]);
  }

  void test_unexpectedToken_semicolonBetweenCompilationUnitMembers() {
    ParserTestCase.parseCompilationUnit(
        "int x; ; int y;", [ParserErrorCode.UNEXPECTED_TOKEN]);
  }

  void test_unterminatedString_at_eof() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    ParserTestCase.parseCompilationUnit(
        r'''
void main() {
  var x = "''',
        [
          ScannerErrorCode.UNTERMINATED_STRING_LITERAL,
          ParserErrorCode.EXPECTED_TOKEN,
          ParserErrorCode.EXPECTED_TOKEN
        ]);
  }

  void test_unterminatedString_at_eol() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    ParserTestCase.parseCompilationUnit(
        r'''
void main() {
  var x = "
;
}
''',
        [ScannerErrorCode.UNTERMINATED_STRING_LITERAL]);
  }

  void test_unterminatedString_multiline_at_eof_3_quotes() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    ParserTestCase.parseCompilationUnit(
        r'''
void main() {
  var x = """''',
        [
          ScannerErrorCode.UNTERMINATED_STRING_LITERAL,
          ParserErrorCode.EXPECTED_TOKEN,
          ParserErrorCode.EXPECTED_TOKEN
        ]);
  }

  void test_unterminatedString_multiline_at_eof_4_quotes() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    ParserTestCase.parseCompilationUnit(
        r'''
void main() {
  var x = """"''',
        [
          ScannerErrorCode.UNTERMINATED_STRING_LITERAL,
          ParserErrorCode.EXPECTED_TOKEN,
          ParserErrorCode.EXPECTED_TOKEN
        ]);
  }

  void test_unterminatedString_multiline_at_eof_5_quotes() {
    // Although the "unterminated string" error message is produced by the
    // scanner, we need to verify that the parser can handle the tokens
    // produced by the scanner when an unterminated string is encountered.
    ParserTestCase.parseCompilationUnit(
        r'''
void main() {
  var x = """""''',
        [
          ScannerErrorCode.UNTERMINATED_STRING_LITERAL,
          ParserErrorCode.EXPECTED_TOKEN,
          ParserErrorCode.EXPECTED_TOKEN
        ]);
  }

  void test_useOfUnaryPlusOperator() {
    createParser('+x');
    Expression expression = parser.parseUnaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression, new isInstanceOf<SimpleIdentifier>());
    SimpleIdentifier identifier = expression;
    expect(identifier.isSynthetic, isTrue);
  }

  void test_varAndType_field() {
    ParserTestCase.parseCompilationUnit(
        "class C { var int x; }", [ParserErrorCode.VAR_AND_TYPE]);
  }

  @failingTest
  void test_varAndType_local() {
    // This is currently reporting EXPECTED_TOKEN for a missing semicolon, but
    // this would be a better error message.
    ParserTestCase.parseStatement("var int x;", [ParserErrorCode.VAR_AND_TYPE]);
  }

  @failingTest
  void test_varAndType_parameter() {
    // This is currently reporting EXPECTED_TOKEN for a missing semicolon, but
    // this would be a better error message.
    createParser('(var int x)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrorsWithCodes([ParserErrorCode.VAR_AND_TYPE]);
  }

  void test_varAndType_topLevelVariable() {
    ParserTestCase
        .parseCompilationUnit("var int x;", [ParserErrorCode.VAR_AND_TYPE]);
  }

  void test_varAsTypeName_as() {
    parseExpression("x as var", [ParserErrorCode.VAR_AS_TYPE_NAME]);
  }

  void test_varClass() {
    ParserTestCase
        .parseCompilationUnit("var class C {}", [ParserErrorCode.VAR_CLASS]);
  }

  void test_varEnum() {
    ParserTestCase
        .parseCompilationUnit("var enum E {ONE}", [ParserErrorCode.VAR_ENUM]);
  }

  void test_varReturnType() {
    createParser('var m() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.VAR_RETURN_TYPE]);
  }

  void test_varTypedef() {
    ParserTestCase.parseCompilationUnit(
        "var typedef F();", [ParserErrorCode.VAR_TYPEDEF]);
  }

  void test_voidParameter() {
    createParser('void a)');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertErrorsWithCodes([ParserErrorCode.VOID_PARAMETER]);
  }

  void test_voidVariable_parseClassMember_initializer() {
    createParser('void x = 0;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.VOID_VARIABLE]);
  }

  void test_voidVariable_parseClassMember_noInitializer() {
    createParser('void x;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.VOID_VARIABLE]);
  }

  void test_voidVariable_parseCompilationUnit_initializer() {
    ParserTestCase
        .parseCompilationUnit("void x = 0;", [ParserErrorCode.VOID_VARIABLE]);
  }

  void test_voidVariable_parseCompilationUnit_noInitializer() {
    ParserTestCase
        .parseCompilationUnit("void x;", [ParserErrorCode.VOID_VARIABLE]);
  }

  void test_voidVariable_parseCompilationUnitMember_initializer() {
    createParser('void a = 0;');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.VOID_VARIABLE]);
  }

  void test_voidVariable_parseCompilationUnitMember_noInitializer() {
    createParser('void a;');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.VOID_VARIABLE]);
  }

  void test_voidVariable_statement_initializer() {
    ParserTestCase.parseStatement("void x = 0;", [
      ParserErrorCode.VOID_VARIABLE,
      ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE
    ]);
  }

  void test_voidVariable_statement_noInitializer() {
    ParserTestCase.parseStatement("void x;", [
      ParserErrorCode.VOID_VARIABLE,
      ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE
    ]);
  }

  void test_withBeforeExtends() {
    ParserTestCase.parseCompilationUnit(
        "class A with B extends C {}", [ParserErrorCode.WITH_BEFORE_EXTENDS]);
  }

  void test_withWithoutExtends() {
    createParser('class A with B, C {}');
    ClassDeclaration declaration =
        parser.parseClassDeclaration(emptyCommentAndMetadata(), null);
    expectNotNullIfNoErrors(declaration);
    listener.assertErrorsWithCodes([ParserErrorCode.WITH_WITHOUT_EXTENDS]);
  }

  void test_wrongSeparatorForPositionalParameter() {
    createParser('(a, [b : 0])');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER]);
  }

  void test_wrongTerminatorForParameterGroup_named() {
    createParser('(a, {b, c])');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.WRONG_TERMINATOR_FOR_PARAMETER_GROUP]);
  }

  void test_wrongTerminatorForParameterGroup_optional() {
    createParser('(a, [b, c})');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.WRONG_TERMINATOR_FOR_PARAMETER_GROUP]);
  }
}

@reflectiveTest
class NonErrorParserTest extends ParserTestCase {
  void test_constFactory_external() {
    createParser('external const factory C();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
  }

  void test_staticMethod_notParsingFunctionBodies() {
    ParserTestCase.parseFunctionBodies = false;
    try {
      createParser('class C { static void m() {} }');
      CompilationUnit unit = parser.parseCompilationUnit2();
      expectNotNullIfNoErrors(unit);
      listener.assertNoErrors();
    } finally {
      ParserTestCase.parseFunctionBodies = true;
    }
  }
}

class ParserTestCase extends EngineTestCase {
  /**
   * A flag indicating whether parser is to parse function bodies.
   */
  static bool parseFunctionBodies = true;

  /**
   * A flag indicating whether the parser is to parse asserts in the initializer
   * list of a constructor.
   */
  bool enableAssertInitializer = false;

  /**
   * A flag indicating whether parser is to parse async.
   */
  bool parseAsync = true;

  /**
   * Whether generic method comments should be enabled for the test.
   */
  bool enableGenericMethodComments = false;

  /**
   * A flag indicating whether lazy assignment operators should be enabled for
   * the test.
   */
  bool enableLazyAssignmentOperators = false;

  /**
   * A flag indicating whether the parser is to parse the non-nullable modifier
   * in type names.
   */
  bool enableNnbd = false;

  /**
   * A flag indicating whether the parser is to parse part-of directives that
   * specify a URI rather than a library name.
   */
  bool enableUriInPartOf = false;

  /**
   * The error listener to which scanner and parser errors will be reported.
   *
   * This field is typically initialized by invoking [createParser].
   */
  GatheringErrorListener listener;

  /**
   * The parser used by the test.
   *
   * This field is typically initialized by invoking [createParser].
   */
  Parser parser;

  /**
   * Return a CommentAndMetadata object with the given values that can be used for testing.
   *
   * @param comment the comment to be wrapped in the object
   * @param annotations the annotations to be wrapped in the object
   * @return a CommentAndMetadata object that can be used for testing
   */
  CommentAndMetadata commentAndMetadata(Comment comment,
      [List<Annotation> annotations]) {
    return new CommentAndMetadata(comment, annotations);
  }

  /**
   * Create the [parser] and [listener] used by a test. The [parser] will be
   * prepared to parse the tokens scanned from the given [content].
   */
  void createParser(String content) {
    listener = new GatheringErrorListener();
    //
    // Scan the source.
    //
    TestSource source = new TestSource();
    CharacterReader reader = new CharSequenceReader(content);
    Scanner scanner = new Scanner(source, reader, listener);
    scanner.scanGenericMethodComments = enableGenericMethodComments;
    scanner.scanLazyAssignmentOperators = enableLazyAssignmentOperators;
    Token tokenStream = scanner.tokenize();
    listener.setLineInfo(source, scanner.lineStarts);
    //
    // Create and initialize the parser.
    //
    parser = new Parser(source, listener);
    parser.enableAssertInitializer = enableAssertInitializer;
    parser.parseGenericMethodComments = enableGenericMethodComments;
    parser.parseFunctionBodies = parseFunctionBodies;
    parser.enableNnbd = enableNnbd;
    parser.enableUriInPartOf = enableUriInPartOf;
    parser.currentToken = tokenStream;
  }

  /**
   * Return an empty CommentAndMetadata object that can be used for testing.
   *
   * @return an empty CommentAndMetadata object that can be used for testing
   */
  CommentAndMetadata emptyCommentAndMetadata() =>
      new CommentAndMetadata(null, null);

  void expectNotNullIfNoErrors(Object result) {
    if (!listener.hasErrors) {
      expect(result, isNotNull);
    }
  }

  /**
   * Parse the given [source] as a compilation unit. Throw an exception if the
   * source could not be parsed, if the compilation errors in the source do not
   * match those that are expected, or if the result would have been `null`.
   */
  CompilationUnit parseCompilationUnitWithOptions(String source,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    createParser(source);
    CompilationUnit unit = parser.parseCompilationUnit2();
    expect(unit, isNotNull);
    listener.assertErrorsWithCodes(errorCodes);
    return unit;
  }

  /**
   * Parse the given source as an expression.
   *
   * @param source the source to be parsed
   * @param errorCodes the error codes of the errors that are expected to be found
   * @return the expression that was parsed
   * @throws Exception if the source could not be parsed, if the compilation errors in the source do
   *           not match those that are expected, or if the result would have been `null`
   */
  Expression parseExpression(String source,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    createParser(source);
    Expression expression = parser.parseExpression2();
    expectNotNullIfNoErrors(expression);
    listener.assertErrorsWithCodes(errorCodes);
    return expression;
  }

  @override
  void setUp() {
    super.setUp();
    parseFunctionBodies = true;
  }

  /**
   * Parse the given source as a compilation unit.
   *
   * @param source the source to be parsed
   * @param errorCodes the error codes of the errors that are expected to be found
   * @return the compilation unit that was parsed
   * @throws Exception if the source could not be parsed, if the compilation errors in the source do
   *           not match those that are expected, or if the result would have been `null`
   */
  static CompilationUnit parseCompilationUnit(String source,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    GatheringErrorListener listener = new GatheringErrorListener();
    Scanner scanner =
        new Scanner(null, new CharSequenceReader(source), listener);
    listener.setLineInfo(new TestSource(), scanner.lineStarts);
    Token token = scanner.tokenize();
    Parser parser = new Parser(null, listener);
    CompilationUnit unit = parser.parseCompilationUnit(token);
    expect(unit, isNotNull);
    listener.assertErrorsWithCodes(errorCodes);
    return unit;
  }

  /**
   * Parse the given [code] as a compilation unit.
   */
  static CompilationUnit parseCompilationUnit2(String code,
      {AnalysisErrorListener listener}) {
    listener ??= AnalysisErrorListener.NULL_LISTENER;
    Scanner scanner = new Scanner(null, new CharSequenceReader(code), listener);
    Token token = scanner.tokenize();
    Parser parser = new Parser(null, listener);
    CompilationUnit unit = parser.parseCompilationUnit(token);
    unit.lineInfo = new LineInfo(scanner.lineStarts);
    return unit;
  }

  /**
   * Parse the given [source] as a statement. The [errorCodes] are the error
   * codes of the errors that are expected to be found. If
   * [enableLazyAssignmentOperators] is `true`, then lazy assignment operators
   * should be enabled.
   */
  static Statement parseStatement(String source,
      [List<ErrorCode> errorCodes = const <ErrorCode>[],
      bool enableLazyAssignmentOperators]) {
    GatheringErrorListener listener = new GatheringErrorListener();
    Scanner scanner =
        new Scanner(null, new CharSequenceReader(source), listener);
    scanner.scanLazyAssignmentOperators = enableLazyAssignmentOperators;
    listener.setLineInfo(new TestSource(), scanner.lineStarts);
    Token token = scanner.tokenize();
    Parser parser = new Parser(null, listener);
    Statement statement = parser.parseStatement(token);
    expect(statement, isNotNull);
    listener.assertErrorsWithCodes(errorCodes);
    return statement;
  }

  /**
   * Parse the given source as a sequence of statements.
   *
   * @param source the source to be parsed
   * @param expectedCount the number of statements that are expected
   * @param errorCodes the error codes of the errors that are expected to be found
   * @return the statements that were parsed
   * @throws Exception if the source could not be parsed, if the number of statements does not match
   *           the expected count, if the compilation errors in the source do not match those that
   *           are expected, or if the result would have been `null`
   */
  static List<Statement> parseStatements(String source, int expectedCount,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    GatheringErrorListener listener = new GatheringErrorListener();
    Scanner scanner =
        new Scanner(null, new CharSequenceReader(source), listener);
    listener.setLineInfo(new TestSource(), scanner.lineStarts);
    Token token = scanner.tokenize();
    Parser parser = new Parser(null, listener);
    List<Statement> statements = parser.parseStatements(token);
    expect(statements, hasLength(expectedCount));
    listener.assertErrorsWithCodes(errorCodes);
    return statements;
  }
}

/**
 * The class `RecoveryParserTest` defines parser tests that test the parsing of invalid code
 * sequences to ensure that the correct recovery steps are taken in the parser.
 */
@reflectiveTest
class RecoveryParserTest extends ParserTestCase {
  void test_additiveExpression_missing_LHS() {
    BinaryExpression expression =
        parseExpression("+ y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_additiveExpression_missing_LHS_RHS() {
    BinaryExpression expression = parseExpression("+", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_additiveExpression_missing_RHS() {
    BinaryExpression expression =
        parseExpression("x +", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_additiveExpression_missing_RHS_super() {
    BinaryExpression expression =
        parseExpression("super +", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_additiveExpression_precedence_multiplicative_left() {
    BinaryExpression expression = parseExpression("* +", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_additiveExpression_precedence_multiplicative_right() {
    BinaryExpression expression = parseExpression("+ *", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.rightOperand);
  }

  void test_additiveExpression_super() {
    BinaryExpression expression = parseExpression("super + +", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_assignableSelector() {
    IndexExpression expression =
        parseExpression("a.b[]", [ParserErrorCode.MISSING_IDENTIFIER]);
    Expression index = expression.index;
    expect(index, new isInstanceOf<SimpleIdentifier>());
    expect(index.isSynthetic, isTrue);
  }

  void test_assignmentExpression_missing_compound1() {
    AssignmentExpression expression =
        parseExpression("= y = 0", [ParserErrorCode.MISSING_IDENTIFIER]);
    Expression syntheticExpression = expression.leftHandSide;
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, syntheticExpression);
    expect(syntheticExpression.isSynthetic, isTrue);
  }

  void test_assignmentExpression_missing_compound2() {
    AssignmentExpression expression =
        parseExpression("x = = 0", [ParserErrorCode.MISSING_IDENTIFIER]);
    Expression syntheticExpression =
        (expression.rightHandSide as AssignmentExpression).leftHandSide;
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, syntheticExpression);
    expect(syntheticExpression.isSynthetic, isTrue);
  }

  void test_assignmentExpression_missing_compound3() {
    AssignmentExpression expression =
        parseExpression("x = y =", [ParserErrorCode.MISSING_IDENTIFIER]);
    Expression syntheticExpression =
        (expression.rightHandSide as AssignmentExpression).rightHandSide;
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, syntheticExpression);
    expect(syntheticExpression.isSynthetic, isTrue);
  }

  void test_assignmentExpression_missing_LHS() {
    AssignmentExpression expression =
        parseExpression("= 0", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.leftHandSide);
    expect(expression.leftHandSide.isSynthetic, isTrue);
  }

  void test_assignmentExpression_missing_RHS() {
    AssignmentExpression expression =
        parseExpression("x =", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.leftHandSide);
    expect(expression.rightHandSide.isSynthetic, isTrue);
  }

  void test_bitwiseAndExpression_missing_LHS() {
    BinaryExpression expression =
        parseExpression("& y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_bitwiseAndExpression_missing_LHS_RHS() {
    BinaryExpression expression = parseExpression("&", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseAndExpression_missing_RHS() {
    BinaryExpression expression =
        parseExpression("x &", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseAndExpression_missing_RHS_super() {
    BinaryExpression expression =
        parseExpression("super &", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseAndExpression_precedence_equality_left() {
    BinaryExpression expression = parseExpression("== &&", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseAndExpression_precedence_equality_right() {
    BinaryExpression expression = parseExpression("&& ==", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.rightOperand);
  }

  void test_bitwiseAndExpression_super() {
    BinaryExpression expression = parseExpression("super &  &", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseOrExpression_missing_LHS() {
    BinaryExpression expression =
        parseExpression("| y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_bitwiseOrExpression_missing_LHS_RHS() {
    BinaryExpression expression = parseExpression("|", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseOrExpression_missing_RHS() {
    BinaryExpression expression =
        parseExpression("x |", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseOrExpression_missing_RHS_super() {
    BinaryExpression expression =
        parseExpression("super |", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseOrExpression_precedence_xor_left() {
    BinaryExpression expression = parseExpression("^ |", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseOrExpression_precedence_xor_right() {
    BinaryExpression expression = parseExpression("| ^", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.rightOperand);
  }

  void test_bitwiseOrExpression_super() {
    BinaryExpression expression = parseExpression("super |  |", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseXorExpression_missing_LHS() {
    BinaryExpression expression =
        parseExpression("^ y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_bitwiseXorExpression_missing_LHS_RHS() {
    BinaryExpression expression = parseExpression("^", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseXorExpression_missing_RHS() {
    BinaryExpression expression =
        parseExpression("x ^", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseXorExpression_missing_RHS_super() {
    BinaryExpression expression =
        parseExpression("super ^", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseXorExpression_precedence_and_left() {
    BinaryExpression expression = parseExpression("& ^", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseXorExpression_precedence_and_right() {
    BinaryExpression expression = parseExpression("^ &", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.rightOperand);
  }

  void test_bitwiseXorExpression_super() {
    BinaryExpression expression = parseExpression("super ^  ^", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_classTypeAlias_withBody() {
    ParserTestCase.parseCompilationUnit(
        r'''
class A {}
class B = Object with A {}''',
        [ParserErrorCode.EXPECTED_TOKEN]);
  }

  void test_conditionalExpression_missingElse() {
    createParser('x ? y :');
    Expression expression = parser.parseConditionalExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression, new isInstanceOf<ConditionalExpression>());
    ConditionalExpression conditionalExpression = expression;
    expect(conditionalExpression.elseExpression,
        new isInstanceOf<SimpleIdentifier>());
    expect(conditionalExpression.elseExpression.isSynthetic, isTrue);
  }

  void test_conditionalExpression_missingThen() {
    createParser('x ? : z');
    Expression expression = parser.parseConditionalExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression, new isInstanceOf<ConditionalExpression>());
    ConditionalExpression conditionalExpression = expression;
    expect(conditionalExpression.thenExpression,
        new isInstanceOf<SimpleIdentifier>());
    expect(conditionalExpression.thenExpression.isSynthetic, isTrue);
  }

  void test_declarationBeforeDirective() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(
        "class foo { } import 'bar.dart';",
        [ParserErrorCode.DIRECTIVE_AFTER_DECLARATION]);
    expect(unit.directives, hasLength(1));
    expect(unit.declarations, hasLength(1));
    ClassDeclaration classDecl = unit.childEntities.first;
    expect(classDecl, isNotNull);
    expect(classDecl.name.name, 'foo');
  }

  void test_equalityExpression_missing_LHS() {
    BinaryExpression expression =
        parseExpression("== y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_equalityExpression_missing_LHS_RHS() {
    BinaryExpression expression = parseExpression("==", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_equalityExpression_missing_RHS() {
    BinaryExpression expression =
        parseExpression("x ==", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_equalityExpression_missing_RHS_super() {
    BinaryExpression expression =
        parseExpression("super ==", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_equalityExpression_precedence_relational_left() {
    BinaryExpression expression = parseExpression("is ==", [
      ParserErrorCode.EXPECTED_TYPE_NAME,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is IsExpression, IsExpression, expression.leftOperand);
  }

  void test_equalityExpression_precedence_relational_right() {
    BinaryExpression expression = parseExpression("== is", [
      ParserErrorCode.EXPECTED_TYPE_NAME,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is IsExpression, IsExpression, expression.rightOperand);
  }

  void test_equalityExpression_super() {
    BinaryExpression expression = parseExpression("super ==  ==", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_expressionList_multiple_end() {
    createParser(', 2, 3, 4');
    List<Expression> result = parser.parseExpressionList();
    expectNotNullIfNoErrors(result);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_IDENTIFIER]);
    expect(result, hasLength(4));
    Expression syntheticExpression = result[0];
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, syntheticExpression);
    expect(syntheticExpression.isSynthetic, isTrue);
  }

  void test_expressionList_multiple_middle() {
    createParser('1, 2, , 4');
    List<Expression> result = parser.parseExpressionList();
    expectNotNullIfNoErrors(result);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_IDENTIFIER]);
    expect(result, hasLength(4));
    Expression syntheticExpression = result[2];
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, syntheticExpression);
    expect(syntheticExpression.isSynthetic, isTrue);
  }

  void test_expressionList_multiple_start() {
    createParser('1, 2, 3,');
    List<Expression> result = parser.parseExpressionList();
    expectNotNullIfNoErrors(result);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_IDENTIFIER]);
    expect(result, hasLength(4));
    Expression syntheticExpression = result[3];
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, syntheticExpression);
    expect(syntheticExpression.isSynthetic, isTrue);
  }

  void test_functionExpression_in_ConstructorFieldInitializer() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(
        "class A { A() : a = (){}; var v; }",
        [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.UNEXPECTED_TOKEN]);
    // Make sure we recovered and parsed "var v" correctly
    ClassDeclaration declaration = unit.declarations[0] as ClassDeclaration;
    NodeList<ClassMember> members = declaration.members;
    ClassMember fieldDecl = members[1];
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FieldDeclaration, FieldDeclaration, fieldDecl);
    NodeList<VariableDeclaration> vars =
        (fieldDecl as FieldDeclaration).fields.variables;
    expect(vars, hasLength(1));
    expect(vars[0].name.name, "v");
  }

  void test_functionExpression_named() {
    parseExpression("m(f() => 0);", [ParserErrorCode.EXPECTED_TOKEN]);
  }

  void test_importDirectivePartial_as() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(
        "import 'b.dart' d as b;", [ParserErrorCode.UNEXPECTED_TOKEN]);
    ImportDirective importDirective = unit.childEntities.first;
    expect(importDirective.asKeyword, isNotNull);
    expect(unit.directives, hasLength(1));
    expect(unit.declarations, hasLength(0));
  }

  void test_importDirectivePartial_hide() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(
        "import 'b.dart' d hide foo;", [ParserErrorCode.UNEXPECTED_TOKEN]);
    ImportDirective importDirective = unit.childEntities.first;
    expect(importDirective.combinators, hasLength(1));
    expect(unit.directives, hasLength(1));
    expect(unit.declarations, hasLength(0));
  }

  void test_importDirectivePartial_show() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(
        "import 'b.dart' d show foo;", [ParserErrorCode.UNEXPECTED_TOKEN]);
    ImportDirective importDirective = unit.childEntities.first;
    expect(importDirective.combinators, hasLength(1));
    expect(unit.directives, hasLength(1));
    expect(unit.declarations, hasLength(0));
  }

  void test_incomplete_conditionalExpression() {
    parseExpression("x ? 0",
        [ParserErrorCode.EXPECTED_TOKEN, ParserErrorCode.MISSING_IDENTIFIER]);
  }

  void test_incomplete_constructorInitializers_empty() {
    createParser('C() : {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.MISSING_INITIALIZER]);
  }

  void test_incomplete_constructorInitializers_missingEquals() {
    createParser('C() : x(3) {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER]);
    expect(member, new isInstanceOf<ConstructorDeclaration>());
    NodeList<ConstructorInitializer> initializers =
        (member as ConstructorDeclaration).initializers;
    expect(initializers, hasLength(1));
    ConstructorInitializer initializer = initializers[0];
    expect(initializer, new isInstanceOf<ConstructorFieldInitializer>());
    Expression expression =
        (initializer as ConstructorFieldInitializer).expression;
    expect(expression, isNotNull);
    expect(expression, new isInstanceOf<ParenthesizedExpression>());
  }

  void test_incomplete_constructorInitializers_variable() {
    createParser('C() : x {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes(
        [ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER]);
  }

  @failingTest
  void test_incomplete_returnType() {
    ParserTestCase.parseCompilationUnit(r'''
Map<Symbol, convertStringToSymbolMap(Map<String, dynamic> map) {
  if (map == null) return null;
  Map<Symbol, dynamic> result = new Map<Symbol, dynamic>();
  map.forEach((name, value) {
    result[new Symbol(name)] = value;
  });
  return result;
}''');
  }

  void test_incomplete_topLevelFunction() {
    ParserTestCase.parseCompilationUnit(
        "foo();", [ParserErrorCode.MISSING_FUNCTION_BODY]);
  }

  void test_incomplete_topLevelVariable() {
    CompilationUnit unit = ParserTestCase
        .parseCompilationUnit("String", [ParserErrorCode.EXPECTED_EXECUTABLE]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember member = declarations[0];
    EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableDeclaration,
        TopLevelVariableDeclaration, member);
    NodeList<VariableDeclaration> variables =
        (member as TopLevelVariableDeclaration).variables.variables;
    expect(variables, hasLength(1));
    SimpleIdentifier name = variables[0].name;
    expect(name.isSynthetic, isTrue);
  }

  void test_incomplete_topLevelVariable_const() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("const ",
        [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember member = declarations[0];
    EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableDeclaration,
        TopLevelVariableDeclaration, member);
    NodeList<VariableDeclaration> variables =
        (member as TopLevelVariableDeclaration).variables.variables;
    expect(variables, hasLength(1));
    SimpleIdentifier name = variables[0].name;
    expect(name.isSynthetic, isTrue);
  }

  void test_incomplete_topLevelVariable_final() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("final ",
        [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember member = declarations[0];
    EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableDeclaration,
        TopLevelVariableDeclaration, member);
    NodeList<VariableDeclaration> variables =
        (member as TopLevelVariableDeclaration).variables.variables;
    expect(variables, hasLength(1));
    SimpleIdentifier name = variables[0].name;
    expect(name.isSynthetic, isTrue);
  }

  void test_incomplete_topLevelVariable_var() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("var ",
        [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember member = declarations[0];
    EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableDeclaration,
        TopLevelVariableDeclaration, member);
    NodeList<VariableDeclaration> variables =
        (member as TopLevelVariableDeclaration).variables.variables;
    expect(variables, hasLength(1));
    SimpleIdentifier name = variables[0].name;
    expect(name.isSynthetic, isTrue);
  }

  void test_incompleteField_const() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(
        r'''
class C {
  const
}''',
        [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember unitMember = declarations[0];
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassDeclaration, ClassDeclaration, unitMember);
    NodeList<ClassMember> members = (unitMember as ClassDeclaration).members;
    expect(members, hasLength(1));
    ClassMember classMember = members[0];
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FieldDeclaration, FieldDeclaration, classMember);
    VariableDeclarationList fieldList =
        (classMember as FieldDeclaration).fields;
    expect(fieldList.keyword.keyword, Keyword.CONST);
    NodeList<VariableDeclaration> fields = fieldList.variables;
    expect(fields, hasLength(1));
    VariableDeclaration field = fields[0];
    expect(field.name.isSynthetic, isTrue);
  }

  void test_incompleteField_final() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(
        r'''
class C {
  final
}''',
        [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember unitMember = declarations[0];
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassDeclaration, ClassDeclaration, unitMember);
    NodeList<ClassMember> members = (unitMember as ClassDeclaration).members;
    expect(members, hasLength(1));
    ClassMember classMember = members[0];
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FieldDeclaration, FieldDeclaration, classMember);
    VariableDeclarationList fieldList =
        (classMember as FieldDeclaration).fields;
    expect(fieldList.keyword.keyword, Keyword.FINAL);
    NodeList<VariableDeclaration> fields = fieldList.variables;
    expect(fields, hasLength(1));
    VariableDeclaration field = fields[0];
    expect(field.name.isSynthetic, isTrue);
  }

  void test_incompleteField_var() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(
        r'''
class C {
  var
}''',
        [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember unitMember = declarations[0];
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassDeclaration, ClassDeclaration, unitMember);
    NodeList<ClassMember> members = (unitMember as ClassDeclaration).members;
    expect(members, hasLength(1));
    ClassMember classMember = members[0];
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FieldDeclaration, FieldDeclaration, classMember);
    VariableDeclarationList fieldList =
        (classMember as FieldDeclaration).fields;
    expect(fieldList.keyword.keyword, Keyword.VAR);
    NodeList<VariableDeclaration> fields = fieldList.variables;
    expect(fields, hasLength(1));
    VariableDeclaration field = fields[0];
    expect(field.name.isSynthetic, isTrue);
  }

  void test_incompleteForEach() {
    ForStatement statement = ParserTestCase.parseStatement(
        'for (String item i) {}',
        [ParserErrorCode.EXPECTED_TOKEN, ParserErrorCode.EXPECTED_TOKEN]);
    expect(statement, new isInstanceOf<ForStatement>());
    expect(statement.toSource(), 'for (String item; i;) {}');
    expect(statement.leftSeparator, isNotNull);
    expect(statement.leftSeparator.type, TokenType.SEMICOLON);
    expect(statement.rightSeparator, isNotNull);
    expect(statement.rightSeparator.type, TokenType.SEMICOLON);
  }

  void test_incompleteLocalVariable_atTheEndOfBlock() {
    Statement statement = ParserTestCase
        .parseStatement('String v }', [ParserErrorCode.EXPECTED_TOKEN]);
    expect(statement, new isInstanceOf<VariableDeclarationStatement>());
    expect(statement.toSource(), 'String v;');
  }

  void test_incompleteLocalVariable_beforeIdentifier() {
    Statement statement = ParserTestCase.parseStatement(
        'String v String v2;', [ParserErrorCode.EXPECTED_TOKEN]);
    expect(statement, new isInstanceOf<VariableDeclarationStatement>());
    expect(statement.toSource(), 'String v;');
  }

  void test_incompleteLocalVariable_beforeKeyword() {
    Statement statement = ParserTestCase.parseStatement(
        'String v if (true) {}', [ParserErrorCode.EXPECTED_TOKEN]);
    expect(statement, new isInstanceOf<VariableDeclarationStatement>());
    expect(statement.toSource(), 'String v;');
  }

  void test_incompleteLocalVariable_beforeNextBlock() {
    Statement statement = ParserTestCase
        .parseStatement('String v {}', [ParserErrorCode.EXPECTED_TOKEN]);
    expect(statement, new isInstanceOf<VariableDeclarationStatement>());
    expect(statement.toSource(), 'String v;');
  }

  void test_incompleteLocalVariable_parameterizedType() {
    Statement statement = ParserTestCase
        .parseStatement('List<String> v {}', [ParserErrorCode.EXPECTED_TOKEN]);
    expect(statement, new isInstanceOf<VariableDeclarationStatement>());
    expect(statement.toSource(), 'List<String> v;');
  }

  void test_incompleteTypeArguments_field() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(
        r'''
class C {
  final List<int f;
}''',
        [ParserErrorCode.EXPECTED_TOKEN]);
    // one class
    List<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    ClassDeclaration classDecl = declarations[0] as ClassDeclaration;
    // one field declaration
    List<ClassMember> members = classDecl.members;
    expect(members, hasLength(1));
    FieldDeclaration fieldDecl = members[0] as FieldDeclaration;
    // one field
    VariableDeclarationList fieldList = fieldDecl.fields;
    List<VariableDeclaration> fields = fieldList.variables;
    expect(fields, hasLength(1));
    VariableDeclaration field = fields[0];
    expect(field.name.name, 'f');
    // validate the type
    TypeArgumentList typeArguments = fieldList.type.typeArguments;
    expect(typeArguments.arguments, hasLength(1));
    // synthetic '>'
    Token token = typeArguments.endToken;
    expect(token.type, TokenType.GT);
    expect(token.isSynthetic, isTrue);
  }

  void test_incompleteTypeParameters() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(
        r'''
class C<K {
}''',
        [ParserErrorCode.EXPECTED_TOKEN]);
    // one class
    List<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    ClassDeclaration classDecl = declarations[0] as ClassDeclaration;
    // validate the type parameters
    TypeParameterList typeParameters = classDecl.typeParameters;
    expect(typeParameters.typeParameters, hasLength(1));
    // synthetic '>'
    Token token = typeParameters.endToken;
    expect(token.type, TokenType.GT);
    expect(token.isSynthetic, isTrue);
  }

  void test_invalidFunctionBodyModifier() {
    ParserTestCase.parseCompilationUnit(
        "f() sync {}", [ParserErrorCode.MISSING_STAR_AFTER_SYNC]);
  }

  void test_isExpression_noType() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(
        "class Bar<T extends Foo> {m(x){if (x is ) return;if (x is !)}}", [
      ParserErrorCode.EXPECTED_TYPE_NAME,
      ParserErrorCode.EXPECTED_TYPE_NAME,
      ParserErrorCode.MISSING_STATEMENT
    ]);
    ClassDeclaration declaration = unit.declarations[0] as ClassDeclaration;
    MethodDeclaration method = declaration.members[0] as MethodDeclaration;
    BlockFunctionBody body = method.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[1] as IfStatement;
    IsExpression expression = ifStatement.condition as IsExpression;
    expect(expression.expression, isNotNull);
    expect(expression.isOperator, isNotNull);
    expect(expression.notOperator, isNotNull);
    TypeName type = expression.type;
    expect(type, isNotNull);
    expect(type.name.isSynthetic, isTrue);
    EngineTestCase.assertInstanceOf((obj) => obj is EmptyStatement,
        EmptyStatement, ifStatement.thenStatement);
  }

  void test_keywordInPlaceOfIdentifier() {
    // TODO(brianwilkerson) We could do better with this.
    ParserTestCase.parseCompilationUnit("do() {}", [
      ParserErrorCode.EXPECTED_EXECUTABLE,
      ParserErrorCode.UNEXPECTED_TOKEN
    ]);
  }

  void test_logicalAndExpression_missing_LHS() {
    BinaryExpression expression =
        parseExpression("&& y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_logicalAndExpression_missing_LHS_RHS() {
    BinaryExpression expression = parseExpression("&&", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_logicalAndExpression_missing_RHS() {
    BinaryExpression expression =
        parseExpression("x &&", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_logicalAndExpression_precedence_bitwiseOr_left() {
    BinaryExpression expression = parseExpression("| &&", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_logicalAndExpression_precedence_bitwiseOr_right() {
    BinaryExpression expression = parseExpression("&& |", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.rightOperand);
  }

  void test_logicalOrExpression_missing_LHS() {
    BinaryExpression expression =
        parseExpression("|| y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_logicalOrExpression_missing_LHS_RHS() {
    BinaryExpression expression = parseExpression("||", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_logicalOrExpression_missing_RHS() {
    BinaryExpression expression =
        parseExpression("x ||", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_logicalOrExpression_precedence_logicalAnd_left() {
    BinaryExpression expression = parseExpression("&& ||", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_logicalOrExpression_precedence_logicalAnd_right() {
    BinaryExpression expression = parseExpression("|| &&", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.rightOperand);
  }

  void test_missing_commaInArgumentList() {
    parseExpression("f(x: 1 y: 2)", [ParserErrorCode.EXPECTED_TOKEN]);
  }

  void test_missingGet() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(
        r'''
class C {
  int length {}
  void foo() {}
}''',
        [ParserErrorCode.MISSING_GET]);
    expect(unit, isNotNull);
    ClassDeclaration classDeclaration =
        unit.declarations[0] as ClassDeclaration;
    NodeList<ClassMember> members = classDeclaration.members;
    expect(members, hasLength(2));
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodDeclaration, MethodDeclaration, members[0]);
    ClassMember member = members[1];
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodDeclaration, MethodDeclaration, member);
    expect((member as MethodDeclaration).name.name, "foo");
  }

  void test_missingIdentifier_afterAnnotation() {
    createParser('@override }');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertErrorsWithCodes([ParserErrorCode.EXPECTED_CLASS_MEMBER]);
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    NodeList<Annotation> metadata = method.metadata;
    expect(metadata, hasLength(1));
    expect(metadata[0].name.name, "override");
  }

  void test_missingSemicolon_varialeDeclarationList() {
    void verify(CompilationUnitMember member, String expectedTypeName,
        String expectedName, String expectedSemicolon) {
      expect(member, new isInstanceOf<TopLevelVariableDeclaration>());
      TopLevelVariableDeclaration declaration = member;
      VariableDeclarationList variableList = declaration.variables;
      expect(variableList, isNotNull);
      NodeList<VariableDeclaration> variables = variableList.variables;
      expect(variables, hasLength(1));
      VariableDeclaration variable = variables[0];
      expect(variableList.type.toString(), expectedTypeName);
      expect(variable.name.name, expectedName);
      expect(declaration.semicolon.lexeme, expectedSemicolon);
    }

    CompilationUnit unit = ParserTestCase.parseCompilationUnit(
        'String n x = "";', [
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE
    ]);
    expect(unit, isNotNull);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(2));
    verify(declarations[0], 'String', 'n', '');
    verify(declarations[1], 'null', 'x', ';');
  }

  void test_multiplicativeExpression_missing_LHS() {
    BinaryExpression expression =
        parseExpression("* y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_multiplicativeExpression_missing_LHS_RHS() {
    BinaryExpression expression = parseExpression("*", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_multiplicativeExpression_missing_RHS() {
    BinaryExpression expression =
        parseExpression("x *", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_multiplicativeExpression_missing_RHS_super() {
    BinaryExpression expression =
        parseExpression("super *", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_multiplicativeExpression_precedence_unary_left() {
    BinaryExpression expression =
        parseExpression("-x *", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is PrefixExpression,
        PrefixExpression, expression.leftOperand);
  }

  void test_multiplicativeExpression_precedence_unary_right() {
    BinaryExpression expression =
        parseExpression("* -y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is PrefixExpression,
        PrefixExpression, expression.rightOperand);
  }

  void test_multiplicativeExpression_super() {
    BinaryExpression expression = parseExpression("super ==  ==", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_nonStringLiteralUri_import() {
    ParserTestCase.parseCompilationUnit("import dart:io; class C {}",
        [ParserErrorCode.NON_STRING_LITERAL_AS_URI]);
  }

  void test_prefixExpression_missing_operand_minus() {
    PrefixExpression expression =
        parseExpression("-", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.operand);
    expect(expression.operand.isSynthetic, isTrue);
    expect(expression.operator.type, TokenType.MINUS);
  }

  void test_primaryExpression_argumentDefinitionTest() {
    createParser('?a');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertErrorsWithCodes([ParserErrorCode.UNEXPECTED_TOKEN]);
    expect(expression, new isInstanceOf<SimpleIdentifier>());
  }

  void test_relationalExpression_missing_LHS() {
    IsExpression expression =
        parseExpression("is y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.expression);
    expect(expression.expression.isSynthetic, isTrue);
  }

  void test_relationalExpression_missing_LHS_RHS() {
    IsExpression expression = parseExpression("is", [
      ParserErrorCode.EXPECTED_TYPE_NAME,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.expression);
    expect(expression.expression.isSynthetic, isTrue);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is TypeName, TypeName, expression.type);
    expect(expression.type.isSynthetic, isTrue);
  }

  void test_relationalExpression_missing_RHS() {
    IsExpression expression =
        parseExpression("x is", [ParserErrorCode.EXPECTED_TYPE_NAME]);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is TypeName, TypeName, expression.type);
    expect(expression.type.isSynthetic, isTrue);
  }

  void test_relationalExpression_precedence_shift_right() {
    IsExpression expression = parseExpression("<< is", [
      ParserErrorCode.EXPECTED_TYPE_NAME,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.expression);
  }

  void test_shiftExpression_missing_LHS() {
    BinaryExpression expression =
        parseExpression("<< y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_shiftExpression_missing_LHS_RHS() {
    BinaryExpression expression = parseExpression("<<", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_shiftExpression_missing_RHS() {
    BinaryExpression expression =
        parseExpression("x <<", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_shiftExpression_missing_RHS_super() {
    BinaryExpression expression =
        parseExpression("super <<", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier,
        SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_shiftExpression_precedence_unary_left() {
    BinaryExpression expression = parseExpression("+ <<", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_shiftExpression_precedence_unary_right() {
    BinaryExpression expression = parseExpression("<< +", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.rightOperand);
  }

  void test_shiftExpression_super() {
    BinaryExpression expression = parseExpression("super << <<", [
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression,
        BinaryExpression, expression.leftOperand);
  }

  void test_typedef_eof() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("typedef n", [
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.MISSING_TYPEDEF_PARAMETERS
    ]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember member = declarations[0];
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionTypeAlias, FunctionTypeAlias, member);
  }

  void test_unaryPlus() {
    parseExpression("+2", [ParserErrorCode.MISSING_IDENTIFIER]);
  }
}

/**
 * The class `SimpleParserTest` defines parser tests that test individual parsing method. The
 * code fragments should be as minimal as possible in order to test the method, but should not test
 * the interactions between the method under test and other methods.
 *
 * More complex tests should be defined in the class [ComplexParserTest].
 */
@reflectiveTest
class SimpleParserTest extends ParserTestCase {
  void test_computeStringValue_emptyInterpolationPrefix() {
    expect(_computeStringValue("'''", true, false), "");
  }

  void test_computeStringValue_escape_b() {
    expect(_computeStringValue("'\\b'", true, true), "\b");
  }

  void test_computeStringValue_escape_f() {
    expect(_computeStringValue("'\\f'", true, true), "\f");
  }

  void test_computeStringValue_escape_n() {
    expect(_computeStringValue("'\\n'", true, true), "\n");
  }

  void test_computeStringValue_escape_notSpecial() {
    expect(_computeStringValue("'\\:'", true, true), ":");
  }

  void test_computeStringValue_escape_r() {
    expect(_computeStringValue("'\\r'", true, true), "\r");
  }

  void test_computeStringValue_escape_t() {
    expect(_computeStringValue("'\\t'", true, true), "\t");
  }

  void test_computeStringValue_escape_u_fixed() {
    expect(_computeStringValue("'\\u4321'", true, true), "\u4321");
  }

  void test_computeStringValue_escape_u_variable() {
    expect(_computeStringValue("'\\u{123}'", true, true), "\u0123");
  }

  void test_computeStringValue_escape_v() {
    expect(_computeStringValue("'\\v'", true, true), "\u000B");
  }

  void test_computeStringValue_escape_x() {
    expect(_computeStringValue("'\\xFF'", true, true), "\u00FF");
  }

  void test_computeStringValue_noEscape_single() {
    expect(_computeStringValue("'text'", true, true), "text");
  }

  void test_computeStringValue_noEscape_triple() {
    expect(_computeStringValue("'''text'''", true, true), "text");
  }

  void test_computeStringValue_raw_single() {
    expect(_computeStringValue("r'text'", true, true), "text");
  }

  void test_computeStringValue_raw_triple() {
    expect(_computeStringValue("r'''text'''", true, true), "text");
  }

  void test_computeStringValue_raw_withEscape() {
    expect(_computeStringValue("r'two\\nlines'", true, true), "two\\nlines");
  }

  void test_computeStringValue_triple_internalQuote_first_empty() {
    expect(_computeStringValue("''''", true, false), "'");
  }

  void test_computeStringValue_triple_internalQuote_first_nonEmpty() {
    expect(_computeStringValue("''''text", true, false), "'text");
  }

  void test_computeStringValue_triple_internalQuote_last_empty() {
    expect(_computeStringValue("'''", false, true), "");
  }

  void test_computeStringValue_triple_internalQuote_last_nonEmpty() {
    expect(_computeStringValue("text'''", false, true), "text");
  }

  void test_constFactory() {
    createParser('const factory C() = A;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
  }

  void test_createSyntheticIdentifier() {
    createParser('');
    SimpleIdentifier identifier = parser.createSyntheticIdentifier();
    expectNotNullIfNoErrors(identifier);
    expect(identifier.isSynthetic, isTrue);
  }

  void test_createSyntheticStringLiteral() {
    createParser('');
    SimpleStringLiteral literal = parser.createSyntheticStringLiteral();
    expectNotNullIfNoErrors(literal);
    expect(literal.isSynthetic, isTrue);
  }

  void test_function_literal_allowed_at_toplevel() {
    ParserTestCase.parseCompilationUnit("var x = () {};");
  }

  void
      test_function_literal_allowed_in_ArgumentList_in_ConstructorFieldInitializer() {
    ParserTestCase.parseCompilationUnit("class C { C() : a = f(() {}); }");
  }

  void
      test_function_literal_allowed_in_IndexExpression_in_ConstructorFieldInitializer() {
    ParserTestCase.parseCompilationUnit("class C { C() : a = x[() {}]; }");
  }

  void
      test_function_literal_allowed_in_ListLiteral_in_ConstructorFieldInitializer() {
    ParserTestCase.parseCompilationUnit("class C { C() : a = [() {}]; }");
  }

  void
      test_function_literal_allowed_in_MapLiteral_in_ConstructorFieldInitializer() {
    ParserTestCase
        .parseCompilationUnit("class C { C() : a = {'key': () {}}; }");
  }

  void
      test_function_literal_allowed_in_ParenthesizedExpression_in_ConstructorFieldInitializer() {
    ParserTestCase.parseCompilationUnit("class C { C() : a = (() {}); }");
  }

  void
      test_function_literal_allowed_in_StringInterpolation_in_ConstructorFieldInitializer() {
    ParserTestCase.parseCompilationUnit("class C { C() : a = \"\${(){}}\"; }");
  }

  void test_import_as_show() {
    ParserTestCase.parseCompilationUnit("import 'dart:math' as M show E;");
  }

  void test_import_show_hide() {
    ParserTestCase.parseCompilationUnit(
        "import 'import1_lib.dart' show hide, show hide ugly;");
  }

  void test_isFunctionDeclaration_nameButNoReturn_block() {
    expect(_isFunctionDeclaration("f() {}"), isTrue);
  }

  void test_isFunctionDeclaration_nameButNoReturn_expression() {
    expect(_isFunctionDeclaration("f() => e"), isTrue);
  }

  void test_isFunctionDeclaration_nameButNoReturn_typeParameters_block() {
    expect(_isFunctionDeclaration("f<E>() {}"), isTrue);
  }

  void test_isFunctionDeclaration_nameButNoReturn_typeParameters_expression() {
    expect(_isFunctionDeclaration("f<E>() => e"), isTrue);
  }

  void test_isFunctionDeclaration_normalReturn_block() {
    expect(_isFunctionDeclaration("C f() {}"), isTrue);
  }

  void test_isFunctionDeclaration_normalReturn_expression() {
    expect(_isFunctionDeclaration("C f() => e"), isTrue);
  }

  void test_isFunctionDeclaration_normalReturn_typeParameters_block() {
    expect(_isFunctionDeclaration("C f<E>() {}"), isTrue);
  }

  void test_isFunctionDeclaration_normalReturn_typeParameters_expression() {
    expect(_isFunctionDeclaration("C f<E>() => e"), isTrue);
  }

  void test_isFunctionDeclaration_voidReturn_block() {
    expect(_isFunctionDeclaration("void f() {}"), isTrue);
  }

  void test_isFunctionDeclaration_voidReturn_expression() {
    expect(_isFunctionDeclaration("void f() => e"), isTrue);
  }

  void test_isFunctionDeclaration_voidReturn_typeParameters_block() {
    expect(_isFunctionDeclaration("void f<E>() {}"), isTrue);
  }

  void test_isFunctionDeclaration_voidReturn_typeParameters_expression() {
    expect(_isFunctionDeclaration("void f<E>() => e"), isTrue);
  }

  void test_isFunctionExpression_false_noBody() {
    expect(_isFunctionExpression("f();"), isFalse);
  }

  void test_isFunctionExpression_false_notParameters() {
    expect(_isFunctionExpression("(a + b) {"), isFalse);
  }

  void test_isFunctionExpression_noParameters_block() {
    expect(_isFunctionExpression("() {}"), isTrue);
  }

  void test_isFunctionExpression_noParameters_expression() {
    expect(_isFunctionExpression("() => e"), isTrue);
  }

  void test_isFunctionExpression_noParameters_typeParameters_block() {
    expect(_isFunctionExpression("<E>() {}"), isTrue);
  }

  void test_isFunctionExpression_noParameters_typeParameters_expression() {
    expect(_isFunctionExpression("<E>() => e"), isTrue);
  }

  void test_isFunctionExpression_parameter_final() {
    expect(_isFunctionExpression("(final a) {}"), isTrue);
    expect(_isFunctionExpression("(final a, b) {}"), isTrue);
    expect(_isFunctionExpression("(final a, final b) {}"), isTrue);
  }

  void test_isFunctionExpression_parameter_final_typed() {
    expect(_isFunctionExpression("(final int a) {}"), isTrue);
    expect(_isFunctionExpression("(final prefix.List a) {}"), isTrue);
    expect(_isFunctionExpression("(final List<int> a) {}"), isTrue);
    expect(_isFunctionExpression("(final prefix.List<int> a) {}"), isTrue);
  }

  void test_isFunctionExpression_parameter_multiple() {
    expect(_isFunctionExpression("(a, b) {}"), isTrue);
  }

  void test_isFunctionExpression_parameter_named() {
    expect(_isFunctionExpression("({a}) {}"), isTrue);
  }

  void test_isFunctionExpression_parameter_optional() {
    expect(_isFunctionExpression("([a]) {}"), isTrue);
  }

  void test_isFunctionExpression_parameter_single() {
    expect(_isFunctionExpression("(a) {}"), isTrue);
  }

  void test_isFunctionExpression_parameter_typed() {
    expect(_isFunctionExpression("(int a, int b) {}"), isTrue);
  }

  void test_isInitializedVariableDeclaration_assignment() {
    expect(_isInitializedVariableDeclaration("a = null;"), isFalse);
  }

  void test_isInitializedVariableDeclaration_comparison() {
    expect(_isInitializedVariableDeclaration("a < 0;"), isFalse);
  }

  void test_isInitializedVariableDeclaration_conditional() {
    expect(_isInitializedVariableDeclaration("a == null ? init() : update();"),
        isFalse);
  }

  void test_isInitializedVariableDeclaration_const_noType_initialized() {
    expect(_isInitializedVariableDeclaration("const a = 0;"), isTrue);
  }

  void test_isInitializedVariableDeclaration_const_noType_uninitialized() {
    expect(_isInitializedVariableDeclaration("const a;"), isTrue);
  }

  void test_isInitializedVariableDeclaration_const_simpleType_uninitialized() {
    expect(_isInitializedVariableDeclaration("const A a;"), isTrue);
  }

  void test_isInitializedVariableDeclaration_final_noType_initialized() {
    expect(_isInitializedVariableDeclaration("final a = 0;"), isTrue);
  }

  void test_isInitializedVariableDeclaration_final_noType_uninitialized() {
    expect(_isInitializedVariableDeclaration("final a;"), isTrue);
  }

  void test_isInitializedVariableDeclaration_final_simpleType_initialized() {
    expect(_isInitializedVariableDeclaration("final A a = 0;"), isTrue);
  }

  void test_isInitializedVariableDeclaration_functionDeclaration_typed() {
    expect(_isInitializedVariableDeclaration("A f() {};"), isFalse);
  }

  void test_isInitializedVariableDeclaration_functionDeclaration_untyped() {
    expect(_isInitializedVariableDeclaration("f() {};"), isFalse);
  }

  void test_isInitializedVariableDeclaration_noType_initialized() {
    expect(_isInitializedVariableDeclaration("var a = 0;"), isTrue);
  }

  void test_isInitializedVariableDeclaration_noType_uninitialized() {
    expect(_isInitializedVariableDeclaration("var a;"), isTrue);
  }

  void test_isInitializedVariableDeclaration_parameterizedType_initialized() {
    expect(_isInitializedVariableDeclaration("List<int> a = null;"), isTrue);
  }

  void test_isInitializedVariableDeclaration_parameterizedType_uninitialized() {
    expect(_isInitializedVariableDeclaration("List<int> a;"), isTrue);
  }

  void test_isInitializedVariableDeclaration_simpleType_initialized() {
    expect(_isInitializedVariableDeclaration("A a = 0;"), isTrue);
  }

  void test_isInitializedVariableDeclaration_simpleType_uninitialized() {
    expect(_isInitializedVariableDeclaration("A a;"), isTrue);
  }

  void test_isSwitchMember_case_labeled() {
    expect(_isSwitchMember("l1: l2: case"), isTrue);
  }

  void test_isSwitchMember_case_unlabeled() {
    expect(_isSwitchMember("case"), isTrue);
  }

  void test_isSwitchMember_default_labeled() {
    expect(_isSwitchMember("l1: l2: default"), isTrue);
  }

  void test_isSwitchMember_default_unlabeled() {
    expect(_isSwitchMember("default"), isTrue);
  }

  void test_isSwitchMember_false() {
    expect(_isSwitchMember("break;"), isFalse);
  }

  void test_parseAdditiveExpression_normal() {
    createParser('x + y');
    Expression expression = parser.parseAdditiveExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<BinaryExpression>());
    BinaryExpression binaryExpression = expression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.PLUS);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseAdditiveExpression_super() {
    createParser('super + y');
    Expression expression = parser.parseAdditiveExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<BinaryExpression>());
    BinaryExpression binaryExpression = expression;
    expect(binaryExpression.leftOperand, new isInstanceOf<SuperExpression>());
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.PLUS);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseAnnotation_n1() {
    createParser('@A');
    Annotation annotation = parser.parseAnnotation();
    expectNotNullIfNoErrors(annotation);
    listener.assertNoErrors();
    expect(annotation.atSign, isNotNull);
    expect(annotation.name, isNotNull);
    expect(annotation.period, isNull);
    expect(annotation.constructorName, isNull);
    expect(annotation.arguments, isNull);
  }

  void test_parseAnnotation_n1_a() {
    createParser('@A(x,y)');
    Annotation annotation = parser.parseAnnotation();
    expectNotNullIfNoErrors(annotation);
    listener.assertNoErrors();
    expect(annotation.atSign, isNotNull);
    expect(annotation.name, isNotNull);
    expect(annotation.period, isNull);
    expect(annotation.constructorName, isNull);
    expect(annotation.arguments, isNotNull);
  }

  void test_parseAnnotation_n2() {
    createParser('@A.B');
    Annotation annotation = parser.parseAnnotation();
    expectNotNullIfNoErrors(annotation);
    listener.assertNoErrors();
    expect(annotation.atSign, isNotNull);
    expect(annotation.name, isNotNull);
    expect(annotation.period, isNull);
    expect(annotation.constructorName, isNull);
    expect(annotation.arguments, isNull);
  }

  void test_parseAnnotation_n2_a() {
    createParser('@A.B(x,y)');
    Annotation annotation = parser.parseAnnotation();
    expectNotNullIfNoErrors(annotation);
    listener.assertNoErrors();
    expect(annotation.atSign, isNotNull);
    expect(annotation.name, isNotNull);
    expect(annotation.period, isNull);
    expect(annotation.constructorName, isNull);
    expect(annotation.arguments, isNotNull);
  }

  void test_parseAnnotation_n3() {
    createParser('@A.B.C');
    Annotation annotation = parser.parseAnnotation();
    expectNotNullIfNoErrors(annotation);
    listener.assertNoErrors();
    expect(annotation.atSign, isNotNull);
    expect(annotation.name, isNotNull);
    expect(annotation.period, isNotNull);
    expect(annotation.constructorName, isNotNull);
    expect(annotation.arguments, isNull);
  }

  void test_parseAnnotation_n3_a() {
    createParser('@A.B.C(x,y)');
    Annotation annotation = parser.parseAnnotation();
    expectNotNullIfNoErrors(annotation);
    listener.assertNoErrors();
    expect(annotation.atSign, isNotNull);
    expect(annotation.name, isNotNull);
    expect(annotation.period, isNotNull);
    expect(annotation.constructorName, isNotNull);
    expect(annotation.arguments, isNotNull);
  }

  void test_parseArgument_named() {
    createParser('n: x');
    Expression expression = parser.parseArgument();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<NamedExpression>());
    NamedExpression namedExpression = expression;
    Label name = namedExpression.name;
    expect(name, isNotNull);
    expect(name.label, isNotNull);
    expect(name.colon, isNotNull);
    expect(namedExpression.expression, isNotNull);
  }

  void test_parseArgument_unnamed() {
    String lexeme = "x";
    createParser(lexeme);
    Expression expression = parser.parseArgument();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<SimpleIdentifier>());
    SimpleIdentifier identifier = expression;
    expect(identifier.name, lexeme);
  }

  void test_parseArgumentList_empty() {
    createParser('()');
    ArgumentList argumentList = parser.parseArgumentList();
    expectNotNullIfNoErrors(argumentList);
    listener.assertNoErrors();
    NodeList<Expression> arguments = argumentList.arguments;
    expect(arguments, hasLength(0));
  }

  void test_parseArgumentList_mixed() {
    createParser('(w, x, y: y, z: z)');
    ArgumentList argumentList = parser.parseArgumentList();
    expectNotNullIfNoErrors(argumentList);
    listener.assertNoErrors();
    NodeList<Expression> arguments = argumentList.arguments;
    expect(arguments, hasLength(4));
  }

  void test_parseArgumentList_noNamed() {
    createParser('(x, y, z)');
    ArgumentList argumentList = parser.parseArgumentList();
    expectNotNullIfNoErrors(argumentList);
    listener.assertNoErrors();
    NodeList<Expression> arguments = argumentList.arguments;
    expect(arguments, hasLength(3));
  }

  void test_parseArgumentList_onlyNamed() {
    createParser('(x: x, y: y)');
    ArgumentList argumentList = parser.parseArgumentList();
    expectNotNullIfNoErrors(argumentList);
    listener.assertNoErrors();
    NodeList<Expression> arguments = argumentList.arguments;
    expect(arguments, hasLength(2));
  }

  void test_parseArgumentList_trailing_comma() {
    createParser('(x, y, z,)');
    ArgumentList argumentList = parser.parseArgumentList();
    expectNotNullIfNoErrors(argumentList);
    listener.assertNoErrors();
    NodeList<Expression> arguments = argumentList.arguments;
    expect(arguments, hasLength(3));
  }

  void test_parseAssertStatement() {
    createParser('assert (x);');
    AssertStatement statement = parser.parseAssertStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.assertKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.comma, isNull);
    expect(statement.message, isNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseAssertStatement_messageLowPrecedence() {
    // Using a throw expression as an assert message would be silly in
    // practice, but it's the lowest precedence expression type, so verifying
    // that it works should give us high confidence that other expression types
    // will work as well.
    createParser('assert (x, throw "foo");');
    AssertStatement statement = parser.parseAssertStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.assertKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.comma, isNotNull);
    expect(statement.message, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseAssertStatement_messageString() {
    createParser('assert (x, "foo");');
    AssertStatement statement = parser.parseAssertStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.assertKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.comma, isNotNull);
    expect(statement.message, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseAssignableExpression_expression_args_dot() {
    createParser('(x)(y).z');
    Expression expression = parser.parseAssignableExpression(false);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<PropertyAccess>());
    PropertyAccess propertyAccess = expression;
    FunctionExpressionInvocation invocation =
        propertyAccess.target as FunctionExpressionInvocation;
    expect(invocation.function, isNotNull);
    expect(invocation.typeArguments, isNull);
    ArgumentList argumentList = invocation.argumentList;
    expect(argumentList, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void
      test_parseAssignableExpression_expression_args_dot_typeParameterComments() {
    enableGenericMethodComments = true;
    createParser('(x)/*<F>*/(y).z');
    Expression expression = parser.parseAssignableExpression(false);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<PropertyAccess>());
    PropertyAccess propertyAccess = expression;
    FunctionExpressionInvocation invocation =
        propertyAccess.target as FunctionExpressionInvocation;
    expect(invocation.function, isNotNull);
    expect(invocation.typeArguments, isNotNull);
    ArgumentList argumentList = invocation.argumentList;
    expect(argumentList, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_expression_args_dot_typeParameters() {
    createParser('(x)<F>(y).z');
    Expression expression = parser.parseAssignableExpression(false);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<PropertyAccess>());
    PropertyAccess propertyAccess = expression;
    FunctionExpressionInvocation invocation =
        propertyAccess.target as FunctionExpressionInvocation;
    expect(invocation.function, isNotNull);
    expect(invocation.typeArguments, isNotNull);
    ArgumentList argumentList = invocation.argumentList;
    expect(argumentList, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_expression_dot() {
    createParser('(x).y');
    Expression expression = parser.parseAssignableExpression(false);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<PropertyAccess>());
    PropertyAccess propertyAccess = expression;
    expect(propertyAccess.target, isNotNull);
    expect(propertyAccess.operator.type, TokenType.PERIOD);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_expression_index() {
    createParser('(x)[y]');
    Expression expression = parser.parseAssignableExpression(false);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<IndexExpression>());
    IndexExpression indexExpression = expression;
    expect(indexExpression.target, isNotNull);
    expect(indexExpression.leftBracket, isNotNull);
    expect(indexExpression.index, isNotNull);
    expect(indexExpression.rightBracket, isNotNull);
  }

  void test_parseAssignableExpression_expression_question_dot() {
    createParser('(x)?.y');
    Expression expression = parser.parseAssignableExpression(false);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<PropertyAccess>());
    PropertyAccess propertyAccess = expression;
    expect(propertyAccess.target, isNotNull);
    expect(propertyAccess.operator.type, TokenType.QUESTION_PERIOD);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_identifier() {
    createParser('x');
    Expression expression = parser.parseAssignableExpression(false);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<SimpleIdentifier>());
    SimpleIdentifier identifier = expression;
    expect(identifier, isNotNull);
  }

  void test_parseAssignableExpression_identifier_args_dot() {
    createParser('x(y).z');
    Expression expression = parser.parseAssignableExpression(false);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<PropertyAccess>());
    PropertyAccess propertyAccess = expression;
    MethodInvocation invocation = propertyAccess.target as MethodInvocation;
    expect(invocation.methodName.name, "x");
    expect(invocation.typeArguments, isNull);
    ArgumentList argumentList = invocation.argumentList;
    expect(argumentList, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void
      test_parseAssignableExpression_identifier_args_dot_typeParameterComments() {
    enableGenericMethodComments = true;
    createParser('x/*<E>*/(y).z');
    Expression expression = parser.parseAssignableExpression(false);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<PropertyAccess>());
    PropertyAccess propertyAccess = expression;
    MethodInvocation invocation = propertyAccess.target as MethodInvocation;
    expect(invocation.methodName.name, "x");
    expect(invocation.typeArguments, isNotNull);
    ArgumentList argumentList = invocation.argumentList;
    expect(argumentList, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_identifier_args_dot_typeParameters() {
    createParser('x<E>(y).z');
    Expression expression = parser.parseAssignableExpression(false);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<PropertyAccess>());
    PropertyAccess propertyAccess = expression;
    MethodInvocation invocation = propertyAccess.target as MethodInvocation;
    expect(invocation.methodName.name, "x");
    expect(invocation.typeArguments, isNotNull);
    ArgumentList argumentList = invocation.argumentList;
    expect(argumentList, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_identifier_dot() {
    createParser('x.y');
    Expression expression = parser.parseAssignableExpression(false);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<PropertyAccess>());
    PropertyAccess propertyAccess = expression;
    expect(propertyAccess.target, isNotNull);
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.operator.type, TokenType.PERIOD);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_identifier_index() {
    createParser('x[y]');
    Expression expression = parser.parseAssignableExpression(false);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<IndexExpression>());
    IndexExpression indexExpression = expression;
    expect(indexExpression.target, isNotNull);
    expect(indexExpression.leftBracket, isNotNull);
    expect(indexExpression.index, isNotNull);
    expect(indexExpression.rightBracket, isNotNull);
  }

  void test_parseAssignableExpression_identifier_question_dot() {
    createParser('x?.y');
    Expression expression = parser.parseAssignableExpression(false);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<PropertyAccess>());
    PropertyAccess propertyAccess = expression;
    expect(propertyAccess.target, isNotNull);
    expect(propertyAccess.operator.type, TokenType.QUESTION_PERIOD);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_super_dot() {
    createParser('super.y');
    Expression expression = parser.parseAssignableExpression(false);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<PropertyAccess>());
    PropertyAccess propertyAccess = expression;
    EngineTestCase.assertInstanceOf((obj) => obj is SuperExpression,
        SuperExpression, propertyAccess.target);
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_super_index() {
    createParser('super[y]');
    Expression expression = parser.parseAssignableExpression(false);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<IndexExpression>());
    IndexExpression indexExpression = expression;
    expect(indexExpression.target, new isInstanceOf<SuperExpression>());
    expect(indexExpression.leftBracket, isNotNull);
    expect(indexExpression.index, isNotNull);
    expect(indexExpression.rightBracket, isNotNull);
  }

  void test_parseAssignableSelector_dot() {
    createParser('.x');
    Expression expression = parser.parseAssignableSelector(null, true);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<PropertyAccess>());
    PropertyAccess propertyAccess = expression;
    expect(propertyAccess.operator.type, TokenType.PERIOD);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableSelector_index() {
    createParser('[x]');
    Expression expression = parser.parseAssignableSelector(null, true);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<IndexExpression>());
    IndexExpression indexExpression = expression;
    expect(indexExpression.leftBracket, isNotNull);
    expect(indexExpression.index, isNotNull);
    expect(indexExpression.rightBracket, isNotNull);
  }

  void test_parseAssignableSelector_none() {
    createParser(';');
    Expression expression =
        parser.parseAssignableSelector(new SimpleIdentifier(null), true);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<SimpleIdentifier>());
    SimpleIdentifier identifier = expression;
    expect(identifier, isNotNull);
  }

  void test_parseAssignableSelector_question_dot() {
    createParser('?.x');
    Expression expression = parser.parseAssignableSelector(null, true);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<PropertyAccess>());
    PropertyAccess propertyAccess = expression;
    expect(propertyAccess.operator.type, TokenType.QUESTION_PERIOD);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAwaitExpression() {
    createParser('await x;');
    AwaitExpression expression = parser.parseAwaitExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.awaitKeyword, isNotNull);
    expect(expression.expression, isNotNull);
  }

  void test_parseAwaitExpression_asStatement_inAsync() {
    createParser('m() async { await x; }');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    FunctionBody body = method.body;
    EngineTestCase.assertInstanceOf(
        (obj) => obj is BlockFunctionBody, BlockFunctionBody, body);
    Statement statement = (body as BlockFunctionBody).block.statements[0];
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ExpressionStatement, ExpressionStatement, statement);
    Expression expression = (statement as ExpressionStatement).expression;
    EngineTestCase.assertInstanceOf(
        (obj) => obj is AwaitExpression, AwaitExpression, expression);
    expect((expression as AwaitExpression).awaitKeyword, isNotNull);
    expect((expression as AwaitExpression).expression, isNotNull);
  }

  void test_parseAwaitExpression_asStatement_inSync() {
    createParser('m() { await x; }');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    FunctionBody body = method.body;
    EngineTestCase.assertInstanceOf(
        (obj) => obj is BlockFunctionBody, BlockFunctionBody, body);
    Statement statement = (body as BlockFunctionBody).block.statements[0];
    EngineTestCase.assertInstanceOf(
        (obj) => obj is VariableDeclarationStatement,
        VariableDeclarationStatement,
        statement);
  }

  @failingTest
  void test_parseAwaitExpression_inSync() {
    // This test requires better error recovery than we currently have. In
    // particular, we need to be able to distinguish between an await expression
    // in the wrong context, and the use of 'await' as an identifier.
    createParser('m() { return await x + await y; }');
    MethodDeclaration method = parser.parseClassMember('C');
    expectNotNullIfNoErrors(method);
    listener.assertNoErrors();
    FunctionBody body = method.body;
    EngineTestCase.assertInstanceOf(
        (obj) => obj is BlockFunctionBody, BlockFunctionBody, body);
    Statement statement = (body as BlockFunctionBody).block.statements[0];
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ReturnStatement, ReturnStatement, statement);
    Expression expression = (statement as ReturnStatement).expression;
    EngineTestCase.assertInstanceOf(
        (obj) => obj is BinaryExpression, BinaryExpression, expression);
    EngineTestCase.assertInstanceOf((obj) => obj is AwaitExpression,
        AwaitExpression, (expression as BinaryExpression).leftOperand);
    EngineTestCase.assertInstanceOf((obj) => obj is AwaitExpression,
        AwaitExpression, (expression as BinaryExpression).rightOperand);
  }

  void test_parseBitwiseAndExpression_normal() {
    createParser('x & y');
    Expression expression = parser.parseBitwiseAndExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<BinaryExpression>());
    BinaryExpression binaryExpression = expression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.AMPERSAND);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseBitwiseAndExpression_super() {
    createParser('super & y');
    Expression expression = parser.parseBitwiseAndExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<BinaryExpression>());
    BinaryExpression binaryExpression = expression;
    expect(binaryExpression.leftOperand, new isInstanceOf<SuperExpression>());
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.AMPERSAND);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseBitwiseOrExpression_normal() {
    createParser('x | y');
    Expression expression = parser.parseBitwiseOrExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<BinaryExpression>());
    BinaryExpression binaryExpression = expression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.BAR);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseBitwiseOrExpression_super() {
    createParser('super | y');
    Expression expression = parser.parseBitwiseOrExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<BinaryExpression>());
    BinaryExpression binaryExpression = expression;
    expect(binaryExpression.leftOperand, new isInstanceOf<SuperExpression>());
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.BAR);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseBitwiseXorExpression_normal() {
    createParser('x ^ y');
    Expression expression = parser.parseBitwiseXorExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<BinaryExpression>());
    BinaryExpression binaryExpression = expression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.CARET);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseBitwiseXorExpression_super() {
    createParser('super ^ y');
    Expression expression = parser.parseBitwiseXorExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<BinaryExpression>());
    BinaryExpression binaryExpression = expression;
    expect(binaryExpression.leftOperand, new isInstanceOf<SuperExpression>());
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.CARET);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseBlock_empty() {
    createParser('{}');
    Block block = parser.parseBlock();
    expectNotNullIfNoErrors(block);
    listener.assertNoErrors();
    expect(block.leftBracket, isNotNull);
    expect(block.statements, hasLength(0));
    expect(block.rightBracket, isNotNull);
  }

  void test_parseBlock_nonEmpty() {
    createParser('{;}');
    Block block = parser.parseBlock();
    expectNotNullIfNoErrors(block);
    listener.assertNoErrors();
    expect(block.leftBracket, isNotNull);
    expect(block.statements, hasLength(1));
    expect(block.rightBracket, isNotNull);
  }

  void test_parseBreakStatement_label() {
    createParser('break foo;');
    BreakStatement statement = parser.parseBreakStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.breakKeyword, isNotNull);
    expect(statement.label, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseBreakStatement_noLabel() {
    createParser('break;');
    BreakStatement statement = parser.parseBreakStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertErrorsWithCodes([ParserErrorCode.BREAK_OUTSIDE_OF_LOOP]);
    expect(statement.breakKeyword, isNotNull);
    expect(statement.label, isNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseCascadeSection_i() {
    createParser('..[i]');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<IndexExpression>());
    IndexExpression section = expression;
    expect(section.target, isNull);
    expect(section.leftBracket, isNotNull);
    expect(section.index, isNotNull);
    expect(section.rightBracket, isNotNull);
  }

  void test_parseCascadeSection_ia() {
    createParser('..[i](b)');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<FunctionExpressionInvocation>());
    FunctionExpressionInvocation section = expression;
    expect(section.function, new isInstanceOf<IndexExpression>());
    expect(section.typeArguments, isNull);
    expect(section.argumentList, isNotNull);
  }

  void test_parseCascadeSection_ia_typeArgumentComments() {
    enableGenericMethodComments = true;
    createParser('..[i]/*<E>*/(b)');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<FunctionExpressionInvocation>());
    FunctionExpressionInvocation section = expression;
    expect(section.function, new isInstanceOf<IndexExpression>());
    expect(section.typeArguments, isNotNull);
    expect(section.argumentList, isNotNull);
  }

  void test_parseCascadeSection_ia_typeArguments() {
    createParser('..[i]<E>(b)');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<FunctionExpressionInvocation>());
    FunctionExpressionInvocation section = expression;
    expect(section.function, new isInstanceOf<IndexExpression>());
    expect(section.typeArguments, isNotNull);
    expect(section.argumentList, isNotNull);
  }

  void test_parseCascadeSection_ii() {
    createParser('..a(b).c(d)');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<MethodInvocation>());
    MethodInvocation section = expression;
    expect(section.target, new isInstanceOf<MethodInvocation>());
    expect(section.operator, isNotNull);
    expect(section.methodName, isNotNull);
    expect(section.typeArguments, isNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_ii_typeArgumentComments() {
    enableGenericMethodComments = true;
    createParser('..a/*<E>*/(b).c/*<F>*/(d)');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<MethodInvocation>());
    MethodInvocation section = expression;
    expect(section.target, new isInstanceOf<MethodInvocation>());
    expect(section.operator, isNotNull);
    expect(section.methodName, isNotNull);
    expect(section.typeArguments, isNotNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_ii_typeArguments() {
    createParser('..a<E>(b).c<F>(d)');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<MethodInvocation>());
    MethodInvocation section = expression;
    expect(section.target, new isInstanceOf<MethodInvocation>());
    expect(section.operator, isNotNull);
    expect(section.methodName, isNotNull);
    expect(section.typeArguments, isNotNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_p() {
    createParser('..a');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<PropertyAccess>());
    PropertyAccess section = expression;
    expect(section.target, isNull);
    expect(section.operator, isNotNull);
    expect(section.propertyName, isNotNull);
  }

  void test_parseCascadeSection_p_assign() {
    createParser('..a = 3');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<AssignmentExpression>());
    AssignmentExpression section = expression;
    expect(section.leftHandSide, isNotNull);
    expect(section.operator, isNotNull);
    Expression rhs = section.rightHandSide;
    expect(rhs, isNotNull);
  }

  void test_parseCascadeSection_p_assign_withCascade() {
    createParser('..a = 3..m()');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<AssignmentExpression>());
    AssignmentExpression section = expression;
    expect(section.leftHandSide, isNotNull);
    expect(section.operator, isNotNull);
    Expression rhs = section.rightHandSide;
    EngineTestCase.assertInstanceOf(
        (obj) => obj is IntegerLiteral, IntegerLiteral, rhs);
  }

  void test_parseCascadeSection_p_assign_withCascade_typeArgumentComments() {
    enableGenericMethodComments = true;
    createParser('..a = 3..m/*<E>*/()');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<AssignmentExpression>());
    AssignmentExpression section = expression;
    expect(section.leftHandSide, isNotNull);
    expect(section.operator, isNotNull);
    Expression rhs = section.rightHandSide;
    EngineTestCase.assertInstanceOf(
        (obj) => obj is IntegerLiteral, IntegerLiteral, rhs);
  }

  void test_parseCascadeSection_p_assign_withCascade_typeArguments() {
    createParser('..a = 3..m<E>()');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<AssignmentExpression>());
    AssignmentExpression section = expression;
    expect(section.leftHandSide, isNotNull);
    expect(section.operator, isNotNull);
    Expression rhs = section.rightHandSide;
    EngineTestCase.assertInstanceOf(
        (obj) => obj is IntegerLiteral, IntegerLiteral, rhs);
  }

  void test_parseCascadeSection_p_builtIn() {
    createParser('..as');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<PropertyAccess>());
    PropertyAccess section = expression;
    expect(section.target, isNull);
    expect(section.operator, isNotNull);
    expect(section.propertyName, isNotNull);
  }

  void test_parseCascadeSection_pa() {
    createParser('..a(b)');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<MethodInvocation>());
    MethodInvocation section = expression;
    expect(section.target, isNull);
    expect(section.operator, isNotNull);
    expect(section.methodName, isNotNull);
    expect(section.typeArguments, isNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_pa_typeArgumentComments() {
    enableGenericMethodComments = true;
    createParser('..a/*<E>*/(b)');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<MethodInvocation>());
    MethodInvocation section = expression;
    expect(section.target, isNull);
    expect(section.operator, isNotNull);
    expect(section.methodName, isNotNull);
    expect(section.typeArguments, isNotNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_pa_typeArguments() {
    createParser('..a<E>(b)');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<MethodInvocation>());
    MethodInvocation section = expression;
    expect(section.target, isNull);
    expect(section.operator, isNotNull);
    expect(section.methodName, isNotNull);
    expect(section.typeArguments, isNotNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_paa() {
    createParser('..a(b)(c)');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<FunctionExpressionInvocation>());
    FunctionExpressionInvocation section = expression;
    expect(section.function, new isInstanceOf<MethodInvocation>());
    expect(section.typeArguments, isNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_paa_typeArgumentComments() {
    enableGenericMethodComments = true;
    createParser('..a/*<E>*/(b)/*<F>*/(c)');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<FunctionExpressionInvocation>());
    FunctionExpressionInvocation section = expression;
    expect(section.function, new isInstanceOf<MethodInvocation>());
    expect(section.typeArguments, isNotNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_paa_typeArguments() {
    createParser('..a<E>(b)<F>(c)');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<FunctionExpressionInvocation>());
    FunctionExpressionInvocation section = expression;
    expect(section.function, new isInstanceOf<MethodInvocation>());
    expect(section.typeArguments, isNotNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_paapaa() {
    createParser('..a(b)(c).d(e)(f)');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<FunctionExpressionInvocation>());
    FunctionExpressionInvocation section = expression;
    expect(section.function, new isInstanceOf<MethodInvocation>());
    expect(section.typeArguments, isNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_paapaa_typeArgumentComments() {
    enableGenericMethodComments = true;
    createParser('..a/*<E>*/(b)/*<F>*/(c).d/*<G>*/(e)/*<H>*/(f)');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<FunctionExpressionInvocation>());
    FunctionExpressionInvocation section = expression;
    expect(section.function, new isInstanceOf<MethodInvocation>());
    expect(section.typeArguments, isNotNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_paapaa_typeArguments() {
    createParser('..a<E>(b)<F>(c).d<G>(e)<H>(f)');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<FunctionExpressionInvocation>());
    FunctionExpressionInvocation section = expression;
    expect(section.function, new isInstanceOf<MethodInvocation>());
    expect(section.typeArguments, isNotNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_pap() {
    createParser('..a(b).c');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<PropertyAccess>());
    PropertyAccess section = expression;
    expect(section.target, isNotNull);
    expect(section.operator, isNotNull);
    expect(section.propertyName, isNotNull);
  }

  void test_parseCascadeSection_pap_typeArgumentComments() {
    enableGenericMethodComments = true;
    createParser('..a/*<E>*/(b).c');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<PropertyAccess>());
    PropertyAccess section = expression;
    expect(section.target, isNotNull);
    expect(section.operator, isNotNull);
    expect(section.propertyName, isNotNull);
  }

  void test_parseCascadeSection_pap_typeArguments() {
    createParser('..a<E>(b).c');
    Expression expression = parser.parseCascadeSection();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<PropertyAccess>());
    PropertyAccess section = expression;
    expect(section.target, isNotNull);
    expect(section.operator, isNotNull);
    expect(section.propertyName, isNotNull);
  }

  void test_parseClassDeclaration_abstract() {
    createParser('class A {}');
    CompilationUnitMember member = parser.parseClassDeclaration(
        emptyCommentAndMetadata(),
        TokenFactory.tokenFromKeyword(Keyword.ABSTRACT));
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<ClassDeclaration>());
    ClassDeclaration declaration = member;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNotNull);
    expect(declaration.extendsClause, isNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseClassDeclaration_empty() {
    createParser('class A {}');
    CompilationUnitMember member =
        parser.parseClassDeclaration(emptyCommentAndMetadata(), null);
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<ClassDeclaration>());
    ClassDeclaration declaration = member;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNull);
    expect(declaration.extendsClause, isNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseClassDeclaration_extends() {
    createParser('class A extends B {}');
    CompilationUnitMember member =
        parser.parseClassDeclaration(emptyCommentAndMetadata(), null);
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<ClassDeclaration>());
    ClassDeclaration declaration = member;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNull);
    expect(declaration.extendsClause, isNotNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseClassDeclaration_extendsAndImplements() {
    createParser('class A extends B implements C {}');
    CompilationUnitMember member =
        parser.parseClassDeclaration(emptyCommentAndMetadata(), null);
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<ClassDeclaration>());
    ClassDeclaration declaration = member;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNull);
    expect(declaration.extendsClause, isNotNull);
    expect(declaration.implementsClause, isNotNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseClassDeclaration_extendsAndWith() {
    createParser('class A extends B with C {}');
    CompilationUnitMember member =
        parser.parseClassDeclaration(emptyCommentAndMetadata(), null);
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<ClassDeclaration>());
    ClassDeclaration declaration = member;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.typeParameters, isNull);
    expect(declaration.extendsClause, isNotNull);
    expect(declaration.withClause, isNotNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
  }

  void test_parseClassDeclaration_extendsAndWithAndImplements() {
    createParser('class A extends B with C implements D {}');
    CompilationUnitMember member =
        parser.parseClassDeclaration(emptyCommentAndMetadata(), null);
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<ClassDeclaration>());
    ClassDeclaration declaration = member;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.typeParameters, isNull);
    expect(declaration.extendsClause, isNotNull);
    expect(declaration.withClause, isNotNull);
    expect(declaration.implementsClause, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
  }

  void test_parseClassDeclaration_implements() {
    createParser('class A implements C {}');
    CompilationUnitMember member =
        parser.parseClassDeclaration(emptyCommentAndMetadata(), null);
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<ClassDeclaration>());
    ClassDeclaration declaration = member;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNull);
    expect(declaration.extendsClause, isNull);
    expect(declaration.implementsClause, isNotNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseClassDeclaration_native() {
    createParser('class A native "nativeValue" {}');
    CompilationUnitMember member =
        parser.parseClassDeclaration(emptyCommentAndMetadata(), null);
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<ClassDeclaration>());
    ClassDeclaration declaration = member;
    NativeClause nativeClause = declaration.nativeClause;
    expect(nativeClause, isNotNull);
    expect(nativeClause.nativeKeyword, isNotNull);
    expect(nativeClause.name.stringValue, "nativeValue");
    expect(nativeClause.beginToken, same(nativeClause.nativeKeyword));
    expect(nativeClause.endToken, same(nativeClause.name.endToken));
  }

  void test_parseClassDeclaration_nonEmpty() {
    createParser('class A {var f;}');
    CompilationUnitMember member =
        parser.parseClassDeclaration(emptyCommentAndMetadata(), null);
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<ClassDeclaration>());
    ClassDeclaration declaration = member;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNull);
    expect(declaration.extendsClause, isNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.members, hasLength(1));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNull);
  }

  void test_parseClassDeclaration_typeAlias_implementsC() {
    createParser('class A = Object with B implements C;');
    CompilationUnitMember member =
        parser.parseClassDeclaration(emptyCommentAndMetadata(), null);
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<ClassTypeAlias>());
    ClassTypeAlias typeAlias = member;
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.withClause, isNotNull);
    expect(typeAlias.implementsClause, isNotNull);
    expect(typeAlias.implementsClause.implementsKeyword, isNotNull);
    expect(typeAlias.implementsClause.interfaces.length, 1);
    expect(typeAlias.semicolon, isNotNull);
  }

  void test_parseClassDeclaration_typeAlias_withB() {
    createParser('class A = Object with B;');
    CompilationUnitMember member =
        parser.parseClassDeclaration(emptyCommentAndMetadata(), null);
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<ClassTypeAlias>());
    ClassTypeAlias typeAlias = member;
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.withClause, isNotNull);
    expect(typeAlias.withClause.withKeyword, isNotNull);
    expect(typeAlias.withClause.mixinTypes.length, 1);
    expect(typeAlias.implementsClause, isNull);
    expect(typeAlias.semicolon, isNotNull);
  }

  void test_parseClassDeclaration_typeParameters() {
    createParser('class A<B> {}');
    CompilationUnitMember member =
        parser.parseClassDeclaration(emptyCommentAndMetadata(), null);
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<ClassDeclaration>());
    ClassDeclaration declaration = member;
    expect(declaration.documentationComment, isNull);
    expect(declaration.abstractKeyword, isNull);
    expect(declaration.extendsClause, isNull);
    expect(declaration.implementsClause, isNull);
    expect(declaration.classKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.members, hasLength(0));
    expect(declaration.rightBracket, isNotNull);
    expect(declaration.typeParameters, isNotNull);
    expect(declaration.typeParameters.typeParameters, hasLength(1));
  }

  void test_parseClassMember_constructor_withInitializers() {
    // TODO(brianwilkerson) Test other kinds of class members: fields, getters
    // and setters.
    createParser('C(_, _\$, this.__) : _a = _ + _\$ {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<ConstructorDeclaration>());
    ConstructorDeclaration constructor = member;
    expect(constructor.body, isNotNull);
    expect(constructor.separator, isNotNull);
    expect(constructor.externalKeyword, isNull);
    expect(constructor.constKeyword, isNull);
    expect(constructor.factoryKeyword, isNull);
    expect(constructor.name, isNull);
    expect(constructor.parameters, isNotNull);
    expect(constructor.period, isNull);
    expect(constructor.returnType, isNotNull);
    expect(constructor.initializers, hasLength(1));
  }

  void test_parseClassMember_field_instance_prefixedType() {
    createParser('p.A f;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<FieldDeclaration>());
    FieldDeclaration field = member;
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseClassMember_field_namedGet() {
    createParser('var get;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<FieldDeclaration>());
    FieldDeclaration field = member;
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseClassMember_field_namedOperator() {
    createParser('var operator;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<FieldDeclaration>());
    FieldDeclaration field = member;
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseClassMember_field_namedOperator_withAssignment() {
    createParser('var operator = (5);');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<FieldDeclaration>());
    FieldDeclaration field = member;
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
    expect(variable.initializer, isNotNull);
  }

  void test_parseClassMember_field_namedSet() {
    createParser('var set;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<FieldDeclaration>());
    FieldDeclaration field = member;
    expect(field.documentationComment, isNull);
    expect(field.metadata, hasLength(0));
    expect(field.staticKeyword, isNull);
    VariableDeclarationList list = field.fields;
    expect(list, isNotNull);
    NodeList<VariableDeclaration> variables = list.variables;
    expect(variables, hasLength(1));
    VariableDeclaration variable = variables[0];
    expect(variable.name, isNotNull);
  }

  void test_parseClassMember_getter_void() {
    createParser('void get g {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNotNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.body, isNotNull);
    expect(method.parameters, isNull);
  }

  void test_parseClassMember_method_external() {
    createParser('external m();');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.body, isNotNull);
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNotNull);
    expect(method.modifierKeyword, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNull);
  }

  void test_parseClassMember_method_external_withTypeAndArgs() {
    createParser('external int m(int a);');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.body, isNotNull);
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNotNull);
    expect(method.modifierKeyword, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
  }

  void test_parseClassMember_method_generic_comment_noReturnType() {
    enableGenericMethodComments = true;
    createParser('m/*<T>*/() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNotNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_generic_comment_returnType() {
    enableGenericMethodComments = true;
    createParser('/*=T*/ m/*<T>*/() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType.name.name, 'T');
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNotNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_generic_comment_returnType_bound() {
    enableGenericMethodComments = true;
    createParser('num/*=T*/ m/*<T extends num>*/() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType.name.name, 'T');
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNotNull);
    TypeParameter tp = method.typeParameters.typeParameters[0];
    expect(tp.name.name, 'T');
    expect(tp.extendsKeyword, isNotNull);
    expect(tp.bound.name.name, 'num');
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_generic_comment_void() {
    enableGenericMethodComments = true;
    createParser('void m/*<T>*/() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNotNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_generic_noReturnType() {
    createParser('m<T>() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNotNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_generic_returnType() {
    createParser('T m<T>() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNotNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_generic_void() {
    createParser('void m<T>() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNotNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_get_noType() {
    createParser('get() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_get_type() {
    createParser('int get() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_get_void() {
    createParser('void get() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_operator_noType() {
    createParser('operator() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_operator_type() {
    createParser('int operator() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_operator_void() {
    createParser('void operator() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_returnType_parameterized() {
    createParser('p.A m() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_set_noType() {
    createParser('set() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_set_type() {
    createParser('int set() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_set_void() {
    createParser('void set() {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_trailing_commas() {
    createParser('void f(int x, int y,) {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_operator_index() {
    createParser('int operator [](int i) {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNotNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_operator_indexAssign() {
    createParser('int operator []=(int i) {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<MethodDeclaration>());
    MethodDeclaration method = member;
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNotNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_redirectingFactory_const() {
    createParser('const factory C() = B;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<ConstructorDeclaration>());
    ConstructorDeclaration constructor = member;
    expect(constructor.externalKeyword, isNull);
    expect(constructor.constKeyword, isNotNull);
    expect(constructor.factoryKeyword, isNotNull);
    expect(constructor.returnType, isNotNull);
    expect(constructor.period, isNull);
    expect(constructor.name, isNull);
    expect(constructor.parameters, isNotNull);
    expect(constructor.separator, isNotNull);
    expect(constructor.initializers, hasLength(0));
    expect(constructor.redirectedConstructor, isNotNull);
    expect(constructor.body, isNotNull);
  }

  void test_parseClassMember_redirectingFactory_nonConst() {
    createParser('factory C() = B;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<ConstructorDeclaration>());
    ConstructorDeclaration constructor = member;
    expect(constructor.externalKeyword, isNull);
    expect(constructor.constKeyword, isNull);
    expect(constructor.factoryKeyword, isNotNull);
    expect(constructor.returnType, isNotNull);
    expect(constructor.period, isNull);
    expect(constructor.name, isNull);
    expect(constructor.parameters, isNotNull);
    expect(constructor.separator, isNotNull);
    expect(constructor.initializers, hasLength(0));
    expect(constructor.redirectedConstructor, isNotNull);
    expect(constructor.body, isNotNull);
  }

  void test_parseClassTypeAlias_abstract() {
    Token classToken = TokenFactory.tokenFromKeyword(Keyword.CLASS);
    Token abstractToken = TokenFactory.tokenFromKeyword(Keyword.ABSTRACT);
    createParser('A = B with C;');
    ClassTypeAlias classTypeAlias = parser.parseClassTypeAlias(
        emptyCommentAndMetadata(), abstractToken, classToken);
    expectNotNullIfNoErrors(classTypeAlias);
    listener.assertNoErrors();
    expect(classTypeAlias.typedefKeyword, isNotNull);
    expect(classTypeAlias.name.name, "A");
    expect(classTypeAlias.equals, isNotNull);
    expect(classTypeAlias.abstractKeyword, isNotNull);
    expect(classTypeAlias.superclass.name.name, isNotNull, reason: "B");
    expect(classTypeAlias.withClause, isNotNull);
    expect(classTypeAlias.implementsClause, isNull);
    expect(classTypeAlias.semicolon, isNotNull);
  }

  void test_parseClassTypeAlias_implements() {
    Token classToken = TokenFactory.tokenFromKeyword(Keyword.CLASS);
    createParser('A = B with C implements D;');
    ClassTypeAlias classTypeAlias =
        parser.parseClassTypeAlias(emptyCommentAndMetadata(), null, classToken);
    expectNotNullIfNoErrors(classTypeAlias);
    listener.assertNoErrors();
    expect(classTypeAlias.typedefKeyword, isNotNull);
    expect(classTypeAlias.name.name, "A");
    expect(classTypeAlias.equals, isNotNull);
    expect(classTypeAlias.abstractKeyword, isNull);
    expect(classTypeAlias.superclass.name.name, isNotNull, reason: "B");
    expect(classTypeAlias.withClause, isNotNull);
    expect(classTypeAlias.implementsClause, isNotNull);
    expect(classTypeAlias.semicolon, isNotNull);
  }

  void test_parseClassTypeAlias_with() {
    Token classToken = TokenFactory.tokenFromKeyword(Keyword.CLASS);
    createParser('A = B with C;');
    ClassTypeAlias classTypeAlias =
        parser.parseClassTypeAlias(emptyCommentAndMetadata(), null, classToken);
    expectNotNullIfNoErrors(classTypeAlias);
    listener.assertNoErrors();
    expect(classTypeAlias.typedefKeyword, isNotNull);
    expect(classTypeAlias.name.name, "A");
    expect(classTypeAlias.equals, isNotNull);
    expect(classTypeAlias.abstractKeyword, isNull);
    expect(classTypeAlias.superclass.name.name, isNotNull, reason: "B");
    expect(classTypeAlias.withClause, isNotNull);
    expect(classTypeAlias.implementsClause, isNull);
    expect(classTypeAlias.semicolon, isNotNull);
  }

  void test_parseClassTypeAlias_with_implements() {
    Token classToken = TokenFactory.tokenFromKeyword(Keyword.CLASS);
    createParser('A = B with C implements D;');
    ClassTypeAlias classTypeAlias =
        parser.parseClassTypeAlias(emptyCommentAndMetadata(), null, classToken);
    expectNotNullIfNoErrors(classTypeAlias);
    listener.assertNoErrors();
    expect(classTypeAlias.typedefKeyword, isNotNull);
    expect(classTypeAlias.name.name, "A");
    expect(classTypeAlias.equals, isNotNull);
    expect(classTypeAlias.abstractKeyword, isNull);
    expect(classTypeAlias.superclass.name.name, isNotNull, reason: "B");
    expect(classTypeAlias.withClause, isNotNull);
    expect(classTypeAlias.implementsClause, isNotNull);
    expect(classTypeAlias.semicolon, isNotNull);
  }

  void test_parseCombinator_hide() {
    createParser('hide a;');
    Combinator combinator = parser.parseCombinator();
    expectNotNullIfNoErrors(combinator);
    listener.assertNoErrors();
    expect(combinator, new isInstanceOf<HideCombinator>());
    HideCombinator hideCombinator = combinator;
    expect(hideCombinator.keyword, isNotNull);
    expect(hideCombinator.hiddenNames, hasLength(1));
  }

  void test_parseCombinator_show() {
    createParser('show a;');
    Combinator combinator = parser.parseCombinator();
    expectNotNullIfNoErrors(combinator);
    listener.assertNoErrors();
    expect(combinator, new isInstanceOf<ShowCombinator>());
    ShowCombinator showCombinator = combinator;
    expect(showCombinator.keyword, isNotNull);
    expect(showCombinator.shownNames, hasLength(1));
  }

  void test_parseCombinators_h() {
    createParser('hide a;');
    List<Combinator> combinators = parser.parseCombinators();
    expectNotNullIfNoErrors(combinators);
    listener.assertNoErrors();
    expect(combinators, hasLength(1));
    HideCombinator combinator = combinators[0] as HideCombinator;
    expect(combinator, isNotNull);
    expect(combinator.keyword, isNotNull);
    expect(combinator.hiddenNames, hasLength(1));
  }

  void test_parseCombinators_hs() {
    createParser('hide a show b;');
    List<Combinator> combinators = parser.parseCombinators();
    expectNotNullIfNoErrors(combinators);
    listener.assertNoErrors();
    expect(combinators, hasLength(2));
    HideCombinator hideCombinator = combinators[0] as HideCombinator;
    expect(hideCombinator, isNotNull);
    expect(hideCombinator.keyword, isNotNull);
    expect(hideCombinator.hiddenNames, hasLength(1));
    ShowCombinator showCombinator = combinators[1] as ShowCombinator;
    expect(showCombinator, isNotNull);
    expect(showCombinator.keyword, isNotNull);
    expect(showCombinator.shownNames, hasLength(1));
  }

  void test_parseCombinators_hshs() {
    createParser('hide a show b hide c show d;');
    List<Combinator> combinators = parser.parseCombinators();
    expectNotNullIfNoErrors(combinators);
    listener.assertNoErrors();
    expect(combinators, hasLength(4));
  }

  void test_parseCombinators_s() {
    createParser('show a;');
    List<Combinator> combinators = parser.parseCombinators();
    expectNotNullIfNoErrors(combinators);
    listener.assertNoErrors();
    expect(combinators, hasLength(1));
    ShowCombinator combinator = combinators[0] as ShowCombinator;
    expect(combinator, isNotNull);
    expect(combinator.keyword, isNotNull);
    expect(combinator.shownNames, hasLength(1));
  }

  void test_parseCommentAndMetadata_c() {
    createParser('/** 1 */ void');
    CommentAndMetadata commentAndMetadata = parser.parseCommentAndMetadata();
    expectNotNullIfNoErrors(commentAndMetadata);
    listener.assertNoErrors();
    expect(commentAndMetadata.comment, isNotNull);
    expect(commentAndMetadata.metadata, isNull);
  }

  void test_parseCommentAndMetadata_cmc() {
    createParser('/** 1 */ @A /** 2 */ void');
    CommentAndMetadata commentAndMetadata = parser.parseCommentAndMetadata();
    expectNotNullIfNoErrors(commentAndMetadata);
    listener.assertNoErrors();
    expect(commentAndMetadata.comment, isNotNull);
    expect(commentAndMetadata.metadata, hasLength(1));
  }

  void test_parseCommentAndMetadata_cmcm() {
    createParser('/** 1 */ @A /** 2 */ @B void');
    CommentAndMetadata commentAndMetadata = parser.parseCommentAndMetadata();
    expectNotNullIfNoErrors(commentAndMetadata);
    listener.assertNoErrors();
    expect(commentAndMetadata.comment, isNotNull);
    expect(commentAndMetadata.metadata, hasLength(2));
  }

  void test_parseCommentAndMetadata_cmm() {
    createParser('/** 1 */ @A @B void');
    CommentAndMetadata commentAndMetadata = parser.parseCommentAndMetadata();
    expectNotNullIfNoErrors(commentAndMetadata);
    listener.assertNoErrors();
    expect(commentAndMetadata.comment, isNotNull);
    expect(commentAndMetadata.metadata, hasLength(2));
  }

  void test_parseCommentAndMetadata_m() {
    createParser('@A void');
    CommentAndMetadata commentAndMetadata = parser.parseCommentAndMetadata();
    expectNotNullIfNoErrors(commentAndMetadata);
    listener.assertNoErrors();
    expect(commentAndMetadata.comment, isNull);
    expect(commentAndMetadata.metadata, hasLength(1));
  }

  void test_parseCommentAndMetadata_mcm() {
    createParser('@A /** 1 */ @B void');
    CommentAndMetadata commentAndMetadata = parser.parseCommentAndMetadata();
    expectNotNullIfNoErrors(commentAndMetadata);
    listener.assertNoErrors();
    expect(commentAndMetadata.comment, isNotNull);
    expect(commentAndMetadata.metadata, hasLength(2));
  }

  void test_parseCommentAndMetadata_mcmc() {
    createParser('@A /** 1 */ @B /** 2 */ void');
    CommentAndMetadata commentAndMetadata = parser.parseCommentAndMetadata();
    expectNotNullIfNoErrors(commentAndMetadata);
    listener.assertNoErrors();
    expect(commentAndMetadata.comment, isNotNull);
    expect(commentAndMetadata.metadata, hasLength(2));
  }

  void test_parseCommentAndMetadata_mm() {
    createParser('@A @B(x) void');
    CommentAndMetadata commentAndMetadata = parser.parseCommentAndMetadata();
    expectNotNullIfNoErrors(commentAndMetadata);
    listener.assertNoErrors();
    expect(commentAndMetadata.comment, isNull);
    expect(commentAndMetadata.metadata, hasLength(2));
  }

  void test_parseCommentAndMetadata_none() {
    createParser('void');
    CommentAndMetadata commentAndMetadata = parser.parseCommentAndMetadata();
    expectNotNullIfNoErrors(commentAndMetadata);
    listener.assertNoErrors();
    expect(commentAndMetadata.comment, isNull);
    expect(commentAndMetadata.metadata, isNull);
  }

  void test_parseCommentAndMetadata_singleLine() {
    createParser(r'''
/// 1
/// 2
void''');
    CommentAndMetadata commentAndMetadata = parser.parseCommentAndMetadata();
    expectNotNullIfNoErrors(commentAndMetadata);
    listener.assertNoErrors();
    expect(commentAndMetadata.comment, isNotNull);
    expect(commentAndMetadata.metadata, isNull);
  }

  void test_parseCommentReference_new_prefixed() {
    createParser('');
    CommentReference reference = parser.parseCommentReference('new a.b', 7);
    expectNotNullIfNoErrors(reference);
    listener.assertNoErrors();
    expect(reference.identifier, new isInstanceOf<PrefixedIdentifier>());
    PrefixedIdentifier prefixedIdentifier = reference.identifier;
    SimpleIdentifier prefix = prefixedIdentifier.prefix;
    expect(prefix.token, isNotNull);
    expect(prefix.name, "a");
    expect(prefix.offset, 11);
    expect(prefixedIdentifier.period, isNotNull);
    SimpleIdentifier identifier = prefixedIdentifier.identifier;
    expect(identifier.token, isNotNull);
    expect(identifier.name, "b");
    expect(identifier.offset, 13);
  }

  void test_parseCommentReference_new_simple() {
    createParser('');
    CommentReference reference = parser.parseCommentReference('new a', 5);
    expectNotNullIfNoErrors(reference);
    listener.assertNoErrors();
    expect(reference.identifier, new isInstanceOf<SimpleIdentifier>());
    SimpleIdentifier identifier = reference.identifier;
    expect(identifier.token, isNotNull);
    expect(identifier.name, "a");
    expect(identifier.offset, 9);
  }

  void test_parseCommentReference_operator_withKeyword_notPrefixed() {
    createParser('');
    CommentReference reference = parser.parseCommentReference('operator ==', 5);
    expectNotNullIfNoErrors(reference);
    listener.assertNoErrors();
    expect(reference.identifier, new isInstanceOf<SimpleIdentifier>());
    SimpleIdentifier identifier = reference.identifier;
    expect(identifier.token, isNotNull);
    expect(identifier.name, "==");
    expect(identifier.offset, 14);
  }

  void test_parseCommentReference_operator_withKeyword_prefixed() {
    createParser('');
    CommentReference reference =
        parser.parseCommentReference('Object.operator==', 7);
    expectNotNullIfNoErrors(reference);
    listener.assertNoErrors();
    expect(reference.identifier, new isInstanceOf<PrefixedIdentifier>());
    PrefixedIdentifier prefixedIdentifier = reference.identifier;
    SimpleIdentifier prefix = prefixedIdentifier.prefix;
    expect(prefix.token, isNotNull);
    expect(prefix.name, "Object");
    expect(prefix.offset, 7);
    expect(prefixedIdentifier.period, isNotNull);
    SimpleIdentifier identifier = prefixedIdentifier.identifier;
    expect(identifier.token, isNotNull);
    expect(identifier.name, "==");
    expect(identifier.offset, 22);
  }

  void test_parseCommentReference_operator_withoutKeyword_notPrefixed() {
    createParser('');
    CommentReference reference = parser.parseCommentReference('==', 5);
    expectNotNullIfNoErrors(reference);
    listener.assertNoErrors();
    expect(reference.identifier, new isInstanceOf<SimpleIdentifier>());
    SimpleIdentifier identifier = reference.identifier;
    expect(identifier.token, isNotNull);
    expect(identifier.name, "==");
    expect(identifier.offset, 5);
  }

  void test_parseCommentReference_operator_withoutKeyword_prefixed() {
    createParser('');
    CommentReference reference = parser.parseCommentReference('Object.==', 7);
    expectNotNullIfNoErrors(reference);
    listener.assertNoErrors();
    expect(reference.identifier, new isInstanceOf<PrefixedIdentifier>());
    PrefixedIdentifier prefixedIdentifier = reference.identifier;
    SimpleIdentifier prefix = prefixedIdentifier.prefix;
    expect(prefix.token, isNotNull);
    expect(prefix.name, "Object");
    expect(prefix.offset, 7);
    expect(prefixedIdentifier.period, isNotNull);
    SimpleIdentifier identifier = prefixedIdentifier.identifier;
    expect(identifier.token, isNotNull);
    expect(identifier.name, "==");
    expect(identifier.offset, 14);
  }

  void test_parseCommentReference_prefixed() {
    createParser('');
    CommentReference reference = parser.parseCommentReference('a.b', 7);
    expectNotNullIfNoErrors(reference);
    listener.assertNoErrors();
    expect(reference.identifier, new isInstanceOf<PrefixedIdentifier>());
    PrefixedIdentifier prefixedIdentifier = reference.identifier;
    SimpleIdentifier prefix = prefixedIdentifier.prefix;
    expect(prefix.token, isNotNull);
    expect(prefix.name, "a");
    expect(prefix.offset, 7);
    expect(prefixedIdentifier.period, isNotNull);
    SimpleIdentifier identifier = prefixedIdentifier.identifier;
    expect(identifier.token, isNotNull);
    expect(identifier.name, "b");
    expect(identifier.offset, 9);
  }

  void test_parseCommentReference_simple() {
    createParser('');
    CommentReference reference = parser.parseCommentReference('a', 5);
    expectNotNullIfNoErrors(reference);
    listener.assertNoErrors();
    expect(reference.identifier, new isInstanceOf<SimpleIdentifier>());
    SimpleIdentifier identifier = reference.identifier;
    expect(identifier.token, isNotNull);
    expect(identifier.name, "a");
    expect(identifier.offset, 5);
  }

  void test_parseCommentReference_synthetic() {
    createParser('');
    CommentReference reference = parser.parseCommentReference('', 5);
    expectNotNullIfNoErrors(reference);
    listener.assertNoErrors();
    expect(reference.identifier, new isInstanceOf<SimpleIdentifier>());
    SimpleIdentifier identifier = reference.identifier;
    expect(identifier, isNotNull);
    expect(identifier.isSynthetic, isTrue);
    expect(identifier.token, isNotNull);
    expect(identifier.name, "");
    expect(identifier.offset, 5);
    // Should end with EOF token.
    Token nextToken = identifier.token.next;
    expect(nextToken, isNotNull);
    expect(nextToken.type, TokenType.EOF);
  }

  @failingTest
  void test_parseCommentReference_this() {
    // This fails because we are returning null from the method and asserting
    // that the return value is not null.
    createParser('');
    CommentReference reference = parser.parseCommentReference('this', 5);
    expectNotNullIfNoErrors(reference);
    listener.assertNoErrors();
    SimpleIdentifier identifier = EngineTestCase.assertInstanceOf(
        (obj) => obj is SimpleIdentifier,
        SimpleIdentifier,
        reference.identifier);
    expect(identifier.token, isNotNull);
    expect(identifier.name, "a");
    expect(identifier.offset, 5);
  }

  void test_parseCommentReferences_multiLine() {
    DocumentationCommentToken token = new DocumentationCommentToken(
        TokenType.MULTI_LINE_COMMENT, "/** xxx [a] yyy [bb] zzz */", 3);
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[token];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    listener.assertNoErrors();
    List<Token> tokenReferences = token.references;
    expect(references, hasLength(2));
    expect(tokenReferences, hasLength(2));
    {
      CommentReference reference = references[0];
      expect(reference, isNotNull);
      expect(reference.identifier, isNotNull);
      expect(reference.offset, 12);
      // the reference is recorded in the comment token
      Token referenceToken = tokenReferences[0];
      expect(referenceToken.offset, 12);
      expect(referenceToken.lexeme, 'a');
    }
    {
      CommentReference reference = references[1];
      expect(reference, isNotNull);
      expect(reference.identifier, isNotNull);
      expect(reference.offset, 20);
      // the reference is recorded in the comment token
      Token referenceToken = tokenReferences[1];
      expect(referenceToken.offset, 20);
      expect(referenceToken.lexeme, 'bb');
    }
  }

  void test_parseCommentReferences_notClosed_noIdentifier() {
    DocumentationCommentToken docToken = new DocumentationCommentToken(
        TokenType.MULTI_LINE_COMMENT, "/** [ some text", 5);
    createParser('');
    List<CommentReference> references =
        parser.parseCommentReferences(<DocumentationCommentToken>[docToken]);
    expectNotNullIfNoErrors(references);
    listener.assertNoErrors();
    expect(docToken.references, hasLength(1));
    expect(references, hasLength(1));
    Token referenceToken = docToken.references[0];
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(docToken.references[0], same(reference.beginToken));
    expect(reference.identifier, isNotNull);
    expect(reference.identifier.isSynthetic, isTrue);
    expect(reference.identifier.name, "");
    // Should end with EOF token.
    Token nextToken = referenceToken.next;
    expect(nextToken, isNotNull);
    expect(nextToken.type, TokenType.EOF);
  }

  void test_parseCommentReferences_notClosed_withIdentifier() {
    DocumentationCommentToken docToken = new DocumentationCommentToken(
        TokenType.MULTI_LINE_COMMENT, "/** [namePrefix some text", 5);
    createParser('');
    List<CommentReference> references =
        parser.parseCommentReferences(<DocumentationCommentToken>[docToken]);
    expectNotNullIfNoErrors(references);
    listener.assertNoErrors();
    expect(docToken.references, hasLength(1));
    expect(references, hasLength(1));
    Token referenceToken = docToken.references[0];
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(referenceToken, same(reference.beginToken));
    expect(reference.identifier, isNotNull);
    expect(reference.identifier.isSynthetic, isFalse);
    expect(reference.identifier.name, "namePrefix");
    // Should end with EOF token.
    Token nextToken = referenceToken.next;
    expect(nextToken, isNotNull);
    expect(nextToken.type, TokenType.EOF);
  }

  void test_parseCommentReferences_singleLine() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[
      new DocumentationCommentToken(
          TokenType.SINGLE_LINE_COMMENT, "/// xxx [a] yyy [b] zzz", 3),
      new DocumentationCommentToken(
          TokenType.SINGLE_LINE_COMMENT, "/// x [c]", 28)
    ];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    listener.assertNoErrors();
    expect(references, hasLength(3));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 12);
    reference = references[1];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 20);
    reference = references[2];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 35);
  }

  void test_parseCommentReferences_skipCodeBlock_4spaces_block() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[
      new DocumentationCommentToken(TokenType.MULTI_LINE_COMMENT,
          "/**\n *     a[i]\n * non-code line\n */", 3)
    ];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    listener.assertNoErrors();
    expect(references, isEmpty);
  }

  void test_parseCommentReferences_skipCodeBlock_4spaces_lines() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[
      new DocumentationCommentToken(
          TokenType.SINGLE_LINE_COMMENT, "/// Code block:", 0),
      new DocumentationCommentToken(
          TokenType.SINGLE_LINE_COMMENT, "///     a[i] == b[i]", 0)
    ];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    listener.assertNoErrors();
    expect(references, isEmpty);
  }

  void test_parseCommentReferences_skipCodeBlock_bracketed() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[
      new DocumentationCommentToken(
          TokenType.MULTI_LINE_COMMENT, "/** [:xxx [a] yyy:] [b] zzz */", 3)
    ];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    listener.assertNoErrors();
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 24);
  }

  void test_parseCommentReferences_skipCodeBlock_gitHub() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[
      new DocumentationCommentToken(
          TokenType.MULTI_LINE_COMMENT, "/** `a[i]` and [b] */", 0)
    ];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    listener.assertNoErrors();
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 16);
  }

  void test_parseCommentReferences_skipCodeBlock_gitHub_multiLine() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[
      new DocumentationCommentToken(
          TokenType.MULTI_LINE_COMMENT,
          r'''
/**
 * First.
 * ```dart
 * Some [int] reference.
 * ```
 * Last.
 */
''',
          3)
    ];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    listener.assertNoErrors();
    expect(references, isEmpty);
  }

  void test_parseCommentReferences_skipCodeBlock_gitHub_multiLine_lines() {
    String commentText = r'''
/// First.
/// ```dart
/// Some [int] reference.
/// ```
/// Last.
''';
    List<DocumentationCommentToken> tokens = commentText
        .split('\n')
        .map((line) => new DocumentationCommentToken(
            TokenType.SINGLE_LINE_COMMENT, line, 0))
        .toList();
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    listener.assertNoErrors();
    expect(references, isEmpty);
  }

  void test_parseCommentReferences_skipCodeBlock_gitHub_notTerminated() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[
      new DocumentationCommentToken(
          TokenType.MULTI_LINE_COMMENT, "/** `a[i] and [b] */", 0)
    ];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    listener.assertNoErrors();
    expect(references, hasLength(2));
  }

  void test_parseCommentReferences_skipCodeBlock_spaces() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[
      new DocumentationCommentToken(TokenType.MULTI_LINE_COMMENT,
          "/**\n *     a[i]\n * xxx [i] zzz\n */", 3)
    ];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    listener.assertNoErrors();
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 27);
  }

  void test_parseCommentReferences_skipLinkDefinition() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[
      new DocumentationCommentToken(TokenType.MULTI_LINE_COMMENT,
          "/** [a]: http://www.google.com (Google) [b] zzz */", 3)
    ];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    listener.assertNoErrors();
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 44);
  }

  void test_parseCommentReferences_skipLinked() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[
      new DocumentationCommentToken(TokenType.MULTI_LINE_COMMENT,
          "/** [a](http://www.google.com) [b] zzz */", 3)
    ];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    listener.assertNoErrors();
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 35);
  }

  void test_parseCommentReferences_skipReferenceLink() {
    List<DocumentationCommentToken> tokens = <DocumentationCommentToken>[
      new DocumentationCommentToken(
          TokenType.MULTI_LINE_COMMENT, "/** [a][c] [b] zzz */", 3)
    ];
    createParser('');
    List<CommentReference> references = parser.parseCommentReferences(tokens);
    expectNotNullIfNoErrors(references);
    listener.assertNoErrors();
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 15);
  }

  void test_parseCompilationUnit_abstractAsPrefix_parameterized() {
    createParser('abstract<dynamic> _abstract = new abstract.A();');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    listener.assertNoErrors();
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnit_builtIn_asFunctionName() {
    ParserTestCase.parseCompilationUnit('abstract(x) => 0;');
    ParserTestCase.parseCompilationUnit('as(x) => 0;');
    ParserTestCase.parseCompilationUnit('dynamic(x) => 0;');
    ParserTestCase.parseCompilationUnit('export(x) => 0;');
    ParserTestCase.parseCompilationUnit('external(x) => 0;');
    ParserTestCase.parseCompilationUnit('factory(x) => 0;');
    ParserTestCase.parseCompilationUnit('get(x) => 0;');
    ParserTestCase.parseCompilationUnit('implements(x) => 0;');
    ParserTestCase.parseCompilationUnit('import(x) => 0;');
    ParserTestCase.parseCompilationUnit('library(x) => 0;');
    ParserTestCase.parseCompilationUnit('operator(x) => 0;');
    ParserTestCase.parseCompilationUnit('part(x) => 0;');
    ParserTestCase.parseCompilationUnit('set(x) => 0;');
    ParserTestCase.parseCompilationUnit('static(x) => 0;');
    ParserTestCase.parseCompilationUnit('typedef(x) => 0;');
  }

  void test_parseCompilationUnit_directives_multiple() {
    createParser("library l;\npart 'a.dart';");
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    listener.assertNoErrors();
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(2));
    expect(unit.declarations, hasLength(0));
  }

  void test_parseCompilationUnit_directives_single() {
    createParser('library l;');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    listener.assertNoErrors();
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(1));
    expect(unit.declarations, hasLength(0));
  }

  void test_parseCompilationUnit_empty() {
    createParser('');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    listener.assertNoErrors();
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(0));
  }

  void test_parseCompilationUnit_exportAsPrefix() {
    createParser('export.A _export = new export.A();');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    listener.assertNoErrors();
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnit_exportAsPrefix_parameterized() {
    createParser('export<dynamic> _export = new export.A();');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    listener.assertNoErrors();
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnit_operatorAsPrefix_parameterized() {
    createParser('operator<dynamic> _operator = new operator.A();');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    listener.assertNoErrors();
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnit_script() {
    createParser('#! /bin/dart');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    listener.assertNoErrors();
    expect(unit.scriptTag, isNotNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(0));
  }

  void test_parseCompilationUnit_skipFunctionBody_withInterpolation() {
    ParserTestCase.parseFunctionBodies = false;
    createParser('f() { "\${n}"; }');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    listener.assertNoErrors();
    expect(unit.scriptTag, isNull);
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnit_topLevelDeclaration() {
    createParser('class A {}');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    listener.assertNoErrors();
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnit_typedefAsPrefix() {
    createParser('typedef.A _typedef = new typedef.A();');
    CompilationUnit unit = parser.parseCompilationUnit2();
    expectNotNullIfNoErrors(unit);
    listener.assertNoErrors();
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnitMember_abstractAsPrefix() {
    createParser('abstract.A _abstract = new abstract.A();');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<TopLevelVariableDeclaration>());
    TopLevelVariableDeclaration declaration = member;
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
  }

  void test_parseCompilationUnitMember_class() {
    createParser('class A {}');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<ClassDeclaration>());
    ClassDeclaration declaration = member;
    expect(declaration.name.name, "A");
    expect(declaration.members, hasLength(0));
  }

  void test_parseCompilationUnitMember_classTypeAlias() {
    createParser('abstract class A = B with C;');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<ClassTypeAlias>());
    ClassTypeAlias declaration = member;
    expect(declaration.name.name, "A");
    expect(declaration.abstractKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_constVariable() {
    createParser('const int x = 0;');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<TopLevelVariableDeclaration>());
    TopLevelVariableDeclaration declaration = member;
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
  }

  void test_parseCompilationUnitMember_finalVariable() {
    createParser('final x = 0;');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<TopLevelVariableDeclaration>());
    TopLevelVariableDeclaration declaration = member;
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
  }

  void test_parseCompilationUnitMember_function_external_noType() {
    createParser('external f();');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<FunctionDeclaration>());
    FunctionDeclaration declaration = member;
    expect(declaration.externalKeyword, isNotNull);
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseCompilationUnitMember_function_external_type() {
    createParser('external int f();');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<FunctionDeclaration>());
    FunctionDeclaration declaration = member;
    expect(declaration.externalKeyword, isNotNull);
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseCompilationUnitMember_function_generic_noReturnType() {
    createParser('f<E>() {}');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<FunctionDeclaration>());
    FunctionDeclaration declaration = member;
    expect(declaration.returnType, isNull);
    expect(declaration.functionExpression.typeParameters, isNotNull);
  }

  void
      test_parseCompilationUnitMember_function_generic_noReturnType_annotated() {
    createParser('f<@a E>() {}');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<FunctionDeclaration>());
    FunctionDeclaration declaration = member;
    expect(declaration.returnType, isNull);
    expect(declaration.functionExpression.typeParameters, isNotNull);
  }

  void test_parseCompilationUnitMember_function_generic_returnType() {
    createParser('E f<E>() {}');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<FunctionDeclaration>());
    FunctionDeclaration declaration = member;
    expect(declaration.returnType, isNotNull);
    expect(declaration.functionExpression.typeParameters, isNotNull);
  }

  void test_parseCompilationUnitMember_function_generic_void() {
    createParser('void f<T>(T t) {}');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<FunctionDeclaration>());
    FunctionDeclaration declaration = member;
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseCompilationUnitMember_function_noType() {
    createParser('f() {}');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<FunctionDeclaration>());
    FunctionDeclaration declaration = member;
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseCompilationUnitMember_function_type() {
    createParser('int f() {}');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<FunctionDeclaration>());
    FunctionDeclaration declaration = member;
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseCompilationUnitMember_function_void() {
    createParser('void f() {}');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<FunctionDeclaration>());
    FunctionDeclaration declaration = member;
    expect(declaration.returnType, isNotNull);
  }

  void test_parseCompilationUnitMember_getter_external_noType() {
    createParser('external get p;');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<FunctionDeclaration>());
    FunctionDeclaration declaration = member;
    expect(declaration.externalKeyword, isNotNull);
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_getter_external_type() {
    createParser('external int get p;');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<FunctionDeclaration>());
    FunctionDeclaration declaration = member;
    expect(declaration.externalKeyword, isNotNull);
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_getter_noType() {
    createParser('get p => 0;');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<FunctionDeclaration>());
    FunctionDeclaration declaration = member;
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_getter_type() {
    createParser('int get p => 0;');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<FunctionDeclaration>());
    FunctionDeclaration declaration = member;
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_setter_external_noType() {
    createParser('external set p(v);');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<FunctionDeclaration>());
    FunctionDeclaration declaration = member;
    expect(declaration.externalKeyword, isNotNull);
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_setter_external_type() {
    createParser('external void set p(int v);');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<FunctionDeclaration>());
    FunctionDeclaration declaration = member;
    expect(declaration.externalKeyword, isNotNull);
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_setter_noType() {
    createParser('set p(v) {}');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<FunctionDeclaration>());
    FunctionDeclaration declaration = member;
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_setter_type() {
    createParser('void set p(int v) {}');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<FunctionDeclaration>());
    FunctionDeclaration declaration = member;
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
    expect(declaration.returnType, isNotNull);
  }

  void test_parseCompilationUnitMember_typeAlias_abstract() {
    createParser('abstract class C = S with M;');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<ClassTypeAlias>());
    ClassTypeAlias typeAlias = member;
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name.name, "C");
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.equals, isNotNull);
    expect(typeAlias.abstractKeyword, isNotNull);
    expect(typeAlias.superclass.name.name, "S");
    expect(typeAlias.withClause, isNotNull);
    expect(typeAlias.implementsClause, isNull);
    expect(typeAlias.semicolon, isNotNull);
  }

  void test_parseCompilationUnitMember_typeAlias_generic() {
    createParser('class C<E> = S<E> with M<E> implements I<E>;');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<ClassTypeAlias>());
    ClassTypeAlias typeAlias = member;
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name.name, "C");
    expect(typeAlias.typeParameters.typeParameters, hasLength(1));
    expect(typeAlias.equals, isNotNull);
    expect(typeAlias.abstractKeyword, isNull);
    expect(typeAlias.superclass.name.name, "S");
    expect(typeAlias.withClause, isNotNull);
    expect(typeAlias.implementsClause, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
  }

  void test_parseCompilationUnitMember_typeAlias_implements() {
    createParser('class C = S with M implements I;');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<ClassTypeAlias>());
    ClassTypeAlias typeAlias = member;
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name.name, "C");
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.equals, isNotNull);
    expect(typeAlias.abstractKeyword, isNull);
    expect(typeAlias.superclass.name.name, "S");
    expect(typeAlias.withClause, isNotNull);
    expect(typeAlias.implementsClause, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
  }

  void test_parseCompilationUnitMember_typeAlias_noImplements() {
    createParser('class C = S with M;');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<ClassTypeAlias>());
    ClassTypeAlias typeAlias = member;
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name.name, "C");
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.equals, isNotNull);
    expect(typeAlias.abstractKeyword, isNull);
    expect(typeAlias.superclass.name.name, "S");
    expect(typeAlias.withClause, isNotNull);
    expect(typeAlias.implementsClause, isNull);
    expect(typeAlias.semicolon, isNotNull);
  }

  void test_parseCompilationUnitMember_typedef() {
    createParser('typedef F();');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<FunctionTypeAlias>());
    FunctionTypeAlias typeAlias = member;
    expect(typeAlias.name.name, "F");
    expect(typeAlias.parameters.parameters, hasLength(0));
  }

  void test_parseCompilationUnitMember_variable() {
    createParser('var x = 0;');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<TopLevelVariableDeclaration>());
    TopLevelVariableDeclaration declaration = member;
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
  }

  void test_parseCompilationUnitMember_variableGet() {
    createParser('String get = null;');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<TopLevelVariableDeclaration>());
    TopLevelVariableDeclaration declaration = member;
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
  }

  void test_parseCompilationUnitMember_variableSet() {
    createParser('String set = null;');
    CompilationUnitMember member =
        parser.parseCompilationUnitMember(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<TopLevelVariableDeclaration>());
    TopLevelVariableDeclaration declaration = member;
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
  }

  void test_parseConditionalExpression() {
    createParser('x ? y : z');
    ConditionalExpression expression = parser.parseConditionalExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.condition, isNotNull);
    expect(expression.question, isNotNull);
    expect(expression.thenExpression, isNotNull);
    expect(expression.colon, isNotNull);
    expect(expression.elseExpression, isNotNull);
  }

  void test_parseConfiguration_noOperator_dottedIdentifier() {
    createParser("if (a.b) 'c.dart'");
    Configuration configuration = parser.parseConfiguration();
    expectNotNullIfNoErrors(configuration);
    listener.assertNoErrors();
    expect(configuration.ifKeyword, isNotNull);
    expect(configuration.leftParenthesis, isNotNull);
    _expectDottedName(configuration.name, ["a", "b"]);
    expect(configuration.equalToken, isNull);
    expect(configuration.value, isNull);
    expect(configuration.rightParenthesis, isNotNull);
    expect(configuration.uri, isNotNull);
  }

  void test_parseConfiguration_noOperator_simpleIdentifier() {
    createParser("if (a) 'b.dart'");
    Configuration configuration = parser.parseConfiguration();
    expectNotNullIfNoErrors(configuration);
    listener.assertNoErrors();
    expect(configuration.ifKeyword, isNotNull);
    expect(configuration.leftParenthesis, isNotNull);
    _expectDottedName(configuration.name, ["a"]);
    expect(configuration.equalToken, isNull);
    expect(configuration.value, isNull);
    expect(configuration.rightParenthesis, isNotNull);
    expect(configuration.uri, isNotNull);
  }

  void test_parseConfiguration_operator_dottedIdentifier() {
    createParser("if (a.b == 'c') 'd.dart'");
    Configuration configuration = parser.parseConfiguration();
    expectNotNullIfNoErrors(configuration);
    listener.assertNoErrors();
    expect(configuration.ifKeyword, isNotNull);
    expect(configuration.leftParenthesis, isNotNull);
    _expectDottedName(configuration.name, ["a", "b"]);
    expect(configuration.equalToken, isNotNull);
    expect(configuration.value, isNotNull);
    expect(configuration.rightParenthesis, isNotNull);
    expect(configuration.uri, isNotNull);
  }

  void test_parseConfiguration_operator_simpleIdentifier() {
    createParser("if (a == 'b') 'c.dart'");
    Configuration configuration = parser.parseConfiguration();
    expectNotNullIfNoErrors(configuration);
    listener.assertNoErrors();
    expect(configuration.ifKeyword, isNotNull);
    expect(configuration.leftParenthesis, isNotNull);
    _expectDottedName(configuration.name, ["a"]);
    expect(configuration.equalToken, isNotNull);
    expect(configuration.value, isNotNull);
    expect(configuration.rightParenthesis, isNotNull);
    expect(configuration.uri, isNotNull);
  }

  void test_parseConstExpression_instanceCreation() {
    createParser('const A()');
    Expression expression = parser.parseConstExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<InstanceCreationExpression>());
    InstanceCreationExpression instanceCreation = expression;
    expect(instanceCreation.keyword, isNotNull);
    ConstructorName name = instanceCreation.constructorName;
    expect(name, isNotNull);
    expect(name.type, isNotNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(instanceCreation.argumentList, isNotNull);
  }

  void test_parseConstExpression_listLiteral_typed() {
    createParser('const <A> []');
    Expression expression = parser.parseConstExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<ListLiteral>());
    ListLiteral literal = expression;
    expect(literal.constKeyword, isNotNull);
    expect(literal.typeArguments, isNotNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseConstExpression_listLiteral_typed_genericComment() {
    enableGenericMethodComments = true;
    createParser('const /*<A>*/ []');
    Expression expression = parser.parseConstExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<ListLiteral>());
    ListLiteral literal = expression;
    expect(literal.constKeyword, isNotNull);
    expect(literal.typeArguments, isNotNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseConstExpression_listLiteral_untyped() {
    createParser('const []');
    Expression expression = parser.parseConstExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<ListLiteral>());
    ListLiteral literal = expression;
    expect(literal.constKeyword, isNotNull);
    expect(literal.typeArguments, isNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseConstExpression_mapLiteral_typed() {
    createParser('const <A, B> {}');
    Expression expression = parser.parseConstExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<MapLiteral>());
    MapLiteral literal = expression;
    expect(literal.leftBracket, isNotNull);
    expect(literal.entries, hasLength(0));
    expect(literal.rightBracket, isNotNull);
    expect(literal.typeArguments, isNotNull);
  }

  void test_parseConstExpression_mapLiteral_typed_genericComment() {
    enableGenericMethodComments = true;
    createParser('const /*<A, B>*/ {}');
    Expression expression = parser.parseConstExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<MapLiteral>());
    MapLiteral literal = expression;
    expect(literal.leftBracket, isNotNull);
    expect(literal.entries, hasLength(0));
    expect(literal.rightBracket, isNotNull);
    expect(literal.typeArguments, isNotNull);
  }

  void test_parseConstExpression_mapLiteral_untyped() {
    createParser('const {}');
    Expression expression = parser.parseConstExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<MapLiteral>());
    MapLiteral literal = expression;
    expect(literal.leftBracket, isNotNull);
    expect(literal.entries, hasLength(0));
    expect(literal.rightBracket, isNotNull);
    expect(literal.typeArguments, isNull);
  }

  void test_parseConstructor() {
    // TODO(brianwilkerson) Implement tests for this method.
  }

  void test_parseConstructor_assert() {
    enableAssertInitializer = true;
    createParser('C(x, y) : _x = x, assert (x < y), _y = y;');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<ConstructorDeclaration>());
    ConstructorDeclaration constructor = member as ConstructorDeclaration;
    NodeList<ConstructorInitializer> initializers = constructor.initializers;
    expect(initializers, hasLength(3));
    ConstructorInitializer initializer = initializers[1];
    expect(initializer, new isInstanceOf<AssertInitializer>());
    AssertInitializer assertInitializer = initializer;
    expect(assertInitializer.condition, isNotNull);
    expect(assertInitializer.message, isNull);
  }

  void test_parseConstructor_with_pseudo_function_literal() {
    // "(b) {}" should not be misinterpreted as a function literal even though
    // it looks like one.
    createParser('C() : a = (b) {}');
    ClassMember member = parser.parseClassMember('C');
    expectNotNullIfNoErrors(member);
    listener.assertNoErrors();
    expect(member, new isInstanceOf<ConstructorDeclaration>());
    ConstructorDeclaration constructor = member as ConstructorDeclaration;
    NodeList<ConstructorInitializer> initializers = constructor.initializers;
    expect(initializers, hasLength(1));
    ConstructorInitializer initializer = initializers[0];
    EngineTestCase.assertInstanceOf((obj) => obj is ConstructorFieldInitializer,
        ConstructorFieldInitializer, initializer);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ParenthesizedExpression,
        ParenthesizedExpression,
        (initializer as ConstructorFieldInitializer).expression);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is BlockFunctionBody, BlockFunctionBody, constructor.body);
  }

  void test_parseConstructorFieldInitializer_qualified() {
    createParser('this.a = b');
    ConstructorFieldInitializer initializer =
        parser.parseConstructorFieldInitializer(true);
    expectNotNullIfNoErrors(initializer);
    listener.assertNoErrors();
    expect(initializer.equals, isNotNull);
    expect(initializer.expression, isNotNull);
    expect(initializer.fieldName, isNotNull);
    expect(initializer.thisKeyword, isNotNull);
    expect(initializer.period, isNotNull);
  }

  void test_parseConstructorFieldInitializer_unqualified() {
    createParser('a = b');
    ConstructorFieldInitializer initializer =
        parser.parseConstructorFieldInitializer(false);
    expectNotNullIfNoErrors(initializer);
    listener.assertNoErrors();
    expect(initializer.equals, isNotNull);
    expect(initializer.expression, isNotNull);
    expect(initializer.fieldName, isNotNull);
    expect(initializer.thisKeyword, isNull);
    expect(initializer.period, isNull);
  }

  void test_parseConstructorName_named_noPrefix() {
    createParser('A.n;');
    ConstructorName name = parser.parseConstructorName();
    expectNotNullIfNoErrors(name);
    listener.assertNoErrors();
    expect(name.type, isNotNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
  }

  void test_parseConstructorName_named_prefixed() {
    createParser('p.A.n;');
    ConstructorName name = parser.parseConstructorName();
    expectNotNullIfNoErrors(name);
    listener.assertNoErrors();
    expect(name.type, isNotNull);
    expect(name.period, isNotNull);
    expect(name.name, isNotNull);
  }

  void test_parseConstructorName_unnamed_noPrefix() {
    createParser('A;');
    ConstructorName name = parser.parseConstructorName();
    expectNotNullIfNoErrors(name);
    listener.assertNoErrors();
    expect(name.type, isNotNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
  }

  void test_parseConstructorName_unnamed_prefixed() {
    createParser('p.A;');
    ConstructorName name = parser.parseConstructorName();
    expectNotNullIfNoErrors(name);
    listener.assertNoErrors();
    expect(name.type, isNotNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
  }

  void test_parseContinueStatement_label() {
    createParser('continue foo;');
    ContinueStatement statement = parser.parseContinueStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertErrorsWithCodes([ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP]);
    expect(statement.continueKeyword, isNotNull);
    expect(statement.label, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseContinueStatement_noLabel() {
    createParser('continue;');
    ContinueStatement statement = parser.parseContinueStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertErrorsWithCodes([ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP]);
    expect(statement.continueKeyword, isNotNull);
    expect(statement.label, isNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseDirective_export() {
    createParser("export 'lib/lib.dart';");
    Directive directive = parser.parseDirective(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(directive);
    listener.assertNoErrors();
    expect(directive, new isInstanceOf<ExportDirective>());
    ExportDirective exportDirective = directive;
    expect(exportDirective.keyword, isNotNull);
    expect(exportDirective.uri, isNotNull);
    expect(exportDirective.combinators, hasLength(0));
    expect(exportDirective.semicolon, isNotNull);
  }

  void test_parseDirective_import() {
    createParser("import 'lib/lib.dart';");
    Directive directive = parser.parseDirective(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(directive);
    listener.assertNoErrors();
    expect(directive, new isInstanceOf<ImportDirective>());
    ImportDirective importDirective = directive;
    expect(importDirective.keyword, isNotNull);
    expect(importDirective.uri, isNotNull);
    expect(importDirective.asKeyword, isNull);
    expect(importDirective.prefix, isNull);
    expect(importDirective.combinators, hasLength(0));
    expect(importDirective.semicolon, isNotNull);
  }

  void test_parseDirective_library() {
    createParser("library l;");
    Directive directive = parser.parseDirective(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(directive);
    listener.assertNoErrors();
    expect(directive, new isInstanceOf<LibraryDirective>());
    LibraryDirective libraryDirective = directive;
    expect(libraryDirective.libraryKeyword, isNotNull);
    expect(libraryDirective.name, isNotNull);
    expect(libraryDirective.semicolon, isNotNull);
  }

  void test_parseDirective_part() {
    createParser("part 'lib/lib.dart';");
    Directive directive = parser.parseDirective(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(directive);
    listener.assertNoErrors();
    expect(directive, new isInstanceOf<PartDirective>());
    PartDirective partDirective = directive;
    expect(partDirective.partKeyword, isNotNull);
    expect(partDirective.uri, isNotNull);
    expect(partDirective.semicolon, isNotNull);
  }

  void test_parseDirective_partOf() {
    createParser("part of l;");
    Directive directive = parser.parseDirective(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(directive);
    listener.assertNoErrors();
    expect(directive, new isInstanceOf<PartOfDirective>());
    PartOfDirective partOfDirective = directive;
    expect(partOfDirective.partKeyword, isNotNull);
    expect(partOfDirective.ofKeyword, isNotNull);
    expect(partOfDirective.libraryName, isNotNull);
    expect(partOfDirective.semicolon, isNotNull);
  }

  void test_parseDirectives_complete() {
    CompilationUnit unit =
        _parseDirectives("#! /bin/dart\nlibrary l;\nclass A {}");
    expect(unit.scriptTag, isNotNull);
    expect(unit.directives, hasLength(1));
  }

  void test_parseDirectives_empty() {
    CompilationUnit unit = _parseDirectives("");
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
  }

  void test_parseDirectives_mixed() {
    CompilationUnit unit =
        _parseDirectives("library l; class A {} part 'foo.dart';");
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(1));
  }

  void test_parseDirectives_multiple() {
    CompilationUnit unit = _parseDirectives("library l;\npart 'a.dart';");
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(2));
  }

  void test_parseDirectives_script() {
    CompilationUnit unit = _parseDirectives("#! /bin/dart");
    expect(unit.scriptTag, isNotNull);
    expect(unit.directives, hasLength(0));
  }

  void test_parseDirectives_single() {
    CompilationUnit unit = _parseDirectives("library l;");
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(1));
  }

  void test_parseDirectives_topLevelDeclaration() {
    CompilationUnit unit = _parseDirectives("class A {}");
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
  }

  void test_parseDocumentationComment_block() {
    createParser('/** */ class');
    Comment comment = parser
        .parseDocumentationComment(parser.parseDocumentationCommentTokens());
    expectNotNullIfNoErrors(comment);
    listener.assertNoErrors();
    expect(comment.isBlock, isFalse);
    expect(comment.isDocumentation, isTrue);
    expect(comment.isEndOfLine, isFalse);
  }

  void test_parseDocumentationComment_block_withReference() {
    createParser('/** [a] */ class');
    Comment comment = parser
        .parseDocumentationComment(parser.parseDocumentationCommentTokens());
    expectNotNullIfNoErrors(comment);
    listener.assertNoErrors();
    expect(comment.isBlock, isFalse);
    expect(comment.isDocumentation, isTrue);
    expect(comment.isEndOfLine, isFalse);
    NodeList<CommentReference> references = comment.references;
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.offset, 5);
  }

  void test_parseDocumentationComment_endOfLine() {
    createParser('/// \n/// \n class');
    Comment comment = parser
        .parseDocumentationComment(parser.parseDocumentationCommentTokens());
    expectNotNullIfNoErrors(comment);
    listener.assertNoErrors();
    expect(comment.isBlock, isFalse);
    expect(comment.isDocumentation, isTrue);
    expect(comment.isEndOfLine, isFalse);
  }

  void test_parseDoStatement() {
    createParser('do {} while (x);');
    DoStatement statement = parser.parseDoStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.doKeyword, isNotNull);
    expect(statement.body, isNotNull);
    expect(statement.whileKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseDottedName_multiple() {
    createParser('a.b.c');
    DottedName name = parser.parseDottedName();
    expectNotNullIfNoErrors(name);
    listener.assertNoErrors();
    _expectDottedName(name, ["a", "b", "c"]);
  }

  void test_parseDottedName_single() {
    createParser('a');
    DottedName name = parser.parseDottedName();
    expectNotNullIfNoErrors(name);
    listener.assertNoErrors();
    _expectDottedName(name, ["a"]);
  }

  void test_parseEmptyStatement() {
    createParser(';');
    EmptyStatement statement = parser.parseEmptyStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.semicolon, isNotNull);
  }

  void test_parseEnumDeclaration_one() {
    createParser("enum E {ONE}");
    EnumDeclaration declaration =
        parser.parseEnumDeclaration(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(declaration);
    listener.assertNoErrors();
    expect(declaration.documentationComment, isNull);
    expect(declaration.enumKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.constants, hasLength(1));
    expect(declaration.rightBracket, isNotNull);
  }

  void test_parseEnumDeclaration_trailingComma() {
    createParser("enum E {ONE,}");
    EnumDeclaration declaration =
        parser.parseEnumDeclaration(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(declaration);
    listener.assertNoErrors();
    expect(declaration.documentationComment, isNull);
    expect(declaration.enumKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.constants, hasLength(1));
    expect(declaration.rightBracket, isNotNull);
  }

  void test_parseEnumDeclaration_two() {
    createParser("enum E {ONE, TWO}");
    EnumDeclaration declaration =
        parser.parseEnumDeclaration(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(declaration);
    listener.assertNoErrors();
    expect(declaration.documentationComment, isNull);
    expect(declaration.enumKeyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.constants, hasLength(2));
    expect(declaration.rightBracket, isNotNull);
  }

  void test_parseEqualityExpression_normal() {
    createParser('x == y');
    BinaryExpression expression = parser.parseEqualityExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.leftOperand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.EQ_EQ);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseEqualityExpression_super() {
    createParser('super == y');
    BinaryExpression expression = parser.parseEqualityExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.leftOperand, new isInstanceOf<SuperExpression>());
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.EQ_EQ);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseExportDirective_configuration_multiple() {
    createParser("export 'lib/lib.dart' if (a) 'b.dart' if (c) 'd.dart';");
    ExportDirective directive =
        parser.parseExportDirective(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(directive);
    listener.assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.configurations, hasLength(2));
    _expectDottedName(directive.configurations[0].name, ['a']);
    _expectDottedName(directive.configurations[1].name, ['c']);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseExportDirective_configuration_single() {
    createParser("export 'lib/lib.dart' if (a.b == 'c.dart') '';");
    ExportDirective directive =
        parser.parseExportDirective(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(directive);
    listener.assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.configurations, hasLength(1));
    _expectDottedName(directive.configurations[0].name, ['a', 'b']);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseExportDirective_hide() {
    createParser("export 'lib/lib.dart' hide A, B;");
    ExportDirective directive =
        parser.parseExportDirective(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(directive);
    listener.assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.combinators, hasLength(1));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseExportDirective_hide_show() {
    createParser("export 'lib/lib.dart' hide A show B;");
    ExportDirective directive =
        parser.parseExportDirective(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(directive);
    listener.assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.combinators, hasLength(2));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseExportDirective_noCombinator() {
    createParser("export 'lib/lib.dart';");
    ExportDirective directive =
        parser.parseExportDirective(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(directive);
    listener.assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseExportDirective_show() {
    createParser("export 'lib/lib.dart' show A, B;");
    ExportDirective directive =
        parser.parseExportDirective(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(directive);
    listener.assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.combinators, hasLength(1));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseExportDirective_show_hide() {
    createParser("export 'lib/lib.dart' show B hide A;");
    ExportDirective directive =
        parser.parseExportDirective(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(directive);
    listener.assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.combinators, hasLength(2));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseExpression_assign() {
    // TODO(brianwilkerson) Implement more tests for this method.
    Expression expression = parseExpression('x = y');
    expect(expression, new isInstanceOf<AssignmentExpression>());
    AssignmentExpression assignmentExpression = expression;
    expect(assignmentExpression.leftHandSide, isNotNull);
    expect(assignmentExpression.operator, isNotNull);
    expect(assignmentExpression.operator.type, TokenType.EQ);
    expect(assignmentExpression.rightHandSide, isNotNull);
  }

  void test_parseExpression_assign_compound() {
    enableLazyAssignmentOperators = true;
    Expression expression = parseExpression('x ||= y');
    expect(expression, new isInstanceOf<AssignmentExpression>());
    AssignmentExpression assignmentExpression = expression;
    expect(assignmentExpression.leftHandSide, isNotNull);
    expect(assignmentExpression.operator, isNotNull);
    expect(assignmentExpression.operator.type, TokenType.BAR_BAR_EQ);
    expect(assignmentExpression.rightHandSide, isNotNull);
  }

  void test_parseExpression_comparison() {
    Expression expression = parseExpression('--a.b == c');
    expect(expression, new isInstanceOf<BinaryExpression>());
    BinaryExpression binaryExpression = expression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.EQ_EQ);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseExpression_function_async() {
    Expression expression = parseExpression('() async {}');
    expect(expression, new isInstanceOf<FunctionExpression>());
    FunctionExpression functionExpression = expression;
    expect(functionExpression.body, isNotNull);
    expect(functionExpression.body.isAsynchronous, isTrue);
    expect(functionExpression.body.isGenerator, isFalse);
    expect(functionExpression.parameters, isNotNull);
  }

  void test_parseExpression_function_asyncStar() {
    Expression expression = parseExpression('() async* {}');
    expect(expression, new isInstanceOf<FunctionExpression>());
    FunctionExpression functionExpression = expression;
    expect(functionExpression.body, isNotNull);
    expect(functionExpression.body.isAsynchronous, isTrue);
    expect(functionExpression.body.isGenerator, isTrue);
    expect(functionExpression.parameters, isNotNull);
  }

  void test_parseExpression_function_sync() {
    Expression expression = parseExpression('() {}');
    expect(expression, new isInstanceOf<FunctionExpression>());
    FunctionExpression functionExpression = expression;
    expect(functionExpression.body, isNotNull);
    expect(functionExpression.body.isAsynchronous, isFalse);
    expect(functionExpression.body.isGenerator, isFalse);
    expect(functionExpression.parameters, isNotNull);
  }

  void test_parseExpression_function_syncStar() {
    Expression expression = parseExpression('() sync* {}');
    expect(expression, new isInstanceOf<FunctionExpression>());
    FunctionExpression functionExpression = expression;
    expect(functionExpression.body, isNotNull);
    expect(functionExpression.body.isAsynchronous, isFalse);
    expect(functionExpression.body.isGenerator, isTrue);
    expect(functionExpression.parameters, isNotNull);
  }

  void test_parseExpression_invokeFunctionExpression() {
    Expression expression = parseExpression('(a) {return a + a;} (3)');
    expect(expression, new isInstanceOf<FunctionExpressionInvocation>());
    FunctionExpressionInvocation invocation = expression;
    expect(invocation.function, new isInstanceOf<FunctionExpression>());
    FunctionExpression functionExpression =
        invocation.function as FunctionExpression;
    expect(functionExpression.parameters, isNotNull);
    expect(functionExpression.body, isNotNull);
    expect(invocation.typeArguments, isNull);
    ArgumentList list = invocation.argumentList;
    expect(list, isNotNull);
    expect(list.arguments, hasLength(1));
  }

  void test_parseExpression_nonAwait() {
    Expression expression = parseExpression('await()');
    expect(expression, new isInstanceOf<MethodInvocation>());
    MethodInvocation invocation = expression;
    expect(invocation.methodName.name, 'await');
    expect(invocation.typeArguments, isNull);
    expect(invocation.argumentList, isNotNull);
  }

  void test_parseExpression_superMethodInvocation() {
    Expression expression = parseExpression('super.m()');
    expect(expression, new isInstanceOf<MethodInvocation>());
    MethodInvocation invocation = expression;
    expect(invocation.target, isNotNull);
    expect(invocation.methodName, isNotNull);
    expect(invocation.typeArguments, isNull);
    expect(invocation.argumentList, isNotNull);
  }

  void test_parseExpression_superMethodInvocation_typeArgumentComments() {
    enableGenericMethodComments = true;
    Expression expression = parseExpression('super.m/*<E>*/()');
    expect(expression, new isInstanceOf<MethodInvocation>());
    MethodInvocation invocation = expression;
    expect(invocation.target, isNotNull);
    expect(invocation.methodName, isNotNull);
    expect(invocation.typeArguments, isNotNull);
    expect(invocation.argumentList, isNotNull);
  }

  void test_parseExpression_superMethodInvocation_typeArguments() {
    Expression expression = parseExpression('super.m<E>()');
    expect(expression, new isInstanceOf<MethodInvocation>());
    MethodInvocation invocation = expression;
    expect(invocation.target, isNotNull);
    expect(invocation.methodName, isNotNull);
    expect(invocation.typeArguments, isNotNull);
    expect(invocation.argumentList, isNotNull);
  }

  void test_parseExpressionList_multiple() {
    createParser('1, 2, 3');
    List<Expression> result = parser.parseExpressionList();
    expectNotNullIfNoErrors(result);
    listener.assertNoErrors();
    expect(result, hasLength(3));
  }

  void test_parseExpressionList_single() {
    createParser('1');
    List<Expression> result = parser.parseExpressionList();
    expectNotNullIfNoErrors(result);
    listener.assertNoErrors();
    expect(result, hasLength(1));
  }

  void test_parseExpressionWithoutCascade_assign() {
    // TODO(brianwilkerson) Implement more tests for this method.
    createParser('x = y');
    Expression expression = parser.parseExpressionWithoutCascade();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<AssignmentExpression>());
    AssignmentExpression assignmentExpression = expression;
    expect(assignmentExpression.leftHandSide, isNotNull);
    expect(assignmentExpression.operator, isNotNull);
    expect(assignmentExpression.operator.type, TokenType.EQ);
    expect(assignmentExpression.rightHandSide, isNotNull);
  }

  void test_parseExpressionWithoutCascade_comparison() {
    createParser('--a.b == c');
    Expression expression = parser.parseExpressionWithoutCascade();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<BinaryExpression>());
    BinaryExpression binaryExpression = expression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.EQ_EQ);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseExpressionWithoutCascade_superMethodInvocation() {
    createParser('super.m()');
    Expression expression = parser.parseExpressionWithoutCascade();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<MethodInvocation>());
    MethodInvocation invocation = expression;
    expect(invocation.target, isNotNull);
    expect(invocation.methodName, isNotNull);
    expect(invocation.typeArguments, isNull);
    expect(invocation.argumentList, isNotNull);
  }

  void
      test_parseExpressionWithoutCascade_superMethodInvocation_typeArgumentComments() {
    enableGenericMethodComments = true;
    createParser('super.m/*<E>*/()');
    Expression expression = parser.parseExpressionWithoutCascade();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<MethodInvocation>());
    MethodInvocation invocation = expression;
    expect(invocation.target, isNotNull);
    expect(invocation.methodName, isNotNull);
    expect(invocation.typeArguments, isNotNull);
    expect(invocation.argumentList, isNotNull);
  }

  void
      test_parseExpressionWithoutCascade_superMethodInvocation_typeArguments() {
    createParser('super.m<E>()');
    Expression expression = parser.parseExpressionWithoutCascade();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<MethodInvocation>());
    MethodInvocation invocation = expression;
    expect(invocation.target, isNotNull);
    expect(invocation.methodName, isNotNull);
    expect(invocation.typeArguments, isNotNull);
    expect(invocation.argumentList, isNotNull);
  }

  void test_parseExtendsClause() {
    createParser('extends B');
    ExtendsClause clause = parser.parseExtendsClause();
    expectNotNullIfNoErrors(clause);
    listener.assertNoErrors();
    expect(clause.extendsKeyword, isNotNull);
    expect(clause.superclass, isNotNull);
    expect(clause.superclass, new isInstanceOf<TypeName>());
  }

  void test_parseFinalConstVarOrType_const_noType() {
    createParser('const');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    listener.assertNoErrors();
    Token keyword = result.keyword;
    expect(keyword, isNotNull);
    expect(keyword.type, TokenType.KEYWORD);
    expect(keyword.keyword, Keyword.CONST);
    expect(result.type, isNull);
  }

  void test_parseFinalConstVarOrType_const_type() {
    createParser('const A a');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    listener.assertNoErrors();
    Token keyword = result.keyword;
    expect(keyword, isNotNull);
    expect(keyword.type, TokenType.KEYWORD);
    expect(keyword.keyword, Keyword.CONST);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_final_noType() {
    createParser('final');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    listener.assertNoErrors();
    Token keyword = result.keyword;
    expect(keyword, isNotNull);
    expect(keyword.type, TokenType.KEYWORD);
    expect(keyword.keyword, Keyword.FINAL);
    expect(result.type, isNull);
  }

  void test_parseFinalConstVarOrType_final_prefixedType() {
    createParser('final p.A a');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    listener.assertNoErrors();
    Token keyword = result.keyword;
    expect(keyword, isNotNull);
    expect(keyword.type, TokenType.KEYWORD);
    expect(keyword.keyword, Keyword.FINAL);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_final_type() {
    createParser('final A a');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    listener.assertNoErrors();
    Token keyword = result.keyword;
    expect(keyword, isNotNull);
    expect(keyword.type, TokenType.KEYWORD);
    expect(keyword.keyword, Keyword.FINAL);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_type_parameterized() {
    createParser('A<B> a');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    listener.assertNoErrors();
    expect(result.keyword, isNull);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_type_prefixed() {
    createParser('p.A a');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    listener.assertNoErrors();
    expect(result.keyword, isNull);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_type_prefixed_noIdentifier() {
    createParser('p.A,');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    listener.assertNoErrors();
    expect(result.keyword, isNull);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_type_prefixedAndParameterized() {
    createParser('p.A<B> a');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    listener.assertNoErrors();
    expect(result.keyword, isNull);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_type_simple() {
    createParser('A a');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    listener.assertNoErrors();
    expect(result.keyword, isNull);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_var() {
    createParser('var');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    listener.assertNoErrors();
    Token keyword = result.keyword;
    expect(keyword, isNotNull);
    expect(keyword.type, TokenType.KEYWORD);
    expect(keyword.keyword, Keyword.VAR);
    expect(result.type, isNull);
  }

  void test_parseFinalConstVarOrType_void() {
    createParser('void f()');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    listener.assertNoErrors();
    expect(result.keyword, isNull);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_void_noIdentifier() {
    createParser('void,');
    FinalConstVarOrType result = parser.parseFinalConstVarOrType(false);
    expectNotNullIfNoErrors(result);
    listener.assertNoErrors();
    expect(result.keyword, isNull);
    expect(result.type, isNotNull);
  }

  void test_parseFormalParameter_final_withType_named() {
    ParameterKind kind = ParameterKind.NAMED;
    createParser('final A a : null');
    FormalParameter parameter = parser.parseFormalParameter(kind);
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<DefaultFormalParameter>());
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.kind, kind);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.kind, kind);
  }

  void test_parseFormalParameter_final_withType_normal() {
    ParameterKind kind = ParameterKind.REQUIRED;
    createParser('final A a');
    FormalParameter parameter = parser.parseFormalParameter(kind);
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<SimpleFormalParameter>());
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.kind, kind);
  }

  void test_parseFormalParameter_final_withType_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    createParser('final A a = null');
    FormalParameter parameter = parser.parseFormalParameter(kind);
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<DefaultFormalParameter>());
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.kind, kind);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.kind, kind);
  }

  void test_parseFormalParameter_nonFinal_withType_named() {
    ParameterKind kind = ParameterKind.NAMED;
    createParser('A a : null');
    FormalParameter parameter = parser.parseFormalParameter(kind);
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<DefaultFormalParameter>());
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.kind, kind);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.kind, kind);
  }

  void test_parseFormalParameter_nonFinal_withType_normal() {
    ParameterKind kind = ParameterKind.REQUIRED;
    createParser('A a');
    FormalParameter parameter = parser.parseFormalParameter(kind);
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<SimpleFormalParameter>());
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.kind, kind);
  }

  void test_parseFormalParameter_nonFinal_withType_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    createParser('A a = null');
    FormalParameter parameter = parser.parseFormalParameter(kind);
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<DefaultFormalParameter>());
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.kind, kind);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.kind, kind);
  }

  void test_parseFormalParameter_var() {
    ParameterKind kind = ParameterKind.REQUIRED;
    createParser('var a');
    FormalParameter parameter = parser.parseFormalParameter(kind);
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<SimpleFormalParameter>());
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.kind, kind);
  }

  void test_parseFormalParameter_var_named() {
    ParameterKind kind = ParameterKind.NAMED;
    createParser('var a : null');
    FormalParameter parameter = parser.parseFormalParameter(kind);
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<DefaultFormalParameter>());
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.kind, kind);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.kind, kind);
  }

  void test_parseFormalParameter_var_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    createParser('var a = null');
    FormalParameter parameter = parser.parseFormalParameter(kind);
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<DefaultFormalParameter>());
    DefaultFormalParameter defaultParameter = parameter;
    SimpleFormalParameter simpleParameter =
        defaultParameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.kind, kind);
    expect(defaultParameter.separator, isNotNull);
    expect(defaultParameter.defaultValue, isNotNull);
    expect(defaultParameter.kind, kind);
  }

  void test_parseFormalParameterList_empty() {
    createParser('()');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(0));
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_named_multiple() {
    createParser('({A a : 1, B b, C c : 3})');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.parameters, hasLength(3));
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_named_single() {
    createParser('({A a})');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.parameters, hasLength(1));
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_named_trailing_comma() {
    createParser('(A a, {B b,})');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.parameters, hasLength(2));
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_normal_multiple() {
    createParser('(A a, B b, C c)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(3));
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_normal_named() {
    createParser('(A a, {B b})');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.parameters, hasLength(2));
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_normal_positional() {
    createParser('(A a, [B b])');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.parameters, hasLength(2));
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_normal_single() {
    createParser('(A a)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(1));
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_normal_single_trailing_comma() {
    createParser('(A a,)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(1));
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_positional_multiple() {
    createParser('([A a = null, B b, C c = null])');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.parameters, hasLength(3));
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_positional_single() {
    createParser('([A a = null])');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.parameters, hasLength(1));
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_positional_trailing_comma() {
    createParser('(A a, [B b,])');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNotNull);
    expect(list.parameters, hasLength(2));
    expect(list.rightDelimiter, isNotNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_prefixedType() {
    createParser('(io.File f)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertNoErrors();
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(1));
    expect(list.parameters[0].toSource(), 'io.File f');
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_prefixedType_partial() {
    createParser('(io.)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrorsWithCodes([
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(1));
    expect(list.parameters[0].toSource(), 'io. ');
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_prefixedType_partial2() {
    createParser('(io.,a)');
    FormalParameterList list = parser.parseFormalParameterList();
    expectNotNullIfNoErrors(list);
    listener.assertErrorsWithCodes([
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
    expect(list.leftParenthesis, isNotNull);
    expect(list.leftDelimiter, isNull);
    expect(list.parameters, hasLength(2));
    expect(list.parameters[0].toSource(), 'io. ');
    expect(list.parameters[1].toSource(), 'a');
    expect(list.rightDelimiter, isNull);
    expect(list.rightParenthesis, isNotNull);
  }

  void test_parseForStatement_each_await() {
    createParser('await for (element in list) {}');
    Statement statement = parser.parseForStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ForEachStatement>());
    ForEachStatement forStatement = statement;
    expect(forStatement.awaitKeyword, isNotNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    expect(forStatement.loopVariable, isNull);
    expect(forStatement.identifier, isNotNull);
    expect(forStatement.inKeyword, isNotNull);
    expect(forStatement.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_identifier() {
    createParser('for (element in list) {}');
    Statement statement = parser.parseForStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ForEachStatement>());
    ForEachStatement forStatement = statement;
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    expect(forStatement.loopVariable, isNull);
    expect(forStatement.identifier, isNotNull);
    expect(forStatement.inKeyword, isNotNull);
    expect(forStatement.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_noType_metadata() {
    createParser('for (@A var element in list) {}');
    Statement statement = parser.parseForStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ForEachStatement>());
    ForEachStatement forStatement = statement;
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    expect(forStatement.loopVariable, isNotNull);
    expect(forStatement.loopVariable.metadata, hasLength(1));
    expect(forStatement.identifier, isNull);
    expect(forStatement.inKeyword, isNotNull);
    expect(forStatement.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_type() {
    createParser('for (A element in list) {}');
    Statement statement = parser.parseForStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ForEachStatement>());
    ForEachStatement forStatement = statement;
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    expect(forStatement.loopVariable, isNotNull);
    expect(forStatement.identifier, isNull);
    expect(forStatement.inKeyword, isNotNull);
    expect(forStatement.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_each_var() {
    createParser('for (var element in list) {}');
    Statement statement = parser.parseForStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ForEachStatement>());
    ForEachStatement forStatement = statement;
    expect(forStatement.awaitKeyword, isNull);
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    expect(forStatement.loopVariable, isNotNull);
    expect(forStatement.identifier, isNull);
    expect(forStatement.inKeyword, isNotNull);
    expect(forStatement.iterable, isNotNull);
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_c() {
    createParser('for (; i < count;) {}');
    Statement statement = parser.parseForStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ForStatement>());
    ForStatement forStatement = statement;
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    expect(forStatement.variables, isNull);
    expect(forStatement.initialization, isNull);
    expect(forStatement.leftSeparator, isNotNull);
    expect(forStatement.condition, isNotNull);
    expect(forStatement.rightSeparator, isNotNull);
    expect(forStatement.updaters, hasLength(0));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_cu() {
    createParser('for (; i < count; i++) {}');
    Statement statement = parser.parseForStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ForStatement>());
    ForStatement forStatement = statement;
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    expect(forStatement.variables, isNull);
    expect(forStatement.initialization, isNull);
    expect(forStatement.leftSeparator, isNotNull);
    expect(forStatement.condition, isNotNull);
    expect(forStatement.rightSeparator, isNotNull);
    expect(forStatement.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_ecu() {
    createParser('for (i--; i < count; i++) {}');
    Statement statement = parser.parseForStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ForStatement>());
    ForStatement forStatement = statement;
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    expect(forStatement.variables, isNull);
    expect(forStatement.initialization, isNotNull);
    expect(forStatement.leftSeparator, isNotNull);
    expect(forStatement.condition, isNotNull);
    expect(forStatement.rightSeparator, isNotNull);
    expect(forStatement.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_i() {
    createParser('for (var i = 0;;) {}');
    Statement statement = parser.parseForStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ForStatement>());
    ForStatement forStatement = statement;
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    VariableDeclarationList variables = forStatement.variables;
    expect(variables, isNotNull);
    expect(variables.metadata, hasLength(0));
    expect(variables.variables, hasLength(1));
    expect(forStatement.initialization, isNull);
    expect(forStatement.leftSeparator, isNotNull);
    expect(forStatement.condition, isNull);
    expect(forStatement.rightSeparator, isNotNull);
    expect(forStatement.updaters, hasLength(0));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_i_withMetadata() {
    createParser('for (@A var i = 0;;) {}');
    Statement statement = parser.parseForStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ForStatement>());
    ForStatement forStatement = statement;
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    VariableDeclarationList variables = forStatement.variables;
    expect(variables, isNotNull);
    expect(variables.metadata, hasLength(1));
    expect(variables.variables, hasLength(1));
    expect(forStatement.initialization, isNull);
    expect(forStatement.leftSeparator, isNotNull);
    expect(forStatement.condition, isNull);
    expect(forStatement.rightSeparator, isNotNull);
    expect(forStatement.updaters, hasLength(0));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_ic() {
    createParser('for (var i = 0; i < count;) {}');
    Statement statement = parser.parseForStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ForStatement>());
    ForStatement forStatement = statement;
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    VariableDeclarationList variables = forStatement.variables;
    expect(variables, isNotNull);
    expect(variables.variables, hasLength(1));
    expect(forStatement.initialization, isNull);
    expect(forStatement.leftSeparator, isNotNull);
    expect(forStatement.condition, isNotNull);
    expect(forStatement.rightSeparator, isNotNull);
    expect(forStatement.updaters, hasLength(0));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_icu() {
    createParser('for (var i = 0; i < count; i++) {}');
    Statement statement = parser.parseForStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ForStatement>());
    ForStatement forStatement = statement;
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    VariableDeclarationList variables = forStatement.variables;
    expect(variables, isNotNull);
    expect(variables.variables, hasLength(1));
    expect(forStatement.initialization, isNull);
    expect(forStatement.leftSeparator, isNotNull);
    expect(forStatement.condition, isNotNull);
    expect(forStatement.rightSeparator, isNotNull);
    expect(forStatement.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_iicuu() {
    createParser('for (int i = 0, j = count; i < j; i++, j--) {}');
    Statement statement = parser.parseForStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ForStatement>());
    ForStatement forStatement = statement;
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    VariableDeclarationList variables = forStatement.variables;
    expect(variables, isNotNull);
    expect(variables.variables, hasLength(2));
    expect(forStatement.initialization, isNull);
    expect(forStatement.leftSeparator, isNotNull);
    expect(forStatement.condition, isNotNull);
    expect(forStatement.rightSeparator, isNotNull);
    expect(forStatement.updaters, hasLength(2));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_iu() {
    createParser('for (var i = 0;; i++) {}');
    Statement statement = parser.parseForStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ForStatement>());
    ForStatement forStatement = statement;
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    VariableDeclarationList variables = forStatement.variables;
    expect(variables, isNotNull);
    expect(variables.variables, hasLength(1));
    expect(forStatement.initialization, isNull);
    expect(forStatement.leftSeparator, isNotNull);
    expect(forStatement.condition, isNull);
    expect(forStatement.rightSeparator, isNotNull);
    expect(forStatement.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseForStatement_loop_u() {
    createParser('for (;; i++) {}');
    Statement statement = parser.parseForStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ForStatement>());
    ForStatement forStatement = statement;
    expect(forStatement.forKeyword, isNotNull);
    expect(forStatement.leftParenthesis, isNotNull);
    expect(forStatement.variables, isNull);
    expect(forStatement.initialization, isNull);
    expect(forStatement.leftSeparator, isNotNull);
    expect(forStatement.condition, isNull);
    expect(forStatement.rightSeparator, isNotNull);
    expect(forStatement.updaters, hasLength(1));
    expect(forStatement.rightParenthesis, isNotNull);
    expect(forStatement.body, isNotNull);
  }

  void test_parseFunctionBody_block() {
    createParser('{}');
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    listener.assertNoErrors();
    expect(functionBody, new isInstanceOf<BlockFunctionBody>());
    BlockFunctionBody body = functionBody;
    expect(body.keyword, isNull);
    expect(body.star, isNull);
    expect(body.block, isNotNull);
    expect(body.isAsynchronous, isFalse);
    expect(body.isGenerator, isFalse);
    expect(body.isSynchronous, isTrue);
  }

  void test_parseFunctionBody_block_async() {
    createParser('async {}');
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    listener.assertNoErrors();
    expect(functionBody, new isInstanceOf<BlockFunctionBody>());
    BlockFunctionBody body = functionBody;
    expect(body.keyword, isNotNull);
    expect(body.keyword.lexeme, Parser.ASYNC);
    expect(body.star, isNull);
    expect(body.block, isNotNull);
    expect(body.isAsynchronous, isTrue);
    expect(body.isGenerator, isFalse);
    expect(body.isSynchronous, isFalse);
  }

  void test_parseFunctionBody_block_asyncGenerator() {
    createParser('async* {}');
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    listener.assertNoErrors();
    expect(functionBody, new isInstanceOf<BlockFunctionBody>());
    BlockFunctionBody body = functionBody;
    expect(body.keyword, isNotNull);
    expect(body.keyword.lexeme, Parser.ASYNC);
    expect(body.star, isNotNull);
    expect(body.block, isNotNull);
    expect(body.isAsynchronous, isTrue);
    expect(body.isGenerator, isTrue);
    expect(body.isSynchronous, isFalse);
  }

  void test_parseFunctionBody_block_syncGenerator() {
    createParser('sync* {}');
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    listener.assertNoErrors();
    expect(functionBody, new isInstanceOf<BlockFunctionBody>());
    BlockFunctionBody body = functionBody;
    expect(body.keyword, isNotNull);
    expect(body.keyword.lexeme, Parser.SYNC);
    expect(body.star, isNotNull);
    expect(body.block, isNotNull);
    expect(body.isAsynchronous, isFalse);
    expect(body.isGenerator, isTrue);
    expect(body.isSynchronous, isTrue);
  }

  void test_parseFunctionBody_empty() {
    createParser(';');
    FunctionBody functionBody = parser.parseFunctionBody(true, null, false);
    expectNotNullIfNoErrors(functionBody);
    listener.assertNoErrors();
    expect(functionBody, new isInstanceOf<EmptyFunctionBody>());
    EmptyFunctionBody body = functionBody;
    expect(body.semicolon, isNotNull);
  }

  void test_parseFunctionBody_expression() {
    createParser('=> y;');
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    listener.assertNoErrors();
    expect(functionBody, new isInstanceOf<ExpressionFunctionBody>());
    ExpressionFunctionBody body = functionBody;
    expect(body.keyword, isNull);
    expect(body.functionDefinition, isNotNull);
    expect(body.expression, isNotNull);
    expect(body.semicolon, isNotNull);
    expect(body.isAsynchronous, isFalse);
    expect(body.isGenerator, isFalse);
    expect(body.isSynchronous, isTrue);
  }

  void test_parseFunctionBody_expression_async() {
    createParser('async => y;');
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    listener.assertNoErrors();
    expect(functionBody, new isInstanceOf<ExpressionFunctionBody>());
    ExpressionFunctionBody body = functionBody;
    expect(body.keyword, isNotNull);
    expect(body.keyword.lexeme, Parser.ASYNC);
    expect(body.functionDefinition, isNotNull);
    expect(body.expression, isNotNull);
    expect(body.semicolon, isNotNull);
    expect(body.isAsynchronous, isTrue);
    expect(body.isGenerator, isFalse);
    expect(body.isSynchronous, isFalse);
  }

  void test_parseFunctionBody_nativeFunctionBody() {
    createParser('native "str";');
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    listener.assertNoErrors();
    expect(functionBody, new isInstanceOf<NativeFunctionBody>());
    NativeFunctionBody body = functionBody;
    expect(body.nativeKeyword, isNotNull);
    expect(body.stringLiteral, isNotNull);
    expect(body.semicolon, isNotNull);
  }

  void test_parseFunctionBody_skip_block() {
    ParserTestCase.parseFunctionBodies = false;
    createParser('{}');
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    listener.assertNoErrors();
    expect(functionBody, new isInstanceOf<EmptyFunctionBody>());
  }

  void test_parseFunctionBody_skip_block_invalid() {
    ParserTestCase.parseFunctionBodies = false;
    createParser('{');
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    listener.assertErrorsWithCodes([ParserErrorCode.EXPECTED_TOKEN]);
    expect(functionBody, new isInstanceOf<EmptyFunctionBody>());
  }

  void test_parseFunctionBody_skip_blocks() {
    ParserTestCase.parseFunctionBodies = false;
    createParser('{ {} }');
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    listener.assertNoErrors();
    expect(functionBody, new isInstanceOf<EmptyFunctionBody>());
  }

  void test_parseFunctionBody_skip_expression() {
    ParserTestCase.parseFunctionBodies = false;
    createParser('=> y;');
    FunctionBody functionBody = parser.parseFunctionBody(false, null, false);
    expectNotNullIfNoErrors(functionBody);
    listener.assertNoErrors();
    expect(functionBody, new isInstanceOf<EmptyFunctionBody>());
  }

  void test_parseFunctionDeclaration_function() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    TypeName returnType = new TypeName(new SimpleIdentifier(null), null);
    createParser('f() {}');
    FunctionDeclaration declaration = parser.parseFunctionDeclaration(
        commentAndMetadata(comment), null, returnType);
    expectNotNullIfNoErrors(declaration);
    listener.assertNoErrors();
    expect(declaration.documentationComment, comment);
    expect(declaration.returnType, returnType);
    expect(declaration.name, isNotNull);
    FunctionExpression expression = declaration.functionExpression;
    expect(expression, isNotNull);
    expect(expression.body, isNotNull);
    expect(expression.typeParameters, isNull);
    expect(expression.parameters, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseFunctionDeclaration_functionWithTypeParameters() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    TypeName returnType = new TypeName(new SimpleIdentifier(null), null);
    createParser('f<E>() {}');
    FunctionDeclaration declaration = parser.parseFunctionDeclaration(
        commentAndMetadata(comment), null, returnType);
    expectNotNullIfNoErrors(declaration);
    listener.assertNoErrors();
    expect(declaration.documentationComment, comment);
    expect(declaration.returnType, returnType);
    expect(declaration.name, isNotNull);
    FunctionExpression expression = declaration.functionExpression;
    expect(expression, isNotNull);
    expect(expression.body, isNotNull);
    expect(expression.typeParameters, isNotNull);
    expect(expression.parameters, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseFunctionDeclaration_functionWithTypeParameters_comment() {
    enableGenericMethodComments = true;
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    TypeName returnType = new TypeName(new SimpleIdentifier(null), null);
    createParser('f/*<E>*/() {}');
    FunctionDeclaration declaration = parser.parseFunctionDeclaration(
        commentAndMetadata(comment), null, returnType);
    expectNotNullIfNoErrors(declaration);
    listener.assertNoErrors();
    expect(declaration.documentationComment, comment);
    expect(declaration.returnType, returnType);
    expect(declaration.name, isNotNull);
    FunctionExpression expression = declaration.functionExpression;
    expect(expression, isNotNull);
    expect(expression.body, isNotNull);
    expect(expression.typeParameters, isNotNull);
    expect(expression.parameters, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseFunctionDeclaration_getter() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    TypeName returnType = new TypeName(new SimpleIdentifier(null), null);
    createParser('get p => 0;');
    FunctionDeclaration declaration = parser.parseFunctionDeclaration(
        commentAndMetadata(comment), null, returnType);
    expectNotNullIfNoErrors(declaration);
    listener.assertNoErrors();
    expect(declaration.documentationComment, comment);
    expect(declaration.returnType, returnType);
    expect(declaration.name, isNotNull);
    FunctionExpression expression = declaration.functionExpression;
    expect(expression, isNotNull);
    expect(expression.body, isNotNull);
    expect(expression.typeParameters, isNull);
    expect(expression.parameters, isNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseFunctionDeclaration_setter() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    TypeName returnType = new TypeName(new SimpleIdentifier(null), null);
    createParser('set p(v) {}');
    FunctionDeclaration declaration = parser.parseFunctionDeclaration(
        commentAndMetadata(comment), null, returnType);
    expectNotNullIfNoErrors(declaration);
    listener.assertNoErrors();
    expect(declaration.documentationComment, comment);
    expect(declaration.returnType, returnType);
    expect(declaration.name, isNotNull);
    FunctionExpression expression = declaration.functionExpression;
    expect(expression, isNotNull);
    expect(expression.body, isNotNull);
    expect(expression.typeParameters, isNull);
    expect(expression.parameters, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseFunctionDeclarationStatement() {
    createParser('void f(int p) => p * 2;');
    FunctionDeclarationStatement statement =
        parser.parseFunctionDeclarationStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.functionDeclaration, isNotNull);
  }

  void test_parseFunctionDeclarationStatement_typeParameterComments() {
    enableGenericMethodComments = true;
    createParser('/*=E*/ f/*<E>*/(/*=E*/ p) => p * 2;');
    FunctionDeclarationStatement statement =
        parser.parseFunctionDeclarationStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    FunctionDeclaration f = statement.functionDeclaration;
    expect(f, isNotNull);
    expect(f.functionExpression.typeParameters, isNotNull);
    expect(f.returnType, isNotNull);
    SimpleFormalParameter p = f.functionExpression.parameters.parameters[0];
    expect(p.type, isNotNull);
  }

  void test_parseFunctionDeclarationStatement_typeParameters() {
    createParser('E f<E>(E p) => p * 2;');
    FunctionDeclarationStatement statement =
        parser.parseFunctionDeclarationStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.functionDeclaration, isNotNull);
    expect(statement.functionDeclaration.functionExpression.typeParameters,
        isNotNull);
  }

  void test_parseFunctionDeclarationStatement_typeParameters_noReturnType() {
    createParser('f<E>(E p) => p * 2;');
    FunctionDeclarationStatement statement =
        parser.parseFunctionDeclarationStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.functionDeclaration, isNotNull);
    expect(statement.functionDeclaration.functionExpression.typeParameters,
        isNotNull);
  }

  void test_parseFunctionExpression_body_inExpression() {
    createParser('(int i) => i++');
    FunctionExpression expression = parser.parseFunctionExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.body, isNotNull);
    expect(expression.typeParameters, isNull);
    expect(expression.parameters, isNotNull);
    expect((expression.body as ExpressionFunctionBody).semicolon, isNull);
  }

  void test_parseFunctionExpression_typeParameterComments() {
    enableGenericMethodComments = true;
    createParser('/*<E>*/(/*=E*/ i) => i++');
    FunctionExpression expression = parser.parseFunctionExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.body, isNotNull);
    expect(expression.typeParameters, isNotNull);
    expect(expression.parameters, isNotNull);
    expect((expression.body as ExpressionFunctionBody).semicolon, isNull);
    SimpleFormalParameter p = expression.parameters.parameters[0];
    expect(p.type, isNotNull);
  }

  void test_parseFunctionExpression_typeParameters() {
    createParser('<E>(E i) => i++');
    FunctionExpression expression = parser.parseFunctionExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.body, isNotNull);
    expect(expression.typeParameters, isNotNull);
    expect(expression.parameters, isNotNull);
    expect((expression.body as ExpressionFunctionBody).semicolon, isNull);
  }

  void test_parseGetter_nonStatic() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    TypeName returnType = new TypeName(new SimpleIdentifier(null), null);
    createParser('get a;');
    MethodDeclaration method =
        parser.parseGetter(commentAndMetadata(comment), null, null, returnType);
    expectNotNullIfNoErrors(method);
    listener.assertNoErrors();
    expect(method.body, isNotNull);
    expect(method.documentationComment, comment);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.parameters, isNull);
    expect(method.propertyKeyword, isNotNull);
    expect(method.returnType, returnType);
  }

  void test_parseGetter_static() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    Token staticKeyword = TokenFactory.tokenFromKeyword(Keyword.STATIC);
    TypeName returnType = new TypeName(new SimpleIdentifier(null), null);
    createParser('get a => 42;');
    MethodDeclaration method = parser.parseGetter(
        commentAndMetadata(comment), null, staticKeyword, returnType);
    expectNotNullIfNoErrors(method);
    listener.assertNoErrors();
    expect(method.body, isNotNull);
    expect(method.documentationComment, comment);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, staticKeyword);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNull);
    expect(method.propertyKeyword, isNotNull);
    expect(method.returnType, returnType);
  }

  void test_parseIdentifierList_multiple() {
    createParser('a, b, c');
    List<SimpleIdentifier> list = parser.parseIdentifierList();
    expectNotNullIfNoErrors(list);
    listener.assertNoErrors();
    expect(list, hasLength(3));
  }

  void test_parseIdentifierList_single() {
    createParser('a');
    List<SimpleIdentifier> list = parser.parseIdentifierList();
    expectNotNullIfNoErrors(list);
    listener.assertNoErrors();
    expect(list, hasLength(1));
  }

  void test_parseIfStatement_else_block() {
    createParser('if (x) {} else {}');
    IfStatement statement = parser.parseIfStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.ifKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.thenStatement, isNotNull);
    expect(statement.elseKeyword, isNotNull);
    expect(statement.elseStatement, isNotNull);
  }

  void test_parseIfStatement_else_statement() {
    createParser('if (x) f(x); else f(y);');
    IfStatement statement = parser.parseIfStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.ifKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.thenStatement, isNotNull);
    expect(statement.elseKeyword, isNotNull);
    expect(statement.elseStatement, isNotNull);
  }

  void test_parseIfStatement_noElse_block() {
    createParser('if (x) {}');
    IfStatement statement = parser.parseIfStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.ifKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.thenStatement, isNotNull);
    expect(statement.elseKeyword, isNull);
    expect(statement.elseStatement, isNull);
  }

  void test_parseIfStatement_noElse_statement() {
    createParser('if (x) f(x);');
    IfStatement statement = parser.parseIfStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.ifKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.thenStatement, isNotNull);
    expect(statement.elseKeyword, isNull);
    expect(statement.elseStatement, isNull);
  }

  void test_parseImplementsClause_multiple() {
    createParser('implements A, B, C');
    ImplementsClause clause = parser.parseImplementsClause();
    expectNotNullIfNoErrors(clause);
    listener.assertNoErrors();
    expect(clause.interfaces, hasLength(3));
    expect(clause.implementsKeyword, isNotNull);
  }

  void test_parseImplementsClause_single() {
    createParser('implements A');
    ImplementsClause clause = parser.parseImplementsClause();
    expectNotNullIfNoErrors(clause);
    listener.assertNoErrors();
    expect(clause.interfaces, hasLength(1));
    expect(clause.implementsKeyword, isNotNull);
  }

  void test_parseImportDirective_configuration_multiple() {
    createParser("import 'lib/lib.dart' if (a) 'b.dart' if (c) 'd.dart';");
    ImportDirective directive =
        parser.parseImportDirective(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(directive);
    listener.assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.configurations, hasLength(2));
    _expectDottedName(directive.configurations[0].name, ['a']);
    _expectDottedName(directive.configurations[1].name, ['c']);
    expect(directive.deferredKeyword, isNull);
    expect(directive.asKeyword, isNull);
    expect(directive.prefix, isNull);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_configuration_single() {
    createParser("import 'lib/lib.dart' if (a.b == 'c.dart') '';");
    ImportDirective directive =
        parser.parseImportDirective(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(directive);
    listener.assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.configurations, hasLength(1));
    _expectDottedName(directive.configurations[0].name, ['a', 'b']);
    expect(directive.deferredKeyword, isNull);
    expect(directive.asKeyword, isNull);
    expect(directive.prefix, isNull);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_deferred() {
    createParser("import 'lib/lib.dart' deferred as a;");
    ImportDirective directive =
        parser.parseImportDirective(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(directive);
    listener.assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredKeyword, isNotNull);
    expect(directive.asKeyword, isNotNull);
    expect(directive.prefix, isNotNull);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_hide() {
    createParser("import 'lib/lib.dart' hide A, B;");
    ImportDirective directive =
        parser.parseImportDirective(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(directive);
    listener.assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredKeyword, isNull);
    expect(directive.asKeyword, isNull);
    expect(directive.prefix, isNull);
    expect(directive.combinators, hasLength(1));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_noCombinator() {
    createParser("import 'lib/lib.dart';");
    ImportDirective directive =
        parser.parseImportDirective(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(directive);
    listener.assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredKeyword, isNull);
    expect(directive.asKeyword, isNull);
    expect(directive.prefix, isNull);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_prefix() {
    createParser("import 'lib/lib.dart' as a;");
    ImportDirective directive =
        parser.parseImportDirective(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(directive);
    listener.assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredKeyword, isNull);
    expect(directive.asKeyword, isNotNull);
    expect(directive.prefix, isNotNull);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_prefix_hide_show() {
    createParser("import 'lib/lib.dart' as a hide A show B;");
    ImportDirective directive =
        parser.parseImportDirective(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(directive);
    listener.assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredKeyword, isNull);
    expect(directive.asKeyword, isNotNull);
    expect(directive.prefix, isNotNull);
    expect(directive.combinators, hasLength(2));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_prefix_show_hide() {
    createParser("import 'lib/lib.dart' as a show B hide A;");
    ImportDirective directive =
        parser.parseImportDirective(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(directive);
    listener.assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredKeyword, isNull);
    expect(directive.asKeyword, isNotNull);
    expect(directive.prefix, isNotNull);
    expect(directive.combinators, hasLength(2));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_show() {
    createParser("import 'lib/lib.dart' show A, B;");
    ImportDirective directive =
        parser.parseImportDirective(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(directive);
    listener.assertNoErrors();
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredKeyword, isNull);
    expect(directive.asKeyword, isNull);
    expect(directive.prefix, isNull);
    expect(directive.combinators, hasLength(1));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseInitializedIdentifierList_type() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    Token staticKeyword = TokenFactory.tokenFromKeyword(Keyword.STATIC);
    TypeName type = new TypeName(new SimpleIdentifier(null), null);
    createParser("a = 1, b, c = 3;");
    FieldDeclaration declaration = parser.parseInitializedIdentifierList(
        commentAndMetadata(comment), staticKeyword, null, type);
    expectNotNullIfNoErrors(declaration);
    listener.assertNoErrors();
    expect(declaration.documentationComment, comment);
    VariableDeclarationList fields = declaration.fields;
    expect(fields, isNotNull);
    expect(fields.keyword, isNull);
    expect(fields.type, type);
    expect(fields.variables, hasLength(3));
    expect(declaration.staticKeyword, staticKeyword);
    expect(declaration.semicolon, isNotNull);
  }

  void test_parseInitializedIdentifierList_var() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    Token staticKeyword = TokenFactory.tokenFromKeyword(Keyword.STATIC);
    Token varKeyword = TokenFactory.tokenFromKeyword(Keyword.VAR);
    createParser('a = 1, b, c = 3;');
    FieldDeclaration declaration = parser.parseInitializedIdentifierList(
        commentAndMetadata(comment), staticKeyword, varKeyword, null);
    expectNotNullIfNoErrors(declaration);
    listener.assertNoErrors();
    expect(declaration.documentationComment, comment);
    VariableDeclarationList fields = declaration.fields;
    expect(fields, isNotNull);
    expect(fields.keyword, varKeyword);
    expect(fields.type, isNull);
    expect(fields.variables, hasLength(3));
    expect(declaration.staticKeyword, staticKeyword);
    expect(declaration.semicolon, isNotNull);
  }

  void test_parseInstanceCreationExpression_qualifiedType() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    createParser('A.B()');
    InstanceCreationExpression expression =
        parser.parseInstanceCreationExpression(token);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.keyword, token);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    TypeName type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments, isNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseInstanceCreationExpression_qualifiedType_named() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    createParser('A.B.c()');
    InstanceCreationExpression expression =
        parser.parseInstanceCreationExpression(token);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.keyword, token);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    TypeName type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments, isNull);
    expect(name.period, isNotNull);
    expect(name.name, isNotNull);
    expect(expression.argumentList, isNotNull);
  }

  void
      test_parseInstanceCreationExpression_qualifiedType_named_typeParameterComment() {
    enableGenericMethodComments = true;
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    createParser('A.B/*<E>*/.c()');
    InstanceCreationExpression expression =
        parser.parseInstanceCreationExpression(token);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.keyword, token);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    TypeName type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments.arguments, hasLength(1));
    expect(name.period, isNotNull);
    expect(name.name, isNotNull);
    expect(expression.argumentList, isNotNull);
  }

  void
      test_parseInstanceCreationExpression_qualifiedType_named_typeParameters() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    createParser('A.B<E>.c()');
    InstanceCreationExpression expression =
        parser.parseInstanceCreationExpression(token);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.keyword, token);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    TypeName type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments.arguments, hasLength(1));
    expect(name.period, isNotNull);
    expect(name.name, isNotNull);
    expect(expression.argumentList, isNotNull);
  }

  void
      test_parseInstanceCreationExpression_qualifiedType_typeParameterComment() {
    enableGenericMethodComments = true;
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    createParser('A.B/*<E>*/()');
    InstanceCreationExpression expression =
        parser.parseInstanceCreationExpression(token);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.keyword, token);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    TypeName type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments.arguments, hasLength(1));
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseInstanceCreationExpression_qualifiedType_typeParameters() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    createParser('A.B<E>()');
    InstanceCreationExpression expression =
        parser.parseInstanceCreationExpression(token);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.keyword, token);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    TypeName type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments.arguments, hasLength(1));
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseInstanceCreationExpression_type() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    createParser('A()');
    InstanceCreationExpression expression =
        parser.parseInstanceCreationExpression(token);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.keyword, token);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    TypeName type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments, isNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseInstanceCreationExpression_type_named() {
    enableGenericMethodComments = true;
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    createParser('A.c()');
    InstanceCreationExpression expression =
        parser.parseInstanceCreationExpression(token);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.keyword, token);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    TypeName type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments, isNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseInstanceCreationExpression_type_named_typeParameterComment() {
    enableGenericMethodComments = true;
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    createParser('A/*<B>*/.c()');
    InstanceCreationExpression expression =
        parser.parseInstanceCreationExpression(token);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.keyword, token);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    TypeName type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments.arguments, hasLength(1));
    expect(name.period, isNotNull);
    expect(name.name, isNotNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseInstanceCreationExpression_type_named_typeParameters() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    createParser('A<B>.c()');
    InstanceCreationExpression expression =
        parser.parseInstanceCreationExpression(token);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.keyword, token);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    TypeName type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments.arguments, hasLength(1));
    expect(name.period, isNotNull);
    expect(name.name, isNotNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseInstanceCreationExpression_type_typeParameterComment() {
    enableGenericMethodComments = true;
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    createParser('A/*<B>*/()');
    InstanceCreationExpression expression =
        parser.parseInstanceCreationExpression(token);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.keyword, token);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    TypeName type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments.arguments, hasLength(1));
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseInstanceCreationExpression_type_typeParameters() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    createParser('A<B>()');
    InstanceCreationExpression expression =
        parser.parseInstanceCreationExpression(token);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.keyword, token);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    TypeName type = name.type;
    expect(type, isNotNull);
    expect(type.typeArguments.arguments, hasLength(1));
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseInstanceCreationExpression_type_typeParameters_nullable() {
    enableNnbd = true;
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    createParser('A<B?>()');
    InstanceCreationExpression expression =
        parser.parseInstanceCreationExpression(token);
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.keyword, token);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    TypeName type = name.type;
    expect(type, isNotNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
    NodeList<TypeName> arguments = type.typeArguments.arguments;
    expect(arguments, hasLength(1));
    expect(arguments[0].question, isNotNull);
  }

  void test_parseLibraryDirective() {
    createParser('library l;');
    LibraryDirective directive =
        parser.parseLibraryDirective(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(directive);
    listener.assertNoErrors();
    expect(directive.libraryKeyword, isNotNull);
    expect(directive.name, isNotNull);
    expect(directive.semicolon, isNotNull);
  }

  void test_parseLibraryIdentifier_multiple() {
    String name = "a.b.c";
    createParser(name);
    LibraryIdentifier identifier = parser.parseLibraryIdentifier();
    expectNotNullIfNoErrors(identifier);
    listener.assertNoErrors();
    expect(identifier.name, name);
  }

  void test_parseLibraryIdentifier_single() {
    String name = "a";
    createParser(name);
    LibraryIdentifier identifier = parser.parseLibraryIdentifier();
    expectNotNullIfNoErrors(identifier);
    listener.assertNoErrors();
    expect(identifier.name, name);
  }

  void test_parseListLiteral_empty_oneToken() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.CONST);
    TypeArgumentList typeArguments = null;
    createParser('[]');
    ListLiteral literal = parser.parseListLiteral(token, typeArguments);
    expectNotNullIfNoErrors(literal);
    listener.assertNoErrors();
    expect(literal.constKeyword, token);
    expect(literal.typeArguments, typeArguments);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseListLiteral_empty_oneToken_withComment() {
    Token token = null;
    TypeArgumentList typeArguments = null;
    createParser('/* 0 */ []');
    ListLiteral literal = parser.parseListLiteral(token, typeArguments);
    expectNotNullIfNoErrors(literal);
    listener.assertNoErrors();
    expect(literal.constKeyword, token);
    expect(literal.typeArguments, typeArguments);
    Token leftBracket = literal.leftBracket;
    expect(leftBracket, isNotNull);
    expect(leftBracket.precedingComments, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseListLiteral_empty_twoTokens() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.CONST);
    TypeArgumentList typeArguments = null;
    createParser('[ ]');
    ListLiteral literal = parser.parseListLiteral(token, typeArguments);
    expectNotNullIfNoErrors(literal);
    listener.assertNoErrors();
    expect(literal.constKeyword, token);
    expect(literal.typeArguments, typeArguments);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseListLiteral_multiple() {
    createParser('[1, 2, 3]');
    ListLiteral literal = parser.parseListLiteral(null, null);
    expectNotNullIfNoErrors(literal);
    listener.assertNoErrors();
    expect(literal.constKeyword, isNull);
    expect(literal.typeArguments, isNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(3));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseListLiteral_single() {
    createParser('[1]');
    ListLiteral literal = parser.parseListLiteral(null, null);
    expectNotNullIfNoErrors(literal);
    listener.assertNoErrors();
    expect(literal.constKeyword, isNull);
    expect(literal.typeArguments, isNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(1));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseListOrMapLiteral_list_noType() {
    createParser('[1]');
    TypedLiteral literal = parser.parseListOrMapLiteral(null);
    expectNotNullIfNoErrors(literal);
    listener.assertNoErrors();
    expect(literal, new isInstanceOf<ListLiteral>());
    ListLiteral listLiteral = literal;
    expect(listLiteral.constKeyword, isNull);
    expect(listLiteral.typeArguments, isNull);
    expect(listLiteral.leftBracket, isNotNull);
    expect(listLiteral.elements, hasLength(1));
    expect(listLiteral.rightBracket, isNotNull);
  }

  void test_parseListOrMapLiteral_list_type() {
    createParser('<int> [1]');
    TypedLiteral literal = parser.parseListOrMapLiteral(null);
    expectNotNullIfNoErrors(literal);
    listener.assertNoErrors();
    expect(literal, new isInstanceOf<ListLiteral>());
    ListLiteral listLiteral = literal;
    expect(listLiteral.constKeyword, isNull);
    expect(listLiteral.typeArguments, isNotNull);
    expect(listLiteral.leftBracket, isNotNull);
    expect(listLiteral.elements, hasLength(1));
    expect(listLiteral.rightBracket, isNotNull);
  }

  void test_parseListOrMapLiteral_map_noType() {
    createParser("{'1' : 1}");
    TypedLiteral literal = parser.parseListOrMapLiteral(null);
    expectNotNullIfNoErrors(literal);
    listener.assertNoErrors();
    expect(literal, new isInstanceOf<MapLiteral>());
    MapLiteral mapLiteral = literal;
    expect(mapLiteral.constKeyword, isNull);
    expect(mapLiteral.typeArguments, isNull);
    expect(mapLiteral.leftBracket, isNotNull);
    expect(mapLiteral.entries, hasLength(1));
    expect(mapLiteral.rightBracket, isNotNull);
  }

  void test_parseListOrMapLiteral_map_type() {
    createParser("<String, int> {'1' : 1}");
    TypedLiteral literal = parser.parseListOrMapLiteral(null);
    expectNotNullIfNoErrors(literal);
    listener.assertNoErrors();
    expect(literal, new isInstanceOf<MapLiteral>());
    MapLiteral mapLiteral = literal;
    expect(mapLiteral.constKeyword, isNull);
    expect(mapLiteral.typeArguments, isNotNull);
    expect(mapLiteral.leftBracket, isNotNull);
    expect(mapLiteral.entries, hasLength(1));
    expect(mapLiteral.rightBracket, isNotNull);
  }

  void test_parseLogicalAndExpression() {
    createParser('x && y');
    Expression expression = parser.parseLogicalAndExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<BinaryExpression>());
    BinaryExpression binaryExpression = expression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.AMPERSAND_AMPERSAND);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseLogicalOrExpression() {
    createParser('x || y');
    Expression expression = parser.parseLogicalOrExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<BinaryExpression>());
    BinaryExpression binaryExpression = expression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.BAR_BAR);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseMapLiteral_empty() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.CONST);
    TypeArgumentList typeArguments = AstTestFactory.typeArgumentList(
        [AstTestFactory.typeName4("String"), AstTestFactory.typeName4("int")]);
    createParser('{}');
    MapLiteral literal = parser.parseMapLiteral(token, typeArguments);
    expectNotNullIfNoErrors(literal);
    listener.assertNoErrors();
    expect(literal.constKeyword, token);
    expect(literal.typeArguments, typeArguments);
    expect(literal.leftBracket, isNotNull);
    expect(literal.entries, hasLength(0));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseMapLiteral_multiple() {
    createParser("{'a' : b, 'x' : y}");
    MapLiteral literal = parser.parseMapLiteral(null, null);
    expectNotNullIfNoErrors(literal);
    listener.assertNoErrors();
    expect(literal.leftBracket, isNotNull);
    expect(literal.entries, hasLength(2));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseMapLiteral_single() {
    createParser("{'x' : y}");
    MapLiteral literal = parser.parseMapLiteral(null, null);
    expectNotNullIfNoErrors(literal);
    listener.assertNoErrors();
    expect(literal.leftBracket, isNotNull);
    expect(literal.entries, hasLength(1));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseMapLiteralEntry_complex() {
    createParser('2 + 2 : y');
    MapLiteralEntry entry = parser.parseMapLiteralEntry();
    expectNotNullIfNoErrors(entry);
    listener.assertNoErrors();
    expect(entry.key, isNotNull);
    expect(entry.separator, isNotNull);
    expect(entry.value, isNotNull);
  }

  void test_parseMapLiteralEntry_int() {
    createParser('0 : y');
    MapLiteralEntry entry = parser.parseMapLiteralEntry();
    expectNotNullIfNoErrors(entry);
    listener.assertNoErrors();
    expect(entry.key, isNotNull);
    expect(entry.separator, isNotNull);
    expect(entry.value, isNotNull);
  }

  void test_parseMapLiteralEntry_string() {
    createParser("'x' : y");
    MapLiteralEntry entry = parser.parseMapLiteralEntry();
    expectNotNullIfNoErrors(entry);
    listener.assertNoErrors();
    expect(entry.key, isNotNull);
    expect(entry.separator, isNotNull);
    expect(entry.value, isNotNull);
  }

  void test_parseModifiers_abstract() {
    createParser('abstract A');
    Modifiers modifiers = parser.parseModifiers();
    expectNotNullIfNoErrors(modifiers);
    listener.assertNoErrors();
    expect(modifiers.abstractKeyword, isNotNull);
  }

  void test_parseModifiers_const() {
    createParser('const A');
    Modifiers modifiers = parser.parseModifiers();
    expectNotNullIfNoErrors(modifiers);
    listener.assertNoErrors();
    expect(modifiers.constKeyword, isNotNull);
  }

  void test_parseModifiers_external() {
    createParser('external A');
    Modifiers modifiers = parser.parseModifiers();
    expectNotNullIfNoErrors(modifiers);
    listener.assertNoErrors();
    expect(modifiers.externalKeyword, isNotNull);
  }

  void test_parseModifiers_factory() {
    createParser('factory A');
    Modifiers modifiers = parser.parseModifiers();
    expectNotNullIfNoErrors(modifiers);
    listener.assertNoErrors();
    expect(modifiers.factoryKeyword, isNotNull);
  }

  void test_parseModifiers_final() {
    createParser('final A');
    Modifiers modifiers = parser.parseModifiers();
    expectNotNullIfNoErrors(modifiers);
    listener.assertNoErrors();
    expect(modifiers.finalKeyword, isNotNull);
  }

  void test_parseModifiers_static() {
    createParser('static A');
    Modifiers modifiers = parser.parseModifiers();
    expectNotNullIfNoErrors(modifiers);
    listener.assertNoErrors();
    expect(modifiers.staticKeyword, isNotNull);
  }

  void test_parseModifiers_var() {
    createParser('var A');
    Modifiers modifiers = parser.parseModifiers();
    expectNotNullIfNoErrors(modifiers);
    listener.assertNoErrors();
    expect(modifiers.varKeyword, isNotNull);
  }

  void test_parseMultiplicativeExpression_normal() {
    createParser('x * y');
    Expression expression = parser.parseMultiplicativeExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<BinaryExpression>());
    BinaryExpression binaryExpression = expression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.STAR);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseMultiplicativeExpression_super() {
    createParser('super * y');
    Expression expression = parser.parseMultiplicativeExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<BinaryExpression>());
    BinaryExpression binaryExpression = expression;
    expect(binaryExpression.leftOperand, new isInstanceOf<SuperExpression>());
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.STAR);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseNewExpression() {
    createParser('new A()');
    InstanceCreationExpression expression = parser.parseNewExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.keyword, isNotNull);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    expect(name.type, isNotNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseNonLabeledStatement_const_list_empty() {
    createParser('const [];');
    Statement statement = parser.parseNonLabeledStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ExpressionStatement>());
    ExpressionStatement expressionStatement = statement;
    expect(expressionStatement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_const_list_nonEmpty() {
    createParser('const [1, 2];');
    Statement statement = parser.parseNonLabeledStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ExpressionStatement>());
    ExpressionStatement expressionStatement = statement;
    expect(expressionStatement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_const_map_empty() {
    createParser('const {};');
    Statement statement = parser.parseNonLabeledStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ExpressionStatement>());
    ExpressionStatement expressionStatement = statement;
    expect(expressionStatement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_const_map_nonEmpty() {
    // TODO(brianwilkerson) Implement more tests for this method.
    createParser("const {'a' : 1};");
    Statement statement = parser.parseNonLabeledStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ExpressionStatement>());
    ExpressionStatement expressionStatement = statement;
    expect(expressionStatement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_const_object() {
    createParser('const A();');
    Statement statement = parser.parseNonLabeledStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ExpressionStatement>());
    ExpressionStatement expressionStatement = statement;
    expect(expressionStatement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_const_object_named_typeParameters() {
    createParser('const A<B>.c();');
    Statement statement = parser.parseNonLabeledStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ExpressionStatement>());
    ExpressionStatement expressionStatement = statement;
    expect(expressionStatement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_constructorInvocation() {
    createParser('new C().m();');
    Statement statement = parser.parseNonLabeledStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ExpressionStatement>());
    ExpressionStatement expressionStatement = statement;
    expect(expressionStatement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_false() {
    createParser('false;');
    Statement statement = parser.parseNonLabeledStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ExpressionStatement>());
    ExpressionStatement expressionStatement = statement;
    expect(expressionStatement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_functionDeclaration() {
    createParser('f() {};');
    Statement statement = parser.parseNonLabeledStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
  }

  void test_parseNonLabeledStatement_functionDeclaration_arguments() {
    createParser('f(void g()) {};');
    Statement statement = parser.parseNonLabeledStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
  }

  void test_parseNonLabeledStatement_functionExpressionIndex() {
    createParser('() {}[0] = null;');
    Statement statement = parser.parseNonLabeledStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
  }

  void test_parseNonLabeledStatement_functionInvocation() {
    createParser('f();');
    Statement statement = parser.parseNonLabeledStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ExpressionStatement>());
    ExpressionStatement expressionStatement = statement;
    expect(expressionStatement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_invokeFunctionExpression() {
    createParser('(a) {return a + a;} (3);');
    Statement statement = parser.parseNonLabeledStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ExpressionStatement>());
    ExpressionStatement expressionStatement = statement;
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionExpressionInvocation,
        FunctionExpressionInvocation,
        expressionStatement.expression);
    FunctionExpressionInvocation invocation =
        expressionStatement.expression as FunctionExpressionInvocation;
    EngineTestCase.assertInstanceOf((obj) => obj is FunctionExpression,
        FunctionExpression, invocation.function);
    FunctionExpression expression = invocation.function as FunctionExpression;
    expect(expression.parameters, isNotNull);
    expect(expression.body, isNotNull);
    expect(invocation.typeArguments, isNull);
    ArgumentList list = invocation.argumentList;
    expect(list, isNotNull);
    expect(list.arguments, hasLength(1));
  }

  void test_parseNonLabeledStatement_null() {
    createParser('null;');
    Statement statement = parser.parseNonLabeledStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ExpressionStatement>());
    ExpressionStatement expressionStatement = statement;
    expect(expressionStatement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_startingWithBuiltInIdentifier() {
    createParser('library.getName();');
    Statement statement = parser.parseNonLabeledStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ExpressionStatement>());
    ExpressionStatement expressionStatement = statement;
    expect(expressionStatement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_true() {
    createParser('true;');
    Statement statement = parser.parseNonLabeledStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ExpressionStatement>());
    ExpressionStatement expressionStatement = statement;
    expect(expressionStatement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_typeCast() {
    createParser('double.NAN as num;');
    Statement statement = parser.parseNonLabeledStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<ExpressionStatement>());
    ExpressionStatement expressionStatement = statement;
    expect(expressionStatement.expression, isNotNull);
  }

  void test_parseNormalFormalParameter_field_const_noType() {
    createParser('const this.a)');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<FieldFormalParameter>());
    FieldFormalParameter fieldParameter = parameter;
    expect(fieldParameter.keyword, isNotNull);
    expect(fieldParameter.type, isNull);
    expect(fieldParameter.identifier, isNotNull);
    expect(fieldParameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_const_type() {
    createParser('const A this.a)');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<FieldFormalParameter>());
    FieldFormalParameter fieldParameter = parameter;
    expect(fieldParameter.keyword, isNotNull);
    expect(fieldParameter.type, isNotNull);
    expect(fieldParameter.identifier, isNotNull);
    expect(fieldParameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_final_noType() {
    createParser('final this.a)');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<FieldFormalParameter>());
    FieldFormalParameter fieldParameter = parameter;
    expect(fieldParameter.keyword, isNotNull);
    expect(fieldParameter.type, isNull);
    expect(fieldParameter.identifier, isNotNull);
    expect(fieldParameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_final_type() {
    createParser('final A this.a)');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<FieldFormalParameter>());
    FieldFormalParameter fieldParameter = parameter;
    expect(fieldParameter.keyword, isNotNull);
    expect(fieldParameter.type, isNotNull);
    expect(fieldParameter.identifier, isNotNull);
    expect(fieldParameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_function_nested() {
    createParser('this.a(B b))');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<FieldFormalParameter>());
    FieldFormalParameter fieldParameter = parameter;
    expect(fieldParameter.keyword, isNull);
    expect(fieldParameter.type, isNull);
    expect(fieldParameter.identifier, isNotNull);
    FormalParameterList parameterList = fieldParameter.parameters;
    expect(parameterList, isNotNull);
    expect(parameterList.parameters, hasLength(1));
  }

  void test_parseNormalFormalParameter_field_function_noNested() {
    createParser('this.a())');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<FieldFormalParameter>());
    FieldFormalParameter fieldParameter = parameter;
    expect(fieldParameter.keyword, isNull);
    expect(fieldParameter.type, isNull);
    expect(fieldParameter.identifier, isNotNull);
    FormalParameterList parameterList = fieldParameter.parameters;
    expect(parameterList, isNotNull);
    expect(parameterList.parameters, hasLength(0));
  }

  void test_parseNormalFormalParameter_field_noType() {
    createParser('this.a)');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<FieldFormalParameter>());
    FieldFormalParameter fieldParameter = parameter;
    expect(fieldParameter.keyword, isNull);
    expect(fieldParameter.type, isNull);
    expect(fieldParameter.identifier, isNotNull);
    expect(fieldParameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_type() {
    createParser('A this.a)');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<FieldFormalParameter>());
    FieldFormalParameter fieldParameter = parameter;
    expect(fieldParameter.keyword, isNull);
    expect(fieldParameter.type, isNotNull);
    expect(fieldParameter.identifier, isNotNull);
    expect(fieldParameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_var() {
    createParser('var this.a)');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<FieldFormalParameter>());
    FieldFormalParameter fieldParameter = parameter;
    expect(fieldParameter.keyword, isNotNull);
    expect(fieldParameter.type, isNull);
    expect(fieldParameter.identifier, isNotNull);
    expect(fieldParameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_function_noType() {
    createParser('a())');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<FunctionTypedFormalParameter>());
    FunctionTypedFormalParameter functionParameter = parameter;
    expect(functionParameter.returnType, isNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
  }

  void test_parseNormalFormalParameter_function_noType_nullable() {
    enableNnbd = true;
    createParser('a()?)');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<FunctionTypedFormalParameter>());
    FunctionTypedFormalParameter functionParameter = parameter;
    expect(functionParameter.returnType, isNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNotNull);
  }

  void test_parseNormalFormalParameter_function_noType_typeParameterComments() {
    enableGenericMethodComments = true;
    createParser('a/*<E>*/())');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<FunctionTypedFormalParameter>());
    FunctionTypedFormalParameter functionParameter = parameter;
    expect(functionParameter.returnType, isNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNotNull);
    expect(functionParameter.parameters, isNotNull);
  }

  void test_parseNormalFormalParameter_function_noType_typeParameters() {
    createParser('a<E>())');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<FunctionTypedFormalParameter>());
    FunctionTypedFormalParameter functionParameter = parameter;
    expect(functionParameter.returnType, isNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNotNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNull);
    expect(functionParameter.question, isNull);
  }

  void
      test_parseNormalFormalParameter_function_noType_typeParameters_nullable() {
    enableNnbd = true;
    createParser('a<E>()?)');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<FunctionTypedFormalParameter>());
    FunctionTypedFormalParameter functionParameter = parameter;
    expect(functionParameter.returnType, isNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNotNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNotNull);
  }

  void test_parseNormalFormalParameter_function_type() {
    createParser('A a())');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<FunctionTypedFormalParameter>());
    FunctionTypedFormalParameter functionParameter = parameter;
    expect(functionParameter.returnType, isNotNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNull);
  }

  void test_parseNormalFormalParameter_function_type_nullable() {
    enableNnbd = true;
    createParser('A a()?)');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<FunctionTypedFormalParameter>());
    FunctionTypedFormalParameter functionParameter = parameter;
    expect(functionParameter.returnType, isNotNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNotNull);
  }

  void test_parseNormalFormalParameter_function_type_typeParameterComments() {
    enableGenericMethodComments = true;
    createParser('A a/*<E>*/())');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<FunctionTypedFormalParameter>());
    FunctionTypedFormalParameter functionParameter = parameter;
    expect(functionParameter.returnType, isNotNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNotNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNull);
  }

  void test_parseNormalFormalParameter_function_type_typeParameters() {
    createParser('A a<E>())');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<FunctionTypedFormalParameter>());
    FunctionTypedFormalParameter functionParameter = parameter;
    expect(functionParameter.returnType, isNotNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNotNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNull);
  }

  void test_parseNormalFormalParameter_function_type_typeParameters_nullable() {
    enableNnbd = true;
    createParser('A a<E>()?)');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<FunctionTypedFormalParameter>());
    FunctionTypedFormalParameter functionParameter = parameter;
    expect(functionParameter.returnType, isNotNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNotNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNotNull);
  }

  void test_parseNormalFormalParameter_function_void() {
    createParser('void a())');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<FunctionTypedFormalParameter>());
    FunctionTypedFormalParameter functionParameter = parameter;
    expect(functionParameter.returnType, isNotNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNull);
  }

  void test_parseNormalFormalParameter_function_void_nullable() {
    enableNnbd = true;
    createParser('void a()?)');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<FunctionTypedFormalParameter>());
    FunctionTypedFormalParameter functionParameter = parameter;
    expect(functionParameter.returnType, isNotNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNotNull);
  }

  void test_parseNormalFormalParameter_function_void_typeParameterComments() {
    enableGenericMethodComments = true;
    createParser('void a/*<E>*/())');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<FunctionTypedFormalParameter>());
    FunctionTypedFormalParameter functionParameter = parameter;
    expect(functionParameter.returnType, isNotNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNotNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNull);
  }

  void test_parseNormalFormalParameter_function_void_typeParameters() {
    createParser('void a<E>())');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<FunctionTypedFormalParameter>());
    FunctionTypedFormalParameter functionParameter = parameter;
    expect(functionParameter.returnType, isNotNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNotNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNull);
  }

  void test_parseNormalFormalParameter_function_void_typeParameters_nullable() {
    enableNnbd = true;
    createParser('void a<E>()?)');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<FunctionTypedFormalParameter>());
    FunctionTypedFormalParameter functionParameter = parameter;
    expect(functionParameter.returnType, isNotNull);
    expect(functionParameter.identifier, isNotNull);
    expect(functionParameter.typeParameters, isNotNull);
    expect(functionParameter.parameters, isNotNull);
    expect(functionParameter.question, isNotNull);
  }

  void test_parseNormalFormalParameter_simple_const_noType() {
    createParser('const a)');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<SimpleFormalParameter>());
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.identifier, isNotNull);
  }

  void test_parseNormalFormalParameter_simple_const_type() {
    createParser('const A a)');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<SimpleFormalParameter>());
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.identifier, isNotNull);
  }

  void test_parseNormalFormalParameter_simple_final_noType() {
    createParser('final a)');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<SimpleFormalParameter>());
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.identifier, isNotNull);
  }

  void test_parseNormalFormalParameter_simple_final_type() {
    createParser('final A a)');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<SimpleFormalParameter>());
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.identifier, isNotNull);
  }

  void test_parseNormalFormalParameter_simple_noType() {
    createParser('a)');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<SimpleFormalParameter>());
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.identifier, isNotNull);
  }

  void test_parseNormalFormalParameter_simple_type() {
    createParser('A a)');
    NormalFormalParameter parameter = parser.parseNormalFormalParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter, new isInstanceOf<SimpleFormalParameter>());
    SimpleFormalParameter simpleParameter = parameter;
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.identifier, isNotNull);
  }

  void test_parseOperator() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    TypeName returnType = new TypeName(new SimpleIdentifier(null), null);
    createParser('operator +(A a);');
    MethodDeclaration method =
        parser.parseOperator(commentAndMetadata(comment), null, returnType);
    expectNotNullIfNoErrors(method);
    listener.assertNoErrors();
    expect(method.body, isNotNull);
    expect(method.documentationComment, comment);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNotNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, returnType);
  }

  void test_parseOptionalReturnType() {
    // TODO(brianwilkerson) Implement tests for this method.
  }

  void test_parsePartDirective() {
    createParser("part 'lib/lib.dart';");
    PartDirective directive =
        parser.parsePartOrPartOfDirective(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(directive);
    listener.assertNoErrors();
    expect(directive.partKeyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.semicolon, isNotNull);
  }

  void test_parsePartOfDirective_name() {
    enableUriInPartOf = true;
    createParser("part of l;");
    PartOfDirective directive =
        parser.parsePartOrPartOfDirective(emptyCommentAndMetadata());
    expect(directive.partKeyword, isNotNull);
    expect(directive.ofKeyword, isNotNull);
    expect(directive.libraryName, isNotNull);
    expect(directive.uri, isNull);
    expect(directive.semicolon, isNotNull);
  }

  void test_parsePartOfDirective_uri() {
    enableUriInPartOf = true;
    createParser("part of 'lib.dart';");
    PartOfDirective directive =
        parser.parsePartOrPartOfDirective(emptyCommentAndMetadata());
    expect(directive.partKeyword, isNotNull);
    expect(directive.ofKeyword, isNotNull);
    expect(directive.libraryName, isNull);
    expect(directive.uri, isNotNull);
    expect(directive.semicolon, isNotNull);
  }

  void test_parsePostfixExpression_decrement() {
    createParser('i--');
    Expression expression = parser.parsePostfixExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<PostfixExpression>());
    PostfixExpression postfixExpression = expression;
    expect(postfixExpression.operand, isNotNull);
    expect(postfixExpression.operator, isNotNull);
    expect(postfixExpression.operator.type, TokenType.MINUS_MINUS);
  }

  void test_parsePostfixExpression_increment() {
    createParser('i++');
    Expression expression = parser.parsePostfixExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<PostfixExpression>());
    PostfixExpression postfixExpression = expression;
    expect(postfixExpression.operand, isNotNull);
    expect(postfixExpression.operator, isNotNull);
    expect(postfixExpression.operator.type, TokenType.PLUS_PLUS);
  }

  void test_parsePostfixExpression_none_indexExpression() {
    createParser('a[0]');
    Expression expression = parser.parsePostfixExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<IndexExpression>());
    IndexExpression indexExpression = expression;
    expect(indexExpression.target, isNotNull);
    expect(indexExpression.index, isNotNull);
  }

  void test_parsePostfixExpression_none_methodInvocation() {
    createParser('a.m()');
    Expression expression = parser.parsePostfixExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<MethodInvocation>());
    MethodInvocation methodInvocation = expression;
    expect(methodInvocation.target, isNotNull);
    expect(methodInvocation.operator.type, TokenType.PERIOD);
    expect(methodInvocation.methodName, isNotNull);
    expect(methodInvocation.typeArguments, isNull);
    expect(methodInvocation.argumentList, isNotNull);
  }

  void test_parsePostfixExpression_none_methodInvocation_question_dot() {
    createParser('a?.m()');
    Expression expression = parser.parsePostfixExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<MethodInvocation>());
    MethodInvocation methodInvocation = expression;
    expect(methodInvocation.target, isNotNull);
    expect(methodInvocation.operator.type, TokenType.QUESTION_PERIOD);
    expect(methodInvocation.methodName, isNotNull);
    expect(methodInvocation.typeArguments, isNull);
    expect(methodInvocation.argumentList, isNotNull);
  }

  void
      test_parsePostfixExpression_none_methodInvocation_question_dot_typeArgumentComments() {
    enableGenericMethodComments = true;
    createParser('a?.m/*<E>*/()');
    Expression expression = parser.parsePostfixExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<MethodInvocation>());
    MethodInvocation methodInvocation = expression;
    expect(methodInvocation.target, isNotNull);
    expect(methodInvocation.operator.type, TokenType.QUESTION_PERIOD);
    expect(methodInvocation.methodName, isNotNull);
    expect(methodInvocation.typeArguments, isNotNull);
    expect(methodInvocation.argumentList, isNotNull);
  }

  void
      test_parsePostfixExpression_none_methodInvocation_question_dot_typeArguments() {
    createParser('a?.m<E>()');
    Expression expression = parser.parsePostfixExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<MethodInvocation>());
    MethodInvocation methodInvocation = expression;
    expect(methodInvocation.target, isNotNull);
    expect(methodInvocation.operator.type, TokenType.QUESTION_PERIOD);
    expect(methodInvocation.methodName, isNotNull);
    expect(methodInvocation.typeArguments, isNotNull);
    expect(methodInvocation.argumentList, isNotNull);
  }

  void
      test_parsePostfixExpression_none_methodInvocation_typeArgumentComments() {
    enableGenericMethodComments = true;
    createParser('a.m/*<E>*/()');
    Expression expression = parser.parsePostfixExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<MethodInvocation>());
    MethodInvocation methodInvocation = expression;
    expect(methodInvocation.target, isNotNull);
    expect(methodInvocation.operator.type, TokenType.PERIOD);
    expect(methodInvocation.methodName, isNotNull);
    expect(methodInvocation.typeArguments, isNotNull);
    expect(methodInvocation.argumentList, isNotNull);
  }

  void test_parsePostfixExpression_none_methodInvocation_typeArguments() {
    createParser('a.m<E>()');
    Expression expression = parser.parsePostfixExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<MethodInvocation>());
    MethodInvocation methodInvocation = expression;
    expect(methodInvocation.target, isNotNull);
    expect(methodInvocation.operator.type, TokenType.PERIOD);
    expect(methodInvocation.methodName, isNotNull);
    expect(methodInvocation.typeArguments, isNotNull);
    expect(methodInvocation.argumentList, isNotNull);
  }

  void test_parsePostfixExpression_none_propertyAccess() {
    createParser('a.b');
    Expression expression = parser.parsePostfixExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<PrefixedIdentifier>());
    PrefixedIdentifier identifier = expression;
    expect(identifier.prefix, isNotNull);
    expect(identifier.identifier, isNotNull);
  }

  void test_parsePrefixedIdentifier_noPrefix() {
    String lexeme = "bar";
    createParser(lexeme);
    Identifier identifier = parser.parsePrefixedIdentifier();
    expectNotNullIfNoErrors(identifier);
    listener.assertNoErrors();
    expect(identifier, new isInstanceOf<SimpleIdentifier>());
    SimpleIdentifier simpleIdentifier = identifier;
    expect(simpleIdentifier.token, isNotNull);
    expect(simpleIdentifier.name, lexeme);
  }

  void test_parsePrefixedIdentifier_prefix() {
    String lexeme = "foo.bar";
    createParser(lexeme);
    Identifier identifier = parser.parsePrefixedIdentifier();
    expectNotNullIfNoErrors(identifier);
    listener.assertNoErrors();
    expect(identifier, new isInstanceOf<PrefixedIdentifier>());
    PrefixedIdentifier prefixedIdentifier = identifier;
    expect(prefixedIdentifier.prefix.name, "foo");
    expect(prefixedIdentifier.period, isNotNull);
    expect(prefixedIdentifier.identifier.name, "bar");
  }

  void test_parsePrimaryExpression_const() {
    createParser('const A()');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, isNotNull);
  }

  void test_parsePrimaryExpression_double() {
    String doubleLiteral = "3.2e4";
    createParser(doubleLiteral);
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<DoubleLiteral>());
    DoubleLiteral literal = expression;
    expect(literal.literal, isNotNull);
    expect(literal.value, double.parse(doubleLiteral));
  }

  void test_parsePrimaryExpression_false() {
    createParser('false');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<BooleanLiteral>());
    BooleanLiteral literal = expression;
    expect(literal.literal, isNotNull);
    expect(literal.value, isFalse);
  }

  void test_parsePrimaryExpression_function_arguments() {
    createParser('(int i) => i + 1');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<FunctionExpression>());
    FunctionExpression functionExpression = expression;
    expect(functionExpression.parameters, isNotNull);
    expect(functionExpression.body, isNotNull);
  }

  void test_parsePrimaryExpression_function_noArguments() {
    createParser('() => 42');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<FunctionExpression>());
    FunctionExpression functionExpression = expression;
    expect(functionExpression.parameters, isNotNull);
    expect(functionExpression.body, isNotNull);
  }

  void test_parsePrimaryExpression_genericFunctionExpression() {
    createParser('<X, Y>(Map<X, Y> m, X x) => m[x]');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<FunctionExpression>());
    FunctionExpression function = expression;
    expect(function.typeParameters, isNotNull);
  }

  void test_parsePrimaryExpression_hex() {
    String hexLiteral = "3F";
    createParser('0x$hexLiteral');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<IntegerLiteral>());
    IntegerLiteral literal = expression;
    expect(literal.literal, isNotNull);
    expect(literal.value, int.parse(hexLiteral, radix: 16));
  }

  void test_parsePrimaryExpression_identifier() {
    createParser('a');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<SimpleIdentifier>());
    SimpleIdentifier identifier = expression;
    expect(identifier, isNotNull);
  }

  void test_parsePrimaryExpression_int() {
    String intLiteral = "472";
    createParser(intLiteral);
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<IntegerLiteral>());
    IntegerLiteral literal = expression;
    expect(literal.literal, isNotNull);
    expect(literal.value, int.parse(intLiteral));
  }

  void test_parsePrimaryExpression_listLiteral() {
    createParser('[ ]');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<ListLiteral>());
    ListLiteral literal = expression;
    expect(literal, isNotNull);
  }

  void test_parsePrimaryExpression_listLiteral_index() {
    createParser('[]');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<ListLiteral>());
    ListLiteral literal = expression;
    expect(literal, isNotNull);
  }

  void test_parsePrimaryExpression_listLiteral_typed() {
    createParser('<A>[ ]');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<ListLiteral>());
    ListLiteral literal = expression;
    expect(literal.typeArguments, isNotNull);
    expect(literal.typeArguments.arguments, hasLength(1));
  }

  void test_parsePrimaryExpression_listLiteral_typed_genericComment() {
    enableGenericMethodComments = true;
    createParser('/*<A>*/[ ]');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<ListLiteral>());
    ListLiteral literal = expression;
    expect(literal.typeArguments, isNotNull);
    expect(literal.typeArguments.arguments, hasLength(1));
  }

  void test_parsePrimaryExpression_mapLiteral() {
    createParser('{}');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<MapLiteral>());
    MapLiteral literal = expression;
    expect(literal.typeArguments, isNull);
    expect(literal, isNotNull);
  }

  void test_parsePrimaryExpression_mapLiteral_typed() {
    createParser('<A, B>{}');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<MapLiteral>());
    MapLiteral literal = expression;
    expect(literal.typeArguments, isNotNull);
    expect(literal.typeArguments.arguments, hasLength(2));
  }

  void test_parsePrimaryExpression_mapLiteral_typed_genericComment() {
    enableGenericMethodComments = true;
    createParser('/*<A, B>*/{}');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<MapLiteral>());
    MapLiteral literal = expression;
    expect(literal.typeArguments, isNotNull);
    expect(literal.typeArguments.arguments, hasLength(2));
  }

  void test_parsePrimaryExpression_new() {
    createParser('new A()');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<InstanceCreationExpression>());
    InstanceCreationExpression creation = expression;
    expect(creation, isNotNull);
  }

  void test_parsePrimaryExpression_null() {
    createParser('null');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<NullLiteral>());
    NullLiteral literal = expression;
    expect(literal.literal, isNotNull);
  }

  void test_parsePrimaryExpression_parenthesized() {
    createParser('(x)');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<ParenthesizedExpression>());
    ParenthesizedExpression parens = expression;
    expect(parens, isNotNull);
  }

  void test_parsePrimaryExpression_string() {
    createParser('"string"');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<SimpleStringLiteral>());
    SimpleStringLiteral literal = expression;
    expect(literal.isMultiline, isFalse);
    expect(literal.isRaw, isFalse);
    expect(literal.value, "string");
  }

  void test_parsePrimaryExpression_string_multiline() {
    createParser("'''string'''");
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<SimpleStringLiteral>());
    SimpleStringLiteral literal = expression;
    expect(literal.isMultiline, isTrue);
    expect(literal.isRaw, isFalse);
    expect(literal.value, "string");
  }

  void test_parsePrimaryExpression_string_raw() {
    createParser("r'string'");
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<SimpleStringLiteral>());
    SimpleStringLiteral literal = expression;
    expect(literal.isMultiline, isFalse);
    expect(literal.isRaw, isTrue);
    expect(literal.value, "string");
  }

  void test_parsePrimaryExpression_super() {
    createParser('super.x');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<PropertyAccess>());
    PropertyAccess propertyAccess = expression;
    expect(propertyAccess.target is SuperExpression, isTrue);
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.operator.type, TokenType.PERIOD);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parsePrimaryExpression_this() {
    createParser('this');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<ThisExpression>());
    ThisExpression thisExpression = expression;
    expect(thisExpression.thisKeyword, isNotNull);
  }

  void test_parsePrimaryExpression_true() {
    createParser('true');
    Expression expression = parser.parsePrimaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<BooleanLiteral>());
    BooleanLiteral literal = expression;
    expect(literal.literal, isNotNull);
    expect(literal.value, isTrue);
  }

  void test_Parser() {
    expect(new Parser(null, null), isNotNull);
  }

  void test_parseRedirectingConstructorInvocation_named() {
    createParser('this.a()');
    RedirectingConstructorInvocation invocation =
        parser.parseRedirectingConstructorInvocation(true);
    expectNotNullIfNoErrors(invocation);
    listener.assertNoErrors();
    expect(invocation.argumentList, isNotNull);
    expect(invocation.constructorName, isNotNull);
    expect(invocation.thisKeyword, isNotNull);
    expect(invocation.period, isNotNull);
  }

  void test_parseRedirectingConstructorInvocation_unnamed() {
    createParser('this()');
    RedirectingConstructorInvocation invocation =
        parser.parseRedirectingConstructorInvocation(false);
    expectNotNullIfNoErrors(invocation);
    listener.assertNoErrors();
    expect(invocation.argumentList, isNotNull);
    expect(invocation.constructorName, isNull);
    expect(invocation.thisKeyword, isNotNull);
    expect(invocation.period, isNull);
  }

  void test_parseRelationalExpression_as() {
    createParser('x as Y');
    Expression expression = parser.parseRelationalExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<AsExpression>());
    AsExpression asExpression = expression;
    expect(asExpression.expression, isNotNull);
    expect(asExpression.asOperator, isNotNull);
    expect(asExpression.type, isNotNull);
  }

  void test_parseRelationalExpression_as_nullable() {
    enableNnbd = true;
    createParser('x as Y?)');
    Expression expression = parser.parseRelationalExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<AsExpression>());
    AsExpression asExpression = expression;
    expect(asExpression.expression, isNotNull);
    expect(asExpression.asOperator, isNotNull);
    expect(asExpression.type, isNotNull);
  }

  void test_parseRelationalExpression_is() {
    createParser('x is y');
    Expression expression = parser.parseRelationalExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<IsExpression>());
    IsExpression isExpression = expression;
    expect(isExpression.expression, isNotNull);
    expect(isExpression.isOperator, isNotNull);
    expect(isExpression.notOperator, isNull);
    expect(isExpression.type, isNotNull);
  }

  void test_parseRelationalExpression_is_nullable() {
    enableNnbd = true;
    createParser('x is y?)');
    Expression expression = parser.parseRelationalExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<IsExpression>());
    IsExpression isExpression = expression;
    expect(isExpression.expression, isNotNull);
    expect(isExpression.isOperator, isNotNull);
    expect(isExpression.notOperator, isNull);
    expect(isExpression.type, isNotNull);
  }

  void test_parseRelationalExpression_isNot() {
    createParser('x is! y');
    Expression expression = parser.parseRelationalExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<IsExpression>());
    IsExpression isExpression = expression;
    expect(isExpression.expression, isNotNull);
    expect(isExpression.isOperator, isNotNull);
    expect(isExpression.notOperator, isNotNull);
    expect(isExpression.type, isNotNull);
  }

  void test_parseRelationalExpression_normal() {
    createParser('x < y');
    Expression expression = parser.parseRelationalExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<BinaryExpression>());
    BinaryExpression binaryExpression = expression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.LT);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseRelationalExpression_super() {
    createParser('super < y');
    Expression expression = parser.parseRelationalExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<BinaryExpression>());
    BinaryExpression binaryExpression = expression;
    expect(binaryExpression.leftOperand, isNotNull);
    expect(binaryExpression.operator, isNotNull);
    expect(binaryExpression.operator.type, TokenType.LT);
    expect(binaryExpression.rightOperand, isNotNull);
  }

  void test_parseRethrowExpression() {
    createParser('rethrow;');
    RethrowExpression expression = parser.parseRethrowExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.rethrowKeyword, isNotNull);
  }

  void test_parseReturnStatement_noValue() {
    createParser('return;');
    ReturnStatement statement = parser.parseReturnStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.returnKeyword, isNotNull);
    expect(statement.expression, isNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseReturnStatement_value() {
    createParser('return x;');
    ReturnStatement statement = parser.parseReturnStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.returnKeyword, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseReturnType_nonVoid() {
    createParser('A<B>');
    TypeName typeName = parser.parseReturnType();
    expectNotNullIfNoErrors(typeName);
    listener.assertNoErrors();
    expect(typeName.name, isNotNull);
    expect(typeName.typeArguments, isNotNull);
  }

  void test_parseReturnType_void() {
    createParser('void');
    TypeName typeName = parser.parseReturnType();
    expectNotNullIfNoErrors(typeName);
    listener.assertNoErrors();
    expect(typeName.name, isNotNull);
    expect(typeName.typeArguments, isNull);
  }

  void test_parseSetter_nonStatic() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    TypeName returnType = new TypeName(new SimpleIdentifier(null), null);
    createParser('set a(var x);');
    MethodDeclaration method =
        parser.parseSetter(commentAndMetadata(comment), null, null, returnType);
    expectNotNullIfNoErrors(method);
    listener.assertNoErrors();
    expect(method.body, isNotNull);
    expect(method.documentationComment, comment);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.propertyKeyword, isNotNull);
    expect(method.returnType, returnType);
  }

  void test_parseSetter_static() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    Token staticKeyword = TokenFactory.tokenFromKeyword(Keyword.STATIC);
    TypeName returnType = new TypeName(new SimpleIdentifier(null), null);
    createParser('set a(var x) {}');
    MethodDeclaration method = parser.parseSetter(
        commentAndMetadata(comment), null, staticKeyword, returnType);
    expectNotNullIfNoErrors(method);
    listener.assertNoErrors();
    expect(method.body, isNotNull);
    expect(method.documentationComment, comment);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, staticKeyword);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.typeParameters, isNull);
    expect(method.parameters, isNotNull);
    expect(method.propertyKeyword, isNotNull);
    expect(method.returnType, returnType);
  }

  void test_parseShiftExpression_normal() {
    createParser('x << y');
    BinaryExpression expression = parser.parseShiftExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.leftOperand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.LT_LT);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseShiftExpression_super() {
    createParser('super << y');
    BinaryExpression expression = parser.parseShiftExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.leftOperand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.LT_LT);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseSimpleIdentifier1_normalIdentifier() {
    // TODO(brianwilkerson) Implement tests for this method.
  }

  void test_parseSimpleIdentifier_builtInIdentifier() {
    String lexeme = "as";
    createParser(lexeme);
    SimpleIdentifier identifier = parser.parseSimpleIdentifier();
    expectNotNullIfNoErrors(identifier);
    listener.assertNoErrors();
    expect(identifier.token, isNotNull);
    expect(identifier.name, lexeme);
  }

  void test_parseSimpleIdentifier_normalIdentifier() {
    String lexeme = "foo";
    createParser(lexeme);
    SimpleIdentifier identifier = parser.parseSimpleIdentifier();
    expectNotNullIfNoErrors(identifier);
    listener.assertNoErrors();
    expect(identifier.token, isNotNull);
    expect(identifier.name, lexeme);
  }

  void test_parseStatement_emptyTypeArgumentList() {
    createParser('C<> c;');
    Statement statement = parser.parseStatement2();
    expectNotNullIfNoErrors(statement);
    listener.assertErrorsWithCodes([ParserErrorCode.EXPECTED_TYPE_NAME]);
    expect(statement, new isInstanceOf<VariableDeclarationStatement>());
    VariableDeclarationStatement declaration = statement;
    VariableDeclarationList variables = declaration.variables;
    TypeName type = variables.type;
    TypeArgumentList argumentList = type.typeArguments;
    expect(argumentList.leftBracket, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    expect(argumentList.arguments[0].isSynthetic, isTrue);
    expect(argumentList.rightBracket, isNotNull);
  }

  void test_parseStatement_functionDeclaration_noReturnType() {
    createParser('f(a, b) {};');
    Statement statement = parser.parseStatement2();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<FunctionDeclarationStatement>());
    FunctionDeclarationStatement declaration = statement;
    expect(declaration.functionDeclaration, isNotNull);
  }

  void
      test_parseStatement_functionDeclaration_noReturnType_typeParameterComments() {
    enableGenericMethodComments = true;
    createParser('f/*<E>*/(a, b) {};');
    Statement statement = parser.parseStatement2();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<FunctionDeclarationStatement>());
    FunctionDeclarationStatement declaration = statement;
    expect(declaration.functionDeclaration, isNotNull);
    expect(declaration.functionDeclaration.functionExpression.typeParameters,
        isNotNull);
  }

  void test_parseStatement_functionDeclaration_noReturnType_typeParameters() {
    createParser('f<E>(a, b) {};');
    Statement statement = parser.parseStatement2();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<FunctionDeclarationStatement>());
    FunctionDeclarationStatement declaration = statement;
    expect(declaration.functionDeclaration, isNotNull);
  }

  void test_parseStatement_functionDeclaration_returnType() {
    // TODO(brianwilkerson) Implement more tests for this method.
    createParser('int f(a, b) {};');
    Statement statement = parser.parseStatement2();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<FunctionDeclarationStatement>());
    FunctionDeclarationStatement declaration = statement;
    expect(declaration.functionDeclaration, isNotNull);
  }

  void test_parseStatement_functionDeclaration_returnType_typeParameters() {
    createParser('int f<E>(a, b) {};');
    Statement statement = parser.parseStatement2();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<FunctionDeclarationStatement>());
    FunctionDeclarationStatement declaration = statement;
    expect(declaration.functionDeclaration, isNotNull);
  }

  void test_parseStatement_mulipleLabels() {
    createParser('l: m: return x;');
    Statement statement = parser.parseStatement2();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<LabeledStatement>());
    LabeledStatement labeledStatement = statement;
    expect(labeledStatement.labels, hasLength(2));
    expect(labeledStatement.statement, isNotNull);
  }

  void test_parseStatement_noLabels() {
    createParser('return x;');
    Statement statement = parser.parseStatement2();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
  }

  void test_parseStatement_singleLabel() {
    createParser('l: return x;');
    Statement statement = parser.parseStatement2();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement, new isInstanceOf<LabeledStatement>());
    LabeledStatement labeledStatement = statement;
    expect(labeledStatement.labels, hasLength(1));
    expect(labeledStatement.labels[0].label.inDeclarationContext(), isTrue);
    expect(labeledStatement.statement, isNotNull);
  }

  void test_parseStatements_multiple() {
    List<Statement> statements =
        ParserTestCase.parseStatements("return; return;", 2);
    expect(statements, hasLength(2));
  }

  void test_parseStatements_single() {
    List<Statement> statements = ParserTestCase.parseStatements("return;", 1);
    expect(statements, hasLength(1));
  }

  void test_parseStringLiteral_adjacent() {
    createParser("'a' 'b'");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<AdjacentStrings>());
    AdjacentStrings literal = expression;
    NodeList<StringLiteral> strings = literal.strings;
    expect(strings, hasLength(2));
    StringLiteral firstString = strings[0];
    StringLiteral secondString = strings[1];
    expect((firstString as SimpleStringLiteral).value, "a");
    expect((secondString as SimpleStringLiteral).value, "b");
  }

  void test_parseStringLiteral_endsWithInterpolation() {
    createParser(r"'x$y'");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<StringInterpolation>());
    StringInterpolation interpolation = expression;
    expect(interpolation.elements, hasLength(3));
    expect(interpolation.elements[0], new isInstanceOf<InterpolationString>());
    InterpolationString element0 = interpolation.elements[0];
    expect(element0.value, 'x');
    expect(
        interpolation.elements[1], new isInstanceOf<InterpolationExpression>());
    InterpolationExpression element1 = interpolation.elements[1];
    expect(element1.expression, new isInstanceOf<SimpleIdentifier>());
    expect(interpolation.elements[2], new isInstanceOf<InterpolationString>());
    InterpolationString element2 = interpolation.elements[2];
    expect(element2.value, '');
  }

  void test_parseStringLiteral_interpolated() {
    createParser("'a \${b} c \$this d'");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<StringInterpolation>());
    StringInterpolation literal = expression;
    NodeList<InterpolationElement> elements = literal.elements;
    expect(elements, hasLength(5));
    expect(elements[0] is InterpolationString, isTrue);
    expect(elements[1] is InterpolationExpression, isTrue);
    expect(elements[2] is InterpolationString, isTrue);
    expect(elements[3] is InterpolationExpression, isTrue);
    expect(elements[4] is InterpolationString, isTrue);
  }

  void test_parseStringLiteral_multiline_encodedSpace() {
    createParser("'''\\x20\na'''");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<SimpleStringLiteral>());
    SimpleStringLiteral literal = expression;
    expect(literal.literal, isNotNull);
    expect(literal.value, " \na");
  }

  void test_parseStringLiteral_multiline_endsWithInterpolation() {
    createParser(r"'''x$y'''");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<StringInterpolation>());
    StringInterpolation interpolation = expression;
    expect(interpolation.elements, hasLength(3));
    expect(interpolation.elements[0], new isInstanceOf<InterpolationString>());
    InterpolationString element0 = interpolation.elements[0];
    expect(element0.value, 'x');
    expect(
        interpolation.elements[1], new isInstanceOf<InterpolationExpression>());
    InterpolationExpression element1 = interpolation.elements[1];
    expect(element1.expression, new isInstanceOf<SimpleIdentifier>());
    expect(interpolation.elements[2], new isInstanceOf<InterpolationString>());
    InterpolationString element2 = interpolation.elements[2];
    expect(element2.value, '');
  }

  void test_parseStringLiteral_multiline_escapedBackslash() {
    createParser("'''\\\\\na'''");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<SimpleStringLiteral>());
    SimpleStringLiteral literal = expression;
    expect(literal.literal, isNotNull);
    expect(literal.value, "\\\na");
  }

  void test_parseStringLiteral_multiline_escapedBackslash_raw() {
    createParser("r'''\\\\\na'''");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<SimpleStringLiteral>());
    SimpleStringLiteral literal = expression;
    expect(literal.literal, isNotNull);
    expect(literal.value, "\\\\\na");
  }

  void test_parseStringLiteral_multiline_escapedEolMarker() {
    createParser("'''\\\na'''");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<SimpleStringLiteral>());
    SimpleStringLiteral literal = expression;
    expect(literal.literal, isNotNull);
    expect(literal.value, "a");
  }

  void test_parseStringLiteral_multiline_escapedEolMarker_raw() {
    createParser("r'''\\\na'''");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<SimpleStringLiteral>());
    SimpleStringLiteral literal = expression;
    expect(literal.literal, isNotNull);
    expect(literal.value, "a");
  }

  void test_parseStringLiteral_multiline_escapedSpaceAndEolMarker() {
    createParser("'''\\ \\\na'''");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<SimpleStringLiteral>());
    SimpleStringLiteral literal = expression;
    expect(literal.literal, isNotNull);
    expect(literal.value, "a");
  }

  void test_parseStringLiteral_multiline_escapedSpaceAndEolMarker_raw() {
    createParser("r'''\\ \\\na'''");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<SimpleStringLiteral>());
    SimpleStringLiteral literal = expression;
    expect(literal.literal, isNotNull);
    expect(literal.value, "a");
  }

  void test_parseStringLiteral_multiline_escapedTab() {
    createParser("'''\\t\na'''");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<SimpleStringLiteral>());
    SimpleStringLiteral literal = expression;
    expect(literal.literal, isNotNull);
    expect(literal.value, "\t\na");
  }

  void test_parseStringLiteral_multiline_escapedTab_raw() {
    createParser("r'''\\t\na'''");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<SimpleStringLiteral>());
    SimpleStringLiteral literal = expression;
    expect(literal.literal, isNotNull);
    expect(literal.value, "\\t\na");
  }

  void test_parseStringLiteral_multiline_quoteAfterInterpolation() {
    createParser(r"""'''$x'y'''""");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<StringInterpolation>());
    StringInterpolation interpolation = expression;
    expect(interpolation.elements, hasLength(3));
    expect(interpolation.elements[0], new isInstanceOf<InterpolationString>());
    InterpolationString element0 = interpolation.elements[0];
    expect(element0.value, '');
    expect(
        interpolation.elements[1], new isInstanceOf<InterpolationExpression>());
    InterpolationExpression element1 = interpolation.elements[1];
    expect(element1.expression, new isInstanceOf<SimpleIdentifier>());
    expect(interpolation.elements[2], new isInstanceOf<InterpolationString>());
    InterpolationString element2 = interpolation.elements[2];
    expect(element2.value, "'y");
  }

  void test_parseStringLiteral_multiline_startsWithInterpolation() {
    createParser(r"'''${x}y'''");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<StringInterpolation>());
    StringInterpolation interpolation = expression;
    expect(interpolation.elements, hasLength(3));
    expect(interpolation.elements[0], new isInstanceOf<InterpolationString>());
    InterpolationString element0 = interpolation.elements[0];
    expect(element0.value, '');
    expect(
        interpolation.elements[1], new isInstanceOf<InterpolationExpression>());
    InterpolationExpression element1 = interpolation.elements[1];
    expect(element1.expression, new isInstanceOf<SimpleIdentifier>());
    expect(interpolation.elements[2], new isInstanceOf<InterpolationString>());
    InterpolationString element2 = interpolation.elements[2];
    expect(element2.value, 'y');
  }

  void test_parseStringLiteral_multiline_twoSpaces() {
    createParser("'''  \na'''");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<SimpleStringLiteral>());
    SimpleStringLiteral literal = expression;
    expect(literal.literal, isNotNull);
    expect(literal.value, "a");
  }

  void test_parseStringLiteral_multiline_twoSpaces_raw() {
    createParser("r'''  \na'''");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<SimpleStringLiteral>());
    SimpleStringLiteral literal = expression;
    expect(literal.literal, isNotNull);
    expect(literal.value, "a");
  }

  void test_parseStringLiteral_multiline_untrimmed() {
    createParser("''' a\nb'''");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<SimpleStringLiteral>());
    SimpleStringLiteral literal = expression;
    expect(literal.literal, isNotNull);
    expect(literal.value, " a\nb");
  }

  void test_parseStringLiteral_quoteAfterInterpolation() {
    createParser(r"""'$x"'""");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<StringInterpolation>());
    StringInterpolation interpolation = expression;
    expect(interpolation.elements, hasLength(3));
    expect(interpolation.elements[0], new isInstanceOf<InterpolationString>());
    InterpolationString element0 = interpolation.elements[0];
    expect(element0.value, '');
    expect(
        interpolation.elements[1], new isInstanceOf<InterpolationExpression>());
    InterpolationExpression element1 = interpolation.elements[1];
    expect(element1.expression, new isInstanceOf<SimpleIdentifier>());
    expect(interpolation.elements[2], new isInstanceOf<InterpolationString>());
    InterpolationString element2 = interpolation.elements[2];
    expect(element2.value, '"');
  }

  void test_parseStringLiteral_single() {
    createParser("'a'");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<SimpleStringLiteral>());
    SimpleStringLiteral literal = expression;
    expect(literal.literal, isNotNull);
    expect(literal.value, "a");
  }

  void test_parseStringLiteral_startsWithInterpolation() {
    createParser(r"'${x}y'");
    Expression expression = parser.parseStringLiteral();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<StringInterpolation>());
    StringInterpolation interpolation = expression;
    expect(interpolation.elements, hasLength(3));
    expect(interpolation.elements[0], new isInstanceOf<InterpolationString>());
    InterpolationString element0 = interpolation.elements[0];
    expect(element0.value, '');
    expect(
        interpolation.elements[1], new isInstanceOf<InterpolationExpression>());
    InterpolationExpression element1 = interpolation.elements[1];
    expect(element1.expression, new isInstanceOf<SimpleIdentifier>());
    expect(interpolation.elements[2], new isInstanceOf<InterpolationString>());
    InterpolationString element2 = interpolation.elements[2];
    expect(element2.value, 'y');
  }

  void test_parseSuperConstructorInvocation_named() {
    createParser('super.a()');
    SuperConstructorInvocation invocation =
        parser.parseSuperConstructorInvocation();
    expectNotNullIfNoErrors(invocation);
    listener.assertNoErrors();
    expect(invocation.argumentList, isNotNull);
    expect(invocation.constructorName, isNotNull);
    expect(invocation.superKeyword, isNotNull);
    expect(invocation.period, isNotNull);
  }

  void test_parseSuperConstructorInvocation_unnamed() {
    createParser('super()');
    SuperConstructorInvocation invocation =
        parser.parseSuperConstructorInvocation();
    expectNotNullIfNoErrors(invocation);
    listener.assertNoErrors();
    expect(invocation.argumentList, isNotNull);
    expect(invocation.constructorName, isNull);
    expect(invocation.superKeyword, isNotNull);
    expect(invocation.period, isNull);
  }

  void test_parseSwitchStatement_case() {
    createParser('switch (a) {case 1: return "I";}');
    SwitchStatement statement = parser.parseSwitchStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.switchKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.leftBracket, isNotNull);
    expect(statement.members, hasLength(1));
    expect(statement.rightBracket, isNotNull);
  }

  void test_parseSwitchStatement_empty() {
    createParser('switch (a) {}');
    SwitchStatement statement = parser.parseSwitchStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.switchKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.leftBracket, isNotNull);
    expect(statement.members, hasLength(0));
    expect(statement.rightBracket, isNotNull);
  }

  void test_parseSwitchStatement_labeledCase() {
    createParser('switch (a) {l1: l2: l3: case(1):}');
    SwitchStatement statement = parser.parseSwitchStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.switchKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.leftBracket, isNotNull);
    expect(statement.members, hasLength(1));
    {
      List<Label> labels = statement.members[0].labels;
      expect(labels, hasLength(3));
      expect(labels[0].label.inDeclarationContext(), isTrue);
      expect(labels[1].label.inDeclarationContext(), isTrue);
      expect(labels[2].label.inDeclarationContext(), isTrue);
    }
    expect(statement.rightBracket, isNotNull);
  }

  void test_parseSwitchStatement_labeledDefault() {
    createParser('switch (a) {l1: l2: l3: default:}');
    SwitchStatement statement = parser.parseSwitchStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.switchKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.leftBracket, isNotNull);
    expect(statement.members, hasLength(1));
    {
      List<Label> labels = statement.members[0].labels;
      expect(labels, hasLength(3));
      expect(labels[0].label.inDeclarationContext(), isTrue);
      expect(labels[1].label.inDeclarationContext(), isTrue);
      expect(labels[2].label.inDeclarationContext(), isTrue);
    }
    expect(statement.rightBracket, isNotNull);
  }

  void test_parseSwitchStatement_labeledStatementInCase() {
    createParser('switch (a) {case 0: f(); l1: g(); break;}');
    SwitchStatement statement = parser.parseSwitchStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.switchKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.leftBracket, isNotNull);
    expect(statement.members, hasLength(1));
    expect(statement.members[0].statements, hasLength(3));
    expect(statement.rightBracket, isNotNull);
  }

  void test_parseSymbolLiteral_builtInIdentifier() {
    createParser('#dynamic.static.abstract');
    SymbolLiteral literal = parser.parseSymbolLiteral();
    expectNotNullIfNoErrors(literal);
    listener.assertNoErrors();
    expect(literal.poundSign, isNotNull);
    List<Token> components = literal.components;
    expect(components, hasLength(3));
    expect(components[0].lexeme, "dynamic");
    expect(components[1].lexeme, "static");
    expect(components[2].lexeme, "abstract");
  }

  void test_parseSymbolLiteral_multiple() {
    createParser('#a.b.c');
    SymbolLiteral literal = parser.parseSymbolLiteral();
    expectNotNullIfNoErrors(literal);
    listener.assertNoErrors();
    expect(literal.poundSign, isNotNull);
    List<Token> components = literal.components;
    expect(components, hasLength(3));
    expect(components[0].lexeme, "a");
    expect(components[1].lexeme, "b");
    expect(components[2].lexeme, "c");
  }

  void test_parseSymbolLiteral_operator() {
    createParser('#==');
    SymbolLiteral literal = parser.parseSymbolLiteral();
    expectNotNullIfNoErrors(literal);
    listener.assertNoErrors();
    expect(literal.poundSign, isNotNull);
    List<Token> components = literal.components;
    expect(components, hasLength(1));
    expect(components[0].lexeme, "==");
  }

  void test_parseSymbolLiteral_single() {
    createParser('#a');
    SymbolLiteral literal = parser.parseSymbolLiteral();
    expectNotNullIfNoErrors(literal);
    listener.assertNoErrors();
    expect(literal.poundSign, isNotNull);
    List<Token> components = literal.components;
    expect(components, hasLength(1));
    expect(components[0].lexeme, "a");
  }

  void test_parseSymbolLiteral_void() {
    createParser('#void');
    SymbolLiteral literal = parser.parseSymbolLiteral();
    expectNotNullIfNoErrors(literal);
    listener.assertNoErrors();
    expect(literal.poundSign, isNotNull);
    List<Token> components = literal.components;
    expect(components, hasLength(1));
    expect(components[0].lexeme, "void");
  }

  void test_parseThrowExpression() {
    createParser('throw x;');
    Expression expression = parser.parseThrowExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<ThrowExpression>());
    ThrowExpression throwExpression = expression;
    expect(throwExpression.throwKeyword, isNotNull);
    expect(throwExpression.expression, isNotNull);
  }

  void test_parseThrowExpressionWithoutCascade() {
    createParser('throw x;');
    Expression expression = parser.parseThrowExpressionWithoutCascade();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression, new isInstanceOf<ThrowExpression>());
    ThrowExpression throwExpression = expression;
    expect(throwExpression.throwKeyword, isNotNull);
    expect(throwExpression.expression, isNotNull);
  }

  void test_parseTryStatement_catch() {
    createParser('try {} catch (e) {}');
    TryStatement statement = parser.parseTryStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    expect(catchClauses, hasLength(1));
    CatchClause clause = catchClauses[0];
    expect(clause.onKeyword, isNull);
    expect(clause.exceptionType, isNull);
    expect(clause.catchKeyword, isNotNull);
    expect(clause.exceptionParameter, isNotNull);
    expect(clause.comma, isNull);
    expect(clause.stackTraceParameter, isNull);
    expect(clause.body, isNotNull);
    expect(statement.finallyKeyword, isNull);
    expect(statement.finallyBlock, isNull);
  }

  void test_parseTryStatement_catch_finally() {
    createParser('try {} catch (e, s) {} finally {}');
    TryStatement statement = parser.parseTryStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    expect(catchClauses, hasLength(1));
    CatchClause clause = catchClauses[0];
    expect(clause.onKeyword, isNull);
    expect(clause.exceptionType, isNull);
    expect(clause.catchKeyword, isNotNull);
    expect(clause.exceptionParameter, isNotNull);
    expect(clause.comma, isNotNull);
    expect(clause.stackTraceParameter, isNotNull);
    expect(clause.body, isNotNull);
    expect(statement.finallyKeyword, isNotNull);
    expect(statement.finallyBlock, isNotNull);
  }

  void test_parseTryStatement_finally() {
    createParser('try {} finally {}');
    TryStatement statement = parser.parseTryStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    expect(statement.catchClauses, hasLength(0));
    expect(statement.finallyKeyword, isNotNull);
    expect(statement.finallyBlock, isNotNull);
  }

  void test_parseTryStatement_multiple() {
    createParser('try {} on NPE catch (e) {} on Error {} catch (e) {}');
    TryStatement statement = parser.parseTryStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    expect(statement.catchClauses, hasLength(3));
    expect(statement.finallyKeyword, isNull);
    expect(statement.finallyBlock, isNull);
  }

  void test_parseTryStatement_on() {
    createParser('try {} on Error {}');
    TryStatement statement = parser.parseTryStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    expect(catchClauses, hasLength(1));
    CatchClause clause = catchClauses[0];
    expect(clause.onKeyword, isNotNull);
    expect(clause.exceptionType, isNotNull);
    expect(clause.catchKeyword, isNull);
    expect(clause.exceptionParameter, isNull);
    expect(clause.comma, isNull);
    expect(clause.stackTraceParameter, isNull);
    expect(clause.body, isNotNull);
    expect(statement.finallyKeyword, isNull);
    expect(statement.finallyBlock, isNull);
  }

  void test_parseTryStatement_on_catch() {
    createParser('try {} on Error catch (e, s) {}');
    TryStatement statement = parser.parseTryStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    expect(catchClauses, hasLength(1));
    CatchClause clause = catchClauses[0];
    expect(clause.onKeyword, isNotNull);
    expect(clause.exceptionType, isNotNull);
    expect(clause.catchKeyword, isNotNull);
    expect(clause.exceptionParameter, isNotNull);
    expect(clause.comma, isNotNull);
    expect(clause.stackTraceParameter, isNotNull);
    expect(clause.body, isNotNull);
    expect(statement.finallyKeyword, isNull);
    expect(statement.finallyBlock, isNull);
  }

  void test_parseTryStatement_on_catch_finally() {
    createParser('try {} on Error catch (e, s) {} finally {}');
    TryStatement statement = parser.parseTryStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    expect(catchClauses, hasLength(1));
    CatchClause clause = catchClauses[0];
    expect(clause.onKeyword, isNotNull);
    expect(clause.exceptionType, isNotNull);
    expect(clause.catchKeyword, isNotNull);
    expect(clause.exceptionParameter, isNotNull);
    expect(clause.comma, isNotNull);
    expect(clause.stackTraceParameter, isNotNull);
    expect(clause.body, isNotNull);
    expect(statement.finallyKeyword, isNotNull);
    expect(statement.finallyBlock, isNotNull);
  }

  void test_parseTypeAlias_function_noParameters() {
    createParser('typedef bool F();');
    FunctionTypeAlias typeAlias =
        parser.parseTypeAlias(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(typeAlias);
    listener.assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.parameters, isNotNull);
    expect(typeAlias.returnType, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    expect(typeAlias.typeParameters, isNull);
  }

  void test_parseTypeAlias_function_noReturnType() {
    createParser('typedef F();');
    FunctionTypeAlias typeAlias =
        parser.parseTypeAlias(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(typeAlias);
    listener.assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.parameters, isNotNull);
    expect(typeAlias.returnType, isNull);
    expect(typeAlias.semicolon, isNotNull);
    expect(typeAlias.typeParameters, isNull);
  }

  void test_parseTypeAlias_function_parameterizedReturnType() {
    createParser('typedef A<B> F();');
    FunctionTypeAlias typeAlias =
        parser.parseTypeAlias(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(typeAlias);
    listener.assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.parameters, isNotNull);
    expect(typeAlias.returnType, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    expect(typeAlias.typeParameters, isNull);
  }

  void test_parseTypeAlias_function_parameters() {
    createParser('typedef bool F(Object value);');
    FunctionTypeAlias typeAlias =
        parser.parseTypeAlias(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(typeAlias);
    listener.assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.parameters, isNotNull);
    expect(typeAlias.returnType, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    expect(typeAlias.typeParameters, isNull);
  }

  void test_parseTypeAlias_function_typeParameters() {
    createParser('typedef bool F<E>();');
    FunctionTypeAlias typeAlias =
        parser.parseTypeAlias(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(typeAlias);
    listener.assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.parameters, isNotNull);
    expect(typeAlias.returnType, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    expect(typeAlias.typeParameters, isNotNull);
  }

  void test_parseTypeAlias_function_voidReturnType() {
    createParser('typedef void F();');
    FunctionTypeAlias typeAlias =
        parser.parseTypeAlias(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(typeAlias);
    listener.assertNoErrors();
    expect(typeAlias.typedefKeyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.parameters, isNotNull);
    expect(typeAlias.returnType, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    expect(typeAlias.typeParameters, isNull);
  }

  void test_parseTypeArgumentList_empty() {
    createParser('<>');
    TypeArgumentList argumentList = parser.parseTypeArgumentList();
    expectNotNullIfNoErrors(argumentList);
    listener.assertErrorsWithCodes([ParserErrorCode.EXPECTED_TYPE_NAME]);
    expect(argumentList.leftBracket, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    expect(argumentList.rightBracket, isNotNull);
  }

  void test_parseTypeArgumentList_multiple() {
    createParser('<int, int, int>');
    TypeArgumentList argumentList = parser.parseTypeArgumentList();
    expectNotNullIfNoErrors(argumentList);
    listener.assertNoErrors();
    expect(argumentList.leftBracket, isNotNull);
    expect(argumentList.arguments, hasLength(3));
    expect(argumentList.rightBracket, isNotNull);
  }

  void test_parseTypeArgumentList_nested() {
    createParser('<A<B>>');
    TypeArgumentList argumentList = parser.parseTypeArgumentList();
    expectNotNullIfNoErrors(argumentList);
    listener.assertNoErrors();
    expect(argumentList.leftBracket, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    TypeName argument = argumentList.arguments[0];
    expect(argument, isNotNull);
    TypeArgumentList innerList = argument.typeArguments;
    expect(innerList, isNotNull);
    expect(innerList.arguments, hasLength(1));
    expect(argumentList.rightBracket, isNotNull);
  }

  void test_parseTypeArgumentList_nested_withComment_double() {
    createParser('<A<B /* 0 */ >>');
    TypeArgumentList argumentList = parser.parseTypeArgumentList();
    expectNotNullIfNoErrors(argumentList);
    listener.assertNoErrors();
    expect(argumentList.leftBracket, isNotNull);
    expect(argumentList.rightBracket, isNotNull);
    expect(argumentList.arguments, hasLength(1));

    TypeName argument = argumentList.arguments[0];
    expect(argument, isNotNull);

    TypeArgumentList innerList = argument.typeArguments;
    expect(innerList, isNotNull);
    expect(innerList.leftBracket, isNotNull);
    expect(innerList.arguments, hasLength(1));
    expect(innerList.rightBracket, isNotNull);
    expect(innerList.rightBracket.precedingComments, isNotNull);
  }

  void test_parseTypeArgumentList_nested_withComment_tripple() {
    createParser('<A<B<C /* 0 */ >>>');
    TypeArgumentList argumentList = parser.parseTypeArgumentList();
    expectNotNullIfNoErrors(argumentList);
    listener.assertNoErrors();
    expect(argumentList.leftBracket, isNotNull);
    expect(argumentList.rightBracket, isNotNull);
    expect(argumentList.arguments, hasLength(1));

    TypeName argument = argumentList.arguments[0];
    expect(argument, isNotNull);

    TypeArgumentList innerList = argument.typeArguments;
    expect(innerList, isNotNull);
    expect(innerList.leftBracket, isNotNull);
    expect(innerList.arguments, hasLength(1));
    expect(innerList.rightBracket, isNotNull);

    TypeName innerArgument = innerList.arguments[0];
    expect(innerArgument, isNotNull);

    TypeArgumentList innerInnerList = innerArgument.typeArguments;
    expect(innerInnerList, isNotNull);
    expect(innerInnerList.leftBracket, isNotNull);
    expect(innerInnerList.arguments, hasLength(1));
    expect(innerInnerList.rightBracket, isNotNull);
    expect(innerInnerList.rightBracket.precedingComments, isNotNull);
  }

  void test_parseTypeArgumentList_single() {
    createParser('<int>');
    TypeArgumentList argumentList = parser.parseTypeArgumentList();
    expectNotNullIfNoErrors(argumentList);
    listener.assertNoErrors();
    expect(argumentList.leftBracket, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    expect(argumentList.rightBracket, isNotNull);
  }

  void test_parseTypeName_parameterized() {
    createParser('List<int>');
    TypeName typeName = parser.parseTypeName(false);
    expectNotNullIfNoErrors(typeName);
    listener.assertNoErrors();
    expect(typeName.name, isNotNull);
    expect(typeName.typeArguments, isNotNull);
    expect(typeName.question, isNull);
  }

  void test_parseTypeName_parameterized_nullable() {
    enableNnbd = true;
    createParser('List<int>?');
    TypeName typeName = parser.parseTypeName(false);
    expectNotNullIfNoErrors(typeName);
    listener.assertNoErrors();
    expect(typeName.name, isNotNull);
    expect(typeName.typeArguments, isNotNull);
    expect(typeName.question, isNotNull);
  }

  void test_parseTypeName_simple() {
    createParser('int');
    TypeName typeName = parser.parseTypeName(false);
    expectNotNullIfNoErrors(typeName);
    listener.assertNoErrors();
    expect(typeName.name, isNotNull);
    expect(typeName.typeArguments, isNull);
    expect(typeName.question, isNull);
  }

  void test_parseTypeName_simple_nullable() {
    enableNnbd = true;
    createParser('String?');
    TypeName typeName = parser.parseTypeName(false);
    expectNotNullIfNoErrors(typeName);
    listener.assertNoErrors();
    expect(typeName.name, isNotNull);
    expect(typeName.typeArguments, isNull);
    expect(typeName.question, isNotNull);
  }

  void test_parseTypeParameter_bounded() {
    createParser('A extends B');
    TypeParameter parameter = parser.parseTypeParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter.bound, isNotNull);
    expect(parameter.extendsKeyword, isNotNull);
    expect(parameter.name, isNotNull);
  }

  void test_parseTypeParameter_bounded_nullable() {
    enableNnbd = true;
    createParser('A extends B?');
    TypeParameter parameter = parser.parseTypeParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter.bound, isNotNull);
    expect(parameter.extendsKeyword, isNotNull);
    expect(parameter.name, isNotNull);
    TypeName bound = parameter.bound;
    expect(bound, isNotNull);
    expect(bound.question, isNotNull);
  }

  void test_parseTypeParameter_simple() {
    createParser('A');
    TypeParameter parameter = parser.parseTypeParameter();
    expectNotNullIfNoErrors(parameter);
    listener.assertNoErrors();
    expect(parameter.bound, isNull);
    expect(parameter.extendsKeyword, isNull);
    expect(parameter.name, isNotNull);
  }

  void test_parseTypeParameterList_multiple() {
    createParser('<A, B extends C, D>');
    TypeParameterList parameterList = parser.parseTypeParameterList();
    expectNotNullIfNoErrors(parameterList);
    listener.assertNoErrors();
    expect(parameterList.leftBracket, isNotNull);
    expect(parameterList.rightBracket, isNotNull);
    expect(parameterList.typeParameters, hasLength(3));
  }

  void test_parseTypeParameterList_parameterizedWithTrailingEquals() {
    createParser('<A extends B<E>>=');
    TypeParameterList parameterList = parser.parseTypeParameterList();
    expectNotNullIfNoErrors(parameterList);
    listener.assertNoErrors();
    expect(parameterList.leftBracket, isNotNull);
    expect(parameterList.rightBracket, isNotNull);
    expect(parameterList.typeParameters, hasLength(1));
  }

  void test_parseTypeParameterList_single() {
    createParser('<<A>');
    TypeParameterList parameterList = parser.parseTypeParameterList();
    expectNotNullIfNoErrors(parameterList);
    listener.assertNoErrors();
    expect(parameterList.leftBracket, isNotNull);
    expect(parameterList.rightBracket, isNotNull);
    expect(parameterList.typeParameters, hasLength(1));
  }

  void test_parseTypeParameterList_withTrailingEquals() {
    createParser('<A>=');
    TypeParameterList parameterList = parser.parseTypeParameterList();
    expectNotNullIfNoErrors(parameterList);
    listener.assertNoErrors();
    expect(parameterList.leftBracket, isNotNull);
    expect(parameterList.rightBracket, isNotNull);
    expect(parameterList.typeParameters, hasLength(1));
  }

  void test_parseUnaryExpression_decrement_normal() {
    createParser('--x');
    PrefixExpression expression = parser.parseUnaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS_MINUS);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_decrement_super() {
    createParser('--super');
    PrefixExpression expression = parser.parseUnaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS);
    Expression innerExpression = expression.operand;
    expect(innerExpression, isNotNull);
    expect(innerExpression is PrefixExpression, isTrue);
    PrefixExpression operand = innerExpression as PrefixExpression;
    expect(operand.operator, isNotNull);
    expect(operand.operator.type, TokenType.MINUS);
    expect(operand.operand, isNotNull);
  }

  void test_parseUnaryExpression_decrement_super_propertyAccess() {
    createParser('--super.x');
    PrefixExpression expression = parser.parseUnaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS_MINUS);
    expect(expression.operand, isNotNull);
    PropertyAccess operand = expression.operand as PropertyAccess;
    expect(operand.target is SuperExpression, isTrue);
    expect(operand.propertyName.name, "x");
  }

  void test_parseUnaryExpression_decrement_super_withComment() {
    createParser('/* 0 */ --super');
    PrefixExpression expression = parser.parseUnaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS);
    expect(expression.operator.precedingComments, isNotNull);
    Expression innerExpression = expression.operand;
    expect(innerExpression, isNotNull);
    expect(innerExpression is PrefixExpression, isTrue);
    PrefixExpression operand = innerExpression as PrefixExpression;
    expect(operand.operator, isNotNull);
    expect(operand.operator.type, TokenType.MINUS);
    expect(operand.operand, isNotNull);
  }

  void test_parseUnaryExpression_increment_normal() {
    createParser('++x');
    PrefixExpression expression = parser.parseUnaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.PLUS_PLUS);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_increment_super_index() {
    createParser('++super[0]');
    PrefixExpression expression = parser.parseUnaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.PLUS_PLUS);
    expect(expression.operand, isNotNull);
    IndexExpression operand = expression.operand as IndexExpression;
    expect(operand.realTarget is SuperExpression, isTrue);
    expect(operand.index is IntegerLiteral, isTrue);
  }

  void test_parseUnaryExpression_increment_super_propertyAccess() {
    createParser('++super.x');
    PrefixExpression expression = parser.parseUnaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.PLUS_PLUS);
    expect(expression.operand, isNotNull);
    PropertyAccess operand = expression.operand as PropertyAccess;
    expect(operand.target is SuperExpression, isTrue);
    expect(operand.propertyName.name, "x");
  }

  void test_parseUnaryExpression_minus_normal() {
    createParser('-x');
    PrefixExpression expression = parser.parseUnaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_minus_super() {
    createParser('-super');
    PrefixExpression expression = parser.parseUnaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_not_normal() {
    createParser('!x');
    PrefixExpression expression = parser.parseUnaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.BANG);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_not_super() {
    createParser('!super');
    PrefixExpression expression = parser.parseUnaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.BANG);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_tilda_normal() {
    createParser('~x');
    PrefixExpression expression = parser.parseUnaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.TILDE);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_tilda_super() {
    createParser('~super');
    PrefixExpression expression = parser.parseUnaryExpression();
    expectNotNullIfNoErrors(expression);
    listener.assertNoErrors();
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.TILDE);
    expect(expression.operand, isNotNull);
  }

  void test_parseVariableDeclaration_equals() {
    createParser('a = b');
    VariableDeclaration declaration = parser.parseVariableDeclaration();
    expectNotNullIfNoErrors(declaration);
    listener.assertNoErrors();
    expect(declaration.name, isNotNull);
    expect(declaration.equals, isNotNull);
    expect(declaration.initializer, isNotNull);
  }

  void test_parseVariableDeclaration_noEquals() {
    createParser('a');
    VariableDeclaration declaration = parser.parseVariableDeclaration();
    expectNotNullIfNoErrors(declaration);
    listener.assertNoErrors();
    expect(declaration.name, isNotNull);
    expect(declaration.equals, isNull);
    expect(declaration.initializer, isNull);
  }

  void test_parseVariableDeclarationListAfterMetadata_const_noType() {
    createParser('const a');
    VariableDeclarationList declarationList = parser
        .parseVariableDeclarationListAfterMetadata(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(declarationList);
    listener.assertNoErrors();
    expect(declarationList.keyword, isNotNull);
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterMetadata_const_type() {
    createParser('const A a');
    VariableDeclarationList declarationList = parser
        .parseVariableDeclarationListAfterMetadata(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(declarationList);
    listener.assertNoErrors();
    expect(declarationList.keyword, isNotNull);
    expect(declarationList.type, isNotNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterMetadata_final_noType() {
    createParser('final a');
    VariableDeclarationList declarationList = parser
        .parseVariableDeclarationListAfterMetadata(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(declarationList);
    listener.assertNoErrors();
    expect(declarationList.keyword, isNotNull);
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterMetadata_final_type() {
    createParser('final A a');
    VariableDeclarationList declarationList = parser
        .parseVariableDeclarationListAfterMetadata(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(declarationList);
    listener.assertNoErrors();
    expect(declarationList.keyword, isNotNull);
    expect(declarationList.type, isNotNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterMetadata_final_typeComment() {
    enableGenericMethodComments = true;
    createParser('final/*=T*/ x');
    VariableDeclarationList declarationList = parser
        .parseVariableDeclarationListAfterMetadata(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(declarationList);
    listener.assertNoErrors();
    expect(declarationList.type.name.name, 'T');
    expect(declarationList.isFinal, true);
  }

  void test_parseVariableDeclarationListAfterMetadata_type_multiple() {
    createParser('A a, b, c');
    VariableDeclarationList declarationList = parser
        .parseVariableDeclarationListAfterMetadata(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(declarationList);
    listener.assertNoErrors();
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, isNotNull);
    expect(declarationList.variables, hasLength(3));
  }

  void test_parseVariableDeclarationListAfterMetadata_type_single() {
    createParser('A a');
    VariableDeclarationList declarationList = parser
        .parseVariableDeclarationListAfterMetadata(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(declarationList);
    listener.assertNoErrors();
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, isNotNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterMetadata_var_multiple() {
    createParser('var a, b, c');
    VariableDeclarationList declarationList = parser
        .parseVariableDeclarationListAfterMetadata(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(declarationList);
    listener.assertNoErrors();
    expect(declarationList.keyword, isNotNull);
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(3));
  }

  void test_parseVariableDeclarationListAfterMetadata_var_single() {
    createParser('var a');
    VariableDeclarationList declarationList = parser
        .parseVariableDeclarationListAfterMetadata(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(declarationList);
    listener.assertNoErrors();
    expect(declarationList.keyword, isNotNull);
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterMetadata_var_typeComment() {
    enableGenericMethodComments = true;
    createParser('var/*=T*/ x');
    VariableDeclarationList declarationList = parser
        .parseVariableDeclarationListAfterMetadata(emptyCommentAndMetadata());
    expectNotNullIfNoErrors(declarationList);
    listener.assertNoErrors();
    expect(declarationList.type.name.name, 'T');
    expect(declarationList.keyword, isNull);
  }

  void test_parseVariableDeclarationListAfterType_type() {
    TypeName type = new TypeName(new SimpleIdentifier(null), null);
    createParser('a');
    VariableDeclarationList declarationList =
        parser.parseVariableDeclarationListAfterType(
            emptyCommentAndMetadata(), null, type);
    expectNotNullIfNoErrors(declarationList);
    listener.assertNoErrors();
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, type);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterType_var() {
    Token keyword = TokenFactory.tokenFromKeyword(Keyword.VAR);
    createParser('a, b, c');
    VariableDeclarationList declarationList =
        parser.parseVariableDeclarationListAfterType(
            emptyCommentAndMetadata(), keyword, null);
    expectNotNullIfNoErrors(declarationList);
    listener.assertNoErrors();
    expect(declarationList.keyword, keyword);
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(3));
  }

  void test_parseVariableDeclarationStatementAfterMetadata_multiple() {
    createParser('var x, y, z;');
    VariableDeclarationStatement statement =
        parser.parseVariableDeclarationStatementAfterMetadata(
            emptyCommentAndMetadata());
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.semicolon, isNotNull);
    VariableDeclarationList variableList = statement.variables;
    expect(variableList, isNotNull);
    expect(variableList.variables, hasLength(3));
  }

  void test_parseVariableDeclarationStatementAfterMetadata_single() {
    createParser('var x;');
    VariableDeclarationStatement statement =
        parser.parseVariableDeclarationStatementAfterMetadata(
            emptyCommentAndMetadata());
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.semicolon, isNotNull);
    VariableDeclarationList variableList = statement.variables;
    expect(variableList, isNotNull);
    expect(variableList.variables, hasLength(1));
  }

  void test_parseWhileStatement() {
    createParser('while (x) {}');
    WhileStatement statement = parser.parseWhileStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.whileKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.body, isNotNull);
  }

  void test_parseWithClause_multiple() {
    createParser('with A, B, C');
    WithClause clause = parser.parseWithClause();
    expectNotNullIfNoErrors(clause);
    listener.assertNoErrors();
    expect(clause.withKeyword, isNotNull);
    expect(clause.mixinTypes, hasLength(3));
  }

  void test_parseWithClause_single() {
    createParser('with M');
    WithClause clause = parser.parseWithClause();
    expectNotNullIfNoErrors(clause);
    listener.assertNoErrors();
    expect(clause.withKeyword, isNotNull);
    expect(clause.mixinTypes, hasLength(1));
  }

  void test_parseYieldStatement_each() {
    createParser('yield* x;');
    YieldStatement statement = parser.parseYieldStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.yieldKeyword, isNotNull);
    expect(statement.star, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseYieldStatement_normal() {
    createParser('yield x;');
    YieldStatement statement = parser.parseYieldStatement();
    expectNotNullIfNoErrors(statement);
    listener.assertNoErrors();
    expect(statement.yieldKeyword, isNotNull);
    expect(statement.star, isNull);
    expect(statement.expression, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_skipPrefixedIdentifier_invalid() {
    createParser('+');
    Token following = parser.skipPrefixedIdentifier(parser.currentToken);
    expect(following, isNull);
  }

  void test_skipPrefixedIdentifier_notPrefixed() {
    createParser('a +');
    Token following = parser.skipPrefixedIdentifier(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipPrefixedIdentifier_prefixed() {
    createParser('a.b +');
    Token following = parser.skipPrefixedIdentifier(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipReturnType_invalid() {
    createParser('+');
    Token following = parser.skipReturnType(parser.currentToken);
    expect(following, isNull);
  }

  void test_skipReturnType_type() {
    createParser('C +');
    Token following = parser.skipReturnType(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipReturnType_void() {
    createParser('void +');
    Token following = parser.skipReturnType(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipSimpleIdentifier_identifier() {
    createParser('i +');
    Token following = parser.skipSimpleIdentifier(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipSimpleIdentifier_invalid() {
    createParser('9 +');
    Token following = parser.skipSimpleIdentifier(parser.currentToken);
    expect(following, isNull);
  }

  void test_skipSimpleIdentifier_pseudoKeyword() {
    createParser('as +');
    Token following = parser.skipSimpleIdentifier(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipStringLiteral_adjacent() {
    createParser("'a' 'b' +");
    Token following = parser.skipStringLiteral(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipStringLiteral_interpolated() {
    createParser("'a\${b}c' +");
    Token following = parser.skipStringLiteral(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipStringLiteral_invalid() {
    createParser('a');
    Token following = parser.skipStringLiteral(parser.currentToken);
    expect(following, isNull);
  }

  void test_skipStringLiteral_single() {
    createParser("'a' +");
    Token following = parser.skipStringLiteral(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipTypeArgumentList_invalid() {
    createParser('+');
    Token following = parser.skipTypeArgumentList(parser.currentToken);
    expect(following, isNull);
  }

  void test_skipTypeArgumentList_multiple() {
    createParser('<E, F, G> +');
    Token following = parser.skipTypeArgumentList(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipTypeArgumentList_single() {
    createParser('<E> +');
    Token following = parser.skipTypeArgumentList(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipTypeName_invalid() {
    createParser('+');
    Token following = parser.skipTypeName(parser.currentToken);
    expect(following, isNull);
  }

  void test_skipTypeName_parameterized() {
    createParser('C<E<F<G>>> +');
    Token following = parser.skipTypeName(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipTypeName_simple() {
    createParser('C +');
    Token following = parser.skipTypeName(parser.currentToken);
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  /**
   * Invoke the method [Parser.computeStringValue] with the given argument.
   *
   * @param lexeme the argument to the method
   * @param first `true` if this is the first token in a string literal
   * @param last `true` if this is the last token in a string literal
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   */
  String _computeStringValue(String lexeme, bool first, bool last) {
    createParser('');
    String value = parser.computeStringValue(lexeme, first, last);
    listener.assertNoErrors();
    return value;
  }

  void _expectDottedName(DottedName name, List<String> expectedComponents) {
    int count = expectedComponents.length;
    NodeList<SimpleIdentifier> components = name.components;
    expect(components, hasLength(count));
    for (int i = 0; i < count; i++) {
      SimpleIdentifier component = components[i];
      expect(component, isNotNull);
      expect(component.name, expectedComponents[i]);
    }
  }

  /**
   * Invoke the method [Parser.isFunctionDeclaration] with the parser set to the token
   * stream produced by scanning the given source.
   *
   * @param source the source to be scanned to produce the token stream being tested
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   */
  bool _isFunctionDeclaration(String source) {
    createParser(source);
    bool result = parser.isFunctionDeclaration();
    expectNotNullIfNoErrors(result);
    return result;
  }

  /**
   * Invoke the method [Parser.isFunctionExpression] with the parser set to the token stream
   * produced by scanning the given source.
   *
   * @param source the source to be scanned to produce the token stream being tested
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   */
  bool _isFunctionExpression(String source) {
    createParser(source);
    return parser.isFunctionExpression(parser.currentToken);
  }

  /**
   * Invoke the method [Parser.isInitializedVariableDeclaration] with the parser set to the
   * token stream produced by scanning the given source.
   *
   * @param source the source to be scanned to produce the token stream being tested
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   */
  bool _isInitializedVariableDeclaration(String source) {
    createParser(source);
    bool result = parser.isInitializedVariableDeclaration();
    expectNotNullIfNoErrors(result);
    return result;
  }

  /**
   * Invoke the method [Parser.isSwitchMember] with the parser set to the token stream
   * produced by scanning the given source.
   *
   * @param source the source to be scanned to produce the token stream being tested
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   */
  bool _isSwitchMember(String source) {
    createParser(source);
    bool result = parser.isSwitchMember();
    expectNotNullIfNoErrors(result);
    return result;
  }

  /**
   * Parse the given source as a compilation unit.
   *
   * @param source the source to be parsed
   * @param errorCodes the error codes of the errors that are expected to be found
   * @return the compilation unit that was parsed
   * @throws Exception if the source could not be parsed, if the compilation errors in the source do
   *           not match those that are expected, or if the result would have been `null`
   */
  CompilationUnit _parseDirectives(String source,
      [List<ErrorCode> errorCodes = const <ErrorCode>[]]) {
    createParser(source);
    CompilationUnit unit = parser.parseDirectives2();
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(0));
    listener.assertErrorsWithCodes(errorCodes);
    return unit;
  }
}
