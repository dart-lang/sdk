// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../util/flutter_utils.dart';

const _desc = r'Use `DecoratedBox`.';

class UseDecoratedBox extends LintRule {
  UseDecoratedBox()
      : super(
          name: LintNames.use_decorated_box,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.use_decorated_box;

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
    if (!isExactWidgetTypeContainer(node.staticType)) {
      return;
    }

    if (_shouldReportForArguments(node.argumentList)) {
      rule.reportLint(node.constructorName);
    }
  }

  /// Determine if the lint [rule] should be reported for
  /// the specified [argumentList].
  static bool _shouldReportForArguments(ArgumentList argumentList) {
    var hasChild = false;
    var hasDecoration = false;

    for (var argument in argumentList.arguments) {
      if (argument is! NamedExpression) {
        // Positional arguments are not supported.
        return false;
      }
      switch (argument.name.label.name) {
        case 'child':
          hasChild = true;
        case 'decoration':
          hasDecoration = true;
        case 'key':
          // Ignore 'key' as both DecoratedBox and Container have it.
          break;
        case _:
          // Other named arguments are not supported.
          return false;
      }
    }

    return hasChild && hasDecoration;
  }
}
