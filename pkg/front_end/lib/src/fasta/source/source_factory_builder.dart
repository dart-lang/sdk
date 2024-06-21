// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../builder/builder.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/function_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/type_builder.dart';
import '../../codes/cfe_codes.dart';
import '../dill/dill_extension_type_member_builder.dart';
import '../dill/dill_member_builder.dart';
import '../identifiers.dart';
import '../kernel/body_builder_context.dart';
import '../kernel/constructor_tearoff_lowering.dart';
import '../kernel/hierarchy/class_member.dart';
import '../kernel/kernel_helper.dart';
import '../messages.dart'
    show
        messageConstFactoryRedirectionToNonConst,
        noLength,
        templateCyclicRedirectingFactoryConstructors,
        templateIncompatibleRedirecteeFunctionType,
        templateRedirectingFactoryIncompatibleTypeArgument,
        templateTypeArgumentMismatch;
import '../problems.dart' show unexpected, unhandled;
import '../scope.dart';
import '../type_inference/inference_helper.dart';
import '../type_inference/type_inferrer.dart';
import '../type_inference/type_schema.dart';
import '../util/helpers.dart';
import 'name_scheme.dart';
import 'redirecting_factory_body.dart';
import 'source_class_builder.dart';
import 'source_function_builder.dart';
import 'source_library_builder.dart' show SourceLibraryBuilder;
import 'source_loader.dart' show SourceLoader;
import 'source_member_builder.dart';

class SourceFactoryBuilder extends SourceFunctionBuilderImpl {
  final int charOpenParenOffset;

  AsyncMarker actualAsyncModifier = AsyncMarker.Sync;

  @override
  final bool isExtensionInstanceMember = false;

  @override
  final TypeBuilder returnType;

  late final Procedure _procedureInternal;
  late final Procedure? _factoryTearOff;

  SourceFactoryBuilder? actualOrigin;

  List<SourceFactoryBuilder>? _augmentations;

  final MemberName _memberName;

  DelayedDefaultValueCloner? _delayedDefaultValueCloner;

  SourceFactoryBuilder(
      List<MetadataBuilder>? metadata,
      int modifiers,
      this.returnType,
      String name,
      List<NominalVariableBuilder> typeVariables,
      List<FormalParameterBuilder>? formals,
      SourceLibraryBuilder libraryBuilder,
      int startCharOffset,
      int charOffset,
      this.charOpenParenOffset,
      int charEndOffset,
      Reference? procedureReference,
      Reference? tearOffReference,
      AsyncMarker asyncModifier,
      NameScheme nameScheme,
      {String? nativeMethodName})
      : _memberName = nameScheme.getDeclaredName(name),
        super(metadata, modifiers, name, typeVariables, formals, libraryBuilder,
            charOffset, nativeMethodName) {
    _procedureInternal = new Procedure(
        dummyName,
        nameScheme.isExtensionTypeMember
            ? ProcedureKind.Method
            : ProcedureKind.Factory,
        new FunctionNode(null),
        fileUri: libraryBuilder.fileUri,
        reference: procedureReference)
      ..fileStartOffset = startCharOffset
      ..fileOffset = charOffset
      ..fileEndOffset = charEndOffset
      ..isExtensionTypeMember = nameScheme.isExtensionTypeMember;
    nameScheme
        .getConstructorMemberName(name, isTearOff: false)
        .attachMember(_procedureInternal);
    _factoryTearOff = createFactoryTearOffProcedure(
        nameScheme.getConstructorMemberName(name, isTearOff: true),
        libraryBuilder,
        libraryBuilder.fileUri,
        charOffset,
        tearOffReference,
        forceCreateLowering: nameScheme.isExtensionTypeMember)
      ?..isExtensionTypeMember = nameScheme.isExtensionTypeMember;
    this.asyncModifier = asyncModifier;
  }

  @override
  Name get memberName => _memberName.name;

  @override
  DeclarationBuilder get declarationBuilder => super.declarationBuilder!;

  List<SourceFactoryBuilder>? get augmentationsForTesting => _augmentations;

  @override
  AsyncMarker get asyncModifier => actualAsyncModifier;

  @override
  Statement? get body {
    if (bodyInternal == null && !isAbstract && !isExternal) {
      bodyInternal = new EmptyStatement();
    }
    return bodyInternal;
  }

  void set asyncModifier(AsyncMarker newModifier) {
    actualAsyncModifier = newModifier;
    function.asyncMarker = actualAsyncModifier;
    function.dartAsyncMarker = actualAsyncModifier;
  }

  @override
  Member get member => _procedure;

  @override
  SourceFactoryBuilder get origin => actualOrigin ?? this;

  @override
  ProcedureKind get kind => ProcedureKind.Factory;

  Procedure get _procedure =>
      isAugmenting ? origin._procedure : _procedureInternal;

  @override
  FunctionNode get function => _procedureInternal.function;

  @override
  Member? get readTarget => origin._factoryTearOff ?? _procedure;

  @override
  Member? get writeTarget => null;

  @override
  Member? get invokeTarget => _procedure;

  @override
  Iterable<Member> get exportedMembers => [_procedure];

  @override
  void buildOutlineNodes(BuildNodesCallback f) {
    _build();
    f(
        member: _procedureInternal,
        tearOff: _factoryTearOff,
        kind: isExtensionTypeMember
            ? BuiltMemberKind.ExtensionTypeFactory
            : BuiltMemberKind.Factory);
  }

  void _build() {
    buildFunction();
    _procedureInternal.function.fileOffset = charOpenParenOffset;
    _procedureInternal.function.fileEndOffset =
        _procedureInternal.fileEndOffset;
    _procedureInternal.isAbstract = isAbstract;
    _procedureInternal.isExternal = isExternal;
    _procedureInternal.isConst = isConst;
    _procedureInternal.isStatic = isStatic;

    if (_factoryTearOff != null) {
      _delayedDefaultValueCloner = buildConstructorTearOffProcedure(
          tearOff: _factoryTearOff,
          declarationConstructor: _procedure,
          implementationConstructor: _procedureInternal,
          libraryBuilder: libraryBuilder);
    }
  }

  bool _hasBuiltOutlines = false;

  @override
  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (_hasBuiltOutlines) return;
    if (_delayedDefaultValueCloner != null) {
      delayedDefaultValueCloners.add(_delayedDefaultValueCloner!);
    }
    super.buildOutlineExpressions(
        classHierarchy, delayedActionPerformers, delayedDefaultValueCloners);
    _hasBuiltOutlines = true;
  }

  @override
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

  @override
  List<ClassMember> get localMembers =>
      throw new UnsupportedError('${runtimeType}.localMembers');

  @override
  List<ClassMember> get localSetters =>
      throw new UnsupportedError('${runtimeType}.localSetters');

  @override
  void becomeNative(SourceLoader loader) {
    _procedureInternal.isExternal = true;
    super.becomeNative(loader);
  }

  void setRedirectingFactoryBody(Member target, List<DartType> typeArguments) {
    if (bodyInternal != null) {
      unexpected("null", "${bodyInternal.runtimeType}", charOffset, fileUri);
    }
    bodyInternal =
        createRedirectingFactoryBody(target, typeArguments, function);
    _procedureInternal.function.body = bodyInternal;
    _procedureInternal.function.redirectingFactoryTarget =
        new RedirectingFactoryTarget(target, typeArguments);
    bodyInternal?.parent = function;
    if (isAugmenting) {
      actualOrigin!.setRedirectingFactoryBody(target, typeArguments);
    }
  }

  @override
  void applyAugmentation(Builder augmentation) {
    if (augmentation is SourceFactoryBuilder) {
      if (checkAugmentation(augmentation)) {
        augmentation.actualOrigin = this;
        (_augmentations ??= []).add(augmentation);
      }
    } else {
      reportAugmentationMismatch(augmentation);
    }
  }

  void _finishAugmentation() {
    finishProcedureAugmentation(origin._procedure, _procedureInternal);

    if (_factoryTearOff != null) {
      finishProcedureAugmentation(origin._factoryTearOff!, _factoryTearOff);
    }
  }

  @override
  int buildBodyNodes(BuildNodesCallback f) {
    if (!isAugmenting) return 0;
    _finishAugmentation();
    return 1;
  }

  @override
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {}

  @override
  void checkTypes(
      SourceLibraryBuilder library, TypeEnvironment typeEnvironment) {
    library.checkTypesInFunctionBuilder(this, typeEnvironment);
    List<SourceFactoryBuilder>? augmentations = _augmentations;
    if (augmentations != null) {
      for (SourceFactoryBuilder augmentation in augmentations) {
        augmentation.checkTypes(library, typeEnvironment);
      }
    }
  }

  /// Checks the redirecting factories of this factory builder and its
  /// augmentations.
  void checkRedirectingFactories(TypeEnvironment typeEnvironment) {
    _checkRedirectingFactory(typeEnvironment);
    List<SourceFactoryBuilder>? augmentations = _augmentations;
    if (augmentations != null) {
      for (SourceFactoryBuilder augmentation in augmentations) {
        augmentation._checkRedirectingFactory(typeEnvironment);
      }
    }
  }

  /// Checks this factory builder if it is for a redirecting factory.
  void _checkRedirectingFactory(TypeEnvironment typeEnvironment) {}

  @override
  BodyBuilderContext createBodyBuilderContext(
      {required bool inOutlineBuildingPhase,
      required bool inMetadata,
      required bool inConstFields}) {
    return new FactoryBodyBuilderContext(this,
        inOutlineBuildingPhase: inOutlineBuildingPhase,
        inMetadata: inMetadata,
        inConstFields: inConstFields);
  }

  @override
  String get fullNameForErrors {
    return "${flattenName(declarationBuilder.name, charOffset, fileUri)}"
        "${name.isEmpty ? '' : '.$name'}";
  }

  // TODO(johnniwinther): Add annotations to tear-offs.
  @override
  Iterable<Annotatable> get annotatables => [_procedure];

  @override
  bool get isAugmented {
    if (isAugmenting) {
      return origin._augmentations!.last != this;
    } else {
      return _augmentations != null;
    }
  }
}

class RedirectingFactoryBuilder extends SourceFactoryBuilder {
  final ConstructorReferenceBuilder redirectionTarget;
  List<DartType>? typeArguments;

  FreshTypeParameters? _tearOffTypeParameters;

  bool _hasBeenCheckedAsRedirectingFactory = false;

  RedirectingFactoryBuilder(
      List<MetadataBuilder>? metadata,
      int modifiers,
      TypeBuilder returnType,
      String name,
      List<NominalVariableBuilder> typeVariables,
      List<FormalParameterBuilder>? formals,
      SourceLibraryBuilder libraryBuilder,
      int startCharOffset,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      Reference? procedureReference,
      Reference? tearOffReference,
      NameScheme nameScheme,
      String? nativeMethodName,
      this.redirectionTarget)
      : super(
            metadata,
            modifiers,
            returnType,
            name,
            typeVariables,
            formals,
            libraryBuilder,
            startCharOffset,
            charOffset,
            charOpenParenOffset,
            charEndOffset,
            procedureReference,
            tearOffReference,
            AsyncMarker.Sync,
            nameScheme,
            nativeMethodName: nativeMethodName);

  @override
  Statement? get body => bodyInternal;

  @override
  void setRedirectingFactoryBody(Member target, List<DartType> typeArguments) {
    if (bodyInternal != null) {
      unexpected("null", "${bodyInternal.runtimeType}", charOffset, fileUri);
    }

    // Ensure that constant factories only have constant targets/bodies.
    if (isConst && !target.isConst) {
      libraryBuilder.addProblem(messageConstFactoryRedirectionToNonConst,
          charOffset, noLength, fileUri);
    }

    bodyInternal =
        createRedirectingFactoryBody(target, typeArguments, function);
    _procedureInternal.function.body = bodyInternal;
    _procedureInternal.function.redirectingFactoryTarget =
        new RedirectingFactoryTarget(target, typeArguments);
    bodyInternal?.parent = function;
    if (isAugmenting) {
      if (function.typeParameters.isNotEmpty) {
        Map<TypeParameter, DartType> substitution = <TypeParameter, DartType>{};
        for (int i = 0; i < function.typeParameters.length; i++) {
          substitution[function.typeParameters[i]] =
              new TypeParameterType.withDefaultNullabilityForLibrary(
                  actualOrigin!.function.typeParameters[i],
                  libraryBuilder.library);
        }
        typeArguments = new List<DartType>.generate(typeArguments.length,
            (int i) => substitute(typeArguments[i], substitution),
            growable: false);
      }
      actualOrigin!.setRedirectingFactoryBody(target, typeArguments);
    }
  }

  void setRedirectingFactoryError(String message) {
    body = createRedirectingFactoryErrorBody(message);
    _procedure.function.redirectingFactoryTarget =
        new RedirectingFactoryTarget.error(message);
    if (_factoryTearOff != null) {
      _factoryTearOff.function.body = createRedirectingFactoryErrorBody(message)
        ..parent = _factoryTearOff.function;
    }
  }

  @override
  void buildOutlineNodes(BuildNodesCallback f) {
    _build();
    f(
        member: _procedureInternal,
        tearOff: _factoryTearOff,
        kind: isExtensionTypeMember
            ? BuiltMemberKind.ExtensionTypeRedirectingFactory
            : BuiltMemberKind.RedirectingFactory);
  }

  @override
  void _build() {
    buildFunction();
    _procedureInternal.function.fileOffset = charOpenParenOffset;
    _procedureInternal.function.fileEndOffset =
        _procedureInternal.fileEndOffset;
    _procedureInternal.isAbstract = isAbstract;
    _procedureInternal.isExternal = isExternal;
    _procedureInternal.isConst = isConst;
    _procedureInternal.isStatic = isStatic;
    if (redirectionTarget.typeArguments != null) {
      typeArguments = new List<DartType>.generate(
          redirectionTarget.typeArguments!.length,
          (int i) => redirectionTarget.typeArguments![i]
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
  }

  @override
  bool _hasBuiltOutlines = false;

  @override
  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (_hasBuiltOutlines) return;
    if (isConst && isAugmenting) {
      origin.buildOutlineExpressions(
          classHierarchy, delayedActionPerformers, delayedDefaultValueCloners);
    }
    super.buildOutlineExpressions(
        classHierarchy, delayedActionPerformers, delayedDefaultValueCloners);

    RedirectingFactoryTarget redirectingFactoryTarget =
        _procedureInternal.function.redirectingFactoryTarget!;
    List<DartType>? typeArguments = redirectingFactoryTarget.typeArguments;
    Member? target = redirectingFactoryTarget.target;
    if (typeArguments != null && typeArguments.any((t) => t is UnknownType)) {
      TypeInferrer inferrer = libraryBuilder.loader.typeInferenceEngine
          .createLocalTypeInferrer(
              fileUri, declarationBuilder.thisType, libraryBuilder, null);
      InferenceHelper helper = libraryBuilder.loader
          .createBodyBuilderForOutlineExpression(
              libraryBuilder,
              createBodyBuilderContext(
                  inOutlineBuildingPhase: true,
                  inMetadata: false,
                  inConstFields: false),
              declarationBuilder.scope,
              fileUri);
      Builder? targetBuilder = redirectionTarget.target;
      if (targetBuilder is SourceMemberBuilder) {
        // Ensure that target has been built.
        targetBuilder.buildOutlineExpressions(classHierarchy,
            delayedActionPerformers, delayedDefaultValueCloners);
      }
      if (targetBuilder is FunctionBuilder) {
        target = targetBuilder.member;
      } else if (targetBuilder is DillMemberBuilder) {
        target = targetBuilder.member;
      } else {
        unhandled("${targetBuilder.runtimeType}", "buildOutlineExpressions",
            charOffset, fileUri);
      }
      typeArguments = inferrer.inferRedirectingFactoryTypeArguments(
          helper,
          _procedureInternal.function.returnType,
          _procedure.function,
          charOffset,
          target,
          target.function!.computeFunctionType(Nullability.nonNullable));
      if (typeArguments == null) {
        // Assume that the error is reported elsewhere, use 'dynamic' for
        // recovery.
        typeArguments = new List<DartType>.filled(
            declarationBuilder.typeVariablesCount, const DynamicType(),
            growable: true);
      }

      _procedureInternal.function.body =
          createRedirectingFactoryBody(target, typeArguments, function);
      assert(function == _procedureInternal.function);
      _procedureInternal.function.body!.parent = function;
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
        typeArguments = redirectingFactoryTarget.typeArguments;
      }
      target = redirectingFactoryTarget.target;
    }

    if (target is Constructor ||
        target is Procedure &&
            (target.isFactory || target.isExtensionTypeMember)) {
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
          target!, _procedure,
          libraryBuilder: libraryBuilder, identicalSignatures: false));
    }
    if (isConst && isAugmenting) {
      _finishAugmentation();
    }
    _hasBuiltOutlines = true;
  }

  @override
  void _finishAugmentation() {
    super._finishAugmentation();

    SourceFactoryBuilder redirectingOrigin = origin;
    if (redirectingOrigin is RedirectingFactoryBuilder) {
      redirectingOrigin.typeArguments = typeArguments;
    }
  }

  List<DartType>? getTypeArguments() {
    return _procedure.function.redirectingFactoryTarget!.typeArguments;
  }

  @override
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {}

  @override
  void checkTypes(
      SourceLibraryBuilder library, TypeEnvironment typeEnvironment) {
    library.checkTypesInRedirectingFactoryBuilder(this, typeEnvironment);
  }

  // Computes the function type of a given redirection target. Returns [null] if
  // the type of the target could not be computed.
  FunctionType? _computeRedirecteeType(
      RedirectingFactoryBuilder factory, TypeEnvironment typeEnvironment) {
    ConstructorReferenceBuilder redirectionTarget = factory.redirectionTarget;
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
          charOffset, fileUri);
    }

    List<DartType>? typeArguments = factory.getTypeArguments();
    FunctionType targetFunctionType =
        targetNode.computeFunctionType(Nullability.nonNullable);
    if (typeArguments != null &&
        targetFunctionType.typeParameters.length != typeArguments.length) {
      libraryBuilder.addProblemForRedirectingFactory(
          factory,
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
          libraryBuilder.addProblemForRedirectingFactory(
              factory,
              templateRedirectingFactoryIncompatibleTypeArgument.withArguments(
                  typeArgument, typeParameterBound),
              redirectionTarget.charOffset,
              noLength,
              redirectionTarget.fileUri);
          hasProblem = true;
        } else {
          if (!typeEnvironment.isSubtypeOf(typeArgument, typeParameterBound,
              SubtypeCheckMode.withNullabilities)) {
            libraryBuilder.addProblemForRedirectingFactory(
                factory,
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

  bool _isCyclicRedirectingFactory(RedirectingFactoryBuilder factory) {
    // We use the [tortoise and hare algorithm]
    // (https://en.wikipedia.org/wiki/Cycle_detection#Tortoise_and_hare) to
    // handle cycles.
    Builder? tortoise = factory;
    Builder? hare = factory.redirectionTarget.target;
    if (hare == factory) {
      return true;
    }
    while (tortoise != hare) {
      // Hare moves 2 steps forward.
      if (hare is! RedirectingFactoryBuilder) {
        return false;
      }
      hare = hare.redirectionTarget.target;
      if (hare == factory) {
        return true;
      }
      if (hare is! RedirectingFactoryBuilder) {
        return false;
      }
      hare = hare.redirectionTarget.target;
      if (hare == factory) {
        return true;
      }
      // Tortoise moves one step forward. No need to test type of tortoise
      // as it follows hare which already checked types.
      tortoise =
          (tortoise as RedirectingFactoryBuilder).redirectionTarget.target;
    }
    // Cycle found, but original factory doesn't belong to a cycle.
    return false;
  }

  @override
  void _checkRedirectingFactory(TypeEnvironment typeEnvironment) {
    if (_hasBeenCheckedAsRedirectingFactory) return;
    _hasBeenCheckedAsRedirectingFactory = true;

    // Check that factory declaration is not cyclic.
    if (_isCyclicRedirectingFactory(this)) {
      libraryBuilder.addProblemForRedirectingFactory(
          this,
          templateCyclicRedirectingFactoryConstructors
              .withArguments("${declarationBuilder.name}"
                  "${name == '' ? '' : '.${name}'}"),
          charOffset,
          noLength,
          fileUri);
      return;
    }

    // The factory type cannot contain any type parameters other than those of
    // its enclosing class, because constructors cannot specify type parameters
    // of their own.
    FunctionType factoryType =
        function.computeThisFunctionType(Nullability.nonNullable);
    if (isAugmenting) {
      // The redirection target type uses the origin type parameters so we must
      // substitute augmentation type parameters before checking subtyping.
      if (function.typeParameters.isNotEmpty) {
        Map<TypeParameter, DartType> substitution = <TypeParameter, DartType>{};
        for (int i = 0; i < function.typeParameters.length; i++) {
          substitution[function.typeParameters[i]] =
              new TypeParameterType.withDefaultNullabilityForLibrary(
                  actualOrigin!.function.typeParameters[i],
                  libraryBuilder.library);
        }
        factoryType = substitute(factoryType, substitution) as FunctionType;
      }
    }
    FunctionType? redirecteeType =
        _computeRedirecteeType(this, typeEnvironment);
    Map<TypeParameter, DartType> substitutionMap = {};
    for (int i = 0; i < factoryType.typeParameters.length; i++) {
      TypeParameter functionTypeParameter = origin.function.typeParameters[i];
      substitutionMap[functionTypeParameter] =
          new StructuralParameterType.forAlphaRenamingFromTypeParameters(
              functionTypeParameter, factoryType.typeParameters[i]);
    }
    redirecteeType = redirecteeType != null
        ? substitute(redirecteeType, substitutionMap) as FunctionType
        : null;

    // TODO(hillerstrom): It would be preferable to know whether a failure
    // happened during [_computeRedirecteeType].
    if (redirecteeType == null) {
      return;
    }

    Builder? redirectionTargetBuilder = redirectionTarget.target;
    if (redirectionTargetBuilder is RedirectingFactoryBuilder) {
      redirectionTargetBuilder._checkRedirectingFactory(typeEnvironment);
      String? errorMessage = redirectionTargetBuilder
          .function.redirectingFactoryTarget?.errorMessage;
      if (errorMessage != null) {
        setRedirectingFactoryError(errorMessage);
      }
    }

    // Redirection to generative enum constructors is forbidden and is reported
    // as an error elsewhere.
    Builder? redirectionTargetParent = redirectionTarget.target?.parent;
    bool redirectingTargetParentIsEnum = redirectionTargetParent is ClassBuilder
        ? redirectionTargetParent.isEnum
        : false;
    if (!((classBuilder?.cls.isEnum ?? false) &&
        (redirectionTarget.target?.isConstructor ?? false) &&
        redirectingTargetParentIsEnum)) {
      // Check whether [redirecteeType] <: [factoryType].
      if (!typeEnvironment.isSubtypeOf(
          redirecteeType,
          factoryType.withoutTypeParameters,
          SubtypeCheckMode.ignoringNullabilities)) {
        libraryBuilder.addProblemForRedirectingFactory(
            this,
            templateIncompatibleRedirecteeFunctionType.withArguments(
                redirecteeType, factoryType.withoutTypeParameters),
            redirectionTarget.charOffset,
            noLength,
            redirectionTarget.fileUri);
      } else {
        if (!typeEnvironment.isSubtypeOf(
            redirecteeType,
            factoryType.withoutTypeParameters,
            SubtypeCheckMode.withNullabilities)) {
          libraryBuilder.addProblemForRedirectingFactory(
              this,
              templateIncompatibleRedirecteeFunctionType.withArguments(
                  redirecteeType, factoryType.withoutTypeParameters),
              redirectionTarget.charOffset,
              noLength,
              redirectionTarget.fileUri);
        }
      }
    }
  }

  @override
  BodyBuilderContext createBodyBuilderContext(
      {required bool inOutlineBuildingPhase,
      required bool inMetadata,
      required bool inConstFields}) {
    return new RedirectingFactoryBodyBuilderContext(this,
        inOutlineBuildingPhase: inOutlineBuildingPhase,
        inMetadata: inMetadata,
        inConstFields: inConstFields);
  }
}
