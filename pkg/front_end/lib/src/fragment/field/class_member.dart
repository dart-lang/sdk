// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../fragment.dart';

class _FieldClassMember implements ClassMember {
  final SourcePropertyBuilder _builder;
  final FieldFragment _fragment;

  @override
  final bool forSetter;

  Covariance? _covariance;

  _FieldClassMember(this._builder, this._fragment, {required this.forSetter});

  @override
  int get charOffset => _fragment.nameOffset;

  @override
  DeclarationBuilder get declarationBuilder => _builder.declarationBuilder!;

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get declarations =>
      throw new UnsupportedError('$runtimeType.declarations');

  @override
  Uri get fileUri => _fragment.fileUri;

  @override
  // Coverage-ignore(suite): Not run.
  String get fullName {
    String className = declarationBuilder.fullNameForErrors;
    return "${className}.${fullNameForErrors}";
  }

  @override
  String get fullNameForErrors => _builder.fullNameForErrors;

  @override
  Covariance getCovariance(ClassMembersBuilder membersBuilder) {
    return _covariance ??= forSetter
        ? new Covariance.fromMember(getMember(membersBuilder),
            forSetter: forSetter)
        : const Covariance.empty();
  }

  @override
  Member getMember(ClassMembersBuilder membersBuilder) {
    _builder.ensureTypes(membersBuilder);
    return forSetter ? _builder.writeTarget! : _builder.readTarget!;
  }

  @override
  // Coverage-ignore(suite): Not run.
  MemberResult getMemberResult(ClassMembersBuilder membersBuilder) {
    if (isStatic) {
      return new StaticMemberResult(getMember(membersBuilder), memberKind,
          isDeclaredAsField: true,
          fullName: '${declarationBuilder.name}.${_builder.memberName.text}');
    } else if (_builder.isExtensionTypeMember) {
      ExtensionTypeDeclaration extensionTypeDeclaration =
          (declarationBuilder as ExtensionTypeDeclarationBuilder)
              .extensionTypeDeclaration;
      Member member = getTearOff(membersBuilder) ?? getMember(membersBuilder);
      return new ExtensionTypeMemberResult(
          extensionTypeDeclaration, member, memberKind, name,
          isDeclaredAsField: true);
    } else {
      return new TypeDeclarationInstanceMemberResult(
          getMember(membersBuilder), memberKind,
          isDeclaredAsField: true);
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  Member? getTearOff(ClassMembersBuilder membersBuilder) => null;

  @override
  bool get hasDeclarations => false;

  @override
  void inferType(ClassMembersBuilder membersBuilder) {
    _builder.ensureTypes(membersBuilder);
  }

  @override
  ClassMember get interfaceMember => this;

  @override
  // TODO(johnniwinther): This should not be determined by the builder. A
  // property can have a non-abstract getter and an abstract setter or the
  // reverse. With augmentations, abstract introductory declarations might even
  // be implemented by augmentations.
  bool get isAbstract => _fragment.modifiers.isAbstract;

  @override
  bool get isDuplicate => _builder.isDuplicate;

  @override
  bool get isExtensionTypeMember => _builder.isExtensionTypeMember;

  @override
  bool get isField => true;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isGetter => false; //!forSetter;

  @override
  bool get isInternalImplementation => false;

  @override
  bool get isNoSuchMethodForwarder => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool isObjectMember(ClassBuilder objectClass) {
    return declarationBuilder == objectClass;
  }

  @override
  bool get isProperty => true;

  @override
  bool isSameDeclaration(ClassMember other) {
    return other is _FieldClassMember && _builder == other._builder;
  }

  @override
  bool get isSetter => false; //forSetter;

  @override
  bool get isSourceDeclaration => true;

  @override
  bool get isStatic => _fragment.modifiers.isStatic;

  @override
  bool get isSynthesized => false;

  @override
  ClassMemberKind get memberKind =>
      forSetter ? ClassMemberKind.Setter : ClassMemberKind.Getter;

  @override
  Name get name => _builder.memberName;

  @override
  void registerOverrideDependency(Set<ClassMember> overriddenMembers) {
    if (forSetter) {
      _builder.registerSetterOverrideDependency(overriddenMembers);
    } else {
      _builder.registerGetterOverrideDependency(overriddenMembers);
    }
  }

  @override
  String toString() => '$runtimeType($fullName,forSetter=${forSetter})';
}

class _SynthesizedFieldClassMember implements ClassMember {
  final SourcePropertyBuilder _builder;
  final _SynthesizedFieldMemberKind _kind;

  final Member _member;

  final Name _name;

  Covariance? _covariance;

  @override
  final ClassMemberKind memberKind;

  _SynthesizedFieldClassMember(
      this._builder, this._member, this._name, this._kind, this.memberKind);

  @override
  bool get isInternalImplementation => _kind.isInternalImplementation;

  @override
  Member getMember(ClassMembersBuilder membersBuilder) {
    _builder.ensureTypes(membersBuilder);
    return _member;
  }

  @override
  Member? getTearOff(ClassMembersBuilder membersBuilder) {
    // Ensure field type is computed.
    getMember(membersBuilder);
    return null;
  }

  @override
  Covariance getCovariance(ClassMembersBuilder membersBuilder) {
    return _covariance ??= new Covariance.fromMember(getMember(membersBuilder),
        forSetter: forSetter);
  }

  @override
  MemberResult getMemberResult(ClassMembersBuilder membersBuilder) {
    return new TypeDeclarationInstanceMemberResult(
        getMember(membersBuilder), memberKind,
        isDeclaredAsField: _builder.isField);
  }

  @override
  void inferType(ClassMembersBuilder membersBuilder) {
    _builder.ensureTypes(membersBuilder);
  }

  @override
  void registerOverrideDependency(Set<ClassMember> overriddenMembers) {
    if (forSetter) {
      _builder.registerSetterOverrideDependency(overriddenMembers);
    } else {
      _builder.registerGetterOverrideDependency(overriddenMembers);
    }
  }

  @override
  bool get isSourceDeclaration => true;

  @override
  bool get forSetter => memberKind == ClassMemberKind.Setter;

  @override
  bool get isProperty => memberKind != ClassMemberKind.Method;

  @override
  DeclarationBuilder get declarationBuilder => _builder.declarationBuilder!;

  @override
  // Coverage-ignore(suite): Not run.
  bool isObjectMember(ClassBuilder objectClass) {
    return declarationBuilder == objectClass;
  }

  @override
  bool get isDuplicate => _builder.isDuplicate;

  @override
  bool get isStatic => _builder.isStatic;

  @override
  bool get isField => _member is Field;

  @override
  bool get isSetter {
    Member procedure = _member;
    return procedure is Procedure && procedure.kind == ProcedureKind.Setter;
  }

  @override
  bool get isGetter {
    Member procedure = _member;
    return procedure is Procedure && procedure.kind == ProcedureKind.Getter;
  }

  @override
  Name get name => _name;

  @override
  // Coverage-ignore(suite): Not run.
  String get fullName {
    String suffix = isSetter ? "=" : "";
    String className = declarationBuilder.fullNameForErrors;
    return "${className}.${fullNameForErrors}$suffix";
  }

  @override
  String get fullNameForErrors => _builder.fullNameForErrors;

  @override
  Uri get fileUri => _builder.fileUri;

  @override
  int get charOffset => _builder.fileOffset;

  @override
  bool get isAbstract => _member.isAbstract;

  @override
  bool get isSynthesized => false;

  @override
  bool get hasDeclarations => false;

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get declarations =>
      throw new UnsupportedError("$runtimeType.declarations");

  @override
  ClassMember get interfaceMember => this;

  @override
  bool isSameDeclaration(ClassMember other) {
    if (identical(this, other)) return true;
    return other is _SynthesizedFieldClassMember &&
        _builder == other._builder &&
        _kind == other._kind;
  }

  @override
  bool get isNoSuchMethodForwarder => false;

  @override
  String toString() => '_SynthesizedFieldClassMember('
      '$_builder,$_member,$_kind,forSetter=${forSetter})';

  @override
  bool get isExtensionTypeMember => _builder.isExtensionTypeMember;
}

enum _SynthesizedFieldMemberKind {
  /// A `isSet` field used for late lowering.
  LateIsSet(isInternalImplementation: true),

  /// A field used for the value of a late lowered field.
  LateField(isInternalImplementation: true),

  /// A getter or setter used for late lowering.
  LateGetterSetter(isInternalImplementation: false),

  /// A getter or setter used for abstract or external fields.
  AbstractExternalGetterSetter(isInternalImplementation: false),

  /// A getter for an extension type declaration representation field.
  RepresentationField(isInternalImplementation: false),
  ;

  final bool isInternalImplementation;

  const _SynthesizedFieldMemberKind({required this.isInternalImplementation});
}
