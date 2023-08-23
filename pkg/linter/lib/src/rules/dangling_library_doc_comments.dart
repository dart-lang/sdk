// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Attach library doc comments to library directives.';

const _details = r'''
Attach library doc comments (with `///`) to library directives, rather than
leaving them dangling near the top of a library.

**BAD:**
```dart
/// This is a great library.
import 'package:math';
```

```dart
/// This is a great library.

class C {}
```

**GOOD:**
```dart
/// This is a great library.
library;

import 'package:math';

class C {}
```

**NOTE:** An unnamed library, like `library;` above, is only supported in Dart
2.19 and later. Code which might run in earlier versions of Dart will need to
provide a name in the `library` directive.
''';

class DanglingLibraryDocComments extends LintRule {
  static const LintCode code = LintCode(
      'dangling_library_doc_comments', 'Dangling library doc comment.',
      correctionMessage:
          "Add a 'library' directive after the library comment.");

  DanglingLibraryDocComments()
      : super(
            name: 'dangling_library_doc_comments',
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
  final DanglingLibraryDocComments rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    if (node.directives.isNotEmpty) {
      // Only consider a doc comment on the first directive. Doc comments on
      // other directives do not have the appearance of documenting the library.
      var firstDirective = node.directives.first;
      if (firstDirective is LibraryDirective) {
        // Given the presence of library directive, don't worry about later doc
        // comments in the library.
        return;
      }
      if (firstDirective is PartOfDirective) {
        // Don't worry about possible "library doc comments" in a part.
        return;
      }

      var docComment = firstDirective.documentationComment;
      if (docComment != null) {
        rule.reportLintForToken(docComment.beginToken);
        return;
      }

      return;
    }

    if (node.declarations.isEmpty) {
      // Without any declarations, we only need to check for a doc comment as
      // the last thing in a file.
      Token? endComment = node.endToken.precedingComments;
      while (endComment is CommentToken) {
        if (endComment is DocumentationCommentToken) {
          rule.reportLintForToken(endComment);
        }
        endComment = endComment.next;
      }
      return;
    }

    var firstDeclaration = node.declarations.first;
    var docComment = firstDeclaration.documentationComment;
    if (docComment == null) {
      return;
    }
    var lineInfo = node.lineInfo;

    if (docComment.tokens.length > 1) {
      for (var i = 0; i < docComment.tokens.length - 1; i++) {
        var commentToken = docComment.tokens[i];
        var followingCommentToken = docComment.tokens[i + 1];
        var commentEndLine = lineInfo.getLocation(commentToken.end).lineNumber;
        var followingCommentLine =
            lineInfo.getLocation(followingCommentToken.offset).lineNumber;
        if (followingCommentLine > commentEndLine + 1) {
          // There is a blank line within the declaration's doc comments.
          rule.reportLintForToken(commentToken);
          return;
        }
      }
    }

    // We must walk through the comments following the doc comment, tracking
    // pairs of consecutive comments so as to check whether any two are
    // separated by a blank line.
    var commentToken = docComment.endToken;
    var followingCommentToken = commentToken.next;
    while (followingCommentToken != null) {
      // Any blank line between the doc comment and following comments makes
      // the doc comment look dangling.
      var commentEndLine = lineInfo.getLocation(commentToken.end).lineNumber;
      var followingCommentLine =
          lineInfo.getLocation(followingCommentToken.offset).lineNumber;
      if (followingCommentLine > commentEndLine + 1) {
        // There is a blank line between the declaration's doc comment and the
        // declaration.
        rule.reportLint(docComment);
        return;
      }

      commentToken = followingCommentToken;
      followingCommentToken = followingCommentToken.next;
    }

    var commentEndLine = lineInfo.getLocation(commentToken.end).lineNumber;
    // The syntactic entity to which a comment is "attached" is the
    // [Comment]'s `parent`, not it's `endToken`'s `next` [Token].
    var tokenAfterDocComment =
        (docComment.endToken as DocumentationCommentToken).parent;
    if (tokenAfterDocComment == null) {
      // We shouldn't get here as the doc comment is attached to
      // [firstDeclaration].
      return;
    }
    var declarationStartLine =
        lineInfo.getLocation(tokenAfterDocComment.offset).lineNumber;
    if (declarationStartLine > commentEndLine + 1) {
      // There is a blank line between the declaration's doc comment and the
      // declaration.
      rule.reportLint(docComment);
    }
  }
}
