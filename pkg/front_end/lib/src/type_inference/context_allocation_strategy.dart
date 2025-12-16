// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import '../util/local_stack.dart';

abstract class ContextAllocationStrategy {
  // TODO(cstefantsova): Replace this flag by implementing the default strategy.
  bool isClosureContextLoweringEnabled;

  final LocalStack<TreeNode> _scopeProviderOrSubstituteStack =
      new LocalStack<TreeNode>(<TreeNode>[]);

  final Map<TreeNode, Scope> _scopeBySubstitute = {};

  bool _enableDebugLogging = true;
  StringBuffer? _debugLog;

  ContextAllocationStrategy({required this.isClosureContextLoweringEnabled});

  TreeNode? get _currentScopeProviderOrSubstitute =>
      _scopeProviderOrSubstituteStack.currentOrNull;

  void _writeDebugLine(String line) {
    if (_enableDebugLogging) {
      (_debugLog ??= new StringBuffer()).writeln(line);
    }
  }

  // Coverage-ignore(suite): Not run.
  String _readDebugLog() {
    return _debugLog?.toString() ?? "";
  }

  void enterScopeProvider(ScopeProvider scopeProvider) {
    if (isClosureContextLoweringEnabled) {
      assert(() {
        _writeDebugLine(
          "Entered ${scopeProvider.runtimeType} "
          "(id=${identityHashCode(scopeProvider)}).",
        );
        return true;
      }());
      _scopeProviderOrSubstituteStack.push(scopeProvider);
    }
  }

  void exitScopeProvider(ScopeProvider scopeProvider) {
    if (isClosureContextLoweringEnabled) {
      assert(() {
        _writeDebugLine(
          "Exited ${scopeProvider.runtimeType} "
          "(id=${identityHashCode(scopeProvider)}).",
        );
        return true;
      }());
      assert(
        identical(_currentScopeProviderOrSubstitute, scopeProvider),
        "Expected the current scope provider "
        "to be identical to the exited one: "
        "current=${_currentScopeProviderOrSubstitute.runtimeType}, "
        "exited=${scopeProvider.runtimeType}."
        "\nDebug log:\n${_readDebugLog()}",
      );
      _scopeProviderOrSubstituteStack.pop();
    }
  }

  void enterScopeProviderSubstitute(TreeNode substitute) {
    if (isClosureContextLoweringEnabled) {
      assert(() {
        _writeDebugLine(
          "Entered ${substitute.runtimeType} "
          "(id=${identityHashCode(substitute)}).",
        );
        return true;
      }());
      _scopeProviderOrSubstituteStack.push(substitute);
    }
  }

  void exitScopeProviderSubstitute(TreeNode substitute) {
    if (isClosureContextLoweringEnabled) {
      assert(() {
        _writeDebugLine(
          "Exited ${substitute.runtimeType} "
          "(id=${identityHashCode(substitute)}).",
        );
        return true;
      }());
      assert(
        identical(_currentScopeProviderOrSubstitute, substitute),
        "Expected the current scope provider substitute "
        "to be identical to the exited one: "
        "current=${_currentScopeProviderOrSubstitute.runtimeType}, "
        "exited=${substitute.runtimeType}."
        "\nDebug log:\n${_readDebugLog()}",
      );
      _scopeProviderOrSubstituteStack.pop();
    }
  }

  Scope _ensureCurrentScope() {
    assert(_currentScopeProviderOrSubstitute != null);
    if (_currentScopeProviderOrSubstitute case ScopeProvider scopeProvider) {
      return scopeProvider.scope ??= new Scope(contexts: []);
    } else {
      return _scopeBySubstitute[_currentScopeProviderOrSubstitute!] ??=
          new Scope(contexts: []);
    }
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

  void transferScope(TreeNode from, ScopeProvider to) {
    to.scope = _scopeBySubstitute[from];
    _scopeBySubstitute.remove(from);
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
  TrivialContextAllocationStrategy({
    required super.isClosureContextLoweringEnabled,
  });

  @override
  void handleDeclarationOfVariable(
    ExpressionVariable variable, {
    required CaptureKind captureKind,
  }) {
    if (isClosureContextLoweringEnabled) {
      assert(_currentScopeProviderOrSubstitute != null);
      _ensureVariableContextInCurrentScope(
        captureKind: captureKind,
      ).addVariable(variable);
    }
  }

  @override
  void handleVariablesCapturedByNode(
    FunctionNode node,
    List<Variable> variables,
  ) {
    if (isClosureContextLoweringEnabled) {
      Set<VariableContext> contexts = {
        for (Variable variable in variables) variable.context,
      };
      (node.contexts ??= []).addAll(contexts);
    }
  }
}
