// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:nnbd_migration/src/edit_plan.dart';

/// Data structure used by the nullability migration engine to refer to a
/// specific location in source code.
class CodeReference {
  final String path;

  final int line;

  final int column;

  CodeReference(this.path, this.line, this.column);

  CodeReference.fromJson(dynamic json)
      : path = json['path'] as String,
        line = json['line'] as int,
        column = json['col'] as int;

  Map<String, Object> toJson() {
    return {'path': path, 'line': line, 'col': column};
  }

  @override
  String toString() {
    var pathAsUri = Uri.file(path);
    return 'unknown ($pathAsUri:$line:$column)';
  }
}

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

  /// Indicates whether the downstream node of this edge is non-nullable and the
  /// edge is hard (and thus upstream nullability propagation should try to make
  /// the source node non-nullable, if possible).
  bool get isUpstreamTriggered;

  /// Information about the graph node that this edge "points away from".
  NullabilityNodeInfo get sourceNode;
}

/// Information exposed to the migration client about the location in source
/// code that led an edge to be introduced into the nullability graph.
abstract class EdgeOriginInfo {
  /// If the proximate cause of the edge being introduced into the graph
  /// corresponds to the type of an element in an already migrated-library, the
  /// corresponding element; otherwise `null`.
  ///
  /// Note that either [node] or [element] will always be non-null.
  Element get element;

  /// The kind of origin represented by this info.
  EdgeOriginKind get kind;

  /// If the proximate cause of the edge being introduced into the graph
  /// corresponds to an AST node in a source file that is being migrated, the
  /// corresponding AST node; otherwise `null`.
  ///
  /// Note that either [node] or [element] will always be non-null.
  AstNode get node;

  /// If [node] is non-null, the source file that it appears in.  Otherwise
  /// `null`.
  Source get source;
}

/// An enumeration of the various kinds of edge origins created by the migration
/// engine.
enum EdgeOriginKind {
  alreadyMigratedType,
  alwaysNullableType,
  compoundAssignment,
  defaultValue,
  dynamicAssignment,
  enumValue,
  expressionChecks,
  fieldFormalParameter,
  fieldNotInitialized,
  forEachVariable,
  greatestLowerBound,
  ifNull,
  implicitMixinSuperCall,
  implicitNullInitializer,
  implicitNullReturn,
  inferredTypeParameterInstantiation,
  initializerInference,
  instanceCreation,
  instantiateToBounds,
  isCheckComponentType,
  isCheckMainType,
  literal,
  listLengthConstructor,
  namedParameterNotSupplied,
  nonNullableBoolType,
  nonNullableObjectSuperclass,
  nonNullableUsage,
  nonNullAssertion,
  nullabilityComment,
  optionalFormalParameter,
  parameterInheritance,
  returnTypeInheritance,
  stackTraceTypeOrigin,
  thisOrSuper,
  throw_,
  typedefReference,
  typeParameterInstantiation,
  uninitializedRead,
}

/// Interface used by the migration engine to expose information to its client
/// about a reason for a modification to the source file.
abstract class FixReasonInfo {}

/// Interface used by the migration engine to expose information to its client
/// about the decisions made during migration, and how those decisions relate to
/// the input source code.
abstract class NullabilityMigrationInstrumentation {
  /// Called whenever changes are decided upon for a given [source] file.
  ///
  /// The format of the changes is a map from source file offset to a list of
  /// changes to be applied at that offset.
  void changes(Source source, Map<int, List<AtomicEdit>> changes);

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

  /// Called whenever reference is made to an [typeParameter] outside of the
  /// code being migrated, to report the nullability nodes associated with the
  /// bound of the type parameter.
  void externalDecoratedTypeParameterBound(
      TypeParameterElement typeParameter, DecoratedTypeInfo decoratedType);

  /// Called whenever the migration engine creates a graph edge between
  /// nullability nodes, to report information about the edge that was created,
  /// and why it was created.
  void graphEdge(EdgeInfo edge, EdgeOriginInfo originInfo);

  /// Called when the migration engine starts up, to report information about
  /// the immutable migration nodes [never] and [always] that are used as the
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

  /// Clear any data from the propagation step in preparation for that step
  /// being re-run.
  void prepareForUpdate();
}

/// Information exposed to the migration client about a single node in the
/// nullability graph.
abstract class NullabilityNodeInfo implements FixReasonInfo {
  /// List of compound nodes wrapping this node.
  final List<NullabilityNodeInfo> outerCompoundNodes = <NullabilityNodeInfo>[];

  /// Some nodes get nullability from downstream, so the downstream edges are
  /// available to query as well.
  Iterable<EdgeInfo> get downstreamEdges;

  /// After migration is complete, this getter can be used to query whether
  /// the type associated with this node was determined to be "exact nullable."
  bool get isExactNullable;

  /// Indicates whether the node is immutable.  The only immutable nodes in the
  /// nullability graph are the nodes `never` and `always` that are used as the
  /// starting points for nullability propagation.
  bool get isImmutable;

  /// After migration is complete, this getter can be used to query whether
  /// the type associated with this node was determined to be nullable.
  bool get isNullable;

  /// The edges that caused this node to have the nullability that it has.
  Iterable<EdgeInfo> get upstreamEdges;

  PropagationStepInfo get whyNullable;
}

abstract class PropagationStepInfo {
  CodeReference get codeReference;

  PropagationStepInfo get principalCause;
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
