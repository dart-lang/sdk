// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/transformations/flags.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../base/identifiers.dart';
import '../base/local_scope.dart';
import '../base/modifiers.dart';
import '../base/name_space.dart';
import '../base/problems.dart' show unexpected, unhandled;
import '../base/scope.dart';
import '../builder/builder.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/function_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../builder/type_builder.dart';
import '../codes/cfe_codes.dart';
import '../dill/dill_extension_type_member_builder.dart';
import '../dill/dill_member_builder.dart';
import '../fragment/fragment.dart';
import '../kernel/body_builder_context.dart';
import '../kernel/constructor_tearoff_lowering.dart';
import '../kernel/hierarchy/class_member.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/type_algorithms.dart';
import '../type_inference/inference_helper.dart';
import '../type_inference/type_inference_engine.dart';
import '../type_inference/type_inferrer.dart';
import '../type_inference/type_schema.dart';
import 'name_scheme.dart';
import 'redirecting_factory_body.dart';
import 'source_class_builder.dart';
import 'source_function_builder.dart';
import 'source_library_builder.dart' show SourceLibraryBuilder;
import 'source_loader.dart'
    show CompilationPhaseForProblemReporting, SourceLoader;
import 'source_member_builder.dart';

class SourceFactoryBuilder extends SourceMemberBuilderImpl
    implements FunctionBuilder {
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

  // Coverage-ignore(suite): Not run.
  List<NominalParameterBuilder>? get typeParametersForTesting =>
      _introductory.typeParameters;

  // Coverage-ignore(suite): Not run.
  List<FormalParameterBuilder>? get formalsForTesting => _introductory.formals;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<MetadataBuilder>? get metadataForTesting => _introductory.metadata;

  ConstructorReferenceBuilder? get redirectionTarget =>
      _lastDeclaration.redirectionTarget;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAugmentation => modifiers.isAugment;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isExternal => modifiers.isExternal;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAbstract => modifiers.isAbstract;

  @override
  bool get isConst => modifiers.isConst;

  @override
  bool get isStatic => modifiers.isStatic;

  @override
  bool get isAugment => modifiers.isAugment;

  @override
  bool get isConstructor => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAssignable => false;

  void becomeNative(SourceLoader loader) {
    _introductory.becomeNative(loader: loader, annotatables: annotatables);
    for (FactoryDeclaration augmentation in _augmentations) {
      // Coverage-ignore-block(suite): Not run.
      augmentation.becomeNative(loader: loader, annotatables: annotatables);
    }
  }

  @override
  Builder get parent => declarationBuilder;

  @override
  // Coverage-ignore(suite): Not run.
  Name get memberName => _memberName.name;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isRegularMethod => false;

  @override
  bool get isGetter => false;

  @override
  bool get isSetter => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isOperator => false;

  @override
  bool get isFactory => true;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isProperty => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isFinal => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSynthesized => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isEnumElement => false;

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

  // Coverage-ignore(suite): Not run.
  /// If this is an extension instance method or constructor with lowering
  /// enabled, the tear off parameter corresponding to the [index]th parameter
  /// on the instance method or constructor is returned.
  ///
  /// This is used to update the default value for the closure parameter when
  /// it has been computed for the original parameter.
  VariableDeclaration? getTearOffParameter(int index) =>
      _introductory.getTearOffParameter(index);

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
        createFileUriExpression:
            _introductory.fileUri != _lastDeclaration.fileUri);
    for (FactoryDeclaration augmentation in _augmentations) {
      augmentation.buildOutlineExpressions(
          libraryBuilder: libraryBuilder,
          factoryBuilder: this,
          classHierarchy: classHierarchy,
          delayedDefaultValueCloners: delayedDefaultValueCloners,
          createFileUriExpression:
              augmentation.fileUri != _lastDeclaration.fileUri);
    }
  }

  void resolveRedirectingFactory() {
    _introductory.resolveRedirectingFactory(
        libraryBuilder: libraryBuilder, factoryBuilder: this);
    for (FactoryDeclaration augmentation in _augmentations) {
      augmentation.resolveRedirectingFactory(
          libraryBuilder: libraryBuilder, factoryBuilder: this);
    }
  }
}

class FactoryBodyBuilderContext extends BodyBuilderContext {
  final SourceFactoryBuilder _builder;

  final FactoryDeclaration _declaration;

  final Member _member;

  FactoryBodyBuilderContext(this._builder, this._declaration, this._member)
      : super(_builder.libraryBuilder, _builder.declarationBuilder,
            isDeclarationInstanceMember: _builder.isDeclarationInstanceMember);

  @override
  VariableDeclaration getFormalParameter(int index) {
    return _declaration.getFormalParameter(index);
  }

  @override
  VariableDeclaration? getTearOffParameter(int index) {
    return _declaration.getTearOffParameter(index);
  }

  @override
  TypeBuilder get returnType => _declaration.returnType;

  @override
  // Coverage-ignore(suite): Not run.
  List<FormalParameterBuilder>? get formals => _declaration.formals;

  @override
  LocalScope computeFormalParameterInitializerScope(LocalScope parent) {
    /// Initializer formals or super parameters cannot occur in getters so
    /// we don't need to create a new scope.
    return parent;
  }

  @override
  FormalParameterBuilder? getFormalParameterByName(Identifier name) {
    return _declaration.getFormal(name);
  }

  @override
  int get memberNameLength => _builder.name.length;

  @override
  FunctionNode get function {
    return _declaration.function;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isFactory => true;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isNativeMethod {
    return _declaration.isNative;
  }

  @override
  bool get isExternalFunction {
    return _declaration.isExternal;
  }

  @override
  bool get isSetter => false;

  @override
  int get memberNameOffset => _declaration.fileOffset;

  @override
  // Coverage-ignore(suite): Not run.
  void registerSuperCall() {
    _member.transformerFlags |= TransformerFlag.superCalls;
  }

  @override
  void registerFunctionBody(Statement body) {
    _declaration.setBody(body);
  }

  @override
  void setAsyncModifier(AsyncMarker asyncModifier) {
    _declaration.setAsyncModifier(asyncModifier);
  }

  @override
  bool get isRedirectingFactory => _declaration.redirectionTarget != null;

  @override
  DartType get returnTypeContext {
    return _declaration.function.returnType;
  }

  @override
  String get redirectingFactoryTargetName {
    return _declaration.redirectionTarget!.fullNameForErrors;
  }
}

abstract class FactoryDeclaration {
  Procedure get procedure;

  Procedure? get tearOff;

  FunctionNode get function;

  List<NominalParameterBuilder>? get typeParameters;

  TypeBuilder get returnType;

  void createNode({
    required String name,
    required SourceLibraryBuilder libraryBuilder,
    required NameScheme nameScheme,
    required Reference? procedureReference,
    required Reference? tearOffReference,
  });

  void buildOutlineNodes(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required BuildNodesCallback f,
      required bool isConst});

  void buildOutlineExpressions(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required ClassHierarchy classHierarchy,
      required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
      required bool createFileUriExpression});

  void inferRedirectionTarget(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required ClassHierarchy classHierarchy,
      required List<DelayedDefaultValueCloner> delayedDefaultValueCloners});

  /// Checks this factory builder if it is for a redirecting factory.
  void checkRedirectingFactory(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required TypeEnvironment typeEnvironment});

  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery});

  void checkTypes(SourceLibraryBuilder library, NameSpace nameSpace,
      TypeEnvironment typeEnvironment);

  void setBody(Statement value);

  void setAsyncModifier(AsyncMarker newModifier);

  FormalParameterBuilder? getFormal(Identifier identifier);

  VariableDeclaration? getTearOffParameter(int index);

  abstract List<DartType>? redirectionTypeArguments;

  bool get isNative;

  bool get isExternal;

  Uri get fileUri;

  int get fileOffset;

  void becomeNative(
      {required SourceLoader loader,
      required Iterable<Annotatable> annotatables});

  void resolveRedirectingFactory(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder});

  void setRedirectingFactoryBody(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required Member target,
      required List<DartType> typeArguments});

  List<FormalParameterBuilder>? get formals;

  /// Returns the [index]th parameter of this function.
  ///
  /// The index is the syntactical index, including both positional and named
  /// parameter in the order they are declared, and excluding the synthesized
  /// this parameter on extension instance members.
  VariableDeclaration getFormalParameter(int index);

  Iterable<MetadataBuilder>? get metadata;

  ConstructorReferenceBuilder? get redirectionTarget;

  BodyBuilderContext createBodyBuilderContext(
      SourceFactoryBuilder factoryBuilder);
}

class FactoryDeclarationImpl implements FactoryDeclaration {
  final FactoryFragment _fragment;
  @override
  final List<NominalParameterBuilder>? typeParameters;
  @override
  final TypeBuilder returnType;
  final FactoryEncoding _encoding;

  FactoryDeclarationImpl(this._fragment,
      {required this.typeParameters, required this.returnType})
      : _encoding = new FactoryEncoding(_fragment,
            typeParameters: typeParameters,
            returnType: returnType,
            redirectionTarget: _fragment.redirectionTarget) {
    _fragment.declaration = this;
  }

  @override
  Procedure get procedure => _encoding.procedure;

  @override
  Procedure? get tearOff => _encoding.tearOff;

  @override
  FunctionNode get function => _encoding.function;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isNative => _encoding.isNative;

  @override
  bool get isExternal => _fragment.modifiers.isExternal;

  @override
  Uri get fileUri => _fragment.fileUri;

  @override
  int get fileOffset => _fragment.fullNameOffset;

  @override
  void becomeNative(
      {required SourceLoader loader,
      required Iterable<Annotatable> annotatables}) {
    for (Annotatable annotatable in annotatables) {
      loader.addNativeAnnotation(annotatable, _fragment.nativeMethodName!);
    }
    _encoding.becomeNative(loader);
  }

  @override
  void createNode({
    required String name,
    required SourceLibraryBuilder libraryBuilder,
    required NameScheme nameScheme,
    required Reference? procedureReference,
    required Reference? tearOffReference,
  }) {
    _encoding.createNode(
        name: name,
        libraryBuilder: libraryBuilder,
        nameScheme: nameScheme,
        procedureReference: procedureReference,
        tearOffReference: tearOffReference);
  }

  @override
  void buildOutlineNodes(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required BuildNodesCallback f,
      required bool isConst}) {
    _encoding.buildOutlineNodes(
        libraryBuilder: libraryBuilder,
        factoryBuilder: factoryBuilder,
        f: f,
        isConst: isConst);
  }

  @override
  BodyBuilderContext createBodyBuilderContext(
      SourceFactoryBuilder factoryBuilder) {
    return new FactoryBodyBuilderContext(
        factoryBuilder, this, _encoding.procedure);
  }

  @override
  void buildOutlineExpressions(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required ClassHierarchy classHierarchy,
      required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
      required bool createFileUriExpression}) {
    _fragment.formals?.infer(classHierarchy);

    BodyBuilderContext bodyBuilderContext =
        createBodyBuilderContext(factoryBuilder);

    for (Annotatable annotatable in factoryBuilder.annotatables) {
      MetadataBuilder.buildAnnotations(
          annotatable,
          _fragment.metadata,
          bodyBuilderContext,
          libraryBuilder,
          _fragment.fileUri,
          _fragment.enclosingScope,
          createFileUriExpression: createFileUriExpression);
    }
    if (typeParameters != null) {
      for (int i = 0; i < typeParameters!.length; i++) {
        typeParameters![i].buildOutlineExpressions(libraryBuilder,
            bodyBuilderContext, classHierarchy, _fragment.typeParameterScope);
      }
    }

    if (_fragment.formals != null) {
      // For const constructors we need to include default parameter values
      // into the outline. For all other formals we need to call
      // buildOutlineExpressions to clear initializerToken to prevent
      // consuming too much memory.
      for (FormalParameterBuilder formal in _fragment.formals!) {
        formal.buildOutlineExpressions(
            libraryBuilder, factoryBuilder.declarationBuilder,
            scope: _fragment.typeParameterScope,
            buildDefaultValue: FormalParameterBuilder
                .needsDefaultValuesBuiltAsOutlineExpressions(factoryBuilder));
      }
    }

    _encoding.buildOutlineExpressions(
        libraryBuilder: libraryBuilder,
        factoryBuilder: factoryBuilder,
        bodyBuilderContext: bodyBuilderContext,
        classHierarchy: classHierarchy,
        delayedDefaultValueCloners: delayedDefaultValueCloners);
  }

  @override
  void inferRedirectionTarget(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required ClassHierarchy classHierarchy,
      required List<DelayedDefaultValueCloner> delayedDefaultValueCloners}) {
    BodyBuilderContext bodyBuilderContext =
        createBodyBuilderContext(factoryBuilder);
    _encoding.inferRedirectionTarget(
        libraryBuilder: libraryBuilder,
        factoryBuilder: factoryBuilder,
        bodyBuilderContext: bodyBuilderContext,
        classHierarchy: classHierarchy,
        delayedDefaultValueCloners: delayedDefaultValueCloners);
  }

  @override
  void checkRedirectingFactory(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required TypeEnvironment typeEnvironment}) {
    _encoding.checkRedirectingFactory(
        libraryBuilder: libraryBuilder,
        factoryBuilder: factoryBuilder,
        typeEnvironment: typeEnvironment);
  }

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    int count = context.computeDefaultTypesForVariables(typeParameters,
        // Type parameters are inherited from the enclosing declaration, so if
        // it has issues, so do the constructors.
        inErrorRecovery: inErrorRecovery);
    context.reportGenericFunctionTypesForFormals(_fragment.formals);
    return count;
  }

  @override
  void checkTypes(SourceLibraryBuilder library, NameSpace nameSpace,
      TypeEnvironment typeEnvironment) {
    if (_fragment.redirectionTarget != null) {
      // Default values are not required on redirecting factory constructors so
      // we don't call [checkInitializersInFormals].
    } else {
      library.checkInitializersInFormals(_fragment.formals, typeEnvironment,
          isAbstract: _fragment.modifiers.isAbstract,
          isExternal: _fragment.modifiers.isExternal);
    }
  }

  @override
  void setBody(Statement value) {
    _encoding.setBody(value);
  }

  @override
  void setAsyncModifier(AsyncMarker newModifier) {
    _encoding.asyncModifier = newModifier;
  }

  @override
  FormalParameterBuilder? getFormal(Identifier identifier) {
    return _encoding.getFormal(identifier);
  }

  @override
  VariableDeclaration? getTearOffParameter(int index) {
    return _encoding.getTearOffParameter(index);
  }

  @override
  // Coverage-ignore(suite): Not run.
  List<DartType>? get redirectionTypeArguments =>
      _encoding.redirectionTypeArguments;

  @override
  // Coverage-ignore(suite): Not run.
  void set redirectionTypeArguments(List<DartType>? value) {
    _encoding.redirectionTypeArguments = value;
  }

  @override
  void resolveRedirectingFactory(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder}) {
    _encoding.resolveRedirectingFactory(
        libraryBuilder: libraryBuilder, factoryBuilder: factoryBuilder);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void setRedirectingFactoryBody(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required Member target,
      required List<DartType> typeArguments}) {
    _encoding.setRedirectingFactoryBody(
        libraryBuilder: libraryBuilder,
        factoryBuilder: factoryBuilder,
        target: target,
        typeArguments: typeArguments);
  }

  @override
  // Coverage-ignore(suite): Not run.
  List<FormalParameterBuilder>? get formals => _fragment.formals;

  @override
  VariableDeclaration getFormalParameter(int index) =>
      _fragment.formals![index].variable!;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  ConstructorReferenceBuilder? get redirectionTarget {
    return _fragment.redirectionTarget;
  }
}

class FactoryEncoding implements InferredTypeListener {
  late final Procedure _procedureInternal;
  late final Procedure? _factoryTearOff;

  final FactoryFragment _fragment;

  AsyncMarker _asyncModifier;

  final List<NominalParameterBuilder>? typeParameters;

  final TypeBuilder returnType;

  DelayedDefaultValueCloner? _delayedDefaultValueCloner;

  List<DartType>? _redirectionTypeArguments;

  FreshTypeParameters? _tearOffTypeParameters;

  final ConstructorReferenceBuilder? _redirectionTarget;

  FactoryEncoding(
    this._fragment, {
    required this.typeParameters,
    required this.returnType,
    required ConstructorReferenceBuilder? redirectionTarget,
  })  : _redirectionTarget = redirectionTarget,
        _asyncModifier = redirectionTarget != null
            ? AsyncMarker.Sync
            : _fragment.asyncModifier;

  void createNode({
    required String name,
    required SourceLibraryBuilder libraryBuilder,
    required NameScheme nameScheme,
    required Reference? procedureReference,
    required Reference? tearOffReference,
  }) {
    _procedureInternal = new Procedure(
        dummyName,
        nameScheme.isExtensionTypeMember
            ? ProcedureKind.Method
            : ProcedureKind.Factory,
        new FunctionNode(null)
          ..asyncMarker = _asyncModifier
          ..dartAsyncMarker = _asyncModifier,
        fileUri: _fragment.fileUri,
        reference: procedureReference)
      ..fileStartOffset = _fragment.startOffset
      ..fileOffset = _fragment.fullNameOffset
      ..fileEndOffset = _fragment.endOffset
      ..isExtensionTypeMember = nameScheme.isExtensionTypeMember;
    nameScheme
        .getConstructorMemberName(name, isTearOff: false)
        .attachMember(_procedureInternal);
    _factoryTearOff = createFactoryTearOffProcedure(
        nameScheme.getConstructorMemberName(name, isTearOff: true),
        libraryBuilder,
        _fragment.fileUri,
        _fragment.fullNameOffset,
        tearOffReference,
        forceCreateLowering: nameScheme.isExtensionTypeMember)
      ?..isExtensionTypeMember = nameScheme.isExtensionTypeMember;
    returnType.registerInferredTypeListener(this);
  }

  Procedure get procedure => _procedureInternal;

  Procedure? get tearOff => _factoryTearOff;

  @override
  // Coverage-ignore(suite): Not run.
  void onInferredType(DartType type) {
    _procedureInternal.function.returnType = type;
  }

  void set asyncModifier(AsyncMarker newModifier) {
    _asyncModifier = newModifier;
    _procedureInternal.function.asyncMarker = _asyncModifier;
    _procedureInternal.function.dartAsyncMarker = _asyncModifier;
  }

  List<DartType>? get redirectionTypeArguments {
    assert(_redirectionTarget != null);
    return _redirectionTypeArguments;
  }

  void set redirectionTypeArguments(List<DartType>? value) {
    assert(_redirectionTarget != null);
    _redirectionTypeArguments = value;
  }

  void buildOutlineNodes(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required BuildNodesCallback f,
      required bool isConst}) {
    _procedureInternal.function.asyncMarker = _asyncModifier;
    if (_redirectionTarget == null &&
        !_fragment.modifiers.isAbstract &&
        !_fragment.modifiers.isExternal) {
      _procedureInternal.function.body = new EmptyStatement()
        ..parent = _procedureInternal.function;
    }
    buildTypeParametersAndFormals(libraryBuilder, _procedureInternal.function,
        typeParameters, _fragment.formals,
        classTypeParameters: null, supportsTypeParameters: true);
    if (returnType is! InferableTypeBuilder) {
      _procedureInternal.function.returnType =
          returnType.build(libraryBuilder, TypeUse.returnType);
    }
    _procedureInternal.function.fileOffset = _fragment.formalsOffset;
    _procedureInternal.function.fileEndOffset =
        _procedureInternal.fileEndOffset;
    _procedureInternal.isAbstract = _fragment.modifiers.isAbstract;
    _procedureInternal.isExternal = _fragment.modifiers.isExternal;
    // TODO(johnniwinther): DDC platform currently relies on the ability to
    // patch a const constructor with a non-const patch. Remove this and enforce
    // equal constness on origin and patch.
    _procedureInternal.isConst = isConst;
    _procedureInternal.isStatic = _fragment.modifiers.isStatic;

    if (_redirectionTarget != null) {
      if (_redirectionTarget.typeArguments != null) {
        redirectionTypeArguments = new List<DartType>.generate(
            _redirectionTarget.typeArguments!.length,
            (int i) => _redirectionTarget.typeArguments![i]
                .build(libraryBuilder, TypeUse.redirectionTypeArgument),
            growable: false);
      }
      if (_factoryTearOff != null) {
        _tearOffTypeParameters =
            buildRedirectingFactoryTearOffProcedureParameters(
                tearOff: _factoryTearOff,
                implementationConstructor: _procedureInternal,
                libraryBuilder: libraryBuilder);
      }
    } else {
      if (_factoryTearOff != null) {
        _delayedDefaultValueCloner = buildConstructorTearOffProcedure(
            tearOff: _factoryTearOff,
            declarationConstructor: factoryBuilder._procedure,
            implementationConstructor: _procedureInternal,
            libraryBuilder: libraryBuilder);
      }
    }
    f(
        member: _procedureInternal,
        tearOff: _factoryTearOff,
        kind: factoryBuilder.isExtensionTypeMember
            ? (_redirectionTarget != null
                ? BuiltMemberKind.ExtensionTypeRedirectingFactory
                : BuiltMemberKind.ExtensionTypeFactory)
            : (_redirectionTarget != null
                ? BuiltMemberKind.RedirectingFactory
                : BuiltMemberKind.Factory));
  }

  void buildOutlineExpressions(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required BodyBuilderContext bodyBuilderContext,
      required ClassHierarchy classHierarchy,
      required List<DelayedDefaultValueCloner> delayedDefaultValueCloners}) {
    if (_delayedDefaultValueCloner != null) {
      delayedDefaultValueCloners.add(_delayedDefaultValueCloner!);
    }
  }

  void inferRedirectionTarget(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required BodyBuilderContext bodyBuilderContext,
      required ClassHierarchy classHierarchy,
      required List<DelayedDefaultValueCloner> delayedDefaultValueCloners}) {
    if (_redirectionTarget == null) {
      return;
    }

    RedirectingFactoryTarget? redirectingFactoryTarget =
        _procedureInternal.function.redirectingFactoryTarget;
    if (redirectingFactoryTarget == null) {
      // The error is reported elsewhere.
      return;
    }
    List<DartType>? typeArguments = redirectingFactoryTarget.typeArguments;
    Member? target = redirectingFactoryTarget.target;
    if (typeArguments != null && typeArguments.any((t) => t is UnknownType)) {
      TypeInferrer inferrer = libraryBuilder.loader.typeInferenceEngine
          .createLocalTypeInferrer(
              _fragment.fileUri,
              factoryBuilder.declarationBuilder.thisType,
              libraryBuilder,
              _fragment.typeParameterScope,
              null);
      InferenceHelper helper = libraryBuilder.loader
          .createBodyBuilderForOutlineExpression(libraryBuilder,
              bodyBuilderContext, _fragment.enclosingScope, _fragment.fileUri);
      Builder? targetBuilder = _redirectionTarget.target;

      if (targetBuilder is SourceMemberBuilder) {
        // Ensure that target has been built.
        targetBuilder.buildOutlineExpressions(
            classHierarchy, delayedDefaultValueCloners);
      }
      if (targetBuilder is FunctionBuilder) {
        target = targetBuilder.invokeTarget!;
      }
      // Coverage-ignore(suite): Not run.
      else if (targetBuilder is DillMemberBuilder) {
        target = targetBuilder.invokeTarget!;
      } else {
        unhandled("${targetBuilder.runtimeType}", "buildOutlineExpressions",
            _fragment.fullNameOffset, _fragment.fileUri);
      }

      typeArguments = inferrer.inferRedirectingFactoryTypeArguments(
          helper,
          _procedureInternal.function.returnType,
          factoryBuilder._procedure.function,
          _fragment.fullNameOffset,
          target,
          target.function!.computeFunctionType(Nullability.nonNullable));
      if (typeArguments == null) {
        assert(libraryBuilder.loader.assertProblemReportedElsewhere(
            "RedirectingFactoryTarget.buildOutlineExpressions",
            expectedPhase: CompilationPhaseForProblemReporting.outline));
        // Use 'dynamic' for recovery.
        typeArguments = new List<DartType>.filled(
            factoryBuilder.declarationBuilder.typeParametersCount,
            const DynamicType(),
            growable: true);
      }

      _procedureInternal.function.body = createRedirectingFactoryBody(
          target, typeArguments, _procedureInternal.function);
      _procedureInternal.function.body!.parent = _procedureInternal.function;
      _procedureInternal.function.redirectingFactoryTarget =
          new RedirectingFactoryTarget(target, typeArguments);
    }

    Set<Procedure> seenTargets = {};
    while (target is Procedure && target.isRedirectingFactory) {
      if (!seenTargets.add(target)) {
        // Cyclic dependency.
        target = null;
        break;
      }
      RedirectingFactoryTarget redirectingFactoryTarget =
          target.function.redirectingFactoryTarget!;
      if (typeArguments != null) {
        Substitution substitution = Substitution.fromPairs(
            target.function.typeParameters, typeArguments);
        typeArguments = redirectingFactoryTarget.typeArguments
            ?.map(substitution.substituteType)
            .toList();
      } else {
        // Coverage-ignore-block(suite): Not run.
        typeArguments = redirectingFactoryTarget.typeArguments;
      }
      target = redirectingFactoryTarget.target;
    }

    if (target is Constructor ||
        target is Procedure &&
            (target.isFactory || target.isExtensionTypeMember)) {
      // Coverage-ignore(suite): Not run.
      typeArguments ??= [];
      if (_factoryTearOff != null) {
        delayedDefaultValueCloners.add(buildRedirectingFactoryTearOffBody(
            _factoryTearOff,
            target!,
            typeArguments,
            _tearOffTypeParameters!,
            libraryBuilder));
      }
      delayedDefaultValueCloners.add(new DelayedDefaultValueCloner(
          target!, factoryBuilder._procedure,
          libraryBuilder: libraryBuilder, identicalSignatures: false));
    }
  }

  void resolveRedirectingFactory(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder}) {
    ConstructorReferenceBuilder? redirectionTarget = _redirectionTarget;
    if (redirectionTarget != null) {
      // Compute the immediate redirection target, not the effective.
      List<TypeBuilder>? typeArguments = redirectionTarget.typeArguments;
      Builder? target = redirectionTarget.target;
      if (typeArguments != null && target is MemberBuilder) {
        TypeName redirectionTargetName = redirectionTarget.typeName;
        if (redirectionTargetName.qualifier == null) {
          // Do nothing. This is the case of an identifier followed by
          // type arguments, such as the following:
          //   B<T>
          //   B<T>.named
        } else {
          if (target.name.isEmpty) {
            // Do nothing. This is the case of a qualified
            // non-constructor prefix (for example, with a library
            // qualifier) followed by type arguments, such as the
            // following:
            //   lib.B<T>
          } else if (target.name != redirectionTargetName.name) {
            // Do nothing. This is the case of a qualified
            // non-constructor prefix followed by type arguments followed
            // by a constructor name, such as the following:
            //   lib.B<T>.named
          } else {
            // TODO(cstefantsova,johnniwinther): Handle this in case in
            // ConstructorReferenceBuilder.resolveIn and unify with other
            // cases of handling of type arguments after constructor
            // names.
            libraryBuilder.addProblem(
                messageConstructorWithTypeArguments,
                redirectionTargetName.nameOffset,
                redirectionTargetName.nameLength,
                _fragment.fileUri);
          }
        }
      }

      Builder? targetBuilder = redirectionTarget.target;
      Member? targetNode;
      if (targetBuilder is FunctionBuilder) {
        targetNode = targetBuilder.invokeTarget!;
      } else if (targetBuilder is DillMemberBuilder) {
        targetNode = targetBuilder.invokeTarget!;
      } else if (targetBuilder is AmbiguousBuilder) {
        _addProblemForRedirectingFactory(
            libraryBuilder: libraryBuilder,
            factoryBuilder: factoryBuilder,
            message: templateDuplicatedDeclarationUse
                .withArguments(redirectionTarget.fullNameForErrors),
            fileOffset: redirectionTarget.charOffset,
            length: noLength,
            fileUri: redirectionTarget.fileUri);
      } else {
        _addProblemForRedirectingFactory(
            libraryBuilder: libraryBuilder,
            factoryBuilder: factoryBuilder,
            message: templateRedirectionTargetNotFound
                .withArguments(redirectionTarget.fullNameForErrors),
            fileOffset: redirectionTarget.charOffset,
            length: noLength,
            fileUri: redirectionTarget.fileUri);
      }
      if (targetNode != null &&
          targetNode is Constructor &&
          targetNode.enclosingClass.isAbstract) {
        _addProblemForRedirectingFactory(
            libraryBuilder: libraryBuilder,
            factoryBuilder: factoryBuilder,
            message: templateAbstractRedirectedClassInstantiation
                .withArguments(redirectionTarget.fullNameForErrors),
            fileOffset: redirectionTarget.charOffset,
            length: noLength,
            fileUri: redirectionTarget.fileUri);
        targetNode = null;
      }
      if (targetNode != null &&
          targetNode is Constructor &&
          targetNode.enclosingClass.isEnum) {
        _addProblemForRedirectingFactory(
            libraryBuilder: libraryBuilder,
            factoryBuilder: factoryBuilder,
            message: messageEnumFactoryRedirectsToConstructor,
            fileOffset: redirectionTarget.charOffset,
            length: noLength,
            fileUri: redirectionTarget.fileUri);
        targetNode = null;
      }
      if (targetNode != null) {
        List<DartType>? typeArguments = redirectionTypeArguments;
        if (typeArguments == null) {
          int typeArgumentCount;
          if (targetBuilder!.isExtensionTypeMember) {
            ExtensionTypeDeclarationBuilder extensionTypeDeclarationBuilder =
                targetBuilder.parent as ExtensionTypeDeclarationBuilder;
            typeArgumentCount =
                extensionTypeDeclarationBuilder.typeParametersCount;
          } else {
            typeArgumentCount =
                targetNode.enclosingClass!.typeParameters.length;
          }
          typeArguments =
              new List<DartType>.filled(typeArgumentCount, const UnknownType());
        }
        setRedirectingFactoryBody(
            libraryBuilder: libraryBuilder,
            factoryBuilder: factoryBuilder,
            target: targetNode,
            typeArguments: typeArguments);
      }
    }
  }

  void setRedirectingFactoryBody(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required Member target,
      required List<DartType> typeArguments}) {
    if (_procedureInternal.function.body != null) {
      unexpected("null", "${_procedureInternal.function.body.runtimeType}",
          _fragment.fullNameOffset, _fragment.fileUri);
    }

    // Ensure that constant factories only have constant targets/bodies.
    if (_fragment.modifiers.isConst && !target.isConst) {
      // Coverage-ignore-block(suite): Not run.
      libraryBuilder.addProblem(messageConstFactoryRedirectionToNonConst,
          _fragment.fullNameOffset, noLength, _fragment.fileUri);
    }

    _procedureInternal.function.body = createRedirectingFactoryBody(
        target, typeArguments, _procedureInternal.function)
      ..parent = _procedureInternal.function;
    _procedureInternal.function.redirectingFactoryTarget =
        new RedirectingFactoryTarget(target, typeArguments);
  }

  void _addProblemForRedirectingFactory(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required Message message,
      required int fileOffset,
      required int length,
      required Uri fileUri}) {
    libraryBuilder.addProblem(message, fileOffset, length, fileUri);
    String text = libraryBuilder.loader.target.context
        .format(
            message.withLocation(fileUri, fileOffset, length), Severity.error)
        .plain;
    _setRedirectingFactoryError(factoryBuilder: factoryBuilder, message: text);
  }

  void _setRedirectingFactoryError(
      {required SourceFactoryBuilder factoryBuilder, required String message}) {
    assert(_redirectionTarget != null);

    setBody(createRedirectingFactoryErrorBody(message));
    factoryBuilder._procedure.function.redirectingFactoryTarget =
        new RedirectingFactoryTarget.error(message);
    if (_factoryTearOff != null) {
      _factoryTearOff.function.body = createRedirectingFactoryErrorBody(message)
        ..parent = _factoryTearOff.function;
    }
  }

  /// Checks this factory builder if it is for a redirecting factory.
  void checkRedirectingFactory(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required TypeEnvironment typeEnvironment}) {
    assert(_redirectionTarget != null);

    // Check that factory declaration is not cyclic.
    if (_isCyclicRedirectingFactory(factoryBuilder)) {
      _addProblemForRedirectingFactory(
          libraryBuilder: libraryBuilder,
          factoryBuilder: factoryBuilder,
          message: templateCyclicRedirectingFactoryConstructors
              .withArguments("${factoryBuilder.declarationBuilder.name}"
                  "${_fragment.name == '' ? '' : '.${_fragment.name}'}"),
          fileOffset: _fragment.fullNameOffset,
          length: noLength,
          fileUri: _fragment.fileUri);
      return;
    }

    // The factory type cannot contain any type parameters other than those of
    // its enclosing class, because constructors cannot specify type parameters
    // of their own.
    FunctionType factoryType = _procedureInternal.function
        .computeThisFunctionType(Nullability.nonNullable);
    FunctionType? redirecteeType = _computeRedirecteeType(
        libraryBuilder: libraryBuilder,
        factoryBuilder: factoryBuilder,
        typeEnvironment: typeEnvironment);
    Map<TypeParameter, DartType> substitutionMap = {};
    for (int i = 0; i < factoryType.typeParameters.length; i++) {
      TypeParameter functionTypeParameter =
          factoryBuilder.function.typeParameters[i];
      substitutionMap[functionTypeParameter] =
          new StructuralParameterType.withDefaultNullability(
              factoryType.typeParameters[i]);
    }
    redirecteeType = redirecteeType != null
        ? substitute(redirecteeType, substitutionMap) as FunctionType
        : null;

    // TODO(hillerstrom): It would be preferable to know whether a failure
    // happened during [_computeRedirecteeType].
    if (redirecteeType == null) {
      return;
    }

    Builder? redirectionTargetBuilder = _redirectionTarget!.target;
    if (redirectionTargetBuilder is SourceFactoryBuilder &&
        redirectionTargetBuilder.redirectionTarget != null) {
      redirectionTargetBuilder.checkRedirectingFactories(typeEnvironment);
      String? errorMessage = redirectionTargetBuilder
          .function.redirectingFactoryTarget?.errorMessage;
      if (errorMessage != null) {
        _setRedirectingFactoryError(
            factoryBuilder: factoryBuilder, message: errorMessage);
      }
    }

    Builder? redirectionTargetParent = _redirectionTarget.target?.parent;
    bool redirectingTargetParentIsEnum = redirectionTargetParent is ClassBuilder
        ? redirectionTargetParent.isEnum
        : false;
    if (!((factoryBuilder.classBuilder?.cls.isEnum ?? false) &&
        (_redirectionTarget.target?.isConstructor ?? false) &&
        redirectingTargetParentIsEnum)) {
      // Check whether [redirecteeType] <: [factoryType].
      FunctionType factoryTypeWithoutTypeParameters =
          factoryType.withoutTypeParameters;
      if (!typeEnvironment.isSubtypeOf(
          redirecteeType,
          factoryTypeWithoutTypeParameters,
          SubtypeCheckMode.withNullabilities)) {
        _addProblemForRedirectingFactory(
            libraryBuilder: libraryBuilder,
            factoryBuilder: factoryBuilder,
            message: templateIncompatibleRedirecteeFunctionType.withArguments(
                redirecteeType, factoryTypeWithoutTypeParameters),
            fileOffset: _redirectionTarget.charOffset,
            length: noLength,
            fileUri: _redirectionTarget.fileUri);
      }
    } else {
      // Redirection to generative enum constructors is forbidden.
      assert(libraryBuilder.loader.assertProblemReportedElsewhere(
          "RedirectingFactoryBuilder._checkRedirectingFactory: "
          "Redirection to generative enum constructor.",
          expectedPhase: CompilationPhaseForProblemReporting.bodyBuilding));
    }
  }

  // Computes the function type of a given redirection target. Returns [null] if
  // the type of the target could not be computed.
  FunctionType? _computeRedirecteeType(
      {required SourceLibraryBuilder libraryBuilder,
      required SourceFactoryBuilder factoryBuilder,
      required TypeEnvironment typeEnvironment}) {
    assert(_redirectionTarget != null);
    ConstructorReferenceBuilder redirectionTarget = _redirectionTarget!;
    Builder? targetBuilder = redirectionTarget.target;
    FunctionNode targetNode;
    if (targetBuilder == null) return null;
    if (targetBuilder is FunctionBuilder) {
      targetNode = targetBuilder.function;
    } else if (targetBuilder is DillExtensionTypeFactoryBuilder) {
      targetNode = targetBuilder.member.function!;
    } else if (targetBuilder is AmbiguousBuilder) {
      // Multiple definitions with the same name: An error has already been
      // issued.
      // TODO(http://dartbug.com/35294): Unfortunate error; see also
      // https://dart-review.googlesource.com/c/sdk/+/85390/.
      return null;
    } else {
      unhandled("${targetBuilder.runtimeType}", "computeRedirecteeType",
          _fragment.fullNameOffset, _fragment.fileUri);
    }

    List<DartType>? typeArguments =
        _getRedirectionTypeArguments(factoryBuilder: factoryBuilder);
    FunctionType targetFunctionType =
        targetNode.computeFunctionType(Nullability.nonNullable);
    if (typeArguments != null &&
        targetFunctionType.typeParameters.length != typeArguments.length) {
      _addProblemForRedirectingFactory(
          libraryBuilder: libraryBuilder,
          factoryBuilder: factoryBuilder,
          message: templateTypeArgumentMismatch
              .withArguments(targetFunctionType.typeParameters.length),
          fileOffset: redirectionTarget.charOffset,
          length: noLength,
          fileUri: redirectionTarget.fileUri);
      return null;
    }

    // Compute the substitution of the target class type parameters if
    // [redirectionTarget] has any type arguments.
    FunctionTypeInstantiator? instantiator;
    bool hasProblem = false;
    if (typeArguments != null && typeArguments.length > 0) {
      instantiator = new FunctionTypeInstantiator.fromIterables(
          targetFunctionType.typeParameters, typeArguments);
      for (int i = 0; i < targetFunctionType.typeParameters.length; i++) {
        StructuralParameter typeParameter =
            targetFunctionType.typeParameters[i];
        DartType typeParameterBound =
            instantiator.substitute(typeParameter.bound);
        DartType typeArgument = typeArguments[i];
        // Check whether the [typeArgument] respects the bounds of
        // [typeParameter].
        if (!typeEnvironment.isSubtypeOf(typeArgument, typeParameterBound,
            SubtypeCheckMode.ignoringNullabilities)) {
          // Coverage-ignore-block(suite): Not run.
          _addProblemForRedirectingFactory(
              libraryBuilder: libraryBuilder,
              factoryBuilder: factoryBuilder,
              message: templateRedirectingFactoryIncompatibleTypeArgument
                  .withArguments(typeArgument, typeParameterBound),
              fileOffset: redirectionTarget.charOffset,
              length: noLength,
              fileUri: redirectionTarget.fileUri);
          hasProblem = true;
        } else {
          if (!typeEnvironment.isSubtypeOf(typeArgument, typeParameterBound,
              SubtypeCheckMode.withNullabilities)) {
            _addProblemForRedirectingFactory(
                libraryBuilder: libraryBuilder,
                factoryBuilder: factoryBuilder,
                message: templateRedirectingFactoryIncompatibleTypeArgument
                    .withArguments(typeArgument, typeParameterBound),
                fileOffset: redirectionTarget.charOffset,
                length: noLength,
                fileUri: redirectionTarget.fileUri);
            hasProblem = true;
          }
        }
      }
    } else if (typeArguments == null &&
        targetFunctionType.typeParameters.length > 0) {
      // TODO(hillerstrom): In this case, we need to perform type inference on
      // the redirectee to obtain actual type arguments which would allow the
      // following program to type check:
      //
      //    class A<T> {
      //       factory A() = B;
      //    }
      //    class B<T> implements A<T> {
      //       B();
      //    }
      //
      return null;
    }

    // Substitute if necessary.
    targetFunctionType = instantiator == null
        ? targetFunctionType
        : (instantiator.substitute(targetFunctionType.withoutTypeParameters)
            as FunctionType);

    return hasProblem ? null : targetFunctionType;
  }

  static bool _isCyclicRedirectingFactory(SourceFactoryBuilder factory) {
    assert(factory.redirectionTarget != null);
    // We use the [tortoise and hare algorithm]
    // (https://en.wikipedia.org/wiki/Cycle_detection#Tortoise_and_hare) to
    // handle cycles.
    Builder? tortoise = factory;
    Builder? hare = factory.redirectionTarget!.target;
    if (hare == factory) {
      return true;
    }
    while (tortoise != hare) {
      // Hare moves 2 steps forward.
      if (hare is! SourceFactoryBuilder || hare.redirectionTarget == null) {
        return false;
      }
      hare = hare.redirectionTarget!.target;
      if (hare == factory) {
        return true;
      }
      if (hare is! SourceFactoryBuilder || hare.redirectionTarget == null) {
        return false;
      }
      hare = hare.redirectionTarget!.target;
      if (hare == factory) {
        return true;
      }
      // Tortoise moves one step forward. No need to test type of tortoise
      // as it follows hare which already checked types.
      tortoise = (tortoise as SourceFactoryBuilder).redirectionTarget!.target;
    }
    // Cycle found, but original factory doesn't belong to a cycle.
    return false;
  }

  List<DartType>? _getRedirectionTypeArguments(
      {required SourceFactoryBuilder factoryBuilder}) {
    assert(_redirectionTarget != null);
    return factoryBuilder
        ._procedure.function.redirectingFactoryTarget!.typeArguments;
  }

  void setBody(Statement value) {
    _procedureInternal.function.body = value
      ..parent = _procedureInternal.function;
  }

  void becomeNative(SourceLoader loader) {
    _procedureInternal.isExternal = true;
  }

  // Coverage-ignore(suite): Not run.
  bool get isNative => _fragment.nativeMethodName != null;

  FunctionNode get function => _procedureInternal.function;

  FormalParameterBuilder? getFormal(Identifier identifier) {
    if (_fragment.formals != null) {
      for (FormalParameterBuilder formal in _fragment.formals!) {
        if (formal.isWildcard &&
            identifier.name == '_' &&
            formal.fileOffset == identifier.nameOffset) {
          return formal;
        }
        if (formal.name == identifier.name &&
            formal.fileOffset == identifier.nameOffset) {
          return formal;
        }
      }
      // Coverage-ignore(suite): Not run.
      // If we have any formals we should find the one we're looking for.
      assert(false, "$identifier not found in ${_fragment.formals}");
    }
    return null;
  }

  VariableDeclaration? getTearOffParameter(int index) {
    if (_factoryTearOff != null) {
      if (index < _factoryTearOff.function.positionalParameters.length) {
        return _factoryTearOff.function.positionalParameters[index];
      } else {
        index -= _factoryTearOff.function.positionalParameters.length;
        if (index < _factoryTearOff.function.namedParameters.length) {
          return _factoryTearOff.function.namedParameters[index];
        }
      }
    }
    return null;
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
