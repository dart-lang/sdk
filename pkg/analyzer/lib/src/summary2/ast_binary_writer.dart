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
import 'package:analyzer/src/summary2/ast_binary_flags.dart';
import 'package:analyzer/src/summary2/informative_data.dart';
import 'package:analyzer/src/summary2/lazy_ast.dart';
import 'package:analyzer/src/summary2/linking_bundle_context.dart';
import 'package:analyzer/src/summary2/tokens_writer.dart';

var timerAstBinaryWriter = Stopwatch();
var timerAstBinaryWriterClass = Stopwatch();
var timerAstBinaryWriterDirective = Stopwatch();
var timerAstBinaryWriterFunctionBody = Stopwatch();
var timerAstBinaryWriterMixin = Stopwatch();
var timerAstBinaryWriterTopVar = Stopwatch();
var timerAstBinaryWriterTypedef = Stopwatch();

/// Serializer of fully resolved ASTs into flat buffers.
class AstBinaryWriter extends ThrowingAstVisitor<LinkedNodeBuilder> {
  final LinkingBundleContext _linkingContext;

  /// Is `true` if the current [ClassDeclaration] has a const constructor,
  /// so initializers of final fields should be written.
  bool _hasConstConstructor = false;

  AstBinaryWriter(this._linkingContext);

  @override
  LinkedNodeBuilder visitAdjacentStrings(AdjacentStrings node) {
    return LinkedNodeBuilder.adjacentStrings(
      adjacentStrings_strings: _writeNodeList(node.strings),
    );
  }

  @override
  LinkedNodeBuilder visitAnnotation(Annotation node) {
    var elementComponents = _componentsOfElement(node.element);

    LinkedNodeBuilder storedArguments;
    var arguments = node.arguments;
    if (arguments != null) {
      if (arguments.arguments.every(_isSerializableExpression)) {
        storedArguments = arguments.accept(this);
      } else {
        storedArguments = LinkedNodeBuilder.argumentList();
      }
    }

    return LinkedNodeBuilder.annotation(
      annotation_arguments: storedArguments,
      annotation_constructorName: node.constructorName?.accept(this),
      annotation_element: elementComponents.rawElement,
      annotation_substitution: elementComponents.substitution,
      annotation_name: node.name?.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitArgumentList(ArgumentList node) {
    return LinkedNodeBuilder.argumentList(
      argumentList_arguments: _writeNodeList(node.arguments),
    );
  }

  @override
  LinkedNodeBuilder visitAsExpression(AsExpression node) {
    return LinkedNodeBuilder.asExpression(
      asExpression_expression: node.expression.accept(this),
      asExpression_type: node.type.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitAssertInitializer(AssertInitializer node) {
    return LinkedNodeBuilder.assertInitializer(
      assertInitializer_condition: node.condition.accept(this),
      assertInitializer_message: node.message?.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitAssertStatement(AssertStatement node) {
    var builder = LinkedNodeBuilder.assertStatement(
      assertStatement_condition: node.condition.accept(this),
      assertStatement_message: node.message?.accept(this),
    );
    _storeStatement(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitAssignmentExpression(AssignmentExpression node) {
    var elementComponents = _componentsOfElement(node.staticElement);
    return LinkedNodeBuilder.assignmentExpression(
      assignmentExpression_element: elementComponents.rawElement,
      assignmentExpression_substitution: elementComponents.substitution,
      assignmentExpression_leftHandSide: node.leftHandSide.accept(this),
      assignmentExpression_operator: TokensWriter.astToBinaryTokenType(
        node.operator.type,
      ),
      assignmentExpression_rightHandSide: node.rightHandSide.accept(this),
      expression_type: _writeType(node.staticType),
    );
  }

  @override
  LinkedNodeBuilder visitAwaitExpression(AwaitExpression node) {
    return LinkedNodeBuilder.awaitExpression(
      awaitExpression_expression: node.expression.accept(this),
      expression_type: _writeType(node.staticType),
    );
  }

  @override
  LinkedNodeBuilder visitBinaryExpression(BinaryExpression node) {
    var elementComponents = _componentsOfElement(node.staticElement);
    return LinkedNodeBuilder.binaryExpression(
      binaryExpression_element: elementComponents.rawElement,
      binaryExpression_substitution: elementComponents.substitution,
      binaryExpression_leftOperand: node.leftOperand.accept(this),
      binaryExpression_operator: TokensWriter.astToBinaryTokenType(
        node.operator.type,
      ),
      binaryExpression_rightOperand: node.rightOperand.accept(this),
      expression_type: _writeType(node.staticType),
    );
  }

  @override
  LinkedNodeBuilder visitBlock(Block node) {
    return LinkedNodeBuilder.block(
      block_statements: _writeNodeList(node.statements),
    );
  }

  @override
  LinkedNodeBuilder visitBlockFunctionBody(BlockFunctionBody node) {
    timerAstBinaryWriterFunctionBody.start();
    try {
      var builder = LinkedNodeBuilder.blockFunctionBody(
        blockFunctionBody_block: node.block.accept(this),
      );
      builder.flags = AstBinaryFlags.encode(
        isAsync: node.keyword?.keyword == Keyword.ASYNC,
        isStar: node.star != null,
        isSync: node.keyword?.keyword == Keyword.SYNC,
      );
      return builder;
    } finally {
      timerAstBinaryWriterFunctionBody.stop();
    }
  }

  @override
  LinkedNodeBuilder visitBooleanLiteral(BooleanLiteral node) {
    return LinkedNodeBuilder.booleanLiteral(
      booleanLiteral_value: node.value,
    );
  }

  @override
  LinkedNodeBuilder visitBreakStatement(BreakStatement node) {
    var builder = LinkedNodeBuilder.breakStatement(
      breakStatement_label: node.label?.accept(this),
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
      catchClause_exceptionParameter: node.exceptionParameter?.accept(this),
      catchClause_exceptionType: node.exceptionType?.accept(this),
      catchClause_stackTraceParameter: node.stackTraceParameter?.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitClassDeclaration(ClassDeclaration node) {
    try {
      timerAstBinaryWriterClass.start();

      _hasConstConstructor = false;
      for (var member in node.members) {
        if (member is ConstructorDeclaration && member.constKeyword != null) {
          _hasConstConstructor = true;
          break;
        }
      }

      var builder = LinkedNodeBuilder.classDeclaration(
        classDeclaration_extendsClause: node.extendsClause?.accept(this),
        classDeclaration_nativeClause: node.nativeClause?.accept(this),
        classDeclaration_withClause: node.withClause?.accept(this),
      );
      builder.flags = AstBinaryFlags.encode(
        isAbstract: node.abstractKeyword != null,
      );
      _storeClassOrMixinDeclaration(builder, node);
      return builder;
    } finally {
      timerAstBinaryWriterClass.stop();
    }
  }

  @override
  LinkedNodeBuilder visitClassTypeAlias(ClassTypeAlias node) {
    timerAstBinaryWriterClass.start();
    try {
      var builder = LinkedNodeBuilder.classTypeAlias(
        classTypeAlias_implementsClause: node.implementsClause?.accept(this),
        classTypeAlias_superclass: node.superclass.accept(this),
        classTypeAlias_typeParameters: node.typeParameters?.accept(this),
        classTypeAlias_withClause: node.withClause.accept(this),
      );
      builder.flags = AstBinaryFlags.encode(
        isAbstract: node.abstractKeyword != null,
      );
      _storeTypeAlias(builder, node);
      _storeIsSimpleBounded(builder, node);
      return builder;
    } finally {
      timerAstBinaryWriterClass.stop();
    }
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
      comment_tokens: node.tokens.map((t) => t.lexeme).toList(),
      comment_type: type,
      // TODO(scheglov) restore
//      comment_references: _writeNodeList(node.references),
    );
  }

  @override
  LinkedNodeBuilder visitCommentReference(CommentReference node) {
//    var identifier = node.identifier;
//    _tokensWriter.writeTokens(
//      node.newKeyword ?? identifier.beginToken,
//      identifier.endToken,
//    );
//
//    return LinkedNodeBuilder.commentReference(
//      commentReference_identifier: identifier.accept(this),
//      commentReference_newKeyword: _getToken(node.newKeyword),
//    );
    return null;
  }

  @override
  LinkedNodeBuilder visitCompilationUnit(CompilationUnit node) {
    var nodeImpl = node as CompilationUnitImpl;
    var builder = LinkedNodeBuilder.compilationUnit(
      compilationUnit_declarations: _writeNodeList(node.declarations),
      compilationUnit_directives: _writeNodeList(node.directives),
      compilationUnit_languageVersion: LinkedLibraryLanguageVersionBuilder(
        package: LinkedLanguageVersionBuilder(
          major: nodeImpl.languageVersion.package.major,
          minor: nodeImpl.languageVersion.package.minor,
        ),
        override2: nodeImpl.languageVersion.override != null
            ? LinkedLanguageVersionBuilder(
                major: nodeImpl.languageVersion.override.major,
                minor: nodeImpl.languageVersion.override.minor,
              )
            : null,
      ),
      compilationUnit_scriptTag: node.scriptTag?.accept(this),
      informativeId: getInformativeId(node),
    );
    return builder;
  }

  @override
  LinkedNodeBuilder visitConditionalExpression(ConditionalExpression node) {
    var builder = LinkedNodeBuilder.conditionalExpression(
      conditionalExpression_condition: node.condition.accept(this),
      conditionalExpression_elseExpression: node.elseExpression.accept(this),
      conditionalExpression_thenExpression: node.thenExpression.accept(this),
    );
    _storeExpression(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitConfiguration(Configuration node) {
    var builder = LinkedNodeBuilder.configuration(
      configuration_name: node.name?.accept(this),
      configuration_value: node.value?.accept(this),
      configuration_uri: node.uri?.accept(this),
    );
    builder.flags = AstBinaryFlags.encode(
      hasEqual: node.equalToken != null,
    );
    return builder;
  }

  @override
  LinkedNodeBuilder visitConstructorDeclaration(ConstructorDeclaration node) {
    var builder = LinkedNodeBuilder.constructorDeclaration(
      constructorDeclaration_initializers: _writeNodeList(node.initializers),
      constructorDeclaration_parameters: node.parameters.accept(this),
      constructorDeclaration_redirectedConstructor:
          node.redirectedConstructor?.accept(this),
      constructorDeclaration_returnType: node.returnType.accept(this),
      informativeId: getInformativeId(node),
    );
    builder.flags = AstBinaryFlags.encode(
      hasName: node.name != null,
      hasSeparatorColon: node.separator?.type == TokenType.COLON,
      hasSeparatorEquals: node.separator?.type == TokenType.EQ,
      isAbstract: node.body is EmptyFunctionBody,
      isConst: node.constKeyword != null,
      isExternal: node.externalKeyword != null,
      isFactory: node.factoryKeyword != null,
    );
    builder.name = node.name?.name;
    _storeClassMember(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitConstructorFieldInitializer(
      ConstructorFieldInitializer node) {
    var builder = LinkedNodeBuilder.constructorFieldInitializer(
      constructorFieldInitializer_expression: node.expression.accept(this),
      constructorFieldInitializer_fieldName: node.fieldName.accept(this),
    );
    builder.flags = AstBinaryFlags.encode(
      hasThis: node.thisKeyword != null,
    );
    _storeConstructorInitializer(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitConstructorName(ConstructorName node) {
    var elementComponents = _componentsOfElement(node.staticElement);
    return LinkedNodeBuilder.constructorName(
      constructorName_element: elementComponents.rawElement,
      constructorName_substitution: elementComponents.substitution,
      constructorName_name: node.name?.accept(this),
      constructorName_type: node.type.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitContinueStatement(ContinueStatement node) {
    var builder = LinkedNodeBuilder.continueStatement(
      continueStatement_label: node.label?.accept(this),
    );
    _storeStatement(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitDeclaredIdentifier(DeclaredIdentifier node) {
    var builder = LinkedNodeBuilder.declaredIdentifier(
      declaredIdentifier_identifier: node.identifier.accept(this),
      declaredIdentifier_type: node.type?.accept(this),
    );
    builder.flags = AstBinaryFlags.encode(
      isConst: node.keyword?.keyword == Keyword.CONST,
      isFinal: node.keyword?.keyword == Keyword.FINAL,
      isVar: node.keyword?.keyword == Keyword.VAR,
    );
    _storeDeclaration(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitDefaultFormalParameter(DefaultFormalParameter node) {
    var defaultValue = node.defaultValue;
    if (!_isSerializableExpression(defaultValue)) {
      defaultValue = null;
    }

    var builder = LinkedNodeBuilder.defaultFormalParameter(
      defaultFormalParameter_defaultValue: defaultValue?.accept(this),
      defaultFormalParameter_kind: _toParameterKind(node),
      defaultFormalParameter_parameter: node.parameter.accept(this),
      informativeId: getInformativeId(node),
    );
    builder.flags = AstBinaryFlags.encode(
      hasInitializer: node.defaultValue != null,
    );
    return builder;
  }

  @override
  LinkedNodeBuilder visitDoStatement(DoStatement node) {
    return LinkedNodeBuilder.doStatement(
      doStatement_body: node.body.accept(this),
      doStatement_condition: node.condition.accept(this),
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
      doubleLiteral_value: node.value,
    );
  }

  @override
  LinkedNodeBuilder visitEmptyFunctionBody(EmptyFunctionBody node) {
    var builder = LinkedNodeBuilder.emptyFunctionBody();
    _storeFunctionBody(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitEmptyStatement(EmptyStatement node) {
    return LinkedNodeBuilder.emptyStatement();
  }

  @override
  LinkedNodeBuilder visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    var builder = LinkedNodeBuilder.enumConstantDeclaration(
      informativeId: getInformativeId(node),
    );
    builder..name = node.name.name;
    _storeDeclaration(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitEnumDeclaration(EnumDeclaration node) {
    var builder = LinkedNodeBuilder.enumDeclaration(
      enumDeclaration_constants: _writeNodeList(node.constants),
    );
    _storeNamedCompilationUnitMember(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitExportDirective(ExportDirective node) {
    timerAstBinaryWriterDirective.start();
    try {
      var builder = LinkedNodeBuilder.exportDirective();
      _storeNamespaceDirective(builder, node);
      return builder;
    } finally {
      timerAstBinaryWriterDirective.stop();
    }
  }

  @override
  LinkedNodeBuilder visitExpressionFunctionBody(ExpressionFunctionBody node) {
    timerAstBinaryWriterFunctionBody.start();
    try {
      var builder = LinkedNodeBuilder.expressionFunctionBody(
        expressionFunctionBody_expression: node.expression.accept(this),
      );
      builder.flags = AstBinaryFlags.encode(
        isAsync: node.keyword?.keyword == Keyword.ASYNC,
        isSync: node.keyword?.keyword == Keyword.SYNC,
      );
      return builder;
    } finally {
      timerAstBinaryWriterFunctionBody.stop();
    }
  }

  @override
  LinkedNodeBuilder visitExpressionStatement(ExpressionStatement node) {
    return LinkedNodeBuilder.expressionStatement(
      expressionStatement_expression: node.expression.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitExtendsClause(ExtendsClause node) {
    return LinkedNodeBuilder.extendsClause(
      extendsClause_superclass: node.superclass.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitExtensionDeclaration(ExtensionDeclaration node) {
    var builder = LinkedNodeBuilder.extensionDeclaration(
      extensionDeclaration_extendedType: node.extendedType.accept(this),
      extensionDeclaration_members: _writeNodeList(node.members),
      extensionDeclaration_typeParameters: node.typeParameters?.accept(this),
    );

    _storeCompilationUnitMember(builder, node);
    _storeInformativeId(builder, node);
    builder.name = node.name?.name;
    LazyExtensionDeclaration.get(node).put(builder);

    return builder;
  }

  @override
  LinkedNodeBuilder visitExtensionOverride(ExtensionOverride node) {
    var builder = LinkedNodeBuilder.extensionOverride(
      extensionOverride_arguments: _writeNodeList(
        node.argumentList.arguments,
      ),
      extensionOverride_extensionName: node.extensionName.accept(this),
      extensionOverride_typeArguments: node.typeArguments?.accept(this),
      extensionOverride_typeArgumentTypes:
          node.typeArgumentTypes.map(_writeType).toList(),
      extensionOverride_extendedType: _writeType(node.extendedType),
    );
    return builder;
  }

  @override
  LinkedNodeBuilder visitFieldDeclaration(FieldDeclaration node) {
    var builder = LinkedNodeBuilder.fieldDeclaration(
      fieldDeclaration_fields: node.fields.accept(this),
      informativeId: getInformativeId(node),
    );
    builder.flags = AstBinaryFlags.encode(
      isCovariant: node.covariantKeyword != null,
      isStatic: node.staticKeyword != null,
    );
    _storeClassMember(builder, node);

    return builder;
  }

  @override
  LinkedNodeBuilder visitFieldFormalParameter(FieldFormalParameter node) {
    var builder = LinkedNodeBuilder.fieldFormalParameter(
      fieldFormalParameter_formalParameters: node.parameters?.accept(this),
      fieldFormalParameter_type: node.type?.accept(this),
      fieldFormalParameter_typeParameters: node.typeParameters?.accept(this),
    );
    _storeNormalFormalParameter(builder, node, node.keyword);
    builder.flags |= AstBinaryFlags.encode(hasQuestion: node.question != null);
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
    var builder = LinkedNodeBuilder.formalParameterList(
      formalParameterList_parameters: _writeNodeList(node.parameters),
    );
    builder.flags = AstBinaryFlags.encode(
      isDelimiterCurly:
          node.leftDelimiter?.type == TokenType.OPEN_CURLY_BRACKET,
      isDelimiterSquare:
          node.leftDelimiter?.type == TokenType.OPEN_SQUARE_BRACKET,
    );
    return builder;
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
      functionDeclaration_returnType: node.returnType?.accept(this),
      functionDeclaration_functionExpression:
          node.functionExpression?.accept(this),
    );
    builder.flags = AstBinaryFlags.encode(
      isExternal: node.externalKeyword != null,
      isGet: node.isGetter,
      isSet: node.isSetter,
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
    var bodyToStore = node.body;
    if (node.parent.parent is CompilationUnit) {
      bodyToStore = null;
    }
    var builder = LinkedNodeBuilder.functionExpression(
      functionExpression_typeParameters: node.typeParameters?.accept(this),
      functionExpression_formalParameters: node.parameters?.accept(this),
      functionExpression_body: bodyToStore?.accept(this),
    );
    builder.flags = AstBinaryFlags.encode(
      isAsync: node.body?.isAsynchronous ?? false,
      isGenerator: node.body?.isGenerator ?? false,
    );
    return builder;
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
    timerAstBinaryWriterTypedef.start();
    try {
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
    } finally {
      timerAstBinaryWriterTypedef.stop();
    }
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
    _storeNormalFormalParameter(builder, node, null);
    return builder;
  }

  @override
  LinkedNodeBuilder visitGenericFunctionType(GenericFunctionType node) {
    var id = LazyAst.getGenericFunctionTypeId(node);
    assert(id != null);

    var builder = LinkedNodeBuilder.genericFunctionType(
      genericFunctionType_id: id,
      genericFunctionType_returnType: node.returnType?.accept(this),
      genericFunctionType_typeParameters: node.typeParameters?.accept(this),
      genericFunctionType_formalParameters: node.parameters.accept(this),
      genericFunctionType_type: _writeType(node.type),
    );
    builder.flags = AstBinaryFlags.encode(
      hasQuestion: node.question != null,
    );
    _writeActualReturnType(builder, node);

    return builder;
  }

  @override
  LinkedNodeBuilder visitGenericTypeAlias(GenericTypeAlias node) {
    timerAstBinaryWriterTypedef.start();
    try {
      var builder = LinkedNodeBuilder.genericTypeAlias(
        genericTypeAlias_typeParameters: node.typeParameters?.accept(this),
        genericTypeAlias_functionType: node.functionType?.accept(this),
        typeAlias_hasSelfReference:
            LazyGenericTypeAlias.getHasSelfReference(node),
      );
      _storeTypeAlias(builder, node);
      _storeIsSimpleBounded(builder, node);
      return builder;
    } finally {
      timerAstBinaryWriterTypedef.stop();
    }
  }

  @override
  LinkedNodeBuilder visitHideCombinator(HideCombinator node) {
    var builder = LinkedNodeBuilder.hideCombinator(
      names: node.hiddenNames.map((id) => id.name).toList(),
    );
    _storeInformativeId(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitIfElement(IfElement node) {
    var builder = LinkedNodeBuilder.ifElement(
      ifMixin_condition: node.condition.accept(this),
      ifElement_elseElement: node.elseElement?.accept(this),
      ifElement_thenElement: node.thenElement.accept(this),
    );
    return builder;
  }

  @override
  LinkedNodeBuilder visitIfStatement(IfStatement node) {
    var builder = LinkedNodeBuilder.ifStatement(
      ifMixin_condition: node.condition.accept(this),
      ifStatement_elseStatement: node.elseStatement?.accept(this),
      ifStatement_thenStatement: node.thenStatement.accept(this),
    );
    return builder;
  }

  @override
  LinkedNodeBuilder visitImplementsClause(ImplementsClause node) {
    return LinkedNodeBuilder.implementsClause(
      implementsClause_interfaces: _writeNodeList(node.interfaces),
    );
  }

  @override
  LinkedNodeBuilder visitImportDirective(ImportDirective node) {
    timerAstBinaryWriterDirective.start();
    try {
      var builder = LinkedNodeBuilder.importDirective(
        importDirective_prefix: node.prefix?.name,
      );
      builder.flags = AstBinaryFlags.encode(
        isDeferred: node.deferredKeyword != null,
      );
      _storeNamespaceDirective(builder, node);
      return builder;
    } finally {
      timerAstBinaryWriterDirective.stop();
    }
  }

  @override
  LinkedNodeBuilder visitIndexExpression(IndexExpression node) {
    var elementComponents = _componentsOfElement(node.staticElement);
    var builder = LinkedNodeBuilder.indexExpression(
      indexExpression_element: elementComponents.rawElement,
      indexExpression_substitution: elementComponents.substitution,
      indexExpression_index: node.index.accept(this),
      indexExpression_target: node.target?.accept(this),
      expression_type: _writeType(node.staticType),
    );
    builder.flags = AstBinaryFlags.encode(
      hasPeriod: node.period != null,
      hasQuestion: node.question != null,
    );
    return builder;
  }

  @override
  LinkedNodeBuilder visitInstanceCreationExpression(
      InstanceCreationExpression node) {
    InstanceCreationExpressionImpl nodeImpl = node;
    var builder = LinkedNodeBuilder.instanceCreationExpression(
      instanceCreationExpression_arguments: _writeNodeList(
        node.argumentList.arguments,
      ),
      instanceCreationExpression_constructorName:
          node.constructorName.accept(this),
      instanceCreationExpression_typeArguments:
          nodeImpl.typeArguments?.accept(this),
      expression_type: _writeType(node.staticType),
    );
    builder.flags = AstBinaryFlags.encode(
      isConst: node.keyword?.type == Keyword.CONST,
      isNew: node.keyword?.type == Keyword.NEW,
    );
    return builder;
  }

  @override
  LinkedNodeBuilder visitIntegerLiteral(IntegerLiteral node) {
    return LinkedNodeBuilder.integerLiteral(
      expression_type: _writeType(node.staticType),
      integerLiteral_value: node.value,
    );
  }

  @override
  LinkedNodeBuilder visitInterpolationExpression(InterpolationExpression node) {
    return LinkedNodeBuilder.interpolationExpression(
      interpolationExpression_expression: node.expression.accept(this),
    )..flags = AstBinaryFlags.encode(
        isStringInterpolationIdentifier:
            node.leftBracket.type == TokenType.STRING_INTERPOLATION_IDENTIFIER,
      );
  }

  @override
  LinkedNodeBuilder visitInterpolationString(InterpolationString node) {
    return LinkedNodeBuilder.interpolationString(
      interpolationString_value: node.value,
    );
  }

  @override
  LinkedNodeBuilder visitIsExpression(IsExpression node) {
    var builder = LinkedNodeBuilder.isExpression(
      isExpression_expression: node.expression.accept(this),
      isExpression_type: node.type.accept(this),
    );
    builder.flags = AstBinaryFlags.encode(
      hasNot: node.notOperator != null,
    );
    return builder;
  }

  @override
  LinkedNodeBuilder visitLabel(Label node) {
    return LinkedNodeBuilder.label(
      label_label: node.label.accept(this),
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
    timerAstBinaryWriterDirective.start();
    try {
      var builder = LinkedNodeBuilder.libraryDirective(
        informativeId: getInformativeId(node),
        libraryDirective_name: node.name.accept(this),
      );
      _storeDirective(builder, node);
      return builder;
    } finally {
      timerAstBinaryWriterDirective.stop();
    }
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
    );
    _storeTypedLiteral(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitMapLiteralEntry(MapLiteralEntry node) {
    return LinkedNodeBuilder.mapLiteralEntry(
      mapLiteralEntry_key: node.key.accept(this),
      mapLiteralEntry_value: node.value.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitMethodDeclaration(MethodDeclaration node) {
    var builder = LinkedNodeBuilder.methodDeclaration(
      methodDeclaration_returnType: node.returnType?.accept(this),
      methodDeclaration_typeParameters: node.typeParameters?.accept(this),
      methodDeclaration_formalParameters: node.parameters?.accept(this),
      methodDeclaration_hasOperatorEqualWithParameterTypeFromObject:
          LazyAst.hasOperatorEqualParameterTypeFromObject(node),
    );
    builder.name = node.name.name;
    builder.flags = AstBinaryFlags.encode(
      isAbstract: node.body is EmptyFunctionBody,
      isAsync: node.body?.isAsynchronous ?? false,
      isExternal: node.externalKeyword != null,
      isGenerator: node.body?.isGenerator ?? false,
      isGet: node.isGetter,
      isNative: node.body is NativeFunctionBody,
      isOperator: node.operatorKeyword != null,
      isSet: node.isSetter,
      isStatic: node.isStatic,
    );
    builder.topLevelTypeInferenceError = LazyAst.getTypeInferenceError(node);
    _storeClassMember(builder, node);
    _storeInformativeId(builder, node);
    _writeActualReturnType(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitMethodInvocation(MethodInvocation node) {
    var builder = LinkedNodeBuilder.methodInvocation(
      methodInvocation_methodName: node.methodName?.accept(this),
      methodInvocation_target: node.target?.accept(this),
    );
    builder.flags = AstBinaryFlags.encode(
      hasPeriod: node.operator?.type == TokenType.PERIOD,
      hasPeriod2: node.operator?.type == TokenType.PERIOD_PERIOD,
    );
    _storeInvocationExpression(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitMixinDeclaration(MixinDeclaration node) {
    timerAstBinaryWriterMixin.start();
    try {
      var builder = LinkedNodeBuilder.mixinDeclaration(
        mixinDeclaration_onClause: node.onClause?.accept(this),
      );
      _storeClassOrMixinDeclaration(builder, node);
      LazyMixinDeclaration.get(node).put(builder);
      return builder;
    } finally {
      timerAstBinaryWriterMixin.stop();
    }
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
      nativeClause_name: node.name.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitNativeFunctionBody(NativeFunctionBody node) {
    return LinkedNodeBuilder.nativeFunctionBody(
      nativeFunctionBody_stringLiteral: node.stringLiteral?.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitNullLiteral(NullLiteral node) {
    return LinkedNodeBuilder.nullLiteral();
  }

  @override
  LinkedNodeBuilder visitOnClause(OnClause node) {
    return LinkedNodeBuilder.onClause(
      onClause_superclassConstraints:
          _writeNodeList(node.superclassConstraints),
    );
  }

  @override
  LinkedNodeBuilder visitParenthesizedExpression(ParenthesizedExpression node) {
    var builder = LinkedNodeBuilder.parenthesizedExpression(
      parenthesizedExpression_expression: node.expression.accept(this),
    );
    _storeExpression(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitPartDirective(PartDirective node) {
    timerAstBinaryWriterDirective.start();
    try {
      var builder = LinkedNodeBuilder.partDirective();
      _storeUriBasedDirective(builder, node);
      return builder;
    } finally {
      timerAstBinaryWriterDirective.stop();
    }
  }

  @override
  LinkedNodeBuilder visitPartOfDirective(PartOfDirective node) {
    timerAstBinaryWriterDirective.start();
    try {
      var builder = LinkedNodeBuilder.partOfDirective(
        partOfDirective_libraryName: node.libraryName?.accept(this),
        partOfDirective_uri: node.uri?.accept(this),
      );
      _storeDirective(builder, node);
      return builder;
    } finally {
      timerAstBinaryWriterDirective.stop();
    }
  }

  @override
  LinkedNodeBuilder visitPostfixExpression(PostfixExpression node) {
    var elementComponents = _componentsOfElement(node.staticElement);
    return LinkedNodeBuilder.postfixExpression(
      expression_type: _writeType(node.staticType),
      postfixExpression_element: elementComponents.rawElement,
      postfixExpression_substitution: elementComponents.substitution,
      postfixExpression_operand: node.operand.accept(this),
      postfixExpression_operator: TokensWriter.astToBinaryTokenType(
        node.operator.type,
      ),
    );
  }

  @override
  LinkedNodeBuilder visitPrefixedIdentifier(PrefixedIdentifier node) {
    return LinkedNodeBuilder.prefixedIdentifier(
      prefixedIdentifier_identifier: node.identifier.accept(this),
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
      prefixExpression_substitution: elementComponents.substitution,
      prefixExpression_operand: node.operand.accept(this),
      prefixExpression_operator: TokensWriter.astToBinaryTokenType(
        node.operator.type,
      ),
    );
  }

  @override
  LinkedNodeBuilder visitPropertyAccess(PropertyAccess node) {
    var builder = LinkedNodeBuilder.propertyAccess(
      propertyAccess_operator: TokensWriter.astToBinaryTokenType(
        node.operator.type,
      ),
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
      redirectingConstructorInvocation_substitution:
          elementComponents.substitution,
    );
    builder.flags = AstBinaryFlags.encode(
      hasThis: node.thisKeyword != null,
    );
    _storeConstructorInitializer(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitRethrowExpression(RethrowExpression node) {
    return LinkedNodeBuilder.rethrowExpression(
      expression_type: _writeType(node.staticType),
    );
  }

  @override
  LinkedNodeBuilder visitReturnStatement(ReturnStatement node) {
    return LinkedNodeBuilder.returnStatement(
      returnStatement_expression: node.expression?.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitScriptTag(ScriptTag node) {
    return null;
  }

  @override
  LinkedNodeBuilder visitSetOrMapLiteral(SetOrMapLiteral node) {
    var builder = LinkedNodeBuilder.setOrMapLiteral(
      setOrMapLiteral_elements: _writeNodeList(node.elements),
    );
    _storeTypedLiteral(builder, node, isMap: node.isMap, isSet: node.isSet);
    return builder;
  }

  @override
  LinkedNodeBuilder visitShowCombinator(ShowCombinator node) {
    var builder = LinkedNodeBuilder.showCombinator(
      names: node.shownNames.map((id) => id.name).toList(),
    );
    _storeInformativeId(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitSimpleFormalParameter(SimpleFormalParameter node) {
    var builder = LinkedNodeBuilder.simpleFormalParameter(
      simpleFormalParameter_type: node.type?.accept(this),
    );
    builder.topLevelTypeInferenceError = LazyAst.getTypeInferenceError(node);
    _storeNormalFormalParameter(builder, node, node.keyword);
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
    var builder = LinkedNodeBuilder.simpleIdentifier(
      simpleIdentifier_element: elementComponents.rawElement,
      simpleIdentifier_substitution: elementComponents.substitution,
      expression_type: _writeType(node.staticType),
    );
    builder.flags = AstBinaryFlags.encode(
      isDeclaration: node is DeclaredSimpleIdentifier,
    );
    builder.name = node.name;
    return builder;
  }

  @override
  LinkedNodeBuilder visitSimpleStringLiteral(SimpleStringLiteral node) {
    var builder = LinkedNodeBuilder.simpleStringLiteral(
      simpleStringLiteral_value: node.value,
    );
    return builder;
  }

  @override
  LinkedNodeBuilder visitSpreadElement(SpreadElement node) {
    return LinkedNodeBuilder.spreadElement(
      spreadElement_expression: node.expression.accept(this),
      spreadElement_spreadOperator: TokensWriter.astToBinaryTokenType(
        node.spreadOperator.type,
      ),
    );
  }

  @override
  LinkedNodeBuilder visitStringInterpolation(StringInterpolation node) {
    return LinkedNodeBuilder.stringInterpolation(
      stringInterpolation_elements: _writeNodeList(node.elements),
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
      superConstructorInvocation_substitution: elementComponents.substitution,
    );
    _storeConstructorInitializer(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitSuperExpression(SuperExpression node) {
    var builder = LinkedNodeBuilder.superExpression();
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
      switchStatement_members: _writeNodeList(node.members),
    );
  }

  @override
  LinkedNodeBuilder visitSymbolLiteral(SymbolLiteral node) {
    var builder = LinkedNodeBuilder.symbolLiteral(
      names: node.components.map((t) => t.lexeme).toList(),
    );
    _storeExpression(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitThisExpression(ThisExpression node) {
    var builder = LinkedNodeBuilder.thisExpression();
    _storeExpression(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitThrowExpression(ThrowExpression node) {
    return LinkedNodeBuilder.throwExpression(
      throwExpression_expression: node.expression.accept(this),
      expression_type: _writeType(node.staticType),
    );
  }

  @override
  LinkedNodeBuilder visitTopLevelVariableDeclaration(
      TopLevelVariableDeclaration node) {
    timerAstBinaryWriterTopVar.start();
    try {
      var builder = LinkedNodeBuilder.topLevelVariableDeclaration(
        informativeId: getInformativeId(node),
        topLevelVariableDeclaration_variableList: node.variables?.accept(this),
      );
      _storeCompilationUnitMember(builder, node);

      return builder;
    } finally {
      timerAstBinaryWriterTopVar.stop();
    }
  }

  @override
  LinkedNodeBuilder visitTryStatement(TryStatement node) {
    return LinkedNodeBuilder.tryStatement(
      tryStatement_body: node.body.accept(this),
      tryStatement_catchClauses: _writeNodeList(node.catchClauses),
      tryStatement_finallyBlock: node.finallyBlock?.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitTypeArgumentList(TypeArgumentList node) {
    return LinkedNodeBuilder.typeArgumentList(
      typeArgumentList_arguments: _writeNodeList(node.arguments),
    );
  }

  @override
  LinkedNodeBuilder visitTypeName(TypeName node) {
    return LinkedNodeBuilder.typeName(
      typeName_name: node.name.accept(this),
      typeName_type: _writeType(node.type),
      typeName_typeArguments: _writeNodeList(
        node.typeArguments?.arguments,
      ),
    )..flags = AstBinaryFlags.encode(
        hasQuestion: node.question != null,
        hasTypeArguments: node.typeArguments != null,
      );
  }

  @override
  LinkedNodeBuilder visitTypeParameter(TypeParameter node) {
    var builder = LinkedNodeBuilder.typeParameter(
      typeParameter_bound: node.bound?.accept(this),
      typeParameter_defaultType: _writeType(LazyAst.getDefaultType(node)),
      typeParameter_variance: _getVarianceToken(node),
      informativeId: getInformativeId(node),
    );
    builder.name = node.name.name;
    _storeDeclaration(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitTypeParameterList(TypeParameterList node) {
    return LinkedNodeBuilder.typeParameterList(
      typeParameterList_typeParameters: _writeNodeList(node.typeParameters),
    );
  }

  @override
  LinkedNodeBuilder visitVariableDeclaration(VariableDeclaration node) {
    var initializer = node.initializer;
    var declarationList = node.parent as VariableDeclarationList;
    var declaration = declarationList.parent;
    if (declaration is TopLevelVariableDeclaration) {
      if (!declarationList.isConst) {
        initializer = null;
      }
    } else if (declaration is FieldDeclaration) {
      if (!(declarationList.isConst ||
          !declaration.isStatic &&
              declarationList.isFinal &&
              _hasConstConstructor)) {
        initializer = null;
      }
    }

    if (!_isSerializableExpression(initializer)) {
      initializer = null;
    }

    var builder = LinkedNodeBuilder.variableDeclaration(
      informativeId: getInformativeId(node),
      variableDeclaration_initializer: initializer?.accept(this),
    );
    builder.flags = AstBinaryFlags.encode(
      hasInitializer: node.initializer != null,
    );
    builder.name = node.name.name;
    builder.topLevelTypeInferenceError = LazyAst.getTypeInferenceError(node);
    _writeActualType(builder, node);
    _storeInheritsCovariant(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitVariableDeclarationList(VariableDeclarationList node) {
    var builder = LinkedNodeBuilder.variableDeclarationList(
      variableDeclarationList_type: node.type?.accept(this),
      variableDeclarationList_variables: _writeNodeList(node.variables),
    );
    builder.flags = AstBinaryFlags.encode(
      isConst: node.isConst,
      isFinal: node.isFinal,
      isLate: node.lateKeyword != null,
      isVar: node.keyword?.keyword == Keyword.VAR,
    );
    _storeAnnotatedNode(builder, node);
    return builder;
  }

  @override
  LinkedNodeBuilder visitVariableDeclarationStatement(
      VariableDeclarationStatement node) {
    return LinkedNodeBuilder.variableDeclarationStatement(
      variableDeclarationStatement_variables: node.variables.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitWhileStatement(WhileStatement node) {
    return LinkedNodeBuilder.whileStatement(
      whileStatement_body: node.body.accept(this),
      whileStatement_condition: node.condition.accept(this),
    );
  }

  @override
  LinkedNodeBuilder visitWithClause(WithClause node) {
    return LinkedNodeBuilder.withClause(
      withClause_mixinTypes: _writeNodeList(node.mixinTypes),
    );
  }

  @override
  LinkedNodeBuilder visitYieldStatement(YieldStatement node) {
    var builder = LinkedNodeBuilder.yieldStatement(
      yieldStatement_expression: node.expression.accept(this),
    );
    builder.flags = AstBinaryFlags.encode(
      isStar: node.star != null,
    );
    _storeStatement(builder, node);
    return builder;
  }

  LinkedNodeBuilder writeUnit(CompilationUnit unit) {
    timerAstBinaryWriter.start();
    try {
      return unit.accept(this);
    } finally {
      timerAstBinaryWriter.stop();
    }
  }

  _ElementComponents _componentsOfElement(Element element) {
    if (element is ParameterMember) {
      element = element.declaration;
    }

    if (element is Member) {
      var elementIndex = _indexOfElement(element.declaration);
      var substitution = element.substitution.map;
      var substitutionBuilder = LinkedNodeTypeSubstitutionBuilder(
        isLegacy: element.isLegacy,
        typeParameters: substitution.keys.map(_indexOfElement).toList(),
        typeArguments: substitution.values.map(_writeType).toList(),
      );
      return _ElementComponents(elementIndex, substitutionBuilder);
    }

    var elementIndex = _indexOfElement(element);
    return _ElementComponents(elementIndex, null);
  }

  UnlinkedTokenType _getVarianceToken(TypeParameter parameter) {
    // TODO (kallentu) : Clean up TypeParameterImpl casting once variance is
    // added to the interface.
    var parameterImpl = parameter as TypeParameterImpl;
    return parameterImpl.varianceKeyword != null
        ? TokensWriter.astToBinaryTokenType(parameterImpl.varianceKeyword.type)
        : null;
  }

  int _indexOfElement(Element element) {
    return _linkingContext.indexOfElement(element);
  }

  void _storeAnnotatedNode(LinkedNodeBuilder builder, AnnotatedNode node) {
    builder.annotatedNode_metadata = _writeNodeList(node.metadata);
  }

  void _storeClassMember(LinkedNodeBuilder builder, ClassMember node) {
    _storeDeclaration(builder, node);
  }

  void _storeClassOrMixinDeclaration(
      LinkedNodeBuilder builder, ClassOrMixinDeclaration node) {
    builder
      ..classOrMixinDeclaration_implementsClause =
          node.implementsClause?.accept(this)
      ..classOrMixinDeclaration_members = _writeNodeList(node.members)
      ..classOrMixinDeclaration_typeParameters =
          node.typeParameters?.accept(this);
    _storeNamedCompilationUnitMember(builder, node);
    _storeIsSimpleBounded(builder, node);
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
    _storeInformativeId(builder, node);
  }

  void _storeExpression(LinkedNodeBuilder builder, Expression node) {
    builder.expression_type = _writeType(node.staticType);
  }

  void _storeForEachParts(LinkedNodeBuilder builder, ForEachParts node) {
    _storeForLoopParts(builder, node);
    builder..forEachParts_iterable = node.iterable?.accept(this);
  }

  void _storeForLoopParts(LinkedNodeBuilder builder, ForLoopParts node) {}

  void _storeFormalParameter(LinkedNodeBuilder builder, FormalParameter node) {
    _writeActualType(builder, node);
  }

  void _storeForMixin(LinkedNodeBuilder builder, ForMixin node) {
    builder.flags = AstBinaryFlags.encode(
      hasAwait: node.awaitKeyword != null,
    );
    builder..forMixin_forLoopParts = node.forLoopParts.accept(this);
  }

  void _storeForParts(LinkedNodeBuilder builder, ForParts node) {
    _storeForLoopParts(builder, node);
    builder
      ..forParts_condition = node.condition?.accept(this)
      ..forParts_updaters = _writeNodeList(node.updaters);
  }

  void _storeFunctionBody(LinkedNodeBuilder builder, FunctionBody node) {}

  void _storeInformativeId(LinkedNodeBuilder builder, AstNode node) {
    builder.informativeId = getInformativeId(node);
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
    _storeInformativeId(builder, node);
    builder.name = node.name.name;
  }

  void _storeNamespaceDirective(
      LinkedNodeBuilder builder, NamespaceDirective node) {
    _storeUriBasedDirective(builder, node);
    builder
      ..namespaceDirective_combinators = _writeNodeList(node.combinators)
      ..namespaceDirective_configurations = _writeNodeList(node.configurations)
      ..namespaceDirective_selectedUri = LazyDirective.getSelectedUri(node);
  }

  void _storeNormalFormalParameter(
      LinkedNodeBuilder builder, NormalFormalParameter node, Token keyword) {
    _storeFormalParameter(builder, node);
    builder
      ..flags = AstBinaryFlags.encode(
        isConst: keyword?.type == Keyword.CONST,
        isCovariant: node.covariantKeyword != null,
        isFinal: keyword?.type == Keyword.FINAL,
        isRequired: node.requiredKeyword != null,
        isVar: keyword?.type == Keyword.VAR,
      )
      ..informativeId = getInformativeId(node)
      ..name = node.identifier?.name
      ..normalFormalParameter_metadata = _writeNodeList(node.metadata);
  }

  void _storeStatement(LinkedNodeBuilder builder, Statement node) {}

  void _storeSwitchMember(LinkedNodeBuilder builder, SwitchMember node) {
    builder.switchMember_labels = _writeNodeList(node.labels);
    builder.switchMember_statements = _writeNodeList(node.statements);
  }

  void _storeTypeAlias(LinkedNodeBuilder builder, TypeAlias node) {
    _storeNamedCompilationUnitMember(builder, node);
  }

  void _storeTypedLiteral(LinkedNodeBuilder builder, TypedLiteral node,
      {bool isMap = false, bool isSet = false}) {
    _storeExpression(builder, node);
    builder
      ..flags = AstBinaryFlags.encode(
        hasTypeArguments: node.typeArguments != null,
        isConst: node.constKeyword != null,
        isMap: isMap,
        isSet: isSet,
      )
      ..typedLiteral_typeArguments = _writeNodeList(
        node.typeArguments?.arguments,
      );
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
    if (nodeList == null) {
      return const <LinkedNodeBuilder>[];
    }

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

  /// Return `true` if the expression might be successfully serialized.
  ///
  /// This does not mean that the expression is constant, it just means that
  /// we know that it might be serialized and deserialized. For example
  /// function expressions are problematic, and are not necessary to
  /// deserialize, so we choose not to do this.
  static bool _isSerializableExpression(Expression node) {
    if (node == null) return false;

    var visitor = _IsSerializableExpressionVisitor();
    node.accept(visitor);
    return visitor.result;
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
      throw StateError('Unknown kind of parameter');
    }
  }
}

/// Components of a [Member] - the raw element, and the substitution.
class _ElementComponents {
  final int rawElement;
  final LinkedNodeTypeSubstitutionBuilder substitution;

  _ElementComponents(this.rawElement, this.substitution);
}

class _IsSerializableExpressionVisitor extends RecursiveAstVisitor<void> {
  bool result = true;

  @override
  void visitFunctionExpression(FunctionExpression node) {
    result = false;
  }
}
