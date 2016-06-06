// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.dart.ast.utilities_test;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/java_engine.dart' show Predicate;
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:unittest/unittest.dart';

import '../../../generated/parser_test.dart' show ParserTestCase;
import '../../../generated/test_support.dart';
import '../../../reflective_tests.dart';
import '../../../utils.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(ConstantEvaluatorTest);
  runReflectiveTests(NodeLocatorTest);
  runReflectiveTests(NodeLocator2Test);
  runReflectiveTests(ResolutionCopierTest);
  runReflectiveTests(ToSourceVisitorTest);
}

@reflectiveTest
class ConstantEvaluatorTest extends ParserTestCase {
  void fail_constructor() {
    Object value = _getConstantValue("?");
    expect(value, null);
  }

  void fail_identifier_class() {
    Object value = _getConstantValue("?");
    expect(value, null);
  }

  void fail_identifier_function() {
    Object value = _getConstantValue("?");
    expect(value, null);
  }

  void fail_identifier_static() {
    Object value = _getConstantValue("?");
    expect(value, null);
  }

  void fail_identifier_staticMethod() {
    Object value = _getConstantValue("?");
    expect(value, null);
  }

  void fail_identifier_topLevel() {
    Object value = _getConstantValue("?");
    expect(value, null);
  }

  void fail_identifier_typeParameter() {
    Object value = _getConstantValue("?");
    expect(value, null);
  }

  void test_binary_bitAnd() {
    Object value = _getConstantValue("74 & 42");
    EngineTestCase.assertInstanceOf((obj) => obj is int, int, value);
    expect(value as int, 74 & 42);
  }

  void test_binary_bitOr() {
    Object value = _getConstantValue("74 | 42");
    EngineTestCase.assertInstanceOf((obj) => obj is int, int, value);
    expect(value as int, 74 | 42);
  }

  void test_binary_bitXor() {
    Object value = _getConstantValue("74 ^ 42");
    EngineTestCase.assertInstanceOf((obj) => obj is int, int, value);
    expect(value as int, 74 ^ 42);
  }

  void test_binary_divide_double() {
    Object value = _getConstantValue("3.2 / 2.3");
    expect(value, 3.2 / 2.3);
  }

  void test_binary_divide_integer() {
    Object value = _getConstantValue("3 / 2");
    expect(value, 1.5);
  }

  void test_binary_equal_boolean() {
    Object value = _getConstantValue("true == false");
    expect(value, false);
  }

  void test_binary_equal_integer() {
    Object value = _getConstantValue("2 == 3");
    expect(value, false);
  }

  void test_binary_equal_invalidLeft() {
    Object value = _getConstantValue("a == 3");
    expect(value, ConstantEvaluator.NOT_A_CONSTANT);
  }

  void test_binary_equal_invalidRight() {
    Object value = _getConstantValue("2 == a");
    expect(value, ConstantEvaluator.NOT_A_CONSTANT);
  }

  void test_binary_equal_string() {
    Object value = _getConstantValue("'a' == 'b'");
    expect(value, false);
  }

  void test_binary_greaterThan() {
    Object value = _getConstantValue("2 > 3");
    expect(value, false);
  }

  void test_binary_greaterThanOrEqual() {
    Object value = _getConstantValue("2 >= 3");
    expect(value, false);
  }

  void test_binary_leftShift() {
    Object value = _getConstantValue("16 << 2");
    EngineTestCase.assertInstanceOf((obj) => obj is int, int, value);
    expect(value as int, 64);
  }

  void test_binary_lessThan() {
    Object value = _getConstantValue("2 < 3");
    expect(value, true);
  }

  void test_binary_lessThanOrEqual() {
    Object value = _getConstantValue("2 <= 3");
    expect(value, true);
  }

  void test_binary_logicalAnd() {
    Object value = _getConstantValue("true && false");
    expect(value, false);
  }

  void test_binary_logicalOr() {
    Object value = _getConstantValue("true || false");
    expect(value, true);
  }

  void test_binary_minus_double() {
    Object value = _getConstantValue("3.2 - 2.3");
    expect(value, 3.2 - 2.3);
  }

  void test_binary_minus_integer() {
    Object value = _getConstantValue("3 - 2");
    expect(value, 1);
  }

  void test_binary_notEqual_boolean() {
    Object value = _getConstantValue("true != false");
    expect(value, true);
  }

  void test_binary_notEqual_integer() {
    Object value = _getConstantValue("2 != 3");
    expect(value, true);
  }

  void test_binary_notEqual_invalidLeft() {
    Object value = _getConstantValue("a != 3");
    expect(value, ConstantEvaluator.NOT_A_CONSTANT);
  }

  void test_binary_notEqual_invalidRight() {
    Object value = _getConstantValue("2 != a");
    expect(value, ConstantEvaluator.NOT_A_CONSTANT);
  }

  void test_binary_notEqual_string() {
    Object value = _getConstantValue("'a' != 'b'");
    expect(value, true);
  }

  void test_binary_plus_double() {
    Object value = _getConstantValue("2.3 + 3.2");
    expect(value, 2.3 + 3.2);
  }

  void test_binary_plus_integer() {
    Object value = _getConstantValue("2 + 3");
    expect(value, 5);
  }

  void test_binary_remainder_double() {
    Object value = _getConstantValue("3.2 % 2.3");
    expect(value, 3.2 % 2.3);
  }

  void test_binary_remainder_integer() {
    Object value = _getConstantValue("8 % 3");
    expect(value, 2);
  }

  void test_binary_rightShift() {
    Object value = _getConstantValue("64 >> 2");
    EngineTestCase.assertInstanceOf((obj) => obj is int, int, value);
    expect(value as int, 16);
  }

  void test_binary_times_double() {
    Object value = _getConstantValue("2.3 * 3.2");
    expect(value, 2.3 * 3.2);
  }

  void test_binary_times_integer() {
    Object value = _getConstantValue("2 * 3");
    expect(value, 6);
  }

  void test_binary_truncatingDivide_double() {
    Object value = _getConstantValue("3.2 ~/ 2.3");
    EngineTestCase.assertInstanceOf((obj) => obj is int, int, value);
    expect(value as int, 1);
  }

  void test_binary_truncatingDivide_integer() {
    Object value = _getConstantValue("10 ~/ 3");
    EngineTestCase.assertInstanceOf((obj) => obj is int, int, value);
    expect(value as int, 3);
  }

  void test_literal_boolean_false() {
    Object value = _getConstantValue("false");
    expect(value, false);
  }

  void test_literal_boolean_true() {
    Object value = _getConstantValue("true");
    expect(value, true);
  }

  void test_literal_list() {
    Object value = _getConstantValue("['a', 'b', 'c']");
    EngineTestCase.assertInstanceOf((obj) => obj is List, List, value);
    List list = value as List;
    expect(list.length, 3);
    expect(list[0], "a");
    expect(list[1], "b");
    expect(list[2], "c");
  }

  void test_literal_map() {
    Object value = _getConstantValue("{'a' : 'm', 'b' : 'n', 'c' : 'o'}");
    EngineTestCase.assertInstanceOf((obj) => obj is Map, Map, value);
    Map map = value as Map;
    expect(map.length, 3);
    expect(map["a"], "m");
    expect(map["b"], "n");
    expect(map["c"], "o");
  }

  void test_literal_null() {
    Object value = _getConstantValue("null");
    expect(value, null);
  }

  void test_literal_number_double() {
    Object value = _getConstantValue("3.45");
    expect(value, 3.45);
  }

  void test_literal_number_integer() {
    Object value = _getConstantValue("42");
    expect(value, 42);
  }

  void test_literal_string_adjacent() {
    Object value = _getConstantValue("'abc' 'def'");
    expect(value, "abcdef");
  }

  void test_literal_string_interpolation_invalid() {
    Object value = _getConstantValue("'a\${f()}c'");
    expect(value, ConstantEvaluator.NOT_A_CONSTANT);
  }

  void test_literal_string_interpolation_valid() {
    Object value = _getConstantValue("'a\${3}c'");
    expect(value, "a3c");
  }

  void test_literal_string_simple() {
    Object value = _getConstantValue("'abc'");
    expect(value, "abc");
  }

  void test_parenthesizedExpression() {
    Object value = _getConstantValue("('a')");
    expect(value, "a");
  }

  void test_unary_bitNot() {
    Object value = _getConstantValue("~42");
    EngineTestCase.assertInstanceOf((obj) => obj is int, int, value);
    expect(value as int, ~42);
  }

  void test_unary_logicalNot() {
    Object value = _getConstantValue("!true");
    expect(value, false);
  }

  void test_unary_negated_double() {
    Object value = _getConstantValue("-42.3");
    expect(value, -42.3);
  }

  void test_unary_negated_integer() {
    Object value = _getConstantValue("-42");
    expect(value, -42);
  }

  Object _getConstantValue(String source) =>
      parseExpression(source).accept(new ConstantEvaluator());
}

@reflectiveTest
class NodeLocator2Test extends ParserTestCase {
  void test_onlyStartOffset() {
    String code = ' int vv; ';
    //             012345678
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(code);
    TopLevelVariableDeclaration declaration = unit.declarations[0];
    VariableDeclarationList variableList = declaration.variables;
    Identifier typeName = variableList.type.name;
    SimpleIdentifier varName = variableList.variables[0].name;
    expect(new NodeLocator2(0).searchWithin(unit), same(unit));
    expect(new NodeLocator2(1).searchWithin(unit), same(typeName));
    expect(new NodeLocator2(2).searchWithin(unit), same(typeName));
    expect(new NodeLocator2(3).searchWithin(unit), same(typeName));
    expect(new NodeLocator2(4).searchWithin(unit), same(variableList));
    expect(new NodeLocator2(5).searchWithin(unit), same(varName));
    expect(new NodeLocator2(6).searchWithin(unit), same(varName));
    expect(new NodeLocator2(7).searchWithin(unit), same(declaration));
    expect(new NodeLocator2(8).searchWithin(unit), same(unit));
    expect(new NodeLocator2(9).searchWithin(unit), isNull);
    expect(new NodeLocator2(100).searchWithin(unit), isNull);
  }

  void test_startEndOffset() {
    String code = ' int vv; ';
    //             012345678
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(code);
    TopLevelVariableDeclaration declaration = unit.declarations[0];
    VariableDeclarationList variableList = declaration.variables;
    Identifier typeName = variableList.type.name;
    SimpleIdentifier varName = variableList.variables[0].name;
    expect(new NodeLocator2(-1, 2).searchWithin(unit), isNull);
    expect(new NodeLocator2(0, 2).searchWithin(unit), same(unit));
    expect(new NodeLocator2(1, 2).searchWithin(unit), same(typeName));
    expect(new NodeLocator2(1, 3).searchWithin(unit), same(typeName));
    expect(new NodeLocator2(1, 4).searchWithin(unit), same(variableList));
    expect(new NodeLocator2(5, 6).searchWithin(unit), same(varName));
    expect(new NodeLocator2(5, 7).searchWithin(unit), same(declaration));
    expect(new NodeLocator2(5, 8).searchWithin(unit), same(unit));
    expect(new NodeLocator2(5, 100).searchWithin(unit), isNull);
    expect(new NodeLocator2(100, 200).searchWithin(unit), isNull);
  }
}

@reflectiveTest
class NodeLocatorTest extends ParserTestCase {
  void test_range() {
    CompilationUnit unit =
        ParserTestCase.parseCompilationUnit("library myLib;");
    _assertLocate(
        unit, 4, 10, (node) => node is LibraryDirective, LibraryDirective);
  }

  void test_searchWithin_null() {
    NodeLocator locator = new NodeLocator(0, 0);
    expect(locator.searchWithin(null), isNull);
  }

  void test_searchWithin_offset() {
    CompilationUnit unit =
        ParserTestCase.parseCompilationUnit("library myLib;");
    _assertLocate(
        unit, 10, 10, (node) => node is SimpleIdentifier, SimpleIdentifier);
  }

  void test_searchWithin_offsetAfterNode() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(r'''
class A {}
class B {}''');
    NodeLocator locator = new NodeLocator(1024, 1024);
    AstNode node = locator.searchWithin(unit.declarations[0]);
    expect(node, isNull);
  }

  void test_searchWithin_offsetBeforeNode() {
    CompilationUnit unit = ParserTestCase.parseCompilationUnit(r'''
class A {}
class B {}''');
    NodeLocator locator = new NodeLocator(0, 0);
    AstNode node = locator.searchWithin(unit.declarations[1]);
    expect(node, isNull);
  }

  void _assertLocate(CompilationUnit unit, int start, int end,
      Predicate<Object> predicate, Type expectedClass) {
    NodeLocator locator = new NodeLocator(start, end);
    AstNode node = locator.searchWithin(unit);
    expect(node, isNotNull);
    expect(locator.foundNode, same(node));
    expect(node.offset <= start, isTrue, reason: "Node starts after range");
    expect(node.offset + node.length > end, isTrue,
        reason: "Node ends before range");
    EngineTestCase.assertInstanceOf(predicate, expectedClass, node);
  }
}

@reflectiveTest
class ResolutionCopierTest extends EngineTestCase {
  void test_visitAdjacentStrings() {
    AdjacentStrings createNode() => new AdjacentStrings([
          new SimpleStringLiteral(null, 'hello'),
          new SimpleStringLiteral(null, 'world')
        ]);

    AdjacentStrings fromNode = createNode();
    DartType propagatedType = ElementFactory.classElement2("A").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("B").type;
    fromNode.staticType = staticType;

    AdjacentStrings toNode = createNode();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitAnnotation() {
    String annotationName = "proxy";
    Annotation fromNode =
        AstFactory.annotation(AstFactory.identifier3(annotationName));
    Element element = ElementFactory.topLevelVariableElement2(annotationName);
    fromNode.element = element;
    Annotation toNode =
        AstFactory.annotation(AstFactory.identifier3(annotationName));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.element, same(element));
  }

  void test_visitAsExpression() {
    AsExpression fromNode = AstFactory.asExpression(
        AstFactory.identifier3("x"), AstFactory.typeName4("A"));
    DartType propagatedType = ElementFactory.classElement2("A").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("B").type;
    fromNode.staticType = staticType;
    AsExpression toNode = AstFactory.asExpression(
        AstFactory.identifier3("x"), AstFactory.typeName4("A"));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitAssignmentExpression() {
    AssignmentExpression fromNode = AstFactory.assignmentExpression(
        AstFactory.identifier3("a"),
        TokenType.PLUS_EQ,
        AstFactory.identifier3("b"));
    DartType propagatedType = ElementFactory.classElement2("C").type;
    MethodElement propagatedElement =
        ElementFactory.methodElement("+", propagatedType);
    fromNode.propagatedElement = propagatedElement;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    MethodElement staticElement = ElementFactory.methodElement("+", staticType);
    fromNode.staticElement = staticElement;
    fromNode.staticType = staticType;
    AssignmentExpression toNode = AstFactory.assignmentExpression(
        AstFactory.identifier3("a"),
        TokenType.PLUS_EQ,
        AstFactory.identifier3("b"));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedElement, same(propagatedElement));
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticElement, same(staticElement));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitBinaryExpression() {
    BinaryExpression fromNode = AstFactory.binaryExpression(
        AstFactory.identifier3("a"),
        TokenType.PLUS,
        AstFactory.identifier3("b"));
    DartType propagatedType = ElementFactory.classElement2("C").type;
    MethodElement propagatedElement =
        ElementFactory.methodElement("+", propagatedType);
    fromNode.propagatedElement = propagatedElement;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    MethodElement staticElement = ElementFactory.methodElement("+", staticType);
    fromNode.staticElement = staticElement;
    fromNode.staticType = staticType;
    BinaryExpression toNode = AstFactory.binaryExpression(
        AstFactory.identifier3("a"),
        TokenType.PLUS,
        AstFactory.identifier3("b"));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedElement, same(propagatedElement));
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticElement, same(staticElement));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitBooleanLiteral() {
    BooleanLiteral fromNode = AstFactory.booleanLiteral(true);
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    BooleanLiteral toNode = AstFactory.booleanLiteral(true);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitCascadeExpression() {
    CascadeExpression fromNode = AstFactory.cascadeExpression(
        AstFactory.identifier3("a"), [AstFactory.identifier3("b")]);
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    CascadeExpression toNode = AstFactory.cascadeExpression(
        AstFactory.identifier3("a"), [AstFactory.identifier3("b")]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitCompilationUnit() {
    CompilationUnit fromNode = AstFactory.compilationUnit();
    CompilationUnitElement element =
        new CompilationUnitElementImpl("test.dart");
    fromNode.element = element;
    CompilationUnit toNode = AstFactory.compilationUnit();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.element, same(element));
  }

  void test_visitConditionalExpression() {
    ConditionalExpression fromNode = AstFactory.conditionalExpression(
        AstFactory.identifier3("c"),
        AstFactory.identifier3("a"),
        AstFactory.identifier3("b"));
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    ConditionalExpression toNode = AstFactory.conditionalExpression(
        AstFactory.identifier3("c"),
        AstFactory.identifier3("a"),
        AstFactory.identifier3("b"));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitConstructorDeclaration() {
    String className = "A";
    String constructorName = "c";
    ConstructorDeclaration fromNode = AstFactory.constructorDeclaration(
        AstFactory.identifier3(className),
        constructorName,
        AstFactory.formalParameterList(),
        null);
    ConstructorElement element = ElementFactory.constructorElement2(
        ElementFactory.classElement2(className), constructorName);
    fromNode.element = element;
    ConstructorDeclaration toNode = AstFactory.constructorDeclaration(
        AstFactory.identifier3(className),
        constructorName,
        AstFactory.formalParameterList(),
        null);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.element, same(element));
  }

  void test_visitConstructorName() {
    ConstructorName fromNode =
        AstFactory.constructorName(AstFactory.typeName4("A"), "c");
    ConstructorElement staticElement = ElementFactory.constructorElement2(
        ElementFactory.classElement2("A"), "c");
    fromNode.staticElement = staticElement;
    ConstructorName toNode =
        AstFactory.constructorName(AstFactory.typeName4("A"), "c");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticElement, same(staticElement));
  }

  void test_visitDoubleLiteral() {
    DoubleLiteral fromNode = AstFactory.doubleLiteral(1.0);
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    DoubleLiteral toNode = AstFactory.doubleLiteral(1.0);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitExportDirective() {
    ExportDirective fromNode = AstFactory.exportDirective2("dart:uri");
    ExportElement element = new ExportElementImpl(-1);
    fromNode.element = element;
    ExportDirective toNode = AstFactory.exportDirective2("dart:uri");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.element, same(element));
  }

  void test_visitFunctionExpression() {
    FunctionExpression fromNode = AstFactory.functionExpression2(
        AstFactory.formalParameterList(), AstFactory.emptyFunctionBody());
    MethodElement element = ElementFactory.methodElement(
        "m", ElementFactory.classElement2("C").type);
    fromNode.element = element;
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    FunctionExpression toNode = AstFactory.functionExpression2(
        AstFactory.formalParameterList(), AstFactory.emptyFunctionBody());
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.element, same(element));
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitFunctionExpressionInvocation() {
    FunctionExpressionInvocation fromNode =
        AstFactory.functionExpressionInvocation(AstFactory.identifier3("f"));
    MethodElement propagatedElement = ElementFactory.methodElement(
        "m", ElementFactory.classElement2("C").type);
    fromNode.propagatedElement = propagatedElement;
    MethodElement staticElement = ElementFactory.methodElement(
        "m", ElementFactory.classElement2("C").type);
    fromNode.staticElement = staticElement;
    FunctionExpressionInvocation toNode =
        AstFactory.functionExpressionInvocation(AstFactory.identifier3("f"));
    ClassElement elementT = ElementFactory.classElement2('T');
    fromNode.typeArguments =
        AstFactory.typeArgumentList(<TypeName>[AstFactory.typeName(elementT)]);
    toNode.typeArguments =
        AstFactory.typeArgumentList(<TypeName>[AstFactory.typeName4('T')]);

    _copyAndVerifyInvocation(fromNode, toNode);

    expect(toNode.propagatedElement, same(propagatedElement));
    expect(toNode.staticElement, same(staticElement));
  }

  void test_visitImportDirective() {
    ImportDirective fromNode = AstFactory.importDirective3("dart:uri", null);
    ImportElement element = new ImportElementImpl(0);
    fromNode.element = element;
    ImportDirective toNode = AstFactory.importDirective3("dart:uri", null);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.element, same(element));
  }

  void test_visitIndexExpression() {
    IndexExpression fromNode = AstFactory.indexExpression(
        AstFactory.identifier3("a"), AstFactory.integer(0));
    MethodElement propagatedElement = ElementFactory.methodElement(
        "m", ElementFactory.classElement2("C").type);
    MethodElement staticElement = ElementFactory.methodElement(
        "m", ElementFactory.classElement2("C").type);
    AuxiliaryElements auxiliaryElements =
        new AuxiliaryElements(staticElement, propagatedElement);
    fromNode.auxiliaryElements = auxiliaryElements;
    fromNode.propagatedElement = propagatedElement;
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    fromNode.staticElement = staticElement;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    IndexExpression toNode = AstFactory.indexExpression(
        AstFactory.identifier3("a"), AstFactory.integer(0));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.auxiliaryElements, same(auxiliaryElements));
    expect(toNode.propagatedElement, same(propagatedElement));
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticElement, same(staticElement));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitInstanceCreationExpression() {
    InstanceCreationExpression fromNode = AstFactory
        .instanceCreationExpression2(Keyword.NEW, AstFactory.typeName4("C"));
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    ConstructorElement staticElement = ElementFactory.constructorElement2(
        ElementFactory.classElement2("C"), null);
    fromNode.staticElement = staticElement;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    InstanceCreationExpression toNode = AstFactory.instanceCreationExpression2(
        Keyword.NEW, AstFactory.typeName4("C"));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticElement, same(staticElement));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitIntegerLiteral() {
    IntegerLiteral fromNode = AstFactory.integer(2);
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    IntegerLiteral toNode = AstFactory.integer(2);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitIsExpression() {
    IsExpression fromNode = AstFactory.isExpression(
        AstFactory.identifier3("x"), false, AstFactory.typeName4("A"));
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    IsExpression toNode = AstFactory.isExpression(
        AstFactory.identifier3("x"), false, AstFactory.typeName4("A"));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitLibraryIdentifier() {
    LibraryIdentifier fromNode =
        AstFactory.libraryIdentifier([AstFactory.identifier3("lib")]);
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    LibraryIdentifier toNode =
        AstFactory.libraryIdentifier([AstFactory.identifier3("lib")]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitListLiteral() {
    ListLiteral fromNode = AstFactory.listLiteral();
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    ListLiteral toNode = AstFactory.listLiteral();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitMapLiteral() {
    MapLiteral fromNode = AstFactory.mapLiteral2();
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    MapLiteral toNode = AstFactory.mapLiteral2();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitMethodInvocation() {
    MethodInvocation fromNode = AstFactory.methodInvocation2("m");
    MethodInvocation toNode = AstFactory.methodInvocation2("m");
    ClassElement elementT = ElementFactory.classElement2('T');
    fromNode.typeArguments =
        AstFactory.typeArgumentList(<TypeName>[AstFactory.typeName(elementT)]);
    toNode.typeArguments =
        AstFactory.typeArgumentList(<TypeName>[AstFactory.typeName4('T')]);
    _copyAndVerifyInvocation(fromNode, toNode);
  }

  void test_visitNamedExpression() {
    NamedExpression fromNode =
        AstFactory.namedExpression2("n", AstFactory.integer(0));
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    NamedExpression toNode =
        AstFactory.namedExpression2("n", AstFactory.integer(0));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitNullLiteral() {
    NullLiteral fromNode = AstFactory.nullLiteral();
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    NullLiteral toNode = AstFactory.nullLiteral();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitParenthesizedExpression() {
    ParenthesizedExpression fromNode =
        AstFactory.parenthesizedExpression(AstFactory.integer(0));
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    ParenthesizedExpression toNode =
        AstFactory.parenthesizedExpression(AstFactory.integer(0));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitPartDirective() {
    PartDirective fromNode = AstFactory.partDirective2("part.dart");
    LibraryElement element = new LibraryElementImpl.forNode(
        null, AstFactory.libraryIdentifier2(["lib"]));
    fromNode.element = element;
    PartDirective toNode = AstFactory.partDirective2("part.dart");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.element, same(element));
  }

  void test_visitPartOfDirective() {
    PartOfDirective fromNode =
        AstFactory.partOfDirective(AstFactory.libraryIdentifier2(["lib"]));
    LibraryElement element = new LibraryElementImpl.forNode(
        null, AstFactory.libraryIdentifier2(["lib"]));
    fromNode.element = element;
    PartOfDirective toNode =
        AstFactory.partOfDirective(AstFactory.libraryIdentifier2(["lib"]));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.element, same(element));
  }

  void test_visitPostfixExpression() {
    String variableName = "x";
    PostfixExpression fromNode = AstFactory.postfixExpression(
        AstFactory.identifier3(variableName), TokenType.PLUS_PLUS);
    MethodElement propagatedElement = ElementFactory.methodElement(
        "+", ElementFactory.classElement2("C").type);
    fromNode.propagatedElement = propagatedElement;
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    MethodElement staticElement = ElementFactory.methodElement(
        "+", ElementFactory.classElement2("C").type);
    fromNode.staticElement = staticElement;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    PostfixExpression toNode = AstFactory.postfixExpression(
        AstFactory.identifier3(variableName), TokenType.PLUS_PLUS);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedElement, same(propagatedElement));
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticElement, same(staticElement));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitPrefixedIdentifier() {
    PrefixedIdentifier fromNode = AstFactory.identifier5("p", "f");
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    PrefixedIdentifier toNode = AstFactory.identifier5("p", "f");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitPrefixExpression() {
    PrefixExpression fromNode = AstFactory.prefixExpression(
        TokenType.PLUS_PLUS, AstFactory.identifier3("x"));
    MethodElement propagatedElement = ElementFactory.methodElement(
        "+", ElementFactory.classElement2("C").type);
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedElement = propagatedElement;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    MethodElement staticElement = ElementFactory.methodElement(
        "+", ElementFactory.classElement2("C").type);
    fromNode.staticElement = staticElement;
    fromNode.staticType = staticType;
    PrefixExpression toNode = AstFactory.prefixExpression(
        TokenType.PLUS_PLUS, AstFactory.identifier3("x"));
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedElement, same(propagatedElement));
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticElement, same(staticElement));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitPropertyAccess() {
    PropertyAccess fromNode =
        AstFactory.propertyAccess2(AstFactory.identifier3("x"), "y");
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    PropertyAccess toNode =
        AstFactory.propertyAccess2(AstFactory.identifier3("x"), "y");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitRedirectingConstructorInvocation() {
    RedirectingConstructorInvocation fromNode =
        AstFactory.redirectingConstructorInvocation();
    ConstructorElement staticElement = ElementFactory.constructorElement2(
        ElementFactory.classElement2("C"), null);
    fromNode.staticElement = staticElement;
    RedirectingConstructorInvocation toNode =
        AstFactory.redirectingConstructorInvocation();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticElement, same(staticElement));
  }

  void test_visitRethrowExpression() {
    RethrowExpression fromNode = AstFactory.rethrowExpression();
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    RethrowExpression toNode = AstFactory.rethrowExpression();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitSimpleIdentifier() {
    SimpleIdentifier fromNode = AstFactory.identifier3("x");
    MethodElement propagatedElement = ElementFactory.methodElement(
        "m", ElementFactory.classElement2("C").type);
    MethodElement staticElement = ElementFactory.methodElement(
        "m", ElementFactory.classElement2("C").type);
    AuxiliaryElements auxiliaryElements =
        new AuxiliaryElements(staticElement, propagatedElement);
    fromNode.auxiliaryElements = auxiliaryElements;
    fromNode.propagatedElement = propagatedElement;
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    fromNode.staticElement = staticElement;
    DartType staticType = ElementFactory.classElement2("C").type;
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
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    SimpleStringLiteral toNode = AstFactory.string2("abc");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitStringInterpolation() {
    StringInterpolation fromNode =
        AstFactory.string([AstFactory.interpolationString("a", "'a'")]);
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    StringInterpolation toNode =
        AstFactory.string([AstFactory.interpolationString("a", "'a'")]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitSuperConstructorInvocation() {
    SuperConstructorInvocation fromNode =
        AstFactory.superConstructorInvocation();
    ConstructorElement staticElement = ElementFactory.constructorElement2(
        ElementFactory.classElement2("C"), null);
    fromNode.staticElement = staticElement;
    SuperConstructorInvocation toNode = AstFactory.superConstructorInvocation();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.staticElement, same(staticElement));
  }

  void test_visitSuperExpression() {
    SuperExpression fromNode = AstFactory.superExpression();
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    SuperExpression toNode = AstFactory.superExpression();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitSymbolLiteral() {
    SymbolLiteral fromNode = AstFactory.symbolLiteral(["s"]);
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    SymbolLiteral toNode = AstFactory.symbolLiteral(["s"]);
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitThisExpression() {
    ThisExpression fromNode = AstFactory.thisExpression();
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    ThisExpression toNode = AstFactory.thisExpression();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitThrowExpression() {
    ThrowExpression fromNode = AstFactory.throwExpression();
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;
    ThrowExpression toNode = AstFactory.throwExpression();
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
  }

  void test_visitTypeName() {
    TypeName fromNode = AstFactory.typeName4("C");
    DartType type = ElementFactory.classElement2("C").type;
    fromNode.type = type;
    TypeName toNode = AstFactory.typeName4("C");
    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.type, same(type));
  }

  void _copyAndVerifyInvocation(
      InvocationExpression fromNode, InvocationExpression toNode) {
    DartType propagatedType = ElementFactory.classElement2("C").type;
    fromNode.propagatedType = propagatedType;
    DartType staticType = ElementFactory.classElement2("C").type;
    fromNode.staticType = staticType;

    DartType propagatedInvokeType = ElementFactory.classElement2("C").type;
    fromNode.propagatedInvokeType = propagatedInvokeType;
    DartType staticInvokeType = ElementFactory.classElement2("C").type;
    fromNode.staticInvokeType = staticInvokeType;

    ResolutionCopier.copyResolutionData(fromNode, toNode);
    expect(toNode.propagatedType, same(propagatedType));
    expect(toNode.staticType, same(staticType));
    expect(toNode.propagatedInvokeType, same(propagatedInvokeType));
    expect(toNode.staticInvokeType, same(staticInvokeType));
    List<TypeName> fromTypeArguments = toNode.typeArguments.arguments;
    List<TypeName> toTypeArguments = fromNode.typeArguments.arguments;
    if (fromTypeArguments != null) {
      for (int i = 0; i < fromTypeArguments.length; i++) {
        TypeName toArgument = fromTypeArguments[i];
        TypeName fromArgument = toTypeArguments[i];
        expect(toArgument.type, same(fromArgument.type));
      }
    }
  }
}

@reflectiveTest
class ToSourceVisitorTest extends EngineTestCase {
  void test_visitAdjacentStrings() {
    _assertSource(
        "'a' 'b'",
        AstFactory.adjacentStrings(
            [AstFactory.string2("a"), AstFactory.string2("b")]));
  }

  void test_visitAnnotation_constant() {
    _assertSource("@A", AstFactory.annotation(AstFactory.identifier3("A")));
  }

  void test_visitAnnotation_constructor() {
    _assertSource(
        "@A.c()",
        AstFactory.annotation2(AstFactory.identifier3("A"),
            AstFactory.identifier3("c"), AstFactory.argumentList()));
  }

  void test_visitArgumentList() {
    _assertSource(
        "(a, b)",
        AstFactory.argumentList(
            [AstFactory.identifier3("a"), AstFactory.identifier3("b")]));
  }

  void test_visitAsExpression() {
    _assertSource(
        "e as T",
        AstFactory.asExpression(
            AstFactory.identifier3("e"), AstFactory.typeName4("T")));
  }

  void test_visitAssertStatement() {
    _assertSource(
        "assert (a);", AstFactory.assertStatement(AstFactory.identifier3("a")));
  }

  void test_visitAssertStatement_withMessage() {
    _assertSource(
        "assert (a, b);",
        AstFactory.assertStatement(
            AstFactory.identifier3("a"), AstFactory.identifier3('b')));
  }

  void test_visitAssignmentExpression() {
    _assertSource(
        "a = b",
        AstFactory.assignmentExpression(AstFactory.identifier3("a"),
            TokenType.EQ, AstFactory.identifier3("b")));
  }

  void test_visitAwaitExpression() {
    _assertSource(
        "await e", AstFactory.awaitExpression(AstFactory.identifier3("e")));
  }

  void test_visitBinaryExpression() {
    _assertSource(
        "a + b",
        AstFactory.binaryExpression(AstFactory.identifier3("a"), TokenType.PLUS,
            AstFactory.identifier3("b")));
  }

  void test_visitBlock_empty() {
    _assertSource("{}", AstFactory.block());
  }

  void test_visitBlock_nonEmpty() {
    _assertSource(
        "{break; break;}",
        AstFactory
            .block([AstFactory.breakStatement(), AstFactory.breakStatement()]));
  }

  void test_visitBlockFunctionBody_async() {
    _assertSource("async {}", AstFactory.asyncBlockFunctionBody());
  }

  void test_visitBlockFunctionBody_async_star() {
    _assertSource("async* {}", AstFactory.asyncGeneratorBlockFunctionBody());
  }

  void test_visitBlockFunctionBody_simple() {
    _assertSource("{}", AstFactory.blockFunctionBody2());
  }

  void test_visitBlockFunctionBody_sync() {
    _assertSource("sync {}", AstFactory.syncBlockFunctionBody());
  }

  void test_visitBlockFunctionBody_sync_star() {
    _assertSource("sync* {}", AstFactory.syncGeneratorBlockFunctionBody());
  }

  void test_visitBooleanLiteral_false() {
    _assertSource("false", AstFactory.booleanLiteral(false));
  }

  void test_visitBooleanLiteral_true() {
    _assertSource("true", AstFactory.booleanLiteral(true));
  }

  void test_visitBreakStatement_label() {
    _assertSource("break l;", AstFactory.breakStatement2("l"));
  }

  void test_visitBreakStatement_noLabel() {
    _assertSource("break;", AstFactory.breakStatement());
  }

  void test_visitCascadeExpression_field() {
    _assertSource(
        "a..b..c",
        AstFactory.cascadeExpression(AstFactory.identifier3("a"), [
          AstFactory.cascadedPropertyAccess("b"),
          AstFactory.cascadedPropertyAccess("c")
        ]));
  }

  void test_visitCascadeExpression_index() {
    _assertSource(
        "a..[0]..[1]",
        AstFactory.cascadeExpression(AstFactory.identifier3("a"), [
          AstFactory.cascadedIndexExpression(AstFactory.integer(0)),
          AstFactory.cascadedIndexExpression(AstFactory.integer(1))
        ]));
  }

  void test_visitCascadeExpression_method() {
    _assertSource(
        "a..b()..c()",
        AstFactory.cascadeExpression(AstFactory.identifier3("a"), [
          AstFactory.cascadedMethodInvocation("b"),
          AstFactory.cascadedMethodInvocation("c")
        ]));
  }

  void test_visitCatchClause_catch_noStack() {
    _assertSource("catch (e) {}", AstFactory.catchClause("e"));
  }

  void test_visitCatchClause_catch_stack() {
    _assertSource("catch (e, s) {}", AstFactory.catchClause2("e", "s"));
  }

  void test_visitCatchClause_on() {
    _assertSource(
        "on E {}", AstFactory.catchClause3(AstFactory.typeName4("E")));
  }

  void test_visitCatchClause_on_catch() {
    _assertSource("on E catch (e) {}",
        AstFactory.catchClause4(AstFactory.typeName4("E"), "e"));
  }

  void test_visitClassDeclaration_abstract() {
    _assertSource(
        "abstract class C {}",
        AstFactory.classDeclaration(
            Keyword.ABSTRACT, "C", null, null, null, null));
  }

  void test_visitClassDeclaration_empty() {
    _assertSource("class C {}",
        AstFactory.classDeclaration(null, "C", null, null, null, null));
  }

  void test_visitClassDeclaration_extends() {
    _assertSource(
        "class C extends A {}",
        AstFactory.classDeclaration(null, "C", null,
            AstFactory.extendsClause(AstFactory.typeName4("A")), null, null));
  }

  void test_visitClassDeclaration_extends_implements() {
    _assertSource(
        "class C extends A implements B {}",
        AstFactory.classDeclaration(
            null,
            "C",
            null,
            AstFactory.extendsClause(AstFactory.typeName4("A")),
            null,
            AstFactory.implementsClause([AstFactory.typeName4("B")])));
  }

  void test_visitClassDeclaration_extends_with() {
    _assertSource(
        "class C extends A with M {}",
        AstFactory.classDeclaration(
            null,
            "C",
            null,
            AstFactory.extendsClause(AstFactory.typeName4("A")),
            AstFactory.withClause([AstFactory.typeName4("M")]),
            null));
  }

  void test_visitClassDeclaration_extends_with_implements() {
    _assertSource(
        "class C extends A with M implements B {}",
        AstFactory.classDeclaration(
            null,
            "C",
            null,
            AstFactory.extendsClause(AstFactory.typeName4("A")),
            AstFactory.withClause([AstFactory.typeName4("M")]),
            AstFactory.implementsClause([AstFactory.typeName4("B")])));
  }

  void test_visitClassDeclaration_implements() {
    _assertSource(
        "class C implements B {}",
        AstFactory.classDeclaration(null, "C", null, null, null,
            AstFactory.implementsClause([AstFactory.typeName4("B")])));
  }

  void test_visitClassDeclaration_multipleMember() {
    _assertSource(
        "class C {var a; var b;}",
        AstFactory.classDeclaration(null, "C", null, null, null, null, [
          AstFactory.fieldDeclaration2(
              false, Keyword.VAR, [AstFactory.variableDeclaration("a")]),
          AstFactory.fieldDeclaration2(
              false, Keyword.VAR, [AstFactory.variableDeclaration("b")])
        ]));
  }

  void test_visitClassDeclaration_parameters() {
    _assertSource(
        "class C<E> {}",
        AstFactory.classDeclaration(
            null, "C", AstFactory.typeParameterList(["E"]), null, null, null));
  }

  void test_visitClassDeclaration_parameters_extends() {
    _assertSource(
        "class C<E> extends A {}",
        AstFactory.classDeclaration(
            null,
            "C",
            AstFactory.typeParameterList(["E"]),
            AstFactory.extendsClause(AstFactory.typeName4("A")),
            null,
            null));
  }

  void test_visitClassDeclaration_parameters_extends_implements() {
    _assertSource(
        "class C<E> extends A implements B {}",
        AstFactory.classDeclaration(
            null,
            "C",
            AstFactory.typeParameterList(["E"]),
            AstFactory.extendsClause(AstFactory.typeName4("A")),
            null,
            AstFactory.implementsClause([AstFactory.typeName4("B")])));
  }

  void test_visitClassDeclaration_parameters_extends_with() {
    _assertSource(
        "class C<E> extends A with M {}",
        AstFactory.classDeclaration(
            null,
            "C",
            AstFactory.typeParameterList(["E"]),
            AstFactory.extendsClause(AstFactory.typeName4("A")),
            AstFactory.withClause([AstFactory.typeName4("M")]),
            null));
  }

  void test_visitClassDeclaration_parameters_extends_with_implements() {
    _assertSource(
        "class C<E> extends A with M implements B {}",
        AstFactory.classDeclaration(
            null,
            "C",
            AstFactory.typeParameterList(["E"]),
            AstFactory.extendsClause(AstFactory.typeName4("A")),
            AstFactory.withClause([AstFactory.typeName4("M")]),
            AstFactory.implementsClause([AstFactory.typeName4("B")])));
  }

  void test_visitClassDeclaration_parameters_implements() {
    _assertSource(
        "class C<E> implements B {}",
        AstFactory.classDeclaration(
            null,
            "C",
            AstFactory.typeParameterList(["E"]),
            null,
            null,
            AstFactory.implementsClause([AstFactory.typeName4("B")])));
  }

  void test_visitClassDeclaration_singleMember() {
    _assertSource(
        "class C {var a;}",
        AstFactory.classDeclaration(null, "C", null, null, null, null, [
          AstFactory.fieldDeclaration2(
              false, Keyword.VAR, [AstFactory.variableDeclaration("a")])
        ]));
  }

  void test_visitClassDeclaration_withMetadata() {
    ClassDeclaration declaration =
        AstFactory.classDeclaration(null, "C", null, null, null, null);
    declaration.metadata
        .add(AstFactory.annotation(AstFactory.identifier3("deprecated")));
    _assertSource("@deprecated class C {}", declaration);
  }

  void test_visitClassTypeAlias_abstract() {
    _assertSource(
        "abstract class C = S with M1;",
        AstFactory.classTypeAlias(
            "C",
            null,
            Keyword.ABSTRACT,
            AstFactory.typeName4("S"),
            AstFactory.withClause([AstFactory.typeName4("M1")]),
            null));
  }

  void test_visitClassTypeAlias_abstract_implements() {
    _assertSource(
        "abstract class C = S with M1 implements I;",
        AstFactory.classTypeAlias(
            "C",
            null,
            Keyword.ABSTRACT,
            AstFactory.typeName4("S"),
            AstFactory.withClause([AstFactory.typeName4("M1")]),
            AstFactory.implementsClause([AstFactory.typeName4("I")])));
  }

  void test_visitClassTypeAlias_generic() {
    _assertSource(
        "class C<E> = S<E> with M1<E>;",
        AstFactory.classTypeAlias(
            "C",
            AstFactory.typeParameterList(["E"]),
            null,
            AstFactory.typeName4("S", [AstFactory.typeName4("E")]),
            AstFactory.withClause([
              AstFactory.typeName4("M1", [AstFactory.typeName4("E")])
            ]),
            null));
  }

  void test_visitClassTypeAlias_implements() {
    _assertSource(
        "class C = S with M1 implements I;",
        AstFactory.classTypeAlias(
            "C",
            null,
            null,
            AstFactory.typeName4("S"),
            AstFactory.withClause([AstFactory.typeName4("M1")]),
            AstFactory.implementsClause([AstFactory.typeName4("I")])));
  }

  void test_visitClassTypeAlias_minimal() {
    _assertSource(
        "class C = S with M1;",
        AstFactory.classTypeAlias("C", null, null, AstFactory.typeName4("S"),
            AstFactory.withClause([AstFactory.typeName4("M1")]), null));
  }

  void test_visitClassTypeAlias_parameters_abstract() {
    _assertSource(
        "abstract class C<E> = S with M1;",
        AstFactory.classTypeAlias(
            "C",
            AstFactory.typeParameterList(["E"]),
            Keyword.ABSTRACT,
            AstFactory.typeName4("S"),
            AstFactory.withClause([AstFactory.typeName4("M1")]),
            null));
  }

  void test_visitClassTypeAlias_parameters_abstract_implements() {
    _assertSource(
        "abstract class C<E> = S with M1 implements I;",
        AstFactory.classTypeAlias(
            "C",
            AstFactory.typeParameterList(["E"]),
            Keyword.ABSTRACT,
            AstFactory.typeName4("S"),
            AstFactory.withClause([AstFactory.typeName4("M1")]),
            AstFactory.implementsClause([AstFactory.typeName4("I")])));
  }

  void test_visitClassTypeAlias_parameters_implements() {
    _assertSource(
        "class C<E> = S with M1 implements I;",
        AstFactory.classTypeAlias(
            "C",
            AstFactory.typeParameterList(["E"]),
            null,
            AstFactory.typeName4("S"),
            AstFactory.withClause([AstFactory.typeName4("M1")]),
            AstFactory.implementsClause([AstFactory.typeName4("I")])));
  }

  void test_visitClassTypeAlias_withMetadata() {
    ClassTypeAlias declaration = AstFactory.classTypeAlias(
        "C",
        null,
        null,
        AstFactory.typeName4("S"),
        AstFactory.withClause([AstFactory.typeName4("M1")]),
        null);
    declaration.metadata
        .add(AstFactory.annotation(AstFactory.identifier3("deprecated")));
    _assertSource("@deprecated class C = S with M1;", declaration);
  }

  void test_visitComment() {
    _assertSource(
        "",
        Comment.createBlockComment(
            <Token>[TokenFactory.tokenFromString("/* comment */")]));
  }

  void test_visitCommentReference() {
    _assertSource("", new CommentReference(null, AstFactory.identifier3("a")));
  }

  void test_visitCompilationUnit_declaration() {
    _assertSource(
        "var a;",
        AstFactory.compilationUnit2([
          AstFactory.topLevelVariableDeclaration2(
              Keyword.VAR, [AstFactory.variableDeclaration("a")])
        ]));
  }

  void test_visitCompilationUnit_directive() {
    _assertSource("library l;",
        AstFactory.compilationUnit3([AstFactory.libraryDirective2("l")]));
  }

  void test_visitCompilationUnit_directive_declaration() {
    _assertSource(
        "library l; var a;",
        AstFactory.compilationUnit4([
          AstFactory.libraryDirective2("l")
        ], [
          AstFactory.topLevelVariableDeclaration2(
              Keyword.VAR, [AstFactory.variableDeclaration("a")])
        ]));
  }

  void test_visitCompilationUnit_empty() {
    _assertSource("", AstFactory.compilationUnit());
  }

  void test_visitCompilationUnit_script() {
    _assertSource(
        "!#/bin/dartvm", AstFactory.compilationUnit5("!#/bin/dartvm"));
  }

  void test_visitCompilationUnit_script_declaration() {
    _assertSource(
        "!#/bin/dartvm var a;",
        AstFactory.compilationUnit6("!#/bin/dartvm", [
          AstFactory.topLevelVariableDeclaration2(
              Keyword.VAR, [AstFactory.variableDeclaration("a")])
        ]));
  }

  void test_visitCompilationUnit_script_directive() {
    _assertSource(
        "!#/bin/dartvm library l;",
        AstFactory.compilationUnit7(
            "!#/bin/dartvm", [AstFactory.libraryDirective2("l")]));
  }

  void test_visitCompilationUnit_script_directives_declarations() {
    _assertSource(
        "!#/bin/dartvm library l; var a;",
        AstFactory.compilationUnit8("!#/bin/dartvm", [
          AstFactory.libraryDirective2("l")
        ], [
          AstFactory.topLevelVariableDeclaration2(
              Keyword.VAR, [AstFactory.variableDeclaration("a")])
        ]));
  }

  void test_visitConditionalExpression() {
    _assertSource(
        "a ? b : c",
        AstFactory.conditionalExpression(AstFactory.identifier3("a"),
            AstFactory.identifier3("b"), AstFactory.identifier3("c")));
  }

  void test_visitConstructorDeclaration_const() {
    _assertSource(
        "const C() {}",
        AstFactory.constructorDeclaration2(
            Keyword.CONST,
            null,
            AstFactory.identifier3("C"),
            null,
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2()));
  }

  void test_visitConstructorDeclaration_external() {
    _assertSource(
        "external C();",
        AstFactory.constructorDeclaration(AstFactory.identifier3("C"), null,
            AstFactory.formalParameterList(), null));
  }

  void test_visitConstructorDeclaration_minimal() {
    _assertSource(
        "C() {}",
        AstFactory.constructorDeclaration2(
            null,
            null,
            AstFactory.identifier3("C"),
            null,
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2()));
  }

  void test_visitConstructorDeclaration_multipleInitializers() {
    _assertSource(
        "C() : a = b, c = d {}",
        AstFactory.constructorDeclaration2(
            null,
            null,
            AstFactory.identifier3("C"),
            null,
            AstFactory.formalParameterList(),
            [
              AstFactory.constructorFieldInitializer(
                  false, "a", AstFactory.identifier3("b")),
              AstFactory.constructorFieldInitializer(
                  false, "c", AstFactory.identifier3("d"))
            ],
            AstFactory.blockFunctionBody2()));
  }

  void test_visitConstructorDeclaration_multipleParameters() {
    _assertSource(
        "C(var a, var b) {}",
        AstFactory.constructorDeclaration2(
            null,
            null,
            AstFactory.identifier3("C"),
            null,
            AstFactory.formalParameterList([
              AstFactory.simpleFormalParameter(Keyword.VAR, "a"),
              AstFactory.simpleFormalParameter(Keyword.VAR, "b")
            ]),
            null,
            AstFactory.blockFunctionBody2()));
  }

  void test_visitConstructorDeclaration_named() {
    _assertSource(
        "C.m() {}",
        AstFactory.constructorDeclaration2(
            null,
            null,
            AstFactory.identifier3("C"),
            "m",
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2()));
  }

  void test_visitConstructorDeclaration_singleInitializer() {
    _assertSource(
        "C() : a = b {}",
        AstFactory.constructorDeclaration2(
            null,
            null,
            AstFactory.identifier3("C"),
            null,
            AstFactory.formalParameterList(),
            [
              AstFactory.constructorFieldInitializer(
                  false, "a", AstFactory.identifier3("b"))
            ],
            AstFactory.blockFunctionBody2()));
  }

  void test_visitConstructorDeclaration_withMetadata() {
    ConstructorDeclaration declaration = AstFactory.constructorDeclaration2(
        null,
        null,
        AstFactory.identifier3("C"),
        null,
        AstFactory.formalParameterList(),
        null,
        AstFactory.blockFunctionBody2());
    declaration.metadata
        .add(AstFactory.annotation(AstFactory.identifier3("deprecated")));
    _assertSource("@deprecated C() {}", declaration);
  }

  void test_visitConstructorFieldInitializer_withoutThis() {
    _assertSource(
        "a = b",
        AstFactory.constructorFieldInitializer(
            false, "a", AstFactory.identifier3("b")));
  }

  void test_visitConstructorFieldInitializer_withThis() {
    _assertSource(
        "this.a = b",
        AstFactory.constructorFieldInitializer(
            true, "a", AstFactory.identifier3("b")));
  }

  void test_visitConstructorName_named_prefix() {
    _assertSource("p.C.n",
        AstFactory.constructorName(AstFactory.typeName4("p.C.n"), null));
  }

  void test_visitConstructorName_unnamed_noPrefix() {
    _assertSource(
        "C", AstFactory.constructorName(AstFactory.typeName4("C"), null));
  }

  void test_visitConstructorName_unnamed_prefix() {
    _assertSource(
        "p.C",
        AstFactory.constructorName(
            AstFactory.typeName3(AstFactory.identifier5("p", "C")), null));
  }

  void test_visitContinueStatement_label() {
    _assertSource("continue l;", AstFactory.continueStatement("l"));
  }

  void test_visitContinueStatement_noLabel() {
    _assertSource("continue;", AstFactory.continueStatement());
  }

  void test_visitDefaultFormalParameter_annotation() {
    DefaultFormalParameter parameter = AstFactory.positionalFormalParameter(
        AstFactory.simpleFormalParameter3("p"), AstFactory.integer(0));
    parameter.metadata.add(AstFactory.annotation(AstFactory.identifier3("A")));
    _assertSource('@A p = 0', parameter);
  }

  void test_visitDefaultFormalParameter_named_noValue() {
    _assertSource(
        "p",
        AstFactory.namedFormalParameter(
            AstFactory.simpleFormalParameter3("p"), null));
  }

  void test_visitDefaultFormalParameter_named_value() {
    _assertSource(
        "p : 0",
        AstFactory.namedFormalParameter(
            AstFactory.simpleFormalParameter3("p"), AstFactory.integer(0)));
  }

  void test_visitDefaultFormalParameter_positional_noValue() {
    _assertSource(
        "p",
        AstFactory.positionalFormalParameter(
            AstFactory.simpleFormalParameter3("p"), null));
  }

  void test_visitDefaultFormalParameter_positional_value() {
    _assertSource(
        "p = 0",
        AstFactory.positionalFormalParameter(
            AstFactory.simpleFormalParameter3("p"), AstFactory.integer(0)));
  }

  void test_visitDoStatement() {
    _assertSource(
        "do {} while (c);",
        AstFactory.doStatement(
            AstFactory.block(), AstFactory.identifier3("c")));
  }

  void test_visitDoubleLiteral() {
    _assertSource("4.2", AstFactory.doubleLiteral(4.2));
  }

  void test_visitEmptyFunctionBody() {
    _assertSource(";", AstFactory.emptyFunctionBody());
  }

  void test_visitEmptyStatement() {
    _assertSource(";", AstFactory.emptyStatement());
  }

  void test_visitEnumDeclaration_multiple() {
    _assertSource(
        "enum E {ONE, TWO}", AstFactory.enumDeclaration2("E", ["ONE", "TWO"]));
  }

  void test_visitEnumDeclaration_single() {
    _assertSource("enum E {ONE}", AstFactory.enumDeclaration2("E", ["ONE"]));
  }

  void test_visitExportDirective_combinator() {
    _assertSource(
        "export 'a.dart' show A;",
        AstFactory.exportDirective2("a.dart", [
          AstFactory.showCombinator([AstFactory.identifier3("A")])
        ]));
  }

  void test_visitExportDirective_combinators() {
    _assertSource(
        "export 'a.dart' show A hide B;",
        AstFactory.exportDirective2("a.dart", [
          AstFactory.showCombinator([AstFactory.identifier3("A")]),
          AstFactory.hideCombinator([AstFactory.identifier3("B")])
        ]));
  }

  void test_visitExportDirective_minimal() {
    _assertSource("export 'a.dart';", AstFactory.exportDirective2("a.dart"));
  }

  void test_visitExportDirective_withMetadata() {
    ExportDirective directive = AstFactory.exportDirective2("a.dart");
    directive.metadata
        .add(AstFactory.annotation(AstFactory.identifier3("deprecated")));
    _assertSource("@deprecated export 'a.dart';", directive);
  }

  void test_visitExpressionFunctionBody_async() {
    _assertSource("async => a;",
        AstFactory.asyncExpressionFunctionBody(AstFactory.identifier3("a")));
  }

  void test_visitExpressionFunctionBody_simple() {
    _assertSource("=> a;",
        AstFactory.expressionFunctionBody(AstFactory.identifier3("a")));
  }

  void test_visitExpressionStatement() {
    _assertSource(
        "a;", AstFactory.expressionStatement(AstFactory.identifier3("a")));
  }

  void test_visitExtendsClause() {
    _assertSource(
        "extends C", AstFactory.extendsClause(AstFactory.typeName4("C")));
  }

  void test_visitFieldDeclaration_instance() {
    _assertSource(
        "var a;",
        AstFactory.fieldDeclaration2(
            false, Keyword.VAR, [AstFactory.variableDeclaration("a")]));
  }

  void test_visitFieldDeclaration_static() {
    _assertSource(
        "static var a;",
        AstFactory.fieldDeclaration2(
            true, Keyword.VAR, [AstFactory.variableDeclaration("a")]));
  }

  void test_visitFieldDeclaration_withMetadata() {
    FieldDeclaration declaration = AstFactory.fieldDeclaration2(
        false, Keyword.VAR, [AstFactory.variableDeclaration("a")]);
    declaration.metadata
        .add(AstFactory.annotation(AstFactory.identifier3("deprecated")));
    _assertSource("@deprecated var a;", declaration);
  }

  void test_visitFieldFormalParameter_annotation() {
    FieldFormalParameter parameter = AstFactory.fieldFormalParameter2('f');
    parameter.metadata.add(AstFactory.annotation(AstFactory.identifier3("A")));
    _assertSource('@A this.f', parameter);
  }

  void test_visitFieldFormalParameter_functionTyped() {
    _assertSource(
        "A this.a(b)",
        AstFactory.fieldFormalParameter(
            null,
            AstFactory.typeName4("A"),
            "a",
            AstFactory.formalParameterList(
                [AstFactory.simpleFormalParameter3("b")])));
  }

  void test_visitFieldFormalParameter_functionTyped_typeParameters() {
    _assertSource(
        "A this.a<E, F>(b)",
        new FieldFormalParameter(
            null,
            null,
            null,
            AstFactory.typeName4('A'),
            TokenFactory.tokenFromKeyword(Keyword.THIS),
            TokenFactory.tokenFromType(TokenType.PERIOD),
            AstFactory.identifier3('a'),
            AstFactory.typeParameterList(['E', 'F']),
            AstFactory.formalParameterList(
                [AstFactory.simpleFormalParameter3("b")])));
  }

  void test_visitFieldFormalParameter_keyword() {
    _assertSource(
        "var this.a", AstFactory.fieldFormalParameter(Keyword.VAR, null, "a"));
  }

  void test_visitFieldFormalParameter_keywordAndType() {
    _assertSource(
        "final A this.a",
        AstFactory.fieldFormalParameter(
            Keyword.FINAL, AstFactory.typeName4("A"), "a"));
  }

  void test_visitFieldFormalParameter_type() {
    _assertSource("A this.a",
        AstFactory.fieldFormalParameter(null, AstFactory.typeName4("A"), "a"));
  }

  void test_visitForEachStatement_declared() {
    _assertSource(
        "for (var a in b) {}",
        AstFactory.forEachStatement(AstFactory.declaredIdentifier3("a"),
            AstFactory.identifier3("b"), AstFactory.block()));
  }

  void test_visitForEachStatement_variable() {
    _assertSource(
        "for (a in b) {}",
        new ForEachStatement.withReference(
            null,
            TokenFactory.tokenFromKeyword(Keyword.FOR),
            TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
            AstFactory.identifier3("a"),
            TokenFactory.tokenFromKeyword(Keyword.IN),
            AstFactory.identifier3("b"),
            TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
            AstFactory.block()));
  }

  void test_visitForEachStatement_variable_await() {
    _assertSource(
        "await for (a in b) {}",
        new ForEachStatement.withReference(
            TokenFactory.tokenFromString("await"),
            TokenFactory.tokenFromKeyword(Keyword.FOR),
            TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
            AstFactory.identifier3("a"),
            TokenFactory.tokenFromKeyword(Keyword.IN),
            AstFactory.identifier3("b"),
            TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
            AstFactory.block()));
  }

  void test_visitFormalParameterList_empty() {
    _assertSource("()", AstFactory.formalParameterList());
  }

  void test_visitFormalParameterList_n() {
    _assertSource(
        "({a : 0})",
        AstFactory.formalParameterList([
          AstFactory.namedFormalParameter(
              AstFactory.simpleFormalParameter3("a"), AstFactory.integer(0))
        ]));
  }

  void test_visitFormalParameterList_nn() {
    _assertSource(
        "({a : 0, b : 1})",
        AstFactory.formalParameterList([
          AstFactory.namedFormalParameter(
              AstFactory.simpleFormalParameter3("a"), AstFactory.integer(0)),
          AstFactory.namedFormalParameter(
              AstFactory.simpleFormalParameter3("b"), AstFactory.integer(1))
        ]));
  }

  void test_visitFormalParameterList_p() {
    _assertSource(
        "([a = 0])",
        AstFactory.formalParameterList([
          AstFactory.positionalFormalParameter(
              AstFactory.simpleFormalParameter3("a"), AstFactory.integer(0))
        ]));
  }

  void test_visitFormalParameterList_pp() {
    _assertSource(
        "([a = 0, b = 1])",
        AstFactory.formalParameterList([
          AstFactory.positionalFormalParameter(
              AstFactory.simpleFormalParameter3("a"), AstFactory.integer(0)),
          AstFactory.positionalFormalParameter(
              AstFactory.simpleFormalParameter3("b"), AstFactory.integer(1))
        ]));
  }

  void test_visitFormalParameterList_r() {
    _assertSource(
        "(a)",
        AstFactory
            .formalParameterList([AstFactory.simpleFormalParameter3("a")]));
  }

  void test_visitFormalParameterList_rn() {
    _assertSource(
        "(a, {b : 1})",
        AstFactory.formalParameterList([
          AstFactory.simpleFormalParameter3("a"),
          AstFactory.namedFormalParameter(
              AstFactory.simpleFormalParameter3("b"), AstFactory.integer(1))
        ]));
  }

  void test_visitFormalParameterList_rnn() {
    _assertSource(
        "(a, {b : 1, c : 2})",
        AstFactory.formalParameterList([
          AstFactory.simpleFormalParameter3("a"),
          AstFactory.namedFormalParameter(
              AstFactory.simpleFormalParameter3("b"), AstFactory.integer(1)),
          AstFactory.namedFormalParameter(
              AstFactory.simpleFormalParameter3("c"), AstFactory.integer(2))
        ]));
  }

  void test_visitFormalParameterList_rp() {
    _assertSource(
        "(a, [b = 1])",
        AstFactory.formalParameterList([
          AstFactory.simpleFormalParameter3("a"),
          AstFactory.positionalFormalParameter(
              AstFactory.simpleFormalParameter3("b"), AstFactory.integer(1))
        ]));
  }

  void test_visitFormalParameterList_rpp() {
    _assertSource(
        "(a, [b = 1, c = 2])",
        AstFactory.formalParameterList([
          AstFactory.simpleFormalParameter3("a"),
          AstFactory.positionalFormalParameter(
              AstFactory.simpleFormalParameter3("b"), AstFactory.integer(1)),
          AstFactory.positionalFormalParameter(
              AstFactory.simpleFormalParameter3("c"), AstFactory.integer(2))
        ]));
  }

  void test_visitFormalParameterList_rr() {
    _assertSource(
        "(a, b)",
        AstFactory.formalParameterList([
          AstFactory.simpleFormalParameter3("a"),
          AstFactory.simpleFormalParameter3("b")
        ]));
  }

  void test_visitFormalParameterList_rrn() {
    _assertSource(
        "(a, b, {c : 3})",
        AstFactory.formalParameterList([
          AstFactory.simpleFormalParameter3("a"),
          AstFactory.simpleFormalParameter3("b"),
          AstFactory.namedFormalParameter(
              AstFactory.simpleFormalParameter3("c"), AstFactory.integer(3))
        ]));
  }

  void test_visitFormalParameterList_rrnn() {
    _assertSource(
        "(a, b, {c : 3, d : 4})",
        AstFactory.formalParameterList([
          AstFactory.simpleFormalParameter3("a"),
          AstFactory.simpleFormalParameter3("b"),
          AstFactory.namedFormalParameter(
              AstFactory.simpleFormalParameter3("c"), AstFactory.integer(3)),
          AstFactory.namedFormalParameter(
              AstFactory.simpleFormalParameter3("d"), AstFactory.integer(4))
        ]));
  }

  void test_visitFormalParameterList_rrp() {
    _assertSource(
        "(a, b, [c = 3])",
        AstFactory.formalParameterList([
          AstFactory.simpleFormalParameter3("a"),
          AstFactory.simpleFormalParameter3("b"),
          AstFactory.positionalFormalParameter(
              AstFactory.simpleFormalParameter3("c"), AstFactory.integer(3))
        ]));
  }

  void test_visitFormalParameterList_rrpp() {
    _assertSource(
        "(a, b, [c = 3, d = 4])",
        AstFactory.formalParameterList([
          AstFactory.simpleFormalParameter3("a"),
          AstFactory.simpleFormalParameter3("b"),
          AstFactory.positionalFormalParameter(
              AstFactory.simpleFormalParameter3("c"), AstFactory.integer(3)),
          AstFactory.positionalFormalParameter(
              AstFactory.simpleFormalParameter3("d"), AstFactory.integer(4))
        ]));
  }

  void test_visitForStatement_c() {
    _assertSource(
        "for (; c;) {}",
        AstFactory.forStatement(
            null, AstFactory.identifier3("c"), null, AstFactory.block()));
  }

  void test_visitForStatement_cu() {
    _assertSource(
        "for (; c; u) {}",
        AstFactory.forStatement(null, AstFactory.identifier3("c"),
            [AstFactory.identifier3("u")], AstFactory.block()));
  }

  void test_visitForStatement_e() {
    _assertSource(
        "for (e;;) {}",
        AstFactory.forStatement(
            AstFactory.identifier3("e"), null, null, AstFactory.block()));
  }

  void test_visitForStatement_ec() {
    _assertSource(
        "for (e; c;) {}",
        AstFactory.forStatement(AstFactory.identifier3("e"),
            AstFactory.identifier3("c"), null, AstFactory.block()));
  }

  void test_visitForStatement_ecu() {
    _assertSource(
        "for (e; c; u) {}",
        AstFactory.forStatement(
            AstFactory.identifier3("e"),
            AstFactory.identifier3("c"),
            [AstFactory.identifier3("u")],
            AstFactory.block()));
  }

  void test_visitForStatement_eu() {
    _assertSource(
        "for (e;; u) {}",
        AstFactory.forStatement(AstFactory.identifier3("e"), null,
            [AstFactory.identifier3("u")], AstFactory.block()));
  }

  void test_visitForStatement_i() {
    _assertSource(
        "for (var i;;) {}",
        AstFactory.forStatement2(
            AstFactory.variableDeclarationList2(
                Keyword.VAR, [AstFactory.variableDeclaration("i")]),
            null,
            null,
            AstFactory.block()));
  }

  void test_visitForStatement_ic() {
    _assertSource(
        "for (var i; c;) {}",
        AstFactory.forStatement2(
            AstFactory.variableDeclarationList2(
                Keyword.VAR, [AstFactory.variableDeclaration("i")]),
            AstFactory.identifier3("c"),
            null,
            AstFactory.block()));
  }

  void test_visitForStatement_icu() {
    _assertSource(
        "for (var i; c; u) {}",
        AstFactory.forStatement2(
            AstFactory.variableDeclarationList2(
                Keyword.VAR, [AstFactory.variableDeclaration("i")]),
            AstFactory.identifier3("c"),
            [AstFactory.identifier3("u")],
            AstFactory.block()));
  }

  void test_visitForStatement_iu() {
    _assertSource(
        "for (var i;; u) {}",
        AstFactory.forStatement2(
            AstFactory.variableDeclarationList2(
                Keyword.VAR, [AstFactory.variableDeclaration("i")]),
            null,
            [AstFactory.identifier3("u")],
            AstFactory.block()));
  }

  void test_visitForStatement_u() {
    _assertSource(
        "for (;; u) {}",
        AstFactory.forStatement(
            null, null, [AstFactory.identifier3("u")], AstFactory.block()));
  }

  void test_visitFunctionDeclaration_external() {
    FunctionDeclaration functionDeclaration = AstFactory.functionDeclaration(
        null,
        null,
        "f",
        AstFactory.functionExpression2(
            AstFactory.formalParameterList(), AstFactory.emptyFunctionBody()));
    functionDeclaration.externalKeyword =
        TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);
    _assertSource("external f();", functionDeclaration);
  }

  void test_visitFunctionDeclaration_getter() {
    _assertSource(
        "get f() {}",
        AstFactory.functionDeclaration(
            null, Keyword.GET, "f", AstFactory.functionExpression()));
  }

  void test_visitFunctionDeclaration_local_blockBody() {
    FunctionDeclaration f = AstFactory.functionDeclaration(
        null, null, "f", AstFactory.functionExpression());
    FunctionDeclarationStatement fStatement =
        new FunctionDeclarationStatement(f);
    _assertSource(
        "main() {f() {} 42;}",
        AstFactory.functionDeclaration(
            null,
            null,
            "main",
            AstFactory.functionExpression2(
                AstFactory.formalParameterList(),
                AstFactory.blockFunctionBody2([
                  fStatement,
                  AstFactory.expressionStatement(AstFactory.integer(42))
                ]))));
  }

  void test_visitFunctionDeclaration_local_expressionBody() {
    FunctionDeclaration f = AstFactory.functionDeclaration(
        null,
        null,
        "f",
        AstFactory.functionExpression2(AstFactory.formalParameterList(),
            AstFactory.expressionFunctionBody(AstFactory.integer(1))));
    FunctionDeclarationStatement fStatement =
        new FunctionDeclarationStatement(f);
    _assertSource(
        "main() {f() => 1; 2;}",
        AstFactory.functionDeclaration(
            null,
            null,
            "main",
            AstFactory.functionExpression2(
                AstFactory.formalParameterList(),
                AstFactory.blockFunctionBody2([
                  fStatement,
                  AstFactory.expressionStatement(AstFactory.integer(2))
                ]))));
  }

  void test_visitFunctionDeclaration_normal() {
    _assertSource(
        "f() {}",
        AstFactory.functionDeclaration(
            null, null, "f", AstFactory.functionExpression()));
  }

  void test_visitFunctionDeclaration_setter() {
    _assertSource(
        "set f() {}",
        AstFactory.functionDeclaration(
            null, Keyword.SET, "f", AstFactory.functionExpression()));
  }

  void test_visitFunctionDeclaration_typeParameters() {
    _assertSource(
        "f<E>() {}",
        AstFactory.functionDeclaration(
            null,
            null,
            "f",
            AstFactory.functionExpression3(
                AstFactory.typeParameterList(['E']),
                AstFactory.formalParameterList(),
                AstFactory.blockFunctionBody2())));
  }

  void test_visitFunctionDeclaration_withMetadata() {
    FunctionDeclaration declaration = AstFactory.functionDeclaration(
        null, null, "f", AstFactory.functionExpression());
    declaration.metadata
        .add(AstFactory.annotation(AstFactory.identifier3("deprecated")));
    _assertSource("@deprecated f() {}", declaration);
  }

  void test_visitFunctionDeclarationStatement() {
    _assertSource(
        "f() {}",
        AstFactory.functionDeclarationStatement(
            null, null, "f", AstFactory.functionExpression()));
  }

  void test_visitFunctionExpression() {
    _assertSource("() {}", AstFactory.functionExpression());
  }

  void test_visitFunctionExpression_typeParameters() {
    _assertSource(
        "<E>() {}",
        AstFactory.functionExpression3(AstFactory.typeParameterList(['E']),
            AstFactory.formalParameterList(), AstFactory.blockFunctionBody2()));
  }

  void test_visitFunctionExpressionInvocation_minimal() {
    _assertSource("f()",
        AstFactory.functionExpressionInvocation(AstFactory.identifier3("f")));
  }

  void test_visitFunctionExpressionInvocation_typeArguments() {
    _assertSource(
        "f<A>()",
        AstFactory.functionExpressionInvocation2(AstFactory.identifier3("f"),
            AstFactory.typeArgumentList([AstFactory.typeName4('A')])));
  }

  void test_visitFunctionTypeAlias_generic() {
    _assertSource(
        "typedef A F<B>();",
        AstFactory.typeAlias(
            AstFactory.typeName4("A"),
            "F",
            AstFactory.typeParameterList(["B"]),
            AstFactory.formalParameterList()));
  }

  void test_visitFunctionTypeAlias_nonGeneric() {
    _assertSource(
        "typedef A F();",
        AstFactory.typeAlias(AstFactory.typeName4("A"), "F", null,
            AstFactory.formalParameterList()));
  }

  void test_visitFunctionTypeAlias_withMetadata() {
    FunctionTypeAlias declaration = AstFactory.typeAlias(
        AstFactory.typeName4("A"), "F", null, AstFactory.formalParameterList());
    declaration.metadata
        .add(AstFactory.annotation(AstFactory.identifier3("deprecated")));
    _assertSource("@deprecated typedef A F();", declaration);
  }

  void test_visitFunctionTypedFormalParameter_annotation() {
    FunctionTypedFormalParameter parameter =
        AstFactory.functionTypedFormalParameter(null, "f");
    parameter.metadata.add(AstFactory.annotation(AstFactory.identifier3("A")));
    _assertSource('@A f()', parameter);
  }

  void test_visitFunctionTypedFormalParameter_noType() {
    _assertSource("f()", AstFactory.functionTypedFormalParameter(null, "f"));
  }

  void test_visitFunctionTypedFormalParameter_type() {
    _assertSource(
        "T f()",
        AstFactory.functionTypedFormalParameter(
            AstFactory.typeName4("T"), "f"));
  }

  void test_visitFunctionTypedFormalParameter_typeParameters() {
    _assertSource(
        "T f<E>()",
        new FunctionTypedFormalParameter(
            null,
            null,
            AstFactory.typeName4("T"),
            AstFactory.identifier3('f'),
            AstFactory.typeParameterList(['E']),
            AstFactory.formalParameterList([])));
  }

  void test_visitIfStatement_withElse() {
    _assertSource(
        "if (c) {} else {}",
        AstFactory.ifStatement2(AstFactory.identifier3("c"), AstFactory.block(),
            AstFactory.block()));
  }

  void test_visitIfStatement_withoutElse() {
    _assertSource(
        "if (c) {}",
        AstFactory.ifStatement(
            AstFactory.identifier3("c"), AstFactory.block()));
  }

  void test_visitImplementsClause_multiple() {
    _assertSource(
        "implements A, B",
        AstFactory.implementsClause(
            [AstFactory.typeName4("A"), AstFactory.typeName4("B")]));
  }

  void test_visitImplementsClause_single() {
    _assertSource("implements A",
        AstFactory.implementsClause([AstFactory.typeName4("A")]));
  }

  void test_visitImportDirective_combinator() {
    _assertSource(
        "import 'a.dart' show A;",
        AstFactory.importDirective3("a.dart", null, [
          AstFactory.showCombinator([AstFactory.identifier3("A")])
        ]));
  }

  void test_visitImportDirective_combinators() {
    _assertSource(
        "import 'a.dart' show A hide B;",
        AstFactory.importDirective3("a.dart", null, [
          AstFactory.showCombinator([AstFactory.identifier3("A")]),
          AstFactory.hideCombinator([AstFactory.identifier3("B")])
        ]));
  }

  void test_visitImportDirective_deferred() {
    _assertSource("import 'a.dart' deferred as p;",
        AstFactory.importDirective2("a.dart", true, "p"));
  }

  void test_visitImportDirective_minimal() {
    _assertSource(
        "import 'a.dart';", AstFactory.importDirective3("a.dart", null));
  }

  void test_visitImportDirective_prefix() {
    _assertSource(
        "import 'a.dart' as p;", AstFactory.importDirective3("a.dart", "p"));
  }

  void test_visitImportDirective_prefix_combinator() {
    _assertSource(
        "import 'a.dart' as p show A;",
        AstFactory.importDirective3("a.dart", "p", [
          AstFactory.showCombinator([AstFactory.identifier3("A")])
        ]));
  }

  void test_visitImportDirective_prefix_combinators() {
    _assertSource(
        "import 'a.dart' as p show A hide B;",
        AstFactory.importDirective3("a.dart", "p", [
          AstFactory.showCombinator([AstFactory.identifier3("A")]),
          AstFactory.hideCombinator([AstFactory.identifier3("B")])
        ]));
  }

  void test_visitImportDirective_withMetadata() {
    ImportDirective directive = AstFactory.importDirective3("a.dart", null);
    directive.metadata
        .add(AstFactory.annotation(AstFactory.identifier3("deprecated")));
    _assertSource("@deprecated import 'a.dart';", directive);
  }

  void test_visitImportHideCombinator_multiple() {
    _assertSource(
        "hide a, b",
        AstFactory.hideCombinator(
            [AstFactory.identifier3("a"), AstFactory.identifier3("b")]));
  }

  void test_visitImportHideCombinator_single() {
    _assertSource(
        "hide a", AstFactory.hideCombinator([AstFactory.identifier3("a")]));
  }

  void test_visitImportShowCombinator_multiple() {
    _assertSource(
        "show a, b",
        AstFactory.showCombinator(
            [AstFactory.identifier3("a"), AstFactory.identifier3("b")]));
  }

  void test_visitImportShowCombinator_single() {
    _assertSource(
        "show a", AstFactory.showCombinator([AstFactory.identifier3("a")]));
  }

  void test_visitIndexExpression() {
    _assertSource(
        "a[i]",
        AstFactory.indexExpression(
            AstFactory.identifier3("a"), AstFactory.identifier3("i")));
  }

  void test_visitInstanceCreationExpression_const() {
    _assertSource(
        "const C()",
        AstFactory.instanceCreationExpression2(
            Keyword.CONST, AstFactory.typeName4("C")));
  }

  void test_visitInstanceCreationExpression_named() {
    _assertSource(
        "new C.c()",
        AstFactory.instanceCreationExpression3(
            Keyword.NEW, AstFactory.typeName4("C"), "c"));
  }

  void test_visitInstanceCreationExpression_unnamed() {
    _assertSource(
        "new C()",
        AstFactory.instanceCreationExpression2(
            Keyword.NEW, AstFactory.typeName4("C")));
  }

  void test_visitIntegerLiteral() {
    _assertSource("42", AstFactory.integer(42));
  }

  void test_visitInterpolationExpression_expression() {
    _assertSource("\${a}",
        AstFactory.interpolationExpression(AstFactory.identifier3("a")));
  }

  void test_visitInterpolationExpression_identifier() {
    _assertSource("\$a", AstFactory.interpolationExpression2("a"));
  }

  void test_visitInterpolationString() {
    _assertSource("'x", AstFactory.interpolationString("'x", "x"));
  }

  void test_visitIsExpression_negated() {
    _assertSource(
        "a is! C",
        AstFactory.isExpression(
            AstFactory.identifier3("a"), true, AstFactory.typeName4("C")));
  }

  void test_visitIsExpression_normal() {
    _assertSource(
        "a is C",
        AstFactory.isExpression(
            AstFactory.identifier3("a"), false, AstFactory.typeName4("C")));
  }

  void test_visitLabel() {
    _assertSource("a:", AstFactory.label2("a"));
  }

  void test_visitLabeledStatement_multiple() {
    _assertSource(
        "a: b: return;",
        AstFactory.labeledStatement(
            [AstFactory.label2("a"), AstFactory.label2("b")],
            AstFactory.returnStatement()));
  }

  void test_visitLabeledStatement_single() {
    _assertSource(
        "a: return;",
        AstFactory.labeledStatement(
            [AstFactory.label2("a")], AstFactory.returnStatement()));
  }

  void test_visitLibraryDirective() {
    _assertSource("library l;", AstFactory.libraryDirective2("l"));
  }

  void test_visitLibraryDirective_withMetadata() {
    LibraryDirective directive = AstFactory.libraryDirective2("l");
    directive.metadata
        .add(AstFactory.annotation(AstFactory.identifier3("deprecated")));
    _assertSource("@deprecated library l;", directive);
  }

  void test_visitLibraryIdentifier_multiple() {
    _assertSource(
        "a.b.c",
        AstFactory.libraryIdentifier([
          AstFactory.identifier3("a"),
          AstFactory.identifier3("b"),
          AstFactory.identifier3("c")
        ]));
  }

  void test_visitLibraryIdentifier_single() {
    _assertSource(
        "a", AstFactory.libraryIdentifier([AstFactory.identifier3("a")]));
  }

  void test_visitListLiteral_const() {
    _assertSource("const []", AstFactory.listLiteral2(Keyword.CONST, null));
  }

  void test_visitListLiteral_empty() {
    _assertSource("[]", AstFactory.listLiteral());
  }

  void test_visitListLiteral_nonEmpty() {
    _assertSource(
        "[a, b, c]",
        AstFactory.listLiteral([
          AstFactory.identifier3("a"),
          AstFactory.identifier3("b"),
          AstFactory.identifier3("c")
        ]));
  }

  void test_visitMapLiteral_const() {
    _assertSource("const {}", AstFactory.mapLiteral(Keyword.CONST, null));
  }

  void test_visitMapLiteral_empty() {
    _assertSource("{}", AstFactory.mapLiteral2());
  }

  void test_visitMapLiteral_nonEmpty() {
    _assertSource(
        "{'a' : a, 'b' : b, 'c' : c}",
        AstFactory.mapLiteral2([
          AstFactory.mapLiteralEntry("a", AstFactory.identifier3("a")),
          AstFactory.mapLiteralEntry("b", AstFactory.identifier3("b")),
          AstFactory.mapLiteralEntry("c", AstFactory.identifier3("c"))
        ]));
  }

  void test_visitMapLiteralEntry() {
    _assertSource("'a' : b",
        AstFactory.mapLiteralEntry("a", AstFactory.identifier3("b")));
  }

  void test_visitMethodDeclaration_external() {
    _assertSource(
        "external m();",
        AstFactory.methodDeclaration(null, null, null, null,
            AstFactory.identifier3("m"), AstFactory.formalParameterList()));
  }

  void test_visitMethodDeclaration_external_returnType() {
    _assertSource(
        "external T m();",
        AstFactory.methodDeclaration(
            null,
            AstFactory.typeName4("T"),
            null,
            null,
            AstFactory.identifier3("m"),
            AstFactory.formalParameterList()));
  }

  void test_visitMethodDeclaration_getter() {
    _assertSource(
        "get m {}",
        AstFactory.methodDeclaration2(
            null,
            null,
            Keyword.GET,
            null,
            AstFactory.identifier3("m"),
            null,
            AstFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_getter_returnType() {
    _assertSource(
        "T get m {}",
        AstFactory.methodDeclaration2(
            null,
            AstFactory.typeName4("T"),
            Keyword.GET,
            null,
            AstFactory.identifier3("m"),
            null,
            AstFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_getter_seturnType() {
    _assertSource(
        "T set m(var v) {}",
        AstFactory.methodDeclaration2(
            null,
            AstFactory.typeName4("T"),
            Keyword.SET,
            null,
            AstFactory.identifier3("m"),
            AstFactory.formalParameterList(
                [AstFactory.simpleFormalParameter(Keyword.VAR, "v")]),
            AstFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_minimal() {
    _assertSource(
        "m() {}",
        AstFactory.methodDeclaration2(
            null,
            null,
            null,
            null,
            AstFactory.identifier3("m"),
            AstFactory.formalParameterList(),
            AstFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_multipleParameters() {
    _assertSource(
        "m(var a, var b) {}",
        AstFactory.methodDeclaration2(
            null,
            null,
            null,
            null,
            AstFactory.identifier3("m"),
            AstFactory.formalParameterList([
              AstFactory.simpleFormalParameter(Keyword.VAR, "a"),
              AstFactory.simpleFormalParameter(Keyword.VAR, "b")
            ]),
            AstFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_operator() {
    _assertSource(
        "operator +() {}",
        AstFactory.methodDeclaration2(
            null,
            null,
            null,
            Keyword.OPERATOR,
            AstFactory.identifier3("+"),
            AstFactory.formalParameterList(),
            AstFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_operator_returnType() {
    _assertSource(
        "T operator +() {}",
        AstFactory.methodDeclaration2(
            null,
            AstFactory.typeName4("T"),
            null,
            Keyword.OPERATOR,
            AstFactory.identifier3("+"),
            AstFactory.formalParameterList(),
            AstFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_returnType() {
    _assertSource(
        "T m() {}",
        AstFactory.methodDeclaration2(
            null,
            AstFactory.typeName4("T"),
            null,
            null,
            AstFactory.identifier3("m"),
            AstFactory.formalParameterList(),
            AstFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_setter() {
    _assertSource(
        "set m(var v) {}",
        AstFactory.methodDeclaration2(
            null,
            null,
            Keyword.SET,
            null,
            AstFactory.identifier3("m"),
            AstFactory.formalParameterList(
                [AstFactory.simpleFormalParameter(Keyword.VAR, "v")]),
            AstFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_static() {
    _assertSource(
        "static m() {}",
        AstFactory.methodDeclaration2(
            Keyword.STATIC,
            null,
            null,
            null,
            AstFactory.identifier3("m"),
            AstFactory.formalParameterList(),
            AstFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_static_returnType() {
    _assertSource(
        "static T m() {}",
        AstFactory.methodDeclaration2(
            Keyword.STATIC,
            AstFactory.typeName4("T"),
            null,
            null,
            AstFactory.identifier3("m"),
            AstFactory.formalParameterList(),
            AstFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_typeParameters() {
    _assertSource(
        "m<E>() {}",
        AstFactory.methodDeclaration3(
            null,
            null,
            null,
            null,
            AstFactory.identifier3("m"),
            AstFactory.typeParameterList(['E']),
            AstFactory.formalParameterList(),
            AstFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_withMetadata() {
    MethodDeclaration declaration = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3("m"),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2());
    declaration.metadata
        .add(AstFactory.annotation(AstFactory.identifier3("deprecated")));
    _assertSource("@deprecated m() {}", declaration);
  }

  void test_visitMethodInvocation_conditional() {
    _assertSource(
        "t?.m()",
        AstFactory.methodInvocation(
            AstFactory.identifier3("t"), "m", null, TokenType.QUESTION_PERIOD));
  }

  void test_visitMethodInvocation_noTarget() {
    _assertSource("m()", AstFactory.methodInvocation2("m"));
  }

  void test_visitMethodInvocation_target() {
    _assertSource(
        "t.m()", AstFactory.methodInvocation(AstFactory.identifier3("t"), "m"));
  }

  void test_visitMethodInvocation_typeArguments() {
    _assertSource(
        "m<A>()",
        AstFactory.methodInvocation3(null, "m",
            AstFactory.typeArgumentList([AstFactory.typeName4('A')])));
  }

  void test_visitNamedExpression() {
    _assertSource(
        "a: b", AstFactory.namedExpression2("a", AstFactory.identifier3("b")));
  }

  void test_visitNamedFormalParameter() {
    _assertSource(
        "var a : 0",
        AstFactory.namedFormalParameter(
            AstFactory.simpleFormalParameter(Keyword.VAR, "a"),
            AstFactory.integer(0)));
  }

  void test_visitNativeClause() {
    _assertSource("native 'code'", AstFactory.nativeClause("code"));
  }

  void test_visitNativeFunctionBody() {
    _assertSource("native 'str';", AstFactory.nativeFunctionBody("str"));
  }

  void test_visitNullLiteral() {
    _assertSource("null", AstFactory.nullLiteral());
  }

  void test_visitParenthesizedExpression() {
    _assertSource(
        "(a)", AstFactory.parenthesizedExpression(AstFactory.identifier3("a")));
  }

  void test_visitPartDirective() {
    _assertSource("part 'a.dart';", AstFactory.partDirective2("a.dart"));
  }

  void test_visitPartDirective_withMetadata() {
    PartDirective directive = AstFactory.partDirective2("a.dart");
    directive.metadata
        .add(AstFactory.annotation(AstFactory.identifier3("deprecated")));
    _assertSource("@deprecated part 'a.dart';", directive);
  }

  void test_visitPartOfDirective() {
    _assertSource("part of l;",
        AstFactory.partOfDirective(AstFactory.libraryIdentifier2(["l"])));
  }

  void test_visitPartOfDirective_withMetadata() {
    PartOfDirective directive =
        AstFactory.partOfDirective(AstFactory.libraryIdentifier2(["l"]));
    directive.metadata
        .add(AstFactory.annotation(AstFactory.identifier3("deprecated")));
    _assertSource("@deprecated part of l;", directive);
  }

  void test_visitPositionalFormalParameter() {
    _assertSource(
        "var a = 0",
        AstFactory.positionalFormalParameter(
            AstFactory.simpleFormalParameter(Keyword.VAR, "a"),
            AstFactory.integer(0)));
  }

  void test_visitPostfixExpression() {
    _assertSource(
        "a++",
        AstFactory.postfixExpression(
            AstFactory.identifier3("a"), TokenType.PLUS_PLUS));
  }

  void test_visitPrefixedIdentifier() {
    _assertSource("a.b", AstFactory.identifier5("a", "b"));
  }

  void test_visitPrefixExpression() {
    _assertSource(
        "-a",
        AstFactory.prefixExpression(
            TokenType.MINUS, AstFactory.identifier3("a")));
  }

  void test_visitPropertyAccess() {
    _assertSource(
        "a.b", AstFactory.propertyAccess2(AstFactory.identifier3("a"), "b"));
  }

  void test_visitPropertyAccess_conditional() {
    _assertSource(
        "a?.b",
        AstFactory.propertyAccess2(
            AstFactory.identifier3("a"), "b", TokenType.QUESTION_PERIOD));
  }

  void test_visitRedirectingConstructorInvocation_named() {
    _assertSource(
        "this.c()", AstFactory.redirectingConstructorInvocation2("c"));
  }

  void test_visitRedirectingConstructorInvocation_unnamed() {
    _assertSource("this()", AstFactory.redirectingConstructorInvocation());
  }

  void test_visitRethrowExpression() {
    _assertSource("rethrow", AstFactory.rethrowExpression());
  }

  void test_visitReturnStatement_expression() {
    _assertSource(
        "return a;", AstFactory.returnStatement2(AstFactory.identifier3("a")));
  }

  void test_visitReturnStatement_noExpression() {
    _assertSource("return;", AstFactory.returnStatement());
  }

  void test_visitScriptTag() {
    String scriptTag = "!#/bin/dart.exe";
    _assertSource(scriptTag, AstFactory.scriptTag(scriptTag));
  }

  void test_visitSimpleFormalParameter_annotation() {
    SimpleFormalParameter parameter = AstFactory.simpleFormalParameter3('x');
    parameter.metadata.add(AstFactory.annotation(AstFactory.identifier3("A")));
    _assertSource('@A x', parameter);
  }

  void test_visitSimpleFormalParameter_keyword() {
    _assertSource("var a", AstFactory.simpleFormalParameter(Keyword.VAR, "a"));
  }

  void test_visitSimpleFormalParameter_keyword_type() {
    _assertSource(
        "final A a",
        AstFactory.simpleFormalParameter2(
            Keyword.FINAL, AstFactory.typeName4("A"), "a"));
  }

  void test_visitSimpleFormalParameter_type() {
    _assertSource("A a",
        AstFactory.simpleFormalParameter4(AstFactory.typeName4("A"), "a"));
  }

  void test_visitSimpleIdentifier() {
    _assertSource("a", AstFactory.identifier3("a"));
  }

  void test_visitSimpleStringLiteral() {
    _assertSource("'a'", AstFactory.string2("a"));
  }

  void test_visitStringInterpolation() {
    _assertSource(
        "'a\${e}b'",
        AstFactory.string([
          AstFactory.interpolationString("'a", "a"),
          AstFactory.interpolationExpression(AstFactory.identifier3("e")),
          AstFactory.interpolationString("b'", "b")
        ]));
  }

  void test_visitSuperConstructorInvocation() {
    _assertSource("super()", AstFactory.superConstructorInvocation());
  }

  void test_visitSuperConstructorInvocation_named() {
    _assertSource("super.c()", AstFactory.superConstructorInvocation2("c"));
  }

  void test_visitSuperExpression() {
    _assertSource("super", AstFactory.superExpression());
  }

  void test_visitSwitchCase_multipleLabels() {
    _assertSource(
        "l1: l2: case a: {}",
        AstFactory.switchCase2(
            [AstFactory.label2("l1"), AstFactory.label2("l2")],
            AstFactory.identifier3("a"),
            [AstFactory.block()]));
  }

  void test_visitSwitchCase_multipleStatements() {
    _assertSource(
        "case a: {} {}",
        AstFactory.switchCase(AstFactory.identifier3("a"),
            [AstFactory.block(), AstFactory.block()]));
  }

  void test_visitSwitchCase_noLabels() {
    _assertSource(
        "case a: {}",
        AstFactory
            .switchCase(AstFactory.identifier3("a"), [AstFactory.block()]));
  }

  void test_visitSwitchCase_singleLabel() {
    _assertSource(
        "l1: case a: {}",
        AstFactory.switchCase2([AstFactory.label2("l1")],
            AstFactory.identifier3("a"), [AstFactory.block()]));
  }

  void test_visitSwitchDefault_multipleLabels() {
    _assertSource(
        "l1: l2: default: {}",
        AstFactory.switchDefault(
            [AstFactory.label2("l1"), AstFactory.label2("l2")],
            [AstFactory.block()]));
  }

  void test_visitSwitchDefault_multipleStatements() {
    _assertSource("default: {} {}",
        AstFactory.switchDefault2([AstFactory.block(), AstFactory.block()]));
  }

  void test_visitSwitchDefault_noLabels() {
    _assertSource(
        "default: {}", AstFactory.switchDefault2([AstFactory.block()]));
  }

  void test_visitSwitchDefault_singleLabel() {
    _assertSource(
        "l1: default: {}",
        AstFactory
            .switchDefault([AstFactory.label2("l1")], [AstFactory.block()]));
  }

  void test_visitSwitchStatement() {
    _assertSource(
        "switch (a) {case 'b': {} default: {}}",
        AstFactory.switchStatement(AstFactory.identifier3("a"), [
          AstFactory.switchCase(AstFactory.string2("b"), [AstFactory.block()]),
          AstFactory.switchDefault2([AstFactory.block()])
        ]));
  }

  void test_visitSymbolLiteral_multiple() {
    _assertSource("#a.b.c", AstFactory.symbolLiteral(["a", "b", "c"]));
  }

  void test_visitSymbolLiteral_single() {
    _assertSource("#a", AstFactory.symbolLiteral(["a"]));
  }

  void test_visitThisExpression() {
    _assertSource("this", AstFactory.thisExpression());
  }

  void test_visitThrowStatement() {
    _assertSource(
        "throw e", AstFactory.throwExpression2(AstFactory.identifier3("e")));
  }

  void test_visitTopLevelVariableDeclaration_multiple() {
    _assertSource(
        "var a;",
        AstFactory.topLevelVariableDeclaration2(
            Keyword.VAR, [AstFactory.variableDeclaration("a")]));
  }

  void test_visitTopLevelVariableDeclaration_single() {
    _assertSource(
        "var a, b;",
        AstFactory.topLevelVariableDeclaration2(Keyword.VAR, [
          AstFactory.variableDeclaration("a"),
          AstFactory.variableDeclaration("b")
        ]));
  }

  void test_visitTryStatement_catch() {
    _assertSource(
        "try {} on E {}",
        AstFactory.tryStatement2(AstFactory.block(),
            [AstFactory.catchClause3(AstFactory.typeName4("E"))]));
  }

  void test_visitTryStatement_catches() {
    _assertSource(
        "try {} on E {} on F {}",
        AstFactory.tryStatement2(AstFactory.block(), [
          AstFactory.catchClause3(AstFactory.typeName4("E")),
          AstFactory.catchClause3(AstFactory.typeName4("F"))
        ]));
  }

  void test_visitTryStatement_catchFinally() {
    _assertSource(
        "try {} on E {} finally {}",
        AstFactory.tryStatement3(
            AstFactory.block(),
            [AstFactory.catchClause3(AstFactory.typeName4("E"))],
            AstFactory.block()));
  }

  void test_visitTryStatement_finally() {
    _assertSource("try {} finally {}",
        AstFactory.tryStatement(AstFactory.block(), AstFactory.block()));
  }

  void test_visitTypeArgumentList_multiple() {
    _assertSource(
        "<E, F>",
        AstFactory.typeArgumentList(
            [AstFactory.typeName4("E"), AstFactory.typeName4("F")]));
  }

  void test_visitTypeArgumentList_single() {
    _assertSource(
        "<E>", AstFactory.typeArgumentList([AstFactory.typeName4("E")]));
  }

  void test_visitTypeName_multipleArgs() {
    _assertSource(
        "C<D, E>",
        AstFactory.typeName4(
            "C", [AstFactory.typeName4("D"), AstFactory.typeName4("E")]));
  }

  void test_visitTypeName_nestedArg() {
    _assertSource(
        "C<D<E>>",
        AstFactory.typeName4("C", [
          AstFactory.typeName4("D", [AstFactory.typeName4("E")])
        ]));
  }

  void test_visitTypeName_noArgs() {
    _assertSource("C", AstFactory.typeName4("C"));
  }

  void test_visitTypeName_singleArg() {
    _assertSource(
        "C<D>", AstFactory.typeName4("C", [AstFactory.typeName4("D")]));
  }

  void test_visitTypeParameter_withExtends() {
    _assertSource("E extends C",
        AstFactory.typeParameter2("E", AstFactory.typeName4("C")));
  }

  void test_visitTypeParameter_withMetadata() {
    TypeParameter parameter = AstFactory.typeParameter("E");
    parameter.metadata
        .add(AstFactory.annotation(AstFactory.identifier3("deprecated")));
    _assertSource("@deprecated E", parameter);
  }

  void test_visitTypeParameter_withoutExtends() {
    _assertSource("E", AstFactory.typeParameter("E"));
  }

  void test_visitTypeParameterList_multiple() {
    _assertSource("<E, F>", AstFactory.typeParameterList(["E", "F"]));
  }

  void test_visitTypeParameterList_single() {
    _assertSource("<E>", AstFactory.typeParameterList(["E"]));
  }

  void test_visitVariableDeclaration_initialized() {
    _assertSource("a = b",
        AstFactory.variableDeclaration2("a", AstFactory.identifier3("b")));
  }

  void test_visitVariableDeclaration_uninitialized() {
    _assertSource("a", AstFactory.variableDeclaration("a"));
  }

  void test_visitVariableDeclaration_withMetadata() {
    VariableDeclaration declaration = AstFactory.variableDeclaration("a");
    declaration.metadata
        .add(AstFactory.annotation(AstFactory.identifier3("deprecated")));
    _assertSource("@deprecated a", declaration);
  }

  void test_visitVariableDeclarationList_const_type() {
    _assertSource(
        "const C a, b",
        AstFactory.variableDeclarationList(
            Keyword.CONST, AstFactory.typeName4("C"), [
          AstFactory.variableDeclaration("a"),
          AstFactory.variableDeclaration("b")
        ]));
  }

  void test_visitVariableDeclarationList_final_noType() {
    _assertSource(
        "final a, b",
        AstFactory.variableDeclarationList2(Keyword.FINAL, [
          AstFactory.variableDeclaration("a"),
          AstFactory.variableDeclaration("b")
        ]));
  }

  void test_visitVariableDeclarationList_final_withMetadata() {
    VariableDeclarationList declarationList = AstFactory
        .variableDeclarationList2(Keyword.FINAL, [
      AstFactory.variableDeclaration("a"),
      AstFactory.variableDeclaration("b")
    ]);
    declarationList.metadata
        .add(AstFactory.annotation(AstFactory.identifier3("deprecated")));
    _assertSource("@deprecated final a, b", declarationList);
  }

  void test_visitVariableDeclarationList_type() {
    _assertSource(
        "C a, b",
        AstFactory.variableDeclarationList(null, AstFactory.typeName4("C"), [
          AstFactory.variableDeclaration("a"),
          AstFactory.variableDeclaration("b")
        ]));
  }

  void test_visitVariableDeclarationList_var() {
    _assertSource(
        "var a, b",
        AstFactory.variableDeclarationList2(Keyword.VAR, [
          AstFactory.variableDeclaration("a"),
          AstFactory.variableDeclaration("b")
        ]));
  }

  void test_visitVariableDeclarationStatement() {
    _assertSource(
        "C c;",
        AstFactory.variableDeclarationStatement(null, AstFactory.typeName4("C"),
            [AstFactory.variableDeclaration("c")]));
  }

  void test_visitWhileStatement() {
    _assertSource(
        "while (c) {}",
        AstFactory.whileStatement(
            AstFactory.identifier3("c"), AstFactory.block()));
  }

  void test_visitWithClause_multiple() {
    _assertSource(
        "with A, B, C",
        AstFactory.withClause([
          AstFactory.typeName4("A"),
          AstFactory.typeName4("B"),
          AstFactory.typeName4("C")
        ]));
  }

  void test_visitWithClause_single() {
    _assertSource("with A", AstFactory.withClause([AstFactory.typeName4("A")]));
  }

  void test_visitYieldStatement() {
    _assertSource(
        "yield e;", AstFactory.yieldStatement(AstFactory.identifier3("e")));
  }

  void test_visitYieldStatement_each() {
    _assertSource("yield* e;",
        AstFactory.yieldEachStatement(AstFactory.identifier3("e")));
  }

  /**
   * Assert that a `ToSourceVisitor` will produce the expected source when visiting the given
   * node.
   *
   * @param expectedSource the source string that the visitor is expected to produce
   * @param node the AST node being visited to produce the actual source
   * @throws AFE if the visitor does not produce the expected source for the given node
   */
  void _assertSource(String expectedSource, AstNode node) {
    PrintStringWriter writer = new PrintStringWriter();
    node.accept(new ToSourceVisitor(writer));
    expect(writer.toString(), expectedSource);
  }
}
