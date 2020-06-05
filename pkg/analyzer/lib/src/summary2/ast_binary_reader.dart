// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/ast_binary_flags.dart';
import 'package:analyzer/src/summary2/lazy_ast.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:analyzer/src/summary2/tokens_context.dart';

var timerAstBinaryReader = Stopwatch();
var timerAstBinaryReaderClass = Stopwatch();
var timerAstBinaryReaderDirective = Stopwatch();
var timerAstBinaryReaderFunctionBody = Stopwatch();
var timerAstBinaryReaderFunctionDeclaration = Stopwatch();
var timerAstBinaryReaderMixin = Stopwatch();
var timerAstBinaryReaderTopLevelVar = Stopwatch();

/// Deserializer of fully resolved ASTs from flat buffers.
class AstBinaryReader {
  final LinkedUnitContext _unitContext;

  /// Set to `true` when this reader is used to lazily read its unit.
  bool isLazy = false;

  /// Whether we are reading a directive.
  ///
  /// [StringLiteral]s in directives are not actual expressions, and don't need
  /// a type. Moreover, when we are reading `dart:core` imports, the type
  /// provider is not ready yet, so we cannot access type `String`.
  bool _isReadingDirective = false;

  AstBinaryReader(this._unitContext);

  InterfaceType get _boolType => _unitContext.typeProvider.boolType;

  InterfaceType get _doubleType => _unitContext.typeProvider.doubleType;

  InterfaceType get _intType => _unitContext.typeProvider.intType;

  DartType get _nullType => _unitContext.typeProvider.nullType;

  InterfaceType get _stringType => _unitContext.typeProvider.stringType;

  AstNode readNode(LinkedNode data) {
    timerAstBinaryReader.start();
    try {
      return _readNode(data);
    } finally {
      timerAstBinaryReader.stop();
    }
  }

  DartType readType(LinkedNodeType data) {
    return _readType(data);
  }

  Token _combinatorKeyword(LinkedNode data, Keyword keyword, Token def) {
    var informativeData = _unitContext.getInformativeData(data);
    if (informativeData != null) {
      return TokenFactory.tokenFromKeyword(keyword)
        ..offset = informativeData.combinatorKeywordOffset;
    }
    return def;
  }

  SimpleIdentifier _declaredIdentifier(LinkedNode data) {
    var informativeData = _unitContext.getInformativeData(data);
    var offset = informativeData?.nameOffset ?? 0;
    return astFactory.simpleIdentifier(
      TokenFactory.tokenFromString(data.name)..offset = offset,
      isDeclaration: true,
    );
  }

  Token _directiveKeyword(LinkedNode data, Keyword keyword, Token def) {
    var informativeData = _unitContext.getInformativeData(data);
    if (informativeData != null) {
      return TokenFactory.tokenFromKeyword(keyword)
        ..offset = informativeData.directiveKeywordOffset;
    }
    return def;
  }

  Element _elementOfComponents(
    int rawElementIndex,
    LinkedNodeTypeSubstitution substitutionNode,
  ) {
    var element = _getElement(rawElementIndex);
    if (substitutionNode == null) return element;

    var typeParameters = substitutionNode.typeParameters
        .map<TypeParameterElement>(_getElement)
        .toList();
    var typeArguments = substitutionNode.typeArguments.map(_readType).toList();
    var substitution = Substitution.fromPairs(typeParameters, typeArguments);

    var member = ExecutableMember.from2(element, substitution);
    if (substitutionNode.isLegacy) {
      member = Member.legacy(member);
    }

    return member;
  }

  T _getElement<T extends Element>(int index) {
    var bundleContext = _unitContext.bundleContext;
    return bundleContext.elementOfIndex(index);
  }

  AdjacentStrings _read_adjacentStrings(LinkedNode data) {
    var node = astFactory.adjacentStrings(
      _readNodeList(data.adjacentStrings_strings),
    );
    if (!_isReadingDirective) {
      node.staticType = _stringType;
    }
    return node;
  }

  Annotation _read_annotation(LinkedNode data) {
    return astFactory.annotation(
      _Tokens.AT,
      _readNode(data.annotation_name),
      _Tokens.PERIOD,
      _readNode(data.annotation_constructorName),
      _readNode(data.annotation_arguments),
    )..element = _elementOfComponents(
        data.annotation_element,
        data.annotation_substitution,
      );
  }

  ArgumentList _read_argumentList(LinkedNode data) {
    return astFactory.argumentList(
      _Tokens.OPEN_PAREN,
      _readNodeList(data.argumentList_arguments),
      _Tokens.CLOSE_PAREN,
    );
  }

  AsExpression _read_asExpression(LinkedNode data) {
    return astFactory.asExpression(
      _readNode(data.asExpression_expression),
      _Tokens.AS,
      _readNode(data.asExpression_type),
    )..staticType = _readType(data.expression_type);
  }

  AssertInitializer _read_assertInitializer(LinkedNode data) {
    return astFactory.assertInitializer(
      _Tokens.ASSERT,
      _Tokens.OPEN_PAREN,
      _readNode(data.assertInitializer_condition),
      _Tokens.COMMA,
      _readNode(data.assertInitializer_message),
      _Tokens.CLOSE_PAREN,
    );
  }

  AssertStatement _read_assertStatement(LinkedNode data) {
    return astFactory.assertStatement(
      _Tokens.AS,
      _Tokens.OPEN_PAREN,
      _readNode(data.assertStatement_condition),
      _Tokens.COMMA,
      _readNode(data.assertStatement_message),
      _Tokens.CLOSE_PAREN,
      _Tokens.SEMICOLON,
    );
  }

  AssignmentExpression _read_assignmentExpression(LinkedNode data) {
    return astFactory.assignmentExpression(
      _readNode(data.assignmentExpression_leftHandSide),
      _Tokens.fromType(data.assignmentExpression_operator),
      _readNode(data.assignmentExpression_rightHandSide),
    )
      ..staticElement = _elementOfComponents(
        data.assignmentExpression_element,
        data.assignmentExpression_substitution,
      )
      ..staticType = _readType(data.expression_type);
  }

  AwaitExpression _read_awaitExpression(LinkedNode data) {
    return astFactory.awaitExpression(
      _Tokens.AWAIT,
      _readNode(data.awaitExpression_expression),
    )..staticType = _readType(data.expression_type);
  }

  BinaryExpression _read_binaryExpression(LinkedNode data) {
    return astFactory.binaryExpression(
      _readNode(data.binaryExpression_leftOperand),
      _Tokens.fromType(data.binaryExpression_operator),
      _readNode(data.binaryExpression_rightOperand),
    )
      ..staticElement = _elementOfComponents(
        data.binaryExpression_element,
        data.binaryExpression_substitution,
      )
      ..staticType = _readType(data.expression_type);
  }

  Block _read_block(LinkedNode data) {
    return astFactory.block(
      _Tokens.OPEN_CURLY_BRACKET,
      _readNodeList(data.block_statements),
      _Tokens.CLOSE_CURLY_BRACKET,
    );
  }

  BlockFunctionBody _read_blockFunctionBody(LinkedNode data) {
    timerAstBinaryReaderFunctionBody.start();
    try {
      return astFactory.blockFunctionBody(
        _Tokens.choose(
          AstBinaryFlags.isAsync(data.flags),
          _Tokens.ASYNC,
          AstBinaryFlags.isSync(data.flags),
          _Tokens.SYNC,
        ),
        AstBinaryFlags.isStar(data.flags) ? _Tokens.STAR : null,
        _readNode(data.blockFunctionBody_block),
      );
    } finally {
      timerAstBinaryReaderFunctionBody.stop();
    }
  }

  BooleanLiteral _read_booleanLiteral(LinkedNode data) {
    return AstTestFactory.booleanLiteral(data.booleanLiteral_value)
      ..staticType = _boolType;
  }

  BreakStatement _read_breakStatement(LinkedNode data) {
    return astFactory.breakStatement(
      _Tokens.BREAK,
      _readNode(data.breakStatement_label),
      _Tokens.SEMICOLON,
    );
  }

  CascadeExpression _read_cascadeExpression(LinkedNode data) {
    return astFactory.cascadeExpression(
      _readNode(data.cascadeExpression_target),
      _readNodeList(data.cascadeExpression_sections),
    )..staticType = _readType(data.expression_type);
  }

  CatchClause _read_catchClause(LinkedNode data) {
    var exceptionType = _readNode(data.catchClause_exceptionType);
    var exceptionParameter = _readNode(data.catchClause_exceptionParameter);
    var stackTraceParameter = _readNode(data.catchClause_stackTraceParameter);
    return astFactory.catchClause(
      exceptionType != null ? _Tokens.ON : null,
      exceptionType,
      exceptionParameter != null ? _Tokens.CATCH : null,
      exceptionParameter != null ? _Tokens.OPEN_PAREN : null,
      exceptionParameter,
      stackTraceParameter != null ? _Tokens.COMMA : null,
      stackTraceParameter,
      exceptionParameter != null ? _Tokens.CLOSE_PAREN : null,
      _readNode(data.catchClause_body),
    );
  }

  ClassDeclaration _read_classDeclaration(LinkedNode data) {
    timerAstBinaryReaderClass.start();
    try {
      var node = astFactory.classDeclaration(
        _readDocumentationComment(data),
        _readNodeListLazy(data.annotatedNode_metadata),
        AstBinaryFlags.isAbstract(data.flags) ? _Tokens.ABSTRACT : null,
        _Tokens.CLASS,
        _declaredIdentifier(data),
        _readNode(data.classOrMixinDeclaration_typeParameters),
        _readNodeLazy(data.classDeclaration_extendsClause),
        _readNodeLazy(data.classDeclaration_withClause),
        _readNodeLazy(data.classOrMixinDeclaration_implementsClause),
        _Tokens.OPEN_CURLY_BRACKET,
        _readNodeListLazy(data.classOrMixinDeclaration_members),
        _Tokens.CLOSE_CURLY_BRACKET,
      );
      node.nativeClause = _readNodeLazy(data.classDeclaration_nativeClause);
      LazyClassDeclaration.setData(node, data);
      return node;
    } finally {
      timerAstBinaryReaderClass.stop();
    }
  }

  ClassTypeAlias _read_classTypeAlias(LinkedNode data) {
    timerAstBinaryReaderClass.start();
    try {
      var node = astFactory.classTypeAlias(
        _readDocumentationComment(data),
        _readNodeListLazy(data.annotatedNode_metadata),
        _Tokens.CLASS,
        _declaredIdentifier(data),
        _readNode(data.classTypeAlias_typeParameters),
        _Tokens.EQ,
        AstBinaryFlags.isAbstract(data.flags) ? _Tokens.ABSTRACT : null,
        _readNodeLazy(data.classTypeAlias_superclass),
        _readNodeLazy(data.classTypeAlias_withClause),
        _readNodeLazy(data.classTypeAlias_implementsClause),
        _Tokens.SEMICOLON,
      );
      LazyClassTypeAlias.setData(node, data);
      return node;
    } finally {
      timerAstBinaryReaderClass.stop();
    }
  }

  Comment _read_comment(LinkedNode data) {
    var tokens = data.comment_tokens
        .map((lexeme) => TokenFactory.tokenFromString(lexeme))
        .toList();
    switch (data.comment_type) {
      case LinkedNodeCommentType.block:
        return astFactory.endOfLineComment(
          tokens,
        );
      case LinkedNodeCommentType.documentation:
        return astFactory.documentationComment(
          tokens,
          _readNodeList(data.comment_references),
        );
      case LinkedNodeCommentType.endOfLine:
        return astFactory.endOfLineComment(
          tokens,
        );
      default:
        throw StateError('${data.comment_type}');
    }
  }

  CommentReference _read_commentReference(LinkedNode data) {
    return astFactory.commentReference(
      AstBinaryFlags.isNew(data.flags) ? _Tokens.NEW : null,
      _readNode(data.commentReference_identifier),
    );
  }

  CompilationUnit _read_compilationUnit(LinkedNode data) {
    var node = astFactory.compilationUnit(
      beginToken: null,
      scriptTag: _readNode(data.compilationUnit_scriptTag),
      directives: _readNodeList(data.compilationUnit_directives),
      declarations: _readNodeList(data.compilationUnit_declarations),
      endToken: null,
      featureSet: null,
    );
    LazyCompilationUnit(node, data);
    return node;
  }

  ConditionalExpression _read_conditionalExpression(LinkedNode data) {
    return astFactory.conditionalExpression(
      _readNode(data.conditionalExpression_condition),
      _Tokens.QUESTION,
      _readNode(data.conditionalExpression_thenExpression),
      _Tokens.COLON,
      _readNode(data.conditionalExpression_elseExpression),
    )..staticType = _readType(data.expression_type);
  }

  Configuration _read_configuration(LinkedNode data) {
    return astFactory.configuration(
      _Tokens.IF,
      _Tokens.OPEN_PAREN,
      _readNode(data.configuration_name),
      AstBinaryFlags.hasEqual(data.flags) ? _Tokens.EQ : null,
      _readNode(data.configuration_value),
      _Tokens.CLOSE_PAREN,
      _readNode(data.configuration_uri),
    );
  }

  ConstructorDeclaration _read_constructorDeclaration(LinkedNode data) {
    SimpleIdentifier returnType = _readNode(
      data.constructorDeclaration_returnType,
    );

    var informativeData = _unitContext.getInformativeData(data);
    returnType.token.offset =
        informativeData?.constructorDeclaration_returnTypeOffset ?? 0;

    Token periodToken;
    SimpleIdentifier nameIdentifier;
    if (AstBinaryFlags.hasName(data.flags)) {
      periodToken = Token(
        TokenType.PERIOD,
        informativeData?.constructorDeclaration_periodOffset ?? 0,
      );
      nameIdentifier = _declaredIdentifier(data);
    }

    var node = astFactory.constructorDeclaration(
      _readDocumentationComment(data),
      _readNodeListLazy(data.annotatedNode_metadata),
      AstBinaryFlags.isExternal(data.flags) ? _Tokens.EXTERNAL : null,
      AstBinaryFlags.isConst(data.flags) ? _Tokens.CONST : null,
      AstBinaryFlags.isFactory(data.flags) ? _Tokens.FACTORY : null,
      returnType,
      periodToken,
      nameIdentifier,
      _readNodeLazy(data.constructorDeclaration_parameters),
      _Tokens.choose(
        AstBinaryFlags.hasSeparatorColon(data.flags),
        _Tokens.COLON,
        AstBinaryFlags.hasSeparatorEquals(data.flags),
        _Tokens.EQ,
      ),
      _readNodeListLazy(data.constructorDeclaration_initializers),
      _readNodeLazy(data.constructorDeclaration_redirectedConstructor),
      _readNodeLazy(data.constructorDeclaration_body),
    );
    LazyConstructorDeclaration.setData(node, data);
    return node;
  }

  ConstructorFieldInitializer _read_constructorFieldInitializer(
      LinkedNode data) {
    var hasThis = AstBinaryFlags.hasThis(data.flags);
    return astFactory.constructorFieldInitializer(
      hasThis ? _Tokens.THIS : null,
      hasThis ? _Tokens.PERIOD : null,
      _readNode(data.constructorFieldInitializer_fieldName),
      _Tokens.EQ,
      _readNode(data.constructorFieldInitializer_expression),
    );
  }

  ConstructorName _read_constructorName(LinkedNode data) {
    return astFactory.constructorName(
      _readNode(data.constructorName_type),
      data.constructorName_name != null ? _Tokens.PERIOD : null,
      _readNode(data.constructorName_name),
    )..staticElement = _elementOfComponents(
        data.constructorName_element,
        data.constructorName_substitution,
      );
  }

  ContinueStatement _read_continueStatement(LinkedNode data) {
    return astFactory.continueStatement(
      _Tokens.CONTINUE,
      _readNode(data.continueStatement_label),
      _Tokens.SEMICOLON,
    );
  }

  DeclaredIdentifier _read_declaredIdentifier(LinkedNode data) {
    return astFactory.declaredIdentifier(
      _readDocumentationComment(data),
      _readNodeList(data.annotatedNode_metadata),
      _Tokens.choose(
        AstBinaryFlags.isConst(data.flags),
        _Tokens.CONST,
        AstBinaryFlags.isFinal(data.flags),
        _Tokens.FINAL,
        AstBinaryFlags.isVar(data.flags),
        _Tokens.VAR,
      ),
      _readNode(data.declaredIdentifier_type),
      _readNode(data.declaredIdentifier_identifier),
    );
  }

  DefaultFormalParameter _read_defaultFormalParameter(LinkedNode data) {
    var node = astFactory.defaultFormalParameter(
      _readNode(data.defaultFormalParameter_parameter),
      _toParameterKind(data.defaultFormalParameter_kind),
      data.defaultFormalParameter_defaultValue != null ? _Tokens.COLON : null,
      _readNodeLazy(data.defaultFormalParameter_defaultValue),
    );
    LazyFormalParameter.setData(node, data);
    return node;
  }

  DoStatement _read_doStatement(LinkedNode data) {
    return astFactory.doStatement(
      _Tokens.DO,
      _readNode(data.doStatement_body),
      _Tokens.WHILE,
      _Tokens.OPEN_PAREN,
      _readNode(data.doStatement_condition),
      _Tokens.CLOSE_PAREN,
      _Tokens.SEMICOLON,
    );
  }

  DottedName _read_dottedName(LinkedNode data) {
    return astFactory.dottedName(
      _readNodeList(data.dottedName_components),
    );
  }

  DoubleLiteral _read_doubleLiteral(LinkedNode data) {
    return AstTestFactory.doubleLiteral(data.doubleLiteral_value)
      ..staticType = _doubleType;
  }

  EmptyFunctionBody _read_emptyFunctionBody(LinkedNode data) {
    return astFactory.emptyFunctionBody(
      _Tokens.SEMICOLON,
    );
  }

  EmptyStatement _read_emptyStatement(LinkedNode data) {
    return astFactory.emptyStatement(
      _Tokens.SEMICOLON,
    );
  }

  EnumConstantDeclaration _read_enumConstantDeclaration(LinkedNode data) {
    var node = astFactory.enumConstantDeclaration(
      _readDocumentationComment(data),
      _readNodeListLazy(data.annotatedNode_metadata),
      _declaredIdentifier(data),
    );
    LazyEnumConstantDeclaration.setData(node, data);
    return node;
  }

  EnumDeclaration _read_enumDeclaration(LinkedNode data) {
    var node = astFactory.enumDeclaration(
      _readDocumentationComment(data),
      _readNodeListLazy(data.annotatedNode_metadata),
      _Tokens.ENUM,
      _declaredIdentifier(data),
      _Tokens.OPEN_CURLY_BRACKET,
      _readNodeListLazy(data.enumDeclaration_constants),
      _Tokens.CLOSE_CURLY_BRACKET,
    );
    LazyEnumDeclaration.setData(node, data);
    return node;
  }

  ExportDirective _read_exportDirective(LinkedNode data) {
    timerAstBinaryReaderDirective.start();
    _isReadingDirective = true;
    try {
      var node = astFactory.exportDirective(
        _readDocumentationComment(data),
        _readNodeListLazy(data.annotatedNode_metadata),
        _directiveKeyword(data, Keyword.EXPORT, _Tokens.EXPORT),
        _readNode(data.uriBasedDirective_uri),
        _readNodeList(data.namespaceDirective_configurations),
        _readNodeList(data.namespaceDirective_combinators),
        _Tokens.SEMICOLON,
      );
      LazyDirective.setData(node, data);
      return node;
    } finally {
      _isReadingDirective = false;
      timerAstBinaryReaderDirective.stop();
    }
  }

  ExpressionFunctionBody _read_expressionFunctionBody(LinkedNode data) {
    timerAstBinaryReaderFunctionBody.start();
    try {
      return astFactory.expressionFunctionBody(
        _Tokens.choose(
          AstBinaryFlags.isAsync(data.flags),
          _Tokens.ASYNC,
          AstBinaryFlags.isSync(data.flags),
          _Tokens.SYNC,
        ),
        _Tokens.ARROW,
        _readNode(data.expressionFunctionBody_expression),
        _Tokens.SEMICOLON,
      );
    } finally {
      timerAstBinaryReaderFunctionBody.stop();
    }
  }

  ExpressionStatement _read_expressionStatement(LinkedNode data) {
    return astFactory.expressionStatement(
      _readNode(data.expressionStatement_expression),
      _Tokens.SEMICOLON,
    );
  }

  ExtendsClause _read_extendsClause(LinkedNode data) {
    return astFactory.extendsClause(
      _Tokens.EXTENDS,
      _readNode(data.extendsClause_superclass),
    );
  }

  ExtensionDeclaration _read_extensionDeclaration(LinkedNode data) {
    timerAstBinaryReaderClass.start();
    try {
      var node = astFactory.extensionDeclaration(
        comment: _readDocumentationComment(data),
        metadata: _readNodeListLazy(data.annotatedNode_metadata),
        extensionKeyword: _Tokens.EXTENSION,
        name: data.name.isNotEmpty ? _declaredIdentifier(data) : null,
        typeParameters: _readNode(data.extensionDeclaration_typeParameters),
        onKeyword: _Tokens.ON,
        extendedType: _readNodeLazy(data.extensionDeclaration_extendedType),
        leftBracket: _Tokens.OPEN_CURLY_BRACKET,
        members: _readNodeListLazy(data.extensionDeclaration_members),
        rightBracket: _Tokens.CLOSE_CURLY_BRACKET,
      );
      LazyExtensionDeclaration(node, data);
      return node;
    } finally {
      timerAstBinaryReaderClass.stop();
    }
  }

  ExtensionOverride _read_extensionOverride(LinkedNode data) {
    var node = astFactory.extensionOverride(
      extensionName: _readNode(data.extensionOverride_extensionName),
      argumentList: astFactory.argumentList(
        _Tokens.OPEN_PAREN,
        _readNodeList(
          data.extensionOverride_arguments,
        ),
        _Tokens.CLOSE_PAREN,
      ),
      typeArguments: _readNode(data.extensionOverride_typeArguments),
    ) as ExtensionOverrideImpl;
    node.extendedType = _readType(data.extensionOverride_extendedType);
    node.typeArgumentTypes =
        data.extensionOverride_typeArgumentTypes.map(_readType).toList();
    return node;
  }

  FieldDeclaration _read_fieldDeclaration(LinkedNode data) {
    var node = astFactory.fieldDeclaration2(
      comment: _readDocumentationComment(data),
      covariantKeyword:
          AstBinaryFlags.isCovariant(data.flags) ? _Tokens.COVARIANT : null,
      fieldList: _readNode(data.fieldDeclaration_fields),
      metadata: _readNodeListLazy(data.annotatedNode_metadata),
      semicolon: _Tokens.SEMICOLON,
      staticKeyword:
          AstBinaryFlags.isStatic(data.flags) ? _Tokens.STATIC : null,
    );
    LazyFieldDeclaration.setData(node, data);
    return node;
  }

  FieldFormalParameter _read_fieldFormalParameter(LinkedNode data) {
    var node = astFactory.fieldFormalParameter2(
      identifier: _declaredIdentifier(data),
      period: _Tokens.PERIOD,
      thisKeyword: _Tokens.THIS,
      covariantKeyword:
          AstBinaryFlags.isCovariant(data.flags) ? _Tokens.COVARIANT : null,
      typeParameters: _readNode(data.fieldFormalParameter_typeParameters),
      keyword: _Tokens.choose(
        AstBinaryFlags.isConst(data.flags),
        _Tokens.CONST,
        AstBinaryFlags.isFinal(data.flags),
        _Tokens.FINAL,
        AstBinaryFlags.isVar(data.flags),
        _Tokens.VAR,
      ),
      metadata: _readNodeList(data.normalFormalParameter_metadata),
      comment: _readDocumentationComment(data),
      type: _readNodeLazy(data.fieldFormalParameter_type),
      parameters: _readNodeLazy(data.fieldFormalParameter_formalParameters),
      question:
          AstBinaryFlags.hasQuestion(data.flags) ? _Tokens.QUESTION : null,
      requiredKeyword:
          AstBinaryFlags.isRequired(data.flags) ? _Tokens.REQUIRED : null,
    );
    LazyFormalParameter.setData(node, data);
    return node;
  }

  ForEachPartsWithDeclaration _read_forEachPartsWithDeclaration(
      LinkedNode data) {
    return astFactory.forEachPartsWithDeclaration(
      inKeyword: _Tokens.IN,
      iterable: _readNode(data.forEachParts_iterable),
      loopVariable: _readNode(data.forEachPartsWithDeclaration_loopVariable),
    );
  }

  ForEachPartsWithIdentifier _read_forEachPartsWithIdentifier(LinkedNode data) {
    return astFactory.forEachPartsWithIdentifier(
      inKeyword: _Tokens.IN,
      iterable: _readNode(data.forEachParts_iterable),
      identifier: _readNode(data.forEachPartsWithIdentifier_identifier),
    );
  }

  ForElement _read_forElement(LinkedNode data) {
    return astFactory.forElement(
      awaitKeyword: AstBinaryFlags.hasAwait(data.flags) ? _Tokens.AWAIT : null,
      body: _readNode(data.forElement_body),
      forKeyword: _Tokens.FOR,
      forLoopParts: _readNode(data.forMixin_forLoopParts),
      leftParenthesis: _Tokens.OPEN_PAREN,
      rightParenthesis: _Tokens.CLOSE_PAREN,
    );
  }

  FormalParameterList _read_formalParameterList(LinkedNode data) {
    return astFactory.formalParameterList(
      _Tokens.OPEN_PAREN,
      _readNodeList(data.formalParameterList_parameters),
      _Tokens.choose(
        AstBinaryFlags.isDelimiterCurly(data.flags),
        _Tokens.OPEN_CURLY_BRACKET,
        AstBinaryFlags.isDelimiterSquare(data.flags),
        _Tokens.OPEN_SQUARE_BRACKET,
      ),
      _Tokens.choose(
        AstBinaryFlags.isDelimiterCurly(data.flags),
        _Tokens.CLOSE_CURLY_BRACKET,
        AstBinaryFlags.isDelimiterSquare(data.flags),
        _Tokens.CLOSE_SQUARE_BRACKET,
      ),
      _Tokens.CLOSE_PAREN,
    );
  }

  ForPartsWithDeclarations _read_forPartsWithDeclarations(LinkedNode data) {
    return astFactory.forPartsWithDeclarations(
      condition: _readNode(data.forParts_condition),
      leftSeparator: _Tokens.SEMICOLON,
      rightSeparator: _Tokens.SEMICOLON,
      updaters: _readNodeList(data.forParts_updaters),
      variables: _readNode(data.forPartsWithDeclarations_variables),
    );
  }

  ForPartsWithExpression _read_forPartsWithExpression(LinkedNode data) {
    return astFactory.forPartsWithExpression(
      condition: _readNode(data.forParts_condition),
      initialization: _readNode(data.forPartsWithExpression_initialization),
      leftSeparator: _Tokens.SEMICOLON,
      rightSeparator: _Tokens.SEMICOLON,
      updaters: _readNodeList(data.forParts_updaters),
    );
  }

  ForStatement _read_forStatement(LinkedNode data) {
    return astFactory.forStatement(
      awaitKeyword: AstBinaryFlags.hasAwait(data.flags) ? _Tokens.AWAIT : null,
      forKeyword: _Tokens.FOR,
      leftParenthesis: _Tokens.OPEN_PAREN,
      forLoopParts: _readNode(data.forMixin_forLoopParts),
      rightParenthesis: _Tokens.CLOSE_PAREN,
      body: _readNode(data.forStatement_body),
    );
  }

  FunctionDeclaration _read_functionDeclaration(LinkedNode data) {
    timerAstBinaryReaderFunctionDeclaration.start();
    try {
      var node = astFactory.functionDeclaration(
        _readDocumentationComment(data),
        _readNodeListLazy(data.annotatedNode_metadata),
        AstBinaryFlags.isExternal(data.flags) ? _Tokens.EXTERNAL : null,
        _readNodeLazy(data.functionDeclaration_returnType),
        _Tokens.choose(
          AstBinaryFlags.isGet(data.flags),
          _Tokens.GET,
          AstBinaryFlags.isSet(data.flags),
          _Tokens.SET,
        ),
        _declaredIdentifier(data),
        _readNodeLazy(data.functionDeclaration_functionExpression),
      );
      LazyFunctionDeclaration.setData(node, data);
      return node;
    } finally {
      timerAstBinaryReaderFunctionDeclaration.stop();
    }
  }

  FunctionDeclarationStatement _read_functionDeclarationStatement(
      LinkedNode data) {
    return astFactory.functionDeclarationStatement(
      _readNode(data.functionDeclarationStatement_functionDeclaration),
    );
  }

  FunctionExpression _read_functionExpression(LinkedNode data) {
    var node = astFactory.functionExpression(
      _readNode(data.functionExpression_typeParameters),
      _readNodeLazy(data.functionExpression_formalParameters),
      _readNodeLazy(data.functionExpression_body),
    );
    LazyFunctionExpression.setData(node, data);
    return node;
  }

  FunctionExpressionInvocation _read_functionExpressionInvocation(
      LinkedNode data) {
    return astFactory.functionExpressionInvocation(
      _readNode(data.functionExpressionInvocation_function),
      _readNode(data.invocationExpression_typeArguments),
      _readNode(data.invocationExpression_arguments),
    )..staticInvokeType = _readType(data.invocationExpression_invokeType);
  }

  FunctionTypeAlias _read_functionTypeAlias(LinkedNode data) {
    var node = astFactory.functionTypeAlias(
      _readDocumentationComment(data),
      _readNodeListLazy(data.annotatedNode_metadata),
      _Tokens.TYPEDEF,
      _readNodeLazy(data.functionTypeAlias_returnType),
      _declaredIdentifier(data),
      _readNode(data.functionTypeAlias_typeParameters),
      _readNodeLazy(data.functionTypeAlias_formalParameters),
      _Tokens.SEMICOLON,
    );
    LazyFunctionTypeAlias.setData(node, data);
    LazyFunctionTypeAlias.setHasSelfReference(
      node,
      data.typeAlias_hasSelfReference,
    );
    return node;
  }

  FunctionTypedFormalParameter _read_functionTypedFormalParameter(
      LinkedNode data) {
    var node = astFactory.functionTypedFormalParameter2(
      comment: _readDocumentationComment(data),
      covariantKeyword:
          AstBinaryFlags.isCovariant(data.flags) ? _Tokens.COVARIANT : null,
      identifier: _declaredIdentifier(data),
      metadata: _readNodeListLazy(data.normalFormalParameter_metadata),
      parameters: _readNodeLazy(
        data.functionTypedFormalParameter_formalParameters,
      ),
      requiredKeyword:
          AstBinaryFlags.isRequired(data.flags) ? _Tokens.REQUIRED : null,
      returnType: _readNodeLazy(data.functionTypedFormalParameter_returnType),
      typeParameters: _readNode(
        data.functionTypedFormalParameter_typeParameters,
      ),
    );
    LazyFormalParameter.setData(node, data);
    return node;
  }

  GenericFunctionType _read_genericFunctionType(LinkedNode data) {
    var id = data.genericFunctionType_id;

    // Read type parameters, without bounds, to avoid forward references.
    TypeParameterList typeParameterList;
    var typeParameterListData = data.genericFunctionType_typeParameters;
    if (typeParameterListData != null) {
      var dataList = typeParameterListData.typeParameterList_typeParameters;
      var typeParameters = List<TypeParameter>(dataList.length);
      for (var i = 0; i < dataList.length; ++i) {
        var data = dataList[i];
        typeParameters[i] = astFactory.typeParameter(
          _readDocumentationComment(data),
          _readNodeList(data.annotatedNode_metadata),
          _declaredIdentifier(data),
          data.typeParameter_bound != null ? _Tokens.EXTENDS : null,
          null,
        );
      }
      typeParameterList = astFactory.typeParameterList(
        _Tokens.LT,
        typeParameters,
        _Tokens.GT,
      );
    }

    GenericFunctionTypeImpl node = astFactory.genericFunctionType(
      null,
      _Tokens.FUNCTION,
      typeParameterList,
      null,
      question:
          AstBinaryFlags.hasQuestion(data.flags) ? _Tokens.QUESTION : null,
    );

    // Create the node element, so now type parameter elements are available.
    LazyAst.setGenericFunctionTypeId(node, id);
    _unitContext.createGenericFunctionTypeElement(id, node);

    // Finish reading.
    if (typeParameterListData != null) {
      var dataList = typeParameterListData.typeParameterList_typeParameters;
      var typeParameters = typeParameterList.typeParameters;
      for (var i = 0; i < dataList.length; ++i) {
        var data = dataList[i];
        var node = typeParameters[i];
        node.bound = _readNode(data.typeParameter_bound);
      }
    }
    node.returnType = readNode(data.genericFunctionType_returnType);
    node.parameters = _readNode(data.genericFunctionType_formalParameters);
    node.type = _readType(data.genericFunctionType_type);

    return node;
  }

  GenericTypeAlias _read_genericTypeAlias(LinkedNode data) {
    var node = astFactory.genericTypeAlias(
      _readDocumentationComment(data),
      _readNodeListLazy(data.annotatedNode_metadata),
      _Tokens.TYPEDEF,
      _declaredIdentifier(data),
      _readNode(data.genericTypeAlias_typeParameters),
      _Tokens.EQ,
      _readNodeLazy(data.genericTypeAlias_functionType),
      _Tokens.SEMICOLON,
    );
    LazyGenericTypeAlias.setData(node, data);
    LazyGenericTypeAlias.setHasSelfReference(
      node,
      data.typeAlias_hasSelfReference,
    );
    return node;
  }

  HideCombinator _read_hideCombinator(LinkedNode data) {
    var node = astFactory.hideCombinator(
      _combinatorKeyword(data, Keyword.HIDE, _Tokens.HIDE),
      data.names.map((name) => AstTestFactory.identifier3(name)).toList(),
    );
    LazyCombinator(node, data);
    return node;
  }

  IfElement _read_ifElement(LinkedNode data) {
    var elseElement = _readNode(data.ifElement_elseElement);
    return astFactory.ifElement(
      condition: _readNode(data.ifMixin_condition),
      elseElement: elseElement,
      elseKeyword: elseElement != null ? _Tokens.ELSE : null,
      ifKeyword: _Tokens.IF,
      leftParenthesis: _Tokens.OPEN_PAREN,
      rightParenthesis: _Tokens.CLOSE_PAREN,
      thenElement: _readNode(data.ifElement_thenElement),
    );
  }

  IfStatement _read_ifStatement(LinkedNode data) {
    var elseStatement = _readNode(data.ifStatement_elseStatement);
    return astFactory.ifStatement(
      _Tokens.IF,
      _Tokens.OPEN_PAREN,
      _readNode(data.ifMixin_condition),
      _Tokens.CLOSE_PAREN,
      _readNode(data.ifStatement_thenStatement),
      elseStatement != null ? _Tokens.ELSE : null,
      elseStatement,
    );
  }

  ImplementsClause _read_implementsClause(LinkedNode data) {
    return astFactory.implementsClause(
      _Tokens.IMPLEMENTS,
      _readNodeList(data.implementsClause_interfaces),
    );
  }

  ImportDirective _read_importDirective(LinkedNode data) {
    timerAstBinaryReaderDirective.start();
    _isReadingDirective = true;
    try {
      SimpleIdentifier prefix;
      if (data.importDirective_prefix.isNotEmpty) {
        prefix = astFactory.simpleIdentifier(
          TokenFactory.tokenFromString(data.importDirective_prefix),
        );

        var informativeData = _unitContext.getInformativeData(data);
        prefix.token.offset =
            informativeData?.importDirective_prefixOffset ?? 0;
      }

      var node = astFactory.importDirective(
        _readDocumentationComment(data),
        _readNodeListLazy(data.annotatedNode_metadata),
        _directiveKeyword(data, Keyword.IMPORT, _Tokens.IMPORT),
        _readNode(data.uriBasedDirective_uri),
        _readNodeList(data.namespaceDirective_configurations),
        AstBinaryFlags.isDeferred(data.flags) ? _Tokens.DEFERRED : null,
        _Tokens.AS,
        prefix,
        _readNodeList(data.namespaceDirective_combinators),
        _Tokens.SEMICOLON,
      );
      LazyDirective.setData(node, data);
      return node;
    } finally {
      _isReadingDirective = false;
      timerAstBinaryReaderDirective.stop();
    }
  }

  IndexExpression _read_indexExpression(LinkedNode data) {
    return astFactory.indexExpressionForTarget2(
      target: _readNode(data.indexExpression_target),
      question:
          AstBinaryFlags.hasQuestion(data.flags) ? _Tokens.QUESTION : null,
      leftBracket: _Tokens.OPEN_SQUARE_BRACKET,
      index: _readNode(data.indexExpression_index),
      rightBracket: _Tokens.CLOSE_SQUARE_BRACKET,
    )
      ..period =
          AstBinaryFlags.hasPeriod(data.flags) ? _Tokens.PERIOD_PERIOD : null
      ..staticElement = _elementOfComponents(
        data.indexExpression_element,
        data.indexExpression_substitution,
      )
      ..staticType = _readType(data.expression_type);
  }

  InstanceCreationExpression _read_instanceCreationExpression(LinkedNode data) {
    var node = astFactory.instanceCreationExpression(
      _Tokens.choose(
        AstBinaryFlags.isConst(data.flags),
        _Tokens.CONST,
        AstBinaryFlags.isNew(data.flags),
        _Tokens.NEW,
      ),
      _readNode(data.instanceCreationExpression_constructorName),
      astFactory.argumentList(
        _Tokens.OPEN_PAREN,
        _readNodeList(
          data.instanceCreationExpression_arguments,
        ),
        _Tokens.CLOSE_PAREN,
      ),
      typeArguments: _readNode(data.instanceCreationExpression_typeArguments),
    );
    node.staticType = _readType(data.expression_type);
    return node;
  }

  IntegerLiteral _read_integerLiteral(LinkedNode data) {
    // TODO(scheglov) Remove `?? _intType` after internal SDK roll.
    return AstTestFactory.integer(data.integerLiteral_value)
      ..staticType = _readType(data.expression_type) ?? _intType;
  }

  InterpolationExpression _read_interpolationExpression(LinkedNode data) {
    var isIdentifier =
        AstBinaryFlags.isStringInterpolationIdentifier(data.flags);
    return astFactory.interpolationExpression(
      isIdentifier
          ? _Tokens.OPEN_CURLY_BRACKET
          : _Tokens.STRING_INTERPOLATION_EXPRESSION,
      _readNode(data.interpolationExpression_expression),
      isIdentifier ? null : _Tokens.CLOSE_CURLY_BRACKET,
    );
  }

  InterpolationString _read_interpolationString(LinkedNode data) {
    return astFactory.interpolationString(
      TokenFactory.tokenFromString(data.interpolationString_value),
      data.interpolationString_value,
    );
  }

  IsExpression _read_isExpression(LinkedNode data) {
    return astFactory.isExpression(
      _readNode(data.isExpression_expression),
      _Tokens.IS,
      AstBinaryFlags.hasNot(data.flags) ? _Tokens.BANG : null,
      _readNode(data.isExpression_type),
    )..staticType = _boolType;
  }

  Label _read_label(LinkedNode data) {
    return astFactory.label(
      _readNode(data.label_label),
      _Tokens.COLON,
    );
  }

  LabeledStatement _read_labeledStatement(LinkedNode data) {
    return astFactory.labeledStatement(
      _readNodeList(data.labeledStatement_labels),
      _readNode(data.labeledStatement_statement),
    );
  }

  LibraryDirective _read_libraryDirective(LinkedNode data) {
    timerAstBinaryReaderDirective.start();
    _isReadingDirective = true;
    try {
      var node = astFactory.libraryDirective(
        _unitContext.createComment(data),
        _readNodeListLazy(data.annotatedNode_metadata),
        _Tokens.LIBRARY,
        _readNode(data.libraryDirective_name),
        _Tokens.SEMICOLON,
      );
      LazyDirective.setData(node, data);
      return node;
    } finally {
      _isReadingDirective = false;
      timerAstBinaryReaderDirective.stop();
    }
  }

  LibraryIdentifier _read_libraryIdentifier(LinkedNode data) {
    return astFactory.libraryIdentifier(
      _readNodeList(data.libraryIdentifier_components),
    );
  }

  ListLiteral _read_listLiteral(LinkedNode data) {
    return astFactory.listLiteral(
      AstBinaryFlags.isConst(data.flags) ? _Tokens.CONST : null,
      AstBinaryFlags.hasTypeArguments(data.flags)
          ? astFactory.typeArgumentList(
              _Tokens.LT,
              _readNodeList(data.typedLiteral_typeArguments),
              _Tokens.GT,
            )
          : null,
      _Tokens.OPEN_SQUARE_BRACKET,
      _readNodeList(data.listLiteral_elements),
      _Tokens.CLOSE_SQUARE_BRACKET,
    )..staticType = _readType(data.expression_type);
  }

  MapLiteralEntry _read_mapLiteralEntry(LinkedNode data) {
    return astFactory.mapLiteralEntry(
      _readNode(data.mapLiteralEntry_key),
      _Tokens.COLON,
      _readNode(data.mapLiteralEntry_value),
    );
  }

  MethodDeclaration _read_methodDeclaration(LinkedNode data) {
    FunctionBody body;
    if (AstBinaryFlags.isNative(data.flags)) {
      body = AstTestFactory.nativeFunctionBody('');
    } else if (AstBinaryFlags.isAbstract(data.flags)) {
      body = AstTestFactory.emptyFunctionBody();
    } else {
      body = AstTestFactory.blockFunctionBody(AstTestFactory.block());
    }

    var node = astFactory.methodDeclaration(
      _readDocumentationComment(data),
      _readNodeListLazy(data.annotatedNode_metadata),
      AstBinaryFlags.isExternal(data.flags) ? _Tokens.EXTERNAL : null,
      AstBinaryFlags.isStatic(data.flags) ? _Tokens.STATIC : null,
      _readNodeLazy(data.methodDeclaration_returnType),
      _Tokens.choose(
        AstBinaryFlags.isGet(data.flags),
        _Tokens.GET,
        AstBinaryFlags.isSet(data.flags),
        _Tokens.SET,
      ),
      AstBinaryFlags.isOperator(data.flags) ? _Tokens.OPERATOR : null,
      _declaredIdentifier(data),
      _readNode(data.methodDeclaration_typeParameters),
      _readNodeLazy(data.methodDeclaration_formalParameters),
      body,
    );
    LazyMethodDeclaration.setData(node, data);
    LazyAst.setOperatorEqualParameterTypeFromObject(
      node,
      data.methodDeclaration_hasOperatorEqualWithParameterTypeFromObject,
    );
    return node;
  }

  MethodInvocation _read_methodInvocation(LinkedNode data) {
    return astFactory.methodInvocation(
      _readNode(data.methodInvocation_target),
      _Tokens.choose(
        AstBinaryFlags.hasPeriod(data.flags),
        _Tokens.PERIOD,
        AstBinaryFlags.hasPeriod2(data.flags),
        _Tokens.PERIOD_PERIOD,
      ),
      _readNode(data.methodInvocation_methodName),
      _readNode(data.invocationExpression_typeArguments),
      _readNode(data.invocationExpression_arguments),
    )..staticInvokeType = _readType(data.invocationExpression_invokeType);
  }

  MixinDeclaration _read_mixinDeclaration(LinkedNode data) {
    timerAstBinaryReaderMixin.start();
    try {
      var node = astFactory.mixinDeclaration(
        _readDocumentationComment(data),
        _readNodeListLazy(data.annotatedNode_metadata),
        _Tokens.MIXIN,
        _declaredIdentifier(data),
        _readNode(data.classOrMixinDeclaration_typeParameters),
        _readNodeLazy(data.mixinDeclaration_onClause),
        _readNodeLazy(data.classOrMixinDeclaration_implementsClause),
        _Tokens.OPEN_CURLY_BRACKET,
        _readNodeListLazy(data.classOrMixinDeclaration_members),
        _Tokens.CLOSE_CURLY_BRACKET,
      );
      LazyMixinDeclaration(node, data);
      return node;
    } finally {
      timerAstBinaryReaderMixin.stop();
    }
  }

  NamedExpression _read_namedExpression(LinkedNode data) {
    Expression expression = _readNode(data.namedExpression_expression);
    return astFactory.namedExpression(
      _readNode(data.namedExpression_name),
      expression,
    )..staticType = expression.staticType;
  }

  NativeClause _read_nativeClause(LinkedNode data) {
    return astFactory.nativeClause(
      _Tokens.NATIVE,
      _readNode(data.nativeClause_name),
    );
  }

  NativeFunctionBody _read_nativeFunctionBody(LinkedNode data) {
    return astFactory.nativeFunctionBody(
      _Tokens.NATIVE,
      _readNode(data.nativeFunctionBody_stringLiteral),
      _Tokens.SEMICOLON,
    );
  }

  NullLiteral _read_nullLiteral(LinkedNode data) {
    return astFactory.nullLiteral(
      _Tokens.NULL,
    )..staticType = _nullType;
  }

  OnClause _read_onClause(LinkedNode data) {
    return astFactory.onClause(
      _Tokens.ON,
      _readNodeList(data.onClause_superclassConstraints),
    );
  }

  ParenthesizedExpression _read_parenthesizedExpression(LinkedNode data) {
    return astFactory.parenthesizedExpression(
      _Tokens.OPEN_PAREN,
      _readNode(data.parenthesizedExpression_expression),
      _Tokens.CLOSE_PAREN,
    )..staticType = _readType(data.expression_type);
  }

  PartDirective _read_partDirective(LinkedNode data) {
    timerAstBinaryReaderDirective.start();
    _isReadingDirective = true;
    try {
      var node = astFactory.partDirective(
        _readDocumentationComment(data),
        _readNodeListLazy(data.annotatedNode_metadata),
        _Tokens.PART,
        _readNode(data.uriBasedDirective_uri),
        _Tokens.SEMICOLON,
      );
      LazyDirective.setData(node, data);
      return node;
    } finally {
      _isReadingDirective = false;
      timerAstBinaryReaderDirective.stop();
    }
  }

  PartOfDirective _read_partOfDirective(LinkedNode data) {
    timerAstBinaryReaderDirective.start();
    _isReadingDirective = true;
    try {
      var node = astFactory.partOfDirective(
        _readDocumentationComment(data),
        _readNodeListLazy(data.annotatedNode_metadata),
        _Tokens.PART,
        _Tokens.OF,
        _readNode(data.partOfDirective_uri),
        _readNode(data.partOfDirective_libraryName),
        _Tokens.SEMICOLON,
      );
      LazyDirective.setData(node, data);
      return node;
    } finally {
      _isReadingDirective = false;
      timerAstBinaryReaderDirective.stop();
    }
  }

  PostfixExpression _read_postfixExpression(LinkedNode data) {
    return astFactory.postfixExpression(
      _readNode(data.postfixExpression_operand),
      _Tokens.fromType(data.postfixExpression_operator),
    )
      ..staticElement = _elementOfComponents(
        data.postfixExpression_element,
        data.postfixExpression_substitution,
      )
      ..staticType = _readType(data.expression_type);
  }

  PrefixedIdentifier _read_prefixedIdentifier(LinkedNode data) {
    return astFactory.prefixedIdentifier(
      _readNode(data.prefixedIdentifier_prefix),
      _Tokens.PERIOD,
      _readNode(data.prefixedIdentifier_identifier),
    )..staticType = _readType(data.expression_type);
  }

  PrefixExpression _read_prefixExpression(LinkedNode data) {
    return astFactory.prefixExpression(
      _Tokens.fromType(data.prefixExpression_operator),
      _readNode(data.prefixExpression_operand),
    )
      ..staticElement = _elementOfComponents(
        data.prefixExpression_element,
        data.prefixExpression_substitution,
      )
      ..staticType = _readType(data.expression_type);
  }

  PropertyAccess _read_propertyAccess(LinkedNode data) {
    return astFactory.propertyAccess(
      _readNode(data.propertyAccess_target),
      _Tokens.fromType(data.propertyAccess_operator),
      _readNode(data.propertyAccess_propertyName),
    )..staticType = _readType(data.expression_type);
  }

  RedirectingConstructorInvocation _read_redirectingConstructorInvocation(
      LinkedNode data) {
    var hasThis = AstBinaryFlags.hasThis(data.flags);
    return astFactory.redirectingConstructorInvocation(
      hasThis ? _Tokens.THIS : null,
      hasThis ? _Tokens.PERIOD : null,
      _readNode(data.redirectingConstructorInvocation_constructorName),
      _readNode(data.redirectingConstructorInvocation_arguments),
    )..staticElement = _elementOfComponents(
        data.redirectingConstructorInvocation_element,
        data.redirectingConstructorInvocation_substitution,
      );
  }

  RethrowExpression _read_rethrowExpression(LinkedNode data) {
    return astFactory.rethrowExpression(
      _Tokens.RETHROW,
    )..staticType = _readType(data.expression_type);
  }

  ReturnStatement _read_returnStatement(LinkedNode data) {
    return astFactory.returnStatement(
      _Tokens.RETURN,
      _readNode(data.returnStatement_expression),
      _Tokens.SEMICOLON,
    );
  }

  SetOrMapLiteral _read_setOrMapLiteral(LinkedNode data) {
    SetOrMapLiteralImpl node = astFactory.setOrMapLiteral(
      constKeyword: AstBinaryFlags.isConst(data.flags) ? _Tokens.CONST : null,
      elements: _readNodeList(data.setOrMapLiteral_elements),
      leftBracket: _Tokens.OPEN_CURLY_BRACKET,
      typeArguments: AstBinaryFlags.hasTypeArguments(data.flags)
          ? astFactory.typeArgumentList(
              _Tokens.LT,
              _readNodeList(data.typedLiteral_typeArguments),
              _Tokens.GT,
            )
          : null,
      rightBracket: _Tokens.CLOSE_CURLY_BRACKET,
    )..staticType = _readType(data.expression_type);
    if (AstBinaryFlags.isMap(data.flags)) {
      node.becomeMap();
    } else if (AstBinaryFlags.isSet(data.flags)) {
      node.becomeSet();
    }
    return node;
  }

  ShowCombinator _read_showCombinator(LinkedNode data) {
    var node = astFactory.showCombinator(
      _combinatorKeyword(data, Keyword.SHOW, _Tokens.SHOW),
      data.names.map((name) => AstTestFactory.identifier3(name)).toList(),
    );
    LazyCombinator(node, data);
    return node;
  }

  SimpleFormalParameter _read_simpleFormalParameter(LinkedNode data) {
    SimpleFormalParameterImpl node = astFactory.simpleFormalParameter2(
      identifier: _declaredIdentifier(data),
      type: _readNode(data.simpleFormalParameter_type),
      covariantKeyword:
          AstBinaryFlags.isCovariant(data.flags) ? _Tokens.COVARIANT : null,
      comment: _readDocumentationComment(data),
      metadata: _readNodeList(data.normalFormalParameter_metadata),
      keyword: _Tokens.choose(
        AstBinaryFlags.isConst(data.flags),
        _Tokens.CONST,
        AstBinaryFlags.isFinal(data.flags),
        _Tokens.FINAL,
        AstBinaryFlags.isVar(data.flags),
        _Tokens.VAR,
      ),
      requiredKeyword:
          AstBinaryFlags.isRequired(data.flags) ? _Tokens.REQUIRED : null,
    );
    LazyFormalParameter.setData(node, data);
    LazyAst.setInheritsCovariant(node, data.inheritsCovariant);
    return node;
  }

  SimpleIdentifier _read_simpleIdentifier(LinkedNode data) {
    return astFactory.simpleIdentifier(
      TokenFactory.tokenFromString(data.name),
      isDeclaration: AstBinaryFlags.isDeclaration(data.flags),
    )
      ..staticElement = _elementOfComponents(
        data.simpleIdentifier_element,
        data.simpleIdentifier_substitution,
      )
      ..staticType = _readType(data.expression_type);
  }

  SimpleStringLiteral _read_simpleStringLiteral(LinkedNode data) {
    var node = AstTestFactory.string2(data.simpleStringLiteral_value);
    if (!_isReadingDirective) {
      node.staticType = _stringType;
    }
    return node;
  }

  SpreadElement _read_spreadElement(LinkedNode data) {
    return astFactory.spreadElement(
      spreadOperator: _Tokens.fromType(data.spreadElement_spreadOperator),
      expression: _readNode(data.spreadElement_expression),
    );
  }

  StringInterpolation _read_stringInterpolation(LinkedNode data) {
    var node = astFactory.stringInterpolation(
      _readNodeList(data.stringInterpolation_elements),
    );
    if (!_isReadingDirective) {
      node.staticType = _stringType;
    }
    return node;
  }

  SuperConstructorInvocation _read_superConstructorInvocation(LinkedNode data) {
    return astFactory.superConstructorInvocation(
      _Tokens.SUPER,
      _Tokens.PERIOD,
      _readNode(data.superConstructorInvocation_constructorName),
      _readNode(data.superConstructorInvocation_arguments),
    )..staticElement = _elementOfComponents(
        data.superConstructorInvocation_element,
        data.superConstructorInvocation_substitution,
      );
  }

  SuperExpression _read_superExpression(LinkedNode data) {
    return astFactory.superExpression(
      _Tokens.SUPER,
    )..staticType = _readType(data.expression_type);
  }

  SwitchCase _read_switchCase(LinkedNode data) {
    return astFactory.switchCase(
      _readNodeList(data.switchMember_labels),
      _Tokens.CASE,
      _readNode(data.switchCase_expression),
      _Tokens.COLON,
      _readNodeList(data.switchMember_statements),
    );
  }

  SwitchDefault _read_switchDefault(LinkedNode data) {
    return astFactory.switchDefault(
      _readNodeList(data.switchMember_labels),
      _Tokens.DEFAULT,
      _Tokens.COLON,
      _readNodeList(data.switchMember_statements),
    );
  }

  SwitchStatement _read_switchStatement(LinkedNode data) {
    return astFactory.switchStatement(
      _Tokens.SWITCH,
      _Tokens.OPEN_PAREN,
      _readNode(data.switchStatement_expression),
      _Tokens.CLOSE_PAREN,
      _Tokens.OPEN_CURLY_BRACKET,
      _readNodeList(data.switchStatement_members),
      _Tokens.CLOSE_CURLY_BRACKET,
    );
  }

  SymbolLiteral _read_symbolLiteral(LinkedNode data) {
    return astFactory.symbolLiteral(
      _Tokens.HASH,
      data.names.map((lexeme) => TokenFactory.tokenFromString(lexeme)).toList(),
    )..staticType = _readType(data.expression_type);
  }

  ThisExpression _read_thisExpression(LinkedNode data) {
    return astFactory.thisExpression(
      _Tokens.THIS,
    )..staticType = _readType(data.expression_type);
  }

  ThrowExpression _read_throwExpression(LinkedNode data) {
    return astFactory.throwExpression(
      _Tokens.THROW,
      _readNode(data.throwExpression_expression),
    )..staticType = _readType(data.expression_type);
  }

  TopLevelVariableDeclaration _read_topLevelVariableDeclaration(
      LinkedNode data) {
    timerAstBinaryReaderTopLevelVar.start();
    try {
      var node = astFactory.topLevelVariableDeclaration(
        _readDocumentationComment(data),
        _readNodeListLazy(data.annotatedNode_metadata),
        _readNode(data.topLevelVariableDeclaration_variableList),
        _Tokens.SEMICOLON,
      );
      LazyTopLevelVariableDeclaration.setData(node, data);
      return node;
    } finally {
      timerAstBinaryReaderTopLevelVar.stop();
    }
  }

  TryStatement _read_tryStatement(LinkedNode data) {
    return astFactory.tryStatement(
      _Tokens.TRY,
      _readNode(data.tryStatement_body),
      _readNodeList(data.tryStatement_catchClauses),
      _Tokens.FINALLY,
      _readNode(data.tryStatement_finallyBlock),
    );
  }

  TypeArgumentList _read_typeArgumentList(LinkedNode data) {
    return astFactory.typeArgumentList(
      _Tokens.LT,
      _readNodeList(data.typeArgumentList_arguments),
      _Tokens.GT,
    );
  }

  TypeName _read_typeName(LinkedNode data) {
    return astFactory.typeName(
      _readNode(data.typeName_name),
      AstBinaryFlags.hasTypeArguments(data.flags)
          ? astFactory.typeArgumentList(
              _Tokens.LT,
              _readNodeList(data.typeName_typeArguments),
              _Tokens.GT,
            )
          : null,
      question:
          AstBinaryFlags.hasQuestion(data.flags) ? _Tokens.QUESTION : null,
    )..type = _readType(data.typeName_type);
  }

  TypeParameter _read_typeParameter(LinkedNode data) {
    // TODO (kallentu) : Clean up AstFactoryImpl casting once variance is
    // added to the interface.
    var node = (astFactory as AstFactoryImpl).typeParameter2(
        comment: _readDocumentationComment(data),
        metadata: _readNodeListLazy(data.annotatedNode_metadata),
        name: _declaredIdentifier(data),
        extendsKeyword: _Tokens.EXTENDS,
        bound: _readNodeLazy(data.typeParameter_bound),
        varianceKeyword: _varianceKeyword(data));
    LazyTypeParameter.setData(node, data);
    return node;
  }

  TypeParameterList _read_typeParameterList(LinkedNode data) {
    return astFactory.typeParameterList(
      _Tokens.LT,
      _readNodeList(data.typeParameterList_typeParameters),
      _Tokens.GT,
    );
  }

  VariableDeclaration _read_variableDeclaration(LinkedNode data) {
    var node = astFactory.variableDeclaration(
      _declaredIdentifier(data),
      _Tokens.EQ,
      _readNodeLazy(data.variableDeclaration_initializer),
    );
    LazyVariableDeclaration.setData(node, data);
    LazyAst.setInheritsCovariant(node, data.inheritsCovariant);
    return node;
  }

  VariableDeclarationList _read_variableDeclarationList(LinkedNode data) {
    var node = astFactory.variableDeclarationList2(
      comment: _readDocumentationComment(data),
      keyword: _Tokens.choose(
        AstBinaryFlags.isConst(data.flags),
        _Tokens.CONST,
        AstBinaryFlags.isFinal(data.flags),
        _Tokens.FINAL,
        AstBinaryFlags.isVar(data.flags),
        _Tokens.VAR,
      ),
      lateKeyword: AstBinaryFlags.isLate(data.flags) ? _Tokens.LATE : null,
      metadata: _readNodeListLazy(data.annotatedNode_metadata),
      type: _readNodeLazy(data.variableDeclarationList_type),
      variables: _readNodeList(data.variableDeclarationList_variables),
    );
    LazyVariableDeclarationList.setData(node, data);
    return node;
  }

  VariableDeclarationStatement _read_variableDeclarationStatement(
      LinkedNode data) {
    return astFactory.variableDeclarationStatement(
      _readNode(data.variableDeclarationStatement_variables),
      _Tokens.SEMICOLON,
    );
  }

  WhileStatement _read_whileStatement(LinkedNode data) {
    return astFactory.whileStatement(
      _Tokens.WHILE,
      _Tokens.OPEN_PAREN,
      _readNode(data.whileStatement_condition),
      _Tokens.CLOSE_PAREN,
      _readNode(data.whileStatement_body),
    );
  }

  WithClause _read_withClause(LinkedNode data) {
    return astFactory.withClause(
      _Tokens.WITH,
      _readNodeList(data.withClause_mixinTypes),
    );
  }

  YieldStatement _read_yieldStatement(LinkedNode data) {
    return astFactory.yieldStatement(
      _Tokens.YIELD,
      AstBinaryFlags.isStar(data.flags) ? _Tokens.STAR : null,
      _readNode(data.yieldStatement_expression),
      _Tokens.SEMICOLON,
    );
  }

  Comment _readDocumentationComment(LinkedNode data) {
    return null;
  }

  AstNode _readNode(LinkedNode data) {
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
      case LinkedNodeKind.commentReference:
        return _read_commentReference(data);
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
      case LinkedNodeKind.extensionDeclaration:
        return _read_extensionDeclaration(data);
      case LinkedNodeKind.extensionOverride:
        return _read_extensionOverride(data);
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
      case LinkedNodeKind.nativeClause:
        return _read_nativeClause(data);
      case LinkedNodeKind.nativeFunctionBody:
        return _read_nativeFunctionBody(data);
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

  AstNode _readNodeLazy(LinkedNode data) {
    if (isLazy) return null;
    return _readNode(data);
  }

  List<T> _readNodeList<T>(List<LinkedNode> nodeList) {
    var result = List<T>.filled(nodeList.length, null);
    for (var i = 0; i < nodeList.length; ++i) {
      var linkedNode = nodeList[i];
      result[i] = _readNode(linkedNode) as T;
    }
    return result;
  }

  List<T> _readNodeListLazy<T>(List<LinkedNode> nodeList) {
    if (isLazy) {
      return List<T>.filled(nodeList.length, null);
    }
    return _readNodeList(nodeList);
  }

  DartType _readType(LinkedNodeType data) {
    return _unitContext.readType(data);
  }

  Token _varianceKeyword(LinkedNode data) {
    if (data.typeParameter_variance != UnlinkedTokenType.NOTHING) {
      return _Tokens.fromType(data.typeParameter_variance);
    }
    return null;
  }

  static ParameterKind _toParameterKind(LinkedNodeFormalParameterKind kind) {
    switch (kind) {
      case LinkedNodeFormalParameterKind.requiredPositional:
        return ParameterKind.REQUIRED;
      case LinkedNodeFormalParameterKind.requiredNamed:
        return ParameterKind.NAMED_REQUIRED;
        break;
      case LinkedNodeFormalParameterKind.optionalPositional:
        return ParameterKind.POSITIONAL;
        break;
      case LinkedNodeFormalParameterKind.optionalNamed:
        return ParameterKind.NAMED;
      default:
        throw StateError('Unexpected: $kind');
    }
  }
}

class _Tokens {
  static final ABSTRACT = TokenFactory.tokenFromKeyword(Keyword.ABSTRACT);
  static final ARROW = TokenFactory.tokenFromType(TokenType.FUNCTION);
  static final AS = TokenFactory.tokenFromKeyword(Keyword.AS);
  static final ASSERT = TokenFactory.tokenFromKeyword(Keyword.ASSERT);
  static final AT = TokenFactory.tokenFromType(TokenType.AT);
  static final ASYNC = TokenFactory.tokenFromKeyword(Keyword.ASYNC);
  static final AWAIT = TokenFactory.tokenFromKeyword(Keyword.AWAIT);
  static final BANG = TokenFactory.tokenFromType(TokenType.BANG);
  static final BREAK = TokenFactory.tokenFromKeyword(Keyword.BREAK);
  static final CASE = TokenFactory.tokenFromKeyword(Keyword.CASE);
  static final CATCH = TokenFactory.tokenFromKeyword(Keyword.CATCH);
  static final CLASS = TokenFactory.tokenFromKeyword(Keyword.CLASS);
  static final CLOSE_CURLY_BRACKET =
      TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET);
  static final CLOSE_PAREN = TokenFactory.tokenFromType(TokenType.CLOSE_PAREN);
  static final CLOSE_SQUARE_BRACKET =
      TokenFactory.tokenFromType(TokenType.CLOSE_SQUARE_BRACKET);
  static final COLON = TokenFactory.tokenFromType(TokenType.COLON);
  static final COMMA = TokenFactory.tokenFromType(TokenType.COMMA);
  static final CONST = TokenFactory.tokenFromKeyword(Keyword.CONST);
  static final CONTINUE = TokenFactory.tokenFromKeyword(Keyword.CONTINUE);
  static final COVARIANT = TokenFactory.tokenFromKeyword(Keyword.COVARIANT);
  static final DEFERRED = TokenFactory.tokenFromKeyword(Keyword.DEFERRED);
  static final ELSE = TokenFactory.tokenFromKeyword(Keyword.ELSE);
  static final EXTERNAL = TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);
  static final FACTORY = TokenFactory.tokenFromKeyword(Keyword.FACTORY);
  static final DEFAULT = TokenFactory.tokenFromKeyword(Keyword.DEFAULT);
  static final DO = TokenFactory.tokenFromKeyword(Keyword.DO);
  static final ENUM = TokenFactory.tokenFromKeyword(Keyword.ENUM);
  static final EQ = TokenFactory.tokenFromType(TokenType.EQ);
  static final EXPORT = TokenFactory.tokenFromKeyword(Keyword.EXPORT);
  static final EXTENDS = TokenFactory.tokenFromKeyword(Keyword.EXTENDS);
  static final EXTENSION = TokenFactory.tokenFromKeyword(Keyword.EXTENSION);
  static final FINAL = TokenFactory.tokenFromKeyword(Keyword.FINAL);
  static final FINALLY = TokenFactory.tokenFromKeyword(Keyword.FINALLY);
  static final FOR = TokenFactory.tokenFromKeyword(Keyword.FOR);
  static final FUNCTION = TokenFactory.tokenFromKeyword(Keyword.FUNCTION);
  static final GET = TokenFactory.tokenFromKeyword(Keyword.GET);
  static final GT = TokenFactory.tokenFromType(TokenType.GT);
  static final HASH = TokenFactory.tokenFromType(TokenType.HASH);
  static final HIDE = TokenFactory.tokenFromKeyword(Keyword.HIDE);
  static final IF = TokenFactory.tokenFromKeyword(Keyword.IF);
  static final IMPLEMENTS = TokenFactory.tokenFromKeyword(Keyword.IMPORT);
  static final IMPORT = TokenFactory.tokenFromKeyword(Keyword.IMPLEMENTS);
  static final IN = TokenFactory.tokenFromKeyword(Keyword.IN);
  static final IS = TokenFactory.tokenFromKeyword(Keyword.IS);
  static final LATE = TokenFactory.tokenFromKeyword(Keyword.LATE);
  static final LIBRARY = TokenFactory.tokenFromKeyword(Keyword.LIBRARY);
  static final LT = TokenFactory.tokenFromType(TokenType.LT);
  static final MIXIN = TokenFactory.tokenFromKeyword(Keyword.MIXIN);
  static final NATIVE = TokenFactory.tokenFromKeyword(Keyword.NATIVE);
  static final NEW = TokenFactory.tokenFromKeyword(Keyword.NEW);
  static final NULL = TokenFactory.tokenFromKeyword(Keyword.NULL);
  static final OF = TokenFactory.tokenFromKeyword(Keyword.OF);
  static final ON = TokenFactory.tokenFromKeyword(Keyword.ON);
  static final OPEN_CURLY_BRACKET =
      TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET);
  static final OPEN_PAREN = TokenFactory.tokenFromType(TokenType.OPEN_PAREN);
  static final OPEN_SQUARE_BRACKET =
      TokenFactory.tokenFromType(TokenType.OPEN_SQUARE_BRACKET);
  static final OPERATOR = TokenFactory.tokenFromKeyword(Keyword.OPERATOR);
  static final PART = TokenFactory.tokenFromKeyword(Keyword.PART);
  static final PERIOD = TokenFactory.tokenFromType(TokenType.PERIOD);
  static final PERIOD_PERIOD =
      TokenFactory.tokenFromType(TokenType.PERIOD_PERIOD);
  static final QUESTION = TokenFactory.tokenFromType(TokenType.QUESTION);
  static final REQUIRED = TokenFactory.tokenFromKeyword(Keyword.REQUIRED);
  static final RETHROW = TokenFactory.tokenFromKeyword(Keyword.RETHROW);
  static final RETURN = TokenFactory.tokenFromKeyword(Keyword.RETURN);
  static final SEMICOLON = TokenFactory.tokenFromType(TokenType.SEMICOLON);
  static final SET = TokenFactory.tokenFromKeyword(Keyword.SET);
  static final SHOW = TokenFactory.tokenFromKeyword(Keyword.SHOW);
  static final STAR = TokenFactory.tokenFromType(TokenType.STAR);
  static final STATIC = TokenFactory.tokenFromKeyword(Keyword.STATIC);
  static final STRING_INTERPOLATION_EXPRESSION =
      TokenFactory.tokenFromType(TokenType.STRING_INTERPOLATION_EXPRESSION);
  static final SUPER = TokenFactory.tokenFromKeyword(Keyword.SUPER);
  static final SWITCH = TokenFactory.tokenFromKeyword(Keyword.SWITCH);
  static final SYNC = TokenFactory.tokenFromKeyword(Keyword.SYNC);
  static final THIS = TokenFactory.tokenFromKeyword(Keyword.THIS);
  static final THROW = TokenFactory.tokenFromKeyword(Keyword.THROW);
  static final TRY = TokenFactory.tokenFromKeyword(Keyword.TRY);
  static final TYPEDEF = TokenFactory.tokenFromKeyword(Keyword.TYPEDEF);
  static final VAR = TokenFactory.tokenFromKeyword(Keyword.VAR);
  static final WITH = TokenFactory.tokenFromKeyword(Keyword.WITH);
  static final WHILE = TokenFactory.tokenFromKeyword(Keyword.WHILE);
  static final YIELD = TokenFactory.tokenFromKeyword(Keyword.YIELD);

  static Token choose(bool if1, Token then1, bool if2, Token then2,
      [bool if3, Token then3]) {
    if (if1) return then1;
    if (if2) return then2;
    if (if2 == true) return then3;
    return null;
  }

  static Token fromType(UnlinkedTokenType type) {
    return TokenFactory.tokenFromType(
      TokensContext.binaryToAstTokenType(type),
    );
  }
}
