// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/summary/format.dart';

/// Create informative data for nodes that need it, and set IDs of this
/// data to the nodes.
List<UnlinkedInformativeDataBuilder> createInformativeData(
    CompilationUnit unit) {
  var visitor = _SetInformativeId();
  unit.accept(visitor);
  return visitor.dataList;
}

/// If [createInformativeData] set the informative data identifier for the
/// [node], return it, otherwise return zero.
int getInformativeId(AstNode node) {
  int id = node.getProperty(_SetInformativeId.ID);
  return id ?? 0;
}

class _SetInformativeId extends SimpleAstVisitor<void> {
  static final String ID = 'informativeId';

  final List<UnlinkedInformativeDataBuilder> dataList = [];

  void setData(AstNode node, UnlinkedInformativeDataBuilder data) {
    var id = 1 + dataList.length;
    node.setProperty(ID, id);
    dataList.add(data);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.classDeclaration(
        codeOffset: node.offset,
        codeLength: node.length,
        documentationComment_tokens: _nodeCommentTokens(node),
        nameOffset: node.name.offset,
      ),
    );

    node.typeParameters?.accept(this);
    node.members.accept(this);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.classTypeAlias(
        codeOffset: node.offset,
        codeLength: node.length,
        documentationComment_tokens: _nodeCommentTokens(node),
        nameOffset: node.name.offset,
      ),
    );

    node.typeParameters?.accept(this);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.compilationUnit(
        codeOffset: node.offset,
        codeLength: node.length,
        compilationUnit_lineStarts: node.lineInfo.lineStarts,
      ),
    );

    node.directives.accept(this);
    node.declarations.accept(this);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.constructorDeclaration(
        codeOffset: node.offset,
        codeLength: node.length,
        documentationComment_tokens: _nodeCommentTokens(node),
        nameOffset: node.name?.offset ?? 0,
        constructorDeclaration_periodOffset: node.period?.offset ?? 0,
        constructorDeclaration_returnTypeOffset: node.returnType.offset,
      ),
    );

    node.parameters?.accept(this);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    var defaultValueCode = node.defaultValue?.toSource();
    setData(
      node,
      UnlinkedInformativeDataBuilder.defaultFormalParameter(
        codeOffset: node.offset,
        codeLength: node.length,
        defaultFormalParameter_defaultValueCode: defaultValueCode,
      ),
    );

    node.parameter.accept(this);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.enumConstantDeclaration(
        codeOffset: node.offset,
        codeLength: node.length,
        documentationComment_tokens: _nodeCommentTokens(node),
        nameOffset: node.name.offset,
      ),
    );
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.enumDeclaration(
        codeOffset: node.offset,
        codeLength: node.length,
        documentationComment_tokens: _nodeCommentTokens(node),
        nameOffset: node.name.offset,
      ),
    );

    node.constants.accept(this);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.exportDirective(
        directiveKeywordOffset: node.keyword.offset,
      ),
    );
    node.combinators.accept(this);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.extensionDeclaration(
        codeOffset: node.offset,
        codeLength: node.length,
        documentationComment_tokens: _nodeCommentTokens(node),
        nameOffset: node.name?.offset ?? 0,
      ),
    );

    node.typeParameters?.accept(this);
    node.members.accept(this);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.fieldDeclaration(
        documentationComment_tokens: _nodeCommentTokens(node),
      ),
    );

    node.fields.accept(this);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.fieldFormalParameter(
        codeOffset: node.offset,
        codeLength: node.length,
        nameOffset: node.identifier.offset,
      ),
    );
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    node.parameters.accept(this);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.functionDeclaration(
        codeOffset: node.offset,
        codeLength: node.length,
        documentationComment_tokens: _nodeCommentTokens(node),
        nameOffset: node.name.offset,
      ),
    );

    node.functionExpression.accept(this);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.functionTypeAlias(
        codeOffset: node.offset,
        codeLength: node.length,
        documentationComment_tokens: _nodeCommentTokens(node),
        nameOffset: node.name.offset,
      ),
    );

    node.typeParameters?.accept(this);
    node.parameters.accept(this);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.functionTypedFormalParameter(
        codeOffset: node.offset,
        codeLength: node.length,
        nameOffset: node.identifier.offset,
      ),
    );
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    node.typeParameters?.accept(this);
    node.parameters.accept(this);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.genericTypeAlias(
        codeOffset: node.offset,
        codeLength: node.length,
        documentationComment_tokens: _nodeCommentTokens(node),
        nameOffset: node.name.offset,
      ),
    );

    node.typeParameters?.accept(this);
    node.functionType?.accept(this);
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.hideCombinator(
        combinatorEnd: node.end,
        combinatorKeywordOffset: node.offset,
      ),
    );
  }

  @override
  void visitImportDirective(ImportDirective node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.importDirective(
        directiveKeywordOffset: node.keyword.offset,
        importDirective_prefixOffset: node.prefix?.offset ?? 0,
      ),
    );
    node.combinators.accept(this);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.libraryDirective(
        documentationComment_tokens: _nodeCommentTokens(node),
      ),
    );
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.methodDeclaration(
        codeOffset: node.offset,
        codeLength: node.length,
        documentationComment_tokens: _nodeCommentTokens(node),
        nameOffset: node.name.offset,
      ),
    );

    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.mixinDeclaration(
        codeOffset: node.offset,
        codeLength: node.length,
        documentationComment_tokens: _nodeCommentTokens(node),
        nameOffset: node.name.offset,
      ),
    );

    node.typeParameters?.accept(this);
    node.members.accept(this);
  }

  @override
  void visitPartDirective(PartDirective node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.partDirective(
        directiveKeywordOffset: node.keyword.offset,
      ),
    );
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.partDirective(
        directiveKeywordOffset: node.keyword.offset,
      ),
    );
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.showCombinator(
        combinatorEnd: node.end,
        combinatorKeywordOffset: node.offset,
      ),
    );
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.simpleFormalParameter(
        codeOffset: node.offset,
        codeLength: node.length,
        nameOffset: node.identifier?.offset ?? 0,
      ),
    );
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.topLevelVariableDeclaration(
        documentationComment_tokens: _nodeCommentTokens(node),
      ),
    );

    node.variables.accept(this);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    setData(
      node,
      UnlinkedInformativeDataBuilder.typeParameter(
        codeOffset: node.offset,
        codeLength: node.length,
        nameOffset: node.name.offset,
      ),
    );
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    node.typeParameters.accept(this);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    var variableList = node.parent as VariableDeclarationList;
    var isFirst = identical(variableList.variables[0], node);
    var codeOffset = (isFirst ? variableList.parent : node).offset;
    var codeLength = node.end - codeOffset;

    setData(
      node,
      UnlinkedInformativeDataBuilder.variableDeclaration(
        codeOffset: codeOffset,
        codeLength: codeLength,
        nameOffset: node.name.offset,
      ),
    );
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    node.variables.accept(this);
  }

  static List<String> _commentTokens(Comment comment) {
    if (comment == null) return null;
    return comment.tokens.map((token) => token.lexeme).toList();
  }

  static List<String> _nodeCommentTokens(AnnotatedNode node) {
    return _commentTokens(node.documentationComment);
  }
}
