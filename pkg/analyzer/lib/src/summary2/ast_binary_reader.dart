// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/ast_binary_flags.dart';
import 'package:analyzer/src/summary2/ast_binary_tag.dart';
import 'package:analyzer/src/summary2/ast_binary_tokens.dart';
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/unlinked_token_type.dart';
import 'package:collection/collection.dart';

/// Deserializer of ASTs.
class AstBinaryReader {
  final ResolutionReader _reader;

  AstBinaryReader({
    required ResolutionReader reader,
  }) : _reader = reader;

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
      case Tag.AwaitExpression:
        return _readAwaitExpression();
      case Tag.BinaryExpression:
        return _readBinaryExpression();
      case Tag.BooleanLiteral:
        return _readBooleanLiteral();
      case Tag.CascadeExpression:
        return _readCascadeExpression();
      case Tag.ConditionalExpression:
        return _readConditionalExpression();
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
      case Tag.ExtensionOverride:
        return _readExtensionOverride();
      case Tag.ForEachPartsWithDeclaration:
        return _readForEachPartsWithDeclaration();
      case Tag.ForElement:
        return _readForElement();
      case Tag.ForPartsWithDeclarations:
        return _readForPartsWithDeclarations();
      case Tag.ForPartsWithExpression:
        return _readForPartsWithExpression();
      case Tag.FieldFormalParameter:
        return _readFieldFormalParameter();
      case Tag.FormalParameterList:
        return _readFormalParameterList();
      case Tag.FunctionExpression:
        return _readFunctionExpression();
      case Tag.FunctionExpressionInvocation:
        return _readFunctionExpressionInvocation();
      case Tag.FunctionTypedFormalParameter:
        return _readFunctionTypedFormalParameter();
      case Tag.GenericFunctionType:
        return _readGenericFunctionType();
      case Tag.IfElement:
        return _readIfElement();
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
      case Tag.ListLiteral:
        return _readListLiteral();
      case Tag.MapLiteralEntry:
        return _readMapLiteralEntry();
      case Tag.MixinDeclaration:
        return _readMixinDeclaration();
      case Tag.MethodInvocation:
        return _readMethodInvocation();
      case Tag.NamedExpression:
        return _readNamedExpression();
      case Tag.NullLiteral:
        return _readNullLiteral();
      case Tag.InstanceCreationExpression:
        return _readInstanceCreationExpression();
      case Tag.ParenthesizedExpression:
        return _readParenthesizedExpression();
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
      case Tag.VariableDeclaration:
        return _readVariableDeclaration();
      case Tag.VariableDeclarationList:
        return _readVariableDeclarationList();
      default:
        throw UnimplementedError('Unexpected tag: $tag');
    }
  }

  IntegerLiteral _createIntegerLiteral(int value) {
    // TODO(scheglov) Write token?
    var node = astFactory.integerLiteral(
      TokenFactory.tokenFromTypeAndString(TokenType.INT, '$value'),
      value,
    );
    _readExpressionResolution(node);
    return node;
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
    var name = readNode() as Identifier;
    var typeArguments = _readOptionalNode() as TypeArgumentList?;
    var constructorName = _readOptionalNode() as SimpleIdentifier?;
    var arguments = _readOptionalNode() as ArgumentList?;
    var node = astFactory.annotation(
      atSign: Tokens.AT,
      name: name,
      typeArguments: typeArguments,
      period: Tokens.PERIOD,
      constructorName: constructorName,
      arguments: arguments,
    );
    node.element = _reader.readElement();
    return node;
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
    var node = astFactory.asExpression(expression, Tokens.AS, type);
    _readExpressionResolution(node);
    return node;
  }

  AssertInitializer _readAssertInitializer() {
    var condition = readNode() as Expression;
    var message = _readOptionalNode() as Expression?;
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
    var node = astFactory.assignmentExpression(
      leftHandSide,
      Tokens.fromType(operatorType),
      rightHandSide,
    );
    node.staticElement = _reader.readElement() as MethodElement?;
    node.readElement = _reader.readElement();
    node.readType = _reader.readType();
    node.writeElement = _reader.readElement();
    node.writeType = _reader.readType();
    _readExpressionResolution(node);
    return node;
  }

  AwaitExpression _readAwaitExpression() {
    var expression = readNode() as Expression;
    return astFactory.awaitExpression(Tokens.AWAIT, expression);
  }

  BinaryExpression _readBinaryExpression() {
    var leftOperand = readNode() as Expression;
    var rightOperand = readNode() as Expression;
    var operatorType = UnlinkedTokenType.values[_readByte()];
    var node = astFactory.binaryExpression(
      leftOperand,
      Tokens.fromType(operatorType),
      rightOperand,
    );
    node.staticElement = _reader.readElement() as MethodElement?;
    _readExpressionResolution(node);
    return node;
  }

  BooleanLiteral _readBooleanLiteral() {
    var value = _readByte() == 1;
    var node = AstTestFactory.booleanLiteral(value);
    _readExpressionResolution(node);
    return node;
  }

  int _readByte() {
    return _reader.readByte();
  }

  CascadeExpression _readCascadeExpression() {
    var target = readNode() as Expression;
    var sections = _readNodeList<Expression>();
    var node = astFactory.cascadeExpression(target, sections);
    node.staticType = target.staticType;
    return node;
  }

  ConditionalExpression _readConditionalExpression() {
    var condition = readNode() as Expression;
    var thenExpression = readNode() as Expression;
    var elseExpression = readNode() as Expression;
    var node = astFactory.conditionalExpression(
      condition,
      Tokens.QUESTION,
      thenExpression,
      Tokens.COLON,
      elseExpression,
    );
    _readExpressionResolution(node);
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
    var name = _readOptionalNode() as SimpleIdentifier?;

    var node = astFactory.constructorName(
      type,
      name != null ? Tokens.PERIOD : null,
      name,
    );
    node.staticElement = _reader.readElement() as ConstructorElement?;
    return node;
  }

  SimpleIdentifier _readDeclarationName() {
    var name = _reader.readStringReference();
    var node = astFactory.simpleIdentifier(
      StringToken(TokenType.STRING, name, -1),
    );
    return node;
  }

  DeclaredIdentifier _readDeclaredIdentifier() {
    var flags = _readByte();
    var type = _readOptionalNode() as TypeAnnotation?;
    var identifier = _readDeclarationName();
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
    var parameter = readNode() as NormalFormalParameter;
    var defaultValue = _readOptionalNode() as Expression?;

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
    );

    return node;
  }

  DottedName _readDottedName() {
    var components = _readNodeList<SimpleIdentifier>();
    return astFactory.dottedName(components);
  }

  DoubleLiteral _readDoubleLiteral() {
    var value = _reader.readDouble();
    var node = AstTestFactory.doubleLiteral(value);
    _readExpressionResolution(node);
    return node;
  }

  void _readExpressionResolution(ExpressionImpl node) {
    node.staticType = _reader.readType();
  }

  ExtensionOverride _readExtensionOverride() {
    var extensionName = readNode() as Identifier;
    var typeArguments = _readOptionalNode() as TypeArgumentList?;
    var argumentList = readNode() as ArgumentList;
    var node = astFactory.extensionOverride(
      extensionName: extensionName,
      argumentList: argumentList,
      typeArguments: typeArguments,
    );
    _readExpressionResolution(node);
    return node;
  }

  FieldFormalParameter _readFieldFormalParameter() {
    var typeParameters = _readOptionalNode() as TypeParameterList?;
    var type = _readOptionalNode() as TypeAnnotation?;
    var formalParameters = _readOptionalNode() as FormalParameterList?;
    var flags = _readByte();
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
    var flags = _readByte();
    var forLoopParts = readNode() as ForLoopParts;
    var body = readNode() as CollectionElement;
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
    var condition = _readOptionalNode() as Expression?;
    var updaters = _readNodeList<Expression>();
    return astFactory.forPartsWithDeclarations(
      condition: condition,
      leftSeparator: Tokens.SEMICOLON,
      rightSeparator: Tokens.SEMICOLON,
      updaters: updaters,
      variables: variables,
    );
  }

  ForPartsWithExpression _readForPartsWithExpression() {
    var initialization = _readOptionalNode() as Expression?;
    var condition = _readOptionalNode() as Expression?;
    var updaters = _readNodeList<Expression>();
    return astFactory.forPartsWithExpression(
      condition: condition,
      initialization: initialization,
      leftSeparator: Tokens.SEMICOLON,
      rightSeparator: Tokens.SEMICOLON,
      updaters: updaters,
    );
  }

  FunctionExpression _readFunctionExpression() {
    var flags = _readByte();
    var typeParameters = _readOptionalNode() as TypeParameterList?;
    var formalParameters = _readOptionalNode() as FormalParameterList?;
    var body = _functionBodyForFlags(flags);

    return astFactory.functionExpression(
      typeParameters,
      formalParameters,
      body,
    );
  }

  FunctionExpressionInvocation _readFunctionExpressionInvocation() {
    var function = readNode() as Expression;
    var typeArguments = _readOptionalNode() as TypeArgumentList?;
    var arguments = readNode() as ArgumentList;
    var node = astFactory.functionExpressionInvocation(
      function,
      typeArguments,
      arguments,
    );
    _readExpressionResolution(node);
    return node;
  }

  FunctionTypedFormalParameter _readFunctionTypedFormalParameter() {
    var typeParameters = _readOptionalNode() as TypeParameterList?;
    var returnType = _readOptionalNode() as TypeAnnotation?;
    var formalParameters = readNode() as FormalParameterList;
    var flags = _readByte();
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
    );
    return node;
  }

  GenericFunctionType _readGenericFunctionType() {
    var flags = _readByte();
    // TODO(scheglov) add type parameters to locals
    var typeParameters = _readOptionalNode() as TypeParameterList?;
    var returnType = _readOptionalNode() as TypeAnnotation?;
    var formalParameters = readNode() as FormalParameterList;
    var node = astFactory.genericFunctionType(
      returnType,
      Tokens.FUNCTION,
      typeParameters,
      formalParameters,
      question: AstBinaryFlags.hasQuestion(flags) ? Tokens.QUESTION : null,
    );
    node.type = _reader.readType();
    return node;
  }

  IfElement _readIfElement() {
    var condition = readNode() as Expression;
    var thenElement = readNode() as CollectionElement;
    var elseElement = _readOptionalNode() as CollectionElement?;
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

  IndexExpression _readIndexExpression() {
    var flags = _readByte();
    var target = _readOptionalNode() as Expression?;
    var index = readNode() as Expression;
    // TODO(scheglov) Is this clumsy?
    IndexExpressionImpl node;
    if (target != null) {
      node = (astFactory.indexExpressionForTarget2(
        target: target,
        question: AstBinaryFlags.hasQuestion(flags) ? Tokens.QUESTION : null,
        leftBracket: Tokens.OPEN_SQUARE_BRACKET,
        index: index,
        rightBracket: Tokens.CLOSE_SQUARE_BRACKET,
      ))
        ..period =
            AstBinaryFlags.hasPeriod(flags) ? Tokens.PERIOD_PERIOD : null;
    } else {
      node = astFactory.indexExpressionForCascade2(
        period: Tokens.PERIOD_PERIOD,
        question: AstBinaryFlags.hasQuestion(flags) ? Tokens.QUESTION : null,
        leftBracket: Tokens.OPEN_SQUARE_BRACKET,
        index: index,
        rightBracket: Tokens.CLOSE_SQUARE_BRACKET,
      );
    }
    node.staticElement = _reader.readElement() as MethodElement?;
    _readExpressionResolution(node);
    return node;
  }

  InstanceCreationExpression _readInstanceCreationExpression() {
    var flags = _readByte();
    var constructorName = readNode() as ConstructorName;
    var argumentList = readNode() as ArgumentList;

    var node = astFactory.instanceCreationExpression(
      Tokens.choose(
        AstBinaryFlags.isConst(flags),
        Tokens.CONST,
        AstBinaryFlags.isNew(flags),
        Tokens.NEW,
      ),
      constructorName,
      argumentList,
    );
    _readExpressionResolution(node);
    _resolveNamedExpressions(
      node.constructorName.staticElement,
      node.argumentList,
    );
    return node;
  }

  IntegerLiteral _readIntegerLiteralNegative() {
    var value = (_readUInt32() << 32) | _readUInt32();
    return _createIntegerLiteral(-value);
  }

  IntegerLiteral _readIntegerLiteralNegative1() {
    var value = _readByte();
    return _createIntegerLiteral(-value);
  }

  IntegerLiteral _readIntegerLiteralNull() {
    var lexeme = _readStringReference();
    var node = astFactory.integerLiteral(
      TokenFactory.tokenFromTypeAndString(TokenType.INT, lexeme),
      null,
    );
    _readExpressionResolution(node);
    return node;
  }

  IntegerLiteral _readIntegerLiteralPositive() {
    var value = (_readUInt32() << 32) | _readUInt32();
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

  void _readInvocationExpression(InvocationExpressionImpl node) {
    // TODO(scheglov) typeArgumentTypes and staticInvokeType?
    node.typeArgumentTypes = [];
    _readExpressionResolution(node);
  }

  IsExpression _readIsExpression() {
    var flags = _readByte();
    var expression = readNode() as Expression;
    var type = readNode() as TypeAnnotation;
    var node = astFactory.isExpression(
      expression,
      Tokens.IS,
      AstBinaryFlags.hasNot(flags) ? Tokens.BANG : null,
      type,
    );
    _readExpressionResolution(node);
    return node;
  }

  ListLiteral _readListLiteral() {
    var flags = _readByte();
    var typeArguments = _readOptionalNode() as TypeArgumentList?;
    var elements = _readNodeList<CollectionElement>();

    var node = astFactory.listLiteral(
      AstBinaryFlags.isConst(flags) ? Tokens.CONST : null,
      typeArguments,
      Tokens.OPEN_SQUARE_BRACKET,
      elements,
      Tokens.CLOSE_SQUARE_BRACKET,
    );
    _readExpressionResolution(node);
    return node;
  }

  MapLiteralEntry _readMapLiteralEntry() {
    var key = readNode() as Expression;
    var value = readNode() as Expression;
    return astFactory.mapLiteralEntry(key, Tokens.COLON, value);
  }

  MethodInvocation _readMethodInvocation() {
    var flags = _readByte();
    var target = _readOptionalNode() as Expression?;
    var methodName = readNode() as SimpleIdentifier;
    var typeArguments = _readOptionalNode() as TypeArgumentList?;
    var arguments = readNode() as ArgumentList;

    var node = astFactory.methodInvocation(
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
    _readInvocationExpression(node);
    return node;
  }

  MixinDeclaration _readMixinDeclaration() {
    var typeParameters = _readOptionalNode() as TypeParameterList?;
    var onClause = _readOptionalNode() as OnClause?;
    var implementsClause = _readOptionalNode() as ImplementsClause?;
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
    );

    return node;
  }

  NamedExpression _readNamedExpression() {
    var name = _readStringReference();
    var nameNode = astFactory.label(
      astFactory.simpleIdentifier(
        StringToken(TokenType.STRING, name, -1),
      ),
      Tokens.COLON,
    );
    var expression = readNode() as Expression;
    var node = astFactory.namedExpression(nameNode, expression);
    node.staticType = expression.staticType;
    return node;
  }

  List<T> _readNodeList<T>() {
    var length = _reader.readUInt30();
    return List.generate(length, (_) => readNode() as T);
  }

  NullLiteral _readNullLiteral() {
    return astFactory.nullLiteral(
      Tokens.NULL,
    );
  }

  AstNode? _readOptionalNode() {
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
    var node = astFactory.parenthesizedExpression(
      Tokens.OPEN_PAREN,
      expression,
      Tokens.CLOSE_PAREN,
    );
    _readExpressionResolution(node);
    return node;
  }

  PostfixExpression _readPostfixExpression() {
    var operand = readNode() as Expression;
    var operatorType = UnlinkedTokenType.values[_readByte()];
    var node = astFactory.postfixExpression(
      operand,
      Tokens.fromType(operatorType),
    );
    node.staticElement = _reader.readElement() as MethodElement?;
    if (node.operator.type.isIncrementOperator) {
      node.readElement = _reader.readElement();
      node.readType = _reader.readType();
      node.writeElement = _reader.readElement();
      node.writeType = _reader.readType();
    }
    _readExpressionResolution(node);
    return node;
  }

  PrefixedIdentifier _readPrefixedIdentifier() {
    var prefix = readNode() as SimpleIdentifier;
    var identifier = readNode() as SimpleIdentifier;
    var node = astFactory.prefixedIdentifier(
      prefix,
      Tokens.PERIOD,
      identifier,
    );
    _readExpressionResolution(node);
    return node;
  }

  PrefixExpression _readPrefixExpression() {
    var operatorType = UnlinkedTokenType.values[_readByte()];
    var operand = readNode() as Expression;
    var node = astFactory.prefixExpression(
      Tokens.fromType(operatorType),
      operand,
    );
    node.staticElement = _reader.readElement() as MethodElement?;
    if (node.operator.type.isIncrementOperator) {
      node.readElement = _reader.readElement();
      node.readType = _reader.readType();
      node.writeElement = _reader.readElement();
      node.writeType = _reader.readType();
    }
    _readExpressionResolution(node);
    return node;
  }

  PropertyAccess _readPropertyAccess() {
    var flags = _readByte();
    var target = _readOptionalNode() as Expression?;
    var propertyName = readNode() as SimpleIdentifier;

    Token operator;
    if (AstBinaryFlags.hasQuestion(flags)) {
      operator = AstBinaryFlags.hasPeriod(flags)
          ? Tokens.QUESTION_PERIOD
          : Tokens.QUESTION_PERIOD_PERIOD;
    } else {
      operator = AstBinaryFlags.hasPeriod(flags)
          ? Tokens.PERIOD
          : Tokens.PERIOD_PERIOD;
    }

    var node = astFactory.propertyAccess(target, operator, propertyName);
    _readExpressionResolution(node);
    return node;
  }

  RedirectingConstructorInvocation _readRedirectingConstructorInvocation() {
    var constructorName = _readOptionalNode() as SimpleIdentifier?;
    var argumentList = readNode() as ArgumentList;
    var node = astFactory.redirectingConstructorInvocation(
      Tokens.THIS,
      constructorName != null ? Tokens.PERIOD : null,
      constructorName,
      argumentList,
    );
    node.staticElement = _reader.readElement() as ConstructorElement?;
    _resolveNamedExpressions(node.staticElement, node.argumentList);
    return node;
  }

  SetOrMapLiteral _readSetOrMapLiteral() {
    var flags = _readByte();
    var isMapOrSetBits = _readByte();
    var typeArguments = _readOptionalNode() as TypeArgumentList?;
    var elements = _readNodeList<CollectionElement>();
    var node = astFactory.setOrMapLiteral(
      constKeyword: AstBinaryFlags.isConst(flags) ? Tokens.CONST : null,
      elements: elements,
      leftBracket: Tokens.OPEN_CURLY_BRACKET,
      typeArguments: typeArguments,
      rightBracket: Tokens.CLOSE_CURLY_BRACKET,
    );

    const isMapBit = 1 << 0;
    const isSetBit = 1 << 1;
    if ((isMapOrSetBits & isMapBit) != 0) {
      node.becomeMap();
    } else if ((isMapOrSetBits & isSetBit) != 0) {
      node.becomeSet();
    }

    _readExpressionResolution(node);
    return node;
  }

  SimpleFormalParameter _readSimpleFormalParameter() {
    var type = _readOptionalNode() as TypeAnnotation?;
    var flags = _readByte();
    var metadata = _readNodeList<Annotation>();
    var identifier =
        AstBinaryFlags.hasName(flags) ? _readDeclarationName() : null;

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
    );
    _reader.readType(); // TODO(scheglov) actual type
    _reader.readByte(); // TODO(scheglov) inherits covariant
    return node;
  }

  SimpleIdentifier _readSimpleIdentifier() {
    var name = _readStringReference();
    var node = astFactory.simpleIdentifier(
      StringToken(TokenType.STRING, name, -1),
    );
    node.staticElement = _reader.readElement();
    _readExpressionResolution(node);
    return node;
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
    return _reader.readStringReference();
  }

  SuperConstructorInvocation _readSuperConstructorInvocation() {
    var constructorName = _readOptionalNode() as SimpleIdentifier?;
    var argumentList = readNode() as ArgumentList;
    var node = astFactory.superConstructorInvocation(
      Tokens.SUPER,
      Tokens.PERIOD,
      constructorName,
      argumentList,
    );
    node.staticElement = _reader.readElement() as ConstructorElement?;
    _resolveNamedExpressions(node.staticElement, node.argumentList);
    return node;
  }

  SuperExpression _readSuperExpression() {
    var node = astFactory.superExpression(Tokens.SUPER);
    _readExpressionResolution(node);
    return node;
  }

  SymbolLiteral _readSymbolLiteral() {
    var components = _reader
        .readStringReferenceList()
        .map(TokenFactory.tokenFromString)
        .toList();
    var node = astFactory.symbolLiteral(Tokens.HASH, components);
    _readExpressionResolution(node);
    return node;
  }

  ThisExpression _readThisExpression() {
    var node = astFactory.thisExpression(Tokens.THIS);
    _readExpressionResolution(node);
    return node;
  }

  ThrowExpression _readThrowExpression() {
    var expression = readNode() as Expression;
    var node = astFactory.throwExpression(Tokens.THROW, expression);
    _readExpressionResolution(node);
    return node;
  }

  TypeArgumentList _readTypeArgumentList() {
    var arguments = _readNodeList<TypeAnnotation>();
    return astFactory.typeArgumentList(Tokens.LT, arguments, Tokens.GT);
  }

  TypeName _readTypeName() {
    var flags = _readByte();
    var name = readNode() as Identifier;
    var typeArguments = _readOptionalNode() as TypeArgumentList?;

    var node = astFactory.typeName(
      name,
      typeArguments,
      question: AstBinaryFlags.hasQuestion(flags) ? Tokens.QUESTION : null,
    );
    node.type = _reader.readType();
    return node;
  }

  TypeParameter _readTypeParameter() {
    var name = _readDeclarationName();
    var bound = _readOptionalNode() as TypeAnnotation?;
    var metadata = _readNodeList<Annotation>();

    var node = astFactory.typeParameter(
      null,
      metadata,
      name,
      bound != null ? Tokens.EXTENDS : null,
      bound,
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

  int _readUInt32() {
    return _reader.readUInt32();
  }

  VariableDeclaration _readVariableDeclaration() {
    var flags = _readByte();
    var name = readNode() as SimpleIdentifier;
    var initializer = _readOptionalNode() as Expression?;

    var node = astFactory.variableDeclaration(
      name,
      Tokens.EQ,
      initializer,
    );

    node.hasInitializer = AstBinaryFlags.hasInitializer(flags);

    return node;
  }

  VariableDeclarationList _readVariableDeclarationList() {
    var flags = _readByte();
    var type = _readOptionalNode() as TypeAnnotation?;
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

  void _resolveNamedExpressions(
    Element? executable,
    ArgumentList argumentList,
  ) {
    for (var argument in argumentList.arguments) {
      if (argument is NamedExpressionImpl) {
        var nameNode = argument.name.label;
        if (executable is ExecutableElement) {
          var parameters = executable.parameters;
          var name = nameNode.name;
          nameNode.staticElement = parameters.firstWhereOrNull((e) {
            return e.name == name;
          });
        }
      }
    }
  }
}
