// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'closure.dart';
import 'constants.dart' show Dart2jsConstantEvaluator;
import 'scope_visitor.dart';
import 'package:front_end/src/api_prototype/constant_evaluator.dart' as ir;

class ScopeModel {
  final ClosureScopeModel? closureScopeModel;
  final VariableScopeModel? variableScopeModel;
  final EvaluationComplexity initializerComplexity;

  const ScopeModel(
      {this.closureScopeModel,
      this.variableScopeModel,
      required this.initializerComplexity});

  /// Inspect members and mark if those members capture any state that needs to
  /// be marked as free variables.
  factory ScopeModel.from(
      ir.Member node, ir.ConstantEvaluator constantEvaluator) {
    ScopeModelBuilder builder =
        ScopeModelBuilder(constantEvaluator as Dart2jsConstantEvaluator);
    return builder.computeModel(node);
  }
}

abstract class VariableScopeModel {
  VariableScope getScopeFor(ir.TreeNode node);
  Iterable<ir.VariableDeclaration> get assignedVariables;
  bool isEffectivelyFinal(ir.VariableDeclaration node);
}

class VariableScopeModelImpl implements VariableScopeModel {
  final Map<ir.TreeNode, VariableScopeImpl> _scopeMap = {};
  Set<ir.VariableDeclaration>? _assignedVariables;

  VariableScopeImpl createScopeFor(ir.TreeNode node) {
    return _scopeMap[node] ??= VariableScopeImpl();
  }

  void registerAssignedVariable(ir.VariableDeclaration node) {
    (_assignedVariables ??= {}).add(node);
  }

  @override
  VariableScope getScopeFor(ir.TreeNode node) {
    return _scopeMap[node]!;
  }

  @override
  Iterable<ir.VariableDeclaration> get assignedVariables =>
      _assignedVariables ?? <ir.VariableDeclaration>[];

  @override
  bool isEffectivelyFinal(ir.VariableDeclaration node) {
    return _assignedVariables == null || !_assignedVariables!.contains(node);
  }
}

/// Variable information for a scope.
abstract class VariableScope {
  /// Returns the set of [ir.VariableDeclaration]s that have been assigned to in
  /// this scope.
  Iterable<ir.VariableDeclaration> get assignedVariables;

  /// Returns `true` if this scope has a [ir.ContinueSwitchStatement].
  bool get hasContinueSwitch;
}

class VariableScopeImpl implements VariableScope {
  List<VariableScope>? _subScopes;
  Set<ir.VariableDeclaration>? _assignedVariables;
  @override
  bool hasContinueSwitch = false;

  void addSubScope(VariableScope scope) {
    _subScopes ??= <VariableScope>[];
    _subScopes!.add(scope);
  }

  void registerAssignedVariable(ir.VariableDeclaration variable) {
    _assignedVariables ??= Set<ir.VariableDeclaration>();
    _assignedVariables!.add(variable);
  }

  @override
  Iterable<ir.VariableDeclaration> get assignedVariables sync* {
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

  void visitInVariableScope(ir.TreeNode root, void f()) {
    VariableScopeImpl? oldScope = currentVariableScope;
    final newScope =
        currentVariableScope = variableScopeModel.createScopeFor(root);
    oldScope?.addSubScope(newScope);
    f();
    currentVariableScope = oldScope;
  }

  void registerAssignedVariable(ir.VariableDeclaration node) {
    currentVariableScope?.registerAssignedVariable(node);
    variableScopeModel.registerAssignedVariable(node);
  }

  void registerContinueSwitch() {
    currentVariableScope?.hasContinueSwitch = true;
  }
}
