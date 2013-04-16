// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.parser_test;

import 'dart:collection';
import 'package:analyzer_experimental/src/generated/java_core.dart';
import 'package:analyzer_experimental/src/generated/java_engine.dart';
import 'package:analyzer_experimental/src/generated/java_junit.dart';
import 'package:analyzer_experimental/src/generated/source.dart';
import 'package:analyzer_experimental/src/generated/error.dart';
import 'package:analyzer_experimental/src/generated/scanner.dart';
import 'package:analyzer_experimental/src/generated/ast.dart';
import 'package:analyzer_experimental/src/generated/parser.dart';
import 'package:analyzer_experimental/src/generated/utilities_dart.dart';
import 'package:unittest/unittest.dart' as _ut;
import 'test_support.dart';
import 'scanner_test.dart' show TokenFactory;

/**
 * The class {@code SimpleParserTest} defines parser tests that test individual parsing method. The
 * code fragments should be as minimal as possible in order to test the method, but should not test
 * the interactions between the method under test and other methods.
 * <p>
 * More complex tests should be defined in the class {@link ComplexParserTest}.
 */
class SimpleParserTest extends ParserTestCase {
  void fail_parseCommentReference_this() {
    CommentReference reference = ParserTestCase.parse("parseCommentReference", <Object> ["this", 5], "");
    SimpleIdentifier identifier21 = EngineTestCase.assertInstanceOf(SimpleIdentifier, reference.identifier);
    JUnitTestCase.assertNotNull(identifier21.token);
    JUnitTestCase.assertEquals("a", identifier21.name);
    JUnitTestCase.assertEquals(5, identifier21.offset);
  }
  void test_computeStringValue_emptyInterpolationPrefix() {
    JUnitTestCase.assertEquals("", computeStringValue("'''"));
  }
  void test_computeStringValue_escape_b() {
    JUnitTestCase.assertEquals("\b", computeStringValue("'\\b'"));
  }
  void test_computeStringValue_escape_f() {
    JUnitTestCase.assertEquals("\f", computeStringValue("'\\f'"));
  }
  void test_computeStringValue_escape_n() {
    JUnitTestCase.assertEquals("\n", computeStringValue("'\\n'"));
  }
  void test_computeStringValue_escape_notSpecial() {
    JUnitTestCase.assertEquals(":", computeStringValue("'\\:'"));
  }
  void test_computeStringValue_escape_r() {
    JUnitTestCase.assertEquals("\r", computeStringValue("'\\r'"));
  }
  void test_computeStringValue_escape_t() {
    JUnitTestCase.assertEquals("\t", computeStringValue("'\\t'"));
  }
  void test_computeStringValue_escape_u_fixed() {
    JUnitTestCase.assertEquals("\u4321", computeStringValue("'\\u4321'"));
  }
  void test_computeStringValue_escape_u_variable() {
    JUnitTestCase.assertEquals("\u0123", computeStringValue("'\\u{123}'"));
  }
  void test_computeStringValue_escape_v() {
    JUnitTestCase.assertEquals("\u000B", computeStringValue("'\\v'"));
  }
  void test_computeStringValue_escape_x() {
    JUnitTestCase.assertEquals("\u00FF", computeStringValue("'\\xFF'"));
  }
  void test_computeStringValue_noEscape_single() {
    JUnitTestCase.assertEquals("text", computeStringValue("'text'"));
  }
  void test_computeStringValue_noEscape_triple() {
    JUnitTestCase.assertEquals("text", computeStringValue("'''text'''"));
  }
  void test_computeStringValue_raw_single() {
    JUnitTestCase.assertEquals("text", computeStringValue("r'text'"));
  }
  void test_computeStringValue_raw_triple() {
    JUnitTestCase.assertEquals("text", computeStringValue("r'''text'''"));
  }
  void test_computeStringValue_raw_withEscape() {
    JUnitTestCase.assertEquals("two\\nlines", computeStringValue("r'two\\nlines'"));
  }
  void test_createSyntheticIdentifier() {
    SimpleIdentifier identifier = createSyntheticIdentifier();
    JUnitTestCase.assertTrue(identifier.isSynthetic());
  }
  void test_createSyntheticStringLiteral() {
    SimpleStringLiteral literal = createSyntheticStringLiteral();
    JUnitTestCase.assertTrue(literal.isSynthetic());
  }
  void test_isFunctionDeclaration_nameButNoReturn_block() {
    JUnitTestCase.assertTrue(isFunctionDeclaration("f() {}"));
  }
  void test_isFunctionDeclaration_nameButNoReturn_expression() {
    JUnitTestCase.assertTrue(isFunctionDeclaration("f() => e"));
  }
  void test_isFunctionDeclaration_normalReturn_block() {
    JUnitTestCase.assertTrue(isFunctionDeclaration("C f() {}"));
  }
  void test_isFunctionDeclaration_normalReturn_expression() {
    JUnitTestCase.assertTrue(isFunctionDeclaration("C f() => e"));
  }
  void test_isFunctionDeclaration_voidReturn_block() {
    JUnitTestCase.assertTrue(isFunctionDeclaration("void f() {}"));
  }
  void test_isFunctionDeclaration_voidReturn_expression() {
    JUnitTestCase.assertTrue(isFunctionDeclaration("void f() => e"));
  }
  void test_isFunctionExpression_false_noBody() {
    JUnitTestCase.assertFalse(isFunctionExpression("f();"));
  }
  void test_isFunctionExpression_false_notParameters() {
    JUnitTestCase.assertFalse(isFunctionExpression("(a + b) {"));
  }
  void test_isFunctionExpression_noName_block() {
    JUnitTestCase.assertTrue(isFunctionExpression("() {}"));
  }
  void test_isFunctionExpression_noName_expression() {
    JUnitTestCase.assertTrue(isFunctionExpression("() => e"));
  }
  void test_isFunctionExpression_parameter_multiple() {
    JUnitTestCase.assertTrue(isFunctionExpression("(a, b) {}"));
  }
  void test_isFunctionExpression_parameter_named() {
    JUnitTestCase.assertTrue(isFunctionExpression("({a}) {}"));
  }
  void test_isFunctionExpression_parameter_optional() {
    JUnitTestCase.assertTrue(isFunctionExpression("([a]) {}"));
  }
  void test_isFunctionExpression_parameter_single() {
    JUnitTestCase.assertTrue(isFunctionExpression("(a) {}"));
  }
  void test_isFunctionExpression_parameter_typed() {
    JUnitTestCase.assertTrue(isFunctionExpression("(int a, int b) {}"));
  }
  void test_isInitializedVariableDeclaration_assignment() {
    JUnitTestCase.assertFalse(isInitializedVariableDeclaration("a = null;"));
  }
  void test_isInitializedVariableDeclaration_comparison() {
    JUnitTestCase.assertFalse(isInitializedVariableDeclaration("a < 0;"));
  }
  void test_isInitializedVariableDeclaration_conditional() {
    JUnitTestCase.assertFalse(isInitializedVariableDeclaration("a == null ? init() : update();"));
  }
  void test_isInitializedVariableDeclaration_const_noType_initialized() {
    JUnitTestCase.assertTrue(isInitializedVariableDeclaration("const a = 0;"));
  }
  void test_isInitializedVariableDeclaration_const_noType_uninitialized() {
    JUnitTestCase.assertTrue(isInitializedVariableDeclaration("const a;"));
  }
  void test_isInitializedVariableDeclaration_const_simpleType_uninitialized() {
    JUnitTestCase.assertTrue(isInitializedVariableDeclaration("const A a;"));
  }
  void test_isInitializedVariableDeclaration_final_noType_initialized() {
    JUnitTestCase.assertTrue(isInitializedVariableDeclaration("final a = 0;"));
  }
  void test_isInitializedVariableDeclaration_final_noType_uninitialized() {
    JUnitTestCase.assertTrue(isInitializedVariableDeclaration("final a;"));
  }
  void test_isInitializedVariableDeclaration_final_simpleType_initialized() {
    JUnitTestCase.assertTrue(isInitializedVariableDeclaration("final A a = 0;"));
  }
  void test_isInitializedVariableDeclaration_functionDeclaration_typed() {
    JUnitTestCase.assertFalse(isInitializedVariableDeclaration("A f() {};"));
  }
  void test_isInitializedVariableDeclaration_functionDeclaration_untyped() {
    JUnitTestCase.assertFalse(isInitializedVariableDeclaration("f() {};"));
  }
  void test_isInitializedVariableDeclaration_noType_initialized() {
    JUnitTestCase.assertTrue(isInitializedVariableDeclaration("var a = 0;"));
  }
  void test_isInitializedVariableDeclaration_noType_uninitialized() {
    JUnitTestCase.assertTrue(isInitializedVariableDeclaration("var a;"));
  }
  void test_isInitializedVariableDeclaration_parameterizedType_initialized() {
    JUnitTestCase.assertTrue(isInitializedVariableDeclaration("List<int> a = null;"));
  }
  void test_isInitializedVariableDeclaration_parameterizedType_uninitialized() {
    JUnitTestCase.assertTrue(isInitializedVariableDeclaration("List<int> a;"));
  }
  void test_isInitializedVariableDeclaration_simpleType_initialized() {
    JUnitTestCase.assertTrue(isInitializedVariableDeclaration("A a = 0;"));
  }
  void test_isInitializedVariableDeclaration_simpleType_uninitialized() {
    JUnitTestCase.assertTrue(isInitializedVariableDeclaration("A a;"));
  }
  void test_isSwitchMember_case_labeled() {
    JUnitTestCase.assertTrue(isSwitchMember("l1: l2: case"));
  }
  void test_isSwitchMember_case_unlabeled() {
    JUnitTestCase.assertTrue(isSwitchMember("case"));
  }
  void test_isSwitchMember_default_labeled() {
    JUnitTestCase.assertTrue(isSwitchMember("l1: l2: default"));
  }
  void test_isSwitchMember_default_unlabeled() {
    JUnitTestCase.assertTrue(isSwitchMember("default"));
  }
  void test_isSwitchMember_false() {
    JUnitTestCase.assertFalse(isSwitchMember("break;"));
  }
  void test_parseAdditiveExpression_normal() {
    BinaryExpression expression = ParserTestCase.parse5("parseAdditiveExpression", "x + y", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.PLUS, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }
  void test_parseAdditiveExpression_super() {
    BinaryExpression expression = ParserTestCase.parse5("parseAdditiveExpression", "super + y", []);
    EngineTestCase.assertInstanceOf(SuperExpression, expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.PLUS, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }
  void test_parseAnnotation_n1() {
    Annotation annotation = ParserTestCase.parse5("parseAnnotation", "@A", []);
    JUnitTestCase.assertNotNull(annotation.atSign);
    JUnitTestCase.assertNotNull(annotation.name);
    JUnitTestCase.assertNull(annotation.period);
    JUnitTestCase.assertNull(annotation.constructorName);
    JUnitTestCase.assertNull(annotation.arguments);
  }
  void test_parseAnnotation_n1_a() {
    Annotation annotation = ParserTestCase.parse5("parseAnnotation", "@A(x,y)", []);
    JUnitTestCase.assertNotNull(annotation.atSign);
    JUnitTestCase.assertNotNull(annotation.name);
    JUnitTestCase.assertNull(annotation.period);
    JUnitTestCase.assertNull(annotation.constructorName);
    JUnitTestCase.assertNotNull(annotation.arguments);
  }
  void test_parseAnnotation_n2() {
    Annotation annotation = ParserTestCase.parse5("parseAnnotation", "@A.B", []);
    JUnitTestCase.assertNotNull(annotation.atSign);
    JUnitTestCase.assertNotNull(annotation.name);
    JUnitTestCase.assertNull(annotation.period);
    JUnitTestCase.assertNull(annotation.constructorName);
    JUnitTestCase.assertNull(annotation.arguments);
  }
  void test_parseAnnotation_n2_a() {
    Annotation annotation = ParserTestCase.parse5("parseAnnotation", "@A.B(x,y)", []);
    JUnitTestCase.assertNotNull(annotation.atSign);
    JUnitTestCase.assertNotNull(annotation.name);
    JUnitTestCase.assertNull(annotation.period);
    JUnitTestCase.assertNull(annotation.constructorName);
    JUnitTestCase.assertNotNull(annotation.arguments);
  }
  void test_parseAnnotation_n3() {
    Annotation annotation = ParserTestCase.parse5("parseAnnotation", "@A.B.C", []);
    JUnitTestCase.assertNotNull(annotation.atSign);
    JUnitTestCase.assertNotNull(annotation.name);
    JUnitTestCase.assertNotNull(annotation.period);
    JUnitTestCase.assertNotNull(annotation.constructorName);
    JUnitTestCase.assertNull(annotation.arguments);
  }
  void test_parseAnnotation_n3_a() {
    Annotation annotation = ParserTestCase.parse5("parseAnnotation", "@A.B.C(x,y)", []);
    JUnitTestCase.assertNotNull(annotation.atSign);
    JUnitTestCase.assertNotNull(annotation.name);
    JUnitTestCase.assertNotNull(annotation.period);
    JUnitTestCase.assertNotNull(annotation.constructorName);
    JUnitTestCase.assertNotNull(annotation.arguments);
  }
  void test_parseArgument_named() {
    NamedExpression expression = ParserTestCase.parse5("parseArgument", "n: x", []);
    Label name26 = expression.name;
    JUnitTestCase.assertNotNull(name26);
    JUnitTestCase.assertNotNull(name26.label);
    JUnitTestCase.assertNotNull(name26.colon);
    JUnitTestCase.assertNotNull(expression.expression);
  }
  void test_parseArgument_unnamed() {
    String lexeme = "x";
    SimpleIdentifier identifier = ParserTestCase.parse5("parseArgument", lexeme, []);
    JUnitTestCase.assertEquals(lexeme, identifier.name);
  }
  void test_parseArgumentDefinitionTest() {
    ArgumentDefinitionTest test = ParserTestCase.parse5("parseArgumentDefinitionTest", "?x", []);
    JUnitTestCase.assertNotNull(test.question);
    JUnitTestCase.assertNotNull(test.identifier);
  }
  void test_parseArgumentList_empty() {
    ArgumentList argumentList = ParserTestCase.parse5("parseArgumentList", "()", []);
    NodeList<Expression> arguments9 = argumentList.arguments;
    EngineTestCase.assertSize(0, arguments9);
  }
  void test_parseArgumentList_mixed() {
    ArgumentList argumentList = ParserTestCase.parse5("parseArgumentList", "(w, x, y: y, z: z)", []);
    NodeList<Expression> arguments10 = argumentList.arguments;
    EngineTestCase.assertSize(4, arguments10);
  }
  void test_parseArgumentList_noNamed() {
    ArgumentList argumentList = ParserTestCase.parse5("parseArgumentList", "(x, y, z)", []);
    NodeList<Expression> arguments11 = argumentList.arguments;
    EngineTestCase.assertSize(3, arguments11);
  }
  void test_parseArgumentList_onlyNamed() {
    ArgumentList argumentList = ParserTestCase.parse5("parseArgumentList", "(x: x, y: y)", []);
    NodeList<Expression> arguments12 = argumentList.arguments;
    EngineTestCase.assertSize(2, arguments12);
  }
  void test_parseAssertStatement() {
    AssertStatement statement = ParserTestCase.parse5("parseAssertStatement", "assert (x);", []);
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
    ArgumentList argumentList10 = invocation.argumentList;
    JUnitTestCase.assertNotNull(argumentList10);
    EngineTestCase.assertSize(1, argumentList10.arguments);
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
    JUnitTestCase.assertNotNull(expression.array);
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
    ArgumentList argumentList11 = invocation.argumentList;
    JUnitTestCase.assertNotNull(argumentList11);
    EngineTestCase.assertSize(1, argumentList11.arguments);
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
    JUnitTestCase.assertNotNull(expression.array);
    JUnitTestCase.assertNotNull(expression.leftBracket);
    JUnitTestCase.assertNotNull(expression.index);
    JUnitTestCase.assertNotNull(expression.rightBracket);
  }
  void test_parseAssignableExpression_super_dot() {
    PropertyAccess propertyAccess = ParserTestCase.parse("parseAssignableExpression", <Object> [false], "super.y");
    EngineTestCase.assertInstanceOf(SuperExpression, propertyAccess.target);
    JUnitTestCase.assertNotNull(propertyAccess.operator);
    JUnitTestCase.assertNotNull(propertyAccess.propertyName);
  }
  void test_parseAssignableExpression_super_index() {
    IndexExpression expression = ParserTestCase.parse("parseAssignableExpression", <Object> [false], "super[y]");
    EngineTestCase.assertInstanceOf(SuperExpression, expression.array);
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
    SimpleIdentifier selector = ParserTestCase.parse("parseAssignableSelector", <Object> [new SimpleIdentifier.full(null), true], ";");
    JUnitTestCase.assertNotNull(selector);
  }
  void test_parseBitwiseAndExpression_normal() {
    BinaryExpression expression = ParserTestCase.parse5("parseBitwiseAndExpression", "x & y", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.AMPERSAND, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }
  void test_parseBitwiseAndExpression_super() {
    BinaryExpression expression = ParserTestCase.parse5("parseBitwiseAndExpression", "super & y", []);
    EngineTestCase.assertInstanceOf(SuperExpression, expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.AMPERSAND, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }
  void test_parseBitwiseOrExpression_normal() {
    BinaryExpression expression = ParserTestCase.parse5("parseBitwiseOrExpression", "x | y", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.BAR, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }
  void test_parseBitwiseOrExpression_super() {
    BinaryExpression expression = ParserTestCase.parse5("parseBitwiseOrExpression", "super | y", []);
    EngineTestCase.assertInstanceOf(SuperExpression, expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.BAR, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }
  void test_parseBitwiseXorExpression_normal() {
    BinaryExpression expression = ParserTestCase.parse5("parseBitwiseXorExpression", "x ^ y", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.CARET, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }
  void test_parseBitwiseXorExpression_super() {
    BinaryExpression expression = ParserTestCase.parse5("parseBitwiseXorExpression", "super ^ y", []);
    EngineTestCase.assertInstanceOf(SuperExpression, expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.CARET, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }
  void test_parseBlock_empty() {
    Block block = ParserTestCase.parse5("parseBlock", "{}", []);
    JUnitTestCase.assertNotNull(block.leftBracket);
    EngineTestCase.assertSize(0, block.statements);
    JUnitTestCase.assertNotNull(block.rightBracket);
  }
  void test_parseBlock_nonEmpty() {
    Block block = ParserTestCase.parse5("parseBlock", "{;}", []);
    JUnitTestCase.assertNotNull(block.leftBracket);
    EngineTestCase.assertSize(1, block.statements);
    JUnitTestCase.assertNotNull(block.rightBracket);
  }
  void test_parseBreakStatement_label() {
    BreakStatement statement = ParserTestCase.parse5("parseBreakStatement", "break foo;", []);
    JUnitTestCase.assertNotNull(statement.keyword);
    JUnitTestCase.assertNotNull(statement.label);
    JUnitTestCase.assertNotNull(statement.semicolon);
  }
  void test_parseBreakStatement_noLabel() {
    BreakStatement statement = ParserTestCase.parse5("parseBreakStatement", "break;", [ParserErrorCode.BREAK_OUTSIDE_OF_LOOP]);
    JUnitTestCase.assertNotNull(statement.keyword);
    JUnitTestCase.assertNull(statement.label);
    JUnitTestCase.assertNotNull(statement.semicolon);
  }
  void test_parseCascadeSection_i() {
    IndexExpression section = ParserTestCase.parse5("parseCascadeSection", "..[i]", []);
    JUnitTestCase.assertNull(section.array);
    JUnitTestCase.assertNotNull(section.leftBracket);
    JUnitTestCase.assertNotNull(section.index);
    JUnitTestCase.assertNotNull(section.rightBracket);
  }
  void test_parseCascadeSection_ia() {
    FunctionExpressionInvocation section = ParserTestCase.parse5("parseCascadeSection", "..[i](b)", []);
    EngineTestCase.assertInstanceOf(IndexExpression, section.function);
    JUnitTestCase.assertNotNull(section.argumentList);
  }
  void test_parseCascadeSection_p() {
    PropertyAccess section = ParserTestCase.parse5("parseCascadeSection", "..a", []);
    JUnitTestCase.assertNull(section.target);
    JUnitTestCase.assertNotNull(section.operator);
    JUnitTestCase.assertNotNull(section.propertyName);
  }
  void test_parseCascadeSection_p_assign() {
    AssignmentExpression section = ParserTestCase.parse5("parseCascadeSection", "..a = 3", []);
    JUnitTestCase.assertNotNull(section.leftHandSide);
    JUnitTestCase.assertNotNull(section.operator);
    Expression rhs = section.rightHandSide;
    JUnitTestCase.assertNotNull(rhs);
  }
  void test_parseCascadeSection_p_assign_withCascade() {
    AssignmentExpression section = ParserTestCase.parse5("parseCascadeSection", "..a = 3..m()", []);
    JUnitTestCase.assertNotNull(section.leftHandSide);
    JUnitTestCase.assertNotNull(section.operator);
    Expression rhs = section.rightHandSide;
    EngineTestCase.assertInstanceOf(IntegerLiteral, rhs);
  }
  void test_parseCascadeSection_p_builtIn() {
    PropertyAccess section = ParserTestCase.parse5("parseCascadeSection", "..as", []);
    JUnitTestCase.assertNull(section.target);
    JUnitTestCase.assertNotNull(section.operator);
    JUnitTestCase.assertNotNull(section.propertyName);
  }
  void test_parseCascadeSection_pa() {
    MethodInvocation section = ParserTestCase.parse5("parseCascadeSection", "..a(b)", []);
    JUnitTestCase.assertNull(section.target);
    JUnitTestCase.assertNotNull(section.period);
    JUnitTestCase.assertNotNull(section.methodName);
    JUnitTestCase.assertNotNull(section.argumentList);
    EngineTestCase.assertSize(1, section.argumentList.arguments);
  }
  void test_parseCascadeSection_paa() {
    FunctionExpressionInvocation section = ParserTestCase.parse5("parseCascadeSection", "..a(b)(c)", []);
    EngineTestCase.assertInstanceOf(MethodInvocation, section.function);
    JUnitTestCase.assertNotNull(section.argumentList);
    EngineTestCase.assertSize(1, section.argumentList.arguments);
  }
  void test_parseCascadeSection_paapaa() {
    FunctionExpressionInvocation section = ParserTestCase.parse5("parseCascadeSection", "..a(b)(c).d(e)(f)", []);
    EngineTestCase.assertInstanceOf(FunctionExpressionInvocation, section.function);
    JUnitTestCase.assertNotNull(section.argumentList);
    EngineTestCase.assertSize(1, section.argumentList.arguments);
  }
  void test_parseCascadeSection_pap() {
    PropertyAccess section = ParserTestCase.parse5("parseCascadeSection", "..a(b).c", []);
    JUnitTestCase.assertNotNull(section.target);
    JUnitTestCase.assertNotNull(section.operator);
    JUnitTestCase.assertNotNull(section.propertyName);
  }
  void test_parseClassDeclaration_abstract() {
    ClassDeclaration declaration = ParserTestCase.parse("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), TokenFactory.token(Keyword.ABSTRACT)], "class A {}");
    JUnitTestCase.assertNull(declaration.documentationComment);
    JUnitTestCase.assertNotNull(declaration.abstractKeyword);
    JUnitTestCase.assertNull(declaration.extendsClause);
    JUnitTestCase.assertNull(declaration.implementsClause);
    JUnitTestCase.assertNotNull(declaration.classKeyword);
    JUnitTestCase.assertNotNull(declaration.leftBracket);
    JUnitTestCase.assertNotNull(declaration.name);
    EngineTestCase.assertSize(0, declaration.members);
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
    EngineTestCase.assertSize(0, declaration.members);
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
    EngineTestCase.assertSize(0, declaration.members);
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
    EngineTestCase.assertSize(0, declaration.members);
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
    EngineTestCase.assertSize(0, declaration.members);
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
    EngineTestCase.assertSize(0, declaration.members);
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
    EngineTestCase.assertSize(0, declaration.members);
    JUnitTestCase.assertNotNull(declaration.rightBracket);
    JUnitTestCase.assertNull(declaration.typeParameters);
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
    EngineTestCase.assertSize(1, declaration.members);
    JUnitTestCase.assertNotNull(declaration.rightBracket);
    JUnitTestCase.assertNull(declaration.typeParameters);
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
    EngineTestCase.assertSize(0, declaration.members);
    JUnitTestCase.assertNotNull(declaration.rightBracket);
    JUnitTestCase.assertNotNull(declaration.typeParameters);
    EngineTestCase.assertSize(1, declaration.typeParameters.typeParameters);
  }
  void test_parseClassMember_constructor_withInitializers() {
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
    EngineTestCase.assertSize(1, constructor.initializers);
  }
  void test_parseClassMember_field_instance_prefixedType() {
    FieldDeclaration field = ParserTestCase.parse("parseClassMember", <Object> ["C"], "p.A f;");
    JUnitTestCase.assertNull(field.documentationComment);
    EngineTestCase.assertSize(0, field.metadata);
    JUnitTestCase.assertNull(field.keyword);
    VariableDeclarationList list = field.fields;
    JUnitTestCase.assertNotNull(list);
    NodeList<VariableDeclaration> variables5 = list.variables;
    EngineTestCase.assertSize(1, variables5);
    VariableDeclaration variable = variables5[0];
    JUnitTestCase.assertNotNull(variable.name);
  }
  void test_parseClassMember_field_namedGet() {
    FieldDeclaration field = ParserTestCase.parse("parseClassMember", <Object> ["C"], "var get;");
    JUnitTestCase.assertNull(field.documentationComment);
    EngineTestCase.assertSize(0, field.metadata);
    JUnitTestCase.assertNull(field.keyword);
    VariableDeclarationList list = field.fields;
    JUnitTestCase.assertNotNull(list);
    NodeList<VariableDeclaration> variables6 = list.variables;
    EngineTestCase.assertSize(1, variables6);
    VariableDeclaration variable = variables6[0];
    JUnitTestCase.assertNotNull(variable.name);
  }
  void test_parseClassMember_field_namedOperator() {
    FieldDeclaration field = ParserTestCase.parse("parseClassMember", <Object> ["C"], "var operator;");
    JUnitTestCase.assertNull(field.documentationComment);
    EngineTestCase.assertSize(0, field.metadata);
    JUnitTestCase.assertNull(field.keyword);
    VariableDeclarationList list = field.fields;
    JUnitTestCase.assertNotNull(list);
    NodeList<VariableDeclaration> variables7 = list.variables;
    EngineTestCase.assertSize(1, variables7);
    VariableDeclaration variable = variables7[0];
    JUnitTestCase.assertNotNull(variable.name);
  }
  void test_parseClassMember_field_namedSet() {
    FieldDeclaration field = ParserTestCase.parse("parseClassMember", <Object> ["C"], "var set;");
    JUnitTestCase.assertNull(field.documentationComment);
    EngineTestCase.assertSize(0, field.metadata);
    JUnitTestCase.assertNull(field.keyword);
    VariableDeclarationList list = field.fields;
    JUnitTestCase.assertNotNull(list);
    NodeList<VariableDeclaration> variables8 = list.variables;
    EngineTestCase.assertSize(1, variables8);
    VariableDeclaration variable = variables8[0];
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
    EngineTestCase.assertSize(0, constructor.initializers);
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
    EngineTestCase.assertSize(0, constructor.initializers);
    JUnitTestCase.assertNotNull(constructor.redirectedConstructor);
    JUnitTestCase.assertNotNull(constructor.body);
  }
  void test_parseClassTypeAlias() {
    Token token5 = TokenFactory.token(Keyword.TYPEDEF);
    ClassTypeAlias classTypeAlias = ParserTestCase.parse("parseClassTypeAlias", <Object> [emptyCommentAndMetadata(), token5], "A = B;");
    JUnitTestCase.assertNotNull(classTypeAlias.keyword);
    JUnitTestCase.assertEquals("A", classTypeAlias.name.name);
    JUnitTestCase.assertNotNull(classTypeAlias.equals);
    JUnitTestCase.assertNull(classTypeAlias.abstractKeyword);
    JUnitTestCase.assertNotNullMsg("B", classTypeAlias.superclass.name.name);
    JUnitTestCase.assertNull(classTypeAlias.withClause);
    JUnitTestCase.assertNull(classTypeAlias.implementsClause);
    JUnitTestCase.assertNotNull(classTypeAlias.semicolon);
  }
  void test_parseClassTypeAlias_abstract() {
    Token token6 = TokenFactory.token(Keyword.TYPEDEF);
    ClassTypeAlias classTypeAlias = ParserTestCase.parse("parseClassTypeAlias", <Object> [emptyCommentAndMetadata(), token6], "A = abstract B;");
    JUnitTestCase.assertNotNull(classTypeAlias.keyword);
    JUnitTestCase.assertEquals("A", classTypeAlias.name.name);
    JUnitTestCase.assertNotNull(classTypeAlias.equals);
    JUnitTestCase.assertNotNull(classTypeAlias.abstractKeyword);
    JUnitTestCase.assertNotNullMsg("B", classTypeAlias.superclass.name.name);
    JUnitTestCase.assertNull(classTypeAlias.withClause);
    JUnitTestCase.assertNull(classTypeAlias.implementsClause);
    JUnitTestCase.assertNotNull(classTypeAlias.semicolon);
  }
  void test_parseClassTypeAlias_implements() {
    Token token7 = TokenFactory.token(Keyword.TYPEDEF);
    ClassTypeAlias classTypeAlias = ParserTestCase.parse("parseClassTypeAlias", <Object> [emptyCommentAndMetadata(), token7], "A = B implements C;");
    JUnitTestCase.assertNotNull(classTypeAlias.keyword);
    JUnitTestCase.assertEquals("A", classTypeAlias.name.name);
    JUnitTestCase.assertNotNull(classTypeAlias.equals);
    JUnitTestCase.assertNull(classTypeAlias.abstractKeyword);
    JUnitTestCase.assertNotNullMsg("B", classTypeAlias.superclass.name.name);
    JUnitTestCase.assertNull(classTypeAlias.withClause);
    JUnitTestCase.assertNotNull(classTypeAlias.implementsClause);
    JUnitTestCase.assertNotNull(classTypeAlias.semicolon);
  }
  void test_parseClassTypeAlias_with() {
    Token token8 = TokenFactory.token(Keyword.TYPEDEF);
    ClassTypeAlias classTypeAlias = ParserTestCase.parse("parseClassTypeAlias", <Object> [emptyCommentAndMetadata(), token8], "A = B with C;");
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
    Token token9 = TokenFactory.token(Keyword.TYPEDEF);
    ClassTypeAlias classTypeAlias = ParserTestCase.parse("parseClassTypeAlias", <Object> [emptyCommentAndMetadata(), token9], "A = B with C implements D;");
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
    List<Combinator> combinators = ParserTestCase.parse5("parseCombinators", "hide a;", []);
    EngineTestCase.assertSize(1, combinators);
    HideCombinator combinator = combinators[0] as HideCombinator;
    JUnitTestCase.assertNotNull(combinator);
    JUnitTestCase.assertNotNull(combinator.keyword);
    EngineTestCase.assertSize(1, combinator.hiddenNames);
  }
  void test_parseCombinators_hs() {
    List<Combinator> combinators = ParserTestCase.parse5("parseCombinators", "hide a show b;", []);
    EngineTestCase.assertSize(2, combinators);
    HideCombinator hideCombinator = combinators[0] as HideCombinator;
    JUnitTestCase.assertNotNull(hideCombinator);
    JUnitTestCase.assertNotNull(hideCombinator.keyword);
    EngineTestCase.assertSize(1, hideCombinator.hiddenNames);
    ShowCombinator showCombinator = combinators[1] as ShowCombinator;
    JUnitTestCase.assertNotNull(showCombinator);
    JUnitTestCase.assertNotNull(showCombinator.keyword);
    EngineTestCase.assertSize(1, showCombinator.shownNames);
  }
  void test_parseCombinators_hshs() {
    List<Combinator> combinators = ParserTestCase.parse5("parseCombinators", "hide a show b hide c show d;", []);
    EngineTestCase.assertSize(4, combinators);
  }
  void test_parseCombinators_s() {
    List<Combinator> combinators = ParserTestCase.parse5("parseCombinators", "show a;", []);
    EngineTestCase.assertSize(1, combinators);
    ShowCombinator combinator = combinators[0] as ShowCombinator;
    JUnitTestCase.assertNotNull(combinator);
    JUnitTestCase.assertNotNull(combinator.keyword);
    EngineTestCase.assertSize(1, combinator.shownNames);
  }
  void test_parseCommentAndMetadata_c() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse5("parseCommentAndMetadata", "/** 1 */ void", []);
    JUnitTestCase.assertNotNull(commentAndMetadata.comment);
    EngineTestCase.assertSize(0, commentAndMetadata.metadata);
  }
  void test_parseCommentAndMetadata_cmc() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse5("parseCommentAndMetadata", "/** 1 */ @A /** 2 */ void", []);
    JUnitTestCase.assertNotNull(commentAndMetadata.comment);
    EngineTestCase.assertSize(1, commentAndMetadata.metadata);
  }
  void test_parseCommentAndMetadata_cmcm() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse5("parseCommentAndMetadata", "/** 1 */ @A /** 2 */ @B void", []);
    JUnitTestCase.assertNotNull(commentAndMetadata.comment);
    EngineTestCase.assertSize(2, commentAndMetadata.metadata);
  }
  void test_parseCommentAndMetadata_cmm() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse5("parseCommentAndMetadata", "/** 1 */ @A @B void", []);
    JUnitTestCase.assertNotNull(commentAndMetadata.comment);
    EngineTestCase.assertSize(2, commentAndMetadata.metadata);
  }
  void test_parseCommentAndMetadata_m() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse5("parseCommentAndMetadata", "@A void", []);
    JUnitTestCase.assertNull(commentAndMetadata.comment);
    EngineTestCase.assertSize(1, commentAndMetadata.metadata);
  }
  void test_parseCommentAndMetadata_mcm() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse5("parseCommentAndMetadata", "@A /** 1 */ @B void", []);
    JUnitTestCase.assertNotNull(commentAndMetadata.comment);
    EngineTestCase.assertSize(2, commentAndMetadata.metadata);
  }
  void test_parseCommentAndMetadata_mcmc() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse5("parseCommentAndMetadata", "@A /** 1 */ @B /** 2 */ void", []);
    JUnitTestCase.assertNotNull(commentAndMetadata.comment);
    EngineTestCase.assertSize(2, commentAndMetadata.metadata);
  }
  void test_parseCommentAndMetadata_mm() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse5("parseCommentAndMetadata", "@A @B(x) void", []);
    JUnitTestCase.assertNull(commentAndMetadata.comment);
    EngineTestCase.assertSize(2, commentAndMetadata.metadata);
  }
  void test_parseCommentAndMetadata_none() {
    CommentAndMetadata commentAndMetadata = ParserTestCase.parse5("parseCommentAndMetadata", "void", []);
    JUnitTestCase.assertNull(commentAndMetadata.comment);
    EngineTestCase.assertSize(0, commentAndMetadata.metadata);
  }
  void test_parseCommentReference_new_prefixed() {
    CommentReference reference = ParserTestCase.parse("parseCommentReference", <Object> ["new a.b", 7], "");
    PrefixedIdentifier prefixedIdentifier = EngineTestCase.assertInstanceOf(PrefixedIdentifier, reference.identifier);
    SimpleIdentifier prefix10 = prefixedIdentifier.prefix;
    JUnitTestCase.assertNotNull(prefix10.token);
    JUnitTestCase.assertEquals("a", prefix10.name);
    JUnitTestCase.assertEquals(11, prefix10.offset);
    JUnitTestCase.assertNotNull(prefixedIdentifier.period);
    SimpleIdentifier identifier22 = prefixedIdentifier.identifier;
    JUnitTestCase.assertNotNull(identifier22.token);
    JUnitTestCase.assertEquals("b", identifier22.name);
    JUnitTestCase.assertEquals(13, identifier22.offset);
  }
  void test_parseCommentReference_new_simple() {
    CommentReference reference = ParserTestCase.parse("parseCommentReference", <Object> ["new a", 5], "");
    SimpleIdentifier identifier23 = EngineTestCase.assertInstanceOf(SimpleIdentifier, reference.identifier);
    JUnitTestCase.assertNotNull(identifier23.token);
    JUnitTestCase.assertEquals("a", identifier23.name);
    JUnitTestCase.assertEquals(9, identifier23.offset);
  }
  void test_parseCommentReference_prefixed() {
    CommentReference reference = ParserTestCase.parse("parseCommentReference", <Object> ["a.b", 7], "");
    PrefixedIdentifier prefixedIdentifier = EngineTestCase.assertInstanceOf(PrefixedIdentifier, reference.identifier);
    SimpleIdentifier prefix11 = prefixedIdentifier.prefix;
    JUnitTestCase.assertNotNull(prefix11.token);
    JUnitTestCase.assertEquals("a", prefix11.name);
    JUnitTestCase.assertEquals(7, prefix11.offset);
    JUnitTestCase.assertNotNull(prefixedIdentifier.period);
    SimpleIdentifier identifier24 = prefixedIdentifier.identifier;
    JUnitTestCase.assertNotNull(identifier24.token);
    JUnitTestCase.assertEquals("b", identifier24.name);
    JUnitTestCase.assertEquals(9, identifier24.offset);
  }
  void test_parseCommentReference_simple() {
    CommentReference reference = ParserTestCase.parse("parseCommentReference", <Object> ["a", 5], "");
    SimpleIdentifier identifier25 = EngineTestCase.assertInstanceOf(SimpleIdentifier, reference.identifier);
    JUnitTestCase.assertNotNull(identifier25.token);
    JUnitTestCase.assertEquals("a", identifier25.name);
    JUnitTestCase.assertEquals(5, identifier25.offset);
  }
  void test_parseCommentReferences_multiLine() {
    List<Token> tokens = <Token> [new StringToken(TokenType.MULTI_LINE_COMMENT, "/** xxx [a] yyy [b] zzz */", 3)];
    List<CommentReference> references = ParserTestCase.parse("parseCommentReferences", <Object> [tokens], "");
    EngineTestCase.assertSize(2, references);
    CommentReference reference = references[0];
    JUnitTestCase.assertNotNull(reference);
    JUnitTestCase.assertNotNull(reference.identifier);
    JUnitTestCase.assertEquals(12, reference.offset);
    reference = references[1];
    JUnitTestCase.assertNotNull(reference);
    JUnitTestCase.assertNotNull(reference.identifier);
    JUnitTestCase.assertEquals(20, reference.offset);
  }
  void test_parseCommentReferences_singleLine() {
    List<Token> tokens = <Token> [new StringToken(TokenType.SINGLE_LINE_COMMENT, "/// xxx [a] yyy [b] zzz", 3), new StringToken(TokenType.SINGLE_LINE_COMMENT, "/// x [c]", 28)];
    List<CommentReference> references = ParserTestCase.parse("parseCommentReferences", <Object> [tokens], "");
    EngineTestCase.assertSize(3, references);
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
  void test_parseCompilationUnit_abstractAsPrefix_parameterized() {
    CompilationUnit unit = ParserTestCase.parse5("parseCompilationUnit", "abstract<dynamic> _abstract = new abstract.A();", []);
    JUnitTestCase.assertNull(unit.scriptTag);
    EngineTestCase.assertSize(0, unit.directives);
    EngineTestCase.assertSize(1, unit.declarations);
  }
  void test_parseCompilationUnit_directives_multiple() {
    CompilationUnit unit = ParserTestCase.parse5("parseCompilationUnit", "library l;\npart 'a.dart';", []);
    JUnitTestCase.assertNull(unit.scriptTag);
    EngineTestCase.assertSize(2, unit.directives);
    EngineTestCase.assertSize(0, unit.declarations);
  }
  void test_parseCompilationUnit_directives_single() {
    CompilationUnit unit = ParserTestCase.parse5("parseCompilationUnit", "library l;", []);
    JUnitTestCase.assertNull(unit.scriptTag);
    EngineTestCase.assertSize(1, unit.directives);
    EngineTestCase.assertSize(0, unit.declarations);
  }
  void test_parseCompilationUnit_empty() {
    CompilationUnit unit = ParserTestCase.parse5("parseCompilationUnit", "", []);
    JUnitTestCase.assertNull(unit.scriptTag);
    EngineTestCase.assertSize(0, unit.directives);
    EngineTestCase.assertSize(0, unit.declarations);
  }
  void test_parseCompilationUnit_exportAsPrefix() {
    CompilationUnit unit = ParserTestCase.parse5("parseCompilationUnit", "export.A _export = new export.A();", []);
    JUnitTestCase.assertNull(unit.scriptTag);
    EngineTestCase.assertSize(0, unit.directives);
    EngineTestCase.assertSize(1, unit.declarations);
  }
  void test_parseCompilationUnit_exportAsPrefix_parameterized() {
    CompilationUnit unit = ParserTestCase.parse5("parseCompilationUnit", "export<dynamic> _export = new export.A();", []);
    JUnitTestCase.assertNull(unit.scriptTag);
    EngineTestCase.assertSize(0, unit.directives);
    EngineTestCase.assertSize(1, unit.declarations);
  }
  void test_parseCompilationUnit_operatorAsPrefix_parameterized() {
    CompilationUnit unit = ParserTestCase.parse5("parseCompilationUnit", "operator<dynamic> _operator = new operator.A();", []);
    JUnitTestCase.assertNull(unit.scriptTag);
    EngineTestCase.assertSize(0, unit.directives);
    EngineTestCase.assertSize(1, unit.declarations);
  }
  void test_parseCompilationUnit_script() {
    CompilationUnit unit = ParserTestCase.parse5("parseCompilationUnit", "#! /bin/dart", []);
    JUnitTestCase.assertNotNull(unit.scriptTag);
    EngineTestCase.assertSize(0, unit.directives);
    EngineTestCase.assertSize(0, unit.declarations);
  }
  void test_parseCompilationUnit_topLevelDeclaration() {
    CompilationUnit unit = ParserTestCase.parse5("parseCompilationUnit", "class A {}", []);
    JUnitTestCase.assertNull(unit.scriptTag);
    EngineTestCase.assertSize(0, unit.directives);
    EngineTestCase.assertSize(1, unit.declarations);
  }
  void test_parseCompilationUnit_typedefAsPrefix() {
    CompilationUnit unit = ParserTestCase.parse5("parseCompilationUnit", "typedef.A _typedef = new typedef.A();", []);
    JUnitTestCase.assertNull(unit.scriptTag);
    EngineTestCase.assertSize(0, unit.directives);
    EngineTestCase.assertSize(1, unit.declarations);
  }
  void test_parseCompilationUnitMember_abstractAsPrefix() {
    TopLevelVariableDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "abstract.A _abstract = new abstract.A();");
    JUnitTestCase.assertNotNull(declaration.semicolon);
    JUnitTestCase.assertNotNull(declaration.variables);
  }
  void test_parseCompilationUnitMember_class() {
    ClassDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "class A {}");
    JUnitTestCase.assertEquals("A", declaration.name.name);
    EngineTestCase.assertSize(0, declaration.members);
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
  }
  void test_parseCompilationUnitMember_typedef_class_abstract() {
    ClassTypeAlias typeAlias = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "typedef C = abstract S with M;");
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
  void test_parseCompilationUnitMember_typedef_class_generic() {
    ClassTypeAlias typeAlias = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "typedef C<E> = S<E> with M<E> implements I<E>;");
    JUnitTestCase.assertNotNull(typeAlias.keyword);
    JUnitTestCase.assertEquals("C", typeAlias.name.name);
    EngineTestCase.assertSize(1, typeAlias.typeParameters.typeParameters);
    JUnitTestCase.assertNotNull(typeAlias.equals);
    JUnitTestCase.assertNull(typeAlias.abstractKeyword);
    JUnitTestCase.assertEquals("S", typeAlias.superclass.name.name);
    JUnitTestCase.assertNotNull(typeAlias.withClause);
    JUnitTestCase.assertNotNull(typeAlias.implementsClause);
    JUnitTestCase.assertNotNull(typeAlias.semicolon);
  }
  void test_parseCompilationUnitMember_typedef_class_implements() {
    ClassTypeAlias typeAlias = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "typedef C = S with M implements I;");
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
  void test_parseCompilationUnitMember_typedef_class_noImplements() {
    ClassTypeAlias typeAlias = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "typedef C = S with M;");
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
  void test_parseCompilationUnitMember_typedef_function() {
    FunctionTypeAlias typeAlias = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "typedef F();");
    JUnitTestCase.assertEquals("F", typeAlias.name.name);
    EngineTestCase.assertSize(0, typeAlias.parameters.parameters);
  }
  void test_parseCompilationUnitMember_variable() {
    TopLevelVariableDeclaration declaration = ParserTestCase.parse("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "var x = 0;");
    JUnitTestCase.assertNotNull(declaration.semicolon);
    JUnitTestCase.assertNotNull(declaration.variables);
  }
  void test_parseConditionalExpression() {
    ConditionalExpression expression = ParserTestCase.parse5("parseConditionalExpression", "x ? y : z", []);
    JUnitTestCase.assertNotNull(expression.condition);
    JUnitTestCase.assertNotNull(expression.question);
    JUnitTestCase.assertNotNull(expression.thenExpression);
    JUnitTestCase.assertNotNull(expression.colon);
    JUnitTestCase.assertNotNull(expression.elseExpression);
  }
  void test_parseConstExpression_instanceCreation() {
    InstanceCreationExpression expression = ParserTestCase.parse5("parseConstExpression", "const A()", []);
    JUnitTestCase.assertNotNull(expression.keyword);
    ConstructorName name = expression.constructorName;
    JUnitTestCase.assertNotNull(name);
    JUnitTestCase.assertNotNull(name.type);
    JUnitTestCase.assertNull(name.period);
    JUnitTestCase.assertNull(name.name);
    JUnitTestCase.assertNotNull(expression.argumentList);
  }
  void test_parseConstExpression_listLiteral_typed() {
    ListLiteral literal = ParserTestCase.parse5("parseConstExpression", "const <A> []", []);
    JUnitTestCase.assertNotNull(literal.modifier);
    JUnitTestCase.assertNotNull(literal.typeArguments);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSize(0, literal.elements);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }
  void test_parseConstExpression_listLiteral_untyped() {
    ListLiteral literal = ParserTestCase.parse5("parseConstExpression", "const []", []);
    JUnitTestCase.assertNotNull(literal.modifier);
    JUnitTestCase.assertNull(literal.typeArguments);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSize(0, literal.elements);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }
  void test_parseConstExpression_mapLiteral_typed() {
    MapLiteral literal = ParserTestCase.parse5("parseConstExpression", "const <A> {}", []);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSize(0, literal.entries);
    JUnitTestCase.assertNotNull(literal.rightBracket);
    JUnitTestCase.assertNotNull(literal.typeArguments);
  }
  void test_parseConstExpression_mapLiteral_untyped() {
    MapLiteral literal = ParserTestCase.parse5("parseConstExpression", "const {}", []);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSize(0, literal.entries);
    JUnitTestCase.assertNotNull(literal.rightBracket);
    JUnitTestCase.assertNull(literal.typeArguments);
  }
  void test_parseConstructor() {
  }
  void test_parseConstructorFieldInitializer_qualified() {
    ConstructorFieldInitializer invocation = ParserTestCase.parse5("parseConstructorFieldInitializer", "this.a = b", []);
    JUnitTestCase.assertNotNull(invocation.equals);
    JUnitTestCase.assertNotNull(invocation.expression);
    JUnitTestCase.assertNotNull(invocation.fieldName);
    JUnitTestCase.assertNotNull(invocation.keyword);
    JUnitTestCase.assertNotNull(invocation.period);
  }
  void test_parseConstructorFieldInitializer_unqualified() {
    ConstructorFieldInitializer invocation = ParserTestCase.parse5("parseConstructorFieldInitializer", "a = b", []);
    JUnitTestCase.assertNotNull(invocation.equals);
    JUnitTestCase.assertNotNull(invocation.expression);
    JUnitTestCase.assertNotNull(invocation.fieldName);
    JUnitTestCase.assertNull(invocation.keyword);
    JUnitTestCase.assertNull(invocation.period);
  }
  void test_parseConstructorName_named_noPrefix() {
    ConstructorName name = ParserTestCase.parse5("parseConstructorName", "A.n;", []);
    JUnitTestCase.assertNotNull(name.type);
    JUnitTestCase.assertNull(name.period);
    JUnitTestCase.assertNull(name.name);
  }
  void test_parseConstructorName_named_prefixed() {
    ConstructorName name = ParserTestCase.parse5("parseConstructorName", "p.A.n;", []);
    JUnitTestCase.assertNotNull(name.type);
    JUnitTestCase.assertNotNull(name.period);
    JUnitTestCase.assertNotNull(name.name);
  }
  void test_parseConstructorName_unnamed_noPrefix() {
    ConstructorName name = ParserTestCase.parse5("parseConstructorName", "A;", []);
    JUnitTestCase.assertNotNull(name.type);
    JUnitTestCase.assertNull(name.period);
    JUnitTestCase.assertNull(name.name);
  }
  void test_parseConstructorName_unnamed_prefixed() {
    ConstructorName name = ParserTestCase.parse5("parseConstructorName", "p.A;", []);
    JUnitTestCase.assertNotNull(name.type);
    JUnitTestCase.assertNull(name.period);
    JUnitTestCase.assertNull(name.name);
  }
  void test_parseContinueStatement_label() {
    ContinueStatement statement = ParserTestCase.parse5("parseContinueStatement", "continue foo;", [ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP]);
    JUnitTestCase.assertNotNull(statement.keyword);
    JUnitTestCase.assertNotNull(statement.label);
    JUnitTestCase.assertNotNull(statement.semicolon);
  }
  void test_parseContinueStatement_noLabel() {
    ContinueStatement statement = ParserTestCase.parse5("parseContinueStatement", "continue;", [ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP]);
    JUnitTestCase.assertNotNull(statement.keyword);
    JUnitTestCase.assertNull(statement.label);
    JUnitTestCase.assertNotNull(statement.semicolon);
  }
  void test_parseDirective_export() {
    ExportDirective directive = ParserTestCase.parse("parseDirective", <Object> [emptyCommentAndMetadata()], "export 'lib/lib.dart';");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    EngineTestCase.assertSize(0, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }
  void test_parseDirective_import() {
    ImportDirective directive = ParserTestCase.parse("parseDirective", <Object> [emptyCommentAndMetadata()], "import 'lib/lib.dart';");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    JUnitTestCase.assertNull(directive.asToken);
    JUnitTestCase.assertNull(directive.prefix);
    EngineTestCase.assertSize(0, directive.combinators);
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
  void test_parseDocumentationComment_block() {
    Comment comment = ParserTestCase.parse5("parseDocumentationComment", "/** */ class", []);
    JUnitTestCase.assertFalse(comment.isBlock());
    JUnitTestCase.assertTrue(comment.isDocumentation());
    JUnitTestCase.assertFalse(comment.isEndOfLine());
  }
  void test_parseDocumentationComment_block_withReference() {
    Comment comment = ParserTestCase.parse5("parseDocumentationComment", "/** [a] */ class", []);
    JUnitTestCase.assertFalse(comment.isBlock());
    JUnitTestCase.assertTrue(comment.isDocumentation());
    JUnitTestCase.assertFalse(comment.isEndOfLine());
    NodeList<CommentReference> references2 = comment.references;
    EngineTestCase.assertSize(1, references2);
    CommentReference reference = references2[0];
    JUnitTestCase.assertNotNull(reference);
    JUnitTestCase.assertEquals(5, reference.offset);
  }
  void test_parseDocumentationComment_endOfLine() {
    Comment comment = ParserTestCase.parse5("parseDocumentationComment", "/// \n/// \n class", []);
    JUnitTestCase.assertFalse(comment.isBlock());
    JUnitTestCase.assertTrue(comment.isDocumentation());
    JUnitTestCase.assertFalse(comment.isEndOfLine());
  }
  void test_parseDoStatement() {
    DoStatement statement = ParserTestCase.parse5("parseDoStatement", "do {} while (x);", []);
    JUnitTestCase.assertNotNull(statement.doKeyword);
    JUnitTestCase.assertNotNull(statement.body);
    JUnitTestCase.assertNotNull(statement.whileKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.semicolon);
  }
  void test_parseEmptyStatement() {
    EmptyStatement statement = ParserTestCase.parse5("parseEmptyStatement", ";", []);
    JUnitTestCase.assertNotNull(statement.semicolon);
  }
  void test_parseEqualityExpression_normal() {
    BinaryExpression expression = ParserTestCase.parse5("parseEqualityExpression", "x == y", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.EQ_EQ, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }
  void test_parseEqualityExpression_super() {
    BinaryExpression expression = ParserTestCase.parse5("parseEqualityExpression", "super == y", []);
    EngineTestCase.assertInstanceOf(SuperExpression, expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.EQ_EQ, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }
  void test_parseExportDirective_hide() {
    ExportDirective directive = ParserTestCase.parse("parseExportDirective", <Object> [emptyCommentAndMetadata()], "export 'lib/lib.dart' hide A, B;");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    EngineTestCase.assertSize(1, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }
  void test_parseExportDirective_hide_show() {
    ExportDirective directive = ParserTestCase.parse("parseExportDirective", <Object> [emptyCommentAndMetadata()], "export 'lib/lib.dart' hide A show B;");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    EngineTestCase.assertSize(2, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }
  void test_parseExportDirective_noCombinator() {
    ExportDirective directive = ParserTestCase.parse("parseExportDirective", <Object> [emptyCommentAndMetadata()], "export 'lib/lib.dart';");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    EngineTestCase.assertSize(0, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }
  void test_parseExportDirective_show() {
    ExportDirective directive = ParserTestCase.parse("parseExportDirective", <Object> [emptyCommentAndMetadata()], "export 'lib/lib.dart' show A, B;");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    EngineTestCase.assertSize(1, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }
  void test_parseExportDirective_show_hide() {
    ExportDirective directive = ParserTestCase.parse("parseExportDirective", <Object> [emptyCommentAndMetadata()], "export 'lib/lib.dart' show B hide A;");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    EngineTestCase.assertSize(2, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }
  void test_parseExpression_assign() {
    AssignmentExpression expression = ParserTestCase.parse5("parseExpression", "x = y", []);
    JUnitTestCase.assertNotNull(expression.leftHandSide);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.EQ, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightHandSide);
  }
  void test_parseExpression_comparison() {
    BinaryExpression expression = ParserTestCase.parse5("parseExpression", "--a.b == c", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.EQ_EQ, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }
  void test_parseExpression_invokeFunctionExpression() {
    FunctionExpressionInvocation invocation = ParserTestCase.parse5("parseExpression", "(a) {return a + a;} (3)", []);
    EngineTestCase.assertInstanceOf(FunctionExpression, invocation.function);
    FunctionExpression expression = invocation.function as FunctionExpression;
    JUnitTestCase.assertNotNull(expression.parameters);
    JUnitTestCase.assertNotNull(expression.body);
    ArgumentList list = invocation.argumentList;
    JUnitTestCase.assertNotNull(list);
    EngineTestCase.assertSize(1, list.arguments);
  }
  void test_parseExpression_superMethodInvocation() {
    MethodInvocation invocation = ParserTestCase.parse5("parseExpression", "super.m()", []);
    JUnitTestCase.assertNotNull(invocation.target);
    JUnitTestCase.assertNotNull(invocation.methodName);
    JUnitTestCase.assertNotNull(invocation.argumentList);
  }
  void test_parseExpressionList_multiple() {
    List<Expression> result = ParserTestCase.parse5("parseExpressionList", "1, 2, 3", []);
    EngineTestCase.assertSize(3, result);
  }
  void test_parseExpressionList_single() {
    List<Expression> result = ParserTestCase.parse5("parseExpressionList", "1", []);
    EngineTestCase.assertSize(1, result);
  }
  void test_parseExpressionWithoutCascade_assign() {
    AssignmentExpression expression = ParserTestCase.parse5("parseExpressionWithoutCascade", "x = y", []);
    JUnitTestCase.assertNotNull(expression.leftHandSide);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.EQ, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightHandSide);
  }
  void test_parseExpressionWithoutCascade_comparison() {
    BinaryExpression expression = ParserTestCase.parse5("parseExpressionWithoutCascade", "--a.b == c", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.EQ_EQ, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }
  void test_parseExpressionWithoutCascade_superMethodInvocation() {
    MethodInvocation invocation = ParserTestCase.parse5("parseExpressionWithoutCascade", "super.m()", []);
    JUnitTestCase.assertNotNull(invocation.target);
    JUnitTestCase.assertNotNull(invocation.methodName);
    JUnitTestCase.assertNotNull(invocation.argumentList);
  }
  void test_parseExtendsClause() {
    ExtendsClause clause = ParserTestCase.parse5("parseExtendsClause", "extends B", []);
    JUnitTestCase.assertNotNull(clause.keyword);
    JUnitTestCase.assertNotNull(clause.superclass);
    EngineTestCase.assertInstanceOf(TypeName, clause.superclass);
  }
  void test_parseFinalConstVarOrType_const_noType() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "const");
    Token keyword32 = result.keyword;
    JUnitTestCase.assertNotNull(keyword32);
    JUnitTestCase.assertEquals(TokenType.KEYWORD, keyword32.type);
    JUnitTestCase.assertEquals(Keyword.CONST, ((keyword32 as KeywordToken)).keyword);
    JUnitTestCase.assertNull(result.type);
  }
  void test_parseFinalConstVarOrType_const_type() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "const A a");
    Token keyword33 = result.keyword;
    JUnitTestCase.assertNotNull(keyword33);
    JUnitTestCase.assertEquals(TokenType.KEYWORD, keyword33.type);
    JUnitTestCase.assertEquals(Keyword.CONST, ((keyword33 as KeywordToken)).keyword);
    JUnitTestCase.assertNotNull(result.type);
  }
  void test_parseFinalConstVarOrType_final_noType() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "final");
    Token keyword34 = result.keyword;
    JUnitTestCase.assertNotNull(keyword34);
    JUnitTestCase.assertEquals(TokenType.KEYWORD, keyword34.type);
    JUnitTestCase.assertEquals(Keyword.FINAL, ((keyword34 as KeywordToken)).keyword);
    JUnitTestCase.assertNull(result.type);
  }
  void test_parseFinalConstVarOrType_final_type() {
    FinalConstVarOrType result = ParserTestCase.parse("parseFinalConstVarOrType", <Object> [false], "final A a");
    Token keyword35 = result.keyword;
    JUnitTestCase.assertNotNull(keyword35);
    JUnitTestCase.assertEquals(TokenType.KEYWORD, keyword35.type);
    JUnitTestCase.assertEquals(Keyword.FINAL, ((keyword35 as KeywordToken)).keyword);
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
    Token keyword36 = result.keyword;
    JUnitTestCase.assertNotNull(keyword36);
    JUnitTestCase.assertEquals(TokenType.KEYWORD, keyword36.type);
    JUnitTestCase.assertEquals(Keyword.VAR, ((keyword36 as KeywordToken)).keyword);
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
    FormalParameterList parameterList = ParserTestCase.parse5("parseFormalParameterList", "()", []);
    JUnitTestCase.assertNotNull(parameterList.leftParenthesis);
    JUnitTestCase.assertNull(parameterList.leftDelimiter);
    EngineTestCase.assertSize(0, parameterList.parameters);
    JUnitTestCase.assertNull(parameterList.rightDelimiter);
    JUnitTestCase.assertNotNull(parameterList.rightParenthesis);
  }
  void test_parseFormalParameterList_named_multiple() {
    FormalParameterList parameterList = ParserTestCase.parse5("parseFormalParameterList", "({A a : 1, B b, C c : 3})", []);
    JUnitTestCase.assertNotNull(parameterList.leftParenthesis);
    JUnitTestCase.assertNotNull(parameterList.leftDelimiter);
    EngineTestCase.assertSize(3, parameterList.parameters);
    JUnitTestCase.assertNotNull(parameterList.rightDelimiter);
    JUnitTestCase.assertNotNull(parameterList.rightParenthesis);
  }
  void test_parseFormalParameterList_named_single() {
    FormalParameterList parameterList = ParserTestCase.parse5("parseFormalParameterList", "({A a})", []);
    JUnitTestCase.assertNotNull(parameterList.leftParenthesis);
    JUnitTestCase.assertNotNull(parameterList.leftDelimiter);
    EngineTestCase.assertSize(1, parameterList.parameters);
    JUnitTestCase.assertNotNull(parameterList.rightDelimiter);
    JUnitTestCase.assertNotNull(parameterList.rightParenthesis);
  }
  void test_parseFormalParameterList_normal_multiple() {
    FormalParameterList parameterList = ParserTestCase.parse5("parseFormalParameterList", "(A a, B b, C c)", []);
    JUnitTestCase.assertNotNull(parameterList.leftParenthesis);
    JUnitTestCase.assertNull(parameterList.leftDelimiter);
    EngineTestCase.assertSize(3, parameterList.parameters);
    JUnitTestCase.assertNull(parameterList.rightDelimiter);
    JUnitTestCase.assertNotNull(parameterList.rightParenthesis);
  }
  void test_parseFormalParameterList_normal_named() {
    FormalParameterList parameterList = ParserTestCase.parse5("parseFormalParameterList", "(A a, {B b})", []);
    JUnitTestCase.assertNotNull(parameterList.leftParenthesis);
    JUnitTestCase.assertNotNull(parameterList.leftDelimiter);
    EngineTestCase.assertSize(2, parameterList.parameters);
    JUnitTestCase.assertNotNull(parameterList.rightDelimiter);
    JUnitTestCase.assertNotNull(parameterList.rightParenthesis);
  }
  void test_parseFormalParameterList_normal_positional() {
    FormalParameterList parameterList = ParserTestCase.parse5("parseFormalParameterList", "(A a, [B b])", []);
    JUnitTestCase.assertNotNull(parameterList.leftParenthesis);
    JUnitTestCase.assertNotNull(parameterList.leftDelimiter);
    EngineTestCase.assertSize(2, parameterList.parameters);
    JUnitTestCase.assertNotNull(parameterList.rightDelimiter);
    JUnitTestCase.assertNotNull(parameterList.rightParenthesis);
  }
  void test_parseFormalParameterList_normal_single() {
    FormalParameterList parameterList = ParserTestCase.parse5("parseFormalParameterList", "(A a)", []);
    JUnitTestCase.assertNotNull(parameterList.leftParenthesis);
    JUnitTestCase.assertNull(parameterList.leftDelimiter);
    EngineTestCase.assertSize(1, parameterList.parameters);
    JUnitTestCase.assertNull(parameterList.rightDelimiter);
    JUnitTestCase.assertNotNull(parameterList.rightParenthesis);
  }
  void test_parseFormalParameterList_positional_multiple() {
    FormalParameterList parameterList = ParserTestCase.parse5("parseFormalParameterList", "([A a = null, B b, C c = null])", []);
    JUnitTestCase.assertNotNull(parameterList.leftParenthesis);
    JUnitTestCase.assertNotNull(parameterList.leftDelimiter);
    EngineTestCase.assertSize(3, parameterList.parameters);
    JUnitTestCase.assertNotNull(parameterList.rightDelimiter);
    JUnitTestCase.assertNotNull(parameterList.rightParenthesis);
  }
  void test_parseFormalParameterList_positional_single() {
    FormalParameterList parameterList = ParserTestCase.parse5("parseFormalParameterList", "([A a = null])", []);
    JUnitTestCase.assertNotNull(parameterList.leftParenthesis);
    JUnitTestCase.assertNotNull(parameterList.leftDelimiter);
    EngineTestCase.assertSize(1, parameterList.parameters);
    JUnitTestCase.assertNotNull(parameterList.rightDelimiter);
    JUnitTestCase.assertNotNull(parameterList.rightParenthesis);
  }
  void test_parseForStatement_each_identifier() {
    ForEachStatement statement = ParserTestCase.parse5("parseForStatement", "for (element in list) {}", []);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.loopVariable);
    JUnitTestCase.assertNotNull(statement.inKeyword);
    JUnitTestCase.assertNotNull(statement.iterator);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }
  void test_parseForStatement_each_noType_metadata() {
    ForEachStatement statement = ParserTestCase.parse5("parseForStatement", "for (@A var element in list) {}", []);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.loopVariable);
    EngineTestCase.assertSize(1, statement.loopVariable.metadata);
    JUnitTestCase.assertNotNull(statement.inKeyword);
    JUnitTestCase.assertNotNull(statement.iterator);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }
  void test_parseForStatement_each_type() {
    ForEachStatement statement = ParserTestCase.parse5("parseForStatement", "for (A element in list) {}", []);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.loopVariable);
    JUnitTestCase.assertNotNull(statement.inKeyword);
    JUnitTestCase.assertNotNull(statement.iterator);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }
  void test_parseForStatement_each_var() {
    ForEachStatement statement = ParserTestCase.parse5("parseForStatement", "for (var element in list) {}", []);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.loopVariable);
    JUnitTestCase.assertNotNull(statement.inKeyword);
    JUnitTestCase.assertNotNull(statement.iterator);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }
  void test_parseForStatement_loop_c() {
    ForStatement statement = ParserTestCase.parse5("parseForStatement", "for (; i < count;) {}", []);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNull(statement.variables);
    JUnitTestCase.assertNull(statement.initialization);
    JUnitTestCase.assertNotNull(statement.leftSeparator);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightSeparator);
    EngineTestCase.assertSize(0, statement.updaters);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }
  void test_parseForStatement_loop_cu() {
    ForStatement statement = ParserTestCase.parse5("parseForStatement", "for (; i < count; i++) {}", []);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNull(statement.variables);
    JUnitTestCase.assertNull(statement.initialization);
    JUnitTestCase.assertNotNull(statement.leftSeparator);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightSeparator);
    EngineTestCase.assertSize(1, statement.updaters);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }
  void test_parseForStatement_loop_ecu() {
    ForStatement statement = ParserTestCase.parse5("parseForStatement", "for (i--; i < count; i++) {}", []);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNull(statement.variables);
    JUnitTestCase.assertNotNull(statement.initialization);
    JUnitTestCase.assertNotNull(statement.leftSeparator);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightSeparator);
    EngineTestCase.assertSize(1, statement.updaters);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }
  void test_parseForStatement_loop_i() {
    ForStatement statement = ParserTestCase.parse5("parseForStatement", "for (var i = 0;;) {}", []);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    VariableDeclarationList variables9 = statement.variables;
    JUnitTestCase.assertNotNull(variables9);
    EngineTestCase.assertSize(0, variables9.metadata);
    EngineTestCase.assertSize(1, variables9.variables);
    JUnitTestCase.assertNull(statement.initialization);
    JUnitTestCase.assertNotNull(statement.leftSeparator);
    JUnitTestCase.assertNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightSeparator);
    EngineTestCase.assertSize(0, statement.updaters);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }
  void test_parseForStatement_loop_i_withMetadata() {
    ForStatement statement = ParserTestCase.parse5("parseForStatement", "for (@A var i = 0;;) {}", []);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    VariableDeclarationList variables10 = statement.variables;
    JUnitTestCase.assertNotNull(variables10);
    EngineTestCase.assertSize(1, variables10.metadata);
    EngineTestCase.assertSize(1, variables10.variables);
    JUnitTestCase.assertNull(statement.initialization);
    JUnitTestCase.assertNotNull(statement.leftSeparator);
    JUnitTestCase.assertNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightSeparator);
    EngineTestCase.assertSize(0, statement.updaters);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }
  void test_parseForStatement_loop_ic() {
    ForStatement statement = ParserTestCase.parse5("parseForStatement", "for (var i = 0; i < count;) {}", []);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    VariableDeclarationList variables11 = statement.variables;
    JUnitTestCase.assertNotNull(variables11);
    EngineTestCase.assertSize(1, variables11.variables);
    JUnitTestCase.assertNull(statement.initialization);
    JUnitTestCase.assertNotNull(statement.leftSeparator);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightSeparator);
    EngineTestCase.assertSize(0, statement.updaters);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }
  void test_parseForStatement_loop_icu() {
    ForStatement statement = ParserTestCase.parse5("parseForStatement", "for (var i = 0; i < count; i++) {}", []);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    VariableDeclarationList variables12 = statement.variables;
    JUnitTestCase.assertNotNull(variables12);
    EngineTestCase.assertSize(1, variables12.variables);
    JUnitTestCase.assertNull(statement.initialization);
    JUnitTestCase.assertNotNull(statement.leftSeparator);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightSeparator);
    EngineTestCase.assertSize(1, statement.updaters);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }
  void test_parseForStatement_loop_iicuu() {
    ForStatement statement = ParserTestCase.parse5("parseForStatement", "for (int i = 0, j = count; i < j; i++, j--) {}", []);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    VariableDeclarationList variables13 = statement.variables;
    JUnitTestCase.assertNotNull(variables13);
    EngineTestCase.assertSize(2, variables13.variables);
    JUnitTestCase.assertNull(statement.initialization);
    JUnitTestCase.assertNotNull(statement.leftSeparator);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightSeparator);
    EngineTestCase.assertSize(2, statement.updaters);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }
  void test_parseForStatement_loop_iu() {
    ForStatement statement = ParserTestCase.parse5("parseForStatement", "for (var i = 0;; i++) {}", []);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    VariableDeclarationList variables14 = statement.variables;
    JUnitTestCase.assertNotNull(variables14);
    EngineTestCase.assertSize(1, variables14.variables);
    JUnitTestCase.assertNull(statement.initialization);
    JUnitTestCase.assertNotNull(statement.leftSeparator);
    JUnitTestCase.assertNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightSeparator);
    EngineTestCase.assertSize(1, statement.updaters);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }
  void test_parseForStatement_loop_u() {
    ForStatement statement = ParserTestCase.parse5("parseForStatement", "for (;; i++) {}", []);
    JUnitTestCase.assertNotNull(statement.forKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNull(statement.variables);
    JUnitTestCase.assertNull(statement.initialization);
    JUnitTestCase.assertNotNull(statement.leftSeparator);
    JUnitTestCase.assertNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightSeparator);
    EngineTestCase.assertSize(1, statement.updaters);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }
  void test_parseFunctionBody_block() {
    BlockFunctionBody functionBody = ParserTestCase.parse("parseFunctionBody", <Object> [false, false], "{}");
    JUnitTestCase.assertNotNull(functionBody.block);
  }
  void test_parseFunctionBody_empty() {
    EmptyFunctionBody functionBody = ParserTestCase.parse("parseFunctionBody", <Object> [true, false], ";");
    JUnitTestCase.assertNotNull(functionBody.semicolon);
  }
  void test_parseFunctionBody_expression() {
    ExpressionFunctionBody functionBody = ParserTestCase.parse("parseFunctionBody", <Object> [false, false], "=> y;");
    JUnitTestCase.assertNotNull(functionBody.functionDefinition);
    JUnitTestCase.assertNotNull(functionBody.expression);
    JUnitTestCase.assertNotNull(functionBody.semicolon);
  }
  void test_parseFunctionBody_nativeFunctionBody() {
    NativeFunctionBody functionBody = ParserTestCase.parse("parseFunctionBody", <Object> [false, false], "native 'str';");
    JUnitTestCase.assertNotNull(functionBody.nativeToken);
    JUnitTestCase.assertNotNull(functionBody.stringLiteral);
    JUnitTestCase.assertNotNull(functionBody.semicolon);
  }
  void test_parseFunctionDeclaration_function() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    TypeName returnType = new TypeName.full(new SimpleIdentifier.full(null), null);
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
    TypeName returnType = new TypeName.full(new SimpleIdentifier.full(null), null);
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
    TypeName returnType = new TypeName.full(new SimpleIdentifier.full(null), null);
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
    FunctionDeclarationStatement statement = ParserTestCase.parse5("parseFunctionDeclarationStatement", "void f(int p) => p * 2;", []);
    JUnitTestCase.assertNotNull(statement.functionDeclaration);
  }
  void test_parseFunctionExpression_body_inExpression() {
    FunctionExpression expression = ParserTestCase.parse5("parseFunctionExpression", "(int i) => i++", []);
    JUnitTestCase.assertNotNull(expression.body);
    JUnitTestCase.assertNotNull(expression.parameters);
    JUnitTestCase.assertNull(((expression.body as ExpressionFunctionBody)).semicolon);
  }
  void test_parseFunctionExpression_minimal() {
    FunctionExpression expression = ParserTestCase.parse5("parseFunctionExpression", "() {}", []);
    JUnitTestCase.assertNotNull(expression.body);
    JUnitTestCase.assertNotNull(expression.parameters);
  }
  void test_parseGetter_nonStatic() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    TypeName returnType = new TypeName.full(new SimpleIdentifier.full(null), null);
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
    Token staticKeyword = TokenFactory.token(Keyword.STATIC);
    TypeName returnType = new TypeName.full(new SimpleIdentifier.full(null), null);
    MethodDeclaration method = ParserTestCase.parse("parseGetter", <Object> [commentAndMetadata(comment, []), null, staticKeyword, returnType], "get a;");
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
    List<SimpleIdentifier> list = ParserTestCase.parse5("parseIdentifierList", "a, b, c", []);
    EngineTestCase.assertSize(3, list);
  }
  void test_parseIdentifierList_single() {
    List<SimpleIdentifier> list = ParserTestCase.parse5("parseIdentifierList", "a", []);
    EngineTestCase.assertSize(1, list);
  }
  void test_parseIfStatement_else_block() {
    IfStatement statement = ParserTestCase.parse5("parseIfStatement", "if (x) {} else {}", []);
    JUnitTestCase.assertNotNull(statement.ifKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.thenStatement);
    JUnitTestCase.assertNotNull(statement.elseKeyword);
    JUnitTestCase.assertNotNull(statement.elseStatement);
  }
  void test_parseIfStatement_else_statement() {
    IfStatement statement = ParserTestCase.parse5("parseIfStatement", "if (x) f(x); else f(y);", []);
    JUnitTestCase.assertNotNull(statement.ifKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.thenStatement);
    JUnitTestCase.assertNotNull(statement.elseKeyword);
    JUnitTestCase.assertNotNull(statement.elseStatement);
  }
  void test_parseIfStatement_noElse_block() {
    IfStatement statement = ParserTestCase.parse5("parseIfStatement", "if (x) {}", []);
    JUnitTestCase.assertNotNull(statement.ifKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.thenStatement);
    JUnitTestCase.assertNull(statement.elseKeyword);
    JUnitTestCase.assertNull(statement.elseStatement);
  }
  void test_parseIfStatement_noElse_statement() {
    IfStatement statement = ParserTestCase.parse5("parseIfStatement", "if (x) f(x);", []);
    JUnitTestCase.assertNotNull(statement.ifKeyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.thenStatement);
    JUnitTestCase.assertNull(statement.elseKeyword);
    JUnitTestCase.assertNull(statement.elseStatement);
  }
  void test_parseImplementsClause_multiple() {
    ImplementsClause clause = ParserTestCase.parse5("parseImplementsClause", "implements A, B, C", []);
    EngineTestCase.assertSize(3, clause.interfaces);
    JUnitTestCase.assertNotNull(clause.keyword);
  }
  void test_parseImplementsClause_single() {
    ImplementsClause clause = ParserTestCase.parse5("parseImplementsClause", "implements A", []);
    EngineTestCase.assertSize(1, clause.interfaces);
    JUnitTestCase.assertNotNull(clause.keyword);
  }
  void test_parseImportDirective_hide() {
    ImportDirective directive = ParserTestCase.parse("parseImportDirective", <Object> [emptyCommentAndMetadata()], "import 'lib/lib.dart' hide A, B;");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    JUnitTestCase.assertNull(directive.asToken);
    JUnitTestCase.assertNull(directive.prefix);
    EngineTestCase.assertSize(1, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }
  void test_parseImportDirective_noCombinator() {
    ImportDirective directive = ParserTestCase.parse("parseImportDirective", <Object> [emptyCommentAndMetadata()], "import 'lib/lib.dart';");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    JUnitTestCase.assertNull(directive.asToken);
    JUnitTestCase.assertNull(directive.prefix);
    EngineTestCase.assertSize(0, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }
  void test_parseImportDirective_prefix() {
    ImportDirective directive = ParserTestCase.parse("parseImportDirective", <Object> [emptyCommentAndMetadata()], "import 'lib/lib.dart' as a;");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    JUnitTestCase.assertNotNull(directive.asToken);
    JUnitTestCase.assertNotNull(directive.prefix);
    EngineTestCase.assertSize(0, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }
  void test_parseImportDirective_prefix_hide_show() {
    ImportDirective directive = ParserTestCase.parse("parseImportDirective", <Object> [emptyCommentAndMetadata()], "import 'lib/lib.dart' as a hide A show B;");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    JUnitTestCase.assertNotNull(directive.asToken);
    JUnitTestCase.assertNotNull(directive.prefix);
    EngineTestCase.assertSize(2, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }
  void test_parseImportDirective_prefix_show_hide() {
    ImportDirective directive = ParserTestCase.parse("parseImportDirective", <Object> [emptyCommentAndMetadata()], "import 'lib/lib.dart' as a show B hide A;");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    JUnitTestCase.assertNotNull(directive.asToken);
    JUnitTestCase.assertNotNull(directive.prefix);
    EngineTestCase.assertSize(2, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }
  void test_parseImportDirective_show() {
    ImportDirective directive = ParserTestCase.parse("parseImportDirective", <Object> [emptyCommentAndMetadata()], "import 'lib/lib.dart' show A, B;");
    JUnitTestCase.assertNotNull(directive.keyword);
    JUnitTestCase.assertNotNull(directive.uri);
    JUnitTestCase.assertNull(directive.asToken);
    JUnitTestCase.assertNull(directive.prefix);
    EngineTestCase.assertSize(1, directive.combinators);
    JUnitTestCase.assertNotNull(directive.semicolon);
  }
  void test_parseInitializedIdentifierList_type() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    Token staticKeyword = TokenFactory.token(Keyword.STATIC);
    TypeName type = new TypeName.full(new SimpleIdentifier.full(null), null);
    FieldDeclaration declaration = ParserTestCase.parse("parseInitializedIdentifierList", <Object> [commentAndMetadata(comment, []), staticKeyword, null, type], "a = 1, b, c = 3;");
    JUnitTestCase.assertEquals(comment, declaration.documentationComment);
    VariableDeclarationList fields4 = declaration.fields;
    JUnitTestCase.assertNotNull(fields4);
    JUnitTestCase.assertNull(fields4.keyword);
    JUnitTestCase.assertEquals(type, fields4.type);
    EngineTestCase.assertSize(3, fields4.variables);
    JUnitTestCase.assertEquals(staticKeyword, declaration.keyword);
    JUnitTestCase.assertNotNull(declaration.semicolon);
  }
  void test_parseInitializedIdentifierList_var() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    Token staticKeyword = TokenFactory.token(Keyword.STATIC);
    Token varKeyword = TokenFactory.token(Keyword.VAR);
    FieldDeclaration declaration = ParserTestCase.parse("parseInitializedIdentifierList", <Object> [commentAndMetadata(comment, []), staticKeyword, varKeyword, null], "a = 1, b, c = 3;");
    JUnitTestCase.assertEquals(comment, declaration.documentationComment);
    VariableDeclarationList fields5 = declaration.fields;
    JUnitTestCase.assertNotNull(fields5);
    JUnitTestCase.assertEquals(varKeyword, fields5.keyword);
    JUnitTestCase.assertNull(fields5.type);
    EngineTestCase.assertSize(3, fields5.variables);
    JUnitTestCase.assertEquals(staticKeyword, declaration.keyword);
    JUnitTestCase.assertNotNull(declaration.semicolon);
  }
  void test_parseInstanceCreationExpression_qualifiedType() {
    Token token10 = TokenFactory.token(Keyword.NEW);
    InstanceCreationExpression expression = ParserTestCase.parse("parseInstanceCreationExpression", <Object> [token10], "A.B()");
    JUnitTestCase.assertEquals(token10, expression.keyword);
    ConstructorName name = expression.constructorName;
    JUnitTestCase.assertNotNull(name);
    JUnitTestCase.assertNotNull(name.type);
    JUnitTestCase.assertNull(name.period);
    JUnitTestCase.assertNull(name.name);
    JUnitTestCase.assertNotNull(expression.argumentList);
  }
  void test_parseInstanceCreationExpression_qualifiedType_named() {
    Token token11 = TokenFactory.token(Keyword.NEW);
    InstanceCreationExpression expression = ParserTestCase.parse("parseInstanceCreationExpression", <Object> [token11], "A.B.c()");
    JUnitTestCase.assertEquals(token11, expression.keyword);
    ConstructorName name = expression.constructorName;
    JUnitTestCase.assertNotNull(name);
    JUnitTestCase.assertNotNull(name.type);
    JUnitTestCase.assertNotNull(name.period);
    JUnitTestCase.assertNotNull(name.name);
    JUnitTestCase.assertNotNull(expression.argumentList);
  }
  void test_parseInstanceCreationExpression_type() {
    Token token12 = TokenFactory.token(Keyword.NEW);
    InstanceCreationExpression expression = ParserTestCase.parse("parseInstanceCreationExpression", <Object> [token12], "A()");
    JUnitTestCase.assertEquals(token12, expression.keyword);
    ConstructorName name = expression.constructorName;
    JUnitTestCase.assertNotNull(name);
    JUnitTestCase.assertNotNull(name.type);
    JUnitTestCase.assertNull(name.period);
    JUnitTestCase.assertNull(name.name);
    JUnitTestCase.assertNotNull(expression.argumentList);
  }
  void test_parseInstanceCreationExpression_type_named() {
    Token token13 = TokenFactory.token(Keyword.NEW);
    InstanceCreationExpression expression = ParserTestCase.parse("parseInstanceCreationExpression", <Object> [token13], "A<B>.c()");
    JUnitTestCase.assertEquals(token13, expression.keyword);
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
    LibraryIdentifier identifier = ParserTestCase.parse5("parseLibraryIdentifier", name, []);
    JUnitTestCase.assertEquals(name, identifier.name);
  }
  void test_parseLibraryIdentifier_single() {
    String name = "a";
    LibraryIdentifier identifier = ParserTestCase.parse5("parseLibraryIdentifier", name, []);
    JUnitTestCase.assertEquals(name, identifier.name);
  }
  void test_parseListLiteral_empty_oneToken() {
    Token token14 = TokenFactory.token(Keyword.CONST);
    TypeArgumentList typeArguments = new TypeArgumentList.full(null, null, null);
    ListLiteral literal = ParserTestCase.parse("parseListLiteral", <Object> [token14, typeArguments], "[]");
    JUnitTestCase.assertEquals(token14, literal.modifier);
    JUnitTestCase.assertEquals(typeArguments, literal.typeArguments);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSize(0, literal.elements);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }
  void test_parseListLiteral_empty_twoTokens() {
    Token token15 = TokenFactory.token(Keyword.CONST);
    TypeArgumentList typeArguments = new TypeArgumentList.full(null, null, null);
    ListLiteral literal = ParserTestCase.parse("parseListLiteral", <Object> [token15, typeArguments], "[ ]");
    JUnitTestCase.assertEquals(token15, literal.modifier);
    JUnitTestCase.assertEquals(typeArguments, literal.typeArguments);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSize(0, literal.elements);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }
  void test_parseListLiteral_multiple() {
    ListLiteral literal = ParserTestCase.parse("parseListLiteral", <Object> [null, null], "[1, 2, 3]");
    JUnitTestCase.assertNull(literal.modifier);
    JUnitTestCase.assertNull(literal.typeArguments);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSize(3, literal.elements);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }
  void test_parseListLiteral_single() {
    ListLiteral literal = ParserTestCase.parse("parseListLiteral", <Object> [null, null], "[1]");
    JUnitTestCase.assertNull(literal.modifier);
    JUnitTestCase.assertNull(literal.typeArguments);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSize(1, literal.elements);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }
  void test_parseListOrMapLiteral_list_noType() {
    ListLiteral literal = ParserTestCase.parse("parseListOrMapLiteral", <Object> [null], "[1]");
    JUnitTestCase.assertNull(literal.modifier);
    JUnitTestCase.assertNull(literal.typeArguments);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSize(1, literal.elements);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }
  void test_parseListOrMapLiteral_list_type() {
    ListLiteral literal = ParserTestCase.parse("parseListOrMapLiteral", <Object> [null], "<int> [1]");
    JUnitTestCase.assertNull(literal.modifier);
    JUnitTestCase.assertNotNull(literal.typeArguments);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSize(1, literal.elements);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }
  void test_parseListOrMapLiteral_map_noType() {
    MapLiteral literal = ParserTestCase.parse("parseListOrMapLiteral", <Object> [null], "{'1' : 1}");
    JUnitTestCase.assertNull(literal.modifier);
    JUnitTestCase.assertNull(literal.typeArguments);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSize(1, literal.entries);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }
  void test_parseListOrMapLiteral_map_type() {
    MapLiteral literal = ParserTestCase.parse("parseListOrMapLiteral", <Object> [null], "<int> {'1' : 1}");
    JUnitTestCase.assertNull(literal.modifier);
    JUnitTestCase.assertNotNull(literal.typeArguments);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSize(1, literal.entries);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }
  void test_parseLogicalAndExpression() {
    BinaryExpression expression = ParserTestCase.parse5("parseLogicalAndExpression", "x && y", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.AMPERSAND_AMPERSAND, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }
  void test_parseLogicalOrExpression() {
    BinaryExpression expression = ParserTestCase.parse5("parseLogicalOrExpression", "x || y", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.BAR_BAR, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }
  void test_parseMapLiteral_empty() {
    Token token16 = TokenFactory.token(Keyword.CONST);
    TypeArgumentList typeArguments = new TypeArgumentList.full(null, null, null);
    MapLiteral literal = ParserTestCase.parse("parseMapLiteral", <Object> [token16, typeArguments], "{}");
    JUnitTestCase.assertEquals(token16, literal.modifier);
    JUnitTestCase.assertEquals(typeArguments, literal.typeArguments);
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSize(0, literal.entries);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }
  void test_parseMapLiteral_multiple() {
    MapLiteral literal = ParserTestCase.parse("parseMapLiteral", <Object> [null, null], "{'a' : b, 'x' : y}");
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSize(2, literal.entries);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }
  void test_parseMapLiteral_single() {
    MapLiteral literal = ParserTestCase.parse("parseMapLiteral", <Object> [null, null], "{'x' : y}");
    JUnitTestCase.assertNotNull(literal.leftBracket);
    EngineTestCase.assertSize(1, literal.entries);
    JUnitTestCase.assertNotNull(literal.rightBracket);
  }
  void test_parseMapLiteralEntry() {
    MapLiteralEntry entry = ParserTestCase.parse5("parseMapLiteralEntry", "'x' : y", []);
    JUnitTestCase.assertNotNull(entry.key);
    JUnitTestCase.assertNotNull(entry.separator);
    JUnitTestCase.assertNotNull(entry.value);
  }
  void test_parseModifiers_abstract() {
    Modifiers modifiers = ParserTestCase.parse5("parseModifiers", "abstract A", []);
    JUnitTestCase.assertNotNull(modifiers.abstractKeyword);
  }
  void test_parseModifiers_const() {
    Modifiers modifiers = ParserTestCase.parse5("parseModifiers", "const A", []);
    JUnitTestCase.assertNotNull(modifiers.constKeyword);
  }
  void test_parseModifiers_external() {
    Modifiers modifiers = ParserTestCase.parse5("parseModifiers", "external A", []);
    JUnitTestCase.assertNotNull(modifiers.externalKeyword);
  }
  void test_parseModifiers_factory() {
    Modifiers modifiers = ParserTestCase.parse5("parseModifiers", "factory A", []);
    JUnitTestCase.assertNotNull(modifiers.factoryKeyword);
  }
  void test_parseModifiers_final() {
    Modifiers modifiers = ParserTestCase.parse5("parseModifiers", "final A", []);
    JUnitTestCase.assertNotNull(modifiers.finalKeyword);
  }
  void test_parseModifiers_static() {
    Modifiers modifiers = ParserTestCase.parse5("parseModifiers", "static A", []);
    JUnitTestCase.assertNotNull(modifiers.staticKeyword);
  }
  void test_parseModifiers_var() {
    Modifiers modifiers = ParserTestCase.parse5("parseModifiers", "var A", []);
    JUnitTestCase.assertNotNull(modifiers.varKeyword);
  }
  void test_parseMultiplicativeExpression_normal() {
    BinaryExpression expression = ParserTestCase.parse5("parseMultiplicativeExpression", "x * y", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.STAR, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }
  void test_parseMultiplicativeExpression_super() {
    BinaryExpression expression = ParserTestCase.parse5("parseMultiplicativeExpression", "super * y", []);
    EngineTestCase.assertInstanceOf(SuperExpression, expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.STAR, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }
  void test_parseNewExpression() {
    InstanceCreationExpression expression = ParserTestCase.parse5("parseNewExpression", "new A()", []);
    JUnitTestCase.assertNotNull(expression.keyword);
    ConstructorName name = expression.constructorName;
    JUnitTestCase.assertNotNull(name);
    JUnitTestCase.assertNotNull(name.type);
    JUnitTestCase.assertNull(name.period);
    JUnitTestCase.assertNull(name.name);
    JUnitTestCase.assertNotNull(expression.argumentList);
  }
  void test_parseNonLabeledStatement_const_list_empty() {
    ExpressionStatement statement = ParserTestCase.parse5("parseNonLabeledStatement", "const [];", []);
    JUnitTestCase.assertNotNull(statement.expression);
  }
  void test_parseNonLabeledStatement_const_list_nonEmpty() {
    ExpressionStatement statement = ParserTestCase.parse5("parseNonLabeledStatement", "const [1, 2];", []);
    JUnitTestCase.assertNotNull(statement.expression);
  }
  void test_parseNonLabeledStatement_const_map_empty() {
    ExpressionStatement statement = ParserTestCase.parse5("parseNonLabeledStatement", "const {};", []);
    JUnitTestCase.assertNotNull(statement.expression);
  }
  void test_parseNonLabeledStatement_const_map_nonEmpty() {
    ExpressionStatement statement = ParserTestCase.parse5("parseNonLabeledStatement", "const {'a' : 1};", []);
    JUnitTestCase.assertNotNull(statement.expression);
  }
  void test_parseNonLabeledStatement_const_object() {
    ExpressionStatement statement = ParserTestCase.parse5("parseNonLabeledStatement", "const A();", []);
    JUnitTestCase.assertNotNull(statement.expression);
  }
  void test_parseNonLabeledStatement_const_object_named_typeParameters() {
    ExpressionStatement statement = ParserTestCase.parse5("parseNonLabeledStatement", "const A<B>.c();", []);
    JUnitTestCase.assertNotNull(statement.expression);
  }
  void test_parseNonLabeledStatement_constructorInvocation() {
    ExpressionStatement statement = ParserTestCase.parse5("parseNonLabeledStatement", "new C().m();", []);
    JUnitTestCase.assertNotNull(statement.expression);
  }
  void test_parseNonLabeledStatement_false() {
    ExpressionStatement statement = ParserTestCase.parse5("parseNonLabeledStatement", "false;", []);
    JUnitTestCase.assertNotNull(statement.expression);
  }
  void test_parseNonLabeledStatement_functionDeclaration() {
    ParserTestCase.parse5("parseNonLabeledStatement", "f() {};", []);
  }
  void test_parseNonLabeledStatement_functionDeclaration_arguments() {
    ParserTestCase.parse5("parseNonLabeledStatement", "f(void g()) {};", []);
  }
  void test_parseNonLabeledStatement_functionExpressionIndex() {
    ParserTestCase.parse5("parseNonLabeledStatement", "() {}[0] = null;", []);
  }
  void test_parseNonLabeledStatement_functionInvocation() {
    ExpressionStatement statement = ParserTestCase.parse5("parseNonLabeledStatement", "f();", []);
    JUnitTestCase.assertNotNull(statement.expression);
  }
  void test_parseNonLabeledStatement_invokeFunctionExpression() {
    ExpressionStatement statement = ParserTestCase.parse5("parseNonLabeledStatement", "(a) {return a + a;} (3);", []);
    EngineTestCase.assertInstanceOf(FunctionExpressionInvocation, statement.expression);
    FunctionExpressionInvocation invocation = statement.expression as FunctionExpressionInvocation;
    EngineTestCase.assertInstanceOf(FunctionExpression, invocation.function);
    FunctionExpression expression = invocation.function as FunctionExpression;
    JUnitTestCase.assertNotNull(expression.parameters);
    JUnitTestCase.assertNotNull(expression.body);
    ArgumentList list = invocation.argumentList;
    JUnitTestCase.assertNotNull(list);
    EngineTestCase.assertSize(1, list.arguments);
  }
  void test_parseNonLabeledStatement_null() {
    ExpressionStatement statement = ParserTestCase.parse5("parseNonLabeledStatement", "null;", []);
    JUnitTestCase.assertNotNull(statement.expression);
  }
  void test_parseNonLabeledStatement_startingWithBuiltInIdentifier() {
    ExpressionStatement statement = ParserTestCase.parse5("parseNonLabeledStatement", "library.getName();", []);
    JUnitTestCase.assertNotNull(statement.expression);
  }
  void test_parseNonLabeledStatement_true() {
    ExpressionStatement statement = ParserTestCase.parse5("parseNonLabeledStatement", "true;", []);
    JUnitTestCase.assertNotNull(statement.expression);
  }
  void test_parseNonLabeledStatement_typeCast() {
    ExpressionStatement statement = ParserTestCase.parse5("parseNonLabeledStatement", "double.NAN as num;", []);
    JUnitTestCase.assertNotNull(statement.expression);
  }
  void test_parseNormalFormalParameter_field_const_noType() {
    FieldFormalParameter parameter = ParserTestCase.parse5("parseNormalFormalParameter", "const this.a)", []);
    JUnitTestCase.assertNotNull(parameter.keyword);
    JUnitTestCase.assertNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
  }
  void test_parseNormalFormalParameter_field_const_type() {
    FieldFormalParameter parameter = ParserTestCase.parse5("parseNormalFormalParameter", "const A this.a)", []);
    JUnitTestCase.assertNotNull(parameter.keyword);
    JUnitTestCase.assertNotNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
  }
  void test_parseNormalFormalParameter_field_final_noType() {
    FieldFormalParameter parameter = ParserTestCase.parse5("parseNormalFormalParameter", "final this.a)", []);
    JUnitTestCase.assertNotNull(parameter.keyword);
    JUnitTestCase.assertNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
  }
  void test_parseNormalFormalParameter_field_final_type() {
    FieldFormalParameter parameter = ParserTestCase.parse5("parseNormalFormalParameter", "final A this.a)", []);
    JUnitTestCase.assertNotNull(parameter.keyword);
    JUnitTestCase.assertNotNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
  }
  void test_parseNormalFormalParameter_field_noType() {
    FieldFormalParameter parameter = ParserTestCase.parse5("parseNormalFormalParameter", "this.a)", []);
    JUnitTestCase.assertNull(parameter.keyword);
    JUnitTestCase.assertNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
  }
  void test_parseNormalFormalParameter_field_type() {
    FieldFormalParameter parameter = ParserTestCase.parse5("parseNormalFormalParameter", "A this.a)", []);
    JUnitTestCase.assertNull(parameter.keyword);
    JUnitTestCase.assertNotNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
  }
  void test_parseNormalFormalParameter_field_var() {
    FieldFormalParameter parameter = ParserTestCase.parse5("parseNormalFormalParameter", "var this.a)", []);
    JUnitTestCase.assertNotNull(parameter.keyword);
    JUnitTestCase.assertNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
  }
  void test_parseNormalFormalParameter_function_noType() {
    FunctionTypedFormalParameter parameter = ParserTestCase.parse5("parseNormalFormalParameter", "a())", []);
    JUnitTestCase.assertNull(parameter.returnType);
    JUnitTestCase.assertNotNull(parameter.identifier);
    JUnitTestCase.assertNotNull(parameter.parameters);
  }
  void test_parseNormalFormalParameter_function_type() {
    FunctionTypedFormalParameter parameter = ParserTestCase.parse5("parseNormalFormalParameter", "A a())", []);
    JUnitTestCase.assertNotNull(parameter.returnType);
    JUnitTestCase.assertNotNull(parameter.identifier);
    JUnitTestCase.assertNotNull(parameter.parameters);
  }
  void test_parseNormalFormalParameter_function_void() {
    FunctionTypedFormalParameter parameter = ParserTestCase.parse5("parseNormalFormalParameter", "void a())", []);
    JUnitTestCase.assertNotNull(parameter.returnType);
    JUnitTestCase.assertNotNull(parameter.identifier);
    JUnitTestCase.assertNotNull(parameter.parameters);
  }
  void test_parseNormalFormalParameter_simple_const_noType() {
    SimpleFormalParameter parameter = ParserTestCase.parse5("parseNormalFormalParameter", "const a)", []);
    JUnitTestCase.assertNotNull(parameter.keyword);
    JUnitTestCase.assertNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
  }
  void test_parseNormalFormalParameter_simple_const_type() {
    SimpleFormalParameter parameter = ParserTestCase.parse5("parseNormalFormalParameter", "const A a)", []);
    JUnitTestCase.assertNotNull(parameter.keyword);
    JUnitTestCase.assertNotNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
  }
  void test_parseNormalFormalParameter_simple_final_noType() {
    SimpleFormalParameter parameter = ParserTestCase.parse5("parseNormalFormalParameter", "final a)", []);
    JUnitTestCase.assertNotNull(parameter.keyword);
    JUnitTestCase.assertNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
  }
  void test_parseNormalFormalParameter_simple_final_type() {
    SimpleFormalParameter parameter = ParserTestCase.parse5("parseNormalFormalParameter", "final A a)", []);
    JUnitTestCase.assertNotNull(parameter.keyword);
    JUnitTestCase.assertNotNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
  }
  void test_parseNormalFormalParameter_simple_noType() {
    SimpleFormalParameter parameter = ParserTestCase.parse5("parseNormalFormalParameter", "a)", []);
    JUnitTestCase.assertNull(parameter.keyword);
    JUnitTestCase.assertNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
  }
  void test_parseNormalFormalParameter_simple_type() {
    SimpleFormalParameter parameter = ParserTestCase.parse5("parseNormalFormalParameter", "A a)", []);
    JUnitTestCase.assertNull(parameter.keyword);
    JUnitTestCase.assertNotNull(parameter.type);
    JUnitTestCase.assertNotNull(parameter.identifier);
  }
  void test_parseOperator() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    TypeName returnType = new TypeName.full(new SimpleIdentifier.full(null), null);
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
    PostfixExpression expression = ParserTestCase.parse5("parsePostfixExpression", "i--", []);
    JUnitTestCase.assertNotNull(expression.operand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.MINUS_MINUS, expression.operator.type);
  }
  void test_parsePostfixExpression_increment() {
    PostfixExpression expression = ParserTestCase.parse5("parsePostfixExpression", "i++", []);
    JUnitTestCase.assertNotNull(expression.operand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.PLUS_PLUS, expression.operator.type);
  }
  void test_parsePostfixExpression_none_indexExpression() {
    IndexExpression expression = ParserTestCase.parse5("parsePostfixExpression", "a[0]", []);
    JUnitTestCase.assertNotNull(expression.array);
    JUnitTestCase.assertNotNull(expression.index);
  }
  void test_parsePostfixExpression_none_methodInvocation() {
    MethodInvocation expression = ParserTestCase.parse5("parsePostfixExpression", "a.m()", []);
    JUnitTestCase.assertNotNull(expression.target);
    JUnitTestCase.assertNotNull(expression.methodName);
    JUnitTestCase.assertNotNull(expression.argumentList);
  }
  void test_parsePostfixExpression_none_propertyAccess() {
    PrefixedIdentifier expression = ParserTestCase.parse5("parsePostfixExpression", "a.b", []);
    JUnitTestCase.assertNotNull(expression.prefix);
    JUnitTestCase.assertNotNull(expression.identifier);
  }
  void test_parsePrefixedIdentifier_noPrefix() {
    String lexeme = "bar";
    SimpleIdentifier identifier = ParserTestCase.parse5("parsePrefixedIdentifier", lexeme, []);
    JUnitTestCase.assertNotNull(identifier.token);
    JUnitTestCase.assertEquals(lexeme, identifier.name);
  }
  void test_parsePrefixedIdentifier_prefix() {
    String lexeme = "foo.bar";
    PrefixedIdentifier identifier = ParserTestCase.parse5("parsePrefixedIdentifier", lexeme, []);
    JUnitTestCase.assertEquals("foo", identifier.prefix.name);
    JUnitTestCase.assertNotNull(identifier.period);
    JUnitTestCase.assertEquals("bar", identifier.identifier.name);
  }
  void test_parsePrimaryExpression_argumentDefinitionTest() {
    ArgumentDefinitionTest expression = ParserTestCase.parse5("parseArgumentDefinitionTest", "?a", []);
    JUnitTestCase.assertNotNull(expression.question);
    JUnitTestCase.assertNotNull(expression.identifier);
  }
  void test_parsePrimaryExpression_const() {
    InstanceCreationExpression expression = ParserTestCase.parse5("parsePrimaryExpression", "const A()", []);
    JUnitTestCase.assertNotNull(expression);
  }
  void test_parsePrimaryExpression_double() {
    String doubleLiteral = "3.2e4";
    DoubleLiteral literal = ParserTestCase.parse5("parsePrimaryExpression", doubleLiteral, []);
    JUnitTestCase.assertNotNull(literal.literal);
    JUnitTestCase.assertEquals(double.parse(doubleLiteral), literal.value);
  }
  void test_parsePrimaryExpression_false() {
    BooleanLiteral literal = ParserTestCase.parse5("parsePrimaryExpression", "false", []);
    JUnitTestCase.assertNotNull(literal.literal);
    JUnitTestCase.assertFalse(literal.value);
  }
  void test_parsePrimaryExpression_function_arguments() {
    FunctionExpression expression = ParserTestCase.parse5("parsePrimaryExpression", "(int i) => i + 1", []);
    JUnitTestCase.assertNotNull(expression.parameters);
    JUnitTestCase.assertNotNull(expression.body);
  }
  void test_parsePrimaryExpression_function_noArguments() {
    FunctionExpression expression = ParserTestCase.parse5("parsePrimaryExpression", "() => 42", []);
    JUnitTestCase.assertNotNull(expression.parameters);
    JUnitTestCase.assertNotNull(expression.body);
  }
  void test_parsePrimaryExpression_hex() {
    String hexLiteral = "3F";
    IntegerLiteral literal = ParserTestCase.parse5("parsePrimaryExpression", "0x${hexLiteral}", []);
    JUnitTestCase.assertNotNull(literal.literal);
    JUnitTestCase.assertEquals(int.parse(hexLiteral, radix: 16), literal.value);
  }
  void test_parsePrimaryExpression_identifier() {
    SimpleIdentifier identifier = ParserTestCase.parse5("parsePrimaryExpression", "a", []);
    JUnitTestCase.assertNotNull(identifier);
  }
  void test_parsePrimaryExpression_int() {
    String intLiteral = "472";
    IntegerLiteral literal = ParserTestCase.parse5("parsePrimaryExpression", intLiteral, []);
    JUnitTestCase.assertNotNull(literal.literal);
    JUnitTestCase.assertEquals(int.parse(intLiteral), literal.value);
  }
  void test_parsePrimaryExpression_listLiteral() {
    ListLiteral literal = ParserTestCase.parse5("parsePrimaryExpression", "[ ]", []);
    JUnitTestCase.assertNotNull(literal);
  }
  void test_parsePrimaryExpression_listLiteral_index() {
    ListLiteral literal = ParserTestCase.parse5("parsePrimaryExpression", "[]", []);
    JUnitTestCase.assertNotNull(literal);
  }
  void test_parsePrimaryExpression_listLiteral_typed() {
    ListLiteral literal = ParserTestCase.parse5("parsePrimaryExpression", "<A>[ ]", []);
    JUnitTestCase.assertNotNull(literal.typeArguments);
    EngineTestCase.assertSize(1, literal.typeArguments.arguments);
  }
  void test_parsePrimaryExpression_mapLiteral() {
    MapLiteral literal = ParserTestCase.parse5("parsePrimaryExpression", "{}", []);
    JUnitTestCase.assertNotNull(literal);
  }
  void test_parsePrimaryExpression_mapLiteral_typed() {
    MapLiteral literal = ParserTestCase.parse5("parsePrimaryExpression", "<A>{}", []);
    JUnitTestCase.assertNotNull(literal.typeArguments);
    EngineTestCase.assertSize(1, literal.typeArguments.arguments);
  }
  void test_parsePrimaryExpression_new() {
    InstanceCreationExpression expression = ParserTestCase.parse5("parsePrimaryExpression", "new A()", []);
    JUnitTestCase.assertNotNull(expression);
  }
  void test_parsePrimaryExpression_null() {
    NullLiteral literal = ParserTestCase.parse5("parsePrimaryExpression", "null", []);
    JUnitTestCase.assertNotNull(literal.literal);
  }
  void test_parsePrimaryExpression_parenthesized() {
    ParenthesizedExpression expression = ParserTestCase.parse5("parsePrimaryExpression", "()", []);
    JUnitTestCase.assertNotNull(expression);
  }
  void test_parsePrimaryExpression_string() {
    SimpleStringLiteral literal = ParserTestCase.parse5("parsePrimaryExpression", "\"string\"", []);
    JUnitTestCase.assertFalse(literal.isMultiline());
    JUnitTestCase.assertEquals("string", literal.value);
  }
  void test_parsePrimaryExpression_super() {
    PropertyAccess propertyAccess = ParserTestCase.parse5("parsePrimaryExpression", "super.x", []);
    JUnitTestCase.assertTrue(propertyAccess.target is SuperExpression);
    JUnitTestCase.assertNotNull(propertyAccess.operator);
    JUnitTestCase.assertEquals(TokenType.PERIOD, propertyAccess.operator.type);
    JUnitTestCase.assertNotNull(propertyAccess.propertyName);
  }
  void test_parsePrimaryExpression_this() {
    ThisExpression expression = ParserTestCase.parse5("parsePrimaryExpression", "this", []);
    JUnitTestCase.assertNotNull(expression.keyword);
  }
  void test_parsePrimaryExpression_true() {
    BooleanLiteral literal = ParserTestCase.parse5("parsePrimaryExpression", "true", []);
    JUnitTestCase.assertNotNull(literal.literal);
    JUnitTestCase.assertTrue(literal.value);
  }
  void test_Parser() {
    JUnitTestCase.assertNotNull(new Parser(null, null));
  }
  void test_parseRedirectingConstructorInvocation_named() {
    RedirectingConstructorInvocation invocation = ParserTestCase.parse5("parseRedirectingConstructorInvocation", "this.a()", []);
    JUnitTestCase.assertNotNull(invocation.argumentList);
    JUnitTestCase.assertNotNull(invocation.constructorName);
    JUnitTestCase.assertNotNull(invocation.keyword);
    JUnitTestCase.assertNotNull(invocation.period);
  }
  void test_parseRedirectingConstructorInvocation_unnamed() {
    RedirectingConstructorInvocation invocation = ParserTestCase.parse5("parseRedirectingConstructorInvocation", "this()", []);
    JUnitTestCase.assertNotNull(invocation.argumentList);
    JUnitTestCase.assertNull(invocation.constructorName);
    JUnitTestCase.assertNotNull(invocation.keyword);
    JUnitTestCase.assertNull(invocation.period);
  }
  void test_parseRelationalExpression_as() {
    AsExpression expression = ParserTestCase.parse5("parseRelationalExpression", "x as Y", []);
    JUnitTestCase.assertNotNull(expression.expression);
    JUnitTestCase.assertNotNull(expression.asOperator);
    JUnitTestCase.assertNotNull(expression.type);
  }
  void test_parseRelationalExpression_is() {
    IsExpression expression = ParserTestCase.parse5("parseRelationalExpression", "x is y", []);
    JUnitTestCase.assertNotNull(expression.expression);
    JUnitTestCase.assertNotNull(expression.isOperator);
    JUnitTestCase.assertNull(expression.notOperator);
    JUnitTestCase.assertNotNull(expression.type);
  }
  void test_parseRelationalExpression_isNot() {
    IsExpression expression = ParserTestCase.parse5("parseRelationalExpression", "x is! y", []);
    JUnitTestCase.assertNotNull(expression.expression);
    JUnitTestCase.assertNotNull(expression.isOperator);
    JUnitTestCase.assertNotNull(expression.notOperator);
    JUnitTestCase.assertNotNull(expression.type);
  }
  void test_parseRelationalExpression_normal() {
    BinaryExpression expression = ParserTestCase.parse5("parseRelationalExpression", "x < y", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.LT, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }
  void test_parseRelationalExpression_super() {
    BinaryExpression expression = ParserTestCase.parse5("parseRelationalExpression", "super < y", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.LT, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }
  void test_parseRethrowExpression() {
    RethrowExpression expression = ParserTestCase.parse5("parseRethrowExpression", "rethrow;", []);
    JUnitTestCase.assertNotNull(expression.keyword);
  }
  void test_parseReturnStatement_noValue() {
    ReturnStatement statement = ParserTestCase.parse5("parseReturnStatement", "return;", []);
    JUnitTestCase.assertNotNull(statement.keyword);
    JUnitTestCase.assertNull(statement.expression);
    JUnitTestCase.assertNotNull(statement.semicolon);
  }
  void test_parseReturnStatement_value() {
    ReturnStatement statement = ParserTestCase.parse5("parseReturnStatement", "return x;", []);
    JUnitTestCase.assertNotNull(statement.keyword);
    JUnitTestCase.assertNotNull(statement.expression);
    JUnitTestCase.assertNotNull(statement.semicolon);
  }
  void test_parseReturnType_nonVoid() {
    TypeName typeName = ParserTestCase.parse5("parseReturnType", "A<B>", []);
    JUnitTestCase.assertNotNull(typeName.name);
    JUnitTestCase.assertNotNull(typeName.typeArguments);
  }
  void test_parseReturnType_void() {
    TypeName typeName = ParserTestCase.parse5("parseReturnType", "void", []);
    JUnitTestCase.assertNotNull(typeName.name);
    JUnitTestCase.assertNull(typeName.typeArguments);
  }
  void test_parseSetter_nonStatic() {
    Comment comment = Comment.createDocumentationComment(new List<Token>(0));
    TypeName returnType = new TypeName.full(new SimpleIdentifier.full(null), null);
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
    Token staticKeyword = TokenFactory.token(Keyword.STATIC);
    TypeName returnType = new TypeName.full(new SimpleIdentifier.full(null), null);
    MethodDeclaration method = ParserTestCase.parse("parseSetter", <Object> [commentAndMetadata(comment, []), null, staticKeyword, returnType], "set a(var x) {}");
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
    BinaryExpression expression = ParserTestCase.parse5("parseShiftExpression", "x << y", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.LT_LT, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }
  void test_parseShiftExpression_super() {
    BinaryExpression expression = ParserTestCase.parse5("parseShiftExpression", "super << y", []);
    JUnitTestCase.assertNotNull(expression.leftOperand);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.LT_LT, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.rightOperand);
  }
  void test_parseSimpleIdentifier_builtInIdentifier() {
    String lexeme = "as";
    SimpleIdentifier identifier = ParserTestCase.parse5("parseSimpleIdentifier", lexeme, []);
    JUnitTestCase.assertNotNull(identifier.token);
    JUnitTestCase.assertEquals(lexeme, identifier.name);
  }
  void test_parseSimpleIdentifier_normalIdentifier() {
    String lexeme = "foo";
    SimpleIdentifier identifier = ParserTestCase.parse5("parseSimpleIdentifier", lexeme, []);
    JUnitTestCase.assertNotNull(identifier.token);
    JUnitTestCase.assertEquals(lexeme, identifier.name);
  }
  void test_parseSimpleIdentifier1_normalIdentifier() {
  }
  void test_parseStatement_functionDeclaration() {
    FunctionDeclarationStatement statement = ParserTestCase.parse5("parseStatement", "int f(a, b) {};", []);
    JUnitTestCase.assertNotNull(statement.functionDeclaration);
  }
  void test_parseStatement_mulipleLabels() {
    LabeledStatement statement = ParserTestCase.parse5("parseStatement", "l: m: return x;", []);
    EngineTestCase.assertSize(2, statement.labels);
    JUnitTestCase.assertNotNull(statement.statement);
  }
  void test_parseStatement_noLabels() {
    ParserTestCase.parse5("parseStatement", "return x;", []);
  }
  void test_parseStatement_singleLabel() {
    LabeledStatement statement = ParserTestCase.parse5("parseStatement", "l: return x;", []);
    EngineTestCase.assertSize(1, statement.labels);
    JUnitTestCase.assertNotNull(statement.statement);
  }
  void test_parseStatements_multiple() {
    List<Statement> statements = ParserTestCase.parseStatements("return; return;", 2, []);
    EngineTestCase.assertSize(2, statements);
  }
  void test_parseStatements_single() {
    List<Statement> statements = ParserTestCase.parseStatements("return;", 1, []);
    EngineTestCase.assertSize(1, statements);
  }
  void test_parseStringLiteral_adjacent() {
    AdjacentStrings literal = ParserTestCase.parse5("parseStringLiteral", "'a' 'b'", []);
    NodeList<StringLiteral> strings2 = literal.strings;
    EngineTestCase.assertSize(2, strings2);
    StringLiteral firstString = strings2[0];
    StringLiteral secondString = strings2[1];
    JUnitTestCase.assertEquals("a", ((firstString as SimpleStringLiteral)).value);
    JUnitTestCase.assertEquals("b", ((secondString as SimpleStringLiteral)).value);
  }
  void test_parseStringLiteral_interpolated() {
    StringInterpolation literal = ParserTestCase.parse5("parseStringLiteral", "'a \${b} c \$this d'", []);
    NodeList<InterpolationElement> elements2 = literal.elements;
    EngineTestCase.assertSize(5, elements2);
    JUnitTestCase.assertTrue(elements2[0] is InterpolationString);
    JUnitTestCase.assertTrue(elements2[1] is InterpolationExpression);
    JUnitTestCase.assertTrue(elements2[2] is InterpolationString);
    JUnitTestCase.assertTrue(elements2[3] is InterpolationExpression);
    JUnitTestCase.assertTrue(elements2[4] is InterpolationString);
  }
  void test_parseStringLiteral_single() {
    SimpleStringLiteral literal = ParserTestCase.parse5("parseStringLiteral", "'a'", []);
    JUnitTestCase.assertNotNull(literal.literal);
    JUnitTestCase.assertEquals("a", literal.value);
  }
  void test_parseSuperConstructorInvocation_named() {
    SuperConstructorInvocation invocation = ParserTestCase.parse5("parseSuperConstructorInvocation", "super.a()", []);
    JUnitTestCase.assertNotNull(invocation.argumentList);
    JUnitTestCase.assertNotNull(invocation.constructorName);
    JUnitTestCase.assertNotNull(invocation.keyword);
    JUnitTestCase.assertNotNull(invocation.period);
  }
  void test_parseSuperConstructorInvocation_unnamed() {
    SuperConstructorInvocation invocation = ParserTestCase.parse5("parseSuperConstructorInvocation", "super()", []);
    JUnitTestCase.assertNotNull(invocation.argumentList);
    JUnitTestCase.assertNull(invocation.constructorName);
    JUnitTestCase.assertNotNull(invocation.keyword);
    JUnitTestCase.assertNull(invocation.period);
  }
  void test_parseSwitchStatement_case() {
    SwitchStatement statement = ParserTestCase.parse5("parseSwitchStatement", "switch (a) {case 1: return 'I';}", []);
    JUnitTestCase.assertNotNull(statement.keyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.expression);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.leftBracket);
    EngineTestCase.assertSize(1, statement.members);
    JUnitTestCase.assertNotNull(statement.rightBracket);
  }
  void test_parseSwitchStatement_empty() {
    SwitchStatement statement = ParserTestCase.parse5("parseSwitchStatement", "switch (a) {}", []);
    JUnitTestCase.assertNotNull(statement.keyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.expression);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.leftBracket);
    EngineTestCase.assertSize(0, statement.members);
    JUnitTestCase.assertNotNull(statement.rightBracket);
  }
  void test_parseSwitchStatement_labeledCase() {
    SwitchStatement statement = ParserTestCase.parse5("parseSwitchStatement", "switch (a) {l1: l2: l3: case(1):}", []);
    JUnitTestCase.assertNotNull(statement.keyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.expression);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.leftBracket);
    EngineTestCase.assertSize(1, statement.members);
    EngineTestCase.assertSize(3, statement.members[0].labels);
    JUnitTestCase.assertNotNull(statement.rightBracket);
  }
  void test_parseSwitchStatement_labeledStatementInCase() {
    SwitchStatement statement = ParserTestCase.parse5("parseSwitchStatement", "switch (a) {case 0: f(); l1: g(); break;}", []);
    JUnitTestCase.assertNotNull(statement.keyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.expression);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.leftBracket);
    EngineTestCase.assertSize(1, statement.members);
    EngineTestCase.assertSize(3, statement.members[0].statements);
    JUnitTestCase.assertNotNull(statement.rightBracket);
  }
  void test_parseThrowExpression() {
    ThrowExpression expression = ParserTestCase.parse5("parseThrowExpression", "throw x;", []);
    JUnitTestCase.assertNotNull(expression.keyword);
    JUnitTestCase.assertNotNull(expression.expression);
  }
  void test_parseThrowExpressionWithoutCascade() {
    ThrowExpression expression = ParserTestCase.parse5("parseThrowExpressionWithoutCascade", "throw x;", []);
    JUnitTestCase.assertNotNull(expression.keyword);
    JUnitTestCase.assertNotNull(expression.expression);
  }
  void test_parseTryStatement_catch() {
    TryStatement statement = ParserTestCase.parse5("parseTryStatement", "try {} catch (e) {}", []);
    JUnitTestCase.assertNotNull(statement.tryKeyword);
    JUnitTestCase.assertNotNull(statement.body);
    NodeList<CatchClause> catchClauses2 = statement.catchClauses;
    EngineTestCase.assertSize(1, catchClauses2);
    CatchClause clause = catchClauses2[0];
    JUnitTestCase.assertNull(clause.onKeyword);
    JUnitTestCase.assertNull(clause.exceptionType);
    JUnitTestCase.assertNotNull(clause.catchKeyword);
    JUnitTestCase.assertNotNull(clause.exceptionParameter);
    JUnitTestCase.assertNull(clause.comma);
    JUnitTestCase.assertNull(clause.stackTraceParameter);
    JUnitTestCase.assertNotNull(clause.body);
    JUnitTestCase.assertNull(statement.finallyKeyword);
    JUnitTestCase.assertNull(statement.finallyClause);
  }
  void test_parseTryStatement_catch_finally() {
    TryStatement statement = ParserTestCase.parse5("parseTryStatement", "try {} catch (e, s) {} finally {}", []);
    JUnitTestCase.assertNotNull(statement.tryKeyword);
    JUnitTestCase.assertNotNull(statement.body);
    NodeList<CatchClause> catchClauses3 = statement.catchClauses;
    EngineTestCase.assertSize(1, catchClauses3);
    CatchClause clause = catchClauses3[0];
    JUnitTestCase.assertNull(clause.onKeyword);
    JUnitTestCase.assertNull(clause.exceptionType);
    JUnitTestCase.assertNotNull(clause.catchKeyword);
    JUnitTestCase.assertNotNull(clause.exceptionParameter);
    JUnitTestCase.assertNotNull(clause.comma);
    JUnitTestCase.assertNotNull(clause.stackTraceParameter);
    JUnitTestCase.assertNotNull(clause.body);
    JUnitTestCase.assertNotNull(statement.finallyKeyword);
    JUnitTestCase.assertNotNull(statement.finallyClause);
  }
  void test_parseTryStatement_finally() {
    TryStatement statement = ParserTestCase.parse5("parseTryStatement", "try {} finally {}", []);
    JUnitTestCase.assertNotNull(statement.tryKeyword);
    JUnitTestCase.assertNotNull(statement.body);
    EngineTestCase.assertSize(0, statement.catchClauses);
    JUnitTestCase.assertNotNull(statement.finallyKeyword);
    JUnitTestCase.assertNotNull(statement.finallyClause);
  }
  void test_parseTryStatement_multiple() {
    TryStatement statement = ParserTestCase.parse5("parseTryStatement", "try {} on NPE catch (e) {} on Error {} catch (e) {}", []);
    JUnitTestCase.assertNotNull(statement.tryKeyword);
    JUnitTestCase.assertNotNull(statement.body);
    EngineTestCase.assertSize(3, statement.catchClauses);
    JUnitTestCase.assertNull(statement.finallyKeyword);
    JUnitTestCase.assertNull(statement.finallyClause);
  }
  void test_parseTryStatement_on() {
    TryStatement statement = ParserTestCase.parse5("parseTryStatement", "try {} on Error {}", []);
    JUnitTestCase.assertNotNull(statement.tryKeyword);
    JUnitTestCase.assertNotNull(statement.body);
    NodeList<CatchClause> catchClauses4 = statement.catchClauses;
    EngineTestCase.assertSize(1, catchClauses4);
    CatchClause clause = catchClauses4[0];
    JUnitTestCase.assertNotNull(clause.onKeyword);
    JUnitTestCase.assertNotNull(clause.exceptionType);
    JUnitTestCase.assertNull(clause.catchKeyword);
    JUnitTestCase.assertNull(clause.exceptionParameter);
    JUnitTestCase.assertNull(clause.comma);
    JUnitTestCase.assertNull(clause.stackTraceParameter);
    JUnitTestCase.assertNotNull(clause.body);
    JUnitTestCase.assertNull(statement.finallyKeyword);
    JUnitTestCase.assertNull(statement.finallyClause);
  }
  void test_parseTryStatement_on_catch() {
    TryStatement statement = ParserTestCase.parse5("parseTryStatement", "try {} on Error catch (e, s) {}", []);
    JUnitTestCase.assertNotNull(statement.tryKeyword);
    JUnitTestCase.assertNotNull(statement.body);
    NodeList<CatchClause> catchClauses5 = statement.catchClauses;
    EngineTestCase.assertSize(1, catchClauses5);
    CatchClause clause = catchClauses5[0];
    JUnitTestCase.assertNotNull(clause.onKeyword);
    JUnitTestCase.assertNotNull(clause.exceptionType);
    JUnitTestCase.assertNotNull(clause.catchKeyword);
    JUnitTestCase.assertNotNull(clause.exceptionParameter);
    JUnitTestCase.assertNotNull(clause.comma);
    JUnitTestCase.assertNotNull(clause.stackTraceParameter);
    JUnitTestCase.assertNotNull(clause.body);
    JUnitTestCase.assertNull(statement.finallyKeyword);
    JUnitTestCase.assertNull(statement.finallyClause);
  }
  void test_parseTryStatement_on_catch_finally() {
    TryStatement statement = ParserTestCase.parse5("parseTryStatement", "try {} on Error catch (e, s) {} finally {}", []);
    JUnitTestCase.assertNotNull(statement.tryKeyword);
    JUnitTestCase.assertNotNull(statement.body);
    NodeList<CatchClause> catchClauses6 = statement.catchClauses;
    EngineTestCase.assertSize(1, catchClauses6);
    CatchClause clause = catchClauses6[0];
    JUnitTestCase.assertNotNull(clause.onKeyword);
    JUnitTestCase.assertNotNull(clause.exceptionType);
    JUnitTestCase.assertNotNull(clause.catchKeyword);
    JUnitTestCase.assertNotNull(clause.exceptionParameter);
    JUnitTestCase.assertNotNull(clause.comma);
    JUnitTestCase.assertNotNull(clause.stackTraceParameter);
    JUnitTestCase.assertNotNull(clause.body);
    JUnitTestCase.assertNotNull(statement.finallyKeyword);
    JUnitTestCase.assertNotNull(statement.finallyClause);
  }
  void test_parseTypeAlias_class_implementsC() {
    ClassTypeAlias typeAlias = ParserTestCase.parse("parseTypeAlias", <Object> [emptyCommentAndMetadata()], "typedef A = Object with B implements C;");
    JUnitTestCase.assertNotNull(typeAlias.keyword);
    JUnitTestCase.assertNotNull(typeAlias.name);
    JUnitTestCase.assertNull(typeAlias.typeParameters);
    JUnitTestCase.assertNotNull(typeAlias.withClause);
    JUnitTestCase.assertNotNull(typeAlias.implementsClause);
    JUnitTestCase.assertNotNull(typeAlias.implementsClause.keyword);
    JUnitTestCase.assertEquals(1, typeAlias.implementsClause.interfaces.length);
    JUnitTestCase.assertNotNull(typeAlias.semicolon);
  }
  void test_parseTypeAlias_class_withB() {
    ClassTypeAlias typeAlias = ParserTestCase.parse("parseTypeAlias", <Object> [emptyCommentAndMetadata()], "typedef A = Object with B;");
    JUnitTestCase.assertNotNull(typeAlias.keyword);
    JUnitTestCase.assertNotNull(typeAlias.name);
    JUnitTestCase.assertNull(typeAlias.typeParameters);
    JUnitTestCase.assertNotNull(typeAlias.withClause);
    JUnitTestCase.assertNotNull(typeAlias.withClause.withKeyword);
    JUnitTestCase.assertEquals(1, typeAlias.withClause.mixinTypes.length);
    JUnitTestCase.assertNull(typeAlias.implementsClause);
    JUnitTestCase.assertNotNull(typeAlias.semicolon);
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
    TypeArgumentList argumentList = ParserTestCase.parse5("parseTypeArgumentList", "<int, int, int>", []);
    JUnitTestCase.assertNotNull(argumentList.leftBracket);
    EngineTestCase.assertSize(3, argumentList.arguments);
    JUnitTestCase.assertNotNull(argumentList.rightBracket);
  }
  void test_parseTypeArgumentList_nested() {
    TypeArgumentList argumentList = ParserTestCase.parse5("parseTypeArgumentList", "<A<B>>", []);
    JUnitTestCase.assertNotNull(argumentList.leftBracket);
    EngineTestCase.assertSize(1, argumentList.arguments);
    TypeName argument = argumentList.arguments[0];
    JUnitTestCase.assertNotNull(argument);
    TypeArgumentList innerList = argument.typeArguments;
    JUnitTestCase.assertNotNull(innerList);
    EngineTestCase.assertSize(1, innerList.arguments);
    JUnitTestCase.assertNotNull(argumentList.rightBracket);
  }
  void test_parseTypeArgumentList_single() {
    TypeArgumentList argumentList = ParserTestCase.parse5("parseTypeArgumentList", "<int>", []);
    JUnitTestCase.assertNotNull(argumentList.leftBracket);
    EngineTestCase.assertSize(1, argumentList.arguments);
    JUnitTestCase.assertNotNull(argumentList.rightBracket);
  }
  void test_parseTypeName_parameterized() {
    TypeName typeName = ParserTestCase.parse5("parseTypeName", "List<int>", []);
    JUnitTestCase.assertNotNull(typeName.name);
    JUnitTestCase.assertNotNull(typeName.typeArguments);
  }
  void test_parseTypeName_simple() {
    TypeName typeName = ParserTestCase.parse5("parseTypeName", "int", []);
    JUnitTestCase.assertNotNull(typeName.name);
    JUnitTestCase.assertNull(typeName.typeArguments);
  }
  void test_parseTypeParameter_bounded() {
    TypeParameter parameter = ParserTestCase.parse5("parseTypeParameter", "A extends B", []);
    JUnitTestCase.assertNotNull(parameter.bound);
    JUnitTestCase.assertNotNull(parameter.keyword);
    JUnitTestCase.assertNotNull(parameter.name);
  }
  void test_parseTypeParameter_simple() {
    TypeParameter parameter = ParserTestCase.parse5("parseTypeParameter", "A", []);
    JUnitTestCase.assertNull(parameter.bound);
    JUnitTestCase.assertNull(parameter.keyword);
    JUnitTestCase.assertNotNull(parameter.name);
  }
  void test_parseTypeParameterList_multiple() {
    TypeParameterList parameterList = ParserTestCase.parse5("parseTypeParameterList", "<A, B extends C, D>", []);
    JUnitTestCase.assertNotNull(parameterList.leftBracket);
    JUnitTestCase.assertNotNull(parameterList.rightBracket);
    EngineTestCase.assertSize(3, parameterList.typeParameters);
  }
  void test_parseTypeParameterList_parameterizedWithTrailingEquals() {
    TypeParameterList parameterList = ParserTestCase.parse5("parseTypeParameterList", "<A extends B<E>>=", []);
    JUnitTestCase.assertNotNull(parameterList.leftBracket);
    JUnitTestCase.assertNotNull(parameterList.rightBracket);
    EngineTestCase.assertSize(1, parameterList.typeParameters);
  }
  void test_parseTypeParameterList_single() {
    TypeParameterList parameterList = ParserTestCase.parse5("parseTypeParameterList", "<A>", []);
    JUnitTestCase.assertNotNull(parameterList.leftBracket);
    JUnitTestCase.assertNotNull(parameterList.rightBracket);
    EngineTestCase.assertSize(1, parameterList.typeParameters);
  }
  void test_parseTypeParameterList_withTrailingEquals() {
    TypeParameterList parameterList = ParserTestCase.parse5("parseTypeParameterList", "<A>=", []);
    JUnitTestCase.assertNotNull(parameterList.leftBracket);
    JUnitTestCase.assertNotNull(parameterList.rightBracket);
    EngineTestCase.assertSize(1, parameterList.typeParameters);
  }
  void test_parseUnaryExpression_decrement_normal() {
    PrefixExpression expression = ParserTestCase.parse5("parseUnaryExpression", "--x", []);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.MINUS_MINUS, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.operand);
  }
  void test_parseUnaryExpression_decrement_super() {
    PrefixExpression expression = ParserTestCase.parse5("parseUnaryExpression", "--super", []);
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
    PrefixExpression expression = ParserTestCase.parse5("parseUnaryExpression", "--super.x", []);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.MINUS_MINUS, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.operand);
    PropertyAccess operand4 = expression.operand as PropertyAccess;
    JUnitTestCase.assertTrue(operand4.target is SuperExpression);
    JUnitTestCase.assertEquals("x", operand4.propertyName.name);
  }
  void test_parseUnaryExpression_increment_normal() {
    PrefixExpression expression = ParserTestCase.parse5("parseUnaryExpression", "++x", []);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.PLUS_PLUS, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.operand);
  }
  void test_parseUnaryExpression_increment_super_index() {
    PrefixExpression expression = ParserTestCase.parse5("parseUnaryExpression", "++super[0]", []);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.PLUS_PLUS, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.operand);
    IndexExpression operand5 = expression.operand as IndexExpression;
    JUnitTestCase.assertTrue(operand5.realTarget is SuperExpression);
    JUnitTestCase.assertTrue(operand5.index is IntegerLiteral);
  }
  void test_parseUnaryExpression_increment_super_propertyAccess() {
    PrefixExpression expression = ParserTestCase.parse5("parseUnaryExpression", "++super.x", []);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.PLUS_PLUS, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.operand);
    PropertyAccess operand6 = expression.operand as PropertyAccess;
    JUnitTestCase.assertTrue(operand6.target is SuperExpression);
    JUnitTestCase.assertEquals("x", operand6.propertyName.name);
  }
  void test_parseUnaryExpression_minus_normal() {
    PrefixExpression expression = ParserTestCase.parse5("parseUnaryExpression", "-x", []);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.MINUS, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.operand);
  }
  void test_parseUnaryExpression_minus_super() {
    PrefixExpression expression = ParserTestCase.parse5("parseUnaryExpression", "-super", []);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.MINUS, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.operand);
  }
  void test_parseUnaryExpression_not_normal() {
    PrefixExpression expression = ParserTestCase.parse5("parseUnaryExpression", "!x", []);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.BANG, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.operand);
  }
  void test_parseUnaryExpression_not_super() {
    PrefixExpression expression = ParserTestCase.parse5("parseUnaryExpression", "!super", []);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.BANG, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.operand);
  }
  void test_parseUnaryExpression_tilda_normal() {
    PrefixExpression expression = ParserTestCase.parse5("parseUnaryExpression", "~x", []);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.TILDE, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.operand);
  }
  void test_parseUnaryExpression_tilda_super() {
    PrefixExpression expression = ParserTestCase.parse5("parseUnaryExpression", "~super", []);
    JUnitTestCase.assertNotNull(expression.operator);
    JUnitTestCase.assertEquals(TokenType.TILDE, expression.operator.type);
    JUnitTestCase.assertNotNull(expression.operand);
  }
  void test_parseVariableDeclaration_equals() {
    VariableDeclaration declaration = ParserTestCase.parse5("parseVariableDeclaration", "a = b", []);
    JUnitTestCase.assertNotNull(declaration.name);
    JUnitTestCase.assertNotNull(declaration.equals);
    JUnitTestCase.assertNotNull(declaration.initializer);
  }
  void test_parseVariableDeclaration_noEquals() {
    VariableDeclaration declaration = ParserTestCase.parse5("parseVariableDeclaration", "a", []);
    JUnitTestCase.assertNotNull(declaration.name);
    JUnitTestCase.assertNull(declaration.equals);
    JUnitTestCase.assertNull(declaration.initializer);
  }
  void test_parseVariableDeclarationList_const_noType() {
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationList", <Object> [emptyCommentAndMetadata()], "const a");
    JUnitTestCase.assertNotNull(declarationList.keyword);
    JUnitTestCase.assertNull(declarationList.type);
    EngineTestCase.assertSize(1, declarationList.variables);
  }
  void test_parseVariableDeclarationList_const_type() {
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationList", <Object> [emptyCommentAndMetadata()], "const A a");
    JUnitTestCase.assertNotNull(declarationList.keyword);
    JUnitTestCase.assertNotNull(declarationList.type);
    EngineTestCase.assertSize(1, declarationList.variables);
  }
  void test_parseVariableDeclarationList_final_noType() {
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationList", <Object> [emptyCommentAndMetadata()], "final a");
    JUnitTestCase.assertNotNull(declarationList.keyword);
    JUnitTestCase.assertNull(declarationList.type);
    EngineTestCase.assertSize(1, declarationList.variables);
  }
  void test_parseVariableDeclarationList_final_type() {
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationList", <Object> [emptyCommentAndMetadata()], "final A a");
    JUnitTestCase.assertNotNull(declarationList.keyword);
    JUnitTestCase.assertNotNull(declarationList.type);
    EngineTestCase.assertSize(1, declarationList.variables);
  }
  void test_parseVariableDeclarationList_type_multiple() {
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationList", <Object> [emptyCommentAndMetadata()], "A a, b, c");
    JUnitTestCase.assertNull(declarationList.keyword);
    JUnitTestCase.assertNotNull(declarationList.type);
    EngineTestCase.assertSize(3, declarationList.variables);
  }
  void test_parseVariableDeclarationList_type_single() {
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationList", <Object> [emptyCommentAndMetadata()], "A a");
    JUnitTestCase.assertNull(declarationList.keyword);
    JUnitTestCase.assertNotNull(declarationList.type);
    EngineTestCase.assertSize(1, declarationList.variables);
  }
  void test_parseVariableDeclarationList_var_multiple() {
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationList", <Object> [emptyCommentAndMetadata()], "var a, b, c");
    JUnitTestCase.assertNotNull(declarationList.keyword);
    JUnitTestCase.assertNull(declarationList.type);
    EngineTestCase.assertSize(3, declarationList.variables);
  }
  void test_parseVariableDeclarationList_var_single() {
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationList", <Object> [emptyCommentAndMetadata()], "var a");
    JUnitTestCase.assertNotNull(declarationList.keyword);
    JUnitTestCase.assertNull(declarationList.type);
    EngineTestCase.assertSize(1, declarationList.variables);
  }
  void test_parseVariableDeclarationList2_type() {
    TypeName type = new TypeName.full(new SimpleIdentifier.full(null), null);
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationList", <Object> [emptyCommentAndMetadata(), null, type], "a");
    JUnitTestCase.assertNull(declarationList.keyword);
    JUnitTestCase.assertEquals(type, declarationList.type);
    EngineTestCase.assertSize(1, declarationList.variables);
  }
  void test_parseVariableDeclarationList2_var() {
    Token keyword = TokenFactory.token(Keyword.VAR);
    VariableDeclarationList declarationList = ParserTestCase.parse("parseVariableDeclarationList", <Object> [emptyCommentAndMetadata(), keyword, null], "a, b, c");
    JUnitTestCase.assertEquals(keyword, declarationList.keyword);
    JUnitTestCase.assertNull(declarationList.type);
    EngineTestCase.assertSize(3, declarationList.variables);
  }
  void test_parseVariableDeclarationStatement_multiple() {
    VariableDeclarationStatement statement = ParserTestCase.parse("parseVariableDeclarationStatement", <Object> [emptyCommentAndMetadata()], "var x, y, z;");
    JUnitTestCase.assertNotNull(statement.semicolon);
    VariableDeclarationList variableList = statement.variables;
    JUnitTestCase.assertNotNull(variableList);
    EngineTestCase.assertSize(3, variableList.variables);
  }
  void test_parseVariableDeclarationStatement_single() {
    VariableDeclarationStatement statement = ParserTestCase.parse("parseVariableDeclarationStatement", <Object> [emptyCommentAndMetadata()], "var x;");
    JUnitTestCase.assertNotNull(statement.semicolon);
    VariableDeclarationList variableList = statement.variables;
    JUnitTestCase.assertNotNull(variableList);
    EngineTestCase.assertSize(1, variableList.variables);
  }
  void test_parseWhileStatement() {
    WhileStatement statement = ParserTestCase.parse5("parseWhileStatement", "while (x) {}", []);
    JUnitTestCase.assertNotNull(statement.keyword);
    JUnitTestCase.assertNotNull(statement.leftParenthesis);
    JUnitTestCase.assertNotNull(statement.condition);
    JUnitTestCase.assertNotNull(statement.rightParenthesis);
    JUnitTestCase.assertNotNull(statement.body);
  }
  void test_parseWithClause_multiple() {
    WithClause clause = ParserTestCase.parse5("parseWithClause", "with A, B, C", []);
    JUnitTestCase.assertNotNull(clause.withKeyword);
    EngineTestCase.assertSize(3, clause.mixinTypes);
  }
  void test_parseWithClause_single() {
    WithClause clause = ParserTestCase.parse5("parseWithClause", "with M", []);
    JUnitTestCase.assertNotNull(clause.withKeyword);
    EngineTestCase.assertSize(1, clause.mixinTypes);
  }
  void test_skipPrefixedIdentifier_invalid() {
    Token following = skip("skipPrefixedIdentifier", "+");
    JUnitTestCase.assertNull(following);
  }
  void test_skipPrefixedIdentifier_notPrefixed() {
    Token following = skip("skipPrefixedIdentifier", "a +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }
  void test_skipPrefixedIdentifier_prefixed() {
    Token following = skip("skipPrefixedIdentifier", "a.b +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }
  void test_skipReturnType_invalid() {
    Token following = skip("skipReturnType", "+");
    JUnitTestCase.assertNull(following);
  }
  void test_skipReturnType_type() {
    Token following = skip("skipReturnType", "C +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }
  void test_skipReturnType_void() {
    Token following = skip("skipReturnType", "void +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }
  void test_skipSimpleIdentifier_identifier() {
    Token following = skip("skipSimpleIdentifier", "i +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }
  void test_skipSimpleIdentifier_invalid() {
    Token following = skip("skipSimpleIdentifier", "9 +");
    JUnitTestCase.assertNull(following);
  }
  void test_skipSimpleIdentifier_pseudoKeyword() {
    Token following = skip("skipSimpleIdentifier", "as +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }
  void test_skipStringLiteral_adjacent() {
    Token following = skip("skipStringLiteral", "'a' 'b' +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }
  void test_skipStringLiteral_interpolated() {
    Token following = skip("skipStringLiteral", "'a\${b}c' +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }
  void test_skipStringLiteral_invalid() {
    Token following = skip("skipStringLiteral", "a");
    JUnitTestCase.assertNull(following);
  }
  void test_skipStringLiteral_single() {
    Token following = skip("skipStringLiteral", "'a' +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }
  void test_skipTypeArgumentList_invalid() {
    Token following = skip("skipTypeArgumentList", "+");
    JUnitTestCase.assertNull(following);
  }
  void test_skipTypeArgumentList_multiple() {
    Token following = skip("skipTypeArgumentList", "<E, F, G> +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }
  void test_skipTypeArgumentList_single() {
    Token following = skip("skipTypeArgumentList", "<E> +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }
  void test_skipTypeName_invalid() {
    Token following = skip("skipTypeName", "+");
    JUnitTestCase.assertNull(following);
  }
  void test_skipTypeName_parameterized() {
    Token following = skip("skipTypeName", "C<E<F<G>>> +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }
  void test_skipTypeName_simple() {
    Token following = skip("skipTypeName", "C +");
    JUnitTestCase.assertNotNull(following);
    JUnitTestCase.assertEquals(TokenType.PLUS, following.type);
  }
  /**
   * Invoke the method {@link Parser#computeStringValue(String)} with the given argument.
   * @param lexeme the argument to the method
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   */
  String computeStringValue(String lexeme) {
    AnalysisErrorListener listener = new AnalysisErrorListener_19();
    Parser parser = new Parser(null, listener);
    return invokeParserMethodImpl(parser, "computeStringValue", <Object> [lexeme], null) as String;
  }
  /**
   * Invoke the method {@link Parser#createSyntheticIdentifier()} with the parser set to the token
   * stream produced by scanning the given source.
   * @param source the source to be scanned to produce the token stream being tested
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   */
  SimpleIdentifier createSyntheticIdentifier() {
    GatheringErrorListener listener = new GatheringErrorListener();
    return ParserTestCase.invokeParserMethod2("createSyntheticIdentifier", "", listener);
  }
  /**
   * Invoke the method {@link Parser#createSyntheticIdentifier()} with the parser set to the token
   * stream produced by scanning the given source.
   * @param source the source to be scanned to produce the token stream being tested
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   */
  SimpleStringLiteral createSyntheticStringLiteral() {
    GatheringErrorListener listener = new GatheringErrorListener();
    return ParserTestCase.invokeParserMethod2("createSyntheticStringLiteral", "", listener);
  }
  /**
   * Invoke the method {@link Parser#isFunctionDeclaration()} with the parser set to the token
   * stream produced by scanning the given source.
   * @param source the source to be scanned to produce the token stream being tested
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   */
  bool isFunctionDeclaration(String source) {
    GatheringErrorListener listener = new GatheringErrorListener();
    return ParserTestCase.invokeParserMethod2("isFunctionDeclaration", source, listener) as bool;
  }
  /**
   * Invoke the method {@link Parser#isFunctionExpression()} with the parser set to the token stream
   * produced by scanning the given source.
   * @param source the source to be scanned to produce the token stream being tested
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   */
  bool isFunctionExpression(String source) {
    GatheringErrorListener listener = new GatheringErrorListener();
    StringScanner scanner = new StringScanner(null, source, listener);
    Token tokenStream = scanner.tokenize();
    Parser parser = new Parser(null, listener);
    return invokeParserMethodImpl(parser, "isFunctionExpression", <Object> [tokenStream], tokenStream) as bool;
  }
  /**
   * Invoke the method {@link Parser#isInitializedVariableDeclaration()} with the parser set to the
   * token stream produced by scanning the given source.
   * @param source the source to be scanned to produce the token stream being tested
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   */
  bool isInitializedVariableDeclaration(String source) {
    GatheringErrorListener listener = new GatheringErrorListener();
    return ParserTestCase.invokeParserMethod2("isInitializedVariableDeclaration", source, listener) as bool;
  }
  /**
   * Invoke the method {@link Parser#isSwitchMember()} with the parser set to the token stream
   * produced by scanning the given source.
   * @param source the source to be scanned to produce the token stream being tested
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   */
  bool isSwitchMember(String source) {
    GatheringErrorListener listener = new GatheringErrorListener();
    return ParserTestCase.invokeParserMethod2("isSwitchMember", source, listener) as bool;
  }
  /**
   * Invoke a "skip" method in {@link Parser}. The method is assumed to take a token as it's
   * parameter and is given the first token in the scanned source.
   * @param methodName the name of the method that should be invoked
   * @param source the source to be processed by the method
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   * @throws AssertionFailedError if the result is {@code null}
   */
  Token skip(String methodName, String source) {
    GatheringErrorListener listener = new GatheringErrorListener();
    StringScanner scanner = new StringScanner(null, source, listener);
    Token tokenStream = scanner.tokenize();
    Parser parser = new Parser(null, listener);
    return invokeParserMethodImpl(parser, methodName, <Object> [tokenStream], tokenStream) as Token;
  }
  static dartSuite() {
    _ut.group('SimpleParserTest', () {
      _ut.test('test_Parser', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_Parser);
      });
      _ut.test('test_computeStringValue_emptyInterpolationPrefix', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_computeStringValue_emptyInterpolationPrefix);
      });
      _ut.test('test_computeStringValue_escape_b', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_computeStringValue_escape_b);
      });
      _ut.test('test_computeStringValue_escape_f', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_computeStringValue_escape_f);
      });
      _ut.test('test_computeStringValue_escape_n', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_computeStringValue_escape_n);
      });
      _ut.test('test_computeStringValue_escape_notSpecial', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_computeStringValue_escape_notSpecial);
      });
      _ut.test('test_computeStringValue_escape_r', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_computeStringValue_escape_r);
      });
      _ut.test('test_computeStringValue_escape_t', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_computeStringValue_escape_t);
      });
      _ut.test('test_computeStringValue_escape_u_fixed', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_computeStringValue_escape_u_fixed);
      });
      _ut.test('test_computeStringValue_escape_u_variable', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_computeStringValue_escape_u_variable);
      });
      _ut.test('test_computeStringValue_escape_v', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_computeStringValue_escape_v);
      });
      _ut.test('test_computeStringValue_escape_x', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_computeStringValue_escape_x);
      });
      _ut.test('test_computeStringValue_noEscape_single', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_computeStringValue_noEscape_single);
      });
      _ut.test('test_computeStringValue_noEscape_triple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_computeStringValue_noEscape_triple);
      });
      _ut.test('test_computeStringValue_raw_single', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_computeStringValue_raw_single);
      });
      _ut.test('test_computeStringValue_raw_triple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_computeStringValue_raw_triple);
      });
      _ut.test('test_computeStringValue_raw_withEscape', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_computeStringValue_raw_withEscape);
      });
      _ut.test('test_createSyntheticIdentifier', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_createSyntheticIdentifier);
      });
      _ut.test('test_createSyntheticStringLiteral', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_createSyntheticStringLiteral);
      });
      _ut.test('test_isFunctionDeclaration_nameButNoReturn_block', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isFunctionDeclaration_nameButNoReturn_block);
      });
      _ut.test('test_isFunctionDeclaration_nameButNoReturn_expression', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isFunctionDeclaration_nameButNoReturn_expression);
      });
      _ut.test('test_isFunctionDeclaration_normalReturn_block', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isFunctionDeclaration_normalReturn_block);
      });
      _ut.test('test_isFunctionDeclaration_normalReturn_expression', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isFunctionDeclaration_normalReturn_expression);
      });
      _ut.test('test_isFunctionDeclaration_voidReturn_block', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isFunctionDeclaration_voidReturn_block);
      });
      _ut.test('test_isFunctionDeclaration_voidReturn_expression', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isFunctionDeclaration_voidReturn_expression);
      });
      _ut.test('test_isFunctionExpression_false_noBody', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isFunctionExpression_false_noBody);
      });
      _ut.test('test_isFunctionExpression_false_notParameters', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isFunctionExpression_false_notParameters);
      });
      _ut.test('test_isFunctionExpression_noName_block', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isFunctionExpression_noName_block);
      });
      _ut.test('test_isFunctionExpression_noName_expression', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isFunctionExpression_noName_expression);
      });
      _ut.test('test_isFunctionExpression_parameter_multiple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isFunctionExpression_parameter_multiple);
      });
      _ut.test('test_isFunctionExpression_parameter_named', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isFunctionExpression_parameter_named);
      });
      _ut.test('test_isFunctionExpression_parameter_optional', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isFunctionExpression_parameter_optional);
      });
      _ut.test('test_isFunctionExpression_parameter_single', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isFunctionExpression_parameter_single);
      });
      _ut.test('test_isFunctionExpression_parameter_typed', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isFunctionExpression_parameter_typed);
      });
      _ut.test('test_isInitializedVariableDeclaration_assignment', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isInitializedVariableDeclaration_assignment);
      });
      _ut.test('test_isInitializedVariableDeclaration_comparison', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isInitializedVariableDeclaration_comparison);
      });
      _ut.test('test_isInitializedVariableDeclaration_conditional', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isInitializedVariableDeclaration_conditional);
      });
      _ut.test('test_isInitializedVariableDeclaration_const_noType_initialized', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isInitializedVariableDeclaration_const_noType_initialized);
      });
      _ut.test('test_isInitializedVariableDeclaration_const_noType_uninitialized', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isInitializedVariableDeclaration_const_noType_uninitialized);
      });
      _ut.test('test_isInitializedVariableDeclaration_const_simpleType_uninitialized', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isInitializedVariableDeclaration_const_simpleType_uninitialized);
      });
      _ut.test('test_isInitializedVariableDeclaration_final_noType_initialized', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isInitializedVariableDeclaration_final_noType_initialized);
      });
      _ut.test('test_isInitializedVariableDeclaration_final_noType_uninitialized', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isInitializedVariableDeclaration_final_noType_uninitialized);
      });
      _ut.test('test_isInitializedVariableDeclaration_final_simpleType_initialized', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isInitializedVariableDeclaration_final_simpleType_initialized);
      });
      _ut.test('test_isInitializedVariableDeclaration_functionDeclaration_typed', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isInitializedVariableDeclaration_functionDeclaration_typed);
      });
      _ut.test('test_isInitializedVariableDeclaration_functionDeclaration_untyped', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isInitializedVariableDeclaration_functionDeclaration_untyped);
      });
      _ut.test('test_isInitializedVariableDeclaration_noType_initialized', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isInitializedVariableDeclaration_noType_initialized);
      });
      _ut.test('test_isInitializedVariableDeclaration_noType_uninitialized', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isInitializedVariableDeclaration_noType_uninitialized);
      });
      _ut.test('test_isInitializedVariableDeclaration_parameterizedType_initialized', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isInitializedVariableDeclaration_parameterizedType_initialized);
      });
      _ut.test('test_isInitializedVariableDeclaration_parameterizedType_uninitialized', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isInitializedVariableDeclaration_parameterizedType_uninitialized);
      });
      _ut.test('test_isInitializedVariableDeclaration_simpleType_initialized', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isInitializedVariableDeclaration_simpleType_initialized);
      });
      _ut.test('test_isInitializedVariableDeclaration_simpleType_uninitialized', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isInitializedVariableDeclaration_simpleType_uninitialized);
      });
      _ut.test('test_isSwitchMember_case_labeled', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isSwitchMember_case_labeled);
      });
      _ut.test('test_isSwitchMember_case_unlabeled', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isSwitchMember_case_unlabeled);
      });
      _ut.test('test_isSwitchMember_default_labeled', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isSwitchMember_default_labeled);
      });
      _ut.test('test_isSwitchMember_default_unlabeled', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isSwitchMember_default_unlabeled);
      });
      _ut.test('test_isSwitchMember_false', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_isSwitchMember_false);
      });
      _ut.test('test_parseAdditiveExpression_normal', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseAdditiveExpression_normal);
      });
      _ut.test('test_parseAdditiveExpression_super', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseAdditiveExpression_super);
      });
      _ut.test('test_parseAnnotation_n1', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseAnnotation_n1);
      });
      _ut.test('test_parseAnnotation_n1_a', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseAnnotation_n1_a);
      });
      _ut.test('test_parseAnnotation_n2', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseAnnotation_n2);
      });
      _ut.test('test_parseAnnotation_n2_a', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseAnnotation_n2_a);
      });
      _ut.test('test_parseAnnotation_n3', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseAnnotation_n3);
      });
      _ut.test('test_parseAnnotation_n3_a', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseAnnotation_n3_a);
      });
      _ut.test('test_parseArgumentDefinitionTest', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseArgumentDefinitionTest);
      });
      _ut.test('test_parseArgumentList_empty', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseArgumentList_empty);
      });
      _ut.test('test_parseArgumentList_mixed', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseArgumentList_mixed);
      });
      _ut.test('test_parseArgumentList_noNamed', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseArgumentList_noNamed);
      });
      _ut.test('test_parseArgumentList_onlyNamed', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseArgumentList_onlyNamed);
      });
      _ut.test('test_parseArgument_named', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseArgument_named);
      });
      _ut.test('test_parseArgument_unnamed', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseArgument_unnamed);
      });
      _ut.test('test_parseAssertStatement', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseAssertStatement);
      });
      _ut.test('test_parseAssignableExpression_expression_args_dot', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseAssignableExpression_expression_args_dot);
      });
      _ut.test('test_parseAssignableExpression_expression_dot', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseAssignableExpression_expression_dot);
      });
      _ut.test('test_parseAssignableExpression_expression_index', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseAssignableExpression_expression_index);
      });
      _ut.test('test_parseAssignableExpression_identifier', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseAssignableExpression_identifier);
      });
      _ut.test('test_parseAssignableExpression_identifier_args_dot', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseAssignableExpression_identifier_args_dot);
      });
      _ut.test('test_parseAssignableExpression_identifier_dot', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseAssignableExpression_identifier_dot);
      });
      _ut.test('test_parseAssignableExpression_identifier_index', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseAssignableExpression_identifier_index);
      });
      _ut.test('test_parseAssignableExpression_super_dot', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseAssignableExpression_super_dot);
      });
      _ut.test('test_parseAssignableExpression_super_index', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseAssignableExpression_super_index);
      });
      _ut.test('test_parseAssignableSelector_dot', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseAssignableSelector_dot);
      });
      _ut.test('test_parseAssignableSelector_index', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseAssignableSelector_index);
      });
      _ut.test('test_parseAssignableSelector_none', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseAssignableSelector_none);
      });
      _ut.test('test_parseBitwiseAndExpression_normal', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseBitwiseAndExpression_normal);
      });
      _ut.test('test_parseBitwiseAndExpression_super', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseBitwiseAndExpression_super);
      });
      _ut.test('test_parseBitwiseOrExpression_normal', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseBitwiseOrExpression_normal);
      });
      _ut.test('test_parseBitwiseOrExpression_super', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseBitwiseOrExpression_super);
      });
      _ut.test('test_parseBitwiseXorExpression_normal', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseBitwiseXorExpression_normal);
      });
      _ut.test('test_parseBitwiseXorExpression_super', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseBitwiseXorExpression_super);
      });
      _ut.test('test_parseBlock_empty', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseBlock_empty);
      });
      _ut.test('test_parseBlock_nonEmpty', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseBlock_nonEmpty);
      });
      _ut.test('test_parseBreakStatement_label', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseBreakStatement_label);
      });
      _ut.test('test_parseBreakStatement_noLabel', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseBreakStatement_noLabel);
      });
      _ut.test('test_parseCascadeSection_i', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCascadeSection_i);
      });
      _ut.test('test_parseCascadeSection_ia', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCascadeSection_ia);
      });
      _ut.test('test_parseCascadeSection_p', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCascadeSection_p);
      });
      _ut.test('test_parseCascadeSection_p_assign', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCascadeSection_p_assign);
      });
      _ut.test('test_parseCascadeSection_p_assign_withCascade', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCascadeSection_p_assign_withCascade);
      });
      _ut.test('test_parseCascadeSection_p_builtIn', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCascadeSection_p_builtIn);
      });
      _ut.test('test_parseCascadeSection_pa', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCascadeSection_pa);
      });
      _ut.test('test_parseCascadeSection_paa', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCascadeSection_paa);
      });
      _ut.test('test_parseCascadeSection_paapaa', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCascadeSection_paapaa);
      });
      _ut.test('test_parseCascadeSection_pap', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCascadeSection_pap);
      });
      _ut.test('test_parseClassDeclaration_abstract', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassDeclaration_abstract);
      });
      _ut.test('test_parseClassDeclaration_empty', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassDeclaration_empty);
      });
      _ut.test('test_parseClassDeclaration_extends', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassDeclaration_extends);
      });
      _ut.test('test_parseClassDeclaration_extendsAndImplements', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassDeclaration_extendsAndImplements);
      });
      _ut.test('test_parseClassDeclaration_extendsAndWith', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassDeclaration_extendsAndWith);
      });
      _ut.test('test_parseClassDeclaration_extendsAndWithAndImplements', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassDeclaration_extendsAndWithAndImplements);
      });
      _ut.test('test_parseClassDeclaration_implements', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassDeclaration_implements);
      });
      _ut.test('test_parseClassDeclaration_nonEmpty', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassDeclaration_nonEmpty);
      });
      _ut.test('test_parseClassDeclaration_typeParameters', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassDeclaration_typeParameters);
      });
      _ut.test('test_parseClassMember_constructor_withInitializers', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassMember_constructor_withInitializers);
      });
      _ut.test('test_parseClassMember_field_instance_prefixedType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassMember_field_instance_prefixedType);
      });
      _ut.test('test_parseClassMember_field_namedGet', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassMember_field_namedGet);
      });
      _ut.test('test_parseClassMember_field_namedOperator', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassMember_field_namedOperator);
      });
      _ut.test('test_parseClassMember_field_namedSet', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassMember_field_namedSet);
      });
      _ut.test('test_parseClassMember_getter_void', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassMember_getter_void);
      });
      _ut.test('test_parseClassMember_method_external', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassMember_method_external);
      });
      _ut.test('test_parseClassMember_method_external_withTypeAndArgs', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassMember_method_external_withTypeAndArgs);
      });
      _ut.test('test_parseClassMember_method_get_noType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassMember_method_get_noType);
      });
      _ut.test('test_parseClassMember_method_get_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassMember_method_get_type);
      });
      _ut.test('test_parseClassMember_method_get_void', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassMember_method_get_void);
      });
      _ut.test('test_parseClassMember_method_operator_noType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassMember_method_operator_noType);
      });
      _ut.test('test_parseClassMember_method_operator_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassMember_method_operator_type);
      });
      _ut.test('test_parseClassMember_method_operator_void', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassMember_method_operator_void);
      });
      _ut.test('test_parseClassMember_method_returnType_parameterized', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassMember_method_returnType_parameterized);
      });
      _ut.test('test_parseClassMember_method_set_noType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassMember_method_set_noType);
      });
      _ut.test('test_parseClassMember_method_set_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassMember_method_set_type);
      });
      _ut.test('test_parseClassMember_method_set_void', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassMember_method_set_void);
      });
      _ut.test('test_parseClassMember_operator_index', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassMember_operator_index);
      });
      _ut.test('test_parseClassMember_operator_indexAssign', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassMember_operator_indexAssign);
      });
      _ut.test('test_parseClassMember_redirectingFactory_const', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassMember_redirectingFactory_const);
      });
      _ut.test('test_parseClassMember_redirectingFactory_nonConst', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassMember_redirectingFactory_nonConst);
      });
      _ut.test('test_parseClassTypeAlias', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassTypeAlias);
      });
      _ut.test('test_parseClassTypeAlias_abstract', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassTypeAlias_abstract);
      });
      _ut.test('test_parseClassTypeAlias_implements', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassTypeAlias_implements);
      });
      _ut.test('test_parseClassTypeAlias_with', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassTypeAlias_with);
      });
      _ut.test('test_parseClassTypeAlias_with_implements', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseClassTypeAlias_with_implements);
      });
      _ut.test('test_parseCombinators_h', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCombinators_h);
      });
      _ut.test('test_parseCombinators_hs', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCombinators_hs);
      });
      _ut.test('test_parseCombinators_hshs', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCombinators_hshs);
      });
      _ut.test('test_parseCombinators_s', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCombinators_s);
      });
      _ut.test('test_parseCommentAndMetadata_c', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCommentAndMetadata_c);
      });
      _ut.test('test_parseCommentAndMetadata_cmc', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCommentAndMetadata_cmc);
      });
      _ut.test('test_parseCommentAndMetadata_cmcm', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCommentAndMetadata_cmcm);
      });
      _ut.test('test_parseCommentAndMetadata_cmm', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCommentAndMetadata_cmm);
      });
      _ut.test('test_parseCommentAndMetadata_m', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCommentAndMetadata_m);
      });
      _ut.test('test_parseCommentAndMetadata_mcm', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCommentAndMetadata_mcm);
      });
      _ut.test('test_parseCommentAndMetadata_mcmc', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCommentAndMetadata_mcmc);
      });
      _ut.test('test_parseCommentAndMetadata_mm', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCommentAndMetadata_mm);
      });
      _ut.test('test_parseCommentAndMetadata_none', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCommentAndMetadata_none);
      });
      _ut.test('test_parseCommentReference_new_prefixed', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCommentReference_new_prefixed);
      });
      _ut.test('test_parseCommentReference_new_simple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCommentReference_new_simple);
      });
      _ut.test('test_parseCommentReference_prefixed', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCommentReference_prefixed);
      });
      _ut.test('test_parseCommentReference_simple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCommentReference_simple);
      });
      _ut.test('test_parseCommentReferences_multiLine', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCommentReferences_multiLine);
      });
      _ut.test('test_parseCommentReferences_singleLine', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCommentReferences_singleLine);
      });
      _ut.test('test_parseCompilationUnitMember_abstractAsPrefix', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnitMember_abstractAsPrefix);
      });
      _ut.test('test_parseCompilationUnitMember_class', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnitMember_class);
      });
      _ut.test('test_parseCompilationUnitMember_constVariable', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnitMember_constVariable);
      });
      _ut.test('test_parseCompilationUnitMember_finalVariable', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnitMember_finalVariable);
      });
      _ut.test('test_parseCompilationUnitMember_function_external_noType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnitMember_function_external_noType);
      });
      _ut.test('test_parseCompilationUnitMember_function_external_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnitMember_function_external_type);
      });
      _ut.test('test_parseCompilationUnitMember_function_noType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnitMember_function_noType);
      });
      _ut.test('test_parseCompilationUnitMember_function_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnitMember_function_type);
      });
      _ut.test('test_parseCompilationUnitMember_function_void', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnitMember_function_void);
      });
      _ut.test('test_parseCompilationUnitMember_getter_external_noType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnitMember_getter_external_noType);
      });
      _ut.test('test_parseCompilationUnitMember_getter_external_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnitMember_getter_external_type);
      });
      _ut.test('test_parseCompilationUnitMember_getter_noType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnitMember_getter_noType);
      });
      _ut.test('test_parseCompilationUnitMember_getter_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnitMember_getter_type);
      });
      _ut.test('test_parseCompilationUnitMember_setter_external_noType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnitMember_setter_external_noType);
      });
      _ut.test('test_parseCompilationUnitMember_setter_external_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnitMember_setter_external_type);
      });
      _ut.test('test_parseCompilationUnitMember_setter_noType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnitMember_setter_noType);
      });
      _ut.test('test_parseCompilationUnitMember_setter_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnitMember_setter_type);
      });
      _ut.test('test_parseCompilationUnitMember_typedef_class_abstract', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnitMember_typedef_class_abstract);
      });
      _ut.test('test_parseCompilationUnitMember_typedef_class_generic', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnitMember_typedef_class_generic);
      });
      _ut.test('test_parseCompilationUnitMember_typedef_class_implements', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnitMember_typedef_class_implements);
      });
      _ut.test('test_parseCompilationUnitMember_typedef_class_noImplements', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnitMember_typedef_class_noImplements);
      });
      _ut.test('test_parseCompilationUnitMember_typedef_function', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnitMember_typedef_function);
      });
      _ut.test('test_parseCompilationUnitMember_variable', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnitMember_variable);
      });
      _ut.test('test_parseCompilationUnit_abstractAsPrefix_parameterized', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnit_abstractAsPrefix_parameterized);
      });
      _ut.test('test_parseCompilationUnit_directives_multiple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnit_directives_multiple);
      });
      _ut.test('test_parseCompilationUnit_directives_single', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnit_directives_single);
      });
      _ut.test('test_parseCompilationUnit_empty', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnit_empty);
      });
      _ut.test('test_parseCompilationUnit_exportAsPrefix', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnit_exportAsPrefix);
      });
      _ut.test('test_parseCompilationUnit_exportAsPrefix_parameterized', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnit_exportAsPrefix_parameterized);
      });
      _ut.test('test_parseCompilationUnit_operatorAsPrefix_parameterized', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnit_operatorAsPrefix_parameterized);
      });
      _ut.test('test_parseCompilationUnit_script', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnit_script);
      });
      _ut.test('test_parseCompilationUnit_topLevelDeclaration', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnit_topLevelDeclaration);
      });
      _ut.test('test_parseCompilationUnit_typedefAsPrefix', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseCompilationUnit_typedefAsPrefix);
      });
      _ut.test('test_parseConditionalExpression', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseConditionalExpression);
      });
      _ut.test('test_parseConstExpression_instanceCreation', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseConstExpression_instanceCreation);
      });
      _ut.test('test_parseConstExpression_listLiteral_typed', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseConstExpression_listLiteral_typed);
      });
      _ut.test('test_parseConstExpression_listLiteral_untyped', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseConstExpression_listLiteral_untyped);
      });
      _ut.test('test_parseConstExpression_mapLiteral_typed', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseConstExpression_mapLiteral_typed);
      });
      _ut.test('test_parseConstExpression_mapLiteral_untyped', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseConstExpression_mapLiteral_untyped);
      });
      _ut.test('test_parseConstructor', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseConstructor);
      });
      _ut.test('test_parseConstructorFieldInitializer_qualified', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseConstructorFieldInitializer_qualified);
      });
      _ut.test('test_parseConstructorFieldInitializer_unqualified', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseConstructorFieldInitializer_unqualified);
      });
      _ut.test('test_parseConstructorName_named_noPrefix', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseConstructorName_named_noPrefix);
      });
      _ut.test('test_parseConstructorName_named_prefixed', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseConstructorName_named_prefixed);
      });
      _ut.test('test_parseConstructorName_unnamed_noPrefix', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseConstructorName_unnamed_noPrefix);
      });
      _ut.test('test_parseConstructorName_unnamed_prefixed', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseConstructorName_unnamed_prefixed);
      });
      _ut.test('test_parseContinueStatement_label', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseContinueStatement_label);
      });
      _ut.test('test_parseContinueStatement_noLabel', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseContinueStatement_noLabel);
      });
      _ut.test('test_parseDirective_export', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseDirective_export);
      });
      _ut.test('test_parseDirective_import', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseDirective_import);
      });
      _ut.test('test_parseDirective_library', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseDirective_library);
      });
      _ut.test('test_parseDirective_part', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseDirective_part);
      });
      _ut.test('test_parseDirective_partOf', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseDirective_partOf);
      });
      _ut.test('test_parseDoStatement', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseDoStatement);
      });
      _ut.test('test_parseDocumentationComment_block', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseDocumentationComment_block);
      });
      _ut.test('test_parseDocumentationComment_block_withReference', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseDocumentationComment_block_withReference);
      });
      _ut.test('test_parseDocumentationComment_endOfLine', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseDocumentationComment_endOfLine);
      });
      _ut.test('test_parseEmptyStatement', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseEmptyStatement);
      });
      _ut.test('test_parseEqualityExpression_normal', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseEqualityExpression_normal);
      });
      _ut.test('test_parseEqualityExpression_super', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseEqualityExpression_super);
      });
      _ut.test('test_parseExportDirective_hide', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseExportDirective_hide);
      });
      _ut.test('test_parseExportDirective_hide_show', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseExportDirective_hide_show);
      });
      _ut.test('test_parseExportDirective_noCombinator', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseExportDirective_noCombinator);
      });
      _ut.test('test_parseExportDirective_show', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseExportDirective_show);
      });
      _ut.test('test_parseExportDirective_show_hide', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseExportDirective_show_hide);
      });
      _ut.test('test_parseExpressionList_multiple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseExpressionList_multiple);
      });
      _ut.test('test_parseExpressionList_single', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseExpressionList_single);
      });
      _ut.test('test_parseExpressionWithoutCascade_assign', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseExpressionWithoutCascade_assign);
      });
      _ut.test('test_parseExpressionWithoutCascade_comparison', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseExpressionWithoutCascade_comparison);
      });
      _ut.test('test_parseExpressionWithoutCascade_superMethodInvocation', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseExpressionWithoutCascade_superMethodInvocation);
      });
      _ut.test('test_parseExpression_assign', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseExpression_assign);
      });
      _ut.test('test_parseExpression_comparison', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseExpression_comparison);
      });
      _ut.test('test_parseExpression_invokeFunctionExpression', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseExpression_invokeFunctionExpression);
      });
      _ut.test('test_parseExpression_superMethodInvocation', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseExpression_superMethodInvocation);
      });
      _ut.test('test_parseExtendsClause', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseExtendsClause);
      });
      _ut.test('test_parseFinalConstVarOrType_const_noType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFinalConstVarOrType_const_noType);
      });
      _ut.test('test_parseFinalConstVarOrType_const_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFinalConstVarOrType_const_type);
      });
      _ut.test('test_parseFinalConstVarOrType_final_noType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFinalConstVarOrType_final_noType);
      });
      _ut.test('test_parseFinalConstVarOrType_final_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFinalConstVarOrType_final_type);
      });
      _ut.test('test_parseFinalConstVarOrType_type_parameterized', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFinalConstVarOrType_type_parameterized);
      });
      _ut.test('test_parseFinalConstVarOrType_type_prefixed', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFinalConstVarOrType_type_prefixed);
      });
      _ut.test('test_parseFinalConstVarOrType_type_prefixedAndParameterized', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFinalConstVarOrType_type_prefixedAndParameterized);
      });
      _ut.test('test_parseFinalConstVarOrType_type_simple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFinalConstVarOrType_type_simple);
      });
      _ut.test('test_parseFinalConstVarOrType_var', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFinalConstVarOrType_var);
      });
      _ut.test('test_parseForStatement_each_identifier', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseForStatement_each_identifier);
      });
      _ut.test('test_parseForStatement_each_noType_metadata', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseForStatement_each_noType_metadata);
      });
      _ut.test('test_parseForStatement_each_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseForStatement_each_type);
      });
      _ut.test('test_parseForStatement_each_var', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseForStatement_each_var);
      });
      _ut.test('test_parseForStatement_loop_c', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseForStatement_loop_c);
      });
      _ut.test('test_parseForStatement_loop_cu', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseForStatement_loop_cu);
      });
      _ut.test('test_parseForStatement_loop_ecu', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseForStatement_loop_ecu);
      });
      _ut.test('test_parseForStatement_loop_i', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseForStatement_loop_i);
      });
      _ut.test('test_parseForStatement_loop_i_withMetadata', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseForStatement_loop_i_withMetadata);
      });
      _ut.test('test_parseForStatement_loop_ic', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseForStatement_loop_ic);
      });
      _ut.test('test_parseForStatement_loop_icu', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseForStatement_loop_icu);
      });
      _ut.test('test_parseForStatement_loop_iicuu', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseForStatement_loop_iicuu);
      });
      _ut.test('test_parseForStatement_loop_iu', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseForStatement_loop_iu);
      });
      _ut.test('test_parseForStatement_loop_u', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseForStatement_loop_u);
      });
      _ut.test('test_parseFormalParameterList_empty', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFormalParameterList_empty);
      });
      _ut.test('test_parseFormalParameterList_named_multiple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFormalParameterList_named_multiple);
      });
      _ut.test('test_parseFormalParameterList_named_single', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFormalParameterList_named_single);
      });
      _ut.test('test_parseFormalParameterList_normal_multiple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFormalParameterList_normal_multiple);
      });
      _ut.test('test_parseFormalParameterList_normal_named', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFormalParameterList_normal_named);
      });
      _ut.test('test_parseFormalParameterList_normal_positional', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFormalParameterList_normal_positional);
      });
      _ut.test('test_parseFormalParameterList_normal_single', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFormalParameterList_normal_single);
      });
      _ut.test('test_parseFormalParameterList_positional_multiple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFormalParameterList_positional_multiple);
      });
      _ut.test('test_parseFormalParameterList_positional_single', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFormalParameterList_positional_single);
      });
      _ut.test('test_parseFormalParameter_final_withType_named', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFormalParameter_final_withType_named);
      });
      _ut.test('test_parseFormalParameter_final_withType_normal', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFormalParameter_final_withType_normal);
      });
      _ut.test('test_parseFormalParameter_final_withType_positional', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFormalParameter_final_withType_positional);
      });
      _ut.test('test_parseFormalParameter_nonFinal_withType_named', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFormalParameter_nonFinal_withType_named);
      });
      _ut.test('test_parseFormalParameter_nonFinal_withType_normal', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFormalParameter_nonFinal_withType_normal);
      });
      _ut.test('test_parseFormalParameter_nonFinal_withType_positional', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFormalParameter_nonFinal_withType_positional);
      });
      _ut.test('test_parseFormalParameter_var', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFormalParameter_var);
      });
      _ut.test('test_parseFormalParameter_var_named', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFormalParameter_var_named);
      });
      _ut.test('test_parseFormalParameter_var_positional', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFormalParameter_var_positional);
      });
      _ut.test('test_parseFunctionBody_block', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFunctionBody_block);
      });
      _ut.test('test_parseFunctionBody_empty', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFunctionBody_empty);
      });
      _ut.test('test_parseFunctionBody_expression', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFunctionBody_expression);
      });
      _ut.test('test_parseFunctionBody_nativeFunctionBody', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFunctionBody_nativeFunctionBody);
      });
      _ut.test('test_parseFunctionDeclarationStatement', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFunctionDeclarationStatement);
      });
      _ut.test('test_parseFunctionDeclaration_function', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFunctionDeclaration_function);
      });
      _ut.test('test_parseFunctionDeclaration_getter', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFunctionDeclaration_getter);
      });
      _ut.test('test_parseFunctionDeclaration_setter', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFunctionDeclaration_setter);
      });
      _ut.test('test_parseFunctionExpression_body_inExpression', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFunctionExpression_body_inExpression);
      });
      _ut.test('test_parseFunctionExpression_minimal', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseFunctionExpression_minimal);
      });
      _ut.test('test_parseGetter_nonStatic', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseGetter_nonStatic);
      });
      _ut.test('test_parseGetter_static', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseGetter_static);
      });
      _ut.test('test_parseIdentifierList_multiple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseIdentifierList_multiple);
      });
      _ut.test('test_parseIdentifierList_single', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseIdentifierList_single);
      });
      _ut.test('test_parseIfStatement_else_block', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseIfStatement_else_block);
      });
      _ut.test('test_parseIfStatement_else_statement', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseIfStatement_else_statement);
      });
      _ut.test('test_parseIfStatement_noElse_block', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseIfStatement_noElse_block);
      });
      _ut.test('test_parseIfStatement_noElse_statement', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseIfStatement_noElse_statement);
      });
      _ut.test('test_parseImplementsClause_multiple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseImplementsClause_multiple);
      });
      _ut.test('test_parseImplementsClause_single', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseImplementsClause_single);
      });
      _ut.test('test_parseImportDirective_hide', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseImportDirective_hide);
      });
      _ut.test('test_parseImportDirective_noCombinator', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseImportDirective_noCombinator);
      });
      _ut.test('test_parseImportDirective_prefix', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseImportDirective_prefix);
      });
      _ut.test('test_parseImportDirective_prefix_hide_show', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseImportDirective_prefix_hide_show);
      });
      _ut.test('test_parseImportDirective_prefix_show_hide', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseImportDirective_prefix_show_hide);
      });
      _ut.test('test_parseImportDirective_show', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseImportDirective_show);
      });
      _ut.test('test_parseInitializedIdentifierList_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseInitializedIdentifierList_type);
      });
      _ut.test('test_parseInitializedIdentifierList_var', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseInitializedIdentifierList_var);
      });
      _ut.test('test_parseInstanceCreationExpression_qualifiedType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseInstanceCreationExpression_qualifiedType);
      });
      _ut.test('test_parseInstanceCreationExpression_qualifiedType_named', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseInstanceCreationExpression_qualifiedType_named);
      });
      _ut.test('test_parseInstanceCreationExpression_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseInstanceCreationExpression_type);
      });
      _ut.test('test_parseInstanceCreationExpression_type_named', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseInstanceCreationExpression_type_named);
      });
      _ut.test('test_parseLibraryDirective', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseLibraryDirective);
      });
      _ut.test('test_parseLibraryIdentifier_multiple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseLibraryIdentifier_multiple);
      });
      _ut.test('test_parseLibraryIdentifier_single', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseLibraryIdentifier_single);
      });
      _ut.test('test_parseListLiteral_empty_oneToken', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseListLiteral_empty_oneToken);
      });
      _ut.test('test_parseListLiteral_empty_twoTokens', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseListLiteral_empty_twoTokens);
      });
      _ut.test('test_parseListLiteral_multiple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseListLiteral_multiple);
      });
      _ut.test('test_parseListLiteral_single', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseListLiteral_single);
      });
      _ut.test('test_parseListOrMapLiteral_list_noType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseListOrMapLiteral_list_noType);
      });
      _ut.test('test_parseListOrMapLiteral_list_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseListOrMapLiteral_list_type);
      });
      _ut.test('test_parseListOrMapLiteral_map_noType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseListOrMapLiteral_map_noType);
      });
      _ut.test('test_parseListOrMapLiteral_map_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseListOrMapLiteral_map_type);
      });
      _ut.test('test_parseLogicalAndExpression', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseLogicalAndExpression);
      });
      _ut.test('test_parseLogicalOrExpression', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseLogicalOrExpression);
      });
      _ut.test('test_parseMapLiteralEntry', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseMapLiteralEntry);
      });
      _ut.test('test_parseMapLiteral_empty', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseMapLiteral_empty);
      });
      _ut.test('test_parseMapLiteral_multiple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseMapLiteral_multiple);
      });
      _ut.test('test_parseMapLiteral_single', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseMapLiteral_single);
      });
      _ut.test('test_parseModifiers_abstract', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseModifiers_abstract);
      });
      _ut.test('test_parseModifiers_const', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseModifiers_const);
      });
      _ut.test('test_parseModifiers_external', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseModifiers_external);
      });
      _ut.test('test_parseModifiers_factory', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseModifiers_factory);
      });
      _ut.test('test_parseModifiers_final', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseModifiers_final);
      });
      _ut.test('test_parseModifiers_static', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseModifiers_static);
      });
      _ut.test('test_parseModifiers_var', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseModifiers_var);
      });
      _ut.test('test_parseMultiplicativeExpression_normal', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseMultiplicativeExpression_normal);
      });
      _ut.test('test_parseMultiplicativeExpression_super', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseMultiplicativeExpression_super);
      });
      _ut.test('test_parseNewExpression', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNewExpression);
      });
      _ut.test('test_parseNonLabeledStatement_const_list_empty', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNonLabeledStatement_const_list_empty);
      });
      _ut.test('test_parseNonLabeledStatement_const_list_nonEmpty', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNonLabeledStatement_const_list_nonEmpty);
      });
      _ut.test('test_parseNonLabeledStatement_const_map_empty', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNonLabeledStatement_const_map_empty);
      });
      _ut.test('test_parseNonLabeledStatement_const_map_nonEmpty', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNonLabeledStatement_const_map_nonEmpty);
      });
      _ut.test('test_parseNonLabeledStatement_const_object', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNonLabeledStatement_const_object);
      });
      _ut.test('test_parseNonLabeledStatement_const_object_named_typeParameters', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNonLabeledStatement_const_object_named_typeParameters);
      });
      _ut.test('test_parseNonLabeledStatement_constructorInvocation', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNonLabeledStatement_constructorInvocation);
      });
      _ut.test('test_parseNonLabeledStatement_false', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNonLabeledStatement_false);
      });
      _ut.test('test_parseNonLabeledStatement_functionDeclaration', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNonLabeledStatement_functionDeclaration);
      });
      _ut.test('test_parseNonLabeledStatement_functionDeclaration_arguments', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNonLabeledStatement_functionDeclaration_arguments);
      });
      _ut.test('test_parseNonLabeledStatement_functionExpressionIndex', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNonLabeledStatement_functionExpressionIndex);
      });
      _ut.test('test_parseNonLabeledStatement_functionInvocation', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNonLabeledStatement_functionInvocation);
      });
      _ut.test('test_parseNonLabeledStatement_invokeFunctionExpression', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNonLabeledStatement_invokeFunctionExpression);
      });
      _ut.test('test_parseNonLabeledStatement_null', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNonLabeledStatement_null);
      });
      _ut.test('test_parseNonLabeledStatement_startingWithBuiltInIdentifier', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNonLabeledStatement_startingWithBuiltInIdentifier);
      });
      _ut.test('test_parseNonLabeledStatement_true', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNonLabeledStatement_true);
      });
      _ut.test('test_parseNonLabeledStatement_typeCast', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNonLabeledStatement_typeCast);
      });
      _ut.test('test_parseNormalFormalParameter_field_const_noType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNormalFormalParameter_field_const_noType);
      });
      _ut.test('test_parseNormalFormalParameter_field_const_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNormalFormalParameter_field_const_type);
      });
      _ut.test('test_parseNormalFormalParameter_field_final_noType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNormalFormalParameter_field_final_noType);
      });
      _ut.test('test_parseNormalFormalParameter_field_final_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNormalFormalParameter_field_final_type);
      });
      _ut.test('test_parseNormalFormalParameter_field_noType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNormalFormalParameter_field_noType);
      });
      _ut.test('test_parseNormalFormalParameter_field_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNormalFormalParameter_field_type);
      });
      _ut.test('test_parseNormalFormalParameter_field_var', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNormalFormalParameter_field_var);
      });
      _ut.test('test_parseNormalFormalParameter_function_noType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNormalFormalParameter_function_noType);
      });
      _ut.test('test_parseNormalFormalParameter_function_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNormalFormalParameter_function_type);
      });
      _ut.test('test_parseNormalFormalParameter_function_void', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNormalFormalParameter_function_void);
      });
      _ut.test('test_parseNormalFormalParameter_simple_const_noType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNormalFormalParameter_simple_const_noType);
      });
      _ut.test('test_parseNormalFormalParameter_simple_const_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNormalFormalParameter_simple_const_type);
      });
      _ut.test('test_parseNormalFormalParameter_simple_final_noType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNormalFormalParameter_simple_final_noType);
      });
      _ut.test('test_parseNormalFormalParameter_simple_final_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNormalFormalParameter_simple_final_type);
      });
      _ut.test('test_parseNormalFormalParameter_simple_noType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNormalFormalParameter_simple_noType);
      });
      _ut.test('test_parseNormalFormalParameter_simple_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseNormalFormalParameter_simple_type);
      });
      _ut.test('test_parseOperator', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseOperator);
      });
      _ut.test('test_parseOptionalReturnType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseOptionalReturnType);
      });
      _ut.test('test_parsePartDirective_part', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePartDirective_part);
      });
      _ut.test('test_parsePartDirective_partOf', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePartDirective_partOf);
      });
      _ut.test('test_parsePostfixExpression_decrement', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePostfixExpression_decrement);
      });
      _ut.test('test_parsePostfixExpression_increment', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePostfixExpression_increment);
      });
      _ut.test('test_parsePostfixExpression_none_indexExpression', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePostfixExpression_none_indexExpression);
      });
      _ut.test('test_parsePostfixExpression_none_methodInvocation', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePostfixExpression_none_methodInvocation);
      });
      _ut.test('test_parsePostfixExpression_none_propertyAccess', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePostfixExpression_none_propertyAccess);
      });
      _ut.test('test_parsePrefixedIdentifier_noPrefix', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePrefixedIdentifier_noPrefix);
      });
      _ut.test('test_parsePrefixedIdentifier_prefix', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePrefixedIdentifier_prefix);
      });
      _ut.test('test_parsePrimaryExpression_argumentDefinitionTest', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePrimaryExpression_argumentDefinitionTest);
      });
      _ut.test('test_parsePrimaryExpression_const', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePrimaryExpression_const);
      });
      _ut.test('test_parsePrimaryExpression_double', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePrimaryExpression_double);
      });
      _ut.test('test_parsePrimaryExpression_false', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePrimaryExpression_false);
      });
      _ut.test('test_parsePrimaryExpression_function_arguments', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePrimaryExpression_function_arguments);
      });
      _ut.test('test_parsePrimaryExpression_function_noArguments', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePrimaryExpression_function_noArguments);
      });
      _ut.test('test_parsePrimaryExpression_hex', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePrimaryExpression_hex);
      });
      _ut.test('test_parsePrimaryExpression_identifier', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePrimaryExpression_identifier);
      });
      _ut.test('test_parsePrimaryExpression_int', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePrimaryExpression_int);
      });
      _ut.test('test_parsePrimaryExpression_listLiteral', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePrimaryExpression_listLiteral);
      });
      _ut.test('test_parsePrimaryExpression_listLiteral_index', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePrimaryExpression_listLiteral_index);
      });
      _ut.test('test_parsePrimaryExpression_listLiteral_typed', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePrimaryExpression_listLiteral_typed);
      });
      _ut.test('test_parsePrimaryExpression_mapLiteral', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePrimaryExpression_mapLiteral);
      });
      _ut.test('test_parsePrimaryExpression_mapLiteral_typed', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePrimaryExpression_mapLiteral_typed);
      });
      _ut.test('test_parsePrimaryExpression_new', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePrimaryExpression_new);
      });
      _ut.test('test_parsePrimaryExpression_null', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePrimaryExpression_null);
      });
      _ut.test('test_parsePrimaryExpression_parenthesized', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePrimaryExpression_parenthesized);
      });
      _ut.test('test_parsePrimaryExpression_string', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePrimaryExpression_string);
      });
      _ut.test('test_parsePrimaryExpression_super', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePrimaryExpression_super);
      });
      _ut.test('test_parsePrimaryExpression_this', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePrimaryExpression_this);
      });
      _ut.test('test_parsePrimaryExpression_true', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parsePrimaryExpression_true);
      });
      _ut.test('test_parseRedirectingConstructorInvocation_named', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseRedirectingConstructorInvocation_named);
      });
      _ut.test('test_parseRedirectingConstructorInvocation_unnamed', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseRedirectingConstructorInvocation_unnamed);
      });
      _ut.test('test_parseRelationalExpression_as', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseRelationalExpression_as);
      });
      _ut.test('test_parseRelationalExpression_is', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseRelationalExpression_is);
      });
      _ut.test('test_parseRelationalExpression_isNot', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseRelationalExpression_isNot);
      });
      _ut.test('test_parseRelationalExpression_normal', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseRelationalExpression_normal);
      });
      _ut.test('test_parseRelationalExpression_super', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseRelationalExpression_super);
      });
      _ut.test('test_parseRethrowExpression', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseRethrowExpression);
      });
      _ut.test('test_parseReturnStatement_noValue', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseReturnStatement_noValue);
      });
      _ut.test('test_parseReturnStatement_value', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseReturnStatement_value);
      });
      _ut.test('test_parseReturnType_nonVoid', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseReturnType_nonVoid);
      });
      _ut.test('test_parseReturnType_void', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseReturnType_void);
      });
      _ut.test('test_parseSetter_nonStatic', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseSetter_nonStatic);
      });
      _ut.test('test_parseSetter_static', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseSetter_static);
      });
      _ut.test('test_parseShiftExpression_normal', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseShiftExpression_normal);
      });
      _ut.test('test_parseShiftExpression_super', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseShiftExpression_super);
      });
      _ut.test('test_parseSimpleIdentifier1_normalIdentifier', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseSimpleIdentifier1_normalIdentifier);
      });
      _ut.test('test_parseSimpleIdentifier_builtInIdentifier', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseSimpleIdentifier_builtInIdentifier);
      });
      _ut.test('test_parseSimpleIdentifier_normalIdentifier', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseSimpleIdentifier_normalIdentifier);
      });
      _ut.test('test_parseStatement_functionDeclaration', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseStatement_functionDeclaration);
      });
      _ut.test('test_parseStatement_mulipleLabels', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseStatement_mulipleLabels);
      });
      _ut.test('test_parseStatement_noLabels', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseStatement_noLabels);
      });
      _ut.test('test_parseStatement_singleLabel', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseStatement_singleLabel);
      });
      _ut.test('test_parseStatements_multiple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseStatements_multiple);
      });
      _ut.test('test_parseStatements_single', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseStatements_single);
      });
      _ut.test('test_parseStringLiteral_adjacent', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseStringLiteral_adjacent);
      });
      _ut.test('test_parseStringLiteral_interpolated', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseStringLiteral_interpolated);
      });
      _ut.test('test_parseStringLiteral_single', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseStringLiteral_single);
      });
      _ut.test('test_parseSuperConstructorInvocation_named', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseSuperConstructorInvocation_named);
      });
      _ut.test('test_parseSuperConstructorInvocation_unnamed', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseSuperConstructorInvocation_unnamed);
      });
      _ut.test('test_parseSwitchStatement_case', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseSwitchStatement_case);
      });
      _ut.test('test_parseSwitchStatement_empty', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseSwitchStatement_empty);
      });
      _ut.test('test_parseSwitchStatement_labeledCase', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseSwitchStatement_labeledCase);
      });
      _ut.test('test_parseSwitchStatement_labeledStatementInCase', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseSwitchStatement_labeledStatementInCase);
      });
      _ut.test('test_parseThrowExpression', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseThrowExpression);
      });
      _ut.test('test_parseThrowExpressionWithoutCascade', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseThrowExpressionWithoutCascade);
      });
      _ut.test('test_parseTryStatement_catch', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTryStatement_catch);
      });
      _ut.test('test_parseTryStatement_catch_finally', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTryStatement_catch_finally);
      });
      _ut.test('test_parseTryStatement_finally', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTryStatement_finally);
      });
      _ut.test('test_parseTryStatement_multiple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTryStatement_multiple);
      });
      _ut.test('test_parseTryStatement_on', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTryStatement_on);
      });
      _ut.test('test_parseTryStatement_on_catch', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTryStatement_on_catch);
      });
      _ut.test('test_parseTryStatement_on_catch_finally', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTryStatement_on_catch_finally);
      });
      _ut.test('test_parseTypeAlias_class_implementsC', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTypeAlias_class_implementsC);
      });
      _ut.test('test_parseTypeAlias_class_withB', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTypeAlias_class_withB);
      });
      _ut.test('test_parseTypeAlias_function_noParameters', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTypeAlias_function_noParameters);
      });
      _ut.test('test_parseTypeAlias_function_noReturnType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTypeAlias_function_noReturnType);
      });
      _ut.test('test_parseTypeAlias_function_parameterizedReturnType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTypeAlias_function_parameterizedReturnType);
      });
      _ut.test('test_parseTypeAlias_function_parameters', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTypeAlias_function_parameters);
      });
      _ut.test('test_parseTypeAlias_function_typeParameters', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTypeAlias_function_typeParameters);
      });
      _ut.test('test_parseTypeAlias_function_voidReturnType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTypeAlias_function_voidReturnType);
      });
      _ut.test('test_parseTypeArgumentList_multiple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTypeArgumentList_multiple);
      });
      _ut.test('test_parseTypeArgumentList_nested', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTypeArgumentList_nested);
      });
      _ut.test('test_parseTypeArgumentList_single', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTypeArgumentList_single);
      });
      _ut.test('test_parseTypeName_parameterized', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTypeName_parameterized);
      });
      _ut.test('test_parseTypeName_simple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTypeName_simple);
      });
      _ut.test('test_parseTypeParameterList_multiple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTypeParameterList_multiple);
      });
      _ut.test('test_parseTypeParameterList_parameterizedWithTrailingEquals', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTypeParameterList_parameterizedWithTrailingEquals);
      });
      _ut.test('test_parseTypeParameterList_single', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTypeParameterList_single);
      });
      _ut.test('test_parseTypeParameterList_withTrailingEquals', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTypeParameterList_withTrailingEquals);
      });
      _ut.test('test_parseTypeParameter_bounded', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTypeParameter_bounded);
      });
      _ut.test('test_parseTypeParameter_simple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseTypeParameter_simple);
      });
      _ut.test('test_parseUnaryExpression_decrement_normal', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseUnaryExpression_decrement_normal);
      });
      _ut.test('test_parseUnaryExpression_decrement_super', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseUnaryExpression_decrement_super);
      });
      _ut.test('test_parseUnaryExpression_decrement_super_propertyAccess', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseUnaryExpression_decrement_super_propertyAccess);
      });
      _ut.test('test_parseUnaryExpression_increment_normal', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseUnaryExpression_increment_normal);
      });
      _ut.test('test_parseUnaryExpression_increment_super_index', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseUnaryExpression_increment_super_index);
      });
      _ut.test('test_parseUnaryExpression_increment_super_propertyAccess', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseUnaryExpression_increment_super_propertyAccess);
      });
      _ut.test('test_parseUnaryExpression_minus_normal', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseUnaryExpression_minus_normal);
      });
      _ut.test('test_parseUnaryExpression_minus_super', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseUnaryExpression_minus_super);
      });
      _ut.test('test_parseUnaryExpression_not_normal', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseUnaryExpression_not_normal);
      });
      _ut.test('test_parseUnaryExpression_not_super', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseUnaryExpression_not_super);
      });
      _ut.test('test_parseUnaryExpression_tilda_normal', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseUnaryExpression_tilda_normal);
      });
      _ut.test('test_parseUnaryExpression_tilda_super', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseUnaryExpression_tilda_super);
      });
      _ut.test('test_parseVariableDeclarationList2_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseVariableDeclarationList2_type);
      });
      _ut.test('test_parseVariableDeclarationList2_var', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseVariableDeclarationList2_var);
      });
      _ut.test('test_parseVariableDeclarationList_const_noType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseVariableDeclarationList_const_noType);
      });
      _ut.test('test_parseVariableDeclarationList_const_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseVariableDeclarationList_const_type);
      });
      _ut.test('test_parseVariableDeclarationList_final_noType', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseVariableDeclarationList_final_noType);
      });
      _ut.test('test_parseVariableDeclarationList_final_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseVariableDeclarationList_final_type);
      });
      _ut.test('test_parseVariableDeclarationList_type_multiple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseVariableDeclarationList_type_multiple);
      });
      _ut.test('test_parseVariableDeclarationList_type_single', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseVariableDeclarationList_type_single);
      });
      _ut.test('test_parseVariableDeclarationList_var_multiple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseVariableDeclarationList_var_multiple);
      });
      _ut.test('test_parseVariableDeclarationList_var_single', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseVariableDeclarationList_var_single);
      });
      _ut.test('test_parseVariableDeclarationStatement_multiple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseVariableDeclarationStatement_multiple);
      });
      _ut.test('test_parseVariableDeclarationStatement_single', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseVariableDeclarationStatement_single);
      });
      _ut.test('test_parseVariableDeclaration_equals', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseVariableDeclaration_equals);
      });
      _ut.test('test_parseVariableDeclaration_noEquals', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseVariableDeclaration_noEquals);
      });
      _ut.test('test_parseWhileStatement', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseWhileStatement);
      });
      _ut.test('test_parseWithClause_multiple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseWithClause_multiple);
      });
      _ut.test('test_parseWithClause_single', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_parseWithClause_single);
      });
      _ut.test('test_skipPrefixedIdentifier_invalid', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_skipPrefixedIdentifier_invalid);
      });
      _ut.test('test_skipPrefixedIdentifier_notPrefixed', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_skipPrefixedIdentifier_notPrefixed);
      });
      _ut.test('test_skipPrefixedIdentifier_prefixed', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_skipPrefixedIdentifier_prefixed);
      });
      _ut.test('test_skipReturnType_invalid', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_skipReturnType_invalid);
      });
      _ut.test('test_skipReturnType_type', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_skipReturnType_type);
      });
      _ut.test('test_skipReturnType_void', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_skipReturnType_void);
      });
      _ut.test('test_skipSimpleIdentifier_identifier', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_skipSimpleIdentifier_identifier);
      });
      _ut.test('test_skipSimpleIdentifier_invalid', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_skipSimpleIdentifier_invalid);
      });
      _ut.test('test_skipSimpleIdentifier_pseudoKeyword', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_skipSimpleIdentifier_pseudoKeyword);
      });
      _ut.test('test_skipStringLiteral_adjacent', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_skipStringLiteral_adjacent);
      });
      _ut.test('test_skipStringLiteral_interpolated', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_skipStringLiteral_interpolated);
      });
      _ut.test('test_skipStringLiteral_invalid', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_skipStringLiteral_invalid);
      });
      _ut.test('test_skipStringLiteral_single', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_skipStringLiteral_single);
      });
      _ut.test('test_skipTypeArgumentList_invalid', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_skipTypeArgumentList_invalid);
      });
      _ut.test('test_skipTypeArgumentList_multiple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_skipTypeArgumentList_multiple);
      });
      _ut.test('test_skipTypeArgumentList_single', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_skipTypeArgumentList_single);
      });
      _ut.test('test_skipTypeName_invalid', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_skipTypeName_invalid);
      });
      _ut.test('test_skipTypeName_parameterized', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_skipTypeName_parameterized);
      });
      _ut.test('test_skipTypeName_simple', () {
        final __test = new SimpleParserTest();
        runJUnitTest(__test, __test.test_skipTypeName_simple);
      });
    });
  }
}
class AnalysisErrorListener_19 implements AnalysisErrorListener {
  void onError(AnalysisError event) {
    JUnitTestCase.fail("Unexpected compilation error: ${event.message} (${event.offset}, ${event.length})");
  }
}
/**
 * The class {@code ComplexParserTest} defines parser tests that test the parsing of more complex
 * code fragments or the interactions between multiple parsing methods. For example, tests to ensure
 * that the precedence of operations is being handled correctly should be defined in this class.
 * <p>
 * Simpler tests should be defined in the class {@link SimpleParserTest}.
 */
class ComplexParserTest extends ParserTestCase {
  void test_additiveExpression_normal() {
    BinaryExpression expression = ParserTestCase.parseExpression("x + y - z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_additiveExpression_noSpaces() {
    BinaryExpression expression = ParserTestCase.parseExpression("i+1", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.leftOperand);
    EngineTestCase.assertInstanceOf(IntegerLiteral, expression.rightOperand);
  }
  void test_additiveExpression_precedence_multiplicative_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("x * y + z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_additiveExpression_precedence_multiplicative_left_withSuper() {
    BinaryExpression expression = ParserTestCase.parseExpression("super * y - z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_additiveExpression_precedence_multiplicative_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("x + y * z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.rightOperand);
  }
  void test_additiveExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super + y - z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_assignableExpression_arguments_normal_chain() {
    PropertyAccess propertyAccess1 = ParserTestCase.parseExpression("a(b)(c).d(e).f", []);
    JUnitTestCase.assertEquals("f", propertyAccess1.propertyName.name);
    MethodInvocation invocation2 = EngineTestCase.assertInstanceOf(MethodInvocation, propertyAccess1.target);
    JUnitTestCase.assertEquals("d", invocation2.methodName.name);
    ArgumentList argumentList2 = invocation2.argumentList;
    JUnitTestCase.assertNotNull(argumentList2);
    EngineTestCase.assertSize(1, argumentList2.arguments);
    FunctionExpressionInvocation invocation3 = EngineTestCase.assertInstanceOf(FunctionExpressionInvocation, invocation2.target);
    ArgumentList argumentList3 = invocation3.argumentList;
    JUnitTestCase.assertNotNull(argumentList3);
    EngineTestCase.assertSize(1, argumentList3.arguments);
    MethodInvocation invocation4 = EngineTestCase.assertInstanceOf(MethodInvocation, invocation3.function);
    JUnitTestCase.assertEquals("a", invocation4.methodName.name);
    ArgumentList argumentList4 = invocation4.argumentList;
    JUnitTestCase.assertNotNull(argumentList4);
    EngineTestCase.assertSize(1, argumentList4.arguments);
  }
  void test_assignmentExpression_compound() {
    AssignmentExpression expression = ParserTestCase.parseExpression("x = y = 0", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.leftHandSide);
    EngineTestCase.assertInstanceOf(AssignmentExpression, expression.rightHandSide);
  }
  void test_assignmentExpression_indexExpression() {
    AssignmentExpression expression = ParserTestCase.parseExpression("x[1] = 0", []);
    EngineTestCase.assertInstanceOf(IndexExpression, expression.leftHandSide);
    EngineTestCase.assertInstanceOf(IntegerLiteral, expression.rightHandSide);
  }
  void test_assignmentExpression_prefixedIdentifier() {
    AssignmentExpression expression = ParserTestCase.parseExpression("x.y = 0", []);
    EngineTestCase.assertInstanceOf(PrefixedIdentifier, expression.leftHandSide);
    EngineTestCase.assertInstanceOf(IntegerLiteral, expression.rightHandSide);
  }
  void test_assignmentExpression_propertyAccess() {
    AssignmentExpression expression = ParserTestCase.parseExpression("super.y = 0", []);
    EngineTestCase.assertInstanceOf(PropertyAccess, expression.leftHandSide);
    EngineTestCase.assertInstanceOf(IntegerLiteral, expression.rightHandSide);
  }
  void test_bitwiseAndExpression_normal() {
    BinaryExpression expression = ParserTestCase.parseExpression("x & y & z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_bitwiseAndExpression_precedence_equality_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("x == y & z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_bitwiseAndExpression_precedence_equality_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("x & y == z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.rightOperand);
  }
  void test_bitwiseAndExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super & y & z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_bitwiseOrExpression_normal() {
    BinaryExpression expression = ParserTestCase.parseExpression("x | y | z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_bitwiseOrExpression_precedence_xor_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("x ^ y | z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_bitwiseOrExpression_precedence_xor_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("x | y ^ z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.rightOperand);
  }
  void test_bitwiseOrExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super | y | z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_bitwiseXorExpression_normal() {
    BinaryExpression expression = ParserTestCase.parseExpression("x ^ y ^ z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_bitwiseXorExpression_precedence_and_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("x & y ^ z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_bitwiseXorExpression_precedence_and_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("x ^ y & z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.rightOperand);
  }
  void test_bitwiseXorExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super ^ y ^ z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_cascade_withAssignment() {
    CascadeExpression cascade = ParserTestCase.parseExpression("new Map()..[3] = 4 ..[0] = 11;", []);
    Expression target4 = cascade.target;
    for (Expression section in cascade.cascadeSections) {
      EngineTestCase.assertInstanceOf(AssignmentExpression, section);
      Expression lhs = ((section as AssignmentExpression)).leftHandSide;
      EngineTestCase.assertInstanceOf(IndexExpression, lhs);
      IndexExpression index = lhs as IndexExpression;
      JUnitTestCase.assertTrue(index.isCascaded());
      JUnitTestCase.assertSame(target4, index.realTarget);
    }
  }
  void test_conditionalExpression_precedence_argumentDefinitionTest_not() {
    ConditionalExpression conditional = ParserTestCase.parseExpression("!?a?!?b:!?c", []);
    EngineTestCase.assertInstanceOf(PrefixExpression, conditional.condition);
    EngineTestCase.assertInstanceOf(ArgumentDefinitionTest, ((conditional.condition as PrefixExpression)).operand);
    EngineTestCase.assertInstanceOf(PrefixExpression, conditional.thenExpression);
    EngineTestCase.assertInstanceOf(ArgumentDefinitionTest, ((conditional.thenExpression as PrefixExpression)).operand);
    EngineTestCase.assertInstanceOf(PrefixExpression, conditional.elseExpression);
    EngineTestCase.assertInstanceOf(ArgumentDefinitionTest, ((conditional.elseExpression as PrefixExpression)).operand);
  }
  void test_conditionalExpression_precedence_logicalOrExpression() {
    ConditionalExpression expression = ParserTestCase.parseExpression("a | b ? y : z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.condition);
  }
  void test_constructor_initializer_withParenthesizedExpression() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(EngineTestCase.createSource(["class C {", "  C() :", "    this.a = (b == null ? c : d) {", "  }", "}"]), []);
    NodeList<CompilationUnitMember> declarations2 = unit.declarations;
    EngineTestCase.assertSize(1, declarations2);
  }
  void test_equalityExpression_normal() {
    BinaryExpression expression = ParserTestCase.parseExpression("x == y != z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_equalityExpression_precedence_relational_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("x is y == z", []);
    EngineTestCase.assertInstanceOf(IsExpression, expression.leftOperand);
  }
  void test_equalityExpression_precedence_relational_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("x == y is z", []);
    EngineTestCase.assertInstanceOf(IsExpression, expression.rightOperand);
  }
  void test_equalityExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super == y != z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_logicalAndExpression() {
    BinaryExpression expression = ParserTestCase.parseExpression("x && y && z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_logicalAndExpression_precedence_bitwiseOr_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("x | y && z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_logicalAndExpression_precedence_bitwiseOr_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("x && y | z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.rightOperand);
  }
  void test_logicalOrExpression() {
    BinaryExpression expression = ParserTestCase.parseExpression("x || y || z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_logicalOrExpression_precedence_logicalAnd_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("x && y || z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_logicalOrExpression_precedence_logicalAnd_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("x || y && z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.rightOperand);
  }
  void test_multipleLabels_statement() {
    LabeledStatement statement = ParserTestCase.parseStatement("a: b: c: return x;", []);
    EngineTestCase.assertSize(3, statement.labels);
    EngineTestCase.assertInstanceOf(ReturnStatement, statement.statement);
  }
  void test_multiplicativeExpression_normal() {
    BinaryExpression expression = ParserTestCase.parseExpression("x * y / z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_multiplicativeExpression_precedence_unary_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("-x * y", []);
    EngineTestCase.assertInstanceOf(PrefixExpression, expression.leftOperand);
  }
  void test_multiplicativeExpression_precedence_unary_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("x * -y", []);
    EngineTestCase.assertInstanceOf(PrefixExpression, expression.rightOperand);
  }
  void test_multiplicativeExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super * y / z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_relationalExpression_precedence_shift_right() {
    IsExpression expression = ParserTestCase.parseExpression("x << y is z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.expression);
  }
  void test_shiftExpression_normal() {
    BinaryExpression expression = ParserTestCase.parseExpression("x >> 4 << 3", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_shiftExpression_precedence_additive_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("x + y << z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_shiftExpression_precedence_additive_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("x << y + z", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.rightOperand);
  }
  void test_shiftExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super >> 4 << 3", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  static dartSuite() {
    _ut.group('ComplexParserTest', () {
      _ut.test('test_additiveExpression_noSpaces', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_additiveExpression_noSpaces);
      });
      _ut.test('test_additiveExpression_normal', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_additiveExpression_normal);
      });
      _ut.test('test_additiveExpression_precedence_multiplicative_left', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_additiveExpression_precedence_multiplicative_left);
      });
      _ut.test('test_additiveExpression_precedence_multiplicative_left_withSuper', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_additiveExpression_precedence_multiplicative_left_withSuper);
      });
      _ut.test('test_additiveExpression_precedence_multiplicative_right', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_additiveExpression_precedence_multiplicative_right);
      });
      _ut.test('test_additiveExpression_super', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_additiveExpression_super);
      });
      _ut.test('test_assignableExpression_arguments_normal_chain', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_assignableExpression_arguments_normal_chain);
      });
      _ut.test('test_assignmentExpression_compound', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_assignmentExpression_compound);
      });
      _ut.test('test_assignmentExpression_indexExpression', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_assignmentExpression_indexExpression);
      });
      _ut.test('test_assignmentExpression_prefixedIdentifier', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_assignmentExpression_prefixedIdentifier);
      });
      _ut.test('test_assignmentExpression_propertyAccess', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_assignmentExpression_propertyAccess);
      });
      _ut.test('test_bitwiseAndExpression_normal', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_bitwiseAndExpression_normal);
      });
      _ut.test('test_bitwiseAndExpression_precedence_equality_left', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_bitwiseAndExpression_precedence_equality_left);
      });
      _ut.test('test_bitwiseAndExpression_precedence_equality_right', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_bitwiseAndExpression_precedence_equality_right);
      });
      _ut.test('test_bitwiseAndExpression_super', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_bitwiseAndExpression_super);
      });
      _ut.test('test_bitwiseOrExpression_normal', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_bitwiseOrExpression_normal);
      });
      _ut.test('test_bitwiseOrExpression_precedence_xor_left', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_bitwiseOrExpression_precedence_xor_left);
      });
      _ut.test('test_bitwiseOrExpression_precedence_xor_right', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_bitwiseOrExpression_precedence_xor_right);
      });
      _ut.test('test_bitwiseOrExpression_super', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_bitwiseOrExpression_super);
      });
      _ut.test('test_bitwiseXorExpression_normal', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_bitwiseXorExpression_normal);
      });
      _ut.test('test_bitwiseXorExpression_precedence_and_left', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_bitwiseXorExpression_precedence_and_left);
      });
      _ut.test('test_bitwiseXorExpression_precedence_and_right', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_bitwiseXorExpression_precedence_and_right);
      });
      _ut.test('test_bitwiseXorExpression_super', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_bitwiseXorExpression_super);
      });
      _ut.test('test_cascade_withAssignment', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_cascade_withAssignment);
      });
      _ut.test('test_conditionalExpression_precedence_argumentDefinitionTest_not', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_conditionalExpression_precedence_argumentDefinitionTest_not);
      });
      _ut.test('test_conditionalExpression_precedence_logicalOrExpression', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_conditionalExpression_precedence_logicalOrExpression);
      });
      _ut.test('test_constructor_initializer_withParenthesizedExpression', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_constructor_initializer_withParenthesizedExpression);
      });
      _ut.test('test_equalityExpression_normal', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_equalityExpression_normal);
      });
      _ut.test('test_equalityExpression_precedence_relational_left', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_equalityExpression_precedence_relational_left);
      });
      _ut.test('test_equalityExpression_precedence_relational_right', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_equalityExpression_precedence_relational_right);
      });
      _ut.test('test_equalityExpression_super', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_equalityExpression_super);
      });
      _ut.test('test_logicalAndExpression', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_logicalAndExpression);
      });
      _ut.test('test_logicalAndExpression_precedence_bitwiseOr_left', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_logicalAndExpression_precedence_bitwiseOr_left);
      });
      _ut.test('test_logicalAndExpression_precedence_bitwiseOr_right', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_logicalAndExpression_precedence_bitwiseOr_right);
      });
      _ut.test('test_logicalOrExpression', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_logicalOrExpression);
      });
      _ut.test('test_logicalOrExpression_precedence_logicalAnd_left', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_logicalOrExpression_precedence_logicalAnd_left);
      });
      _ut.test('test_logicalOrExpression_precedence_logicalAnd_right', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_logicalOrExpression_precedence_logicalAnd_right);
      });
      _ut.test('test_multipleLabels_statement', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_multipleLabels_statement);
      });
      _ut.test('test_multiplicativeExpression_normal', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_multiplicativeExpression_normal);
      });
      _ut.test('test_multiplicativeExpression_precedence_unary_left', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_multiplicativeExpression_precedence_unary_left);
      });
      _ut.test('test_multiplicativeExpression_precedence_unary_right', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_multiplicativeExpression_precedence_unary_right);
      });
      _ut.test('test_multiplicativeExpression_super', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_multiplicativeExpression_super);
      });
      _ut.test('test_relationalExpression_precedence_shift_right', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_relationalExpression_precedence_shift_right);
      });
      _ut.test('test_shiftExpression_normal', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_shiftExpression_normal);
      });
      _ut.test('test_shiftExpression_precedence_additive_left', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_shiftExpression_precedence_additive_left);
      });
      _ut.test('test_shiftExpression_precedence_additive_right', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_shiftExpression_precedence_additive_right);
      });
      _ut.test('test_shiftExpression_super', () {
        final __test = new ComplexParserTest();
        runJUnitTest(__test, __test.test_shiftExpression_super);
      });
    });
  }
}
/**
 * Instances of the class {@code ASTValidator} are used to validate the correct construction of an
 * AST structure.
 */
class ASTValidator extends GeneralizingASTVisitor<Object> {
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
  Object visitNode(ASTNode node) {
    validate(node);
    return super.visitNode(node);
  }
  /**
   * Validate that the given AST node is correctly constructed.
   * @param node the AST node being validated
   */
  void validate(ASTNode node) {
    ASTNode parent21 = node.parent;
    if (node is CompilationUnit) {
      if (parent21 != null) {
        _errors.add("Compilation units should not have a parent");
      }
    } else {
      if (parent21 == null) {
        _errors.add("No parent for ${node.runtimeType.toString()}");
      }
    }
    if (node.beginToken == null) {
      _errors.add("No begin token for ${node.runtimeType.toString()}");
    }
    if (node.endToken == null) {
      _errors.add("No end token for ${node.runtimeType.toString()}");
    }
    int nodeStart = node.offset;
    int nodeLength = node.length;
    if (nodeStart < 0 || nodeLength < 0) {
      _errors.add("No source info for ${node.runtimeType.toString()}");
    }
    if (parent21 != null) {
      int nodeEnd = nodeStart + nodeLength;
      int parentStart = parent21.offset;
      int parentEnd = parentStart + parent21.length;
      if (nodeStart < parentStart) {
        _errors.add("Invalid source start (${nodeStart}) for ${node.runtimeType.toString()} inside ${parent21.runtimeType.toString()} (${parentStart})");
      }
      if (nodeEnd > parentEnd) {
        _errors.add("Invalid source end (${nodeEnd}) for ${node.runtimeType.toString()} inside ${parent21.runtimeType.toString()} (${parentStart})");
      }
    }
  }
}
class ParserTestCase extends EngineTestCase {
  /**
   * An empty array of objects used as arguments to zero-argument methods.
   */
  static List<Object> _EMPTY_ARGUMENTS = new List<Object>(0);
  /**
   * Invoke a parse method in {@link Parser}. The method is assumed to have the given number and
   * type of parameters and will be invoked with the given arguments.
   * <p>
   * The given source is scanned and the parser is initialized to start with the first token in the
   * source before the parse method is invoked.
   * @param methodName the name of the parse method that should be invoked to parse the source
   * @param objects the values of the arguments to the method
   * @param source the source to be parsed by the parse method
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   * @throws AssertionFailedError if the result is {@code null} or if any errors are produced
   */
  static Object parse(String methodName, List<Object> objects, String source) => parse3(methodName, objects, source, new List<AnalysisError>(0));
  /**
   * Invoke a parse method in {@link Parser}. The method is assumed to have the given number and
   * type of parameters and will be invoked with the given arguments.
   * <p>
   * The given source is scanned and the parser is initialized to start with the first token in the
   * source before the parse method is invoked.
   * @param methodName the name of the parse method that should be invoked to parse the source
   * @param objects the values of the arguments to the method
   * @param source the source to be parsed by the parse method
   * @param errorCodes the error codes of the errors that should be generated
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   * @throws AssertionFailedError if the result is {@code null} or the errors produced while
   * scanning and parsing the source do not match the expected errors
   */
  static Object parse3(String methodName, List<Object> objects, String source, List<AnalysisError> errors) {
    GatheringErrorListener listener = new GatheringErrorListener();
    Object result = invokeParserMethod(methodName, objects, source, listener);
    listener.assertErrors(errors);
    return result;
  }
  /**
   * Invoke a parse method in {@link Parser}. The method is assumed to have the given number and
   * type of parameters and will be invoked with the given arguments.
   * <p>
   * The given source is scanned and the parser is initialized to start with the first token in the
   * source before the parse method is invoked.
   * @param methodName the name of the parse method that should be invoked to parse the source
   * @param objects the values of the arguments to the method
   * @param source the source to be parsed by the parse method
   * @param errorCodes the error codes of the errors that should be generated
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   * @throws AssertionFailedError if the result is {@code null} or the errors produced while
   * scanning and parsing the source do not match the expected errors
   */
  static Object parse4(String methodName, List<Object> objects, String source, List<ErrorCode> errorCodes) {
    GatheringErrorListener listener = new GatheringErrorListener();
    Object result = invokeParserMethod(methodName, objects, source, listener);
    listener.assertErrors2(errorCodes);
    return result;
  }
  /**
   * Invoke a parse method in {@link Parser}. The method is assumed to have no arguments.
   * <p>
   * The given source is scanned and the parser is initialized to start with the first token in the
   * source before the parse method is invoked.
   * @param methodName the name of the parse method that should be invoked to parse the source
   * @param source the source to be parsed by the parse method
   * @param errorCodes the error codes of the errors that should be generated
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   * @throws AssertionFailedError if the result is {@code null} or the errors produced while
   * scanning and parsing the source do not match the expected errors
   */
  static Object parse5(String methodName, String source, List<ErrorCode> errorCodes) => parse4(methodName, _EMPTY_ARGUMENTS, source, errorCodes);
  /**
   * Parse the given source as a compilation unit.
   * @param source the source to be parsed
   * @param errorCodes the error codes of the errors that are expected to be found
   * @return the compilation unit that was parsed
   * @throws Exception if the source could not be parsed, if the compilation errors in the source do
   * not match those that are expected, or if the result would have been {@code null}
   */
  static CompilationUnit parseCompilationUnit(String source, List<ErrorCode> errorCodes) {
    GatheringErrorListener listener = new GatheringErrorListener();
    StringScanner scanner = new StringScanner(null, source, listener);
    listener.setLineInfo(new TestSource(), scanner.lineStarts);
    Token token = scanner.tokenize();
    Parser parser = new Parser(null, listener);
    CompilationUnit unit = parser.parseCompilationUnit(token);
    JUnitTestCase.assertNotNull(unit);
    listener.assertErrors2(errorCodes);
    return unit;
  }
  /**
   * Parse the given source as an expression.
   * @param source the source to be parsed
   * @param errorCodes the error codes of the errors that are expected to be found
   * @return the expression that was parsed
   * @throws Exception if the source could not be parsed, if the compilation errors in the source do
   * not match those that are expected, or if the result would have been {@code null}
   */
  static Expression parseExpression(String source, List<ErrorCode> errorCodes) {
    GatheringErrorListener listener = new GatheringErrorListener();
    StringScanner scanner = new StringScanner(null, source, listener);
    listener.setLineInfo(new TestSource(), scanner.lineStarts);
    Token token = scanner.tokenize();
    Parser parser = new Parser(null, listener);
    Expression expression = parser.parseExpression(token);
    JUnitTestCase.assertNotNull(expression);
    listener.assertErrors2(errorCodes);
    return expression as Expression;
  }
  /**
   * Parse the given source as a statement.
   * @param source the source to be parsed
   * @param errorCodes the error codes of the errors that are expected to be found
   * @return the statement that was parsed
   * @throws Exception if the source could not be parsed, if the compilation errors in the source do
   * not match those that are expected, or if the result would have been {@code null}
   */
  static Statement parseStatement(String source, List<ErrorCode> errorCodes) {
    GatheringErrorListener listener = new GatheringErrorListener();
    StringScanner scanner = new StringScanner(null, source, listener);
    listener.setLineInfo(new TestSource(), scanner.lineStarts);
    Token token = scanner.tokenize();
    Parser parser = new Parser(null, listener);
    Statement statement = parser.parseStatement(token);
    JUnitTestCase.assertNotNull(statement);
    listener.assertErrors2(errorCodes);
    return statement as Statement;
  }
  /**
   * Parse the given source as a sequence of statements.
   * @param source the source to be parsed
   * @param expectedCount the number of statements that are expected
   * @param errorCodes the error codes of the errors that are expected to be found
   * @return the statements that were parsed
   * @throws Exception if the source could not be parsed, if the number of statements does not match
   * the expected count, if the compilation errors in the source do not match those that
   * are expected, or if the result would have been {@code null}
   */
  static List<Statement> parseStatements(String source, int expectedCount, List<ErrorCode> errorCodes) {
    GatheringErrorListener listener = new GatheringErrorListener();
    StringScanner scanner = new StringScanner(null, source, listener);
    listener.setLineInfo(new TestSource(), scanner.lineStarts);
    Token token = scanner.tokenize();
    Parser parser = new Parser(null, listener);
    List<Statement> statements = parser.parseStatements(token);
    EngineTestCase.assertSize(expectedCount, statements);
    listener.assertErrors2(errorCodes);
    return statements;
  }
  /**
   * Invoke a method in {@link Parser}. The method is assumed to have the given number and type of
   * parameters and will be invoked with the given arguments.
   * <p>
   * The given source is scanned and the parser is initialized to start with the first token in the
   * source before the method is invoked.
   * @param methodName the name of the method that should be invoked
   * @param objects the values of the arguments to the method
   * @param source the source to be processed by the parse method
   * @param listener the error listener that will be used for both scanning and parsing
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   * @throws AssertionFailedError if the result is {@code null} or the errors produced while
   * scanning and parsing the source do not match the expected errors
   */
  static Object invokeParserMethod(String methodName, List<Object> objects, String source, GatheringErrorListener listener) {
    StringScanner scanner = new StringScanner(null, source, listener);
    Token tokenStream = scanner.tokenize();
    listener.setLineInfo(new TestSource(), scanner.lineStarts);
    Parser parser = new Parser(null, listener);
    Object result = invokeParserMethodImpl(parser, methodName, objects, tokenStream);
    if (!listener.hasErrors()) {
      JUnitTestCase.assertNotNull(result);
    }
    return result as Object;
  }
  /**
   * Invoke a method in {@link Parser}. The method is assumed to have no arguments.
   * <p>
   * The given source is scanned and the parser is initialized to start with the first token in the
   * source before the method is invoked.
   * @param methodName the name of the method that should be invoked
   * @param source the source to be processed by the parse method
   * @param listener the error listener that will be used for both scanning and parsing
   * @return the result of invoking the method
   * @throws Exception if the method could not be invoked or throws an exception
   * @throws AssertionFailedError if the result is {@code null} or the errors produced while
   * scanning and parsing the source do not match the expected errors
   */
  static Object invokeParserMethod2(String methodName, String source, GatheringErrorListener listener) => invokeParserMethod(methodName, _EMPTY_ARGUMENTS, source, listener);
  /**
   * Return a CommentAndMetadata object with the given values that can be used for testing.
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
   * @return an empty CommentAndMetadata object that can be used for testing
   */
  CommentAndMetadata emptyCommentAndMetadata() => new CommentAndMetadata(null, new List<Annotation>());
  static dartSuite() {
    _ut.group('ParserTestCase', () {
    });
  }
}
/**
 * The class {@code RecoveryParserTest} defines parser tests that test the parsing of invalid code
 * sequences to ensure that the correct recovery steps are taken in the parser.
 */
class RecoveryParserTest extends ParserTestCase {
  void test_additiveExpression_missing_LHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("+ y", [ParserErrorCode.USE_OF_UNARY_PLUS_OPERATOR]);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic());
  }
  void test_additiveExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("+", [ParserErrorCode.USE_OF_UNARY_PLUS_OPERATOR]);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic());
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_additiveExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x +", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_additiveExpression_missing_RHS_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super +", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_additiveExpression_precedence_multiplicative_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("* +", [ParserErrorCode.USE_OF_UNARY_PLUS_OPERATOR]);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_additiveExpression_precedence_multiplicative_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("+ *", [ParserErrorCode.USE_OF_UNARY_PLUS_OPERATOR]);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.rightOperand);
  }
  void test_additiveExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super + +", [ParserErrorCode.USE_OF_UNARY_PLUS_OPERATOR]);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_argumentDefinitionTest_missing_identifier() {
    ArgumentDefinitionTest expression = ParserTestCase.parseExpression("?", [ParserErrorCode.MISSING_IDENTIFIER]);
    JUnitTestCase.assertTrue(expression.identifier.isSynthetic());
  }
  void test_assignmentExpression_missing_compound1() {
    AssignmentExpression expression = ParserTestCase.parseExpression("= y = 0", []);
    Expression syntheticExpression = expression.leftHandSide;
    EngineTestCase.assertInstanceOf(SimpleIdentifier, syntheticExpression);
    JUnitTestCase.assertTrue(syntheticExpression.isSynthetic());
  }
  void test_assignmentExpression_missing_compound2() {
    AssignmentExpression expression = ParserTestCase.parseExpression("x = = 0", []);
    Expression syntheticExpression = ((expression.rightHandSide as AssignmentExpression)).leftHandSide;
    EngineTestCase.assertInstanceOf(SimpleIdentifier, syntheticExpression);
    JUnitTestCase.assertTrue(syntheticExpression.isSynthetic());
  }
  void test_assignmentExpression_missing_compound3() {
    AssignmentExpression expression = ParserTestCase.parseExpression("x = y =", []);
    Expression syntheticExpression = ((expression.rightHandSide as AssignmentExpression)).rightHandSide;
    EngineTestCase.assertInstanceOf(SimpleIdentifier, syntheticExpression);
    JUnitTestCase.assertTrue(syntheticExpression.isSynthetic());
  }
  void test_assignmentExpression_missing_LHS() {
    AssignmentExpression expression = ParserTestCase.parseExpression("= 0", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.leftHandSide);
    JUnitTestCase.assertTrue(expression.leftHandSide.isSynthetic());
  }
  void test_assignmentExpression_missing_RHS() {
    AssignmentExpression expression = ParserTestCase.parseExpression("x =", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.leftHandSide);
    JUnitTestCase.assertTrue(expression.rightHandSide.isSynthetic());
  }
  void test_bitwiseAndExpression_missing_LHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("& y", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic());
  }
  void test_bitwiseAndExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("&", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic());
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_bitwiseAndExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x &", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_bitwiseAndExpression_missing_RHS_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super &", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_bitwiseAndExpression_precedence_equality_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("== &", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_bitwiseAndExpression_precedence_equality_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("& ==", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.rightOperand);
  }
  void test_bitwiseAndExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super &  &", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_bitwiseOrExpression_missing_LHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("| y", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic());
  }
  void test_bitwiseOrExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("|", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic());
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_bitwiseOrExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x |", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_bitwiseOrExpression_missing_RHS_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super |", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_bitwiseOrExpression_precedence_xor_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("^ |", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_bitwiseOrExpression_precedence_xor_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("| ^", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.rightOperand);
  }
  void test_bitwiseOrExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super |  |", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_bitwiseXorExpression_missing_LHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("^ y", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic());
  }
  void test_bitwiseXorExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("^", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic());
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_bitwiseXorExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x ^", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_bitwiseXorExpression_missing_RHS_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super ^", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_bitwiseXorExpression_precedence_and_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("& ^", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_bitwiseXorExpression_precedence_and_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("^ &", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.rightOperand);
  }
  void test_bitwiseXorExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super ^  ^", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_conditionalExpression_missingElse() {
    ConditionalExpression expression = ParserTestCase.parse5("parseConditionalExpression", "x ? y :", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.elseExpression);
    JUnitTestCase.assertTrue(expression.elseExpression.isSynthetic());
  }
  void test_conditionalExpression_missingThen() {
    ConditionalExpression expression = ParserTestCase.parse5("parseConditionalExpression", "x ? : z", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.thenExpression);
    JUnitTestCase.assertTrue(expression.thenExpression.isSynthetic());
  }
  void test_equalityExpression_missing_LHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("== y", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic());
  }
  void test_equalityExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("==", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic());
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_equalityExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x ==", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_equalityExpression_missing_RHS_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super ==", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_equalityExpression_precedence_relational_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("is ==", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf(IsExpression, expression.leftOperand);
  }
  void test_equalityExpression_precedence_relational_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("== is", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf(IsExpression, expression.rightOperand);
  }
  void test_equalityExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super ==  ==", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_expressionList_multiple_end() {
    List<Expression> result = ParserTestCase.parse5("parseExpressionList", ", 2, 3, 4", []);
    EngineTestCase.assertSize(4, result);
    Expression syntheticExpression = result[0];
    EngineTestCase.assertInstanceOf(SimpleIdentifier, syntheticExpression);
    JUnitTestCase.assertTrue(syntheticExpression.isSynthetic());
  }
  void test_expressionList_multiple_middle() {
    List<Expression> result = ParserTestCase.parse5("parseExpressionList", "1, 2, , 4", []);
    EngineTestCase.assertSize(4, result);
    Expression syntheticExpression = result[2];
    EngineTestCase.assertInstanceOf(SimpleIdentifier, syntheticExpression);
    JUnitTestCase.assertTrue(syntheticExpression.isSynthetic());
  }
  void test_expressionList_multiple_start() {
    List<Expression> result = ParserTestCase.parse5("parseExpressionList", "1, 2, 3,", []);
    EngineTestCase.assertSize(4, result);
    Expression syntheticExpression = result[3];
    EngineTestCase.assertInstanceOf(SimpleIdentifier, syntheticExpression);
    JUnitTestCase.assertTrue(syntheticExpression.isSynthetic());
  }
  void test_isExpression_noType() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("class Bar<T extends Foo> {m(x){if (x is ) return;if (x is !)}}", [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.MISSING_STATEMENT]);
    ClassDeclaration declaration = unit.declarations[0] as ClassDeclaration;
    MethodDeclaration method = declaration.members[0] as MethodDeclaration;
    BlockFunctionBody body5 = method.body as BlockFunctionBody;
    IfStatement ifStatement = body5.block.statements[1] as IfStatement;
    IsExpression expression = ifStatement.condition as IsExpression;
    JUnitTestCase.assertNotNull(expression.expression);
    JUnitTestCase.assertNotNull(expression.isOperator);
    JUnitTestCase.assertNotNull(expression.notOperator);
    TypeName type37 = expression.type;
    JUnitTestCase.assertNotNull(type37);
    JUnitTestCase.assertTrue(type37.name.isSynthetic());
    EngineTestCase.assertInstanceOf(EmptyStatement, ifStatement.thenStatement);
  }
  void test_logicalAndExpression_missing_LHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("&& y", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic());
  }
  void test_logicalAndExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("&&", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic());
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_logicalAndExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x &&", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_logicalAndExpression_precedence_bitwiseOr_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("| &&", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_logicalAndExpression_precedence_bitwiseOr_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("&& |", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.rightOperand);
  }
  void test_logicalOrExpression_missing_LHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("|| y", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic());
  }
  void test_logicalOrExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("||", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic());
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_logicalOrExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x ||", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_logicalOrExpression_precedence_logicalAnd_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("&& ||", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_logicalOrExpression_precedence_logicalAnd_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("|| &&", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.rightOperand);
  }
  void test_multiplicativeExpression_missing_LHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("* y", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic());
  }
  void test_multiplicativeExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("*", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic());
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_multiplicativeExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x *", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_multiplicativeExpression_missing_RHS_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super *", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_multiplicativeExpression_precedence_unary_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("-x *", []);
    EngineTestCase.assertInstanceOf(PrefixExpression, expression.leftOperand);
  }
  void test_multiplicativeExpression_precedence_unary_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("* -y", []);
    EngineTestCase.assertInstanceOf(PrefixExpression, expression.rightOperand);
  }
  void test_multiplicativeExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super ==  ==", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_prefixExpression_missing_operand_minus() {
    PrefixExpression expression = ParserTestCase.parseExpression("-", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.operand);
    JUnitTestCase.assertTrue(expression.operand.isSynthetic());
    JUnitTestCase.assertEquals(TokenType.MINUS, expression.operator.type);
  }
  void test_relationalExpression_missing_LHS() {
    IsExpression expression = ParserTestCase.parseExpression("is y", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.expression);
    JUnitTestCase.assertTrue(expression.expression.isSynthetic());
  }
  void test_relationalExpression_missing_LHS_RHS() {
    IsExpression expression = ParserTestCase.parseExpression("is", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.expression);
    JUnitTestCase.assertTrue(expression.expression.isSynthetic());
    EngineTestCase.assertInstanceOf(TypeName, expression.type);
    JUnitTestCase.assertTrue(expression.type.isSynthetic());
  }
  void test_relationalExpression_missing_RHS() {
    IsExpression expression = ParserTestCase.parseExpression("x is", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf(TypeName, expression.type);
    JUnitTestCase.assertTrue(expression.type.isSynthetic());
  }
  void test_relationalExpression_precedence_shift_right() {
    IsExpression expression = ParserTestCase.parseExpression("<< is", [ParserErrorCode.MISSING_IDENTIFIER]);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.expression);
  }
  void test_shiftExpression_missing_LHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("<< y", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic());
  }
  void test_shiftExpression_missing_LHS_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("<<", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.leftOperand);
    JUnitTestCase.assertTrue(expression.leftOperand.isSynthetic());
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_shiftExpression_missing_RHS() {
    BinaryExpression expression = ParserTestCase.parseExpression("x <<", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_shiftExpression_missing_RHS_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super <<", []);
    EngineTestCase.assertInstanceOf(SimpleIdentifier, expression.rightOperand);
    JUnitTestCase.assertTrue(expression.rightOperand.isSynthetic());
  }
  void test_shiftExpression_precedence_unary_left() {
    BinaryExpression expression = ParserTestCase.parseExpression("+ <<", [ParserErrorCode.USE_OF_UNARY_PLUS_OPERATOR]);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_shiftExpression_precedence_unary_right() {
    BinaryExpression expression = ParserTestCase.parseExpression("<< +", [ParserErrorCode.USE_OF_UNARY_PLUS_OPERATOR]);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.rightOperand);
  }
  void test_shiftExpression_super() {
    BinaryExpression expression = ParserTestCase.parseExpression("super << <<", []);
    EngineTestCase.assertInstanceOf(BinaryExpression, expression.leftOperand);
  }
  void test_typedef_eof() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit("typedef n", [ParserErrorCode.EXPECTED_TOKEN, ParserErrorCode.MISSING_TYPEDEF_PARAMETERS]);
    NodeList<CompilationUnitMember> declarations3 = unit.declarations;
    EngineTestCase.assertSize(1, declarations3);
    CompilationUnitMember member = declarations3[0];
    EngineTestCase.assertInstanceOf(FunctionTypeAlias, member);
  }
  static dartSuite() {
    _ut.group('RecoveryParserTest', () {
      _ut.test('test_additiveExpression_missing_LHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_additiveExpression_missing_LHS);
      });
      _ut.test('test_additiveExpression_missing_LHS_RHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_additiveExpression_missing_LHS_RHS);
      });
      _ut.test('test_additiveExpression_missing_RHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_additiveExpression_missing_RHS);
      });
      _ut.test('test_additiveExpression_missing_RHS_super', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_additiveExpression_missing_RHS_super);
      });
      _ut.test('test_additiveExpression_precedence_multiplicative_left', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_additiveExpression_precedence_multiplicative_left);
      });
      _ut.test('test_additiveExpression_precedence_multiplicative_right', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_additiveExpression_precedence_multiplicative_right);
      });
      _ut.test('test_additiveExpression_super', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_additiveExpression_super);
      });
      _ut.test('test_argumentDefinitionTest_missing_identifier', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_argumentDefinitionTest_missing_identifier);
      });
      _ut.test('test_assignmentExpression_missing_LHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_assignmentExpression_missing_LHS);
      });
      _ut.test('test_assignmentExpression_missing_RHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_assignmentExpression_missing_RHS);
      });
      _ut.test('test_assignmentExpression_missing_compound1', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_assignmentExpression_missing_compound1);
      });
      _ut.test('test_assignmentExpression_missing_compound2', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_assignmentExpression_missing_compound2);
      });
      _ut.test('test_assignmentExpression_missing_compound3', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_assignmentExpression_missing_compound3);
      });
      _ut.test('test_bitwiseAndExpression_missing_LHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_bitwiseAndExpression_missing_LHS);
      });
      _ut.test('test_bitwiseAndExpression_missing_LHS_RHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_bitwiseAndExpression_missing_LHS_RHS);
      });
      _ut.test('test_bitwiseAndExpression_missing_RHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_bitwiseAndExpression_missing_RHS);
      });
      _ut.test('test_bitwiseAndExpression_missing_RHS_super', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_bitwiseAndExpression_missing_RHS_super);
      });
      _ut.test('test_bitwiseAndExpression_precedence_equality_left', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_bitwiseAndExpression_precedence_equality_left);
      });
      _ut.test('test_bitwiseAndExpression_precedence_equality_right', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_bitwiseAndExpression_precedence_equality_right);
      });
      _ut.test('test_bitwiseAndExpression_super', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_bitwiseAndExpression_super);
      });
      _ut.test('test_bitwiseOrExpression_missing_LHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_bitwiseOrExpression_missing_LHS);
      });
      _ut.test('test_bitwiseOrExpression_missing_LHS_RHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_bitwiseOrExpression_missing_LHS_RHS);
      });
      _ut.test('test_bitwiseOrExpression_missing_RHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_bitwiseOrExpression_missing_RHS);
      });
      _ut.test('test_bitwiseOrExpression_missing_RHS_super', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_bitwiseOrExpression_missing_RHS_super);
      });
      _ut.test('test_bitwiseOrExpression_precedence_xor_left', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_bitwiseOrExpression_precedence_xor_left);
      });
      _ut.test('test_bitwiseOrExpression_precedence_xor_right', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_bitwiseOrExpression_precedence_xor_right);
      });
      _ut.test('test_bitwiseOrExpression_super', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_bitwiseOrExpression_super);
      });
      _ut.test('test_bitwiseXorExpression_missing_LHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_bitwiseXorExpression_missing_LHS);
      });
      _ut.test('test_bitwiseXorExpression_missing_LHS_RHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_bitwiseXorExpression_missing_LHS_RHS);
      });
      _ut.test('test_bitwiseXorExpression_missing_RHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_bitwiseXorExpression_missing_RHS);
      });
      _ut.test('test_bitwiseXorExpression_missing_RHS_super', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_bitwiseXorExpression_missing_RHS_super);
      });
      _ut.test('test_bitwiseXorExpression_precedence_and_left', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_bitwiseXorExpression_precedence_and_left);
      });
      _ut.test('test_bitwiseXorExpression_precedence_and_right', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_bitwiseXorExpression_precedence_and_right);
      });
      _ut.test('test_bitwiseXorExpression_super', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_bitwiseXorExpression_super);
      });
      _ut.test('test_conditionalExpression_missingElse', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_conditionalExpression_missingElse);
      });
      _ut.test('test_conditionalExpression_missingThen', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_conditionalExpression_missingThen);
      });
      _ut.test('test_equalityExpression_missing_LHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_equalityExpression_missing_LHS);
      });
      _ut.test('test_equalityExpression_missing_LHS_RHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_equalityExpression_missing_LHS_RHS);
      });
      _ut.test('test_equalityExpression_missing_RHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_equalityExpression_missing_RHS);
      });
      _ut.test('test_equalityExpression_missing_RHS_super', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_equalityExpression_missing_RHS_super);
      });
      _ut.test('test_equalityExpression_precedence_relational_left', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_equalityExpression_precedence_relational_left);
      });
      _ut.test('test_equalityExpression_precedence_relational_right', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_equalityExpression_precedence_relational_right);
      });
      _ut.test('test_equalityExpression_super', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_equalityExpression_super);
      });
      _ut.test('test_expressionList_multiple_end', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_expressionList_multiple_end);
      });
      _ut.test('test_expressionList_multiple_middle', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_expressionList_multiple_middle);
      });
      _ut.test('test_expressionList_multiple_start', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_expressionList_multiple_start);
      });
      _ut.test('test_isExpression_noType', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_isExpression_noType);
      });
      _ut.test('test_logicalAndExpression_missing_LHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_logicalAndExpression_missing_LHS);
      });
      _ut.test('test_logicalAndExpression_missing_LHS_RHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_logicalAndExpression_missing_LHS_RHS);
      });
      _ut.test('test_logicalAndExpression_missing_RHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_logicalAndExpression_missing_RHS);
      });
      _ut.test('test_logicalAndExpression_precedence_bitwiseOr_left', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_logicalAndExpression_precedence_bitwiseOr_left);
      });
      _ut.test('test_logicalAndExpression_precedence_bitwiseOr_right', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_logicalAndExpression_precedence_bitwiseOr_right);
      });
      _ut.test('test_logicalOrExpression_missing_LHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_logicalOrExpression_missing_LHS);
      });
      _ut.test('test_logicalOrExpression_missing_LHS_RHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_logicalOrExpression_missing_LHS_RHS);
      });
      _ut.test('test_logicalOrExpression_missing_RHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_logicalOrExpression_missing_RHS);
      });
      _ut.test('test_logicalOrExpression_precedence_logicalAnd_left', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_logicalOrExpression_precedence_logicalAnd_left);
      });
      _ut.test('test_logicalOrExpression_precedence_logicalAnd_right', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_logicalOrExpression_precedence_logicalAnd_right);
      });
      _ut.test('test_multiplicativeExpression_missing_LHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_multiplicativeExpression_missing_LHS);
      });
      _ut.test('test_multiplicativeExpression_missing_LHS_RHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_multiplicativeExpression_missing_LHS_RHS);
      });
      _ut.test('test_multiplicativeExpression_missing_RHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_multiplicativeExpression_missing_RHS);
      });
      _ut.test('test_multiplicativeExpression_missing_RHS_super', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_multiplicativeExpression_missing_RHS_super);
      });
      _ut.test('test_multiplicativeExpression_precedence_unary_left', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_multiplicativeExpression_precedence_unary_left);
      });
      _ut.test('test_multiplicativeExpression_precedence_unary_right', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_multiplicativeExpression_precedence_unary_right);
      });
      _ut.test('test_multiplicativeExpression_super', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_multiplicativeExpression_super);
      });
      _ut.test('test_prefixExpression_missing_operand_minus', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_prefixExpression_missing_operand_minus);
      });
      _ut.test('test_relationalExpression_missing_LHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_relationalExpression_missing_LHS);
      });
      _ut.test('test_relationalExpression_missing_LHS_RHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_relationalExpression_missing_LHS_RHS);
      });
      _ut.test('test_relationalExpression_missing_RHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_relationalExpression_missing_RHS);
      });
      _ut.test('test_relationalExpression_precedence_shift_right', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_relationalExpression_precedence_shift_right);
      });
      _ut.test('test_shiftExpression_missing_LHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_shiftExpression_missing_LHS);
      });
      _ut.test('test_shiftExpression_missing_LHS_RHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_shiftExpression_missing_LHS_RHS);
      });
      _ut.test('test_shiftExpression_missing_RHS', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_shiftExpression_missing_RHS);
      });
      _ut.test('test_shiftExpression_missing_RHS_super', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_shiftExpression_missing_RHS_super);
      });
      _ut.test('test_shiftExpression_precedence_unary_left', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_shiftExpression_precedence_unary_left);
      });
      _ut.test('test_shiftExpression_precedence_unary_right', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_shiftExpression_precedence_unary_right);
      });
      _ut.test('test_shiftExpression_super', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_shiftExpression_super);
      });
      _ut.test('test_typedef_eof', () {
        final __test = new RecoveryParserTest();
        runJUnitTest(__test, __test.test_typedef_eof);
      });
    });
  }
}
/**
 * The class {@code ErrorParserTest} defines parser tests that test the parsing of code to ensure
 * that errors are correctly reported, and in some cases, not reported.
 */
class ErrorParserTest extends ParserTestCase {
  void fail_expectedListOrMapLiteral() {
    TypedLiteral literal = ParserTestCase.parse4("parseListOrMapLiteral", <Object> [null], "1", [ParserErrorCode.EXPECTED_LIST_OR_MAP_LITERAL]);
    JUnitTestCase.assertTrue(literal.isSynthetic());
  }
  void fail_illegalAssignmentToNonAssignable_superAssigned() {
    ParserTestCase.parse5("parseExpression", "super = x;", [ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE]);
  }
  void fail_invalidCommentReference__new_nonIdentifier() {
    ParserTestCase.parse4("parseCommentReference", <Object> ["new 42", 0], "", [ParserErrorCode.INVALID_COMMENT_REFERENCE]);
  }
  void fail_invalidCommentReference__new_tooMuch() {
    ParserTestCase.parse4("parseCommentReference", <Object> ["new a.b.c.d", 0], "", [ParserErrorCode.INVALID_COMMENT_REFERENCE]);
  }
  void fail_invalidCommentReference__nonNew_nonIdentifier() {
    ParserTestCase.parse4("parseCommentReference", <Object> ["42", 0], "", [ParserErrorCode.INVALID_COMMENT_REFERENCE]);
  }
  void fail_invalidCommentReference__nonNew_tooMuch() {
    ParserTestCase.parse4("parseCommentReference", <Object> ["a.b.c.d", 0], "", [ParserErrorCode.INVALID_COMMENT_REFERENCE]);
  }
  void fail_missingClosingParenthesis() {
    ParserTestCase.parse5("parseFormalParameterList", "(int a, int b ;", [ParserErrorCode.MISSING_CLOSING_PARENTHESIS]);
  }
  void fail_missingExpressionInThrow_withCascade() {
    ParserTestCase.parse5("parseThrowExpression", "throw;", [ParserErrorCode.MISSING_EXPRESSION_IN_THROW]);
  }
  void fail_missingExpressionInThrow_withoutCascade() {
    ParserTestCase.parse5("parseThrowExpressionWithoutCascade", "throw;", [ParserErrorCode.MISSING_EXPRESSION_IN_THROW]);
  }
  void fail_missingFunctionParameters_local_nonVoid_block() {
    ParserTestCase.parse5("parseStatement", "int f { return x;}", [ParserErrorCode.MISSING_FUNCTION_PARAMETERS]);
  }
  void fail_missingFunctionParameters_local_nonVoid_expression() {
    ParserTestCase.parse5("parseStatement", "int f => x;", [ParserErrorCode.MISSING_FUNCTION_PARAMETERS]);
  }
  void fail_namedFunctionExpression() {
    Expression expression = ParserTestCase.parse5("parsePrimaryExpression", "f() {}", [ParserErrorCode.NAMED_FUNCTION_EXPRESSION]);
    EngineTestCase.assertInstanceOf(FunctionExpression, expression);
  }
  void fail_unexpectedToken_invalidPostfixExpression() {
    ParserTestCase.parse5("parseExpression", "f()++", [ParserErrorCode.UNEXPECTED_TOKEN]);
  }
  void fail_voidVariable_initializer() {
    ParserTestCase.parse5("parseStatement", "void x = 0;", [ParserErrorCode.VOID_VARIABLE]);
  }
  void fail_voidVariable_noInitializer() {
    ParserTestCase.parse5("parseStatement", "void x;", [ParserErrorCode.VOID_VARIABLE]);
  }
  void test_abstractClassMember_constructor() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "abstract C.c();", [ParserErrorCode.ABSTRACT_CLASS_MEMBER]);
  }
  void test_abstractClassMember_field() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "abstract C f;", [ParserErrorCode.ABSTRACT_CLASS_MEMBER]);
  }
  void test_abstractClassMember_getter() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "abstract get m;", [ParserErrorCode.ABSTRACT_CLASS_MEMBER]);
  }
  void test_abstractClassMember_method() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "abstract m();", [ParserErrorCode.ABSTRACT_CLASS_MEMBER]);
  }
  void test_abstractClassMember_setter() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "abstract set m(v);", [ParserErrorCode.ABSTRACT_CLASS_MEMBER]);
  }
  void test_abstractTopLevelFunction_function() {
    ParserTestCase.parse5("parseCompilationUnit", "abstract f(v) {}", [ParserErrorCode.ABSTRACT_TOP_LEVEL_FUNCTION]);
  }
  void test_abstractTopLevelFunction_getter() {
    ParserTestCase.parse5("parseCompilationUnit", "abstract get m {}", [ParserErrorCode.ABSTRACT_TOP_LEVEL_FUNCTION]);
  }
  void test_abstractTopLevelFunction_setter() {
    ParserTestCase.parse5("parseCompilationUnit", "abstract set m(v) {}", [ParserErrorCode.ABSTRACT_TOP_LEVEL_FUNCTION]);
  }
  void test_abstractTopLevelVariable() {
    ParserTestCase.parse5("parseCompilationUnit", "abstract C f;", [ParserErrorCode.ABSTRACT_TOP_LEVEL_VARIABLE]);
  }
  void test_abstractTypeDef() {
    ParserTestCase.parse5("parseCompilationUnit", "abstract typedef F();", [ParserErrorCode.ABSTRACT_TYPEDEF]);
  }
  void test_breakOutsideOfLoop_breakInDoStatement() {
    ParserTestCase.parse5("parseDoStatement", "do {break;} while (x);", []);
  }
  void test_breakOutsideOfLoop_breakInForStatement() {
    ParserTestCase.parse5("parseForStatement", "for (; x;) {break;}", []);
  }
  void test_breakOutsideOfLoop_breakInIfStatement() {
    ParserTestCase.parse5("parseIfStatement", "if (x) {break;}", [ParserErrorCode.BREAK_OUTSIDE_OF_LOOP]);
  }
  void test_breakOutsideOfLoop_breakInSwitchStatement() {
    ParserTestCase.parse5("parseSwitchStatement", "switch (x) {case 1: break;}", []);
  }
  void test_breakOutsideOfLoop_breakInWhileStatement() {
    ParserTestCase.parse5("parseWhileStatement", "while (x) {break;}", []);
  }
  void test_breakOutsideOfLoop_functionExpression_inALoop() {
    ParserTestCase.parse5("parseStatement", "for(; x;) {() {break;};}", [ParserErrorCode.BREAK_OUTSIDE_OF_LOOP]);
  }
  void test_breakOutsideOfLoop_functionExpression_withALoop() {
    ParserTestCase.parse5("parseStatement", "() {for (; x;) {break;}};", []);
  }
  void test_constAndFinal() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "const final int x;", [ParserErrorCode.CONST_AND_FINAL]);
  }
  void test_constAndVar() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "const var x;", [ParserErrorCode.CONST_AND_VAR]);
  }
  void test_constClass() {
    ParserTestCase.parse5("parseCompilationUnit", "const class C {}", [ParserErrorCode.CONST_CLASS]);
  }
  void test_constMethod() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "const int m() {}", [ParserErrorCode.CONST_METHOD]);
  }
  void test_constTypedef() {
    ParserTestCase.parse5("parseCompilationUnit", "const typedef F();", [ParserErrorCode.CONST_TYPEDEF]);
  }
  void test_continueOutsideOfLoop_continueInDoStatement() {
    ParserTestCase.parse5("parseDoStatement", "do {continue;} while (x);", []);
  }
  void test_continueOutsideOfLoop_continueInForStatement() {
    ParserTestCase.parse5("parseForStatement", "for (; x;) {continue;}", []);
  }
  void test_continueOutsideOfLoop_continueInIfStatement() {
    ParserTestCase.parse5("parseIfStatement", "if (x) {continue;}", [ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP]);
  }
  void test_continueOutsideOfLoop_continueInSwitchStatement() {
    ParserTestCase.parse5("parseSwitchStatement", "switch (x) {case 1: continue a;}", []);
  }
  void test_continueOutsideOfLoop_continueInWhileStatement() {
    ParserTestCase.parse5("parseWhileStatement", "while (x) {continue;}", []);
  }
  void test_continueOutsideOfLoop_functionExpression_inALoop() {
    ParserTestCase.parse5("parseStatement", "for(; x;) {() {continue;};}", [ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP]);
  }
  void test_continueOutsideOfLoop_functionExpression_withALoop() {
    ParserTestCase.parse5("parseStatement", "() {for (; x;) {continue;}};", []);
  }
  void test_continueWithoutLabelInCase_error() {
    ParserTestCase.parse5("parseSwitchStatement", "switch (x) {case 1: continue;}", [ParserErrorCode.CONTINUE_WITHOUT_LABEL_IN_CASE]);
  }
  void test_continueWithoutLabelInCase_noError() {
    ParserTestCase.parse5("parseSwitchStatement", "switch (x) {case 1: continue a;}", []);
  }
  void test_continueWithoutLabelInCase_noError_switchInLoop() {
    ParserTestCase.parse5("parseWhileStatement", "while (a) { switch (b) {default: continue;}}", []);
  }
  void test_directiveAfterDeclaration_classBeforeDirective() {
    CompilationUnit unit = ParserTestCase.parse5("parseCompilationUnit", "class Foo{} library l;", [ParserErrorCode.DIRECTIVE_AFTER_DECLARATION]);
    JUnitTestCase.assertNotNull(unit);
  }
  void test_directiveAfterDeclaration_classBetweenDirectives() {
    CompilationUnit unit = ParserTestCase.parse5("parseCompilationUnit", "library l;\nclass Foo{}\npart 'a.dart';", [ParserErrorCode.DIRECTIVE_AFTER_DECLARATION]);
    JUnitTestCase.assertNotNull(unit);
  }
  void test_duplicatedModifier_const() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "const const m;", [ParserErrorCode.DUPLICATED_MODIFIER]);
  }
  void test_duplicatedModifier_external() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "external external f();", [ParserErrorCode.DUPLICATED_MODIFIER]);
  }
  void test_duplicatedModifier_factory() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "factory factory C() {}", [ParserErrorCode.DUPLICATED_MODIFIER]);
  }
  void test_duplicatedModifier_final() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "final final m;", [ParserErrorCode.DUPLICATED_MODIFIER]);
  }
  void test_duplicatedModifier_static() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "static static m;", [ParserErrorCode.DUPLICATED_MODIFIER]);
  }
  void test_duplicatedModifier_var() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "var var m;", [ParserErrorCode.DUPLICATED_MODIFIER]);
  }
  void test_duplicateLabelInSwitchStatement() {
    ParserTestCase.parse5("parseSwitchStatement", "switch (e) {l1: case 0: break; l1: case 1: break;}", [ParserErrorCode.DUPLICATE_LABEL_IN_SWITCH_STATEMENT]);
  }
  void test_expectedCaseOrDefault() {
    ParserTestCase.parse5("parseSwitchStatement", "switch (e) {break;}", [ParserErrorCode.EXPECTED_CASE_OR_DEFAULT]);
  }
  void test_expectedClassMember_inClass_afterType() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "heart 2 heart", [ParserErrorCode.EXPECTED_CLASS_MEMBER]);
  }
  void test_expectedClassMember_inClass_beforeType() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "4 score", [ParserErrorCode.EXPECTED_CLASS_MEMBER]);
  }
  void test_expectedExecutable_inClass_afterVoid() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "void 2 void", [ParserErrorCode.EXPECTED_EXECUTABLE]);
  }
  void test_expectedExecutable_topLevel_afterType() {
    ParserTestCase.parse4("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "heart 2 heart", [ParserErrorCode.EXPECTED_EXECUTABLE]);
  }
  void test_expectedExecutable_topLevel_afterVoid() {
    ParserTestCase.parse4("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "void 2 void", [ParserErrorCode.EXPECTED_EXECUTABLE]);
  }
  void test_expectedExecutable_topLevel_beforeType() {
    ParserTestCase.parse4("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "4 score", [ParserErrorCode.EXPECTED_EXECUTABLE]);
  }
  void test_expectedStringLiteral() {
    StringLiteral expression = ParserTestCase.parse5("parseStringLiteral", "1", [ParserErrorCode.EXPECTED_STRING_LITERAL]);
    JUnitTestCase.assertTrue(expression.isSynthetic());
  }
  void test_expectedToken_commaMissingInArgumentList() {
    ParserTestCase.parse5("parseArgumentList", "(x, y z)", [ParserErrorCode.EXPECTED_TOKEN]);
  }
  void test_expectedToken_semicolonMissingAfterExpression() {
    ParserTestCase.parse5("parseStatement", "x", [ParserErrorCode.EXPECTED_TOKEN]);
  }
  void test_expectedToken_whileMissingInDoStatement() {
    ParserTestCase.parse5("parseStatement", "do {} (x);", [ParserErrorCode.EXPECTED_TOKEN]);
  }
  void test_exportDirectiveAfterPartDirective() {
    ParserTestCase.parse5("parseCompilationUnit", "part 'a.dart'; export 'b.dart';", [ParserErrorCode.EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE]);
  }
  void test_externalAfterConst() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "const external C();", [ParserErrorCode.EXTERNAL_AFTER_CONST]);
  }
  void test_externalAfterFactory() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "factory external C();", [ParserErrorCode.EXTERNAL_AFTER_FACTORY]);
  }
  void test_externalAfterStatic() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "static external int m();", [ParserErrorCode.EXTERNAL_AFTER_STATIC]);
  }
  void test_externalClass() {
    ParserTestCase.parse5("parseCompilationUnit", "external class C {}", [ParserErrorCode.EXTERNAL_CLASS]);
  }
  void test_externalConstructorWithBody_factory() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "external factory C() {}", [ParserErrorCode.EXTERNAL_CONSTRUCTOR_WITH_BODY]);
  }
  void test_externalConstructorWithBody_named() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "external C.c() {}", [ParserErrorCode.EXTERNAL_CONSTRUCTOR_WITH_BODY]);
  }
  void test_externalField_const() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "external const A f;", [ParserErrorCode.EXTERNAL_FIELD]);
  }
  void test_externalField_final() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "external final A f;", [ParserErrorCode.EXTERNAL_FIELD]);
  }
  void test_externalField_static() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "external static A f;", [ParserErrorCode.EXTERNAL_FIELD]);
  }
  void test_externalField_typed() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "external A f;", [ParserErrorCode.EXTERNAL_FIELD]);
  }
  void test_externalField_untyped() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "external var f;", [ParserErrorCode.EXTERNAL_FIELD]);
  }
  void test_externalGetterWithBody() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "external int get x {}", [ParserErrorCode.EXTERNAL_GETTER_WITH_BODY]);
  }
  void test_externalMethodWithBody() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "external m() {}", [ParserErrorCode.EXTERNAL_METHOD_WITH_BODY]);
  }
  void test_externalOperatorWithBody() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "external operator +(int value) {}", [ParserErrorCode.EXTERNAL_OPERATOR_WITH_BODY]);
  }
  void test_externalSetterWithBody() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "external set x(int value) {}", [ParserErrorCode.EXTERNAL_SETTER_WITH_BODY]);
  }
  void test_externalTypedef() {
    ParserTestCase.parse5("parseCompilationUnit", "external typedef F();", [ParserErrorCode.EXTERNAL_TYPEDEF]);
  }
  void test_factoryTopLevelDeclaration_class() {
    ParserTestCase.parse5("parseCompilationUnit", "factory class C {}", [ParserErrorCode.FACTORY_TOP_LEVEL_DECLARATION]);
  }
  void test_factoryTopLevelDeclaration_typedef() {
    ParserTestCase.parse5("parseCompilationUnit", "factory typedef F();", [ParserErrorCode.FACTORY_TOP_LEVEL_DECLARATION]);
  }
  void test_fieldInitializerOutsideConstructor() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "void m(this.x);", [ParserErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR]);
  }
  void test_finalAndVar() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "final var x;", [ParserErrorCode.FINAL_AND_VAR]);
  }
  void test_finalClass() {
    ParserTestCase.parse5("parseCompilationUnit", "final class C {}", [ParserErrorCode.FINAL_CLASS]);
  }
  void test_finalConstructor() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "final C() {}", [ParserErrorCode.FINAL_CONSTRUCTOR]);
  }
  void test_finalMethod() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "final int m() {}", [ParserErrorCode.FINAL_METHOD]);
  }
  void test_finalTypedef() {
    ParserTestCase.parse5("parseCompilationUnit", "final typedef F();", [ParserErrorCode.FINAL_TYPEDEF]);
  }
  void test_getterWithParameters() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "int get x() {}", [ParserErrorCode.GETTER_WITH_PARAMETERS]);
  }
  void test_illegalAssignmentToNonAssignable_superAssigned() {
    ParserTestCase.parse5("parseExpression", "super = x;", [ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE]);
  }
  void test_implementsBeforeExtends() {
    ParserTestCase.parse5("parseCompilationUnit", "class A implements B extends C {}", [ParserErrorCode.IMPLEMENTS_BEFORE_EXTENDS]);
  }
  void test_implementsBeforeWith() {
    ParserTestCase.parse5("parseCompilationUnit", "class A extends B implements C with D {}", [ParserErrorCode.IMPLEMENTS_BEFORE_WITH]);
  }
  void test_importDirectiveAfterPartDirective() {
    ParserTestCase.parse5("parseCompilationUnit", "part 'a.dart'; import 'b.dart';", [ParserErrorCode.IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE]);
  }
  void test_initializedVariableInForEach() {
    ParserTestCase.parse5("parseForStatement", "for (int a = 0 in foo) {}", [ParserErrorCode.INITIALIZED_VARIABLE_IN_FOR_EACH]);
  }
  void test_invalidCodePoint() {
    ParserTestCase.parse5("parseStringLiteral", "'\\uD900'", [ParserErrorCode.INVALID_CODE_POINT]);
  }
  void test_invalidHexEscape_invalidDigit() {
    ParserTestCase.parse5("parseStringLiteral", "'\\x0 a'", [ParserErrorCode.INVALID_HEX_ESCAPE]);
  }
  void test_invalidHexEscape_tooFewDigits() {
    ParserTestCase.parse5("parseStringLiteral", "'\\x0'", [ParserErrorCode.INVALID_HEX_ESCAPE]);
  }
  void test_invalidOperator() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "void operator ===(x) {}", [ParserErrorCode.INVALID_OPERATOR]);
  }
  void test_invalidOperatorForSuper() {
    ParserTestCase.parse5("parseUnaryExpression", "++super", [ParserErrorCode.INVALID_OPERATOR_FOR_SUPER]);
  }
  void test_invalidUnicodeEscape_incomplete_noDigits() {
    ParserTestCase.parse5("parseStringLiteral", "'\\u{'", [ParserErrorCode.INVALID_UNICODE_ESCAPE]);
  }
  void test_invalidUnicodeEscape_incomplete_someDigits() {
    ParserTestCase.parse5("parseStringLiteral", "'\\u{0A'", [ParserErrorCode.INVALID_UNICODE_ESCAPE]);
  }
  void test_invalidUnicodeEscape_invalidDigit() {
    ParserTestCase.parse5("parseStringLiteral", "'\\u0 a'", [ParserErrorCode.INVALID_UNICODE_ESCAPE]);
  }
  void test_invalidUnicodeEscape_tooFewDigits_fixed() {
    ParserTestCase.parse5("parseStringLiteral", "'\\u04'", [ParserErrorCode.INVALID_UNICODE_ESCAPE]);
  }
  void test_invalidUnicodeEscape_tooFewDigits_variable() {
    ParserTestCase.parse5("parseStringLiteral", "'\\u{}'", [ParserErrorCode.INVALID_UNICODE_ESCAPE]);
  }
  void test_invalidUnicodeEscape_tooManyDigits_variable() {
    ParserTestCase.parse5("parseStringLiteral", "'\\u{12345678}'", [ParserErrorCode.INVALID_UNICODE_ESCAPE, ParserErrorCode.INVALID_CODE_POINT]);
  }
  void test_libraryDirectiveNotFirst() {
    ParserTestCase.parse5("parseCompilationUnit", "import 'x.dart'; library l;", [ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST]);
  }
  void test_libraryDirectiveNotFirst_afterPart() {
    CompilationUnit unit = ParserTestCase.parse5("parseCompilationUnit", "part 'a.dart';\nlibrary l;", [ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST]);
    JUnitTestCase.assertNotNull(unit);
  }
  void test_missingAssignableSelector_identifiersAssigned() {
    ParserTestCase.parse5("parseExpression", "x.y = y;", []);
  }
  void test_missingAssignableSelector_primarySelectorPostfix() {
    ParserTestCase.parse5("parseExpression", "x(y)(z)++", [ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR]);
  }
  void test_missingAssignableSelector_selector() {
    ParserTestCase.parse5("parseExpression", "x(y)(z).a++", []);
  }
  void test_missingAssignableSelector_superPrimaryExpression() {
    SuperExpression expression = ParserTestCase.parse5("parsePrimaryExpression", "super", [ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR]);
    JUnitTestCase.assertNotNull(expression.keyword);
  }
  void test_missingAssignableSelector_superPropertyAccessAssigned() {
    ParserTestCase.parse5("parseExpression", "super.x = x;", []);
  }
  void test_missingCatchOrFinally() {
    TryStatement statement = ParserTestCase.parse5("parseTryStatement", "try {}", [ParserErrorCode.MISSING_CATCH_OR_FINALLY]);
    JUnitTestCase.assertNotNull(statement);
  }
  void test_missingClassBody() {
    ParserTestCase.parse5("parseCompilationUnit", "class A class B {}", [ParserErrorCode.MISSING_CLASS_BODY]);
  }
  void test_missingConstFinalVarOrType() {
    ParserTestCase.parse4("parseFinalConstVarOrType", <Object> [false], "a;", [ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE]);
  }
  void test_missingFunctionBody_emptyNotAllowed() {
    ParserTestCase.parse4("parseFunctionBody", <Object> [false, false], ";", [ParserErrorCode.MISSING_FUNCTION_BODY]);
  }
  void test_missingFunctionBody_invalid() {
    ParserTestCase.parse4("parseFunctionBody", <Object> [false, false], "return 0;", [ParserErrorCode.MISSING_FUNCTION_BODY]);
  }
  void test_missingFunctionParameters_local_void_block() {
    ParserTestCase.parse5("parseStatement", "void f { return x;}", [ParserErrorCode.MISSING_FUNCTION_PARAMETERS]);
  }
  void test_missingFunctionParameters_local_void_expression() {
    ParserTestCase.parse5("parseStatement", "void f => x;", [ParserErrorCode.MISSING_FUNCTION_PARAMETERS]);
  }
  void test_missingFunctionParameters_topLevel_nonVoid_block() {
    ParserTestCase.parse5("parseCompilationUnit", "int f { return x;}", [ParserErrorCode.MISSING_FUNCTION_PARAMETERS]);
  }
  void test_missingFunctionParameters_topLevel_nonVoid_expression() {
    ParserTestCase.parse5("parseCompilationUnit", "int f => x;", [ParserErrorCode.MISSING_FUNCTION_PARAMETERS]);
  }
  void test_missingFunctionParameters_topLevel_void_block() {
    ParserTestCase.parse5("parseCompilationUnit", "void f { return x;}", [ParserErrorCode.MISSING_FUNCTION_PARAMETERS]);
  }
  void test_missingFunctionParameters_topLevel_void_expression() {
    ParserTestCase.parse5("parseCompilationUnit", "void f => x;", [ParserErrorCode.MISSING_FUNCTION_PARAMETERS]);
  }
  void test_missingIdentifier_functionDeclaration_returnTypeWithoutName() {
    ParserTestCase.parse5("parseFunctionDeclarationStatement", "A<T> () {}", [ParserErrorCode.MISSING_IDENTIFIER]);
  }
  void test_missingIdentifier_number() {
    SimpleIdentifier expression = ParserTestCase.parse5("parseSimpleIdentifier", "1", [ParserErrorCode.MISSING_IDENTIFIER]);
    JUnitTestCase.assertTrue(expression.isSynthetic());
  }
  void test_missingKeywordOperator() {
    ParserTestCase.parse4("parseOperator", <Object> [emptyCommentAndMetadata(), null, null], "+(x) {}", [ParserErrorCode.MISSING_KEYWORD_OPERATOR]);
  }
  void test_missingNameInLibraryDirective() {
    CompilationUnit unit = ParserTestCase.parse5("parseCompilationUnit", "library;", [ParserErrorCode.MISSING_NAME_IN_LIBRARY_DIRECTIVE]);
    JUnitTestCase.assertNotNull(unit);
  }
  void test_missingNameInPartOfDirective() {
    CompilationUnit unit = ParserTestCase.parse5("parseCompilationUnit", "part of;", [ParserErrorCode.MISSING_NAME_IN_PART_OF_DIRECTIVE]);
    JUnitTestCase.assertNotNull(unit);
  }
  void test_missingTerminatorForParameterGroup_named() {
    ParserTestCase.parse5("parseFormalParameterList", "(a, {b: 0)", [ParserErrorCode.MISSING_TERMINATOR_FOR_PARAMETER_GROUP]);
  }
  void test_missingTerminatorForParameterGroup_optional() {
    ParserTestCase.parse5("parseFormalParameterList", "(a, [b = 0)", [ParserErrorCode.MISSING_TERMINATOR_FOR_PARAMETER_GROUP]);
  }
  void test_missingTypedefParameters_nonVoid() {
    ParserTestCase.parse5("parseCompilationUnit", "typedef int F;", [ParserErrorCode.MISSING_TYPEDEF_PARAMETERS]);
  }
  void test_missingTypedefParameters_typeParameters() {
    ParserTestCase.parse5("parseCompilationUnit", "typedef F<E>;", [ParserErrorCode.MISSING_TYPEDEF_PARAMETERS]);
  }
  void test_missingTypedefParameters_void() {
    ParserTestCase.parse5("parseCompilationUnit", "typedef void F;", [ParserErrorCode.MISSING_TYPEDEF_PARAMETERS]);
  }
  void test_missingVariableInForEach() {
    ParserTestCase.parse5("parseForStatement", "for (a < b in foo) {}", [ParserErrorCode.MISSING_VARIABLE_IN_FOR_EACH]);
  }
  void test_mixedParameterGroups_namedPositional() {
    ParserTestCase.parse5("parseFormalParameterList", "(a, {b}, [c])", [ParserErrorCode.MIXED_PARAMETER_GROUPS]);
  }
  void test_mixedParameterGroups_positionalNamed() {
    ParserTestCase.parse5("parseFormalParameterList", "(a, [b], {c})", [ParserErrorCode.MIXED_PARAMETER_GROUPS]);
  }
  void test_multipleLibraryDirectives() {
    ParserTestCase.parse5("parseCompilationUnit", "library l; library m;", [ParserErrorCode.MULTIPLE_LIBRARY_DIRECTIVES]);
  }
  void test_multipleNamedParameterGroups() {
    ParserTestCase.parse5("parseFormalParameterList", "(a, {b}, {c})", [ParserErrorCode.MULTIPLE_NAMED_PARAMETER_GROUPS]);
  }
  void test_multiplePartOfDirectives() {
    ParserTestCase.parse5("parseCompilationUnit", "part of l; part of m;", [ParserErrorCode.MULTIPLE_PART_OF_DIRECTIVES]);
  }
  void test_multiplePositionalParameterGroups() {
    ParserTestCase.parse5("parseFormalParameterList", "(a, [b], [c])", [ParserErrorCode.MULTIPLE_POSITIONAL_PARAMETER_GROUPS]);
  }
  void test_multipleVariablesInForEach() {
    ParserTestCase.parse5("parseForStatement", "for (int a, b in foo) {}", [ParserErrorCode.MULTIPLE_VARIABLES_IN_FOR_EACH]);
  }
  void test_namedParameterOutsideGroup() {
    ParserTestCase.parse5("parseFormalParameterList", "(a, b : 0)", [ParserErrorCode.NAMED_PARAMETER_OUTSIDE_GROUP]);
  }
  void test_nonConstructorFactory_field() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "factory int x;", [ParserErrorCode.NON_CONSTRUCTOR_FACTORY]);
  }
  void test_nonConstructorFactory_method() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "factory int m() {}", [ParserErrorCode.NON_CONSTRUCTOR_FACTORY]);
  }
  void test_nonIdentifierLibraryName_library() {
    CompilationUnit unit = ParserTestCase.parse5("parseCompilationUnit", "library 'lib';", [ParserErrorCode.NON_IDENTIFIER_LIBRARY_NAME]);
    JUnitTestCase.assertNotNull(unit);
  }
  void test_nonIdentifierLibraryName_partOf() {
    CompilationUnit unit = ParserTestCase.parse5("parseCompilationUnit", "part of 'lib';", [ParserErrorCode.NON_IDENTIFIER_LIBRARY_NAME]);
    JUnitTestCase.assertNotNull(unit);
  }
  void test_nonPartOfDirectiveInPart_after() {
    ParserTestCase.parse5("parseCompilationUnit", "part of l; part 'f.dart';", [ParserErrorCode.NON_PART_OF_DIRECTIVE_IN_PART]);
  }
  void test_nonPartOfDirectiveInPart_before() {
    ParserTestCase.parse5("parseCompilationUnit", "part 'f.dart'; part of m;", [ParserErrorCode.NON_PART_OF_DIRECTIVE_IN_PART]);
  }
  void test_nonUserDefinableOperator() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "operator +=(int x) => x + 1;", [ParserErrorCode.NON_USER_DEFINABLE_OPERATOR]);
  }
  void test_positionalAfterNamedArgument() {
    ParserTestCase.parse5("parseArgumentList", "(x: 1, 2)", [ParserErrorCode.POSITIONAL_AFTER_NAMED_ARGUMENT]);
  }
  void test_positionalParameterOutsideGroup() {
    ParserTestCase.parse5("parseFormalParameterList", "(a, b = 0)", [ParserErrorCode.POSITIONAL_PARAMETER_OUTSIDE_GROUP]);
  }
  void test_staticAfterConst() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "final static int f;", [ParserErrorCode.STATIC_AFTER_FINAL]);
  }
  void test_staticAfterFinal() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "const static int f;", [ParserErrorCode.STATIC_AFTER_CONST]);
  }
  void test_staticAfterVar() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "var static f;", [ParserErrorCode.STATIC_AFTER_VAR]);
  }
  void test_staticConstructor() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "static C.m() {}", [ParserErrorCode.STATIC_CONSTRUCTOR]);
  }
  void test_staticOperator_noReturnType() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "static operator +(int x) => x + 1;", [ParserErrorCode.STATIC_OPERATOR]);
  }
  void test_staticOperator_returnType() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "static int operator +(int x) => x + 1;", [ParserErrorCode.STATIC_OPERATOR]);
  }
  void test_staticTopLevelDeclaration_class() {
    ParserTestCase.parse5("parseCompilationUnit", "static class C {}", [ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION]);
  }
  void test_staticTopLevelDeclaration_typedef() {
    ParserTestCase.parse5("parseCompilationUnit", "static typedef F();", [ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION]);
  }
  void test_staticTopLevelDeclaration_variable() {
    ParserTestCase.parse5("parseCompilationUnit", "static var x;", [ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION]);
  }
  void test_topLevelOperator_withoutType() {
    ParserTestCase.parse4("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "operator +(bool x, bool y) => x | y;", [ParserErrorCode.TOP_LEVEL_OPERATOR]);
  }
  void test_topLevelOperator_withType() {
    ParserTestCase.parse4("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "bool operator +(bool x, bool y) => x | y;", [ParserErrorCode.TOP_LEVEL_OPERATOR]);
  }
  void test_topLevelOperator_withVoid() {
    ParserTestCase.parse4("parseCompilationUnitMember", <Object> [emptyCommentAndMetadata()], "void operator +(bool x, bool y) => x | y;", [ParserErrorCode.TOP_LEVEL_OPERATOR]);
  }
  void test_unexpectedTerminatorForParameterGroup_named() {
    ParserTestCase.parse5("parseFormalParameterList", "(a, b})", [ParserErrorCode.UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP]);
  }
  void test_unexpectedTerminatorForParameterGroup_optional() {
    ParserTestCase.parse5("parseFormalParameterList", "(a, b])", [ParserErrorCode.UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP]);
  }
  void test_unexpectedToken_semicolonBetweenClassMembers() {
    ParserTestCase.parse4("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class C { int x; ; int y;}", [ParserErrorCode.UNEXPECTED_TOKEN]);
  }
  void test_unexpectedToken_semicolonBetweenCompilationUnitMembers() {
    ParserTestCase.parse5("parseCompilationUnit", "int x; ; int y;", [ParserErrorCode.UNEXPECTED_TOKEN]);
  }
  void test_useOfUnaryPlusOperator() {
    ParserTestCase.parse5("parseUnaryExpression", "+x", [ParserErrorCode.USE_OF_UNARY_PLUS_OPERATOR]);
  }
  void test_varClass() {
    ParserTestCase.parse5("parseCompilationUnit", "var class C {}", [ParserErrorCode.VAR_CLASS]);
  }
  void test_varConstructor() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "var C() {}", [ParserErrorCode.CONSTRUCTOR_WITH_RETURN_TYPE]);
  }
  void test_varReturnType() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "var m() {}", [ParserErrorCode.VAR_RETURN_TYPE]);
  }
  void test_varTypedef() {
    ParserTestCase.parse5("parseCompilationUnit", "var typedef F();", [ParserErrorCode.VAR_TYPEDEF]);
  }
  void test_voidField_initializer() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "void x = 0;", [ParserErrorCode.VOID_VARIABLE]);
  }
  void test_voidField_noInitializer() {
    ParserTestCase.parse4("parseClassMember", <Object> ["C"], "void x;", [ParserErrorCode.VOID_VARIABLE]);
  }
  void test_voidParameter() {
    ParserTestCase.parse5("parseNormalFormalParameter", "void a)", [ParserErrorCode.VOID_PARAMETER]);
  }
  void test_withBeforeExtends() {
    ParserTestCase.parse5("parseCompilationUnit", "class A with B extends C {}", [ParserErrorCode.WITH_BEFORE_EXTENDS]);
  }
  void test_withWithoutExtends() {
    ParserTestCase.parse4("parseClassDeclaration", <Object> [emptyCommentAndMetadata(), null], "class A with B, C {}", [ParserErrorCode.WITH_WITHOUT_EXTENDS]);
  }
  void test_wrongSeparatorForNamedParameter() {
    ParserTestCase.parse5("parseFormalParameterList", "(a, {b = 0})", [ParserErrorCode.WRONG_SEPARATOR_FOR_NAMED_PARAMETER]);
  }
  void test_wrongSeparatorForPositionalParameter() {
    ParserTestCase.parse5("parseFormalParameterList", "(a, [b : 0])", [ParserErrorCode.WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER]);
  }
  void test_wrongTerminatorForParameterGroup_named() {
    ParserTestCase.parse5("parseFormalParameterList", "(a, {b, c])", [ParserErrorCode.WRONG_TERMINATOR_FOR_PARAMETER_GROUP]);
  }
  void test_wrongTerminatorForParameterGroup_optional() {
    ParserTestCase.parse5("parseFormalParameterList", "(a, [b, c})", [ParserErrorCode.WRONG_TERMINATOR_FOR_PARAMETER_GROUP]);
  }
  static dartSuite() {
    _ut.group('ErrorParserTest', () {
      _ut.test('test_abstractClassMember_constructor', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_abstractClassMember_constructor);
      });
      _ut.test('test_abstractClassMember_field', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_abstractClassMember_field);
      });
      _ut.test('test_abstractClassMember_getter', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_abstractClassMember_getter);
      });
      _ut.test('test_abstractClassMember_method', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_abstractClassMember_method);
      });
      _ut.test('test_abstractClassMember_setter', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_abstractClassMember_setter);
      });
      _ut.test('test_abstractTopLevelFunction_function', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_abstractTopLevelFunction_function);
      });
      _ut.test('test_abstractTopLevelFunction_getter', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_abstractTopLevelFunction_getter);
      });
      _ut.test('test_abstractTopLevelFunction_setter', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_abstractTopLevelFunction_setter);
      });
      _ut.test('test_abstractTopLevelVariable', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_abstractTopLevelVariable);
      });
      _ut.test('test_abstractTypeDef', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_abstractTypeDef);
      });
      _ut.test('test_breakOutsideOfLoop_breakInDoStatement', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_breakOutsideOfLoop_breakInDoStatement);
      });
      _ut.test('test_breakOutsideOfLoop_breakInForStatement', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_breakOutsideOfLoop_breakInForStatement);
      });
      _ut.test('test_breakOutsideOfLoop_breakInIfStatement', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_breakOutsideOfLoop_breakInIfStatement);
      });
      _ut.test('test_breakOutsideOfLoop_breakInSwitchStatement', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_breakOutsideOfLoop_breakInSwitchStatement);
      });
      _ut.test('test_breakOutsideOfLoop_breakInWhileStatement', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_breakOutsideOfLoop_breakInWhileStatement);
      });
      _ut.test('test_breakOutsideOfLoop_functionExpression_inALoop', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_breakOutsideOfLoop_functionExpression_inALoop);
      });
      _ut.test('test_breakOutsideOfLoop_functionExpression_withALoop', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_breakOutsideOfLoop_functionExpression_withALoop);
      });
      _ut.test('test_constAndFinal', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_constAndFinal);
      });
      _ut.test('test_constAndVar', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_constAndVar);
      });
      _ut.test('test_constClass', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_constClass);
      });
      _ut.test('test_constMethod', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_constMethod);
      });
      _ut.test('test_constTypedef', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_constTypedef);
      });
      _ut.test('test_continueOutsideOfLoop_continueInDoStatement', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_continueOutsideOfLoop_continueInDoStatement);
      });
      _ut.test('test_continueOutsideOfLoop_continueInForStatement', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_continueOutsideOfLoop_continueInForStatement);
      });
      _ut.test('test_continueOutsideOfLoop_continueInIfStatement', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_continueOutsideOfLoop_continueInIfStatement);
      });
      _ut.test('test_continueOutsideOfLoop_continueInSwitchStatement', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_continueOutsideOfLoop_continueInSwitchStatement);
      });
      _ut.test('test_continueOutsideOfLoop_continueInWhileStatement', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_continueOutsideOfLoop_continueInWhileStatement);
      });
      _ut.test('test_continueOutsideOfLoop_functionExpression_inALoop', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_continueOutsideOfLoop_functionExpression_inALoop);
      });
      _ut.test('test_continueOutsideOfLoop_functionExpression_withALoop', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_continueOutsideOfLoop_functionExpression_withALoop);
      });
      _ut.test('test_continueWithoutLabelInCase_error', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_continueWithoutLabelInCase_error);
      });
      _ut.test('test_continueWithoutLabelInCase_noError', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_continueWithoutLabelInCase_noError);
      });
      _ut.test('test_continueWithoutLabelInCase_noError_switchInLoop', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_continueWithoutLabelInCase_noError_switchInLoop);
      });
      _ut.test('test_directiveAfterDeclaration_classBeforeDirective', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_directiveAfterDeclaration_classBeforeDirective);
      });
      _ut.test('test_directiveAfterDeclaration_classBetweenDirectives', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_directiveAfterDeclaration_classBetweenDirectives);
      });
      _ut.test('test_duplicateLabelInSwitchStatement', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_duplicateLabelInSwitchStatement);
      });
      _ut.test('test_duplicatedModifier_const', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_duplicatedModifier_const);
      });
      _ut.test('test_duplicatedModifier_external', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_duplicatedModifier_external);
      });
      _ut.test('test_duplicatedModifier_factory', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_duplicatedModifier_factory);
      });
      _ut.test('test_duplicatedModifier_final', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_duplicatedModifier_final);
      });
      _ut.test('test_duplicatedModifier_static', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_duplicatedModifier_static);
      });
      _ut.test('test_duplicatedModifier_var', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_duplicatedModifier_var);
      });
      _ut.test('test_expectedCaseOrDefault', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_expectedCaseOrDefault);
      });
      _ut.test('test_expectedClassMember_inClass_afterType', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_expectedClassMember_inClass_afterType);
      });
      _ut.test('test_expectedClassMember_inClass_beforeType', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_expectedClassMember_inClass_beforeType);
      });
      _ut.test('test_expectedExecutable_inClass_afterVoid', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_expectedExecutable_inClass_afterVoid);
      });
      _ut.test('test_expectedExecutable_topLevel_afterType', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_expectedExecutable_topLevel_afterType);
      });
      _ut.test('test_expectedExecutable_topLevel_afterVoid', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_expectedExecutable_topLevel_afterVoid);
      });
      _ut.test('test_expectedExecutable_topLevel_beforeType', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_expectedExecutable_topLevel_beforeType);
      });
      _ut.test('test_expectedStringLiteral', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_expectedStringLiteral);
      });
      _ut.test('test_expectedToken_commaMissingInArgumentList', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_expectedToken_commaMissingInArgumentList);
      });
      _ut.test('test_expectedToken_semicolonMissingAfterExpression', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_expectedToken_semicolonMissingAfterExpression);
      });
      _ut.test('test_expectedToken_whileMissingInDoStatement', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_expectedToken_whileMissingInDoStatement);
      });
      _ut.test('test_exportDirectiveAfterPartDirective', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_exportDirectiveAfterPartDirective);
      });
      _ut.test('test_externalAfterConst', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_externalAfterConst);
      });
      _ut.test('test_externalAfterFactory', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_externalAfterFactory);
      });
      _ut.test('test_externalAfterStatic', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_externalAfterStatic);
      });
      _ut.test('test_externalClass', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_externalClass);
      });
      _ut.test('test_externalConstructorWithBody_factory', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_externalConstructorWithBody_factory);
      });
      _ut.test('test_externalConstructorWithBody_named', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_externalConstructorWithBody_named);
      });
      _ut.test('test_externalField_const', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_externalField_const);
      });
      _ut.test('test_externalField_final', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_externalField_final);
      });
      _ut.test('test_externalField_static', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_externalField_static);
      });
      _ut.test('test_externalField_typed', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_externalField_typed);
      });
      _ut.test('test_externalField_untyped', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_externalField_untyped);
      });
      _ut.test('test_externalGetterWithBody', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_externalGetterWithBody);
      });
      _ut.test('test_externalMethodWithBody', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_externalMethodWithBody);
      });
      _ut.test('test_externalOperatorWithBody', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_externalOperatorWithBody);
      });
      _ut.test('test_externalSetterWithBody', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_externalSetterWithBody);
      });
      _ut.test('test_externalTypedef', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_externalTypedef);
      });
      _ut.test('test_factoryTopLevelDeclaration_class', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_factoryTopLevelDeclaration_class);
      });
      _ut.test('test_factoryTopLevelDeclaration_typedef', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_factoryTopLevelDeclaration_typedef);
      });
      _ut.test('test_fieldInitializerOutsideConstructor', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_fieldInitializerOutsideConstructor);
      });
      _ut.test('test_finalAndVar', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_finalAndVar);
      });
      _ut.test('test_finalClass', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_finalClass);
      });
      _ut.test('test_finalConstructor', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_finalConstructor);
      });
      _ut.test('test_finalMethod', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_finalMethod);
      });
      _ut.test('test_finalTypedef', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_finalTypedef);
      });
      _ut.test('test_getterWithParameters', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_getterWithParameters);
      });
      _ut.test('test_illegalAssignmentToNonAssignable_superAssigned', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_illegalAssignmentToNonAssignable_superAssigned);
      });
      _ut.test('test_implementsBeforeExtends', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_implementsBeforeExtends);
      });
      _ut.test('test_implementsBeforeWith', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_implementsBeforeWith);
      });
      _ut.test('test_importDirectiveAfterPartDirective', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_importDirectiveAfterPartDirective);
      });
      _ut.test('test_initializedVariableInForEach', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_initializedVariableInForEach);
      });
      _ut.test('test_invalidCodePoint', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_invalidCodePoint);
      });
      _ut.test('test_invalidHexEscape_invalidDigit', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_invalidHexEscape_invalidDigit);
      });
      _ut.test('test_invalidHexEscape_tooFewDigits', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_invalidHexEscape_tooFewDigits);
      });
      _ut.test('test_invalidOperator', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_invalidOperator);
      });
      _ut.test('test_invalidOperatorForSuper', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_invalidOperatorForSuper);
      });
      _ut.test('test_invalidUnicodeEscape_incomplete_noDigits', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_invalidUnicodeEscape_incomplete_noDigits);
      });
      _ut.test('test_invalidUnicodeEscape_incomplete_someDigits', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_invalidUnicodeEscape_incomplete_someDigits);
      });
      _ut.test('test_invalidUnicodeEscape_invalidDigit', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_invalidUnicodeEscape_invalidDigit);
      });
      _ut.test('test_invalidUnicodeEscape_tooFewDigits_fixed', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_invalidUnicodeEscape_tooFewDigits_fixed);
      });
      _ut.test('test_invalidUnicodeEscape_tooFewDigits_variable', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_invalidUnicodeEscape_tooFewDigits_variable);
      });
      _ut.test('test_invalidUnicodeEscape_tooManyDigits_variable', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_invalidUnicodeEscape_tooManyDigits_variable);
      });
      _ut.test('test_libraryDirectiveNotFirst', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_libraryDirectiveNotFirst);
      });
      _ut.test('test_libraryDirectiveNotFirst_afterPart', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_libraryDirectiveNotFirst_afterPart);
      });
      _ut.test('test_missingAssignableSelector_identifiersAssigned', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingAssignableSelector_identifiersAssigned);
      });
      _ut.test('test_missingAssignableSelector_primarySelectorPostfix', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingAssignableSelector_primarySelectorPostfix);
      });
      _ut.test('test_missingAssignableSelector_selector', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingAssignableSelector_selector);
      });
      _ut.test('test_missingAssignableSelector_superPrimaryExpression', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingAssignableSelector_superPrimaryExpression);
      });
      _ut.test('test_missingAssignableSelector_superPropertyAccessAssigned', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingAssignableSelector_superPropertyAccessAssigned);
      });
      _ut.test('test_missingCatchOrFinally', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingCatchOrFinally);
      });
      _ut.test('test_missingClassBody', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingClassBody);
      });
      _ut.test('test_missingConstFinalVarOrType', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingConstFinalVarOrType);
      });
      _ut.test('test_missingFunctionBody_emptyNotAllowed', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingFunctionBody_emptyNotAllowed);
      });
      _ut.test('test_missingFunctionBody_invalid', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingFunctionBody_invalid);
      });
      _ut.test('test_missingFunctionParameters_local_void_block', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingFunctionParameters_local_void_block);
      });
      _ut.test('test_missingFunctionParameters_local_void_expression', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingFunctionParameters_local_void_expression);
      });
      _ut.test('test_missingFunctionParameters_topLevel_nonVoid_block', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingFunctionParameters_topLevel_nonVoid_block);
      });
      _ut.test('test_missingFunctionParameters_topLevel_nonVoid_expression', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingFunctionParameters_topLevel_nonVoid_expression);
      });
      _ut.test('test_missingFunctionParameters_topLevel_void_block', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingFunctionParameters_topLevel_void_block);
      });
      _ut.test('test_missingFunctionParameters_topLevel_void_expression', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingFunctionParameters_topLevel_void_expression);
      });
      _ut.test('test_missingIdentifier_functionDeclaration_returnTypeWithoutName', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingIdentifier_functionDeclaration_returnTypeWithoutName);
      });
      _ut.test('test_missingIdentifier_number', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingIdentifier_number);
      });
      _ut.test('test_missingKeywordOperator', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingKeywordOperator);
      });
      _ut.test('test_missingNameInLibraryDirective', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingNameInLibraryDirective);
      });
      _ut.test('test_missingNameInPartOfDirective', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingNameInPartOfDirective);
      });
      _ut.test('test_missingTerminatorForParameterGroup_named', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingTerminatorForParameterGroup_named);
      });
      _ut.test('test_missingTerminatorForParameterGroup_optional', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingTerminatorForParameterGroup_optional);
      });
      _ut.test('test_missingTypedefParameters_nonVoid', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingTypedefParameters_nonVoid);
      });
      _ut.test('test_missingTypedefParameters_typeParameters', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingTypedefParameters_typeParameters);
      });
      _ut.test('test_missingTypedefParameters_void', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingTypedefParameters_void);
      });
      _ut.test('test_missingVariableInForEach', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_missingVariableInForEach);
      });
      _ut.test('test_mixedParameterGroups_namedPositional', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_mixedParameterGroups_namedPositional);
      });
      _ut.test('test_mixedParameterGroups_positionalNamed', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_mixedParameterGroups_positionalNamed);
      });
      _ut.test('test_multipleLibraryDirectives', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_multipleLibraryDirectives);
      });
      _ut.test('test_multipleNamedParameterGroups', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_multipleNamedParameterGroups);
      });
      _ut.test('test_multiplePartOfDirectives', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_multiplePartOfDirectives);
      });
      _ut.test('test_multiplePositionalParameterGroups', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_multiplePositionalParameterGroups);
      });
      _ut.test('test_multipleVariablesInForEach', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_multipleVariablesInForEach);
      });
      _ut.test('test_namedParameterOutsideGroup', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_namedParameterOutsideGroup);
      });
      _ut.test('test_nonConstructorFactory_field', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_nonConstructorFactory_field);
      });
      _ut.test('test_nonConstructorFactory_method', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_nonConstructorFactory_method);
      });
      _ut.test('test_nonIdentifierLibraryName_library', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_nonIdentifierLibraryName_library);
      });
      _ut.test('test_nonIdentifierLibraryName_partOf', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_nonIdentifierLibraryName_partOf);
      });
      _ut.test('test_nonPartOfDirectiveInPart_after', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_nonPartOfDirectiveInPart_after);
      });
      _ut.test('test_nonPartOfDirectiveInPart_before', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_nonPartOfDirectiveInPart_before);
      });
      _ut.test('test_nonUserDefinableOperator', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_nonUserDefinableOperator);
      });
      _ut.test('test_positionalAfterNamedArgument', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_positionalAfterNamedArgument);
      });
      _ut.test('test_positionalParameterOutsideGroup', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_positionalParameterOutsideGroup);
      });
      _ut.test('test_staticAfterConst', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_staticAfterConst);
      });
      _ut.test('test_staticAfterFinal', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_staticAfterFinal);
      });
      _ut.test('test_staticAfterVar', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_staticAfterVar);
      });
      _ut.test('test_staticConstructor', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_staticConstructor);
      });
      _ut.test('test_staticOperator_noReturnType', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_staticOperator_noReturnType);
      });
      _ut.test('test_staticOperator_returnType', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_staticOperator_returnType);
      });
      _ut.test('test_staticTopLevelDeclaration_class', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_staticTopLevelDeclaration_class);
      });
      _ut.test('test_staticTopLevelDeclaration_typedef', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_staticTopLevelDeclaration_typedef);
      });
      _ut.test('test_staticTopLevelDeclaration_variable', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_staticTopLevelDeclaration_variable);
      });
      _ut.test('test_topLevelOperator_withType', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_topLevelOperator_withType);
      });
      _ut.test('test_topLevelOperator_withVoid', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_topLevelOperator_withVoid);
      });
      _ut.test('test_topLevelOperator_withoutType', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_topLevelOperator_withoutType);
      });
      _ut.test('test_unexpectedTerminatorForParameterGroup_named', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_unexpectedTerminatorForParameterGroup_named);
      });
      _ut.test('test_unexpectedTerminatorForParameterGroup_optional', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_unexpectedTerminatorForParameterGroup_optional);
      });
      _ut.test('test_unexpectedToken_semicolonBetweenClassMembers', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_unexpectedToken_semicolonBetweenClassMembers);
      });
      _ut.test('test_unexpectedToken_semicolonBetweenCompilationUnitMembers', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_unexpectedToken_semicolonBetweenCompilationUnitMembers);
      });
      _ut.test('test_useOfUnaryPlusOperator', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_useOfUnaryPlusOperator);
      });
      _ut.test('test_varClass', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_varClass);
      });
      _ut.test('test_varConstructor', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_varConstructor);
      });
      _ut.test('test_varReturnType', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_varReturnType);
      });
      _ut.test('test_varTypedef', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_varTypedef);
      });
      _ut.test('test_voidField_initializer', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_voidField_initializer);
      });
      _ut.test('test_voidField_noInitializer', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_voidField_noInitializer);
      });
      _ut.test('test_voidParameter', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_voidParameter);
      });
      _ut.test('test_withBeforeExtends', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_withBeforeExtends);
      });
      _ut.test('test_withWithoutExtends', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_withWithoutExtends);
      });
      _ut.test('test_wrongSeparatorForNamedParameter', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_wrongSeparatorForNamedParameter);
      });
      _ut.test('test_wrongSeparatorForPositionalParameter', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_wrongSeparatorForPositionalParameter);
      });
      _ut.test('test_wrongTerminatorForParameterGroup_named', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_wrongTerminatorForParameterGroup_named);
      });
      _ut.test('test_wrongTerminatorForParameterGroup_optional', () {
        final __test = new ErrorParserTest();
        runJUnitTest(__test, __test.test_wrongTerminatorForParameterGroup_optional);
      });
    });
  }
}
main() {
  ComplexParserTest.dartSuite();
  ErrorParserTest.dartSuite();
  RecoveryParserTest.dartSuite();
  SimpleParserTest.dartSuite();
}
Map<String, MethodTrampoline> _methodTable_Parser = <String, MethodTrampoline> {
  'parseCompilationUnit_1': new MethodTrampoline(1, (Parser target, arg0) => target.parseCompilationUnit(arg0)),
  'parseExpression_1': new MethodTrampoline(1, (Parser target, arg0) => target.parseExpression(arg0)),
  'parseStatement_1': new MethodTrampoline(1, (Parser target, arg0) => target.parseStatement(arg0)),
  'parseStatements_1': new MethodTrampoline(1, (Parser target, arg0) => target.parseStatements(arg0)),
  'advance_0': new MethodTrampoline(0, (Parser target) => target.advance()),
  'appendScalarValue_5': new MethodTrampoline(5, (Parser target, arg0, arg1, arg2, arg3, arg4) => target.appendScalarValue(arg0, arg1, arg2, arg3, arg4)),
  'computeStringValue_1': new MethodTrampoline(1, (Parser target, arg0) => target.computeStringValue(arg0)),
  'createSyntheticIdentifier_0': new MethodTrampoline(0, (Parser target) => target.createSyntheticIdentifier()),
  'createSyntheticStringLiteral_0': new MethodTrampoline(0, (Parser target) => target.createSyntheticStringLiteral()),
  'createSyntheticToken_1': new MethodTrampoline(1, (Parser target, arg0) => target.createSyntheticToken(arg0)),
  'ensureAssignable_1': new MethodTrampoline(1, (Parser target, arg0) => target.ensureAssignable(arg0)),
  'expect_1': new MethodTrampoline(1, (Parser target, arg0) => target.expect(arg0)),
  'hasReturnTypeInTypeAlias_0': new MethodTrampoline(0, (Parser target) => target.hasReturnTypeInTypeAlias()),
  'isFunctionDeclaration_0': new MethodTrampoline(0, (Parser target) => target.isFunctionDeclaration()),
  'isFunctionExpression_1': new MethodTrampoline(1, (Parser target, arg0) => target.isFunctionExpression(arg0)),
  'isHexDigit_1': new MethodTrampoline(1, (Parser target, arg0) => target.isHexDigit(arg0)),
  'isInitializedVariableDeclaration_0': new MethodTrampoline(0, (Parser target) => target.isInitializedVariableDeclaration()),
  'isOperator_1': new MethodTrampoline(1, (Parser target, arg0) => target.isOperator(arg0)),
  'isSwitchMember_0': new MethodTrampoline(0, (Parser target) => target.isSwitchMember()),
  'lexicallyFirst_1': new MethodTrampoline(1, (Parser target, arg0) => target.lexicallyFirst(arg0)),
  'matches_1': new MethodTrampoline(1, (Parser target, arg0) => target.matches(arg0)),
  'matches_2': new MethodTrampoline(2, (Parser target, arg0, arg1) => target.matches3(arg0, arg1)),
  'matchesAny_2': new MethodTrampoline(2, (Parser target, arg0, arg1) => target.matchesAny(arg0, arg1)),
  'matchesIdentifier_0': new MethodTrampoline(0, (Parser target) => target.matchesIdentifier()),
  'matchesIdentifier_1': new MethodTrampoline(1, (Parser target, arg0) => target.matchesIdentifier2(arg0)),
  'optional_1': new MethodTrampoline(1, (Parser target, arg0) => target.optional(arg0)),
  'parseAdditiveExpression_0': new MethodTrampoline(0, (Parser target) => target.parseAdditiveExpression()),
  'parseAnnotation_0': new MethodTrampoline(0, (Parser target) => target.parseAnnotation()),
  'parseArgument_0': new MethodTrampoline(0, (Parser target) => target.parseArgument()),
  'parseArgumentDefinitionTest_0': new MethodTrampoline(0, (Parser target) => target.parseArgumentDefinitionTest()),
  'parseArgumentList_0': new MethodTrampoline(0, (Parser target) => target.parseArgumentList()),
  'parseAssertStatement_0': new MethodTrampoline(0, (Parser target) => target.parseAssertStatement()),
  'parseAssignableExpression_1': new MethodTrampoline(1, (Parser target, arg0) => target.parseAssignableExpression(arg0)),
  'parseAssignableSelector_2': new MethodTrampoline(2, (Parser target, arg0, arg1) => target.parseAssignableSelector(arg0, arg1)),
  'parseBitwiseAndExpression_0': new MethodTrampoline(0, (Parser target) => target.parseBitwiseAndExpression()),
  'parseBitwiseOrExpression_0': new MethodTrampoline(0, (Parser target) => target.parseBitwiseOrExpression()),
  'parseBitwiseXorExpression_0': new MethodTrampoline(0, (Parser target) => target.parseBitwiseXorExpression()),
  'parseBlock_0': new MethodTrampoline(0, (Parser target) => target.parseBlock()),
  'parseBreakStatement_0': new MethodTrampoline(0, (Parser target) => target.parseBreakStatement()),
  'parseCascadeSection_0': new MethodTrampoline(0, (Parser target) => target.parseCascadeSection()),
  'parseClassDeclaration_2': new MethodTrampoline(2, (Parser target, arg0, arg1) => target.parseClassDeclaration(arg0, arg1)),
  'parseClassMember_1': new MethodTrampoline(1, (Parser target, arg0) => target.parseClassMember(arg0)),
  'parseClassMembers_2': new MethodTrampoline(2, (Parser target, arg0, arg1) => target.parseClassMembers(arg0, arg1)),
  'parseClassTypeAlias_2': new MethodTrampoline(2, (Parser target, arg0, arg1) => target.parseClassTypeAlias(arg0, arg1)),
  'parseCombinators_0': new MethodTrampoline(0, (Parser target) => target.parseCombinators()),
  'parseCommentAndMetadata_0': new MethodTrampoline(0, (Parser target) => target.parseCommentAndMetadata()),
  'parseCommentReference_2': new MethodTrampoline(2, (Parser target, arg0, arg1) => target.parseCommentReference(arg0, arg1)),
  'parseCommentReferences_1': new MethodTrampoline(1, (Parser target, arg0) => target.parseCommentReferences(arg0)),
  'parseCompilationUnit_0': new MethodTrampoline(0, (Parser target) => target.parseCompilationUnit2()),
  'parseCompilationUnitMember_1': new MethodTrampoline(1, (Parser target, arg0) => target.parseCompilationUnitMember(arg0)),
  'parseConditionalExpression_0': new MethodTrampoline(0, (Parser target) => target.parseConditionalExpression()),
  'parseConstExpression_0': new MethodTrampoline(0, (Parser target) => target.parseConstExpression()),
  'parseConstructor_8': new MethodTrampoline(8, (Parser target, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7) => target.parseConstructor(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7)),
  'parseConstructorFieldInitializer_0': new MethodTrampoline(0, (Parser target) => target.parseConstructorFieldInitializer()),
  'parseConstructorName_0': new MethodTrampoline(0, (Parser target) => target.parseConstructorName()),
  'parseContinueStatement_0': new MethodTrampoline(0, (Parser target) => target.parseContinueStatement()),
  'parseDirective_1': new MethodTrampoline(1, (Parser target, arg0) => target.parseDirective(arg0)),
  'parseDocumentationComment_0': new MethodTrampoline(0, (Parser target) => target.parseDocumentationComment()),
  'parseDoStatement_0': new MethodTrampoline(0, (Parser target) => target.parseDoStatement()),
  'parseEmptyStatement_0': new MethodTrampoline(0, (Parser target) => target.parseEmptyStatement()),
  'parseEqualityExpression_0': new MethodTrampoline(0, (Parser target) => target.parseEqualityExpression()),
  'parseExportDirective_1': new MethodTrampoline(1, (Parser target, arg0) => target.parseExportDirective(arg0)),
  'parseExpression_0': new MethodTrampoline(0, (Parser target) => target.parseExpression2()),
  'parseExpressionList_0': new MethodTrampoline(0, (Parser target) => target.parseExpressionList()),
  'parseExpressionWithoutCascade_0': new MethodTrampoline(0, (Parser target) => target.parseExpressionWithoutCascade()),
  'parseExtendsClause_0': new MethodTrampoline(0, (Parser target) => target.parseExtendsClause()),
  'parseFinalConstVarOrType_1': new MethodTrampoline(1, (Parser target, arg0) => target.parseFinalConstVarOrType(arg0)),
  'parseFormalParameter_1': new MethodTrampoline(1, (Parser target, arg0) => target.parseFormalParameter(arg0)),
  'parseFormalParameterList_0': new MethodTrampoline(0, (Parser target) => target.parseFormalParameterList()),
  'parseForStatement_0': new MethodTrampoline(0, (Parser target) => target.parseForStatement()),
  'parseFunctionBody_2': new MethodTrampoline(2, (Parser target, arg0, arg1) => target.parseFunctionBody(arg0, arg1)),
  'parseFunctionDeclaration_3': new MethodTrampoline(3, (Parser target, arg0, arg1, arg2) => target.parseFunctionDeclaration(arg0, arg1, arg2)),
  'parseFunctionDeclarationStatement_0': new MethodTrampoline(0, (Parser target) => target.parseFunctionDeclarationStatement()),
  'parseFunctionDeclarationStatement_2': new MethodTrampoline(2, (Parser target, arg0, arg1) => target.parseFunctionDeclarationStatement2(arg0, arg1)),
  'parseFunctionExpression_0': new MethodTrampoline(0, (Parser target) => target.parseFunctionExpression()),
  'parseFunctionTypeAlias_2': new MethodTrampoline(2, (Parser target, arg0, arg1) => target.parseFunctionTypeAlias(arg0, arg1)),
  'parseGetter_4': new MethodTrampoline(4, (Parser target, arg0, arg1, arg2, arg3) => target.parseGetter(arg0, arg1, arg2, arg3)),
  'parseIdentifierList_0': new MethodTrampoline(0, (Parser target) => target.parseIdentifierList()),
  'parseIfStatement_0': new MethodTrampoline(0, (Parser target) => target.parseIfStatement()),
  'parseImplementsClause_0': new MethodTrampoline(0, (Parser target) => target.parseImplementsClause()),
  'parseImportDirective_1': new MethodTrampoline(1, (Parser target, arg0) => target.parseImportDirective(arg0)),
  'parseInitializedIdentifierList_4': new MethodTrampoline(4, (Parser target, arg0, arg1, arg2, arg3) => target.parseInitializedIdentifierList(arg0, arg1, arg2, arg3)),
  'parseInstanceCreationExpression_1': new MethodTrampoline(1, (Parser target, arg0) => target.parseInstanceCreationExpression(arg0)),
  'parseLibraryDirective_1': new MethodTrampoline(1, (Parser target, arg0) => target.parseLibraryDirective(arg0)),
  'parseLibraryIdentifier_0': new MethodTrampoline(0, (Parser target) => target.parseLibraryIdentifier()),
  'parseLibraryName_2': new MethodTrampoline(2, (Parser target, arg0, arg1) => target.parseLibraryName(arg0, arg1)),
  'parseListLiteral_2': new MethodTrampoline(2, (Parser target, arg0, arg1) => target.parseListLiteral(arg0, arg1)),
  'parseListOrMapLiteral_1': new MethodTrampoline(1, (Parser target, arg0) => target.parseListOrMapLiteral(arg0)),
  'parseLogicalAndExpression_0': new MethodTrampoline(0, (Parser target) => target.parseLogicalAndExpression()),
  'parseLogicalOrExpression_0': new MethodTrampoline(0, (Parser target) => target.parseLogicalOrExpression()),
  'parseMapLiteral_2': new MethodTrampoline(2, (Parser target, arg0, arg1) => target.parseMapLiteral(arg0, arg1)),
  'parseMapLiteralEntry_0': new MethodTrampoline(0, (Parser target) => target.parseMapLiteralEntry()),
  'parseMethodDeclaration_4': new MethodTrampoline(4, (Parser target, arg0, arg1, arg2, arg3) => target.parseMethodDeclaration(arg0, arg1, arg2, arg3)),
  'parseMethodDeclaration_6': new MethodTrampoline(6, (Parser target, arg0, arg1, arg2, arg3, arg4, arg5) => target.parseMethodDeclaration2(arg0, arg1, arg2, arg3, arg4, arg5)),
  'parseModifiers_0': new MethodTrampoline(0, (Parser target) => target.parseModifiers()),
  'parseMultiplicativeExpression_0': new MethodTrampoline(0, (Parser target) => target.parseMultiplicativeExpression()),
  'parseNewExpression_0': new MethodTrampoline(0, (Parser target) => target.parseNewExpression()),
  'parseNonLabeledStatement_0': new MethodTrampoline(0, (Parser target) => target.parseNonLabeledStatement()),
  'parseNormalFormalParameter_0': new MethodTrampoline(0, (Parser target) => target.parseNormalFormalParameter()),
  'parseOperator_3': new MethodTrampoline(3, (Parser target, arg0, arg1, arg2) => target.parseOperator(arg0, arg1, arg2)),
  'parseOptionalReturnType_0': new MethodTrampoline(0, (Parser target) => target.parseOptionalReturnType()),
  'parsePartDirective_1': new MethodTrampoline(1, (Parser target, arg0) => target.parsePartDirective(arg0)),
  'parsePostfixExpression_0': new MethodTrampoline(0, (Parser target) => target.parsePostfixExpression()),
  'parsePrefixedIdentifier_0': new MethodTrampoline(0, (Parser target) => target.parsePrefixedIdentifier()),
  'parsePrimaryExpression_0': new MethodTrampoline(0, (Parser target) => target.parsePrimaryExpression()),
  'parseRedirectingConstructorInvocation_0': new MethodTrampoline(0, (Parser target) => target.parseRedirectingConstructorInvocation()),
  'parseRelationalExpression_0': new MethodTrampoline(0, (Parser target) => target.parseRelationalExpression()),
  'parseRethrowExpression_0': new MethodTrampoline(0, (Parser target) => target.parseRethrowExpression()),
  'parseReturnStatement_0': new MethodTrampoline(0, (Parser target) => target.parseReturnStatement()),
  'parseReturnType_0': new MethodTrampoline(0, (Parser target) => target.parseReturnType()),
  'parseSetter_4': new MethodTrampoline(4, (Parser target, arg0, arg1, arg2, arg3) => target.parseSetter(arg0, arg1, arg2, arg3)),
  'parseShiftExpression_0': new MethodTrampoline(0, (Parser target) => target.parseShiftExpression()),
  'parseSimpleIdentifier_0': new MethodTrampoline(0, (Parser target) => target.parseSimpleIdentifier()),
  'parseStatement_0': new MethodTrampoline(0, (Parser target) => target.parseStatement2()),
  'parseStatements_0': new MethodTrampoline(0, (Parser target) => target.parseStatements2()),
  'parseStringInterpolation_1': new MethodTrampoline(1, (Parser target, arg0) => target.parseStringInterpolation(arg0)),
  'parseStringLiteral_0': new MethodTrampoline(0, (Parser target) => target.parseStringLiteral()),
  'parseSuperConstructorInvocation_0': new MethodTrampoline(0, (Parser target) => target.parseSuperConstructorInvocation()),
  'parseSwitchStatement_0': new MethodTrampoline(0, (Parser target) => target.parseSwitchStatement()),
  'parseThrowExpression_0': new MethodTrampoline(0, (Parser target) => target.parseThrowExpression()),
  'parseThrowExpressionWithoutCascade_0': new MethodTrampoline(0, (Parser target) => target.parseThrowExpressionWithoutCascade()),
  'parseTryStatement_0': new MethodTrampoline(0, (Parser target) => target.parseTryStatement()),
  'parseTypeAlias_1': new MethodTrampoline(1, (Parser target, arg0) => target.parseTypeAlias(arg0)),
  'parseTypeArgumentList_0': new MethodTrampoline(0, (Parser target) => target.parseTypeArgumentList()),
  'parseTypeName_0': new MethodTrampoline(0, (Parser target) => target.parseTypeName()),
  'parseTypeParameter_0': new MethodTrampoline(0, (Parser target) => target.parseTypeParameter()),
  'parseTypeParameterList_0': new MethodTrampoline(0, (Parser target) => target.parseTypeParameterList()),
  'parseUnaryExpression_0': new MethodTrampoline(0, (Parser target) => target.parseUnaryExpression()),
  'parseVariableDeclaration_0': new MethodTrampoline(0, (Parser target) => target.parseVariableDeclaration()),
  'parseVariableDeclarationList_1': new MethodTrampoline(1, (Parser target, arg0) => target.parseVariableDeclarationList(arg0)),
  'parseVariableDeclarationList_3': new MethodTrampoline(3, (Parser target, arg0, arg1, arg2) => target.parseVariableDeclarationList2(arg0, arg1, arg2)),
  'parseVariableDeclarationStatement_1': new MethodTrampoline(1, (Parser target, arg0) => target.parseVariableDeclarationStatement(arg0)),
  'parseVariableDeclarationStatement_3': new MethodTrampoline(3, (Parser target, arg0, arg1, arg2) => target.parseVariableDeclarationStatement2(arg0, arg1, arg2)),
  'parseWhileStatement_0': new MethodTrampoline(0, (Parser target) => target.parseWhileStatement()),
  'parseWithClause_0': new MethodTrampoline(0, (Parser target) => target.parseWithClause()),
  'peek_0': new MethodTrampoline(0, (Parser target) => target.peek()),
  'peek_1': new MethodTrampoline(1, (Parser target, arg0) => target.peek2(arg0)),
  'reportError_3': new MethodTrampoline(3, (Parser target, arg0, arg1, arg2) => target.reportError(arg0, arg1, arg2)),
  'reportError_2': new MethodTrampoline(2, (Parser target, arg0, arg1) => target.reportError4(arg0, arg1)),
  'skipFinalConstVarOrType_1': new MethodTrampoline(1, (Parser target, arg0) => target.skipFinalConstVarOrType(arg0)),
  'skipFormalParameterList_1': new MethodTrampoline(1, (Parser target, arg0) => target.skipFormalParameterList(arg0)),
  'skipPastMatchingToken_1': new MethodTrampoline(1, (Parser target, arg0) => target.skipPastMatchingToken(arg0)),
  'skipPrefixedIdentifier_1': new MethodTrampoline(1, (Parser target, arg0) => target.skipPrefixedIdentifier(arg0)),
  'skipReturnType_1': new MethodTrampoline(1, (Parser target, arg0) => target.skipReturnType(arg0)),
  'skipSimpleIdentifier_1': new MethodTrampoline(1, (Parser target, arg0) => target.skipSimpleIdentifier(arg0)),
  'skipStringInterpolation_1': new MethodTrampoline(1, (Parser target, arg0) => target.skipStringInterpolation(arg0)),
  'skipStringLiteral_1': new MethodTrampoline(1, (Parser target, arg0) => target.skipStringLiteral(arg0)),
  'skipTypeArgumentList_1': new MethodTrampoline(1, (Parser target, arg0) => target.skipTypeArgumentList(arg0)),
  'skipTypeName_1': new MethodTrampoline(1, (Parser target, arg0) => target.skipTypeName(arg0)),
  'skipTypeParameterList_1': new MethodTrampoline(1, (Parser target, arg0) => target.skipTypeParameterList(arg0)),
  'translateCharacter_3': new MethodTrampoline(3, (Parser target, arg0, arg1, arg2) => target.translateCharacter(arg0, arg1, arg2)),
  'validateFormalParameterList_1': new MethodTrampoline(1, (Parser target, arg0) => target.validateFormalParameterList(arg0)),
  'validateModifiersForClass_1': new MethodTrampoline(1, (Parser target, arg0) => target.validateModifiersForClass(arg0)),
  'validateModifiersForConstructor_1': new MethodTrampoline(1, (Parser target, arg0) => target.validateModifiersForConstructor(arg0)),
  'validateModifiersForField_1': new MethodTrampoline(1, (Parser target, arg0) => target.validateModifiersForField(arg0)),
  'validateModifiersForGetterOrSetterOrMethod_1': new MethodTrampoline(1, (Parser target, arg0) => target.validateModifiersForGetterOrSetterOrMethod(arg0)),
  'validateModifiersForOperator_1': new MethodTrampoline(1, (Parser target, arg0) => target.validateModifiersForOperator(arg0)),
  'validateModifiersForTopLevelDeclaration_1': new MethodTrampoline(1, (Parser target, arg0) => target.validateModifiersForTopLevelDeclaration(arg0)),
  'validateModifiersForTopLevelFunction_1': new MethodTrampoline(1, (Parser target, arg0) => target.validateModifiersForTopLevelFunction(arg0)),
  'validateModifiersForTopLevelVariable_1': new MethodTrampoline(1, (Parser target, arg0) => target.validateModifiersForTopLevelVariable(arg0)),
  'validateModifiersForTypedef_1': new MethodTrampoline(1, (Parser target, arg0) => target.validateModifiersForTypedef(arg0)),};


Object invokeParserMethodImpl(Parser parser, String methodName, List<Object> objects, Token tokenStream) {
  parser.currentToken = tokenStream;
  MethodTrampoline method = _methodTable_Parser['${methodName}_${objects.length}'];
  return method.invoke(parser, objects);
}
