// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_environment.dart';

import '../base/modifiers.dart';
import '../base/name_space.dart';
import '../builder/builder.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/factory_builder.dart';
import '../builder/metadata_builder.dart';
import '../codes/cfe_codes.dart';
import '../fragment/factory/declaration.dart';
import '../kernel/hierarchy/class_member.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/type_algorithms.dart';
import '../type_inference/type_inference_engine.dart';
import 'name_scheme.dart';
import 'source_class_builder.dart';
import 'source_library_builder.dart' show SourceLibraryBuilder;
import 'source_member_builder.dart';

class SourceFactoryBuilder extends SourceMemberBuilderImpl
    implements FactoryBuilder {
  final Modifiers modifiers;

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

  final FactoryDeclaration _introductory;

  final List<FactoryDeclaration> _augmentations;

  late final FactoryDeclaration _lastDeclaration;

  late final List<FactoryDeclaration> _augmentedDeclarations;

  SourceFactoryBuilder(
      {required this.modifiers,
      required this.name,
      required this.libraryBuilder,
      required this.declarationBuilder,
      required this.fileUri,
      required this.fileOffset,
      required Reference? procedureReference,
      required Reference? tearOffReference,
      required NameScheme nameScheme,
      required FactoryDeclaration introductory,
      required List<FactoryDeclaration> augmentations})
      : _memberName = nameScheme.getDeclaredName(name),
        _introductory = introductory,
        _augmentations = augmentations {
    if (augmentations.isEmpty) {
      _augmentedDeclarations = augmentations;
      _lastDeclaration = introductory;
    } else {
      _augmentedDeclarations = [introductory, ...augmentations];
      _lastDeclaration = _augmentedDeclarations.removeLast();
    }

    for (FactoryDeclaration augmentedDeclaration in _augmentedDeclarations) {
      augmentedDeclaration.createNode(
          name: name,
          libraryBuilder: libraryBuilder,
          nameScheme: nameScheme,
          procedureReference: null,
          tearOffReference: null);
    }
    _lastDeclaration.createNode(
        name: name,
        libraryBuilder: libraryBuilder,
        nameScheme: nameScheme,
        procedureReference: procedureReference,
        tearOffReference: tearOffReference);
  }

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<MetadataBuilder>? get metadataForTesting => _introductory.metadata;

  ConstructorReferenceBuilder? get redirectionTarget =>
      _lastDeclaration.redirectionTarget;

  @override
  bool get isConst => modifiers.isConst;

  @override
  bool get isStatic => modifiers.isStatic;

  @override
  // Coverage-ignore(suite): Not run.
  Builder get getable => this;

  @override
  // Coverage-ignore(suite): Not run.
  Builder? get setable => null;

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

  Procedure get _procedure => _lastDeclaration.procedure;

  Procedure? get _tearOff => _lastDeclaration.tearOff;

  @override
  FunctionNode get function => _lastDeclaration.function;

  @override
  Member get readTarget => _tearOff ?? _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference => readTarget.reference;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => null;

  @override
  Member get invokeTarget => _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get invokeTargetReference => _procedure.reference;

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
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    int count = _introductory.computeDefaultTypes(context,
        inErrorRecovery: inErrorRecovery);
    for (FactoryDeclaration augmentation in _augmentations) {
      count += augmentation.computeDefaultTypes(context,
          inErrorRecovery: inErrorRecovery);
    }
    return count;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {}

  @override
  void checkTypes(SourceLibraryBuilder library, NameSpace nameSpace,
      TypeEnvironment typeEnvironment) {
    _introductory.checkTypes(library, nameSpace, typeEnvironment);
    for (FactoryDeclaration augmentation in _augmentations) {
      augmentation.checkTypes(library, nameSpace, typeEnvironment);
    }
  }

  bool _hasBeenCheckedAsRedirectingFactory = false;

  /// Checks the redirecting factories of this factory builder and its
  /// augmentations.
  void checkRedirectingFactories(TypeEnvironment typeEnvironment) {
    if (_hasBeenCheckedAsRedirectingFactory) return;
    _hasBeenCheckedAsRedirectingFactory = true;

    if (_introductory.redirectionTarget != null) {
      _introductory.checkRedirectingFactory(
          libraryBuilder: libraryBuilder,
          factoryBuilder: this,
          typeEnvironment: typeEnvironment);
    }
    for (FactoryDeclaration augmentation in _augmentations) {
      if (augmentation.redirectionTarget != null) {
        augmentation.checkRedirectingFactory(
            libraryBuilder: libraryBuilder,
            factoryBuilder: this,
            typeEnvironment: typeEnvironment);
      }
    }
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
  void buildOutlineNodes(BuildNodesCallback f) {
    for (FactoryDeclaration augmentedDeclaration in _augmentedDeclarations) {
      augmentedDeclaration.buildOutlineNodes(
          libraryBuilder: libraryBuilder,
          factoryBuilder: this,
          isConst: isConst,
          f: noAddBuildNodesCallback);
    }
    _lastDeclaration.buildOutlineNodes(
        libraryBuilder: libraryBuilder,
        factoryBuilder: this,
        f: f,
        isConst: isConst);
  }

  bool _hasInferredRedirectionTarget = false;

  void inferRedirectionTarget(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (_hasInferredRedirectionTarget) return;
    _hasInferredRedirectionTarget = true;
    _introductory.inferRedirectionTarget(
        libraryBuilder: libraryBuilder,
        factoryBuilder: this,
        classHierarchy: classHierarchy,
        delayedDefaultValueCloners: delayedDefaultValueCloners);
    for (FactoryDeclaration augmentation in _augmentations) {
      augmentation.inferRedirectionTarget(
          libraryBuilder: libraryBuilder,
          factoryBuilder: this,
          classHierarchy: classHierarchy,
          delayedDefaultValueCloners: delayedDefaultValueCloners);
    }
  }

  bool _hasBuiltOutlineExpressions = false;

  @override
  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    inferRedirectionTarget(classHierarchy, delayedDefaultValueCloners);
    if (_hasBuiltOutlineExpressions) return;
    _hasBuiltOutlineExpressions = true;

    _introductory.buildOutlineExpressions(
        libraryBuilder: libraryBuilder,
        factoryBuilder: this,
        classHierarchy: classHierarchy,
        delayedDefaultValueCloners: delayedDefaultValueCloners,
        annotatables: annotatables,
        annotatablesFileUri: _procedure.fileUri);
    for (FactoryDeclaration augmentation in _augmentations) {
      augmentation.buildOutlineExpressions(
          libraryBuilder: libraryBuilder,
          factoryBuilder: this,
          classHierarchy: classHierarchy,
          delayedDefaultValueCloners: delayedDefaultValueCloners,
          annotatables: annotatables,
          annotatablesFileUri: _procedure.fileUri);
    }
  }

  void resolveRedirectingFactory() {
    _introductory.resolveRedirectingFactory(libraryBuilder: libraryBuilder);
    for (FactoryDeclaration augmentation in _augmentations) {
      augmentation.resolveRedirectingFactory(libraryBuilder: libraryBuilder);
    }
  }
}

class InferableRedirectingFactory implements InferableMember {
  final SourceFactoryBuilder _builder;

  final ClassHierarchy _classHierarchy;
  final List<DelayedDefaultValueCloner> _delayedDefaultValueCloners;

  InferableRedirectingFactory(
      this._builder, this._classHierarchy, this._delayedDefaultValueCloners);

  @override
  Member get member => _builder.invokeTarget;

  @override
  void inferMemberTypes(ClassHierarchyBase classHierarchy) {
    _builder.inferRedirectionTarget(
        _classHierarchy, _delayedDefaultValueCloners);
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
        templateCantInferTypeDueToCircularity.withArguments(name),
        _builder.fileOffset,
        name.length,
        _builder.fileUri);
  }
}
