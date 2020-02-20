// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:meta/meta.dart';

import '../analyzer.dart';

const _desc = r'Avoid escaping inner quotes by converting surrounding quotes.';

const _details = r'''

Avoid escaping inner quotes by converting surrounding quotes.

**BAD:**
```
var s = 'It\'s not fun';
```

**GOOD:**
```
var s = "It's not fun";
```

''';

class AvoidEscapingInnerQuotes extends LintRule implements NodeLintRule {
  AvoidEscapingInnerQuotes()
      : super(
            name: 'avoid_escaping_inner_quotes',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = _Visitor(this);
    registry.addSimpleStringLiteral(this, visitor);
    registry.addStringInterpolation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (node.isRaw || node.isMultiline) return;

    if (isChangeable(node.value, isSingleQuoted: node.isSingleQuoted)) {
      rule.reportLint(node);
    }
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    if (node.isRaw || node.isMultiline) return;

    final text = node.elements
        .whereType<InterpolationString>()
        .map((e) => e.value)
        .reduce((a, b) => '$a$b');
    if (isChangeable(text, isSingleQuoted: node.isSingleQuoted)) {
      rule.reportLint(node);
    }
  }

  bool isChangeable(String text, {@required bool isSingleQuoted}) =>
      text.contains(isSingleQuoted ? "'" : '"') &&
      !text.contains(isSingleQuoted ? '"' : "'");
}
