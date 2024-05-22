// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:_fe_analyzer_shared/src/type_inference/type_constraint.dart';
import 'package:analyzer/dart/ast/ast.dart'
    show
        Annotation,
        AsExpression,
        AstNode,
        ConstructorName,
        Expression,
        InvocationExpression,
        SimpleIdentifier;
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart' show ErrorReporter;
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_constraint_gatherer.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/error/codes.dart'
    show CompileTimeErrorCode, WarningCode;
import 'package:analyzer/src/utilities/extensions/collection.dart';

/// Tracks upper and lower type bounds for a set of type parameters.
///
/// This class is used by calling [isSubtypeOf]. When it encounters one of
/// the type parameters it is inferring, it will record the constraint, and
/// optimistically assume the constraint will be satisfied.
///
/// For example if we are inferring type parameter A, and we ask if
/// `A <: num`, this will record that A must be a subtype of `num`. It also
/// handles cases when A appears as part of the structure of another type, for
/// example `Iterable<A> <: Iterable<num>` would infer the same constraint
/// (due to covariant generic types) as would `() -> A <: () -> num`. In
/// contrast `(A) -> void <: (num) -> void`.
///
/// Once the lower/upper bounds are determined, [infer] should be called to
/// finish the inference. It will instantiate a generic function type with the
/// inferred types for each type parameter.
///
/// It can also optionally compute a partial solution, in case some of the type
/// parameters could not be inferred (because the constraints cannot be
/// satisfied), or bail on the inference when this happens.
///
/// As currently designed, an instance of this class should only be used to
/// infer a single call and discarded immediately afterwards.
class GenericInferrer {
  final TypeSystemImpl _typeSystem;
  final Set<TypeParameterElement> _typeParameters = Set.identity();
  final Map<
      TypeParameterElement,
      List<
          MergedTypeConstraint<
              DartType,
              DartType,
              TypeParameterElement,
              PromotableElement,
              InterfaceType,
              InterfaceElement>>> _constraints = {};

  /// The list of type parameters being inferred.
  final List<TypeParameterElement> _typeFormals;

  /// The [ErrorReporter] to which inference errors should be reported, or
  /// `null` if errors shouldn't be reported.
  final ErrorReporter? errorReporter;

  /// The [SyntacticEntity] to which errors should be attached.  May be `null`
  /// if errors are not being reported (that is, if [errorReporter] is also
  /// `null`).
  final SyntacticEntity? errorEntity;

  /// Indicates whether the "generic metadata" feature is enabled.  When it is,
  /// type arguments are allowed to be instantiated with generic function types.
  final bool genericMetadataIsEnabled;

  final bool _strictInference;

  /// Map whose keys are type parameters for which a previous inference phase
  /// has fixed a type, and whose values are the corresponding fixed types.
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
  final Map<TypeParameterElement, DartType> _typesInferredSoFar = {};

  final TypeSystemOperations _typeSystemOperations;

  final TypeConstraintGenerationDataForTesting? dataForTesting;

  GenericInferrer(this._typeSystem, this._typeFormals,
      {this.errorReporter,
      this.errorEntity,
      required this.genericMetadataIsEnabled,
      required bool strictInference,
      required TypeSystemOperations typeSystemOperations,
      required this.dataForTesting})
      : _strictInference = strictInference,
        _typeSystemOperations = typeSystemOperations {
    if (errorReporter != null) {
      assert(errorEntity != null);
    }
    _typeParameters.addAll(_typeFormals);
    for (var formal in _typeFormals) {
      _constraints[formal] = [];
    }
  }

  TypeProviderImpl get typeProvider => _typeSystem.typeProvider;

  /// Performs upwards inference, producing a final set of inferred types that
  /// does not  contain references to the "unknown type".
  List<DartType> chooseFinalTypes() => tryChooseFinalTypes(failAtError: false)!;

  /// Performs partial (either downwards or horizontal) inference, producing a
  /// set of inferred types that may contain references to the "unknown type".
  List<DartType> choosePreliminaryTypes() => _chooseTypes(preliminary: true);

  /// Apply an argument constraint, which asserts that the [argument] staticType
  /// is a subtype of the [parameterType].
  void constrainArgument(
      DartType argumentType, DartType parameterType, String parameterName,
      {InterfaceElement? genericClass, required AstNode? nodeForTesting}) {
    var origin = TypeConstraintFromArgument<
        DartType,
        DartType,
        PromotableElement,
        TypeParameterElement,
        InterfaceType,
        InterfaceElement>(
      argumentType: argumentType,
      parameterType: parameterType,
      parameterName: parameterName,
      genericClassName: genericClass?.name,
      isGenericClassInDartCore: genericClass?.library.isDartCore ?? false,
    );
    _tryMatchSubtypeOf(argumentType, parameterType, origin,
        covariant: false, nodeForTesting: nodeForTesting);
  }

  /// Applies all the argument constraints implied by [parameters] and
  /// [argumentTypes].
  void constrainArguments(
      {InterfaceElement? genericClass,
      required List<ParameterElement> parameters,
      required List<DartType> argumentTypes,
      required AstNode? nodeForTesting}) {
    for (int i = 0; i < argumentTypes.length; i++) {
      // Try to pass each argument to each parameter, recording any type
      // parameter bounds that were implied by this assignment.
      constrainArgument(
        argumentTypes[i],
        parameters[i].type,
        parameters[i].name,
        genericClass: genericClass,
        nodeForTesting: nodeForTesting,
      );
    }
  }

  /// Constrain a universal function type [fnType] used in a context
  /// [contextType].
  void constrainGenericFunctionInContext(
      FunctionType fnType, DartType contextType,
      {required AstNode? nodeForTesting}) {
    var origin = TypeConstraintFromFunctionContext<
        DartType,
        DartType,
        PromotableElement,
        TypeParameterElement,
        InterfaceType,
        InterfaceElement>(functionType: fnType, contextType: contextType);

    // Since we're trying to infer the instantiation, we want to ignore type
    // formals as we check the parameters and return type.
    var inferFnType = FunctionTypeImpl(
      typeFormals: const [],
      parameters: fnType.parameters,
      returnType: fnType.returnType,
      nullabilitySuffix: fnType.nullabilitySuffix,
    );
    _tryMatchSubtypeOf(inferFnType, contextType, origin,
        covariant: true, nodeForTesting: nodeForTesting);
  }

  /// Apply a return type constraint, which asserts that the [declaredType]
  /// is a subtype of the [contextType].
  void constrainReturnType(DartType declaredType, DartType contextType,
      {required AstNode? nodeForTesting}) {
    var origin = TypeConstraintFromReturnType<
        DartType,
        DartType,
        PromotableElement,
        TypeParameterElement,
        InterfaceType,
        InterfaceElement>(declaredType: declaredType, contextType: contextType);
    _tryMatchSubtypeOf(declaredType, contextType, origin,
        covariant: true, nodeForTesting: nodeForTesting);
  }

  /// Same as [chooseFinalTypes], but if [failAtError] is `true` (the default)
  /// and inference fails, returns `null` rather than trying to perform error
  /// recovery.
  List<DartType>? tryChooseFinalTypes({bool failAtError = true}) {
    var inferredTypes = _chooseTypes(preliminary: false);
    // Check the inferred types against all of the constraints.
    var knownTypes = <TypeParameterElement, DartType>{};
    var hasErrorReported = false;
    for (int i = 0; i < _typeFormals.length; i++) {
      TypeParameterElement parameter = _typeFormals[i];
      var constraints = _constraints[parameter]!;

      var inferred = inferredTypes[i];
      bool success = constraints
          .every((c) => c.isSatisfiedBy(inferred, _typeSystemOperations));

      // If everything else succeeded, check the `extends` constraint.
      if (success) {
        var parameterBoundRaw = parameter.bound;
        if (parameterBoundRaw != null) {
          var parameterBound =
              Substitution.fromPairs(_typeFormals, inferredTypes)
                  .substituteType(parameterBoundRaw);
          var extendsConstraint = MergedTypeConstraint<
              DartType,
              DartType,
              TypeParameterElement,
              PromotableElement,
              InterfaceType,
              InterfaceElement>.fromExtends(
            typeParameterName: parameter.name,
            boundType: parameterBoundRaw,
            extendsType: parameterBound,
            typeAnalyzerOperations: _typeSystemOperations,
          );
          constraints.add(extendsConstraint);
          success =
              extendsConstraint.isSatisfiedBy(inferred, _typeSystemOperations);
        }
      }

      if (!success) {
        if (failAtError) return null;
        hasErrorReported = true;
        errorReporter?.atEntity(
          errorEntity!,
          CompileTimeErrorCode.COULD_NOT_INFER,
          arguments: [
            parameter.name,
            _formatError(parameter, inferred, constraints)
          ],
        );

        // Heuristic: even if we failed, keep the erroneous type.
        // It should satisfy at least some of the constraints (e.g. the return
        // context). If we fall back to instantiateToBounds, we'll typically get
        // more errors (e.g. because `dynamic` is the most common bound).
      }

      if (inferred is FunctionType &&
          inferred.typeFormals.isNotEmpty &&
          !genericMetadataIsEnabled &&
          errorReporter != null) {
        if (failAtError) return null;
        hasErrorReported = true;
        var typeFormals = inferred.typeFormals;
        var typeFormalsStr = typeFormals.map(_elementStr).join(', ');
        errorReporter!.atEntity(
          errorEntity!,
          CompileTimeErrorCode.COULD_NOT_INFER,
          arguments: [
            parameter.name,
            ' Inferred candidate type ${_typeStr(inferred)} has type parameters'
                ' [$typeFormalsStr], but a function with'
                ' type parameters cannot be used as a type argument.'
          ],
        );
      }

      if (UnknownInferredType.isKnown(inferred)) {
        knownTypes[parameter] = inferred;
      } else if (_strictInference) {
        // [typeParam] could not be inferred. A result will still be returned
        // by [infer], with [typeParam] filled in as its bounds. This is
        // considered a failure of inference, under the "strict-inference"
        // mode.
        _reportInferenceFailure(
          errorReporter: errorReporter,
          errorEntity: errorEntity,
          genericMetadataIsEnabled: genericMetadataIsEnabled,
        );
      }
    }

    // Use instantiate to bounds to finish things off.
    var hasError = List<bool>.filled(_typeFormals.length, false);
    var result = _typeSystem.instantiateTypeFormalsToBounds(_typeFormals,
        hasError: hasError, knownTypes: knownTypes);

    // Report any errors from instantiateToBounds.
    for (int i = 0; i < hasError.length; i++) {
      if (hasError[i]) {
        if (failAtError) return null;
        hasErrorReported = true;
        TypeParameterElement typeParam = _typeFormals[i];
        var typeParamBound = Substitution.fromPairs(_typeFormals, inferredTypes)
            .substituteType(typeParam.bound ?? typeProvider.objectType);
        // TODO(jmesserly): improve this error message.
        errorReporter?.atEntity(
          errorEntity!,
          CompileTimeErrorCode.COULD_NOT_INFER,
          arguments: [
            typeParam.name,
            "\nRecursive bound cannot be instantiated: '$typeParamBound'."
                "\nConsider passing explicit type argument(s) "
                "to the generic.\n\n'"
          ],
        );
      }
    }

    if (!hasErrorReported) {
      _checkArgumentsNotMatchingBounds(
        errorEntity: errorEntity,
        errorReporter: errorReporter,
        typeArguments: result,
      );
    }

    _demoteTypes(result);
    return result;
  }

  /// Check that inferred [typeArguments] satisfy the [typeParameters] bounds.
  void _checkArgumentsNotMatchingBounds({
    required SyntacticEntity? errorEntity,
    required ErrorReporter? errorReporter,
    required List<DartType> typeArguments,
  }) {
    for (int i = 0; i < _typeFormals.length; i++) {
      var parameter = _typeFormals[i];
      var argument = typeArguments[i];

      var rawBound = parameter.bound;
      if (rawBound == null) {
        continue;
      }

      var substitution = Substitution.fromPairs(_typeFormals, typeArguments);
      var bound = substitution.substituteType(rawBound);
      if (!_typeSystem.isSubtypeOf(argument, bound)) {
        errorReporter?.atEntity(
          errorEntity!,
          CompileTimeErrorCode.COULD_NOT_INFER,
          arguments: [
            parameter.name,
            "\n'${_typeStr(argument)}' doesn't conform to "
                "the bound '${_typeStr(bound)}'"
                ", instantiated from '${_typeStr(rawBound)}'"
                " using type arguments ${typeArguments.map(_typeStr).toList()}.",
          ],
        );
      }
    }
  }

  /// Choose the bound that was implied by the return type, if any.
  ///
  /// Which bound this is depends on what positions the type parameter
  /// appears in. If the type only appears only in a contravariant position,
  /// we will choose the lower bound instead.
  ///
  /// For example given:
  ///
  ///     Func1<T, bool> makeComparer<T>(T x) => (T y) => x() == y;
  ///
  ///     main() {
  ///       Func1<num, bool> t = makeComparer/* infer <num> */(42);
  ///       print(t(42.0)); /// false, no error.
  ///     }
  ///
  /// The constraints we collect are:
  ///
  /// * `num <: T`
  /// * `int <: T`
  ///
  /// ... and no upper bound. Therefore the lower bound is the best choice.
  ///
  /// If [isContravariant] is `true`, then we are solving for a contravariant
  /// type parameter which means we choose the upper bound rather than the
  /// lower bound for normally covariant type parameters.
  DartType _chooseTypeFromConstraints(
      Iterable<
              MergedTypeConstraint<DartType, DartType, TypeParameterElement,
                  PromotableElement, InterfaceType, InterfaceElement>>
          constraints,
      {bool toKnownType = false,
      required bool isContravariant}) {
    DartType lower = UnknownInferredType.instance;
    DartType upper = UnknownInferredType.instance;
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
      upper = _typeSystem.greatestLowerBound(upper, constraint.upper);
      lower = _typeSystem.leastUpperBound(lower, constraint.lower);
    }

    // Prefer the known bound, if any.
    // Otherwise take whatever bound has partial information, e.g. `Iterable<?>`
    //
    // For both of those, prefer the lower bound (arbitrary heuristic) or upper
    // bound if [isContravariant] is `true`
    if (isContravariant) {
      if (UnknownInferredType.isKnown(upper)) {
        return upper;
      }
      if (UnknownInferredType.isKnown(lower)) {
        return lower;
      }
      if (!identical(UnknownInferredType.instance, upper)) {
        return toKnownType ? _typeSystem.greatestClosureOfSchema(upper) : upper;
      }
      if (!identical(UnknownInferredType.instance, lower)) {
        return toKnownType ? _typeSystem.leastClosureOfSchema(lower) : lower;
      }
      return upper;
    } else {
      if (UnknownInferredType.isKnown(lower)) {
        return lower;
      }
      if (UnknownInferredType.isKnown(upper)) {
        return upper;
      }
      if (!identical(UnknownInferredType.instance, lower)) {
        return toKnownType ? _typeSystem.leastClosureOfSchema(lower) : lower;
      }
      if (!identical(UnknownInferredType.instance, upper)) {
        return toKnownType ? _typeSystem.greatestClosureOfSchema(upper) : upper;
      }
      return lower;
    }
  }

  /// Computes (or recomputes) a set of [inferredTypes] based on the constraints
  /// that have been recorded so far.
  List<DartType> _chooseTypes({required bool preliminary}) {
    var inferredTypes = List<DartType>.filled(
        _typeFormals.length, UnknownInferredType.instance);
    for (int i = 0; i < _typeFormals.length; i++) {
      // TODO(kallentu): : Clean up TypeParameterElementImpl casting once
      // variance is added to the interface.
      var typeParam = _typeFormals[i] as TypeParameterElementImpl;
      MergedTypeConstraint<DartType, DartType, TypeParameterElement,
          PromotableElement, InterfaceType, InterfaceElement>? extendsClause;
      var bound = typeParam.bound;
      if (bound != null) {
        extendsClause = MergedTypeConstraint<
            DartType,
            DartType,
            TypeParameterElement,
            PromotableElement,
            InterfaceType,
            InterfaceElement>.fromExtends(
          typeParameterName: typeParam.name,
          boundType: bound,
          extendsType: Substitution.fromPairs(_typeFormals, inferredTypes)
              .substituteType(bound),
          typeAnalyzerOperations: _typeSystemOperations,
        );
      }

      var constraints = _constraints[typeParam]!;
      var previouslyInferredType = _typesInferredSoFar[typeParam];
      if (previouslyInferredType != null) {
        inferredTypes[i] = previouslyInferredType;
      } else if (preliminary) {
        var inferredType = _inferTypeParameterFromContext(
            constraints, extendsClause,
            isContravariant: typeParam.variance.isContravariant);
        inferredTypes[i] = inferredType;
        if (typeParam.isLegacyCovariant &&
            UnknownInferredType.isKnown(inferredType)) {
          _typesInferredSoFar[typeParam] = inferredType;
        }
      } else {
        inferredTypes[i] = _inferTypeParameterFromAll(
            constraints, extendsClause,
            isContravariant: typeParam.variance.isContravariant);
      }
    }

    return inferredTypes;
  }

  void _demoteTypes(List<DartType> types) {
    for (var i = 0; i < types.length; i++) {
      types[i] = _typeSystem.demoteType(types[i]);
    }
  }

  String _elementStr(Element element) {
    return element.getDisplayString();
  }

  String _formatError(
      TypeParameterElement typeParam,
      DartType inferred,
      Iterable<
              MergedTypeConstraint<DartType, DartType, TypeParameterElement,
                  PromotableElement, InterfaceType, InterfaceElement>>
          constraints) {
    var inferredStr = inferred.getDisplayString();
    var intro = "Tried to infer '$inferredStr' for '${typeParam.name}'"
        " which doesn't work:";

    var constraintsByOrigin = <TypeConstraintOrigin<
            DartType,
            DartType,
            PromotableElement,
            TypeParameterElement,
            InterfaceType,
            InterfaceElement>,
        List<
            MergedTypeConstraint<DartType, DartType, TypeParameterElement,
                PromotableElement, InterfaceType, InterfaceElement>>>{};
    for (var c in constraints) {
      constraintsByOrigin.putIfAbsent(c.origin, () => []).add(c);
    }

    // Only report unique constraint origins.
    Iterable<
        MergedTypeConstraint<
            DartType,
            DartType,
            TypeParameterElement,
            PromotableElement,
            InterfaceType,
            InterfaceElement>> isSatisfied(bool expected) => constraintsByOrigin
        .values
        .where((l) =>
            l.every((c) => c.isSatisfiedBy(inferred, _typeSystemOperations)) ==
            expected)
        .flattenedToList2;

    String unsatisfied =
        _formatConstraints(isSatisfied(false), _typeSystemOperations);
    String satisfied =
        _formatConstraints(isSatisfied(true), _typeSystemOperations);

    assert(unsatisfied.isNotEmpty);
    if (satisfied.isNotEmpty) {
      satisfied = "\nThe type '$inferredStr' was inferred from:\n$satisfied";
    }

    return '\n\n$intro\n$unsatisfied$satisfied\n\n'
        'Consider passing explicit type argument(s) to the generic.\n\n';
  }

  DartType _inferTypeParameterFromAll(
      List<
              MergedTypeConstraint<DartType, DartType, TypeParameterElement,
                  PromotableElement, InterfaceType, InterfaceElement>>
          constraints,
      MergedTypeConstraint<DartType, DartType, TypeParameterElement,
              PromotableElement, InterfaceType, InterfaceElement>?
          extendsClause,
      {required bool isContravariant}) {
    if (extendsClause != null) {
      constraints = constraints.toList()..add(extendsClause);
    }

    var choice = _chooseTypeFromConstraints(constraints,
        toKnownType: true, isContravariant: isContravariant);
    return choice;
  }

  DartType _inferTypeParameterFromContext(
      Iterable<
              MergedTypeConstraint<DartType, DartType, TypeParameterElement,
                  PromotableElement, InterfaceType, InterfaceElement>>
          constraints,
      MergedTypeConstraint<DartType, DartType, TypeParameterElement,
              PromotableElement, InterfaceType, InterfaceElement>?
          extendsClause,
      {required bool isContravariant}) {
    DartType t = _chooseTypeFromConstraints(constraints,
        isContravariant: isContravariant);
    if (UnknownInferredType.isUnknown(t)) {
      return t;
    }

    // If we're about to make our final choice, apply the extends clause.
    // This gives us a chance to refine the choice, in case it would violate
    // the `extends` clause. For example:
    //
    //     Object obj = math.min/*<infer Object, error>*/(1, 2);
    //
    // If we consider the `T extends num` we conclude `<num>`, which works.
    if (extendsClause != null) {
      constraints = constraints.toList()..add(extendsClause);
      return _chooseTypeFromConstraints(constraints,
          isContravariant: isContravariant);
    }
    return t;
  }

  /// Reports an inference failure on [errorEntity] according to its type.
  void _reportInferenceFailure({
    ErrorReporter? errorReporter,
    SyntacticEntity? errorEntity,
    required bool genericMetadataIsEnabled,
  }) {
    if (errorReporter == null || errorEntity == null) {
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
        !(errorEntity.type.type as InterfaceType).element.hasOptionalTypeArgs) {
      String constructorName = errorEntity.name == null
          ? errorEntity.type.qualifiedName
          : '${errorEntity.type}.${errorEntity.name}';
      errorReporter.atNode(
        errorEntity,
        WarningCode.INFERENCE_FAILURE_ON_INSTANCE_CREATION,
        arguments: [constructorName],
      );
    } else if (errorEntity is Annotation) {
      if (genericMetadataIsEnabled) {
        // Only report an error if generic metadata is valid syntax.
        var element = errorEntity.name.staticElement;
        if (element != null && !element.hasOptionalTypeArgs) {
          String constructorName = errorEntity.constructorName == null
              ? errorEntity.name.name
              : '${errorEntity.name.name}.${errorEntity.constructorName}';
          errorReporter.atNode(
            errorEntity,
            WarningCode.INFERENCE_FAILURE_ON_INSTANCE_CREATION,
            arguments: [constructorName],
          );
        }
      }
    } else if (errorEntity is SimpleIdentifier) {
      var element = errorEntity.staticElement;
      if (element != null) {
        if (element is VariableElement) {
          // For variable elements, we check their type and possible alias type.
          var type = element.type;
          var typeElement = type is InterfaceType ? type.element : null;
          if (typeElement != null && typeElement.hasOptionalTypeArgs) {
            return;
          }
          var typeAliasElement = type.alias?.element;
          if (typeAliasElement != null &&
              typeAliasElement.hasOptionalTypeArgs) {
            return;
          }
        }
        if (!element.hasOptionalTypeArgs) {
          errorReporter.atNode(
            errorEntity,
            WarningCode.INFERENCE_FAILURE_ON_FUNCTION_INVOCATION,
            arguments: [errorEntity.name],
          );
          return;
        }
      }
    } else if (errorEntity is Expression) {
      var type = errorEntity.staticType;
      if (type != null) {
        var typeDisplayString = _typeStr(type);
        errorReporter.atNode(
          errorEntity,
          WarningCode.INFERENCE_FAILURE_ON_GENERIC_INVOCATION,
          arguments: [typeDisplayString],
        );
        return;
      }
    }
  }

  /// Tries to make [i1] a subtype of [i2] and accumulate constraints as needed.
  ///
  /// The return value indicates whether the match was successful.  If it was
  /// unsuccessful, any constraints that were accumulated during the match
  /// attempt have been rewound (see [_rewindConstraints]).
  bool _tryMatchSubtypeOf(
      DartType t1,
      DartType t2,
      TypeConstraintOrigin<DartType, DartType, PromotableElement,
              TypeParameterElement, InterfaceType, InterfaceElement>
          origin,
      {required bool covariant,
      required AstNode? nodeForTesting}) {
    var gatherer = TypeConstraintGatherer(
        typeSystem: _typeSystem,
        typeParameters: _typeParameters,
        typeSystemOperations: _typeSystemOperations,
        dataForTesting: dataForTesting);
    var success = gatherer.trySubtypeMatch(t1, t2, !covariant,
        nodeForTesting: nodeForTesting);
    if (success) {
      var constraints = gatherer.computeConstraints();
      for (var entry in constraints.entries) {
        if (!entry.value.isEmpty(_typeSystemOperations) &&
            !_typesInferredSoFar.containsKey(entry.key)) {
          var constraint = _constraints[entry.key]!;
          constraint.add(entry.value..origin = origin);
        }
      }
    }

    return success;
  }

  String _typeStr(DartType type) {
    return type.getDisplayString();
  }

  static String _formatConstraints(
      Iterable<
              MergedTypeConstraint<DartType, DartType, TypeParameterElement,
                  PromotableElement, InterfaceType, InterfaceElement>>
          constraints,
      TypeSystemOperations typeSystemOperations) {
    List<List<String>> lineParts = Set<
            TypeConstraintOrigin<
                DartType,
                DartType,
                PromotableElement,
                TypeParameterElement,
                InterfaceType,
                InterfaceElement>>.from(constraints.map((c) => c.origin))
        .map((o) => o.formatError(typeSystemOperations))
        .toList();

    int prefixMax = lineParts.map((p) => p[0].length).fold(0, math.max);

    // Use a set to prevent identical message lines.
    // (It's not uncommon for the same constraint to show up in a few places.)
    var messageLines = Set<String>.from(lineParts.map((parts) {
      var prefix = parts[0];
      var middle = parts[1];
      var prefixPad = ' ' * (prefixMax - prefix.length);
      var middlePad = ' ' * prefixMax;
      var end = "";
      if (parts.length > 2) {
        end = '\n  $middlePad ${parts[2]}';
      }
      return '  $prefix$prefixPad $middle$end';
    }));

    return messageLines.join('\n');
  }
}
