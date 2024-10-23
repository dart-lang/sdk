// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Annotate overridden members.';

class AnnotateOverrides extends LintRule {
  AnnotateOverrides()
      : super(
          name: LintNames.annotate_overrides,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.annotate_overrides;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addFieldDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  void check(Element2? element, Token target) {
    if (element == null) return;
    if (element case Annotatable a when a.metadata2.hasOverride) return;

    var member = context.inheritanceManager.overriddenMember2(element);
    if (member != null) {
      rule.reportLintForToken(target, arguments: [member.name3!]);
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
