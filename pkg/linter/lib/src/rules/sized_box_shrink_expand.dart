// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
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

class SizedBoxShrinkExpand extends AnalysisRule {
  SizedBoxShrinkExpand()
    : super(
        name: LintNames.sized_box_shrink_expand,
        description: 'Use SizedBox shrink and expand named constructors.',
      );

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.sizedBoxShrinkExpand;

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
  final SizedBoxShrinkExpand rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Only interested in the default constructor for the SizedBox widget
    if (!isExactWidgetTypeSizedBox(node.staticType) ||
        node.constructorName.name != null) {
      return;
    }

    var data = _analyzeArguments(node.argumentList);
    if (data == null) {
      return;
    }

    if (data.width == 0 && data.height == 0) {
      rule.reportAtNode(node.constructorName, arguments: ['shrink']);
    } else if (data.width == double.infinity &&
        data.height == double.infinity) {
      rule.reportAtNode(node.constructorName, arguments: ['expand']);
    }
  }

  /// Determine the value of the arguments specified in the [argumentList],
  /// and return `null` if there are unsupported arguments.
  static ({double? height, double? width})? _analyzeArguments(
    ArgumentList argumentList,
  ) {
    double? height;
    double? width;

    for (var argument in argumentList.arguments) {
      if (argument is! NamedExpression) {
        // Positional arguments are not supported.
        return null;
      }

      switch (argument.name.label.name) {
        case 'width':
          width = argument.expression.argumentValue;
        case 'height':
          height = argument.expression.argumentValue;
      }
    }

    return (height: height, width: width);
  }
}

extension on Expression {
  double? get argumentValue {
    var self = this;
    return switch (self) {
      IntegerLiteral() => self.value?.toDouble(),
      DoubleLiteral() => self.value,
      PrefixedIdentifier(:var identifier, :var prefix)
          when identifier.name == 'infinity' && prefix.name == 'double' =>
        double.infinity,
      _ => null,
    };
  }
}
