// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

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

class UnnecessaryConst extends LintRule {
  static const LintCode code = LintCode(
      'unnecessary_const', "Unnecessary 'const' keyword.",
      correctionMessage: 'Try removing the keyword.');

  UnnecessaryConst()
      : super(
            name: 'unnecessary_const',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  bool get canUseParsedResult => true;

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addListLiteral(this, visitor);
    registry.addRecordLiteral(this, visitor);
    registry.addSetOrMapLiteral(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.keyword?.type != Keyword.CONST) return;

    if (node.inConstantContext) {
      rule.reportLint(node);
    }
  }

  @override
  void visitListLiteral(ListLiteral node) {
    if (node.unParenthesized.parent is ConstantPattern) return;
    _visitTypedLiteral(node);
  }

  @override
  void visitRecordLiteral(RecordLiteral node) {
    if (node.constKeyword == null) return;

    if (node.inConstantContext) {
      rule.reportLint(node);
    }
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    if (node.unParenthesized.parent is ConstantPattern) return;
    _visitTypedLiteral(node);
  }

  void _visitTypedLiteral(TypedLiteral node) {
    if (node.constKeyword?.type != Keyword.CONST) return;

    if (node.inConstantContext) {
      rule.reportLint(node);
    }
  }
}
