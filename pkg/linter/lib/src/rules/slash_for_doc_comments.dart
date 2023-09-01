// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Prefer using /// for doc comments.';

const _details = r'''
From [Effective Dart](https://dart.dev/effective-dart/documentation#do-use--doc-comments-to-document-members-and-types):

**DO** use `///` for documentation comments.

Although Dart supports two syntaxes of doc comments (`///` and `/**`), we
prefer using `///` for doc comments.

**GOOD:**
```dart
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
  if (tokens.isEmpty) {
    return false;
  }
  //Should be only one
  return comment.tokens.first.lexeme.startsWith('/**');
}

class SlashForDocComments extends LintRule {
  static const LintCode code = LintCode('slash_for_doc_comments',
      "Use the end-of-line form ('///') for doc comments.",
      correctionMessage: "Try rewriting the comment to use '///'.");

  SlashForDocComments()
      : super(
            name: 'slash_for_doc_comments',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  bool get canUseParsedResult => true;

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addClassTypeAlias(this, visitor);
    registry.addCompilationUnit(this, visitor);
    registry.addConstructorDeclaration(this, visitor);
    registry.addEnumConstantDeclaration(this, visitor);
    registry.addEnumDeclaration(this, visitor);
    registry.addExtensionDeclaration(this, visitor);
    registry.addFieldDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addFunctionDeclarationStatement(this, visitor);
    registry.addFunctionTypeAlias(this, visitor);
    registry.addGenericTypeAlias(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addMixinDeclaration(this, visitor);
    registry.addTopLevelVariableDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  void checkComment(Comment? comment) {
    if (comment != null && isJavaStyle(comment)) {
      rule.reportLint(comment);
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    checkComment(node.documentationComment);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    checkComment(node.documentationComment);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    var directives = node.directives;
    if (directives.isNotEmpty) {
      checkComment(directives.first.documentationComment);
    }
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    checkComment(node.documentationComment);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    checkComment(node.documentationComment);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    checkComment(node.documentationComment);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    checkComment(node.documentationComment);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    checkComment(node.documentationComment);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    checkComment(node.documentationComment);
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    var comment = node.beginToken.precedingComments;
    if (comment != null && comment.lexeme.startsWith('/**')) {
      rule.reportLintForToken(comment);
    }
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    checkComment(node.documentationComment);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    checkComment(node.documentationComment);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    checkComment(node.documentationComment);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    checkComment(node.documentationComment);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    checkComment(node.documentationComment);
  }
}
