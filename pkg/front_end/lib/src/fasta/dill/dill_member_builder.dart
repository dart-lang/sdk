// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_member_builder;

import 'package:kernel/ast.dart'
    show Constructor, Field, Member, Procedure, ProcedureKind;

import '../builder/builder.dart';
import '../builder/member_builder.dart';
import '../builder/library_builder.dart';

import '../kernel/class_hierarchy_builder.dart'
    show ClassHierarchyBuilder, ClassMember;
import '../kernel/kernel_builder.dart'
    show isRedirectingGenerativeConstructorImplementation;

import '../modifier.dart'
    show abstractMask, constMask, externalMask, finalMask, lateMask, staticMask;

import '../problems.dart' show unhandled;

class DillMemberBuilder extends MemberBuilderImpl {
  final int modifiers;

  final Member member;

  DillMemberBuilder(Member member, Builder parent)
      : modifiers = computeModifiers(member),
        member = member,
        super(parent, member.fileOffset);

  String get debugName => "DillMemberBuilder";

  String get name => member.name.name;

  bool get isConstructor => member is Constructor;

  ProcedureKind get kind {
    final Member member = this.member;
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
    final Member member = this.member;
    return member is Constructor && member.isSynthetic;
  }

  bool get isField => member is Field;

  @override
  bool get isAssignable => member is Field && member.hasSetter;

  @override
  Member get readTarget {
    if (isField) {
      return member;
    } else if (isConstructor) {
      return null;
    }
    switch (kind) {
      case ProcedureKind.Method:
      case ProcedureKind.Getter:
        return member;
      case ProcedureKind.Operator:
      case ProcedureKind.Setter:
      case ProcedureKind.Factory:
        return null;
    }
    throw unhandled('ProcedureKind', '$kind', charOffset, fileUri);
  }

  @override
  Member get writeTarget {
    if (isField) {
      return isAssignable ? member : null;
    } else if (isConstructor) {
      return null;
    }
    switch (kind) {
      case ProcedureKind.Setter:
        return member;
      case ProcedureKind.Method:
      case ProcedureKind.Getter:
      case ProcedureKind.Operator:
      case ProcedureKind.Factory:
        return null;
    }
    throw unhandled('ProcedureKind', '$kind', charOffset, fileUri);
  }

  @override
  Member get invokeTarget {
    if (isField) {
      return member;
    } else if (isConstructor) {
      return member;
    }
    switch (kind) {
      case ProcedureKind.Method:
      case ProcedureKind.Getter:
      case ProcedureKind.Operator:
      case ProcedureKind.Factory:
        return member;
      case ProcedureKind.Setter:
        return null;
    }
    throw unhandled('ProcedureKind', '$kind', charOffset, fileUri);
  }

  @override
  void buildMembers(
      LibraryBuilder library, void Function(Member, BuiltMemberKind) f) {
    throw new UnsupportedError('DillMemberBuilder.buildMembers');
  }

  @override
  List<ClassMember> get localMembers => isSetter
      ? const <ClassMember>[]
      : <ClassMember>[new DillClassMember(this, forSetter: false)];

  @override
  List<ClassMember> get localSetters =>
      isSetter || member is Field && member.hasSetter
          ? <ClassMember>[new DillClassMember(this, forSetter: true)]
          : const <ClassMember>[];
}

class DillClassMember extends BuilderClassMember {
  @override
  final DillMemberBuilder memberBuilder;

  @override
  final bool forSetter;

  DillClassMember(this.memberBuilder, {this.forSetter})
      : assert(forSetter != null);

  @override
  bool get isSourceDeclaration => false;

  @override
  bool get isInternalImplementation {
    Member member = memberBuilder.member;
    return member is Field && member.isInternalImplementation;
  }

  @override
  bool get isProperty =>
      memberBuilder.kind == null ||
      memberBuilder.kind == ProcedureKind.Getter ||
      memberBuilder.kind == ProcedureKind.Setter;

  @override
  bool get isSynthesized {
    Member member = memberBuilder.member;
    return member is Procedure &&
        (member.isMemberSignature ||
            (member.isForwardingStub && !member.isForwardingSemiStub));
  }

  @override
  bool get isFunction => !isProperty;

  @override
  void inferType(ClassHierarchyBuilder hierarchy) {
    // Do nothing; this is only for source members.
  }

  @override
  void registerOverrideDependency(ClassMember overriddenMember) {
    // Do nothing; this is only for source members.
  }

  String toString() => 'DillClassMember($memberBuilder,forSetter=${forSetter})';
}

int computeModifiers(Member member) {
  int modifier = member.isAbstract ? abstractMask : 0;
  modifier |= member.isExternal ? externalMask : 0;
  if (member is Field) {
    modifier |= member.isConst ? constMask : 0;
    modifier |= member.isFinal ? finalMask : 0;
    modifier |= member.isLate ? lateMask : 0;
    modifier |= member.isStatic ? staticMask : 0;
  } else if (member is Procedure) {
    modifier |= member.isConst ? constMask : 0;
    modifier |= member.isStatic ? staticMask : 0;
  } else if (member is Constructor) {
    modifier |= member.isConst ? constMask : 0;
  } else {
    dynamic parent = member.parent;
    unhandled("${member.runtimeType}", "computeModifiers", member.fileOffset,
        Uri.base.resolve(parent.fileUri));
  }
  return modifier;
}
