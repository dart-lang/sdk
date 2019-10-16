// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Use `=` to separate a named parameter from its default value.';

const _details = r'''

From the [style guide](https://dart.dev/guides/language/effective-dart/usage):

**DO** Use `=` to separate a named parameter from its default value.

**BAD:**
```
m({a: 1})
```

**GOOD:**
```
m({a = 1})
```

''';

class PreferEqualForDefaultValues extends LintRule implements NodeLintRule {
  PreferEqualForDefaultValues()
      : super(
            name: 'prefer_equal_for_default_values',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addDefaultFormalParameter(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    if (node.isNamed && node.separator?.type == TokenType.COLON) {
      rule.reportLintForToken(node.separator);
    }
  }
}
