// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.stack_listener;

import 'dart:collection' show
    Queue;

import 'package:front_end/src/fasta/parser/listener.dart' show
    Listener;

import 'package:front_end/src/fasta/scanner/token.dart' show
    BeginGroupToken,
    Token;

import 'package:kernel/ast.dart' show
    AsyncMarker;

import '../errors.dart' show
    inputError,
    internalError;

import '../quote.dart' show
    unescapeString;

enum NullValue {
  Arguments,
  Block,
  BreakTarget,
  CascadeReceiver,
  Combinators,
  ContinueTarget,
  Expression,
  FormalParameters,
  FunctionBody,
  IdentifierList,
  Initializers,
  Metadata,
  Modifiers,
  SwitchScope,
  Type,
  TypeArguments,
  TypeList,
  TypeVariable,
  TypeVariables,
}

abstract class StackListener extends Listener {
  final Queue<Object> stack = new Queue<Object>();

  Uri get uri;

  // TODO(ahe): This doesn't belong here. Only implemented by body_builder.dart
  // and ast_builder.dart.
  void finishFunction(formals, AsyncMarker asyncModifier, body) {
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
    stack.addLast(node);
  }

  Object peek() {
    Object node = stack.last;
    return node is NullValue ? null : node;
  }

  Object pop() {
    Object node = stack.removeLast();
    return node is NullValue ? null : node;
  }

  Object popIfNotNull(Object value) {
    return value == null ? null : pop();
  }

  List popList(int n) {
    if (n == 0) return null;
    List list = new List.filled(n, null, growable: true);
    for (int i = n - 1; i >= 0; i--) {
      list[i] = pop();
    }
    return list;
  }

  void debugEvent(String name) {
    // printEvent(name);
  }

  void printEvent(String name) {
    for (Object o in stack) {
      String s = "  $o";
      int index = s.indexOf("\n");
      if (index != -1) {
        s = s.substring(0, index) + "...";
      }
      print(s);
    }
    print(name);
  }

  void logEvent(String name) {
    print("  ${stack.join('\n  ')}");
    internalError("Unhandled event: $name in $runtimeType $uri.");
  }

  void handleIdentifier(Token token) {
    debugEvent("handleIdentifier");
    push(token.value);
  }

  void endConstructorInitializer(Token token) {
    debugEvent("ConstructorInitializer");
  }

  void checkEmpty() {
    if (stack.isNotEmpty) {
      internalError("${runtimeType}: Stack not empty $uri:\n"
          "  ${stack.join('\n  ')}");
    }
    if (recoverableErrors.isNotEmpty) {
      // TODO(ahe): Handle recoverable errors better.
      inputError(uri, recoverableErrors.first.token.charOffset,
          recoverableErrors);
    }
  }

  void endTopLevelDeclaration(Token token) {
    debugEvent("TopLevelDeclaration");
    checkEmpty();
  }

  void endCompilationUnit(int count, Token token) {
    debugEvent("CompilationUnit");
    checkEmpty();
  }

  void handleNoTypeArguments(Token token) {
    debugEvent("NoTypeArguments");
    push(NullValue.TypeArguments);
  }

  void handleNoTypeVariables(Token token) {
    debugEvent("NoTypeVariables");
    push(NullValue.TypeVariables);
  }

  void handleNoType(Token token) {
    debugEvent("NoType");
    push(NullValue.Type);
  }

  void handleNoFormalParameters(Token token) {
    debugEvent("NoFormalParameters");
    push(NullValue.FormalParameters);
  }

  void handleNoArguments(Token token) {
    debugEvent("NoArguments");
    push(NullValue.Arguments);
  }

  void handleNoFunctionBody(Token token) {
    debugEvent("NoFunctionBody");
    push(NullValue.FunctionBody);
  }

  void handleNoInitializers() {
    debugEvent("NoInitializers");
    push(NullValue.Initializers);
  }

  void handleParenthesizedExpression(BeginGroupToken token) {
    debugEvent("ParenthesizedExpression");
  }

  void beginLiteralString(Token token) {
    debugEvent("beginLiteralString");
    push(token);
  }

  void endLiteralString(int interpolationCount) {
    debugEvent("endLiteralString");
    if (interpolationCount == 0) {
      Token token = pop();
      push(unescapeString(token.value));
    } else {
      internalError("String interpolation not implemented.");
    }
  }

  void handleStringJuxtaposition(int literalCount) {
    debugEvent("StringJuxtaposition");
    push(popList(literalCount).join(""));
  }

  void endCatchClause(Token token) {
    debugEvent("CatchClause");
  }

  void error(String message, Token token) {
    inputError(uri, token.charOffset, message);
  }
}
