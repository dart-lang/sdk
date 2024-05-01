// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/lint/linter.dart'; // ignore: implementation_imports

import '../analyzer.dart';
import '../extensions.dart';

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
    var visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.isConst) return;
    if (node.constructorName.type.isDeferred) return;

    var element = node.constructorName.staticElement;
    if (element == null) return;
    if (!element.isConst) return;

    // Handled by an analyzer warning.
    if (element.hasLiteral) return;

    var enclosingElement = element.enclosingElement;
    if (enclosingElement is ClassElement && enclosingElement.isDartCoreObject) {
      // Skip lint for `new Object()`, because it can be used for ID creation.
      return;
    }

    if (enclosingElement.typeParameters.isNotEmpty &&
        node.constructorName.type.typeArguments == null) {
      var approximateContextType = node.approximateContextType;
      var contextTypeAsInstanceOfEnclosing =
          approximateContextType?.asInstanceOf(enclosingElement);
      if (contextTypeAsInstanceOfEnclosing != null) {
        if (contextTypeAsInstanceOfEnclosing.typeArguments
            .any((e) => e is TypeParameterType)) {
          // The context type has type parameters, which may be substituted via
          // upward inference from the static type of `node`. Changing `node`
          // from non-const to const will affect inference to change its own
          // type arguments to `Never`, which affects that upward inference.
          // See https://github.com/dart-lang/linter/issues/4531.
          return;
        }
      }
    }

    if (node.canBeConst) {
      rule.reportLint(node);
    }
  }
}
