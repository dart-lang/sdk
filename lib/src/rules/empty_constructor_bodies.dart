// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Use `;` instead of `{}` for empty constructor bodies.';

const _details = r'''

From the [style guide](https://www.dartlang.org/articles/style-guide/):

**DO** use `;` instead of `{}` for empty constructor bodies.

In Dart, a constructor with an empty body can be terminated with just a
semicolon.  This is required for const constructors.  For consistency and
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
            description: _desc,
            details: _details,
            group: Group.style);

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
      if (block.statements.isEmpty) {
        if (block.endToken?.precedingComments == null) {
          rule.reportLint(block);
        }
      }
    }
  }
}
