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
import '../../ir/annotations.dart';
import '../../ir/constants.dart';
import '../../kernel/element_map.dart';
import '../../options.dart';

bool _shouldNotInline(Annotatable node) =>
    computePragmaAnnotationDataFromIr(node).any((pragma) =>
        pragma == const PragmaAnnotationData('noInline') ||
        pragma == const PragmaAnnotationData('never-inline'));

class ConstConditionalSimplifier extends RemovingTransformer {
  final Component _component;
  final Environment _environment;
  final DiagnosticReporter _reporter;
  final CompilerOptions _options;

  late final TypeEnvironment _typeEnvironment;
  late final _ConstantEvaluator _constantEvaluator;

  ConstConditionalSimplifier(
      this._component, this._environment, this._reporter, this._options) {
    final coreTypes = CoreTypes(_component);
    final classHierarchy = ClassHierarchy(_component, coreTypes);
    _typeEnvironment = TypeEnvironment(coreTypes, classHierarchy);
    _constantEvaluator = _ConstantEvaluator(_component, _typeEnvironment,
        (LocatedMessage message, List<LocatedMessage>? context) {
      reportLocatedMessage(_reporter, message, context);
    },
        environment: _environment,
        evaluationMode: _options.useLegacySubtyping
            ? EvaluationMode.weak
            : EvaluationMode.strong);
  }

  Constant? _evaluate(Expression node) => _constantEvaluator._evaluate(node);

  TreeNode run() => transform(_component);

  @override
  TreeNode defaultMember(Member node, TreeNode? removalSentinel) {
    _constantEvaluator._staticTypeContext =
        StaticTypeContext(node, _typeEnvironment);
    _constantEvaluator._clearLocalCaches();
    return super.defaultMember(node, removalSentinel);
  }

  @override
  TreeNode visitConditionalExpression(
      ConditionalExpression node, TreeNode? removalSentinel) {
    super.visitConditionalExpression(node, removalSentinel);
    final condition = _evaluate(node.condition);
    if (condition is! BoolConstant) return node;
    return condition.value ? node.then : node.otherwise;
  }

  @override
  TreeNode visitIfStatement(IfStatement node, TreeNode? removalSentinel) {
    super.visitIfStatement(node, removalSentinel);
    final condition = _evaluate(node.condition);
    if (condition is! BoolConstant) return node;
    if (condition.value) {
      return node.then;
    } else {
      return node.otherwise ?? removalSentinel ?? EmptyStatement();
    }
  }
}

class _ConstantEvaluator extends Dart2jsConstantEvaluator {
  late StaticTypeContext _staticTypeContext;

  // TODO(fishythefish): Do caches need to be invalidated when the static type
  // context changes?
  final Map<VariableDeclaration, Constant?> _variableCache = {};
  final Map<Field, Constant?> _staticFieldCache = {};
  final Map<FunctionNode, Constant?> _functionCache = {};
  final Map<FunctionNode, Constant?> _localFunctionCache = {};

  _ConstantEvaluator(super.component, super.typeEnvironment, super.reportError,
      {super.environment, required super.evaluationMode});

  void _clearLocalCaches() {
    _variableCache.clear();
    _localFunctionCache.clear();
  }

  Constant? _evaluate(Expression node) =>
      evaluateOrNull(_staticTypeContext, node, requireConstant: false);

  Constant? _evaluateFunctionInvocation(FunctionNode node) {
    if (node.typeParameters.isNotEmpty ||
        node.requiredParameterCount != 0 ||
        node.positionalParameters.isNotEmpty ||
        node.namedParameters.isNotEmpty) return null;
    final body = node.body;
    if (body is! ReturnStatement) return null;
    final expression = body.expression;
    if (expression == null) return null;
    return _evaluate(expression);
  }

  Constant? _evaluateVariableGet(VariableDeclaration variable) {
    // A function parameter can be declared final with an initializer, but
    // doesn't necessarily have the initializer's value.
    if (variable.parent is FunctionNode) return null;
    if (_shouldNotInline(variable)) return null;
    if (!variable.isFinal) return null;
    final initializer = variable.initializer;
    if (initializer == null) return null;
    return _evaluate(initializer);
  }

  Constant? _lookupVariableGet(VariableDeclaration variable) => _variableCache
      .putIfAbsent(variable, () => _evaluateVariableGet(variable));

  @override
  Constant visitVariableGet(VariableGet node) =>
      _lookupVariableGet(node.variable) ?? super.visitVariableGet(node);

  Constant? _evaluateStaticFieldGet(Field field) {
    if (_shouldNotInline(field)) return null;
    if (!field.isFinal) return null;
    final initializer = field.initializer;
    if (initializer == null) return null;
    return _evaluate(initializer);
  }

  Constant? _lookupStaticFieldGet(Field field) => _staticFieldCache.putIfAbsent(
      field, () => _evaluateStaticFieldGet(field));

  Constant? _evaluateStaticGetter(Procedure getter) {
    if (_shouldNotInline(getter)) return null;
    return _evaluateFunctionInvocation(getter.function);
  }

  Constant? _lookupStaticGetter(Procedure getter) => _functionCache.putIfAbsent(
      getter.function, () => _evaluateStaticGetter(getter));

  Constant? _lookupStaticGet(Member target) {
    if (target is Field) return _lookupStaticFieldGet(target);
    return _lookupStaticGetter(target as Procedure);
  }

  @override
  Constant visitStaticGet(StaticGet node) =>
      _lookupStaticGet(node.target) ?? super.visitStaticGet(node);

  Constant? _evaluateLocalFunctionInvocation(LocalFunctionInvocation node) {
    if (_shouldNotInline(node.variable)) return null;
    return _evaluateFunctionInvocation(node.localFunction.function);
  }

  Constant? _lookupLocalFunctionInvocation(LocalFunctionInvocation node) =>
      _localFunctionCache.putIfAbsent(node.localFunction.function,
          () => _evaluateLocalFunctionInvocation(node));

  @override
  Constant visitLocalFunctionInvocation(LocalFunctionInvocation node) =>
      _lookupLocalFunctionInvocation(node) ??
      super.visitLocalFunctionInvocation(node);

  Constant? _evaluateStaticInvocation(Procedure target) {
    if (_shouldNotInline(target)) return null;
    return _evaluateFunctionInvocation(target.function);
  }

  Constant? _lookupStaticInvocation(Procedure target) => _functionCache
      .putIfAbsent(target.function, () => _evaluateStaticInvocation(target));

  @override
  Constant visitStaticInvocation(StaticInvocation node) {
    return _lookupStaticInvocation(node.target) ??
        super.visitStaticInvocation(node);
  }
}
