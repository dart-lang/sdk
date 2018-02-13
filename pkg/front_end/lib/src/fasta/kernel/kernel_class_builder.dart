// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_class_builder;

import 'package:front_end/src/fasta/fasta_codes.dart';
import 'package:kernel/ast.dart'
    show
        Class,
        Constructor,
        DartType,
        Expression,
        Field,
        FunctionNode,
        InterfaceType,
        ListLiteral,
        Member,
        Name,
        Procedure,
        ProcedureKind,
        StaticGet,
        Supertype,
        TypeParameter,
        TypeParameterType,
        VariableDeclaration;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/type_algebra.dart' show Substitution;

import 'package:kernel/type_environment.dart' show TypeEnvironment;

import '../dill/dill_member_builder.dart' show DillMemberBuilder;

import '../fasta_codes.dart'
    show
        messagePatchClassOrigin,
        messagePatchClassTypeVariablesMismatch,
        messagePatchDeclarationMismatch,
        messagePatchDeclarationOrigin,
        templateOverriddenMethodCause,
        templateOverrideFewerNamedArguments,
        templateOverrideFewerPositionalArguments,
        templateOverrideMismatchNamedParameter,
        templateOverrideMoreRequiredArguments,
        templateOverrideTypeMismatchParameter,
        templateOverrideTypeMismatchReturnType,
        templateOverrideTypeVariablesMismatch,
        templateRedirectionTargetNotFound;

import '../problems.dart' show unexpected, unhandled, unimplemented;

import 'kernel_builder.dart'
    show
        Builder,
        ClassBuilder,
        ConstructorReferenceBuilder,
        KernelLibraryBuilder,
        KernelProcedureBuilder,
        KernelTypeBuilder,
        KernelTypeVariableBuilder,
        LibraryBuilder,
        MemberBuilder,
        MetadataBuilder,
        ProcedureBuilder,
        Scope,
        TypeVariableBuilder,
        TypeBuilder,
        computeDefaultTypeArguments;

import 'redirecting_factory_body.dart' show RedirectingFactoryBody;

abstract class KernelClassBuilder
    extends ClassBuilder<KernelTypeBuilder, InterfaceType> {
  KernelClassBuilder actualOrigin;

  @override
  List<TypeBuilder> calculatedBounds;

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

  List<DartType> buildTypeArguments(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    List<DartType> typeArguments = <DartType>[];
    for (KernelTypeBuilder builder in arguments) {
      DartType type = builder.build(library);
      if (type == null) {
        unhandled("${builder.runtimeType}", "buildTypeArguments", -1, null);
      }
      typeArguments.add(type);
    }
    return computeDefaultTypeArguments(
        library, cls.typeParameters, typeArguments);
  }

  InterfaceType buildType(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    arguments ??= calculatedBounds;
    List<DartType> typeArguments;
    if (arguments != null) {
      typeArguments = buildTypeArguments(library, arguments);
    }
    return buildTypesWithBuiltArguments(library, typeArguments);
  }

  Supertype buildSupertype(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    Class cls = isPatch ? origin.target : this.cls;
    arguments ??= calculatedBounds;
    if (arguments != null) {
      return new Supertype(cls, buildTypeArguments(library, arguments));
    } else {
      return cls.asRawSupertype;
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
        Builder builder = constructors[name];
        if (builder.parent != this) {
          unexpected(
              "$fileUri", "${builder.parent.fileUri}", charOffset, fileUri);
        }
        if (builder is KernelProcedureBuilder && builder.isFactory) {
          // Compute the immediate redirection target, not the effective.
          ConstructorReferenceBuilder redirectionTarget =
              builder.redirectionTarget;
          if (redirectionTarget != null) {
            Builder targetBuilder = redirectionTarget.target;
            addRedirectingConstructor(builder, library);
            if (targetBuilder is ProcedureBuilder) {
              builder.setRedirectingFactoryBody(targetBuilder.target);
            } else if (targetBuilder is DillMemberBuilder) {
              builder.setRedirectingFactoryBody(targetBuilder.member);
            } else {
              var message = templateRedirectionTargetNotFound
                  .withArguments(redirectionTarget.fullNameForErrors);
              if (builder.isConst) {
                addCompileTimeError(message, builder.charOffset);
              } else {
                addProblem(message, builder.charOffset);
              }
              // CoreTypes aren't computed yet, and this is the outline
              // phase. So we can't and shouldn't create a method body.
              builder.body = new RedirectingFactoryBody.unresolved(
                  redirectionTarget.fullNameForErrors);
            }
          }
        }
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

  void checkOverrides(
      ClassHierarchy hierarchy, TypeEnvironment typeEnvironment) {
    hierarchy.forEachOverridePair(cls,
        (Member declaredMember, Member interfaceMember, bool isSetter) {
      if (declaredMember is Constructor || interfaceMember is Constructor) {
        unimplemented("Constructor in override check.",
            declaredMember.fileOffset, fileUri);
      }
      if (declaredMember is Procedure && interfaceMember is Procedure) {
        if (declaredMember.kind == ProcedureKind.Method &&
            interfaceMember.kind == ProcedureKind.Method) {
          checkMethodOverride(
              hierarchy, typeEnvironment, declaredMember, interfaceMember);
        }
        if (declaredMember.kind == ProcedureKind.Getter &&
            interfaceMember.kind == ProcedureKind.Getter) {
          checkGetterOverride(
              hierarchy, typeEnvironment, declaredMember, interfaceMember);
        }
        if (declaredMember.kind == ProcedureKind.Setter &&
            interfaceMember.kind == ProcedureKind.Setter) {
          checkSetterOverride(
              hierarchy, typeEnvironment, declaredMember, interfaceMember);
        }
      }
      // TODO(ahe): Handle other cases: accessors, operators, and fields.
    });
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
      FunctionNode interfaceFunction) {
    Substitution interfaceSubstitution;
    if (interfaceMember.enclosingClass.typeParameters.isNotEmpty) {
      interfaceSubstitution = Substitution.fromSupertype(
          hierarchy.getClassAsInstanceOf(cls, interfaceMember.enclosingClass));
    }
    if (declaredFunction?.typeParameters?.length !=
        interfaceFunction?.typeParameters?.length) {
      addProblem(
          templateOverrideTypeVariablesMismatch.withArguments(
              "$name::${declaredMember.name.name}",
              "${interfaceMember.enclosingClass.name}::"
              "${interfaceMember.name.name}"),
          declaredMember.fileOffset,
          context: templateOverriddenMethodCause
              .withArguments(interfaceMember.name.name)
              .withLocation(
                  _getMemberUri(interfaceMember), interfaceMember.fileOffset));
    } else if (library.loader.target.backendTarget.strongMode &&
        declaredFunction?.typeParameters != null) {
      var substitution = <TypeParameter, DartType>{};
      for (int i = 0; i < declaredFunction.typeParameters.length; ++i) {
        var declaredParameter = declaredFunction.typeParameters[i];
        var interfaceParameter = interfaceFunction.typeParameters[i];
        substitution[interfaceParameter] =
            new TypeParameterType(declaredParameter);
      }
      var newSubstitution = Substitution.fromMap(substitution);
      interfaceSubstitution = interfaceSubstitution == null
          ? newSubstitution
          : Substitution.combine(interfaceSubstitution, newSubstitution);
    }
    return interfaceSubstitution;
  }

  bool _checkTypes(
      TypeEnvironment typeEnvironment,
      Substitution interfaceSubstitution,
      Member declaredMember,
      Member interfaceMember,
      DartType declaredType,
      DartType interfaceType,
      bool isCovariant,
      VariableDeclaration declaredParameter) {
    if (!library.loader.target.backendTarget.strongMode) return false;

    if (interfaceSubstitution != null) {
      interfaceType = interfaceSubstitution.substituteType(interfaceType);
    }

    bool inParameter = declaredParameter != null;
    DartType subtype = inParameter ? interfaceType : declaredType;
    DartType supertype = inParameter ? declaredType : interfaceType;

    if (typeEnvironment.isSubtypeOf(subtype, supertype)) {
      // No problem--the proper subtyping relation is satisfied.
    } else if (isCovariant && typeEnvironment.isSubtypeOf(supertype, subtype)) {
      // No problem--the overriding parameter is marked "covariant" and has
      // a type which is a subtype of the parameter it overrides.
    } else {
      // Report an error.
      var declaredMemberName = '$name::${declaredMember.name.name}';
      Message message;
      int fileOffset;
      if (declaredParameter == null) {
        message = templateOverrideTypeMismatchReturnType.withArguments(
            declaredMemberName, declaredType, interfaceType);
        fileOffset = declaredMember.fileOffset;
      } else {
        message = templateOverrideTypeMismatchParameter.withArguments(
            declaredParameter.name,
            declaredMemberName,
            declaredType,
            interfaceType);
        fileOffset = declaredParameter.fileOffset;
      }
      library.addCompileTimeError(message, fileOffset, fileUri,
          context: templateOverriddenMethodCause
              .withArguments(interfaceMember.name.name)
              .withLocation(
                  _getMemberUri(interfaceMember), interfaceMember.fileOffset));
      return true;
    }
    return false;
  }

  void checkMethodOverride(
      ClassHierarchy hierarchy,
      TypeEnvironment typeEnvironment,
      Procedure declaredMember,
      Procedure interfaceMember) {
    if (declaredMember.enclosingClass != cls) {
      // TODO(ahe): Include these checks as well, but the message needs to
      // explain that [declaredMember] is inherited.
      return;
    }
    assert(declaredMember.kind == ProcedureKind.Method);
    assert(interfaceMember.kind == ProcedureKind.Method);
    FunctionNode declaredFunction = declaredMember.function;
    FunctionNode interfaceFunction = interfaceMember.function;

    Substitution interfaceSubstitution = _computeInterfaceSubstitution(
        hierarchy,
        declaredMember,
        interfaceMember,
        declaredFunction,
        interfaceFunction);

    _checkTypes(
        typeEnvironment,
        interfaceSubstitution,
        declaredMember,
        interfaceMember,
        declaredFunction.returnType,
        interfaceFunction.returnType,
        false,
        null);
    if (declaredFunction.positionalParameters.length <
            interfaceFunction.requiredParameterCount ||
        declaredFunction.positionalParameters.length <
            interfaceFunction.positionalParameters.length) {
      addProblem(
          templateOverrideFewerPositionalArguments.withArguments(
              "$name::${declaredMember.name.name}",
              "${interfaceMember.enclosingClass.name}::"
              "${interfaceMember.name.name}"),
          declaredMember.fileOffset,
          context: templateOverriddenMethodCause
              .withArguments(interfaceMember.name.name)
              .withLocation(
                  interfaceMember.fileUri, interfaceMember.fileOffset));
    }
    if (interfaceFunction.requiredParameterCount <
        declaredFunction.requiredParameterCount) {
      addProblem(
          templateOverrideMoreRequiredArguments.withArguments(
              "$name::${declaredMember.name.name}",
              "${interfaceMember.enclosingClass.name}::"
              "${interfaceMember.name.name}"),
          declaredMember.fileOffset,
          context: templateOverriddenMethodCause
              .withArguments(interfaceMember.name.name)
              .withLocation(
                  interfaceMember.fileUri, interfaceMember.fileOffset));
    }
    for (int i = 0;
        i < declaredFunction.positionalParameters.length &&
            i < interfaceFunction.positionalParameters.length;
        i++) {
      var declaredParameter = declaredFunction.positionalParameters[i];
      _checkTypes(
          typeEnvironment,
          interfaceSubstitution,
          declaredMember,
          interfaceMember,
          declaredParameter.type,
          interfaceFunction.positionalParameters[i].type,
          declaredParameter.isCovariant,
          declaredParameter);
    }
    if (declaredFunction.namedParameters.isEmpty &&
        interfaceFunction.namedParameters.isEmpty) {
      return;
    }
    if (declaredFunction.namedParameters.length <
        interfaceFunction.namedParameters.length) {
      addProblem(
          templateOverrideFewerNamedArguments.withArguments(
              "$name::${declaredMember.name.name}",
              "${interfaceMember.enclosingClass.name}::"
              "${interfaceMember.name.name}"),
          declaredMember.fileOffset,
          context: templateOverriddenMethodCause
              .withArguments(interfaceMember.name.name)
              .withLocation(
                  interfaceMember.fileUri, interfaceMember.fileOffset));
    }
    Iterator<VariableDeclaration> declaredNamedParameters =
        declaredFunction.namedParameters.iterator;
    Iterator<VariableDeclaration> interfaceNamedParameters =
        interfaceFunction.namedParameters.iterator;
    outer:
    while (declaredNamedParameters.moveNext() &&
        interfaceNamedParameters.moveNext()) {
      while (declaredNamedParameters.current.name !=
          interfaceNamedParameters.current.name) {
        if (!declaredNamedParameters.moveNext()) {
          addProblem(
              templateOverrideMismatchNamedParameter.withArguments(
                  "$name::${declaredMember.name.name}",
                  interfaceNamedParameters.current.name,
                  "${interfaceMember.enclosingClass.name}::"
                  "${interfaceMember.name.name}"),
              declaredMember.fileOffset,
              context: templateOverriddenMethodCause
                  .withArguments(interfaceMember.name.name)
                  .withLocation(
                      interfaceMember.fileUri, interfaceMember.fileOffset));
          break outer;
        }
      }
      var declaredParameter = declaredNamedParameters.current;
      _checkTypes(
          typeEnvironment,
          interfaceSubstitution,
          declaredMember,
          interfaceMember,
          declaredParameter.type,
          interfaceNamedParameters.current.type,
          declaredParameter.isCovariant,
          declaredParameter);
    }
  }

  void checkGetterOverride(
      ClassHierarchy hierarchy,
      TypeEnvironment typeEnvironment,
      Procedure declaredMember,
      Procedure interfaceMember) {
    if (declaredMember.enclosingClass != cls) {
      // TODO(paulberry): Include these checks as well, but the message needs to
      // explain that [declaredMember] is inherited.
      return;
    }
    Substitution interfaceSubstitution = _computeInterfaceSubstitution(
        hierarchy, declaredMember, interfaceMember, null, null);
    var declaredType = declaredMember.getterType;
    var interfaceType = interfaceMember.getterType;
    _checkTypes(typeEnvironment, interfaceSubstitution, declaredMember,
        interfaceMember, declaredType, interfaceType, false, null);
  }

  void checkSetterOverride(
      ClassHierarchy hierarchy,
      TypeEnvironment typeEnvironment,
      Procedure declaredMember,
      Procedure interfaceMember) {
    if (declaredMember.enclosingClass != cls) {
      // TODO(paulberry): Include these checks as well, but the message needs to
      // explain that [declaredMember] is inherited.
      return;
    }
    Substitution interfaceSubstitution = _computeInterfaceSubstitution(
        hierarchy, declaredMember, interfaceMember, null, null);
    var declaredType = declaredMember.setterType;
    var interfaceType = interfaceMember.setterType;
    var declaredParameter = declaredMember.function.positionalParameters[0];
    bool isCovariant = declaredParameter.isCovariant;
    _checkTypes(
        typeEnvironment,
        interfaceSubstitution,
        declaredMember,
        interfaceMember,
        declaredType,
        interfaceType,
        isCovariant,
        declaredParameter);
  }

  String get fullNameForErrors {
    return isMixinApplication
        ? "${supertype.fullNameForErrors} with ${mixedInType.fullNameForErrors}"
        : name;
  }

  @override
  void applyPatch(Builder patch) {
    if (patch is KernelClassBuilder) {
      patch.actualOrigin = this;
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
        patch.addCompileTimeError(
            messagePatchClassTypeVariablesMismatch, patch.charOffset,
            context: messagePatchClassOrigin.withLocation(fileUri, charOffset));
      } else if (typeVariables != null) {
        int count = 0;
        for (KernelTypeVariableBuilder t in patch.typeVariables) {
          typeVariables[count++].applyPatch(t);
        }
      }
    } else {
      library.addCompileTimeError(
          messagePatchDeclarationMismatch, patch.charOffset, patch.fileUri,
          context:
              messagePatchDeclarationOrigin.withLocation(fileUri, charOffset));
    }
  }

  @override
  Builder findStaticBuilder(
      String name, int charOffset, Uri fileUri, LibraryBuilder accessingLibrary,
      {bool isSetter: false}) {
    Builder builder = super.findStaticBuilder(
        name, charOffset, fileUri, accessingLibrary,
        isSetter: isSetter);
    if (builder == null && isPatch) {
      return origin.findStaticBuilder(
          name, charOffset, fileUri, accessingLibrary,
          isSetter: isSetter);
    }
    return builder;
  }

  @override
  Builder findConstructorOrFactory(
      String name, int charOffset, Uri uri, LibraryBuilder accessingLibrary) {
    Builder builder =
        super.findConstructorOrFactory(name, charOffset, uri, accessingLibrary);
    if (builder == null && isPatch) {
      return origin.findConstructorOrFactory(
          name, charOffset, uri, accessingLibrary);
    }
    return builder;
  }
}
