// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
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
import '../extensions.dart';

const _desc =
    r'Avoid defining a one-member abstract class when a simple function will do.';

class OneMemberAbstracts extends AnalysisRule {
  OneMemberAbstracts()
    : super(name: LintNames.one_member_abstracts, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.oneMemberAbstracts;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (node.abstractKeyword == null) return;
    if (node.extendsClause != null) return;

    if (node.isAugmentation) return;

    var element = node.declaredFragment?.element;
    if (element == null) return;

    if (element.interfaces.isNotEmpty) return;
    if (element.mixins.isNotEmpty) return;
    if (element.fields.isNotEmpty) return;

    var methods = element.methods;
    if (methods.length != 1) return;

    var method = methods.first;
    if (!method.isAbstract) return;

    var name = method.name;
    if (name == null) return;

    rule.reportAtToken(node.namePart.typeName, arguments: [name]);
  }
}
