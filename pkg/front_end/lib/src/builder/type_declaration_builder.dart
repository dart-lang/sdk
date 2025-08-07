// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'declaration_builders.dart';

// Coverage-ignore(suite): Not run.
abstract class ITypeDeclarationBuilder
    implements Builder, LookupResult, NamedBuilder {
  @override
  String get name;

  bool get isNamedMixinApplication;

  int get typeParametersCount => 0;

  /// Return `true` if this type declaration is an enum.
  bool get isEnum;

  /// Creates the [DartType] corresponding to this declaration applied with
  /// [arguments] in [library] with the syntactical nullability defined by
  /// [nullabilityBuilder]. The created type will contain [TypedefType] instead
  /// of their unaliased type.
  ///
  /// For instance, if this declaration is a class declaration `C`, then
  /// an occurrence of `C<int>?` in a null safe library `lib1` would call
  /// `buildType(<lib1>, <?>, [<int>])` to create `C<int>?`, or `C<int>` in a
  /// legacy library `lib2` call `buildType(<lib2>, <> [<int>]` to create
  /// `C<int*>*`.
  DartType buildAliasedType(
      LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder,
      List<TypeBuilder>? arguments,
      TypeUse typeUse,
      Uri fileUri,
      int charOffset,
      ClassHierarchyBase? hierarchy,
      {required bool hasExplicitTypeArguments});

  /// [arguments] have already been built.
  DartType buildAliasedTypeWithBuiltArguments(
      LibraryBuilder library,
      Nullability nullability,
      List<DartType> arguments,
      TypeUse typeUse,
      Uri fileUri,
      int charOffset,
      {required bool hasExplicitTypeArguments});

  /// Computes the nullability of this type declaration when instantiated with
  /// [typeArguments].
  ///
  /// [typeParametersTraversalState] is passed to handle cyclic dependencies
  /// between type parameters,
  Nullability computeNullabilityWithArguments(List<TypeBuilder>? typeArguments,
      {required Map<TypeParameterBuilder, TraversalState>
          typeParametersTraversalState});
}

abstract class TypeDeclarationBuilderImpl extends NamedBuilderImpl
    with LookupResultMixin
    implements ITypeDeclarationBuilder {
  @override
  // Coverage-ignore(suite): Not run.
  bool get isNamedMixinApplication => false;

  @override
  bool get isEnum => false;

  @override
  String get fullNameForErrors => name;

  @override
  NamedBuilder get getable => this;

  @override
  NamedBuilder? get setable => null;

  @override
  String toString() {
    return '$runtimeType($name)';
  }
}
