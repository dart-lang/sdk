// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/string_canonicalizer.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/ast_binary_flags.dart';
import 'package:analyzer/src/summary2/ast_binary_tag.dart';
import 'package:analyzer/src/summary2/ast_binary_tokens.dart';
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/unlinked_token_type.dart';

/// Deserializer of ASTs.
class AstBinaryReader {
  final ResolutionReader _reader;

  AstBinaryReader({required ResolutionReader reader}) : _reader = reader;

  AstNode readNode() {
    var node = _readNode();
    if (node is AstNodeImpl) {
      AstNodeImpl.linkNodeTokens(node);
    }
    return node;
  }

  void _bindFormalParameterFragment(
    FormalParameterImpl node,
    FormalParameterFragmentImpl fragment,
  ) {
    fragment.constantInitializer2 = node.defaultClause?.value2;
    if (node.functionTypedSuffix case var functionTypedSuffix?) {
      for (var formalParameter
          in functionTypedSuffix.formalParameters.allFormalParameters) {
        formalParameter.declaredFragment!.initElement();
      }
    }
    node.declaredFragment = fragment;
  }

  IntegerLiteral _createIntegerLiteral(String lexeme, int value) {
    var node = IntegerLiteralImpl(
      // TODO(srawlins): TokenType.INT_WITH_SEPARATORS?
      literal: TokenFactory.tokenFromTypeAndString(TokenType.INT, lexeme),
      value: value,
    );
    _readExpressionResolution(node);
    return node;
  }

  AdjacentStrings _readAdjacentStrings() {
    var components = _readNodeList<StringLiteralImpl>();
    var node = AdjacentStringsImpl(strings: components);
    _readExpressionResolution(node);
    return node;
  }

  Annotation _readAnnotation() {
    var name = _readNode() as IdentifierImpl;
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;
    var constructorName = _readOptionalNode() as SimpleIdentifierImpl?;
    var arguments = _readOptionalNode() as ArgumentListImpl?;
    var node = AnnotationImpl(
      atSign: Tokens.at(),
      name: name,
      typeArguments: typeArguments,
      period: constructorName != null ? Tokens.period() : null,
      constructorName: constructorName,
      arguments: arguments,
    );
    node.element = _reader.readElement();
    if (arguments != null) {
      _resolveArguments(node.element, arguments);
    }
    return node;
  }

  ArgumentList _readArgumentList() {
    var arguments = _readNodeList<ArgumentImpl>();

    return ArgumentListImpl(
      leftParenthesis: Tokens.openParenthesis(),
      arguments2: arguments,
      rightParenthesis: Tokens.closeParenthesis(),
    );
  }

  AsExpression _readAsExpression() {
    var expression = _readNode() as ExpressionImpl;
    var type = _readNode() as TypeAnnotationImpl;
    var node = AsExpressionImpl(
      expression2: expression,
      asOperator: Tokens.as_(),
      type: type,
    );
    _readExpressionResolution(node);
    return node;
  }

  AssertInitializer _readAssertInitializer() {
    var condition = _readNode() as ExpressionImpl;
    var message = _readOptionalNode() as ExpressionImpl?;
    return AssertInitializerImpl(
      assertKeyword: Tokens.assert_(),
      leftParenthesis: Tokens.openParenthesis(),
      condition2: condition,
      comma: message != null ? Tokens.comma() : null,
      message2: message,
      rightParenthesis: Tokens.closeParenthesis(),
    );
  }

  AssignmentExpression _readAssignmentExpression() {
    var leftHandSide = _readNode() as ExpressionImpl;
    var rightHandSide = _readNode() as ExpressionImpl;
    var operatorType = _reader.readEnum(UnlinkedTokenType.values);
    var node = AssignmentExpressionImpl(
      leftHandSide2: leftHandSide,
      operator: Tokens.fromType(operatorType),
      rightHandSide2: rightHandSide,
    );
    node.element = _reader.readElement() as InternalMethodElement?;
    _readExpressionResolution(node);
    return node;
  }

  AwaitExpression _readAwaitExpression() {
    var expression = _readNode() as ExpressionImpl;
    return AwaitExpressionImpl(
      awaitKeyword: Tokens.await_(),
      expression2: expression,
    );
  }

  BinaryOperatorInvocation _readBinaryOperatorInvocation() {
    var leftOperand = _readNode() as InstanceReceiverImpl;
    var rightOperand = _readNode() as ExpressionImpl;
    var operatorType = _reader.readEnum(UnlinkedTokenType.values);
    var node = BinaryOperatorInvocationImpl(
      leftOperand: leftOperand,
      operator: Tokens.fromType(operatorType),
      rightOperand: rightOperand,
    );
    node.element = _reader.readElement() as InternalMethodElement?;
    _readExpressionResolution(node);
    return node;
  }

  BooleanLiteral _readBooleanLiteral() {
    var value = _readByte() == 1;
    var node = BooleanLiteralImpl(
      literal: value ? Tokens.true_() : Tokens.false_(),
      value: value,
    );
    _readExpressionResolution(node);
    return node;
  }

  int _readByte() {
    return _reader.readByte();
  }

  CallInvocation _readCallInvocation() {
    var receiver = _readNode() as InstanceReceiverImpl;
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;
    var arguments = _readNode() as ArgumentListImpl;
    var node = CallInvocationImpl(
      receiver: receiver,
      typeArguments: typeArguments,
      argumentList: arguments,
    );
    node.staticInvokeType = _reader.readType();
    node.typeArgumentTypes = _reader.readOptionalTypeList();
    node.resolution = _reader.readOptionalObject(_readInvocationResolution);
    _readExpressionResolution(node);
    return node;
  }

  CascadeExpression _readCascadeExpression() {
    var target = _readNode() as ExpressionImpl;
    var sections = _readNodeList<CascadeSectionImpl>();
    var node = CascadeExpressionImpl(target2: target, sections: sections);
    node.setPseudoExpressionStaticType(target.staticType);
    return node;
  }

  CascadeIndexAssignmentTarget _readCascadeIndexAssignmentTarget() {
    var index = _readNode() as ExpressionImpl;
    var node = CascadeIndexAssignmentTargetImpl(
      leftBracket: Tokens.openSquareBracket(),
      index: index,
      rightBracket: Tokens.closeSquareBracket(),
    );
    node.read = _reader.readOptionalObject(_readIndexReadResolution);
    node.write = _reader.readOptionalObject(_readIndexWriteResolution);
    return node;
  }

  CascadeIndexExpression _readCascadeIndexExpression() {
    var index = _readNode() as ExpressionImpl;
    var node = CascadeIndexExpressionImpl(
      leftBracket: Tokens.openSquareBracket(),
      index: index,
      rightBracket: Tokens.closeSquareBracket(),
    );
    node.resolution = _reader.readOptionalObject(_readIndexReadResolution);
    _readExpressionResolution(node);
    return node;
  }

  CascadeMethodInvocation _readCascadeMethodInvocation() {
    var name = _readStringReference();
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;
    var arguments = _readNode() as ArgumentListImpl;
    var node = CascadeMethodInvocationImpl(
      name: StringToken(TokenType.STRING, name, -1),
      typeArguments: typeArguments,
      argumentList: arguments,
    );
    node.staticInvokeType = _reader.readType();
    node.typeArgumentTypes = _reader.readOptionalTypeList();
    node.resolution = _reader.readOptionalObject(_readInvocationResolution);
    _readExpressionResolution(node);
    return node;
  }

  CascadePropertyAssignmentTarget _readCascadePropertyAssignmentTarget() {
    var propertyName = _readStringReference();
    var node = CascadePropertyAssignmentTargetImpl(
      propertyName: StringToken(TokenType.STRING, propertyName, -1),
    );
    node.read = _reader.readOptionalObject(_readNamedReadResolution);
    node.write = _reader.readOptionalObject(_readNamedWriteResolution);
    return node;
  }

  CascadePropertyExtraction _readCascadePropertyExtraction() {
    var propertyName = _readStringReference();
    var node = CascadePropertyExtractionImpl(
      propertyName: StringToken(TokenType.STRING, propertyName, -1),
    );
    node.resolution = _reader.readOptionalObject(_readNamedReadResolution);
    _readExpressionResolution(node);
    return node;
  }

  CascadeSection _readCascadeSection() {
    var isNullAware = _readByte() == 1;
    var body = _readNode() as ExpressionImpl;
    var operatorType = isNullAware
        ? TokenType.QUESTION_PERIOD_PERIOD
        : TokenType.PERIOD_PERIOD;
    return CascadeSectionImpl(
      operator: body.beginToken.type == operatorType
          ? body.beginToken
          : isNullAware
          ? Tokens.questionPeriodPeriod()
          : Tokens.periodPeriod(),
      body: body,
    );
  }

  CompoundAssignment _readCompoundAssignment() {
    var target = _readNode() as AssignmentTargetImpl;
    var value = _readNode() as ExpressionImpl;
    var operatorType = _reader.readEnum(UnlinkedTokenType.values);
    var node = CompoundAssignmentImpl(
      target: target,
      operator: Tokens.fromType(operatorType),
      value: value,
    );
    node.element = _reader.readElement() as InternalMethodElement?;
    node.operatorResultType = _reader.readType();
    _readExpressionResolution(node);
    return node;
  }

  ConditionalExpression _readConditionalExpression() {
    var condition = _readNode() as ExpressionImpl;
    var thenExpression = _readNode() as ExpressionImpl;
    var elseExpression = _readNode() as ExpressionImpl;
    var node = ConditionalExpressionImpl(
      condition2: condition,
      question: Tokens.question(),
      thenExpression2: thenExpression,
      colon: Tokens.colon(),
      elseExpression2: elseExpression,
    );
    _readExpressionResolution(node);
    return node;
  }

  ConstructorFieldInitializer _readConstructorFieldInitializer() {
    var flags = _readByte();
    var fieldName = _readStringReference();
    var fieldElement = _reader.readElement() as InternalFieldElement?;
    var expression = _readNode() as ExpressionImpl;
    var hasThis = AstBinaryFlags.hasThis(flags);
    return ConstructorFieldInitializerImpl(
      thisKeyword: hasThis ? Tokens.this_() : null,
      period: hasThis ? Tokens.period() : null,
      fieldName2: StringToken(TokenType.STRING, fieldName, -1),
      equals: Tokens.eq(),
      expression2: expression,
    )..fieldElement = fieldElement;
  }

  ConstructorInvocation _readConstructorInvocation() {
    var flags = _readByte();
    var constructorReference = _readNode() as ConstructorReference2Impl;
    var argumentList = _readNode() as ArgumentListImpl;

    var node = ConstructorInvocationImpl(
      keyword: Tokens.choose(
        AstBinaryFlags.isConst(flags),
        Tokens.const_(),
        AstBinaryFlags.isNew(flags),
        Tokens.new_(),
      ),
      constructorReference: constructorReference,
      argumentList: argumentList,
      typeArguments: null,
    );
    _readExpressionResolution(node);
    _resolveArguments(node.constructorReference.element, node.argumentList);
    return node;
  }

  ConstructorReference2Impl _readConstructorReference2() {
    var typeReference = _readNode() as ConstructorTypeReferenceImpl;
    var selector = _readOptionalNode() as ConstructorSelectorImpl?;
    return ConstructorReference2Impl(
      typeReference: typeReference,
      selector: selector,
    )..element = _reader.readElement() as InternalConstructorElement?;
  }

  ConstructorSelectorImpl _readConstructorSelector() {
    var name = _readStringReference();
    return ConstructorSelectorImpl.v2(
      period: Token(TokenType.PERIOD, -1),
      name2: StringToken(TokenType.STRING, name, -1),
    );
  }

  ConstructorTearOffImpl _readConstructorTearOff() {
    var typeReference = _readNode() as ConstructorTypeReferenceImpl;
    var selector = _readNode() as ConstructorSelectorImpl;
    var element = _reader.readElement() as InternalConstructorElement?;
    var node = ConstructorTearOffImpl(
      typeReference: typeReference,
      selector: selector,
    );
    _readExpressionResolution(node);
    node.element = switch ((element, node.staticType)) {
      (
        InternalConstructorElement element,
        FunctionTypeImpl(returnType: InterfaceTypeImpl returnType),
      ) =>
        SubstitutedConstructorElementImpl.from2(
          element.baseElement,
          returnType,
        ),
      _ => element,
    };
    return node;
  }

  ConstructorTypeReferenceImpl _readConstructorTypeReference() {
    var importPrefix = _readOptionalNode() as ImportPrefixReferenceImpl?;
    var name = _readStringReference();
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;
    return ConstructorTypeReferenceImpl(
        importPrefix: importPrefix,
        name: StringToken(TokenType.STRING, name, -1),
        typeArguments: typeArguments,
      )
      ..element = _reader.readElement()
      ..type = _reader.readType();
  }

  Token _readDeclarationName() {
    var name = _reader.readStringReference();
    return StringToken(TokenType.STRING, name, -1);
  }

  DeclaredIdentifier _readDeclaredIdentifier() {
    var flags = _readByte();
    var type = _readOptionalNode() as TypeAnnotationImpl?;
    var name = _readDeclarationName();
    var metadata = _readNodeList<AnnotationImpl>();
    return DeclaredIdentifierImpl(
      comment: null,
      metadata: metadata,
      keyword: Tokens.choose(
        AstBinaryFlags.isConst(flags),
        Tokens.const_(),
        AstBinaryFlags.isFinal(flags),
        Tokens.final_(),
        AstBinaryFlags.isVar(flags),
        Tokens.var_(),
      ),
      type: type,
      name: name,
    );
  }

  DelimitedFormalParametersImpl _readDelimitedFormalParameters() {
    var flags = _readByte();
    var formalParameters = _readNodeList<FormalParameterImpl>();
    var isNamed = AstBinaryFlags.isNamed(flags);
    return DelimitedFormalParametersImpl(
      leftDelimiter: isNamed
          ? Tokens.openCurlyBracket()
          : Tokens.openSquareBracket(),
      formalParameters: formalParameters,
      rightDelimiter: isNamed
          ? Tokens.closeCurlyBracket()
          : Tokens.closeSquareBracket(),
    );
  }

  DirectAssignment _readDirectAssignment() {
    var target = _readNode() as AssignmentTargetImpl;
    var value = _readNode() as ExpressionImpl;
    var node = DirectAssignmentImpl(
      target: target,
      operator: Tokens.fromType(UnlinkedTokenType.EQ),
      value: value,
    );
    _readExpressionResolution(node);
    return node;
  }

  DotShorthandConstructorInvocation _readDotShorthandConstructorInvocation() {
    var flags = _readByte();
    var constructorName = _readNode() as SimpleIdentifierImpl;
    var argumentList = _readNode() as ArgumentListImpl;

    var node = DotShorthandConstructorInvocationImpl(
      constKeyword: AstBinaryFlags.isConst(flags) ? Tokens.const_() : null,
      period: Tokens.period(),
      constructorName: constructorName,
      typeArguments: null,
      argumentList: argumentList,
    )..isDotShorthand = AstBinaryFlags.isDotShorthand(flags);
    _readExpressionResolution(node);
    _resolveArguments(node.constructorName.element, node.argumentList);
    return node;
  }

  DotShorthandInvocation _readDotShorthandInvocation() {
    var flags = _readByte();
    var memberName = _readNode() as SimpleIdentifierImpl;
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;
    var arguments = _readNode() as ArgumentListImpl;
    var node = DotShorthandInvocationImpl(
      period: Tokens.period(),
      memberName: memberName,
      typeArguments: typeArguments,
      argumentList: arguments,
    )..isDotShorthand = AstBinaryFlags.isDotShorthand(flags);
    _readInvocationExpression(node);
    return node;
  }

  DotShorthandMethodInvocation _readDotShorthandMethodInvocation() {
    var flags = _readByte();
    var name = _readStringReference();
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;
    var arguments = _readNode() as ArgumentListImpl;
    var node = DotShorthandMethodInvocationImpl(
      period: Tokens.period(),
      name: StringToken(TokenType.STRING, name, -1),
      typeArguments: typeArguments,
      argumentList: arguments,
    );
    node.staticInvokeType = _reader.readType();
    node.typeArgumentTypes = _reader.readOptionalTypeList();
    node.resolution = _reader.readOptionalObject(_readInvocationResolution);
    node.isDotShorthand = AstBinaryFlags.isDotShorthand(flags);
    _readExpressionResolution(node);
    return node;
  }

  DotShorthandNameExpression _readDotShorthandNameExpression() {
    var flags = _readByte();
    var name = _readStringReference();
    var node = DotShorthandNameExpressionImpl(
      period: Tokens.period(),
      name: StringToken(TokenType.STRING, name, -1),
    );
    node.resolution = _reader.readOptionalObject(_readNamedReadResolution);
    node.isDotShorthand = AstBinaryFlags.isDotShorthand(flags);
    _readExpressionResolution(node);
    return node;
  }

  DotShorthandPropertyAccess _readDotShorthandPropertyAccess() {
    var flags = _readByte();
    var propertyName = _readNode() as SimpleIdentifierImpl;
    var node = DotShorthandPropertyAccessImpl(
      period: Tokens.period(),
      propertyName: propertyName,
    )..isDotShorthand = AstBinaryFlags.isDotShorthand(flags);
    _readExpressionResolution(node);
    return node;
  }

  DottedName _readDottedName() {
    var count = _readUint32();
    var tokens = <Token>[];
    for (var i = 0; i < count; i++) {
      var lexeme = _readStringReference();
      var type = lexeme == '.' ? TokenType.PERIOD : TokenType.IDENTIFIER;
      tokens.add(TokenFactory.tokenFromTypeAndString(type, lexeme));
    }
    return DottedNameImpl(tokens: tokens);
  }

  DoubleLiteral _readDoubleLiteral() {
    var value = _reader.readDouble();
    var node = DoubleLiteralImpl(
      literal: StringToken(
        TokenType.STRING,
        considerCanonicalizeString('$value'),
        -1,
      ),
      value: value,
    );
    _readExpressionResolution(node);
    return node;
  }

  void _readExpressionResolution(ExpressionImpl node) {
    node.setPseudoExpressionStaticType(_reader.readType());
  }

  ExtensionOverride _readExtensionOverride() {
    var importPrefix = _readOptionalNode() as ImportPrefixReferenceImpl?;
    var extensionName = _readStringReference();
    var element = _reader.readElement() as ExtensionElementImpl;
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;
    var argumentList = _readNode() as ArgumentListImpl;
    var node = ExtensionOverrideImpl(
      importPrefix: importPrefix,
      name: StringToken(TokenType.STRING, extensionName, -1),
      element: element,
      argumentList: argumentList,
      typeArguments: typeArguments,
    );
    _readExpressionResolution(node);
    return node;
  }

  FieldFormalParameter _readFieldFormalParameter() {
    var functionTypeParameters = _readOptionalNode() as TypeParameterListImpl?;
    var type = _readOptionalNode() as TypeAnnotationImpl?;
    var functionFormalParameters = _readOptionalFormalParameterList();
    var flags = _readByte();
    var metadata = _readNodeList<AnnotationImpl>();
    var name = _readDeclarationName();
    var kind = _readFormalParameterKind(flags);
    var functionTypedSuffix = functionFormalParameters == null
        ? null
        : FunctionTypedFormalParameterSuffixImpl(
            typeParameters: functionTypeParameters,
            formalParameters: functionFormalParameters,
            question: AstBinaryFlags.formalParameterHasQuestion(flags)
                ? Tokens.question()
                : null,
          );
    var node = FieldFormalParameterImpl(
      comment: null,
      metadata: metadata,
      kind: kind,
      covariantKeyword: AstBinaryFlags.formalParameterIsCovariant(flags)
          ? Tokens.covariant_()
          : null,
      requiredKeyword: _readFormalParameterRequiredKeyword(flags, kind),
      constFinalOrVarKeyword: Tokens.choose(
        AstBinaryFlags.formalParameterIsConst(flags),
        Tokens.const_(),
        AstBinaryFlags.formalParameterIsFinal(flags),
        Tokens.final_(),
        AstBinaryFlags.formalParameterIsVar(flags),
        Tokens.var_(),
      ),
      type: type,
      thisKeyword: Tokens.this_(),
      period: Tokens.period(),
      name: name,
      functionTypedSuffix: functionTypedSuffix,
      defaultClause: _readFormalParameterDefaultClause(flags),
    );
    var fragment = FieldFormalParameterFragmentImpl(
      name: name.lexeme,
      nameOffset: null,
      parameterKind: kind,
      privateName: null,
    );
    _bindFormalParameterFragment(node, fragment);
    return node;
  }

  ForEachPartsWithDeclaration _readForEachPartsWithDeclaration() {
    var loopVariable = _readNode() as DeclaredIdentifierImpl;
    var iterable = _readNode() as ExpressionImpl;
    return ForEachPartsWithDeclarationImpl(
      inKeyword: Tokens.in_(),
      iterable2: iterable,
      loopVariable: loopVariable,
    );
  }

  ForElement _readForElement() {
    var flags = _readByte();
    var forLoopParts = _readNode() as ForLoopPartsImpl;
    var body = _readNode() as CollectionElementImpl;
    return ForElementImpl(
      awaitKeyword: AstBinaryFlags.hasAwait(flags) ? Tokens.await_() : null,
      body2: body,
      forKeyword: Tokens.for_(),
      forLoopParts: forLoopParts,
      leftParenthesis: Tokens.openParenthesis(),
      rightParenthesis: Tokens.closeParenthesis(),
    );
  }

  FormalParameterDefaultClauseImpl? _readFormalParameterDefaultClause(
    int flags,
  ) {
    if (!AstBinaryFlags.formalParameterHasInitializer(flags)) {
      return null;
    }
    return FormalParameterDefaultClauseImpl(
      separator: Tokens.colon(),
      value2: _readNode() as ExpressionImpl,
    );
  }

  ParameterKind _readFormalParameterKind(int flags) {
    if (AstBinaryFlags.formalParameterIsPositional(flags)) {
      return AstBinaryFlags.formalParameterIsRequired(flags)
          ? ParameterKind.REQUIRED
          : ParameterKind.POSITIONAL;
    } else {
      return AstBinaryFlags.formalParameterIsRequired(flags)
          ? ParameterKind.NAMED_REQUIRED
          : ParameterKind.NAMED;
    }
  }

  FormalParameterListImpl _readFormalParameterList() {
    var requiredPositionalFormalParameters =
        _readNodeList<FormalParameterImpl>();
    var delimitedFormalParameters =
        _readOptionalNode() as DelimitedFormalParametersImpl?;

    return FormalParameterListImpl(
      leftParenthesis: Tokens.openParenthesis(),
      requiredPositionalFormalParameters: requiredPositionalFormalParameters,
      delimitedFormalParameters: delimitedFormalParameters,
      rightParenthesis: Tokens.closeParenthesis(),
    );
  }

  void _readFormalParameterListResolution(FormalParameterListImpl node) {
    for (var formalParameter in node.allFormalParameters) {
      var fragment = formalParameter.declaredFragment!;
      assert(fragment.nextFragment == null);
      fragment.element.type = _reader.readRequiredType();
      if (formalParameter.functionTypedSuffix case var functionTypedSuffix?) {
        _readFormalParameterListResolution(
          functionTypedSuffix.formalParameters,
        );
      }
    }
  }

  Token? _readFormalParameterRequiredKeyword(int flags, ParameterKind kind) {
    return !kind.isPositional && AstBinaryFlags.formalParameterIsRequired(flags)
        ? Tokens.required_()
        : null;
  }

  ForPartsWithDeclarations _readForPartsWithDeclarations() {
    var variables = _readNode() as VariableDeclarationListImpl;
    var condition = _readOptionalNode() as ExpressionImpl?;
    var updaters = _readNodeList<ExpressionImpl>();
    return ForPartsWithDeclarationsImpl(
      variables: variables,
      condition2: condition,
      leftSeparator: Tokens.semicolon(),
      rightSeparator: Tokens.semicolon(),
      updaters2: updaters,
    );
  }

  ForPartsWithExpression _readForPartsWithExpression() {
    var initialization = _readOptionalNode() as ExpressionImpl?;
    var condition = _readOptionalNode() as ExpressionImpl?;
    var updaters = _readNodeList<ExpressionImpl>();
    return ForPartsWithExpressionImpl(
      condition2: condition,
      initialization2: initialization,
      leftSeparator: Tokens.semicolon(),
      rightSeparator: Tokens.semicolon(),
      updaters2: updaters,
    );
  }

  FunctionReference _readFunctionReference() {
    var function = _readNode() as ExpressionImpl;
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;

    var node = FunctionReferenceImpl(
      function2: function,
      typeArguments: typeArguments,
    );
    node.typeArgumentTypes = _reader.readOptionalTypeList();
    _readExpressionResolution(node);
    return node;
  }

  GenericFunctionType _readGenericFunctionType() {
    var flags = _readByte();
    // TODO(scheglov): add type parameters to locals
    var typeParameters = _readOptionalNode() as TypeParameterListImpl?;
    var returnType = _readOptionalNode() as TypeAnnotationImpl?;
    var formalParameters = _readRequiredFormalParameterList();
    var node = GenericFunctionTypeImpl(
      returnType: returnType,
      functionKeyword: Tokens.function(),
      typeParameters: typeParameters,
      parameters: formalParameters,
      question: AstBinaryFlags.hasQuestion(flags) ? Tokens.question() : null,
    );
    var type = _reader.readRequiredType() as FunctionTypeImpl;
    node.type = type;

    var fragment = GenericFunctionTypeFragmentImpl();
    fragment.formalParameters = formalParameters.allFormalParameters
        .map((formalParameter) => formalParameter.declaredFragment!)
        .toList();
    node.declaredFragment = fragment;
    _reader.currentLibraryFragment.encloseElement(fragment);

    var element = GenericFunctionTypeElementImpl(fragment);
    element.returnType = type.returnType;
    element.type = type;
    _readFormalParameterListResolution(formalParameters);

    return node;
  }

  IfElement _readIfElement() {
    var expression = _readNode() as ExpressionImpl;
    var thenElement = _readNode() as CollectionElementImpl;
    var elseElement = _readOptionalNode() as CollectionElementImpl?;
    return IfElementImpl(
      expression2: expression,
      caseClause: null,
      elseElement2: elseElement,
      elseKeyword: elseElement != null ? Tokens.else_() : null,
      ifKeyword: Tokens.if_(),
      leftParenthesis: Tokens.openParenthesis(),
      rightParenthesis: Tokens.closeParenthesis(),
      thenElement2: thenElement,
    );
  }

  IfNull _readIfNull() {
    var leftOperand = _readNode() as ExpressionImpl;
    var rightOperand = _readNode() as ExpressionImpl;
    var node = IfNullImpl(
      leftOperand: leftOperand,
      operator: Tokens.questionQuestion(),
      rightOperand: rightOperand,
    );
    _readExpressionResolution(node);
    return node;
  }

  IfNullAssignment _readIfNullAssignment() {
    var target = _readNode() as AssignmentTargetImpl;
    var value = _readNode() as ExpressionImpl;
    var node = IfNullAssignmentImpl(
      target: target,
      operator: Tokens.fromType(UnlinkedTokenType.QUESTION_QUESTION_EQ),
      value: value,
    );
    _readExpressionResolution(node);
    return node;
  }

  ImplicitCallReference _readImplicitCallReference() {
    var expression = _readNode() as ExpressionImpl;
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;
    var typeArgumentTypes = _reader.readOptionalTypeList()!;
    var staticElement = _reader.readElement() as MethodElementImpl;

    var node = ImplicitCallReferenceImpl(
      expression2: expression,
      element: staticElement,
      typeArguments: typeArguments,
      typeArgumentTypes: typeArgumentTypes,
    );
    _readExpressionResolution(node);
    return node;
  }

  ImportPrefixedFunctionInvocation _readImportPrefixedFunctionInvocation() {
    var importPrefix = _readNode() as ImportPrefixReferenceImpl;
    var name = _readStringReference();
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;
    var arguments = _readNode() as ArgumentListImpl;
    var node = ImportPrefixedFunctionInvocationImpl(
      importPrefix: importPrefix,
      name: StringToken(TokenType.STRING, name, -1),
      typeArguments: typeArguments,
      argumentList: arguments,
    );
    node.staticInvokeType = _reader.readType();
    node.typeArgumentTypes = _reader.readOptionalTypeList();
    node.resolution = _reader.readOptionalObject(_readInvocationResolution);
    _readExpressionResolution(node);
    return node;
  }

  ImportPrefixReferenceImpl _readImportPrefixReference() {
    var name = _readStringReference();

    var node = ImportPrefixReferenceImpl(
      name: StringToken(TokenType.STRING, name, -1),
      period: Tokens.period(),
    );
    node.element = _reader.readElement();
    return node;
  }

  void _readIncrementOrDecrementResolution(
    IncrementOrDecrementExpressionImpl node,
  ) {
    node.element = _reader.readElement() as InternalMethodElement?;
    node.operatorResultType = _reader.readType();
    _readExpressionResolution(node);
  }

  IndexExpression _readIndexExpression() {
    var flags = _readByte();
    var target = _readOptionalNode() as ExpressionImpl?;
    var index = _readNode() as ExpressionImpl;
    var node = IndexExpressionImpl(
      target2: target,
      period: AstBinaryFlags.hasPeriod(flags) ? Tokens.periodPeriod() : null,
      question: AstBinaryFlags.hasQuestion(flags) ? Tokens.question() : null,
      leftBracket: Tokens.openSquareBracket(),
      index2: index,
      rightBracket: Tokens.closeSquareBracket(),
    );
    node.element = _reader.readElement() as MethodElement?;
    _readExpressionResolution(node);
    return node;
  }

  IndexReadResolutionImpl _readIndexReadResolution() {
    switch (_reader.readEnum(IndexReadResolutionTag.values)) {
      case IndexReadResolutionTag.dynamic_:
        return const DynamicIndexReadResolutionImpl();
      case IndexReadResolutionTag.invalid:
        return InvalidIndexReadResolutionImpl(
          recovery: _reader.readOptionalObject(
            () => _readIndexReadResolution() as MethodIndexReadResolutionImpl,
          ),
        );
      case IndexReadResolutionTag.method:
        return MethodIndexReadResolutionImpl(
          element: _reader.readElement() as InternalMethodElement,
          type: _reader.readType() as TypeImpl,
        );
    }
  }

  IndexWriteResolutionImpl _readIndexWriteResolution() {
    switch (_reader.readEnum(IndexWriteResolutionTag.values)) {
      case IndexWriteResolutionTag.dynamic_:
        return const DynamicIndexWriteResolutionImpl();
      case IndexWriteResolutionTag.invalid:
        return InvalidIndexWriteResolutionImpl(
          recovery: _reader.readOptionalObject(
            () => _readIndexWriteResolution() as MethodIndexWriteResolutionImpl,
          ),
        );
      case IndexWriteResolutionTag.method:
        return MethodIndexWriteResolutionImpl(
          element: _reader.readElement() as InternalMethodElement,
        );
    }
  }

  IntegerLiteral _readIntegerLiteralNegative() {
    var lexeme = _readStringReference();
    var value = (_readUint32() << 32) | _readUint32();
    return _createIntegerLiteral(lexeme, -value);
  }

  IntegerLiteral _readIntegerLiteralNegative1() {
    var lexeme = _readStringReference();
    var value = _readByte();
    return _createIntegerLiteral(lexeme, -value);
  }

  IntegerLiteral _readIntegerLiteralNull() {
    var lexeme = _readStringReference();
    var node = IntegerLiteralImpl(
      // TODO(srawlins): TokenType.INT_WITH_SEPARATORS?
      literal: TokenFactory.tokenFromTypeAndString(TokenType.INT, lexeme),
      value: null,
    );
    _readExpressionResolution(node);
    return node;
  }

  IntegerLiteral _readIntegerLiteralPositive() {
    var lexeme = _readStringReference();
    var value = (_readUint32() << 32) | _readUint32();
    return _createIntegerLiteral(lexeme, value);
  }

  IntegerLiteral _readIntegerLiteralPositive1() {
    var lexeme = _readStringReference();
    var value = _readByte();
    return _createIntegerLiteral(lexeme, value);
  }

  InterpolationExpression _readInterpolationExpression() {
    var flags = _readByte();
    var expression = _readNode() as ExpressionImpl;
    var isIdentifier = AstBinaryFlags.isStringInterpolationIdentifier(flags);
    return InterpolationExpressionImpl(
      leftBracket: isIdentifier
          ? Tokens.stringInterpolationIdentifier()
          : Tokens.stringInterpolationExpression(),
      expression2: expression,
      rightBracket: isIdentifier ? null : Tokens.closeCurlyBracket(),
    );
  }

  InterpolationString _readInterpolationString() {
    var lexeme = _readStringReference();
    var value = _readStringReference();
    return InterpolationStringImpl(
      contents: TokenFactory.tokenFromString(lexeme),
      value: value,
    );
  }

  InvalidExpressionAssignmentTarget _readInvalidExpressionAssignmentTarget() {
    return InvalidExpressionAssignmentTargetImpl(
      expression: _readNode() as ExpressionImpl,
    );
  }

  void _readInvocationExpression(InvocationExpressionImpl node) {
    node.staticInvokeType = _reader.readType();
    node.typeArgumentTypes = _reader.readOptionalTypeList();
    _readExpressionResolution(node);
  }

  InvocationResolutionImpl _readInvocationResolution() {
    var tag = _reader.readEnum(InvocationResolutionTag.values);
    switch (tag) {
      case InvocationResolutionTag.dynamic_:
        return DynamicInvocationResolutionImpl(
          type: _reader.readRequiredType(),
        );
      case InvocationResolutionTag.executable:
        return ExecutableInvocationResolutionImpl(
          element: _reader.readElement() as InternalExecutableElement,
          invokeType: _reader.readRequiredType() as FunctionTypeImpl,
          type: _reader.readRequiredType(),
        );
      case InvocationResolutionTag.functionCall:
        return FunctionCallInvocationResolutionImpl(
          invokeType: _reader.readRequiredType() as FunctionTypeImpl,
          type: _reader.readRequiredType(),
        );
      case InvocationResolutionTag.functionInterface:
        return FunctionInterfaceInvocationResolutionImpl(
          type: _reader.readRequiredType(),
        );
      case InvocationResolutionTag.functionType:
        return FunctionTypeInvocationResolutionImpl(
          invokeType: _reader.readRequiredType() as FunctionTypeImpl,
          type: _reader.readRequiredType(),
        );
      case InvocationResolutionTag.invalid:
        var type = _reader.readRequiredType();
        var candidates = _reader.readElementList<Element>();
        var recovery = _reader.readOptionalObject(() {
          return _readInvocationResolution() as ValidInvocationResolutionImpl;
        });
        return InvalidInvocationResolutionImpl(
          candidates: candidates,
          recovery: recovery,
          type: type,
        );
    }
  }

  IsExpression _readIsExpression() {
    var flags = _readByte();
    var expression = _readNode() as ExpressionImpl;
    var type = _readNode() as TypeAnnotationImpl;
    var node = IsExpressionImpl(
      expression2: expression,
      isOperator: Tokens.is_(),
      notOperator: AstBinaryFlags.hasNot(flags) ? Tokens.bang() : null,
      type: type,
    );
    _readExpressionResolution(node);
    return node;
  }

  ListLiteral _readListLiteral() {
    var flags = _readByte();
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;
    var elements = _readNodeList<CollectionElementImpl>();

    var node = ListLiteralImpl(
      constKeyword: AstBinaryFlags.isConst(flags) ? Tokens.const_() : null,
      typeArguments: typeArguments,
      leftBracket: Tokens.openSquareBracket(),
      elements2: elements,
      rightBracket: Tokens.closeSquareBracket(),
    );
    _readExpressionResolution(node);
    return node;
  }

  LogicalAnd _readLogicalAnd() {
    var leftOperand = _readNode() as ExpressionImpl;
    var rightOperand = _readNode() as ExpressionImpl;
    var node = LogicalAndImpl(
      leftOperand: leftOperand,
      operator: Tokens.ampersandAmpersand(),
      rightOperand: rightOperand,
    );
    _readExpressionResolution(node);
    return node;
  }

  LogicalNot _readLogicalNot() {
    var operand = _readNode() as ExpressionImpl;
    var node = LogicalNotImpl(operator: Tokens.bang(), operand: operand);
    _readExpressionResolution(node);
    return node;
  }

  LogicalOr _readLogicalOr() {
    var leftOperand = _readNode() as ExpressionImpl;
    var rightOperand = _readNode() as ExpressionImpl;
    var node = LogicalOrImpl(
      leftOperand: leftOperand,
      operator: Tokens.barBar(),
      rightOperand: rightOperand,
    );
    _readExpressionResolution(node);
    return node;
  }

  MapLiteralEntry _readMapLiteralEntry() {
    var keyFlags = _readByte();
    var key = _readNode() as ExpressionImpl;
    var valueFlags = _readByte();
    var value = _readNode() as ExpressionImpl;
    return MapLiteralEntryImpl(
      keyQuestion: AstBinaryFlags.hasQuestion(keyFlags)
          ? Tokens.question()
          : null,
      key2: key,
      separator: Tokens.colon(),
      valueQuestion: AstBinaryFlags.hasQuestion(valueFlags)
          ? Tokens.question()
          : null,
      value2: value,
    );
  }

  MethodInvocation _readMethodInvocation() {
    var flags = _readByte();
    var target = _readOptionalNode() as ExpressionImpl?;
    var methodName = _readNode() as SimpleIdentifierImpl;
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;
    var arguments = _readNode() as ArgumentListImpl;

    Token? operator;
    if (AstBinaryFlags.hasQuestion(flags)) {
      operator = AstBinaryFlags.hasPeriod(flags)
          ? Tokens.questionPeriod()
          : Tokens.questionPeriodPeriod();
    } else if (AstBinaryFlags.hasPeriod(flags)) {
      operator = Tokens.period();
    } else if (AstBinaryFlags.hasPeriod2(flags)) {
      operator = Tokens.periodPeriod();
    }

    var node = MethodInvocationImpl(
      target2: target,
      operator: operator,
      methodName: methodName,
      typeArguments: typeArguments,
      argumentList: arguments,
    );
    _readInvocationExpression(node);
    return node;
  }

  NamedArgument _readNamedArgument() {
    var name = _readStringReference();
    var argumentExpression = _readNode() as ExpressionImpl;
    return NamedArgumentImpl(
      name: StringToken(TokenType.STRING, name, -1),
      colon: Tokens.colon(),
      argumentExpression2: argumentExpression,
    );
  }

  NamedReadResolutionImpl _readNamedReadResolution() {
    switch (_reader.readEnum(NamedReadResolutionTag.values)) {
      case NamedReadResolutionTag.dynamicPropertyRead:
        return DynamicPropertyReadResolutionImpl();
      case NamedReadResolutionTag.executableTearOff:
        return ExecutableTearOffResolutionImpl(
          element: _reader.readElement() as InternalExecutableElement,
        );
      case NamedReadResolutionTag.functionCallTearOff:
        return FunctionCallTearOffResolutionImpl(
          type: _reader.readRequiredType(),
          associatedFunctionType:
              _reader.readRequiredType() as FunctionTypeImpl,
        );
      case NamedReadResolutionTag.functionInterfaceCallTearOff:
        return FunctionInterfaceCallTearOffResolutionImpl(
          type: _reader.readRequiredType(),
        );
      case NamedReadResolutionTag.getterInvocation:
        return GetterInvocationResolutionImpl(
          element: _reader.readElement() as InternalGetterElement,
          type: _reader.readRequiredType(),
        );
      case NamedReadResolutionTag.invalid:
        var type = _reader.readRequiredType();
        var candidates = _reader.readElementList<Element>();
        var recovery = _reader.readOptionalObject(() {
          return _readNamedReadResolution()
              as NamedReadResolutionWithElementImpl;
        });
        return InvalidNamedReadResolutionImpl(
          candidates: candidates,
          recovery: recovery,
          type: type,
        );
      case NamedReadResolutionTag.recordFieldRead:
        return RecordFieldReadResolutionImpl(type: _reader.readRequiredType());
      case NamedReadResolutionTag.variableRead:
        return VariableReadResolutionImpl(
          element: _reader.readElement() as InternalVariableElement,
          type: _reader.readRequiredType(),
        );
    }
  }

  NamedType _readNamedType() {
    var flags = _readByte();
    var importPrefix = _readOptionalNode() as ImportPrefixReferenceImpl?;
    var name = _readStringReference();
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;

    var node = NamedTypeImpl(
      importPrefix: importPrefix,
      name: StringToken(TokenType.STRING, name, -1),
      typeArguments: typeArguments,
      question: AstBinaryFlags.hasQuestion(flags) ? Tokens.question() : null,
    );
    node.element = _reader.readElement();
    node.type = _reader.readType();
    return node;
  }

  NamedWriteResolutionImpl _readNamedWriteResolution() {
    switch (_reader.readEnum(NamedWriteResolutionTag.values)) {
      case NamedWriteResolutionTag.invalid:
        var acceptedType = _reader.readType()!;
        var candidates = _reader.readElementList<Element>();
        var recovery = _reader.readOptionalObject(() {
          return _readNamedWriteResolution()
              as NamedWriteResolutionWithElementImpl;
        });
        return InvalidNamedWriteResolutionImpl(
          acceptedType: acceptedType,
          candidates: candidates,
          recovery: recovery,
        );
      case NamedWriteResolutionTag.setterInvocation:
        return SetterInvocationResolutionImpl(
          element: _reader.readElement() as InternalSetterElement,
        );
      case NamedWriteResolutionTag.variableWrite:
        return VariableWriteResolutionImpl(
          element: _reader.readElement() as InternalVariableElement,
          acceptedType: _reader.readType()!,
        );
      case NamedWriteResolutionTag.dynamicPropertyWrite:
        return const DynamicPropertyWriteResolutionImpl();
    }
  }

  AstNode _readNode() {
    var tag = _reader.readEnum(AstNodeTag.values);
    switch (tag) {
      case AstNodeTag.AdjacentStrings:
        return _readAdjacentStrings();
      case AstNodeTag.Annotation:
        return _readAnnotation();
      case AstNodeTag.ArgumentList:
        return _readArgumentList();
      case AstNodeTag.AsExpression:
        return _readAsExpression();
      case AstNodeTag.AssertInitializer:
        return _readAssertInitializer();
      case AstNodeTag.AssignmentExpression:
        return _readAssignmentExpression();
      case AstNodeTag.CompoundAssignment:
        return _readCompoundAssignment();
      case AstNodeTag.DirectAssignment:
        return _readDirectAssignment();
      case AstNodeTag.IfNullAssignment:
        return _readIfNullAssignment();
      case AstNodeTag.InvalidExpressionAssignmentTarget:
        return _readInvalidExpressionAssignmentTarget();
      case AstNodeTag.AwaitExpression:
        return _readAwaitExpression();
      case AstNodeTag.BinaryOperatorInvocation:
        return _readBinaryOperatorInvocation();
      case AstNodeTag.BooleanLiteral:
        return _readBooleanLiteral();
      case AstNodeTag.CascadeExpression:
        return _readCascadeExpression();
      case AstNodeTag.CascadeIndexAssignmentTarget:
        return _readCascadeIndexAssignmentTarget();
      case AstNodeTag.CascadeIndexExpression:
        return _readCascadeIndexExpression();
      case AstNodeTag.CascadeMethodInvocation:
        return _readCascadeMethodInvocation();
      case AstNodeTag.CascadePropertyAssignmentTarget:
        return _readCascadePropertyAssignmentTarget();
      case AstNodeTag.CascadePropertyExtraction:
        return _readCascadePropertyExtraction();
      case AstNodeTag.CascadeSection:
        return _readCascadeSection();
      case AstNodeTag.ConditionalExpression:
        return _readConditionalExpression();
      case AstNodeTag.ConstructorFieldInitializer:
        return _readConstructorFieldInitializer();
      case AstNodeTag.ConstructorTearOff:
        return _readConstructorTearOff();
      case AstNodeTag.ConstructorReference2:
        return _readConstructorReference2();
      case AstNodeTag.ConstructorSelector:
        return _readConstructorSelector();
      case AstNodeTag.ConstructorTypeReference:
        return _readConstructorTypeReference();
      case AstNodeTag.DeclaredIdentifier:
        return _readDeclaredIdentifier();
      case AstNodeTag.DelimitedFormalParameters:
        return _readDelimitedFormalParameters();
      case AstNodeTag.DotShorthandConstructorInvocation:
        return _readDotShorthandConstructorInvocation();
      case AstNodeTag.DotShorthandInvocation:
        return _readDotShorthandInvocation();
      case AstNodeTag.DotShorthandPropertyAccess:
        return _readDotShorthandPropertyAccess();
      case AstNodeTag.DottedName:
        return _readDottedName();
      case AstNodeTag.DoubleLiteral:
        return _readDoubleLiteral();
      case AstNodeTag.ExtensionOverride:
        return _readExtensionOverride();
      case AstNodeTag.ForEachPartsWithDeclaration:
        return _readForEachPartsWithDeclaration();
      case AstNodeTag.ForElement:
        return _readForElement();
      case AstNodeTag.ForPartsWithDeclarations:
        return _readForPartsWithDeclarations();
      case AstNodeTag.ForPartsWithExpression:
        return _readForPartsWithExpression();
      case AstNodeTag.FieldFormalParameter:
        return _readFieldFormalParameter();
      case AstNodeTag.FormalParameterList:
        return _readFormalParameterList();
      case AstNodeTag.CallInvocation:
        return _readCallInvocation();
      case AstNodeTag.FunctionReference:
        return _readFunctionReference();
      case AstNodeTag.GenericFunctionType:
        return _readGenericFunctionType();
      case AstNodeTag.RegularFormalParameter:
        return _readRegularFormalParameter();
      case AstNodeTag.IfElement:
        return _readIfElement();
      case AstNodeTag.ImplicitCallReference:
        return _readImplicitCallReference();
      case AstNodeTag.ImportPrefixReference:
        return _readImportPrefixReference();
      case AstNodeTag.ImportPrefixedFunctionInvocation:
        return _readImportPrefixedFunctionInvocation();
      case AstNodeTag.IndexExpression:
        return _readIndexExpression();
      case AstNodeTag.ReceiverIndexExpression:
        return _readReceiverIndexExpression();
      case AstNodeTag.ReceiverIndexAssignmentTarget:
        return _readReceiverIndexAssignmentTarget();
      case AstNodeTag.ReceiverMethodInvocation:
        return _readReceiverMethodInvocation();
      case AstNodeTag.DotShorthandMethodInvocation:
        return _readDotShorthandMethodInvocation();
      case AstNodeTag.DotShorthandNameExpression:
        return _readDotShorthandNameExpression();
      case AstNodeTag.IntegerLiteralNegative1:
        return _readIntegerLiteralNegative1();
      case AstNodeTag.IntegerLiteralNull:
        return _readIntegerLiteralNull();
      case AstNodeTag.IntegerLiteralPositive1:
        return _readIntegerLiteralPositive1();
      case AstNodeTag.IntegerLiteralPositive:
        return _readIntegerLiteralPositive();
      case AstNodeTag.IntegerLiteralNegative:
        return _readIntegerLiteralNegative();
      case AstNodeTag.InterpolationExpression:
        return _readInterpolationExpression();
      case AstNodeTag.InterpolationString:
        return _readInterpolationString();
      case AstNodeTag.IsExpression:
        return _readIsExpression();
      case AstNodeTag.IfNull:
        return _readIfNull();
      case AstNodeTag.ListLiteral:
        return _readListLiteral();
      case AstNodeTag.LogicalAnd:
        return _readLogicalAnd();
      case AstNodeTag.MapLiteralEntry:
        return _readMapLiteralEntry();
      case AstNodeTag.MethodInvocation:
        return _readMethodInvocation();
      case AstNodeTag.LogicalNot:
        return _readLogicalNot();
      case AstNodeTag.LogicalOr:
        return _readLogicalOr();
      case AstNodeTag.NamedArgument:
        return _readNamedArgument();
      case AstNodeTag.NullAwareElement:
        return _readNullAwareElement();
      case AstNodeTag.NullAssertionExpression:
        return _readNullAssertionExpression();
      case AstNodeTag.NullLiteral:
        return _readNullLiteral();
      case AstNodeTag.ConstructorInvocation:
        return _readConstructorInvocation();
      case AstNodeTag.ParenthesizedExpression:
        return _readParenthesizedExpression();
      case AstNodeTag.PostfixDecrement:
        return _readPostfixDecrement();
      case AstNodeTag.PostfixIncrement:
        return _readPostfixIncrement();
      case AstNodeTag.PrefixDecrement:
        return _readPrefixDecrement();
      case AstNodeTag.PrefixIncrement:
        return _readPrefixIncrement();
      case AstNodeTag.PrefixedIdentifier:
        return _readPrefixedIdentifier();
      case AstNodeTag.PropertyAccess:
        return _readPropertyAccess();
      case AstNodeTag.ReceiverPropertyAssignmentTarget:
        return _readReceiverPropertyAssignmentTarget();
      case AstNodeTag.ReceiverPropertyExtraction:
        return _readReceiverPropertyExtraction();
      case AstNodeTag.RecordLiteral:
        return _readRecordLiteral();
      case AstNodeTag.RecordLiteralNamedField:
        return _readRecordLiteralNamedField();
      case AstNodeTag.RecordTypeAnnotation:
        return _readRecordTypeAnnotation();
      case AstNodeTag.RecordTypeAnnotationNamedField:
        return _readRecordTypeAnnotationNamedField();
      case AstNodeTag.RecordTypeAnnotationNamedFields:
        return _readRecordTypeAnnotationNamedFields();
      case AstNodeTag.RecordTypeAnnotationPositionalField:
        return _readRecordTypeAnnotationPositionalField();
      case AstNodeTag.RedirectingConstructorInvocation:
        return _readRedirectingConstructorInvocation();
      case AstNodeTag.SetOrMapLiteral:
        return _readSetOrMapLiteral();
      case AstNodeTag.SimpleIdentifier:
        return _readSimpleIdentifier();
      case AstNodeTag.SimpleStringLiteral:
        return _readSimpleStringLiteral();
      case AstNodeTag.SpreadElement:
        return _readSpreadElement();
      case AstNodeTag.StringInterpolation:
        return _readStringInterpolation();
      case AstNodeTag.SuperConstructorInvocation:
        return _readSuperConstructorInvocation();
      case AstNodeTag.SuperExpression:
        return _readSuperExpression();
      case AstNodeTag.SuperFormalParameter:
        return _readSuperFormalParameter();
      case AstNodeTag.SymbolLiteral:
        return _readSymbolLiteral();
      case AstNodeTag.ThisExpression:
        return _readThisExpression();
      case AstNodeTag.ThrowExpression:
        return _readThrowExpression();
      case AstNodeTag.TypeArgumentList:
        return _readTypeArgumentList();
      case AstNodeTag.TypeLiteral:
        return _readTypeLiteral();
      case AstNodeTag.NamedType:
        return _readNamedType();
      case AstNodeTag.TypeParameter:
        return _readTypeParameter();
      case AstNodeTag.TypeParameterList:
        return _readTypeParameterList();
      case AstNodeTag.UnqualifiedNameAssignmentTarget:
        return _readUnqualifiedNameAssignmentTarget();
      case AstNodeTag.UnqualifiedFunctionInvocation:
        return _readUnqualifiedFunctionInvocation();
      case AstNodeTag.UnaryOperatorInvocation:
        return _readUnaryOperatorInvocation();
      case AstNodeTag.VariableDeclaration:
        return _readVariableDeclaration();
      case AstNodeTag.VariableDeclarationList:
        return _readVariableDeclarationList();
    }
  }

  List<T> _readNodeList<T>() {
    var length = _reader.readUint30();
    return List.generate(length, (_) => _readNode() as T);
  }

  NullAssertionExpression _readNullAssertionExpression() {
    var operand = _readNode() as ExpressionImpl;
    var node = NullAssertionExpressionImpl(
      operand: operand,
      operator: Tokens.bang(),
    );
    _readExpressionResolution(node);
    return node;
  }

  NullAwareElement _readNullAwareElement() {
    var value = _readNode() as ExpressionImpl;
    return NullAwareElementImpl(question: Tokens.question(), value2: value);
  }

  NullLiteral _readNullLiteral() {
    var node = NullLiteralImpl(literal: Tokens.null_());
    _readExpressionResolution(node);
    return node;
  }

  FormalParameterListImpl? _readOptionalFormalParameterList() {
    return _readOptionalNode() as FormalParameterListImpl?;
  }

  AstNode? _readOptionalNode() {
    return _reader.readOptionalObject(_readNode);
  }

  ParenthesizedExpression _readParenthesizedExpression() {
    var expression = _readNode() as ExpressionImpl;
    var node = ParenthesizedExpressionImpl(
      leftParenthesis: Tokens.openParenthesis(),
      expression2: expression,
      rightParenthesis: Tokens.closeParenthesis(),
    );
    _readExpressionResolution(node);
    return node;
  }

  PostfixDecrement _readPostfixDecrement() {
    var target = _readNode() as AssignmentTargetImpl;
    var node = PostfixDecrementImpl(
      target: target,
      operator: Tokens.fromType(UnlinkedTokenType.MINUS_MINUS),
    );
    _readIncrementOrDecrementResolution(node);
    return node;
  }

  PostfixIncrement _readPostfixIncrement() {
    var target = _readNode() as AssignmentTargetImpl;
    var node = PostfixIncrementImpl(
      target: target,
      operator: Tokens.fromType(UnlinkedTokenType.PLUS_PLUS),
    );
    _readIncrementOrDecrementResolution(node);
    return node;
  }

  PrefixDecrement _readPrefixDecrement() {
    var target = _readNode() as AssignmentTargetImpl;
    var node = PrefixDecrementImpl(
      operator: Tokens.fromType(UnlinkedTokenType.MINUS_MINUS),
      target: target,
    );
    _readIncrementOrDecrementResolution(node);
    return node;
  }

  PrefixedIdentifierImpl _readPrefixedIdentifier() {
    var prefix = _readNode() as SimpleIdentifierImpl;
    var identifier = _readNode() as SimpleIdentifierImpl;
    var node = PrefixedIdentifierImpl(
      prefix: prefix,
      period: Tokens.period(),
      identifier: identifier,
    );
    _readExpressionResolution(node);
    return node;
  }

  PrefixIncrement _readPrefixIncrement() {
    var target = _readNode() as AssignmentTargetImpl;
    var node = PrefixIncrementImpl(
      operator: Tokens.fromType(UnlinkedTokenType.PLUS_PLUS),
      target: target,
    );
    _readIncrementOrDecrementResolution(node);
    return node;
  }

  PropertyAccess _readPropertyAccess() {
    var flags = _readByte();
    var target = _readOptionalNode() as ExpressionImpl?;
    var propertyName = _readNode() as SimpleIdentifierImpl;

    Token operator;
    if (AstBinaryFlags.hasQuestion(flags)) {
      operator = AstBinaryFlags.hasPeriod(flags)
          ? Tokens.questionPeriod()
          : Tokens.questionPeriodPeriod();
    } else {
      operator = AstBinaryFlags.hasPeriod(flags)
          ? Tokens.period()
          : Tokens.periodPeriod();
    }

    var node = PropertyAccessImpl(
      target2: target,
      operator: operator,
      propertyName: propertyName,
    );
    _readExpressionResolution(node);
    return node;
  }

  ReceiverIndexAssignmentTarget _readReceiverIndexAssignmentTarget() {
    var flags = _readByte();
    var receiver = _readNode() as ExpressionImpl;
    var index = _readNode() as ExpressionImpl;
    var node = ReceiverIndexAssignmentTargetImpl(
      receiver: receiver,
      question: AstBinaryFlags.hasQuestion(flags) ? Tokens.question() : null,
      leftBracket: Tokens.openSquareBracket(),
      index: index,
      rightBracket: Tokens.closeSquareBracket(),
    );
    node.read = _reader.readOptionalObject(_readIndexReadResolution);
    node.write = _reader.readOptionalObject(_readIndexWriteResolution);
    return node;
  }

  ReceiverIndexExpression _readReceiverIndexExpression() {
    var flags = _readByte();
    var receiver = _readNode() as ExpressionImpl;
    var index = _readNode() as ExpressionImpl;
    var node = ReceiverIndexExpressionImpl(
      receiver: receiver,
      question: AstBinaryFlags.hasQuestion(flags) ? Tokens.question() : null,
      leftBracket: Tokens.openSquareBracket(),
      index: index,
      rightBracket: Tokens.closeSquareBracket(),
    );
    node.resolution = _reader.readOptionalObject(_readIndexReadResolution);
    _readExpressionResolution(node);
    return node;
  }

  ReceiverMethodInvocation _readReceiverMethodInvocation() {
    var receiver = _readNode() as ExpressionImpl;
    var operatorType = UnlinkedTokenType.values[_readByte()];
    var name = _readStringReference();
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;
    var arguments = _readNode() as ArgumentListImpl;
    var node = ReceiverMethodInvocationImpl(
      receiver: receiver,
      operator: Tokens.fromType(operatorType),
      name: StringToken(TokenType.STRING, name, -1),
      typeArguments: typeArguments,
      argumentList: arguments,
    );
    node.staticInvokeType = _reader.readType();
    node.typeArgumentTypes = _reader.readOptionalTypeList();
    node.resolution = _reader.readOptionalObject(_readInvocationResolution);
    _readExpressionResolution(node);
    return node;
  }

  ReceiverPropertyAssignmentTarget _readReceiverPropertyAssignmentTarget() {
    var receiver = _readNode() as ExpressionImpl;
    var operatorType = _reader.readEnum(UnlinkedTokenType.values);
    var propertyName = _readStringReference();
    var node = ReceiverPropertyAssignmentTargetImpl(
      receiver: receiver,
      operator: Tokens.fromType(operatorType),
      propertyName: StringToken(TokenType.STRING, propertyName, -1),
    );
    node.read = _reader.readOptionalObject(_readNamedReadResolution);
    node.write = _reader.readOptionalObject(_readNamedWriteResolution);
    return node;
  }

  ReceiverPropertyExtraction _readReceiverPropertyExtraction() {
    var receiver = _readNode() as ExpressionImpl;
    var operatorType = _reader.readEnum(UnlinkedTokenType.values);
    var propertyName = _readStringReference();
    var node = ReceiverPropertyExtractionImpl(
      receiver: receiver,
      operator: Tokens.fromType(operatorType),
      propertyName: StringToken(TokenType.STRING, propertyName, -1),
    );
    node.resolution = _reader.readOptionalObject(_readNamedReadResolution);
    _readExpressionResolution(node);
    return node;
  }

  RecordLiteralImpl _readRecordLiteral() {
    var flags = _readByte();
    var fields = _readNodeList<RecordLiteralFieldImpl>();
    var node = RecordLiteralImpl(
      constKeyword: AstBinaryFlags.isConst(flags) ? Tokens.const_() : null,
      leftParenthesis: Tokens.openParenthesis(),
      fields2: fields,
      rightParenthesis: Tokens.closeParenthesis(),
    );
    _readExpressionResolution(node);
    return node;
  }

  RecordLiteralNamedField _readRecordLiteralNamedField() {
    var name = _readStringReference();
    var fieldExpression = _readNode() as ExpressionImpl;
    return RecordLiteralNamedFieldImpl(
      name: StringToken(TokenType.STRING, name, -1),
      colon: Tokens.colon(),
      fieldExpression2: fieldExpression,
    );
  }

  RecordTypeAnnotationImpl _readRecordTypeAnnotation() {
    var flags = _readByte();
    var positionalFields =
        _readNodeList<RecordTypeAnnotationPositionalFieldImpl>();
    var namedFields =
        _readOptionalNode() as RecordTypeAnnotationNamedFieldsImpl?;

    var node = RecordTypeAnnotationImpl(
      leftParenthesis: Tokens.openParenthesis(),
      positionalFields: positionalFields,
      namedFields: namedFields,
      rightParenthesis: Tokens.closeParenthesis(),
      question: AstBinaryFlags.hasQuestion(flags) ? Tokens.question() : null,
    );
    node.type = _reader.readType();
    return node;
  }

  RecordTypeAnnotationNamedFieldImpl _readRecordTypeAnnotationNamedField() {
    var metadata = _readNodeList<AnnotationImpl>();
    var type = _readNode() as TypeAnnotationImpl;

    var lexeme = _reader.readStringReference();
    var name = TokenFactory.tokenFromString(lexeme);

    return RecordTypeAnnotationNamedFieldImpl(
      metadata: metadata,
      type: type,
      name: name,
    );
  }

  RecordTypeAnnotationNamedFieldsImpl _readRecordTypeAnnotationNamedFields() {
    var fields = _readNodeList<RecordTypeAnnotationNamedFieldImpl>();
    return RecordTypeAnnotationNamedFieldsImpl(
      leftBracket: Tokens.openCurlyBracket(),
      fields: fields,
      rightBracket: Tokens.closeCurlyBracket(),
    );
  }

  RecordTypeAnnotationPositionalFieldImpl
  _readRecordTypeAnnotationPositionalField() {
    var metadata = _readNodeList<AnnotationImpl>();
    var type = _readNode() as TypeAnnotationImpl;

    var name = _reader.readOptionalObject(() {
      var lexeme = _reader.readStringReference();
      return TokenFactory.tokenFromString(lexeme);
    });

    return RecordTypeAnnotationPositionalFieldImpl(
      metadata: metadata,
      type: type,
      name: name,
    );
  }

  RedirectingConstructorInvocation _readRedirectingConstructorInvocation() {
    var constructorSelector = _readOptionalNode() as ConstructorSelectorImpl?;
    var argumentList = _readNode() as ArgumentListImpl;
    var node = RedirectingConstructorInvocationImpl(
      thisKeyword: Tokens.this_(),
      constructorSelector: constructorSelector,
      argumentList: argumentList,
    );
    node.element = _reader.readElement() as ConstructorElementImpl?;
    node.constructorName?.element = node.element;
    _resolveArguments(node.element, node.argumentList);
    return node;
  }

  RegularFormalParameter _readRegularFormalParameter() {
    var functionTypeParameters = _readOptionalNode() as TypeParameterListImpl?;
    var type = _readOptionalNode() as TypeAnnotationImpl?;
    var functionFormalParameters = _readOptionalFormalParameterList();
    var flags = _readByte();
    var metadata = _readNodeList<AnnotationImpl>();
    var name = AstBinaryFlags.formalParameterHasName(flags)
        ? _readDeclarationName()
        : null;
    var kind = _readFormalParameterKind(flags);
    var functionTypedSuffix = functionFormalParameters == null
        ? null
        : FunctionTypedFormalParameterSuffixImpl(
            typeParameters: functionTypeParameters,
            formalParameters: functionFormalParameters,
            question: AstBinaryFlags.formalParameterHasQuestion(flags)
                ? Tokens.question()
                : null,
          );

    var node = RegularFormalParameterImpl(
      comment: null,
      metadata: metadata,
      kind: kind,
      covariantKeyword: AstBinaryFlags.formalParameterIsCovariant(flags)
          ? Tokens.covariant_()
          : null,
      constFinalOrVarKeyword: Tokens.choose(
        AstBinaryFlags.formalParameterIsConst(flags),
        Tokens.const_(),
        AstBinaryFlags.formalParameterIsFinal(flags),
        Tokens.final_(),
        AstBinaryFlags.formalParameterIsVar(flags),
        Tokens.var_(),
      ),
      type: type,
      name: name,
      functionTypedSuffix: functionTypedSuffix,
      defaultClause: _readFormalParameterDefaultClause(flags),
      requiredKeyword: _readFormalParameterRequiredKeyword(flags, kind),
    );
    var fragment = FormalParameterFragmentImpl(
      name: name?.lexeme,
      nameOffset: null,
      parameterKind: kind,
    );
    _bindFormalParameterFragment(node, fragment);

    return node;
  }

  FormalParameterListImpl _readRequiredFormalParameterList() {
    return _readNode() as FormalParameterListImpl;
  }

  SetOrMapLiteral _readSetOrMapLiteral() {
    var flags = _readByte();
    var isMapOrSetBits = _readByte();
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;
    var elements = _readNodeList<CollectionElementImpl>();
    var node = SetOrMapLiteralImpl(
      constKeyword: AstBinaryFlags.isConst(flags) ? Tokens.const_() : null,
      elements2: elements,
      leftBracket: Tokens.openCurlyBracket(),
      typeArguments: typeArguments,
      rightBracket: Tokens.closeCurlyBracket(),
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

  SimpleIdentifier _readSimpleIdentifier() {
    var name = _readStringReference();
    var node = SimpleIdentifierImpl(
      token: StringToken(TokenType.STRING, name, -1),
    );
    node.element = _reader.readElement();
    node.tearOffTypeArgumentTypes = _reader.readOptionalTypeList();
    _readExpressionResolution(node);
    return node;
  }

  SimpleStringLiteral _readSimpleStringLiteral() {
    var lexeme = _readStringReference();
    var value = _readStringReference();

    var node = SimpleStringLiteralImpl(
      literal: TokenFactory.tokenFromString(lexeme),
      value: value,
    );
    _readExpressionResolution(node);
    return node;
  }

  SpreadElement _readSpreadElement() {
    var flags = _readByte();
    var expression = _readNode() as ExpressionImpl;
    return SpreadElementImpl(
      spreadOperator: AstBinaryFlags.hasQuestion(flags)
          ? Tokens.periodPeriodPeriodQuestion()
          : Tokens.periodPeriodPeriod(),
      expression2: expression,
    );
  }

  StringInterpolation _readStringInterpolation() {
    var elements = _readNodeList<InterpolationElementImpl>();
    var node = StringInterpolationImpl(elements: elements);
    _readExpressionResolution(node);
    return node;
  }

  String _readStringReference() {
    return _reader.readStringReference();
  }

  SuperConstructorInvocation _readSuperConstructorInvocation() {
    var constructorSelector = _readOptionalNode() as ConstructorSelectorImpl?;
    var argumentList = _readNode() as ArgumentListImpl;
    var node = SuperConstructorInvocationImpl(
      superKeyword: Tokens.super_(),
      constructorSelector: constructorSelector,
      argumentList: argumentList,
    );
    node.element = _reader.readElement() as InternalConstructorElement?;
    node.constructorName?.element = node.element;
    _resolveArguments(node.element, node.argumentList);
    return node;
  }

  SuperExpression _readSuperExpression() {
    var node = SuperExpressionImpl(superKeyword: Tokens.super_());
    _readExpressionResolution(node);
    return node;
  }

  SuperFormalParameter _readSuperFormalParameter() {
    var functionTypeParameters = _readOptionalNode() as TypeParameterListImpl?;
    var type = _readOptionalNode() as TypeAnnotationImpl?;
    var functionFormalParameters = _readOptionalFormalParameterList();
    var flags = _readByte();
    var metadata = _readNodeList<AnnotationImpl>();
    var name = _readDeclarationName();
    var kind = _readFormalParameterKind(flags);
    var functionTypedSuffix = functionFormalParameters == null
        ? null
        : FunctionTypedFormalParameterSuffixImpl(
            typeParameters: functionTypeParameters,
            formalParameters: functionFormalParameters,
            question: AstBinaryFlags.formalParameterHasQuestion(flags)
                ? Tokens.question()
                : null,
          );

    var node = SuperFormalParameterImpl(
      comment: null,
      metadata: metadata,
      kind: kind,
      covariantKeyword: AstBinaryFlags.formalParameterIsCovariant(flags)
          ? Tokens.covariant_()
          : null,
      requiredKeyword: _readFormalParameterRequiredKeyword(flags, kind),
      constFinalOrVarKeyword: Tokens.choose(
        AstBinaryFlags.formalParameterIsConst(flags),
        Tokens.const_(),
        AstBinaryFlags.formalParameterIsFinal(flags),
        Tokens.final_(),
        AstBinaryFlags.formalParameterIsVar(flags),
        Tokens.var_(),
      ),
      type: type,
      superKeyword: Tokens.super_(),
      period: Tokens.period(),
      name: name,
      functionTypedSuffix: functionTypedSuffix,
      defaultClause: _readFormalParameterDefaultClause(flags),
    );
    var fragment = SuperFormalParameterFragmentImpl(
      name: name.lexeme,
      nameOffset: null,
      parameterKind: kind,
    );
    _bindFormalParameterFragment(node, fragment);

    return node;
  }

  SymbolLiteral _readSymbolLiteral() {
    var components = _reader
        .readStringReferenceList()
        .map(TokenFactory.tokenFromString)
        .toList();
    var node = SymbolLiteralImpl(
      poundSign: Tokens.hash(),
      components: components,
    );
    _readExpressionResolution(node);
    return node;
  }

  ThisExpression _readThisExpression() {
    var node = ThisExpressionImpl(thisKeyword: Tokens.this_());
    _readExpressionResolution(node);
    return node;
  }

  ThrowExpression _readThrowExpression() {
    var expression = _readNode() as ExpressionImpl;
    var node = ThrowExpressionImpl(
      throwKeyword: Tokens.throw_(),
      expression2: expression,
    );
    _readExpressionResolution(node);
    return node;
  }

  TypeArgumentListImpl _readTypeArgumentList() {
    var arguments = _readNodeList<TypeAnnotationImpl>();
    return TypeArgumentListImpl(
      leftBracket: Tokens.lt(),
      arguments: arguments,
      rightBracket: Tokens.gt(),
    );
  }

  TypeLiteral _readTypeLiteral() {
    var typeName = _readNode() as NamedTypeImpl;
    var node = TypeLiteralImpl(type: typeName);
    _readExpressionResolution(node);
    return node;
  }

  TypeParameter _readTypeParameter() {
    var name = _readDeclarationName();
    var bound = _readOptionalNode() as TypeAnnotationImpl?;
    var metadata = _readNodeList<AnnotationImpl>();

    var node = TypeParameterImpl(
      comment: null,
      metadata: metadata,
      varianceKeyword: null,
      name: name,
      extendsKeyword: bound != null ? Tokens.extends_() : null,
      bound: bound,
    );

    return node;
  }

  TypeParameterList _readTypeParameterList() {
    var typeParameters = _readNodeList<TypeParameterImpl>();
    return TypeParameterListImpl(
      leftBracket: Tokens.lt(),
      typeParameters: typeParameters,
      rightBracket: Tokens.gt(),
    );
  }

  int _readUint32() {
    return _reader.readUint32();
  }

  UnaryOperatorInvocation _readUnaryOperatorInvocation() {
    var operatorType = _reader.readEnum(UnlinkedTokenType.values);
    var operand = _readNode() as InstanceReceiverImpl;
    var node = UnaryOperatorInvocationImpl(
      operator: Tokens.fromType(operatorType),
      operand: operand,
    );
    _readExpressionResolution(node);
    node.element = _reader.readElement() as InternalMethodElement?;
    return node;
  }

  UnqualifiedFunctionInvocation _readUnqualifiedFunctionInvocation() {
    var name = _readStringReference();
    var typeArguments = _readOptionalNode() as TypeArgumentListImpl?;
    var arguments = _readNode() as ArgumentListImpl;
    var node = UnqualifiedFunctionInvocationImpl(
      name: StringToken(TokenType.STRING, name, -1),
      typeArguments: typeArguments,
      argumentList: arguments,
    );
    node.staticInvokeType = _reader.readType();
    node.typeArgumentTypes = _reader.readOptionalTypeList();
    node.resolution = _reader.readOptionalObject(_readInvocationResolution);
    _readExpressionResolution(node);
    return node;
  }

  UnqualifiedNameAssignmentTarget _readUnqualifiedNameAssignmentTarget() {
    var name = _readStringReference();
    var node = UnqualifiedNameAssignmentTargetImpl(
      name: StringToken(TokenType.STRING, name, -1),
    );
    node.read = _reader.readOptionalObject(_readNamedReadResolution);
    node.write = _reader.readOptionalObject(_readNamedWriteResolution);
    return node;
  }

  VariableDeclaration _readVariableDeclaration() {
    var flags = _readByte();
    var name = _readDeclarationName();
    var initializer = _readOptionalNode() as ExpressionImpl?;

    var node = VariableDeclarationImpl(
      comment: null,
      metadata: [],
      name: name,
      equals: Tokens.eq(),
      initializer2: initializer,
    );

    node.hasInitializer = AstBinaryFlags.hasInitializer(flags);

    return node;
  }

  VariableDeclarationList _readVariableDeclarationList() {
    var flags = _readByte();
    var type = _readOptionalNode() as TypeAnnotationImpl?;
    var variables = _readNodeList<VariableDeclarationImpl>();
    var metadata = _readNodeList<AnnotationImpl>();

    return VariableDeclarationListImpl(
      comment: null,
      keyword: Tokens.choose(
        AstBinaryFlags.isConst(flags),
        Tokens.const_(),
        AstBinaryFlags.isFinal(flags),
        Tokens.final_(),
        AstBinaryFlags.isVar(flags),
        Tokens.var_(),
      ),
      lateKeyword: AstBinaryFlags.isLate(flags) ? Tokens.late_() : null,
      metadata: metadata,
      type: type,
      variables: variables,
    );
  }

  void _resolveArguments(Element? executable, ArgumentListImpl argumentList) {
    if (executable is! InternalExecutableElement) {
      return;
    }

    var formalParameters = executable.formalParameters;
    var positionalParameters = <InternalFormalParameterElement>[];
    var namedParameters = <String, InternalFormalParameterElement>{};
    for (var parameter in formalParameters) {
      if (parameter.isNamed) {
        namedParameters[parameter.name ?? ''] = parameter;
      } else {
        positionalParameters.add(parameter);
      }
    }

    var resolved = List<InternalFormalParameterElement?>.filled(
      argumentList.arguments2.length,
      null,
    );
    var positionalIndex = 0;
    for (var i = 0; i < argumentList.arguments2.length; i++) {
      var argument = argumentList.arguments2[i];
      if (argument is NamedArgumentImpl) {
        resolved[i] = namedParameters[argument.name.lexeme];
      } else if (positionalIndex < positionalParameters.length) {
        resolved[i] = positionalParameters[positionalIndex++];
      }
    }
    argumentList.correspondingStaticParameters = resolved;
  }
}
