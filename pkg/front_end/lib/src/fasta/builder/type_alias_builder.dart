// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'declaration_builders.dart';

abstract class TypeAliasBuilder implements TypeDeclarationBuilder {
  TypeBuilder get type;

  /// The [Typedef] built by this builder.
  Typedef get typedef;

  DartType? thisType;

  String get debugName;

  @override
  LibraryBuilder get parent;

  LibraryBuilder get libraryBuilder;

  @override
  Uri get fileUri;

  List<TypeVariableBuilder>? get typeVariables;

  int varianceAt(int index);

  bool get fromDill => false;

  DartType buildThisType();

  List<DartType> buildAliasedTypeArguments(LibraryBuilder library,
      List<TypeBuilder>? arguments, ClassHierarchyBase? hierarchy);

  /// Returns `true` if this typedef is an alias of the `Null` type.
  bool get isNullAlias;

  /// Returns the unaliased type for this type alias with the given
  /// [typeArguments], or `null` if this type alias is cyclic.
  ///
  /// If [usedTypeAliasBuilders] is supplied, the [TypeAliasBuilder]s used
  /// during unaliasing are added to [usedTypeAliasBuilders].
  ///
  /// If [unboundTypes] is provided, created type builders that are not bound
  /// are added to [unboundTypes]. Otherwise, creating an unbound type builder
  /// results in an assertion error.
  ///
  /// If [unboundTypeVariables] is provided, created type variable builders are
  /// added to [unboundTypeVariables]. Otherwise, creating a
  /// type variable builder result in an assertion error.
  ///
  /// The [unboundTypes] and [unboundTypeVariables] must be processed by the
  /// call, unless the created [TypeBuilder]s and [TypeVariableBuilder]s are
  /// not part of the generated AST.
  // TODO(johnniwinther): Used this instead of [unaliasDeclaration] and
  // [unaliasTypeArguments].
  TypeBuilder? unalias(List<TypeBuilder>? typeArguments,
      {Set<TypeAliasBuilder>? usedTypeAliasBuilders,
      List<TypeBuilder>? unboundTypes,
      List<StructuralVariableBuilder>? unboundTypeVariables});

  /// Helper method for computing [unalias].
  ///
  /// Returns the directly alias of this type alias with the given
  /// [typeArguments], or `null` if this type alias is cyclic.
  ///
  /// [currentTypeAliasBuilders] contains the type alias builders used so
  /// for in the computation of [unalias]. This method will add this type alias
  /// builder to [currentTypeAliasBuilders] or report a cyclic error if this
  /// type alias builder is already in the set.
  ///
  /// If [unboundTypes] is provided, created type builders that are not bound
  /// are added to [unboundTypes]. Otherwise, creating an unbound type builder
  /// results in an assertion error.
  ///
  /// If [unboundTypeVariables] is provided, created type variable builders are
  /// added to [unboundTypeVariables]. Otherwise, creating a
  /// type variable builder result in an assertion error.
  ///
  /// The [unboundTypes] and [unboundTypeVariables] must be processed by the
  /// call, unless the created [TypeBuilder]s and [TypeVariableBuilder]s are
  /// not part of the generated AST.
  TypeBuilder? unaliasOnce(
      List<TypeBuilder>? typeArguments,
      Set<TypeAliasBuilder> currentTypeAliasBuilders,
      List<TypeBuilder>? unboundTypes,
      List<StructuralVariableBuilder>? unboundTypeVariables);

  /// Returns the [TypeDeclarationBuilder] for the type aliased by `this`,
  /// based on the given [typeArguments]. It expands type aliases repeatedly
  /// until it encounters a builder which is not a [TypeAliasBuilder].
  ///
  /// If [isUsedAsClass] is false: In this case it is required that
  /// `typeArguments.length == typeVariables.length`. The [typeArguments] are
  /// threaded through the expansion if needed, and the resulting declaration
  /// is returned.
  ///
  /// If [isUsedAsClass] is true: In this case [typeArguments] are ignored, but
  /// [usedAsClassCharOffset] and [usedAsClassFileUri] must be non-null. If
  /// `this` type alias expands in one or more steps to a builder which is not a
  /// [TypeAliasBuilder] nor a [TypeVariableBuilder] then that builder is
  /// returned. If this type alias is cyclic or expands to an invalid type or
  /// a type that does not have a declaration (say, a function type) then `this`
  /// is returned (when the type was invalid: with `thisType` set to
  /// `const InvalidType()`). If `this` type alias expands to a
  /// [TypeVariableBuilder] then the type alias cannot be used in a constructor
  /// invocation. Then an error is emitted and `this` is returned.
  TypeDeclarationBuilder? unaliasDeclaration(List<TypeBuilder>? typeArguments,
      {bool isUsedAsClass = false,
      int? usedAsClassCharOffset,
      Uri? usedAsClassFileUri});

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
  // TODO(johnniwinther): Should we enforce that [typeArguments] are non-null
  // as stated in the docs? It is not needed for the implementation.
  List<TypeBuilder>? unaliasTypeArguments(List<TypeBuilder>? typeArguments);

  /// Returns the lowering for the constructor or factory named [name] on the
  /// effective target class of this typedef.
  ///
  /// For instance, if we have
  ///
  ///     class A<T> {
  ///       A();
  ///     }
  ///     typedef F = A<int>;
  ///     typedef G = F;
  ///     typedef H<X, Y> = A<X>;
  ///
  /// the lowering will create
  ///
  ///     A<int> _#F#new#tearOff() => new A<int>();
  ///     A<int> _#G#new#tearOff() => new A<int>();
  ///     A<int> _#H#new#tearOff<X, Y>() => new A<X>();
  ///
  /// which will be return by [findConstructorOrFactory] on `F`, `G`, `H` with
  /// name 'new' or ''.
  Procedure? findConstructorOrFactory(
      String name, int charOffset, Uri uri, LibraryBuilder accessingLibrary);
}

abstract class TypeAliasBuilderImpl extends TypeDeclarationBuilderImpl
    implements TypeAliasBuilder {
  @override
  final Uri fileUri;

  TypeAliasBuilderImpl(List<MetadataBuilder>? metadata, String name,
      LibraryBuilder parent, int charOffset)
      : fileUri = parent.fileUri,
        super(metadata, 0, name, parent, charOffset);

  @override
  String get debugName => "TypeAliasBuilder";

  @override
  LibraryBuilder get parent => super.parent as LibraryBuilder;

  @override
  LibraryBuilder get libraryBuilder => super.parent as LibraryBuilder;

  /// [arguments] have already been built.
  @override
  DartType buildAliasedTypeWithBuiltArguments(
      LibraryBuilder library,
      Nullability nullability,
      List<DartType>? arguments,
      TypeUse typeUse,
      Uri fileUri,
      int charOffset,
      {required bool hasExplicitTypeArguments}) {
    buildThisType();
    TypedefType type = new TypedefType(typedef, nullability, arguments);
    if (library is SourceLibraryBuilder) {
      if (typeVariablesCount != 0) {
        library.registerBoundsCheck(type, fileUri, charOffset, typeUse,
            inferred: !hasExplicitTypeArguments);
      }
      if (!library.libraryFeatures.genericMetadata.isEnabled) {
        library.registerGenericFunctionTypeCheck(type, fileUri, charOffset);
      }
    }

    return type;
  }

  @override
  DartType buildAliasedType(
      LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder,
      List<TypeBuilder>? arguments,
      TypeUse typeUse,
      Uri fileUri,
      int charOffset,
      ClassHierarchyBase? hierarchy,
      {required bool hasExplicitTypeArguments}) {
    DartType thisType = buildThisType();
    if (thisType is InvalidType) return thisType;

    Nullability nullability = nullabilityBuilder.build(library);
    return buildAliasedTypeWithBuiltArguments(
        library,
        nullability,
        buildAliasedTypeArguments(library, arguments, hierarchy),
        typeUse,
        fileUri,
        charOffset,
        hasExplicitTypeArguments: hasExplicitTypeArguments);
  }

  @override
  TypeBuilder? unalias(List<TypeBuilder>? typeArguments,
      {Set<TypeAliasBuilder>? usedTypeAliasBuilders,
      List<TypeBuilder>? unboundTypes,
      List<StructuralVariableBuilder>? unboundTypeVariables}) {
    Set<TypeAliasBuilder> currentTypeAliasBuilders;
    if (usedTypeAliasBuilders != null && usedTypeAliasBuilders.isEmpty) {
      currentTypeAliasBuilders = usedTypeAliasBuilders;
    } else {
      currentTypeAliasBuilders = {};
    }
    TypeBuilder? type = unaliasOnce(typeArguments, currentTypeAliasBuilders,
        unboundTypes, unboundTypeVariables);
    while (type is NamedTypeBuilder && type.declaration is TypeAliasBuilder) {
      TypeAliasBuilder? declaration = type.declaration as TypeAliasBuilder;
      type = declaration.unaliasOnce(type.arguments, currentTypeAliasBuilders,
          unboundTypes, unboundTypeVariables);
    }
    if (usedTypeAliasBuilders != null &&
        !identical(usedTypeAliasBuilders, currentTypeAliasBuilders)) {
      usedTypeAliasBuilders.addAll(currentTypeAliasBuilders);
    }
    return type;
  }

  @override
  TypeBuilder? unaliasOnce(
      List<TypeBuilder>? typeArguments,
      Set<TypeAliasBuilder> currentBuilders,
      List<TypeBuilder>? unboundTypes,
      List<StructuralVariableBuilder>? unboundTypeVariables) {
    if (!currentBuilders.add(this)) {
      // Cyclic type alias.
      libraryBuilder.addProblem(templateCyclicTypedef.withArguments(this.name),
          charOffset, noLength, fileUri);
      return null;
    }
    // TODO(johnniwinther): Handle/report type argument count mismatch. These
    // are currently reported through [unaliasDeclaration].
    if (typeVariables != null) {
      if (typeArguments == null ||
          typeArguments.length != typeVariables!.length) {
        typeArguments =
            new List<TypeBuilder>.generate(typeVariables!.length, (int i) {
          return typeVariables![i].defaultType!;
        }, growable: true);
      }
      Map<TypeVariableBuilder, TypeBuilder> substitution = {};
      for (int index = 0; index < typeArguments.length; index++) {
        substitution[typeVariables![index]] = typeArguments[index];
      }
      return type.subst(substitution,
          unboundTypes: unboundTypes,
          unboundTypeVariables: unboundTypeVariables);
    }
    return type;
  }

  TypeDeclarationBuilder? _cachedUnaliasedDeclaration;

  /// Returns the [TypeDeclarationBuilder] for the type aliased by `this`,
  /// based on the given [typeArguments]. It expands type aliases repeatedly
  /// until it encounters a builder which is not a [TypeAliasBuilder].
  ///
  /// The parameter [isUsedAsClass] indicates whether the type alias is being
  /// used as a class, e.g., as the class in an instance creation, as a
  /// superinterface, in a redirecting factory constructor, or to invoke a
  /// static member.
  ///
  /// If [isUsedAsClass] is false: In this case it is required that
  /// `typeArguments.length == typeVariables.length`. The [typeArguments] are
  /// threaded through the expansion if needed, and the resulting declaration
  /// is returned.
  ///
  /// If [isUsedAsClass] is true: In this case [typeArguments] can be null, but
  /// [usedAsClassCharOffset] and [usedAsClassFileUri] must be non-null. When
  /// [typeArguments] is null, the returned [TypeDeclarationBuilder] indicates
  /// which class the type alias denotes, without type arguments. If `this`
  /// type alias expands in one or more steps to a builder which is not a
  /// [TypeAliasBuilder] nor a [TypeVariableBuilder] then that builder is
  /// returned. If this type alias is cyclic or expands to an invalid type or
  /// a type that does not have a declaration (say, a function type) then `this`
  /// is returned (when the type was invalid: with `thisType` set to
  /// `const InvalidType()`). If `this` type alias expands to a
  /// [TypeVariableBuilder] then the type alias cannot be used as a class, in
  /// which case an error is emitted and `this` is returned.
  @override
  TypeDeclarationBuilder? unaliasDeclaration(List<TypeBuilder>? typeArguments,
      {bool isUsedAsClass = false,
      int? usedAsClassCharOffset,
      Uri? usedAsClassFileUri}) {
    if (_cachedUnaliasedDeclaration != null) {
      return _cachedUnaliasedDeclaration;
    }
    Set<TypeDeclarationBuilder> builders = {this};
    TypeDeclarationBuilder current = this;
    while (current is TypeAliasBuilder) {
      TypeAliasBuilder currentAliasBuilder = current;
      TypeDeclarationBuilder? next = currentAliasBuilder.type.declaration;
      if (next != null) {
        current = next;
      } else {
        // `currentAliasBuilder`'s right hand side is not a [NamedTypeBuilder].
        // There is no ultimate declaration, so unaliasing is a no-op.
        return _cachedUnaliasedDeclaration = this;
      }
      if (builders.contains(current)) {
        // Cyclic type alias.
        currentAliasBuilder.libraryBuilder.addProblem(
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
        // a non-null `type`. However, this type alias can not be used as a
        // class.
        if (isUsedAsClass) {
          List<TypeBuilder> freshTypeArguments = [
            if (typeVariables != null)
              for (TypeVariableBuilder typeVariable in typeVariables!)
                new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
                    typeVariable, libraryBuilder.nonNullableBuilder,
                    arguments: const [],
                    fileUri: fileUri,
                    charOffset: charOffset,
                    instanceTypeVariableAccess:
                        InstanceTypeVariableAccessState.Unexpected),
          ];
          TypeDeclarationBuilder? typeDeclarationBuilder =
              _unaliasDeclaration(freshTypeArguments);
          bool found = false;
          for (TypeBuilder typeBuilder in freshTypeArguments) {
            if (typeBuilder.declaration == typeDeclarationBuilder) {
              found = true;
              break;
            }
          }
          if (found) {
            libraryBuilder.addProblem(
                messageTypedefTypeVariableNotConstructor,
                usedAsClassCharOffset ?? TreeNode.noOffset,
                noLength,
                usedAsClassFileUri,
                context: [
                  messageTypedefTypeVariableNotConstructorCause.withLocation(
                      current.fileUri!, current.charOffset, noLength),
                ]);
            return this;
          }
          if (typeArguments == null) return typeDeclarationBuilder;
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
  TypeDeclarationBuilder? _unaliasDeclaration(
      List<TypeBuilder>? typeArguments) {
    TypeDeclarationBuilder? currentDeclarationBuilder = this;
    TypeAliasBuilder? previousAliasBuilder = null;
    List<TypeBuilder>? currentTypeArguments = typeArguments;
    while (currentDeclarationBuilder is TypeAliasBuilder) {
      TypeAliasBuilder currentAliasBuilder = currentDeclarationBuilder;
      TypeBuilder nextTypeBuilder = currentAliasBuilder.type;
      if (nextTypeBuilder is NamedTypeBuilder) {
        Map<TypeVariableBuilder, TypeBuilder> substitution = {};
        int index = 0;
        if (currentTypeArguments == null || currentTypeArguments.isEmpty) {
          if (currentAliasBuilder.typeVariables != null) {
            List<TypeBuilder> defaultTypeArguments =
                new List<TypeBuilder>.generate(
                    currentAliasBuilder.typeVariables!.length, (int i) {
              return currentAliasBuilder.typeVariables![i].defaultType!;
            }, growable: true);
            currentTypeArguments = defaultTypeArguments;
          } else {
            currentTypeArguments = <TypeBuilder>[];
          }
        }
        if ((currentAliasBuilder.typeVariables?.length ?? 0) !=
            currentTypeArguments.length) {
          if (previousAliasBuilder != null) {
            previousAliasBuilder.libraryBuilder.addProblem(
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
        TypeDeclarationBuilder? nextDeclarationBuilder =
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
            TypeDeclarationBuilder? declarationBuilder =
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
        NamedTypeBuilder namedBuilder = substitutedBuilder as NamedTypeBuilder;
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

  /// Compute type arguments passed to [ClassBuilder] or
  /// [ExtensionTypeDeclarationBuilder] from unaliasDeclaration.
  /// This method does not check for cycles and may only be called if an
  /// invocation of `this.unaliasDeclaration(typeArguments)` has returned a
  /// [ClassBuilder] or [ExtensionTypeDeclarationBuilder].
  ///
  /// The parameter [typeArguments] would typically be obtained from a
  /// [NamedTypeBuilder] whose `declaration` is `this`. It must be non-null.
  ///
  /// Returns `null` if an error occurred.
  ///
  /// The method substitutes through the chain of type aliases denoted by
  /// [this], such that the returned [TypeBuilder]s are appropriate type
  /// arguments for passing to the [ClassBuilder] or
  /// [ExtensionTypeDeclarationBuilder] which is the end of the unaliasing
  /// chain.
  @override
  List<TypeBuilder>? unaliasTypeArguments(List<TypeBuilder>? typeArguments) {
    TypeDeclarationBuilder? currentDeclarationBuilder = this;
    List<TypeBuilder>? currentTypeArguments = typeArguments;
    while (currentDeclarationBuilder is TypeAliasBuilder) {
      TypeAliasBuilder currentAliasBuilder = currentDeclarationBuilder;
      TypeBuilder nextTypeBuilder = currentAliasBuilder.type;
      assert(nextTypeBuilder is NamedTypeBuilder,
          "Expected NamedTypeBuilder, got '${nextTypeBuilder.runtimeType}'.");
      NamedTypeBuilder namedNextTypeBuilder =
          nextTypeBuilder as NamedTypeBuilder;
      Map<TypeVariableBuilder, TypeBuilder> substitution = {};
      int index = 0;
      if (currentTypeArguments == null || currentTypeArguments.isEmpty) {
        if (currentAliasBuilder.typeVariables != null) {
          List<TypeBuilder> defaultTypeArguments =
              new List<TypeBuilder>.generate(
                  currentAliasBuilder.typeVariables!.length, (int i) {
            return currentAliasBuilder.typeVariables![i].defaultType!;
          }, growable: false);
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
      TypeDeclarationBuilder? nextDeclarationBuilder =
          namedNextTypeBuilder.declaration;
      TypeBuilder substitutedBuilder = nextTypeBuilder.subst(substitution);
      if (nextDeclarationBuilder is TypeVariableBuilder) {
        // We have reached the end of the type alias chain which yields a
        // type argument, which may become a type alias, possibly with its
        // own similar chain.
        assert(substitutedBuilder is NamedTypeBuilder);
        NamedTypeBuilder namedSubstitutedBuilder =
            substitutedBuilder as NamedTypeBuilder;
        TypeDeclarationBuilder? declarationBuilder =
            namedSubstitutedBuilder.declaration;
        if (declarationBuilder is TypeAliasBuilder) {
          return declarationBuilder
              .unaliasTypeArguments(namedSubstitutedBuilder.arguments);
        }
        assert(declarationBuilder is ClassBuilder ||
            declarationBuilder is ExtensionTypeDeclarationBuilder);
        return namedSubstitutedBuilder.arguments ?? [];
      }
      // Not yet at the end of the chain, more named builders to come.
      NamedTypeBuilder namedBuilder = substitutedBuilder as NamedTypeBuilder;
      currentDeclarationBuilder = namedBuilder.declaration;
      currentTypeArguments = namedBuilder.arguments ?? [];
    }
    return currentTypeArguments;
  }

  Map<Name, Procedure>? get tearOffs;

  @override
  Procedure? findConstructorOrFactory(
      String text, int charOffset, Uri uri, LibraryBuilder accessingLibrary) {
    if (tearOffs != null) {
      Name name = new Name(text == 'new' ? '' : text, accessingLibrary.library);
      return tearOffs![name];
    }
    return null;
  }
}

/// Used to detect cycles in the declaration of a typedef
///
/// When a typedef is built, [pendingTypeAliasMarker] is used as a placeholder
/// value to indicated that the process has started.  If somewhere in the
/// process of building the typedef this value is encountered, it's replaced
/// with [cyclicTypeAliasMarker] as the result of the build process.
final InvalidType pendingTypeAliasMarker = new InvalidType();

/// Used to detect cycles in the declaration of a typedef
///
/// When a typedef is built, [pendingTypeAliasMarker] is used as a placeholder
/// value to indicated that the process has started.  If somewhere in the
/// process of building the typedef this value is encountered, it's replaced
/// with [cyclicTypeAliasMarker] as the result of the build process.
final InvalidType cyclicTypeAliasMarker = new InvalidType();
