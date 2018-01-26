// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.stack_listener;

import 'package:kernel/ast.dart' show AsyncMarker, Expression;

import '../deprecated_problems.dart' show deprecated_inputError;

import '../fasta_codes.dart'
    show
        Message,
        messageNativeClauseShouldBeAnnotation,
        templateInternalProblemStackNotEmpty;

import '../parser.dart' show Listener, MemberKind;

import '../parser/identifier_context.dart' show IdentifierContext;

import '../problems.dart'
    show internalProblem, unhandled, unimplemented, unsupported;

import '../quote.dart' show unescapeString;

import '../scanner.dart' show Token;

enum NullValue {
  Arguments,
  As,
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
  WithClause,
}

abstract class StackListener extends Listener {
  final Stack stack = new Stack();

  @override
  Uri get uri;

  // TODO(ahe): This doesn't belong here. Only implemented by body_builder.dart
  // and ast_builder.dart.
  void finishFunction(List annotations, covariant formals,
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
  List<Expression> finishMetadata() {
    return unsupported("finishMetadata", -1, uri);
  }

  // TODO(ahe): This doesn't belong here. Only implemented by body_builder.dart
  // and ast_builder.dart.
  void exitLocalScope() => unsupported("exitLocalScope", -1, uri);

  void push(Object node) {
    if (node == null) unhandled("null", "push", -1, uri);
    stack.push(node);
  }

  void pushIfNull(Token tokenOrNull, NullValue nullValue) {
    if (tokenOrNull == null) stack.push(nullValue);
  }

  Object peek() => stack.last;

  Object pop([NullValue nullValue]) {
    return stack.pop(nullValue);
  }

  Object popIfNotNull(Object value) {
    return value == null ? null : pop();
  }

  List popList(int n, [List list]) {
    if (n == 0) return null;
    return stack.popList(n, list);
  }

  void debugEvent(String name) {
    // printEvent(name);
  }

  void printEvent(String name) {
    for (Object o in stack.values) {
      String s = "  $o";
      int index = s.indexOf("\n");
      if (index != -1) {
        s = s.substring(0, index) + "...";
      }
      print(s);
    }
    print(name);
    print('------------------\n');
  }

  @override
  void logEvent(String name) {
    printEvent(name);
    unhandled(name, "$runtimeType", -1, uri);
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    debugEvent("handleIdentifier");
    push(token.lexeme);
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
    if (recoverableErrors.isNotEmpty) {
      // TODO(ahe): Handle recoverable errors better.
      deprecated_inputError(
          uri, recoverableErrors.first.beginOffset, recoverableErrors);
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
  void handleClassHeader(Token begin, Token classKeyword, Token nativeToken) {
    debugEvent("ClassHeader");
  }

  @override
  void handleRecoverClassHeader() {
    debugEvent("RecoverClassHeader");
  }

  @override
  void handleClassImplements(Token implementsKeyword, int interfacesCount) {
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
      push(unescapeString(token.lexeme));
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
  void handleStringJuxtaposition(int literalCount) {
    debugEvent("StringJuxtaposition");
    push(popList(literalCount).join(""));
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
    /// TODO(danrubel): Ignore this error until we deprecate `native` support.
    if (message == messageNativeClauseShouldBeAnnotation) {
      return;
    }
    debugEvent("Error: ${message.message}");
    int offset = startToken.offset;
    addCompileTimeError(message, offset, endToken.end - offset);
  }

  @override
  Token handleUnrecoverableError(Token token, Message message) {
    throw deprecated_inputError(uri, token.charOffset, message.message);
  }

  void addCompileTimeError(Message message, int charOffset, int length);
}

class Stack {
  List array = new List(8);
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

  Object pop([NullValue nullValue]) {
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

  List popList(int count, List list) {
    assert(arrayLength >= count);

    final table = array;
    final length = arrayLength;

    final tailList = list ?? new List.filled(count, null, growable: true);
    final startIndex = length - count;
    for (int i = 0; i < count; i++) {
      final value = table[startIndex + i];
      tailList[i] = value is NullValue ? null : value;
      table[startIndex + i] = null;
    }
    arrayLength -= count;

    return tailList;
  }

  List get values {
    final List list = new List(arrayLength);
    list.setRange(0, arrayLength, array);
    return list;
  }

  void _grow() {
    final List newTable = new List(array.length * 2);
    newTable.setRange(0, array.length, array, 0);
    array = newTable;
  }
}
