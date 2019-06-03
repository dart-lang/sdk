// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Prefer const with constant constructors.';

const _details = r'''

**PREFER** using `const` for instantiating constant constructors.

If a const constructor is available, it is preferable to use it.

**GOOD:**
```
class A {
  const A();
}

void accessA() {
  A a = const A();
}
```

**GOOD:**
```
class A {
  final int x;

  const A(this.x);
}

A foo(int x) => new A(x);
```

**BAD:**
```
class A {
  const A();
}

void accessA() {
  A a = new A();
}
```

''';

class PreferConstConstructors extends LintRule implements NodeLintRule {
  PreferConstConstructors()
      : super(
            name: 'prefer_const_constructors',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = new _Visitor(this, context);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!node.isConst &&
        node.staticElement != null &&
        node.staticElement.isConst) {
      final typeProvider = context.typeProvider;

      if (node.staticElement.enclosingElement.type == typeProvider.objectType) {
        // Skip lint for `new Object()`, because it can be used for Id creation.
        return;
      }

      if (context.canBeConst(node)) {
        // A work-around to address: #1592; remove once fixed in analyzer.
        final collector = new _Collector();
        node.accept(collector);
        if (collector.foundTypeParamElement) {
          return;
        }
        rule.reportLint(node);
      }
    }
  }
}

class _Collector extends RecursiveAstVisitor<void> {
  bool foundTypeParamElement = false;
  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.staticElement is TypeParameterElement) {
      foundTypeParamElement = true;
    }
  }
}
