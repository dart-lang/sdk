// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/error/error.dart';
import 'package:collection/collection.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../extensions.dart';
import '../util/dart_type_utilities.dart';

const _desc = r"Don't create a lambda when a tear-off will do.";

Set<Element?> _extractElementsOfSimpleIdentifiers(AstNode node) =>
    _IdentifierVisitor().extractElements(node);

class UnnecessaryLambdas extends AnalysisRule {
  UnnecessaryLambdas()
    : super(name: LintNames.unnecessary_lambdas, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.unnecessaryLambdas;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addFunctionExpression(this, visitor);
  }
}

class _FinalExpressionChecker {
  final Set<FormalParameterElement?> parameters;

  _FinalExpressionChecker(this.parameters);

  bool isFinalNode(Expression? node_) {
    if (node_ == null) {
      return true;
    }

    var node = node_.unParenthesized;

    if (node is FunctionExpression) {
      var referencedElements = _extractElementsOfSimpleIdentifiers(node);
      return !referencedElements.any(parameters.contains);
    }

    if (node is PrefixedIdentifier) {
      return isFinalNode(node.prefix) && isFinalNode(node.identifier);
    }

    if (node is PropertyAccess) {
      return isFinalNode(node.target) && isFinalNode(node.propertyName);
    }

    if (node is SimpleIdentifier) {
      var element = node.element;
      if (parameters.contains(element)) {
        return false;
      }
      return element.isFinal;
    }

    return false;
  }
}

class _IdentifierVisitor extends RecursiveAstVisitor<void> {
  final _elements = <Element?>{};

  _IdentifierVisitor();

  Set<Element?> extractElements(AstNode node) {
    node.accept(this);
    return _elements;
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    _elements.add(node.element);
    super.visitSimpleIdentifier(node);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final bool constructorTearOffsEnabled;
  final AnalysisRule rule;
  final TypeSystem typeSystem;

  _Visitor(this.rule, RuleContext context)
    : constructorTearOffsEnabled = context.isFeatureEnabled(
        Feature.constructor_tearoffs,
      ),
      typeSystem = context.typeSystem;

  bool parametersMatch(DartType invocationType, FunctionType nodeType) {
    if (invocationType is! FunctionType) {
      // We must assume is valid here.
      return true;
    }
    var requiredPositionalInvocation = invocationType
        .formalParameters
        .requiredPositional
        .toList();
    var requiredPositionalNode = nodeType.formalParameters.requiredPositional
        .toList();
    if (requiredPositionalInvocation.length != requiredPositionalNode.length) {
      return false;
    }
    for (var (invocationParam, nodeParam) in (
      nodeType.formalParameters.optionalPositional.toList(),
      invocationType.formalParameters.optionalPositional.toList(),
    ).minLengthList) {
      if (!typeSystem.isAssignableTo(invocationParam.type, nodeParam.type)) {
        return false;
      }
    }
    var namedParametersInvocation = invocationType.formalParameters.allNamed
        .toList();
    for (var parameter in namedParametersInvocation) {
      var invocationParameter = nodeType.formalParameters.named(parameter.name);
      if (invocationParameter == null) {
        if (parameter.isRequired) {
          return false;
        } else {
          continue;
        }
      }
      if (!typeSystem.isAssignableTo(
        parameter.type,
        invocationParameter.type,
      )) {
        return false;
      }
      if (parameter.isRequired != invocationParameter.isRequired) {
        return false;
      }
    }
    return true;
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    var element = node.declaredFragment?.element;
    if (element?.name != null || node.body.keyword != null) {
      return;
    }
    var body = node.body;
    if (body is BlockFunctionBody && body.block.statements.length == 1) {
      var statement = body.block.statements.single;
      if (statement is ExpressionStatement &&
          statement.expression is InvocationExpression) {
        _visitInvocationExpression(
          statement.expression as InvocationExpression,
          node,
        );
      } else if (statement is ReturnStatement &&
          statement.expression is InvocationExpression) {
        var expression = statement.expression;
        if (expression is InvocationExpression) {
          // In the code, `(e) { f(e); }`, check `f(e)`.
          _visitInvocationExpression(expression, node);
        }
      }
    } else if (body is ExpressionFunctionBody) {
      var expression = body.expression;
      if (expression is InvocationExpression) {
        // In the code, `(e) => f(e);`, check `f(e)`.
        _visitInvocationExpression(expression, node);
      } else if (constructorTearOffsEnabled &&
          expression is InstanceCreationExpression) {
        // In the code, `(e) => C(e)`, check `C(e)`.
        _visitInstanceCreation(expression, node);
      }
    }
  }

  /// Checks [expression], the singular child the body of [node], to see whether
  /// [node] unnecessarily wraps [node].
  void _visitInstanceCreation(
    InstanceCreationExpression expression,
    FunctionExpression node,
  ) {
    if (expression.isConst || expression.constructorName.type.isDeferred) {
      return;
    }

    var functionElement = node.declaredFragment?.element;

    var nodeType = functionElement?.type;
    var invocationType = expression.constructorName.element?.type;
    if (nodeType == null) return;
    if (invocationType == null) return;
    // It is possible that the invocation function type is a valid replacement
    // for the node's function type, even if each of the parameters of `node`
    // is a valid argument for the corresponding parameter of `expression`.
    if (!typeSystem.isAssignableTo(invocationType, nodeType)) {
      return;
    }

    var arguments = expression.argumentList.arguments;
    if (arguments.any((a) => a is! SimpleIdentifier)) return;

    var identifierArguments = arguments.cast<SimpleIdentifier>();
    var parameters = node.parameters?.parameters ?? <FormalParameter>[];
    if (parameters.length != arguments.length) return;

    for (var i = 0; i < arguments.length; ++i) {
      if (identifierArguments[i].name != parameters[i].name?.lexeme) {
        return;
      }
    }

    rule.reportAtNode(node);
  }

  void _visitInvocationExpression(
    InvocationExpression node,
    FunctionExpression nodeToLint,
  ) {
    var nodeToLintParams = nodeToLint.parameters?.parameters;
    if (nodeToLintParams == null ||
        !argumentsMatchParameters(
          node.argumentList.arguments,
          nodeToLintParams,
        )) {
      return;
    }

    var functionElement = nodeToLint.declaredFragment?.element;
    var nodeType = functionElement?.type;
    if (nodeType == null) return;
    var invocationType = node.staticInvokeType;
    if (invocationType == null) return;
    if (!typeSystem.isAssignableTo(invocationType, nodeType) &&
        !parametersMatch(invocationType, nodeType)) {
      return;
    }

    var parameters = nodeToLintParams
        .map((e) => e.declaredFragment?.element)
        .toSet();
    if (node is FunctionExpressionInvocation) {
      if (node.function.mightBeDeferred) return;

      // TODO(pq): consider checking for assignability
      // see: https://github.com/dart-lang/linter/issues/1561
      var checker = _FinalExpressionChecker(parameters);
      if (checker.isFinalNode(node.function)) {
        rule.reportAtNode(nodeToLint);
      }
    } else if (node is MethodInvocation) {
      if (node.target.mightBeDeferred) return;

      var tearoffType = node.staticInvokeType;
      if (tearoffType == null) return;

      var parent = nodeToLint.parent;
      if (parent is NamedExpression) {
        var argType = parent.staticType;
        if (argType == null) return;
        if (!typeSystem.isSubtypeOf(tearoffType, argType)) return;
      } else if (parent is VariableDeclaration) {
        var variableElement = parent.declaredFragment?.element;
        var variableType = variableElement?.type;
        if (variableType == null) return;
        if (!typeSystem.isSubtypeOf(tearoffType, variableType)) return;
      }

      var checker = _FinalExpressionChecker(parameters);
      if (!node.containsNullAwareInvocationInChain &&
          checker.isFinalNode(node.target) &&
          node.methodName.element.isFinal &&
          node.typeArguments == null) {
        rule.reportAtNode(nodeToLint);
      }
    }
  }
}

extension on List<FormalParameterElement> {
  Iterable<FormalParameterElement> get allNamed => where((p) => p.isNamed);

  Iterable<FormalParameterElement> get optionalPositional =>
      where((p) => p.isOptionalPositional);

  Iterable<FormalParameterElement> get requiredPositional =>
      where((p) => p.isRequiredPositional);

  FormalParameterElement? named(String? name) =>
      name == null ? null : firstWhereOrNull((p) => p.name == name);
}

extension<T, S> on (List<T>, List<S>) {
  /// Used on `optionalPositional` lists to get the minimum length of the two
  /// lists to check for assignability of the parameters.
  List<(T, S)> get minLengthList {
    var length = min($1.length, $2.length);
    return [for (var i = 0; i < length; ++i) ($1[i], $2[i])];
  }
}

extension on Expression? {
  bool get mightBeDeferred {
    var element = switch (this) {
      PrefixedIdentifier(:var prefix) => prefix.element,
      SimpleIdentifier(:var element) => element,
      _ => null,
    };
    return element is PrefixElement &&
        element.imports.any((e) => e.prefix?.isDeferred ?? false);
  }
}

extension on Element? {
  /// Returns whether this is a `final` variable or property and not `late`.
  bool get isFinal => switch (this) {
    PropertyAccessorElement(:var isOriginVariable, :var variable) =>
      isOriginVariable && variable.isFinal && !variable.isLate,
    VariableElement(:var isLate, :var isFinal) => isFinal && !isLate,
    // TODO(pq): [element model] this preserves existing v1 semantics but looks fishy
    _ => true,
  };
}
