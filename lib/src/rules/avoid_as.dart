// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart'
    show AsExpression, AstNode, AstVisitor, NamedType;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Avoid using `as`.';

const _details = r'''

From the [flutter style guide](https://github.com/flutter/engine/blob/master/sky/specs/style-guide.md):

**AVOID** using `as`.

If you know the type is correct, use an assertion or assign to a more
narrowly-typed variable (this avoids the type check in release mode; `as` is not
compiled out in release mode).  If you don't know whether the type is
correct, check using `is` (this avoids the exception that `as` raises).

**BAD:**
```
(pm as Person).firstName = 'Seth';
```

**GOOD:**
```
Person person = pm;
person.firstName = 'Seth';
```

or

**GOOD:**
```
if (pm is Person)
  pm.firstName = 'Seth';
```

but certainly not

**BAD:**
```
try {
   (pm as Person).firstName = 'Seth';
} on CastError { }

```

Note that an exception is made in the case of `dynamic` since the cast has no
performance impact.

**OK:**
```
HasScrollDirection scrollable = renderObject as dynamic;
```

''';

class AvoidAs extends LintRule {
  AvoidAs()
      : super(
            name: 'avoid_as',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  final LintRule rule;
  Visitor(this.rule);

  @override
  visitAsExpression(AsExpression node) {
    // TODO(brianwilkerson) Use TypeAnnotation rather than AstNode below.
    AstNode typeAnnotation = node.type;
    if (typeAnnotation is NamedType && typeAnnotation.name.name != 'dynamic') {
      rule.reportLint(node);
    }
  }
}
