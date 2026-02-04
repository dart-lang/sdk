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
  /// If [name] is `[]` or `[]=` then the `operator []` and `operator []=`
  /// members are returned as the [MemberLookupResult.getable] and
  /// [MemberLookupResult.setable], respectively.
  MemberLookupResult? lookupExtensionMemberByName(Name name);
}

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
  // Coverage-ignore(suite): Not run.
  Nullability computeNullabilityWithArguments(
    List<TypeBuilder>? typeArguments, {
    required Map<TypeParameterBuilder, TraversalState>
    typeParametersTraversalState,
  }) => Nullability.nonNullable;

  @override
  MemberLookupResult? lookupExtensionMemberByName(Name name) {
    if (name.isPrivate && libraryBuilder.library != name.library) {
      return null;
    }

    MemberLookupResult? result = lookupLocalMember(name.text, required: false);
    if (result != null && result.isInvalidLookup) {
      return result;
    }

    if (name == indexGetName) {
      // We need to find `operator []=` as well.
      MemberLookupResult? setterResult = lookupLocalMember(
        indexSetName.text,
        required: false,
      );
      if (setterResult != null && !setterResult.isInvalidLookup) {
        if (result != null) {
          // Return `operator []` and `operator []=` as the getable and
          // setable results, respectively.
          return new GetableSetableMemberResult(
            result.getable!,
            setterResult.getable!,
            isStatic: result.isStatic,
          );
          // Return `operator []=` as the setable result.
        } else {
          return new SetableMemberResult(
            setterResult.getable!,
            isStatic: setterResult.isStatic,
          );
        }
      } else {
        // Return `operator []` as the getable result.
        return result;
      }
    } else if (name == indexSetName) {
      // We need to find `operator []` as well.
      MemberLookupResult? getterResult = lookupLocalMember(
        indexGetName.text,
        required: false,
      );
      if (getterResult != null && !getterResult.isInvalidLookup) {
        if (result != null) {
          // Return `operator []` and `operator []=` as the getable and
          // setable results, respectively.
          return new GetableSetableMemberResult(
            getterResult.getable!,
            result.getable!,
            isStatic: result.isStatic,
          );
        } else {
          // Return `operator []` as the getable result.
          return getterResult;
        }
      } else if (result != null) {
        // Return `operator []=` as the setable result.
        return new SetableMemberResult(
          result.getable!,
          isStatic: result.isStatic,
        );
      } else {
        return null;
      }
    } else {
      return result;
    }
  }
}
