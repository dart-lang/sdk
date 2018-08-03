// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_class_builder;

import 'package:kernel/ast.dart' show Class, DartType, Member;

import '../problems.dart' show unimplemented;

import '../kernel/kernel_builder.dart'
    show
        KernelClassBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        MemberBuilder,
        Scope;

import '../modifier.dart' show abstractMask;

import 'dill_member_builder.dart' show DillMemberBuilder;

import 'dill_library_builder.dart' show DillLibraryBuilder;

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
            new Scope(<String, MemberBuilder>{}, null, null, "constructors",
                isModifiable: false),
            parent,
            cls.fileOffset);

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

  KernelTypeBuilder get mixedInType => unimplemented("mixedInType", -1, null);

  void set mixedInType(KernelTypeBuilder mixin) {
    unimplemented("mixedInType=", -1, null);
  }
}

int computeModifiers(Class cls) {
  return cls.isAbstract ? abstractMask : 0;
}
