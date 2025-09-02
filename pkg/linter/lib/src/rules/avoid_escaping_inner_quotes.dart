// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r'Avoid escaping inner quotes by converting surrounding quotes.';

class AvoidEscapingInnerQuotes extends LintRule {
  AvoidEscapingInnerQuotes()
    : super(name: LintNames.avoid_escaping_inner_quotes, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.avoidEscapingInnerQuotes;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addSimpleStringLiteral(this, visitor);
    registry.addStringInterpolation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (node.isRaw || node.isMultiline) return;
    _check(node, node.value, node.isSingleQuoted);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    if (node.isRaw || node.isMultiline) return;

    var text = StringBuffer();
    for (var element in node.elements) {
      if (element is InterpolationString) {
        text.write(element.value);
      }
    }
    _check(node, text.toString(), node.isSingleQuoted);
  }

  void _check(AstNode node, String text, bool isSingleQuoted) {
    if (_isChangeable(text, isSingleQuoted: isSingleQuoted)) {
      rule.reportAtNode(
        node,
        arguments: [isSingleQuoted ? "'" : '"', isSingleQuoted ? '"' : "'"],
      );
    }
  }

  bool _isChangeable(String text, {required bool isSingleQuoted}) =>
      text.contains(isSingleQuoted ? "'" : '"') &&
      !text.contains(isSingleQuoted ? '"' : "'");
}
