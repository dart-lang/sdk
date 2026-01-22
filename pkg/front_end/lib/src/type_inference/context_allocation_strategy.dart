// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import '../util/local_stack.dart';

enum ScopeProviderInfoKind {
  Block,
  BlockExpression,
  Catch,
  ForInStatement,
  ForStatement,
  FunctionNode,
}

class ScopeProviderInfo {
  final ScopeProviderInfoKind kind;

  Scope? scope;

  ScopeProviderInfo({required this.kind});
}

abstract class ContextAllocationStrategy {
  final LocalStack<ScopeProviderInfo> _scopeProviderInfoStack =
      new LocalStack<ScopeProviderInfo>(<ScopeProviderInfo>[]);

  bool _enableDebugLogging = true;
  StringBuffer? _debugLog;

  ScopeProviderInfo? get _currentScopeProviderInfo =>
      _scopeProviderInfoStack.currentOrNull;

  void _writeDebugLine(String line) {
    if (_enableDebugLogging) {
      (_debugLog ??= new StringBuffer()).writeln(line);
    }
  }

  // Coverage-ignore(suite): Not run.
  String _readDebugLog() {
    return _debugLog?.toString() ?? "";
  }

  /// Creates and returns a tracking object for the entered [ScopeProvider].
  ScopeProviderInfo enterScopeProvider({required ScopeProviderInfoKind kind}) {
    ScopeProviderInfo scopeProviderInfo = new ScopeProviderInfo(kind: kind);
    _scopeProviderInfoStack.push(scopeProviderInfo);

    assert(() {
      _writeDebugLine(
        "Entered ${scopeProviderInfo.kind} "
        "(id=${identityHashCode(scopeProviderInfo)}).",
      );
      return true;
    }());

    return scopeProviderInfo;
  }

  /// Ensures that the tracking object [scopeProviderInfo] for the exited
  /// [ScopeProvider] matches the one previously entered.
  void exitScopeProvider(ScopeProviderInfo scopeProviderInfo) {
    assert(() {
      _writeDebugLine(
        "Exited ${scopeProviderInfo.kind} "
        "(id=${identityHashCode(scopeProviderInfo)}).",
      );
      return true;
    }());
    assert(
      identical(_currentScopeProviderInfo, scopeProviderInfo),
      "Expected the current scope provider "
      "to be identical to the exited one: "
      "current=${_currentScopeProviderInfo?.kind}, "
      "exited=${scopeProviderInfo.kind}."
      "\nDebug log:\n${_readDebugLog()}",
    );
    _scopeProviderInfoStack.pop();
  }

  Scope _ensureCurrentScope() {
    assert(_currentScopeProviderInfo != null);
    return _currentScopeProviderInfo!.scope ??= new Scope(contexts: []);
  }

  VariableContext _ensureVariableContextInCurrentScope({
    required CaptureKind captureKind,
  }) {
    Scope scope = _ensureCurrentScope();
    for (VariableContext context in scope.contexts) {
      // Coverage-ignore-block(suite): Not run.
      if (context.captureKind == captureKind) {
        return context;
      }
    }
    VariableContext context = new VariableContext(
      captureKind: captureKind,
      variables: [],
    );
    scope.addContext(context);
    return context;
  }

  void handleDeclarationOfVariable(
    ExpressionVariable variable, {
    required CaptureKind captureKind,
  });

  void handleVariablesCapturedByNode(
    FunctionNode node,
    List<Variable> variables,
  );
}

class TrivialContextAllocationStrategy extends ContextAllocationStrategy {
  TrivialContextAllocationStrategy();

  @override
  void handleDeclarationOfVariable(
    ExpressionVariable variable, {
    required CaptureKind captureKind,
  }) {
    assert(_currentScopeProviderInfo != null);
    _ensureVariableContextInCurrentScope(
      captureKind: captureKind,
    ).addVariable(variable);
  }

  @override
  void handleVariablesCapturedByNode(
    FunctionNode node,
    List<Variable> variables,
  ) {
    Set<VariableContext> contexts = {
      for (Variable variable in variables) variable.context,
    };
    (node.contexts ??= []).addAll(contexts);
  }
}
