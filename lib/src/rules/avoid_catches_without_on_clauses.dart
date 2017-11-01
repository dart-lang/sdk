// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Avoid catches without on clauses.';

const _details = r'''

**AVOID** catches without on clauses.

Using catch clauses without on clauses make your code prone to encountering
unexpected errors that won't be thrown (and thus will go unnoticed).

**BAD:**
```
try {
 somethingRisky()
}
catch(e) {
  doSomething(e);
}
```

**GOOD:**
```
try {
 somethingRisky()
}
on Exception catch(e) {
  doSomething(e);
}
```

''';

class AvoidCatchesWithoutOnClauses extends LintRule {
  _Visitor _visitor;
  AvoidCatchesWithoutOnClauses()
      : super(
            name: 'avoid_catches_without_on_clauses',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  visitCatchClause(CatchClause node) {
    if (node.onKeyword == null) {
      rule.reportLint(node);
    }
  }
}
