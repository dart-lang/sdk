// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/kernel/hierarchy/members_builder.dart';
import 'package:front_end/src/kernel/member_covariance.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_environment.dart';

import '../base/name_space.dart';
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/metadata_builder.dart';
import '../builder/method_builder.dart';
import '../kernel/hierarchy/class_member.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/type_algorithms.dart';
import 'name_scheme.dart';
import 'source_class_builder.dart';
import 'source_library_builder.dart';
import 'source_member_builder.dart';

class SyntheticMethodBuilder extends SourceMemberBuilderImpl
    implements MethodBuilder {
  @override
  final String name;

  @override
  final Uri fileUri;

  @override
  final int fileOffset;

  @override
  final SourceLibraryBuilder libraryBuilder;

  @override
  final DeclarationBuilder? declarationBuilder;

  final Reference _reference;

  final MemberName _memberName;

  @override
  final bool isAbstract;

  final SyntheticMethodCreator _creator;

  late final Procedure _procedure;

  SyntheticMethodBuilder(
      {required this.name,
      required this.fileUri,
      required this.fileOffset,
      required this.libraryBuilder,
      this.declarationBuilder,
      required NameScheme nameScheme,
      required this.isAbstract,
      required SyntheticMethodCreator creator,
      required Reference? reference})
      : _memberName = nameScheme.getDeclaredName(name),
        _reference = reference ?? new Reference(),
        _creator = creator;

  @override
  Builder get parent =>
      declarationBuilder ?? // Coverage-ignore(suite): Not run.
      libraryBuilder;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Annotatable> get annotatables => [];

  @override
  int buildBodyNodes(BuildNodesCallback f) {
    return 0;
  }

  @override
  void buildOutlineNodes(BuildNodesCallback f) {
    _procedure = _creator.buildOutlineNode(
        libraryBuilder: libraryBuilder,
        name: memberName,
        fileUri: fileUri,
        fileOffset: fileOffset,
        reference: _reference);
    f(kind: BuiltMemberKind.Method, member: _procedure);
  }

  @override
  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    _creator.buildOutlineExpressions(
        procedure: _procedure, classHierarchy: classHierarchy);
  }

  @override
  void checkTypes(SourceLibraryBuilder library, NameSpace nameSpace,
      TypeEnvironment typeEnvironment) {}

  @override
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {}

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    return 0;
  }

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [invokeTargetReference];

  @override
  Member get invokeTarget => _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => _reference;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAssignable => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAugmentation => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isProperty => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isFinal => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSynthesized => true;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isEnumElement => false;

  @override
  late final List<ClassMember> localMembers = [
    new _SyntheticMethodClassMember(this)
  ];

  @override
  List<ClassMember> get localSetters => const [];

  @override
  Name get memberName => _memberName.name;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<MetadataBuilder>? get metadataForTesting => const [];

  @override
  // Coverage-ignore(suite): Not run.
  Member? get readTarget => _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get readTargetReference => _procedure.reference;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => null;
}

class _SyntheticMethodClassMember implements ClassMember {
  final SyntheticMethodBuilder _builder;

  _SyntheticMethodClassMember(this._builder);

  @override
  // Coverage-ignore(suite): Not run.
  int get charOffset => _builder.fileOffset;

  @override
  DeclarationBuilder get declarationBuilder => _builder.declarationBuilder!;

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get declarations =>
      throw new UnsupportedError('$runtimeType.declarations');

  @override
  // Coverage-ignore(suite): Not run.
  Uri get fileUri => _builder.fileUri;

  @override
  bool get forSetter => false;

  @override
  // Coverage-ignore(suite): Not run.
  String get fullName => _builder.declarationBuilder != null
      ? '${_builder.declarationBuilder!.name}.${_builder.name}'
      : _builder.name;

  @override
  // Coverage-ignore(suite): Not run.
  String get fullNameForErrors => _builder.fullNameForErrors;

  @override
  // Coverage-ignore(suite): Not run.
  Covariance getCovariance(ClassMembersBuilder membersBuilder) {
    return new Covariance.fromMember(_builder.invokeTarget, forSetter: false);
  }

  @override
  Member getMember(ClassMembersBuilder membersBuilder) {
    return _builder.invokeTarget;
  }

  @override
  // Coverage-ignore(suite): Not run.
  MemberResult getMemberResult(ClassMembersBuilder membersBuilder) {
    if (isStatic) {
      return new StaticMemberResult(getMember(membersBuilder), memberKind,
          isDeclaredAsField: false,
          fullName: '${declarationBuilder.name}.${_builder.memberName.text}');
    } else if (_builder.isExtensionTypeMember) {
      ExtensionTypeDeclaration extensionTypeDeclaration =
          (declarationBuilder as ExtensionTypeDeclarationBuilder)
              .extensionTypeDeclaration;
      Member member = getTearOff(membersBuilder) ?? getMember(membersBuilder);
      return new ExtensionTypeMemberResult(
          extensionTypeDeclaration, member, memberKind, name,
          isDeclaredAsField: false);
    } else {
      return new TypeDeclarationInstanceMemberResult(
          getMember(membersBuilder), memberKind,
          isDeclaredAsField: false);
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  Member? getTearOff(ClassMembersBuilder membersBuilder) {
    return null;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasDeclarations => false;

  @override
  void inferType(ClassMembersBuilder membersBuilder) {}

  @override
  ClassMember get interfaceMember => this;

  @override
  bool get isAbstract => _builder.isAbstract;

  @override
  bool get isDuplicate => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isExtensionTypeMember => _builder.isExtensionTypeMember;

  @override
  bool get isField => false;

  @override
  bool get isGetter => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isInternalImplementation => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isNoSuchMethodForwarder => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool isObjectMember(ClassBuilder objectClass) => false;

  @override
  bool get isProperty => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool isSameDeclaration(ClassMember other) {
    return other is _SyntheticMethodClassMember && _builder == other._builder;
  }

  @override
  bool get isSetter => false;

  @override
  // TODO(johnniwinther): This should be false.
  bool get isSourceDeclaration => true;

  @override
  bool get isStatic => _builder.isStatic;

  @override
  // Coverage-ignore(suite): Not run.
  // TODO(johnniwinther): Should this be true?
  bool get isSynthesized => !isSourceDeclaration;

  @override
  // Coverage-ignore(suite): Not run.
  ClassMemberKind get memberKind => ClassMemberKind.Method;

  @override
  Name get name => _builder.memberName;

  @override
  void registerOverrideDependency(Set<ClassMember> overriddenMembers) {}

  @override
  String toString() => '$runtimeType($fullName,forSetter=${forSetter})';
}

/// Strategy used for creating [Procedure]s through [SyntheticMethodBuilder].
abstract class SyntheticMethodCreator {
  /// Called to create the [Procedure] the method during
  /// [SourceMemberBuilder.buildOutlineNodes].
  Procedure buildOutlineNode(
      {required SourceLibraryBuilder libraryBuilder,
      required Name name,
      required Uri fileUri,
      required int fileOffset,
      required Reference reference});

  /// Called to create the body for [procedure] during
  /// [SourceMemberBuilder.buildOutlineExpressions].
  // TODO(johnniwinther): Move building of bodies to
  //  [SourceMemberBuilder.buildBodyNodes].
  void buildOutlineExpressions(
      {required Procedure procedure, required ClassHierarchy classHierarchy});
}
