// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_class_builder;

import 'package:front_end/src/base/instrumentation.dart' show Instrumentation;

import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart'
    show ShadowClass;

import 'package:kernel/ast.dart'
    show Class, Constructor, Supertype, TreeNode, setParents;

import '../dill/dill_member_builder.dart' show DillMemberBuilder;

import '../fasta_codes.dart'
    show
        templateConflictsWithConstructor,
        templateConflictsWithFactory,
        templateConflictsWithMember,
        templateConflictsWithSetter;

import '../kernel/kernel_builder.dart'
    show
        Builder,
        ClassBuilder,
        ConstructorReferenceBuilder,
        KernelClassBuilder,
        KernelFieldBuilder,
        KernelFunctionBuilder,
        KernelLibraryBuilder,
        KernelTypeBuilder,
        KernelTypeVariableBuilder,
        LibraryBuilder,
        MetadataBuilder,
        Scope,
        TypeVariableBuilder,
        compareProcedures;

import '../problems.dart' show unhandled;

import 'source_library_builder.dart' show SourceLibraryBuilder;

ShadowClass initializeClass(
    ShadowClass cls, String name, KernelLibraryBuilder parent, int charOffset) {
  cls ??= new ShadowClass(name: name);
  cls.fileUri ??= parent.library.fileUri;
  if (cls.fileOffset == TreeNode.noOffset) {
    cls.fileOffset = charOffset;
  }
  return cls;
}

class SourceClassBuilder extends KernelClassBuilder {
  final ShadowClass cls;

  final List<ConstructorReferenceBuilder> constructorReferences;

  KernelTypeBuilder mixedInType;

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
      int charOffset,
      [ShadowClass cls,
      this.mixedInType])
      : cls = initializeClass(cls, name, parent, charOffset),
        super(metadata, modifiers, name, typeVariables, supertype, interfaces,
            scope, constructors, parent, charOffset) {
    ShadowClass.setBuilder(this.cls, this);
  }

  @override
  int resolveTypes(LibraryBuilder library) {
    int count = 0;
    if (typeVariables != null) {
      for (KernelTypeVariableBuilder t in typeVariables) {
        cls.typeParameters.add(t.parameter);
      }
      setParents(cls.typeParameters, cls);
      count += cls.typeParameters.length;
    }
    return count + super.resolveTypes(library);
  }

  Class build(KernelLibraryBuilder library, LibraryBuilder coreLibrary) {
    void buildBuilders(String name, Builder builder) {
      do {
        if (builder is KernelFieldBuilder) {
          // TODO(ahe): It would be nice to have a common interface for the
          // build method to avoid duplicating these two cases.
          cls.addMember(builder.build(library));
        } else if (builder is KernelFunctionBuilder) {
          cls.addMember(builder.build(library));
        } else {
          unhandled("${builder.runtimeType}", "buildBuilders",
              builder.charOffset, builder.fileUri);
        }
        builder = builder.next;
      } while (builder != null);
    }

    scope.forEach(buildBuilders);
    constructors.forEach(buildBuilders);
    cls.supertype = supertype?.buildSupertype(library);
    cls.mixedInType = mixedInType?.buildSupertype(library);
    // TODO(ahe): If `cls.supertype` is null, and this isn't Object, report a
    // compile-time error.
    cls.isAbstract = isAbstract;
    if (interfaces != null) {
      for (KernelTypeBuilder interface in interfaces) {
        Supertype supertype = interface.buildSupertype(library);
        if (supertype != null) {
          // TODO(ahe): Report an error if supertype is null.
          cls.implementedTypes.add(supertype);
        }
      }
    }

    constructors.forEach((String name, Builder constructor) {
      Builder member = scopeBuilder[name];
      if (member == null) return;
      // TODO(ahe): charOffset is missing.
      addCompileTimeError(templateConflictsWithMember.withArguments(name),
          constructor.charOffset);
      if (constructor.isFactory) {
        addCompileTimeError(
            templateConflictsWithFactory.withArguments("${this.name}.${name}"),
            member.charOffset);
      } else {
        addCompileTimeError(
            templateConflictsWithConstructor
                .withArguments("${this.name}.${name}"),
            member.charOffset);
      }
    });

    scope.setters.forEach((String name, Builder setter) {
      Builder member = scopeBuilder[name];
      if (member == null || !member.isField || member.isFinal) return;
      // TODO(ahe): charOffset is missing.
      var report = member.isInstanceMember != setter.isInstanceMember
          ? addWarning
          : addCompileTimeError;
      report(
          templateConflictsWithMember.withArguments(name), setter.charOffset);
      report(
          templateConflictsWithSetter.withArguments(name), member.charOffset);
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

  @override
  void prepareTopLevelInference(
      SourceLibraryBuilder library, ClassBuilder currentClass) {
    scope.forEach((name, builder) {
      builder.prepareTopLevelInference(library, this);
    });
  }

  @override
  void instrumentTopLevelInference(Instrumentation instrumentation) {
    scope.forEach((name, builder) {
      builder.instrumentTopLevelInference(instrumentation);
    });
  }
}
