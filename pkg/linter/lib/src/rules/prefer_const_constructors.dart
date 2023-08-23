// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc = r'Prefer const with constant constructors.';

const _details = r'''
**PREFER** using `const` for instantiating constant constructors.

If a constructor can be invoked as const to produce a canonicalized instance,
it's preferable to do so.

**BAD:**
```dart
class A {
  const A();
}

void accessA() {
  A a = new A();
}
```

**GOOD:**
```dart
class A {
  const A();
}

void accessA() {
  A a = const A();
}
```

**GOOD:**
```dart
class A {
  final int x;

  const A(this.x);
}

A foo(int x) => new A(x);
```

''';

class PreferConstConstructors extends LintRule {
  static const LintCode code = LintCode('prefer_const_constructors',
      "Use 'const' with the constructor to improve performance.",
      correctionMessage:
          "Try adding the 'const' keyword to the constructor invocation.");

  PreferConstConstructors()
      : super(
            name: 'prefer_const_constructors',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.type.isDeferred) return;

    var element = node.constructorName.staticElement;
    if (element == null) return;

    if (element.isConst && !node.isConst) {
      // Handled by analyzer hint.
      if (element.hasLiteral) return;

      var enclosingElement = element.enclosingElement;
      if (enclosingElement is ClassElement &&
          enclosingElement.isDartCoreObject) {
        // Skip lint for `new Object()`, because it can be used for Id creation.
        return;
      }

      if (context.canBeConst(node)) {
        rule.reportLint(node);
      }
    }
  }
}
