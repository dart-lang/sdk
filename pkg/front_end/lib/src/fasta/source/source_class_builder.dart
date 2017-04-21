// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_class_builder;

import 'package:kernel/ast.dart'
    show Class, Constructor, Supertype, TreeNode, setParents;

import '../errors.dart' show internalError;

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
        ProcedureBuilder,
        TypeVariableBuilder;

import '../dill/dill_member_builder.dart' show DillMemberBuilder;

import '../util/relativize.dart' show relativizeUri;

Class initializeClass(
    Class cls, String name, LibraryBuilder parent, int charOffset) {
  cls ??= new Class(name: name);
  cls.fileUri ??= relativizeUri(parent.fileUri);
  if (cls.fileOffset == TreeNode.noOffset) {
    cls.fileOffset = charOffset;
  }
  return cls;
}

class SourceClassBuilder extends KernelClassBuilder {
  final Class cls;

  final Map<String, Builder> constructors;

  final Map<String, Builder> membersInScope;

  final List<ConstructorReferenceBuilder> constructorReferences;

  final KernelTypeBuilder mixedInType;

  SourceClassBuilder(
      List<MetadataBuilder> metadata,
      int modifiers,
      String name,
      List<TypeVariableBuilder> typeVariables,
      KernelTypeBuilder supertype,
      List<KernelTypeBuilder> interfaces,
      Map<String, Builder> members,
      LibraryBuilder parent,
      this.constructorReferences,
      int charOffset,
      [Class cls,
      this.mixedInType])
      : cls = initializeClass(cls, name, parent, charOffset),
        membersInScope = computeMembersInScope(members),
        constructors = computeConstructors(members),
        super(metadata, modifiers, name, typeVariables, supertype, interfaces,
            members, parent, charOffset);

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

  Class build(KernelLibraryBuilder library) {
    void buildBuilder(Builder builder) {
      if (builder is KernelFieldBuilder) {
        // TODO(ahe): It would be nice to have a common interface for the build
        // method to avoid duplicating these two cases.
        cls.addMember(builder.build(library));
      } else if (builder is KernelFunctionBuilder) {
        cls.addMember(builder.build(library));
      } else {
        internalError("Unhandled builder: ${builder.runtimeType}");
      }
    }

    members.forEach((String name, Builder builder) {
      do {
        buildBuilder(builder);
        builder = builder.next;
      } while (builder != null);
    });
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
    return cls;
  }

  Builder findConstructorOrFactory(String name) => constructors[name];

  void addSyntheticConstructor(Constructor constructor) {
    String name = constructor.name.name;
    cls.constructors.add(constructor);
    constructor.parent = cls;
    DillMemberBuilder memberBuilder = new DillMemberBuilder(constructor, this);
    memberBuilder.next = constructors[name];
    constructors[name] = memberBuilder;
  }
}

Map<String, Builder> computeMembersInScope(Map<String, Builder> members) {
  Map<String, Builder> membersInScope = <String, Builder>{};
  members.forEach((String name, Builder builder) {
    if (builder is ProcedureBuilder) {
      if (builder.isConstructor || builder.isFactory) return;
    }
    membersInScope[name] = builder;
  });
  return membersInScope;
}

Map<String, Builder> computeConstructors(Map<String, Builder> members) {
  Map<String, Builder> constructors = <String, Builder>{};
  members.forEach((String name, Builder builder) {
    if (builder is ProcedureBuilder &&
        (builder.isConstructor || builder.isFactory)) {
      constructors[name] = builder;
    }
  });
  return constructors;
}
