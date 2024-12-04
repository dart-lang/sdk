// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';

import '../analyzer.dart';

const _desc = r'Annotate redeclared members.';

class AnnotateRedeclares extends LintRule {
  AnnotateRedeclares()
      : super(
          name: LintNames.annotate_redeclares,
          description: _desc,
          state: State.experimental(),
        );

  @override
  LintCode get lintCode => LinterLintCode.annotate_redeclares;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addExtensionTypeDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    node.members.whereType<MethodDeclaration>().forEach(_check);
  }

  void _check(MethodDeclaration node) {
    if (node.isStatic) return;
    var parent = node.parent;
    // Shouldn't happen.
    if (parent is! ExtensionTypeDeclaration) return;

    var element = node.declaredFragment?.element;
    if (element == null || element.metadata2.hasRedeclare) return;

    var parentElement = parent.declaredFragment?.element;
    var extensionType = parentElement?.firstFragment.element;
    if (extensionType == null) return;

    if (_redeclaresMember(element, extensionType)) {
      rule.reportLintForToken(node.name, arguments: [element.displayName]);
    }
  }

  /// Return `true` if the [member] redeclares a member from a superinterface.
  bool _redeclaresMember(
      ExecutableElement2 member, InterfaceElement2 extensionType) {
    // TODO(pq): unify with similar logic in `redeclare_verifier` and move to inheritanceManager
    var interface = context.inheritanceManager.getInterface2(extensionType);
    var memberName = member.name3;
    return memberName != null &&
        interface.redeclared2
            .containsKey(Name.forLibrary(member.library2, memberName));
  }
}
