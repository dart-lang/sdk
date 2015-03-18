// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.empty_constructor_bodies;

import 'package:analyzer/src/generated/ast.dart';
import 'package:linter/src/linter.dart';

const desc = 'Use ; instead of {} for empty constructor bodies.';

const details =
'''
From the [style guide] (https://www.dartlang.org/articles/style-guide/):

**DO** use ; instead of {} for empty constructor bodies.

In Dart, a constructor with an empty body can be terminated with just a 
semicolon. This is required for const constructors. For consistency and 
brevity, other constructors should also do this.

**GOOD:**

```
class Point {
  int x, y;
  Point(this.x, this.y);
}
```

**BAD:**

```
class Point {
  int x, y;
  Point(this.x, this.y) {}
}
```
''';

class EmptyConstructorBodies extends LintRule {

  EmptyConstructorBodies()
      : super(
          name: 'empty_constructor_bodies',
          description: desc,
          details: details,
          group: Group.STYLE_GUIDE,
          kind: Kind.DO);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  LintRule rule;

  Visitor(this.rule);

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.body is BlockFunctionBody) {
      Block block = (node.body as BlockFunctionBody).block;
      if (block.statements.length == 0) {
        rule.reportLint(block);
      }
    }
  }
}
