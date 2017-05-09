// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const desc = r'Only reference in scope identifiers in doc comments.';

const details = r'''
**DO** reference only in scope identifiers in doc comments.

If you surround things like variable, method, or type names in square brackets,
then [dartdoc](https://www.dartlang.org/effective-dart/documentation/) will look
up the name and link to its docs.  For this all to work, ensure that all
identifiers in docs wrapped in brackets are in scope.

For example,

**GOOD:**
```
/// Return the larger of [a] or [b].
int max_int(int a, int b) { ... }
```

On the other hand, assuming `outOfScopeId` is out of scope:

**BAD:**
```
void f(int outOfScopeId) { ... }
```
''';

class CommentReferences extends LintRule {
  CommentReferences()
      : super(
            name: 'comment_references',
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
  visitCommentReference(CommentReference node) {
    Identifier identifier = node.identifier;
    if (!identifier.isSynthetic && identifier.bestElement == null) {
      rule.reportLint(identifier);
    }
  }
}
