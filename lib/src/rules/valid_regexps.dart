// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Use valid regular expression syntax.';

const _details = r'''

**DO** use valid regular expression syntax when creating regular expression
instances.

Regular expressions created with invalid syntax will throw a `FormatException`
at runtime so should be avoided.

**BAD:**
```
print(new RegExp('(').hasMatch('foo()'));
```

**GOOD:**
```
print(new RegExp('[(]').hasMatch('foo()'));
```

''';

class ValidRegExps extends LintRule {
  ValidRegExps()
      : super(
            name: 'valid_regexps',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  final LintRule rule;
  Visitor(this.rule);

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    ClassElement element = resolutionMap
        .staticElementForConstructorReference(node)
        ?.enclosingElement;
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
          } on FormatException {
            rule.reportLint(sourceExpression);
          }
        }
      }
    }
  }
}
