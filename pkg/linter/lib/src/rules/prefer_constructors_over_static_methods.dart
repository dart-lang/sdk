// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc =
    r'Prefer defining constructors instead of static methods to create instances.';

const _details = r'''
**PREFER** defining constructors instead of static methods to create instances.

In most cases, it makes more sense to use a named constructor rather than a
static method because it makes instantiation clearer.

**BAD:**
```dart
class Point {
  num x, y;
  Point(this.x, this.y);
  static Point polar(num theta, num radius) {
    return Point(radius * math.cos(theta),
        radius * math.sin(theta));
  }
}
```

**GOOD:**
```dart
class Point {
  num x, y;
  Point(this.x, this.y);
  Point.polar(num theta, num radius)
      : x = radius * math.cos(theta),
        y = radius * math.sin(theta);
}
```
''';

// TODO(pq): temporary; remove after renamed class is in the SDK
// ignore: non_constant_identifier_names
LintRule PreferConstructorsInsteadOfStaticMethods() =>
    PreferConstructorsOverStaticMethods();

bool _hasNewInvocation(DartType returnType, FunctionBody body) =>
    _BodyVisitor(returnType).containsInstanceCreation(body);

class PreferConstructorsOverStaticMethods extends LintRule {
  static const LintCode code = LintCode(
      'prefer_constructors_over_static_methods',
      'Static method should be a constructor.',
      correctionMessage: 'Try converting the method into a constructor.');

  PreferConstructorsOverStaticMethods()
      : super(
            name: 'prefer_constructors_over_static_methods',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _BodyVisitor extends RecursiveAstVisitor {
  bool found = false;

  final DartType returnType;
  _BodyVisitor(this.returnType);

  bool containsInstanceCreation(FunctionBody body) {
    body.accept(this);
    return found;
  }

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    found = node.staticType == returnType;
    if (!found) {
      super.visitInstanceCreationExpression(node);
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!node.isStatic) return;
    if (node.typeParameters != null) return;
    var returnType = node.returnType?.type;
    if (returnType is! InterfaceType) return;

    var interfaceType = node.parent.typeToCheckOrNull();
    if (interfaceType != null) {
      if (!context.typeSystem.isAssignableTo(returnType, interfaceType)) {
        return;
      }
      if (_hasNewInvocation(returnType, node.body)) {
        rule.reportLintForToken(node.name);
      }
    }
  }
}

extension on AstNode? {
  InterfaceType? typeToCheckOrNull() => switch (this) {
        ExtensionTypeDeclaration e =>
          e.typeParameters == null ? e.declaredElement?.thisType : null,
        ClassDeclaration c =>
          c.typeParameters == null ? c.declaredElement?.thisType : null,
        _ => null
      };
}
