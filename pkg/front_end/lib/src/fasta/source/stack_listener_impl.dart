// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.stack_listener_impl;

import 'package:_fe_analyzer_shared/src/messages/codes.dart' show Message;

import 'package:_fe_analyzer_shared/src/parser/parser.dart' show Parser;

import 'package:_fe_analyzer_shared/src/parser/stack_listener.dart';

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;

import 'package:kernel/ast.dart'
    show AsyncMarker, Expression, FunctionNode, TreeNode;

import '../problems.dart' as problems
    show internalProblem, unhandled, unsupported;

abstract class StackListenerImpl extends StackListener {
  // TODO(ahe): This doesn't belong here. Only implemented by body_builder.dart
  // and ast_builder.dart.
  void finishFunction(
      covariant formals, AsyncMarker asyncModifier, covariant body) {
    return problems.unsupported("finishFunction", -1, uri);
  }

  // TODO(ahe): This doesn't belong here. Only implemented by body_builder.dart
  // and ast_builder.dart.
  dynamic finishFields() {
    return problems.unsupported("finishFields", -1, uri);
  }

  // TODO(ahe): This doesn't belong here. Only implemented by body_builder.dart
  // and ast_builder.dart.
  List<Expression> finishMetadata(TreeNode parent) {
    return problems.unsupported("finishMetadata", -1, uri);
  }

  // TODO(ahe): This doesn't belong here. Only implemented by body_builder.dart
  // and ast_builder.dart.
  void exitLocalScope() => problems.unsupported("exitLocalScope", -1, uri);

  // TODO(ahe): This doesn't belong here. Only implemented by body_builder.dart.
  dynamic parseSingleExpression(
      Parser parser, Token token, FunctionNode parameters) {
    return problems.unsupported("finishSingleExpression", -1, uri);
  }

  /// Used to report an internal error encountered in the stack listener.
  dynamic internalProblem(Message message, int charOffset, Uri uri) {
    return problems.internalProblem(message, charOffset, uri);
  }

  /// Used to report an unexpected situation encountered in the stack
  /// listener.
  dynamic unhandled(String what, String where, int charOffset, Uri uri) {
    return problems.unhandled(what, where, charOffset, uri);
  }
}

/// A null-aware alternative to `token.offset`.  If [token] is `null`, returns
/// `TreeNode.noOffset`.
int offsetForToken(Token token) {
  return token == null ? TreeNode.noOffset : token.offset;
}
