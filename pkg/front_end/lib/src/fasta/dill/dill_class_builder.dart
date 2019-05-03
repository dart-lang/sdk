// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_class_builder;

import 'package:kernel/ast.dart'
    show Class, DartType, Member, Supertype, TypeParameter;

import '../problems.dart' show unimplemented;

import '../kernel/kernel_builder.dart'
    show
        KernelClassBuilder,
        KernelTypeBuilder,
        KernelTypeVariableBuilder,
        LibraryBuilder,
        MemberBuilder,
        Scope,
        TypeVariableBuilder;

import '../modifier.dart' show abstractMask;

import 'dill_library_builder.dart' show DillLibraryBuilder;

import 'dill_member_builder.dart' show DillMemberBuilder;

class DillClassBuilder extends KernelClassBuilder {
  final Class cls;

  DillClassBuilder(Class cls, DillLibraryBuilder parent)
      : cls = cls,
        super(
            null,
            computeModifiers(cls),
            cls.name,
            null,
            null,
            null,
            new Scope(<String, MemberBuilder>{}, <String, MemberBuilder>{},
                parent.scope, "class ${cls.name}", isModifiable: false),
            new Scope(<String, MemberBuilder>{}, null, null, cls.name,
                isModifiable: false),
            parent,
            cls.fileOffset);

  List<TypeVariableBuilder> get typeVariables {
    List<TypeVariableBuilder> typeVariables = super.typeVariables;
    if (typeVariables == null && cls.typeParameters.isNotEmpty) {
      typeVariables = super.typeVariables =
          computeTypeVariableBuilders(library, cls.typeParameters);
    }
    return typeVariables;
  }

  Uri get fileUri => cls.fileUri;

  KernelTypeBuilder get supertype {
    KernelTypeBuilder supertype = super.supertype;
    if (supertype == null) {
      Supertype targetSupertype = cls.supertype;
      if (targetSupertype == null) return null;
      super.supertype =
          supertype = computeTypeBuilder(library, targetSupertype);
    }
    return supertype;
  }

  @override
  Class get actualCls => cls;

  void addMember(Member member) {
    DillMemberBuilder builder = new DillMemberBuilder(member, this);
    String name = member.name.name;
    if (builder.isConstructor || builder.isFactory) {
      constructorScopeBuilder.addMember(name, builder);
    } else if (builder.isSetter) {
      scopeBuilder.addSetter(name, builder);
    } else {
      scopeBuilder.addMember(name, builder);
    }
  }

  @override
  int get typeVariablesCount => cls.typeParameters.length;

  @override
  List<DartType> buildTypeArguments(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    // For performance reasons, [typeVariables] aren't restored from [target].
    // So, if [arguments] is null, the default types should be retrieved from
    // [cls.typeParameters].
    if (arguments == null) {
      List<DartType> result = new List<DartType>.filled(
          cls.typeParameters.length, null,
          growable: true);
      for (int i = 0; i < result.length; ++i) {
        result[i] = cls.typeParameters[i].defaultType;
      }
      return result;
    }

    // [arguments] != null
    List<DartType> result =
        new List<DartType>.filled(arguments.length, null, growable: true);
    for (int i = 0; i < result.length; ++i) {
      result[i] = arguments[i].build(library);
    }
    return result;
  }

  /// Returns true if this class is the result of applying a mixin to its
  /// superclass.
  bool get isMixinApplication => cls.isMixinApplication;

  KernelTypeBuilder get mixedInType {
    return computeTypeBuilder(library, cls.mixedInType);
  }

  List<KernelTypeBuilder> get interfaces {
    if (cls.implementedTypes.isEmpty) return null;
    if (super.interfaces == null) {
      List<KernelTypeBuilder> result =
          new List<KernelTypeBuilder>(cls.implementedTypes.length);
      for (int i = 0; i < result.length; i++) {
        result[i] = computeTypeBuilder(library, cls.implementedTypes[i]);
      }
      super.interfaces = result;
    }
    return super.interfaces;
  }

  void set mixedInType(KernelTypeBuilder mixin) {
    unimplemented("mixedInType=", -1, null);
  }
}

int computeModifiers(Class cls) {
  return cls.isAbstract ? abstractMask : 0;
}

KernelTypeBuilder computeTypeBuilder(
    DillLibraryBuilder library, Supertype supertype) {
  return supertype == null
      ? null
      : library.loader.computeTypeBuilder(supertype.asInterfaceType);
}

List<TypeVariableBuilder> computeTypeVariableBuilders(
    DillLibraryBuilder library, List<TypeParameter> typeParameters) {
  if (typeParameters == null || typeParameters.length == 0) return null;
  List<TypeVariableBuilder> result =
      new List.filled(typeParameters.length, null);
  for (int i = 0; i < result.length; i++) {
    result[i] =
        new KernelTypeVariableBuilder.fromKernel(typeParameters[i], library);
  }
  return result;
}
