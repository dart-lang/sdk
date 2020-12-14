// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/src/conditional_discard.dart';
import 'package:nnbd_migration/src/decorated_class_hierarchy.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/edge_builder.dart';
import 'package:nnbd_migration/src/expression_checks.dart';
import 'package:nnbd_migration/src/node_builder.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/nullability_node_target.dart';
import 'package:nnbd_migration/src/variables.dart';
import 'package:test/test.dart';

import 'abstract_single_unit.dart';

/// A [NodeMatcher] that matches any node, and records what node it matched to.
class AnyNodeMatcher extends _RecordingNodeMatcher {
  @override
  bool matches(NullabilityNode node) {
    return true;
  }
}

/// Mixin allowing unit tests to create decorated types easily.
mixin DecoratedTypeTester implements DecoratedTypeTesterBase {
  int nodeId = 0;

  NullabilityNode get always => graph.always;

  DecoratedType get bottom => DecoratedType(typeProvider.bottomType, never);

  DecoratedType get dynamic_ => DecoratedType(typeProvider.dynamicType, always);

  NullabilityNode get never => graph.never;

  DecoratedType get null_ => DecoratedType(typeProvider.nullType, always);

  DecoratedType get void_ => DecoratedType(typeProvider.voidType, always);

  DecoratedType function(DecoratedType returnType,
      {List<DecoratedType> required = const [],
      List<DecoratedType> positional = const [],
      Map<String, DecoratedType> named = const {},
      List<TypeParameterElement> typeFormals = const [],
      NullabilityNode node}) {
    int i = 0;
    var parameters = required
        .map((t) => ParameterElementImpl.synthetic(
            'p${i++}', t.type, ParameterKind.REQUIRED))
        .toList();
    parameters.addAll(positional.map((t) => ParameterElementImpl.synthetic(
        'p${i++}', t.type, ParameterKind.POSITIONAL)));
    parameters.addAll(named.entries.map((e) => ParameterElementImpl.synthetic(
        e.key, e.value.type, ParameterKind.NAMED)));
    return DecoratedType(
        FunctionTypeImpl(
          typeFormals: typeFormals,
          parameters: parameters,
          returnType: returnType.type,
          nullabilitySuffix: NullabilitySuffix.star,
        ),
        node ?? newNode(),
        returnType: returnType,
        positionalParameters: required.toList()..addAll(positional),
        namedParameters: named);
  }

  DecoratedType future(DecoratedType parameter, {NullabilityNode node}) {
    return DecoratedType(
        typeProvider.futureType2(parameter.type), node ?? newNode(),
        typeArguments: [parameter]);
  }

  DecoratedType futureOr(DecoratedType parameter, {NullabilityNode node}) {
    return DecoratedType(
        typeProvider.futureOrType2(parameter.type), node ?? newNode(),
        typeArguments: [parameter]);
  }

  DecoratedType int_({NullabilityNode node}) =>
      DecoratedType(typeProvider.intType, node ?? newNode());

  DecoratedType iterable(DecoratedType elementType, {NullabilityNode node}) =>
      DecoratedType(
          typeProvider.iterableType2(elementType.type), node ?? newNode(),
          typeArguments: [elementType]);

  DecoratedType list(DecoratedType elementType, {NullabilityNode node}) =>
      DecoratedType(typeProvider.listType2(elementType.type), node ?? newNode(),
          typeArguments: [elementType]);

  NullabilityNode newNode() => NullabilityNode.forTypeAnnotation(
      NullabilityNodeTarget.text('node ${nodeId++}'));

  DecoratedType num_({NullabilityNode node}) =>
      DecoratedType(typeProvider.numType, node ?? newNode());

  DecoratedType object({NullabilityNode node}) =>
      DecoratedType(typeProvider.objectType, node ?? newNode());

  TypeParameterElement typeParameter(String name, DecoratedType bound) {
    var element = TypeParameterElementImpl.synthetic(name);
    element.bound = bound.type;
    decoratedTypeParameterBounds.put(element, bound);
    return element;
  }

  DecoratedType typeParameterType(TypeParameterElement typeParameter,
      {NullabilityNode node}) {
    return DecoratedType(
      typeParameter.instantiate(
        nullabilitySuffix: NullabilitySuffix.star,
      ),
      node ?? newNode(),
    );
  }
}

/// Base functionality that must be implemented by classes mixing in
/// [DecoratedTypeTester].
abstract class DecoratedTypeTesterBase {
  DecoratedTypeParameterBounds get decoratedTypeParameterBounds;

  NullabilityGraph get graph;

  TypeProvider get typeProvider;
}

class EdgeBuilderTestBase extends MigrationVisitorTestBase {
  DecoratedClassHierarchy decoratedClassHierarchy;

  /// Analyzes the given source code, producing constraint variables and
  /// constraints for it.
  @override
  Future<CompilationUnit> analyze(String code) async {
    var unit = await super.analyze(code);
    decoratedClassHierarchy = DecoratedClassHierarchy(variables, graph);
    unit.accept(EdgeBuilder(typeProvider, typeSystem, variables, graph,
        testSource, null, decoratedClassHierarchy));
    return unit;
  }
}

/// Mixin allowing unit tests to check for the presence of graph edges.
mixin EdgeTester {
  /// Gets the set of all nodes pointed to by always, plus always itself.
  Set<NullabilityNode> get alwaysPlus {
    var result = <NullabilityNode>{graph.always};
    for (var edge in getEdges(graph.always, anyNode)) {
      if (edge.guards.isEmpty) {
        result.add(edge.destinationNode);
      }
    }
    return result;
  }

  /// Returns a [NodeMatcher] that matches any node whatsoever.
  AnyNodeMatcher get anyNode => AnyNodeMatcher();

  NullabilityGraphForTesting get graph;

  /// Gets the transitive closure of all nodes with hard edges pointing to
  /// never, plus never itself.
  Set<NullabilityNode> get neverClosure {
    var result = <NullabilityNode>{};
    var pending = <NullabilityNode>[graph.never];
    while (pending.isNotEmpty) {
      var node = pending.removeLast();
      if (result.add(node)) {
        for (var edge in getEdges(anyNode, node)) {
          pending.add(edge.sourceNode);
        }
      }
    }
    return result;
  }

  /// Gets the set of nodes with hard edges pointing to never.
  Set<NullabilityNode> get pointsToNever {
    return {for (var edge in getEdges(anyNode, graph.never)) edge.sourceNode};
  }

  /// Asserts that a dummy edge exists from [source] to always.
  NullabilityEdge assertDummyEdge(Object source) =>
      assertEdge(source, graph.always, hard: false, checkable: false);

  /// Asserts that an edge exists with a node matching [source] and a node
  /// matching [destination], and with the given [hard]ness and [guards].
  ///
  /// [source] and [destination] are converted to [NodeMatcher] objects if they
  /// aren't already.  In practice this means that the caller can pass in either
  /// a [NodeMatcher] or a [NullabilityNode].
  NullabilityEdge assertEdge(Object source, Object destination,
      {@required bool hard,
      bool checkable = true,
      bool isSetupAssignment = false,
      Object guards = isEmpty,
      Object codeReference}) {
    var edges = getEdges(source, destination);
    if (edges.isEmpty) {
      fail('Expected edge $source -> $destination, found none');
    } else if (edges.length != 1) {
      fail('Found multiple edges $source -> $destination');
    } else {
      var edge = edges[0];
      expect(edge.isHard, hard);
      expect(edge.isCheckable, checkable);
      expect(edge.isSetupAssignment, isSetupAssignment);
      expect(edge.guards, guards);
      if (codeReference != null) {
        expect(edge.codeReference, codeReference);
      }
      return edge;
    }
  }

  /// Asserts that no edge exists with a node matching [source] and a node
  /// matching [destination].
  ///
  /// [source] and [destination] are converted to [NodeMatcher] objects if they
  /// aren't already.  In practice this means that the caller can pass in either
  /// a [NodeMatcher] or a [NullabilityNode].
  void assertNoEdge(Object source, Object destination) {
    var edges = getEdges(source, destination);
    if (edges.isNotEmpty) {
      fail('Expected no edge $source -> $destination, found $edges');
    }
  }

  /// Asserts that a union-type edge exists between nodes [x] and [y].
  ///
  /// [x] and [y] are converted to [NodeMatcher] objects if they aren't already.
  /// In practice this means that the caller can pass in either a [NodeMatcher]
  /// or a [NullabilityNode].
  void assertUnion(Object x, Object y) {
    var edges = getEdges(x, y);
    for (var edge in edges) {
      if (edge.isUnion) {
        expect(edge.upstreamNodes, hasLength(1));
        return;
      }
    }
    fail('Expected union between $x and $y, not found');
  }

  /// Gets a list of all edges whose source matches [source] and whose
  /// destination matches [destination].
  ///
  /// [source] and [destination] are converted to [NodeMatcher] objects if they
  /// aren't already.  In practice this means that the caller can pass in either
  /// a [NodeMatcher] or a [NullabilityNode].
  List<NullabilityEdge> getEdges(Object source, Object destination) {
    var sourceMatcher = NodeMatcher(source);
    var destinationMatcher = NodeMatcher(destination);
    var result = <NullabilityEdge>[];
    for (var edge in graph.getAllEdges()) {
      if (sourceMatcher.matches(edge.sourceNode) &&
          destinationMatcher.matches(edge.destinationNode)) {
        sourceMatcher.matched(edge.sourceNode);
        destinationMatcher.matched(edge.destinationNode);
        result.add(edge);
      }
    }
    return result;
  }

  /// Returns a [NodeMatcher] that matches any node in the given set.
  NodeSetMatcher inSet(Set<NullabilityNode> nodes) => NodeSetMatcher(nodes);

  /// Creates a [NodeMatcher] matching a substitution node whose inner and outer
  /// nodes match [inner] and [outer].
  ///
  /// [inner] and [outer] are converted to [NodeMatcher] objects if they aren't
  /// already.  In practice this means that the caller can pass in either a
  /// [NodeMatcher] or a [NullabilityNode].
  NodeMatcher substitutionNode(Object inner, Object outer) =>
      _SubstitutionNodeMatcher(NodeMatcher(inner), NodeMatcher(outer));
}

/// Mock representation of constraint variables.
class InstrumentedVariables extends Variables {
  final _conditionalDiscard = <AstNode, ConditionalDiscard>{};

  final _decoratedExpressionTypes = <Expression, DecoratedType>{};

  final _expressionChecks = <Expression, ExpressionChecksOrigin>{};

  InstrumentedVariables(NullabilityGraph graph, TypeProvider typeProvider,
      LineInfo Function(String) getLineInfo)
      : super(graph, typeProvider, getLineInfo);

  /// Gets the [ExpressionChecks] associated with the given [expression].
  ExpressionChecksOrigin checkExpression(Expression expression) =>
      _expressionChecks[_normalizeExpression(expression)];

  /// Gets the [conditionalDiscard] associated with the given [expression].
  ConditionalDiscard conditionalDiscard(AstNode node) =>
      _conditionalDiscard[node];

  /// Gets the [DecoratedType] associated with the given [expression].
  DecoratedType decoratedExpressionType(Expression expression) =>
      _decoratedExpressionTypes[_normalizeExpression(expression)];

  @override
  void recordConditionalDiscard(
      Source source, AstNode node, ConditionalDiscard conditionalDiscard) {
    _conditionalDiscard[node] = conditionalDiscard;
    super.recordConditionalDiscard(source, node, conditionalDiscard);
  }

  void recordDecoratedExpressionType(Expression node, DecoratedType type) {
    super.recordDecoratedExpressionType(node, type);
    _decoratedExpressionTypes[_normalizeExpression(node)] = type;
  }

  @override
  void recordExpressionChecks(
      Source source, Expression expression, ExpressionChecksOrigin origin) {
    super.recordExpressionChecks(source, expression, origin);
    _expressionChecks[_normalizeExpression(expression)] = origin;
  }

  /// Unwraps any parentheses surrounding [expression].
  Expression _normalizeExpression(Expression expression) {
    while (expression is ParenthesizedExpression) {
      expression = (expression as ParenthesizedExpression).expression;
    }
    return expression;
  }
}

class MigrationVisitorTestBase extends AbstractSingleUnitTest with EdgeTester {
  InstrumentedVariables variables;

  final NullabilityGraphForTesting graph;

  final decoratedTypeParameterBounds = DecoratedTypeParameterBounds();

  MigrationVisitorTestBase() : this._(NullabilityGraphForTesting());

  MigrationVisitorTestBase._(this.graph);

  NullabilityNode get always => graph.always;

  NullabilityNode get never => graph.never;

  TypeProvider get typeProvider => testAnalysisResult.typeProvider;

  TypeSystemImpl get typeSystem =>
      testAnalysisResult.typeSystem as TypeSystemImpl;

  Future<CompilationUnit> analyze(String code) async {
    await resolveTestUnit(code);
    variables = InstrumentedVariables(graph, typeProvider, getLineInfo);
    testUnit.accept(NodeBuilder(
        variables, testSource, null, graph, typeProvider, getLineInfo));
    return testUnit;
  }

  /// Gets the [DecoratedType] associated with the constructor declaration whose
  /// name matches [search].
  DecoratedType decoratedConstructorDeclaration(String search) => variables
      .decoratedElementType(findNode.constructor(search).declaredElement);

  Map<ClassElement, DecoratedType> decoratedDirectSupertypes(String name) {
    return variables.decoratedDirectSupertypes(findElement.classOrMixin(name));
  }

  /// Gets the [DecoratedType] associated with the generic function type
  /// annotation whose text is [text].
  DecoratedType decoratedGenericFunctionTypeAnnotation(String text) {
    return variables.decoratedTypeAnnotation(
        testSource, findNode.genericFunctionType(text));
  }

  /// Gets the [DecoratedType] associated with the method declaration whose
  /// name matches [search].
  DecoratedType decoratedMethodType(String search) => variables
      .decoratedElementType(findNode.methodDeclaration(search).declaredElement);

  /// Gets the [DecoratedType] associated with the type annotation whose text
  /// is [text].
  DecoratedType decoratedTypeAnnotation(String text) {
    return variables.decoratedTypeAnnotation(
        testSource, findNode.typeAnnotation(text));
  }

  /// Gets the [ConditionalDiscard] information associated with the collection
  /// element whose text is [text].
  ConditionalDiscard elementDiscard(String text) {
    return variables.conditionalDiscard(findNode.collectionElement(text));
  }

  /// Returns a [Matcher] that matches a [CodeReference] pointing to the given
  /// file [offset], with the given [function] name.
  TypeMatcher<CodeReference> matchCodeRef(
      {@required int offset, @required String function}) {
    var location = testUnit.lineInfo.getLocation(offset);
    return TypeMatcher<CodeReference>()
        .having((cr) => cr.line, 'line', location.lineNumber)
        .having((cr) => cr.column, 'column', location.columnNumber)
        .having((cr) => cr.function, 'function', function);
  }

  void setUp() {
    DecoratedTypeParameterBounds.current = decoratedTypeParameterBounds;
    super.setUp();
  }

  /// Gets the [ConditionalDiscard] information associated with the statement
  /// whose text is [text].
  ConditionalDiscard statementDiscard(String text) {
    return variables.conditionalDiscard(findNode.statement(text));
  }

  void tearDown() {
    DecoratedTypeParameterBounds.current = null;
    super.tearDown();
  }
}

/// Abstract base class representing a thing that can be matched against
/// nullability nodes.
abstract class NodeMatcher {
  factory NodeMatcher(Object expectation) {
    if (expectation is NodeMatcher) return expectation;
    if (expectation is NullabilityNode) return _ExactNodeMatcher(expectation);
    fail(
        'Unclear how to match node expectation of type ${expectation.runtimeType}');
  }

  void matched(NullabilityNode node);

  bool matches(NullabilityNode node);
}

/// A [NodeMatcher] that matches any node contained in the given set.
class NodeSetMatcher extends _RecordingNodeMatcher {
  final Set<NullabilityNode> _targetSet;

  NodeSetMatcher(this._targetSet);

  @override
  bool matches(NullabilityNode node) => _targetSet.contains(node);
}

/// A [NodeMatcher] that matches exactly one node.
class _ExactNodeMatcher implements NodeMatcher {
  final NullabilityNode _expectation;

  _ExactNodeMatcher(this._expectation);

  @override
  void matched(NullabilityNode node) {}

  @override
  bool matches(NullabilityNode node) => node == _expectation;
}

/// Base class for [NodeMatcher]s that remember which nodes were matched.
abstract class _RecordingNodeMatcher implements NodeMatcher {
  final List<NullabilityNode> _matchingNodes = [];

  NullabilityNode get matchingNode => _matchingNodes.single;

  @override
  void matched(NullabilityNode node) {
    _matchingNodes.add(node);
  }
}

/// A [NodeMatcher] that matches a substitution node with the given inner and
/// outer nodes.
class _SubstitutionNodeMatcher implements NodeMatcher {
  final NodeMatcher inner;
  final NodeMatcher outer;

  _SubstitutionNodeMatcher(this.inner, this.outer);

  @override
  void matched(NullabilityNode node) {
    if (node is NullabilityNodeForSubstitution) {
      inner.matched(node.innerNode);
      outer.matched(node.outerNode);
    } else {
      throw StateError(
          'matched should only be called on nodes for which matches returned '
          'true');
    }
  }

  @override
  bool matches(NullabilityNode node) {
    return node is NullabilityNodeForSubstitution &&
        inner.matches(node.innerNode) &&
        outer.matches(node.outerNode);
  }
}
