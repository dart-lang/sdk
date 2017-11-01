// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Avoid empty statements.';

const _details = r'''

**AVOID** empty statments.

Empty statements almost always indicate a bug.

For example,

**BAD:**
```
if (complicated.expression.foo());
  bar();
```

Formatted with `dartfmt` the bug becomes obvious:

```
if (complicated.expression.foo()) ;
bar();

```

Better to avoid the empty statement altogether.

**GOOD:**
```
if (complicated.expression.foo())
  bar();
```

''';

class EmptyStatements extends LintRule {
  EmptyStatements()
      : super(
            name: 'empty_statements',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  final LintRule rule;
  Visitor(this.rule);

  @override
  visitEmptyStatement(EmptyStatement node) {
    rule.reportLint(node);
  }
}
