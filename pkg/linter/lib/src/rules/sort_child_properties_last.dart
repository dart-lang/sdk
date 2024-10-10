// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../util/flutter_utils.dart';

const _desc = r'Sort child properties last in widget instance creations.';

class SortChildPropertiesLast extends LintRule {
  SortChildPropertiesLast()
      : super(
          name: LintNames.sort_child_properties_last,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.sort_child_properties_last;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!isWidgetType(node.staticType)) {
      return;
    }

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
        .where((element) =>
            element is NamedExpression &&
            element.expression is! FunctionExpression)
        .isEmpty;
    if (!onlyClosuresAfterChild) {
      var argument = arguments.firstWhere(isChildArg);
      var name = (argument as NamedExpression).name.label.name;
      rule.reportLint(argument, arguments: [name]);
    }
  }

  static bool isChildArg(Expression e) {
    if (e is NamedExpression) {
      var name = e.name.label.name;
      return (name == 'child' || name == 'children') &&
          isWidgetProperty(e.staticType);
    }
    return false;
  }
}
