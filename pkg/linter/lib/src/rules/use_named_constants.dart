// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
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

const _desc = r'Use predefined named constants.';

class UseNamedConstants extends AnalysisRule {
  UseNamedConstants()
    : super(name: LintNames.use_named_constants, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.useNamedConstants;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.isConst) {
      var type = node.staticType;
      if (type is! InterfaceType) return;
      var element = type.element;
      if (element is ClassElement) {
        var nodeField = node
            .thisOrAncestorOfType<VariableDeclaration>()
            ?.declaredFragment
            ?.element;

        // avoid diagnostic for fields in the same class having the same value
        // class A {
        //   const A();
        //   static const a = A();
        //   static const b = A();
        // }
        if (nodeField?.enclosingElement == element) return;

        var library =
            (node.root as CompilationUnit).declaredFragment?.element.library;
        if (library == null) return;
        var value = node.computeConstantValue()?.value;
        for (var field in element.fields.where(
          (e) => e.isStatic && e.isConst,
        )) {
          if (field.isAccessibleIn(library) &&
              field.computeConstantValue() == value) {
            rule.reportAtNode(
              node,
              arguments: ['${element.name}.${field.name}'],
            );
            return;
          }
        }
      }
    }
  }
}
