// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Avoid using `as`.';

const _details = r'''

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

class AvoidAs extends LintRule implements NodeLintRule {
  AvoidAs()
      : super(
            name: 'avoid_as',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addAsExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitAsExpression(AsExpression node) {
    final typeAnnotation = node.type;
    if (typeAnnotation is NamedType && typeAnnotation.name.name != 'dynamic') {
      rule.reportLint(typeAnnotation);
    }
  }
}
