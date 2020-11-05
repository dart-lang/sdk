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

  final int offset;

  /// Name of the enclosing function, or `null` if not known.
  String function;

  CodeReference(this.path, this.offset, this.line, this.column, this.function);

  /// Creates a [CodeReference] pointing to the given [node].
  factory CodeReference.fromAstNode(AstNode node) {
    var compilationUnit = node.thisOrAncestorOfType<CompilationUnit>();
    var source = compilationUnit.declaredElement.source;
    var location = compilationUnit.lineInfo.getLocation(node.offset);
    return CodeReference(source.fullName, node.offset, location.lineNumber,
        location.columnNumber, _computeEnclosingName(node));
  }

  factory CodeReference.fromElement(
      Element element, LineInfo Function(String) getLineInfo) {
    var path = element.source.fullName;
    var offset = element.nameOffset;
    var location = getLineInfo(path).getLocation(offset);
    return CodeReference(path, offset, location.lineNumber,
        location.columnNumber, _computeElementFullName(element));
  }

  CodeReference.fromJson(dynamic json)
      : path = json['path'] as String,
        offset = json['offset'] as int,
        line = json['line'] as int,
        column = json['col'] as int,
        function = json['function'] as String;

  /// Gets a short description of this code reference (using the last component
  /// of the path rather than the full path)
  String get shortName => '$shortPath:$line:$column';

  /// Gets the last component of the path part of this code reference.
  String get shortPath {
    var pathAsUri = Uri.file(path);
    return pathAsUri.pathSegments.last;
  }

  Map<String, Object> toJson() {
    return {
      'path': path,
      'offset': offset,
      'line': line,
      'col': column,
      if (function != null) 'function': function
    };
  }

  @override
  String toString() {
    var pathAsUri = Uri.file(path);
    return '${function ?? 'unknown'} ($pathAsUri:$line:$column)';
  }

  static String _computeElementFullName(Element element) {
    List<String> parts = [];
    while (element != null) {
      var elementName = _computeElementName(element);
      if (elementName != null) {
        parts.add(elementName);
      }
      element = element.enclosingElement;
    }
    if (parts.isEmpty) return null;
    return parts.reversed.join('.');
  }

  static String _computeElementName(Element element) {
    if (element is CompilationUnitElement || element is LibraryElement) {
      return null;
    }
    return element.name;
  }

  static String _computeEnclosingName(AstNode node) {
    List<String> parts = [];
    while (node != null) {
      var nodeName = _computeNodeDeclarationName(node);
      if (nodeName != null) {
        parts.add(nodeName);
      } else if (parts.isEmpty && node is VariableDeclarationList) {
        parts.add(node.variables.first.declaredElement.name);
      }
      node = node.parent;
    }
    if (parts.isEmpty) return null;
    return parts.reversed.join('.');
  }

  static String _computeNodeDeclarationName(AstNode node) {
    if (node is ExtensionDeclaration) {
      return node.declaredElement?.name ?? '<unnamed extension>';
    } else if (node is Declaration) {
      var name = node.declaredElement?.name;
      return name == '' ? '<unnamed>' : name;
    } else {
      return null;
    }
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

/// Information about a propagation step that occurred during downstream
/// propagation.
abstract class DownstreamPropagationStepInfo implements PropagationStepInfo {
  DownstreamPropagationStepInfo get principalCause;

  /// The node whose nullability was changed.
  ///
  /// Any propagation step that took effect should have a non-null value here.
  /// Propagation steps that are pending but have not taken effect yet, or that
  /// never had an effect (e.g. because an edge was not triggered) will have a
  /// `null` value for this field.
  NullabilityNodeInfo get targetNode;
}

/// Information exposed to the migration client about an edge in the nullability
/// graph.
///
/// A graph edge represents a dependency relationship between two types being
/// migrated, suggesting that if one type (the source) is made nullable, it may
/// be desirable to make the other type (the destination) nullable as well.
abstract class EdgeInfo implements FixReasonInfo {
  /// User-friendly description of the edge, or `null` if not known.
  String get description;

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
  argumentErrorCheckNotNull,
  callTearOff,
  compoundAssignment,
  // See [DummyOrigin].
  dummy,
  dynamicAssignment,
  enumValue,
  expressionChecks,
  fieldFormalParameter,
  fieldNotInitialized,
  forEachVariable,
  getterSetterCorrespondence,
  greatestLowerBound,
  ifNull,
  implicitMixinSuperCall,
  implicitNullInitializer,
  implicitNullReturn,
  inferredTypeParameterInstantiation,
  instanceCreation,
  instantiateToBounds,
  isCheckComponentType,
  isCheckMainType,
  iteratorMethodReturn,
  listLengthConstructor,
  literal,
  namedParameterNotSupplied,
  nonNullableBoolType,
  nonNullableObjectSuperclass,
  nonNullableUsage,
  nonNullAssertion,
  nullabilityComment,
  optionalFormalParameter,
  parameterInheritance,
  quiverCheckNotNull,
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

/// Enum describing the possible hints that can be performed on an edge or a
/// node.
///
/// Which actions are available can be built by other visitors, and the hint can
/// be applied by visitors such as EditPlanner when the user requests it from
/// the front end.
enum HintActionKind {
  /// Add a `/*?*/` hint to a type.
  addNullableHint,

  /// Add a `/*!*/` hint to a type.
  addNonNullableHint,

  /// Change a `/*!*/` hint to a `/*?*/` hint.
  changeToNullableHint,

  /// Change a `/*?*/` hint to a `/*!*/` hint.
  changeToNonNullableHint,

  /// Remove a `/*?*/` hint.
  removeNullableHint,

  /// Remove a `/*!*/` hint.
  removeNonNullableHint,
}

/// Abstract interface for assigning ids numbers to nodes, and performing
/// lookups afterwards.
abstract class NodeMapper extends NodeToIdMapper {
  /// Gets the node corresponding to the given [id].
  NullabilityNodeInfo nodeForId(int id);
}

/// Abstract interface for assigning ids numbers to nodes.
abstract class NodeToIdMapper {
  /// Gets the id corresponding to the given [node].
  int idForNode(NullabilityNodeInfo node);
}

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

  /// Called when the migration process is finished.
  void finished();

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

  /// Source code location corresponding to this nullability node, or `null` if
  /// not known.
  CodeReference get codeReference;

  /// Some nodes get nullability from downstream, so the downstream edges are
  /// available to query as well.
  Iterable<EdgeInfo> get downstreamEdges;

  /// The hint actions users can perform on this node, indexed by the type of
  /// hint.
  ///
  /// Each edit is represented as a [Map<int, List<AtomicEdit>>] as is typical
  /// of [AtomicEdit]s since they do not have an offset. See extensions
  /// [AtomicEditMap] and [AtomicEditList] for usage.
  Map<HintActionKind, Map<int, List<AtomicEdit>>> get hintActions;

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

  /// If [isNullable] is false, the propagation step that caused this node to
  /// become non-nullable (if any).
  UpstreamPropagationStepInfo get whyNotNullable;

  /// If [isNullable] is true, the propagation step that caused this node to
  /// become nullable.
  DownstreamPropagationStepInfo get whyNullable;
}

abstract class PropagationStepInfo {
  CodeReference get codeReference;

  /// The nullability edge associated with this propagation step, if any.
  /// Otherwise `null`.
  EdgeInfo get edge;
}

/// Reason information for a simple fix that isn't associated with any edges or
/// nodes.
abstract class SimpleFixReasonInfo implements FixReasonInfo {
  /// Code location of the fix.
  CodeReference get codeReference;

  /// Description of the fix.
  String get description;
}

/// A simple implementation of [NodeMapper] that assigns ids to nodes as they
/// are requested, backed by a map.
///
/// Be careful not to leak references to nodes by holding on to this beyond the
/// lifetime of the nodes it maps.
class SimpleNodeMapper extends NodeMapper {
  final _nodeToId = <NullabilityNodeInfo, int>{};
  final _idToNode = <int, NullabilityNodeInfo>{};

  @override
  int idForNode(NullabilityNodeInfo node) {
    final id = _nodeToId.putIfAbsent(node, () => _nodeToId.length);
    _idToNode.putIfAbsent(id, () => node);
    return id;
  }

  @override
  NullabilityNodeInfo nodeForId(int id) => _idToNode[id];
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

/// Information about a propagation step that occurred during upstream
/// propagation.
abstract class UpstreamPropagationStepInfo implements PropagationStepInfo {
  bool get isStartingPoint;

  /// The node whose nullability was changed.
  ///
  /// Any propagation step that took effect should have a non-null value here.
  /// Propagation steps that are pending but have not taken effect yet, or that
  /// never had an effect (e.g. because an edge was not triggered) will have a
  /// `null` value for this field.
  NullabilityNodeInfo get node;

  UpstreamPropagationStepInfo get principalCause;
}

/// Extension methods to make [HintActionKind] act as a smart enum.
extension HintActionKindBehaviors on HintActionKind {
  /// Get the text description of a [HintActionKind], for display to users.
  String get description {
    switch (this) {
      case HintActionKind.addNullableHint:
        return 'Add /*?*/ hint';
      case HintActionKind.addNonNullableHint:
        return 'Add /*!*/ hint';
      case HintActionKind.removeNullableHint:
        return 'Remove /*?*/ hint';
      case HintActionKind.removeNonNullableHint:
        return 'Remove /*!*/ hint';
      case HintActionKind.changeToNullableHint:
        return 'Change to /*?*/ hint';
      case HintActionKind.changeToNonNullableHint:
        return 'Change to /*!*/ hint';
    }

    assert(false);
    return null;
  }
}
