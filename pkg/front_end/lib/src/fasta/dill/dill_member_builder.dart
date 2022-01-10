// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_member_builder;

import 'package:kernel/ast.dart'
    show Constructor, Field, Member, Procedure, ProcedureKind;

import '../builder/builder.dart';
import '../builder/member_builder.dart';
import '../builder/library_builder.dart';

import '../kernel/hierarchy/class_member.dart' show ClassMember;
import '../kernel/hierarchy/members_builder.dart' show ClassMembersBuilder;
import '../kernel/member_covariance.dart';
import '../kernel/utils.dart'
    show isRedirectingGenerativeConstructorImplementation;

import '../modifier.dart'
    show abstractMask, constMask, externalMask, finalMask, lateMask, staticMask;

import '../problems.dart' show unhandled;

abstract class DillMemberBuilder extends MemberBuilderImpl {
  @override
  final int modifiers;

  DillMemberBuilder(Member member, Builder parent)
      : modifiers = computeModifiers(member),
        super(parent, member.fileOffset, member.fileUri);

  @override
  Member get member;

  @override
  Iterable<Member> get exportedMembers => [member];

  @override
  String get debugName => "DillMemberBuilder";

  @override
  String get name => member.name.text;

  @override
  bool get isConstructor => member is Constructor;

  @override
  ProcedureKind? get kind {
    final Member member = this.member;
    return member is Procedure ? member.kind : null;
  }

  @override
  bool get isRegularMethod => identical(ProcedureKind.Method, kind);

  @override
  bool get isGetter => identical(ProcedureKind.Getter, kind);

  @override
  bool get isSetter => identical(ProcedureKind.Setter, kind);

  @override
  bool get isOperator => identical(ProcedureKind.Operator, kind);

  @override
  bool get isFactory => identical(ProcedureKind.Factory, kind);

  @override
  bool get isRedirectingGenerativeConstructor {
    return isConstructor &&
        isRedirectingGenerativeConstructorImplementation(member as Constructor);
  }

  @override
  bool get isSynthetic {
    final Member member = this.member;
    return member is Constructor && member.isSynthetic;
  }

  @override
  bool get isAssignable => false;

  @override
  void buildMembers(
      LibraryBuilder library, void Function(Member, BuiltMemberKind) f) {
    throw new UnsupportedError('DillMemberBuilder.buildMembers');
  }

  List<ClassMember>? _localMembers;
  List<ClassMember>? _localSetters;

  @override
  List<ClassMember> get localMembers => _localMembers ??= isSetter
      ? const <ClassMember>[]
      : <ClassMember>[new DillClassMember(this, forSetter: false)];

  @override
  List<ClassMember> get localSetters =>
      _localSetters ??= isSetter || member is Field && member.hasSetter
          ? <ClassMember>[new DillClassMember(this, forSetter: true)]
          : const <ClassMember>[];
}

class DillFieldBuilder extends DillMemberBuilder {
  final Field field;

  DillFieldBuilder(this.field, Builder parent) : super(field, parent);

  @override
  Member get member => field;

  @override
  Member? get readTarget => field;

  @override
  Member? get writeTarget => isAssignable ? field : null;

  @override
  Member? get invokeTarget => field;

  @override
  bool get isField => true;

  @override
  bool get isAssignable => field.hasSetter;
}

class DillGetterBuilder extends DillMemberBuilder {
  final Procedure procedure;

  DillGetterBuilder(this.procedure, Builder parent)
      : assert(procedure.kind == ProcedureKind.Getter),
        super(procedure, parent);

  @override
  Member get member => procedure;

  @override
  Member get readTarget => procedure;

  @override
  Member? get writeTarget => null;

  @override
  Member get invokeTarget => procedure;
}

class DillSetterBuilder extends DillMemberBuilder {
  final Procedure procedure;

  DillSetterBuilder(this.procedure, Builder parent)
      : assert(procedure.kind == ProcedureKind.Setter),
        super(procedure, parent);

  @override
  Member get member => procedure;

  @override
  Member? get readTarget => null;

  @override
  Member get writeTarget => procedure;

  @override
  Member? get invokeTarget => null;
}

class DillMethodBuilder extends DillMemberBuilder {
  final Procedure procedure;

  DillMethodBuilder(this.procedure, Builder parent)
      : assert(procedure.kind == ProcedureKind.Method),
        super(procedure, parent);

  @override
  Member get member => procedure;

  @override
  Member get readTarget => procedure;

  @override
  Member? get writeTarget => null;

  @override
  Member get invokeTarget => procedure;
}

class DillOperatorBuilder extends DillMemberBuilder {
  final Procedure procedure;

  DillOperatorBuilder(this.procedure, Builder parent)
      : assert(procedure.kind == ProcedureKind.Operator),
        super(procedure, parent);

  @override
  Member get member => procedure;

  @override
  Member? get readTarget => null;

  @override
  Member? get writeTarget => null;

  @override
  Member get invokeTarget => procedure;
}

class DillFactoryBuilder extends DillMemberBuilder {
  final Procedure procedure;
  final Procedure? _factoryTearOff;

  DillFactoryBuilder(this.procedure, this._factoryTearOff, Builder parent)
      : super(procedure, parent);

  @override
  Member get member => procedure;

  @override
  Member? get readTarget => _factoryTearOff ?? procedure;

  @override
  Member? get writeTarget => null;

  @override
  Member get invokeTarget => procedure;
}

class DillConstructorBuilder extends DillMemberBuilder {
  final Constructor constructor;
  final Procedure? _constructorTearOff;

  DillConstructorBuilder(
      this.constructor, this._constructorTearOff, Builder parent)
      : super(constructor, parent);

  @override
  Constructor get member => constructor;

  @override
  Member? get readTarget => _constructorTearOff ?? constructor;

  @override
  Member? get writeTarget => null;

  @override
  Constructor get invokeTarget => constructor;
}

class DillClassMember extends BuilderClassMember {
  @override
  final DillMemberBuilder memberBuilder;

  Covariance? _covariance;

  @override
  final bool forSetter;

  DillClassMember(this.memberBuilder, {required this.forSetter})
      // ignore: unnecessary_null_comparison
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
    return member is Procedure && member.isSynthetic;
  }

  @override
  Member getMember(ClassMembersBuilder membersBuilder) => memberBuilder.member;

  @override
  Covariance getCovariance(ClassMembersBuilder membersBuilder) {
    return _covariance ??=
        new Covariance.fromMember(memberBuilder.member, forSetter: forSetter);
  }

  @override
  void inferType(ClassMembersBuilder hierarchy) {
    // Do nothing; this is only for source members.
  }

  @override
  void registerOverrideDependency(Set<ClassMember> overriddenMembers) {
    // Do nothing; this is only for source members.
  }

  @override
  bool isSameDeclaration(ClassMember other) {
    return other is DillClassMember && memberBuilder == other.memberBuilder;
  }

  @override
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
