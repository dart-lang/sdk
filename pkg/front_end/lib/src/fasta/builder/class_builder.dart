// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.class_builder;

import 'package:kernel/ast.dart'
    show
        Arguments,
        AsExpression,
        Class,
        Constructor,
        DartType,
        DynamicType,
        Expression,
        Field,
        FunctionNode,
        InterfaceType,
        InvalidType,
        ListLiteral,
        Member,
        MethodInvocation,
        Name,
        Nullability,
        Procedure,
        ProcedureKind,
        RedirectingFactoryConstructor,
        ReturnStatement,
        StaticGet,
        Supertype,
        ThisExpression,
        TypeParameter,
        TypeParameterType,
        VariableDeclaration,
        VoidType;

import 'package:kernel/ast.dart' show FunctionType, TypeParameterType;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/clone.dart' show CloneWithoutBody;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/src/bounds_checks.dart'
    show TypeArgumentIssue, findTypeArgumentIssues, getGenericTypeName;
import 'package:kernel/text/text_serialization_verifier.dart';

import 'package:kernel/type_algebra.dart' show Substitution, substitute;

import 'package:kernel/type_algebra.dart' as type_algebra
    show getSubstitutionMap;

import 'package:kernel/type_environment.dart'
    show SubtypeCheckMode, TypeEnvironment;

import '../../base/common.dart';

import '../dill/dill_member_builder.dart' show DillMemberBuilder;

import 'builder.dart'
    show
        ConstructorReferenceBuilder,
        Builder,
        LibraryBuilder,
        MemberBuilder,
        MetadataBuilder,
        NullabilityBuilder,
        Scope,
        ScopeBuilder,
        TypeBuilder,
        TypeVariableBuilder;

import 'declaration.dart';

import 'declaration_builder.dart';

import '../fasta_codes.dart'
    show
        LocatedMessage,
        Message,
        messageGenericFunctionTypeUsedAsActualTypeArgument,
        messageImplementsFutureOr,
        messagePatchClassOrigin,
        messagePatchClassTypeVariablesMismatch,
        messagePatchDeclarationMismatch,
        messagePatchDeclarationOrigin,
        noLength,
        templateDuplicatedDeclarationUse,
        templateGenericFunctionTypeInferredAsActualTypeArgument,
        templateImplementsRepeated,
        templateImplementsSuperClass,
        templateImplicitMixinOverride,
        templateIncompatibleRedirecteeFunctionType,
        templateIncorrectTypeArgument,
        templateIncorrectTypeArgumentInSupertype,
        templateIncorrectTypeArgumentInSupertypeInferred,
        templateInterfaceCheck,
        templateInternalProblemNotFoundIn,
        templateMixinApplicationIncompatibleSupertype,
        templateNamedMixinOverride,
        templateOverriddenMethodCause,
        templateOverrideFewerNamedArguments,
        templateOverrideFewerPositionalArguments,
        templateOverrideMismatchNamedParameter,
        templateOverrideMoreRequiredArguments,
        templateOverrideTypeMismatchParameter,
        templateOverrideTypeMismatchReturnType,
        templateOverrideTypeMismatchSetter,
        templateOverrideTypeVariablesMismatch,
        templateRedirectingFactoryIncompatibleTypeArgument,
        templateRedirectionTargetNotFound,
        templateTypeArgumentMismatch;

import '../kernel/kernel_builder.dart'
    show
        ConstructorReferenceBuilder,
        Builder,
        FunctionBuilder,
        NamedTypeBuilder,
        LibraryBuilder,
        MemberBuilder,
        MetadataBuilder,
        ProcedureBuilder,
        RedirectingFactoryBuilder,
        Scope,
        TypeBuilder,
        TypeVariableBuilder;

import '../kernel/redirecting_factory_body.dart'
    show getRedirectingFactoryBody, RedirectingFactoryBody;

import '../kernel/kernel_target.dart' show KernelTarget;

import '../kernel/types.dart' show Types;

import '../names.dart' show noSuchMethodName;

import '../problems.dart'
    show internalProblem, unexpected, unhandled, unimplemented, unsupported;

import '../scope.dart' show AmbiguousBuilder;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import '../type_inference/type_schema.dart' show UnknownType;

abstract class ClassBuilder implements DeclarationBuilder {
  /// The type variables declared on a class, extension or mixin declaration.
  List<TypeVariableBuilder> typeVariables;

  /// The type in the `extends` clause of a class declaration.
  ///
  /// Currently this also holds the synthesized super class for a mixin
  /// declaration.
  TypeBuilder supertype;

  /// The type in the `implements` clause of a class or mixin declaration.
  List<TypeBuilder> interfaces;

  /// The types in the `on` clause of an extension or mixin declaration.
  List<TypeBuilder> onTypes;

  Scope get constructors;

  ScopeBuilder get constructorScopeBuilder;

  Map<String, ConstructorRedirection> redirectingConstructors;

  ClassBuilder actualOrigin;

  ClassBuilder patchForTesting;

  TypeBuilder get mixedInType;

  void set mixedInType(TypeBuilder mixin);

  List<ConstructorReferenceBuilder> get constructorReferences;

  void buildOutlineExpressions(LibraryBuilder library);

  /// Registers a constructor redirection for this class and returns true if
  /// this redirection gives rise to a cycle that has not been reported before.
  bool checkConstructorCyclic(String source, String target);

  Builder findConstructorOrFactory(
      String name, int charOffset, Uri uri, LibraryBuilder accessingLibrary);

  void forEach(void f(String name, Builder builder));

  @override
  Builder lookupLocalMember(String name,
      {bool setter: false, bool required: false});

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

  // Deliberately unrelated return type to statically detect more accidental
  // use until Builder.target is fully retired.
  UnrelatedTarget get target;

  @override
  ClassBuilder get origin;

  Class get actualCls;

  InterfaceType get legacyRawType;

  InterfaceType get nullableRawType;

  InterfaceType get nonNullableRawType;

  InterfaceType rawType(Nullability nullability);

  List<DartType> buildTypeArguments(
      LibraryBuilder library, List<TypeBuilder> arguments);

  Supertype buildSupertype(LibraryBuilder library, List<TypeBuilder> arguments);

  Supertype buildMixedInType(
      LibraryBuilder library, List<TypeBuilder> arguments);

  void checkSupertypes(CoreTypes coreTypes);

  void checkBoundsInSupertype(
      Supertype supertype, TypeEnvironment typeEnvironment);

  void checkBoundsInOutline(TypeEnvironment typeEnvironment);

  void addRedirectingConstructor(
      ProcedureBuilder constructorBuilder, SourceLibraryBuilder library);

  void handleSeenCovariant(
      Types types,
      Member declaredMember,
      Member interfaceMember,
      bool isSetter,
      callback(Member declaredMember, Member interfaceMember, bool isSetter));

  void checkOverride(
      Types types,
      Member declaredMember,
      Member interfaceMember,
      bool isSetter,
      callback(Member declaredMember, Member interfaceMember, bool isSetter),
      {bool isInterfaceCheck = false});

  void checkOverrides(
      ClassHierarchy hierarchy, TypeEnvironment typeEnvironment);

  void checkAbstractMembers(CoreTypes coreTypes, ClassHierarchy hierarchy,
      TypeEnvironment typeEnvironment);

  bool hasUserDefinedNoSuchMethod(
      Class klass, ClassHierarchy hierarchy, Class objectClass);

  void transformProcedureToNoSuchMethodForwarder(
      Member noSuchMethodInterface, KernelTarget target, Procedure procedure);

  void addNoSuchMethodForwarderForProcedure(Member noSuchMethod,
      KernelTarget target, Procedure procedure, ClassHierarchy hierarchy);

  void addNoSuchMethodForwarderGetterForField(Member noSuchMethod,
      KernelTarget target, Field field, ClassHierarchy hierarchy);

  void addNoSuchMethodForwarderSetterForField(Member noSuchMethod,
      KernelTarget target, Field field, ClassHierarchy hierarchy);

  /// Adds noSuchMethod forwarding stubs to this class. Returns `true` if the
  /// class was modified.
  bool addNoSuchMethodForwarders(KernelTarget target, ClassHierarchy hierarchy);

  /// Returns whether a covariant parameter was seen and more methods thus have
  /// to be checked.
  bool checkMethodOverride(Types types, Procedure declaredMember,
      Procedure interfaceMember, bool isInterfaceCheck);

  void checkGetterOverride(Types types, Member declaredMember,
      Member interfaceMember, bool isInterfaceCheck);

  /// Returns whether a covariant parameter was seen and more methods thus have
  /// to be checked.
  bool checkSetterOverride(Types types, Member declaredMember,
      Member interfaceMember, bool isInterfaceCheck);

  // When the overriding member is inherited, report the class containing
  // the conflict as the main error.
  void reportInvalidOverride(bool isInterfaceCheck, Member declaredMember,
      Message message, int fileOffset, int length,
      {List<LocatedMessage> context});

  void checkMixinApplication(ClassHierarchy hierarchy);

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
}

abstract class ClassBuilderImpl extends DeclarationBuilderImpl
    implements ClassBuilder {
  @override
  List<TypeVariableBuilder> typeVariables;

  @override
  TypeBuilder supertype;

  @override
  List<TypeBuilder> interfaces;

  @override
  List<TypeBuilder> onTypes;

  @override
  final Scope constructors;

  @override
  final ScopeBuilder constructorScopeBuilder;

  @override
  Map<String, ConstructorRedirection> redirectingConstructors;

  @override
  ClassBuilder actualOrigin;

  @override
  ClassBuilder patchForTesting;

  ClassBuilderImpl(
      List<MetadataBuilder> metadata,
      int modifiers,
      String name,
      this.typeVariables,
      this.supertype,
      this.interfaces,
      this.onTypes,
      Scope scope,
      this.constructors,
      LibraryBuilder parent,
      int charOffset)
      : constructorScopeBuilder = new ScopeBuilder(constructors),
        super(metadata, modifiers, name, parent, charOffset, scope);

  @override
  String get debugName => "ClassBuilder";

  @override
  bool get isMixinApplication => mixedInType != null;

  @override
  bool get isNamedMixinApplication {
    return isMixinApplication && super.isNamedMixinApplication;
  }

  @override
  List<ConstructorReferenceBuilder> get constructorReferences => null;

  @override
  void buildOutlineExpressions(LibraryBuilder library) {
    void build(String ignore, Builder declaration) {
      MemberBuilder member = declaration;
      member.buildOutlineExpressions(library);
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
  int resolveConstructors(LibraryBuilder library) {
    if (constructorReferences == null) return 0;
    for (ConstructorReferenceBuilder ref in constructorReferences) {
      ref.resolveIn(scope, library);
    }
    int count = constructorReferences.length;
    if (count != 0) {
      Map<String, MemberBuilder> constructors = this.constructors.local;
      // Copy keys to avoid concurrent modification error.
      List<String> names = constructors.keys.toList();
      for (String name in names) {
        Builder declaration = constructors[name];
        do {
          if (declaration.parent != this) {
            unexpected("$fileUri", "${declaration.parent.fileUri}", charOffset,
                fileUri);
          }
          if (declaration is RedirectingFactoryBuilder) {
            // Compute the immediate redirection target, not the effective.
            ConstructorReferenceBuilder redirectionTarget =
                declaration.redirectionTarget;
            if (redirectionTarget != null) {
              Builder targetBuilder = redirectionTarget.target;
              if (declaration.next == null) {
                // Only the first one (that is, the last on in the linked list)
                // is actually in the kernel tree. This call creates a StaticGet
                // to [declaration.target] in a field `_redirecting#` which is
                // only legal to do to things in the kernel tree.
                addRedirectingConstructor(declaration, library);
              }
              if (targetBuilder is FunctionBuilder) {
                List<DartType> typeArguments = declaration.typeArguments;
                if (typeArguments == null) {
                  // TODO(32049) If type arguments aren't specified, they should
                  // be inferred.  Currently, the inference is not performed.
                  // The code below is a workaround.
                  typeArguments = new List<DartType>.filled(
                      targetBuilder.member.enclosingClass.typeParameters.length,
                      const DynamicType(),
                      growable: true);
                }
                declaration.setRedirectingFactoryBody(
                    targetBuilder.member, typeArguments);
              } else if (targetBuilder is DillMemberBuilder) {
                List<DartType> typeArguments = declaration.typeArguments;
                if (typeArguments == null) {
                  // TODO(32049) If type arguments aren't specified, they should
                  // be inferred.  Currently, the inference is not performed.
                  // The code below is a workaround.
                  typeArguments = new List<DartType>.filled(
                      targetBuilder.member.enclosingClass.typeParameters.length,
                      const DynamicType(),
                      growable: true);
                }
                declaration.setRedirectingFactoryBody(
                    targetBuilder.member, typeArguments);
              } else if (targetBuilder is AmbiguousBuilder) {
                Message message = templateDuplicatedDeclarationUse
                    .withArguments(redirectionTarget.fullNameForErrors);
                if (declaration.isConst) {
                  addProblem(message, declaration.charOffset, noLength);
                } else {
                  addProblem(message, declaration.charOffset, noLength);
                }
                // CoreTypes aren't computed yet, and this is the outline
                // phase. So we can't and shouldn't create a method body.
                declaration.body = new RedirectingFactoryBody.unresolved(
                    redirectionTarget.fullNameForErrors);
              } else {
                Message message = templateRedirectionTargetNotFound
                    .withArguments(redirectionTarget.fullNameForErrors);
                if (declaration.isConst) {
                  addProblem(message, declaration.charOffset, noLength);
                } else {
                  addProblem(message, declaration.charOffset, noLength);
                }
                // CoreTypes aren't computed yet, and this is the outline
                // phase. So we can't and shouldn't create a method body.
                declaration.body = new RedirectingFactoryBody.unresolved(
                    redirectionTarget.fullNameForErrors);
              }
            }
          }
          declaration = declaration.next;
        } while (declaration != null);
      }
    }
    return count;
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
  Builder findConstructorOrFactory(
      String name, int charOffset, Uri uri, LibraryBuilder accessingLibrary) {
    if (accessingLibrary.origin != library.origin && name.startsWith("_")) {
      return null;
    }
    Builder declaration = constructors.lookup(name, charOffset, uri);
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
  Builder lookupLocalMember(String name,
      {bool setter: false, bool required: false}) {
    Builder builder = setter ? scope.setters[name] : scope.local[name];
    if (builder == null && isPatch) {
      builder = setter ? origin.scope.setters[name] : origin.scope.local[name];
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

  InterfaceType _legacyRawType;
  InterfaceType _nullableRawType;
  InterfaceType _nonNullableRawType;

  // Deliberately unrelated return type to statically detect more accidental
  // use until Builder.target is fully retired.
  @override
  UnrelatedTarget get target => unsupported(
      "ClassBuilder.target is deprecated. "
      "Use ClassBuilder.cls instead.",
      charOffset,
      fileUri);

  @override
  ClassBuilder get origin => actualOrigin ?? this;

  @override
  InterfaceType get thisType => cls.thisType;

  @override
  InterfaceType get legacyRawType {
    // TODO(dmitryas): Use computeBound instead of DynamicType here?
    return _legacyRawType ??= new InterfaceType(
        cls,
        new List<DartType>.filled(typeVariablesCount, const DynamicType()),
        Nullability.legacy);
  }

  @override
  InterfaceType get nullableRawType {
    // TODO(dmitryas): Use computeBound instead of DynamicType here?
    return _nullableRawType ??= new InterfaceType(
        cls,
        new List<DartType>.filled(typeVariablesCount, const DynamicType()),
        Nullability.nullable);
  }

  @override
  InterfaceType get nonNullableRawType {
    // TODO(dmitryas): Use computeBound instead of DynamicType here?
    return _nonNullableRawType ??= new InterfaceType(
        cls,
        new List<DartType>.filled(typeVariablesCount, const DynamicType()),
        Nullability.nonNullable);
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
      case Nullability.neither:
      default:
        return unhandled("$nullability", "rawType", noOffset, noUri);
    }
  }

  @override
  InterfaceType buildTypesWithBuiltArguments(LibraryBuilder library,
      Nullability nullability, List<DartType> arguments) {
    assert(arguments == null || cls.typeParameters.length == arguments.length);
    return arguments == null
        ? rawType(nullability)
        : new InterfaceType(cls, arguments, nullability);
  }

  @override
  int get typeVariablesCount => typeVariables?.length ?? 0;

  @override
  List<DartType> buildTypeArguments(
      LibraryBuilder library, List<TypeBuilder> arguments) {
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
  InterfaceType buildType(LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder, List<TypeBuilder> arguments) {
    return buildTypesWithBuiltArguments(
        library,
        nullabilityBuilder.build(library),
        buildTypeArguments(library, arguments));
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
    if (interfaces == null) return;

    // Extract super class (if it exists).
    ClassBuilder superClass;
    TypeBuilder superClassType = supertype;
    if (superClassType is NamedTypeBuilder) {
      Builder decl = superClassType.declaration;
      if (decl is ClassBuilder) {
        superClass = decl;
      }
    }

    // Validate interfaces.
    Map<ClassBuilder, int> problems;
    Map<ClassBuilder, int> problemsOffsets;
    Set<ClassBuilder> implemented = new Set<ClassBuilder>();
    for (TypeBuilder type in interfaces) {
      if (type is NamedTypeBuilder) {
        int charOffset = -1; // TODO(ahe): Get offset from type.
        Builder decl = type.declaration;
        if (decl is ClassBuilder) {
          ClassBuilder interface = decl;
          if (superClass == interface) {
            addProblem(
                templateImplementsSuperClass.withArguments(interface.name),
                charOffset,
                noLength);
          } else if (implemented.contains(interface)) {
            // Aggregate repetitions.
            problems ??= new Map<ClassBuilder, int>();
            problems[interface] ??= 0;
            problems[interface] += 1;

            problemsOffsets ??= new Map<ClassBuilder, int>();
            problemsOffsets[interface] ??= charOffset;
          } else if (interface.cls == coreTypes.futureOrClass) {
            addProblem(messageImplementsFutureOr, charOffset,
                interface.cls.name.length);
          } else {
            implemented.add(interface);
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
  void checkBoundsInSupertype(
      Supertype supertype, TypeEnvironment typeEnvironment) {
    SourceLibraryBuilder library = this.library;

    List<TypeArgumentIssue> issues = findTypeArgumentIssues(
        new InterfaceType(supertype.classNode, supertype.typeArguments),
        typeEnvironment,
        allowSuperBounded: false);
    if (issues != null) {
      for (TypeArgumentIssue issue in issues) {
        Message message;
        DartType argument = issue.argument;
        TypeParameter typeParameter = issue.typeParameter;
        bool inferred = library.inferredTypes.contains(argument);
        if (argument is FunctionType && argument.typeParameters.length > 0) {
          if (inferred) {
            message = templateGenericFunctionTypeInferredAsActualTypeArgument
                .withArguments(argument);
          } else {
            message = messageGenericFunctionTypeUsedAsActualTypeArgument;
          }
          typeParameter = null;
        } else {
          if (inferred) {
            message =
                templateIncorrectTypeArgumentInSupertypeInferred.withArguments(
                    argument,
                    typeParameter.bound,
                    typeParameter.name,
                    getGenericTypeName(issue.enclosingType),
                    supertype.classNode.name,
                    name);
          } else {
            message = templateIncorrectTypeArgumentInSupertype.withArguments(
                argument,
                typeParameter.bound,
                typeParameter.name,
                getGenericTypeName(issue.enclosingType),
                supertype.classNode.name,
                name);
          }
        }

        library.reportTypeArgumentIssue(
            message, fileUri, charOffset, typeParameter);
      }
    }
  }

  @override
  void checkBoundsInOutline(TypeEnvironment typeEnvironment) {
    SourceLibraryBuilder library = this.library;

    // Check in bounds of own type variables.
    for (TypeParameter parameter in cls.typeParameters) {
      List<TypeArgumentIssue> issues = findTypeArgumentIssues(
          parameter.bound, typeEnvironment,
          allowSuperBounded: true);
      if (issues != null) {
        for (TypeArgumentIssue issue in issues) {
          DartType argument = issue.argument;
          TypeParameter typeParameter = issue.typeParameter;
          if (library.inferredTypes.contains(argument)) {
            // Inference in type expressions in the supertypes boils down to
            // instantiate-to-bound which shouldn't produce anything that breaks
            // the bounds after the non-simplicity checks are done.  So, any
            // violation here is the result of non-simple bounds, and the error
            // is reported elsewhere.
            continue;
          }

          Message message;
          if (argument is FunctionType && argument.typeParameters.length > 0) {
            message = messageGenericFunctionTypeUsedAsActualTypeArgument;
            typeParameter = null;
          } else {
            message = templateIncorrectTypeArgument.withArguments(
                argument,
                typeParameter.bound,
                typeParameter.name,
                getGenericTypeName(issue.enclosingType));
          }

          library.reportTypeArgumentIssue(
              message, fileUri, parameter.fileOffset, typeParameter);
        }
      }
    }

    // Check in supers.
    if (cls.supertype != null) {
      checkBoundsInSupertype(cls.supertype, typeEnvironment);
    }
    if (cls.mixedInType != null) {
      checkBoundsInSupertype(cls.mixedInType, typeEnvironment);
    }
    if (cls.implementedTypes != null) {
      for (Supertype supertype in cls.implementedTypes) {
        checkBoundsInSupertype(supertype, typeEnvironment);
      }
    }

    // Check in members.
    for (Field field in cls.fields) {
      library.checkBoundsInField(field, typeEnvironment);
    }
    for (Procedure procedure in cls.procedures) {
      library.checkBoundsInFunctionNode(
          procedure.function, typeEnvironment, fileUri);
    }
    for (Constructor constructor in cls.constructors) {
      library.checkBoundsInFunctionNode(
          constructor.function, typeEnvironment, fileUri);
    }
    for (RedirectingFactoryConstructor redirecting
        in cls.redirectingFactoryConstructors) {
      library.checkBoundsInFunctionNodeParts(
          typeEnvironment, fileUri, redirecting.fileOffset,
          typeParameters: redirecting.typeParameters,
          positionalParameters: redirecting.positionalParameters,
          namedParameters: redirecting.namedParameters);
    }
  }

  @override
  void addRedirectingConstructor(
      ProcedureBuilder constructorBuilder, SourceLibraryBuilder library) {
    // Add a new synthetic field to this class for representing factory
    // constructors. This is used to support resolving such constructors in
    // source code.
    //
    // The synthetic field looks like this:
    //
    //     final _redirecting# = [c1, ..., cn];
    //
    // Where each c1 ... cn are an instance of [StaticGet] whose target is
    // [constructor.target].
    //
    // TODO(ahe): Add a kernel node to represent redirecting factory bodies.
    DillMemberBuilder constructorsField =
        origin.scope.local.putIfAbsent("_redirecting#", () {
      ListLiteral literal = new ListLiteral(<Expression>[]);
      Name name = new Name("_redirecting#", library.library);
      Field field = new Field(name,
          isStatic: true, initializer: literal, fileUri: cls.fileUri)
        ..fileOffset = cls.fileOffset;
      cls.addMember(field);
      return new DillMemberBuilder(field, this);
    });
    Field field = constructorsField.member;
    ListLiteral literal = field.initializer;
    literal.expressions
        .add(new StaticGet(constructorBuilder.procedure)..parent = literal);
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
      Member m = types.hierarchy.getInterfaceMemberKernel(
          supertype.classNode, interfaceMember.name, isSetter);
      if (m != null) {
        callback(declaredMember, m, isSetter);
      }
    }
  }

  @override
  void checkOverride(
      Types types,
      Member declaredMember,
      Member interfaceMember,
      bool isSetter,
      callback(Member declaredMember, Member interfaceMember, bool isSetter),
      {bool isInterfaceCheck = false}) {
    if (declaredMember == interfaceMember) {
      return;
    }
    if (declaredMember is Constructor || interfaceMember is Constructor) {
      unimplemented(
          "Constructor in override check.", declaredMember.fileOffset, fileUri);
    }
    if (declaredMember is Procedure && interfaceMember is Procedure) {
      if (declaredMember.kind == ProcedureKind.Method &&
          interfaceMember.kind == ProcedureKind.Method) {
        bool seenCovariant = checkMethodOverride(
            types, declaredMember, interfaceMember, isInterfaceCheck);
        if (seenCovariant) {
          handleSeenCovariant(
              types, declaredMember, interfaceMember, isSetter, callback);
        }
      }
      if (declaredMember.kind == ProcedureKind.Getter &&
          interfaceMember.kind == ProcedureKind.Getter) {
        checkGetterOverride(
            types, declaredMember, interfaceMember, isInterfaceCheck);
      }
      if (declaredMember.kind == ProcedureKind.Setter &&
          interfaceMember.kind == ProcedureKind.Setter) {
        bool seenCovariant = checkSetterOverride(
            types, declaredMember, interfaceMember, isInterfaceCheck);
        if (seenCovariant) {
          handleSeenCovariant(
              types, declaredMember, interfaceMember, isSetter, callback);
        }
      }
    } else {
      bool declaredMemberHasGetter = declaredMember is Field ||
          declaredMember is Procedure && declaredMember.isGetter;
      bool interfaceMemberHasGetter = interfaceMember is Field ||
          interfaceMember is Procedure && interfaceMember.isGetter;
      bool declaredMemberHasSetter = (declaredMember is Field &&
              !declaredMember.isFinal &&
              !declaredMember.isConst) ||
          declaredMember is Procedure && declaredMember.isSetter;
      bool interfaceMemberHasSetter = (interfaceMember is Field &&
              !interfaceMember.isFinal &&
              !interfaceMember.isConst) ||
          interfaceMember is Procedure && interfaceMember.isSetter;
      if (declaredMemberHasGetter && interfaceMemberHasGetter) {
        checkGetterOverride(
            types, declaredMember, interfaceMember, isInterfaceCheck);
      }
      if (declaredMemberHasSetter && interfaceMemberHasSetter) {
        bool seenCovariant = checkSetterOverride(
            types, declaredMember, interfaceMember, isInterfaceCheck);
        if (seenCovariant) {
          handleSeenCovariant(
              types, declaredMember, interfaceMember, isSetter, callback);
        }
      }
    }
    // TODO(ahe): Handle other cases: accessors, operators, and fields.
  }

  @override
  void checkOverrides(
      ClassHierarchy hierarchy, TypeEnvironment typeEnvironment) {}

  @override
  void checkAbstractMembers(CoreTypes coreTypes, ClassHierarchy hierarchy,
      TypeEnvironment typeEnvironment) {}

  @override
  bool hasUserDefinedNoSuchMethod(
      Class klass, ClassHierarchy hierarchy, Class objectClass) {
    Member noSuchMethod = hierarchy.getDispatchTarget(klass, noSuchMethodName);
    return noSuchMethod != null && noSuchMethod.enclosingClass != objectClass;
  }

  @override
  void transformProcedureToNoSuchMethodForwarder(
      Member noSuchMethodInterface, KernelTarget target, Procedure procedure) {
    String prefix =
        procedure.isGetter ? 'get:' : procedure.isSetter ? 'set:' : '';
    Expression invocation = target.backendTarget.instantiateInvocation(
        target.loader.coreTypes,
        new ThisExpression(),
        prefix + procedure.name.name,
        new Arguments.forwarded(procedure.function),
        procedure.fileOffset,
        /*isSuper=*/ false);
    Expression result = new MethodInvocation(new ThisExpression(),
        noSuchMethodName, new Arguments([invocation]), noSuchMethodInterface)
      ..fileOffset = procedure.fileOffset;
    if (procedure.function.returnType is! VoidType) {
      result = new AsExpression(result, procedure.function.returnType)
        ..isTypeError = true
        ..fileOffset = procedure.fileOffset;
    }
    procedure.function.body = new ReturnStatement(result)
      ..fileOffset = procedure.fileOffset;
    procedure.function.body.parent = procedure.function;

    procedure.isAbstract = false;
    procedure.isNoSuchMethodForwarder = true;
    procedure.isForwardingStub = false;
    procedure.isForwardingSemiStub = false;
  }

  @override
  void addNoSuchMethodForwarderForProcedure(Member noSuchMethod,
      KernelTarget target, Procedure procedure, ClassHierarchy hierarchy) {
    CloneWithoutBody cloner = new CloneWithoutBody(
        typeSubstitution: type_algebra.getSubstitutionMap(
            hierarchy.getClassAsInstanceOf(cls, procedure.enclosingClass)),
        cloneAnnotations: false);
    Procedure cloned = cloner.clone(procedure)..isExternal = false;
    transformProcedureToNoSuchMethodForwarder(noSuchMethod, target, cloned);
    cls.procedures.add(cloned);
    cloned.parent = cls;

    SourceLibraryBuilder library = this.library;
    library.forwardersOrigins.add(cloned);
    library.forwardersOrigins.add(procedure);
  }

  @override
  void addNoSuchMethodForwarderGetterForField(Member noSuchMethod,
      KernelTarget target, Field field, ClassHierarchy hierarchy) {
    Substitution substitution = Substitution.fromSupertype(
        hierarchy.getClassAsInstanceOf(cls, field.enclosingClass));
    Procedure getter = new Procedure(
        field.name,
        ProcedureKind.Getter,
        new FunctionNode(null,
            typeParameters: <TypeParameter>[],
            positionalParameters: <VariableDeclaration>[],
            namedParameters: <VariableDeclaration>[],
            requiredParameterCount: 0,
            returnType: substitution.substituteType(field.type)),
        fileUri: field.fileUri)
      ..fileOffset = field.fileOffset;
    transformProcedureToNoSuchMethodForwarder(noSuchMethod, target, getter);
    cls.procedures.add(getter);
    getter.parent = cls;
  }

  @override
  void addNoSuchMethodForwarderSetterForField(Member noSuchMethod,
      KernelTarget target, Field field, ClassHierarchy hierarchy) {
    Substitution substitution = Substitution.fromSupertype(
        hierarchy.getClassAsInstanceOf(cls, field.enclosingClass));
    Procedure setter = new Procedure(
        field.name,
        ProcedureKind.Setter,
        new FunctionNode(null,
            typeParameters: <TypeParameter>[],
            positionalParameters: <VariableDeclaration>[
              new VariableDeclaration("value",
                  type: substitution.substituteType(field.type))
            ],
            namedParameters: <VariableDeclaration>[],
            requiredParameterCount: 1,
            returnType: const VoidType()),
        fileUri: field.fileUri)
      ..fileOffset = field.fileOffset;
    transformProcedureToNoSuchMethodForwarder(noSuchMethod, target, setter);
    cls.procedures.add(setter);
    setter.parent = cls;
  }

  @override
  bool addNoSuchMethodForwarders(
      KernelTarget target, ClassHierarchy hierarchy) {
    if (cls.isAbstract) return false;

    Set<Name> existingForwardersNames = new Set<Name>();
    Set<Name> existingSetterForwardersNames = new Set<Name>();
    Class leastConcreteSuperclass = cls.superclass;
    while (
        leastConcreteSuperclass != null && leastConcreteSuperclass.isAbstract) {
      leastConcreteSuperclass = leastConcreteSuperclass.superclass;
    }
    if (leastConcreteSuperclass != null) {
      bool superHasUserDefinedNoSuchMethod = hasUserDefinedNoSuchMethod(
          leastConcreteSuperclass, hierarchy, target.objectClass);
      List<Member> concrete =
          hierarchy.getDispatchTargets(leastConcreteSuperclass);
      for (Member member
          in hierarchy.getInterfaceMembers(leastConcreteSuperclass)) {
        if ((superHasUserDefinedNoSuchMethod ||
                leastConcreteSuperclass.enclosingLibrary.compareTo(
                            member.enclosingClass.enclosingLibrary) !=
                        0 &&
                    member.name.isPrivate) &&
            ClassHierarchy.findMemberByName(concrete, member.name) == null) {
          existingForwardersNames.add(member.name);
        }
      }

      List<Member> concreteSetters =
          hierarchy.getDispatchTargets(leastConcreteSuperclass, setters: true);
      for (Member member in hierarchy
          .getInterfaceMembers(leastConcreteSuperclass, setters: true)) {
        if (ClassHierarchy.findMemberByName(concreteSetters, member.name) ==
            null) {
          existingSetterForwardersNames.add(member.name);
        }
      }
    }

    Member noSuchMethod = ClassHierarchy.findMemberByName(
        hierarchy.getInterfaceMembers(cls), noSuchMethodName);

    List<Member> concrete = hierarchy.getDispatchTargets(cls);
    List<Member> declared = hierarchy.getDeclaredMembers(cls);

    bool clsHasUserDefinedNoSuchMethod =
        hasUserDefinedNoSuchMethod(cls, hierarchy, target.objectClass);
    bool changed = false;
    for (Member member in hierarchy.getInterfaceMembers(cls)) {
      // We generate a noSuchMethod forwarder for [member] in [cls] if the
      // following three conditions are satisfied simultaneously:
      // 1) There is a user-defined noSuchMethod in [cls] or [member] is private
      //    and the enclosing library of [member] is different from that of
      //    [cls].
      // 2) There is no implementation of [member] in [cls].
      // 3) The superclass of [cls] has no forwarder for [member].
      if (member is Procedure &&
          (clsHasUserDefinedNoSuchMethod ||
              cls.enclosingLibrary
                          .compareTo(member.enclosingClass.enclosingLibrary) !=
                      0 &&
                  member.name.isPrivate) &&
          ClassHierarchy.findMemberByName(concrete, member.name) == null &&
          !existingForwardersNames.contains(member.name)) {
        if (ClassHierarchy.findMemberByName(declared, member.name) != null) {
          transformProcedureToNoSuchMethodForwarder(
              noSuchMethod, target, member);
        } else {
          addNoSuchMethodForwarderForProcedure(
              noSuchMethod, target, member, hierarchy);
        }
        existingForwardersNames.add(member.name);
        changed = true;
        continue;
      }

      if (member is Field &&
          ClassHierarchy.findMemberByName(concrete, member.name) == null &&
          !existingForwardersNames.contains(member.name)) {
        addNoSuchMethodForwarderGetterForField(
            noSuchMethod, target, member, hierarchy);
        existingForwardersNames.add(member.name);
        changed = true;
      }
    }

    List<Member> concreteSetters =
        hierarchy.getDispatchTargets(cls, setters: true);
    List<Member> declaredSetters =
        hierarchy.getDeclaredMembers(cls, setters: true);
    for (Member member in hierarchy.getInterfaceMembers(cls, setters: true)) {
      if (member is Procedure &&
          ClassHierarchy.findMemberByName(concreteSetters, member.name) ==
              null &&
          !existingSetterForwardersNames.contains(member.name)) {
        if (ClassHierarchy.findMemberByName(declaredSetters, member.name) !=
            null) {
          transformProcedureToNoSuchMethodForwarder(
              noSuchMethod, target, member);
        } else {
          addNoSuchMethodForwarderForProcedure(
              noSuchMethod, target, member, hierarchy);
        }
        existingSetterForwardersNames.add(member.name);
        changed = true;
      }
      if (member is Field &&
          ClassHierarchy.findMemberByName(concreteSetters, member.name) ==
              null &&
          !existingSetterForwardersNames.contains(member.name)) {
        addNoSuchMethodForwarderSetterForField(
            noSuchMethod, target, member, hierarchy);
        existingSetterForwardersNames.add(member.name);
        changed = true;
      }
    }

    return changed;
  }

  Uri _getMemberUri(Member member) {
    if (member is Field) return member.fileUri;
    if (member is Procedure) return member.fileUri;
    // Other member types won't be seen because constructors don't participate
    // in override relationships
    return unhandled('${member.runtimeType}', '_getMemberUri', -1, null);
  }

  Substitution _computeInterfaceSubstitution(
      Types types,
      Member declaredMember,
      Member interfaceMember,
      FunctionNode declaredFunction,
      FunctionNode interfaceFunction,
      bool isInterfaceCheck) {
    Substitution interfaceSubstitution = Substitution.empty;
    if (interfaceMember.enclosingClass.typeParameters.isNotEmpty) {
      interfaceSubstitution = Substitution.fromInterfaceType(types.hierarchy
          .getKernelTypeAsInstanceOf(
              cls.thisType, interfaceMember.enclosingClass));
    }
    if (declaredFunction?.typeParameters?.length !=
        interfaceFunction?.typeParameters?.length) {
      reportInvalidOverride(
          isInterfaceCheck,
          declaredMember,
          templateOverrideTypeVariablesMismatch.withArguments(
              "${declaredMember.enclosingClass.name}."
                  "${declaredMember.name.name}",
              "${interfaceMember.enclosingClass.name}."
                  "${interfaceMember.name.name}"),
          declaredMember.fileOffset,
          noLength,
          context: [
            templateOverriddenMethodCause
                .withArguments(interfaceMember.name.name)
                .withLocation(_getMemberUri(interfaceMember),
                    interfaceMember.fileOffset, noLength)
          ]);
    } else if (declaredFunction?.typeParameters != null) {
      Map<TypeParameter, DartType> substitutionMap =
          <TypeParameter, DartType>{};
      for (int i = 0; i < declaredFunction.typeParameters.length; ++i) {
        substitutionMap[interfaceFunction.typeParameters[i]] =
            new TypeParameterType(declaredFunction.typeParameters[i]);
      }
      Substitution substitution = Substitution.fromMap(substitutionMap);
      for (int i = 0; i < declaredFunction.typeParameters.length; ++i) {
        TypeParameter declaredParameter = declaredFunction.typeParameters[i];
        TypeParameter interfaceParameter = interfaceFunction.typeParameters[i];
        if (!interfaceParameter.isGenericCovariantImpl) {
          DartType declaredBound = declaredParameter.bound;
          DartType interfaceBound = interfaceParameter.bound;
          if (interfaceSubstitution != null) {
            declaredBound = interfaceSubstitution.substituteType(declaredBound);
            interfaceBound =
                interfaceSubstitution.substituteType(interfaceBound);
          }
          if (declaredBound != substitution.substituteType(interfaceBound)) {
            reportInvalidOverride(
                isInterfaceCheck,
                declaredMember,
                templateOverrideTypeVariablesMismatch.withArguments(
                    "${declaredMember.enclosingClass.name}."
                        "${declaredMember.name.name}",
                    "${interfaceMember.enclosingClass.name}."
                        "${interfaceMember.name.name}"),
                declaredMember.fileOffset,
                noLength,
                context: [
                  templateOverriddenMethodCause
                      .withArguments(interfaceMember.name.name)
                      .withLocation(_getMemberUri(interfaceMember),
                          interfaceMember.fileOffset, noLength)
                ]);
          }
        }
      }
      interfaceSubstitution =
          Substitution.combine(interfaceSubstitution, substitution);
    }
    return interfaceSubstitution;
  }

  Substitution _computeDeclaredSubstitution(
      Types types, Member declaredMember) {
    Substitution declaredSubstitution = Substitution.empty;
    if (declaredMember.enclosingClass.typeParameters.isNotEmpty) {
      declaredSubstitution = Substitution.fromInterfaceType(types.hierarchy
          .getKernelTypeAsInstanceOf(
              cls.thisType, declaredMember.enclosingClass));
    }
    return declaredSubstitution;
  }

  void _checkTypes(
      Types types,
      Substitution interfaceSubstitution,
      Substitution declaredSubstitution,
      Member declaredMember,
      Member interfaceMember,
      DartType declaredType,
      DartType interfaceType,
      bool isCovariant,
      VariableDeclaration declaredParameter,
      bool isInterfaceCheck,
      {bool asIfDeclaredParameter = false}) {
    if (interfaceSubstitution != null) {
      interfaceType = interfaceSubstitution.substituteType(interfaceType);
    }
    if (declaredSubstitution != null) {
      declaredType = declaredSubstitution.substituteType(declaredType);
    }

    bool inParameter = declaredParameter != null || asIfDeclaredParameter;
    DartType subtype = inParameter ? interfaceType : declaredType;
    DartType supertype = inParameter ? declaredType : interfaceType;

    if (types.isSubtypeOfKernel(
        subtype, supertype, SubtypeCheckMode.ignoringNullabilities)) {
      // No problem--the proper subtyping relation is satisfied.
    } else if (isCovariant &&
        types.isSubtypeOfKernel(
            supertype, subtype, SubtypeCheckMode.ignoringNullabilities)) {
      // No problem--the overriding parameter is marked "covariant" and has
      // a type which is a subtype of the parameter it overrides.
    } else if (subtype is InvalidType || supertype is InvalidType) {
      // Don't report a problem as something else is wrong that has already
      // been reported.
    } else {
      // Report an error.
      String declaredMemberName =
          '${declaredMember.enclosingClass.name}.${declaredMember.name.name}';
      String interfaceMemberName =
          '${interfaceMember.enclosingClass.name}.${interfaceMember.name.name}';
      Message message;
      int fileOffset;
      if (declaredParameter == null) {
        if (asIfDeclaredParameter) {
          // Setter overridden by field
          message = templateOverrideTypeMismatchSetter.withArguments(
              declaredMemberName,
              declaredType,
              interfaceType,
              interfaceMemberName);
        } else {
          message = templateOverrideTypeMismatchReturnType.withArguments(
              declaredMemberName,
              declaredType,
              interfaceType,
              interfaceMemberName);
        }
        fileOffset = declaredMember.fileOffset;
      } else {
        message = templateOverrideTypeMismatchParameter.withArguments(
            declaredParameter.name,
            declaredMemberName,
            declaredType,
            interfaceType,
            interfaceMemberName);
        fileOffset = declaredParameter.fileOffset;
      }
      reportInvalidOverride(
          isInterfaceCheck, declaredMember, message, fileOffset, noLength,
          context: [
            templateOverriddenMethodCause
                .withArguments(interfaceMember.name.name)
                .withLocation(_getMemberUri(interfaceMember),
                    interfaceMember.fileOffset, noLength)
          ]);
    }
  }

  @override
  bool checkMethodOverride(Types types, Procedure declaredMember,
      Procedure interfaceMember, bool isInterfaceCheck) {
    assert(declaredMember.kind == ProcedureKind.Method);
    assert(interfaceMember.kind == ProcedureKind.Method);
    bool seenCovariant = false;
    FunctionNode declaredFunction = declaredMember.function;
    FunctionNode interfaceFunction = interfaceMember.function;

    Substitution interfaceSubstitution = _computeInterfaceSubstitution(
        types,
        declaredMember,
        interfaceMember,
        declaredFunction,
        interfaceFunction,
        isInterfaceCheck);

    Substitution declaredSubstitution =
        _computeDeclaredSubstitution(types, declaredMember);

    _checkTypes(
        types,
        interfaceSubstitution,
        declaredSubstitution,
        declaredMember,
        interfaceMember,
        declaredFunction.returnType,
        interfaceFunction.returnType,
        false,
        null,
        isInterfaceCheck);
    if (declaredFunction.positionalParameters.length <
        interfaceFunction.positionalParameters.length) {
      reportInvalidOverride(
          isInterfaceCheck,
          declaredMember,
          templateOverrideFewerPositionalArguments.withArguments(
              "${declaredMember.enclosingClass.name}."
                  "${declaredMember.name.name}",
              "${interfaceMember.enclosingClass.name}."
                  "${interfaceMember.name.name}"),
          declaredMember.fileOffset,
          noLength,
          context: [
            templateOverriddenMethodCause
                .withArguments(interfaceMember.name.name)
                .withLocation(interfaceMember.fileUri,
                    interfaceMember.fileOffset, noLength)
          ]);
    }
    if (interfaceFunction.requiredParameterCount <
        declaredFunction.requiredParameterCount) {
      reportInvalidOverride(
          isInterfaceCheck,
          declaredMember,
          templateOverrideMoreRequiredArguments.withArguments(
              "${declaredMember.enclosingClass.name}."
                  "${declaredMember.name.name}",
              "${interfaceMember.enclosingClass.name}."
                  "${interfaceMember.name.name}"),
          declaredMember.fileOffset,
          noLength,
          context: [
            templateOverriddenMethodCause
                .withArguments(interfaceMember.name.name)
                .withLocation(interfaceMember.fileUri,
                    interfaceMember.fileOffset, noLength)
          ]);
    }
    for (int i = 0;
        i < declaredFunction.positionalParameters.length &&
            i < interfaceFunction.positionalParameters.length;
        i++) {
      VariableDeclaration declaredParameter =
          declaredFunction.positionalParameters[i];
      VariableDeclaration interfaceParameter =
          interfaceFunction.positionalParameters[i];
      _checkTypes(
          types,
          interfaceSubstitution,
          declaredSubstitution,
          declaredMember,
          interfaceMember,
          declaredParameter.type,
          interfaceFunction.positionalParameters[i].type,
          declaredParameter.isCovariant || interfaceParameter.isCovariant,
          declaredParameter,
          isInterfaceCheck);
      if (declaredParameter.isCovariant) seenCovariant = true;
    }
    if (declaredFunction.namedParameters.isEmpty &&
        interfaceFunction.namedParameters.isEmpty) {
      return seenCovariant;
    }
    if (declaredFunction.namedParameters.length <
        interfaceFunction.namedParameters.length) {
      reportInvalidOverride(
          isInterfaceCheck,
          declaredMember,
          templateOverrideFewerNamedArguments.withArguments(
              "${declaredMember.enclosingClass.name}."
                  "${declaredMember.name.name}",
              "${interfaceMember.enclosingClass.name}."
                  "${interfaceMember.name.name}"),
          declaredMember.fileOffset,
          noLength,
          context: [
            templateOverriddenMethodCause
                .withArguments(interfaceMember.name.name)
                .withLocation(interfaceMember.fileUri,
                    interfaceMember.fileOffset, noLength)
          ]);
    }
    int compareNamedParameters(VariableDeclaration p0, VariableDeclaration p1) {
      return p0.name.compareTo(p1.name);
    }

    List<VariableDeclaration> sortedFromDeclared =
        new List.from(declaredFunction.namedParameters)
          ..sort(compareNamedParameters);
    List<VariableDeclaration> sortedFromInterface =
        new List.from(interfaceFunction.namedParameters)
          ..sort(compareNamedParameters);
    Iterator<VariableDeclaration> declaredNamedParameters =
        sortedFromDeclared.iterator;
    Iterator<VariableDeclaration> interfaceNamedParameters =
        sortedFromInterface.iterator;
    outer:
    while (declaredNamedParameters.moveNext() &&
        interfaceNamedParameters.moveNext()) {
      while (declaredNamedParameters.current.name !=
          interfaceNamedParameters.current.name) {
        if (!declaredNamedParameters.moveNext()) {
          reportInvalidOverride(
              isInterfaceCheck,
              declaredMember,
              templateOverrideMismatchNamedParameter.withArguments(
                  "${declaredMember.enclosingClass.name}."
                      "${declaredMember.name.name}",
                  interfaceNamedParameters.current.name,
                  "${interfaceMember.enclosingClass.name}."
                      "${interfaceMember.name.name}"),
              declaredMember.fileOffset,
              noLength,
              context: [
                templateOverriddenMethodCause
                    .withArguments(interfaceMember.name.name)
                    .withLocation(interfaceMember.fileUri,
                        interfaceMember.fileOffset, noLength)
              ]);
          break outer;
        }
      }
      VariableDeclaration declaredParameter = declaredNamedParameters.current;
      _checkTypes(
          types,
          interfaceSubstitution,
          declaredSubstitution,
          declaredMember,
          interfaceMember,
          declaredParameter.type,
          interfaceNamedParameters.current.type,
          declaredParameter.isCovariant,
          declaredParameter,
          isInterfaceCheck);
      if (declaredParameter.isCovariant) seenCovariant = true;
    }
    return seenCovariant;
  }

  void checkGetterOverride(Types types, Member declaredMember,
      Member interfaceMember, bool isInterfaceCheck) {
    Substitution interfaceSubstitution = _computeInterfaceSubstitution(
        types, declaredMember, interfaceMember, null, null, isInterfaceCheck);
    Substitution declaredSubstitution =
        _computeDeclaredSubstitution(types, declaredMember);
    DartType declaredType = declaredMember.getterType;
    DartType interfaceType = interfaceMember.getterType;
    _checkTypes(
        types,
        interfaceSubstitution,
        declaredSubstitution,
        declaredMember,
        interfaceMember,
        declaredType,
        interfaceType,
        false,
        null,
        isInterfaceCheck);
  }

  @override
  bool checkSetterOverride(Types types, Member declaredMember,
      Member interfaceMember, bool isInterfaceCheck) {
    Substitution interfaceSubstitution = _computeInterfaceSubstitution(
        types, declaredMember, interfaceMember, null, null, isInterfaceCheck);
    Substitution declaredSubstitution =
        _computeDeclaredSubstitution(types, declaredMember);
    DartType declaredType = declaredMember.setterType;
    DartType interfaceType = interfaceMember.setterType;
    VariableDeclaration declaredParameter =
        declaredMember.function?.positionalParameters?.elementAt(0);
    bool isCovariant = declaredParameter?.isCovariant ?? false;
    if (!isCovariant && declaredMember is Field) {
      isCovariant = declaredMember.isCovariant;
    }
    if (!isCovariant && interfaceMember is Field) {
      isCovariant = interfaceMember.isCovariant;
    }
    _checkTypes(
        types,
        interfaceSubstitution,
        declaredSubstitution,
        declaredMember,
        interfaceMember,
        declaredType,
        interfaceType,
        isCovariant,
        declaredParameter,
        isInterfaceCheck,
        asIfDeclaredParameter: true);
    return isCovariant;
  }

  @override
  void reportInvalidOverride(bool isInterfaceCheck, Member declaredMember,
      Message message, int fileOffset, int length,
      {List<LocatedMessage> context}) {
    if (declaredMember.enclosingClass == cls) {
      // Ordinary override
      library.addProblem(message, fileOffset, length, declaredMember.fileUri,
          context: context);
    } else {
      context = [
        message.withLocation(declaredMember.fileUri, fileOffset, length),
        ...?context
      ];
      if (isInterfaceCheck) {
        // Interface check
        library.addProblem(
            templateInterfaceCheck.withArguments(
                declaredMember.name.name, cls.name),
            cls.fileOffset,
            cls.name.length,
            cls.fileUri,
            context: context);
      } else {
        if (cls.isAnonymousMixin) {
          // Implicit mixin application class
          String baseName = cls.superclass.demangledName;
          String mixinName = cls.mixedInClass.name;
          int classNameLength = cls.nameAsMixinApplicationSubclass.length;
          library.addProblem(
              templateImplicitMixinOverride.withArguments(
                  mixinName, baseName, declaredMember.name.name),
              cls.fileOffset,
              classNameLength,
              cls.fileUri,
              context: context);
        } else {
          // Named mixin application class
          library.addProblem(
              templateNamedMixinOverride.withArguments(
                  cls.name, declaredMember.name.name),
              cls.fileOffset,
              cls.name.length,
              cls.fileUri,
              context: context);
        }
      }
    }
  }

  @override
  String get fullNameForErrors {
    return isMixinApplication && !isNamedMixinApplication
        ? "${supertype.fullNameForErrors} with ${mixedInType.fullNameForErrors}"
        : name;
  }

  @override
  void checkMixinApplication(ClassHierarchy hierarchy) {
    // A mixin declaration can only be applied to a class that implements all
    // the declaration's superclass constraints.
    InterfaceType supertype = cls.supertype.asInterfaceType;
    Substitution substitution = Substitution.fromSupertype(cls.mixedInType);
    for (Supertype constraint in cls.mixedInClass.superclassConstraints()) {
      InterfaceType interface =
          substitution.substituteSupertype(constraint).asInterfaceType;
      if (hierarchy.getTypeAsInstanceOf(supertype, interface.classNode) !=
          interface) {
        library.addProblem(
            templateMixinApplicationIncompatibleSupertype.withArguments(
                supertype, interface, cls.mixedInType.asInterfaceType),
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
      if (retainDataForTesting) {
        patchForTesting = patch;
      }
      // TODO(ahe): Complain if `patch.supertype` isn't null.
      scope.local.forEach((String name, Builder member) {
        Builder memberPatch = patch.scope.local[name];
        if (memberPatch != null) {
          member.applyPatch(memberPatch);
        }
      });
      scope.setters.forEach((String name, Builder member) {
        Builder memberPatch = patch.scope.setters[name];
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
    } else if (redirectionTarget.target is DillMemberBuilder &&
        (redirectionTarget.target.isConstructor ||
            redirectionTarget.target.isFactory)) {
      DillMemberBuilder targetBuilder = redirectionTarget.target;
      // It seems that the [redirectionTarget.target] is an instance of
      // [DillMemberBuilder] whenever the redirectee is an implicit constructor,
      // e.g.
      //
      //   class A {
      //     factory A() = B;
      //   }
      //   class B implements A {}
      //
      target = targetBuilder.member.function;
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
    FunctionType targetFunctionType = target.functionType;
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
        if (!typeEnvironment.isSubtypeOf(typeArgument, typeParameterBound,
            SubtypeCheckMode.ignoringNullabilities)) {
          addProblem(
              templateRedirectingFactoryIncompatibleTypeArgument.withArguments(
                  typeArgument, typeParameterBound),
              redirectionTarget.charOffset,
              noLength);
          hasProblem = true;
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
    FunctionType factoryType =
        factory.procedure.function.thisFunctionType.withoutTypeParameters;
    FunctionType redirecteeType =
        computeRedirecteeType(factory, typeEnvironment);

    // TODO(hillerstrom): It would be preferable to know whether a failure
    // happened during [_computeRedirecteeType].
    if (redirecteeType == null) return;

    // Check whether [redirecteeType] <: [factoryType].
    if (!typeEnvironment.isSubtypeOf(
        redirecteeType, factoryType, SubtypeCheckMode.ignoringNullabilities)) {
      addProblem(
          templateIncompatibleRedirecteeFunctionType.withArguments(
              redirecteeType, factoryType),
          factory.redirectionTarget.charOffset,
          noLength);
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
        Object supertype = builder.supertype;
        if (supertype is NamedTypeBuilder) {
          Object builder = supertype.declaration;
          if (builder is ClassBuilder) return builder;
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
