// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../extensions.dart';

const _desc = r"Don't override fields.";

class OverriddenFields extends AnalysisRule {
  OverriddenFields()
    : super(name: LintNames.overridden_fields, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.overriddenFields;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addFieldDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (node.isAugmentation) return;
    if (node.isStatic) return;

    for (var variable in node.fields.variables) {
      var parent = variable.declaredFragment?.element.enclosingElement;
      if (parent is InterfaceElement) {
        var overriddenMember = parent.getInheritedConcreteMember(
          Name(parent.library.uri, variable.name.lexeme),
        );
        if (overriddenMember is GetterElement &&
            overriddenMember.isOriginVariable) {
          var definingInterface = overriddenMember.enclosingElement;
          rule.reportAtToken(
            variable.name,
            arguments: [definingInterface.displayName],
          );
        }
      }
    }
  }
}
