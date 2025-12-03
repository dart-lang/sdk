// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Prefer using mixins.';

class PreferMixin extends AnalysisRule {
  PreferMixin() : super(name: LintNames.prefer_mixin, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.preferMixin;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addWithClause(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitWithClause(WithClause node) {
    for (var mixinNode in node.mixinTypes) {
      var type = mixinNode.type;
      if (type is InterfaceType) {
        var element = type.element;
        if (element is MixinElement) continue;
        if (element is ClassElement && !element.isMixinClass) {
          rule.reportAtNode(mixinNode, arguments: [mixinNode.name.lexeme]);
        }
      }
    }
  }
}
