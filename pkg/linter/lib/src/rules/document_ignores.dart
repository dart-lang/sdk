// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/ignore_comments/ignore_info.dart' // ignore: implementation_imports
    show
        CommentTokenExtension,
        CompilationUnitExtension,
        IgnoredDiagnosticComment;
import 'package:analyzer/src/utilities/extensions/string.dart' // ignore: implementation_imports
    show IntExtension;

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Document ignore comments.';

class DocumentIgnores extends AnalysisRule {
  DocumentIgnores()
    : super(name: LintNames.document_ignores, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.documentIgnores;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    assert(context.currentUnit?.unit == node);
    var content = context.currentUnit?.content;
    for (var comment in node.ignoreComments) {
      var ignoredElements = comment.ignoredElements;
      if (ignoredElements.isEmpty) {
        continue;
      }
      if (ignoredElements.last is IgnoredDiagnosticComment) {
        // Some trailing text in `comment` documents this/these ignore(s).
        continue;
      }

      var ignoreCommentLine = node.lineInfo
          .getLocation(comment.offset)
          .lineNumber;
      if (ignoreCommentLine > 1) {
        // Only look at the line above if the ignore comment line is not the
        // first line.
        var previousLineOffset = node.lineInfo.getOffsetOfLine(
          ignoreCommentLine - 2,
        );
        if (content != null &&
            _startsWithEndOfLineComment(content, previousLineOffset)) {
          // A preceding comment, which may be attached to a different token,
          // documents this/these ignore(s). For example in:
          //
          // ```dart
          // // Text.
          // int x = 0; // ignore: unused_element
          // ```
          continue;
        }
      }

      rule.reportAtToken(comment);
    }
  }

  /// Returns whether [content] at [offset_] represents starts with optional
  /// whitespace and then an end-of-line comment (two slashes).
  bool _startsWithEndOfLineComment(String content, int offset_) {
    var offset = offset_;
    var length = content.length;
    while (offset < length) {
      if (!content.codeUnitAt(offset).isSpace) break;
      offset++;
    }
    if (offset + 1 >= length) return false;
    return content.codeUnitAt(offset) == 0x2F /* '/' */ &&
        content.codeUnitAt(offset + 1) == 0x2F /* '/' */;
  }
}
