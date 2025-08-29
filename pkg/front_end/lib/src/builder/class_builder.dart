// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'declaration_builders.dart';

const Uri? noUri = null;

abstract class ClassBuilder implements DeclarationBuilder {
  /// The type in the `extends` clause of a class declaration.
  ///
  /// Currently this also holds the synthesized super class for a mixin
  /// declaration.
  TypeBuilder? get supertypeBuilder;

  /// The type in the `implements` clause of a class or mixin declaration.
  List<TypeBuilder>? get interfaceBuilders;

  @override
  Uri get fileUri;

  bool get isAbstract;

  bool get isSealed;

  bool get isBase;

  bool get isInterface;

  bool get isFinal;

  bool get declaresConstConstructor;

  bool get isMixinClass;

  bool get isMixinDeclaration;

  bool get isMixinApplication;

  bool get isAnonymousMixinApplication;

  TypeBuilder? get mixedInTypeBuilder;

  bool get isFutureOr;

  /// The [Class] built by this builder.
  ///
  /// For an augmentation class the origin class is returned.
  Class get cls;

  /// Reference for the class built by this builder.
  Reference get reference;

  abstract bool isNullClass;

  @override
  InterfaceType get thisType;

  Supertype buildMixedInType(
    LibraryBuilder library,
    List<TypeBuilder>? arguments,
  );

  /// Looks up the member by [name] on the class built by this class builder.
  ///
  /// If [isSetter] is `false`, only fields, methods, and getters with that name
  /// will be found.  If [isSetter] is `true`, only non-final fields and setters
  /// will be found.
  ///
  /// If [isSuper] is `false`, the member is found among the interface members
  /// the class built by this class builder. If [isSuper] is `true`, the member
  /// is found among the class members of the superclass.
  ///
  /// If this class builder is an augmentation, interface members declared in
  /// this augmentation are searched before searching the interface members in
  /// the origin class.
  ///
  /// Unused in interface; left in on purpose.
  Member? lookupInstanceMember(
    ClassHierarchy hierarchy,
    Name name, {
    bool isSetter = false,
    bool isSuper = false,
  });
}

abstract class ClassBuilderImpl extends DeclarationBuilderImpl
    with DeclarationBuilderMixin
    implements ClassBuilder {
  @override
  bool isNullClass = false;

  InterfaceType? _nullableRawType;
  InterfaceType? _nonNullableRawType;
  InterfaceType? _thisType;

  @override
  bool get isMixinApplication => mixedInTypeBuilder != null;

  @override
  bool get isAnonymousMixinApplication {
    return isMixinApplication &&
        // Coverage-ignore(suite): Not run.
        !isNamedMixinApplication;
  }

  @override
  InterfaceType get thisType {
    return _thisType ??= new InterfaceType(
      cls,
      Nullability.nonNullable,
      getAsTypeArguments(cls.typeParameters, libraryBuilder.library),
    );
  }

  InterfaceType get nullableRawType {
    return _nullableRawType ??= new InterfaceType(
      cls,
      Nullability.nullable,
      new List<DartType>.filled(typeParametersCount, const DynamicType()),
    );
  }

  InterfaceType get nonNullableRawType {
    return _nonNullableRawType ??= new InterfaceType(
      cls,
      Nullability.nonNullable,
      new List<DartType>.filled(typeParametersCount, const DynamicType()),
    );
  }

  InterfaceType rawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.nullable:
        return nullableRawType;
      case Nullability.nonNullable:
        return nonNullableRawType;
      // Coverage-ignore(suite): Not run.
      case Nullability.undetermined:
        return unhandled("$nullability", "rawType", TreeNode.noOffset, noUri);
    }
  }

  InterfaceType? aliasedTypeWithBuiltArgumentsCacheNonNullable;
  InterfaceType? aliasedTypeWithBuiltArgumentsCacheNullable;

  @override
  bool get isFutureOr {
    if (name == "FutureOr") {
      if (parent.importUri.isScheme("dart") &&
          parent.importUri.path == "async") {
        return true;
      }
    }
    return false;
  }

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
    assert(cls.typeParameters.length == arguments.length);
    if (isNullClass) {
      return const NullType();
    }
    if (isFutureOr) {
      assert(arguments.length == 1);
      return new FutureOrType(arguments.single, nullability);
    }
    if (arguments.isEmpty) {
      return rawType(nullability);
    }
    if (aliasedTypeWithBuiltArgumentsCacheNonNullable != null &&
        // Coverage-ignore(suite): Not run.
        nullability == Nullability.nonNullable) {
      // Coverage-ignore-block(suite): Not run.
      assert(
        aliasedTypeWithBuiltArgumentsCacheNonNullable!.classReference ==
            cls.reference,
      );
      assert(arguments.isEmpty);
      return aliasedTypeWithBuiltArgumentsCacheNonNullable!;
    } else if (aliasedTypeWithBuiltArgumentsCacheNullable != null &&
        // Coverage-ignore(suite): Not run.
        nullability == Nullability.nullable) {
      // Coverage-ignore-block(suite): Not run.
      assert(
        aliasedTypeWithBuiltArgumentsCacheNullable!.classReference ==
            cls.reference,
      );
      assert(arguments.isEmpty);
      return aliasedTypeWithBuiltArgumentsCacheNullable!;
    }
    InterfaceType type = new InterfaceType(cls, nullability, arguments);
    if (arguments.isEmpty) {
      // Coverage-ignore-block(suite): Not run.
      assert(typeParametersCount == 0);
      if (nullability == Nullability.nonNullable) {
        aliasedTypeWithBuiltArgumentsCacheNonNullable = type;
      } else if (nullability == Nullability.nullable) {
        aliasedTypeWithBuiltArgumentsCacheNullable = type;
      }
    }

    if (typeParametersCount != 0 && library is SourceLibraryBuilder) {
      library.registerBoundsCheck(
        type,
        fileUri,
        charOffset,
        typeUse,
        inferred: !hasExplicitTypeArguments,
      );
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
    ClassHierarchyBase? hierarchy, {
    required bool hasExplicitTypeArguments,
  }) {
    if (name == "Record" &&
        libraryBuilder.importUri.scheme == "dart" &&
        libraryBuilder.importUri.path == "core" &&
        library is SourceLibraryBuilder &&
        !isRecordAccessAllowed(library)) {
      // Coverage-ignore-block(suite): Not run.
      library.reportFeatureNotEnabled(
        library.libraryFeatures.records,
        fileUri,
        charOffset,
        name.length,
      );
      return const InvalidType();
    }
    return buildAliasedTypeWithBuiltArguments(
      library,
      nullabilityBuilder.build(),
      buildAliasedTypeArguments(library, arguments, hierarchy),
      typeUse,
      fileUri,
      charOffset,
      hasExplicitTypeArguments: hasExplicitTypeArguments,
    );
  }

  @override
  Supertype buildMixedInType(
    LibraryBuilder library,
    List<TypeBuilder>? arguments,
  ) {
    if (arguments != null) {
      List<DartType> typeArguments = buildAliasedTypeArguments(
        library,
        arguments,
        /* hierarchy = */ null,
      );
      typeArguments = unaliasTypes(typeArguments)!;
      return new Supertype(cls, typeArguments);
    } else {
      return new Supertype(
        cls,
        new List<DartType>.filled(
          cls.typeParameters.length,
          const UnknownType(),
          growable: true,
        ),
      );
    }
  }

  @override
  String get fullNameForErrors {
    return isMixinApplication && !isNamedMixinApplication
        ? "${supertypeBuilder!.fullNameForErrors} with "
              "${mixedInTypeBuilder!.fullNameForErrors}"
        : name;
  }

  @override
  Member? lookupInstanceMember(
    ClassHierarchy hierarchy,
    Name name, {
    bool isSetter = false,
    bool isSuper = false,
  }) {
    Class? instanceClass = cls;
    if (isSuper) {
      instanceClass = instanceClass.superclass;
      if (instanceClass == null) return null;
    }
    Member? target = isSuper
        ? hierarchy.getDispatchTarget(instanceClass, name, setter: isSetter)
        :
          // Coverage-ignore(suite): Not run.
          hierarchy.getInterfaceMember(instanceClass, name, setter: isSetter);
    if (isSuper && target == null) {
      if (cls.isMixinDeclaration) {
        target = hierarchy.getInterfaceMember(
          instanceClass,
          name,
          setter: isSetter,
        );
      }
    }
    return target;
  }

  @override
  Nullability computeNullabilityWithArguments(
    List<TypeBuilder>? typeArguments, {
    required Map<TypeParameterBuilder, TraversalState>
    typeParametersTraversalState,
  }) {
    if (isNullClass) {
      return Nullability.nullable;
    } else if (isFutureOr) {
      if (typeArguments != null && typeArguments.length == 1) {
        return typeArguments.single.computeNullability(
          typeParametersTraversalState: typeParametersTraversalState,
        );
      } else {
        // This is `FutureOr<dynamic>`.
        return Nullability.nullable;
      }
    }
    return Nullability.nonNullable;
  }
}

class ConstructorRedirection {
  String target;
  bool cycleReported;

  ConstructorRedirection(this.target) : cycleReported = false;
}
