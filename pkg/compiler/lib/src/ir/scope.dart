// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'closure.dart';
import 'scope_visitor.dart';

class ScopeModel {
  final ClosureScopeModel closureScopeModel;
  final VariableScopeModel variableScopeModel;
  final InitializerComplexity initializerComplexity;

  ScopeModel(this.closureScopeModel, this.variableScopeModel,
      this.initializerComplexity);

  /// Inspect members and mark if those members capture any state that needs to
  /// be marked as free variables.
  static ScopeModel computeScopeModel(ir.Member node) {
    if (node.isAbstract && !node.isExternal) return null;
    if (node is ir.Field && !node.isInstanceMember) {
      ir.Field field = node;
      // Skip top-level/static fields without an initializer.
      if (field.initializer == null) return null;
    }

    bool hasThisLocal = false;
    if (node is ir.Constructor) {
      hasThisLocal = true;
    } else if (node is ir.Procedure && node.kind == ir.ProcedureKind.Factory) {
      hasThisLocal = false;
    } else if (node.isInstanceMember) {
      hasThisLocal = true;
    }
    ClosureScopeModel closureScopeModel = new ClosureScopeModel();
    ScopeModelBuilder builder =
        new ScopeModelBuilder(closureScopeModel, hasThisLocal: hasThisLocal);
    InitializerComplexity initializerComplexity =
        const InitializerComplexity.lazy();
    if (node is ir.Field) {
      if (node is ir.Field && node.initializer != null) {
        initializerComplexity = node.accept(builder);
      } else {
        assert(node.isInstanceMember);
        closureScopeModel.scopeInfo = new KernelScopeInfo(true);
      }
    } else {
      assert(node is ir.Procedure || node is ir.Constructor);
      node.accept(builder);
    }
    return new ScopeModel(
        closureScopeModel, builder.variableScopeModel, initializerComplexity);
  }
}

abstract class VariableScopeModel {
  VariableScope getScopeFor(ir.TreeNode node);
  Iterable<ir.VariableDeclaration> get assignedVariables;
  bool isEffectivelyFinal(ir.VariableDeclaration node);
}

class VariableScopeModelImpl implements VariableScopeModel {
  Map<ir.TreeNode, VariableScope> _scopeMap = {};
  Set<ir.VariableDeclaration> _assignedVariables;

  VariableScope createScopeFor(ir.TreeNode node) {
    return _scopeMap[node] ??= new VariableScopeImpl();
  }

  void registerAssignedVariable(ir.VariableDeclaration node) {
    _assignedVariables ??= new Set<ir.VariableDeclaration>();
    _assignedVariables.add(node);
  }

  @override
  VariableScope getScopeFor(ir.TreeNode node) {
    return _scopeMap[node];
  }

  @override
  Iterable<ir.VariableDeclaration> get assignedVariables =>
      _assignedVariables ?? <ir.VariableDeclaration>[];

  @override
  bool isEffectivelyFinal(ir.VariableDeclaration node) {
    return _assignedVariables == null || !_assignedVariables.contains(node);
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
  List<VariableScope> _subScopes;
  Set<ir.VariableDeclaration> _assignedVariables;
  bool hasContinueSwitch = false;

  void addSubScope(VariableScope scope) {
    _subScopes ??= <VariableScope>[];
    _subScopes.add(scope);
  }

  void registerAssignedVariable(ir.VariableDeclaration variable) {
    _assignedVariables ??= new Set<ir.VariableDeclaration>();
    _assignedVariables.add(variable);
  }

  Iterable<ir.VariableDeclaration> get assignedVariables sync* {
    if (_assignedVariables != null) {
      yield* _assignedVariables;
    }
    if (_subScopes != null) {
      for (VariableScope subScope in _subScopes) {
        yield* subScope.assignedVariables;
      }
    }
  }
}

abstract class VariableCollectorMixin {
  VariableScopeImpl currentVariableScope;
  VariableScopeModelImpl variableScopeModel = new VariableScopeModelImpl();

  void visitInVariableScope(ir.TreeNode root, void f()) {
    VariableScopeImpl oldScope = currentVariableScope;
    currentVariableScope = variableScopeModel.createScopeFor(root);
    oldScope?.addSubScope(currentVariableScope);
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
