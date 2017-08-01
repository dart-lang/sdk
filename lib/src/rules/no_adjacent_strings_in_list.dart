// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const desc = 'Do not use adjacent strings in list.';

const details = r'''
**DO NOT** use adjacent strings in list. This can be
sign of forgotten comma.

**GOOD:**

```
List<String> list = <String>[
  'a' +
  'b',
  'c',
];
```

**BAD:**

```
List<String> list = <String>[
  'a'
  'b',
  'c',
];
```
''';

class NoAdjacentStringsInList extends LintRule {
  NoAdjacentStringsInList()
      : super(
            name: 'no_adjacent_strings_in_list',
            description: desc,
            details: details,
            group: Group.errors);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  LintRule rule;

  Visitor(this.rule);

  @override
  void visitListLiteral(ListLiteral node) {
    node.elements.forEach((Expression e) {
      if (e is AdjacentStrings) {
        rule.reportLint(e);
      }
    });
  }
}
