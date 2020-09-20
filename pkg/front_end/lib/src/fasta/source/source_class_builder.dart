// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_class_builder;

import 'package:kernel/ast.dart' hide MapEntry;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/clone.dart' show CloneProcedureWithoutBody;
import 'package:kernel/reference_from_index.dart' show IndexedClass;
import 'package:kernel/src/bounds_checks.dart';
import 'package:kernel/src/legacy_erasure.dart';
import 'package:kernel/src/types.dart' show Types;
import 'package:kernel/type_algebra.dart' show Substitution;
import 'package:kernel/type_algebra.dart' as type_algebra
    show getSubstitutionMap;
import 'package:kernel/type_environment.dart';

import '../builder/builder.dart';
import '../builder/class_builder.dart';
import '../builder/constructor_builder.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/field_builder.dart';
import '../builder/function_builder.dart';
import '../builder/invalid_type_declaration_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/procedure_builder.dart';
import '../builder/type_alias_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_declaration_builder.dart';
import '../builder/type_variable_builder.dart';

import '../dill/dill_member_builder.dart' show DillMemberBuilder;

import '../fasta_codes.dart';

import '../kernel/kernel_builder.dart' show compareProcedures;
import '../kernel/kernel_target.dart' show KernelTarget;
import '../kernel/redirecting_factory_body.dart' show RedirectingFactoryBody;
import '../kernel/redirecting_factory_body.dart' show redirectingName;
import '../kernel/type_algorithms.dart'
    show Variance, computeTypeVariableBuilderVariance;

import '../names.dart' show equalsName, noSuchMethodName;

import '../problems.dart' show unexpected, unhandled, unimplemented;

import '../scope.dart';

import '../type_inference/type_schema.dart';

import 'source_library_builder.dart' show SourceLibraryBuilder;

Class initializeClass(
    Class cls,
    List<TypeVariableBuilder> typeVariables,
    String name,
    SourceLibraryBuilder parent,
    int startCharOffset,
    int charOffset,
    int charEndOffset,
    Class referencesFrom) {
  cls ??= new Class(
      name: name,
      typeParameters:
          TypeVariableBuilder.typeParametersFromBuilders(typeVariables),
      reference: referencesFrom?.reference);
  cls.fileUri ??= parent.fileUri;
  if (cls.startFileOffset == TreeNode.noOffset) {
    cls.startFileOffset = startCharOffset;
  }
  if (cls.fileOffset == TreeNode.noOffset) {
    cls.fileOffset = charOffset;
  }
  if (cls.fileEndOffset == TreeNode.noOffset) {
    cls.fileEndOffset = charEndOffset;
  }

  return cls;
}

class SourceClassBuilder extends ClassBuilderImpl
    implements Comparable<SourceClassBuilder> {
  @override
  final Class actualCls;

  final List<ConstructorReferenceBuilder> constructorReferences;

  TypeBuilder mixedInTypeBuilder;

  bool isMixinDeclaration;

  final Class referencesFrom;
  final IndexedClass referencesFromIndexed;

  SourceClassBuilder(
    List<MetadataBuilder> metadata,
    int modifiers,
    String name,
    List<TypeVariableBuilder> typeVariables,
    TypeBuilder supertype,
    List<TypeBuilder> interfaces,
    List<TypeBuilder> onTypes,
    Scope scope,
    ConstructorScope constructors,
    LibraryBuilder parent,
    this.constructorReferences,
    int startCharOffset,
    int nameOffset,
    int charEndOffset,
    Class referencesFrom,
    IndexedClass referencesFromIndexed, {
    Class cls,
    this.mixedInTypeBuilder,
    this.isMixinDeclaration = false,
  })  : actualCls = initializeClass(cls, typeVariables, name, parent,
            startCharOffset, nameOffset, charEndOffset, referencesFrom),
        referencesFrom = referencesFrom,
        referencesFromIndexed = referencesFromIndexed,
        super(metadata, modifiers, name, typeVariables, supertype, interfaces,
            onTypes, scope, constructors, parent, nameOffset) {
    actualCls.hasConstConstructor = declaresConstConstructor;
  }

  @override
  Class get cls => origin.actualCls;

  @override
  SourceLibraryBuilder get library => super.library;

  Class build(SourceLibraryBuilder library, LibraryBuilder coreLibrary) {
    void buildBuilders(String name, Builder declaration) {
      do {
        if (declaration.parent != this) {
          if (fileUri != declaration.parent.fileUri) {
            unexpected("$fileUri", "${declaration.parent.fileUri}", charOffset,
                fileUri);
          } else {
            unexpected(fullNameForErrors, declaration.parent?.fullNameForErrors,
                charOffset, fileUri);
          }
        } else if (declaration is MemberBuilderImpl) {
          MemberBuilderImpl memberBuilder = declaration;
          memberBuilder.buildMembers(library,
              (Member member, BuiltMemberKind memberKind) {
            member.parent = cls;
            if (!memberBuilder.isPatch && !memberBuilder.isDuplicate) {
              cls.addMember(member);
            }
          });
        } else {
          unhandled("${declaration.runtimeType}", "buildBuilders",
              declaration.charOffset, declaration.fileUri);
        }
        declaration = declaration.next;
      } while (declaration != null);
    }

    scope.forEach(buildBuilders);
    constructors.forEach(buildBuilders);
    supertypeBuilder = checkSupertype(supertypeBuilder);
    Supertype supertype =
        supertypeBuilder?.buildSupertype(library, charOffset, fileUri);
    if (supertype != null) {
      Class superclass = supertype.classNode;
      if (superclass.name == 'Function' &&
          superclass.enclosingLibrary == coreLibrary.library) {
        library.addProblem(
            messageExtendFunction, charOffset, noLength, fileUri);
        supertype = null;
        supertypeBuilder = null;
      }
    }
    if (!isMixinDeclaration &&
        actualCls.supertype != null &&
        actualCls.superclass.isMixinDeclaration) {
      // Declared mixins have interfaces that can be implemented, but they
      // cannot be extended.  However, a mixin declaration with a single
      // superclass constraint is encoded with the constraint as the supertype,
      // and that is allowed to be a mixin's interface.
      library.addProblem(
          templateSupertypeIsIllegal.withArguments(actualCls.superclass.name),
          charOffset,
          noLength,
          fileUri);
      supertype = null;
    }
    if (supertype == null && supertypeBuilder is! NamedTypeBuilder) {
      supertypeBuilder = null;
    }
    actualCls.supertype = supertype;

    mixedInTypeBuilder = checkSupertype(mixedInTypeBuilder);
    Supertype mixedInType =
        mixedInTypeBuilder?.buildMixedInType(library, charOffset, fileUri);
    if (mixedInType != null) {
      Class superclass = mixedInType.classNode;
      if (superclass.name == 'Function' &&
          superclass.enclosingLibrary == coreLibrary.library) {
        library.addProblem(messageMixinFunction, charOffset, noLength, fileUri);
        mixedInType = null;
        mixedInTypeBuilder = null;
        actualCls.isAnonymousMixin = false;
        isMixinDeclaration = false;
      }
    }
    if (mixedInType == null && mixedInTypeBuilder is! NamedTypeBuilder) {
      mixedInTypeBuilder = null;
    }
    actualCls.isMixinDeclaration = isMixinDeclaration;
    actualCls.mixedInType = mixedInType;

    // TODO(ahe): If `cls.supertype` is null, and this isn't Object, report a
    // compile-time error.
    cls.isAbstract = isAbstract;
    if (interfaceBuilders != null) {
      for (int i = 0; i < interfaceBuilders.length; ++i) {
        interfaceBuilders[i] = checkSupertype(interfaceBuilders[i]);
        Supertype supertype =
            interfaceBuilders[i].buildSupertype(library, charOffset, fileUri);
        if (supertype != null) {
          Class superclass = supertype.classNode;
          if (superclass.name == 'Function' &&
              superclass.enclosingLibrary == coreLibrary.library) {
            library.addProblem(
                messageImplementFunction, charOffset, noLength, fileUri);
            continue;
          }
          // TODO(ahe): Report an error if supertype is null.
          actualCls.implementedTypes.add(supertype);
        }
      }
    }

    constructors.forEach((String name, Builder constructor) {
      Builder member = scopeBuilder[name];
      if (member == null) return;
      if (!member.isStatic) return;
      // TODO(ahe): Revisit these messages. It seems like the last two should
      // be `context` parameter to this message.
      addProblem(templateConflictsWithMember.withArguments(name),
          constructor.charOffset, noLength);
      if (constructor.isFactory) {
        addProblem(
            templateConflictsWithFactory.withArguments("${this.name}.${name}"),
            member.charOffset,
            noLength);
      } else {
        addProblem(
            templateConflictsWithConstructor
                .withArguments("${this.name}.${name}"),
            member.charOffset,
            noLength);
      }
    });

    scope.forEachLocalSetter((String name, Builder setter) {
      Builder member = scopeBuilder[name];
      if (member == null ||
          !(member.isField && !member.isFinal && !member.isConst ||
              member.isRegularMethod && member.isStatic && setter.isStatic)) {
        return;
      }
      addProblem(templateConflictsWithMember.withArguments(name),
          setter.charOffset, noLength);
      // TODO(ahe): Context argument to previous message?
      addProblem(templateConflictsWithSetter.withArguments(name),
          member.charOffset, noLength);
    });

    scope.forEachLocalSetter((String name, Builder setter) {
      Builder constructor = constructorScopeBuilder[name];
      if (constructor == null || !setter.isStatic) return;
      addProblem(templateConflictsWithConstructor.withArguments(name),
          setter.charOffset, noLength);
      addProblem(templateConflictsWithSetter.withArguments(name),
          constructor.charOffset, noLength);
    });

    cls.procedures.sort(compareProcedures);
    return cls;
  }

  TypeBuilder checkSupertype(TypeBuilder supertype) {
    if (typeVariables == null || supertype == null) return supertype;
    Message message;
    for (int i = 0; i < typeVariables.length; ++i) {
      int variance = computeTypeVariableBuilderVariance(
          typeVariables[i], supertype, library);
      if (!Variance.greaterThanOrEqual(variance, typeVariables[i].variance)) {
        if (typeVariables[i].parameter.isLegacyCovariant) {
          message = templateInvalidTypeVariableInSupertype.withArguments(
              typeVariables[i].name,
              Variance.keywordString(variance),
              supertype.name);
        } else {
          message =
              templateInvalidTypeVariableInSupertypeWithVariance.withArguments(
                  Variance.keywordString(typeVariables[i].variance),
                  typeVariables[i].name,
                  Variance.keywordString(variance),
                  supertype.name);
        }
        library.addProblem(message, charOffset, noLength, fileUri);
      }
    }
    if (message != null) {
      return new NamedTypeBuilder(
          supertype.name,
          const NullabilityBuilder.omitted(),
          /* arguments = */ null,
          fileUri,
          charOffset)
        ..bind(new InvalidTypeDeclarationBuilder(supertype.name,
            message.withLocation(fileUri, charOffset, noLength)));
    }
    return supertype;
  }

  void checkVarianceInField(SourceFieldBuilder fieldBuilder,
      TypeEnvironment typeEnvironment, List<TypeParameter> typeParameters) {
    for (TypeParameter typeParameter in typeParameters) {
      int fieldVariance =
          computeVariance(typeParameter, fieldBuilder.fieldType);
      if (fieldBuilder.isClassInstanceMember) {
        reportVariancePositionIfInvalid(fieldVariance, typeParameter,
            fieldBuilder.fileUri, fieldBuilder.charOffset);
      }
      if (fieldBuilder.isClassInstanceMember &&
          fieldBuilder.isAssignable &&
          !fieldBuilder.isCovariant) {
        fieldVariance = Variance.combine(Variance.contravariant, fieldVariance);
        reportVariancePositionIfInvalid(fieldVariance, typeParameter,
            fieldBuilder.fileUri, fieldBuilder.charOffset);
      }
    }
  }

  void checkVarianceInFunction(Procedure procedure,
      TypeEnvironment typeEnvironment, List<TypeParameter> typeParameters) {
    List<TypeParameter> functionTypeParameters =
        procedure.function.typeParameters;
    List<VariableDeclaration> positionalParameters =
        procedure.function.positionalParameters;
    List<VariableDeclaration> namedParameters =
        procedure.function.namedParameters;
    DartType returnType = procedure.function.returnType;

    if (functionTypeParameters != null) {
      for (TypeParameter functionParameter in functionTypeParameters) {
        for (TypeParameter typeParameter in typeParameters) {
          int typeVariance = Variance.combine(Variance.invariant,
              computeVariance(typeParameter, functionParameter.bound));
          reportVariancePositionIfInvalid(typeVariance, typeParameter, fileUri,
              functionParameter.fileOffset);
        }
      }
    }
    if (positionalParameters != null) {
      for (VariableDeclaration formal in positionalParameters) {
        if (!formal.isCovariant) {
          for (TypeParameter typeParameter in typeParameters) {
            int formalVariance = Variance.combine(Variance.contravariant,
                computeVariance(typeParameter, formal.type));
            reportVariancePositionIfInvalid(
                formalVariance, typeParameter, fileUri, formal.fileOffset);
          }
        }
      }
    }
    if (namedParameters != null) {
      for (VariableDeclaration named in namedParameters) {
        for (TypeParameter typeParameter in typeParameters) {
          int namedVariance = Variance.combine(Variance.contravariant,
              computeVariance(typeParameter, named.type));
          reportVariancePositionIfInvalid(
              namedVariance, typeParameter, fileUri, named.fileOffset);
        }
      }
    }
    if (returnType != null) {
      for (TypeParameter typeParameter in typeParameters) {
        int returnTypeVariance = computeVariance(typeParameter, returnType);
        reportVariancePositionIfInvalid(returnTypeVariance, typeParameter,
            fileUri, procedure.function.fileOffset,
            isReturnType: true);
      }
    }
  }

  void reportVariancePositionIfInvalid(
      int variance, TypeParameter typeParameter, Uri fileUri, int fileOffset,
      {bool isReturnType: false}) {
    SourceLibraryBuilder library = this.library;
    if (!typeParameter.isLegacyCovariant &&
        !Variance.greaterThanOrEqual(variance, typeParameter.variance)) {
      Message message;
      if (isReturnType) {
        message = templateInvalidTypeVariableVariancePositionInReturnType
            .withArguments(Variance.keywordString(typeParameter.variance),
                typeParameter.name, Variance.keywordString(variance));
      } else {
        message = templateInvalidTypeVariableVariancePosition.withArguments(
            Variance.keywordString(typeParameter.variance),
            typeParameter.name,
            Variance.keywordString(variance));
      }
      library.reportTypeArgumentIssue(
          message, fileUri, fileOffset, typeParameter);
    }
  }

  void checkBoundsInSupertype(
      Supertype supertype, TypeEnvironment typeEnvironment) {
    SourceLibraryBuilder libraryBuilder = this.library;
    Library library = libraryBuilder.library;
    final DartType bottomType = library.isNonNullableByDefault
        ? const NeverType(Nullability.nonNullable)
        : typeEnvironment.nullType;

    Set<TypeArgumentIssue> issues = {};
    issues.addAll(findTypeArgumentIssues(
            library,
            new InterfaceType(supertype.classNode, library.nonNullable,
                supertype.typeArguments),
            typeEnvironment,
            SubtypeCheckMode.ignoringNullabilities,
            bottomType,
            allowSuperBounded: false) ??
        const []);
    if (library.isNonNullableByDefault) {
      issues.addAll(findTypeArgumentIssues(
              library,
              new InterfaceType(supertype.classNode, library.nonNullable,
                  supertype.typeArguments),
              typeEnvironment,
              SubtypeCheckMode.withNullabilities,
              bottomType,
              allowSuperBounded: false) ??
          const []);
    }
    for (TypeArgumentIssue issue in issues) {
      DartType argument = issue.argument;
      TypeParameter typeParameter = issue.typeParameter;
      bool inferred = libraryBuilder.inferredTypes.contains(argument);
      if (argument is FunctionType && argument.typeParameters.length > 0) {
        if (inferred) {
          libraryBuilder.reportTypeArgumentIssue(
              templateGenericFunctionTypeInferredAsActualTypeArgument
                  .withArguments(argument, library.isNonNullableByDefault),
              fileUri,
              charOffset,
              null);
        } else {
          libraryBuilder.reportTypeArgumentIssue(
              messageGenericFunctionTypeUsedAsActualTypeArgument,
              fileUri,
              charOffset,
              null);
        }
      } else {
        void reportProblem(
            Template<
                    Message Function(DartType, DartType, String, String, String,
                        String, bool)>
                template) {
          libraryBuilder.reportTypeArgumentIssue(
              template.withArguments(
                  argument,
                  typeParameter.bound,
                  typeParameter.name,
                  getGenericTypeName(issue.enclosingType),
                  supertype.classNode.name,
                  name,
                  library.isNonNullableByDefault),
              fileUri,
              charOffset,
              typeParameter);
        }

        if (inferred) {
          reportProblem(templateIncorrectTypeArgumentInSupertypeInferred);
        } else {
          reportProblem(templateIncorrectTypeArgumentInSupertype);
        }
      }
    }
  }

  void checkTypesInOutline(TypeEnvironment typeEnvironment) {
    SourceLibraryBuilder libraryBuilder = this.library;
    Library library = libraryBuilder.library;
    final DartType bottomType = library.isNonNullableByDefault
        ? const NeverType(Nullability.nonNullable)
        : typeEnvironment.nullType;

    // Check in bounds of own type variables.
    for (TypeParameter parameter in cls.typeParameters) {
      Set<TypeArgumentIssue> issues = {};
      issues.addAll(findTypeArgumentIssues(
              library,
              parameter.bound,
              typeEnvironment,
              SubtypeCheckMode.ignoringNullabilities,
              bottomType,
              allowSuperBounded: true) ??
          const []);
      if (library.isNonNullableByDefault) {
        issues.addAll(findTypeArgumentIssues(library, parameter.bound,
                typeEnvironment, SubtypeCheckMode.withNullabilities, bottomType,
                allowSuperBounded: true) ??
            const []);
      }
      for (TypeArgumentIssue issue in issues) {
        DartType argument = issue.argument;
        TypeParameter typeParameter = issue.typeParameter;
        if (libraryBuilder.inferredTypes.contains(argument)) {
          // Inference in type expressions in the supertypes boils down to
          // instantiate-to-bound which shouldn't produce anything that breaks
          // the bounds after the non-simplicity checks are done.  So, any
          // violation here is the result of non-simple bounds, and the error
          // is reported elsewhere.
          continue;
        }

        if (argument is FunctionType && argument.typeParameters.length > 0) {
          libraryBuilder.reportTypeArgumentIssue(
              messageGenericFunctionTypeUsedAsActualTypeArgument,
              fileUri,
              parameter.fileOffset,
              null);
        } else {
          libraryBuilder.reportTypeArgumentIssue(
              templateIncorrectTypeArgument.withArguments(
                  argument,
                  typeParameter.bound,
                  typeParameter.name,
                  getGenericTypeName(issue.enclosingType),
                  library.isNonNullableByDefault),
              fileUri,
              parameter.fileOffset,
              typeParameter);
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
    for (Procedure procedure in cls.procedures) {
      checkVarianceInFunction(procedure, typeEnvironment, cls.typeParameters);
      libraryBuilder.checkBoundsInFunctionNode(
          procedure.function, typeEnvironment, fileUri);
    }
    for (Constructor constructor in cls.constructors) {
      libraryBuilder.checkBoundsInFunctionNode(
          constructor.function, typeEnvironment, fileUri);
    }
    for (RedirectingFactoryConstructor redirecting
        in cls.redirectingFactoryConstructors) {
      libraryBuilder.checkBoundsInFunctionNodeParts(
          typeEnvironment, fileUri, redirecting.fileOffset,
          typeParameters: redirecting.typeParameters,
          positionalParameters: redirecting.positionalParameters,
          namedParameters: redirecting.namedParameters);
    }

    forEach((String name, Builder builder) {
      // Check fields.
      if (builder is SourceFieldBuilder) {
        checkVarianceInField(builder, typeEnvironment, cls.typeParameters);
        libraryBuilder.checkTypesInField(builder, typeEnvironment);
      }

      // Check initializers.
      if (builder is FunctionBuilder &&
          !(builder.isAbstract || builder.isExternal) &&
          builder.formals != null) {
        libraryBuilder.checkInitializersInFormals(
            builder.formals, typeEnvironment);
      }
    });

    constructors.local.forEach((String name, MemberBuilder builder) {
      if (builder is ConstructorBuilder) {
        if (!builder.isExternal && builder.formals != null) {
          libraryBuilder.checkInitializersInFormals(
              builder.formals, typeEnvironment);
        }
      } else if (builder is RedirectingFactoryBuilder) {
        // Default values are not required on redirecting factory constructors.
      } else if (builder is ProcedureBuilder) {
        assert(builder.isFactory, "Unexpected constructor $builder.");
        if (!builder.isExternal && builder.formals != null) {
          libraryBuilder.checkInitializersInFormals(
              builder.formals, typeEnvironment);
        }
      } else {
        assert(
            // This is a synthesized constructor.
            builder is DillMemberBuilder && builder.member is Constructor,
            "Unexpected constructor $builder.");
      }
    });
  }

  void addSyntheticConstructor(Constructor constructor) {
    String name = constructor.name.text;
    cls.constructors.add(constructor);
    constructor.parent = cls;
    DillMemberBuilder memberBuilder = new DillMemberBuilder(constructor, this);
    memberBuilder.next = constructorScopeBuilder[name];
    constructorScopeBuilder.addMember(name, memberBuilder);
    if (constructor.isConst) {
      cls.hasConstConstructor = true;
    }
  }

  @override
  int finishPatch() {
    if (!isPatch) return 0;

    // TODO(ahe): restore file-offset once we track both origin and patch file
    // URIs. See https://github.com/dart-lang/sdk/issues/31579
    cls.annotations.forEach((m) => m.fileOffset = origin.cls.fileOffset);

    int count = 0;
    scope.forEach((String name, Builder declaration) {
      count += declaration.finishPatch();
    });
    constructors.forEach((String name, Builder declaration) {
      count += declaration.finishPatch();
    });
    return count;
  }

  /// Return a map whose keys are the supertypes of this [SourceClassBuilder]
  /// after expansion of type aliases, if any. For each supertype key, the
  /// corresponding value is the type alias which was unaliased in order to
  /// find the supertype, or null if the supertype was not aliased.
  Map<TypeDeclarationBuilder, TypeAliasBuilder> computeDirectSupertypes(
      ClassBuilder objectClass) {
    final Map<TypeDeclarationBuilder, TypeAliasBuilder> result =
        <TypeDeclarationBuilder, TypeAliasBuilder>{};
    final TypeBuilder supertype = this.supertypeBuilder;
    if (supertype != null) {
      TypeDeclarationBuilder declarationBuilder = supertype.declaration;
      if (declarationBuilder is TypeAliasBuilder) {
        TypeAliasBuilder aliasBuilder = declarationBuilder;
        NamedTypeBuilder namedBuilder = supertype;
        declarationBuilder =
            aliasBuilder.unaliasDeclaration(namedBuilder.arguments);
        result[declarationBuilder] = aliasBuilder;
      } else {
        result[declarationBuilder] = null;
      }
    } else if (objectClass != this) {
      result[objectClass] = null;
    }
    final List<TypeBuilder> interfaces = this.interfaceBuilders;
    if (interfaces != null) {
      for (int i = 0; i < interfaces.length; i++) {
        TypeBuilder interface = interfaces[i];
        TypeDeclarationBuilder declarationBuilder = interface.declaration;
        if (declarationBuilder is TypeAliasBuilder) {
          TypeAliasBuilder aliasBuilder = declarationBuilder;
          NamedTypeBuilder namedBuilder = interface;
          declarationBuilder =
              aliasBuilder.unaliasDeclaration(namedBuilder.arguments);
          result[declarationBuilder] = aliasBuilder;
        } else {
          result[declarationBuilder] = null;
        }
      }
    }
    final TypeBuilder mixedInTypeBuilder = this.mixedInTypeBuilder;
    if (mixedInTypeBuilder != null) {
      TypeDeclarationBuilder declarationBuilder =
          mixedInTypeBuilder.declaration;
      if (declarationBuilder is TypeAliasBuilder) {
        TypeAliasBuilder aliasBuilder = declarationBuilder;
        NamedTypeBuilder namedBuilder = mixedInTypeBuilder;
        declarationBuilder =
            aliasBuilder.unaliasDeclaration(namedBuilder.arguments);
        result[declarationBuilder] = aliasBuilder;
      } else {
        result[declarationBuilder] = null;
      }
    }
    return result;
  }

  @override
  int compareTo(SourceClassBuilder other) {
    int result = "$fileUri".compareTo("${other.fileUri}");
    if (result != 0) return result;
    return charOffset.compareTo(other.charOffset);
  }

  void addNoSuchMethodForwarderForProcedure(Member noSuchMethod,
      KernelTarget target, Procedure procedure, ClassHierarchy hierarchy) {
    Procedure referenceFrom;
    if (referencesFromIndexed != null) {
      if (procedure.isSetter) {
        referenceFrom =
            referencesFromIndexed.lookupProcedureSetter(procedure.name.text);
      } else {
        referenceFrom =
            referencesFromIndexed.lookupProcedureNotSetter(procedure.name.text);
      }
    }

    CloneProcedureWithoutBody cloner = new CloneProcedureWithoutBody(
        typeSubstitution: type_algebra.getSubstitutionMap(
            hierarchy.getClassAsInstanceOf(cls, procedure.enclosingClass)),
        cloneAnnotations: false);
    Procedure cloned = cloner.cloneProcedure(procedure, referenceFrom)
      ..isExternal = false;
    transformProcedureToNoSuchMethodForwarder(noSuchMethod, target, cloned);
    cls.procedures.add(cloned);
    cloned.parent = cls;

    library.forwardersOrigins.add(cloned);
    library.forwardersOrigins.add(procedure);
  }

  void addNoSuchMethodForwarderGetterForField(
      Field field, Member noSuchMethod, KernelTarget target) {
    ClassHierarchy hierarchy = target.loader.hierarchy;
    Substitution substitution = Substitution.fromSupertype(
        hierarchy.getClassAsInstanceOf(cls, field.enclosingClass));

    Procedure referenceFrom;
    if (referencesFromIndexed != null) {
      referenceFrom =
          referencesFromIndexed.lookupProcedureNotSetter(field.name.text);
    }
    Procedure getter = new Procedure(
        field.name,
        ProcedureKind.Getter,
        new FunctionNode(null,
            typeParameters: <TypeParameter>[],
            positionalParameters: <VariableDeclaration>[],
            namedParameters: <VariableDeclaration>[],
            requiredParameterCount: 0,
            returnType: substitution.substituteType(field.type)),
        fileUri: field.fileUri,
        reference: referenceFrom?.reference)
      ..fileOffset = field.fileOffset
      ..isNonNullableByDefault = cls.enclosingLibrary.isNonNullableByDefault;
    transformProcedureToNoSuchMethodForwarder(noSuchMethod, target, getter);
    cls.procedures.add(getter);
    getter.parent = cls;
  }

  void addNoSuchMethodForwarderSetterForField(
      Field field, Member noSuchMethod, KernelTarget target) {
    ClassHierarchy hierarchy = target.loader.hierarchy;
    Substitution substitution = Substitution.fromSupertype(
        hierarchy.getClassAsInstanceOf(cls, field.enclosingClass));

    Procedure referenceFrom;
    if (referencesFromIndexed != null) {
      referenceFrom =
          referencesFromIndexed.lookupProcedureSetter(field.name.text);
    }

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
        fileUri: field.fileUri,
        reference: referenceFrom?.reference)
      ..fileOffset = field.fileOffset
      ..isNonNullableByDefault = cls.enclosingLibrary.isNonNullableByDefault;
    transformProcedureToNoSuchMethodForwarder(noSuchMethod, target, setter);
    cls.procedures.add(setter);
    setter.parent = cls;
  }

  bool _addMissingNoSuchMethodForwarders(
      KernelTarget target, Set<Member> existingForwarders,
      {bool forSetters}) {
    assert(forSetters != null);

    ClassHierarchy hierarchy = target.loader.hierarchy;
    TypeEnvironment typeEnvironment =
        target.loader.typeInferenceEngine.typeSchemaEnvironment;

    List<Member> allMembers =
        hierarchy.getInterfaceMembers(cls, setters: forSetters);
    List<Member> concreteMembers =
        hierarchy.getDispatchTargets(cls, setters: forSetters);
    List<Member> declaredMembers =
        hierarchy.getDeclaredMembers(cls, setters: forSetters);

    Member noSuchMethod = ClassHierarchy.findMemberByName(
        hierarchy.getInterfaceMembers(cls), noSuchMethodName);
    bool clsHasUserDefinedNoSuchMethod =
        hasUserDefinedNoSuchMethod(cls, hierarchy, target.objectClass);

    bool changed = false;

    // It's possible to have multiple abstract members with the same name -- as
    // long as there's one with function type that's a subtype of function types
    // of all other members.  Such member is called "best" in the code below.
    // Members with the same name are put into groups, and "best" is searched
    // for in each group.
    Map<Name, List<Member>> sameNameMembers = {};
    for (Member member in allMembers) {
      (sameNameMembers[member.name] ??= []).add(member);
    }
    for (Name name in sameNameMembers.keys) {
      List<Member> members = sameNameMembers[name];
      assert(members.isNotEmpty);
      List<DartType> memberTypes = [];

      // The most specific member has the type that is subtype of the types of
      // all other members.
      Member bestSoFar = members.first;
      DartType bestSoFarType =
          forSetters ? bestSoFar.setterType : bestSoFar.getterType;
      Supertype supertype =
          hierarchy.getClassAsInstanceOf(cls, bestSoFar.enclosingClass);
      assert(
          supertype != null,
          "No supertype of enclosing class ${bestSoFar.enclosingClass} for "
          "$bestSoFar found for $cls.");
      bestSoFarType =
          Substitution.fromSupertype(supertype).substituteType(bestSoFarType);
      for (int i = 1; i < members.length; ++i) {
        Member candidate = members[i];
        DartType candidateType =
            forSetters ? candidate.setterType : candidate.getterType;
        Supertype supertype =
            hierarchy.getClassAsInstanceOf(cls, candidate.enclosingClass);
        assert(
            supertype != null,
            "No supertype of enclosing class ${candidate.enclosingClass} for "
            "$candidate found for $cls.");
        Substitution substitution = Substitution.fromSupertype(supertype);
        candidateType = substitution.substituteType(candidateType);
        memberTypes.add(candidateType);
        bool isMoreSpecific = forSetters
            ? typeEnvironment.isSubtypeOf(bestSoFarType, candidateType,
                SubtypeCheckMode.withNullabilities)
            : typeEnvironment.isSubtypeOf(candidateType, bestSoFarType,
                SubtypeCheckMode.withNullabilities);
        if (isMoreSpecific) {
          bestSoFar = candidate;
          bestSoFarType = candidateType;
        }
      }
      // Since isSubtypeOf isn't a linear order on types, we need to check once
      // again that the found member is indeed the most specific one.
      bool isActuallyBestSoFar = true;
      for (DartType memberType in memberTypes) {
        bool isMoreSpecific = forSetters
            ? typeEnvironment.isSubtypeOf(
                memberType, bestSoFarType, SubtypeCheckMode.withNullabilities)
            : typeEnvironment.isSubtypeOf(
                bestSoFarType, memberType, SubtypeCheckMode.withNullabilities);
        if (!isMoreSpecific) {
          isActuallyBestSoFar = false;
          break;
        }
      }
      if (!isActuallyBestSoFar) {
        // It's a member conflict that is reported elsewhere.
      } else {
        Member member = bestSoFar;

        if (_isForwarderRequired(
                clsHasUserDefinedNoSuchMethod, member, cls, concreteMembers,
                isPatch: member.fileUri != member.enclosingClass.fileUri) &&
            !existingForwarders.contains(member)) {
          if (member is Procedure) {
            // If there's a declared member with such name, then it's abstract
            // -- transform it into a noSuchMethod forwarder.
            if (ClassHierarchy.findMemberByName(declaredMembers, member.name) !=
                null) {
              transformProcedureToNoSuchMethodForwarder(
                  noSuchMethod, target, member);
            } else {
              addNoSuchMethodForwarderForProcedure(
                  noSuchMethod, target, member, hierarchy);
            }
            changed = true;
          } else if (member is Field) {
            // Current class isn't abstract, so it can't have an abstract field
            // with the same name -- just insert the forwarder.
            if (forSetters) {
              addNoSuchMethodForwarderSetterForField(
                  member, noSuchMethod, target);
            } else {
              addNoSuchMethodForwarderGetterForField(
                  member, noSuchMethod, target);
            }
            changed = true;
          } else {
            return unhandled(
                "${member.runtimeType}",
                "addNoSuchMethodForwarders",
                cls.fileOffset,
                cls.enclosingLibrary.fileUri);
          }
        }
      }
    }

    return changed;
  }

  /// Adds noSuchMethod forwarding stubs to this class.
  ///
  /// Returns `true` if the class was modified.
  bool addNoSuchMethodForwarders(
      KernelTarget target, ClassHierarchy hierarchy) {
    // Don't install forwarders in superclasses.
    if (cls.isAbstract) return false;

    // Compute signatures of existing noSuchMethod forwarders in superclasses.
    Set<Member> existingForwarders = new Set<Member>.identity();
    Set<Member> existingSetterForwarders = new Set<Member>.identity();
    {
      Class nearestConcreteSuperclass = cls.superclass;
      while (nearestConcreteSuperclass != null &&
          nearestConcreteSuperclass.isAbstract) {
        nearestConcreteSuperclass = nearestConcreteSuperclass.superclass;
      }
      if (nearestConcreteSuperclass != null) {
        bool superHasUserDefinedNoSuchMethod = hasUserDefinedNoSuchMethod(
            nearestConcreteSuperclass, hierarchy, target.objectClass);
        {
          List<Member> concrete =
              hierarchy.getDispatchTargets(nearestConcreteSuperclass);
          for (Member member
              in hierarchy.getInterfaceMembers(nearestConcreteSuperclass)) {
            if (_isForwarderRequired(superHasUserDefinedNoSuchMethod, member,
                nearestConcreteSuperclass, concrete,
                isPatch: member.fileUri != member.enclosingClass.fileUri)) {
              existingForwarders.add(member);
            }
          }
        }

        {
          List<Member> concreteSetters = hierarchy
              .getDispatchTargets(nearestConcreteSuperclass, setters: true);
          for (Member member in hierarchy
              .getInterfaceMembers(nearestConcreteSuperclass, setters: true)) {
            if (_isForwarderRequired(superHasUserDefinedNoSuchMethod, member,
                nearestConcreteSuperclass, concreteSetters)) {
              existingSetterForwarders.add(member);
            }
          }
        }
      }
    }

    bool changed = false;

    // Install noSuchMethod forwarders for methods and getters.
    changed = _addMissingNoSuchMethodForwarders(target, existingForwarders,
            forSetters: false) ||
        changed;

    // Install noSuchMethod forwarders for setters.
    changed = _addMissingNoSuchMethodForwarders(
            target, existingSetterForwarders,
            forSetters: true) ||
        changed;

    return changed;
  }

  /// Tells if a noSuchMethod forwarder is required for [member] in [cls].
  bool _isForwarderRequired(bool hasUserDefinedNoSuchMethod, Member member,
      Class cls, List<Member> concreteMembers,
      {bool isPatch = false}) {
    // A noSuchMethod forwarder is allowed for an abstract member if the class
    // has a user-defined noSuchMethod or if the member is private and is
    // defined in a different library.  Private members in patches are assumed
    // to be visible only to patches, so they are treated as if they were from
    // another library.
    bool isForwarderAllowed = hasUserDefinedNoSuchMethod ||
        (member.name.isPrivate &&
            cls.enclosingLibrary.compareTo(member.enclosingLibrary) != 0) ||
        (member.name.isPrivate && isPatch);
    // A noSuchMethod forwarder is required if it's allowed and if there's no
    // concrete implementation or a forwarder already.
    bool isForwarderRequired = isForwarderAllowed &&
        ClassHierarchy.findMemberByName(concreteMembers, member.name) == null;
    return isForwarderRequired;
  }

  void addRedirectingConstructor(ProcedureBuilder constructorBuilder,
      SourceLibraryBuilder library, Field referenceFrom) {
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
        origin.scope.lookupLocalMember(redirectingName, setter: false);
    if (constructorsField == null) {
      ListLiteral literal = new ListLiteral(<Expression>[]);
      Name name = new Name(redirectingName, library.library);
      Field field = new Field(name,
          isStatic: true,
          initializer: literal,
          fileUri: cls.fileUri,
          reference: referenceFrom?.reference)
        ..fileOffset = cls.fileOffset;
      cls.addMember(field);
      constructorsField = new DillMemberBuilder(field, this);
      origin.scope
          .addLocalMember(redirectingName, constructorsField, setter: false);
    }
    Field field = constructorsField.member;
    ListLiteral literal = field.initializer;
    literal.expressions
        .add(new StaticGet(constructorBuilder.procedure)..parent = literal);
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
                Field referenceFrom =
                    referencesFromIndexed?.lookupField("_redirecting#");
                addRedirectingConstructor(declaration, library, referenceFrom);
              }
              if (targetBuilder is FunctionBuilder) {
                List<DartType> typeArguments = declaration.typeArguments ??
                    new List<DartType>.filled(
                        targetBuilder
                            .member.enclosingClass.typeParameters.length,
                        const UnknownType());
                declaration.setRedirectingFactoryBody(
                    targetBuilder.member, typeArguments);
              } else if (targetBuilder is DillMemberBuilder) {
                List<DartType> typeArguments = declaration.typeArguments ??
                    new List<DartType>.filled(
                        targetBuilder
                            .member.enclosingClass.typeParameters.length,
                        const UnknownType());
                declaration.setRedirectingFactoryBody(
                    targetBuilder.member, typeArguments);
              } else if (targetBuilder is AmbiguousBuilder) {
                addProblem(
                    templateDuplicatedDeclarationUse
                        .withArguments(redirectionTarget.fullNameForErrors),
                    redirectionTarget.charOffset,
                    noLength);
                // CoreTypes aren't computed yet, and this is the outline
                // phase. So we can't and shouldn't create a method body.
                declaration.body = new RedirectingFactoryBody.unresolved(
                    redirectionTarget.fullNameForErrors);
              } else {
                addProblem(
                    templateRedirectionTargetNotFound
                        .withArguments(redirectionTarget.fullNameForErrors),
                    redirectionTarget.charOffset,
                    noLength);
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
    Member interfaceMemberOrigin =
        interfaceMember.memberSignatureOrigin ?? interfaceMember;
    if (declaredMember is Constructor || interfaceMember is Constructor) {
      unimplemented(
          "Constructor in override check.", declaredMember.fileOffset, fileUri);
    }
    if (declaredMember is Procedure && interfaceMember is Procedure) {
      if (declaredMember.kind == interfaceMember.kind) {
        if (declaredMember.kind == ProcedureKind.Method ||
            declaredMember.kind == ProcedureKind.Operator) {
          bool seenCovariant = checkMethodOverride(types, declaredMember,
              interfaceMember, interfaceMemberOrigin, isInterfaceCheck);
          if (seenCovariant) {
            handleSeenCovariant(
                types, declaredMember, interfaceMember, isSetter, callback);
          }
        } else if (declaredMember.kind == ProcedureKind.Getter) {
          checkGetterOverride(types, declaredMember, interfaceMember,
              interfaceMemberOrigin, isInterfaceCheck);
        } else if (declaredMember.kind == ProcedureKind.Setter) {
          bool seenCovariant = checkSetterOverride(types, declaredMember,
              interfaceMember, interfaceMemberOrigin, isInterfaceCheck);
          if (seenCovariant) {
            handleSeenCovariant(
                types, declaredMember, interfaceMember, isSetter, callback);
          }
        } else {
          assert(
              false,
              "Unexpected procedure kind in override check: "
              "${declaredMember.kind}");
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
        checkGetterOverride(types, declaredMember, interfaceMember,
            interfaceMemberOrigin, isInterfaceCheck);
      }
      if (declaredMemberHasSetter && interfaceMemberHasSetter) {
        bool seenCovariant = checkSetterOverride(types, declaredMember,
            interfaceMember, interfaceMemberOrigin, isInterfaceCheck);
        if (seenCovariant) {
          handleSeenCovariant(
              types, declaredMember, interfaceMember, isSetter, callback);
        }
      }
    }
    // TODO(ahe): Handle other cases: accessors, operators, and fields.
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
      Member interfaceMemberOrigin,
      FunctionNode declaredFunction,
      FunctionNode interfaceFunction,
      bool isInterfaceCheck) {
    Substitution interfaceSubstitution = Substitution.empty;
    if (interfaceMember.enclosingClass.typeParameters.isNotEmpty) {
      Class enclosingClass = interfaceMember.enclosingClass;
      interfaceSubstitution = Substitution.fromPairs(
          enclosingClass.typeParameters,
          types.hierarchy
              .getTypeArgumentsAsInstanceOf(thisType, enclosingClass));
    }

    if (declaredFunction?.typeParameters?.length !=
        interfaceFunction?.typeParameters?.length) {
      reportInvalidOverride(
          isInterfaceCheck,
          declaredMember,
          templateOverrideTypeVariablesMismatch.withArguments(
              "${declaredMember.enclosingClass.name}."
                  "${declaredMember.name.text}",
              "${interfaceMemberOrigin.enclosingClass.name}."
                  "${interfaceMemberOrigin.name.text}"),
          declaredMember.fileOffset,
          noLength,
          context: [
            templateOverriddenMethodCause
                .withArguments(interfaceMemberOrigin.name.text)
                .withLocation(_getMemberUri(interfaceMemberOrigin),
                    interfaceMemberOrigin.fileOffset, noLength)
          ]);
    } else if (declaredFunction?.typeParameters != null) {
      Map<TypeParameter, DartType> substitutionMap =
          <TypeParameter, DartType>{};
      for (int i = 0; i < declaredFunction.typeParameters.length; ++i) {
        substitutionMap[interfaceFunction.typeParameters[i]] =
            new TypeParameterType.forAlphaRenaming(
                interfaceFunction.typeParameters[i],
                declaredFunction.typeParameters[i]);
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
          DartType computedBound = substitution.substituteType(interfaceBound);
          if (!library.isNonNullableByDefault) {
            computedBound =
                legacyErasure(types.hierarchy.coreTypes, computedBound);
          }
          if (!types
              .performNullabilityAwareMutualSubtypesCheck(
                  declaredBound, computedBound)
              .isSubtypeWhenUsingNullabilities()) {
            reportInvalidOverride(
                isInterfaceCheck,
                declaredMember,
                templateOverrideTypeVariablesBoundMismatch.withArguments(
                    declaredBound,
                    declaredParameter.name,
                    "${declaredMember.enclosingClass.name}."
                        "${declaredMember.name.text}",
                    computedBound,
                    "${interfaceMemberOrigin.enclosingClass.name}."
                        "${interfaceMemberOrigin.name.text}",
                    library.isNonNullableByDefault),
                declaredMember.fileOffset,
                noLength,
                context: [
                  templateOverriddenMethodCause
                      .withArguments(interfaceMemberOrigin.name.text)
                      .withLocation(_getMemberUri(interfaceMemberOrigin),
                          interfaceMemberOrigin.fileOffset, noLength)
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
      Class enclosingClass = declaredMember.enclosingClass;
      declaredSubstitution = Substitution.fromPairs(
          enclosingClass.typeParameters,
          types.hierarchy
              .getTypeArgumentsAsInstanceOf(thisType, enclosingClass));
    }
    return declaredSubstitution;
  }

  void _checkTypes(
      Types types,
      Substitution interfaceSubstitution,
      Substitution declaredSubstitution,
      Member declaredMember,
      Member interfaceMember,
      Member interfaceMemberOrigin,
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

    if (!declaredMember.isNonNullableByDefault &&
        interfaceMember.isNonNullableByDefault) {
      interfaceType = legacyErasure(types.hierarchy.coreTypes, interfaceType);
    }

    bool inParameter = declaredParameter != null || asIfDeclaredParameter;
    DartType subtype = inParameter ? interfaceType : declaredType;
    DartType supertype = inParameter ? declaredType : interfaceType;

    if (types.isSubtypeOf(
        subtype, supertype, SubtypeCheckMode.withNullabilities)) {
      // No problem--the proper subtyping relation is satisfied.
    } else if (isCovariant &&
        types.isSubtypeOf(
            supertype, subtype, SubtypeCheckMode.withNullabilities)) {
      // No problem--the overriding parameter is marked "covariant" and has
      // a type which is a subtype of the parameter it overrides.
    } else if (subtype is InvalidType || supertype is InvalidType) {
      // Don't report a problem as something else is wrong that has already
      // been reported.
    } else {
      // Report an error.
      bool isErrorInNnbdOptedOutMode = !types.isSubtypeOf(
              subtype, supertype, SubtypeCheckMode.ignoringNullabilities) &&
          (!isCovariant ||
              !types.isSubtypeOf(
                  supertype, subtype, SubtypeCheckMode.ignoringNullabilities));
      if (isErrorInNnbdOptedOutMode || library.isNonNullableByDefault) {
        String declaredMemberName = '${declaredMember.enclosingClass.name}'
            '.${declaredMember.name.text}';
        String interfaceMemberName =
            '${interfaceMemberOrigin.enclosingClass.name}'
            '.${interfaceMemberOrigin.name.text}';
        Message message;
        int fileOffset;
        if (declaredParameter == null) {
          if (asIfDeclaredParameter) {
            // Setter overridden by field
            message = templateOverrideTypeMismatchSetter.withArguments(
                declaredMemberName,
                declaredType,
                interfaceType,
                interfaceMemberName,
                library.isNonNullableByDefault);
          } else {
            message = templateOverrideTypeMismatchReturnType.withArguments(
                declaredMemberName,
                declaredType,
                interfaceType,
                interfaceMemberName,
                library.isNonNullableByDefault);
          }
          fileOffset = declaredMember.fileOffset;
        } else {
          message = templateOverrideTypeMismatchParameter.withArguments(
              declaredParameter.name,
              declaredMemberName,
              declaredType,
              interfaceType,
              interfaceMemberName,
              library.isNonNullableByDefault);
          fileOffset = declaredParameter.fileOffset;
        }
        reportInvalidOverride(
            isInterfaceCheck, declaredMember, message, fileOffset, noLength,
            context: [
              templateOverriddenMethodCause
                  .withArguments(interfaceMemberOrigin.name.text)
                  .withLocation(_getMemberUri(interfaceMemberOrigin),
                      interfaceMemberOrigin.fileOffset, noLength)
            ]);
      }
    }
  }

  /// Checks whether [declaredMember] correctly overrides [interfaceMember].
  ///
  /// If an error is reporter [interfaceMemberOrigin] is used as the context
  /// for where [interfaceMember] was declared, since [interfaceMember] might
  /// itself be synthesized.
  ///
  /// Returns whether a covariant parameter was seen and more methods thus have
  /// to be checked.
  bool checkMethodOverride(
      Types types,
      Procedure declaredMember,
      Procedure interfaceMember,
      Member interfaceMemberOrigin,
      bool isInterfaceCheck) {
    assert(declaredMember.kind == interfaceMember.kind);
    assert(declaredMember.kind == ProcedureKind.Method ||
        declaredMember.kind == ProcedureKind.Operator);
    bool seenCovariant = false;
    FunctionNode declaredFunction = declaredMember.function;
    FunctionNode interfaceFunction = interfaceMember.function;

    Substitution interfaceSubstitution = _computeInterfaceSubstitution(
        types,
        declaredMember,
        interfaceMember,
        interfaceMemberOrigin,
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
        interfaceMemberOrigin,
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
                  "${declaredMember.name.text}",
              "${interfaceMember.enclosingClass.name}."
                  "${interfaceMember.name.text}"),
          declaredMember.fileOffset,
          noLength,
          context: [
            templateOverriddenMethodCause
                .withArguments(interfaceMember.name.text)
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
                  "${declaredMember.name.text}",
              "${interfaceMember.enclosingClass.name}."
                  "${interfaceMember.name.text}"),
          declaredMember.fileOffset,
          noLength,
          context: [
            templateOverriddenMethodCause
                .withArguments(interfaceMember.name.text)
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
      if (i == 0 &&
          declaredMember.name == equalsName &&
          declaredParameter.type ==
              types.hierarchy.coreTypes.objectNonNullableRawType &&
          interfaceParameter.type is DynamicType) {
        // TODO(johnniwinther): Add check for opt-in overrides of operator ==.
        // `operator ==` methods in opt-out classes have type
        // `bool Function(dynamic)`.
        continue;
      }

      _checkTypes(
          types,
          interfaceSubstitution,
          declaredSubstitution,
          declaredMember,
          interfaceMember,
          interfaceMemberOrigin,
          declaredParameter.type,
          interfaceParameter.type,
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
                  "${declaredMember.name.text}",
              "${interfaceMemberOrigin.enclosingClass.name}."
                  "${interfaceMemberOrigin.name.text}"),
          declaredMember.fileOffset,
          noLength,
          context: [
            templateOverriddenMethodCause
                .withArguments(interfaceMemberOrigin.name.text)
                .withLocation(interfaceMemberOrigin.fileUri,
                    interfaceMemberOrigin.fileOffset, noLength)
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
                      "${declaredMember.name.text}",
                  interfaceNamedParameters.current.name,
                  "${interfaceMember.enclosingClass.name}."
                      "${interfaceMember.name.text}"),
              declaredMember.fileOffset,
              noLength,
              context: [
                templateOverriddenMethodCause
                    .withArguments(interfaceMember.name.text)
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
          interfaceMemberOrigin,
          declaredParameter.type,
          interfaceNamedParameters.current.type,
          declaredParameter.isCovariant,
          declaredParameter,
          isInterfaceCheck);
      if (declaredMember.isNonNullableByDefault &&
          declaredParameter.isRequired &&
          interfaceMember.isNonNullableByDefault &&
          !interfaceNamedParameters.current.isRequired) {
        reportInvalidOverride(
            isInterfaceCheck,
            declaredMember,
            templateOverrideMismatchRequiredNamedParameter.withArguments(
                declaredParameter.name,
                "${declaredMember.enclosingClass.name}."
                    "${declaredMember.name.text}",
                "${interfaceMember.enclosingClass.name}."
                    "${interfaceMember.name.text}"),
            declaredParameter.fileOffset,
            noLength,
            context: [
              templateOverriddenMethodCause
                  .withArguments(interfaceMemberOrigin.name.text)
                  .withLocation(_getMemberUri(interfaceMemberOrigin),
                      interfaceMemberOrigin.fileOffset, noLength)
            ]);
      }
      if (declaredParameter.isCovariant) seenCovariant = true;
    }
    return seenCovariant;
  }

  /// Checks whether [declaredMember] correctly overrides [interfaceMember].
  ///
  /// If an error is reporter [interfaceMemberOrigin] is used as the context
  /// for where [interfaceMember] was declared, since [interfaceMember] might
  /// itself be synthesized.
  void checkGetterOverride(
      Types types,
      Member declaredMember,
      Member interfaceMember,
      Member interfaceMemberOrigin,
      bool isInterfaceCheck) {
    Substitution interfaceSubstitution = _computeInterfaceSubstitution(
        types,
        declaredMember,
        interfaceMember,
        interfaceMemberOrigin,
        /* declaredFunction = */ null,
        /* interfaceFunction = */ null,
        isInterfaceCheck);
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
        interfaceMemberOrigin,
        declaredType,
        interfaceType,
        /* isCovariant = */ false,
        /* declaredParameter = */ null,
        isInterfaceCheck);
  }

  /// Checks whether [declaredMember] correctly overrides [interfaceMember].
  ///
  /// If an error is reporter [interfaceMemberOrigin] is used as the context
  /// for where [interfaceMember] was declared, since [interfaceMember] might
  /// itself be synthesized.
  ///
  /// Returns whether a covariant parameter was seen and more methods thus have
  /// to be checked.
  bool checkSetterOverride(
      Types types,
      Member declaredMember,
      Member interfaceMember,
      Member interfaceMemberOrigin,
      bool isInterfaceCheck) {
    Substitution interfaceSubstitution = _computeInterfaceSubstitution(
        types,
        declaredMember,
        interfaceMember,
        interfaceMemberOrigin,
        /* declaredFunction = */ null,
        /* interfaceFunction = */ null,
        isInterfaceCheck);
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
        interfaceMemberOrigin,
        declaredType,
        interfaceType,
        isCovariant,
        declaredParameter,
        isInterfaceCheck,
        asIfDeclaredParameter: true);
    return isCovariant;
  }

  // When the overriding member is inherited, report the class containing
  // the conflict as the main error.
  void reportInvalidOverride(bool isInterfaceCheck, Member declaredMember,
      Message message, int fileOffset, int length,
      {List<LocatedMessage> context}) {
    if (shouldOverrideProblemBeOverlooked(this)) {
      return;
    }

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
                declaredMember.name.text, cls.name),
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
                  mixinName, baseName, declaredMember.name.text),
              cls.fileOffset,
              classNameLength,
              cls.fileUri,
              context: context);
        } else {
          // Named mixin application class
          library.addProblem(
              templateNamedMixinOverride.withArguments(
                  cls.name, declaredMember.name.text),
              cls.fileOffset,
              cls.name.length,
              cls.fileUri,
              context: context);
        }
      }
    }
  }
}
