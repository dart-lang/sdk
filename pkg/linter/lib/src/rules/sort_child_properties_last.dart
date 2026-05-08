// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../util/flutter_utils.dart';

const _desc = r'Sort child properties last in widget instance creations.';

class SortChildPropertiesLast extends AnalysisRule {
  SortChildPropertiesLast()
    : super(name: LintNames.sort_child_properties_last, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.sortChildPropertiesLast;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!node.staticType.isWidgetType) return;

    var arguments = node.argumentList.arguments;
    if (arguments.length < 2 ||
        isChildArg(arguments.last) ||
        arguments.where(isChildArg).length != 1) {
      return;
    }

    var onlyClosuresAfterChild = arguments.reversed
        .takeWhile((argument) => !isChildArg(argument))
        .toList()
        .reversed
        .where(
          (element) =>
              element is NamedExpression &&
              element.expression is! FunctionExpression,
        )
        .isEmpty;
    if (!onlyClosuresAfterChild) {
      var argument = arguments.firstWhere(isChildArg);
      var name = (argument as NamedExpression).name.label.name;
      rule.reportAtNode(argument, arguments: [name]);
    }
  }

  static bool isChildArg(Expression e) {
    if (e is! NamedExpression) return false;

    var name = e.name.label.name;
    return (name == 'child' || name == 'children') &&
        e.staticType.isWidgetProperty;
  }
}
