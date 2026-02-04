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
import '../diagnostic.dart' as diag;

const _desc = r'Use raw string to avoid escapes.';

class UseRawStrings extends AnalysisRule {
  UseRawStrings() : super(name: LintNames.use_raw_strings, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.useRawStrings;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addSimpleStringLiteral(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (node.isRaw) return;

    var lexeme = node.literal.lexeme.substring(
      node.contentsOffset - node.literal.offset,
      node.contentsEnd - node.literal.offset,
    );
    var hasEscape = false;
    for (var i = 0; i < lexeme.length - 1; i++) {
      var current = lexeme[i];
      if (current == r'\') {
        hasEscape = true;
        i += 1;
        current = lexeme[i];
        if (current != r'\' && current != r'$') {
          return;
        }
      }
    }
    if (hasEscape) {
      rule.reportAtNode(node);
    }
  }
}
