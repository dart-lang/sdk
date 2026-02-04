// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
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

const _desc = r'Avoid JavaScript rounded ints.';

class AvoidJsRoundedInts extends AnalysisRule {
  AvoidJsRoundedInts()
    : super(name: LintNames.avoid_js_rounded_ints, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.avoidJsRoundedInts;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addIntegerLiteral(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  bool isRounded(int? value) => value?.toDouble().toInt() != value;
  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    if (isRounded(node.value)) {
      rule.reportAtNode(node);
    }
  }
}
