// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.source_class_builder;

import 'package:kernel/ast.dart' show
    Class,
    Constructor,
    Supertype,
    TreeNode,
    setParents;

import '../errors.dart' show
    internalError,
    inputError;

import '../kernel/kernel_builder.dart' show
    Builder,
    ConstructorReferenceBuilder,
    KernelClassBuilder,
    KernelFieldBuilder,
    KernelFunctionBuilder,
    KernelLibraryBuilder,
    KernelProcedureBuilder,
    KernelTypeBuilder,
    KernelTypeVariableBuilder,
    LibraryBuilder,
    MemberBuilder,
    MetadataBuilder,
    ProcedureBuilder,
    TypeVariableBuilder;

import '../dill/dill_member_builder.dart' show
    DillMemberBuilder;

import '../util/relativize.dart' show
    relativizeUri;

Class initializeClass(Class cls, String name, LibraryBuilder parent,
    int charOffset) {
  cls ??= new Class(name: name);
  cls.fileUri ??= relativizeUri(parent.fileUri);
  if (cls.fileOffset != TreeNode.noOffset) {
    cls.fileOffset = charOffset;
  }
  return cls;
}

class SourceClassBuilder extends KernelClassBuilder {
  final Class cls;

  final Map<String, Builder> constructors = <String, Builder>{};

  final Map<String, Builder> membersInScope;

  final List<ConstructorReferenceBuilder> constructorReferences;

  SourceClassBuilder(List<MetadataBuilder> metadata, int modifiers,
      String name, List<TypeVariableBuilder> typeVariables,
      KernelTypeBuilder supertype, List<KernelTypeBuilder>interfaces,
      Map<String, Builder> members, LibraryBuilder parent,
      this.constructorReferences, int charOffset, [Class cls])
      : cls = initializeClass(cls, name, parent, charOffset),
        membersInScope = computeMembersInScope(members, name),
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
        cls.addMember(builder.build(library.library));
      } else if (builder is KernelFunctionBuilder) {
        cls.addMember(builder.build(library.library));
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
    cls.supertype = supertype?.buildSupertype();
    // TODO(ahe): If `cls.supertype` is null, and this isn't Object, report a
    // compile-time error.
    cls.isAbstract = isAbstract;
    if (interfaces != null) {
      for (KernelTypeBuilder interface in interfaces) {
        Supertype supertype = interface.buildSupertype();
        if (supertype != null) {
          // TODO(ahe): Report an error if supertype is null.
          cls.implementedTypes.add(supertype);
        }
      }
    }
    return cls;
  }

  int convertConstructors(KernelLibraryBuilder library) {
    List<String> oldConstructorNames = <String>[];
    // TODO(sigmund): should be `covariant MemberBuilder`
    members.forEach((String name, dynamic b) {
      MemberBuilder builder = b;
      if (isConstructorName(name, this.name)) {
        oldConstructorNames.add(name);
        String newName = "";
        int index = name.indexOf(".");
        if (index != -1) {
          newName = name.substring(index + 1);
        }
        if (builder is KernelProcedureBuilder) {
          Builder constructor = builder.toConstructor(newName, typeVariables);
          Builder other = members[newName];
          if (other != null) {
            return inputError(null, null, "Constructor name '$newName' "
                "conflicts with other declaration.");
          }
          constructors[newName] = constructor;
        } else {
          return inputError(null, null, "Expected a constructor or factory.");
        }
      }
    });
    for (String name in oldConstructorNames) {
      members.remove(name);
    }
    constructors.forEach((String name, Builder builder) {
      members[name] = builder;
    });
    return oldConstructorNames.length;
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

bool isConstructorName(String name, String className) {
  if (name.startsWith(className)) {
    if (name.length == className.length) return true;
    if (name.startsWith(".", className.length)) return true;
  }
  return false;
}

Map<String, Builder> computeMembersInScope(Map<String, Builder> members,
    String className) {
  Map<String, Builder> membersInScope = <String, Builder>{};
  members.forEach((String name, Builder builder) {
    if (builder is ProcedureBuilder) {
      if (isConstructorName(builder.name, className)) return;
    }
    if (name.indexOf(".") != -1) {
      inputError(null, null, "Only constructors and factories can have names "
          "containing a period ('.'): $name");
    }
    membersInScope[name] = builder;
  });
  return membersInScope;
}
