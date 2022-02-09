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
        Member,
        Name,
        NullType,
        Nullability,
        Supertype,
        getAsTypeArguments;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/src/legacy_erasure.dart';
import 'package:kernel/text/text_serialization_verifier.dart';

import '../fasta_codes.dart';
import '../modifier.dart';
import '../problems.dart' show internalProblem, unhandled;
import '../scope.dart';
import '../type_inference/type_schema.dart' show UnknownType;
import 'builder.dart';
import 'declaration_builder.dart';
import 'library_builder.dart';
import 'member_builder.dart';
import 'metadata_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';
import 'type_variable_builder.dart';

abstract class ClassBuilder implements DeclarationBuilder {
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

  ConstructorScope get constructors;

  ConstructorScopeBuilder get constructorScopeBuilder;

  @override
  Uri get fileUri;

  bool get isAbstract;

  bool get isMacro;

  bool get declaresConstConstructor;

  bool get isMixin;

  bool get isMixinApplication;

  bool get isAnonymousMixinApplication;

  abstract TypeBuilder? mixedInTypeBuilder;

  MemberBuilder? findConstructorOrFactory(
      String name, int charOffset, Uri uri, LibraryBuilder accessingLibrary);

  void forEach(void f(String name, Builder builder));

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

  List<DartType> buildTypeArguments(
      LibraryBuilder library, List<TypeBuilder>? arguments);

  Supertype buildSupertype(
      LibraryBuilder library, List<TypeBuilder>? arguments);

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
      {bool isSetter: false, bool isSuper: false});

  /// Calls [f] for each constructor declared in this class.
  ///
  /// If [includeInjectedConstructors] is `true`, constructors only declared in
  /// the patch class, if any, are included.
  void forEachConstructor(void Function(String, MemberBuilder) f,
      {bool includeInjectedConstructors: false});
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
  final ConstructorScope constructors;

  @override
  final ConstructorScopeBuilder constructorScopeBuilder;

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
      this.constructors,
      LibraryBuilder parent,
      int charOffset)
      : constructorScopeBuilder = new ConstructorScopeBuilder(constructors),
        super(metadata, modifiers, name, parent, charOffset, scope);

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
      {bool isSetter: false}) {
    if (accessingLibrary.nameOriginBuilder.origin !=
            library.nameOriginBuilder.origin &&
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
  MemberBuilder? findConstructorOrFactory(
      String name, int charOffset, Uri uri, LibraryBuilder accessingLibrary) {
    if (accessingLibrary.nameOriginBuilder.origin !=
            library.nameOriginBuilder.origin &&
        name.startsWith("_")) {
      return null;
    }
    MemberBuilder? declaration =
        constructors.lookup(name == 'new' ? '' : name, charOffset, uri);
    if (declaration == null && isPatch) {
      return origin.findConstructorOrFactory(
          name, charOffset, uri, accessingLibrary);
    }
    return declaration;
  }

  @override
  void forEach(void f(String name, Builder builder)) {
    scope.forEach(f);
  }

  @override
  Builder? lookupLocalMember(String name,
      {bool setter: false, bool required: false}) {
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
    return _thisType ??= new InterfaceType(cls, library.nonNullable,
        getAsTypeArguments(cls.typeParameters, library.library));
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
        return unhandled("$nullability", "rawType", noOffset, noUri);
    }
  }

  @override
  DartType buildTypeWithBuiltArguments(LibraryBuilder library,
      Nullability nullability, List<DartType>? arguments) {
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
    return arguments == null
        ? rawType(nullability)
        : new InterfaceType(cls, nullability, arguments);
  }

  @override
  DartType buildType(LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder, List<TypeBuilder>? arguments) {
    return buildTypeWithBuiltArguments(
        library,
        nullabilityBuilder.build(library),
        buildTypeArguments(library, arguments));
  }

  @override
  Supertype buildSupertype(
      LibraryBuilder library, List<TypeBuilder>? arguments) {
    Class cls = isPatch ? origin.cls : this.cls;
    List<DartType> typeArguments = buildTypeArguments(library, arguments);
    if (!library.isNonNullableByDefault) {
      for (int i = 0; i < typeArguments.length; ++i) {
        typeArguments[i] = legacyErasure(typeArguments[i]);
      }
    }
    return new Supertype(cls, typeArguments);
  }

  @override
  Supertype buildMixedInType(
      LibraryBuilder library, List<TypeBuilder>? arguments) {
    Class cls = isPatch ? origin.cls : this.cls;
    if (arguments != null) {
      return new Supertype(cls, buildTypeArguments(library, arguments));
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
      {bool isSetter: false, bool isSuper: false}) {
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
      if (cls.isMixinDeclaration ||
          (library.loader.target.backendTarget.enableSuperMixins &&
              this.isAbstract)) {
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
