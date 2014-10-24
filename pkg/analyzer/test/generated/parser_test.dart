// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.parser_test;

import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/java_junit.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:unittest/unittest.dart' as _ut;
import 'test_support.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';

import '../reflective_tests.dart';


class AnalysisErrorListener_SimpleParserTest_computeStringValue implements AnalysisErrorListener {
  @override
  void onError(AnalysisError event) {
    JUnitTestCase.fail("Unexpected compilation error: ${event.message} (${event.offset}, ${event.length})");
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
      JavaStringBuilder builder = new JavaStringBuilder();
      builder.append("Invalid AST structure:");
      for (String message in _errors) {
        builder.append("\r\n   ");
        builder.append(message);
      }
      JUnitTestCase.fail(builder.toString());
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
        _errors.add("Invalid source start (${nodeStart}) for ${node.runtimeType} inside ${parent.runtimeType} (${parentStart})");
      }
      if (nodeEnd > parentEnd) {
        _errors.add("Invalid source end (${nodeEnd}) for ${node.runtimeType} inside ${parent.runtimeType} (${parentStart})");
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
    JUnitTestCase.assertEquals("f", propertyAccess1.propertyName.name);
    //
    // a(b)(c).d(e)
    //
    MethodInvocation invocation2 = EngineTestCase.assertInstanceOf((obj) => obj is MethodInvocation, MethodInvocation, propertyAccess1.target);
    JUnitTestCase.assertEquals("d", invocation2.methodName.name);
    ArgumentList argumentList2 = invocation2.argumentList;
    JUnitTestCase.assertNotNull(argumentList2);
    EngineTestCase.assertSizeOfList(1, argumentList2.arguments);
    //
    // a(b)(c)
    //
    FunctionExpressionInvocation invocation3 = EngineTestCase.assertInstanceOf((obj) => obj is FunctionExpressionInvocation, FunctionExpressionInvocation, invocation2.target);
    ArgumentList argumentList3 = invocation3.argumentList;
    JUnitTestCase.assertNotNull(argumentList3);
    EngineTestCase.assertSizeOfList(1, argumentList3.arguments);
    //
    // a(b)
    //
    MethodInvocation invocation4 = EngineTestCase.assertInstanceOf((obj) => obj is MethodInvocation, MethodInvocation, invocation3.function);
    JUnitTestCase.assertEquals("a", invocation4.methodName.name);
    ArgumentList argumentList4 = invocation4.argumentList;
    JUnitTestCase.assertNotNull(argumentList4);
    EngineTestCase.assertSizeOfList(1, argumentList4.arguments);
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
      JUnitTestCase.assertTrue(index.isCascaded);
      JUnitTestCase.assertSame(target, index.realTarget);
    }
  }

  void test_conditionalExpression_precedence_logicalOrExpression() {
    ConditionalExpression expression = ParserTestCase.parseExpression("a | b ? y : z", []);
    EngineTestCase.assertInstanceOf((obj) => obj is BinaryExpression, BinaryExpression, expression.condition);
  }

  void test_constructor_initializer_withParenthesizedExpression() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(EngineTestCase.createSource([
        "class C {",
        "  C() :",
        "    this.a = (b == null ? c : d) {",
        "  }",
        "}"]), []);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    EngineTestCase.assertSizeOfList(1, declarations);
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
    EngineTestCase.assertSizeOfList(3, statement.labels);
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
    JUnitTestCase.assertTrue(literal.isSynthetic);
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
    JUnitTestCase.assertNotNull(unit);
  }

  void test_directiveAfterDeclaration_classBetweenDirectives() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("library l;\nclass Foo{}\npart 'a.dart';", [ParserErrorCode.DIRECTIVE_AFTER_DECLARATION]);
    JUnitTestCase.assertNotNull(unit);
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
    JUnitTestCase.assertTrue(expression.isSynthetic);
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
    JUnitTestCase.assertNotNull(semicolon);
    JUnitTestCase.assertTrue(semicolon.isSynthetic);
  }

  void test_expectedToken_semicolonMissingAfterExpression() {
    ParserTestCase.parseStatement("x", [ParserErrorCode.EXPECTED_TOKEN]);
  }

  void test_expectedToken_semicolonMissingAfterImport() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("import '' class A {}", [ParserErrorCode.EXPECTED_TOKEN]);
    ImportDirective directive = unit.directives[0] as ImportDirective;
    Token semicolon = directive.semicolon;
    JUnitTestCase.assertNotNull(semicolon);
    JUnitTestCase.assertTrue(semicolon.isSynthetic);
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
    JUnitTestCase.assertNotNull(unit);
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
    JUnitTestCase.assertNotNull(expression.keyword);
  }

  void test_missingAssignableSelector_superPropertyAccessAssigned() {
    ParserTestCase.parseExpression("super.x = x;", []);
  }

  void test_missingCatchOrFinally() {
    TryStatement statement = ParserTestCase.parse4("parseTryStatement", "try {}", [ParserErrorCode.MISSING_CATCH_OR_FINALLY]);
    JUnitTestCase.assertNotNull(statement);
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
    JUnitTestCase.assertTrue(expression.isSynthetic);
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
    JUnitTestCase.assertNotNull(unit);
  }

  void test_missingNameInPartOfDirective() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("part of;", [ParserErrorCode.MISSING_NAME_IN_PART_OF_DIRECTIVE]);
    JUnitTestCase.assertNotNull(unit);
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
    JUnitTestCase.assertNotNull(unit);
  }

  void test_nonIdentifierLibraryName_partOf() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("part of 'lib';", [ParserErrorCode.NON_IDENTIFIER_LIBRARY_NAME]);
    JUnitTestCase.assertNotNull(unit);
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
    JUnitTestCase.assertNull(methodInvocation.target);
    JUnitTestCase.assertEquals("", methodInvocation.methodName.name);
    EngineTestCase.assertSizeOfList(0, methodInvocation.argumentList.arguments);
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
    JUnitTestCase.assertTrue(expression.isSynthetic);
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
    String originalContents = "${prefix}${removed}${suffix}";
    String modifiedContents = "${prefix}${added}${suffix}";
    int replaceStart = prefix.length;
    Source source = new TestSource();
    //
    // Parse the original contents.
    //
    GatheringErrorListener originalListener = new GatheringErrorListener();
    Scanner originalScanner = new Scanner(source, new CharSequenceReader(originalContents), originalListener);
    Token originalTokens = originalScanner.tokenize();
    JUnitTestCase.assertNotNull(originalTokens);
    Parser originalParser = new Parser(source, originalListener);
    CompilationUnit originalUnit = originalParser.parseCompilationUnit(originalTokens);
    JUnitTestCase.assertNotNull(originalUnit);
    //
    // Parse the modified contents.
    //
    GatheringErrorListener modifiedListener = new GatheringErrorListener();
    Scanner modifiedScanner = new Scanner(source, new CharSequenceReader(modifiedContents), modifiedListener);
    Token modifiedTokens = modifiedScanner.tokenize();
    JUnitTestCase.assertNotNull(modifiedTokens);
    Parser modifiedParser = new Parser(source, modifiedListener);
    CompilationUnit modifiedUnit = modifiedParser.parseCompilationUnit(modifiedTokens);
    JUnitTestCase.assertNotNull(modifiedUnit);
    //
    // Incrementally parse the modified contents.
    //
    GatheringErrorListener incrementalListener = new GatheringErrorListener();
    IncrementalScanner incrementalScanner = new IncrementalScanner(source, new CharSequenceReader(modifiedContents), incrementalListener);
    Token incrementalTokens = incrementalScanner.rescan(originalTokens, replaceStart, removed.length, added.length);
    JUnitTestCase.assertNotNull(incrementalTokens);
    IncrementalParser incrementalParser = new IncrementalParser(source, incrementalScanner.tokenMap, incrementalListener);
    CompilationUnit incrementalUnit = incrementalParser.reparse(originalUnit, incrementalScanner.leftToken, incrementalScanner.rightToken, replaceStart, prefix.length + removed.length);
    JUnitTestCase.assertNotNull(incrementalUnit);
    //
    // Validate that the results of the incremental parse are the same as the full parse of the
    // modified source.
    //
    JUnitTestCase.assertTrue(AstComparator.equalNodes(modifiedUnit, incrementalUnit));
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
    JUnitTestCase.assertNotNull(unit);
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
    JUnitTestCase.assertNotNull(expression);
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
    JUnitTestCase.assertNotNull(statement);
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
    EngineTestCase.assertSizeOfList(expectedCount, statements);
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
      JUnitTestCase.assertNotNull(result);
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
    ParserTestCase.parseCompilationUnit(EngineTestCase.createSource([
        "Map<Symbol, convertStringToSymbolMap(Map<String, dynamic> map) {",
        "  if (map == null) return null;",
        "  Map<Symbol, dynamic> result = new Map<Symbol, dynamic>();",
        "  map.forEach((name, value) {",
        "    result[new Symbol(name)] = value;",
        "  });",
        "  return result;",
        "}"]), []);
  }

  void test_additiveExpression_missing_LHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("+ y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic);
  }

  void test_additiveExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("+", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
  }

  void test_additiveExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x +", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
  }

  void test_additiveExpression_missing_RHS_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super +", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
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
    JUnitTestCase.assertTrue(syntheticExpression.isSynthetic);
  }

  void test_assignmentExpression_missing_compound2() {
    AssignmentExpression expression = ParserTestCase.parseExpression("x = = 0", [ParserErrorCode.MISSING_IDENTIFIER]);
    Expression syntheticExpression = (expression.rightHandSide as AssignmentExpression).leftHandSide;
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, syntheticExpression);
    JUnitTestCase.assertTrue(syntheticExpression.isSynthetic);
  }

  void test_assignmentExpression_missing_compound3() {
    AssignmentExpression expression = ParserTestCase.parseExpression("x = y =", [ParserErrorCode.MISSING_IDENTIFIER]);
    Expression syntheticExpression = (expression.rightHandSide as AssignmentExpression).rightHandSide;
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, syntheticExpression);
    JUnitTestCase.assertTrue(syntheticExpression.isSynthetic);
  }

  void test_assignmentExpression_missing_LHS() {
    AssignmentExpression expression = ParserTestCase.parseExpression("= 0", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftHandSide);
    JUnitTestCase.assertTrue(expression.leftHandSide.isSynthetic);
  }

  void test_assignmentExpression_missing_RHS() {
    AssignmentExpression expression = ParserTestCase.parseExpression("x =", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftHandSide);
    JUnitTestCase.assertTrue(expression.rightHandSide.isSynthetic);
  }

  void test_bitwiseAndExpression_missing_LHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("& y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic);
  }

  void test_bitwiseAndExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("&", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
  }

  void test_bitwiseAndExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x &", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
  }

  void test_bitwiseAndExpression_missing_RHS_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super &", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
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
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic);
  }

  void test_bitwiseOrExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("|", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
  }

  void test_bitwiseOrExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x |", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
  }

  void test_bitwiseOrExpression_missing_RHS_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super |", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
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
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic);
  }

  void test_bitwiseXorExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("^", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
  }

  void test_bitwiseXorExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x ^", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
  }

  void test_bitwiseXorExpression_missing_RHS_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super ^", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
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
    ParserTestCase.parseCompilationUnit(EngineTestCase.createSource(["class A {}", "class B = Object with A {}"]), [ParserErrorCode.EXPECTED_TOKEN]);
  }

  void test_conditionalExpression_missingElse() {
    ConditionalExpression expression = ParserTestCase.parse4("parseConditionalExpression", "x ? y :", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.elseExpression);
    JUnitTestCase.assertTrue(expression.elseExpression.isSynthetic);
  }

  void test_conditionalExpression_missingThen() {
    ConditionalExpression expression = ParserTestCase.parse4("parseConditionalExpression", "x ? : z", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.thenExpression);
    JUnitTestCase.assertTrue(expression.thenExpression.isSynthetic);
  }

  void test_equalityExpression_missing_LHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("== y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic);
  }

  void test_equalityExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("==", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
  }

  void test_equalityExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x ==", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
  }

  void test_equalityExpression_missing_RHS_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super ==", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
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
    EngineTestCase.assertSizeOfList(4, result);
    Expression syntheticExpression = result[0];
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, syntheticExpression);
    JUnitTestCase.assertTrue(syntheticExpression.isSynthetic);
  }

  void test_expressionList_multiple_middle() {
    List<Expression> result = ParserTestCase.parse4("parseExpressionList", "1, 2, , 4", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertSizeOfList(4, result);
    Expression syntheticExpression = result[2];
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, syntheticExpression);
    JUnitTestCase.assertTrue(syntheticExpression.isSynthetic);
  }

  void test_expressionList_multiple_start() {
    List<Expression> result = ParserTestCase.parse4("parseExpressionList", "1, 2, 3,", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertSizeOfList(4, result);
    Expression syntheticExpression = result[3];
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, syntheticExpression);
    JUnitTestCase.assertTrue(syntheticExpression.isSynthetic);
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
    EngineTestCase.assertSizeOfList(1, vars);
    JUnitTestCase.assertEquals("v", vars[0].name.name);
  }

  void test_incomplete_topLevelVariable() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("String", [ParserErrorCode.EXPECTED_EXECUTABLE]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    EngineTestCase.assertSizeOfList(1, declarations);
    CompilationUnitMember member = declarations[0];
    EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableDeclaration, TopLevelVariableDeclaration, member);
    NodeList<VariableDeclaration> variables = (member as TopLevelVariableDeclaration).variables.variables;
    EngineTestCase.assertSizeOfList(1, variables);
    SimpleIdentifier name = variables[0].name;
    JUnitTestCase.assertTrue(name.isSynthetic);
  }

  void test_incomplete_topLevelVariable_const() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("const ", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.EXPECTED_TOKEN]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    EngineTestCase.assertSizeOfList(1, declarations);
    CompilationUnitMember member = declarations[0];
    EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableDeclaration, TopLevelVariableDeclaration, member);
    NodeList<VariableDeclaration> variables = (member as TopLevelVariableDeclaration).variables.variables;
    EngineTestCase.assertSizeOfList(1, variables);
    SimpleIdentifier name = variables[0].name;
    JUnitTestCase.assertTrue(name.isSynthetic);
  }

  void test_incomplete_topLevelVariable_final() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("final ", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.EXPECTED_TOKEN]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    EngineTestCase.assertSizeOfList(1, declarations);
    CompilationUnitMember member = declarations[0];
    EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableDeclaration, TopLevelVariableDeclaration, member);
    NodeList<VariableDeclaration> variables = (member as TopLevelVariableDeclaration).variables.variables;
    EngineTestCase.assertSizeOfList(1, variables);
    SimpleIdentifier name = variables[0].name;
    JUnitTestCase.assertTrue(name.isSynthetic);
  }

  void test_incomplete_topLevelVariable_var() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("var ", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.EXPECTED_TOKEN]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    EngineTestCase.assertSizeOfList(1, declarations);
    CompilationUnitMember member = declarations[0];
    EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableDeclaration, TopLevelVariableDeclaration, member);
    NodeList<VariableDeclaration> variables = (member as TopLevelVariableDeclaration).variables.variables;
    EngineTestCase.assertSizeOfList(1, variables);
    SimpleIdentifier name = variables[0].name;
    JUnitTestCase.assertTrue(name.isSynthetic);
  }

  void test_incompleteField_const() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(EngineTestCase.createSource(["class C {", "  const", "}"]), [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.EXPECTED_TOKEN]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    EngineTestCase.assertSizeOfList(1, declarations);
    CompilationUnitMember unitMember = declarations[0];
    EngineTestCase.assertInstanceOf((obj) => obj is ClassDeclaration, ClassDeclaration, unitMember);
    NodeList<ClassMember> members = (unitMember as ClassDeclaration).members;
    EngineTestCase.assertSizeOfList(1, members);
    ClassMember classMember = members[0];
    EngineTestCase.assertInstanceOf((obj) => obj is FieldDeclaration, FieldDeclaration, classMember);
    VariableDeclarationList fieldList = (classMember as FieldDeclaration).fields;
    JUnitTestCase.assertEquals(Keyword.CONST, (fieldList.keyword as KeywordToken).keyword);
    NodeList<VariableDeclaration> fields = fieldList.variables;
    EngineTestCase.assertSizeOfList(1, fields);
    VariableDeclaration field = fields[0];
    JUnitTestCase.assertTrue(field.name.isSynthetic);
  }

  void test_incompleteField_final() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(EngineTestCase.createSource(["class C {", "  final", "}"]), [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.EXPECTED_TOKEN]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    EngineTestCase.assertSizeOfList(1, declarations);
    CompilationUnitMember unitMember = declarations[0];
    EngineTestCase.assertInstanceOf((obj) => obj is ClassDeclaration, ClassDeclaration, unitMember);
    NodeList<ClassMember> members = (unitMember as ClassDeclaration).members;
    EngineTestCase.assertSizeOfList(1, members);
    ClassMember classMember = members[0];
    EngineTestCase.assertInstanceOf((obj) => obj is FieldDeclaration, FieldDeclaration, classMember);
    VariableDeclarationList fieldList = (classMember as FieldDeclaration).fields;
    JUnitTestCase.assertEquals(Keyword.FINAL, (fieldList.keyword as KeywordToken).keyword);
    NodeList<VariableDeclaration> fields = fieldList.variables;
    EngineTestCase.assertSizeOfList(1, fields);
    VariableDeclaration field = fields[0];
    JUnitTestCase.assertTrue(field.name.isSynthetic);
  }

  void test_incompleteField_var() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(EngineTestCase.createSource(["class C {", "  var", "}"]), [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.EXPECTED_TOKEN]);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    EngineTestCase.assertSizeOfList(1, declarations);
    CompilationUnitMember unitMember = declarations[0];
    EngineTestCase.assertInstanceOf((obj) => obj is ClassDeclaration, ClassDeclaration, unitMember);
    NodeList<ClassMember> members = (unitMember as ClassDeclaration).members;
    EngineTestCase.assertSizeOfList(1, members);
    ClassMember classMember = members[0];
    EngineTestCase.assertInstanceOf((obj) => obj is FieldDeclaration, FieldDeclaration, classMember);
    VariableDeclarationList fieldList = (classMember as FieldDeclaration).fields;
    JUnitTestCase.assertEquals(Keyword.VAR, (fieldList.keyword as KeywordToken).keyword);
    NodeList<VariableDeclaration> fields = fieldList.variables;
    EngineTestCase.assertSizeOfList(1, fields);
    VariableDeclaration field = fields[0];
    JUnitTestCase.assertTrue(field.name.isSynthetic);
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
    JUnitTestCase.assertNotNull(expression.expression);
    JUnitTestCase.assertNotNull(expression.isOperator);
    JUnitTestCase.assertNotNull(expression.notOperator);
    TypeName type = expression.type;
    JUnitTestCase.assertNotNull(type);
    JUnitTestCase.assertTrue(type.name.isSynthetic);
    EngineTestCase.assertInstanceOf((obj) => obj is EmptyStatement, EmptyStatement, ifStatement.thenStatement);
  }

  void test_logicalAndExpression_missing_LHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("&& y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic);
  }

  void test_logicalAndExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("&&", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
  }

  void test_logicalAndExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x &&", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
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
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic);
  }

  void test_logicalOrExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("||", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
  }

  void test_logicalOrExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x ||", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
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
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(EngineTestCase.createSource(["class C {", "  int length {}", "  void foo() {}", "}"]), [ParserErrorCode.MISSING_GET]);
    JUnitTestCase.assertNotNull(unit);
    ClassDeclaration classDeclaration = unit.declarations[0] as ClassDeclaration;
    NodeList<ClassMember> members = classDeclaration.members;
    EngineTestCase.assertSizeOfList(2, members);
    EngineTestCase.assertInstanceOf((obj) => obj is MethodDeclaration, MethodDeclaration, members[0]);
    ClassMember member = members[1];
    EngineTestCase.assertInstanceOf((obj) => obj is MethodDeclaration, MethodDeclaration, member);
    JUnitTestCase.assertEquals("foo", (member as MethodDeclaration).name.name);
  }

  void test_missingIdentifier_afterAnnotation() {
    MethodDeclaration method = ParserTestCase.parse3("parseClassMember", <Object> ["C"], "@override }", [ParserErrorCode.EXPECTED_CLASS_MEMBER]);
    JUnitTestCase.assertNull(method.documentationComment);
    NodeList<Annotation> metadata = method.metadata;
    EngineTestCase.assertSizeOfList(1, metadata);
    JUnitTestCase.assertEquals("override", metadata[0].name.name);
  }

  void test_multiplicativeExpression_missing_LHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("* y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic);
  }

  void test_multiplicativeExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("*", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
  }

  void test_multiplicativeExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x *", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
  }

  void test_multiplicativeExpression_missing_RHS_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super *", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
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
    JUnitTestCase.assertTrue(expression.operand.isSynthetic);
    JUnitTestCase.assertEquals(TokenType.MINUS, expression.operator.type);
  }

  void test_primaryExpression_argumentDefinitionTest() {
    Expression expression = ParserTestCase.parse4("parsePrimaryExpression", "?a", [ParserErrorCode.UNEXPECTED_TOKEN]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression);
  }

  void test_relationalExpression_missing_LHS() {
    IsExpression expression = ParserTestCase.parseExpression("is y", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.expression);
    JUnitTestCase.assertTrue(expression.expression.isSynthetic);
  }

  void test_relationalExpression_missing_LHS_RHS() {
    IsExpression expression = ParserTestCase.parseExpression("is", [
        ParserErrorCode.EXPECTED_TYPE_NAME,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.expression);
    JUnitTestCase.assertTrue(expression.expression.isSynthetic);
    EngineTestCase.assertInstanceOf((obj) => obj is TypeName, TypeName, expression.type);
    JUnitTestCase.assertTrue(expression.type.isSynthetic);
  }

  void test_relationalExpression_missing_RHS() {
    IsExpression expression = ParserTestCase.parseExpression("x is", [ParserErrorCode.EXPECTED_TYPE_NAME]);
    EngineTestCase.assertInstanceOf((obj) => obj is TypeName, TypeName, expression.type);
    JUnitTestCase.assertTrue(expression.type.isSynthetic);
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
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic);
  }

  void test_shiftExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("<<", [
        ParserErrorCode.MISSING_IDENTIFIER,
        ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
  }

  void test_shiftExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x <<", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
  }

  void test_shiftExpression_missing_RHS_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super <<", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic);
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
    EngineTestCase.assertSizeOfList(1, declarations);
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
    JUnitTestCase.assertSame(element, toNode.element);
  }

  void test_visitAsExpression() {
    AsExpression fromNode = AstFactory.asExpression(AstFactory.identifier3("x"), AstFactory.typeName4("A", []));
    DartType propagatedType = ElementFactory.classElement2("A", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("B", []).type;
    fromNode.staticType = staticType;
    AsExpression toNode = AstFactory.asExpression(AstFactory.identifier3("x"), AstFactory.typeName4("A", []));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
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
    JUnitTestCase.assertSame(propagatedElement, toNode.propagatedElement);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticElement, toNode.staticElement);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
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
    JUnitTestCase.assertSame(propagatedElement, toNode.propagatedElement);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticElement, toNode.staticElement);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitBooleanLiteral() {
    BooleanLiteral fromNode = AstFactory.booleanLiteral(true);
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    BooleanLiteral toNode = AstFactory.booleanLiteral(true);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitCascadeExpression() {
    CascadeExpression fromNode = AstFactory.cascadeExpression(AstFactory.identifier3("a"), [AstFactory.identifier3("b")]);
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    CascadeExpression toNode = AstFactory.cascadeExpression(AstFactory.identifier3("a"), [AstFactory.identifier3("b")]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitCompilationUnit() {
    CompilationUnit fromNode = AstFactory.compilationUnit();
    CompilationUnitElement element = new CompilationUnitElementImpl("test.dart");
    fromNode.element = element;
    CompilationUnit toNode = AstFactory.compilationUnit();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(element, toNode.element);
  }

  void test_visitConditionalExpression() {
    ConditionalExpression fromNode = AstFactory.conditionalExpression(AstFactory.identifier3("c"), AstFactory.identifier3("a"), AstFactory.identifier3("b"));
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    ConditionalExpression toNode = AstFactory.conditionalExpression(AstFactory.identifier3("c"), AstFactory.identifier3("a"), AstFactory.identifier3("b"));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitConstructorDeclaration() {
    String className = "A";
    String constructorName = "c";
    ConstructorDeclaration fromNode = AstFactory.constructorDeclaration(AstFactory.identifier3(className), constructorName, AstFactory.formalParameterList([]), null);
    ConstructorElement element = ElementFactory.constructorElement2(ElementFactory.classElement2(className, []), constructorName, []);
    fromNode.element = element;
    ConstructorDeclaration toNode = AstFactory.constructorDeclaration(AstFactory.identifier3(className), constructorName, AstFactory.formalParameterList([]), null);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(element, toNode.element);
  }

  void test_visitConstructorName() {
    ConstructorName fromNode = AstFactory.constructorName(AstFactory.typeName4("A", []), "c");
    ConstructorElement staticElement = ElementFactory.constructorElement2(ElementFactory.classElement2("A", []), "c", []);
    fromNode.staticElement = staticElement;
    ConstructorName toNode = AstFactory.constructorName(AstFactory.typeName4("A", []), "c");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(staticElement, toNode.staticElement);
  }

  void test_visitDoubleLiteral() {
    DoubleLiteral fromNode = AstFactory.doubleLiteral(1.0);
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    DoubleLiteral toNode = AstFactory.doubleLiteral(1.0);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitExportDirective() {
    ExportDirective fromNode = AstFactory.exportDirective2("dart:uri", []);
    ExportElement element = new ExportElementImpl();
    fromNode.element = element;
    ExportDirective toNode = AstFactory.exportDirective2("dart:uri", []);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(element, toNode.element);
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
    JUnitTestCase.assertSame(element, toNode.element);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
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
    JUnitTestCase.assertSame(propagatedElement, toNode.propagatedElement);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticElement, toNode.staticElement);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitImportDirective() {
    ImportDirective fromNode = AstFactory.importDirective3("dart:uri", null, []);
    ImportElement element = new ImportElementImpl(0);
    fromNode.element = element;
    ImportDirective toNode = AstFactory.importDirective3("dart:uri", null, []);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(element, toNode.element);
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
    JUnitTestCase.assertSame(auxiliaryElements, toNode.auxiliaryElements);
    JUnitTestCase.assertSame(propagatedElement, toNode.propagatedElement);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticElement, toNode.staticElement);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
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
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticElement, toNode.staticElement);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitIntegerLiteral() {
    IntegerLiteral fromNode = AstFactory.integer(2);
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    IntegerLiteral toNode = AstFactory.integer(2);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitIsExpression() {
    IsExpression fromNode = AstFactory.isExpression(AstFactory.identifier3("x"), false, AstFactory.typeName4("A", []));
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    IsExpression toNode = AstFactory.isExpression(AstFactory.identifier3("x"), false, AstFactory.typeName4("A", []));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitLibraryIdentifier() {
    LibraryIdentifier fromNode = AstFactory.libraryIdentifier([AstFactory.identifier3("lib")]);
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    LibraryIdentifier toNode = AstFactory.libraryIdentifier([AstFactory.identifier3("lib")]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitListLiteral() {
    ListLiteral fromNode = AstFactory.listLiteral([]);
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    ListLiteral toNode = AstFactory.listLiteral([]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitMapLiteral() {
    MapLiteral fromNode = AstFactory.mapLiteral2([]);
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    MapLiteral toNode = AstFactory.mapLiteral2([]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitMethodInvocation() {
    MethodInvocation fromNode = AstFactory.methodInvocation2("m", []);
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    MethodInvocation toNode = AstFactory.methodInvocation2("m", []);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitNamedExpression() {
    NamedExpression fromNode = AstFactory.namedExpression2("n", AstFactory.integer(0));
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    NamedExpression toNode = AstFactory.namedExpression2("n", AstFactory.integer(0));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitNullLiteral() {
    NullLiteral fromNode = AstFactory.nullLiteral();
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    NullLiteral toNode = AstFactory.nullLiteral();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitParenthesizedExpression() {
    ParenthesizedExpression fromNode = AstFactory.parenthesizedExpression(AstFactory.integer(0));
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    ParenthesizedExpression toNode = AstFactory.parenthesizedExpression(AstFactory.integer(0));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitPartDirective() {
    PartDirective fromNode = AstFactory.partDirective2("part.dart");
    LibraryElement element = new LibraryElementImpl.forNode(null, AstFactory.libraryIdentifier2(["lib"]));
    fromNode.element = element;
    PartDirective toNode = AstFactory.partDirective2("part.dart");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(element, toNode.element);
  }

  void test_visitPartOfDirective() {
    PartOfDirective fromNode = AstFactory.partOfDirective(AstFactory.libraryIdentifier2(["lib"]));
    LibraryElement element = new LibraryElementImpl.forNode(null, AstFactory.libraryIdentifier2(["lib"]));
    fromNode.element = element;
    PartOfDirective toNode = AstFactory.partOfDirective(AstFactory.libraryIdentifier2(["lib"]));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(element, toNode.element);
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
    JUnitTestCase.assertSame(propagatedElement, toNode.propagatedElement);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticElement, toNode.staticElement);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitPrefixedIdentifier() {
    PrefixedIdentifier fromNode = AstFactory.identifier5("p", "f");
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    PrefixedIdentifier toNode = AstFactory.identifier5("p", "f");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
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
    JUnitTestCase.assertSame(propagatedElement, toNode.propagatedElement);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticElement, toNode.staticElement);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitPropertyAccess() {
    PropertyAccess fromNode = AstFactory.propertyAccess2(AstFactory.identifier3("x"), "y");
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    PropertyAccess toNode = AstFactory.propertyAccess2(AstFactory.identifier3("x"), "y");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitRedirectingConstructorInvocation() {
    RedirectingConstructorInvocation fromNode = AstFactory.redirectingConstructorInvocation([]);
    ConstructorElement staticElement = ElementFactory.constructorElement2(ElementFactory.classElement2("C", []), null, []);
    fromNode.staticElement = staticElement;
    RedirectingConstructorInvocation toNode = AstFactory.redirectingConstructorInvocation([]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(staticElement, toNode.staticElement);
  }

  void test_visitRethrowExpression() {
    RethrowExpression fromNode = AstFactory.rethrowExpression();
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    RethrowExpression toNode = AstFactory.rethrowExpression();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
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
    JUnitTestCase.assertSame(auxiliaryElements, toNode.auxiliaryElements);
    JUnitTestCase.assertSame(propagatedElement, toNode.propagatedElement);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticElement, toNode.staticElement);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitSimpleStringLiteral() {
    SimpleStringLiteral fromNode = AstFactory.string2("abc");
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    SimpleStringLiteral toNode = AstFactory.string2("abc");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitStringInterpolation() {
    StringInterpolation fromNode = AstFactory.string([AstFactory.interpolationString("a", "'a'")]);
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    StringInterpolation toNode = AstFactory.string([AstFactory.interpolationString("a", "'a'")]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitSuperConstructorInvocation() {
    SuperConstructorInvocation fromNode = AstFactory.superConstructorInvocation([]);
    ConstructorElement staticElement = ElementFactory.constructorElement2(ElementFactory.classElement2("C", []), null, []);
    fromNode.staticElement = staticElement;
    SuperConstructorInvocation toNode = AstFactory.superConstructorInvocation([]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(staticElement, toNode.staticElement);
  }

  void test_visitSuperExpression() {
    SuperExpression fromNode = AstFactory.superExpression();
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    SuperExpression toNode = AstFactory.superExpression();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitSymbolLiteral() {
    SymbolLiteral fromNode = AstFactory.symbolLiteral(["s"]);
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    SymbolLiteral toNode = AstFactory.symbolLiteral(["s"]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitThisExpression() {
    ThisExpression fromNode = AstFactory.thisExpression();
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    ThisExpression toNode = AstFactory.thisExpression();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitThrowExpression() {
    ThrowExpression fromNode = AstFactory.throwExpression();
    DartType propagatedType = ElementFactory.classElement2("C", []).type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C", []).type;
    fromNode.staticType = staticType;
    ThrowExpression toNode = AstFactory.throwExpression();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(propagatedType, toNode.propagatedType);
    JUnitTestCase.assertSame(staticType, toNode.staticType);
  }

  void test_visitTypeName() {
    TypeName fromNode = AstFactory.typeName4("C", []);
    DartType type = ElementFactory.classElement2("C", []).type;
    fromNode.type = type;
    TypeName toNode = AstFactory.typeName4("C", []);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    JUnitTestCase.assertSame(type, toNode.type);
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
    JUnitTestCase.assertNotNull(identifier.token);
    JUnitTestCase.assertEquals("a", identifier.name);
    JUnitTestCase.assertEquals(5, identifier.offset);
  }

  void test_computeStringValue_emptyInterpolationPrefix() {
    JUnitTestCase.assertEquals("", _computeStringValue("'''", true, false));
  }

  void test_computeStringValue_escape_b() {
    JUnitTestCase.assertEquals("\b", _computeStringValue("'\\b'", true, true));
  }

  void test_computeStringValue_escape_f() {
    JUnitTestCase.assertEquals("\f", _computeStringValue("'\\f'", true, true));
  }

  void test_computeStringValue_escape_n() {
    JUnitTestCase.assertEquals("\n", _computeStringValue("'\\n'", true, true));
  }

  void test_computeStringValue_escape_notSpecial() {
    JUnitTestCase.assertEquals(":", _computeStringValue("'\\:'", true, true));
  }

  void test_computeStringValue_escape_r() {
    JUnitTestCase.assertEquals("\r", _computeStringValue("'\\r'", true, true));
  }

  void test_computeStringValue_escape_t() {
    JUnitTestCase.assertEquals("\t", _computeStringValue("'\\t'", true, true));
  }

  void test_computeStringValue_escape_u_fixed() {
    JUnitTestCase.assertEquals("\u4321", _computeStringValue("'\\u4321'", true, true));
  }

  void test_computeStringValue_escape_u_variable() {
    JUnitTestCase.assertEquals("\u0123", _computeStringValue("'\\u{123}'", true, true));
  }

  void test_computeStringValue_escape_v() {
    JUnitTestCase.assertEquals("\u000B", _computeStringValue("'\\v'", true, true));
  }

  void test_computeStringValue_escape_x() {
    JUnitTestCase.assertEquals("\u00FF", _computeStringValue("'\\xFF'", true, true));
  }

  void test_computeStringValue_noEscape_single() {
    JUnitTestCase.assertEquals("text", _computeStringValue("'text'", true, true));
  }

  void test_computeStringValue_noEscape_triple() {
    JUnitTestCase.assertEquals("text", _computeStringValue("'''text'''", true, true));
  }

  void test_computeStringValue_raw_single() {
    JUnitTestCase.assertEquals("text", _computeStringValue("r'text'", true, true));
  }

  void test_computeStringValue_raw_triple() {
    JUnitTestCase.assertEquals("text", _computeStringValue("r'''text'''", true, true));
  }

  void test_computeStringValue_raw_withEscape() {
    JUnitTestCase.assertEquals("two\\nlines", _computeStringValue("r'two\\nlines'", true, true));
  }

  void test_computeStringValue_triple_internalQuote_first_empty() {
    JUnitTestCase.assertEquals("'", _computeStringValue("''''", true, false));
  }

  void test_computeStringValue_triple_internalQuote_first_nonEmpty() {
    JUnitTestCase.assertEquals("'text", _computeStringValue("''''text", true, false));
  }

  void test_computeStringValue_triple_internalQuote_last_empty() {
    JUnitTestCase.assertEquals("", _computeStringValue("'''", false, true));
  }

  void test_computeStringValue_triple_internalQuote_last_nonEmpty() {
    JUnitTestCase.assertEquals("text", _computeStringValue("text'''", false, true));
  }

  void test_constFactory() {
    ParserTestCase.parse("parseClassMember", <Object> ["C"], "const factory C() = A;");
  }

  void test_createSyntheticIdentifier() {
    SimpleIdentifier identifier = _createSyntheticIdentifier();
    JUnitTestCase.assertTrue(identifier.isSynthetic);
  }

  void test_createSyntheticStringLiteral() {
    SimpleStringLiteral literal = _createSyntheticStringLiteral();
    JUnitTestCase.assertTrue(literal.isSynthetic);
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
    JUnitTestCase.assertTrue(_isFunctionDeclaration("f() {}"));
  }

  void test_isFunctionDeclaration_nameButNoReturn_expression() {
    JUnitTestCase.assertTrue(_isFunctionDeclaration("f() => e"));
  }

  void test_isFunctionDeclaration_normalReturn_block() {
    JUnitTestCase.assertTrue(_isFunctionDeclaration("C f() {}"));
  }

  void test_isFunctionDeclaration_normalReturn_expression() {
    JUnitTestCase.assertTrue(_isFunctionDeclaration("C f() => e"));
  }

  void test_isFunctionDeclaration_voidReturn_block() {
    JUnitTestCase.assertTrue(_isFunctionDeclaration("void f() {}"));
  }

  void test_isFunctionDeclaration_voidReturn_expression() {
    JUnitTestCase.assertTrue(_isFunctionDeclaration("void f() => e"));
  }

  void test_isFunctionExpression_false_noBody() {
    JUnitTestCase.assertFalse(_isFunctionExpression("f();"));
  }

  void test_isFunctionExpression_false_notParameters() {
    JUnitTestCase.assertFalse(_isFunctionExpression("(a + b) {"));
  }

  void test_isFunctionExpression_noName_block() {
    JUnitTestCase.assertTrue(_isFunctionExpression("() {}"));
  }

  void test_isFunctionExpression_noName_expression() {
    JUnitTestCase.assertTrue(_isFunctionExpression("() => e"));
  }

  void test_isFunctionExpression_parameter_final() {
    JUnitTestCase.assertTrue(_isFunctionExpression("(final a) {}"));
    JUnitTestCase.assertTrue(_isFunctionExpression("(final a, b) {}"));
    JUnitTestCase.assertTrue(_isFunctionExpression("(final a, final b) {}"));
  }

  void test_isFunctionExpression_parameter_final_typed() {
    JUnitTestCase.assertTrue(_isFunctionExpression("(final int a) {}"));
    JUnitTestCase.assertTrue(_isFunctionExpression("(final prefix.List a) {}"));
    JUnitTestCase.assertTrue(_isFunctionExpression("(final List<int> a) {}"));
    JUnitTestCase.assertTrue(_isFunctionExpression("(final prefix.List<int> a) {}"));
  }

  void test_isFunctionExpression_parameter_multiple() {
    JUnitTestCase.assertTrue(_isFunctionExpression("(a, b) {}"));
  }

  void test_isFunctionExpression_parameter_named() {
    JUnitTestCase.assertTrue(_isFunctionExpression("({a}) {}"));
  }

  void test_isFunctionExpression_parameter_optional() {
    JUnitTestCase.assertTrue(_isFunctionExpression("([a]) {}"));
  }

  void test_isFunctionExpression_parameter_single() {
    JUnitTestCase.assertTrue(_isFunctionExpression("(a) {}"));
  }

  void test_isFunctionExpression_parameter_typed() {
    JUnitTestCase.assertTrue(_isFunctionExpression("(int a, int b) {}"));
  }

  void test_isInitializedVariableDeclaration_assignment() {
    JUnitTestCase.assertFalse(_isInitializedVariableDeclaration("a = null;"));
  }

  void test_isInitializedVariableDeclaration_comparison() {
    JUnitTestCase.assertFalse(_isInitializedVariableDeclaration("a < 0;"));
  }

  void test_isInitializedVariableDeclaration_conditional() {
    JUnitTestCase.assertFalse(_isInitializedVariableDeclaration("a == null ? init() : update();"));
  }

  void test_isInitializedVariableDeclaration_const_noType_initialized() {
    JUnitTestCase.assertTrue(_isInitializedVariableDeclaration("const a = 0;"));
  }

  void test_isInitializedVariableDeclaration_const_noType_uninitialized() {
    JUnitTestCase.assertTrue(_isInitializedVariableDeclaration("const a;"));
  }

  void test_isInitializedVariableDeclaration_const_simpleType_uninitialized() {
    JUnitTestCase.assertTrue(_isInitializedVariableDeclaration("const A a;"));
  }

  void test_isInitializedVariableDeclaration_final_noType_initialized() {
    JUnitTestCase.assertTrue(_isInitializedVariableDeclaration("final a = 0;"));
  }

  void test_isInitializedVariableDeclaration_final_noType_uninitialized() {
    JUnitTestCase.assertTrue(_isInitializedVariableDeclaration("final a;"));
  }

  void test_isInitializedVariableDeclaration_final_simpleType_initialized() {
    JUnitTestCase.assertTrue(_isInitializedVariableDeclaration("final A a = 0;"));
  }

  void test_isInitializedVariableDeclaration_functionDeclaration_typed() {
    JUnitTestCase.assertFalse(_isInitializedVariableDeclaration("A f() {};"));
  }

  void test_isInitializedVariableDeclaration_functionDeclaration_untyped() {
    JUnitTestCase.assertFalse(_isInitializedVariableDeclaration("f() {};"));
  }

  void test_isInitializedVariableDeclaration_noType_initialized() {
    JUnitTestCase.assertTrue(_isInitializedVariableDeclaration("var a = 0;"));
  }

  void test_isInitializedVariableDeclaration_noType_uninitialized() {
    JUnitTestCase.assertTrue(_isInitializedVariableDeclaration("var a;"));
  }

  void test_isInitializedVariableDeclaration_parameterizedType_initialized() {
    JUnitTestCase.assertTrue(_isInitializedVariableDeclaration("List<int> a = null;"));
  }

  void test_isInitializedVariableDeclaration_parameterizedType_uninitialized() {
    JUnitTestCase.assertTrue(_isInitializedVariableDeclaration("List<int> a;"));
  }

  void test_isInitializedVariableDeclaration_simpleType_initialized() {
    JUnitTestCase.assertTrue(_isInitializedVariableDeclaration("A a = 0;"));
  }

  void test_isInitializedVariableDeclaration_simpleType_uninitialized() {
    JUnitTestCase.assertTrue(_isInitializedVariableDeclaration("A a;"));
  }

  void test_isSwitchMember_case_labeled() {
    JUnitTestCase.assertTrue(_isSwitchMember("l1: l2: case"));
  }

  void test_isSwitchMember_case_unlabeled() {
    JUnitTestCase.assertTrue(_isSwitchMember("case"));
  }

  void test_isSwitchMember_default_labeled() {
    JUnitTestCase.assertTrue(_isSwitchMember("l1: l2: default"));
  }

  void test_isSwitchMember_default_unlabeled() {
    JUnitTestCase.assertTrue(_isSwitchMember("default"));
  }

  void test_isSwitchMember_false() {
    JUnitTestCase.assertFalse(_isSwitchMember("break;"));
  }

  void test_parseAdditiveExpression_normal() {
    BinaryExpression expression = ParserTestCase.parse4("parseAdditiveExpression", "x + y", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.PLUS, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }

  void test_parseAdditiveExpression_super() {
    BinaryExpression expression = ParserTestCase.parse4("parseAdditiveExpression", "super + y", []);
    EngineTestCase.assertInstanceOf((obj) => obj is SuperExpression, SuperExpression, expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.PLUS, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }

  void test_parseAnnotation_n1() {
    Annotation annotation = ParserTestCase.parse4("parseAnnotation", "@A", []);
    JUnitTestCase.assertNotNull(annotation.atSign);
    JUnitTestCase.assertNotNull(annotation.name);
    JUnitTestCase.assertNull(annotation.period);
    JUnitTestCase.assertNull(annotation.constructorName);
    JUnitTestCase.assertNull(annotation.arguments);
  }

  void test_parseAnnotation_n1_a() {
    Annotation annotation = ParserTestCase.parse4("parseAnnotation", "@A(x,y)", []);
    JUnitTestCase.assertNotNull(annotation.atSign);
    JUnitTestCase.assertNotNull(annotation.name);
    JUnitTestCase.assertNull(annotation.period);
    JUnitTestCase.assertNull(annotation.constructorName);
    JUnitTestCase.assertNotNull(annotation.arguments);
  }

  void test_parseAnnotation_n2() {
    Annotation annotation = ParserTestCase.parse4("parseAnnotation", "@A.B", []);
    JUnitTestCase.assertNotNull(annotation.atSign);
    JUnitTestCase.assertNotNull(annotation.name);
    JUnitTestCase.assertNull(annotation.period);
    JUnitTestCase.assertNull(annotation.constructorName);
    JUnitTestCase.assertNull(annotation.arguments);
  }

  void test_parseAnnotation_n2_a() {
    Annotation annotation = ParserTestCase.parse4("parseAnnotation", "@A.B(x,y)", []);
    JUnitTestCase.assertNotNull(annotation.atSign);
    JUnitTestCase.assertNotNull(annotation.name);
    JUnitTestCase.assertNull(annotation.period);
    JUnitTestCase.assertNull(annotation.constructorName);
    JUnitTestCase.assertNotNull(annotation.arguments);
  }

  void test_parseAnnotation_n3() {
    Annotation annotation = ParserTestCase.parse4("parseAnnotation", "@A.B.C", []);
    JUnitTestCase.assertNotNull(annotation.atSign);
    JUnitTestCase.assertNotNull(annotation.name);
    JUnitTestCase.assertNotNull(annotation.period);
    JUnitTestCase.assertNotNull(annotation.constructorName);
    JUnitTestCase.assertNull(annotation.arguments);
  }

  void test_parseAnnotation_n3_a() {
    Annotation annotation = ParserTestCase.parse4("parseAnnotation", "@A.B.C(x,y)", []);
    JUnitTestCase.assertNotNull(annotation.atSign);
    JUnitTestCase.assertNotNull(annotation.name);
    JUnitTestCase.assertNotNull(annotation.period);
    JUnitTestCase.assertNotNull(annotation.constructorName);
    JUnitTestCase.assertNotNull(annotation.arguments);
  }

  void test_parseArgument_named() {
    NamedExpression expression = ParserTestCase.parse4("parseArgument", "n: x", []);
    Label name = expression.name;
    JUnitTestCase.assertNotNull(name);
    JUnitTestCase.assertNotNull(name.label);
    JUnitTestCase.assertNotNull(name.colon);
    JUnitTestCase.assertNotNull(expression.expression);
  }

  void test_parseArgument_unnamed() {
    String lexeme = "x";
    SimpleIdentifier identifier = ParserTestCase.parse4("parseArgument", lexeme, []);
    JUnitTestCase.assertEquals(lexeme, identifier.name);
  }

  void test_parseArgumentList_empty() {
    ArgumentList argumentList = ParserTestCase.parse4("parseArgumentList", "()", []);
    NodeList<Expression> arguments = argumentList.arguments;
    EngineTestCase.assertSizeOfList(0, arguments);
  }

  void test_parseArgumentList_mixed() {
    ArgumentList argumentList = ParserTestCase.parse4("parseArgumentList", "(w, x, y: y, z: z)", []);
    NodeList<Expression> arguments = argumentList.arguments;
    EngineTestCase.assertSizeOfList(4, arguments);
  }

  void test_parseArgumentList_noNamed() {
    ArgumentList argumentList = ParserTestCase.parse4("parseArgumentList", "(x, y, z)", []);
    NodeList<Expression> arguments = argumentList.arguments;
    EngineTestCase.assertSizeOfList(3, arguments);
  }

  void test_parseArgumentList_onlyNamed() {
    ArgumentList argumentList = ParserTestCase.parse4("parseArgumentList", "(x: x, y: y)", []);
    NodeList<Expression> arguments = argumentList.arguments;
    EngineTestCase.assertSizeOfList(2, arguments);
  }

  void test_parseAssertStatement() {
    AssertStatement statement = ParserTestCase.parse4("parseAssertStatement", "assert (x);", []);
    JUnitTestCase.assertNotNull(statement.keyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.semicolon);
  }

  void test_parseAssignableExpression_expression_args_dot() {
    PropertyAccess propertyAccess = ParserTestCase.parse("parseAssignableExpression", <Object> [false], "(x)(y).z");
    FunctionExpressionInvocation invocation = propertyAccess.target as FunctionExpressionInvocation;
    JUnitTestCase.assertNotNull(invocation.function);
    ArgumentList argumentList = invocation.argumentList;
    JUnitTestCase.assertNotNull(argumentList);
    EngineTestCase.assertSizeOfList(1, argumentList.arguments);
    JUnitTestCase.assertNotNull(propertyAccess.operator);
    JUnitTestCase.assertNotNull(propertyAccess.propertyName);
  }

  void test_parseAssignableExpression_expression_dot() {
    PropertyAccess propertyAccess = ParserTestCase.parse("parseAssignableExpression", <Object> [false], "(x).y");
    JUnitTestCase.assertNotNull(propertyAccess.target);
    JUnitTestCase.assertNotNull(propertyAccess.operator);
    JUnitTestCase.assertNotNull(propertyAccess.propertyName);
  }

  void test_parseAssignableExpression_expression_index() {
    IndexExpression expression = ParserTestCase.parse("parseAssignableExpression", <Object> [false], "(x)[y]");
    JUnitTestCase.assertNotNull(expression.target);
    JUnitTestCase.assertNotNull(expression.leftBracket);
    JUnitTestCase.assertNotNull(expression.index);
    JUnitTestCase.assertNotNull(expression.rightBracket);
  }

  void test_parseAssignableExpression_identifier() {
    SimpleIdentifier identifier = ParserTestCase.parse("parseAssignableExpression", <Object> [false], "x");
    JUnitTestCase.assertNotNull(identifier);
  }

  void test_parseAssignableExpression_identifier_args_dot() {
    PropertyAccess propertyAccess = ParserTestCase.parse("parseAssignableExpression", <Object> [false], "x(y).z");
    MethodInvocation invocation = propertyAccess.target as MethodInvocation;
    JUnitTestCase.assertEquals("x", invocation.methodName.name);
    ArgumentList argumentList = invocation.argumentList;
    JUnitTestCase.assertNotNull(argumentList);
    EngineTestCase.assertSizeOfList(1, argumentList.arguments);
    JUnitTestCase.assertNotNull(propertyAccess.operator);
    JUnitTestCase.assertNotNull(propertyAccess.propertyName);
  }

  void test_parseAssignableExpression_identifier_dot() {
    PropertyAccess propertyAccess = ParserTestCase.parse("parseAssignableExpression", <Object> [false], "x.y");
    JUnitTestCase.assertNotNull(propertyAccess.target);
    JUnitTestCase.assertNotNull(propertyAccess.operator);
    JUnitTestCase.assertNotNull(propertyAccess.propertyName);
  }

  void test_parseAssignableExpression_identifier_index() {
    IndexExpression expression = ParserTestCase.parse("parseAssignableExpression", <Object> [false], "x[y]");
    JUnitTestCase.assertNotNull(expression.target);
    JUnitTestCase.assertNotNull(expression.leftBracket);
    JUnitTestCase.assertNotNull(expression.index);
    JUnitTestCase.assertNotNull(expression.rightBracket);
  }

  void test_parseAssignableExpression_super_dot() {
    PropertyAccess propertyAccess = ParserTestCase.parse("parseAssignableExpression", <Object> [false], "super.y");
    EngineTestCase.assertInstanceOf((obj) => obj is SuperExpression, SuperExpression, propertyAccess.target);
    JUnitTestCase.assertNotNull(propertyAccess.operator);
    JUnitTestCase.assertNotNull(propertyAccess.propertyName);
  }

  void test_parseAssignableExpression_super_index() {
    IndexExpression expression = ParserTestCase.parse("parseAssignableExpression", <Object> [false], "super[y]");
    EngineTestCase.assertInstanceOf((obj) => obj is SuperExpression, SuperExpression, expression.target);
    JUnitTestCase.assertNotNull(expression.leftBracket);
    JUnitTestCase.assertNotNull(expression.index);
    JUnitTestCase.assertNotNull(expression.rightBracket);
  }

  void test_parseAssignableSelector_dot() {
    PropertyAccess selector = ParserTestCase.parse("parseAssignableSelector", <Object> [null, true], ".x");
    JUnitTestCase.assertNotNull(selector.operator);
    JUnitTestCase.assertNotNull(selector.propertyName);
  }

  void test_parseAssignableSelector_index() {
    IndexExpression selector = ParserTestCase.parse("parseAssignableSelector", <Object> [null, true], "[x]");
    JUnitTestCase.assertNotNull(selector.leftBracket);
    JUnitTestCase.assertNotNull(selector.index);
    JUnitTestCase.assertNotNull(selector.rightBracket);
  }

  void test_parseAssignableSelector_none() {
    SimpleIdentifier selector = ParserTestCase.parse("parseAssignableSelector", <Object> [new SimpleIdentifier(null), true], ";");
    JUnitTestCase.assertNotNull(selector);
  }

  void test_parseAwaitExpression() {
    AwaitExpression expression = ParserTestCase.parse4("parseAwaitExpression", "await x;", []);
    JUnitTestCase.assertNotNull(expression.awaitKeyword);
    JUnitTestCase.assertNotNull(expression.expression);
  }

  void test_parseAwaitExpression_asStatement_inAsync() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], EngineTestCase.createSource(["m() async { await x; }"]));
    FunctionBody body = method.body;
    EngineTestCase.assertInstanceOf((obj) => obj is BlockFunctionBody, BlockFunctionBody, body);
    Statement statement = (body as BlockFunctionBody).block.statements[0];
    EngineTestCase.assertInstanceOf((obj) => obj is ExpressionStatement, ExpressionStatement, statement);
    Expression expression = (statement as ExpressionStatement).expression;
    EngineTestCase.assertInstanceOf((obj) => obj is AwaitExpression, AwaitExpression, expression);
    JUnitTestCase.assertNotNull((expression as AwaitExpression).awaitKeyword);
    JUnitTestCase.assertNotNull((expression as AwaitExpression).expression);
  }

  void test_parseAwaitExpression_asStatement_inSync() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], EngineTestCase.createSource(["m() { await x; }"]));
    FunctionBody body = method.body;
    EngineTestCase.assertInstanceOf((obj) => obj is BlockFunctionBody, BlockFunctionBody, body);
    Statement statement = (body as BlockFunctionBody).block.statements[0];
    EngineTestCase.assertInstanceOf((obj) => obj is VariableDeclarationStatement, VariableDeclarationStatement, statement);
  }

  void test_parseAwaitExpression_inSync() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], EngineTestCase.createSource(["m() { return await x + await y; }"]));
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
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.AMPERSAND, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }

  void test_parseBitwiseAndExpression_super() {
    BinaryExpression expression = ParserTestCase.parse4("parseBitwiseAndExpression", "super & y", []);
    EngineTestCase.assertInstanceOf((obj) => obj is SuperExpression, SuperExpression, expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.AMPERSAND, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }

  void test_parseBitwiseOrExpression_normal() {
    BinaryExpression expression = ParserTestCase.parse4("parseBitwiseOrExpression", "x | y", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.BAR, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }

  void test_parseBitwiseOrExpression_super() {
    BinaryExpression expression = ParserTestCase.parse4("parseBitwiseOrExpression", "super | y", []);
    EngineTestCase.assertInstanceOf((obj) => obj is SuperExpression, SuperExpression, expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.BAR, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }

  void test_parseBitwiseXorExpression_normal() {
    BinaryExpression expression = ParserTestCase.parse4("parseBitwiseXorExpression", "x ^ y", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.CARET, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }

  void test_parseBitwiseXorExpression_super() {
    BinaryExpression expression = ParserTestCase.parse4("parseBitwiseXorExpression", "super ^ y", []);
    EngineTestCase.assertInstanceOf((obj) => obj is SuperExpression, SuperExpression, expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.CARET, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }

  void test_parseBlock_empty() {
    Block block = ParserTestCase.parse4("parseBlock", "{}", []);
    JUnitTestCase.assertNotNull(block.leftBracket);
    EngineTestCase.assertSizeOfList(0, block.statements);
    JUnitTestCase.assertNotNull(block.rightBracket);
  }

  void test_parseBlock_nonEmpty() {
    Block block = ParserTestCase.parse4("parseBlock", "{;}", []);
    JUnitTestCase.assertNotNull(block.leftBracket);
    EngineTestCase.assertSizeOfList(1, block.statements);
    JUnitTestCase.assertNotNull(block.rightBracket);
  }

  void test_parseBreakStatement_label() {
    BreakStatement statement = ParserTestCase.parse4("parseBreakStatement", "break foo;", []);
    JUnitTestCase.assertNotNull(statement.keyword);
    JUnitTestCase.assertNotNull(statement.label);
    JUnitTestCase.assertNotNull(statement.semicolon);
  }

  void test_parseBreakStatement_noLabel() {
    BreakStatement statement = ParserTestCase.parse4("parseBreakStatement", "break;", [ParserErrorCode.BREAK_OUTSIDE_OF_LOOP]);
    JUnitTestCase.assertNotNull(statement.keyword);
    JUnitTestCase.assertNull(statement.label);
    JUnitTestCase.assertNotNull(statement.semicolon);
  }

  void test_parseCascadeSection_i() {
    IndexExpression section = ParserTestCase.parse4("parseCascadeSection", "..[i]", []);
    JUnitTestCase.assertNull(section.target);
    JUnitTestCase.assertNotNull(section.leftBracket);
    JUnitTestCase.assertNotNull(section.index);
    JUnitTestCase.assertNotNull(section.rightBracket);
  }

  void test_parseCascadeSection_ia() {
    FunctionExpressionInvocation section = ParserTestCase.parse4("parseCascadeSection", "..[i](b)", []);
    EngineTestCase.assertInstanceOf((obj) => obj is IndexExpression, IndexExpression, section.function);
    JUnitTestCase.assertNotNull(section.argumentList);
  }

  void test_parseCascadeSection_ii() {
    MethodInvocation section = ParserTestCase.parse4("parseCascadeSection", "..a(b).c(d)", []);
    EngineTestCase.assertInstanceOf((obj) => obj is MethodInvocation, MethodInvocation, section.target);
    JUnitTestCase.assertNotNull(section.period);
    JUnitTestCase.assertNotNull(section.methodName);
    JUnitTestCase.assertNotNull(section.argumentList);
    EngineTestCase.assertSizeOfList(1, section.argumentList.arguments);
  }

  void test_parseCascadeSection_p() {
    PropertyAccess section = ParserTestCase.parse4("parseCascadeSection", "..a", []);
    JUnitTestCase.assertNull(section.target);
    JUnitTestCase.assertNotNull(section.operator);
    JUnitTestCase.assertNotNull(section.propertyName);
  }

  void test_parseCascadeSection_p_assign() {
    AssignmentExpression section = ParserTestCase.parse4("parseCascadeSection", "..a = 3", []);
    JUnitTestCase.assertNotNull(section.leftHandSide);
    JUnitTestCase.assertNotNull(section.operator);
    Expression rhs = section.rightHandSide;
    JUnitTestCase.assertNotNull(rhs);
  }

  void test_parseCascadeSection_p_assign_withCascade() {
    AssignmentExpression section = ParserTestCase.parse4("parseCascadeSection", "..a = 3..m()", []);
    JUnitTestCase.assertNotNull(section.leftHandSide);
    JUnitTestCase.assertNotNull(section.operator);
    Expression rhs = section.rightHandSide;
    EngineTestCase.assertInstanceOf((obj) => obj is IntegerLiteral, IntegerLiteral, rhs);
  }

  void test_parseCascadeSection_p_builtIn() {
    PropertyAccess section = ParserTestCase.parse4("parseCascadeSection", "..as", []);
    JUnitTestCase.assertNull(section.target);
    JUnitTestCase.assertNotNull(section.operator);
    JUnitTestCase.assertNotNull(section.propertyName);
  }

  void test_parseCascadeSection_pa() {
    MethodInvocation section = ParserTestCase.parse4("parseCascadeSection", "..a(b)", []);
    JUnitTestCase.assertNull(section.target);
    JUnitTestCase.assertNotNull(section.period);
    JUnitTestCase.assertNotNull(section.methodName);
    JUnitTestCase.assertNotNull(section.argumentList);
    EngineTestCase.assertSizeOfList(1, section.argumentList.arguments);
  }

  void test_parseCascadeSection_paa() {
    FunctionExpressionInvocation section = ParserTestCase.parse4("parseCascadeSection", "..a(b)(c)", []);
    EngineTestCase.assertInstanceOf((obj) => obj is MethodInvocation, MethodInvocation, section.function);
    JUnitTestCase.assertNotNull(section.argumentList);
    EngineTestCase.assertSizeOfList(1, section.argumentList.arguments);
  }

  void test_parseCascadeSection_paapaa() {
    FunctionExpressionInvocation section = ParserTestCase.parse4("parseCascadeSection", "..a(b)(c).d(e)(f)", []);
    EngineTestCase.assertInstanceOf((obj) => obj is MethodInvocation, MethodInvocation, section.function);
    JUnitTestCase.assertNotNull(section.argumentList);
    EngineTestCase.assertSizeOfList(1, section.argumentList.arguments);
  }

  void test_parseCascadeSection_pap() {
    PropertyAccess section = ParserTestCase.parse4("parseCascadeSection", "..a(b).c", []);
    JUnitTestCase.assertNotNull(section.target);
    JUnitTestCase.assertNotNull(section.operator);
    JUnitTestCase.assertNotNull(section.propertyName);
  }

  void test_parseClassDeclaration_abstract() {
    ClassDeclaration declaration = ParserTestCase.parse("parseClassDeclaration", <Object> [
        emptyCommentAndMetadata(),
        TokenFactory.tokenFromKeyword(Keyword.ABSTRACT)], "class A {}");
    JUnitTestCase.assertNull(declaration.documentationComment);
    JUnitTestCase.assertNotNull(declaration.abstractKeyword);
    JUnitTestCase.assertNull(declaration.extendsClause);
    JUnitTestCase.assertNull(declaration.implementsClause);
    JUnitTestCase.assertNotNull(declaration.classKeyword);
    JUnitTestCase.assertNotNull(declaration.leftBracket);
    JUnitTestCase.assertNotNull(declaration.name);
    EngineTestCase.assertSizeOfList(0, declaration.members);
    JUnitTestCase.assertNotNull(declaration.rightBracket);
    JUnitTestCase.assertNull(declaration.typeParameters);
  }

  void test_parseClassDeclaration_empty() {
    ClassDeclaration declaration = ParserTestCase.parse("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class A {}");
    JUnitTestCase.assertNull(declaration.documentationComment);
    JUnitTestCase.assertNull(declaration.abstractKeyword);
    JUnitTestCase.assertNull(declaration.extendsClause);
    JUnitTestCase.assertNull(declaration.implementsClause);
    JUnitTestCase.assertNotNull(declaration.classKeyword);
    JUnitTestCase.assertNotNull(declaration.leftBracket);
    JUnitTestCase.assertNotNull(declaration.name);
    EngineTestCase.assertSizeOfList(0, declaration.members);
    JUnitTestCase.assertNotNull(declaration.rightBracket);
    JUnitTestCase.assertNull(declaration.typeParameters);
  }

  void test_parseClassDeclaration_extends() {
    ClassDeclaration declaration = ParserTestCase.parse("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class A extends B {}");
    JUnitTestCase.assertNull(declaration.documentationComment);
    JUnitTestCase.assertNull(declaration.abstractKeyword);
    JUnitTestCase.assertNotNull(declaration.extendsClause);
    JUnitTestCase.assertNull(declaration.implementsClause);
    JUnitTestCase.assertNotNull(declaration.classKeyword);
    JUnitTestCase.assertNotNull(declaration.leftBracket);
    JUnitTestCase.assertNotNull(declaration.name);
    EngineTestCase.assertSizeOfList(0, declaration.members);
    JUnitTestCase.assertNotNull(declaration.rightBracket);
    JUnitTestCase.assertNull(declaration.typeParameters);
  }

  void test_parseClassDeclaration_extendsAndImplements() {
    ClassDeclaration declaration = ParserTestCase.parse("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class A extends B implements C {}");
    JUnitTestCase.assertNull(declaration.documentationComment);
    JUnitTestCase.assertNull(declaration.abstractKeyword);
    JUnitTestCase.assertNotNull(declaration.extendsClause);
    JUnitTestCase.assertNotNull(declaration.implementsClause);
    JUnitTestCase.assertNotNull(declaration.classKeyword);
    JUnitTestCase.assertNotNull(declaration.leftBracket);
    JUnitTestCase.assertNotNull(declaration.name);
    EngineTestCase.assertSizeOfList(0, declaration.members);
    JUnitTestCase.assertNotNull(declaration.rightBracket);
    JUnitTestCase.assertNull(declaration.typeParameters);
  }

  void test_parseClassDeclaration_extendsAndWith() {
    ClassDeclaration declaration = ParserTestCase.parse("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class A extends B with C {}");
    JUnitTestCase.assertNull(declaration.documentationComment);
    JUnitTestCase.assertNull(declaration.abstractKeyword);
    JUnitTestCase.assertNotNull(declaration.classKeyword);
    JUnitTestCase.assertNotNull(declaration.name);
    JUnitTestCase.assertNull(declaration.typeParameters);
    JUnitTestCase.assertNotNull(declaration.extendsClause);
    JUnitTestCase.assertNotNull(declaration.withClause);
    JUnitTestCase.assertNull(declaration.implementsClause);
    JUnitTestCase.assertNotNull(declaration.leftBracket);
    EngineTestCase.assertSizeOfList(0, declaration.members);
    JUnitTestCase.assertNotNull(declaration.rightBracket);
  }

  void test_parseClassDeclaration_extendsAndWithAndImplements() {
    ClassDeclaration declaration = ParserTestCase.parse("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class A extends B with C implements D {}");
    JUnitTestCase.assertNull(declaration.documentationComment);
    JUnitTestCase.assertNull(declaration.abstractKeyword);
    JUnitTestCase.assertNotNull(declaration.classKeyword);
    JUnitTestCase.assertNotNull(declaration.name);
    JUnitTestCase.assertNull(declaration.typeParameters);
    JUnitTestCase.assertNotNull(declaration.extendsClause);
    JUnitTestCase.assertNotNull(declaration.withClause);
    JUnitTestCase.assertNotNull(declaration.implementsClause);
    JUnitTestCase.assertNotNull(declaration.leftBracket);
    EngineTestCase.assertSizeOfList(0, declaration.members);
    JUnitTestCase.assertNotNull(declaration.rightBracket);
  }

  void test_parseClassDeclaration_implements() {
    ClassDeclaration declaration = ParserTestCase.parse("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class A implements C {}");
    JUnitTestCase.assertNull(declaration.documentationComment);
    JUnitTestCase.assertNull(declaration.abstractKeyword);
    JUnitTestCase.assertNull(declaration.extendsClause);
    JUnitTestCase.assertNotNull(declaration.implementsClause);
    JUnitTestCase.assertNotNull(declaration.classKeyword);
    JUnitTestCase.assertNotNull(declaration.leftBracket);
    JUnitTestCase.assertNotNull(declaration.name);
    EngineTestCase.assertSizeOfList(0, declaration.members);
    JUnitTestCase.assertNotNull(declaration.rightBracket);
    JUnitTestCase.assertNull(declaration.typeParameters);
  }

  void test_parseClassDeclaration_native() {
    ClassDeclaration declaration = ParserTestCase.parse("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class A native 'nativeValue' {}");
    NativeClause nativeClause = declaration.nativeClause;
    JUnitTestCase.assertNotNull(nativeClause);
    JUnitTestCase.assertNotNull(nativeClause.keyword);
    JUnitTestCase.assertEquals("nativeValue", nativeClause.name.stringValue);
    JUnitTestCase.assertSame(nativeClause.keyword, nativeClause.beginToken);
    JUnitTestCase.assertSame(nativeClause.name.endToken, nativeClause.endToken);
  }

  void test_parseClassDeclaration_nonEmpty() {
    ClassDeclaration declaration = ParserTestCase.parse("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class A {var f;}");
    JUnitTestCase.assertNull(declaration.documentationComment);
    JUnitTestCase.assertNull(declaration.abstractKeyword);
    JUnitTestCase.assertNull(declaration.extendsClause);
    JUnitTestCase.assertNull(declaration.implementsClause);
    JUnitTestCase.assertNotNull(declaration.classKeyword);
    JUnitTestCase.assertNotNull(declaration.leftBracket);
    JUnitTestCase.assertNotNull(declaration.name);
    EngineTestCase.assertSizeOfList(1, declaration.members);
    JUnitTestCase.assertNotNull(declaration.rightBracket);
    JUnitTestCase.assertNull(declaration.typeParameters);
  }

  void test_parseClassDeclaration_typeAlias_implementsC() {
    ClassTypeAlias typeAlias = ParserTestCase.parse("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class A = Object with B implements C;");
    JUnitTestCase.assertNotNull(typeAlias.keyword);
    JUnitTestCase.assertNotNull(typeAlias.name);
    JUnitTestCase.assertNull(typeAlias.typeParameters);
    JUnitTestCase.assertNotNull(typeAlias.withClause);
    JUnitTestCase.assertNotNull(typeAlias.implementsClause);
    JUnitTestCase.assertNotNull(typeAlias.implementsClause.keyword);
    JUnitTestCase.assertEquals(1, typeAlias.implementsClause.interfaces.length);
    JUnitTestCase.assertNotNull(typeAlias.semicolon);
  }

  void test_parseClassDeclaration_typeAlias_withB() {
    ClassTypeAlias typeAlias = ParserTestCase.parse("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class A = Object with B;");
    JUnitTestCase.assertNotNull(typeAlias.keyword);
    JUnitTestCase.assertNotNull(typeAlias.name);
    JUnitTestCase.assertNull(typeAlias.typeParameters);
    JUnitTestCase.assertNotNull(typeAlias.withClause);
    JUnitTestCase.assertNotNull(typeAlias.withClause.withKeyword);
    JUnitTestCase.assertEquals(1, typeAlias.withClause.mixinTypes.length);
    JUnitTestCase.assertNull(typeAlias.implementsClause);
    JUnitTestCase.assertNotNull(typeAlias.semicolon);
  }

  void test_parseClassDeclaration_typeParameters() {
    ClassDeclaration declaration = ParserTestCase.parse("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class A<B> {}");
    JUnitTestCase.assertNull(declaration.documentationComment);
    JUnitTestCase.assertNull(declaration.abstractKeyword);
    JUnitTestCase.assertNull(declaration.extendsClause);
    JUnitTestCase.assertNull(declaration.implementsClause);
    JUnitTestCase.assertNotNull(declaration.classKeyword);
    JUnitTestCase.assertNotNull(declaration.leftBracket);
    JUnitTestCase.assertNotNull(declaration.name);
    EngineTestCase.assertSizeOfList(0, declaration.members);
    JUnitTestCase.assertNotNull(declaration.rightBracket);
    JUnitTestCase.assertNotNull(declaration.typeParameters);
    EngineTestCase.assertSizeOfList(1, declaration.typeParameters.typeParameters);
  }

  void test_parseClassMember_constructor_withInitializers() {
    // TODO(brianwilkerson) Test other kinds of class members: fields, getters and setters.
    ConstructorDeclaration constructor = ParserTestCase.parse("parseClassMember", <Object> ["C"], "C(_, _\$, this.__) : _a = _ + _\$ {}");
    JUnitTestCase.assertNotNull(constructor.body);
    JUnitTestCase.assertNotNull(constructor.separator);
    JUnitTestCase.assertNull(constructor.externalKeyword);
    JUnitTestCase.assertNull(constructor.constKeyword);
    JUnitTestCase.assertNull(constructor.factoryKeyword);
    JUnitTestCase.assertNull(constructor.name);
    JUnitTestCase.assertNotNull(constructor.parameters);
    JUnitTestCase.assertNull(constructor.period);
    JUnitTestCase.assertNotNull(constructor.returnType);
    EngineTestCase.assertSizeOfList(1, constructor.initializers);
  }

  void test_parseClassMember_field_instance_prefixedType() {
    FieldDeclaration field = ParserTestCase.parse("parseClassMember", <Object> ["C"], "p.A f;");
    JUnitTestCase.assertNull(field.documentationComment);
    EngineTestCase.assertSizeOfList(0, field.metadata);
    JUnitTestCase.assertNull(field.staticKeyword);
    VariableDeclarationList list = field.fields;
    JUnitTestCase.assertNotNull(list);
    NodeList<VariableDeclaration> variables = list.variables;
    EngineTestCase.assertSizeOfList(1, variables);
    VariableDeclaration variable = variables[0];
    JUnitTestCase.assertNotNull(variable.name);
  }

  void test_parseClassMember_field_namedGet() {
    FieldDeclaration field = ParserTestCase.parse("parseClassMember", <Object> ["C"], "var get;");
    JUnitTestCase.assertNull(field.documentationComment);
    EngineTestCase.assertSizeOfList(0, field.metadata);
    JUnitTestCase.assertNull(field.staticKeyword);
    VariableDeclarationList list = field.fields;
    JUnitTestCase.assertNotNull(list);
    NodeList<VariableDeclaration> variables = list.variables;
    EngineTestCase.assertSizeOfList(1, variables);
    VariableDeclaration variable = variables[0];
    JUnitTestCase.assertNotNull(variable.name);
  }

  void test_parseClassMember_field_namedOperator() {
    FieldDeclaration field = ParserTestCase.parse("parseClassMember", <Object> ["C"], "var operator;");
    JUnitTestCase.assertNull(field.documentationComment);
    EngineTestCase.assertSizeOfList(0, field.metadata);
    JUnitTestCase.assertNull(field.staticKeyword);
    VariableDeclarationList list = field.fields;
    JUnitTestCase.assertNotNull(list);
    NodeList<VariableDeclaration> variables = list.variables;
    EngineTestCase.assertSizeOfList(1, variables);
    VariableDeclaration variable = variables[0];
    JUnitTestCase.assertNotNull(variable.name);
  }

  void test_parseClassMember_field_namedOperator_withAssignment() {
    FieldDeclaration field = ParserTestCase.parse("parseClassMember", <Object> ["C"], "var operator = (5);");
    JUnitTestCase.assertNull(field.documentationComment);
    EngineTestCase.assertSizeOfList(0, field.metadata);
    JUnitTestCase.assertNull(field.staticKeyword);
    VariableDeclarationList list = field.fields;
    JUnitTestCase.assertNotNull(list);
    NodeList<VariableDeclaration> variables = list.variables;
    EngineTestCase.assertSizeOfList(1, variables);
    VariableDeclaration variable = variables[0];
    JUnitTestCase.assertNotNull(variable.name);
    JUnitTestCase.assertNotNull(variable.initializer);
  }

  void test_parseClassMember_field_namedSet() {
    FieldDeclaration field = ParserTestCase.parse("parseClassMember", <Object> ["C"], "var set;");
    JUnitTestCase.assertNull(field.documentationComment);
    EngineTestCase.assertSizeOfList(0, field.metadata);
    JUnitTestCase.assertNull(field.staticKeyword);
    VariableDeclarationList list = field.fields;
    JUnitTestCase.assertNotNull(list);
    NodeList<VariableDeclaration> variables = list.variables;
    EngineTestCase.assertSizeOfList(1, variables);
    VariableDeclaration variable = variables[0];
    JUnitTestCase.assertNotNull(variable.name);
  }

  void test_parseClassMember_getter_void() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "void get g {}");
    JUnitTestCase.assertNull(method.documentationComment);
    JUnitTestCase.assertNull(method.externalKeyword);
    JUnitTestCase.assertNull(method.modifierKeyword);
    JUnitTestCase.assertNotNull(method.propertyKeyword);
    JUnitTestCase.assertNotNull(method.returnType);
    JUnitTestCase.assertNotNull(method.name);
    JUnitTestCase.assertNull(method.operatorKeyword);
    JUnitTestCase.assertNotNull(method.body);
  }

  void test_parseClassMember_method_external() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "external m();");
    JUnitTestCase.assertNotNull(method.body);
    JUnitTestCase.assertNull(method.documentationComment);
    JUnitTestCase.assertNotNull(method.externalKeyword);
    JUnitTestCase.assertNull(method.modifierKeyword);
    JUnitTestCase.assertNotNull(method.name);
    JUnitTestCase.assertNull(method.operatorKeyword);
    JUnitTestCase.assertNotNull(method.parameters);
    JUnitTestCase.assertNull(method.propertyKeyword);
    JUnitTestCase.assertNull(method.returnType);
  }

  void test_parseClassMember_method_external_withTypeAndArgs() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "external int m(int a);");
    JUnitTestCase.assertNotNull(method.body);
    JUnitTestCase.assertNull(method.documentationComment);
    JUnitTestCase.assertNotNull(method.externalKeyword);
    JUnitTestCase.assertNull(method.modifierKeyword);
    JUnitTestCase.assertNotNull(method.name);
    JUnitTestCase.assertNull(method.operatorKeyword);
    JUnitTestCase.assertNotNull(method.parameters);
    JUnitTestCase.assertNull(method.propertyKeyword);
    JUnitTestCase.assertNotNull(method.returnType);
  }

  void test_parseClassMember_method_get_noType() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "get() {}");
    JUnitTestCase.assertNull(method.documentationComment);
    JUnitTestCase.assertNull(method.externalKeyword);
    JUnitTestCase.assertNull(method.modifierKeyword);
    JUnitTestCase.assertNull(method.propertyKeyword);
    JUnitTestCase.assertNull(method.returnType);
    JUnitTestCase.assertNotNull(method.name);
    JUnitTestCase.assertNull(method.operatorKeyword);
    JUnitTestCase.assertNotNull(method.parameters);
    JUnitTestCase.assertNotNull(method.body);
  }

  void test_parseClassMember_method_get_type() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "int get() {}");
    JUnitTestCase.assertNull(method.documentationComment);
    JUnitTestCase.assertNull(method.externalKeyword);
    JUnitTestCase.assertNull(method.modifierKeyword);
    JUnitTestCase.assertNull(method.propertyKeyword);
    JUnitTestCase.assertNotNull(method.returnType);
    JUnitTestCase.assertNotNull(method.name);
    JUnitTestCase.assertNull(method.operatorKeyword);
    JUnitTestCase.assertNotNull(method.parameters);
    JUnitTestCase.assertNotNull(method.body);
  }

  void test_parseClassMember_method_get_void() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "void get() {}");
    JUnitTestCase.assertNull(method.documentationComment);
    JUnitTestCase.assertNull(method.externalKeyword);
    JUnitTestCase.assertNull(method.modifierKeyword);
    JUnitTestCase.assertNull(method.propertyKeyword);
    JUnitTestCase.assertNotNull(method.returnType);
    JUnitTestCase.assertNotNull(method.name);
    JUnitTestCase.assertNull(method.operatorKeyword);
    JUnitTestCase.assertNotNull(method.parameters);
    JUnitTestCase.assertNotNull(method.body);
  }

  void test_parseClassMember_method_operator_noType() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "operator() {}");
    JUnitTestCase.assertNull(method.documentationComment);
    JUnitTestCase.assertNull(method.externalKeyword);
    JUnitTestCase.assertNull(method.modifierKeyword);
    JUnitTestCase.assertNull(method.propertyKeyword);
    JUnitTestCase.assertNull(method.returnType);
    JUnitTestCase.assertNotNull(method.name);
    JUnitTestCase.assertNull(method.operatorKeyword);
    JUnitTestCase.assertNotNull(method.parameters);
    JUnitTestCase.assertNotNull(method.body);
  }

  void test_parseClassMember_method_operator_type() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "int operator() {}");
    JUnitTestCase.assertNull(method.documentationComment);
    JUnitTestCase.assertNull(method.externalKeyword);
    JUnitTestCase.assertNull(method.modifierKeyword);
    JUnitTestCase.assertNull(method.propertyKeyword);
    JUnitTestCase.assertNotNull(method.returnType);
    JUnitTestCase.assertNotNull(method.name);
    JUnitTestCase.assertNull(method.operatorKeyword);
    JUnitTestCase.assertNotNull(method.parameters);
    JUnitTestCase.assertNotNull(method.body);
  }

  void test_parseClassMember_method_operator_void() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "void operator() {}");
    JUnitTestCase.assertNull(method.documentationComment);
    JUnitTestCase.assertNull(method.externalKeyword);
    JUnitTestCase.assertNull(method.modifierKeyword);
    JUnitTestCase.assertNull(method.propertyKeyword);
    JUnitTestCase.assertNotNull(method.returnType);
    JUnitTestCase.assertNotNull(method.name);
    JUnitTestCase.assertNull(method.operatorKeyword);
    JUnitTestCase.assertNotNull(method.parameters);
    JUnitTestCase.assertNotNull(method.body);
  }

  void test_parseClassMember_method_returnType_parameterized() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "p.A m() {}");
    JUnitTestCase.assertNull(method.documentationComment);
    JUnitTestCase.assertNull(method.externalKeyword);
    JUnitTestCase.assertNull(method.modifierKeyword);
    JUnitTestCase.assertNull(method.propertyKeyword);
    JUnitTestCase.assertNotNull(method.returnType);
    JUnitTestCase.assertNotNull(method.name);
    JUnitTestCase.assertNull(method.operatorKeyword);
    JUnitTestCase.assertNotNull(method.parameters);
    JUnitTestCase.assertNotNull(method.body);
  }

  void test_parseClassMember_method_set_noType() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "set() {}");
    JUnitTestCase.assertNull(method.documentationComment);
    JUnitTestCase.assertNull(method.externalKeyword);
    JUnitTestCase.assertNull(method.modifierKeyword);
    JUnitTestCase.assertNull(method.propertyKeyword);
    JUnitTestCase.assertNull(method.returnType);
    JUnitTestCase.assertNotNull(method.name);
    JUnitTestCase.assertNull(method.operatorKeyword);
    JUnitTestCase.assertNotNull(method.parameters);
    JUnitTestCase.assertNotNull(method.body);
  }

  void test_parseClassMember_method_set_type() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "int set() {}");
    JUnitTestCase.assertNull(method.documentationComment);
    JUnitTestCase.assertNull(method.externalKeyword);
    JUnitTestCase.assertNull(method.modifierKeyword);
    JUnitTestCase.assertNull(method.propertyKeyword);
    JUnitTestCase.assertNotNull(method.returnType);
    JUnitTestCase.assertNotNull(method.name);
    JUnitTestCase.assertNull(method.operatorKeyword);
    JUnitTestCase.assertNotNull(method.parameters);
    JUnitTestCase.assertNotNull(method.body);
  }

  void test_parseClassMember_method_set_void() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "void set() {}");
    JUnitTestCase.assertNull(method.documentationComment);
    JUnitTestCase.assertNull(method.externalKeyword);
    JUnitTestCase.assertNull(method.modifierKeyword);
    JUnitTestCase.assertNull(method.propertyKeyword);
    JUnitTestCase.assertNotNull(method.returnType);
    JUnitTestCase.assertNotNull(method.name);
    JUnitTestCase.assertNull(method.operatorKeyword);
    JUnitTestCase.assertNotNull(method.parameters);
    JUnitTestCase.assertNotNull(method.body);
  }

  void test_parseClassMember_operator_index() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "int operator [](int i) {}");
    JUnitTestCase.assertNull(method.documentationComment);
    JUnitTestCase.assertNull(method.externalKeyword);
    JUnitTestCase.assertNull(method.modifierKeyword);
    JUnitTestCase.assertNull(method.propertyKeyword);
    JUnitTestCase.assertNotNull(method.returnType);
    JUnitTestCase.assertNotNull(method.name);
    JUnitTestCase.assertNotNull(method.operatorKeyword);
    JUnitTestCase.assertNotNull(method.parameters);
    JUnitTestCase.assertNotNull(method.body);
  }

  void test_parseClassMember_operator_indexAssign() {
    MethodDeclaration method = ParserTestCase.parse("parseClassMember", <Object> ["C"], "int operator []=(int i) {}");
    JUnitTestCase.assertNull(method.documentationComment);
    JUnitTestCase.assertNull(method.externalKeyword);
    JUnitTestCase.assertNull(method.modifierKeyword);
    JUnitTestCase.assertNull(method.propertyKeyword);
    JUnitTestCase.assertNotNull(method.returnType);
    JUnitTestCase.assertNotNull(method.name);
    JUnitTestCase.assertNotNull(method.operatorKeyword);
    JUnitTestCase.assertNotNull(method.parameters);
    JUnitTestCase.assertNotNull(method.body);
  }

  void test_parseClassMember_redirectingFactory_const() {
    ConstructorDeclaration constructor = ParserTestCase.parse("parseClassMember", <Object> ["C"], "const factory C() = B;");
    JUnitTestCase.assertNull(constructor.externalKeyword);
    JUnitTestCase.assertNotNull(constructor.constKeyword);
    JUnitTestCase.assertNotNull(constructor.factoryKeyword);
    JUnitTestCase.assertNotNull(constructor.returnType);
    JUnitTestCase.assertNull(constructor.period);
    JUnitTestCase.assertNull(constructor.name);
    JUnitTestCase.assertNotNull(constructor.parameters);
    JUnitTestCase.assertNotNull(constructor.separator);
    EngineTestCase.assertSizeOfList(0, constructor.initializers);
    JUnitTestCase.assertNotNull(constructor.redirectedConstructor);
    JUnitTestCase.assertNotNull(constructor.body);
  }

  void test_parseClassMember_redirectingFactory_nonConst() {
    ConstructorDeclaration constructor = ParserTestCase.parse("parseClassMember", <Object> ["C"], "factory C() = B;");
    JUnitTestCase.assertNull(constructor.externalKeyword);
    JUnitTestCase.assertNull(constructor.constKeyword);
    JUnitTestCase.assertNotNull(constructor.factoryKeyword);
    JUnitTestCase.assertNotNull(constructor.returnType);
    JUnitTestCase.assertNull(constructor.period);
    JUnitTestCase.assertNull(constructor.name);
    JUnitTestCase.assertNotNull(constructor.parameters);
    JUnitTestCase.assertNotNull(constructor.separator);
    EngineTestCase.assertSizeOfList(0, constructor.initializers);
    JUnitTestCase.assertNotNull(constructor.redirectedConstructor);
    JUnitTestCase.assertNotNull(constructor.body);
  }

  void test_parseClassTypeAlias_abstract() {
    Token classToken = TokenFactory.tokenFromKeyword(Keyword.CLASS);
    Token abstractToken = TokenFactory.tokenFromKeyword(Keyword.ABSTRACT);
    ClassTypeAlias classTypeAlias = ParserTestCase.parse("parseClassTypeAlias", <Object> [emptyCommentAndMetadata(), abstractToken, classToken], "A = B with C;");
    JUnitTestCase.assertNotNull(classTypeAlias.keyword);
    JUnitTestCase.assertEquals("A", classTypeAlias.name.name);
    JUnitTestCase.assertNotNull(classTypeAlias.equals);
    JUnitTestCase.assertNotNull(classTypeAlias.abstractKeyword);
    JUnitTestCase.assertNotNullMsg("B", classTypeAlias.superclass.name.name);
    JUnitTestCase.assertNotNull(classTypeAlias.withClause);
    JUnitTestCase.assertNull(classTypeAlias.implementsClause);
    JUnitTestCase.assertNotNull(classTypeAlias.semicolon);
  }

  void test_parseClassTypeAlias_implements() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.CLASS);
    ClassTypeAlias classTypeAlias = ParserTestCase.parse("parseClassTypeAlias", <Object> [emptyCommentAndMetadata(), null, token], "A = B with C implements D;");
    JUnitTestCase.assertNotNull(classTypeAlias.keyword);
    JUnitTestCase.assertEquals("A", classTypeAlias.name.name);
    JUnitTestCase.assertNotNull(classTypeAlias.equals);
    JUnitTestCase.assertNull(classTypeAlias.abstractKeyword);
    JUnitTestCase.assertNotNullMsg("B", classTypeAlias.superclass.name.name);
    JUnitTestCase.assertNotNull(classTypeAlias.withClause);
    JUnitTestCase.assertNotNull(classTypeAlias.implementsClause);
    JUnitTestCase.assertNotNull(classTypeAlias.semicolon);
  }

  void test_parseClassTypeAlias_with() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.CLASS);
    ClassTypeAlias classTypeAlias = ParserTestCase.parse("parseClassTypeAlias", <Object> [emptyCommentAndMetadata(), null, token], "A = B with C;");
    JUnitTestCase.assertNotNull(classTypeAlias.keyword);
    JUnitTestCase.assertEquals("A", classTypeAlias.name.name);
    JUnitTestCase.assertNotNull(classTypeAlias.equals);
    JUnitTestCase.assertNull(classTypeAlias.abstractKeyword);
    JUnitTestCase.assertNotNullMsg("B", classTypeAlias.superclass.name.name);
    JUnitTestCase.assertNotNull(classTypeAlias.withClause);
    JUnitTestCase.assertNull(classTypeAlias.implementsClause);
    JUnitTestCase.assertNotNull(classTypeAlias.semicolon);
  }

  void test_parseClassTypeAlias_with_implements() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.CLASS);
    ClassTypeAlias classTypeAlias = ParserTestCase.parse("parseClassTypeAlias", <Object> [emptyCommentAndMetadata(), null, token], "A = B with C implements D;");
    JUnitTestCase.assertNotNull(classTypeAlias.keyword);
    JUnitTestCase.assertEquals("A", classTypeAlias.name.name);
    JUnitTestCase.assertNotNull(classTypeAlias.equals);
    JUnitTestCase.assertNull(classTypeAlias.abstractKeyword);
    JUnitTestCase.assertNotNullMsg("B", classTypeAlias.superclass.name.name);
    JUnitTestCase.assertNotNull(classTypeAlias.withClause);
    JUnitTestCase.assertNotNull(classTypeAlias.implementsClause);
    JUnitTestCase.assertNotNull(classTypeAlias.semicolon);
  }

  void test_parseCombinators_h() {
    List<Combinator> combinators = ParserTestCase.parse4("parseCombinators", "hide a;", []);
    EngineTestCase.assertSizeOfList(1, combinators);
    HideCombinator combinator = combinators[0] as HideCombinator;
    JUnitTestCase.assertNotNull(combinator);
    JUnitTestCase.assertNotNull(combinator.keyword);
    EngineTestCase.assertSizeOfList(1, combinator.hiddenNames);
  }

  void test_parseCombinators_hs() {
    List<Combinator> combinators = ParserTestCase.parse4("parseCombinators", "hide a show b;", []);
    EngineTestCase.assertSizeOfList(2, combinators);
    HideCombinator hideCombinator = combinators[0] as HideCombinator;
    JUnitTestCase.assertNotNull(hideCombinator);
    JUnitTestCase.assertNotNull(hideCombinator.keyword);
    EngineTestCase.assertSizeOfList(1, hideCombinator.hiddenNames);
    ShowCombinator showCombinator = combinators[1] as ShowCombinator;
    JUnitTestCase.assertNotNull(showCombinator);
    JUnitTestCase.assertNotNull(showCombinator.keyword);
    EngineTestCase.assertSizeOfList(1, showCombinator.shownNames);
  }

  void test_parseCombinators_hshs() {
    List<Combinator> combinators = ParserTestCase.parse4("parseCombinators", "hide a show b hide c show d;", []);
    EngineTestCase.assertSizeOfList(4, combinators);
  }

  void test_parseCombinators_s() {
    List<Combinator> combinators = ParserTestCase.parse4("parseCombinators", "show a;", []);
    EngineTestCase.assertSizeOfList(1, combinators);
    ShowCombinator combinator = combinators[0] as ShowCombinator;
    JUnitTestCase.assertNotNull(combinator);
    JUnitTestCase.assertNotNull(combinator.keyword);
    EngineTestCase.assertSizeOfList(1, combinator.shownNames);
  }

  void test_parseCommentAndMetadata_c() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse4("parseCommentAndMetadata", "/** 1 */ void", []);
    JUnitTestCase.assertNotNull(commentAndMetadata.comment);
    EngineTestCase.assertSizeOfList(0, commentAndMetadata.metadata);
  }

  void test_parseCommentAndMetadata_cmc() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse4("parseCommentAndMetadata", "/** 1 */ @A /** 2 */ void", []);
    JUnitTestCase.assertNotNull(commentAndMetadata.comment);
    EngineTestCase.assertSizeOfList(1, commentAndMetadata.metadata);
  }

  void test_parseCommentAndMetadata_cmcm() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse4("parseCommentAndMetadata", "/** 1 */ @A /** 2 */ @B void", []);
    JUnitTestCase.assertNotNull(commentAndMetadata.comment);
    EngineTestCase.assertSizeOfList(2, commentAndMetadata.metadata);
  }

  void test_parseCommentAndMetadata_cmm() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse4("parseCommentAndMetadata", "/** 1 */ @A @B void", []);
    JUnitTestCase.assertNotNull(commentAndMetadata.comment);
    EngineTestCase.assertSizeOfList(2, commentAndMetadata.metadata);
  }

  void test_parseCommentAndMetadata_m() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse4("parseCommentAndMetadata", "@A void", []);
    JUnitTestCase.assertNull(commentAndMetadata.comment);
    EngineTestCase.assertSizeOfList(1, commentAndMetadata.metadata);
  }

  void test_parseCommentAndMetadata_mcm() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse4("parseCommentAndMetadata", "@A /** 1 */ @B void", []);
    JUnitTestCase.assertNotNull(commentAndMetadata.comment);
    EngineTestCase.assertSizeOfList(2, commentAndMetadata.metadata);
  }

  void test_parseCommentAndMetadata_mcmc() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse4("parseCommentAndMetadata", "@A /** 1 */ @B /** 2 */ void", []);
    JUnitTestCase.assertNotNull(commentAndMetadata.comment);
    EngineTestCase.assertSizeOfList(2, commentAndMetadata.metadata);
  }

  void test_parseCommentAndMetadata_mm() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse4("parseCommentAndMetadata", "@A @B(x) void", []);
    JUnitTestCase.assertNull(commentAndMetadata.comment);
    EngineTestCase.assertSizeOfList(2, commentAndMetadata.metadata);
  }

  void test_parseCommentAndMetadata_none() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse4("parseCommentAndMetadata", "void", []);
    JUnitTestCase.assertNull(commentAndMetadata.comment);
    EngineTestCase.assertSizeOfList(0, commentAndMetadata.metadata);
  }

  void test_parseCommentAndMetadata_singleLine() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse4("parseCommentAndMetadata", EngineTestCase.createSource(["/// 1", "/// 2", "void"]), []);
    JUnitTestCase.assertNotNull(commentAndMetadata.comment);
    EngineTestCase.assertSizeOfList(0, commentAndMetadata.metadata);
  }

  void test_parseCommentReference_new_prefixed() {
    CommentReference reference = ParserTestCase.parse("parseCommentReference", <Object> ["new a.b", 7], "");
    PrefixedIdentifier prefixedIdentifier = EngineTestCase.assertInstanceOf((obj) => obj is PrefixedIdentifier, PrefixedIdentifier, reference.identifier);
    SimpleIdentifier prefix = prefixedIdentifier.prefix;
    JUnitTestCase.assertNotNull(prefix.token);
    JUnitTestCase.assertEquals("a", prefix.name);
    JUnitTestCase.assertEquals(11, prefix.offset);
    JUnitTestCase.assertNotNull(prefixedIdentifier.period);
    SimpleIdentifier identifier = prefixedIdentifier.identifier;
    JUnitTestCase.assertNotNull(identifier.token);
    JUnitTestCase.assertEquals("b", identifier.name);
    JUnitTestCase.assertEquals(13, identifier.offset);
  }

  void test_parseCommentReference_new_simple() {
    CommentReference reference = ParserTestCase.parse("parseCommentReference", <Object> ["new a", 5], "");
    SimpleIdentifier identifier = EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, reference.identifier);
    JUnitTestCase.assertNotNull(identifier.token);
    JUnitTestCase.assertEquals("a", identifier.name);
    JUnitTestCase.assertEquals(9, identifier.offset);
  }

  void test_parseCommentReference_prefixed() {
    CommentReference reference = ParserTestCase.parse("parseCommentReference", <Object> ["a.b", 7], "");
    PrefixedIdentifier prefixedIdentifier = EngineTestCase.assertInstanceOf((obj) => obj is PrefixedIdentifier, PrefixedIdentifier, reference.identifier);
    SimpleIdentifier prefix = prefixedIdentifier.prefix;
    JUnitTestCase.assertNotNull(prefix.token);
    JUnitTestCase.assertEquals("a", prefix.name);
    JUnitTestCase.assertEquals(7, prefix.offset);
    JUnitTestCase.assertNotNull(prefixedIdentifier.period);
    SimpleIdentifier identifier = prefixedIdentifier.identifier;
    JUnitTestCase.assertNotNull(identifier.token);
    JUnitTestCase.assertEquals("b", identifier.name);
    JUnitTestCase.assertEquals(9, identifier.offset);
  }

  void test_parseCommentReference_simple() {
    CommentReference reference = ParserTestCase.parse("parseCommentReference", <Object> ["a", 5], "");
    SimpleIdentifier identifier = EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, reference.identifier);
    JUnitTestCase.assertNotNull(identifier.token);
    JUnitTestCase.assertEquals("a", identifier.name);
    JUnitTestCase.assertEquals(5, identifier.offset);
  }

  void test_parseCommentReference_synthetic() {
    CommentReference reference = ParserTestCase.parse("parseCommentReference", <Object> ["", 5], "");
    SimpleIdentifier identifier = EngineTestCase.assertInstanceOf((obj) => obj is SimpleIdentifier, SimpleIdentifier, reference.identifier);
    JUnitTestCase.assertNotNull(identifier);
    JUnitTestCase.assertTrue(identifier.isSynthetic);
    JUnitTestCase.assertNotNull(identifier.token);
    JUnitTestCase.assertEquals("", identifier.name);
    JUnitTestCase.assertEquals(5, identifier.offset);
  }

  void test_parseCommentReferences_multiLine() {
    List<Token> tokens = <Token> [new StringToken(TokenType.MULTI_LINE_COMMENT, "/** xxx [a] yyy [b] zzz */", 3)];
    List<CommentReference> references = ParserTestCase.parse("parseCommentReferences", <Object> [tokens], "");
    EngineTestCase.assertSizeOfList(2, references);
    CommentReference reference = references[0];
    JUnitTestCase.assertNotNull(reference);
    JUnitTestCase.assertNotNull(reference.identifier);
    JUnitTestCase.assertEquals(12, reference.offset);
    reference = references[1];
    JUnitTestCase.assertNotNull(reference);
    JUnitTestCase.assertNotNull(reference.identifier);
    JUnitTestCase.assertEquals(20, reference.offset);
  }

  void test_parseCommentReferences_notClosed_noIdentifier() {
    List<Token> tokens = <Token> [new StringToken(TokenType.MULTI_LINE_COMMENT, "/** [ some text", 5)];
    List<CommentReference> references = ParserTestCase.parse("parseCommentReferences", <Object> [tokens], "");
    EngineTestCase.assertSizeOfList(1, references);
    CommentReference reference = references[0];
    JUnitTestCase.assertNotNull(reference);
    JUnitTestCase.assertNotNull(reference.identifier);
    JUnitTestCase.assertTrue(reference.identifier.isSynthetic);
    JUnitTestCase.assertEquals("", reference.identifier.name);
  }

  void test_parseCommentReferences_notClosed_withIdentifier() {
    List<Token> tokens = <Token> [new StringToken(TokenType.MULTI_LINE_COMMENT, "/** [namePrefix some text", 5)];
    List<CommentReference> references = ParserTestCase.parse("parseCommentReferences", <Object> [tokens], "");
    EngineTestCase.assertSizeOfList(1, references);
    CommentReference reference = references[0];
    JUnitTestCase.assertNotNull(reference);
    JUnitTestCase.assertNotNull(reference.identifier);
    JUnitTestCase.assertFalse(reference.identifier.isSynthetic);
    JUnitTestCase.assertEquals("namePrefix", reference.identifier.name);
  }

  void test_parseCommentReferences_singleLine() {
    List<Token> tokens = <Token> [
        new StringToken(TokenType.SINGLE_LINE_COMMENT, "/// xxx [a] yyy [b] zzz", 3),
        new StringToken(TokenType.SINGLE_LINE_COMMENT, "/// x [c]", 28)];
    List<CommentReference> references = ParserTestCase.parse("parseCommentReferences", <Object> [tokens], "");
    EngineTestCase.assertSizeOfList(3, references);
    CommentReference reference = references[0];
    JUnitTestCase.assertNotNull(reference);
    JUnitTestCase.assertNotNull(reference.identifier);
    JUnitTestCase.assertEquals(12, reference.offset);
    reference = references[1];
    JUnitTestCase.assertNotNull(reference);
    JUnitTestCase.assertNotNull(reference.identifier);
    JUnitTestCase.assertEquals(20, reference.offset);
    reference = references[2];
    JUnitTestCase.assertNotNull(reference);
    JUnitTestCase.assertNotNull(reference.identifier);
    JUnitTestCase.assertEquals(35, reference.offset);
  }

  void test_parseCommentReferences_skipCodeBlock_bracketed() {
    List<Token> tokens = <Token> [new StringToken(TokenType.MULTI_LINE_COMMENT, "/** [:xxx [a] yyy:] [b] zzz */", 3)];
    List<CommentReference> references = ParserTestCase.parse("parseCommentReferences", <Object> [tokens], "");
    EngineTestCase.assertSizeOfList(1, references);
    CommentReference reference = references[0];
    JUnitTestCase.assertNotNull(reference);
    JUnitTestCase.assertNotNull(reference.identifier);
    JUnitTestCase.assertEquals(24, reference.offset);
  }

  void test_parseCommentReferences_skipCodeBlock_spaces() {
    List<Token> tokens = <Token> [new StringToken(TokenType.MULTI_LINE_COMMENT, "/**\n *     a[i]\n * xxx [i] zzz\n */", 3)];
    List<CommentReference> references = ParserTestCase.parse("parseCommentReferences", <Object> [tokens], "");
    EngineTestCase.assertSizeOfList(1, references);
    CommentReference reference = references[0];
    JUnitTestCase.assertNotNull(reference);
    JUnitTestCase.assertNotNull(reference.identifier);
    JUnitTestCase.assertEquals(27, reference.offset);
  }

  void test_parseCommentReferences_skipLinkDefinition() {
    List<Token> tokens = <Token> [new StringToken(TokenType.MULTI_LINE_COMMENT, "/** [a]: http://www.google.com (Google) [b] zzz */", 3)];
    List<CommentReference> references = ParserTestCase.parse("parseCommentReferences", <Object> [tokens], "");
    EngineTestCase.assertSizeOfList(1, references);
    CommentReference reference = references[0];
    JUnitTestCase.assertNotNull(reference);
    JUnitTestCase.assertNotNull(reference.identifier);
    JUnitTestCase.assertEquals(44, reference.offset);
  }

  void test_parseCommentReferences_skipLinked() {
    List<Token> tokens = <Token> [new StringToken(TokenType.MULTI_LINE_COMMENT, "/** [a](http://www.google.com) [b] zzz */", 3)];
    List<CommentReference> references = ParserTestCase.parse("parseCommentReferences", <Object> [tokens], "");
    EngineTestCase.assertSizeOfList(1, references);
    CommentReference reference = references[0];
    JUnitTestCase.assertNotNull(reference);
    JUnitTestCase.assertNotNull(reference.identifier);
    JUnitTestCase.assertEquals(35, reference.offset);
  }

  void test_parseCommentReferences_skipReferenceLink() {
    List<Token> tokens = <Token> [new StringToken(TokenType.MULTI_LINE_COMMENT, "/** [a][c] [b] zzz */", 3)];
    List<CommentReference> references = ParserTestCase.parse("parseCommentReferences", <Object> [tokens], "");
    EngineTestCase.assertSizeOfList(1, references);
    CommentReference reference = references[0];
    JUnitTestCase.assertNotNull(reference);
    JUnitTestCase.assertNotNull(reference.identifier);
    JUnitTestCase.assertEquals(15, reference.offset);
  }

  void test_parseCompilationUnit_abstractAsPrefix_parameterized() {
    CompilationUnit unit = ParserTestCase.parse4("parseCompilationUnit", "abstract<dynamic> _abstract = new abstract.A();", []);
    JUnitTestCase.assertNull(unit.scriptTag);
    EngineTestCase.assertSizeOfList(0, unit.directives);
    EngineTestCase.assertSizeOfList(1, unit.declarations);
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
    JUnitTestCase.assertNull(unit.scriptTag);
    EngineTestCase.assertSizeOfList(2, unit.directives);
    EngineTestCase.assertSizeOfList(0, unit.declarations);
  }

  void test_parseCompilationUnit_directives_single() {
    CompilationUnit unit = ParserTestCase.parse4("parseCompilationUnit", "library l;", []);
    JUnitTestCase.assertNull(unit.scriptTag);
    EngineTestCase.assertSizeOfList(1, unit.directives);
    EngineTestCase.assertSizeOfList(0, unit.declarations);
  }

  void test_parseCompilationUnit_empty() {
    CompilationUnit unit = ParserTestCase.parse4("parseCompilationUnit", "", []);
    JUnitTestCase.assertNull(unit.scriptTag);
    EngineTestCase.assertSizeOfList(0, unit.directives);
    EngineTestCase.assertSizeOfList(0, unit.declarations);
  }

  void test_parseCompilationUnit_exportAsPrefix() {
    CompilationUnit unit = ParserTestCase.parse4("parseCompilationUnit", "export.A _export = new export.A();", []);
    JUnitTestCase.assertNull(unit.scriptTag);
    EngineTestCase.assertSizeOfList(0, unit.directives);
    EngineTestCase.assertSizeOfList(1, unit.declarations);
  }

  void test_parseCompilationUnit_exportAsPrefix_parameterized() {
    CompilationUnit unit = ParserTestCase.parse4("parseCompilationUnit", "export<dynamic> _export = new export.A();", []);
    JUnitTestCase.assertNull(unit.scriptTag);
    EngineTestCase.assertSizeOfList(0, unit.directives);
    EngineTestCase.assertSizeOfList(1, unit.declarations);
  }

  void test_parseCompilationUnit_operatorAsPrefix_parameterized() {
    CompilationUnit unit = ParserTestCase.parse4("parseCompilationUnit", "operator<dynamic> _operator = new operator.A();", []);
    JUnitTestCase.assertNull(unit.scriptTag);
    EngineTestCase.assertSizeOfList(0, unit.directives);
    EngineTestCase.assertSizeOfList(1, unit.declarations);
  }

  void test_parseCompilationUnit_script() {
    CompilationUnit unit = ParserTestCase.parse4("parseCompilationUnit", "#! /bin/dart", []);
    JUnitTestCase.assertNotNull(unit.scriptTag);
    EngineTestCase.assertSizeOfList(0, unit.directives);
    EngineTestCase.assertSizeOfList(0, unit.declarations);
  }

  void test_parseCompilationUnit_skipFunctionBody_withInterpolation() {
    ParserTestCase.parseFunctionBodies = false;
    CompilationUnit unit = ParserTestCase.parse4("parseCompilationUnit", "f() { '\${n}'; }", []);
    JUnitTestCase.assertNull(unit.scriptTag);
    EngineTestCase.assertSizeOfList(1, unit.declarations);
  }

  void test_parseCompilationUnit_topLevelDeclaration() {
    CompilationUnit unit = ParserTestCase.parse4("parseCompilationUnit", "class A {}", []);
    JUnitTestCase.assertNull(unit.scriptTag);
    EngineTestCase.assertSizeOfList(0, unit.directives);
    EngineTestCase.assertSizeOfList(1, unit.declarations);
  }

  void test_parseCompilationUnit_typedefAsPrefix() {
    CompilationUnit unit = ParserTestCase.parse4("parseCompilationUnit", "typedef.A _typedef = new typedef.A();", []);
    JUnitTestCase.assertNull(unit.scriptTag);
    EngineTestCase.assertSizeOfList(0, unit.directives);
    EngineTestCase.assertSizeOfList(1, unit.declarations);
  }

  void test_parseCompilationUnitMember_abstractAsPrefix() {
    TopLevelVariableDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "abstract.A _abstract = new abstract.A();");
    JUnitTestCase.assertNotNull(declaration.semicolon);
    JUnitTestCase.assertNotNull(declaration.variables);
  }

  void test_parseCompilationUnitMember_class() {
    ClassDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "class A {}");
    JUnitTestCase.assertEquals("A", declaration.name.name);
    EngineTestCase.assertSizeOfList(0, declaration.members);
  }

  void test_parseCompilationUnitMember_classTypeAlias() {
    ClassTypeAlias alias = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "abstract class A = B with C;");
    JUnitTestCase.assertEquals("A", alias.name.name);
    JUnitTestCase.assertNotNull(alias.abstractKeyword);
  }

  void test_parseCompilationUnitMember_constVariable() {
    TopLevelVariableDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "const int x = 0;");
    JUnitTestCase.assertNotNull(declaration.semicolon);
    JUnitTestCase.assertNotNull(declaration.variables);
  }

  void test_parseCompilationUnitMember_finalVariable() {
    TopLevelVariableDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "final x = 0;");
    JUnitTestCase.assertNotNull(declaration.semicolon);
    JUnitTestCase.assertNotNull(declaration.variables);
  }

  void test_parseCompilationUnitMember_function_external_noType() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "external f();");
    JUnitTestCase.assertNotNull(declaration.externalKeyword);
    JUnitTestCase.assertNotNull(declaration.functionExpression);
    JUnitTestCase.assertNull(declaration.propertyKeyword);
  }

  void test_parseCompilationUnitMember_function_external_type() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "external int f();");
    JUnitTestCase.assertNotNull(declaration.externalKeyword);
    JUnitTestCase.assertNotNull(declaration.functionExpression);
    JUnitTestCase.assertNull(declaration.propertyKeyword);
  }

  void test_parseCompilationUnitMember_function_noType() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "f() {}");
    JUnitTestCase.assertNotNull(declaration.functionExpression);
    JUnitTestCase.assertNull(declaration.propertyKeyword);
  }

  void test_parseCompilationUnitMember_function_type() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "int f() {}");
    JUnitTestCase.assertNotNull(declaration.functionExpression);
    JUnitTestCase.assertNull(declaration.propertyKeyword);
  }

  void test_parseCompilationUnitMember_function_void() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "void f() {}");
    JUnitTestCase.assertNotNull(declaration.returnType);
  }

  void test_parseCompilationUnitMember_getter_external_noType() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "external get p;");
    JUnitTestCase.assertNotNull(declaration.externalKeyword);
    JUnitTestCase.assertNotNull(declaration.functionExpression);
    JUnitTestCase.assertNotNull(declaration.propertyKeyword);
  }

  void test_parseCompilationUnitMember_getter_external_type() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "external int get p;");
    JUnitTestCase.assertNotNull(declaration.externalKeyword);
    JUnitTestCase.assertNotNull(declaration.functionExpression);
    JUnitTestCase.assertNotNull(declaration.propertyKeyword);
  }

  void test_parseCompilationUnitMember_getter_noType() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "get p => 0;");
    JUnitTestCase.assertNotNull(declaration.functionExpression);
    JUnitTestCase.assertNotNull(declaration.propertyKeyword);
  }

  void test_parseCompilationUnitMember_getter_type() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "int get p => 0;");
    JUnitTestCase.assertNotNull(declaration.functionExpression);
    JUnitTestCase.assertNotNull(declaration.propertyKeyword);
  }

  void test_parseCompilationUnitMember_setter_external_noType() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "external set p(v);");
    JUnitTestCase.assertNotNull(declaration.externalKeyword);
    JUnitTestCase.assertNotNull(declaration.functionExpression);
    JUnitTestCase.assertNotNull(declaration.propertyKeyword);
  }

  void test_parseCompilationUnitMember_setter_external_type() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "external void set p(int v);");
    JUnitTestCase.assertNotNull(declaration.externalKeyword);
    JUnitTestCase.assertNotNull(declaration.functionExpression);
    JUnitTestCase.assertNotNull(declaration.propertyKeyword);
  }

  void test_parseCompilationUnitMember_setter_noType() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "set p(v) {}");
    JUnitTestCase.assertNotNull(declaration.functionExpression);
    JUnitTestCase.assertNotNull(declaration.propertyKeyword);
  }

  void test_parseCompilationUnitMember_setter_type() {
    FunctionDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "void set p(int v) {}");
    JUnitTestCase.assertNotNull(declaration.functionExpression);
    JUnitTestCase.assertNotNull(declaration.propertyKeyword);
    JUnitTestCase.assertNotNull(declaration.returnType);
  }

  void test_parseCompilationUnitMember_typeAlias_abstract() {
    ClassTypeAlias typeAlias = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "abstract class C = S with M;");
    JUnitTestCase.assertNotNull(typeAlias.keyword);
    JUnitTestCase.assertEquals("C", typeAlias.name.name);
    JUnitTestCase.assertNull(typeAlias.typeParameters);
    JUnitTestCase.assertNotNull(typeAlias.equals);
    JUnitTestCase.assertNotNull(typeAlias.abstractKeyword);
    JUnitTestCase.assertEquals("S", typeAlias.superclass.name.name);
    JUnitTestCase.assertNotNull(typeAlias.withClause);
    JUnitTestCase.assertNull(typeAlias.implementsClause);
    JUnitTestCase.assertNotNull(typeAlias.semicolon);
  }

  void test_parseCompilationUnitMember_typeAlias_generic() {
    ClassTypeAlias typeAlias = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "class C<E> = S<E> with M<E> implements I<E>;");
    JUnitTestCase.assertNotNull(typeAlias.keyword);
    JUnitTestCase.assertEquals("C", typeAlias.name.name);
    EngineTestCase.assertSizeOfList(1, typeAlias.typeParameters.typeParameters);
    JUnitTestCase.assertNotNull(typeAlias.equals);
    JUnitTestCase.assertNull(typeAlias.abstractKeyword);
    JUnitTestCase.assertEquals("S", typeAlias.superclass.name.name);
    JUnitTestCase.assertNotNull(typeAlias.withClause);
    JUnitTestCase.assertNotNull(typeAlias.implementsClause);
    JUnitTestCase.assertNotNull(typeAlias.semicolon);
  }

  void test_parseCompilationUnitMember_typeAlias_implements() {
    ClassTypeAlias typeAlias = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "class C = S with M implements I;");
    JUnitTestCase.assertNotNull(typeAlias.keyword);
    JUnitTestCase.assertEquals("C", typeAlias.name.name);
    JUnitTestCase.assertNull(typeAlias.typeParameters);
    JUnitTestCase.assertNotNull(typeAlias.equals);
    JUnitTestCase.assertNull(typeAlias.abstractKeyword);
    JUnitTestCase.assertEquals("S", typeAlias.superclass.name.name);
    JUnitTestCase.assertNotNull(typeAlias.withClause);
    JUnitTestCase.assertNotNull(typeAlias.implementsClause);
    JUnitTestCase.assertNotNull(typeAlias.semicolon);
  }

  void test_parseCompilationUnitMember_typeAlias_noImplements() {
    ClassTypeAlias typeAlias = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "class C = S with M;");
    JUnitTestCase.assertNotNull(typeAlias.keyword);
    JUnitTestCase.assertEquals("C", typeAlias.name.name);
    JUnitTestCase.assertNull(typeAlias.typeParameters);
    JUnitTestCase.assertNotNull(typeAlias.equals);
    JUnitTestCase.assertNull(typeAlias.abstractKeyword);
    JUnitTestCase.assertEquals("S", typeAlias.superclass.name.name);
    JUnitTestCase.assertNotNull(typeAlias.withClause);
    JUnitTestCase.assertNull(typeAlias.implementsClause);
    JUnitTestCase.assertNotNull(typeAlias.semicolon);
  }

  void test_parseCompilationUnitMember_typedef() {
    FunctionTypeAlias typeAlias = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "typedef F();");
    JUnitTestCase.assertEquals("F", typeAlias.name.name);
    EngineTestCase.assertSizeOfList(0, typeAlias.parameters.parameters);
  }

  void test_parseCompilationUnitMember_variable() {
    TopLevelVariableDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "var x = 0;");
    JUnitTestCase.assertNotNull(declaration.semicolon);
    JUnitTestCase.assertNotNull(declaration.variables);
  }

  void test_parseCompilationUnitMember_variableGet() {
    TopLevelVariableDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "String get = null;");
    JUnitTestCase.assertNotNull(declaration.semicolon);
    JUnitTestCase.assertNotNull(declaration.variables);
  }

  void test_parseCompilationUnitMember_variableSet() {
    TopLevelVariableDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "String set = null;");
    JUnitTestCase.assertNotNull(declaration.semicolon);
    JUnitTestCase.assertNotNull(declaration.variables);
  }

  void test_parseConditionalExpression() {
    ConditionalExpression expression = ParserTestCase.parse4("parseConditionalExpression", "x ? y : z", []);
    JUnitTestCase.assertNotNull(expression.condition);
    JUnitTestCase.assertNotNull(expression.question);
    JUnitTestCase.assertNotNull(expression.thenExpression);
    JUnitTestCase.assertNotNull(expression.colon);
    JUnitTestCase.assertNotNull(expression.elseExpression);
  }

  void test_parseConstExpression_instanceCreation() {
    InstanceCreationExpression expression = ParserTestCase.parse4("parseConstExpression", "const A()", []);
    JUnitTestCase.assertNotNull(expression.keyword);
    ConstructorName name = expression.constructorName;
    JUnitTestCase.assertNotNull(name);
    JUnitTestCase.assertNotNull(name.type);
    JUnitTestCase.assertNull(name.period);
    JUnitTestCase.assertNull(name.name);
    JUnitTestCase.assertNotNull(expression.argumentList);
  }

  void test_parseConstExpression_listLiteral_typed() {
    ListLiteral literal = ParserTestCase.parse4("parseConstExpression", "const <A> []", []);
    JUnitTestCase.assertNotNull(literal.constKeyword);
    JUnitTestCase.assertNotNull(literal.typeArguments);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSizeOfList(0, literal.elements);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }

  void test_parseConstExpression_listLiteral_untyped() {
    ListLiteral literal = ParserTestCase.parse4("parseConstExpression", "const []", []);
    JUnitTestCase.assertNotNull(literal.constKeyword);
    JUnitTestCase.assertNull(literal.typeArguments);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSizeOfList(0, literal.elements);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }

  void test_parseConstExpression_mapLiteral_typed() {
    MapLiteral literal = ParserTestCase.parse4("parseConstExpression", "const <A, B> {}", []);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSizeOfList(0, literal.entries);
    JUnitTestCase.assertNotNull(literal.rightBracket);
    JUnitTestCase.assertNotNull(literal.typeArguments);
  }

  void test_parseConstExpression_mapLiteral_untyped() {
    MapLiteral literal = ParserTestCase.parse4("parseConstExpression", "const {}", []);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSizeOfList(0, literal.entries);
    JUnitTestCase.assertNotNull(literal.rightBracket);
    JUnitTestCase.assertNull(literal.typeArguments);
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
    EngineTestCase.assertSizeOfList(1, initializers);
    ConstructorInitializer initializer = initializers[0];
    EngineTestCase.assertInstanceOf((obj) => obj is ConstructorFieldInitializer, ConstructorFieldInitializer, initializer);
    EngineTestCase.assertInstanceOf((obj) => obj is ParenthesizedExpression, ParenthesizedExpression, (initializer as ConstructorFieldInitializer).expression);
    EngineTestCase.assertInstanceOf((obj) => obj is BlockFunctionBody, BlockFunctionBody, constructor.body);
  }

  void test_parseConstructorFieldInitializer_qualified() {
    ConstructorFieldInitializer invocation = ParserTestCase.parse4("parseConstructorFieldInitializer", "this.a = b", []);
    JUnitTestCase.assertNotNull(invocation.equals);
    JUnitTestCase.assertNotNull(invocation.expression);
    JUnitTestCase.assertNotNull(invocation.fieldName);
    JUnitTestCase.assertNotNull(invocation.keyword);
    JUnitTestCase.assertNotNull(invocation.period);
  }

  void test_parseConstructorFieldInitializer_unqualified() {
    ConstructorFieldInitializer invocation = ParserTestCase.parse4("parseConstructorFieldInitializer", "a = b", []);
    JUnitTestCase.assertNotNull(invocation.equals);
    JUnitTestCase.assertNotNull(invocation.expression);
    JUnitTestCase.assertNotNull(invocation.fieldName);
    JUnitTestCase.assertNull(invocation.keyword);
    JUnitTestCase.assertNull(invocation.period);
  }

  void test_parseConstructorName_named_noPrefix() {
    ConstructorName name = ParserTestCase.parse4("parseConstructorName", "A.n;", []);
    JUnitTestCase.assertNotNull(name.type);
    JUnitTestCase.assertNull(name.period);
    JUnitTestCase.assertNull(name.name);
  }

  void test_parseConstructorName_named_prefixed() {
    ConstructorName name = ParserTestCase.parse4("parseConstructorName", "p.A.n;", []);
    JUnitTestCase.assertNotNull(name.type);
    JUnitTestCase.assertNotNull(name.period);
    JUnitTestCase.assertNotNull(name.name);
  }

  void test_parseConstructorName_unnamed_noPrefix() {
    ConstructorName name = ParserTestCase.parse4("parseConstructorName", "A;", []);
    JUnitTestCase.assertNotNull(name.type);
    JUnitTestCase.assertNull(name.period);
    JUnitTestCase.assertNull(name.name);
  }

  void test_parseConstructorName_unnamed_prefixed() {
    ConstructorName name = ParserTestCase.parse4("parseConstructorName", "p.A;", []);
    JUnitTestCase.assertNotNull(name.type);
    JUnitTestCase.assertNull(name.period);
    JUnitTestCase.assertNull(name.name);
  }

  void test_parseContinueStatement_label() {
    ContinueStatement statement = ParserTestCase.parse4("parseContinueStatement", "continue foo;", [ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP]);
    JUnitTestCase.assertNotNull(statement.keyword);
    JUnitTestCase.assertNotNull(statement.label);
    JUnitTestCase.assertNotNull(statement.semicolon);
  }

  void test_parseContinueStatement_noLabel() {
    ContinueStatement statement = ParserTestCase.parse4("parseContinueStatement", "continue;", [ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP]);
    JUnitTestCase.assertNotNull(statement.keyword);
    JUnitTestCase.assertNull(statement.label);
    JUnitTestCase.assertNotNull(statement.semicolon);
  }

  void test_parseDirective_export() {
    ExportDirective directive = ParserTestCase.parse("parseDirective", <Object> [emptyCommentAndMetadata()], "export 'lib/lib.dart';");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    EngineTestCase.assertSizeOfList(0, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }

  void test_parseDirective_import() {
    ImportDirective directive = ParserTestCase.parse("parseDirective", <Object> [emptyCommentAndMetadata()], "import 'lib/lib.dart';");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    JUnitTestCase.assertNull(directive.asToken);
    JUnitTestCase.assertNull(directive.prefix);
    EngineTestCase.assertSizeOfList(0, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }

  void test_parseDirective_library() {
    LibraryDirective directive = ParserTestCase.parse("parseDirective", <Object> [emptyCommentAndMetadata()], "library l;");
    JUnitTestCase.assertNotNull(directive.libraryToken);
    JUnitTestCase.assertNotNull(directive.name);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }

  void test_parseDirective_part() {
    PartDirective directive = ParserTestCase.parse("parseDirective", <Object> [emptyCommentAndMetadata()], "part 'lib/lib.dart';");
    JUnitTestCase.assertNotNull(directive.partToken);
    JUnitTestCase.assertNotNull(directive.uri);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }

  void test_parseDirective_partOf() {
    PartOfDirective directive = ParserTestCase.parse("parseDirective", <Object> [emptyCommentAndMetadata()], "part of l;");
    JUnitTestCase.assertNotNull(directive.partToken);
    JUnitTestCase.assertNotNull(directive.ofToken);
    JUnitTestCase.assertNotNull(directive.libraryName);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }

  void test_parseDirectives_complete() {
    CompilationUnit unit = _parseDirectives("#! /bin/dart\nlibrary l;\nclass A {}", []);
    JUnitTestCase.assertNotNull(unit.scriptTag);
    EngineTestCase.assertSizeOfList(1, unit.directives);
  }

  void test_parseDirectives_empty() {
    CompilationUnit unit = _parseDirectives("", []);
    JUnitTestCase.assertNull(unit.scriptTag);
    EngineTestCase.assertSizeOfList(0, unit.directives);
  }

  void test_parseDirectives_mixed() {
    CompilationUnit unit = _parseDirectives("library l; class A {} part 'foo.dart';", []);
    JUnitTestCase.assertNull(unit.scriptTag);
    EngineTestCase.assertSizeOfList(1, unit.directives);
  }

  void test_parseDirectives_multiple() {
    CompilationUnit unit = _parseDirectives("library l;\npart 'a.dart';", []);
    JUnitTestCase.assertNull(unit.scriptTag);
    EngineTestCase.assertSizeOfList(2, unit.directives);
  }

  void test_parseDirectives_script() {
    CompilationUnit unit = _parseDirectives("#! /bin/dart", []);
    JUnitTestCase.assertNotNull(unit.scriptTag);
    EngineTestCase.assertSizeOfList(0, unit.directives);
  }

  void test_parseDirectives_single() {
    CompilationUnit unit = _parseDirectives("library l;", []);
    JUnitTestCase.assertNull(unit.scriptTag);
    EngineTestCase.assertSizeOfList(1, unit.directives);
  }

  void test_parseDirectives_topLevelDeclaration() {
    CompilationUnit unit = _parseDirectives("class A {}", []);
    JUnitTestCase.assertNull(unit.scriptTag);
    EngineTestCase.assertSizeOfList(0, unit.directives);
  }

  void test_parseDocumentationComment_block() {
    Comment comment = ParserTestCase.parse4("parseDocumentationComment", "/** */ class", []);
    JUnitTestCase.assertFalse(comment.isBlock);
    JUnitTestCase.assertTrue(comment.isDocumentation);
    JUnitTestCase.assertFalse(comment.isEndOfLine);
  }

  void test_parseDocumentationComment_block_withReference() {
    Comment comment = ParserTestCase.parse4("parseDocumentationComment", "/** [a] */ class", []);
    JUnitTestCase.assertFalse(comment.isBlock);
    JUnitTestCase.assertTrue(comment.isDocumentation);
    JUnitTestCase.assertFalse(comment.isEndOfLine);
    NodeList<CommentReference> references = comment.references;
    EngineTestCase.assertSizeOfList(1, references);
    CommentReference reference = references[0];
    JUnitTestCase.assertNotNull(reference);
    JUnitTestCase.assertEquals(5, reference.offset);
  }

  void test_parseDocumentationComment_endOfLine() {
    Comment comment = ParserTestCase.parse4("parseDocumentationComment", "/// \n/// \n class", []);
    JUnitTestCase.assertFalse(comment.isBlock);
    JUnitTestCase.assertTrue(comment.isDocumentation);
    JUnitTestCase.assertFalse(comment.isEndOfLine);
  }

  void test_parseDoStatement() {
    DoStatement statement = ParserTestCase.parse4("parseDoStatement", "do {} while (x);", []);
    JUnitTestCase.assertNotNull(statement.doKeyword);
    JUnitTestCase.assertNotNull(statement.body);
    JUnitTestCase.assertNotNull(statement.whileKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.semicolon);
  }

  void test_parseEmptyStatement() {
    EmptyStatement statement = ParserTestCase.parse4("parseEmptyStatement", ";", []);
    JUnitTestCase.assertNotNull(statement.semicolon);
  }

  void test_parseEnumDeclaration_one() {
    EnumDeclaration declaration = ParserTestCase.parse("parseEnumDeclaration", <Object> [emptyCommentAndMetadata()], "enum E {ONE}");
    JUnitTestCase.assertNull(declaration.documentationComment);
    JUnitTestCase.assertNotNull(declaration.keyword);
    JUnitTestCase.assertNotNull(declaration.leftBracket);
    JUnitTestCase.assertNotNull(declaration.name);
    EngineTestCase.assertSizeOfList(1, declaration.constants);
    JUnitTestCase.assertNotNull(declaration.rightBracket);
  }

  void test_parseEnumDeclaration_trailingComma() {
    EnumDeclaration declaration = ParserTestCase.parse("parseEnumDeclaration", <Object> [emptyCommentAndMetadata()], "enum E {ONE,}");
    JUnitTestCase.assertNull(declaration.documentationComment);
    JUnitTestCase.assertNotNull(declaration.keyword);
    JUnitTestCase.assertNotNull(declaration.leftBracket);
    JUnitTestCase.assertNotNull(declaration.name);
    EngineTestCase.assertSizeOfList(1, declaration.constants);
    JUnitTestCase.assertNotNull(declaration.rightBracket);
  }

  void test_parseEnumDeclaration_two() {
    EnumDeclaration declaration = ParserTestCase.parse("parseEnumDeclaration", <Object> [emptyCommentAndMetadata()], "enum E {ONE, TWO}");
    JUnitTestCase.assertNull(declaration.documentationComment);
    JUnitTestCase.assertNotNull(declaration.keyword);
    JUnitTestCase.assertNotNull(declaration.leftBracket);
    JUnitTestCase.assertNotNull(declaration.name);
    EngineTestCase.assertSizeOfList(2, declaration.constants);
    JUnitTestCase.assertNotNull(declaration.rightBracket);
  }

  void test_parseEqualityExpression_normal() {
    BinaryExpression expression = ParserTestCase.parse4("parseEqualityExpression", "x == y", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.EQ_EQ, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }

  void test_parseEqualityExpression_super() {
    BinaryExpression expression = ParserTestCase.parse4("parseEqualityExpression", "super == y", []);
    EngineTestCase.assertInstanceOf((obj) => obj is SuperExpression, SuperExpression, expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.EQ_EQ, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }

  void test_parseExportDirective_hide() {
    ExportDirective directive = ParserTestCase.parse("parseExportDirective", <Object> [emptyCommentAndMetadata()], "export 'lib/lib.dart' hide A, B;");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    EngineTestCase.assertSizeOfList(1, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }

  void test_parseExportDirective_hide_show() {
    ExportDirective directive = ParserTestCase.parse("parseExportDirective", <Object> [emptyCommentAndMetadata()], "export 'lib/lib.dart' hide A show B;");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    EngineTestCase.assertSizeOfList(2, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }

  void test_parseExportDirective_noCombinator() {
    ExportDirective directive = ParserTestCase.parse("parseExportDirective", <Object> [emptyCommentAndMetadata()], "export 'lib/lib.dart';");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    EngineTestCase.assertSizeOfList(0, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }

  void test_parseExportDirective_show() {
    ExportDirective directive = ParserTestCase.parse("parseExportDirective", <Object> [emptyCommentAndMetadata()], "export 'lib/lib.dart' show A, B;");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    EngineTestCase.assertSizeOfList(1, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }

  void test_parseExportDirective_show_hide() {
    ExportDirective directive = ParserTestCase.parse("parseExportDirective", <Object> [emptyCommentAndMetadata()], "export 'lib/lib.dart' show B hide A;");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    EngineTestCase.assertSizeOfList(2, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }

  void test_parseExpression_assign() {
    // TODO(brianwilkerson) Implement more tests for this method.
    AssignmentExpression expression = ParserTestCase.parse4("parseExpression", "x = y", []);
    JUnitTestCase.assertNotNull(expression.leftHandSide);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.EQ, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightHandSide);
  }

  void test_parseExpression_comparison() {
    BinaryExpression expression = ParserTestCase.parse4("parseExpression", "--a.b == c", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.EQ_EQ, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }

  void test_parseExpression_function_async() {
    FunctionExpression expression = ParserTestCase.parseExpression("() async {}", []);
    JUnitTestCase.assertNotNull(expression.body);
    JUnitTestCase.assertTrue(expression.body.isAsynchronous);
    JUnitTestCase.assertFalse(expression.body.isGenerator);
    JUnitTestCase.assertNotNull(expression.parameters);
  }

  void test_parseExpression_function_asyncStar() {
    FunctionExpression expression = ParserTestCase.parseExpression("() async* {}", []);
    JUnitTestCase.assertNotNull(expression.body);
    JUnitTestCase.assertTrue(expression.body.isAsynchronous);
    JUnitTestCase.assertTrue(expression.body.isGenerator);
    JUnitTestCase.assertNotNull(expression.parameters);
  }

  void test_parseExpression_function_sync() {
    FunctionExpression expression = ParserTestCase.parseExpression("() {}", []);
    JUnitTestCase.assertNotNull(expression.body);
    JUnitTestCase.assertFalse(expression.body.isAsynchronous);
    JUnitTestCase.assertFalse(expression.body.isGenerator);
    JUnitTestCase.assertNotNull(expression.parameters);
  }

  void test_parseExpression_function_syncStar() {
    FunctionExpression expression = ParserTestCase.parseExpression("() sync* {}", []);
    JUnitTestCase.assertNotNull(expression.body);
    JUnitTestCase.assertFalse(expression.body.isAsynchronous);
    JUnitTestCase.assertTrue(expression.body.isGenerator);
    JUnitTestCase.assertNotNull(expression.parameters);
  }

  void test_parseExpression_invokeFunctionExpression() {
    FunctionExpressionInvocation invocation = ParserTestCase.parse4("parseExpression", "(a) {return a + a;} (3)", []);
    EngineTestCase.assertInstanceOf((obj) => obj is FunctionExpression, FunctionExpression, invocation.function);
    FunctionExpression expression = invocation.function as FunctionExpression;
    JUnitTestCase.assertNotNull(expression.parameters);
    JUnitTestCase.assertNotNull(expression.body);
    ArgumentList list = invocation.argumentList;
    JUnitTestCase.assertNotNull(list);
    EngineTestCase.assertSizeOfList(1, list.arguments);
  }

  void test_parseExpression_superMethodInvocation() {
    MethodInvocation invocation = ParserTestCase.parse4("parseExpression", "super.m()", []);
    JUnitTestCase.assertNotNull(invocation.target);
    JUnitTestCase.assertNotNull(invocation.methodName);
    JUnitTestCase.assertNotNull(invocation.argumentList);
  }

  void test_parseExpressionList_multiple() {
    List<Expression> result = ParserTestCase.parse4("parseExpressionList", "1, 2, 3", []);
    EngineTestCase.assertSizeOfList(3, result);
  }

  void test_parseExpressionList_single() {
    List<Expression> result = ParserTestCase.parse4("parseExpressionList", "1", []);
    EngineTestCase.assertSizeOfList(1, result);
  }

  void test_parseExpressionWithoutCascade_assign() {
    // TODO(brianwilkerson) Implement more tests for this method.
    AssignmentExpression expression = ParserTestCase.parse4("parseExpressionWithoutCascade", "x = y", []);
    JUnitTestCase.assertNotNull(expression.leftHandSide);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.EQ, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightHandSide);
  }

  void test_parseExpressionWithoutCascade_comparison() {
    BinaryExpression expression = ParserTestCase.parse4("parseExpressionWithoutCascade", "--a.b == c", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.EQ_EQ, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }

  void test_parseExpressionWithoutCascade_superMethodInvocation() {
    MethodInvocation invocation = ParserTestCase.parse4("parseExpressionWithoutCascade", "super.m()", []);
    JUnitTestCase.assertNotNull(invocation.target);
    JUnitTestCase.assertNotNull(invocation.methodName);
    JUnitTestCase.assertNotNull(invocation.argumentList);
  }

  void test_parseExtendsClause() {
    ExtendsClause clause = ParserTestCase.parse4("parseExtendsClause", "extends B", []);
    JUnitTestCase.assertNotNull(clause.keyword);
    JUnitTestCase.assertNotNull(clause.superclass);
    EngineTestCase.assertInstanceOf((obj) => obj is TypeName, TypeName, clause.superclass);
  }

  void test_parseFinalConstVarOrType_const_noType() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "const");
    Token keyword = result.keyword;
    JUnitTestCase.assertNotNull(keyword);
    JUnitTestCase.assertEquals(TokenType.KEYWORD, keyword.type);
    JUnitTestCase.assertEquals(Keyword.CONST, (keyword as KeywordToken).keyword);
    JUnitTestCase.assertNull(result.type);
  }

  void test_parseFinalConstVarOrType_const_type() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "const A a");
    Token keyword = result.keyword;
    JUnitTestCase.assertNotNull(keyword);
    JUnitTestCase.assertEquals(TokenType.KEYWORD, keyword.type);
    JUnitTestCase.assertEquals(Keyword.CONST, (keyword as KeywordToken).keyword);
    JUnitTestCase.assertNotNull(result.type);
  }

  void test_parseFinalConstVarOrType_final_noType() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "final");
    Token keyword = result.keyword;
    JUnitTestCase.assertNotNull(keyword);
    JUnitTestCase.assertEquals(TokenType.KEYWORD, keyword.type);
    JUnitTestCase.assertEquals(Keyword.FINAL, (keyword as KeywordToken).keyword);
    JUnitTestCase.assertNull(result.type);
  }

  void test_parseFinalConstVarOrType_final_prefixedType() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "final p.A a");
    Token keyword = result.keyword;
    JUnitTestCase.assertNotNull(keyword);
    JUnitTestCase.assertEquals(TokenType.KEYWORD, keyword.type);
    JUnitTestCase.assertEquals(Keyword.FINAL, (keyword as KeywordToken).keyword);
    JUnitTestCase.assertNotNull(result.type);
  }

  void test_parseFinalConstVarOrType_final_type() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "final A a");
    Token keyword = result.keyword;
    JUnitTestCase.assertNotNull(keyword);
    JUnitTestCase.assertEquals(TokenType.KEYWORD, keyword.type);
    JUnitTestCase.assertEquals(Keyword.FINAL, (keyword as KeywordToken).keyword);
    JUnitTestCase.assertNotNull(result.type);
  }

  void test_parseFinalConstVarOrType_type_parameterized() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "A<B> a");
    JUnitTestCase.assertNull(result.keyword);
    JUnitTestCase.assertNotNull(result.type);
  }

  void test_parseFinalConstVarOrType_type_prefixed() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "p.A a");
    JUnitTestCase.assertNull(result.keyword);
    JUnitTestCase.assertNotNull(result.type);
  }

  void test_parseFinalConstVarOrType_type_prefixedAndParameterized() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "p.A<B> a");
    JUnitTestCase.assertNull(result.keyword);
    JUnitTestCase.assertNotNull(result.type);
  }

  void test_parseFinalConstVarOrType_type_simple() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "A a");
    JUnitTestCase.assertNull(result.keyword);
    JUnitTestCase.assertNotNull(result.type);
  }

  void test_parseFinalConstVarOrType_var() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "var");
    Token keyword = result.keyword;
    JUnitTestCase.assertNotNull(keyword);
    JUnitTestCase.assertEquals(TokenType.KEYWORD, keyword.type);
    JUnitTestCase.assertEquals(Keyword.VAR, (keyword as KeywordToken).keyword);
    JUnitTestCase.assertNull(result.type);
  }

  void test_parseFormalParameter_final_withType_named() {
    ParameterKind kind = ParameterKind.NAMED;
    DefaultFormalParameter parameter = ParserTestCase.parse("parseFormalParameter", <Object> [kind], "final A a : null");
    SimpleFormalParameter simpleParameter = parameter.parameter as SimpleFormalParameter;
    JUnitTestCase.assertNotNull(simpleParameter.identifier);
    JUnitTestCase.assertNotNull(simpleParameter.keyword);
    JUnitTestCase.assertNotNull(simpleParameter.type);
    JUnitTestCase.assertEquals(kind, simpleParameter.kind);
    JUnitTestCase.assertNotNull(parameter.separator);
    JUnitTestCase.assertNotNull(parameter.defaultValue);
    JUnitTestCase.assertEquals(kind, parameter.kind);
  }

  void test_parseFormalParameter_final_withType_normal() {
    ParameterKind kind = ParameterKind.REQUIRED;
    SimpleFormalParameter parameter = ParserTestCase.parse("parseFormalParameter", <Object> [kind], "final A a");
    JUnitTestCase.assertNotNull(parameter.identifier);
    JUnitTestCase.assertNotNull(parameter.keyword);
    JUnitTestCase.assertNotNull(parameter.type);
    JUnitTestCase.assertEquals(kind, parameter.kind);
  }

  void test_parseFormalParameter_final_withType_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    DefaultFormalParameter parameter = ParserTestCase.parse("parseFormalParameter", <Object> [kind], "final A a = null");
    SimpleFormalParameter simpleParameter = parameter.parameter as SimpleFormalParameter;
    JUnitTestCase.assertNotNull(simpleParameter.identifier);
    JUnitTestCase.assertNotNull(simpleParameter.keyword);
    JUnitTestCase.assertNotNull(simpleParameter.type);
    JUnitTestCase.assertEquals(kind, simpleParameter.kind);
    JUnitTestCase.assertNotNull(parameter.separator);
    JUnitTestCase.assertNotNull(parameter.defaultValue);
    JUnitTestCase.assertEquals(kind, parameter.kind);
  }

  void test_parseFormalParameter_nonFinal_withType_named() {
    ParameterKind kind = ParameterKind.NAMED;
    DefaultFormalParameter parameter = ParserTestCase.parse("parseFormalParameter", <Object> [kind], "A a : null");
    SimpleFormalParameter simpleParameter = parameter.parameter as SimpleFormalParameter;
    JUnitTestCase.assertNotNull(simpleParameter.identifier);
    JUnitTestCase.assertNull(simpleParameter.keyword);
    JUnitTestCase.assertNotNull(simpleParameter.type);
    JUnitTestCase.assertEquals(kind, simpleParameter.kind);
    JUnitTestCase.assertNotNull(parameter.separator);
    JUnitTestCase.assertNotNull(parameter.defaultValue);
    JUnitTestCase.assertEquals(kind, parameter.kind);
  }

  void test_parseFormalParameter_nonFinal_withType_normal() {
    ParameterKind kind = ParameterKind.REQUIRED;
    SimpleFormalParameter parameter = ParserTestCase.parse("parseFormalParameter", <Object> [kind], "A a");
    JUnitTestCase.assertNotNull(parameter.identifier);
    JUnitTestCase.assertNull(parameter.keyword);
    JUnitTestCase.assertNotNull(parameter.type);
    JUnitTestCase.assertEquals(kind, parameter.kind);
  }

  void test_parseFormalParameter_nonFinal_withType_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    DefaultFormalParameter parameter = ParserTestCase.parse("parseFormalParameter", <Object> [kind], "A a = null");
    SimpleFormalParameter simpleParameter = parameter.parameter as SimpleFormalParameter;
    JUnitTestCase.assertNotNull(simpleParameter.identifier);
    JUnitTestCase.assertNull(simpleParameter.keyword);
    JUnitTestCase.assertNotNull(simpleParameter.type);
    JUnitTestCase.assertEquals(kind, simpleParameter.kind);
    JUnitTestCase.assertNotNull(parameter.separator);
    JUnitTestCase.assertNotNull(parameter.defaultValue);
    JUnitTestCase.assertEquals(kind, parameter.kind);
  }

  void test_parseFormalParameter_var() {
    ParameterKind kind = ParameterKind.REQUIRED;
    SimpleFormalParameter parameter = ParserTestCase.parse("parseFormalParameter", <Object> [kind], "var a");
    JUnitTestCase.assertNotNull(parameter.identifier);
    JUnitTestCase.assertNotNull(parameter.keyword);
    JUnitTestCase.assertNull(parameter.type);
    JUnitTestCase.assertEquals(kind, parameter.kind);
  }

  void test_parseFormalParameter_var_named() {
    ParameterKind kind = ParameterKind.NAMED;
    DefaultFormalParameter parameter = ParserTestCase.parse("parseFormalParameter", <Object> [kind], "var a : null");
    SimpleFormalParameter simpleParameter = parameter.parameter as SimpleFormalParameter;
    JUnitTestCase.assertNotNull(simpleParameter.identifier);
    JUnitTestCase.assertNotNull(simpleParameter.keyword);
    JUnitTestCase.assertNull(simpleParameter.type);
    JUnitTestCase.assertEquals(kind, simpleParameter.kind);
    JUnitTestCase.assertNotNull(parameter.separator);
    JUnitTestCase.assertNotNull(parameter.defaultValue);
    JUnitTestCase.assertEquals(kind, parameter.kind);
  }

  void test_parseFormalParameter_var_positional() {
    ParameterKind kind = ParameterKind.POSITIONAL;
    DefaultFormalParameter parameter = ParserTestCase.parse("parseFormalParameter", <Object> [kind], "var a = null");
    SimpleFormalParameter simpleParameter = parameter.parameter as SimpleFormalParameter;
    JUnitTestCase.assertNotNull(simpleParameter.identifier);
    JUnitTestCase.assertNotNull(simpleParameter.keyword);
    JUnitTestCase.assertNull(simpleParameter.type);
    JUnitTestCase.assertEquals(kind, simpleParameter.kind);
    JUnitTestCase.assertNotNull(parameter.separator);
    JUnitTestCase.assertNotNull(parameter.defaultValue);
    JUnitTestCase.assertEquals(kind, parameter.kind);
  }

  void test_parseFormalParameterList_empty() {
    FormalParameterList parameterList = ParserTestCase.parse4("parseFormalParameterList", "()", []);
    JUnitTestCase.assertNotNull(parameterList.leftParenthesis);
    JUnitTestCase.assertNull(parameterList.leftDelimiter);
    EngineTestCase.assertSizeOfList(0, parameterList.parameters);
    JUnitTestCase.assertNull(parameterList.rightDelimiter);
    JUnitTestCase.assertNotNull(parameterList.rightParenthesis);
  }

  void test_parseFormalParameterList_named_multiple() {
    FormalParameterList parameterList = ParserTestCase.parse4("parseFormalParameterList", "({A a : 1, B b, C c : 3})", []);
    JUnitTestCase.assertNotNull(parameterList.leftParenthesis);
    JUnitTestCase.assertNotNull(parameterList.leftDelimiter);
    EngineTestCase.assertSizeOfList(3, parameterList.parameters);
    JUnitTestCase.assertNotNull(parameterList.rightDelimiter);
    JUnitTestCase.assertNotNull(parameterList.rightParenthesis);
  }

  void test_parseFormalParameterList_named_single() {
    FormalParameterList parameterList = ParserTestCase.parse4("parseFormalParameterList", "({A a})", []);
    JUnitTestCase.assertNotNull(parameterList.leftParenthesis);
    JUnitTestCase.assertNotNull(parameterList.leftDelimiter);
    EngineTestCase.assertSizeOfList(1, parameterList.parameters);
    JUnitTestCase.assertNotNull(parameterList.rightDelimiter);
    JUnitTestCase.assertNotNull(parameterList.rightParenthesis);
  }

  void test_parseFormalParameterList_normal_multiple() {
    FormalParameterList parameterList = ParserTestCase.parse4("parseFormalParameterList", "(A a, B b, C c)", []);
    JUnitTestCase.assertNotNull(parameterList.leftParenthesis);
    JUnitTestCase.assertNull(parameterList.leftDelimiter);
    EngineTestCase.assertSizeOfList(3, parameterList.parameters);
    JUnitTestCase.assertNull(parameterList.rightDelimiter);
    JUnitTestCase.assertNotNull(parameterList.rightParenthesis);
  }

  void test_parseFormalParameterList_normal_named() {
    FormalParameterList parameterList = ParserTestCase.parse4("parseFormalParameterList", "(A a, {B b})", []);
    JUnitTestCase.assertNotNull(parameterList.leftParenthesis);
    JUnitTestCase.assertNotNull(parameterList.leftDelimiter);
    EngineTestCase.assertSizeOfList(2, parameterList.parameters);
    JUnitTestCase.assertNotNull(parameterList.rightDelimiter);
    JUnitTestCase.assertNotNull(parameterList.rightParenthesis);
  }

  void test_parseFormalParameterList_normal_positional() {
    FormalParameterList parameterList = ParserTestCase.parse4("parseFormalParameterList", "(A a, [B b])", []);
    JUnitTestCase.assertNotNull(parameterList.leftParenthesis);
    JUnitTestCase.assertNotNull(parameterList.leftDelimiter);
    EngineTestCase.assertSizeOfList(2, parameterList.parameters);
    JUnitTestCase.assertNotNull(parameterList.rightDelimiter);
    JUnitTestCase.assertNotNull(parameterList.rightParenthesis);
  }

  void test_parseFormalParameterList_normal_single() {
    FormalParameterList parameterList = ParserTestCase.parse4("parseFormalParameterList", "(A a)", []);
    JUnitTestCase.assertNotNull(parameterList.leftParenthesis);
    JUnitTestCase.assertNull(parameterList.leftDelimiter);
    EngineTestCase.assertSizeOfList(1, parameterList.parameters);
    JUnitTestCase.assertNull(parameterList.rightDelimiter);
    JUnitTestCase.assertNotNull(parameterList.rightParenthesis);
  }

  void test_parseFormalParameterList_positional_multiple() {
    FormalParameterList parameterList = ParserTestCase.parse4("parseFormalParameterList", "([A a = null, B b, C c = null])", []);
    JUnitTestCase.assertNotNull(parameterList.leftParenthesis);
    JUnitTestCase.assertNotNull(parameterList.leftDelimiter);
    EngineTestCase.assertSizeOfList(3, parameterList.parameters);
    JUnitTestCase.assertNotNull(parameterList.rightDelimiter);
    JUnitTestCase.assertNotNull(parameterList.rightParenthesis);
  }

  void test_parseFormalParameterList_positional_single() {
    FormalParameterList parameterList = ParserTestCase.parse4("parseFormalParameterList", "([A a = null])", []);
    JUnitTestCase.assertNotNull(parameterList.leftParenthesis);
    JUnitTestCase.assertNotNull(parameterList.leftDelimiter);
    EngineTestCase.assertSizeOfList(1, parameterList.parameters);
    JUnitTestCase.assertNotNull(parameterList.rightDelimiter);
    JUnitTestCase.assertNotNull(parameterList.rightParenthesis);
  }

  void test_parseForStatement_each_await() {
    ForEachStatement statement = ParserTestCase.parse4("parseForStatement", "await for (element in list) {}", []);
    JUnitTestCase.assertNotNull(statement.awaitKeyword);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNull(statement.loopVariable);
    JUnitTestCase.assertNotNull(statement.identifier);
    JUnitTestCase.assertNotNull(statement.inKeyword);
    JUnitTestCase.assertNotNull(statement.iterator);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }

  void test_parseForStatement_each_identifier() {
    ForEachStatement statement = ParserTestCase.parse4("parseForStatement", "for (element in list) {}", []);
    JUnitTestCase.assertNull(statement.awaitKeyword);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNull(statement.loopVariable);
    JUnitTestCase.assertNotNull(statement.identifier);
    JUnitTestCase.assertNotNull(statement.inKeyword);
    JUnitTestCase.assertNotNull(statement.iterator);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }

  void test_parseForStatement_each_noType_metadata() {
    ForEachStatement statement = ParserTestCase.parse4("parseForStatement", "for (@A var element in list) {}", []);
    JUnitTestCase.assertNull(statement.awaitKeyword);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.loopVariable);
    EngineTestCase.assertSizeOfList(1, statement.loopVariable.metadata);
    JUnitTestCase.assertNull(statement.identifier);
    JUnitTestCase.assertNotNull(statement.inKeyword);
    JUnitTestCase.assertNotNull(statement.iterator);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }

  void test_parseForStatement_each_type() {
    ForEachStatement statement = ParserTestCase.parse4("parseForStatement", "for (A element in list) {}", []);
    JUnitTestCase.assertNull(statement.awaitKeyword);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.loopVariable);
    JUnitTestCase.assertNull(statement.identifier);
    JUnitTestCase.assertNotNull(statement.inKeyword);
    JUnitTestCase.assertNotNull(statement.iterator);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }

  void test_parseForStatement_each_var() {
    ForEachStatement statement = ParserTestCase.parse4("parseForStatement", "for (var element in list) {}", []);
    JUnitTestCase.assertNull(statement.awaitKeyword);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.loopVariable);
    JUnitTestCase.assertNull(statement.identifier);
    JUnitTestCase.assertNotNull(statement.inKeyword);
    JUnitTestCase.assertNotNull(statement.iterator);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }

  void test_parseForStatement_loop_c() {
    ForStatement statement = ParserTestCase.parse4("parseForStatement", "for (; i < count;) {}", []);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNull(statement.variables);
    JUnitTestCase.assertNull(statement.initialization);
    JUnitTestCase.assertNotNull(statement.leftSeparator);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightSeparator);
    EngineTestCase.assertSizeOfList(0, statement.updaters);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }

  void test_parseForStatement_loop_cu() {
    ForStatement statement = ParserTestCase.parse4("parseForStatement", "for (; i < count; i++) {}", []);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNull(statement.variables);
    JUnitTestCase.assertNull(statement.initialization);
    JUnitTestCase.assertNotNull(statement.leftSeparator);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightSeparator);
    EngineTestCase.assertSizeOfList(1, statement.updaters);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }

  void test_parseForStatement_loop_ecu() {
    ForStatement statement = ParserTestCase.parse4("parseForStatement", "for (i--; i < count; i++) {}", []);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNull(statement.variables);
    JUnitTestCase.assertNotNull(statement.initialization);
    JUnitTestCase.assertNotNull(statement.leftSeparator);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightSeparator);
    EngineTestCase.assertSizeOfList(1, statement.updaters);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }

  void test_parseForStatement_loop_i() {
    ForStatement statement = ParserTestCase.parse4("parseForStatement", "for (var i = 0;;) {}", []);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    VariableDeclarationList variables = statement.variables;
    JUnitTestCase.assertNotNull(variables);
    EngineTestCase.assertSizeOfList(0, variables.metadata);
    EngineTestCase.assertSizeOfList(1, variables.variables);
    JUnitTestCase.assertNull(statement.initialization);
    JUnitTestCase.assertNotNull(statement.leftSeparator);
    JUnitTestCase.assertNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightSeparator);
    EngineTestCase.assertSizeOfList(0, statement.updaters);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }

  void test_parseForStatement_loop_i_withMetadata() {
    ForStatement statement = ParserTestCase.parse4("parseForStatement", "for (@A var i = 0;;) {}", []);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    VariableDeclarationList variables = statement.variables;
    JUnitTestCase.assertNotNull(variables);
    EngineTestCase.assertSizeOfList(1, variables.metadata);
    EngineTestCase.assertSizeOfList(1, variables.variables);
    JUnitTestCase.assertNull(statement.initialization);
    JUnitTestCase.assertNotNull(statement.leftSeparator);
    JUnitTestCase.assertNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightSeparator);
    EngineTestCase.assertSizeOfList(0, statement.updaters);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }

  void test_parseForStatement_loop_ic() {
    ForStatement statement = ParserTestCase.parse4("parseForStatement", "for (var i = 0; i < count;) {}", []);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    VariableDeclarationList variables = statement.variables;
    JUnitTestCase.assertNotNull(variables);
    EngineTestCase.assertSizeOfList(1, variables.variables);
    JUnitTestCase.assertNull(statement.initialization);
    JUnitTestCase.assertNotNull(statement.leftSeparator);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightSeparator);
    EngineTestCase.assertSizeOfList(0, statement.updaters);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }

  void test_parseForStatement_loop_icu() {
    ForStatement statement = ParserTestCase.parse4("parseForStatement", "for (var i = 0; i < count; i++) {}", []);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    VariableDeclarationList variables = statement.variables;
    JUnitTestCase.assertNotNull(variables);
    EngineTestCase.assertSizeOfList(1, variables.variables);
    JUnitTestCase.assertNull(statement.initialization);
    JUnitTestCase.assertNotNull(statement.leftSeparator);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightSeparator);
    EngineTestCase.assertSizeOfList(1, statement.updaters);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }

  void test_parseForStatement_loop_iicuu() {
    ForStatement statement = ParserTestCase.parse4("parseForStatement", "for (int i = 0, j = count; i < j; i++, j--) {}", []);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    VariableDeclarationList variables = statement.variables;
    JUnitTestCase.assertNotNull(variables);
    EngineTestCase.assertSizeOfList(2, variables.variables);
    JUnitTestCase.assertNull(statement.initialization);
    JUnitTestCase.assertNotNull(statement.leftSeparator);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightSeparator);
    EngineTestCase.assertSizeOfList(2, statement.updaters);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }

  void test_parseForStatement_loop_iu() {
    ForStatement statement = ParserTestCase.parse4("parseForStatement", "for (var i = 0;; i++) {}", []);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    VariableDeclarationList variables = statement.variables;
    JUnitTestCase.assertNotNull(variables);
    EngineTestCase.assertSizeOfList(1, variables.variables);
    JUnitTestCase.assertNull(statement.initialization);
    JUnitTestCase.assertNotNull(statement.leftSeparator);
    JUnitTestCase.assertNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightSeparator);
    EngineTestCase.assertSizeOfList(1, statement.updaters);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }

  void test_parseForStatement_loop_u() {
    ForStatement statement = ParserTestCase.parse4("parseForStatement", "for (;; i++) {}", []);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNull(statement.variables);
    JUnitTestCase.assertNull(statement.initialization);
    JUnitTestCase.assertNotNull(statement.leftSeparator);
    JUnitTestCase.assertNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightSeparator);
    EngineTestCase.assertSizeOfList(1, statement.updaters);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }

  void test_parseFunctionBody_block() {
    BlockFunctionBody functionBody = ParserTestCase.parse("parseFunctionBody", <Object> [false, null, false], "{}");
    JUnitTestCase.assertNull(functionBody.keyword);
    JUnitTestCase.assertNull(functionBody.star);
    JUnitTestCase.assertNotNull(functionBody.block);
    JUnitTestCase.assertFalse(functionBody.isAsynchronous);
    JUnitTestCase.assertFalse(functionBody.isGenerator);
    JUnitTestCase.assertTrue(functionBody.isSynchronous);
  }

  void test_parseFunctionBody_block_async() {
    BlockFunctionBody functionBody = ParserTestCase.parse("parseFunctionBody", <Object> [false, null, false], "async {}");
    JUnitTestCase.assertNotNull(functionBody.keyword);
    JUnitTestCase.assertEquals(Parser.ASYNC, functionBody.keyword.lexeme);
    JUnitTestCase.assertNull(functionBody.star);
    JUnitTestCase.assertNotNull(functionBody.block);
    JUnitTestCase.assertTrue(functionBody.isAsynchronous);
    JUnitTestCase.assertFalse(functionBody.isGenerator);
    JUnitTestCase.assertFalse(functionBody.isSynchronous);
  }

  void test_parseFunctionBody_block_asyncGenerator() {
    BlockFunctionBody functionBody = ParserTestCase.parse("parseFunctionBody", <Object> [false, null, false], "async* {}");
    JUnitTestCase.assertNotNull(functionBody.keyword);
    JUnitTestCase.assertEquals(Parser.ASYNC, functionBody.keyword.lexeme);
    JUnitTestCase.assertNotNull(functionBody.star);
    JUnitTestCase.assertNotNull(functionBody.block);
    JUnitTestCase.assertTrue(functionBody.isAsynchronous);
    JUnitTestCase.assertTrue(functionBody.isGenerator);
    JUnitTestCase.assertFalse(functionBody.isSynchronous);
  }

  void test_parseFunctionBody_block_syncGenerator() {
    BlockFunctionBody functionBody = ParserTestCase.parse("parseFunctionBody", <Object> [false, null, false], "sync* {}");
    JUnitTestCase.assertNotNull(functionBody.keyword);
    JUnitTestCase.assertEquals(Parser.SYNC, functionBody.keyword.lexeme);
    JUnitTestCase.assertNotNull(functionBody.star);
    JUnitTestCase.assertNotNull(functionBody.block);
    JUnitTestCase.assertFalse(functionBody.isAsynchronous);
    JUnitTestCase.assertTrue(functionBody.isGenerator);
    JUnitTestCase.assertTrue(functionBody.isSynchronous);
  }

  void test_parseFunctionBody_empty() {
    EmptyFunctionBody functionBody = ParserTestCase.parse("parseFunctionBody", <Object> [true, null, false], ";");
    JUnitTestCase.assertNotNull(functionBody.semicolon);
  }

  void test_parseFunctionBody_expression() {
    ExpressionFunctionBody functionBody = ParserTestCase.parse("parseFunctionBody", <Object> [false, null, false], "=> y;");
    JUnitTestCase.assertNull(functionBody.keyword);
    JUnitTestCase.assertNotNull(functionBody.functionDefinition);
    JUnitTestCase.assertNotNull(functionBody.expression);
    JUnitTestCase.assertNotNull(functionBody.semicolon);
    JUnitTestCase.assertFalse(functionBody.isAsynchronous);
    JUnitTestCase.assertFalse(functionBody.isGenerator);
    JUnitTestCase.assertTrue(functionBody.isSynchronous);
  }

  void test_parseFunctionBody_expression_async() {
    ExpressionFunctionBody functionBody = ParserTestCase.parse("parseFunctionBody", <Object> [false, null, false], "async => y;");
    JUnitTestCase.assertNotNull(functionBody.keyword);
    JUnitTestCase.assertEquals(Parser.ASYNC, functionBody.keyword.lexeme);
    JUnitTestCase.assertNotNull(functionBody.functionDefinition);
    JUnitTestCase.assertNotNull(functionBody.expression);
    JUnitTestCase.assertNotNull(functionBody.semicolon);
    JUnitTestCase.assertTrue(functionBody.isAsynchronous);
    JUnitTestCase.assertFalse(functionBody.isGenerator);
    JUnitTestCase.assertFalse(functionBody.isSynchronous);
  }

  void test_parseFunctionBody_nativeFunctionBody() {
    NativeFunctionBody functionBody = ParserTestCase.parse("parseFunctionBody", <Object> [false, null, false], "native 'str';");
    JUnitTestCase.assertNotNull(functionBody.nativeToken);
    JUnitTestCase.assertNotNull(functionBody.stringLiteral);
    JUnitTestCase.assertNotNull(functionBody.semicolon);
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
    JUnitTestCase.assertEquals(comment, declaration.documentationComment);
    JUnitTestCase.assertEquals(returnType, declaration.returnType);
    JUnitTestCase.assertNotNull(declaration.name);
    FunctionExpression expression = declaration.functionExpression;
    JUnitTestCase.assertNotNull(expression);
    JUnitTestCase.assertNotNull(expression.body);
    JUnitTestCase.assertNotNull(expression.parameters);
    JUnitTestCase.assertNull(declaration.propertyKeyword);
  }

  void test_parseFunctionDeclaration_getter() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    TypeName returnType = new TypeName(new SimpleIdentifier(null), null);
    FunctionDeclaration declaration = ParserTestCase.parse("parseFunctionDeclaration", <Object> [commentAndMetadata(comment, []), null, returnType], "get p => 0;");
    JUnitTestCase.assertEquals(comment, declaration.documentationComment);
    JUnitTestCase.assertEquals(returnType, declaration.returnType);
    JUnitTestCase.assertNotNull(declaration.name);
    FunctionExpression expression = declaration.functionExpression;
    JUnitTestCase.assertNotNull(expression);
    JUnitTestCase.assertNotNull(expression.body);
    JUnitTestCase.assertNull(expression.parameters);
    JUnitTestCase.assertNotNull(declaration.propertyKeyword);
  }

  void test_parseFunctionDeclaration_setter() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    TypeName returnType = new TypeName(new SimpleIdentifier(null), null);
    FunctionDeclaration declaration = ParserTestCase.parse("parseFunctionDeclaration", <Object> [commentAndMetadata(comment, []), null, returnType], "set p(v) {}");
    JUnitTestCase.assertEquals(comment, declaration.documentationComment);
    JUnitTestCase.assertEquals(returnType, declaration.returnType);
    JUnitTestCase.assertNotNull(declaration.name);
    FunctionExpression expression = declaration.functionExpression;
    JUnitTestCase.assertNotNull(expression);
    JUnitTestCase.assertNotNull(expression.body);
    JUnitTestCase.assertNotNull(expression.parameters);
    JUnitTestCase.assertNotNull(declaration.propertyKeyword);
  }

  void test_parseFunctionDeclarationStatement() {
    FunctionDeclarationStatement statement = ParserTestCase.parse4("parseFunctionDeclarationStatement", "void f(int p) => p * 2;", []);
    JUnitTestCase.assertNotNull(statement.functionDeclaration);
  }

  void test_parseFunctionExpression_body_inExpression() {
    FunctionExpression expression = ParserTestCase.parse4("parseFunctionExpression", "(int i) => i++", []);
    JUnitTestCase.assertNotNull(expression.body);
    JUnitTestCase.assertNotNull(expression.parameters);
    JUnitTestCase.assertNull((expression.body as ExpressionFunctionBody).semicolon);
  }

  void test_parseGetter_nonStatic() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    TypeName returnType = new TypeName(new SimpleIdentifier(null), null);
    MethodDeclaration method = ParserTestCase.parse("parseGetter", <Object> [commentAndMetadata(comment, []), null, null, returnType], "get a;");
    JUnitTestCase.assertNotNull(method.body);
    JUnitTestCase.assertEquals(comment, method.documentationComment);
    JUnitTestCase.assertNull(method.externalKeyword);
    JUnitTestCase.assertNull(method.modifierKeyword);
    JUnitTestCase.assertNotNull(method.name);
    JUnitTestCase.assertNull(method.operatorKeyword);
    JUnitTestCase.assertNull(method.parameters);
    JUnitTestCase.assertNotNull(method.propertyKeyword);
    JUnitTestCase.assertEquals(returnType, method.returnType);
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
    JUnitTestCase.assertNotNull(method.body);
    JUnitTestCase.assertEquals(comment, method.documentationComment);
    JUnitTestCase.assertNull(method.externalKeyword);
    JUnitTestCase.assertEquals(staticKeyword, method.modifierKeyword);
    JUnitTestCase.assertNotNull(method.name);
    JUnitTestCase.assertNull(method.operatorKeyword);
    JUnitTestCase.assertNull(method.parameters);
    JUnitTestCase.assertNotNull(method.propertyKeyword);
    JUnitTestCase.assertEquals(returnType, method.returnType);
  }

  void test_parseIdentifierList_multiple() {
    List<SimpleIdentifier> list = ParserTestCase.parse4("parseIdentifierList", "a, b, c", []);
    EngineTestCase.assertSizeOfList(3, list);
  }

  void test_parseIdentifierList_single() {
    List<SimpleIdentifier> list = ParserTestCase.parse4("parseIdentifierList", "a", []);
    EngineTestCase.assertSizeOfList(1, list);
  }

  void test_parseIfStatement_else_block() {
    IfStatement statement = ParserTestCase.parse4("parseIfStatement", "if (x) {} else {}", []);
    JUnitTestCase.assertNotNull(statement.ifKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.thenStatement);
    JUnitTestCase.assertNotNull(statement.elseKeyword);
    JUnitTestCase.assertNotNull(statement.elseStatement);
  }

  void test_parseIfStatement_else_statement() {
    IfStatement statement = ParserTestCase.parse4("parseIfStatement", "if (x) f(x); else f(y);", []);
    JUnitTestCase.assertNotNull(statement.ifKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.thenStatement);
    JUnitTestCase.assertNotNull(statement.elseKeyword);
    JUnitTestCase.assertNotNull(statement.elseStatement);
  }

  void test_parseIfStatement_noElse_block() {
    IfStatement statement = ParserTestCase.parse4("parseIfStatement", "if (x) {}", []);
    JUnitTestCase.assertNotNull(statement.ifKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.thenStatement);
    JUnitTestCase.assertNull(statement.elseKeyword);
    JUnitTestCase.assertNull(statement.elseStatement);
  }

  void test_parseIfStatement_noElse_statement() {
    IfStatement statement = ParserTestCase.parse4("parseIfStatement", "if (x) f(x);", []);
    JUnitTestCase.assertNotNull(statement.ifKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.thenStatement);
    JUnitTestCase.assertNull(statement.elseKeyword);
    JUnitTestCase.assertNull(statement.elseStatement);
  }

  void test_parseImplementsClause_multiple() {
    ImplementsClause clause = ParserTestCase.parse4("parseImplementsClause", "implements A, B, C", []);
    EngineTestCase.assertSizeOfList(3, clause.interfaces);
    JUnitTestCase.assertNotNull(clause.keyword);
  }

  void test_parseImplementsClause_single() {
    ImplementsClause clause = ParserTestCase.parse4("parseImplementsClause", "implements A", []);
    EngineTestCase.assertSizeOfList(1, clause.interfaces);
    JUnitTestCase.assertNotNull(clause.keyword);
  }

  void test_parseImportDirective_deferred() {
    ImportDirective directive = ParserTestCase.parse("parseImportDirective", <Object> [emptyCommentAndMetadata()], "import 'lib/lib.dart' deferred as a;");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    JUnitTestCase.assertNotNull(directive.deferredToken);
    JUnitTestCase.assertNotNull(directive.asToken);
    JUnitTestCase.assertNotNull(directive.prefix);
    EngineTestCase.assertSizeOfList(0, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }

  void test_parseImportDirective_hide() {
    ImportDirective directive = ParserTestCase.parse("parseImportDirective", <Object> [emptyCommentAndMetadata()], "import 'lib/lib.dart' hide A, B;");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    JUnitTestCase.assertNull(directive.deferredToken);
    JUnitTestCase.assertNull(directive.asToken);
    JUnitTestCase.assertNull(directive.prefix);
    EngineTestCase.assertSizeOfList(1, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }

  void test_parseImportDirective_noCombinator() {
    ImportDirective directive = ParserTestCase.parse("parseImportDirective", <Object> [emptyCommentAndMetadata()], "import 'lib/lib.dart';");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    JUnitTestCase.assertNull(directive.deferredToken);
    JUnitTestCase.assertNull(directive.asToken);
    JUnitTestCase.assertNull(directive.prefix);
    EngineTestCase.assertSizeOfList(0, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }

  void test_parseImportDirective_prefix() {
    ImportDirective directive = ParserTestCase.parse("parseImportDirective", <Object> [emptyCommentAndMetadata()], "import 'lib/lib.dart' as a;");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    JUnitTestCase.assertNull(directive.deferredToken);
    JUnitTestCase.assertNotNull(directive.asToken);
    JUnitTestCase.assertNotNull(directive.prefix);
    EngineTestCase.assertSizeOfList(0, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }

  void test_parseImportDirective_prefix_hide_show() {
    ImportDirective directive = ParserTestCase.parse("parseImportDirective", <Object> [emptyCommentAndMetadata()], "import 'lib/lib.dart' as a hide A show B;");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    JUnitTestCase.assertNull(directive.deferredToken);
    JUnitTestCase.assertNotNull(directive.asToken);
    JUnitTestCase.assertNotNull(directive.prefix);
    EngineTestCase.assertSizeOfList(2, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }

  void test_parseImportDirective_prefix_show_hide() {
    ImportDirective directive = ParserTestCase.parse("parseImportDirective", <Object> [emptyCommentAndMetadata()], "import 'lib/lib.dart' as a show B hide A;");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    JUnitTestCase.assertNull(directive.deferredToken);
    JUnitTestCase.assertNotNull(directive.asToken);
    JUnitTestCase.assertNotNull(directive.prefix);
    EngineTestCase.assertSizeOfList(2, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }

  void test_parseImportDirective_show() {
    ImportDirective directive = ParserTestCase.parse("parseImportDirective", <Object> [emptyCommentAndMetadata()], "import 'lib/lib.dart' show A, B;");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    JUnitTestCase.assertNull(directive.deferredToken);
    JUnitTestCase.assertNull(directive.asToken);
    JUnitTestCase.assertNull(directive.prefix);
    EngineTestCase.assertSizeOfList(1, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
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
    JUnitTestCase.assertEquals(comment, declaration.documentationComment);
    VariableDeclarationList fields = declaration.fields;
    JUnitTestCase.assertNotNull(fields);
    JUnitTestCase.assertNull(fields.keyword);
    JUnitTestCase.assertEquals(type, fields.type);
    EngineTestCase.assertSizeOfList(3, fields.variables);
    JUnitTestCase.assertEquals(staticKeyword, declaration.staticKeyword);
    JUnitTestCase.assertNotNull(declaration.semicolon);
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
    JUnitTestCase.assertEquals(comment, declaration.documentationComment);
    VariableDeclarationList fields = declaration.fields;
    JUnitTestCase.assertNotNull(fields);
    JUnitTestCase.assertEquals(varKeyword, fields.keyword);
    JUnitTestCase.assertNull(fields.type);
    EngineTestCase.assertSizeOfList(3, fields.variables);
    JUnitTestCase.assertEquals(staticKeyword, declaration.staticKeyword);
    JUnitTestCase.assertNotNull(declaration.semicolon);
  }

  void test_parseInstanceCreationExpression_qualifiedType() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    InstanceCreationExpression expression = ParserTestCase.parse("parseInstanceCreationExpression", <Object> [token], "A.B()");
    JUnitTestCase.assertEquals(token, expression.keyword);
    ConstructorName name = expression.constructorName;
    JUnitTestCase.assertNotNull(name);
    JUnitTestCase.assertNotNull(name.type);
    JUnitTestCase.assertNull(name.period);
    JUnitTestCase.assertNull(name.name);
    JUnitTestCase.assertNotNull(expression.argumentList);
  }

  void test_parseInstanceCreationExpression_qualifiedType_named() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    InstanceCreationExpression expression = ParserTestCase.parse("parseInstanceCreationExpression", <Object> [token], "A.B.c()");
    JUnitTestCase.assertEquals(token, expression.keyword);
    ConstructorName name = expression.constructorName;
    JUnitTestCase.assertNotNull(name);
    JUnitTestCase.assertNotNull(name.type);
    JUnitTestCase.assertNotNull(name.period);
    JUnitTestCase.assertNotNull(name.name);
    JUnitTestCase.assertNotNull(expression.argumentList);
  }

  void test_parseInstanceCreationExpression_type() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    InstanceCreationExpression expression = ParserTestCase.parse("parseInstanceCreationExpression", <Object> [token], "A()");
    JUnitTestCase.assertEquals(token, expression.keyword);
    ConstructorName name = expression.constructorName;
    JUnitTestCase.assertNotNull(name);
    JUnitTestCase.assertNotNull(name.type);
    JUnitTestCase.assertNull(name.period);
    JUnitTestCase.assertNull(name.name);
    JUnitTestCase.assertNotNull(expression.argumentList);
  }

  void test_parseInstanceCreationExpression_type_named() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.NEW);
    InstanceCreationExpression expression = ParserTestCase.parse("parseInstanceCreationExpression", <Object> [token], "A<B>.c()");
    JUnitTestCase.assertEquals(token, expression.keyword);
    ConstructorName name = expression.constructorName;
    JUnitTestCase.assertNotNull(name);
    JUnitTestCase.assertNotNull(name.type);
    JUnitTestCase.assertNotNull(name.period);
    JUnitTestCase.assertNotNull(name.name);
    JUnitTestCase.assertNotNull(expression.argumentList);
  }

  void test_parseLibraryDirective() {
    LibraryDirective directive = ParserTestCase.parse("parseLibraryDirective", <Object> [emptyCommentAndMetadata()], "library l;");
    JUnitTestCase.assertNotNull(directive.libraryToken);
    JUnitTestCase.assertNotNull(directive.name);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }

  void test_parseLibraryIdentifier_multiple() {
    String name = "a.b.c";
    LibraryIdentifier identifier = ParserTestCase.parse4("parseLibraryIdentifier", name, []);
    JUnitTestCase.assertEquals(name, identifier.name);
  }

  void test_parseLibraryIdentifier_single() {
    String name = "a";
    LibraryIdentifier identifier = ParserTestCase.parse4("parseLibraryIdentifier", name, []);
    JUnitTestCase.assertEquals(name, identifier.name);
  }

  void test_parseListLiteral_empty_oneToken() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.CONST);
    TypeArgumentList typeArguments = null;
    ListLiteral literal = ParserTestCase.parse("parseListLiteral", <Object> [token, typeArguments], "[]");
    JUnitTestCase.assertEquals(token, literal.constKeyword);
    JUnitTestCase.assertEquals(typeArguments, literal.typeArguments);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSizeOfList(0, literal.elements);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }

  void test_parseListLiteral_empty_twoTokens() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.CONST);
    TypeArgumentList typeArguments = null;
    ListLiteral literal = ParserTestCase.parse("parseListLiteral", <Object> [token, typeArguments], "[ ]");
    JUnitTestCase.assertEquals(token, literal.constKeyword);
    JUnitTestCase.assertEquals(typeArguments, literal.typeArguments);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSizeOfList(0, literal.elements);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }

  void test_parseListLiteral_multiple() {
    ListLiteral literal = ParserTestCase.parse("parseListLiteral", <Object> [null, null], "[1, 2, 3]");
    JUnitTestCase.assertNull(literal.constKeyword);
    JUnitTestCase.assertNull(literal.typeArguments);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSizeOfList(3, literal.elements);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }

  void test_parseListLiteral_single() {
    ListLiteral literal = ParserTestCase.parse("parseListLiteral", <Object> [null, null], "[1]");
    JUnitTestCase.assertNull(literal.constKeyword);
    JUnitTestCase.assertNull(literal.typeArguments);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSizeOfList(1, literal.elements);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }

  void test_parseListOrMapLiteral_list_noType() {
    ListLiteral literal = ParserTestCase.parse("parseListOrMapLiteral", <Object> [null], "[1]");
    JUnitTestCase.assertNull(literal.constKeyword);
    JUnitTestCase.assertNull(literal.typeArguments);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSizeOfList(1, literal.elements);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }

  void test_parseListOrMapLiteral_list_type() {
    ListLiteral literal = ParserTestCase.parse("parseListOrMapLiteral", <Object> [null], "<int> [1]");
    JUnitTestCase.assertNull(literal.constKeyword);
    JUnitTestCase.assertNotNull(literal.typeArguments);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSizeOfList(1, literal.elements);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }

  void test_parseListOrMapLiteral_map_noType() {
    MapLiteral literal = ParserTestCase.parse("parseListOrMapLiteral", <Object> [null], "{'1' : 1}");
    JUnitTestCase.assertNull(literal.constKeyword);
    JUnitTestCase.assertNull(literal.typeArguments);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSizeOfList(1, literal.entries);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }

  void test_parseListOrMapLiteral_map_type() {
    MapLiteral literal = ParserTestCase.parse("parseListOrMapLiteral", <Object> [null], "<String, int> {'1' : 1}");
    JUnitTestCase.assertNull(literal.constKeyword);
    JUnitTestCase.assertNotNull(literal.typeArguments);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSizeOfList(1, literal.entries);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }

  void test_parseLogicalAndExpression() {
    BinaryExpression expression = ParserTestCase.parse4("parseLogicalAndExpression", "x && y", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.AMPERSAND_AMPERSAND, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }

  void test_parseLogicalOrExpression() {
    BinaryExpression expression = ParserTestCase.parse4("parseLogicalOrExpression", "x || y", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.BAR_BAR, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }

  void test_parseMapLiteral_empty() {
    Token token = TokenFactory.tokenFromKeyword(Keyword.CONST);
    TypeArgumentList typeArguments = AstFactory.typeArgumentList([
        AstFactory.typeName4("String", []),
        AstFactory.typeName4("int", [])]);
    MapLiteral literal = ParserTestCase.parse("parseMapLiteral", <Object> [token, typeArguments], "{}");
    JUnitTestCase.assertEquals(token, literal.constKeyword);
    JUnitTestCase.assertEquals(typeArguments, literal.typeArguments);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSizeOfList(0, literal.entries);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }

  void test_parseMapLiteral_multiple() {
    MapLiteral literal = ParserTestCase.parse("parseMapLiteral", <Object> [null, null], "{'a' : b, 'x' : y}");
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSizeOfList(2, literal.entries);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }

  void test_parseMapLiteral_single() {
    MapLiteral literal = ParserTestCase.parse("parseMapLiteral", <Object> [null, null], "{'x' : y}");
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSizeOfList(1, literal.entries);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }

  void test_parseMapLiteralEntry_complex() {
    MapLiteralEntry entry = ParserTestCase.parse4("parseMapLiteralEntry", "2 + 2 : y", []);
    JUnitTestCase.assertNotNull(entry.key);
    JUnitTestCase.assertNotNull(entry.separator);
    JUnitTestCase.assertNotNull(entry.value);
  }

  void test_parseMapLiteralEntry_int() {
    MapLiteralEntry entry = ParserTestCase.parse4("parseMapLiteralEntry", "0 : y", []);
    JUnitTestCase.assertNotNull(entry.key);
    JUnitTestCase.assertNotNull(entry.separator);
    JUnitTestCase.assertNotNull(entry.value);
  }

  void test_parseMapLiteralEntry_string() {
    MapLiteralEntry entry = ParserTestCase.parse4("parseMapLiteralEntry", "'x' : y", []);
    JUnitTestCase.assertNotNull(entry.key);
    JUnitTestCase.assertNotNull(entry.separator);
    JUnitTestCase.assertNotNull(entry.value);
  }

  void test_parseModifiers_abstract() {
    Modifiers modifiers = ParserTestCase.parse4("parseModifiers", "abstract A", []);
    JUnitTestCase.assertNotNull(modifiers.abstractKeyword);
  }

  void test_parseModifiers_const() {
    Modifiers modifiers = ParserTestCase.parse4("parseModifiers", "const A", []);
    JUnitTestCase.assertNotNull(modifiers.constKeyword);
  }

  void test_parseModifiers_external() {
    Modifiers modifiers = ParserTestCase.parse4("parseModifiers", "external A", []);
    JUnitTestCase.assertNotNull(modifiers.externalKeyword);
  }

  void test_parseModifiers_factory() {
    Modifiers modifiers = ParserTestCase.parse4("parseModifiers", "factory A", []);
    JUnitTestCase.assertNotNull(modifiers.factoryKeyword);
  }

  void test_parseModifiers_final() {
    Modifiers modifiers = ParserTestCase.parse4("parseModifiers", "final A", []);
    JUnitTestCase.assertNotNull(modifiers.finalKeyword);
  }

  void test_parseModifiers_static() {
    Modifiers modifiers = ParserTestCase.parse4("parseModifiers", "static A", []);
    JUnitTestCase.assertNotNull(modifiers.staticKeyword);
  }

  void test_parseModifiers_var() {
    Modifiers modifiers = ParserTestCase.parse4("parseModifiers", "var A", []);
    JUnitTestCase.assertNotNull(modifiers.varKeyword);
  }

  void test_parseMultiplicativeExpression_normal() {
    BinaryExpression expression = ParserTestCase.parse4("parseMultiplicativeExpression", "x * y", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.STAR, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }

  void test_parseMultiplicativeExpression_super() {
    BinaryExpression expression = ParserTestCase.parse4("parseMultiplicativeExpression", "super * y", []);
    EngineTestCase.assertInstanceOf((obj) => obj is SuperExpression, SuperExpression, expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.STAR, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }

  void test_parseNewExpression() {
    InstanceCreationExpression expression = ParserTestCase.parse4("parseNewExpression", "new A()", []);
    JUnitTestCase.assertNotNull(expression.keyword);
    ConstructorName name = expression.constructorName;
    JUnitTestCase.assertNotNull(name);
    JUnitTestCase.assertNotNull(name.type);
    JUnitTestCase.assertNull(name.period);
    JUnitTestCase.assertNull(name.name);
    JUnitTestCase.assertNotNull(expression.argumentList);
  }

  void test_parseNonLabeledStatement_const_list_empty() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "const [];", []);
    JUnitTestCase.assertNotNull(statement.expression);
  }

  void test_parseNonLabeledStatement_const_list_nonEmpty() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "const [1, 2];", []);
    JUnitTestCase.assertNotNull(statement.expression);
  }

  void test_parseNonLabeledStatement_const_map_empty() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "const {};", []);
    JUnitTestCase.assertNotNull(statement.expression);
  }

  void test_parseNonLabeledStatement_const_map_nonEmpty() {
    // TODO(brianwilkerson) Implement more tests for this method.
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "const {'a' : 1};", []);
    JUnitTestCase.assertNotNull(statement.expression);
  }

  void test_parseNonLabeledStatement_const_object() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "const A();", []);
    JUnitTestCase.assertNotNull(statement.expression);
  }

  void test_parseNonLabeledStatement_const_object_named_typeParameters() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "const A<B>.c();", []);
    JUnitTestCase.assertNotNull(statement.expression);
  }

  void test_parseNonLabeledStatement_constructorInvocation() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "new C().m();", []);
    JUnitTestCase.assertNotNull(statement.expression);
  }

  void test_parseNonLabeledStatement_false() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "false;", []);
    JUnitTestCase.assertNotNull(statement.expression);
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
    JUnitTestCase.assertNotNull(statement.expression);
  }

  void test_parseNonLabeledStatement_invokeFunctionExpression() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "(a) {return a + a;} (3);", []);
    EngineTestCase.assertInstanceOf((obj) => obj is FunctionExpressionInvocation, FunctionExpressionInvocation, statement.expression);
    FunctionExpressionInvocation invocation = statement.expression as FunctionExpressionInvocation;
    EngineTestCase.assertInstanceOf((obj) => obj is FunctionExpression, FunctionExpression, invocation.function);
    FunctionExpression expression = invocation.function as FunctionExpression;
    JUnitTestCase.assertNotNull(expression.parameters);
    JUnitTestCase.assertNotNull(expression.body);
    ArgumentList list = invocation.argumentList;
    JUnitTestCase.assertNotNull(list);
    EngineTestCase.assertSizeOfList(1, list.arguments);
  }

  void test_parseNonLabeledStatement_null() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "null;", []);
    JUnitTestCase.assertNotNull(statement.expression);
  }

  void test_parseNonLabeledStatement_startingWithBuiltInIdentifier() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "library.getName();", []);
    JUnitTestCase.assertNotNull(statement.expression);
  }

  void test_parseNonLabeledStatement_true() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "true;", []);
    JUnitTestCase.assertNotNull(statement.expression);
  }

  void test_parseNonLabeledStatement_typeCast() {
    ExpressionStatement statement = ParserTestCase.parse4("parseNonLabeledStatement", "double.NAN as num;", []);
    JUnitTestCase.assertNotNull(statement.expression);
  }

  void test_parseNormalFormalParameter_field_const_noType() {
    FieldFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "const this.a)", []);
    JUnitTestCase.assertNotNull(parameter.keyword);
    JUnitTestCase.assertNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
    JUnitTestCase.assertNull(parameter.parameters);
  }

  void test_parseNormalFormalParameter_field_const_type() {
    FieldFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "const A this.a)", []);
    JUnitTestCase.assertNotNull(parameter.keyword);
    JUnitTestCase.assertNotNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
    JUnitTestCase.assertNull(parameter.parameters);
  }

  void test_parseNormalFormalParameter_field_final_noType() {
    FieldFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "final this.a)", []);
    JUnitTestCase.assertNotNull(parameter.keyword);
    JUnitTestCase.assertNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
    JUnitTestCase.assertNull(parameter.parameters);
  }

  void test_parseNormalFormalParameter_field_final_type() {
    FieldFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "final A this.a)", []);
    JUnitTestCase.assertNotNull(parameter.keyword);
    JUnitTestCase.assertNotNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
    JUnitTestCase.assertNull(parameter.parameters);
  }

  void test_parseNormalFormalParameter_field_function_nested() {
    FieldFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "this.a(B b))", []);
    JUnitTestCase.assertNull(parameter.keyword);
    JUnitTestCase.assertNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
    FormalParameterList parameterList = parameter.parameters;
    JUnitTestCase.assertNotNull(parameterList);
    EngineTestCase.assertSizeOfList(1, parameterList.parameters);
  }

  void test_parseNormalFormalParameter_field_function_noNested() {
    FieldFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "this.a())", []);
    JUnitTestCase.assertNull(parameter.keyword);
    JUnitTestCase.assertNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
    FormalParameterList parameterList = parameter.parameters;
    JUnitTestCase.assertNotNull(parameterList);
    EngineTestCase.assertSizeOfList(0, parameterList.parameters);
  }

  void test_parseNormalFormalParameter_field_noType() {
    FieldFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "this.a)", []);
    JUnitTestCase.assertNull(parameter.keyword);
    JUnitTestCase.assertNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
    JUnitTestCase.assertNull(parameter.parameters);
  }

  void test_parseNormalFormalParameter_field_type() {
    FieldFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "A this.a)", []);
    JUnitTestCase.assertNull(parameter.keyword);
    JUnitTestCase.assertNotNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
    JUnitTestCase.assertNull(parameter.parameters);
  }

  void test_parseNormalFormalParameter_field_var() {
    FieldFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "var this.a)", []);
    JUnitTestCase.assertNotNull(parameter.keyword);
    JUnitTestCase.assertNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
    JUnitTestCase.assertNull(parameter.parameters);
  }

  void test_parseNormalFormalParameter_function_noType() {
    FunctionTypedFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "a())", []);
    JUnitTestCase.assertNull(parameter.returnType);
    JUnitTestCase.assertNotNull(parameter.identifier);
    JUnitTestCase.assertNotNull(parameter.parameters);
  }

  void test_parseNormalFormalParameter_function_type() {
    FunctionTypedFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "A a())", []);
    JUnitTestCase.assertNotNull(parameter.returnType);
    JUnitTestCase.assertNotNull(parameter.identifier);
    JUnitTestCase.assertNotNull(parameter.parameters);
  }

  void test_parseNormalFormalParameter_function_void() {
    FunctionTypedFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "void a())", []);
    JUnitTestCase.assertNotNull(parameter.returnType);
    JUnitTestCase.assertNotNull(parameter.identifier);
    JUnitTestCase.assertNotNull(parameter.parameters);
  }

  void test_parseNormalFormalParameter_simple_const_noType() {
    SimpleFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "const a)", []);
    JUnitTestCase.assertNotNull(parameter.keyword);
    JUnitTestCase.assertNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
  }

  void test_parseNormalFormalParameter_simple_const_type() {
    SimpleFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "const A a)", []);
    JUnitTestCase.assertNotNull(parameter.keyword);
    JUnitTestCase.assertNotNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
  }

  void test_parseNormalFormalParameter_simple_final_noType() {
    SimpleFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "final a)", []);
    JUnitTestCase.assertNotNull(parameter.keyword);
    JUnitTestCase.assertNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
  }

  void test_parseNormalFormalParameter_simple_final_type() {
    SimpleFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "final A a)", []);
    JUnitTestCase.assertNotNull(parameter.keyword);
    JUnitTestCase.assertNotNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
  }

  void test_parseNormalFormalParameter_simple_noType() {
    SimpleFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "a)", []);
    JUnitTestCase.assertNull(parameter.keyword);
    JUnitTestCase.assertNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
  }

  void test_parseNormalFormalParameter_simple_type() {
    SimpleFormalParameter parameter = ParserTestCase.parse4("parseNormalFormalParameter", "A a)", []);
    JUnitTestCase.assertNull(parameter.keyword);
    JUnitTestCase.assertNotNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
  }

  void test_parseOperator() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    TypeName returnType = new TypeName(new SimpleIdentifier(null), null);
    MethodDeclaration method = ParserTestCase.parse("parseOperator", <Object> [commentAndMetadata(comment, []), null, returnType], "operator +(A a);");
    JUnitTestCase.assertNotNull(method.body);
    JUnitTestCase.assertEquals(comment, method.documentationComment);
    JUnitTestCase.assertNull(method.externalKeyword);
    JUnitTestCase.assertNull(method.modifierKeyword);
    JUnitTestCase.assertNotNull(method.name);
    JUnitTestCase.assertNotNull(method.operatorKeyword);
    JUnitTestCase.assertNotNull(method.parameters);
    JUnitTestCase.assertNull(method.propertyKeyword);
    JUnitTestCase.assertEquals(returnType, method.returnType);
  }

  void test_parseOptionalReturnType() {
    // TODO(brianwilkerson) Implement tests for this method.
  }

  void test_parsePartDirective_part() {
    PartDirective directive = ParserTestCase.parse("parsePartDirective", <Object> [emptyCommentAndMetadata()], "part 'lib/lib.dart';");
    JUnitTestCase.assertNotNull(directive.partToken);
    JUnitTestCase.assertNotNull(directive.uri);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }

  void test_parsePartDirective_partOf() {
    PartOfDirective directive = ParserTestCase.parse("parsePartDirective", <Object> [emptyCommentAndMetadata()], "part of l;");
    JUnitTestCase.assertNotNull(directive.partToken);
    JUnitTestCase.assertNotNull(directive.ofToken);
    JUnitTestCase.assertNotNull(directive.libraryName);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }

  void test_parsePostfixExpression_decrement() {
    PostfixExpression expression = ParserTestCase.parse4("parsePostfixExpression", "i--", []);
    JUnitTestCase.assertNotNull(expression.operand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.MINUS_MINUS, expression.operator.type);
  }

  void test_parsePostfixExpression_increment() {
    PostfixExpression expression = ParserTestCase.parse4("parsePostfixExpression", "i++", []);
    JUnitTestCase.assertNotNull(expression.operand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.PLUS_PLUS, expression.operator.type);
  }

  void test_parsePostfixExpression_none_indexExpression() {
    IndexExpression expression = ParserTestCase.parse4("parsePostfixExpression", "a[0]", []);
    JUnitTestCase.assertNotNull(expression.target);
    JUnitTestCase.assertNotNull(expression.index);
  }

  void test_parsePostfixExpression_none_methodInvocation() {
    MethodInvocation expression = ParserTestCase.parse4("parsePostfixExpression", "a.m()", []);
    JUnitTestCase.assertNotNull(expression.target);
    JUnitTestCase.assertNotNull(expression.methodName);
    JUnitTestCase.assertNotNull(expression.argumentList);
  }

  void test_parsePostfixExpression_none_propertyAccess() {
    PrefixedIdentifier expression = ParserTestCase.parse4("parsePostfixExpression", "a.b", []);
    JUnitTestCase.assertNotNull(expression.prefix);
    JUnitTestCase.assertNotNull(expression.identifier);
  }

  void test_parsePrefixedIdentifier_noPrefix() {
    String lexeme = "bar";
    SimpleIdentifier identifier = ParserTestCase.parse4("parsePrefixedIdentifier", lexeme, []);
    JUnitTestCase.assertNotNull(identifier.token);
    JUnitTestCase.assertEquals(lexeme, identifier.name);
  }

  void test_parsePrefixedIdentifier_prefix() {
    String lexeme = "foo.bar";
    PrefixedIdentifier identifier = ParserTestCase.parse4("parsePrefixedIdentifier", lexeme, []);
    JUnitTestCase.assertEquals("foo", identifier.prefix.name);
    JUnitTestCase.assertNotNull(identifier.period);
    JUnitTestCase.assertEquals("bar", identifier.identifier.name);
  }

  void test_parsePrimaryExpression_const() {
    InstanceCreationExpression expression = ParserTestCase.parse4("parsePrimaryExpression", "const A()", []);
    JUnitTestCase.assertNotNull(expression);
  }

  void test_parsePrimaryExpression_double() {
    String doubleLiteral = "3.2e4";
    DoubleLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", doubleLiteral, []);
    JUnitTestCase.assertNotNull(literal.literal);
    JUnitTestCase.assertEquals(double.parse(doubleLiteral), literal.value);
  }

  void test_parsePrimaryExpression_false() {
    BooleanLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", "false", []);
    JUnitTestCase.assertNotNull(literal.literal);
    JUnitTestCase.assertFalse(literal.value);
  }

  void test_parsePrimaryExpression_function_arguments() {
    FunctionExpression expression = ParserTestCase.parse4("parsePrimaryExpression", "(int i) => i + 1", []);
    JUnitTestCase.assertNotNull(expression.parameters);
    JUnitTestCase.assertNotNull(expression.body);
  }

  void test_parsePrimaryExpression_function_noArguments() {
    FunctionExpression expression = ParserTestCase.parse4("parsePrimaryExpression", "() => 42", []);
    JUnitTestCase.assertNotNull(expression.parameters);
    JUnitTestCase.assertNotNull(expression.body);
  }

  void test_parsePrimaryExpression_hex() {
    String hexLiteral = "3F";
    IntegerLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", "0x${hexLiteral}", []);
    JUnitTestCase.assertNotNull(literal.literal);
    JUnitTestCase.assertEquals(int.parse(hexLiteral, radix: 16), literal.value);
  }

  void test_parsePrimaryExpression_identifier() {
    SimpleIdentifier identifier = ParserTestCase.parse4("parsePrimaryExpression", "a", []);
    JUnitTestCase.assertNotNull(identifier);
  }

  void test_parsePrimaryExpression_int() {
    String intLiteral = "472";
    IntegerLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", intLiteral, []);
    JUnitTestCase.assertNotNull(literal.literal);
    JUnitTestCase.assertEquals(int.parse(intLiteral), literal.value);
  }

  void test_parsePrimaryExpression_listLiteral() {
    ListLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", "[ ]", []);
    JUnitTestCase.assertNotNull(literal);
  }

  void test_parsePrimaryExpression_listLiteral_index() {
    ListLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", "[]", []);
    JUnitTestCase.assertNotNull(literal);
  }

  void test_parsePrimaryExpression_listLiteral_typed() {
    ListLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", "<A>[ ]", []);
    JUnitTestCase.assertNotNull(literal.typeArguments);
    EngineTestCase.assertSizeOfList(1, literal.typeArguments.arguments);
  }

  void test_parsePrimaryExpression_mapLiteral() {
    MapLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", "{}", []);
    JUnitTestCase.assertNotNull(literal);
  }

  void test_parsePrimaryExpression_mapLiteral_typed() {
    MapLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", "<A, B>{}", []);
    JUnitTestCase.assertNotNull(literal.typeArguments);
    EngineTestCase.assertSizeOfList(2, literal.typeArguments.arguments);
  }

  void test_parsePrimaryExpression_new() {
    InstanceCreationExpression expression = ParserTestCase.parse4("parsePrimaryExpression", "new A()", []);
    JUnitTestCase.assertNotNull(expression);
  }

  void test_parsePrimaryExpression_null() {
    NullLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", "null", []);
    JUnitTestCase.assertNotNull(literal.literal);
  }

  void test_parsePrimaryExpression_parenthesized() {
    ParenthesizedExpression expression = ParserTestCase.parse4("parsePrimaryExpression", "(x)", []);
    JUnitTestCase.assertNotNull(expression);
  }

  void test_parsePrimaryExpression_string() {
    SimpleStringLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", "\"string\"", []);
    JUnitTestCase.assertFalse(literal.isMultiline);
    JUnitTestCase.assertFalse(literal.isRaw);
    JUnitTestCase.assertEquals("string", literal.value);
  }

  void test_parsePrimaryExpression_string_multiline() {
    SimpleStringLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", "'''string'''", []);
    JUnitTestCase.assertTrue(literal.isMultiline);
    JUnitTestCase.assertFalse(literal.isRaw);
    JUnitTestCase.assertEquals("string", literal.value);
  }

  void test_parsePrimaryExpression_string_raw() {
    SimpleStringLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", "r'string'", []);
    JUnitTestCase.assertFalse(literal.isMultiline);
    JUnitTestCase.assertTrue(literal.isRaw);
    JUnitTestCase.assertEquals("string", literal.value);
  }

  void test_parsePrimaryExpression_super() {
    PropertyAccess propertyAccess = ParserTestCase.parse4("parsePrimaryExpression", "super.x", []);
    JUnitTestCase.assertTrue(propertyAccess.target is SuperExpression);
    JUnitTestCase.assertNotNull(propertyAccess.operator);
    JUnitTestCase.assertEquals(TokenType.PERIOD, propertyAccess.operator.type);
    JUnitTestCase.assertNotNull(propertyAccess.propertyName);
  }

  void test_parsePrimaryExpression_this() {
    ThisExpression expression = ParserTestCase.parse4("parsePrimaryExpression", "this", []);
    JUnitTestCase.assertNotNull(expression.keyword);
  }

  void test_parsePrimaryExpression_true() {
    BooleanLiteral literal = ParserTestCase.parse4("parsePrimaryExpression", "true", []);
    JUnitTestCase.assertNotNull(literal.literal);
    JUnitTestCase.assertTrue(literal.value);
  }

  void test_Parser() {
    JUnitTestCase.assertNotNull(new Parser(null, null));
  }

  void test_parseRedirectingConstructorInvocation_named() {
    RedirectingConstructorInvocation invocation = ParserTestCase.parse4("parseRedirectingConstructorInvocation", "this.a()", []);
    JUnitTestCase.assertNotNull(invocation.argumentList);
    JUnitTestCase.assertNotNull(invocation.constructorName);
    JUnitTestCase.assertNotNull(invocation.keyword);
    JUnitTestCase.assertNotNull(invocation.period);
  }

  void test_parseRedirectingConstructorInvocation_unnamed() {
    RedirectingConstructorInvocation invocation = ParserTestCase.parse4("parseRedirectingConstructorInvocation", "this()", []);
    JUnitTestCase.assertNotNull(invocation.argumentList);
    JUnitTestCase.assertNull(invocation.constructorName);
    JUnitTestCase.assertNotNull(invocation.keyword);
    JUnitTestCase.assertNull(invocation.period);
  }

  void test_parseRelationalExpression_as() {
    AsExpression expression = ParserTestCase.parse4("parseRelationalExpression", "x as Y", []);
    JUnitTestCase.assertNotNull(expression.expression);
    JUnitTestCase.assertNotNull(expression.asOperator);
    JUnitTestCase.assertNotNull(expression.type);
  }

  void test_parseRelationalExpression_is() {
    IsExpression expression = ParserTestCase.parse4("parseRelationalExpression", "x is y", []);
    JUnitTestCase.assertNotNull(expression.expression);
    JUnitTestCase.assertNotNull(expression.isOperator);
    JUnitTestCase.assertNull(expression.notOperator);
    JUnitTestCase.assertNotNull(expression.type);
  }

  void test_parseRelationalExpression_isNot() {
    IsExpression expression = ParserTestCase.parse4("parseRelationalExpression", "x is! y", []);
    JUnitTestCase.assertNotNull(expression.expression);
    JUnitTestCase.assertNotNull(expression.isOperator);
    JUnitTestCase.assertNotNull(expression.notOperator);
    JUnitTestCase.assertNotNull(expression.type);
  }

  void test_parseRelationalExpression_normal() {
    BinaryExpression expression = ParserTestCase.parse4("parseRelationalExpression", "x < y", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.LT, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }

  void test_parseRelationalExpression_super() {
    BinaryExpression expression = ParserTestCase.parse4("parseRelationalExpression", "super < y", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.LT, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }

  void test_parseRethrowExpression() {
    RethrowExpression expression = ParserTestCase.parse4("parseRethrowExpression", "rethrow;", []);
    JUnitTestCase.assertNotNull(expression.keyword);
  }

  void test_parseReturnStatement_noValue() {
    ReturnStatement statement = ParserTestCase.parse4("parseReturnStatement", "return;", []);
    JUnitTestCase.assertNotNull(statement.keyword);
    JUnitTestCase.assertNull(statement.expression);
    JUnitTestCase.assertNotNull(statement.semicolon);
  }

  void test_parseReturnStatement_value() {
    ReturnStatement statement = ParserTestCase.parse4("parseReturnStatement", "return x;", []);
    JUnitTestCase.assertNotNull(statement.keyword);
    JUnitTestCase.assertNotNull(statement.expression);
    JUnitTestCase.assertNotNull(statement.semicolon);
  }

  void test_parseReturnType_nonVoid() {
    TypeName typeName = ParserTestCase.parse4("parseReturnType", "A<B>", []);
    JUnitTestCase.assertNotNull(typeName.name);
    JUnitTestCase.assertNotNull(typeName.typeArguments);
  }

  void test_parseReturnType_void() {
    TypeName typeName = ParserTestCase.parse4("parseReturnType", "void", []);
    JUnitTestCase.assertNotNull(typeName.name);
    JUnitTestCase.assertNull(typeName.typeArguments);
  }

  void test_parseSetter_nonStatic() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    TypeName returnType = new TypeName(new SimpleIdentifier(null), null);
    MethodDeclaration method = ParserTestCase.parse("parseSetter", <Object> [commentAndMetadata(comment, []), null, null, returnType], "set a(var x);");
    JUnitTestCase.assertNotNull(method.body);
    JUnitTestCase.assertEquals(comment, method.documentationComment);
    JUnitTestCase.assertNull(method.externalKeyword);
    JUnitTestCase.assertNull(method.modifierKeyword);
    JUnitTestCase.assertNotNull(method.name);
    JUnitTestCase.assertNull(method.operatorKeyword);
    JUnitTestCase.assertNotNull(method.parameters);
    JUnitTestCase.assertNotNull(method.propertyKeyword);
    JUnitTestCase.assertEquals(returnType, method.returnType);
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
    JUnitTestCase.assertNotNull(method.body);
    JUnitTestCase.assertEquals(comment, method.documentationComment);
    JUnitTestCase.assertNull(method.externalKeyword);
    JUnitTestCase.assertEquals(staticKeyword, method.modifierKeyword);
    JUnitTestCase.assertNotNull(method.name);
    JUnitTestCase.assertNull(method.operatorKeyword);
    JUnitTestCase.assertNotNull(method.parameters);
    JUnitTestCase.assertNotNull(method.propertyKeyword);
    JUnitTestCase.assertEquals(returnType, method.returnType);
  }

  void test_parseShiftExpression_normal() {
    BinaryExpression expression = ParserTestCase.parse4("parseShiftExpression", "x << y", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.LT_LT, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }

  void test_parseShiftExpression_super() {
    BinaryExpression expression = ParserTestCase.parse4("parseShiftExpression", "super << y", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.LT_LT, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }

  void test_parseSimpleIdentifier_builtInIdentifier() {
    String lexeme = "as";
    SimpleIdentifier identifier = ParserTestCase.parse4("parseSimpleIdentifier", lexeme, []);
    JUnitTestCase.assertNotNull(identifier.token);
    JUnitTestCase.assertEquals(lexeme, identifier.name);
  }

  void test_parseSimpleIdentifier_normalIdentifier() {
    String lexeme = "foo";
    SimpleIdentifier identifier = ParserTestCase.parse4("parseSimpleIdentifier", lexeme, []);
    JUnitTestCase.assertNotNull(identifier.token);
    JUnitTestCase.assertEquals(lexeme, identifier.name);
  }

  void test_parseSimpleIdentifier1_normalIdentifier() {
    // TODO(brianwilkerson) Implement tests for this method.
  }

  void test_parseStatement_functionDeclaration() {
    // TODO(brianwilkerson) Implement more tests for this method.
    FunctionDeclarationStatement statement = ParserTestCase.parse4("parseStatement", "int f(a, b) {};", []);
    JUnitTestCase.assertNotNull(statement.functionDeclaration);
  }

  void test_parseStatement_mulipleLabels() {
    LabeledStatement statement = ParserTestCase.parse4("parseStatement", "l: m: return x;", []);
    EngineTestCase.assertSizeOfList(2, statement.labels);
    JUnitTestCase.assertNotNull(statement.statement);
  }

  void test_parseStatement_noLabels() {
    ParserTestCase.parse4("parseStatement", "return x;", []);
  }

  void test_parseStatement_singleLabel() {
    LabeledStatement statement = ParserTestCase.parse4("parseStatement", "l: return x;", []);
    EngineTestCase.assertSizeOfList(1, statement.labels);
    JUnitTestCase.assertNotNull(statement.statement);
  }

  void test_parseStatements_multiple() {
    List<Statement> statements = ParserTestCase.parseStatements("return; return;", 2, []);
    EngineTestCase.assertSizeOfList(2, statements);
  }

  void test_parseStatements_single() {
    List<Statement> statements = ParserTestCase.parseStatements("return;", 1, []);
    EngineTestCase.assertSizeOfList(1, statements);
  }

  void test_parseStringLiteral_adjacent() {
    AdjacentStrings literal = ParserTestCase.parse4("parseStringLiteral", "'a' 'b'", []);
    NodeList<StringLiteral> strings = literal.strings;
    EngineTestCase.assertSizeOfList(2, strings);
    StringLiteral firstString = strings[0];
    StringLiteral secondString = strings[1];
    JUnitTestCase.assertEquals("a", (firstString as SimpleStringLiteral).value);
    JUnitTestCase.assertEquals("b", (secondString as SimpleStringLiteral).value);
  }

  void test_parseStringLiteral_interpolated() {
    StringInterpolation literal = ParserTestCase.parse4("parseStringLiteral", "'a \${b} c \$this d'", []);
    NodeList<InterpolationElement> elements = literal.elements;
    EngineTestCase.assertSizeOfList(5, elements);
    JUnitTestCase.assertTrue(elements[0] is InterpolationString);
    JUnitTestCase.assertTrue(elements[1] is InterpolationExpression);
    JUnitTestCase.assertTrue(elements[2] is InterpolationString);
    JUnitTestCase.assertTrue(elements[3] is InterpolationExpression);
    JUnitTestCase.assertTrue(elements[4] is InterpolationString);
  }

  void test_parseStringLiteral_single() {
    SimpleStringLiteral literal = ParserTestCase.parse4("parseStringLiteral", "'a'", []);
    JUnitTestCase.assertNotNull(literal.literal);
    JUnitTestCase.assertEquals("a", literal.value);
  }

  void test_parseSuperConstructorInvocation_named() {
    SuperConstructorInvocation invocation = ParserTestCase.parse4("parseSuperConstructorInvocation", "super.a()", []);
    JUnitTestCase.assertNotNull(invocation.argumentList);
    JUnitTestCase.assertNotNull(invocation.constructorName);
    JUnitTestCase.assertNotNull(invocation.keyword);
    JUnitTestCase.assertNotNull(invocation.period);
  }

  void test_parseSuperConstructorInvocation_unnamed() {
    SuperConstructorInvocation invocation = ParserTestCase.parse4("parseSuperConstructorInvocation", "super()", []);
    JUnitTestCase.assertNotNull(invocation.argumentList);
    JUnitTestCase.assertNull(invocation.constructorName);
    JUnitTestCase.assertNotNull(invocation.keyword);
    JUnitTestCase.assertNull(invocation.period);
  }

  void test_parseSwitchStatement_case() {
    SwitchStatement statement = ParserTestCase.parse4("parseSwitchStatement", "switch (a) {case 1: return 'I';}", []);
    JUnitTestCase.assertNotNull(statement.keyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.expression);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.leftBracket);
    EngineTestCase.assertSizeOfList(1, statement.members);
    JUnitTestCase.assertNotNull(statement.rightBracket);
  }

  void test_parseSwitchStatement_empty() {
    SwitchStatement statement = ParserTestCase.parse4("parseSwitchStatement", "switch (a) {}", []);
    JUnitTestCase.assertNotNull(statement.keyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.expression);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.leftBracket);
    EngineTestCase.assertSizeOfList(0, statement.members);
    JUnitTestCase.assertNotNull(statement.rightBracket);
  }

  void test_parseSwitchStatement_labeledCase() {
    SwitchStatement statement = ParserTestCase.parse4("parseSwitchStatement", "switch (a) {l1: l2: l3: case(1):}", []);
    JUnitTestCase.assertNotNull(statement.keyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.expression);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.leftBracket);
    EngineTestCase.assertSizeOfList(1, statement.members);
    EngineTestCase.assertSizeOfList(3, statement.members[0].labels);
    JUnitTestCase.assertNotNull(statement.rightBracket);
  }

  void test_parseSwitchStatement_labeledStatementInCase() {
    SwitchStatement statement = ParserTestCase.parse4("parseSwitchStatement", "switch (a) {case 0: f(); l1: g(); break;}", []);
    JUnitTestCase.assertNotNull(statement.keyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.expression);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.leftBracket);
    EngineTestCase.assertSizeOfList(1, statement.members);
    EngineTestCase.assertSizeOfList(3, statement.members[0].statements);
    JUnitTestCase.assertNotNull(statement.rightBracket);
  }

  void test_parseSymbolLiteral_builtInIdentifier() {
    SymbolLiteral literal = ParserTestCase.parse4("parseSymbolLiteral", "#dynamic.static.abstract", []);
    JUnitTestCase.assertNotNull(literal.poundSign);
    List<Token> components = literal.components;
    EngineTestCase.assertLength(3, components);
    JUnitTestCase.assertEquals("dynamic", components[0].lexeme);
    JUnitTestCase.assertEquals("static", components[1].lexeme);
    JUnitTestCase.assertEquals("abstract", components[2].lexeme);
  }

  void test_parseSymbolLiteral_multiple() {
    SymbolLiteral literal = ParserTestCase.parse4("parseSymbolLiteral", "#a.b.c", []);
    JUnitTestCase.assertNotNull(literal.poundSign);
    List<Token> components = literal.components;
    EngineTestCase.assertLength(3, components);
    JUnitTestCase.assertEquals("a", components[0].lexeme);
    JUnitTestCase.assertEquals("b", components[1].lexeme);
    JUnitTestCase.assertEquals("c", components[2].lexeme);
  }

  void test_parseSymbolLiteral_operator() {
    SymbolLiteral literal = ParserTestCase.parse4("parseSymbolLiteral", "#==", []);
    JUnitTestCase.assertNotNull(literal.poundSign);
    List<Token> components = literal.components;
    EngineTestCase.assertLength(1, components);
    JUnitTestCase.assertEquals("==", components[0].lexeme);
  }

  void test_parseSymbolLiteral_single() {
    SymbolLiteral literal = ParserTestCase.parse4("parseSymbolLiteral", "#a", []);
    JUnitTestCase.assertNotNull(literal.poundSign);
    List<Token> components = literal.components;
    EngineTestCase.assertLength(1, components);
    JUnitTestCase.assertEquals("a", components[0].lexeme);
  }

  void test_parseSymbolLiteral_void() {
    SymbolLiteral literal = ParserTestCase.parse4("parseSymbolLiteral", "#void", []);
    JUnitTestCase.assertNotNull(literal.poundSign);
    List<Token> components = literal.components;
    EngineTestCase.assertLength(1, components);
    JUnitTestCase.assertEquals("void", components[0].lexeme);
  }

  void test_parseThrowExpression() {
    ThrowExpression expression = ParserTestCase.parse4("parseThrowExpression", "throw x;", []);
    JUnitTestCase.assertNotNull(expression.keyword);
    JUnitTestCase.assertNotNull(expression.expression);
  }

  void test_parseThrowExpressionWithoutCascade() {
    ThrowExpression expression = ParserTestCase.parse4("parseThrowExpressionWithoutCascade", "throw x;", []);
    JUnitTestCase.assertNotNull(expression.keyword);
    JUnitTestCase.assertNotNull(expression.expression);
  }

  void test_parseTryStatement_catch() {
    TryStatement statement = ParserTestCase.parse4("parseTryStatement", "try {} catch (e) {}", []);
    JUnitTestCase.assertNotNull(statement.tryKeyword);
    JUnitTestCase.assertNotNull(statement.body);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    EngineTestCase.assertSizeOfList(1, catchClauses);
    CatchClause clause = catchClauses[0];
    JUnitTestCase.assertNull(clause.onKeyword);
    JUnitTestCase.assertNull(clause.exceptionType);
    JUnitTestCase.assertNotNull(clause.catchKeyword);
    JUnitTestCase.assertNotNull(clause.exceptionParameter);
    JUnitTestCase.assertNull(clause.comma);
    JUnitTestCase.assertNull(clause.stackTraceParameter);
    JUnitTestCase.assertNotNull(clause.body);
    JUnitTestCase.assertNull(statement.finallyKeyword);
    JUnitTestCase.assertNull(statement.finallyBlock);
  }

  void test_parseTryStatement_catch_finally() {
    TryStatement statement = ParserTestCase.parse4("parseTryStatement", "try {} catch (e, s) {} finally {}", []);
    JUnitTestCase.assertNotNull(statement.tryKeyword);
    JUnitTestCase.assertNotNull(statement.body);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    EngineTestCase.assertSizeOfList(1, catchClauses);
    CatchClause clause = catchClauses[0];
    JUnitTestCase.assertNull(clause.onKeyword);
    JUnitTestCase.assertNull(clause.exceptionType);
    JUnitTestCase.assertNotNull(clause.catchKeyword);
    JUnitTestCase.assertNotNull(clause.exceptionParameter);
    JUnitTestCase.assertNotNull(clause.comma);
    JUnitTestCase.assertNotNull(clause.stackTraceParameter);
    JUnitTestCase.assertNotNull(clause.body);
    JUnitTestCase.assertNotNull(statement.finallyKeyword);
    JUnitTestCase.assertNotNull(statement.finallyBlock);
  }

  void test_parseTryStatement_finally() {
    TryStatement statement = ParserTestCase.parse4("parseTryStatement", "try {} finally {}", []);
    JUnitTestCase.assertNotNull(statement.tryKeyword);
    JUnitTestCase.assertNotNull(statement.body);
    EngineTestCase.assertSizeOfList(0, statement.catchClauses);
    JUnitTestCase.assertNotNull(statement.finallyKeyword);
    JUnitTestCase.assertNotNull(statement.finallyBlock);
  }

  void test_parseTryStatement_multiple() {
    TryStatement statement = ParserTestCase.parse4("parseTryStatement", "try {} on NPE catch (e) {} on Error {} catch (e) {}", []);
    JUnitTestCase.assertNotNull(statement.tryKeyword);
    JUnitTestCase.assertNotNull(statement.body);
    EngineTestCase.assertSizeOfList(3, statement.catchClauses);
    JUnitTestCase.assertNull(statement.finallyKeyword);
    JUnitTestCase.assertNull(statement.finallyBlock);
  }

  void test_parseTryStatement_on() {
    TryStatement statement = ParserTestCase.parse4("parseTryStatement", "try {} on Error {}", []);
    JUnitTestCase.assertNotNull(statement.tryKeyword);
    JUnitTestCase.assertNotNull(statement.body);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    EngineTestCase.assertSizeOfList(1, catchClauses);
    CatchClause clause = catchClauses[0];
    JUnitTestCase.assertNotNull(clause.onKeyword);
    JUnitTestCase.assertNotNull(clause.exceptionType);
    JUnitTestCase.assertNull(clause.catchKeyword);
    JUnitTestCase.assertNull(clause.exceptionParameter);
    JUnitTestCase.assertNull(clause.comma);
    JUnitTestCase.assertNull(clause.stackTraceParameter);
    JUnitTestCase.assertNotNull(clause.body);
    JUnitTestCase.assertNull(statement.finallyKeyword);
    JUnitTestCase.assertNull(statement.finallyBlock);
  }

  void test_parseTryStatement_on_catch() {
    TryStatement statement = ParserTestCase.parse4("parseTryStatement", "try {} on Error catch (e, s) {}", []);
    JUnitTestCase.assertNotNull(statement.tryKeyword);
    JUnitTestCase.assertNotNull(statement.body);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    EngineTestCase.assertSizeOfList(1, catchClauses);
    CatchClause clause = catchClauses[0];
    JUnitTestCase.assertNotNull(clause.onKeyword);
    JUnitTestCase.assertNotNull(clause.exceptionType);
    JUnitTestCase.assertNotNull(clause.catchKeyword);
    JUnitTestCase.assertNotNull(clause.exceptionParameter);
    JUnitTestCase.assertNotNull(clause.comma);
    JUnitTestCase.assertNotNull(clause.stackTraceParameter);
    JUnitTestCase.assertNotNull(clause.body);
    JUnitTestCase.assertNull(statement.finallyKeyword);
    JUnitTestCase.assertNull(statement.finallyBlock);
  }

  void test_parseTryStatement_on_catch_finally() {
    TryStatement statement = ParserTestCase.parse4("parseTryStatement", "try {} on Error catch (e, s) {} finally {}", []);
    JUnitTestCase.assertNotNull(statement.tryKeyword);
    JUnitTestCase.assertNotNull(statement.body);
    NodeList<CatchClause> catchClauses = statement.catchClauses;
    EngineTestCase.assertSizeOfList(1, catchClauses);
    CatchClause clause = catchClauses[0];
    JUnitTestCase.assertNotNull(clause.onKeyword);
    JUnitTestCase.assertNotNull(clause.exceptionType);
    JUnitTestCase.assertNotNull(clause.catchKeyword);
    JUnitTestCase.assertNotNull(clause.exceptionParameter);
    JUnitTestCase.assertNotNull(clause.comma);
    JUnitTestCase.assertNotNull(clause.stackTraceParameter);
    JUnitTestCase.assertNotNull(clause.body);
    JUnitTestCase.assertNotNull(statement.finallyKeyword);
    JUnitTestCase.assertNotNull(statement.finallyBlock);
  }

  void test_parseTypeAlias_function_noParameters() {
    FunctionTypeAlias typeAlias = ParserTestCase.parse("parseTypeAlias", <Object> [emptyCommentAndMetadata()], "typedef bool F();");
    JUnitTestCase.assertNotNull(typeAlias.keyword);
    JUnitTestCase.assertNotNull(typeAlias.name);
    JUnitTestCase.assertNotNull(typeAlias.parameters);
    JUnitTestCase.assertNotNull(typeAlias.returnType);
    JUnitTestCase.assertNotNull(typeAlias.semicolon);
    JUnitTestCase.assertNull(typeAlias.typeParameters);
  }

  void test_parseTypeAlias_function_noReturnType() {
    FunctionTypeAlias typeAlias = ParserTestCase.parse("parseTypeAlias", <Object> [emptyCommentAndMetadata()], "typedef F();");
    JUnitTestCase.assertNotNull(typeAlias.keyword);
    JUnitTestCase.assertNotNull(typeAlias.name);
    JUnitTestCase.assertNotNull(typeAlias.parameters);
    JUnitTestCase.assertNull(typeAlias.returnType);
    JUnitTestCase.assertNotNull(typeAlias.semicolon);
    JUnitTestCase.assertNull(typeAlias.typeParameters);
  }

  void test_parseTypeAlias_function_parameterizedReturnType() {
    FunctionTypeAlias typeAlias = ParserTestCase.parse("parseTypeAlias", <Object> [emptyCommentAndMetadata()], "typedef A<B> F();");
    JUnitTestCase.assertNotNull(typeAlias.keyword);
    JUnitTestCase.assertNotNull(typeAlias.name);
    JUnitTestCase.assertNotNull(typeAlias.parameters);
    JUnitTestCase.assertNotNull(typeAlias.returnType);
    JUnitTestCase.assertNotNull(typeAlias.semicolon);
    JUnitTestCase.assertNull(typeAlias.typeParameters);
  }

  void test_parseTypeAlias_function_parameters() {
    FunctionTypeAlias typeAlias = ParserTestCase.parse("parseTypeAlias", <Object> [emptyCommentAndMetadata()], "typedef bool F(Object value);");
    JUnitTestCase.assertNotNull(typeAlias.keyword);
    JUnitTestCase.assertNotNull(typeAlias.name);
    JUnitTestCase.assertNotNull(typeAlias.parameters);
    JUnitTestCase.assertNotNull(typeAlias.returnType);
    JUnitTestCase.assertNotNull(typeAlias.semicolon);
    JUnitTestCase.assertNull(typeAlias.typeParameters);
  }

  void test_parseTypeAlias_function_typeParameters() {
    FunctionTypeAlias typeAlias = ParserTestCase.parse("parseTypeAlias", <Object> [emptyCommentAndMetadata()], "typedef bool F<E>();");
    JUnitTestCase.assertNotNull(typeAlias.keyword);
    JUnitTestCase.assertNotNull(typeAlias.name);
    JUnitTestCase.assertNotNull(typeAlias.parameters);
    JUnitTestCase.assertNotNull(typeAlias.returnType);
    JUnitTestCase.assertNotNull(typeAlias.semicolon);
    JUnitTestCase.assertNotNull(typeAlias.typeParameters);
  }

  void test_parseTypeAlias_function_voidReturnType() {
    FunctionTypeAlias typeAlias = ParserTestCase.parse("parseTypeAlias", <Object> [emptyCommentAndMetadata()], "typedef void F();");
    JUnitTestCase.assertNotNull(typeAlias.keyword);
    JUnitTestCase.assertNotNull(typeAlias.name);
    JUnitTestCase.assertNotNull(typeAlias.parameters);
    JUnitTestCase.assertNotNull(typeAlias.returnType);
    JUnitTestCase.assertNotNull(typeAlias.semicolon);
    JUnitTestCase.assertNull(typeAlias.typeParameters);
  }

  void test_parseTypeArgumentList_multiple() {
    TypeArgumentList argumentList = ParserTestCase.parse4("parseTypeArgumentList", "<int, int, int>", []);
    JUnitTestCase.assertNotNull(argumentList.leftBracket);
    EngineTestCase.assertSizeOfList(3, argumentList.arguments);
    JUnitTestCase.assertNotNull(argumentList.rightBracket);
  }

  void test_parseTypeArgumentList_nested() {
    TypeArgumentList argumentList = ParserTestCase.parse4("parseTypeArgumentList", "<A<B>>", []);
    JUnitTestCase.assertNotNull(argumentList.leftBracket);
    EngineTestCase.assertSizeOfList(1, argumentList.arguments);
    TypeName argument = argumentList.arguments[0];
    JUnitTestCase.assertNotNull(argument);
    TypeArgumentList innerList = argument.typeArguments;
    JUnitTestCase.assertNotNull(innerList);
    EngineTestCase.assertSizeOfList(1, innerList.arguments);
    JUnitTestCase.assertNotNull(argumentList.rightBracket);
  }

  void test_parseTypeArgumentList_single() {
    TypeArgumentList argumentList = ParserTestCase.parse4("parseTypeArgumentList", "<int>", []);
    JUnitTestCase.assertNotNull(argumentList.leftBracket);
    EngineTestCase.assertSizeOfList(1, argumentList.arguments);
    JUnitTestCase.assertNotNull(argumentList.rightBracket);
  }

  void test_parseTypeName_parameterized() {
    TypeName typeName = ParserTestCase.parse4("parseTypeName", "List<int>", []);
    JUnitTestCase.assertNotNull(typeName.name);
    JUnitTestCase.assertNotNull(typeName.typeArguments);
  }

  void test_parseTypeName_simple() {
    TypeName typeName = ParserTestCase.parse4("parseTypeName", "int", []);
    JUnitTestCase.assertNotNull(typeName.name);
    JUnitTestCase.assertNull(typeName.typeArguments);
  }

  void test_parseTypeParameter_bounded() {
    TypeParameter parameter = ParserTestCase.parse4("parseTypeParameter", "A extends B", []);
    JUnitTestCase.assertNotNull(parameter.bound);
    JUnitTestCase.assertNotNull(parameter.keyword);
    JUnitTestCase.assertNotNull(parameter.name);
  }

  void test_parseTypeParameter_simple() {
    TypeParameter parameter = ParserTestCase.parse4("parseTypeParameter", "A", []);
    JUnitTestCase.assertNull(parameter.bound);
    JUnitTestCase.assertNull(parameter.keyword);
    JUnitTestCase.assertNotNull(parameter.name);
  }

  void test_parseTypeParameterList_multiple() {
    TypeParameterList parameterList = ParserTestCase.parse4("parseTypeParameterList", "<A, B extends C, D>", []);
    JUnitTestCase.assertNotNull(parameterList.leftBracket);
    JUnitTestCase.assertNotNull(parameterList.rightBracket);
    EngineTestCase.assertSizeOfList(3, parameterList.typeParameters);
  }

  void test_parseTypeParameterList_parameterizedWithTrailingEquals() {
    TypeParameterList parameterList = ParserTestCase.parse4("parseTypeParameterList", "<A extends B<E>>=", []);
    JUnitTestCase.assertNotNull(parameterList.leftBracket);
    JUnitTestCase.assertNotNull(parameterList.rightBracket);
    EngineTestCase.assertSizeOfList(1, parameterList.typeParameters);
  }

  void test_parseTypeParameterList_single() {
    TypeParameterList parameterList = ParserTestCase.parse4("parseTypeParameterList", "<A>", []);
    JUnitTestCase.assertNotNull(parameterList.leftBracket);
    JUnitTestCase.assertNotNull(parameterList.rightBracket);
    EngineTestCase.assertSizeOfList(1, parameterList.typeParameters);
  }

  void test_parseTypeParameterList_withTrailingEquals() {
    TypeParameterList parameterList = ParserTestCase.parse4("parseTypeParameterList", "<A>=", []);
    JUnitTestCase.assertNotNull(parameterList.leftBracket);
    JUnitTestCase.assertNotNull(parameterList.rightBracket);
    EngineTestCase.assertSizeOfList(1, parameterList.typeParameters);
  }

  void test_parseUnaryExpression_decrement_normal() {
    PrefixExpression expression = ParserTestCase.parse4("parseUnaryExpression", "--x", []);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.MINUS_MINUS, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.operand);
  }

  void test_parseUnaryExpression_decrement_super() {
    PrefixExpression expression = ParserTestCase.parse4("parseUnaryExpression", "--super", []);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.MINUS, expression.operator.type);
    Expression innerExpression = expression.operand;
    JUnitTestCase.assertNotNull(innerExpression);
    JUnitTestCase.assertTrue(innerExpression is PrefixExpression);
    PrefixExpression operand = innerExpression as PrefixExpression;
    JUnitTestCase.assertNotNull(operand.operator);
    JUnitTestCase.assertEquals(TokenType.MINUS, operand.operator.type);
    JUnitTestCase.assertNotNull(operand.operand);
  }

  void test_parseUnaryExpression_decrement_super_propertyAccess() {
    PrefixExpression expression = ParserTestCase.parse4("parseUnaryExpression", "--super.x", []);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.MINUS_MINUS, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.operand);
    PropertyAccess operand = expression.operand as PropertyAccess;
    JUnitTestCase.assertTrue(operand.target is SuperExpression);
    JUnitTestCase.assertEquals("x", operand.propertyName.name);
  }

  void test_parseUnaryExpression_increment_normal() {
    PrefixExpression expression = ParserTestCase.parse4("parseUnaryExpression", "++x", []);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.PLUS_PLUS, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.operand);
  }

  void test_parseUnaryExpression_increment_super_index() {
    PrefixExpression expression = ParserTestCase.parse4("parseUnaryExpression", "++super[0]", []);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.PLUS_PLUS, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.operand);
    IndexExpression operand = expression.operand as IndexExpression;
    JUnitTestCase.assertTrue(operand.realTarget is SuperExpression);
    JUnitTestCase.assertTrue(operand.index is IntegerLiteral);
  }

  void test_parseUnaryExpression_increment_super_propertyAccess() {
    PrefixExpression expression = ParserTestCase.parse4("parseUnaryExpression", "++super.x", []);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.PLUS_PLUS, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.operand);
    PropertyAccess operand = expression.operand as PropertyAccess;
    JUnitTestCase.assertTrue(operand.target is SuperExpression);
    JUnitTestCase.assertEquals("x", operand.propertyName.name);
  }

  void test_parseUnaryExpression_minus_normal() {
    PrefixExpression expression = ParserTestCase.parse4("parseUnaryExpression", "-x", []);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.MINUS, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.operand);
  }

  void test_parseUnaryExpression_minus_super() {
    PrefixExpression expression = ParserTestCase.parse4("parseUnaryExpression", "-super", []);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.MINUS, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.operand);
  }

  void test_parseUnaryExpression_not_normal() {
    PrefixExpression expression = ParserTestCase.parse4("parseUnaryExpression", "!x", []);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.BANG, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.operand);
  }

  void test_parseUnaryExpression_not_super() {
    PrefixExpression expression = ParserTestCase.parse4("parseUnaryExpression", "!super", []);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.BANG, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.operand);
  }

  void test_parseUnaryExpression_tilda_normal() {
    PrefixExpression expression = ParserTestCase.parse4("parseUnaryExpression", "~x", []);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.TILDE, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.operand);
  }

  void test_parseUnaryExpression_tilda_super() {
    PrefixExpression expression = ParserTestCase.parse4("parseUnaryExpression", "~super", []);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.TILDE, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.operand);
  }

  void test_parseVariableDeclaration_equals() {
    VariableDeclaration declaration = ParserTestCase.parse4("parseVariableDeclaration", "a = b", []);
    JUnitTestCase.assertNotNull(declaration.name);
    JUnitTestCase.assertNotNull(declaration.equals);
    JUnitTestCase.assertNotNull(declaration.initializer);
  }

  void test_parseVariableDeclaration_noEquals() {
    VariableDeclaration declaration = ParserTestCase.parse4("parseVariableDeclaration", "a", []);
    JUnitTestCase.assertNotNull(declaration.name);
    JUnitTestCase.assertNull(declaration.equals);
    JUnitTestCase.assertNull(declaration.initializer);
  }

  void test_parseVariableDeclarationListAfterMetadata_const_noType() {
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationListAfterMetadata", <Object> [emptyCommentAndMetadata()], "const a");
    JUnitTestCase.assertNotNull(declarationList.keyword);
    JUnitTestCase.assertNull(declarationList.type);
    EngineTestCase.assertSizeOfList(1, declarationList.variables);
  }

  void test_parseVariableDeclarationListAfterMetadata_const_type() {
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationListAfterMetadata", <Object> [emptyCommentAndMetadata()], "const A a");
    JUnitTestCase.assertNotNull(declarationList.keyword);
    JUnitTestCase.assertNotNull(declarationList.type);
    EngineTestCase.assertSizeOfList(1, declarationList.variables);
  }

  void test_parseVariableDeclarationListAfterMetadata_final_noType() {
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationListAfterMetadata", <Object> [emptyCommentAndMetadata()], "final a");
    JUnitTestCase.assertNotNull(declarationList.keyword);
    JUnitTestCase.assertNull(declarationList.type);
    EngineTestCase.assertSizeOfList(1, declarationList.variables);
  }

  void test_parseVariableDeclarationListAfterMetadata_final_type() {
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationListAfterMetadata", <Object> [emptyCommentAndMetadata()], "final A a");
    JUnitTestCase.assertNotNull(declarationList.keyword);
    JUnitTestCase.assertNotNull(declarationList.type);
    EngineTestCase.assertSizeOfList(1, declarationList.variables);
  }

  void test_parseVariableDeclarationListAfterMetadata_type_multiple() {
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationListAfterMetadata", <Object> [emptyCommentAndMetadata()], "A a, b, c");
    JUnitTestCase.assertNull(declarationList.keyword);
    JUnitTestCase.assertNotNull(declarationList.type);
    EngineTestCase.assertSizeOfList(3, declarationList.variables);
  }

  void test_parseVariableDeclarationListAfterMetadata_type_single() {
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationListAfterMetadata", <Object> [emptyCommentAndMetadata()], "A a");
    JUnitTestCase.assertNull(declarationList.keyword);
    JUnitTestCase.assertNotNull(declarationList.type);
    EngineTestCase.assertSizeOfList(1, declarationList.variables);
  }

  void test_parseVariableDeclarationListAfterMetadata_var_multiple() {
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationListAfterMetadata", <Object> [emptyCommentAndMetadata()], "var a, b, c");
    JUnitTestCase.assertNotNull(declarationList.keyword);
    JUnitTestCase.assertNull(declarationList.type);
    EngineTestCase.assertSizeOfList(3, declarationList.variables);
  }

  void test_parseVariableDeclarationListAfterMetadata_var_single() {
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationListAfterMetadata", <Object> [emptyCommentAndMetadata()], "var a");
    JUnitTestCase.assertNotNull(declarationList.keyword);
    JUnitTestCase.assertNull(declarationList.type);
    EngineTestCase.assertSizeOfList(1, declarationList.variables);
  }

  void test_parseVariableDeclarationListAfterType_type() {
    TypeName type = new TypeName(new SimpleIdentifier(null), null);
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationListAfterType", <Object> [emptyCommentAndMetadata(), null, type], "a");
    JUnitTestCase.assertNull(declarationList.keyword);
    JUnitTestCase.assertEquals(type, declarationList.type);
    EngineTestCase.assertSizeOfList(1, declarationList.variables);
  }

  void test_parseVariableDeclarationListAfterType_var() {
    Token keyword = TokenFactory.tokenFromKeyword(Keyword.VAR);
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationListAfterType", <Object> [emptyCommentAndMetadata(), keyword, null], "a, b, c");
    JUnitTestCase.assertEquals(keyword, declarationList.keyword);
    JUnitTestCase.assertNull(declarationList.type);
    EngineTestCase.assertSizeOfList(3, declarationList.variables);
  }

  void test_parseVariableDeclarationStatementAfterMetadata_multiple() {
    VariableDeclarationStatement statement = ParserTestCase.parse("parseVariableDeclarationStatementAfterMetadata", <Object> [emptyCommentAndMetadata()], "var x, y, z;");
    JUnitTestCase.assertNotNull(statement.semicolon);
    VariableDeclarationList variableList = statement.variables;
    JUnitTestCase.assertNotNull(variableList);
    EngineTestCase.assertSizeOfList(3, variableList.variables);
  }

  void test_parseVariableDeclarationStatementAfterMetadata_single() {
    VariableDeclarationStatement statement = ParserTestCase.parse("parseVariableDeclarationStatementAfterMetadata", <Object> [emptyCommentAndMetadata()], "var x;");
    JUnitTestCase.assertNotNull(statement.semicolon);
    VariableDeclarationList variableList = statement.variables;
    JUnitTestCase.assertNotNull(variableList);
    EngineTestCase.assertSizeOfList(1, variableList.variables);
  }

  void test_parseWhileStatement() {
    WhileStatement statement = ParserTestCase.parse4("parseWhileStatement", "while (x) {}", []);
    JUnitTestCase.assertNotNull(statement.keyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }

  void test_parseWithClause_multiple() {
    WithClause clause = ParserTestCase.parse4("parseWithClause", "with A, B, C", []);
    JUnitTestCase.assertNotNull(clause.withKeyword);
    EngineTestCase.assertSizeOfList(3, clause.mixinTypes);
  }

  void test_parseWithClause_single() {
    WithClause clause = ParserTestCase.parse4("parseWithClause", "with M", []);
    JUnitTestCase.assertNotNull(clause.withKeyword);
    EngineTestCase.assertSizeOfList(1, clause.mixinTypes);
  }

  void test_parseYieldStatement_each() {
    YieldStatement statement = ParserTestCase.parse4("parseYieldStatement", "yield* x;", []);
    JUnitTestCase.assertNotNull(statement.yieldKeyword);
    JUnitTestCase.assertNotNull(statement.star);
    JUnitTestCase.assertNotNull(statement.expression);
    JUnitTestCase.assertNotNull(statement.semicolon);
  }

  void test_parseYieldStatement_normal() {
    YieldStatement statement = ParserTestCase.parse4("parseYieldStatement", "yield x;", []);
    JUnitTestCase.assertNotNull(statement.yieldKeyword);
    JUnitTestCase.assertNull(statement.star);
    JUnitTestCase.assertNotNull(statement.expression);
    JUnitTestCase.assertNotNull(statement.semicolon);
  }

  void test_skipPrefixedIdentifier_invalid() {
    Token following = _skip("skipPrefixedIdentifier", "+");
    JUnitTestCase.assertNull(following);
  }

  void test_skipPrefixedIdentifier_notPrefixed() {
    Token following = _skip("skipPrefixedIdentifier", "a +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }

  void test_skipPrefixedIdentifier_prefixed() {
    Token following = _skip("skipPrefixedIdentifier", "a.b +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }

  void test_skipReturnType_invalid() {
    Token following = _skip("skipReturnType", "+");
    JUnitTestCase.assertNull(following);
  }

  void test_skipReturnType_type() {
    Token following = _skip("skipReturnType", "C +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }

  void test_skipReturnType_void() {
    Token following = _skip("skipReturnType", "void +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }

  void test_skipSimpleIdentifier_identifier() {
    Token following = _skip("skipSimpleIdentifier", "i +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }

  void test_skipSimpleIdentifier_invalid() {
    Token following = _skip("skipSimpleIdentifier", "9 +");
    JUnitTestCase.assertNull(following);
  }

  void test_skipSimpleIdentifier_pseudoKeyword() {
    Token following = _skip("skipSimpleIdentifier", "as +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }

  void test_skipStringLiteral_adjacent() {
    Token following = _skip("skipStringLiteral", "'a' 'b' +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }

  void test_skipStringLiteral_interpolated() {
    Token following = _skip("skipStringLiteral", "'a\${b}c' +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }

  void test_skipStringLiteral_invalid() {
    Token following = _skip("skipStringLiteral", "a");
    JUnitTestCase.assertNull(following);
  }

  void test_skipStringLiteral_single() {
    Token following = _skip("skipStringLiteral", "'a' +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }

  void test_skipTypeArgumentList_invalid() {
    Token following = _skip("skipTypeArgumentList", "+");
    JUnitTestCase.assertNull(following);
  }

  void test_skipTypeArgumentList_multiple() {
    Token following = _skip("skipTypeArgumentList", "<E, F, G> +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }

  void test_skipTypeArgumentList_single() {
    Token following = _skip("skipTypeArgumentList", "<E> +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }

  void test_skipTypeName_invalid() {
    Token following = _skip("skipTypeName", "+");
    JUnitTestCase.assertNull(following);
  }

  void test_skipTypeName_parameterized() {
    Token following = _skip("skipTypeName", "C<E<F<G>>> +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }

  void test_skipTypeName_simple() {
    Token following = _skip("skipTypeName", "C +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
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
    JUnitTestCase.assertNotNull(unit);
    EngineTestCase.assertSizeOfList(0, unit.declarations);
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
  _ut.groupSep = ' | ';
  runReflectiveTests(ComplexParserTest);
  runReflectiveTests(ErrorParserTest);
  runReflectiveTests(IncrementalParserTest);
  runReflectiveTests(NonErrorParserTest);
  runReflectiveTests(RecoveryParserTest);
  runReflectiveTests(ResolutionCopierTest);
  runReflectiveTests(SimpleParserTest);
}