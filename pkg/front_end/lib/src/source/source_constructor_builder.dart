// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:front_end/src/source/source_loader.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../api_prototype/experimental_flags.dart';
import '../base/messages.dart' show ProblemReporting;
import '../base/name_space.dart';
import '../builder/builder.dart';
import '../builder/constructor_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/function_signature.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../builder/property_builder.dart';
import '../fragment/constructor/declaration.dart';
import '../kernel/hierarchy/class_member.dart' show ClassMember;
import '../kernel/kernel_helper.dart' show DelayedDefaultValueCloner;
import '../kernel/type_algorithms.dart';
import '../type_inference/type_inference_engine.dart';
import '../util/helpers.dart';
import '../util/reference_map.dart';
import 'name_scheme.dart';
import 'source_class_builder.dart';
import 'source_library_builder.dart' show SourceLibraryBuilder;
import 'source_member_builder.dart';
import 'source_property_builder.dart';

class InferableConstructor implements InferableMember {
  @override
  final Member member;

  final SourceConstructorBuilder _builder;

  new(this.member, this._builder);

  @override
  void inferMemberTypes(ClassHierarchyBase classHierarchy) {
    _builder.inferFormalTypes(classHierarchy);
  }

  @override
  void reportCyclicDependency() {
    _builder._reportCyclicDependency();
  }
}

class SourceConstructorBuilder extends SourceMemberBuilderImpl
    implements ConstructorBuilder, SourceMemberBuilder, Inferable {
  @override
  final String name;

  @override
  final SourceLibraryBuilder libraryBuilder;

  @override
  final DeclarationBuilder declarationBuilder;

  @override
  final int fileOffset;

  @override
  final Uri fileUri;

  /// The declarations of this constructor. The first is the introductory
  /// declaration and subsequent declarations are augmentations.
  final List<ConstructorDeclaration> _declarations;

  /// The declaration used as the implementation of this constructor.
  ///
  /// This is the last complete declaration, if any. Otherwise it is
  /// the first declaration.
  final ConstructorDeclaration _implementation;

  final MemberName _memberName;

  final List<DelayedDefaultValueCloner> _delayedDefaultValueCloners = [];

  Map<SourcePropertyBuilder, FieldInitialization>? _initializedFields;

  late final Substitution _fieldTypeSubstitution = _introductory
      .computeFieldTypeSubstitution(declarationBuilder);

  bool _hasBuiltOutlines = false;

  bool hasBuiltOutlineExpressions = false;

  bool _hasFormalsInferred = false;

  @override
  final bool isConst;

  final ConstructorReferences _constructorReferences;
  final NameScheme _nameScheme;

  final bool isPrimaryConstructor;

  new({
    required this.name,
    required this.libraryBuilder,
    required this.declarationBuilder,
    required this.fileOffset,
    required this.fileUri,
    required this._constructorReferences,
    required this._nameScheme,
    required this._declarations,
    required this._implementation,
    required this.isConst,
  }) : _memberName = _nameScheme.getDeclaredName(name),
       isPrimaryConstructor = _declarations.first.isPrimaryConstructor,
       assert(
         _declarations.contains(_implementation),
         "Constructor implementation $_implementation not found in "
         "declarations $_declarations",
       );

  ConstructorDeclaration get _introductory => _declarations.first;

  /// Returns `true` if field initializers should be moved to the initializer
  /// list of this constructor.
  ///
  /// This is done for primary constructors because non-late field initializers
  /// have access to the parameters of the primary constructor.
  ///
  /// An exception to this is for mixin classes. In the non-erroneous cases,
  /// these can't have parameters, so the field initializers can stay in the
  /// field declaration. This is done to ensure that mixin transformation can
  /// simply clone the mixin class fields, instead of having to fetch the
  /// initializer from the initializer list of the constructor. For mixin
  /// classes with parameters in the primary constructor, which is an erroneous
  /// case, the initializers are moved to the constructor like for other
  /// primary constructors to avoid generating an AST where the parameters are
  /// accessed out of scope.
  bool get shouldTakeFieldInitializers {
    if (isPrimaryConstructor) {
      if (declarationBuilder.isMixinClass && !_introductory.hasParameters) {
        return false;
      }
      return true;
    }
    return false;
  }

  /// If this constructor is a primary constructor, returns the parameters
  /// available in the initializer scope. Otherwise return `null`.
  List<FormalParameterBuilder>?
  get primaryConstructorInitializerScopeParameters {
    if (isPrimaryConstructor) {
      return _implementation.primaryConstructorInitializerScopeParameters;
    }
    return null;
  }

  void buildPrimaryConstructorFieldInitializers() {
    List<SourcePropertyBuilder> nonLateClassInstanceFieldsWithInitializers = [];

    Iterator<SourcePropertyBuilder> fieldIterator = declarationBuilder
        .filteredMembersIterator(includeDuplicates: false);
    while (fieldIterator.moveNext()) {
      SourcePropertyBuilder fieldBuilder = fieldIterator.current;
      if (fieldBuilder.hasConcreteField &&
          declarationBuilder is SourceClassBuilder &&
          fieldBuilder.isDeclarationInstanceMember &&
          !fieldBuilder.isLate &&
          fieldBuilder.hasInitializer) {
        nonLateClassInstanceFieldsWithInitializers.add(fieldBuilder);
      }
    }
    // We prepend the initializers in reversed order to preserve normal
    // field initializer evaluation order.
    for (SourcePropertyBuilder field
        in nonLateClassInstanceFieldsWithInitializers.reversed) {
      FieldInitialization? fieldInitialization = _initializedFields?[field];
      if (fieldInitialization == null) {
        prependInitializer(field.takePrimaryConstructorFieldInitializer());
      }
    }
  }

  // TODO(johnniwinther): Add annotations to tear-offs.
  Iterable<Annotatable> get annotatables => [invokeTarget];

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [invokeTargetReference];

  @override
  // Coverage-ignore(suite): Not run.
  String get fullNameForErrors {
    return "${declarationBuilder.name}"
        "${name.isEmpty ? '' : '.$name'}";
  }

  @override
  FunctionSignature get signature => _implementation.signature;

  @override
  MemberBuilder get getable => this;

  bool get hasParameters => _introductory.hasParameters;

  @override
  Member get invokeTarget => invokeTargetReference.asMember;

  @override
  Reference get invokeTargetReference =>
      _constructorReferences.constructorReference;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isClassInstanceMember => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isDeclarationInstanceMember => false;

  /// Returns `true` if this constructor, including its augmentations, is
  /// external.
  ///
  /// An augmented constructor is considered external if all of the origin
  /// and augmentation constructors are external.
  bool get isEffectivelyExternal => _implementation.isExternal;

  /// Returns `true` if this constructor or any of its augmentations are
  /// redirecting.
  ///
  /// An augmented constructor is considered redirecting if any of the origin
  /// or augmentation constructors is redirecting. Since it is an error if more
  /// than one is redirecting, only one can be redirecting in the without
  /// errors.
  bool get isEffectivelyRedirecting => _implementation.isRedirecting;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isFinal => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isProperty => false;

  @override
  bool get isStatic => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSynthesized => false;

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get localMembers =>
      throw new UnsupportedError('${runtimeType}.localMembers');

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get localSetters =>
      throw new UnsupportedError('${runtimeType}.localSetters');

  @override
  // Coverage-ignore(suite): Not run.
  Name get memberName => _memberName.name;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<MetadataBuilder>? get metadataForTesting => _introductory.metadata;

  @override
  Builder get parent => declarationBuilder;

  @override
  Member get readTarget => readTargetReference.asMember;

  @override
  Reference get readTargetReference => _constructorReferences.tearOffReference;

  @override
  MemberBuilder? get setable => null;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => null;

  void registerInitializers(
    List<Initializer> initializers, {
    required bool isErroneous,
  }) {
    if (isErroneous) {
      markAsErroneous();
    }
    _implementation.registerInitializers(initializers);
  }

  void addSuperParameterDefaultValueCloners(
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  ) {
    for (int i = 0; i < _declarations.length; i++) {
      _declarations[i].addSuperParameterDefaultValueCloners(
        libraryBuilder,
        declarationBuilder,
        delayedDefaultValueCloners,
      );
    }
  }

  @override
  int buildBodyNodes(BuildNodesCallback f) {
    for (int i = 0; i < _declarations.length; i++) {
      _declarations[i].buildBody();
    }
    return _declarations.length - 1;
  }

  @override
  void buildOutlineExpressions(
    ClassHierarchy classHierarchy,
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  ) {
    if (_hasBuiltOutlines) return;

    if (!hasBuiltOutlineExpressions) {
      for (int i = 0; i < _declarations.length; i++) {
        _declarations[i].buildOutlineExpressions(
          annotatables: annotatables,
          annotatablesFileUri: invokeTarget.fileUri,
          libraryBuilder: libraryBuilder,
          declarationBuilder: declarationBuilder,
          constructorBuilder: this,
          classHierarchy: classHierarchy,
          delayedDefaultValueCloners: delayedDefaultValueCloners,
        );
      }
      hasBuiltOutlineExpressions = true;
    }

    delayedDefaultValueCloners.addAll(_delayedDefaultValueCloners);
    _delayedDefaultValueCloners.clear();
    _hasBuiltOutlines = true;
  }

  @override
  void buildOutlineNodes(BuildNodesCallback callback) {
    for (int i = 0; i < _declarations.length; i++) {
      ConstructorDeclaration declaration = _declarations[i];
      bool isImplementation = declaration == _implementation;
      declaration.buildOutlineNodes(
        callback: isImplementation ? callback : noAddBuildNodesCallback,
        constructorBuilder: this,
        libraryBuilder: libraryBuilder,
        nameScheme: _nameScheme,
        constructorReferences: isImplementation ? _constructorReferences : null,
        delayedDefaultValueCloners: _delayedDefaultValueCloners,
      );
    }
  }

  @override
  void checkTypes(
    ProblemReporting problemReporting,
    LibraryFeatures libraryFeatures,
    NameSpace nameSpace,
    TypeEnvironment typeEnvironment,
  ) {
    _implementation.checkTypes(problemReporting, nameSpace, typeEnvironment);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void checkVariance(
    SourceClassBuilder sourceClassBuilder,
    TypeEnvironment typeEnvironment,
  ) {}

  @override
  int computeDefaultTypes(
    ComputeDefaultTypeContext context, {
    required bool inErrorRecovery,
  }) {
    int count = 0;
    for (int i = 0; i < _declarations.length; i++) {
      count += _declarations[i].computeDefaultTypes(
        context,
        inErrorRecovery: inErrorRecovery,
      );
    }
    return count;
  }

  /// Infers the types of any untyped initializing formals.
  void inferFormalTypes(ClassHierarchyBase hierarchy) {
    if (_hasFormalsInferred) return;
    for (int i = 0; i < _declarations.length; i++) {
      _declarations[i].inferFormalTypes(
        libraryBuilder,
        declarationBuilder,
        this,
        hierarchy,
        _delayedDefaultValueCloners,
      );
    }
    _hasFormalsInferred = true;
  }

  @override
  void inferTypes(ClassHierarchyBase hierarchy) {
    inferFormalTypes(hierarchy);
  }

  void prepareInitializers() {
    for (int i = 0; i < _declarations.length; i++) {
      _declarations[i].prepareInitializers();
    }
  }

  void prependInitializer(Initializer initializer) {
    _implementation.prependInitializer(initializer);
  }

  /// Registers field as being initialized by this constructor.
  ///
  /// The [fieldInitialization] contains information about whether the field
  /// was initialized via an initializing formal or via an entry in the
  /// constructor initializer list.
  void registerInitializedField(
    SourcePropertyBuilder fieldBuilder,
    FieldInitialization fieldInitialization,
  ) {
    (_initializedFields ??= {})[fieldBuilder] = fieldInitialization;
  }

  /// Substitute [fieldType] from the context of the enclosing class or
  /// extension type declaration to this constructor.
  ///
  /// This is used for generic extension type constructors where the type
  /// variable referring to the class type parameters must be substituted for
  /// the synthesized constructor type parameters.
  DartType substituteFieldType(DartType fieldType) {
    return _fieldTypeSubstitution.substituteType(fieldType);
  }

  /// Returns the fields registered as initialized by this constructor.
  ///
  /// Returns the set of fields previously registered via
  /// [registerInitializedField] and passes on the ownership of the collection
  /// to the caller.
  Map<SourcePropertyBuilder, FieldInitialization>? takeInitializedFields() {
    Map<SourcePropertyBuilder, FieldInitialization>? result =
        _initializedFields;
    _initializedFields = null;
    return result;
  }

  /// Mark the constructor as erroneous.
  ///
  /// This is used during the compilation phase to set the appropriate flag on
  /// the input AST node. The flag helps the verifier to skip apriori erroneous
  /// members and to avoid reporting cascading errors.
  void markAsErroneous() {
    for (int i = 0; i < _declarations.length; i++) {
      _declarations[i].markAsErroneous();
    }
  }

  void _reportCyclicDependency() {
    // There is a cyclic dependency where inferring the types of the
    // initializing formals of a constructor required us to infer the
    // corresponding field type which required us to know the type of the
    // constructor.
    String constructorName = declarationBuilder.name;
    if (name.isNotEmpty) {
      constructorName += ".${name}";
    }
    libraryBuilder.addProblem(
      diag.cantInferTypeDueToCircularity.withArguments(name: name),
      fileOffset,
      constructorName.length,
      fileUri,
    );
    markAsErroneous();
  }
}

/// [Reference]s used for the [Member] nodes created for a generative
/// constructor.
class ConstructorReferences {
  Reference? _constructorReference;
  Reference? _tearOffReference;

  /// If `true`, the generative constructor has a tear-off lowering and should
  /// therefore have distinct [constructorReference] and [tearOffReference]
  /// values.
  final bool _hasTearOffLowering;

  /// Creates a [ConstructorReferences] object preloaded with the
  /// [preExistingConstructorReference] and [preExistingTearOffReference].
  ///
  /// For initial/one-off compilations these are `null`, but for subsequent
  /// compilations during an incremental compilation, these are the references
  /// used for the same generative constructor and tear-off in the previous
  /// compilation.
  new _({
    required Reference? preExistingConstructorReference,
    required Reference? preExistingTearOffReference,
    required bool hasTearOffLowering,
  }) : _constructorReference = preExistingConstructorReference,
       _tearOffReference = preExistingTearOffReference,
       _hasTearOffLowering = hasTearOffLowering,
       assert(
         !(preExistingTearOffReference != null && !hasTearOffLowering),
         "Unexpected tear off reference $preExistingTearOffReference.",
       );

  /// Creates a [ConstructorReferences] object preloaded with the pre-existing
  /// references from [indexedContainer], if available.
  factory({
    required String name,
    required NameScheme nameScheme,
    required IndexedContainer? indexedContainer,
    required SourceLoader loader,
    required DeclarationBuilder declarationBuilder,
  }) {
    bool hasTearOffLowering = switch (declarationBuilder) {
      ClassBuilder() =>
        !(declarationBuilder.isAbstract || declarationBuilder.isEnum) &&
            loader.target.backendTarget.isConstructorTearOffLoweringEnabled,
      ExtensionBuilder() => true,
      ExtensionTypeDeclarationBuilder() => true,
    };

    Reference? preExistingConstructorReference;
    Reference? preExistingTearOffReference;

    if (indexedContainer != null) {
      preExistingConstructorReference = indexedContainer
          .lookupConstructorReference(
            nameScheme.getConstructorMemberName(name, isTearOff: false).name,
          );
      preExistingTearOffReference = indexedContainer.lookupGetterReference(
        nameScheme.getConstructorMemberName(name, isTearOff: true).name,
      );
    }

    return new ConstructorReferences._(
      preExistingConstructorReference: preExistingConstructorReference,
      preExistingTearOffReference: preExistingTearOffReference,
      hasTearOffLowering: hasTearOffLowering,
    );
  }

  /// Registers that [builder] is created for the pre-existing references
  /// provided in [ConstructorReferences._].
  ///
  /// This must be called before [constructorReference] and [tearOffReference]
  /// are accessed.
  void registerReference(
    ReferenceMap referenceMap,
    SourceConstructorBuilder builder,
  ) {
    if (_constructorReference != null) {
      referenceMap.registerNamedBuilder(_constructorReference!, builder);
    }
    if (_tearOffReference != null) {
      referenceMap.registerNamedBuilder(_tearOffReference!, builder);
    }
  }

  /// The [Reference] used to refer to the [Member] node created for the
  /// generative constructor.
  Reference get constructorReference =>
      _constructorReference ??= new Reference();

  /// The [Reference] used to refer to the [Member] node created for the
  /// tear-off of the generative constructor.
  ///
  /// If a tear-off lowering is created for the generative constructor, this is
  /// distinct from [constructorReference], otherwise it is the same [Reference]
  /// as [constructorReference].
  Reference get tearOffReference => _tearOffReference ??= _hasTearOffLowering
      ? new Reference()
      : constructorReference;
}
