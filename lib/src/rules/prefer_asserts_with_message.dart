// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Prefer asserts with message.';

const _details = r'''

When assertions fail it's not always simple to understand why. Adding a message
to the `assert` helps the developer to understand why the AssertionError occurs.

**BAD:**
```
f(a) {
  assert(a != null);
}

class A {
  A(a) : assert(a != null);
}
```

**GOOD:**
```
f(a) {
  assert(a != null, 'a must not be null');
}

class A {
  A(a) : assert(a != null, 'a must not be null');
}
```

''';

class PreferAssertsWithMessage extends LintRule implements NodeLintRule {
  PreferAssertsWithMessage()
      : super(
            name: 'prefer_asserts_with_message',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addAssertInitializer(this, visitor);
    registry.addAssertStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitAssertInitializer(AssertInitializer node) {
    if (node.message == null) {
      rule.reportLint(node);
    }
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    if (node.message == null) {
      rule.reportLint(node);
    }
  }
}
