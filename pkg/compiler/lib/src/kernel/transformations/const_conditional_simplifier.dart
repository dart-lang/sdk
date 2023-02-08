// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_prototype/constant_evaluator.dart';
import 'package:front_end/src/api_unstable/dart2js.dart' show LocatedMessage;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_environment.dart';

import '../../diagnostics/diagnostic_listener.dart';
import '../../environment.dart';
import '../../ir/constants.dart';
import '../../kernel/element_map.dart';
import '../../options.dart';

class ConstConditionalSimplifier extends RemovingTransformer {
  final Component _component;
  final Environment _environment;
  final DiagnosticReporter _reporter;
  final CompilerOptions _options;

  late final TypeEnvironment _typeEnvironment;
  late final Dart2jsConstantEvaluator _constantEvaluator;
  late StaticTypeContext _staticTypeContext;

  ConstConditionalSimplifier(
      this._component, this._environment, this._reporter, this._options) {
    final coreTypes = CoreTypes(_component);
    final classHierarchy = ClassHierarchy(_component, coreTypes);
    _typeEnvironment = TypeEnvironment(coreTypes, classHierarchy);
    _constantEvaluator = Dart2jsConstantEvaluator(_component, _typeEnvironment,
        (LocatedMessage message, List<LocatedMessage>? context) {
      reportLocatedMessage(_reporter, message, context);
    },
        environment: _environment,
        evaluationMode: _options.useLegacySubtyping
            ? EvaluationMode.weak
            : EvaluationMode.strong);
  }

  TreeNode run() => transform(_component);

  @override
  TreeNode defaultMember(Member node, TreeNode? removalSentinel) {
    _staticTypeContext = StaticTypeContext(node, _typeEnvironment);
    return super.defaultMember(node, removalSentinel);
  }

  @override
  TreeNode visitConditionalExpression(
      ConditionalExpression node, TreeNode? removalSentinel) {
    super.visitConditionalExpression(node, removalSentinel);
    final condition = _constantEvaluator.evaluateOrNull(
        _staticTypeContext, node.condition,
        requireConstant: false);
    if (condition is! BoolConstant) return node;
    return condition.value ? node.then : node.otherwise;
  }

  @override
  TreeNode visitIfStatement(IfStatement node, TreeNode? removalSentinel) {
    super.visitIfStatement(node, removalSentinel);
    final condition = _constantEvaluator.evaluateOrNull(
        _staticTypeContext, node.condition,
        requireConstant: false);
    if (condition is! BoolConstant) return node;
    if (condition.value) {
      return node.then;
    } else {
      return node.otherwise ?? removalSentinel ?? EmptyStatement();
    }
  }
}
