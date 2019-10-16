// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

const _desc =
    r'Prefer defining constructors instead of static methods to create instances.';

const _details = r'''

**PREFER** defining constructors instead of static methods to create instances.

In most cases, it makes more sense to use a named constructor rather than a
static method because it makes instantiation clearer.

**BAD:**
```
class Point {
  num x, y;
  Point(this.x, this.y);
  static Point polar(num theta, num radius) {
    return new Point(radius * math.cos(theta),
        radius * math.sin(theta));
  }
}
```

**GOOD:**
```
class Point {
  num x, y;
  Point(this.x, this.y);
  Point.polar(num theta, num radius)
      : x = radius * math.cos(theta),
        y = radius * math.sin(theta);
}
```

''';

bool _hasNewInvocation(DartType returnType, FunctionBody body) {
  bool _isInstanceCreationExpression(AstNode node) =>
      node is InstanceCreationExpression && node.staticType == returnType;

  return DartTypeUtilities.traverseNodesInDFS(body)
      .any(_isInstanceCreationExpression);
}

class PreferConstructorsInsteadOfStaticMethods extends LintRule
    implements NodeLintRule {
  PreferConstructorsInsteadOfStaticMethods()
      : super(
            name: 'prefer_constructors_over_static_methods',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final returnType = node.returnType?.type;
    final parent = node.parent;
    if (node.isStatic &&
        parent is ClassOrMixinDeclaration &&
        returnType is InterfaceType &&
        returnType.element == parent.declaredElement &&
        _hasNewInvocation(returnType, node.body)) {
      rule.reportLint(node.name);
    }
  }
}
