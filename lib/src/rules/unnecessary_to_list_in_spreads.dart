// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Unnecessary toList() in spreads.';

const _details = r'''
Unnecessary `toList()` in spreads.

**BAD:**
```dart
children: <Widget>[
  ...['foo', 'bar', 'baz'].map((String s) => Text(s)).toList(),
]
```

**GOOD:**
```dart
children: <Widget>[
  ...['foo', 'bar', 'baz'].map((String s) => Text(s)),
]
```

''';

class UnnecessaryToListInSpreads extends LintRule {
  static const LintCode code = LintCode('unnecessary_to_list_in_spreads',
      "Unnecessary use of 'toList' in a spread.",
      correctionMessage: "Try removing the invocation of 'toList'.");

  UnnecessaryToListInSpreads()
      : super(
          name: 'unnecessary_to_list_in_spreads',
          description: _desc,
          details: _details,
          group: Group.style,
        );

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addSpreadElement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitSpreadElement(SpreadElement node) {
    var expression = node.expression;
    if (expression is! MethodInvocation) {
      return;
    }
    var target = expression.target;
    if (expression.methodName.name == 'toList' &&
        target != null &&
        target.staticType.implementsInterface('Iterable', 'dart.core')) {
      rule.reportLint(expression.methodName);
    }
  }
}
