// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Avoid const keyword.';

const _details = r'''

**AVOID** repeating const keyword in a const context.

**BAD:**
```
class A() { const A(); }
m(){
  const a = const A();
  final b = const [const A()];
}
```

**GOOD:**
```
class A() { const A(); }
m(){
  const a = A();
  final b = const [A()];
}
```

''';

class UnnecessaryConst extends LintRule implements NodeLintRule {
  UnnecessaryConst()
      : super(
            name: 'unnecessary_const',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry) {
    final visitor = new _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addListLiteral(this, visitor);
    registry.addMapLiteral(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.keyword == null) return;

    // remove keyword and check if there's const error
    final oldKeyword = node.keyword;
    node.keyword = null;
    final isConstWithoutKeyword = node.isConst;
    node.keyword = oldKeyword;

    if (isConstWithoutKeyword && node.keyword.type == Keyword.CONST) {
      rule.reportLint(node);
    }
  }

  @override
  visitListLiteral(ListLiteral node) => _visitTypedLiteral(node);

  @override
  visitMapLiteral(MapLiteral node) => _visitTypedLiteral(node);

  _visitTypedLiteral(TypedLiteral node) {
    if (node.constKeyword == null) return;

    // remove keyword and check if there's const error
    final oldKeyword = node.constKeyword;
    node.constKeyword = null;
    final isConstWithoutKeyword = node.isConst;
    node.constKeyword = oldKeyword;

    if (isConstWithoutKeyword && node.constKeyword.type == Keyword.CONST) {
      rule.reportLint(node);
    }
  }
}
