// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Prefer equal for default values.';

const _details = r'''

**DO** Use `=` to define default values.

**BAD:**
```
m({a: 1})
```

**GOOD:**
```
m({a = 1})
```

''';

class PreferEqualForDefaultValues extends LintRule {
  PreferEqualForDefaultValues()
      : super(
            name: 'prefer_equal_for_default_values',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  Visitor(this.rule);

  final LintRule rule;

  @override
  visitDefaultFormalParameter(DefaultFormalParameter node) {
    if (node.isNamed && node.separator?.type == TokenType.COLON) {
      rule.reportLintForToken(node.separator);
    }
  }
}
