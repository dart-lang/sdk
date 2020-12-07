// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart'
    show
        BottomType,
        Class,
        DartType,
        DynamicType,
        FunctionType,
        FutureOrType,
        InterfaceType,
        InvalidType,
        Library,
        NamedType,
        NeverType,
        NullType,
        Nullability,
        TypeParameter,
        TypeParameterType,
        Typedef,
        TypedefType,
        Variance,
        VoidType;

import '../type_algebra.dart' show Substitution, substitute;

import '../type_environment.dart' show SubtypeCheckMode, TypeEnvironment;

import '../util/graph.dart' show Graph, computeStrongComponents;

import '../visitor.dart' show DartTypeVisitor, DartTypeVisitor1;

import 'legacy_erasure.dart';

class TypeVariableGraph extends Graph<int> {
  List<int> vertices;
  List<TypeParameter> typeParameters;
  List<DartType> bounds;

  // `edges[i]` is the list of indices of type variables that reference the type
  // variable with the index `i` in their bounds.
  List<List<int>> edges;

  TypeVariableGraph(this.typeParameters, this.bounds) {
    assert(typeParameters.length == bounds.length);

    vertices = new List<int>.filled(typeParameters.length, null);
    Map<TypeParameter, int> typeParameterIndices = <TypeParameter, int>{};
    edges = new List<List<int>>.filled(typeParameters.length, null);
    for (int i = 0; i < vertices.length; i++) {
      vertices[i] = i;
      typeParameterIndices[typeParameters[i]] = i;
      edges[i] = <int>[];
    }

    for (int i = 0; i < vertices.length; i++) {
      OccurrenceCollectorVisitor collector =
          new OccurrenceCollectorVisitor(typeParameters.toSet());
      collector.visit(bounds[i]);
      for (TypeParameter typeParameter in collector.occurred) {
        edges[typeParameterIndices[typeParameter]].add(i);
      }
    }
  }

  Iterable<int> neighborsOf(int index) {
    return edges[index];
  }
}

class OccurrenceCollectorVisitor extends DartTypeVisitor {
  final Set<TypeParameter> typeParameters;
  Set<TypeParameter> occurred = new Set<TypeParameter>();

  OccurrenceCollectorVisitor(this.typeParameters);

  visit(DartType node) => node.accept(this);

  visitNamedType(NamedType node) {
    node.type.accept(this);
  }

  visitInvalidType(InvalidType node);
  visitDynamicType(DynamicType node);
  visitVoidType(VoidType node);

  visitInterfaceType(InterfaceType node) {
    for (DartType argument in node.typeArguments) {
      argument.accept(this);
    }
  }

  visitTypedefType(TypedefType node) {
    for (DartType argument in node.typeArguments) {
      argument.accept(this);
    }
  }

  visitFunctionType(FunctionType node) {
    for (TypeParameter typeParameter in node.typeParameters) {
      typeParameter.bound.accept(this);
      typeParameter.defaultType?.accept(this);
    }
    for (DartType parameter in node.positionalParameters) {
      parameter.accept(this);
    }
    for (NamedType namedParameter in node.namedParameters) {
      namedParameter.type.accept(this);
    }
    node.returnType.accept(this);
  }

  visitTypeParameterType(TypeParameterType node) {
    if (typeParameters.contains(node.parameter)) {
      occurred.add(node.parameter);
    }
  }
}

DartType instantiateToBounds(
    DartType type, Class objectClass, Library contextLibrary) {
  if (type is InterfaceType) {
    if (type.typeArguments.isEmpty) return type;
    for (DartType typeArgument in type.typeArguments) {
      // If at least one of the arguments is not dynamic, we assume that the
      // type is not raw and does not need instantiation of its type parameters
      // to their bounds.
      if (typeArgument is! DynamicType) {
        return type;
      }
    }
    return new InterfaceType.byReference(
        type.className,
        type.nullability,
        calculateBounds(
            type.classNode.typeParameters, objectClass, contextLibrary));
  }
  if (type is TypedefType) {
    if (type.typeArguments.isEmpty) return type;
    for (DartType typeArgument in type.typeArguments) {
      if (typeArgument is! DynamicType) {
        return type;
      }
    }
    return new TypedefType.byReference(
        type.typedefReference,
        type.nullability,
        calculateBounds(
            type.typedefNode.typeParameters, objectClass, contextLibrary));
  }
  return type;
}

/// Calculates bounds to be provided as type arguments in place of missing type
/// arguments on raw types with the given type parameters.
///
/// See the [description]
/// (https://github.com/dart-lang/sdk/blob/master/docs/language/informal/instantiate-to-bound.md)
/// of the algorithm for details.
List<DartType> calculateBounds(List<TypeParameter> typeParameters,
    Class objectClass, Library contextLibrary) {
  List<DartType> bounds =
      new List<DartType>.filled(typeParameters.length, null);
  for (int i = 0; i < typeParameters.length; i++) {
    DartType bound = typeParameters[i].bound;
    if (bound == null) {
      bound = const DynamicType();
    } else if (bound is InterfaceType && bound.classNode == objectClass) {
      DartType defaultType = typeParameters[i].defaultType;
      if (!(defaultType is InterfaceType &&
          defaultType.classNode == objectClass)) {
        bound = const DynamicType();
      }
    }
    bounds[i] = bound;
  }

  TypeVariableGraph graph = new TypeVariableGraph(typeParameters, bounds);
  List<List<int>> stronglyConnected = computeStrongComponents(graph);
  final DartType topType = const DynamicType();
  final DartType bottomType = contextLibrary.isNonNullableByDefault
      ? const NeverType(Nullability.nonNullable)
      : const BottomType();
  for (List<int> component in stronglyConnected) {
    Map<TypeParameter, DartType> upperBounds = <TypeParameter, DartType>{};
    Map<TypeParameter, DartType> lowerBounds = <TypeParameter, DartType>{};
    for (int typeParameterIndex in component) {
      upperBounds[typeParameters[typeParameterIndex]] = topType;
      lowerBounds[typeParameters[typeParameterIndex]] = bottomType;
    }
    Substitution substitution =
        Substitution.fromUpperAndLowerBounds(upperBounds, lowerBounds);
    for (int typeParameterIndex in component) {
      bounds[typeParameterIndex] =
          substitution.substituteType(bounds[typeParameterIndex]);
    }
  }

  for (int i = 0; i < typeParameters.length; i++) {
    Map<TypeParameter, DartType> upperBounds = <TypeParameter, DartType>{};
    Map<TypeParameter, DartType> lowerBounds = <TypeParameter, DartType>{};
    upperBounds[typeParameters[i]] = bounds[i];
    lowerBounds[typeParameters[i]] = bottomType;
    Substitution substitution =
        Substitution.fromUpperAndLowerBounds(upperBounds, lowerBounds);
    for (int j = 0; j < typeParameters.length; j++) {
      bounds[j] = substitution.substituteType(bounds[j]);
    }
  }

  return bounds;
}

class TypeArgumentIssue {
  /// The index for type argument within the passed type arguments.
  final int index;

  /// The type argument that violated the bound.
  final DartType argument;

  /// The type parameter with the bound that was violated.
  final TypeParameter typeParameter;

  /// The enclosing type of the issue, that is, the one with [typeParameter].
  final DartType enclosingType;

  TypeArgumentIssue(
      this.index, this.argument, this.typeParameter, this.enclosingType);

  int get hashCode {
    int hash = 0x3fffffff & index;
    hash = 0x3fffffff & (hash * 31 + (hash ^ argument.hashCode));
    hash = 0x3fffffff & (hash * 31 + (hash ^ typeParameter.hashCode));
    hash = 0x3fffffff & (hash * 31 + (hash ^ enclosingType.hashCode));
    return hash;
  }

  bool operator ==(Object other) {
    assert(other is TypeArgumentIssue);
    return other is TypeArgumentIssue &&
        index == other.index &&
        argument == other.argument &&
        typeParameter == other.typeParameter &&
        enclosingType == other.enclosingType;
  }

  String toString() {
    return "TypeArgumentIssue(index=${index}, argument=${argument}, "
        "typeParameter=${typeParameter}, enclosingType=${enclosingType}";
  }
}

// Finds type arguments that don't follow the rules of well-boundness.
//
// [bottomType] should be either Null or Never, depending on what should be
// taken for the bottom type at the call site.  The bottom type is used in the
// checks for super-boundness for construction of the auxiliary type.  For
// details see Dart Language Specification, Section 14.3.2 The Instantiation to
// Bound Algorithm.
// TODO(dmitryas):  Remove [typedefInstantiations] when type arguments passed to
// typedefs are preserved in the Kernel output.
List<TypeArgumentIssue> findTypeArgumentIssues(
    Library library,
    DartType type,
    TypeEnvironment typeEnvironment,
    SubtypeCheckMode subtypeCheckMode,
    DartType bottomType,
    {bool allowSuperBounded = false}) {
  assert(bottomType == const NeverType(Nullability.nonNullable) ||
      bottomType is NullType);
  List<TypeParameter> variables;
  List<DartType> arguments;
  List<TypeArgumentIssue> typedefRhsResult;

  if (type is FunctionType && type.typedefType != null) {
    // [type] is a function type that is an application of a parametrized
    // typedef.  We need to check both the l.h.s. and the r.h.s. of the
    // definition in that case.  For details, see [link]
    // (https://github.com/dart-lang/sdk/blob/master/docs/language/informal/super-bounded-types.md).
    FunctionType functionType = type;
    FunctionType cloned = new FunctionType(functionType.positionalParameters,
        functionType.returnType, functionType.nullability,
        namedParameters: functionType.namedParameters,
        typeParameters: functionType.typeParameters,
        requiredParameterCount: functionType.requiredParameterCount,
        typedefType: null);
    typedefRhsResult = findTypeArgumentIssues(
        library, cloned, typeEnvironment, subtypeCheckMode, bottomType,
        allowSuperBounded: true);
    type = functionType.typedefType;
  }

  if (type is InterfaceType) {
    variables = type.classNode.typeParameters;
    arguments = type.typeArguments;
  } else if (type is TypedefType) {
    variables = type.typedefNode.typeParameters;
    arguments = type.typeArguments;
  } else if (type is FunctionType) {
    List<TypeArgumentIssue> result = <TypeArgumentIssue>[];
    for (TypeParameter parameter in type.typeParameters) {
      result.addAll(findTypeArgumentIssues(library, parameter.bound,
              typeEnvironment, subtypeCheckMode, bottomType,
              allowSuperBounded: true) ??
          const <TypeArgumentIssue>[]);
    }
    for (DartType formal in type.positionalParameters) {
      result.addAll(findTypeArgumentIssues(
              library, formal, typeEnvironment, subtypeCheckMode, bottomType,
              allowSuperBounded: true) ??
          const <TypeArgumentIssue>[]);
    }
    for (NamedType named in type.namedParameters) {
      result.addAll(findTypeArgumentIssues(library, named.type, typeEnvironment,
              subtypeCheckMode, bottomType,
              allowSuperBounded: true) ??
          const <TypeArgumentIssue>[]);
    }
    result.addAll(findTypeArgumentIssues(library, type.returnType,
            typeEnvironment, subtypeCheckMode, bottomType,
            allowSuperBounded: true) ??
        const <TypeArgumentIssue>[]);
    return result.isEmpty ? null : result;
  } else if (type is FutureOrType) {
    variables = typeEnvironment.coreTypes.futureClass.typeParameters;
    arguments = <DartType>[type.typeArgument];
  } else {
    return null;
  }

  if (variables == null) return null;

  List<TypeArgumentIssue> result;
  List<TypeArgumentIssue> argumentsResult;

  Map<TypeParameter, DartType> substitutionMap =
      new Map<TypeParameter, DartType>.fromIterables(variables, arguments);
  for (int i = 0; i < arguments.length; ++i) {
    DartType argument = arguments[i];
    if (argument is FunctionType && argument.typeParameters.length > 0) {
      // Generic function types aren't allowed as type arguments either.
      result ??= <TypeArgumentIssue>[];
      result.add(new TypeArgumentIssue(i, argument, variables[i], type));
    } else if (variables[i].bound is! InvalidType) {
      DartType bound = substitute(variables[i].bound, substitutionMap);
      if (!library.isNonNullableByDefault) {
        bound = legacyErasure(bound);
      }
      if (!typeEnvironment.isSubtypeOf(argument, bound, subtypeCheckMode)) {
        // If the bound is InvalidType it's not checked, because an error was
        // reported already at the time of the creation of InvalidType.
        result ??= <TypeArgumentIssue>[];
        result.add(new TypeArgumentIssue(i, argument, variables[i], type));
      }
    }

    List<TypeArgumentIssue> issues = findTypeArgumentIssues(
        library, argument, typeEnvironment, subtypeCheckMode, bottomType,
        allowSuperBounded: true);
    if (issues != null) {
      argumentsResult ??= <TypeArgumentIssue>[];
      argumentsResult.addAll(issues);
    }
  }
  if (argumentsResult != null) {
    result ??= <TypeArgumentIssue>[];
    result.addAll(argumentsResult);
  }
  if (typedefRhsResult != null) {
    result ??= <TypeArgumentIssue>[];
    result.addAll(typedefRhsResult);
  }

  // [type] is regular-bounded.
  if (result == null) return null;
  if (!allowSuperBounded) return result;

  result = null;
  type = convertSuperBoundedToRegularBounded(
      library, typeEnvironment, type, bottomType);
  List<DartType> argumentsToReport = arguments.toList();
  if (type is InterfaceType) {
    variables = type.classNode.typeParameters;
    arguments = type.typeArguments;
  } else if (type is TypedefType) {
    variables = type.typedefNode.typeParameters;
    arguments = type.typeArguments;
  } else if (type is FutureOrType) {
    variables = typeEnvironment.coreTypes.futureClass.typeParameters;
    arguments = <DartType>[type.typeArgument];
  }
  substitutionMap =
      new Map<TypeParameter, DartType>.fromIterables(variables, arguments);
  for (int i = 0; i < arguments.length; ++i) {
    DartType argument = arguments[i];
    if (argument is FunctionType && argument.typeParameters.length > 0) {
      // Generic function types aren't allowed as type arguments either.
      result ??= <TypeArgumentIssue>[];
      result.add(
          new TypeArgumentIssue(i, argumentsToReport[i], variables[i], type));
    } else if (!typeEnvironment.isSubtypeOf(argument,
        substitute(variables[i].bound, substitutionMap), subtypeCheckMode)) {
      result ??= <TypeArgumentIssue>[];
      result.add(
          new TypeArgumentIssue(i, argumentsToReport[i], variables[i], type));
    }
  }
  if (argumentsResult != null) {
    result ??= <TypeArgumentIssue>[];
    result.addAll(argumentsResult);
  }
  if (typedefRhsResult != null) {
    result ??= <TypeArgumentIssue>[];
    result.addAll(typedefRhsResult);
  }
  return result;
}

// Finds type arguments that don't follow the rules of well-boundness.
//
// [bottomType] should be either Null or Never, depending on what should be
// taken for the bottom type at the call site.  The bottom type is used in the
// checks for super-boundness for construction of the auxiliary type.  For
// details see Dart Language Specification, Section 14.3.2 The Instantiation to
// Bound Algorithm.
// TODO(dmitryas):  Remove [typedefInstantiations] when type arguments passed to
// typedefs are preserved in the Kernel output.
List<TypeArgumentIssue> findTypeArgumentIssuesForInvocation(
    Library library,
    List<TypeParameter> parameters,
    List<DartType> arguments,
    TypeEnvironment typeEnvironment,
    SubtypeCheckMode subtypeCheckMode,
    DartType bottomType,
    {Map<FunctionType, List<DartType>> typedefInstantiations}) {
  assert(arguments.length == parameters.length);
  assert(bottomType == const NeverType(Nullability.nonNullable) ||
      bottomType is NullType);
  List<TypeArgumentIssue> result;
  Map<TypeParameter, DartType> substitutionMap = <TypeParameter, DartType>{};
  for (int i = 0; i < arguments.length; ++i) {
    substitutionMap[parameters[i]] = arguments[i];
  }
  for (int i = 0; i < arguments.length; ++i) {
    DartType argument = arguments[i];
    if (argument is TypeParameterType && argument.promotedBound != null) {
      result ??= <TypeArgumentIssue>[];
      result.add(new TypeArgumentIssue(i, argument, parameters[i], null));
    } else if (argument is FunctionType && argument.typeParameters.length > 0) {
      // Generic function types aren't allowed as type arguments either.
      result ??= <TypeArgumentIssue>[];
      result.add(new TypeArgumentIssue(i, argument, parameters[i], null));
    } else if (parameters[i].bound is! InvalidType) {
      DartType bound = substitute(parameters[i].bound, substitutionMap);
      if (!library.isNonNullableByDefault) {
        bound = legacyErasure(bound);
      }
      if (!typeEnvironment.isSubtypeOf(argument, bound, subtypeCheckMode)) {
        result ??= <TypeArgumentIssue>[];
        result.add(new TypeArgumentIssue(i, argument, parameters[i], null));
      }
    }

    List<TypeArgumentIssue> issues = findTypeArgumentIssues(
        library, argument, typeEnvironment, subtypeCheckMode, bottomType,
        allowSuperBounded: true);
    if (issues != null) {
      result ??= <TypeArgumentIssue>[];
      result.addAll(issues);
    }
  }
  return result;
}

String getGenericTypeName(DartType type) {
  if (type is InterfaceType) {
    return type.classNode.name;
  } else if (type is TypedefType) {
    return type.typedefNode.name;
  }
  return type.toString();
}

/// Replaces all covariant occurrences of `dynamic`, `Object`, and `void` with
/// [BottomType] and all contravariant occurrences of `Null` and [BottomType]
/// with `Object`.
DartType convertSuperBoundedToRegularBounded(Library clientLibrary,
    TypeEnvironment typeEnvironment, DartType type, DartType bottomType,
    {bool isCovariant = true}) {
  bool isTop = clientLibrary.isNonNullableByDefault
      ? typeEnvironment.coreTypes.isTop(type)
      : type is DynamicType ||
          type is VoidType ||
          type is InterfaceType &&
              type.classNode == typeEnvironment.coreTypes.objectClass;
  if (isTop && isCovariant) {
    return bottomType;
  } else if ((type == bottomType || type is BottomType) && !isCovariant) {
    return typeEnvironment.coreTypes.objectLegacyRawType;
  } else if (type is InterfaceType && type.classNode.typeParameters != null) {
    List<DartType> replacedTypeArguments =
        new List<DartType>.filled(type.typeArguments.length, null);
    for (int i = 0; i < replacedTypeArguments.length; i++) {
      replacedTypeArguments[i] = convertSuperBoundedToRegularBounded(
          clientLibrary, typeEnvironment, type.typeArguments[i], bottomType,
          isCovariant: isCovariant);
    }
    return new InterfaceType(
        type.classNode, type.nullability, replacedTypeArguments);
  } else if (type is TypedefType && type.typedefNode.typeParameters != null) {
    List<DartType> replacedTypeArguments =
        new List<DartType>.filled(type.typeArguments.length, null);
    for (int i = 0; i < replacedTypeArguments.length; i++) {
      replacedTypeArguments[i] = convertSuperBoundedToRegularBounded(
          clientLibrary, typeEnvironment, type.typeArguments[i], bottomType,
          isCovariant: isCovariant);
    }
    return new TypedefType(
        type.typedefNode, type.nullability, replacedTypeArguments);
  } else if (type is FunctionType) {
    DartType replacedReturnType = convertSuperBoundedToRegularBounded(
        clientLibrary, typeEnvironment, type.returnType, bottomType,
        isCovariant: isCovariant);
    List<DartType> replacedPositionalParameters =
        new List<DartType>.filled(type.positionalParameters.length, null);
    for (int i = 0; i < replacedPositionalParameters.length; i++) {
      replacedPositionalParameters[i] = convertSuperBoundedToRegularBounded(
          clientLibrary,
          typeEnvironment,
          type.positionalParameters[i],
          bottomType,
          isCovariant: !isCovariant);
    }
    List<NamedType> replacedNamedParameters =
        new List<NamedType>.filled(type.namedParameters.length, null);
    for (int i = 0; i < replacedNamedParameters.length; i++) {
      replacedNamedParameters[i] = new NamedType(
          type.namedParameters[i].name,
          convertSuperBoundedToRegularBounded(clientLibrary, typeEnvironment,
              type.namedParameters[i].type, bottomType,
              isCovariant: !isCovariant));
    }
    return new FunctionType(
        replacedPositionalParameters, replacedReturnType, type.nullability,
        namedParameters: replacedNamedParameters,
        typeParameters: type.typeParameters,
        requiredParameterCount: type.requiredParameterCount,
        typedefType: type.typedefType);
  } else if (type is FutureOrType) {
    return new FutureOrType(
        convertSuperBoundedToRegularBounded(
            clientLibrary, typeEnvironment, type.typeArgument, bottomType),
        type.declaredNullability);
  }
  return type;
}

int computeVariance(TypeParameter typeParameter, DartType type,
    {Map<TypeParameter, Map<DartType, int>> computedVariances}) {
  computedVariances ??= new Map<TypeParameter, Map<DartType, int>>.identity();
  computedVariances[typeParameter] ??= new Map<DartType, int>.identity();

  int variance = computedVariances[typeParameter][type];
  if (variance != null) return variance;
  computedVariances[typeParameter][type] = VarianceCalculator._visitMarker;

  return computedVariances[typeParameter][type] =
      type.accept1(new VarianceCalculator(typeParameter), computedVariances);
}

class VarianceCalculator
    implements DartTypeVisitor1<int, Map<TypeParameter, Map<DartType, int>>> {
  final TypeParameter typeParameter;

  static const int _visitMarker = -2;

  VarianceCalculator(this.typeParameter);

  @override
  int defaultDartType(
      DartType node, Map<TypeParameter, Map<DartType, int>> computedVariances) {
    throw new StateError("Unhandled ${node.runtimeType} "
        "when computing variance of a type parameter.");
  }

  @override
  int visitTypeParameterType(TypeParameterType node,
      Map<TypeParameter, Map<DartType, int>> computedVariances) {
    if (node.parameter == typeParameter) return Variance.covariant;
    return Variance.unrelated;
  }

  @override
  int visitInterfaceType(InterfaceType node,
      Map<TypeParameter, Map<DartType, int>> computedVariances) {
    int result = Variance.unrelated;
    for (int i = 0; i < node.typeArguments.length; ++i) {
      result = Variance.meet(
          result,
          Variance.combine(
              node.classNode.typeParameters[i].variance,
              computeVariance(typeParameter, node.typeArguments[i],
                  computedVariances: computedVariances)));
    }
    return result;
  }

  @override
  int visitFutureOrType(FutureOrType node,
      Map<TypeParameter, Map<DartType, int>> computedVariances) {
    return computeVariance(typeParameter, node.typeArgument,
        computedVariances: computedVariances);
  }

  @override
  int visitTypedefType(TypedefType node,
      Map<TypeParameter, Map<DartType, int>> computedVariances) {
    int result = Variance.unrelated;
    for (int i = 0; i < node.typeArguments.length; ++i) {
      Typedef typedefNode = node.typedefNode;
      TypeParameter typedefTypeParameter = typedefNode.typeParameters[i];
      if (computedVariances.containsKey(typedefTypeParameter) &&
          computedVariances[typedefTypeParameter][typedefNode.type] ==
              _visitMarker) {
        throw new StateError("The typedef '${node.typedefNode.name}' "
            "has a reference to itself.");
      }

      result = Variance.meet(
          result,
          Variance.combine(
              computeVariance(typeParameter, node.typeArguments[i],
                  computedVariances: computedVariances),
              computeVariance(typedefTypeParameter, typedefNode.type,
                  computedVariances: computedVariances)));
    }
    return result;
  }

  @override
  int visitFunctionType(FunctionType node,
      Map<TypeParameter, Map<DartType, int>> computedVariances) {
    int result = Variance.unrelated;
    result = Variance.meet(
        result,
        computeVariance(typeParameter, node.returnType,
            computedVariances: computedVariances));
    for (TypeParameter functionTypeParameter in node.typeParameters) {
      // If [typeParameter] is referenced in the bound at all, it makes the
      // variance of [typeParameter] in the entire type invariant.  The
      // invocation of the visitor below is made to simply figure out if
      // [typeParameter] occurs in the bound.
      if (computeVariance(typeParameter, functionTypeParameter.bound,
              computedVariances: computedVariances) !=
          Variance.unrelated) {
        result = Variance.invariant;
      }
    }
    for (DartType positionalType in node.positionalParameters) {
      result = Variance.meet(
          result,
          Variance.combine(
              Variance.contravariant,
              computeVariance(typeParameter, positionalType,
                  computedVariances: computedVariances)));
    }
    for (NamedType namedType in node.namedParameters) {
      result = Variance.meet(
          result,
          Variance.combine(
              Variance.contravariant,
              computeVariance(typeParameter, namedType.type,
                  computedVariances: computedVariances)));
    }
    return result;
  }

  @override
  int visitBottomType(BottomType node,
      Map<TypeParameter, Map<DartType, int>> computedVariances) {
    return Variance.unrelated;
  }

  @override
  int visitNeverType(NeverType node,
      Map<TypeParameter, Map<DartType, int>> computedVariances) {
    return Variance.unrelated;
  }

  @override
  int visitNullType(
      NullType node, Map<TypeParameter, Map<DartType, int>> computedVariances) {
    return Variance.unrelated;
  }

  @override
  int visitVoidType(
      VoidType node, Map<TypeParameter, Map<DartType, int>> computedVariances) {
    return Variance.unrelated;
  }

  @override
  int visitDynamicType(DynamicType node,
      Map<TypeParameter, Map<DartType, int>> computedVariances) {
    return Variance.unrelated;
  }

  @override
  int visitInvalidType(InvalidType node,
      Map<TypeParameter, Map<DartType, int>> computedVariances) {
    return Variance.unrelated;
  }
}
