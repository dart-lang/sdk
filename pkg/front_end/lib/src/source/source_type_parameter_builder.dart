// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/source/source_library_builder.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../base/scope.dart';
import '../builder/declaration_builders.dart';
import '../builder/metadata_builder.dart';
import '../builder/type_builder.dart';
import '../fragment/fragment.dart';
import '../kernel/body_builder_context.dart';

class SourceNominalParameterBuilder extends NominalParameterBuilder {
  final NominalParameterDeclaration _declaration;

  @override
  TypeBuilder? bound;

  @override
  TypeBuilder? defaultType;

  final List<MetadataBuilder>? metadata;

  SourceNominalParameterBuilder? actualOrigin;

  final TypeParameter actualParameter;

  /// [NominalParameterBuilder] overrides ==/hashCode in terms of
  /// [actualParameter] making it vulnerable to use in sets and maps. This
  /// fields tracks the first access to [hashCode] when asserts are enabled, to
  /// signal if the [hashCode] is used before updates to [actualParameter].
  StackTrace? _hasHashCode;

  SourceNominalParameterBuilder(this._declaration,
      {this.bound, super.variableVariance, this.metadata})
      : actualParameter = new TypeParameter(
            _declaration.name == NominalParameterBuilder.noNameSentinel
                ? null
                : _declaration.name,
            null)
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
  Uri? get fileUri => _declaration.fileUri;

  void buildOutlineExpressions(
      SourceLibraryBuilder libraryBuilder,
      BodyBuilderContext bodyBuilderContext,
      ClassHierarchy classHierarchy,
      LookupScope scope) {
    MetadataBuilder.buildAnnotations(parameter, metadata, bodyBuilderContext,
        libraryBuilder, fileUri!, scope);
  }

  SourceNominalParameterBuilder get origin => actualOrigin ?? this;

  @override
  TypeParameter get parameter => origin.actualParameter;

  void setAugmentation(covariant SourceNominalParameterBuilder augmentation) {
    assert(
        _hasHashCode == null,
        "Cannot apply augmentation since to $this since hashCode has already "
        "been computed from $actualParameter @\n$_hasHashCode");
    augmentation.actualOrigin = this;
  }

  @override
  void addAugmentation(covariant SourceNominalParameterBuilder augmentation) {
    setAugmentation(augmentation);
  }

  @override
  void applyAugmentation(covariant SourceNominalParameterBuilder augmentation) {
    setAugmentation(augmentation);
  }

  @override
  bool operator ==(Object other) {
    return other is NominalParameterBuilder && parameter == other.parameter;
  }

  @override
  int get hashCode {
    assert(() {
      _hasHashCode ??= StackTrace.current;
      return true;
    }());
    return parameter.hashCode;
  }

  static List<TypeParameter>? typeParametersFromBuilders(
      List<SourceNominalParameterBuilder>? builders) {
    if (builders == null) return null;
    return new List<TypeParameter>.generate(
        builders.length, (int i) => builders[i].parameter,
        growable: true);
  }
}

abstract class NominalParameterDeclaration {
  String get name;

  TypeParameterKind get kind;

  bool get isWildcard;

  int get fileOffset;

  Uri? get fileUri;
}

class RegularNominalParameterDeclaration
    implements NominalParameterDeclaration {
  final TypeParameterFragment _fragment;

  RegularNominalParameterDeclaration(this._fragment);

  @override
  int get fileOffset => _fragment.nameOffset;

  @override
  Uri? get fileUri => _fragment.fileUri;

  @override
  bool get isWildcard => _fragment.isWildcard;

  @override
  TypeParameterKind get kind => _fragment.kind;

  @override
  String get name => _fragment.variableName;
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
  final Uri? fileUri;

  DirectNominalParameterDeclaration(
      {required this.name,
      required this.kind,
      required this.isWildcard,
      required this.fileOffset,
      required this.fileUri});
}

class SyntheticNominalParameterDeclaration
    implements NominalParameterDeclaration {
  final NominalParameterBuilder _builder;

  @override
  final int fileOffset;

  @override
  final Uri? fileUri;

  @override
  final TypeParameterKind kind;

  SyntheticNominalParameterDeclaration(this._builder,
      {required this.kind, required this.fileOffset, required this.fileUri});

  @override
  bool get isWildcard => _builder.isWildcard;

  @override
  String get name => _builder.name;
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

  SourceStructuralParameterBuilder(this._declaration,
      {this.bound, Variance? parameterVariance, this.metadata})
      : parameter = new StructuralParameter(
            _declaration.name == StructuralParameterBuilder.noNameSentinel
                ? null
                : _declaration.name,
            null)
          ..fileOffset = _declaration.fileOffset
          ..variance = parameterVariance;

  @override
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

  final TypeBuilder? bound;

  @override
  final int fileOffset;

  @override
  final Uri fileUri;

  @override
  final bool isWildcard;

  RegularStructuralParameterDeclaration(
      {required this.metadata,
      required this.name,
      required this.bound,
      required this.fileOffset,
      required this.fileUri,
      required this.isWildcard});
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
  bool get isWildcard => _builder.isWildcard;

  @override
  String get name => _builder.name;
}
