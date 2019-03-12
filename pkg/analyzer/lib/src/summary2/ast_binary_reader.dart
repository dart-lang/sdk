// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';

/// Deserializer of fully resolved ASTs from flat buffers.
class AstBinaryReader {
  final LinkedUnitContext _unitContext;

  AstBinaryReader(this._unitContext);

  AstNode readNode(LinkedNode data) {
    if (data == null) return null;

    switch (data.kind) {
      case LinkedNodeKind.adjacentStrings:
        return _read_adjacentStrings(data);
      case LinkedNodeKind.annotation:
        return _read_annotation(data);
      case LinkedNodeKind.argumentList:
        return _read_argumentList(data);
      case LinkedNodeKind.asExpression:
        return _read_asExpression(data);
      case LinkedNodeKind.assertInitializer:
        return _read_assertInitializer(data);
      case LinkedNodeKind.assertStatement:
        return _read_assertStatement(data);
      case LinkedNodeKind.assignmentExpression:
        return _read_assignmentExpression(data);
      case LinkedNodeKind.awaitExpression:
        return _read_awaitExpression(data);
      case LinkedNodeKind.binaryExpression:
        return _read_binaryExpression(data);
      case LinkedNodeKind.block:
        return _read_block(data);
      case LinkedNodeKind.blockFunctionBody:
        return _read_blockFunctionBody(data);
      case LinkedNodeKind.booleanLiteral:
        return _read_booleanLiteral(data);
      case LinkedNodeKind.breakStatement:
        return _read_breakStatement(data);
      case LinkedNodeKind.cascadeExpression:
        return _read_cascadeExpression(data);
      case LinkedNodeKind.catchClause:
        return _read_catchClause(data);
      case LinkedNodeKind.classDeclaration:
        return _read_classDeclaration(data);
      case LinkedNodeKind.classTypeAlias:
        return _read_classTypeAlias(data);
      case LinkedNodeKind.comment:
        return _read_comment(data);
      case LinkedNodeKind.compilationUnit:
        return _read_compilationUnit(data);
      case LinkedNodeKind.conditionalExpression:
        return _read_conditionalExpression(data);
      case LinkedNodeKind.configuration:
        return _read_configuration(data);
      case LinkedNodeKind.constructorDeclaration:
        return _read_constructorDeclaration(data);
      case LinkedNodeKind.constructorFieldInitializer:
        return _read_constructorFieldInitializer(data);
      case LinkedNodeKind.constructorName:
        return _read_constructorName(data);
      case LinkedNodeKind.continueStatement:
        return _read_continueStatement(data);
      case LinkedNodeKind.declaredIdentifier:
        return _read_declaredIdentifier(data);
      case LinkedNodeKind.defaultFormalParameter:
        return _read_defaultFormalParameter(data);
      case LinkedNodeKind.doStatement:
        return _read_doStatement(data);
      case LinkedNodeKind.dottedName:
        return _read_dottedName(data);
      case LinkedNodeKind.doubleLiteral:
        return _read_doubleLiteral(data);
      case LinkedNodeKind.emptyFunctionBody:
        return _read_emptyFunctionBody(data);
      case LinkedNodeKind.emptyStatement:
        return _read_emptyStatement(data);
      case LinkedNodeKind.enumConstantDeclaration:
        return _read_enumConstantDeclaration(data);
      case LinkedNodeKind.enumDeclaration:
        return _read_enumDeclaration(data);
      case LinkedNodeKind.exportDirective:
        return _read_exportDirective(data);
      case LinkedNodeKind.expressionFunctionBody:
        return _read_expressionFunctionBody(data);
      case LinkedNodeKind.expressionStatement:
        return _read_expressionStatement(data);
      case LinkedNodeKind.extendsClause:
        return _read_extendsClause(data);
      case LinkedNodeKind.fieldDeclaration:
        return _read_fieldDeclaration(data);
      case LinkedNodeKind.fieldFormalParameter:
        return _read_fieldFormalParameter(data);
      case LinkedNodeKind.forEachPartsWithDeclaration:
        return _read_forEachPartsWithDeclaration(data);
      case LinkedNodeKind.forEachPartsWithIdentifier:
        return _read_forEachPartsWithIdentifier(data);
      case LinkedNodeKind.forElement:
        return _read_forElement(data);
      case LinkedNodeKind.forPartsWithExpression:
        return _read_forPartsWithExpression(data);
      case LinkedNodeKind.forPartsWithDeclarations:
        return _read_forPartsWithDeclarations(data);
      case LinkedNodeKind.forStatement:
        return _read_forStatement(data);
      case LinkedNodeKind.formalParameterList:
        return _read_formalParameterList(data);
      case LinkedNodeKind.functionDeclaration:
        return _read_functionDeclaration(data);
      case LinkedNodeKind.functionDeclarationStatement:
        return _read_functionDeclarationStatement(data);
      case LinkedNodeKind.functionExpression:
        return _read_functionExpression(data);
      case LinkedNodeKind.functionExpressionInvocation:
        return _read_functionExpressionInvocation(data);
      case LinkedNodeKind.functionTypeAlias:
        return _read_functionTypeAlias(data);
      case LinkedNodeKind.functionTypedFormalParameter:
        return _read_functionTypedFormalParameter(data);
      case LinkedNodeKind.genericFunctionType:
        return _read_genericFunctionType(data);
      case LinkedNodeKind.genericTypeAlias:
        return _read_genericTypeAlias(data);
      case LinkedNodeKind.hideCombinator:
        return _read_hideCombinator(data);
      case LinkedNodeKind.ifElement:
        return _read_ifElement(data);
      case LinkedNodeKind.ifStatement:
        return _read_ifStatement(data);
      case LinkedNodeKind.implementsClause:
        return _read_implementsClause(data);
      case LinkedNodeKind.importDirective:
        return _read_importDirective(data);
      case LinkedNodeKind.indexExpression:
        return _read_indexExpression(data);
      case LinkedNodeKind.instanceCreationExpression:
        return _read_instanceCreationExpression(data);
      case LinkedNodeKind.integerLiteral:
        return _read_integerLiteral(data);
      case LinkedNodeKind.interpolationString:
        return _read_interpolationString(data);
      case LinkedNodeKind.interpolationExpression:
        return _read_interpolationExpression(data);
      case LinkedNodeKind.isExpression:
        return _read_isExpression(data);
      case LinkedNodeKind.label:
        return _read_label(data);
      case LinkedNodeKind.labeledStatement:
        return _read_labeledStatement(data);
      case LinkedNodeKind.libraryDirective:
        return _read_libraryDirective(data);
      case LinkedNodeKind.libraryIdentifier:
        return _read_libraryIdentifier(data);
      case LinkedNodeKind.listLiteral:
        return _read_listLiteral(data);
      case LinkedNodeKind.mapLiteralEntry:
        return _read_mapLiteralEntry(data);
      case LinkedNodeKind.methodDeclaration:
        return _read_methodDeclaration(data);
      case LinkedNodeKind.methodInvocation:
        return _read_methodInvocation(data);
      case LinkedNodeKind.mixinDeclaration:
        return _read_mixinDeclaration(data);
      case LinkedNodeKind.namedExpression:
        return _read_namedExpression(data);
      case LinkedNodeKind.nullLiteral:
        return _read_nullLiteral(data);
      case LinkedNodeKind.onClause:
        return _read_onClause(data);
      case LinkedNodeKind.parenthesizedExpression:
        return _read_parenthesizedExpression(data);
      case LinkedNodeKind.partDirective:
        return _read_partDirective(data);
      case LinkedNodeKind.partOfDirective:
        return _read_partOfDirective(data);
      case LinkedNodeKind.postfixExpression:
        return _read_postfixExpression(data);
      case LinkedNodeKind.prefixExpression:
        return _read_prefixExpression(data);
      case LinkedNodeKind.propertyAccess:
        return _read_propertyAccess(data);
      case LinkedNodeKind.prefixedIdentifier:
        return _read_prefixedIdentifier(data);
      case LinkedNodeKind.redirectingConstructorInvocation:
        return _read_redirectingConstructorInvocation(data);
      case LinkedNodeKind.rethrowExpression:
        return _read_rethrowExpression(data);
      case LinkedNodeKind.returnStatement:
        return _read_returnStatement(data);
      case LinkedNodeKind.scriptTag:
        return _read_scriptTag(data);
      case LinkedNodeKind.setOrMapLiteral:
        return _read_setOrMapLiteral(data);
      case LinkedNodeKind.showCombinator:
        return _read_showCombinator(data);
      case LinkedNodeKind.simpleFormalParameter:
        return _read_simpleFormalParameter(data);
      case LinkedNodeKind.simpleIdentifier:
        return _read_simpleIdentifier(data);
      case LinkedNodeKind.simpleStringLiteral:
        return _read_simpleStringLiteral(data);
      case LinkedNodeKind.spreadElement:
        return _read_spreadElement(data);
      case LinkedNodeKind.stringInterpolation:
        return _read_stringInterpolation(data);
      case LinkedNodeKind.superConstructorInvocation:
        return _read_superConstructorInvocation(data);
      case LinkedNodeKind.superExpression:
        return _read_superExpression(data);
      case LinkedNodeKind.switchCase:
        return _read_switchCase(data);
      case LinkedNodeKind.switchDefault:
        return _read_switchDefault(data);
      case LinkedNodeKind.switchStatement:
        return _read_switchStatement(data);
      case LinkedNodeKind.symbolLiteral:
        return _read_symbolLiteral(data);
      case LinkedNodeKind.thisExpression:
        return _read_thisExpression(data);
      case LinkedNodeKind.throwExpression:
        return _read_throwExpression(data);
      case LinkedNodeKind.topLevelVariableDeclaration:
        return _read_topLevelVariableDeclaration(data);
      case LinkedNodeKind.tryStatement:
        return _read_tryStatement(data);
      case LinkedNodeKind.typeArgumentList:
        return _read_typeArgumentList(data);
      case LinkedNodeKind.typeName:
        return _read_typeName(data);
      case LinkedNodeKind.typeParameter:
        return _read_typeParameter(data);
      case LinkedNodeKind.typeParameterList:
        return _read_typeParameterList(data);
      case LinkedNodeKind.variableDeclaration:
        return _read_variableDeclaration(data);
      case LinkedNodeKind.variableDeclarationList:
        return _read_variableDeclarationList(data);
      case LinkedNodeKind.variableDeclarationStatement:
        return _read_variableDeclarationStatement(data);
      case LinkedNodeKind.whileStatement:
        return _read_whileStatement(data);
      case LinkedNodeKind.withClause:
        return _read_withClause(data);
      case LinkedNodeKind.yieldStatement:
        return _read_yieldStatement(data);
      default:
        throw UnimplementedError('Expression kind: ${data.kind}');
    }
  }

  T _getElement<T extends Element>(int index) {
    var bundleContext = _unitContext.bundleContext;
    return bundleContext.elementOfIndex(index);
  }

  List<T> _getElements<T extends Element>(List<int> indexList) {
    var bundleContext = _unitContext.bundleContext;
    return bundleContext.elementsOfIndexes(indexList);
  }

  Token _getToken(int index) {
    return _unitContext.tokensContext.tokenOfIndex(index);
  }

  List<Token> _getTokens(List<int> indexList) {
    var result = List<Token>(indexList.length);
    for (var i = 0; i < indexList.length; ++i) {
      var index = indexList[i];
      result[i] = _getToken(index);
    }
    return result;
  }

  AdjacentStrings _read_adjacentStrings(LinkedNode data) {
    return astFactory.adjacentStrings(
      _readNodeList(data.adjacentStrings_strings),
    )..staticType = _readType(data.expression_type);
  }

  Annotation _read_annotation(LinkedNode data) {
    return astFactory.annotation(
      _getToken(data.annotation_atSign),
      readNode(data.annotation_name),
      _getToken(data.annotation_period),
      readNode(data.annotation_constructorName),
      readNode(data.annotation_arguments),
    );
  }

  ArgumentList _read_argumentList(LinkedNode data) {
    return astFactory.argumentList(
      _getToken(data.argumentList_leftParenthesis),
      _readNodeList(data.argumentList_arguments),
      _getToken(data.argumentList_rightParenthesis),
    );
  }

  AsExpression _read_asExpression(LinkedNode data) {
    return astFactory.asExpression(
      readNode(data.asExpression_expression),
      _getToken(data.asExpression_asOperator),
      readNode(data.asExpression_type),
    )..staticType = _readType(data.expression_type);
  }

  AssertInitializer _read_assertInitializer(LinkedNode data) {
    return astFactory.assertInitializer(
      _getToken(data.assertInitializer_assertKeyword),
      _getToken(data.assertInitializer_leftParenthesis),
      readNode(data.assertInitializer_condition),
      _getToken(data.assertInitializer_comma),
      readNode(data.assertInitializer_message),
      _getToken(data.assertInitializer_rightParenthesis),
    );
  }

  AssertStatement _read_assertStatement(LinkedNode data) {
    return astFactory.assertStatement(
      _getToken(data.assertStatement_assertKeyword),
      _getToken(data.assertStatement_leftParenthesis),
      readNode(data.assertStatement_condition),
      _getToken(data.assertStatement_comma),
      readNode(data.assertStatement_message),
      _getToken(data.assertStatement_rightParenthesis),
      _getToken(data.assertStatement_semicolon),
    );
  }

  AssignmentExpression _read_assignmentExpression(LinkedNode data) {
    return astFactory.assignmentExpression(
      readNode(data.assignmentExpression_leftHandSide),
      _getToken(data.assignmentExpression_operator),
      readNode(data.assignmentExpression_rightHandSide),
    )
      ..staticElement = _getElement(data.assignmentExpression_element)
      ..staticType = _readType(data.expression_type);
  }

  AwaitExpression _read_awaitExpression(LinkedNode data) {
    return astFactory.awaitExpression(
      _getToken(data.awaitExpression_awaitKeyword),
      readNode(data.awaitExpression_expression),
    )..staticType = _readType(data.expression_type);
  }

  BinaryExpression _read_binaryExpression(LinkedNode data) {
    return astFactory.binaryExpression(
      readNode(data.binaryExpression_leftOperand),
      _getToken(data.binaryExpression_operator),
      readNode(data.binaryExpression_rightOperand),
    )
      ..staticElement = _getElement(data.binaryExpression_element)
      ..staticType = _readType(data.expression_type);
  }

  Block _read_block(LinkedNode data) {
    return astFactory.block(
      _getToken(data.block_leftBracket),
      _readNodeList(data.block_statements),
      _getToken(data.block_rightBracket),
    );
  }

  BlockFunctionBody _read_blockFunctionBody(LinkedNode data) {
    return astFactory.blockFunctionBody(
      _getToken(data.blockFunctionBody_keyword),
      _getToken(data.blockFunctionBody_star),
      readNode(data.blockFunctionBody_block),
    );
  }

  BooleanLiteral _read_booleanLiteral(LinkedNode data) {
    return astFactory.booleanLiteral(
      _getToken(data.booleanLiteral_literal),
      data.booleanLiteral_value,
    )..staticType = _readType(data.expression_type);
  }

  BreakStatement _read_breakStatement(LinkedNode data) {
    return astFactory.breakStatement(
      _getToken(data.breakStatement_breakKeyword),
      readNode(data.breakStatement_label),
      _getToken(data.breakStatement_semicolon),
    );
  }

  CascadeExpression _read_cascadeExpression(LinkedNode data) {
    return astFactory.cascadeExpression(
      readNode(data.cascadeExpression_target),
      _readNodeList(data.cascadeExpression_sections),
    )..staticType = _readType(data.expression_type);
  }

  CatchClause _read_catchClause(LinkedNode data) {
    return astFactory.catchClause(
      _getToken(data.catchClause_onKeyword),
      readNode(data.catchClause_exceptionType),
      _getToken(data.catchClause_catchKeyword),
      _getToken(data.catchClause_leftParenthesis),
      readNode(data.catchClause_exceptionParameter),
      _getToken(data.catchClause_comma),
      readNode(data.catchClause_stackTraceParameter),
      _getToken(data.catchClause_rightParenthesis),
      readNode(data.catchClause_body),
    );
  }

  ClassDeclaration _read_classDeclaration(LinkedNode data) {
    return astFactory.classDeclaration(
      readNode(data.annotatedNode_comment),
      _readNodeList(data.annotatedNode_metadata),
      _getToken(data.classDeclaration_abstractKeyword),
      _getToken(data.classDeclaration_classKeyword),
      readNode(data.namedCompilationUnitMember_name),
      readNode(data.classOrMixinDeclaration_typeParameters),
      readNode(data.classDeclaration_extendsClause),
      readNode(data.classDeclaration_withClause),
      readNode(data.classOrMixinDeclaration_implementsClause),
      _getToken(data.classOrMixinDeclaration_leftBracket),
      _readNodeList(data.classOrMixinDeclaration_members),
      _getToken(data.classOrMixinDeclaration_rightBracket),
    );
  }

  ClassTypeAlias _read_classTypeAlias(LinkedNode data) {
    return astFactory.classTypeAlias(
      readNode(data.annotatedNode_comment),
      _readNodeList(data.annotatedNode_metadata),
      _getToken(data.typeAlias_typedefKeyword),
      readNode(data.namedCompilationUnitMember_name),
      readNode(data.classTypeAlias_typeParameters),
      _getToken(data.classTypeAlias_equals),
      _getToken(data.classTypeAlias_abstractKeyword),
      readNode(data.classTypeAlias_superclass),
      readNode(data.classTypeAlias_withClause),
      readNode(data.classTypeAlias_implementsClause),
      _getToken(data.typeAlias_semicolon),
    );
  }

  Comment _read_comment(LinkedNode data) {
    var tokens = _getTokens(data.comment_tokens);
    switch (data.comment_type) {
      case LinkedNodeCommentType.block:
        return astFactory.endOfLineComment(
          tokens,
        );
      case LinkedNodeCommentType.documentation:
        return astFactory.documentationComment(
          tokens,
          // TODO(scheglov) references
        );
      case LinkedNodeCommentType.endOfLine:
        return astFactory.endOfLineComment(
          tokens,
        );
      default:
        throw StateError('${data.comment_type}');
    }
  }

  CompilationUnit _read_compilationUnit(LinkedNode data) {
    return astFactory.compilationUnit(
      _getToken(data.compilationUnit_beginToken),
      readNode(data.compilationUnit_scriptTag),
      _readNodeList(data.compilationUnit_directives),
      _readNodeList(data.compilationUnit_declarations),
      _getToken(data.compilationUnit_endToken),
    );
  }

  ConditionalExpression _read_conditionalExpression(LinkedNode data) {
    return astFactory.conditionalExpression(
      readNode(data.conditionalExpression_condition),
      _getToken(data.conditionalExpression_question),
      readNode(data.conditionalExpression_thenExpression),
      _getToken(data.conditionalExpression_colon),
      readNode(data.conditionalExpression_elseExpression),
    )..staticType = _readType(data.expression_type);
  }

  Configuration _read_configuration(LinkedNode data) {
    return astFactory.configuration(
      _getToken(data.configuration_ifKeyword),
      _getToken(data.configuration_leftParenthesis),
      readNode(data.configuration_name),
      _getToken(data.configuration_equalToken),
      readNode(data.configuration_value),
      _getToken(data.configuration_rightParenthesis),
      readNode(data.configuration_uri),
    );
  }

  ConstructorDeclaration _read_constructorDeclaration(LinkedNode data) {
    return astFactory.constructorDeclaration(
      readNode(data.annotatedNode_comment),
      _readNodeList(data.annotatedNode_metadata),
      _getToken(data.constructorDeclaration_externalKeyword),
      _getToken(data.constructorDeclaration_constKeyword),
      _getToken(data.constructorDeclaration_factoryKeyword),
      readNode(data.constructorDeclaration_returnType),
      _getToken(data.constructorDeclaration_period),
      readNode(data.constructorDeclaration_name),
      readNode(data.constructorDeclaration_parameters),
      _getToken(data.constructorDeclaration_separator),
      _readNodeList(data.constructorDeclaration_initializers),
      readNode(data.constructorDeclaration_redirectedConstructor),
      readNode(data.constructorDeclaration_body),
    );
  }

  ConstructorFieldInitializer _read_constructorFieldInitializer(
      LinkedNode data) {
    return astFactory.constructorFieldInitializer(
      _getToken(data.constructorFieldInitializer_thisKeyword),
      _getToken(data.constructorFieldInitializer_period),
      readNode(data.constructorFieldInitializer_fieldName),
      _getToken(data.constructorFieldInitializer_equals),
      readNode(data.constructorFieldInitializer_expression),
    );
  }

  ConstructorName _read_constructorName(LinkedNode data) {
    return astFactory.constructorName(
      readNode(data.constructorName_type),
      _getToken(data.constructorName_period),
      readNode(data.constructorName_name),
    )..staticElement = _getElement(data.constructorName_element);
  }

  ContinueStatement _read_continueStatement(LinkedNode data) {
    return astFactory.continueStatement(
      _getToken(data.continueStatement_continueKeyword),
      readNode(data.continueStatement_label),
      _getToken(data.continueStatement_semicolon),
    );
  }

  DeclaredIdentifier _read_declaredIdentifier(LinkedNode data) {
    return astFactory.declaredIdentifier(
      readNode(data.annotatedNode_comment),
      _readNodeList(data.annotatedNode_metadata),
      _getToken(data.declaredIdentifier_keyword),
      readNode(data.declaredIdentifier_type),
      readNode(data.declaredIdentifier_identifier),
    );
  }

  DefaultFormalParameter _read_defaultFormalParameter(LinkedNode data) {
    return astFactory.defaultFormalParameter(
      readNode(data.defaultFormalParameter_parameter),
      data.defaultFormalParameter_isNamed
          ? ParameterKind.NAMED
          : ParameterKind.POSITIONAL,
      _getToken(data.defaultFormalParameter_separator),
      readNode(data.defaultFormalParameter_defaultValue),
    );
  }

  DoStatement _read_doStatement(LinkedNode data) {
    return astFactory.doStatement(
      _getToken(data.doStatement_doKeyword),
      readNode(data.doStatement_body),
      _getToken(data.doStatement_whileKeyword),
      _getToken(data.doStatement_leftParenthesis),
      readNode(data.doStatement_condition),
      _getToken(data.doStatement_rightParenthesis),
      _getToken(data.doStatement_semicolon),
    );
  }

  DottedName _read_dottedName(LinkedNode data) {
    return astFactory.dottedName(
      _readNodeList(data.dottedName_components),
    );
  }

  DoubleLiteral _read_doubleLiteral(LinkedNode data) {
    return astFactory.doubleLiteral(
      _getToken(data.doubleLiteral_literal),
      data.doubleLiteral_value,
    )..staticType = _readType(data.expression_type);
  }

  EmptyFunctionBody _read_emptyFunctionBody(LinkedNode data) {
    return astFactory.emptyFunctionBody(
      _getToken(data.emptyFunctionBody_semicolon),
    );
  }

  EmptyStatement _read_emptyStatement(LinkedNode data) {
    return astFactory.emptyStatement(
      _getToken(data.emptyStatement_semicolon),
    );
  }

  EnumConstantDeclaration _read_enumConstantDeclaration(LinkedNode data) {
    return astFactory.enumConstantDeclaration(
      readNode(data.annotatedNode_comment),
      _readNodeList(data.annotatedNode_metadata),
      readNode(data.enumConstantDeclaration_name),
    );
  }

  EnumDeclaration _read_enumDeclaration(LinkedNode data) {
    return astFactory.enumDeclaration(
      readNode(data.annotatedNode_comment),
      _readNodeList(data.annotatedNode_metadata),
      _getToken(data.enumDeclaration_enumKeyword),
      readNode(data.namedCompilationUnitMember_name),
      _getToken(data.enumDeclaration_leftBracket),
      _readNodeList(data.enumDeclaration_constants),
      _getToken(data.enumDeclaration_rightBracket),
    );
  }

  ExportDirective _read_exportDirective(LinkedNode data) {
    return astFactory.exportDirective(
      readNode(data.annotatedNode_comment),
      _readNodeList(data.annotatedNode_metadata),
      _getToken(data.directive_keyword),
      readNode(data.uriBasedDirective_uri),
      _readNodeList(data.namespaceDirective_configurations),
      _readNodeList(data.namespaceDirective_combinators),
      _getToken(data.namespaceDirective_semicolon),
    );
  }

  ExpressionFunctionBody _read_expressionFunctionBody(LinkedNode data) {
    return astFactory.expressionFunctionBody(
      _getToken(data.expressionFunctionBody_keyword),
      _getToken(data.expressionFunctionBody_arrow),
      readNode(data.expressionFunctionBody_expression),
      _getToken(data.expressionFunctionBody_semicolon),
    );
  }

  ExpressionStatement _read_expressionStatement(LinkedNode data) {
    return astFactory.expressionStatement(
      readNode(data.expressionStatement_expression),
      _getToken(data.expressionStatement_semicolon),
    );
  }

  ExtendsClause _read_extendsClause(LinkedNode data) {
    return astFactory.extendsClause(
      _getToken(data.extendsClause_extendsKeyword),
      readNode(data.extendsClause_superclass),
    );
  }

  FieldDeclaration _read_fieldDeclaration(LinkedNode data) {
    return astFactory.fieldDeclaration2(
      comment: readNode(data.annotatedNode_comment),
      covariantKeyword: _getToken(data.fieldDeclaration_covariantKeyword),
      fieldList: readNode(data.fieldDeclaration_fields),
      metadata: _readNodeList(data.annotatedNode_metadata),
      semicolon: _getToken(data.fieldDeclaration_semicolon),
      staticKeyword: _getToken(data.fieldDeclaration_staticKeyword),
    );
  }

  FieldFormalParameter _read_fieldFormalParameter(LinkedNode data) {
    return astFactory.fieldFormalParameter2(
      identifier: readNode(data.normalFormalParameter_identifier),
      period: _getToken(data.fieldFormalParameter_period),
      thisKeyword: _getToken(data.fieldFormalParameter_thisKeyword),
      covariantKeyword: _getToken(data.normalFormalParameter_covariantKeyword),
      typeParameters: readNode(data.fieldFormalParameter_typeParameters),
      keyword: _getToken(data.fieldFormalParameter_keyword),
      metadata: _readNodeList(data.normalFormalParameter_metadata),
      comment: readNode(data.normalFormalParameter_comment),
      type: readNode(data.fieldFormalParameter_type),
      parameters: readNode(data.fieldFormalParameter_formalParameters),
    );
  }

  ForEachPartsWithDeclaration _read_forEachPartsWithDeclaration(
      LinkedNode data) {
    return astFactory.forEachPartsWithDeclaration(
      inKeyword: _getToken(data.forEachParts_inKeyword),
      iterable: readNode(data.forEachParts_iterable),
      loopVariable: readNode(data.forEachPartsWithDeclaration_loopVariable),
    );
  }

  ForEachPartsWithIdentifier _read_forEachPartsWithIdentifier(LinkedNode data) {
    return astFactory.forEachPartsWithIdentifier(
      inKeyword: _getToken(data.forEachParts_inKeyword),
      iterable: readNode(data.forEachParts_iterable),
      identifier: readNode(data.forEachPartsWithIdentifier_identifier),
    );
  }

  ForElement _read_forElement(LinkedNode data) {
    return astFactory.forElement(
      awaitKeyword: _getToken(data.forMixin_awaitKeyword),
      body: readNode(data.forElement_body),
      forKeyword: _getToken(data.forMixin_forKeyword),
      forLoopParts: readNode(data.forMixin_forLoopParts),
      leftParenthesis: _getToken(data.forMixin_leftParenthesis),
      rightParenthesis: _getToken(data.forMixin_rightParenthesis),
    );
  }

  FormalParameterList _read_formalParameterList(LinkedNode data) {
    return astFactory.formalParameterList(
      _getToken(data.formalParameterList_leftParenthesis),
      _readNodeList(data.formalParameterList_parameters),
      _getToken(data.formalParameterList_leftDelimiter),
      _getToken(data.formalParameterList_rightDelimiter),
      _getToken(data.formalParameterList_rightParenthesis),
    );
  }

  ForPartsWithDeclarations _read_forPartsWithDeclarations(LinkedNode data) {
    return astFactory.forPartsWithDeclarations(
      condition: readNode(data.forParts_condition),
      leftSeparator: _getToken(data.forParts_leftSeparator),
      rightSeparator: _getToken(data.forParts_rightSeparator),
      updaters: _readNodeList(data.forParts_updaters),
      variables: readNode(data.forPartsWithDeclarations_variables),
    );
  }

  ForPartsWithExpression _read_forPartsWithExpression(LinkedNode data) {
    return astFactory.forPartsWithExpression(
      condition: readNode(data.forParts_condition),
      initialization: readNode(data.forPartsWithExpression_initialization),
      leftSeparator: _getToken(data.forParts_leftSeparator),
      rightSeparator: _getToken(data.forParts_rightSeparator),
      updaters: _readNodeList(data.forParts_updaters),
    );
  }

  ForStatement2 _read_forStatement(LinkedNode data) {
    return astFactory.forStatement2(
      forKeyword: _getToken(data.forMixin_forKeyword),
      leftParenthesis: _getToken(data.forMixin_leftParenthesis),
      forLoopParts: readNode(data.forMixin_forLoopParts),
      rightParenthesis: _getToken(data.forMixin_rightParenthesis),
      body: readNode(data.forStatement_body),
    );
  }

  FunctionDeclaration _read_functionDeclaration(LinkedNode data) {
    return astFactory.functionDeclaration(
      readNode(data.annotatedNode_comment),
      _readNodeList(data.annotatedNode_metadata),
      _getToken(data.functionDeclaration_externalKeyword),
      readNode(data.functionDeclaration_returnType),
      _getToken(data.functionDeclaration_propertyKeyword),
      readNode(data.namedCompilationUnitMember_name),
      readNode(data.functionDeclaration_functionExpression),
    );
  }

  FunctionDeclarationStatement _read_functionDeclarationStatement(
      LinkedNode data) {
    return astFactory.functionDeclarationStatement(
      readNode(data.functionDeclarationStatement_functionDeclaration),
    );
  }

  FunctionExpression _read_functionExpression(LinkedNode data) {
    return astFactory.functionExpression(
      readNode(data.functionExpression_typeParameters),
      readNode(data.functionExpression_formalParameters),
      readNode(data.functionExpression_body),
    );
  }

  FunctionExpressionInvocation _read_functionExpressionInvocation(
      LinkedNode data) {
    return astFactory.functionExpressionInvocation(
      readNode(data.functionExpressionInvocation_function),
      readNode(data.invocationExpression_typeArguments),
      readNode(data.invocationExpression_arguments),
    )..staticInvokeType = _readType(data.invocationExpression_invokeType);
  }

  FunctionTypeAlias _read_functionTypeAlias(LinkedNode data) {
    return astFactory.functionTypeAlias(
      readNode(data.annotatedNode_comment),
      _readNodeList(data.annotatedNode_metadata),
      _getToken(data.typeAlias_typedefKeyword),
      readNode(data.functionTypeAlias_returnType),
      readNode(data.namedCompilationUnitMember_name),
      readNode(data.functionTypeAlias_typeParameters),
      readNode(data.functionTypeAlias_formalParameters),
      _getToken(data.typeAlias_semicolon),
    );
  }

  FunctionTypedFormalParameter _read_functionTypedFormalParameter(
      LinkedNode data) {
    return astFactory.functionTypedFormalParameter2(
      identifier: readNode(data.normalFormalParameter_identifier),
      parameters: readNode(data.functionTypedFormalParameter_formalParameters),
      returnType: readNode(data.functionTypedFormalParameter_returnType),
      covariantKeyword: _getToken(data.normalFormalParameter_covariantKeyword),
      comment: readNode(data.normalFormalParameter_comment),
      metadata: _readNodeList(data.normalFormalParameter_metadata),
      typeParameters:
          readNode(data.functionTypedFormalParameter_typeParameters),
    );
  }

  GenericFunctionType _read_genericFunctionType(LinkedNode data) {
    return astFactory.genericFunctionType(
      readNode(data.genericFunctionType_returnType),
      _getToken(data.genericFunctionType_functionKeyword),
      readNode(data.genericFunctionType_typeParameters),
      readNode(data.genericFunctionType_formalParameters),
      question: _getToken(data.genericFunctionType_question),
    );
  }

  GenericTypeAlias _read_genericTypeAlias(LinkedNode data) {
    return astFactory.genericTypeAlias(
      readNode(data.annotatedNode_comment),
      _readNodeList(data.annotatedNode_metadata),
      _getToken(data.typeAlias_typedefKeyword),
      readNode(data.namedCompilationUnitMember_name),
      readNode(data.genericTypeAlias_typeParameters),
      _getToken(data.genericTypeAlias_equals),
      readNode(data.genericTypeAlias_functionType),
      _getToken(data.typeAlias_semicolon),
    );
  }

  HideCombinator _read_hideCombinator(LinkedNode data) {
    return astFactory.hideCombinator(
      _getToken(data.combinator_keyword),
      _readNodeList(data.hideCombinator_hiddenNames),
    );
  }

  IfElement _read_ifElement(LinkedNode data) {
    return astFactory.ifElement(
      condition: readNode(data.ifMixin_condition),
      elseElement: readNode(data.ifElement_elseElement),
      elseKeyword: _getToken(data.ifMixin_elseKeyword),
      ifKeyword: _getToken(data.ifMixin_ifKeyword),
      leftParenthesis: _getToken(data.ifMixin_leftParenthesis),
      rightParenthesis: _getToken(data.ifMixin_rightParenthesis),
      thenElement: readNode(data.ifElement_thenElement),
    );
  }

  IfStatement _read_ifStatement(LinkedNode data) {
    return astFactory.ifStatement(
      _getToken(data.ifMixin_ifKeyword),
      _getToken(data.ifMixin_leftParenthesis),
      readNode(data.ifMixin_condition),
      _getToken(data.ifMixin_rightParenthesis),
      readNode(data.ifStatement_thenStatement),
      _getToken(data.ifMixin_elseKeyword),
      readNode(data.ifStatement_elseStatement),
    );
  }

  ImplementsClause _read_implementsClause(LinkedNode data) {
    return astFactory.implementsClause(
      _getToken(data.implementsClause_implementsKeyword),
      _readNodeList(data.implementsClause_interfaces),
    );
  }

  ImportDirective _read_importDirective(LinkedNode data) {
    return astFactory.importDirective(
      readNode(data.annotatedNode_comment),
      _readNodeList(data.annotatedNode_metadata),
      _getToken(data.directive_keyword),
      readNode(data.uriBasedDirective_uri),
      _readNodeList(data.namespaceDirective_configurations),
      _getToken(data.importDirective_deferredKeyword),
      _getToken(data.importDirective_asKeyword),
      readNode(data.importDirective_prefix),
      _readNodeList(data.namespaceDirective_combinators),
      _getToken(data.namespaceDirective_semicolon),
    );
  }

  IndexExpression _read_indexExpression(LinkedNode data) {
    return astFactory.indexExpressionForTarget(
      readNode(data.indexExpression_target),
      _getToken(data.indexExpression_leftBracket),
      readNode(data.indexExpression_index),
      _getToken(data.indexExpression_rightBracket),
    )
      ..staticElement = _getElement(data.indexExpression_element)
      ..staticType = _readType(data.expression_type);
  }

  InstanceCreationExpression _read_instanceCreationExpression(LinkedNode data) {
    return astFactory.instanceCreationExpression(
      _getToken(data.instanceCreationExpression_keyword),
      readNode(data.instanceCreationExpression_constructorName),
      readNode(data.instanceCreationExpression_arguments),
      typeArguments: readNode(data.instanceCreationExpression_typeArguments),
    )..staticType = _readType(data.expression_type);
  }

  IntegerLiteral _read_integerLiteral(LinkedNode data) {
    return astFactory.integerLiteral(
      _getToken(data.integerLiteral_literal),
      data.integerLiteral_value,
    )..staticType = _readType(data.expression_type);
  }

  InterpolationExpression _read_interpolationExpression(LinkedNode data) {
    return astFactory.interpolationExpression(
      _getToken(data.interpolationExpression_leftBracket),
      readNode(data.interpolationExpression_expression),
      _getToken(data.interpolationExpression_rightBracket),
    );
  }

  InterpolationString _read_interpolationString(LinkedNode data) {
    return astFactory.interpolationString(
      _getToken(data.interpolationString_token),
      data.interpolationString_value,
    );
  }

  IsExpression _read_isExpression(LinkedNode data) {
    return astFactory.isExpression(
      readNode(data.isExpression_expression),
      _getToken(data.isExpression_isOperator),
      _getToken(data.isExpression_notOperator),
      readNode(data.isExpression_type),
    )..staticType = _readType(data.expression_type);
  }

  Label _read_label(LinkedNode data) {
    return astFactory.label(
      readNode(data.label_label),
      _getToken(data.label_colon),
    );
  }

  LabeledStatement _read_labeledStatement(LinkedNode data) {
    return astFactory.labeledStatement(
      _readNodeList(data.labeledStatement_labels),
      readNode(data.labeledStatement_statement),
    );
  }

  LibraryDirective _read_libraryDirective(LinkedNode data) {
    return astFactory.libraryDirective(
      readNode(data.annotatedNode_comment),
      _readNodeList(data.annotatedNode_metadata),
      _getToken(data.directive_keyword),
      readNode(data.libraryDirective_name),
      _getToken(data.namespaceDirective_semicolon),
    );
  }

  LibraryIdentifier _read_libraryIdentifier(LinkedNode data) {
    return astFactory.libraryIdentifier(
      _readNodeList(data.libraryIdentifier_components),
    );
  }

  ListLiteral _read_listLiteral(LinkedNode data) {
    return astFactory.listLiteral(
      _getToken(data.typedLiteral_constKeyword),
      readNode(data.typedLiteral_typeArguments),
      _getToken(data.listLiteral_leftBracket),
      _readNodeList(data.listLiteral_elements),
      _getToken(data.listLiteral_rightBracket),
    )..staticType = _readType(data.expression_type);
  }

  MapLiteralEntry _read_mapLiteralEntry(LinkedNode data) {
    return astFactory.mapLiteralEntry(
      readNode(data.mapLiteralEntry_key),
      _getToken(data.mapLiteralEntry_separator),
      readNode(data.mapLiteralEntry_value),
    );
  }

  MethodDeclaration _read_methodDeclaration(LinkedNode data) {
    return astFactory.methodDeclaration(
      readNode(data.annotatedNode_comment),
      _readNodeList(data.annotatedNode_metadata),
      _getToken(data.methodDeclaration_externalKeyword),
      _getToken(data.methodDeclaration_modifierKeyword),
      readNode(data.methodDeclaration_returnType),
      _getToken(data.methodDeclaration_propertyKeyword),
      _getToken(data.methodDeclaration_operatorKeyword),
      readNode(data.methodDeclaration_name),
      readNode(data.methodDeclaration_typeParameters),
      readNode(data.methodDeclaration_formalParameters),
      readNode(data.methodDeclaration_body),
    );
  }

  MethodInvocation _read_methodInvocation(LinkedNode data) {
    return astFactory.methodInvocation(
      readNode(data.methodInvocation_target),
      _getToken(data.methodInvocation_operator),
      readNode(data.methodInvocation_methodName),
      readNode(data.invocationExpression_typeArguments),
      readNode(data.invocationExpression_arguments),
    )..staticInvokeType = _readType(data.invocationExpression_invokeType);
  }

  MixinDeclaration _read_mixinDeclaration(LinkedNode data) {
    return astFactory.mixinDeclaration(
      readNode(data.annotatedNode_comment),
      _readNodeList(data.annotatedNode_metadata),
      _getToken(data.mixinDeclaration_mixinKeyword),
      readNode(data.namedCompilationUnitMember_name),
      readNode(data.classOrMixinDeclaration_typeParameters),
      readNode(data.mixinDeclaration_onClause),
      readNode(data.classOrMixinDeclaration_implementsClause),
      _getToken(data.classOrMixinDeclaration_leftBracket),
      _readNodeList(data.classOrMixinDeclaration_members),
      _getToken(data.classOrMixinDeclaration_rightBracket),
    );
  }

  NamedExpression _read_namedExpression(LinkedNode data) {
    return astFactory.namedExpression(
      readNode(data.namedExpression_name),
      readNode(data.namedExpression_expression),
    )..staticType = _readType(data.expression_type);
  }

  NullLiteral _read_nullLiteral(LinkedNode data) {
    return astFactory.nullLiteral(
      _getToken(data.nullLiteral_literal),
    )..staticType = _readType(data.expression_type);
  }

  OnClause _read_onClause(LinkedNode data) {
    return astFactory.onClause(
      _getToken(data.onClause_onKeyword),
      _readNodeList(data.onClause_superclassConstraints),
    );
  }

  ParenthesizedExpression _read_parenthesizedExpression(LinkedNode data) {
    return astFactory.parenthesizedExpression(
      _getToken(data.parenthesizedExpression_leftParenthesis),
      readNode(data.parenthesizedExpression_expression),
      _getToken(data.parenthesizedExpression_rightParenthesis),
    )..staticType = _readType(data.expression_type);
  }

  PartDirective _read_partDirective(LinkedNode data) {
    return astFactory.partDirective(
      readNode(data.annotatedNode_comment),
      _readNodeList(data.annotatedNode_metadata),
      _getToken(data.directive_keyword),
      readNode(data.uriBasedDirective_uri),
      _getToken(data.namespaceDirective_semicolon),
    );
  }

  PartOfDirective _read_partOfDirective(LinkedNode data) {
    return astFactory.partOfDirective(
      readNode(data.annotatedNode_comment),
      _readNodeList(data.annotatedNode_metadata),
      _getToken(data.directive_keyword),
      _getToken(data.partOfDirective_ofKeyword),
      readNode(data.partOfDirective_uri),
      readNode(data.partOfDirective_libraryName),
      _getToken(data.partOfDirective_semicolon),
    );
  }

  PostfixExpression _read_postfixExpression(LinkedNode data) {
    return astFactory.postfixExpression(
      readNode(data.postfixExpression_operand),
      _getToken(data.postfixExpression_operator),
    )
      ..staticElement = _getElement(data.postfixExpression_element)
      ..staticType = _readType(data.expression_type);
  }

  PrefixedIdentifier _read_prefixedIdentifier(LinkedNode data) {
    return astFactory.prefixedIdentifier(
      readNode(data.prefixedIdentifier_prefix),
      _getToken(data.prefixedIdentifier_period),
      readNode(data.prefixedIdentifier_identifier),
    )..staticType = _readType(data.expression_type);
  }

  PrefixExpression _read_prefixExpression(LinkedNode data) {
    return astFactory.prefixExpression(
      _getToken(data.prefixExpression_operator),
      readNode(data.prefixExpression_operand),
    )
      ..staticElement = _getElement(data.prefixExpression_element)
      ..staticType = _readType(data.expression_type);
  }

  PropertyAccess _read_propertyAccess(LinkedNode data) {
    return astFactory.propertyAccess(
      readNode(data.propertyAccess_target),
      _getToken(data.propertyAccess_operator),
      readNode(data.propertyAccess_propertyName),
    )..staticType = _readType(data.expression_type);
  }

  RedirectingConstructorInvocation _read_redirectingConstructorInvocation(
      LinkedNode data) {
    return astFactory.redirectingConstructorInvocation(
      _getToken(data.redirectingConstructorInvocation_thisKeyword),
      _getToken(data.redirectingConstructorInvocation_period),
      readNode(data.redirectingConstructorInvocation_constructorName),
      readNode(data.redirectingConstructorInvocation_arguments),
    )..staticElement =
        _getElement(data.redirectingConstructorInvocation_element);
  }

  RethrowExpression _read_rethrowExpression(LinkedNode data) {
    return astFactory.rethrowExpression(
      _getToken(data.rethrowExpression_rethrowKeyword),
    )..staticType = _readType(data.expression_type);
  }

  ReturnStatement _read_returnStatement(LinkedNode data) {
    return astFactory.returnStatement(
      _getToken(data.returnStatement_returnKeyword),
      readNode(data.returnStatement_expression),
      _getToken(data.returnStatement_semicolon),
    );
  }

  ScriptTag _read_scriptTag(LinkedNode data) {
    return astFactory.scriptTag(
      _getToken(data.scriptTag_scriptTag),
    );
  }

  SetOrMapLiteral _read_setOrMapLiteral(LinkedNode data) {
    SetOrMapLiteralImpl node = astFactory.setOrMapLiteral(
      constKeyword: _getToken(data.typedLiteral_constKeyword),
      elements: _readNodeList(data.setOrMapLiteral_elements),
      leftBracket: _getToken(data.setOrMapLiteral_leftBracket),
      typeArguments: readNode(data.typedLiteral_typeArguments),
      rightBracket: _getToken(data.setOrMapLiteral_leftBracket),
    )..staticType = _readType(data.expression_type);
    if (data.setOrMapLiteral_isMap) {
      node.becomeMap();
    } else if (data.setOrMapLiteral_isSet) {
      node.becomeSet();
    }
    return node;
  }

  ShowCombinator _read_showCombinator(LinkedNode data) {
    return astFactory.showCombinator(
      _getToken(data.combinator_keyword),
      _readNodeList(data.showCombinator_shownNames),
    );
  }

  SimpleFormalParameter _read_simpleFormalParameter(LinkedNode data) {
    return astFactory.simpleFormalParameter2(
      identifier: readNode(data.normalFormalParameter_identifier),
      type: readNode(data.simpleFormalParameter_type),
      covariantKeyword: _getToken(data.normalFormalParameter_covariantKeyword),
      comment: readNode(data.normalFormalParameter_comment),
      metadata: _readNodeList(data.normalFormalParameter_metadata),
      keyword: _getToken(data.simpleFormalParameter_keyword),
    );
  }

  SimpleIdentifier _read_simpleIdentifier(LinkedNode data) {
    return astFactory.simpleIdentifier(
      _getToken(data.simpleIdentifier_token),
    )
      ..staticElement = _getElement(data.simpleIdentifier_element)
      ..staticType = _readType(data.expression_type);
  }

  SimpleStringLiteral _read_simpleStringLiteral(LinkedNode data) {
    return astFactory.simpleStringLiteral(
      _getToken(data.simpleStringLiteral_token),
      data.simpleStringLiteral_value,
    )..staticType = _readType(data.expression_type);
  }

  SpreadElement _read_spreadElement(LinkedNode data) {
    return astFactory.spreadElement(
      spreadOperator: _getToken(data.spreadElement_spreadOperator),
      expression: readNode(data.spreadElement_expression),
    );
  }

  StringInterpolation _read_stringInterpolation(LinkedNode data) {
    return astFactory.stringInterpolation(
      _readNodeList(data.stringInterpolation_elements),
    )..staticType = _readType(data.expression_type);
  }

  SuperConstructorInvocation _read_superConstructorInvocation(LinkedNode data) {
    return astFactory.superConstructorInvocation(
      _getToken(data.superConstructorInvocation_superKeyword),
      _getToken(data.superConstructorInvocation_period),
      readNode(data.superConstructorInvocation_constructorName),
      readNode(data.superConstructorInvocation_arguments),
    )..staticElement = _getElement(data.superConstructorInvocation_element);
  }

  SuperExpression _read_superExpression(LinkedNode data) {
    return astFactory.superExpression(
      _getToken(data.superExpression_superKeyword),
    )..staticType = _readType(data.expression_type);
  }

  SwitchCase _read_switchCase(LinkedNode data) {
    return astFactory.switchCase(
      _readNodeList(data.switchMember_labels),
      _getToken(data.switchMember_keyword),
      readNode(data.switchCase_expression),
      _getToken(data.switchMember_colon),
      _readNodeList(data.switchMember_statements),
    );
  }

  SwitchDefault _read_switchDefault(LinkedNode data) {
    return astFactory.switchDefault(
      _readNodeList(data.switchMember_labels),
      _getToken(data.switchMember_keyword),
      _getToken(data.switchMember_colon),
      _readNodeList(data.switchMember_statements),
    );
  }

  SwitchStatement _read_switchStatement(LinkedNode data) {
    return astFactory.switchStatement(
      _getToken(data.switchStatement_switchKeyword),
      _getToken(data.switchStatement_leftParenthesis),
      readNode(data.switchStatement_expression),
      _getToken(data.switchStatement_rightParenthesis),
      _getToken(data.switchStatement_leftBracket),
      _readNodeList(data.switchStatement_members),
      _getToken(data.switchStatement_rightBracket),
    );
  }

  SymbolLiteral _read_symbolLiteral(LinkedNode data) {
    return astFactory.symbolLiteral(
      _getToken(data.symbolLiteral_poundSign),
      _getTokens(data.symbolLiteral_components),
    )..staticType = _readType(data.expression_type);
  }

  ThisExpression _read_thisExpression(LinkedNode data) {
    return astFactory.thisExpression(
      _getToken(data.thisExpression_thisKeyword),
    )..staticType = _readType(data.expression_type);
  }

  ThrowExpression _read_throwExpression(LinkedNode data) {
    return astFactory.throwExpression(
      _getToken(data.throwExpression_throwKeyword),
      readNode(data.throwExpression_expression),
    )..staticType = _readType(data.expression_type);
  }

  TopLevelVariableDeclaration _read_topLevelVariableDeclaration(
      LinkedNode data) {
    return astFactory.topLevelVariableDeclaration(
      readNode(data.annotatedNode_comment),
      _readNodeList(data.annotatedNode_metadata),
      readNode(data.topLevelVariableDeclaration_variableList),
      _getToken(data.topLevelVariableDeclaration_semicolon),
    );
  }

  TryStatement _read_tryStatement(LinkedNode data) {
    return astFactory.tryStatement(
      _getToken(data.tryStatement_tryKeyword),
      readNode(data.tryStatement_body),
      _readNodeList(data.tryStatement_catchClauses),
      _getToken(data.tryStatement_tryKeyword),
      readNode(data.tryStatement_finallyBlock),
    );
  }

  TypeArgumentList _read_typeArgumentList(LinkedNode data) {
    return astFactory.typeArgumentList(
      _getToken(data.typeArgumentList_leftBracket),
      _readNodeList(data.typeArgumentList_arguments),
      _getToken(data.typeArgumentList_rightBracket),
    );
  }

  TypeName _read_typeName(LinkedNode data) {
    return astFactory.typeName(
      readNode(data.typeName_name),
      readNode(data.typeName_typeArguments),
      question: _getToken(data.typeName_question),
    )..type = _readType(data.typeName_type);
  }

  TypeParameter _read_typeParameter(LinkedNode data) {
    return astFactory.typeParameter(
      readNode(data.annotatedNode_comment),
      _readNodeList(data.annotatedNode_metadata),
      readNode(data.typeParameter_name),
      _getToken(data.typeParameter_extendsKeyword),
      readNode(data.typeParameter_bound),
    );
  }

  TypeParameterList _read_typeParameterList(LinkedNode data) {
    return astFactory.typeParameterList(
      _getToken(data.typeParameterList_leftBracket),
      _readNodeList(data.typeParameterList_typeParameters),
      _getToken(data.typeParameterList_rightBracket),
    );
  }

  VariableDeclaration _read_variableDeclaration(LinkedNode data) {
    return astFactory.variableDeclaration(
      readNode(data.variableDeclaration_name),
      _getToken(data.variableDeclaration_equals),
      readNode(data.variableDeclaration_initializer),
    );
  }

  VariableDeclarationList _read_variableDeclarationList(LinkedNode data) {
    return astFactory.variableDeclarationList(
      readNode(data.annotatedNode_comment),
      _readNodeList(data.annotatedNode_metadata),
      _getToken(data.variableDeclarationList_keyword),
      readNode(data.variableDeclarationList_type),
      _readNodeList(data.variableDeclarationList_variables),
    );
  }

  VariableDeclarationStatement _read_variableDeclarationStatement(
      LinkedNode data) {
    return astFactory.variableDeclarationStatement(
      readNode(data.variableDeclarationStatement_variables),
      _getToken(data.variableDeclarationStatement_semicolon),
    );
  }

  WhileStatement _read_whileStatement(LinkedNode data) {
    return astFactory.whileStatement(
      _getToken(data.whileStatement_whileKeyword),
      _getToken(data.whileStatement_leftParenthesis),
      readNode(data.whileStatement_condition),
      _getToken(data.whileStatement_rightParenthesis),
      readNode(data.whileStatement_body),
    );
  }

  WithClause _read_withClause(LinkedNode data) {
    return astFactory.withClause(
      _getToken(data.withClause_withKeyword),
      _readNodeList(data.withClause_mixinTypes),
    );
  }

  YieldStatement _read_yieldStatement(LinkedNode data) {
    return astFactory.yieldStatement(
      _getToken(data.yieldStatement_yieldKeyword),
      _getToken(data.yieldStatement_star),
      readNode(data.yieldStatement_expression),
      _getToken(data.yieldStatement_semicolon),
    );
  }

  List<T> _readNodeList<T>(List<LinkedNode> nodeList) {
    var result = List<T>.filled(nodeList.length, null);
    for (var i = 0; i < nodeList.length; ++i) {
      var linkedNode = nodeList[i];
      result[i] = readNode(linkedNode) as T;
    }
    return result;
  }

  DartType _readType(LinkedNodeType data) {
    if (data == null) return null;

    switch (data.kind) {
      case LinkedNodeTypeKind.bottom:
        return BottomTypeImpl.instance;
      case LinkedNodeTypeKind.dynamic_:
        return DynamicTypeImpl.instance;
      case LinkedNodeTypeKind.function:
        return FunctionTypeImpl.synthetic(
          _readType(data.functionReturnType),
          _getElements(data.functionTypeParameters),
          _getElements(data.functionFormalParameters),
        );
      case LinkedNodeTypeKind.interface:
        var element = _getElement(data.interfaceClass);
        if (element != null) {
          return InterfaceTypeImpl.explicit(
            element,
            _readTypes(
              data.interfaceTypeArguments,
              const <InterfaceType>[],
            ),
          );
        }
        return DynamicTypeImpl.instance;
      case LinkedNodeTypeKind.typeParameter:
        var element = _getElement(data.typeParameterParameter);
        // TODO(scheglov) Remove when references include all type parameters.
        element ??= TypeParameterElementImpl('', -1);
        return TypeParameterTypeImpl(element);
      case LinkedNodeTypeKind.void_:
        return VoidTypeImpl.instance;
      default:
        throw UnimplementedError('Type kind: ${data.kind}');
    }
  }

  List<T> _readTypes<T extends DartType>(
    List<LinkedNodeType> dataList,
    List<T> ifEmpty,
  ) {
    if (dataList.isEmpty) return ifEmpty;

    var result = List<T>(dataList.length);
    for (var i = 0; i < dataList.length; ++i) {
      var data = dataList[i];
      result[i] = _readType(data);
    }
    return result;
  }
}
