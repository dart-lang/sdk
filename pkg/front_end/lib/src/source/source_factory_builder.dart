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
    implements SourceFunctionBuilder {
  final Modifiers modifiers;

  @override
  final String name;

  @override
  final SourceLibraryBuilder libraryBuilder;

  @override
  final DeclarationBuilder declarationBuilder;

  @override
  final bool isExtensionInstanceMember = false;

  SourceFactoryBuilder? _actualOrigin;

  List<SourceFactoryBuilder>? _augmentations;

  final MemberName _memberName;

  @override
  final Uri fileUri;

  @override
  final int fileOffset;

  final FactoryFragment _introductory;

  final _FactoryEncoding _encoding;

  SourceFactoryBuilder(
      {required this.modifiers,
      required TypeBuilder returnType,
      required this.name,
      required List<NominalParameterBuilder>? typeParameters,
      required this.libraryBuilder,
      required this.declarationBuilder,
      required this.fileUri,
      required this.fileOffset,
      required Reference? procedureReference,
      required Reference? tearOffReference,
      required NameScheme nameScheme,
      required FactoryFragment fragment})
      : _memberName = nameScheme.getDeclaredName(name),
        _introductory = fragment,
        _encoding = new _FactoryEncoding(fragment,
            name: name,
            libraryBuilder: libraryBuilder,
            typeParameters: typeParameters,
            returnType: returnType,
            nameScheme: nameScheme,
            procedureReference: procedureReference,
            tearOffReference: tearOffReference);

  @override
  List<MetadataBuilder>? get metadata => _introductory.metadata;

  @override
  // Coverage-ignore(suite): Not run.
  List<NominalParameterBuilder>? get typeParameters => _encoding.typeParameters;

  @override
  TypeBuilder get returnType => _encoding.returnType;

  @override
  // Coverage-ignore(suite): Not run.
  List<FormalParameterBuilder>? get formals => _introductory.formals;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<MetadataBuilder>? get metadataForTesting => metadata;

  ConstructorReferenceBuilder? get redirectionTarget =>
      _introductory.redirectionTarget;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAugmentation => modifiers.isAugment;

  @override
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

  @override
  FormalParameterBuilder? getFormal(Identifier identifier) =>
      _encoding.getFormal(identifier);

  void setBody(Statement value) {
    _encoding.setBody(value);
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isNative => _encoding.isNative;

  @override
  VariableDeclaration getFormalParameter(int index) =>
      _introductory.formals![index].variable!;

  @override
  VariableDeclaration? get thisVariable => null;

  @override
  List<TypeParameter>? get thisTypeParameters => null;

  @override
  void becomeNative(SourceLoader loader) {
    _encoding.becomeNative(loader);
  }

  @override
  Builder get parent => declarationBuilder;

  @override
  // Coverage-ignore(suite): Not run.
  Name get memberName => _memberName.name;

  // Coverage-ignore(suite): Not run.
  List<SourceFactoryBuilder>? get augmentationsForTesting => _augmentations;

  void _setAsyncModifier(AsyncMarker newModifier) {
    _encoding.asyncModifier = newModifier;
  }

  @override
  SourceFactoryBuilder get origin => _actualOrigin ?? this;

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

  Procedure get _procedure =>
      isAugmenting ? origin._procedure : _encoding.procedure;

  Procedure? get _tearOff => isAugmenting ? origin._tearOff : _encoding.tearOff;

  @override
  FunctionNode get function => _encoding.function;

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
  Member? get invokeTarget => _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get invokeTargetReference => _procedure.reference;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [_procedure.reference];

  @override
  VariableDeclaration? getTearOffParameter(int index) =>
      _encoding.getTearOffParameter(index);

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get localMembers =>
      throw new UnsupportedError('${runtimeType}.localMembers');

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get localSetters =>
      throw new UnsupportedError('${runtimeType}.localSetters');

  @override
  void applyAugmentation(Builder augmentation) {
    if (augmentation is SourceFactoryBuilder) {
      if (checkAugmentation(
          augmentationLibraryBuilder: augmentation.libraryBuilder,
          origin: this,
          augmentation: augmentation)) {
        augmentation._actualOrigin = this;
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
  int buildBodyNodes(BuildNodesCallback f) {
    if (!isAugmenting) return 0;
    _finishAugmentation();
    return 1;
  }

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    return _encoding.computeDefaultTypes(context,
        inErrorRecovery: inErrorRecovery);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {}

  @override
  void checkTypes(SourceLibraryBuilder library, NameSpace nameSpace,
      TypeEnvironment typeEnvironment) {
    _encoding.checkTypes(library, nameSpace, typeEnvironment);
    List<SourceFactoryBuilder>? augmentations = _augmentations;
    if (augmentations != null) {
      for (SourceFactoryBuilder augmentation in augmentations) {
        augmentation.checkTypes(library, nameSpace, typeEnvironment);
      }
    }
  }

  bool _hasBeenCheckedAsRedirectingFactory = false;

  /// Checks the redirecting factories of this factory builder and its
  /// augmentations.
  void checkRedirectingFactories(TypeEnvironment typeEnvironment) {
    if (_hasBeenCheckedAsRedirectingFactory) return;
    _hasBeenCheckedAsRedirectingFactory = true;

    if (_introductory.redirectionTarget != null) {
      _encoding.checkRedirectingFactory(typeEnvironment);
    }
    List<SourceFactoryBuilder>? augmentations = _augmentations;
    if (augmentations != null) {
      for (SourceFactoryBuilder augmentation in augmentations) {
        if (augmentation.redirectionTarget != null) {
          augmentation.checkRedirectingFactories(typeEnvironment);
        }
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
  @override
  Iterable<Annotatable> get annotatables => [_procedure];

  /// Returns `true` if this member is augmented, either by being the origin
  /// of a augmented member or by not being the last among augmentations.
  bool get isAugmented {
    if (isAugmenting) {
      return origin._augmentations!.last != this;
    } else {
      return _augmentations != null;
    }
  }

  // Coverage-ignore(suite): Not run.
  List<DartType>? get _redirectionTypeArguments =>
      _encoding.redirectionTypeArguments;

  // Coverage-ignore(suite): Not run.
  void set _redirectionTypeArguments(List<DartType>? value) {
    _encoding.redirectionTypeArguments = value;
  }

  @override
  void buildOutlineNodes(BuildNodesCallback f) {
    _encoding.buildOutlineNodes(f);
  }

  bool _hasBuiltOutlineExpressions = false;

  @override
  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (_hasBuiltOutlineExpressions) return;
    _hasBuiltOutlineExpressions = true;

    if (_introductory.redirectionTarget != null && isConst && isAugmenting) {
      origin.buildOutlineExpressions(
          classHierarchy, delayedDefaultValueCloners);
    }

    _encoding.buildOutlineExpressions(
        classHierarchy, delayedDefaultValueCloners);

    if (isConst && isAugmenting) {
      _finishAugmentation();
    }
  }

  void _finishAugmentation() {
    finishProcedureAugmentation(_procedure, _encoding.procedure);

    if (_encoding.tearOff != null) {
      finishProcedureAugmentation(_tearOff!, _encoding.tearOff!);
    }

    if (_introductory.redirectionTarget != null) {
      if (origin.redirectionTarget != null) {
        // Coverage-ignore-block(suite): Not run.
        origin._redirectionTypeArguments = _redirectionTypeArguments;
      }
    }
  }

  BodyBuilderContext createBodyBuilderContext() {
    return new FactoryBodyBuilderContext(this, _procedure);
  }

  void resolveRedirectingFactory() {
    _encoding.resolveRedirectingFactory();
  }

  void _setRedirectingFactoryBody(Member target, List<DartType> typeArguments) {
    _encoding.setRedirectingFactoryBody(target, typeArguments);
  }
}

class FactoryBodyBuilderContext extends BodyBuilderContext {
  final SourceFactoryBuilder _member;

  final Member _builtMember;

  FactoryBodyBuilderContext(this._member, this._builtMember)
      : super(_member.libraryBuilder, _member.declarationBuilder,
            isDeclarationInstanceMember: _member.isDeclarationInstanceMember);

  @override
  VariableDeclaration getFormalParameter(int index) {
    return _member.getFormalParameter(index);
  }

  @override
  VariableDeclaration? getTearOffParameter(int index) {
    return _member.getTearOffParameter(index);
  }

  @override
  TypeBuilder get returnType => _member.returnType;

  @override
  // Coverage-ignore(suite): Not run.
  List<FormalParameterBuilder>? get formals => _member.formals;

  @override
  LocalScope computeFormalParameterInitializerScope(LocalScope parent) {
    /// Initializer formals or super parameters cannot occur in getters so
    /// we don't need to create a new scope.
    return parent;
  }

  @override
  FormalParameterBuilder? getFormalParameterByName(Identifier name) {
    return _member.getFormal(name);
  }

  @override
  int get memberNameLength => _member.name.length;

  @override
  FunctionNode get function {
    return _member.function;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isFactory {
    return _member.isFactory;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isNativeMethod {
    return _member.isNative;
  }

  @override
  bool get isExternalFunction {
    return _member.isExternal;
  }

  @override
  bool get isSetter {
    return _member.isSetter;
  }

  @override
  // Coverage-ignore(suite): Not run.
  AugmentSuperTarget? get augmentSuperTarget {
    if (_member.isAugmentation) {
      return _member.augmentSuperTarget;
    }
    return null;
  }

  @override
  int get memberNameOffset => _member.fileOffset;

  @override
  // Coverage-ignore(suite): Not run.
  void registerSuperCall() {
    _builtMember.transformerFlags |= TransformerFlag.superCalls;
  }

  @override
  void registerFunctionBody(Statement body) {
    _member.setBody(body);
  }

  @override
  void setAsyncModifier(AsyncMarker asyncModifier) {
    _member._setAsyncModifier(asyncModifier);
  }

  @override
  bool get isRedirectingFactory => _member.redirectionTarget != null;

  @override
  DartType get returnTypeContext {
    return _member.function.returnType;
  }

  @override
  String get redirectingFactoryTargetName {
    return _member.redirectionTarget!.fullNameForErrors;
  }
}

class _FactoryEncoding implements InferredTypeListener {
  late final Procedure _procedureInternal;
  late final Procedure? _factoryTearOff;

  final FactoryFragment _fragment;

  AsyncMarker _asyncModifier;

  final List<NominalParameterBuilder>? typeParameters;

  final TypeBuilder returnType;

  DelayedDefaultValueCloner? _delayedDefaultValueCloner;

  List<DartType>? _redirectionTypeArguments;

  FreshTypeParameters? _tearOffTypeParameters;

  _FactoryEncoding(this._fragment,
      {required String name,
      required SourceLibraryBuilder libraryBuilder,
      required this.typeParameters,
      required this.returnType,
      required NameScheme nameScheme,
      required Reference? procedureReference,
      required Reference? tearOffReference})
      : _asyncModifier = _fragment.redirectionTarget != null
            ? AsyncMarker.Sync
            : _fragment.asyncModifier {
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
    assert(_fragment.redirectionTarget != null);
    return _redirectionTypeArguments;
  }

  void set redirectionTypeArguments(List<DartType>? value) {
    assert(_fragment.redirectionTarget != null);
    _redirectionTypeArguments = value;
  }

  void buildOutlineNodes(BuildNodesCallback f) {
    _procedureInternal.function.asyncMarker = _asyncModifier;
    if (_fragment.redirectionTarget == null &&
        !_fragment.modifiers.isAbstract &&
        !_fragment.modifiers.isExternal) {
      _procedureInternal.function.body = new EmptyStatement()
        ..parent = _procedureInternal.function;
    }
    buildTypeParametersAndFormals(_fragment.builder.libraryBuilder,
        _procedureInternal.function, typeParameters, _fragment.formals,
        classTypeParameters: null, supportsTypeParameters: true);
    if (returnType is! InferableTypeBuilder) {
      _procedureInternal.function.returnType = returnType.build(
          _fragment.builder.libraryBuilder, TypeUse.returnType);
    }
    _procedureInternal.function.fileOffset = _fragment.formalsOffset;
    _procedureInternal.function.fileEndOffset =
        _procedureInternal.fileEndOffset;
    _procedureInternal.isAbstract = _fragment.modifiers.isAbstract;
    _procedureInternal.isExternal = _fragment.modifiers.isExternal;
    _procedureInternal.isConst = _fragment.modifiers.isConst;
    _procedureInternal.isStatic = _fragment.modifiers.isStatic;

    if (_fragment.redirectionTarget != null) {
      if (_fragment.redirectionTarget!.typeArguments != null) {
        redirectionTypeArguments = new List<DartType>.generate(
            _fragment.redirectionTarget!.typeArguments!.length,
            (int i) => _fragment.redirectionTarget!.typeArguments![i].build(
                _fragment.builder.libraryBuilder,
                TypeUse.redirectionTypeArgument),
            growable: false);
      }
      if (_factoryTearOff != null) {
        _tearOffTypeParameters =
            buildRedirectingFactoryTearOffProcedureParameters(
                tearOff: _factoryTearOff,
                implementationConstructor: _procedureInternal,
                libraryBuilder: _fragment.builder.libraryBuilder);
      }
    } else {
      if (_factoryTearOff != null) {
        _delayedDefaultValueCloner = buildConstructorTearOffProcedure(
            tearOff: _factoryTearOff,
            declarationConstructor: _fragment.builder._procedure,
            implementationConstructor: _procedureInternal,
            libraryBuilder: _fragment.builder.libraryBuilder);
      }
    }
    f(
        member: _procedureInternal,
        tearOff: _factoryTearOff,
        kind: _fragment.builder.isExtensionTypeMember
            ? (_fragment.redirectionTarget != null
                ? BuiltMemberKind.ExtensionTypeRedirectingFactory
                : BuiltMemberKind.ExtensionTypeFactory)
            : (_fragment.redirectionTarget != null
                ? BuiltMemberKind.RedirectingFactory
                : BuiltMemberKind.Factory));
  }

  // TODO(johnniwinther): Remove this.
  LookupScope _computeTypeParameterScope(LookupScope parent) {
    if (typeParameters == null) return parent;
    Map<String, Builder> local = <String, Builder>{};
    for (NominalParameterBuilder variable in typeParameters!) {
      if (variable.isWildcard) continue;
      local[variable.name] = variable;
    }
    return new TypeParameterScope(parent, local);
  }

  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    _fragment.formals?.infer(classHierarchy);

    if (_delayedDefaultValueCloner != null) {
      delayedDefaultValueCloners.add(_delayedDefaultValueCloner!);
    }

    LookupScope parentScope = _fragment.builder.declarationBuilder.scope;
    for (Annotatable annotatable in _fragment.builder.annotatables) {
      MetadataBuilder.buildAnnotations(
          annotatable,
          _fragment.metadata,
          _fragment.builder.createBodyBuilderContext(),
          _fragment.builder.libraryBuilder,
          _fragment.fileUri,
          parentScope,
          createFileUriExpression: _fragment.builder.isAugmented);
    }
    if (typeParameters != null) {
      for (int i = 0; i < typeParameters!.length; i++) {
        typeParameters![i].buildOutlineExpressions(
            _fragment.builder.libraryBuilder,
            _fragment.builder.createBodyBuilderContext(),
            classHierarchy,
            _computeTypeParameterScope(parentScope));
      }
    }

    if (_fragment.formals != null) {
      // For const constructors we need to include default parameter values
      // into the outline. For all other formals we need to call
      // buildOutlineExpressions to clear initializerToken to prevent
      // consuming too much memory.
      for (FormalParameterBuilder formal in _fragment.formals!) {
        formal.buildOutlineExpressions(_fragment.builder.libraryBuilder,
            _fragment.builder.declarationBuilder,
            buildDefaultValue: FormalParameterBuilder
                .needsDefaultValuesBuiltAsOutlineExpressions(
                    _fragment.builder));
      }
    }

    if (_fragment.redirectionTarget == null) {
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
      TypeInferrer inferrer = _fragment
          .builder.libraryBuilder.loader.typeInferenceEngine
          .createLocalTypeInferrer(
              _fragment.fileUri,
              _fragment.builder.declarationBuilder.thisType,
              _fragment.builder.libraryBuilder,
              null);
      InferenceHelper helper = _fragment.builder.libraryBuilder.loader
          .createBodyBuilderForOutlineExpression(
              _fragment.builder.libraryBuilder,
              _fragment.builder.createBodyBuilderContext(),
              _fragment.builder.declarationBuilder.scope,
              _fragment.fileUri);
      Builder? targetBuilder = _fragment.redirectionTarget!.target;

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
          _fragment.builder._procedure.function,
          _fragment.fullNameOffset,
          target,
          target.function!.computeFunctionType(Nullability.nonNullable));
      if (typeArguments == null) {
        assert(_fragment.builder.libraryBuilder.loader
            .assertProblemReportedElsewhere(
                "RedirectingFactoryTarget.buildOutlineExpressions",
                expectedPhase: CompilationPhaseForProblemReporting.outline));
        // Use 'dynamic' for recovery.
        typeArguments = new List<DartType>.filled(
            _fragment.builder.declarationBuilder.typeParametersCount,
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
            _fragment.builder.libraryBuilder));
      }
      delayedDefaultValueCloners.add(new DelayedDefaultValueCloner(
          target!, _fragment.builder._procedure,
          libraryBuilder: _fragment.builder.libraryBuilder,
          identicalSignatures: false));
    }
  }

  void resolveRedirectingFactory() {
    ConstructorReferenceBuilder? redirectionTarget =
        _fragment.redirectionTarget;
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
            _fragment.builder.libraryBuilder.addProblem(
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
            templateDuplicatedDeclarationUse
                .withArguments(redirectionTarget.fullNameForErrors),
            redirectionTarget.charOffset,
            noLength,
            redirectionTarget.fileUri);
      } else {
        _addProblemForRedirectingFactory(
            templateRedirectionTargetNotFound
                .withArguments(redirectionTarget.fullNameForErrors),
            redirectionTarget.charOffset,
            noLength,
            redirectionTarget.fileUri);
      }
      if (targetNode != null &&
          targetNode is Constructor &&
          targetNode.enclosingClass.isAbstract) {
        _addProblemForRedirectingFactory(
            templateAbstractRedirectedClassInstantiation
                .withArguments(redirectionTarget.fullNameForErrors),
            redirectionTarget.charOffset,
            noLength,
            redirectionTarget.fileUri);
        targetNode = null;
      }
      if (targetNode != null &&
          targetNode is Constructor &&
          targetNode.enclosingClass.isEnum) {
        _addProblemForRedirectingFactory(
            messageEnumFactoryRedirectsToConstructor,
            redirectionTarget.charOffset,
            noLength,
            redirectionTarget.fileUri);
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
        setRedirectingFactoryBody(targetNode, typeArguments);
      }
    }
  }

  void setRedirectingFactoryBody(Member target, List<DartType> typeArguments) {
    if (_procedureInternal.function.body != null) {
      unexpected("null", "${_procedureInternal.function.body.runtimeType}",
          _fragment.fullNameOffset, _fragment.fileUri);
    }

    // Ensure that constant factories only have constant targets/bodies.
    if (_fragment.modifiers.isConst && !target.isConst) {
      // Coverage-ignore-block(suite): Not run.
      _fragment.builder.libraryBuilder.addProblem(
          messageConstFactoryRedirectionToNonConst,
          _fragment.fullNameOffset,
          noLength,
          _fragment.fileUri);
    }

    _procedureInternal.function.body = createRedirectingFactoryBody(
        target, typeArguments, _procedureInternal.function)
      ..parent = _procedureInternal.function;
    _procedureInternal.function.redirectingFactoryTarget =
        new RedirectingFactoryTarget(target, typeArguments);
    if (_fragment.builder.isAugmenting) {
      if (_procedureInternal.function.typeParameters.isNotEmpty) {
        Map<TypeParameter, DartType> substitution = <TypeParameter, DartType>{};
        for (int i = 0;
            i < _procedureInternal.function.typeParameters.length;
            i++) {
          substitution[_procedureInternal.function.typeParameters[i]] =
              new TypeParameterType.withDefaultNullability(
                  _fragment.builder.origin.function.typeParameters[i]);
        }
        typeArguments = new List<DartType>.generate(typeArguments.length,
            (int i) => substitute(typeArguments[i], substitution),
            growable: false);
      }
      _fragment.builder.origin
          ._setRedirectingFactoryBody(target, typeArguments);
    }
  }

  void _addProblemForRedirectingFactory(
      Message message, int charOffset, int length, Uri fileUri) {
    _fragment.builder.libraryBuilder
        .addProblem(message, charOffset, length, fileUri);
    String text = _fragment.builder.libraryBuilder.loader.target.context
        .format(
            message.withLocation(fileUri, charOffset, length), Severity.error)
        .plain;
    _setRedirectingFactoryError(text);
  }

  void _setRedirectingFactoryError(String message) {
    assert(_fragment.redirectionTarget != null);

    setBody(createRedirectingFactoryErrorBody(message));
    _fragment.builder._procedure.function.redirectingFactoryTarget =
        new RedirectingFactoryTarget.error(message);
    if (_factoryTearOff != null) {
      _factoryTearOff.function.body = createRedirectingFactoryErrorBody(message)
        ..parent = _factoryTearOff.function;
    }
  }

  /// Checks this factory builder if it is for a redirecting factory.
  void checkRedirectingFactory(TypeEnvironment typeEnvironment) {
    assert(_fragment.redirectionTarget != null);

    // Check that factory declaration is not cyclic.
    if (_isCyclicRedirectingFactory(_fragment.builder)) {
      _addProblemForRedirectingFactory(
          templateCyclicRedirectingFactoryConstructors
              .withArguments("${_fragment.builder.declarationBuilder.name}"
                  "${_fragment.name == '' ? '' : '.${_fragment.name}'}"),
          _fragment.fullNameOffset,
          noLength,
          _fragment.fileUri);
      return;
    }

    // The factory type cannot contain any type parameters other than those of
    // its enclosing class, because constructors cannot specify type parameters
    // of their own.
    FunctionType factoryType = _procedureInternal.function
        .computeThisFunctionType(Nullability.nonNullable);
    if (_fragment.builder.isAugmenting) {
      // The redirection target type uses the origin type parameters so we must
      // substitute augmentation type parameters before checking subtyping.
      if (_procedureInternal.function.typeParameters.isNotEmpty) {
        Map<TypeParameter, DartType> substitution = <TypeParameter, DartType>{};
        for (int i = 0;
            i < _procedureInternal.function.typeParameters.length;
            i++) {
          substitution[_procedureInternal.function.typeParameters[i]] =
              new TypeParameterType.withDefaultNullability(
                  _fragment.builder.origin.function.typeParameters[i]);
        }
        factoryType = substitute(factoryType, substitution) as FunctionType;
      }
    }
    FunctionType? redirecteeType = _computeRedirecteeType(typeEnvironment);
    Map<TypeParameter, DartType> substitutionMap = {};
    for (int i = 0; i < factoryType.typeParameters.length; i++) {
      TypeParameter functionTypeParameter =
          _fragment.builder.origin.function.typeParameters[i];
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

    Builder? redirectionTargetBuilder = _fragment.redirectionTarget!.target;
    if (redirectionTargetBuilder is SourceFactoryBuilder &&
        redirectionTargetBuilder.redirectionTarget != null) {
      redirectionTargetBuilder.checkRedirectingFactories(typeEnvironment);
      String? errorMessage = redirectionTargetBuilder
          .function.redirectingFactoryTarget?.errorMessage;
      if (errorMessage != null) {
        _setRedirectingFactoryError(errorMessage);
      }
    }

    Builder? redirectionTargetParent =
        _fragment.redirectionTarget!.target?.parent;
    bool redirectingTargetParentIsEnum = redirectionTargetParent is ClassBuilder
        ? redirectionTargetParent.isEnum
        : false;
    if (!((_fragment.builder.classBuilder?.cls.isEnum ?? false) &&
        (_fragment.redirectionTarget!.target?.isConstructor ?? false) &&
        redirectingTargetParentIsEnum)) {
      // Check whether [redirecteeType] <: [factoryType].
      FunctionType factoryTypeWithoutTypeParameters =
          factoryType.withoutTypeParameters;
      if (!typeEnvironment.isSubtypeOf(
          redirecteeType,
          factoryTypeWithoutTypeParameters,
          SubtypeCheckMode.withNullabilities)) {
        _addProblemForRedirectingFactory(
            templateIncompatibleRedirecteeFunctionType.withArguments(
                redirecteeType, factoryTypeWithoutTypeParameters),
            _fragment.redirectionTarget!.charOffset,
            noLength,
            _fragment.redirectionTarget!.fileUri);
      }
    } else {
      // Redirection to generative enum constructors is forbidden.
      assert(_fragment.builder.libraryBuilder.loader
          .assertProblemReportedElsewhere(
              "RedirectingFactoryBuilder._checkRedirectingFactory: "
              "Redirection to generative enum constructor.",
              expectedPhase: CompilationPhaseForProblemReporting.bodyBuilding));
    }
  }

  // Computes the function type of a given redirection target. Returns [null] if
  // the type of the target could not be computed.
  FunctionType? _computeRedirecteeType(TypeEnvironment typeEnvironment) {
    assert(_fragment.redirectionTarget != null);
    ConstructorReferenceBuilder redirectionTarget =
        _fragment.redirectionTarget!;
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

    List<DartType>? typeArguments = _getRedirectionTypeArguments();
    FunctionType targetFunctionType =
        targetNode.computeFunctionType(Nullability.nonNullable);
    if (typeArguments != null &&
        targetFunctionType.typeParameters.length != typeArguments.length) {
      _addProblemForRedirectingFactory(
          templateTypeArgumentMismatch
              .withArguments(targetFunctionType.typeParameters.length),
          redirectionTarget.charOffset,
          noLength,
          redirectionTarget.fileUri);
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
              templateRedirectingFactoryIncompatibleTypeArgument.withArguments(
                  typeArgument, typeParameterBound),
              redirectionTarget.charOffset,
              noLength,
              redirectionTarget.fileUri);
          hasProblem = true;
        } else {
          if (!typeEnvironment.isSubtypeOf(typeArgument, typeParameterBound,
              SubtypeCheckMode.withNullabilities)) {
            _addProblemForRedirectingFactory(
                templateRedirectingFactoryIncompatibleTypeArgument
                    .withArguments(typeArgument, typeParameterBound),
                redirectionTarget.charOffset,
                noLength,
                redirectionTarget.fileUri);
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

  List<DartType>? _getRedirectionTypeArguments() {
    assert(_fragment.redirectionTarget != null);
    return _fragment
        .builder._procedure.function.redirectingFactoryTarget!.typeArguments;
  }

  void setBody(Statement value) {
    _procedureInternal.function.body = value
      ..parent = _procedureInternal.function;
  }

  void becomeNative(SourceLoader loader) {
    for (Annotatable annotatable in _fragment.builder.annotatables) {
      loader.addNativeAnnotation(annotatable, _fragment.nativeMethodName!);
    }
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

  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    int count = context.computeDefaultTypesForVariables(typeParameters,
        // Type parameters are inherited from the enclosing declaration, so if
        // it has issues, so do the constructors.
        inErrorRecovery: inErrorRecovery);
    context.reportGenericFunctionTypesForFormals(_fragment.formals);
    return count;
  }

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
}
