// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../rules/control_flow_in_finally.dart';

const _desc = r'Avoid `throw` in `finally` block.';

class ThrowInFinally extends LintRule {
  ThrowInFinally()
    : super(name: LintNames.throw_in_finally, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.throw_in_finally;

  @override
  void registerNodeProcessors(NodeLintRegistry registry, RuleContext context) {
    var visitor = _Visitor(this);
    registry.addThrowExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void>
    with ControlFlowInFinallyBlockReporter {
  @override
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitThrowExpression(ThrowExpression node) {
    reportIfFinallyAncestorExists(node, kind: 'throw');
  }
}
