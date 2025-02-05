// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Use valid regular expression syntax.';

class ValidRegexps extends LintRule {
  ValidRegexps()
      : super(
          name: LintNames.valid_regexps,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.valid_regexps;

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
    var element = node.constructorName.element?.enclosingElement2;
    if (element == null) return;

    if (element.name3 == 'RegExp' && element.library2.isDartCore) {
      var args = node.argumentList.arguments;
      if (args.isEmpty) return;

      bool isTrue(Expression e) => e is BooleanLiteral && e.value;

      var unicode = args.any((arg) =>
          arg is NamedExpression &&
          arg.name.label.name == 'unicode' &&
          isTrue(arg.expression));

      var sourceExpression = args.first;
      if (sourceExpression is StringLiteral) {
        var source = sourceExpression.stringValue;
        if (source != null) {
          try {
            RegExp(source, unicode: unicode);
          } on FormatException {
            rule.reportLint(sourceExpression);
          }
        }
      }
    }
  }
}
