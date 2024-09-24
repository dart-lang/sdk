// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc = r"Don't implicitly reopen classes.";

class ImplicitReopen extends LintRule {
  ImplicitReopen()
      : super(
          name: 'implicit_reopen',
          description: _desc,
          state: State.experimental(),
        );

  @override
  LintCode get lintCode => LinterLintCode.implicit_reopen;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addClassTypeAlias(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  void checkElement(InterfaceElement? element, NamedCompilationUnitMember node,
      {required String type}) {
    if (element is! ClassElement) return;
    if (element.hasReopen) return;
    if (element.isSealed) return;
    if (element.isMixinClass) return;

    var library = element.library;
    var supertype = element.supertype?.element;
    if (supertype is! ClassElement) return;
    if (supertype.library != library) return;

    if (element.isBase) {
      if (supertype.isFinal) {
        reportLint(node,
            target: element, other: supertype, reason: 'final', type: type);
        return;
      } else if (supertype.isInterface) {
        reportLint(node,
            target: element, other: supertype, reason: 'interface', type: type);
        return;
      }
    } else if (element.hasNoModifiers) {
      if (supertype.isInterface) {
        reportLint(node,
            target: element, other: supertype, reason: 'interface', type: type);
        return;
      }
    }
  }

  void reportLint(
    NamedCompilationUnitMember member, {
    required String type,
    required InterfaceElement target,
    required InterfaceElement other,
    required String reason,
  }) {
    rule.reportLintForToken(member.name,
        arguments: [type, target.name, other.name, reason]);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    checkElement(node.declaredElement, node, type: 'class');
  }

  @override
  visitClassTypeAlias(ClassTypeAlias node) {
    checkElement(node.declaredElement, node, type: 'class');
  }
}

extension on ClassElement {
  bool get hasNoModifiers => !isInterface && !isBase && !isSealed && !isFinal;
}
