// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.type_init_formals;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const desc = "Don't type annotate initializing formals.";

const details = r'''
From the [style guide](https://www.dartlang.org/articles/style-guide/):

**DON'T** type annotate initializing formals.

If a constructor parameter is using `this`. to initialize a field, then the
type of the parameter is understood to be the same type as the field.

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
  Point(int this.x, int this.y);
}
```
''';

class TypeInitFormals extends LintRule {
  TypeInitFormals()
      : super(
            name: 'type_init_formals',
            description: desc,
            details: details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  LintRule rule;
  Visitor(this.rule);

  @override
  visitFieldFormalParameter(FieldFormalParameter node) {
    if (node.type != null) {
      rule.reportLint(node.type);
    }
  }
}
