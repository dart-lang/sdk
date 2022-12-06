// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Declare visit methods for all registered node types.';

const _details = r'''
**DO** declare a visit method for all registered node processors.

**BAD:**
```dart
  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addFunctionTypeAlias(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
  
  class _Visitor {
    @override
    void visitFunctionDeclaration(FunctionDeclaration node) {
        // ...
    }
  }
```

**GOOD:**
**BAD:**
```dart
  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addFunctionTypeAlias(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
  
  class _Visitor {
    @override
    void visitFunctionDeclaration(FunctionDeclaration node) {
      // ...
    }
    
    @override
    void visitFunctionTypeAlias(FunctionTypeAlias node) {
      // ...
    }

    @override
    void visitMethodDeclaration(MethodDeclaration node) {
      // ...
    }
  }
```
''';

class VisitRegisteredNodes extends LintRule {
  VisitRegisteredNodes()
      : super(
            name: 'visit_registered_nodes',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _BodyVisitor extends RecursiveAstVisitor<void> {
  final LintRule rule;
  _BodyVisitor(this.rule);

  bool implements(ClassElement visitor, String methodName) {
    if (visitor.getMethod(methodName) != null) {
      return true;
    }

    var method =
        visitor.lookUpInheritedConcreteMethod(methodName, visitor.library);
    // In general lint visitors should only inherit from SimpleAstVisitors
    // (and the method implementations inherited from there are only stubs).
    // (We might consider enforcing this since it's harder to ensure that
    // Unifying and Generalizing visitors are doing the right thing.)
    // For now we flag methods inherited from SimpleAstVisitor since they
    // surely don't do anything.
    return method?.enclosingElement.name != 'SimpleAstVisitor';
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var targetType = node.target?.staticType;
    if (targetType is! InterfaceType) return;
    if (targetType.element.name != 'NodeLintRegistry') return;
    var methodName = node.methodName.name;
    if (!methodName.startsWith('add')) return;
    var nodeType = methodName.substring(3);
    var args = node.argumentList.arguments;
    var argType = args[1].staticType;
    if (argType is! InterfaceType) return;
    var visitor = argType.element;
    if (visitor is! ClassElement) return;
    if (implements(visitor, 'visit$nodeType')) return;

    rule.reportLint(node.methodName);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme == 'registerNodeProcessors') {
      node.body.accept(_BodyVisitor(rule));
    }
  }
}
