// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
// ignore: implementation_imports
import 'package:analyzer/src/ignore_comments/ignore_info.dart';
// ignore: implementation_imports
import 'package:analyzer/src/utilities/extensions/string.dart';

import '../analyzer.dart';

const _desc = r'Document ignore comments.';

const _details = r'''
**DO** document all ignored diagnostic reports.

**BAD:**
```dart
// ignore: unused_element
int _x = 1;
```

**GOOD:**
```dart
// This private field will be used later.
// ignore: unused_element
int _x = 1;
```

''';

class DocumentIgnores extends LintRule {
  static const LintCode code = LintCode(
    'document_ignores',
    'Missing documentation explaining why a diagnostic is ignored.',
    correctionMessage:
        'Try adding a comment immediately above the ignore comment.',
  );

  DocumentIgnores()
      : super(
            name: 'document_ignores',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    var content = node.declaredElement?.source.contents.data;
    for (var comment in node.ignoreComments) {
      var ignoredElements = comment.ignoredElements;
      if (ignoredElements.isEmpty) {
        continue;
      }
      if (ignoredElements.last is IgnoredDiagnosticComment) {
        // Some trailing text in `comment` documents this/these ignore(s).
        continue;
      }

      var ignoreCommentLine =
          node.lineInfo.getLocation(comment.offset).lineNumber;
      if (ignoreCommentLine > 1) {
        // Only look at the line above if the ignore comment line is not the
        // first line.
        var previousLineOffset =
            node.lineInfo.getOffsetOfLine(ignoreCommentLine - 2);
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

      rule.reportLintForToken(comment);
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
