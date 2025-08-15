// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r'Prefer using `///` for doc comments.';

bool isJavaStyle(Comment comment) {
  var tokens = comment.tokens;
  if (tokens.isEmpty) {
    return false;
  }
  //Should be only one
  return comment.tokens.first.lexeme.startsWith('/**');
}

class SlashForDocComments extends LintRule {
  SlashForDocComments()
    : super(name: LintNames.slash_for_doc_comments, description: _desc);

  @override
  bool get canUseParsedResult => true;

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.slashForDocComments;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
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
      rule.reportAtNode(comment);
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
      rule.reportAtToken(comment);
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
