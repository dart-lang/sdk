// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/summary2/ast_resolver.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linking_node_scope.dart';

class MetadataResolver extends ThrowingAstVisitor<void> {
  final Linker _linker;
  final Scope _libraryScope;
  final CompilationUnitElement _unitElement;
  Scope _scope;

  MetadataResolver(this._linker, this._libraryScope, this._unitElement)
      : _scope = _libraryScope;

  @override
  void visitAnnotation(Annotation node) {
    node.elementAnnotation = ElementAnnotationImpl(_unitElement);

    var astResolver = AstResolver(_linker, _unitElement, _scope);
    astResolver.resolve(node, () => node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    node.metadata.accept(this);
    node.typeParameters?.accept(this);

    _scope = LinkingNodeContext.get(node).scope;
    try {
      node.members.accept(this);
    } finally {
      _scope = _libraryScope;
    }
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    node.metadata.accept(this);
    node.typeParameters?.accept(this);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    node.directives.accept(this);
    node.declarations.accept(this);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    node.metadata.accept(this);
    node.parameters.accept(this);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    node.parameter.accept(this);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    node.metadata.accept(this);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    node.metadata.accept(this);
    node.constants.accept(this);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    node.metadata.accept(this);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    node.metadata.accept(this);
    node.typeParameters?.accept(this);

    _scope = LinkingNodeContext.get(node).scope;
    try {
      node.members.accept(this);
    } finally {
      _scope = _libraryScope;
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    node.metadata.accept(this);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    node.metadata.accept(this);
    node.parameters?.accept(this);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    node.parameters.accept(this);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    node.metadata.accept(this);
    node.functionExpression.accept(this);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    node.metadata.accept(this);
    node.typeParameters?.accept(this);
    node.parameters.accept(this);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    node.metadata.accept(this);
    node.typeParameters?.accept(this);
    node.parameters.accept(this);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    node.typeParameters?.accept(this);
    node.parameters.accept(this);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    node.metadata.accept(this);
    node.typeParameters?.accept(this);
    node.functionType?.accept(this);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    node.metadata.accept(this);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    node.metadata.accept(this);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    node.metadata.accept(this);
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    node.metadata.accept(this);
    node.typeParameters?.accept(this);

    _scope = LinkingNodeContext.get(node).scope;
    try {
      node.members.accept(this);
    } finally {
      _scope = _libraryScope;
    }
  }

  @override
  void visitPartDirective(PartDirective node) {
    node.metadata.accept(this);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    node.metadata.accept(this);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    node.metadata.accept(this);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    node.metadata.accept(this);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    node.metadata.accept(this);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    node.typeParameters.accept(this);
  }
}
