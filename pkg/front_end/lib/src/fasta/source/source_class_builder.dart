// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_class_builder;

import 'package:kernel/ast.dart'
    show Class, Constructor, Member, Supertype, TreeNode;

import '../builder/class_builder.dart';

import '../dill/dill_member_builder.dart' show DillMemberBuilder;

import '../fasta_codes.dart'
    show
        Message,
        noLength,
        templateBadTypeVariableInSupertype,
        templateConflictsWithConstructor,
        templateConflictsWithFactory,
        templateConflictsWithMember,
        templateConflictsWithMemberWarning,
        templateConflictsWithSetter,
        templateConflictsWithSetterWarning,
        templateSupertypeIsIllegal;

import '../kernel/kernel_builder.dart'
    show
        ConstructorReferenceBuilder,
        Builder,
        FieldBuilder,
        FunctionBuilder,
        InvalidTypeBuilder,
        NamedTypeBuilder,
        LibraryBuilder,
        MetadataBuilder,
        NullabilityBuilder,
        Scope,
        TypeBuilder,
        TypeVariableBuilder,
        compareProcedures;

import '../kernel/type_algorithms.dart' show Variance, computeVariance;

import '../problems.dart' show unexpected, unhandled;

import 'source_library_builder.dart' show SourceLibraryBuilder;

Class initializeClass(
    Class cls,
    List<TypeVariableBuilder> typeVariables,
    String name,
    SourceLibraryBuilder parent,
    int startCharOffset,
    int charOffset,
    int charEndOffset) {
  cls ??= new Class(
      name: name,
      typeParameters:
          TypeVariableBuilder.typeParametersFromBuilders(typeVariables));
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

  SourceClassBuilder(
      List<MetadataBuilder> metadata,
      int modifiers,
      String name,
      List<TypeVariableBuilder> typeVariables,
      TypeBuilder supertype,
      List<TypeBuilder> interfaces,
      List<TypeBuilder> onTypes,
      Scope scope,
      Scope constructors,
      LibraryBuilder parent,
      this.constructorReferences,
      int startCharOffset,
      int nameOffset,
      int charEndOffset,
      {Class cls,
      this.mixedInType,
      this.isMixinDeclaration = false})
      : actualCls = initializeClass(cls, typeVariables, name, parent,
            startCharOffset, nameOffset, charEndOffset),
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
        } else if (declaration is FieldBuilder) {
          // TODO(ahe): It would be nice to have a common interface for the
          // build method to avoid duplicating these two cases.
          Member field = declaration.build(library);
          if (!declaration.isPatch && declaration.next == null) {
            cls.addMember(field);
          }
        } else if (declaration is FunctionBuilder) {
          Member member = declaration.build(library);
          member.parent = cls;
          if (!declaration.isPatch && declaration.next == null) {
            cls.addMember(member);
          }
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

    scope.setters.forEach((String name, Builder setter) {
      Builder member = scopeBuilder[name];
      if (member == null ||
          !(member.isField && !member.isFinal && !member.isConst ||
              member.isRegularMethod && member.isStatic && setter.isStatic)) {
        return;
      }
      if (member.isDeclarationInstanceMember ==
          setter.isDeclarationInstanceMember) {
        addProblem(templateConflictsWithMember.withArguments(name),
            setter.charOffset, noLength);
        // TODO(ahe): Context argument to previous message?
        addProblem(templateConflictsWithSetter.withArguments(name),
            member.charOffset, noLength);
      } else {
        addProblem(templateConflictsWithMemberWarning.withArguments(name),
            setter.charOffset, noLength);
        // TODO(ahe): Context argument to previous message?
        addProblem(templateConflictsWithSetterWarning.withArguments(name),
            member.charOffset, noLength);
      }
    });

    scope.setters.forEach((String name, Builder setter) {
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
      int variance = computeVariance(typeVariables[i], supertype);
      if (variance == Variance.contravariant ||
          variance == Variance.invariant) {
        message = templateBadTypeVariableInSupertype.withArguments(
            typeVariables[i].name, supertype.name);
        library.addProblem(message, charOffset, noLength, fileUri);
      }
    }
    if (message != null) {
      return new NamedTypeBuilder(
          supertype.name, const NullabilityBuilder.omitted(), null)
        ..bind(new InvalidTypeBuilder(supertype.name,
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
      result.add(supertype.declaration);
    } else if (objectClass != this) {
      result.add(objectClass);
    }
    final List<TypeBuilder> interfaces = this.interfaces;
    if (interfaces != null) {
      for (int i = 0; i < interfaces.length; i++) {
        TypeBuilder interface = interfaces[i];
        result.add(interface.declaration);
      }
    }
    final TypeBuilder mixedInType = this.mixedInType;
    if (mixedInType != null) {
      result.add(mixedInType.declaration);
    }
    return result;
  }

  @override
  int compareTo(SourceClassBuilder other) {
    int result = "$fileUri".compareTo("${other.fileUri}");
    if (result != 0) return result;
    return charOffset.compareTo(other.charOffset);
  }
}
