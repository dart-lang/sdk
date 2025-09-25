// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'resolver.dart';

typedef BodyBuilderCreator =
    BodyBuilder Function({
      required SourceLibraryBuilder libraryBuilder,
      required BodyBuilderContext context,
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
  final Uri fileUri;

  late final CloneVisitorNotMembers _simpleCloner =
      new CloneVisitorNotMembers();

  _ResolverContext._({
    required this.libraryBuilder,
    required this.typeInferrer,
    required this.typeEnvironment,
    required this.assignedVariables,
    required this.fileUri,
  });

  factory _ResolverContext({
    required TypeInferenceEngineImpl typeInferenceEngine,
    required SourceLibraryBuilder libraryBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required LookupScope scope,
    required Uri fileUri,
    InferenceDataForTesting? inferenceDataForTesting,
  }) {
    TypeInferrer typeInferrer = typeInferenceEngine.createTypeInferrer(
      thisType: bodyBuilderContext.thisType,
      libraryBuilder: libraryBuilder,
      extensionScope: scope,
      dataForTesting: inferenceDataForTesting,
    );
    TypeEnvironment typeEnvironment = typeInferrer.typeSchemaEnvironment;
    AssignedVariables assignedVariables = typeInferrer.assignedVariables;
    return new _ResolverContext._(
      libraryBuilder: libraryBuilder,
      typeInferrer: typeInferrer,
      typeEnvironment: typeEnvironment,
      assignedVariables: assignedVariables,
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
