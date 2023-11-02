// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/experiments/flags.dart';
import 'package:_fe_analyzer_shared/src/macros/executor.dart' as macro;
import 'package:_fe_analyzer_shared/src/messages/codes.dart';
import 'package:_fe_analyzer_shared/src/parser/parser.dart';
import 'package:_fe_analyzer_shared/src/parser/quote.dart';
import 'package:_fe_analyzer_shared/src/scanner/error_token.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart';

import '../../builder/builder.dart';
import '../../builder/declaration_builders.dart';
import '../../builder/member_builder.dart';
import '../../builder/metadata_builder.dart';
import '../../builder/prefix_builder.dart';
import '../../scope.dart';
import '../../source/diet_parser.dart';
import '../../source/source_library_builder.dart';
import 'macro.dart';

List<MacroApplication>? prebuildAnnotations(
    {required SourceLibraryBuilder enclosingLibrary,
    required List<MetadataBuilder>? metadataBuilders,
    required Uri fileUri,
    required Scope scope}) {
  if (metadataBuilders == null) return null;
  List<MacroApplication>? result;
  for (MetadataBuilder metadataBuilder in metadataBuilders) {
    _MacroListener listener =
        new _MacroListener(enclosingLibrary, fileUri, scope);
    Parser parser = new Parser(listener,
        useImplicitCreationExpression: useImplicitCreationExpressionInCfe);
    parser.parseMetadata(
        parser.syntheticPreviousToken(metadataBuilder.beginToken!));
    MacroApplication? application = listener.popMacroApplication();
    if (application != null) {
      result ??= [];
      result.add(application);
    }
  }
  if (result != null && result.length > 1) {
    result = result.reversed.toList(growable: false);
  }
  return result;
}

class _Node {}

class _UnrecognizedNode implements _Node {
  const _UnrecognizedNode();
}

class _MacroClassNode implements _Node {
  final Token token;
  final ClassBuilder classBuilder;

  _MacroClassNode(this.token, this.classBuilder);
}

class _MacroConstructorNode implements _Node {
  final ClassBuilder classBuilder;
  final String constructorName;

  _MacroConstructorNode(this.classBuilder, this.constructorName);
}

class _PrefixNode implements _Node {
  final PrefixBuilder prefixBuilder;

  _PrefixNode(this.prefixBuilder);
}

class _MacroApplicationNode implements _Node {
  final MacroApplication application;

  _MacroApplicationNode(this.application);
}

class _NoArgumentsNode implements _Node {
  const _NoArgumentsNode();
}

class _ArgumentsNode implements _Node {
  final List<macro.Argument> positionalArguments;
  final Map<String, macro.Argument> namedArguments;

  _ArgumentsNode(this.positionalArguments, this.namedArguments);
}

class _PrimitiveValueNode implements _Node {
  Object? get value => argument.value;

  final macro.Argument argument;

  _PrimitiveValueNode(this.argument);
}

class _TokenNode implements _Node {
  final Token token;

  _TokenNode(this.token);
}

class _NamedArgumentIdentifierNode implements _Node {
  final String name;

  _NamedArgumentIdentifierNode(this.name);
}

class _NamedArgumentNode implements _Node {
  final String name;
  final macro.Argument argument;

  Object? get value => argument.value;

  _NamedArgumentNode(this.name, this.argument);
}

class _MacroListener implements Listener {
  final SourceLibraryBuilder currentLibrary;

  @override
  final Uri uri;

  final Scope scope;

  final List<_Node> _stack = [];

  Object? _unrecognized;

  bool get unrecognized => _unrecognized != null;

  void set unrecognized(bool value) {
    if (value) {
      // TODO(johnniwinther): Remove this when implementation is more mature.
      _unrecognized = StackTrace.current;
    } else {
      _unrecognized = null;
    }
  }

  _MacroListener(this.currentLibrary, this.uri, this.scope);

  void pushUnsupported() {
    push(const _UnrecognizedNode());
    _unsupported();
  }

  void push(_Node node) {
    _stack.add(node);
  }

  _Node pop() => _stack.removeLast();

  MacroApplication? popMacroApplication() {
    if (unrecognized) return null;
    if (_stack.length != 1) return null;
    _Node node = pop();
    if (node is _MacroApplicationNode) {
      return node.application;
    }
    return null;
  }

  @override
  void beginMetadata(Token token) {
    // Do nothing.
  }

  @override
  void endMetadata(Token beginToken, Token? periodBeforeName, Token endToken) {
    _Node argumentsNode = pop();
    _Node referenceNode = pop();
    if (!unrecognized) {
      ClassBuilder? macroClass;
      String? constructorName;
      if (referenceNode is _MacroClassNode) {
        macroClass = referenceNode.classBuilder;
        MemberBuilder? member = referenceNode.classBuilder
            .findConstructorOrFactory(
                '', referenceNode.token.charOffset, uri, currentLibrary);
        if (member != null) {
          constructorName = '';
        }
      } else if (referenceNode is _MacroConstructorNode) {
        macroClass = referenceNode.classBuilder;
        constructorName = referenceNode.constructorName;
      }
      if (macroClass != null &&
          constructorName != null &&
          argumentsNode is _ArgumentsNode) {
        push(new _MacroApplicationNode(new MacroApplication(
            macroClass,
            constructorName,
            new macro.Arguments(argumentsNode.positionalArguments,
                argumentsNode.namedArguments),
            fileOffset: beginToken.next!.charOffset)));
        return;
      }
    }
    pushUnsupported();
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    switch (context) {
      case IdentifierContext.metadataReference:
        Builder? builder = scope.lookup(token.lexeme, token.charOffset, uri);
        if (builder is ClassBuilder && builder.isMacro) {
          push(new _MacroClassNode(token, builder));
        } else if (builder is PrefixBuilder) {
          push(new _PrefixNode(builder));
        } else {
          pushUnsupported();
        }
        break;
      case IdentifierContext.metadataContinuation:
        _Node node = pop();
        if (node is _PrefixNode) {
          Builder? builder =
              node.prefixBuilder.lookup(token.lexeme, token.charOffset, uri);
          if (builder is ClassBuilder && builder.isMacro) {
            push(new _MacroClassNode(token, builder));
          } else {
            pushUnsupported();
          }
        } else if (node is _MacroClassNode) {
          MemberBuilder? member = node.classBuilder.findConstructorOrFactory(
              token.lexeme, token.charOffset, uri, currentLibrary);
          if (member != null) {
            push(new _MacroConstructorNode(node.classBuilder, token.lexeme));
          } else {
            pushUnsupported();
          }
        } else {
          pushUnsupported();
        }
        break;
      case IdentifierContext.metadataContinuationAfterTypeArguments:
        _Node node = pop();
        if (node is _MacroClassNode) {
          MemberBuilder? member = node.classBuilder.findConstructorOrFactory(
              token.lexeme, token.charOffset, uri, currentLibrary);
          if (member != null) {
            push(new _MacroConstructorNode(node.classBuilder, token.lexeme));
          } else {
            pushUnsupported();
          }
        } else {
          pushUnsupported();
        }
        break;
      case IdentifierContext.namedArgumentReference:
        push(new _NamedArgumentIdentifierNode(token.lexeme));
        break;
      default:
        pushUnsupported();
        break;
    }
  }

  @override
  void beginArguments(Token token) {
    // Do nothing.
  }

  @override
  void endArguments(int count, Token beginToken, Token endToken) {
    if (unrecognized) {
      pushUnsupported();
      return;
    }
    List<macro.Argument> positionalArguments = [];
    Map<String, macro.Argument> namedArguments = {};
    for (int i = 0; i < count; i++) {
      _Node node = pop();
      if (node is _PrimitiveValueNode) {
        positionalArguments.add(node.argument);
      } else if (node is _NamedArgumentNode &&
          !namedArguments.containsKey(node.name)) {
        namedArguments[node.name] = node.argument;
      } else {
        _unsupported();
      }
    }
    if (unrecognized) {
      pushUnsupported();
    } else {
      push(new _ArgumentsNode(positionalArguments, namedArguments));
    }
  }

  @override
  void handleObjectPatternFields(int count, Token beginToken, Token endToken) {
    _unsupported();
  }

  @override
  void handleNoArguments(Token token) {
    push(const _NoArgumentsNode());
  }

  @override
  void handleNoTypeArguments(Token token) {
    // TODO(johnniwinther): Handle type arguments. Ignore for now.
  }

  @override
  void handleQualified(Token period) {
    // Do nothing. Supported qualified names are handled through the identifier
    // context.
  }

  @override
  void handleNamedArgument(Token colon) {
    if (unrecognized) {
      pushUnsupported();
    } else {
      _Node value = pop();
      _Node name = pop();
      if (name is _NamedArgumentIdentifierNode &&
          value is _PrimitiveValueNode) {
        push(new _NamedArgumentNode(name.name, value.argument));
      } else {
        pushUnsupported();
      }
    }
  }

  @override
  void handlePatternField(Token? colon) {
    _unsupported();
  }

  @override
  // TODO: Handle directly.
  void handleNamedRecordField(Token colon) => handleNamedArgument(colon);

  @override
  void handleLiteralNull(Token token) {
    push(new _PrimitiveValueNode(new macro.NullArgument()));
  }

  @override
  void handleLiteralBool(Token token) {
    push(new _PrimitiveValueNode(
        new macro.BoolArgument(token.lexeme == 'true')));
  }

  @override
  void handleLiteralDouble(Token token) {
    push(new _PrimitiveValueNode(
        new macro.DoubleArgument(double.parse(token.lexeme))));
  }

  @override
  void handleLiteralInt(Token token) {
    push(new _PrimitiveValueNode(
        new macro.IntArgument(int.parse(token.lexeme))));
  }

  @override
  void beginLiteralString(Token token) {
    push(new _TokenNode(token));
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    if (unrecognized) {
      pushUnsupported();
      return;
    }
    if (interpolationCount == 0) {
      _Node node = pop();
      if (node is _TokenNode) {
        String text = unescapeString(node.token.lexeme, node.token, this);
        if (unrecognized) {
          pushUnsupported();
        } else {
          push(new _PrimitiveValueNode(new macro.StringArgument(text)));
        }
      } else {
        pushUnsupported();
      }
    } else {
      // TODO(johnniwinther): Should we support this?
      pushUnsupported();
    }
  }

  @override
  void handleStringPart(Token token) {
    // TODO(johnniwinther): Should we support this?
    _unhandled();
  }

  @override
  void handleStringJuxtaposition(Token startToken, int literalCount) {
    if (unrecognized) {
      pushUnsupported();
    } else {
      List<String> values = [];
      for (int i = 0; i < literalCount; i++) {
        _Node node = pop();
        if (node is _PrimitiveValueNode && node.value is String) {
          values.add(node.value as String);
        } else {
          _unsupported();
        }
      }
      if (unrecognized) {
        pushUnsupported();
      } else {
        push(new _PrimitiveValueNode(
            new macro.StringArgument(values.reversed.join())));
      }
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Stub implementation
  //////////////////////////////////////////////////////////////////////////////

  /// Called for listener events that are expected but not supported.
  void _unsupported() {
    unrecognized = true;
  }

  /// Called for listener events that are unexpected.
  void _unexpected() {
    unrecognized = true;
  }

  /// Called for listener events that are supported but not handled yet.
  void _unhandled() {
    unrecognized = true;
  }

  /// Called for listener events whose use in unknown.
  void _unknown() {
    unrecognized = true;
  }

  @override
  void beginAsOperatorType(Token operator) {
    _unsupported();
  }

  @override
  void beginAssert(Token assertKeyword, Assert kind) {
    _unsupported();
  }

  @override
  void beginAwaitExpression(Token token) {
    _unsupported();
  }

  @override
  void beginBinaryExpression(Token token) {
    _unsupported();
  }

  @override
  void beginBinaryPattern(Token token) {
    _unsupported();
  }

  @override
  void beginBlock(Token token, BlockKind blockKind) {
    _unsupported();
  }

  @override
  void beginBlockFunctionBody(Token token) {
    _unsupported();
  }

  @override
  void beginCascade(Token token) {
    _unsupported();
  }

  @override
  void beginCaseExpression(Token caseKeyword) {
    _unsupported();
  }

  @override
  void beginCatchClause(Token token) {
    _unsupported();
  }

  @override
  void beginClassDeclaration(
      Token begin,
      Token? abstractToken,
      Token? macroToken,
      Token? sealedToken,
      Token? baseToken,
      Token? interfaceToken,
      Token? finalToken,
      Token? augmentToken,
      Token? mixinToken,
      Token name) {
    _unexpected();
  }

  @override
  void beginClassOrMixinOrExtensionBody(DeclarationKind kind, Token token) {
    _unexpected();
  }

  @override
  void beginClassOrMixinOrNamedMixinApplicationPrelude(Token token) {
    _unexpected();
  }

  @override
  void beginCombinators(Token token) {
    _unexpected();
  }

  @override
  void beginCompilationUnit(Token token) {
    _unexpected();
  }

  @override
  void beginConditionalExpression(Token question) {
    _unsupported();
  }

  @override
  void beginConditionalUri(Token ifKeyword) {
    _unexpected();
  }

  @override
  void beginConditionalUris(Token token) {
    _unexpected();
  }

  @override
  void beginConstExpression(Token constKeyword) {
    _unhandled();
  }

  @override
  void beginConstLiteral(Token token) {
    _unhandled();
  }

  @override
  void beginConstructorReference(Token start) {
    _unknown();
  }

  @override
  void beginDoWhileStatement(Token token) {
    _unsupported();
  }

  @override
  void beginDoWhileStatementBody(Token token) {
    _unsupported();
  }

  @override
  void beginElseStatement(Token token) {
    _unsupported();
  }

  @override
  void beginEnum(Token enumKeyword) {
    _unexpected();
  }

  @override
  void beginExport(Token token) {
    _unexpected();
  }

  @override
  void beginExtensionDeclaration(Token extensionKeyword, Token? name) {
    _unexpected();
  }

  @override
  void beginExtensionDeclarationPrelude(Token extensionKeyword) {
    _unexpected();
  }

  @override
  void beginFactoryMethod(DeclarationKind declarationKind, Token lastConsumed,
      Token? externalToken, Token? constToken) {
    _unexpected();
  }

  @override
  void beginFieldInitializer(Token token) {
    _unexpected();
  }

  @override
  void beginFields(
      DeclarationKind declarationKind,
      Token? abstractToken,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      Token lastConsumed) {
    _unexpected();
  }

  @override
  void beginForControlFlow(Token? awaitToken, Token forToken) {
    _unsupported();
  }

  @override
  void beginForInBody(Token token) {
    _unsupported();
  }

  @override
  void beginForInExpression(Token token) {
    _unsupported();
  }

  @override
  void beginForStatement(Token token) {
    _unsupported();
  }

  @override
  void beginForStatementBody(Token token) {
    _unsupported();
  }

  @override
  void beginFormalParameter(Token token, MemberKind kind, Token? requiredToken,
      Token? covariantToken, Token? varFinalOrConst) {
    _unsupported();
  }

  @override
  void beginFormalParameterDefaultValueExpression() {
    _unsupported();
  }

  @override
  void beginFormalParameters(Token token, MemberKind kind) {
    _unsupported();
  }

  @override
  void beginFunctionExpression(Token token) {
    _unsupported();
  }

  @override
  void beginFunctionName(Token token) {
    _unsupported();
  }

  @override
  void beginRecordType(Token beginToken) {
    _unhandled();
  }

  @override
  void endRecordType(
      Token leftBracket, Token? questionMark, int count, bool hasNamedFields) {
    _unhandled();
  }

  @override
  void beginRecordTypeEntry() {
    _unhandled();
  }

  @override
  void endRecordTypeEntry() {
    _unhandled();
  }

  @override
  void beginRecordTypeNamedFields(Token leftBracket) {
    _unhandled();
  }

  @override
  void endRecordTypeNamedFields(int count, Token leftBracket) {
    _unhandled();
  }

  @override
  void beginFunctionType(Token beginToken) {
    _unhandled();
  }

  @override
  void beginFunctionTypedFormalParameter(Token token) {
    _unknown();
  }

  @override
  void beginHide(Token hideKeyword) {
    _unexpected();
  }

  @override
  void beginIfControlFlow(Token ifToken) {
    _unsupported();
  }

  @override
  void beginIfStatement(Token token) {
    _unsupported();
  }

  @override
  void beginImplicitCreationExpression(Token token) {
    _unhandled();
  }

  @override
  void beginImport(Token importKeyword) {
    _unexpected();
  }

  @override
  void beginInitializedIdentifier(Token token) {
    _unsupported();
  }

  @override
  void beginInitializer(Token token) {
    _unexpected();
  }

  @override
  void beginInitializers(Token token) {
    _unexpected();
  }

  @override
  void beginIsOperatorType(Token operator) {
    _unhandled();
  }

  @override
  void beginLabeledStatement(Token token, int labelCount) {
    _unsupported();
  }

  @override
  void beginLibraryAugmentation(Token libraryKeyword, Token augmentKeyword) {
    _unexpected();
  }

  @override
  void endLibraryAugmentation(
      Token libraryKeyword, Token augmentKeyword, Token semicolon) {
    _unexpected();
  }

  @override
  void beginLibraryName(Token token) {
    _unexpected();
  }

  @override
  void beginLiteralSymbol(Token token) {
    _unhandled();
  }

  @override
  void beginLocalFunctionDeclaration(Token token) {
    _unsupported();
  }

  @override
  void beginMember() {
    _unexpected();
  }

  @override
  void beginMetadataStar(Token token) {
    _unsupported();
  }

  @override
  void beginMethod(
      DeclarationKind declarationKind,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? varFinalOrConst,
      Token? getOrSet,
      Token name) {
    _unexpected();
  }

  @override
  void beginMixinDeclaration(Token beginToken, Token? augmentToken,
      Token? baseToken, Token mixinKeyword, Token name) {
    _unexpected();
  }

  @override
  void beginNamedFunctionExpression(Token token) {
    _unsupported();
  }

  @override
  void beginNamedMixinApplication(
      Token begin,
      Token? abstractToken,
      Token? macroToken,
      Token? sealedToken,
      Token? baseToken,
      Token? interfaceToken,
      Token? finalToken,
      Token? augmentToken,
      Token? mixinToken,
      Token name) {
    _unexpected();
  }

  @override
  void beginNewExpression(Token token) {
    _unsupported();
  }

  @override
  void beginOptionalFormalParameters(Token token) {
    _unsupported();
  }

  @override
  void beginPart(Token token) {
    _unexpected();
  }

  @override
  void beginPartOf(Token token) {
    _unexpected();
  }

  @override
  void beginRedirectingFactoryBody(Token token) {
    _unexpected();
  }

  @override
  void beginRethrowStatement(Token token) {
    _unsupported();
  }

  @override
  void beginReturnStatement(Token token) {
    _unsupported();
  }

  @override
  void beginShow(Token showKeyword) {
    _unexpected();
  }

  @override
  void beginSwitchBlock(Token token) {
    _unsupported();
  }

  @override
  void beginSwitchExpressionBlock(Token token) {
    _unsupported();
  }

  @override
  void beginSwitchCase(int labelCount, int expressionCount, Token firstToken) {
    _unsupported();
  }

  @override
  void beginSwitchExpressionCase() {
    _unsupported();
  }

  @override
  void beginSwitchStatement(Token token) {
    _unsupported();
  }

  @override
  void beginSwitchExpression(Token token) {
    _unsupported();
  }

  @override
  void beginThenStatement(Token token) {
    _unsupported();
  }

  @override
  void beginTopLevelMember(Token token) {
    _unexpected();
  }

  @override
  void beginTopLevelMethod(
      Token lastConsumed, Token? augmentToken, Token? externalToken) {
    _unexpected();
  }

  @override
  void beginTryStatement(Token token) {
    _unsupported();
  }

  @override
  void beginTypeArguments(Token token) {
    _unhandled();
  }

  @override
  void beginTypeList(Token token) {
    _unexpected();
  }

  @override
  void beginTypeVariable(Token token) {
    _unsupported();
  }

  @override
  void beginTypeVariables(Token token) {
    _unsupported();
  }

  @override
  void beginTypedef(Token token) {
    _unexpected();
  }

  @override
  void beginUncategorizedTopLevelDeclaration(Token token) {
    _unexpected();
  }

  @override
  void beginVariableInitializer(Token token) {
    _unsupported();
  }

  @override
  void beginVariablesDeclaration(
      Token token, Token? lateToken, Token? varFinalOrConst) {
    _unsupported();
  }

  @override
  void beginWhileStatement(Token token) {
    _unsupported();
  }

  @override
  void beginWhileStatementBody(Token token) {
    _unsupported();
  }

  @override
  void beginYieldStatement(Token token) {
    _unsupported();
  }

  @override
  void endAsOperatorType(Token operator) {
    _unhandled();
  }

  @override
  void endAssert(Token assertKeyword, Assert kind, Token leftParenthesis,
      Token? commaToken, Token semicolonToken) {
    _unsupported();
  }

  @override
  void endAwaitExpression(Token beginToken, Token endToken) {
    _unsupported();
  }

  @override
  void endBinaryExpression(Token token) {
    _unknown();
  }

  @override
  void endBinaryPattern(Token token) {
    _unsupported();
  }

  @override
  void endBlock(
      int count, Token beginToken, Token endToken, BlockKind blockKind) {
    _unsupported();
  }

  @override
  void endBlockFunctionBody(int count, Token beginToken, Token endToken) {
    _unsupported();
  }

  @override
  void endCascade() {
    _unsupported();
  }

  @override
  void endCaseExpression(Token caseKeyword, Token? when, Token colon) {
    _unsupported();
  }

  @override
  void endCatchClause(Token token) {
    _unsupported();
  }

  @override
  void endClassConstructor(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    _unexpected();
  }

  @override
  void endClassDeclaration(Token beginToken, Token endToken) {
    _unexpected();
  }

  @override
  void endClassFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    _unexpected();
  }

  @override
  void endClassFields(
      Token? abstractToken,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    _unexpected();
  }

  @override
  void endClassMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    _unexpected();
  }

  @override
  void endClassOrMixinOrExtensionBody(
      DeclarationKind kind, int memberCount, Token beginToken, Token endToken) {
    _unexpected();
  }

  @override
  void endCombinators(int count) {
    _unexpected();
  }

  @override
  void endCompilationUnit(int count, Token token) {
    _unexpected();
  }

  @override
  void endConditionalExpression(Token question, Token colon) {
    _unhandled();
  }

  @override
  void endConditionalUri(Token ifKeyword, Token leftParen, Token? equalSign) {
    _unexpected();
  }

  @override
  void endConditionalUris(int count) {
    _unexpected();
  }

  @override
  void endConstExpression(Token token) {
    _unknown();
  }

  @override
  void endConstLiteral(Token token) {
    _unknown();
  }

  @override
  void endConstructorReference(Token start, Token? periodBeforeName,
      Token endToken, ConstructorReferenceContext constructorReferenceContext) {
    _unknown();
  }

  @override
  void endDoWhileStatement(
      Token doKeyword, Token whileKeyword, Token endToken) {
    _unsupported();
  }

  @override
  void endDoWhileStatementBody(Token token) {
    _unsupported();
  }

  @override
  void endElseStatement(Token token) {
    _unsupported();
  }

  @override
  void endEnum(Token beginToken, Token enumKeyword, Token leftBrace,
      int memberCount, Token endToken) {
    _unexpected();
  }

  @override
  void endEnumConstructor(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    _unexpected();
  }

  @override
  void endEnumFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    _unexpected();
  }

  @override
  void endEnumFields(
      Token? abstractToken,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    _unexpected();
  }

  @override
  void endEnumMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    _unexpected();
  }

  @override
  void endExport(Token exportKeyword, Token semicolon) {
    _unexpected();
  }

  @override
  void endExtensionConstructor(Token? getOrSet, Token beginToken,
      Token beginParam, Token? beginInitializers, Token endToken) {
    _unexpected();
  }

  @override
  void endExtensionDeclaration(Token beginToken, Token extensionKeyword,
      Token onKeyword, Token endToken) {
    _unexpected();
  }

  @override
  void endExtensionFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    _unexpected();
  }

  @override
  void endExtensionFields(
      Token? abstractToken,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    _unexpected();
  }

  @override
  void endExtensionMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    _unexpected();
  }

  @override
  void endFieldInitializer(Token assignment, Token token) {
    _unexpected();
  }

  @override
  void endForControlFlow(Token token) {
    _unsupported();
  }

  @override
  void endForIn(Token endToken) {
    _unsupported();
  }

  @override
  void endForInBody(Token token) {
    _unsupported();
  }

  @override
  void endForInControlFlow(Token token) {
    _unsupported();
  }

  @override
  void endForInExpression(Token token) {
    _unsupported();
  }

  @override
  void endForStatement(Token endToken) {
    _unsupported();
  }

  @override
  void endForStatementBody(Token token) {
    _unsupported();
  }

  @override
  void endFormalParameter(
      Token? thisKeyword,
      Token? superKeyword,
      Token? periodAfterThisOrSuper,
      Token nameToken,
      Token? initializerStart,
      Token? initializerEnd,
      FormalParameterKind kind,
      MemberKind memberKind) {
    _unsupported();
  }

  @override
  void endFormalParameterDefaultValueExpression() {
    _unsupported();
  }

  @override
  void endFormalParameters(
      int count, Token beginToken, Token endToken, MemberKind kind) {
    _unsupported();
  }

  @override
  void endFunctionExpression(Token beginToken, Token token) {
    _unsupported();
  }

  @override
  void endFunctionName(Token beginToken, Token token) {
    _unsupported();
  }

  @override
  void endFunctionType(Token functionToken, Token? questionMark) {
    _unhandled();
  }

  @override
  void endFunctionTypedFormalParameter(Token nameToken, Token? question) {
    _unknown();
  }

  @override
  void endHide(Token hideKeyword) {
    _unexpected();
  }

  @override
  void endIfControlFlow(Token token) {
    _unsupported();
  }

  @override
  void endIfElseControlFlow(Token token) {
    _unsupported();
  }

  @override
  void endIfStatement(Token ifToken, Token? elseToken) {
    _unsupported();
  }

  @override
  void endImplicitCreationExpression(Token token, Token openAngleBracket) {
    _unhandled();
  }

  @override
  void endImport(Token importKeyword, Token? augmentToken, Token? semicolon) {
    _unexpected();
  }

  @override
  void endInitializedIdentifier(Token nameToken) {
    _unsupported();
  }

  @override
  void endInitializer(Token token) {
    _unexpected();
  }

  @override
  void endInitializers(int count, Token beginToken, Token endToken) {
    _unexpected();
  }

  @override
  void endInvalidAwaitExpression(
      Token beginToken, Token endToken, MessageCode errorCode) {
    _unsupported();
  }

  @override
  void endInvalidYieldStatement(Token beginToken, Token? starToken,
      Token endToken, MessageCode errorCode) {
    _unsupported();
  }

  @override
  void endIsOperatorType(Token operator) {
    _unhandled();
  }

  @override
  void endLabeledStatement(int labelCount) {
    _unsupported();
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon, bool hasName) {
    _unexpected();
  }

  @override
  void endLiteralSymbol(Token hashToken, int identifierCount) {
    _unhandled();
  }

  @override
  void endLocalFunctionDeclaration(Token endToken) {
    _unsupported();
  }

  @override
  void endMember() {
    _unexpected();
  }

  @override
  void endMetadataStar(int count) {
    _unsupported();
  }

  @override
  void endMixinConstructor(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    _unexpected();
  }

  @override
  void endMixinDeclaration(Token beginToken, Token endToken) {
    _unexpected();
  }

  @override
  void endMixinFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    _unexpected();
  }

  @override
  void endMixinFields(
      Token? abstractToken,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    _unexpected();
  }

  @override
  void endMixinMethod(Token? getOrSet, Token beginToken, Token beginParam,
      Token? beginInitializers, Token endToken) {
    _unexpected();
  }

  @override
  void endNamedFunctionExpression(Token endToken) {
    _unsupported();
  }

  @override
  void endNamedMixinApplication(Token begin, Token classKeyword, Token equals,
      Token? implementsKeyword, Token endToken) {
    _unexpected();
  }

  @override
  void endNewExpression(Token token) {
    _unsupported();
  }

  @override
  void endOptionalFormalParameters(
      int count, Token beginToken, Token endToken) {
    _unsupported();
  }

  @override
  void endPart(Token partKeyword, Token semicolon) {
    _unexpected();
  }

  @override
  void endPartOf(
      Token partKeyword, Token ofKeyword, Token semicolon, bool hasName) {
    _unexpected();
  }

  @override
  void endRedirectingFactoryBody(Token beginToken, Token endToken) {
    _unexpected();
  }

  @override
  void endRethrowStatement(Token rethrowToken, Token endToken) {
    _unsupported();
  }

  @override
  void endReturnStatement(
      bool hasExpression, Token beginToken, Token endToken) {
    _unsupported();
  }

  @override
  void endShow(Token showKeyword) {
    _unexpected();
  }

  @override
  void endSwitchBlock(int caseCount, Token beginToken, Token endToken) {
    _unsupported();
  }

  @override
  void endSwitchExpressionBlock(
      int caseCount, Token beginToken, Token endToken) {
    _unsupported();
  }

  @override
  void endSwitchCase(
      int labelCount,
      int expressionCount,
      Token? defaultKeyword,
      Token? colonAfterDefault,
      int statementCount,
      Token firstToken,
      Token endToken) {
    _unsupported();
  }

  @override
  void endSwitchExpressionCase(Token? when, Token arrow, Token endToken) {
    _unsupported();
  }

  @override
  void endSwitchStatement(Token switchKeyword, Token endToken) {
    _unsupported();
  }

  @override
  void endSwitchExpression(Token switchKeyword, Token endToken) {
    _unsupported();
  }

  @override
  void endThenStatement(Token token) {
    _unsupported();
  }

  @override
  void endTopLevelDeclaration(Token nextToken) {
    _unexpected();
  }

  @override
  void endTopLevelFields(
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    _unexpected();
  }

  @override
  void endTopLevelMethod(Token beginToken, Token? getOrSet, Token endToken) {
    _unexpected();
  }

  @override
  void endTryStatement(
      int catchCount, Token tryKeyword, Token? finallyKeyword) {
    _unsupported();
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    _unhandled();
  }

  @override
  void endTypeList(int count) {
    _unexpected();
  }

  @override
  void endTypeVariable(
      Token token, int index, Token? extendsOrSuper, Token? variance) {
    _unsupported();
  }

  @override
  void endTypeVariables(Token beginToken, Token endToken) {
    _unsupported();
  }

  @override
  void endTypedef(Token typedefKeyword, Token? equals, Token endToken) {
    _unexpected();
  }

  @override
  void endVariableInitializer(Token assignmentOperator) {
    _unsupported();
  }

  @override
  void endVariablesDeclaration(int count, Token? endToken) {
    _unsupported();
  }

  @override
  void endWhileStatement(Token whileKeyword, Token endToken) {
    _unsupported();
  }

  @override
  void endWhileStatementBody(Token token) {
    _unsupported();
  }

  @override
  void endYieldStatement(Token yieldToken, Token? starToken, Token endToken) {
    _unsupported();
  }

  @override
  void handleAsOperator(Token operator) {
    _unhandled();
  }

  @override
  void handleCastPattern(Token operator) {
    _unsupported();
  }

  @override
  void handleAssignmentExpression(Token token) {
    _unsupported();
  }

  @override
  void handleAsyncModifier(Token? asyncToken, Token? starToken) {
    _unsupported();
  }

  @override
  void handleBreakStatement(
      bool hasTarget, Token breakKeyword, Token endToken) {
    _unsupported();
  }

  @override
  void handleCatchBlock(Token? onKeyword, Token? catchKeyword, Token? comma) {
    _unsupported();
  }

  @override
  void handleClassExtends(Token? extendsKeyword, int typeCount) {
    _unexpected();
  }

  @override
  void handleClassHeader(Token begin, Token classKeyword, Token? nativeToken) {
    _unexpected();
  }

  @override
  void handleClassNoWithClause() {
    _unexpected();
  }

  @override
  void handleClassWithClause(Token withKeyword) {
    _unexpected();
  }

  @override
  void handleMixinWithClause(Token withKeyword) {
    _unexpected();
  }

  @override
  void handleConditionalExpressionColon() {
    _unhandled();
  }

  @override
  void handleConstFactory(Token constKeyword) {
    _unexpected();
  }

  @override
  void handleContinueStatement(
      bool hasTarget, Token continueKeyword, Token endToken) {
    _unsupported();
  }

  @override
  void handleDirectivesOnly() {
    _unknown();
  }

  @override
  void handleDottedName(int count, Token firstIdentifier) {
    _unknown();
  }

  @override
  void handleElseControlFlow(Token elseToken) {
    _unsupported();
  }

  @override
  void handleEmptyFunctionBody(Token semicolon) {
    _unsupported();
  }

  @override
  void handleEmptyStatement(Token token) {
    _unsupported();
  }

  @override
  void handleEndingBinaryExpression(Token token) {
    _unknown();
  }

  @override
  void handleEnumElement(Token beginToken) {
    _unexpected();
  }

  @override
  void handleEnumElements(Token elementsEndToken, int elementsCount) {
    _unexpected();
  }

  @override
  void handleEnumHeader(Token enumKeyword, Token leftBrace) {
    _unexpected();
  }

  @override
  void handleEnumNoWithClause() {
    _unexpected();
  }

  @override
  void handleEnumWithClause(Token withKeyword) {
    _unexpected();
  }

  @override
  void handleErrorToken(ErrorToken token) {
    _unsupported();
  }

  @override
  void handleExpressionFunctionBody(Token arrowToken, Token? endToken) {
    _unsupported();
  }

  @override
  void handleExpressionStatement(Token token) {
    _unsupported();
  }

  @override
  void handleExtraneousExpression(Token token, Message message) {
    _unknown();
  }

  @override
  void handleFinallyBlock(Token finallyKeyword) {
    _unsupported();
  }

  @override
  void handleForInLoopParts(Token? awaitToken, Token forToken,
      Token leftParenthesis, Token? patternKeyword, Token inKeyword) {
    _unsupported();
  }

  @override
  void handleForInitializerEmptyStatement(Token token) {
    _unsupported();
  }

  @override
  void handleForInitializerExpressionStatement(Token token, bool forIn) {
    _unsupported();
  }

  @override
  void handleForInitializerLocalVariableDeclaration(Token token, bool forIn) {
    _unsupported();
  }

  @override
  void handleForInitializerPatternVariableAssignment(
      Token keyword, Token equals) {
    _unsupported();
  }

  @override
  void handleForLoopParts(Token forKeyword, Token leftParen,
      Token leftSeparator, int updateExpressionCount) {
    _unsupported();
  }

  @override
  void handleFormalParameterWithoutValue(Token token) {
    _unsupported();
  }

  @override
  void handleFunctionBodySkipped(Token token, bool isExpressionBody) {
    _unsupported();
  }

  @override
  void handleIdentifierList(int count) {
    _unknown();
  }

  @override
  void handleImplements(Token? implementsKeyword, int interfacesCount) {
    _unexpected();
  }

  @override
  void handleImportPrefix(Token? deferredKeyword, Token? asKeyword) {
    _unexpected();
  }

  @override
  void handleIndexedExpression(
      Token? question, Token openSquareBracket, Token closeSquareBracket) {
    _unsupported();
  }

  @override
  void handleInterpolationExpression(Token leftBracket, Token? rightBracket) {
    _unhandled();
  }

  @override
  void handleInvalidExpression(Token token) {
    _unsupported();
  }

  @override
  void handleInvalidFunctionBody(Token token) {
    _unsupported();
  }

  @override
  void handleInvalidMember(Token endToken) {
    _unexpected();
  }

  @override
  void handleInvalidOperatorName(Token operatorKeyword, Token token) {
    _unexpected();
  }

  @override
  void handleInvalidStatement(Token token, Message message) {
    _unsupported();
  }

  @override
  void handleInvalidTopLevelBlock(Token token) {
    _unexpected();
  }

  @override
  void handleInvalidTopLevelDeclaration(Token endToken) {
    _unexpected();
  }

  @override
  void handleInvalidTypeArguments(Token token) {
    _unsupported();
  }

  @override
  void handleInvalidTypeReference(Token token) {
    _unsupported();
  }

  @override
  void handleIsOperator(Token isOperator, Token? not) {
    _unhandled();
  }

  @override
  void handleLabel(Token token) {
    _unsupported();
  }

  @override
  void handleLiteralList(
      int count, Token leftBracket, Token? constKeyword, Token rightBracket) {
    _unhandled();
  }

  @override
  void handleListPattern(int count, Token leftBracket, Token rightBracket) {
    _unsupported();
  }

  @override
  void handleLiteralMapEntry(Token colon, Token endToken) {
    _unhandled();
  }

  @override
  void handleMapPattern(int count, Token leftBrace, Token rightBrace) {
    _unsupported();
  }

  @override
  void handleMapPatternEntry(Token colon, Token endToken) {
    _unsupported();
  }

  @override
  void handleLiteralSetOrMap(int count, Token leftBrace, Token? constKeyword,
      Token rightBrace, bool hasSetEntry) {
    _unhandled();
  }

  @override
  void handleMixinHeader(Token mixinKeyword) {
    _unexpected();
  }

  @override
  void handleMixinOn(Token? onKeyword, int typeCount) {
    _unexpected();
  }

  @override
  void handleNamedMixinApplicationWithClause(Token withKeyword) {
    _unexpected();
  }

  @override
  void handleNativeClause(Token nativeToken, bool hasName) {
    _unexpected();
  }

  @override
  void handleNativeFunctionBody(Token nativeToken, Token semicolon) {
    _unexpected();
  }

  @override
  void handleNativeFunctionBodyIgnored(Token nativeToken, Token semicolon) {
    _unexpected();
  }

  @override
  void handleNativeFunctionBodySkipped(Token nativeToken, Token semicolon) {
    _unexpected();
  }

  @override
  void handleNewAsIdentifier(Token token) {
    _unhandled();
  }

  @override
  void handleNoConstructorReferenceContinuationAfterTypeArguments(Token token) {
    _unknown();
  }

  @override
  void handleNoFieldInitializer(Token token) {
    _unexpected();
  }

  @override
  void handleNoFormalParameters(Token token, MemberKind kind) {
    _unsupported();
  }

  @override
  void handleNoFunctionBody(Token token) {
    _unsupported();
  }

  @override
  void handleNoInitializers() {
    _unexpected();
  }

  @override
  void handleNoName(Token token) {
    _unknown();
  }

  @override
  void handleNoType(Token lastConsumed) {
    _unknown();
  }

  @override
  void handleNoTypeNameInConstructorReference(Token token) {
    _unknown();
  }

  @override
  void handleNoTypeVariables(Token token) {
    _unsupported();
  }

  @override
  void handleNoVariableInitializer(Token token) {
    _unsupported();
  }

  @override
  void handleNonNullAssertExpression(Token bang) {
    _unsupported();
  }

  @override
  void handleNullAssertPattern(Token bang) {
    _unsupported();
  }

  @override
  void handleNullCheckPattern(Token question) {
    _unsupported();
  }

  @override
  void handleAssignedVariablePattern(Token variable) {
    _unsupported();
  }

  @override
  void handleDeclaredVariablePattern(Token? keyword, Token variable,
      {required bool inAssignmentPattern}) {
    _unsupported();
  }

  @override
  void handleWildcardPattern(Token? keyword, Token wildcard) {
    _unsupported();
  }

  @override
  void handleOperator(Token token) {
    _unknown();
  }

  @override
  void handleOperatorName(Token operatorKeyword, Token token) {
    _unexpected();
  }

  @override
  void handleParenthesizedCondition(Token token, Token? case_, Token? when) {
    _unknown();
  }

  @override
  void beginPattern(Token token) {
    _unhandled();
  }

  @override
  void beginPatternGuard(Token token) {
    _unhandled();
  }

  @override
  void beginParenthesizedExpressionOrRecordLiteral(Token token) {
    _unhandled();
  }

  @override
  void beginSwitchCaseWhenClause(Token when) {
    _unhandled();
  }

  @override
  void endRecordLiteral(Token token, int count, Token? constKeyword) {
    _unhandled();
  }

  @override
  void handleRecordPattern(Token token, int count) {
    _unsupported();
  }

  @override
  void endPattern(Token token) {
    _unhandled();
  }

  @override
  void endPatternGuard(Token token) {
    _unhandled();
  }

  @override
  void endParenthesizedExpression(Token token) {
    _unhandled();
  }

  @override
  void endSwitchCaseWhenClause(Token token) {
    _unhandled();
  }

  @override
  void handleParenthesizedPattern(Token token) {
    _unsupported();
  }

  @override
  void beginConstantPattern(Token? constKeyword) {
    _unsupported();
  }

  @override
  void endConstantPattern(Token? constKeyword) {
    _unsupported();
  }

  @override
  void handleObjectPattern(
      Token firstIdentifier, Token? dot, Token? secondIdentifier) {
    _unsupported();
  }

  @override
  void handleRecoverDeclarationHeader(DeclarationHeaderKind kind) {
    _unexpected();
  }

  @override
  void handleRecoverImport(Token? semicolon) {
    _unexpected();
  }

  @override
  void handleRecoverMixinHeader() {
    _unexpected();
  }

  @override
  void handleRecoverableError(
      Message message, Token startToken, Token endToken) {
    _unsupported();
  }

  @override
  void handleScript(Token token) {
    _unexpected();
  }

  @override
  void handleSend(Token beginToken, Token endToken) {
    _unhandled();
  }

  @override
  void handleSpreadExpression(Token spreadToken) {
    _unsupported();
  }

  @override
  void handleRestPattern(Token dots, {required bool hasSubPattern}) {
    _unsupported();
  }

  @override
  void handleSuperExpression(Token token, IdentifierContext context) {
    _unsupported();
  }

  @override
  void handleAugmentSuperExpression(
      Token augmentToken, Token superToken, IdentifierContext context) {
    _unsupported();
  }

  @override
  void handleSwitchCaseNoWhenClause(Token token) {
    _unhandled();
  }

  @override
  void handleSwitchExpressionCasePattern(Token token) {
    _unhandled();
  }

  @override
  void handleSymbolVoid(Token token) {
    _unhandled();
  }

  @override
  void handleThenControlFlow(Token token) {
    _unsupported();
  }

  @override
  void handleThisExpression(Token token, IdentifierContext context) {
    _unsupported();
  }

  @override
  void handleThrowExpression(Token throwToken, Token endToken) {
    _unsupported();
  }

  @override
  void handleType(Token beginToken, Token? questionMark) {
    _unknown();
  }

  @override
  void handleTypeArgumentApplication(Token openAngleBracket) {
    _unhandled();
  }

  @override
  void handleTypeVariablesDefined(Token token, int count) {
    _unsupported();
  }

  @override
  void handleUnaryPostfixAssignmentExpression(Token token) {
    _unsupported();
  }

  @override
  void handleUnaryPrefixAssignmentExpression(Token token) {
    _unsupported();
  }

  @override
  void handleUnaryPrefixExpression(Token token) {
    _unsupported();
  }

  @override
  void handleRelationalPattern(Token token) {
    _unsupported();
  }

  @override
  void handleUnescapeError(
      Message message, covariant Token location, int stringOffset, int length) {
    _unsupported();
  }

  @override
  void handleValuedFormalParameter(
      Token equals, Token token, FormalParameterKind kind) {
    _unsupported();
  }

  @override
  void handleVoidKeyword(Token token) {
    _unknown();
  }

  @override
  void handleVoidKeywordWithTypeArguments(Token token) {
    _unsupported();
  }

  @override
  void handlePatternVariableDeclarationStatement(
      Token keyword, Token equals, Token semicolon) {
    _unsupported();
  }

  @override
  void handlePatternAssignment(Token equals) {
    _unsupported();
  }

  @override
  void logEvent(String name) {}

  @override
  void reportVarianceModifierNotEnabled(Token? variance) {
    _unsupported();
  }

  @override
  void handleExperimentNotEnabled(
      ExperimentalFlag experimentalFlag, Token startToken, Token endToken) {
    _unsupported();
  }

  @override
  void beginExtensionTypeDeclaration(Token extensionKeyword, Token name) {
    _unsupported();
  }

  @override
  void endExtensionTypeConstructor(Token? getOrSet, Token beginToken,
      Token beginParam, Token? beginInitializers, Token endToken) {
    _unsupported();
  }

  @override
  void endExtensionTypeDeclaration(Token beginToken, Token extensionKeyword,
      Token? typeKeyword, Token endToken) {
    _unsupported();
  }

  @override
  void endExtensionTypeFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    _unsupported();
  }

  @override
  void endExtensionTypeFields(
      Token? abstractToken,
      Token? augmentToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    _unsupported();
  }

  @override
  void endExtensionTypeMethod(Token? getOrSet, Token beginToken,
      Token beginParam, Token? beginInitializers, Token endToken) {
    _unsupported();
  }

  @override
  void beginPrimaryConstructor(Token beginToken) {
    _unsupported();
  }

  @override
  void endPrimaryConstructor(
      Token beginToken, Token? constKeyword, bool hasName) {
    _unsupported();
  }

  @override
  void handleNoPrimaryConstructor(Token token, Token? constKeyword) {
    _unsupported();
  }
}
