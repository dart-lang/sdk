// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/nullability_state.dart';

/// Information exposed to the migration client about the set of nullability
/// nodes decorating a type in the program being migrated.
abstract class DecoratedTypeInfo {
  /// Information about the graph node associated with the decision of whether
  /// or not to make this type into a nullable type.
  NullabilityNodeInfo get node;

  /// If [type] is a function type, information about the set of nullability
  /// nodes decorating the type's return type.
  DecoratedTypeInfo get returnType;

  /// The original (pre-migration) type that is being migrated.
  DartType get type;

  /// If [type] is a function type, looks up information about the set of
  /// nullability nodes decorating one of the type's named parameter types.
  DecoratedTypeInfo namedParameter(String name);

  /// If [type] is a function type, looks up information about the set of
  /// nullability nodes decorating one of the type's positional parameter types.
  /// (This could be an optional or a required positional parameter).
  DecoratedTypeInfo positionalParameter(int i);

  /// If [type] is an interface type, looks up information about the set of
  /// nullability nodes decorating one of the type's type arguments.
  DecoratedTypeInfo typeArgument(int i);
}

/// Information exposed to the migration client about an edge in the nullability
/// graph.
///
/// A graph edge represents a dependency relationship between two types being
/// migrated, suggesting that if one type (the source) is made nullable, it may
/// be desirable to make the other type (the destination) nullable as well.
abstract class EdgeInfo implements FixReasonInfo {
  /// Information about the graph node that this edge "points to".
  NullabilityNodeInfo get destinationNode;

  /// The set of "guard nodes" for this edge.  Guard nodes are graph nodes whose
  /// nullability determines whether it is important to satisfy a graph edge.
  /// If at least one of an edge's guards is non-nullable, then it is not
  /// important to satisfy the graph edge.  (Typically this is because the code
  /// that led to the graph edge being created is only reachable if the guards
  /// are all nullable).
  Iterable<NullabilityNodeInfo> get guards;

  /// A boolean indicating whether the graph edge is a "hard" edge.  Hard edges
  /// are associated with unconditional control flow, and thus allow information
  /// about non-nullability to be propagated "upstream" through the nullability
  /// graph.
  bool get isHard;

  /// A boolean indicating whether the graph edge is "satisfied".  At its heart,
  /// the nullability propagation algorithm is an effort to satisfy graph edges
  /// in a way that corresponds to the user's intent.  A graph edge is
  /// considered satisfied if any of the following is true:
  /// - Its [sourceNode] is non-nullable.
  /// - One of its [guards] is non-nullable.
  /// - Its [destinationNode] is nullable.
  bool get isSatisfied;

  /// Indicates whether all the upstream nodes of this edge are nullable (and
  /// thus downstream nullability propagation should try to make the destination
  /// node nullable, if possible).
  bool get isTriggered;

  /// A boolean indicating whether the graph edge is a "union" edge.  Union
  /// edges are edges for which the nullability propagation algorithm tries to
  /// ensure that both the [sourceNode] and the [destinationNode] have the
  /// same nullability.  Typically these are associated with situations where
  /// Dart language semantics require two types to be the same type (e.g. a type
  /// formal bound on a generic function type in a base class, and the
  /// corresponding type formal bound on a generic function type in an
  /// overriding class).
  ///
  /// The [isHard] property is always true for union edges.
  bool get isUnion;

  /// Information about the graph node that this edge "points away from".
  NullabilityNodeInfo get sourceNode;
}

/// Information exposed to the migration client about the location in source
/// code that led an edge to be introduced into the nullability graph.
abstract class EdgeOriginInfo {
  /// The AST node that led the edge to be introduced into the nullability
  /// graph.
  AstNode get node;

  /// The source file that [node] appears in.
  Source get source;
}

/// Interface used by the migration engine to expose information to its client
/// about a reason for a modification to the source file.
abstract class FixReasonInfo {}

/// Interface used by the migration engine to expose information to its client
/// about the decisions made during migration, and how those decisions relate to
/// the input source code.
abstract class NullabilityMigrationInstrumentation {
  /// Called whenever an explicit [typeAnnotation] is found in the source code,
  /// to report the nullability [node] that was associated with this type.  If
  /// the migration engine determines that the [node] should be nullable, a `?`
  /// will be inserted after the type annotation.
  void explicitTypeNullability(
      Source source, TypeAnnotation typeAnnotation, NullabilityNodeInfo node);

  /// Called whenever reference is made to an [element] outside of the code
  /// being migrated, to report the nullability nodes associated with the type
  /// of the element.
  void externalDecoratedType(Element element, DecoratedTypeInfo decoratedType);

  /// Called whenever a fix is decided upon, to report the reasons for the fix.
  void fix(SingleNullabilityFix fix, Iterable<FixReasonInfo> reasons);

  /// Called whenever the migration engine creates a graph edge between
  /// nullability nodes, to report information about the edge that was created,
  /// and why it was created.
  void graphEdge(EdgeInfo edge, EdgeOriginInfo originInfo);

  /// Called when the migration engine start up, to report information about the
  /// immutable migration nodes [never] and [always] that are used as the
  /// starting point for nullability propagation.
  void immutableNodes(NullabilityNodeInfo never, NullabilityNodeInfo always);

  /// Called whenever the migration engine encounters an implicit return type
  /// associated with an AST node, to report the nullability nodes associated
  /// with the implicit return type of the AST node.
  ///
  /// [node] is the AST node having an implicit return type; it may be an
  /// executable declaration, function-typed formal parameter declaration,
  /// function type alias declaration, GenericFunctionType, or a function
  /// expression.
  void implicitReturnType(
      Source source, AstNode node, DecoratedTypeInfo decoratedReturnType);

  /// Called whenever the migration engine encounters an implicit type
  /// associated with an AST node, to report the nullability nodes associated
  /// with the implicit type of the AST node.
  ///
  /// [node] is the AST node having an implicit type; it may be a formal
  /// parameter, a declared identifier, or a variable in a variable declaration
  /// list.
  void implicitType(
      Source source, AstNode node, DecoratedTypeInfo decoratedType);

  /// Called whenever the migration engine encounters an AST node with implicit
  /// type arguments, to report the nullability nodes associated with the
  /// implicit type arguments of the AST node.
  ///
  /// [node] is the AST node having implicit type arguments; it may be a
  /// constructor redirection, function expression invocation, method
  /// invocation, instance creation expression, list/map/set literal, or type
  /// annotation.
  void implicitTypeArguments(
      Source source, AstNode node, Iterable<DecoratedTypeInfo> types);

  /// Called whenever the migration engine performs a step in the propagation of
  /// nullability information through the nullability graph, to report details
  /// of the step that was performed and why.
  void propagationStep(PropagationInfo info);
}

/// Information exposed to the migration client about a single node in the
/// nullability graph.
abstract class NullabilityNodeInfo implements FixReasonInfo {
  /// Indicates whether the node is immutable.  The only immutable nodes in the
  /// nullability graph are the nodes `never` and `always` that are used as the
  /// starting points for nullability propagation.
  bool get isImmutable;

  /// After migration is complete, this getter can be used to query whether
  /// the type associated with this node was determined to be nullable.
  bool get isNullable;

  /// The edges that caused this node to have the nullability that it has.
  Iterable<EdgeInfo> get upstreamEdges;
}

/// Information exposed to the migration client about a single step in the
/// nullability propagation algorithm, in which the nullability state of a
/// single node was changed.
abstract class PropagationInfo {
  /// The edge that caused the nullability state of [node] to be set to
  /// [newState], or `null` if the nullability state was changed for reasons
  /// not associated with an edge.  Will be `null` when [reason] is
  /// [StateChangeReason.substituteInner] or
  /// [StateChangeReason.substituteOuter], non-null otherwise.
  EdgeInfo get edge;

  /// The new state that [node] was placed into.
  NullabilityState get newState;

  /// The nullability node whose state was changed.
  NullabilityNodeInfo get node;

  /// The reason the nullability node's state was changed.
  StateChangeReason get reason;

  /// The substitution node that caused the nullability state of [node] to be
  /// set to [newState], or `null` if the nullability state was changed for
  /// reasons not associated with a substitution node.  Will be non-null when
  /// [reason] is [StateChangeReason.substituteInner] or
  /// [StateChangeReason.substituteOuter], `null` otherwise.
  SubstitutionNodeInfo get substitutionNode;
}

/// Enum representing the various reasons why a nullability node might change
/// state during nullability propagation.
enum StateChangeReason {
  /// A union edge exists between this node and a node that is known a priori to
  /// be nullable, so this node is being made nullable as well.
  union,

  /// A hard or union edge exists whose source is this node, and whose
  /// destination is non-nullable, so this node is being made non-nullable as
  /// well.
  upstream,

  /// An edge exists whose destination is this node, and whose source is
  /// nullable, so this node is being made nullable as well.
  downstream,

  /// An edge exists whose source is this node, and whose destination is exact
  /// nullable, so this node is being made exact nullable as well.
  exactUpstream,

  /// A substitution node exists whose inner node points to this node, and the
  /// substitution node is nullable, so this node is being made nullable as
  /// well.
  substituteInner,

  /// A substitution node exists whose outer node points to this node, and the
  /// substitution node is nullable, so this node is being made nullable as
  /// well.
  substituteOuter,
}

/// Information exposed to the migration client about a node in the nullability
/// graph resulting from a type substitution.
abstract class SubstitutionNodeInfo extends NullabilityNodeInfo {
  /// Nullability node representing the inner type of the substitution.
  ///
  /// For example, if this NullabilityNode arose from substituting `int*` for
  /// `T` in the type `T*`, [innerNode] is the nullability corresponding to the
  /// `*` in `int*`.
  NullabilityNodeInfo get innerNode;

  /// Nullability node representing the outer type of the substitution.
  ///
  /// For example, if this NullabilityNode arose from substituting `int*` for
  /// `T` in the type `T*`, [innerNode] is the nullability corresponding to the
  /// `*` in `T*`.
  NullabilityNodeInfo get outerNode;
}
