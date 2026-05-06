// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/front_end/scopes.dart';
import 'package:kernel/ast.dart' as ast;

/// Mapping between AST nodes and corresponding wrappers.
class _Mapping {
  final Map<ast.Scope, AstScope> _scopes = {};
  final Map<ast.VariableContext, AstContext> _contexts = {};

  AstScope mapScope(ast.Scope node) => _scopes[node] ??= AstScope(this, node);
  AstContext mapContext(ast.VariableContext node) =>
      _contexts[node] ??= AstContext(node);
}

/// Wrapper for [ast.VariableContext].
final class AstContext implements Context {
  final ast.VariableContext _node;

  AstContext(this._node);

  @override
  bool isCaptured({required bool enableAsserts}) =>
      _node.isCaptured(enableAsserts: enableAsserts);

  @override
  late final List<Variable> variables = [...variables.cast<Variable>()];
}

/// Wrapper for [ast.Scope].
final class AstScope implements Scope {
  final _Mapping _mapping;
  final ast.Scope _node;

  AstScope(this._mapping, this._node);

  @override
  late final List<Context> contexts = [
    for (final node in _node.contexts) _mapping.mapContext(node),
  ];
}

/// Implementation of [Scopes] using context information from AST.
final class AstScopes implements Scopes {
  final _Mapping _mapping = _Mapping();

  AstScopes();

  @override
  Scope? getScope(ast.TreeNode node) => switch (node) {
    ast.ScopeProvider(:var scope?) => _mapping.mapScope(scope),
    _ => null,
  };

  @override
  Context getVariableContext(Variable variable) =>
      _mapping.mapContext(variable.context);

  @override
  List<Context> getCapturedContexts(
    ast.FunctionNode function, {
    required bool enableAsserts,
  }) {
    final capturedContexts = function.capturedContexts;
    if (capturedContexts == null) {
      return [];
    }
    return [
      for (final node in capturedContexts)
        if (node.isCaptured(enableAsserts: enableAsserts))
          _mapping.mapContext(node),
    ];
  }

  @override
  Variable? getThisVariable(ast.Member member) => member.function?.thisVariable;
}

extension on ast.VariableContext {
  bool isCaptured({required bool enableAsserts}) => switch (captureKind) {
    .directCaptured => true,
    .assertCaptured => enableAsserts,
    .notCaptured => false,
  };
}
