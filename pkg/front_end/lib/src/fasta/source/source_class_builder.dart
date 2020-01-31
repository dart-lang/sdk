// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_class_builder;

import 'package:kernel/ast.dart'
    show
        Class,
        Constructor,
        Expression,
        ListLiteral,
        Member,
        StaticGet,
        Supertype,
        TreeNode,
        DartType,
        DynamicType,
        Field,
        FunctionNode,
        Name,
        Procedure,
        ProcedureKind,
        TypeParameter,
        VariableDeclaration,
        Variance,
        VoidType;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/clone.dart' show CloneProcedureWithoutBody;

import 'package:kernel/reference_from_index.dart' show IndexedClass;

import 'package:kernel/type_algebra.dart' show Substitution;

import 'package:kernel/type_algebra.dart' as type_algebra
    show getSubstitutionMap;

import '../builder/builder.dart';

import '../builder/class_builder.dart';

import '../builder/constructor_reference_builder.dart';

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

import '../fasta_codes.dart'
    show
        Message,
        noLength,
        templateConflictsWithConstructor,
        templateConflictsWithFactory,
        templateConflictsWithMember,
        templateConflictsWithSetter,
        templateDuplicatedDeclarationUse,
        templateInvalidTypeVariableInSupertype,
        templateInvalidTypeVariableInSupertypeWithVariance,
        templateRedirectionTargetNotFound,
        templateSupertypeIsIllegal;

import '../kernel/redirecting_factory_body.dart' show redirectingName;

import '../kernel/kernel_builder.dart' show compareProcedures;

import '../kernel/kernel_target.dart' show KernelTarget;

import '../kernel/redirecting_factory_body.dart' show RedirectingFactoryBody;

import '../kernel/type_algorithms.dart' show Variance, computeVariance;

import '../names.dart' show noSuchMethodName;

import '../problems.dart' show unexpected, unhandled;

import '../scope.dart';

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

  TypeBuilder mixedInType;

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
    this.mixedInType,
    this.isMixinDeclaration = false,
  })  : actualCls = initializeClass(cls, typeVariables, name, parent,
            startCharOffset, nameOffset, charEndOffset, referencesFrom),
        referencesFrom = referencesFrom,
        referencesFromIndexed = referencesFromIndexed,
        super(metadata, modifiers, name, typeVariables, supertype, interfaces,
            onTypes, scope, constructors, parent, nameOffset);

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
    supertype = checkSupertype(supertype);
    actualCls.supertype =
        supertype?.buildSupertype(library, charOffset, fileUri);
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
      actualCls.supertype = null;
    }
    if (actualCls.supertype == null && supertype is! NamedTypeBuilder) {
      supertype = null;
    }
    mixedInType = checkSupertype(mixedInType);
    actualCls.mixedInType =
        mixedInType?.buildMixedInType(library, charOffset, fileUri);
    if (actualCls.mixedInType == null && mixedInType is! NamedTypeBuilder) {
      mixedInType = null;
    }
    actualCls.isMixinDeclaration = isMixinDeclaration;
    // TODO(ahe): If `cls.supertype` is null, and this isn't Object, report a
    // compile-time error.
    cls.isAbstract = isAbstract;
    if (interfaces != null) {
      for (int i = 0; i < interfaces.length; ++i) {
        interfaces[i] = checkSupertype(interfaces[i]);
        Supertype supertype =
            interfaces[i].buildSupertype(library, charOffset, fileUri);
        if (supertype != null) {
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
      int variance = computeVariance(typeVariables[i], supertype, library);
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
          supertype.name, const NullabilityBuilder.omitted(), null)
        ..bind(new InvalidTypeDeclarationBuilder(supertype.name,
            message.withLocation(fileUri, charOffset, noLength)));
    }
    return supertype;
  }

  void addSyntheticConstructor(Constructor constructor) {
    String name = constructor.name.name;
    cls.constructors.add(constructor);
    constructor.parent = cls;
    DillMemberBuilder memberBuilder = new DillMemberBuilder(constructor, this);
    memberBuilder.next = constructorScopeBuilder[name];
    constructorScopeBuilder.addMember(name, memberBuilder);
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

  List<Builder> computeDirectSupertypes(ClassBuilder objectClass) {
    final List<Builder> result = <Builder>[];
    final TypeBuilder supertype = this.supertype;
    if (supertype != null) {
      TypeDeclarationBuilder declarationBuilder = supertype.declaration;
      if (declarationBuilder is TypeAliasBuilder) {
        TypeAliasBuilder aliasBuilder = declarationBuilder;
        declarationBuilder = aliasBuilder.unaliasDeclaration;
      }
      result.add(declarationBuilder);
    } else if (objectClass != this) {
      result.add(objectClass);
    }
    final List<TypeBuilder> interfaces = this.interfaces;
    if (interfaces != null) {
      for (int i = 0; i < interfaces.length; i++) {
        TypeBuilder interface = interfaces[i];
        TypeDeclarationBuilder declarationBuilder = interface.declaration;
        if (declarationBuilder is TypeAliasBuilder) {
          TypeAliasBuilder aliasBuilder = declarationBuilder;
          declarationBuilder = aliasBuilder.unaliasDeclaration;
        }
        result.add(declarationBuilder);
      }
    }
    final TypeBuilder mixedInType = this.mixedInType;
    if (mixedInType != null) {
      TypeDeclarationBuilder declarationBuilder = mixedInType.declaration;
      if (declarationBuilder is TypeAliasBuilder) {
        TypeAliasBuilder aliasBuilder = declarationBuilder;
        declarationBuilder = aliasBuilder.unaliasDeclaration;
      }
      result.add(declarationBuilder);
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
            referencesFromIndexed.lookupProcedureSetter(procedure.name.name);
      } else {
        referenceFrom =
            referencesFromIndexed.lookupProcedureNotSetter(procedure.name.name);
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

  void addNoSuchMethodForwarderGetterForField(Member noSuchMethod,
      KernelTarget target, Field field, ClassHierarchy hierarchy) {
    Substitution substitution = Substitution.fromSupertype(
        hierarchy.getClassAsInstanceOf(cls, field.enclosingClass));

    Procedure referenceFrom;
    if (referencesFromIndexed != null) {
      referenceFrom =
          referencesFromIndexed.lookupProcedureNotSetter(field.name.name);
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
      ..fileOffset = field.fileOffset;
    transformProcedureToNoSuchMethodForwarder(noSuchMethod, target, getter);
    cls.procedures.add(getter);
    getter.parent = cls;
  }

  void addNoSuchMethodForwarderSetterForField(Member noSuchMethod,
      KernelTarget target, Field field, ClassHierarchy hierarchy) {
    Substitution substitution = Substitution.fromSupertype(
        hierarchy.getClassAsInstanceOf(cls, field.enclosingClass));

    Procedure referenceFrom;
    if (referencesFromIndexed != null) {
      referenceFrom =
          referencesFromIndexed.lookupProcedureSetter(field.name.name);
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
}
