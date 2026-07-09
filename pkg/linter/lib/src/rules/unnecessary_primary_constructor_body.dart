// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Unnecessary primary constructor bodies can be removed.';

class UnnecessaryPrimaryConstructorBody extends AnalysisRule {
  new()
    : super(
        name: LintNames.unnecessary_primary_constructor_body,
        description: _desc,
        state: .stable(since: .new(3, 13, 0)),
      );

  @override
  DiagnosticCode get diagnosticCode => diag.unnecessaryPrimaryConstructorBody;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context.typeSystem);
    registry.addPrimaryConstructorBody(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final TypeSystem typeSystem;

  new(this.rule, this.typeSystem);

  @override
  void visitPrimaryConstructorBody(PrimaryConstructorBody node) {
    var body = node.body;
    if (node.metadata.isNotEmpty) return;
    if (node.documentationComment != null) return;
    if (node.initializers.isNotEmpty) return;

    if (body is EmptyFunctionBody) {
      rule.reportAtToken(node.thisKeyword);
    } else if (body is BlockFunctionBody && body.block.statements.isEmpty) {
      rule.reportAtToken(node.thisKeyword);
    }
  }
}
