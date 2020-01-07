// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

const _desc = r'Avoid positional boolean parameters.';

const _details = r'''

**AVOID** positional boolean parameters.

Positional boolean parameters are a bad practice because they are very
ambiguous.  Using named boolean parameters is much more readable because it
inherently describes what the boolean value represents.

**BAD:**
```
Task(true);
Task(false);
ListBox(false, true, true);
Button(false);
```

**GOOD:**
```
Task.oneShot();
Task.repeating();
ListBox(scroll: true, showScrollbars: true);
Button(ButtonState.enabled);
```

''';

class AvoidPositionalBooleanParameters extends LintRule
    implements NodeLintRule {
  AvoidPositionalBooleanParameters()
      : super(
            name: 'avoid_positional_boolean_parameters',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this, context);
    registry.addCompilationUnit(this, visitor);
    registry.addConstructorDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (!node.declaredElement.isPrivate) {
      final parametersToLint =
          node.parameters?.parameters?.where(_isFormalParameterToLint);
      if (parametersToLint?.isNotEmpty == true) {
        rule.reportLint(parametersToLint.first);
      }
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (!node.declaredElement.isPrivate) {
      final parametersToLint = node.functionExpression.parameters?.parameters
          ?.where(_isFormalParameterToLint);
      if (parametersToLint?.isNotEmpty == true) {
        rule.reportLint(parametersToLint.first);
      }
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!node.isSetter &&
        !node.declaredElement.isPrivate &&
        !node.isOperator &&
        !DartTypeUtilities.hasInheritedMethod(node) &&
        !_isOverridingMember(node.declaredElement)) {
      final parametersToLint =
          node.parameters?.parameters?.where(_isFormalParameterToLint);
      if (parametersToLint?.isNotEmpty == true) {
        rule.reportLint(parametersToLint.first);
      }
    }
  }

  bool _isFormalParameterToLint(FormalParameter node) =>
      !node.isNamed &&
      DartTypeUtilities.isClass(node.declaredElement.type, 'bool', 'dart.core');

  bool _isOverridingMember(Element member) {
    if (member == null) {
      return false;
    }

    final classElement = member.thisOrAncestorOfType<ClassElement>();
    if (classElement == null) {
      return false;
    }
    final libraryUri = classElement.library.source.uri;
    return context.inheritanceManager.getInherited(
            classElement.thisType, Name(libraryUri, member.name)) !=
        null;
  }
}
