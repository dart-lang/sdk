// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc =
    r'Avoid defining a one-member abstract class when a simple function will do.';

class OneMemberAbstracts extends LintRule {
  OneMemberAbstracts()
      : super(
          name: LintNames.one_member_abstracts,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.one_member_abstracts;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (node.abstractKeyword == null) return;
    if (node.extendsClause != null) return;

    if (node.macroKeyword != null) return;
    if (node.isAugmentation) return;

    var element = node.declaredFragment?.element;
    if (element == null) return;

    if (element.interfaces.isNotEmpty) return;
    if (element.mixins.isNotEmpty) return;
    if (element.fields2.isNotEmpty) return;

    var methods = element.methods2;
    if (methods.length != 1) return;

    var method = methods.first;
    if (method.isAbstract) {
      rule.reportLintForToken(node.name, arguments: [method.name]);
    }
  }
}
