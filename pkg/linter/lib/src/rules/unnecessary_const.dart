// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Avoid `const` keyword.';

class UnnecessaryConst extends AnalysisRule {
  UnnecessaryConst()
    : super(name: LintNames.unnecessary_const, description: _desc);

  @override
  bool get canUseParsedResult => true;

  @override
  DiagnosticCode get diagnosticCode => diag.unnecessaryConst;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addDotShorthandConstructorInvocation(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addListLiteral(this, visitor);
    registry.addRecordLiteral(this, visitor);
    registry.addSetOrMapLiteral(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  _Visitor(this.rule);

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    var constKeyword = node.constKeyword;
    if (constKeyword == null) return;
    if (node.inConstantContext) {
      rule.reportAtToken(constKeyword);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var keyword = node.keyword;
    if (keyword == null || keyword.type != Keyword.CONST) return;

    if (node.inConstantContext) {
      rule.reportAtToken(keyword);
    }
  }

  @override
  void visitListLiteral(ListLiteral node) {
    if (node.unParenthesized.parent is ConstantPattern) return;
    _visitTypedLiteral(node);
  }

  @override
  void visitRecordLiteral(RecordLiteral node) {
    var constKeyword = node.constKeyword;
    if (constKeyword == null) return;

    if (node.inConstantContext) {
      rule.reportAtToken(constKeyword);
    }
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    if (node.unParenthesized.parent is ConstantPattern) return;
    _visitTypedLiteral(node);
  }

  void _visitTypedLiteral(TypedLiteral node) {
    var constKeyword = node.constKeyword;
    if (constKeyword == null || constKeyword.type != Keyword.CONST) return;

    if (node.inConstantContext) {
      rule.reportAtToken(constKeyword);
    }
  }
}
