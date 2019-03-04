// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:meta/meta.dart';

/// Serializer of fully resolved ASTs into flat buffers.
class AstBinaryWriter extends ThrowingAstVisitor<LinkedNodeBuilder> {
  final referenceRoot = Reference.root();
  final referenceBuilder = LinkedNodeReferenceBuilder();
  final _references = <Reference>[];

  final UnlinkedTokensBuilder tokens = UnlinkedTokensBuilder();
  final Map<Token, int> _tokenMap = Map.identity();
  int _tokenIndex = 0;

  AstBinaryWriter() {
    _references.add(referenceRoot);
    _addToken(
      isSynthetic: true,
      kind: UnlinkedTokenKind.nothing,
      length: 0,
      lexeme: '',
      offset: 0,
      precedingComment: 0,
      type: UnlinkedTokenType.NOTHING,
    );
  }

  @override
  LinkedNodeBuilder visitAdjacentStrings(AdjacentStrings node) {
    return LinkedNodeBuilder.adjacentStrings(
      adjacentStrings_strings: _writeNodeList(node.strings),
    );
  }

  @override
  LinkedNodeBuilder visitAnnotation(Annotation node) {
    return LinkedNodeBuilder.annotation(
      annotation_arguments: node.arguments?.accept(this),
      annotation_atSign: _getToken(node.atSign),
      annotation_constructorName: node.constructorName?.accept(this),
      annotation_name: node.name?.accept(this),
      annotation_period: _getToken(node.period),
    );
  }

  @override
  LinkedNodeBuilder visitArgumentList(ArgumentList node) {
    return LinkedNodeBuilder.argumentList(
      argumentList_arguments: _writeNodeList(node.arguments),
      argumentList_leftParenthesis: _getToken(node.leftParenthesis),
      argumentList_rightParenthesis: _getToken(node.rightParenthesis),
    );
  }

  @override
  LinkedNodeBuilder visitAsExpression(AsExpression node) {
    return LinkedNodeBuilder.asExpression(
      asExpression_asOperator: _getToken(node.asOperator),
      asExpression_expression: node.expression.accept(this),
      asExpression_type: node.type.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitAssertInitializer(AssertInitializer node) {
    return LinkedNodeBuilder.assertInitializer(
      assertInitializer_assertKeyword: _getToken(node.assertKeyword),
      assertInitializer_comma: _getToken(node.comma),
      assertInitializer_condition: node.condition.accept(this),
      assertInitializer_leftParenthesis: _getToken(node.leftParenthesis),
      assertInitializer_message: node.message?.accept(this),
      assertInitializer_rightParenthesis: _getToken(node.rightParenthesis),
    );
  }

  @override
  LinkedNodeBuilder visitAssertStatement(AssertStatement node) {
    var builder = LinkedNodeBuilder.assertStatement(
      assertStatement_assertKeyword: _getToken(node.assertKeyword),
      assertStatement_comma: _getToken(node.comma),
      assertStatement_condition: node.condition.accept(this),
      assertStatement_leftParenthesis: _getToken(node.leftParenthesis),
      assertStatement_message: node.message?.accept(this),
      assertStatement_rightParenthesis: _getToken(node.rightParenthesis),
      assertStatement_semicolon: _getToken(node.semicolon),
    );
    _storeStatement(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitAssignmentExpression(AssignmentExpression node) {
    return LinkedNodeBuilder.assignmentExpression(
      assignmentExpression_element: _getReference(node.staticElement).index,
      assignmentExpression_leftHandSide: node.leftHandSide.accept(this),
      assignmentExpression_operator: _getToken(node.operator),
      assignmentExpression_rightHandSide: node.rightHandSide.accept(this),
      expression_type: _writeType(node.staticType),
    );
  }

  @override
  LinkedNodeBuilder visitAwaitExpression(AwaitExpression node) {
    return LinkedNodeBuilder.awaitExpression(
      awaitExpression_awaitKeyword: _getToken(node.awaitKeyword),
      awaitExpression_expression: node.expression.accept(this),
      expression_type: _writeType(node.staticType),
    );
  }

  @override
  LinkedNodeBuilder visitBinaryExpression(BinaryExpression node) {
    return LinkedNodeBuilder.binaryExpression(
      binaryExpression_element: _getReference(node.staticElement).index,
      binaryExpression_leftOperand: node.leftOperand.accept(this),
      binaryExpression_operator: _getToken(node.operator),
      binaryExpression_rightOperand: node.rightOperand.accept(this),
      expression_type: _writeType(node.staticType),
    );
  }

  @override
  LinkedNodeBuilder visitBlock(Block node) {
    return LinkedNodeBuilder.block(
      block_leftBracket: _getToken(node.leftBracket),
      block_rightBracket: _getToken(node.rightBracket),
      block_statements: _writeNodeList(node.statements),
    );
  }

  @override
  LinkedNodeBuilder visitBlockFunctionBody(BlockFunctionBody node) {
    return LinkedNodeBuilder.blockFunctionBody(
      blockFunctionBody_block: node.block.accept(this),
      blockFunctionBody_keyword: _getToken(node.keyword),
      blockFunctionBody_star: _getToken(node.star),
    );
  }

  @override
  LinkedNodeBuilder visitBooleanLiteral(BooleanLiteral node) {
    return LinkedNodeBuilder.booleanLiteral(
      booleanLiteral_literal: _getToken(node.literal),
      booleanLiteral_value: node.value,
    );
  }

  @override
  LinkedNodeBuilder visitBreakStatement(BreakStatement node) {
    var builder = LinkedNodeBuilder.breakStatement(
      breakStatement_breakKeyword: _getToken(node.breakKeyword),
      breakStatement_label: node.label?.accept(this),
      breakStatement_semicolon: _getToken(node.semicolon),
    );
    _storeStatement(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitCascadeExpression(CascadeExpression node) {
    var builder = LinkedNodeBuilder.cascadeExpression(
      cascadeExpression_target: node.target.accept(this),
      cascadeExpression_sections: _writeNodeList(node.cascadeSections),
    );
    _storeExpression(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitCatchClause(CatchClause node) {
    return LinkedNodeBuilder.catchClause(
      catchClause_body: node.body.accept(this),
      catchClause_catchKeyword: _getToken(node.catchKeyword),
      catchClause_comma: _getToken(node.comma),
      catchClause_exceptionParameter: node.exceptionParameter?.accept(this),
      catchClause_exceptionType: node.exceptionType?.accept(this),
      catchClause_leftParenthesis: _getToken(node.leftParenthesis),
      catchClause_onKeyword: _getToken(node.onKeyword),
      catchClause_rightParenthesis: _getToken(node.rightParenthesis),
      catchClause_stackTraceParameter: node.stackTraceParameter?.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitClassDeclaration(ClassDeclaration node) {
    var builder = LinkedNodeBuilder.classDeclaration(
      classDeclaration_abstractKeyword: _getToken(node.abstractKeyword),
      classDeclaration_classKeyword: _getToken(node.classKeyword),
      classDeclaration_extendsClause: node.extendsClause?.accept(this),
      classDeclaration_withClause: node.withClause?.accept(this),
    );
    _storeClassOrMixinDeclaration(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitComment(Comment node) {
    LinkedNodeCommentType type;
    if (node.isBlock) {
      type = LinkedNodeCommentType.block;
    } else if (node.isDocumentation) {
      type = LinkedNodeCommentType.documentation;
    } else if (node.isEndOfLine) {
      type = LinkedNodeCommentType.endOfLine;
    }

    return LinkedNodeBuilder.comment(
      comment_tokens: _getTokens(node.tokens),
      comment_type: type,
    );
  }

  @override
  LinkedNodeBuilder visitCompilationUnit(CompilationUnit node) {
    return LinkedNodeBuilder.compilationUnit(
      compilationUnit_beginToken: _getToken(node.beginToken),
      compilationUnit_declarations: _writeNodeList(node.declarations),
      compilationUnit_directives: _writeNodeList(node.directives),
      compilationUnit_endToken: _getToken(node.endToken),
      compilationUnit_scriptTag: node.scriptTag?.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitConditionalExpression(ConditionalExpression node) {
    var builder = LinkedNodeBuilder.conditionalExpression(
      conditionalExpression_colon: _getToken(node.colon),
      conditionalExpression_condition: node.condition.accept(this),
      conditionalExpression_elseExpression: node.elseExpression.accept(this),
      conditionalExpression_question: _getToken(node.question),
      conditionalExpression_thenExpression: node.thenExpression.accept(this),
    );
    _storeExpression(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitConstructorDeclaration(ConstructorDeclaration node) {
    var builder = LinkedNodeBuilder.constructorDeclaration(
      constructorDeclaration_body: node.body?.accept(this),
      constructorDeclaration_constKeyword: _getToken(node.constKeyword),
      constructorDeclaration_externalKeyword: _getToken(node.externalKeyword),
      constructorDeclaration_factoryKeyword: _getToken(node.factoryKeyword),
      constructorDeclaration_initializers: _writeNodeList(node.initializers),
      constructorDeclaration_name: node.name?.accept(this),
      constructorDeclaration_parameters: node.parameters.accept(this),
      constructorDeclaration_period: _getToken(node.period),
      constructorDeclaration_redirectedConstructor:
          node.redirectedConstructor?.accept(this),
      constructorDeclaration_returnType: node.returnType.accept(this),
      constructorDeclaration_separator: _getToken(node.separator),
    );
    _storeClassMember(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitConstructorFieldInitializer(
      ConstructorFieldInitializer node) {
    var builder = LinkedNodeBuilder.constructorFieldInitializer(
      constructorFieldInitializer_equals: _getToken(node.equals),
      constructorFieldInitializer_expression: node.expression.accept(this),
      constructorFieldInitializer_fieldName: node.fieldName.accept(this),
      constructorFieldInitializer_period: _getToken(node.period),
      constructorFieldInitializer_thisKeyword: _getToken(node.thisKeyword),
    );
    _storeConstructorInitializer(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitConstructorName(ConstructorName node) {
    return LinkedNodeBuilder.constructorName(
      constructorName_element: _getReference(node.staticElement).index,
      constructorName_name: node.name?.accept(this),
      constructorName_period: _getToken(node.period),
      constructorName_type: node.type.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitContinueStatement(ContinueStatement node) {
    var builder = LinkedNodeBuilder.continueStatement(
      continueStatement_continueKeyword: _getToken(node.continueKeyword),
      continueStatement_label: node.label?.accept(this),
      continueStatement_semicolon: _getToken(node.semicolon),
    );
    _storeStatement(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitDeclaredIdentifier(DeclaredIdentifier node) {
    var builder = LinkedNodeBuilder.declaredIdentifier(
      declaredIdentifier_identifier: node.identifier.accept(this),
      declaredIdentifier_keyword: _getToken(node.keyword),
      declaredIdentifier_type: node.type?.accept(this),
    );
    _storeDeclaration(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitDefaultFormalParameter(DefaultFormalParameter node) {
    return LinkedNodeBuilder.defaultFormalParameter(
      defaultFormalParameter_defaultValue: node.defaultValue?.accept(this),
      defaultFormalParameter_isNamed: node.isNamed,
      defaultFormalParameter_parameter: node.parameter.accept(this),
      defaultFormalParameter_separator: _getToken(node.separator),
    );
  }

  @override
  LinkedNodeBuilder visitDoStatement(DoStatement node) {
    return LinkedNodeBuilder.doStatement(
      doStatement_body: node.body.accept(this),
      doStatement_condition: node.condition.accept(this),
      doStatement_doKeyword: _getToken(node.doKeyword),
      doStatement_leftParenthesis: _getToken(node.leftParenthesis),
      doStatement_rightParenthesis: _getToken(node.rightParenthesis),
      doStatement_semicolon: _getToken(node.whileKeyword),
      doStatement_whileKeyword: _getToken(node.whileKeyword),
    );
  }

  @override
  LinkedNodeBuilder visitDoubleLiteral(DoubleLiteral node) {
    return LinkedNodeBuilder.doubleLiteral(
      doubleLiteral_literal: _getToken(node.literal),
      doubleLiteral_value: node.value,
      expression_type: _writeType(node.staticType),
    );
  }

  @override
  LinkedNodeBuilder visitEmptyFunctionBody(EmptyFunctionBody node) {
    var builder = LinkedNodeBuilder.emptyFunctionBody(
      emptyFunctionBody_semicolon: _getToken(node.semicolon),
    );
    _storeFunctionBody(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    var builder = LinkedNodeBuilder.enumConstantDeclaration(
      enumConstantDeclaration_name: node.name.accept(this),
    );
    _storeDeclaration(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitEnumDeclaration(EnumDeclaration node) {
    var builder = LinkedNodeBuilder.enumDeclaration(
      enumDeclaration_constants: _writeNodeList(node.constants),
      enumDeclaration_enumKeyword: _getToken(node.enumKeyword),
      enumDeclaration_leftBracket: _getToken(node.leftBracket),
      enumDeclaration_rightBracket: _getToken(node.rightBracket),
    );
    _storeNamedCompilationUnitMember(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitExportDirective(ExportDirective node) {
    var builder = LinkedNodeBuilder.exportDirective();
    _storeNamespaceDirective(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitExpressionFunctionBody(ExpressionFunctionBody node) {
    return LinkedNodeBuilder.expressionFunctionBody(
      expressionFunctionBody_arrow: _getToken(node.functionDefinition),
      expressionFunctionBody_expression: node.expression.accept(this),
      expressionFunctionBody_keyword: _getToken(node.keyword),
      expressionFunctionBody_semicolon: _getToken(node.semicolon),
    );
  }

  @override
  LinkedNodeBuilder visitExpressionStatement(ExpressionStatement node) {
    return LinkedNodeBuilder.expressionStatement(
      expressionStatement_expression: node.expression.accept(this),
      expressionStatement_semicolon: _getToken(node.semicolon),
    );
  }

  @override
  LinkedNodeBuilder visitExtendsClause(ExtendsClause node) {
    return LinkedNodeBuilder.extendsClause(
      extendsClause_extendsKeyword: _getToken(node.extendsKeyword),
      extendsClause_superclass: node.superclass.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitFieldDeclaration(FieldDeclaration node) {
    var builder = LinkedNodeBuilder.fieldDeclaration(
      fieldDeclaration_covariantKeyword: _getToken(node.covariantKeyword),
      fieldDeclaration_fields: node.fields.accept(this),
      fieldDeclaration_semicolon: _getToken(node.semicolon),
      fieldDeclaration_staticKeyword: _getToken(node.staticKeyword),
    );
    _storeClassMember(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitFieldFormalParameter(FieldFormalParameter node) {
    var builder = LinkedNodeBuilder.fieldFormalParameter(
      fieldFormalParameter_formalParameters: node.parameters?.accept(this),
      fieldFormalParameter_keyword: _getToken(node.keyword),
      fieldFormalParameter_period: _getToken(node.period),
      fieldFormalParameter_thisKeyword: _getToken(node.thisKeyword),
      fieldFormalParameter_type: node.type?.accept(this),
      fieldFormalParameter_typeParameters: node.typeParameters?.accept(this),
    );
    _storeNormalFormalParameter(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitForEachStatement(ForEachStatement node) {
    return LinkedNodeBuilder.forEachStatement(
      forEachStatement_awaitKeyword: _getToken(node.awaitKeyword),
      forStatement_body: node.body.accept(this),
      forStatement_forKeyword: _getToken(node.forKeyword),
      forEachStatement_identifier: node.identifier?.accept(this),
      forEachStatement_inKeyword: _getToken(node.inKeyword),
      forEachStatement_iterable: node.iterable.accept(this),
      forStatement_leftParenthesis: _getToken(node.leftParenthesis),
      forEachStatement_loopVariable: node.loopVariable?.accept(this),
      forStatement_rightParenthesis: _getToken(node.rightParenthesis),
    );
  }

  @override
  LinkedNodeBuilder visitFormalParameterList(FormalParameterList node) {
    return LinkedNodeBuilder.formalParameterList(
      formalParameterList_leftDelimiter: _getToken(node.leftDelimiter),
      formalParameterList_leftParenthesis: _getToken(node.leftParenthesis),
      formalParameterList_parameters: _writeNodeList(node.parameters),
      formalParameterList_rightDelimiter: _getToken(node.rightDelimiter),
      formalParameterList_rightParenthesis: _getToken(node.rightParenthesis),
    );
  }

  @override
  LinkedNodeBuilder visitForStatement(ForStatement node) {
    return LinkedNodeBuilder.forStatement(
      forStatement_body: node.body.accept(this),
      forStatement_condition: node.condition?.accept(this),
      forStatement_forKeyword: _getToken(node.forKeyword),
      forStatement_initialization: node.initialization?.accept(this),
      forStatement_leftParenthesis: _getToken(node.leftParenthesis),
      forStatement_leftSeparator: _getToken(node.leftSeparator),
      forStatement_rightParenthesis: _getToken(node.rightParenthesis),
      forStatement_rightSeparator: _getToken(node.rightSeparator),
      forStatement_updaters: _writeNodeList(node.updaters),
      forStatement_variableList: node.variables?.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitFunctionDeclaration(FunctionDeclaration node) {
    var builder = LinkedNodeBuilder.functionDeclaration(
      functionDeclaration_externalKeyword: _getToken(node.externalKeyword),
      functionDeclaration_functionExpression:
          node.functionExpression?.accept(this),
      functionDeclaration_propertyKeyword: _getToken(node.propertyKeyword),
      functionDeclaration_returnType: node.returnType?.accept(this),
    );
    _storeNamedCompilationUnitMember(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitFunctionDeclarationStatement(
      FunctionDeclarationStatement node) {
    return LinkedNodeBuilder.functionDeclarationStatement(
      functionDeclarationStatement_functionDeclaration:
          node.functionDeclaration.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitFunctionExpression(FunctionExpression node) {
    return LinkedNodeBuilder.functionExpression(
      functionExpression_body: node.body?.accept(this),
      functionExpression_formalParameters: node.parameters?.accept(this),
      functionExpression_typeParameters: node.typeParameters?.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitFunctionExpressionInvocation(
      FunctionExpressionInvocation node) {
    var builder = LinkedNodeBuilder.functionExpressionInvocation(
      functionExpressionInvocation_function: node.function?.accept(this),
    );
    _storeInvocationExpression(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitFunctionTypeAlias(FunctionTypeAlias node) {
    var builder = LinkedNodeBuilder.functionTypeAlias(
      functionTypeAlias_formalParameters: node.parameters.accept(this),
      functionTypeAlias_returnType: node.returnType?.accept(this),
      functionTypeAlias_typeParameters: node.typeParameters?.accept(this),
    );
    _storeTypeAlias(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitFunctionTypedFormalParameter(
      FunctionTypedFormalParameter node) {
    var builder = LinkedNodeBuilder.functionTypedFormalParameter(
      functionTypedFormalParameter_formalParameters:
          node.parameters.accept(this),
      functionTypedFormalParameter_returnType: node.returnType?.accept(this),
      functionTypedFormalParameter_typeParameters:
          node.typeParameters?.accept(this),
    );
    _storeNormalFormalParameter(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitGenericFunctionType(GenericFunctionType node) {
    return LinkedNodeBuilder.genericFunctionType(
      genericFunctionType_formalParameters: node.parameters.accept(this),
      genericFunctionType_functionKeyword: _getToken(node.functionKeyword),
      genericFunctionType_question: _getToken(node.question),
      genericFunctionType_returnType: node.returnType?.accept(this),
      genericFunctionType_typeParameters: node.typeParameters?.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitGenericTypeAlias(GenericTypeAlias node) {
    var builder = LinkedNodeBuilder.genericTypeAlias(
      genericTypeAlias_equals: _getToken(node.equals),
      genericTypeAlias_functionType: node.functionType.accept(this),
      genericTypeAlias_typeParameters: node.typeParameters?.accept(this),
    );
    _storeTypeAlias(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitHideCombinator(HideCombinator node) {
    var builder = LinkedNodeBuilder.hideCombinator(
      hideCombinator_hiddenNames: _writeNodeList(node.hiddenNames),
    );
    _storeCombinator(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitIfStatement(IfStatement node) {
    return LinkedNodeBuilder.ifStatement(
      ifStatement_condition: node.condition.accept(this),
      ifStatement_elseKeyword: _getToken(node.elseKeyword),
      ifStatement_elseStatement: node.elseStatement?.accept(this),
      ifStatement_ifKeyword: _getToken(node.ifKeyword),
      ifStatement_leftParenthesis: _getToken(node.leftParenthesis),
      ifStatement_rightParenthesis: _getToken(node.rightParenthesis),
      ifStatement_thenStatement: node.thenStatement.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitImplementsClause(ImplementsClause node) {
    return LinkedNodeBuilder.implementsClause(
      implementsClause_implementsKeyword: _getToken(node.implementsKeyword),
      implementsClause_interfaces: _writeNodeList(node.interfaces),
    );
  }

  @override
  LinkedNodeBuilder visitImportDirective(ImportDirective node) {
    var builder = LinkedNodeBuilder.importDirective(
      importDirective_asKeyword: _getToken(node.asKeyword),
      importDirective_deferredKeyword: _getToken(node.deferredKeyword),
      importDirective_prefix: node.prefix?.accept(this),
    );
    _storeNamespaceDirective(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitIndexExpression(IndexExpression node) {
    return LinkedNodeBuilder.indexExpression(
      indexExpression_element: _getReference(node.staticElement).index,
      indexExpression_index: node.index.accept(this),
      indexExpression_leftBracket: _getToken(node.leftBracket),
      indexExpression_rightBracket: _getToken(node.rightBracket),
      indexExpression_target: node.target?.accept(this),
      expression_type: _writeType(node.staticType),
    );
  }

  @override
  LinkedNodeBuilder visitInstanceCreationExpression(
      InstanceCreationExpression node) {
    InstanceCreationExpressionImpl nodeImpl = node;
    return LinkedNodeBuilder.instanceCreationExpression(
      instanceCreationExpression_arguments: node.argumentList.accept(this),
      instanceCreationExpression_constructorName:
          node.constructorName.accept(this),
      instanceCreationExpression_keyword: _getToken(node.keyword),
      instanceCreationExpression_typeArguments:
          nodeImpl.typeArguments?.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitIntegerLiteral(IntegerLiteral node) {
    return LinkedNodeBuilder.integerLiteral(
      integerLiteral_literal: _getToken(node.literal),
      integerLiteral_value: node.value,
      expression_type: _writeType(node.staticType),
    );
  }

  @override
  LinkedNodeBuilder visitInterpolationExpression(InterpolationExpression node) {
    return LinkedNodeBuilder.interpolationExpression(
      interpolationExpression_expression: node.expression.accept(this),
      interpolationExpression_leftBracket: _getToken(node.leftBracket),
      interpolationExpression_rightBracket: _getToken(node.rightBracket),
    );
  }

  @override
  LinkedNodeBuilder visitInterpolationString(InterpolationString node) {
    return LinkedNodeBuilder.interpolationString(
      interpolationString_token: _getToken(node.contents),
      interpolationString_value: node.value,
    );
  }

  @override
  LinkedNodeBuilder visitIsExpression(IsExpression node) {
    var builder = LinkedNodeBuilder.isExpression(
      isExpression_expression: node.expression.accept(this),
      isExpression_isOperator: _getToken(node.isOperator),
      isExpression_notOperator: _getToken(node.notOperator),
      isExpression_type: node.type.accept(this),
    );
    _storeExpression(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitLabel(Label node) {
    return LinkedNodeBuilder.label(
      label_label: node.label.accept(this),
      label_colon: _getToken(node.colon),
    );
  }

  @override
  LinkedNodeBuilder visitLibraryDirective(LibraryDirective node) {
    var builder = LinkedNodeBuilder.libraryDirective(
      libraryDirective_name: node.name.accept(this),
    );
    _storeDirective(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitLibraryIdentifier(LibraryIdentifier node) {
    return LinkedNodeBuilder.libraryIdentifier(
      libraryIdentifier_components: _writeNodeList(node.components),
    );
  }

  @override
  LinkedNodeBuilder visitListLiteral(ListLiteral node) {
    var builder = LinkedNodeBuilder.listLiteral(
      listLiteral_elements: _writeNodeList(node.elements2),
      listLiteral_leftBracket: _getToken(node.leftBracket),
      listLiteral_rightBracket: _getToken(node.rightBracket),
    );
    _storeTypedLiteral(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitMapLiteral(MapLiteral node) {
    var builder = LinkedNodeBuilder.mapLiteral(
      mapLiteral_entries: _writeNodeList(node.entries),
      mapLiteral_leftBracket: _getToken(node.leftBracket),
      mapLiteral_rightBracket: _getToken(node.rightBracket),
    );
    _storeTypedLiteral(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitMapLiteralEntry(MapLiteralEntry node) {
    return LinkedNodeBuilder.mapLiteralEntry(
      mapLiteralEntry_key: node.key.accept(this),
      mapLiteralEntry_separator: _getToken(node.separator),
      mapLiteralEntry_value: node.value.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitMethodDeclaration(MethodDeclaration node) {
    var builder = LinkedNodeBuilder.methodDeclaration(
      methodDeclaration_body: node.body?.accept(this),
      methodDeclaration_externalKeyword: _getToken(node.externalKeyword),
      methodDeclaration_formalParameters: node.parameters?.accept(this),
      methodDeclaration_modifierKeyword: _getToken(node.modifierKeyword),
      methodDeclaration_name: node.name.accept(this),
      methodDeclaration_operatorKeyword: _getToken(node.operatorKeyword),
      methodDeclaration_propertyKeyword: _getToken(node.propertyKeyword),
      methodDeclaration_returnType: node.returnType?.accept(this),
    );
    _storeClassMember(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitMethodInvocation(MethodInvocation node) {
    var builder = LinkedNodeBuilder.methodInvocation(
      methodInvocation_methodName: node.methodName?.accept(this),
      methodInvocation_operator: _getToken(node.operator),
      methodInvocation_target: node.target?.accept(this),
    );
    _storeInvocationExpression(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitMixinDeclaration(MixinDeclaration node) {
    var builder = LinkedNodeBuilder.mixinDeclaration(
      mixinDeclaration_mixinKeyword: _getToken(node.mixinKeyword),
      mixinDeclaration_onClause: node.onClause?.accept(this),
    );
    _storeClassOrMixinDeclaration(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitNamedExpression(NamedExpression node) {
    return LinkedNodeBuilder.namedExpression(
      namedExpression_expression: node.expression.accept(this),
      namedExpression_name: node.name.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitNullLiteral(NullLiteral node) {
    var builder = LinkedNodeBuilder.nullLiteral(
      nullLiteral_literal: _getToken(node.literal),
    );
    _storeExpression(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitOnClause(OnClause node) {
    return LinkedNodeBuilder.onClause(
      onClause_onKeyword: _getToken(node.onKeyword),
      onClause_superclassConstraints:
          _writeNodeList(node.superclassConstraints),
    );
  }

  @override
  LinkedNodeBuilder visitParenthesizedExpression(ParenthesizedExpression node) {
    var builder = LinkedNodeBuilder.parenthesizedExpression(
      parenthesizedExpression_expression: node.expression.accept(this),
      parenthesizedExpression_leftParenthesis: _getToken(node.leftParenthesis),
      parenthesizedExpression_rightParenthesis:
          _getToken(node.rightParenthesis),
    );
    _storeExpression(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitPartDirective(PartDirective node) {
    var builder = LinkedNodeBuilder.partDirective();
    _storeUriBasedDirective(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitPartOfDirective(PartOfDirective node) {
    var builder = LinkedNodeBuilder.partOfDirective(
      partOfDirective_libraryName: node.libraryName?.accept(this),
      partOfDirective_ofKeyword: _getToken(node.ofKeyword),
      partOfDirective_semicolon: _getToken(node.semicolon),
      partOfDirective_uri: node.uri?.accept(this),
    );
    _storeDirective(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitPostfixExpression(PostfixExpression node) {
    return LinkedNodeBuilder.postfixExpression(
      expression_type: _writeType(node.staticType),
      postfixExpression_element: _getReference(node.staticElement).index,
      postfixExpression_operand: node.operand.accept(this),
      postfixExpression_operator: _getToken(node.operator),
    );
  }

  @override
  LinkedNodeBuilder visitPrefixedIdentifier(PrefixedIdentifier node) {
    return LinkedNodeBuilder.prefixedIdentifier(
      prefixedIdentifier_identifier: node.identifier.accept(this),
      prefixedIdentifier_period: _getToken(node.period),
      prefixedIdentifier_prefix: node.prefix.accept(this),
      expression_type: _writeType(node.staticType),
    );
  }

  @override
  LinkedNodeBuilder visitPrefixExpression(PrefixExpression node) {
    return LinkedNodeBuilder.prefixExpression(
      expression_type: _writeType(node.staticType),
      prefixExpression_element: _getReference(node.staticElement).index,
      prefixExpression_operand: node.operand.accept(this),
      prefixExpression_operator: _getToken(node.operator),
    );
  }

  @override
  LinkedNodeBuilder visitPropertyAccess(PropertyAccess node) {
    var builder = LinkedNodeBuilder.propertyAccess(
      propertyAccess_operator: _getToken(node.operator),
      propertyAccess_propertyName: node.propertyName.accept(this),
      propertyAccess_target: node.target?.accept(this),
    );
    _storeExpression(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    var builder = LinkedNodeBuilder.redirectingConstructorInvocation(
      redirectingConstructorInvocation_arguments:
          node.argumentList.accept(this),
      redirectingConstructorInvocation_constructorName:
          node.constructorName?.accept(this),
      redirectingConstructorInvocation_element:
          _getReference(node.staticElement).index,
      redirectingConstructorInvocation_period: _getToken(node.period),
      redirectingConstructorInvocation_thisKeyword: _getToken(node.thisKeyword),
    );
    _storeConstructorInitializer(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitRethrowExpression(RethrowExpression node) {
    var builder = LinkedNodeBuilder.rethrowExpression(
      rethrowExpression_rethrowKeyword: _getToken(node.rethrowKeyword),
    );
    _storeExpression(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitReturnStatement(ReturnStatement node) {
    return LinkedNodeBuilder.returnStatement(
      returnStatement_expression: node.expression?.accept(this),
      returnStatement_returnKeyword: _getToken(node.returnKeyword),
      returnStatement_semicolon: _getToken(node.semicolon),
    );
  }

  @override
  LinkedNodeBuilder visitShowCombinator(ShowCombinator node) {
    var builder = LinkedNodeBuilder.showCombinator(
      showCombinator_shownNames: _writeNodeList(node.shownNames),
    );
    _storeCombinator(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitSimpleFormalParameter(SimpleFormalParameter node) {
    var builder = LinkedNodeBuilder.simpleFormalParameter(
      simpleFormalParameter_keyword: _getToken(node.keyword),
      simpleFormalParameter_type: node.type?.accept(this),
    );
    _storeNormalFormalParameter(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitSimpleIdentifier(SimpleIdentifier node) {
    var isDeclared = node.inDeclarationContext();

    return LinkedNodeBuilder.simpleIdentifier(
      simpleIdentifier_element:
          isDeclared ? null : _getReference(node.staticElement).index,
      simpleIdentifier_token: _getToken(node.token),
      expression_type: _writeType(node.staticType),
    );
  }

  @override
  LinkedNodeBuilder visitSimpleStringLiteral(SimpleStringLiteral node) {
    var builder = LinkedNodeBuilder.simpleStringLiteral(
      simpleStringLiteral_token: _getToken(node.literal),
      simpleStringLiteral_value: node.value,
    );
    _storeExpression(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitStringInterpolation(StringInterpolation node) {
    return LinkedNodeBuilder.stringInterpolation(
      stringInterpolation_elements: _writeNodeList(node.elements),
      expression_type: _writeType(node.staticType),
    );
  }

  @override
  LinkedNodeBuilder visitSuperConstructorInvocation(
      SuperConstructorInvocation node) {
    var builder = LinkedNodeBuilder.superConstructorInvocation(
      superConstructorInvocation_arguments: node.argumentList.accept(this),
      superConstructorInvocation_constructorName:
          node.constructorName?.accept(this),
      superConstructorInvocation_element:
          _getReference(node.staticElement).index,
      superConstructorInvocation_period: _getToken(node.period),
      superConstructorInvocation_superKeyword: _getToken(node.superKeyword),
    );
    _storeConstructorInitializer(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitSuperExpression(SuperExpression node) {
    var builder = LinkedNodeBuilder.superExpression(
      superExpression_superKeyword: _getToken(node.superKeyword),
    );
    _storeExpression(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitSwitchCase(SwitchCase node) {
    var builder = LinkedNodeBuilder.switchCase(
      switchCase_expression: node.expression.accept(this),
    );
    _storeSwitchMember(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitSwitchDefault(SwitchDefault node) {
    var builder = LinkedNodeBuilder.switchDefault();
    _storeSwitchMember(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitSwitchStatement(SwitchStatement node) {
    return LinkedNodeBuilder.switchStatement(
      switchStatement_expression: node.expression.accept(this),
      switchStatement_leftBracket: _getToken(node.leftBracket),
      switchStatement_leftParenthesis: _getToken(node.leftParenthesis),
      switchStatement_members: _writeNodeList(node.members),
      switchStatement_rightBracket: _getToken(node.rightBracket),
      switchStatement_rightParenthesis: _getToken(node.rightParenthesis),
      switchStatement_switchKeyword: _getToken(node.switchKeyword),
    );
  }

  @override
  LinkedNodeBuilder visitSymbolLiteral(SymbolLiteral node) {
    var builder = LinkedNodeBuilder.symbolLiteral(
      symbolLiteral_poundSign: _getToken(node.poundSign),
      symbolLiteral_components: _getTokens(node.components),
    );
    _storeExpression(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitThisExpression(ThisExpression node) {
    var builder = LinkedNodeBuilder.thisExpression(
      thisExpression_thisKeyword: _getToken(node.thisKeyword),
    );
    _storeExpression(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitThrowExpression(ThrowExpression node) {
    return LinkedNodeBuilder.throwExpression(
      throwExpression_expression: node.expression.accept(this),
      throwExpression_throwKeyword: _getToken(node.throwKeyword),
      expression_type: _writeType(node.staticType),
    );
  }

  @override
  LinkedNodeBuilder visitTopLevelVariableDeclaration(
      TopLevelVariableDeclaration node) {
    var builder = LinkedNodeBuilder.topLevelVariableDeclaration(
      topLevelVariableDeclaration_semicolon: _getToken(node.semicolon),
      topLevelVariableDeclaration_variableList: node.variables?.accept(this),
    );
    _storeCompilationUnitMember(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitTryStatement(TryStatement node) {
    return LinkedNodeBuilder.tryStatement(
      tryStatement_body: node.body.accept(this),
      tryStatement_catchClauses: _writeNodeList(node.catchClauses),
      tryStatement_finallyBlock: node.finallyBlock?.accept(this),
      tryStatement_finallyKeyword: _getToken(node.finallyKeyword),
      tryStatement_tryKeyword: _getToken(node.tryKeyword),
    );
  }

  @override
  LinkedNodeBuilder visitTypeArgumentList(TypeArgumentList node) {
    return LinkedNodeBuilder.typeArgumentList(
      typeArgumentList_arguments: _writeNodeList(node.arguments),
      typeArgumentList_leftBracket: _getToken(node.leftBracket),
      typeArgumentList_rightBracket: _getToken(node.rightBracket),
    );
  }

  @override
  LinkedNodeBuilder visitTypeName(TypeName node) {
    return LinkedNodeBuilder.typeName(
      typeName_name: node.name.accept(this),
      typeName_question: _getToken(node.question),
      typeName_type: _writeType(node.type),
      typeName_typeArguments: node.typeArguments?.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitTypeParameter(TypeParameter node) {
    var builder = LinkedNodeBuilder.typeParameter(
        typeParameter_bound: node.bound?.accept(this),
        typeParameter_extendsKeyword: _getToken(node.extendsKeyword),
        typeParameter_name: node.name.accept(this));
    _storeDeclaration(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitTypeParameterList(TypeParameterList node) {
    return LinkedNodeBuilder.typeParameterList(
      typeParameterList_leftBracket: _getToken(node.leftBracket),
      typeParameterList_rightBracket: _getToken(node.rightBracket),
      typeParameterList_typeParameters: _writeNodeList(node.typeParameters),
    );
  }

  @override
  LinkedNodeBuilder visitVariableDeclaration(VariableDeclaration node) {
    return LinkedNodeBuilder.variableDeclaration(
      variableDeclaration_equals: _getToken(node.equals),
      variableDeclaration_initializer: node.initializer?.accept(this),
      variableDeclaration_name: node.name.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitVariableDeclarationList(VariableDeclarationList node) {
    var builder = LinkedNodeBuilder.variableDeclarationList(
      variableDeclarationList_keyword: _getToken(node.keyword),
      variableDeclarationList_type: node.type?.accept(this),
      variableDeclarationList_variables: _writeNodeList(node.variables),
    );
    _storeAnnotatedNode(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitVariableDeclarationStatement(
      VariableDeclarationStatement node) {
    return LinkedNodeBuilder.variableDeclarationStatement(
      variableDeclarationStatement_semicolon: _getToken(node.semicolon),
      variableDeclarationStatement_variables: node.variables.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitWhileStatement(WhileStatement node) {
    return LinkedNodeBuilder.whileStatement(
      whileStatement_body: node.body.accept(this),
      whileStatement_condition: node.condition.accept(this),
      whileStatement_leftParenthesis: _getToken(node.leftParenthesis),
      whileStatement_rightParenthesis: _getToken(node.rightParenthesis),
      whileStatement_whileKeyword: _getToken(node.whileKeyword),
    );
  }

  @override
  LinkedNodeBuilder visitWithClause(WithClause node) {
    return LinkedNodeBuilder.withClause(
      withClause_mixinTypes: _writeNodeList(node.mixinTypes),
      withClause_withKeyword: _getToken(node.withKeyword),
    );
  }

  @override
  LinkedNodeBuilder visitYieldStatement(YieldStatement node) {
    var builder = LinkedNodeBuilder.yieldStatement(
      yieldStatement_yieldKeyword: _getToken(node.yieldKeyword),
      yieldStatement_expression: node.expression.accept(this),
      yieldStatement_semicolon: _getToken(node.semicolon),
      yieldStatement_star: _getToken(node.star),
    );
    _storeStatement(builder, node);
    return builder;
  }

  LinkedNodeBuilder writeNode(AstNode node) {
    _writeTokens(node.beginToken, node.endToken);
    return node.accept(this);
  }

  /// Write [referenceRoot] and all its children into [referenceBuilder].
  void writeReferences() {
    for (var reference in _references) {
      referenceBuilder.parent.add(reference.parent?.index ?? 0);
      referenceBuilder.name.add(reference.name);
    }
  }

  void _addToken({
    @required bool isSynthetic,
    @required UnlinkedTokenKind kind,
    @required int length,
    @required String lexeme,
    @required int offset,
    @required int precedingComment,
    @required UnlinkedTokenType type,
  }) {
    tokens.endGroup.add(0);
    tokens.isSynthetic.add(isSynthetic);
    tokens.kind.add(kind);
    tokens.length.add(length);
    tokens.lexeme.add(lexeme);
    tokens.next.add(0);
    tokens.offset.add(offset);
    tokens.precedingComment.add(precedingComment);
    tokens.type.add(type);
    _tokenIndex++;
  }

  void _ensureReferenceIndex(Reference reference) {
    if (reference.index == null) {
      reference.index = _references.length;
      _references.add(reference);
    }
  }

  Reference _getReference(Element element) {
    if (element == null) return referenceRoot;

    // TODO(scheglov) handle Member elements

    Reference result;
    if (element is ClassElement) {
      var containerRef = _getReference(element.library).getChild('@class');
      _ensureReferenceIndex(containerRef);

      result = containerRef.getChild(element.name);
    } else if (element is CompilationUnitElement) {
      return _getReference(element.enclosingElement);
    } else if (element is ConstructorElement) {
      var enclosingRef = _getReference(element.enclosingElement);
      var containerRef = enclosingRef.getChild('@constructor');
      _ensureReferenceIndex(containerRef);

      result = containerRef.getChild(element.name);
    } else if (element is DynamicElementImpl) {
      result = _getReference(element.library).getChild('@dynamic');
    } else if (element is FieldElement) {
      var enclosingRef = _getReference(element.enclosingElement);
      var containerRef = enclosingRef.getChild('@field');
      _ensureReferenceIndex(containerRef);

      result = containerRef.getChild(element.name);
    } else if (element is FunctionElement) {
      var containerRef = _getReference(element.library).getChild('@function');
      _ensureReferenceIndex(containerRef);

      result = containerRef.getChild(element.name ?? '');
    } else if (element is FunctionTypeAliasElement) {
      var libraryRef = _getReference(element.library);
      var containerRef = libraryRef.getChild('@functionTypeAlias');
      _ensureReferenceIndex(containerRef);

      result = containerRef.getChild(element.name);
    } else if (element is GenericFunctionTypeElement) {
      if (element.enclosingElement is GenericTypeAliasElement) {
        return _getReference(element.enclosingElement);
      } else {
        var libraryRef = _getReference(element.library);
        var containerRef = libraryRef.getChild('@functionType');
        _ensureReferenceIndex(containerRef);

        // TODO(scheglov) do we need to store these elements at all?
        result = containerRef.getChild('<unnamed>');
      }
    } else if (element is GenericTypeAliasElement) {
      var containerRef = _getReference(element.library).getChild('@typeAlias');
      _ensureReferenceIndex(containerRef);

      result = containerRef.getChild(element.name);
    } else if (element is GenericFunctionTypeElement &&
        element.enclosingElement is ParameterElement) {
      return _getReference(element.enclosingElement);
    } else if (element is LibraryElement) {
      var uriStr = element.source.uri.toString();
      result = referenceRoot.getChild(uriStr);
    } else if (element is LocalVariableElement) {
      var enclosingRef = _getReference(element.enclosingElement);
      var containerRef = enclosingRef.getChild('@localVariable');
      _ensureReferenceIndex(containerRef);

      // TODO(scheglov) use index instead of offset
      result = containerRef.getChild('${element.nameOffset}');
    } else if (element is MethodElement) {
      var enclosingRef = _getReference(element.enclosingElement);
      var containerRef = enclosingRef.getChild('@method');
      _ensureReferenceIndex(containerRef);

      result = containerRef.getChild(element.name);
    } else if (element is ParameterElement) {
      var enclosing = element.enclosingElement;
      var enclosingRef = _getReference(enclosing);
      var containerRef = enclosingRef.getChild('@parameter');
      _ensureReferenceIndex(containerRef);

      result = containerRef.getChild(element.name);
    } else if (element is PrefixElement) {
      var containerRef = _getReference(element.library).getChild('@prefix');
      _ensureReferenceIndex(containerRef);

      result = containerRef.getChild(element.name);
    } else if (element is PropertyAccessorElement) {
      var enclosingRef = _getReference(element.library);
      var containerRef = enclosingRef.getChild(
        element.isGetter ? '@getter' : '@setter',
      );
      _ensureReferenceIndex(containerRef);

      result = containerRef.getChild(element.displayName);
    } else if (element is TopLevelVariableElement) {
      var enclosingRef = _getReference(element.library);
      var containerRef = enclosingRef.getChild('@variable');
      _ensureReferenceIndex(containerRef);

      result = containerRef.getChild(element.name);
    } else if (element is TypeParameterElement) {
      var enclosingRef = _getReference(element.enclosingElement);
      var containerRef = enclosingRef.getChild('@typeParameter');
      _ensureReferenceIndex(containerRef);

      result = containerRef.getChild(element.name);
    } else {
      throw UnimplementedError('(${element.runtimeType}) $element');
    }
    _ensureReferenceIndex(result);
    return result;
  }

  List<int> _getReferences(List<Element> elements) {
    var result = List<int>(elements.length);
    for (var i = 0; i < elements.length; ++i) {
      var element = elements[i];
      result[i] = _getReference(element).index;
    }
    return result;
  }

  int _getToken(Token token) {
    if (token == null) return 0;

    var index = _tokenMap[token];
    if (index == null) {
      throw StateError('Token must be written first: $token');
    }
    return index;
  }

  List<int> _getTokens(List<Token> tokenList) {
    var result = List<int>(tokenList.length);
    for (var i = 0; i < tokenList.length; ++i) {
      var token = tokenList[i];
      result[i] = _getToken(token);
    }
    return result;
  }

  void _storeAnnotatedNode(LinkedNodeBuilder builder, AnnotatedNode node) {
    builder
      ..annotatedNode_comment = node.documentationComment?.accept(this)
      ..annotatedNode_metadata = _writeNodeList(node.metadata);
  }

  void _storeClassMember(LinkedNodeBuilder builder, ClassMember node) {
    _storeDeclaration(builder, node);
  }

  void _storeClassOrMixinDeclaration(
      LinkedNodeBuilder builder, ClassOrMixinDeclaration node) {
    builder
      ..classOrMixinDeclaration_implementsClause =
          node.implementsClause?.accept(this)
      ..classOrMixinDeclaration_leftBracket = _getToken(node.leftBracket)
      ..classOrMixinDeclaration_members = _writeNodeList(node.members)
      ..classOrMixinDeclaration_rightBracket = _getToken(node.rightBracket)
      ..classOrMixinDeclaration_typeParameters =
          node.typeParameters?.accept(this);
    _storeNamedCompilationUnitMember(builder, node);
  }

  void _storeCombinator(LinkedNodeBuilder builder, Combinator node) {
    builder.combinator_keyword = _getToken(node.keyword);
  }

  void _storeCompilationUnitMember(
      LinkedNodeBuilder builder, CompilationUnitMember node) {
    _storeDeclaration(builder, node);
  }

  void _storeConstructorInitializer(
      LinkedNodeBuilder builder, ConstructorInitializer node) {}

  void _storeDeclaration(LinkedNodeBuilder builder, Declaration node) {
    _storeAnnotatedNode(builder, node);
  }

  void _storeDirective(LinkedNodeBuilder builder, Directive node) {
    _storeAnnotatedNode(builder, node);
    builder..directive_keyword = _getToken(node.keyword);
  }

  void _storeExpression(LinkedNodeBuilder builder, Expression node) {
    builder.expression_type = _writeType(node.staticType);
  }

  void _storeFormalParameter(LinkedNodeBuilder builder, FormalParameter node) {
    var kind = LinkedNodeFormalParameterKind.required;
    if (node.isNamed) {
      kind = LinkedNodeFormalParameterKind.optionalNamed;
    } else if (node.isOptionalPositional) {
      kind = LinkedNodeFormalParameterKind.optionalPositional;
    }

    builder.formalParameter_kind = kind;
  }

  void _storeFunctionBody(LinkedNodeBuilder builder, FunctionBody node) {}

  void _storeInvocationExpression(
      LinkedNodeBuilder builder, InvocationExpression node) {
    _storeExpression(builder, node);
    builder
      ..invocationExpression_arguments = node.argumentList.accept(this)
      ..invocationExpression_invokeType = _writeType(node.staticInvokeType)
      ..invocationExpression_typeArguments = node.typeArguments?.accept(this);
  }

  void _storeNamedCompilationUnitMember(
      LinkedNodeBuilder builder, NamedCompilationUnitMember node) {
    _storeCompilationUnitMember(builder, node);
    builder..namedCompilationUnitMember_name = node.name.accept(this);
  }

  void _storeNamespaceDirective(
      LinkedNodeBuilder builder, NamespaceDirective node) {
    _storeUriBasedDirective(builder, node);
    builder
      ..namespaceDirective_combinators = _writeNodeList(node.combinators)
      ..namespaceDirective_configurations = _writeNodeList(node.configurations)
      ..namespaceDirective_selectedUriContent = node.selectedUriContent
      ..namespaceDirective_semicolon = _getToken(node.semicolon);
  }

  void _storeNormalFormalParameter(
      LinkedNodeBuilder builder, NormalFormalParameter node) {
    _storeFormalParameter(builder, node);
    builder
      ..normalFormalParameter_comment = node.documentationComment?.accept(this)
      ..normalFormalParameter_covariantKeyword =
          _getToken(node.covariantKeyword)
      ..normalFormalParameter_identifier = node.identifier?.accept(this)
      ..normalFormalParameter_metadata = _writeNodeList(node.metadata);
  }

  void _storeStatement(LinkedNodeBuilder builder, Statement node) {}

  void _storeSwitchMember(LinkedNodeBuilder builder, SwitchMember node) {
    builder.switchMember_colon = _getToken(node.colon);
    builder.switchMember_keyword = _getToken(node.keyword);
    builder.switchMember_labels = _writeNodeList(node.labels);
    builder.switchMember_statements = _writeNodeList(node.statements);
  }

  void _storeTypeAlias(LinkedNodeBuilder builder, TypeAlias node) {
    _storeNamedCompilationUnitMember(builder, node);
    builder
      ..typeAlias_semicolon = _getToken(node.semicolon)
      ..typeAlias_typedefKeyword = _getToken(node.typedefKeyword);
  }

  void _storeTypedLiteral(LinkedNodeBuilder builder, TypedLiteral node) {
    _storeExpression(builder, node);
    builder
      ..typedLiteral_constKeyword = _getToken(node.constKeyword)
      ..typedLiteral_typeArguments = node.typeArguments?.accept(this);
  }

  void _storeUriBasedDirective(
      LinkedNodeBuilder builder, UriBasedDirective node) {
    _storeDirective(builder, node);
    builder
      ..uriBasedDirective_uri = node.uri.accept(this)
      ..uriBasedDirective_uriContent = node.uriContent
      ..uriBasedDirective_uriElement = _getReference(node.uriElement).index;
  }

  int _writeCommentToken(CommentToken token) {
    if (token == null) return 0;
    var firstIndex = _tokenIndex;

    var previousIndex = 0;
    while (token != null) {
      var index = _tokenIndex;
      _tokenMap[token] = index;
      _addToken(
        isSynthetic: false,
        kind: UnlinkedTokenKind.comment,
        length: token.length,
        lexeme: token.lexeme,
        offset: token.offset,
        precedingComment: 0,
        type: _astToBinaryTokenType(token.type),
      );

      if (previousIndex != 0) {
        tokens.next[previousIndex] = index;
      }
      previousIndex = index;

      token = token.next;
    }

    return firstIndex;
  }

  List<LinkedNodeBuilder> _writeNodeList(List<AstNode> nodeList) {
    var result = List<LinkedNodeBuilder>.filled(nodeList.length, null);
    for (var i = 0; i < nodeList.length; ++i) {
      result[i] = nodeList[i].accept(this);
    }
    return result;
  }

  int _writeToken(Token token) {
    assert(_tokenMap[token] == null);

    var commentIndex = _writeCommentToken(token.precedingComments);

    var index = _tokenIndex;
    _tokenMap[token] = index;

    if (token is KeywordToken) {
      _addToken(
        isSynthetic: token.isSynthetic,
        kind: UnlinkedTokenKind.keyword,
        lexeme: '',
        offset: token.offset,
        length: token.length,
        precedingComment: commentIndex,
        type: _astToBinaryTokenType(token.type),
      );
    } else if (token is StringToken) {
      _addToken(
        isSynthetic: token.isSynthetic,
        kind: UnlinkedTokenKind.string,
        lexeme: token.lexeme,
        offset: token.offset,
        length: token.length,
        precedingComment: commentIndex,
        type: _astToBinaryTokenType(token.type),
      );
    } else if (token is SimpleToken) {
      _addToken(
        isSynthetic: token.isSynthetic,
        kind: UnlinkedTokenKind.simple,
        lexeme: token.lexeme,
        offset: token.offset,
        length: token.length,
        precedingComment: commentIndex,
        type: _astToBinaryTokenType(token.type),
      );
    } else {
      throw UnimplementedError('(${token.runtimeType}) $token');
    }

    return index;
  }

  /// Write all the tokens from the [first] to the [last] inclusively.
  void _writeTokens(Token first, Token last) {
    if (first is CommentToken) {
      first = (first as CommentToken).parent;
    }

    var endGroupToBeginIndexMap = <Token, int>{};
    var previousIndex = 0;
    for (var token = first;; token = token.next) {
      var index = _writeToken(token);

      if (previousIndex != 0) {
        tokens.next[previousIndex] = index;
      }
      previousIndex = index;

      if (token.endGroup != null) {
        endGroupToBeginIndexMap[token.endGroup] = index;
      }

      var beginIndex = endGroupToBeginIndexMap[token];
      if (beginIndex != null) {
        tokens.endGroup[beginIndex] = index;
      }

      if (token == last) break;
    }
  }

  LinkedNodeTypeBuilder _writeType(DartType type) {
    if (type == null) return null;

    if (type.isBottom) {
      return LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.bottom,
      );
    } else if (type.isDynamic) {
      return LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.dynamic_,
      );
    } else if (type is FunctionType) {
      return LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.function,
        functionFormalParameters: _getReferences(type.parameters),
        functionReturnType: _writeType(type.returnType),
        functionTypeParameters: _getReferences(type.parameters),
      );
    } else if (type is InterfaceType) {
      return LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.interface,
        interfaceClass: _getReference(type.element).index,
        interfaceTypeArguments: type.typeArguments.map(_writeType).toList(),
      );
    } else if (type is TypeParameterType) {
      return LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.typeParameter,
        typeParameterParameter: _getReference(type.element).index,
      );
    } else if (type is VoidType) {
      return LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.void_,
      );
    } else {
      throw UnimplementedError('(${type.runtimeType}) $type');
    }
  }

  static UnlinkedTokenType _astToBinaryTokenType(TokenType type) {
    if (type == Keyword.ABSTRACT) {
      return UnlinkedTokenType.ABSTRACT;
    } else if (type == TokenType.AMPERSAND) {
      return UnlinkedTokenType.AMPERSAND;
    } else if (type == TokenType.AMPERSAND_AMPERSAND) {
      return UnlinkedTokenType.AMPERSAND_AMPERSAND;
    } else if (type == TokenType.AMPERSAND_EQ) {
      return UnlinkedTokenType.AMPERSAND_EQ;
    } else if (type == TokenType.AS) {
      return UnlinkedTokenType.AS;
    } else if (type == Keyword.ASSERT) {
      return UnlinkedTokenType.ASSERT;
    } else if (type == Keyword.ASYNC) {
      return UnlinkedTokenType.ASYNC;
    } else if (type == TokenType.AT) {
      return UnlinkedTokenType.AT;
    } else if (type == Keyword.AWAIT) {
      return UnlinkedTokenType.AWAIT;
    } else if (type == TokenType.BACKPING) {
      return UnlinkedTokenType.BACKPING;
    } else if (type == TokenType.BACKSLASH) {
      return UnlinkedTokenType.BACKSLASH;
    } else if (type == TokenType.BANG) {
      return UnlinkedTokenType.BANG;
    } else if (type == TokenType.BANG_EQ) {
      return UnlinkedTokenType.BANG_EQ;
    } else if (type == TokenType.BAR) {
      return UnlinkedTokenType.BAR;
    } else if (type == TokenType.BAR_BAR) {
      return UnlinkedTokenType.BAR_BAR;
    } else if (type == TokenType.BAR_EQ) {
      return UnlinkedTokenType.BAR_EQ;
    } else if (type == Keyword.BREAK) {
      return UnlinkedTokenType.BREAK;
    } else if (type == TokenType.CARET) {
      return UnlinkedTokenType.CARET;
    } else if (type == TokenType.CARET_EQ) {
      return UnlinkedTokenType.CARET_EQ;
    } else if (type == Keyword.CASE) {
      return UnlinkedTokenType.CASE;
    } else if (type == Keyword.CATCH) {
      return UnlinkedTokenType.CATCH;
    } else if (type == Keyword.CLASS) {
      return UnlinkedTokenType.CLASS;
    } else if (type == TokenType.CLOSE_CURLY_BRACKET) {
      return UnlinkedTokenType.CLOSE_CURLY_BRACKET;
    } else if (type == TokenType.CLOSE_PAREN) {
      return UnlinkedTokenType.CLOSE_PAREN;
    } else if (type == TokenType.CLOSE_SQUARE_BRACKET) {
      return UnlinkedTokenType.CLOSE_SQUARE_BRACKET;
    } else if (type == TokenType.COLON) {
      return UnlinkedTokenType.COLON;
    } else if (type == TokenType.COMMA) {
      return UnlinkedTokenType.COMMA;
    } else if (type == Keyword.CONST) {
      return UnlinkedTokenType.CONST;
    } else if (type == Keyword.CONTINUE) {
      return UnlinkedTokenType.CONTINUE;
    } else if (type == Keyword.COVARIANT) {
      return UnlinkedTokenType.COVARIANT;
    } else if (type == Keyword.DEFAULT) {
      return UnlinkedTokenType.DEFAULT;
    } else if (type == Keyword.DEFERRED) {
      return UnlinkedTokenType.DEFERRED;
    } else if (type == Keyword.DO) {
      return UnlinkedTokenType.DO;
    } else if (type == TokenType.DOUBLE) {
      return UnlinkedTokenType.DOUBLE;
    } else if (type == Keyword.DYNAMIC) {
      return UnlinkedTokenType.DYNAMIC;
    } else if (type == Keyword.ELSE) {
      return UnlinkedTokenType.ELSE;
    } else if (type == Keyword.ENUM) {
      return UnlinkedTokenType.ENUM;
    } else if (type == TokenType.EOF) {
      return UnlinkedTokenType.EOF;
    } else if (type == TokenType.EQ) {
      return UnlinkedTokenType.EQ;
    } else if (type == TokenType.EQ_EQ) {
      return UnlinkedTokenType.EQ_EQ;
    } else if (type == Keyword.EXPORT) {
      return UnlinkedTokenType.EXPORT;
    } else if (type == Keyword.EXTENDS) {
      return UnlinkedTokenType.EXTENDS;
    } else if (type == Keyword.EXTERNAL) {
      return UnlinkedTokenType.EXTERNAL;
    } else if (type == Keyword.FACTORY) {
      return UnlinkedTokenType.FACTORY;
    } else if (type == Keyword.FALSE) {
      return UnlinkedTokenType.FALSE;
    } else if (type == Keyword.FINAL) {
      return UnlinkedTokenType.FINAL;
    } else if (type == Keyword.FINALLY) {
      return UnlinkedTokenType.FINALLY;
    } else if (type == Keyword.FOR) {
      return UnlinkedTokenType.FOR;
    } else if (type == Keyword.FUNCTION) {
      return UnlinkedTokenType.FUNCTION_KEYWORD;
    } else if (type == TokenType.FUNCTION) {
      return UnlinkedTokenType.FUNCTION;
    } else if (type == Keyword.GET) {
      return UnlinkedTokenType.GET;
    } else if (type == TokenType.GT) {
      return UnlinkedTokenType.GT;
    } else if (type == TokenType.GT_EQ) {
      return UnlinkedTokenType.GT_EQ;
    } else if (type == TokenType.GT_GT) {
      return UnlinkedTokenType.GT_GT;
    } else if (type == TokenType.GT_GT_EQ) {
      return UnlinkedTokenType.GT_GT_EQ;
    } else if (type == TokenType.HASH) {
      return UnlinkedTokenType.HASH;
    } else if (type == TokenType.HEXADECIMAL) {
      return UnlinkedTokenType.HEXADECIMAL;
    } else if (type == Keyword.HIDE) {
      return UnlinkedTokenType.HIDE;
    } else if (type == TokenType.IDENTIFIER) {
      return UnlinkedTokenType.IDENTIFIER;
    } else if (type == Keyword.IF) {
      return UnlinkedTokenType.IF;
    } else if (type == Keyword.IMPLEMENTS) {
      return UnlinkedTokenType.IMPLEMENTS;
    } else if (type == Keyword.IMPORT) {
      return UnlinkedTokenType.IMPORT;
    } else if (type == Keyword.IN) {
      return UnlinkedTokenType.IN;
    } else if (type == TokenType.INDEX) {
      return UnlinkedTokenType.INDEX;
    } else if (type == TokenType.INDEX_EQ) {
      return UnlinkedTokenType.INDEX_EQ;
    } else if (type == TokenType.INT) {
      return UnlinkedTokenType.INT;
    } else if (type == Keyword.INTERFACE) {
      return UnlinkedTokenType.INTERFACE;
    } else if (type == TokenType.IS) {
      return UnlinkedTokenType.IS;
    } else if (type == Keyword.LIBRARY) {
      return UnlinkedTokenType.LIBRARY;
    } else if (type == TokenType.LT) {
      return UnlinkedTokenType.LT;
    } else if (type == TokenType.LT_EQ) {
      return UnlinkedTokenType.LT_EQ;
    } else if (type == TokenType.LT_LT) {
      return UnlinkedTokenType.LT_LT;
    } else if (type == TokenType.LT_LT_EQ) {
      return UnlinkedTokenType.LT_LT_EQ;
    } else if (type == TokenType.MINUS) {
      return UnlinkedTokenType.MINUS;
    } else if (type == TokenType.MINUS_EQ) {
      return UnlinkedTokenType.MINUS_EQ;
    } else if (type == TokenType.MINUS_MINUS) {
      return UnlinkedTokenType.MINUS_MINUS;
    } else if (type == Keyword.MIXIN) {
      return UnlinkedTokenType.MIXIN;
    } else if (type == TokenType.MULTI_LINE_COMMENT) {
      return UnlinkedTokenType.MULTI_LINE_COMMENT;
    } else if (type == Keyword.NATIVE) {
      return UnlinkedTokenType.NATIVE;
    } else if (type == Keyword.NEW) {
      return UnlinkedTokenType.NEW;
    } else if (type == Keyword.NULL) {
      return UnlinkedTokenType.NULL;
    } else if (type == Keyword.OF) {
      return UnlinkedTokenType.OF;
    } else if (type == Keyword.ON) {
      return UnlinkedTokenType.ON;
    } else if (type == TokenType.OPEN_CURLY_BRACKET) {
      return UnlinkedTokenType.OPEN_CURLY_BRACKET;
    } else if (type == TokenType.OPEN_PAREN) {
      return UnlinkedTokenType.OPEN_PAREN;
    } else if (type == TokenType.OPEN_SQUARE_BRACKET) {
      return UnlinkedTokenType.OPEN_SQUARE_BRACKET;
    } else if (type == Keyword.OPERATOR) {
      return UnlinkedTokenType.OPERATOR;
    } else if (type == Keyword.PART) {
      return UnlinkedTokenType.PART;
    } else if (type == Keyword.PATCH) {
      return UnlinkedTokenType.PATCH;
    } else if (type == TokenType.PERCENT) {
      return UnlinkedTokenType.PERCENT;
    } else if (type == TokenType.PERCENT_EQ) {
      return UnlinkedTokenType.PERCENT_EQ;
    } else if (type == TokenType.PERIOD) {
      return UnlinkedTokenType.PERIOD;
    } else if (type == TokenType.PERIOD_PERIOD) {
      return UnlinkedTokenType.PERIOD_PERIOD;
    } else if (type == TokenType.PERIOD_PERIOD_PERIOD) {
      return UnlinkedTokenType.PERIOD_PERIOD_PERIOD;
    } else if (type == TokenType.PERIOD_PERIOD_PERIOD_QUESTION) {
      return UnlinkedTokenType.PERIOD_PERIOD_PERIOD_QUESTION;
    } else if (type == TokenType.PLUS) {
      return UnlinkedTokenType.PLUS;
    } else if (type == TokenType.PLUS_EQ) {
      return UnlinkedTokenType.PLUS_EQ;
    } else if (type == TokenType.PLUS_PLUS) {
      return UnlinkedTokenType.PLUS_PLUS;
    } else if (type == TokenType.QUESTION) {
      return UnlinkedTokenType.QUESTION;
    } else if (type == TokenType.QUESTION_PERIOD) {
      return UnlinkedTokenType.QUESTION_PERIOD;
    } else if (type == TokenType.QUESTION_QUESTION) {
      return UnlinkedTokenType.QUESTION_QUESTION;
    } else if (type == TokenType.QUESTION_QUESTION_EQ) {
      return UnlinkedTokenType.QUESTION_QUESTION_EQ;
    } else if (type == Keyword.RETHROW) {
      return UnlinkedTokenType.RETHROW;
    } else if (type == Keyword.RETURN) {
      return UnlinkedTokenType.RETURN;
    } else if (type == TokenType.SCRIPT_TAG) {
      return UnlinkedTokenType.SCRIPT_TAG;
    } else if (type == TokenType.SEMICOLON) {
      return UnlinkedTokenType.SEMICOLON;
    } else if (type == Keyword.SET) {
      return UnlinkedTokenType.SET;
    } else if (type == Keyword.SHOW) {
      return UnlinkedTokenType.SHOW;
    } else if (type == TokenType.SINGLE_LINE_COMMENT) {
      return UnlinkedTokenType.SINGLE_LINE_COMMENT;
    } else if (type == TokenType.SLASH) {
      return UnlinkedTokenType.SLASH;
    } else if (type == TokenType.SLASH_EQ) {
      return UnlinkedTokenType.SLASH_EQ;
    } else if (type == Keyword.SOURCE) {
      return UnlinkedTokenType.SOURCE;
    } else if (type == TokenType.STAR) {
      return UnlinkedTokenType.STAR;
    } else if (type == TokenType.STAR_EQ) {
      return UnlinkedTokenType.STAR_EQ;
    } else if (type == Keyword.STATIC) {
      return UnlinkedTokenType.STATIC;
    } else if (type == TokenType.STRING) {
      return UnlinkedTokenType.STRING;
    } else if (type == TokenType.STRING_INTERPOLATION_EXPRESSION) {
      return UnlinkedTokenType.STRING_INTERPOLATION_EXPRESSION;
    } else if (type == TokenType.STRING_INTERPOLATION_IDENTIFIER) {
      return UnlinkedTokenType.STRING_INTERPOLATION_IDENTIFIER;
    } else if (type == Keyword.SUPER) {
      return UnlinkedTokenType.SUPER;
    } else if (type == Keyword.SWITCH) {
      return UnlinkedTokenType.SWITCH;
    } else if (type == Keyword.SYNC) {
      return UnlinkedTokenType.SYNC;
    } else if (type == Keyword.THIS) {
      return UnlinkedTokenType.THIS;
    } else if (type == Keyword.THROW) {
      return UnlinkedTokenType.THROW;
    } else if (type == TokenType.TILDE) {
      return UnlinkedTokenType.TILDE;
    } else if (type == TokenType.TILDE_SLASH) {
      return UnlinkedTokenType.TILDE_SLASH;
    } else if (type == TokenType.TILDE_SLASH_EQ) {
      return UnlinkedTokenType.TILDE_SLASH_EQ;
    } else if (type == Keyword.TRUE) {
      return UnlinkedTokenType.TRUE;
    } else if (type == Keyword.TRY) {
      return UnlinkedTokenType.TRY;
    } else if (type == Keyword.TYPEDEF) {
      return UnlinkedTokenType.TYPEDEF;
    } else if (type == Keyword.VAR) {
      return UnlinkedTokenType.VAR;
    } else if (type == Keyword.VOID) {
      return UnlinkedTokenType.VOID;
    } else if (type == Keyword.WHILE) {
      return UnlinkedTokenType.WHILE;
    } else if (type == Keyword.WITH) {
      return UnlinkedTokenType.WITH;
    } else if (type == Keyword.YIELD) {
      return UnlinkedTokenType.YIELD;
    } else {
      throw StateError('Unexpected type: $type');
    }
  }
}
