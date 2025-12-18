// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'resolver.dart';

typedef BodyBuilderCreator =
    BodyBuilder Function({
      required SourceLibraryBuilder libraryBuilder,
      required BodyBuilderContext context,
      required ExtensionScope extensionScope,
      required LookupScope enclosingScope,
      LocalScope? formalParameterScope,
      required ClassHierarchy hierarchy,
      required CoreTypes coreTypes,
      VariableDeclaration? thisVariable,
      List<TypeParameter>? thisTypeParameters,
      required Uri uri,
      required AssignedVariables assignedVariables,
      required TypeEnvironment typeEnvironment,
      required ConstantContext constantContext,
    });

// Coverage-ignore(suite): Not run.
class ResolverForTesting extends Resolver {
  final BodyBuilderCreator bodyBuilderCreator;

  ResolverForTesting({
    required super.classHierarchy,
    required super.coreTypes,
    required super.typeInferenceEngine,
    required super.benchmarker,
    required this.bodyBuilderCreator,
  });

  @override
  BodyBuilder _createBodyBuilderInternal({
    required _ResolverContext context,
    required BodyBuilderContext bodyBuilderContext,
    required LookupScope scope,
    required LocalScope? formalParameterScope,
    required VariableDeclaration? thisVariable,
    required List<TypeParameter>? thisTypeParameters,
    required ConstantContext constantContext,
  }) {
    return bodyBuilderCreator(
      libraryBuilder: context.libraryBuilder,
      context: bodyBuilderContext,
      extensionScope: context.extensionScope,
      enclosingScope: scope,
      formalParameterScope: formalParameterScope,
      hierarchy: _classHierarchy,
      coreTypes: _coreTypes,
      thisVariable: thisVariable,
      thisTypeParameters: thisTypeParameters,
      uri: context.fileUri,
      assignedVariables: context.assignedVariables,
      typeEnvironment: context.typeEnvironment,
      constantContext: constantContext,
    );
  }
}

class _ResolverContext {
  final SourceLibraryBuilder libraryBuilder;
  final TypeInferrer typeInferrer;
  final TypeEnvironment typeEnvironment;
  final AssignedVariables assignedVariables;
  final ExtensionScope extensionScope;
  final Uri fileUri;

  late final CloneVisitorNotMembers _simpleCloner =
      new CloneVisitorNotMembers();

  _ResolverContext._({
    required this.libraryBuilder,
    required this.typeInferrer,
    required this.typeEnvironment,
    required this.assignedVariables,
    required this.extensionScope,
    required this.fileUri,
  });

  factory _ResolverContext({
    required TypeInferenceEngineImpl typeInferenceEngine,
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ExtensionScope extensionScope,
    required Uri fileUri,
    InferenceDataForTesting? inferenceDataForTesting,
  }) {
    TypeInferrer typeInferrer = typeInferenceEngine.createTypeInferrer(
      thisType: bodyBuilderContext.thisType,
      libraryBuilder: libraryBuilder,
      extensionScope: extensionScope,
      dataForTesting: inferenceDataForTesting,
    );
    TypeEnvironment typeEnvironment = typeInferrer.typeSchemaEnvironment;
    AssignedVariables assignedVariables = typeInferrer.assignedVariables;
    return new _ResolverContext._(
      libraryBuilder: libraryBuilder,
      typeInferrer: typeInferrer,
      typeEnvironment: typeEnvironment,
      assignedVariables: assignedVariables,
      extensionScope: extensionScope,
      fileUri: fileUri,
    );
  }

  /// Infers the annotations of [annotatable].
  ///
  /// If [indices] is provided, only the annotations at the given indices are
  /// inferred. Otherwise all annotations are inferred.
  void _inferAnnotations({
    required Annotatable annotatable,
    List<int>? indices,
  }) {
    typeInferrer.inferMetadata(
      fileUri: fileUri,
      annotatable: annotatable,
      indices: indices,
    );
  }

  void inferSingleTargetAnnotation({
    required SingleTargetAnnotations singleTarget,
  }) {
    _inferAnnotations(
      annotatable: singleTarget.target,
      indices: singleTarget.indicesOfAnnotationsToBeInferred,
    );
  }

  void _inferPendingAnnotations({required PendingAnnotations annotations}) {
    List<SingleTargetAnnotations>? singleTargetAnnotations =
        annotations.singleTargetAnnotations;
    if (singleTargetAnnotations != null) {
      for (int i = 0; i < singleTargetAnnotations.length; i++) {
        SingleTargetAnnotations singleTarget = singleTargetAnnotations[i];
        inferSingleTargetAnnotation(singleTarget: singleTarget);
      }
    }

    List<MultiTargetAnnotations>? multiTargetAnnotations =
        annotations.multiTargetAnnotations;
    if (multiTargetAnnotations != null) {
      for (int i = 0; i < multiTargetAnnotations.length; i++) {
        MultiTargetAnnotations multiTarget = multiTargetAnnotations[i];
        List<Annotatable> targets = multiTarget.targets;
        Annotatable firstTarget = targets.first;
        List<Expression> annotations = firstTarget.annotations;
        _inferAnnotations(annotatable: firstTarget);
        for (int i = 1; i < targets.length; i++) {
          Annotatable target = targets[i];
          for (int i = 0; i < annotations.length; i++) {
            target.addAnnotation(_simpleCloner.cloneInContext(annotations[i]));
          }
        }
      }
    }
  }

  void performBacklog(PendingAnnotations? annotations) {
    if (annotations != null) {
      _inferPendingAnnotations(annotations: annotations);
    }
    libraryBuilder.checkPendingBoundsChecks(typeEnvironment);
  }
}

class _InitializerBuilder {
  SuperInitializer? superInitializer;

  RedirectingInitializer? redirectingInitializer;

  List<Initializer> _initializers = [];

  void _injectInvalidInitializer(
    CompilerContext compilerContext,
    ProblemReporting problemReporting,
    Message message,
    Uri fileUri,
    int fileOffset,
    int length,
  ) {
    Initializer lastInitializer = _initializers.removeLast();
    assert(
      lastInitializer == superInitializer ||
          lastInitializer == redirectingInitializer,
    );
    Initializer error = createInvalidInitializer(
      problemReporting.buildProblem(
        compilerContext: compilerContext,
        message: message,
        fileUri: fileUri,
        fileOffset: fileOffset,
        length: length,
      ),
    );
    _initializers.add(error);
    _initializers.add(lastInitializer);
  }

  bool addInitializer(
    CompilerContext compilerContext,
    ProblemReporting problemReporting,
    BodyBuilderContext bodyBuilderContext,
    InitializerInferenceResult inferenceResult, {
    required Uri fileUri,
  }) {
    Initializer initializer = inferenceResult.initializer;
    if (initializer is SuperInitializer) {
      if (superInitializer != null) {
        _injectInvalidInitializer(
          compilerContext,
          problemReporting,
          codeMoreThanOneSuperInitializer,
          fileUri,
          initializer.fileOffset,
          "super".length,
        );
        return false;
      } else if (redirectingInitializer != null) {
        _injectInvalidInitializer(
          compilerContext,
          problemReporting,
          codeRedirectingConstructorWithSuperInitializer,
          fileUri,
          initializer.fileOffset,
          "super".length,
        );
        return false;
      } else {
        inferenceResult.applyResult(_initializers, null);
        superInitializer = initializer;
        _initializers.add(initializer);
        return true;
      }
    } else if (initializer
        case RedirectingInitializer() ||
            ExtensionTypeRedirectingInitializer()) {
      if (superInitializer != null) {
        // Point to the existing super initializer.
        _injectInvalidInitializer(
          compilerContext,
          problemReporting,
          codeRedirectingConstructorWithSuperInitializer,
          fileUri,
          superInitializer!.fileOffset,
          "super".length,
        );
        bodyBuilderContext.markAsErroneous();
        return false;
      } else if (redirectingInitializer != null) {
        _injectInvalidInitializer(
          compilerContext,
          problemReporting,
          codeRedirectingConstructorWithMultipleRedirectInitializers,
          fileUri,
          initializer.fileOffset,
          noLength,
        );
        bodyBuilderContext.markAsErroneous();
        return false;
      } else if (_initializers.isNotEmpty) {
        // Error on all previous ones.
        for (int i = 0; i < _initializers.length; i++) {
          Initializer initializer = _initializers[i];
          int length = noLength;
          if (initializer is AssertInitializer) length = "assert".length;
          Initializer error = createInvalidInitializer(
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: codeRedirectingConstructorWithAnotherInitializer,
              fileUri: fileUri,
              fileOffset: initializer.fileOffset,
              length: length,
            ),
          );
          _initializers[i] = error;
        }
        inferenceResult.applyResult(_initializers, null);
        _initializers.add(initializer);
        if (initializer is RedirectingInitializer) {
          redirectingInitializer = initializer;
        }
        bodyBuilderContext.markAsErroneous();
        return false;
      } else {
        inferenceResult.applyResult(_initializers, null);
        if (initializer is RedirectingInitializer) {
          redirectingInitializer = initializer;
        }
        _initializers.add(initializer);
        return true;
      }
    } else if (redirectingInitializer != null) {
      int length = noLength;
      if (initializer is AssertInitializer) length = "assert".length;
      _injectInvalidInitializer(
        compilerContext,
        problemReporting,
        codeRedirectingConstructorWithAnotherInitializer,
        fileUri,
        initializer.fileOffset,
        length,
      );
      bodyBuilderContext.markAsErroneous();
      return false;
    } else if (superInitializer != null) {
      _injectInvalidInitializer(
        compilerContext,
        problemReporting,
        codeSuperInitializerNotLast,
        fileUri,
        initializer.fileOffset,
        noLength,
      );
      bodyBuilderContext.markAsErroneous();
      return false;
    } else {
      inferenceResult.applyResult(_initializers, null);
      _initializers.add(initializer);
      return true;
    }
  }

  List<Initializer> get initializers => _initializers;
}
