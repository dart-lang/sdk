// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;
import 'closure.dart';
import 'scope_visitor.dart';

class ScopeModel {
  final ClosureScopeModel? closureScopeModel;
  final VariableScopeModel? variableScopeModel;
  final EvaluationComplexity initializerComplexity;

  const ScopeModel({
    this.closureScopeModel,
    this.variableScopeModel,
    required this.initializerComplexity,
  });

  /// Inspect members and mark if those members capture any state that needs to
  /// be marked as free variables.
  factory ScopeModel.from(ir.Member node, ir.TypeEnvironment typeEnvironment) {
    ScopeModelBuilder builder = ScopeModelBuilder(typeEnvironment);
    return builder.computeModel(node);
  }
}

abstract class VariableScopeModel {
  VariableScope getScopeFor(ir.TreeNode node);
  Iterable<ir.Variable> get assignedVariables;
}

class VariableScopeModelImpl implements VariableScopeModel {
  final Map<ir.TreeNode, VariableScopeImpl> _scopeMap = {};
  Set<ir.Variable>? _assignedVariables;

  VariableScopeImpl createScopeFor(ir.TreeNode node) {
    return _scopeMap[node] ??= VariableScopeImpl();
  }

  void registerAssignedVariable(ir.Variable node) {
    (_assignedVariables ??= {}).add(node);
  }

  @override
  VariableScope getScopeFor(ir.TreeNode node) {
    return _scopeMap[node]!;
  }

  @override
  Iterable<ir.Variable> get assignedVariables =>
      _assignedVariables ?? <ir.Variable>[];
}

/// Variable information for a scope.
abstract class VariableScope {
  /// Returns the set of [ir.Variable]s that have been assigned to in
  /// this scope.
  Iterable<ir.Variable> get assignedVariables;

  /// Returns `true` if this scope has a [ir.ContinueSwitchStatement].
  bool get hasContinueSwitch;
}

class VariableScopeImpl implements VariableScope {
  List<VariableScope>? _subScopes;
  Set<ir.Variable>? _assignedVariables;
  @override
  bool hasContinueSwitch = false;

  void addSubScope(VariableScope scope) {
    _subScopes ??= <VariableScope>[];
    _subScopes!.add(scope);
  }

  void registerAssignedVariable(ir.Variable variable) {
    _assignedVariables ??= <ir.Variable>{};
    _assignedVariables!.add(variable);
  }

  @override
  Iterable<ir.Variable> get assignedVariables sync* {
    if (_assignedVariables != null) {
      yield* _assignedVariables!;
    }
    if (_subScopes != null) {
      for (VariableScope subScope in _subScopes!) {
        yield* subScope.assignedVariables;
      }
    }
  }
}

mixin VariableCollectorMixin {
  VariableScopeImpl? currentVariableScope;
  VariableScopeModelImpl variableScopeModel = VariableScopeModelImpl();

  void visitInVariableScope(ir.TreeNode root, void Function() f) {
    VariableScopeImpl? oldScope = currentVariableScope;
    final newScope = currentVariableScope = variableScopeModel.createScopeFor(
      root,
    );
    oldScope?.addSubScope(newScope);
    f();
    currentVariableScope = oldScope;
  }

  void registerAssignedVariable(ir.Variable node) {
    currentVariableScope?.registerAssignedVariable(node);
    variableScopeModel.registerAssignedVariable(node);
  }

  void registerContinueSwitch() {
    currentVariableScope?.hasContinueSwitch = true;
  }
}
