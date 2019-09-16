// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/src/conditional_discard.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/edge_builder.dart';
import 'package:nnbd_migration/src/expression_checks.dart';
import 'package:nnbd_migration/src/node_builder.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/variables.dart';
import 'package:test/test.dart';

import 'abstract_single_unit.dart';

/// A [NodeMatcher] that matches any node, and records what node it matched to.
class AnyNodeMatcher implements NodeMatcher {
  final List<NullabilityNode> _matchingNodes = [];

  NullabilityNode get matchingNode => _matchingNodes.single;

  @override
  bool matches(NullabilityNode node) {
    _matchingNodes.add(node);
    return true;
  }
}

/// Mixin allowing unit tests to create decorated types easily.
mixin DecoratedTypeTester implements DecoratedTypeTesterBase {
  int _offset = 0;

  Map<TypeParameterElement, DecoratedType> _decoratedTypeParameterBounds =
      Map.identity();

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
        FunctionTypeImpl.synthetic(returnType.type, typeFormals, parameters),
        node ?? newNode(),
        typeFormalBounds: typeFormals
            .map((formal) => _decoratedTypeParameterBounds[formal])
            .toList(),
        returnType: returnType,
        positionalParameters: required.toList()..addAll(positional),
        namedParameters: named);
  }

  DecoratedType future(DecoratedType parameter, {NullabilityNode node}) {
    return DecoratedType(typeProvider.futureType.instantiate([parameter.type]),
        node ?? newNode(),
        typeArguments: [parameter]);
  }

  DecoratedType futureOr(DecoratedType parameter, {NullabilityNode node}) {
    return DecoratedType(
        typeProvider.futureOrType.instantiate([parameter.type]),
        node ?? newNode(),
        typeArguments: [parameter]);
  }

  DecoratedType int_({NullabilityNode node}) =>
      DecoratedType(typeProvider.intType, node ?? newNode());

  DecoratedType list(DecoratedType elementType, {NullabilityNode node}) =>
      DecoratedType(typeProvider.listType.instantiate([elementType.type]),
          node ?? newNode(),
          typeArguments: [elementType]);

  NullabilityNode newNode() => NullabilityNode.forTypeAnnotation(_offset++);

  DecoratedType object({NullabilityNode node}) =>
      DecoratedType(typeProvider.objectType, node ?? newNode());

  TypeParameterElement typeParameter(String name, DecoratedType bound) {
    var element = TypeParameterElementImpl.synthetic(name);
    element.bound = bound.type;
    _decoratedTypeParameterBounds[element] = bound;
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
  NullabilityGraph get graph;

  TypeProvider get typeProvider;
}

class EdgeBuilderTestBase extends MigrationVisitorTestBase {
  /// Analyzes the given source code, producing constraint variables and
  /// constraints for it.
  @override
  Future<CompilationUnit> analyze(String code) async {
    var unit = await super.analyze(code);
    unit.accept(EdgeBuilder(
        typeProvider, typeSystem, variables, graph, testSource, null));
    return unit;
  }
}

/// Mixin allowing unit tests to check for the presence of graph edges.
mixin EdgeTester {
  /// Returns a [NodeMatcher] that matches any node whatsoever.
  AnyNodeMatcher get anyNode => AnyNodeMatcher();

  NullabilityGraphForTesting get graph;

  /// Asserts that an edge exists with a node matching [source] and a node
  /// matching [destination], and with the given [hard]ness and [guards].
  ///
  /// [source] and [destination] are converted to [NodeMatcher] objects if they
  /// aren't already.  In practice this means that the caller can pass in either
  //  /// a [NodeMatcher] or a [NullabilityNode].
  NullabilityEdge assertEdge(Object source, Object destination,
      {@required bool hard, List<NullabilityNode> guards = const []}) {
    var edges = getEdges(source, destination);
    if (edges.length == 0) {
      fail('Expected edge $source -> $destination, found none');
    } else if (edges.length != 1) {
      fail('Found multiple edges $source -> $destination');
    } else {
      var edge = edges[0];
      expect(edge.hard, hard);
      expect(edge.guards, unorderedEquals(guards));
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
      fail('Expected no edge $source -> $destination, found ${edges.length}');
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
        expect(edge.sources, hasLength(1));
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
    return graph
        .getAllEdges()
        .where((e) =>
            sourceMatcher.matches(e.primarySource) &&
            destinationMatcher.matches(e.destinationNode))
        .toList();
  }

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

  final _expressionChecks = <Expression, ExpressionChecks>{};

  final _possiblyOptional = <DefaultFormalParameter, NullabilityNode>{};

  InstrumentedVariables(NullabilityGraph graph, TypeProvider typeProvider)
      : super(graph, typeProvider);

  /// Gets the [ExpressionChecks] associated with the given [expression].
  ExpressionChecks checkExpression(Expression expression) =>
      _expressionChecks[_normalizeExpression(expression)];

  /// Gets the [conditionalDiscard] associated with the given [expression].
  ConditionalDiscard conditionalDiscard(AstNode node) =>
      _conditionalDiscard[node];

  /// Gets the [DecoratedType] associated with the given [expression].
  DecoratedType decoratedExpressionType(Expression expression) =>
      _decoratedExpressionTypes[_normalizeExpression(expression)];

  /// Gets the [NullabilityNode] associated with the possibility that
  /// [parameter] may be optional.
  NullabilityNode possiblyOptionalParameter(DefaultFormalParameter parameter) =>
      _possiblyOptional[parameter];

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
      Source source, Expression expression, ExpressionChecks checks) {
    super.recordExpressionChecks(source, expression, checks);
    _expressionChecks[_normalizeExpression(expression)] = checks;
  }

  @override
  void recordPossiblyOptional(
      Source source, DefaultFormalParameter parameter, NullabilityNode node) {
    _possiblyOptional[parameter] = node;
    super.recordPossiblyOptional(source, parameter, node);
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

  MigrationVisitorTestBase() : this._(NullabilityGraphForTesting());

  MigrationVisitorTestBase._(this.graph);

  NullabilityNode get always => graph.always;

  NullabilityNode get never => graph.never;

  TypeProvider get typeProvider => testAnalysisResult.typeProvider;

  TypeSystem get typeSystem => testAnalysisResult.typeSystem;

  Future<CompilationUnit> analyze(String code) async {
    await resolveTestUnit(code);
    variables = InstrumentedVariables(graph, typeProvider);
    testUnit
        .accept(NodeBuilder(variables, testSource, null, graph, typeProvider));
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

  NullabilityNode possiblyOptionalParameter(String text) {
    return variables.possiblyOptionalParameter(findNode.defaultParameter(text));
  }

  /// Gets the [ConditionalDiscard] information associated with the statement
  /// whose text is [text].
  ConditionalDiscard statementDiscard(String text) {
    return variables.conditionalDiscard(findNode.statement(text));
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

  bool matches(NullabilityNode node);
}

/// A [NodeMatcher] that matches exactly one node.
class _ExactNodeMatcher implements NodeMatcher {
  final NullabilityNode _expectation;

  _ExactNodeMatcher(this._expectation);

  @override
  bool matches(NullabilityNode node) => node == _expectation;
}

/// A [NodeMatcher] that matches a substitution node with the given inner and
/// outer nodes.
class _SubstitutionNodeMatcher implements NodeMatcher {
  final NodeMatcher inner;
  final NodeMatcher outer;

  _SubstitutionNodeMatcher(this.inner, this.outer);

  @override
  bool matches(NullabilityNode node) {
    return node is NullabilityNodeForSubstitution &&
        inner.matches(node.innerNode) &&
        outer.matches(node.outerNode);
  }
}
