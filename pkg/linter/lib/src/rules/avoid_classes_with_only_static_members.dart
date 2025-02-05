// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';

import '../analyzer.dart';

const _desc = r'Avoid defining a class that contains only static members.';

class AvoidClassesWithOnlyStaticMembers extends LintRule {
  AvoidClassesWithOnlyStaticMembers()
      : super(
          name: LintNames.avoid_classes_with_only_static_members,
          description: _desc,
        );

  @override
  LintCode get lintCode =>
      LinterLintCode.avoid_classes_with_only_static_members;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addClassDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var fragment = node.declaredFragment;
    if (fragment == null || fragment.isAugmentation) return;
    var element = fragment.element;
    if (element.isSealed) return;

    var interface = context.inheritanceManager.getInterface2(element);
    var map = interface.map2;
    for (var member in map.values) {
      var enclosingElement = member.enclosingElement2;
      if (enclosingElement is ClassElement2 &&
          !enclosingElement.isDartCoreObject) {
        return;
      }
    }

    var declaredElement = node.declaredFragment?.element;
    if (declaredElement == null) return;

    var constructors = declaredElement.constructors2;
    if (constructors.isNotEmpty &&
        constructors.any((c) => !c.isDefaultConstructor)) {
      return;
    }

    var methods = declaredElement.methods2;
    if (methods.isNotEmpty && !methods.every((m) => m.isStatic)) return;

    if (methods.isNotEmpty || declaredElement.fields2.any((f) => !f.isConst)) {
      rule.reportLint(node);
    }
  }
}
