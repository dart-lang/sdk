// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/lazy_ast.dart';
import 'package:analyzer/src/summary2/linking_bundle_context.dart';
import 'package:analyzer/src/summary2/tokens_writer.dart';

/// Serializer of fully resolved ASTs into flat buffers.
class AstBinaryWriter extends ThrowingAstVisitor<LinkedNodeBuilder> {
  final LinkingBundleContext _linkingContext;
  final _tokensWriter = TokensWriter();

  /// This field is set temporary while visiting [FieldDeclaration] or
  /// [TopLevelVariableDeclaration] to store data shared among all variables
  /// in these declarations.
  LinkedNodeVariablesDeclarationBuilder _variablesDeclaration;

  AstBinaryWriter(this._linkingContext);

  UnlinkedTokensBuilder get tokensBuilder => _tokensWriter.tokensBuilder;

  @override
  LinkedNodeBuilder visitAdjacentStrings(AdjacentStrings node) {
    return LinkedNodeBuilder.adjacentStrings(
      adjacentStrings_strings: _writeNodeList(node.strings),
    );
  }

  @override
  LinkedNodeBuilder visitAnnotation(Annotation node) {
    var elementComponents = _componentsOfElement(node.element);
    return LinkedNodeBuilder.annotation(
      annotation_arguments: node.arguments?.accept(this),
      annotation_atSign: _getToken(node.atSign),
      annotation_constructorName: node.constructorName?.accept(this),
      annotation_element: elementComponents.rawElement,
      annotation_elementType: elementComponents.definingType,
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
    var elementComponents = _componentsOfElement(node.staticElement);
    return LinkedNodeBuilder.assignmentExpression(
      assignmentExpression_element: elementComponents.rawElement,
      assignmentExpression_elementType: elementComponents.definingType,
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
    var elementComponents = _componentsOfElement(node.staticElement);
    return LinkedNodeBuilder.binaryExpression(
      binaryExpression_element: elementComponents.rawElement,
      binaryExpression_elementType: elementComponents.definingType,
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
      classDeclaration_nativeClause: node.nativeClause?.accept(this),
      classDeclaration_withClause: node.withClause?.accept(this),
    );
    _storeClassOrMixinDeclaration(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitClassTypeAlias(ClassTypeAlias node) {
    var builder = LinkedNodeBuilder.classTypeAlias(
      classTypeAlias_abstractKeyword: _getToken(node.abstractKeyword),
      classTypeAlias_equals: _getToken(node.equals),
      classTypeAlias_implementsClause: node.implementsClause?.accept(this),
      classTypeAlias_superclass: node.superclass.accept(this),
      classTypeAlias_typeParameters: node.typeParameters?.accept(this),
      classTypeAlias_withClause: node.withClause.accept(this),
    );
    _storeTypeAlias(builder, node);
    _storeIsSimpleBounded(builder, node);
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
      comment_references: _writeNodeList(node.references),
    );
  }

  @override
  LinkedNodeBuilder visitCommentReference(CommentReference node) {
    var identifier = node.identifier;
    _tokensWriter.writeTokens(
      node.newKeyword ?? identifier.beginToken,
      identifier.endToken,
    );

    return LinkedNodeBuilder.commentReference(
      commentReference_identifier: identifier.accept(this),
      commentReference_newKeyword: _getToken(node.newKeyword),
    );
  }

  @override
  LinkedNodeBuilder visitCompilationUnit(CompilationUnit node) {
    var builder = LinkedNodeBuilder.compilationUnit(
      compilationUnit_beginToken: _getToken(node.beginToken),
      compilationUnit_declarations: _writeNodeList(node.declarations),
      compilationUnit_directives: _writeNodeList(node.directives),
      compilationUnit_endToken: _getToken(node.endToken),
      compilationUnit_scriptTag: node.scriptTag?.accept(this),
    );
    _storeCodeOffsetLength(builder, node);
    return builder;
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
  LinkedNodeBuilder visitConfiguration(Configuration node) {
    return LinkedNodeBuilder.configuration(
      configuration_equalToken: _getToken(node.equalToken),
      configuration_ifKeyword: _getToken(node.ifKeyword),
      configuration_leftParenthesis: _getToken(node.leftParenthesis),
      configuration_name: node.name?.accept(this),
      configuration_rightParenthesis: _getToken(node.rightParenthesis),
      configuration_value: node.value?.accept(this),
      configuration_uri: node.uri?.accept(this),
    );
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
    _storeCodeOffsetLength(builder, node);
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
    var elementComponents = _componentsOfElement(node.staticElement);
    return LinkedNodeBuilder.constructorName(
      constructorName_element: elementComponents.rawElement,
      constructorName_elementType: elementComponents.definingType,
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
    var builder = LinkedNodeBuilder.defaultFormalParameter(
      defaultFormalParameter_defaultValue: node.defaultValue?.accept(this),
      defaultFormalParameter_kind: _toParameterKind(node),
      defaultFormalParameter_parameter: node.parameter.accept(this),
      defaultFormalParameter_separator: _getToken(node.separator),
    );
    _storeCodeOffsetLength(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitDoStatement(DoStatement node) {
    return LinkedNodeBuilder.doStatement(
      doStatement_body: node.body.accept(this),
      doStatement_condition: node.condition.accept(this),
      doStatement_doKeyword: _getToken(node.doKeyword),
      doStatement_leftParenthesis: _getToken(node.leftParenthesis),
      doStatement_rightParenthesis: _getToken(node.rightParenthesis),
      doStatement_semicolon: _getToken(node.semicolon),
      doStatement_whileKeyword: _getToken(node.whileKeyword),
    );
  }

  @override
  LinkedNodeBuilder visitDottedName(DottedName node) {
    return LinkedNodeBuilder.dottedName(
      dottedName_components: _writeNodeList(node.components),
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
  LinkedNodeBuilder visitEmptyStatement(EmptyStatement node) {
    return LinkedNodeBuilder.emptyStatement(
      emptyStatement_semicolon: _getToken(node.semicolon),
    );
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
    _variablesDeclaration = LinkedNodeVariablesDeclarationBuilder(
      isCovariant: node.covariantKeyword != null,
      isStatic: node.isStatic,
    );

    var builder = LinkedNodeBuilder.fieldDeclaration(
      fieldDeclaration_covariantKeyword: _getToken(node.covariantKeyword),
      fieldDeclaration_fields: node.fields.accept(this),
      fieldDeclaration_semicolon: _getToken(node.semicolon),
      fieldDeclaration_staticKeyword: _getToken(node.staticKeyword),
    );
    _storeClassMember(builder, node);

    _variablesDeclaration.comment = builder.annotatedNode_comment;
    _variablesDeclaration = null;

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
  LinkedNodeBuilder visitForEachPartsWithDeclaration(
      ForEachPartsWithDeclaration node) {
    var builder = LinkedNodeBuilder.forEachPartsWithDeclaration(
      forEachPartsWithDeclaration_loopVariable: node.loopVariable.accept(this),
    );
    _storeForEachParts(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitForEachPartsWithIdentifier(
      ForEachPartsWithIdentifier node) {
    var builder = LinkedNodeBuilder.forEachPartsWithIdentifier(
      forEachPartsWithIdentifier_identifier: node.identifier.accept(this),
    );
    _storeForEachParts(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitForElement(ForElement node) {
    var builder = LinkedNodeBuilder.forElement(
      forElement_body: node.body.accept(this),
    );
    _storeForMixin(builder, node as ForElementImpl);
    return builder;
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
  LinkedNodeBuilder visitForPartsWithDeclarations(
      ForPartsWithDeclarations node) {
    var builder = LinkedNodeBuilder.forPartsWithDeclarations(
      forPartsWithDeclarations_variables: node.variables.accept(this),
    );
    _storeForParts(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitForPartsWithExpression(ForPartsWithExpression node) {
    var builder = LinkedNodeBuilder.forPartsWithExpression(
      forPartsWithExpression_initialization: node.initialization?.accept(this),
    );
    _storeForParts(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitForStatement(ForStatement node) {
    var builder = LinkedNodeBuilder.forStatement(
      forStatement_body: node.body.accept(this),
    );
    _storeForMixin(builder, node as ForStatementImpl);
    return builder;
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
    _writeActualReturnType(builder, node);
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
      typeAlias_hasSelfReference:
          LazyFunctionTypeAlias.getHasSelfReference(node),
    );
    _storeTypeAlias(builder, node);
    _writeActualReturnType(builder, node);
    _storeIsSimpleBounded(builder, node);
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
    var builder = LinkedNodeBuilder.genericFunctionType(
      genericFunctionType_formalParameters: node.parameters.accept(this),
      genericFunctionType_functionKeyword: _getToken(node.functionKeyword),
      genericFunctionType_question: _getToken(node.question),
      genericFunctionType_returnType: node.returnType?.accept(this),
      genericFunctionType_type: _writeType(node.type),
      genericFunctionType_typeParameters: node.typeParameters?.accept(this),
    );
    _writeActualReturnType(builder, node);

    var id = LazyAst.getGenericFunctionTypeId(node);
    builder.genericFunctionType_id = id;

    return builder;
  }

  @override
  LinkedNodeBuilder visitGenericTypeAlias(GenericTypeAlias node) {
    var builder = LinkedNodeBuilder.genericTypeAlias(
      genericTypeAlias_equals: _getToken(node.equals),
      genericTypeAlias_functionType: node.functionType?.accept(this),
      genericTypeAlias_typeParameters: node.typeParameters?.accept(this),
      typeAlias_hasSelfReference:
          LazyGenericTypeAlias.getHasSelfReference(node),
    );
    _storeTypeAlias(builder, node);
    _storeIsSimpleBounded(builder, node);
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
  LinkedNodeBuilder visitIfElement(IfElement node) {
    var builder = LinkedNodeBuilder.ifElement(
      ifElement_elseElement: node.elseElement?.accept(this),
      ifElement_thenElement: node.thenElement.accept(this),
    );
    _storeIfMixin(builder, node as IfElementImpl);
    return builder;
  }

  @override
  LinkedNodeBuilder visitIfStatement(IfStatement node) {
    var builder = LinkedNodeBuilder.ifStatement(
      ifMixin_condition: node.condition.accept(this),
      ifMixin_elseKeyword: _getToken(node.elseKeyword),
      ifStatement_elseStatement: node.elseStatement?.accept(this),
      ifMixin_ifKeyword: _getToken(node.ifKeyword),
      ifMixin_leftParenthesis: _getToken(node.leftParenthesis),
      ifMixin_rightParenthesis: _getToken(node.rightParenthesis),
      ifStatement_thenStatement: node.thenStatement.accept(this),
    );
    _storeIfMixin(builder, node as IfStatementImpl);
    return builder;
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
    var elementComponents = _componentsOfElement(node.staticElement);
    return LinkedNodeBuilder.indexExpression(
      indexExpression_element: elementComponents.rawElement,
      indexExpression_elementType: elementComponents.definingType,
      indexExpression_index: node.index.accept(this),
      indexExpression_leftBracket: _getToken(node.leftBracket),
      indexExpression_period: _getToken(node.period),
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
      expression_type: _writeType(node.staticType),
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
  LinkedNodeBuilder visitLabeledStatement(LabeledStatement node) {
    return LinkedNodeBuilder.labeledStatement(
      labeledStatement_labels: _writeNodeList(node.labels),
      labeledStatement_statement: node.statement.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitLibraryDirective(LibraryDirective node) {
    var builder = LinkedNodeBuilder.libraryDirective(
      libraryDirective_name: node.name.accept(this),
      directive_semicolon: _getToken(node.semicolon),
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
      listLiteral_elements: _writeNodeList(node.elements),
      listLiteral_leftBracket: _getToken(node.leftBracket),
      listLiteral_rightBracket: _getToken(node.rightBracket),
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
      methodDeclaration_typeParameters: node.typeParameters?.accept(this),
    );
    _storeClassMember(builder, node);
    _storeCodeOffsetLength(builder, node);
    _writeActualReturnType(builder, node);
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
    LazyMixinDeclaration.get(node).put(builder);
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
  LinkedNodeBuilder visitNativeClause(NativeClause node) {
    return LinkedNodeBuilder.nativeClause(
      nativeClause_nativeKeyword: _getToken(node.nativeKeyword),
      nativeClause_name: node.name.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitNativeFunctionBody(NativeFunctionBody node) {
    return LinkedNodeBuilder.nativeFunctionBody(
      nativeFunctionBody_nativeKeyword: _getToken(node.nativeKeyword),
      nativeFunctionBody_semicolon: _getToken(node.semicolon),
      nativeFunctionBody_stringLiteral: node.stringLiteral?.accept(this),
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
    var builder = LinkedNodeBuilder.partDirective(
      directive_semicolon: _getToken(node.semicolon),
    );
    _storeUriBasedDirective(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitPartOfDirective(PartOfDirective node) {
    var builder = LinkedNodeBuilder.partOfDirective(
      partOfDirective_libraryName: node.libraryName?.accept(this),
      partOfDirective_ofKeyword: _getToken(node.ofKeyword),
      directive_semicolon: _getToken(node.semicolon),
      partOfDirective_uri: node.uri?.accept(this),
    );
    _storeDirective(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitPostfixExpression(PostfixExpression node) {
    var elementComponents = _componentsOfElement(node.staticElement);
    return LinkedNodeBuilder.postfixExpression(
      expression_type: _writeType(node.staticType),
      postfixExpression_element: elementComponents.rawElement,
      postfixExpression_elementType: elementComponents.definingType,
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
    var elementComponents = _componentsOfElement(node.staticElement);
    return LinkedNodeBuilder.prefixExpression(
      expression_type: _writeType(node.staticType),
      prefixExpression_element: elementComponents.rawElement,
      prefixExpression_elementType: elementComponents.definingType,
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
    var elementComponents = _componentsOfElement(node.staticElement);
    var builder = LinkedNodeBuilder.redirectingConstructorInvocation(
      redirectingConstructorInvocation_arguments:
          node.argumentList.accept(this),
      redirectingConstructorInvocation_constructorName:
          node.constructorName?.accept(this),
      redirectingConstructorInvocation_element: elementComponents.rawElement,
      redirectingConstructorInvocation_elementType:
          elementComponents.definingType,
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
  LinkedNodeBuilder visitScriptTag(ScriptTag node) {
    return LinkedNodeBuilder.scriptTag(
      scriptTag_scriptTag: _getToken(node.scriptTag),
    );
  }

  @override
  LinkedNodeBuilder visitSetOrMapLiteral(SetOrMapLiteral node) {
    var builder = LinkedNodeBuilder.setOrMapLiteral(
      setOrMapLiteral_elements: _writeNodeList(node.elements),
      setOrMapLiteral_isMap: node.isMap,
      setOrMapLiteral_isSet: node.isSet,
      setOrMapLiteral_leftBracket: _getToken(node.leftBracket),
      setOrMapLiteral_rightBracket: _getToken(node.rightBracket),
    );
    _storeTypedLiteral(builder, node);
    return builder;
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
    builder.topLevelTypeInferenceError = LazyAst.getTypeInferenceError(node);
    _storeNormalFormalParameter(builder, node);
    _storeInheritsCovariant(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitSimpleIdentifier(SimpleIdentifier node) {
    Element element;
    if (!node.inDeclarationContext()) {
      element = node.staticElement;
      if (element is MultiplyDefinedElement) {
        element = null;
      }
    }

    var elementComponents = _componentsOfElement(element);
    return LinkedNodeBuilder.simpleIdentifier(
      simpleIdentifier_element: elementComponents.rawElement,
      simpleIdentifier_elementType: elementComponents.definingType,
      simpleIdentifier_isDeclaration: node is DeclaredSimpleIdentifier,
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
  LinkedNodeBuilder visitSpreadElement(SpreadElement node) {
    return LinkedNodeBuilder.spreadElement(
      spreadElement_expression: node.expression.accept(this),
      spreadElement_spreadOperator: _getToken(node.spreadOperator),
    );
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
    var elementComponents = _componentsOfElement(node.staticElement);
    var builder = LinkedNodeBuilder.superConstructorInvocation(
      superConstructorInvocation_arguments: node.argumentList.accept(this),
      superConstructorInvocation_constructorName:
          node.constructorName?.accept(this),
      superConstructorInvocation_element: elementComponents.rawElement,
      superConstructorInvocation_elementType: elementComponents.definingType,
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
    _variablesDeclaration = LinkedNodeVariablesDeclarationBuilder();

    var builder = LinkedNodeBuilder.topLevelVariableDeclaration(
      topLevelVariableDeclaration_semicolon: _getToken(node.semicolon),
      topLevelVariableDeclaration_variableList: node.variables?.accept(this),
    );
    _storeCompilationUnitMember(builder, node);

    _variablesDeclaration.comment = builder.annotatedNode_comment;
    _variablesDeclaration = null;

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
      typeParameter_defaultType: _writeType(LazyAst.getDefaultType(node)),
      typeParameter_extendsKeyword: _getToken(node.extendsKeyword),
      typeParameter_name: node.name.accept(this),
    );
    _storeDeclaration(builder, node);
    _storeCodeOffsetLength(builder, node);
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
    var builder = LinkedNodeBuilder.variableDeclaration(
      variableDeclaration_equals: _getToken(node.equals),
      variableDeclaration_initializer: node.initializer?.accept(this),
      variableDeclaration_name: node.name.accept(this),
      variableDeclaration_declaration: _variablesDeclaration,
    );
    builder.topLevelTypeInferenceError = LazyAst.getTypeInferenceError(node);
    _writeActualType(builder, node);
    _storeInheritsCovariant(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitVariableDeclarationList(VariableDeclarationList node) {
    if (_variablesDeclaration != null) {
      _variablesDeclaration.isConst = node.isConst;
      _variablesDeclaration.isFinal = node.isFinal;
    }

    var builder = LinkedNodeBuilder.variableDeclarationList(
      variableDeclarationList_keyword: _getToken(node.keyword),
      variableDeclarationList_lateKeyword: _getToken(node.lateKeyword),
      variableDeclarationList_type: node.type?.accept(this),
      variableDeclarationList_variables: _writeNodeList(node.variables),
    );
    _storeAnnotatedNode(builder, node);
    _storeCodeOffsetLengthVariables(builder, node);
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
    _tokensWriter.writeTokens(node.beginToken, node.endToken);
    return node.accept(this);
  }

  _ElementComponents _componentsOfElement(Element element) {
    while (element is ParameterMember) {
      element = (element as ParameterMember).baseElement;
    }

    if (element is Member) {
      var elementIndex = _indexOfElement(element.baseElement);
      var definingTypeNode = _writeType(element.definingType);
      return _ElementComponents(elementIndex, definingTypeNode);
    }

    var elementIndex = _indexOfElement(element);
    return _ElementComponents(elementIndex, null);
  }

  int _getToken(Token token) {
    return _tokensWriter.indexOfToken(token);
  }

  List<int> _getTokens(List<Token> tokenList) {
    var result = List<int>(tokenList.length);
    for (var i = 0; i < tokenList.length; ++i) {
      var token = tokenList[i];
      result[i] = _getToken(token);
    }
    return result;
  }

  int _indexOfElement(Element element) {
    return _linkingContext.indexOfElement(element);
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
    _storeIsSimpleBounded(builder, node);
  }

  void _storeCodeOffsetLength(LinkedNodeBuilder builder, AstNode node) {
    builder.codeOffset = node.offset;
    builder.codeLength = node.length;
  }

  void _storeCodeOffsetLengthVariables(
      LinkedNodeBuilder builder, VariableDeclarationList node) {
    var builders = builder.variableDeclarationList_variables;
    for (var i = 0; i < builders.length; ++i) {
      var variableBuilder = builders[i];
      var variableNode = node.variables[i];
      var offset = (i == 0 ? node.parent : variableNode).offset;
      variableBuilder.codeOffset = offset;
      variableBuilder.codeLength = variableNode.end - offset;
    }
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

  void _storeForEachParts(LinkedNodeBuilder builder, ForEachParts node) {
    _storeForLoopParts(builder, node);
    builder
      ..forEachParts_inKeyword = _getToken(node.inKeyword)
      ..forEachParts_iterable = node.iterable?.accept(this);
  }

  void _storeForLoopParts(LinkedNodeBuilder builder, ForLoopParts node) {}

  void _storeFormalParameter(LinkedNodeBuilder builder, FormalParameter node) {
    _storeCodeOffsetLength(builder, node);
    _writeActualType(builder, node);
  }

  void _storeForMixin(LinkedNodeBuilder builder, ForMixin node) {
    builder
      ..forMixin_awaitKeyword = _getToken(node.awaitKeyword)
      ..forMixin_forKeyword = _getToken(node.forKeyword)
      ..forMixin_forLoopParts = node.forLoopParts.accept(this)
      ..forMixin_leftParenthesis = _getToken(node.leftParenthesis)
      ..forMixin_rightParenthesis = _getToken(node.rightParenthesis);
  }

  void _storeForParts(LinkedNodeBuilder builder, ForParts node) {
    _storeForLoopParts(builder, node);
    builder
      ..forParts_leftSeparator = _getToken(node.leftSeparator)
      ..forParts_condition = node.condition?.accept(this)
      ..forParts_rightSeparator = _getToken(node.rightSeparator)
      ..forParts_updaters = _writeNodeList(node.updaters);
  }

  void _storeFunctionBody(LinkedNodeBuilder builder, FunctionBody node) {}

  void _storeIfMixin(LinkedNodeBuilder builder, IfMixin node) {
    builder
      ..ifMixin_condition = node.condition.accept(this)
      ..ifMixin_elseKeyword = _getToken(node.elseKeyword)
      ..ifMixin_ifKeyword = _getToken(node.ifKeyword)
      ..ifMixin_leftParenthesis = _getToken(node.leftParenthesis)
      ..ifMixin_rightParenthesis = _getToken(node.rightParenthesis);
  }

  void _storeInheritsCovariant(LinkedNodeBuilder builder, AstNode node) {
    var value = LazyAst.getInheritsCovariant(node);
    builder.inheritsCovariant = value;
  }

  void _storeInvocationExpression(
      LinkedNodeBuilder builder, InvocationExpression node) {
    _storeExpression(builder, node);
    builder
      ..invocationExpression_arguments = node.argumentList.accept(this)
      ..invocationExpression_invokeType = _writeType(node.staticInvokeType)
      ..invocationExpression_typeArguments = node.typeArguments?.accept(this);
  }

  void _storeIsSimpleBounded(LinkedNodeBuilder builder, AstNode node) {
    var flag = LazyAst.isSimplyBounded(node);
    // TODO(scheglov) Check for `null` when writing resolved AST.
    builder.simplyBoundable_isSimplyBounded = flag;
  }

  void _storeNamedCompilationUnitMember(
      LinkedNodeBuilder builder, NamedCompilationUnitMember node) {
    _storeCompilationUnitMember(builder, node);
    _storeCodeOffsetLength(builder, node);
    builder..namedCompilationUnitMember_name = node.name.accept(this);
  }

  void _storeNamespaceDirective(
      LinkedNodeBuilder builder, NamespaceDirective node) {
    _storeUriBasedDirective(builder, node);
    builder
      ..namespaceDirective_combinators = _writeNodeList(node.combinators)
      ..namespaceDirective_configurations = _writeNodeList(node.configurations)
      ..namespaceDirective_selectedUri = LazyDirective.getSelectedUri(node)
      ..directive_semicolon = _getToken(node.semicolon);
  }

  void _storeNormalFormalParameter(
      LinkedNodeBuilder builder, NormalFormalParameter node) {
    _storeFormalParameter(builder, node);
    builder
      ..normalFormalParameter_comment = node.documentationComment?.accept(this)
      ..normalFormalParameter_covariantKeyword =
          _getToken(node.covariantKeyword)
      ..normalFormalParameter_identifier = node.identifier?.accept(this)
      ..normalFormalParameter_metadata = _writeNodeList(node.metadata)
      ..normalFormalParameter_requiredKeyword = _getToken(node.requiredKeyword);
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
      ..uriBasedDirective_uriElement = _indexOfElement(node.uriElement);
  }

  void _writeActualReturnType(LinkedNodeBuilder builder, AstNode node) {
    var type = LazyAst.getReturnType(node);
    // TODO(scheglov) Check for `null` when writing resolved AST.
    builder.actualReturnType = _writeType(type);
  }

  void _writeActualType(LinkedNodeBuilder builder, AstNode node) {
    var type = LazyAst.getType(node);
    // TODO(scheglov) Check for `null` when writing resolved AST.
    builder.actualType = _writeType(type);
  }

  List<LinkedNodeBuilder> _writeNodeList(List<AstNode> nodeList) {
    var result = List<LinkedNodeBuilder>.filled(
      nodeList.length,
      null,
      growable: true,
    );
    for (var i = 0; i < nodeList.length; ++i) {
      result[i] = nodeList[i].accept(this);
    }
    return result;
  }

  LinkedNodeTypeBuilder _writeType(DartType type) {
    return _linkingContext.writeType(type);
  }

  static LinkedNodeFormalParameterKind _toParameterKind(FormalParameter node) {
    if (node.isRequiredPositional) {
      return LinkedNodeFormalParameterKind.requiredPositional;
    } else if (node.isRequiredNamed) {
      return LinkedNodeFormalParameterKind.requiredNamed;
    } else if (node.isOptionalPositional) {
      return LinkedNodeFormalParameterKind.optionalPositional;
    } else if (node.isOptionalNamed) {
      return LinkedNodeFormalParameterKind.optionalNamed;
    } else {
      throw new StateError('Unknown kind of parameter');
    }
  }
}

/// Components of a [Member] - the raw element, and the defining type.
class _ElementComponents {
  final int rawElement;
  final LinkedNodeType definingType;

  _ElementComponents(this.rawElement, this.definingType);
}
