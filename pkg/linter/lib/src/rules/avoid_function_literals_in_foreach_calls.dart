// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Avoid using `forEach` with a function literal.';

bool _hasMethodChaining(MethodInvocation node) {
  var exp = node.target;
  while (exp is PrefixedIdentifier ||
      exp is MethodInvocation ||
      exp is PropertyAccess) {
    if (exp is PrefixedIdentifier) {
      exp = exp.prefix;
    } else if (exp is MethodInvocation) {
      return true;
    } else if (exp is PropertyAccess) {
      exp = exp.target;
    }
  }
  return false;
}

bool _isInsideCascade(AstNode node) =>
    node.thisOrAncestorMatching((n) => n is Statement || n is CascadeExpression)
        is CascadeExpression;

bool _isIterable(DartType? type) =>
    type != null && type.implementsInterface('Iterable', 'dart.core');

class AvoidFunctionLiteralsInForeachCalls extends LintRule {
  AvoidFunctionLiteralsInForeachCalls()
    : super(
        name: LintNames.avoid_function_literals_in_foreach_calls,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.avoidFunctionLiteralsInForeachCalls;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var target = node.target;
    if (target != null &&
        node.methodName.token.value() == 'forEach' &&
        node.argumentList.arguments.isNotEmpty &&
        node.argumentList.arguments.first is FunctionExpression &&
        _isIterable(target.staticType) &&
        !node.containsNullAwareInvocationInChain &&
        !_hasMethodChaining(node) &&
        !_isInsideCascade(node)) {
      rule.reportAtNode(node.function);
    }
  }
}
