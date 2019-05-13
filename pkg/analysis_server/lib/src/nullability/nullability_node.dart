// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/nullability/nullability_graph.dart';
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
      _NullabilityNodeImmutable('always', true);

  /// [NullabilityNode] used for types that are known a priori to be
  /// non-nullable (e.g. the type of an integer literal).
  static final NullabilityNode never =
      _NullabilityNodeImmutable('never', false);

  static final _debugNamesInUse = Set<String>();

  bool _isPossiblyOptional = false;

  String _debugName;

  /// Creates a [NullabilityNode] representing the nullability of a variable
  /// whose type is `dynamic` due to type inference.
  ///
  /// TODO(paulberry): this should go away; we should decorate the actual
  /// inferred type rather than assuming `dynamic`.
  factory NullabilityNode.forInferredDynamicType(
      NullabilityGraph graph, int offset) {
    var node = _NullabilityNodeSimple('inferredDynamic($offset)');
    graph.connect(NullabilityNode.always, node, unconditional: true);
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
      NullabilityGraph graph) = NullabilityNodeForLUB._;

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
          NullabilityNode innerNode, NullabilityNode outerNode) =
      NullabilityNodeForSubstitution._;

  /// Creates a [NullabilityNode] representing the nullability of a type
  /// annotation appearing explicitly in the user's program.
  factory NullabilityNode.forTypeAnnotation(int endOffset,
          {@required bool always}) =>
      _NullabilityNodeSimple('type($endOffset)');

  NullabilityNode._();

  /// Gets a string that can be appended to a type name during debugging to help
  /// annotate the nullability of that type.
  String get debugSuffix =>
      this == always ? '?' : this == never ? '' : '?($this)';

  /// After nullability propagation, this getter can be used to query whether
  /// the type associated with this node should be considered nullable.
  bool get isNullable;

  /// Indicates whether this node is associated with a named parameter for which
  /// nullability migration needs to decide whether it is optional or required.
  bool get isPossiblyOptional => _isPossiblyOptional;

  String get _debugPrefix;

  /// Records the fact that an invocation was made to a function with named
  /// parameters, and the named parameter associated with this node was not
  /// supplied.
  void recordNamedParameterNotSupplied(
      List<NullabilityNode> guards, NullabilityGraph graph) {
    if (isPossiblyOptional) {
      graph.connect(NullabilityNode.always, this, guards: guards);
    }
  }

  void recordNonNullIntent(
      List<NullabilityNode> guards, NullabilityGraph graph) {
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
      List<NullabilityNode> guards,
      NullabilityGraph graph,
      bool inConditionalControlFlow) {
    graph.connect(sourceNode, destinationNode,
        guards: guards, unconditional: !inConditionalControlFlow);
  }
}

/// Derived class for nullability nodes that arise from the least-upper-bound
/// implied by a conditional expression.
class NullabilityNodeForLUB extends NullabilityNodeMutable {
  final NullabilityNode left;

  final NullabilityNode right;

  NullabilityNodeForLUB._(
      Expression expression, this.left, this.right, NullabilityGraph graph)
      : super._() {
    graph.connect(left, this);
    graph.connect(right, this);
  }

  @override
  String get _debugPrefix => 'LUB($left, $right)';
}

/// Derived class for nullability nodes that arise from type variable
/// substitution.
class NullabilityNodeForSubstitution extends NullabilityNodeMutable {
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

  NullabilityNodeForSubstitution._(this.innerNode, this.outerNode) : super._();

  @override
  String get _debugPrefix => 'Substituted($innerNode, $outerNode)';
}

/// Base class for nullability nodes whose state can be mutated safely.
///
/// Nearly all nullability nodes derive from this class; the only exceptions are
/// the fixed nodes [NullabilityNode.always] and [NullabilityNode.never].
abstract class NullabilityNodeMutable extends NullabilityNode {
  bool _isNullable = false;

  NullabilityNodeMutable._() : super._();

  @override
  bool get isNullable => _isNullable;

  /// During constraint solving, this method marks the type as nullable, or does
  /// nothing if the type was already nullable.
  ///
  /// Return value indicates whether a change was made.
  bool becomeNullable() {
    if (_isNullable) return false;
    _isNullable = true;
    return true;
  }
}

class _NullabilityNodeImmutable extends NullabilityNode {
  @override
  final String _debugPrefix;

  @override
  final bool isNullable;

  _NullabilityNodeImmutable(this._debugPrefix, this.isNullable) : super._();
}

class _NullabilityNodeSimple extends NullabilityNodeMutable {
  @override
  final String _debugPrefix;

  _NullabilityNodeSimple(this._debugPrefix) : super._();
}
