// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:_fe_analyzer_shared/src/type_inference/shared_inference_log.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_constraint_gatherer.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/error/codes.dart'
    show CompileTimeErrorCode, WarningCode;
import 'package:analyzer/src/generated/inference_log.dart';
import 'package:collection/collection.dart';

/// Tracks upper and lower type bounds for a set of type parameters.
///
/// When the methods of this class encounter one of the type parameters it is
/// inferring, it will record the constraint, and optimistically assume the
/// constraint will be satisfied.
///
/// For example if we are inferring type parameter A, and we ask if
/// `A <: num`, this will record that A must be a subtype of `num`. It also
/// handles cases when A appears as part of the structure of another type, for
/// example `Iterable<A> <: Iterable<num>` would infer the same constraint
/// (due to covariant generic types) as would `() -> A <: () -> num`. In
/// contrast `(A) -> void <: (num) -> void`.
///
/// Once the lower/upper bounds are determined, `chooseFinalTypes` should be
/// called to finish the inference. It will instantiate a generic function type
/// with the inferred types for each type parameter.
///
/// It can also optionally compute a partial solution, in case some of the type
/// parameters could not be inferred (because the constraints cannot be
/// satisfied), or bail on the inference when this happens.
///
/// As currently designed, an instance of this class should only be used to
/// infer a single call and discarded immediately afterwards.
class GenericInferrer {
  final TypeSystemImpl _typeSystem;
  final List<TypeParameterElementImpl> _typeParameters;
  final Map<TypeParameterElementImpl, List<MergedTypeConstraint>> _constraints;

  /// The list of type parameters being inferred.
  final List<TypeParameterElementImpl> _typeFormals;

  /// The [DiagnosticReporter] to which inference diagnostics should be reported, or
  /// `null` if diagnostics shouldn't be reported.
  final DiagnosticReporter? _diagnosticReporter;

  /// The [SyntacticEntity] to which errors should be attached.  May be `null`
  /// if errors are not being reported (that is, if [_diagnosticReporter] is also
  /// `null`).
  final SyntacticEntity? errorEntity;

  /// Indicates whether the "generic metadata" feature is enabled.  When it is,
  /// type arguments are allowed to be instantiated with generic function types.
  final bool _genericMetadataIsEnabled;

  /// Indicates whether the "inference using bounds" feature is enabled. When it
  /// is, the bounds of type parameters will be used more extensively when
  /// computing the solutions after each of the inference phases.
  final bool inferenceUsingBoundsIsEnabled;

  final bool _strictInference;

  /// List whose elements are the corresponding to the fixed inferred types.
  ///
  /// Background: sometimes the upwards inference phase of generic type
  /// inference is capable of assigning a more specific type than the downwards
  /// inference phase, but we don't want to use the more specific type due to
  /// Dart's "runtime checked covariant generics" design.  For example, in this
  /// code:
  ///
  ///     List<num> x = [1, 2, 3];
  ///     x.add(4.0);
  ///
  /// Downwards inference provisionally considers the list to be a `List<num>`.
  /// Without this heuristic, upwards inference would refine the type to
  /// `List<int>`, leading to a runtime failure.  So what we do is fix the type
  /// parameter to `num` after downwards inference, preventing upwards inference
  /// from doing any further refinement.
  ///
  /// (Note that the heuristic isn't needed for type parameters whose variance
  /// is explicitly specified using the as-yet-unreleased "variance" feature,
  /// since type parameters whose variance is explicitly specified don't undergo
  /// implicit runtime checks).
  final List<TypeImpl> _typesInferredSoFar;

  final TypeSystemOperations _typeSystemOperations;

  final TypeConstraintGenerationDataForTesting? dataForTesting;

  GenericInferrer(
    this._typeSystem,
    List<TypeParameterElementImpl> typeFormals, {
    DiagnosticReporter? diagnosticReporter,
    this.errorEntity,
    required bool genericMetadataIsEnabled,
    required this.inferenceUsingBoundsIsEnabled,
    required bool strictInference,
    required TypeSystemOperations typeSystemOperations,
    required this.dataForTesting,
  }) : assert(diagnosticReporter == null || errorEntity != null),
       _typeParameters = typeFormals,
       _typesInferredSoFar = List.filled(
         typeFormals.length,
         UnknownInferredType.instance,
       ),
       _constraints = {for (var formal in typeFormals) formal: []},
       _diagnosticReporter = diagnosticReporter,
       _typeFormals = typeFormals,
       _genericMetadataIsEnabled = genericMetadataIsEnabled,
       _strictInference = strictInference,
       _typeSystemOperations = typeSystemOperations;

  /// Performs upwards inference, producing a final set of inferred types that
  /// does not  contain references to the "unknown type".
  List<TypeImpl> chooseFinalTypes() => tryChooseFinalTypes(failAtError: false)!;

  /// Performs partial (either downwards or horizontal) inference, producing a
  /// set of inferred types that may contain references to the "unknown type".
  List<TypeImpl> choosePreliminaryTypes() {
    var inferencePhaseConstraints = {
      for (var typeParameter in _constraints.keys)
        typeParameter: _squashConstraints(_constraints[typeParameter]!),
    };
    var types = _typeSystemOperations
        .chooseTypes(
          _typeFormals,
          inferencePhaseConstraints,
          _typesInferredSoFar,
          preliminary: true,
          inferenceUsingBoundsIsEnabled: inferenceUsingBoundsIsEnabled,
          dataForTesting: null,
          treeNodeForTesting: null,
        )
        .cast<TypeImpl>();

    // Mark type parameters with fully known inferred types as "fixed" in the
    // overall solution.
    for (
      int typeParameterIndex = 0;
      typeParameterIndex < types.length;
      typeParameterIndex++
    ) {
      var typeParameter = _typeFormals[typeParameterIndex];
      var inferredType = types[typeParameterIndex];
      if (typeParameter.isLegacyCovariant &&
          _typeSystemOperations.isKnownType(
            SharedTypeSchemaView(inferredType),
          )) {
        _typesInferredSoFar[typeParameterIndex] = inferredType;
      }
    }

    inferenceLogWriter?.recordPreliminaryTypes(types);
    return types;
  }

  /// Apply an argument constraint, which asserts that the [argumentType] static
  /// type is a subtype of the [parameterType].
  void constrainArgument(
    TypeImpl argumentType,
    TypeImpl parameterType,
    String parameterName, {
    InterfaceFragmentImpl? genericClass,
    required AstNodeImpl? nodeForTesting,
  }) {
    var origin = TypeConstraintFromArgument(
      argumentType: SharedTypeView(argumentType),
      parameterType: SharedTypeView(parameterType),
      parameterName: parameterName,
      genericClassName: genericClass?.name,
      isGenericClassInDartCore:
          genericClass?.element.library.isDartCore ?? false,
    );
    inferenceLogWriter?.enterConstraintGeneration(
      ConstraintGenerationSource.argument,
      argumentType,
      parameterType,
    );
    _tryMatchSubtypeOf(
      argumentType,
      parameterType,
      origin,
      covariant: false,
      nodeForTesting: nodeForTesting,
    );
    inferenceLogWriter?.exitConstraintGeneration();
  }

  /// Applies all the argument constraints implied by [parameters] and
  /// [argumentTypes].
  void constrainArguments({
    InterfaceFragmentImpl? genericClass,
    required List<FormalParameterElementImpl> parameters,
    required List<TypeImpl> argumentTypes,
    required AstNodeImpl? nodeForTesting,
  }) {
    for (int i = 0; i < argumentTypes.length; i++) {
      // Try to pass each argument to each parameter, recording any type
      // parameter bounds that were implied by this assignment.
      constrainArgument(
        argumentTypes[i],
        parameters[i].type,
        parameters[i].name ?? '',
        genericClass: genericClass,
        nodeForTesting: nodeForTesting,
      );
    }
  }

  /// Applies all the argument constraints implied by [parameters] and
  /// [argumentTypes].
  void constrainArguments2({
    InterfaceFragmentImpl? genericClass,
    required List<InternalFormalParameterElement> parameters,
    required List<TypeImpl> argumentTypes,
    required AstNodeImpl? nodeForTesting,
  }) {
    for (int i = 0; i < argumentTypes.length; i++) {
      // Try to pass each argument to each parameter, recording any type
      // parameter bounds that were implied by this assignment.
      constrainArgument(
        argumentTypes[i],
        parameters[i].type,
        parameters[i].name ?? '',
        genericClass: genericClass,
        nodeForTesting: nodeForTesting,
      );
    }
  }

  /// Constrain a universal function type [fnType] used in a context
  /// [contextType].
  void constrainGenericFunctionInContext(
    FunctionTypeImpl fnType,
    TypeImpl contextType, {
    required AstNodeImpl? nodeForTesting,
  }) {
    var origin = TypeConstraintFromFunctionContext(
      functionType: fnType,
      contextType: contextType,
    );

    // Since we're trying to infer the instantiation, we want to ignore type
    // formals as we check the parameters and return type.
    var inferFnType = FunctionTypeImpl(
      typeParameters: const [],
      parameters: fnType.parameters,
      returnType: fnType.returnType,
      nullabilitySuffix: fnType.nullabilitySuffix,
    );
    inferenceLogWriter?.enterConstraintGeneration(
      ConstraintGenerationSource.genericFunctionInContext,
      inferFnType,
      contextType,
    );
    _tryMatchSubtypeOf(
      inferFnType,
      contextType,
      origin,
      covariant: true,
      nodeForTesting: nodeForTesting,
    );
    inferenceLogWriter?.exitConstraintGeneration();
  }

  /// Apply a return type constraint, which asserts that the [declaredType]
  /// is a subtype of the [contextType].
  void constrainReturnType(
    TypeImpl declaredType,
    TypeImpl contextType, {
    required AstNodeImpl? nodeForTesting,
  }) {
    var origin = TypeConstraintFromReturnType(
      declaredType: declaredType,
      contextType: contextType,
    );
    inferenceLogWriter?.enterConstraintGeneration(
      ConstraintGenerationSource.returnType,
      declaredType,
      contextType,
    );
    _tryMatchSubtypeOf(
      declaredType,
      contextType,
      origin,
      covariant: true,
      nodeForTesting: nodeForTesting,
    );
    inferenceLogWriter?.exitConstraintGeneration();
  }

  /// Same as [chooseFinalTypes], but if [failAtError] is `true` (the default)
  /// and inference fails, returns `null` rather than trying to perform error
  /// recovery.
  List<TypeImpl>? tryChooseFinalTypes({bool failAtError = true}) {
    var inferencePhaseConstraints = {
      for (var typeParameter in _constraints.keys)
        typeParameter: _squashConstraints(_constraints[typeParameter]!),
    };
    var inferredTypes = _typeSystemOperations
        .chooseTypes(
          _typeFormals,
          inferencePhaseConstraints,
          _typesInferredSoFar,
          preliminary: false,
          inferenceUsingBoundsIsEnabled: inferenceUsingBoundsIsEnabled,
          dataForTesting: null,
          treeNodeForTesting: null,
        )
        .cast<TypeImpl>();
    // Check the inferred types against all of the constraints.
    var knownTypes = <TypeParameterElement, TypeImpl>{};
    var hasErrorReported = false;
    for (int i = 0; i < _typeFormals.length; i++) {
      TypeParameterElementImpl parameter = _typeFormals[i];
      var constraints = _constraints[parameter]!;

      var inferred = inferredTypes[i];
      bool success = constraints.every(
        (c) => c.isSatisfiedBy(SharedTypeView(inferred), _typeSystemOperations),
      );

      // If everything else succeeded, check the `extends` constraint.
      if (success) {
        var name = parameter.name;
        var parameterBoundRaw = parameter.bound;
        if (name != null && parameterBoundRaw != null) {
          var parameterBound = Substitution.fromPairs2(
            _typeFormals,
            inferredTypes,
          ).substituteType(parameterBoundRaw);
          var extendsConstraint = MergedTypeConstraint.fromExtends(
            typeParameterName: name,
            boundType: SharedTypeView(parameterBoundRaw),
            extendsType: SharedTypeView(parameterBound),
            typeAnalyzerOperations: _typeSystemOperations,
          );
          constraints.add(extendsConstraint);
          success = extendsConstraint.isSatisfiedBy(
            SharedTypeView(inferred),
            _typeSystemOperations,
          );
        }
      }

      if (!success) {
        if (failAtError) {
          inferenceLogWriter?.exitGenericInference(failed: true);
          return null;
        }
        hasErrorReported = true;

        var name = parameter.name;
        if (name == null) {
          return null;
        }

        _diagnosticReporter?.atEntity(
          errorEntity!,
          CompileTimeErrorCode.couldNotInfer,
          arguments: [name, _formatError(parameter, inferred, constraints)],
        );

        // Heuristic: even if we failed, keep the erroneous type.
        // It should satisfy at least some of the constraints (e.g. the return
        // context). If we fall back to instantiateToBounds, we'll typically get
        // more errors (e.g. because `dynamic` is the most common bound).
      }

      if (inferred is FunctionTypeImpl &&
          inferred.typeParameters.isNotEmpty &&
          !_genericMetadataIsEnabled &&
          _diagnosticReporter != null) {
        if (failAtError) {
          inferenceLogWriter?.exitGenericInference(failed: true);
          return null;
        }
        hasErrorReported = true;

        var name = parameter.name;
        if (name == null) {
          return null;
        }

        var typeParameters = inferred.typeParameters;
        var typeParametersStr = typeParameters.map(_elementStr).join(', ');
        _diagnosticReporter.atEntity(
          errorEntity!,
          CompileTimeErrorCode.couldNotInfer,
          arguments: [
            name,
            ' Inferred candidate type ${_typeStr(inferred)} has type parameters'
                ' [$typeParametersStr], but a function with'
                ' type parameters cannot be used as a type argument.',
          ],
        );
      }

      if (_typeSystemOperations.isKnownType(SharedTypeSchemaView(inferred))) {
        knownTypes[parameter] = inferred;
      } else if (_strictInference) {
        // [typeParam] could not be inferred. A result will still be returned
        // by [infer], with [typeParam] filled in as its bounds. This is
        // considered a failure of inference, under the "strict-inference"
        // mode.
        _reportInferenceFailure(
          diagnosticReporter: _diagnosticReporter,
          errorEntity: errorEntity,
          genericMetadataIsEnabled: _genericMetadataIsEnabled,
        );
      }
    }

    // Use instantiate to bounds to finish things off.
    var hasError = List<bool>.filled(_typeFormals.length, false);
    var result = _typeSystem.instantiateTypeFormalsToBounds(
      _typeFormals,
      hasError: hasError,
      knownTypes: knownTypes,
    );

    // Report any errors from instantiateToBounds.
    for (int i = 0; i < hasError.length; i++) {
      if (hasError[i]) {
        if (failAtError) {
          inferenceLogWriter?.exitGenericInference(failed: true);
          return null;
        }
        hasErrorReported = true;
        TypeParameterElementImpl typeParam = _typeFormals[i];

        var name = typeParam.name;
        if (name == null) {
          return null;
        }

        var typeParamBound =
            Substitution.fromPairs2(_typeFormals, inferredTypes).substituteType(
              typeParam.bound ?? _typeSystem.typeProvider.objectType,
            );
        // TODO(jmesserly): improve this error message.
        _diagnosticReporter?.atEntity(
          errorEntity!,
          CompileTimeErrorCode.couldNotInfer,
          arguments: [
            name,
            "\nRecursive bound cannot be instantiated: '$typeParamBound'."
                "\nConsider passing explicit type argument(s) "
                "to the generic.\n\n'",
          ],
        );
      }
    }

    if (!hasErrorReported) {
      _checkArgumentsNotMatchingBounds(
        errorEntity: errorEntity,
        diagnosticReporter: _diagnosticReporter,
        typeArguments: result,
      );
    }

    _demoteTypes(result);
    inferenceLogWriter?.exitGenericInference(finalTypes: result);
    return result;
  }

  /// Check that inferred [typeArguments] satisfy the [_typeParameters] bounds.
  void _checkArgumentsNotMatchingBounds({
    required SyntacticEntity? errorEntity,
    required DiagnosticReporter? diagnosticReporter,
    required List<TypeImpl> typeArguments,
  }) {
    for (int i = 0; i < _typeFormals.length; i++) {
      var parameter = _typeFormals[i];
      var argument = typeArguments[i];

      var rawBound = parameter.bound;
      if (rawBound == null) {
        continue;
      }

      var name = parameter.name;
      if (name == null) {
        continue;
      }

      var substitution = Substitution.fromPairs2(
        _typeFormals.map((e) => e).toList(),
        typeArguments,
      );
      var bound = substitution.substituteType(rawBound);
      if (!_typeSystem.isSubtypeOf(argument, bound)) {
        diagnosticReporter?.atEntity(
          errorEntity!,
          CompileTimeErrorCode.couldNotInfer,
          arguments: [
            name,
            "\n'${_typeStr(argument)}' doesn't conform to "
                "the bound '${_typeStr(bound)}'"
                ", instantiated from '${_typeStr(rawBound)}'"
                " using type arguments ${typeArguments.map(_typeStr).toList()}.",
          ],
        );
      }
    }
  }

  void _demoteTypes(List<TypeImpl> types) {
    for (var i = 0; i < types.length; i++) {
      types[i] = _typeSystem.demoteType(types[i]);
    }
  }

  String _elementStr(ElementImpl element) {
    return element.displayString();
  }

  String _formatError(
    TypeParameterElementImpl typeParam,
    TypeImpl inferred,
    Iterable<MergedTypeConstraint> constraints,
  ) {
    var inferredStr = inferred.getDisplayString();
    var intro =
        "Tried to infer '$inferredStr' for '${typeParam.name}'"
        " which doesn't work:";

    var constraintsByOrigin =
        <TypeConstraintOrigin, List<MergedTypeConstraint>>{};
    for (var c in constraints) {
      constraintsByOrigin.putIfAbsent(c.origin, () => []).add(c);
    }

    // Only report unique constraint origins.
    Iterable<MergedTypeConstraint> isSatisfied(bool expected) =>
        constraintsByOrigin.values
            .where(
              (l) =>
                  l.every(
                    (c) => c.isSatisfiedBy(
                      SharedTypeView(inferred),
                      _typeSystemOperations,
                    ),
                  ) ==
                  expected,
            )
            .flattenedToList;

    String unsatisfied = _formatConstraints(
      isSatisfied(false),
      _typeSystemOperations,
    );
    String satisfied = _formatConstraints(
      isSatisfied(true),
      _typeSystemOperations,
    );

    assert(unsatisfied.isNotEmpty);
    if (satisfied.isNotEmpty) {
      satisfied = "\nThe type '$inferredStr' was inferred from:\n$satisfied";
    }

    return '\n\n$intro\n$unsatisfied$satisfied\n\n'
        'Consider passing explicit type argument(s) to the generic.\n\n';
  }

  /// Reports an inference failure on [errorEntity] according to its type.
  void _reportInferenceFailure({
    DiagnosticReporter? diagnosticReporter,
    SyntacticEntity? errorEntity,
    required bool genericMetadataIsEnabled,
  }) {
    if (diagnosticReporter == null || errorEntity == null) {
      return;
    }
    if (errorEntity is AstNode &&
        errorEntity.parent is InvocationExpression &&
        errorEntity.parent?.parent is AsExpression) {
      // Casts via `as` do not play a part in downward inference. We allow an
      // exception when inference has "failed" but the return value is
      // immediately cast with `as`.
      return;
    }
    if (errorEntity is ConstructorName &&
        !(errorEntity.type.type as InterfaceType)
            .element
            .metadata
            .hasOptionalTypeArgs) {
      String constructorName = errorEntity.name == null
          ? errorEntity.type.qualifiedName
          : '${errorEntity.type}.${errorEntity.name}';
      diagnosticReporter.atNode(
        errorEntity,
        WarningCode.inferenceFailureOnInstanceCreation,
        arguments: [constructorName],
      );
    } else if (errorEntity is Annotation) {
      if (genericMetadataIsEnabled) {
        // Only report an error if generic metadata is valid syntax.
        var element = errorEntity.name.element;
        if (element != null && !element.metadata.hasOptionalTypeArgs) {
          String constructorName = errorEntity.constructorName == null
              ? errorEntity.name.name
              : '${errorEntity.name.name}.${errorEntity.constructorName}';
          diagnosticReporter.atNode(
            errorEntity,
            WarningCode.inferenceFailureOnInstanceCreation,
            arguments: [constructorName],
          );
        }
      }
    } else if (errorEntity is SimpleIdentifier) {
      var element = errorEntity.element;
      if (element != null) {
        if (element is VariableElement) {
          // For variable elements, we check their type and possible alias type.
          var type = element.type;
          var typeElement = type is InterfaceType ? type.element : null;
          if (typeElement != null && typeElement.metadata.hasOptionalTypeArgs) {
            return;
          }
          var typeAliasElement = type.alias?.element;
          if (typeAliasElement != null &&
              typeAliasElement.metadata.hasOptionalTypeArgs) {
            return;
          }
        }
        if (!element.metadata.hasOptionalTypeArgs) {
          diagnosticReporter.atNode(
            errorEntity,
            WarningCode.inferenceFailureOnFunctionInvocation,
            arguments: [errorEntity.name],
          );
          return;
        }
      }
    } else if (errorEntity is Expression) {
      var type = errorEntity.staticType;
      if (type != null) {
        var typeDisplayString = _typeStr(type);
        diagnosticReporter.atNode(
          errorEntity,
          WarningCode.inferenceFailureOnGenericInvocation,
          arguments: [typeDisplayString],
        );
        return;
      }
    }
  }

  MergedTypeConstraint _squashConstraints(
    Iterable<MergedTypeConstraint> constraints,
  ) {
    TypeImpl lower = UnknownInferredType.instance;
    TypeImpl upper = UnknownInferredType.instance;
    TypeConstraintOrigin origin = UnknownTypeConstraintOrigin();

    for (var constraint in constraints) {
      // Given constraints:
      //
      //     L1 <: T <: U1
      //     L2 <: T <: U2
      //
      // These can be combined to produce:
      //
      //     LUB(L1, L2) <: T <: GLB(U1, U2).
      //
      // This can then be done for all constraints in sequence.
      //
      // This resulting constraint may be unsatisfiable; in that case inference
      // will fail.
      upper = _typeSystem.greatestLowerBound(
        upper,
        constraint.upper.unwrapTypeSchemaView(),
      );
      lower = _typeSystem.leastUpperBound(
        lower,
        constraint.lower.unwrapTypeSchemaView(),
      );
    }
    return MergedTypeConstraint(
      lower: SharedTypeSchemaView(lower),
      upper: SharedTypeSchemaView(upper),
      origin: origin,
    );
  }

  /// Tries to make [t1] a subtype of [t2] and accumulate constraints as needed.
  ///
  /// The return value indicates whether the match was successful.  If it was
  /// unsuccessful, any constraints that were accumulated during the match
  /// attempt have been rewound.
  bool _tryMatchSubtypeOf(
    TypeImpl t1,
    TypeImpl t2,
    TypeConstraintOrigin origin, {
    required bool covariant,
    required AstNodeImpl? nodeForTesting,
  }) {
    var gatherer = TypeConstraintGatherer(
      typeParameters: _typeParameters,
      typeSystemOperations: _typeSystemOperations,
      inferenceUsingBoundsIsEnabled: inferenceUsingBoundsIsEnabled,
      dataForTesting: dataForTesting,
    );
    var success = gatherer.performSubtypeConstraintGenerationInternal(
      t1,
      t2,
      leftSchema: !covariant,
      astNodeForTesting: nodeForTesting,
    );
    if (success) {
      var constraints = gatherer.computeConstraints();
      for (
        int typeParameterIndex = 0;
        typeParameterIndex < _typeParameters.length;
        typeParameterIndex++
      ) {
        var typeParameter = _typeParameters[typeParameterIndex];
        var constraint = constraints[typeParameter];
        if (constraint != null &&
            !constraint.isEmpty(_typeSystemOperations) &&
            _typesInferredSoFar[typeParameterIndex] ==
                UnknownInferredType.instance) {
          var existingConstraint = _constraints[typeParameter]!;
          existingConstraint.add(constraint..origin = origin);
          inferenceLogWriter?.recordGeneratedConstraint(
            typeParameter,
            constraint,
          );
        }
      }
    }

    return success;
  }

  String _typeStr(DartType type) {
    return type.getDisplayString();
  }

  static String _formatConstraints(
    Iterable<MergedTypeConstraint> constraints,
    TypeSystemOperations typeSystemOperations,
  ) {
    List<List<String>> lineParts = Set<TypeConstraintOrigin>.from(
      constraints.map((c) => c.origin),
    ).map((o) => o.formatError(typeSystemOperations)).toList();

    int prefixMax = lineParts.map((p) => p[0].length).fold(0, math.max);

    // Use a set to prevent identical message lines.
    // (It's not uncommon for the same constraint to show up in a few places.)
    var messageLines = Set<String>.from(
      lineParts.map((parts) {
        var prefix = parts[0];
        var middle = parts[1];
        var prefixPad = ' ' * (prefixMax - prefix.length);
        var middlePad = ' ' * prefixMax;
        var end = "";
        if (parts.length > 2) {
          end = '\n  $middlePad ${parts[2]}';
        }
        return '  $prefix$prefixPad $middle$end';
      }),
    );

    return messageLines.join('\n');
  }
}
