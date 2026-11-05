// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../fragment.dart';

abstract class ClassDeclaration {
  String get name;
  ExtensionScope get extensionScope;
  LookupScope get compilationUnitScope;
  LookupScope get bodyScope;
  Uri get fileUri;
  int get nameOffset;
  int get startOffset;
  int get endOffset;
  bool get isMixinDeclaration;

  /// [UriOffsetLength] for the class declaration.
  UriOffsetLength get uriOffset;

  void buildOutlineExpressions({
    required Annotatable annotatable,
    required Uri annotatableFileUri,
    required SourceLibraryBuilder libraryBuilder,
    required ClassHierarchy classHierarchy,
    required BodyBuilderContext bodyBuilderContext,
    required bool createFileUriExpression,
  });

  int resolveConstructorReferences(SourceLibraryBuilder libraryBuilder);
}

class RegularClassDeclaration implements ClassDeclaration {
  final ClassFragment _fragment;

  new(this._fragment);

  @override
  ExtensionScope get extensionScope =>
      _fragment.enclosingCompilationUnit.extensionScope;

  @override
  LookupScope get compilationUnitScope => _fragment.enclosingScope;

  @override
  LookupScope get bodyScope => _fragment.bodyScope;

  @override
  // Coverage-ignore(suite): Not run.
  UriOffsetLength get uriOffset => _fragment.uriOffset;

  @override
  Uri get fileUri => _fragment.fileUri;

  @override
  int get endOffset => _fragment.endOffset;

  @override
  String get name => _fragment.name;

  @override
  int get nameOffset => _fragment.nameOffset;

  @override
  int get startOffset => _fragment.startOffset;

  @override
  bool get isMixinDeclaration => false;

  @override
  void buildOutlineExpressions({
    required Annotatable annotatable,
    required Uri annotatableFileUri,
    required SourceLibraryBuilder libraryBuilder,
    required ClassHierarchy classHierarchy,
    required BodyBuilderContext bodyBuilderContext,
    required bool createFileUriExpression,
  }) {
    MetadataBuilder.buildAnnotations(
      annotatable: annotatable,
      annotatableFileUri: annotatableFileUri,
      metadata: _fragment.metadata,
      annotationsFileUri: _fragment.fileUri,
      bodyBuilderContext: bodyBuilderContext,
      libraryBuilder: libraryBuilder,
      extensionScope: _fragment.enclosingCompilationUnit.extensionScope,
      scope: _fragment.enclosingScope,
    );
  }

  @override
  int resolveConstructorReferences(SourceLibraryBuilder libraryBuilder) {
    for (ConstructorReferenceBuilder ref in _fragment.constructorReferences) {
      ref.resolveIn(bodyScope, libraryBuilder);
    }
    return _fragment.constructorReferences.length;
  }
}

class EnumDeclaration implements ClassDeclaration {
  final EnumFragment _fragment;

  new(this._fragment);

  @override
  ExtensionScope get extensionScope =>
      _fragment.enclosingCompilationUnit.extensionScope;

  @override
  LookupScope get compilationUnitScope => _fragment.enclosingScope;

  @override
  LookupScope get bodyScope => _fragment.bodyScope;

  @override
  // Coverage-ignore(suite): Not run.
  UriOffsetLength get uriOffset => _fragment.uriOffset;

  @override
  Uri get fileUri => _fragment.fileUri;

  @override
  int get endOffset => _fragment.endOffset;

  @override
  String get name => _fragment.name;

  @override
  int get nameOffset => _fragment.nameOffset;

  @override
  int get startOffset => _fragment.startOffset;

  @override
  bool get isMixinDeclaration => false;

  @override
  void buildOutlineExpressions({
    required Annotatable annotatable,
    required Uri annotatableFileUri,
    required SourceLibraryBuilder libraryBuilder,
    required ClassHierarchy classHierarchy,
    required BodyBuilderContext bodyBuilderContext,
    required bool createFileUriExpression,
  }) {
    MetadataBuilder.buildAnnotations(
      annotatable: annotatable,
      annotatableFileUri: annotatableFileUri,
      metadata: _fragment.metadata,
      annotationsFileUri: _fragment.fileUri,
      bodyBuilderContext: bodyBuilderContext,
      libraryBuilder: libraryBuilder,
      extensionScope: _fragment.enclosingCompilationUnit.extensionScope,
      scope: _fragment.enclosingScope,
    );
  }

  @override
  int resolveConstructorReferences(SourceLibraryBuilder libraryBuilder) {
    for (ConstructorReferenceBuilder ref in _fragment.constructorReferences) {
      ref.resolveIn(bodyScope, libraryBuilder);
    }
    return _fragment.constructorReferences.length;
  }
}

class NamedMixinApplication implements ClassDeclaration {
  final NamedMixinApplicationFragment _fragment;

  new(this._fragment);

  @override
  ExtensionScope get extensionScope =>
      _fragment.enclosingCompilationUnit.extensionScope;

  @override
  LookupScope get compilationUnitScope => _fragment.enclosingScope;

  @override
  // Coverage-ignore(suite): Not run.
  LookupScope get bodyScope => compilationUnitScope;

  @override
  // Coverage-ignore(suite): Not run.
  UriOffsetLength get uriOffset => _fragment.uriOffset;

  @override
  Uri get fileUri => _fragment.fileUri;

  @override
  int get endOffset => _fragment.endOffset;

  @override
  String get name => _fragment.name;

  @override
  int get nameOffset => _fragment.nameOffset;

  @override
  int get startOffset => _fragment.startOffset;

  @override
  bool get isMixinDeclaration => false;

  @override
  void buildOutlineExpressions({
    required Annotatable annotatable,
    required Uri annotatableFileUri,
    required SourceLibraryBuilder libraryBuilder,
    required ClassHierarchy classHierarchy,
    required BodyBuilderContext bodyBuilderContext,
    required bool createFileUriExpression,
  }) {
    MetadataBuilder.buildAnnotations(
      annotatable: annotatable,
      annotatableFileUri: annotatableFileUri,
      metadata: _fragment.metadata,
      annotationsFileUri: _fragment.fileUri,
      bodyBuilderContext: bodyBuilderContext,
      libraryBuilder: libraryBuilder,
      extensionScope: _fragment.enclosingCompilationUnit.extensionScope,
      scope: _fragment.enclosingScope,
    );
  }

  @override
  int resolveConstructorReferences(SourceLibraryBuilder libraryBuilder) {
    return 0;
  }
}

class AnonymousMixinApplication implements ClassDeclaration {
  @override
  final String name;

  @override
  final ExtensionScope extensionScope;

  @override
  final LookupScope compilationUnitScope;

  @override
  final int nameOffset;

  @override
  final int startOffset;

  @override
  final int endOffset;

  @override
  final Uri fileUri;

  @override
  final UriOffsetLength uriOffset;

  @override
  bool get isMixinDeclaration => false;

  new({
    required this.name,
    required this.extensionScope,
    required this.compilationUnitScope,
    required this.uriOffset,
    required this.fileUri,
    required this.nameOffset,
    required this.startOffset,
    required this.endOffset,
  });

  @override
  // Coverage-ignore(suite): Not run.
  LookupScope get bodyScope => compilationUnitScope;

  @override
  void buildOutlineExpressions({
    required Annotatable annotatable,
    required Uri annotatableFileUri,
    required SourceLibraryBuilder libraryBuilder,
    required ClassHierarchy classHierarchy,
    required BodyBuilderContext bodyBuilderContext,
    required bool createFileUriExpression,
  }) {}

  @override
  int resolveConstructorReferences(SourceLibraryBuilder libraryBuilder) {
    return 0;
  }
}

class MixinDeclaration implements ClassDeclaration {
  final MixinFragment _fragment;

  new(this._fragment);

  @override
  ExtensionScope get extensionScope =>
      _fragment.enclosingCompilationUnit.extensionScope;

  @override
  LookupScope get compilationUnitScope => _fragment.enclosingScope;

  @override
  // Coverage-ignore(suite): Not run.
  LookupScope get bodyScope => _fragment.bodyScope;

  @override
  // Coverage-ignore(suite): Not run.
  UriOffsetLength get uriOffset => _fragment.uriOffset;

  @override
  Uri get fileUri => _fragment.fileUri;

  @override
  int get endOffset => _fragment.endOffset;

  @override
  String get name => _fragment.name;

  @override
  int get nameOffset => _fragment.nameOffset;

  @override
  int get startOffset => _fragment.startOffset;

  @override
  bool get isMixinDeclaration => true;

  @override
  void buildOutlineExpressions({
    required Annotatable annotatable,
    required Uri annotatableFileUri,
    required SourceLibraryBuilder libraryBuilder,
    required ClassHierarchy classHierarchy,
    required BodyBuilderContext bodyBuilderContext,
    required bool createFileUriExpression,
  }) {
    MetadataBuilder.buildAnnotations(
      annotatable: annotatable,
      annotatableFileUri: annotatableFileUri,
      metadata: _fragment.metadata,
      annotationsFileUri: _fragment.fileUri,
      bodyBuilderContext: bodyBuilderContext,
      libraryBuilder: libraryBuilder,
      extensionScope: _fragment.enclosingCompilationUnit.extensionScope,
      scope: _fragment.enclosingScope,
    );
  }

  @override
  int resolveConstructorReferences(SourceLibraryBuilder libraryBuilder) {
    for (ConstructorReferenceBuilder ref in _fragment.constructorReferences) {
      // Coverage-ignore-block(suite): Not run.
      ref.resolveIn(bodyScope, libraryBuilder);
    }
    return _fragment.constructorReferences.length;
  }
}
