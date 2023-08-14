// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.class_builder;

import 'package:kernel/ast.dart'
    show
        Class,
        DartType,
        DynamicType,
        FutureOrType,
        InterfaceType,
        InvalidType,
        Member,
        Name,
        NullType,
        Nullability,
        Supertype,
        TreeNode,
        getAsTypeArguments;
import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchy, ClassHierarchyBase;
import 'package:kernel/src/unaliasing.dart';

import '../fasta_codes.dart';
import '../modifier.dart';
import '../problems.dart' show internalProblem, unhandled;
import '../scope.dart';
import '../source/source_library_builder.dart';
import '../type_inference/type_schema.dart' show UnknownType;
import '../util/helpers.dart';
import 'builder.dart';
import 'declaration_builder.dart';
import 'library_builder.dart';
import 'member_builder.dart';
import 'metadata_builder.dart';
import 'name_iterator.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';
import 'type_variable_builder.dart';

const Uri? noUri = null;

abstract class ClassMemberAccess {
  /// [Iterator] for all members declared in this class or any of its
  /// augmentations.
  ///
  /// Duplicates and augmenting constructor are _not_ included.
  Iterator<T> fullConstructorIterator<T extends MemberBuilder>();

  /// [NameIterator] for all constructors declared in this class or any of its
  /// augmentations.
  ///
  /// Duplicates and augmenting constructors are _not_ included.
  NameIterator<T> fullConstructorNameIterator<T extends MemberBuilder>();

  /// [Iterator] for all members declared in this class or any of its
  /// augmentations.
  ///
  /// Duplicates and augmenting members are _not_ included.
  Iterator<T> fullMemberIterator<T extends Builder>();

  /// [NameIterator] for all members declared in this class or any of its
  /// augmentations.
  ///
  /// Duplicates and augmenting members are _not_ included.
  NameIterator<T> fullMemberNameIterator<T extends Builder>();
}

abstract class ClassBuilder implements DeclarationBuilder, ClassMemberAccess {
  /// The type variables declared on a class, extension or mixin declaration.
  List<TypeVariableBuilder>? get typeVariables;

  /// The type in the `extends` clause of a class declaration.
  ///
  /// Currently this also holds the synthesized super class for a mixin
  /// declaration.
  abstract TypeBuilder? supertypeBuilder;

  /// The type in the `implements` clause of a class or mixin declaration.
  abstract List<TypeBuilder>? interfaceBuilders;

  /// The types in the `on` clause of an extension or mixin declaration.
  List<TypeBuilder>? get onTypes;

  @override
  Uri get fileUri;

  bool get isAbstract;

  bool get isMacro;

  bool get isSealed;

  bool get isBase;

  bool get isInterface;

  @override
  bool get isFinal;

  bool get isAugmentation;

  bool get declaresConstConstructor;

  bool get isMixin;

  bool get isMixinClass;

  bool get isMixinDeclaration;

  bool get isMixinApplication;

  bool get isAnonymousMixinApplication;

  abstract TypeBuilder? mixedInTypeBuilder;

  /// The [Class] built by this builder.
  ///
  /// For a patch class the origin class is returned.
  Class get cls;

  @override
  ClassBuilder get origin;

  abstract bool isNullClass;

  @override
  InterfaceType get thisType;

  InterfaceType get legacyRawType;

  InterfaceType get nullableRawType;

  InterfaceType get nonNullableRawType;

  InterfaceType rawType(Nullability nullability);

  Supertype buildMixedInType(
      LibraryBuilder library, List<TypeBuilder>? arguments);

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
  /// If this class builder is a patch, interface members declared in this
  /// patch are searched before searching the interface members in the origin
  /// class.
  Member? lookupInstanceMember(ClassHierarchy hierarchy, Name name,
      {bool isSetter = false, bool isSuper = false});
}

abstract class ClassBuilderImpl extends DeclarationBuilderImpl
    implements ClassBuilder {
  @override
  List<TypeVariableBuilder>? typeVariables;

  @override
  TypeBuilder? supertypeBuilder;

  @override
  List<TypeBuilder>? interfaceBuilders;

  @override
  List<TypeBuilder>? onTypes;

  @override
  bool isNullClass = false;

  InterfaceType? _legacyRawType;
  InterfaceType? _nullableRawType;
  InterfaceType? _nonNullableRawType;
  InterfaceType? _thisType;

  ClassBuilderImpl(
      List<MetadataBuilder>? metadata,
      int modifiers,
      String name,
      this.typeVariables,
      this.supertypeBuilder,
      this.interfaceBuilders,
      this.onTypes,
      Scope scope,
      ConstructorScope constructorScope,
      LibraryBuilder parent,
      int charOffset)
      : super(metadata, modifiers, name, parent, charOffset, scope,
            constructorScope);

  @override
  String get debugName => "ClassBuilder";

  @override
  bool get isAbstract => (modifiers & abstractMask) != 0;

  @override
  bool get isMixin => (modifiers & mixinDeclarationMask) != 0;

  @override
  bool get isMixinApplication => mixedInTypeBuilder != null;

  @override
  bool get isNamedMixinApplication {
    return isMixinApplication && (modifiers & namedMixinApplicationMask) != 0;
  }

  @override
  bool get isAnonymousMixinApplication {
    return isMixinApplication && !isNamedMixinApplication;
  }

  @override
  bool get declaresConstConstructor =>
      (modifiers & declaresConstConstructorMask) != 0;

  @override
  Builder? findStaticBuilder(
      String name, int charOffset, Uri fileUri, LibraryBuilder accessingLibrary,
      {bool isSetter = false}) {
    if (accessingLibrary.nameOriginBuilder.origin !=
            libraryBuilder.nameOriginBuilder.origin &&
        name.startsWith("_")) {
      return null;
    }
    Builder? declaration = isSetter
        ? scope.lookupSetter(name, charOffset, fileUri, isInstanceScope: false)
        : scope.lookup(name, charOffset, fileUri, isInstanceScope: false);
    if (declaration == null && isPatch) {
      return origin.findStaticBuilder(
          name, charOffset, fileUri, accessingLibrary,
          isSetter: isSetter);
    }
    return declaration;
  }

  @override
  Builder? lookupLocalMember(String name,
      {bool setter = false, bool required = false}) {
    Builder? builder = scope.lookupLocalMember(name, setter: setter);
    if (builder == null && isPatch) {
      builder = origin.scope.lookupLocalMember(name, setter: setter);
    }
    if (required && builder == null) {
      internalProblem(
          templateInternalProblemNotFoundIn.withArguments(
              name, fullNameForErrors),
          -1,
          null);
    }
    return builder;
  }

  /// Find the first member of this class with [name]. This method isn't
  /// suitable for scope lookups as it will throw an error if the name isn't
  /// declared. The [scope] should be used for that. This method is used to
  /// find a member that is known to exist and it will pick the first
  /// declaration if the name is ambiguous.
  ///
  /// For example, this method is convenient for use when building synthetic
  /// members, such as those of an enum.
  MemberBuilder? firstMemberNamed(String name) {
    MemberBuilder declaration =
        lookupLocalMember(name, required: true) as MemberBuilder;
    while (declaration.next != null) {
      declaration = declaration.next as MemberBuilder;
    }
    return declaration;
  }

  @override
  InterfaceType get thisType {
    return _thisType ??= new InterfaceType(cls, libraryBuilder.nonNullable,
        getAsTypeArguments(cls.typeParameters, libraryBuilder.library));
  }

  @override
  InterfaceType get legacyRawType {
    return _legacyRawType ??= new InterfaceType(cls, Nullability.legacy,
        new List<DartType>.filled(typeVariablesCount, const DynamicType()));
  }

  @override
  InterfaceType get nullableRawType {
    return _nullableRawType ??= new InterfaceType(cls, Nullability.nullable,
        new List<DartType>.filled(typeVariablesCount, const DynamicType()));
  }

  @override
  InterfaceType get nonNullableRawType {
    return _nonNullableRawType ??= new InterfaceType(
        cls,
        Nullability.nonNullable,
        new List<DartType>.filled(typeVariablesCount, const DynamicType()));
  }

  @override
  InterfaceType rawType(Nullability nullability) {
    switch (nullability) {
      case Nullability.legacy:
        return legacyRawType;
      case Nullability.nullable:
        return nullableRawType;
      case Nullability.nonNullable:
        return nonNullableRawType;
      case Nullability.undetermined:
      default:
        return unhandled("$nullability", "rawType", TreeNode.noOffset, noUri);
    }
  }

  InterfaceType? aliasedTypeWithBuiltArgumentsCacheNonNullable;
  InterfaceType? aliasedTypeWithBuiltArgumentsCacheNullable;

  @override
  DartType buildAliasedTypeWithBuiltArguments(
      LibraryBuilder library,
      Nullability nullability,
      List<DartType>? arguments,
      TypeUse typeUse,
      Uri fileUri,
      int charOffset,
      {required bool hasExplicitTypeArguments}) {
    assert(arguments == null || cls.typeParameters.length == arguments.length);
    if (isNullClass) {
      return const NullType();
    }
    if (name == "FutureOr") {
      LibraryBuilder parentLibrary = parent as LibraryBuilder;
      if (parentLibrary.importUri.isScheme("dart") &&
          parentLibrary.importUri.path == "async") {
        assert(arguments != null && arguments.length == 1);
        return new FutureOrType(arguments!.single, nullability);
      }
    }
    DartType type;
    if (arguments == null) {
      type = rawType(nullability);
    } else {
      if (aliasedTypeWithBuiltArgumentsCacheNonNullable != null &&
          nullability == Nullability.nonNullable) {
        assert(aliasedTypeWithBuiltArgumentsCacheNonNullable!.classReference ==
            cls.reference);
        assert(arguments.isEmpty);
        return aliasedTypeWithBuiltArgumentsCacheNonNullable!;
      } else if (aliasedTypeWithBuiltArgumentsCacheNullable != null &&
          nullability == Nullability.nullable) {
        assert(aliasedTypeWithBuiltArgumentsCacheNullable!.classReference ==
            cls.reference);
        assert(arguments.isEmpty);
        return aliasedTypeWithBuiltArgumentsCacheNullable!;
      }
      InterfaceType cacheable =
          type = new InterfaceType(cls, nullability, arguments);
      if (arguments.isEmpty) {
        assert(typeVariablesCount == 0);
        if (nullability == Nullability.nonNullable) {
          aliasedTypeWithBuiltArgumentsCacheNonNullable = cacheable;
        } else if (nullability == Nullability.nullable) {
          aliasedTypeWithBuiltArgumentsCacheNullable = cacheable;
        }
      }
    }

    if (typeVariablesCount != 0 && library is SourceLibraryBuilder) {
      library.registerBoundsCheck(type, fileUri, charOffset, typeUse,
          inferred: !hasExplicitTypeArguments);
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
    if (name == "Record" &&
        libraryBuilder.importUri.scheme == "dart" &&
        libraryBuilder.importUri.path == "core" &&
        library is SourceLibraryBuilder &&
        !isRecordAccessAllowed(library)) {
      library.reportFeatureNotEnabled(
          library.libraryFeatures.records, fileUri, charOffset, name.length);
      return const InvalidType();
    }
    return buildAliasedTypeWithBuiltArguments(
        library,
        nullabilityBuilder.build(library),
        buildAliasedTypeArguments(library, arguments, hierarchy),
        typeUse,
        fileUri,
        charOffset,
        hasExplicitTypeArguments: hasExplicitTypeArguments);
  }

  @override
  Supertype buildMixedInType(
      LibraryBuilder library, List<TypeBuilder>? arguments) {
    Class cls = isPatch ? origin.cls : this.cls;
    if (arguments != null) {
      List<DartType> typeArguments =
          buildAliasedTypeArguments(library, arguments, /* hierarchy = */ null);
      typeArguments = unaliasTypes(typeArguments,
          legacyEraseAliases: !library.isNonNullableByDefault)!;
      return new Supertype(cls, typeArguments);
    } else {
      return new Supertype(
          cls,
          new List<DartType>.filled(
              cls.typeParameters.length, const UnknownType(),
              growable: true));
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
  Member? lookupInstanceMember(ClassHierarchy hierarchy, Name name,
      {bool isSetter = false, bool isSuper = false}) {
    Class? instanceClass = cls;
    if (isPatch) {
      assert(identical(instanceClass, origin.cls),
          "Found ${origin.cls} expected $instanceClass");
      if (isSuper) {
        // The super class is only correctly found through the origin class.
        instanceClass = origin.cls;
      } else {
        Member? member =
            hierarchy.getInterfaceMember(instanceClass, name, setter: isSetter);
        if (member?.parent == instanceClass) {
          // Only if the member is found in the patch can we use it.
          return member;
        } else {
          // Otherwise, we need to keep searching in the origin class.
          instanceClass = origin.cls;
        }
      }
    }

    if (isSuper) {
      instanceClass = instanceClass.superclass;
      if (instanceClass == null) return null;
    }
    Member? target = isSuper
        ? hierarchy.getDispatchTarget(instanceClass, name, setter: isSetter)
        : hierarchy.getInterfaceMember(instanceClass, name, setter: isSetter);
    if (isSuper && target == null) {
      if (cls.isMixinDeclaration) {
        target =
            hierarchy.getInterfaceMember(instanceClass, name, setter: isSetter);
      }
    }
    return target;
  }
}

class ConstructorRedirection {
  String target;
  bool cycleReported;

  ConstructorRedirection(this.target) : cycleReported = false;
}
