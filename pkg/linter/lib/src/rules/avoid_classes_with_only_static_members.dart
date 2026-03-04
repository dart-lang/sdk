// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
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

const _desc = r'Avoid defining a class that contains only static members.';

class AvoidClassesWithOnlyStaticMembers extends AnalysisRule {
  AvoidClassesWithOnlyStaticMembers()
    : super(
        name: LintNames.avoid_classes_with_only_static_members,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode => diag.avoidClassesWithOnlyStaticMembers;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var fragment = node.declaredFragment;
    if (fragment == null || fragment.isAugmentation) return;
    var element = fragment.element;
    if (element.isSealed) return;

    for (var member in element.interfaceMembers.values) {
      var enclosingElement = member.enclosingElement;
      if (enclosingElement is ClassElement &&
          !enclosingElement.isDartCoreObject) {
        return;
      }
    }

    var declaredElement = node.declaredFragment?.element;
    if (declaredElement == null) return;

    var constructors = declaredElement.constructors;
    if (constructors.isNotEmpty &&
        constructors.any((c) => !c.isDefaultConstructor)) {
      return;
    }

    var methods = declaredElement.methods;
    if (methods.isNotEmpty && !methods.every((m) => m.isStatic)) return;

    if (methods.isNotEmpty || declaredElement.fields.any((f) => !f.isConst)) {
      rule.reportAtToken(node.namePart.typeName);
    }
  }
}
