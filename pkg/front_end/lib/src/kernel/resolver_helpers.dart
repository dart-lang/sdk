// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'resolver.dart';

typedef BodyBuilderCreator = BodyBuilder Function({
  required SourceLibraryBuilder libraryBuilder,
  required BodyBuilderContext context,
  required ExtensionScope extensionScope,
  required LookupScope enclosingScope,
  LocalScope? formalParameterScope,
  required ClassHierarchy hierarchy,
  required CoreTypes coreTypes,
  InternalVariable? thisVariable,
  List<TypeParameter>? thisTypeParameters,
  required Uri uri,
  required AssignedVariablesImpl assignedVariables,
  required TypeEnvironment typeEnvironment,
  required ConstantContext constantContext,
});

// Coverage-ignore(suite): Not run.
class ResolverForTesting extends Resolver {
  final BodyBuilderCreator bodyBuilderCreator;

  new({
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
    required InternalVariable? thisVariable,
    required List<TypeParameter>? thisTypeParameters,
    required ConstantContext constantContext,
    required InternalThisVariable? internalThisVariable,
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
  final AssignedVariablesImpl assignedVariables;
  final ExtensionScope extensionScope;
  final Uri fileUri;

  late final CloneVisitorNotMembers _simpleCloner =
      new CloneVisitorNotMembers();

  new _({
    required this.libraryBuilder,
    required this.typeInferrer,
    required this.typeEnvironment,
    required this.assignedVariables,
    required this.extensionScope,
    required this.fileUri,
  });

  factory({
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
    AssignedVariablesImpl assignedVariables = typeInferrer.assignedVariables;
    return new _ResolverContext._(
      libraryBuilder: libraryBuilder,
      typeInferrer: typeInferrer,
      typeEnvironment: typeEnvironment,
      assignedVariables: assignedVariables,
      extensionScope: extensionScope,
      fileUri: fileUri,
    );
  }

  /// Infers the [annotations] and adds them to [annotatable].
  ///
  /// Returns a list of the inferred annotations.
  List<Expression> _inferAnnotations({
    required Annotatable annotatable,
    required List<Expression> annotations,
  }) {
    return typeInferrer.inferMetadata(
      fileUri: fileUri,
      annotatable: annotatable,
      annotations: annotations,
    );
  }

  List<Expression> inferSingleTargetAnnotation({
    required SingleTargetAnnotations singleTarget,
  }) {
    Annotatable target = singleTarget.target;
    return _inferAnnotations(
      annotatable: target,
      annotations: singleTarget.annotations,
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
        List<Expression> annotations = _inferAnnotations(
          annotatable: firstTarget,
          annotations: multiTarget.annotations,
        );
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
  final CompilerContext _compilerContext;
  final ProblemReporting _problemReporting;
  final BodyBuilderContext _bodyBuilderContext;
  final TypeInferrer _typeInferrer;
  final Uri _fileUri;

  SuperInitializer? _superInitializer;

  Initializer? _redirectingInitializer;

  List<Initializer> _regularInitializers = [];

  bool _isErroneous = false;

  /// Only used when [member] is a constructor. It tracks if an implicit super
  /// initializer is needed.
  ///
  /// An implicit super initializer isn't needed
  ///
  /// 1. if the current class is Object,
  /// 2. if there is an explicit super initializer,
  /// 3. if there is a redirecting (this) initializer, or
  /// 4. if a compile-time error prevented us from generating code for an
  ///    initializer. This avoids cascading errors.
  bool _needsImplicitSuperInitializer;

  new({
    required CompilerContext compilerContext,
    required ProblemReporting problemReporting,
    required BodyBuilderContext bodyBuilderContext,
    required TypeInferrer typeInferrer,
    required CoreTypes coreTypes,
    required Uri fileUri,
  }) : this._compilerContext = compilerContext,
       this._problemReporting = problemReporting,
       this._bodyBuilderContext = bodyBuilderContext,
       this._typeInferrer = typeInferrer,
       this._fileUri = fileUri,
       this._needsImplicitSuperInitializer = bodyBuilderContext
           .needsImplicitSuperInitializer(coreTypes);

  void _inferInitializers(
    List<InternalInitializer> initializers, {
    required ContextAllocationStrategy contextAllocationStrategy,
  }) {
    InferredConstructorInitializers result = _typeInferrer.inferInitializers(
      fileUri: _fileUri,
      constructorContext: _bodyBuilderContext.constructorContext!,
      initializers: initializers,
      contextAllocationStrategy: contextAllocationStrategy,
    );
    if (!_bodyBuilderContext.isExternalConstructor) {
      for (InitializerInferenceResult initializerInferenceResult
          in result.initializersInferenceResult) {
        _addInferredInitializer(initializerInferenceResult);
      }
    }
  }

  void processInitializers({
    required SourceLibraryBuilder libraryBuilder,
    required LibraryFeatures libraryFeatures,
    required _SuperParameterArguments? superParameterArguments,
    required List<InternalInitializer> initializers,
    required AsyncModifier asyncModifier,
    required bool forPrimaryConstructor,
    required List<InternalVariable> parameters,
    required InternalThisVariable? internalThisVariable,
    required ContextAllocationStrategy contextAllocationStrategy,
    required bool isConstructorWithoutBody,
  }) {
    if (initializers.isNotEmpty) {
      if (_bodyBuilderContext.isMixinClass) {
        // Report an error if a mixin class has a constructor with an
        // initializer.
        _problemReporting.buildProblem(
          compilerContext: _compilerContext,
          message: diag.illegalMixinDueToConstructors.withArguments(
            className: _bodyBuilderContext.className,
          ),
          fileUri: _fileUri,
          // It is allowed to have a primary constructor without a body, so
          // for primary constructors we report the error on the first
          // initializer and not the name of the constructor.
          fileOffset: forPrimaryConstructor
              ? initializers.first.fileOffset
              : _bodyBuilderContext.memberNameOffset,
          length: noLength,
        );
      }
    }

    List<InternalInitializer> initializersToBeInferred = [];
    for (InternalInitializer initializer in initializers) {
      switch (initializer) {
        case ExtensionTypeRedirectingInitializer():
          _needsImplicitSuperInitializer = false;
          initializersToBeInferred.add(initializer);
        case ExtensionTypeRepresentationFieldInitializer():
          initializersToBeInferred.add(initializer);
        case InternalRedirectingInitializer():
          _needsImplicitSuperInitializer = false;
          if (_bodyBuilderContext.isEnumClass) {
            List<FormalParameterBuilder> formals = _bodyBuilderContext.formals!;
            ActualArguments arguments = initializer.arguments;
            List<InternalExpression> enumSyntheticArguments = [
              intern.createVariableGet(
                formals[0].variable,
                fileOffset: formals[0].fileOffset,
              )..parent = initializer.arguments,
              intern.createVariableGet(
                formals[1].variable,
                fileOffset: formals[1].fileOffset,
              )..parent = initializer.arguments,
            ];
            arguments.prependArguments([
              new PositionalArgument(enumSyntheticArguments[0]),
              new PositionalArgument(enumSyntheticArguments[1]),
            ], positionalCount: 2);
          }
          initializersToBeInferred.add(initializer);
        case InternalSuperInitializer():
          _needsImplicitSuperInitializer = false;
          if (_bodyBuilderContext.isEnumClass) {
            initializer = intern.createInvalidInitializer(
              intern.createInvalidExpressionFromErrorText(
                _problemReporting.buildProblem(
                  compilerContext: _compilerContext,
                  message: diag.enumConstructorSuperInitializer,
                  fileUri: _fileUri,
                  fileOffset: initializer.fileOffset,
                  length: noLength,
                ),
              ),
              isSuperInitializer: true,
            );
          } else if (superParameterArguments != null) {
            bool insertNamedOnly = false;
            ActualArguments arguments = initializer.arguments;
            if (superParameterArguments.positionalCount > 0) {
              if (arguments.positionalCount > 0) {
                _problemReporting.addProblem(
                  diag.positionalSuperParametersAndArguments,
                  arguments.fileOffset,
                  noLength,
                  _fileUri,
                  context: <LocatedMessage>[
                    diag.superInitializerParameter.withLocation(
                      _fileUri,
                      superParameterArguments.firstPositionalOffset,
                      noLength,
                    ),
                  ],
                );
                insertNamedOnly = true;
              }
            }
            if (insertNamedOnly) {
              /// Error case: Don't insert positional argument when
              /// positional arguments already exist.
              arguments.prependArguments(
                superParameterArguments.arguments
                    .whereType<NamedArgument>()
                    .toList(),
                positionalCount: 0,
              );
            } else {
              arguments.prependArguments(
                superParameterArguments.arguments,
                positionalCount: superParameterArguments.positionalCount,
              );
            }
          }
          initializersToBeInferred.add(initializer);
        case InternalFieldInitializer():
        case InternalAssertInitializer():
          initializersToBeInferred.add(initializer);
        case InternalInvalidInitializer():
          initializersToBeInferred.add(initializer);
          _needsImplicitSuperInitializer = false;
      }
    }

    if (asyncModifier.kind != AsyncMarker.Sync) {
      InternalInvalidInitializer invalidInitializer = intern
          .createInvalidInitializer(
            intern.createInvalidExpressionFromErrorText(
              _problemReporting.buildProblem(
                compilerContext: _compilerContext,
                message: diag.constructorNotSync,
                fileUri: _fileUri,
                fileOffset: asyncModifier.fileOffset,
                length: noLength,
              ),
            ),
          );
      initializersToBeInferred.add(invalidInitializer);
      _needsImplicitSuperInitializer = false;
    }

    if (_needsImplicitSuperInitializer) {
      InternalInitializer initializer = _createImplicitSuperInitializer(
        libraryBuilder: libraryBuilder,
        typeInferrer: _typeInferrer,
        superParameterArguments: superParameterArguments,
      );
      initializersToBeInferred.add(initializer);
    }
    _inferInitializers(
      initializersToBeInferred,
      contextAllocationStrategy: contextAllocationStrategy,
    );
    _bodyBuilderContext.registerInitializers([
      ..._regularInitializers,
      ?_redirectingInitializer,
      ?_superInitializer,
    ], isErroneous: _isErroneous);
  }

  void _addSuperInitializer(
    InitializerInferenceResult inferenceResult,
    SuperInitializer initializer,
  ) {
    if (_superInitializer != null) {
      _regularInitializers.add(
        extern.createInvalidInitializer(
          extern.createInvalidExpressionFromErrorText(
            _problemReporting.buildProblem(
              compilerContext: _compilerContext,
              message: diag.moreThanOneSuperInitializer,
              fileUri: _fileUri,
              fileOffset: initializer.fileOffset,
              length: "super".length,
            ),
          ),
        ),
      );
      _needsImplicitSuperInitializer = false;
    } else if (_redirectingInitializer != null) {
      _regularInitializers.add(
        extern.createInvalidInitializer(
          extern.createInvalidExpressionFromErrorText(
            _problemReporting.buildProblem(
              compilerContext: _compilerContext,
              message: diag.redirectingConstructorWithSuperInitializer,
              fileUri: _fileUri,
              fileOffset: initializer.fileOffset,
              length: "super".length,
            ),
          ),
        ),
      );
      _needsImplicitSuperInitializer = false;
    } else {
      inferenceResult.addHoistedArguments(_regularInitializers);
      _superInitializer = initializer;
    }
  }

  void _addRedirectingInitializer(
    InitializerInferenceResult inferenceResult,
    Initializer initializer,
  ) {
    if (_superInitializer != null) {
      // Point to the existing super initializer.
      _regularInitializers.add(
        extern.createInvalidInitializer(
          extern.createInvalidExpressionFromErrorText(
            _problemReporting.buildProblem(
              compilerContext: _compilerContext,
              message: diag.redirectingConstructorWithSuperInitializer,
              fileUri: _fileUri,
              fileOffset: _superInitializer!.fileOffset,
              length: "super".length,
            ),
          ),
        ),
      );
      _isErroneous = true;
      _needsImplicitSuperInitializer = false;
    } else if (_redirectingInitializer != null) {
      _regularInitializers.add(
        extern.createInvalidInitializer(
          extern.createInvalidExpressionFromErrorText(
            _problemReporting.buildProblem(
              compilerContext: _compilerContext,
              message:
                  diag.redirectingConstructorWithMultipleRedirectInitializers,
              fileUri: _fileUri,
              fileOffset: initializer.fileOffset,
              length: noLength,
            ),
          ),
        ),
      );
      _isErroneous = true;
      _needsImplicitSuperInitializer = false;
    } else if (_regularInitializers.isNotEmpty) {
      // Error on all previous ones.
      for (int i = 0; i < _regularInitializers.length; i++) {
        Initializer initializer = _regularInitializers[i];
        int length = noLength;
        if (initializer is AssertInitializer) length = "assert".length;
        _regularInitializers[i] = extern.createInvalidInitializer(
          extern.createInvalidExpressionFromErrorText(
            _problemReporting.buildProblem(
              compilerContext: _compilerContext,
              message: diag.redirectingConstructorWithAnotherInitializer,
              fileUri: _fileUri,
              fileOffset: initializer.fileOffset,
              length: length,
            ),
          ),
        );
      }
      inferenceResult.addHoistedArguments(_regularInitializers);
      _redirectingInitializer = initializer;
      _isErroneous = true;
      _needsImplicitSuperInitializer = false;
    } else {
      inferenceResult.addHoistedArguments(_regularInitializers);
      _redirectingInitializer = initializer;
    }
  }

  void _addRegularInitializer(
    InitializerInferenceResult inferenceResult,
    Initializer initializer,
  ) {
    if (_redirectingInitializer != null) {
      int length = noLength;
      if (initializer is AssertInitializer) length = "assert".length;
      _regularInitializers.add(
        extern.createInvalidInitializer(
          extern.createInvalidExpressionFromErrorText(
            _problemReporting.buildProblem(
              compilerContext: _compilerContext,
              message: diag.redirectingConstructorWithAnotherInitializer,
              fileUri: _fileUri,
              fileOffset: initializer.fileOffset,
              length: length,
            ),
          ),
        ),
      );
      _isErroneous = true;
      _needsImplicitSuperInitializer = false;
    } else if (_superInitializer != null) {
      _regularInitializers.add(
        extern.createInvalidInitializer(
          extern.createInvalidExpressionFromErrorText(
            _problemReporting.buildProblem(
              compilerContext: _compilerContext,
              message: diag.superInitializerNotLast,
              fileUri: _fileUri,
              fileOffset: initializer.fileOffset,
              length: noLength,
            ),
          ),
        ),
      );
      _isErroneous = true;
      _needsImplicitSuperInitializer = false;
    } else {
      inferenceResult.addHoistedArguments(_regularInitializers);
      _regularInitializers.add(initializer);
    }
  }

  void _addInferredInitializer(
    InitializerInferenceResult initializerInferenceResult,
  ) {
    Initializer initializer = initializerInferenceResult.initializer;
    switch (initializer) {
      case SuperInitializer():
        _addSuperInitializer(initializerInferenceResult, initializer);
      case RedirectingInitializer():
        _addRedirectingInitializer(initializerInferenceResult, initializer);
      case AssertInitializer():
      case InvalidInitializer():
      case LocalInitializer():
      case FieldInitializer():
        _addRegularInitializer(initializerInferenceResult, initializer);
      case AuxiliaryInitializer():
        if (initializer is ExternalInitializer) {
          switch (initializer) {
            case ExternalExtensionTypeRedirectingInitializer():
              _addRedirectingInitializer(
                initializerInferenceResult,
                initializer,
              );
            case ExternalExtensionTypeRepresentationFieldInitializer():
              _addRegularInitializer(initializerInferenceResult, initializer);
          }
        } else {
          throw new UnsupportedError(
            "Unexpected initializer ${initializer} "
            "(${initializer.runtimeType}).",
          );
        }
    }
  }

  InternalInitializer _createImplicitSuperInitializer({
    required SourceLibraryBuilder libraryBuilder,
    required TypeInferrer typeInferrer,
    required _SuperParameterArguments? superParameterArguments,
  }) {
    /// >If no superinitializer is provided, an implicit superinitializer
    /// >of the form super() is added at the end of the constructor's
    /// >initializer list, unless the enclosing class is class Object.
    InternalInitializer? initializer;
    ActualArguments arguments;
    List<Argument>? argumentsOriginalOrder;
    int positionalCount = 0;
    if (superParameterArguments != null) {
      argumentsOriginalOrder = superParameterArguments.arguments;
      positionalCount += superParameterArguments.positionalCount;
    }
    if (_bodyBuilderContext.isEnumClass) {
      List<FormalParameterBuilder> formals = _bodyBuilderContext.formals!;
      assert(
        formals.length >= 2 &&
            formals[0].name == "#index" &&
            formals[1].name == "#name",
      );
      InternalExpression indexExpression = intern.createVariableGet(
        formals[0].variable,
        fileOffset: formals[0].fileOffset,
      );
      InternalExpression nameExpression = intern.createVariableGet(
        formals[1].variable,
        fileOffset: formals[1].fileOffset,
      );
      (argumentsOriginalOrder ??= []).insertAll(0, [
        new PositionalArgument(indexExpression),
        new PositionalArgument(nameExpression),
      ]);
      positionalCount += 2;
    }

    int argumentsOffset = -1;
    if (superParameterArguments != null) {
      for (Argument argument in superParameterArguments.arguments) {
        int currentArgumentOffset = argument.expression.fileOffset;
        argumentsOffset = argumentsOffset <= currentArgumentOffset
            ? argumentsOffset
            : currentArgumentOffset;
      }
    }
    if (argumentsOffset == -1) {
      argumentsOffset = _bodyBuilderContext.memberNameOffset;
    }

    if (argumentsOriginalOrder != null) {
      arguments = intern.createArguments(
        argumentsOffset,
        arguments: argumentsOriginalOrder,
        hasNamedBeforePositional: false,
        positionalCount: positionalCount,
      );
    } else {
      arguments = intern.createArgumentsEmpty(argumentsOffset);
    }

    MemberLookupResult? result = _bodyBuilderContext.lookupSuperConstructor(
      '',
      libraryBuilder.nameOriginBuilder,
    );
    Constructor? superTarget;
    if (result != null) {
      if (result.isInvalidLookup) {
        int length = _bodyBuilderContext.memberNameLength;
        if (length == 0) {
          length = _bodyBuilderContext.className.length;
        }
        initializer = intern.createInvalidInitializer2(
          LookupResult.createDuplicateErrorText(
            result,
            context: _compilerContext,
            name: '',
            fileUri: _fileUri,
            fileOffset: _bodyBuilderContext.memberNameOffset,
            length: noLength,
          ),
          isSuperInitializer: true,
        );
      } else {
        MemberBuilder? memberBuilder = result.getable;
        Member? member = memberBuilder?.invokeTarget;
        if (member is Constructor) {
          superTarget = member;
        }
      }
    }
    if (initializer == null) {
      if (superTarget == null) {
        String superclass = _bodyBuilderContext.superClassName;
        int length = _bodyBuilderContext.memberNameLength;
        if (length == 0) {
          length = _bodyBuilderContext.className.length;
        }
        initializer = intern.createInvalidInitializer(
          intern.createInvalidExpressionFromErrorText(
            _problemReporting.buildProblem(
              compilerContext: _compilerContext,
              message: diag.superclassHasNoDefaultConstructor.withArguments(
                className: superclass,
              ),
              fileUri: _fileUri,
              fileOffset: _bodyBuilderContext.memberNameOffset,
              length: length,
            ),
          ),
          isSuperInitializer: true,
        );
      } else if (_problemReporting.checkArgumentsForFunction(
            function: superTarget.function,
            explicitTypeArguments: null,
            arguments: arguments,
            fileOffset: _bodyBuilderContext.memberNameOffset,
            fileUri: _fileUri,
            typeParameters: const <TypeParameter>[],
          )
          case LocatedMessage argumentIssue) {
        InternalInitializer? errorMessageInitializer;
        if (superParameterArguments != null) {
          int positionalSuperParameterCount =
              superTarget.function.positionalParameters.length;
          Set<String> superTargetNamedParameterNames = {
            for (NamedParameter namedParameter
                in superTarget.function.namedParameters)
              // Coverage-ignore(suite): Not run.
              namedParameter.parameterName,
          };
          int positionalIndex = 0;
          for (Argument argument in superParameterArguments.arguments) {
            switch (argument) {
              case PositionalArgument():
                if (positionalIndex >= positionalSuperParameterCount) {
                  InternalInvalidExpression errorMessageExpression = intern
                      .createInvalidExpressionFromErrorText(
                        _problemReporting.buildProblem(
                          compilerContext: _compilerContext,
                          message:
                              diag.missingPositionalSuperConstructorParameter,
                          fileUri: _fileUri,
                          fileOffset: argument.expression.fileOffset,
                          length: noLength,
                        ),
                      );
                  errorMessageInitializer ??= intern.createInvalidInitializer(
                    errorMessageExpression,
                    isSuperInitializer: true,
                  );
                }
                positionalIndex++;
              case NamedArgument():
                if (!superTargetNamedParameterNames.contains(
                  argument.namedExpression.name,
                )) {
                  InternalInvalidExpression errorMessageExpression = intern
                      .createInvalidExpressionFromErrorText(
                        _problemReporting.buildProblem(
                          compilerContext: _compilerContext,
                          message: diag.missingNamedSuperConstructorParameter,
                          fileUri: _fileUri,
                          fileOffset: argument.namedExpression.fileOffset,
                          length: noLength,
                        ),
                      );
                  errorMessageInitializer ??= intern.createInvalidInitializer(
                    errorMessageExpression,
                    isSuperInitializer: true,
                  );
                }
            }
          }
        }
        errorMessageInitializer ??= intern.createInvalidInitializer(
          intern.createInvalidExpressionFromErrorText(
            _problemReporting.buildProblem(
              compilerContext: _compilerContext,
              message: diag.implicitSuperInitializerMissingArguments
                  .withArguments(className: superTarget.enclosingClass.name),
              fileUri: _fileUri,
              fileOffset: argumentIssue.charOffset,
              length: argumentIssue.length,
            ),
          ),
          isSuperInitializer: true,
        );
        initializer = errorMessageInitializer;
      } else {
        if (_bodyBuilderContext.isConstConstructor && !superTarget.isConst) {
          _problemReporting.addProblem(
            diag.constConstructorWithNonConstSuper,
            _bodyBuilderContext.memberNameOffset,
            superTarget.name.text.length,
            _fileUri,
          );
        }
        initializer = intern.createSuperInitializer(
          target: superTarget,
          arguments: arguments,
          isSynthetic: true,
          fileOffset: _bodyBuilderContext.memberNameOffset,
        );
      }
    }
    return initializer;
  }
}

class _SuperParameterArguments {
  final List<Argument> arguments;
  final int positionalCount;
  final int firstPositionalOffset;

  new(
    this.arguments, {
    required this.positionalCount,
    required this.firstPositionalOffset,
  });

  // Coverage-ignore(suite): Not run.
  int get namedCount => arguments.length - positionalCount;
}
