// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_class_builder;

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

import 'package:kernel/type_algebra.dart' show Substitution, substitute;

import 'package:kernel/type_algebra.dart' as type_algebra
    show getSubstitutionMap;

import 'package:kernel/type_environment.dart' show TypeEnvironment;

import '../dill/dill_member_builder.dart' show DillMemberBuilder;

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
        templateIllegalMixinDueToConstructors,
        templateIllegalMixinDueToConstructorsCause,
        templateImplementsRepeated,
        templateImplementsSuperClass,
        templateImplicitMixinOverrideContext,
        templateIncompatibleRedirecteeFunctionType,
        templateIncorrectTypeArgument,
        templateIncorrectTypeArgumentInSupertype,
        templateIncorrectTypeArgumentInSupertypeInferred,
        templateInterfaceCheckContext,
        templateMixinApplicationIncompatibleSupertype,
        templateNamedMixinOverrideContext,
        templateOverriddenMethodCause,
        templateOverrideFewerNamedArguments,
        templateOverrideFewerPositionalArguments,
        templateOverrideMismatchNamedParameter,
        templateOverrideMoreRequiredArguments,
        templateOverrideTypeMismatchParameter,
        templateOverrideTypeMismatchReturnType,
        templateOverrideTypeVariablesMismatch,
        templateRedirectingFactoryIncompatibleTypeArgument,
        templateRedirectionTargetNotFound,
        templateTypeArgumentMismatch;

import '../names.dart' show noSuchMethodName;

import '../problems.dart' show unexpected, unhandled, unimplemented;

import '../scope.dart' show AmbiguousBuilder;

import '../type_inference/type_schema.dart' show UnknownType;

import 'kernel_builder.dart'
    show
        ClassBuilder,
        ConstructorReferenceBuilder,
        Declaration,
        KernelFunctionBuilder,
        KernelLibraryBuilder,
        KernelNamedTypeBuilder,
        KernelProcedureBuilder,
        KernelRedirectingFactoryBuilder,
        KernelTypeBuilder,
        KernelTypeVariableBuilder,
        LibraryBuilder,
        MemberBuilder,
        MetadataBuilder,
        ProcedureBuilder,
        Scope,
        TypeVariableBuilder;

import 'redirecting_factory_body.dart'
    show getRedirectingFactoryBody, RedirectingFactoryBody;

import 'kernel_target.dart' show KernelTarget;

abstract class KernelClassBuilder
    extends ClassBuilder<KernelTypeBuilder, InterfaceType> {
  KernelClassBuilder actualOrigin;

  KernelClassBuilder(
      List<MetadataBuilder> metadata,
      int modifiers,
      String name,
      List<TypeVariableBuilder> typeVariables,
      KernelTypeBuilder supertype,
      List<KernelTypeBuilder> interfaces,
      Scope scope,
      Scope constructors,
      LibraryBuilder parent,
      int charOffset)
      : super(metadata, modifiers, name, typeVariables, supertype, interfaces,
            scope, constructors, parent, charOffset);

  Class get cls;

  Class get target => cls;

  Class get actualCls;

  @override
  KernelClassBuilder get origin => actualOrigin ?? this;

  /// [arguments] have already been built.
  InterfaceType buildTypesWithBuiltArguments(
      LibraryBuilder library, List<DartType> arguments) {
    assert(arguments == null || cls.typeParameters.length == arguments.length);
    return arguments == null ? cls.rawType : new InterfaceType(cls, arguments);
  }

  @override
  int get typeVariablesCount => typeVariables?.length ?? 0;

  List<DartType> buildTypeArguments(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    if (arguments == null && typeVariables == null) {
      return <DartType>[];
    }

    if (arguments == null && typeVariables != null) {
      List<DartType> result =
          new List<DartType>.filled(typeVariables.length, null, growable: true);
      for (int i = 0; i < result.length; ++i) {
        result[i] = typeVariables[i].defaultType.build(library);
      }
      if (library is KernelLibraryBuilder) {
        library.inferredTypes.addAll(result);
      }
      return result;
    }

    if (arguments != null && arguments.length != (typeVariables?.length ?? 0)) {
      // That should be caught and reported as a compile-time error earlier.
      return unhandled(
          templateTypeArgumentMismatch
              .withArguments(typeVariables.length)
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

  /// If [arguments] are null, the default types for the variables are used.
  InterfaceType buildType(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    return buildTypesWithBuiltArguments(
        library, buildTypeArguments(library, arguments));
  }

  Supertype buildSupertype(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    Class cls = isPatch ? origin.target : this.cls;
    return new Supertype(cls, buildTypeArguments(library, arguments));
  }

  Supertype buildMixedInType(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    Class cls = isPatch ? origin.target : this.cls;
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

  void checkSupertypes(CoreTypes coreTypes) {
    // This method determines whether the class (that's being built) its super
    // class appears both in 'extends' and 'implements' clauses and whether any
    // interface appears multiple times in the 'implements' clause.
    if (interfaces == null) return;

    // Extract super class (if it exists).
    ClassBuilder superClass;
    KernelTypeBuilder superClassType = supertype;
    if (superClassType is KernelNamedTypeBuilder) {
      Declaration decl = superClassType.declaration;
      if (decl is ClassBuilder) {
        superClass = decl;
      }
    }

    // Validate interfaces.
    Map<ClassBuilder, int> problems;
    Map<ClassBuilder, int> problemsOffsets;
    Set<ClassBuilder> implemented = new Set<ClassBuilder>();
    for (KernelTypeBuilder type in interfaces) {
      if (type is KernelNamedTypeBuilder) {
        int charOffset = -1; // TODO(ahe): Get offset from type.
        Declaration decl = type.declaration;
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
          } else if (interface.target == coreTypes.futureOrClass) {
            addProblem(messageImplementsFutureOr, charOffset,
                interface.target.name.length);
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

  void checkBoundsInSupertype(
      Supertype supertype, TypeEnvironment typeEnvironment) {
    KernelLibraryBuilder library = this.library;

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

        library.reportTypeArgumentIssue(message, charOffset, typeParameter);
      }
    }
  }

  void checkBoundsInOutline(TypeEnvironment typeEnvironment) {
    KernelLibraryBuilder library = this.library;

    // Check in bounds of own type variables.
    for (TypeParameter parameter in cls.typeParameters) {
      List<TypeArgumentIssue> issues = findTypeArgumentIssues(
          parameter.bound, typeEnvironment,
          allowSuperBounded: false);
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
              message, parameter.fileOffset, typeParameter);
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
      library.checkBoundsInFunctionNode(procedure.function, typeEnvironment);
    }
    for (Constructor constructor in cls.constructors) {
      library.checkBoundsInFunctionNode(constructor.function, typeEnvironment);
    }
    for (RedirectingFactoryConstructor redirecting
        in cls.redirectingFactoryConstructors) {
      library.checkBoundsInFunctionNodeParts(
          typeEnvironment, redirecting.fileOffset,
          typeParameters: redirecting.typeParameters,
          positionalParameters: redirecting.positionalParameters,
          namedParameters: redirecting.namedParameters);
    }
  }

  @override
  int resolveConstructors(LibraryBuilder library) {
    int count = super.resolveConstructors(library);
    if (count != 0) {
      Map<String, MemberBuilder> constructors = this.constructors.local;
      // Copy keys to avoid concurrent modification error.
      List<String> names = constructors.keys.toList();
      for (String name in names) {
        Declaration declaration = constructors[name];
        do {
          if (declaration.parent != this) {
            unexpected("$fileUri", "${declaration.parent.fileUri}", charOffset,
                fileUri);
          }
          if (declaration is KernelRedirectingFactoryBuilder) {
            // Compute the immediate redirection target, not the effective.
            ConstructorReferenceBuilder redirectionTarget =
                declaration.redirectionTarget;
            if (redirectionTarget != null) {
              Declaration targetBuilder = redirectionTarget.target;
              if (declaration.next == null) {
                // Only the first one (that is, the last on in the linked list)
                // is actually in the kernel tree. This call creates a StaticGet
                // to [declaration.target] in a field `_redirecting#` which is
                // only legal to do to things in the kernel tree.
                addRedirectingConstructor(declaration, library);
              }
              if (targetBuilder is ProcedureBuilder) {
                List<DartType> typeArguments = declaration.typeArguments;
                if (typeArguments == null) {
                  // TODO(32049) If type arguments aren't specified, they should
                  // be inferred.  Currently, the inference is not performed.
                  // The code below is a workaround.
                  typeArguments = new List<DartType>.filled(
                      targetBuilder.target.enclosingClass.typeParameters.length,
                      const DynamicType(),
                      growable: true);
                }
                declaration.setRedirectingFactoryBody(
                    targetBuilder.target, typeArguments);
              } else if (targetBuilder is DillMemberBuilder) {
                List<DartType> typeArguments = declaration.typeArguments;
                if (typeArguments == null) {
                  // TODO(32049) If type arguments aren't specified, they should
                  // be inferred.  Currently, the inference is not performed.
                  // The code below is a workaround.
                  typeArguments = new List<DartType>.filled(
                      targetBuilder.target.enclosingClass.typeParameters.length,
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

  void addRedirectingConstructor(
      KernelProcedureBuilder constructor, KernelLibraryBuilder library) {
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
    Field field = constructorsField.target;
    ListLiteral literal = field.initializer;
    literal.expressions
        .add(new StaticGet(constructor.target)..parent = literal);
  }

  void handleSeenCovariant(
      ClassHierarchy hierarchy,
      Member declaredMember,
      Member interfaceMember,
      bool isSetter,
      callback(Member declaredMember, Member interfaceMember, bool isSetter)) {
    // When a parameter is covariant we have to check that we also
    // override the same member in all parents.
    for (Supertype supertype in interfaceMember.enclosingClass.supers) {
      Member m = hierarchy.getInterfaceMember(
          supertype.classNode, interfaceMember.name,
          setter: isSetter);
      if (m != null) {
        callback(declaredMember, m, isSetter);
      }
    }
  }

  void checkOverride(
      ClassHierarchy hierarchy,
      TypeEnvironment typeEnvironment,
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
        bool seenCovariant = checkMethodOverride(hierarchy, typeEnvironment,
            declaredMember, interfaceMember, isInterfaceCheck);
        if (seenCovariant) {
          handleSeenCovariant(
              hierarchy, declaredMember, interfaceMember, isSetter, callback);
        }
      }
      if (declaredMember.kind == ProcedureKind.Getter &&
          interfaceMember.kind == ProcedureKind.Getter) {
        checkGetterOverride(hierarchy, typeEnvironment, declaredMember,
            interfaceMember, isInterfaceCheck);
      }
      if (declaredMember.kind == ProcedureKind.Setter &&
          interfaceMember.kind == ProcedureKind.Setter) {
        bool seenCovariant = checkSetterOverride(hierarchy, typeEnvironment,
            declaredMember, interfaceMember, isInterfaceCheck);
        if (seenCovariant) {
          handleSeenCovariant(
              hierarchy, declaredMember, interfaceMember, isSetter, callback);
        }
      }
    } else {
      bool declaredMemberHasGetter = declaredMember is Field ||
          declaredMember is Procedure && declaredMember.isGetter;
      bool interfaceMemberHasGetter = interfaceMember is Field ||
          interfaceMember is Procedure && interfaceMember.isGetter;
      bool declaredMemberHasSetter = declaredMember is Field ||
          declaredMember is Procedure && declaredMember.isSetter;
      bool interfaceMemberHasSetter = interfaceMember is Field ||
          interfaceMember is Procedure && interfaceMember.isSetter;
      if (declaredMemberHasGetter && interfaceMemberHasGetter) {
        checkGetterOverride(hierarchy, typeEnvironment, declaredMember,
            interfaceMember, isInterfaceCheck);
      } else if (declaredMemberHasSetter && interfaceMemberHasSetter) {
        bool seenCovariant = checkSetterOverride(hierarchy, typeEnvironment,
            declaredMember, interfaceMember, isInterfaceCheck);
        if (seenCovariant) {
          handleSeenCovariant(
              hierarchy, declaredMember, interfaceMember, isSetter, callback);
        }
      }
    }
    // TODO(ahe): Handle other cases: accessors, operators, and fields.
  }

  void checkOverrides(
      ClassHierarchy hierarchy, TypeEnvironment typeEnvironment) {
    void overridePairCallback(
        Member declaredMember, Member interfaceMember, bool isSetter) {
      checkOverride(hierarchy, typeEnvironment, declaredMember, interfaceMember,
          isSetter, overridePairCallback);
    }

    hierarchy.forEachOverridePair(cls, overridePairCallback);
  }

  void checkAbstractMembers(CoreTypes coreTypes, ClassHierarchy hierarchy,
      TypeEnvironment typeEnvironment) {
    // TODO(ahe): Move this to [ClassHierarchyBuilder].
    if (isAbstract) {
      // Unimplemented members allowed
      return;
    }

    bool mustHaveImplementation(Member member) {
      // Public member
      if (!member.name.isPrivate) return true;
      // Private member in different library
      if (member.enclosingLibrary != cls.enclosingLibrary) return false;
      // Private member in patch
      if (member.fileUri != member.enclosingClass.fileUri) return false;
      // Private member in same library
      return true;
    }

    void overridePairCallback(
        Member declaredMember, Member interfaceMember, bool isSetter) {
      checkOverride(hierarchy, typeEnvironment, declaredMember, interfaceMember,
          isSetter, overridePairCallback,
          isInterfaceCheck: true);
    }

    void findMissingImplementations({bool setters}) {
      List<Member> dispatchTargets =
          hierarchy.getDispatchTargets(cls, setters: setters);
      int targetIndex = 0;
      for (Member interfaceMember
          in hierarchy.getInterfaceMembers(cls, setters: setters)) {
        if (mustHaveImplementation(interfaceMember)) {
          while (targetIndex < dispatchTargets.length &&
              ClassHierarchy.compareMembers(
                      dispatchTargets[targetIndex], interfaceMember) <
                  0) {
            targetIndex++;
          }
          bool foundTarget = targetIndex < dispatchTargets.length &&
              ClassHierarchy.compareMembers(
                      dispatchTargets[targetIndex], interfaceMember) <=
                  0;
          if (foundTarget) {
            Member dispatchTarget = dispatchTargets[targetIndex];
            while (dispatchTarget is Procedure &&
                !dispatchTarget.isExternal &&
                dispatchTarget.forwardingStubSuperTarget != null) {
              dispatchTarget =
                  (dispatchTarget as Procedure).forwardingStubSuperTarget;
            }
            while (interfaceMember is Procedure &&
                !interfaceMember.isExternal &&
                interfaceMember.forwardingStubInterfaceTarget != null) {
              interfaceMember =
                  (interfaceMember as Procedure).forwardingStubInterfaceTarget;
            }
            if (!hierarchy.isSubtypeOf(dispatchTarget.enclosingClass,
                interfaceMember.enclosingClass)) {
              overridePairCallback(dispatchTarget, interfaceMember, setters);
            }
          }
        }
      }
    }

    findMissingImplementations(setters: false);
    findMissingImplementations(setters: true);
  }

  bool hasUserDefinedNoSuchMethod(
      Class klass, ClassHierarchy hierarchy, Class objectClass) {
    Member noSuchMethod = hierarchy.getDispatchTarget(klass, noSuchMethodName);
    return noSuchMethod != null && noSuchMethod.enclosingClass != objectClass;
  }

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

    KernelLibraryBuilder library = this.library;
    library.forwardersOrigins.add(cloned);
    library.forwardersOrigins.add(procedure);
  }

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

  /// Adds noSuchMethod forwarding stubs to this class. Returns `true` if the
  /// class was modified.
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
      ClassHierarchy hierarchy,
      Member declaredMember,
      Member interfaceMember,
      FunctionNode declaredFunction,
      FunctionNode interfaceFunction,
      bool isInterfaceCheck) {
    Substitution interfaceSubstitution = Substitution.empty;
    if (interfaceMember.enclosingClass.typeParameters.isNotEmpty) {
      interfaceSubstitution = Substitution.fromSupertype(
          hierarchy.getClassAsInstanceOf(cls, interfaceMember.enclosingClass));
    }
    if (declaredFunction?.typeParameters?.length !=
        interfaceFunction?.typeParameters?.length) {
      library.addProblem(
          templateOverrideTypeVariablesMismatch.withArguments(
              "${declaredMember.enclosingClass.name}."
              "${declaredMember.name.name}",
              "${interfaceMember.enclosingClass.name}."
              "${interfaceMember.name.name}"),
          declaredMember.fileOffset,
          noLength,
          declaredMember.fileUri,
          context: [
                templateOverriddenMethodCause
                    .withArguments(interfaceMember.name.name)
                    .withLocation(_getMemberUri(interfaceMember),
                        interfaceMember.fileOffset, noLength)
              ] +
              inheritedContext(isInterfaceCheck, declaredMember));
    } else if (!library.loader.target.backendTarget.legacyMode &&
        declaredFunction?.typeParameters != null) {
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
            library.addProblem(
                templateOverrideTypeVariablesMismatch.withArguments(
                    "${declaredMember.enclosingClass.name}."
                    "${declaredMember.name.name}",
                    "${interfaceMember.enclosingClass.name}."
                    "${interfaceMember.name.name}"),
                declaredMember.fileOffset,
                noLength,
                declaredMember.fileUri,
                context: [
                      templateOverriddenMethodCause
                          .withArguments(interfaceMember.name.name)
                          .withLocation(_getMemberUri(interfaceMember),
                              interfaceMember.fileOffset, noLength)
                    ] +
                    inheritedContext(isInterfaceCheck, declaredMember));
          }
        }
      }
      interfaceSubstitution =
          Substitution.combine(interfaceSubstitution, substitution);
    }
    return interfaceSubstitution;
  }

  Substitution _computeDeclaredSubstitution(
      ClassHierarchy hierarchy, Member declaredMember) {
    Substitution declaredSubstitution = Substitution.empty;
    if (declaredMember.enclosingClass.typeParameters.isNotEmpty) {
      declaredSubstitution = Substitution.fromSupertype(
          hierarchy.getClassAsInstanceOf(cls, declaredMember.enclosingClass));
    }
    return declaredSubstitution;
  }

  bool _checkTypes(
      TypeEnvironment typeEnvironment,
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
    if (library.loader.target.backendTarget.legacyMode) return false;

    if (interfaceSubstitution != null) {
      interfaceType = interfaceSubstitution.substituteType(interfaceType);
    }
    if (declaredSubstitution != null) {
      declaredType = declaredSubstitution.substituteType(declaredType);
    }

    bool inParameter = declaredParameter != null || asIfDeclaredParameter;
    DartType subtype = inParameter ? interfaceType : declaredType;
    DartType supertype = inParameter ? declaredType : interfaceType;

    if (typeEnvironment.isSubtypeOf(subtype, supertype)) {
      // No problem--the proper subtyping relation is satisfied.
    } else if (isCovariant && typeEnvironment.isSubtypeOf(supertype, subtype)) {
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
        message = templateOverrideTypeMismatchReturnType.withArguments(
            declaredMemberName,
            declaredType,
            interfaceType,
            interfaceMemberName);
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
      library.addProblem(message, fileOffset, noLength, declaredMember.fileUri,
          context: [
                templateOverriddenMethodCause
                    .withArguments(interfaceMember.name.name)
                    .withLocation(_getMemberUri(interfaceMember),
                        interfaceMember.fileOffset, noLength)
              ] +
              inheritedContext(isInterfaceCheck, declaredMember));
      return true;
    }
    return false;
  }

  /// Returns whether a covariant parameter was seen and more methods thus have
  /// to be checked.
  bool checkMethodOverride(
      ClassHierarchy hierarchy,
      TypeEnvironment typeEnvironment,
      Procedure declaredMember,
      Procedure interfaceMember,
      bool isInterfaceCheck) {
    assert(declaredMember.kind == ProcedureKind.Method);
    assert(interfaceMember.kind == ProcedureKind.Method);
    bool seenCovariant = false;
    FunctionNode declaredFunction = declaredMember.function;
    FunctionNode interfaceFunction = interfaceMember.function;

    Substitution interfaceSubstitution = _computeInterfaceSubstitution(
        hierarchy,
        declaredMember,
        interfaceMember,
        declaredFunction,
        interfaceFunction,
        isInterfaceCheck);

    Substitution declaredSubstitution =
        _computeDeclaredSubstitution(hierarchy, declaredMember);

    _checkTypes(
        typeEnvironment,
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
      library.addProblem(
          templateOverrideFewerPositionalArguments.withArguments(
              "${declaredMember.enclosingClass.name}."
              "${declaredMember.name.name}",
              "${interfaceMember.enclosingClass.name}."
              "${interfaceMember.name.name}"),
          declaredMember.fileOffset,
          noLength,
          declaredMember.fileUri,
          context: [
                templateOverriddenMethodCause
                    .withArguments(interfaceMember.name.name)
                    .withLocation(interfaceMember.fileUri,
                        interfaceMember.fileOffset, noLength)
              ] +
              inheritedContext(isInterfaceCheck, declaredMember));
    }
    if (interfaceFunction.requiredParameterCount <
        declaredFunction.requiredParameterCount) {
      library.addProblem(
          templateOverrideMoreRequiredArguments.withArguments(
              "${declaredMember.enclosingClass.name}."
              "${declaredMember.name.name}",
              "${interfaceMember.enclosingClass.name}."
              "${interfaceMember.name.name}"),
          declaredMember.fileOffset,
          noLength,
          declaredMember.fileUri,
          context: [
                templateOverriddenMethodCause
                    .withArguments(interfaceMember.name.name)
                    .withLocation(interfaceMember.fileUri,
                        interfaceMember.fileOffset, noLength)
              ] +
              inheritedContext(isInterfaceCheck, declaredMember));
    }
    for (int i = 0;
        i < declaredFunction.positionalParameters.length &&
            i < interfaceFunction.positionalParameters.length;
        i++) {
      var declaredParameter = declaredFunction.positionalParameters[i];
      var interfaceParameter = interfaceFunction.positionalParameters[i];
      _checkTypes(
          typeEnvironment,
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
      library.addProblem(
          templateOverrideFewerNamedArguments.withArguments(
              "${declaredMember.enclosingClass.name}."
              "${declaredMember.name.name}",
              "${interfaceMember.enclosingClass.name}."
              "${interfaceMember.name.name}"),
          declaredMember.fileOffset,
          noLength,
          declaredMember.fileUri,
          context: [
                templateOverriddenMethodCause
                    .withArguments(interfaceMember.name.name)
                    .withLocation(interfaceMember.fileUri,
                        interfaceMember.fileOffset, noLength)
              ] +
              inheritedContext(isInterfaceCheck, declaredMember));
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
          library.addProblem(
              templateOverrideMismatchNamedParameter.withArguments(
                  "${declaredMember.enclosingClass.name}."
                  "${declaredMember.name.name}",
                  interfaceNamedParameters.current.name,
                  "${interfaceMember.enclosingClass.name}."
                  "${interfaceMember.name.name}"),
              declaredMember.fileOffset,
              noLength,
              declaredMember.fileUri,
              context: [
                    templateOverriddenMethodCause
                        .withArguments(interfaceMember.name.name)
                        .withLocation(interfaceMember.fileUri,
                            interfaceMember.fileOffset, noLength)
                  ] +
                  inheritedContext(isInterfaceCheck, declaredMember));
          break outer;
        }
      }
      var declaredParameter = declaredNamedParameters.current;
      _checkTypes(
          typeEnvironment,
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

  void checkGetterOverride(
      ClassHierarchy hierarchy,
      TypeEnvironment typeEnvironment,
      Member declaredMember,
      Member interfaceMember,
      bool isInterfaceCheck) {
    Substitution interfaceSubstitution = _computeInterfaceSubstitution(
        hierarchy,
        declaredMember,
        interfaceMember,
        null,
        null,
        isInterfaceCheck);
    Substitution declaredSubstitution =
        _computeDeclaredSubstitution(hierarchy, declaredMember);
    var declaredType = declaredMember.getterType;
    var interfaceType = interfaceMember.getterType;
    _checkTypes(
        typeEnvironment,
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

  /// Returns whether a covariant parameter was seen and more methods thus have
  /// to be checked.
  bool checkSetterOverride(
      ClassHierarchy hierarchy,
      TypeEnvironment typeEnvironment,
      Member declaredMember,
      Member interfaceMember,
      bool isInterfaceCheck) {
    Substitution interfaceSubstitution = _computeInterfaceSubstitution(
        hierarchy,
        declaredMember,
        interfaceMember,
        null,
        null,
        isInterfaceCheck);
    Substitution declaredSubstitution =
        _computeDeclaredSubstitution(hierarchy, declaredMember);
    var declaredType = declaredMember.setterType;
    var interfaceType = interfaceMember.setterType;
    var declaredParameter =
        declaredMember.function?.positionalParameters?.elementAt(0);
    bool isCovariant = declaredParameter?.isCovariant ?? false;
    if (declaredMember is Field) isCovariant = declaredMember.isCovariant;
    _checkTypes(
        typeEnvironment,
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

  // Extra context on override messages when the overriding member is inherited
  List<LocatedMessage> inheritedContext(
      bool isInterfaceCheck, Member declaredMember) {
    if (declaredMember.enclosingClass == cls) {
      // Ordinary override
      return const [];
    }
    if (isInterfaceCheck) {
      // Interface check
      return [
        templateInterfaceCheckContext
            .withArguments(cls.name)
            .withLocation(cls.fileUri, cls.fileOffset, cls.name.length)
      ];
    } else {
      if (cls.isAnonymousMixin) {
        // Implicit mixin application class
        String baseName = cls.superclass.demangledName;
        String mixinName = cls.mixedInClass.name;
        int classNameLength = cls.nameAsMixinApplicationSubclass.length;
        return [
          templateImplicitMixinOverrideContext
              .withArguments(mixinName, baseName)
              .withLocation(cls.fileUri, cls.fileOffset, classNameLength)
        ];
      } else {
        // Named mixin application class
        return [
          templateNamedMixinOverrideContext
              .withArguments(cls.name)
              .withLocation(cls.fileUri, cls.fileOffset, cls.name.length)
        ];
      }
    }
  }

  String get fullNameForErrors {
    return isMixinApplication && !isNamedMixinApplication
        ? "${supertype.fullNameForErrors} with ${mixedInType.fullNameForErrors}"
        : name;
  }

  void checkMixinDeclaration() {
    assert(cls.isMixinDeclaration);
    for (Declaration constructory in constructors.local.values) {
      if (!constructory.isSynthetic &&
          (constructory.isFactory || constructory.isConstructor)) {
        addProblem(
            templateIllegalMixinDueToConstructors
                .withArguments(fullNameForErrors),
            charOffset,
            noLength,
            context: [
              templateIllegalMixinDueToConstructorsCause
                  .withArguments(fullNameForErrors)
                  .withLocation(
                      constructory.fileUri, constructory.charOffset, noLength)
            ]);
      }
    }
  }

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
  void applyPatch(Declaration patch) {
    if (patch is KernelClassBuilder) {
      patch.actualOrigin = this;
      // TODO(ahe): Complain if `patch.supertype` isn't null.
      scope.local.forEach((String name, Declaration member) {
        Declaration memberPatch = patch.scope.local[name];
        if (memberPatch != null) {
          member.applyPatch(memberPatch);
        }
      });
      scope.setters.forEach((String name, Declaration member) {
        Declaration memberPatch = patch.scope.setters[name];
        if (memberPatch != null) {
          member.applyPatch(memberPatch);
        }
      });
      constructors.local.forEach((String name, Declaration member) {
        Declaration memberPatch = patch.constructors.local[name];
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
        for (KernelTypeVariableBuilder t in patch.typeVariables) {
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
  Declaration findStaticBuilder(
      String name, int charOffset, Uri fileUri, LibraryBuilder accessingLibrary,
      {bool isSetter: false}) {
    Declaration declaration = super.findStaticBuilder(
        name, charOffset, fileUri, accessingLibrary,
        isSetter: isSetter);
    if (declaration == null && isPatch) {
      return origin.findStaticBuilder(
          name, charOffset, fileUri, accessingLibrary,
          isSetter: isSetter);
    }
    return declaration;
  }

  @override
  Declaration findConstructorOrFactory(
      String name, int charOffset, Uri uri, LibraryBuilder accessingLibrary) {
    Declaration declaration =
        super.findConstructorOrFactory(name, charOffset, uri, accessingLibrary);
    if (declaration == null && isPatch) {
      return origin.findConstructorOrFactory(
          name, charOffset, uri, accessingLibrary);
    }
    return declaration;
  }

  // Computes the function type of a given redirection target. Returns [null] if
  // the type of the target could not be computed.
  FunctionType computeRedirecteeType(KernelRedirectingFactoryBuilder factory,
      TypeEnvironment typeEnvironment) {
    ConstructorReferenceBuilder redirectionTarget = factory.redirectionTarget;
    FunctionNode target;
    if (redirectionTarget.target == null) return null;
    if (redirectionTarget.target is KernelFunctionBuilder) {
      KernelFunctionBuilder targetBuilder = redirectionTarget.target;
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
        getRedirectingFactoryBody(factory.target).typeArguments;
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
        // Check whether the [typeArgument] respects the bounds of [typeParameter].
        if (!typeEnvironment.isSubtypeOf(typeArgument, typeParameterBound)) {
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

  String computeRedirecteeName(ConstructorReferenceBuilder redirectionTarget) {
    String targetName = redirectionTarget.fullNameForErrors;
    if (targetName == "") {
      return redirectionTarget.target.parent.fullNameForErrors;
    } else {
      return targetName;
    }
  }

  void checkRedirectingFactory(KernelRedirectingFactoryBuilder factory,
      TypeEnvironment typeEnvironment) {
    // The factory type cannot contain any type parameters other than those of
    // its enclosing class, because constructors cannot specify type parameters
    // of their own.
    FunctionType factoryType =
        factory.procedure.function.functionType.withoutTypeParameters;
    FunctionType redirecteeType =
        computeRedirecteeType(factory, typeEnvironment);

    // TODO(hillerstrom): It would be preferable to know whether a failure
    // happened during [_computeRedirecteeType].
    if (redirecteeType == null) return;

    // Check whether [redirecteeType] <: [factoryType].
    if (!typeEnvironment.isSubtypeOf(redirecteeType, factoryType)) {
      addProblem(
          templateIncompatibleRedirecteeFunctionType.withArguments(
              redirecteeType, factoryType),
          factory.redirectionTarget.charOffset,
          noLength);
    }
  }

  void checkRedirectingFactories(TypeEnvironment typeEnvironment) {
    Map<String, MemberBuilder> constructors = this.constructors.local;
    Iterable<String> names = constructors.keys;
    for (String name in names) {
      Declaration constructor = constructors[name];
      do {
        if (constructor is KernelRedirectingFactoryBuilder) {
          checkRedirectingFactory(constructor, typeEnvironment);
        }
        constructor = constructor.next;
      } while (constructor != null);
    }
  }

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
  Map<TypeParameter, DartType> getSubstitutionMap(Class superclass) {
    Supertype supertype = target.supertype;
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
}
