// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import '../util/local_stack.dart';

abstract class ContextAllocationStrategy {
  // TODO(cstefantsova): Replace this flag by implementing the default strategy.
  bool isClosureContextLoweringEnabled;

  ContextAllocationStrategy({required this.isClosureContextLoweringEnabled});

  LocalStack<ScopeProvider> _scopeProviderStack = new LocalStack<ScopeProvider>(
    <ScopeProvider>[],
  );
  ScopeProvider? get _currentScopeProvider => _scopeProviderStack.currentOrNull;

  bool _enableDebugLogging = false;
  StringBuffer? _debugLog;

  void _writeDebugLine(String line) {
    if (_enableDebugLogging) {
      // Coverage-ignore-block(suite): Not run.
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
      _scopeProviderStack.push(scopeProvider);
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
        identical(_currentScopeProvider, scopeProvider),
        "Expected the current scope provider "
        "to be identical to the exited one: "
        "current=${_currentScopeProvider.runtimeType}, "
        "exited=${scopeProvider.runtimeType}."
        "\nDebug log:\n${_readDebugLog()}",
      );
      _scopeProviderStack.pop();
    }
  }

  VariableContext _ensureVariableContextInCurrentScope({
    required CaptureKind captureKind,
  }) {
    assert(_currentScopeProvider != null);
    Scope scope = _currentScopeProvider!.scope ??= new Scope(contexts: []);
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
      assert(_currentScopeProvider != null);
      _ensureVariableContextInCurrentScope(
        captureKind: captureKind,
      ).addVariable(variable);
    }
  }
}
