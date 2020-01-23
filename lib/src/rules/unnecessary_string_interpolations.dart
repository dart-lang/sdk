// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Unnecessary string interpolation.';

const _details = r'''

Don't use string interpolation if there's only a string expression in it.

**BAD:**
```
String message;
String o = '$message';
```

**GOOD:**
```
String message;
String o = message;
```

''';

class UnnecessaryStringInterpolations extends LintRule implements NodeLintRule {
  UnnecessaryStringInterpolations()
      : super(
            name: 'unnecessary_string_interpolations',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = _Visitor(this);
    registry.addStringInterpolation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitStringInterpolation(StringInterpolation node) {
    if (node.parent is AdjacentStrings) return;
    if (node.elements.length == 3) {
      final start = node.elements[0] as InterpolationString;
      final interpolation = node.elements[1] as InterpolationExpression;
      final end = node.elements[2] as InterpolationString;
      if (start.value.isEmpty && end.value.isEmpty) {
        if (interpolation.expression.staticType.isDartCoreString) {
          rule.reportLint(node);
        }
      }
    }
  }
}
