// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_member_builder;

import 'package:kernel/ast.dart'
    show Constructor, Field, Member, Procedure, ProcedureKind;

import '../errors.dart' show internalError;

import '../kernel/kernel_builder.dart'
    show
        Builder,
        MemberBuilder,
        isRedirectingGenerativeConstructorImplementation;

import '../modifier.dart'
    show abstractMask, constMask, externalMask, finalMask, staticMask;

class DillMemberBuilder extends MemberBuilder {
  final int modifiers;

  final Member member;

  DillMemberBuilder(Member member, Builder parent)
      : modifiers = computeModifiers(member),
        member = member,
        super(parent, member.fileOffset);

  Member get target => member;

  String get name => member.name.name;

  bool get isConstructor => member is Constructor;

  ProcedureKind get kind {
    final member = this.member;
    return member is Procedure ? member.kind : null;
  }

  bool get isRegularMethod => identical(ProcedureKind.Method, kind);

  bool get isGetter => identical(ProcedureKind.Getter, kind);

  bool get isSetter => identical(ProcedureKind.Setter, kind);

  bool get isOperator => identical(ProcedureKind.Operator, kind);

  bool get isFactory => identical(ProcedureKind.Factory, kind);

  bool get isRedirectingGenerativeConstructor {
    return isConstructor &&
        isRedirectingGenerativeConstructorImplementation(member);
  }

  bool get isSynthetic {
    // TODO(ahe): Kernel should eventually support a synthetic bit.
    return isConstructor &&
        name == "" &&
        (charOffset == parent.charOffset || charOffset == -1);
  }
}

int computeModifiers(Member member) {
  int modifier = member.isAbstract ? abstractMask : 0;
  modifier |= member.isExternal ? externalMask : 0;
  if (member is Field) {
    modifier |= member.isConst ? constMask : 0;
    modifier |= member.isFinal ? finalMask : 0;
    modifier |= member.isStatic ? staticMask : 0;
  } else if (member is Procedure) {
    modifier |= member.isConst ? constMask : 0;
    modifier |= member.isStatic ? staticMask : 0;
  } else if (member is Constructor) {
    modifier |= member.isConst ? constMask : 0;
  } else {
    internalError("Unhandled: ${member.runtimeType}");
  }
  return modifier;
}
