// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../util/flutter_utils.dart';

const _desc = r'`SizedBox` for whitespace.';

class SizedBoxForWhitespace extends AnalysisRule {
  SizedBoxForWhitespace()
    : super(name: LintNames.sized_box_for_whitespace, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.sizedBoxForWhitespace;

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
    if (!isExactWidgetTypeContainer(node.staticType)) {
      return;
    }

    if (_shouldReportForArguments(node.argumentList)) {
      rule.reportAtNode(node.constructorName);
    }
  }

  /// Determine if the lint [rule] should be reported for
  /// the specified [argumentList].
  static bool _shouldReportForArguments(ArgumentList argumentList) {
    var hasChild = false;
    var hasHeight = false;
    var hasWidth = false;

    for (var argument in argumentList.arguments) {
      if (argument is! NamedExpression) {
        // Positional arguments are not supported.
        return false;
      }
      switch (argument.name.label.name) {
        case 'child':
          hasChild = true;
        case 'height':
          hasHeight = true;
        case 'width':
          hasWidth = true;
        case 'key':
          // Ignore 'key' as both SizedBox and Container have it.
          break;
        case _:
          // Other named arguments are not supported.
          return false;
      }
    }

    return hasChild && (hasWidth || hasHeight) || hasWidth && hasHeight;
  }
}
