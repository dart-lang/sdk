// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
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

/// Implementation of [NodeChange] representing the removal of a dead branch
/// because the conditional expression in an if statement, if element, or
/// conditional expression has been determined to always evaluate to either
/// `true` or `false`.
///
/// TODO(paulberry): store additional information necessary to include in the
/// preview.
class EliminateDeadIf extends NodeChange {
  /// The value that the conditional expression has been determined to always
  /// evaluate to
  final bool conditionValue;

  const EliminateDeadIf(this.conditionValue);

  @override
  EditPlan apply(AstNode node, FixAggregator aggregator) {
    // TODO(paulberry): do we need to detect whether the condition has side
    // effects?  For now, assuming no.
    AstNode nodeToKeep;
    if (node is IfStatement) {
      nodeToKeep = conditionValue ? node.thenStatement : node.elseStatement;
    } else if (node is ConditionalExpression) {
      nodeToKeep = conditionValue ? node.thenExpression : node.elseExpression;
    } else if (node is IfElement) {
      nodeToKeep = conditionValue ? node.thenElement : node.elseElement;
    } else {
      throw StateError(
          "EliminateDeadIf applied to an AST node that's not an if");
    }
    if (nodeToKeep == null) {
      return aggregator.planner.removeNode(node);
    }
    if (nodeToKeep is Block) {
      if (nodeToKeep.statements.isEmpty) {
        return aggregator.planner.removeNode(node);
      } else if (nodeToKeep.statements.length == 1) {
        var singleStatement = nodeToKeep.statements[0];
        if (singleStatement is VariableDeclarationStatement) {
          // It's not safe to eliminate the {} because it increases the scope of
          // the variable declarations
        } else {
          return aggregator.planner.extract(
              node, aggregator.innerPlanForNode(nodeToKeep.statements.single));
        }
      }
    }
    return aggregator.planner
        .extract(node, aggregator.innerPlanForNode(nodeToKeep));
  }

  @override
  String toString() => 'EliminateDeadIf($conditionValue)';
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
  NodeProducingEditPlan innerPlanForNode(AstNode node) =>
      planner.passThrough(node, innerPlans: innerPlansForNode(node));

  /// Gathers all the changes to nodes descended from [node] into a list of
  /// [EditPlan]s, one for each change.
  List<EditPlan> innerPlansForNode(AstNode node) {
    var previousPlans = _plans;
    try {
      _plans = [];
      node.visitChildren(this);
      return _plans;
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
      CompilationUnit unit, String sourceText, Map<AstNode, NodeChange> changes,
      {bool removeViaComments: false}) {
    var planner = EditPlanner(unit.lineInfo, sourceText,
        removeViaComments: removeViaComments);
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
class MakeNullable extends _NestableChange {
  /// The decorated type to which a question mark is being added.
  final DecoratedType decoratedType;

  const MakeNullable(this.decoratedType,
      [NodeChange<NodeProducingEditPlan> inner = const NoChange()])
      : super(inner);

  @override
  EditPlan apply(AstNode node, FixAggregator aggregator) {
    var innerPlan = _inner.apply(node, aggregator);
    return aggregator.planner.surround(innerPlan,
        suffix: [AtomicEditWithReason.insert('?', decoratedType.node)]);
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

/// Implementation of [NodeChange] that changes an `@required` annotation into
/// a `required` keyword.
///
/// TODO(paulberry): store additional information necessary to include in the
/// preview.
class RequiredAnnotationToRequiredKeyword extends _NestableChange {
  const RequiredAnnotationToRequiredKeyword(
      [NodeChange<NodeProducingEditPlan> inner = const NoChange()])
      : super(inner);

  @override
  EditPlan apply(AstNode node, FixAggregator aggregator) {
    var annotation = node as Annotation;
    var name = annotation.name;
    if (name is PrefixedIdentifier) {
      name = (name as PrefixedIdentifier).identifier;
    }
    if (name != null &&
        aggregator.planner.sourceText.substring(name.offset, name.end) ==
            'required') {
      // The text `required` already exists in the annotation; we can just
      // extract it.
      return aggregator.planner.extract(node, _inner.apply(name, aggregator));
    } else {
      return aggregator.planner.replace(node, [AtomicEdit.insert('required')]);
    }
  }
}

/// Shared base class for [NodeChange]s that are based on an [_inner] change.
abstract class _NestableChange extends NodeChange {
  final NodeChange<NodeProducingEditPlan> _inner;

  const _NestableChange(this._inner);
}
