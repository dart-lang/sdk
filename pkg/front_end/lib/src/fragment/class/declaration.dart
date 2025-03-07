// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../fragment.dart';

abstract class ClassDeclaration {
  String get name;
  List<MetadataBuilder>? get metadata;
  LookupScope get compilationUnitScope;
  LookupScope get bodyScope;
  Uri get fileUri;
  int get nameOffset;
  int get startOffset;
  int get endOffset;
  List<NominalParameterBuilder>? get typeParameters;
  bool get isMixinDeclaration;

  TypeBuilder? get supertype;
  List<TypeBuilder>? get mixedInTypes;
  List<TypeBuilder>? get interfaces;

  void buildOutlineExpressions(
      {required Annotatable annotatable,
      required SourceLibraryBuilder libraryBuilder,
      required ClassHierarchy classHierarchy,
      required BodyBuilderContext bodyBuilderContext,
      required bool createFileUriExpression});

  int resolveConstructorReferences(SourceLibraryBuilder libraryBuilder);
}

class RegularClassDeclaration implements ClassDeclaration {
  final ClassFragment _fragment;

  RegularClassDeclaration(this._fragment);

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  LookupScope get compilationUnitScope => _fragment.enclosingScope;

  @override
  LookupScope get bodyScope => _fragment.bodyScope;

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
  List<NominalParameterBuilder>? get typeParameters =>
      _fragment.typeParameters?.builders;

  @override
  bool get isMixinDeclaration => false;

  @override
  TypeBuilder? get supertype => _fragment.supertype;

  @override
  List<TypeBuilder>? get mixedInTypes => _fragment.mixins;

  @override
  List<TypeBuilder>? get interfaces => _fragment.interfaces;

  @override
  void buildOutlineExpressions(
      {required Annotatable annotatable,
      required SourceLibraryBuilder libraryBuilder,
      required ClassHierarchy classHierarchy,
      required BodyBuilderContext bodyBuilderContext,
      required bool createFileUriExpression}) {
    MetadataBuilder.buildAnnotations(
        annotatable,
        _fragment.metadata,
        bodyBuilderContext,
        libraryBuilder,
        _fragment.fileUri,
        _fragment.enclosingScope,
        createFileUriExpression: createFileUriExpression);

    if (typeParameters != null) {
      for (int i = 0; i < typeParameters!.length; i++) {
        typeParameters![i].buildOutlineExpressions(libraryBuilder,
            bodyBuilderContext, classHierarchy, _fragment.typeParameterScope);
      }
    }
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

  @override
  final TypeBuilder supertype;

  EnumDeclaration(this._fragment, this.supertype);

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  LookupScope get compilationUnitScope => _fragment.enclosingScope;

  @override
  LookupScope get bodyScope => _fragment.bodyScope;

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
  List<NominalParameterBuilder>? get typeParameters =>
      _fragment.typeParameters?.builders;

  @override
  bool get isMixinDeclaration => false;

  @override
  List<TypeBuilder>? get mixedInTypes => _fragment.mixins;

  @override
  List<TypeBuilder>? get interfaces => _fragment.interfaces;

  @override
  void buildOutlineExpressions(
      {required Annotatable annotatable,
      required SourceLibraryBuilder libraryBuilder,
      required ClassHierarchy classHierarchy,
      required BodyBuilderContext bodyBuilderContext,
      required bool createFileUriExpression}) {
    MetadataBuilder.buildAnnotations(
        annotatable,
        _fragment.metadata,
        bodyBuilderContext,
        libraryBuilder,
        _fragment.fileUri,
        _fragment.enclosingScope,
        createFileUriExpression: createFileUriExpression);

    if (typeParameters != null) {
      for (int i = 0; i < typeParameters!.length; i++) {
        typeParameters![i].buildOutlineExpressions(libraryBuilder,
            bodyBuilderContext, classHierarchy, _fragment.typeParameterScope);
      }
    }
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

  @override
  final List<TypeBuilder> mixedInTypes;

  NamedMixinApplication(this._fragment, this.mixedInTypes);

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  LookupScope get compilationUnitScope => _fragment.enclosingScope;

  @override
  // Coverage-ignore(suite): Not run.
  LookupScope get bodyScope => compilationUnitScope;

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
  List<NominalParameterBuilder>? get typeParameters =>
      _fragment.typeParameters?.builders;

  @override
  bool get isMixinDeclaration => false;

  @override
  TypeBuilder? get supertype => _fragment.supertype;

  @override
  List<TypeBuilder>? get interfaces => _fragment.interfaces;

  @override
  void buildOutlineExpressions(
      {required Annotatable annotatable,
      required SourceLibraryBuilder libraryBuilder,
      required ClassHierarchy classHierarchy,
      required BodyBuilderContext bodyBuilderContext,
      required bool createFileUriExpression}) {
    MetadataBuilder.buildAnnotations(
        annotatable,
        _fragment.metadata,
        bodyBuilderContext,
        libraryBuilder,
        _fragment.fileUri,
        _fragment.enclosingScope,
        createFileUriExpression: createFileUriExpression);

    if (typeParameters != null) {
      for (int i = 0; i < typeParameters!.length; i++) {
        typeParameters![i].buildOutlineExpressions(libraryBuilder,
            bodyBuilderContext, classHierarchy, _fragment.typeParameterScope);
      }
    }
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
  final List<NominalParameterBuilder>? typeParameters;

  @override
  final TypeBuilder? supertype;

  @override
  bool get isMixinDeclaration => false;

  @override
  List<TypeBuilder>? get mixedInTypes => null;

  @override
  final List<TypeBuilder>? interfaces;

  AnonymousMixinApplication(
      {required this.name,
      required this.compilationUnitScope,
      required this.fileUri,
      required this.nameOffset,
      required this.startOffset,
      required this.endOffset,
      required this.typeParameters,
      required this.supertype,
      required this.interfaces});

  @override
  // Coverage-ignore(suite): Not run.
  LookupScope get bodyScope => compilationUnitScope;

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => null;

  @override
  void buildOutlineExpressions(
      {required Annotatable annotatable,
      required SourceLibraryBuilder libraryBuilder,
      required ClassHierarchy classHierarchy,
      required BodyBuilderContext bodyBuilderContext,
      required bool createFileUriExpression}) {}

  @override
  int resolveConstructorReferences(SourceLibraryBuilder libraryBuilder) {
    return 0;
  }
}

class MixinDeclaration implements ClassDeclaration {
  final MixinFragment _fragment;

  MixinDeclaration(this._fragment);

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  LookupScope get compilationUnitScope => _fragment.enclosingScope;

  @override
  // Coverage-ignore(suite): Not run.
  LookupScope get bodyScope => _fragment.bodyScope;

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
  List<NominalParameterBuilder>? get typeParameters =>
      _fragment.typeParameters?.builders;

  @override
  bool get isMixinDeclaration => true;

  @override
  TypeBuilder? get supertype => _fragment.supertype;

  @override
  List<TypeBuilder>? get mixedInTypes => _fragment.mixins;

  @override
  List<TypeBuilder>? get interfaces => _fragment.interfaces;

  @override
  void buildOutlineExpressions(
      {required Annotatable annotatable,
      required SourceLibraryBuilder libraryBuilder,
      required ClassHierarchy classHierarchy,
      required BodyBuilderContext bodyBuilderContext,
      required bool createFileUriExpression}) {
    MetadataBuilder.buildAnnotations(
        annotatable,
        _fragment.metadata,
        bodyBuilderContext,
        libraryBuilder,
        _fragment.fileUri,
        _fragment.enclosingScope,
        createFileUriExpression: createFileUriExpression);

    if (typeParameters != null) {
      for (int i = 0; i < typeParameters!.length; i++) {
        typeParameters![i].buildOutlineExpressions(libraryBuilder,
            bodyBuilderContext, classHierarchy, _fragment.typeParameterScope);
      }
    }
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
