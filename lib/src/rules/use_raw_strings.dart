// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Use raw string to avoid escapes.';

const _details = r'''

A raw string can be used to avoid escaping only backslashes and dollars.

**BAD:**
```
var s = 'A string with only \\ and \$';
```

**GOOD:**
```
var s = r'A string with only \ and $';
```

''';

class UseRawStrings extends LintRule implements NodeLintRule {
  UseRawStrings()
      : super(
            name: 'use_raw_strings',
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

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (node.isRaw) return;

    final lexeme = node.literal.lexeme.substring(
        node.contentsOffset - node.literal.offset,
        node.contentsEnd - node.literal.offset);
    var hasEscape = false;
    for (var i = 0; i < lexeme.length; i++) {
      var current = lexeme[i];
      if (current == r'\') {
        hasEscape = true;
        i += 1;
        current = lexeme[i];
        if (current != r'\' && current != r'$') {
          return;
        }
      }
    }
    if (hasEscape) {
      rule.reportLint(node);
    }
  }
}
