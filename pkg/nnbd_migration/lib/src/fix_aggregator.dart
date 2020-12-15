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
import 'package:meta/meta.dart';
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
      {bool removeViaComments = false, bool warnOnWeakCode = false}) {
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

/// Reasons that a variable declaration is to be made late.
enum LateAdditionReason {
  /// It was inferred that the associated variable declaration is to be made
  /// late through the late-inferring algorithm.
  inference,

  /// It was inferred that the associated variable declaration is to be made
  /// late, because it is a test variable which is assigned during setup.
  testVariableInference,
}

/// Base class representing a kind of change that [FixAggregator] might make to
/// a particular AST node.
abstract class NodeChange<N extends AstNode> {
  NodeChange._();

  /// Indicates whether this node exists solely to provide informative
  /// information.
  bool get isInformative => false;

  Iterable<String> get _toStringParts => const [];

  @override
  String toString() => '$runtimeType(${_toStringParts.join(', ')})';

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
  Iterable<String> get _toStringParts =>
      [if (changeToRequiredKeyword) 'changeToRequiredKeyword'];

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
          infoBefore: changeToRequiredKeywordInfo, alwaysDelete: true);
    } else {
      return aggregator.planner.replace(node,
          [AtomicEdit.insert('required', info: changeToRequiredKeywordInfo)]);
    }
  }
}

/// Implementation of [NodeChange] specialized for operating on [ArgumentList]
/// nodes.
class NodeChangeForArgumentList extends NodeChange<ArgumentList> {
  /// Map whose keys are the arguments that should be dropped from this argument
  /// list, if any.  Values are info about why the arguments are being dropped.
  final Map<Expression, AtomicEditInfo> _argumentsToDrop = {};

  NodeChangeForArgumentList() : super._();

  /// Queries the map whose keys are the arguments that should be dropped from
  /// this argument list, if any.  Values are info about why the arguments are
  /// being dropped.
  @visibleForTesting
  Map<Expression, AtomicEditInfo> get argumentsToDrop => _argumentsToDrop;

  @override
  Iterable<String> get _toStringParts =>
      [if (_argumentsToDrop.isNotEmpty) 'argumentsToDrop: $_argumentsToDrop'];

  /// Updates `this` so that the given [argument] will be dropped, using [info]
  /// to annotate the reason why it is being dropped.
  void dropArgument(Expression argument, AtomicEditInfo info) {
    assert(!_argumentsToDrop.containsKey(argument));
    _argumentsToDrop[argument] = info;
  }

  @override
  EditPlan _apply(ArgumentList node, FixAggregator aggregator) {
    assert(_argumentsToDrop.keys.every((e) => identical(e.parent, node)));
    List<EditPlan> innerPlans = [];
    for (var argument in node.arguments) {
      if (_argumentsToDrop.containsKey(argument)) {
        innerPlans.add(aggregator.planner
            .removeNode(argument, info: _argumentsToDrop[argument]));
      } else {
        innerPlans.add(aggregator.planForNode(argument));
      }
    }
    return aggregator.planner.passThrough(node, innerPlans: innerPlans);
  }
}

/// Implementation of [NodeChange] specialized for operating on [AsExpression]
/// nodes.
class NodeChangeForAsExpression extends NodeChangeForExpression<AsExpression> {
  /// Indicates whether the cast should be removed.
  bool removeAs = false;

  @override
  Iterable<String> get _toStringParts =>
      [...super._toStringParts, if (removeAs) 'removeAs'];

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
/// [AssignmentExpression] nodes.
class NodeChangeForAssignment
    extends NodeChangeForExpression<AssignmentExpression>
    with NodeChangeForAssignmentLike {
  /// Indicates whether the user should be warned that the assignment is a
  /// null-aware assignment that will have no effect when strong checking is
  /// enabled.
  bool isWeakNullAware = false;

  @override
  Iterable<String> get _toStringParts =>
      [...super._toStringParts, if (isWeakNullAware) 'isWeakNullAware'];

  @override
  NodeProducingEditPlan _apply(
      AssignmentExpression node, FixAggregator aggregator) {
    var lhsPlan = aggregator.planForNode(node.leftHandSide);
    if (isWeakNullAware && !aggregator._warnOnWeakCode) {
      // Just keep the LHS
      return aggregator.planner.extract(node, lhsPlan as NodeProducingEditPlan,
          infoAfter: AtomicEditInfo(
              NullabilityFixDescription.removeNullAwareAssignment, const {}));
    }
    var operatorPlan = _makeOperatorPlan(aggregator, node, node.operator);
    var rhsPlan = aggregator.planForNode(node.rightHandSide);
    var innerPlans = <EditPlan>[
      lhsPlan,
      if (operatorPlan != null) operatorPlan,
      rhsPlan
    ];
    return _applyExpression(aggregator,
        aggregator.planner.passThrough(node, innerPlans: innerPlans));
  }

  EditPlan _makeOperatorPlan(
      FixAggregator aggregator, AssignmentExpression node, Token operator) {
    var operatorPlan = super._makeOperatorPlan(aggregator, node, operator);
    if (operatorPlan != null) return operatorPlan;
    if (isWeakNullAware) {
      assert(aggregator._warnOnWeakCode);
      return aggregator.planner.informativeMessageForToken(node, operator,
          info: AtomicEditInfo(
              NullabilityFixDescription
                  .nullAwareAssignmentUnnecessaryInStrongMode,
              const {}));
    } else {
      return null;
    }
  }
}

/// Common behaviors for expressions that can represent an assignment (possibly
/// through desugaring).
mixin NodeChangeForAssignmentLike<N extends Expression>
    on NodeChangeForExpression<N> {
  /// Indicates whether the user should be warned that the assignment has a
  /// bad combined type (the return type of the combiner isn't assignable to the
  /// write type of the target).
  bool hasBadCombinedType = false;

  /// Indicates whether the user should be warned that the assignment has a
  /// nullable source type.
  bool hasNullableSource = false;

  @override
  Iterable<String> get _toStringParts => [
        ...super._toStringParts,
        if (hasBadCombinedType) 'hasBadCombinedType',
        if (hasNullableSource) 'hasNullableSource'
      ];

  EditPlan _makeOperatorPlan(FixAggregator aggregator, N node, Token operator) {
    if (hasNullableSource) {
      return aggregator.planner.informativeMessageForToken(node, operator,
          info: AtomicEditInfo(
              NullabilityFixDescription.compoundAssignmentHasNullableSource,
              const {}));
    } else if (hasBadCombinedType) {
      return aggregator.planner.informativeMessageForToken(node, operator,
          info: AtomicEditInfo(
              NullabilityFixDescription.compoundAssignmentHasBadCombinedType,
              const {}));
    } else {
      return null;
    }
  }
}

/// Implementation of [NodeChange] specialized for operating on
/// [CompilationUnit] nodes.
class NodeChangeForCompilationUnit extends NodeChange<CompilationUnit> {
  /// A map of the imports that should be added, or the empty map if no imports
  /// should be added.
  ///
  /// Each import is expressed as a map entry whose key is the URI to import and
  /// whose value is the set of symbols to show.
  final Map<String, Set<String>> _addImports = {};

  bool removeLanguageVersionComment = false;

  NodeChangeForCompilationUnit() : super._();

  /// Queries a map of the imports that should be added, or the empty map if no
  /// imports should be added.
  ///
  /// Each import is expressed as a map entry whose key is the URI to import and
  /// whose value is the set of symbols to show.
  @visibleForTesting
  Map<String, Set<String>> get addImports => _addImports;

  @override
  Iterable<String> get _toStringParts => [
        if (_addImports.isNotEmpty) 'addImports: $_addImports',
        if (removeLanguageVersionComment) 'removeLanguageVersionComment'
      ];

  /// Updates `this` so that an import of [uri] will be added, showing [name].
  void addImport(String uri, String name) {
    (_addImports[uri] ??= {}).add(name);
  }

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
    _processDirectives(node, aggregator, innerPlans);
    for (var declaration in node.declarations) {
      innerPlans.add(aggregator.planForNode(declaration));
    }
    return aggregator.planner.passThrough(node, innerPlans: innerPlans);
  }

  /// Adds the necessary inner plans to [innerPlans] for the directives part of
  /// [node].  This solely involves adding imports.
  void _processDirectives(CompilationUnit node, FixAggregator aggregator,
      List<EditPlan> innerPlans) {
    List<MapEntry<String, Set<String>>> importsToAdd =
        _addImports.entries.toList();
    importsToAdd.sort((x, y) => x.key.compareTo(y.key));

    void insertImport(int offset, MapEntry<String, Set<String>> importToAdd,
        {String prefix = '', String suffix = '\n'}) {
      var shownNames = importToAdd.value.toList();
      shownNames.sort();
      innerPlans.add(aggregator.planner.insertText(node, offset, [
        if (prefix.isNotEmpty) AtomicEdit.insert(prefix),
        AtomicEdit.insert(
            "import '${importToAdd.key}' show ${shownNames.join(', ')};",
            info: AtomicEditInfo(NullabilityFixDescription.addImport, {})),
        if (suffix.isNotEmpty) AtomicEdit.insert(suffix)
      ]));
    }

    if (node.directives.every((d) => d is LibraryDirective)) {
      while (importsToAdd.isNotEmpty) {
        insertImport(
            node.declarations.beginToken.offset, importsToAdd.removeAt(0),
            suffix: importsToAdd.isEmpty ? '\n\n' : '\n');
      }
    } else {
      for (var directive in node.directives) {
        while (importsToAdd.isNotEmpty &&
            _shouldImportGoBefore(importsToAdd.first.key, directive)) {
          insertImport(directive.offset, importsToAdd.removeAt(0));
        }
        innerPlans.add(aggregator.planForNode(directive));
      }
      while (importsToAdd.isNotEmpty) {
        insertImport(node.directives.last.end, importsToAdd.removeAt(0),
            prefix: '\n', suffix: '');
      }
    }
  }

  /// Determines whether a new import of [newImportUri] should be sorted before
  /// an existing [directive].
  bool _shouldImportGoBefore(String newImportUri, Directive directive) {
    if (directive is ImportDirective) {
      return newImportUri.compareTo(directive.uriContent) < 0;
    } else if (directive is LibraryDirective) {
      // Library directives must come before imports.
      return false;
    } else {
      // Everything else tends to come after imports.
      return true;
    }
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

  @override
  Iterable<String> get _toStringParts =>
      [...super._toStringParts, if (conditionValue != null) 'conditionValue'];

  /// If dead code removal is warranted for [node], returns an [EditPlan] that
  /// removes the dead code (and performs appropriate updates within any
  /// descendant AST nodes that remain).  Otherwise returns `null`.
  EditPlan _applyConditional(N node, FixAggregator aggregator,
      AstNode conditionNode, AstNode thenNode, AstNode elseNode) {
    if (conditionValue == null) return null;
    if (aggregator._warnOnWeakCode) {
      var conditionPlan = aggregator.innerPlanForNode(conditionNode);
      var info = AtomicEditInfo(
          conditionValue
              ? NullabilityFixDescription.conditionTrueInStrongMode
              : NullabilityFixDescription.conditionFalseInStrongMode,
          {FixReasonTarget.root: conditionReason});
      var commentedConditionPlan = aggregator.planner.addCommentPostfix(
          conditionPlan, '/* == $conditionValue */',
          info: info, isInformative: true);
      return aggregator.planner.passThrough(node, innerPlans: [
        commentedConditionPlan,
        aggregator.planForNode(thenNode),
        if (elseNode != null) aggregator.planForNode(elseNode)
      ]);
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

  /// If non-null, indicates a `@required` annotation which should be removed
  /// from this node.
  Annotation annotationToRemove;

  /// If [annotationToRemove] is non-null, the information that should be
  /// contained in the edit.
  AtomicEditInfo removeAnnotationInfo;

  NodeChangeForDefaultFormalParameter() : super._();

  @override
  Iterable<String> get _toStringParts =>
      [if (addRequiredKeyword) 'addRequiredKeyword'];

  @override
  EditPlan _apply(DefaultFormalParameter node, FixAggregator aggregator) {
    var innerPlan = aggregator.innerPlanForNode(node);
    if (!addRequiredKeyword) return innerPlan;

    var offset = node.firstTokenAfterCommentAndMetadata.offset;
    return aggregator.planner.passThrough(node, innerPlans: [
      aggregator.planner.insertText(node, offset, [
        AtomicEdit.insert('required ', info: addRequiredKeywordInfo),
      ]),
      if (annotationToRemove != null)
        aggregator.planner
            .removeNode(annotationToRemove, info: removeAnnotationInfo),
      ...aggregator.innerPlansForNode(node),
    ]);
  }
}

/// Implementation of [NodeChange] specialized for operating on [Expression]
/// nodes.
class NodeChangeForExpression<N extends Expression> extends NodeChange<N> {
  bool _addsNoValidMigration = false;

  AtomicEditInfo _addNoValidMigrationInfo;

  bool _addsNullCheck = false;

  AtomicEditInfo _addNullCheckInfo;

  HintComment _addNullCheckHint;

  DartType _introducesAsType;

  AtomicEditInfo _introduceAsInfo;

  NodeChangeForExpression() : super._();

  /// Gets the info for any added "no valid migration" comment.
  AtomicEditInfo get addNoValidMigrationInfo => _addNoValidMigrationInfo;

  /// Gets the info for any added null check.
  AtomicEditInfo get addNullCheckInfo => _addNullCheckInfo;

  /// Indicates whether [addNoValidMigration] has been called.
  bool get addsNoValidMigration => _addsNoValidMigration;

  /// Indicates whether [addNullCheck] has been called.
  bool get addsNullCheck => _addsNullCheck;

  /// Gets the info for any introduced "as" cast
  AtomicEditInfo get introducesAsInfo => _introduceAsInfo;

  /// Gets the type for any introduced "as" cast, or `null` if no "as" cast is
  /// being introduced.
  DartType get introducesAsType => _introducesAsType;

  @override
  Iterable<String> get _toStringParts => [
        if (_addsNoValidMigration) 'addsNoValidMigration',
        if (_addsNullCheck) 'addsNullCheck',
        if (_introducesAsType != null) 'introducesAsType'
      ];

  void addNoValidMigration(AtomicEditInfo info) {
    assert(!_addsNoValidMigration);
    _addsNoValidMigration = true;
    _addNoValidMigrationInfo = info;
  }

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
    if (_addsNoValidMigration) {
      plan = aggregator.planner.addCommentPostfix(
          plan, '/* no valid migration */',
          info: _addNoValidMigrationInfo, isInformative: true);
    }
    if (_introducesAsType != null) {
      plan = aggregator.planner.addBinaryPostfix(
          plan, TokenType.AS, aggregator.typeToCode(_introducesAsType),
          info: _introduceAsInfo);
    }
    return plan;
  }
}

/// Implementation of [NodeChange] specialized for operating on
/// [FieldFormalParameter] nodes.
class NodeChangeForFieldFormalParameter
    extends NodeChangeForType<FieldFormalParameter> {
  /// If not `null`, an explicit type annotation that should be added to the
  /// parameter.
  DartType addExplicitType;

  NodeChangeForFieldFormalParameter() : super._();

  @override
  Iterable<String> get _toStringParts =>
      [if (addExplicitType != null) 'addExplicitType'];

  @override
  EditPlan _apply(FieldFormalParameter node, FixAggregator aggregator) {
    if (addExplicitType != null) {
      var typeText = aggregator.typeToCode(addExplicitType);
      // Even a field formal parameter can use `var`, `final`.
      if (node.keyword?.keyword == Keyword.VAR) {
        // TODO(srawlins): Test instrumentation info.
        var info =
            AtomicEditInfo(NullabilityFixDescription.replaceVar(typeText), {});
        return aggregator.planner.passThrough(node, innerPlans: [
          aggregator.planner
              .replaceToken(node, node.keyword, typeText, info: info),
          ...aggregator.innerPlansForNode(node),
        ]);
      } else {
        // TODO(srawlins): Test instrumentation info.
        var info =
            AtomicEditInfo(NullabilityFixDescription.addType(typeText), {});
        var offset = node.thisKeyword.offset;
        return aggregator.planner.passThrough(node, innerPlans: [
          aggregator.planner.insertText(node, offset, [
            AtomicEdit.insert(typeText, info: info),
            AtomicEdit.insert(' ')
          ]),
          ...aggregator.innerPlansForNode(node),
        ]);
      }
    } else {
      return super._apply(node, aggregator);
    }
  }
}

/// Implementation of [NodeChange] specialized for operating on
/// [FunctionTypedFormalParameter] nodes.
class NodeChangeForFunctionTypedFormalParameter
    extends NodeChangeForType<FunctionTypedFormalParameter> {
  NodeChangeForFunctionTypedFormalParameter() : super._();
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

/// Implementation of [NodeChange] specialized for operating on
/// [SimpleIdentifier] nodes that represent a method name.
class NodeChangeForMethodName extends NodeChange<SimpleIdentifier> {
  /// The name the method name should be changed to, or `null` if no change
  /// should be made.
  String _replacement;

  /// Info object associated with the replacement.
  AtomicEditInfo _replacementInfo;

  NodeChangeForMethodName() : super._();

  /// Queries the name the method name should be changed to, or `null` if no
  /// change should be made.
  @visibleForTesting
  String get replacement => _replacement;

  /// Queries the info object associated with the replacement.
  @visibleForTesting
  AtomicEditInfo get replacementInfo => _replacementInfo;

  @override
  Iterable<String> get _toStringParts =>
      [if (replacement != null) 'replacement: $replacement'];

  /// Updates `this` so that the method name will be changed to [replacement],
  /// using [info] to annotate the reason for the change.
  void replaceWith(String replacement, AtomicEditInfo info) {
    assert(_replacement == null);
    _replacement = replacement;
    _replacementInfo = info;
  }

  @override
  EditPlan _apply(SimpleIdentifier node, FixAggregator aggregator) {
    if (replacement != null) {
      return aggregator.planner.replace(
          node, [AtomicEdit.insert(replacement, info: replacementInfo)],
          info: replacementInfo);
    } else {
      return aggregator.innerPlanForNode(node);
    }
  }
}

/// Common infrastructure used by [NodeChange] objects that operate on AST nodes
/// with that can be null-aware (method invocations and propety accesses).
mixin NodeChangeForNullAware<N extends Expression> on NodeChange<N> {
  /// Indicates whether null-awareness should be removed.
  bool removeNullAwareness = false;

  @override
  Iterable<String> get _toStringParts =>
      [...super._toStringParts, if (removeNullAwareness) 'removeNullAwareness'];

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

/// Implementation of [NodeChange] specialized for operating on
/// [PostfixExpression] nodes.
class NodeChangeForPostfixExpression
    extends NodeChangeForExpression<PostfixExpression>
    with NodeChangeForAssignmentLike {
  @override
  NodeProducingEditPlan _apply(
      PostfixExpression node, FixAggregator aggregator) {
    var operandPlan = aggregator.planForNode(node.operand);
    var operatorPlan = _makeOperatorPlan(aggregator, node, node.operator);
    var innerPlans = <EditPlan>[
      operandPlan,
      if (operatorPlan != null) operatorPlan
    ];
    return _applyExpression(aggregator,
        aggregator.planner.passThrough(node, innerPlans: innerPlans));
  }
}

/// Implementation of [NodeChange] specialized for operating on
/// [PrefixExpression] nodes.
class NodeChangeForPrefixExpression
    extends NodeChangeForExpression<PrefixExpression>
    with NodeChangeForAssignmentLike {
  @override
  NodeProducingEditPlan _apply(
      PrefixExpression node, FixAggregator aggregator) {
    var operatorPlan = _makeOperatorPlan(aggregator, node, node.operator);
    var operandPlan = aggregator.planForNode(node.operand);
    var innerPlans = <EditPlan>[
      if (operatorPlan != null) operatorPlan,
      operandPlan
    ];
    return _applyExpression(aggregator,
        aggregator.planner.passThrough(node, innerPlans: innerPlans));
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

/// Implementation of [NodeChange] specialized for operating on [ShowCombinator]
/// nodes.
class NodeChangeForShowCombinator extends NodeChange<ShowCombinator> {
  /// A set of the names that should be added, or the empty set if no names
  /// should be added.
  final Set<String> _addNames = {};

  NodeChangeForShowCombinator() : super._();

  /// Queries the set of names that should be added, or the empty set if no
  /// names should be added.
  @visibleForTesting
  Iterable<String> get addNames => _addNames;

  @override
  Iterable<String> get _toStringParts => [
        if (_addNames.isNotEmpty) 'addNames: $_addNames',
      ];

  /// Updates `this` so that [name] will be added.
  void addName(String name) {
    _addNames.add(name);
  }

  @override
  EditPlan _apply(ShowCombinator node, FixAggregator aggregator) {
    List<EditPlan> innerPlans = [];
    List<String> namesToAdd = _addNames.toList();
    namesToAdd.sort();

    void insertName(int offset, String nameToAdd,
        {String prefix = '', String suffix = ', '}) {
      innerPlans.add(aggregator.planner.insertText(node, offset, [
        if (prefix.isNotEmpty) AtomicEdit.insert(prefix),
        AtomicEdit.insert(nameToAdd),
        if (suffix.isNotEmpty) AtomicEdit.insert(suffix)
      ]));
    }

    for (var shownName in node.shownNames) {
      while (namesToAdd.isNotEmpty &&
          namesToAdd.first.compareTo(shownName.name) < 0) {
        insertName(shownName.offset, namesToAdd.removeAt(0));
      }
      innerPlans.add(aggregator.planForNode(shownName));
    }
    while (namesToAdd.isNotEmpty) {
      insertName(node.shownNames.last.end, namesToAdd.removeAt(0),
          prefix: ', ', suffix: '');
    }
    return aggregator.planner.passThrough(node, innerPlans: innerPlans);
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
  Iterable<String> get _toStringParts =>
      [if (addExplicitType != null) 'addExplicitType'];

  @override
  EditPlan _apply(SimpleFormalParameter node, FixAggregator aggregator) {
    var innerPlan = aggregator.innerPlanForNode(node);
    if (addExplicitType == null) return innerPlan;
    var typeText = aggregator.typeToCode(addExplicitType);
    if (node.keyword?.keyword == Keyword.VAR) {
      // TODO(srawlins): Test instrumentation info.
      var info =
          AtomicEditInfo(NullabilityFixDescription.replaceVar(typeText), {});
      return aggregator.planner.passThrough(node, innerPlans: [
        aggregator.planner
            .replaceToken(node, node.keyword, typeText, info: info),
        ...aggregator.innerPlansForNode(node),
      ]);
    } else {
      // TODO(srawlins): Test instrumentation info.
      var info =
          AtomicEditInfo(NullabilityFixDescription.addType(typeText), {});
      // Skip past the offset of any metadata, a potential `final` keyword, and
      // a potential `covariant` keyword.
      var offset = node.type?.offset ?? node.identifier.offset;
      return aggregator.planner.passThrough(node, innerPlans: [
        aggregator.planner.insertText(node, offset,
            [AtomicEdit.insert(typeText, info: info), AtomicEdit.insert(' ')]),
        ...aggregator.innerPlansForNode(node),
      ]);
    }
  }
}

/// Implementation of [NodeChange] specialized for operating on nodes which
/// represent a type, and can be made and hinted nullable and non-nullable.
abstract class NodeChangeForType<N extends AstNode> extends NodeChange<N> {
  bool _makeNullable = false;

  HintComment _nullabilityHint;

  /// The decorated type of the type annotation, or `null` if there is no
  /// decorated type info of interest.  If [makeNullable] is `true`, the node
  /// from this type will be attached to the edit that adds the `?`. If
  /// [_makeNullable] is `false`, the node from this type will be attached to
  /// the information about why the node wasn't made nullable.
  DecoratedType _decoratedType;

  NodeChangeForType._() : super._();

  @override
  bool get isInformative => !_makeNullable;

  /// Indicates whether the type should be made nullable by adding a `?`.
  bool get makeNullable => _makeNullable;

  /// If we are making the type nullable due to a hint, the comment that caused
  /// it.
  HintComment get nullabilityHint => _nullabilityHint;

  @override
  Iterable<String> get _toStringParts => [
        if (_makeNullable) 'makeNullable',
        if (_nullabilityHint != null) 'nullabilityHint'
      ];

  void recordNullability(DecoratedType decoratedType, bool makeNullable,
      {HintComment nullabilityHint}) {
    _decoratedType = decoratedType;
    _makeNullable = makeNullable;
    _nullabilityHint = nullabilityHint;
  }

  @override
  EditPlan _apply(N node, FixAggregator aggregator) {
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

/// Implementation of [NodeChange] specialized for operating on [TypeAnnotation]
/// nodes.
class NodeChangeForTypeAnnotation extends NodeChangeForType<TypeAnnotation> {
  NodeChangeForTypeAnnotation() : super._();
}

/// Implementation of [NodeChange] specialized for operating on
/// [VariableDeclarationList] nodes.
class NodeChangeForVariableDeclarationList
    extends NodeChange<VariableDeclarationList> {
  /// If an explicit type should be added to this variable declaration, the type
  /// that should be added.  Otherwise `null`.
  DartType addExplicitType;

  /// Indicates whether a "late" annotation should be added to this variable
  /// declaration, caused by inference.
  LateAdditionReason lateAdditionReason;

  /// If a "late" annotation should be added to this variable declaration, and
  /// the cause is a "late" hint, the hint that caused it.  Otherwise `null`.
  HintComment lateHint;

  NodeChangeForVariableDeclarationList() : super._();

  @override
  Iterable<String> get _toStringParts => [
        if (addExplicitType != null) 'addExplicitType',
        if (lateAdditionReason != null) 'lateAdditionReason',
        if (lateHint != null) 'lateHint'
      ];

  @override
  EditPlan _apply(VariableDeclarationList node, FixAggregator aggregator) {
    List<EditPlan> innerPlans = [];
    if (lateAdditionReason != null) {
      var description = lateAdditionReason == LateAdditionReason.inference
          ? NullabilityFixDescription.addLate
          : NullabilityFixDescription.addLateDueToTestSetup;
      var info = AtomicEditInfo(description, {});
      innerPlans.add(aggregator.planner.insertText(
          node,
          node.firstTokenAfterCommentAndMetadata.offset,
          [AtomicEdit.insert('late', info: info), AtomicEdit.insert(' ')]));
    }
    if (addExplicitType != null) {
      var typeText = aggregator.typeToCode(addExplicitType);
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
      var description = lateHint.kind == HintCommentKind.late_
          ? NullabilityFixDescription.addLateDueToHint
          : NullabilityFixDescription.addLateFinalDueToHint;
      plan = aggregator.planner.acceptLateHint(plan, lateHint,
          info: AtomicEditInfo(description, {}, hintComment: lateHint));
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
  NodeChange visitArgumentList(ArgumentList node) =>
      NodeChangeForArgumentList();

  @override
  NodeChange visitAsExpression(AsExpression node) =>
      NodeChangeForAsExpression();

  @override
  NodeChange visitAssignmentExpression(AssignmentExpression node) =>
      NodeChangeForAssignment();

  @override
  NodeChange visitCompilationUnit(CompilationUnit node) =>
      NodeChangeForCompilationUnit();

  @override
  NodeChange visitConditionalExpression(ConditionalExpression node) =>
      NodeChangeForConditionalExpression();

  @override
  NodeChange visitDefaultFormalParameter(DefaultFormalParameter node) =>
      NodeChangeForDefaultFormalParameter();

  @override
  NodeChange visitExpression(Expression node) => NodeChangeForExpression();

  @override
  NodeChange visitFieldFormalParameter(FieldFormalParameter node) =>
      NodeChangeForFieldFormalParameter();

  @override
  NodeChange visitFunctionTypedFormalParameter(
          FunctionTypedFormalParameter node) =>
      NodeChangeForFunctionTypedFormalParameter();

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
  NodeChange visitPostfixExpression(PostfixExpression node) =>
      NodeChangeForPostfixExpression();

  @override
  NodeChange visitPrefixExpression(PrefixExpression node) =>
      NodeChangeForPrefixExpression();

  @override
  NodeChange visitPropertyAccess(PropertyAccess node) =>
      NodeChangeForPropertyAccess();

  @override
  NodeChange visitShowCombinator(ShowCombinator node) =>
      NodeChangeForShowCombinator();

  @override
  NodeChange visitSimpleFormalParameter(SimpleFormalParameter node) =>
      NodeChangeForSimpleFormalParameter();

  @override
  NodeChange visitSimpleIdentifier(SimpleIdentifier node) {
    var parent = node.parent;
    if (parent is MethodInvocation && identical(node, parent.methodName)) {
      return NodeChangeForMethodName();
    } else {
      return super.visitSimpleIdentifier(node);
    }
  }

  @override
  NodeChange visitTypeName(TypeName node) => NodeChangeForTypeAnnotation();

  @override
  NodeChange visitVariableDeclarationList(VariableDeclarationList node) =>
      NodeChangeForVariableDeclarationList();
}
