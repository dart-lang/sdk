// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/ast_resolver.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';

class MetadataResolver extends ThrowingAstVisitor2<void> {
  final Linker _linker;
  final Scope _containerScope;
  final LibraryBuilder _libraryBuilder;
  final LibraryFragmentImpl _libraryFragment;
  late Scope _scope;

  MetadataResolver(this._linker, this._libraryFragment, this._libraryBuilder)
    : _containerScope = _libraryFragment.scope {
    _scope = _containerScope;
  }

  @override
  void visitAnnotation(covariant AnnotationImpl node) {
    var annotationElement = node.elementAnnotation;
    if (annotationElement is ElementAnnotationImpl) {
      var analysisOptions = _libraryBuilder.kind.file.analysisOptions;
      var astResolver = AstResolver(
        _linker,
        _libraryFragment,
        _scope,
        analysisOptions,
      );
      astResolver.resolveAnnotation(node);
    }
  }

  @override
  void visitBlockClassBody(BlockClassBody node) {
    node.visitChildren2(this);
  }

  @override
  void visitBlockEnumBody(BlockEnumBody node) {
    node.visitChildren2(this);
  }

  @override
  void visitClassDeclaration(covariant ClassDeclarationImpl node) {
    node.metadata.accept2(this);
    node.namePart.typeParameters?.accept2(this);

    _scope = node.bodyScope!;
    try {
      node.namePart
          .tryCast<PrimaryConstructorDeclaration>()
          ?.formalParameters
          .accept2(this);
      node.body.accept2(this);
    } finally {
      _scope = _containerScope;
    }
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    node.metadata.accept2(this);
    node.typeParameters?.accept2(this);
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    node.directives.accept2(this);
    node.declarations.accept2(this);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    node.metadata.accept2(this);
    node.parameters.accept2(this);
  }

  @override
  void visitEmptyClassBody(EmptyClassBody node) {}

  @override
  void visitEmptyEnumBody(EmptyEnumBody node) {}

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    node.metadata.accept2(this);
  }

  @override
  void visitEnumDeclaration(covariant EnumDeclarationImpl node) {
    node.metadata.accept2(this);
    node.namePart.typeParameters?.accept2(this);

    _scope = node.bodyScope!;
    try {
      node.namePart
          .tryCast<PrimaryConstructorDeclaration>()
          ?.formalParameters
          .accept2(this);
      node.body.accept2(this);
    } finally {
      _scope = _containerScope;
    }
  }

  @override
  void visitExportDirective(covariant ExportDirectiveImpl node) {
    node.metadata.accept2(this);

    // We access export directive metadata while building scopes.
    // But for the current library cycle the metadata was not resolved yet.
    // Now that we resolved it, reset the cache.
    node.libraryExport!.metadata.resetCache();
  }

  @override
  void visitExtensionDeclaration(covariant ExtensionDeclarationImpl node) {
    node.metadata.accept2(this);
    node.typeParameters?.accept2(this);

    _scope = node.bodyScope!;
    try {
      node.body.accept2(this);
    } finally {
      _scope = _containerScope;
    }
  }

  @override
  void visitExtensionTypeDeclaration(
    covariant ExtensionTypeDeclarationImpl node,
  ) {
    node.metadata.accept2(this);
    node.namePart.typeParameters?.accept2(this);

    _scope = node.bodyScope!;
    try {
      node.namePart
          .tryCast<PrimaryConstructorDeclaration>()
          ?.formalParameters
          .accept2(this);
      node.body.accept2(this);
    } finally {
      _scope = _containerScope;
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    node.metadata.accept2(this);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    node.metadata.accept2(this);
    if (node.functionTypedSuffix case var functionTypedSuffix?) {
      functionTypedSuffix.formalParameters.accept2(this);
    }
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    node.parameters.accept2(this);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    node.metadata.accept2(this);
    node.functionExpression.accept2(this);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    node.typeParameters?.accept2(this);
    node.parameters?.accept2(this);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    node.metadata.accept2(this);
    node.typeParameters?.accept2(this);
    node.parameters.accept2(this);
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    node.typeParameters?.accept2(this);
    node.parameters.accept2(this);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    node.metadata.accept2(this);
    node.typeParameters?.accept2(this);
    // TODO(eernst): Extend this visitor to visit types.
    // E.g., `List<Function<@m X>()> Function()` is not included now.
    var type = node.type;
    if (type is GenericFunctionType) type.accept2(this);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    node.metadata.accept2(this);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    node.metadata.accept2(this);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    node.metadata.accept2(this);
    node.typeParameters?.accept2(this);
    node.parameters?.accept2(this);
  }

  @override
  void visitMixinDeclaration(covariant MixinDeclarationImpl node) {
    node.metadata.accept2(this);
    node.typeParameters?.accept2(this);

    _scope = node.bodyScope!;
    try {
      node.body.accept2(this);
    } finally {
      _scope = _containerScope;
    }
  }

  @override
  void visitNameWithTypeParameters(NameWithTypeParameters node) {
    node.typeParameters?.accept2(this);
  }

  @override
  void visitPartDirective(PartDirective node) {
    node.metadata.accept2(this);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    node.metadata.accept2(this);
  }

  @override
  void visitPrimaryConstructorBody(PrimaryConstructorBody node) {
    node.metadata.accept2(this);
  }

  @override
  void visitPrimaryConstructorDeclaration(PrimaryConstructorDeclaration node) {
    node.typeParameters?.accept2(this);
    node.formalParameters.accept2(this);
  }

  @override
  void visitRegularFormalParameter(RegularFormalParameter node) {
    node.metadata.accept2(this);
    if (node.functionTypedSuffix case var functionTypedSuffix?) {
      functionTypedSuffix.typeParameters?.accept2(this);
      functionTypedSuffix.formalParameters.accept2(this);
    }
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    node.metadata.accept2(this);
    if (node.functionTypedSuffix case var functionTypedSuffix?) {
      functionTypedSuffix.formalParameters.accept2(this);
    }
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    node.metadata.accept2(this);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    node.metadata.accept2(this);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    node.typeParameters.accept2(this);
  }
}
