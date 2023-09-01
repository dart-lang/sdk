// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: file_names
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = r'Avoid calling toString() on runtimeType.';

const _details = r'''
Calling `toString` on a runtime type is a non-trivial operation that can
negatively impact performance. It's better to avoid it.

**BAD:**
```dart
class A {
  String toString() => '$runtimeType()';
}
```

**GOOD:**
```dart
class A {
  String toString() => 'A()';
}
```

This lint has some exceptions where performance is not a problem or where real
type information is more important than performance:

* in an assertion
* in a throw expression
* in a catch clause
* in a mixin declaration
* in an abstract class declaration

''';

class NoRuntimeTypeToString extends LintRule {
  static const LintCode code = LintCode('no_runtimeType_toString',
      "Using 'toString' on a 'Type' is not safe in production code.");

  NoRuntimeTypeToString()
      : super(
            name: 'no_runtimeType_toString',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addInterpolationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    if (!_isRuntimeTypeAccess(node.expression)) return;
    if (_canSkip(node)) return;

    rule.reportLint(node.expression);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'toString') return;
    if (!_isRuntimeTypeAccess(node.realTarget)) return;
    if (_canSkip(node)) return;

    rule.reportLint(node.methodName);
  }

  bool _canSkip(AstNode node) =>
      node.thisOrAncestorMatching((n) {
        if (n is Assertion) return true;
        if (n is ThrowExpression) return true;
        if (n is CatchClause) return true;
        if (n is MixinDeclaration) return true;
        if (n is ClassDeclaration && n.abstractKeyword != null) return true;
        if (n is ExtensionDeclaration) {
          var declaredElement = n.declaredElement;
          if (declaredElement != null) {
            var extendedType = declaredElement.extendedType;
            if (extendedType is InterfaceType) {
              var extendedElement = extendedType.element;
              return !(extendedElement is ClassElement &&
                  !extendedElement.isAbstract);
            }
          }
        }
        return false;
      }) !=
      null;

  bool _isRuntimeTypeAccess(Expression? target) =>
      target is PropertyAccess &&
          (target.target is ThisExpression ||
              target.target is SuperExpression) &&
          target.propertyName.name == 'runtimeType' ||
      target is SimpleIdentifier &&
          target.name == 'runtimeType' &&
          target.staticElement is PropertyAccessorElement;
}
