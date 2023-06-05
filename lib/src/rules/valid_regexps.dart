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
```dart
print(RegExp(r'(').hasMatch('foo()'));
```

**GOOD:**
```dart
print(RegExp(r'\(').hasMatch('foo()'));
```

''';

class ValidRegexps extends LintRule {
  static const LintCode code = LintCode(
      'valid_regexps', 'Invalid regular expression syntax.',
      correctionMessage: 'Try correcting the regular expression.');

  ValidRegexps()
      : super(
            name: 'valid_regexps',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var element = node.constructorName.staticElement?.enclosingElement;
    if (element?.name == 'RegExp' && element?.library.name == 'dart.core') {
      var args = node.argumentList.arguments;
      if (args.isEmpty) {
        return;
      }

      bool isTrue(Expression e) => e is BooleanLiteral && e.value;

      var unicode = args.any((arg) =>
          arg is NamedExpression &&
          arg.name.label.name == 'unicode' &&
          isTrue(arg.expression));

      var sourceExpression = args.first;
      if (sourceExpression is StringLiteral) {
        var source = sourceExpression.stringValue;
        if (source != null) {
          try {
            RegExp(source, unicode: unicode);
          } on FormatException {
            rule.reportLint(sourceExpression);
          }
        }
      }
    }
  }
}
