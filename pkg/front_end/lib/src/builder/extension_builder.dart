// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'declaration_builders.dart';

abstract class ExtensionBuilder implements DeclarationBuilder {
  /// The type of the on-clause of the extension declaration.
  TypeBuilder get onType;

  /// Reference for the extension built by this builder.
  Reference get reference;

  /// Return the [Extension] built by this builder.
  Extension get extension;

  /// Looks up extension member by [name] taking privacy into account.
  ///
  /// If [setter] is `true` the sought member is a setter or assignable field.
  /// If [required] is `true` and no member is found an internal problem is
  /// reported.
  ///
  /// If the extension member is a duplicate, `null` is returned.
  MemberLookupResult? lookupLocalMemberByName(
    Name name, {
    bool required = false,
  });
}

// Coverage-ignore(suite): Not run.
abstract class ExtensionBuilderImpl extends DeclarationBuilderImpl
    with DeclarationBuilderMixin
    implements ExtensionBuilder {
  @override
  DartType buildAliasedTypeWithBuiltArguments(
    LibraryBuilder library,
    Nullability nullability,
    List<DartType> arguments,
    TypeUse typeUse,
    Uri fileUri,
    int charOffset, {
    required bool hasExplicitTypeArguments,
  }) {
    throw new UnsupportedError(
      "ExtensionBuilder.buildTypesWithBuiltArguments "
      "is not supported in library '${library.importUri}'.",
    );
  }

  @override
  Nullability computeNullabilityWithArguments(
    List<TypeBuilder>? typeArguments, {
    required Map<TypeParameterBuilder, TraversalState>
    typeParametersTraversalState,
  }) => Nullability.nonNullable;
}
