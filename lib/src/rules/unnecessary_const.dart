// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/ast/ast.dart';

import '../analyzer.dart';

const _desc = r'Avoid const keyword.';

const _details = r'''

**AVOID** repeating const keyword in a const context.

**BAD:**
```dart
class A { const A(); }
m(){
  const a = const A();
  final b = const [const A()];
}
```

**GOOD:**
```dart
class A { const A(); }
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
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addListLiteral(this, visitor);
    registry.addSetOrMapLiteral(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.keyword?.type != Keyword.CONST) return;

    // todo (pq): remove cast when `inConstantContext` is public on Expression
    if ((node as ExpressionImpl).inConstantContext) {
      rule.reportLint(node);
    }
  }

  @override
  void visitListLiteral(ListLiteral node) => _visitTypedLiteral(node);

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _visitTypedLiteral(node);
  }

  void _visitTypedLiteral(TypedLiteral node) {
    if (node.constKeyword?.type != Keyword.CONST) return;

    // todo (pq): remove cast when `inConstantContext` is public on Expression
    if ((node as ExpressionImpl).inConstantContext) {
      rule.reportLint(node);
    }
  }
}
