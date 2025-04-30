// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/metadata/expressions.dart' as shared;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../base/modifiers.dart';
import '../base/name_space.dart';
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
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
import 'name_scheme.dart';
import 'source_class_builder.dart';
import 'source_library_builder.dart';
import 'source_loader.dart';
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

  Modifiers _modifiers;

  final PropertyReferences _references;

  final MemberName _memberName;

  SourcePropertyBuilder.forGetter(
      {required this.fileUri,
      required this.fileOffset,
      required this.name,
      required this.libraryBuilder,
      required this.declarationBuilder,
      required NameScheme nameScheme,
      required GetterDeclaration declaration,
      required List<GetterDeclaration> augmentations,
      required Modifiers modifiers,
      required PropertyReferences references})
      : _nameScheme = nameScheme,
        _introductoryGetable = declaration,
        _getterAugmentations = augmentations,
        _modifiers = modifiers,
        _references = references,
        _memberName = nameScheme.getDeclaredName(name) {
    if (augmentations.isEmpty) {
      _augmentedGetables = augmentations;
      _lastGetable = declaration;
    } else {
      _augmentedGetables = [declaration, ...augmentations];
      _lastGetable = _augmentedGetables!.removeLast();
    }
  }

  SourcePropertyBuilder.forSetter(
      {required this.fileUri,
      required this.fileOffset,
      required this.name,
      required this.libraryBuilder,
      required this.declarationBuilder,
      required NameScheme nameScheme,
      required SetterDeclaration declaration,
      required List<SetterDeclaration> augmentations,
      required Modifiers modifiers,
      required PropertyReferences references})
      : _nameScheme = nameScheme,
        _introductorySetable = declaration,
        _setterAugmentations = augmentations,
        _modifiers = modifiers,
        _references = references,
        _memberName = nameScheme.getDeclaredName(name) {
    if (augmentations.isEmpty) {
      _augmentedSetables = augmentations;
      _lastSetable = declaration;
    } else {
      _augmentedSetables = [declaration, ...augmentations];
      _lastSetable = _augmentedSetables!.removeLast();
    }
  }

  SourcePropertyBuilder.forField(
      {required this.fileUri,
      required this.fileOffset,
      required this.name,
      required this.libraryBuilder,
      required this.declarationBuilder,
      required NameScheme nameScheme,
      required FieldDeclaration fieldDeclaration,
      required GetterDeclaration getterDeclaration,
      required SetterDeclaration? setterDeclaration,
      required Modifiers modifiers,
      required PropertyReferences references})
      : _nameScheme = nameScheme,
        _introductoryField = fieldDeclaration,
        _introductoryGetable = getterDeclaration,
        _introductorySetable = setterDeclaration,
        _modifiers = modifiers,
        _references = references,
        _memberName = nameScheme.getDeclaredName(name) {
    _lastGetable = getterDeclaration;
    _augmentedGetables = const [];
    _lastSetable = setterDeclaration;
    if (setterDeclaration != null) {
      _augmentedSetables = const [];
    }
  }

  @override
  Builder get parent => declarationBuilder ?? libraryBuilder;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAugmentation => _modifiers.isAugment;

  @override
  bool get isStatic => _modifiers.isStatic;

  @override
  bool get hasConstField => _modifiers.isConst;

  @override
  bool get isSynthesized => false;

  @override
  bool get isEnumElement => _introductoryField?.isEnumElement ?? false;

  @override
  Builder? get getable =>
      _introductoryField != null || _introductoryGetable != null ? this : null;

  @override
  Builder? get setable =>
      _introductoryField != null && _introductoryField!.hasSetter ||
              _introductorySetable != null
          ? this
          : null;

  @override
  int buildBodyNodes(BuildNodesCallback f) => 0;

  @override
  void buildOutlineNodes(BuildNodesCallback f) {
    _introductoryField?.buildFieldOutlineNode(
        libraryBuilder, _nameScheme, f, _references as FieldReference,
        classTypeParameters: classBuilder?.cls.typeParameters);

    List<GetterDeclaration>? augmentedGetables = _augmentedGetables;
    if (augmentedGetables != null) {
      for (GetterDeclaration augmented in augmentedGetables) {
        augmented.buildGetterOutlineNode(
            libraryBuilder: libraryBuilder,
            nameScheme: _nameScheme,
            f: noAddBuildNodesCallback,
            // Augmented getters don't reuse references.
            references: null,
            classTypeParameters: classBuilder?.cls.typeParameters);
      }
    }
    _lastGetable?.buildGetterOutlineNode(
        libraryBuilder: libraryBuilder,
        nameScheme: _nameScheme,
        f: f,
        references: _references,
        classTypeParameters: classBuilder?.cls.typeParameters);

    List<SetterDeclaration>? augmentedSetables = _augmentedSetables;
    if (augmentedSetables != null) {
      for (SetterDeclaration augmented in augmentedSetables) {
        augmented.buildSetterOutlineNode(
            libraryBuilder: libraryBuilder,
            nameScheme: _nameScheme,
            f: noAddBuildNodesCallback,
            // Augmented setters don't reuse references.
            references: null,
            classTypeParameters: classBuilder?.cls.typeParameters);
      }
    }
    _lastSetable?.buildSetterOutlineNode(
        libraryBuilder: libraryBuilder,
        nameScheme: _nameScheme,
        f: f,
        references: _references,
        classTypeParameters: classBuilder?.cls.typeParameters);
  }

  bool hasBuiltOutlineExpressions = false;

  @override
  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (!hasBuiltOutlineExpressions) {
      _introductoryField?.buildFieldOutlineExpressions(
          classHierarchy: classHierarchy,
          libraryBuilder: libraryBuilder,
          declarationBuilder: declarationBuilder,
          annotatables: [
            readTarget as Annotatable,
            if (writeTarget != null && readTarget != writeTarget)
              writeTarget as Annotatable
          ],
          annotatablesFileUri: readTarget!.fileUri,
          isClassInstanceMember: isClassInstanceMember);
      _introductoryGetable?.buildGetterOutlineExpressions(
          classHierarchy: classHierarchy,
          libraryBuilder: libraryBuilder,
          declarationBuilder: declarationBuilder,
          propertyBuilder: this,
          annotatable: readTarget as Annotatable,
          annotatableFileUri: readTarget!.fileUri,
          isClassInstanceMember: isClassInstanceMember);
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
              isClassInstanceMember: isClassInstanceMember);
        }
      }
      _introductorySetable?.buildSetterOutlineExpressions(
          classHierarchy: classHierarchy,
          libraryBuilder: libraryBuilder,
          declarationBuilder: declarationBuilder,
          propertyBuilder: this,
          annotatable: writeTarget as Annotatable,
          annotatableFileUri: writeTarget!.fileUri,
          isClassInstanceMember: isClassInstanceMember);
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
              isClassInstanceMember: isClassInstanceMember);
        }
      }
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
    _introductoryField?.checkFieldTypes(
        library, typeEnvironment, setterBuilder);

    _introductoryGetable?.checkGetterTypes(
        library, typeEnvironment, setterBuilder);
    List<GetterDeclaration>? getterAugmentations = _getterAugmentations;
    if (getterAugmentations != null) {
      for (GetterDeclaration augmentation in getterAugmentations) {
        augmentation.checkGetterTypes(library, typeEnvironment, setterBuilder);
      }
    }
    _introductorySetable?.checkSetterTypes(library, typeEnvironment);
    List<SetterDeclaration>? setterAugmentations = _setterAugmentations;
    if (setterAugmentations != null) {
      for (SetterDeclaration augmentation in setterAugmentations) {
        augmentation.checkSetterTypes(library, typeEnvironment);
      }
    }
  }

  @override
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    if (!isClassInstanceMember) return;
    _introductoryField?.checkFieldVariance(sourceClassBuilder, typeEnvironment);

    _introductoryGetable?.checkGetterVariance(
        sourceClassBuilder, typeEnvironment);
    List<GetterDeclaration>? getterAugmentations = _getterAugmentations;
    if (getterAugmentations != null) {
      for (GetterDeclaration augmentation in getterAugmentations) {
        augmentation.checkGetterVariance(sourceClassBuilder, typeEnvironment);
      }
    }

    _introductorySetable?.checkSetterVariance(
        sourceClassBuilder, typeEnvironment);
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
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
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
      ClassMembersBuilder membersBuilder, Set<ClassMember> overriddenMembers) {
    assert(
        overriddenMembers.every((overriddenMember) =>
            overriddenMember.declarationBuilder != classBuilder),
        "Unexpected override dependencies for $this: $overriddenMembers");
    _classMembersBuilder ??= membersBuilder;
    _getterOverrideDependencies ??= {};
    _getterOverrideDependencies!.addAll(overriddenMembers);
  }

  Set<ClassMember>? _setterOverrideDependencies;

  void registerSetterOverrideDependency(
      ClassMembersBuilder membersBuilder, Set<ClassMember> overriddenMembers) {
    assert(
        overriddenMembers.every((overriddenMember) =>
            overriddenMember.declarationBuilder != classBuilder),
        "Unexpected override dependencies for $this: $overriddenMembers");
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

      assert(getterOverrideDependencies != null ||
          setterOverrideDependencies != null);

      _introductoryField?.ensureTypes(classMembersBuilder,
          getterOverrideDependencies, setterOverrideDependencies);

      _introductoryGetable?.ensureGetterTypes(
          libraryBuilder: libraryBuilder,
          declarationBuilder: declarationBuilder,
          membersBuilder: classMembersBuilder,
          getterOverrideDependencies: getterOverrideDependencies);
      List<GetterDeclaration>? getterAugmentations = _getterAugmentations;
      if (getterAugmentations != null) {
        for (GetterDeclaration augmentation in getterAugmentations) {
          // Coverage-ignore-block(suite): Not run.
          augmentation.ensureGetterTypes(
              libraryBuilder: libraryBuilder,
              declarationBuilder: declarationBuilder,
              membersBuilder: classMembersBuilder,
              getterOverrideDependencies: getterOverrideDependencies);
        }
      }

      _introductorySetable?.ensureSetterTypes(
          libraryBuilder: libraryBuilder,
          declarationBuilder: declarationBuilder,
          membersBuilder: classMembersBuilder,
          setterOverrideDependencies: setterOverrideDependencies);
      List<SetterDeclaration>? setterAugmentations = _setterAugmentations;
      if (setterAugmentations != null) {
        for (SetterDeclaration augmentation in setterAugmentations) {
          // Coverage-ignore-block(suite): Not run.
          augmentation.ensureSetterTypes(
              libraryBuilder: libraryBuilder,
              declarationBuilder: declarationBuilder,
              membersBuilder: classMembersBuilder,
              setterOverrideDependencies: setterOverrideDependencies);
        }
      }

      _getterOverrideDependencies = null;
      _setterOverrideDependencies = null;
      _classMembersBuilder = null;
    }
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
        setterType = Substitution.fromPairs(setterExtensionTypeParameters, [
          for (TypeParameter parameter in getterExtensionTypeParameters)
            new TypeParameterType.withDefaultNullability(parameter)
        ]).substituteType(setterType);
      }
    } else {
      setterType = procedure.setterType;
    }
    return setterType;
  }

  DartType get fieldType {
    return _introductoryField!.fieldType;
  }

  /// Creates the [Initializer] for the invalid initialization of this field.
  ///
  /// This is only used for instance fields.
  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset}) {
    return _introductoryField!
        .buildErroneousInitializer(effect, value, fileOffset: fileOffset);
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
  List<Initializer> buildInitializer(int fileOffset, Expression value,
      {required bool isSynthetic}) {
    return _introductoryField!
        .buildInitializer(fileOffset, value, isSynthetic: isSynthetic);
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
}

class GetterClassMember implements ClassMember {
  final SourcePropertyBuilder _builder;

  GetterClassMember(this._builder);

  @override
  int get charOffset => _builder.fileOffset;

  @override
  DeclarationBuilder get declarationBuilder => _builder.declarationBuilder!;

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get declarations =>
      throw new UnsupportedError('$runtimeType.declarations');

  @override
  Uri get fileUri => _builder.fileUri;

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
      ClassMembersBuilder membersBuilder, Set<ClassMember> overriddenMembers) {
    _builder.registerGetterOverrideDependency(
        membersBuilder, overriddenMembers);
  }

  @override
  String toString() => '$runtimeType($fullName,forSetter=${forSetter})';
}

class SetterClassMember implements ClassMember {
  final SourcePropertyBuilder _builder;
  late final Covariance _covariance =
      new Covariance.fromSetter(_builder.writeTarget as Procedure);

  SetterClassMember(this._builder);

  @override
  int get charOffset => _builder.fileOffset;

  @override
  DeclarationBuilder get declarationBuilder => _builder.declarationBuilder!;

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get declarations =>
      throw new UnsupportedError('$runtimeType.declarations');

  @override
  Uri get fileUri => _builder.fileUri;

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
      ClassMembersBuilder membersBuilder, Set<ClassMember> overriddenMembers) {
    _builder.registerSetterOverrideDependency(
        membersBuilder, overriddenMembers);
  }

  @override
  String toString() => '$runtimeType($fullName,forSetter=${forSetter})';
}

abstract class PropertyReferences {
  Reference? get getterReference;
  Reference? get setterReference;
}

class GetterReference extends PropertyReferences {
  Reference? _getterReference;

  GetterReference._(this._getterReference);

  factory GetterReference(
      String name, NameScheme nameScheme, IndexedContainer? indexedContainer) {
    Reference? procedureReference;
    ProcedureKind kind = ProcedureKind.Getter;
    if (indexedContainer != null) {
      Name nameToLookup = nameScheme.getProcedureMemberName(kind, name).name;
      procedureReference = indexedContainer.lookupGetterReference(nameToLookup);
    }
    return new GetterReference._(procedureReference);
  }

  void registerReference(SourceLoader loader, Builder builder) {
    if (_getterReference != null) {
      loader.buildersCreatedWithReferences[_getterReference!] = builder;
    }
  }

  @override
  Reference get getterReference => _getterReference ??= new Reference();

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get setterReference => null;
}

class SetterReference extends PropertyReferences {
  Reference? _setterReference;

  SetterReference._(this._setterReference);

  factory SetterReference(
      String name, NameScheme nameScheme, IndexedContainer? indexedContainer) {
    Reference? procedureReference;
    ProcedureKind kind = ProcedureKind.Setter;
    if (indexedContainer != null) {
      Name nameToLookup = nameScheme.getProcedureMemberName(kind, name).name;
      if ((nameScheme.isExtensionMember || nameScheme.isExtensionTypeMember) &&
          nameScheme.isInstanceMember) {
        // Extension (type) instance setters are encoded as methods.
        procedureReference =
            indexedContainer.lookupGetterReference(nameToLookup);
      } else {
        procedureReference =
            indexedContainer.lookupSetterReference(nameToLookup);
      }
    }
    return new SetterReference._(procedureReference);
  }

  void registerReference(SourceLoader loader, Builder builder) {
    if (_setterReference != null) {
      loader.buildersCreatedWithReferences[_setterReference!] = builder;
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get getterReference => null;

  @override
  Reference get setterReference => _setterReference ??= new Reference();
}

abstract class FieldReference extends PropertyReferences {
  factory FieldReference(
      String name, NameScheme nameScheme, IndexedContainer? indexedContainer,
      {required bool fieldIsLateWithLowering, required bool isExternal}) {
    Reference? fieldReference;
    Reference? fieldGetterReference;
    Reference? fieldSetterReference;
    Reference? lateIsSetFieldReference;
    Reference? lateIsSetGetterReference;
    Reference? lateIsSetSetterReference;
    Reference? lateGetterReference;
    Reference? lateSetterReference;
    if (indexedContainer != null) {
      if ((nameScheme.isExtensionMember || nameScheme.isExtensionTypeMember) &&
          nameScheme.isInstanceMember &&
          isExternal) {
        /// An external extension (type) instance field is special. It is
        /// treated as an external getter/setter pair and is therefore
        /// encoded as a pair of top level methods using the extension
        /// instance member naming convention.
        fieldGetterReference = indexedContainer.lookupGetterReference(
            nameScheme.getProcedureMemberName(ProcedureKind.Getter, name).name);
        fieldSetterReference = indexedContainer.lookupGetterReference(
            nameScheme.getProcedureMemberName(ProcedureKind.Setter, name).name);
      } else if (nameScheme.isExtensionTypeMember &&
          nameScheme.isInstanceMember) {
        Name nameToLookup = nameScheme
            .getFieldMemberName(FieldNameType.RepresentationField, name,
                isSynthesized: true)
            .name;
        fieldGetterReference =
            indexedContainer.lookupGetterReference(nameToLookup);
      } else {
        Name nameToLookup = nameScheme
            .getFieldMemberName(FieldNameType.Field, name,
                isSynthesized: fieldIsLateWithLowering)
            .name;
        fieldReference = indexedContainer.lookupFieldReference(nameToLookup);
        fieldGetterReference =
            indexedContainer.lookupGetterReference(nameToLookup);
        fieldSetterReference =
            indexedContainer.lookupSetterReference(nameToLookup);
      }

      if (fieldIsLateWithLowering) {
        Name lateIsSetName = nameScheme
            .getFieldMemberName(FieldNameType.IsSetField, name,
                isSynthesized: fieldIsLateWithLowering)
            .name;
        lateIsSetFieldReference =
            indexedContainer.lookupFieldReference(lateIsSetName);
        lateIsSetGetterReference =
            indexedContainer.lookupGetterReference(lateIsSetName);
        lateIsSetSetterReference =
            indexedContainer.lookupSetterReference(lateIsSetName);
        lateGetterReference = indexedContainer.lookupGetterReference(nameScheme
            .getFieldMemberName(FieldNameType.Getter, name,
                isSynthesized: fieldIsLateWithLowering)
            .name);
        lateSetterReference = indexedContainer.lookupSetterReference(nameScheme
            .getFieldMemberName(FieldNameType.Setter, name,
                isSynthesized: fieldIsLateWithLowering)
            .name);
      }
    }
    if (fieldIsLateWithLowering) {
      return new _LateFieldLoweringReference._(
          fieldReference: fieldReference,
          fieldGetterReference: fieldGetterReference,
          fieldSetterReference: fieldSetterReference,
          lateIsSetFieldReference: lateIsSetFieldReference,
          lateIsSetGetterReference: lateIsSetGetterReference,
          lateIsSetSetterReference: lateIsSetSetterReference,
          lateGetterReference: lateGetterReference,
          lateSetterReference: lateSetterReference);
    } else {
      return new _RegularFieldReference._(
          fieldReference: fieldReference,
          fieldGetterReference: fieldGetterReference,
          fieldSetterReference: fieldSetterReference,
          lateIsSetFieldReference: lateIsSetFieldReference,
          lateIsSetGetterReference: lateIsSetGetterReference,
          lateIsSetSetterReference: lateIsSetSetterReference,
          lateGetterReference: lateGetterReference,
          lateSetterReference: lateSetterReference);
    }
  }

  void registerReference(SourceLoader loader, Builder builder);

  Reference get fieldReference;
  Reference get fieldGetterReference;
  Reference get fieldSetterReference;
  Reference get lateIsSetFieldReference;
  Reference get lateIsSetGetterReference;
  Reference get lateIsSetSetterReference;
  Reference get lateGetterReference;
  Reference get lateSetterReference;
}

class _RegularFieldReference implements FieldReference {
  Reference? _fieldReference;
  Reference? _fieldGetterReference;
  Reference? _fieldSetterReference;
  Reference? _lateIsSetFieldReference;
  Reference? _lateIsSetGetterReference;
  Reference? _lateIsSetSetterReference;
  Reference? _lateGetterReference;
  Reference? _lateSetterReference;

  _RegularFieldReference._(
      {required Reference? fieldReference,
      required Reference? fieldGetterReference,
      required Reference? fieldSetterReference,
      required Reference? lateIsSetFieldReference,
      required Reference? lateIsSetGetterReference,
      required Reference? lateIsSetSetterReference,
      required Reference? lateGetterReference,
      required Reference? lateSetterReference})
      : _fieldReference = fieldReference,
        _fieldGetterReference = fieldGetterReference,
        _fieldSetterReference = fieldSetterReference,
        _lateIsSetFieldReference = lateIsSetFieldReference,
        _lateIsSetGetterReference = lateIsSetGetterReference,
        _lateIsSetSetterReference = lateIsSetSetterReference,
        _lateGetterReference = lateGetterReference,
        _lateSetterReference = lateSetterReference;

  @override
  void registerReference(SourceLoader loader, Builder builder) {
    if (_fieldGetterReference != null) {
      loader.buildersCreatedWithReferences[_fieldGetterReference!] = builder;
    }
    if (_fieldSetterReference != null) {
      loader.buildersCreatedWithReferences[_fieldSetterReference!] = builder;
    }
  }

  @override
  Reference get fieldReference => _fieldReference ??= new Reference();

  @override
  Reference get fieldGetterReference =>
      _fieldGetterReference ??= new Reference();

  @override
  Reference get fieldSetterReference =>
      _fieldSetterReference ??= new Reference();

  @override
  Reference get lateIsSetFieldReference =>
      _lateIsSetFieldReference ??= new Reference();

  @override
  Reference get lateIsSetGetterReference =>
      _lateIsSetGetterReference ??= new Reference();

  @override
  Reference get lateIsSetSetterReference =>
      _lateIsSetSetterReference ??= new Reference();

  @override
  Reference get lateGetterReference => _lateGetterReference ??= new Reference();

  @override
  Reference get lateSetterReference => _lateSetterReference ??= new Reference();

  @override
  Reference? get getterReference => fieldGetterReference;

  @override
  Reference? get setterReference => fieldSetterReference;
}

class _LateFieldLoweringReference implements FieldReference {
  Reference? _fieldReference;
  Reference? _fieldGetterReference;
  Reference? _fieldSetterReference;
  Reference? _lateIsSetFieldReference;
  Reference? _lateIsSetGetterReference;
  Reference? _lateIsSetSetterReference;
  Reference? _lateGetterReference;
  Reference? _lateSetterReference;

  _LateFieldLoweringReference._(
      {required Reference? fieldReference,
      required Reference? fieldGetterReference,
      required Reference? fieldSetterReference,
      required Reference? lateIsSetFieldReference,
      required Reference? lateIsSetGetterReference,
      required Reference? lateIsSetSetterReference,
      required Reference? lateGetterReference,
      required Reference? lateSetterReference})
      : _fieldReference = fieldReference,
        _fieldGetterReference = fieldGetterReference,
        _fieldSetterReference = fieldSetterReference,
        _lateIsSetFieldReference = lateIsSetFieldReference,
        _lateIsSetGetterReference = lateIsSetGetterReference,
        _lateIsSetSetterReference = lateIsSetSetterReference,
        _lateGetterReference = lateGetterReference,
        _lateSetterReference = lateSetterReference;

  @override
  void registerReference(SourceLoader loader, Builder builder) {
    if (_fieldGetterReference != null) {
      loader.buildersCreatedWithReferences[_fieldGetterReference!] = builder;
    }
    if (_fieldSetterReference != null) {
      loader.buildersCreatedWithReferences[_fieldSetterReference!] = builder;
    }
  }

  @override
  Reference get fieldReference => _fieldReference ??= new Reference();

  @override
  Reference get fieldGetterReference =>
      _fieldGetterReference ??= new Reference();

  @override
  Reference get fieldSetterReference =>
      _fieldSetterReference ??= new Reference();

  @override
  Reference get lateIsSetFieldReference =>
      _lateIsSetFieldReference ??= new Reference();

  @override
  Reference get lateIsSetGetterReference =>
      _lateIsSetGetterReference ??= new Reference();

  @override
  Reference get lateIsSetSetterReference =>
      _lateIsSetSetterReference ??= new Reference();

  @override
  Reference get lateGetterReference => _lateGetterReference ??= new Reference();

  @override
  Reference get lateSetterReference => _lateSetterReference ??= new Reference();

  @override
  Reference? get getterReference => lateGetterReference;

  @override
  Reference? get setterReference => lateSetterReference;
}
