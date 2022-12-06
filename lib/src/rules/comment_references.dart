// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Only reference in scope identifiers in doc comments.';

const _details = r'''
**DO** reference only in scope identifiers in doc comments.

If you surround things like variable, method, or type names in square brackets,
then [`dart doc`](https://dart.dev/tools/dart-doc) will look
up the name and link to its docs.  For this all to work, ensure that all
identifiers in docs wrapped in brackets are in scope.

For example, assuming `outOfScopeId` is out of scope:

**BAD:**
```dart
/// Return true if [value] is larger than [outOfScopeId].
bool isOutOfRange(int value) { ... }
```

**GOOD:**
```dart
/// Return the larger of [a] or [b].
int max_int(int a, int b) { ... }
```

Note that the square bracket comment format is designed to allow
comments to refer to declarations using a fairly natural format
but does not allow *arbitrary expressions*.  In particular, code
references within square brackets can consist of either

- a single identifier where the identifier is any identifier in scope for the comment (see the spec for what is in scope in doc comments),
- two identifiers separated by a period where the first identifier is the name of a class that is in scope and the second is the name of a member declared in the class,
- a single identifier followed by a pair of parentheses where the identifier is the name of a class that is in scope (used to refer to the unnamed constructor for the class), or
- two identifiers separated by a period and followed by a pair of parentheses where the first identifier is the name of a class that is in scope and the second is the name of a named constructor (not strictly necessary, but allowed for consistency).

''';

class CommentReferences extends LintRule {
  static const LintCode code = LintCode(
      'comment_references', "The referenced name isn't visible in scope.",
      correctionMessage: 'Try adding an import for the referenced name.');

  CommentReferences()
      : super(
            name: 'comment_references',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addComment(this, visitor);
    registry.addCommentReference(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final links = <String>[];

  _Visitor(this.rule);

  @override
  void visitComment(Comment node) {
    // clear links of previous comments
    links.clear();

    // Check for keywords that are not treated as references by the parser
    // but should be flagged by the linter.
    // Note that no special care is taken to handle embedded code blocks.
    for (var token in node.tokens) {
      if (!token.isSynthetic) {
        var comment = token.lexeme;
        var leftIndex = comment.indexOf('[');
        while (leftIndex >= 0) {
          var rightIndex = comment.indexOf(']', leftIndex);
          if (rightIndex >= 0) {
            var reference = comment.substring(leftIndex + 1, rightIndex);
            if (_isParserSpecialCase(reference)) {
              var nameOffset = token.offset + leftIndex + 1;
              rule.reporter.reportErrorForOffset(
                  rule.lintCode, nameOffset, reference.length);
            }
            if (rightIndex + 1 < comment.length &&
                comment[rightIndex + 1] == ':') {
              links.add(reference);
            }
          }
          leftIndex = rightIndex < 0 ? -1 : comment.indexOf('[', rightIndex);
        }
      }
    }
  }

  @override
  void visitCommentReference(CommentReference node) {
    var expression = node.expression;
    if (expression.isSynthetic) return;
    if (expression is Identifier &&
        expression.staticElement == null &&
        !links.contains(expression.name)) {
      rule.reportLint(expression);
    }
  }

  bool _isParserSpecialCase(String reference) =>
      reference == 'this' ||
      reference == 'null' ||
      reference == 'true' ||
      reference == 'false';
}
