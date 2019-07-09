// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/src/conditional_discard.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/expression_checks.dart';
import 'package:nnbd_migration/src/node_builder.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:nnbd_migration/src/variables.dart';
import 'package:test/test.dart';

import 'abstract_single_unit.dart';

/// Mock representation of constraint variables.
class InstrumentedVariables extends Variables {
  final _conditionalDiscard = <AstNode, ConditionalDiscard>{};

  final _decoratedExpressionTypes = <Expression, DecoratedType>{};

  final _expressionChecks = <Expression, ExpressionChecks>{};

  final _possiblyOptional = <DefaultFormalParameter, NullabilityNode>{};

  InstrumentedVariables(NullabilityGraph graph) : super(graph);

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

class MigrationVisitorTestBase extends AbstractSingleUnitTest {
  final InstrumentedVariables variables;

  final NullabilityGraphForTesting graph;

  MigrationVisitorTestBase() : this._(NullabilityGraphForTesting());

  MigrationVisitorTestBase._(this.graph)
      : variables = InstrumentedVariables(graph);

  NullabilityNode get always => graph.always;

  NullabilityNode get never => graph.never;

  TypeProvider get typeProvider => testAnalysisResult.typeProvider;

  TypeSystem get typeSystem => testAnalysisResult.typeSystem;

  Future<CompilationUnit> analyze(String code) async {
    await resolveTestUnit(code);
    testUnit
        .accept(NodeBuilder(variables, testSource, null, graph, typeProvider));
    return testUnit;
  }

  NullabilityEdge assertEdge(
      NullabilityNode source, NullabilityNode destination,
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

  void assertNoEdge(NullabilityNode source, NullabilityNode destination) {
    var edges = getEdges(source, destination);
    if (edges.isNotEmpty) {
      fail('Expected no edge $source -> $destination, found ${edges.length}');
    }
  }

  void assertUnion(NullabilityNode x, NullabilityNode y) {
    var edges = getEdges(x, y);
    for (var edge in edges) {
      if (edge.isUnion) {
        expect(edge.sources, hasLength(1));
        return;
      }
    }
    fail('Expected union between $x and $y, not found');
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

  List<NullabilityEdge> getEdges(
          NullabilityNode source, NullabilityNode destination) =>
      graph
          .getUpstreamEdges(destination)
          .where((e) => e.primarySource == source)
          .toList();

  NullabilityNode possiblyOptionalParameter(String text) {
    return variables.possiblyOptionalParameter(findNode.defaultParameter(text));
  }

  /// Gets the [ConditionalDiscard] information associated with the statement
  /// whose text is [text].
  ConditionalDiscard statementDiscard(String text) {
    return variables.conditionalDiscard(findNode.statement(text));
  }
}
