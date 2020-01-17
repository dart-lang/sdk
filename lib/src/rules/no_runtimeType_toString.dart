// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc = r'Avoid calling toString() on runtimeType.';

const _details = r'''

Calling `toString` on a runtime type is a non-trivial operation that can
negatively impact performance. It's better to avoid it.

**BAD:**
```
class A {
  String toString() => '$runtimeType()';
}
```

**GOOD:**
```
class A {
  String toString() => 'A()';
}
```

This lint has some exceptions where performance is not a problem or where real
type information is more important than performance:

* in assertion
* in throw expressions
* in catch clauses
* in mixin declaration
* in abstract class

''';

class NoRuntimeTypeToString extends LintRule implements NodeLintRule {
  NoRuntimeTypeToString()
      : super(
            name: 'no_runtimeType_toString',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = _Visitor(this);
    registry.addInterpolationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_canSkip(node)) {
      return;
    }
    if (node.methodName.name == 'toString' &&
        _isRuntimeTypeAccess(node.realTarget)) {
      rule.reportLint(node.methodName);
    }
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    if (_canSkip(node)) {
      return;
    }
    if (_isRuntimeTypeAccess(node.expression)) {
      rule.reportLint(node.expression);
    }
  }

  bool _isRuntimeTypeAccess(Expression target) =>
      target is PropertyAccess &&
          (target.target is ThisExpression ||
              target.target is SuperExpression) &&
          target.propertyName.name == 'runtimeType' ||
      target is SimpleIdentifier &&
          target.name == 'runtimeType' &&
          target.staticElement is PropertyAccessorElement;

  bool _canSkip(AstNode node) =>
      node.thisOrAncestorMatching((n) {
        if (n is Assertion) return true;
        if (n is ThrowExpression) return true;
        if (n is CatchClause) return true;
        if (n is MixinDeclaration) return true;
        if (n is ClassDeclaration && n.isAbstract) return true;
        if (n is ExtensionDeclaration) {
          final extendedElement = n.declaredElement.extendedType.element;
          return !(extendedElement is ClassElement &&
              !extendedElement.isAbstract);
        }
        return false;
      }) !=
      null;
}
