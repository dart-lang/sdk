// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/type_environment.dart';

import '../api_prototype/experimental_flags.dart';
import '../base/messages.dart';
import '../base/modifiers.dart';
import '../base/name_space.dart';
import '../base/uri_offset.dart';
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/method_builder.dart';
import '../fragment/method/declaration.dart';
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

  /// The declarations of this method. The first is the introductory declaration
  /// and subsequent declarations are augmentations.
  final List<MethodDeclaration> _declarations;

  /// The declaration used as the implementation of this method.
  ///
  /// This is the last non-abstract declaration, if any. Otherwise it is the
  /// first declaration.
  final MethodDeclaration _implementation;

  final Modifiers _modifiers;

  final MethodReferences _references;

  final MemberName _memberName;

  late final Procedure _invokeTarget;
  late final Procedure? _readTarget;

  new({
    required this.fileUri,
    required this.fileOffset,
    required this.name,
    required this.libraryBuilder,
    required this.declarationBuilder,
    required this.isStatic,
    required Modifiers modifiers,
    required NameScheme nameScheme,
    required this._declarations,
    required this._implementation,
    required this._references,
  }) : _nameScheme = nameScheme,
       _modifiers = modifiers,
       isOperator = _declarations.first.isOperator,
       _memberName = nameScheme.getDeclaredName(name);

  @override
  Builder get parent => declarationBuilder ?? libraryBuilder;

  @override
  bool get isAbstract => _modifiers.isAbstract;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isFinal => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSynthesized => false;

  @override
  MemberBuilder get getable => this;

  @override
  MemberBuilder? get setable => null;

  @override
  int buildBodyNodes(BuildNodesCallback f) {
    // TODO(johnniwinther): Generate the needed augmented methods.
    return 0;
  }

  @override
  void buildOutlineNodes(BuildNodesCallback callback) {
    for (MethodDeclaration declaration in _declarations) {
      bool isImplementation = declaration == _implementation;
      declaration.buildOutlineNode(
        libraryBuilder: libraryBuilder,
        problemReporting: libraryBuilder,
        nameScheme: _nameScheme,
        callback: isImplementation ? callback : noAddBuildNodesCallback,
        references: isImplementation ? _references : null,
        classTypeParameters: classBuilder?.cls.typeParameters,
      );
    }
    _invokeTarget = _implementation.invokeTarget;
    _readTarget = _implementation.readTarget;
  }

  bool hasBuiltOutlineExpressions = false;

  @override
  void buildOutlineExpressions(
    ClassHierarchy classHierarchy,
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  ) {
    if (!hasBuiltOutlineExpressions) {
      for (int i = 0; i < _declarations.length; i++) {
        _declarations[i].buildOutlineExpressions(
          classHierarchy: classHierarchy,
          libraryBuilder: libraryBuilder,
          declarationBuilder: declarationBuilder,
          methodBuilder: this,
          annotatable: _invokeTarget,
          annotatableFileUri: _invokeTarget.fileUri,
        );
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
    // TODO(johnniwinther): Updated checks for default values to handle
    // default values declared on the introductory method and omitted on the
    // augmenting method.
    for (int i = 0; i < _declarations.length; i++) {
      _declarations[i].checkTypes(problemReporting, typeEnvironment);
    }
  }

  @override
  void checkVariance(
    SourceClassBuilder sourceClassBuilder,
    TypeEnvironment typeEnvironment,
  ) {
    if (!isClassInstanceMember) return;
    for (int i = 0; i < _declarations.length; i++) {
      _declarations[i].checkVariance(sourceClassBuilder, typeEnvironment);
    }
  }

  @override
  Iterable<Reference> get exportedMemberReferences => [
    _references.methodReference,
  ];

  List<ClassMember>? _localMembers;

  UriOffsetLength get uriOffset => _declarations.first.uriOffset;

  @override
  List<ClassMember> get localMembers =>
      _localMembers ??= [new _MethodClassMember(this, uriOffset)];

  @override
  List<ClassMember> get localSetters => const [];

  @override
  Name get memberName => _memberName.name;

  @override
  Member? get readTarget => _readTarget;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get readTargetReference => _references.tearOffReference;

  @override
  Member get invokeTarget => _invokeTarget;

  @override
  Reference get invokeTargetReference => _references.methodReference;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => null;

  @override
  int computeDefaultTypes(
    ComputeDefaultTypeContext context, {
    required bool inErrorRecovery,
  }) {
    int count = 0;
    for (int i = 0; i < _declarations.length; i++) {
      count += _declarations[i].computeDefaultTypes(context);
    }
    return count;
  }

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<MetadataBuilder>? get metadataForTesting =>
      _declarations.first.metadata;

  @override
  bool get isProperty => false;

  bool _typeEnsured = false;
  ClassMembersBuilder? _classMembersBuilder;
  Set<ClassMember>? _overrideDependencies;

  void _registerOverrideDependency(
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
    _overrideDependencies ??= {};
    _overrideDependencies!.addAll(overriddenMembers);
  }

  void _ensureTypes() {
    if (_typeEnsured) return;
    if (_classMembersBuilder != null) {
      assert(_overrideDependencies != null);
      _declarations.first.ensureTypes(
        _classMembersBuilder!,
        declarationBuilder as SourceClassBuilder,
        _overrideDependencies,
      );
      _overrideDependencies = null;
      _classMembersBuilder = null;
    }
    _typeEnsured = true;
  }
}

class _MethodClassMember implements ClassMember {
  final SourceMethodBuilder _builder;
  late final Covariance _covariance = new Covariance.fromMethod(
    _builder.invokeTarget as Procedure,
  );

  @override
  final UriOffsetLength uriOffset;

  new(this._builder, this.uriOffset);

  @override
  DeclarationBuilder get declarationBuilder => _builder.declarationBuilder!;

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get declarations =>
      throw new UnsupportedError('$runtimeType.declarations');

  @override
  bool get forSetter => false;

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
    return _builder.invokeTarget;
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
  bool get isAbstract => _builder.isAbstract;

  @override
  bool get isDuplicate => _builder.isDuplicate;

  @override
  bool get isExtensionTypeMember => _builder.isExtensionTypeMember;

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
  bool get isStatic => _builder.isStatic;

  @override
  bool get isSynthesized => false;

  @override
  ClassMemberKind get memberKind => ClassMemberKind.Method;

  @override
  Name get name => _builder.memberName;

  @override
  void registerOverrideDependency(
    ClassMembersBuilder membersBuilder,
    Set<ClassMember> overriddenMembers,
  ) {
    _builder._registerOverrideDependency(membersBuilder, overriddenMembers);
  }

  @override
  String toString() => '$runtimeType($fullName,forSetter=${forSetter})';
}

/// [Reference]s used for the [Member] nodes created for a method.
class MethodReferences {
  Reference? _methodReference;
  Reference? _tearOffReference;

  /// Whether there is an explicit tear off reference for this method.
  ///
  /// This is only needed for extension (type) methods whose lowering produce
  /// a separate tear-off member.
  final bool _hasTearOffReference;

  /// Creates a [MethodReferences] object preloaded with the
  /// [preExistingMethodReference] and [preExistingTearOffReference].
  ///
  /// For initial/one-off compilations these are `null`, but for subsequent
  /// compilations during an incremental compilation, these are the references
  /// used for the same method and tear-off in the previous compilation.
  new _({
    required Reference? preExistingMethodReference,
    required Reference? preExistingTearOffReference,
    required this._hasTearOffReference,
  }) : _methodReference = preExistingMethodReference,
       _tearOffReference = preExistingTearOffReference;

  /// Creates a [MethodReferences] object preloaded with the pre-existing
  /// references from [indexedContainer], if available.
  factory(
    String name,
    NameScheme nameScheme,
    IndexedContainer? indexedContainer, {
    required ProcedureKind kind,
  }) {
    bool isExtensionMember =
        nameScheme.containerType == ContainerType.Extension;
    bool isExtensionTypeMember =
        nameScheme.containerType == ContainerType.ExtensionType;
    bool hasTearOffReference =
        kind == ProcedureKind.Method &&
        (isExtensionMember || isExtensionTypeMember);

    Reference? preExistingReference;
    Reference? preExistingTearOffReference;
    if (indexedContainer != null) {
      Name nameToLookup = nameScheme.getProcedureMemberName(kind, name).name;
      preExistingReference = indexedContainer.lookupGetterReference(
        nameToLookup,
      );
      if (hasTearOffReference) {
        preExistingTearOffReference = indexedContainer.lookupGetterReference(
          nameScheme.getProcedureMemberName(ProcedureKind.Getter, name).name,
        );
      }
    }
    return new MethodReferences._(
      preExistingMethodReference: preExistingReference,
      preExistingTearOffReference: preExistingTearOffReference,
      hasTearOffReference: hasTearOffReference,
    );
  }

  /// Registers that [builder] is created for the pre-existing references
  /// provided in [MethodReferences._].
  ///
  /// This must be called before [methodReference] and [tearOffReference] are
  /// accessed.
  void registerReference(
    ReferenceMap referenceMap,
    SourceMethodBuilder builder,
  ) {
    if (_methodReference != null) {
      referenceMap.registerNamedBuilder(_methodReference!, builder);
    }
    if (_tearOffReference != null) {
      referenceMap.registerNamedBuilder(_tearOffReference!, builder);
    }
  }

  /// The [Reference] used to refer the [Procedure] node created for this
  /// method.
  Reference get methodReference => _methodReference ??= new Reference();

  /// The [Reference] used to refer to the [Procedure] node created for the
  /// tear-off of this method.
  ///
  /// If the lowering does not produce an explicit tear-off procedure, this
  /// is the same as [methodReference].
  Reference get tearOffReference => _tearOffReference ??= _hasTearOffReference
      ? new Reference()
      :
        // Coverage-ignore(suite): Not run.
        methodReference;
}
