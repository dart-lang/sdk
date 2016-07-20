// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.valid_regexps;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/linter.dart';

const desc = r'Use valid regular expression syntax.';

const details = r'''
**DO** use valid regular expression syntax when creating regular expression
instances.

Regular expressions created with invalid syntax will throw a `FormatException`
at runtime so should be avoided.

**BAD:**
```
print(new RegExp('(').hasMatch('foo()')); //u-oh
```

**GOOD:**
```
print(new RegExp('[(]').hasMatch('foo()')); //ok
```
''';

class ValidRegExps extends LintRule {
  ValidRegExps()
      : super(
            name: 'valid_regexps',
            description: desc,
            details: details,
            group: Group.errors);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  final LintRule rule;
  Visitor(this.rule);

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    ClassElement element = node.staticElement?.enclosingElement;
    if (element?.name == 'RegExp' && element?.library?.name == 'dart.core') {
      NodeList<Expression> args = node.argumentList.arguments;
      if (args.isEmpty) {
        return;
      }

      Expression sourceExpression = args.first;
      if (sourceExpression is StringLiteral) {
        String source = sourceExpression.stringValue;
        if (source != null) {
          try {
            new RegExp(source);
          } catch (_) {
            rule.reportLint(sourceExpression);
          }
        }
      }
    }
  }
}
