// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'declaration_builders.dart';

abstract class ExtensionTypeDeclarationBuilder
    implements DeclarationBuilder, ClassMemberAccess {
  /// The type of the underlying representation.
  DartType get declaredRepresentationType;

  /// The type builder of the underlying representation.
  TypeBuilder? get declaredRepresentationTypeBuilder;

  /// Return the [ExtensionTypeDeclaration] built by this builder.
  ExtensionTypeDeclaration get extensionTypeDeclaration;

  /// Returns a list of the classes and extension types implemented by this
  /// extension type.
  List<TypeBuilder>? get interfaceBuilders;

  @override
  Uri get fileUri;

  /// Computes the inherent nullability of this extension type.
  ///
  /// An extension type is non-nullable if it implements a non-nullable type.
  Nullability computeNullability(
      {Map<ExtensionTypeDeclarationBuilder, TraversalState>? traversalState});
}

abstract class ExtensionTypeDeclarationBuilderImpl
    extends DeclarationBuilderImpl
    with DeclarationBuilderMixin
    implements ExtensionTypeDeclarationBuilder {
  @override
  DartType buildAliasedTypeWithBuiltArguments(
      LibraryBuilder library,
      Nullability nullability,
      List<DartType> arguments,
      TypeUse typeUse,
      Uri fileUri,
      int charOffset,
      {required bool hasExplicitTypeArguments}) {
    ExtensionType type =
        new ExtensionType(extensionTypeDeclaration, nullability, arguments);
    if (typeParametersCount != 0 && library is SourceLibraryBuilder) {
      library.registerBoundsCheck(type, fileUri, charOffset, typeUse,
          inferred: !hasExplicitTypeArguments);
    }
    return type;
  }

  @override
  Nullability computeNullabilityWithArguments(List<TypeBuilder>? typeArguments,
      {required Map<TypeParameterBuilder, TraversalState>
          typeParametersTraversalState}) {
    return computeNullability();
  }
}
