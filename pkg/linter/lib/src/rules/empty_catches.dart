// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
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
import '../util/ascii_utils.dart';

const _desc = r'Avoid empty catch blocks.';

class EmptyCatches extends AnalysisRule {
  EmptyCatches() : super(name: LintNames.empty_catches, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.emptyCatches;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addCatchClause(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitCatchClause(CatchClause node) {
    // Skip exceptions named with underscores.
    var exceptionParameter = node.exceptionParameter;
    if (exceptionParameter != null &&
        exceptionParameter.name.lexeme.isJustUnderscores) {
      return;
    }

    var body = node.body;
    if (node.body.statements.isEmpty &&
        body.rightBracket.precedingComments == null) {
      rule.reportAtNode(body);
    }
  }
}
