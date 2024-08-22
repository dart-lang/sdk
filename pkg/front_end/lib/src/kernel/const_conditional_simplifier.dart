// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/type_environment.dart';

import 'constant_evaluator.dart';
import 'try_constant_evaluator.dart';

class ConstConditionalSimplifier extends RemovingTransformer {
  final Component _component;

  late final TypeEnvironment _typeEnvironment;
  late final _ConstantEvaluator constantEvaluator;
  final bool _removeAsserts;

  ConstConditionalSimplifier(
    DartLibrarySupport librarySupport,
    ConstantsBackend constantsBackend,
    this._component,
    ReportErrorFunction _reportError, {
    Map<String, String>? environmentDefines,
    required EvaluationMode evaluationMode,
    bool Function(TreeNode)? shouldNotInline,
    CoreTypes? coreTypes,
    ClassHierarchy? classHierarchy,
    bool removeAsserts = false,
  }) : _removeAsserts = removeAsserts {
    // Coverage-ignore(suite): Not run.
    coreTypes ??= new CoreTypes(_component);
    // Coverage-ignore(suite): Not run.
    classHierarchy ??= new ClassHierarchy(_component, coreTypes);
    _typeEnvironment = new TypeEnvironment(coreTypes, classHierarchy);
    constantEvaluator = new _ConstantEvaluator(
      librarySupport,
      constantsBackend,
      _component,
      _typeEnvironment,
      _reportError,
      environmentDefines: environmentDefines,
      evaluationMode: evaluationMode,
      shouldNotInline: shouldNotInline,
    );
  }

  Constant? _evaluate(Expression node) => constantEvaluator._evaluate(node);

  TreeNode run() => transform(_component);

  @override
  TreeNode defaultMember(Member node, TreeNode? removalSentinel) {
    return constantEvaluator
        .inStaticTypeContext(new StaticTypeContext(node, _typeEnvironment), () {
      constantEvaluator._clearLocalCaches();
      return super.defaultMember(node, removalSentinel);
    });
  }

  @override
  TreeNode visitConditionalExpression(
      ConditionalExpression node, TreeNode? removalSentinel) {
    super.visitConditionalExpression(node, removalSentinel);
    Constant? condition = _evaluate(node.condition);
    if (condition is! BoolConstant) return node;
    return condition.value
        ? node.then
        :
        // Coverage-ignore(suite): Not run.
        node.otherwise;
  }

  @override
  TreeNode visitIfStatement(IfStatement node, TreeNode? removalSentinel) {
    super.visitIfStatement(node, removalSentinel);
    Constant? condition = _evaluate(node.condition);
    if (condition is! BoolConstant) return node;
    // Coverage-ignore(suite): Not run.
    if (condition.value) {
      return node.then;
    } else {
      return node.otherwise ?? removalSentinel ?? new EmptyStatement();
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  TreeNode visitAssertBlock(AssertBlock node, TreeNode? removalSentinel) {
    if (_removeAsserts) {
      return removalSentinel ?? new EmptyStatement();
    } else {
      return super.visitAssertBlock(node, removalSentinel);
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  TreeNode visitAssertInitializer(
      AssertInitializer node, TreeNode? removalSentinel) {
    if (_removeAsserts) {
      // Initializers only occur in the initializer list, where they are always
      // removable.
      return removalSentinel!;
    } else {
      return super.visitAssertInitializer(node, removalSentinel);
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  TreeNode visitAssertStatement(
      AssertStatement node, TreeNode? removalSentinel) {
    if (_removeAsserts) {
      return removalSentinel ?? new EmptyStatement();
    } else {
      return super.visitAssertStatement(node, removalSentinel);
    }
  }
}

class _ConstantEvaluator extends TryConstantEvaluator {
  // TODO(fishythefish): Do caches need to be invalidated when the static type
  // context changes?
  final Map<VariableDeclaration, Constant?> _variableCache = {};
  final Map<Field, Constant?> _staticFieldCache = {};
  final Map<FunctionNode, Constant?> _functionCache = {};
  final Map<FunctionNode, Constant?> _localFunctionCache = {};
  // TODO(fishythefish): Make this more granular than [TreeNode].
  final bool Function(TreeNode) _shouldNotInline;

  _ConstantEvaluator(super.librarySupport, super.constantsBackend,
      super.component, super.typeEnvironment, super.reportError,
      {super.environmentDefines,
      required super.evaluationMode,
      bool Function(TreeNode)? shouldNotInline})
      : _shouldNotInline = shouldNotInline ?? ((_) => false);

  void _clearLocalCaches() {
    _variableCache.clear();
    _localFunctionCache.clear();
  }

  Constant? _evaluate(Expression node) =>
      evaluateOrNull(staticTypeContext, node, requireConstant: false);

  // Coverage-ignore(suite): Not run.
  Constant? _evaluateFunctionInvocation(FunctionNode node) {
    if (node.typeParameters.isNotEmpty ||
        node.requiredParameterCount != 0 ||
        node.positionalParameters.isNotEmpty ||
        node.namedParameters.isNotEmpty) {
      return null;
    }
    Statement? body = node.body;
    if (body is! ReturnStatement) return null;
    Expression? expression = body.expression;
    if (expression == null) return null;
    return _evaluate(expression);
  }

  Constant? _evaluateVariableGet(VariableDeclaration variable) {
    // A function parameter can be declared final with an initializer, but
    // doesn't necessarily have the initializer's value.
    if (variable.parent is FunctionNode) return null;
    // Coverage-ignore-block(suite): Not run.
    if (_shouldNotInline(variable)) return null;
    if (!variable.isFinal) return null;
    Expression? initializer = variable.initializer;
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
    // Coverage-ignore-block(suite): Not run.
    Expression? initializer = field.initializer;
    if (initializer == null) return null;
    return _evaluate(initializer);
  }

  Constant? _lookupStaticFieldGet(Field field) => _staticFieldCache.putIfAbsent(
      field, () => _evaluateStaticFieldGet(field));

  // Coverage-ignore(suite): Not run.
  Constant? _evaluateStaticGetter(Procedure getter) {
    if (_shouldNotInline(getter)) return null;
    return _evaluateFunctionInvocation(getter.function);
  }

  // Coverage-ignore(suite): Not run.
  Constant? _lookupStaticGetter(Procedure getter) => _functionCache.putIfAbsent(
      getter.function, () => _evaluateStaticGetter(getter));

  Constant? _lookupStaticGet(Member target) {
    if (target is Field) return _lookupStaticFieldGet(target);
    // Coverage-ignore(suite): Not run.
    return _lookupStaticGetter(target as Procedure);
  }

  @override
  Constant visitStaticGet(StaticGet node) =>
      _lookupStaticGet(node.target) ?? super.visitStaticGet(node);

  // Coverage-ignore(suite): Not run.
  Constant? _evaluateLocalFunctionInvocation(LocalFunctionInvocation node) {
    if (_shouldNotInline(node.variable)) return null;
    return _evaluateFunctionInvocation(node.localFunction.function);
  }

  // Coverage-ignore(suite): Not run.
  Constant? _lookupLocalFunctionInvocation(LocalFunctionInvocation node) =>
      _localFunctionCache.putIfAbsent(node.localFunction.function,
          () => _evaluateLocalFunctionInvocation(node));

  @override
  // Coverage-ignore(suite): Not run.
  Constant visitLocalFunctionInvocation(LocalFunctionInvocation node) =>
      _lookupLocalFunctionInvocation(node) ??
      super.visitLocalFunctionInvocation(node);

  // Coverage-ignore(suite): Not run.
  Constant? _evaluateStaticInvocation(Procedure target) {
    if (_shouldNotInline(target)) return null;
    return _evaluateFunctionInvocation(target.function);
  }

  // Coverage-ignore(suite): Not run.
  Constant? _lookupStaticInvocation(Procedure target) => _functionCache
      .putIfAbsent(target.function, () => _evaluateStaticInvocation(target));

  @override
  // Coverage-ignore(suite): Not run.
  Constant visitStaticInvocation(StaticInvocation node) {
    return _lookupStaticInvocation(node.target) ??
        super.visitStaticInvocation(node);
  }
}
