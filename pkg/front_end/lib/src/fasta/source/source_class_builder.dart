// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_class_builder;

import 'package:front_end/src/fasta/builder/class_builder.dart'
    show ClassBuilder;

import 'package:front_end/src/fasta/source/source_library_builder.dart'
    show SourceLibraryBuilder;

import 'package:kernel/ast.dart'
    show Class, Constructor, Supertype, TreeNode, setParents;

import '../deprecated_problems.dart' show deprecated_internalProblem;

import '../kernel/kernel_builder.dart'
    show
        Builder,
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

import '../dill/dill_member_builder.dart' show DillMemberBuilder;

Class initializeClass(
    Class cls, String name, KernelLibraryBuilder parent, int charOffset) {
  cls ??= new Class(name: name);
  cls.fileUri ??= parent.library.fileUri;
  if (cls.fileOffset == TreeNode.noOffset) {
    cls.fileOffset = charOffset;
  }
  return cls;
}

class SourceClassBuilder extends KernelClassBuilder {
  final Class cls;

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
      [Class cls,
      this.mixedInType])
      : cls = initializeClass(cls, name, parent, charOffset),
        super(metadata, modifiers, name, typeVariables, supertype, interfaces,
            scope, constructors, parent, charOffset);

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
          deprecated_internalProblem(
              "Unhandled builder: ${builder.runtimeType}");
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
      deprecated_addCompileTimeError(
          constructor.charOffset, "Conflicts with member '${name}'.");
      if (constructor.isFactory) {
        deprecated_addCompileTimeError(member.charOffset,
            "Conflicts with factory '${this.name}.${name}'.");
      } else {
        deprecated_addCompileTimeError(member.charOffset,
            "Conflicts with constructor '${this.name}.${name}'.");
      }
    });

    scope.setters.forEach((String name, Builder setter) {
      Builder member = scopeBuilder[name];
      if (member == null || !member.isField || member.isFinal) return;
      // TODO(ahe): charOffset is missing.
      var report = member.isInstanceMember != setter.isInstanceMember
          ? deprecated_addWarning
          : deprecated_addCompileTimeError;
      report(setter.charOffset, "Conflicts with member '${name}'.");
      report(member.charOffset, "Conflicts with setter '${name}'.");
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
  void prepareInitializerInference(
      SourceLibraryBuilder library, ClassBuilder currentClass) {
    scope.forEach((name, builder) {
      builder.prepareInitializerInference(library, this);
    });
  }
}
