// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: file_names
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r'Avoid calling `toString()` on `runtimeType`.';

class NoRuntimeTypeToString extends AnalysisRule {
  NoRuntimeTypeToString()
    : super(name: LintNames.no_runtimeType_toString, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.noRuntimetypeTostring;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addInterpolationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    if (!_isRuntimeTypeAccess(node.expression)) return;
    if (_canSkip(node)) return;

    rule.reportAtNode(node.expression);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'toString') return;
    if (!_isRuntimeTypeAccess(node.realTarget)) return;
    if (_canSkip(node)) return;

    rule.reportAtNode(node.methodName);
  }

  bool _canSkip(AstNode node) =>
      node.thisOrAncestorMatching((n) {
        if (n is Assertion) return true;
        if (n is ThrowExpression) return true;
        if (n is CatchClause) return true;
        if (n is MixinDeclaration) return true;
        if (n is ClassDeclaration && n.abstractKeyword != null) return true;
        if (n is ExtensionDeclaration) {
          var declaredElement = n.declaredFragment?.element;
          if (declaredElement != null) {
            var extendedType = declaredElement.extendedType;
            if (extendedType is InterfaceType) {
              var extendedElement = extendedType.element;
              return !(extendedElement is ClassElement &&
                  !extendedElement.isAbstract);
            }
          }
        }
        return false;
      }) !=
      null;

  bool _isRuntimeTypeAccess(Expression? target) =>
      target is PropertyAccess &&
          (target.target is ThisExpression ||
              target.target is SuperExpression) &&
          target.propertyName.name == 'runtimeType' ||
      target is SimpleIdentifier &&
          target.name == 'runtimeType' &&
          target.element is GetterElement;
}
