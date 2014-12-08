// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.utilities_test;

import 'dart:collection';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/generated/utilities_collection.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import 'test_support.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(AstClonerTest);
  runReflectiveTests(NodeReplacerTest);
  runReflectiveTests(LineInfoTest);
  runReflectiveTests(SourceRangeTest);
  runReflectiveTests(BooleanArrayTest);
  runReflectiveTests(DirectedGraphTest);
  runReflectiveTests(ListUtilitiesTest);
  runReflectiveTests(MultipleMapIteratorTest);
  runReflectiveTests(SingleMapIteratorTest);
  runReflectiveTests(TokenMapTest);
  runReflectiveTests(StringUtilitiesTest);
}

class AstCloneComparator extends AstComparator {
  final bool expectTokensCopied;

  AstCloneComparator(this.expectTokensCopied);

  @override
  bool isEqualNodes(AstNode first, AstNode second) {
    if (first != null && identical(first, second)) {
      fail('Failed to copy node: $first (${first.offset})');
      return false;
    }
    return super.isEqualNodes(first, second);
  }

  @override
  bool isEqualTokens(Token first, Token second) {
    if (expectTokensCopied && first != null && identical(first, second)) {
      fail('Failed to copy token: ${first.lexeme} (${first.offset})');
      return false;
    }
    return super.isEqualTokens(first, second);
  }
}

@ReflectiveTestCase()
class AstClonerTest extends EngineTestCase {
  void test_visitAdjacentStrings() {
    _assertClone(
        AstFactory.adjacentStrings([AstFactory.string2("a"), AstFactory.string2("b")]));
  }

  void test_visitAnnotation_constant() {
    _assertClone(AstFactory.annotation(AstFactory.identifier3("A")));
  }

  void test_visitAnnotation_constructor() {
    _assertClone(
        AstFactory.annotation2(
            AstFactory.identifier3("A"),
            AstFactory.identifier3("c"),
            AstFactory.argumentList()));
  }

  void test_visitArgumentList() {
    _assertClone(
        AstFactory.argumentList(
            [AstFactory.identifier3("a"), AstFactory.identifier3("b")]));
  }

  void test_visitAsExpression() {
    _assertClone(
        AstFactory.asExpression(
            AstFactory.identifier3("e"),
            AstFactory.typeName4("T")));
  }

  void test_visitAssertStatement() {
    _assertClone(AstFactory.assertStatement(AstFactory.identifier3("a")));
  }

  void test_visitAssignmentExpression() {
    _assertClone(
        AstFactory.assignmentExpression(
            AstFactory.identifier3("a"),
            TokenType.EQ,
            AstFactory.identifier3("b")));
  }

  void test_visitAwaitExpression() {
    _assertClone(AstFactory.awaitExpression(AstFactory.identifier3("a")));
  }

  void test_visitBinaryExpression() {
    _assertClone(
        AstFactory.binaryExpression(
            AstFactory.identifier3("a"),
            TokenType.PLUS,
            AstFactory.identifier3("b")));
  }

  void test_visitBlock_empty() {
    _assertClone(AstFactory.block());
  }

  void test_visitBlock_nonEmpty() {
    _assertClone(
        AstFactory.block([AstFactory.breakStatement(), AstFactory.breakStatement()]));
  }

  void test_visitBlockFunctionBody() {
    _assertClone(AstFactory.blockFunctionBody2());
  }

  void test_visitBooleanLiteral_false() {
    _assertClone(AstFactory.booleanLiteral(false));
  }

  void test_visitBooleanLiteral_true() {
    _assertClone(AstFactory.booleanLiteral(true));
  }

  void test_visitBreakStatement_label() {
    _assertClone(AstFactory.breakStatement2("l"));
  }

  void test_visitBreakStatement_noLabel() {
    _assertClone(AstFactory.breakStatement());
  }

  void test_visitCascadeExpression_field() {
    _assertClone(
        AstFactory.cascadeExpression(
            AstFactory.identifier3("a"),
            [
                AstFactory.cascadedPropertyAccess("b"),
                AstFactory.cascadedPropertyAccess("c")]));
  }

  void test_visitCascadeExpression_index() {
    _assertClone(
        AstFactory.cascadeExpression(
            AstFactory.identifier3("a"),
            [
                AstFactory.cascadedIndexExpression(AstFactory.integer(0)),
                AstFactory.cascadedIndexExpression(AstFactory.integer(1))]));
  }

  void test_visitCascadeExpression_method() {
    _assertClone(
        AstFactory.cascadeExpression(
            AstFactory.identifier3("a"),
            [
                AstFactory.cascadedMethodInvocation("b"),
                AstFactory.cascadedMethodInvocation("c")]));
  }

  void test_visitCatchClause_catch_noStack() {
    _assertClone(AstFactory.catchClause("e"));
  }

  void test_visitCatchClause_catch_stack() {
    _assertClone(AstFactory.catchClause2("e", "s"));
  }

  void test_visitCatchClause_on() {
    _assertClone(AstFactory.catchClause3(AstFactory.typeName4("E")));
  }

  void test_visitCatchClause_on_catch() {
    _assertClone(AstFactory.catchClause4(AstFactory.typeName4("E"), "e"));
  }

  void test_visitClassDeclaration_abstract() {
    _assertClone(
        AstFactory.classDeclaration(Keyword.ABSTRACT, "C", null, null, null, null));
  }

  void test_visitClassDeclaration_empty() {
    _assertClone(
        AstFactory.classDeclaration(null, "C", null, null, null, null));
  }

  void test_visitClassDeclaration_extends() {
    _assertClone(
        AstFactory.classDeclaration(
            null,
            "C",
            null,
            AstFactory.extendsClause(AstFactory.typeName4("A")),
            null,
            null));
  }

  void test_visitClassDeclaration_extends_implements() {
    _assertClone(
        AstFactory.classDeclaration(
            null,
            "C",
            null,
            AstFactory.extendsClause(AstFactory.typeName4("A")),
            null,
            AstFactory.implementsClause([AstFactory.typeName4("B")])));
  }

  void test_visitClassDeclaration_extends_with() {
    _assertClone(
        AstFactory.classDeclaration(
            null,
            "C",
            null,
            AstFactory.extendsClause(AstFactory.typeName4("A")),
            AstFactory.withClause([AstFactory.typeName4("M")]),
            null));
  }

  void test_visitClassDeclaration_extends_with_implements() {
    _assertClone(
        AstFactory.classDeclaration(
            null,
            "C",
            null,
            AstFactory.extendsClause(AstFactory.typeName4("A")),
            AstFactory.withClause([AstFactory.typeName4("M")]),
            AstFactory.implementsClause([AstFactory.typeName4("B")])));
  }

  void test_visitClassDeclaration_implements() {
    _assertClone(
        AstFactory.classDeclaration(
            null,
            "C",
            null,
            null,
            null,
            AstFactory.implementsClause([AstFactory.typeName4("B")])));
  }

  void test_visitClassDeclaration_multipleMember() {
    _assertClone(
        AstFactory.classDeclaration(
            null,
            "C",
            null,
            null,
            null,
            null,
            [
                AstFactory.fieldDeclaration2(
                    false,
                    Keyword.VAR,
                    [AstFactory.variableDeclaration("a")]),
                AstFactory.fieldDeclaration2(
                    false,
                    Keyword.VAR,
                    [AstFactory.variableDeclaration("b")])]));
  }

  void test_visitClassDeclaration_parameters() {
    _assertClone(
        AstFactory.classDeclaration(
            null,
            "C",
            AstFactory.typeParameterList(["E"]),
            null,
            null,
            null));
  }

  void test_visitClassDeclaration_parameters_extends() {
    _assertClone(
        AstFactory.classDeclaration(
            null,
            "C",
            AstFactory.typeParameterList(["E"]),
            AstFactory.extendsClause(AstFactory.typeName4("A")),
            null,
            null));
  }

  void test_visitClassDeclaration_parameters_extends_implements() {
    _assertClone(
        AstFactory.classDeclaration(
            null,
            "C",
            AstFactory.typeParameterList(["E"]),
            AstFactory.extendsClause(AstFactory.typeName4("A")),
            null,
            AstFactory.implementsClause([AstFactory.typeName4("B")])));
  }

  void test_visitClassDeclaration_parameters_extends_with() {
    _assertClone(
        AstFactory.classDeclaration(
            null,
            "C",
            AstFactory.typeParameterList(["E"]),
            AstFactory.extendsClause(AstFactory.typeName4("A")),
            AstFactory.withClause([AstFactory.typeName4("M")]),
            null));
  }

  void test_visitClassDeclaration_parameters_extends_with_implements() {
    _assertClone(
        AstFactory.classDeclaration(
            null,
            "C",
            AstFactory.typeParameterList(["E"]),
            AstFactory.extendsClause(AstFactory.typeName4("A")),
            AstFactory.withClause([AstFactory.typeName4("M")]),
            AstFactory.implementsClause([AstFactory.typeName4("B")])));
  }

  void test_visitClassDeclaration_parameters_implements() {
    _assertClone(
        AstFactory.classDeclaration(
            null,
            "C",
            AstFactory.typeParameterList(["E"]),
            null,
            null,
            AstFactory.implementsClause([AstFactory.typeName4("B")])));
  }

  void test_visitClassDeclaration_singleMember() {
    _assertClone(
        AstFactory.classDeclaration(
            null,
            "C",
            null,
            null,
            null,
            null,
            [
                AstFactory.fieldDeclaration2(
                    false,
                    Keyword.VAR,
                    [AstFactory.variableDeclaration("a")])]));
  }

  void test_visitClassDeclaration_withMetadata() {
    ClassDeclaration declaration =
        AstFactory.classDeclaration(null, "C", null, null, null, null);
    declaration.metadata =
        [AstFactory.annotation(AstFactory.identifier3("deprecated"))];
    _assertClone(declaration);
  }

  void test_visitClassTypeAlias_abstract() {
    _assertClone(
        AstFactory.classTypeAlias(
            "C",
            null,
            Keyword.ABSTRACT,
            AstFactory.typeName4("S"),
            AstFactory.withClause([AstFactory.typeName4("M1")]),
            null));
  }

  void test_visitClassTypeAlias_abstract_implements() {
    _assertClone(
        AstFactory.classTypeAlias(
            "C",
            null,
            Keyword.ABSTRACT,
            AstFactory.typeName4("S"),
            AstFactory.withClause([AstFactory.typeName4("M1")]),
            AstFactory.implementsClause([AstFactory.typeName4("I")])));
  }

  void test_visitClassTypeAlias_generic() {
    _assertClone(
        AstFactory.classTypeAlias(
            "C",
            AstFactory.typeParameterList(["E"]),
            null,
            AstFactory.typeName4("S", [AstFactory.typeName4("E")]),
            AstFactory.withClause(
                [AstFactory.typeName4("M1", [AstFactory.typeName4("E")])]),
            null));
  }

  void test_visitClassTypeAlias_implements() {
    _assertClone(
        AstFactory.classTypeAlias(
            "C",
            null,
            null,
            AstFactory.typeName4("S"),
            AstFactory.withClause([AstFactory.typeName4("M1")]),
            AstFactory.implementsClause([AstFactory.typeName4("I")])));
  }

  void test_visitClassTypeAlias_minimal() {
    _assertClone(
        AstFactory.classTypeAlias(
            "C",
            null,
            null,
            AstFactory.typeName4("S"),
            AstFactory.withClause([AstFactory.typeName4("M1")]),
            null));
  }

  void test_visitClassTypeAlias_parameters_abstract() {
    _assertClone(
        AstFactory.classTypeAlias(
            "C",
            AstFactory.typeParameterList(["E"]),
            Keyword.ABSTRACT,
            AstFactory.typeName4("S"),
            AstFactory.withClause([AstFactory.typeName4("M1")]),
            null));
  }

  void test_visitClassTypeAlias_parameters_abstract_implements() {
    _assertClone(
        AstFactory.classTypeAlias(
            "C",
            AstFactory.typeParameterList(["E"]),
            Keyword.ABSTRACT,
            AstFactory.typeName4("S"),
            AstFactory.withClause([AstFactory.typeName4("M1")]),
            AstFactory.implementsClause([AstFactory.typeName4("I")])));
  }

  void test_visitClassTypeAlias_parameters_implements() {
    _assertClone(
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
    declaration.metadata =
        [AstFactory.annotation(AstFactory.identifier3("deprecated"))];
    _assertClone(declaration);
  }

  void test_visitComment() {
    _assertClone(
        Comment.createBlockComment(
            <Token>[TokenFactory.tokenFromString("/* comment */")]));
  }

  void test_visitCommentReference() {
    _assertClone(new CommentReference(null, AstFactory.identifier3("a")));
  }

  void test_visitCompilationUnit_declaration() {
    _assertClone(
        AstFactory.compilationUnit2(
            [
                AstFactory.topLevelVariableDeclaration2(
                    Keyword.VAR,
                    [AstFactory.variableDeclaration("a")])]));
  }

  void test_visitCompilationUnit_directive() {
    _assertClone(
        AstFactory.compilationUnit3([AstFactory.libraryDirective2("l")]));
  }

  void test_visitCompilationUnit_directive_declaration() {
    _assertClone(
        AstFactory.compilationUnit4(
            [AstFactory.libraryDirective2("l")],
            [
                AstFactory.topLevelVariableDeclaration2(
                    Keyword.VAR,
                    [AstFactory.variableDeclaration("a")])]));
  }

  void test_visitCompilationUnit_empty() {
    _assertClone(AstFactory.compilationUnit());
  }

  void test_visitCompilationUnit_script() {
    _assertClone(AstFactory.compilationUnit5("!#/bin/dartvm"));
  }

  void test_visitCompilationUnit_script_declaration() {
    _assertClone(
        AstFactory.compilationUnit6(
            "!#/bin/dartvm",
            [
                AstFactory.topLevelVariableDeclaration2(
                    Keyword.VAR,
                    [AstFactory.variableDeclaration("a")])]));
  }

  void test_visitCompilationUnit_script_directive() {
    _assertClone(
        AstFactory.compilationUnit7(
            "!#/bin/dartvm",
            [AstFactory.libraryDirective2("l")]));
  }

  void test_visitCompilationUnit_script_directives_declarations() {
    _assertClone(
        AstFactory.compilationUnit8(
            "!#/bin/dartvm",
            [AstFactory.libraryDirective2("l")],
            [
                AstFactory.topLevelVariableDeclaration2(
                    Keyword.VAR,
                    [AstFactory.variableDeclaration("a")])]));
  }

  void test_visitConditionalExpression() {
    _assertClone(
        AstFactory.conditionalExpression(
            AstFactory.identifier3("a"),
            AstFactory.identifier3("b"),
            AstFactory.identifier3("c")));
  }

  void test_visitConstructorDeclaration_const() {
    _assertClone(
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
    _assertClone(
        AstFactory.constructorDeclaration(
            AstFactory.identifier3("C"),
            null,
            AstFactory.formalParameterList(),
            null));
  }

  void test_visitConstructorDeclaration_minimal() {
    _assertClone(
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
    _assertClone(
        AstFactory.constructorDeclaration2(
            null,
            null,
            AstFactory.identifier3("C"),
            null,
            AstFactory.formalParameterList(),
            [
                AstFactory.constructorFieldInitializer(false, "a", AstFactory.identifier3("b")),
                AstFactory.constructorFieldInitializer(
                    false,
                    "c",
                    AstFactory.identifier3("d"))],
            AstFactory.blockFunctionBody2()));
  }

  void test_visitConstructorDeclaration_multipleParameters() {
    _assertClone(
        AstFactory.constructorDeclaration2(
            null,
            null,
            AstFactory.identifier3("C"),
            null,
            AstFactory.formalParameterList(
                [
                    AstFactory.simpleFormalParameter(Keyword.VAR, "a"),
                    AstFactory.simpleFormalParameter(Keyword.VAR, "b")]),
            null,
            AstFactory.blockFunctionBody2()));
  }

  void test_visitConstructorDeclaration_named() {
    _assertClone(
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
    _assertClone(
        AstFactory.constructorDeclaration2(
            null,
            null,
            AstFactory.identifier3("C"),
            null,
            AstFactory.formalParameterList(),
            [
                AstFactory.constructorFieldInitializer(
                    false,
                    "a",
                    AstFactory.identifier3("b"))],
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
    declaration.metadata =
        [AstFactory.annotation(AstFactory.identifier3("deprecated"))];
    _assertClone(declaration);
  }

  void test_visitConstructorFieldInitializer_withoutThis() {
    _assertClone(
        AstFactory.constructorFieldInitializer(
            false,
            "a",
            AstFactory.identifier3("b")));
  }

  void test_visitConstructorFieldInitializer_withThis() {
    _assertClone(
        AstFactory.constructorFieldInitializer(true, "a", AstFactory.identifier3("b")));
  }

  void test_visitConstructorName_named_prefix() {
    _assertClone(
        AstFactory.constructorName(AstFactory.typeName4("p.C.n"), null));
  }

  void test_visitConstructorName_unnamed_noPrefix() {
    _assertClone(AstFactory.constructorName(AstFactory.typeName4("C"), null));
  }

  void test_visitConstructorName_unnamed_prefix() {
    _assertClone(
        AstFactory.constructorName(
            AstFactory.typeName3(AstFactory.identifier5("p", "C")),
            null));
  }

  void test_visitContinueStatement_label() {
    _assertClone(AstFactory.continueStatement("l"));
  }

  void test_visitContinueStatement_noLabel() {
    _assertClone(AstFactory.continueStatement());
  }

  void test_visitDefaultFormalParameter_named_noValue() {
    _assertClone(
        AstFactory.namedFormalParameter(AstFactory.simpleFormalParameter3("p"), null));
  }

  void test_visitDefaultFormalParameter_named_value() {
    _assertClone(
        AstFactory.namedFormalParameter(
            AstFactory.simpleFormalParameter3("p"),
            AstFactory.integer(0)));
  }

  void test_visitDefaultFormalParameter_positional_noValue() {
    _assertClone(
        AstFactory.positionalFormalParameter(
            AstFactory.simpleFormalParameter3("p"),
            null));
  }

  void test_visitDefaultFormalParameter_positional_value() {
    _assertClone(
        AstFactory.positionalFormalParameter(
            AstFactory.simpleFormalParameter3("p"),
            AstFactory.integer(0)));
  }

  void test_visitDoStatement() {
    _assertClone(
        AstFactory.doStatement(AstFactory.block(), AstFactory.identifier3("c")));
  }

  void test_visitDoubleLiteral() {
    _assertClone(AstFactory.doubleLiteral(4.2));
  }

  void test_visitEmptyFunctionBody() {
    _assertClone(AstFactory.emptyFunctionBody());
  }

  void test_visitEmptyStatement() {
    _assertClone(AstFactory.emptyStatement());
  }

  void test_visitExportDirective_combinator() {
    _assertClone(
        AstFactory.exportDirective2(
            "a.dart",
            [AstFactory.showCombinator([AstFactory.identifier3("A")])]));
  }

  void test_visitExportDirective_combinators() {
    _assertClone(
        AstFactory.exportDirective2(
            "a.dart",
            [
                AstFactory.showCombinator([AstFactory.identifier3("A")]),
                AstFactory.hideCombinator([AstFactory.identifier3("B")])]));
  }

  void test_visitExportDirective_minimal() {
    _assertClone(AstFactory.exportDirective2("a.dart"));
  }

  void test_visitExportDirective_withMetadata() {
    ExportDirective directive = AstFactory.exportDirective2("a.dart");
    directive.metadata =
        [AstFactory.annotation(AstFactory.identifier3("deprecated"))];
    _assertClone(directive);
  }

  void test_visitExpressionFunctionBody() {
    _assertClone(
        AstFactory.expressionFunctionBody(AstFactory.identifier3("a")));
  }

  void test_visitExpressionStatement() {
    _assertClone(AstFactory.expressionStatement(AstFactory.identifier3("a")));
  }

  void test_visitExtendsClause() {
    _assertClone(AstFactory.extendsClause(AstFactory.typeName4("C")));
  }

  void test_visitFieldDeclaration_instance() {
    _assertClone(
        AstFactory.fieldDeclaration2(
            false,
            Keyword.VAR,
            [AstFactory.variableDeclaration("a")]));
  }

  void test_visitFieldDeclaration_static() {
    _assertClone(
        AstFactory.fieldDeclaration2(
            true,
            Keyword.VAR,
            [AstFactory.variableDeclaration("a")]));
  }

  void test_visitFieldDeclaration_withMetadata() {
    FieldDeclaration declaration = AstFactory.fieldDeclaration2(
        false,
        Keyword.VAR,
        [AstFactory.variableDeclaration("a")]);
    declaration.metadata =
        [AstFactory.annotation(AstFactory.identifier3("deprecated"))];
    _assertClone(declaration);
  }

  void test_visitFieldFormalParameter_functionTyped() {
    _assertClone(
        AstFactory.fieldFormalParameter(
            null,
            AstFactory.typeName4("A"),
            "a",
            AstFactory.formalParameterList([AstFactory.simpleFormalParameter3("b")])));
  }

  void test_visitFieldFormalParameter_keyword() {
    _assertClone(AstFactory.fieldFormalParameter(Keyword.VAR, null, "a"));
  }

  void test_visitFieldFormalParameter_keywordAndType() {
    _assertClone(
        AstFactory.fieldFormalParameter(Keyword.FINAL, AstFactory.typeName4("A"), "a"));
  }

  void test_visitFieldFormalParameter_type() {
    _assertClone(
        AstFactory.fieldFormalParameter(null, AstFactory.typeName4("A"), "a"));
  }

  void test_visitForEachStatement_declared() {
    _assertClone(
        AstFactory.forEachStatement(
            AstFactory.declaredIdentifier3("a"),
            AstFactory.identifier3("b"),
            AstFactory.block()));
  }

  void test_visitForEachStatement_variable() {
    _assertClone(
        new ForEachStatement.con2(
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
    _assertClone(
        new ForEachStatement.con2(
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
    _assertClone(AstFactory.formalParameterList());
  }

  void test_visitFormalParameterList_n() {
    _assertClone(
        AstFactory.formalParameterList(
            [
                AstFactory.namedFormalParameter(
                    AstFactory.simpleFormalParameter3("a"),
                    AstFactory.integer(0))]));
  }

  void test_visitFormalParameterList_nn() {
    _assertClone(
        AstFactory.formalParameterList(
            [
                AstFactory.namedFormalParameter(
                    AstFactory.simpleFormalParameter3("a"),
                    AstFactory.integer(0)),
                AstFactory.namedFormalParameter(
                    AstFactory.simpleFormalParameter3("b"),
                    AstFactory.integer(1))]));
  }

  void test_visitFormalParameterList_p() {
    _assertClone(
        AstFactory.formalParameterList(
            [
                AstFactory.positionalFormalParameter(
                    AstFactory.simpleFormalParameter3("a"),
                    AstFactory.integer(0))]));
  }

  void test_visitFormalParameterList_pp() {
    _assertClone(
        AstFactory.formalParameterList(
            [
                AstFactory.positionalFormalParameter(
                    AstFactory.simpleFormalParameter3("a"),
                    AstFactory.integer(0)),
                AstFactory.positionalFormalParameter(
                    AstFactory.simpleFormalParameter3("b"),
                    AstFactory.integer(1))]));
  }

  void test_visitFormalParameterList_r() {
    _assertClone(
        AstFactory.formalParameterList([AstFactory.simpleFormalParameter3("a")]));
  }

  void test_visitFormalParameterList_rn() {
    _assertClone(
        AstFactory.formalParameterList(
            [
                AstFactory.simpleFormalParameter3("a"),
                AstFactory.namedFormalParameter(
                    AstFactory.simpleFormalParameter3("b"),
                    AstFactory.integer(1))]));
  }

  void test_visitFormalParameterList_rnn() {
    _assertClone(
        AstFactory.formalParameterList(
            [
                AstFactory.simpleFormalParameter3("a"),
                AstFactory.namedFormalParameter(
                    AstFactory.simpleFormalParameter3("b"),
                    AstFactory.integer(1)),
                AstFactory.namedFormalParameter(
                    AstFactory.simpleFormalParameter3("c"),
                    AstFactory.integer(2))]));
  }

  void test_visitFormalParameterList_rp() {
    _assertClone(
        AstFactory.formalParameterList(
            [
                AstFactory.simpleFormalParameter3("a"),
                AstFactory.positionalFormalParameter(
                    AstFactory.simpleFormalParameter3("b"),
                    AstFactory.integer(1))]));
  }

  void test_visitFormalParameterList_rpp() {
    _assertClone(
        AstFactory.formalParameterList(
            [
                AstFactory.simpleFormalParameter3("a"),
                AstFactory.positionalFormalParameter(
                    AstFactory.simpleFormalParameter3("b"),
                    AstFactory.integer(1)),
                AstFactory.positionalFormalParameter(
                    AstFactory.simpleFormalParameter3("c"),
                    AstFactory.integer(2))]));
  }

  void test_visitFormalParameterList_rr() {
    _assertClone(
        AstFactory.formalParameterList(
            [
                AstFactory.simpleFormalParameter3("a"),
                AstFactory.simpleFormalParameter3("b")]));
  }

  void test_visitFormalParameterList_rrn() {
    _assertClone(
        AstFactory.formalParameterList(
            [
                AstFactory.simpleFormalParameter3("a"),
                AstFactory.simpleFormalParameter3("b"),
                AstFactory.namedFormalParameter(
                    AstFactory.simpleFormalParameter3("c"),
                    AstFactory.integer(3))]));
  }

  void test_visitFormalParameterList_rrnn() {
    _assertClone(
        AstFactory.formalParameterList(
            [
                AstFactory.simpleFormalParameter3("a"),
                AstFactory.simpleFormalParameter3("b"),
                AstFactory.namedFormalParameter(
                    AstFactory.simpleFormalParameter3("c"),
                    AstFactory.integer(3)),
                AstFactory.namedFormalParameter(
                    AstFactory.simpleFormalParameter3("d"),
                    AstFactory.integer(4))]));
  }

  void test_visitFormalParameterList_rrp() {
    _assertClone(
        AstFactory.formalParameterList(
            [
                AstFactory.simpleFormalParameter3("a"),
                AstFactory.simpleFormalParameter3("b"),
                AstFactory.positionalFormalParameter(
                    AstFactory.simpleFormalParameter3("c"),
                    AstFactory.integer(3))]));
  }

  void test_visitFormalParameterList_rrpp() {
    _assertClone(
        AstFactory.formalParameterList(
            [
                AstFactory.simpleFormalParameter3("a"),
                AstFactory.simpleFormalParameter3("b"),
                AstFactory.positionalFormalParameter(
                    AstFactory.simpleFormalParameter3("c"),
                    AstFactory.integer(3)),
                AstFactory.positionalFormalParameter(
                    AstFactory.simpleFormalParameter3("d"),
                    AstFactory.integer(4))]));
  }

  void test_visitForStatement_c() {
    _assertClone(
        AstFactory.forStatement(
            null,
            AstFactory.identifier3("c"),
            null,
            AstFactory.block()));
  }

  void test_visitForStatement_cu() {
    _assertClone(
        AstFactory.forStatement(
            null,
            AstFactory.identifier3("c"),
            [AstFactory.identifier3("u")],
            AstFactory.block()));
  }

  void test_visitForStatement_e() {
    _assertClone(
        AstFactory.forStatement(
            AstFactory.identifier3("e"),
            null,
            null,
            AstFactory.block()));
  }

  void test_visitForStatement_ec() {
    _assertClone(
        AstFactory.forStatement(
            AstFactory.identifier3("e"),
            AstFactory.identifier3("c"),
            null,
            AstFactory.block()));
  }

  void test_visitForStatement_ecu() {
    _assertClone(
        AstFactory.forStatement(
            AstFactory.identifier3("e"),
            AstFactory.identifier3("c"),
            [AstFactory.identifier3("u")],
            AstFactory.block()));
  }

  void test_visitForStatement_eu() {
    _assertClone(
        AstFactory.forStatement(
            AstFactory.identifier3("e"),
            null,
            [AstFactory.identifier3("u")],
            AstFactory.block()));
  }

  void test_visitForStatement_i() {
    _assertClone(
        AstFactory.forStatement2(
            AstFactory.variableDeclarationList2(
                Keyword.VAR,
                [AstFactory.variableDeclaration("i")]),
            null,
            null,
            AstFactory.block()));
  }

  void test_visitForStatement_ic() {
    _assertClone(
        AstFactory.forStatement2(
            AstFactory.variableDeclarationList2(
                Keyword.VAR,
                [AstFactory.variableDeclaration("i")]),
            AstFactory.identifier3("c"),
            null,
            AstFactory.block()));
  }

  void test_visitForStatement_icu() {
    _assertClone(
        AstFactory.forStatement2(
            AstFactory.variableDeclarationList2(
                Keyword.VAR,
                [AstFactory.variableDeclaration("i")]),
            AstFactory.identifier3("c"),
            [AstFactory.identifier3("u")],
            AstFactory.block()));
  }

  void test_visitForStatement_iu() {
    _assertClone(
        AstFactory.forStatement2(
            AstFactory.variableDeclarationList2(
                Keyword.VAR,
                [AstFactory.variableDeclaration("i")]),
            null,
            [AstFactory.identifier3("u")],
            AstFactory.block()));
  }

  void test_visitForStatement_u() {
    _assertClone(
        AstFactory.forStatement(
            null,
            null,
            [AstFactory.identifier3("u")],
            AstFactory.block()));
  }

  void test_visitFunctionDeclaration_getter() {
    _assertClone(
        AstFactory.functionDeclaration(
            null,
            Keyword.GET,
            "f",
            AstFactory.functionExpression()));
  }

  void test_visitFunctionDeclaration_normal() {
    _assertClone(
        AstFactory.functionDeclaration(
            null,
            null,
            "f",
            AstFactory.functionExpression()));
  }

  void test_visitFunctionDeclaration_setter() {
    _assertClone(
        AstFactory.functionDeclaration(
            null,
            Keyword.SET,
            "f",
            AstFactory.functionExpression()));
  }

  void test_visitFunctionDeclaration_withMetadata() {
    FunctionDeclaration declaration = AstFactory.functionDeclaration(
        null,
        null,
        "f",
        AstFactory.functionExpression());
    declaration.metadata =
        [AstFactory.annotation(AstFactory.identifier3("deprecated"))];
    _assertClone(declaration);
  }

  void test_visitFunctionDeclarationStatement() {
    _assertClone(
        AstFactory.functionDeclarationStatement(
            null,
            null,
            "f",
            AstFactory.functionExpression()));
  }

  void test_visitFunctionExpression() {
    _assertClone(AstFactory.functionExpression());
  }

  void test_visitFunctionExpressionInvocation() {
    _assertClone(
        AstFactory.functionExpressionInvocation(AstFactory.identifier3("f")));
  }

  void test_visitFunctionTypeAlias_generic() {
    _assertClone(
        AstFactory.typeAlias(
            AstFactory.typeName4("A"),
            "F",
            AstFactory.typeParameterList(["B"]),
            AstFactory.formalParameterList()));
  }

  void test_visitFunctionTypeAlias_nonGeneric() {
    _assertClone(
        AstFactory.typeAlias(
            AstFactory.typeName4("A"),
            "F",
            null,
            AstFactory.formalParameterList()));
  }

  void test_visitFunctionTypeAlias_withMetadata() {
    FunctionTypeAlias declaration = AstFactory.typeAlias(
        AstFactory.typeName4("A"),
        "F",
        null,
        AstFactory.formalParameterList());
    declaration.metadata =
        [AstFactory.annotation(AstFactory.identifier3("deprecated"))];
    _assertClone(declaration);
  }

  void test_visitFunctionTypedFormalParameter_noType() {
    _assertClone(AstFactory.functionTypedFormalParameter(null, "f"));
  }

  void test_visitFunctionTypedFormalParameter_type() {
    _assertClone(
        AstFactory.functionTypedFormalParameter(AstFactory.typeName4("T"), "f"));
  }

  void test_visitIfStatement_withElse() {
    _assertClone(
        AstFactory.ifStatement2(
            AstFactory.identifier3("c"),
            AstFactory.block(),
            AstFactory.block()));
  }

  void test_visitIfStatement_withoutElse() {
    _assertClone(
        AstFactory.ifStatement(AstFactory.identifier3("c"), AstFactory.block()));
  }

  void test_visitImplementsClause_multiple() {
    _assertClone(
        AstFactory.implementsClause(
            [AstFactory.typeName4("A"), AstFactory.typeName4("B")]));
  }

  void test_visitImplementsClause_single() {
    _assertClone(AstFactory.implementsClause([AstFactory.typeName4("A")]));
  }

  void test_visitImportDirective_combinator() {
    _assertClone(
        AstFactory.importDirective3(
            "a.dart",
            null,
            [AstFactory.showCombinator([AstFactory.identifier3("A")])]));
  }

  void test_visitImportDirective_combinators() {
    _assertClone(
        AstFactory.importDirective3(
            "a.dart",
            null,
            [
                AstFactory.showCombinator([AstFactory.identifier3("A")]),
                AstFactory.hideCombinator([AstFactory.identifier3("B")])]));
  }

  void test_visitImportDirective_minimal() {
    _assertClone(AstFactory.importDirective3("a.dart", null));
  }

  void test_visitImportDirective_prefix() {
    _assertClone(AstFactory.importDirective3("a.dart", "p"));
  }

  void test_visitImportDirective_prefix_combinator() {
    _assertClone(
        AstFactory.importDirective3(
            "a.dart",
            "p",
            [AstFactory.showCombinator([AstFactory.identifier3("A")])]));
  }

  void test_visitImportDirective_prefix_combinators() {
    _assertClone(
        AstFactory.importDirective3(
            "a.dart",
            "p",
            [
                AstFactory.showCombinator([AstFactory.identifier3("A")]),
                AstFactory.hideCombinator([AstFactory.identifier3("B")])]));
  }

  void test_visitImportDirective_withMetadata() {
    ImportDirective directive = AstFactory.importDirective3("a.dart", null);
    directive.metadata =
        [AstFactory.annotation(AstFactory.identifier3("deprecated"))];
    _assertClone(directive);
  }

  void test_visitImportHideCombinator_multiple() {
    _assertClone(
        AstFactory.hideCombinator(
            [AstFactory.identifier3("a"), AstFactory.identifier3("b")]));
  }

  void test_visitImportHideCombinator_single() {
    _assertClone(AstFactory.hideCombinator([AstFactory.identifier3("a")]));
  }

  void test_visitImportShowCombinator_multiple() {
    _assertClone(
        AstFactory.showCombinator(
            [AstFactory.identifier3("a"), AstFactory.identifier3("b")]));
  }

  void test_visitImportShowCombinator_single() {
    _assertClone(AstFactory.showCombinator([AstFactory.identifier3("a")]));
  }

  void test_visitIndexExpression() {
    _assertClone(
        AstFactory.indexExpression(
            AstFactory.identifier3("a"),
            AstFactory.identifier3("i")));
  }

  void test_visitInstanceCreationExpression_const() {
    _assertClone(
        AstFactory.instanceCreationExpression2(
            Keyword.CONST,
            AstFactory.typeName4("C")));
  }

  void test_visitInstanceCreationExpression_named() {
    _assertClone(
        AstFactory.instanceCreationExpression3(
            Keyword.NEW,
            AstFactory.typeName4("C"),
            "c"));
  }

  void test_visitInstanceCreationExpression_unnamed() {
    _assertClone(
        AstFactory.instanceCreationExpression2(Keyword.NEW, AstFactory.typeName4("C")));
  }

  void test_visitIntegerLiteral() {
    _assertClone(AstFactory.integer(42));
  }

  void test_visitInterpolationExpression_expression() {
    _assertClone(
        AstFactory.interpolationExpression(AstFactory.identifier3("a")));
  }

  void test_visitInterpolationExpression_identifier() {
    _assertClone(AstFactory.interpolationExpression2("a"));
  }

  void test_visitInterpolationString() {
    _assertClone(AstFactory.interpolationString("'x", "x"));
  }

  void test_visitIsExpression_negated() {
    _assertClone(
        AstFactory.isExpression(
            AstFactory.identifier3("a"),
            true,
            AstFactory.typeName4("C")));
  }

  void test_visitIsExpression_normal() {
    _assertClone(
        AstFactory.isExpression(
            AstFactory.identifier3("a"),
            false,
            AstFactory.typeName4("C")));
  }

  void test_visitLabel() {
    _assertClone(AstFactory.label2("a"));
  }

  void test_visitLabeledStatement_multiple() {
    _assertClone(
        AstFactory.labeledStatement(
            [AstFactory.label2("a"), AstFactory.label2("b")],
            AstFactory.returnStatement()));
  }

  void test_visitLabeledStatement_single() {
    _assertClone(
        AstFactory.labeledStatement(
            [AstFactory.label2("a")],
            AstFactory.returnStatement()));
  }

  void test_visitLibraryDirective() {
    _assertClone(AstFactory.libraryDirective2("l"));
  }

  void test_visitLibraryDirective_withMetadata() {
    LibraryDirective directive = AstFactory.libraryDirective2("l");
    directive.metadata =
        [AstFactory.annotation(AstFactory.identifier3("deprecated"))];
    _assertClone(directive);
  }

  void test_visitLibraryIdentifier_multiple() {
    _assertClone(
        AstFactory.libraryIdentifier(
            [
                AstFactory.identifier3("a"),
                AstFactory.identifier3("b"),
                AstFactory.identifier3("c")]));
  }

  void test_visitLibraryIdentifier_single() {
    _assertClone(AstFactory.libraryIdentifier([AstFactory.identifier3("a")]));
  }

  void test_visitListLiteral_const() {
    _assertClone(AstFactory.listLiteral2(Keyword.CONST, null));
  }

  void test_visitListLiteral_empty() {
    _assertClone(AstFactory.listLiteral());
  }

  void test_visitListLiteral_nonEmpty() {
    _assertClone(
        AstFactory.listLiteral(
            [
                AstFactory.identifier3("a"),
                AstFactory.identifier3("b"),
                AstFactory.identifier3("c")]));
  }

  void test_visitMapLiteral_const() {
    _assertClone(AstFactory.mapLiteral(Keyword.CONST, null));
  }

  void test_visitMapLiteral_empty() {
    _assertClone(AstFactory.mapLiteral2());
  }

  void test_visitMapLiteral_nonEmpty() {
    _assertClone(
        AstFactory.mapLiteral2(
            [
                AstFactory.mapLiteralEntry("a", AstFactory.identifier3("a")),
                AstFactory.mapLiteralEntry("b", AstFactory.identifier3("b")),
                AstFactory.mapLiteralEntry("c", AstFactory.identifier3("c"))]));
  }

  void test_visitMapLiteralEntry() {
    _assertClone(AstFactory.mapLiteralEntry("a", AstFactory.identifier3("b")));
  }

  void test_visitMethodDeclaration_external() {
    _assertClone(
        AstFactory.methodDeclaration(
            null,
            null,
            null,
            null,
            AstFactory.identifier3("m"),
            AstFactory.formalParameterList()));
  }

  void test_visitMethodDeclaration_external_returnType() {
    _assertClone(
        AstFactory.methodDeclaration(
            null,
            AstFactory.typeName4("T"),
            null,
            null,
            AstFactory.identifier3("m"),
            AstFactory.formalParameterList()));
  }

  void test_visitMethodDeclaration_getter() {
    _assertClone(
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
    _assertClone(
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
    _assertClone(
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
    _assertClone(
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
    _assertClone(
        AstFactory.methodDeclaration2(
            null,
            null,
            null,
            null,
            AstFactory.identifier3("m"),
            AstFactory.formalParameterList(
                [
                    AstFactory.simpleFormalParameter(Keyword.VAR, "a"),
                    AstFactory.simpleFormalParameter(Keyword.VAR, "b")]),
            AstFactory.blockFunctionBody2()));
  }

  void test_visitMethodDeclaration_operator() {
    _assertClone(
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
    _assertClone(
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
    _assertClone(
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
    _assertClone(
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
    _assertClone(
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
    _assertClone(
        AstFactory.methodDeclaration2(
            Keyword.STATIC,
            AstFactory.typeName4("T"),
            null,
            null,
            AstFactory.identifier3("m"),
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
    declaration.metadata =
        [AstFactory.annotation(AstFactory.identifier3("deprecated"))];
    _assertClone(declaration);
  }

  void test_visitMethodInvocation_noTarget() {
    _assertClone(AstFactory.methodInvocation2("m"));
  }

  void test_visitMethodInvocation_target() {
    _assertClone(AstFactory.methodInvocation(AstFactory.identifier3("t"), "m"));
  }

  void test_visitNamedExpression() {
    _assertClone(AstFactory.namedExpression2("a", AstFactory.identifier3("b")));
  }

  void test_visitNamedFormalParameter() {
    _assertClone(
        AstFactory.namedFormalParameter(
            AstFactory.simpleFormalParameter(Keyword.VAR, "a"),
            AstFactory.integer(0)));
  }

  void test_visitNativeClause() {
    _assertClone(AstFactory.nativeClause("code"));
  }

  void test_visitNativeFunctionBody() {
    _assertClone(AstFactory.nativeFunctionBody("str"));
  }

  void test_visitNullLiteral() {
    _assertClone(AstFactory.nullLiteral());
  }

  void test_visitParenthesizedExpression() {
    _assertClone(
        AstFactory.parenthesizedExpression(AstFactory.identifier3("a")));
  }

  void test_visitPartDirective() {
    _assertClone(AstFactory.partDirective2("a.dart"));
  }

  void test_visitPartDirective_withMetadata() {
    PartDirective directive = AstFactory.partDirective2("a.dart");
    directive.metadata =
        [AstFactory.annotation(AstFactory.identifier3("deprecated"))];
    _assertClone(directive);
  }

  void test_visitPartOfDirective() {
    _assertClone(
        AstFactory.partOfDirective(AstFactory.libraryIdentifier2(["l"])));
  }

  void test_visitPartOfDirective_withMetadata() {
    PartOfDirective directive =
        AstFactory.partOfDirective(AstFactory.libraryIdentifier2(["l"]));
    directive.metadata =
        [AstFactory.annotation(AstFactory.identifier3("deprecated"))];
    _assertClone(directive);
  }

  void test_visitPositionalFormalParameter() {
    _assertClone(
        AstFactory.positionalFormalParameter(
            AstFactory.simpleFormalParameter(Keyword.VAR, "a"),
            AstFactory.integer(0)));
  }

  void test_visitPostfixExpression() {
    _assertClone(
        AstFactory.postfixExpression(AstFactory.identifier3("a"), TokenType.PLUS_PLUS));
  }

  void test_visitPrefixedIdentifier() {
    _assertClone(AstFactory.identifier5("a", "b"));
  }

  void test_visitPrefixExpression() {
    _assertClone(
        AstFactory.prefixExpression(TokenType.MINUS, AstFactory.identifier3("a")));
  }

  void test_visitPropertyAccess() {
    _assertClone(AstFactory.propertyAccess2(AstFactory.identifier3("a"), "b"));
  }

  void test_visitRedirectingConstructorInvocation_named() {
    _assertClone(AstFactory.redirectingConstructorInvocation2("c"));
  }

  void test_visitRedirectingConstructorInvocation_unnamed() {
    _assertClone(AstFactory.redirectingConstructorInvocation());
  }

  void test_visitRethrowExpression() {
    _assertClone(AstFactory.rethrowExpression());
  }

  void test_visitReturnStatement_expression() {
    _assertClone(AstFactory.returnStatement2(AstFactory.identifier3("a")));
  }

  void test_visitReturnStatement_noExpression() {
    _assertClone(AstFactory.returnStatement());
  }

  void test_visitScriptTag() {
    String scriptTag = "!#/bin/dart.exe";
    _assertClone(AstFactory.scriptTag(scriptTag));
  }

  void test_visitSimpleFormalParameter_keyword() {
    _assertClone(AstFactory.simpleFormalParameter(Keyword.VAR, "a"));
  }

  void test_visitSimpleFormalParameter_keyword_type() {
    _assertClone(
        AstFactory.simpleFormalParameter2(
            Keyword.FINAL,
            AstFactory.typeName4("A"),
            "a"));
  }

  void test_visitSimpleFormalParameter_type() {
    _assertClone(
        AstFactory.simpleFormalParameter4(AstFactory.typeName4("A"), "a"));
  }

  void test_visitSimpleIdentifier() {
    _assertClone(AstFactory.identifier3("a"));
  }

  void test_visitSimpleStringLiteral() {
    _assertClone(AstFactory.string2("a"));
  }

  void test_visitStringInterpolation() {
    _assertClone(
        AstFactory.string(
            [
                AstFactory.interpolationString("'a", "a"),
                AstFactory.interpolationExpression(AstFactory.identifier3("e")),
                AstFactory.interpolationString("b'", "b")]));
  }

  void test_visitSuperConstructorInvocation() {
    _assertClone(AstFactory.superConstructorInvocation());
  }

  void test_visitSuperConstructorInvocation_named() {
    _assertClone(AstFactory.superConstructorInvocation2("c"));
  }

  void test_visitSuperExpression() {
    _assertClone(AstFactory.superExpression());
  }

  void test_visitSwitchCase_multipleLabels() {
    _assertClone(
        AstFactory.switchCase2(
            [AstFactory.label2("l1"), AstFactory.label2("l2")],
            AstFactory.identifier3("a"),
            [AstFactory.block()]));
  }

  void test_visitSwitchCase_multipleStatements() {
    _assertClone(
        AstFactory.switchCase(
            AstFactory.identifier3("a"),
            [AstFactory.block(), AstFactory.block()]));
  }

  void test_visitSwitchCase_noLabels() {
    _assertClone(
        AstFactory.switchCase(AstFactory.identifier3("a"), [AstFactory.block()]));
  }

  void test_visitSwitchCase_singleLabel() {
    _assertClone(
        AstFactory.switchCase2(
            [AstFactory.label2("l1")],
            AstFactory.identifier3("a"),
            [AstFactory.block()]));
  }

  void test_visitSwitchDefault_multipleLabels() {
    _assertClone(
        AstFactory.switchDefault(
            [AstFactory.label2("l1"), AstFactory.label2("l2")],
            [AstFactory.block()]));
  }

  void test_visitSwitchDefault_multipleStatements() {
    _assertClone(
        AstFactory.switchDefault2([AstFactory.block(), AstFactory.block()]));
  }

  void test_visitSwitchDefault_noLabels() {
    _assertClone(AstFactory.switchDefault2([AstFactory.block()]));
  }

  void test_visitSwitchDefault_singleLabel() {
    _assertClone(
        AstFactory.switchDefault([AstFactory.label2("l1")], [AstFactory.block()]));
  }

  void test_visitSwitchStatement() {
    _assertClone(
        AstFactory.switchStatement(
            AstFactory.identifier3("a"),
            [
                AstFactory.switchCase(AstFactory.string2("b"), [AstFactory.block()]),
                AstFactory.switchDefault2([AstFactory.block()])]));
  }

  void test_visitSymbolLiteral_multiple() {
    _assertClone(AstFactory.symbolLiteral(["a", "b", "c"]));
  }

  void test_visitSymbolLiteral_single() {
    _assertClone(AstFactory.symbolLiteral(["a"]));
  }

  void test_visitThisExpression() {
    _assertClone(AstFactory.thisExpression());
  }

  void test_visitThrowStatement() {
    _assertClone(AstFactory.throwExpression2(AstFactory.identifier3("e")));
  }

  void test_visitTopLevelVariableDeclaration_multiple() {
    _assertClone(
        AstFactory.topLevelVariableDeclaration2(
            Keyword.VAR,
            [AstFactory.variableDeclaration("a")]));
  }

  void test_visitTopLevelVariableDeclaration_single() {
    _assertClone(
        AstFactory.topLevelVariableDeclaration2(
            Keyword.VAR,
            [AstFactory.variableDeclaration("a"), AstFactory.variableDeclaration("b")]));
  }

  void test_visitTryStatement_catch() {
    _assertClone(
        AstFactory.tryStatement2(
            AstFactory.block(),
            [AstFactory.catchClause3(AstFactory.typeName4("E"))]));
  }

  void test_visitTryStatement_catches() {
    _assertClone(
        AstFactory.tryStatement2(
            AstFactory.block(),
            [
                AstFactory.catchClause3(AstFactory.typeName4("E")),
                AstFactory.catchClause3(AstFactory.typeName4("F"))]));
  }

  void test_visitTryStatement_catchFinally() {
    _assertClone(
        AstFactory.tryStatement3(
            AstFactory.block(),
            [AstFactory.catchClause3(AstFactory.typeName4("E"))],
            AstFactory.block()));
  }

  void test_visitTryStatement_finally() {
    _assertClone(
        AstFactory.tryStatement(AstFactory.block(), AstFactory.block()));
  }

  void test_visitTypeArgumentList_multiple() {
    _assertClone(
        AstFactory.typeArgumentList(
            [AstFactory.typeName4("E"), AstFactory.typeName4("F")]));
  }

  void test_visitTypeArgumentList_single() {
    _assertClone(AstFactory.typeArgumentList([AstFactory.typeName4("E")]));
  }

  void test_visitTypeName_multipleArgs() {
    _assertClone(
        AstFactory.typeName4(
            "C",
            [AstFactory.typeName4("D"), AstFactory.typeName4("E")]));
  }

  void test_visitTypeName_nestedArg() {
    _assertClone(
        AstFactory.typeName4(
            "C",
            [AstFactory.typeName4("D", [AstFactory.typeName4("E")])]));
  }

  void test_visitTypeName_noArgs() {
    _assertClone(AstFactory.typeName4("C"));
  }

  void test_visitTypeName_singleArg() {
    _assertClone(AstFactory.typeName4("C", [AstFactory.typeName4("D")]));
  }

  void test_visitTypeParameter_withExtends() {
    _assertClone(AstFactory.typeParameter2("E", AstFactory.typeName4("C")));
  }

  void test_visitTypeParameter_withMetadata() {
    TypeParameter parameter = AstFactory.typeParameter("E");
    parameter.metadata =
        [AstFactory.annotation(AstFactory.identifier3("deprecated"))];
    _assertClone(parameter);
  }

  void test_visitTypeParameter_withoutExtends() {
    _assertClone(AstFactory.typeParameter("E"));
  }

  void test_visitTypeParameterList_multiple() {
    _assertClone(AstFactory.typeParameterList(["E", "F"]));
  }

  void test_visitTypeParameterList_single() {
    _assertClone(AstFactory.typeParameterList(["E"]));
  }

  void test_visitVariableDeclaration_initialized() {
    _assertClone(
        AstFactory.variableDeclaration2("a", AstFactory.identifier3("b")));
  }

  void test_visitVariableDeclaration_uninitialized() {
    _assertClone(AstFactory.variableDeclaration("a"));
  }

  void test_visitVariableDeclaration_withMetadata() {
    VariableDeclaration declaration = AstFactory.variableDeclaration("a");
    declaration.metadata =
        [AstFactory.annotation(AstFactory.identifier3("deprecated"))];
    _assertClone(declaration);
  }

  void test_visitVariableDeclarationList_const_type() {
    _assertClone(
        AstFactory.variableDeclarationList(
            Keyword.CONST,
            AstFactory.typeName4("C"),
            [AstFactory.variableDeclaration("a"), AstFactory.variableDeclaration("b")]));
  }

  void test_visitVariableDeclarationList_final_noType() {
    _assertClone(
        AstFactory.variableDeclarationList2(
            Keyword.FINAL,
            [AstFactory.variableDeclaration("a"), AstFactory.variableDeclaration("b")]));
  }

  void test_visitVariableDeclarationList_final_withMetadata() {
    VariableDeclarationList declarationList =
        AstFactory.variableDeclarationList2(
            Keyword.FINAL,
            [AstFactory.variableDeclaration("a"), AstFactory.variableDeclaration("b")]);
    declarationList.metadata =
        [AstFactory.annotation(AstFactory.identifier3("deprecated"))];
    _assertClone(declarationList);
  }

  void test_visitVariableDeclarationList_type() {
    _assertClone(
        AstFactory.variableDeclarationList(
            null,
            AstFactory.typeName4("C"),
            [AstFactory.variableDeclaration("a"), AstFactory.variableDeclaration("b")]));
  }

  void test_visitVariableDeclarationList_var() {
    _assertClone(
        AstFactory.variableDeclarationList2(
            Keyword.VAR,
            [AstFactory.variableDeclaration("a"), AstFactory.variableDeclaration("b")]));
  }

  void test_visitVariableDeclarationStatement() {
    _assertClone(
        AstFactory.variableDeclarationStatement(
            null,
            AstFactory.typeName4("C"),
            [AstFactory.variableDeclaration("c")]));
  }

  void test_visitWhileStatement() {
    _assertClone(
        AstFactory.whileStatement(AstFactory.identifier3("c"), AstFactory.block()));
  }

  void test_visitWithClause_multiple() {
    _assertClone(
        AstFactory.withClause(
            [
                AstFactory.typeName4("A"),
                AstFactory.typeName4("B"),
                AstFactory.typeName4("C")]));
  }

  void test_visitWithClause_single() {
    _assertClone(AstFactory.withClause([AstFactory.typeName4("A")]));
  }

  void test_visitYieldStatement() {
    _assertClone(AstFactory.yieldStatement(AstFactory.identifier3("A")));
  }

  /**
   * Assert that an `AstCloner` will produce the expected AST structure when
   * visiting the given [node].
   *
   * @param node the AST node being visited to produce the cloned structure
   * @throws AFE if the visitor does not produce the expected source for the given node
   */
  void _assertClone(AstNode node) {
    AstNode clone = node.accept(new AstCloner());
    AstCloneComparator comparitor = new AstCloneComparator(false);
    if (!comparitor.isEqualNodes(node, clone)) {
      fail("Failed to clone ${node.runtimeType.toString()}");
    }

    clone = node.accept(new AstCloner(true));
    comparitor = new AstCloneComparator(true);
    if (!comparitor.isEqualNodes(node, clone)) {
      fail("Failed to clone ${node.runtimeType.toString()}");
    }
  }
}

@ReflectiveTestCase()
class BooleanArrayTest {
  void test_get_negative() {
    try {
      BooleanArray.get(0, -1);
      fail("Expected ");
    } on RangeError catch (exception) {
      // Expected
    }
  }

  void test_get_tooBig() {
    try {
      BooleanArray.get(0, 31);
      fail("Expected ");
    } on RangeError catch (exception) {
      // Expected
    }
  }

  void test_get_valid() {
    expect(BooleanArray.get(0, 0), false);
    expect(BooleanArray.get(1, 0), true);
    expect(BooleanArray.get(0, 30), false);
    expect(BooleanArray.get(1 << 30, 30), true);
  }

  void test_set_negative() {
    try {
      BooleanArray.set(0, -1, true);
      fail("Expected ");
    } on RangeError catch (exception) {
      // Expected
    }
  }

  void test_set_tooBig() {
    try {
      BooleanArray.set(0, 32, true);
      fail("Expected ");
    } on RangeError catch (exception) {
      // Expected
    }
  }

  void test_set_valueChanging() {
    expect(BooleanArray.set(0, 0, true), 1);
    expect(BooleanArray.set(1, 0, false), 0);
    expect(BooleanArray.set(0, 30, true), 1 << 30);
    expect(BooleanArray.set(1 << 30, 30, false), 0);
  }

  void test_set_valuePreserving() {
    expect(BooleanArray.set(0, 0, false), 0);
    expect(BooleanArray.set(1, 0, true), 1);
    expect(BooleanArray.set(0, 30, false), 0);
    expect(BooleanArray.set(1 << 30, 30, true), 1 << 30);
  }
}

@ReflectiveTestCase()
class DirectedGraphTest extends EngineTestCase {
  void test_addEdge() {
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    expect(graph.isEmpty, isTrue);
    graph.addEdge(new DirectedGraphTest_Node(), new DirectedGraphTest_Node());
    expect(graph.isEmpty, isFalse);
  }

  void test_addNode() {
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    expect(graph.isEmpty, isTrue);
    graph.addNode(new DirectedGraphTest_Node());
    expect(graph.isEmpty, isFalse);
  }

  void test_containsPath_noCycles() {
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node3 = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    graph.addEdge(node1, node2);
    graph.addEdge(node2, node3);
    expect(graph.containsPath(node1, node1), isTrue);
    expect(graph.containsPath(node1, node2), isTrue);
    expect(graph.containsPath(node1, node3), isTrue);
    expect(graph.containsPath(node2, node1), isFalse);
    expect(graph.containsPath(node2, node2), isTrue);
    expect(graph.containsPath(node2, node3), isTrue);
    expect(graph.containsPath(node3, node1), isFalse);
    expect(graph.containsPath(node3, node2), isFalse);
    expect(graph.containsPath(node3, node3), isTrue);
  }

  void test_containsPath_withCycles() {
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node3 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node4 = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    graph.addEdge(node1, node2);
    graph.addEdge(node2, node1);
    graph.addEdge(node1, node3);
    graph.addEdge(node3, node4);
    graph.addEdge(node4, node3);
    expect(graph.containsPath(node1, node1), isTrue);
    expect(graph.containsPath(node1, node2), isTrue);
    expect(graph.containsPath(node1, node3), isTrue);
    expect(graph.containsPath(node1, node4), isTrue);
    expect(graph.containsPath(node2, node1), isTrue);
    expect(graph.containsPath(node2, node2), isTrue);
    expect(graph.containsPath(node2, node3), isTrue);
    expect(graph.containsPath(node2, node4), isTrue);
    expect(graph.containsPath(node3, node1), isFalse);
    expect(graph.containsPath(node3, node2), isFalse);
    expect(graph.containsPath(node3, node3), isTrue);
    expect(graph.containsPath(node3, node4), isTrue);
    expect(graph.containsPath(node4, node1), isFalse);
    expect(graph.containsPath(node4, node2), isFalse);
    expect(graph.containsPath(node4, node3), isTrue);
    expect(graph.containsPath(node4, node4), isTrue);
  }

  void test_creation() {
    expect(new DirectedGraph<DirectedGraphTest_Node>(), isNotNull);
  }

  void test_findCycleContaining_complexCycle() {
    // Two overlapping loops: (1, 2, 3) and (3, 4, 5)
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node3 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node4 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node5 = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    graph.addEdge(node1, node2);
    graph.addEdge(node2, node3);
    graph.addEdge(node3, node1);
    graph.addEdge(node3, node4);
    graph.addEdge(node4, node5);
    graph.addEdge(node5, node3);
    List<DirectedGraphTest_Node> cycle = graph.findCycleContaining(node1);
    expect(cycle, hasLength(5));
    expect(cycle.contains(node1), isTrue);
    expect(cycle.contains(node2), isTrue);
    expect(cycle.contains(node3), isTrue);
    expect(cycle.contains(node4), isTrue);
    expect(cycle.contains(node5), isTrue);
  }

  void test_findCycleContaining_cycle() {
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node3 = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    graph.addEdge(node1, node2);
    graph.addEdge(node2, node3);
    graph.addEdge(node2, new DirectedGraphTest_Node());
    graph.addEdge(node3, node1);
    graph.addEdge(node3, new DirectedGraphTest_Node());
    List<DirectedGraphTest_Node> cycle = graph.findCycleContaining(node1);
    expect(cycle, hasLength(3));
    expect(cycle.contains(node1), isTrue);
    expect(cycle.contains(node2), isTrue);
    expect(cycle.contains(node3), isTrue);
  }

  void test_findCycleContaining_notInGraph() {
    DirectedGraphTest_Node node = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    List<DirectedGraphTest_Node> cycle = graph.findCycleContaining(node);
    expect(cycle, hasLength(1));
    expect(cycle[0], node);
  }

  void test_findCycleContaining_null() {
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    try {
      graph.findCycleContaining(null);
      fail("Expected IllegalArgumentException");
    } on IllegalArgumentException catch (exception) {
      // Expected
    }
  }

  void test_findCycleContaining_singleton() {
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node3 = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    graph.addEdge(node1, node2);
    graph.addEdge(node2, node3);
    List<DirectedGraphTest_Node> cycle = graph.findCycleContaining(node1);
    expect(cycle, hasLength(1));
    expect(cycle[0], node1);
  }

  void test_getNodeCount() {
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    expect(graph.nodeCount, 0);
    graph.addNode(node1);
    expect(graph.nodeCount, 1);
    graph.addNode(node2);
    expect(graph.nodeCount, 2);
    graph.removeNode(node1);
    expect(graph.nodeCount, 1);
  }

  void test_getTails() {
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node3 = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    expect(graph.getTails(node1), hasLength(0));
    graph.addEdge(node1, node2);
    expect(graph.getTails(node1), hasLength(1));
    graph.addEdge(node1, node3);
    expect(graph.getTails(node1), hasLength(2));
  }

  void test_removeAllNodes() {
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    List<DirectedGraphTest_Node> nodes = new List<DirectedGraphTest_Node>();
    nodes.add(node1);
    nodes.add(node2);
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    graph.addEdge(node1, node2);
    graph.addEdge(node2, node1);
    expect(graph.isEmpty, isFalse);
    graph.removeAllNodes(nodes);
    expect(graph.isEmpty, isTrue);
  }

  void test_removeEdge() {
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node3 = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    graph.addEdge(node1, node2);
    graph.addEdge(node1, node3);
    expect(graph.getTails(node1), hasLength(2));
    graph.removeEdge(node1, node2);
    expect(graph.getTails(node1), hasLength(1));
  }

  void test_removeNode() {
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node3 = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    graph.addEdge(node1, node2);
    graph.addEdge(node1, node3);
    expect(graph.getTails(node1), hasLength(2));
    graph.removeNode(node2);
    expect(graph.getTails(node1), hasLength(1));
  }

  void test_removeSink() {
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    graph.addEdge(node1, node2);
    expect(graph.removeSink(), same(node2));
    expect(graph.removeSink(), same(node1));
    expect(graph.isEmpty, isTrue);
  }

  void test_topologicalSort_noCycles() {
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node3 = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    graph.addEdge(node1, node2);
    graph.addEdge(node1, node3);
    graph.addEdge(node2, node3);
    List<List<DirectedGraphTest_Node>> topologicalSort =
        graph.computeTopologicalSort();
    expect(topologicalSort, hasLength(3));
    expect(topologicalSort[0], hasLength(1));
    expect(topologicalSort[0][0], node3);
    expect(topologicalSort[1], hasLength(1));
    expect(topologicalSort[1][0], node2);
    expect(topologicalSort[2], hasLength(1));
    expect(topologicalSort[2][0], node1);
  }

  void test_topologicalSort_withCycles() {
    DirectedGraphTest_Node node1 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node2 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node3 = new DirectedGraphTest_Node();
    DirectedGraphTest_Node node4 = new DirectedGraphTest_Node();
    DirectedGraph<DirectedGraphTest_Node> graph =
        new DirectedGraph<DirectedGraphTest_Node>();
    graph.addEdge(node1, node2);
    graph.addEdge(node2, node1);
    graph.addEdge(node1, node3);
    graph.addEdge(node3, node4);
    graph.addEdge(node4, node3);
    List<List<DirectedGraphTest_Node>> topologicalSort =
        graph.computeTopologicalSort();
    expect(topologicalSort, hasLength(2));
    expect(topologicalSort[0], unorderedEquals([node3, node4]));
    expect(topologicalSort[1], unorderedEquals([node1, node2]));
  }
}

/**
 * Instances of the class `Node` represent simple nodes used for testing purposes.
 */
class DirectedGraphTest_Node {
}

class Getter_NodeReplacerTest_test_annotation implements NodeReplacerTest_Getter
    {
  @override
  ArgumentList get(Annotation node) => node.arguments;
}

class Getter_NodeReplacerTest_test_annotation_2 implements
    NodeReplacerTest_Getter {
  @override
  Identifier get(Annotation node) => node.name;
}

class Getter_NodeReplacerTest_test_annotation_3 implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(Annotation node) => node.constructorName;
}

class Getter_NodeReplacerTest_test_asExpression implements
    NodeReplacerTest_Getter {
  @override
  TypeName get(AsExpression node) => node.type;
}

class Getter_NodeReplacerTest_test_asExpression_2 implements
    NodeReplacerTest_Getter {
  @override
  Expression get(AsExpression node) => node.expression;
}

class Getter_NodeReplacerTest_test_assertStatement implements
    NodeReplacerTest_Getter {
  @override
  Expression get(AssertStatement node) => node.condition;
}

class Getter_NodeReplacerTest_test_assignmentExpression implements
    NodeReplacerTest_Getter {
  @override
  Expression get(AssignmentExpression node) => node.rightHandSide;
}

class Getter_NodeReplacerTest_test_assignmentExpression_2 implements
    NodeReplacerTest_Getter {
  @override
  Expression get(AssignmentExpression node) => node.leftHandSide;
}

class Getter_NodeReplacerTest_test_binaryExpression implements
    NodeReplacerTest_Getter {
  @override
  Expression get(BinaryExpression node) => node.leftOperand;
}

class Getter_NodeReplacerTest_test_binaryExpression_2 implements
    NodeReplacerTest_Getter {
  @override
  Expression get(BinaryExpression node) => node.rightOperand;
}

class Getter_NodeReplacerTest_test_blockFunctionBody implements
    NodeReplacerTest_Getter {
  @override
  Block get(BlockFunctionBody node) => node.block;
}

class Getter_NodeReplacerTest_test_breakStatement implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(BreakStatement node) => node.label;
}

class Getter_NodeReplacerTest_test_cascadeExpression implements
    NodeReplacerTest_Getter {
  @override
  Expression get(CascadeExpression node) => node.target;
}

class Getter_NodeReplacerTest_test_catchClause implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(CatchClause node) => node.stackTraceParameter;
}

class Getter_NodeReplacerTest_test_catchClause_2 implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(CatchClause node) => node.exceptionParameter;
}

class Getter_NodeReplacerTest_test_catchClause_3 implements
    NodeReplacerTest_Getter {
  @override
  TypeName get(CatchClause node) => node.exceptionType;
}

class Getter_NodeReplacerTest_test_classDeclaration implements
    NodeReplacerTest_Getter {
  @override
  ImplementsClause get(ClassDeclaration node) => node.implementsClause;
}

class Getter_NodeReplacerTest_test_classDeclaration_2 implements
    NodeReplacerTest_Getter {
  @override
  WithClause get(ClassDeclaration node) => node.withClause;
}

class Getter_NodeReplacerTest_test_classDeclaration_3 implements
    NodeReplacerTest_Getter {
  @override
  NativeClause get(ClassDeclaration node) => node.nativeClause;
}

class Getter_NodeReplacerTest_test_classDeclaration_4 implements
    NodeReplacerTest_Getter {
  @override
  ExtendsClause get(ClassDeclaration node) => node.extendsClause;
}

class Getter_NodeReplacerTest_test_classDeclaration_5 implements
    NodeReplacerTest_Getter {
  @override
  TypeParameterList get(ClassDeclaration node) => node.typeParameters;
}

class Getter_NodeReplacerTest_test_classDeclaration_6 implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(ClassDeclaration node) => node.name;
}

class Getter_NodeReplacerTest_test_classTypeAlias implements
    NodeReplacerTest_Getter {
  @override
  TypeName get(ClassTypeAlias node) => node.superclass;
}

class Getter_NodeReplacerTest_test_classTypeAlias_2 implements
    NodeReplacerTest_Getter {
  @override
  ImplementsClause get(ClassTypeAlias node) => node.implementsClause;
}

class Getter_NodeReplacerTest_test_classTypeAlias_3 implements
    NodeReplacerTest_Getter {
  @override
  WithClause get(ClassTypeAlias node) => node.withClause;
}

class Getter_NodeReplacerTest_test_classTypeAlias_4 implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(ClassTypeAlias node) => node.name;
}

class Getter_NodeReplacerTest_test_classTypeAlias_5 implements
    NodeReplacerTest_Getter {
  @override
  TypeParameterList get(ClassTypeAlias node) => node.typeParameters;
}

class Getter_NodeReplacerTest_test_commentReference implements
    NodeReplacerTest_Getter {
  @override
  Identifier get(CommentReference node) => node.identifier;
}

class Getter_NodeReplacerTest_test_compilationUnit implements
    NodeReplacerTest_Getter {
  @override
  ScriptTag get(CompilationUnit node) => node.scriptTag;
}

class Getter_NodeReplacerTest_test_conditionalExpression implements
    NodeReplacerTest_Getter {
  @override
  Expression get(ConditionalExpression node) => node.elseExpression;
}

class Getter_NodeReplacerTest_test_conditionalExpression_2 implements
    NodeReplacerTest_Getter {
  @override
  Expression get(ConditionalExpression node) => node.thenExpression;
}

class Getter_NodeReplacerTest_test_conditionalExpression_3 implements
    NodeReplacerTest_Getter {
  @override
  Expression get(ConditionalExpression node) => node.condition;
}

class Getter_NodeReplacerTest_test_constructorDeclaration implements
    NodeReplacerTest_Getter {
  @override
  ConstructorName get(ConstructorDeclaration node) =>
      node.redirectedConstructor;
}

class Getter_NodeReplacerTest_test_constructorDeclaration_2 implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(ConstructorDeclaration node) => node.name;
}

class Getter_NodeReplacerTest_test_constructorDeclaration_3 implements
    NodeReplacerTest_Getter {
  @override
  Identifier get(ConstructorDeclaration node) => node.returnType;
}

class Getter_NodeReplacerTest_test_constructorDeclaration_4 implements
    NodeReplacerTest_Getter {
  @override
  FormalParameterList get(ConstructorDeclaration node) => node.parameters;
}

class Getter_NodeReplacerTest_test_constructorDeclaration_5 implements
    NodeReplacerTest_Getter {
  @override
  FunctionBody get(ConstructorDeclaration node) => node.body;
}

class Getter_NodeReplacerTest_test_constructorFieldInitializer implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(ConstructorFieldInitializer node) => node.fieldName;
}

class Getter_NodeReplacerTest_test_constructorFieldInitializer_2 implements
    NodeReplacerTest_Getter {
  @override
  Expression get(ConstructorFieldInitializer node) => node.expression;
}

class Getter_NodeReplacerTest_test_constructorName implements
    NodeReplacerTest_Getter {
  @override
  TypeName get(ConstructorName node) => node.type;
}

class Getter_NodeReplacerTest_test_constructorName_2 implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(ConstructorName node) => node.name;
}

class Getter_NodeReplacerTest_test_continueStatement implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(ContinueStatement node) => node.label;
}

class Getter_NodeReplacerTest_test_declaredIdentifier implements
    NodeReplacerTest_Getter {
  @override
  TypeName get(DeclaredIdentifier node) => node.type;
}

class Getter_NodeReplacerTest_test_declaredIdentifier_2 implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(DeclaredIdentifier node) => node.identifier;
}

class Getter_NodeReplacerTest_test_defaultFormalParameter implements
    NodeReplacerTest_Getter {
  @override
  NormalFormalParameter get(DefaultFormalParameter node) => node.parameter;
}

class Getter_NodeReplacerTest_test_defaultFormalParameter_2 implements
    NodeReplacerTest_Getter {
  @override
  Expression get(DefaultFormalParameter node) => node.defaultValue;
}

class Getter_NodeReplacerTest_test_doStatement implements
    NodeReplacerTest_Getter {
  @override
  Expression get(DoStatement node) => node.condition;
}

class Getter_NodeReplacerTest_test_doStatement_2 implements
    NodeReplacerTest_Getter {
  @override
  Statement get(DoStatement node) => node.body;
}

class Getter_NodeReplacerTest_test_enumConstantDeclaration implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(EnumConstantDeclaration node) => node.name;
}

class Getter_NodeReplacerTest_test_enumDeclaration implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(EnumDeclaration node) => node.name;
}

class Getter_NodeReplacerTest_test_expressionFunctionBody implements
    NodeReplacerTest_Getter {
  @override
  Expression get(ExpressionFunctionBody node) => node.expression;
}

class Getter_NodeReplacerTest_test_expressionStatement implements
    NodeReplacerTest_Getter {
  @override
  Expression get(ExpressionStatement node) => node.expression;
}

class Getter_NodeReplacerTest_test_extendsClause implements
    NodeReplacerTest_Getter {
  @override
  TypeName get(ExtendsClause node) => node.superclass;
}

class Getter_NodeReplacerTest_test_fieldDeclaration implements
    NodeReplacerTest_Getter {
  @override
  VariableDeclarationList get(FieldDeclaration node) => node.fields;
}

class Getter_NodeReplacerTest_test_fieldFormalParameter implements
    NodeReplacerTest_Getter {
  @override
  FormalParameterList get(FieldFormalParameter node) => node.parameters;
}

class Getter_NodeReplacerTest_test_fieldFormalParameter_2 implements
    NodeReplacerTest_Getter {
  @override
  TypeName get(FieldFormalParameter node) => node.type;
}

class Getter_NodeReplacerTest_test_forEachStatement_withIdentifier implements
    NodeReplacerTest_Getter {
  @override
  Statement get(ForEachStatement node) => node.body;
}

class Getter_NodeReplacerTest_test_forEachStatement_withIdentifier_2 implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(ForEachStatement node) => node.identifier;
}

class Getter_NodeReplacerTest_test_forEachStatement_withIdentifier_3 implements
    NodeReplacerTest_Getter {
  @override
  Expression get(ForEachStatement node) => node.iterable;
}

class Getter_NodeReplacerTest_test_forEachStatement_withLoopVariable implements
    NodeReplacerTest_Getter {
  @override
  Expression get(ForEachStatement node) => node.iterable;
}

class Getter_NodeReplacerTest_test_forEachStatement_withLoopVariable_2
    implements NodeReplacerTest_Getter {
  @override
  DeclaredIdentifier get(ForEachStatement node) => node.loopVariable;
}

class Getter_NodeReplacerTest_test_forEachStatement_withLoopVariable_3
    implements NodeReplacerTest_Getter {
  @override
  Statement get(ForEachStatement node) => node.body;
}

class Getter_NodeReplacerTest_test_forStatement_withInitialization implements
    NodeReplacerTest_Getter {
  @override
  Statement get(ForStatement node) => node.body;
}

class Getter_NodeReplacerTest_test_forStatement_withInitialization_2 implements
    NodeReplacerTest_Getter {
  @override
  Expression get(ForStatement node) => node.condition;
}

class Getter_NodeReplacerTest_test_forStatement_withInitialization_3 implements
    NodeReplacerTest_Getter {
  @override
  Expression get(ForStatement node) => node.initialization;
}

class Getter_NodeReplacerTest_test_forStatement_withVariables implements
    NodeReplacerTest_Getter {
  @override
  Statement get(ForStatement node) => node.body;
}

class Getter_NodeReplacerTest_test_forStatement_withVariables_2 implements
    NodeReplacerTest_Getter {
  @override
  VariableDeclarationList get(ForStatement node) => node.variables;
}

class Getter_NodeReplacerTest_test_forStatement_withVariables_3 implements
    NodeReplacerTest_Getter {
  @override
  Expression get(ForStatement node) => node.condition;
}

class Getter_NodeReplacerTest_test_functionDeclaration implements
    NodeReplacerTest_Getter {
  @override
  TypeName get(FunctionDeclaration node) => node.returnType;
}

class Getter_NodeReplacerTest_test_functionDeclaration_2 implements
    NodeReplacerTest_Getter {
  @override
  FunctionExpression get(FunctionDeclaration node) => node.functionExpression;
}

class Getter_NodeReplacerTest_test_functionDeclaration_3 implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(FunctionDeclaration node) => node.name;
}

class Getter_NodeReplacerTest_test_functionDeclarationStatement implements
    NodeReplacerTest_Getter {
  @override
  FunctionDeclaration get(FunctionDeclarationStatement node) =>
      node.functionDeclaration;
}

class Getter_NodeReplacerTest_test_functionExpression implements
    NodeReplacerTest_Getter {
  @override
  FormalParameterList get(FunctionExpression node) => node.parameters;
}

class Getter_NodeReplacerTest_test_functionExpression_2 implements
    NodeReplacerTest_Getter {
  @override
  FunctionBody get(FunctionExpression node) => node.body;
}

class Getter_NodeReplacerTest_test_functionExpressionInvocation implements
    NodeReplacerTest_Getter {
  @override
  Expression get(FunctionExpressionInvocation node) => node.function;
}

class Getter_NodeReplacerTest_test_functionExpressionInvocation_2 implements
    NodeReplacerTest_Getter {
  @override
  ArgumentList get(FunctionExpressionInvocation node) => node.argumentList;
}

class Getter_NodeReplacerTest_test_functionTypeAlias implements
    NodeReplacerTest_Getter {
  @override
  TypeParameterList get(FunctionTypeAlias node) => node.typeParameters;
}

class Getter_NodeReplacerTest_test_functionTypeAlias_2 implements
    NodeReplacerTest_Getter {
  @override
  FormalParameterList get(FunctionTypeAlias node) => node.parameters;
}

class Getter_NodeReplacerTest_test_functionTypeAlias_3 implements
    NodeReplacerTest_Getter {
  @override
  TypeName get(FunctionTypeAlias node) => node.returnType;
}

class Getter_NodeReplacerTest_test_functionTypeAlias_4 implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(FunctionTypeAlias node) => node.name;
}

class Getter_NodeReplacerTest_test_functionTypedFormalParameter implements
    NodeReplacerTest_Getter {
  @override
  TypeName get(FunctionTypedFormalParameter node) => node.returnType;
}

class Getter_NodeReplacerTest_test_functionTypedFormalParameter_2 implements
    NodeReplacerTest_Getter {
  @override
  FormalParameterList get(FunctionTypedFormalParameter node) => node.parameters;
}

class Getter_NodeReplacerTest_test_ifStatement implements
    NodeReplacerTest_Getter {
  @override
  Expression get(IfStatement node) => node.condition;
}

class Getter_NodeReplacerTest_test_ifStatement_2 implements
    NodeReplacerTest_Getter {
  @override
  Statement get(IfStatement node) => node.elseStatement;
}

class Getter_NodeReplacerTest_test_ifStatement_3 implements
    NodeReplacerTest_Getter {
  @override
  Statement get(IfStatement node) => node.thenStatement;
}

class Getter_NodeReplacerTest_test_importDirective implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(ImportDirective node) => node.prefix;
}

class Getter_NodeReplacerTest_test_indexExpression implements
    NodeReplacerTest_Getter {
  @override
  Expression get(IndexExpression node) => node.target;
}

class Getter_NodeReplacerTest_test_indexExpression_2 implements
    NodeReplacerTest_Getter {
  @override
  Expression get(IndexExpression node) => node.index;
}

class Getter_NodeReplacerTest_test_instanceCreationExpression implements
    NodeReplacerTest_Getter {
  @override
  ArgumentList get(InstanceCreationExpression node) => node.argumentList;
}

class Getter_NodeReplacerTest_test_instanceCreationExpression_2 implements
    NodeReplacerTest_Getter {
  @override
  ConstructorName get(InstanceCreationExpression node) => node.constructorName;
}

class Getter_NodeReplacerTest_test_interpolationExpression implements
    NodeReplacerTest_Getter {
  @override
  Expression get(InterpolationExpression node) => node.expression;
}

class Getter_NodeReplacerTest_test_isExpression implements
    NodeReplacerTest_Getter {
  @override
  Expression get(IsExpression node) => node.expression;
}

class Getter_NodeReplacerTest_test_isExpression_2 implements
    NodeReplacerTest_Getter {
  @override
  TypeName get(IsExpression node) => node.type;
}

class Getter_NodeReplacerTest_test_label implements NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(Label node) => node.label;
}

class Getter_NodeReplacerTest_test_labeledStatement implements
    NodeReplacerTest_Getter {
  @override
  Statement get(LabeledStatement node) => node.statement;
}

class Getter_NodeReplacerTest_test_libraryDirective implements
    NodeReplacerTest_Getter {
  @override
  LibraryIdentifier get(LibraryDirective node) => node.name;
}

class Getter_NodeReplacerTest_test_mapLiteralEntry implements
    NodeReplacerTest_Getter {
  @override
  Expression get(MapLiteralEntry node) => node.value;
}

class Getter_NodeReplacerTest_test_mapLiteralEntry_2 implements
    NodeReplacerTest_Getter {
  @override
  Expression get(MapLiteralEntry node) => node.key;
}

class Getter_NodeReplacerTest_test_methodDeclaration implements
    NodeReplacerTest_Getter {
  @override
  TypeName get(MethodDeclaration node) => node.returnType;
}

class Getter_NodeReplacerTest_test_methodDeclaration_2 implements
    NodeReplacerTest_Getter {
  @override
  FunctionBody get(MethodDeclaration node) => node.body;
}

class Getter_NodeReplacerTest_test_methodDeclaration_3 implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(MethodDeclaration node) => node.name;
}

class Getter_NodeReplacerTest_test_methodDeclaration_4 implements
    NodeReplacerTest_Getter {
  @override
  FormalParameterList get(MethodDeclaration node) => node.parameters;
}

class Getter_NodeReplacerTest_test_methodInvocation implements
    NodeReplacerTest_Getter {
  @override
  ArgumentList get(MethodInvocation node) => node.argumentList;
}

class Getter_NodeReplacerTest_test_methodInvocation_2 implements
    NodeReplacerTest_Getter {
  @override
  Expression get(MethodInvocation node) => node.target;
}

class Getter_NodeReplacerTest_test_methodInvocation_3 implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(MethodInvocation node) => node.methodName;
}

class Getter_NodeReplacerTest_test_namedExpression implements
    NodeReplacerTest_Getter {
  @override
  Label get(NamedExpression node) => node.name;
}

class Getter_NodeReplacerTest_test_namedExpression_2 implements
    NodeReplacerTest_Getter {
  @override
  Expression get(NamedExpression node) => node.expression;
}

class Getter_NodeReplacerTest_test_nativeClause implements
    NodeReplacerTest_Getter {
  @override
  StringLiteral get(NativeClause node) => node.name;
}

class Getter_NodeReplacerTest_test_nativeFunctionBody implements
    NodeReplacerTest_Getter {
  @override
  StringLiteral get(NativeFunctionBody node) => node.stringLiteral;
}

class Getter_NodeReplacerTest_test_parenthesizedExpression implements
    NodeReplacerTest_Getter {
  @override
  Expression get(ParenthesizedExpression node) => node.expression;
}

class Getter_NodeReplacerTest_test_partOfDirective implements
    NodeReplacerTest_Getter {
  @override
  LibraryIdentifier get(PartOfDirective node) => node.libraryName;
}

class Getter_NodeReplacerTest_test_postfixExpression implements
    NodeReplacerTest_Getter {
  @override
  Expression get(PostfixExpression node) => node.operand;
}

class Getter_NodeReplacerTest_test_prefixedIdentifier implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(PrefixedIdentifier node) => node.identifier;
}

class Getter_NodeReplacerTest_test_prefixedIdentifier_2 implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(PrefixedIdentifier node) => node.prefix;
}

class Getter_NodeReplacerTest_test_prefixExpression implements
    NodeReplacerTest_Getter {
  @override
  Expression get(PrefixExpression node) => node.operand;
}

class Getter_NodeReplacerTest_test_propertyAccess implements
    NodeReplacerTest_Getter {
  @override
  Expression get(PropertyAccess node) => node.target;
}

class Getter_NodeReplacerTest_test_propertyAccess_2 implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(PropertyAccess node) => node.propertyName;
}

class Getter_NodeReplacerTest_test_redirectingConstructorInvocation implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(RedirectingConstructorInvocation node) =>
      node.constructorName;
}

class Getter_NodeReplacerTest_test_redirectingConstructorInvocation_2 implements
    NodeReplacerTest_Getter {
  @override
  ArgumentList get(RedirectingConstructorInvocation node) => node.argumentList;
}

class Getter_NodeReplacerTest_test_returnStatement implements
    NodeReplacerTest_Getter {
  @override
  Expression get(ReturnStatement node) => node.expression;
}

class Getter_NodeReplacerTest_test_simpleFormalParameter implements
    NodeReplacerTest_Getter {
  @override
  TypeName get(SimpleFormalParameter node) => node.type;
}

class Getter_NodeReplacerTest_test_superConstructorInvocation implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(SuperConstructorInvocation node) => node.constructorName;
}

class Getter_NodeReplacerTest_test_superConstructorInvocation_2 implements
    NodeReplacerTest_Getter {
  @override
  ArgumentList get(SuperConstructorInvocation node) => node.argumentList;
}

class Getter_NodeReplacerTest_test_switchCase implements NodeReplacerTest_Getter
    {
  @override
  Expression get(SwitchCase node) => node.expression;
}

class Getter_NodeReplacerTest_test_switchStatement implements
    NodeReplacerTest_Getter {
  @override
  Expression get(SwitchStatement node) => node.expression;
}

class Getter_NodeReplacerTest_test_throwExpression implements
    NodeReplacerTest_Getter {
  @override
  Expression get(ThrowExpression node) => node.expression;
}

class Getter_NodeReplacerTest_test_topLevelVariableDeclaration implements
    NodeReplacerTest_Getter {
  @override
  VariableDeclarationList get(TopLevelVariableDeclaration node) =>
      node.variables;
}

class Getter_NodeReplacerTest_test_tryStatement implements
    NodeReplacerTest_Getter {
  @override
  Block get(TryStatement node) => node.finallyBlock;
}

class Getter_NodeReplacerTest_test_tryStatement_2 implements
    NodeReplacerTest_Getter {
  @override
  Block get(TryStatement node) => node.body;
}

class Getter_NodeReplacerTest_test_typeName implements NodeReplacerTest_Getter {
  @override
  TypeArgumentList get(TypeName node) => node.typeArguments;
}

class Getter_NodeReplacerTest_test_typeName_2 implements NodeReplacerTest_Getter
    {
  @override
  Identifier get(TypeName node) => node.name;
}

class Getter_NodeReplacerTest_test_typeParameter implements
    NodeReplacerTest_Getter {
  @override
  TypeName get(TypeParameter node) => node.bound;
}

class Getter_NodeReplacerTest_test_typeParameter_2 implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(TypeParameter node) => node.name;
}

class Getter_NodeReplacerTest_test_variableDeclaration implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(VariableDeclaration node) => node.name;
}

class Getter_NodeReplacerTest_test_variableDeclaration_2 implements
    NodeReplacerTest_Getter {
  @override
  Expression get(VariableDeclaration node) => node.initializer;
}

class Getter_NodeReplacerTest_test_variableDeclarationList implements
    NodeReplacerTest_Getter {
  @override
  TypeName get(VariableDeclarationList node) => node.type;
}

class Getter_NodeReplacerTest_test_variableDeclarationStatement implements
    NodeReplacerTest_Getter {
  @override
  VariableDeclarationList get(VariableDeclarationStatement node) =>
      node.variables;
}

class Getter_NodeReplacerTest_test_whileStatement implements
    NodeReplacerTest_Getter {
  @override
  Expression get(WhileStatement node) => node.condition;
}

class Getter_NodeReplacerTest_test_whileStatement_2 implements
    NodeReplacerTest_Getter {
  @override
  Statement get(WhileStatement node) => node.body;
}

class Getter_NodeReplacerTest_testAnnotatedNode implements
    NodeReplacerTest_Getter {
  @override
  Comment get(AnnotatedNode node) => node.documentationComment;
}

class Getter_NodeReplacerTest_testNormalFormalParameter implements
    NodeReplacerTest_Getter {
  @override
  SimpleIdentifier get(NormalFormalParameter node) => node.identifier;
}

class Getter_NodeReplacerTest_testNormalFormalParameter_2 implements
    NodeReplacerTest_Getter {
  @override
  Comment get(NormalFormalParameter node) => node.documentationComment;
}

class Getter_NodeReplacerTest_testTypedLiteral implements
    NodeReplacerTest_Getter {
  @override
  TypeArgumentList get(TypedLiteral node) => node.typeArguments;
}

class Getter_NodeReplacerTest_testUriBasedDirective implements
    NodeReplacerTest_Getter {
  @override
  StringLiteral get(UriBasedDirective node) => node.uri;
}

@ReflectiveTestCase()
class LineInfoTest {
  void test_creation() {
    expect(new LineInfo(<int>[0]), isNotNull);
  }

  void test_creation_empty() {
    try {
      new LineInfo(<int>[]);
      fail("Expected IllegalArgumentException");
    } on IllegalArgumentException catch (exception) {
      // Expected
    }
  }

  void test_creation_null() {
    try {
      new LineInfo(null);
      fail("Expected IllegalArgumentException");
    } on IllegalArgumentException catch (exception) {
      // Expected
    }
  }

  void test_firstLine() {
    LineInfo info = new LineInfo(<int>[0, 12, 34]);
    LineInfo_Location location = info.getLocation(4);
    expect(location.lineNumber, 1);
    expect(location.columnNumber, 5);
  }

  void test_lastLine() {
    LineInfo info = new LineInfo(<int>[0, 12, 34]);
    LineInfo_Location location = info.getLocation(36);
    expect(location.lineNumber, 3);
    expect(location.columnNumber, 3);
  }

  void test_middleLine() {
    LineInfo info = new LineInfo(<int>[0, 12, 34]);
    LineInfo_Location location = info.getLocation(12);
    expect(location.lineNumber, 2);
    expect(location.columnNumber, 1);
  }
}

class ListGetter_NodeReplacerTest_test_adjacentStrings extends
    NodeReplacerTest_ListGetter<AdjacentStrings, StringLiteral> {
  ListGetter_NodeReplacerTest_test_adjacentStrings(int arg0) : super(arg0);

  @override
  NodeList<StringLiteral> getList(AdjacentStrings node) => node.strings;
}

class ListGetter_NodeReplacerTest_test_adjacentStrings_2 extends
    NodeReplacerTest_ListGetter<AdjacentStrings, StringLiteral> {
  ListGetter_NodeReplacerTest_test_adjacentStrings_2(int arg0) : super(arg0);

  @override
  NodeList<StringLiteral> getList(AdjacentStrings node) => node.strings;
}

class ListGetter_NodeReplacerTest_test_argumentList extends
    NodeReplacerTest_ListGetter<ArgumentList, Expression> {
  ListGetter_NodeReplacerTest_test_argumentList(int arg0) : super(arg0);

  @override
  NodeList<Expression> getList(ArgumentList node) => node.arguments;
}

class ListGetter_NodeReplacerTest_test_block extends
    NodeReplacerTest_ListGetter<Block, Statement> {
  ListGetter_NodeReplacerTest_test_block(int arg0) : super(arg0);

  @override
  NodeList<Statement> getList(Block node) => node.statements;
}

class ListGetter_NodeReplacerTest_test_cascadeExpression extends
    NodeReplacerTest_ListGetter<CascadeExpression, Expression> {
  ListGetter_NodeReplacerTest_test_cascadeExpression(int arg0) : super(arg0);

  @override
  NodeList<Expression> getList(CascadeExpression node) => node.cascadeSections;
}

class ListGetter_NodeReplacerTest_test_classDeclaration extends
    NodeReplacerTest_ListGetter<ClassDeclaration, ClassMember> {
  ListGetter_NodeReplacerTest_test_classDeclaration(int arg0) : super(arg0);

  @override
  NodeList<ClassMember> getList(ClassDeclaration node) => node.members;
}

class ListGetter_NodeReplacerTest_test_comment extends
    NodeReplacerTest_ListGetter<Comment, CommentReference> {
  ListGetter_NodeReplacerTest_test_comment(int arg0) : super(arg0);

  @override
  NodeList<CommentReference> getList(Comment node) => node.references;
}

class ListGetter_NodeReplacerTest_test_compilationUnit extends
    NodeReplacerTest_ListGetter<CompilationUnit, Directive> {
  ListGetter_NodeReplacerTest_test_compilationUnit(int arg0) : super(arg0);

  @override
  NodeList<Directive> getList(CompilationUnit node) => node.directives;
}

class ListGetter_NodeReplacerTest_test_compilationUnit_2 extends
    NodeReplacerTest_ListGetter<CompilationUnit, CompilationUnitMember> {
  ListGetter_NodeReplacerTest_test_compilationUnit_2(int arg0) : super(arg0);

  @override
  NodeList<CompilationUnitMember> getList(CompilationUnit node) =>
      node.declarations;
}

class ListGetter_NodeReplacerTest_test_constructorDeclaration extends
    NodeReplacerTest_ListGetter<ConstructorDeclaration, ConstructorInitializer> {
  ListGetter_NodeReplacerTest_test_constructorDeclaration(int arg0)
      : super(arg0);

  @override
  NodeList<ConstructorInitializer> getList(ConstructorDeclaration node) =>
      node.initializers;
}

class ListGetter_NodeReplacerTest_test_formalParameterList extends
    NodeReplacerTest_ListGetter<FormalParameterList, FormalParameter> {
  ListGetter_NodeReplacerTest_test_formalParameterList(int arg0) : super(arg0);

  @override
  NodeList<FormalParameter> getList(FormalParameterList node) =>
      node.parameters;
}

class ListGetter_NodeReplacerTest_test_forStatement_withInitialization extends
    NodeReplacerTest_ListGetter<ForStatement, Expression> {
  ListGetter_NodeReplacerTest_test_forStatement_withInitialization(int arg0)
      : super(arg0);

  @override
  NodeList<Expression> getList(ForStatement node) => node.updaters;
}

class ListGetter_NodeReplacerTest_test_forStatement_withVariables extends
    NodeReplacerTest_ListGetter<ForStatement, Expression> {
  ListGetter_NodeReplacerTest_test_forStatement_withVariables(int arg0)
      : super(arg0);

  @override
  NodeList<Expression> getList(ForStatement node) => node.updaters;
}

class ListGetter_NodeReplacerTest_test_hideCombinator extends
    NodeReplacerTest_ListGetter<HideCombinator, SimpleIdentifier> {
  ListGetter_NodeReplacerTest_test_hideCombinator(int arg0) : super(arg0);

  @override
  NodeList<SimpleIdentifier> getList(HideCombinator node) => node.hiddenNames;
}

class ListGetter_NodeReplacerTest_test_implementsClause extends
    NodeReplacerTest_ListGetter<ImplementsClause, TypeName> {
  ListGetter_NodeReplacerTest_test_implementsClause(int arg0) : super(arg0);

  @override
  NodeList<TypeName> getList(ImplementsClause node) => node.interfaces;
}

class ListGetter_NodeReplacerTest_test_labeledStatement extends
    NodeReplacerTest_ListGetter<LabeledStatement, Label> {
  ListGetter_NodeReplacerTest_test_labeledStatement(int arg0) : super(arg0);

  @override
  NodeList<Label> getList(LabeledStatement node) => node.labels;
}

class ListGetter_NodeReplacerTest_test_libraryIdentifier extends
    NodeReplacerTest_ListGetter<LibraryIdentifier, SimpleIdentifier> {
  ListGetter_NodeReplacerTest_test_libraryIdentifier(int arg0) : super(arg0);

  @override
  NodeList<SimpleIdentifier> getList(LibraryIdentifier node) => node.components;
}

class ListGetter_NodeReplacerTest_test_listLiteral extends
    NodeReplacerTest_ListGetter<ListLiteral, Expression> {
  ListGetter_NodeReplacerTest_test_listLiteral(int arg0) : super(arg0);

  @override
  NodeList<Expression> getList(ListLiteral node) => node.elements;
}

class ListGetter_NodeReplacerTest_test_mapLiteral extends
    NodeReplacerTest_ListGetter<MapLiteral, MapLiteralEntry> {
  ListGetter_NodeReplacerTest_test_mapLiteral(int arg0) : super(arg0);

  @override
  NodeList<MapLiteralEntry> getList(MapLiteral node) => node.entries;
}

class ListGetter_NodeReplacerTest_test_showCombinator extends
    NodeReplacerTest_ListGetter<ShowCombinator, SimpleIdentifier> {
  ListGetter_NodeReplacerTest_test_showCombinator(int arg0) : super(arg0);

  @override
  NodeList<SimpleIdentifier> getList(ShowCombinator node) => node.shownNames;
}

class ListGetter_NodeReplacerTest_test_stringInterpolation extends
    NodeReplacerTest_ListGetter<StringInterpolation, InterpolationElement> {
  ListGetter_NodeReplacerTest_test_stringInterpolation(int arg0) : super(arg0);

  @override
  NodeList<InterpolationElement> getList(StringInterpolation node) =>
      node.elements;
}

class ListGetter_NodeReplacerTest_test_switchStatement extends
    NodeReplacerTest_ListGetter<SwitchStatement, SwitchMember> {
  ListGetter_NodeReplacerTest_test_switchStatement(int arg0) : super(arg0);

  @override
  NodeList<SwitchMember> getList(SwitchStatement node) => node.members;
}

class ListGetter_NodeReplacerTest_test_tryStatement extends
    NodeReplacerTest_ListGetter<TryStatement, CatchClause> {
  ListGetter_NodeReplacerTest_test_tryStatement(int arg0) : super(arg0);

  @override
  NodeList<CatchClause> getList(TryStatement node) => node.catchClauses;
}

class ListGetter_NodeReplacerTest_test_typeArgumentList extends
    NodeReplacerTest_ListGetter<TypeArgumentList, TypeName> {
  ListGetter_NodeReplacerTest_test_typeArgumentList(int arg0) : super(arg0);

  @override
  NodeList<TypeName> getList(TypeArgumentList node) => node.arguments;
}

class ListGetter_NodeReplacerTest_test_typeParameterList extends
    NodeReplacerTest_ListGetter<TypeParameterList, TypeParameter> {
  ListGetter_NodeReplacerTest_test_typeParameterList(int arg0) : super(arg0);

  @override
  NodeList<TypeParameter> getList(TypeParameterList node) =>
      node.typeParameters;
}

class ListGetter_NodeReplacerTest_test_variableDeclarationList extends
    NodeReplacerTest_ListGetter<VariableDeclarationList, VariableDeclaration> {
  ListGetter_NodeReplacerTest_test_variableDeclarationList(int arg0)
      : super(arg0);

  @override
  NodeList<VariableDeclaration> getList(VariableDeclarationList node) =>
      node.variables;
}

class ListGetter_NodeReplacerTest_test_withClause extends
    NodeReplacerTest_ListGetter<WithClause, TypeName> {
  ListGetter_NodeReplacerTest_test_withClause(int arg0) : super(arg0);

  @override
  NodeList<TypeName> getList(WithClause node) => node.mixinTypes;
}

class ListGetter_NodeReplacerTest_testAnnotatedNode extends
    NodeReplacerTest_ListGetter<AnnotatedNode, Annotation> {
  ListGetter_NodeReplacerTest_testAnnotatedNode(int arg0) : super(arg0);

  @override
  NodeList<Annotation> getList(AnnotatedNode node) => node.metadata;
}

class ListGetter_NodeReplacerTest_testNamespaceDirective extends
    NodeReplacerTest_ListGetter<NamespaceDirective, Combinator> {
  ListGetter_NodeReplacerTest_testNamespaceDirective(int arg0) : super(arg0);

  @override
  NodeList<Combinator> getList(NamespaceDirective node) => node.combinators;
}

class ListGetter_NodeReplacerTest_testNormalFormalParameter extends
    NodeReplacerTest_ListGetter<NormalFormalParameter, Annotation> {
  ListGetter_NodeReplacerTest_testNormalFormalParameter(int arg0) : super(arg0);

  @override
  NodeList<Annotation> getList(NormalFormalParameter node) => node.metadata;
}

class ListGetter_NodeReplacerTest_testSwitchMember extends
    NodeReplacerTest_ListGetter<SwitchMember, Label> {
  ListGetter_NodeReplacerTest_testSwitchMember(int arg0) : super(arg0);

  @override
  NodeList<Label> getList(SwitchMember node) => node.labels;
}

class ListGetter_NodeReplacerTest_testSwitchMember_2 extends
    NodeReplacerTest_ListGetter<SwitchMember, Statement> {
  ListGetter_NodeReplacerTest_testSwitchMember_2(int arg0) : super(arg0);

  @override
  NodeList<Statement> getList(SwitchMember node) => node.statements;
}

@ReflectiveTestCase()
class ListUtilitiesTest {
  void test_addAll_emptyToEmpty() {
    List<String> list = new List<String>();
    List<String> elements = <String>[];
    ListUtilities.addAll(list, elements);
    expect(list.length, 0);
  }

  void test_addAll_emptyToNonEmpty() {
    List<String> list = new List<String>();
    list.add("a");
    List<String> elements = <String>[];
    ListUtilities.addAll(list, elements);
    expect(list.length, 1);
  }

  void test_addAll_nonEmptyToEmpty() {
    List<String> list = new List<String>();
    List<String> elements = ["b", "c"];
    ListUtilities.addAll(list, elements);
    expect(list.length, 2);
  }

  void test_addAll_nonEmptyToNonEmpty() {
    List<String> list = new List<String>();
    list.add("a");
    List<String> elements = ["b", "c"];
    ListUtilities.addAll(list, elements);
    expect(list.length, 3);
  }
}

@ReflectiveTestCase()
class MultipleMapIteratorTest extends EngineTestCase {
  void test_multipleMaps_firstEmpty() {
    Map<String, String> map1 = new HashMap<String, String>();
    Map<String, String> map2 = new HashMap<String, String>();
    map2["k2"] = "v2";
    Map<String, String> map3 = new HashMap<String, String>();
    map3["k3"] = "v3";
    MultipleMapIterator<String, String> iterator =
        _iterator([map1, map2, map3]);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isFalse);
  }

  void test_multipleMaps_lastEmpty() {
    Map<String, String> map1 = new HashMap<String, String>();
    map1["k1"] = "v1";
    Map<String, String> map2 = new HashMap<String, String>();
    map2["k2"] = "v2";
    Map<String, String> map3 = new HashMap<String, String>();
    MultipleMapIterator<String, String> iterator =
        _iterator([map1, map2, map3]);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isFalse);
  }

  void test_multipleMaps_middleEmpty() {
    Map<String, String> map1 = new HashMap<String, String>();
    map1["k1"] = "v1";
    Map<String, String> map2 = new HashMap<String, String>();
    Map<String, String> map3 = new HashMap<String, String>();
    map3["k3"] = "v3";
    MultipleMapIterator<String, String> iterator =
        _iterator([map1, map2, map3]);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isFalse);
  }

  void test_multipleMaps_nonEmpty() {
    Map<String, String> map1 = new HashMap<String, String>();
    map1["k1"] = "v1";
    Map<String, String> map2 = new HashMap<String, String>();
    map2["k2"] = "v2";
    Map<String, String> map3 = new HashMap<String, String>();
    map3["k3"] = "v3";
    MultipleMapIterator<String, String> iterator =
        _iterator([map1, map2, map3]);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isFalse);
  }

  void test_noMap() {
    MultipleMapIterator<String, String> iterator = _iterator([]);
    expect(iterator.moveNext(), isFalse);
    expect(iterator.moveNext(), isFalse);
  }

  void test_singleMap_empty() {
    Map<String, String> map = new HashMap<String, String>();
    MultipleMapIterator<String, String> iterator = _iterator(<Map>[map]);
    expect(iterator.moveNext(), isFalse);
    try {
      iterator.key;
      fail("Expected NoSuchElementException");
    } on NoSuchElementException catch (exception) {
      // Expected
    }
    try {
      iterator.value;
      fail("Expected NoSuchElementException");
    } on NoSuchElementException catch (exception) {
      // Expected
    }
    try {
      iterator.value = "x";
      fail("Expected NoSuchElementException");
    } on NoSuchElementException catch (exception) {
      // Expected
    }
  }

  void test_singleMap_multiple() {
    Map<String, String> map = new HashMap<String, String>();
    map["k1"] = "v1";
    map["k2"] = "v2";
    map["k3"] = "v3";
    MultipleMapIterator<String, String> iterator = _iterator([map]);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isFalse);
  }

  void test_singleMap_single() {
    String key = "key";
    String value = "value";
    Map<String, String> map = new HashMap<String, String>();
    map[key] = value;
    MultipleMapIterator<String, String> iterator = _iterator([map]);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.key, same(key));
    expect(iterator.value, same(value));
    String newValue = "newValue";
    iterator.value = newValue;
    expect(iterator.value, same(newValue));
    expect(iterator.moveNext(), isFalse);
  }

  MultipleMapIterator<String, String> _iterator(List<Map> maps) {
    return new MultipleMapIterator<String, String>(maps);
  }
}

@ReflectiveTestCase()
class NodeReplacerTest extends EngineTestCase {
  /**
   * An empty list of tokens.
   */
  static const List<Token> EMPTY_TOKEN_LIST = const <Token>[];

  void test_adjacentStrings() {
    AdjacentStrings node =
        AstFactory.adjacentStrings([AstFactory.string2("a"), AstFactory.string2("b")]);
    _assertReplace(
        node,
        new ListGetter_NodeReplacerTest_test_adjacentStrings_2(0));
    _assertReplace(
        node,
        new ListGetter_NodeReplacerTest_test_adjacentStrings(1));
  }

  void test_annotation() {
    Annotation node = AstFactory.annotation2(
        AstFactory.identifier3("C"),
        AstFactory.identifier3("c"),
        AstFactory.argumentList([AstFactory.integer(0)]));
    _assertReplace(node, new Getter_NodeReplacerTest_test_annotation());
    _assertReplace(node, new Getter_NodeReplacerTest_test_annotation_3());
    _assertReplace(node, new Getter_NodeReplacerTest_test_annotation_2());
  }

  void test_argumentList() {
    ArgumentList node = AstFactory.argumentList([AstFactory.integer(0)]);
    _assertReplace(node, new ListGetter_NodeReplacerTest_test_argumentList(0));
  }

  void test_asExpression() {
    AsExpression node = AstFactory.asExpression(
        AstFactory.integer(0),
        AstFactory.typeName3(AstFactory.identifier3("a"), [AstFactory.typeName4("C")]));
    _assertReplace(node, new Getter_NodeReplacerTest_test_asExpression_2());
    _assertReplace(node, new Getter_NodeReplacerTest_test_asExpression());
  }

  void test_assertStatement() {
    AssertStatement node =
        AstFactory.assertStatement(AstFactory.booleanLiteral(true));
    _assertReplace(node, new Getter_NodeReplacerTest_test_assertStatement());
  }

  void test_assignmentExpression() {
    AssignmentExpression node = AstFactory.assignmentExpression(
        AstFactory.identifier3("l"),
        TokenType.EQ,
        AstFactory.identifier3("r"));
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_assignmentExpression_2());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_assignmentExpression());
  }

  void test_binaryExpression() {
    BinaryExpression node = AstFactory.binaryExpression(
        AstFactory.identifier3("l"),
        TokenType.PLUS,
        AstFactory.identifier3("r"));
    _assertReplace(node, new Getter_NodeReplacerTest_test_binaryExpression());
    _assertReplace(node, new Getter_NodeReplacerTest_test_binaryExpression_2());
  }

  void test_block() {
    Block node = AstFactory.block([AstFactory.emptyStatement()]);
    _assertReplace(node, new ListGetter_NodeReplacerTest_test_block(0));
  }

  void test_blockFunctionBody() {
    BlockFunctionBody node = AstFactory.blockFunctionBody(AstFactory.block());
    _assertReplace(node, new Getter_NodeReplacerTest_test_blockFunctionBody());
  }

  void test_breakStatement() {
    BreakStatement node = AstFactory.breakStatement2("l");
    _assertReplace(node, new Getter_NodeReplacerTest_test_breakStatement());
  }

  void test_cascadeExpression() {
    CascadeExpression node = AstFactory.cascadeExpression(
        AstFactory.integer(0),
        [AstFactory.propertyAccess(null, AstFactory.identifier3("b"))]);
    _assertReplace(node, new Getter_NodeReplacerTest_test_cascadeExpression());
    _assertReplace(
        node,
        new ListGetter_NodeReplacerTest_test_cascadeExpression(0));
  }

  void test_catchClause() {
    CatchClause node = AstFactory.catchClause5(
        AstFactory.typeName4("E"),
        "e",
        "s",
        [AstFactory.emptyStatement()]);
    _assertReplace(node, new Getter_NodeReplacerTest_test_catchClause_3());
    _assertReplace(node, new Getter_NodeReplacerTest_test_catchClause_2());
    _assertReplace(node, new Getter_NodeReplacerTest_test_catchClause());
  }

  void test_classDeclaration() {
    ClassDeclaration node = AstFactory.classDeclaration(
        null,
        "A",
        AstFactory.typeParameterList(["E"]),
        AstFactory.extendsClause(AstFactory.typeName4("B")),
        AstFactory.withClause([AstFactory.typeName4("C")]),
        AstFactory.implementsClause([AstFactory.typeName4("D")]),
        [
            AstFactory.fieldDeclaration2(
                false,
                null,
                [AstFactory.variableDeclaration("f")])]);
    node.documentationComment =
        Comment.createEndOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [AstFactory.annotation(AstFactory.identifier3("a"))];
    node.nativeClause = AstFactory.nativeClause("");
    _assertReplace(node, new Getter_NodeReplacerTest_test_classDeclaration_6());
    _assertReplace(node, new Getter_NodeReplacerTest_test_classDeclaration_5());
    _assertReplace(node, new Getter_NodeReplacerTest_test_classDeclaration_4());
    _assertReplace(node, new Getter_NodeReplacerTest_test_classDeclaration_2());
    _assertReplace(node, new Getter_NodeReplacerTest_test_classDeclaration());
    _assertReplace(node, new Getter_NodeReplacerTest_test_classDeclaration_3());
    _assertReplace(
        node,
        new ListGetter_NodeReplacerTest_test_classDeclaration(0));
    _testAnnotatedNode(node);
  }

  void test_classTypeAlias() {
    ClassTypeAlias node = AstFactory.classTypeAlias(
        "A",
        AstFactory.typeParameterList(["E"]),
        null,
        AstFactory.typeName4("B"),
        AstFactory.withClause([AstFactory.typeName4("C")]),
        AstFactory.implementsClause([AstFactory.typeName4("D")]));
    node.documentationComment =
        Comment.createEndOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [AstFactory.annotation(AstFactory.identifier3("a"))];
    _assertReplace(node, new Getter_NodeReplacerTest_test_classTypeAlias_4());
    _assertReplace(node, new Getter_NodeReplacerTest_test_classTypeAlias_5());
    _assertReplace(node, new Getter_NodeReplacerTest_test_classTypeAlias());
    _assertReplace(node, new Getter_NodeReplacerTest_test_classTypeAlias_3());
    _assertReplace(node, new Getter_NodeReplacerTest_test_classTypeAlias_2());
    _testAnnotatedNode(node);
  }

  void test_comment() {
    Comment node = Comment.createEndOfLineComment(EMPTY_TOKEN_LIST);
    node.references.add(
        new CommentReference(null, AstFactory.identifier3("x")));
    _assertReplace(node, new ListGetter_NodeReplacerTest_test_comment(0));
  }

  void test_commentReference() {
    CommentReference node =
        new CommentReference(null, AstFactory.identifier3("x"));
    _assertReplace(node, new Getter_NodeReplacerTest_test_commentReference());
  }

  void test_compilationUnit() {
    CompilationUnit node = AstFactory.compilationUnit8(
        "",
        [AstFactory.libraryDirective2("lib")],
        [
            AstFactory.topLevelVariableDeclaration2(
                null,
                [AstFactory.variableDeclaration("X")])]);
    _assertReplace(node, new Getter_NodeReplacerTest_test_compilationUnit());
    _assertReplace(
        node,
        new ListGetter_NodeReplacerTest_test_compilationUnit(0));
    _assertReplace(
        node,
        new ListGetter_NodeReplacerTest_test_compilationUnit_2(0));
  }

  void test_conditionalExpression() {
    ConditionalExpression node = AstFactory.conditionalExpression(
        AstFactory.booleanLiteral(true),
        AstFactory.integer(0),
        AstFactory.integer(1));
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_conditionalExpression_3());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_conditionalExpression_2());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_conditionalExpression());
  }

  void test_constructorDeclaration() {
    ConstructorDeclaration node = AstFactory.constructorDeclaration2(
        null,
        null,
        AstFactory.identifier3("C"),
        "d",
        AstFactory.formalParameterList(),
        [AstFactory.constructorFieldInitializer(false, "x", AstFactory.integer(0))],
        AstFactory.emptyFunctionBody());
    node.documentationComment =
        Comment.createEndOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [AstFactory.annotation(AstFactory.identifier3("a"))];
    node.redirectedConstructor =
        AstFactory.constructorName(AstFactory.typeName4("B"), "a");
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_constructorDeclaration_3());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_constructorDeclaration_2());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_constructorDeclaration_4());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_constructorDeclaration());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_constructorDeclaration_5());
    _assertReplace(
        node,
        new ListGetter_NodeReplacerTest_test_constructorDeclaration(0));
    _testAnnotatedNode(node);
  }

  void test_constructorFieldInitializer() {
    ConstructorFieldInitializer node =
        AstFactory.constructorFieldInitializer(false, "f", AstFactory.integer(0));
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_constructorFieldInitializer());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_constructorFieldInitializer_2());
  }

  void test_constructorName() {
    ConstructorName node =
        AstFactory.constructorName(AstFactory.typeName4("C"), "n");
    _assertReplace(node, new Getter_NodeReplacerTest_test_constructorName());
    _assertReplace(node, new Getter_NodeReplacerTest_test_constructorName_2());
  }

  void test_continueStatement() {
    ContinueStatement node = AstFactory.continueStatement("l");
    _assertReplace(node, new Getter_NodeReplacerTest_test_continueStatement());
  }

  void test_declaredIdentifier() {
    DeclaredIdentifier node =
        AstFactory.declaredIdentifier4(AstFactory.typeName4("C"), "i");
    node.documentationComment =
        Comment.createEndOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [AstFactory.annotation(AstFactory.identifier3("a"))];
    _assertReplace(node, new Getter_NodeReplacerTest_test_declaredIdentifier());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_declaredIdentifier_2());
    _testAnnotatedNode(node);
  }

  void test_defaultFormalParameter() {
    DefaultFormalParameter node = AstFactory.positionalFormalParameter(
        AstFactory.simpleFormalParameter3("p"),
        AstFactory.integer(0));
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_defaultFormalParameter());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_defaultFormalParameter_2());
  }

  void test_doStatement() {
    DoStatement node =
        AstFactory.doStatement(AstFactory.block(), AstFactory.booleanLiteral(true));
    _assertReplace(node, new Getter_NodeReplacerTest_test_doStatement_2());
    _assertReplace(node, new Getter_NodeReplacerTest_test_doStatement());
  }

  void test_enumConstantDeclaration() {
    EnumConstantDeclaration node = new EnumConstantDeclaration(
        Comment.createEndOfLineComment(EMPTY_TOKEN_LIST),
        [AstFactory.annotation(AstFactory.identifier3("a"))],
        AstFactory.identifier3("C"));
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_enumConstantDeclaration());
    _testAnnotatedNode(node);
  }

  void test_enumDeclaration() {
    EnumDeclaration node = AstFactory.enumDeclaration2("E", ["ONE", "TWO"]);
    node.documentationComment =
        Comment.createEndOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [AstFactory.annotation(AstFactory.identifier3("a"))];
    _assertReplace(node, new Getter_NodeReplacerTest_test_enumDeclaration());
    _testAnnotatedNode(node);
  }

  void test_exportDirective() {
    ExportDirective node =
        AstFactory.exportDirective2("", [AstFactory.hideCombinator2(["C"])]);
    node.documentationComment =
        Comment.createEndOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [AstFactory.annotation(AstFactory.identifier3("a"))];
    _testNamespaceDirective(node);
  }

  void test_expressionFunctionBody() {
    ExpressionFunctionBody node =
        AstFactory.expressionFunctionBody(AstFactory.integer(0));
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_expressionFunctionBody());
  }

  void test_expressionStatement() {
    ExpressionStatement node =
        AstFactory.expressionStatement(AstFactory.integer(0));
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_expressionStatement());
  }

  void test_extendsClause() {
    ExtendsClause node = AstFactory.extendsClause(AstFactory.typeName4("S"));
    _assertReplace(node, new Getter_NodeReplacerTest_test_extendsClause());
  }

  void test_fieldDeclaration() {
    FieldDeclaration node = AstFactory.fieldDeclaration(
        false,
        null,
        AstFactory.typeName4("C"),
        [AstFactory.variableDeclaration("c")]);
    node.documentationComment =
        Comment.createEndOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [AstFactory.annotation(AstFactory.identifier3("a"))];
    _assertReplace(node, new Getter_NodeReplacerTest_test_fieldDeclaration());
    _testAnnotatedNode(node);
  }

  void test_fieldFormalParameter() {
    FieldFormalParameter node = AstFactory.fieldFormalParameter(
        null,
        AstFactory.typeName4("C"),
        "f",
        AstFactory.formalParameterList());
    node.documentationComment =
        Comment.createEndOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [AstFactory.annotation(AstFactory.identifier3("a"))];
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_fieldFormalParameter_2());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_fieldFormalParameter());
    _testNormalFormalParameter(node);
  }

  void test_forEachStatement_withIdentifier() {
    ForEachStatement node = AstFactory.forEachStatement2(
        AstFactory.identifier3("i"),
        AstFactory.identifier3("l"),
        AstFactory.block());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_forEachStatement_withIdentifier_2());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_forEachStatement_withIdentifier_3());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_forEachStatement_withIdentifier());
  }

  void test_forEachStatement_withLoopVariable() {
    ForEachStatement node = AstFactory.forEachStatement(
        AstFactory.declaredIdentifier3("e"),
        AstFactory.identifier3("l"),
        AstFactory.block());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_forEachStatement_withLoopVariable_2());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_forEachStatement_withLoopVariable());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_forEachStatement_withLoopVariable_3());
  }

  void test_formalParameterList() {
    FormalParameterList node =
        AstFactory.formalParameterList([AstFactory.simpleFormalParameter3("p")]);
    _assertReplace(
        node,
        new ListGetter_NodeReplacerTest_test_formalParameterList(0));
  }

  void test_forStatement_withInitialization() {
    ForStatement node = AstFactory.forStatement(
        AstFactory.identifier3("a"),
        AstFactory.booleanLiteral(true),
        [AstFactory.integer(0)],
        AstFactory.block());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_forStatement_withInitialization_3());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_forStatement_withInitialization_2());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_forStatement_withInitialization());
    _assertReplace(
        node,
        new ListGetter_NodeReplacerTest_test_forStatement_withInitialization(0));
  }

  void test_forStatement_withVariables() {
    ForStatement node = AstFactory.forStatement2(
        AstFactory.variableDeclarationList2(
            null,
            [AstFactory.variableDeclaration("i")]),
        AstFactory.booleanLiteral(true),
        [AstFactory.integer(0)],
        AstFactory.block());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_forStatement_withVariables_2());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_forStatement_withVariables_3());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_forStatement_withVariables());
    _assertReplace(
        node,
        new ListGetter_NodeReplacerTest_test_forStatement_withVariables(0));
  }

  void test_functionDeclaration() {
    FunctionDeclaration node = AstFactory.functionDeclaration(
        AstFactory.typeName4("R"),
        null,
        "f",
        AstFactory.functionExpression2(
            AstFactory.formalParameterList(),
            AstFactory.blockFunctionBody(AstFactory.block())));
    node.documentationComment =
        Comment.createEndOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [AstFactory.annotation(AstFactory.identifier3("a"))];
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_functionDeclaration());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_functionDeclaration_3());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_functionDeclaration_2());
    _testAnnotatedNode(node);
  }

  void test_functionDeclarationStatement() {
    FunctionDeclarationStatement node = AstFactory.functionDeclarationStatement(
        AstFactory.typeName4("R"),
        null,
        "f",
        AstFactory.functionExpression2(
            AstFactory.formalParameterList(),
            AstFactory.blockFunctionBody(AstFactory.block())));
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_functionDeclarationStatement());
  }

  void test_functionExpression() {
    FunctionExpression node = AstFactory.functionExpression2(
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody(AstFactory.block()));
    _assertReplace(node, new Getter_NodeReplacerTest_test_functionExpression());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_functionExpression_2());
  }

  void test_functionExpressionInvocation() {
    FunctionExpressionInvocation node = AstFactory.functionExpressionInvocation(
        AstFactory.identifier3("f"),
        [AstFactory.integer(0)]);
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_functionExpressionInvocation());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_functionExpressionInvocation_2());
  }

  void test_functionTypeAlias() {
    FunctionTypeAlias node = AstFactory.typeAlias(
        AstFactory.typeName4("R"),
        "F",
        AstFactory.typeParameterList(["E"]),
        AstFactory.formalParameterList());
    node.documentationComment =
        Comment.createEndOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [AstFactory.annotation(AstFactory.identifier3("a"))];
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_functionTypeAlias_3());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_functionTypeAlias_4());
    _assertReplace(node, new Getter_NodeReplacerTest_test_functionTypeAlias());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_functionTypeAlias_2());
    _testAnnotatedNode(node);
  }

  void test_functionTypedFormalParameter() {
    FunctionTypedFormalParameter node = AstFactory.functionTypedFormalParameter(
        AstFactory.typeName4("R"),
        "f",
        [AstFactory.simpleFormalParameter3("p")]);
    node.documentationComment =
        Comment.createEndOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [AstFactory.annotation(AstFactory.identifier3("a"))];
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_functionTypedFormalParameter());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_functionTypedFormalParameter_2());
    _testNormalFormalParameter(node);
  }

  void test_hideCombinator() {
    HideCombinator node = AstFactory.hideCombinator2(["A", "B"]);
    _assertReplace(
        node,
        new ListGetter_NodeReplacerTest_test_hideCombinator(0));
  }

  void test_ifStatement() {
    IfStatement node = AstFactory.ifStatement2(
        AstFactory.booleanLiteral(true),
        AstFactory.block(),
        AstFactory.block());
    _assertReplace(node, new Getter_NodeReplacerTest_test_ifStatement());
    _assertReplace(node, new Getter_NodeReplacerTest_test_ifStatement_3());
    _assertReplace(node, new Getter_NodeReplacerTest_test_ifStatement_2());
  }

  void test_implementsClause() {
    ImplementsClause node = AstFactory.implementsClause(
        [AstFactory.typeName4("I"), AstFactory.typeName4("J")]);
    _assertReplace(
        node,
        new ListGetter_NodeReplacerTest_test_implementsClause(0));
  }

  void test_importDirective() {
    ImportDirective node = AstFactory.importDirective3(
        "",
        "p",
        [AstFactory.showCombinator2(["A"]), AstFactory.hideCombinator2(["B"])]);
    node.documentationComment =
        Comment.createEndOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [AstFactory.annotation(AstFactory.identifier3("a"))];
    _assertReplace(node, new Getter_NodeReplacerTest_test_importDirective());
    _testNamespaceDirective(node);
  }

  void test_indexExpression() {
    IndexExpression node = AstFactory.indexExpression(
        AstFactory.identifier3("a"),
        AstFactory.identifier3("i"));
    _assertReplace(node, new Getter_NodeReplacerTest_test_indexExpression());
    _assertReplace(node, new Getter_NodeReplacerTest_test_indexExpression_2());
  }

  void test_instanceCreationExpression() {
    InstanceCreationExpression node = AstFactory.instanceCreationExpression3(
        null,
        AstFactory.typeName4("C"),
        "c",
        [AstFactory.integer(2)]);
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_instanceCreationExpression_2());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_instanceCreationExpression());
  }

  void test_interpolationExpression() {
    InterpolationExpression node = AstFactory.interpolationExpression2("x");
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_interpolationExpression());
  }

  void test_isExpression() {
    IsExpression node = AstFactory.isExpression(
        AstFactory.identifier3("v"),
        false,
        AstFactory.typeName4("T"));
    _assertReplace(node, new Getter_NodeReplacerTest_test_isExpression());
    _assertReplace(node, new Getter_NodeReplacerTest_test_isExpression_2());
  }

  void test_label() {
    Label node = AstFactory.label2("l");
    _assertReplace(node, new Getter_NodeReplacerTest_test_label());
  }

  void test_labeledStatement() {
    LabeledStatement node =
        AstFactory.labeledStatement([AstFactory.label2("l")], AstFactory.block());
    _assertReplace(
        node,
        new ListGetter_NodeReplacerTest_test_labeledStatement(0));
    _assertReplace(node, new Getter_NodeReplacerTest_test_labeledStatement());
  }

  void test_libraryDirective() {
    LibraryDirective node = AstFactory.libraryDirective2("lib");
    node.documentationComment =
        Comment.createEndOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [AstFactory.annotation(AstFactory.identifier3("a"))];
    _assertReplace(node, new Getter_NodeReplacerTest_test_libraryDirective());
    _testAnnotatedNode(node);
  }

  void test_libraryIdentifier() {
    LibraryIdentifier node = AstFactory.libraryIdentifier2(["lib"]);
    _assertReplace(
        node,
        new ListGetter_NodeReplacerTest_test_libraryIdentifier(0));
  }

  void test_listLiteral() {
    ListLiteral node = AstFactory.listLiteral2(
        null,
        AstFactory.typeArgumentList([AstFactory.typeName4("E")]),
        [AstFactory.identifier3("e")]);
    _assertReplace(node, new ListGetter_NodeReplacerTest_test_listLiteral(0));
    _testTypedLiteral(node);
  }

  void test_mapLiteral() {
    MapLiteral node = AstFactory.mapLiteral(
        null,
        AstFactory.typeArgumentList([AstFactory.typeName4("E")]),
        [AstFactory.mapLiteralEntry("k", AstFactory.identifier3("v"))]);
    _assertReplace(node, new ListGetter_NodeReplacerTest_test_mapLiteral(0));
    _testTypedLiteral(node);
  }

  void test_mapLiteralEntry() {
    MapLiteralEntry node =
        AstFactory.mapLiteralEntry("k", AstFactory.identifier3("v"));
    _assertReplace(node, new Getter_NodeReplacerTest_test_mapLiteralEntry_2());
    _assertReplace(node, new Getter_NodeReplacerTest_test_mapLiteralEntry());
  }

  void test_methodDeclaration() {
    MethodDeclaration node = AstFactory.methodDeclaration2(
        null,
        AstFactory.typeName4("A"),
        null,
        null,
        AstFactory.identifier3("m"),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody(AstFactory.block()));
    node.documentationComment =
        Comment.createEndOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [AstFactory.annotation(AstFactory.identifier3("a"))];
    _assertReplace(node, new Getter_NodeReplacerTest_test_methodDeclaration());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_methodDeclaration_3());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_methodDeclaration_4());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_methodDeclaration_2());
    _testAnnotatedNode(node);
  }

  void test_methodInvocation() {
    MethodInvocation node = AstFactory.methodInvocation(
        AstFactory.identifier3("t"),
        "m",
        [AstFactory.integer(0)]);
    _assertReplace(node, new Getter_NodeReplacerTest_test_methodInvocation_2());
    _assertReplace(node, new Getter_NodeReplacerTest_test_methodInvocation_3());
    _assertReplace(node, new Getter_NodeReplacerTest_test_methodInvocation());
  }

  void test_namedExpression() {
    NamedExpression node =
        AstFactory.namedExpression2("l", AstFactory.identifier3("v"));
    _assertReplace(node, new Getter_NodeReplacerTest_test_namedExpression());
    _assertReplace(node, new Getter_NodeReplacerTest_test_namedExpression_2());
  }

  void test_nativeClause() {
    NativeClause node = AstFactory.nativeClause("");
    _assertReplace(node, new Getter_NodeReplacerTest_test_nativeClause());
  }

  void test_nativeFunctionBody() {
    NativeFunctionBody node = AstFactory.nativeFunctionBody("m");
    _assertReplace(node, new Getter_NodeReplacerTest_test_nativeFunctionBody());
  }

  void test_parenthesizedExpression() {
    ParenthesizedExpression node =
        AstFactory.parenthesizedExpression(AstFactory.integer(0));
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_parenthesizedExpression());
  }

  void test_partDirective() {
    PartDirective node = AstFactory.partDirective2("");
    node.documentationComment =
        Comment.createEndOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [AstFactory.annotation(AstFactory.identifier3("a"))];
    _testUriBasedDirective(node);
  }

  void test_partOfDirective() {
    PartOfDirective node =
        AstFactory.partOfDirective(AstFactory.libraryIdentifier2(["lib"]));
    node.documentationComment =
        Comment.createEndOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [AstFactory.annotation(AstFactory.identifier3("a"))];
    _assertReplace(node, new Getter_NodeReplacerTest_test_partOfDirective());
    _testAnnotatedNode(node);
  }

  void test_postfixExpression() {
    PostfixExpression node = AstFactory.postfixExpression(
        AstFactory.identifier3("x"),
        TokenType.MINUS_MINUS);
    _assertReplace(node, new Getter_NodeReplacerTest_test_postfixExpression());
  }

  void test_prefixedIdentifier() {
    PrefixedIdentifier node = AstFactory.identifier5("a", "b");
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_prefixedIdentifier_2());
    _assertReplace(node, new Getter_NodeReplacerTest_test_prefixedIdentifier());
  }

  void test_prefixExpression() {
    PrefixExpression node =
        AstFactory.prefixExpression(TokenType.PLUS_PLUS, AstFactory.identifier3("y"));
    _assertReplace(node, new Getter_NodeReplacerTest_test_prefixExpression());
  }

  void test_propertyAccess() {
    PropertyAccess node =
        AstFactory.propertyAccess2(AstFactory.identifier3("x"), "y");
    _assertReplace(node, new Getter_NodeReplacerTest_test_propertyAccess());
    _assertReplace(node, new Getter_NodeReplacerTest_test_propertyAccess_2());
  }

  void test_redirectingConstructorInvocation() {
    RedirectingConstructorInvocation node =
        AstFactory.redirectingConstructorInvocation2("c", [AstFactory.integer(0)]);
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_redirectingConstructorInvocation());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_redirectingConstructorInvocation_2());
  }

  void test_returnStatement() {
    ReturnStatement node = AstFactory.returnStatement2(AstFactory.integer(0));
    _assertReplace(node, new Getter_NodeReplacerTest_test_returnStatement());
  }

  void test_showCombinator() {
    ShowCombinator node = AstFactory.showCombinator2(["X", "Y"]);
    _assertReplace(
        node,
        new ListGetter_NodeReplacerTest_test_showCombinator(0));
  }

  void test_simpleFormalParameter() {
    SimpleFormalParameter node =
        AstFactory.simpleFormalParameter4(AstFactory.typeName4("T"), "p");
    node.documentationComment =
        Comment.createEndOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [AstFactory.annotation(AstFactory.identifier3("a"))];
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_simpleFormalParameter());
    _testNormalFormalParameter(node);
  }

  void test_stringInterpolation() {
    StringInterpolation node =
        AstFactory.string([AstFactory.interpolationExpression2("a")]);
    _assertReplace(
        node,
        new ListGetter_NodeReplacerTest_test_stringInterpolation(0));
  }

  void test_superConstructorInvocation() {
    SuperConstructorInvocation node =
        AstFactory.superConstructorInvocation2("s", [AstFactory.integer(1)]);
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_superConstructorInvocation());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_superConstructorInvocation_2());
  }

  void test_switchCase() {
    SwitchCase node = AstFactory.switchCase2(
        [AstFactory.label2("l")],
        AstFactory.integer(0),
        [AstFactory.block()]);
    _assertReplace(node, new Getter_NodeReplacerTest_test_switchCase());
    _testSwitchMember(node);
  }

  void test_switchDefault() {
    SwitchDefault node =
        AstFactory.switchDefault([AstFactory.label2("l")], [AstFactory.block()]);
    _testSwitchMember(node);
  }

  void test_switchStatement() {
    SwitchStatement node = AstFactory.switchStatement(
        AstFactory.identifier3("x"),
        [
            AstFactory.switchCase2(
                [AstFactory.label2("l")],
                AstFactory.integer(0),
                [AstFactory.block()]),
            AstFactory.switchDefault([AstFactory.label2("l")], [AstFactory.block()])]);
    _assertReplace(node, new Getter_NodeReplacerTest_test_switchStatement());
    _assertReplace(
        node,
        new ListGetter_NodeReplacerTest_test_switchStatement(0));
  }

  void test_throwExpression() {
    ThrowExpression node =
        AstFactory.throwExpression2(AstFactory.identifier3("e"));
    _assertReplace(node, new Getter_NodeReplacerTest_test_throwExpression());
  }

  void test_topLevelVariableDeclaration() {
    TopLevelVariableDeclaration node = AstFactory.topLevelVariableDeclaration(
        null,
        AstFactory.typeName4("T"),
        [AstFactory.variableDeclaration("t")]);
    node.documentationComment =
        Comment.createEndOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [AstFactory.annotation(AstFactory.identifier3("a"))];
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_topLevelVariableDeclaration());
    _testAnnotatedNode(node);
  }

  void test_tryStatement() {
    TryStatement node = AstFactory.tryStatement3(
        AstFactory.block(),
        [AstFactory.catchClause("e", [AstFactory.block()])],
        AstFactory.block());
    _assertReplace(node, new Getter_NodeReplacerTest_test_tryStatement_2());
    _assertReplace(node, new Getter_NodeReplacerTest_test_tryStatement());
    _assertReplace(node, new ListGetter_NodeReplacerTest_test_tryStatement(0));
  }

  void test_typeArgumentList() {
    TypeArgumentList node =
        AstFactory.typeArgumentList([AstFactory.typeName4("A")]);
    _assertReplace(
        node,
        new ListGetter_NodeReplacerTest_test_typeArgumentList(0));
  }

  void test_typeName() {
    TypeName node = AstFactory.typeName4(
        "T",
        [AstFactory.typeName4("E"), AstFactory.typeName4("F")]);
    _assertReplace(node, new Getter_NodeReplacerTest_test_typeName_2());
    _assertReplace(node, new Getter_NodeReplacerTest_test_typeName());
  }

  void test_typeParameter() {
    TypeParameter node =
        AstFactory.typeParameter2("E", AstFactory.typeName4("B"));
    _assertReplace(node, new Getter_NodeReplacerTest_test_typeParameter_2());
    _assertReplace(node, new Getter_NodeReplacerTest_test_typeParameter());
  }

  void test_typeParameterList() {
    TypeParameterList node = AstFactory.typeParameterList(["A", "B"]);
    _assertReplace(
        node,
        new ListGetter_NodeReplacerTest_test_typeParameterList(0));
  }

  void test_variableDeclaration() {
    VariableDeclaration node =
        AstFactory.variableDeclaration2("a", AstFactory.nullLiteral());
    node.documentationComment =
        Comment.createEndOfLineComment(EMPTY_TOKEN_LIST);
    node.metadata = [AstFactory.annotation(AstFactory.identifier3("a"))];
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_variableDeclaration());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_variableDeclaration_2());
    _testAnnotatedNode(node);
  }

  void test_variableDeclarationList() {
    VariableDeclarationList node = AstFactory.variableDeclarationList(
        null,
        AstFactory.typeName4("T"),
        [AstFactory.variableDeclaration("a")]);
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_variableDeclarationList());
    _assertReplace(
        node,
        new ListGetter_NodeReplacerTest_test_variableDeclarationList(0));
  }

  void test_variableDeclarationStatement() {
    VariableDeclarationStatement node = AstFactory.variableDeclarationStatement(
        null,
        AstFactory.typeName4("T"),
        [AstFactory.variableDeclaration("a")]);
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_test_variableDeclarationStatement());
  }

  void test_whileStatement() {
    WhileStatement node =
        AstFactory.whileStatement(AstFactory.booleanLiteral(true), AstFactory.block());
    _assertReplace(node, new Getter_NodeReplacerTest_test_whileStatement());
    _assertReplace(node, new Getter_NodeReplacerTest_test_whileStatement_2());
  }

  void test_withClause() {
    WithClause node = AstFactory.withClause([AstFactory.typeName4("M")]);
    _assertReplace(node, new ListGetter_NodeReplacerTest_test_withClause(0));
  }

  void _assertReplace(AstNode parent, NodeReplacerTest_Getter getter) {
    AstNode child = getter.get(parent);
    if (child != null) {
      AstNode clone = child.accept(new AstCloner());
      NodeReplacer.replace(child, clone);
      expect(getter.get(parent), clone);
      expect(clone.parent, parent);
    }
  }

  void _testAnnotatedNode(AnnotatedNode node) {
    _assertReplace(node, new Getter_NodeReplacerTest_testAnnotatedNode());
    _assertReplace(node, new ListGetter_NodeReplacerTest_testAnnotatedNode(0));
  }

  void _testNamespaceDirective(NamespaceDirective node) {
    _assertReplace(
        node,
        new ListGetter_NodeReplacerTest_testNamespaceDirective(0));
    _testUriBasedDirective(node);
  }

  void _testNormalFormalParameter(NormalFormalParameter node) {
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_testNormalFormalParameter_2());
    _assertReplace(
        node,
        new Getter_NodeReplacerTest_testNormalFormalParameter());
    _assertReplace(
        node,
        new ListGetter_NodeReplacerTest_testNormalFormalParameter(0));
  }

  void _testSwitchMember(SwitchMember node) {
    _assertReplace(node, new ListGetter_NodeReplacerTest_testSwitchMember(0));
    _assertReplace(node, new ListGetter_NodeReplacerTest_testSwitchMember_2(0));
  }

  void _testTypedLiteral(TypedLiteral node) {
    _assertReplace(node, new Getter_NodeReplacerTest_testTypedLiteral());
  }

  void _testUriBasedDirective(UriBasedDirective node) {
    _assertReplace(node, new Getter_NodeReplacerTest_testUriBasedDirective());
    _testAnnotatedNode(node);
  }
}

abstract class NodeReplacerTest_Getter<P, C> {
  C get(P parent);
}

abstract class NodeReplacerTest_ListGetter<P extends AstNode, C extends AstNode>
    implements NodeReplacerTest_Getter<P, C> {
  final int _index;

  NodeReplacerTest_ListGetter(this._index);

  @override
  C get(P parent) {
    NodeList<C> list = getList(parent);
    if (list.isEmpty) {
      return null;
    }
    return list[_index];
  }

  NodeList<C> getList(P parent);
}

@ReflectiveTestCase()
class SingleMapIteratorTest extends EngineTestCase {
  void test_empty() {
    Map<String, String> map = new HashMap<String, String>();
    SingleMapIterator<String, String> iterator =
        new SingleMapIterator<String, String>(map);
    expect(iterator.moveNext(), isFalse);
    try {
      iterator.key;
      fail("Expected NoSuchElementException");
    } on NoSuchElementException catch (exception) {
      // Expected
    }
    try {
      iterator.value;
      fail("Expected NoSuchElementException");
    } on NoSuchElementException catch (exception) {
      // Expected
    }
    try {
      iterator.value = "x";
      fail("Expected NoSuchElementException");
    } on NoSuchElementException catch (exception) {
      // Expected
    }
    expect(iterator.moveNext(), isFalse);
  }

  void test_multiple() {
    Map<String, String> map = new HashMap<String, String>();
    map["k1"] = "v1";
    map["k2"] = "v2";
    map["k3"] = "v3";
    SingleMapIterator<String, String> iterator =
        new SingleMapIterator<String, String>(map);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.moveNext(), isFalse);
  }

  void test_single() {
    String key = "key";
    String value = "value";
    Map<String, String> map = new HashMap<String, String>();
    map[key] = value;
    SingleMapIterator<String, String> iterator =
        new SingleMapIterator<String, String>(map);
    expect(iterator.moveNext(), isTrue);
    expect(iterator.key, same(key));
    expect(iterator.value, same(value));
    String newValue = "newValue";
    iterator.value = newValue;
    expect(iterator.value, same(newValue));
    expect(iterator.moveNext(), isFalse);
  }
}

@ReflectiveTestCase()
class SourceRangeTest {
  void test_access() {
    SourceRange r = new SourceRange(10, 1);
    expect(r.offset, 10);
    expect(r.length, 1);
    expect(r.end, 10 + 1);
    // to check
    r.hashCode;
  }

  void test_contains() {
    SourceRange r = new SourceRange(5, 10);
    expect(r.contains(5), isTrue);
    expect(r.contains(10), isTrue);
    expect(r.contains(14), isTrue);
    expect(r.contains(0), isFalse);
    expect(r.contains(15), isFalse);
  }

  void test_containsExclusive() {
    SourceRange r = new SourceRange(5, 10);
    expect(r.containsExclusive(5), isFalse);
    expect(r.containsExclusive(10), isTrue);
    expect(r.containsExclusive(14), isTrue);
    expect(r.containsExclusive(0), isFalse);
    expect(r.containsExclusive(15), isFalse);
  }

  void test_coveredBy() {
    SourceRange r = new SourceRange(5, 10);
    // ends before
    expect(r.coveredBy(new SourceRange(20, 10)), isFalse);
    // starts after
    expect(r.coveredBy(new SourceRange(0, 3)), isFalse);
    // only intersects
    expect(r.coveredBy(new SourceRange(0, 10)), isFalse);
    expect(r.coveredBy(new SourceRange(10, 10)), isFalse);
    // covered
    expect(r.coveredBy(new SourceRange(0, 20)), isTrue);
    expect(r.coveredBy(new SourceRange(5, 10)), isTrue);
  }

  void test_covers() {
    SourceRange r = new SourceRange(5, 10);
    // ends before
    expect(r.covers(new SourceRange(0, 3)), isFalse);
    // starts after
    expect(r.covers(new SourceRange(20, 3)), isFalse);
    // only intersects
    expect(r.covers(new SourceRange(0, 10)), isFalse);
    expect(r.covers(new SourceRange(10, 10)), isFalse);
    // covers
    expect(r.covers(new SourceRange(5, 10)), isTrue);
    expect(r.covers(new SourceRange(6, 9)), isTrue);
    expect(r.covers(new SourceRange(6, 8)), isTrue);
  }

  void test_endsIn() {
    SourceRange r = new SourceRange(5, 10);
    // ends before
    expect(r.endsIn(new SourceRange(20, 10)), isFalse);
    // starts after
    expect(r.endsIn(new SourceRange(0, 3)), isFalse);
    // ends
    expect(r.endsIn(new SourceRange(10, 20)), isTrue);
    expect(r.endsIn(new SourceRange(0, 20)), isTrue);
  }

  void test_equals() {
    SourceRange r = new SourceRange(10, 1);
    expect(r == null, isFalse);
    expect(r == this, isFalse);
    expect(r == new SourceRange(20, 2), isFalse);
    expect(r == new SourceRange(10, 1), isTrue);
    expect(r == r, isTrue);
  }

  void test_getExpanded() {
    SourceRange r = new SourceRange(5, 3);
    expect(r.getExpanded(0), r);
    expect(r.getExpanded(2), new SourceRange(3, 7));
    expect(r.getExpanded(-1), new SourceRange(6, 1));
  }

  void test_getMoveEnd() {
    SourceRange r = new SourceRange(5, 3);
    expect(r.getMoveEnd(0), r);
    expect(r.getMoveEnd(3), new SourceRange(5, 6));
    expect(r.getMoveEnd(-1), new SourceRange(5, 2));
  }

  void test_getTranslated() {
    SourceRange r = new SourceRange(5, 3);
    expect(r.getTranslated(0), r);
    expect(r.getTranslated(2), new SourceRange(7, 3));
    expect(r.getTranslated(-1), new SourceRange(4, 3));
  }

  void test_getUnion() {
    expect(
        new SourceRange(10, 10).getUnion(new SourceRange(15, 10)),
        new SourceRange(10, 15));
    expect(
        new SourceRange(15, 10).getUnion(new SourceRange(10, 10)),
        new SourceRange(10, 15));
    // "other" is covered/covers
    expect(
        new SourceRange(10, 10).getUnion(new SourceRange(15, 2)),
        new SourceRange(10, 10));
    expect(
        new SourceRange(15, 2).getUnion(new SourceRange(10, 10)),
        new SourceRange(10, 10));
  }

  void test_intersects() {
    SourceRange r = new SourceRange(5, 3);
    // null
    expect(r.intersects(null), isFalse);
    // ends before
    expect(r.intersects(new SourceRange(0, 5)), isFalse);
    // begins after
    expect(r.intersects(new SourceRange(8, 5)), isFalse);
    // begins on same offset
    expect(r.intersects(new SourceRange(5, 1)), isTrue);
    // begins inside, ends inside
    expect(r.intersects(new SourceRange(6, 1)), isTrue);
    // begins inside, ends after
    expect(r.intersects(new SourceRange(6, 10)), isTrue);
    // begins before, ends after
    expect(r.intersects(new SourceRange(0, 10)), isTrue);
  }

  void test_startsIn() {
    SourceRange r = new SourceRange(5, 10);
    // ends before
    expect(r.startsIn(new SourceRange(20, 10)), isFalse);
    // starts after
    expect(r.startsIn(new SourceRange(0, 3)), isFalse);
    // starts
    expect(r.startsIn(new SourceRange(5, 1)), isTrue);
    expect(r.startsIn(new SourceRange(0, 20)), isTrue);
  }

  void test_toString() {
    SourceRange r = new SourceRange(10, 1);
    expect(r.toString(), "[offset=10, length=1]");
  }
}

@ReflectiveTestCase()
class StringUtilitiesTest {
  void test_EMPTY() {
    expect(StringUtilities.EMPTY, "");
    expect(StringUtilities.EMPTY.isEmpty, isTrue);
  }

  void test_EMPTY_ARRAY() {
    expect(StringUtilities.EMPTY_ARRAY.length, 0);
  }

  void test_endsWith3() {
    expect(StringUtilities.endsWith3("abc", 0x61, 0x62, 0x63), isTrue);
    expect(StringUtilities.endsWith3("abcdefghi", 0x67, 0x68, 0x69), isTrue);
    expect(StringUtilities.endsWith3("abcdefghi", 0x64, 0x65, 0x61), isFalse);
    // missing
  }

  void test_endsWithChar() {
    expect(StringUtilities.endsWithChar("a", 0x61), isTrue);
    expect(StringUtilities.endsWithChar("b", 0x61), isFalse);
    expect(StringUtilities.endsWithChar("", 0x61), isFalse);
  }

  void test_indexOf1() {
    expect(StringUtilities.indexOf1("a", 0, 0x61), 0);
    expect(StringUtilities.indexOf1("abcdef", 0, 0x61), 0);
    expect(StringUtilities.indexOf1("abcdef", 0, 0x63), 2);
    expect(StringUtilities.indexOf1("abcdef", 0, 0x66), 5);
    expect(StringUtilities.indexOf1("abcdef", 0, 0x7A), -1);
    expect(StringUtilities.indexOf1("abcdef", 1, 0x61), -1);
    // before start
  }

  void test_indexOf2() {
    expect(StringUtilities.indexOf2("ab", 0, 0x61, 0x62), 0);
    expect(StringUtilities.indexOf2("abcdef", 0, 0x61, 0x62), 0);
    expect(StringUtilities.indexOf2("abcdef", 0, 0x63, 0x64), 2);
    expect(StringUtilities.indexOf2("abcdef", 0, 0x65, 0x66), 4);
    expect(StringUtilities.indexOf2("abcdef", 0, 0x64, 0x61), -1);
    expect(StringUtilities.indexOf2("abcdef", 1, 0x61, 0x62), -1);
    // before start
  }

  void test_indexOf4() {
    expect(StringUtilities.indexOf4("abcd", 0, 0x61, 0x62, 0x63, 0x64), 0);
    expect(StringUtilities.indexOf4("abcdefghi", 0, 0x61, 0x62, 0x63, 0x64), 0);
    expect(StringUtilities.indexOf4("abcdefghi", 0, 0x63, 0x64, 0x65, 0x66), 2);
    expect(StringUtilities.indexOf4("abcdefghi", 0, 0x66, 0x67, 0x68, 0x69), 5);
    expect(
        StringUtilities.indexOf4("abcdefghi", 0, 0x64, 0x65, 0x61, 0x64),
        -1);
    expect(
        StringUtilities.indexOf4("abcdefghi", 1, 0x61, 0x62, 0x63, 0x64),
        -1);
    // before start
  }

  void test_indexOf5() {
    expect(
        StringUtilities.indexOf5("abcde", 0, 0x61, 0x62, 0x63, 0x64, 0x65),
        0);
    expect(
        StringUtilities.indexOf5("abcdefghi", 0, 0x61, 0x62, 0x63, 0x64, 0x65),
        0);
    expect(
        StringUtilities.indexOf5("abcdefghi", 0, 0x63, 0x64, 0x65, 0x66, 0x67),
        2);
    expect(
        StringUtilities.indexOf5("abcdefghi", 0, 0x65, 0x66, 0x67, 0x68, 0x69),
        4);
    expect(
        StringUtilities.indexOf5("abcdefghi", 0, 0x64, 0x65, 0x66, 0x69, 0x6E),
        -1);
    expect(
        StringUtilities.indexOf5("abcdefghi", 1, 0x61, 0x62, 0x63, 0x64, 0x65),
        -1);
    // before start
  }

  void test_isEmpty() {
    expect(StringUtilities.isEmpty(""), isTrue);
    expect(StringUtilities.isEmpty(" "), isFalse);
    expect(StringUtilities.isEmpty("a"), isFalse);
    expect(StringUtilities.isEmpty(StringUtilities.EMPTY), isTrue);
  }

  void test_isTagName() {
    expect(StringUtilities.isTagName(null), isFalse);
    expect(StringUtilities.isTagName(""), isFalse);
    expect(StringUtilities.isTagName("-"), isFalse);
    expect(StringUtilities.isTagName("0"), isFalse);
    expect(StringUtilities.isTagName("0a"), isFalse);
    expect(StringUtilities.isTagName("a b"), isFalse);
    expect(StringUtilities.isTagName("a0"), isTrue);
    expect(StringUtilities.isTagName("a"), isTrue);
    expect(StringUtilities.isTagName("ab"), isTrue);
    expect(StringUtilities.isTagName("a-b"), isTrue);
  }

  void test_printListOfQuotedNames_empty() {
    try {
      StringUtilities.printListOfQuotedNames(new List<String>(0));
      fail("Expected IllegalArgumentException");
    } on IllegalArgumentException catch (exception) {
      // Expected
    }
  }

  void test_printListOfQuotedNames_five() {
    expect(
        StringUtilities.printListOfQuotedNames(<String>["a", "b", "c", "d", "e"]),
        "'a', 'b', 'c', 'd' and 'e'");
  }

  void test_printListOfQuotedNames_null() {
    try {
      StringUtilities.printListOfQuotedNames(null);
      fail("Expected IllegalArgumentException");
    } on IllegalArgumentException catch (exception) {
      // Expected
    }
  }

  void test_printListOfQuotedNames_one() {
    try {
      StringUtilities.printListOfQuotedNames(<String>["a"]);
      fail("Expected IllegalArgumentException");
    } on IllegalArgumentException catch (exception) {
      // Expected
    }
  }

  void test_printListOfQuotedNames_three() {
    expect(
        StringUtilities.printListOfQuotedNames(<String>["a", "b", "c"]),
        "'a', 'b' and 'c'");
  }

  void test_printListOfQuotedNames_two() {
    expect(
        StringUtilities.printListOfQuotedNames(<String>["a", "b"]),
        "'a' and 'b'");
  }

  void test_startsWith2() {
    expect(StringUtilities.startsWith2("ab", 0, 0x61, 0x62), isTrue);
    expect(StringUtilities.startsWith2("abcdefghi", 0, 0x61, 0x62), isTrue);
    expect(StringUtilities.startsWith2("abcdefghi", 2, 0x63, 0x64), isTrue);
    expect(StringUtilities.startsWith2("abcdefghi", 5, 0x66, 0x67), isTrue);
    expect(StringUtilities.startsWith2("abcdefghi", 0, 0x64, 0x64), isFalse);
    // missing
  }

  void test_startsWith3() {
    expect(StringUtilities.startsWith3("abc", 0, 0x61, 0x62, 0x63), isTrue);
    expect(
        StringUtilities.startsWith3("abcdefghi", 0, 0x61, 0x62, 0x63),
        isTrue);
    expect(
        StringUtilities.startsWith3("abcdefghi", 2, 0x63, 0x64, 0x65),
        isTrue);
    expect(
        StringUtilities.startsWith3("abcdefghi", 6, 0x67, 0x68, 0x69),
        isTrue);
    expect(
        StringUtilities.startsWith3("abcdefghi", 0, 0x64, 0x65, 0x61),
        isFalse);
    // missing
  }

  void test_startsWith4() {
    expect(
        StringUtilities.startsWith4("abcd", 0, 0x61, 0x62, 0x63, 0x64),
        isTrue);
    expect(
        StringUtilities.startsWith4("abcdefghi", 0, 0x61, 0x62, 0x63, 0x64),
        isTrue);
    expect(
        StringUtilities.startsWith4("abcdefghi", 2, 0x63, 0x64, 0x65, 0x66),
        isTrue);
    expect(
        StringUtilities.startsWith4("abcdefghi", 5, 0x66, 0x67, 0x68, 0x69),
        isTrue);
    expect(
        StringUtilities.startsWith4("abcdefghi", 0, 0x64, 0x65, 0x61, 0x64),
        isFalse);
    // missing
  }

  void test_startsWith5() {
    expect(
        StringUtilities.startsWith5("abcde", 0, 0x61, 0x62, 0x63, 0x64, 0x65),
        isTrue);
    expect(
        StringUtilities.startsWith5("abcdefghi", 0, 0x61, 0x62, 0x63, 0x64, 0x65),
        isTrue);
    expect(
        StringUtilities.startsWith5("abcdefghi", 2, 0x63, 0x64, 0x65, 0x66, 0x67),
        isTrue);
    expect(
        StringUtilities.startsWith5("abcdefghi", 4, 0x65, 0x66, 0x67, 0x68, 0x69),
        isTrue);
    expect(
        StringUtilities.startsWith5("abcdefghi", 0, 0x61, 0x62, 0x63, 0x62, 0x61),
        isFalse);
    // missing
  }

  void test_startsWith6() {
    expect(
        StringUtilities.startsWith6("abcdef", 0, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66),
        isTrue);
    expect(
        StringUtilities.startsWith6("abcdefghi", 0, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66),
        isTrue);
    expect(
        StringUtilities.startsWith6("abcdefghi", 2, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68),
        isTrue);
    expect(
        StringUtilities.startsWith6("abcdefghi", 3, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69),
        isTrue);
    expect(
        StringUtilities.startsWith6("abcdefghi", 0, 0x61, 0x62, 0x63, 0x64, 0x65, 0x67),
        isFalse);
    // missing
  }

  void test_startsWithChar() {
    expect(StringUtilities.startsWithChar("a", 0x61), isTrue);
    expect(StringUtilities.startsWithChar("b", 0x61), isFalse);
    expect(StringUtilities.startsWithChar("", 0x61), isFalse);
  }

  void test_substringBefore() {
    expect(StringUtilities.substringBefore(null, ""), null);
    expect(StringUtilities.substringBefore(null, "a"), null);
    expect(StringUtilities.substringBefore("", "a"), "");
    expect(StringUtilities.substringBefore("abc", "a"), "");
    expect(StringUtilities.substringBefore("abcba", "b"), "a");
    expect(StringUtilities.substringBefore("abc", "c"), "ab");
    expect(StringUtilities.substringBefore("abc", "d"), "abc");
    expect(StringUtilities.substringBefore("abc", ""), "");
    expect(StringUtilities.substringBefore("abc", null), "abc");
  }

  void test_substringBeforeChar() {
    expect(StringUtilities.substringBeforeChar(null, 0x61), null);
    expect(StringUtilities.substringBeforeChar("", 0x61), "");
    expect(StringUtilities.substringBeforeChar("abc", 0x61), "");
    expect(StringUtilities.substringBeforeChar("abcba", 0x62), "a");
    expect(StringUtilities.substringBeforeChar("abc", 0x63), "ab");
    expect(StringUtilities.substringBeforeChar("abc", 0x64), "abc");
  }
}


@ReflectiveTestCase()
class TokenMapTest {
  void test_creation() {
    expect(new TokenMap(), isNotNull);
  }

  void test_get_absent() {
    TokenMap tokenMap = new TokenMap();
    expect(tokenMap.get(TokenFactory.tokenFromType(TokenType.AT)), isNull);
  }

  void test_get_added() {
    TokenMap tokenMap = new TokenMap();
    Token key = TokenFactory.tokenFromType(TokenType.AT);
    Token value = TokenFactory.tokenFromType(TokenType.AT);
    tokenMap.put(key, value);
    expect(tokenMap.get(key), same(value));
  }
}
