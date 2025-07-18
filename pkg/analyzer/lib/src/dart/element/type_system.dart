// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart' show AstNode;
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart' show TokenType;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/error/listener.dart' show DiagnosticReporter;
import 'package:analyzer/src/dart/ast/ast.dart' show AstNodeImpl;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/generic_inferrer.dart';
import 'package:analyzer/src/dart/element/greatest_lower_bound.dart';
import 'package:analyzer/src/dart/element/least_greatest_closure.dart';
import 'package:analyzer/src/dart/element/least_upper_bound.dart';
import 'package:analyzer/src/dart/element/normalize.dart';
import 'package:analyzer/src/dart/element/replace_top_bottom_visitor.dart';
import 'package:analyzer/src/dart/element/replacement_visitor.dart';
import 'package:analyzer/src/dart/element/runtime_type_equality.dart';
import 'package:analyzer/src/dart/element/subtype.dart';
import 'package:analyzer/src/dart/element/top_merge.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_constraint_gatherer.dart';
import 'package:analyzer/src/dart/element/type_demotion.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_schema_elimination.dart';
import 'package:analyzer/src/dart/element/well_bounded.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/generated/inference_log.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:meta/meta.dart';

class ExtensionTypeErasure extends ReplacementVisitor {
  const ExtensionTypeErasure();

  TypeImpl perform(TypeImpl type) {
    return type.accept(this) ?? type;
  }

  @override
  TypeImpl? visitInterfaceType(covariant InterfaceTypeImpl type) {
    if (type.representationType case var representationType?) {
      var erased = representationType.accept(this) ?? representationType;
      // If the extension type is nullable, apply it to the erased.
      if (type.nullabilitySuffix == NullabilitySuffix.question) {
        return erased.withNullability(NullabilitySuffix.question);
      }
      // Use the erased as is, still might be nullable.
      return erased;
    }

    return super.visitInterfaceType(type);
  }
}

/// Fresh type parameters created to unify two lists of type parameters.
class RelatedTypeParameters2 {
  static final _empty = RelatedTypeParameters2._(const [], const []);

  final List<TypeParameterElementImpl> typeParameters;
  final List<TypeParameterTypeImpl> typeParameterTypes;

  RelatedTypeParameters2._(this.typeParameters, this.typeParameterTypes);
}

/// The [TypeSystem] implementation.
class TypeSystemImpl implements TypeSystem {
  /// The provider of types for the system.
  final TypeProviderImpl typeProvider;

  /// The cached instance of `Object?`.
  InterfaceTypeImpl? _objectQuestion;

  /// The cached instance of `Object!`.
  InterfaceTypeImpl? _objectNone;

  /// The cached instance of `Null!`.
  InterfaceTypeImpl? _nullNone;

  late final GreatestLowerBoundHelper _greatestLowerBoundHelper;
  late final LeastUpperBoundHelper _leastUpperBoundHelper;

  /// The implementation of the subtyping relation.
  late final SubtypeHelper _subtypeHelper;

  TypeSystemImpl({required TypeProvider typeProvider})
    : typeProvider = typeProvider as TypeProviderImpl {
    _greatestLowerBoundHelper = GreatestLowerBoundHelper(this);
    _leastUpperBoundHelper = LeastUpperBoundHelper(this);
    _subtypeHelper = SubtypeHelper(this);
  }

  InterfaceTypeImpl get nullNone =>
      _nullNone ??= typeProvider.nullType.withNullability(
        NullabilitySuffix.none,
      );

  InterfaceTypeImpl get objectNone =>
      _objectNone ??= typeProvider.objectType.withNullability(
        NullabilitySuffix.none,
      );

  InterfaceTypeImpl get objectQuestion =>
      _objectQuestion ??= typeProvider.objectType.withNullability(
        NullabilitySuffix.question,
      );

  /// Returns true iff the type [t] accepts function types, and requires an
  /// implicit coercion if interface types with a `call` method are passed in.
  ///
  /// This is true for:
  /// - all function types
  /// - the special type `Function` that is a supertype of all function types
  /// - `FutureOr<T>` where T is one of the two cases above.
  ///
  /// Note that this returns false if [t] is a top type such as Object.
  bool acceptsFunctionType(DartType t) {
    if (t.isDartAsyncFutureOr) {
      return acceptsFunctionType((t as InterfaceType).typeArguments[0]);
    }
    return t is FunctionType || t.isDartCoreFunction;
  }

  /// Checks if an instance of [left] could possibly also be an instance of
  /// [right]. For example, an instance of `num` could be `int`, so
  /// canBeSubtypeOf(`num`, `int`) would return `true`, even though `num` is
  /// not a subtype of `int`. More generally, we check if there could be a
  /// type that implements both [left] and [right], regardless of whether
  /// [left] is a subtype of [right], or [right] is a subtype of [left].
  ///
  /// If [eraseTypes] is not null, this function uses that function to erase the
  /// extension types within [left] and [right]. Otherwise, it uses the
  /// extension type erasure.
  bool canBeSubtypeOf(
    TypeImpl left,
    TypeImpl right, {
    (TypeImpl, TypeImpl) Function(TypeImpl, TypeImpl)? eraseTypes,
  }) {
    (left, right) =
        eraseTypes != null
            ? eraseTypes(left, right)
            : (left.extensionTypeErasure, right.extensionTypeErasure);

    // If one is `Null`, then the other must be nullable.
    var leftIsNullable = isPotentiallyNullable(left);
    var rightIsNullable = isPotentiallyNullable(right);
    if (left.isDartCoreNull) {
      return rightIsNullable;
    } else if (right.isDartCoreNull) {
      return leftIsNullable;
    }

    // If none is `Null`, but both are nullable, they match at `Null`.
    if (leftIsNullable && rightIsNullable) {
      return true;
    }

    // Could be `void Function() vs. Object`.
    // Could be `void Function() vs. Function`.
    if (left is FunctionTypeImpl && right is InterfaceTypeImpl) {
      return right.isDartCoreFunction || right.isDartCoreObject;
    }

    // Could be `Object vs. void Function()`.
    // Could be `Function vs. void Function()`.
    if (left is InterfaceTypeImpl && right is FunctionTypeImpl) {
      return left.isDartCoreFunction || left.isDartCoreObject;
    }

    // FutureOr<T> = T || Future<T>
    // So, we attempt to match both to the right.
    if (left.isDartAsyncFutureOr) {
      var base = futureOrBase(left);
      var future = typeProvider.futureType(base);
      return canBeSubtypeOf(base, right, eraseTypes: eraseTypes) ||
          canBeSubtypeOf(future, right, eraseTypes: eraseTypes);
    }

    // FutureOr<T> = T || Future<T>
    // So, we attempt to match both to the left.
    if (right.isDartAsyncFutureOr) {
      var base = futureOrBase(right);
      var future = typeProvider.futureType(base);
      return canBeSubtypeOf(left, base, eraseTypes: eraseTypes) ||
          canBeSubtypeOf(left, future, eraseTypes: eraseTypes);
    }

    if (left is InterfaceTypeImpl && right is InterfaceTypeImpl) {
      var leftElement = left.element;
      var rightElement = right.element;

      // Can happen in JavaScript.
      if (left.isDartCoreInt && right.isDartCoreDouble ||
          left.isDartCoreDouble && right.isDartCoreInt) {
        return true;
      }

      bool canBeSubtypeOfInterfaces(
        InterfaceTypeImpl left,
        InterfaceTypeImpl right,
      ) {
        assert(left.element == right.element);
        var leftArguments = left.typeArguments;
        var rightArguments = right.typeArguments;
        assert(leftArguments.length == rightArguments.length);
        for (var i = 0; i < leftArguments.length; i++) {
          if (!canBeSubtypeOf(
            leftArguments[i],
            rightArguments[i],
            eraseTypes: eraseTypes,
          )) {
            return false;
          }
        }
        return true;
      }

      // If the left is enum, we know types of all its instances.
      if (leftElement is EnumElementImpl) {
        for (var constant in leftElement.constants) {
          var constantType = constant.type;
          if (isSubtypeOf(constantType, right)) {
            return true;
          }
        }
        return false;
      }

      if (leftElement == rightElement) {
        return canBeSubtypeOfInterfaces(left, right);
      }

      if (leftElement is ClassElementImpl) {
        // If we know all subtypes, only they can implement the right.
        var allSubtypes = leftElement.allSubtypes;
        if (allSubtypes != null) {
          for (var candidate in [left, ...allSubtypes]) {
            var asRight = candidate.asInstanceOf(rightElement);
            if (asRight != null) {
              if (_canBeEqualArguments(asRight, right)) {
                return true;
              }
            }
          }
          return false;
        }
      }

      if (rightElement is ClassElementImpl) {
        // If we know all subtypes, only they can implement the left.
        var allSubtypes = rightElement.allSubtypes;
        if (allSubtypes != null) {
          for (var candidate in [right, ...allSubtypes]) {
            var asLeft = candidate.asInstanceOf(leftElement);
            if (asLeft != null) {
              if (canBeSubtypeOfInterfaces(left, asLeft)) {
                return true;
              }
            }
          }
          return false;
        }
      }
    }

    if (left is RecordType) {
      if (right is FunctionType) {
        return false;
      }
      if (right is InterfaceType) {
        return right.isDartCoreObject || right.isDartCoreRecord;
      }
    }

    if (right is RecordType) {
      if (left is FunctionType) {
        return false;
      }
      if (left is InterfaceType) {
        return left.isDartCoreObject || left.isDartCoreRecord;
      }
    }

    if (left is RecordTypeImpl && right is RecordTypeImpl) {
      if (left.positionalFields.length != right.positionalFields.length) {
        return false;
      }
      for (var i = 0; i < left.positionalFields.length; i++) {
        var leftField = left.positionalFields[i];
        var rightField = right.positionalFields[i];
        if (!canBeSubtypeOf(
          leftField.type,
          rightField.type,
          eraseTypes: eraseTypes,
        )) {
          return false;
        }
      }

      if (left.namedFields.length != right.namedFields.length) {
        return false;
      }
      for (var i = 0; i < left.namedFields.length; i++) {
        var leftField = left.namedFields[i];
        var rightField = right.namedFields[i];
        if (leftField.name != rightField.name) {
          return false;
        }
        if (!canBeSubtypeOf(
          leftField.type,
          rightField.type,
          eraseTypes: eraseTypes,
        )) {
          return false;
        }
      }
    }

    return true;
  }

  /// Returns [type] in which all promoted type variables have been replaced
  /// with their unpromoted equivalents, and, if non-nullable by default,
  /// replaces all legacy types with their non-nullable equivalents.
  TypeImpl demoteType(TypeImpl type) {
    var visitor = const DemotionVisitor();
    return type.accept(visitor) ?? type;
  }

  /// Eliminates type variables from the context [type], replacing them with
  /// `Null` or `Object` as appropriate.
  ///
  /// For example in `List<T> list = const []`, the context type for inferring
  /// the list should be changed from `List<T>` to `List<Null>` so the constant
  /// doesn't depend on the type variables `T` (because it can't be
  /// canonicalized at compile time, as `T` is unknown).
  ///
  /// Conceptually this is similar to the "least closure", except instead of
  /// eliminating `_` ([UnknownInferredType]) it eliminates all type variables
  /// ([TypeParameterType]).
  ///
  /// The equivalent CFE code can be found in the `TypeVariableEliminator`
  /// class.
  TypeImpl eliminateTypeVariables(DartType type) {
    return _TypeVariableEliminator(
      objectQuestion,
      NeverTypeImpl.instance,
    ).substituteType(type);
  }

  /// Defines the "remainder" of `T` when `S` has been removed from
  /// consideration by an instance check.  This operation is used for type
  /// promotion during flow analysis.
  TypeImpl factor(TypeImpl T, TypeImpl S) {
    // * If T <: S then Never
    if (isSubtypeOf(T, S)) {
      return NeverTypeImpl.instance;
    }

    var T_nullability = T.nullabilitySuffix;

    // * Else if T is R? and Null <: S then factor(R, S)
    // * Else if T is R? then factor(R, S)?
    if (T_nullability == NullabilitySuffix.question) {
      var R = T.withNullability(NullabilitySuffix.none);
      var factor_RS = factor(R, S);
      if (isSubtypeOf(nullNone, S)) {
        return factor_RS;
      } else {
        return factor_RS.withNullability(NullabilitySuffix.question);
      }
    }

    // * Else if T is FutureOr<R> and Future<R> <: S then factor(R, S)
    // * Else if T is FutureOr<R> and R <: S then factor(Future<R>, S)
    if (T is InterfaceTypeImpl && T.isDartAsyncFutureOr) {
      var R = T.typeArguments[0];
      var future_R = typeProvider.futureType(R);
      if (isSubtypeOf(future_R, S)) {
        return factor(R, S);
      }
      if (isSubtypeOf(R, S)) {
        return factor(future_R, S);
      }
    }

    return T;
  }

  @override
  TypeImpl flatten(covariant TypeImpl T) {
    if (identical(T, UnknownInferredType.instance)) {
      return T;
    }

    // if T is S? then flatten(T) = flatten(S)?
    var nullabilitySuffix = T.nullabilitySuffix;
    if (nullabilitySuffix != NullabilitySuffix.none) {
      var S = T.withNullability(NullabilitySuffix.none);
      return flatten(S).withNullability(nullabilitySuffix);
    }

    // If T is X & S for some type variable X and type S then:
    if (T is TypeParameterTypeImpl) {
      var S = T.promotedBound;
      if (S != null) {
        // * if S has future type U then flatten(T) = flatten(U)
        var futureType = this.futureType(S);
        if (futureType != null) {
          return flatten(futureType);
        }
        // * otherwise, flatten(T) = flatten(X)
        return flatten(
          TypeParameterTypeImpl(
            element: T.element,
            nullabilitySuffix: nullabilitySuffix,
          ),
        );
      }
    }

    // If T has future type Future<S> or FutureOr<S> then flatten(T) = S
    // If T has future type Future<S>? or FutureOr<S>? then flatten(T) = S?
    var futureType = this.futureType(T);
    if (futureType is InterfaceTypeImpl) {
      if (futureType.isDartAsyncFuture || futureType.isDartAsyncFutureOr) {
        var S = futureType.typeArguments[0];
        if (futureType.nullabilitySuffix == NullabilitySuffix.question) {
          return S.withNullability(NullabilitySuffix.question);
        }
        return S;
      }
    }

    // otherwise flatten(T) = T
    return T;
  }

  TypeImpl futureOrBase(TypeImpl type) {
    // If `T` is `FutureOr<S>` for some `S`,
    // then `futureOrBase(T)` = `futureOrBase(S)`
    if (type is InterfaceTypeImpl && type.isDartAsyncFutureOr) {
      return futureOrBase(type.typeArguments[0]);
    }

    // Otherwise `futureOrBase(T)` = `T`.
    return type;
  }

  /// We say that S is the future type of a type T in the following cases,
  /// using the first applicable case:
  @visibleForTesting
  TypeImpl? futureType(TypeImpl T) {
    // T implements S, and there is a U such that S is Future<U>
    if (T.nullabilitySuffix != NullabilitySuffix.question) {
      var result = T.asInstanceOf(typeProvider.futureElement);
      if (result != null) {
        return result;
      }
    }

    // T is S bounded, and there is a U such that S is FutureOr<U>,
    // Future<U>?, or FutureOr<U>?.
    return _futureTypeOfBounded(T);
  }

  /// Compute "future value type" of [T].
  ///
  /// https://github.com/dart-lang/language/
  /// See `nnbd/feature-specification.md`
  /// See `#the-future-value-type-of-an-asynchronous-non-generator-function`
  TypeImpl futureValueType(TypeImpl T) {
    // futureValueType(`S?`) = futureValueType(`S`), for all `S`.
    if (T.nullabilitySuffix != NullabilitySuffix.none) {
      var S = T.withNullability(NullabilitySuffix.none);
      return futureValueType(S);
    }

    // futureValueType(Future<`S`>) = `S`, for all `S`.
    // futureValueType(FutureOr<`S`>) = `S`, for all `S`.
    if (T is InterfaceTypeImpl) {
      if (T.isDartAsyncFuture || T.isDartAsyncFutureOr) {
        return T.typeArguments[0];
      }
    }

    // futureValueType(`dynamic`) = `dynamic`.
    if (identical(T, DynamicTypeImpl.instance)) {
      return T;
    }

    // futureValueType(`void`) = `void`.
    if (identical(T, VoidTypeImpl.instance)) {
      return T;
    }

    // Otherwise, for all `S`, futureValueType(`S`) = `Object?`.
    return objectQuestion;
  }

  List<InterfaceTypeImpl> gatherMixinSupertypeConstraintsForInference(
    InterfaceElementImpl mixinElement,
  ) {
    List<InterfaceTypeImpl> candidates;
    if (mixinElement is MixinElementImpl) {
      candidates = mixinElement.superclassConstraints;
    } else {
      var supertype = mixinElement.supertype;
      if (supertype == null) {
        return const [];
      }
      candidates = [supertype];
      candidates.addAll(mixinElement.mixins);
      if (mixinElement is ClassElementImpl && mixinElement.isMixinApplication) {
        candidates.removeLast();
      }
    }
    return candidates
        .where((type) => type.element.typeParameters.isNotEmpty)
        .toList();
  }

  /// Given a type [t], if [t] is an interface type with a `call` method
  /// defined, return the function type for the `call` method, otherwise return
  /// `null`.
  ///
  /// This does not find extension methods (which are not defined on an
  /// interface type); it is meant to find implicit call references.
  FunctionTypeImpl? getCallMethodType(DartType t) {
    if (t is InterfaceTypeImpl) {
      return t
          .lookUpMethod(MethodElement.CALL_METHOD_NAME, t.element.library)
          ?.type;
    }
    return null;
  }

  /// Computes the set of free type parameters appearing in [rootType].
  ///
  /// If a non-null [candidates] set is given, then only type parameters
  /// appearing in it are considered; otherwise all type parameters are
  /// considered.
  List<TypeParameterElement>? getFreeParameters(
    DartType rootType, {
    Set<TypeParameterElement>? candidates,
  }) {
    List<TypeParameterElement>? parameters;
    Set<DartType> visitedTypes = HashSet<DartType>();
    Set<TypeParameterElement> boundTypeParameters =
        HashSet<TypeParameterElement>();

    void appendParameters(DartType? type) {
      if (type == null) {
        return;
      }
      if (visitedTypes.contains(type)) {
        return;
      }
      visitedTypes.add(type);
      if (type is TypeParameterType) {
        var element = type.element;
        if ((candidates == null || candidates.contains(element)) &&
            !boundTypeParameters.contains(element)) {
          parameters ??= <TypeParameterElement>[];
          parameters!.add(element);
        }
      } else if (type is FunctionType) {
        assert(
          !type.typeParameters.any((t) => boundTypeParameters.contains(t)),
        );
        boundTypeParameters.addAll(type.typeParameters);
        appendParameters(type.returnType);
        type.formalParameters.map((p) => p.type).forEach(appendParameters);
        // TODO(scheglov): https://github.com/dart-lang/sdk/issues/44218
        type.alias?.typeArguments.forEach(appendParameters);
        boundTypeParameters.removeAll(type.typeParameters);
      } else if (type is InterfaceType) {
        type.typeArguments.forEach(appendParameters);
      } else if (type is RecordType) {
        type.positionalFields.map((f) => f.type).forEach(appendParameters);
        type.namedFields.map((f) => f.type).forEach(appendParameters);
      }
    }

    appendParameters(rootType);
    return parameters;
  }

  /// Returns the greatest closure of [type] with respect to [typeParameters].
  ///
  /// https://github.com/dart-lang/language
  /// See `resources/type-system/inference.md`
  TypeImpl greatestClosure(
    TypeImpl type,
    List<TypeParameterElementImpl> typeParameters,
  ) {
    var typeParameterSet = Set<TypeParameterElementImpl>.identity();
    typeParameterSet.addAll(typeParameters);

    return LeastGreatestClosureHelper(
      typeSystem: this,
      topType: objectQuestion,
      topFunctionType: typeProvider.functionType,
      bottomType: NeverTypeImpl.instance,
      eliminationTargets: typeParameterSet,
    ).eliminateToGreatest(type);
  }

  /// Returns the greatest closure of the given type [schema] with respect to
  /// `_`.
  ///
  /// The greatest closure of a type schema `P` with respect to `_` is defined
  /// as `P` with every covariant occurrence of `_` replaced with `Null`, and
  /// every contravariant occurrence of `_` replaced with `Object`.
  ///
  /// If the schema contains no instances of `_`, the original schema object is
  /// returned to avoid unnecessary allocation.
  ///
  /// Note that the closure of a type schema is a proper type.
  ///
  /// Note that the greatest closure of a type schema is always a supertype of
  /// any type which matches the schema.
  TypeImpl greatestClosureOfSchema(TypeImpl schema) {
    return TypeSchemaEliminationVisitor.run(
      topType: objectQuestion,
      bottomType: NeverTypeImpl.instance,
      isLeastClosure: false,
      schema: schema,
    );
  }

  @override
  TypeImpl greatestLowerBound(covariant TypeImpl T1, covariant TypeImpl T2) {
    // TODO(paulberry): make these casts unnecessary by changing the type of
    // `T1` and `T2`.
    return _greatestLowerBoundHelper.getGreatestLowerBound(T1, T2);
  }

  /// Given a generic function type `F<T0, T1, ... Tn>` and a context type C,
  /// infer an instantiation of F, such that `F<S0, S1, ..., Sn>` <: C.
  ///
  /// This is similar to [setupGenericTypeInference], but the return type is
  /// also considered as part of the solution.
  List<TypeImpl> inferFunctionTypeInstantiation(
    FunctionTypeImpl contextType,
    FunctionTypeImpl fnType, {
    DiagnosticReporter? diagnosticReporter,
    AstNode? errorNode,
    required TypeSystemOperations typeSystemOperations,
    required bool genericMetadataIsEnabled,
    required bool inferenceUsingBoundsIsEnabled,
    required bool strictInference,
    required bool strictCasts,
    required TypeConstraintGenerationDataForTesting? dataForTesting,
    required AstNodeImpl? nodeForTesting,
  }) {
    if (contextType.typeParameters.isNotEmpty ||
        fnType.typeParameters.isEmpty) {
      return const <TypeImpl>[];
    }

    inferenceLogWriter?.enterGenericInference(fnType.typeParameters, fnType);
    // Create a TypeSystem that will allow certain type parameters to be
    // inferred. It will optimistically assume these type parameters can be
    // subtypes (or supertypes) as necessary, and track the constraints that
    // are implied by this.
    var inferrer = GenericInferrer(
      this,
      fnType.typeParameters,
      diagnosticReporter: diagnosticReporter,
      errorEntity: errorNode,
      genericMetadataIsEnabled: genericMetadataIsEnabled,
      inferenceUsingBoundsIsEnabled: inferenceUsingBoundsIsEnabled,
      strictInference: strictInference,
      typeSystemOperations: typeSystemOperations,
      dataForTesting: dataForTesting,
    );
    inferrer.constrainGenericFunctionInContext(
      fnType,
      contextType,
      nodeForTesting: nodeForTesting,
    );

    // Infer and instantiate the resulting type.
    return inferrer.chooseFinalTypes();
  }

  @override
  InterfaceTypeImpl instantiateInterfaceToBounds({
    required covariant InterfaceElementImpl element,
    required NullabilitySuffix nullabilitySuffix,
  }) {
    var typeParameters = element.typeParameters;
    var typeArguments = _defaultTypeArguments(typeParameters);
    return element.instantiateImpl(
      typeArguments: typeArguments,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  @Deprecated('Use instantiateInterfaceToBounds instead')
  @override
  InterfaceTypeImpl instantiateInterfaceToBounds2({
    required covariant InterfaceElementImpl element,
    required NullabilitySuffix nullabilitySuffix,
  }) {
    return instantiateInterfaceToBounds(element: element, nullabilitySuffix: nullabilitySuffix);
  }

  /// Given a [DartType] [type] and a list of types
  /// [typeArguments], instantiate the type formals with the
  /// provided actuals.  If [type] is not a parameterized type,
  /// no instantiation is done.
  DartType instantiateType(DartType type, List<TypeImpl> typeArguments) {
    if (type is FunctionType) {
      return type.instantiate(typeArguments);
    } else if (type is InterfaceTypeImpl) {
      // TODO(scheglov): Use `ClassElement.instantiate()`, don't use raw types.
      return type.element.instantiateImpl(
        typeArguments: typeArguments,
        nullabilitySuffix: type.nullabilitySuffix,
      );
    } else {
      return type;
    }
  }

  @override
  TypeImpl instantiateTypeAliasToBounds({
    required covariant TypeAliasElementImpl element,
    required NullabilitySuffix nullabilitySuffix,
  }) {
    var typeParameters = element.typeParameters;
    var typeArguments = _defaultTypeArguments(typeParameters);
    return element.instantiateImpl(
      typeArguments: typeArguments,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  @Deprecated('Use instantiateTypeAliasToBounds instead')
  @override
  TypeImpl instantiateTypeAliasToBounds2({
    required covariant TypeAliasElementImpl element,
    required NullabilitySuffix nullabilitySuffix,
  }) {
    return instantiateTypeAliasToBounds(element: element, nullabilitySuffix: nullabilitySuffix);
  }

  /// Given uninstantiated [typeFormals], instantiate them to their bounds.
  /// See the issue for the algorithm description.
  ///
  /// https://github.com/dart-lang/sdk/issues/27526#issuecomment-260021397
  List<TypeImpl> instantiateTypeFormalsToBounds(
    List<TypeParameterElementImpl> typeParameters, {
    List<bool>? hasError,
    Map<TypeParameterElement, TypeImpl>? knownTypes,
  }) {
    int count = typeParameters.length;
    if (count == 0) {
      return const <TypeImpl>[];
    }

    Set<TypeParameterElement> all = <TypeParameterElement>{};
    // all ground
    Map<TypeParameterElement, TypeImpl> defaults = knownTypes ?? {};
    // not ground
    Map<TypeParameterElement, TypeImpl> partials = {};

    for (var typeParameter in typeParameters) {
      all.add(typeParameter);
      if (!defaults.containsKey(typeParameter)) {
        var bound = typeParameter.bound ?? DynamicTypeImpl.instance;
        partials[typeParameter] = bound;
      }
    }

    bool hasProgress = true;
    while (hasProgress) {
      hasProgress = false;
      for (TypeParameterElement parameter in partials.keys) {
        var value = partials[parameter]!;
        var freeParameters = getFreeParameters(value, candidates: all);
        if (freeParameters == null) {
          defaults[parameter] = value;
          partials.remove(parameter);
          hasProgress = true;
          break;
        } else if (freeParameters.every(defaults.containsKey)) {
          defaults[parameter] = Substitution.fromMap(
            defaults,
          ).substituteType(value);
          partials.remove(parameter);
          hasProgress = true;
          break;
        }
      }
    }

    // If we stopped making progress, and not all types are ground,
    // then the whole type is malbounded and an error should be reported
    // if errors are requested, and a partially completed type should
    // be returned.
    if (partials.isNotEmpty) {
      if (hasError != null) {
        hasError[0] = true;
      }
      var domain = defaults.keys.toList();
      var range = defaults.values.toList();
      // Build a substitution Phi mapping each uncompleted type variable to
      // dynamic, and each completed type variable to its default.
      for (TypeParameterElement parameter in partials.keys) {
        domain.add(parameter);
        range.add(DynamicTypeImpl.instance);
      }
      // Set the default for an uncompleted type variable (T extends B)
      // to be Phi(B)
      for (TypeParameterElement parameter in partials.keys) {
        defaults[parameter] = Substitution.fromPairs2(
          domain,
          range,
        ).substituteType(partials[parameter]!);
      }
    }

    List<TypeImpl> orderedArguments =
        typeParameters.map((p) => defaults[p]!).toFixedList();
    return orderedArguments;
  }

  /// https://github.com/dart-lang/language
  /// accepted/future-releases/0546-patterns/feature-specification.md#exhaustiveness-and-reachability
  bool isAlwaysExhaustive(DartType type) {
    if (type is InterfaceType) {
      if (type.isDartCoreBool) {
        return true;
      }
      if (type.isDartCoreNull) {
        return true;
      }
      var element = type.element;
      if (element is EnumElement) {
        return true;
      }
      if (element is ClassElement && element.isSealed) {
        return true;
      }
      if (element is ExtensionTypeElement) {
        return isAlwaysExhaustive(type.extensionTypeErasure);
      }
      if (type.isDartAsyncFutureOr) {
        return isAlwaysExhaustive(type.typeArguments[0]);
      }
      return false;
    } else if (type is TypeParameterTypeImpl) {
      var promotedBound = type.promotedBound;
      if (promotedBound != null && isAlwaysExhaustive(promotedBound)) {
        return true;
      }
      var bound = type.element.bound;
      if (bound != null && isAlwaysExhaustive(bound)) {
        return true;
      }
      return false;
    } else if (type is RecordType) {
      for (var field in type.fields) {
        if (!isAlwaysExhaustive(field.type)) {
          return false;
        }
      }
      return true;
    } else {
      return false;
    }
  }

  @override
  bool isAssignableTo(
    covariant TypeImpl fromType,
    covariant TypeImpl toType, {
    bool strictCasts = false,
  }) {
    // An actual subtype
    if (isSubtypeOf(fromType, toType)) {
      return true;
    }

    // Accept the invalid type, we have already reported an error for it.
    if (fromType is InvalidType) {
      return true;
    }

    // A 'call' method tearoff.
    if (fromType is InterfaceTypeImpl &&
        !isNullable(fromType) &&
        acceptsFunctionType(toType)) {
      var callMethodType = getCallMethodType(fromType);
      if (callMethodType != null &&
          isAssignableTo(callMethodType, toType, strictCasts: strictCasts)) {
        return true;
      }
    }

    // First make sure that the static analysis option, `strict-casts: true`
    // disables all downcasts, including casts from `dynamic`.
    if (strictCasts) {
      return false;
    }

    // Now handle NNBD default behavior, where we disable non-dynamic downcasts.
    return fromType is DynamicType;
  }

  /// A dynamic bounded type is either `dynamic` itself, or a type variable
  /// whose bound is dynamic bounded, or an intersection (promoted type
  /// parameter type) whose second operand is dynamic bounded.
  bool isDynamicBounded(DartType type) {
    if (identical(type, DynamicTypeImpl.instance)) {
      return true;
    }

    if (type is TypeParameterTypeImpl) {
      var bound = type.element.bound;
      if (bound != null && isDynamicBounded(bound)) {
        return true;
      }

      var promotedBound = type.promotedBound;
      if (promotedBound != null && isDynamicBounded(promotedBound)) {
        return true;
      }
    }

    return false;
  }

  /// Check if [left] is equal to [right].
  ///
  /// Implements:
  /// https://github.com/dart-lang/language
  /// See `resources/type-system/subtyping.md#type-equality`
  bool isEqualTo(TypeImpl left, TypeImpl right) {
    return isSubtypeOf(left, right) && isSubtypeOf(right, left);
  }

  /// A function bounded type is either `Function` itself, or a type variable
  /// whose bound is function bounded, or an intersection (promoted type
  /// parameter type) whose second operand is function bounded.
  bool isFunctionBounded(DartType type) {
    if (type is FunctionType) {
      return type.nullabilitySuffix != NullabilitySuffix.question;
    }

    if (type is InterfaceType && type.isDartCoreFunction) {
      return type.nullabilitySuffix != NullabilitySuffix.question;
    }

    if (type is TypeParameterTypeImpl) {
      var bound = type.element.bound;
      if (bound != null && isFunctionBounded(bound)) {
        return true;
      }

      var promotedBound = type.promotedBound;
      if (promotedBound != null && isFunctionBounded(promotedBound)) {
        return true;
      }
    }

    return false;
  }

  /// We say that a type `T` is _incompatible with await_ if at least
  /// one of the following criteria holds:
  bool isIncompatibleWithAwait(TypeImpl T) {
    // `T` is `S?`, and `S` is incompatible with await.
    if (T.nullabilitySuffix == NullabilitySuffix.question) {
      var T_none = T.withNullability(NullabilitySuffix.none);
      return isIncompatibleWithAwait(T_none);
    }

    // `T` is an extension type that does not implement `Future`.
    if (T.element is ExtensionTypeElement) {
      var anyFuture = typeProvider.futureType(objectQuestion);
      if (!isSubtypeOf(T, anyFuture)) {
        return true;
      }
    }

    if (T is TypeParameterTypeImpl) {
      // `T` is `X & B`, and `B` is incompatible with await.
      if (T.promotedBound case var B?) {
        return isIncompatibleWithAwait(B);
      }
      // `T` is a type variable with bound `S`, and `S` is incompatible
      // with await.
      if (T.element.bound case var S?) {
        return isIncompatibleWithAwait(S);
      }
    }

    return false;
  }

  /// Either [InvalidType] itself, or an intersection with it.
  bool isInvalidBounded(DartType type) {
    if (identical(type, InvalidTypeImpl.instance)) {
      return true;
    }

    if (type is TypeParameterTypeImpl) {
      var bound = type.element.bound;
      if (bound != null && isInvalidBounded(bound)) {
        return true;
      }

      var promotedBound = type.promotedBound;
      if (promotedBound != null && isInvalidBounded(promotedBound)) {
        return true;
      }
    }

    return false;
  }

  /// Defines an (almost) total order on bottom and `Null` types. This does not
  /// currently consistently order two different type variables with the same
  /// bound.
  bool isMoreBottom(TypeImpl T, TypeImpl S) {
    var T_nullability = T.nullabilitySuffix;
    var S_nullability = S.nullabilitySuffix;

    // MOREBOTTOM(Never, T) = true
    if (identical(T, NeverTypeImpl.instance)) {
      return true;
    }

    // MOREBOTTOM(T, Never) = false
    if (identical(S, NeverTypeImpl.instance)) {
      return false;
    }

    // MOREBOTTOM(Null, T) = true
    if (T_nullability == NullabilitySuffix.none && T.isDartCoreNull) {
      return true;
    }

    // MOREBOTTOM(T, Null) = false
    if (S_nullability == NullabilitySuffix.none && S.isDartCoreNull) {
      return false;
    }

    // MOREBOTTOM(T?, S?) = MOREBOTTOM(T, S)
    if (T_nullability == NullabilitySuffix.question &&
        S_nullability == NullabilitySuffix.question) {
      var T2 = T.withNullability(NullabilitySuffix.none);
      var S2 = S.withNullability(NullabilitySuffix.none);
      return isMoreBottom(T2, S2);
    }

    // MOREBOTTOM(T, S?) = true
    if (S_nullability == NullabilitySuffix.question) {
      return true;
    }

    // MOREBOTTOM(T?, S) = false
    if (T_nullability == NullabilitySuffix.question) {
      return false;
    }

    // Type parameters.
    if (T is TypeParameterTypeImpl && S is TypeParameterTypeImpl) {
      // We have eliminated the possibility that T_nullability or S_nullability
      // is anything except none by this point.
      assert(T_nullability == NullabilitySuffix.none);
      assert(S_nullability == NullabilitySuffix.none);
      var T_element = T.element;
      var S_element = S.element;

      // MOREBOTTOM(X&T, Y&S) = MOREBOTTOM(T, S)
      var T_promotedBound = T.promotedBound;
      var S_promotedBound = S.promotedBound;
      if (T_promotedBound != null && S_promotedBound != null) {
        return isMoreBottom(T_promotedBound, S_promotedBound);
      }

      // MOREBOTTOM(X&T, S) = true
      if (T_promotedBound != null) {
        return true;
      }

      // MOREBOTTOM(T, Y&S) = false
      if (S_promotedBound != null) {
        return false;
      }

      // MOREBOTTOM(X extends T, Y extends S) = MOREBOTTOM(T, S)
      // The invariant of the larger algorithm that this is only called with
      // types that satisfy `BOTTOM(T)` or `NULL(T)`, and all such types, if
      // they are type variables, have bounds which themselves are
      // `BOTTOM` or `NULL` types.
      var T_bound = T_element.bound!;
      var S_bound = S_element.bound!;
      return isMoreBottom(T_bound, S_bound);
    }

    return false;
  }

  /// Defines a total order on top and Object types.
  bool isMoreTop(TypeImpl T, TypeImpl S) {
    var T_nullability = T.nullabilitySuffix;
    var S_nullability = S.nullabilitySuffix;

    // MORETOP(void, S) = true
    if (identical(T, VoidTypeImpl.instance)) {
      return true;
    }

    // MORETOP(T, void) = false
    if (identical(S, VoidTypeImpl.instance)) {
      return false;
    }

    // MORETOP(dynamic, S) = true
    if (identical(T, DynamicTypeImpl.instance) ||
        identical(T, InvalidTypeImpl.instance)) {
      return true;
    }

    // MORETOP(T, dynamic) = false
    if (identical(S, DynamicTypeImpl.instance) ||
        identical(S, InvalidTypeImpl.instance)) {
      return false;
    }

    // MORETOP(Object, S) = true
    if (T_nullability == NullabilitySuffix.none && T.isDartCoreObject) {
      return true;
    }

    // MORETOP(T, Object) = false
    if (S_nullability == NullabilitySuffix.none && S.isDartCoreObject) {
      return false;
    }

    // MORETOP(T?, S?) = MORETOP(T, S)
    if (T_nullability == NullabilitySuffix.question &&
        S_nullability == NullabilitySuffix.question) {
      var T2 = T.withNullability(NullabilitySuffix.none);
      var S2 = S.withNullability(NullabilitySuffix.none);
      return isMoreTop(T2, S2);
    }

    // MORETOP(T, S?) = true
    if (S_nullability == NullabilitySuffix.question) {
      return true;
    }

    // MORETOP(T?, S) = false
    if (T_nullability == NullabilitySuffix.question) {
      return false;
    }

    // MORETOP(FutureOr<T>, FutureOr<S>) = MORETOP(T, S)
    if (T is InterfaceTypeImpl &&
        T.isDartAsyncFutureOr &&
        S is InterfaceTypeImpl &&
        S.isDartAsyncFutureOr) {
      assert(T_nullability == NullabilitySuffix.none);
      assert(S_nullability == NullabilitySuffix.none);
      var T2 = T.typeArguments[0];
      var S2 = S.typeArguments[0];
      return isMoreTop(T2, S2);
    }

    return false;
  }

  @override
  bool isNonNullable(DartType type) {
    if (type is DynamicType ||
        type is InvalidType ||
        type is UnknownInferredType ||
        type is VoidType ||
        type.isDartCoreNull) {
      return false;
    } else if (type is TypeParameterTypeImpl && type.promotedBound != null) {
      return isNonNullable(type.promotedBound!);
    } else if (type.nullabilitySuffix == NullabilitySuffix.question) {
      return false;
    } else if (type is InterfaceTypeImpl) {
      if (type.isDartAsyncFutureOr) {
        return isNonNullable(type.typeArguments[0]);
      }
      if (type.element is ExtensionTypeElement) {
        return type.interfaces.isNotEmpty;
      }
    } else if (type is TypeParameterType) {
      var bound = type.element.bound;
      return bound != null && isNonNullable(bound);
    }
    return true;
  }

  /// Return `true` for things in the equivalence class of `Null`.
  bool isNull(TypeImpl type) {
    var nullabilitySuffix = type.nullabilitySuffix;

    // NULL(Null) is true
    // Also includes `Null?` from the rules below.
    if (type.isDartCoreNull) {
      return true;
    }

    // NULL(T?) is true iff NULL(T) or BOTTOM(T)
    // The case for `Null?` is already checked above.
    if (nullabilitySuffix == NullabilitySuffix.question) {
      var T = type.withNullability(NullabilitySuffix.none);
      return T.isBottom;
    }

    // NULL(T) is false otherwise
    return false;
  }

  @override
  bool isNullable(DartType type) {
    if (type is DynamicType ||
        type is InvalidType ||
        type is UnknownInferredType ||
        type is VoidType ||
        type.isDartCoreNull) {
      return true;
    } else if (type is TypeParameterTypeImpl && type.promotedBound != null) {
      return isNullable(type.promotedBound!);
    } else if (type.nullabilitySuffix == NullabilitySuffix.question) {
      return true;
    } else if (type is InterfaceTypeImpl) {
      if (type.isDartAsyncFutureOr) {
        return isNullable(type.typeArguments[0]);
      }
    }
    return false;
  }

  /// Return `true` for any type which is in the equivalence class of `Object`.
  bool isObject(TypeImpl type) {
    if (type.nullabilitySuffix != NullabilitySuffix.none) {
      return false;
    }

    // OBJECT(Object) is true
    if (type.isDartCoreObject) {
      return true;
    }

    // OBJECT(FutureOr<T>) is OBJECT(T)
    if (type is InterfaceTypeImpl && type.isDartAsyncFutureOr) {
      var T = type.typeArguments[0];
      return isObject(T);
    }

    // OBJECT(T) is false otherwise
    return false;
  }

  @override
  bool isPotentiallyNonNullable(DartType type) => !isNullable(type);

  @override
  bool isPotentiallyNullable(DartType type) => !isNonNullable(type);

  @override
  bool isStrictlyNonNullable(DartType type) {
    if (type is DynamicType ||
        type is InvalidType ||
        type is UnknownInferredType ||
        type is VoidType ||
        type.isDartCoreNull) {
      return false;
    } else if (type.nullabilitySuffix != NullabilitySuffix.none) {
      return false;
    } else if (type is InterfaceTypeImpl) {
      if (type.isDartAsyncFutureOr) {
        return isStrictlyNonNullable(type.typeArguments[0]);
      }
      if (type.element is ExtensionTypeElement) {
        return type.interfaces.isNotEmpty;
      }
    } else if (type is TypeParameterType) {
      return isStrictlyNonNullable(type.bound);
    }
    return true;
  }

  /// Check if [leftType] is a subtype of [rightType].
  ///
  /// Implements:
  /// https://github.com/dart-lang/language
  /// See `resources/type-system/subtyping.md`
  @override
  bool isSubtypeOf(covariant TypeImpl leftType, covariant TypeImpl rightType) {
    return _subtypeHelper.isSubtypeOf(leftType, rightType);
  }

  /// Return `true` for any type which is in the equivalence class of top types.
  bool isTop(TypeImpl type) {
    // TOP(?) is true
    if (identical(type, UnknownInferredType.instance)) {
      return true;
    }

    // TOP(dynamic) is true
    if (identical(type, DynamicTypeImpl.instance) ||
        identical(type, InvalidTypeImpl.instance)) {
      return true;
    }

    // TOP(void) is true
    if (identical(type, VoidTypeImpl.instance)) {
      return true;
    }

    var nullabilitySuffix = type.nullabilitySuffix;

    // TOP(T?) is true iff TOP(T) or OBJECT(T)
    if (nullabilitySuffix == NullabilitySuffix.question) {
      var T = type.withNullability(NullabilitySuffix.none);
      return isTop(T) || isObject(T);
    }

    // TOP(FutureOr<T>) is TOP(T)
    if (type is InterfaceTypeImpl && type.isDartAsyncFutureOr) {
      assert(nullabilitySuffix == NullabilitySuffix.none);
      var T = type.typeArguments[0];
      return isTop(T);
    }

    // TOP(T) is false otherwise
    return false;
  }

  /// Whether [type] is a valid superinterface for an extension type.
  bool isValidExtensionTypeSuperinterface(DartType type) {
    if (type is! InterfaceType) {
      return false;
    }

    if (type.nullabilitySuffix == NullabilitySuffix.question) {
      return false;
    }

    if (type.isDartAsyncFutureOr ||
        type.isDartCoreFunction ||
        type.isDartCoreNull ||
        type.isDartCoreRecord) {
      return false;
    }

    return true;
  }

  /// See `15.2 Super-bounded types` in the language specification.
  TypeBoundedResult isWellBounded(
    TypeImpl type, {
    required bool allowSuperBounded,
  }) {
    return TypeBoundedHelper(
      this,
    ).isWellBounded(type, allowSuperBounded: allowSuperBounded);
  }

  /// Returns the least closure of [type] with respect to [typeParameters].
  ///
  /// https://github.com/dart-lang/language
  /// See `resources/type-system/inference.md`
  TypeImpl leastClosure(
    TypeImpl type,
    List<TypeParameterElementImpl> typeParameters,
  ) {
    var typeParameterSet = Set<TypeParameterElementImpl>.identity();
    typeParameterSet.addAll(typeParameters);

    return LeastGreatestClosureHelper(
      typeSystem: this,
      topType: objectQuestion,
      topFunctionType: typeProvider.functionType,
      bottomType: NeverTypeImpl.instance,
      eliminationTargets: typeParameterSet,
    ).eliminateToLeast(type);
  }

  /// Returns the least closure of the given type [schema] with respect to `_`.
  ///
  /// The least closure of a type schema `P` with respect to `_` is defined as
  /// `P` with every covariant occurrence of `_` replaced with `Object`, an
  /// every contravariant occurrence of `_` replaced with `Null`.
  ///
  /// If the schema contains no instances of `_`, the original schema object is
  /// returned to avoid unnecessary allocation.
  ///
  /// Note that the closure of a type schema is a proper type.
  ///
  /// Note that the least closure of a type schema is always a subtype of any
  /// type which matches the schema.
  TypeImpl leastClosureOfSchema(TypeImpl schema) {
    return TypeSchemaEliminationVisitor.run(
      topType: objectQuestion,
      bottomType: NeverTypeImpl.instance,
      isLeastClosure: true,
      schema: schema,
    );
  }

  @override
  TypeImpl leastUpperBound(covariant TypeImpl T1, covariant TypeImpl T2) {
    return _leastUpperBoundHelper.getLeastUpperBound(T1, T2);
  }

  /// Returns a nullable version of [type].  The result would be equivalent to
  /// the union `type | Null` (if we supported union types).
  TypeImpl makeNullable(TypeImpl type) {
    return type.withNullability(NullabilitySuffix.question);
  }

  /// Attempts to find the appropriate substitution for the [typeParameters]
  /// that can be applied to [srcTypes] to make it equal to [destTypes].
  /// If no such substitution can be found, `null` is returned.
  List<TypeImpl>? matchSupertypeConstraints(
    List<TypeParameterElementImpl> typeParameters,
    List<TypeImpl> srcTypes,
    List<TypeImpl> destTypes, {
    required TypeSystemOperations typeSystemOperations,
    required bool genericMetadataIsEnabled,
    required bool inferenceUsingBoundsIsEnabled,
    required bool strictInference,
    required bool strictCasts,
  }) {
    var inferrer = GenericInferrer(
      this,
      typeParameters,
      genericMetadataIsEnabled: genericMetadataIsEnabled,
      inferenceUsingBoundsIsEnabled: inferenceUsingBoundsIsEnabled,
      strictInference: strictInference,
      typeSystemOperations: typeSystemOperations,
      dataForTesting: null,
    );
    for (int i = 0; i < srcTypes.length; i++) {
      inferrer.constrainReturnType(
        srcTypes[i],
        destTypes[i],
        nodeForTesting: null,
      );
      inferrer.constrainReturnType(
        destTypes[i],
        srcTypes[i],
        nodeForTesting: null,
      );
    }

    var inferredTypes =
        inferrer
            .chooseFinalTypes()
            .map(_removeBoundsOfGenericFunctionTypes)
            .toFixedList();
    var substitution = Substitution.fromPairs2(typeParameters, inferredTypes);

    for (int i = 0; i < srcTypes.length; i++) {
      var srcType = substitution.substituteType(srcTypes[i]);
      var destType = destTypes[i];
      if (srcType != destType) {
        // Failed to find an appropriate substitution
        return null;
      }
    }

    return inferredTypes;
  }

  /// Compute the canonical representation of [T].
  ///
  /// https://github.com/dart-lang/language
  /// See `resources/type-system/normalization.md`
  TypeImpl normalize(TypeImpl T) {
    return NormalizeHelper(this).normalize(T);
  }

  FunctionTypeImpl normalizeFunctionType(FunctionTypeImpl T) {
    return NormalizeHelper(this).normalizeFunctionType(T);
  }

  InterfaceTypeImpl normalizeInterfaceType(InterfaceTypeImpl T) {
    return NormalizeHelper(this).normalizeInterfaceType(T);
  }

  /// Returns a non-nullable version of [type].  This is equivalent to the
  /// operation `NonNull` defined in the spec.
  @override
  TypeImpl promoteToNonNull(covariant TypeImpl type) {
    if (type.isDartCoreNull) return NeverTypeImpl.instance;

    if (type is TypeParameterTypeImpl) {
      var element = type.element;

      // NonNull(X & T) = X & NonNull(T)
      if (type.promotedBound != null) {
        var promotedBound = promoteToNonNull(type.promotedBound!);
        return TypeParameterTypeImpl(
          element: element,
          nullabilitySuffix: NullabilitySuffix.none,
          promotedBound: promotedBound,
        );
      }

      // NonNull(X) = X & NonNull(B), where B is the bound of X
      DartType? promotedBound =
          element.bound != null
              ? promoteToNonNull(element.bound!)
              : typeProvider.objectType;
      if (identical(promotedBound, element.bound)) {
        promotedBound = null;
      }
      return TypeParameterTypeImpl(
        element: element,
        nullabilitySuffix: NullabilitySuffix.none,
        promotedBound: promotedBound,
      );
    }

    return type.withNullability(NullabilitySuffix.none);
  }

  /// Determine the type of a binary expression with the given [operator] whose
  /// left operand has the type [leftType] and whose right operand has the type
  /// [rightType], given that resolution has so far produced the [currentType].
  TypeImpl refineBinaryExpressionType(
    TypeImpl leftType,
    TokenType operator,
    TypeImpl rightType,
    TypeImpl currentType,
    MethodElement? operatorElement,
  ) {
    if (operatorElement == null) return currentType;
    return _refineNumericInvocationTypeNullSafe(leftType, operatorElement, [
      rightType,
    ], currentType);
  }

  /// Determines the context type for the parameters of a method invocation
  /// where the type of the target is [targetType], the method being invoked is
  /// [methodElement], the context surrounding the method invocation is
  /// [invocationContext], and the context type produced so far by resolution is
  /// [currentType].
  TypeImpl refineNumericInvocationContext(
    TypeImpl? targetType,
    Element? methodElement,
    TypeImpl invocationContext,
    TypeImpl currentType,
  ) {
    if (targetType != null && methodElement is MethodElement) {
      return _refineNumericInvocationContextNullSafe(
        targetType,
        methodElement,
        invocationContext,
        currentType,
      );
    } else {
      // No special rules apply.
      return currentType;
    }
  }

  /// Determines the type of a method invocation where the type of the target is
  /// [targetType], the method being invoked is [methodElement], the types of
  /// the arguments passed to the method are [argumentTypes], and the type
  /// produced so far by resolution is [currentType].
  ///
  // TODO(scheglov): I expected that [methodElement] is [MethodElement].
  TypeImpl refineNumericInvocationType(
    TypeImpl targetType,
    Element? methodElement,
    List<TypeImpl> argumentTypes,
    TypeImpl currentType,
  ) {
    if (methodElement is MethodElement) {
      return _refineNumericInvocationTypeNullSafe(
        targetType,
        methodElement,
        argumentTypes,
        currentType,
      );
    } else {
      // No special rules apply.
      return currentType;
    }
  }

  /// Given two lists of type parameters, check that they have the same
  /// number of elements, and their bounds are equal.
  ///
  /// The return value will be a new list of fresh type parameters, that can
  /// be used to instantiate both function types, allowing further comparison.
  RelatedTypeParameters2? relateTypeParameters(
    List<TypeParameterElementImpl> typeParameters1,
    List<TypeParameterElementImpl> typeParameters2,
  ) {
    if (typeParameters1.length != typeParameters2.length) {
      return null;
    }
    if (typeParameters1.isEmpty) {
      return RelatedTypeParameters2._empty;
    }

    var length = typeParameters1.length;
    var freshTypeParameters = List.generate(length, (index) {
      return typeParameters1[index].freshCopy();
    }, growable: false);

    var freshTypeParameterTypes = List.generate(length, (index) {
      return freshTypeParameters[index].instantiate(
        nullabilitySuffix: NullabilitySuffix.none,
      );
    }, growable: false);

    var substitution1 = Substitution.fromPairs2(
      typeParameters1,
      freshTypeParameterTypes,
    );
    var substitution2 = Substitution.fromPairs2(
      typeParameters2,
      freshTypeParameterTypes,
    );

    for (var i = 0; i < typeParameters1.length; i++) {
      var bound1 = typeParameters1[i].bound;
      var bound2 = typeParameters2[i].bound;
      if (bound1 == null && bound2 == null) {
        continue;
      }
      bound1 ??= DynamicTypeImpl.instance;
      bound2 ??= DynamicTypeImpl.instance;
      bound1 = substitution1.substituteType(bound1);
      bound2 = substitution2.substituteType(bound2);
      if (!isEqualTo(bound1, bound2)) {
        return null;
      }

      if (bound1 is! DynamicType) {
        freshTypeParameters[i].bound = bound1;
      }
    }

    return RelatedTypeParameters2._(
      freshTypeParameters,
      freshTypeParameterTypes,
    );
  }

  /// Replaces all covariant occurrences of `dynamic`, `void`, and `Object` or
  /// `Object?` with `Null` or `Never` and all contravariant occurrences of
  /// `Null` or `Never` with `Object` or `Object?`.
  TypeImpl replaceTopAndBottom(TypeImpl dartType) {
    return ReplaceTopBottomVisitor.run(
      topType: objectQuestion,
      bottomType: NeverTypeImpl.instance,
      typeSystem: this,
      type: dartType,
    );
  }

  @override
  TypeImpl resolveToBound(covariant TypeImpl type) {
    if (type is TypeParameterTypeImpl) {
      var promotedBound = type.promotedBound;
      if (promotedBound != null) {
        return resolveToBound(promotedBound);
      }

      var bound = type.element.bound;
      if (bound == null) {
        return objectQuestion;
      }

      var resolved = resolveToBound(bound);

      var newNullabilitySuffix = uniteNullabilities(
        uniteNullabilities(type.nullabilitySuffix, bound.nullabilitySuffix),
        resolved.nullabilitySuffix,
      );

      return resolved.withNullability(newNullabilitySuffix);
    }

    return type;
  }

  /// Return `true` if runtime types [T1] and [T2] are equal.
  ///
  /// nnbd/feature-specification.md#runtime-type-equality-operator
  bool runtimeTypesEqual(TypeImpl T1, TypeImpl T2) {
    return RuntimeTypeEqualityHelper(this).equal(T1, T2);
  }

  /// Prepares to infer type arguments for a generic type, function, method, or
  /// list/map literal, initializing a [GenericInferrer] using the downward
  /// context type.
  GenericInferrer setupGenericTypeInference({
    required List<TypeParameterElementImpl> typeParameters,
    required TypeImpl declaredReturnType,
    required TypeImpl contextReturnType,
    DiagnosticReporter? diagnosticReporter,
    SyntacticEntity? errorEntity,
    required bool genericMetadataIsEnabled,
    required bool inferenceUsingBoundsIsEnabled,
    bool isConst = false,
    required bool strictInference,
    required bool strictCasts,
    required TypeSystemOperations typeSystemOperations,
    required TypeConstraintGenerationDataForTesting? dataForTesting,
    required AstNodeImpl? nodeForTesting,
  }) {
    // Create a GenericInferrer that will allow certain type parameters to be
    // inferred. It will optimistically assume these type parameters can be
    // subtypes (or supertypes) as necessary, and track the constraints that
    // are implied by this.
    var inferrer = GenericInferrer(
      this,
      typeParameters,
      diagnosticReporter: diagnosticReporter,
      errorEntity: errorEntity,
      genericMetadataIsEnabled: genericMetadataIsEnabled,
      inferenceUsingBoundsIsEnabled: inferenceUsingBoundsIsEnabled,
      strictInference: strictInference,
      typeSystemOperations: typeSystemOperations,
      dataForTesting: dataForTesting,
    );

    if (isConst) {
      contextReturnType = eliminateTypeVariables(contextReturnType);
    }
    inferrer.constrainReturnType(
      declaredReturnType,
      contextReturnType,
      nodeForTesting: nodeForTesting,
    );

    return inferrer;
  }

  /// Merges two types into a single type.
  /// Compute the canonical representation of [T].
  ///
  /// https://github.com/dart-lang/language/
  /// See `accepted/future-releases/nnbd/feature-specification.md`
  /// See `#classes-defined-in-opted-in-libraries`
  TypeImpl topMerge(TypeImpl T, TypeImpl S) {
    return TopMergeHelper(this).topMerge(T, S);
  }

  /// Tries to promote from the first type from the second type, and returns the
  /// promoted type if it succeeds, otherwise null.
  TypeImpl? tryPromoteToType(TypeImpl to, TypeImpl from) {
    // Allow promoting to a subtype, for example:
    //
    //     f(Base b) {
    //       if (b is SubTypeOfBase) {
    //         // promote `b` to SubTypeOfBase for this block
    //       }
    //     }
    //
    // This allows the variable to be used wherever the supertype (here `Base`)
    // is expected, while gaining a more precise type.
    if (isSubtypeOf(to, from)) {
      return to;
    }
    // For a type parameter `T extends U`, allow promoting the upper bound
    // `U` to `S` where `S <: U`, yielding a type parameter `T extends S`.
    if (from is TypeParameterTypeImpl) {
      if (isSubtypeOf(to, from.bound)) {
        var declaration = from.element.baseElement;
        return TypeParameterTypeImpl(
          element: declaration,
          nullabilitySuffix: _promotedTypeParameterTypeNullability(
            from.nullabilitySuffix,
            to.nullabilitySuffix,
          ),
          promotedBound: to,
        );
      }
    }

    return null;
  }

  /// Optimistically estimates, if type arguments of [left] can be equal to
  /// the type arguments of [right]. Both types must be instantiations of the
  /// same element.
  bool _canBeEqualArguments(InterfaceType left, InterfaceType right) {
    assert(left.element == right.element);
    var leftArguments = left.typeArguments;
    var rightArguments = right.typeArguments;
    assert(leftArguments.length == rightArguments.length);
    for (var i = 0; i < leftArguments.length; i++) {
      var leftArgument = leftArguments[i];
      var rightArgument = rightArguments[i];
      if (!_canBeEqualTo(leftArgument, rightArgument)) {
        return false;
      }
    }
    return true;
  }

  /// Optimistically estimates, if [left] can be equal to [right].
  bool _canBeEqualTo(DartType left, DartType right) {
    if (left is InterfaceType && right is InterfaceType) {
      if (left.element != right.element) {
        return false;
      }
    }
    return true;
  }

  List<TypeImpl> _defaultTypeArguments(
    List<TypeParameterElement> typeParameters,
  ) {
    return typeParameters.map((typeParameter) {
      var typeParameterImpl = typeParameter as TypeParameterElementImpl;
      return typeParameterImpl.defaultType!;
    }).toFixedList();
  }

  /// `S` is the future type of a type `T` in the following cases, using the
  /// first applicable case:
  /// * see [futureType].
  /// * `T` is `S` bounded, and there is a `U` such that `S` is `FutureOr<U>`,
  /// `Future<U>?`, or `FutureOr<U>?`.
  ///
  /// 17.15.3: For a given type `T0`, we introduce the notion of a `T0` bounded
  /// type: `T0` itself is `T0` bounded; if `B` is `T0` bounded and `X` is a
  /// type variable with bound `B` then `X` is `T0` bounded; finally, if `B`
  /// is `T0` bounded and `X` is a type variable then `X&B` is `T0` bounded.
  TypeImpl? _futureTypeOfBounded(TypeImpl T) {
    if (T is InterfaceType) {
      if (T.nullabilitySuffix != NullabilitySuffix.question) {
        if (T.isDartAsyncFutureOr) {
          return T;
        }
      } else {
        if (T.isDartAsyncFutureOr || T.isDartAsyncFuture) {
          return T;
        }
      }
    }

    if (T is TypeParameterTypeImpl) {
      var bound = T.element.bound;
      if (bound != null) {
        var result = _futureTypeOfBounded(bound);
        if (result != null) {
          return result;
        }
      }

      var promotedBound = T.promotedBound;
      if (promotedBound != null) {
        var result = _futureTypeOfBounded(promotedBound);
        if (result != null) {
          return result;
        }
      }
    }

    return null;
  }

  TypeImpl _refineNumericInvocationContextNullSafe(
    TypeImpl targetType,
    MethodElement methodElement,
    TypeImpl invocationContext,
    TypeImpl currentType,
  ) {
    // If the method being invoked comes from an extension, don't refine the
    // type because we can only make guarantees about methods defined in the
    // SDK, and the numeric methods we refine are all instance methods.
    if (methodElement.enclosingElement is ExtensionElement ||
        methodElement.enclosingElement is ExtensionTypeElement) {
      return currentType;
    }

    // If e is an expression of the form e1 + e2, e1 - e2, e1 * e2, e1 % e2 or
    // e1.remainder(e2)...
    if (const {'+', '-', '*', '%', 'remainder'}.contains(methodElement.name)) {
      // ...where C is the context type of e and T is the static type of e1, and
      // where T is a non-Never subtype of num...
      // Notes:
      // - We don't have to check for Never because if T is Never, the method
      //   element will fail to resolve so we'll never reach here.
      // - We actually check against `num?` rather than `num`.  It's equivalent
      //   from the standpoint of correctness (since it's illegal to call these
      //   methods on nullable types, and that's checked for elsewhere), but
      //   better from the standpoint of error recovery (since it allows e.g.
      //   `int? + int` to resolve to `int` rather than `num`).
      var c = invocationContext;
      var t = targetType;
      assert(!t.isBottom);
      var numType = typeProvider.numType;
      if (isSubtypeOf(t, typeProvider.numTypeQuestion)) {
        // Then:
        // - If int <: C, not num <: C, and T <: int, then the context type of
        //   e2 is int.
        // (Note: as above, we check the type of T against `int?`, because it's
        // equivalent and leads to better error recovery.)
        var intType = typeProvider.intType;
        if (isSubtypeOf(intType, c) &&
            !isSubtypeOf(numType, c) &&
            isSubtypeOf(t, typeProvider.intTypeQuestion)) {
          return intType;
        }
        // - If double <: C, not num <: C, and not T <: double, then the context
        //   type of e2 is double.
        // (Note: as above, we check the type of T against `double?`, because
        // it's equivalent and leads to better error recovery.)
        var doubleType = typeProvider.doubleType;
        if (isSubtypeOf(doubleType, c) &&
            !isSubtypeOf(numType, c) &&
            !isSubtypeOf(t, typeProvider.doubleTypeQuestion)) {
          return doubleType;
        }
        // Otherwise, the context type of e2 is num.
        return numType;
      }
    }
    // If e is an expression of the form e1.clamp(e2, e3)...
    if (methodElement.name == 'clamp') {
      // ...where C is the context type of e and T is the static type of e1
      // where T is a non-Never subtype of num...
      // Notes:
      // - We don't have to check for Never because if T is Never, the method
      //   element will fail to resolve so we'll never reach here.
      // - We actually check against `num?` rather than `num`.  It's
      //   equivalent from the standpoint of correctness (since it's illegal
      //   to call `num.clamp` on a nullable type or to pass it a nullable
      //   type as an argument, and that's checked for elsewhere), but better
      //   from the standpoint of error recovery (since it allows e.g.
      //   `int?.clamp(e2, e3)` to give the same context to `e2` and `e3` that
      //   `int.clamp(e2, e3` would).
      var c = invocationContext;
      var t = targetType;
      assert(!t.isBottom);
      var numType = typeProvider.numType;
      if (isSubtypeOf(t, typeProvider.numTypeQuestion)) {
        // Then:
        // - If int <: C, not num <: C, and T <: int, then the context type of
        //   e2 and e3 is int.
        // (Note: as above, we check the type of T against `int?`, because it's
        // equivalent and leads to better error recovery.)
        var intType = typeProvider.intType;
        if (isSubtypeOf(intType, c) &&
            !isSubtypeOf(numType, c) &&
            isSubtypeOf(t, typeProvider.intTypeQuestion)) {
          return intType;
        }
        // - If double <: C, not num <: C, and T <: double, then the context
        //   type of e2 and e3 is double.
        var doubleType = typeProvider.doubleType;
        if (isSubtypeOf(doubleType, c) &&
            !isSubtypeOf(numType, c) &&
            isSubtypeOf(t, typeProvider.doubleTypeQuestion)) {
          return doubleType;
        }
        // - Otherwise the context type of e2 an e3 is num.
        return numType;
      }
    }
    // No special rules apply.
    return currentType;
  }

  TypeImpl _refineNumericInvocationTypeNullSafe(
    TypeImpl targetType,
    MethodElement methodElement,
    List<TypeImpl> argumentTypes,
    TypeImpl currentType,
  ) {
    // If the method being invoked comes from an extension, don't refine the
    // type because we can only make guarantees about methods defined in the
    // SDK, and the numeric methods we refine are all instance methods.
    if (methodElement.enclosingElement is ExtensionElement ||
        methodElement.enclosingElement is ExtensionTypeElement) {
      return currentType;
    }

    // Let e be an expression of one of the forms e1 + e2, e1 - e2, e1 * e2,
    // e1 % e2 or e1.remainder(e2)...
    if (const {'+', '-', '*', '%', 'remainder'}.contains(methodElement.name)) {
      // ...where the static type of e1 is a non-Never type T and T <: num...
      // Notes:
      // - We don't have to check for Never because if T is Never, the method
      //   element will fail to resolve so we'll never reach here.
      // - We actually check against `num?` rather than `num`.  It's equivalent
      //   from the standpoint of correctness (since it's illegal to call these
      //   methods on nullable types, and that's checked for elsewhere), but
      //   better from the standpoint of error recovery (since it allows e.g.
      //   `int? + int` to resolve to `int` rather than `num`).
      var t = targetType;
      assert(!t.isBottom);
      if (isSubtypeOf(t, typeProvider.numTypeQuestion)) {
        // ...and where the static type of e2 is S and S is assignable to num.
        // (Note: we don't have to check that S is assignable to num because
        // this is required by the signature of the method.)
        if (argumentTypes.length == 1) {
          var s = argumentTypes[0];
          // Then:
          // - If T <: double then the static type of e is double. This includes
          //   S being dynamic or Never.
          // (Note: as above, we check against `double?` because it's equivalent
          // and leads to better error recovery.)
          var doubleType = typeProvider.doubleType;
          var doubleTypeQuestion = typeProvider.doubleTypeQuestion;
          if (isSubtypeOf(t, doubleTypeQuestion)) {
            return doubleType;
          }
          // - If S <: double and not S <: Never, then the static type of e is
          //   double.
          // (Again, we check against `double?` for error recovery.)
          if (!s.isBottom && isSubtypeOf(s, doubleTypeQuestion)) {
            return doubleType;
          }
          // - If T <: int, S <: int and not S <: Never, then the static type of
          //   e is int.
          // (As above, we check against `int?` for error recovery.)
          var intTypeQuestion = typeProvider.intTypeQuestion;
          if (!s.isBottom &&
              isSubtypeOf(t, intTypeQuestion) &&
              isSubtypeOf(s, intTypeQuestion)) {
            return typeProvider.intType;
          }
          // - Otherwise the static type of e is num.
          return typeProvider.numType;
        }
      }
    }
    // Let e be a normal invocation of the form e1.clamp(e2, e3)...
    if (methodElement.name == 'clamp') {
      // ...where the static types of e1, e2 and e3 are T1, T2 and T3
      // respectively...
      var t1 = targetType;
      if (argumentTypes.length == 2) {
        var t2 = argumentTypes[0];
        var t3 = argumentTypes[1];
        // ...and where T1, T2, and T3 are all non-Never subtypes of num.
        // Notes:
        // - We don't have to check T1 for Never because if T1 is Never, the
        //   method element will fail to resolve so we'll never reach here.
        // - We actually check against `num?` rather than `num`.  It's
        //   equivalent from the standpoint of correctness (since it's illegal
        //   to call `num.clamp` on a nullable type or to pass it a nullable
        //   type as an argument, and that's checked for elsewhere), but better
        //   from the standpoint of error recovery (since it allows e.g.
        //   `int?.clamp(int, int)` to resolve to `int` rather than `num`).
        // - We don't check that T2 and T3 are subtypes of num because the
        //   signature of `num.clamp` requires it.
        var numTypeQuestion = typeProvider.numTypeQuestion;
        if (isSubtypeOf(t1, numTypeQuestion) && !t2.isBottom && !t3.isBottom) {
          assert(!t1.isBottom);
          // Then:
          // - If T1, T2 and T3 are all subtypes of int, the static type of e is
          //   int.
          // (Note: as above, we check against `int?` because it's equivalent
          // and leads to better error recovery.)
          var intTypeQuestion = typeProvider.intTypeQuestion;
          if (isSubtypeOf(t1, intTypeQuestion) &&
              isSubtypeOf(t2, intTypeQuestion) &&
              isSubtypeOf(t3, intTypeQuestion)) {
            return typeProvider.intType;
          }
          // If T1, T2 and T3 are all subtypes of double, the static type of e
          // is double.
          // (As above, we check against `double?` for error recovery.)
          var doubleTypeQuestion = typeProvider.doubleTypeQuestion;
          if (isSubtypeOf(t1, doubleTypeQuestion) &&
              isSubtypeOf(t2, doubleTypeQuestion) &&
              isSubtypeOf(t3, doubleTypeQuestion)) {
            return typeProvider.doubleType;
          }
          // Otherwise the static type of e is num.
          return typeProvider.numType;
        }
      }
    }
    // No special rules apply.
    return currentType;
  }

  TypeImpl _removeBoundsOfGenericFunctionTypes(TypeImpl type) {
    return _RemoveBoundsOfGenericFunctionTypeVisitor.run(
      bottomType: NeverTypeImpl.instance,
      type: type,
    );
  }

  static NullabilitySuffix _promotedTypeParameterTypeNullability(
    NullabilitySuffix nullabilityOfType,
    NullabilitySuffix nullabilityOfBound,
  ) {
    if (nullabilityOfType == NullabilitySuffix.question &&
        nullabilityOfBound == NullabilitySuffix.none) {
      return NullabilitySuffix.none;
    }

    if (nullabilityOfType == NullabilitySuffix.question &&
        nullabilityOfBound == NullabilitySuffix.question) {
      return NullabilitySuffix.question;
    }

    // Intersection with a non-nullable type always yields a non-nullable type,
    // as it's the most restrictive kind of types.
    return NullabilitySuffix.none;
  }
}

// TODO(scheglov): Ask the language team how to deal with it.
class _RemoveBoundsOfGenericFunctionTypeVisitor extends ReplacementVisitor {
  final DartType _bottomType;

  _RemoveBoundsOfGenericFunctionTypeVisitor._(this._bottomType);

  @override
  DartType visitTypeParameterBound(DartType type) {
    return _bottomType;
  }

  static TypeImpl run({required TypeImpl bottomType, required TypeImpl type}) {
    var visitor = _RemoveBoundsOfGenericFunctionTypeVisitor._(bottomType);
    var result = type.accept(visitor);
    return result ?? type;
  }
}

class _TypeVariableEliminator extends Substitution {
  final DartType _topType;
  final DartType _bottomType;

  _TypeVariableEliminator(this._topType, this._bottomType);

  @override
  DartType getSubstitute(TypeParameterElement parameter, bool upperBound) {
    return upperBound ? _bottomType : _topType;
  }
}
