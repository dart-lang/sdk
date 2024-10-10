// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: file_names
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = r'Avoid calling `toString()` on `runtimeType`.';

class NoRuntimeTypeToString extends LintRule {
  NoRuntimeTypeToString()
      : super(
          name: LintNames.no_runtimeType_toString,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.no_runtimeType_toString;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addInterpolationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    if (!_isRuntimeTypeAccess(node.expression)) return;
    if (_canSkip(node)) return;

    rule.reportLint(node.expression);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'toString') return;
    if (!_isRuntimeTypeAccess(node.realTarget)) return;
    if (_canSkip(node)) return;

    rule.reportLint(node.methodName);
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
              var extendedElement = extendedType.element3;
              return !(extendedElement is ClassElement2 &&
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
