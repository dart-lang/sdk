// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.stack_listener;

import 'package:kernel/ast.dart'
    show AsyncMarker, Expression, FunctionNode, TreeNode;

import '../fasta_codes.dart'
    show
        Code,
        LocatedMessage,
        Message,
        codeCatchSyntaxExtraParameters,
        codeNativeClauseShouldBeAnnotation,
        templateInternalProblemStackNotEmpty;

import '../parser.dart'
    show Listener, MemberKind, Parser, lengthOfSpan, offsetForToken;

import '../parser/identifier_context.dart' show IdentifierContext;

import '../problems.dart'
    show internalProblem, unhandled, unimplemented, unsupported;

import '../quote.dart' show unescapeString;

import '../scanner.dart' show Token;

enum NullValue {
  Arguments,
  As,
  AwaitToken,
  Block,
  BreakTarget,
  CascadeReceiver,
  Combinators,
  Comments,
  ConditionalUris,
  ConditionallySelectedImport,
  ConstructorInitializerSeparator,
  ConstructorInitializers,
  ConstructorReferenceContinuationAfterTypeArguments,
  ContinueTarget,
  Deferred,
  DocumentationComment,
  Expression,
  ExtendsClause,
  FieldInitializer,
  FormalParameters,
  FunctionBody,
  FunctionBodyAsyncToken,
  FunctionBodyStarToken,
  Identifier,
  IdentifierList,
  Initializers,
  Labels,
  Metadata,
  Modifiers,
  ParameterDefaultValue,
  Prefix,
  StringLiteral,
  SwitchScope,
  Type,
  TypeArguments,
  TypeBuilderList,
  TypeList,
  TypeVariable,
  TypeVariables,
  VarFinalOrConstToken,
  WithClause,
}

abstract class StackListener extends Listener {
  final Stack stack = new Stack();

  @override
  Uri get uri;

  void discard(int n) {
    for (int i = 0; i < n; i++) {
      pop();
    }
  }

  // TODO(ahe): This doesn't belong here. Only implemented by body_builder.dart
  // and ast_builder.dart.
  void finishFunction(covariant List<Object> annotations, covariant formals,
      AsyncMarker asyncModifier, covariant body) {
    return unsupported("finishFunction", -1, uri);
  }

  // TODO(ahe): This doesn't belong here. Only implemented by body_builder.dart
  // and ast_builder.dart.
  dynamic finishFields() {
    return unsupported("finishFields", -1, uri);
  }

  // TODO(ahe): This doesn't belong here. Only implemented by body_builder.dart
  // and ast_builder.dart.
  List<Expression> finishMetadata(TreeNode parent) {
    return unsupported("finishMetadata", -1, uri);
  }

  // TODO(ahe): This doesn't belong here. Only implemented by body_builder.dart
  // and ast_builder.dart.
  void exitLocalScope() => unsupported("exitLocalScope", -1, uri);

  // TODO(ahe): This doesn't belong here. Only implemented by body_builder.dart.
  dynamic parseSingleExpression(
      Parser parser, Token token, FunctionNode parameters) {
    return unsupported("finishSingleExpression", -1, uri);
  }

  void push(Object node) {
    if (node == null) unhandled("null", "push", -1, uri);
    stack.push(node);
  }

  void pushIfNull(Token tokenOrNull, NullValue nullValue) {
    if (tokenOrNull == null) stack.push(nullValue);
  }

  Object peek() => stack.isNotEmpty ? stack.last : null;

  Object pop([NullValue nullValue]) {
    return stack.pop(nullValue);
  }

  Object popIfNotNull(Object value) {
    return value == null ? null : pop();
  }

  void debugEvent(String name) {
    // printEvent(name);
  }

  void printEvent(String name) {
    print('\n------------------');
    for (Object o in stack.values) {
      String s = "  $o";
      int index = s.indexOf("\n");
      if (index != -1) {
        s = s.substring(0, index) + "...";
      }
      print(s);
    }
    print("  >> $name");
  }

  @override
  void logEvent(String name) {
    printEvent(name);
    unhandled(name, "$runtimeType", -1, uri);
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    debugEvent("handleIdentifier");
    if (!token.isSynthetic) {
      push(token.lexeme);
    } else {
      // This comes from a synthetic token which is inserted by the parser in
      // an attempt to recover.  This almost always means that the parser has
      // gotten very confused and we need to ignore the results.
      push(new ParserRecovery(token.charOffset));
    }
  }

  @override
  void handleNoName(Token token) {
    debugEvent("NoName");
    push(NullValue.Identifier);
  }

  @override
  void endInitializer(Token token) {
    debugEvent("Initializer");
  }

  void checkEmpty(int charOffset) {
    if (stack.isNotEmpty) {
      internalProblem(
          templateInternalProblemStackNotEmpty.withArguments(
              "${runtimeType}", stack.values.join("\n  ")),
          charOffset,
          uri);
    }
  }

  @override
  void endTopLevelDeclaration(Token token) {
    debugEvent("TopLevelDeclaration");
    checkEmpty(token.charOffset);
  }

  @override
  void endCompilationUnit(int count, Token token) {
    debugEvent("CompilationUnit");
    checkEmpty(token.charOffset);
  }

  @override
  void handleClassExtends(Token extendsKeyword) {
    debugEvent("ClassExtends");
  }

  @override
  void handleMixinOn(Token onKeyword, int typeCount) {
    debugEvent("MixinOn");
  }

  @override
  void handleClassHeader(Token begin, Token classKeyword, Token nativeToken) {
    debugEvent("ClassHeader");
  }

  @override
  void handleMixinHeader(Token mixinKeyword) {
    debugEvent("MixinHeader");
  }

  @override
  void handleRecoverClassHeader() {
    debugEvent("RecoverClassHeader");
  }

  @override
  void handleRecoverMixinHeader() {
    debugEvent("RecoverMixinHeader");
  }

  @override
  void handleClassOrMixinImplements(
      Token implementsKeyword, int interfacesCount) {
    debugEvent("ClassImplements");
  }

  @override
  void handleNoTypeArguments(Token token) {
    debugEvent("NoTypeArguments");
    push(NullValue.TypeArguments);
  }

  @override
  void handleNoTypeVariables(Token token) {
    debugEvent("NoTypeVariables");
    push(NullValue.TypeVariables);
  }

  @override
  void handleNoConstructorReferenceContinuationAfterTypeArguments(Token token) {
    debugEvent("NoConstructorReferenceContinuationAfterTypeArguments");
  }

  @override
  void handleNoType(Token lastConsumed) {
    debugEvent("NoType");
    push(NullValue.Type);
  }

  @override
  void handleNoFormalParameters(Token token, MemberKind kind) {
    debugEvent("NoFormalParameters");
    push(NullValue.FormalParameters);
  }

  @override
  void handleNoArguments(Token token) {
    debugEvent("NoArguments");
    push(NullValue.Arguments);
  }

  @override
  void handleNativeFunctionBody(Token nativeToken, Token semicolon) {
    debugEvent("NativeFunctionBody");
    push(NullValue.FunctionBody);
  }

  @override
  void handleNativeFunctionBodyIgnored(Token nativeToken, Token semicolon) {
    debugEvent("NativeFunctionBodyIgnored");
  }

  @override
  void handleNativeFunctionBodySkipped(Token nativeToken, Token semicolon) {
    debugEvent("NativeFunctionBodySkipped");
  }

  @override
  void handleNoFunctionBody(Token token) {
    debugEvent("NoFunctionBody");
    push(NullValue.FunctionBody);
  }

  @override
  void handleNoInitializers() {
    debugEvent("NoInitializers");
    push(NullValue.Initializers);
  }

  @override
  void handleParenthesizedCondition(Token token) {
    debugEvent("handleParenthesizedCondition");
  }

  @override
  void handleParenthesizedExpression(Token token) {
    debugEvent("ParenthesizedExpression");
  }

  @override
  void beginLiteralString(Token token) {
    debugEvent("beginLiteralString");
    push(token);
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    debugEvent("endLiteralString");
    if (interpolationCount == 0) {
      Token token = pop();
      push(unescapeString(token.lexeme, token, this));
    } else {
      unimplemented("string interpolation", endToken.charOffset, uri);
    }
  }

  @override
  void handleNativeClause(Token nativeToken, bool hasName) {
    debugEvent("NativeClause");
    if (hasName) {
      pop(); // Pop the native name which is a String.
    }
  }

  @override
  void handleDirectivesOnly() {
    pop(); // Discard the metadata.
  }

  void handleExtraneousExpression(Token token, Message message) {
    debugEvent("ExtraneousExpression");
    pop(); // Discard the extraneous expression.
  }

  @override
  void endCaseExpression(Token colon) {
    debugEvent("CaseExpression");
  }

  @override
  void endCatchClause(Token token) {
    debugEvent("CatchClause");
  }

  @override
  void handleRecoverableError(
      Message message, Token startToken, Token endToken) {
    debugEvent("Error: ${message.message}");
    if (isIgnoredError(message.code, startToken)) return;
    addProblem(message, offsetForToken(startToken),
        lengthOfSpan(startToken, endToken));
  }

  bool isIgnoredError(Code code, Token token) {
    if (code == codeNativeClauseShouldBeAnnotation) {
      // TODO(danrubel): Ignore this error until we deprecate `native`
      // support.
      return true;
    } else if (code == codeCatchSyntaxExtraParameters) {
      // Ignored. This error is handled by the BodyBuilder.
      return true;
    } else {
      return false;
    }
  }

  @override
  void handleUnescapeError(
      Message message, Token token, int stringOffset, int length) {
    addProblem(message, token.charOffset + stringOffset, length);
  }

  void addProblem(Message message, int charOffset, int length,
      {bool wasHandled: false, List<LocatedMessage> context});
}

class Stack {
  List<Object> array = new List<Object>(8);
  int arrayLength = 0;

  bool get isNotEmpty => arrayLength > 0;

  int get length => arrayLength;

  Object get last {
    final value = array[arrayLength - 1];
    return value is NullValue ? null : value;
  }

  void push(Object value) {
    array[arrayLength++] = value;
    if (array.length == arrayLength) {
      _grow();
    }
  }

  Object pop(NullValue nullValue) {
    assert(arrayLength > 0);
    final Object value = array[--arrayLength];
    array[arrayLength] = null;
    if (value is! NullValue) {
      return value;
    } else if (nullValue == null || value == nullValue) {
      return null;
    } else {
      return value;
    }
  }

  List<Object> popList(int count, List<Object> list, NullValue nullValue) {
    assert(arrayLength >= count);
    final List<Object> array = this.array;
    final int length = arrayLength;
    final int startIndex = length - count;
    bool isParserRecovery = false;
    for (int i = 0; i < count; i++) {
      int arrayIndex = startIndex + i;
      final Object value = array[arrayIndex];
      array[arrayIndex] = null;
      if (value is NullValue && nullValue == null ||
          identical(value, nullValue)) {
        list[i] = null;
      } else if (value is ParserRecovery) {
        isParserRecovery = true;
      } else {
        if (value is NullValue) {
          print(value);
        }
        list[i] = value;
      }
    }
    arrayLength -= count;

    return isParserRecovery ? null : list;
  }

  List<Object> get values {
    final int length = arrayLength;
    final List<Object> list = new List<Object>(length);
    list.setRange(0, length, array);
    return list;
  }

  void _grow() {
    final int length = array.length;
    final List<Object> newArray = new List<Object>(length * 2);
    newArray.setRange(0, length, array, 0);
    array = newArray;
  }
}

/// Helper constant for popping a list of the top of a [Stack].  This helper
/// returns null instead of empty lists, and the lists returned are of fixed
/// length.
class FixedNullableList<T> {
  const FixedNullableList();

  List<T> pop(Stack stack, int count, [NullValue nullValue]) {
    if (count == 0) return null;
    return stack.popList(count, new List<T>(count), nullValue);
  }

  List<T> popPadded(Stack stack, int count, int padding,
      [NullValue nullValue]) {
    if (count + padding == 0) return null;
    return stack.popList(count, new List<T>(count + padding), nullValue);
  }
}

/// Helper constant for popping a list of the top of a [Stack].  This helper
/// returns growable lists (also when empty).
class GrowableList<T> {
  const GrowableList();

  List<T> pop(Stack stack, int count, [NullValue nullValue]) {
    return stack.popList(
        count, new List<T>.filled(count, null, growable: true), nullValue);
  }
}

class ParserRecovery {
  final int charOffset;
  ParserRecovery(this.charOffset);

  String toString() => "ParserRecovery(@$charOffset)";
}
