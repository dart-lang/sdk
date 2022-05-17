// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

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
  UnnecessaryToListInSpreads()
      : super(
          name: 'unnecessary_to_list_in_spreads',
          description: _desc,
          details: _details,
          group: Group.style,
        );

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
    if (expression is MethodInvocation &&
        expression.methodName.name == 'toList' &&
        DartTypeUtilities.implementsInterface(
            expression.target?.staticType, 'Iterable', 'dart.core')) {
      rule.reportLint(expression.methodName);
    }
  }
}
