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
import 'package:nnbd_migration/src/fix_builder.dart';

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
    var innerPlans = innerPlansForNode(node);
    return planner.passThrough(node, innerPlans: innerPlans);
  }

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

  /// Gathers all the changes to [node] and its descendants into a single
  /// [EditPlan].
  EditPlan planForNode(AstNode node) {
    var change = _changes[node];
    if (change != null) {
      return change._apply(node, this);
    } else {
      return planner.passThrough(node, innerPlans: innerPlansForNode(node));
    }
  }

  @override
  void visitNode(AstNode node) {
    var change = _changes[node];
    if (change != null) {
      var innerPlan = change._apply(node, this);
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

/// Base class representing a kind of change that [FixAggregator] might make to
/// a particular AST node.
abstract class NodeChange {
  /// Creates the appropriate specialized kind of [NodeChange] appropriate for
  /// the given [node].
  factory NodeChange(AstNode node) => node.accept(_NodeChangeVisitor._instance);

  NodeChange._();

  /// Applies this change to the given [node], producing an [EditPlan].  The
  /// [aggregator] may be used to gather up any edits to the node's descendants
  /// into their own [EditPlan]s.
  ///
  /// Note: the reason the caller can't just gather up the edits and pass them
  /// in is that some changes don't preserve all of the structure of the nodes
  /// below them (e.g. dropping an unnecessary cast), so those changes need to
  /// be able to call the appropriate [aggregator] methods just on the nodes
  /// they need.
  ///
  /// May return `null` if no changes need to be made.
  EditPlan _apply(AstNode node, FixAggregator aggregator);
}

/// Implementation of [NodeChange] specialized for operating on [Annotation]
/// nodes.
class NodeChangeForAnnotation extends NodeChange {
  /// Indicates whether the node should be changed into a `required` keyword.
  bool changeToRequiredKeyword = false;

  /// If [changeToRequiredKeyword] is `true`, the information that should be
  /// contained in the edit.
  AtomicEditInfo changeToRequiredKeywordInfo;

  NodeChangeForAnnotation() : super._();

  @override
  EditPlan _apply(covariant Annotation node, FixAggregator aggregator) {
    if (!changeToRequiredKeyword) {
      return aggregator.innerPlanForNode(node);
    }
    var name = node.name;
    if (name is PrefixedIdentifier) {
      name = (name as PrefixedIdentifier).identifier;
    }
    if (name != null &&
        aggregator.planner.sourceText.substring(name.offset, name.end) ==
            'required') {
      // The text `required` already exists in the annotation; we can just
      // extract it.
      return aggregator.planner.extract(
          node, aggregator.planForNode(name) as NodeProducingEditPlan,
          infoBefore: changeToRequiredKeywordInfo);
    } else {
      return aggregator.planner.replace(node,
          [AtomicEdit.insert('required', info: changeToRequiredKeywordInfo)]);
    }
  }
}

/// Implementation of [NodeChange] specialized for operating on [AsExpression]
/// nodes.
class NodeChangeForAsExpression extends NodeChangeForExpression {
  /// Indicates whether the cast should be removed.
  bool removeAs = false;

  @override
  EditPlan _apply(covariant AsExpression node, FixAggregator aggregator) {
    if (removeAs) {
      return aggregator.planner.extract(node,
          aggregator.planForNode(node.expression) as NodeProducingEditPlan,
          infoAfter:
              AtomicEditInfo(NullabilityFixDescription.removeAs, const []));
    } else {
      return super._apply(node, aggregator);
    }
  }
}

/// Common infrastructure used by [NodeChange] objects that operate on AST nodes
/// with conditional behavior (if statements, if elements, and conditional
/// expressions).
mixin NodeChangeForConditional on NodeChange {
  /// If not `null`, indicates that the condition expression is known to
  /// evaluate to either `true` or `false`, so the other branch of the
  /// conditional is dead code and should be eliminated.
  bool conditionValue;

  /// If [conditionValue] is not `null`, the reasons that should be included in
  /// the [AtomicEditInfo] for the edit that removes the dead code.
  List<FixReasonInfo> conditionReasons;

  /// If dead code removal is warranted for [node], returns an [EditPlan] that
  /// removes the dead code (and performs appropriate updates within any
  /// descendant AST nodes that remain).  Otherwise returns `null`.
  EditPlan _applyConditional(AstNode node, FixAggregator aggregator,
      AstNode thenNode, AstNode elseNode) {
    if (conditionValue == null) return null;
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
      var info =
          AtomicEditInfo(NullabilityFixDescription.discardIf, conditionReasons);
      return aggregator.planner.removeNode(node, info: info);
    }
    var infoBefore = AtomicEditInfo(descriptionBefore, conditionReasons);
    var infoAfter = AtomicEditInfo(descriptionAfter, conditionReasons);
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
        node, aggregator.planForNode(nodeToKeep) as NodeProducingEditPlan,
        infoBefore: infoBefore, infoAfter: infoAfter);
  }
}

/// Implementation of [NodeChange] specialized for operating on
/// [ConditionalExpression] nodes.
class NodeChangeForConditionalExpression extends NodeChangeForExpression
    with NodeChangeForConditional {
  @override
  EditPlan _apply(
      covariant ConditionalExpression node, FixAggregator aggregator) {
    return _applyConditional(
            node, aggregator, node.thenExpression, node.elseExpression) ??
        super._apply(node, aggregator);
  }
}

/// Implementation of [NodeChange] specialized for operating on
/// [DefaultFormalParameter] nodes.
class NodeChangeForDefaultFormalParameter extends NodeChange {
  /// Indicates whether a `required` keyword should be added to this node.
  bool addRequiredKeyword = false;

  /// If [addRequiredKeyword] is `true`, the information that should be
  /// contained in the edit.
  AtomicEditInfo addRequiredKeywordInfo;

  NodeChangeForDefaultFormalParameter() : super._();

  @override
  EditPlan _apply(
      covariant DefaultFormalParameter node, FixAggregator aggregator) {
    var innerPlan = aggregator.innerPlanForNode(node);
    if (!addRequiredKeyword) return innerPlan;
    return aggregator.planner.surround(innerPlan,
        prefix: [AtomicEdit.insert('required ', info: addRequiredKeywordInfo)]);
  }
}

/// Implementation of [NodeChange] specialized for operating on [Expression]
/// nodes.
class NodeChangeForExpression extends NodeChange {
  /// Indicates whether the expression should be null checked.
  bool addNullCheck = false;

  /// If [addNullCheck] is `true`, the information that should be contained in
  /// the edit that adds the null check.
  AtomicEditInfo addNullCheckInfo;

  /// Indicates whether the expression should be cast to a different type using
  /// `as`.
  String introduceAsType;

  /// If [introduceAsType] is not `null`, the information that should be
  /// contained in the edit that introduces the cast.
  AtomicEditInfo introduceAsInfo;

  NodeChangeForExpression() : super._();

  @override
  EditPlan _apply(covariant Expression node, FixAggregator aggregator) {
    var innerPlan = aggregator.innerPlanForNode(node);
    return _applyExpression(aggregator, innerPlan);
  }

  /// If the expression needs to be wrapped in another expression (e.g. a null
  /// check), wraps the given [innerPlan] to produce appropriate result.
  /// Otherwise returns [innerPlan] unchanged.
  NodeProducingEditPlan _applyExpression(
      FixAggregator aggregator, NodeProducingEditPlan innerPlan) {
    assert((introduceAsType == null) == (introduceAsInfo == null));
    if (addNullCheck) {
      assert(introduceAsInfo == null);
      return aggregator.planner
          .addUnaryPostfix(innerPlan, TokenType.BANG, info: addNullCheckInfo);
    } else if (introduceAsInfo != null) {
      return aggregator.planner
          .addBinaryPostfix(innerPlan, TokenType.AS, introduceAsType);
    } else {
      return innerPlan;
    }
  }
}

/// Implementation of [NodeChange] specialized for operating on [IfElement]
/// nodes.
class NodeChangeForIfElement extends NodeChange with NodeChangeForConditional {
  NodeChangeForIfElement() : super._();

  @override
  EditPlan _apply(covariant IfElement node, FixAggregator aggregator) {
    return _applyConditional(
            node, aggregator, node.thenElement, node.elseElement) ??
        aggregator.innerPlanForNode(node);
  }
}

/// Implementation of [NodeChange] specialized for operating on [IfStatement]
/// nodes.
class NodeChangeForIfStatement extends NodeChange
    with NodeChangeForConditional {
  NodeChangeForIfStatement() : super._();

  @override
  EditPlan _apply(covariant IfStatement node, FixAggregator aggregator) {
    return _applyConditional(
            node, aggregator, node.thenStatement, node.elseStatement) ??
        aggregator.innerPlanForNode(node);
  }
}

/// Implementation of [NodeChange] specialized for operating on
/// [MethodInvocation] nodes.
class NodeChangeForMethodInvocation extends NodeChangeForExpression
    with NodeChangeForNullAware {
  @override
  NodeProducingEditPlan _apply(
      covariant MethodInvocation node, FixAggregator aggregator) {
    var target = node.target;
    var targetPlan = target == null ? null : aggregator.planForNode(target);
    var nullAwarePlan = _applyNullAware(node, aggregator);
    var methodNamePlan = aggregator.planForNode(node.methodName);
    var typeArguments = node.typeArguments;
    var typeArgumentsPlan =
        typeArguments == null ? null : aggregator.planForNode(typeArguments);
    var argumentListPlan = aggregator.planForNode(node.argumentList);
    var innerPlans = [
      if (targetPlan != null) targetPlan,
      if (nullAwarePlan != null) nullAwarePlan,
      if (methodNamePlan != null) methodNamePlan,
      if (typeArgumentsPlan != null) typeArgumentsPlan,
      if (argumentListPlan != null) argumentListPlan
    ];
    return _applyExpression(aggregator,
        aggregator.planner.passThrough(node, innerPlans: innerPlans));
  }
}

/// Common infrastructure used by [NodeChange] objects that operate on AST nodes
/// with that can be null-aware (method invocations and propety accesses).
mixin NodeChangeForNullAware on NodeChange {
  /// Indicates whether null-awareness should be removed.
  bool removeNullAwareness = false;

  /// Returns an [EditPlan] that removes null awareness, if appropriate.
  /// Otherwise returns `null`.
  EditPlan _applyNullAware(Expression node, FixAggregator aggregator) {
    if (!removeNullAwareness) return null;
    return aggregator.planner.removeNullAwareness(node,
        info:
            AtomicEditInfo(NullabilityFixDescription.removeNullAwareness, []));
  }
}

/// Implementation of [NodeChange] specialized for operating on [PropertyAccess]
/// nodes.
class NodeChangeForPropertyAccess extends NodeChangeForExpression
    with NodeChangeForNullAware {
  @override
  NodeProducingEditPlan _apply(
      covariant PropertyAccess node, FixAggregator aggregator) {
    var targetPlan = aggregator.planForNode(node.target);
    var nullAwarePlan = _applyNullAware(node, aggregator);
    var propertyNamePlan = aggregator.planForNode(node.propertyName);
    var innerPlans = [
      if (targetPlan != null) targetPlan,
      if (nullAwarePlan != null) nullAwarePlan,
      if (propertyNamePlan != null) propertyNamePlan
    ];
    return _applyExpression(aggregator,
        aggregator.planner.passThrough(node, innerPlans: innerPlans));
  }
}

/// Implementation of [NodeChange] specialized for operating on [TypeAnnotation]
/// nodes.
class NodeChangeForTypeAnnotation extends NodeChange {
  /// Indicates whether the type should be made nullable by adding a `?`.
  bool makeNullable = false;

  /// If [makeNullable] is `true`, the decorated type that results.
  DecoratedType makeNullableType;

  NodeChangeForTypeAnnotation() : super._();

  @override
  EditPlan _apply(covariant TypeAnnotation node, FixAggregator aggregator) {
    var innerPlan = aggregator.innerPlanForNode(node);
    if (!makeNullable) return innerPlan;
    return aggregator.planner.makeNullable(innerPlan,
        info: AtomicEditInfo(
            NullabilityFixDescription.makeTypeNullable(
                makeNullableType.type.toString()),
            [makeNullableType.node]));
  }
}

/// Visitor that creates an appropriate [NodeChange] object for the node being
/// visited.
class _NodeChangeVisitor extends GeneralizingAstVisitor<NodeChange> {
  static final _instance = _NodeChangeVisitor();

  @override
  NodeChange visitAnnotation(Annotation node) => NodeChangeForAnnotation();

  @override
  NodeChange visitAsExpression(AsExpression node) =>
      NodeChangeForAsExpression();

  @override
  NodeChange visitDefaultFormalParameter(DefaultFormalParameter node) =>
      NodeChangeForDefaultFormalParameter();

  @override
  NodeChange visitExpression(Expression node) => NodeChangeForExpression();

  @override
  NodeChange visitGenericFunctionType(GenericFunctionType node) =>
      NodeChangeForTypeAnnotation();

  @override
  NodeChange visitIfElement(IfElement node) => NodeChangeForIfElement();

  @override
  NodeChange visitIfStatement(IfStatement node) => NodeChangeForIfStatement();

  @override
  NodeChange visitMethodInvocation(MethodInvocation node) =>
      NodeChangeForMethodInvocation();

  @override
  NodeChange visitNode(AstNode node) =>
      throw StateError('Unexpected node type: ${node.runtimeType}');

  @override
  NodeChange visitPropertyAccess(PropertyAccess node) =>
      NodeChangeForPropertyAccess();

  @override
  NodeChange visitTypeName(TypeName node) => NodeChangeForTypeAnnotation();
}
