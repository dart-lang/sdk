// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/ast_binary_flags.dart';
import 'package:analyzer/src/summary2/ast_binary_tag.dart';
import 'package:analyzer/src/summary2/ast_binary_tokens.dart';
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/unlinked_token_type.dart';
import 'package:meta/meta.dart';

/// Deserializer of ASTs.
class AstBinaryReader {
  static final _noDocumentationComment = Uint32List(0);

  final UnitReader _unitReader;
  final bool _withInformative;

  AstBinaryReader({
    @required UnitReader reader,
  })  : _unitReader = reader,
        _withInformative = reader.withInformative;

  AstNode readNode() {
    var tag = _readByte();
    switch (tag) {
      case Tag.AdjacentStrings:
        return _readAdjacentStrings();
      case Tag.Annotation:
        return _readAnnotation();
      case Tag.ArgumentList:
        return _readArgumentList();
      case Tag.AsExpression:
        return _readAsExpression();
      case Tag.AssertInitializer:
        return _readAssertInitializer();
      case Tag.AssignmentExpression:
        return _readAssignmentExpression();
      case Tag.BinaryExpression:
        return _readBinaryExpression();
      case Tag.BooleanLiteral:
        return _readBooleanLiteral();
      case Tag.CascadeExpression:
        return _readCascadeExpression();
      case Tag.Class:
        return _readClassDeclaration();
      case Tag.ClassTypeAlias:
        return _readClassTypeAlias();
      case Tag.ConditionalExpression:
        return _readConditionalExpression();
      case Tag.Configuration:
        return _readConfiguration();
      case Tag.ConstructorDeclaration:
        return _readConstructorDeclaration();
      case Tag.ConstructorFieldInitializer:
        return _readConstructorFieldInitializer();
      case Tag.ConstructorName:
        return _readConstructorName();
      case Tag.DeclaredIdentifier:
        return _readDeclaredIdentifier();
      case Tag.DefaultFormalParameter:
        return _readDefaultFormalParameter();
      case Tag.DottedName:
        return _readDottedName();
      case Tag.DoubleLiteral:
        return _readDoubleLiteral();
      case Tag.EnumConstantDeclaration:
        return _readEnumConstantDeclaration();
      case Tag.EnumDeclaration:
        return _readEnumDeclaration();
      case Tag.ExportDirective:
        return _readExportDirective();
      case Tag.ExtendsClause:
        return _readExtendsClause();
      case Tag.ExtensionDeclaration:
        return _readExtensionDeclaration();
      case Tag.ExtensionOverride:
        return _readExtensionOverride();
      case Tag.FieldDeclaration:
        return _readFieldDeclaration();
      case Tag.ForEachPartsWithDeclaration:
        return _readForEachPartsWithDeclaration();
      case Tag.ForElement:
        return _readForElement();
      case Tag.ForPartsWithDeclarations:
        return _readForPartsWithDeclarations();
      case Tag.FieldFormalParameter:
        return _readFieldFormalParameter();
      case Tag.FormalParameterList:
        return _readFormalParameterList();
      case Tag.FunctionDeclaration:
        return _readFunctionDeclaration();
      case Tag.FunctionExpression:
        return _readFunctionExpression();
      case Tag.FunctionExpressionInvocation:
        return _readFunctionExpressionInvocation();
      case Tag.FunctionTypeAlias:
        return _readFunctionTypeAlias();
      case Tag.FunctionTypedFormalParameter:
        return _readFunctionTypedFormalParameter();
      case Tag.GenericFunctionType:
        return _readGenericFunctionType();
      case Tag.GenericTypeAlias:
        return _readGenericTypeAlias();
      case Tag.HideCombinator:
        return _readHideCombinator();
      case Tag.IfElement:
        return _readIfElement();
      case Tag.ImplementsClause:
        return _readImplementsClause();
      case Tag.IndexExpression:
        return _readIndexExpression();
      case Tag.IntegerLiteralNegative1:
        return _readIntegerLiteralNegative1();
      case Tag.IntegerLiteralNull:
        return _readIntegerLiteralNull();
      case Tag.IntegerLiteralPositive1:
        return _readIntegerLiteralPositive1();
      case Tag.IntegerLiteralPositive:
        return _readIntegerLiteralPositive();
      case Tag.IntegerLiteralNegative:
        return _readIntegerLiteralNegative();
      case Tag.InterpolationExpression:
        return _readInterpolationExpression();
      case Tag.InterpolationString:
        return _readInterpolationString();
      case Tag.IsExpression:
        return _readIsExpression();
      case Tag.LibraryDirective:
        return _readLibraryDirective();
      case Tag.LibraryIdentifier:
        return _readLibraryIdentifier();
      case Tag.ListLiteral:
        return _readListLiteral();
      case Tag.MapLiteralEntry:
        return _readMapLiteralEntry();
      case Tag.MethodDeclaration:
        return _readMethodDeclaration();
      case Tag.MixinDeclaration:
        return _readMixinDeclaration();
      case Tag.MethodInvocation:
        return _readMethodInvocation();
      case Tag.NamedExpression:
        return _readNamedExpression();
      case Tag.NativeClause:
        return _readNativeClause();
      case Tag.NullLiteral:
        return _readNullLiteral();
      case Tag.OnClause:
        return _readOnClause();
      case Tag.ImportDirective:
        return _readImportDirective();
      case Tag.InstanceCreationExpression:
        return _readInstanceCreationExpression();
      case Tag.ParenthesizedExpression:
        return _readParenthesizedExpression();
      case Tag.PartDirective:
        return _readPartDirective();
      case Tag.PartOfDirective:
        return _readPartOfDirective();
      case Tag.PostfixExpression:
        return _readPostfixExpression();
      case Tag.PrefixExpression:
        return _readPrefixExpression();
      case Tag.PrefixedIdentifier:
        return _readPrefixedIdentifier();
      case Tag.PropertyAccess:
        return _readPropertyAccess();
      case Tag.RedirectingConstructorInvocation:
        return _readRedirectingConstructorInvocation();
      case Tag.SetOrMapLiteral:
        return _readSetOrMapLiteral();
      case Tag.ShowCombinator:
        return _readShowCombinator();
      case Tag.SimpleFormalParameter:
        return _readSimpleFormalParameter();
      case Tag.SimpleIdentifier:
        return _readSimpleIdentifier();
      case Tag.SimpleStringLiteral:
        return _readSimpleStringLiteral();
      case Tag.SpreadElement:
        return _readSpreadElement();
      case Tag.StringInterpolation:
        return _readStringInterpolation();
      case Tag.SuperConstructorInvocation:
        return _readSuperConstructorInvocation();
      case Tag.SuperExpression:
        return _readSuperExpression();
      case Tag.SymbolLiteral:
        return _readSymbolLiteral();
      case Tag.ThisExpression:
        return _readThisExpression();
      case Tag.ThrowExpression:
        return _readThrowExpression();
      case Tag.TypeArgumentList:
        return _readTypeArgumentList();
      case Tag.TypeName:
        return _readTypeName();
      case Tag.TypeParameter:
        return _readTypeParameter();
      case Tag.TypeParameterList:
        return _readTypeParameterList();
      case Tag.TopLevelVariableDeclaration:
        return _readTopLevelVariableDeclaration();
      case Tag.VariableDeclaration:
        return _readVariableDeclaration();
      case Tag.VariableDeclarationList:
        return _readVariableDeclarationList();
      case Tag.WithClause:
        return _readWithClause();
      default:
        throw UnimplementedError('Unexpected tag: $tag');
    }
  }

  IntegerLiteral _createIntegerLiteral(int value) {
    // TODO(scheglov) Write token?
    return astFactory.integerLiteral(
      TokenFactory.tokenFromTypeAndString(TokenType.INT, '$value'),
      value,
    );
  }

  FunctionBody _functionBodyForFlags(int flags) {
    if (AstBinaryFlags.isNative(flags)) {
      return AstTestFactory.nativeFunctionBody('');
    } else if (AstBinaryFlags.isAbstract(flags)) {
      return AstTestFactory.emptyFunctionBody();
    } else {
      return astFactory.blockFunctionBody(
        AstBinaryFlags.isAsync(flags) ? Tokens.ASYNC : null,
        AstBinaryFlags.isGenerator(flags) ? Tokens.STAR : null,
        astFactory.block(
          Tokens.OPEN_CURLY_BRACKET,
          const <Statement>[],
          Tokens.CLOSE_CURLY_BRACKET,
        ),
      );
    }
  }

  AdjacentStrings _readAdjacentStrings() {
    var components = _readNodeList<StringLiteral>();
    return astFactory.adjacentStrings(components);
  }

  Annotation _readAnnotation() {
    var name = _readOptionalNode() as Identifier;
    var constructorName = _readOptionalNode() as SimpleIdentifier;
    var arguments = _readOptionalNode() as ArgumentList;
    return astFactory.annotation(
      Tokens.AT,
      name,
      Tokens.PERIOD,
      constructorName,
      arguments,
    );
  }

  ArgumentList _readArgumentList() {
    var arguments = _readNodeList<Expression>();

    return astFactory.argumentList(
      Tokens.OPEN_PAREN,
      arguments,
      Tokens.CLOSE_PAREN,
    );
  }

  AsExpression _readAsExpression() {
    var expression = readNode() as Expression;
    var type = readNode() as TypeAnnotation;
    return astFactory.asExpression(expression, Tokens.AS, type);
  }

  AssertInitializer _readAssertInitializer() {
    var condition = readNode() as Expression;
    var message = _readOptionalNode() as Expression;
    return astFactory.assertInitializer(
      Tokens.ASSERT,
      Tokens.OPEN_PAREN,
      condition,
      Tokens.COMMA,
      message,
      Tokens.CLOSE_PAREN,
    );
  }

  AssignmentExpression _readAssignmentExpression() {
    var leftHandSide = readNode() as Expression;
    var rightHandSide = readNode() as Expression;
    var operatorType = UnlinkedTokenType.values[_readByte()];
    return astFactory.assignmentExpression(
      leftHandSide,
      Tokens.fromType(operatorType),
      rightHandSide,
    );
  }

  BinaryExpression _readBinaryExpression() {
    var leftOperand = readNode() as Expression;
    var rightOperand = readNode() as Expression;
    var operatorType = UnlinkedTokenType.values[_readByte()];
    return astFactory.binaryExpression(
      leftOperand,
      Tokens.fromType(operatorType),
      rightOperand,
    );
  }

  BooleanLiteral _readBooleanLiteral() {
    var value = _readByte() == 1;
    // TODO(scheglov) type?
    return AstTestFactory.booleanLiteral(value);
  }

  int _readByte() {
    return _unitReader.astReader.readByte();
  }

  CascadeExpression _readCascadeExpression() {
    var target = readNode() as Expression;
    var sections = _readNodeList<Expression>();
    return astFactory.cascadeExpression(target, sections);
  }

  ClassDeclaration _readClassDeclaration() {
    var flags = _readByte();

    var codeOffset = _readInformativeUint30();
    var codeLength = _readInformativeUint30();
    var documentationTokenIndexList = _readUint30List();

    var typeParameters = _readOptionalNode() as TypeParameterList;
    var extendsClause = _readOptionalNode() as ExtendsClause;
    var withClause = _readOptionalNode() as WithClause;
    var implementsClause = _readOptionalNode() as ImplementsClause;
    var nativeClause = _readOptionalNode() as NativeClause;
    var name = readNode() as SimpleIdentifier;
    var metadata = _readNodeList<Annotation>();

    var node = astFactory.classDeclaration(
      null,
      metadata,
      AstBinaryFlags.isAbstract(flags) ? Tokens.ABSTRACT : null,
      Tokens.CLASS,
      name,
      typeParameters,
      extendsClause,
      withClause,
      implementsClause,
      Tokens.OPEN_CURLY_BRACKET,
      const <ClassMember>[],
      Tokens.CLOSE_CURLY_BRACKET,
    ) as ClassDeclarationImpl;
    node.nativeClause = nativeClause;

    node.linkedContext = LinkedContext(
      _unitReader,
      node,
      codeOffset: codeOffset,
      codeLength: codeLength,
      isClassWithConstConstructor: AstBinaryFlags.hasConstConstructor(flags),
      resolutionIndex: _readUInt30(),
      documentationTokenIndexList: documentationTokenIndexList,
    );

    return node;
  }

  ClassTypeAlias _readClassTypeAlias() {
    var flags = _readByte();

    var codeOffset = _readInformativeUint30();
    var codeLength = _readInformativeUint30();

    var typeParameters = _readOptionalNode() as TypeParameterList;
    var superClass = readNode() as TypeName;
    var withClause = readNode() as WithClause;
    var implementsClause = _readOptionalNode() as ImplementsClause;
    var name = readNode() as SimpleIdentifier;
    var metadata = _readNodeList<Annotation>();
    var documentationTokenIndexList = _readUint30List();

    var node = astFactory.classTypeAlias(
      null,
      metadata,
      Tokens.CLASS,
      name,
      typeParameters,
      Tokens.EQ,
      AstBinaryFlags.isAbstract(flags) ? Tokens.ABSTRACT : null,
      superClass,
      withClause,
      implementsClause,
      Tokens.SEMICOLON,
    ) as ClassTypeAliasImpl;

    node.linkedContext = LinkedContext(
      _unitReader,
      node,
      codeOffset: codeOffset,
      codeLength: codeLength,
      resolutionIndex: _readUInt30(),
      documentationTokenIndexList: documentationTokenIndexList,
    );

    return node;
  }

  ConditionalExpression _readConditionalExpression() {
    var condition = readNode() as Expression;
    var thenExpression = readNode() as Expression;
    var elseExpression = readNode() as Expression;
    return astFactory.conditionalExpression(
      condition,
      Tokens.QUESTION,
      thenExpression,
      Tokens.COLON,
      elseExpression,
    );
  }

  Configuration _readConfiguration() {
    var flags = _readByte();
    var name = readNode() as DottedName;
    var value = _readOptionalNode() as StringLiteral;
    var uri = readNode() as StringLiteral;
    return astFactory.configuration(
      Tokens.IF,
      Tokens.OPEN_PAREN,
      name,
      AstBinaryFlags.hasEqual(flags) ? Tokens.EQ : null,
      value,
      Tokens.CLOSE_PAREN,
      uri,
    );
  }

  ConstructorDeclaration _readConstructorDeclaration() {
    var flags = _readByte();

    var codeOffset = _readInformativeUint30();
    var codeLength = _readInformativeUint30();
    var documentationTokenIndexList = _readUint30List();

    var returnType = readNode() as SimpleIdentifier;

    Token period;
    SimpleIdentifier name;
    if (AstBinaryFlags.hasName(flags)) {
      var periodOffset = _readInformativeUint30();
      period = Token(TokenType.PERIOD, periodOffset);
      name = readNode() as SimpleIdentifier;
    }

    var parameters = readNode() as FormalParameterList;
    var initializers = _readNodeList<ConstructorInitializer>();
    var redirectedConstructor = _readOptionalNode() as ConstructorName;
    var metadata = _readNodeList<Annotation>();

    var node = astFactory.constructorDeclaration(
      null,
      metadata,
      AstBinaryFlags.isExternal(flags) ? Tokens.EXTERNAL : null,
      AstBinaryFlags.isConst(flags) ? Tokens.CONST : null,
      AstBinaryFlags.isFactory(flags) ? Tokens.FACTORY : null,
      returnType,
      period,
      name,
      parameters,
      Tokens.choose(
        AstBinaryFlags.hasSeparatorColon(flags),
        Tokens.COLON,
        AstBinaryFlags.hasSeparatorEquals(flags),
        Tokens.EQ,
      ),
      initializers,
      redirectedConstructor,
      null,
    ) as ConstructorDeclarationImpl;

    node.linkedContext = LinkedContext(
      _unitReader,
      node,
      codeOffset: codeOffset,
      codeLength: codeLength,
      resolutionIndex: _readUInt30(),
      documentationTokenIndexList: documentationTokenIndexList,
    );

    return node;
  }

  ConstructorFieldInitializer _readConstructorFieldInitializer() {
    var flags = _readByte();
    var fieldName = readNode() as SimpleIdentifier;
    var expression = readNode() as Expression;
    var hasThis = AstBinaryFlags.hasThis(flags);
    return astFactory.constructorFieldInitializer(
      hasThis ? Tokens.THIS : null,
      hasThis ? Tokens.PERIOD : null,
      fieldName,
      Tokens.EQ,
      expression,
    );
  }

  ConstructorName _readConstructorName() {
    var type = readNode() as TypeName;
    var name = _readOptionalNode() as SimpleIdentifier;

    return astFactory.constructorName(
      type,
      name != null ? Tokens.PERIOD : null,
      name,
    );
  }

  DeclaredIdentifier _readDeclaredIdentifier() {
    var flags = _readByte();
    var type = _readOptionalNode() as TypeAnnotation;
    var identifier = readNode() as SimpleIdentifier;
    var metadata = _readNodeList<Annotation>();
    return astFactory.declaredIdentifier(
      null,
      metadata,
      Tokens.choose(
        AstBinaryFlags.isConst(flags),
        Tokens.CONST,
        AstBinaryFlags.isFinal(flags),
        Tokens.FINAL,
        AstBinaryFlags.isVar(flags),
        Tokens.VAR,
      ),
      type,
      identifier,
    );
  }

  DefaultFormalParameter _readDefaultFormalParameter() {
    var flags = _readByte();
    var codeOffset = _readInformativeUint30();
    var codeLength = _readInformativeUint30();
    var parameter = readNode() as NormalFormalParameter;
    var defaultValue = _readOptionalNode() as Expression;

    ParameterKind kind;
    if (AstBinaryFlags.isPositional(flags)) {
      kind = AstBinaryFlags.isRequired(flags)
          ? ParameterKind.REQUIRED
          : ParameterKind.POSITIONAL;
    } else {
      kind = AstBinaryFlags.isRequired(flags)
          ? ParameterKind.NAMED_REQUIRED
          : ParameterKind.NAMED;
    }

    var node = astFactory.defaultFormalParameter(
      parameter,
      kind,
      AstBinaryFlags.hasInitializer(flags) ? Tokens.COLON : null,
      defaultValue,
    ) as DefaultFormalParameterImpl;
    node.summaryData = SummaryDataForFormalParameter(
      codeOffset: codeOffset,
      codeLength: codeLength,
    );

    return node;
  }

  DottedName _readDottedName() {
    var components = _readNodeList<SimpleIdentifier>();
    return astFactory.dottedName(components);
  }

  DoubleLiteral _readDoubleLiteral() {
    var value = _unitReader.astReader.readDouble();
    return AstTestFactory.doubleLiteral(value);
  }

  EnumConstantDeclaration _readEnumConstantDeclaration() {
    var codeOffset = _readInformativeUint30();
    var codeLength = _readInformativeUint30();
    var documentationTokenIndexList = _readUint30List();

    var name = readNode() as SimpleIdentifier;
    var metadata = _readNodeList<Annotation>();

    var node = astFactory.enumConstantDeclaration(null, metadata, name)
        as EnumConstantDeclarationImpl;

    node.linkedContext = LinkedContext(
      _unitReader,
      node,
      codeOffset: codeOffset,
      codeLength: codeLength,
      resolutionIndex: -1,
      documentationTokenIndexList: documentationTokenIndexList,
    );

    return node;
  }

  EnumDeclaration _readEnumDeclaration() {
    var codeOffset = _readInformativeUint30();
    var codeLength = _readInformativeUint30();
    var documentationTokenIndexList = _readUint30List();

    var constants = _readNodeList<EnumConstantDeclaration>();
    var name = readNode() as SimpleIdentifier;
    var metadata = _readNodeList<Annotation>();

    var node = astFactory.enumDeclaration(
      null,
      metadata,
      Tokens.ENUM,
      name,
      Tokens.OPEN_CURLY_BRACKET,
      constants,
      Tokens.CLOSE_CURLY_BRACKET,
    ) as EnumDeclarationImpl;

    node.linkedContext = LinkedContext(
      _unitReader,
      node,
      codeOffset: codeOffset,
      codeLength: codeLength,
      resolutionIndex: _readUInt30(),
      documentationTokenIndexList: documentationTokenIndexList,
    );

    return node;
  }

  ExportDirective _readExportDirective() {
    var combinators = _readNodeList<Combinator>();
    var configurations = _readNodeList<Configuration>();
    var uri = readNode();
    var keywordOffset = _readInformativeUint30();
    var metadata = _readNodeList<Annotation>();

    var node = astFactory.exportDirective(
      null,
      metadata,
      KeywordToken(Keyword.EXPORT, keywordOffset),
      uri,
      configurations,
      combinators,
      Tokens.SEMICOLON,
    ) as ExportDirectiveImpl;

    node.linkedContext = LinkedContext(
      _unitReader,
      node,
      codeOffset: -1,
      codeLength: 0,
      documentationTokenIndexList: _noDocumentationComment,
      resolutionIndex: _readUInt30(),
    );

    return node;
  }

  ExtendsClause _readExtendsClause() {
    var type = readNode() as TypeName;
    return astFactory.extendsClause(Tokens.EXTENDS, type);
  }

  ExtensionDeclaration _readExtensionDeclaration() {
    var codeOffset = _readInformativeUint30();
    var codeLength = _readInformativeUint30();
    var documentationTokenIndexList = _readUint30List();

    var typeParameters = _readOptionalNode() as TypeParameterList;
    var extendedType = readNode() as TypeAnnotation;
    var name = _readOptionalNode() as SimpleIdentifier;
    var metadata = _readNodeList<Annotation>();

    var node = astFactory.extensionDeclaration(
      comment: null,
      metadata: metadata,
      extensionKeyword: Tokens.EXTENSION,
      name: name,
      typeParameters: typeParameters,
      onKeyword: Tokens.ON,
      extendedType: extendedType,
      leftBracket: Tokens.OPEN_CURLY_BRACKET,
      members: const <ClassMember>[],
      rightBracket: Tokens.CLOSE_CURLY_BRACKET,
    ) as ExtensionDeclarationImpl;

    node.linkedContext = LinkedContext(
      _unitReader,
      node,
      codeOffset: codeOffset,
      codeLength: codeLength,
      resolutionIndex: _readUInt30(),
      documentationTokenIndexList: documentationTokenIndexList,
    );

    return node;
  }

  ExtensionOverride _readExtensionOverride() {
    var extensionName = readNode() as Identifier;
    var typeArguments = _readOptionalNode() as TypeArgumentList;
    var argumentList = readNode() as ArgumentList;
    return astFactory.extensionOverride(
      extensionName: extensionName,
      argumentList: argumentList,
      typeArguments: typeArguments,
    );
  }

  FieldDeclaration _readFieldDeclaration() {
    var flags = _readByte();
    var codeOffsetLengthList = _readInformativeUint30List();
    var documentationTokenIndexList = _readUint30List();
    var fields = readNode() as VariableDeclarationList;
    var metadata = _readNodeList<Annotation>();

    var node = astFactory.fieldDeclaration2(
      comment: null,
      abstractKeyword:
          AstBinaryFlags.isAbstract(flags) ? Tokens.ABSTRACT : null,
      covariantKeyword:
          AstBinaryFlags.isCovariant(flags) ? Tokens.COVARIANT : null,
      externalKeyword:
          AstBinaryFlags.isExternal(flags) ? Tokens.EXTERNAL : null,
      fieldList: fields,
      metadata: metadata,
      semicolon: Tokens.SEMICOLON,
      staticKeyword: AstBinaryFlags.isStatic(flags) ? Tokens.STATIC : null,
    ) as FieldDeclarationImpl;

    node.linkedContext = LinkedContext(
      _unitReader,
      node,
      codeOffset: -1,
      codeLength: 0,
      codeOffsetLengthList: codeOffsetLengthList,
      resolutionIndex: _readUInt30(),
      documentationTokenIndexList: documentationTokenIndexList,
    );

    return node;
  }

  FieldFormalParameter _readFieldFormalParameter() {
    var typeParameters = _readOptionalNode() as TypeParameterList;
    var type = _readOptionalNode() as TypeAnnotation;
    var formalParameters = _readOptionalNode() as FormalParameterList;
    var flags = _readByte();
    var codeOffset = _readInformativeUint30();
    var codeLength = _readInformativeUint30();
    var metadata = _readNodeList<Annotation>();
    var identifier = readNode() as SimpleIdentifier;
    var node = astFactory.fieldFormalParameter2(
      identifier: identifier,
      period: Tokens.PERIOD,
      thisKeyword: Tokens.THIS,
      covariantKeyword:
          AstBinaryFlags.isCovariant(flags) ? Tokens.COVARIANT : null,
      typeParameters: typeParameters,
      keyword: Tokens.choose(
        AstBinaryFlags.isConst(flags),
        Tokens.CONST,
        AstBinaryFlags.isFinal(flags),
        Tokens.FINAL,
        AstBinaryFlags.isVar(flags),
        Tokens.VAR,
      ),
      metadata: metadata,
      comment: null,
      type: type,
      parameters: formalParameters,
      question: AstBinaryFlags.hasQuestion(flags) ? Tokens.QUESTION : null,
      requiredKeyword:
          AstBinaryFlags.isRequired(flags) ? Tokens.REQUIRED : null,
    ) as FieldFormalParameterImpl;
    node.summaryData = SummaryDataForFormalParameter(
      codeOffset: codeOffset,
      codeLength: codeLength,
    );
    return node;
  }

  ForEachPartsWithDeclaration _readForEachPartsWithDeclaration() {
    var loopVariable = readNode() as DeclaredIdentifier;
    var iterable = readNode() as Expression;
    return astFactory.forEachPartsWithDeclaration(
      inKeyword: Tokens.IN,
      iterable: iterable,
      loopVariable: loopVariable,
    );
  }

  ForElement _readForElement() {
    var body = readNode() as CollectionElement;
    var flags = _readByte();
    var forLoopParts = readNode() as ForLoopParts;
    return astFactory.forElement(
      awaitKeyword: AstBinaryFlags.hasAwait(flags) ? Tokens.AWAIT : null,
      body: body,
      forKeyword: Tokens.FOR,
      forLoopParts: forLoopParts,
      leftParenthesis: Tokens.OPEN_PAREN,
      rightParenthesis: Tokens.CLOSE_PAREN,
    );
  }

  FormalParameterList _readFormalParameterList() {
    var flags = _readByte();
    var parameters = _readNodeList<FormalParameter>();

    return astFactory.formalParameterList(
      Tokens.OPEN_PAREN,
      parameters,
      Tokens.choose(
        AstBinaryFlags.isDelimiterCurly(flags),
        Tokens.OPEN_CURLY_BRACKET,
        AstBinaryFlags.isDelimiterSquare(flags),
        Tokens.OPEN_SQUARE_BRACKET,
      ),
      Tokens.choose(
        AstBinaryFlags.isDelimiterCurly(flags),
        Tokens.CLOSE_CURLY_BRACKET,
        AstBinaryFlags.isDelimiterSquare(flags),
        Tokens.CLOSE_SQUARE_BRACKET,
      ),
      Tokens.CLOSE_PAREN,
    );
  }

  ForPartsWithDeclarations _readForPartsWithDeclarations() {
    var variables = readNode() as VariableDeclarationList;
    var condition = _readOptionalNode() as Expression;
    var updaters = _readNodeList<Expression>();
    return astFactory.forPartsWithDeclarations(
      condition: condition,
      leftSeparator: Tokens.SEMICOLON,
      rightSeparator: Tokens.SEMICOLON,
      updaters: updaters,
      variables: variables,
    );
  }

  FunctionDeclaration _readFunctionDeclaration() {
    var flags = _readByte();
    var codeOffset = _readInformativeUint30();
    var codeLength = _readInformativeUint30();
    var documentationTokenIndexList = _readUint30List();
    var functionExpression = readNode() as FunctionExpression;
    var returnType = _readOptionalNode() as TypeAnnotation;
    var name = readNode() as SimpleIdentifier;
    var metadata = _readNodeList<Annotation>();

    var node = astFactory.functionDeclaration(
      null,
      metadata,
      AstBinaryFlags.isExternal(flags) ? Tokens.EXTERNAL : null,
      returnType,
      Tokens.choose(
        AstBinaryFlags.isGet(flags),
        Tokens.GET,
        AstBinaryFlags.isSet(flags),
        Tokens.SET,
      ),
      name,
      functionExpression,
    ) as FunctionDeclarationImpl;

    node.linkedContext = LinkedContext(
      _unitReader,
      node,
      codeOffset: codeOffset,
      codeLength: codeLength,
      resolutionIndex: _readUInt30(),
      documentationTokenIndexList: documentationTokenIndexList,
    );

    return node;
  }

  FunctionExpression _readFunctionExpression() {
    var flags = _readByte();
    var typeParameters = _readOptionalNode() as TypeParameterList;
    var formalParameters = _readOptionalNode() as FormalParameterList;
    var body = _functionBodyForFlags(flags);

    return astFactory.functionExpression(
      typeParameters,
      formalParameters,
      body,
    );
  }

  FunctionExpressionInvocation _readFunctionExpressionInvocation() {
    var function = readNode() as Expression;
    var typeArguments = _readOptionalNode() as TypeArgumentList;
    var arguments = readNode() as ArgumentList;
    return astFactory.functionExpressionInvocation(
      function,
      typeArguments,
      arguments,
    );
  }

  FunctionTypeAlias _readFunctionTypeAlias() {
    var codeOffset = _readInformativeUint30();
    var codeLength = _readInformativeUint30();
    var documentationTokenIndexList = _readUint30List();

    var typeParameters = _readOptionalNode() as TypeParameterList;
    var returnType = _readOptionalNode() as TypeAnnotation;
    var formalParameters = readNode() as FormalParameterList;
    var name = readNode() as SimpleIdentifier;
    var metadata = _readNodeList<Annotation>();

    var node = astFactory.functionTypeAlias(
      null,
      metadata,
      Tokens.TYPEDEF,
      returnType,
      name,
      typeParameters,
      formalParameters,
      Tokens.SEMICOLON,
    ) as FunctionTypeAliasImpl;

    node.linkedContext = LinkedContext(
      _unitReader,
      node,
      codeOffset: codeOffset,
      codeLength: codeLength,
      resolutionIndex: _readUInt30(),
      documentationTokenIndexList: documentationTokenIndexList,
    );

    return node;
  }

  FunctionTypedFormalParameter _readFunctionTypedFormalParameter() {
    var typeParameters = _readOptionalNode() as TypeParameterList;
    var returnType = _readOptionalNode() as TypeAnnotation;
    var formalParameters = readNode() as FormalParameterList;
    var flags = _readByte();
    var codeOffset = _readInformativeUint30();
    var codeLength = _readInformativeUint30();
    var metadata = _readNodeList<Annotation>();
    var identifier = readNode() as SimpleIdentifier;
    var node = astFactory.functionTypedFormalParameter2(
      comment: null,
      covariantKeyword:
          AstBinaryFlags.isCovariant(flags) ? Tokens.COVARIANT : null,
      identifier: identifier,
      metadata: metadata,
      parameters: formalParameters,
      requiredKeyword:
          AstBinaryFlags.isRequired(flags) ? Tokens.REQUIRED : null,
      returnType: returnType,
      typeParameters: typeParameters,
    ) as FunctionTypedFormalParameterImpl;
    node.summaryData = SummaryDataForFormalParameter(
      codeOffset: codeOffset,
      codeLength: codeLength,
    );
    return node;
  }

  GenericFunctionType _readGenericFunctionType() {
    var flags = _readByte();
    var typeParameters = _readOptionalNode() as TypeParameterList;
    var returnType = _readOptionalNode() as TypeAnnotation;
    var formalParameters = readNode() as FormalParameterList;

    return astFactory.genericFunctionType(
      returnType,
      Tokens.FUNCTION,
      typeParameters,
      formalParameters,
      question: AstBinaryFlags.hasQuestion(flags) ? Tokens.QUESTION : null,
    );
  }

  GenericTypeAlias _readGenericTypeAlias() {
    var codeOffset = _readInformativeUint30();
    var codeLength = _readInformativeUint30();
    var documentationTokenIndexList = _readUint30List();

    var typeParameters = _readOptionalNode() as TypeParameterList;
    var type = _readOptionalNode();
    var name = readNode() as SimpleIdentifier;
    var metadata = _readNodeList<Annotation>();

    var node = astFactory.genericTypeAlias(
      null,
      metadata,
      Tokens.TYPEDEF,
      name,
      typeParameters,
      Tokens.EQ,
      type,
      Tokens.SEMICOLON,
    ) as GenericTypeAliasImpl;

    node.linkedContext = LinkedContext(
      _unitReader,
      node,
      codeOffset: codeOffset,
      codeLength: codeLength,
      resolutionIndex: _readUInt30(),
      documentationTokenIndexList: documentationTokenIndexList,
    );

    return node;
  }

  HideCombinator _readHideCombinator() {
    var keywordOffset = _readInformativeUint30();
    return astFactory.hideCombinator(
      KeywordToken(Keyword.HIDE, keywordOffset),
      _readNodeList<SimpleIdentifier>(),
    );
  }

  IfElement _readIfElement() {
    var condition = readNode() as Expression;
    var thenElement = readNode() as CollectionElement;
    var elseElement = _readOptionalNode() as CollectionElement;
    return astFactory.ifElement(
      condition: condition,
      elseElement: elseElement,
      elseKeyword: elseElement != null ? Tokens.ELSE : null,
      ifKeyword: Tokens.IF,
      leftParenthesis: Tokens.OPEN_PAREN,
      rightParenthesis: Tokens.CLOSE_PAREN,
      thenElement: thenElement,
    );
  }

  ImplementsClause _readImplementsClause() {
    var interfaces = _readNodeList<TypeName>();
    return astFactory.implementsClause(Tokens.IMPLEMENTS, interfaces);
  }

  ImportDirective _readImportDirective() {
    var flags = _readByte();

    SimpleIdentifier prefixIdentifier;
    if (AstBinaryFlags.hasPrefix(flags)) {
      var prefixName = _readStringReference();
      var prefixOffset = _readInformativeUint30();
      prefixIdentifier = astFactory.simpleIdentifier(
        StringToken(TokenType.STRING, prefixName, prefixOffset),
      );
    }

    var combinators = _readNodeList<Combinator>();
    var configurations = _readNodeList<Configuration>();
    var uri = readNode();
    var keywordOffset = _readInformativeUint30();
    var metadata = _readNodeList<Annotation>();

    var node = astFactory.importDirective(
      null,
      metadata,
      KeywordToken(Keyword.IMPORT, keywordOffset),
      uri,
      configurations,
      AstBinaryFlags.isDeferred(flags) ? Tokens.DEFERRED : null,
      Tokens.AS,
      prefixIdentifier,
      combinators,
      Tokens.SEMICOLON,
    ) as ImportDirectiveImpl;

    node.linkedContext = LinkedContext(
      _unitReader,
      node,
      codeOffset: -1,
      codeLength: 0,
      documentationTokenIndexList: _noDocumentationComment,
      resolutionIndex: _readUInt30(),
    );

    return node;
  }

  IndexExpression _readIndexExpression() {
    var flags = _readByte();
    var target = _readOptionalNode() as Expression;
    var index = readNode() as Expression;
    return astFactory.indexExpressionForTarget2(
      target: target,
      question: AstBinaryFlags.hasQuestion(flags) ? Tokens.QUESTION : null,
      leftBracket: Tokens.OPEN_SQUARE_BRACKET,
      index: index,
      rightBracket: Tokens.CLOSE_SQUARE_BRACKET,
    )..period = AstBinaryFlags.hasPeriod(flags) ? Tokens.PERIOD_PERIOD : null;
  }

  int _readInformativeUint30() {
    if (_withInformative) {
      return _readUInt30();
    }
    return 0;
  }

  Uint32List _readInformativeUint30List() {
    if (_withInformative) {
      return _readUint30List();
    }
    return null;
  }

  InstanceCreationExpression _readInstanceCreationExpression() {
    var flags = _readByte();
    var constructorName = readNode() as ConstructorName;
    var argumentList = readNode() as ArgumentList;

    return astFactory.instanceCreationExpression(
      Tokens.choose(
        AstBinaryFlags.isConst(flags),
        Tokens.CONST,
        AstBinaryFlags.isNew(flags),
        Tokens.NEW,
      ),
      constructorName,
      argumentList,
    );
  }

  IntegerLiteral _readIntegerLiteralNegative() {
    var value = (_readUint32() << 32) | _readUint32();
    return _createIntegerLiteral(-value);
  }

  IntegerLiteral _readIntegerLiteralNegative1() {
    var value = _readByte();
    return _createIntegerLiteral(-value);
  }

  IntegerLiteral _readIntegerLiteralNull() {
    var lexeme = _readStringReference();
    return astFactory.integerLiteral(
      TokenFactory.tokenFromTypeAndString(TokenType.INT, lexeme),
      null,
    );
  }

  IntegerLiteral _readIntegerLiteralPositive() {
    var value = (_readUint32() << 32) | _readUint32();
    return _createIntegerLiteral(value);
  }

  IntegerLiteral _readIntegerLiteralPositive1() {
    var value = _readByte();
    return _createIntegerLiteral(value);
  }

  InterpolationExpression _readInterpolationExpression() {
    var flags = _readByte();
    var expression = readNode() as Expression;
    var isIdentifier = AstBinaryFlags.isStringInterpolationIdentifier(flags);
    return astFactory.interpolationExpression(
      isIdentifier
          ? Tokens.OPEN_CURLY_BRACKET
          : Tokens.STRING_INTERPOLATION_EXPRESSION,
      expression,
      isIdentifier ? null : Tokens.CLOSE_CURLY_BRACKET,
    );
  }

  InterpolationString _readInterpolationString() {
    var value = _readStringReference();
    return astFactory.interpolationString(
      TokenFactory.tokenFromString(value),
      value,
    );
  }

  IsExpression _readIsExpression() {
    var flags = _readByte();
    var expression = readNode() as Expression;
    var type = readNode() as TypeAnnotation;
    return astFactory.isExpression(
      expression,
      Tokens.IS,
      AstBinaryFlags.hasNot(flags) ? Tokens.BANG : null,
      type,
    );
  }

  LibraryDirective _readLibraryDirective() {
    var documentationTokenIndexList = _readUint30List();
    var name = readNode();
    var keywordOffset = _readInformativeUint30();
    var metadata = _readNodeList<Annotation>();

    var node = astFactory.libraryDirective(
      null,
      metadata,
      KeywordToken(Keyword.LIBRARY, keywordOffset),
      name,
      Tokens.SEMICOLON,
    );
    SummaryDataForLibraryDirective(
      _unitReader,
      node,
      documentationTokenIndexList: documentationTokenIndexList,
    );
    return node;
  }

  LibraryIdentifier _readLibraryIdentifier() {
    var components = _readNodeList<SimpleIdentifier>();
    return astFactory.libraryIdentifier(
      components,
    );
  }

  ListLiteral _readListLiteral() {
    var flags = _readByte();
    var typeArguments = _readOptionalNode();
    var elements = _readNodeList<CollectionElement>();

    return astFactory.listLiteral(
      AstBinaryFlags.isConst(flags) ? Tokens.CONST : null,
      typeArguments,
      Tokens.OPEN_SQUARE_BRACKET,
      elements,
      Tokens.CLOSE_SQUARE_BRACKET,
    );
  }

  MapLiteralEntry _readMapLiteralEntry() {
    var key = readNode() as Expression;
    var value = readNode() as Expression;
    return astFactory.mapLiteralEntry(key, Tokens.COLON, value);
  }

  MethodDeclaration _readMethodDeclaration() {
    var flags = _readUInt30();

    var codeOffset = _readInformativeUint30();
    var codeLength = _readInformativeUint30();
    var documentationTokenIndexList = _readUint30List();

    var name = readNode() as SimpleIdentifier;
    var typeParameters = _readOptionalNode() as TypeParameterList;
    var returnType = _readOptionalNode() as TypeAnnotation;
    var formalParameters = _readOptionalNode() as FormalParameterList;
    var metadata = _readNodeList<Annotation>();
    var body = _functionBodyForFlags(flags);

    var node = astFactory.methodDeclaration(
      null,
      metadata,
      AstBinaryFlags.isExternal(flags) ? Tokens.EXTERNAL : null,
      AstBinaryFlags.isStatic(flags) ? Tokens.STATIC : null,
      returnType,
      Tokens.choose(
        AstBinaryFlags.isGet(flags),
        Tokens.GET,
        AstBinaryFlags.isSet(flags),
        Tokens.SET,
      ),
      AstBinaryFlags.isOperator(flags) ? Tokens.OPERATOR : null,
      name,
      typeParameters,
      formalParameters,
      body,
    ) as MethodDeclarationImpl;

    node.linkedContext = LinkedContext(
      _unitReader,
      node,
      codeOffset: codeOffset,
      codeLength: codeLength,
      resolutionIndex: _readUInt30(),
      documentationTokenIndexList: documentationTokenIndexList,
    );

    return node;
  }

  MethodInvocation _readMethodInvocation() {
    var flags = _readByte();
    var target = _readOptionalNode() as Expression;
    var methodName = readNode() as SimpleIdentifier;
    var typeArguments = _readOptionalNode() as TypeArgumentList;
    var arguments = readNode() as ArgumentList;

    return astFactory.methodInvocation(
      target,
      Tokens.choose(
        AstBinaryFlags.hasPeriod(flags),
        Tokens.PERIOD,
        AstBinaryFlags.hasPeriod2(flags),
        Tokens.PERIOD_PERIOD,
      ),
      methodName,
      typeArguments,
      arguments,
    );
  }

  MixinDeclaration _readMixinDeclaration() {
    var codeOffset = _readInformativeUint30();
    var codeLength = _readInformativeUint30();
    var documentationTokenIndexList = _readUint30List();

    var typeParameters = _readOptionalNode() as TypeParameterList;
    var onClause = _readOptionalNode() as OnClause;
    var implementsClause = _readOptionalNode() as ImplementsClause;
    var name = readNode() as SimpleIdentifier;
    var metadata = _readNodeList<Annotation>();

    var node = astFactory.mixinDeclaration(
      null,
      metadata,
      Tokens.MIXIN,
      name,
      typeParameters,
      onClause,
      implementsClause,
      Tokens.OPEN_CURLY_BRACKET,
      const <ClassMember>[],
      Tokens.CLOSE_CURLY_BRACKET,
    ) as MixinDeclarationImpl;

    node.linkedContext = LinkedContext(
      _unitReader,
      node,
      codeOffset: codeOffset,
      codeLength: codeLength,
      resolutionIndex: _readUInt30(),
      documentationTokenIndexList: documentationTokenIndexList,
    );

    return node;
  }

  NamedExpression _readNamedExpression() {
    var name = _readStringReference();
    var offset = _readInformativeUint30();
    var nameNode = astFactory.label(
      astFactory.simpleIdentifier(
        StringToken(TokenType.STRING, name, offset),
      ),
      Tokens.COLON,
    );

    var expression = readNode() as Expression;
    return astFactory.namedExpression(nameNode, expression);
  }

  NativeClause _readNativeClause() {
    var name = readNode();
    return astFactory.nativeClause(Tokens.NATIVE, name);
  }

  List<T> _readNodeList<T>() {
    var length = _readUInt30();
    // TODO(scheglov) This will not work for null safety, rewrite.
    var result = List<T>.filled(length, null);
    for (var i = 0; i < length; ++i) {
      result[i] = readNode() as T;
    }
    return result;
  }

  NullLiteral _readNullLiteral() {
    return astFactory.nullLiteral(
      Tokens.NULL,
    );
  }

  OnClause _readOnClause() {
    var superclassConstraints = _readNodeList<TypeName>();
    return astFactory.onClause(Tokens.ON, superclassConstraints);
  }

  AstNode _readOptionalNode() {
    if (_readOptionTag()) {
      return readNode();
    } else {
      return null;
    }
  }

  bool _readOptionTag() {
    var tag = _readByte();
    if (tag == Tag.Nothing) {
      return false;
    } else if (tag == Tag.Something) {
      return true;
    } else {
      throw UnimplementedError('Unexpected option tag: $tag');
    }
  }

  ParenthesizedExpression _readParenthesizedExpression() {
    var expression = readNode() as Expression;
    return astFactory.parenthesizedExpression(
      Tokens.OPEN_PAREN,
      expression,
      Tokens.CLOSE_PAREN,
    );
  }

  PartDirective _readPartDirective() {
    var uri = readNode();
    var keywordOffset = _readInformativeUint30();
    var metadata = _readNodeList<Annotation>();

    return astFactory.partDirective(
      null,
      metadata,
      KeywordToken(Keyword.PART, keywordOffset),
      uri,
      Tokens.SEMICOLON,
    );
  }

  PartOfDirective _readPartOfDirective() {
    var libraryName = _readOptionalNode() as LibraryIdentifier;
    var uri = _readOptionalNode() as StringLiteral;
    var keywordOffset = _readInformativeUint30();
    var metadata = _readNodeList<Annotation>();

    return astFactory.partOfDirective(
      null,
      metadata,
      KeywordToken(Keyword.PART, keywordOffset),
      Tokens.OF,
      uri,
      libraryName,
      Tokens.SEMICOLON,
    );
  }

  PostfixExpression _readPostfixExpression() {
    var operand = readNode() as Expression;
    var operatorType = UnlinkedTokenType.values[_readByte()];
    return astFactory.postfixExpression(
      operand,
      Tokens.fromType(operatorType),
    );
  }

  PrefixedIdentifier _readPrefixedIdentifier() {
    var prefix = readNode() as SimpleIdentifier;
    var identifier = readNode() as SimpleIdentifier;
    return astFactory.prefixedIdentifier(
      prefix,
      Tokens.PERIOD,
      identifier,
    );
  }

  PrefixExpression _readPrefixExpression() {
    var operatorType = UnlinkedTokenType.values[_readByte()];
    var operand = readNode() as Expression;
    return astFactory.prefixExpression(
      Tokens.fromType(operatorType),
      operand,
    );
  }

  PropertyAccess _readPropertyAccess() {
    var flags = _readByte();
    var target = _readOptionalNode() as Expression;
    var propertyName = readNode() as SimpleIdentifier;
    return astFactory.propertyAccess(
      target,
      Tokens.choose(
        AstBinaryFlags.hasPeriod(flags),
        Tokens.PERIOD,
        AstBinaryFlags.hasPeriod2(flags),
        Tokens.PERIOD_PERIOD,
      ),
      propertyName,
    );
  }

  RedirectingConstructorInvocation _readRedirectingConstructorInvocation() {
    var flags = _readByte();
    var constructorName = _readOptionalNode() as SimpleIdentifier;
    var argumentList = readNode() as ArgumentList;
    var hasThis = AstBinaryFlags.hasThis(flags);
    return astFactory.redirectingConstructorInvocation(
      hasThis ? Tokens.THIS : null,
      hasThis ? Tokens.PERIOD : null,
      constructorName,
      argumentList,
    );
  }

  SetOrMapLiteral _readSetOrMapLiteral() {
    var flags = _readByte();
    var typeArguments = _readOptionalNode() as TypeArgumentList;
    var elements = _readNodeList<CollectionElement>();
    var node = astFactory.setOrMapLiteral(
      constKeyword: AstBinaryFlags.isConst(flags) ? Tokens.CONST : null,
      elements: elements,
      leftBracket: Tokens.OPEN_CURLY_BRACKET,
      typeArguments: typeArguments,
      rightBracket: Tokens.CLOSE_CURLY_BRACKET,
    ) as SetOrMapLiteralImpl;
    return node;
  }

  ShowCombinator _readShowCombinator() {
    var keywordOffset = _readInformativeUint30();
    return astFactory.showCombinator(
      KeywordToken(Keyword.SHOW, keywordOffset),
      _readNodeList<SimpleIdentifier>(),
    );
  }

  SimpleFormalParameter _readSimpleFormalParameter() {
    var type = _readOptionalNode() as TypeAnnotation;
    var flags = _readByte();
    var codeOffset = _readInformativeUint30();
    var codeLength = _readInformativeUint30();
    var metadata = _readNodeList<Annotation>();
    var identifier =
        AstBinaryFlags.hasName(flags) ? readNode() as SimpleIdentifier : null;

    var node = astFactory.simpleFormalParameter2(
      identifier: identifier,
      type: type,
      covariantKeyword:
          AstBinaryFlags.isCovariant(flags) ? Tokens.COVARIANT : null,
      comment: null,
      metadata: metadata,
      keyword: Tokens.choose(
        AstBinaryFlags.isConst(flags),
        Tokens.CONST,
        AstBinaryFlags.isFinal(flags),
        Tokens.FINAL,
        AstBinaryFlags.isVar(flags),
        Tokens.VAR,
      ),
      requiredKeyword:
          AstBinaryFlags.isRequired(flags) ? Tokens.REQUIRED : null,
    ) as SimpleFormalParameterImpl;
    node.summaryData = SummaryDataForFormalParameter(
      codeOffset: codeOffset,
      codeLength: codeLength,
    );
    return node;
  }

  SimpleIdentifier _readSimpleIdentifier() {
    var name = _readStringReference();
    var offset = _readInformativeUint30();
    return astFactory.simpleIdentifier(
      StringToken(TokenType.STRING, name, offset),
    );
  }

  SimpleStringLiteral _readSimpleStringLiteral() {
    var lexeme = _readStringReference();
    var value = _readStringReference();

    return astFactory.simpleStringLiteral(
      TokenFactory.tokenFromString(lexeme),
      value,
    );
  }

  SpreadElement _readSpreadElement() {
    var flags = _readByte();
    var expression = readNode() as Expression;
    return astFactory.spreadElement(
      spreadOperator: AstBinaryFlags.hasQuestion(flags)
          ? Tokens.PERIOD_PERIOD_PERIOD_QUESTION
          : Tokens.PERIOD_PERIOD_PERIOD,
      expression: expression,
    );
  }

  StringInterpolation _readStringInterpolation() {
    var elements = _readNodeList<InterpolationElement>();
    return astFactory.stringInterpolation(elements);
  }

  String _readStringReference() {
    return _unitReader.astReader.readStringReference();
  }

  SuperConstructorInvocation _readSuperConstructorInvocation() {
    var constructorName = _readOptionalNode() as SimpleIdentifier;
    var argumentList = readNode() as ArgumentList;
    return astFactory.superConstructorInvocation(
      Tokens.SUPER,
      Tokens.PERIOD,
      constructorName,
      argumentList,
    );
  }

  SuperExpression _readSuperExpression() {
    return astFactory.superExpression(Tokens.SUPER);
  }

  SymbolLiteral _readSymbolLiteral() {
    var components = <Token>[];
    var length = _readUInt30();
    for (var i = 0; i < length; i++) {
      var lexeme = _readStringReference();
      var token = TokenFactory.tokenFromString(lexeme);
      components.add(token);
    }
    return astFactory.symbolLiteral(Tokens.HASH, components);
  }

  ThisExpression _readThisExpression() {
    return astFactory.thisExpression(Tokens.THIS);
  }

  ThrowExpression _readThrowExpression() {
    var expression = readNode() as Expression;
    return astFactory.throwExpression(Tokens.THROW, expression);
  }

  TopLevelVariableDeclaration _readTopLevelVariableDeclaration() {
    var flags = _readByte();
    var codeOffsetLengthList = _readInformativeUint30List();
    var documentationTokenIndexList = _readUint30List();
    var variableList = readNode() as VariableDeclarationList;
    var metadata = _readNodeList<Annotation>();

    var node = astFactory.topLevelVariableDeclaration(
      null,
      metadata,
      variableList,
      Tokens.SEMICOLON,
      externalKeyword:
          AstBinaryFlags.isExternal(flags) ? Tokens.EXTERNAL : null,
    ) as TopLevelVariableDeclarationImpl;

    node.linkedContext = LinkedContext(
      _unitReader,
      node,
      codeOffset: -1,
      codeLength: 0,
      codeOffsetLengthList: codeOffsetLengthList,
      resolutionIndex: _readUInt30(),
      documentationTokenIndexList: documentationTokenIndexList,
    );

    return node;
  }

  TypeArgumentList _readTypeArgumentList() {
    var arguments = _readNodeList<TypeAnnotation>();
    return astFactory.typeArgumentList(Tokens.LT, arguments, Tokens.GT);
  }

  TypeName _readTypeName() {
    var flags = _readByte();
    var name = readNode() as Identifier;
    var typeArguments = _readOptionalNode() as TypeArgumentList;

    return astFactory.typeName(
      name,
      typeArguments,
      question: AstBinaryFlags.hasQuestion(flags) ? Tokens.QUESTION : null,
    );
  }

  TypeParameter _readTypeParameter() {
    var codeOffset = _readInformativeUint30();
    var codeLength = _readInformativeUint30();
    var name = readNode() as Identifier;
    var bound = _readOptionalNode() as TypeAnnotation;
    var metadata = _readNodeList<Annotation>();

    var node = astFactory.typeParameter(
      null,
      metadata,
      name,
      bound != null ? Tokens.EXTENDS : null,
      bound,
    ) as TypeParameterImpl;
    node.summaryData = SummaryDataForTypeParameter(
      codeOffset: codeOffset,
      codeLength: codeLength,
    );

    return node;
  }

  TypeParameterList _readTypeParameterList() {
    var typeParameters = _readNodeList<TypeParameter>();
    return astFactory.typeParameterList(
      Tokens.LT,
      typeParameters,
      Tokens.GT,
    );
  }

  int _readUInt30() {
    var byte = _readByte();
    if (byte & 0x80 == 0) {
      // 0xxxxxxx
      return byte;
    } else if (byte & 0x40 == 0) {
      // 10xxxxxx
      return ((byte & 0x3F) << 8) | _readByte();
    } else {
      // 11xxxxxx
      return ((byte & 0x3F) << 24) |
          (_readByte() << 16) |
          (_readByte() << 8) |
          _readByte();
    }
  }

  Uint32List _readUint30List() {
    var length = _readUInt30();
    var result = Uint32List(length);
    for (var i = 0; i < length; ++i) {
      result[i] = _readUInt30();
    }
    return result;
  }

  int _readUint32() {
    return (_readByte() << 24) |
        (_readByte() << 16) |
        (_readByte() << 8) |
        _readByte();
  }

  VariableDeclaration _readVariableDeclaration() {
    var flags = _readByte();
    var name = readNode() as SimpleIdentifier;
    var initializer = _readOptionalNode() as Expression;

    var node = astFactory.variableDeclaration(
      name,
      Tokens.EQ,
      initializer,
    ) as VariableDeclarationImpl;

    node.hasInitializer = AstBinaryFlags.hasInitializer(flags);

    return node;
  }

  VariableDeclarationList _readVariableDeclarationList() {
    var flags = _readByte();
    var type = _readOptionalNode() as TypeAnnotation;
    var variables = _readNodeList<VariableDeclaration>();
    var metadata = _readNodeList<Annotation>();

    return astFactory.variableDeclarationList2(
      comment: null,
      keyword: Tokens.choose(
        AstBinaryFlags.isConst(flags),
        Tokens.CONST,
        AstBinaryFlags.isFinal(flags),
        Tokens.FINAL,
        AstBinaryFlags.isVar(flags),
        Tokens.VAR,
      ),
      lateKeyword: AstBinaryFlags.isLate(flags) ? Tokens.LATE : null,
      metadata: metadata,
      type: type,
      variables: variables,
    );
  }

  WithClause _readWithClause() {
    var mixins = _readNodeList<TypeName>();
    return astFactory.withClause(Tokens.WITH, mixins);
  }
}
