// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.stack_listener;

import '../fasta_codes.dart' show FastaMessage;

import '../parser.dart' show Listener, MemberKind;

import '../parser/identifier_context.dart' show IdentifierContext;

import '../scanner.dart' show BeginGroupToken, Token;

import 'package:kernel/ast.dart' show AsyncMarker;

import '../errors.dart' show inputError, internalError;

import '../quote.dart' show unescapeString;

import '../messages.dart' as messages;

enum NullValue {
  Arguments,
  Block,
  BreakTarget,
  CascadeReceiver,
  Combinators,
  Comments,
  ConditionalUris,
  ConstructorInitializerSeparator,
  ConstructorInitializers,
  ConstructorReferenceContinuationAfterTypeArguments,
  ContinueTarget,
  Expression,
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
  SwitchScope,
  Type,
  TypeArguments,
  TypeList,
  TypeVariable,
  TypeVariables,
}

abstract class StackListener extends Listener {
  final Stack stack = new Stack();

  @override
  Uri get uri;

  // TODO(ahe): This doesn't belong here. Only implemented by body_builder.dart
  // and ast_builder.dart.
  void finishFunction(
      covariant formals, AsyncMarker asyncModifier, covariant body) {
    return internalError("Unsupported operation");
  }

  // TODO(ahe): This doesn't belong here. Only implemented by body_builder.dart
  // and ast_builder.dart.
  void exitLocalScope() => internalError("Unsupported operation");

  // TODO(ahe): This doesn't belong here. Only implemented by body_builder.dart
  // and ast_builder.dart.
  void prepareInitializers() => internalError("Unsupported operation");

  void push(Object node) {
    if (node == null) internalError("null not allowed.");
    stack.push(node);
  }

  Object peek() => stack.last;

  Object pop() => stack.pop();

  Object popIfNotNull(Object value) {
    return value == null ? null : pop();
  }

  List popList(int n) {
    if (n == 0) return null;
    return stack.popList(n);
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
  }

  @override
  void logEvent(String name) {
    internalError("Unhandled event: $name in $runtimeType $uri:\n"
        "  ${stack.values.join('\n  ')}");
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
      internalError(
          "${runtimeType}: Stack not empty:\n"
          "  ${stack.values.join('\n  ')}",
          uri,
          charOffset);
    }
    if (recoverableErrors.isNotEmpty) {
      // TODO(ahe): Handle recoverable errors better.
      inputError(uri, recoverableErrors.first.beginOffset, recoverableErrors);
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
  void handleNoType(Token token) {
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
  void handleParenthesizedExpression(BeginGroupToken token) {
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
      internalError("String interpolation not implemented.");
    }
  }

  @override
  void handleStringJuxtaposition(int literalCount) {
    debugEvent("StringJuxtaposition");
    push(popList(literalCount).join(""));
  }

  @override
  void handleRecoverExpression(Token token) {
    debugEvent("RecoverExpression");
  }

  @override
  void endCatchClause(Token token) {
    debugEvent("CatchClause");
  }

  @override
  void handleRecoverableError(Token token, FastaMessage message) {
    debugEvent("Error: ${message.message}");
    super.handleRecoverableError(token, message);
  }

  @override
  Token handleUnrecoverableError(Token token, FastaMessage message) {
    throw inputError(uri, token.charOffset, message.message);
  }

  void nit(String message, [int charOffset = -1]) {
    messages.nit(uri, charOffset, message);
  }

  void warning(String message, [int charOffset = -1]) {
    messages.warning(uri, charOffset, message);
  }
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

  Object pop() {
    assert(arrayLength > 0);
    final Object value = array[--arrayLength];
    array[arrayLength] = null;
    return value is NullValue ? null : value;
  }

  List popList(int count) {
    assert(arrayLength >= count);

    final table = array;
    final length = arrayLength;

    final tailList = new List.filled(count, null, growable: true);
    final startIndex = length - count;
    for (int i = 0; i < count; i++) {
      final value = table[startIndex + i];
      tailList[i] = value is NullValue ? null : value;
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
