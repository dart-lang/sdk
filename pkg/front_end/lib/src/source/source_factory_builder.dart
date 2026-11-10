// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:front_end/src/source/source_loader.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/type_environment.dart';

import '../api_prototype/experimental_flags.dart';
import '../base/messages.dart';
import '../base/name_space.dart';
import '../builder/builder.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/factory_builder.dart';
import '../builder/function_signature.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../fragment/factory/declaration.dart';
import '../kernel/hierarchy/class_member.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/type_algorithms.dart';
import '../type_inference/type_inference_engine.dart';
import '../util/reference_map.dart';
import 'name_scheme.dart';
import 'source_class_builder.dart';
import 'source_library_builder.dart' show SourceLibraryBuilder;
import 'source_member_builder.dart';

class SourceFactoryBuilder extends SourceMemberBuilderImpl
    implements FactoryBuilder {
  @override
  final String name;

  @override
  final SourceLibraryBuilder libraryBuilder;

  @override
  final DeclarationBuilder declarationBuilder;

  @override
  final bool isExtensionInstanceMember = false;

  final MemberName _memberName;

  @override
  final Uri fileUri;

  @override
  final int fileOffset;

  final NameScheme _nameScheme;

  final FactoryReferences _factoryReferences;

  /// The declarations of this factory constructor. The first is the
  /// introductory declaration and subsequent declarations are augmentations.
  final List<FactoryDeclaration> _declarations;

  /// The declaration used as the implementation of this factory constructor.
  ///
  /// This is the last complete declaration, if any. Otherwise it is
  /// the first declaration.
  final FactoryDeclaration _implementation;

  @override
  final bool isConst;

  new({
    required this.name,
    required this.libraryBuilder,
    required this.declarationBuilder,
    required this.fileUri,
    required this.fileOffset,
    required this._factoryReferences,
    required this._nameScheme,
    required this._declarations,
    required this._implementation,
    required this.isConst,
  }) : _memberName = _nameScheme.getDeclaredName(name);

  // Coverage-ignore(suite): Not run.
  FactoryDeclaration get _introductory => _declarations.first;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<MetadataBuilder>? get metadataForTesting => _introductory.metadata;

  ConstructorReferenceBuilder? get redirectionTarget =>
      _implementation.redirectionTarget;

  @override
  bool get isStatic => true;

  @override
  MemberBuilder get getable => this;

  @override
  MemberBuilder? get setable => null;

  @override
  Builder get parent => declarationBuilder;

  @override
  // Coverage-ignore(suite): Not run.
  Name get memberName => _memberName.name;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isProperty => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isFinal => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSynthesized => false;

  Procedure get _procedure => _implementation.procedure;

  @override
  FunctionSignature get signature => _implementation.signature;

  @override
  Member get readTarget => readTargetReference.asMember;

  @override
  Reference get readTargetReference => _factoryReferences.tearOffReference;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => null;

  @override
  Member get invokeTarget => invokeTargetReference.asMember;

  @override
  Reference get invokeTargetReference => _factoryReferences.factoryReference;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [_procedure.reference];

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get localMembers =>
      throw new UnsupportedError('${runtimeType}.localMembers');

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get localSetters =>
      throw new UnsupportedError('${runtimeType}.localSetters');

  @override
  int buildBodyNodes(BuildNodesCallback f) {
    return 0;
  }

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

  @override
  // Coverage-ignore(suite): Not run.
  void checkVariance(
    SourceClassBuilder sourceClassBuilder,
    TypeEnvironment typeEnvironment,
  ) {}

  @override
  void checkTypes(
    ProblemReporting problemReporting,
    LibraryFeatures libraryFeatures,
    NameSpace nameSpace,
    TypeEnvironment typeEnvironment,
  ) {
    for (int i = 0; i < _declarations.length; i++) {
      _declarations[i].checkTypes(problemReporting, nameSpace, typeEnvironment);
    }
  }

  bool _hasBeenCheckedAsRedirectingFactory = false;

  /// Checks the redirecting factories of this factory builder and its
  /// augmentations.
  ///
  /// If this is an erroneous redirecting factory, return the corresponding
  /// error message. Returns `null` otherwise.
  String? checkRedirectingFactories(TypeEnvironment typeEnvironment) {
    if (!_hasBeenCheckedAsRedirectingFactory) {
      _hasBeenCheckedAsRedirectingFactory = true;

      for (int i = 0; i < _declarations.length; i++) {
        FactoryDeclaration declaration = _declarations[i];
        if (declaration.redirectionTarget != null) {
          declaration.checkRedirectingFactory(
            libraryBuilder: libraryBuilder,
            factoryBuilder: this,
            typeEnvironment: typeEnvironment,
          );
        }
      }
    }
    return _implementation.redirectingFactoryTargetErrorMessage;
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get fullNameForErrors {
    return "${declarationBuilder.name}"
        "${name.isEmpty ? '' : '.$name'}";
  }

  // TODO(johnniwinther): Add annotations to tear-offs.
  Iterable<Annotatable> get annotatables => [_procedure];

  @override
  void buildOutlineNodes(BuildNodesCallback callback) {
    for (int i = 0; i < _declarations.length; i++) {
      FactoryDeclaration declaration = _declarations[i];
      bool isImplementation = declaration == _implementation;
      declaration.buildOutlineNodes(
        libraryBuilder: libraryBuilder,
        factoryBuilder: this,
        nameScheme: _nameScheme,
        factoryReferences: isImplementation ? _factoryReferences : null,
        isConst: isConst,
        callback: isImplementation ? callback : noAddBuildNodesCallback,
      );
    }
  }

  bool _hasInferredRedirectionTarget = false;

  void inferRedirectionTarget(
    ClassHierarchy classHierarchy,
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  ) {
    if (_hasInferredRedirectionTarget) return;
    _hasInferredRedirectionTarget = true;
    for (int i = 0; i < _declarations.length; i++) {
      _declarations[i].inferRedirectionTarget(
        libraryBuilder: libraryBuilder,
        factoryBuilder: this,
        classHierarchy: classHierarchy,
        delayedDefaultValueCloners: delayedDefaultValueCloners,
      );
    }
  }

  bool _hasBuiltOutlineExpressions = false;

  @override
  void buildOutlineExpressions(
    ClassHierarchy classHierarchy,
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  ) {
    inferRedirectionTarget(classHierarchy, delayedDefaultValueCloners);
    if (_hasBuiltOutlineExpressions) return;
    _hasBuiltOutlineExpressions = true;

    for (int i = 0; i < _declarations.length; i++) {
      _declarations[i].buildOutlineExpressions(
        libraryBuilder: libraryBuilder,
        factoryBuilder: this,
        classHierarchy: classHierarchy,
        delayedDefaultValueCloners: delayedDefaultValueCloners,
        annotatables: annotatables,
        annotatablesFileUri: _procedure.fileUri,
      );
    }
  }

  void resolveRedirectingFactory() {
    for (int i = 0; i < _declarations.length; i++) {
      _declarations[i].resolveRedirectingFactory(
        libraryBuilder: libraryBuilder,
      );
    }
  }
}

class InferableRedirectingFactory implements InferableMember {
  final SourceFactoryBuilder _builder;

  final ClassHierarchy _classHierarchy;
  final List<DelayedDefaultValueCloner> _delayedDefaultValueCloners;

  new(this._builder, this._classHierarchy, this._delayedDefaultValueCloners);

  @override
  Member get member => _builder.invokeTarget;

  @override
  void inferMemberTypes(ClassHierarchyBase classHierarchy) {
    _builder.inferRedirectionTarget(
      _classHierarchy,
      _delayedDefaultValueCloners,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void reportCyclicDependency() {
    // There is a cyclic dependency where inferring the types of the
    // initializing formals of a constructor required us to infer the
    // corresponding field type which required us to know the type of the
    // constructor.
    String name = _builder.declarationBuilder.name;
    if (_builder.name.isNotEmpty) {
      // TODO(ahe): Use `inferrer.helper.constructorNameForDiagnostics`
      // instead. However, `inferrer.helper` may be null.
      name += ".${_builder.name}";
    }
    _builder.libraryBuilder.addProblem(
      diag.cantInferTypeDueToCircularity.withArguments(name: name),
      _builder.fileOffset,
      name.length,
      _builder.fileUri,
    );
  }
}

/// [Reference]s used for the [Member] nodes created for a factory constructor.
class FactoryReferences {
  Reference? _factoryReference;
  Reference? _tearOffReference;

  /// If `true`, the factory constructor has a tear-off lowering and should
  /// therefore have distinct [factoryReference] and [tearOffReference]
  /// values.
  final bool _hasTearOffLowering;

  /// Creates a [FactoryReferences] object preloaded with the
  /// [preExistingFactoryReference] and [preExistingTearOffReference].
  ///
  /// For initial/one-off compilations these are `null`, but for subsequent
  /// compilations during an incremental compilation, these are the references
  /// used for the same factory constructor and tear-off in the previous
  /// compilation.
  new _({
    required Reference? preExistingFactoryReference,
    required Reference? preExistingTearOffReference,
    required bool hasTearOffLowering,
  }) : _factoryReference = preExistingFactoryReference,
       _tearOffReference = preExistingTearOffReference,
       _hasTearOffLowering = hasTearOffLowering,
       assert(
         !(preExistingTearOffReference != null && !hasTearOffLowering),
         "Unexpected tear off reference $preExistingTearOffReference.",
       );

  /// Creates a [FactoryReferences] object preloaded with the pre-existing
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
        loader.target.backendTarget.isFactoryTearOffLoweringEnabled,
      ExtensionBuilder() => false,
      ExtensionTypeDeclarationBuilder() => true,
    };

    Reference? preExistingFactoryReference;
    Reference? preExistingTearOffReference;

    if (indexedContainer != null) {
      preExistingFactoryReference = indexedContainer.lookupConstructorReference(
        nameScheme.getConstructorMemberName(name, isTearOff: false).name,
      );
      preExistingTearOffReference = indexedContainer.lookupGetterReference(
        nameScheme.getConstructorMemberName(name, isTearOff: true).name,
      );
    }

    return new FactoryReferences._(
      preExistingFactoryReference: preExistingFactoryReference,
      preExistingTearOffReference: preExistingTearOffReference,
      hasTearOffLowering: hasTearOffLowering,
    );
  }

  /// Registers that [builder] is created for the pre-existing references
  /// provided in [FactoryReferences._].
  ///
  /// This must be called before [factoryReference] and [tearOffReference] are
  /// accessed.
  void registerReference(
    ReferenceMap referenceMap,
    SourceFactoryBuilder builder,
  ) {
    if (_factoryReference != null) {
      referenceMap.registerNamedBuilder(_factoryReference!, builder);
    }
    if (_tearOffReference != null) {
      referenceMap.registerNamedBuilder(_tearOffReference!, builder);
    }
  }

  /// The [Reference] used to refer to the [Member] node created for the factory
  /// constructor.
  Reference get factoryReference => _factoryReference ??= new Reference();

  /// The [Reference] used to refer to the [Member] node created for the
  /// tear-off of the factory constructor.
  ///
  /// If a tear-off lowering is created for the factory constructor, this is
  /// distinct from [factoryReference], otherwise it is the same [Reference] as
  /// [factoryReference].
  Reference get tearOffReference => _tearOffReference ??= _hasTearOffLowering
      ? new Reference()
      : factoryReference;
}
