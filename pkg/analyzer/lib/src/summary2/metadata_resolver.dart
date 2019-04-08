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

class MetadataResolver extends ThrowingAstVisitor<void> {
  final Linker _linker;
  final LibraryElement _libraryElement;

  Scope scope;

  MetadataResolver(this._linker, this._libraryElement);

  @override
  void visitAnnotation(Annotation node) {
    // TODO(scheglov) get rid of?
    node.elementAnnotation = ElementAnnotationImpl(null);

    var astResolver = AstResolver(_linker, _libraryElement, scope);
    // TODO(scheglov) enclosing elements?
    astResolver.resolve(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    node.metadata.accept(this);
    node.typeParameters?.accept(this);
    node.members.accept(this);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    node.metadata.accept(this);
    node.typeParameters?.accept(this);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    node.declarations.accept(this);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    node.metadata.accept(this);
    node.parameters.accept(this);
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
  void visitFieldDeclaration(FieldDeclaration node) {
    node.metadata.accept(this);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    // TODO: implement visitFormalParameterList
//    super.visitFormalParameterList(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    node.metadata.accept(this);
    node.functionExpression.accept(this);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // TODO: implement visitFunctionExpression
//    super.visitFunctionExpression(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    node.metadata.accept(this);
    node.typeParameters?.accept(this);
    node.parameters.accept(this);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    // TODO: implement visitGenericTypeAlias
//    super.visitGenericTypeAlias(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    node.metadata.accept(this);
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    // TODO: implement visitMixinDeclaration
//    super.visitMixinDeclaration(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    node.metadata.accept(this);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    // TODO: implement visitTypeParameterList
//    super.visitTypeParameterList(node);
  }
}
