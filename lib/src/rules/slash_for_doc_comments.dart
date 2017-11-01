// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Prefer using /// for doc comments.';

const _details = r'''

From the [style guide](https://www.dartlang.org/articles/style-guide/):

**PREFER** using `///` for doc comments.

Although Dart supports two syntaxes of doc comments (`///` and `/**`), we
prefer using `///` for doc comments.

**GOOD:**
```
/// Parses a set of option strings. For each option:
///
/// * If it is `null`, then it is ignored.
/// * If it is a string, then [validate] is called on it.
/// * If it is any other type, it is *not* validated.
void parse(List options) {
  // ...
}
```

Within a doc comment, you can use markdown for formatting.

''';

bool isJavaStyle(Comment comment) {
  var tokens = comment.tokens;
  if (tokens == null || tokens.isEmpty) {
    return false;
  }
  //Should be only one
  return comment.tokens[0].lexeme.startsWith('/**');
}

class SlashForDocComments extends LintRule {
  SlashForDocComments()
      : super(
            name: 'slash_for_doc_comments',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  LintRule rule;
  Visitor(this.rule);

  checkComment(Comment comment) {
    if (comment != null && isJavaStyle(comment)) {
      rule.reportLint(comment);
    }
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    checkComment(node.documentationComment);
  }

  @override
  visitClassTypeAlias(ClassTypeAlias node) {
    checkComment(node.documentationComment);
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    checkComment(node.documentationComment);
  }

  @override
  visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    checkComment(node.documentationComment);
  }

  @override
  visitEnumDeclaration(EnumDeclaration node) {
    checkComment(node.documentationComment);
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    checkComment(node.documentationComment);
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    checkComment(node.documentationComment);
  }

  @override
  visitFunctionTypeAlias(FunctionTypeAlias node) {
    checkComment(node.documentationComment);
  }

  @override
  visitLibraryDirective(LibraryDirective node) {
    checkComment(node.documentationComment);
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    checkComment(node.documentationComment);
  }

  @override
  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    checkComment(node.documentationComment);
  }
}
