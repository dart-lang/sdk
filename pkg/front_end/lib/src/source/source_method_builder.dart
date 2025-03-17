// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_environment.dart';

import '../base/modifiers.dart';
import '../base/name_space.dart';
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/method_builder.dart';
import '../builder/type_builder.dart';
import '../fragment/fragment.dart';
import '../kernel/hierarchy/class_member.dart';
import '../kernel/hierarchy/members_builder.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/member_covariance.dart';
import '../kernel/type_algorithms.dart';
import 'name_scheme.dart';
import 'source_class_builder.dart';
import 'source_library_builder.dart';
import 'source_member_builder.dart';

class SourceMethodBuilder extends SourceMemberBuilderImpl
    implements MethodBuilder {
  @override
  final Uri fileUri;

  @override
  final int fileOffset;

  @override
  final String name;

  @override
  final SourceLibraryBuilder libraryBuilder;

  @override
  final DeclarationBuilder? declarationBuilder;

  @override
  final bool isStatic;

  final NameScheme _nameScheme;

  @override
  final bool isOperator;

  /// The declarations that introduces this method. Subsequent methods of the
  /// same name must be augmentations.
  final MethodFragment _introductory;
  final List<MethodFragment> _augmentations;

  final Modifiers _modifiers;

  final Reference _reference;
  final Reference? _tearOffReference;

  final MemberName _memberName;

  late final Procedure _invokeTarget;
  late final Procedure? _readTarget;

  SourceMethodBuilder(
      {required this.fileUri,
      required this.fileOffset,
      required this.name,
      required this.libraryBuilder,
      required this.declarationBuilder,
      required this.isStatic,
      required Modifiers modifiers,
      required NameScheme nameScheme,
      required MethodFragment introductory,
      required List<MethodFragment> augmentations,
      required Reference? reference,
      required Reference? tearOffReference})
      : _nameScheme = nameScheme,
        _introductory = introductory,
        _modifiers = modifiers,
        isOperator = introductory.isOperator,
        _reference = reference ?? new Reference(),
        _tearOffReference = tearOffReference,
        _memberName = nameScheme.getDeclaredName(name),
        _augmentations = augmentations;

  @override
  Builder get parent => declarationBuilder ?? libraryBuilder;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAugmentation => _modifiers.isAugment;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isExternal => _modifiers.isExternal;

  @override
  bool get isAbstract => _modifiers.isAbstract;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isConst => _modifiers.isConst;

  @override
  bool get isAugment => _modifiers.isAugment;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isFinal => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSynthesized => false;

  @override
  bool get isEnumElement => false;

  // TODO(johnniwinther): What is this supposed to return?
  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Annotatable> get annotatables => [
        if (readTarget != null && invokeTarget != readTarget)
          readTarget as Annotatable,
        invokeTarget as Annotatable,
      ];

  // Coverage-ignore(suite): Not run.
  // TODO(johnniwinther): Remove this. This is only needed for detecting patches
  // and macro annotations and we should use the fragment directly once
  // augmentations are fragments.
  List<MetadataBuilder>? get metadata => _introductory.metadata;

  @override
  int buildBodyNodes(BuildNodesCallback f) {
    // TODO(johnniwinther): Generate the needed augmented methods.
    return 0;
  }

  @override
  void buildOutlineNodes(BuildNodesCallback f) {
    List<MethodFragment> augmentedFragments = [
      _introductory,
      ..._augmentations
    ];
    // TODO(johnniwinther): Support augmenting a concrete method with an
    //  abstract method.
    MethodFragment lastFragment = augmentedFragments.removeLast();
    lastFragment.buildOutlineNode(libraryBuilder, _nameScheme, f,
        reference: _reference,
        tearOffReference: _tearOffReference,
        classTypeParameters: classBuilder?.cls.typeParameters);

    for (MethodFragment augmented in augmentedFragments) {
      augmented.buildOutlineNode(
          libraryBuilder, _nameScheme, noAddBuildNodesCallback,
          reference: new Reference(),
          tearOffReference: new Reference(),
          classTypeParameters: classBuilder?.cls.typeParameters);
    }
    _invokeTarget = lastFragment.invokeTarget;
    _readTarget = lastFragment.readTarget;
  }

  bool hasBuiltOutlineExpressions = false;

  @override
  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (!hasBuiltOutlineExpressions) {
      _introductory.buildOutlineExpressions(
          classHierarchy, libraryBuilder, declarationBuilder, _invokeTarget,
          isClassInstanceMember: isClassInstanceMember,
          createFileUriExpression:
              _invokeTarget.fileUri != _introductory.fileUri);
      for (MethodFragment augmentation in _augmentations) {
        augmentation.buildOutlineExpressions(
            classHierarchy, libraryBuilder, declarationBuilder, _invokeTarget,
            isClassInstanceMember: isClassInstanceMember,
            createFileUriExpression:
                _invokeTarget.fileUri != augmentation.fileUri);
      }
      hasBuiltOutlineExpressions = true;
    }
  }

  @override
  void checkTypes(SourceLibraryBuilder library, NameSpace nameSpace,
      TypeEnvironment typeEnvironment) {
    // TODO(johnniwinther): Updated checks for default values to handle
    // default values declared on the introductory method and omitted on the
    // augmenting method.
    _introductory.checkTypes(library, typeEnvironment);
    for (MethodFragment augmentation in _augmentations) {
      augmentation.checkTypes(library, typeEnvironment);
    }
  }

  @override
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    if (!isClassInstanceMember) return;
    _introductory.checkVariance(sourceClassBuilder, typeEnvironment);
    for (MethodFragment augmentation in _augmentations) {
      augmentation.checkVariance(sourceClassBuilder, typeEnvironment);
    }
  }

  @override
  Iterable<Reference> get exportedMemberReferences => [
        _reference,
      ];

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAssignable =>
      throw new UnsupportedError('$runtimeType.isAssignable');

  List<ClassMember>? _localMembers;

  @override
  List<ClassMember> get localMembers =>
      _localMembers ??= [new _MethodClassMember(this, _introductory)];

  @override
  List<ClassMember> get localSetters => const [];

  @override
  Name get memberName => _memberName.name;

  @override
  Member? get readTarget => _readTarget;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get readTargetReference => _tearOffReference ?? _reference;

  @override
  Member get invokeTarget => _invokeTarget;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => _reference;

  @override
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => null;

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    int count = _introductory.computeDefaultTypes(context);
    for (MethodFragment augmentation in _augmentations) {
      count += augmentation.computeDefaultTypes(context);
    }
    return count;
  }

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<MetadataBuilder>? get metadataForTesting => _introductory.metadata;

  // Coverage-ignore(suite): Not run.
  // TODO(johnniwinther): Remove these (or reinterpret them). These are used
  // for testing and macros by rely on old assumptions of the builder model.
  List<NominalParameterBuilder>? get typeParametersForTesting =>
      _introductory.typeParametersForTesting;

  // Coverage-ignore(suite): Not run.
  List<FormalParameterBuilder>? get formalsForTesting =>
      _introductory.formalsForTesting;

  // Coverage-ignore(suite): Not run.
  TypeBuilder? get returnTypeForTesting => _introductory.returnType;

  @override
  bool get isAugmenting => this != origin;

  @override
  bool get isProperty => false;

  @override
  bool get isRegularMethod => !isOperator;

  bool _typeEnsured = false;
  ClassMembersBuilder? _classMembersBuilder;
  Set<ClassMember>? _overrideDependencies;

  void _registerOverrideDependency(
      ClassMembersBuilder membersBuilder, Set<ClassMember> overriddenMembers) {
    assert(
        overriddenMembers.every((overriddenMember) =>
            overriddenMember.declarationBuilder != classBuilder),
        "Unexpected override dependencies for $this: $overriddenMembers");
    _classMembersBuilder ??= membersBuilder;
    _overrideDependencies ??= {};
    _overrideDependencies!.addAll(overriddenMembers);
  }

  void _ensureTypes() {
    if (_typeEnsured) return;
    if (_classMembersBuilder != null) {
      assert(_overrideDependencies != null);
      _introductory.ensureTypes(_classMembersBuilder!,
          declarationBuilder as SourceClassBuilder, _overrideDependencies);
      _overrideDependencies = null;
      _classMembersBuilder = null;
    }
    _typeEnsured = true;
  }
}

class _MethodClassMember implements ClassMember {
  final SourceMethodBuilder _builder;
  final MethodFragment _fragment;
  late final Covariance _covariance =
      new Covariance.fromMethod(_builder.invokeTarget as Procedure);

  _MethodClassMember(this._builder, this._fragment);

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
  bool get forSetter => false;

  @override
  String get fullName {
    String className = declarationBuilder.fullNameForErrors;
    return "${className}.${fullNameForErrors}";
  }

  @override
  String get fullNameForErrors => _builder.fullNameForErrors;

  @override
  Covariance getCovariance(ClassMembersBuilder membersBuilder) => _covariance;

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
  Member? getTearOff(ClassMembersBuilder membersBuilder) {
    if (_builder.readTarget != _builder.invokeTarget) {
      return _builder.readTarget;
    }
    return null;
  }

  @override
  bool get hasDeclarations => false;

  @override
  void inferType(ClassMembersBuilder membersBuilder) {
    _builder._ensureTypes();
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
  bool get isField => false;

  @override
  bool get isGetter => false;

  @override
  bool get isInternalImplementation => false;

  @override
  bool get isNoSuchMethodForwarder => false;

  @override
  bool isObjectMember(ClassBuilder objectClass) {
    return declarationBuilder == objectClass;
  }

  @override
  bool get isProperty => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool isSameDeclaration(ClassMember other) {
    return other is _MethodClassMember && _builder == other._builder;
  }

  @override
  bool get isSetter => false;

  @override
  bool get isSourceDeclaration => true;

  @override
  bool get isStatic => _fragment.modifiers.isStatic;

  @override
  bool get isSynthesized => false;

  @override
  ClassMemberKind get memberKind => ClassMemberKind.Method;

  @override
  Name get name => _builder.memberName;

  @override
  void registerOverrideDependency(
      ClassMembersBuilder membersBuilder, Set<ClassMember> overriddenMembers) {
    _builder._registerOverrideDependency(membersBuilder, overriddenMembers);
  }

  @override
  String toString() => '$runtimeType($fullName,forSetter=${forSetter})';
}
