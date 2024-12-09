// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_environment.dart';

import '../base/name_space.dart';
import '../base/scope.dart';
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/metadata_builder.dart';
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
import 'source_procedure_builder.dart';

class SourcePropertyBuilder extends SourceMemberBuilderImpl {
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

  /// The declarations that introduces this property. Subsequent property of the
  /// same name must be augmentations.
  // TODO(johnniwinther): Support setter and field declarations.
  // TODO(johnniwinther): Add [_augmentations] field.
  final GetterFragment _introductory;

  final Reference _getterReference;

  final MemberName _memberName;

  // TODO(johnniwinther): Implement augmentation using fragments.

  /// The builder for the original declaration.
  SourcePropertyBuilder? _origin;

  /// If this builder is a patch or an augmentation, this is the builder for
  /// the immediately augmented procedure.
  SourcePropertyBuilder? _augmentedBuilder;

  Procedure? _augmentedProcedure;

  int _augmentationIndex = 0;

  List<SourcePropertyBuilder>? _augmentations;

  SourcePropertyBuilder(
      {required this.fileUri,
      required this.fileOffset,
      required this.name,
      required this.libraryBuilder,
      required this.declarationBuilder,
      required this.isStatic,
      required NameScheme nameScheme,
      required GetterFragment fragment,
      required Reference? getterReference})
      : _nameScheme = nameScheme,
        _introductory = fragment,
        _getterReference = getterReference ?? new Reference(),
        _memberName = nameScheme.getDeclaredName(name);

  @override
  Builder get parent => declarationBuilder ?? libraryBuilder;

  @override
  bool get isAugmentation => _introductory.modifiers.isAugment;

  @override
  bool get isExternal => _introductory.modifiers.isExternal;

  @override
  bool get isAbstract => _introductory.modifiers.isAbstract;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isConst => _introductory.modifiers.isConst;

  @override
  bool get isAugment => _introductory.modifiers.isAugment;

  // TODO(johnniwinther): What is this supposed to return?
  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Annotatable> get annotatables => [readTarget as Annotatable];

  // TODO(johnniwinther): Remove this. This is only needed for detecting patches
  // and macro annotations and we should use the fragment directly once
  // augmentations are fragments.
  List<MetadataBuilder>? get metadata => _introductory.metadata;

  @override
  void applyAugmentation(Builder augmentation) {
    if (augmentation is SourcePropertyBuilder) {
      if (checkAugmentation(
          augmentationLibraryBuilder: augmentation.libraryBuilder,
          origin: this,
          augmentation: augmentation)) {
        augmentation._origin = this;
        SourcePropertyBuilder augmentedBuilder = _augmentations == null
            ? this
            :
            // Coverage-ignore(suite): Not run.
            _augmentations!.last;
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
  SourcePropertyBuilder get origin => _origin ?? this;

  bool get isAugmented {
    if (isAugmenting) {
      return origin._augmentations!.last != this;
    } else {
      return _augmentations != null;
    }
  }

  // Coverage-ignore(suite): Not run.
  List<SourcePropertyBuilder>? get augmentationsForTesting => _augmentations;

  Map<SourcePropertyBuilder, AugmentSuperTarget?> _augmentedProcedures = {};

  AugmentSuperTarget? _createAugmentSuperTarget(
      SourcePropertyBuilder? targetBuilder) {
    if (targetBuilder == null) return null;
    Procedure declaredProcedure = targetBuilder._introductory.readTarget;

    if (declaredProcedure.isAbstract || declaredProcedure.isExternal) {
      // Coverage-ignore-block(suite): Not run.
      return targetBuilder._augmentedBuilder != null
          ? _getAugmentSuperTarget(targetBuilder._augmentedBuilder!)
          : null;
    }

    Procedure augmentedProcedure =
        targetBuilder._augmentedProcedure = new Procedure(
            augmentedName(declaredProcedure.name.text, libraryBuilder.library,
                targetBuilder._augmentationIndex),
            declaredProcedure.kind,
            declaredProcedure.function,
            fileUri: declaredProcedure.fileUri)
          ..flags = declaredProcedure.flags
          ..isStatic = _introductory.readTarget.isStatic
          ..parent = _introductory.readTarget.parent
          ..isInternalImplementation = true;

    return new AugmentSuperTarget(
        declaration: targetBuilder,
        readTarget: augmentedProcedure,
        invokeTarget: augmentedProcedure,
        writeTarget: null);
  }

  AugmentSuperTarget? _getAugmentSuperTarget(
      SourcePropertyBuilder augmentation) {
    return _augmentedProcedures[augmentation] ??=
        _createAugmentSuperTarget(augmentation._augmentedBuilder);
  }

  @override
  AugmentSuperTarget? get augmentSuperTarget =>
      origin._getAugmentSuperTarget(this);

  @override
  int buildBodyNodes(BuildNodesCallback f) {
    List<SourcePropertyBuilder>? augmentations = _augmentations;
    if (augmentations != null) {
      void addAugmentedProcedure(SourcePropertyBuilder builder) {
        Procedure? augmentedProcedure = builder._augmentedProcedure;
        if (augmentedProcedure != null) {
          augmentedProcedure
            ..fileOffset = builder._introductory.readTarget.fileOffset
            ..fileEndOffset = builder._introductory.readTarget.fileEndOffset
            ..fileStartOffset = builder._introductory.readTarget.fileStartOffset
            ..signatureType = builder._introductory.readTarget.signatureType
            ..flags = builder._introductory.readTarget.flags;
          f(member: augmentedProcedure, kind: BuiltMemberKind.Method);
        }
      }

      addAugmentedProcedure(this);
      for (SourcePropertyBuilder augmentation in augmentations) {
        addAugmentedProcedure(augmentation);
      }
      finishProcedureAugmentation(_introductory.readTarget,
          augmentations.last._introductory.readTarget);

      return augmentations.length;
    }
    return 0;
  }

  @override
  void buildOutlineNodes(BuildNodesCallback f) {
    _introductory.buildOutlineNode(libraryBuilder, _nameScheme, f,
        getterReference: _getterReference,
        classTypeParameters: classBuilder?.cls.typeParameters);
  }

  bool hasBuiltOutlineExpressions = false;

  @override
  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (!hasBuiltOutlineExpressions) {
      LookupScope parentScope =
          declarationBuilder?.scope ?? libraryBuilder.scope;
      _introductory.buildOutlineExpressions(
          classHierarchy,
          libraryBuilder,
          declarationBuilder,
          parentScope,
          readTarget as Annotatable,
          isClassInstanceMember: isClassInstanceMember,
          createFileUriExpression: isAugmented);
      hasBuiltOutlineExpressions = true;
    }
  }

  @override
  void checkTypes(SourceLibraryBuilder library, NameSpace nameSpace,
      TypeEnvironment typeEnvironment) {
    SourceProcedureBuilder? setterBuilder;
    if (!isClassMember) {
      // Getter/setter type conflict for class members is handled in the class
      // hierarchy builder.
      setterBuilder = nameSpace.lookupLocalMember(name, setter: true)
          as SourceProcedureBuilder?;
    }
    _introductory.checkTypes(library, typeEnvironment, setterBuilder,
        isExternal: isExternal, isAbstract: isAbstract);
    List<SourcePropertyBuilder>? augmentations = _augmentations;
    if (augmentations != null) {
      for (SourcePropertyBuilder augmentation in augmentations) {
        augmentation.checkTypes(libraryBuilder, nameSpace, typeEnvironment);
      }
    }
  }

  @override
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    if (!isClassInstanceMember) return;
    _introductory.checkVariance(sourceClassBuilder, typeEnvironment);
    List<SourcePropertyBuilder>? augmentations = _augmentations;
    if (augmentations != null) {
      for (SourcePropertyBuilder augmentation in augmentations) {
        augmentation.checkVariance(sourceClassBuilder, typeEnvironment);
      }
    }
  }

  @override
  Iterable<Reference> get exportedMemberReferences => [_getterReference];

  @override
  Member? get invokeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAssignable =>
      throw new UnsupportedError('$runtimeType.isAssignable');

  List<ClassMember>? _localMembers;

  @override
  List<ClassMember> get localMembers =>
      _localMembers ??= [new _GetterClassMember(this, _introductory)];

  @override
  List<ClassMember> get localSetters => const [];

  @override
  Name get memberName => _memberName.name;

  @override
  Member? get readTarget =>
      isAugmenting ? _origin!.readTarget : _introductory.readTarget;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    return _introductory.computeDefaultTypes(context,
        inErrorRecovery: inErrorRecovery);
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
  TypeBuilder get returnTypeForTesting => _introductory.returnType;

  @override
  bool get isAugmenting => this != origin;

  @override
  bool get isProperty => true;

  // TODO(johnniwinther): Remove this. Maybe replace with `hasGetter`?
  @override
  bool get isGetter => true;

  bool _typeEnsured = false;
  Set<ClassMember>? _getterOverrideDependencies;

  void _registerGetterOverrideDependency(Set<ClassMember> overriddenMembers) {
    assert(
        overriddenMembers.every((overriddenMember) =>
            overriddenMember.declarationBuilder != classBuilder),
        "Unexpected override dependencies for $this: $overriddenMembers");
    _getterOverrideDependencies ??= {};
    _getterOverrideDependencies!.addAll(overriddenMembers);
  }

  void _ensureTypes(ClassMembersBuilder membersBuilder) {
    if (_typeEnsured) return;
    _introductory.ensureTypes(membersBuilder,
        declarationBuilder as SourceClassBuilder, _getterOverrideDependencies);
    _getterOverrideDependencies = null;
    _typeEnsured = true;
  }
}

class _GetterClassMember implements ClassMember {
  final SourcePropertyBuilder _builder;
  final GetterFragment _fragment;

  _GetterClassMember(this._builder, this._fragment);

  @override
  int get charOffset => _fragment.nameOffset;

  @override
  DeclarationBuilder get declarationBuilder => _builder.declarationBuilder!;

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get declarations =>
      throw new UnsupportedError('_GetterClassMember.declarations');

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
  Covariance getCovariance(ClassMembersBuilder membersBuilder) =>
      const Covariance.empty();

  @override
  Member getMember(ClassMembersBuilder membersBuilder) {
    return _builder.readTarget!;
  }

  @override
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
  Member? getTearOff(ClassMembersBuilder membersBuilder) => null;

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
  bool get isGetter => true;

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
    return other is _GetterClassMember &&
        // Coverage-ignore(suite): Not run.
        _builder == other._builder;
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
  ClassMemberKind get memberKind => ClassMemberKind.Getter;

  @override
  Name get name => _builder.memberName;

  @override
  void registerOverrideDependency(Set<ClassMember> overriddenMembers) {
    _builder._registerGetterOverrideDependency(overriddenMembers);
  }

  @override
  String toString() => '$runtimeType($fullName,forSetter=${forSetter})';
}
