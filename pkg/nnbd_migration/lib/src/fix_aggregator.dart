// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/edit_plan.dart';

/// Implementation of [NodeChange] representing the addition of the keyword
/// `required` to a named parameter.
class AddRequiredKeyword extends NestableChange {
  /// Information about why the change should be made.
  final AtomicEditInfo info;

  const AddRequiredKeyword(this.info,
      [NodeChange<NodeProducingEditPlan> inner = const NoChange()])
      : super._(inner);

  @override
  EditPlan apply(AstNode node, FixAggregator aggregator) {
    var innerPlan = inner.apply(node, aggregator);
    return aggregator.planner.surround(innerPlan,
        prefix: [AtomicEdit.insert('required ', info: info)]);
  }
}

/// Implementation of [NodeChange] representing the removal of a dead branch
/// because the conditional expression in an if statement, if element, or
/// conditional expression has been determined to always evaluate to either
/// `true` or `false`.
class EliminateDeadIf extends NodeChange {
  /// The value that the conditional expression has been determined to always
  /// evaluate to
  final bool conditionValue;

  /// Reasons for the change.
  final List<FixReasonInfo> reasons;

  const EliminateDeadIf(this.conditionValue, {this.reasons = const []});

  @override
  EditPlan apply(AstNode node, FixAggregator aggregator) {
    // TODO(paulberry): do we need to detect whether the condition has side
    // effects?  For now, assuming no.
    AstNode thenNode;
    AstNode elseNode;
    if (node is IfStatement) {
      thenNode = node.thenStatement;
      elseNode = node.elseStatement;
    } else if (node is ConditionalExpression) {
      thenNode = node.thenExpression;
      elseNode = node.elseExpression;
    } else if (node is IfElement) {
      thenNode = node.thenElement;
      elseNode = node.elseElement;
    } else {
      throw StateError(
          "EliminateDeadIf applied to an AST node that's not an if");
    }
    AstNode nodeToKeep;
    NullabilityFixDescription descriptionBefore, descriptionAfter;
    if (conditionValue) {
      nodeToKeep = thenNode;
      descriptionBefore = NullabilityFixDescription.discardCondition;
      if (elseNode == null) {
        descriptionAfter = descriptionBefore;
      } else {
        descriptionAfter = NullabilityFixDescription.discardElse;
      }
    } else {
      nodeToKeep = elseNode;
      descriptionBefore =
          descriptionAfter = NullabilityFixDescription.discardThen;
    }
    if (nodeToKeep == null ||
        nodeToKeep is Block && nodeToKeep.statements.isEmpty) {
      var info = AtomicEditInfo(NullabilityFixDescription.discardIf, reasons);
      return aggregator.planner.removeNode(node, info: info);
    }
    var infoBefore = AtomicEditInfo(descriptionBefore, reasons);
    var infoAfter = AtomicEditInfo(descriptionAfter, reasons);
    if (nodeToKeep is Block && nodeToKeep.statements.length == 1) {
      var singleStatement = (nodeToKeep as Block).statements[0];
      if (singleStatement is VariableDeclarationStatement) {
        // It's not safe to eliminate the {} because it increases the scope of
        // the variable declarations
      } else {
        nodeToKeep = singleStatement;
      }
    }
    return aggregator.planner.extract(
        node, aggregator.innerPlanForNode(nodeToKeep),
        infoBefore: infoBefore, infoAfter: infoAfter);
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
class IntroduceAs extends NestableChange {
  /// TODO(paulberry): shouldn't be a String
  final String type;

  /// Information about why the change should be made.
  final AtomicEditInfo info;

  const IntroduceAs(this.type, this.info,
      [NodeChange<NodeProducingEditPlan> inner = const NoChange()])
      : super._(inner);

  @override
  EditPlan apply(AstNode node, FixAggregator aggregator) {
    var innerPlan = inner.apply(node, aggregator);
    return aggregator.planner.addBinaryPostfix(innerPlan, TokenType.AS, type);
  }
}

/// Implementation of [NodeChange] representing the addition of a trailing `?`
/// to a type.
class MakeNullable extends NestableChange {
  /// The decorated type to which a question mark is being added.
  final DecoratedType decoratedType;

  const MakeNullable(this.decoratedType,
      [NodeChange<NodeProducingEditPlan> inner = const NoChange()])
      : super._(inner);

  @override
  EditPlan apply(AstNode node, FixAggregator aggregator) {
    var innerPlan = inner.apply(node, aggregator);
    return aggregator.planner.makeNullable(innerPlan,
        info: AtomicEditInfo(
            NullabilityFixDescription.makeTypeNullable(
                decoratedType.type.toString()),
            [decoratedType.node]));
  }
}

/// Shared base class for [NodeChange]s that are based on an [inner] change.
abstract class NestableChange extends NodeChange {
  /// The change that should be applied first, before applying this change.
  final NodeChange<NodeProducingEditPlan> inner;

  const NestableChange._(this.inner);
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
class NullCheck extends NestableChange {
  /// Information about why the change should be made.
  final AtomicEditInfo info;

  const NullCheck(this.info,
      [NodeChange<NodeProducingEditPlan> inner = const NoChange()])
      : super._(inner);

  @override
  EditPlan apply(AstNode node, FixAggregator aggregator) {
    var innerPlan = inner.apply(node, aggregator);
    return aggregator.planner
        .addUnaryPostfix(innerPlan, TokenType.BANG, info: info);
  }
}

/// Implementation of [NodeChange] representing the removal of an unnecessary
/// cast.
class RemoveAs extends NestableChange {
  const RemoveAs([NodeChange<NodeProducingEditPlan> inner = const NoChange()])
      : super._(inner);

  @override
  EditPlan apply(AstNode node, FixAggregator aggregator) {
    return aggregator.planner.extract(
        node, inner.apply((node as AsExpression).expression, aggregator),
        infoAfter:
            AtomicEditInfo(NullabilityFixDescription.removeAs, const []));
  }
}

/// Implementation of [NodeChange] representing the removal of `?` from a `?.`
/// in a method invocation because the target is non-nullable, or because of
/// null shorting.
class RemoveNullAwarenessFromMethodInvocation
    extends NodeChange<NodeProducingEditPlan> {
  const RemoveNullAwarenessFromMethodInvocation();

  @override
  NodeProducingEditPlan apply(AstNode node, FixAggregator aggregator) {
    var methodInvocation = node as MethodInvocation;
    var typeArguments = methodInvocation.typeArguments;
    return aggregator.planner.passThrough(methodInvocation, innerPlans: [
      aggregator.innerPlanForNode(methodInvocation.target),
      aggregator.planner.removeNullAwareness(methodInvocation,
          info: AtomicEditInfo(
              NullabilityFixDescription.removeNullAwareness, [])),
      aggregator.innerPlanForNode(methodInvocation.methodName),
      if (typeArguments != null) aggregator.innerPlanForNode(typeArguments),
      aggregator.innerPlanForNode(methodInvocation.argumentList)
    ]);
  }
}

/// Implementation of [NodeChange] representing the removal of `?` from a `?.`
/// in a property access because the target is non-nullable, or because of null
/// shorting.
class RemoveNullAwarenessFromPropertyAccess
    extends NodeChange<NodeProducingEditPlan> {
  const RemoveNullAwarenessFromPropertyAccess();

  @override
  NodeProducingEditPlan apply(AstNode node, FixAggregator aggregator) {
    var propertyAccess = node as PropertyAccess;
    return aggregator.planner.passThrough(
      propertyAccess,
      innerPlans: [
        aggregator.innerPlanForNode(propertyAccess.target),
        aggregator.planner.removeNullAwareness(propertyAccess,
            info: AtomicEditInfo(
                NullabilityFixDescription.removeNullAwareness, [])),
        aggregator.innerPlanForNode(propertyAccess.propertyName)
      ],
    );
  }
}

/// Implementation of [NodeChange] that changes an `@required` annotation into
/// a `required` keyword.
class RequiredAnnotationToRequiredKeyword extends NestableChange {
  /// Information about why the change should be made.
  final AtomicEditInfo info;

  const RequiredAnnotationToRequiredKeyword(this.info,
      [NodeChange<NodeProducingEditPlan> inner = const NoChange()])
      : super._(inner);

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
      return aggregator.planner
          .extract(node, inner.apply(name, aggregator), infoBefore: info);
    } else {
      return aggregator.planner
          .replace(node, [AtomicEdit.insert('required', info: info)]);
    }
  }
}
