// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/nullability/decorated_type.dart';
import 'package:analysis_server/src/nullability/nullability_graph.dart';
import 'package:analysis_server/src/nullability/transitional_api.dart';
import 'package:analysis_server/src/nullability/unit_propagation.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:meta/meta.dart';

/// Representation of a single node in the nullability inference graph.
///
/// Initially, this is just a wrapper over constraint variables, and the
/// nullability inference graph is encoded into the wrapped constraint
/// variables.  Over time this will be replaced by a first class representation
/// of the nullability inference graph.
abstract class NullabilityNode {
  /// [NullabilityNode] used for types that are known a priori to be nullable
  /// (e.g. the type of the `null` literal).
  static final NullabilityNode always =
      _NullabilityNodeSimple(ConstraintVariable.always, 'always');

  /// [NullabilityNode] used for types that are known a priori to be
  /// non-nullable (e.g. the type of an integer literal).
  static final NullabilityNode never = _NullabilityNodeSimple(null, 'never');

  static final _debugNamesInUse = Set<String>();

  /// [ConstraintVariable] whose value will be set to `true` if this type needs
  /// to be nullable.
  ///
  /// If `null`, that means that an external constraint (outside the code being
  /// migrated) forces this type to be non-nullable.
  final ConstraintVariable _nullable;

  ConstraintVariable _nonNullIntent;

  bool _isPossiblyOptional = false;

  String _debugName;

  /// Creates a [NullabilityNode] representing the nullability of a variable
  /// whose type is `dynamic` due to type inference.
  ///
  /// TODO(paulberry): this should go away; we should decorate the actual
  /// inferred type rather than assuming `dynamic`.
  factory NullabilityNode.forInferredDynamicType(
      NullabilityGraph graph, Constraints constraints, int offset) {
    var node = _NullabilityNodeSimple(
        TypeIsNullable(null), 'inferredDynamic($offset)');
    constraints.record([], node._nullable);
    graph.connect(NullabilityNode.always, node);
    return node;
  }

  /// Creates a [NullabilityNode] representing the nullability of an
  /// expression which is nullable iff both [a] and [b] are nullable.
  ///
  /// The constraint variable contained in the new node is created using the
  /// [joinNullabilities] callback.  TODO(paulberry): this should become
  /// unnecessary once constraint solving is performed directly using
  /// [NullabilityNode] objects.
  factory NullabilityNode.forLUB(
      Expression conditionalExpression,
      NullabilityNode a,
      NullabilityNode b,
      NullabilityGraph graph,
      ConstraintVariable Function(
              Expression, ConstraintVariable, ConstraintVariable)
          joinNullabilities) = NullabilityNodeForLUB._;

  /// Creates a [NullabilityNode] representing the nullability of a type
  /// substitution where [outerNode] is the nullability node for the type
  /// variable being eliminated by the substitution, and [innerNode] is the
  /// nullability node for the type being substituted in its place.
  ///
  /// [innerNode] may be `null`.  TODO(paulberry): when?
  ///
  /// Additional constraints are recorded in [constraints] as necessary to make
  /// the new nullability node behave consistently with the old nodes.
  /// TODO(paulberry): this should become unnecessary once constraint solving is
  /// performed directly using [NullabilityNode] objects.
  factory NullabilityNode.forSubstitution(
      Constraints constraints,
      NullabilityNode innerNode,
      NullabilityNode outerNode) = NullabilityNodeForSubstitution._;

  /// Creates a [NullabilityNode] representing the nullability of a type
  /// annotation appearing explicitly in the user's program.
  factory NullabilityNode.forTypeAnnotation(int endOffset,
          {@required bool always}) =>
      _NullabilityNodeSimple(
          always ? ConstraintVariable.always : TypeIsNullable(endOffset),
          'type($endOffset)');

  NullabilityNode._(this._nullable);

  /// Gets a string that can be appended to a type name during debugging to help
  /// annotate the nullability of that type.
  String get debugSuffix => _nullable == null ? '' : '?($_nullable)';

  /// After constraint solving, this getter can be used to query whether the
  /// type associated with this node should be considered nullable.
  bool get isNullable => _nullable == null ? false : _nullable.value;

  /// Indicates whether this node is associated with a named parameter for which
  /// nullability migration needs to decide whether it is optional or required.
  bool get isPossiblyOptional => _isPossiblyOptional;

  /// [ConstraintVariable] whose value will be set to `true` if the usage of
  /// this type suggests that it is intended to be non-null (because of the
  /// presence of a statement or expression that would unconditionally lead to
  /// an exception being thrown in the case of a `null` value at runtime).
  ConstraintVariable get nonNullIntent => _nonNullIntent;

  String get _debugPrefix;

  /// Records the fact that an invocation was made to a function with named
  /// parameters, and the named parameter associated with this node was not
  /// supplied.
  void recordNamedParameterNotSupplied(
      Constraints constraints, List<NullabilityNode> guards) {
    if (isPossiblyOptional) {
      _recordConstraints(constraints, guards, const [], _nullable);
    }
  }

  void recordNonNullIntent(Constraints constraints,
      List<NullabilityNode> guards, NullabilityGraph graph) {
    _recordConstraints(constraints, guards, const [], nonNullIntent);
    graph.connect(this, NullabilityNode.never, unconditional: true);
  }

  String toString() {
    if (_debugName == null) {
      var prefix = _debugPrefix;
      if (_debugNamesInUse.add(prefix)) {
        _debugName = prefix;
      } else {
        for (int i = 0;; i++) {
          var name = '${prefix}_$i';
          if (_debugNamesInUse.add(name)) {
            _debugName = name;
            break;
          }
        }
      }
    }
    return _debugName;
  }

  /// Tracks that the possibility that this nullability node might demonstrate
  /// non-null intent, based on the fact that it corresponds to a formal
  /// parameter declaration at location [offset].
  ///
  /// TODO(paulberry): consider eliminating this method altogether, and simply
  /// allowing all nullability nodes to track non-null intent if necessary.
  void trackNonNullIntent(int offset) {
    assert(_nonNullIntent == null);
    _nonNullIntent = NonNullIntent(offset);
  }

  /// Tracks the possibility that this node is associated with a named parameter
  /// for which nullability migration needs to decide whether it is optional or
  /// required.
  void trackPossiblyOptional() {
    _isPossiblyOptional = true;
  }

  /// Connect the nullability nodes [sourceNode] and [destinationNode]
  /// appopriately to account for an assignment in the source code being
  /// analyzed.  Any constraints generated are recorded in [constraints].
  ///
  /// If [checkNotNull] is non-null, then it tracks the expression that may
  /// require null-checking.
  ///
  /// [inConditionalControlFlow] indicates whether the assignment being analyzed
  /// is reachable conditionally or unconditionally from the entry point of the
  /// function; this affects how non-null intent is back-propagated.
  static void recordAssignment(
      NullabilityNode sourceNode,
      NullabilityNode destinationNode,
      CheckExpression checkNotNull,
      List<NullabilityNode> guards,
      Constraints constraints,
      NullabilityGraph graph,
      bool inConditionalControlFlow) {
    var additionalConditions = <ConstraintVariable>[];
    graph.connect(sourceNode, destinationNode,
        unconditional: !inConditionalControlFlow);
    if (sourceNode._nullable != null) {
      additionalConditions.add(sourceNode._nullable);
      var destinationNonNullIntent = destinationNode.nonNullIntent;
      // nullable_src => nullable_dst | check_expr
      _recordConstraints(
          constraints,
          guards,
          additionalConditions,
          ConstraintVariable.or(
              constraints, destinationNode._nullable, checkNotNull));
      if (checkNotNull != null) {
        // nullable_src & nonNullIntent_dst => check_expr
        if (destinationNonNullIntent != null) {
          additionalConditions.add(destinationNonNullIntent);
          _recordConstraints(
              constraints, guards, additionalConditions, checkNotNull);
        }
      }
      additionalConditions.clear();
      var sourceNonNullIntent = sourceNode.nonNullIntent;
      if (!inConditionalControlFlow && sourceNonNullIntent != null) {
        if (destinationNode._nullable == null) {
          // The destination type can never be nullable so this demonstrates
          // non-null intent.
          _recordConstraints(
              constraints, guards, additionalConditions, sourceNonNullIntent);
        } else if (destinationNonNullIntent != null) {
          // Propagate non-null intent from the destination to the source.
          additionalConditions.add(destinationNonNullIntent);
          _recordConstraints(
              constraints, guards, additionalConditions, sourceNonNullIntent);
        }
      }
    }
  }

  static void _recordConstraints(
      Constraints constraints,
      List<NullabilityNode> guards,
      List<ConstraintVariable> additionalConditions,
      ConstraintVariable consequence) {
    var conditions = guards.map((node) => node._nullable).toList();
    conditions.addAll(additionalConditions);
    constraints.record(conditions, consequence);
  }
}

/// Derived class for nullability nodes that arise from the least-upper-bound
/// implied by a conditional expression.
class NullabilityNodeForLUB extends NullabilityNode {
  final NullabilityNode left;

  final NullabilityNode right;

  NullabilityNodeForLUB._(
      Expression expression,
      this.left,
      this.right,
      NullabilityGraph graph,
      ConstraintVariable Function(
              ConditionalExpression, ConstraintVariable, ConstraintVariable)
          joinNullabilities)
      : super._(
            joinNullabilities(expression, left._nullable, right._nullable)) {
    graph.connect(left, this);
    graph.connect(right, this);
  }

  @override
  String get _debugPrefix => 'LUB($left, $right)';
}

/// Derived class for nullability nodes that arise from type variable
/// substitution.
class NullabilityNodeForSubstitution extends NullabilityNode {
  /// Nullability node representing the inner type of the substitution.
  ///
  /// For example, if this NullabilityNode arose from substituting `int*` for
  /// `T` in the type `T*`, [innerNode] is the nullability corresponding to the
  /// `*` in `int*`.
  final NullabilityNode innerNode;

  /// Nullability node representing the outer type of the substitution.
  ///
  /// For example, if this NullabilityNode arose from substituting `int*` for
  /// `T` in the type `T*`, [innerNode] is the nullability corresponding to the
  /// `*` in `T*`.
  final NullabilityNode outerNode;

  NullabilityNodeForSubstitution._(
      Constraints constraints, this.innerNode, this.outerNode)
      : super._(ConstraintVariable.or(
            constraints, innerNode?._nullable, outerNode._nullable));

  @override
  String get _debugPrefix => 'Substituted($innerNode, $outerNode)';
}

class _NullabilityNodeSimple extends NullabilityNode {
  @override
  final String _debugPrefix;

  _NullabilityNodeSimple(ConstraintVariable nullable, this._debugPrefix)
      : super._(nullable);
}
