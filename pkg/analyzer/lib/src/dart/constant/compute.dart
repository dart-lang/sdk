// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/resolver.dart'
    show TypeProvider, TypeSystem;
import 'package:analyzer/src/summary/link.dart' as graph
    show DependencyWalker, Node;

/// Compute values of the given [constants] with correct ordering.
void computeConstants(
    TypeProvider typeProvider,
    TypeSystem typeSystem,
    DeclaredVariables declaredVariables,
    List<ConstantEvaluationTarget> constants,
    ExperimentStatus experimentStatus) {
  var evaluationEngine = ConstantEvaluationEngine(
      typeProvider, declaredVariables,
      forAnalysisDriver: true,
      typeSystem: typeSystem,
      experimentStatus: experimentStatus);

  var nodes = <_ConstantNode>[];
  var nodeMap = <ConstantEvaluationTarget, _ConstantNode>{};
  for (var constant in constants) {
    var node = _ConstantNode(evaluationEngine, nodeMap, constant);
    nodes.add(node);
    nodeMap[constant] = node;
  }

  for (var node in nodes) {
    if (!node.isEvaluated) {
      _ConstantWalker(evaluationEngine).walk(node);
    }
  }
}

/**
 * [graph.Node] that is used to compute constants in dependency order.
 */
class _ConstantNode extends graph.Node<_ConstantNode> {
  final ConstantEvaluationEngine evaluationEngine;
  final Map<ConstantEvaluationTarget, _ConstantNode> nodeMap;
  final ConstantEvaluationTarget constant;

  _ConstantNode(this.evaluationEngine, this.nodeMap, this.constant);

  @override
  bool get isEvaluated => constant.isConstantEvaluated;

  @override
  List<_ConstantNode> computeDependencies() {
    var targets = <ConstantEvaluationTarget>[];
    evaluationEngine.computeDependencies(constant, targets.add);
    return targets.map(_getNode).toList();
  }

  _ConstantNode _getNode(ConstantEvaluationTarget constant) {
    return nodeMap.putIfAbsent(
      constant,
      () => _ConstantNode(evaluationEngine, nodeMap, constant),
    );
  }
}

/**
 * [graph.DependencyWalker] for computing constants and detecting cycles.
 */
class _ConstantWalker extends graph.DependencyWalker<_ConstantNode> {
  final ConstantEvaluationEngine evaluationEngine;

  _ConstantWalker(this.evaluationEngine);

  @override
  void evaluate(_ConstantNode node) {
    evaluationEngine.computeConstantValue(node.constant);
  }

  @override
  void evaluateScc(List<_ConstantNode> scc) {
    var constantsInCycle = scc.map((node) => node.constant);
    for (var node in scc) {
      var constant = node.constant;
      if (constant is ConstructorElementImpl) {
        constant.isCycleFree = false;
      }
      evaluationEngine.generateCycleError(constantsInCycle, constant);
    }
  }
}
