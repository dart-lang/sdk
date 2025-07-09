// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Prefer `const` with constant constructors.';

class PreferConstConstructors extends LintRule {
  PreferConstConstructors()
    : super(name: LintNames.prefer_const_constructors, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.prefer_const_constructors;

  @override
  void registerNodeProcessors(NodeLintRegistry registry, RuleContext context) {
    var visitor = _Visitor(this);
    registry.addDotShorthandConstructorInvocation(this, visitor);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    if (node.isConst) return;

    var element = node.constructorName.element;
    if (element is! ConstructorElement) return;
    if (!element.isConst) return;

    // Handled by an analyzer warning.
    if (element.metadata.hasLiteral) return;

    var enclosingElement = element.enclosingElement;
    if (enclosingElement is ClassElement && enclosingElement.isDartCoreObject) {
      // Skip lint for `new Object()`, because it can be used for ID creation.
      return;
    }

    if (node.canBeConst) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.isConst) return;
    if (node.constructorName.type.isDeferred) return;

    var element = node.constructorName.element;
    if (element == null) return;
    if (!element.isConst) return;

    // Handled by an analyzer warning.
    if (element.metadata.hasLiteral) return;

    var enclosingElement = element.enclosingElement;
    if (enclosingElement is ClassElement && enclosingElement.isDartCoreObject) {
      // Skip lint for `new Object()`, because it can be used for ID creation.
      return;
    }

    if (enclosingElement.typeParameters2.isNotEmpty &&
        node.constructorName.type.typeArguments == null) {
      var approximateContextType = node.approximateContextType;
      var contextTypeAsInstanceOfEnclosing = approximateContextType
          ?.asInstanceOf(enclosingElement);
      if (contextTypeAsInstanceOfEnclosing != null) {
        if (contextTypeAsInstanceOfEnclosing.typeArguments.any(
          (e) => e is TypeParameterType,
        )) {
          // The context type has type parameters, which may be substituted via
          // upward inference from the static type of `node`. Changing `node`
          // from non-const to const will affect inference to change its own
          // type arguments to `Never`, which affects that upward inference.
          // See https://github.com/dart-lang/linter/issues/4531.
          return;
        }
      }
    }

    if (node.canBeConst) {
      rule.reportAtNode(node);
    }
  }
}
