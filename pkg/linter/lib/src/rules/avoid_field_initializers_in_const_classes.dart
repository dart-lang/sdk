// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Avoid field initializers in const classes.';

class AvoidFieldInitializersInConstClasses extends LintRule {
  AvoidFieldInitializersInConstClasses()
      : super(
          name: LintNames.avoid_field_initializers_in_const_classes,
          description: _desc,
        );

  @override
  LintCode get lintCode =>
      LinterLintCode.avoid_field_initializers_in_const_classes;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addFieldDeclaration(this, visitor);
    registry.addConstructorFieldInitializer(this, visitor);
  }
}

class HasParameterReferenceVisitor extends RecursiveAstVisitor<void> {
  Iterable<FormalParameterElement?> parameters;

  bool useParameter = false;

  HasParameterReferenceVisitor(
      Iterable<FormalParameterFragment?> fragmentParameters)
      : parameters = fragmentParameters.map((p) => p?.element);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (parameters.contains(node.element)) {
      useParameter = true;
    } else {
      super.visitSimpleIdentifier(node);
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    var declaration = node.parent;
    if (declaration is ConstructorDeclaration) {
      if (declaration.constKeyword == null) return;
      var classDecl = declaration.thisOrAncestorOfType<ClassDeclaration>();
      if (classDecl == null) return;

      var element = classDecl.declaredFragment?.element;
      if (element == null) return;

      // no lint if several constructors
      if (element.constructors2.length > 1) return;

      var visitor = HasParameterReferenceVisitor(
          declaration.parameters.parameterFragments);
      node.expression.accept(visitor);
      if (!visitor.useParameter) {
        rule.reportLint(node);
      }
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (node.isAugmentation) return;
    if (node.isStatic) return;
    if (!node.fields.isFinal) return;
    // only const class
    var parent = node.parent;
    if (parent is ClassDeclaration) {
      var declaredElement = parent.declaredFragment?.element;
      if (declaredElement == null) return;

      if (declaredElement.constructors2.every((e) => !e.isConst)) {
        return;
      }
      for (var variable in node.fields.variables) {
        if (variable.initializer != null) {
          rule.reportLint(variable);
        }
      }
    }
  }
}
