// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Avoid positional boolean parameters.';

const _details = r'''

**AVOID** positional boolean parameters.

Positional boolean parameters are a bad practice because they are very
ambiguous.  Using named boolean parameters is much more readable because it
inherently describes what the boolean value represents.

**BAD:**
```
new Task(true);
new Task(false);
new ListBox(false, true, true);
new Button(false);
```

**GOOD:**
```
new Task.oneShot();
new Task.repeating();
new ListBox(scroll: true, showScrollbars: true);
new Button(ButtonState.enabled);
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
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = new _Visitor(this);
    registry.addCompilationUnit(this, visitor);
    registry.addConstructorDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  InheritanceManager2 manager;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    LibraryElement library =
        resolutionMap.elementDeclaredByCompilationUnit(node)?.library;
    manager = library == null
        ? null
        : new InheritanceManager2(library.context.typeSystem);
  }

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
      DartTypeUtilities.implementsInterface(
          node.identifier.staticType, 'bool', 'dart.core') &&
      !node.isNamed;

  bool _isOverridingMember(Element member) {
    if (member == null || manager == null) {
      return false;
    }

    ClassElement classElement =
        member.getAncestor((element) => element is ClassElement);
    if (classElement == null) {
      return false;
    }
    Uri libraryUri = classElement.library.source.uri;
    return manager.getInherited(
            classElement.type, new Name(libraryUri, member.name)) !=
        null;
  }
}
