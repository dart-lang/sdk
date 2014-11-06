// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.parser_test;

import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:unittest/unittest.dart';
import 'test_support.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';

import '../reflective_tests.dart';


class AnalysisErrorListener_SimpleParserTest_computeStringValue implements AnalysisErrorListener {
  @override
  void onError(AnalysisError event) {
    fail("Unexpected compilation error: ${event.message} (${event.offset}, ${event.length})");
  }
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
        _errors.add("Invalid source start ($nodeStart) for ${node.runtimeType} inside ${parent.runtimeType} ($parentStart)");
      }
      if (nodeEnd > parentEnd) {
        _errors.add("Invalid source end ($nodeEnd) for ${node.runtimeType} inside ${parent.runtimeType} ($parentStart)");
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
class ComplexParserTest extends ParserTestCase {
  void test_additiveExpression_normal() {
    BinaryExpression expression = ParserTestCase.parseExpression("x + y - z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_additiveExpression_noSpaces() {
    BinaryExpression expression = ParserTestCase.parseExpression("i+1", []);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    EngineTestCase.assertInstanceOf((obj) => obj is IntegerLiteral, IntegerLiteral, expression.rightOperand);
  }

  void test_additiveExpression_precedence_multiplicative_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("x * y + z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_additiveExpression_precedence_multiplicative_left_withSuper() {
    BinaryExpression expression = ParserTestCase.parseExpression("super * y - z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_additiveExpression_precedence_multiplicative_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("x + y * z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.rightOperand);
  }

  void test_additiveExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super + y - z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_assignableExpression_arguments_normal_chain() {
    PropertyAccess propertyAccess1 = ParserTestCase.parseExpression("a(b)(c).d(e).f", []);
    expect(propertyAccess1.propertyName.name, "f");
    //
    // a(b)(c).d(e)
    //
    MethodInvocation invocation2 = EngineTestCase.assertInstanceOf((obj) => obj is MethodInvocation, MethodInvocation, propertyAccess1.target);
    expect(invocation2.methodName.name, "d");
    ArgumentList argumentList2 = invocation2.argumentList;
    expect(argumentList2, isNotNull);
    expect(argumentList2.arguments, hasLength(1));
    //
    // a(b)(c)
    //
    FunctionExpressionInvocation invocation3 = EngineTestCase.assertInstanceOf((obj) => obj is FunctionExpressionInvocation, FunctionExpressionInvocation, invocation2.target);
    ArgumentList argumentList3 = invocation3.argumentList;
    expect(argumentList3, isNotNull);
    expect(argumentList3.arguments, hasLength(1));
    //
    // a(b)
    //
    MethodInvocation invocation4 = EngineTestCase.assertInstanceOf((obj) => obj is MethodInvocation, MethodInvocation, invocation3.function);
    expect(invocation4.methodName.name, "a");
    ArgumentList argumentList4 = invocation4.argumentList;
    expect(argumentList4, isNotNull);
    expect(argumentList4.arguments, hasLength(1));
  }

  void test_assignmentExpression_compound() {
    AssignmentExpression expression = ParserTestCase.parseExpression("x = y = 0", []);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftHandSide);
    EngineTestCase.assertInstanceOf((obj) => obj is AssignmentExpression, AssignmentExpression, expression.rightHandSide);
  }

  void test_assignmentExpression_indexExpression() {
    AssignmentExpression expression = ParserTestCase.parseExpression("x[1] = 0", []);
    EngineTestCase.assertInstanceOf((obj) => obj is IndexExpression, IndexExpression, expression.leftHandSide);
    EngineTestCase.assertInstanceOf((obj) => obj is IntegerLiteral, IntegerLiteral, expression.rightHandSide);
  }

  void test_assignmentExpression_prefixedIdentifier() {
    AssignmentExpression expression = ParserTestCase.parseExpression("x.y = 0", []);
    EngineTestCase.assertInstanceOf((obj) => obj is PrefixedIdentifier, PrefixedIdentifier, expression.leftHandSide);
    EngineTestCase.assertInstanceOf((obj) => obj is IntegerLiteral, IntegerLiteral, expression.rightHandSide);
  }

  void test_assignmentExpression_propertyAccess() {
    AssignmentExpression expression = ParserTestCase.parseExpression("super.y = 0", []);
    EngineTestCase.assertInstanceOf((obj) => obj is PropertyAccess, PropertyAccess, expression.leftHandSide);
    EngineTestCase.assertInstanceOf((obj) => obj is IntegerLiteral, IntegerLiteral, expression.rightHandSide);
  }

  void test_bitwiseAndExpression_normal() {
    BinaryExpression expression = ParserTestCase.parseExpression("x & y & z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseAndExpression_precedence_equality_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("x == y && z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseAndExpression_precedence_equality_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("x && y == z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.rightOperand);
  }

  void test_bitwiseAndExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super & y & z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseOrExpression_normal() {
    BinaryExpression expression = ParserTestCase.parseExpression("x | y | z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseOrExpression_precedence_xor_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("x ^ y | z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseOrExpression_precedence_xor_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("x | y ^ z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.rightOperand);
  }

  void test_bitwiseOrExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super | y | z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseXorExpression_normal() {
    BinaryExpression expression = ParserTestCase.parseExpression("x ^ y ^ z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseXorExpression_precedence_and_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("x & y ^ z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseXorExpression_precedence_and_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("x ^ y & z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.rightOperand);
  }

  void test_bitwiseXorExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super ^ y ^ z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_cascade_withAssignment() {
    CascadeExpression cascade = ParserTestCase.parseExpression("new Map()..[3] = 4 ..[0] = 11;", []);
    Expression target = cascade.target;
    for (Expression section in cascade.cascadeSections) {
      EngineTestCase.assertInstanceOf((obj) => obj is AssignmentExpression, AssignmentExpression, section);
      Expression lhs = (section as AssignmentExpression).leftHandSide;
      EngineTestCase.assertInstanceOf((obj) => obj is IndexExpression, IndexExpression, lhs);
      IndexExpression index = lhs as IndexExpression;
      expect(index.isCascaded, isTrue);
      expect(index.realTarget, same(target));
    }
  }

  void test_conditionalExpression_precedence_logicalOrExpression() {
    ConditionalExpression expression = ParserTestCase.parseExpression("a | b ? y : z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.condition);
  }

  void test_constructor_initializer_withParenthesizedExpression() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(r'''
class C {
  C() :
    this.a = (b == null ? c : d) {
  }
}''', []);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
  }

  void test_equalityExpression_normal() {
    BinaryExpression expression = ParserTestCase.parseExpression("x == y != z", [ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_equalityExpression_precedence_relational_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("x is y == z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is IsExpression, IsExpression, expression.leftOperand);
  }

  void test_equalityExpression_precedence_relational_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("x == y is z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is IsExpression, IsExpression, expression.rightOperand);
  }

  void test_equalityExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super == y != z", [ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_logicalAndExpression() {
    BinaryExpression expression = ParserTestCase.parseExpression("x && y && z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_logicalAndExpression_precedence_bitwiseOr_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("x | y < z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_logicalAndExpression_precedence_bitwiseOr_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("x < y | z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.rightOperand);
  }

  void test_logicalOrExpression() {
    BinaryExpression expression = ParserTestCase.parseExpression("x || y || z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_logicalOrExpression_precedence_logicalAnd_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("x && y || z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_logicalOrExpression_precedence_logicalAnd_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("x || y && z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.rightOperand);
  }

  void test_multipleLabels_statement() {
    LabeledStatement statement = ParserTestCase.parseStatement("a: b: c: return x;", []);
    expect(statement.labels, hasLength(3));
    EngineTestCase.assertInstanceOf((obj) => obj is ReturnStatement, ReturnStatement, statement.statement);
  }

  void test_multiplicativeExpression_normal() {
    BinaryExpression expression = ParserTestCase.parseExpression("x * y / z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_multiplicativeExpression_precedence_unary_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("-x * y", []);
    EngineTestCase.assertInstanceOf((obj) => obj is PrefixExpression, PrefixExpression, expression.leftOperand);
  }

  void test_multiplicativeExpression_precedence_unary_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("x * -y", []);
    EngineTestCase.assertInstanceOf((obj) => obj is PrefixExpression, PrefixExpression, expression.rightOperand);
  }

  void test_multiplicativeExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super * y / z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_relationalExpression_precedence_shift_right() {
    IsExpression expression = ParserTestCase.parseExpression("x << y is z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.expression);
  }

  void test_shiftExpression_normal() {
    BinaryExpression expression = ParserTestCase.parseExpression("x >> 4 << 3", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_shiftExpression_precedence_additive_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("x + y << z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_shiftExpression_precedence_additive_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("x << y + z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.rightOperand);
  }

  void test_shiftExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super >> 4 << 3", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_topLevelVariable_withMetadata() {
    ParserTestCase.parseCompilationUnit("String @A string;", []);
  }
}

/**
 * The class `ErrorParserTest` defines parser tests that test the parsing of code to ensure
 * that errors are correctly reported, and in some cases, not reported.
 */
class ErrorParserTest extends ParserTestCase {
  void fail_expectedListOrMapLiteral() {
    // It isn't clear that this test can ever pass. The parser is currently create a synthetic list
    // literal in this case, but isSynthetic() isn't overridden for ListLiteral. The problem is that
    // the synthetic list literals that are being created are not always zero length (because they
    // could have type parameters), which violates the contract of isSynthetic().
    TypedLiteral literal = ParserTestCase.parse3("parseListOrMapLiteral", <Object> [null], "1", [ParserErrorCode.EXPECTED_LIST_OR_MAP_LITERAL]);
    expect(literal.isSynthetic, isTrue);
  }

  void fail_illegalAssignmentToNonAssignable_superAssigned() {
    // TODO(brianwilkerson) When this test starts to pass, remove the test
    // test_illegalAssignmentToNonAssignable_superAssigned.
    ParserTestCase.parseExpression("super = x;", [ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE]);
  }

  void fail_invalidCommentReference__new_nonIdentifier() {
    // This test fails because the method parseCommentReference returns null.
    ParserTestCase.parse3("parseCommentReference", <Object> ["new 42", 0], "", [ParserErrorCode.INVALID_COMMENT_REFERENCE]);
  }

  void fail_invalidCommentReference__new_tooMuch() {
    ParserTestCase.parse3("parseCommentReference", <Object> ["new a.b.c.d", 0], "", [ParserErrorCode.INVALID_COMMENT_REFERENCE]);
  }

  void fail_invalidCommentReference__nonNew_nonIdentifier() {
    // This test fails because the method parseCommentReference returns null.
    ParserTestCase.parse3("parseCommentReference", <Object> ["42", 0], "", [ParserErrorCode.INVALID_COMMENT_REFERENCE]);
  }

  void fail_invalidCommentReference__nonNew_tooMuch() {
    ParserTestCase.parse3("parseCommentReference", <Object> ["a.b.c.d", 0], "", [ParserErrorCode.INVALID_COMMENT_REFERENCE]);
  }

  void fail_missingClosingParenthesis() {
    // It is possible that it is not possible to generate this error (that it's being reported in
    // code that cannot actually be reached), but that hasn't been proven yet.
    ParserTestCase.parse4("parseFormalParameterList", "(int a, int b ;", [ParserErrorCode.MISSING_CLOSING_PARENTHESIS]);
  }

  void fail_missingFunctionParameters_local_nonVoid_block() {
    // The parser does not recognize this as a function declaration, so it tries to parse it as an
    // expression statement. It isn't clear what the best error message is in this case.
    ParserTestCase.parseStatement("int f { return x;}", [ParserErrorCode.MISSING_FUNCTION_PARAMETERS]);
  }

  void fail_missingFunctionParameters_local_nonVoid_expression() {
    // The parser does not recognize this as a function declaration, so it tries to parse it as an
    // expression statement. It isn't clear what the best error message is in this case.
    ParserTestCase.parseStatement("int f => x;", [ParserErrorCode.MISSING_FUNCTION_PARAMETERS]);
  }

  void fail_namedFunctionExpression() {
    Expression expression = ParserTestCase.parse4("parsePrimaryExpression", "f() {}", [ParserErrorCode.NAMED_FUNCTION_EXPRESSION]);
    EngineTestCase.assertInstanceOf((obj) => obj is FunctionExpression, FunctionExpression, expression);
  }

  void fail_unexpectedToken_invalidPostfixExpression() {
    // Note: this might not be the right error to produce, but some error should be produced
    ParserTestCase.parseExpression("f()++", [ParserErrorCode.UNEXPECTED_TOKEN]);
  }

  void fail_varAndType_local() {
    // This is currently reporting EXPECTED_TOKEN for a missing semicolon, but this would be a
    // better error message.
    ParserTestCase.parseStatement("var int x;", [ParserErrorCode.VAR_AND_TYPE]);
  }

  void fail_varAndType_parameter() {
    // This is currently reporting EXPECTED_TOKEN for a missing semicolon, but this would be a
    // better error message.
    ParserTestCase.parse4("parseFormalParameterList", "(var int x)", [ParserErrorCode.VAR_AND_TYPE]);
  }

  void test_abstractClassMember_constructor() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "abstract C.c();", [ParserErrorCode.ABSTRACT_CLASS_MEMBER]);
  }

  void test_abstractClassMember_field() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "abstract C f;", [ParserErrorCode.ABSTRACT_CLASS_MEMBER]);
  }

  void test_abstractClassMember_getter() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "abstract get m;", [ParserErrorCode.ABSTRACT_CLASS_MEMBER]);
  }

  void test_abstractClassMember_method() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "abstract m();", [ParserErrorCode.ABSTRACT_CLASS_MEMBER]);
  }

  void test_abstractClassMember_setter() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "abstract set m(v);", [ParserErrorCode.ABSTRACT_CLASS_MEMBER]);
  }

  void test_abstractEnum() {
    ParserTestCase.parseCompilationUnit("abstract enum E {ONE}", [ParserErrorCode.ABSTRACT_ENUM]);
  }

  void test_abstractTopLevelFunction_function() {
    ParserTestCase.parseCompilationUnit("abstract f(v) {}", [ParserErrorCode.ABSTRACT_TOP_LEVEL_FUNCTION]);
  }

  void test_abstractTopLevelFunction_getter() {
    ParserTestCase.parseCompilationUnit("abstract get m {}", [ParserErrorCode.ABSTRACT_TOP_LEVEL_FUNCTION]);
  }

  void test_abstractTopLevelFunction_setter() {
    ParserTestCase.parseCompilationUnit("abstract set m(v) {}", [ParserErrorCode.ABSTRACT_TOP_LEVEL_FUNCTION]);
  }

  void test_abstractTopLevelVariable() {
    ParserTestCase.parseCompilationUnit("abstract C f;", [ParserErrorCode.ABSTRACT_TOP_LEVEL_VARIABLE]);
  }

  void test_abstractTypeDef() {
    ParserTestCase.parseCompilationUnit("abstract typedef F();", [ParserErrorCode.ABSTRACT_TYPEDEF]);
  }

  void test_assertDoesNotTakeAssignment() {
    ParserTestCase.parse4("parseAssertStatement", "assert(b = true);", [ParserErrorCode.ASSERT_DOES_NOT_TAKE_ASSIGNMENT]);
  }

  void test_assertDoesNotTakeCascades() {
    ParserTestCase.parse4("parseAssertStatement", "assert(new A()..m());", [ParserErrorCode.ASSERT_DOES_NOT_TAKE_CASCADE]);
  }

  void test_assertDoesNotTakeRethrow() {
    ParserTestCase.parse4("parseAssertStatement", "assert(rethrow);", [ParserErrorCode.ASSERT_DOES_NOT_TAKE_RETHROW]);
  }

  void test_assertDoesNotTakeThrow() {
    ParserTestCase.parse4("parseAssertStatement", "assert(throw x);", [ParserErrorCode.ASSERT_DOES_NOT_TAKE_THROW]);
  }

  void test_breakOutsideOfLoop_breakInDoStatement() {
    ParserTestCase.parse4("parseDoStatement", "do {break;} while (x);", []);
  }

  void test_breakOutsideOfLoop_breakInForStatement() {
    ParserTestCase.parse4("parseForStatement", "for (; x;) {break;}", []);
  }

  void test_breakOutsideOfLoop_breakInIfStatement() {
    ParserTestCase.parse4("parseIfStatement", "if (x) {break;}", [ParserErrorCode.BREAK_OUTSIDE_OF_LOOP]);
  }

  void test_breakOutsideOfLoop_breakInSwitchStatement() {
    ParserTestCase.parse4("parseSwitchStatement", "switch (x) {case 1: break;}", []);
  }

  void test_breakOutsideOfLoop_breakInWhileStatement() {
    ParserTestCase.parse4("parseWhileStatement", "while (x) {break;}", []);
  }

  void test_breakOutsideOfLoop_functionExpression_inALoop() {
    ParserTestCase.parseStatement("for(; x;) {() {break;};}", [ParserErrorCode.BREAK_OUTSIDE_OF_LOOP]);
  }

  void test_breakOutsideOfLoop_functionExpression_withALoop() {
    ParserTestCase.parseStatement("() {for (; x;) {break;}};", []);
  }

  void test_classTypeAlias_abstractAfterEq() {
    // This syntax has been removed from the language in favor of "abstract class A = B with C;"
    // (issue 18098).
    ParserTestCase.parse3("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "class A = abstract B with C;", [
        ParserErrorCode.EXPECTED_TOKEN,
        ParserErrorCode.EXPECTED_TOKEN]);
  }

  void test_constAndFinal() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "const final int x;", [ParserErrorCode.CONST_AND_FINAL]);
  }

  void test_constAndVar() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "const var x;", [ParserErrorCode.CONST_AND_VAR]);
  }

  void test_constClass() {
    ParserTestCase.parseCompilationUnit("const class C {}", [ParserErrorCode.CONST_CLASS]);
  }

  void test_constConstructorWithBody() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "const C() {}", [ParserErrorCode.CONST_CONSTRUCTOR_WITH_BODY]);
  }

  void test_constEnum() {
    ParserTestCase.parseCompilationUnit("const enum E {ONE}", [ParserErrorCode.CONST_ENUM]);
  }

  void test_constFactory() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "const factory C() {}", [ParserErrorCode.CONST_FACTORY]);
  }

  void test_constMethod() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "const int m() {}", [ParserErrorCode.CONST_METHOD]);
  }

  void test_constructorWithReturnType() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "C C() {}", [ParserErrorCode.CONSTRUCTOR_WITH_RETURN_TYPE]);
  }

  void test_constructorWithReturnType_var() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "var C() {}", [ParserErrorCode.CONSTRUCTOR_WITH_RETURN_TYPE]);
  }

  void test_constTypedef() {
    ParserTestCase.parseCompilationUnit("const typedef F();", [ParserErrorCode.CONST_TYPEDEF]);
  }

  void test_continueOutsideOfLoop_continueInDoStatement() {
    ParserTestCase.parse4("parseDoStatement", "do {continue;} while (x);", []);
  }

  void test_continueOutsideOfLoop_continueInForStatement() {
    ParserTestCase.parse4("parseForStatement", "for (; x;) {continue;}", []);
  }

  void test_continueOutsideOfLoop_continueInIfStatement() {
    ParserTestCase.parse4("parseIfStatement", "if (x) {continue;}", [ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP]);
  }

  void test_continueOutsideOfLoop_continueInSwitchStatement() {
    ParserTestCase.parse4("parseSwitchStatement", "switch (x) {case 1: continue a;}", []);
  }

  void test_continueOutsideOfLoop_continueInWhileStatement() {
    ParserTestCase.parse4("parseWhileStatement", "while (x) {continue;}", []);
  }

  void test_continueOutsideOfLoop_functionExpression_inALoop() {
    ParserTestCase.parseStatement("for(; x;) {() {continue;};}", [ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP]);
  }

  void test_continueOutsideOfLoop_functionExpression_withALoop() {
    ParserTestCase.parseStatement("() {for (; x;) {continue;}};", []);
  }

  void test_continueWithoutLabelInCase_error() {
    ParserTestCase.parse4("parseSwitchStatement", "switch (x) {case 1: continue;}", [ParserErrorCode.CONTINUE_WITHOUT_LABEL_IN_CASE]);
  }

  void test_continueWithoutLabelInCase_noError() {
    ParserTestCase.parse4("parseSwitchStatement", "switch (x) {case 1: continue a;}", []);
  }

  void test_continueWithoutLabelInCase_noError_switchInLoop() {
    ParserTestCase.parse4("parseWhileStatement", "while (a) { switch (b) {default: continue;}}", []);
  }

  void test_deprecatedClassTypeAlias() {
    ParserTestCase.parseCompilationUnit("typedef C = S with M;", [ParserErrorCode.DEPRECATED_CLASS_TYPE_ALIAS]);
  }

  void test_deprecatedClassTypeAlias_withGeneric() {
    ParserTestCase.parseCompilationUnit("typedef C<T> = S<T> with M;", [ParserErrorCode.DEPRECATED_CLASS_TYPE_ALIAS]);
  }

  void test_directiveAfterDeclaration_classBeforeDirective() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("class Foo{} library l;", [ParserErrorCode.DIRECTIVE_AFTER_DECLARATION]);
    expect(unit, isNotNull);
  }

  void test_directiveAfterDeclaration_classBetweenDirectives() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("library l;\nclass Foo{}\npart 'a.dart';", [ParserErrorCode.DIRECTIVE_AFTER_DECLARATION]);
    expect(unit, isNotNull);
  }

  void test_duplicatedModifier_const() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "const const m;", [ParserErrorCode.DUPLICATED_MODIFIER]);
  }

  void test_duplicatedModifier_external() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "external external f();", [ParserErrorCode.DUPLICATED_MODIFIER]);
  }

  void test_duplicatedModifier_factory() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "factory factory C() {}", [ParserErrorCode.DUPLICATED_MODIFIER]);
  }

  void test_duplicatedModifier_final() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "final final m;", [ParserErrorCode.DUPLICATED_MODIFIER]);
  }

  void test_duplicatedModifier_static() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "static static var m;", [ParserErrorCode.DUPLICATED_MODIFIER]);
  }

  void test_duplicatedModifier_var() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "var var m;", [ParserErrorCode.DUPLICATED_MODIFIER]);
  }

  void test_duplicateLabelInSwitchStatement() {
    ParserTestCase.parse4("parseSwitchStatement", "switch (e) {l1: case 0: break; l1: case 1: break;}", [ParserErrorCode.DUPLICATE_LABEL_IN_SWITCH_STATEMENT]);
  }

  void test_emptyEnumBody() {
    ParserTestCase.parse3("parseEnumDeclaration", <Object> [emptyCommentAndMetadata()], "enum E {}", [ParserErrorCode.EMPTY_ENUM_BODY]);
  }

  void test_equalityCannotBeEqualityOperand_eq_eq() {
    ParserTestCase.parseExpression("1 == 2 == 3", [ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND]);
  }

  void test_equalityCannotBeEqualityOperand_eq_neq() {
    ParserTestCase.parseExpression("1 == 2 != 3", [ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND]);
  }

  void test_equalityCannotBeEqualityOperand_neq_eq() {
    ParserTestCase.parseExpression("1 != 2 == 3", [ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND]);
  }

  void test_expectedCaseOrDefault() {
    ParserTestCase.parse4("parseSwitchStatement", "switch (e) {break;}", [ParserErrorCode.EXPECTED_CASE_OR_DEFAULT]);
  }

  void test_expectedClassMember_inClass_afterType() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "heart 2 heart", [ParserErrorCode.EXPECTED_CLASS_MEMBER]);
  }

  void test_expectedClassMember_inClass_beforeType() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "4 score", [ParserErrorCode.EXPECTED_CLASS_MEMBER]);
  }

  void test_expectedExecutable_inClass_afterVoid() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "void 2 void", [ParserErrorCode.EXPECTED_EXECUTABLE]);
  }

  void test_expectedExecutable_topLevel_afterType() {
    ParserTestCase.parse3("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "heart 2 heart", [ParserErrorCode.EXPECTED_EXECUTABLE]);
  }

  void test_expectedExecutable_topLevel_afterVoid() {
    ParserTestCase.parse3("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "void 2 void", [ParserErrorCode.EXPECTED_EXECUTABLE]);
  }

  void test_expectedExecutable_topLevel_beforeType() {
    ParserTestCase.parse3("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "4 score", [ParserErrorCode.EXPECTED_EXECUTABLE]);
  }

  void test_expectedExecutable_topLevel_eof() {
    ParserTestCase.parse2("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "x", [new AnalysisError.con2(null, 0, 1, ParserErrorCode.EXPECTED_EXECUTABLE, [])]);
  }

  void test_expectedInterpolationIdentifier() {
    ParserTestCase.parse4("parseStringLiteral", "'\$x\$'", [ParserErrorCode.MISSING_IDENTIFIER]);
  }

  void test_expectedInterpolationIdentifier_emptyString() {
    // The scanner inserts an empty string token between the two $'s; we need to make sure that the
    // MISSING_IDENTIFIER error that is generated has a nonzero width so that it will show up in
    // the editor UI.
    ParserTestCase.parse2("parseStringLiteral", <Object> [], "'\$\$foo'", [new AnalysisError.con2(null, 2, 1, ParserErrorCode.MISSING_IDENTIFIER, [])]);
  }

  void test_expectedStringLiteral() {
    StringLiteral expression = ParserTestCase.parse4("parseStringLiteral", "1", [ParserErrorCode.EXPECTED_STRING_LITERAL]);
    expect(expression.isSynthetic, isTrue);
  }

  void test_expectedToken_commaMissingInArgumentList() {
    ParserTestCase.parse4("parseArgumentList", "(x, y z)", [ParserErrorCode.EXPECTED_TOKEN]);
  }

  void test_expectedToken_parseStatement_afterVoid() {
    ParserTestCase.parseStatement("void}", [
        ParserErrorCode.EXPECTED_TOKEN,
        ParserErrorCode.MISSING_IDENTIFIER]);
  }

  void test_expectedToken_semicolonAfterClass() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.CLASS);
    ParserTestCase.parse3("parseClassTypeAlias", <Object> [emptyCommentAndMetadata(), null, token], "A = B with C", [ParserErrorCode.EXPECTED_TOKEN]);
  }

  void test_expectedToken_semicolonMissingAfterExport() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("export '' class A {}", [ParserErrorCode.EXPECTED_TOKEN]);
    ExportDirective directive = unit.directives[0] as ExportDirective;
    Token semicolon = directive.semicolon;
    expect(semicolon, isNotNull);
    expect(semicolon.isSynthetic, isTrue);
  }

  void test_expectedToken_semicolonMissingAfterExpression() {
    ParserTestCase.parseStatement("x", [ParserErrorCode.EXPECTED_TOKEN]);
  }

  void test_expectedToken_semicolonMissingAfterImport() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("import '' class A {}", [ParserErrorCode.EXPECTED_TOKEN]);
    ImportDirective directive = unit.directives[0] as ImportDirective;
    Token semicolon = directive.semicolon;
    expect(semicolon, isNotNull);
    expect(semicolon.isSynthetic, isTrue);
  }

  void test_expectedToken_whileMissingInDoStatement() {
    ParserTestCase.parseStatement("do {} (x);", [ParserErrorCode.EXPECTED_TOKEN]);
  }

  void test_expectedTypeName_is() {
    ParserTestCase.parseExpression("x is", [ParserErrorCode.EXPECTED_TYPE_NAME]);
  }

  void test_exportDirectiveAfterPartDirective() {
    ParserTestCase.parseCompilationUnit("part 'a.dart'; export 'b.dart';", [ParserErrorCode.EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE]);
  }

  void test_externalAfterConst() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "const external C();", [ParserErrorCode.EXTERNAL_AFTER_CONST]);
  }

  void test_externalAfterFactory() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "factory external C();", [ParserErrorCode.EXTERNAL_AFTER_FACTORY]);
  }

  void test_externalAfterStatic() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "static external int m();", [ParserErrorCode.EXTERNAL_AFTER_STATIC]);
  }

  void test_externalClass() {
    ParserTestCase.parseCompilationUnit("external class C {}", [ParserErrorCode.EXTERNAL_CLASS]);
  }

  void test_externalConstructorWithBody_factory() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "external factory C() {}", [ParserErrorCode.EXTERNAL_CONSTRUCTOR_WITH_BODY]);
  }

  void test_externalConstructorWithBody_named() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "external C.c() {}", [ParserErrorCode.EXTERNAL_CONSTRUCTOR_WITH_BODY]);
  }

  void test_externalEnum() {
    ParserTestCase.parseCompilationUnit("external enum E {ONE}", [ParserErrorCode.EXTERNAL_ENUM]);
  }

  void test_externalField_const() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "external const A f;", [ParserErrorCode.EXTERNAL_FIELD]);
  }

  void test_externalField_final() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "external final A f;", [ParserErrorCode.EXTERNAL_FIELD]);
  }

  void test_externalField_static() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "external static A f;", [ParserErrorCode.EXTERNAL_FIELD]);
  }

  void test_externalField_typed() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "external A f;", [ParserErrorCode.EXTERNAL_FIELD]);
  }

  void test_externalField_untyped() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "external var f;", [ParserErrorCode.EXTERNAL_FIELD]);
  }

  void test_externalGetterWithBody() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "external int get x {}", [ParserErrorCode.EXTERNAL_GETTER_WITH_BODY]);
  }

  void test_externalMethodWithBody() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "external m() {}", [ParserErrorCode.EXTERNAL_METHOD_WITH_BODY]);
  }

  void test_externalOperatorWithBody() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "external operator +(int value) {}", [ParserErrorCode.EXTERNAL_OPERATOR_WITH_BODY]);
  }

  void test_externalSetterWithBody() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "external set x(int value) {}", [ParserErrorCode.EXTERNAL_SETTER_WITH_BODY]);
  }

  void test_externalTypedef() {
    ParserTestCase.parseCompilationUnit("external typedef F();", [ParserErrorCode.EXTERNAL_TYPEDEF]);
  }

  void test_factoryTopLevelDeclaration_class() {
    ParserTestCase.parseCompilationUnit("factory class C {}", [ParserErrorCode.FACTORY_TOP_LEVEL_DECLARATION]);
  }

  void test_factoryTopLevelDeclaration_typedef() {
    ParserTestCase.parseCompilationUnit("factory typedef F();", [ParserErrorCode.FACTORY_TOP_LEVEL_DECLARATION]);
  }

  void test_factoryWithoutBody() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "factory C();", [ParserErrorCode.FACTORY_WITHOUT_BODY]);
  }

  void test_fieldInitializerOutsideConstructor() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "void m(this.x);", [ParserErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR]);
  }

  void test_finalAndVar() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "final var x;", [ParserErrorCode.FINAL_AND_VAR]);
  }

  void test_finalClass() {
    ParserTestCase.parseCompilationUnit("final class C {}", [ParserErrorCode.FINAL_CLASS]);
  }

  void test_finalConstructor() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "final C() {}", [ParserErrorCode.FINAL_CONSTRUCTOR]);
  }

  void test_finalEnum() {
    ParserTestCase.parseCompilationUnit("final enum E {ONE}", [ParserErrorCode.FINAL_ENUM]);
  }

  void test_finalMethod() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "final int m() {}", [ParserErrorCode.FINAL_METHOD]);
  }

  void test_finalTypedef() {
    ParserTestCase.parseCompilationUnit("final typedef F();", [ParserErrorCode.FINAL_TYPEDEF]);
  }

  void test_functionTypedParameter_const() {
    ParserTestCase.parseCompilationUnit("void f(const x()) {}", [ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR]);
  }

  void test_functionTypedParameter_final() {
    ParserTestCase.parseCompilationUnit("void f(final x()) {}", [ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR]);
  }

  void test_functionTypedParameter_var() {
    ParserTestCase.parseCompilationUnit("void f(var x()) {}", [ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR]);
  }

  void test_getterInFunction_block_noReturnType() {
    ParserTestCase.parseStatement("get x { return _x; }", [ParserErrorCode.GETTER_IN_FUNCTION]);
  }

  void test_getterInFunction_block_returnType() {
    ParserTestCase.parseStatement("int get x { return _x; }", [ParserErrorCode.GETTER_IN_FUNCTION]);
  }

  void test_getterInFunction_expression_noReturnType() {
    ParserTestCase.parseStatement("get x => _x;", [ParserErrorCode.GETTER_IN_FUNCTION]);
  }

  void test_getterInFunction_expression_returnType() {
    ParserTestCase.parseStatement("int get x => _x;", [ParserErrorCode.GETTER_IN_FUNCTION]);
  }

  void test_getterWithParameters() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "int get x() {}", [ParserErrorCode.GETTER_WITH_PARAMETERS]);
  }

  void test_illegalAssignmentToNonAssignable_postfix_minusMinus_literal() {
    ParserTestCase.parseExpression("0--", [ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE]);
  }

  void test_illegalAssignmentToNonAssignable_postfix_plusPlus_literal() {
    ParserTestCase.parseExpression("0++", [ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE]);
  }

  void test_illegalAssignmentToNonAssignable_postfix_plusPlus_parethesized() {
    ParserTestCase.parseExpression("(x)++", [ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE]);
  }

  void test_illegalAssignmentToNonAssignable_primarySelectorPostfix() {
    ParserTestCase.parseExpression("x(y)(z)++", [ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE]);
  }

  void test_illegalAssignmentToNonAssignable_superAssigned() {
    // TODO(brianwilkerson) When the test fail_illegalAssignmentToNonAssignable_superAssigned starts
    // to pass, remove this test (there should only be one error generated, but we're keeping this
    // test until that time so that we can catch other forms of regressions).
    ParserTestCase.parseExpression("super = x;", [
        ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR,
        ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE]);
  }

  void test_implementsBeforeExtends() {
    ParserTestCase.parseCompilationUnit("class A implements B extends C {}", [ParserErrorCode.IMPLEMENTS_BEFORE_EXTENDS]);
  }

  void test_implementsBeforeWith() {
    ParserTestCase.parseCompilationUnit("class A extends B implements C with D {}", [ParserErrorCode.IMPLEMENTS_BEFORE_WITH]);
  }

  void test_importDirectiveAfterPartDirective() {
    ParserTestCase.parseCompilationUnit("part 'a.dart'; import 'b.dart';", [ParserErrorCode.IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE]);
  }

  void test_initializedVariableInForEach() {
    ParserTestCase.parse4("parseForStatement", "for (int a = 0 in foo) {}", [ParserErrorCode.INITIALIZED_VARIABLE_IN_FOR_EACH]);
  }

  void test_invalidAwaitInFor() {
    ParserTestCase.parse4("parseForStatement", "await for (; ;) {}", [ParserErrorCode.INVALID_AWAIT_IN_FOR]);
  }

  void test_invalidCodePoint() {
    ParserTestCase.parse4("parseStringLiteral", "'\\uD900'", [ParserErrorCode.INVALID_CODE_POINT]);
  }

  void test_invalidHexEscape_invalidDigit() {
    ParserTestCase.parse4("parseStringLiteral", "'\\x0 a'", [ParserErrorCode.INVALID_HEX_ESCAPE]);
  }

  void test_invalidHexEscape_tooFewDigits() {
    ParserTestCase.parse4("parseStringLiteral", "'\\x0'", [ParserErrorCode.INVALID_HEX_ESCAPE]);
  }

  void test_invalidInterpolationIdentifier_startWithDigit() {
    ParserTestCase.parse4("parseStringLiteral", "'\$1'", [ParserErrorCode.MISSING_IDENTIFIER]);
  }

  void test_invalidOperator() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "void operator ===(x) {}", [ParserErrorCode.INVALID_OPERATOR]);
  }

  void test_invalidOperatorForSuper() {
    ParserTestCase.parse4("parseUnaryExpression", "++super", [ParserErrorCode.INVALID_OPERATOR_FOR_SUPER]);
  }

  void test_invalidStarAfterAsync() {
    ParserTestCase.parse3("parseFunctionBody", <Object> [false, null, false], "async* => 0;", [ParserErrorCode.INVALID_STAR_AFTER_ASYNC]);
  }

  void test_invalidSync() {
    ParserTestCase.parse3("parseFunctionBody", <Object> [false, null, false], "sync* => 0;", [ParserErrorCode.INVALID_SYNC]);
  }

  void test_invalidUnicodeEscape_incomplete_noDigits() {
    ParserTestCase.parse4("parseStringLiteral", "'\\u{'", [ParserErrorCode.INVALID_UNICODE_ESCAPE]);
  }

  void test_invalidUnicodeEscape_incomplete_someDigits() {
    ParserTestCase.parse4("parseStringLiteral", "'\\u{0A'", [ParserErrorCode.INVALID_UNICODE_ESCAPE]);
  }

  void test_invalidUnicodeEscape_invalidDigit() {
    ParserTestCase.parse4("parseStringLiteral", "'\\u0 a'", [ParserErrorCode.INVALID_UNICODE_ESCAPE]);
  }

  void test_invalidUnicodeEscape_tooFewDigits_fixed() {
    ParserTestCase.parse4("parseStringLiteral", "'\\u04'", [ParserErrorCode.INVALID_UNICODE_ESCAPE]);
  }

  void test_invalidUnicodeEscape_tooFewDigits_variable() {
    ParserTestCase.parse4("parseStringLiteral", "'\\u{}'", [ParserErrorCode.INVALID_UNICODE_ESCAPE]);
  }

  void test_invalidUnicodeEscape_tooManyDigits_variable() {
    ParserTestCase.parse4("parseStringLiteral", "'\\u{12345678}'", [
        ParserErrorCode.INVALID_UNICODE_ESCAPE,
        ParserErrorCode.INVALID_CODE_POINT]);
  }

  void test_libraryDirectiveNotFirst() {
    ParserTestCase.parseCompilationUnit("import 'x.dart'; library l;", [ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST]);
  }

  void test_libraryDirectiveNotFirst_afterPart() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("part 'a.dart';\nlibrary l;", [ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST]);
    expect(unit, isNotNull);
  }

  void test_localFunctionDeclarationModifier_abstract() {
    ParserTestCase.parseStatement("abstract f() {}", [ParserErrorCode.LOCAL_FUNCTION_DECLARATION_MODIFIER]);
  }

  void test_localFunctionDeclarationModifier_external() {
    ParserTestCase.parseStatement("external f() {}", [ParserErrorCode.LOCAL_FUNCTION_DECLARATION_MODIFIER]);
  }

  void test_localFunctionDeclarationModifier_factory() {
    ParserTestCase.parseStatement("factory f() {}", [ParserErrorCode.LOCAL_FUNCTION_DECLARATION_MODIFIER]);
  }

  void test_localFunctionDeclarationModifier_static() {
    ParserTestCase.parseStatement("static f() {}", [ParserErrorCode.LOCAL_FUNCTION_DECLARATION_MODIFIER]);
  }

  void test_missingAssignableSelector_identifiersAssigned() {
    ParserTestCase.parseExpression("x.y = y;", []);
  }

  void test_missingAssignableSelector_prefix_minusMinus_literal() {
    ParserTestCase.parseExpression("--0", [ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR]);
  }

  void test_missingAssignableSelector_prefix_plusPlus_literal() {
    ParserTestCase.parseExpression("++0", [ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR]);
  }

  void test_missingAssignableSelector_selector() {
    ParserTestCase.parseExpression("x(y)(z).a++", []);
  }

  void test_missingAssignableSelector_superPrimaryExpression() {
    SuperExpression expression = ParserTestCase.parse4("parsePrimaryExpression", "super", [ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR]);
    expect(expression.keyword, isNotNull);
  }

  void test_missingAssignableSelector_superPropertyAccessAssigned() {
    ParserTestCase.parseExpression("super.x = x;", []);
  }

  void test_missingCatchOrFinally() {
    TryStatement statement = ParserTestCase.parse4("parseTryStatement", "try {}", [ParserErrorCode.MISSING_CATCH_OR_FINALLY]);
    expect(statement, isNotNull);
  }

  void test_missingClassBody() {
    ParserTestCase.parseCompilationUnit("class A class B {}", [ParserErrorCode.MISSING_CLASS_BODY]);
  }

  void test_missingConstFinalVarOrType_static() {
    ParserTestCase.parseCompilationUnit("class A { static f; }", [ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE]);
  }

  void test_missingConstFinalVarOrType_topLevel() {
    ParserTestCase.parse3("parseFinalConstVarOrType", <Object> [false], "a;", [ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE]);
  }

  void test_missingEnumBody() {
    ParserTestCase.parse3("parseEnumDeclaration", <Object> [emptyCommentAndMetadata()], "enum E;", [ParserErrorCode.MISSING_ENUM_BODY]);
  }

  void test_missingExpressionInThrow_withCascade() {
    ParserTestCase.parse4("parseThrowExpression", "throw;", [ParserErrorCode.MISSING_EXPRESSION_IN_THROW]);
  }

  void test_missingExpressionInThrow_withoutCascade() {
    ParserTestCase.parse4("parseThrowExpressionWithoutCascade", "throw;", [ParserErrorCode.MISSING_EXPRESSION_IN_THROW]);
  }

  void test_missingFunctionBody_emptyNotAllowed() {
    ParserTestCase.parse3("parseFunctionBody", <Object> [false, ParserErrorCode.MISSING_FUNCTION_BODY, false], ";", [ParserErrorCode.MISSING_FUNCTION_BODY]);
  }

  void test_missingFunctionBody_invalid() {
    ParserTestCase.parse3("parseFunctionBody", <Object> [false, ParserErrorCode.MISSING_FUNCTION_BODY, false], "return 0;", [ParserErrorCode.MISSING_FUNCTION_BODY]);
  }

  void test_missingFunctionParameters_local_void_block() {
    ParserTestCase.parseStatement("void f { return x;}", [ParserErrorCode.MISSING_FUNCTION_PARAMETERS]);
  }

  void test_missingFunctionParameters_local_void_expression() {
    ParserTestCase.parseStatement("void f => x;", [ParserErrorCode.MISSING_FUNCTION_PARAMETERS]);
  }

  void test_missingFunctionParameters_topLevel_nonVoid_block() {
    ParserTestCase.parseCompilationUnit("int f { return x;}", [ParserErrorCode.MISSING_FUNCTION_PARAMETERS]);
  }

  void test_missingFunctionParameters_topLevel_nonVoid_expression() {
    ParserTestCase.parseCompilationUnit("int f => x;", [ParserErrorCode.MISSING_FUNCTION_PARAMETERS]);
  }

  void test_missingFunctionParameters_topLevel_void_block() {
    ParserTestCase.parseCompilationUnit("void f { return x;}", [ParserErrorCode.MISSING_FUNCTION_PARAMETERS]);
  }

  void test_missingFunctionParameters_topLevel_void_expression() {
    ParserTestCase.parseCompilationUnit("void f => x;", [ParserErrorCode.MISSING_FUNCTION_PARAMETERS]);
  }

  void test_missingIdentifier_afterOperator() {
    ParserTestCase.parse4("parseMultiplicativeExpression", "1 *", [ParserErrorCode.MISSING_IDENTIFIER]);
  }

  void test_missingIdentifier_beforeClosingCurly() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "int}", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.EXPECTED_TOKEN]);
  }

  void test_missingIdentifier_functionDeclaration_returnTypeWithoutName() {
    ParserTestCase.parse4("parseFunctionDeclarationStatement", "A<T> () {}", [ParserErrorCode.MISSING_IDENTIFIER]);
  }

  void test_missingIdentifier_inEnum() {
    ParserTestCase.parse3("parseEnumDeclaration", <Object> [emptyCommentAndMetadata()], "enum E {, TWO}", [ParserErrorCode.MISSING_IDENTIFIER]);
  }

  void test_missingIdentifier_inSymbol_afterPeriod() {
    ParserTestCase.parse4("parseSymbolLiteral", "#a.", [ParserErrorCode.MISSING_IDENTIFIER]);
  }

  void test_missingIdentifier_inSymbol_first() {
    ParserTestCase.parse4("parseSymbolLiteral", "#", [ParserErrorCode.MISSING_IDENTIFIER]);
  }

  void test_missingIdentifier_number() {
    SimpleIdentifier expression = ParserTestCase.parse4("parseSimpleIdentifier", "1", [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(expression.isSynthetic, isTrue);
  }

  void test_missingKeywordOperator() {
    ParserTestCase.parse3("parseOperator", <Object> [emptyCommentAndMetadata(), null, null], "+(x) {}", [ParserErrorCode.MISSING_KEYWORD_OPERATOR]);
  }

  void test_missingKeywordOperator_parseClassMember() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "+() {}", [ParserErrorCode.MISSING_KEYWORD_OPERATOR]);
  }

  void test_missingKeywordOperator_parseClassMember_afterTypeName() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "int +() {}", [ParserErrorCode.MISSING_KEYWORD_OPERATOR]);
  }

  void test_missingKeywordOperator_parseClassMember_afterVoid() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "void +() {}", [ParserErrorCode.MISSING_KEYWORD_OPERATOR]);
  }

  void test_missingNameInLibraryDirective() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("library;", [ParserErrorCode.MISSING_NAME_IN_LIBRARY_DIRECTIVE]);
    expect(unit, isNotNull);
  }

  void test_missingNameInPartOfDirective() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("part of;", [ParserErrorCode.MISSING_NAME_IN_PART_OF_DIRECTIVE]);
    expect(unit, isNotNull);
  }

  void test_missingPrefixInDeferredImport() {
    ParserTestCase.parseCompilationUnit("import 'foo.dart' deferred;", [ParserErrorCode.MISSING_PREFIX_IN_DEFERRED_IMPORT]);
  }

  void test_missingStartAfterSync() {
    ParserTestCase.parse3("parseFunctionBody", <Object> [false, null, false], "sync {}", [ParserErrorCode.MISSING_STAR_AFTER_SYNC]);
  }

  void test_missingStatement() {
    ParserTestCase.parseStatement("is", [ParserErrorCode.MISSING_STATEMENT]);
  }

  void test_missingStatement_afterVoid() {
    ParserTestCase.parseStatement("void;", [ParserErrorCode.MISSING_STATEMENT]);
  }

  void test_missingTerminatorForParameterGroup_named() {
    ParserTestCase.parse4("parseFormalParameterList", "(a, {b: 0)", [ParserErrorCode.MISSING_TERMINATOR_FOR_PARAMETER_GROUP]);
  }

  void test_missingTerminatorForParameterGroup_optional() {
    ParserTestCase.parse4("parseFormalParameterList", "(a, [b = 0)", [ParserErrorCode.MISSING_TERMINATOR_FOR_PARAMETER_GROUP]);
  }

  void test_missingTypedefParameters_nonVoid() {
    ParserTestCase.parseCompilationUnit("typedef int F;", [ParserErrorCode.MISSING_TYPEDEF_PARAMETERS]);
  }

  void test_missingTypedefParameters_typeParameters() {
    ParserTestCase.parseCompilationUnit("typedef F<E>;", [ParserErrorCode.MISSING_TYPEDEF_PARAMETERS]);
  }

  void test_missingTypedefParameters_void() {
    ParserTestCase.parseCompilationUnit("typedef void F;", [ParserErrorCode.MISSING_TYPEDEF_PARAMETERS]);
  }

  void test_missingVariableInForEach() {
    ParserTestCase.parse4("parseForStatement", "for (a < b in foo) {}", [ParserErrorCode.MISSING_VARIABLE_IN_FOR_EACH]);
  }

  void test_mixedParameterGroups_namedPositional() {
    ParserTestCase.parse4("parseFormalParameterList", "(a, {b}, [c])", [ParserErrorCode.MIXED_PARAMETER_GROUPS]);
  }

  void test_mixedParameterGroups_positionalNamed() {
    ParserTestCase.parse4("parseFormalParameterList", "(a, [b], {c})", [ParserErrorCode.MIXED_PARAMETER_GROUPS]);
  }

  void test_mixin_application_lacks_with_clause() {
    ParserTestCase.parseCompilationUnit("class Foo = Bar;", [ParserErrorCode.EXPECTED_TOKEN]);
  }

  void test_multipleExtendsClauses() {
    ParserTestCase.parseCompilationUnit("class A extends B extends C {}", [ParserErrorCode.MULTIPLE_EXTENDS_CLAUSES]);
  }

  void test_multipleImplementsClauses() {
    ParserTestCase.parseCompilationUnit("class A implements B implements C {}", [ParserErrorCode.MULTIPLE_IMPLEMENTS_CLAUSES]);
  }

  void test_multipleLibraryDirectives() {
    ParserTestCase.parseCompilationUnit("library l; library m;", [ParserErrorCode.MULTIPLE_LIBRARY_DIRECTIVES]);
  }

  void test_multipleNamedParameterGroups() {
    ParserTestCase.parse4("parseFormalParameterList", "(a, {b}, {c})", [ParserErrorCode.MULTIPLE_NAMED_PARAMETER_GROUPS]);
  }

  void test_multiplePartOfDirectives() {
    ParserTestCase.parseCompilationUnit("part of l; part of m;", [ParserErrorCode.MULTIPLE_PART_OF_DIRECTIVES]);
  }

  void test_multiplePositionalParameterGroups() {
    ParserTestCase.parse4("parseFormalParameterList", "(a, [b], [c])", [ParserErrorCode.MULTIPLE_POSITIONAL_PARAMETER_GROUPS]);
  }

  void test_multipleVariablesInForEach() {
    ParserTestCase.parse4("parseForStatement", "for (int a, b in foo) {}", [ParserErrorCode.MULTIPLE_VARIABLES_IN_FOR_EACH]);
  }

  void test_multipleWithClauses() {
    ParserTestCase.parseCompilationUnit("class A extends B with C with D {}", [ParserErrorCode.MULTIPLE_WITH_CLAUSES]);
  }

  void test_namedParameterOutsideGroup() {
    ParserTestCase.parse4("parseFormalParameterList", "(a, b : 0)", [ParserErrorCode.NAMED_PARAMETER_OUTSIDE_GROUP]);
  }

  void test_nonConstructorFactory_field() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "factory int x;", [ParserErrorCode.NON_CONSTRUCTOR_FACTORY]);
  }

  void test_nonConstructorFactory_method() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "factory int m() {}", [ParserErrorCode.NON_CONSTRUCTOR_FACTORY]);
  }

  void test_nonIdentifierLibraryName_library() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("library 'lib';", [ParserErrorCode.NON_IDENTIFIER_LIBRARY_NAME]);
    expect(unit, isNotNull);
  }

  void test_nonIdentifierLibraryName_partOf() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("part of 'lib';", [ParserErrorCode.NON_IDENTIFIER_LIBRARY_NAME]);
    expect(unit, isNotNull);
  }

  void test_nonPartOfDirectiveInPart_after() {
    ParserTestCase.parseCompilationUnit("part of l; part 'f.dart';", [ParserErrorCode.NON_PART_OF_DIRECTIVE_IN_PART]);
  }

  void test_nonPartOfDirectiveInPart_before() {
    ParserTestCase.parseCompilationUnit("part 'f.dart'; part of m;", [ParserErrorCode.NON_PART_OF_DIRECTIVE_IN_PART]);
  }

  void test_nonUserDefinableOperator() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "operator +=(int x) => x + 1;", [ParserErrorCode.NON_USER_DEFINABLE_OPERATOR]);
  }

  void test_optionalAfterNormalParameters_named() {
    ParserTestCase.parseCompilationUnit("f({a}, b) {}", [ParserErrorCode.NORMAL_BEFORE_OPTIONAL_PARAMETERS]);
  }

  void test_optionalAfterNormalParameters_positional() {
    ParserTestCase.parseCompilationUnit("f([a], b) {}", [ParserErrorCode.NORMAL_BEFORE_OPTIONAL_PARAMETERS]);
  }

  void test_parseCascadeSection_missingIdentifier() {
    MethodInvocation methodInvocation = ParserTestCase.parse4("parseCascadeSection", "..()", [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(methodInvocation.target, isNull);
    expect(methodInvocation.methodName.name, "");
    expect(methodInvocation.argumentList.arguments, hasLength(0));
  }

  void test_positionalAfterNamedArgument() {
    ParserTestCase.parse4("parseArgumentList", "(x: 1, 2)", [ParserErrorCode.POSITIONAL_AFTER_NAMED_ARGUMENT]);
  }

  void test_positionalParameterOutsideGroup() {
    ParserTestCase.parse4("parseFormalParameterList", "(a, b = 0)", [ParserErrorCode.POSITIONAL_PARAMETER_OUTSIDE_GROUP]);
  }

  void test_redirectionInNonFactoryConstructor() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "C() = D;", [ParserErrorCode.REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR]);
  }

  void test_setterInFunction_block() {
    ParserTestCase.parseStatement("set x(v) {_x = v;}", [ParserErrorCode.SETTER_IN_FUNCTION]);
  }

  void test_setterInFunction_expression() {
    ParserTestCase.parseStatement("set x(v) => _x = v;", [ParserErrorCode.SETTER_IN_FUNCTION]);
  }

  void test_staticAfterConst() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "final static int f;", [ParserErrorCode.STATIC_AFTER_FINAL]);
  }

  void test_staticAfterFinal() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "const static int f;", [ParserErrorCode.STATIC_AFTER_CONST]);
  }

  void test_staticAfterVar() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "var static f;", [ParserErrorCode.STATIC_AFTER_VAR]);
  }

  void test_staticConstructor() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "static C.m() {}", [ParserErrorCode.STATIC_CONSTRUCTOR]);
  }

  void test_staticGetterWithoutBody() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "static get m;", [ParserErrorCode.STATIC_GETTER_WITHOUT_BODY]);
  }

  void test_staticOperator_noReturnType() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "static operator +(int x) => x + 1;", [ParserErrorCode.STATIC_OPERATOR]);
  }

  void test_staticOperator_returnType() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "static int operator +(int x) => x + 1;", [ParserErrorCode.STATIC_OPERATOR]);
  }

  void test_staticSetterWithoutBody() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "static set m(x);", [ParserErrorCode.STATIC_SETTER_WITHOUT_BODY]);
  }

  void test_staticTopLevelDeclaration_class() {
    ParserTestCase.parseCompilationUnit("static class C {}", [ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION]);
  }

  void test_staticTopLevelDeclaration_function() {
    ParserTestCase.parseCompilationUnit("static f() {}", [ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION]);
  }

  void test_staticTopLevelDeclaration_typedef() {
    ParserTestCase.parseCompilationUnit("static typedef F();", [ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION]);
  }

  void test_staticTopLevelDeclaration_variable() {
    ParserTestCase.parseCompilationUnit("static var x;", [ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION]);
  }

  void test_switchHasCaseAfterDefaultCase() {
    ParserTestCase.parse4("parseSwitchStatement", "switch (a) {default: return 0; case 1: return 1;}", [ParserErrorCode.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE]);
  }

  void test_switchHasCaseAfterDefaultCase_repeated() {
    ParserTestCase.parse4("parseSwitchStatement", "switch (a) {default: return 0; case 1: return 1; case 2: return 2;}", [
        ParserErrorCode.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE,
        ParserErrorCode.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE]);
  }

  void test_switchHasMultipleDefaultCases() {
    ParserTestCase.parse4("parseSwitchStatement", "switch (a) {default: return 0; default: return 1;}", [ParserErrorCode.SWITCH_HAS_MULTIPLE_DEFAULT_CASES]);
  }

  void test_switchHasMultipleDefaultCases_repeated() {
    ParserTestCase.parse4("parseSwitchStatement", "switch (a) {default: return 0; default: return 1; default: return 2;}", [
        ParserErrorCode.SWITCH_HAS_MULTIPLE_DEFAULT_CASES,
        ParserErrorCode.SWITCH_HAS_MULTIPLE_DEFAULT_CASES]);
  }

  void test_topLevelOperator_withoutType() {
    ParserTestCase.parse3("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "operator +(bool x, bool y) => x | y;", [ParserErrorCode.TOP_LEVEL_OPERATOR]);
  }

  void test_topLevelOperator_withType() {
    ParserTestCase.parse3("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "bool operator +(bool x, bool y) => x | y;", [ParserErrorCode.TOP_LEVEL_OPERATOR]);
  }

  void test_topLevelOperator_withVoid() {
    ParserTestCase.parse3("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "void operator +(bool x, bool y) => x | y;", [ParserErrorCode.TOP_LEVEL_OPERATOR]);
  }

  void test_unexpectedTerminatorForParameterGroup_named() {
    ParserTestCase.parse4("parseFormalParameterList", "(a, b})", [ParserErrorCode.UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP]);
  }

  void test_unexpectedTerminatorForParameterGroup_optional() {
    ParserTestCase.parse4("parseFormalParameterList", "(a, b])", [ParserErrorCode.UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP]);
  }

  void test_unexpectedToken_semicolonBetweenClassMembers() {
    ParserTestCase.parse3("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class C { int x; ; int y;}", [ParserErrorCode.UNEXPECTED_TOKEN]);
  }

  void test_unexpectedToken_semicolonBetweenCompilationUnitMembers() {
    ParserTestCase.parseCompilationUnit("int x; ; int y;", [ParserErrorCode.UNEXPECTED_TOKEN]);
  }

  void test_useOfUnaryPlusOperator() {
    SimpleIdentifier expression = ParserTestCase.parse4("parseUnaryExpression", "+x", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression);
    expect(expression.isSynthetic, isTrue);
  }

  void test_varAndType_field() {
    ParserTestCase.parseCompilationUnit("class C { var int x; }", [ParserErrorCode.VAR_AND_TYPE]);
  }

  void test_varAndType_topLevelVariable() {
    ParserTestCase.parseCompilationUnit("var int x;", [ParserErrorCode.VAR_AND_TYPE]);
  }

  void test_varAsTypeName_as() {
    ParserTestCase.parseExpression("x as var", [ParserErrorCode.VAR_AS_TYPE_NAME]);
  }

  void test_varClass() {
    ParserTestCase.parseCompilationUnit("var class C {}", [ParserErrorCode.VAR_CLASS]);
  }

  void test_varEnum() {
    ParserTestCase.parseCompilationUnit("var enum E {ONE}", [ParserErrorCode.VAR_ENUM]);
  }

  void test_varReturnType() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "var m() {}", [ParserErrorCode.VAR_RETURN_TYPE]);
  }

  void test_varTypedef() {
    ParserTestCase.parseCompilationUnit("var typedef F();", [ParserErrorCode.VAR_TYPEDEF]);
  }

  void test_voidParameter() {
    ParserTestCase.parse4("parseNormalFormalParameter", "void a)", [ParserErrorCode.VOID_PARAMETER]);
  }

  void test_voidVariable_parseClassMember_initializer() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "void x = 0;", [ParserErrorCode.VOID_VARIABLE]);
  }

  void test_voidVariable_parseClassMember_noInitializer() {
    ParserTestCase.parse3("parseClassMember", <Object> ["C"], "void x;", [ParserErrorCode.VOID_VARIABLE]);
  }

  void test_voidVariable_parseCompilationUnit_initializer() {
    ParserTestCase.parseCompilationUnit("void x = 0;", [ParserErrorCode.VOID_VARIABLE]);
  }

  void test_voidVariable_parseCompilationUnit_noInitializer() {
    ParserTestCase.parseCompilationUnit("void x;", [ParserErrorCode.VOID_VARIABLE]);
  }

  void test_voidVariable_parseCompilationUnitMember_initializer() {
    ParserTestCase.parse3("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "void a = 0;", [ParserErrorCode.VOID_VARIABLE]);
  }

  void test_voidVariable_parseCompilationUnitMember_noInitializer() {
    ParserTestCase.parse3("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "void a;", [ParserErrorCode.VOID_VARIABLE]);
  }

  void test_voidVariable_statement_initializer() {
    ParserTestCase.parseStatement("void x = 0;", [
        ParserErrorCode.VOID_VARIABLE,
        ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE]);
  }

  void test_voidVariable_statement_noInitializer() {
    ParserTestCase.parseStatement("void x;", [
        ParserErrorCode.VOID_VARIABLE,
        ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE]);
  }

  void test_withBeforeExtends() {
    ParserTestCase.parseCompilationUnit("class A with B extends C {}", [ParserErrorCode.WITH_BEFORE_EXTENDS]);
  }

  void test_withWithoutExtends() {
    ParserTestCase.parse3("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class A with B, C {}", [ParserErrorCode.WITH_WITHOUT_EXTENDS]);
  }

  void test_wrongSeparatorForNamedParameter() {
    ParserTestCase.parse4("parseFormalParameterList", "(a, {b = 0})", [ParserErrorCode.WRONG_SEPARATOR_FOR_NAMED_PARAMETER]);
  }

  void test_wrongSeparatorForPositionalParameter() {
    ParserTestCase.parse4("parseFormalParameterList", "(a, [b : 0])", [ParserErrorCode.WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER]);
  }

  void test_wrongTerminatorForParameterGroup_named() {
    ParserTestCase.parse4("parseFormalParameterList", "(a, {b, c])", [ParserErrorCode.WRONG_TERMINATOR_FOR_PARAMETER_GROUP]);
  }

  void test_wrongTerminatorForParameterGroup_optional() {
    ParserTestCase.parse4("parseFormalParameterList", "(a, [b, c})", [ParserErrorCode.WRONG_TERMINATOR_FOR_PARAMETER_GROUP]);
  }
}

class IncrementalParserTest extends EngineTestCase {
  void fail_replace_identifier_with_functionLiteral_in_initializer() {
    // Function literals aren't allowed inside initializers; incremental parsing needs to gather
    // the appropriate context.
    //
    // "class A { var a; A(b) : a = b ? b : 0 { } }"
    // "class A { var a; A(b) : a = b ? () {} : 0 { } }"
    _assertParse("class A { var a; A(b) : a = b ? ", "b", "() {}", " : 0 { } }");
  }

  void test_delete_everything() {
    // "f() => a + b;"
    // ""
    _assertParse("", "f() => a + b;", "", "");
  }

  void test_delete_identifier_beginning() {
    // "f() => abs + b;"
    // "f() => s + b;"
    _assertParse("f() => ", "ab", "", "s + b;");
  }

  void test_delete_identifier_end() {
    // "f() => abs + b;"
    // "f() => a + b;"
    _assertParse("f() => a", "bs", "", " + b;");
  }

  void test_delete_identifier_middle() {
    // "f() => abs + b;"
    // "f() => as + b;"
    _assertParse("f() => a", "b", "", "s + b;");
  }

  void test_delete_mergeTokens() {
    // "f() => a + b + c;"
    // "f() => ac;"
    _assertParse("f() => a", " + b + ", "", "c;");
  }

  void test_insert_afterIdentifier1() {
    // "f() => a + b;"
    // "f() => abs + b;"
    _assertParse("f() => a", "", "bs", " + b;");
  }

  void test_insert_afterIdentifier2() {
    // "f() => a + b;"
    // "f() => a + bar;"
    _assertParse("f() => a + b", "", "ar", ";");
  }

  void test_insert_beforeIdentifier1() {
    // "f() => a + b;"
    // "f() => xa + b;"
    _assertParse("f() => ", "", "x", "a + b;");
  }

  void test_insert_beforeIdentifier2() {
    // "f() => a + b;"
    // "f() => a + xb;"
    _assertParse("f() => a + ", "", "x", "b;");
  }

  void test_insert_convertOneFunctionToTwo() {
    // "f() {}"
    // "f() => 0; g() {}"
    _assertParse("f()", "", " => 0; g()", " {}");
  }

  void test_insert_end() {
    // "class A {}"
    // "class A {} class B {}"
    _assertParse("class A {}", "", " class B {}", "");
  }

  void test_insert_insideClassBody() {
    // "class C {C(); }"
    // "class C { C(); }"
    _assertParse("class C {", "", " ", "C(); }");
  }

  void test_insert_insideIdentifier() {
    // "f() => cob;"
    // "f() => cow.b;"
    _assertParse("f() => co", "", "w.", "b;");
  }

  void test_insert_newIdentifier1() {
    // "f() => a; c;"
    // "f() => a; b c;"
    _assertParse("f() => a;", "", " b", " c;");
  }

  void test_insert_newIdentifier2() {
    // "f() => a;  c;"
    // "f() => a;b  c;"
    _assertParse("f() => a;", "", "b", "  c;");
  }

  void test_insert_newIdentifier3() {
    // "/** A simple function. */ f() => a; c;"
    // "/** A simple function. */ f() => a; b c;"
    _assertParse("/** A simple function. */ f() => a;", "", " b", " c;");
  }

  void test_insert_newIdentifier4() {
    // "/** An [A]. */ class A {} class B { m() { return 1; } }"
    // "/** An [A]. */ class A {} class B { m() { return 1 + 2; } }"
    _assertParse("/** An [A]. */ class A {} class B { m() { return 1", "", " + 2", "; } }");
  }

  void test_insert_period() {
    // "f() => a + b;"
    // "f() => a + b.;"
    _assertParse("f() => a + b", "", ".", ";");
  }

  void test_insert_period_betweenIdentifiers1() {
    // "f() => a b;"
    // "f() => a. b;"
    _assertParse("f() => a", "", ".", " b;");
  }

  void test_insert_period_betweenIdentifiers2() {
    // "f() => a b;"
    // "f() => a .b;"
    _assertParse("f() => a ", "", ".", "b;");
  }

  void test_insert_period_betweenIdentifiers3() {
    // "f() => a  b;"
    // "f() => a . b;"
    _assertParse("f() => a ", "", ".", " b;");
  }

  void test_insert_period_insideExistingIdentifier() {
    // "f() => ab;"
    // "f() => a.b;"
    _assertParse("f() => a", "", ".", "b;");
  }

  void test_insert_periodAndIdentifier() {
    // "f() => a + b;"
    // "f() => a + b.x;"
    _assertParse("f() => a + b", "", ".x", ";");
  }

  void test_insert_simpleToComplexExression() {
    // "/** An [A]. */ class A {} class B { m() => 1; }"
    // "/** An [A]. */ class A {} class B { m() => 1 + 2; }"
    _assertParse("/** An [A]. */ class A {} class B { m() => 1", "", " + 2", "; }");
  }

  void test_insert_whitespace_end() {
    // "f() => a + b;"
    // "f() => a + b; "
    _assertParse("f() => a + b;", "", " ", "");
  }

  void test_insert_whitespace_end_multiple() {
    // "f() => a + b;"
    // "f() => a + b;  "
    _assertParse("f() => a + b;", "", "  ", "");
  }

  void test_insert_whitespace_middle() {
    // "f() => a + b;"
    // "f() => a  + b;"
    _assertParse("f() => a", "", " ", " + b;");
  }

  void test_replace_identifier_beginning() {
    // "f() => bell + b;"
    // "f() => fell + b;"
    _assertParse("f() => ", "b", "f", "ell + b;");
  }

  void test_replace_identifier_end() {
    // "f() => bell + b;"
    // "f() => belt + b;"
    _assertParse("f() => bel", "l", "t", " + b;");
  }

  void test_replace_identifier_middle() {
    // "f() => first + b;"
    // "f() => frost + b;"
    _assertParse("f() => f", "ir", "ro", "st + b;");
  }

  void test_replace_multiple_partialFirstAndLast() {
    // "f() => aa + bb;"
    // "f() => ab * ab;"
    _assertParse("f() => a", "a + b", "b * a", "b;");
  }

  void test_replace_operator_oneForMany() {
    // "f() => a + b;"
    // "f() => a * c - b;"
    _assertParse("f() => a ", "+", "* c -", " b;");
  }

  void test_replace_operator_oneForOne() {
    // "f() => a + b;"
    // "f() => a * b;"
    _assertParse("f() => a ", "+", "*", " b;");
  }

  /**
   * Given a description of the original and modified contents, perform an incremental scan of the
   * two pieces of text.
   *
   * @param prefix the unchanged text before the edit region
   * @param removed the text that was removed from the original contents
   * @param added the text that was added to the modified contents
   * @param suffix the unchanged text after the edit region
   */
  void _assertParse(String prefix, String removed, String added, String suffix) {
    //
    // Compute the information needed to perform the test.
    //
    String originalContents = "$prefix$removed$suffix";
    String modifiedContents = "$prefix$added$suffix";
    int replaceStart = prefix.length;
    Source source = new TestSource();
    //
    // Parse the original contents.
    //
    GatheringErrorListener originalListener = new GatheringErrorListener();
    Scanner originalScanner = new Scanner(source, new CharSequenceReader(originalContents), originalListener);
    Token originalTokens = originalScanner.tokenize();
    expect(originalTokens, isNotNull);
    Parser originalParser = new Parser(source, originalListener);
    CompilationUnit originalUnit = originalParser.parseCompilationUnit(originalTokens);
    expect(originalUnit, isNotNull);
    //
    // Parse the modified contents.
    //
    GatheringErrorListener modifiedListener = new GatheringErrorListener();
    Scanner modifiedScanner = new Scanner(source, new CharSequenceReader(modifiedContents), modifiedListener);
    Token modifiedTokens = modifiedScanner.tokenize();
    expect(modifiedTokens, isNotNull);
    Parser modifiedParser = new Parser(source, modifiedListener);
    CompilationUnit modifiedUnit = modifiedParser.parseCompilationUnit(modifiedTokens);
    expect(modifiedUnit, isNotNull);
    //
    // Incrementally parse the modified contents.
    //
    GatheringErrorListener incrementalListener = new GatheringErrorListener();
    IncrementalScanner incrementalScanner = new IncrementalScanner(source, new CharSequenceReader(modifiedContents), incrementalListener);
    Token incrementalTokens = incrementalScanner.rescan(originalTokens, replaceStart, removed.length, added.length);
    expect(incrementalTokens, isNotNull);
    IncrementalParser incrementalParser = new IncrementalParser(source, incrementalScanner.tokenMap, incrementalListener);
    CompilationUnit incrementalUnit = incrementalParser.reparse(originalUnit, incrementalScanner.leftToken, incrementalScanner.rightToken, replaceStart, prefix.length + removed.length);
    expect(incrementalUnit, isNotNull);
    //
    // Validate that the results of the incremental parse are the same as the full parse of the
    // modified source.
    //
    expect(AstComparator.equalNodes(modifiedUnit, incrementalUnit), isTrue);
    // TODO(brianwilkerson) Verify that the errors are correct?
  }
}

class NonErrorParserTest extends ParserTestCase {
  void test_constFactory_external() {
    ParserTestCase.parse("parseClassMember", <Object> ["C"], "external const factory C();");
  }
}

class ParserTestCase extends EngineTestCase {
  /**
   * An empty array of objects used as arguments to zero-argument methods.
   */
  static List<Object> _EMPTY_ARGUMENTS = new List<Object>(0);

  /**
   * A flag indicating whether parser is to parse function bodies.
   */
  static bool parseFunctionBodies = true;

  /**
   * Create a parser.
   *
   * @param listener the listener to be passed to the parser
   * @return the parser that was created
   */
  static Parser createParser(GatheringErrorListener listener) {
    Parser parser = new Parser(null, listener);
    parser.parseAsync = true;
    parser.parseDeferredLibraries = true;
    parser.parseEnum = true;
    return parser;
  }

  /**
   * Invoke a parse method in [Parser]. The method is assumed to have the given number and
   * type of parameters and will be invoked with the given arguments.
   *
   * The given source is scanned and the parser is initialized to start with the first token in the
   * source before the parse method is invoked.
   *
   * @param methodName the name of the parse method that should be invoked to parse the source
   * @param objects the values of the arguments to the method
   * @param source the source to be parsed by the parse method
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   * @throws AssertionFailedError if the result is `null` or if any errors are produced
   */
  static Object parse(String methodName, List<Object> objects, String source) => parse2(methodName, objects, source, new List<AnalysisError>(0));

  /**
   * Invoke a parse method in [Parser]. The method is assumed to have the given number and
   * type of parameters and will be invoked with the given arguments.
   *
   * The given source is scanned and the parser is initialized to start with the first token in the
   * source before the parse method is invoked.
   *
   * @param methodName the name of the parse method that should be invoked to parse the source
   * @param objects the values of the arguments to the method
   * @param source the source to be parsed by the parse method
   * @param errors the errors that should be generated
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   * @throws AssertionFailedError if the result is `null` or the errors produced while
   *           scanning and parsing the source do not match the expected errors
   */
  static Object parse2(String methodName, List<Object> objects, String source, List<AnalysisError> errors) {
    GatheringErrorListener listener = new GatheringErrorListener();
    Object result = invokeParserMethod(methodName, objects, source, listener);
    listener.assertErrors(errors);
    return result;
  }

  /**
   * Invoke a parse method in [Parser]. The method is assumed to have the given number and
   * type of parameters and will be invoked with the given arguments.
   *
   * The given source is scanned and the parser is initialized to start with the first token in the
   * source before the parse method is invoked.
   *
   * @param methodName the name of the parse method that should be invoked to parse the source
   * @param objects the values of the arguments to the method
   * @param source the source to be parsed by the parse method
   * @param errorCodes the error codes of the errors that should be generated
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   * @throws AssertionFailedError if the result is `null` or the errors produced while
   *           scanning and parsing the source do not match the expected errors
   */
  static Object parse3(String methodName, List<Object> objects, String source, List<ErrorCode> errorCodes) {
    GatheringErrorListener listener = new GatheringErrorListener();
    Object result = invokeParserMethod(methodName, objects, source, listener);
    listener.assertErrorsWithCodes(errorCodes);
    return result;
  }

  /**
   * Invoke a parse method in [Parser]. The method is assumed to have no arguments.
   *
   * The given source is scanned and the parser is initialized to start with the first token in the
   * source before the parse method is invoked.
   *
   * @param methodName the name of the parse method that should be invoked to parse the source
   * @param source the source to be parsed by the parse method
   * @param errorCodes the error codes of the errors that should be generated
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   * @throws AssertionFailedError if the result is `null` or the errors produced while
   *           scanning and parsing the source do not match the expected errors
   */
  static Object parse4(String methodName, String source, List<ErrorCode> errorCodes) => parse3(methodName, _EMPTY_ARGUMENTS, source, errorCodes);

  /**
   * Parse the given source as a compilation unit.
   *
   * @param source the source to be parsed
   * @param errorCodes the error codes of the errors that are expected to be found
   * @return the compilation unit that was parsed
   * @throws Exception if the source could not be parsed, if the compilation errors in the source do
   *           not match those that are expected, or if the result would have been `null`
   */
  static CompilationUnit parseCompilationUnit(String source, List<ErrorCode> errorCodes) {
    GatheringErrorListener listener = new GatheringErrorListener();
    Scanner scanner = new Scanner(null, new CharSequenceReader(source), listener);
    listener.setLineInfo(new TestSource(), scanner.lineStarts);
    Token token = scanner.tokenize();
    Parser parser = createParser(listener);
    CompilationUnit unit = parser.parseCompilationUnit(token);
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
  static Expression parseExpression(String source, List<ErrorCode> errorCodes) {
    GatheringErrorListener listener = new GatheringErrorListener();
    Scanner scanner = new Scanner(null, new CharSequenceReader(source), listener);
    listener.setLineInfo(new TestSource(), scanner.lineStarts);
    Token token = scanner.tokenize();
    Parser parser = createParser(listener);
    Expression expression = parser.parseExpression(token);
    expect(expression, isNotNull);
    listener.assertErrorsWithCodes(errorCodes);
    return expression;
  }

  /**
   * Parse the given source as a statement.
   *
   * @param source the source to be parsed
   * @param errorCodes the error codes of the errors that are expected to be found
   * @return the statement that was parsed
   * @throws Exception if the source could not be parsed, if the compilation errors in the source do
   *           not match those that are expected, or if the result would have been `null`
   */
  static Statement parseStatement(String source, List<ErrorCode> errorCodes) {
    GatheringErrorListener listener = new GatheringErrorListener();
    Scanner scanner = new Scanner(null, new CharSequenceReader(source), listener);
    listener.setLineInfo(new TestSource(), scanner.lineStarts);
    Token token = scanner.tokenize();
    Parser parser = createParser(listener);
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
  static List<Statement> parseStatements(String source, int expectedCount, List<ErrorCode> errorCodes) {
    GatheringErrorListener listener = new GatheringErrorListener();
    Scanner scanner = new Scanner(null, new CharSequenceReader(source), listener);
    listener.setLineInfo(new TestSource(), scanner.lineStarts);
    Token token = scanner.tokenize();
    Parser parser = createParser(listener);
    List<Statement> statements = parser.parseStatements(token);
    expect(statements, hasLength(expectedCount));
    listener.assertErrorsWithCodes(errorCodes);
    return statements;
  }

  /**
   * Invoke a method in [Parser]. The method is assumed to have the given number and type of
   * parameters and will be invoked with the given arguments.
   *
   * The given source is scanned and the parser is initialized to start with the first token in the
   * source before the method is invoked.
   *
   * @param methodName the name of the method that should be invoked
   * @param objects the values of the arguments to the method
   * @param source the source to be processed by the parse method
   * @param listener the error listener that will be used for both scanning and parsing
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   * @throws AssertionFailedError if the result is `null` or the errors produced while
   *           scanning and parsing the source do not match the expected errors
   */
  static Object invokeParserMethod(String methodName, List<Object> objects, String source, GatheringErrorListener listener) {
    //
    // Scan the source.
    //
    Scanner scanner = new Scanner(null, new CharSequenceReader(source), listener);
    Token tokenStream = scanner.tokenize();
    listener.setLineInfo(new TestSource(), scanner.lineStarts);
    //
    // Parse the source.
    //
    Parser parser = createParser(listener);
    parser.parseFunctionBodies = parseFunctionBodies;
    parser.parseDeferredLibraries = true;
    parser.parseAsync = true;
    Object result = invokeParserMethodImpl(parser, methodName, objects, tokenStream);
    //
    // Partially test the results.
    //
    if (!listener.hasErrors) {
      expect(result, isNotNull);
    }
    return result;
  }

  /**
   * Invoke a method in [Parser]. The method is assumed to have no arguments.
   *
   * The given source is scanned and the parser is initialized to start with the first token in the
   * source before the method is invoked.
   *
   * @param methodName the name of the method that should be invoked
   * @param source the source to be processed by the parse method
   * @param listener the error listener that will be used for both scanning and parsing
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   * @throws AssertionFailedError if the result is `null` or the errors produced while
   *           scanning and parsing the source do not match the expected errors
   */
  static Object invokeParserMethod2(String methodName, String source, GatheringErrorListener listener) => invokeParserMethod(methodName, _EMPTY_ARGUMENTS, source, listener);

  /**
   * Return a CommentAndMetadata object with the given values that can be used for testing.
   *
   * @param comment the comment to be wrapped in the object
   * @param annotations the annotations to be wrapped in the object
   * @return a CommentAndMetadata object that can be used for testing
   */
  CommentAndMetadata commentAndMetadata(Comment comment, List<Annotation> annotations) {
    List<Annotation> metadata = new List<Annotation>();
    for (Annotation annotation in annotations) {
      metadata.add(annotation);
    }
    return new CommentAndMetadata(comment, metadata);
  }

  /**
   * Return an empty CommentAndMetadata object that can be used for testing.
   *
   * @return an empty CommentAndMetadata object that can be used for testing
   */
  CommentAndMetadata emptyCommentAndMetadata() => new CommentAndMetadata(null, new List<Annotation>());

  @override
  void setUp() {
    super.setUp();
    parseFunctionBodies = true;
  }
}

/**
 * The class `RecoveryParserTest` defines parser tests that test the parsing of invalid code
 * sequences to ensure that the correct recovery steps are taken in the parser.
 */
class RecoveryParserTest extends ParserTestCase {
  void fail_incomplete_returnType() {
    ParserTestCase.parseCompilationUnit(r'''
Map<Symbol, convertStringToSymbolMap(Map<String, dynamic> map) {
  if (map == null) return null;
  Map<Symbol, dynamic> result = new Map<Symbol, dynamic>();
  map.forEach((name, value) {
    result[new Symbol(name)] = value;
  });
  return result;
}''', []);
  }

  void test_additiveExpression_missing_LHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("+ y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_additiveExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("+", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_additiveExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x +", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_additiveExpression_missing_RHS_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super +", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_additiveExpression_precedence_multiplicative_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("* +", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_additiveExpression_precedence_multiplicative_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("+ *", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.rightOperand);
  }

  void test_additiveExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super + +", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_assignmentExpression_missing_compound1() {
    AssignmentExpression expression = ParserTestCase.parseExpression("= y = 0", [ParserErrorCode.MISSING_IDENTIFIER]);
    Expression syntheticExpression = expression.leftHandSide;
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, syntheticExpression);
    expect(syntheticExpression.isSynthetic, isTrue);
  }

  void test_assignmentExpression_missing_compound2() {
    AssignmentExpression expression = ParserTestCase.parseExpression("x = = 0", [ParserErrorCode.MISSING_IDENTIFIER]);
    Expression syntheticExpression = (expression.rightHandSide as AssignmentExpression).leftHandSide;
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, syntheticExpression);
    expect(syntheticExpression.isSynthetic, isTrue);
  }

  void test_assignmentExpression_missing_compound3() {
    AssignmentExpression expression = ParserTestCase.parseExpression("x = y =", [ParserErrorCode.MISSING_IDENTIFIER]);
    Expression syntheticExpression = (expression.rightHandSide as AssignmentExpression).rightHandSide;
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, syntheticExpression);
    expect(syntheticExpression.isSynthetic, isTrue);
  }

  void test_assignmentExpression_missing_LHS() {
    AssignmentExpression expression = ParserTestCase.parseExpression("= 0", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftHandSide);
    expect(expression.leftHandSide.isSynthetic, isTrue);
  }

  void test_assignmentExpression_missing_RHS() {
    AssignmentExpression expression = ParserTestCase.parseExpression("x =", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftHandSide);
    expect(expression.rightHandSide.isSynthetic, isTrue);
  }

  void test_bitwiseAndExpression_missing_LHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("& y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_bitwiseAndExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("&", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseAndExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x &", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseAndExpression_missing_RHS_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super &", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseAndExpression_precedence_equality_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("== &&", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseAndExpression_precedence_equality_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("&& ==", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.rightOperand);
  }

  void test_bitwiseAndExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super &  &", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseOrExpression_missing_LHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("| y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_bitwiseOrExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("|", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseOrExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x |", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseOrExpression_missing_RHS_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super |", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseOrExpression_precedence_xor_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("^ |", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseOrExpression_precedence_xor_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("| ^", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.rightOperand);
  }

  void test_bitwiseOrExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super |  |", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseXorExpression_missing_LHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("^ y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_bitwiseXorExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("^", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseXorExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x ^", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseXorExpression_missing_RHS_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super ^", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_bitwiseXorExpression_precedence_and_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("& ^", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_bitwiseXorExpression_precedence_and_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("^ &", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.rightOperand);
  }

  void test_bitwiseXorExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super ^  ^", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_classTypeAlias_withBody() {
    ParserTestCase.parseCompilationUnit(r'''
class A {}
class B = Object with A {}''', [ParserErrorCode.EXPECTED_TOKEN]);
  }

  void test_conditionalExpression_missingElse() {
    ConditionalExpression expression = ParserTestCase.parse4("parseConditionalExpression", "x ? y :", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.elseExpression);
    expect(expression.elseExpression.isSynthetic, isTrue);
  }

  void test_conditionalExpression_missingThen() {
    ConditionalExpression expression = ParserTestCase.parse4("parseConditionalExpression", "x ? : z", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.thenExpression);
    expect(expression.thenExpression.isSynthetic, isTrue);
  }

  void test_equalityExpression_missing_LHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("== y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_equalityExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("==", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_equalityExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x ==", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_equalityExpression_missing_RHS_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super ==", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_equalityExpression_precedence_relational_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("is ==", [
        ParserErrorCode.EXPECTED_TYPE_NAME,
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is IsExpression, IsExpression, expression.leftOperand);
  }

  void test_equalityExpression_precedence_relational_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("== is", [
        ParserErrorCode.EXPECTED_TYPE_NAME,
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is IsExpression, IsExpression, expression.rightOperand);
  }

  void test_equalityExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super ==  ==", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_expressionList_multiple_end() {
    List<Expression> result = ParserTestCase.parse4("parseExpressionList", ", 2, 3, 4", [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(result, hasLength(4));
    Expression syntheticExpression = result[0];
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, syntheticExpression);
    expect(syntheticExpression.isSynthetic, isTrue);
  }

  void test_expressionList_multiple_middle() {
    List<Expression> result = ParserTestCase.parse4("parseExpressionList", "1, 2, , 4", [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(result, hasLength(4));
    Expression syntheticExpression = result[2];
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, syntheticExpression);
    expect(syntheticExpression.isSynthetic, isTrue);
  }

  void test_expressionList_multiple_start() {
    List<Expression> result = ParserTestCase.parse4("parseExpressionList", "1, 2, 3,", [ParserErrorCode.MISSING_IDENTIFIER]);
    expect(result, hasLength(4));
    Expression syntheticExpression = result[3];
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, syntheticExpression);
    expect(syntheticExpression.isSynthetic, isTrue);
  }

  void test_functionExpression_in_ConstructorFieldInitializer() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("class A { A() : a = (){}; var v; }", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.UNEXPECTED_TOKEN]);
    // Make sure we recovered and parsed "var v" correctly
    ClassDeclaration declaration = unit.declarations[0] as ClassDeclaration;
    NodeList<ClassMember> members = declaration.members;
    ClassMember fieldDecl = members[1];
    EngineTestCase.assertInstanceOf((obj) => obj is FieldDeclaration, FieldDeclaration, fieldDecl);
    NodeList<VariableDeclaration> vars = (fieldDecl as FieldDeclaration).fields.variables;
    expect(vars, hasLength(1));
    expect(vars[0].name.name, "v");
  }

  void test_incomplete_topLevelVariable() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("String", [ParserErrorCode.EXPECTED_EXECUTABLE]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember member = declarations[0];
    EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableDeclaration, TopLevelVariableDeclaration, member);
    NodeList<VariableDeclaration> variables = (member as TopLevelVariableDeclaration).variables.variables;
    expect(variables, hasLength(1));
    SimpleIdentifier name = variables[0].name;
    expect(name.isSynthetic, isTrue);
  }

  void test_incomplete_topLevelVariable_const() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("const ", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.EXPECTED_TOKEN]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember member = declarations[0];
    EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableDeclaration, TopLevelVariableDeclaration, member);
    NodeList<VariableDeclaration> variables = (member as TopLevelVariableDeclaration).variables.variables;
    expect(variables, hasLength(1));
    SimpleIdentifier name = variables[0].name;
    expect(name.isSynthetic, isTrue);
  }

  void test_incomplete_topLevelVariable_final() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("final ", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.EXPECTED_TOKEN]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember member = declarations[0];
    EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableDeclaration, TopLevelVariableDeclaration, member);
    NodeList<VariableDeclaration> variables = (member as TopLevelVariableDeclaration).variables.variables;
    expect(variables, hasLength(1));
    SimpleIdentifier name = variables[0].name;
    expect(name.isSynthetic, isTrue);
  }

  void test_incomplete_topLevelVariable_var() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("var ", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.EXPECTED_TOKEN]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember member = declarations[0];
    EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableDeclaration, TopLevelVariableDeclaration, member);
    NodeList<VariableDeclaration> variables = (member as TopLevelVariableDeclaration).variables.variables;
    expect(variables, hasLength(1));
    SimpleIdentifier name = variables[0].name;
    expect(name.isSynthetic, isTrue);
  }

  void test_incompleteField_const() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(r'''
class C {
  const
}''', [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.EXPECTED_TOKEN]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember unitMember = declarations[0];
    EngineTestCase.assertInstanceOf((obj) => obj is ClassDeclaration, ClassDeclaration, unitMember);
    NodeList<ClassMember> members = (unitMember as ClassDeclaration).members;
    expect(members, hasLength(1));
    ClassMember classMember = members[0];
    EngineTestCase.assertInstanceOf((obj) => obj is FieldDeclaration, FieldDeclaration, classMember);
    VariableDeclarationList fieldList = (classMember as FieldDeclaration).fields;
    expect((fieldList.keyword as KeywordToken).keyword, Keyword.CONST);
    NodeList<VariableDeclaration> fields = fieldList.variables;
    expect(fields, hasLength(1));
    VariableDeclaration field = fields[0];
    expect(field.name.isSynthetic, isTrue);
  }

  void test_incompleteField_final() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(r'''
class C {
  final
}''', [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.EXPECTED_TOKEN]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember unitMember = declarations[0];
    EngineTestCase.assertInstanceOf((obj) => obj is ClassDeclaration, ClassDeclaration, unitMember);
    NodeList<ClassMember> members = (unitMember as ClassDeclaration).members;
    expect(members, hasLength(1));
    ClassMember classMember = members[0];
    EngineTestCase.assertInstanceOf((obj) => obj is FieldDeclaration, FieldDeclaration, classMember);
    VariableDeclarationList fieldList = (classMember as FieldDeclaration).fields;
    expect((fieldList.keyword as KeywordToken).keyword, Keyword.FINAL);
    NodeList<VariableDeclaration> fields = fieldList.variables;
    expect(fields, hasLength(1));
    VariableDeclaration field = fields[0];
    expect(field.name.isSynthetic, isTrue);
  }

  void test_incompleteField_var() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(r'''
class C {
  var
}''', [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.EXPECTED_TOKEN]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember unitMember = declarations[0];
    EngineTestCase.assertInstanceOf((obj) => obj is ClassDeclaration, ClassDeclaration, unitMember);
    NodeList<ClassMember> members = (unitMember as ClassDeclaration).members;
    expect(members, hasLength(1));
    ClassMember classMember = members[0];
    EngineTestCase.assertInstanceOf((obj) => obj is FieldDeclaration, FieldDeclaration, classMember);
    VariableDeclarationList fieldList = (classMember as FieldDeclaration).fields;
    expect((fieldList.keyword as KeywordToken).keyword, Keyword.VAR);
    NodeList<VariableDeclaration> fields = fieldList.variables;
    expect(fields, hasLength(1));
    VariableDeclaration field = fields[0];
    expect(field.name.isSynthetic, isTrue);
  }

  void test_isExpression_noType() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("class Bar<T extends Foo> {m(x){if (x is ) return;if (x is !)}}", [
        ParserErrorCode.EXPECTED_TYPE_NAME,
        ParserErrorCode.EXPECTED_TYPE_NAME,
        ParserErrorCode.MISSING_STATEMENT]);
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
    EngineTestCase.assertInstanceOf((obj) => obj is EmptyStatement, EmptyStatement, ifStatement.thenStatement);
  }

  void test_logicalAndExpression_missing_LHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("&& y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_logicalAndExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("&&", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_logicalAndExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x &&", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_logicalAndExpression_precedence_bitwiseOr_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("| &&", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_logicalAndExpression_precedence_bitwiseOr_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("&& |", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.rightOperand);
  }

  void test_logicalOrExpression_missing_LHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("|| y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_logicalOrExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("||", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_logicalOrExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x ||", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_logicalOrExpression_precedence_logicalAnd_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("&& ||", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_logicalOrExpression_precedence_logicalAnd_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("|| &&", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.rightOperand);
  }

  void test_missingGet() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(r'''
class C {
  int length {}
  void foo() {}
}''', [ParserErrorCode.MISSING_GET]);
    expect(unit, isNotNull);
    ClassDeclaration classDeclaration = unit.declarations[0] as ClassDeclaration;
    NodeList<ClassMember> members = classDeclaration.members;
    expect(members, hasLength(2));
    EngineTestCase.assertInstanceOf((obj) => obj is MethodDeclaration, MethodDeclaration, members[0]);
    ClassMember member = members[1];
    EngineTestCase.assertInstanceOf((obj) => obj is MethodDeclaration, MethodDeclaration, member);
    expect((member as MethodDeclaration).name.name, "foo");
  }

  void test_missingIdentifier_afterAnnotation() {
    MethodDeclaration method = ParserTestCase.parse3("parseClassMember", <Object> ["C"], "@override }", [ParserErrorCode.EXPECTED_CLASS_MEMBER]);
    expect(method.documentationComment, isNull);
    NodeList<Annotation> metadata = method.metadata;
    expect(metadata, hasLength(1));
    expect(metadata[0].name.name, "override");
  }

  void test_multiplicativeExpression_missing_LHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("* y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_multiplicativeExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("*", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_multiplicativeExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x *", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_multiplicativeExpression_missing_RHS_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super *", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_multiplicativeExpression_precedence_unary_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("-x *", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is PrefixExpression, PrefixExpression, expression.leftOperand);
  }

  void test_multiplicativeExpression_precedence_unary_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("* -y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is PrefixExpression, PrefixExpression, expression.rightOperand);
  }

  void test_multiplicativeExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super ==  ==", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_prefixExpression_missing_operand_minus() {
    PrefixExpression expression = ParserTestCase.parseExpression("-", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.operand);
    expect(expression.operand.isSynthetic, isTrue);
    expect(expression.operator.type, TokenType.MINUS);
  }

  void test_primaryExpression_argumentDefinitionTest() {
    Expression expression = ParserTestCase.parse4("parsePrimaryExpression", "?a", [ParserErrorCode.UNEXPECTED_TOKEN]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression);
  }

  void test_relationalExpression_missing_LHS() {
    IsExpression expression = ParserTestCase.parseExpression("is y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.expression);
    expect(expression.expression.isSynthetic, isTrue);
  }

  void test_relationalExpression_missing_LHS_RHS() {
    IsExpression expression = ParserTestCase.parseExpression("is", [
        ParserErrorCode.EXPECTED_TYPE_NAME,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.expression);
    expect(expression.expression.isSynthetic, isTrue);
    EngineTestCase.assertInstanceOf((obj) => obj is TypeName, TypeName, expression.type);
    expect(expression.type.isSynthetic, isTrue);
  }

  void test_relationalExpression_missing_RHS() {
    IsExpression expression = ParserTestCase.parseExpression("x is", [ParserErrorCode.EXPECTED_TYPE_NAME]);
    EngineTestCase.assertInstanceOf((obj) => obj is TypeName, TypeName, expression.type);
    expect(expression.type.isSynthetic, isTrue);
  }

  void test_relationalExpression_precedence_shift_right() {
    IsExpression expression = ParserTestCase.parseExpression("<< is", [
        ParserErrorCode.EXPECTED_TYPE_NAME,
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.expression);
  }

  void test_shiftExpression_missing_LHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("<< y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
  }

  void test_shiftExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("<<", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    expect(expression.leftOperand.isSynthetic, isTrue);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_shiftExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x <<", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_shiftExpression_missing_RHS_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super <<", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    expect(expression.rightOperand.isSynthetic, isTrue);
  }

  void test_shiftExpression_precedence_unary_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("+ <<", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_shiftExpression_precedence_unary_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("<< +", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.rightOperand);
  }

  void test_shiftExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super << <<", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.leftOperand);
  }

  void test_typedef_eof() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("typedef n", [
        ParserErrorCode.EXPECTED_TOKEN,
        ParserErrorCode.MISSING_TYPEDEF_PARAMETERS]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember member = declarations[0];
    EngineTestCase.assertInstanceOf((obj) => obj is FunctionTypeAlias, FunctionTypeAlias, member);
  }
}

class ResolutionCopierTest extends EngineTestCase {
  void test_visitAnnotation() {
    String annotationName = "proxy";
    Annotation fromNode = AstFactory.annotation(AstFactory.identifier3(annotationName));
    Element element = ElementFactory.topLevelVariableElement2(annotationName);
    fromNode.element = element;
    Annotation toNode = AstFactory.annotation(AstFactory.identifier3(annotationName));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.element, same(element));
  }

  void test_visitAsExpression() {
    AsExpression fromNode = AstFactory.asExpression(AstFactory.identifier3("x"), AstFactory.typeName4("A", []));
    DartType propagatedType = ElementFactory.classElement2("A", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("B", []).type;
    fromNode.staticType = staticType;
    AsExpression toNode = AstFactory.asExpression(AstFactory.identifier3("x"), AstFactory.typeName4("A", []));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitAssignmentExpression() {
    AssignmentExpression fromNode = AstFactory.assignmentExpression(AstFactory.identifier3("a"), TokenType.PLUS_EQ, AstFactory.identifier3("b"));
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    MethodElement propagatedElement = ElementFactory.methodElement("+", propagatedType, []);
    fromNode.propagatedElement = propagatedElement;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    MethodElement staticElement = ElementFactory.methodElement("+", staticType, []);
    fromNode.staticElement = staticElement;
    fromNode.staticType = staticType;
    AssignmentExpression toNode = AstFactory.assignmentExpression(AstFactory.identifier3("a"), TokenType.PLUS_EQ, AstFactory.identifier3("b"));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedElement, same(propagatedElement));
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticElement, same(staticElement));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitBinaryExpression() {
    BinaryExpression fromNode = AstFactory.binaryExpression(AstFactory.identifier3("a"), TokenType.PLUS, AstFactory.identifier3("b"));
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    MethodElement propagatedElement = ElementFactory.methodElement("+", propagatedType, []);
    fromNode.propagatedElement = propagatedElement;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    MethodElement staticElement = ElementFactory.methodElement("+", staticType, []);
    fromNode.staticElement = staticElement;
    fromNode.staticType = staticType;
    BinaryExpression toNode = AstFactory.binaryExpression(AstFactory.identifier3("a"), TokenType.PLUS, AstFactory.identifier3("b"));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedElement, same(propagatedElement));
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticElement, same(staticElement));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitBooleanLiteral() {
    BooleanLiteral fromNode = AstFactory.booleanLiteral(true);
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    BooleanLiteral toNode = AstFactory.booleanLiteral(true);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitCascadeExpression() {
    CascadeExpression fromNode = AstFactory.cascadeExpression(AstFactory.identifier3("a"), [AstFactory.identifier3("b")]);
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    CascadeExpression toNode = AstFactory.cascadeExpression(AstFactory.identifier3("a"), [AstFactory.identifier3("b")]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitCompilationUnit() {
    CompilationUnit fromNode = AstFactory.compilationUnit();
    CompilationUnitElement element = new CompilationUnitElementImpl("test.dart");
    fromNode.element = element;
    CompilationUnit toNode = AstFactory.compilationUnit();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.element, same(element));
  }

  void test_visitConditionalExpression() {
    ConditionalExpression fromNode = AstFactory.conditionalExpression(AstFactory.identifier3("c"), AstFactory.identifier3("a"), AstFactory.identifier3("b"));
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    ConditionalExpression toNode = AstFactory.conditionalExpression(AstFactory.identifier3("c"), AstFactory.identifier3("a"), AstFactory.identifier3("b"));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitConstructorDeclaration() {
    String className = "A";
    String constructorName = "c";
    ConstructorDeclaration fromNode = AstFactory.constructorDeclaration(AstFactory.identifier3(className), constructorName, AstFactory.formalParameterList([]), null);
    ConstructorElement element = ElementFactory.constructorElement2(ElementFactory.classElement2(className, []), constructorName, []);
    fromNode.element = element;
    ConstructorDeclaration toNode = AstFactory.constructorDeclaration(AstFactory.identifier3(className), constructorName, AstFactory.formalParameterList([]), null);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.element, same(element));
  }

  void test_visitConstructorName() {
    ConstructorName fromNode = AstFactory.constructorName(AstFactory.typeName4("A", []), "c");
    ConstructorElement staticElement = ElementFactory.constructorElement2(ElementFactory.classElement2("A", []), "c", []);
    fromNode.staticElement = staticElement;
    ConstructorName toNode = AstFactory.constructorName(AstFactory.typeName4("A", []), "c");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticElement, same(staticElement));
  }

  void test_visitDoubleLiteral() {
    DoubleLiteral fromNode = AstFactory.doubleLiteral(1.0);
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    DoubleLiteral toNode = AstFactory.doubleLiteral(1.0);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitExportDirective() {
    ExportDirective fromNode = AstFactory.exportDirective2("dart:uri", []);
    ExportElement element = new ExportElementImpl();
    fromNode.element = element;
    ExportDirective toNode = AstFactory.exportDirective2("dart:uri", []);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.element, same(element));
  }

  void test_visitFunctionExpression() {
    FunctionExpression fromNode = AstFactory.functionExpression2(AstFactory.formalParameterList([]), AstFactory.emptyFunctionBody());
    MethodElement element = ElementFactory.methodElement("m", ElementFactory.classElement2("C", []).type, []);
    fromNode.element = element;
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    FunctionExpression toNode = AstFactory.functionExpression2(AstFactory.formalParameterList([]), AstFactory.emptyFunctionBody());
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.element, same(element));
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitFunctionExpressionInvocation() {
    FunctionExpressionInvocation fromNode = AstFactory.functionExpressionInvocation(AstFactory.identifier3("f"), []);
    MethodElement propagatedElement = ElementFactory.methodElement("m", ElementFactory.classElement2("C", []).type, []);
    fromNode.propagatedElement = propagatedElement;
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    MethodElement staticElement = ElementFactory.methodElement("m", ElementFactory.classElement2("C", []).type, []);
    fromNode.staticElement = staticElement;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    FunctionExpressionInvocation toNode = AstFactory.functionExpressionInvocation(AstFactory.identifier3("f"), []);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedElement, same(propagatedElement));
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticElement, same(staticElement));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitImportDirective() {
    ImportDirective fromNode = AstFactory.importDirective3("dart:uri", null, []);
    ImportElement element = new ImportElementImpl(0);
    fromNode.element = element;
    ImportDirective toNode = AstFactory.importDirective3("dart:uri", null, []);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.element, same(element));
  }

  void test_visitIndexExpression() {
    IndexExpression fromNode = AstFactory.indexExpression(AstFactory.identifier3("a"), AstFactory.integer(0));
    MethodElement propagatedElement = ElementFactory.methodElement("m", ElementFactory.classElement2("C", []).type, []);
    MethodElement staticElement = ElementFactory.methodElement("m", ElementFactory.classElement2("C", []).type, []);
    AuxiliaryElements auxiliaryElements = new AuxiliaryElements(staticElement, propagatedElement);
    fromNode.auxiliaryElements = auxiliaryElements;
    fromNode.propagatedElement = propagatedElement;
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    fromNode.staticElement = staticElement;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    IndexExpression toNode = AstFactory.indexExpression(AstFactory.identifier3("a"), AstFactory.integer(0));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.auxiliaryElements, same(auxiliaryElements));
    expect(toNode.propagatedElement, same(propagatedElement));
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticElement, same(staticElement));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitInstanceCreationExpression() {
    InstanceCreationExpression fromNode = AstFactory.instanceCreationExpression2(Keyword.NEW, AstFactory.typeName4("C", []), []);
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    ConstructorElement staticElement = ElementFactory.constructorElement2(ElementFactory.classElement2("C", []), null, []);
    fromNode.staticElement = staticElement;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    InstanceCreationExpression toNode = AstFactory.instanceCreationExpression2(Keyword.NEW, AstFactory.typeName4("C", []), []);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticElement, same(staticElement));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitIntegerLiteral() {
    IntegerLiteral fromNode = AstFactory.integer(2);
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    IntegerLiteral toNode = AstFactory.integer(2);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitIsExpression() {
    IsExpression fromNode = AstFactory.isExpression(AstFactory.identifier3("x"), false, AstFactory.typeName4("A", []));
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    IsExpression toNode = AstFactory.isExpression(AstFactory.identifier3("x"), false, AstFactory.typeName4("A", []));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitLibraryIdentifier() {
    LibraryIdentifier fromNode = AstFactory.libraryIdentifier([AstFactory.identifier3("lib")]);
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    LibraryIdentifier toNode = AstFactory.libraryIdentifier([AstFactory.identifier3("lib")]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitListLiteral() {
    ListLiteral fromNode = AstFactory.listLiteral([]);
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    ListLiteral toNode = AstFactory.listLiteral([]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitMapLiteral() {
    MapLiteral fromNode = AstFactory.mapLiteral2([]);
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    MapLiteral toNode = AstFactory.mapLiteral2([]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitMethodInvocation() {
    MethodInvocation fromNode = AstFactory.methodInvocation2("m", []);
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    MethodInvocation toNode = AstFactory.methodInvocation2("m", []);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitNamedExpression() {
    NamedExpression fromNode = AstFactory.namedExpression2("n", AstFactory.integer(0));
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    NamedExpression toNode = AstFactory.namedExpression2("n", AstFactory.integer(0));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitNullLiteral() {
    NullLiteral fromNode = AstFactory.nullLiteral();
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    NullLiteral toNode = AstFactory.nullLiteral();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitParenthesizedExpression() {
    ParenthesizedExpression fromNode = AstFactory.parenthesizedExpression(AstFactory.integer(0));
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    ParenthesizedExpression toNode = AstFactory.parenthesizedExpression(AstFactory.integer(0));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitPartDirective() {
    PartDirective fromNode = AstFactory.partDirective2("part.dart");
    LibraryElement element = new LibraryElementImpl.forNode(null, AstFactory.libraryIdentifier2(["lib"]));
    fromNode.element = element;
    PartDirective toNode = AstFactory.partDirective2("part.dart");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.element, same(element));
  }

  void test_visitPartOfDirective() {
    PartOfDirective fromNode = AstFactory.partOfDirective(AstFactory.libraryIdentifier2(["lib"]));
    LibraryElement element = new LibraryElementImpl.forNode(null, AstFactory.libraryIdentifier2(["lib"]));
    fromNode.element = element;
    PartOfDirective toNode = AstFactory.partOfDirective(AstFactory.libraryIdentifier2(["lib"]));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.element, same(element));
  }

  void test_visitPostfixExpression() {
    String variableName = "x";
    PostfixExpression fromNode = AstFactory.postfixExpression(AstFactory.identifier3(variableName), TokenType.PLUS_PLUS);
    MethodElement propagatedElement = ElementFactory.methodElement("+", ElementFactory.classElement2("C", []).type, []);
    fromNode.propagatedElement = propagatedElement;
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    MethodElement staticElement = ElementFactory.methodElement("+", ElementFactory.classElement2("C", []).type, []);
    fromNode.staticElement = staticElement;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    PostfixExpression toNode = AstFactory.postfixExpression(AstFactory.identifier3(variableName), TokenType.PLUS_PLUS);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedElement, same(propagatedElement));
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticElement, same(staticElement));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitPrefixedIdentifier() {
    PrefixedIdentifier fromNode = AstFactory.identifier5("p", "f");
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    PrefixedIdentifier toNode = AstFactory.identifier5("p", "f");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitPrefixExpression() {
    PrefixExpression fromNode = AstFactory.prefixExpression(TokenType.PLUS_PLUS, AstFactory.identifier3("x"));
    MethodElement propagatedElement = ElementFactory.methodElement("+", ElementFactory.classElement2("C", []).type, []);
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedElement = propagatedElement;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    MethodElement staticElement = ElementFactory.methodElement("+", ElementFactory.classElement2("C", []).type, []);
    fromNode.staticElement = staticElement;
    fromNode.staticType = staticType;
    PrefixExpression toNode = AstFactory.prefixExpression(TokenType.PLUS_PLUS, AstFactory.identifier3("x"));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedElement, same(propagatedElement));
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticElement, same(staticElement));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitPropertyAccess() {
    PropertyAccess fromNode = AstFactory.propertyAccess2(AstFactory.identifier3("x"), "y");
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    PropertyAccess toNode = AstFactory.propertyAccess2(AstFactory.identifier3("x"), "y");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitRedirectingConstructorInvocation() {
    RedirectingConstructorInvocation fromNode = AstFactory.redirectingConstructorInvocation([]);
    ConstructorElement staticElement = ElementFactory.constructorElement2(ElementFactory.classElement2("C", []), null, []);
    fromNode.staticElement = staticElement;
    RedirectingConstructorInvocation toNode = AstFactory.redirectingConstructorInvocation([]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticElement, same(staticElement));
  }

  void test_visitRethrowExpression() {
    RethrowExpression fromNode = AstFactory.rethrowExpression();
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    RethrowExpression toNode = AstFactory.rethrowExpression();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitSimpleIdentifier() {
    SimpleIdentifier fromNode = AstFactory.identifier3("x");
    MethodElement propagatedElement = ElementFactory.methodElement("m", ElementFactory.classElement2("C", []).type, []);
    MethodElement staticElement = ElementFactory.methodElement("m", ElementFactory.classElement2("C", []).type, []);
    AuxiliaryElements auxiliaryElements = new AuxiliaryElements(staticElement, propagatedElement);
    fromNode.auxiliaryElements = auxiliaryElements;
    fromNode.propagatedElement = propagatedElement;
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    fromNode.staticElement = staticElement;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    SimpleIdentifier toNode = AstFactory.identifier3("x");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.auxiliaryElements, same(auxiliaryElements));
    expect(toNode.propagatedElement, same(propagatedElement));
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticElement, same(staticElement));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitSimpleStringLiteral() {
    SimpleStringLiteral fromNode = AstFactory.string2("abc");
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    SimpleStringLiteral toNode = AstFactory.string2("abc");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitStringInterpolation() {
    StringInterpolation fromNode = AstFactory.string([AstFactory.interpolationString("a", "'a'")]);
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    StringInterpolation toNode = AstFactory.string([AstFactory.interpolationString("a", "'a'")]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitSuperConstructorInvocation() {
    SuperConstructorInvocation fromNode = AstFactory.superConstructorInvocation([]);
    ConstructorElement staticElement = ElementFactory.constructorElement2(ElementFactory.classElement2("C", []), null, []);
    fromNode.staticElement = staticElement;
    SuperConstructorInvocation toNode = AstFactory.superConstructorInvocation([]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticElement, same(staticElement));
  }

  void test_visitSuperExpression() {
    SuperExpression fromNode = AstFactory.superExpression();
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    SuperExpression toNode = AstFactory.superExpression();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitSymbolLiteral() {
    SymbolLiteral fromNode = AstFactory.symbolLiteral(["s"]);
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    SymbolLiteral toNode = AstFactory.symbolLiteral(["s"]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitThisExpression() {
    ThisExpression fromNode = AstFactory.thisExpression();
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    ThisExpression toNode = AstFactory.thisExpression();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitThrowExpression() {
    ThrowExpression fromNode = AstFactory.throwExpression();
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    ThrowExpression toNode = AstFactory.throwExpression();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitTypeName() {
    TypeName fromNode = AstFactory.typeName4("C", []);
    DartType type = ElementFactory.classElement2("C", []).type;
    fromNode.type = type;
    TypeName toNode = AstFactory.typeName4("C", []);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.type, same(type));
  }
}

/**
 * The class `SimpleParserTest` defines parser tests that test individual parsing method. The
 * code fragments should be as minimal as possible in order to test the method, but should not test
 * the interactions between the method under test and other methods.
 *
 * More complex tests should be defined in the class [ComplexParserTest].
 */
class SimpleParserTest extends ParserTestCase {
  void fail_parseCommentReference_this() {
    // This fails because we are returning null from the method and asserting that the return value
    // is not null.
    CommentReference reference = ParserTestCase.parse("parseCommentReference", <Object> ["this", 5], "");
    SimpleIdentifier identifier = EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, reference.identifier);
    expect(identifier.token, isNotNull);
    expect(identifier.name, "a");
    expect(identifier.offset, 5);
  }

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
    ParserTestCase.parse("parseClassMember", <Object> ["C"], "const factory C() = A;");
  }

  void test_createSyntheticIdentifier() {
    SimpleIdentifier identifier = _createSyntheticIdentifier();
    expect(identifier.isSynthetic, isTrue);
  }

  void test_createSyntheticStringLiteral() {
    SimpleStringLiteral literal = _createSyntheticStringLiteral();
    expect(literal.isSynthetic, isTrue);
  }

  void test_function_literal_allowed_at_toplevel() {
    ParserTestCase.parseCompilationUnit("var x = () {};", []);
  }

  void test_function_literal_allowed_in_ArgumentList_in_ConstructorFieldInitializer() {
    ParserTestCase.parseCompilationUnit("class C { C() : a = f(() {}); }", []);
  }

  void test_function_literal_allowed_in_IndexExpression_in_ConstructorFieldInitializer() {
    ParserTestCase.parseCompilationUnit("class C { C() : a = x[() {}]; }", []);
  }

  void test_function_literal_allowed_in_ListLiteral_in_ConstructorFieldInitializer() {
    ParserTestCase.parseCompilationUnit("class C { C() : a = [() {}]; }", []);
  }

  void test_function_literal_allowed_in_MapLiteral_in_ConstructorFieldInitializer() {
    ParserTestCase.parseCompilationUnit("class C { C() : a = {'key': () {}}; }", []);
  }

  void test_function_literal_allowed_in_ParenthesizedExpression_in_ConstructorFieldInitializer() {
    ParserTestCase.parseCompilationUnit("class C { C() : a = (() {}); }", []);
  }

  void test_function_literal_allowed_in_StringInterpolation_in_ConstructorFieldInitializer() {
    ParserTestCase.parseCompilationUnit("class C { C() : a = \"\${(){}}\"; }", []);
  }

  void test_isFunctionDeclaration_nameButNoReturn_block() {
    expect(_isFunctionDeclaration("f() {}"), isTrue);
  }

  void test_isFunctionDeclaration_nameButNoReturn_expression() {
    expect(_isFunctionDeclaration("f() => e"), isTrue);
  }

  void test_isFunctionDeclaration_normalReturn_block() {
    expect(_isFunctionDeclaration("C f() {}"), isTrue);
  }

  void test_isFunctionDeclaration_normalReturn_expression() {
    expect(_isFunctionDeclaration("C f() => e"), isTrue);
  }

  void test_isFunctionDeclaration_voidReturn_block() {
    expect(_isFunctionDeclaration("void f() {}"), isTrue);
  }

  void test_isFunctionDeclaration_voidReturn_expression() {
    expect(_isFunctionDeclaration("void f() => e"), isTrue);
  }

  void test_isFunctionExpression_false_noBody() {
    expect(_isFunctionExpression("f();"), isFalse);
  }

  void test_isFunctionExpression_false_notParameters() {
    expect(_isFunctionExpression("(a + b) {"), isFalse);
  }

  void test_isFunctionExpression_noName_block() {
    expect(_isFunctionExpression("() {}"), isTrue);
  }

  void test_isFunctionExpression_noName_expression() {
    expect(_isFunctionExpression("() => e"), isTrue);
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
    expect(_isInitializedVariableDeclaration("a == null ? init() : update();"), isFalse);
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
    BinaryExpression expression = ParserTestCase.parse4("parseAdditiveExpression", "x + y", []);
    expect(expression.leftOperand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.PLUS);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseAdditiveExpression_super() {
    BinaryExpression expression = ParserTestCase.parse4("parseAdditiveExpression", "super + y", []);
    EngineTestCase.assertInstanceOf((obj) => obj is SuperExpression, SuperExpression, expression.leftOperand);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.PLUS);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseAnnotation_n1() {
    Annotation annotation = ParserTestCase.parse4("parseAnnotation", "@A", []);
    expect(annotation.atSign, isNotNull);
    expect(annotation.name, isNotNull);
    expect(annotation.period, isNull);
    expect(annotation.constructorName, isNull);
    expect(annotation.arguments, isNull);
  }

  void test_parseAnnotation_n1_a() {
    Annotation annotation = ParserTestCase.parse4("parseAnnotation", "@A(x,y)", []);
    expect(annotation.atSign, isNotNull);
    expect(annotation.name, isNotNull);
    expect(annotation.period, isNull);
    expect(annotation.constructorName, isNull);
    expect(annotation.arguments, isNotNull);
  }

  void test_parseAnnotation_n2() {
    Annotation annotation = ParserTestCase.parse4("parseAnnotation", "@A.B", []);
    expect(annotation.atSign, isNotNull);
    expect(annotation.name, isNotNull);
    expect(annotation.period, isNull);
    expect(annotation.constructorName, isNull);
    expect(annotation.arguments, isNull);
  }

  void test_parseAnnotation_n2_a() {
    Annotation annotation = ParserTestCase.parse4("parseAnnotation", "@A.B(x,y)", []);
    expect(annotation.atSign, isNotNull);
    expect(annotation.name, isNotNull);
    expect(annotation.period, isNull);
    expect(annotation.constructorName, isNull);
    expect(annotation.arguments, isNotNull);
  }

  void test_parseAnnotation_n3() {
    Annotation annotation = ParserTestCase.parse4("parseAnnotation", "@A.B.C", []);
    expect(annotation.atSign, isNotNull);
    expect(annotation.name, isNotNull);
    expect(annotation.period, isNotNull);
    expect(annotation.constructorName, isNotNull);
    expect(annotation.arguments, isNull);
  }

  void test_parseAnnotation_n3_a() {
    Annotation annotation = ParserTestCase.parse4("parseAnnotation", "@A.B.C(x,y)", []);
    expect(annotation.atSign, isNotNull);
    expect(annotation.name, isNotNull);
    expect(annotation.period, isNotNull);
    expect(annotation.constructorName, isNotNull);
    expect(annotation.arguments, isNotNull);
  }

  void test_parseArgument_named() {
    NamedExpression expression = ParserTestCase.parse4("parseArgument", "n: x", []);
    Label name = expression.name;
    expect(name, isNotNull);
    expect(name.label, isNotNull);
    expect(name.colon, isNotNull);
    expect(expression.expression, isNotNull);
  }

  void test_parseArgument_unnamed() {
    String lexeme = "x";
    SimpleIdentifier identifier = ParserTestCase.parse4("parseArgument", lexeme, []);
    expect(identifier.name, lexeme);
  }

  void test_parseArgumentList_empty() {
    ArgumentList argumentList = ParserTestCase.parse4("parseArgumentList", "()", []);
    NodeList<Expression> arguments = argumentList.arguments;
    expect(arguments, hasLength(0));
  }

  void test_parseArgumentList_mixed() {
    ArgumentList argumentList = ParserTestCase.parse4("parseArgumentList", "(w, x, y: y, z: z)", []);
    NodeList<Expression> arguments = argumentList.arguments;
    expect(arguments, hasLength(4));
  }

  void test_parseArgumentList_noNamed() {
    ArgumentList argumentList = ParserTestCase.parse4("parseArgumentList", "(x, y, z)", []);
    NodeList<Expression> arguments = argumentList.arguments;
    expect(arguments, hasLength(3));
  }

  void test_parseArgumentList_onlyNamed() {
    ArgumentList argumentList = ParserTestCase.parse4("parseArgumentList", "(x: x, y: y)", []);
    NodeList<Expression> arguments = argumentList.arguments;
    expect(arguments, hasLength(2));
  }

  void test_parseAssertStatement() {
    AssertStatement statement = ParserTestCase.parse4("parseAssertStatement", "assert (x);", []);
    expect(statement.keyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseAssignableExpression_expression_args_dot() {
    PropertyAccess propertyAccess = ParserTestCase.parse("parseAssignableExpression", <Object> [false], "(x)(y).z");
    FunctionExpressionInvocation invocation = propertyAccess.target as FunctionExpressionInvocation;
    expect(invocation.function, isNotNull);
    ArgumentList argumentList = invocation.argumentList;
    expect(argumentList, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_expression_dot() {
    PropertyAccess propertyAccess = ParserTestCase.parse("parseAssignableExpression", <Object> [false], "(x).y");
    expect(propertyAccess.target, isNotNull);
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_expression_index() {
    IndexExpression expression = ParserTestCase.parse("parseAssignableExpression", <Object> [false], "(x)[y]");
    expect(expression.target, isNotNull);
    expect(expression.leftBracket, isNotNull);
    expect(expression.index, isNotNull);
    expect(expression.rightBracket, isNotNull);
  }

  void test_parseAssignableExpression_identifier() {
    SimpleIdentifier identifier = ParserTestCase.parse("parseAssignableExpression", <Object> [false], "x");
    expect(identifier, isNotNull);
  }

  void test_parseAssignableExpression_identifier_args_dot() {
    PropertyAccess propertyAccess = ParserTestCase.parse("parseAssignableExpression", <Object> [false], "x(y).z");
    MethodInvocation invocation = propertyAccess.target as MethodInvocation;
    expect(invocation.methodName.name, "x");
    ArgumentList argumentList = invocation.argumentList;
    expect(argumentList, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_identifier_dot() {
    PropertyAccess propertyAccess = ParserTestCase.parse("parseAssignableExpression", <Object> [false], "x.y");
    expect(propertyAccess.target, isNotNull);
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_identifier_index() {
    IndexExpression expression = ParserTestCase.parse("parseAssignableExpression", <Object> [false], "x[y]");
    expect(expression.target, isNotNull);
    expect(expression.leftBracket, isNotNull);
    expect(expression.index, isNotNull);
    expect(expression.rightBracket, isNotNull);
  }

  void test_parseAssignableExpression_super_dot() {
    PropertyAccess propertyAccess = ParserTestCase.parse("parseAssignableExpression", <Object> [false], "super.y");
    EngineTestCase.assertInstanceOf((obj) => obj is SuperExpression, SuperExpression, propertyAccess.target);
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parseAssignableExpression_super_index() {
    IndexExpression expression = ParserTestCase.parse("parseAssignableExpression", <Object> [false], "super[y]");
    EngineTestCase.assertInstanceOf((obj) => obj is SuperExpression, SuperExpression, expression.target);
    expect(expression.leftBracket, isNotNull);
    expect(expression.index, isNotNull);
    expect(expression.rightBracket, isNotNull);
  }

  void test_parseAssignableSelector_dot() {
    PropertyAccess selector = ParserTestCase.parse("parseAssignableSelector", <Object> [null, true], ".x");
    expect(selector.operator, isNotNull);
    expect(selector.propertyName, isNotNull);
  }

  void test_parseAssignableSelector_index() {
    IndexExpression selector = ParserTestCase.parse("parseAssignableSelector", <Object> [null, true], "[x]");
    expect(selector.leftBracket, isNotNull);
    expect(selector.index, isNotNull);
    expect(selector.rightBracket, isNotNull);
  }

  void test_parseAssignableSelector_none() {
    SimpleIdentifier selector = ParserTestCase.parse("parseAssignableSelector", <Object> [new SimpleIdentifier(null), true], ";");
    expect(selector, isNotNull);
  }

  void test_parseAwaitExpression() {
    AwaitExpression expression = ParserTestCase.parse4("parseAwaitExpression", "await x;", []);
    expect(expression.awaitKeyword, isNotNull);
    expect(expression.expression, isNotNull);
  }

  void test_parseAwaitExpression_asStatement_inAsync() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "m() async { await x; }");
    FunctionBody body = method.body;
    EngineTestCase.assertInstanceOf((obj) => obj is BlockFunctionBody, BlockFunctionBody, body);
    Statement statement = (body as BlockFunctionBody).block.statements[0];
    EngineTestCase.assertInstanceOf((obj) => obj is ExpressionStatement, ExpressionStatement, statement);
    Expression expression = (statement as ExpressionStatement).expression;
    EngineTestCase.assertInstanceOf((obj) => obj is AwaitExpression, AwaitExpression, expression);
    expect((expression as AwaitExpression).awaitKeyword, isNotNull);
    expect((expression as AwaitExpression).expression, isNotNull);
  }

  void test_parseAwaitExpression_asStatement_inSync() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "m() { await x; }");
    FunctionBody body = method.body;
    EngineTestCase.assertInstanceOf((obj) => obj is BlockFunctionBody, BlockFunctionBody, body);
    Statement statement = (body as BlockFunctionBody).block.statements[0];
    EngineTestCase.assertInstanceOf((obj) => obj is VariableDeclarationStatement, VariableDeclarationStatement, statement);
  }

  void test_parseAwaitExpression_inSync() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "m() { return await x + await y; }");
    FunctionBody body = method.body;
    EngineTestCase.assertInstanceOf((obj) => obj is BlockFunctionBody, BlockFunctionBody, body);
    Statement statement = (body as BlockFunctionBody).block.statements[0];
    EngineTestCase.assertInstanceOf((obj) => obj is ReturnStatement, ReturnStatement, statement);
    Expression expression = (statement as ReturnStatement).expression;
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression);
    EngineTestCase.assertInstanceOf((obj) => obj is AwaitExpression, AwaitExpression, (expression as BinaryExpression).leftOperand);
    EngineTestCase.assertInstanceOf((obj) => obj is AwaitExpression, AwaitExpression, (expression as BinaryExpression).rightOperand);
  }

  void test_parseBitwiseAndExpression_normal() {
    BinaryExpression expression = ParserTestCase.parse4("parseBitwiseAndExpression", "x & y", []);
    expect(expression.leftOperand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.AMPERSAND);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseBitwiseAndExpression_super() {
    BinaryExpression expression = ParserTestCase.parse4("parseBitwiseAndExpression", "super & y", []);
    EngineTestCase.assertInstanceOf((obj) => obj is SuperExpression, SuperExpression, expression.leftOperand);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.AMPERSAND);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseBitwiseOrExpression_normal() {
    BinaryExpression expression = ParserTestCase.parse4("parseBitwiseOrExpression", "x | y", []);
    expect(expression.leftOperand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.BAR);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseBitwiseOrExpression_super() {
    BinaryExpression expression = ParserTestCase.parse4("parseBitwiseOrExpression", "super | y", []);
    EngineTestCase.assertInstanceOf((obj) => obj is SuperExpression, SuperExpression, expression.leftOperand);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.BAR);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseBitwiseXorExpression_normal() {
    BinaryExpression expression = ParserTestCase.parse4("parseBitwiseXorExpression", "x ^ y", []);
    expect(expression.leftOperand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.CARET);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseBitwiseXorExpression_super() {
    BinaryExpression expression = ParserTestCase.parse4("parseBitwiseXorExpression", "super ^ y", []);
    EngineTestCase.assertInstanceOf((obj) => obj is SuperExpression, SuperExpression, expression.leftOperand);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.CARET);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseBlock_empty() {
    Block block = ParserTestCase.parse4("parseBlock", "{}", []);
    expect(block.leftBracket, isNotNull);
    expect(block.statements, hasLength(0));
    expect(block.rightBracket, isNotNull);
  }

  void test_parseBlock_nonEmpty() {
    Block block = ParserTestCase.parse4("parseBlock", "{;}", []);
    expect(block.leftBracket, isNotNull);
    expect(block.statements, hasLength(1));
    expect(block.rightBracket, isNotNull);
  }

  void test_parseBreakStatement_label() {
    BreakStatement statement = ParserTestCase.parse4("parseBreakStatement", "break foo;", []);
    expect(statement.keyword, isNotNull);
    expect(statement.label, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseBreakStatement_noLabel() {
    BreakStatement statement = ParserTestCase.parse4("parseBreakStatement", "break;", [ParserErrorCode.BREAK_OUTSIDE_OF_LOOP]);
    expect(statement.keyword, isNotNull);
    expect(statement.label, isNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseCascadeSection_i() {
    IndexExpression section = ParserTestCase.parse4("parseCascadeSection", "..[i]", []);
    expect(section.target, isNull);
    expect(section.leftBracket, isNotNull);
    expect(section.index, isNotNull);
    expect(section.rightBracket, isNotNull);
  }

  void test_parseCascadeSection_ia() {
    FunctionExpressionInvocation section = ParserTestCase.parse4("parseCascadeSection", "..[i](b)", []);
    EngineTestCase.assertInstanceOf((obj) => obj is IndexExpression, IndexExpression, section.function);
    expect(section.argumentList, isNotNull);
  }

  void test_parseCascadeSection_ii() {
    MethodInvocation section = ParserTestCase.parse4("parseCascadeSection", "..a(b).c(d)", []);
    EngineTestCase.assertInstanceOf((obj) => obj is MethodInvocation, MethodInvocation, section.target);
    expect(section.period, isNotNull);
    expect(section.methodName, isNotNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_p() {
    PropertyAccess section = ParserTestCase.parse4("parseCascadeSection", "..a", []);
    expect(section.target, isNull);
    expect(section.operator, isNotNull);
    expect(section.propertyName, isNotNull);
  }

  void test_parseCascadeSection_p_assign() {
    AssignmentExpression section = ParserTestCase.parse4("parseCascadeSection", "..a = 3", []);
    expect(section.leftHandSide, isNotNull);
    expect(section.operator, isNotNull);
    Expression rhs = section.rightHandSide;
    expect(rhs, isNotNull);
  }

  void test_parseCascadeSection_p_assign_withCascade() {
    AssignmentExpression section = ParserTestCase.parse4("parseCascadeSection", "..a = 3..m()", []);
    expect(section.leftHandSide, isNotNull);
    expect(section.operator, isNotNull);
    Expression rhs = section.rightHandSide;
    EngineTestCase.assertInstanceOf((obj) => obj is IntegerLiteral, IntegerLiteral, rhs);
  }

  void test_parseCascadeSection_p_builtIn() {
    PropertyAccess section = ParserTestCase.parse4("parseCascadeSection", "..as", []);
    expect(section.target, isNull);
    expect(section.operator, isNotNull);
    expect(section.propertyName, isNotNull);
  }

  void test_parseCascadeSection_pa() {
    MethodInvocation section = ParserTestCase.parse4("parseCascadeSection", "..a(b)", []);
    expect(section.target, isNull);
    expect(section.period, isNotNull);
    expect(section.methodName, isNotNull);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_paa() {
    FunctionExpressionInvocation section = ParserTestCase.parse4("parseCascadeSection", "..a(b)(c)", []);
    EngineTestCase.assertInstanceOf((obj) => obj is MethodInvocation, MethodInvocation, section.function);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_paapaa() {
    FunctionExpressionInvocation section = ParserTestCase.parse4("parseCascadeSection", "..a(b)(c).d(e)(f)", []);
    EngineTestCase.assertInstanceOf((obj) => obj is MethodInvocation, MethodInvocation, section.function);
    expect(section.argumentList, isNotNull);
    expect(section.argumentList.arguments, hasLength(1));
  }

  void test_parseCascadeSection_pap() {
    PropertyAccess section = ParserTestCase.parse4("parseCascadeSection", "..a(b).c", []);
    expect(section.target, isNotNull);
    expect(section.operator, isNotNull);
    expect(section.propertyName, isNotNull);
  }

  void test_parseClassDeclaration_abstract() {
    ClassDeclaration declaration = ParserTestCase.parse("parseClassDeclaration", <Object> [
        emptyCommentAndMetadata(),
        TokenFactory.tokenFromKeyword(Keyword.ABSTRACT)], "class A {}");
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
    ClassDeclaration declaration = ParserTestCase.parse("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class A {}");
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
    ClassDeclaration declaration = ParserTestCase.parse("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class A extends B {}");
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
    ClassDeclaration declaration = ParserTestCase.parse("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class A extends B implements C {}");
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
    ClassDeclaration declaration = ParserTestCase.parse("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class A extends B with C {}");
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
    ClassDeclaration declaration = ParserTestCase.parse("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class A extends B with C implements D {}");
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
    ClassDeclaration declaration = ParserTestCase.parse("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class A implements C {}");
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
    ClassDeclaration declaration = ParserTestCase.parse("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class A native 'nativeValue' {}");
    NativeClause nativeClause = declaration.nativeClause;
    expect(nativeClause, isNotNull);
    expect(nativeClause.keyword, isNotNull);
    expect(nativeClause.name.stringValue, "nativeValue");
    expect(nativeClause.beginToken, same(nativeClause.keyword));
    expect(nativeClause.endToken, same(nativeClause.name.endToken));
  }

  void test_parseClassDeclaration_nonEmpty() {
    ClassDeclaration declaration = ParserTestCase.parse("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class A {var f;}");
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
    ClassTypeAlias typeAlias = ParserTestCase.parse("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class A = Object with B implements C;");
    expect(typeAlias.keyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.withClause, isNotNull);
    expect(typeAlias.implementsClause, isNotNull);
    expect(typeAlias.implementsClause.keyword, isNotNull);
    expect(typeAlias.implementsClause.interfaces.length, 1);
    expect(typeAlias.semicolon, isNotNull);
  }

  void test_parseClassDeclaration_typeAlias_withB() {
    ClassTypeAlias typeAlias = ParserTestCase.parse("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class A = Object with B;");
    expect(typeAlias.keyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.typeParameters, isNull);
    expect(typeAlias.withClause, isNotNull);
    expect(typeAlias.withClause.withKeyword, isNotNull);
    expect(typeAlias.withClause.mixinTypes.length, 1);
    expect(typeAlias.implementsClause, isNull);
    expect(typeAlias.semicolon, isNotNull);
  }

  void test_parseClassDeclaration_typeParameters() {
    ClassDeclaration declaration = ParserTestCase.parse("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class A<B> {}");
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
    // TODO(brianwilkerson) Test other kinds of class members: fields, getters and setters.
    ConstructorDeclaration constructor = ParserTestCase.parse("parseClassMember", <Object> ["C"], "C(_, _\$, this.__) : _a = _ + _\$ {}");
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
    FieldDeclaration field = ParserTestCase.parse("parseClassMember", <Object> ["C"], "p.A f;");
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
    FieldDeclaration field = ParserTestCase.parse("parseClassMember", <Object> ["C"], "var get;");
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
    FieldDeclaration field = ParserTestCase.parse("parseClassMember", <Object> ["C"], "var operator;");
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
    FieldDeclaration field = ParserTestCase.parse("parseClassMember", <Object> ["C"], "var operator = (5);");
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
    FieldDeclaration field = ParserTestCase.parse("parseClassMember", <Object> ["C"], "var set;");
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
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "void get g {}");
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNotNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_external() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "external m();");
    expect(method.body, isNotNull);
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNotNull);
    expect(method.modifierKeyword, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.parameters, isNotNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNull);
  }

  void test_parseClassMember_method_external_withTypeAndArgs() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "external int m(int a);");
    expect(method.body, isNotNull);
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNotNull);
    expect(method.modifierKeyword, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.parameters, isNotNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
  }

  void test_parseClassMember_method_get_noType() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "get() {}");
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_get_type() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "int get() {}");
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_get_void() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "void get() {}");
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_operator_noType() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "operator() {}");
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_operator_type() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "int operator() {}");
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_operator_void() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "void operator() {}");
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_returnType_parameterized() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "p.A m() {}");
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_set_noType() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "set() {}");
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_set_type() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "int set() {}");
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_method_set_void() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "void set() {}");
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_operator_index() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "int operator [](int i) {}");
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNotNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_operator_indexAssign() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "int operator []=(int i) {}");
    expect(method.documentationComment, isNull);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, isNotNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNotNull);
    expect(method.parameters, isNotNull);
    expect(method.body, isNotNull);
  }

  void test_parseClassMember_redirectingFactory_const() {
    ConstructorDeclaration constructor = ParserTestCase.parse("parseClassMember", <Object> ["C"], "const factory C() = B;");
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
    ConstructorDeclaration constructor = ParserTestCase.parse("parseClassMember", <Object> ["C"], "factory C() = B;");
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
    ClassTypeAlias classTypeAlias = ParserTestCase.parse("parseClassTypeAlias", <Object> [emptyCommentAndMetadata(), abstractToken, classToken], "A = B with C;");
    expect(classTypeAlias.keyword, isNotNull);
    expect(classTypeAlias.name.name, "A");
    expect(classTypeAlias.equals, isNotNull);
    expect(classTypeAlias.abstractKeyword, isNotNull);
    expect(classTypeAlias.superclass.name.name, isNotNull, reason: "B");
    expect(classTypeAlias.withClause, isNotNull);
    expect(classTypeAlias.implementsClause, isNull);
    expect(classTypeAlias.semicolon, isNotNull);
  }

  void test_parseClassTypeAlias_implements() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.CLASS);
    ClassTypeAlias classTypeAlias = ParserTestCase.parse("parseClassTypeAlias", <Object> [emptyCommentAndMetadata(), null, token], "A = B with C implements D;");
    expect(classTypeAlias.keyword, isNotNull);
    expect(classTypeAlias.name.name, "A");
    expect(classTypeAlias.equals, isNotNull);
    expect(classTypeAlias.abstractKeyword, isNull);
    expect(classTypeAlias.superclass.name.name, isNotNull, reason: "B");
    expect(classTypeAlias.withClause, isNotNull);
    expect(classTypeAlias.implementsClause, isNotNull);
    expect(classTypeAlias.semicolon, isNotNull);
  }

  void test_parseClassTypeAlias_with() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.CLASS);
    ClassTypeAlias classTypeAlias = ParserTestCase.parse("parseClassTypeAlias", <Object> [emptyCommentAndMetadata(), null, token], "A = B with C;");
    expect(classTypeAlias.keyword, isNotNull);
    expect(classTypeAlias.name.name, "A");
    expect(classTypeAlias.equals, isNotNull);
    expect(classTypeAlias.abstractKeyword, isNull);
    expect(classTypeAlias.superclass.name.name, isNotNull, reason: "B");
    expect(classTypeAlias.withClause, isNotNull);
    expect(classTypeAlias.implementsClause, isNull);
    expect(classTypeAlias.semicolon, isNotNull);
  }

  void test_parseClassTypeAlias_with_implements() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.CLASS);
    ClassTypeAlias classTypeAlias = ParserTestCase.parse("parseClassTypeAlias", <Object> [emptyCommentAndMetadata(), null, token], "A = B with C implements D;");
    expect(classTypeAlias.keyword, isNotNull);
    expect(classTypeAlias.name.name, "A");
    expect(classTypeAlias.equals, isNotNull);
    expect(classTypeAlias.abstractKeyword, isNull);
    expect(classTypeAlias.superclass.name.name, isNotNull, reason: "B");
    expect(classTypeAlias.withClause, isNotNull);
    expect(classTypeAlias.implementsClause, isNotNull);
    expect(classTypeAlias.semicolon, isNotNull);
  }

  void test_parseCombinators_h() {
    List<Combinator> combinators = ParserTestCase.parse4("parseCombinators", "hide a;", []);
    expect(combinators, hasLength(1));
    HideCombinator combinator = combinators[0] as HideCombinator;
    expect(combinator, isNotNull);
    expect(combinator.keyword, isNotNull);
    expect(combinator.hiddenNames, hasLength(1));
  }

  void test_parseCombinators_hs() {
    List<Combinator> combinators = ParserTestCase.parse4("parseCombinators", "hide a show b;", []);
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
    List<Combinator> combinators = ParserTestCase.parse4("parseCombinators", "hide a show b hide c show d;", []);
    expect(combinators, hasLength(4));
  }

  void test_parseCombinators_s() {
    List<Combinator> combinators = ParserTestCase.parse4("parseCombinators", "show a;", []);
    expect(combinators, hasLength(1));
    ShowCombinator combinator = combinators[0] as ShowCombinator;
    expect(combinator, isNotNull);
    expect(combinator.keyword, isNotNull);
    expect(combinator.shownNames, hasLength(1));
  }

  void test_parseCommentAndMetadata_c() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse4("parseCommentAndMetadata", "/** 1 */ void", []);
    expect(commentAndMetadata.comment, isNotNull);
    expect(commentAndMetadata.metadata, hasLength(0));
  }

  void test_parseCommentAndMetadata_cmc() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse4("parseCommentAndMetadata", "/** 1 */ @A /** 2 */ void", []);
    expect(commentAndMetadata.comment, isNotNull);
    expect(commentAndMetadata.metadata, hasLength(1));
  }

  void test_parseCommentAndMetadata_cmcm() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse4("parseCommentAndMetadata", "/** 1 */ @A /** 2 */ @B void", []);
    expect(commentAndMetadata.comment, isNotNull);
    expect(commentAndMetadata.metadata, hasLength(2));
  }

  void test_parseCommentAndMetadata_cmm() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse4("parseCommentAndMetadata", "/** 1 */ @A @B void", []);
    expect(commentAndMetadata.comment, isNotNull);
    expect(commentAndMetadata.metadata, hasLength(2));
  }

  void test_parseCommentAndMetadata_m() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse4("parseCommentAndMetadata", "@A void", []);
    expect(commentAndMetadata.comment, isNull);
    expect(commentAndMetadata.metadata, hasLength(1));
  }

  void test_parseCommentAndMetadata_mcm() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse4("parseCommentAndMetadata", "@A /** 1 */ @B void", []);
    expect(commentAndMetadata.comment, isNotNull);
    expect(commentAndMetadata.metadata, hasLength(2));
  }

  void test_parseCommentAndMetadata_mcmc() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse4("parseCommentAndMetadata", "@A /** 1 */ @B /** 2 */ void", []);
    expect(commentAndMetadata.comment, isNotNull);
    expect(commentAndMetadata.metadata, hasLength(2));
  }

  void test_parseCommentAndMetadata_mm() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse4("parseCommentAndMetadata", "@A @B(x) void", []);
    expect(commentAndMetadata.comment, isNull);
    expect(commentAndMetadata.metadata, hasLength(2));
  }

  void test_parseCommentAndMetadata_none() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse4("parseCommentAndMetadata", "void", []);
    expect(commentAndMetadata.comment, isNull);
    expect(commentAndMetadata.metadata, hasLength(0));
  }

  void test_parseCommentAndMetadata_singleLine() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse4("parseCommentAndMetadata", r'''
/// 1
/// 2
void''', []);
    expect(commentAndMetadata.comment, isNotNull);
    expect(commentAndMetadata.metadata, hasLength(0));
  }

  void test_parseCommentReference_new_prefixed() {
    CommentReference reference = ParserTestCase.parse("parseCommentReference", <Object> ["new a.b", 7], "");
    PrefixedIdentifier prefixedIdentifier = EngineTestCase.assertInstanceOf((obj) => obj is PrefixedIdentifier, PrefixedIdentifier, reference.identifier);
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
    CommentReference reference = ParserTestCase.parse("parseCommentReference", <Object> ["new a", 5], "");
    SimpleIdentifier identifier = EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, reference.identifier);
    expect(identifier.token, isNotNull);
    expect(identifier.name, "a");
    expect(identifier.offset, 9);
  }

  void test_parseCommentReference_prefixed() {
    CommentReference reference = ParserTestCase.parse("parseCommentReference", <Object> ["a.b", 7], "");
    PrefixedIdentifier prefixedIdentifier = EngineTestCase.assertInstanceOf((obj) => obj is PrefixedIdentifier, PrefixedIdentifier, reference.identifier);
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
    CommentReference reference = ParserTestCase.parse("parseCommentReference", <Object> ["a", 5], "");
    SimpleIdentifier identifier = EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, reference.identifier);
    expect(identifier.token, isNotNull);
    expect(identifier.name, "a");
    expect(identifier.offset, 5);
  }

  void test_parseCommentReference_synthetic() {
    CommentReference reference = ParserTestCase.parse("parseCommentReference", <Object> ["", 5], "");
    SimpleIdentifier identifier = EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, reference.identifier);
    expect(identifier, isNotNull);
    expect(identifier.isSynthetic, isTrue);
    expect(identifier.token, isNotNull);
    expect(identifier.name, "");
    expect(identifier.offset, 5);
  }

  void test_parseCommentReferences_multiLine() {
    List<Token> tokens = <Token> [new StringToken(TokenType.MULTI_LINE_COMMENT, "/** xxx [a] yyy [b] zzz */", 3)];
    List<CommentReference> references = ParserTestCase.parse("parseCommentReferences", <Object> [tokens], "");
    expect(references, hasLength(2));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 12);
    reference = references[1];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 20);
  }

  void test_parseCommentReferences_notClosed_noIdentifier() {
    List<Token> tokens = <Token> [new StringToken(TokenType.MULTI_LINE_COMMENT, "/** [ some text", 5)];
    List<CommentReference> references = ParserTestCase.parse("parseCommentReferences", <Object> [tokens], "");
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.identifier.isSynthetic, isTrue);
    expect(reference.identifier.name, "");
  }

  void test_parseCommentReferences_notClosed_withIdentifier() {
    List<Token> tokens = <Token> [new StringToken(TokenType.MULTI_LINE_COMMENT, "/** [namePrefix some text", 5)];
    List<CommentReference> references = ParserTestCase.parse("parseCommentReferences", <Object> [tokens], "");
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.identifier.isSynthetic, isFalse);
    expect(reference.identifier.name, "namePrefix");
  }

  void test_parseCommentReferences_singleLine() {
    List<Token> tokens = <Token> [
        new StringToken(TokenType.SINGLE_LINE_COMMENT, "/// xxx [a] yyy [b] zzz", 3),
        new StringToken(TokenType.SINGLE_LINE_COMMENT, "/// x [c]", 28)];
    List<CommentReference> references = ParserTestCase.parse("parseCommentReferences", <Object> [tokens], "");
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

  void test_parseCommentReferences_skipCodeBlock_bracketed() {
    List<Token> tokens = <Token> [new StringToken(TokenType.MULTI_LINE_COMMENT, "/** [:xxx [a] yyy:] [b] zzz */", 3)];
    List<CommentReference> references = ParserTestCase.parse("parseCommentReferences", <Object> [tokens], "");
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 24);
  }

  void test_parseCommentReferences_skipCodeBlock_spaces() {
    List<Token> tokens = <Token> [new StringToken(TokenType.MULTI_LINE_COMMENT, "/**\n *     a[i]\n * xxx [i] zzz\n */", 3)];
    List<CommentReference> references = ParserTestCase.parse("parseCommentReferences", <Object> [tokens], "");
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 27);
  }

  void test_parseCommentReferences_skipLinkDefinition() {
    List<Token> tokens = <Token> [new StringToken(TokenType.MULTI_LINE_COMMENT, "/** [a]: http://www.google.com (Google) [b] zzz */", 3)];
    List<CommentReference> references = ParserTestCase.parse("parseCommentReferences", <Object> [tokens], "");
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 44);
  }

  void test_parseCommentReferences_skipLinked() {
    List<Token> tokens = <Token> [new StringToken(TokenType.MULTI_LINE_COMMENT, "/** [a](http://www.google.com) [b] zzz */", 3)];
    List<CommentReference> references = ParserTestCase.parse("parseCommentReferences", <Object> [tokens], "");
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 35);
  }

  void test_parseCommentReferences_skipReferenceLink() {
    List<Token> tokens = <Token> [new StringToken(TokenType.MULTI_LINE_COMMENT, "/** [a][c] [b] zzz */", 3)];
    List<CommentReference> references = ParserTestCase.parse("parseCommentReferences", <Object> [tokens], "");
    expect(references, hasLength(1));
    CommentReference reference = references[0];
    expect(reference, isNotNull);
    expect(reference.identifier, isNotNull);
    expect(reference.offset, 15);
  }

  void test_parseCompilationUnit_abstractAsPrefix_parameterized() {
    CompilationUnit unit = ParserTestCase.parse4("parseCompilationUnit", "abstract<dynamic> _abstract = new abstract.A();", []);
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnit_builtIn_asFunctionName() {
    ParserTestCase.parse4("parseCompilationUnit", "abstract(x) => 0;", []);
    ParserTestCase.parse4("parseCompilationUnit", "as(x) => 0;", []);
    ParserTestCase.parse4("parseCompilationUnit", "dynamic(x) => 0;", []);
    ParserTestCase.parse4("parseCompilationUnit", "export(x) => 0;", []);
    ParserTestCase.parse4("parseCompilationUnit", "external(x) => 0;", []);
    ParserTestCase.parse4("parseCompilationUnit", "factory(x) => 0;", []);
    ParserTestCase.parse4("parseCompilationUnit", "get(x) => 0;", []);
    ParserTestCase.parse4("parseCompilationUnit", "implements(x) => 0;", []);
    ParserTestCase.parse4("parseCompilationUnit", "import(x) => 0;", []);
    ParserTestCase.parse4("parseCompilationUnit", "library(x) => 0;", []);
    ParserTestCase.parse4("parseCompilationUnit", "operator(x) => 0;", []);
    ParserTestCase.parse4("parseCompilationUnit", "part(x) => 0;", []);
    ParserTestCase.parse4("parseCompilationUnit", "set(x) => 0;", []);
    ParserTestCase.parse4("parseCompilationUnit", "static(x) => 0;", []);
    ParserTestCase.parse4("parseCompilationUnit", "typedef(x) => 0;", []);
  }

  void test_parseCompilationUnit_directives_multiple() {
    CompilationUnit unit = ParserTestCase.parse4("parseCompilationUnit", "library l;\npart 'a.dart';", []);
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(2));
    expect(unit.declarations, hasLength(0));
  }

  void test_parseCompilationUnit_directives_single() {
    CompilationUnit unit = ParserTestCase.parse4("parseCompilationUnit", "library l;", []);
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(1));
    expect(unit.declarations, hasLength(0));
  }

  void test_parseCompilationUnit_empty() {
    CompilationUnit unit = ParserTestCase.parse4("parseCompilationUnit", "", []);
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(0));
  }

  void test_parseCompilationUnit_exportAsPrefix() {
    CompilationUnit unit = ParserTestCase.parse4("parseCompilationUnit", "export.A _export = new export.A();", []);
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnit_exportAsPrefix_parameterized() {
    CompilationUnit unit = ParserTestCase.parse4("parseCompilationUnit", "export<dynamic> _export = new export.A();", []);
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnit_operatorAsPrefix_parameterized() {
    CompilationUnit unit = ParserTestCase.parse4("parseCompilationUnit", "operator<dynamic> _operator = new operator.A();", []);
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnit_script() {
    CompilationUnit unit = ParserTestCase.parse4("parseCompilationUnit", "#! /bin/dart", []);
    expect(unit.scriptTag, isNotNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(0));
  }

  void test_parseCompilationUnit_skipFunctionBody_withInterpolation() {
    ParserTestCase.parseFunctionBodies = false;
    CompilationUnit unit = ParserTestCase.parse4("parseCompilationUnit", "f() { '\${n}'; }", []);
    expect(unit.scriptTag, isNull);
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnit_topLevelDeclaration() {
    CompilationUnit unit = ParserTestCase.parse4("parseCompilationUnit", "class A {}", []);
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnit_typedefAsPrefix() {
    CompilationUnit unit = ParserTestCase.parse4("parseCompilationUnit", "typedef.A _typedef = new typedef.A();", []);
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
    expect(unit.declarations, hasLength(1));
  }

  void test_parseCompilationUnitMember_abstractAsPrefix() {
    TopLevelVariableDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "abstract.A _abstract = new abstract.A();");
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
  }

  void test_parseCompilationUnitMember_class() {
    ClassDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "class A {}");
    expect(declaration.name.name, "A");
    expect(declaration.members, hasLength(0));
  }

  void test_parseCompilationUnitMember_classTypeAlias() {
    ClassTypeAlias alias = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "abstract class A = B with C;");
    expect(alias.name.name, "A");
    expect(alias.abstractKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_constVariable() {
    TopLevelVariableDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "const int x = 0;");
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
  }

  void test_parseCompilationUnitMember_finalVariable() {
    TopLevelVariableDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "final x = 0;");
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
  }

  void test_parseCompilationUnitMember_function_external_noType() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "external f();");
    expect(declaration.externalKeyword, isNotNull);
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseCompilationUnitMember_function_external_type() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "external int f();");
    expect(declaration.externalKeyword, isNotNull);
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseCompilationUnitMember_function_noType() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "f() {}");
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseCompilationUnitMember_function_type() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "int f() {}");
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseCompilationUnitMember_function_void() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "void f() {}");
    expect(declaration.returnType, isNotNull);
  }

  void test_parseCompilationUnitMember_getter_external_noType() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "external get p;");
    expect(declaration.externalKeyword, isNotNull);
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_getter_external_type() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "external int get p;");
    expect(declaration.externalKeyword, isNotNull);
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_getter_noType() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "get p => 0;");
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_getter_type() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "int get p => 0;");
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_setter_external_noType() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "external set p(v);");
    expect(declaration.externalKeyword, isNotNull);
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_setter_external_type() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "external void set p(int v);");
    expect(declaration.externalKeyword, isNotNull);
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_setter_noType() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "set p(v) {}");
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseCompilationUnitMember_setter_type() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "void set p(int v) {}");
    expect(declaration.functionExpression, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
    expect(declaration.returnType, isNotNull);
  }

  void test_parseCompilationUnitMember_typeAlias_abstract() {
    ClassTypeAlias typeAlias = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "abstract class C = S with M;");
    expect(typeAlias.keyword, isNotNull);
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
    ClassTypeAlias typeAlias = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "class C<E> = S<E> with M<E> implements I<E>;");
    expect(typeAlias.keyword, isNotNull);
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
    ClassTypeAlias typeAlias = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "class C = S with M implements I;");
    expect(typeAlias.keyword, isNotNull);
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
    ClassTypeAlias typeAlias = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "class C = S with M;");
    expect(typeAlias.keyword, isNotNull);
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
    FunctionTypeAlias typeAlias = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "typedef F();");
    expect(typeAlias.name.name, "F");
    expect(typeAlias.parameters.parameters, hasLength(0));
  }

  void test_parseCompilationUnitMember_variable() {
    TopLevelVariableDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "var x = 0;");
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
  }

  void test_parseCompilationUnitMember_variableGet() {
    TopLevelVariableDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "String get = null;");
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
  }

  void test_parseCompilationUnitMember_variableSet() {
    TopLevelVariableDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "String set = null;");
    expect(declaration.semicolon, isNotNull);
    expect(declaration.variables, isNotNull);
  }

  void test_parseConditionalExpression() {
    ConditionalExpression expression = ParserTestCase.parse4("parseConditionalExpression", "x ? y : z", []);
    expect(expression.condition, isNotNull);
    expect(expression.question, isNotNull);
    expect(expression.thenExpression, isNotNull);
    expect(expression.colon, isNotNull);
    expect(expression.elseExpression, isNotNull);
  }

  void test_parseConstExpression_instanceCreation() {
    InstanceCreationExpression expression = ParserTestCase.parse4("parseConstExpression", "const A()", []);
    expect(expression.keyword, isNotNull);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    expect(name.type, isNotNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseConstExpression_listLiteral_typed() {
    ListLiteral literal = ParserTestCase.parse4("parseConstExpression", "const <A> []", []);
    expect(literal.constKeyword, isNotNull);
    expect(literal.typeArguments, isNotNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseConstExpression_listLiteral_untyped() {
    ListLiteral literal = ParserTestCase.parse4("parseConstExpression", "const []", []);
    expect(literal.constKeyword, isNotNull);
    expect(literal.typeArguments, isNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseConstExpression_mapLiteral_typed() {
    MapLiteral literal = ParserTestCase.parse4("parseConstExpression", "const <A, B> {}", []);
    expect(literal.leftBracket, isNotNull);
    expect(literal.entries, hasLength(0));
    expect(literal.rightBracket, isNotNull);
    expect(literal.typeArguments, isNotNull);
  }

  void test_parseConstExpression_mapLiteral_untyped() {
    MapLiteral literal = ParserTestCase.parse4("parseConstExpression", "const {}", []);
    expect(literal.leftBracket, isNotNull);
    expect(literal.entries, hasLength(0));
    expect(literal.rightBracket, isNotNull);
    expect(literal.typeArguments, isNull);
  }

  void test_parseConstructor() {
    // TODO(brianwilkerson) Implement tests for this method.
    //    parse("parseConstructor", new Class[] {Parser.CommentAndMetadata.class,
    //        Token.class, Token.class, SimpleIdentifier.class, Token.class,
    //        SimpleIdentifier.class, FormalParameterList.class}, new Object[] {emptyCommentAndMetadata(),
    //        null, null, null, null, null, null}, "");
  }

  void test_parseConstructor_with_pseudo_function_literal() {
    // "(b) {}" should not be misinterpreted as a function literal even though it looks like one.
    ClassMember classMember = ParserTestCase.parse("parseClassMember", <Object> ["C"], "C() : a = (b) {}");
    EngineTestCase.assertInstanceOf((obj) => obj is ConstructorDeclaration, ConstructorDeclaration, classMember);
    ConstructorDeclaration constructor = classMember as ConstructorDeclaration;
    NodeList<ConstructorInitializer> initializers = constructor.initializers;
    expect(initializers, hasLength(1));
    ConstructorInitializer initializer = initializers[0];
    EngineTestCase.assertInstanceOf((obj) => obj is ConstructorFieldInitializer, ConstructorFieldInitializer, initializer);
    EngineTestCase.assertInstanceOf((obj) => obj is ParenthesizedExpression, ParenthesizedExpression, (initializer as ConstructorFieldInitializer).expression);
    EngineTestCase.assertInstanceOf((obj) => obj is BlockFunctionBody, BlockFunctionBody, constructor.body);
  }

  void test_parseConstructorFieldInitializer_qualified() {
    ConstructorFieldInitializer invocation = ParserTestCase.parse4("parseConstructorFieldInitializer", "this.a = b", []);
    expect(invocation.equals, isNotNull);
    expect(invocation.expression, isNotNull);
    expect(invocation.fieldName, isNotNull);
    expect(invocation.keyword, isNotNull);
    expect(invocation.period, isNotNull);
  }

  void test_parseConstructorFieldInitializer_unqualified() {
    ConstructorFieldInitializer invocation = ParserTestCase.parse4("parseConstructorFieldInitializer", "a = b", []);
    expect(invocation.equals, isNotNull);
    expect(invocation.expression, isNotNull);
    expect(invocation.fieldName, isNotNull);
    expect(invocation.keyword, isNull);
    expect(invocation.period, isNull);
  }

  void test_parseConstructorName_named_noPrefix() {
    ConstructorName name = ParserTestCase.parse4("parseConstructorName", "A.n;", []);
    expect(name.type, isNotNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
  }

  void test_parseConstructorName_named_prefixed() {
    ConstructorName name = ParserTestCase.parse4("parseConstructorName", "p.A.n;", []);
    expect(name.type, isNotNull);
    expect(name.period, isNotNull);
    expect(name.name, isNotNull);
  }

  void test_parseConstructorName_unnamed_noPrefix() {
    ConstructorName name = ParserTestCase.parse4("parseConstructorName", "A;", []);
    expect(name.type, isNotNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
  }

  void test_parseConstructorName_unnamed_prefixed() {
    ConstructorName name = ParserTestCase.parse4("parseConstructorName", "p.A;", []);
    expect(name.type, isNotNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
  }

  void test_parseContinueStatement_label() {
    ContinueStatement statement = ParserTestCase.parse4("parseContinueStatement", "continue foo;", [ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP]);
    expect(statement.keyword, isNotNull);
    expect(statement.label, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseContinueStatement_noLabel() {
    ContinueStatement statement = ParserTestCase.parse4("parseContinueStatement", "continue;", [ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP]);
    expect(statement.keyword, isNotNull);
    expect(statement.label, isNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseDirective_export() {
    ExportDirective directive = ParserTestCase.parse("parseDirective", <Object> [emptyCommentAndMetadata()], "export 'lib/lib.dart';");
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseDirective_import() {
    ImportDirective directive = ParserTestCase.parse("parseDirective", <Object> [emptyCommentAndMetadata()], "import 'lib/lib.dart';");
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.asToken, isNull);
    expect(directive.prefix, isNull);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseDirective_library() {
    LibraryDirective directive = ParserTestCase.parse("parseDirective", <Object> [emptyCommentAndMetadata()], "library l;");
    expect(directive.libraryToken, isNotNull);
    expect(directive.name, isNotNull);
    expect(directive.semicolon, isNotNull);
  }

  void test_parseDirective_part() {
    PartDirective directive = ParserTestCase.parse("parseDirective", <Object> [emptyCommentAndMetadata()], "part 'lib/lib.dart';");
    expect(directive.partToken, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.semicolon, isNotNull);
  }

  void test_parseDirective_partOf() {
    PartOfDirective directive = ParserTestCase.parse("parseDirective", <Object> [emptyCommentAndMetadata()], "part of l;");
    expect(directive.partToken, isNotNull);
    expect(directive.ofToken, isNotNull);
    expect(directive.libraryName, isNotNull);
    expect(directive.semicolon, isNotNull);
  }

  void test_parseDirectives_complete() {
    CompilationUnit unit = _parseDirectives("#! /bin/dart\nlibrary l;\nclass A {}", []);
    expect(unit.scriptTag, isNotNull);
    expect(unit.directives, hasLength(1));
  }

  void test_parseDirectives_empty() {
    CompilationUnit unit = _parseDirectives("", []);
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
  }

  void test_parseDirectives_mixed() {
    CompilationUnit unit = _parseDirectives("library l; class A {} part 'foo.dart';", []);
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(1));
  }

  void test_parseDirectives_multiple() {
    CompilationUnit unit = _parseDirectives("library l;\npart 'a.dart';", []);
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(2));
  }

  void test_parseDirectives_script() {
    CompilationUnit unit = _parseDirectives("#! /bin/dart", []);
    expect(unit.scriptTag, isNotNull);
    expect(unit.directives, hasLength(0));
  }

  void test_parseDirectives_single() {
    CompilationUnit unit = _parseDirectives("library l;", []);
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(1));
  }

  void test_parseDirectives_topLevelDeclaration() {
    CompilationUnit unit = _parseDirectives("class A {}", []);
    expect(unit.scriptTag, isNull);
    expect(unit.directives, hasLength(0));
  }

  void test_parseDocumentationComment_block() {
    Comment comment = ParserTestCase.parse4("parseDocumentationComment", "/** */ class", []);
    expect(comment.isBlock, isFalse);
    expect(comment.isDocumentation, isTrue);
    expect(comment.isEndOfLine, isFalse);
  }

  void test_parseDocumentationComment_block_withReference() {
    Comment comment = ParserTestCase.parse4("parseDocumentationComment", "/** [a] */ class", []);
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
    Comment comment = ParserTestCase.parse4("parseDocumentationComment", "/// \n/// \n class", []);
    expect(comment.isBlock, isFalse);
    expect(comment.isDocumentation, isTrue);
    expect(comment.isEndOfLine, isFalse);
  }

  void test_parseDoStatement() {
    DoStatement statement = ParserTestCase.parse4("parseDoStatement", "do {} while (x);", []);
    expect(statement.doKeyword, isNotNull);
    expect(statement.body, isNotNull);
    expect(statement.whileKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseEmptyStatement() {
    EmptyStatement statement = ParserTestCase.parse4("parseEmptyStatement", ";", []);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseEnumDeclaration_one() {
    EnumDeclaration declaration = ParserTestCase.parse("parseEnumDeclaration", <Object> [emptyCommentAndMetadata()], "enum E {ONE}");
    expect(declaration.documentationComment, isNull);
    expect(declaration.keyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.constants, hasLength(1));
    expect(declaration.rightBracket, isNotNull);
  }

  void test_parseEnumDeclaration_trailingComma() {
    EnumDeclaration declaration = ParserTestCase.parse("parseEnumDeclaration", <Object> [emptyCommentAndMetadata()], "enum E {ONE,}");
    expect(declaration.documentationComment, isNull);
    expect(declaration.keyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.constants, hasLength(1));
    expect(declaration.rightBracket, isNotNull);
  }

  void test_parseEnumDeclaration_two() {
    EnumDeclaration declaration = ParserTestCase.parse("parseEnumDeclaration", <Object> [emptyCommentAndMetadata()], "enum E {ONE, TWO}");
    expect(declaration.documentationComment, isNull);
    expect(declaration.keyword, isNotNull);
    expect(declaration.leftBracket, isNotNull);
    expect(declaration.name, isNotNull);
    expect(declaration.constants, hasLength(2));
    expect(declaration.rightBracket, isNotNull);
  }

  void test_parseEqualityExpression_normal() {
    BinaryExpression expression = ParserTestCase.parse4("parseEqualityExpression", "x == y", []);
    expect(expression.leftOperand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.EQ_EQ);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseEqualityExpression_super() {
    BinaryExpression expression = ParserTestCase.parse4("parseEqualityExpression", "super == y", []);
    EngineTestCase.assertInstanceOf((obj) => obj is SuperExpression, SuperExpression, expression.leftOperand);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.EQ_EQ);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseExportDirective_hide() {
    ExportDirective directive = ParserTestCase.parse("parseExportDirective", <Object> [emptyCommentAndMetadata()], "export 'lib/lib.dart' hide A, B;");
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.combinators, hasLength(1));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseExportDirective_hide_show() {
    ExportDirective directive = ParserTestCase.parse("parseExportDirective", <Object> [emptyCommentAndMetadata()], "export 'lib/lib.dart' hide A show B;");
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.combinators, hasLength(2));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseExportDirective_noCombinator() {
    ExportDirective directive = ParserTestCase.parse("parseExportDirective", <Object> [emptyCommentAndMetadata()], "export 'lib/lib.dart';");
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseExportDirective_show() {
    ExportDirective directive = ParserTestCase.parse("parseExportDirective", <Object> [emptyCommentAndMetadata()], "export 'lib/lib.dart' show A, B;");
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.combinators, hasLength(1));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseExportDirective_show_hide() {
    ExportDirective directive = ParserTestCase.parse("parseExportDirective", <Object> [emptyCommentAndMetadata()], "export 'lib/lib.dart' show B hide A;");
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.combinators, hasLength(2));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseExpression_assign() {
    // TODO(brianwilkerson) Implement more tests for this method.
    AssignmentExpression expression = ParserTestCase.parse4("parseExpression", "x = y", []);
    expect(expression.leftHandSide, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.EQ);
    expect(expression.rightHandSide, isNotNull);
  }

  void test_parseExpression_comparison() {
    BinaryExpression expression = ParserTestCase.parse4("parseExpression", "--a.b == c", []);
    expect(expression.leftOperand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.EQ_EQ);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseExpression_function_async() {
    FunctionExpression expression = ParserTestCase.parseExpression("() async {}", []);
    expect(expression.body, isNotNull);
    expect(expression.body.isAsynchronous, isTrue);
    expect(expression.body.isGenerator, isFalse);
    expect(expression.parameters, isNotNull);
  }

  void test_parseExpression_function_asyncStar() {
    FunctionExpression expression = ParserTestCase.parseExpression("() async* {}", []);
    expect(expression.body, isNotNull);
    expect(expression.body.isAsynchronous, isTrue);
    expect(expression.body.isGenerator, isTrue);
    expect(expression.parameters, isNotNull);
  }

  void test_parseExpression_function_sync() {
    FunctionExpression expression = ParserTestCase.parseExpression("() {}", []);
    expect(expression.body, isNotNull);
    expect(expression.body.isAsynchronous, isFalse);
    expect(expression.body.isGenerator, isFalse);
    expect(expression.parameters, isNotNull);
  }

  void test_parseExpression_function_syncStar() {
    FunctionExpression expression = ParserTestCase.parseExpression("() sync* {}", []);
    expect(expression.body, isNotNull);
    expect(expression.body.isAsynchronous, isFalse);
    expect(expression.body.isGenerator, isTrue);
    expect(expression.parameters, isNotNull);
  }

  void test_parseExpression_invokeFunctionExpression() {
    FunctionExpressionInvocation invocation = ParserTestCase.parse4("parseExpression", "(a) {return a + a;} (3)", []);
    EngineTestCase.assertInstanceOf((obj) => obj is FunctionExpression, FunctionExpression, invocation.function);
    FunctionExpression expression = invocation.function as FunctionExpression;
    expect(expression.parameters, isNotNull);
    expect(expression.body, isNotNull);
    ArgumentList list = invocation.argumentList;
    expect(list, isNotNull);
    expect(list.arguments, hasLength(1));
  }

  void test_parseExpression_superMethodInvocation() {
    MethodInvocation invocation = ParserTestCase.parse4("parseExpression", "super.m()", []);
    expect(invocation.target, isNotNull);
    expect(invocation.methodName, isNotNull);
    expect(invocation.argumentList, isNotNull);
  }

  void test_parseExpressionList_multiple() {
    List<Expression> result = ParserTestCase.parse4("parseExpressionList", "1, 2, 3", []);
    expect(result, hasLength(3));
  }

  void test_parseExpressionList_single() {
    List<Expression> result = ParserTestCase.parse4("parseExpressionList", "1", []);
    expect(result, hasLength(1));
  }

  void test_parseExpressionWithoutCascade_assign() {
    // TODO(brianwilkerson) Implement more tests for this method.
    AssignmentExpression expression = ParserTestCase.parse4("parseExpressionWithoutCascade", "x = y", []);
    expect(expression.leftHandSide, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.EQ);
    expect(expression.rightHandSide, isNotNull);
  }

  void test_parseExpressionWithoutCascade_comparison() {
    BinaryExpression expression = ParserTestCase.parse4("parseExpressionWithoutCascade", "--a.b == c", []);
    expect(expression.leftOperand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.EQ_EQ);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseExpressionWithoutCascade_superMethodInvocation() {
    MethodInvocation invocation = ParserTestCase.parse4("parseExpressionWithoutCascade", "super.m()", []);
    expect(invocation.target, isNotNull);
    expect(invocation.methodName, isNotNull);
    expect(invocation.argumentList, isNotNull);
  }

  void test_parseExtendsClause() {
    ExtendsClause clause = ParserTestCase.parse4("parseExtendsClause", "extends B", []);
    expect(clause.keyword, isNotNull);
    expect(clause.superclass, isNotNull);
    EngineTestCase.assertInstanceOf((obj) => obj is TypeName, TypeName, clause.superclass);
  }

  void test_parseFinalConstVarOrType_const_noType() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "const");
    Token keyword = result.keyword;
    expect(keyword, isNotNull);
    expect(keyword.type, TokenType.KEYWORD);
    expect((keyword as KeywordToken).keyword, Keyword.CONST);
    expect(result.type, isNull);
  }

  void test_parseFinalConstVarOrType_const_type() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "const A a");
    Token keyword = result.keyword;
    expect(keyword, isNotNull);
    expect(keyword.type, TokenType.KEYWORD);
    expect((keyword as KeywordToken).keyword, Keyword.CONST);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_final_noType() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "final");
    Token keyword = result.keyword;
    expect(keyword, isNotNull);
    expect(keyword.type, TokenType.KEYWORD);
    expect((keyword as KeywordToken).keyword, Keyword.FINAL);
    expect(result.type, isNull);
  }

  void test_parseFinalConstVarOrType_final_prefixedType() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "final p.A a");
    Token keyword = result.keyword;
    expect(keyword, isNotNull);
    expect(keyword.type, TokenType.KEYWORD);
    expect((keyword as KeywordToken).keyword, Keyword.FINAL);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_final_type() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "final A a");
    Token keyword = result.keyword;
    expect(keyword, isNotNull);
    expect(keyword.type, TokenType.KEYWORD);
    expect((keyword as KeywordToken).keyword, Keyword.FINAL);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_type_parameterized() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "A<B> a");
    expect(result.keyword, isNull);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_type_prefixed() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "p.A a");
    expect(result.keyword, isNull);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_type_prefixed_noIdentifier() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "p.A,");
    expect(result.keyword, isNull);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_type_prefixedAndParameterized() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "p.A<B> a");
    expect(result.keyword, isNull);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_type_simple() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "A a");
    expect(result.keyword, isNull);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_var() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "var");
    Token keyword = result.keyword;
    expect(keyword, isNotNull);
    expect(keyword.type, TokenType.KEYWORD);
    expect((keyword as KeywordToken).keyword, Keyword.VAR);
    expect(result.type, isNull);
  }

  void test_parseFinalConstVarOrType_void() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "void f()");
    expect(result.keyword, isNull);
    expect(result.type, isNotNull);
  }

  void test_parseFinalConstVarOrType_void_noIdentifier() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "void,");
    expect(result.keyword, isNull);
    expect(result.type, isNotNull);
  }

  void test_parseFormalParameter_final_withType_named() {
    ParameterKind kind = ParameterKind.NAMED;
    DefaultFormalParameter parameter = ParserTestCase.parse("parseFormalParameter", <Object> [kind], "final A a : null");
    SimpleFormalParameter simpleParameter = parameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.kind, kind);
    expect(parameter.separator, isNotNull);
    expect(parameter.defaultValue, isNotNull);
    expect(parameter.kind, kind);
  }

  void test_parseFormalParameter_final_withType_normal() {
    ParameterKind kind = ParameterKind.REQUIRED;
    SimpleFormalParameter parameter = ParserTestCase.parse("parseFormalParameter", <Object> [kind], "final A a");
    expect(parameter.identifier, isNotNull);
    expect(parameter.keyword, isNotNull);
    expect(parameter.type, isNotNull);
    expect(parameter.kind, kind);
  }

  void test_parseFormalParameter_final_withType_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    DefaultFormalParameter parameter = ParserTestCase.parse("parseFormalParameter", <Object> [kind], "final A a = null");
    SimpleFormalParameter simpleParameter = parameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.kind, kind);
    expect(parameter.separator, isNotNull);
    expect(parameter.defaultValue, isNotNull);
    expect(parameter.kind, kind);
  }

  void test_parseFormalParameter_nonFinal_withType_named() {
    ParameterKind kind = ParameterKind.NAMED;
    DefaultFormalParameter parameter = ParserTestCase.parse("parseFormalParameter", <Object> [kind], "A a : null");
    SimpleFormalParameter simpleParameter = parameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.kind, kind);
    expect(parameter.separator, isNotNull);
    expect(parameter.defaultValue, isNotNull);
    expect(parameter.kind, kind);
  }

  void test_parseFormalParameter_nonFinal_withType_normal() {
    ParameterKind kind = ParameterKind.REQUIRED;
    SimpleFormalParameter parameter = ParserTestCase.parse("parseFormalParameter", <Object> [kind], "A a");
    expect(parameter.identifier, isNotNull);
    expect(parameter.keyword, isNull);
    expect(parameter.type, isNotNull);
    expect(parameter.kind, kind);
  }

  void test_parseFormalParameter_nonFinal_withType_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    DefaultFormalParameter parameter = ParserTestCase.parse("parseFormalParameter", <Object> [kind], "A a = null");
    SimpleFormalParameter simpleParameter = parameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNull);
    expect(simpleParameter.type, isNotNull);
    expect(simpleParameter.kind, kind);
    expect(parameter.separator, isNotNull);
    expect(parameter.defaultValue, isNotNull);
    expect(parameter.kind, kind);
  }

  void test_parseFormalParameter_var() {
    ParameterKind kind = ParameterKind.REQUIRED;
    SimpleFormalParameter parameter = ParserTestCase.parse("parseFormalParameter", <Object> [kind], "var a");
    expect(parameter.identifier, isNotNull);
    expect(parameter.keyword, isNotNull);
    expect(parameter.type, isNull);
    expect(parameter.kind, kind);
  }

  void test_parseFormalParameter_var_named() {
    ParameterKind kind = ParameterKind.NAMED;
    DefaultFormalParameter parameter = ParserTestCase.parse("parseFormalParameter", <Object> [kind], "var a : null");
    SimpleFormalParameter simpleParameter = parameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.kind, kind);
    expect(parameter.separator, isNotNull);
    expect(parameter.defaultValue, isNotNull);
    expect(parameter.kind, kind);
  }

  void test_parseFormalParameter_var_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    DefaultFormalParameter parameter = ParserTestCase.parse("parseFormalParameter", <Object> [kind], "var a = null");
    SimpleFormalParameter simpleParameter = parameter.parameter as SimpleFormalParameter;
    expect(simpleParameter.identifier, isNotNull);
    expect(simpleParameter.keyword, isNotNull);
    expect(simpleParameter.type, isNull);
    expect(simpleParameter.kind, kind);
    expect(parameter.separator, isNotNull);
    expect(parameter.defaultValue, isNotNull);
    expect(parameter.kind, kind);
  }

  void test_parseFormalParameterList_empty() {
    FormalParameterList parameterList = ParserTestCase.parse4("parseFormalParameterList", "()", []);
    expect(parameterList.leftParenthesis, isNotNull);
    expect(parameterList.leftDelimiter, isNull);
    expect(parameterList.parameters, hasLength(0));
    expect(parameterList.rightDelimiter, isNull);
    expect(parameterList.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_named_multiple() {
    FormalParameterList parameterList = ParserTestCase.parse4("parseFormalParameterList", "({A a : 1, B b, C c : 3})", []);
    expect(parameterList.leftParenthesis, isNotNull);
    expect(parameterList.leftDelimiter, isNotNull);
    expect(parameterList.parameters, hasLength(3));
    expect(parameterList.rightDelimiter, isNotNull);
    expect(parameterList.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_named_single() {
    FormalParameterList parameterList = ParserTestCase.parse4("parseFormalParameterList", "({A a})", []);
    expect(parameterList.leftParenthesis, isNotNull);
    expect(parameterList.leftDelimiter, isNotNull);
    expect(parameterList.parameters, hasLength(1));
    expect(parameterList.rightDelimiter, isNotNull);
    expect(parameterList.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_normal_multiple() {
    FormalParameterList parameterList = ParserTestCase.parse4("parseFormalParameterList", "(A a, B b, C c)", []);
    expect(parameterList.leftParenthesis, isNotNull);
    expect(parameterList.leftDelimiter, isNull);
    expect(parameterList.parameters, hasLength(3));
    expect(parameterList.rightDelimiter, isNull);
    expect(parameterList.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_normal_named() {
    FormalParameterList parameterList = ParserTestCase.parse4("parseFormalParameterList", "(A a, {B b})", []);
    expect(parameterList.leftParenthesis, isNotNull);
    expect(parameterList.leftDelimiter, isNotNull);
    expect(parameterList.parameters, hasLength(2));
    expect(parameterList.rightDelimiter, isNotNull);
    expect(parameterList.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_normal_positional() {
    FormalParameterList parameterList = ParserTestCase.parse4("parseFormalParameterList", "(A a, [B b])", []);
    expect(parameterList.leftParenthesis, isNotNull);
    expect(parameterList.leftDelimiter, isNotNull);
    expect(parameterList.parameters, hasLength(2));
    expect(parameterList.rightDelimiter, isNotNull);
    expect(parameterList.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_normal_single() {
    FormalParameterList parameterList = ParserTestCase.parse4("parseFormalParameterList", "(A a)", []);
    expect(parameterList.leftParenthesis, isNotNull);
    expect(parameterList.leftDelimiter, isNull);
    expect(parameterList.parameters, hasLength(1));
    expect(parameterList.rightDelimiter, isNull);
    expect(parameterList.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_positional_multiple() {
    FormalParameterList parameterList = ParserTestCase.parse4("parseFormalParameterList", "([A a = null, B b, C c = null])", []);
    expect(parameterList.leftParenthesis, isNotNull);
    expect(parameterList.leftDelimiter, isNotNull);
    expect(parameterList.parameters, hasLength(3));
    expect(parameterList.rightDelimiter, isNotNull);
    expect(parameterList.rightParenthesis, isNotNull);
  }

  void test_parseFormalParameterList_positional_single() {
    FormalParameterList parameterList = ParserTestCase.parse4("parseFormalParameterList", "([A a = null])", []);
    expect(parameterList.leftParenthesis, isNotNull);
    expect(parameterList.leftDelimiter, isNotNull);
    expect(parameterList.parameters, hasLength(1));
    expect(parameterList.rightDelimiter, isNotNull);
    expect(parameterList.rightParenthesis, isNotNull);
  }

  void test_parseForStatement_each_await() {
    ForEachStatement statement = ParserTestCase.parse4("parseForStatement", "await for (element in list) {}", []);
    expect(statement.awaitKeyword, isNotNull);
    expect(statement.forKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.loopVariable, isNull);
    expect(statement.identifier, isNotNull);
    expect(statement.inKeyword, isNotNull);
    expect(statement.iterable, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.body, isNotNull);
  }

  void test_parseForStatement_each_identifier() {
    ForEachStatement statement = ParserTestCase.parse4("parseForStatement", "for (element in list) {}", []);
    expect(statement.awaitKeyword, isNull);
    expect(statement.forKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.loopVariable, isNull);
    expect(statement.identifier, isNotNull);
    expect(statement.inKeyword, isNotNull);
    expect(statement.iterable, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.body, isNotNull);
  }

  void test_parseForStatement_each_noType_metadata() {
    ForEachStatement statement = ParserTestCase.parse4("parseForStatement", "for (@A var element in list) {}", []);
    expect(statement.awaitKeyword, isNull);
    expect(statement.forKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.loopVariable, isNotNull);
    expect(statement.loopVariable.metadata, hasLength(1));
    expect(statement.identifier, isNull);
    expect(statement.inKeyword, isNotNull);
    expect(statement.iterable, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.body, isNotNull);
  }

  void test_parseForStatement_each_type() {
    ForEachStatement statement = ParserTestCase.parse4("parseForStatement", "for (A element in list) {}", []);
    expect(statement.awaitKeyword, isNull);
    expect(statement.forKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.loopVariable, isNotNull);
    expect(statement.identifier, isNull);
    expect(statement.inKeyword, isNotNull);
    expect(statement.iterable, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.body, isNotNull);
  }

  void test_parseForStatement_each_var() {
    ForEachStatement statement = ParserTestCase.parse4("parseForStatement", "for (var element in list) {}", []);
    expect(statement.awaitKeyword, isNull);
    expect(statement.forKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.loopVariable, isNotNull);
    expect(statement.identifier, isNull);
    expect(statement.inKeyword, isNotNull);
    expect(statement.iterable, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.body, isNotNull);
  }

  void test_parseForStatement_loop_c() {
    ForStatement statement = ParserTestCase.parse4("parseForStatement", "for (; i < count;) {}", []);
    expect(statement.forKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.variables, isNull);
    expect(statement.initialization, isNull);
    expect(statement.leftSeparator, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightSeparator, isNotNull);
    expect(statement.updaters, hasLength(0));
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.body, isNotNull);
  }

  void test_parseForStatement_loop_cu() {
    ForStatement statement = ParserTestCase.parse4("parseForStatement", "for (; i < count; i++) {}", []);
    expect(statement.forKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.variables, isNull);
    expect(statement.initialization, isNull);
    expect(statement.leftSeparator, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightSeparator, isNotNull);
    expect(statement.updaters, hasLength(1));
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.body, isNotNull);
  }

  void test_parseForStatement_loop_ecu() {
    ForStatement statement = ParserTestCase.parse4("parseForStatement", "for (i--; i < count; i++) {}", []);
    expect(statement.forKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.variables, isNull);
    expect(statement.initialization, isNotNull);
    expect(statement.leftSeparator, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightSeparator, isNotNull);
    expect(statement.updaters, hasLength(1));
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.body, isNotNull);
  }

  void test_parseForStatement_loop_i() {
    ForStatement statement = ParserTestCase.parse4("parseForStatement", "for (var i = 0;;) {}", []);
    expect(statement.forKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    VariableDeclarationList variables = statement.variables;
    expect(variables, isNotNull);
    expect(variables.metadata, hasLength(0));
    expect(variables.variables, hasLength(1));
    expect(statement.initialization, isNull);
    expect(statement.leftSeparator, isNotNull);
    expect(statement.condition, isNull);
    expect(statement.rightSeparator, isNotNull);
    expect(statement.updaters, hasLength(0));
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.body, isNotNull);
  }

  void test_parseForStatement_loop_i_withMetadata() {
    ForStatement statement = ParserTestCase.parse4("parseForStatement", "for (@A var i = 0;;) {}", []);
    expect(statement.forKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    VariableDeclarationList variables = statement.variables;
    expect(variables, isNotNull);
    expect(variables.metadata, hasLength(1));
    expect(variables.variables, hasLength(1));
    expect(statement.initialization, isNull);
    expect(statement.leftSeparator, isNotNull);
    expect(statement.condition, isNull);
    expect(statement.rightSeparator, isNotNull);
    expect(statement.updaters, hasLength(0));
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.body, isNotNull);
  }

  void test_parseForStatement_loop_ic() {
    ForStatement statement = ParserTestCase.parse4("parseForStatement", "for (var i = 0; i < count;) {}", []);
    expect(statement.forKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    VariableDeclarationList variables = statement.variables;
    expect(variables, isNotNull);
    expect(variables.variables, hasLength(1));
    expect(statement.initialization, isNull);
    expect(statement.leftSeparator, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightSeparator, isNotNull);
    expect(statement.updaters, hasLength(0));
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.body, isNotNull);
  }

  void test_parseForStatement_loop_icu() {
    ForStatement statement = ParserTestCase.parse4("parseForStatement", "for (var i = 0; i < count; i++) {}", []);
    expect(statement.forKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    VariableDeclarationList variables = statement.variables;
    expect(variables, isNotNull);
    expect(variables.variables, hasLength(1));
    expect(statement.initialization, isNull);
    expect(statement.leftSeparator, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightSeparator, isNotNull);
    expect(statement.updaters, hasLength(1));
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.body, isNotNull);
  }

  void test_parseForStatement_loop_iicuu() {
    ForStatement statement = ParserTestCase.parse4("parseForStatement", "for (int i = 0, j = count; i < j; i++, j--) {}", []);
    expect(statement.forKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    VariableDeclarationList variables = statement.variables;
    expect(variables, isNotNull);
    expect(variables.variables, hasLength(2));
    expect(statement.initialization, isNull);
    expect(statement.leftSeparator, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightSeparator, isNotNull);
    expect(statement.updaters, hasLength(2));
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.body, isNotNull);
  }

  void test_parseForStatement_loop_iu() {
    ForStatement statement = ParserTestCase.parse4("parseForStatement", "for (var i = 0;; i++) {}", []);
    expect(statement.forKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    VariableDeclarationList variables = statement.variables;
    expect(variables, isNotNull);
    expect(variables.variables, hasLength(1));
    expect(statement.initialization, isNull);
    expect(statement.leftSeparator, isNotNull);
    expect(statement.condition, isNull);
    expect(statement.rightSeparator, isNotNull);
    expect(statement.updaters, hasLength(1));
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.body, isNotNull);
  }

  void test_parseForStatement_loop_u() {
    ForStatement statement = ParserTestCase.parse4("parseForStatement", "for (;; i++) {}", []);
    expect(statement.forKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.variables, isNull);
    expect(statement.initialization, isNull);
    expect(statement.leftSeparator, isNotNull);
    expect(statement.condition, isNull);
    expect(statement.rightSeparator, isNotNull);
    expect(statement.updaters, hasLength(1));
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.body, isNotNull);
  }

  void test_parseFunctionBody_block() {
    BlockFunctionBody functionBody = ParserTestCase.parse("parseFunctionBody", <Object> [false, null, false], "{}");
    expect(functionBody.keyword, isNull);
    expect(functionBody.star, isNull);
    expect(functionBody.block, isNotNull);
    expect(functionBody.isAsynchronous, isFalse);
    expect(functionBody.isGenerator, isFalse);
    expect(functionBody.isSynchronous, isTrue);
  }

  void test_parseFunctionBody_block_async() {
    BlockFunctionBody functionBody = ParserTestCase.parse("parseFunctionBody", <Object> [false, null, false], "async {}");
    expect(functionBody.keyword, isNotNull);
    expect(functionBody.keyword.lexeme, Parser.ASYNC);
    expect(functionBody.star, isNull);
    expect(functionBody.block, isNotNull);
    expect(functionBody.isAsynchronous, isTrue);
    expect(functionBody.isGenerator, isFalse);
    expect(functionBody.isSynchronous, isFalse);
  }

  void test_parseFunctionBody_block_asyncGenerator() {
    BlockFunctionBody functionBody = ParserTestCase.parse("parseFunctionBody", <Object> [false, null, false], "async* {}");
    expect(functionBody.keyword, isNotNull);
    expect(functionBody.keyword.lexeme, Parser.ASYNC);
    expect(functionBody.star, isNotNull);
    expect(functionBody.block, isNotNull);
    expect(functionBody.isAsynchronous, isTrue);
    expect(functionBody.isGenerator, isTrue);
    expect(functionBody.isSynchronous, isFalse);
  }

  void test_parseFunctionBody_block_syncGenerator() {
    BlockFunctionBody functionBody = ParserTestCase.parse("parseFunctionBody", <Object> [false, null, false], "sync* {}");
    expect(functionBody.keyword, isNotNull);
    expect(functionBody.keyword.lexeme, Parser.SYNC);
    expect(functionBody.star, isNotNull);
    expect(functionBody.block, isNotNull);
    expect(functionBody.isAsynchronous, isFalse);
    expect(functionBody.isGenerator, isTrue);
    expect(functionBody.isSynchronous, isTrue);
  }

  void test_parseFunctionBody_empty() {
    EmptyFunctionBody functionBody = ParserTestCase.parse("parseFunctionBody", <Object> [true, null, false], ";");
    expect(functionBody.semicolon, isNotNull);
  }

  void test_parseFunctionBody_expression() {
    ExpressionFunctionBody functionBody = ParserTestCase.parse("parseFunctionBody", <Object> [false, null, false], "=> y;");
    expect(functionBody.keyword, isNull);
    expect(functionBody.functionDefinition, isNotNull);
    expect(functionBody.expression, isNotNull);
    expect(functionBody.semicolon, isNotNull);
    expect(functionBody.isAsynchronous, isFalse);
    expect(functionBody.isGenerator, isFalse);
    expect(functionBody.isSynchronous, isTrue);
  }

  void test_parseFunctionBody_expression_async() {
    ExpressionFunctionBody functionBody = ParserTestCase.parse("parseFunctionBody", <Object> [false, null, false], "async => y;");
    expect(functionBody.keyword, isNotNull);
    expect(functionBody.keyword.lexeme, Parser.ASYNC);
    expect(functionBody.functionDefinition, isNotNull);
    expect(functionBody.expression, isNotNull);
    expect(functionBody.semicolon, isNotNull);
    expect(functionBody.isAsynchronous, isTrue);
    expect(functionBody.isGenerator, isFalse);
    expect(functionBody.isSynchronous, isFalse);
  }

  void test_parseFunctionBody_nativeFunctionBody() {
    NativeFunctionBody functionBody = ParserTestCase.parse("parseFunctionBody", <Object> [false, null, false], "native 'str';");
    expect(functionBody.nativeToken, isNotNull);
    expect(functionBody.stringLiteral, isNotNull);
    expect(functionBody.semicolon, isNotNull);
  }

  void test_parseFunctionBody_skip_block() {
    ParserTestCase.parseFunctionBodies = false;
    FunctionBody functionBody = ParserTestCase.parse("parseFunctionBody", <Object> [false, null, false], "{}");
    EngineTestCase.assertInstanceOf((obj) => obj is EmptyFunctionBody, EmptyFunctionBody, functionBody);
  }

  void test_parseFunctionBody_skip_block_invalid() {
    ParserTestCase.parseFunctionBodies = false;
    FunctionBody functionBody = ParserTestCase.parse3("parseFunctionBody", <Object> [false, null, false], "{", [ParserErrorCode.EXPECTED_TOKEN]);
    EngineTestCase.assertInstanceOf((obj) => obj is EmptyFunctionBody, EmptyFunctionBody, functionBody);
  }

  void test_parseFunctionBody_skip_blocks() {
    ParserTestCase.parseFunctionBodies = false;
    FunctionBody functionBody = ParserTestCase.parse("parseFunctionBody", <Object> [false, null, false], "{ {} }");
    EngineTestCase.assertInstanceOf((obj) => obj is EmptyFunctionBody, EmptyFunctionBody, functionBody);
  }

  void test_parseFunctionBody_skip_expression() {
    ParserTestCase.parseFunctionBodies = false;
    FunctionBody functionBody = ParserTestCase.parse("parseFunctionBody", <Object> [false, null, false], "=> y;");
    EngineTestCase.assertInstanceOf((obj) => obj is EmptyFunctionBody, EmptyFunctionBody, functionBody);
  }

  void test_parseFunctionDeclaration_function() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    TypeName returnType = new TypeName(new SimpleIdentifier(null), null);
    FunctionDeclaration declaration = ParserTestCase.parse("parseFunctionDeclaration", <Object> [commentAndMetadata(comment, []), null, returnType], "f() {}");
    expect(declaration.documentationComment, comment);
    expect(declaration.returnType, returnType);
    expect(declaration.name, isNotNull);
    FunctionExpression expression = declaration.functionExpression;
    expect(expression, isNotNull);
    expect(expression.body, isNotNull);
    expect(expression.parameters, isNotNull);
    expect(declaration.propertyKeyword, isNull);
  }

  void test_parseFunctionDeclaration_getter() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    TypeName returnType = new TypeName(new SimpleIdentifier(null), null);
    FunctionDeclaration declaration = ParserTestCase.parse("parseFunctionDeclaration", <Object> [commentAndMetadata(comment, []), null, returnType], "get p => 0;");
    expect(declaration.documentationComment, comment);
    expect(declaration.returnType, returnType);
    expect(declaration.name, isNotNull);
    FunctionExpression expression = declaration.functionExpression;
    expect(expression, isNotNull);
    expect(expression.body, isNotNull);
    expect(expression.parameters, isNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseFunctionDeclaration_setter() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    TypeName returnType = new TypeName(new SimpleIdentifier(null), null);
    FunctionDeclaration declaration = ParserTestCase.parse("parseFunctionDeclaration", <Object> [commentAndMetadata(comment, []), null, returnType], "set p(v) {}");
    expect(declaration.documentationComment, comment);
    expect(declaration.returnType, returnType);
    expect(declaration.name, isNotNull);
    FunctionExpression expression = declaration.functionExpression;
    expect(expression, isNotNull);
    expect(expression.body, isNotNull);
    expect(expression.parameters, isNotNull);
    expect(declaration.propertyKeyword, isNotNull);
  }

  void test_parseFunctionDeclarationStatement() {
    FunctionDeclarationStatement statement = ParserTestCase.parse4("parseFunctionDeclarationStatement", "void f(int p) => p * 2;", []);
    expect(statement.functionDeclaration, isNotNull);
  }

  void test_parseFunctionExpression_body_inExpression() {
    FunctionExpression expression = ParserTestCase.parse4("parseFunctionExpression", "(int i) => i++", []);
    expect(expression.body, isNotNull);
    expect(expression.parameters, isNotNull);
    expect((expression.body as ExpressionFunctionBody).semicolon, isNull);
  }

  void test_parseGetter_nonStatic() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    TypeName returnType = new TypeName(new SimpleIdentifier(null), null);
    MethodDeclaration method = ParserTestCase.parse("parseGetter", <Object> [commentAndMetadata(comment, []), null, null, returnType], "get a;");
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
    MethodDeclaration method = ParserTestCase.parse("parseGetter", <Object> [
        commentAndMetadata(comment, []),
        null,
        staticKeyword,
        returnType], "get a => 42;");
    expect(method.body, isNotNull);
    expect(method.documentationComment, comment);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, staticKeyword);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.parameters, isNull);
    expect(method.propertyKeyword, isNotNull);
    expect(method.returnType, returnType);
  }

  void test_parseIdentifierList_multiple() {
    List<SimpleIdentifier> list = ParserTestCase.parse4("parseIdentifierList", "a, b, c", []);
    expect(list, hasLength(3));
  }

  void test_parseIdentifierList_single() {
    List<SimpleIdentifier> list = ParserTestCase.parse4("parseIdentifierList", "a", []);
    expect(list, hasLength(1));
  }

  void test_parseIfStatement_else_block() {
    IfStatement statement = ParserTestCase.parse4("parseIfStatement", "if (x) {} else {}", []);
    expect(statement.ifKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.thenStatement, isNotNull);
    expect(statement.elseKeyword, isNotNull);
    expect(statement.elseStatement, isNotNull);
  }

  void test_parseIfStatement_else_statement() {
    IfStatement statement = ParserTestCase.parse4("parseIfStatement", "if (x) f(x); else f(y);", []);
    expect(statement.ifKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.thenStatement, isNotNull);
    expect(statement.elseKeyword, isNotNull);
    expect(statement.elseStatement, isNotNull);
  }

  void test_parseIfStatement_noElse_block() {
    IfStatement statement = ParserTestCase.parse4("parseIfStatement", "if (x) {}", []);
    expect(statement.ifKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.thenStatement, isNotNull);
    expect(statement.elseKeyword, isNull);
    expect(statement.elseStatement, isNull);
  }

  void test_parseIfStatement_noElse_statement() {
    IfStatement statement = ParserTestCase.parse4("parseIfStatement", "if (x) f(x);", []);
    expect(statement.ifKeyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.thenStatement, isNotNull);
    expect(statement.elseKeyword, isNull);
    expect(statement.elseStatement, isNull);
  }

  void test_parseImplementsClause_multiple() {
    ImplementsClause clause = ParserTestCase.parse4("parseImplementsClause", "implements A, B, C", []);
    expect(clause.interfaces, hasLength(3));
    expect(clause.keyword, isNotNull);
  }

  void test_parseImplementsClause_single() {
    ImplementsClause clause = ParserTestCase.parse4("parseImplementsClause", "implements A", []);
    expect(clause.interfaces, hasLength(1));
    expect(clause.keyword, isNotNull);
  }

  void test_parseImportDirective_deferred() {
    ImportDirective directive = ParserTestCase.parse("parseImportDirective", <Object> [emptyCommentAndMetadata()], "import 'lib/lib.dart' deferred as a;");
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredToken, isNotNull);
    expect(directive.asToken, isNotNull);
    expect(directive.prefix, isNotNull);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_hide() {
    ImportDirective directive = ParserTestCase.parse("parseImportDirective", <Object> [emptyCommentAndMetadata()], "import 'lib/lib.dart' hide A, B;");
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredToken, isNull);
    expect(directive.asToken, isNull);
    expect(directive.prefix, isNull);
    expect(directive.combinators, hasLength(1));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_noCombinator() {
    ImportDirective directive = ParserTestCase.parse("parseImportDirective", <Object> [emptyCommentAndMetadata()], "import 'lib/lib.dart';");
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredToken, isNull);
    expect(directive.asToken, isNull);
    expect(directive.prefix, isNull);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_prefix() {
    ImportDirective directive = ParserTestCase.parse("parseImportDirective", <Object> [emptyCommentAndMetadata()], "import 'lib/lib.dart' as a;");
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredToken, isNull);
    expect(directive.asToken, isNotNull);
    expect(directive.prefix, isNotNull);
    expect(directive.combinators, hasLength(0));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_prefix_hide_show() {
    ImportDirective directive = ParserTestCase.parse("parseImportDirective", <Object> [emptyCommentAndMetadata()], "import 'lib/lib.dart' as a hide A show B;");
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredToken, isNull);
    expect(directive.asToken, isNotNull);
    expect(directive.prefix, isNotNull);
    expect(directive.combinators, hasLength(2));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_prefix_show_hide() {
    ImportDirective directive = ParserTestCase.parse("parseImportDirective", <Object> [emptyCommentAndMetadata()], "import 'lib/lib.dart' as a show B hide A;");
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredToken, isNull);
    expect(directive.asToken, isNotNull);
    expect(directive.prefix, isNotNull);
    expect(directive.combinators, hasLength(2));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseImportDirective_show() {
    ImportDirective directive = ParserTestCase.parse("parseImportDirective", <Object> [emptyCommentAndMetadata()], "import 'lib/lib.dart' show A, B;");
    expect(directive.keyword, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.deferredToken, isNull);
    expect(directive.asToken, isNull);
    expect(directive.prefix, isNull);
    expect(directive.combinators, hasLength(1));
    expect(directive.semicolon, isNotNull);
  }

  void test_parseInitializedIdentifierList_type() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    Token staticKeyword = TokenFactory.tokenFromKeyword(Keyword.STATIC);
    TypeName type = new TypeName(new SimpleIdentifier(null), null);
    FieldDeclaration declaration = ParserTestCase.parse("parseInitializedIdentifierList", <Object> [
        commentAndMetadata(comment, []),
        staticKeyword,
        null,
        type], "a = 1, b, c = 3;");
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
    FieldDeclaration declaration = ParserTestCase.parse("parseInitializedIdentifierList", <Object> [
        commentAndMetadata(comment, []),
        staticKeyword,
        varKeyword,
        null], "a = 1, b, c = 3;");
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
    InstanceCreationExpression expression = ParserTestCase.parse("parseInstanceCreationExpression", <Object> [token], "A.B()");
    expect(expression.keyword, token);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    expect(name.type, isNotNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseInstanceCreationExpression_qualifiedType_named() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    InstanceCreationExpression expression = ParserTestCase.parse("parseInstanceCreationExpression", <Object> [token], "A.B.c()");
    expect(expression.keyword, token);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    expect(name.type, isNotNull);
    expect(name.period, isNotNull);
    expect(name.name, isNotNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseInstanceCreationExpression_type() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    InstanceCreationExpression expression = ParserTestCase.parse("parseInstanceCreationExpression", <Object> [token], "A()");
    expect(expression.keyword, token);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    expect(name.type, isNotNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseInstanceCreationExpression_type_named() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    InstanceCreationExpression expression = ParserTestCase.parse("parseInstanceCreationExpression", <Object> [token], "A<B>.c()");
    expect(expression.keyword, token);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    expect(name.type, isNotNull);
    expect(name.period, isNotNull);
    expect(name.name, isNotNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseLibraryDirective() {
    LibraryDirective directive = ParserTestCase.parse("parseLibraryDirective", <Object> [emptyCommentAndMetadata()], "library l;");
    expect(directive.libraryToken, isNotNull);
    expect(directive.name, isNotNull);
    expect(directive.semicolon, isNotNull);
  }

  void test_parseLibraryIdentifier_multiple() {
    String name = "a.b.c";
    LibraryIdentifier identifier = ParserTestCase.parse4("parseLibraryIdentifier", name, []);
    expect(identifier.name, name);
  }

  void test_parseLibraryIdentifier_single() {
    String name = "a";
    LibraryIdentifier identifier = ParserTestCase.parse4("parseLibraryIdentifier", name, []);
    expect(identifier.name, name);
  }

  void test_parseListLiteral_empty_oneToken() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.CONST);
    TypeArgumentList typeArguments = null;
    ListLiteral literal = ParserTestCase.parse("parseListLiteral", <Object> [token, typeArguments], "[]");
    expect(literal.constKeyword, token);
    expect(literal.typeArguments, typeArguments);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseListLiteral_empty_twoTokens() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.CONST);
    TypeArgumentList typeArguments = null;
    ListLiteral literal = ParserTestCase.parse("parseListLiteral", <Object> [token, typeArguments], "[ ]");
    expect(literal.constKeyword, token);
    expect(literal.typeArguments, typeArguments);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(0));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseListLiteral_multiple() {
    ListLiteral literal = ParserTestCase.parse("parseListLiteral", <Object> [null, null], "[1, 2, 3]");
    expect(literal.constKeyword, isNull);
    expect(literal.typeArguments, isNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(3));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseListLiteral_single() {
    ListLiteral literal = ParserTestCase.parse("parseListLiteral", <Object> [null, null], "[1]");
    expect(literal.constKeyword, isNull);
    expect(literal.typeArguments, isNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(1));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseListOrMapLiteral_list_noType() {
    ListLiteral literal = ParserTestCase.parse("parseListOrMapLiteral", <Object> [null], "[1]");
    expect(literal.constKeyword, isNull);
    expect(literal.typeArguments, isNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(1));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseListOrMapLiteral_list_type() {
    ListLiteral literal = ParserTestCase.parse("parseListOrMapLiteral", <Object> [null], "<int> [1]");
    expect(literal.constKeyword, isNull);
    expect(literal.typeArguments, isNotNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.elements, hasLength(1));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseListOrMapLiteral_map_noType() {
    MapLiteral literal = ParserTestCase.parse("parseListOrMapLiteral", <Object> [null], "{'1' : 1}");
    expect(literal.constKeyword, isNull);
    expect(literal.typeArguments, isNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.entries, hasLength(1));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseListOrMapLiteral_map_type() {
    MapLiteral literal = ParserTestCase.parse("parseListOrMapLiteral", <Object> [null], "<String, int> {'1' : 1}");
    expect(literal.constKeyword, isNull);
    expect(literal.typeArguments, isNotNull);
    expect(literal.leftBracket, isNotNull);
    expect(literal.entries, hasLength(1));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseLogicalAndExpression() {
    BinaryExpression expression = ParserTestCase.parse4("parseLogicalAndExpression", "x && y", []);
    expect(expression.leftOperand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.AMPERSAND_AMPERSAND);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseLogicalOrExpression() {
    BinaryExpression expression = ParserTestCase.parse4("parseLogicalOrExpression", "x || y", []);
    expect(expression.leftOperand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.BAR_BAR);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseMapLiteral_empty() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.CONST);
    TypeArgumentList typeArguments = AstFactory.typeArgumentList([
        AstFactory.typeName4("String", []),
        AstFactory.typeName4("int", [])]);
    MapLiteral literal = ParserTestCase.parse("parseMapLiteral", <Object> [token, typeArguments], "{}");
    expect(literal.constKeyword, token);
    expect(literal.typeArguments, typeArguments);
    expect(literal.leftBracket, isNotNull);
    expect(literal.entries, hasLength(0));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseMapLiteral_multiple() {
    MapLiteral literal = ParserTestCase.parse("parseMapLiteral", <Object> [null, null], "{'a' : b, 'x' : y}");
    expect(literal.leftBracket, isNotNull);
    expect(literal.entries, hasLength(2));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseMapLiteral_single() {
    MapLiteral literal = ParserTestCase.parse("parseMapLiteral", <Object> [null, null], "{'x' : y}");
    expect(literal.leftBracket, isNotNull);
    expect(literal.entries, hasLength(1));
    expect(literal.rightBracket, isNotNull);
  }

  void test_parseMapLiteralEntry_complex() {
    MapLiteralEntry entry = ParserTestCase.parse4("parseMapLiteralEntry", "2 + 2 : y", []);
    expect(entry.key, isNotNull);
    expect(entry.separator, isNotNull);
    expect(entry.value, isNotNull);
  }

  void test_parseMapLiteralEntry_int() {
    MapLiteralEntry entry = ParserTestCase.parse4("parseMapLiteralEntry", "0 : y", []);
    expect(entry.key, isNotNull);
    expect(entry.separator, isNotNull);
    expect(entry.value, isNotNull);
  }

  void test_parseMapLiteralEntry_string() {
    MapLiteralEntry entry = ParserTestCase.parse4("parseMapLiteralEntry", "'x' : y", []);
    expect(entry.key, isNotNull);
    expect(entry.separator, isNotNull);
    expect(entry.value, isNotNull);
  }

  void test_parseModifiers_abstract() {
    Modifiers modifiers = ParserTestCase.parse4("parseModifiers", "abstract A", []);
    expect(modifiers.abstractKeyword, isNotNull);
  }

  void test_parseModifiers_const() {
    Modifiers modifiers = ParserTestCase.parse4("parseModifiers", "const A", []);
    expect(modifiers.constKeyword, isNotNull);
  }

  void test_parseModifiers_external() {
    Modifiers modifiers = ParserTestCase.parse4("parseModifiers", "external A", []);
    expect(modifiers.externalKeyword, isNotNull);
  }

  void test_parseModifiers_factory() {
    Modifiers modifiers = ParserTestCase.parse4("parseModifiers", "factory A", []);
    expect(modifiers.factoryKeyword, isNotNull);
  }

  void test_parseModifiers_final() {
    Modifiers modifiers = ParserTestCase.parse4("parseModifiers", "final A", []);
    expect(modifiers.finalKeyword, isNotNull);
  }

  void test_parseModifiers_static() {
    Modifiers modifiers = ParserTestCase.parse4("parseModifiers", "static A", []);
    expect(modifiers.staticKeyword, isNotNull);
  }

  void test_parseModifiers_var() {
    Modifiers modifiers = ParserTestCase.parse4("parseModifiers", "var A", []);
    expect(modifiers.varKeyword, isNotNull);
  }

  void test_parseMultiplicativeExpression_normal() {
    BinaryExpression expression = ParserTestCase.parse4("parseMultiplicativeExpression", "x * y", []);
    expect(expression.leftOperand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.STAR);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseMultiplicativeExpression_super() {
    BinaryExpression expression = ParserTestCase.parse4("parseMultiplicativeExpression", "super * y", []);
    EngineTestCase.assertInstanceOf((obj) => obj is SuperExpression, SuperExpression, expression.leftOperand);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.STAR);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseNewExpression() {
    InstanceCreationExpression expression = ParserTestCase.parse4("parseNewExpression", "new A()", []);
    expect(expression.keyword, isNotNull);
    ConstructorName name = expression.constructorName;
    expect(name, isNotNull);
    expect(name.type, isNotNull);
    expect(name.period, isNull);
    expect(name.name, isNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parseNonLabeledStatement_const_list_empty() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "const [];", []);
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_const_list_nonEmpty() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "const [1, 2];", []);
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_const_map_empty() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "const {};", []);
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_const_map_nonEmpty() {
    // TODO(brianwilkerson) Implement more tests for this method.
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "const {'a' : 1};", []);
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_const_object() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "const A();", []);
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_const_object_named_typeParameters() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "const A<B>.c();", []);
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_constructorInvocation() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "new C().m();", []);
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_false() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "false;", []);
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_functionDeclaration() {
    ParserTestCase.parse4("parseNonLabeledStatement", "f() {};", []);
  }

  void test_parseNonLabeledStatement_functionDeclaration_arguments() {
    ParserTestCase.parse4("parseNonLabeledStatement", "f(void g()) {};", []);
  }

  void test_parseNonLabeledStatement_functionExpressionIndex() {
    ParserTestCase.parse4("parseNonLabeledStatement", "() {}[0] = null;", []);
  }

  void test_parseNonLabeledStatement_functionInvocation() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "f();", []);
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_invokeFunctionExpression() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "(a) {return a + a;} (3);", []);
    EngineTestCase.assertInstanceOf((obj) => obj is FunctionExpressionInvocation, FunctionExpressionInvocation, statement.expression);
    FunctionExpressionInvocation invocation = statement.expression as FunctionExpressionInvocation;
    EngineTestCase.assertInstanceOf((obj) => obj is FunctionExpression, FunctionExpression, invocation.function);
    FunctionExpression expression = invocation.function as FunctionExpression;
    expect(expression.parameters, isNotNull);
    expect(expression.body, isNotNull);
    ArgumentList list = invocation.argumentList;
    expect(list, isNotNull);
    expect(list.arguments, hasLength(1));
  }

  void test_parseNonLabeledStatement_null() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "null;", []);
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_startingWithBuiltInIdentifier() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "library.getName();", []);
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_true() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "true;", []);
    expect(statement.expression, isNotNull);
  }

  void test_parseNonLabeledStatement_typeCast() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "double.NAN as num;", []);
    expect(statement.expression, isNotNull);
  }

  void test_parseNormalFormalParameter_field_const_noType() {
    FieldFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "const this.a)", []);
    expect(parameter.keyword, isNotNull);
    expect(parameter.type, isNull);
    expect(parameter.identifier, isNotNull);
    expect(parameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_const_type() {
    FieldFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "const A this.a)", []);
    expect(parameter.keyword, isNotNull);
    expect(parameter.type, isNotNull);
    expect(parameter.identifier, isNotNull);
    expect(parameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_final_noType() {
    FieldFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "final this.a)", []);
    expect(parameter.keyword, isNotNull);
    expect(parameter.type, isNull);
    expect(parameter.identifier, isNotNull);
    expect(parameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_final_type() {
    FieldFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "final A this.a)", []);
    expect(parameter.keyword, isNotNull);
    expect(parameter.type, isNotNull);
    expect(parameter.identifier, isNotNull);
    expect(parameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_function_nested() {
    FieldFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "this.a(B b))", []);
    expect(parameter.keyword, isNull);
    expect(parameter.type, isNull);
    expect(parameter.identifier, isNotNull);
    FormalParameterList parameterList = parameter.parameters;
    expect(parameterList, isNotNull);
    expect(parameterList.parameters, hasLength(1));
  }

  void test_parseNormalFormalParameter_field_function_noNested() {
    FieldFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "this.a())", []);
    expect(parameter.keyword, isNull);
    expect(parameter.type, isNull);
    expect(parameter.identifier, isNotNull);
    FormalParameterList parameterList = parameter.parameters;
    expect(parameterList, isNotNull);
    expect(parameterList.parameters, hasLength(0));
  }

  void test_parseNormalFormalParameter_field_noType() {
    FieldFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "this.a)", []);
    expect(parameter.keyword, isNull);
    expect(parameter.type, isNull);
    expect(parameter.identifier, isNotNull);
    expect(parameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_type() {
    FieldFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "A this.a)", []);
    expect(parameter.keyword, isNull);
    expect(parameter.type, isNotNull);
    expect(parameter.identifier, isNotNull);
    expect(parameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_field_var() {
    FieldFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "var this.a)", []);
    expect(parameter.keyword, isNotNull);
    expect(parameter.type, isNull);
    expect(parameter.identifier, isNotNull);
    expect(parameter.parameters, isNull);
  }

  void test_parseNormalFormalParameter_function_noType() {
    FunctionTypedFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "a())", []);
    expect(parameter.returnType, isNull);
    expect(parameter.identifier, isNotNull);
    expect(parameter.parameters, isNotNull);
  }

  void test_parseNormalFormalParameter_function_type() {
    FunctionTypedFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "A a())", []);
    expect(parameter.returnType, isNotNull);
    expect(parameter.identifier, isNotNull);
    expect(parameter.parameters, isNotNull);
  }

  void test_parseNormalFormalParameter_function_void() {
    FunctionTypedFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "void a())", []);
    expect(parameter.returnType, isNotNull);
    expect(parameter.identifier, isNotNull);
    expect(parameter.parameters, isNotNull);
  }

  void test_parseNormalFormalParameter_simple_const_noType() {
    SimpleFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "const a)", []);
    expect(parameter.keyword, isNotNull);
    expect(parameter.type, isNull);
    expect(parameter.identifier, isNotNull);
  }

  void test_parseNormalFormalParameter_simple_const_type() {
    SimpleFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "const A a)", []);
    expect(parameter.keyword, isNotNull);
    expect(parameter.type, isNotNull);
    expect(parameter.identifier, isNotNull);
  }

  void test_parseNormalFormalParameter_simple_final_noType() {
    SimpleFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "final a)", []);
    expect(parameter.keyword, isNotNull);
    expect(parameter.type, isNull);
    expect(parameter.identifier, isNotNull);
  }

  void test_parseNormalFormalParameter_simple_final_type() {
    SimpleFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "final A a)", []);
    expect(parameter.keyword, isNotNull);
    expect(parameter.type, isNotNull);
    expect(parameter.identifier, isNotNull);
  }

  void test_parseNormalFormalParameter_simple_noType() {
    SimpleFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "a)", []);
    expect(parameter.keyword, isNull);
    expect(parameter.type, isNull);
    expect(parameter.identifier, isNotNull);
  }

  void test_parseNormalFormalParameter_simple_type() {
    SimpleFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "A a)", []);
    expect(parameter.keyword, isNull);
    expect(parameter.type, isNotNull);
    expect(parameter.identifier, isNotNull);
  }

  void test_parseOperator() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    TypeName returnType = new TypeName(new SimpleIdentifier(null), null);
    MethodDeclaration method = ParserTestCase.parse("parseOperator", <Object> [commentAndMetadata(comment, []), null, returnType], "operator +(A a);");
    expect(method.body, isNotNull);
    expect(method.documentationComment, comment);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNotNull);
    expect(method.parameters, isNotNull);
    expect(method.propertyKeyword, isNull);
    expect(method.returnType, returnType);
  }

  void test_parseOptionalReturnType() {
    // TODO(brianwilkerson) Implement tests for this method.
  }

  void test_parsePartDirective_part() {
    PartDirective directive = ParserTestCase.parse("parsePartDirective", <Object> [emptyCommentAndMetadata()], "part 'lib/lib.dart';");
    expect(directive.partToken, isNotNull);
    expect(directive.uri, isNotNull);
    expect(directive.semicolon, isNotNull);
  }

  void test_parsePartDirective_partOf() {
    PartOfDirective directive = ParserTestCase.parse("parsePartDirective", <Object> [emptyCommentAndMetadata()], "part of l;");
    expect(directive.partToken, isNotNull);
    expect(directive.ofToken, isNotNull);
    expect(directive.libraryName, isNotNull);
    expect(directive.semicolon, isNotNull);
  }

  void test_parsePostfixExpression_decrement() {
    PostfixExpression expression = ParserTestCase.parse4("parsePostfixExpression", "i--", []);
    expect(expression.operand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS_MINUS);
  }

  void test_parsePostfixExpression_increment() {
    PostfixExpression expression = ParserTestCase.parse4("parsePostfixExpression", "i++", []);
    expect(expression.operand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.PLUS_PLUS);
  }

  void test_parsePostfixExpression_none_indexExpression() {
    IndexExpression expression = ParserTestCase.parse4("parsePostfixExpression", "a[0]", []);
    expect(expression.target, isNotNull);
    expect(expression.index, isNotNull);
  }

  void test_parsePostfixExpression_none_methodInvocation() {
    MethodInvocation expression = ParserTestCase.parse4("parsePostfixExpression", "a.m()", []);
    expect(expression.target, isNotNull);
    expect(expression.methodName, isNotNull);
    expect(expression.argumentList, isNotNull);
  }

  void test_parsePostfixExpression_none_propertyAccess() {
    PrefixedIdentifier expression = ParserTestCase.parse4("parsePostfixExpression", "a.b", []);
    expect(expression.prefix, isNotNull);
    expect(expression.identifier, isNotNull);
  }

  void test_parsePrefixedIdentifier_noPrefix() {
    String lexeme = "bar";
    SimpleIdentifier identifier = ParserTestCase.parse4("parsePrefixedIdentifier", lexeme, []);
    expect(identifier.token, isNotNull);
    expect(identifier.name, lexeme);
  }

  void test_parsePrefixedIdentifier_prefix() {
    String lexeme = "foo.bar";
    PrefixedIdentifier identifier = ParserTestCase.parse4("parsePrefixedIdentifier", lexeme, []);
    expect(identifier.prefix.name, "foo");
    expect(identifier.period, isNotNull);
    expect(identifier.identifier.name, "bar");
  }

  void test_parsePrimaryExpression_const() {
    InstanceCreationExpression expression = ParserTestCase.parse4("parsePrimaryExpression", "const A()", []);
    expect(expression, isNotNull);
  }

  void test_parsePrimaryExpression_double() {
    String doubleLiteral = "3.2e4";
    DoubleLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", doubleLiteral, []);
    expect(literal.literal, isNotNull);
    expect(literal.value, double.parse(doubleLiteral));
  }

  void test_parsePrimaryExpression_false() {
    BooleanLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", "false", []);
    expect(literal.literal, isNotNull);
    expect(literal.value, isFalse);
  }

  void test_parsePrimaryExpression_function_arguments() {
    FunctionExpression expression = ParserTestCase.parse4("parsePrimaryExpression", "(int i) => i + 1", []);
    expect(expression.parameters, isNotNull);
    expect(expression.body, isNotNull);
  }

  void test_parsePrimaryExpression_function_noArguments() {
    FunctionExpression expression = ParserTestCase.parse4("parsePrimaryExpression", "() => 42", []);
    expect(expression.parameters, isNotNull);
    expect(expression.body, isNotNull);
  }

  void test_parsePrimaryExpression_hex() {
    String hexLiteral = "3F";
    IntegerLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", "0x$hexLiteral", []);
    expect(literal.literal, isNotNull);
    expect(literal.value, int.parse(hexLiteral, radix: 16));
  }

  void test_parsePrimaryExpression_identifier() {
    SimpleIdentifier identifier = ParserTestCase.parse4("parsePrimaryExpression", "a", []);
    expect(identifier, isNotNull);
  }

  void test_parsePrimaryExpression_int() {
    String intLiteral = "472";
    IntegerLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", intLiteral, []);
    expect(literal.literal, isNotNull);
    expect(literal.value, int.parse(intLiteral));
  }

  void test_parsePrimaryExpression_listLiteral() {
    ListLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", "[ ]", []);
    expect(literal, isNotNull);
  }

  void test_parsePrimaryExpression_listLiteral_index() {
    ListLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", "[]", []);
    expect(literal, isNotNull);
  }

  void test_parsePrimaryExpression_listLiteral_typed() {
    ListLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", "<A>[ ]", []);
    expect(literal.typeArguments, isNotNull);
    expect(literal.typeArguments.arguments, hasLength(1));
  }

  void test_parsePrimaryExpression_mapLiteral() {
    MapLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", "{}", []);
    expect(literal, isNotNull);
  }

  void test_parsePrimaryExpression_mapLiteral_typed() {
    MapLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", "<A, B>{}", []);
    expect(literal.typeArguments, isNotNull);
    expect(literal.typeArguments.arguments, hasLength(2));
  }

  void test_parsePrimaryExpression_new() {
    InstanceCreationExpression expression = ParserTestCase.parse4("parsePrimaryExpression", "new A()", []);
    expect(expression, isNotNull);
  }

  void test_parsePrimaryExpression_null() {
    NullLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", "null", []);
    expect(literal.literal, isNotNull);
  }

  void test_parsePrimaryExpression_parenthesized() {
    ParenthesizedExpression expression = ParserTestCase.parse4("parsePrimaryExpression", "(x)", []);
    expect(expression, isNotNull);
  }

  void test_parsePrimaryExpression_string() {
    SimpleStringLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", "\"string\"", []);
    expect(literal.isMultiline, isFalse);
    expect(literal.isRaw, isFalse);
    expect(literal.value, "string");
  }

  void test_parsePrimaryExpression_string_multiline() {
    SimpleStringLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", "'''string'''", []);
    expect(literal.isMultiline, isTrue);
    expect(literal.isRaw, isFalse);
    expect(literal.value, "string");
  }

  void test_parsePrimaryExpression_string_raw() {
    SimpleStringLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", "r'string'", []);
    expect(literal.isMultiline, isFalse);
    expect(literal.isRaw, isTrue);
    expect(literal.value, "string");
  }

  void test_parsePrimaryExpression_super() {
    PropertyAccess propertyAccess = ParserTestCase.parse4("parsePrimaryExpression", "super.x", []);
    expect(propertyAccess.target is SuperExpression, isTrue);
    expect(propertyAccess.operator, isNotNull);
    expect(propertyAccess.operator.type, TokenType.PERIOD);
    expect(propertyAccess.propertyName, isNotNull);
  }

  void test_parsePrimaryExpression_this() {
    ThisExpression expression = ParserTestCase.parse4("parsePrimaryExpression", "this", []);
    expect(expression.keyword, isNotNull);
  }

  void test_parsePrimaryExpression_true() {
    BooleanLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", "true", []);
    expect(literal.literal, isNotNull);
    expect(literal.value, isTrue);
  }

  void test_Parser() {
    expect(new Parser(null, null), isNotNull);
  }

  void test_parseRedirectingConstructorInvocation_named() {
    RedirectingConstructorInvocation invocation = ParserTestCase.parse4("parseRedirectingConstructorInvocation", "this.a()", []);
    expect(invocation.argumentList, isNotNull);
    expect(invocation.constructorName, isNotNull);
    expect(invocation.keyword, isNotNull);
    expect(invocation.period, isNotNull);
  }

  void test_parseRedirectingConstructorInvocation_unnamed() {
    RedirectingConstructorInvocation invocation = ParserTestCase.parse4("parseRedirectingConstructorInvocation", "this()", []);
    expect(invocation.argumentList, isNotNull);
    expect(invocation.constructorName, isNull);
    expect(invocation.keyword, isNotNull);
    expect(invocation.period, isNull);
  }

  void test_parseRelationalExpression_as() {
    AsExpression expression = ParserTestCase.parse4("parseRelationalExpression", "x as Y", []);
    expect(expression.expression, isNotNull);
    expect(expression.asOperator, isNotNull);
    expect(expression.type, isNotNull);
  }

  void test_parseRelationalExpression_is() {
    IsExpression expression = ParserTestCase.parse4("parseRelationalExpression", "x is y", []);
    expect(expression.expression, isNotNull);
    expect(expression.isOperator, isNotNull);
    expect(expression.notOperator, isNull);
    expect(expression.type, isNotNull);
  }

  void test_parseRelationalExpression_isNot() {
    IsExpression expression = ParserTestCase.parse4("parseRelationalExpression", "x is! y", []);
    expect(expression.expression, isNotNull);
    expect(expression.isOperator, isNotNull);
    expect(expression.notOperator, isNotNull);
    expect(expression.type, isNotNull);
  }

  void test_parseRelationalExpression_normal() {
    BinaryExpression expression = ParserTestCase.parse4("parseRelationalExpression", "x < y", []);
    expect(expression.leftOperand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.LT);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseRelationalExpression_super() {
    BinaryExpression expression = ParserTestCase.parse4("parseRelationalExpression", "super < y", []);
    expect(expression.leftOperand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.LT);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseRethrowExpression() {
    RethrowExpression expression = ParserTestCase.parse4("parseRethrowExpression", "rethrow;", []);
    expect(expression.keyword, isNotNull);
  }

  void test_parseReturnStatement_noValue() {
    ReturnStatement statement = ParserTestCase.parse4("parseReturnStatement", "return;", []);
    expect(statement.keyword, isNotNull);
    expect(statement.expression, isNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseReturnStatement_value() {
    ReturnStatement statement = ParserTestCase.parse4("parseReturnStatement", "return x;", []);
    expect(statement.keyword, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseReturnType_nonVoid() {
    TypeName typeName = ParserTestCase.parse4("parseReturnType", "A<B>", []);
    expect(typeName.name, isNotNull);
    expect(typeName.typeArguments, isNotNull);
  }

  void test_parseReturnType_void() {
    TypeName typeName = ParserTestCase.parse4("parseReturnType", "void", []);
    expect(typeName.name, isNotNull);
    expect(typeName.typeArguments, isNull);
  }

  void test_parseSetter_nonStatic() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    TypeName returnType = new TypeName(new SimpleIdentifier(null), null);
    MethodDeclaration method = ParserTestCase.parse("parseSetter", <Object> [commentAndMetadata(comment, []), null, null, returnType], "set a(var x);");
    expect(method.body, isNotNull);
    expect(method.documentationComment, comment);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, isNull);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.parameters, isNotNull);
    expect(method.propertyKeyword, isNotNull);
    expect(method.returnType, returnType);
  }

  void test_parseSetter_static() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    Token staticKeyword = TokenFactory.tokenFromKeyword(Keyword.STATIC);
    TypeName returnType = new TypeName(new SimpleIdentifier(null), null);
    MethodDeclaration method = ParserTestCase.parse("parseSetter", <Object> [
        commentAndMetadata(comment, []),
        null,
        staticKeyword,
        returnType], "set a(var x) {}");
    expect(method.body, isNotNull);
    expect(method.documentationComment, comment);
    expect(method.externalKeyword, isNull);
    expect(method.modifierKeyword, staticKeyword);
    expect(method.name, isNotNull);
    expect(method.operatorKeyword, isNull);
    expect(method.parameters, isNotNull);
    expect(method.propertyKeyword, isNotNull);
    expect(method.returnType, returnType);
  }

  void test_parseShiftExpression_normal() {
    BinaryExpression expression = ParserTestCase.parse4("parseShiftExpression", "x << y", []);
    expect(expression.leftOperand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.LT_LT);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseShiftExpression_super() {
    BinaryExpression expression = ParserTestCase.parse4("parseShiftExpression", "super << y", []);
    expect(expression.leftOperand, isNotNull);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.LT_LT);
    expect(expression.rightOperand, isNotNull);
  }

  void test_parseSimpleIdentifier_builtInIdentifier() {
    String lexeme = "as";
    SimpleIdentifier identifier = ParserTestCase.parse4("parseSimpleIdentifier", lexeme, []);
    expect(identifier.token, isNotNull);
    expect(identifier.name, lexeme);
  }

  void test_parseSimpleIdentifier_normalIdentifier() {
    String lexeme = "foo";
    SimpleIdentifier identifier = ParserTestCase.parse4("parseSimpleIdentifier", lexeme, []);
    expect(identifier.token, isNotNull);
    expect(identifier.name, lexeme);
  }

  void test_parseSimpleIdentifier1_normalIdentifier() {
    // TODO(brianwilkerson) Implement tests for this method.
  }

  void test_parseStatement_functionDeclaration() {
    // TODO(brianwilkerson) Implement more tests for this method.
    FunctionDeclarationStatement statement = ParserTestCase.parse4("parseStatement", "int f(a, b) {};", []);
    expect(statement.functionDeclaration, isNotNull);
  }

  void test_parseStatement_mulipleLabels() {
    LabeledStatement statement = ParserTestCase.parse4("parseStatement", "l: m: return x;", []);
    expect(statement.labels, hasLength(2));
    expect(statement.statement, isNotNull);
  }

  void test_parseStatement_noLabels() {
    ParserTestCase.parse4("parseStatement", "return x;", []);
  }

  void test_parseStatement_singleLabel() {
    LabeledStatement statement = ParserTestCase.parse4("parseStatement", "l: return x;", []);
    expect(statement.labels, hasLength(1));
    expect(statement.statement, isNotNull);
  }

  void test_parseStatements_multiple() {
    List<Statement> statements = ParserTestCase.parseStatements("return; return;", 2, []);
    expect(statements, hasLength(2));
  }

  void test_parseStatements_single() {
    List<Statement> statements = ParserTestCase.parseStatements("return;", 1, []);
    expect(statements, hasLength(1));
  }

  void test_parseStringLiteral_adjacent() {
    AdjacentStrings literal = ParserTestCase.parse4("parseStringLiteral", "'a' 'b'", []);
    NodeList<StringLiteral> strings = literal.strings;
    expect(strings, hasLength(2));
    StringLiteral firstString = strings[0];
    StringLiteral secondString = strings[1];
    expect((firstString as SimpleStringLiteral).value, "a");
    expect((secondString as SimpleStringLiteral).value, "b");
  }

  void test_parseStringLiteral_interpolated() {
    StringInterpolation literal = ParserTestCase.parse4("parseStringLiteral", "'a \${b} c \$this d'", []);
    NodeList<InterpolationElement> elements = literal.elements;
    expect(elements, hasLength(5));
    expect(elements[0] is InterpolationString, isTrue);
    expect(elements[1] is InterpolationExpression, isTrue);
    expect(elements[2] is InterpolationString, isTrue);
    expect(elements[3] is InterpolationExpression, isTrue);
    expect(elements[4] is InterpolationString, isTrue);
  }

  void test_parseStringLiteral_single() {
    SimpleStringLiteral literal = ParserTestCase.parse4("parseStringLiteral", "'a'", []);
    expect(literal.literal, isNotNull);
    expect(literal.value, "a");
  }

  void test_parseSuperConstructorInvocation_named() {
    SuperConstructorInvocation invocation = ParserTestCase.parse4("parseSuperConstructorInvocation", "super.a()", []);
    expect(invocation.argumentList, isNotNull);
    expect(invocation.constructorName, isNotNull);
    expect(invocation.keyword, isNotNull);
    expect(invocation.period, isNotNull);
  }

  void test_parseSuperConstructorInvocation_unnamed() {
    SuperConstructorInvocation invocation = ParserTestCase.parse4("parseSuperConstructorInvocation", "super()", []);
    expect(invocation.argumentList, isNotNull);
    expect(invocation.constructorName, isNull);
    expect(invocation.keyword, isNotNull);
    expect(invocation.period, isNull);
  }

  void test_parseSwitchStatement_case() {
    SwitchStatement statement = ParserTestCase.parse4("parseSwitchStatement", "switch (a) {case 1: return 'I';}", []);
    expect(statement.keyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.leftBracket, isNotNull);
    expect(statement.members, hasLength(1));
    expect(statement.rightBracket, isNotNull);
  }

  void test_parseSwitchStatement_empty() {
    SwitchStatement statement = ParserTestCase.parse4("parseSwitchStatement", "switch (a) {}", []);
    expect(statement.keyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.leftBracket, isNotNull);
    expect(statement.members, hasLength(0));
    expect(statement.rightBracket, isNotNull);
  }

  void test_parseSwitchStatement_labeledCase() {
    SwitchStatement statement = ParserTestCase.parse4("parseSwitchStatement", "switch (a) {l1: l2: l3: case(1):}", []);
    expect(statement.keyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.leftBracket, isNotNull);
    expect(statement.members, hasLength(1));
    expect(statement.members[0].labels, hasLength(3));
    expect(statement.rightBracket, isNotNull);
  }

  void test_parseSwitchStatement_labeledStatementInCase() {
    SwitchStatement statement = ParserTestCase.parse4("parseSwitchStatement", "switch (a) {case 0: f(); l1: g(); break;}", []);
    expect(statement.keyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.leftBracket, isNotNull);
    expect(statement.members, hasLength(1));
    expect(statement.members[0].statements, hasLength(3));
    expect(statement.rightBracket, isNotNull);
  }

  void test_parseSymbolLiteral_builtInIdentifier() {
    SymbolLiteral literal = ParserTestCase.parse4("parseSymbolLiteral", "#dynamic.static.abstract", []);
    expect(literal.poundSign, isNotNull);
    List<Token> components = literal.components;
    expect(components, hasLength(3));
    expect(components[0].lexeme, "dynamic");
    expect(components[1].lexeme, "static");
    expect(components[2].lexeme, "abstract");
  }

  void test_parseSymbolLiteral_multiple() {
    SymbolLiteral literal = ParserTestCase.parse4("parseSymbolLiteral", "#a.b.c", []);
    expect(literal.poundSign, isNotNull);
    List<Token> components = literal.components;
    expect(components, hasLength(3));
    expect(components[0].lexeme, "a");
    expect(components[1].lexeme, "b");
    expect(components[2].lexeme, "c");
  }

  void test_parseSymbolLiteral_operator() {
    SymbolLiteral literal = ParserTestCase.parse4("parseSymbolLiteral", "#==", []);
    expect(literal.poundSign, isNotNull);
    List<Token> components = literal.components;
    expect(components, hasLength(1));
    expect(components[0].lexeme, "==");
  }

  void test_parseSymbolLiteral_single() {
    SymbolLiteral literal = ParserTestCase.parse4("parseSymbolLiteral", "#a", []);
    expect(literal.poundSign, isNotNull);
    List<Token> components = literal.components;
    expect(components, hasLength(1));
    expect(components[0].lexeme, "a");
  }

  void test_parseSymbolLiteral_void() {
    SymbolLiteral literal = ParserTestCase.parse4("parseSymbolLiteral", "#void", []);
    expect(literal.poundSign, isNotNull);
    List<Token> components = literal.components;
    expect(components, hasLength(1));
    expect(components[0].lexeme, "void");
  }

  void test_parseThrowExpression() {
    ThrowExpression expression = ParserTestCase.parse4("parseThrowExpression", "throw x;", []);
    expect(expression.keyword, isNotNull);
    expect(expression.expression, isNotNull);
  }

  void test_parseThrowExpressionWithoutCascade() {
    ThrowExpression expression = ParserTestCase.parse4("parseThrowExpressionWithoutCascade", "throw x;", []);
    expect(expression.keyword, isNotNull);
    expect(expression.expression, isNotNull);
  }

  void test_parseTryStatement_catch() {
    TryStatement statement = ParserTestCase.parse4("parseTryStatement", "try {} catch (e) {}", []);
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
    TryStatement statement = ParserTestCase.parse4("parseTryStatement", "try {} catch (e, s) {} finally {}", []);
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
    TryStatement statement = ParserTestCase.parse4("parseTryStatement", "try {} finally {}", []);
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    expect(statement.catchClauses, hasLength(0));
    expect(statement.finallyKeyword, isNotNull);
    expect(statement.finallyBlock, isNotNull);
  }

  void test_parseTryStatement_multiple() {
    TryStatement statement = ParserTestCase.parse4("parseTryStatement", "try {} on NPE catch (e) {} on Error {} catch (e) {}", []);
    expect(statement.tryKeyword, isNotNull);
    expect(statement.body, isNotNull);
    expect(statement.catchClauses, hasLength(3));
    expect(statement.finallyKeyword, isNull);
    expect(statement.finallyBlock, isNull);
  }

  void test_parseTryStatement_on() {
    TryStatement statement = ParserTestCase.parse4("parseTryStatement", "try {} on Error {}", []);
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
    TryStatement statement = ParserTestCase.parse4("parseTryStatement", "try {} on Error catch (e, s) {}", []);
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
    TryStatement statement = ParserTestCase.parse4("parseTryStatement", "try {} on Error catch (e, s) {} finally {}", []);
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
    FunctionTypeAlias typeAlias = ParserTestCase.parse("parseTypeAlias", <Object> [emptyCommentAndMetadata()], "typedef bool F();");
    expect(typeAlias.keyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.parameters, isNotNull);
    expect(typeAlias.returnType, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    expect(typeAlias.typeParameters, isNull);
  }

  void test_parseTypeAlias_function_noReturnType() {
    FunctionTypeAlias typeAlias = ParserTestCase.parse("parseTypeAlias", <Object> [emptyCommentAndMetadata()], "typedef F();");
    expect(typeAlias.keyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.parameters, isNotNull);
    expect(typeAlias.returnType, isNull);
    expect(typeAlias.semicolon, isNotNull);
    expect(typeAlias.typeParameters, isNull);
  }

  void test_parseTypeAlias_function_parameterizedReturnType() {
    FunctionTypeAlias typeAlias = ParserTestCase.parse("parseTypeAlias", <Object> [emptyCommentAndMetadata()], "typedef A<B> F();");
    expect(typeAlias.keyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.parameters, isNotNull);
    expect(typeAlias.returnType, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    expect(typeAlias.typeParameters, isNull);
  }

  void test_parseTypeAlias_function_parameters() {
    FunctionTypeAlias typeAlias = ParserTestCase.parse("parseTypeAlias", <Object> [emptyCommentAndMetadata()], "typedef bool F(Object value);");
    expect(typeAlias.keyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.parameters, isNotNull);
    expect(typeAlias.returnType, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    expect(typeAlias.typeParameters, isNull);
  }

  void test_parseTypeAlias_function_typeParameters() {
    FunctionTypeAlias typeAlias = ParserTestCase.parse("parseTypeAlias", <Object> [emptyCommentAndMetadata()], "typedef bool F<E>();");
    expect(typeAlias.keyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.parameters, isNotNull);
    expect(typeAlias.returnType, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    expect(typeAlias.typeParameters, isNotNull);
  }

  void test_parseTypeAlias_function_voidReturnType() {
    FunctionTypeAlias typeAlias = ParserTestCase.parse("parseTypeAlias", <Object> [emptyCommentAndMetadata()], "typedef void F();");
    expect(typeAlias.keyword, isNotNull);
    expect(typeAlias.name, isNotNull);
    expect(typeAlias.parameters, isNotNull);
    expect(typeAlias.returnType, isNotNull);
    expect(typeAlias.semicolon, isNotNull);
    expect(typeAlias.typeParameters, isNull);
  }

  void test_parseTypeArgumentList_multiple() {
    TypeArgumentList argumentList = ParserTestCase.parse4("parseTypeArgumentList", "<int, int, int>", []);
    expect(argumentList.leftBracket, isNotNull);
    expect(argumentList.arguments, hasLength(3));
    expect(argumentList.rightBracket, isNotNull);
  }

  void test_parseTypeArgumentList_nested() {
    TypeArgumentList argumentList = ParserTestCase.parse4("parseTypeArgumentList", "<A<B>>", []);
    expect(argumentList.leftBracket, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    TypeName argument = argumentList.arguments[0];
    expect(argument, isNotNull);
    TypeArgumentList innerList = argument.typeArguments;
    expect(innerList, isNotNull);
    expect(innerList.arguments, hasLength(1));
    expect(argumentList.rightBracket, isNotNull);
  }

  void test_parseTypeArgumentList_single() {
    TypeArgumentList argumentList = ParserTestCase.parse4("parseTypeArgumentList", "<int>", []);
    expect(argumentList.leftBracket, isNotNull);
    expect(argumentList.arguments, hasLength(1));
    expect(argumentList.rightBracket, isNotNull);
  }

  void test_parseTypeName_parameterized() {
    TypeName typeName = ParserTestCase.parse4("parseTypeName", "List<int>", []);
    expect(typeName.name, isNotNull);
    expect(typeName.typeArguments, isNotNull);
  }

  void test_parseTypeName_simple() {
    TypeName typeName = ParserTestCase.parse4("parseTypeName", "int", []);
    expect(typeName.name, isNotNull);
    expect(typeName.typeArguments, isNull);
  }

  void test_parseTypeParameter_bounded() {
    TypeParameter parameter = ParserTestCase.parse4("parseTypeParameter", "A extends B", []);
    expect(parameter.bound, isNotNull);
    expect(parameter.keyword, isNotNull);
    expect(parameter.name, isNotNull);
  }

  void test_parseTypeParameter_simple() {
    TypeParameter parameter = ParserTestCase.parse4("parseTypeParameter", "A", []);
    expect(parameter.bound, isNull);
    expect(parameter.keyword, isNull);
    expect(parameter.name, isNotNull);
  }

  void test_parseTypeParameterList_multiple() {
    TypeParameterList parameterList = ParserTestCase.parse4("parseTypeParameterList", "<A, B extends C, D>", []);
    expect(parameterList.leftBracket, isNotNull);
    expect(parameterList.rightBracket, isNotNull);
    expect(parameterList.typeParameters, hasLength(3));
  }

  void test_parseTypeParameterList_parameterizedWithTrailingEquals() {
    TypeParameterList parameterList = ParserTestCase.parse4("parseTypeParameterList", "<A extends B<E>>=", []);
    expect(parameterList.leftBracket, isNotNull);
    expect(parameterList.rightBracket, isNotNull);
    expect(parameterList.typeParameters, hasLength(1));
  }

  void test_parseTypeParameterList_single() {
    TypeParameterList parameterList = ParserTestCase.parse4("parseTypeParameterList", "<A>", []);
    expect(parameterList.leftBracket, isNotNull);
    expect(parameterList.rightBracket, isNotNull);
    expect(parameterList.typeParameters, hasLength(1));
  }

  void test_parseTypeParameterList_withTrailingEquals() {
    TypeParameterList parameterList = ParserTestCase.parse4("parseTypeParameterList", "<A>=", []);
    expect(parameterList.leftBracket, isNotNull);
    expect(parameterList.rightBracket, isNotNull);
    expect(parameterList.typeParameters, hasLength(1));
  }

  void test_parseUnaryExpression_decrement_normal() {
    PrefixExpression expression = ParserTestCase.parse4("parseUnaryExpression", "--x", []);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS_MINUS);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_decrement_super() {
    PrefixExpression expression = ParserTestCase.parse4("parseUnaryExpression", "--super", []);
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
    PrefixExpression expression = ParserTestCase.parse4("parseUnaryExpression", "--super.x", []);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS_MINUS);
    expect(expression.operand, isNotNull);
    PropertyAccess operand = expression.operand as PropertyAccess;
    expect(operand.target is SuperExpression, isTrue);
    expect(operand.propertyName.name, "x");
  }

  void test_parseUnaryExpression_increment_normal() {
    PrefixExpression expression = ParserTestCase.parse4("parseUnaryExpression", "++x", []);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.PLUS_PLUS);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_increment_super_index() {
    PrefixExpression expression = ParserTestCase.parse4("parseUnaryExpression", "++super[0]", []);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.PLUS_PLUS);
    expect(expression.operand, isNotNull);
    IndexExpression operand = expression.operand as IndexExpression;
    expect(operand.realTarget is SuperExpression, isTrue);
    expect(operand.index is IntegerLiteral, isTrue);
  }

  void test_parseUnaryExpression_increment_super_propertyAccess() {
    PrefixExpression expression = ParserTestCase.parse4("parseUnaryExpression", "++super.x", []);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.PLUS_PLUS);
    expect(expression.operand, isNotNull);
    PropertyAccess operand = expression.operand as PropertyAccess;
    expect(operand.target is SuperExpression, isTrue);
    expect(operand.propertyName.name, "x");
  }

  void test_parseUnaryExpression_minus_normal() {
    PrefixExpression expression = ParserTestCase.parse4("parseUnaryExpression", "-x", []);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_minus_super() {
    PrefixExpression expression = ParserTestCase.parse4("parseUnaryExpression", "-super", []);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.MINUS);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_not_normal() {
    PrefixExpression expression = ParserTestCase.parse4("parseUnaryExpression", "!x", []);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.BANG);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_not_super() {
    PrefixExpression expression = ParserTestCase.parse4("parseUnaryExpression", "!super", []);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.BANG);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_tilda_normal() {
    PrefixExpression expression = ParserTestCase.parse4("parseUnaryExpression", "~x", []);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.TILDE);
    expect(expression.operand, isNotNull);
  }

  void test_parseUnaryExpression_tilda_super() {
    PrefixExpression expression = ParserTestCase.parse4("parseUnaryExpression", "~super", []);
    expect(expression.operator, isNotNull);
    expect(expression.operator.type, TokenType.TILDE);
    expect(expression.operand, isNotNull);
  }

  void test_parseVariableDeclaration_equals() {
    VariableDeclaration declaration = ParserTestCase.parse4("parseVariableDeclaration", "a = b", []);
    expect(declaration.name, isNotNull);
    expect(declaration.equals, isNotNull);
    expect(declaration.initializer, isNotNull);
  }

  void test_parseVariableDeclaration_noEquals() {
    VariableDeclaration declaration = ParserTestCase.parse4("parseVariableDeclaration", "a", []);
    expect(declaration.name, isNotNull);
    expect(declaration.equals, isNull);
    expect(declaration.initializer, isNull);
  }

  void test_parseVariableDeclarationListAfterMetadata_const_noType() {
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationListAfterMetadata", <Object> [emptyCommentAndMetadata()], "const a");
    expect(declarationList.keyword, isNotNull);
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterMetadata_const_type() {
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationListAfterMetadata", <Object> [emptyCommentAndMetadata()], "const A a");
    expect(declarationList.keyword, isNotNull);
    expect(declarationList.type, isNotNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterMetadata_final_noType() {
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationListAfterMetadata", <Object> [emptyCommentAndMetadata()], "final a");
    expect(declarationList.keyword, isNotNull);
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterMetadata_final_type() {
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationListAfterMetadata", <Object> [emptyCommentAndMetadata()], "final A a");
    expect(declarationList.keyword, isNotNull);
    expect(declarationList.type, isNotNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterMetadata_type_multiple() {
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationListAfterMetadata", <Object> [emptyCommentAndMetadata()], "A a, b, c");
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, isNotNull);
    expect(declarationList.variables, hasLength(3));
  }

  void test_parseVariableDeclarationListAfterMetadata_type_single() {
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationListAfterMetadata", <Object> [emptyCommentAndMetadata()], "A a");
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, isNotNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterMetadata_var_multiple() {
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationListAfterMetadata", <Object> [emptyCommentAndMetadata()], "var a, b, c");
    expect(declarationList.keyword, isNotNull);
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(3));
  }

  void test_parseVariableDeclarationListAfterMetadata_var_single() {
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationListAfterMetadata", <Object> [emptyCommentAndMetadata()], "var a");
    expect(declarationList.keyword, isNotNull);
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterType_type() {
    TypeName type = new TypeName(new SimpleIdentifier(null), null);
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationListAfterType", <Object> [emptyCommentAndMetadata(), null, type], "a");
    expect(declarationList.keyword, isNull);
    expect(declarationList.type, type);
    expect(declarationList.variables, hasLength(1));
  }

  void test_parseVariableDeclarationListAfterType_var() {
    Token keyword = TokenFactory.tokenFromKeyword(Keyword.VAR);
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationListAfterType", <Object> [emptyCommentAndMetadata(), keyword, null], "a, b, c");
    expect(declarationList.keyword, keyword);
    expect(declarationList.type, isNull);
    expect(declarationList.variables, hasLength(3));
  }

  void test_parseVariableDeclarationStatementAfterMetadata_multiple() {
    VariableDeclarationStatement statement = ParserTestCase.parse("parseVariableDeclarationStatementAfterMetadata", <Object> [emptyCommentAndMetadata()], "var x, y, z;");
    expect(statement.semicolon, isNotNull);
    VariableDeclarationList variableList = statement.variables;
    expect(variableList, isNotNull);
    expect(variableList.variables, hasLength(3));
  }

  void test_parseVariableDeclarationStatementAfterMetadata_single() {
    VariableDeclarationStatement statement = ParserTestCase.parse("parseVariableDeclarationStatementAfterMetadata", <Object> [emptyCommentAndMetadata()], "var x;");
    expect(statement.semicolon, isNotNull);
    VariableDeclarationList variableList = statement.variables;
    expect(variableList, isNotNull);
    expect(variableList.variables, hasLength(1));
  }

  void test_parseWhileStatement() {
    WhileStatement statement = ParserTestCase.parse4("parseWhileStatement", "while (x) {}", []);
    expect(statement.keyword, isNotNull);
    expect(statement.leftParenthesis, isNotNull);
    expect(statement.condition, isNotNull);
    expect(statement.rightParenthesis, isNotNull);
    expect(statement.body, isNotNull);
  }

  void test_parseWithClause_multiple() {
    WithClause clause = ParserTestCase.parse4("parseWithClause", "with A, B, C", []);
    expect(clause.withKeyword, isNotNull);
    expect(clause.mixinTypes, hasLength(3));
  }

  void test_parseWithClause_single() {
    WithClause clause = ParserTestCase.parse4("parseWithClause", "with M", []);
    expect(clause.withKeyword, isNotNull);
    expect(clause.mixinTypes, hasLength(1));
  }

  void test_parseYieldStatement_each() {
    YieldStatement statement = ParserTestCase.parse4("parseYieldStatement", "yield* x;", []);
    expect(statement.yieldKeyword, isNotNull);
    expect(statement.star, isNotNull);
    expect(statement.expression, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_parseYieldStatement_normal() {
    YieldStatement statement = ParserTestCase.parse4("parseYieldStatement", "yield x;", []);
    expect(statement.yieldKeyword, isNotNull);
    expect(statement.star, isNull);
    expect(statement.expression, isNotNull);
    expect(statement.semicolon, isNotNull);
  }

  void test_skipPrefixedIdentifier_invalid() {
    Token following = _skip("skipPrefixedIdentifier", "+");
    expect(following, isNull);
  }

  void test_skipPrefixedIdentifier_notPrefixed() {
    Token following = _skip("skipPrefixedIdentifier", "a +");
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipPrefixedIdentifier_prefixed() {
    Token following = _skip("skipPrefixedIdentifier", "a.b +");
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipReturnType_invalid() {
    Token following = _skip("skipReturnType", "+");
    expect(following, isNull);
  }

  void test_skipReturnType_type() {
    Token following = _skip("skipReturnType", "C +");
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipReturnType_void() {
    Token following = _skip("skipReturnType", "void +");
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipSimpleIdentifier_identifier() {
    Token following = _skip("skipSimpleIdentifier", "i +");
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipSimpleIdentifier_invalid() {
    Token following = _skip("skipSimpleIdentifier", "9 +");
    expect(following, isNull);
  }

  void test_skipSimpleIdentifier_pseudoKeyword() {
    Token following = _skip("skipSimpleIdentifier", "as +");
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipStringLiteral_adjacent() {
    Token following = _skip("skipStringLiteral", "'a' 'b' +");
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipStringLiteral_interpolated() {
    Token following = _skip("skipStringLiteral", "'a\${b}c' +");
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipStringLiteral_invalid() {
    Token following = _skip("skipStringLiteral", "a");
    expect(following, isNull);
  }

  void test_skipStringLiteral_single() {
    Token following = _skip("skipStringLiteral", "'a' +");
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipTypeArgumentList_invalid() {
    Token following = _skip("skipTypeArgumentList", "+");
    expect(following, isNull);
  }

  void test_skipTypeArgumentList_multiple() {
    Token following = _skip("skipTypeArgumentList", "<E, F, G> +");
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipTypeArgumentList_single() {
    Token following = _skip("skipTypeArgumentList", "<E> +");
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipTypeName_invalid() {
    Token following = _skip("skipTypeName", "+");
    expect(following, isNull);
  }

  void test_skipTypeName_parameterized() {
    Token following = _skip("skipTypeName", "C<E<F<G>>> +");
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  void test_skipTypeName_simple() {
    Token following = _skip("skipTypeName", "C +");
    expect(following, isNotNull);
    expect(following.type, TokenType.PLUS);
  }

  /**
   * Invoke the method [Parser#computeStringValue] with the given argument.
   *
   * @param lexeme the argument to the method
   * @param first `true` if this is the first token in a string literal
   * @param last `true` if this is the last token in a string literal
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   */
  String _computeStringValue(String lexeme, bool first, bool last) {
    AnalysisErrorListener listener = new AnalysisErrorListener_SimpleParserTest_computeStringValue();
    Parser parser = new Parser(null, listener);
    return invokeParserMethodImpl(parser, "computeStringValue", <Object> [lexeme, first, last], null) as String;
  }

  /**
   * Invoke the method [Parser#createSyntheticIdentifier] with the parser set to the token
   * stream produced by scanning the given source.
   *
   * @param source the source to be scanned to produce the token stream being tested
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   */
  SimpleIdentifier _createSyntheticIdentifier() {
    GatheringErrorListener listener = new GatheringErrorListener();
    return ParserTestCase.invokeParserMethod2("createSyntheticIdentifier", "", listener);
  }

  /**
   * Invoke the method [Parser#createSyntheticIdentifier] with the parser set to the token
   * stream produced by scanning the given source.
   *
   * @param source the source to be scanned to produce the token stream being tested
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   */
  SimpleStringLiteral _createSyntheticStringLiteral() {
    GatheringErrorListener listener = new GatheringErrorListener();
    return ParserTestCase.invokeParserMethod2("createSyntheticStringLiteral", "", listener);
  }

  /**
   * Invoke the method [Parser#isFunctionDeclaration] with the parser set to the token
   * stream produced by scanning the given source.
   *
   * @param source the source to be scanned to produce the token stream being tested
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   */
  bool _isFunctionDeclaration(String source) {
    GatheringErrorListener listener = new GatheringErrorListener();
    return ParserTestCase.invokeParserMethod2("isFunctionDeclaration", source, listener) as bool;
  }

  /**
   * Invoke the method [Parser#isFunctionExpression] with the parser set to the token stream
   * produced by scanning the given source.
   *
   * @param source the source to be scanned to produce the token stream being tested
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   */
  bool _isFunctionExpression(String source) {
    GatheringErrorListener listener = new GatheringErrorListener();
    //
    // Scan the source.
    //
    Scanner scanner = new Scanner(null, new CharSequenceReader(source), listener);
    Token tokenStream = scanner.tokenize();
    //
    // Parse the source.
    //
    Parser parser = new Parser(null, listener);
    return invokeParserMethodImpl(parser, "isFunctionExpression", <Object> [tokenStream], tokenStream) as bool;
  }

  /**
   * Invoke the method [Parser#isInitializedVariableDeclaration] with the parser set to the
   * token stream produced by scanning the given source.
   *
   * @param source the source to be scanned to produce the token stream being tested
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   */
  bool _isInitializedVariableDeclaration(String source) {
    GatheringErrorListener listener = new GatheringErrorListener();
    return ParserTestCase.invokeParserMethod2("isInitializedVariableDeclaration", source, listener) as bool;
  }

  /**
   * Invoke the method [Parser#isSwitchMember] with the parser set to the token stream
   * produced by scanning the given source.
   *
   * @param source the source to be scanned to produce the token stream being tested
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   */
  bool _isSwitchMember(String source) {
    GatheringErrorListener listener = new GatheringErrorListener();
    return ParserTestCase.invokeParserMethod2("isSwitchMember", source, listener) as bool;
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
  CompilationUnit _parseDirectives(String source, List<ErrorCode> errorCodes) {
    GatheringErrorListener listener = new GatheringErrorListener();
    Scanner scanner = new Scanner(null, new CharSequenceReader(source), listener);
    listener.setLineInfo(new TestSource(), scanner.lineStarts);
    Token token = scanner.tokenize();
    Parser parser = new Parser(null, listener);
    CompilationUnit unit = parser.parseDirectives(token);
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(0));
    listener.assertErrorsWithCodes(errorCodes);
    return unit;
  }

  /**
   * Invoke a "skip" method in [Parser]. The method is assumed to take a token as it's
   * parameter and is given the first token in the scanned source.
   *
   * @param methodName the name of the method that should be invoked
   * @param source the source to be processed by the method
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   * @throws AssertionFailedError if the result is `null`
   */
  Token _skip(String methodName, String source) {
    GatheringErrorListener listener = new GatheringErrorListener();
    //
    // Scan the source.
    //
    Scanner scanner = new Scanner(null, new CharSequenceReader(source), listener);
    Token tokenStream = scanner.tokenize();
    //
    // Parse the source.
    //
    Parser parser = new Parser(null, listener);
    return invokeParserMethodImpl(parser, methodName, <Object> [tokenStream], tokenStream) as Token;
  }
}

main() {
  groupSep = ' | ';
  runReflectiveTests(ComplexParserTest);
  runReflectiveTests(ErrorParserTest);
  runReflectiveTests(IncrementalParserTest);
  runReflectiveTests(NonErrorParserTest);
  runReflectiveTests(RecoveryParserTest);
  runReflectiveTests(ResolutionCopierTest);
  runReflectiveTests(SimpleParserTest);
}