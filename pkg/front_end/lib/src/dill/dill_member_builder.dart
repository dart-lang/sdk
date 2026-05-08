// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart'
    show
        Constructor,
        Field,
        Member,
        Name,
        Procedure,
        ProcedureKind,
        ProcedureStubKind;
import 'package:kernel/canonical_name.dart';
import 'package:kernel/names.dart';

import '../base/uri_offset.dart';
import '../builder/builder.dart';
import '../builder/constructor_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/factory_builder.dart';
import '../builder/function_signature.dart';
import '../builder/member_builder.dart';
import '../builder/method_builder.dart';
import '../builder/property_builder.dart';
import '../kernel/hierarchy/class_member.dart';
import '../kernel/hierarchy/members_builder.dart' show ClassMembersBuilder;
import '../kernel/member_covariance.dart';
import 'dill_builder_mixins.dart';
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
  bool get isSynthetic {
    final Member member = this.member;
    return member is Constructor && member.isSynthetic;
  }

  @override
  String toString() {
    String fullName = member.name.text;
    if (member.enclosingTypeDeclaration != null) {
      fullName = '${member.enclosingTypeDeclaration?.name}.$fullName';
    }
    return '${runtimeType}($fullName)';
  }
}

class DillFieldBuilder extends DillMemberBuilder
    with DillFieldBuilderMixin
    implements PropertyBuilder {
  final Field field;

  DillFieldBuilder(
    this.field,
    super.libraryBuilder, [
    super.declarationBuilder,
  ]);

  @override
  Member get member => field;

  @override
  Member? get readTarget => field;

  @override
  Reference get readTargetReference => field.getterReference;

  @override
  Member? get writeTarget => field.hasSetter ? field : null;

  @override
  Reference? get writeTargetReference => field.setterReference;

  @override
  bool get hasConstField => field.isConst;

  @override
  bool get isStatic => field.isStatic;

  @override
  Iterable<Reference> get exportedMemberReferences => [
    field.getterReference,
    if (field.hasSetter) field.setterReference!,
  ];

  @override
  // Coverage-ignore(suite): Not run.
  bool get isEnumElement => field.isEnumElement;

  @override
  FieldQuality get fieldQuality => FieldQuality.Concrete;

  @override
  GetterQuality get getterQuality => GetterQuality.Implicit;

  @override
  SetterQuality get setterQuality =>
      field.hasSetter ? SetterQuality.Implicit : SetterQuality.Absent;

  @override
  UriOffsetLength get getterUriOffset =>
      new UriOffsetLength(fileUri, fileOffset, field.name.text.length);

  @override
  UriOffsetLength? get setterUriOffset => hasSetter
      ? new UriOffsetLength(fileUri, fileOffset, field.name.text.length)
      : null;
}

abstract class _DillProcedureBuilder extends DillMemberBuilder {
  final Procedure _procedure;

  _DillProcedureBuilder(
    this._procedure,
    super.libraryBuilder, [
    super.declarationBuilder,
  ]);

  @override
  bool get isStatic => _procedure.isStatic;

  @override
  Iterable<Reference> get exportedMemberReferences => [_procedure.reference];
}

class DillGetterBuilder extends _DillProcedureBuilder
    with DillGetterBuilderMixin
    implements PropertyBuilder {
  DillGetterBuilder(
    super.procedure,
    super.libraryBuilder, [
    super.declarationBuilder,
  ]) : assert(procedure.kind == ProcedureKind.Getter);

  @override
  Member get member => _procedure;

  @override
  Member get readTarget => _procedure;

  @override
  Reference get readTargetReference => _procedure.reference;

  @override
  Member get invokeTarget => _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => _procedure.reference;

  @override
  FieldQuality get fieldQuality => FieldQuality.Absent;

  @override
  GetterQuality get getterQuality => _procedure.isExternal
      ? GetterQuality.External
      : _procedure.isAbstract
      ? GetterQuality.Abstract
      : GetterQuality.Concrete;

  @override
  SetterQuality get setterQuality => SetterQuality.Absent;

  @override
  UriOffsetLength get getterUriOffset =>
      new UriOffsetLength(fileUri, fileOffset, _procedure.name.text.length);
}

class DillSetterBuilder extends _DillProcedureBuilder
    with DillSetterBuilderMixin
    implements PropertyBuilder {
  DillSetterBuilder(
    super.procedure,
    super.libraryBuilder, [
    super.declarationBuilder,
  ]) : assert(procedure.kind == ProcedureKind.Setter);

  @override
  Member get member => _procedure;

  @override
  Member get writeTarget => _procedure;

  @override
  Reference get writeTargetReference => _procedure.reference;

  @override
  FieldQuality get fieldQuality => FieldQuality.Absent;

  @override
  // Coverage-ignore(suite): Not run.
  GetterQuality get getterQuality => GetterQuality.Absent;

  @override
  SetterQuality get setterQuality => _procedure.isExternal
      ? SetterQuality.External
      : _procedure.isAbstract
      ? SetterQuality.Abstract
      : SetterQuality.Concrete;

  @override
  UriOffsetLength get setterUriOffset =>
      new UriOffsetLength(fileUri, fileOffset, _procedure.name.text.length);
}

class DillMethodBuilder extends _DillProcedureBuilder
    with DillMethodBuilderMixin
    implements MethodBuilder {
  DillMethodBuilder(
    super.procedure,
    super.libraryBuilder, [
    super.declarationBuilder,
  ]) : assert(procedure.kind == ProcedureKind.Method);

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAbstract => _procedure.isAbstract;

  @override
  Member get member => _procedure;

  @override
  Member get readTarget => _procedure;

  @override
  Reference get readTargetReference => _procedure.reference;

  @override
  Member get invokeTarget => _procedure;

  @override
  Reference get invokeTargetReference => _procedure.reference;

  @override
  UriOffsetLength get uriOffset =>
      new UriOffsetLength(fileUri, fileOffset, _procedure.name.text.length);
}

class DillOperatorBuilder extends _DillProcedureBuilder
    with DillOperatorBuilderMixin
    implements MethodBuilder {
  DillOperatorBuilder(
    super.procedure,
    super.libraryBuilder, [
    super.declarationBuilder,
  ]) : assert(procedure.kind == ProcedureKind.Operator);

  @override
  bool get isAbstract => _procedure.isAbstract;

  @override
  Member get member => _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Member get invokeTarget => _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => _procedure.reference;

  @override
  UriOffsetLength get uriOffset => new UriOffsetLength(
    fileUri,
    fileOffset,
    _procedure.name == unaryMinusName ? 1 : _procedure.name.text.length,
  );
}

class DillFactoryBuilder extends _DillProcedureBuilder
    with DillFactoryBuilderMixin
    implements FactoryBuilder {
  final Procedure? _factoryTearOff;

  DillFactoryBuilder(
    super.procedure,
    this._factoryTearOff,
    super.libraryBuilder,
    DillClassBuilder super.declarationBuilder,
  );

  @override
  Member get member => _procedure;

  @override
  Member? get readTarget => _factoryTearOff ?? _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference =>
      (_factoryTearOff ?? _procedure).reference;

  @override
  Member get invokeTarget => _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => _procedure.reference;

  @override
  FunctionSignature get signature =>
      new FunctionNodeSignature(_procedure.function);

  @override
  // Coverage-ignore(suite): Not run.
  bool get isConst => _procedure.isConst;
}

class DillConstructorBuilder extends DillMemberBuilder
    with DillConstructorBuilderMixin
    implements ConstructorBuilder {
  final Constructor _constructor;
  final Procedure? _constructorTearOff;

  DillConstructorBuilder(
    this._constructor,
    this._constructorTearOff,
    super.libraryBuilder,
    ClassBuilder super.declarationBuilder,
  );

  @override
  FunctionSignature get signature =>
      new FunctionNodeSignature(_constructor.function);

  @override
  Constructor get member => _constructor;

  @override
  Member get readTarget => _constructorTearOff ?? _constructor;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference =>
      (_constructorTearOff ?? _constructor).reference;

  @override
  Constructor get invokeTarget => _constructor;

  @override
  Reference get invokeTargetReference => _constructor.reference;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isConst => _constructor.isConst;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [_constructor.reference];
}

class DillClassMember extends BuilderClassMember {
  @override
  final DillMemberBuilder memberBuilder;

  @override
  final UriOffsetLength uriOffset;

  Covariance? _covariance;

  @override
  final ClassMemberKind memberKind;

  DillClassMember(this.memberBuilder, this.memberKind, this.uriOffset)
    : assert(
        !memberBuilder.member.isInternalImplementation,
        "ClassMember should not be created for internal implementation "
        "member $memberBuilder.",
      );

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSourceDeclaration => false;

  @override
  bool get isExtensionTypeMember {
    Member member = memberBuilder.member;
    return member.isExtensionTypeMember;
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
  bool get isAbstract {
    Member member = memberBuilder.member;
    return member is Procedure && member.isAbstract;
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
    return _covariance ??= new Covariance.fromMember(
      memberBuilder.member,
      forSetter: forSetter,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void inferType(ClassMembersBuilder hierarchy) {
    // Do nothing; this is only for source members.
  }

  @override
  // Coverage-ignore(suite): Not run.
  void registerOverrideDependency(
    ClassMembersBuilder membersBuilder,
    Set<ClassMember> overriddenMembers,
  ) {
    // Do nothing; this is only for source members.
  }

  @override
  bool isSameDeclaration(ClassMember other) {
    return other is DillClassMember && memberBuilder == other.memberBuilder;
  }

  @override
  // Coverage-ignore(suite): Not run.
  MemberResult getMemberResult(ClassMembersBuilder membersBuilder) {
    Member member = getMember(membersBuilder);
    if (member is Procedure &&
        member.stubKind == ProcedureStubKind.RepresentationField) {
      return new TypeDeclarationInstanceMemberResult(
        getMember(membersBuilder),
        memberKind,
        isDeclaredAsField: true,
      );
    }
    return super.getMemberResult(membersBuilder);
  }

  @override
  String toString() => 'DillClassMember($memberBuilder,forSetter=${forSetter})';
}
