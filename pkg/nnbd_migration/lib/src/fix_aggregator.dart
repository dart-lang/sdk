// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:nnbd_migration/src/edit_plan.dart';

/// Implementation of [NodeChange] representing the addition of the keyword
/// `required` to a named parameter.
///
/// TODO(paulberry): store additional information necessary to include in the
/// preview.
class AddRequiredKeyword extends _NestableChange {
  const AddRequiredKeyword(
      [NodeChange<NodeProducingEditPlan> inner = const NoChange()])
      : super(inner);

  @override
  EditPlan apply(AstNode node, FixAggregator aggregator) {
    var innerPlan = _inner.apply(node, aggregator);
    return aggregator.planner
        .surround(innerPlan, prefix: [const AtomicEdit.insert('required ')]);
  }
}

/// Visitor that combines together the changes produced by [FixBuilder] into a
/// concrete set of source code edits using the infrastructure of [EditPlan].
class FixAggregator extends UnifyingAstVisitor<void> {
  /// Map from the [AstNode]s that need to have changes made, to the changes
  /// that need to be applied to them.
  final Map<AstNode, NodeChange> _changes;

  /// The set of [EditPlan]s being accumulated.
  List<EditPlan> _plans = [];

  final EditPlanner planner;

  FixAggregator._(this.planner, this._changes);

  /// Gathers all the changes to nodes descended from [node] into a single
  /// [EditPlan].
  NodeProducingEditPlan innerPlanForNode(AstNode node) {
    var previousPlans = _plans;
    try {
      _plans = [];
      node.visitChildren(this);
      return planner.passThrough(node, innerPlans: _plans);
    } finally {
      _plans = previousPlans;
    }
  }

  @override
  void visitNode(AstNode node) {
    var change = _changes[node];
    if (change != null) {
      var innerPlan = change.apply(node, this);
      if (innerPlan != null) {
        _plans.add(innerPlan);
      }
    } else {
      node.visitChildren(this);
    }
  }

  /// Runs the [FixAggregator] on a [unit] and returns the resulting edits.
  static Map<int, List<AtomicEdit>> run(
      CompilationUnit unit, Map<AstNode, NodeChange> changes) {
    var planner = EditPlanner();
    var aggregator = FixAggregator._(planner, changes);
    unit.accept(aggregator);
    if (aggregator._plans.isEmpty) return {};
    EditPlan plan;
    if (aggregator._plans.length == 1) {
      plan = aggregator._plans[0];
    } else {
      plan = planner.passThrough(unit, innerPlans: aggregator._plans);
    }
    return planner.finalize(plan);
  }
}

/// Implementation of [NodeChange] representing introduction of an explicit
/// downcast.
///
/// TODO(paulberry): store additional information necessary to include in the
/// preview.
class IntroduceAs extends _NestableChange {
  /// TODO(paulberry): shouldn't be a String
  final String type;

  const IntroduceAs(this.type,
      [NodeChange<NodeProducingEditPlan> inner = const NoChange()])
      : super(inner);

  @override
  EditPlan apply(AstNode node, FixAggregator aggregator) {
    var innerPlan = _inner.apply(node, aggregator);
    return aggregator.planner.surround(innerPlan,
        suffix: [AtomicEdit.insert(' as $type')],
        outerPrecedence: Precedence.relational,
        innerPrecedence: Precedence.relational);
  }
}

/// Implementation of [NodeChange] representing the addition of a trailing `?`
/// to a type.
///
/// TODO(paulberry): store additional information necessary to include in the
/// preview.
class MakeNullable extends _NestableChange {
  const MakeNullable(
      [NodeChange<NodeProducingEditPlan> inner = const NoChange()])
      : super(inner);

  @override
  EditPlan apply(AstNode node, FixAggregator aggregator) {
    var innerPlan = _inner.apply(node, aggregator);
    return aggregator.planner
        .surround(innerPlan, suffix: [const AtomicEdit.insert('?')]);
  }
}

/// Implementation of [NodeChange] representing no change at all.  This class
/// is intended to be used as a base class for changes that wrap around other
/// changes.
class NoChange extends NodeChange<NodeProducingEditPlan> {
  const NoChange();

  @override
  NodeProducingEditPlan apply(AstNode node, FixAggregator aggregator) {
    return aggregator.innerPlanForNode(node);
  }
}

/// Base class representing a kind of change that [FixAggregator] might make to a
/// particular AST node.
abstract class NodeChange<P extends EditPlan> {
  const NodeChange();

  /// Applies this change to the given [node], producing an [EditPlan].  The
  /// [aggregator] may be used to gather up any edits to the node's descendants
  /// into their own [EditPlan]s.
  ///
  /// Note: the reason the caller can't just gather up the edits and pass them
  /// in is that some changes don't preserve all of the structure of the nodes
  /// below them (e.g. dropping an unnecessary cast), so those changes need to
  /// be able to call the appropriate [aggregator] methods just on the nodes
  /// they need.
  P apply(AstNode node, FixAggregator aggregator);
}

/// Implementation of [NodeChange] representing the addition of a null check to
/// an expression.
///
/// TODO(paulberry): store additional information necessary to include in the
/// preview.
class NullCheck extends _NestableChange {
  const NullCheck([NodeChange<NodeProducingEditPlan> inner = const NoChange()])
      : super(inner);

  @override
  EditPlan apply(AstNode node, FixAggregator aggregator) {
    var innerPlan = _inner.apply(node, aggregator);
    return aggregator.planner.surround(innerPlan,
        suffix: [const AtomicEdit.insert('!')],
        outerPrecedence: Precedence.postfix,
        innerPrecedence: Precedence.postfix,
        associative: true);
  }
}

/// Implementation of [NodeChange] representing the removal of an unnecessary
/// cast.
///
/// TODO(paulberry): store additional information necessary to include in the
/// preview.
class RemoveAs extends _NestableChange {
  const RemoveAs([NodeChange<NodeProducingEditPlan> inner = const NoChange()])
      : super(inner);

  @override
  EditPlan apply(AstNode node, FixAggregator aggregator) {
    return aggregator.planner.extract(
        node, _inner.apply((node as AsExpression).expression, aggregator));
  }
}

/// Shared base class for [NodeChange]s that are based on an [_inner] change.
abstract class _NestableChange extends NodeChange {
  final NodeChange<NodeProducingEditPlan> _inner;

  const _NestableChange(this._inner);
}
