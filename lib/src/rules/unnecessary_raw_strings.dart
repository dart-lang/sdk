// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Unnecessary raw string.';

const _details = r'''

Use raw string only when needed.

**BAD:**
```
var s1 = r'a';
```

**GOOD:**
```
var s1 = 'a';
var s2 = r'$a';
var s3 = r'\a';
```

''';

class UnnecessaryRawStrings extends LintRule implements NodeLintRule {
  UnnecessaryRawStrings()
      : super(
            name: 'unnecessary_raw_strings',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = _Visitor(this);
    registry.addSimpleStringLiteral(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (node.isRaw && ![r'\', r'$'].any(node.literal.lexeme.contains)) {
      rule.reportLint(node);
    }
  }
}
