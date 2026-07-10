// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../util/local_stack.dart';

extension type ScopeProviderInfoStack<Info extends ScopeProviderInfo>(
  List<Info> _list,
) implements LocalStack<Info> {
  ScopeProviderInfo? topmostOfKind(
    Set<ScopeProviderInfoKind> scopeProviderInfoKinds,
  ) {
    for (int index = _list.length - 1; index >= 0; index--) {
      Info info = _list[index];
      if (scopeProviderInfoKinds.contains(info.kind)) {
        return info;
      }
    }
    return null;
  }
}

enum ScopeProviderInfoKind {
  Block,
  BlockExpression,
  Catch,
  FunctionNode,
  FunctionNodeWithThis,
  InstanceField,
  Loop,
  StaticField,
}

class ScopeProviderInfo({required this.kind}) {
  final ScopeProviderInfoKind kind;
  Scope? scope;
  ThisVariable? thisVariable;
}

abstract class ContextAllocationStrategy<Info extends ScopeProviderInfo> {
  final ScopeProviderInfoStack<Info> _scopeProviderInfoStack =
      new ScopeProviderInfoStack<Info>(<Info>[]);

  bool _enableDebugLogging = true;
  StringBuffer? _debugLog;

  Info? get _currentScopeProviderInfo => _scopeProviderInfoStack.currentOrNull;

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
  Info enterScopeProvider({
    required ScopeProviderInfoKind scopeProviderInfoKind,
  }) {
    Info scopeProviderInfo = createScopeProviderInfo(
      scopeProviderInfoKind: scopeProviderInfoKind,
    );
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

  Scope _ensureScopeWithThis() {
    ScopeProviderInfo? scopeProviderInfo = _scopeProviderInfoStack
        .topmostOfKind(const {
          ScopeProviderInfoKind.FunctionNodeWithThis,
          ScopeProviderInfoKind.InstanceField,
        });
    assert(scopeProviderInfo != null);
    return scopeProviderInfo!.scope ??= // Coverage-ignore(suite): Not run.
    new Scope(
      contexts: [],
    );
  }

  VariableContext _ensureVariableContextInCurrentScope({
    required CaptureKind captureKind,
  }) {
    Scope scope = _ensureCurrentScope();
    VariableContext? context = _fetchVariableContextOfScope(
      scope: scope,
      captureKind: captureKind,
    );
    if (context != null) {
      return context;
    } else {
      context = new VariableContext(captureKind: captureKind, variables: []);
      scope.addContext(context);
      return context;
    }
  }

  VariableContext? _fetchVariableContextOfScope({
    required Scope scope,
    required CaptureKind captureKind,
  }) {
    for (VariableContext context in scope.contexts) {
      if (context.captureKind == captureKind) {
        return context;
      }
    }
    return null;
  }

  void handleDeclarationOfVariable(
    Variable variable, {
    required CaptureKind captureKind,
  });

  List<VariableContext> computeCapturedVariableContexts(
    List<VariableBase> variables,
  ) {
    if (variables.isEmpty) {
      return [];
    }
    return {for (VariableBase variable in variables) variable.context}.toList();
  }

  ThisVariable get thisVariable {
    ThisVariable? result;
    for (VariableContext context in _ensureScopeWithThis().contexts) {
      if (context.variables.whereType<ThisVariable>().firstOrNull
          case var variable?) {
        result = variable;
        break;
      }
    }
    return result!;
  }

  Info createScopeProviderInfo({
    required ScopeProviderInfoKind scopeProviderInfoKind,
  });

  /// Initiates closure context allocation as a part of type inference.
  ///
  /// [parameters] are those of the function being inferred.
  ScopeProviderInfo beginClosureContextAllocation(
    List<VariableWithCaptureKind<Variable>> parameters, {
    required VariableWithCaptureKind<ThisVariable>? thisVariable,
  }) {
    ScopeProviderInfo scopeProviderInfo = enterScopeProvider(
      scopeProviderInfoKind: thisVariable == null
          ? ScopeProviderInfoKind.FunctionNode
          : ScopeProviderInfoKind.FunctionNodeWithThis,
    );
    if (thisVariable != null) {
      scopeProviderInfo.thisVariable = thisVariable.variable;
      handleDeclarationOfVariable(
        thisVariable.variable,
        captureKind: thisVariable.captureKind,
      );
    }
    handleDeclarationsOfParameters(parameters);
    return scopeProviderInfo;
  }

  /// Finishes closure context allocation after inferring the function body.
  void endClosureContextAllocation(ScopeProviderInfo scopeProviderInfo) {
    exitScopeProvider(scopeProviderInfo);
  }

  void handleDeclarationsOfParameters(
    List<VariableWithCaptureKind<Variable>> parameters,
  ) {
    for (VariableWithCaptureKind<Variable> parameter in parameters) {
      handleDeclarationOfVariable(
        parameter.variable,
        captureKind: parameter.captureKind,
      );
    }
  }
}

class TrivialContextAllocationStrategy
    extends ContextAllocationStrategy<ScopeProviderInfo> {
  @override
  void handleDeclarationOfVariable(
    Variable variable, {
    required CaptureKind captureKind,
  }) {
    assert(_currentScopeProviderInfo != null);
    _ensureVariableContextInCurrentScope(captureKind: captureKind)
        .addVariable(variable);
  }

  @override
  ScopeProviderInfo createScopeProviderInfo({
    required ScopeProviderInfoKind scopeProviderInfoKind,
  }) => new ScopeProviderInfo(kind: scopeProviderInfoKind);
}

// Coverage-ignore(suite): Not run.
class CollectorScopeProviderInfo extends ScopeProviderInfo {
  /// Link to [CollectorScopeProviderInfo] that the current info object
  /// delegates collecting captured variables to.
  ///
  /// [capturedVariableCollector] points to the object itself if it itself
  /// collects its own (and its children's) captured variables. It is `null` in
  /// case the current scope doesn't contain captured variables yet.
  CollectorScopeProviderInfo? capturedVariableCollector;

  new({required super.kind});
}

// Coverage-ignore(suite): Not run.
class LoopDepthAllocationStrategy
    extends ContextAllocationStrategy<CollectorScopeProviderInfo> {
  @override
  CollectorScopeProviderInfo createScopeProviderInfo({
    required ScopeProviderInfoKind scopeProviderInfoKind,
  }) => new CollectorScopeProviderInfo(kind: scopeProviderInfoKind);

  /// Predicate describing the stopping conditions for delegation to collector.
  ///
  /// Loops and functions serves as boundaries to propagating the delegation to
  /// collector.
  static bool _isStoppingDelegationToCollector(
    ScopeProviderInfoKind scopeProviderInfoKind,
  ) {
    switch (scopeProviderInfoKind) {
      case ScopeProviderInfoKind.Block:
      case ScopeProviderInfoKind.BlockExpression:
      case ScopeProviderInfoKind.Catch:
        return false;
      case ScopeProviderInfoKind.Loop:
      case ScopeProviderInfoKind.FunctionNode:
      case ScopeProviderInfoKind.FunctionNodeWithThis:
      case ScopeProviderInfoKind.InstanceField:
      case ScopeProviderInfoKind.StaticField:
        return true;
    }
  }

  @override
  CollectorScopeProviderInfo enterScopeProvider({
    required ScopeProviderInfoKind scopeProviderInfoKind,
  }) {
    CollectorScopeProviderInfo? previousScopeProvider =
        _currentScopeProviderInfo;
    CollectorScopeProviderInfo currentScopeProvider = super.enterScopeProvider(
      scopeProviderInfoKind: scopeProviderInfoKind,
    );
    // If the delegation to collection shouldn't be stopped, inherit the
    // collector from the previous [CollectorScopeProviderInfo] object. In case
    // it was `null` (that is, it didn't hold any captured variables), the
    // current scope starts with `null` as well.
    if (!_isStoppingDelegationToCollector(scopeProviderInfoKind)) {
      currentScopeProvider.capturedVariableCollector =
          previousScopeProvider?.capturedVariableCollector;
    }
    return currentScopeProvider;
  }

  @override
  void handleDeclarationOfVariable(
    Variable variable, {
    required CaptureKind captureKind,
  }) {
    CollectorScopeProviderInfo currentScope = _currentScopeProviderInfo!;
    if (variable is ThisVariable) {
      currentScope.thisVariable = variable;
    }

    // Delegation happens when the current variable is not uncaptured (that is,
    // it's either captured or assert-captured), and there's a collector to
    // delegate to.
    bool delegateToCollector =
        captureKind != CaptureKind.notCaptured &&
        currentScope.capturedVariableCollector != null;
    if (delegateToCollector) {
      _fetchVariableContextOfScope(
        scope: currentScope.capturedVariableCollector!.scope!,
        captureKind: captureKind,
      )!.addVariable(variable);
    } else {
      _ensureVariableContextInCurrentScope(captureKind: captureKind)
          .addVariable(variable);

      // In case it was the first not uncaptured variable (that is, either
      // captured or assert-captured) for the current scope, and it didn't have
      // a collector to delegate to due to the enclosing if-condition, it
      // becomes a collector of captured variables itself.
      bool becomesCollector =
          captureKind != CaptureKind.notCaptured &&
          currentScope.capturedVariableCollector == null;
      if (becomesCollector) {
        currentScope.capturedVariableCollector = currentScope;
      }
    }
  }
}

/// A variable paired together with its [CaptureKind].
class VariableWithCaptureKind<Variable extends VariableBase>(
  var Variable variable,
  var CaptureKind captureKind,
);
