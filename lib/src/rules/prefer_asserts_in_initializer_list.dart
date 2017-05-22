// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.prefer_const_constructors_in_immutables;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart' show AstVisitor;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const desc = 'Prefer put asserts in initializer list.';

const details = '''
**DO** put asserts in initializer list for constructors with only asserts in
their body.

**GOOD:**
```
class A {
  A(int a) : assert(a != null);
}
```

**BAD:**
```
class A {
  A(int a) {
    assert(a != null);
  }
}
```
''';

class PreferAssertsInInitializerList extends LintRule {
  PreferAssertsInInitializerList()
      : super(
            name: 'prefer_asserts_in_initializer_list',
            description: desc,
            details: details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  final LintRule rule;

  Visitor(this.rule);

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    final body = node.body;
    if (body is BlockFunctionBody &&
        body.block.statements.isNotEmpty &&
        body.block.statements.every((s) => s is AssertStatement)) {
      rule.reportLintForToken(body.beginToken);
    }
  }
}
