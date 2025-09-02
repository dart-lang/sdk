// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r'Use valid regular expression syntax.';

class ValidRegexps extends LintRule {
  ValidRegexps() : super(name: LintNames.valid_regexps, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.validRegexps;

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
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var element = node.constructorName.element?.enclosingElement;
    if (element == null) return;

    if (element.name == 'RegExp' && element.library.isDartCore) {
      var args = node.argumentList.arguments;
      if (args.isEmpty) return;

      bool isTrue(Expression e) => e is BooleanLiteral && e.value;

      var unicode = args.any(
        (arg) =>
            arg is NamedExpression &&
            arg.name.label.name == 'unicode' &&
            isTrue(arg.expression),
      );

      var sourceExpression = args.first;
      if (sourceExpression is StringLiteral) {
        var source = sourceExpression.stringValue;
        if (source != null) {
          try {
            RegExp(source, unicode: unicode);
          } on FormatException {
            rule.reportAtNode(sourceExpression);
          }
        }
      }
    }
  }
}
