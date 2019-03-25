// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_class_builder;

import 'package:kernel/ast.dart'
    show Class, Constructor, Member, Supertype, TreeNode;

import '../dill/dill_member_builder.dart' show DillMemberBuilder;

import '../fasta_codes.dart'
    show
        noLength,
        templateConflictsWithConstructor,
        templateConflictsWithFactory,
        templateConflictsWithMember,
        templateConflictsWithMemberWarning,
        templateConflictsWithSetter,
        templateConflictsWithSetterWarning,
        templateSupertypeIsIllegal;

import '../kernel/kernel_builder.dart'
    show
        ClassBuilder,
        ConstructorReferenceBuilder,
        Declaration,
        KernelClassBuilder,
        KernelFieldBuilder,
        KernelFunctionBuilder,
        KernelLibraryBuilder,
        KernelNamedTypeBuilder,
        KernelTypeBuilder,
        KernelTypeVariableBuilder,
        LibraryBuilder,
        MetadataBuilder,
        Scope,
        TypeVariableBuilder,
        compareProcedures;

import '../kernel/kernel_shadow_ast.dart' show ShadowClass;

import '../problems.dart' show unexpected, unhandled;

ShadowClass initializeClass(
    ShadowClass cls,
    List<TypeVariableBuilder> typeVariables,
    String name,
    KernelLibraryBuilder parent,
    int startCharOffset,
    int charOffset,
    int charEndOffset) {
  cls ??= new ShadowClass(
      name: name,
      typeParameters:
          KernelTypeVariableBuilder.kernelTypeParametersFromBuilders(
              typeVariables));
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

class SourceClassBuilder extends KernelClassBuilder
    implements Comparable<SourceClassBuilder> {
  @override
  final Class actualCls;

  final List<ConstructorReferenceBuilder> constructorReferences;

  KernelTypeBuilder mixedInType;

  bool isMixinDeclaration;

  SourceClassBuilder(
      List<MetadataBuilder> metadata,
      int modifiers,
      String name,
      List<TypeVariableBuilder> typeVariables,
      KernelTypeBuilder supertype,
      List<KernelTypeBuilder> interfaces,
      Scope scope,
      Scope constructors,
      LibraryBuilder parent,
      this.constructorReferences,
      int startCharOffset,
      int charOffset,
      int charEndOffset,
      {Class cls,
      this.mixedInType,
      this.isMixinDeclaration = false})
      : actualCls = initializeClass(cls, typeVariables, name, parent,
            startCharOffset, charOffset, charEndOffset),
        super(metadata, modifiers, name, typeVariables, supertype, interfaces,
            scope, constructors, parent, charOffset) {
    ShadowClass.setBuilder(this.cls, this);
  }

  @override
  ShadowClass get cls => origin.actualCls;

  @override
  KernelLibraryBuilder get library => super.library;

  Class build(KernelLibraryBuilder library, LibraryBuilder coreLibrary) {
    void buildBuilders(String name, Declaration declaration) {
      do {
        if (declaration.parent != this) {
          if (fileUri != declaration.parent.fileUri) {
            unexpected("$fileUri", "${declaration.parent.fileUri}", charOffset,
                fileUri);
          } else {
            unexpected(fullNameForErrors, declaration.parent?.fullNameForErrors,
                charOffset, fileUri);
          }
        } else if (declaration is KernelFieldBuilder) {
          // TODO(ahe): It would be nice to have a common interface for the
          // build method to avoid duplicating these two cases.
          Member field = declaration.build(library);
          if (!declaration.isPatch && declaration.next == null) {
            cls.addMember(field);
          }
        } else if (declaration is KernelFunctionBuilder) {
          Member function = declaration.build(library);
          function.parent = cls;
          if (!declaration.isPatch && declaration.next == null) {
            cls.addMember(function);
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
    actualCls.mixedInType =
        mixedInType?.buildMixedInType(library, charOffset, fileUri);
    actualCls.isMixinDeclaration = isMixinDeclaration;
    // TODO(ahe): If `cls.supertype` is null, and this isn't Object, report a
    // compile-time error.
    cls.isAbstract = isAbstract;
    if (interfaces != null) {
      for (KernelTypeBuilder interface in interfaces) {
        Supertype supertype =
            interface.buildSupertype(library, charOffset, fileUri);
        if (supertype != null) {
          // TODO(ahe): Report an error if supertype is null.
          actualCls.implementedTypes.add(supertype);
        }
      }
    }

    constructors.forEach((String name, Declaration constructor) {
      Declaration member = scopeBuilder[name];
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

    scope.setters.forEach((String name, Declaration setter) {
      Declaration member = scopeBuilder[name];
      if (member == null ||
          !(member.isField && !member.isFinal ||
              member.isRegularMethod && member.isStatic && setter.isStatic))
        return;
      if (member.isInstanceMember == setter.isInstanceMember) {
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

    scope.setters.forEach((String name, Declaration setter) {
      Declaration constructor = constructorScopeBuilder[name];
      if (constructor == null || !setter.isStatic) return;
      addProblem(templateConflictsWithConstructor.withArguments(name),
          setter.charOffset, noLength);
      addProblem(templateConflictsWithSetter.withArguments(name),
          constructor.charOffset, noLength);
    });

    cls.procedures.sort(compareProcedures);
    return cls;
  }

  void addSyntheticConstructor(Constructor constructor) {
    String name = constructor.name.name;
    cls.constructors.add(constructor);
    constructor.parent = cls;
    DillMemberBuilder memberBuilder = new DillMemberBuilder(constructor, this);
    memberBuilder.next = constructorScopeBuilder[name];
    constructorScopeBuilder.addMember(name, memberBuilder);
  }

  void prepareTopLevelInference() {
    scope.forEach((String name, Declaration declaration) {
      do {
        if (declaration is KernelFieldBuilder) {
          declaration.prepareTopLevelInference();
        }
        declaration = declaration.next;
      } while (declaration != null);
    });
    if (!isPatch) {
      cls.setupApiMembers(library.loader.interfaceResolver);
    }
  }

  @override
  int finishPatch() {
    if (!isPatch) return 0;

    // TODO(ahe): restore file-offset once we track both origin and patch file
    // URIs. See https://github.com/dart-lang/sdk/issues/31579
    cls.annotations.forEach((m) => m.fileOffset = origin.cls.fileOffset);

    int count = 0;
    scope.forEach((String name, Declaration declaration) {
      count += declaration.finishPatch();
    });
    constructors.forEach((String name, Declaration declaration) {
      count += declaration.finishPatch();
    });
    return count;
  }

  List<Declaration> computeDirectSupertypes(ClassBuilder objectClass) {
    final List<Declaration> result = <Declaration>[];
    final KernelNamedTypeBuilder supertype = this.supertype;
    if (supertype != null) {
      result.add(supertype.declaration);
    } else if (objectClass != this) {
      result.add(objectClass);
    }
    final List<KernelTypeBuilder> interfaces = this.interfaces;
    if (interfaces != null) {
      for (int i = 0; i < interfaces.length; i++) {
        KernelNamedTypeBuilder interface = interfaces[i];
        result.add(interface.declaration);
      }
    }
    final KernelNamedTypeBuilder mixedInType = this.mixedInType;
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
