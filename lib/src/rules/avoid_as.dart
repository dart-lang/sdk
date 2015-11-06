// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.avoid_as;

import 'package:analyzer/src/generated/ast.dart'
    show AsExpression, AstVisitor, SimpleAstVisitor;
import 'package:linter/src/linter.dart';

const desc = r'Avoid using `as`.';

const details = r'''
From the [flutter style guide]
(https://github.com/flutter/engine/blob/master/sky/specs/style-guide.md):

**AVOID** using `as`.

If you know the type is correct, use an assertion or assign to a more
narrowly-typed variable (this avoids the type check in release mode; `as`
is not compiled out in release mode). If you don't know whether the type is
correct, check using `is` (this avoids the exception that `as` raises).

**BAD:**
```
try {
   (pm as Person).firstName = 'Seth';
} on CastError { }
```

**GOOD:**
```
Person person = pm;
person.firstName = 'Seth';
```
''';

class AvoidAs extends LintRule {
  AvoidAs()
      : super(
            name: 'avoid_as',
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
  visitAsExpression(AsExpression node) {
    rule.reportLint(node);
  }
}
