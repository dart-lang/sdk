// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.function_type_alias_builder;

import 'package:kernel/ast.dart'
    show
        DartType,
        DynamicType,
        InvalidType,
        Nullability,
        TypeParameter,
        Typedef;

import 'package:kernel/type_algebra.dart' show substitute, uniteNullabilities;
import 'package:kernel/src/legacy_erasure.dart';

import '../fasta_codes.dart'
    show
        noLength,
        templateCyclicTypedef,
        templateTypeArgumentMismatch,
        messageTypedefTypeVariableNotConstructor,
        messageTypedefTypeVariableNotConstructorCause;

import '../problems.dart' show unhandled;

import 'class_builder.dart';
import 'library_builder.dart';
import 'metadata_builder.dart';
import 'named_type_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';
import 'type_declaration_builder.dart';
import 'type_variable_builder.dart';

abstract class TypeAliasBuilder implements TypeDeclarationBuilder {
  TypeBuilder get type;

  /// The [Typedef] built by this builder.
  Typedef get typedef;

  DartType thisType;

  String get debugName;

  LibraryBuilder get parent;

  LibraryBuilder get library;

  List<TypeVariableBuilder> get typeVariables;

  int varianceAt(int index);

  bool get fromDill => false;

  DartType buildThisType();

  /// [arguments] have already been built.
  DartType buildTypesWithBuiltArguments(LibraryBuilder library,
      Nullability nullability, List<DartType> arguments);

  List<DartType> buildTypeArguments(
      LibraryBuilder library, List<TypeBuilder> arguments,
      [bool notInstanceContext]);

  /// Returns `true` if this typedef is an alias of the `Null` type.
  bool get isNullAlias;

  @override
  DartType buildType(LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder, List<TypeBuilder> arguments,
      [bool notInstanceContext]);

  /// Returns the [TypeDeclarationBuilder] for the type aliased by `this`,
  /// based on the given [typeArguments]. It expands type aliases repeatedly
  /// until it encounters a builder which is not a [TypeAliasBuilder].
  ///
  /// If [isInvocation] is false: In this case it is required that
  /// `typeArguments.length == typeVariables.length`. The [typeArguments] are
  /// threaded through the expansion if needed, and the resulting declaration
  /// is returned.
  ///
  /// If [isInvocation] is true: In this case [typeArguments] are ignored, but
  /// [invocationCharOffset] and [invocationFileUri] must be non-null. If `this`
  /// type alias expands in one or more steps to a builder which is not a
  /// [TypeAliasBuilder] nor a [TypeVariableBuilder] then that builder is
  /// returned. If this type alias is cyclic or expands to an invalid type or
  /// a type that does not have a declaration (say, a function type) then `this`
  /// is returned (when the type was invalid: with `thisType` set to
  /// `const InvalidType()`). If `this` type alias expands to a
  /// [TypeVariableBuilder] then the type alias cannot be used in a constructor
  /// invocation. Then an error is emitted and `this` is returned.
  TypeDeclarationBuilder unaliasDeclaration(List<TypeBuilder> typeArguments,
      {bool isInvocation = false,
      int invocationCharOffset,
      Uri invocationFileUri});

  /// Compute type arguments passed to [ClassBuilder] from unaliasDeclaration.
  /// This method does not check for cycles and may only be called if an
  /// invocation of `this.unaliasDeclaration(typeArguments)` has returned a
  /// [ClassBuilder].
  ///
  /// The parameter [typeArguments] would typically be obtained from a
  /// [NamedTypeBuilder] whose `declaration` is `this`. It must be non-null.
  ///
  /// Returns `null` if an error occurred.
  ///
  /// The method substitutes through the chain of type aliases denoted by
  /// [this], such that the returned [TypeBuilder]s are appropriate type
  /// arguments for passing to the [ClassBuilder] which is the end of the
  /// unaliasing chain.
  List<TypeBuilder> unaliasTypeArguments(List<TypeBuilder> typeArguments);
}

abstract class TypeAliasBuilderImpl extends TypeDeclarationBuilderImpl
    implements TypeAliasBuilder {
  TypeAliasBuilderImpl(List<MetadataBuilder> metadata, String name,
      LibraryBuilder parent, int charOffset)
      : super(metadata, 0, name, parent, charOffset);

  String get debugName => "TypeAliasBuilder";

  LibraryBuilder get parent => super.parent;

  LibraryBuilder get library => super.parent;

  /// [arguments] have already been built.
  DartType buildTypesWithBuiltArguments(LibraryBuilder library,
      Nullability nullability, List<DartType> arguments) {
    DartType thisType = buildThisType();
    if (const DynamicType() == thisType) return thisType;
    Nullability adjustedNullability =
        isNullAlias ? Nullability.nullable : nullability;
    DartType result = thisType.withDeclaredNullability(adjustedNullability);
    if (typedef.typeParameters.isEmpty && arguments == null) return result;
    Map<TypeParameter, DartType> substitution = <TypeParameter, DartType>{};
    for (int i = 0; i < typedef.typeParameters.length; i++) {
      substitution[typedef.typeParameters[i]] = arguments[i];
    }
    return substitute(result, substitution);
  }

  @override
  DartType buildType(LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder, List<TypeBuilder> arguments,
      [bool notInstanceContext]) {
    DartType thisType = buildThisType();
    if (thisType is InvalidType) return thisType;

    // The following won't work if the right-hand side of the typedef is a
    // FutureOr.
    Nullability nullability;
    if (isNullAlias) {
      // Null is always nullable.
      nullability = Nullability.nullable;
    } else if (!parent.isNonNullableByDefault ||
        !library.isNonNullableByDefault) {
      // The typedef is defined or used in an opt-out library so the nullability
      // is based on the use site alone.
      nullability = nullabilityBuilder.build(library);
    } else {
      nullability = uniteNullabilities(
          thisType.declaredNullability, nullabilityBuilder.build(library));
    }
    DartType result;
    if (typedef.typeParameters.isEmpty && arguments == null) {
      result = thisType.withDeclaredNullability(nullability);
    } else {
      // Otherwise, substitute.
      result = buildTypesWithBuiltArguments(
          library, nullability, buildTypeArguments(library, arguments));
    }
    if (!library.isNonNullableByDefault) {
      result = legacyErasure(result);
    }
    return result;
  }

  TypeDeclarationBuilder _cachedUnaliasedDeclaration;

  /// Returns the [TypeDeclarationBuilder] for the type aliased by `this`,
  /// based on the given [typeArguments]. It expands type aliases repeatedly
  /// until it encounters a builder which is not a [TypeAliasBuilder].
  ///
  /// If [isInvocation] is false: In this case it is required that
  /// `typeArguments.length == typeVariables.length`. The [typeArguments] are
  /// threaded through the expansion if needed, and the resulting declaration
  /// is returned.
  ///
  /// If [isInvocation] is true: In this case [typeArguments] are ignored, but
  /// [invocationCharOffset] and [invocationFileUri] must be non-null. If `this`
  /// type alias expands in one or more steps to a builder which is not a
  /// [TypeAliasBuilder] nor a [TypeVariableBuilder] then that builder is
  /// returned. If this type alias is cyclic or expands to an invalid type or
  /// a type that does not have a declaration (say, a function type) then `this`
  /// is returned (when the type was invalid: with `thisType` set to
  /// `const InvalidType()`). If `this` type alias expands to a
  /// [TypeVariableBuilder] then the type alias cannot be used in a constructor
  /// invocation. Then an error is emitted and `this` is returned.
  TypeDeclarationBuilder unaliasDeclaration(List<TypeBuilder> typeArguments,
      {bool isInvocation = false,
      int invocationCharOffset,
      Uri invocationFileUri}) {
    if (_cachedUnaliasedDeclaration != null) return _cachedUnaliasedDeclaration;
    Set<TypeDeclarationBuilder> builders = {this};
    TypeDeclarationBuilder current = this;
    while (current is TypeAliasBuilder) {
      TypeAliasBuilder currentAliasBuilder = current;
      TypeDeclarationBuilder next = currentAliasBuilder.type?.declaration;
      if (next != null) {
        current = next;
      } else {
        // `currentAliasBuilder`'s right hand side is not a [NamedTypeBuilder].
        // There is no ultimate declaration, so unaliasing is a no-op.
        return _cachedUnaliasedDeclaration = this;
      }
      if (builders.contains(current)) {
        // Cyclic type alias.
        currentAliasBuilder.library.addProblem(
            templateCyclicTypedef.withArguments(this.name),
            charOffset,
            noLength,
            fileUri);
        // Ensure that it is not reported again.
        thisType = const InvalidType();
        return _cachedUnaliasedDeclaration = this;
      }
      if (current is TypeVariableBuilder) {
        // Encountered `typedef F<..X..> = X`, must repeat the computation,
        // tracing type variables at each step. We repeat everything because
        // that kind of type alias is expected to be rare. We cannot save it in
        // `_cachedUnaliasedDeclaration` because it changes from call to call
        // with type aliases of this kind. Note that every `aliasBuilder.type`
        // up to this point is a [NamedTypeBuilder], because only they can have
        // a non-null `type`. However, a constructor invocation is not admitted.
        if (isInvocation) {
          library.addProblem(messageTypedefTypeVariableNotConstructor,
              invocationCharOffset, noLength, invocationFileUri,
              context: [
                messageTypedefTypeVariableNotConstructorCause.withLocation(
                    current.fileUri, current.charOffset, noLength),
              ]);
          return this;
        }
        return _unaliasDeclaration(typeArguments);
      }
    }
    return _cachedUnaliasedDeclaration = current;
  }

  // Helper method with same purpose as [unaliasDeclaration], for a hard case.
  //
  // It is required that `typeArguments.length == typeVariables.length`, and
  // [typeArguments] are considered to be passed as actual type arguments to
  // [this]. It is also required that the sequence traversed by following
  // `.type.declaration` starting from `this` in a finite number of steps
  // reaches a `TypeVariableBuilder`. So this method does not check for cycles,
  // nor for other types than `NamedTypeBuilder` and `TypeVariableBuilder`
  // after each step over a `.type.declaration`.
  //
  // Returns `this` if an error is encountered.
  //
  // This method more expensive than [unaliasDeclaration], but it will handle
  // the case where a sequence of type aliases F_1 .. F_k is such that F_i
  // has a right hand side which is F_{i+1}, possibly applied to some type
  // arguments, for all i in 1 .. k-1, and the right hand side of F_k is a type
  // variable. In this case, the unaliased declaration must be obtained from
  // the type argument, which is the reason why we must trace them.
  TypeDeclarationBuilder _unaliasDeclaration(List<TypeBuilder> typeArguments) {
    TypeDeclarationBuilder currentDeclarationBuilder = this;
    TypeAliasBuilder previousAliasBuilder = null;
    List<TypeBuilder> currentTypeArguments = typeArguments;
    while (currentDeclarationBuilder is TypeAliasBuilder) {
      TypeAliasBuilder currentAliasBuilder = currentDeclarationBuilder;
      TypeBuilder nextTypeBuilder = currentAliasBuilder.type;
      if (nextTypeBuilder is NamedTypeBuilder) {
        Map<TypeVariableBuilder, TypeBuilder> substitution = {};
        int index = 0;
        if (currentTypeArguments == null || currentTypeArguments.isEmpty) {
          if (currentAliasBuilder.typeVariables != null) {
            List<TypeBuilder> defaultTypeArguments =
                new List<TypeBuilder>.filled(
                    currentAliasBuilder.typeVariables.length, null,
                    growable: true);
            for (int i = 0; i < defaultTypeArguments.length; ++i) {
              defaultTypeArguments[i] =
                  currentAliasBuilder.typeVariables[i].defaultType;
            }
            currentTypeArguments = defaultTypeArguments;
          } else {
            currentTypeArguments = <TypeBuilder>[];
          }
        }
        if ((currentAliasBuilder.typeVariables?.length ?? 0) !=
            currentTypeArguments.length) {
          if (previousAliasBuilder != null) {
            previousAliasBuilder.library.addProblem(
                templateTypeArgumentMismatch.withArguments(
                    currentAliasBuilder.typeVariables?.length ?? 0),
                previousAliasBuilder.charOffset,
                noLength,
                previousAliasBuilder.fileUri);
            previousAliasBuilder.thisType = const InvalidType();
            return this;
          } else {
            // This implies that `currentAliasBuilder` is [this], and the call
            // violated the precondition.
            return unhandled("$this: Wrong number of type arguments",
                "_unaliasDeclaration", -1, null);
          }
        }
        for (TypeVariableBuilder typeVariableBuilder
            in currentAliasBuilder.typeVariables ?? []) {
          substitution[typeVariableBuilder] = currentTypeArguments[index];
          ++index;
        }
        TypeDeclarationBuilder nextDeclarationBuilder =
            nextTypeBuilder.declaration;
        TypeBuilder substitutedBuilder = nextTypeBuilder.subst(substitution);
        if (nextDeclarationBuilder is TypeVariableBuilder) {
          // We have reached the end of the type alias chain which yields a
          // type argument, which may become a type alias, possibly with its
          // own similar chain. We do not simply continue the iteration here,
          // though: We must call `unaliasDeclaration` because it can be
          // cyclic; we want to do it as well, because the result could be
          // cached.
          if (substitutedBuilder is NamedTypeBuilder) {
            TypeDeclarationBuilder declarationBuilder =
                substitutedBuilder.declaration;
            if (declarationBuilder is TypeAliasBuilder) {
              return declarationBuilder
                  .unaliasDeclaration(substitutedBuilder.arguments);
            }
            return declarationBuilder;
          }
          // This can be null, e.g, `substitutedBuilder is FunctionTypeBuilder`
          return substitutedBuilder.declaration;
        }
        // Not yet at the end of the chain, more named builders to come.
        NamedTypeBuilder namedBuilder = substitutedBuilder;
        currentDeclarationBuilder = namedBuilder.declaration;
        currentTypeArguments = namedBuilder.arguments;
        previousAliasBuilder = currentAliasBuilder;
      } else {
        // Violation of requirement that we only step through
        // `NamedTypeBuilder`s ending in a `TypeVariableBuilder`.
        return null;
      }
    }
    return currentDeclarationBuilder;
  }

  /// Compute type arguments passed to [ClassBuilder] from unaliasDeclaration.
  /// This method does not check for cycles and may only be called if an
  /// invocation of `this.unaliasDeclaration(typeArguments)` has returned a
  /// [ClassBuilder].
  ///
  /// The parameter [typeArguments] would typically be obtained from a
  /// [NamedTypeBuilder] whose `declaration` is `this`. It must be non-null.
  ///
  /// Returns `null` if an error occurred.
  ///
  /// The method substitutes through the chain of type aliases denoted by
  /// [this], such that the returned [TypeBuilder]s are appropriate type
  /// arguments for passing to the [ClassBuilder] which is the end of the
  /// unaliasing chain.
  List<TypeBuilder> unaliasTypeArguments(List<TypeBuilder> typeArguments) {
    TypeDeclarationBuilder currentDeclarationBuilder = this;
    List<TypeBuilder> currentTypeArguments = typeArguments;
    while (currentDeclarationBuilder is TypeAliasBuilder) {
      TypeAliasBuilder currentAliasBuilder = currentDeclarationBuilder;
      TypeBuilder nextTypeBuilder = currentAliasBuilder.type;
      assert(nextTypeBuilder is NamedTypeBuilder);
      NamedTypeBuilder namedNextTypeBuilder = nextTypeBuilder;
      Map<TypeVariableBuilder, TypeBuilder> substitution = {};
      int index = 0;
      if (currentTypeArguments == null || currentTypeArguments.isEmpty) {
        if (currentAliasBuilder.typeVariables != null) {
          List<TypeBuilder> defaultTypeArguments = new List<TypeBuilder>.filled(
              currentAliasBuilder.typeVariables.length, null,
              growable: true);
          for (int i = 0; i < defaultTypeArguments.length; ++i) {
            defaultTypeArguments[i] =
                currentAliasBuilder.typeVariables[i].defaultType;
          }
          currentTypeArguments = defaultTypeArguments;
        } else {
          currentTypeArguments = <TypeBuilder>[];
        }
      }
      assert((currentAliasBuilder.typeVariables?.length ?? 0) ==
          currentTypeArguments.length);
      for (TypeVariableBuilder typeVariableBuilder
          in currentAliasBuilder.typeVariables ?? []) {
        substitution[typeVariableBuilder] = currentTypeArguments[index];
        ++index;
      }
      TypeDeclarationBuilder nextDeclarationBuilder =
          namedNextTypeBuilder.declaration;
      TypeBuilder substitutedBuilder = nextTypeBuilder.subst(substitution);
      if (nextDeclarationBuilder is TypeVariableBuilder) {
        // We have reached the end of the type alias chain which yields a
        // type argument, which may become a type alias, possibly with its
        // own similar chain.
        assert(substitutedBuilder is NamedTypeBuilder);
        NamedTypeBuilder namedSubstitutedBuilder = substitutedBuilder;
        TypeDeclarationBuilder declarationBuilder =
            namedSubstitutedBuilder.declaration;
        if (declarationBuilder is TypeAliasBuilder) {
          return declarationBuilder
              .unaliasTypeArguments(namedSubstitutedBuilder.arguments);
        }
        assert(declarationBuilder is ClassBuilder);
        return namedSubstitutedBuilder.arguments ?? [];
      }
      // Not yet at the end of the chain, more named builders to come.
      NamedTypeBuilder namedBuilder = substitutedBuilder;
      currentDeclarationBuilder = namedBuilder.declaration;
      currentTypeArguments = namedBuilder.arguments ?? [];
    }
    return currentTypeArguments;
  }
}

final InvalidType cyclicTypeAliasMarker = new InvalidType();
