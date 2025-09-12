// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/metadata/expressions.dart' as shared;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../api_prototype/experimental_flags.dart';
import '../base/messages.dart';
import '../base/name_space.dart';
import '../base/uri_offset.dart';
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/property_builder.dart';
import '../fragment/field/declaration.dart';
import '../fragment/getter/declaration.dart';
import '../fragment/setter/declaration.dart';
import '../kernel/hierarchy/class_member.dart';
import '../kernel/hierarchy/members_builder.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/member_covariance.dart';
import '../kernel/type_algorithms.dart';
import '../util/reference_map.dart';
import 'name_scheme.dart';
import 'source_class_builder.dart';
import 'source_library_builder.dart';
import 'source_member_builder.dart';

class SourcePropertyBuilder extends SourceMemberBuilderImpl
    implements PropertyBuilder {
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
  FieldDeclaration? _introductoryField;
  GetterDeclaration? _introductoryGetable;
  List<GetterDeclaration>? _getterAugmentations;
  List<GetterDeclaration>? _augmentedGetables;
  GetterDeclaration? _lastGetable;

  SetterDeclaration? _introductorySetable;
  List<SetterDeclaration>? _setterAugmentations;
  List<SetterDeclaration>? _augmentedSetables;
  SetterDeclaration? _lastSetable;

  final PropertyReferences _references;

  final MemberName _memberName;

  SourcePropertyBuilder({
    required this.fileUri,
    required this.fileOffset,
    required this.name,
    required this.libraryBuilder,
    required this.declarationBuilder,
    required NameScheme nameScheme,
    required FieldDeclaration? fieldDeclaration,
    required GetterDeclaration? getterDeclaration,
    required List<GetterDeclaration> getterAugmentations,
    required SetterDeclaration? setterDeclaration,
    required List<SetterDeclaration> setterAugmentations,
    required this.isStatic,
    required PropertyReferences references,
  }) : _nameScheme = nameScheme,
       _introductoryField = fieldDeclaration,
       _introductoryGetable = getterDeclaration,
       _getterAugmentations = getterAugmentations,
       _introductorySetable = setterDeclaration,
       _setterAugmentations = setterAugmentations,
       _references = references,
       _memberName = nameScheme.getDeclaredName(name) {
    if (getterAugmentations.isEmpty) {
      _augmentedGetables = getterAugmentations;
      _lastGetable = getterDeclaration;
    } else if (getterDeclaration != null) {
      _augmentedGetables = [getterDeclaration, ...getterAugmentations];
      _lastGetable = _augmentedGetables!.removeLast();
    }
    if (setterAugmentations.isEmpty) {
      _augmentedSetables = setterAugmentations;
      _lastSetable = setterDeclaration;
    } else if (setterDeclaration != null) {
      _augmentedSetables = [setterDeclaration, ...setterAugmentations];
      _lastSetable = _augmentedSetables!.removeLast();
    }
  }

  @override
  Builder get parent => declarationBuilder ?? libraryBuilder;

  @override
  bool get hasConstField => _introductoryField?.isConst ?? false;

  @override
  bool get isSynthesized => false;

  @override
  bool get isEnumElement => _introductoryField?.isEnumElement ?? false;

  @override
  MemberBuilder? get getable => hasGetter ? this : null;

  @override
  MemberBuilder? get setable => hasSetter ? this : null;

  @override
  int buildBodyNodes(BuildNodesCallback f) => 0;

  @override
  void buildOutlineNodes(BuildNodesCallback f) {
    _introductoryField?.buildFieldOutlineNode(
      libraryBuilder,
      _nameScheme,
      f,
      _references,
      classTypeParameters: classBuilder?.cls.typeParameters,
    );

    List<GetterDeclaration>? augmentedGetables = _augmentedGetables;
    if (augmentedGetables != null) {
      for (GetterDeclaration augmented in augmentedGetables) {
        augmented.buildGetterOutlineNode(
          libraryBuilder: libraryBuilder,
          nameScheme: _nameScheme,
          f: noAddBuildNodesCallback,
          // Augmented getters don't reuse references.
          references: null,
          classTypeParameters: classBuilder?.cls.typeParameters,
        );
      }
    }
    _lastGetable?.buildGetterOutlineNode(
      libraryBuilder: libraryBuilder,
      nameScheme: _nameScheme,
      f: f,
      references: _references,
      classTypeParameters: classBuilder?.cls.typeParameters,
    );

    List<SetterDeclaration>? augmentedSetables = _augmentedSetables;
    if (augmentedSetables != null) {
      for (SetterDeclaration augmented in augmentedSetables) {
        augmented.buildSetterOutlineNode(
          libraryBuilder: libraryBuilder,
          nameScheme: _nameScheme,
          f: noAddBuildNodesCallback,
          // Augmented setters don't reuse references.
          references: null,
          classTypeParameters: classBuilder?.cls.typeParameters,
        );
      }
    }
    _lastSetable?.buildSetterOutlineNode(
      libraryBuilder: libraryBuilder,
      nameScheme: _nameScheme,
      f: f,
      references: _references,
      classTypeParameters: classBuilder?.cls.typeParameters,
    );
  }

  bool hasBuiltOutlineExpressions = false;

  @override
  void buildOutlineExpressions(
    ClassHierarchy classHierarchy,
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  ) {
    if (!hasBuiltOutlineExpressions) {
      _introductoryField?.buildFieldOutlineExpressions(
        classHierarchy: classHierarchy,
        libraryBuilder: libraryBuilder,
        declarationBuilder: declarationBuilder,
        annotatables: [
          readTarget as Annotatable,
          if (writeTarget != null && readTarget != writeTarget)
            writeTarget as Annotatable,
        ],
        annotatablesFileUri: readTarget!.fileUri,
        isClassInstanceMember: isClassInstanceMember,
      );
      _introductoryGetable?.buildGetterOutlineExpressions(
        classHierarchy: classHierarchy,
        libraryBuilder: libraryBuilder,
        declarationBuilder: declarationBuilder,
        propertyBuilder: this,
        annotatable: readTarget as Annotatable,
        annotatableFileUri: readTarget!.fileUri,
        isClassInstanceMember: isClassInstanceMember,
      );
      List<GetterDeclaration>? getterAugmentations = _getterAugmentations;
      if (getterAugmentations != null) {
        for (GetterDeclaration augmentation in getterAugmentations) {
          augmentation.buildGetterOutlineExpressions(
            classHierarchy: classHierarchy,
            libraryBuilder: libraryBuilder,
            declarationBuilder: declarationBuilder,
            propertyBuilder: this,
            annotatable: readTarget as Annotatable,
            annotatableFileUri: readTarget!.fileUri,
            isClassInstanceMember: isClassInstanceMember,
          );
        }
      }
      _introductorySetable?.buildSetterOutlineExpressions(
        classHierarchy: classHierarchy,
        libraryBuilder: libraryBuilder,
        declarationBuilder: declarationBuilder,
        propertyBuilder: this,
        annotatable: writeTarget as Annotatable,
        annotatableFileUri: writeTarget!.fileUri,
        isClassInstanceMember: isClassInstanceMember,
      );
      List<SetterDeclaration>? setterAugmentations = _setterAugmentations;
      if (setterAugmentations != null) {
        for (SetterDeclaration augmentation in setterAugmentations) {
          augmentation.buildSetterOutlineExpressions(
            classHierarchy: classHierarchy,
            libraryBuilder: libraryBuilder,
            declarationBuilder: declarationBuilder,
            propertyBuilder: this,
            annotatable: writeTarget as Annotatable,
            annotatableFileUri: writeTarget!.fileUri,
            isClassInstanceMember: isClassInstanceMember,
          );
        }
      }
      hasBuiltOutlineExpressions = true;
    }
  }

  @override
  void checkTypes(
    ProblemReporting problemReporting,
    LibraryFeatures libraryFeatures,
    NameSpace nameSpace,
    TypeEnvironment typeEnvironment,
  ) {
    SourcePropertyBuilder? setterBuilder;
    if (!isClassMember) {
      // Getter/setter type conflict for class members is handled in the class
      // hierarchy builder.
      setterBuilder = nameSpace.lookup(name)?.setable as SourcePropertyBuilder?;
    }
    _introductoryField?.checkFieldTypes(
      problemReporting,
      typeEnvironment,
      setterBuilder,
    );

    _introductoryGetable?.checkGetterTypes(
      problemReporting,
      libraryFeatures,
      typeEnvironment,
      setterBuilder,
    );
    List<GetterDeclaration>? getterAugmentations = _getterAugmentations;
    if (getterAugmentations != null) {
      for (GetterDeclaration augmentation in getterAugmentations) {
        augmentation.checkGetterTypes(
          problemReporting,
          libraryFeatures,
          typeEnvironment,
          setterBuilder,
        );
      }
    }
    _introductorySetable?.checkSetterTypes(problemReporting, typeEnvironment);
    List<SetterDeclaration>? setterAugmentations = _setterAugmentations;
    if (setterAugmentations != null) {
      for (SetterDeclaration augmentation in setterAugmentations) {
        augmentation.checkSetterTypes(problemReporting, typeEnvironment);
      }
    }
  }

  @override
  void checkVariance(
    SourceClassBuilder sourceClassBuilder,
    TypeEnvironment typeEnvironment,
  ) {
    if (!isClassInstanceMember) return;
    _introductoryField?.checkFieldVariance(sourceClassBuilder, typeEnvironment);

    _introductoryGetable?.checkGetterVariance(
      sourceClassBuilder,
      typeEnvironment,
    );
    List<GetterDeclaration>? getterAugmentations = _getterAugmentations;
    if (getterAugmentations != null) {
      for (GetterDeclaration augmentation in getterAugmentations) {
        augmentation.checkGetterVariance(sourceClassBuilder, typeEnvironment);
      }
    }

    _introductorySetable?.checkSetterVariance(
      sourceClassBuilder,
      typeEnvironment,
    );
    List<SetterDeclaration>? setterAugmentations = _setterAugmentations;
    if (setterAugmentations != null) {
      for (SetterDeclaration augmentation in setterAugmentations) {
        augmentation.checkSetterVariance(sourceClassBuilder, typeEnvironment);
      }
    }
  }

  @override
  Iterable<Reference> get exportedMemberReferences => [
    ...?_lastGetable?.getExportedGetterReferences(_references),
    ...?_lastSetable?.getExportedSetterReferences(_references),
  ];

  // TODO(johnniwinther): Should fields and getters have an invoke target?
  @override
  Member? get invokeTarget => readTarget;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get invokeTargetReference => readTargetReference;

  List<ClassMember>? _localMembers;

  List<ClassMember>? _localSetters;

  @override
  List<ClassMember> get localMembers =>
      _localMembers ??= _introductoryGetable?.localMembers ?? const [];

  @override
  List<ClassMember> get localSetters =>
      _localSetters ??= _introductorySetable?.localSetters ?? const [];

  @override
  Name get memberName => _memberName.name;

  @override
  Member? get readTarget => _lastGetable?.readTarget;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get readTargetReference => _references.getterReference;

  @override
  Member? get writeTarget => _lastSetable?.writeTarget;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => _references.setterReference;

  @override
  int computeDefaultTypes(
    ComputeDefaultTypeContext context, {
    required bool inErrorRecovery,
  }) {
    int count = 0;
    if (_introductoryField != null) {
      count += _introductoryField!.computeFieldDefaultTypes(context);
    }

    if (_introductoryGetable != null) {
      count += _introductoryGetable!.computeGetterDefaultTypes(context);
    }
    List<GetterDeclaration>? getterAugmentations = _getterAugmentations;
    if (getterAugmentations != null) {
      for (GetterDeclaration augmentation in getterAugmentations) {
        count += augmentation.computeGetterDefaultTypes(context);
      }
    }

    if (_introductorySetable != null) {
      count += _introductorySetable!.computeSetterDefaultTypes(context);
    }
    List<SetterDeclaration>? setterAugmentations = _setterAugmentations;
    if (setterAugmentations != null) {
      for (SetterDeclaration augmentation in setterAugmentations) {
        count += augmentation.computeSetterDefaultTypes(context);
      }
    }
    return count;
  }

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<MetadataBuilder>? get metadataForTesting =>
      _introductoryGetable?.metadata ?? _introductorySetable?.metadata;

  @override
  bool get isProperty => true;

  bool _typeEnsured = false;
  ClassMembersBuilder? _classMembersBuilder;
  Set<ClassMember>? _getterOverrideDependencies;

  void registerGetterOverrideDependency(
    ClassMembersBuilder membersBuilder,
    Set<ClassMember> overriddenMembers,
  ) {
    assert(
      overriddenMembers.every(
        (overriddenMember) =>
            overriddenMember.declarationBuilder != classBuilder,
      ),
      "Unexpected override dependencies for $this: $overriddenMembers",
    );
    _classMembersBuilder ??= membersBuilder;
    _getterOverrideDependencies ??= {};
    _getterOverrideDependencies!.addAll(overriddenMembers);
  }

  Set<ClassMember>? _setterOverrideDependencies;

  void registerSetterOverrideDependency(
    ClassMembersBuilder membersBuilder,
    Set<ClassMember> overriddenMembers,
  ) {
    assert(
      overriddenMembers.every(
        (overriddenMember) =>
            overriddenMember.declarationBuilder != classBuilder,
      ),
      "Unexpected override dependencies for $this: $overriddenMembers",
    );
    _classMembersBuilder ??= membersBuilder;
    _setterOverrideDependencies ??= {};
    _setterOverrideDependencies!.addAll(overriddenMembers);
  }

  void inferTypesFromOverrides() {
    if (_typeEnsured) return;
    ClassMembersBuilder? classMembersBuilder = _classMembersBuilder;
    if (classMembersBuilder != null) {
      Set<ClassMember>? getterOverrideDependencies =
          _getterOverrideDependencies;
      Set<ClassMember>? setterOverrideDependencies =
          _setterOverrideDependencies;

      assert(
        getterOverrideDependencies != null ||
            setterOverrideDependencies != null,
      );

      _introductoryField?.ensureTypes(
        classMembersBuilder,
        getterOverrideDependencies,
        setterOverrideDependencies,
      );

      _introductoryGetable?.ensureGetterTypes(
        libraryBuilder: libraryBuilder,
        declarationBuilder: declarationBuilder,
        membersBuilder: classMembersBuilder,
        getterOverrideDependencies: getterOverrideDependencies,
      );
      List<GetterDeclaration>? getterAugmentations = _getterAugmentations;
      if (getterAugmentations != null) {
        for (GetterDeclaration augmentation in getterAugmentations) {
          // Coverage-ignore-block(suite): Not run.
          augmentation.ensureGetterTypes(
            libraryBuilder: libraryBuilder,
            declarationBuilder: declarationBuilder,
            membersBuilder: classMembersBuilder,
            getterOverrideDependencies: getterOverrideDependencies,
          );
        }
      }

      _introductorySetable?.ensureSetterTypes(
        libraryBuilder: libraryBuilder,
        declarationBuilder: declarationBuilder,
        membersBuilder: classMembersBuilder,
        setterOverrideDependencies: setterOverrideDependencies,
      );
      List<SetterDeclaration>? setterAugmentations = _setterAugmentations;
      if (setterAugmentations != null) {
        for (SetterDeclaration augmentation in setterAugmentations) {
          // Coverage-ignore-block(suite): Not run.
          augmentation.ensureSetterTypes(
            libraryBuilder: libraryBuilder,
            declarationBuilder: declarationBuilder,
            membersBuilder: classMembersBuilder,
            setterOverrideDependencies: setterOverrideDependencies,
          );
        }
      }

      _getterOverrideDependencies = null;
      _setterOverrideDependencies = null;
      _classMembersBuilder = null;
    }
    _typeEnsured = true;
  }

  static DartType getSetterType(
    SourcePropertyBuilder setterBuilder, {
    required List<TypeParameter>? getterExtensionTypeParameters,
  }) {
    DartType setterType;
    Member member = setterBuilder.writeTarget!;
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
      Procedure procedure = member as Procedure;
      setterType = procedure.function.positionalParameters[1].type;
      if (getterExtensionTypeParameters != null &&
          getterExtensionTypeParameters.isNotEmpty) {
        // We substitute the setter type parameters for the getter type
        // parameters to check them below in a shared context.
        List<TypeParameter> setterExtensionTypeParameters =
            procedure.function.typeParameters;
        assert(
          getterExtensionTypeParameters.length ==
              setterExtensionTypeParameters.length,
        );
        setterType = Substitution.fromPairs(setterExtensionTypeParameters, [
          for (TypeParameter parameter in getterExtensionTypeParameters)
            new TypeParameterType.withDefaultNullability(parameter),
        ]).substituteType(setterType);
      }
    } else {
      setterType = member.setterType;
    }
    return setterType;
  }

  DartType get fieldType {
    return _introductoryField!.fieldType;
  }

  /// Creates the [Initializer] for the invalid initialization of this field.
  ///
  /// This is only used for instance fields.
  Initializer buildErroneousInitializer(
    Expression effect,
    Expression value, {
    required int fileOffset,
  }) {
    return _introductoryField!.buildErroneousInitializer(
      effect,
      value,
      fileOffset: fileOffset,
    );
  }

  /// Creates the AST node for this field as the default initializer.
  ///
  /// This is only used for instance fields.
  void buildImplicitDefaultValue() {
    _introductoryField!.buildImplicitDefaultValue();
  }

  /// Create the [Initializer] for the implicit initialization of this field
  /// in a constructor.
  ///
  /// This is only used for instance fields.
  Initializer buildImplicitInitializer() {
    return _introductoryField!.buildImplicitInitializer();
  }

  /// Builds the [Initializer]s for each field used to encode this field
  /// using the [fileOffset] for the created nodes and [value] as the initial
  /// field value.
  ///
  /// This is only used for instance fields.
  List<Initializer> buildInitializer(
    int fileOffset,
    Expression value, {
    required bool isSynthetic,
  }) {
    return _introductoryField!.buildInitializer(
      fileOffset,
      value,
      isSynthetic: isSynthetic,
    );
  }

  bool get hasInitializer => _introductoryField!.hasInitializer;

  bool get isExtensionTypeDeclaredInstanceField =>
      _introductoryField!.isExtensionTypeDeclaredInstanceField;

  @override
  bool get isFinal => _introductoryField!.isFinal;

  bool get isLate => _introductoryField!.isLate;

  DartType inferFieldType(ClassHierarchyBase hierarchy) {
    inferTypesFromOverrides();
    return _introductoryField!.inferType(hierarchy);
  }

  // Coverage-ignore(suite): Not run.
  shared.Expression? get initializerExpression =>
      _introductoryField?.initializerExpression;

  @override
  FieldQuality get fieldQuality =>
      _introductoryField?.fieldQuality ?? FieldQuality.Absent;

  @override
  GetterQuality get getterQuality =>
      _lastGetable?.getterQuality ?? GetterQuality.Absent;

  @override
  SetterQuality get setterQuality =>
      _lastSetable?.setterQuality ?? SetterQuality.Absent;

  UriOffsetLength? get fieldUriOffset => _introductoryField?.uriOffset;

  @override
  UriOffsetLength? get getterUriOffset => _introductoryGetable?.uriOffset;

  @override
  UriOffsetLength? get setterUriOffset => _introductorySetable?.uriOffset;
}

class GetterClassMember implements ClassMember {
  final SourcePropertyBuilder _builder;

  GetterClassMember(this._builder);

  @override
  UriOffsetLength get uriOffset => _builder.getterUriOffset!;

  @override
  DeclarationBuilder get declarationBuilder => _builder.declarationBuilder!;

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get declarations =>
      throw new UnsupportedError('$runtimeType.declarations');

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
  // Coverage-ignore(suite): Not run.
  MemberResult getMemberResult(ClassMembersBuilder membersBuilder) {
    if (isStatic) {
      return new StaticMemberResult(
        getMember(membersBuilder),
        memberKind,
        isDeclaredAsField: false,
        fullName: '${declarationBuilder.name}.${_builder.memberName.text}',
      );
    } else if (_builder.isExtensionTypeMember) {
      ExtensionTypeDeclaration extensionTypeDeclaration =
          (declarationBuilder as ExtensionTypeDeclarationBuilder)
              .extensionTypeDeclaration;
      Member member = getTearOff(membersBuilder) ?? getMember(membersBuilder);
      return new ExtensionTypeMemberResult(
        extensionTypeDeclaration,
        member,
        memberKind,
        name,
        isDeclaredAsField: false,
      );
    } else {
      return new TypeDeclarationInstanceMemberResult(
        getMember(membersBuilder),
        memberKind,
        isDeclaredAsField: false,
      );
    }
  }

  @override
  Member? getTearOff(ClassMembersBuilder membersBuilder) => null;

  @override
  bool get hasDeclarations => false;

  @override
  void inferType(ClassMembersBuilder membersBuilder) {
    _builder.inferTypesFromOverrides();
  }

  @override
  ClassMember get interfaceMember => this;

  @override
  bool get isAbstract => _builder.hasAbstractGetter;

  @override
  bool get isDuplicate => _builder.isDuplicate;

  @override
  bool get isExtensionTypeMember => _builder.isExtensionTypeMember;

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
    return other is GetterClassMember &&
        // Coverage-ignore(suite): Not run.
        _builder == other._builder;
  }

  @override
  bool get isSetter => false;

  @override
  bool get isSourceDeclaration => true;

  @override
  bool get isStatic => _builder.isStatic;

  @override
  bool get isSynthesized => false;

  @override
  ClassMemberKind get memberKind => ClassMemberKind.Getter;

  @override
  Name get name => _builder.memberName;

  @override
  void registerOverrideDependency(
    ClassMembersBuilder membersBuilder,
    Set<ClassMember> overriddenMembers,
  ) {
    _builder.registerGetterOverrideDependency(
      membersBuilder,
      overriddenMembers,
    );
  }

  @override
  String toString() => '$runtimeType($fullName,forSetter=${forSetter})';
}

class SetterClassMember implements ClassMember {
  final SourcePropertyBuilder _builder;
  late final Covariance _covariance = new Covariance.fromSetter(
    _builder.writeTarget as Procedure,
  );

  SetterClassMember(this._builder);

  @override
  UriOffsetLength get uriOffset => _builder.setterUriOffset!;

  @override
  DeclarationBuilder get declarationBuilder => _builder.declarationBuilder!;

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get declarations =>
      throw new UnsupportedError('$runtimeType.declarations');

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
  // Coverage-ignore(suite): Not run.
  MemberResult getMemberResult(ClassMembersBuilder membersBuilder) {
    if (isStatic) {
      return new StaticMemberResult(
        getMember(membersBuilder),
        memberKind,
        isDeclaredAsField: false,
        fullName: '${declarationBuilder.name}.${_builder.memberName.text}',
      );
    } else if (_builder.isExtensionTypeMember) {
      ExtensionTypeDeclaration extensionTypeDeclaration =
          (declarationBuilder as ExtensionTypeDeclarationBuilder)
              .extensionTypeDeclaration;
      Member member = getTearOff(membersBuilder) ?? getMember(membersBuilder);
      return new ExtensionTypeMemberResult(
        extensionTypeDeclaration,
        member,
        memberKind,
        name,
        isDeclaredAsField: false,
      );
    } else {
      return new TypeDeclarationInstanceMemberResult(
        getMember(membersBuilder),
        memberKind,
        isDeclaredAsField: false,
      );
    }
  }

  @override
  Member? getTearOff(ClassMembersBuilder membersBuilder) => null;

  @override
  bool get hasDeclarations => false;

  @override
  void inferType(ClassMembersBuilder membersBuilder) {
    _builder.inferTypesFromOverrides();
  }

  @override
  ClassMember get interfaceMember => this;

  @override
  bool get isAbstract => _builder.hasAbstractSetter;

  @override
  bool get isDuplicate => _builder.isDuplicate;

  @override
  bool get isExtensionTypeMember => _builder.isExtensionTypeMember;

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
    return other is SetterClassMember && _builder == other._builder;
  }

  @override
  bool get isSetter => true;

  @override
  bool get isSourceDeclaration => true;

  @override
  bool get isStatic => _builder.isStatic;

  @override
  bool get isSynthesized => false;

  @override
  ClassMemberKind get memberKind => ClassMemberKind.Setter;

  @override
  Name get name => _builder.memberName;

  @override
  void registerOverrideDependency(
    ClassMembersBuilder membersBuilder,
    Set<ClassMember> overriddenMembers,
  ) {
    _builder.registerSetterOverrideDependency(
      membersBuilder,
      overriddenMembers,
    );
  }

  @override
  String toString() => '$runtimeType($fullName,forSetter=${forSetter})';
}

/// [Reference]s used for the [Member] nodes created for a property.
class PropertyReferences {
  Reference? _fieldReference;
  Reference? _getterReference;
  Reference? _setterReference;

  /// Creates a [PropertyReferences] object preloaded with the
  /// [preExistingFieldReference], [preExistingGetterReference] and
  /// [preExistingSetterReference].
  ///
  /// For initial/one-off compilations these are `null`, but for subsequent
  /// compilations during an incremental compilation, these are the references
  /// used for the same field, getter, and setter in the previous compilation.
  PropertyReferences._({
    required Reference? preExistingFieldReference,
    required Reference? preExistingGetterReference,
    required Reference? preExistingSetterReference,
  }) : _fieldReference = preExistingFieldReference,
       _getterReference = preExistingGetterReference,
       _setterReference = preExistingSetterReference;

  /// Creates a [PropertyReferences] object preloaded with the pre-existing
  /// references from [indexedContainer], if available.
  factory PropertyReferences(
    String name,
    NameScheme nameScheme,
    IndexedContainer? indexedContainer, {
    required bool fieldIsLateWithLowering,
  }) {
    Reference? preExistingGetterReference;
    Reference? preExistingSetterReference;
    Reference? preExistingFieldReference;
    if (indexedContainer != null) {
      Name getterNameToLookup = nameScheme
          .getProcedureMemberName(ProcedureKind.Getter, name)
          .name;
      preExistingGetterReference = indexedContainer.lookupGetterReference(
        getterNameToLookup,
      );

      Name setterNameToLookup = nameScheme
          .getProcedureMemberName(ProcedureKind.Setter, name)
          .name;
      if ((nameScheme.isExtensionMember || nameScheme.isExtensionTypeMember) &&
          nameScheme.isInstanceMember) {
        // Extension (type) instance setters are encoded as methods.
        preExistingSetterReference = indexedContainer.lookupGetterReference(
          setterNameToLookup,
        );
      } else {
        preExistingSetterReference = indexedContainer.lookupSetterReference(
          setterNameToLookup,
        );
      }

      Name fieldNameToLookup = nameScheme
          .getFieldMemberName(
            FieldNameType.Field,
            name,
            isSynthesized: fieldIsLateWithLowering,
          )
          .name;
      preExistingFieldReference = indexedContainer.lookupFieldReference(
        fieldNameToLookup,
      );
    }

    return new PropertyReferences._(
      preExistingFieldReference: preExistingFieldReference,
      preExistingGetterReference: preExistingGetterReference,
      preExistingSetterReference: preExistingSetterReference,
    );
  }

  /// Registers that [builder] is created for the pre-existing references
  /// provided in [PropertyReferences._].
  ///
  /// This must be called before [fieldReference], [getterReference] and
  /// [setterReference] are accessed.
  void registerReference(
    ReferenceMap referenceMap,
    SourcePropertyBuilder builder,
  ) {
    if (_fieldReference != null) {
      referenceMap.registerNamedBuilder(_fieldReference!, builder);
    }
    if (_getterReference != null) {
      referenceMap.registerNamedBuilder(_getterReference!, builder);
    }
    if (_setterReference != null) {
      referenceMap.registerNamedBuilder(_setterReference!, builder);
    }
  }

  /// The [Reference] used to refer to the field aspect of the [Field] node
  /// created for this property.
  Reference get fieldReference => _fieldReference ??= new Reference();

  /// The [Reference] used to refer to the getter aspect of the [Member] node(s)
  /// created for this property.
  Reference get getterReference => _getterReference ??= new Reference();

  /// The [Reference] used to refer to the setter aspect of the [Member] node(s)
  /// created for this property.
  Reference get setterReference => _setterReference ??= new Reference();
}
