// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Use valid regular expression syntax.';

const _details = r'''

**DO** use valid regular expression syntax when creating regular expression
instances.

Regular expressions created with invalid syntax will throw a `FormatException`
at runtime so should be avoided.

**BAD:**
```
print(RegExp('(').hasMatch('foo()'));
```

**GOOD:**
```
print(RegExp('[(]').hasMatch('foo()'));
```

''';

class ValidRegExps extends LintRule implements NodeLintRule {
  ValidRegExps()
      : super(
            name: 'valid_regexps',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final element = node.staticElement?.enclosingElement;
    if (element?.name == 'RegExp' && element?.library?.name == 'dart.core') {
      final args = node.argumentList.arguments;
      if (args.isEmpty) {
        return;
      }

      final sourceExpression = args.first;
      if (sourceExpression is StringLiteral) {
        final source = sourceExpression.stringValue;
        if (source != null) {
          try {
            RegExp(source);
          } on FormatException {
            rule.reportLint(sourceExpression);
          }
        }
      }
    }
  }
}
