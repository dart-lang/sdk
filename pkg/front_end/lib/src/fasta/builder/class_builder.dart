// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.class_builder;

import 'package:kernel/ast.dart'
    show
        Class,
        Constructor,
        DartType,
        DynamicType,
        FunctionNode,
        FunctionType,
        FutureOrType,
        InterfaceType,
        Member,
        Name,
        NullType,
        Nullability,
        Supertype,
        TypeParameter,
        getAsTypeArguments;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/text/text_serialization_verifier.dart';

import 'package:kernel/type_algebra.dart' show Substitution, substitute;

import 'package:kernel/type_environment.dart'
    show SubtypeCheckMode, TypeEnvironment;

import 'package:kernel/src/types.dart' show Types;

import '../dill/dill_member_builder.dart';

import '../fasta_codes.dart';

import '../kernel/redirecting_factory_body.dart' show getRedirectingFactoryBody;

import '../loader.dart';

import '../modifier.dart';

import '../names.dart' show noSuchMethodName;

import '../problems.dart' show internalProblem, unhandled;

import '../scope.dart';

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import '../source/source_loader.dart';

import '../type_inference/type_schema.dart' show UnknownType;

import 'builder.dart';
import 'constructor_builder.dart';
import 'constructor_reference_builder.dart';
import 'declaration_builder.dart';
import 'field_builder.dart';
import 'function_builder.dart';
import 'library_builder.dart';
import 'member_builder.dart';
import 'metadata_builder.dart';
import 'named_type_builder.dart';
import 'never_type_declaration_builder.dart';
import 'nullability_builder.dart';
import 'procedure_builder.dart';
import 'type_alias_builder.dart';
import 'type_builder.dart';
import 'type_declaration_builder.dart';
import 'type_variable_builder.dart';
import 'void_type_declaration_builder.dart';

abstract class ClassBuilder implements DeclarationBuilder {
  /// The type variables declared on a class, extension or mixin declaration.
  List<TypeVariableBuilder> typeVariables;

  /// The type in the `extends` clause of a class declaration.
  ///
  /// Currently this also holds the synthesized super class for a mixin
  /// declaration.
  TypeBuilder supertypeBuilder;

  /// The type in the `implements` clause of a class or mixin declaration.
  List<TypeBuilder> interfaceBuilders;

  /// The types in the `on` clause of an extension or mixin declaration.
  List<TypeBuilder> onTypes;

  ConstructorScope get constructors;

  ConstructorScopeBuilder get constructorScopeBuilder;

  Map<String, ConstructorRedirection> redirectingConstructors;

  ClassBuilder actualOrigin;

  ClassBuilder get patchForTesting;

  bool get isAbstract;

  bool get declaresConstConstructor;

  bool get isMixin;

  bool get isMixinApplication;

  bool get isAnonymousMixinApplication;

  TypeBuilder get mixedInTypeBuilder;

  void set mixedInTypeBuilder(TypeBuilder mixin);

  List<ConstructorReferenceBuilder> get constructorReferences;

  void buildOutlineExpressions(LibraryBuilder library, CoreTypes coreTypes);

  /// Registers a constructor redirection for this class and returns true if
  /// this redirection gives rise to a cycle that has not been reported before.
  bool checkConstructorCyclic(String source, String target);

  MemberBuilder findConstructorOrFactory(
      String name, int charOffset, Uri uri, LibraryBuilder accessingLibrary);

  void forEach(void f(String name, Builder builder));

  void forEachDeclaredField(
      void Function(String name, FieldBuilder fieldBuilder) f);

  void forEachDeclaredConstructor(
      void Function(String name, ConstructorBuilder constructorBuilder)
          callback);

  /// Find the first member of this class with [name]. This method isn't
  /// suitable for scope lookups as it will throw an error if the name isn't
  /// declared. The [scope] should be used for that. This method is used to
  /// find a member that is known to exist and it will pick the first
  /// declaration if the name is ambiguous.
  ///
  /// For example, this method is convenient for use when building synthetic
  /// members, such as those of an enum.
  MemberBuilder firstMemberNamed(String name);

  /// The [Class] built by this builder.
  ///
  /// For a patch class the origin class is returned.
  Class get cls;

  @override
  ClassBuilder get origin;

  Class get actualCls;

  bool isNullClass;

  InterfaceType get legacyRawType;

  InterfaceType get nullableRawType;

  InterfaceType get nonNullableRawType;

  InterfaceType rawType(Nullability nullability);

  List<DartType> buildTypeArguments(
      LibraryBuilder library, List<TypeBuilder> arguments,
      [bool notInstanceContext]);

  Supertype buildSupertype(LibraryBuilder library, List<TypeBuilder> arguments);

  Supertype buildMixedInType(
      LibraryBuilder library, List<TypeBuilder> arguments);

  void checkSupertypes(CoreTypes coreTypes);

  void handleSeenCovariant(
      Types types,
      Member declaredMember,
      Member interfaceMember,
      bool isSetter,
      callback(Member declaredMember, Member interfaceMember, bool isSetter));

  bool hasUserDefinedNoSuchMethod(
      Class klass, ClassHierarchy hierarchy, Class objectClass);

  void checkMixinApplication(ClassHierarchy hierarchy, CoreTypes coreTypes);

  // Computes the function type of a given redirection target. Returns [null] if
  // the type of the target could not be computed.
  FunctionType computeRedirecteeType(
      RedirectingFactoryBuilder factory, TypeEnvironment typeEnvironment);

  String computeRedirecteeName(ConstructorReferenceBuilder redirectionTarget);

  void checkRedirectingFactory(
      RedirectingFactoryBuilder factory, TypeEnvironment typeEnvironment);

  void checkRedirectingFactories(TypeEnvironment typeEnvironment);

  /// Returns a map which maps the type variables of [superclass] to their
  /// respective values as defined by the superclass clause of this class (and
  /// its superclasses).
  ///
  /// It's assumed that [superclass] is a superclass of this class.
  ///
  /// For example, given:
  ///
  ///     class Box<T> {}
  ///     class BeatBox extends Box<Beat> {}
  ///     class Beat {}
  ///
  /// We have:
  ///
  ///     [[BeatBox]].getSubstitutionMap([[Box]]) -> {[[Box::T]]: Beat]]}.
  ///
  /// It's an error if [superclass] isn't a superclass.
  Map<TypeParameter, DartType> getSubstitutionMap(Class superclass);

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
  Member lookupInstanceMember(ClassHierarchy hierarchy, Name name,
      {bool isSetter: false, bool isSuper: false});

  /// Looks up the constructor by [name] on the the class built by this class
  /// builder.
  ///
  /// If [isSuper] is `true`, constructors in the superclass are searched.
  Constructor lookupConstructor(Name name, {bool isSuper: false});

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
  List<TypeVariableBuilder> typeVariables;

  @override
  TypeBuilder supertypeBuilder;

  @override
  List<TypeBuilder> interfaceBuilders;

  @override
  List<TypeBuilder> onTypes;

  @override
  final ConstructorScope constructors;

  @override
  final ConstructorScopeBuilder constructorScopeBuilder;

  @override
  Map<String, ConstructorRedirection> redirectingConstructors;

  @override
  ClassBuilder actualOrigin;

  @override
  ClassBuilder get patchForTesting => _patchBuilder;

  @override
  bool isNullClass = false;

  InterfaceType _legacyRawType;
  InterfaceType _nullableRawType;
  InterfaceType _nonNullableRawType;
  InterfaceType _thisType;
  ClassBuilder _patchBuilder;

  ClassBuilderImpl(
      List<MetadataBuilder> metadata,
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

  bool get declaresConstConstructor =>
      (modifiers & declaresConstConstructorMask) != 0;

  @override
  List<ConstructorReferenceBuilder> get constructorReferences => null;

  void forEachConstructor(void Function(String, MemberBuilder) f,
      {bool includeInjectedConstructors: false}) {
    if (isPatch) {
      actualOrigin.forEachConstructor(f,
          includeInjectedConstructors: includeInjectedConstructors);
    } else {
      constructors.forEach(f);
      if (includeInjectedConstructors && _patchBuilder != null) {
        _patchBuilder.constructors
            .forEach((String name, MemberBuilder builder) {
          if (!builder.isPatch) {
            f(name, builder);
          }
        });
      }
    }
  }

  @override
  void buildOutlineExpressions(LibraryBuilder library, CoreTypes coreTypes) {
    void build(String ignore, Builder declaration) {
      MemberBuilder member = declaration;
      member.buildOutlineExpressions(library, coreTypes);
    }

    MetadataBuilder.buildAnnotations(
        isPatch ? origin.cls : cls, metadata, library, this, null);
    constructors.forEach(build);
    scope.forEach(build);
  }

  /// Registers a constructor redirection for this class and returns true if
  /// this redirection gives rise to a cycle that has not been reported before.
  bool checkConstructorCyclic(String source, String target) {
    ConstructorRedirection redirect = new ConstructorRedirection(target);
    redirectingConstructors ??= <String, ConstructorRedirection>{};
    redirectingConstructors[source] = redirect;
    while (redirect != null) {
      if (redirect.cycleReported) return false;
      if (redirect.target == source) {
        redirect.cycleReported = true;
        return true;
      }
      redirect = redirectingConstructors[redirect.target];
    }
    return false;
  }

  @override
  Builder findStaticBuilder(
      String name, int charOffset, Uri fileUri, LibraryBuilder accessingLibrary,
      {bool isSetter: false}) {
    if (accessingLibrary.origin != library.origin && name.startsWith("_")) {
      return null;
    }
    Builder declaration = isSetter
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
  MemberBuilder findConstructorOrFactory(
      String name, int charOffset, Uri uri, LibraryBuilder accessingLibrary) {
    if (accessingLibrary.origin != library.origin && name.startsWith("_")) {
      return null;
    }
    MemberBuilder declaration = constructors.lookup(name, charOffset, uri);
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

  void forEachDeclaredField(
      void Function(String name, FieldBuilder fieldBuilder) callback) {
    void callbackFilteringFieldBuilders(String name, Builder builder) {
      if (builder is FieldBuilder) {
        callback(name, builder);
      }
    }

    // Currently, fields can't be patched, but can be injected.  When the fields
    // will be made available for patching, the following code should iterate
    // first over the fields from the patch and then -- over the fields in the
    // original declaration, filtering out the patched fields.  For now, the
    // assert checks that the names of the fields from the original declaration
    // and from the patch don't intersect.
    assert(
        _patchBuilder == null ||
            _patchBuilder.scope.localMembers
                .where((b) => b is FieldBuilder)
                .map((b) => (b as FieldBuilder).name)
                .toSet()
                .intersection(scope.localMembers
                    .where((b) => b is FieldBuilder)
                    .map((b) => (b as FieldBuilder).name)
                    .toSet())
                .isEmpty,
        "Detected an attempt to patch a field.");
    _patchBuilder?.scope?.forEach(callbackFilteringFieldBuilders);
    scope.forEach(callbackFilteringFieldBuilders);
  }

  @override
  void forEachDeclaredConstructor(
      void Function(String name, ConstructorBuilder constructorBuilder)
          callback) {
    Set<String> visitedConstructorNames = {};
    void callbackFilteringFieldBuilders(String name, Builder builder) {
      if (builder is ConstructorBuilder &&
          visitedConstructorNames.add(builder.name)) {
        callback(name, builder);
      }
    }

    // Constructors can be patched, so iterate first over constructors in the
    // patch, and then over constructors in the original declaration skipping
    // those with the names that are in the patch.
    _patchBuilder?.constructors?.forEach(callbackFilteringFieldBuilders);
    constructors.forEach(callbackFilteringFieldBuilders);
  }

  @override
  Builder lookupLocalMember(String name,
      {bool setter: false, bool required: false}) {
    Builder builder = scope.lookupLocalMember(name, setter: setter);
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

  @override
  MemberBuilder firstMemberNamed(String name) {
    Builder declaration = lookupLocalMember(name, required: true);
    while (declaration.next != null) {
      declaration = declaration.next;
    }
    return declaration;
  }

  @override
  ClassBuilder get origin => actualOrigin ?? this;

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
  DartType buildTypesWithBuiltArguments(LibraryBuilder library,
      Nullability nullability, List<DartType> arguments) {
    assert(arguments == null || cls.typeParameters.length == arguments.length);
    if (isNullClass) {
      return const NullType();
    }
    if (name == "FutureOr") {
      LibraryBuilder parentLibrary = parent;
      if (parentLibrary.importUri.scheme == "dart" &&
          parentLibrary.importUri.path == "async") {
        assert(arguments != null && arguments.length == 1);
        return new FutureOrType(arguments.single, nullability);
      }
    }
    return arguments == null
        ? rawType(nullability)
        : new InterfaceType(cls, nullability, arguments);
  }

  @override
  int get typeVariablesCount => typeVariables?.length ?? 0;

  @override
  List<DartType> buildTypeArguments(
      LibraryBuilder library, List<TypeBuilder> arguments,
      [bool notInstanceContext]) {
    if (arguments == null && typeVariables == null) {
      return <DartType>[];
    }

    if (arguments == null && typeVariables != null) {
      List<DartType> result =
          new List<DartType>.filled(typeVariables.length, null, growable: true);
      for (int i = 0; i < result.length; ++i) {
        result[i] = typeVariables[i].defaultType.build(library);
      }
      if (library is SourceLibraryBuilder) {
        library.inferredTypes.addAll(result);
      }
      return result;
    }

    if (arguments != null && arguments.length != typeVariablesCount) {
      // That should be caught and reported as a compile-time error earlier.
      return unhandled(
          templateTypeArgumentMismatch
              .withArguments(typeVariablesCount)
              .message,
          "buildTypeArguments",
          -1,
          null);
    }

    // arguments.length == typeVariables.length
    List<DartType> result =
        new List<DartType>.filled(arguments.length, null, growable: true);
    for (int i = 0; i < result.length; ++i) {
      result[i] = arguments[i].build(library);
    }
    return result;
  }

  @override
  DartType buildType(LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder, List<TypeBuilder> arguments,
      [bool notInstanceContext]) {
    return buildTypesWithBuiltArguments(
        library,
        nullabilityBuilder.build(library),
        buildTypeArguments(library, arguments, notInstanceContext));
  }

  @override
  Supertype buildSupertype(
      LibraryBuilder library, List<TypeBuilder> arguments) {
    Class cls = isPatch ? origin.cls : this.cls;
    return new Supertype(cls, buildTypeArguments(library, arguments));
  }

  @override
  Supertype buildMixedInType(
      LibraryBuilder library, List<TypeBuilder> arguments) {
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
  void checkSupertypes(CoreTypes coreTypes) {
    // This method determines whether the class (that's being built) its super
    // class appears both in 'extends' and 'implements' clauses and whether any
    // interface appears multiple times in the 'implements' clause.
    // Moreover, it checks that `FutureOr` and `void` are not among the
    // supertypes.

    void fail(NamedTypeBuilder target, Message message,
        TypeAliasBuilder aliasBuilder) {
      int nameOffset = target.nameOffset;
      int nameLength = target.nameLength;
      // TODO(eernst): nameOffset not fully implemented; use backup.
      if (nameOffset == -1) {
        nameOffset = this.charOffset;
        nameLength = noLength;
      }
      if (aliasBuilder != null) {
        addProblem(message, nameOffset, nameLength, context: [
          messageTypedefCause.withLocation(
              aliasBuilder.fileUri, aliasBuilder.charOffset, noLength),
        ]);
      } else {
        addProblem(message, nameOffset, nameLength);
      }
    }

    // Extract and check superclass (if it exists).
    ClassBuilder superClass;
    TypeBuilder superClassType = supertypeBuilder;
    if (superClassType is NamedTypeBuilder) {
      TypeDeclarationBuilder decl = superClassType.declaration;
      TypeAliasBuilder aliasBuilder; // Non-null if a type alias is use.
      if (decl is TypeAliasBuilder) {
        aliasBuilder = decl;
        decl = aliasBuilder.unaliasDeclaration(superClassType.arguments);
      }
      // TODO(eernst): Should gather 'restricted supertype' checks in one place,
      // e.g., dynamic/int/String/Null and more are checked elsewhere.
      if (decl is VoidTypeDeclarationBuilder) {
        fail(superClassType, messageExtendsVoid, aliasBuilder);
      } else if (decl is NeverTypeDeclarationBuilder) {
        fail(superClassType, messageExtendsNever, aliasBuilder);
      } else if (decl is ClassBuilder) {
        superClass = decl;
      }
    }
    if (interfaceBuilders == null) return;

    // Validate interfaces.
    Map<ClassBuilder, int> problems;
    Map<ClassBuilder, int> problemsOffsets;
    Set<ClassBuilder> implemented = new Set<ClassBuilder>();
    for (TypeBuilder type in interfaceBuilders) {
      if (type is NamedTypeBuilder) {
        int charOffset = -1; // TODO(ahe): Get offset from type.
        TypeDeclarationBuilder typeDeclaration = type.declaration;
        TypeDeclarationBuilder decl;
        TypeAliasBuilder aliasBuilder; // Non-null if a type alias is used.
        if (typeDeclaration is TypeAliasBuilder) {
          aliasBuilder = typeDeclaration;
          decl = aliasBuilder.unaliasDeclaration(type.arguments);
        } else {
          decl = typeDeclaration;
        }
        if (decl is ClassBuilder) {
          ClassBuilder interface = decl;
          if (superClass == interface) {
            addProblem(
                templateImplementsSuperClass.withArguments(interface.name),
                this.charOffset,
                noLength);
          } else if (interface.cls.name == "FutureOr" &&
              interface.cls.enclosingLibrary.importUri.scheme == "dart" &&
              interface.cls.enclosingLibrary.importUri.path == "async") {
            addProblem(messageImplementsFutureOr, this.charOffset, noLength);
          } else if (implemented.contains(interface)) {
            // Aggregate repetitions.
            problems ??= new Map<ClassBuilder, int>();
            problems[interface] ??= 0;
            problems[interface] += 1;
            problemsOffsets ??= new Map<ClassBuilder, int>();
            problemsOffsets[interface] ??= charOffset;
          } else {
            implemented.add(interface);
          }
        }
        if (decl != superClass) {
          // TODO(eernst): Have all 'restricted supertype' checks in one place.
          if (decl is VoidTypeDeclarationBuilder) {
            fail(type, messageImplementsVoid, aliasBuilder);
          } else if (decl is NeverTypeDeclarationBuilder) {
            fail(type, messageImplementsNever, aliasBuilder);
          }
        }
      }
    }
    if (problems != null) {
      problems.forEach((ClassBuilder interface, int repetitions) {
        addProblem(
            templateImplementsRepeated.withArguments(
                interface.name, repetitions),
            problemsOffsets[interface],
            noLength);
      });
    }
  }

  @override
  void handleSeenCovariant(
      Types types,
      Member declaredMember,
      Member interfaceMember,
      bool isSetter,
      callback(Member declaredMember, Member interfaceMember, bool isSetter)) {
    // When a parameter is covariant we have to check that we also
    // override the same member in all parents.
    for (Supertype supertype in interfaceMember.enclosingClass.supers) {
      Member m = types.hierarchy.getInterfaceMember(
          supertype.classNode, interfaceMember.name,
          setter: isSetter);
      if (m != null) {
        callback(declaredMember, m, isSetter);
      }
    }
  }

  @override
  bool hasUserDefinedNoSuchMethod(
      Class klass, ClassHierarchy hierarchy, Class objectClass) {
    Member noSuchMethod = hierarchy.getDispatchTarget(klass, noSuchMethodName);
    return noSuchMethod != null && noSuchMethod.enclosingClass != objectClass;
  }

  @override
  String get fullNameForErrors {
    return isMixinApplication && !isNamedMixinApplication
        ? "${supertypeBuilder.fullNameForErrors} with "
            "${mixedInTypeBuilder.fullNameForErrors}"
        : name;
  }

  @override
  void checkMixinApplication(ClassHierarchy hierarchy, CoreTypes coreTypes) {
    TypeEnvironment typeEnvironment = new TypeEnvironment(coreTypes, hierarchy);
    // A mixin declaration can only be applied to a class that implements all
    // the declaration's superclass constraints.
    InterfaceType supertype = cls.supertype.asInterfaceType;
    Substitution substitution = Substitution.fromSupertype(cls.mixedInType);
    for (Supertype constraint in cls.mixedInClass.superclassConstraints()) {
      InterfaceType requiredInterface =
          substitution.substituteSupertype(constraint).asInterfaceType;
      InterfaceType implementedInterface = hierarchy.getTypeAsInstanceOf(
          supertype, requiredInterface.classNode, library.library);
      if (implementedInterface == null ||
          !typeEnvironment.areMutualSubtypes(
              implementedInterface,
              requiredInterface,
              library.isNonNullableByDefault
                  ? SubtypeCheckMode.withNullabilities
                  : SubtypeCheckMode.ignoringNullabilities)) {
        library.addProblem(
            templateMixinApplicationIncompatibleSupertype.withArguments(
                supertype,
                requiredInterface,
                cls.mixedInType.asInterfaceType,
                library.isNonNullableByDefault),
            cls.fileOffset,
            noLength,
            cls.fileUri);
      }
    }
  }

  @override
  void applyPatch(Builder patch) {
    if (patch is ClassBuilder) {
      patch.actualOrigin = this;
      _patchBuilder = patch;
      // TODO(ahe): Complain if `patch.supertype` isn't null.
      scope.forEachLocalMember((String name, Builder member) {
        Builder memberPatch =
            patch.scope.lookupLocalMember(name, setter: false);
        if (memberPatch != null) {
          member.applyPatch(memberPatch);
        }
      });
      scope.forEachLocalSetter((String name, Builder member) {
        Builder memberPatch = patch.scope.lookupLocalMember(name, setter: true);
        if (memberPatch != null) {
          member.applyPatch(memberPatch);
        }
      });
      constructors.local.forEach((String name, Builder member) {
        Builder memberPatch = patch.constructors.local[name];
        if (memberPatch != null) {
          member.applyPatch(memberPatch);
        }
      });

      int originLength = typeVariables?.length ?? 0;
      int patchLength = patch.typeVariables?.length ?? 0;
      if (originLength != patchLength) {
        patch.addProblem(messagePatchClassTypeVariablesMismatch,
            patch.charOffset, noLength, context: [
          messagePatchClassOrigin.withLocation(fileUri, charOffset, noLength)
        ]);
      } else if (typeVariables != null) {
        int count = 0;
        for (TypeVariableBuilder t in patch.typeVariables) {
          typeVariables[count++].applyPatch(t);
        }
      }
    } else {
      library.addProblem(messagePatchDeclarationMismatch, patch.charOffset,
          noLength, patch.fileUri, context: [
        messagePatchDeclarationOrigin.withLocation(
            fileUri, charOffset, noLength)
      ]);
    }
  }

  @override
  FunctionType computeRedirecteeType(
      RedirectingFactoryBuilder factory, TypeEnvironment typeEnvironment) {
    ConstructorReferenceBuilder redirectionTarget = factory.redirectionTarget;
    FunctionNode target;
    if (redirectionTarget.target == null) return null;
    if (redirectionTarget.target is FunctionBuilder) {
      FunctionBuilder targetBuilder = redirectionTarget.target;
      target = targetBuilder.function;
    } else if (redirectionTarget.target is DillConstructorBuilder) {
      DillConstructorBuilder targetBuilder = redirectionTarget.target;
      // It seems that the [redirectionTarget.target] is an instance of
      // [DillMemberBuilder] whenever the redirectee is an implicit constructor,
      // e.g.
      //
      //   class A {
      //     factory A() = B;
      //   }
      //   class B implements A {}
      //
      target = targetBuilder.constructor.function;
    } else if (redirectionTarget.target is DillFactoryBuilder) {
      DillFactoryBuilder targetBuilder = redirectionTarget.target;
      // It seems that the [redirectionTarget.target] is an instance of
      // [DillMemberBuilder] whenever the redirectee is an implicit constructor,
      // e.g.
      //
      //   class A {
      //     factory A() = B;
      //   }
      //   class B implements A {}
      //
      target = targetBuilder.procedure.function;
    } else if (redirectionTarget.target is AmbiguousBuilder) {
      // Multiple definitions with the same name: An error has already been
      // issued.
      // TODO(http://dartbug.com/35294): Unfortunate error; see also
      // https://dart-review.googlesource.com/c/sdk/+/85390/.
      return null;
    } else {
      unhandled("${redirectionTarget.target}", "computeRedirecteeType",
          charOffset, fileUri);
    }

    List<DartType> typeArguments =
        getRedirectingFactoryBody(factory.procedure).typeArguments;
    FunctionType targetFunctionType =
        target.computeFunctionType(library.nonNullable);
    if (typeArguments != null &&
        targetFunctionType.typeParameters.length != typeArguments.length) {
      addProblem(
          templateTypeArgumentMismatch
              .withArguments(targetFunctionType.typeParameters.length),
          redirectionTarget.charOffset,
          noLength);
      return null;
    }

    // Compute the substitution of the target class type parameters if
    // [redirectionTarget] has any type arguments.
    Substitution substitution;
    bool hasProblem = false;
    if (typeArguments != null && typeArguments.length > 0) {
      substitution = Substitution.fromPairs(
          targetFunctionType.typeParameters, typeArguments);
      for (int i = 0; i < targetFunctionType.typeParameters.length; i++) {
        TypeParameter typeParameter = targetFunctionType.typeParameters[i];
        DartType typeParameterBound =
            substitution.substituteType(typeParameter.bound);
        DartType typeArgument = typeArguments[i];
        // Check whether the [typeArgument] respects the bounds of
        // [typeParameter].
        Loader loader = library.loader;
        if (!typeEnvironment.isSubtypeOf(typeArgument, typeParameterBound,
            SubtypeCheckMode.ignoringNullabilities)) {
          addProblem(
              templateRedirectingFactoryIncompatibleTypeArgument.withArguments(
                  typeArgument,
                  typeParameterBound,
                  library.isNonNullableByDefault),
              redirectionTarget.charOffset,
              noLength);
          hasProblem = true;
        } else if (library.isNonNullableByDefault && loader is SourceLoader) {
          if (!typeEnvironment.isSubtypeOf(typeArgument, typeParameterBound,
              SubtypeCheckMode.withNullabilities)) {
            addProblem(
                templateRedirectingFactoryIncompatibleTypeArgument
                    .withArguments(typeArgument, typeParameterBound,
                        library.isNonNullableByDefault),
                redirectionTarget.charOffset,
                noLength);
            hasProblem = true;
          }
        }
      }
    } else if (typeArguments == null &&
        targetFunctionType.typeParameters.length > 0) {
      // TODO(hillerstrom): In this case, we need to perform type inference on
      // the redirectee to obtain actual type arguments which would allow the
      // following program to type check:
      //
      //    class A<T> {
      //       factory A() = B;
      //    }
      //    class B<T> implements A<T> {
      //       B();
      //    }
      //
      return null;
    }

    // Substitute if necessary.
    targetFunctionType = substitution == null
        ? targetFunctionType
        : (substitution.substituteType(targetFunctionType.withoutTypeParameters)
            as FunctionType);

    return hasProblem ? null : targetFunctionType;
  }

  @override
  String computeRedirecteeName(ConstructorReferenceBuilder redirectionTarget) {
    String targetName = redirectionTarget.fullNameForErrors;
    if (targetName == "") {
      return redirectionTarget.target.parent.fullNameForErrors;
    } else {
      return targetName;
    }
  }

  @override
  void checkRedirectingFactory(
      RedirectingFactoryBuilder factory, TypeEnvironment typeEnvironment) {
    // The factory type cannot contain any type parameters other than those of
    // its enclosing class, because constructors cannot specify type parameters
    // of their own.
    FunctionType factoryType = factory.procedure.function
        .computeThisFunctionType(library.nonNullable)
        .withoutTypeParameters;
    FunctionType redirecteeType =
        computeRedirecteeType(factory, typeEnvironment);

    // TODO(hillerstrom): It would be preferable to know whether a failure
    // happened during [_computeRedirecteeType].
    if (redirecteeType == null) return;

    // Check whether [redirecteeType] <: [factoryType].
    Loader loader = library.loader;
    if (!typeEnvironment.isSubtypeOf(
        redirecteeType, factoryType, SubtypeCheckMode.ignoringNullabilities)) {
      addProblem(
          templateIncompatibleRedirecteeFunctionType.withArguments(
              redirecteeType, factoryType, library.isNonNullableByDefault),
          factory.redirectionTarget.charOffset,
          noLength);
    } else if (library.isNonNullableByDefault && loader is SourceLoader) {
      if (!typeEnvironment.isSubtypeOf(
          redirecteeType, factoryType, SubtypeCheckMode.withNullabilities)) {
        addProblem(
            templateIncompatibleRedirecteeFunctionType.withArguments(
                redirecteeType, factoryType, library.isNonNullableByDefault),
            factory.redirectionTarget.charOffset,
            noLength);
      }
    }
  }

  @override
  void checkRedirectingFactories(TypeEnvironment typeEnvironment) {
    Map<String, MemberBuilder> constructors = this.constructors.local;
    Iterable<String> names = constructors.keys;
    for (String name in names) {
      Builder constructor = constructors[name];
      do {
        if (constructor is RedirectingFactoryBuilder) {
          checkRedirectingFactory(constructor, typeEnvironment);
        }
        constructor = constructor.next;
      } while (constructor != null);
    }
  }

  @override
  Map<TypeParameter, DartType> getSubstitutionMap(Class superclass) {
    Supertype supertype = cls.supertype;
    Map<TypeParameter, DartType> substitutionMap = <TypeParameter, DartType>{};
    List<DartType> arguments;
    List<TypeParameter> variables;
    Class classNode;

    while (classNode != superclass) {
      classNode = supertype.classNode;
      arguments = supertype.typeArguments;
      variables = classNode.typeParameters;
      supertype = classNode.supertype;
      if (variables.isNotEmpty) {
        Map<TypeParameter, DartType> directSubstitutionMap =
            <TypeParameter, DartType>{};
        for (int i = 0; i < variables.length; i++) {
          DartType argument =
              i < arguments.length ? arguments[i] : const DynamicType();
          if (substitutionMap != null) {
            // TODO(ahe): Investigate if requiring the caller to use
            // `substituteDeep` from `package:kernel/type_algebra.dart` instead
            // of `substitute` is faster. If so, we can simply this code.
            argument = substitute(argument, substitutionMap);
          }
          directSubstitutionMap[variables[i]] = argument;
        }
        substitutionMap = directSubstitutionMap;
      }
    }

    return substitutionMap;
  }

  @override
  Member lookupInstanceMember(ClassHierarchy hierarchy, Name name,
      {bool isSetter: false, bool isSuper: false}) {
    Class instanceClass = cls;
    if (isPatch) {
      assert(identical(instanceClass, origin.cls),
          "Found ${origin.cls} expected $instanceClass");
      if (isSuper) {
        // The super class is only correctly found through the origin class.
        instanceClass = origin.cls;
      } else {
        Member member =
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
    Member target = isSuper
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

  @override
  Constructor lookupConstructor(Name name, {bool isSuper: false}) {
    Class instanceClass = cls;
    if (isSuper) {
      instanceClass = instanceClass.superclass;
    }
    if (instanceClass != null) {
      for (Constructor constructor in instanceClass.constructors) {
        if (constructor.name == name) return constructor;
      }
    }

    /// Performs a similar lookup to [lookupConstructor], but using a slower
    /// implementation.
    Constructor lookupConstructorWithPatches(Name name, bool isSuper) {
      ClassBuilder builder = this.origin;

      ClassBuilder getSuperclass(ClassBuilder builder) {
        // This way of computing the superclass is slower than using the kernel
        // objects directly.
        Object supertype = builder.supertypeBuilder;
        if (supertype is NamedTypeBuilder) {
          Object builder = supertype.declaration;
          if (builder is ClassBuilder) return builder;
          if (builder is TypeAliasBuilder) {
            TypeDeclarationBuilder declarationBuilder =
                builder.unaliasDeclaration(supertype.arguments);
            if (declarationBuilder is ClassBuilder) return declarationBuilder;
          }
        }
        return null;
      }

      if (isSuper) {
        builder = getSuperclass(builder)?.origin;
      }
      if (builder != null) {
        Class cls = builder.cls;
        for (Constructor constructor in cls.constructors) {
          if (constructor.name == name) return constructor;
        }
      }
      return null;
    }

    return lookupConstructorWithPatches(name, isSuper);
  }
}

class ConstructorRedirection {
  String target;
  bool cycleReported;

  ConstructorRedirection(this.target) : cycleReported = false;
}
