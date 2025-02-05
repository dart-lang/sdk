// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Only reference in-scope identifiers in doc comments.';

class CommentReferences extends LintRule {
  CommentReferences()
      : super(
          name: LintNames.comment_references,
          description: _desc,
        );

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
        expression.element == null &&
        !linkReferences.contains(expression.name)) {
      rule.reportLint(expression);
    } else if (expression is PropertyAccess &&
        expression.propertyName.element == null) {
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
