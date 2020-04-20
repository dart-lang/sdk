// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:nnbd_migration/fix_reason_target.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/edit_plan.dart';
import 'package:nnbd_migration/src/fix_builder.dart';
import 'package:nnbd_migration/src/utilities/hint_utils.dart';

/// Visitor that combines together the changes produced by [FixBuilder] into a
/// concrete set of source code edits using the infrastructure of [EditPlan].
class FixAggregator extends UnifyingAstVisitor<void> {
  /// Map from the [AstNode]s that need to have changes made, to the changes
  /// that need to be applied to them.
  final Map<AstNode, NodeChange> _changes;

  /// The set of [EditPlan]s being accumulated.
  List<EditPlan> _plans = [];

  final EditPlanner planner;

  /// Map from library to the prefix we should use when inserting code that
  /// refers to it.
  final Map<LibraryElement, String> _importPrefixes = {};

  final bool _warnOnWeakCode;

  FixAggregator._(this.planner, this._changes, this._warnOnWeakCode,
      CompilationUnitElement compilationUnitElement) {
    for (var importElement in compilationUnitElement.library.imports) {
      // TODO(paulberry): the `??=` should ensure that if there are two imports,
      // one prefixed and one not, we prefer the prefix.  Test this.
      _importPrefixes[importElement.importedLibrary] ??=
          importElement.prefix?.name;
    }
  }

  /// Creates the necessary Dart code to refer to the given element, using an
  /// import prefix if necessary.
  ///
  /// TODO(paulberry): if the element is not currently imported, we should
  /// update or add an import statement as necessary.
  String elementToCode(Element element) {
    var name = element.name;
    var library = element.library;
    var prefix = _importPrefixes[library];
    if (prefix != null) {
      return '$prefix.$name';
    } else {
      return name;
    }
  }

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

  /// Creates a string representation of the given type parameter element,
  /// suitable for inserting into the user's source code.
  String typeFormalToCode(TypeParameterElement formal) {
    var bound = formal.bound;
    if (bound == null ||
        bound.isDynamic ||
        (bound.isDartCoreObject &&
            bound.nullabilitySuffix != NullabilitySuffix.none)) {
      return formal.name;
    }
    return '${formal.name} extends ${typeToCode(bound)}';
  }

  String typeToCode(DartType type) {
    // TODO(paulberry): is it possible to share code with DartType.toString()
    // somehow?
    String suffix =
        type.nullabilitySuffix == NullabilitySuffix.question ? '?' : '';
    if (type is InterfaceType) {
      var name = elementToCode(type.element);
      var typeArguments = type.typeArguments;
      if (typeArguments.isEmpty) {
        return '$name$suffix';
      } else {
        var args = [for (var arg in typeArguments) typeToCode(arg)].join(', ');
        return '$name<$args>$suffix';
      }
    } else if (type is FunctionType) {
      var buffer = StringBuffer();
      buffer.write(typeToCode(type.returnType));
      buffer.write(' Function');
      var typeFormals = type.typeFormals;
      if (typeFormals.isNotEmpty) {
        var formals = [for (var formal in typeFormals) typeFormalToCode(formal)]
            .join(', ');
        buffer.write('<$formals>');
      }
      buffer.write('(');
      String optionalOrNamedCloser = '';
      bool commaNeeded = false;
      for (var parameter in type.parameters) {
        if (commaNeeded) {
          buffer.write(', ');
        } else {
          commaNeeded = true;
        }
        if (optionalOrNamedCloser.isEmpty && !parameter.isRequiredPositional) {
          if (parameter.isPositional) {
            buffer.write('[');
            optionalOrNamedCloser = ']';
          } else {
            buffer.write('{');
            optionalOrNamedCloser = '}';
          }
        }
        buffer.write(typeToCode(parameter.type));
        if (parameter.isNamed) {
          buffer.write(' ${parameter.name}');
        }
      }
      buffer.write(optionalOrNamedCloser);
      buffer.write(')');
      buffer.write(suffix);
      return buffer.toString();
    } else {
      return type.toString();
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
      {bool removeViaComments = true, bool warnOnWeakCode = false}) {
    var planner = EditPlanner(unit.lineInfo, sourceText,
        removeViaComments: removeViaComments);
    var aggregator =
        FixAggregator._(planner, changes, warnOnWeakCode, unit.declaredElement);
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
abstract class NodeChange<N extends AstNode> {
  NodeChange._();

  /// Indicates whether this node exists solely to provide informative
  /// information.
  bool get isInformative => false;

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
  EditPlan _apply(N node, FixAggregator aggregator);

  /// Creates the appropriate specialized kind of [NodeChange] appropriate for
  /// the given [node].
  static NodeChange<AstNode> create(AstNode node) =>
      node.accept(_NodeChangeVisitor._instance);
}

/// Implementation of [NodeChange] specialized for operating on [Annotation]
/// nodes.
class NodeChangeForAnnotation extends NodeChange<Annotation> {
  /// Indicates whether the node should be changed into a `required` keyword.
  bool changeToRequiredKeyword = false;

  /// If [changeToRequiredKeyword] is `true`, the information that should be
  /// contained in the edit.
  AtomicEditInfo changeToRequiredKeywordInfo;

  NodeChangeForAnnotation() : super._();

  @override
  EditPlan _apply(Annotation node, FixAggregator aggregator) {
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
class NodeChangeForAsExpression extends NodeChangeForExpression<AsExpression> {
  /// Indicates whether the cast should be removed.
  bool removeAs = false;

  @override
  EditPlan _apply(AsExpression node, FixAggregator aggregator) {
    if (removeAs) {
      return aggregator.planner.extract(node,
          aggregator.planForNode(node.expression) as NodeProducingEditPlan,
          infoAfter:
              AtomicEditInfo(NullabilityFixDescription.removeAs, const {}));
    } else {
      return super._apply(node, aggregator);
    }
  }
}

/// Implementation of [NodeChange] specialized for operating on
/// [CompilationUnit] nodes.
class NodeChangeForCompilationUnit extends NodeChange<CompilationUnit> {
  bool removeLanguageVersionComment = false;

  NodeChangeForCompilationUnit() : super._();

  @override
  EditPlan _apply(CompilationUnit node, FixAggregator aggregator) {
    List<EditPlan> innerPlans = [];
    if (removeLanguageVersionComment) {
      final comment = (node as CompilationUnitImpl).languageVersionToken;
      assert(comment != null);
      innerPlans.add(aggregator.planner.replaceToken(node, comment, '',
          info: AtomicEditInfo(
              NullabilityFixDescription.removeLanguageVersionComment,
              const {})));
    }
    innerPlans.addAll(aggregator.innerPlansForNode(node));
    return aggregator.planner.passThrough(node, innerPlans: innerPlans);
  }
}

/// Common infrastructure used by [NodeChange] objects that operate on AST nodes
/// with conditional behavior (if statements, if elements, and conditional
/// expressions).
mixin NodeChangeForConditional<N extends AstNode> on NodeChange<N> {
  /// If not `null`, indicates that the condition expression is known to
  /// evaluate to either `true` or `false`, so the other branch of the
  /// conditional is dead code and should be eliminated.
  bool conditionValue;

  /// If [conditionValue] is not `null`, the reason that should be included in
  /// the [AtomicEditInfo] for the edit that removes the dead code.
  FixReasonInfo conditionReason;

  /// If dead code removal is warranted for [node], returns an [EditPlan] that
  /// removes the dead code (and performs appropriate updates within any
  /// descendant AST nodes that remain).  Otherwise returns `null`.
  EditPlan _applyConditional(N node, FixAggregator aggregator,
      AstNode conditionNode, AstNode thenNode, AstNode elseNode) {
    if (conditionValue == null) return null;
    if (aggregator._warnOnWeakCode) {
      List<EditPlan> innerPlans = [];
      var conditionPlan = aggregator.innerPlanForNode(conditionNode);
      var info = AtomicEditInfo(
          conditionValue
              ? NullabilityFixDescription.conditionTrueInStrongMode
              : NullabilityFixDescription.conditionFalseInStrongMode,
          {FixReasonTarget.root: conditionReason});
      var commentedConditionPlan = aggregator.planner.addCommentPostfix(
          conditionPlan, '/* == $conditionValue */',
          info: info, isInformative: true);
      innerPlans.add(commentedConditionPlan);
      innerPlans.addAll(aggregator.innerPlansForNode(thenNode));
      if (elseNode != null) {
        innerPlans.addAll(aggregator.innerPlansForNode(elseNode));
      }
      return aggregator.planner.passThrough(node, innerPlans: innerPlans);
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
      // The conditional node collapses to a no-op, so try to remove it
      // entirely.
      var info = AtomicEditInfo(NullabilityFixDescription.discardIf,
          {FixReasonTarget.root: conditionReason});
      var removeNode = aggregator.planner.tryRemoveNode(node, info: info);
      if (removeNode != null) {
        return removeNode;
      } else {
        // We can't remove the node because it's not inside a sequence, so we
        // have to create a suitable replacement.
        if (node is IfStatement) {
          return aggregator.planner
              .replace(node, [AtomicEdit.insert('{}', info: info)], info: info);
        } else if (node is IfElement) {
          return aggregator.planner.replace(
              node, [AtomicEdit.insert('...{}', info: info)],
              info: info);
        } else {
          // We should never get here; the only types of conditional nodes that
          // can wind up collapsing to a no-op are if statements and if
          // elements.
          throw StateError(
              'Unexpected node type collapses to no-op: ${node.runtimeType}');
        }
      }
    }
    var infoBefore = AtomicEditInfo(
        descriptionBefore, {FixReasonTarget.root: conditionReason});
    var infoAfter = AtomicEditInfo(
        descriptionAfter, {FixReasonTarget.root: conditionReason});
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
class NodeChangeForConditionalExpression
    extends NodeChangeForExpression<ConditionalExpression>
    with NodeChangeForConditional {
  @override
  EditPlan _apply(ConditionalExpression node, FixAggregator aggregator) {
    return _applyConditional(node, aggregator, node.condition,
            node.thenExpression, node.elseExpression) ??
        super._apply(node, aggregator);
  }
}

/// Implementation of [NodeChange] specialized for operating on
/// [DefaultFormalParameter] nodes.
class NodeChangeForDefaultFormalParameter
    extends NodeChange<DefaultFormalParameter> {
  /// Indicates whether a `required` keyword should be added to this node.
  bool addRequiredKeyword = false;

  /// If [addRequiredKeyword] is `true`, the information that should be
  /// contained in the edit.
  AtomicEditInfo addRequiredKeywordInfo;

  NodeChangeForDefaultFormalParameter() : super._();

  @override
  EditPlan _apply(DefaultFormalParameter node, FixAggregator aggregator) {
    var innerPlan = aggregator.innerPlanForNode(node);
    if (!addRequiredKeyword) return innerPlan;
    return aggregator.planner.surround(innerPlan,
        prefix: [AtomicEdit.insert('required ', info: addRequiredKeywordInfo)]);
  }
}

/// Implementation of [NodeChange] specialized for operating on [Expression]
/// nodes.
class NodeChangeForExpression<N extends Expression> extends NodeChange<N> {
  bool _addsNullCheck = false;

  AtomicEditInfo _addNullCheckInfo;

  HintComment _addNullCheckHint;

  DartType _introducesAsType;

  AtomicEditInfo _introduceAsInfo;

  NodeChangeForExpression() : super._();

  /// Gets the info for any added null check.
  AtomicEditInfo get addNullCheckInfo => _addNullCheckInfo;

  /// Indicates whether [addNullCheck] has been called.
  bool get addsNullCheck => _addsNullCheck;

  /// Gets the info for any introduced "as" cast
  AtomicEditInfo get introducesAsInfo => _introduceAsInfo;

  /// Gets the type for any introduced "as" cast, or `null` if no "as" cast is
  /// being introduced.
  DartType get introducesAsType => _introducesAsType;

  /// Causes a null check to be added to this expression, with the given [info].
  void addNullCheck(AtomicEditInfo info, {HintComment hint}) {
    assert(!_addsNullCheck);
    _addsNullCheck = true;
    _addNullCheckInfo = info;
    _addNullCheckHint = hint;
  }

  /// Causes a cast to the given [type] to be added to this expression, with
  /// the given [info].
  void introduceAs(DartType type, AtomicEditInfo info) {
    assert(_introducesAsType == null);
    assert(type != null);
    _introducesAsType = type;
    _introduceAsInfo = info;
  }

  @override
  EditPlan _apply(N node, FixAggregator aggregator) {
    var innerPlan = aggregator.innerPlanForNode(node);
    return _applyExpression(aggregator, innerPlan);
  }

  /// If the expression needs to be wrapped in another expression (e.g. a null
  /// check), wraps the given [innerPlan] to produce appropriate result.
  /// Otherwise returns [innerPlan] unchanged.
  NodeProducingEditPlan _applyExpression(
      FixAggregator aggregator, NodeProducingEditPlan innerPlan) {
    var plan = innerPlan;
    if (_addsNullCheck) {
      var hint = _addNullCheckHint;
      if (hint != null) {
        plan = aggregator.planner.acceptNullabilityOrNullCheckHint(plan, hint,
            info: _addNullCheckInfo);
      } else {
        plan = aggregator.planner
            .addUnaryPostfix(plan, TokenType.BANG, info: _addNullCheckInfo);
      }
    }
    if (_introducesAsType != null) {
      plan = aggregator.planner.addBinaryPostfix(
          plan, TokenType.AS, aggregator.typeToCode(_introducesAsType),
          info: _introduceAsInfo);
    }
    return plan;
  }
}

/// Implementation of [NodeChange] specialized for operating on [IfElement]
/// nodes.
class NodeChangeForIfElement extends NodeChange<IfElement>
    with NodeChangeForConditional {
  NodeChangeForIfElement() : super._();

  @override
  EditPlan _apply(IfElement node, FixAggregator aggregator) {
    return _applyConditional(node, aggregator, node.condition, node.thenElement,
            node.elseElement) ??
        aggregator.innerPlanForNode(node);
  }
}

/// Implementation of [NodeChange] specialized for operating on [IfStatement]
/// nodes.
class NodeChangeForIfStatement extends NodeChange<IfStatement>
    with NodeChangeForConditional {
  NodeChangeForIfStatement() : super._();

  @override
  EditPlan _apply(IfStatement node, FixAggregator aggregator) {
    return _applyConditional(node, aggregator, node.condition,
            node.thenStatement, node.elseStatement) ??
        aggregator.innerPlanForNode(node);
  }
}

/// Implementation of [NodeChange] specialized for operating on
/// [MethodInvocation] nodes.
class NodeChangeForMethodInvocation
    extends NodeChangeForExpression<MethodInvocation>
    with NodeChangeForNullAware {
  @override
  NodeProducingEditPlan _apply(
      MethodInvocation node, FixAggregator aggregator) {
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
mixin NodeChangeForNullAware<N extends Expression> on NodeChange<N> {
  /// Indicates whether null-awareness should be removed.
  bool removeNullAwareness = false;

  /// Returns an [EditPlan] that removes null awareness, if appropriate.
  /// Otherwise returns `null`.
  EditPlan _applyNullAware(N node, FixAggregator aggregator) {
    if (!removeNullAwareness) return null;
    var description = aggregator._warnOnWeakCode
        ? NullabilityFixDescription.nullAwarenessUnnecessaryInStrongMode
        : NullabilityFixDescription.removeNullAwareness;
    return aggregator.planner.removeNullAwareness(node,
        info: AtomicEditInfo(description, const {}),
        isInformative: aggregator._warnOnWeakCode);
  }
}

/// Implementation of [NodeChange] specialized for operating on [PropertyAccess]
/// nodes.
class NodeChangeForPropertyAccess
    extends NodeChangeForExpression<PropertyAccess>
    with NodeChangeForNullAware {
  @override
  NodeProducingEditPlan _apply(PropertyAccess node, FixAggregator aggregator) {
    var targetPlan =
        node.target == null ? null : aggregator.planForNode(node.target);
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

/// Implementation of [NodeChange] specialized for operating on
/// [SimpleFormalParameter] nodes.
class NodeChangeForSimpleFormalParameter
    extends NodeChange<SimpleFormalParameter> {
  /// If not `null`, an explicit type annotation that should be added to the
  /// parameter.
  DartType addExplicitType;

  NodeChangeForSimpleFormalParameter() : super._();

  @override
  EditPlan _apply(SimpleFormalParameter node, FixAggregator aggregator) {
    var innerPlan = aggregator.innerPlanForNode(node);
    if (addExplicitType == null) return innerPlan;
    return aggregator.planner.surround(innerPlan, prefix: [
      AtomicEdit.insert(
          addExplicitType.getDisplayString(withNullability: true)),
      AtomicEdit.insert(' ')
    ]);
  }
}

/// Implementation of [NodeChange] specialized for operating on [TypeAnnotation]
/// nodes.
class NodeChangeForTypeAnnotation extends NodeChange<TypeAnnotation> {
  bool _makeNullable = false;

  HintComment _nullabilityHint;

  /// The decorated type of the type annotation, or `null` if there is no
  /// decorated type info of interest.  If [makeNullable] is `true`, the node
  /// from this type will be attached to the edit that adds the `?`. If
  /// [_makeNullable] is `false`, the node from this type will be attached to the
  /// information about why the node wasn't made nullable.
  DecoratedType _decoratedType;

  NodeChangeForTypeAnnotation() : super._();

  @override
  bool get isInformative => !_makeNullable;

  /// Indicates whether the type should be made nullable by adding a `?`.
  bool get makeNullable => _makeNullable;

  /// If we are making the type nullable due to a hint, the comment that caused
  /// it.
  HintComment get nullabilityHint => _nullabilityHint;

  void recordNullability(DecoratedType decoratedType, bool makeNullable,
      {HintComment nullabilityHint}) {
    _decoratedType = decoratedType;
    _makeNullable = makeNullable;
    _nullabilityHint = nullabilityHint;
  }

  @override
  EditPlan _apply(TypeAnnotation node, FixAggregator aggregator) {
    var innerPlan = aggregator.innerPlanForNode(node);
    if (_decoratedType == null) return innerPlan;
    var typeName = _decoratedType.type.getDisplayString(withNullability: false);
    var fixReasons = {FixReasonTarget.root: _decoratedType.node};
    if (_makeNullable) {
      var hint = _nullabilityHint;
      if (hint != null) {
        return aggregator.planner.acceptNullabilityOrNullCheckHint(
            innerPlan, hint,
            info: AtomicEditInfo(
                NullabilityFixDescription.makeTypeNullableDueToHint(typeName),
                fixReasons,
                hintComment: hint));
      } else {
        return aggregator.planner.makeNullable(innerPlan,
            info: AtomicEditInfo(
                NullabilityFixDescription.makeTypeNullable(typeName),
                fixReasons));
      }
    } else {
      var hint = _nullabilityHint;
      if (hint != null) {
        return aggregator.planner.dropNullabilityHint(innerPlan, hint,
            info: AtomicEditInfo(
                NullabilityFixDescription.typeNotMadeNullableDueToHint(
                    typeName),
                fixReasons,
                hintComment: hint));
      } else {
        return aggregator.planner.explainNonNullable(innerPlan,
            info: AtomicEditInfo(
                NullabilityFixDescription.typeNotMadeNullable(typeName),
                fixReasons));
      }
    }
  }
}

/// Implementation of [NodeChange] specialized for operating on
/// [VariableDeclarationList] nodes.
class NodeChangeForVariableDeclarationList
    extends NodeChange<VariableDeclarationList> {
  /// If an explicit type should be added to this variable declaration, the type
  /// that should be added.  Otherwise `null`.
  DartType addExplicitType;

  /// If a "late" annotation should be added to this variable  declaration, the
  /// hint that caused it.  Otherwise `null`.
  HintComment lateHint;

  NodeChangeForVariableDeclarationList() : super._();

  @override
  EditPlan _apply(VariableDeclarationList node, FixAggregator aggregator) {
    List<EditPlan> innerPlans = [];
    if (addExplicitType != null) {
      var typeText = addExplicitType.getDisplayString(withNullability: true);
      if (node.keyword?.keyword == Keyword.VAR) {
        var info =
            AtomicEditInfo(NullabilityFixDescription.replaceVar(typeText), {});
        innerPlans.add(aggregator.planner
            .replaceToken(node, node.keyword, typeText, info: info));
      } else {
        var info =
            AtomicEditInfo(NullabilityFixDescription.addType(typeText), {});
        innerPlans.add(aggregator.planner.insertText(
            node,
            node.variables.first.offset,
            [AtomicEdit.insert(typeText, info: info), AtomicEdit.insert(' ')]));
      }
    }
    innerPlans.addAll(aggregator.innerPlansForNode(node));
    var plan = aggregator.planner.passThrough(node, innerPlans: innerPlans);
    if (lateHint != null) {
      plan = aggregator.planner.acceptLateHint(plan, lateHint,
          info: AtomicEditInfo(NullabilityFixDescription.addLateDueToHint, {},
              hintComment: lateHint));
    }
    return plan;
  }
}

/// Visitor that creates an appropriate [NodeChange] object for the node being
/// visited.
class _NodeChangeVisitor extends GeneralizingAstVisitor<NodeChange<AstNode>> {
  static final _instance = _NodeChangeVisitor();

  @override
  NodeChange visitAnnotation(Annotation node) => NodeChangeForAnnotation();

  @override
  NodeChange visitAsExpression(AsExpression node) =>
      NodeChangeForAsExpression();

  @override
  NodeChange visitCompilationUnit(CompilationUnit node) =>
      NodeChangeForCompilationUnit();

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
  NodeChange visitSimpleFormalParameter(SimpleFormalParameter node) =>
      NodeChangeForSimpleFormalParameter();

  @override
  NodeChange visitTypeName(TypeName node) => NodeChangeForTypeAnnotation();

  @override
  NodeChange visitVariableDeclarationList(VariableDeclarationList node) =>
      NodeChangeForVariableDeclarationList();
}
