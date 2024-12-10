// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../base/modifiers.dart';
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
  GetterFragment? _introductoryGetable;
  SetterFragment? _introductorySetable;

  Modifiers _modifiers;

  final Reference? _getterReference;
  final Reference? _setterReference;

  final MemberName _memberName;

  // TODO(johnniwinther): Implement augmentation using fragments.

  /// The builder for the original declaration.
  SourcePropertyBuilder? _origin;

  /// If this builder is a patch or an augmentation, this is the builder for
  /// the immediately augmented procedure.
  SourcePropertyBuilder? _augmentedBuilder;

  Procedure? _augmentedGetter;
  Procedure? _augmentedSetter;

  int _augmentationIndex = 0;

  List<SourcePropertyBuilder>? _getterAugmentations;
  List<SourcePropertyBuilder>? _setterAugmentations;

  SourcePropertyBuilder.forGetter(
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
        _introductoryGetable = fragment,
        _modifiers = fragment.modifiers,
        _getterReference = getterReference ?? new Reference(),
        _setterReference = null,
        _memberName = nameScheme.getDeclaredName(name);

  SourcePropertyBuilder.forSetter(
      {required this.fileUri,
      required this.fileOffset,
      required this.name,
      required this.libraryBuilder,
      required this.declarationBuilder,
      required this.isStatic,
      required NameScheme nameScheme,
      required SetterFragment fragment,
      required Reference? setterReference})
      : _nameScheme = nameScheme,
        _introductorySetable = fragment,
        _modifiers = fragment.modifiers,
        _getterReference = null,
        _setterReference = setterReference ?? new Reference(),
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
        if (readTarget != null) readTarget as Annotatable,
        if (writeTarget != null) writeTarget as Annotatable
      ];

  // TODO(johnniwinther): Remove this. This is only needed for detecting patches
  // and macro annotations and we should use the fragment directly once
  // augmentations are fragments.
  List<MetadataBuilder>? get metadata =>
      _introductoryGetable?.metadata ?? // Coverage-ignore(suite): Not run.
      _introductorySetable?.metadata;

  @override
  void applyAugmentation(Builder augmentation) {
    if (augmentation is SourcePropertyBuilder) {
      if (checkAugmentation(
          augmentationLibraryBuilder: augmentation.libraryBuilder,
          origin: this,
          augmentation: augmentation)) {
        augmentation._origin = this;
        if (augmentation.isSetter) {
          SourcePropertyBuilder augmentedBuilder =
              _setterAugmentations == null ? this : _setterAugmentations!.last;
          augmentation._augmentedBuilder = augmentedBuilder;
          augmentation._augmentationIndex =
              augmentedBuilder._augmentationIndex + 1;
          (_setterAugmentations ??= []).add(augmentation);
        } else {
          SourcePropertyBuilder augmentedBuilder = _getterAugmentations == null
              ? this
              :
              // Coverage-ignore(suite): Not run.
              _getterAugmentations!.last;
          augmentation._augmentedBuilder = augmentedBuilder;
          augmentation._augmentationIndex =
              augmentedBuilder._augmentationIndex + 1;
          (_getterAugmentations ??= []).add(augmentation);
        }
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
    if (isSetter) {
      if (isAugmenting) {
        return origin._setterAugmentations!.last != this;
      } else {
        return _setterAugmentations != null;
      }
    } else {
      if (isAugmenting) {
        return origin._getterAugmentations!.last != this;
      } else {
        return _getterAugmentations != null;
      }
    }
  }

  // Coverage-ignore(suite): Not run.
  List<SourcePropertyBuilder>? get augmentationsForTesting =>
      _getterAugmentations ?? _setterAugmentations;

  Map<SourcePropertyBuilder, AugmentSuperTarget?> _augmentedProcedures = {};

  AugmentSuperTarget? _createAugmentSuperTarget(
      SourcePropertyBuilder? targetBuilder) {
    if (targetBuilder == null) return null;
    if (isSetter) {
      Procedure? declaredSetter =
          targetBuilder._introductorySetable?.writeTarget;
      if (declaredSetter == null) return null;

      if (declaredSetter.isAbstract || declaredSetter.isExternal) {
        // Coverage-ignore-block(suite): Not run.
        return targetBuilder._augmentedBuilder != null
            ? _getAugmentSuperTarget(targetBuilder._augmentedBuilder!)
            : null;
      }

      Procedure augmentedSetter =
          targetBuilder._augmentedSetter = new Procedure(
              augmentedName(declaredSetter.name.text, libraryBuilder.library,
                  targetBuilder._augmentationIndex),
              declaredSetter.kind,
              declaredSetter.function,
              fileUri: declaredSetter.fileUri)
            ..flags = declaredSetter.flags
            ..isStatic = declaredSetter.isStatic
            ..parent = declaredSetter.parent
            ..isInternalImplementation = true;

      return new AugmentSuperTarget(
          declaration: targetBuilder,
          readTarget: null,
          invokeTarget: null,
          writeTarget: augmentedSetter);
    } else {
      Procedure? declaredGetter =
          targetBuilder._introductoryGetable?.readTarget;
      if (declaredGetter == null) return null;

      if (declaredGetter.isAbstract || declaredGetter.isExternal) {
        // Coverage-ignore-block(suite): Not run.
        return targetBuilder._augmentedBuilder != null
            ? _getAugmentSuperTarget(targetBuilder._augmentedBuilder!)
            : null;
      }

      Procedure augmentedGetter =
          targetBuilder._augmentedGetter = new Procedure(
              augmentedName(declaredGetter.name.text, libraryBuilder.library,
                  targetBuilder._augmentationIndex),
              declaredGetter.kind,
              declaredGetter.function,
              fileUri: declaredGetter.fileUri)
            ..flags = declaredGetter.flags
            ..isStatic = declaredGetter.isStatic
            ..parent = declaredGetter.parent
            ..isInternalImplementation = true;

      return new AugmentSuperTarget(
          declaration: targetBuilder,
          readTarget: augmentedGetter,
          invokeTarget: augmentedGetter,
          writeTarget: null);
    }
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
    List<SourcePropertyBuilder>? getterAugmentations = _getterAugmentations;
    if (getterAugmentations != null) {
      void addAugmentedProcedure(SourcePropertyBuilder builder) {
        Procedure? augmentedGetter = builder._augmentedGetter;
        if (augmentedGetter != null) {
          augmentedGetter
            ..fileOffset = builder._introductoryGetable!.readTarget.fileOffset
            ..fileEndOffset =
                builder._introductoryGetable!.readTarget.fileEndOffset
            ..fileStartOffset =
                builder._introductoryGetable!.readTarget.fileStartOffset
            ..signatureType =
                builder._introductoryGetable!.readTarget.signatureType
            ..flags = builder._introductoryGetable!.readTarget.flags;
          f(member: augmentedGetter, kind: BuiltMemberKind.Method);
        }
      }

      addAugmentedProcedure(this);
      for (SourcePropertyBuilder augmentation in getterAugmentations) {
        addAugmentedProcedure(augmentation);
      }
      finishProcedureAugmentation(_introductoryGetable!.readTarget,
          getterAugmentations.last._introductoryGetable!.readTarget);

      return getterAugmentations.length;
    }
    List<SourcePropertyBuilder>? setterAugmentations = _setterAugmentations;
    if (setterAugmentations != null) {
      void addAugmentedProcedure(SourcePropertyBuilder builder) {
        Procedure? augmentedSetter = builder._augmentedSetter;
        if (augmentedSetter != null) {
          augmentedSetter
            ..fileOffset = builder._introductorySetable!.writeTarget.fileOffset
            ..fileEndOffset =
                builder._introductorySetable!.writeTarget.fileEndOffset
            ..fileStartOffset =
                builder._introductorySetable!.writeTarget.fileStartOffset
            ..signatureType =
                builder._introductorySetable!.writeTarget.signatureType
            ..flags = builder._introductorySetable!.writeTarget.flags;
          f(member: augmentedSetter, kind: BuiltMemberKind.Method);
        }
      }

      addAugmentedProcedure(this);
      for (SourcePropertyBuilder augmentation in setterAugmentations) {
        addAugmentedProcedure(augmentation);
      }
      finishProcedureAugmentation(_introductorySetable!.writeTarget,
          setterAugmentations.last._introductorySetable!.writeTarget);

      return setterAugmentations.length;
    }
    return 0;
  }

  @override
  void buildOutlineNodes(BuildNodesCallback f) {
    _introductoryGetable?.buildOutlineNode(libraryBuilder, _nameScheme, f,
        getterReference: _getterReference!,
        classTypeParameters: classBuilder?.cls.typeParameters);
    _introductorySetable?.buildOutlineNode(libraryBuilder, _nameScheme, f,
        setterReference: _setterReference!,
        classTypeParameters: classBuilder?.cls.typeParameters);
  }

  bool hasBuiltOutlineExpressions = false;

  @override
  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (!hasBuiltOutlineExpressions) {
      LookupScope parentScope =
          declarationBuilder?.scope ?? libraryBuilder.scope;
      _introductoryGetable?.buildOutlineExpressions(
          classHierarchy,
          libraryBuilder,
          declarationBuilder,
          parentScope,
          readTarget as Annotatable,
          isClassInstanceMember: isClassInstanceMember,
          createFileUriExpression: isAugmented);
      _introductorySetable?.buildOutlineExpressions(
          classHierarchy,
          libraryBuilder,
          declarationBuilder,
          parentScope,
          writeTarget as Annotatable,
          isClassInstanceMember: isClassInstanceMember,
          createFileUriExpression: isAugmented);
      hasBuiltOutlineExpressions = true;
    }
  }

  @override
  void checkTypes(SourceLibraryBuilder library, NameSpace nameSpace,
      TypeEnvironment typeEnvironment) {
    SourcePropertyBuilder? setterBuilder;
    if (!isClassMember) {
      // Getter/setter type conflict for class members is handled in the class
      // hierarchy builder.
      setterBuilder = nameSpace.lookupLocalMember(name, setter: true)
          as SourcePropertyBuilder?;
    }
    _introductoryGetable?.checkTypes(library, typeEnvironment, setterBuilder,
        isExternal: isExternal, isAbstract: isAbstract);
    _introductorySetable?.checkTypes(library, typeEnvironment,
        isExternal: isExternal, isAbstract: isAbstract);
    List<SourcePropertyBuilder>? getterAugmentations = _getterAugmentations;
    if (getterAugmentations != null) {
      for (SourcePropertyBuilder augmentation in getterAugmentations) {
        augmentation.checkTypes(libraryBuilder, nameSpace, typeEnvironment);
      }
    }
    List<SourcePropertyBuilder>? setterAugmentations = _setterAugmentations;
    if (setterAugmentations != null) {
      for (SourcePropertyBuilder augmentation in setterAugmentations) {
        augmentation.checkTypes(libraryBuilder, nameSpace, typeEnvironment);
      }
    }
  }

  @override
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    if (!isClassInstanceMember) return;
    _introductoryGetable?.checkVariance(sourceClassBuilder, typeEnvironment);
    _introductorySetable?.checkVariance(sourceClassBuilder, typeEnvironment);
    List<SourcePropertyBuilder>? getterAugmentations = _getterAugmentations;
    if (getterAugmentations != null) {
      for (SourcePropertyBuilder augmentation in getterAugmentations) {
        augmentation.checkVariance(sourceClassBuilder, typeEnvironment);
      }
    }
    List<SourcePropertyBuilder>? setterAugmentations = _setterAugmentations;
    if (setterAugmentations != null) {
      for (SourcePropertyBuilder augmentation in setterAugmentations) {
        augmentation.checkVariance(sourceClassBuilder, typeEnvironment);
      }
    }
  }

  @override
  Iterable<Reference> get exportedMemberReferences => [
        if (_getterReference != null) _getterReference,
        if (_setterReference != null) _setterReference
      ];

  @override
  Member? get invokeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAssignable =>
      throw new UnsupportedError('$runtimeType.isAssignable');

  List<ClassMember>? _localMembers;

  List<ClassMember>? _localSetters;

  @override
  List<ClassMember> get localMembers => _localMembers ??= [
        if (_introductoryGetable != null)
          new _GetterClassMember(this, _introductoryGetable!)
      ];

  @override
  List<ClassMember> get localSetters => _localSetters ??= [
        if (_introductorySetable != null && !isConflictingSetter)
          new _SetterClassMember(this, _introductorySetable!)
      ];

  @override
  Name get memberName => _memberName.name;

  @override
  Member? get readTarget =>
      isAugmenting ? _origin!.readTarget : _introductoryGetable?.readTarget;

  @override
  Member? get writeTarget =>
      isAugmenting ? _origin!.writeTarget : _introductorySetable?.writeTarget;

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    int count = 0;
    if (_introductoryGetable != null) {
      count += _introductoryGetable!
          .computeDefaultTypes(context, inErrorRecovery: inErrorRecovery);
    }
    if (_introductorySetable != null) {
      count += _introductorySetable!
          .computeDefaultTypes(context, inErrorRecovery: inErrorRecovery);
    }
    return count;
  }

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<MetadataBuilder>? get metadataForTesting =>
      _introductoryGetable?.metadata ?? _introductorySetable?.metadata;

  // Coverage-ignore(suite): Not run.
  // TODO(johnniwinther): Remove these (or reinterpret them). These are used
  // for testing and macros by rely on old assumptions of the builder model.
  List<NominalParameterBuilder>? get typeParametersForTesting =>
      _introductoryGetable?.typeParametersForTesting ??
      _introductorySetable?.typeParametersForTesting;

  // Coverage-ignore(suite): Not run.
  List<FormalParameterBuilder>? get formalsForTesting =>
      _introductoryGetable?.formalsForTesting ??
      _introductorySetable?.formalsForTesting;

  // Coverage-ignore(suite): Not run.
  TypeBuilder? get returnTypeForTesting =>
      _introductoryGetable?.returnType ?? _introductorySetable?.returnType;

  @override
  bool get isAugmenting => this != origin;

  @override
  bool get isProperty => true;

  // TODO(johnniwinther): Remove this. Maybe replace with `hasGetter`?
  @override
  bool get isGetter => _introductoryGetable != null;

  // TODO(johnniwinther): Remove this. Maybe replace with `hasSetter`?
  @override
  bool get isSetter => _introductorySetable != null;

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

  Set<ClassMember>? _setterOverrideDependencies;

  void _registerSetterOverrideDependency(Set<ClassMember> overriddenMembers) {
    assert(
        overriddenMembers.every((overriddenMember) =>
            overriddenMember.declarationBuilder != classBuilder),
        "Unexpected override dependencies for $this: $overriddenMembers");
    _setterOverrideDependencies ??= {};
    _setterOverrideDependencies!.addAll(overriddenMembers);
  }

  void _ensureTypes(ClassMembersBuilder membersBuilder) {
    if (_typeEnsured) return;
    _introductoryGetable?.ensureTypes(membersBuilder,
        declarationBuilder as SourceClassBuilder, _getterOverrideDependencies);
    _getterOverrideDependencies = null;
    _introductorySetable?.ensureTypes(membersBuilder,
        declarationBuilder as SourceClassBuilder, _setterOverrideDependencies);
    _setterOverrideDependencies = null;
    _typeEnsured = true;
  }

  static DartType getSetterType(SourcePropertyBuilder setterBuilder,
      {required List<TypeParameter>? getterExtensionTypeParameters}) {
    DartType setterType;
    Procedure procedure = setterBuilder.writeTarget as Procedure;
    if (setterBuilder.isExtensionInstanceMember ||
        setterBuilder.isExtensionTypeInstanceMember) {
      // An extension instance setter
      //
      //     extension E<T> on A {
      //       void set property(T value) { ... }
      //     }
      //
      // is encoded as a top level method
      //
      //   void E#set#property<T#>(A #this, T# value) { ... }
      //
      // Similarly for extension type instance setters.
      //
      setterType = procedure.function.positionalParameters[1].type;
      if (getterExtensionTypeParameters != null &&
          getterExtensionTypeParameters.isNotEmpty) {
        // We substitute the setter type parameters for the getter type
        // parameters to check them below in a shared context.
        List<TypeParameter> setterExtensionTypeParameters =
            procedure.function.typeParameters;
        assert(getterExtensionTypeParameters.length ==
            setterExtensionTypeParameters.length);
        setterType = Substitution.fromPairs(
                setterExtensionTypeParameters,
                new List<DartType>.generate(
                    getterExtensionTypeParameters.length,
                    (int index) => new TypeParameterType.forAlphaRenaming(
                        setterExtensionTypeParameters[index],
                        getterExtensionTypeParameters[index])))
            .substituteType(setterType);
      }
    } else {
      setterType = procedure.setterType;
    }
    return setterType;
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

class _SetterClassMember implements ClassMember {
  final SourcePropertyBuilder _builder;
  final SetterFragment _fragment;
  late final Covariance _covariance =
      new Covariance.fromSetter(_builder.writeTarget as Procedure);

  _SetterClassMember(this._builder, this._fragment);

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
  bool get forSetter => true;

  @override
  // Coverage-ignore(suite): Not run.
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
    return _builder.writeTarget!;
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
  bool get isGetter => false;

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
  // Coverage-ignore(suite): Not run.
  bool isSameDeclaration(ClassMember other) {
    return other is _GetterClassMember && _builder == other._builder;
  }

  @override
  bool get isSetter => true;

  @override
  bool get isSourceDeclaration => true;

  @override
  bool get isStatic => _fragment.modifiers.isStatic;

  @override
  bool get isSynthesized => false;

  @override
  ClassMemberKind get memberKind => ClassMemberKind.Setter;

  @override
  Name get name => _builder.memberName;

  @override
  void registerOverrideDependency(Set<ClassMember> overriddenMembers) {
    _builder._registerSetterOverrideDependency(overriddenMembers);
  }

  @override
  String toString() => '$runtimeType($fullName,forSetter=${forSetter})';
}
