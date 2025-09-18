// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/source/source_library_builder.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../builder/declaration_builders.dart';
import '../builder/metadata_builder.dart';
import '../builder/type_builder.dart';
import '../fragment/fragment.dart';
import '../kernel/body_builder_context.dart';

class SourceNominalParameterBuilder extends NominalParameterBuilder {
  final NominalParameterDeclaration _declaration;

  List<NominalParameterDeclaration>? _augmentations;

  @override
  TypeBuilder? bound;

  @override
  TypeBuilder? defaultType;

  @override
  final TypeParameter parameter;

  SourceNominalParameterBuilder(
    this._declaration, {
    this.bound,
    super.variableVariance,
  }) : parameter =
           new TypeParameter(
               _declaration.name == NominalParameterBuilder.noNameSentinel
                   ? null
                   : _declaration.name,
               null,
             )
             ..fileOffset = _declaration.fileOffset
             ..variance = variableVariance;

  @override
  int get fileOffset => _declaration.fileOffset;

  @override
  String get name => _declaration.name;

  @override
  TypeParameterKind get kind => _declaration.kind;

  @override
  bool get isWildcard => _declaration.isWildcard;

  @override
  Uri get fileUri => _declaration.fileUri;

  void buildOutlineExpressions(
    SourceLibraryBuilder libraryBuilder,
    BodyBuilderContext bodyBuilderContext,
    ClassHierarchy classHierarchy,
  ) {
    _declaration.buildOutlineExpressions(
      libraryBuilder: libraryBuilder,
      bodyBuilderContext: bodyBuilderContext,
      classHierarchy: classHierarchy,
      parameter: parameter,
      annotatableFileUri: fileUri,
    );
    List<NominalParameterDeclaration>? augmentations = _augmentations;
    if (augmentations != null) {
      for (NominalParameterDeclaration augmentation in augmentations) {
        augmentation.buildOutlineExpressions(
          libraryBuilder: libraryBuilder,
          bodyBuilderContext: bodyBuilderContext,
          classHierarchy: classHierarchy,
          parameter: parameter,
          annotatableFileUri: fileUri,
        );
      }
    }
  }

  void addAugmentingDeclaration(NominalParameterDeclaration augmentation) {
    (_augmentations ??= []).add(augmentation);
  }

  static List<TypeParameter>? typeParametersFromBuilders(
    List<SourceNominalParameterBuilder>? builders,
  ) {
    if (builders == null) return null;
    return new List<TypeParameter>.generate(
      builders.length,
      (int i) => builders[i].parameter,
      growable: true,
    );
  }
}

abstract class NominalParameterDeclaration {
  String get name;

  TypeParameterKind get kind;

  bool get isWildcard;

  int get fileOffset;

  Uri get fileUri;

  void buildOutlineExpressions({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
    required TypeParameter parameter,
    required Uri annotatableFileUri,
  });
}

class RegularNominalParameterDeclaration
    implements NominalParameterDeclaration {
  final TypeParameterFragment _fragment;

  RegularNominalParameterDeclaration(this._fragment);

  @override
  int get fileOffset => _fragment.nameOffset;

  @override
  Uri get fileUri => _fragment.fileUri;

  @override
  bool get isWildcard => _fragment.isWildcard;

  @override
  TypeParameterKind get kind => _fragment.kind;

  @override
  String get name => _fragment.variableName;

  @override
  void buildOutlineExpressions({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
    required TypeParameter parameter,
    required Uri annotatableFileUri,
  }) {
    MetadataBuilder.buildAnnotations(
      annotatable: parameter,
      annotatableFileUri: annotatableFileUri,
      metadata: _fragment.metadata,
      annotationsFileUri: _fragment.fileUri,
      bodyBuilderContext: bodyBuilderContext,
      libraryBuilder: libraryBuilder,
      scope: _fragment.typeParameterScope,
    );
  }
}

class DirectNominalParameterDeclaration implements NominalParameterDeclaration {
  @override
  final int fileOffset;

  @override
  final String name;

  @override
  final TypeParameterKind kind;

  @override
  final bool isWildcard;

  @override
  final Uri fileUri;

  DirectNominalParameterDeclaration({
    required this.name,
    required this.kind,
    required this.isWildcard,
    required this.fileOffset,
    required this.fileUri,
  });

  @override
  // Coverage-ignore(suite): Not run.
  void buildOutlineExpressions({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
    required TypeParameter parameter,
    required Uri? annotatableFileUri,
  }) {}
}

class SyntheticNominalParameterDeclaration
    implements NominalParameterDeclaration {
  final NominalParameterBuilder _builder;

  @override
  final int fileOffset;

  @override
  final Uri fileUri;

  @override
  final TypeParameterKind kind;

  SyntheticNominalParameterDeclaration(
    this._builder, {
    required this.kind,
    required this.fileOffset,
    required this.fileUri,
  });

  @override
  bool get isWildcard => _builder.isWildcard;

  @override
  String get name => _builder.name;

  @override
  void buildOutlineExpressions({
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
    required TypeParameter parameter,
    required Uri? annotatableFileUri,
  }) {}
}

class SourceStructuralParameterBuilder extends StructuralParameterBuilder {
  final StructuralParameterDeclaration _declaration;

  @override
  TypeBuilder? bound;

  @override
  TypeBuilder? defaultType;

  final List<MetadataBuilder>? metadata;

  /// The [StructuralParameter] built by this builder.
  @override
  final StructuralParameter parameter;

  SourceStructuralParameterBuilder(
    this._declaration, {
    Variance? parameterVariance,
    this.metadata,
  }) : parameter =
           new StructuralParameter(
               _declaration.name == StructuralParameterBuilder.noNameSentinel
                   ? null
                   : _declaration.name,
               null,
             )
             ..fileOffset = _declaration.fileOffset
             ..variance = parameterVariance;

  @override
  // Coverage-ignore(suite): Not run.
  TypeParameterKind get kind => TypeParameterKind.function;

  @override
  int get fileOffset => _declaration.fileOffset;

  @override
  String get name => _declaration.name;

  @override
  bool get isWildcard => _declaration.isWildcard;

  @override
  Uri? get fileUri => _declaration.fileUri;
}

abstract class StructuralParameterDeclaration {
  String get name;

  bool get isWildcard;

  int get fileOffset;

  Uri? get fileUri;
}

class RegularStructuralParameterDeclaration
    implements StructuralParameterDeclaration {
  final List<MetadataBuilder>? metadata;

  @override
  final String name;

  @override
  final int fileOffset;

  @override
  final Uri fileUri;

  @override
  final bool isWildcard;

  RegularStructuralParameterDeclaration({
    required this.metadata,
    required this.name,
    required this.fileOffset,
    required this.fileUri,
    required this.isWildcard,
  });
}

class SyntheticStructuralParameterDeclaration
    implements StructuralParameterDeclaration {
  final StructuralParameterBuilder _builder;

  SyntheticStructuralParameterDeclaration(this._builder);

  @override
  int get fileOffset => _builder.fileOffset;

  @override
  Uri? get fileUri => _builder.fileUri;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isWildcard => _builder.isWildcard;

  @override
  String get name => _builder.name;
}
