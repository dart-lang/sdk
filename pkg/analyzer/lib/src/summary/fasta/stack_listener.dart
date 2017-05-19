// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fe.stack_listener;

import 'dart:collection' show Queue;

import 'package:front_end/src/fasta/parser.dart'
    show IdentifierContext, Listener, MemberKind;

import 'package:front_end/src/fasta/scanner.dart' show BeginGroupToken, Token;

enum NullValue {
  Arguments,
  Combinators,
  FormalParameters,
  FunctionBody,
  IdentifierList,
  Initializers,
  Metadata,
  Modifiers,
  Type,
  TypeArguments,
  TypeList,
  TypeVariable,
  TypeVariables,
}

abstract class StackListener extends Listener {
  final Queue<Object> stack = new Queue<Object>();

  Uri get uri;

  void checkEmpty() {
    if (stack.isNotEmpty) {
      throw "Stack not empty $uri:\n"
          "  ${stack.join('\n  ')}";
    }
  }

  void debugEvent(String name) {
    // print("  ${stack.join('\n  ')}");
    // print(name);
  }

  void endCompilationUnit(int count, Token token) {
    debugEvent("CompilationUnit");
    checkEmpty();
  }

  void endTopLevelDeclaration(Token token) {
    debugEvent("TopLevelDeclaration");
    checkEmpty();
  }

  void handleIdentifier(Token token, IdentifierContext context) {
    debugEvent("handleIdentifier");
    push(token.lexeme);
  }

  void handleNoArguments(Token token) {
    debugEvent("NoArguments");
    var typeArguments = pop();
    assert(typeArguments == null);
    push(NullValue.Arguments);
  }

  void handleNoFormalParameters(Token token, MemberKind kind) {
    debugEvent("NoFormalParameters");
    push(NullValue.FormalParameters);
  }

  void handleNoFunctionBody(Token token) {
    debugEvent("NoFunctionBody");
    push(NullValue.FunctionBody);
  }

  void handleNoInitializers() {
    debugEvent("NoInitializers");
    push(NullValue.Initializers);
  }

  void handleNoType(Token token) {
    debugEvent("NoType");
    push(NullValue.Type);
  }

  void handleNoTypeArguments(Token token) {
    debugEvent("NoTypeArguments");
    push(NullValue.TypeArguments);
  }

  void handleNoTypeVariables(Token token) {
    debugEvent("NoTypeVariables");
    push(NullValue.TypeVariables);
  }

  void handleParenthesizedExpression(BeginGroupToken token) {
    debugEvent("ParenthesizedExpression");
  }

  void logEvent(String name) {
    print("  ${stack.join('\n  ')}");
    throw "Unhandled event: $name in $runtimeType $uri.";
  }

  Object peek() {
    Object node = stack.last;
    return node is NullValue ? null : node;
  }

  Object pop({NullValue expect: null}) {
    Object node = stack.removeLast();
    if (expect != null && expect != node) {
      throw "unexpected value: $expect vs $node";
    }
    return node is NullValue ? null : node;
  }

  Object popIfNotNull(Object value) {
    return value == null ? null : pop();
  }

  List popList(int n) {
    if (n == 0) return null;
    List list = new List(n);
    for (int i = n - 1; i >= 0; i--) {
      list[i] = pop();
    }
    return list;
  }

  void push(Object node) {
    if (node == null) throw "null not allowed.";
    stack.addLast(node);
  }
}
