// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Only reference in scope identifiers in doc comments.';

const _details = r'''

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
  visitComment(Comment node) {
    // Check for keywords that are not treated as references by the parser
    // but should be flagged by the linter.
    // Note that no special care is taken to handle embedded code blocks.
    for (Token token in node.tokens) {
      if (!token.isSynthetic) {
        String comment = token.lexeme;
        int leftIndex = comment.indexOf('[');
        while (leftIndex >= 0) {
          int rightIndex = comment.indexOf(']', leftIndex);
          if (rightIndex >= 0) {
            String reference = comment.substring(leftIndex + 1, rightIndex);
            if (_isParserSpecialCase(reference)) {
              int nameOffset = token.offset + leftIndex + 1;
              rule.reporter.reportErrorForOffset(
                  rule.lintCode, nameOffset, reference.length);
            }
          }
          leftIndex = rightIndex < 0 ? -1 : comment.indexOf('[', rightIndex);
        }
      }
    }
  }

  @override
  visitCommentReference(CommentReference node) {
    Identifier identifier = node.identifier;
    if (!identifier.isSynthetic && identifier.bestElement == null) {
      rule.reportLint(identifier);
    }
  }

  bool _isParserSpecialCase(String reference) =>
      reference == 'this' ||
      reference == 'null' ||
      reference == 'true' ||
      reference == 'false';
}
