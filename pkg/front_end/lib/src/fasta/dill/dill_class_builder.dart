// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_class_builder;

import 'package:kernel/ast.dart'
    show Class, Constructor, Member, Procedure, ProcedureKind;

import '../errors.dart' show internalError;

import '../kernel/kernel_builder.dart'
    show Builder, KernelClassBuilder, KernelTypeBuilder;

import '../modifier.dart' show abstractMask;

import 'dill_member_builder.dart' show DillMemberBuilder;

import 'dill_library_builder.dart' show DillLibraryBuilder;

class DillClassBuilder extends KernelClassBuilder {
  final Class cls;

  final Map<String, Builder> constructors = <String, Builder>{};

  DillClassBuilder(Class cls, DillLibraryBuilder parent)
      : cls = cls,
        super(null, computeModifiers(cls), cls.name, null, null, null,
            <String, Builder>{}, parent, cls.fileOffset);

  void addMember(Member member) {
    DillMemberBuilder builder = new DillMemberBuilder(member, this);
    String name = member.name.name;
    if (member is Constructor ||
        (member is Procedure && member.kind == ProcedureKind.Factory)) {
      constructors[name] = builder;
    } else {
      DillMemberBuilder existing = members[name];
      if (existing == null) {
        members[name] = builder;
      } else {
        existing.next = builder;
      }
    }
  }

  /// Returns true if this class is the result of applying a mixin to its
  /// superclass.
  bool get isMixinApplication => cls.isMixinApplication;

  KernelTypeBuilder get mixedInType => internalError("Not implemented.");

  Builder findConstructorOrFactory(String name) => constructors[name];
}

int computeModifiers(Class cls) {
  return cls.isAbstract ? abstractMask : 0;
}
