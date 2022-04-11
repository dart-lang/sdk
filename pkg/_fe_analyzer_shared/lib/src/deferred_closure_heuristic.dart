// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/dependency_walker.dart';

/// Data structure tracking the type inference dependencies between closures
/// passed as invocation parameters.
///
/// [planClosureReconciliationStages] is used as part of support for
/// https://github.com/dart-lang/language/issues/731 (improved inference for
/// fold etc.) to choose the proper order in which to recursively analyze
/// closures passed as invocation arguments.
abstract class ClosureDependencies<TypeVariable, Closure> {
  final List<_ClosureNode<Closure>> _closureNodes = [];

  /// Construct a [ClosureDependencies] object that's prepared to determine the
  /// order to resolve [closures] for a generic invocation involving the given
  /// [typeVariables].
  ClosureDependencies(
      Iterable<Closure> closures, Iterable<TypeVariable> typeVariables) {
    Map<TypeVariable, Set<_ClosureNode<Closure>>> closuresDependingOnTypeVar =
        {};
    Map<TypeVariable, Set<_ClosureNode<Closure>>> closuresConstrainingTypeVar =
        {};
    for (Closure closure in closures) {
      _ClosureNode<Closure> closureNode = new _ClosureNode<Closure>(closure);
      _closureNodes.add(closureNode);
      for (TypeVariable v in typeVarsFreeInClosureArguments(closure)) {
        (closuresDependingOnTypeVar[v] ??= {}).add(closureNode);
      }
      for (TypeVariable v in typeVarsFreeInClosureReturns(closure)) {
        (closuresConstrainingTypeVar[v] ??= {}).add(closureNode);
      }
    }
    for (TypeVariable typeVariable in typeVariables) {
      for (_ClosureNode<Closure> closureNode
          in closuresDependingOnTypeVar[typeVariable] ?? const {}) {
        closureNode.dependencies
            .addAll(closuresConstrainingTypeVar[typeVariable] ?? const {});
      }
    }
  }

  /// Computes the order in which to resolve the closures passed to the
  /// constructor.
  ///
  /// Each entry in the returned list represents the set of closures that should
  /// be visited during a single stage of resolution; after each stage, the
  /// assignment of actual types to type variables should be refined.
  ///
  /// So, for example, if the closures in question are A, B, and C, and the
  /// returned list is `[{A, B}, {C}]`, then first closures A and B should be
  /// resolved, then the assignment of actual types to type variables should be
  /// refined, and then C should be resolved, and then the final assignment of
  /// actual types to type variables should be computed.
  List<Set<Closure>> planClosureReconciliationStages() {
    _DependencyWalker<Closure> walker = new _DependencyWalker<Closure>();
    for (_ClosureNode<Closure> closureNode in _closureNodes) {
      walker.walk(closureNode);
    }
    return walker.closureReconciliationStages;
  }

  /// If the type of the parameter corresponding to [closure] is a function
  /// type, the set of type parameters referred to by the parameter types of
  /// that parameter.  If the type of the parameter is not a function type, an
  /// empty iterable should be returned.
  ///
  /// Should be overridden by the client.
  Iterable<TypeVariable> typeVarsFreeInClosureArguments(Closure closure);

  /// If the type of the parameter corresponding to [closure] is a function
  /// type, the set of type parameters referred to by the return type of that
  /// parameter.  If the type of the parameter is not a function type, the set
  /// type parameters referred to by the type of the parameter should be
  /// returned.
  ///
  /// Should be overridden by the client.
  Iterable<TypeVariable> typeVarsFreeInClosureReturns(Closure closure);
}

/// Node type representing a single [Closure] for purposes of walking the
/// graph of type inference dependencies among closures.
class _ClosureNode<Closure> extends Node<_ClosureNode<Closure>> {
  /// The [Closure] being represented by this node.
  final Closure closure;

  /// If not `null`, the index of the reconciliation stage to which this closure
  /// has been assigned.
  int? stageNum;

  /// The nodes for the closures depended on by this closure.
  final List<_ClosureNode<Closure>> dependencies = [];

  _ClosureNode(this.closure);

  @override
  bool get isEvaluated => stageNum != null;

  @override
  List<_ClosureNode<Closure>> computeDependencies() => dependencies;
}

/// Derived class of [DependencyWalker] capable of walking the graph of type
/// inference dependencies among closures.
class _DependencyWalker<Closure>
    extends DependencyWalker<_ClosureNode<Closure>> {
  /// The set of closure reconciliation stages accumulated so far.
  final List<Set<Closure>> closureReconciliationStages = [];

  @override
  void evaluate(_ClosureNode v) => evaluateScc([v]);

  @override
  void evaluateScc(List<_ClosureNode> nodes) {
    int stageNum = 0;
    for (_ClosureNode node in nodes) {
      for (_ClosureNode dependency in node.dependencies) {
        int? dependencyStageNum = dependency.stageNum;
        if (dependencyStageNum != null && dependencyStageNum >= stageNum) {
          stageNum = dependencyStageNum + 1;
        }
      }
    }
    if (closureReconciliationStages.length <= stageNum) {
      closureReconciliationStages.add({});
      // `stageNum` can't grow by more than 1 each time `evaluateScc` is called,
      // so adding one stage is sufficient to make sure the list is now long
      // enough.
      assert(stageNum < closureReconciliationStages.length);
    }
    Set<Closure> stage = closureReconciliationStages[stageNum];
    for (_ClosureNode node in nodes) {
      node.stageNum = stageNum;
      stage.add(node.closure);
    }
  }
}
