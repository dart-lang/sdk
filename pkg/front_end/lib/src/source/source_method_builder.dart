// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_environment.dart';

import '../base/modifiers.dart';
import '../base/name_space.dart';
import '../base/scope.dart';
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/method_builder.dart';
import '../builder/type_builder.dart';
import '../fragment/fragment.dart';
import '../kernel/augmentation_lowering.dart';
import '../kernel/hierarchy/class_member.dart';
import '../kernel/hierarchy/members_builder.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/member_covariance.dart';
import '../kernel/type_algorithms.dart';
import 'name_scheme.dart';
import 'source_class_builder.dart';
import 'source_function_builder.dart';
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
  // TODO(johnniwinther): Add [_augmentations] field.
  MethodFragment _introductory;

  Modifiers _modifiers;

  final Reference _reference;
  final Reference? _tearOffReference;

  final MemberName _memberName;

  // TODO(johnniwinther): Implement augmentation using fragments.

  /// The builder for the original declaration.
  SourceMethodBuilder? _origin;

  /// If this builder is a patch or an augmentation, this is the builder for
  /// the immediately augmented procedure.
  SourceMethodBuilder? _augmentedBuilder;

  Procedure? _augmentedMethod;

  int _augmentationIndex = 0;

  List<SourceMethodBuilder>? _augmentations;

  SourceMethodBuilder(
      {required this.fileUri,
      required this.fileOffset,
      required this.name,
      required this.libraryBuilder,
      required this.declarationBuilder,
      required this.isStatic,
      required NameScheme nameScheme,
      required MethodFragment fragment,
      required Reference? reference,
      required Reference? tearOffReference})
      : _nameScheme = nameScheme,
        _introductory = fragment,
        _modifiers = fragment.modifiers,
        isOperator = fragment.isOperator,
        _reference = reference ?? new Reference(),
        _tearOffReference = tearOffReference,
        _memberName = nameScheme.getDeclaredName(name);

  @override
  Builder get parent => declarationBuilder ?? libraryBuilder;

  @override
  bool get isAugmentation => _modifiers.isAugment;

  @override
  bool get isExternal => _modifiers.isExternal;

  @override
  bool get isAbstract => _modifiers.isAbstract;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isConst => _modifiers.isConst;

  @override
  bool get isAugment => _modifiers.isAugment;

  // TODO(johnniwinther): What is this supposed to return?
  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Annotatable> get annotatables => [
        if (readTarget != null && invokeTarget != readTarget)
          readTarget as Annotatable,
        invokeTarget as Annotatable,
      ];

  // TODO(johnniwinther): Remove this. This is only needed for detecting patches
  // and macro annotations and we should use the fragment directly once
  // augmentations are fragments.
  List<MetadataBuilder>? get metadata => _introductory.metadata;

  @override
  void applyAugmentation(Builder augmentation) {
    if (augmentation is SourceMethodBuilder) {
      if (checkAugmentation(
          augmentationLibraryBuilder: augmentation.libraryBuilder,
          origin: this,
          augmentation: augmentation)) {
        augmentation._origin = this;
        SourceMethodBuilder augmentedBuilder =
            _augmentations == null ? this : _augmentations!.last;
        augmentation._augmentedBuilder = augmentedBuilder;
        augmentation._augmentationIndex =
            augmentedBuilder._augmentationIndex + 1;
        (_augmentations ??= []).add(augmentation);
      }
    } else {
      // Coverage-ignore-block(suite): Not run.
      reportAugmentationMismatch(
          originLibraryBuilder: libraryBuilder,
          origin: this,
          augmentation: augmentation);
    }
  }

  @override
  SourceMethodBuilder get origin => _origin ?? this;

  bool get isAugmented {
    if (isAugmenting) {
      return origin._augmentations!.last != this;
    } else {
      return _augmentations != null;
    }
  }

  // Coverage-ignore(suite): Not run.
  List<SourceMethodBuilder>? get augmentationsForTesting => _augmentations;

  Map<SourceMethodBuilder, AugmentSuperTarget?> _augmentedMethods = {};

  AugmentSuperTarget? _createAugmentSuperTarget(
      SourceMethodBuilder? targetBuilder) {
    if (targetBuilder == null) return null;

    Procedure declaredMethod = targetBuilder._introductory.invokeTarget;
    if (declaredMethod.isAbstract || declaredMethod.isExternal) {
      // Coverage-ignore-block(suite): Not run.
      return targetBuilder._augmentedBuilder != null
          ? _getAugmentSuperTarget(targetBuilder._augmentedBuilder!)
          : null;
    }

    Procedure augmentedMethod = targetBuilder._augmentedMethod = new Procedure(
        augmentedName(declaredMethod.name.text, libraryBuilder.library,
            targetBuilder._augmentationIndex),
        declaredMethod.kind,
        declaredMethod.function,
        fileUri: declaredMethod.fileUri)
      ..flags = declaredMethod.flags
      ..isStatic = declaredMethod.isStatic
      ..parent = declaredMethod.parent
      ..isInternalImplementation = true;

    return new AugmentSuperTarget(
        declaration: targetBuilder,
        readTarget: augmentedMethod,
        invokeTarget: augmentedMethod,
        writeTarget: null);
  }

  AugmentSuperTarget? _getAugmentSuperTarget(SourceMethodBuilder augmentation) {
    return _augmentedMethods[augmentation] ??=
        _createAugmentSuperTarget(augmentation._augmentedBuilder);
  }

  @override
  AugmentSuperTarget? get augmentSuperTarget =>
      origin._getAugmentSuperTarget(this);

  @override
  int buildBodyNodes(BuildNodesCallback f) {
    List<SourceMethodBuilder>? augmentations = _augmentations;
    if (augmentations != null) {
      void addAugmentedMethod(SourceMethodBuilder builder) {
        Procedure? augmentedMethod = builder._augmentedMethod;
        if (augmentedMethod != null) {
          augmentedMethod
            ..fileOffset = builder._introductory.invokeTarget.fileOffset
            ..fileEndOffset = builder._introductory.invokeTarget.fileEndOffset
            ..fileStartOffset =
                builder._introductory.invokeTarget.fileStartOffset
            ..signatureType = builder._introductory.invokeTarget.signatureType
            ..flags = builder._introductory.invokeTarget.flags;
          f(member: augmentedMethod, kind: BuiltMemberKind.Method);
        }
      }

      addAugmentedMethod(this);
      for (SourceMethodBuilder augmentation in augmentations) {
        addAugmentedMethod(augmentation);
      }
      finishProcedureAugmentation(_introductory.invokeTarget,
          augmentations.last._introductory.invokeTarget);

      return augmentations.length;
    }
    return 0;
  }

  @override
  void buildOutlineNodes(BuildNodesCallback f) {
    _introductory.buildOutlineNode(libraryBuilder, _nameScheme, f,
        reference: _reference,
        tearOffReference: _tearOffReference,
        classTypeParameters: classBuilder?.cls.typeParameters);
  }

  bool hasBuiltOutlineExpressions = false;

  @override
  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (!hasBuiltOutlineExpressions) {
      LookupScope parentScope =
          declarationBuilder?.scope ?? libraryBuilder.scope;
      _introductory.buildOutlineExpressions(classHierarchy, libraryBuilder,
          declarationBuilder, parentScope, invokeTarget as Annotatable,
          isClassInstanceMember: isClassInstanceMember,
          createFileUriExpression: isAugmented);
      hasBuiltOutlineExpressions = true;
    }
  }

  @override
  void checkTypes(SourceLibraryBuilder library, NameSpace nameSpace,
      TypeEnvironment typeEnvironment) {
    _introductory.checkTypes(library, typeEnvironment,
        isExternal: isExternal, isAbstract: isAbstract);
    List<SourceMethodBuilder>? augmentations = _augmentations;
    if (augmentations != null) {
      for (SourceMethodBuilder augmentation in augmentations) {
        augmentation.checkTypes(libraryBuilder, nameSpace, typeEnvironment);
      }
    }
  }

  @override
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    if (!isClassInstanceMember) return;
    _introductory.checkVariance(sourceClassBuilder, typeEnvironment);
    List<SourceMethodBuilder>? augmentations = _augmentations;
    if (augmentations != null) {
      for (SourceMethodBuilder augmentation in augmentations) {
        augmentation.checkVariance(sourceClassBuilder, typeEnvironment);
      }
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
  Member? get readTarget =>
      isAugmenting ? _origin!.readTarget : _introductory.readTarget;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get readTargetReference => isAugmenting
      ? _origin!.readTargetReference
      : (_tearOffReference ?? _reference);

  @override
  Member get invokeTarget =>
      isAugmenting ? _origin!.invokeTarget : _introductory.invokeTarget;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference =>
      isAugmenting ? _origin!.invokeTargetReference : _reference;

  @override
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => null;

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    return _introductory.computeDefaultTypes(context);
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
  Set<ClassMember>? _overrideDependencies;

  void _registerOverrideDependency(Set<ClassMember> overriddenMembers) {
    assert(
        overriddenMembers.every((overriddenMember) =>
            overriddenMember.declarationBuilder != classBuilder),
        "Unexpected override dependencies for $this: $overriddenMembers");
    _overrideDependencies ??= {};
    _overrideDependencies!.addAll(overriddenMembers);
  }

  void _ensureTypes(ClassMembersBuilder membersBuilder) {
    if (_typeEnsured) return;
    _introductory.ensureTypes(membersBuilder,
        declarationBuilder as SourceClassBuilder, _overrideDependencies);
    _overrideDependencies = null;
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
    _builder._ensureTypes(membersBuilder);
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
  void registerOverrideDependency(Set<ClassMember> overriddenMembers) {
    _builder._registerOverrideDependency(overriddenMembers);
  }

  @override
  String toString() => '$runtimeType($fullName,forSetter=${forSetter})';
}
