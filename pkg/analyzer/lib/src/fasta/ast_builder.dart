// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/ast_factory.dart' show AstFactory;
import 'package:analyzer/dart/ast/standard_ast_factory.dart' as standard;
import 'package:analyzer/dart/ast/token.dart' show Token, TokenType;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/ast/ast.dart'
    show
        ClassDeclarationImpl,
        ClassOrMixinDeclarationImpl,
        CompilationUnitImpl,
        MixinDeclarationImpl;
import 'package:analyzer/src/fasta/error_converter.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:front_end/src/fasta/messages.dart'
    show
        LocatedMessage,
        Message,
        messageConstConstructorWithBody,
        messageConstMethod,
        messageConstructorWithReturnType,
        messageConstructorWithTypeParameters,
        messageDirectiveAfterDeclaration,
        messageExpectedStatement,
        messageFieldInitializerOutsideConstructor,
        messageIllegalAssignmentToNonAssignable,
        messageInterpolationInUri,
        messageInvalidSuperInInitializer,
        messageInvalidThisInInitializer,
        messageMissingAssignableSelector,
        messageNativeClauseShouldBeAnnotation,
        messageStaticConstructor,
        messageTypedefNotFunction,
        templateDuplicateLabelInSwitchStatement,
        templateExpectedButGot,
        templateExpectedIdentifier,
        templateExperimentNotEnabled,
        templateUnexpectedToken;
import 'package:front_end/src/fasta/parser.dart'
    show
        Assert,
        FormalParameterKind,
        IdentifierContext,
        MemberKind,
        optional,
        Parser;
import 'package:front_end/src/fasta/problems.dart' show unhandled;
import 'package:front_end/src/fasta/quote.dart';
import 'package:front_end/src/fasta/scanner.dart' hide StringToken;
import 'package:front_end/src/fasta/scanner/token_constants.dart';
import 'package:front_end/src/fasta/source/stack_listener.dart'
    show NullValue, StackListener;
import 'package:front_end/src/scanner/errors.dart' show translateErrorToken;
import 'package:front_end/src/scanner/token.dart'
    show SyntheticStringToken, SyntheticToken;
import 'package:kernel/ast.dart' show AsyncMarker;

const _invalidCollectionElement = const _InvalidCollectionElement._();

/// A parser listener that builds the analyzer's AST structure.
class AstBuilder extends StackListener {
  final AstFactory ast = standard.astFactory;

  final FastaErrorReporter errorReporter;
  final Uri fileUri;
  ScriptTag scriptTag;
  final List<Directive> directives = <Directive>[];
  final List<CompilationUnitMember> declarations = <CompilationUnitMember>[];
  final localDeclarations = <int, AstNode>{};

  @override
  final Uri uri;

  /// The parser that uses this listener, used to parse optional parts, e.g.
  /// `native` support.
  Parser parser;

  /// The class currently being parsed, or `null` if no class is being parsed.
  ClassDeclarationImpl classDeclaration;

  /// The mixin currently being parsed, or `null` if no mixin is being parsed.
  MixinDeclarationImpl mixinDeclaration;

  /// If true, this is building a full AST. Otherwise, only create method
  /// bodies.
  final bool isFullAst;

  /// `true` if the `native` clause is allowed
  /// in class, method, and function declarations.
  ///
  /// This is being replaced by the @native(...) annotation.
  //
  // TODO(danrubel) Move this flag to a better location
  // and should only be true if either:
  // * The current library is a platform library
  // * The current library has an import that uses the scheme "dart-ext".
  bool allowNativeClause = false;

  StringLiteral nativeName;

  bool parseFunctionBodies = true;

  /// `true` if non-nullable behavior is enabled.
  ///
  /// When setting this field, be sure to set `scanner.enableNonNullable`
  /// to the same value.
  bool enableNonNullable = false;

  /// `true` if spread-collections behavior is enabled
  bool enableSpreadCollections = false;

  /// `true` if control-flow-collections behavior is enabled
  bool enableControlFlowCollections = false;

  /// `true` if triple-shift behavior is enabled
  bool enableTripleShift = false;

  FeatureSet _featureSet;

  AstBuilder(ErrorReporter errorReporter, this.fileUri, this.isFullAst,
      [Uri uri])
      : this.errorReporter = new FastaErrorReporter(errorReporter),
        uri = uri ?? fileUri;

  @override
  void addProblem(Message message, int charOffset, int length,
      {bool wasHandled: false, List<LocatedMessage> context}) {
    if (directives.isEmpty &&
        (message.code.analyzerCodes
                ?.contains('NON_PART_OF_DIRECTIVE_IN_PART') ??
            false)) {
      message = messageDirectiveAfterDeclaration;
    }
    errorReporter.reportMessage(message, charOffset, length);
  }

  void beginCascade(Token token) {
    assert(optional('..', token));
    debugEvent("beginCascade");

    Expression expression = pop();
    push(token);
    if (expression is CascadeExpression) {
      push(expression);
    } else {
      push(ast.cascadeExpression(expression, <Expression>[]));
    }
    push(NullValue.CascadeReceiver);
  }

  @override
  void beginClassDeclaration(Token begin, Token abstractToken, Token name) {
    assert(classDeclaration == null && mixinDeclaration == null);
    push(new _Modifiers()..abstractKeyword = abstractToken);
  }

  @override
  void beginCompilationUnit(Token token) {
    push(token);
  }

  @override
  void beginFactoryMethod(
      Token lastConsumed, Token externalToken, Token constToken) {
    push(new _Modifiers()
      ..externalKeyword = externalToken
      ..finalConstOrVarKeyword = constToken);
  }

  @override
  void beginFormalParameter(Token token, MemberKind kind, Token requiredToken,
      Token covariantToken, Token varFinalOrConst) {
    push(new _Modifiers()
      ..covariantKeyword = covariantToken
      ..finalConstOrVarKeyword = varFinalOrConst
      ..requiredToken = requiredToken);
  }

  @override
  void beginFormalParameterDefaultValueExpression() {}

  void beginIfControlFlow(Token ifToken) {
    push(ifToken);
  }

  void beginLiteralString(Token literalString) {
    assert(identical(literalString.kind, STRING_TOKEN));
    debugEvent("beginLiteralString");

    push(literalString);
  }

  @override
  void beginMetadataStar(Token token) {
    debugEvent("beginMetadataStar");
  }

  @override
  void beginMethod(Token externalToken, Token staticToken, Token covariantToken,
      Token varFinalOrConst, Token getOrSet, Token name) {
    _Modifiers modifiers = new _Modifiers();
    if (externalToken != null) {
      assert(externalToken.isModifier);
      modifiers.externalKeyword = externalToken;
    }
    if (staticToken != null) {
      assert(staticToken.isModifier);
      String className = classDeclaration != null
          ? classDeclaration.name.name
          : mixinDeclaration.name.name;
      if (name?.lexeme == className && getOrSet == null) {
        // This error is also reported in OutlineBuilder.beginMethod
        handleRecoverableError(
            messageStaticConstructor, staticToken, staticToken);
      } else {
        modifiers.staticKeyword = staticToken;
      }
    }
    if (covariantToken != null) {
      assert(covariantToken.isModifier);
      modifiers.covariantKeyword = covariantToken;
    }
    if (varFinalOrConst != null) {
      assert(varFinalOrConst.isModifier);
      modifiers.finalConstOrVarKeyword = varFinalOrConst;
    }
    push(modifiers);
  }

  @override
  void beginMixinDeclaration(Token mixinKeyword, Token name) {
    assert(classDeclaration == null && mixinDeclaration == null);
  }

  @override
  void beginNamedMixinApplication(
      Token begin, Token abstractToken, Token name) {
    push(new _Modifiers()..abstractKeyword = abstractToken);
  }

  void beginTopLevelMethod(Token lastConsumed, Token externalToken) {
    push(new _Modifiers()..externalKeyword = externalToken);
  }

  @override
  void beginTypeVariable(Token token) {
    debugEvent("beginTypeVariable");
    SimpleIdentifier name = pop();
    List<Annotation> metadata = pop();

    Comment comment = _findComment(metadata, name.beginToken);
    var typeParameter = ast.typeParameter(comment, metadata, name, null, null);
    localDeclarations[name.offset] = typeParameter;
    push(typeParameter);
  }

  @override
  void beginVariablesDeclaration(
      Token token, Token lateToken, Token varFinalOrConst) {
    debugEvent("beginVariablesDeclaration");
    if (varFinalOrConst != null || lateToken != null) {
      push(new _Modifiers()
        ..finalConstOrVarKeyword = varFinalOrConst
        ..lateToken = lateToken);
    } else {
      push(NullValue.Modifiers);
    }
  }

  void checkFieldFormalParameters(FormalParameterList parameters) {
    if (parameters?.parameters != null) {
      parameters.parameters.forEach((FormalParameter param) {
        if (param is FieldFormalParameter) {
          // This error is reported in the BodyBuilder.endFormalParameter.
          handleRecoverableError(messageFieldInitializerOutsideConstructor,
              param.thisKeyword, param.thisKeyword);
        }
      });
    }
  }

  /// Configures the parser appropriately for the given [featureSet].
  ///
  /// TODO(paulberry): stop exposing `enableNonNullable`,
  /// `enableSpreadCollections`, `enableControlFlowCollections`, and
  /// `enableTripleShift` so that callers are forced to use this API.  Note that
  /// this will not be a breaking change, because this code is in `lib/src`.
  void configureFeatures(FeatureSet featureSet) {
    enableNonNullable = featureSet.isEnabled(Feature.non_nullable);
    enableSpreadCollections = featureSet.isEnabled(Feature.spread_collections);
    enableControlFlowCollections =
        featureSet.isEnabled(Feature.control_flow_collections);
    enableTripleShift = featureSet.isEnabled(Feature.triple_shift);
    _featureSet = featureSet;
  }

  @override
  void debugEvent(String name) {
    // printEvent('AstBuilder: $name');
  }

  @override
  void discardTypeReplacedWithCommentTypeAssign() {
    pop();
  }

  void doDotExpression(Token dot) {
    Expression identifierOrInvoke = pop();
    Expression receiver = pop();
    if (identifierOrInvoke is SimpleIdentifier) {
      if (receiver is SimpleIdentifier && identical('.', dot.stringValue)) {
        push(ast.prefixedIdentifier(receiver, dot, identifierOrInvoke));
      } else {
        push(ast.propertyAccess(receiver, dot, identifierOrInvoke));
      }
    } else if (identifierOrInvoke is MethodInvocation) {
      assert(identifierOrInvoke.target == null);
      identifierOrInvoke
        ..target = receiver
        ..operator = dot;
      push(identifierOrInvoke);
    } else {
      // This same error is reported in BodyBuilder.doDotOrCascadeExpression
      Token token = identifierOrInvoke.beginToken;
      // TODO(danrubel): Consider specializing the error message based
      // upon the type of expression. e.g. "x.this" -> templateThisAsIdentifier
      handleRecoverableError(
          templateExpectedIdentifier.withArguments(token), token, token);
      SimpleIdentifier identifier =
          ast.simpleIdentifier(token, isDeclaration: false);
      push(ast.propertyAccess(receiver, dot, identifier));
    }
  }

  void doInvocation(
      TypeArgumentList typeArguments, MethodInvocation arguments) {
    Expression receiver = pop();
    if (receiver is SimpleIdentifier) {
      arguments.methodName = receiver;
      if (typeArguments != null) {
        arguments.typeArguments = typeArguments;
      }
      push(arguments);
    } else {
      push(ast.functionExpressionInvocation(
          receiver, typeArguments, arguments.argumentList));
    }
  }

  void doPropertyGet() {}

  void endArguments(int count, Token leftParenthesis, Token rightParenthesis) {
    assert(optional('(', leftParenthesis));
    assert(optional(')', rightParenthesis));
    debugEvent("Arguments");

    List<Expression> expressions = popTypedList(count);
    ArgumentList arguments =
        ast.argumentList(leftParenthesis, expressions, rightParenthesis);
    push(ast.methodInvocation(null, null, null, null, arguments));
  }

  @override
  void endAssert(Token assertKeyword, Assert kind, Token leftParenthesis,
      Token comma, Token semicolon) {
    assert(optional('assert', assertKeyword));
    assert(optional('(', leftParenthesis));
    assert(optionalOrNull(',', comma));
    assert(kind != Assert.Statement || optionalOrNull(';', semicolon));
    debugEvent("Assert");

    Expression message = popIfNotNull(comma);
    Expression condition = pop();
    switch (kind) {
      case Assert.Expression:
        // The parser has already reported an error indicating that assert
        // cannot be used in an expression. Insert a placeholder.
        List<Expression> arguments = <Expression>[condition];
        if (message != null) {
          arguments.add(message);
        }
        push(ast.functionExpressionInvocation(
            ast.simpleIdentifier(assertKeyword),
            null,
            ast.argumentList(
                leftParenthesis, arguments, leftParenthesis?.endGroup)));
        break;
      case Assert.Initializer:
        push(ast.assertInitializer(assertKeyword, leftParenthesis, condition,
            comma, message, leftParenthesis?.endGroup));
        break;
      case Assert.Statement:
        push(ast.assertStatement(assertKeyword, leftParenthesis, condition,
            comma, message, leftParenthesis?.endGroup, semicolon));
        break;
    }
  }

  void endAwaitExpression(Token awaitKeyword, Token endToken) {
    assert(optional('await', awaitKeyword));
    debugEvent("AwaitExpression");

    push(ast.awaitExpression(awaitKeyword, pop()));
  }

  @override
  void endBinaryExpression(Token operatorToken) {
    assert(operatorToken.isOperator ||
        optional('.', operatorToken) ||
        optional('?.', operatorToken) ||
        optional('..', operatorToken));
    debugEvent("BinaryExpression");

    if (identical(".", operatorToken.stringValue) ||
        identical("?.", operatorToken.stringValue) ||
        identical("..", operatorToken.stringValue)) {
      doDotExpression(operatorToken);
    } else {
      Expression right = pop();
      Expression left = pop();
      reportErrorIfSuper(right);
      push(ast.binaryExpression(left, operatorToken, right));
      if (!enableTripleShift && operatorToken.type == TokenType.GT_GT_GT) {
        handleRecoverableError(
            templateExperimentNotEnabled
                .withArguments(EnableString.triple_shift),
            operatorToken,
            operatorToken);
      }
    }
  }

  void endBlock(int count, Token leftBracket, Token rightBracket) {
    assert(optional('{', leftBracket));
    assert(optional('}', rightBracket));
    debugEvent("Block");

    List<Statement> statements = popTypedList(count) ?? <Statement>[];
    push(ast.block(leftBracket, statements, rightBracket));
  }

  void endBlockFunctionBody(int count, Token leftBracket, Token rightBracket) {
    assert(optional('{', leftBracket));
    assert(optional('}', rightBracket));
    debugEvent("BlockFunctionBody");

    List<Statement> statements = popTypedList(count);
    Block block = ast.block(leftBracket, statements, rightBracket);
    Token star = pop();
    Token asyncKeyword = pop();
    if (parseFunctionBodies) {
      push(ast.blockFunctionBody(asyncKeyword, star, block));
    } else {
      // TODO(danrubel): Skip the block rather than parsing it.
      push(ast.emptyFunctionBody(
          new SyntheticToken(TokenType.SEMICOLON, leftBracket.charOffset)));
    }
  }

  void endCascade() {
    debugEvent("Cascade");

    Expression expression = pop();
    CascadeExpression receiver = pop();
    pop(); // Token.
    receiver.cascadeSections.add(expression);
    push(receiver);
  }

  @override
  void endClassDeclaration(Token beginToken, Token endToken) {
    debugEvent("ClassDeclaration");
    classDeclaration = null;
  }

  @override
  void endClassOrMixinBody(
      int memberCount, Token leftBracket, Token rightBracket) {
    assert(optional('{', leftBracket));
    assert(optional('}', rightBracket));
    debugEvent("ClassOrMixinBody");

    ClassOrMixinDeclarationImpl declaration =
        classDeclaration ?? mixinDeclaration;
    declaration.leftBracket = leftBracket;
    declaration.rightBracket = rightBracket;
  }

  @override
  void endCombinators(int count) {
    debugEvent("Combinators");
    push(popTypedList<Combinator>(count) ?? NullValue.Combinators);
  }

  @override
  void endCompilationUnit(int count, Token endToken) {
    debugEvent("CompilationUnit");

    Token beginToken = pop();
    checkEmpty(endToken.charOffset);

    CompilationUnitImpl unit = ast.compilationUnit2(
        beginToken: beginToken,
        scriptTag: scriptTag,
        directives: directives,
        declarations: declarations,
        endToken: endToken,
        featureSet: _featureSet) as CompilationUnitImpl;
    push(unit);
  }

  void endConditionalExpression(Token question, Token colon) {
    assert(optional('?', question));
    assert(optional(':', colon));
    debugEvent("ConditionalExpression");

    Expression elseExpression = pop();
    Expression thenExpression = pop();
    Expression condition = pop();
    reportErrorIfSuper(elseExpression);
    reportErrorIfSuper(thenExpression);
    push(ast.conditionalExpression(
        condition, question, thenExpression, colon, elseExpression));
  }

  void endConditionalUri(Token ifKeyword, Token leftParen, Token equalSign) {
    assert(optional('if', ifKeyword));
    assert(optionalOrNull('(', leftParen));
    assert(optionalOrNull('==', equalSign));
    debugEvent("ConditionalUri");

    StringLiteral libraryUri = pop();
    StringLiteral value = popIfNotNull(equalSign);
    if (value is StringInterpolation) {
      for (var child in value.childEntities) {
        if (child is InterpolationExpression) {
          // This error is reported in OutlineBuilder.endLiteralString
          handleRecoverableError(
              messageInterpolationInUri, child.beginToken, child.endToken);
          break;
        }
      }
    }
    DottedName name = pop();
    push(ast.configuration(ifKeyword, leftParen, name, equalSign, value,
        leftParen?.endGroup, libraryUri));
  }

  @override
  void endConditionalUris(int count) {
    debugEvent("ConditionalUris");

    push(popTypedList<Configuration>(count) ?? NullValue.ConditionalUris);
  }

  @override
  void endConstExpression(Token constKeyword) {
    assert(optional('const', constKeyword));
    debugEvent("ConstExpression");

    _handleInstanceCreation(constKeyword);
  }

  @override
  void endConstLiteral(Token token) {
    debugEvent("endConstLiteral");
  }

  @override
  void endConstructorReference(
      Token start, Token periodBeforeName, Token endToken) {
    assert(optionalOrNull('.', periodBeforeName));
    debugEvent("ConstructorReference");

    SimpleIdentifier constructorName = pop();
    TypeArgumentList typeArguments = pop();
    Identifier typeNameIdentifier = pop();
    push(ast.constructorName(ast.typeName(typeNameIdentifier, typeArguments),
        periodBeforeName, constructorName));
  }

  @override
  void endDoWhileStatement(
      Token doKeyword, Token whileKeyword, Token semicolon) {
    assert(optional('do', doKeyword));
    assert(optional('while', whileKeyword));
    assert(optional(';', semicolon));
    debugEvent("DoWhileStatement");

    ParenthesizedExpression condition = pop();
    Statement body = pop();
    push(ast.doStatement(
        doKeyword,
        body,
        whileKeyword,
        condition.leftParenthesis,
        condition.expression,
        condition.rightParenthesis,
        semicolon));
  }

  @override
  void endDoWhileStatementBody(Token token) {
    debugEvent("endDoWhileStatementBody");
  }

  @override
  void endElseStatement(Token token) {
    debugEvent("endElseStatement");
  }

  @override
  void endEnum(Token enumKeyword, Token leftBrace, int count) {
    assert(optional('enum', enumKeyword));
    assert(optional('{', leftBrace));
    debugEvent("Enum");

    List<EnumConstantDeclaration> constants = popTypedList(count);
    SimpleIdentifier name = pop();
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, enumKeyword);
    declarations.add(ast.enumDeclaration(comment, metadata, enumKeyword, name,
        leftBrace, constants, leftBrace?.endGroup));
  }

  void endExport(Token exportKeyword, Token semicolon) {
    assert(optional('export', exportKeyword));
    assert(optional(';', semicolon));
    debugEvent("Export");

    List<Combinator> combinators = pop();
    List<Configuration> configurations = pop();
    StringLiteral uri = pop();
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, exportKeyword);
    directives.add(ast.exportDirective(comment, metadata, exportKeyword, uri,
        configurations, combinators, semicolon));
  }

  @override
  void endFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    assert(optional('factory', factoryKeyword));
    assert(optional(';', endToken) || optional('}', endToken));
    debugEvent("FactoryMethod");

    FunctionBody body;
    Token separator;
    ConstructorName redirectedConstructor;
    Object bodyObject = pop();
    if (bodyObject is FunctionBody) {
      body = bodyObject;
    } else if (bodyObject is _RedirectingFactoryBody) {
      separator = bodyObject.equalToken;
      redirectedConstructor = bodyObject.constructorName;
      body = ast.emptyFunctionBody(endToken);
    } else {
      unhandled("${bodyObject.runtimeType}", "bodyObject",
          beginToken.charOffset, uri);
    }

    FormalParameterList parameters = pop();
    TypeParameterList typeParameters = pop();
    Object constructorName = pop();
    _Modifiers modifiers = pop();
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, beginToken);

    assert(parameters != null);

    if (typeParameters != null) {
      // TODO(danrubel): Update OutlineBuilder to report this error message.
      handleRecoverableError(messageConstructorWithTypeParameters,
          typeParameters.beginToken, typeParameters.endToken);
    }

    // Decompose the preliminary ConstructorName into the type name and
    // the actual constructor name.
    SimpleIdentifier returnType;
    Token period;
    SimpleIdentifier name;
    Identifier typeName = constructorName;
    if (typeName is SimpleIdentifier) {
      returnType = typeName;
    } else if (typeName is PrefixedIdentifier) {
      returnType = typeName.prefix;
      period = typeName.period;
      name =
          ast.simpleIdentifier(typeName.identifier.token, isDeclaration: true);
    }

    (classDeclaration ?? mixinDeclaration).members.add(
        ast.constructorDeclaration(
            comment,
            metadata,
            modifiers?.externalKeyword,
            modifiers?.finalConstOrVarKeyword,
            factoryKeyword,
            ast.simpleIdentifier(returnType.token),
            period,
            name,
            parameters,
            separator,
            null,
            redirectedConstructor,
            body));
  }

  void endFieldInitializer(Token assignment, Token token) {
    assert(optional('=', assignment));
    debugEvent("FieldInitializer");

    Expression initializer = pop();
    SimpleIdentifier name = pop();
    push(_makeVariableDeclaration(name, assignment, initializer));
  }

  @override
  void endFields(Token staticToken, Token covariantToken, Token lateToken,
      Token varFinalOrConst, int count, Token beginToken, Token semicolon) {
    assert(optional(';', semicolon));
    debugEvent("Fields");

    List<VariableDeclaration> variables = popTypedList(count);
    TypeAnnotation type = pop();
    var variableList = ast.variableDeclarationList2(
      lateKeyword: lateToken,
      keyword: varFinalOrConst,
      type: type,
      variables: variables,
    );
    Token covariantKeyword = covariantToken;
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, beginToken);
    (classDeclaration ?? mixinDeclaration).members.add(ast.fieldDeclaration2(
        comment: comment,
        metadata: metadata,
        covariantKeyword: covariantKeyword,
        staticKeyword: staticToken,
        fieldList: variableList,
        semicolon: semicolon));
  }

  @override
  void endForControlFlow(Token token) {
    debugEvent("endForControlFlow");
    var entry = pop();
    ForParts forLoopParts = pop();
    Token leftParen = pop();
    Token forToken = pop();

    pushForControlFlowInfo(null, forToken, leftParen, forLoopParts, entry);
  }

  @override
  void endForIn(Token endToken) {
    debugEvent("ForInExpression");

    Statement body = pop();
    ForEachParts forLoopParts = pop();
    Token leftParenthesis = pop();
    Token forToken = pop();
    Token awaitToken = pop(NullValue.AwaitToken);

    push(ast.forStatement(
      awaitKeyword: awaitToken,
      forKeyword: forToken,
      leftParenthesis: leftParenthesis,
      forLoopParts: forLoopParts,
      rightParenthesis: leftParenthesis.endGroup,
      body: body,
    ));
  }

  @override
  void endForInBody(Token token) {
    debugEvent("endForInBody");
  }

  @override
  void endForInControlFlow(Token token) {
    debugEvent("endForInControlFlow");

    var entry = pop();
    ForEachParts forLoopParts = pop();
    Token leftParenthesis = pop();
    Token forToken = pop();
    Token awaitToken = pop(NullValue.AwaitToken);

    pushForControlFlowInfo(
        awaitToken, forToken, leftParenthesis, forLoopParts, entry);
  }

  @override
  void endForInExpression(Token token) {
    debugEvent("ForInExpression");
  }

  @override
  void endFormalParameter(Token thisKeyword, Token periodAfterThis,
      Token nameToken, FormalParameterKind kind, MemberKind memberKind) {
    assert(optionalOrNull('this', thisKeyword));
    assert(thisKeyword == null
        ? periodAfterThis == null
        : optional('.', periodAfterThis));
    debugEvent("FormalParameter");

    _ParameterDefaultValue defaultValue = pop();
    SimpleIdentifier name = pop();
    AstNode typeOrFunctionTypedParameter = pop();
    _Modifiers modifiers = pop();
    Token keyword = modifiers?.finalConstOrVarKeyword;
    Token covariantKeyword = modifiers?.covariantKeyword;
    Token requiredKeyword = modifiers?.requiredToken;
    if (!enableNonNullable) {
      reportNonNullableModifierError(requiredKeyword);
    }
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata,
        thisKeyword ?? typeOrFunctionTypedParameter?.beginToken ?? nameToken);

    NormalFormalParameter node;
    if (typeOrFunctionTypedParameter is FunctionTypedFormalParameter) {
      // This is a temporary AST node that was constructed in
      // [endFunctionTypedFormalParameter]. We now deconstruct it and create
      // the final AST node.
      if (thisKeyword == null) {
        node = ast.functionTypedFormalParameter2(
            identifier: name,
            comment: comment,
            metadata: metadata,
            covariantKeyword: covariantKeyword,
            requiredKeyword: requiredKeyword,
            returnType: typeOrFunctionTypedParameter.returnType,
            typeParameters: typeOrFunctionTypedParameter.typeParameters,
            parameters: typeOrFunctionTypedParameter.parameters);
      } else {
        node = ast.fieldFormalParameter2(
            identifier: name,
            comment: comment,
            metadata: metadata,
            covariantKeyword: covariantKeyword,
            requiredKeyword: requiredKeyword,
            type: typeOrFunctionTypedParameter.returnType,
            thisKeyword: thisKeyword,
            period: periodAfterThis,
            typeParameters: typeOrFunctionTypedParameter.typeParameters,
            parameters: typeOrFunctionTypedParameter.parameters);
      }
    } else {
      TypeAnnotation type = typeOrFunctionTypedParameter;
      if (thisKeyword == null) {
        node = ast.simpleFormalParameter2(
            comment: comment,
            metadata: metadata,
            covariantKeyword: covariantKeyword,
            requiredKeyword: requiredKeyword,
            keyword: keyword,
            type: type,
            identifier: name);
      } else {
        node = ast.fieldFormalParameter2(
            comment: comment,
            metadata: metadata,
            covariantKeyword: covariantKeyword,
            requiredKeyword: requiredKeyword,
            keyword: keyword,
            type: type,
            thisKeyword: thisKeyword,
            period: thisKeyword.next,
            identifier: name);
      }
    }

    ParameterKind analyzerKind =
        _toAnalyzerParameterKind(kind, requiredKeyword);
    FormalParameter parameter = node;
    if (analyzerKind != ParameterKind.REQUIRED) {
      parameter = ast.defaultFormalParameter(
          node, analyzerKind, defaultValue?.separator, defaultValue?.value);
    } else if (defaultValue != null) {
      // An error is reported if a required parameter has a default value.
      // Record it as named parameter for recovery.
      parameter = ast.defaultFormalParameter(node, ParameterKind.NAMED,
          defaultValue.separator, defaultValue.value);
    }
    localDeclarations[nameToken.offset] = parameter;
    push(parameter);
  }

  @override
  void endFormalParameterDefaultValueExpression() {
    debugEvent("FormalParameterDefaultValueExpression");
  }

  void endFormalParameters(
      int count, Token leftParen, Token rightParen, MemberKind kind) {
    assert(optional('(', leftParen));
    assert(optional(')', rightParen));
    debugEvent("FormalParameters");

    List<Object> rawParameters = popTypedList(count) ?? const <Object>[];
    List<FormalParameter> parameters = <FormalParameter>[];
    Token leftDelimiter;
    Token rightDelimiter;
    for (Object raw in rawParameters) {
      if (raw is _OptionalFormalParameters) {
        parameters.addAll(raw.parameters ?? const <FormalParameter>[]);
        leftDelimiter = raw.leftDelimiter;
        rightDelimiter = raw.rightDelimiter;
      } else {
        parameters.add(raw as FormalParameter);
      }
    }
    push(ast.formalParameterList(
        leftParen, parameters, leftDelimiter, rightDelimiter, rightParen));
  }

  @override
  void endForStatement(Token endToken) {
    debugEvent("ForStatement");
    Statement body = pop();
    ForParts forLoopParts = pop();
    Token leftParen = pop();
    Token forToken = pop();

    push(ast.forStatement(
      forKeyword: forToken,
      leftParenthesis: leftParen,
      forLoopParts: forLoopParts,
      rightParenthesis: leftParen.endGroup,
      body: body,
    ));
  }

  @override
  void endForStatementBody(Token token) {
    debugEvent("endForStatementBody");
  }

  @override
  void endFunctionExpression(Token beginToken, Token token) {
    // TODO(paulberry): set up scopes properly to resolve parameters and type
    // variables.  Note that this is tricky due to the handling of initializers
    // in constructors, so the logic should be shared with BodyBuilder as much
    // as possible.
    debugEvent("FunctionExpression");

    FunctionBody body = pop();
    FormalParameterList parameters = pop();
    TypeParameterList typeParameters = pop();
    push(ast.functionExpression(typeParameters, parameters, body));
  }

  @override
  void endFunctionName(Token beginToken, Token token) {
    debugEvent("FunctionName");
  }

  @override
  void endFunctionType(Token functionToken, Token questionMark) {
    assert(optional('Function', functionToken));
    debugEvent("FunctionType");
    if (!enableNonNullable) {
      reportErrorIfNullableType(questionMark);
    }

    FormalParameterList parameters = pop();
    TypeAnnotation returnType = pop();
    TypeParameterList typeParameters = pop();
    push(ast.genericFunctionType(
        returnType, functionToken, typeParameters, parameters,
        question: questionMark));
  }

  @override
  void endFunctionTypeAlias(
      Token typedefKeyword, Token equals, Token semicolon) {
    assert(optional('typedef', typedefKeyword));
    assert(optionalOrNull('=', equals));
    assert(optional(';', semicolon));
    debugEvent("FunctionTypeAlias");

    if (equals == null) {
      FormalParameterList parameters = pop();
      TypeParameterList typeParameters = pop();
      SimpleIdentifier name = pop();
      TypeAnnotation returnType = pop();
      List<Annotation> metadata = pop();
      Comment comment = _findComment(metadata, typedefKeyword);
      declarations.add(ast.functionTypeAlias(comment, metadata, typedefKeyword,
          returnType, name, typeParameters, parameters, semicolon));
    } else {
      TypeAnnotation type = pop();
      TypeParameterList templateParameters = pop();
      SimpleIdentifier name = pop();
      List<Annotation> metadata = pop();
      Comment comment = _findComment(metadata, typedefKeyword);
      if (type is! GenericFunctionType) {
        // This error is also reported in the OutlineBuilder.
        handleRecoverableError(messageTypedefNotFunction, equals, equals);
        type = null;
      }
      declarations.add(ast.genericTypeAlias(
          comment,
          metadata,
          typedefKeyword,
          name,
          templateParameters,
          equals,
          type as GenericFunctionType,
          semicolon));
    }
  }

  @override
  void endFunctionTypedFormalParameter(Token nameToken) {
    debugEvent("FunctionTypedFormalParameter");

    FormalParameterList formalParameters = pop();
    TypeAnnotation returnType = pop();
    TypeParameterList typeParameters = pop();

    // Create a temporary formal parameter that will be dissected later in
    // [endFormalParameter].
    push(ast.functionTypedFormalParameter2(
        identifier: null,
        returnType: returnType,
        typeParameters: typeParameters,
        parameters: formalParameters));
  }

  @override
  void endHide(Token hideKeyword) {
    assert(optional('hide', hideKeyword));
    debugEvent("Hide");

    List<SimpleIdentifier> hiddenNames = pop();
    push(ast.hideCombinator(hideKeyword, hiddenNames));
  }

  @override
  void endIfControlFlow(Token token) {
    CollectionElement thenElement = pop();
    ParenthesizedExpression condition = pop();
    Token ifToken = pop();
    pushIfControlFlowInfo(ifToken, condition, thenElement, null, null);
  }

  @override
  void endIfElseControlFlow(Token token) {
    CollectionElement elseElement = pop();
    Token elseToken = pop();
    CollectionElement thenElement = pop();
    ParenthesizedExpression condition = pop();
    Token ifToken = pop();
    pushIfControlFlowInfo(
        ifToken, condition, thenElement, elseToken, elseElement);
  }

  void endIfStatement(Token ifToken, Token elseToken) {
    assert(optional('if', ifToken));
    assert(optionalOrNull('else', elseToken));

    Statement elsePart = popIfNotNull(elseToken);
    Statement thenPart = pop();
    ParenthesizedExpression condition = pop();
    push(ast.ifStatement(
        ifToken,
        condition.leftParenthesis,
        condition.expression,
        condition.rightParenthesis,
        thenPart,
        elseToken,
        elsePart));
  }

  @override
  void endImplicitCreationExpression(Token token) {
    debugEvent("ImplicitCreationExpression");

    _handleInstanceCreation(null);
  }

  @override
  void endImport(Token importKeyword, Token semicolon) {
    assert(optional('import', importKeyword));
    assert(optionalOrNull(';', semicolon));
    debugEvent("Import");

    List<Combinator> combinators = pop();
    Token deferredKeyword = pop(NullValue.Deferred);
    Token asKeyword = pop(NullValue.As);
    SimpleIdentifier prefix = pop(NullValue.Prefix);
    List<Configuration> configurations = pop();
    StringLiteral uri = pop();
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, importKeyword);

    directives.add(ast.importDirective(
        comment,
        metadata,
        importKeyword,
        uri,
        configurations,
        deferredKeyword,
        asKeyword,
        prefix,
        combinators,
        semicolon));
  }

  void endInitializedIdentifier(Token nameToken) {
    debugEvent("InitializedIdentifier");

    AstNode node = pop();
    VariableDeclaration variable;
    // TODO(paulberry): This seems kludgy.  It would be preferable if we
    // could respond to a "handleNoVariableInitializer" event by converting a
    // SimpleIdentifier into a VariableDeclaration, and then when this code was
    // reached, node would always be a VariableDeclaration.
    if (node is VariableDeclaration) {
      variable = node;
    } else if (node is SimpleIdentifier) {
      variable = _makeVariableDeclaration(node, null, null);
    } else {
      unhandled("${node.runtimeType}", "identifier", nameToken.charOffset, uri);
    }
    push(variable);
  }

  void endInitializers(int count, Token colon, Token endToken) {
    assert(optional(':', colon));
    debugEvent("Initializers");

    List<Object> initializerObjects = popTypedList(count) ?? const [];
    if (!isFullAst) return;

    push(colon);

    var initializers = <ConstructorInitializer>[];
    for (Object initializerObject in initializerObjects) {
      if (initializerObject is FunctionExpressionInvocation) {
        Expression function = initializerObject.function;
        if (function is SuperExpression) {
          initializers.add(ast.superConstructorInvocation(function.superKeyword,
              null, null, initializerObject.argumentList));
        } else {
          initializers.add(ast.redirectingConstructorInvocation(
              (function as ThisExpression).thisKeyword,
              null,
              null,
              initializerObject.argumentList));
        }
      } else if (initializerObject is MethodInvocation) {
        Expression target = initializerObject.target;
        if (target is SuperExpression) {
          initializers.add(ast.superConstructorInvocation(
              target.superKeyword,
              initializerObject.operator,
              initializerObject.methodName,
              initializerObject.argumentList));
        } else if (target is ThisExpression) {
          initializers.add(ast.redirectingConstructorInvocation(
              target.thisKeyword,
              initializerObject.operator,
              initializerObject.methodName,
              initializerObject.argumentList));
        } else {
          // Recovery: Invalid initializer
          if (target is FunctionExpressionInvocation) {
            var targetFunct = target.function;
            if (targetFunct is SuperExpression) {
              initializers.add(ast.superConstructorInvocation(
                  targetFunct.superKeyword, null, null, target.argumentList));
              // TODO(danrubel): Consider generating this error in the parser
              // This error is also reported in the body builder
              handleRecoverableError(messageInvalidSuperInInitializer,
                  targetFunct.superKeyword, targetFunct.superKeyword);
            } else if (targetFunct is ThisExpression) {
              initializers.add(ast.redirectingConstructorInvocation(
                  targetFunct.thisKeyword, null, null, target.argumentList));
              // TODO(danrubel): Consider generating this error in the parser
              // This error is also reported in the body builder
              handleRecoverableError(messageInvalidThisInInitializer,
                  targetFunct.thisKeyword, targetFunct.thisKeyword);
            } else {
              throw new UnsupportedError(
                  'unsupported initializer $initializerObject');
            }
          } else {
            throw new UnsupportedError(
                'unsupported initializer $initializerObject');
          }
        }
      } else if (initializerObject is AssignmentExpression) {
        Token thisKeyword;
        Token period;
        SimpleIdentifier fieldName;
        Expression left = initializerObject.leftHandSide;
        if (left is PropertyAccess) {
          Expression target = left.target;
          if (target is ThisExpression) {
            thisKeyword = target.thisKeyword;
            period = left.operator;
          } else {
            assert(target is SuperExpression);
            // Recovery:
            // Parser has reported FieldInitializedOutsideDeclaringClass.
          }
          fieldName = left.propertyName;
        } else if (left is SimpleIdentifier) {
          fieldName = left;
        } else {
          // Recovery:
          // Parser has reported invalid assignment.
          SuperExpression superExpression = left;
          fieldName = ast.simpleIdentifier(superExpression.superKeyword);
        }
        initializers.add(ast.constructorFieldInitializer(
            thisKeyword,
            period,
            fieldName,
            initializerObject.operator,
            initializerObject.rightHandSide));
      } else if (initializerObject is AssertInitializer) {
        initializers.add(initializerObject);
      } else if (initializerObject is PropertyAccess) {
        // Recovery: Invalid initializer
        Expression target = initializerObject.target;
        if (target is FunctionExpressionInvocation) {
          var targetFunct = target.function;
          if (targetFunct is SuperExpression) {
            initializers.add(ast.superConstructorInvocation(
                targetFunct.superKeyword, null, null, target.argumentList));
            // TODO(danrubel): Consider generating this error in the parser
            // This error is also reported in the body builder
            handleRecoverableError(messageInvalidSuperInInitializer,
                targetFunct.superKeyword, targetFunct.superKeyword);
          } else if (targetFunct is ThisExpression) {
            initializers.add(ast.redirectingConstructorInvocation(
                targetFunct.thisKeyword, null, null, target.argumentList));
            // TODO(danrubel): Consider generating this error in the parser
            // This error is also reported in the body builder
            handleRecoverableError(messageInvalidThisInInitializer,
                targetFunct.thisKeyword, targetFunct.thisKeyword);
          } else {
            throw new UnsupportedError(
                'unsupported initializer $initializerObject');
          }
        } else {
          throw new UnsupportedError(
              'unsupported initializer $initializerObject');
        }
      } else {
        throw new UnsupportedError('unsupported initializer:'
            ' ${initializerObject.runtimeType} :: $initializerObject');
      }
    }

    push(initializers);
  }

  @override
  void endLabeledStatement(int labelCount) {
    debugEvent("LabeledStatement");

    Statement statement = pop();
    List<Label> labels = popTypedList(labelCount);
    push(ast.labeledStatement(labels, statement));
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    assert(optional('library', libraryKeyword));
    assert(optional(';', semicolon));
    debugEvent("LibraryName");

    List<SimpleIdentifier> libraryName = pop();
    var name = ast.libraryIdentifier(libraryName);
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, libraryKeyword);
    directives.add(ast.libraryDirective(
        comment, metadata, libraryKeyword, name, semicolon));
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    debugEvent("endLiteralString");

    if (interpolationCount == 0) {
      Token token = pop();
      String value = unescapeString(token.lexeme, token, this);
      push(ast.simpleStringLiteral(token, value));
    } else {
      List<Object> parts = popTypedList(1 + interpolationCount * 2);
      Token first = parts.first;
      Token last = parts.last;
      Quote quote = analyzeQuote(first.lexeme);
      List<InterpolationElement> elements = <InterpolationElement>[];
      elements.add(ast.interpolationString(
          first, unescapeFirstStringPart(first.lexeme, quote, first, this)));
      for (int i = 1; i < parts.length - 1; i++) {
        var part = parts[i];
        if (part is Token) {
          elements.add(ast.interpolationString(
              part, unescape(part.lexeme, quote, part, this)));
        } else if (part is InterpolationExpression) {
          elements.add(part);
        } else {
          unhandled("${part.runtimeType}", "string interpolation",
              first.charOffset, uri);
        }
      }
      elements.add(ast.interpolationString(
          last,
          unescapeLastStringPart(
              last.lexeme, quote, last, last.isSynthetic, this)));
      push(ast.stringInterpolation(elements));
    }
  }

  void endLiteralSymbol(Token hashToken, int tokenCount) {
    assert(optional('#', hashToken));
    debugEvent("LiteralSymbol");

    List<Token> components = popTypedList(tokenCount);
    push(ast.symbolLiteral(hashToken, components));
  }

  @override
  void endLocalFunctionDeclaration(Token token) {
    debugEvent("LocalFunctionDeclaration");
    FunctionBody body = pop();
    if (isFullAst) {
      pop(); // constructor initializers
      pop(); // separator before constructor initializers
    }
    FormalParameterList parameters = pop();
    checkFieldFormalParameters(parameters);
    SimpleIdentifier name = pop();
    TypeAnnotation returnType = pop();
    TypeParameterList typeParameters = pop();
    List<Annotation> metadata = pop(NullValue.Metadata);
    FunctionExpression functionExpression =
        ast.functionExpression(typeParameters, parameters, body);
    var functionDeclaration = ast.functionDeclaration(
        null, metadata, null, returnType, null, name, functionExpression);
    localDeclarations[name.offset] = functionDeclaration;
    push(ast.functionDeclarationStatement(functionDeclaration));
  }

  @override
  void endMember() {
    debugEvent("Member");
  }

  @override
  void endMetadata(Token atSign, Token periodBeforeName, Token endToken) {
    assert(optional('@', atSign));
    assert(optionalOrNull('.', periodBeforeName));
    debugEvent("Metadata");

    MethodInvocation invocation = pop();
    SimpleIdentifier constructorName = periodBeforeName != null ? pop() : null;
    pop(); // Type arguments, not allowed.
    Identifier name = pop();
    push(ast.annotation(atSign, name, periodBeforeName, constructorName,
        invocation?.argumentList));
  }

  @override
  void endMetadataStar(int count) {
    debugEvent("MetadataStar");

    push(popTypedList<Annotation>(count) ?? NullValue.Metadata);
  }

  @override
  void endMethod(
      Token getOrSet, Token beginToken, Token beginParam, Token endToken) {
    assert(getOrSet == null ||
        optional('get', getOrSet) ||
        optional('set', getOrSet));
    debugEvent("Method");

    var bodyObject = pop();
    List<ConstructorInitializer> initializers = pop() ?? const [];
    Token separator = pop();
    FormalParameterList parameters = pop();
    TypeParameterList typeParameters = pop();
    var name = pop();
    TypeAnnotation returnType = pop();
    _Modifiers modifiers = pop();
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, beginToken);

    assert(parameters != null || optional('get', getOrSet));

    ConstructorName redirectedConstructor;
    FunctionBody body;
    if (bodyObject is FunctionBody) {
      body = bodyObject;
    } else if (bodyObject is _RedirectingFactoryBody) {
      separator = bodyObject.equalToken;
      redirectedConstructor = bodyObject.constructorName;
      body = ast.emptyFunctionBody(endToken);
    } else {
      unhandled("${bodyObject.runtimeType}", "bodyObject",
          beginToken.charOffset, uri);
    }

    ClassOrMixinDeclarationImpl declaration =
        classDeclaration ?? mixinDeclaration;

    void constructor(
        SimpleIdentifier prefixOrName, Token period, SimpleIdentifier name) {
      if (typeParameters != null) {
        // Outline builder also reports this error message.
        handleRecoverableError(messageConstructorWithTypeParameters,
            typeParameters.beginToken, typeParameters.endToken);
      }
      if (modifiers?.constKeyword != null &&
          body != null &&
          (body.length > 1 || body.beginToken?.lexeme != ';')) {
        // This error is also reported in BodyBuilder.finishFunction
        Token bodyToken = body.beginToken ?? modifiers.constKeyword;
        handleRecoverableError(
            messageConstConstructorWithBody, bodyToken, bodyToken);
      }
      if (returnType != null) {
        // This error is also reported in OutlineBuilder.endMethod
        handleRecoverableError(messageConstructorWithReturnType,
            returnType.beginToken, returnType.beginToken);
      }
      ConstructorDeclaration constructor = ast.constructorDeclaration(
          comment,
          metadata,
          modifiers?.externalKeyword,
          modifiers?.finalConstOrVarKeyword,
          null,
          // TODO(paulberry): factoryKeyword
          ast.simpleIdentifier(prefixOrName.token),
          period,
          name,
          parameters,
          separator,
          initializers,
          redirectedConstructor,
          body);
      declaration.members.add(constructor);
      if (mixinDeclaration != null) {
        // TODO (danrubel): Report an error if this is a mixin declaration.
      }
    }

    void method(Token operatorKeyword, SimpleIdentifier name) {
      if (modifiers?.constKeyword != null &&
          body != null &&
          (body.length > 1 || body.beginToken?.lexeme != ';')) {
        // This error is also reported in OutlineBuilder.endMethod
        handleRecoverableError(
            messageConstMethod, modifiers.constKeyword, modifiers.constKeyword);
      }
      checkFieldFormalParameters(parameters);
      declaration.members.add(ast.methodDeclaration(
          comment,
          metadata,
          modifiers?.externalKeyword,
          modifiers?.abstractKeyword ?? modifiers?.staticKeyword,
          returnType,
          getOrSet,
          operatorKeyword,
          name,
          typeParameters,
          parameters,
          body));
    }

    if (name is SimpleIdentifier) {
      if (name.name == declaration.name.name && getOrSet == null) {
        constructor(name, null, null);
      } else if (initializers.isNotEmpty) {
        constructor(name, null, null);
      } else {
        method(null, name);
      }
    } else if (name is _OperatorName) {
      method(name.operatorKeyword, name.name);
    } else if (name is PrefixedIdentifier) {
      constructor(name.prefix, name.period, name.identifier);
    } else {
      throw new UnimplementedError();
    }
  }

  @override
  void endMixinDeclaration(Token mixinKeyword, Token endToken) {
    debugEvent("MixinDeclaration");
    mixinDeclaration = null;
  }

  @override
  void endNamedFunctionExpression(Token endToken) {
    debugEvent("NamedFunctionExpression");
    FunctionBody body = pop();
    if (isFullAst) {
      pop(); // constructor initializers
      pop(); // separator before constructor initializers
    }
    FormalParameterList parameters = pop();
    pop(); // name
    pop(); // returnType
    TypeParameterList typeParameters = pop();
    push(ast.functionExpression(typeParameters, parameters, body));
  }

  @override
  void endNamedMixinApplication(Token beginToken, Token classKeyword,
      Token equalsToken, Token implementsKeyword, Token semicolon) {
    assert(optional('class', classKeyword));
    assert(optionalOrNull('=', equalsToken));
    assert(optionalOrNull('implements', implementsKeyword));
    assert(optional(';', semicolon));
    debugEvent("NamedMixinApplication");

    ImplementsClause implementsClause;
    if (implementsKeyword != null) {
      List<TypeName> interfaces = pop();
      implementsClause = ast.implementsClause(implementsKeyword, interfaces);
    }
    WithClause withClause = pop(NullValue.WithClause);
    TypeName superclass = pop();
    _Modifiers modifiers = pop();
    TypeParameterList typeParameters = pop();
    SimpleIdentifier name = pop();
    Token abstractKeyword = modifiers?.abstractKeyword;
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, beginToken);
    declarations.add(ast.classTypeAlias(
        comment,
        metadata,
        classKeyword,
        name,
        typeParameters,
        equalsToken,
        abstractKeyword,
        superclass,
        withClause,
        implementsClause,
        semicolon));
  }

  @override
  void endNewExpression(Token newKeyword) {
    assert(optional('new', newKeyword));
    debugEvent("NewExpression");

    _handleInstanceCreation(newKeyword);
  }

  @override
  void endOptionalFormalParameters(
      int count, Token leftDelimeter, Token rightDelimeter) {
    assert((optional('[', leftDelimeter) && optional(']', rightDelimeter)) ||
        (optional('{', leftDelimeter) && optional('}', rightDelimeter)));
    debugEvent("OptionalFormalParameters");

    push(new _OptionalFormalParameters(
        popTypedList(count), leftDelimeter, rightDelimeter));
  }

  @override
  void endPart(Token partKeyword, Token semicolon) {
    assert(optional('part', partKeyword));
    assert(optional(';', semicolon));
    debugEvent("Part");

    StringLiteral uri = pop();
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, partKeyword);
    directives
        .add(ast.partDirective(comment, metadata, partKeyword, uri, semicolon));
  }

  @override
  void endPartOf(
      Token partKeyword, Token ofKeyword, Token semicolon, bool hasName) {
    assert(optional('part', partKeyword));
    assert(optional('of', ofKeyword));
    assert(optional(';', semicolon));
    debugEvent("PartOf");
    var libraryNameOrUri = pop();
    LibraryIdentifier name;
    StringLiteral uri;
    if (libraryNameOrUri is StringLiteral) {
      uri = libraryNameOrUri;
    } else {
      name = ast.libraryIdentifier(libraryNameOrUri as List<SimpleIdentifier>);
    }
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, partKeyword);
    directives.add(ast.partOfDirective(
        comment, metadata, partKeyword, ofKeyword, uri, name, semicolon));
  }

  @override
  void endRedirectingFactoryBody(Token equalToken, Token endToken) {
    assert(optional('=', equalToken));
    debugEvent("RedirectingFactoryBody");

    ConstructorName constructorName = pop();
    Token starToken = pop();
    Token asyncToken = pop();
    push(new _RedirectingFactoryBody(
        asyncToken, starToken, equalToken, constructorName));
  }

  @override
  void endRethrowStatement(Token rethrowToken, Token semicolon) {
    assert(optional('rethrow', rethrowToken));
    assert(optional(';', semicolon));
    debugEvent("RethrowStatement");

    RethrowExpression expression = ast.rethrowExpression(rethrowToken);
    // TODO(scheglov) According to the specification, 'rethrow' is a statement.
    push(ast.expressionStatement(expression, semicolon));
  }

  void endReturnStatement(
      bool hasExpression, Token returnKeyword, Token semicolon) {
    assert(optional('return', returnKeyword));
    assert(optional(';', semicolon));
    debugEvent("ReturnStatement");

    Expression expression = hasExpression ? pop() : null;
    push(ast.returnStatement(returnKeyword, expression, semicolon));
  }

  @override
  void endShow(Token showKeyword) {
    assert(optional('show', showKeyword));
    debugEvent("Show");

    List<SimpleIdentifier> shownNames = pop();
    push(ast.showCombinator(showKeyword, shownNames));
  }

  @override
  void endSwitchBlock(int caseCount, Token leftBracket, Token rightBracket) {
    assert(optional('{', leftBracket));
    assert(optional('}', rightBracket));
    debugEvent("SwitchBlock");

    List<List<SwitchMember>> membersList = popTypedList(caseCount);
    List<SwitchMember> members =
        membersList?.expand((members) => members)?.toList() ?? <SwitchMember>[];

    Set<String> labels = new Set<String>();
    for (SwitchMember member in members) {
      for (Label label in member.labels) {
        if (!labels.add(label.label.name)) {
          handleRecoverableError(
              templateDuplicateLabelInSwitchStatement
                  .withArguments(label.label.name),
              label.beginToken,
              label.beginToken);
        }
      }
    }

    push(leftBracket);
    push(members);
    push(rightBracket);
  }

  @override
  void endSwitchCase(
      int labelCount,
      int expressionCount,
      Token defaultKeyword,
      Token colonAfterDefault,
      int statementCount,
      Token firstToken,
      Token endToken) {
    assert(optionalOrNull('default', defaultKeyword));
    assert(defaultKeyword == null
        ? colonAfterDefault == null
        : optional(':', colonAfterDefault));
    debugEvent("SwitchCase");

    List<Statement> statements = popTypedList(statementCount);
    List<SwitchMember> members;

    if (labelCount == 0 && defaultKeyword == null) {
      // Common situation: case with no default and no labels.
      members = popTypedList<SwitchMember>(expressionCount) ?? [];
    } else {
      // Labels and case statements may be intertwined
      if (defaultKeyword != null) {
        SwitchDefault member = ast.switchDefault(
            <Label>[], defaultKeyword, colonAfterDefault, <Statement>[]);
        while (peek() is Label) {
          member.labels.insert(0, pop());
          --labelCount;
        }
        members = new List<SwitchMember>(expressionCount + 1);
        members[expressionCount] = member;
      } else {
        members = new List<SwitchMember>(expressionCount);
      }
      for (int index = expressionCount - 1; index >= 0; --index) {
        SwitchMember member = pop();
        while (peek() is Label) {
          member.labels.insert(0, pop());
          --labelCount;
        }
        members[index] = member;
      }
      assert(labelCount == 0);
    }
    if (members.isNotEmpty) {
      members.last.statements.addAll(statements);
    }
    push(members);
  }

  @override
  void endSwitchStatement(Token switchKeyword, Token endToken) {
    assert(optional('switch', switchKeyword));
    debugEvent("SwitchStatement");

    Token rightBracket = pop();
    List<SwitchMember> members = pop();
    Token leftBracket = pop();
    ParenthesizedExpression expression = pop();
    push(ast.switchStatement(
        switchKeyword,
        expression.leftParenthesis,
        expression.expression,
        expression.rightParenthesis,
        leftBracket,
        members,
        rightBracket));
  }

  @override
  void endThenStatement(Token token) {
    debugEvent("endThenStatement");
  }

  @override
  void endTopLevelDeclaration(Token token) {
    debugEvent("TopLevelDeclaration");
  }

  void endTopLevelFields(
      Token staticToken,
      Token covariantToken,
      Token lateToken,
      Token varFinalOrConst,
      int count,
      Token beginToken,
      Token semicolon) {
    assert(optional(';', semicolon));
    debugEvent("TopLevelFields");

    List<VariableDeclaration> variables = popTypedList(count);
    TypeAnnotation type = pop();
    var variableList = ast.variableDeclarationList2(
      lateKeyword: lateToken,
      keyword: varFinalOrConst,
      type: type,
      variables: variables,
    );
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, beginToken);
    declarations.add(ast.topLevelVariableDeclaration(
        comment, metadata, variableList, semicolon));
  }

  void endTopLevelMethod(Token beginToken, Token getOrSet, Token endToken) {
    // TODO(paulberry): set up scopes properly to resolve parameters and type
    // variables.
    assert(getOrSet == null ||
        optional('get', getOrSet) ||
        optional('set', getOrSet));
    debugEvent("TopLevelMethod");

    FunctionBody body = pop();
    FormalParameterList parameters = pop();
    TypeParameterList typeParameters = pop();
    SimpleIdentifier name = pop();
    TypeAnnotation returnType = pop();
    _Modifiers modifiers = pop();
    Token externalKeyword = modifiers?.externalKeyword;
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, beginToken);
    declarations.add(ast.functionDeclaration(
        comment,
        metadata,
        externalKeyword,
        returnType,
        getOrSet,
        name,
        ast.functionExpression(typeParameters, parameters, body)));
  }

  void endTryStatement(int catchCount, Token tryKeyword, Token finallyKeyword) {
    assert(optional('try', tryKeyword));
    assert(optionalOrNull('finally', finallyKeyword));
    debugEvent("TryStatement");

    Block finallyBlock = popIfNotNull(finallyKeyword);
    List<CatchClause> catchClauses = popTypedList(catchCount);
    Block body = pop();
    push(ast.tryStatement(
        tryKeyword, body, catchClauses, finallyKeyword, finallyBlock));
  }

  @override
  void endTypeArguments(int count, Token leftBracket, Token rightBracket) {
    assert(optional('<', leftBracket));
    assert(optional('>', rightBracket));
    debugEvent("TypeArguments");

    List<TypeAnnotation> arguments = popTypedList(count);
    push(ast.typeArgumentList(leftBracket, arguments, rightBracket));
  }

  @override
  void endTypeList(int count) {
    debugEvent("TypeList");
    push(popTypedList<TypeName>(count) ?? NullValue.TypeList);
  }

  @override
  void endTypeVariable(Token token, int index, Token extendsOrSuper) {
    debugEvent("TypeVariable");
    assert(extendsOrSuper == null ||
        optional('extends', extendsOrSuper) ||
        optional('super', extendsOrSuper));
    TypeAnnotation bound = pop();

    // Peek to leave type parameters on top of stack.
    List<TypeParameter> typeParameters = peek();
    typeParameters[index]
      ..extendsKeyword = extendsOrSuper
      ..bound = bound;
  }

  @override
  void endTypeVariables(Token beginToken, Token endToken) {
    assert(optional('<', beginToken));
    assert(optional('>', endToken));
    debugEvent("TypeVariables");

    List<TypeParameter> typeParameters = pop();
    push(ast.typeParameterList(beginToken, typeParameters, endToken));
  }

  void endVariableInitializer(Token assignmentOperator) {
    assert(optionalOrNull('=', assignmentOperator));
    debugEvent("VariableInitializer");

    Expression initializer = pop();
    SimpleIdentifier identifier = pop();
    // TODO(ahe): Don't push initializers, instead install them.
    push(_makeVariableDeclaration(identifier, assignmentOperator, initializer));
  }

  @override
  void endVariablesDeclaration(int count, Token semicolon) {
    assert(optionalOrNull(';', semicolon));
    debugEvent("VariablesDeclaration");

    List<VariableDeclaration> variables = popTypedList(count);
    _Modifiers modifiers = pop(NullValue.Modifiers);
    TypeAnnotation type = pop();
    Token keyword = modifiers?.finalConstOrVarKeyword;
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata,
        variables[0].beginToken ?? type?.beginToken ?? modifiers.beginToken);
    push(ast.variableDeclarationStatement(
        ast.variableDeclarationList2(
          comment: comment,
          metadata: metadata,
          lateKeyword: modifiers?.lateToken,
          keyword: keyword,
          type: type,
          variables: variables,
        ),
        semicolon));
  }

  @override
  void endWhileStatement(Token whileKeyword, Token endToken) {
    assert(optional('while', whileKeyword));
    debugEvent("WhileStatement");

    Statement body = pop();
    ParenthesizedExpression condition = pop();
    push(ast.whileStatement(whileKeyword, condition.leftParenthesis,
        condition.expression, condition.rightParenthesis, body));
  }

  @override
  void endWhileStatementBody(Token token) {
    debugEvent("endWhileStatementBody");
  }

  @override
  void endYieldStatement(Token yieldToken, Token starToken, Token semicolon) {
    assert(optional('yield', yieldToken));
    assert(optionalOrNull('*', starToken));
    assert(optional(';', semicolon));
    debugEvent("YieldStatement");

    Expression expression = pop();
    push(ast.yieldStatement(yieldToken, starToken, expression, semicolon));
  }

  @override
  void exitLocalScope() {}

  @override
  AstNode finishFields() {
    debugEvent("finishFields");

    if (classDeclaration != null) {
      return classDeclaration.members
          .removeAt(classDeclaration.members.length - 1);
    } else if (mixinDeclaration != null) {
      return mixinDeclaration.members
          .removeAt(mixinDeclaration.members.length - 1);
    } else {
      return declarations.removeLast();
    }
  }

  void finishFunction(
      List annotations, formals, AsyncMarker asyncModifier, FunctionBody body) {
    debugEvent("finishFunction");

    Statement bodyStatement;
    if (body is EmptyFunctionBody) {
      bodyStatement = ast.emptyStatement(body.semicolon);
    } else if (body is NativeFunctionBody) {
      // TODO(danrubel): what do we need to do with NativeFunctionBody?
    } else if (body is ExpressionFunctionBody) {
      bodyStatement = ast.returnStatement(null, body.expression, null);
    } else {
      bodyStatement = (body as BlockFunctionBody).block;
    }
    // TODO(paulberry): what do we need to do with bodyStatement at this point?
    bodyStatement; // Suppress "unused local variable" hint
  }

  void handleAsOperator(Token asOperator) {
    assert(optional('as', asOperator));
    debugEvent("AsOperator");

    TypeAnnotation type = pop();
    Expression expression = pop();
    push(ast.asExpression(expression, asOperator, type));
  }

  void handleAssignmentExpression(Token token) {
    assert(token.type.isAssignmentOperator);
    debugEvent("AssignmentExpression");

    Expression rhs = pop();
    Expression lhs = pop();
    if (!lhs.isAssignable) {
      // TODO(danrubel): Update the BodyBuilder to report this error.
      handleRecoverableError(
          messageMissingAssignableSelector, lhs.beginToken, lhs.endToken);
    }
    push(ast.assignmentExpression(lhs, token, rhs));
    if (!enableTripleShift && token.type == TokenType.GT_GT_GT_EQ) {
      handleRecoverableError(
          templateExperimentNotEnabled.withArguments(EnableString.triple_shift),
          token,
          token);
    }
  }

  void handleAsyncModifier(Token asyncToken, Token starToken) {
    assert(asyncToken == null ||
        optional('async', asyncToken) ||
        optional('sync', asyncToken));
    assert(optionalOrNull('*', starToken));
    debugEvent("AsyncModifier");

    push(asyncToken ?? NullValue.FunctionBodyAsyncToken);
    push(starToken ?? NullValue.FunctionBodyStarToken);
  }

  @override
  void handleBreakStatement(
      bool hasTarget, Token breakKeyword, Token semicolon) {
    assert(optional('break', breakKeyword));
    assert(optional(';', semicolon));
    debugEvent("BreakStatement");

    SimpleIdentifier label = hasTarget ? pop() : null;
    push(ast.breakStatement(breakKeyword, label, semicolon));
  }

  @override
  void handleCaseMatch(Token caseKeyword, Token colon) {
    assert(optional('case', caseKeyword));
    assert(optional(':', colon));
    debugEvent("CaseMatch");

    Expression expression = pop();
    push(ast.switchCase(
        <Label>[], caseKeyword, expression, colon, <Statement>[]));
  }

  void handleCatchBlock(Token onKeyword, Token catchKeyword, Token comma) {
    assert(optionalOrNull('on', onKeyword));
    assert(optionalOrNull('catch', catchKeyword));
    assert(optionalOrNull(',', comma));
    debugEvent("CatchBlock");

    Block body = pop();
    FormalParameterList catchParameterList = popIfNotNull(catchKeyword);
    TypeAnnotation type = popIfNotNull(onKeyword);
    SimpleIdentifier exception;
    SimpleIdentifier stackTrace;
    if (catchParameterList != null) {
      List<FormalParameter> catchParameters = catchParameterList.parameters;
      if (catchParameters.length > 0) {
        exception = catchParameters[0].identifier;
        localDeclarations[exception.offset] = exception;
      }
      if (catchParameters.length > 1) {
        stackTrace = catchParameters[1].identifier;
        localDeclarations[stackTrace.offset] = stackTrace;
      }
    }
    push(ast.catchClause(
        onKeyword,
        type,
        catchKeyword,
        catchParameterList?.leftParenthesis,
        exception,
        comma,
        stackTrace,
        catchParameterList?.rightParenthesis,
        body));
  }

  @override
  void handleClassExtends(Token extendsKeyword) {
    assert(extendsKeyword == null || extendsKeyword.isKeywordOrIdentifier);
    debugEvent("ClassExtends");

    TypeName supertype = pop();
    if (supertype != null) {
      push(ast.extendsClause(extendsKeyword, supertype));
    } else {
      push(NullValue.ExtendsClause);
    }
  }

  @override
  void handleClassHeader(Token begin, Token classKeyword, Token nativeToken) {
    assert(optional('class', classKeyword));
    assert(optionalOrNull('native', nativeToken));
    assert(classDeclaration == null && mixinDeclaration == null);
    debugEvent("ClassHeader");

    NativeClause nativeClause;
    if (nativeToken != null) {
      nativeClause = ast.nativeClause(nativeToken, nativeName);
    }
    ImplementsClause implementsClause = pop(NullValue.IdentifierList);
    WithClause withClause = pop(NullValue.WithClause);
    ExtendsClause extendsClause = pop(NullValue.ExtendsClause);
    _Modifiers modifiers = pop();
    TypeParameterList typeParameters = pop();
    SimpleIdentifier name = pop();
    Token abstractKeyword = modifiers?.abstractKeyword;
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, begin);
    // leftBracket, members, and rightBracket
    // are set in [endClassOrMixinBody].
    classDeclaration = ast.classDeclaration(
      comment,
      metadata,
      abstractKeyword,
      classKeyword,
      name,
      typeParameters,
      extendsClause,
      withClause,
      implementsClause,
      null,
      // leftBracket
      <ClassMember>[],
      null, // rightBracket
    );

    classDeclaration.nativeClause = nativeClause;
    declarations.add(classDeclaration);
  }

  @override
  void handleClassNoWithClause() {
    push(NullValue.WithClause);
  }

  @override
  void handleClassOrMixinImplements(
      Token implementsKeyword, int interfacesCount) {
    assert(optionalOrNull('implements', implementsKeyword));
    debugEvent("ClassImplements");

    if (implementsKeyword != null) {
      List<TypeName> interfaces = popTypedList(interfacesCount);
      push(ast.implementsClause(implementsKeyword, interfaces));
    } else {
      push(NullValue.IdentifierList);
    }
  }

  @override
  void handleClassWithClause(Token withKeyword) {
    assert(optional('with', withKeyword));
    List<TypeName> mixinTypes = pop();
    push(ast.withClause(withKeyword, mixinTypes));
  }

  @override
  void handleCommentReference(
      Token newKeyword, Token prefix, Token period, Token token) {
    Identifier identifier = ast.simpleIdentifier(token);
    if (prefix != null) {
      identifier = ast.prefixedIdentifier(
          ast.simpleIdentifier(prefix), period, identifier);
    }
    push(ast.commentReference(newKeyword, identifier));
  }

  @override
  void handleCommentReferenceText(String referenceSource, int referenceOffset) {
    push(referenceSource);
    push(referenceOffset);
  }

  @override
  void handleContinueStatement(
      bool hasTarget, Token continueKeyword, Token semicolon) {
    assert(optional('continue', continueKeyword));
    assert(optional(';', semicolon));
    debugEvent("ContinueStatement");

    SimpleIdentifier label = hasTarget ? pop() : null;
    push(ast.continueStatement(continueKeyword, label, semicolon));
  }

  @override
  void handleDottedName(int count, Token firstIdentifier) {
    assert(firstIdentifier.isIdentifier);
    debugEvent("DottedName");

    List<SimpleIdentifier> components = popTypedList(count);
    push(ast.dottedName(components));
  }

  @override
  void handleElseControlFlow(Token elseToken) {
    push(elseToken);
  }

  @override
  void handleEmptyFunctionBody(Token semicolon) {
    assert(optional(';', semicolon));
    debugEvent("EmptyFunctionBody");

    // TODO(scheglov) Change the parser to not produce these modifiers.
    pop(); // star
    pop(); // async
    push(ast.emptyFunctionBody(semicolon));
  }

  @override
  void handleEmptyStatement(Token semicolon) {
    assert(optional(';', semicolon));
    debugEvent("EmptyStatement");

    push(ast.emptyStatement(semicolon));
  }

  @override
  void handleErrorToken(ErrorToken token) {
    translateErrorToken(token, errorReporter.reportScannerError);
  }

  void handleExpressionFunctionBody(Token arrowToken, Token semicolon) {
    assert(optional('=>', arrowToken) || optional('=', arrowToken));
    assert(optionalOrNull(';', semicolon));
    debugEvent("ExpressionFunctionBody");

    Expression expression = pop();
    pop(); // star (*)
    Token asyncKeyword = pop();
    if (parseFunctionBodies) {
      push(ast.expressionFunctionBody(
          asyncKeyword, arrowToken, expression, semicolon));
    } else {
      push(ast.emptyFunctionBody(semicolon));
    }
  }

  void handleExpressionStatement(Token semicolon) {
    assert(optional(';', semicolon));
    debugEvent("ExpressionStatement");
    Expression expression = pop();
    reportErrorIfSuper(expression);
    if (expression is SimpleIdentifier &&
        expression.token?.keyword?.isBuiltInOrPseudo == false) {
      // This error is also reported by the body builder.
      handleRecoverableError(
          messageExpectedStatement, expression.beginToken, expression.endToken);
    }
    if (expression is AssignmentExpression) {
      if (!expression.leftHandSide.isAssignable) {
        // This error is also reported by the body builder.
        handleRecoverableError(
            messageIllegalAssignmentToNonAssignable,
            expression.leftHandSide.beginToken,
            expression.leftHandSide.endToken);
      }
    }
    push(ast.expressionStatement(expression, semicolon));
  }

  @override
  void handleFinallyBlock(Token finallyKeyword) {
    debugEvent("FinallyBlock");
    // The finally block is popped in "endTryStatement".
  }

  @override
  void handleForInitializerEmptyStatement(Token token) {
    debugEvent("ForInitializerEmptyStatement");
    push(NullValue.Expression);
  }

  @override
  void handleForInitializerExpressionStatement(Token token) {
    debugEvent("ForInitializerExpressionStatement");
  }

  @override
  void handleForInitializerLocalVariableDeclaration(Token token) {
    debugEvent("ForInitializerLocalVariableDeclaration");
  }

  @override
  void handleForInLoopParts(Token awaitToken, Token forToken,
      Token leftParenthesis, Token inKeyword) {
    assert(optionalOrNull('await', awaitToken));
    assert(optional('for', forToken));
    assert(optional('(', leftParenthesis));
    assert(optional('in', inKeyword) || optional(':', inKeyword));

    Expression iterator = pop();
    Object variableOrDeclaration = pop();

    ForEachParts forLoopParts;
    if (variableOrDeclaration is VariableDeclarationStatement) {
      VariableDeclarationList variableList = variableOrDeclaration.variables;
      forLoopParts = ast.forEachPartsWithDeclaration(
        loopVariable: ast.declaredIdentifier(
            variableList.documentationComment,
            variableList.metadata,
            variableList.keyword,
            variableList.type,
            variableList.variables.first.name),
        inKeyword: inKeyword,
        iterable: iterator,
      );
    } else {
      if (variableOrDeclaration is! SimpleIdentifier) {
        // Parser has already reported the error.
        if (!leftParenthesis.next.isIdentifier) {
          parser.rewriter.insertToken(
              leftParenthesis,
              new SyntheticStringToken(
                  TokenType.IDENTIFIER, '', leftParenthesis.next.charOffset));
        }
        variableOrDeclaration = ast.simpleIdentifier(leftParenthesis.next);
      }
      forLoopParts = ast.forEachPartsWithIdentifier(
        identifier: variableOrDeclaration,
        inKeyword: inKeyword,
        iterable: iterator,
      );
    }

    push(awaitToken ?? NullValue.AwaitToken);
    push(forToken);
    push(leftParenthesis);
    push(forLoopParts);
  }

  @override
  void handleForLoopParts(Token forKeyword, Token leftParen,
      Token leftSeparator, int updateExpressionCount) {
    assert(optional('for', forKeyword));
    assert(optional('(', leftParen));
    assert(optional(';', leftSeparator));
    assert(updateExpressionCount >= 0);

    List<Expression> updates = popTypedList(updateExpressionCount);
    Statement conditionStatement = pop();
    Object initializerPart = pop();

    Expression condition;
    Token rightSeparator;
    if (conditionStatement is ExpressionStatement) {
      condition = conditionStatement.expression;
      rightSeparator = conditionStatement.semicolon;
    } else {
      rightSeparator = (conditionStatement as EmptyStatement).semicolon;
    }

    ForParts forLoopParts;
    if (initializerPart is VariableDeclarationStatement) {
      forLoopParts = ast.forPartsWithDeclarations(
        variables: initializerPart.variables,
        leftSeparator: leftSeparator,
        condition: condition,
        rightSeparator: rightSeparator,
        updaters: updates,
      );
    } else {
      forLoopParts = ast.forPartsWithExpression(
        initialization: initializerPart as Expression,
        leftSeparator: leftSeparator,
        condition: condition,
        rightSeparator: rightSeparator,
        updaters: updates,
      );
    }

    push(forKeyword);
    push(leftParen);
    push(forLoopParts);
  }

  void handleFormalParameterWithoutValue(Token token) {
    debugEvent("FormalParameterWithoutValue");

    push(NullValue.ParameterDefaultValue);
  }

  void handleIdentifier(Token token, IdentifierContext context) {
    assert(token.isKeywordOrIdentifier);
    debugEvent("handleIdentifier");

    if (context.inSymbol) {
      push(token);
      return;
    }

    SimpleIdentifier identifier =
        ast.simpleIdentifier(token, isDeclaration: context.inDeclaration);
    if (context.inLibraryOrPartOfDeclaration) {
      if (!context.isContinuation) {
        push([identifier]);
      } else {
        push(identifier);
      }
    } else if (context == IdentifierContext.enumValueDeclaration) {
      List<Annotation> metadata = pop();
      Comment comment = _findComment(null, token);
      push(ast.enumConstantDeclaration(comment, metadata, identifier));
    } else {
      push(identifier);
    }
  }

  @override
  void handleIdentifierList(int count) {
    debugEvent("IdentifierList");

    push(popTypedList<SimpleIdentifier>(count) ?? NullValue.IdentifierList);
  }

  @override
  void handleImportPrefix(Token deferredKeyword, Token asKeyword) {
    assert(optionalOrNull('deferred', deferredKeyword));
    assert(optionalOrNull('as', asKeyword));
    debugEvent("ImportPrefix");

    if (asKeyword == null) {
      // If asKeyword is null, then no prefix has been pushed on the stack.
      // Push a placeholder indicating that there is no prefix.
      push(NullValue.Prefix);
      push(NullValue.As);
    } else {
      push(asKeyword);
    }
    push(deferredKeyword ?? NullValue.Deferred);
  }

  void handleIndexedExpression(Token leftBracket, Token rightBracket) {
    assert(optional('[', leftBracket));
    assert(optional(']', rightBracket));
    debugEvent("IndexedExpression");

    Expression index = pop();
    Expression target = pop();
    if (target == null) {
      CascadeExpression receiver = pop();
      Token token = peek();
      push(receiver);
      IndexExpression expression = ast.indexExpressionForCascade(
          token, leftBracket, index, rightBracket);
      assert(expression.isCascaded);
      push(expression);
    } else {
      push(ast.indexExpressionForTarget(
          target, leftBracket, index, rightBracket));
    }
  }

  @override
  void handleInterpolationExpression(Token leftBracket, Token rightBracket) {
    Expression expression = pop();
    push(ast.interpolationExpression(leftBracket, expression, rightBracket));
  }

  @override
  void handleInvalidExpression(Token token) {
    debugEvent("InvalidExpression");
  }

  @override
  void handleInvalidFunctionBody(Token leftBracket) {
    assert(optional('{', leftBracket));
    assert(optional('}', leftBracket.endGroup));
    debugEvent("InvalidFunctionBody");
    Block block = ast.block(leftBracket, [], leftBracket.endGroup);
    Token star = pop();
    Token asyncKeyword = pop();
    push(ast.blockFunctionBody(asyncKeyword, star, block));
  }

  @override
  void handleInvalidMember(Token endToken) {
    debugEvent("InvalidMember");
    pop(); // metadata star
  }

  @override
  void handleInvalidOperatorName(Token operatorKeyword, Token token) {
    assert(optional('operator', operatorKeyword));
    debugEvent("InvalidOperatorName");

    push(new _OperatorName(
        operatorKeyword, ast.simpleIdentifier(token, isDeclaration: true)));
  }

  void handleInvalidTopLevelBlock(Token token) {
    // TODO(danrubel): Consider improved recovery by adding this block
    // as part of a synthetic top level function.
    pop(); // block
  }

  @override
  void handleInvalidTopLevelDeclaration(Token endToken) {
    debugEvent("InvalidTopLevelDeclaration");

    pop(); // metadata star
    // TODO(danrubel): consider creating a AST node
    // representing the invalid declaration to better support code completion,
    // quick fixes, etc, rather than discarding the metadata and token
  }

  @override
  void handleInvalidTypeArguments(Token token) {
    TypeArgumentList invalidTypeArgs = pop();
    var node = pop();
    if (node is ConstructorName) {
      push(new _ConstructorNameWithInvalidTypeArgs(node, invalidTypeArgs));
    } else {
      throw new UnimplementedError();
    }
  }

  void handleIsOperator(Token isOperator, Token not) {
    assert(optional('is', isOperator));
    assert(optionalOrNull('!', not));
    debugEvent("IsOperator");

    TypeAnnotation type = pop();
    Expression expression = pop();
    push(ast.isExpression(expression, isOperator, not, type));
  }

  @override
  void handleLabel(Token colon) {
    assert(optionalOrNull(':', colon));
    debugEvent("Label");

    SimpleIdentifier name = pop();
    push(ast.label(name, colon));
  }

  void handleLiteralBool(Token token) {
    bool value = identical(token.stringValue, "true");
    assert(value || identical(token.stringValue, "false"));
    debugEvent("LiteralBool");

    push(ast.booleanLiteral(token, value));
  }

  void handleLiteralDouble(Token token) {
    assert(token.type == TokenType.DOUBLE);
    debugEvent("LiteralDouble");

    push(ast.doubleLiteral(token, double.parse(token.lexeme)));
  }

  void handleLiteralInt(Token token) {
    assert(identical(token.kind, INT_TOKEN) ||
        identical(token.kind, HEXADECIMAL_TOKEN));
    debugEvent("LiteralInt");

    push(ast.integerLiteral(token, int.tryParse(token.lexeme)));
  }

  void handleLiteralList(
      int count, Token leftBracket, Token constKeyword, Token rightBracket) {
    assert(optional('[', leftBracket));
    assert(optionalOrNull('const', constKeyword));
    assert(optional(']', rightBracket));
    debugEvent("LiteralList");

    if (enableControlFlowCollections || enableSpreadCollections) {
      List<CollectionElement> elements = popCollectionElements(count);
      TypeArgumentList typeArguments = pop();

      // TODO(danrubel): Remove this and _InvalidCollectionElement
      // once control flow and spread collection support is enabled by default
      elements.removeWhere((e) => e == _invalidCollectionElement);

      push(ast.listLiteral(
          constKeyword, typeArguments, leftBracket, elements, rightBracket));
    } else {
      List<dynamic> elements = popTypedList(count);
      TypeArgumentList typeArguments = pop();

      List<Expression> expressions = <Expression>[];
      if (elements != null) {
        for (var elem in elements) {
          if (elem is Expression) {
            expressions.add(elem);
          }
        }
      }

      push(ast.listLiteral(
          constKeyword, typeArguments, leftBracket, expressions, rightBracket));
    }
  }

  void handleLiteralMapEntry(Token colon, Token endToken) {
    assert(optional(':', colon));
    debugEvent("LiteralMapEntry");

    Expression value = pop();
    Expression key = pop();
    push(ast.mapLiteralEntry(key, colon, value));
  }

  void handleLiteralNull(Token token) {
    assert(optional('null', token));
    debugEvent("LiteralNull");

    push(ast.nullLiteral(token));
  }

  @override
  void handleLiteralSetOrMap(
    int count,
    Token leftBrace,
    Token constKeyword,
    Token rightBrace,
    // TODO(danrubel): hasSetEntry parameter exists for replicating existing
    // behavior and will be removed once unified collection has been enabled
    bool hasSetEntry,
  ) {
    if (enableControlFlowCollections || enableSpreadCollections) {
      List<CollectionElement> elements = popCollectionElements(count);

      // TODO(danrubel): Remove this and _InvalidCollectionElement
      // once control flow and spread collection support is enabled by default
      elements.removeWhere((e) => e == _invalidCollectionElement);

      TypeArgumentList typeArguments = pop();
      push(ast.setOrMapLiteral(
        constKeyword: constKeyword,
        typeArguments: typeArguments,
        leftBracket: leftBrace,
        elements: elements,
        rightBracket: rightBrace,
      ));
    } else {
      List<dynamic> elements = popTypedList(count);
      TypeArgumentList typeArguments = pop();

      // Replicate existing behavior that has been removed from the parser.
      // This will be removed once control flow collections
      // and spread collections are enabled by default.

      // Determine if this is a set or map based on type args and content
      final typeArgCount = typeArguments?.arguments?.length;
      bool isSet =
          typeArgCount == 1 ? true : typeArgCount != null ? false : null;
      isSet ??= hasSetEntry;

      // Build the set or map
      if (isSet) {
        final setEntries = <Expression>[];
        if (elements != null) {
          for (var elem in elements) {
            if (elem is MapLiteralEntry) {
              setEntries.add(elem.key);
              handleRecoverableError(
                  templateUnexpectedToken.withArguments(elem.separator),
                  elem.separator,
                  elem.separator);
            } else if (elem is Expression) {
              setEntries.add(elem);
            }
          }
        }
        push(ast.setOrMapLiteral(
          constKeyword: constKeyword,
          typeArguments: typeArguments,
          leftBracket: leftBrace,
          elements: setEntries,
          rightBracket: rightBrace,
        ));
      } else {
        final mapEntries = <MapLiteralEntry>[];
        if (elements != null) {
          for (var elem in elements) {
            if (elem is MapLiteralEntry) {
              mapEntries.add(elem);
            } else if (elem is Expression) {
              Token next = elem.endToken.next;
              int offset = next.offset;
              handleRecoverableError(
                  templateExpectedButGot.withArguments(':'), next, next);
              handleRecoverableError(
                  templateExpectedIdentifier.withArguments(next), next, next);
              Token separator = SyntheticToken(TokenType.COLON, offset);
              Expression value = ast.simpleIdentifier(
                  SyntheticStringToken(TokenType.IDENTIFIER, '', offset));
              mapEntries.add(ast.mapLiteralEntry(elem, separator, value));
            }
          }
        }
        push(ast.setOrMapLiteral(
          constKeyword: constKeyword,
          typeArguments: typeArguments,
          leftBracket: leftBrace,
          elements: mapEntries,
          rightBracket: rightBrace,
        ));
      }
    }
  }

  @override
  void handleMixinHeader(Token mixinKeyword) {
    assert(optional('mixin', mixinKeyword));
    assert(classDeclaration == null && mixinDeclaration == null);
    debugEvent("MixinHeader");

    ImplementsClause implementsClause = pop(NullValue.IdentifierList);
    OnClause onClause = pop(NullValue.IdentifierList);
    TypeParameterList typeParameters = pop();
    SimpleIdentifier name = pop();
    List<Annotation> metadata = pop();
    Comment comment = _findComment(metadata, mixinKeyword);

    mixinDeclaration = ast.mixinDeclaration(
      comment,
      metadata,
      mixinKeyword,
      name,
      typeParameters,
      onClause,
      implementsClause,
      null,
      // leftBracket
      <ClassMember>[],
      null, // rightBracket
    );
    declarations.add(mixinDeclaration);
  }

  @override
  void handleMixinOn(Token onKeyword, int typeCount) {
    assert(onKeyword == null || onKeyword.isKeywordOrIdentifier);
    debugEvent("MixinOn");

    if (onKeyword != null) {
      List<TypeName> types = popTypedList(typeCount);
      push(ast.onClause(onKeyword, types));
    } else {
      push(NullValue.IdentifierList);
    }
  }

  void handleNamedArgument(Token colon) {
    assert(optional(':', colon));
    debugEvent("NamedArgument");

    Expression expression = pop();
    SimpleIdentifier name = pop();
    push(ast.namedExpression(ast.label(name, colon), expression));
  }

  @override
  void handleNamedMixinApplicationWithClause(Token withKeyword) {
    assert(optionalOrNull('with', withKeyword));
    List<TypeName> mixinTypes = pop();
    push(ast.withClause(withKeyword, mixinTypes));
  }

  @override
  void handleNativeClause(Token nativeToken, bool hasName) {
    debugEvent("NativeClause");

    if (hasName) {
      nativeName = pop(); // StringLiteral
    } else {
      nativeName = null;
    }
  }

  @override
  void handleNativeFunctionBody(Token nativeToken, Token semicolon) {
    assert(optional('native', nativeToken));
    assert(optional(';', semicolon));
    debugEvent("NativeFunctionBody");

    // TODO(danrubel) Change the parser to not produce these modifiers.
    pop(); // star
    pop(); // async
    push(ast.nativeFunctionBody(nativeToken, nativeName, semicolon));
  }

  @override
  void handleNoConstructorReferenceContinuationAfterTypeArguments(Token token) {
    debugEvent("NoConstructorReferenceContinuationAfterTypeArguments");

    push(NullValue.ConstructorReferenceContinuationAfterTypeArguments);
  }

  @override
  void handleNoFieldInitializer(Token token) {
    debugEvent("NoFieldInitializer");

    SimpleIdentifier name = pop();
    push(_makeVariableDeclaration(name, null, null));
  }

  void handleNoInitializers() {
    debugEvent("NoInitializers");

    if (!isFullAst) return;
    push(NullValue.ConstructorInitializerSeparator);
    push(NullValue.ConstructorInitializers);
  }

  @override
  void handleNonNullAssertExpression(Token bang) {
    debugEvent('NonNullAssertExpression');
    if (!enableNonNullable) {
      reportNonNullAssertExpressionNotEnabled(bang);
    } else {
      push(ast.postfixExpression(pop(), bang));
    }
  }

  @override
  void handleNoVariableInitializer(Token token) {
    debugEvent("NoVariableInitializer");
  }

  void handleOperator(Token operatorToken) {
    assert(operatorToken.isUserDefinableOperator);
    debugEvent("Operator");

    push(operatorToken);
  }

  @override
  void handleOperatorName(Token operatorKeyword, Token token) {
    assert(optional('operator', operatorKeyword));
    assert(token.type.isUserDefinableOperator);
    debugEvent("OperatorName");

    push(new _OperatorName(
        operatorKeyword, ast.simpleIdentifier(token, isDeclaration: true)));
  }

  @override
  void handleParenthesizedCondition(Token leftParenthesis) {
    // TODO(danrubel): Implement rather than forwarding.
    handleParenthesizedExpression(leftParenthesis);
  }

  @override
  void handleParenthesizedExpression(Token leftParenthesis) {
    assert(optional('(', leftParenthesis));
    debugEvent("ParenthesizedExpression");

    Expression expression = pop();
    push(ast.parenthesizedExpression(
        leftParenthesis, expression, leftParenthesis?.endGroup));
  }

  @override
  void handleQualified(Token period) {
    assert(optional('.', period));

    SimpleIdentifier identifier = pop();
    var prefix = pop();
    if (prefix is List) {
      // We're just accumulating components into a list.
      prefix.add(identifier);
      push(prefix);
    } else if (prefix is SimpleIdentifier) {
      // TODO(paulberry): resolve [identifier].  Note that BodyBuilder handles
      // this situation using SendAccessGenerator.
      push(ast.prefixedIdentifier(prefix, period, identifier));
    } else {
      // TODO(paulberry): implement.
      logEvent('Qualified with >1 dot');
    }
  }

  @override
  void handleRecoverableError(
      Message message, Token startToken, Token endToken) {
    /// TODO(danrubel): Ignore this error until we deprecate `native` support.
    if (message == messageNativeClauseShouldBeAnnotation && allowNativeClause) {
      return;
    }
    debugEvent("Error: ${message.message}");
    if (message.code.analyzerCodes == null && startToken is ErrorToken) {
      translateErrorToken(startToken, errorReporter.reportScannerError);
    } else {
      int offset = startToken.offset;
      int length = endToken.end - offset;
      addProblem(message, offset, length);
    }
  }

  @override
  void handleRecoverClassHeader() {
    debugEvent("RecoverClassHeader");

    ImplementsClause implementsClause = pop(NullValue.IdentifierList);
    WithClause withClause = pop(NullValue.WithClause);
    ExtendsClause extendsClause = pop(NullValue.ExtendsClause);
    ClassDeclaration declaration = declarations.last;
    if (extendsClause != null) {
      if (declaration.extendsClause?.superclass == null) {
        declaration.extendsClause = extendsClause;
      }
    }
    if (withClause != null) {
      if (declaration.withClause == null) {
        declaration.withClause = withClause;
      } else {
        declaration.withClause.mixinTypes.addAll(withClause.mixinTypes);
      }
    }
    if (implementsClause != null) {
      if (declaration.implementsClause == null) {
        declaration.implementsClause = implementsClause;
      } else {
        declaration.implementsClause.interfaces
            .addAll(implementsClause.interfaces);
      }
    }
  }

  @override
  void handleRecoverImport(Token semicolon) {
    assert(optionalOrNull(';', semicolon));
    debugEvent("RecoverImport");

    List<Combinator> combinators = pop();
    Token deferredKeyword = pop(NullValue.Deferred);
    Token asKeyword = pop(NullValue.As);
    SimpleIdentifier prefix = pop(NullValue.Prefix);
    List<Configuration> configurations = pop();

    ImportDirective directive = directives.last;
    if (combinators != null) {
      directive.combinators.addAll(combinators);
    }
    directive.deferredKeyword ??= deferredKeyword;
    if (directive.asKeyword == null && asKeyword != null) {
      directive.asKeyword = asKeyword;
      directive.prefix = prefix;
    }
    if (configurations != null) {
      directive.configurations.addAll(configurations);
    }
    directive.semicolon = semicolon;
  }

  @override
  void handleRecoverMixinHeader() {
    ImplementsClause implementsClause = pop(NullValue.IdentifierList);
    OnClause onClause = pop(NullValue.IdentifierList);

    if (onClause != null) {
      if (mixinDeclaration.onClause == null) {
        mixinDeclaration.onClause = onClause;
      } else {
        mixinDeclaration.onClause.superclassConstraints
            .addAll(onClause.superclassConstraints);
      }
    }
    if (implementsClause != null) {
      if (mixinDeclaration.implementsClause == null) {
        mixinDeclaration.implementsClause = implementsClause;
      } else {
        mixinDeclaration.implementsClause.interfaces
            .addAll(implementsClause.interfaces);
      }
    }
  }

  void handleScript(Token token) {
    assert(identical(token.type, TokenType.SCRIPT_TAG));
    debugEvent("Script");

    scriptTag = ast.scriptTag(token);
  }

  void handleSend(Token beginToken, Token endToken) {
    debugEvent("Send");

    MethodInvocation arguments = pop();
    TypeArgumentList typeArguments = pop();
    if (arguments != null) {
      doInvocation(typeArguments, arguments);
    } else {
      doPropertyGet();
    }
  }

  @override
  void handleSpreadExpression(Token spreadToken) {
    var expression = pop();
    if (enableSpreadCollections) {
      push(ast.spreadElement(
          spreadOperator: spreadToken, expression: expression));
    } else {
      handleRecoverableError(
          templateExperimentNotEnabled
              .withArguments(EnableString.spread_collections),
          spreadToken,
          spreadToken);
      push(_invalidCollectionElement);
    }
  }

  void handleStringJuxtaposition(int literalCount) {
    debugEvent("StringJuxtaposition");

    push(ast.adjacentStrings(popTypedList(literalCount)));
  }

  @override
  void handleStringPart(Token literalString) {
    assert(identical(literalString.kind, STRING_TOKEN));
    debugEvent("StringPart");

    push(literalString);
  }

  @override
  void handleSuperExpression(Token superKeyword, IdentifierContext context) {
    assert(optional('super', superKeyword));
    debugEvent("SuperExpression");

    push(ast.superExpression(superKeyword));
  }

  void handleSymbolVoid(Token voidKeyword) {
    assert(optional('void', voidKeyword));
    debugEvent("SymbolVoid");

    push(voidKeyword);
  }

  @override
  void handleThisExpression(Token thisKeyword, IdentifierContext context) {
    assert(optional('this', thisKeyword));
    debugEvent("ThisExpression");

    push(ast.thisExpression(thisKeyword));
  }

  void handleThrowExpression(Token throwToken, Token endToken) {
    assert(optional('throw', throwToken));
    debugEvent("ThrowExpression");

    push(ast.throwExpression(throwToken, pop()));
  }

  @override
  void handleType(Token beginToken, Token questionMark) {
    debugEvent("Type");
    if (!enableNonNullable) {
      reportErrorIfNullableType(questionMark);
    }

    TypeArgumentList arguments = pop();
    Identifier name = pop();
    push(ast.typeName(name, arguments, question: questionMark));
  }

  @override
  void handleTypeVariablesDefined(Token token, int count) {
    debugEvent("handleTypeVariablesDefined");
    assert(count > 0);
    push(popTypedList(count, new List<TypeParameter>(count)));
  }

  void handleUnaryPostfixAssignmentExpression(Token operator) {
    assert(operator.type.isUnaryPostfixOperator);
    debugEvent("UnaryPostfixAssignmentExpression");

    Expression expression = pop();
    if (!expression.isAssignable) {
      // This error is also reported by the body builder.
      handleRecoverableError(
          messageIllegalAssignmentToNonAssignable, operator, operator);
    }
    push(ast.postfixExpression(expression, operator));
  }

  void handleUnaryPrefixAssignmentExpression(Token operator) {
    assert(operator.type.isUnaryPrefixOperator);
    debugEvent("UnaryPrefixAssignmentExpression");

    Expression expression = pop();
    if (!expression.isAssignable) {
      // This error is also reported by the body builder.
      handleRecoverableError(messageMissingAssignableSelector,
          expression.endToken, expression.endToken);
    }
    push(ast.prefixExpression(operator, expression));
  }

  void handleUnaryPrefixExpression(Token operator) {
    assert(operator.type.isUnaryPrefixOperator);
    debugEvent("UnaryPrefixExpression");

    push(ast.prefixExpression(operator, pop()));
  }

  void handleValuedFormalParameter(Token equals, Token token) {
    assert(optional('=', equals) || optional(':', equals));
    debugEvent("ValuedFormalParameter");

    Expression value = pop();
    push(new _ParameterDefaultValue(equals, value));
  }

  @override
  void handleVoidKeyword(Token voidKeyword) {
    assert(optional('void', voidKeyword));
    debugEvent("VoidKeyword");

    // TODO(paulberry): is this sufficient, or do we need to hook the "void"
    // keyword up to an element?
    handleIdentifier(voidKeyword, IdentifierContext.typeReference);
    handleNoTypeArguments(voidKeyword);
    handleType(voidKeyword, null);
  }

  /// Return `true` if [token] is either `null` or is the symbol or keyword
  /// [value].
  bool optionalOrNull(String value, Token token) {
    return token == null || identical(value, token.stringValue);
  }

  List<CommentReference> parseCommentReferences(Token dartdoc) {
    // Parse dartdoc into potential comment reference source/offset pairs
    int count = parser.parseCommentReferences(dartdoc);
    List sourcesAndOffsets = new List(count * 2);
    popList(count * 2, sourcesAndOffsets);

    // Parse each of the source/offset pairs into actual comment references
    count = 0;
    int index = 0;
    while (index < sourcesAndOffsets.length) {
      String referenceSource = sourcesAndOffsets[index++];
      int referenceOffset = sourcesAndOffsets[index++];
      ScannerResult result = scanString(referenceSource);
      if (!result.hasErrors) {
        Token token = result.tokens;
        if (parser.parseOneCommentReference(token, referenceOffset)) {
          ++count;
        }
      }
    }

    final references = new List<CommentReference>(count);
    popTypedList(count, references);
    return references;
  }

  List<CollectionElement> popCollectionElements(int count) {
    final elements = new List<CollectionElement>()..length = count;
    for (int index = count - 1; index >= 0; --index) {
      var element = pop();
      elements[index] = element as CollectionElement;
    }
    return elements;
  }

  List popList(int n, List list) {
    if (n == 0) return null;
    return stack.popList(n, list, null);
  }

  List<T> popTypedList<T>(int count, [List<T> list]) {
    if (count == 0) return null;
    assert(stack.arrayLength >= count);

    final table = stack.array;
    final length = stack.arrayLength;

    final tailList = list ?? new List<T>.filled(count, null, growable: true);
    final startIndex = length - count;
    for (int i = 0; i < count; i++) {
      final value = table[startIndex + i];
      tailList[i] = value is NullValue ? null : value;
      table[startIndex + i] = null;
    }
    stack.arrayLength -= count;

    return tailList;
  }

  void pushForControlFlowInfo(Token awaitToken, Token forToken,
      Token leftParenthesis, ForLoopParts forLoopParts, Object entry) {
    if (entry == _invalidCollectionElement) {
      push(_invalidCollectionElement);
    } else if (enableControlFlowCollections) {
      push(ast.forElement(
        awaitKeyword: awaitToken,
        forKeyword: forToken,
        leftParenthesis: leftParenthesis,
        forLoopParts: forLoopParts,
        rightParenthesis: leftParenthesis.endGroup,
        body: entry as CollectionElement,
      ));
    } else {
      handleRecoverableError(
          templateExperimentNotEnabled
              .withArguments(EnableString.control_flow_collections),
          forToken,
          forToken);
      push(_invalidCollectionElement);
    }
  }

  void pushIfControlFlowInfo(
      Token ifToken,
      ParenthesizedExpression condition,
      CollectionElement thenElement,
      Token elseToken,
      CollectionElement elseElement) {
    if (thenElement == _invalidCollectionElement ||
        elseElement == _invalidCollectionElement) {
      push(_invalidCollectionElement);
    } else if (enableControlFlowCollections) {
      push(ast.ifElement(
        ifKeyword: ifToken,
        leftParenthesis: condition.leftParenthesis,
        condition: condition.expression,
        rightParenthesis: condition.rightParenthesis,
        thenElement: thenElement,
        elseKeyword: elseToken,
        elseElement: elseElement,
      ));
    } else {
      handleRecoverableError(
          templateExperimentNotEnabled
              .withArguments(EnableString.control_flow_collections),
          ifToken,
          ifToken);
      push(_invalidCollectionElement);
    }
  }

  void reportErrorIfSuper(Expression expression) {
    if (expression is SuperExpression) {
      // This error is also reported by the body builder.
      handleRecoverableError(messageMissingAssignableSelector,
          expression.beginToken, expression.endToken);
    }
  }

  Comment _findComment(List<Annotation> metadata, Token tokenAfterMetadata) {
    // Find the dartdoc tokens
    Token dartdoc = parser.findDartDoc(tokenAfterMetadata);
    if (dartdoc == null) {
      if (metadata == null) {
        return null;
      }
      int index = metadata.length;
      while (true) {
        if (index == 0) {
          return null;
        }
        --index;
        dartdoc = parser.findDartDoc(metadata[index].beginToken);
        if (dartdoc != null) {
          break;
        }
      }
    }

    // Build and return the comment
    List<CommentReference> references = parseCommentReferences(dartdoc);
    List<Token> tokens = <Token>[dartdoc];
    if (dartdoc.lexeme.startsWith('///')) {
      dartdoc = dartdoc.next;
      while (dartdoc != null) {
        if (dartdoc.lexeme.startsWith('///')) {
          tokens.add(dartdoc);
        }
        dartdoc = dartdoc.next;
      }
    }
    return ast.documentationComment(tokens, references);
  }

  void _handleInstanceCreation(Token token) {
    MethodInvocation arguments = pop();
    ConstructorName constructorName;
    TypeArgumentList typeArguments;
    var object = pop();
    if (object is _ConstructorNameWithInvalidTypeArgs) {
      constructorName = object.name;
      typeArguments = object.invalidTypeArgs;
    } else {
      constructorName = object;
    }
    push(ast.instanceCreationExpression(
        token, constructorName, arguments.argumentList,
        typeArguments: typeArguments));
  }

  VariableDeclaration _makeVariableDeclaration(
      SimpleIdentifier name, Token equals, Expression initializer) {
    var variableDeclaration =
        ast.variableDeclaration(name, equals, initializer);
    localDeclarations[name.offset] = variableDeclaration;
    return variableDeclaration;
  }

  ParameterKind _toAnalyzerParameterKind(
      FormalParameterKind type, Token requiredKeyword) {
    if (type == FormalParameterKind.optionalPositional) {
      return ParameterKind.POSITIONAL;
    } else if (type == FormalParameterKind.optionalNamed) {
      if (requiredKeyword != null) {
        return ParameterKind.NAMED_REQUIRED;
      }
      return ParameterKind.NAMED;
    } else {
      return ParameterKind.REQUIRED;
    }
  }
}

class _ConstructorNameWithInvalidTypeArgs {
  final ConstructorName name;
  final TypeArgumentList invalidTypeArgs;

  _ConstructorNameWithInvalidTypeArgs(this.name, this.invalidTypeArgs);
}

/// When [enableSpreadCollections] and/or [enableControlFlowCollections]
/// are false, this class is pushed on the stack when a disabled
/// [CollectionElement] has been parsed.
class _InvalidCollectionElement implements CollectionElement {
  // TODO(danrubel): Remove this once control flow and spread collections
  // have been enabled by default.

  const _InvalidCollectionElement._();

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Data structure placed on the stack to represent a non-empty sequence
/// of modifiers.
class _Modifiers {
  Token abstractKeyword;
  Token externalKeyword;
  Token finalConstOrVarKeyword;
  Token staticKeyword;
  Token covariantKeyword;
  Token requiredToken;
  Token lateToken;

  /// Return the token that is lexically first.
  Token get beginToken {
    Token firstToken = null;
    for (Token token in [
      abstractKeyword,
      externalKeyword,
      finalConstOrVarKeyword,
      staticKeyword,
      covariantKeyword,
      requiredToken,
      lateToken,
    ]) {
      if (firstToken == null) {
        firstToken = token;
      } else if (token != null) {
        if (token.offset < firstToken.offset) {
          firstToken = token;
        }
      }
    }
    return firstToken;
  }

  /// Return the `const` keyword or `null`.
  Token get constKeyword {
    return identical('const', finalConstOrVarKeyword?.lexeme)
        ? finalConstOrVarKeyword
        : null;
  }
}

/// Data structure placed on the stack to represent the keyword "operator"
/// followed by a token.
class _OperatorName {
  final Token operatorKeyword;
  final SimpleIdentifier name;

  _OperatorName(this.operatorKeyword, this.name);
}

/// Data structure placed on the stack as a container for optional parameters.
class _OptionalFormalParameters {
  final List<FormalParameter> parameters;
  final Token leftDelimiter;
  final Token rightDelimiter;

  _OptionalFormalParameters(
      this.parameters, this.leftDelimiter, this.rightDelimiter);
}

/// Data structure placed on the stack to represent the default parameter
/// value with the separator token.
class _ParameterDefaultValue {
  final Token separator;
  final Expression value;

  _ParameterDefaultValue(this.separator, this.value);
}

/// Data structure placed on stack to represent the redirected constructor.
class _RedirectingFactoryBody {
  final Token asyncKeyword;
  final Token starKeyword;
  final Token equalToken;
  final ConstructorName constructorName;

  _RedirectingFactoryBody(this.asyncKeyword, this.starKeyword, this.equalToken,
      this.constructorName);
}
