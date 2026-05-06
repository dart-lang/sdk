// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ast;

typedef Variable = ast.VariableDeclaration;

/// A unit of capturing. Contains variables and belongs to a certain [Scope].
abstract class Context {
  /// Whether this context is captured.
  bool isCaptured({required bool enableAsserts});

  /// Variables which belong to this context.
  List<Variable> get variables;
}

/// Scope introduced by a certain AST node.
abstract class Scope {
  /// Contexts which belong to this scope.
  List<Context> get contexts;
}

/// Interface to the computed scopes.
abstract class Scopes {
  /// Scope introduced by [node].
  Scope? getScope(ast.TreeNode node);

  /// Context of the given [variable].
  Context getVariableContext(Variable variable);

  /// List of contexts captured by [function].
  List<Context> getCapturedContexts(
    ast.FunctionNode function, {
    required bool enableAsserts,
  });

  /// Variable representing `this`.
  Variable? getThisVariable(ast.Member member);
}
