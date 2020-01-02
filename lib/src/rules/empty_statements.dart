// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Avoid empty statements.';

const _details = r'''

**AVOID** empty statements.

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

class EmptyStatements extends LintRule implements NodeLintRule {
  EmptyStatements()
      : super(
            name: 'empty_statements',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addEmptyStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitEmptyStatement(EmptyStatement node) {
    rule.reportLint(node);
  }
}
