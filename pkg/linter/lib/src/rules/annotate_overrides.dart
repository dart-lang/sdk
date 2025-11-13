// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../extensions.dart';

const _desc = r'Annotate overridden members.';

class AnnotateOverrides extends AnalysisRule {
  AnnotateOverrides()
    : super(name: LintNames.annotate_overrides, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.annotateOverrides;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addFieldDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  void check(Element? element, Token target) {
    if (element == null) return;
    if (element.metadata.hasOverride) return;

    var member = element.overriddenMember;
    if (member != null) {
      rule.reportAtToken(target, arguments: [member.name!]);
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (node.isAugmentation) return;
    if (node.isStatic) return;
    if (node.parent is ExtensionTypeDeclaration) return;

    for (var field in node.fields.variables) {
      check(field.declaredFragment?.element, field.name);
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isAugmentation) return;
    if (node.isStatic) return;
    if (node.parent is ExtensionTypeDeclaration) return;

    check(node.declaredFragment?.element, node.name);
  }
}
