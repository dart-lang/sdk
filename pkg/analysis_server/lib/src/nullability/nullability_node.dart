// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/nullability/decorated_type.dart';
import 'package:analysis_server/src/nullability/unit_propagation.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:meta/meta.dart';

/// Representation of a single node in the nullability inference graph.
///
/// Initially, this is just a wrapper over constraint variables, and the
/// nullability inference graph is encoded into the wrapped constraint
/// variables.  Over time this will be replaced by a first class representation
/// of the nullability inference graph.
class NullabilityNode {
  /// [NullabilityNode] used for types that are known a priori to be nullable
  /// (e.g. the type of the `null` literal).
  static final always = NullabilityNode._(ConstraintVariable.always);

  /// [NullabilityNode] used for types that are known a priori to be
  /// non-nullable (e.g. the type of an integer literal).
  static final never = NullabilityNode._(null);

  /// [ConstraintVariable] whose value will be set to `true` if this type needs
  /// to be nullable.
  ///
  /// If `null`, that means that an external constraint (outside the code being
  /// migrated) forces this type to be non-nullable.
  final ConstraintVariable nullable;

  ConstraintVariable _nonNullIntent;

  /// Creates a [NullabilityNode] representing the nullability of a conditional
  /// expression which is nullable iff both [a] and [b] are nullable.
  ///
  /// The constraint variable contained in the new node is created using the
  /// [joinNullabilities] callback.  TODO(paulberry): this should become
  /// unnecessary once constraint solving is performed directly using
  /// [NullabilityNode] objects.
  NullabilityNode.forConditionalexpression(
      ConditionalExpression conditionalExpression,
      NullabilityNode a,
      NullabilityNode b,
      ConstraintVariable Function(
              ConditionalExpression, ConstraintVariable, ConstraintVariable)
          joinNullabilities)
      : this._(
            joinNullabilities(conditionalExpression, a.nullable, b.nullable));

  /// Creates a [NullabilityNode] representing the nullability of a variable
  /// whose type is `dynamic` due to type inference.
  ///
  /// TODO(paulberry): this should go away; we should decorate the actual
  /// inferred type rather than assuming `dynamic`.
  NullabilityNode.forInferredDynamicType() : this._(ConstraintVariable.always);

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
  NullabilityNode.forSubstitution(Constraints constraints,
      NullabilityNode innerNode, NullabilityNode outerNode)
      : this._(ConstraintVariable.or(
            constraints, innerNode?.nullable, outerNode.nullable));

  /// Creates a [NullabilityNode] representing the nullability of a type
  /// annotation appearing explicitly in the user's program.
  NullabilityNode.forTypeAnnotation(int endOffset, {@required bool always})
      : this._(always ? ConstraintVariable.always : TypeIsNullable(endOffset));

  NullabilityNode._(this.nullable);

  /// [ConstraintVariable] whose value will be set to `true` if the usage of
  /// this type suggests that it is intended to be non-null (because of the
  /// presence of a statement or expression that would unconditionally lead to
  /// an exception being thrown in the case of a `null` value at runtime).
  ConstraintVariable get nonNullIntent => _nonNullIntent;

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
}
