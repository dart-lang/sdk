// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc = r'Only reference in-scope identifiers in doc comments.';

const _details = r'''
**DO** reference only in-scope identifiers in doc comments.

If you surround identifiers like variable, method, or type names in square
brackets, then tools like your IDE and
[`dart doc`](https://dart.dev/tools/dart-doc) can link to them. For this to
work, ensure that all identifiers in docs wrapped in brackets are in scope.

For example, assuming `outOfScopeId` is out of scope:

**BAD:**
```dart
/// Returns whether [value] is larger than [outOfScopeId].
bool isOutOfRange(int value) { ... }
```

**GOOD:**
```dart
/// Returns the larger of [a] or [b].
int max_int(int a, int b) { ... }
```

Note that the square bracket comment format is designed to allow comments to
refer to declarations using a fairly natural format but does not allow
*arbitrary expressions*.  In particular, code references within square brackets
can consist of any of the following:

- A bare identifier which is in-scope for the comment (see the spec for what is
  "in-scope" in doc comments). Examples include `[print]` and `[Future]`.
- Two identifiers separated by a period (a "prefixed identifier"), such that the
  first identifier acts as a namespacing identifier, such as a class property
  name or method name prefixed by the containing class's name, or a top-level
  identifier prefixed by an import prefix. Examples include `[Future.new]` (an
  unnamed constructor), `[Future.value]` (a constructor), `[Future.wait]` (a
  static method), `[Future.then]` (an instance method), `[math.max]` (given that
  'dart:async' is imported with a `max` prefix).
- A prefixed identifier followed by a pair of parentheses, used to disambiguate
  named constructors from instance members (whose names are allowed to collide).
  Examples include `[Future.value()]`.
- Three identifiers separated by two periods, such that the first identifier is
  an import prefix name, the second identifier is a top-level element like a
  class or an extension, and the third identifier is a member of that top-level
  element. Examples include `[async.Future.then]` (given that 'dart:async' is
  imported with an `async` prefix).

**Known limitations**

The `comment_references` lint rule aligns with the Dart analyzer's notion of
comment references, which is occasionally distinct from Dartdoc's notion of
comment references. The lint rule may report comment references which Dartdoc
can resolve, even though the analyzer cannot. See
[linter#1142](https://github.com/dart-lang/linter/issues/1142) for more
information.

''';

class CommentReferences extends LintRule {
  CommentReferences()
      : super(
            name: 'comment_references',
            description: _desc,
            details: _details,
            categories: {LintRuleCategory.documentationCommentMaintenance});

  @override
  LintCode get lintCode => LinterLintCode.comment_references;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addComment(this, visitor);
    registry.addCommentReference(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  static final _commentStartPattern = RegExp(r'^///+\s*$');

  final LintRule rule;

  /// Recognized Markdown link references (see
  /// https://spec.commonmark.org/0.31.2/#link-reference-definitions).
  final linkReferences = <String>[];

  _Visitor(this.rule);

  @override
  void visitComment(Comment node) {
    // Clear any link references of the previous comment.
    linkReferences.clear();

    // Check for keywords that are not treated as references by the parser
    // but should be reported.
    // Note that no special care is taken to handle embedded code blocks.
    // TODO(srawlins): Skip over code blocks, made available via
    // `Comment.codeBlocks`.
    for (var token in node.tokens) {
      if (token.isSynthetic) continue;

      var comment = token.lexeme;
      var referenceIndices = comment.referenceIndices(0);
      if (referenceIndices == null) continue;
      var (leftIndex, rightIndex) = referenceIndices;
      var prefix = comment.substring(0, leftIndex);
      if (_commentStartPattern.hasMatch(prefix)) {
        // Check for a Markdown [link reference
        // definition](https://spec.commonmark.org/0.31.2/#link-reference-definitions).
        var reference = comment.substring(leftIndex + 1, rightIndex);
        if (rightIndex + 1 < comment.length && comment[rightIndex + 1] == ':') {
          linkReferences.add(reference);
        }
      }

      while (referenceIndices != null) {
        (leftIndex, rightIndex) = referenceIndices;
        var reference = comment.substring(leftIndex + 1, rightIndex);
        if (_isParserSpecialCase(reference)) {
          var nameOffset = token.offset + leftIndex + 1;
          rule.reportLintForOffset(nameOffset, reference.length);
        }

        referenceIndices = comment.referenceIndices(rightIndex);
      }
    }
  }

  @override
  void visitCommentReference(CommentReference node) {
    if (node.isSynthetic) return;
    var expression = node.expression;
    if (expression.isSynthetic) return;

    if (expression is Identifier &&
        expression.staticElement == null &&
        !linkReferences.contains(expression.name)) {
      rule.reportLint(expression);
    } else if (expression is PropertyAccess &&
        expression.propertyName.staticElement == null) {
      var target = expression.target;
      if (target is PrefixedIdentifier) {
        var name = '${target.name}.${expression.propertyName.name}';
        if (!linkReferences.contains(name)) {
          rule.reportLint(expression);
        }
      }
    }
  }

  bool _isParserSpecialCase(String reference) =>
      reference == 'this' ||
      reference == 'null' ||
      reference == 'true' ||
      reference == 'false';
}

extension on String {
  /// Returns the first indices of a left and right bracket, if a left bracket
  /// is found before a right bracket in this [String], starting at [start], and
  /// `null` otherwise.
  (int, int)? referenceIndices(int start) {
    var leftIndex = indexOf('[', start);
    if (leftIndex < 0) return null;
    var rightIndex = indexOf(']', leftIndex);
    if (rightIndex < 0) return null;
    return (leftIndex, rightIndex);
  }
}
