// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart'
    show
        Annotatable,
        Constructor,
        Field,
        FunctionNode,
        Member,
        Name,
        Procedure,
        ProcedureKind,
        ProcedureStubKind;
import 'package:kernel/canonical_name.dart';

import '../builder/builder.dart';
import '../builder/constructor_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/field_builder.dart';
import '../builder/member_builder.dart';
import '../builder/procedure_builder.dart';
import '../kernel/hierarchy/class_member.dart';
import '../kernel/hierarchy/members_builder.dart' show ClassMembersBuilder;
import '../kernel/member_covariance.dart';
import 'dill_class_builder.dart';
import 'dill_library_builder.dart';

abstract class DillMemberBuilder extends MemberBuilderImpl {
  @override
  final DillLibraryBuilder libraryBuilder;

  @override
  final DeclarationBuilder? declarationBuilder;

  DillMemberBuilder(this.libraryBuilder, this.declarationBuilder);

  Member get member;

  @override
  int get fileOffset => member.fileOffset;

  @override
  Uri get fileUri => member.fileUri;

  @override
  Builder get parent => declarationBuilder ?? libraryBuilder;

  @override
  String get name => member.name.text;

  @override
  Name get memberName => member.name;

  @override
  bool get isConstructor => member is Constructor;

  ProcedureKind? get kind {
    final Member member = this.member;
    return member is Procedure
        ?
        // Coverage-ignore(suite): Not run.
        member.kind
        : null;
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
  bool get isAbstract => member.isAbstract;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isExternal => member.isExternal;

  @override
  bool get isSynthetic {
    final Member member = this.member;
    return member is Constructor && member.isSynthetic;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAssignable => false;

  List<ClassMember>? _localMembers;
  List<ClassMember>? _localSetters;

  @override
  List<ClassMember> get localMembers => _localMembers ??= isSetter
      ? const <ClassMember>[]
      : <ClassMember>[
          new DillClassMember(
              this,
              member is Field || isGetter
                  ? ClassMemberKind.Getter
                  : ClassMemberKind.Method)
        ];

  @override
  List<ClassMember> get localSetters =>
      _localSetters ??= isSetter || member is Field && member.hasSetter
          ? <ClassMember>[new DillClassMember(this, ClassMemberKind.Setter)]
          : const <ClassMember>[];

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Annotatable> get annotatables => [member];
}

class DillFieldBuilder extends DillMemberBuilder implements FieldBuilder {
  @override
  final Field field;

  DillFieldBuilder(this.field, super.libraryBuilder,
      [super.declarationBuilder]);

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

  @override
  // Coverage-ignore(suite): Not run.
  bool get isConst => field.isConst;

  @override
  bool get isStatic => field.isStatic;

  @override
  Iterable<Reference> get exportedMemberReferences =>
      [field.getterReference, if (field.hasSetter) field.setterReference!];

  @override
  // Coverage-ignore(suite): Not run.
  bool get isProperty => true;
}

abstract class DillProcedureBuilder extends DillMemberBuilder
    implements ProcedureBuilder {
  @override
  final Procedure procedure;

  DillProcedureBuilder(this.procedure, super.libraryBuilder,
      [super.declarationBuilder]);

  @override
  ProcedureKind get kind => procedure.kind;

  @override
  FunctionNode get function => procedure.function;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isConst => procedure.isConst;

  @override
  bool get isStatic => procedure.isStatic;

  @override
  Iterable<Reference> get exportedMemberReferences => [procedure.reference];
}

class DillGetterBuilder extends DillProcedureBuilder {
  DillGetterBuilder(super.procedure, super.libraryBuilder,
      [super.declarationBuilder])
      : assert(procedure.kind == ProcedureKind.Getter);

  @override
  // Coverage-ignore(suite): Not run.
  bool get isProperty => true;

  @override
  Member get member => procedure;

  @override
  Member get readTarget => procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  Member get invokeTarget => procedure;
}

class DillSetterBuilder extends DillProcedureBuilder {
  DillSetterBuilder(super.procedure, super.libraryBuilder,
      [super.declarationBuilder])
      : assert(procedure.kind == ProcedureKind.Setter);

  @override
  // Coverage-ignore(suite): Not run.
  bool get isProperty => true;

  @override
  Member get member => procedure;

  @override
  Member? get readTarget => null;

  @override
  Member get writeTarget => procedure;

  @override
  Member? get invokeTarget => null;
}

class DillMethodBuilder extends DillProcedureBuilder {
  DillMethodBuilder(super.procedure, super.libraryBuilder,
      [super.declarationBuilder])
      : assert(procedure.kind == ProcedureKind.Method);

  @override
  // Coverage-ignore(suite): Not run.
  bool get isProperty => false;

  @override
  Member get member => procedure;

  @override
  Member get readTarget => procedure;

  @override
  Member? get writeTarget => null;

  @override
  Member get invokeTarget => procedure;
}

class DillOperatorBuilder extends DillProcedureBuilder {
  DillOperatorBuilder(super.procedure, super.libraryBuilder,
      [super.declarationBuilder])
      : assert(procedure.kind == ProcedureKind.Operator);

  @override
  // Coverage-ignore(suite): Not run.
  bool get isProperty => false;

  @override
  Member get member => procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get readTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Member get invokeTarget => procedure;
}

class DillFactoryBuilder extends DillProcedureBuilder {
  final Procedure? _factoryTearOff;

  DillFactoryBuilder(super.procedure, this._factoryTearOff,
      super.libraryBuilder, DillClassBuilder super.declarationBuilder);

  @override
  // Coverage-ignore(suite): Not run.
  bool get isProperty => false;

  @override
  Member get member => procedure;

  @override
  Member? get readTarget => _factoryTearOff ?? procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  Member get invokeTarget => procedure;
}

class DillConstructorBuilder extends DillMemberBuilder
    implements ConstructorBuilder {
  final Constructor constructor;
  final Procedure? _constructorTearOff;

  DillConstructorBuilder(this.constructor, this._constructorTearOff,
      super.libraryBuilder, ClassBuilder super.declarationBuilder);

  @override
  // Coverage-ignore(suite): Not run.
  bool get isProperty => false;

  @override
  FunctionNode get function => constructor.function;

  @override
  Constructor get member => constructor;

  @override
  Member get readTarget => _constructorTearOff ?? constructor;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  Constructor get invokeTarget => constructor;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isConst => constructor.isConst;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [constructor.reference];
}

class DillClassMember extends BuilderClassMember {
  @override
  final DillMemberBuilder memberBuilder;

  Covariance? _covariance;

  @override
  final ClassMemberKind memberKind;

  DillClassMember(this.memberBuilder, this.memberKind);

  @override
  bool get isSourceDeclaration => false;

  @override
  bool get isExtensionTypeMember {
    Member member = memberBuilder.member;
    return member.isExtensionTypeMember;
  }

  @override
  bool get isInternalImplementation {
    Member member = memberBuilder.member;
    return member.isInternalImplementation;
  }

  @override
  bool get isNoSuchMethodForwarder {
    Member member = memberBuilder.member;
    return member is Procedure &&
        member.stubKind == ProcedureStubKind.NoSuchMethodForwarder;
  }

  @override
  bool get isSynthesized {
    Member member = memberBuilder.member;
    return member is Procedure && member.isSynthetic;
  }

  @override
  Member getMember(ClassMembersBuilder membersBuilder) => memberBuilder.member;

  @override
  Member? getTearOff(ClassMembersBuilder membersBuilder) {
    Member? readTarget = memberBuilder.readTarget;
    return readTarget != memberBuilder.invokeTarget ? readTarget : null;
  }

  @override
  Covariance getCovariance(ClassMembersBuilder membersBuilder) {
    return _covariance ??=
        new Covariance.fromMember(memberBuilder.member, forSetter: forSetter);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void inferType(ClassMembersBuilder hierarchy) {
    // Do nothing; this is only for source members.
  }

  @override
  // Coverage-ignore(suite): Not run.
  void registerOverrideDependency(Set<ClassMember> overriddenMembers) {
    // Do nothing; this is only for source members.
  }

  @override
  bool isSameDeclaration(ClassMember other) {
    return other is DillClassMember && memberBuilder == other.memberBuilder;
  }

  @override
  MemberResult getMemberResult(ClassMembersBuilder membersBuilder) {
    Member member = getMember(membersBuilder);
    if (member is Procedure &&
        member.stubKind == ProcedureStubKind.RepresentationField) {
      return new TypeDeclarationInstanceMemberResult(
          getMember(membersBuilder), memberKind,
          isDeclaredAsField: true);
    }
    return super.getMemberResult(membersBuilder);
  }

  @override
  String toString() => 'DillClassMember($memberBuilder,forSetter=${forSetter})';
}
