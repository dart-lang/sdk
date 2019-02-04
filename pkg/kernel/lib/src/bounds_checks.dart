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
        InterfaceType,
        InvalidType,
        NamedType,
        TypeParameter,
        TypeParameterType,
        TypedefType,
        VoidType;

import '../type_algebra.dart' show Substitution, substitute;

import '../type_environment.dart' show TypeEnvironment;

import '../util/graph.dart' show Graph, computeStrongComponents;

import '../visitor.dart' show DartTypeVisitor;

class TypeVariableGraph extends Graph<int> {
  List<int> vertices;
  List<TypeParameter> typeParameters;
  List<DartType> bounds;

  // `edges[i]` is the list of indices of type variables that reference the type
  // variable with the index `i` in their bounds.
  List<List<int>> edges;

  TypeVariableGraph(this.typeParameters, this.bounds) {
    assert(typeParameters.length == bounds.length);

    vertices = new List<int>(typeParameters.length);
    Map<TypeParameter, int> typeParameterIndices = <TypeParameter, int>{};
    edges = new List<List<int>>(typeParameters.length);
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

DartType instantiateToBounds(DartType type, Class object) {
  if (type is InterfaceType) {
    for (var typeArgument in type.typeArguments) {
      // If at least one of the arguments is not dynamic, we assume that the
      // type is not raw and does not need instantiation of its type parameters
      // to their bounds.
      if (typeArgument is! DynamicType) {
        return type;
      }
    }
    return new InterfaceType.byReference(
        type.className, calculateBounds(type.classNode.typeParameters, object));
  }
  if (type is TypedefType) {
    for (var typeArgument in type.typeArguments) {
      if (typeArgument is! DynamicType) {
        return type;
      }
    }
    return new TypedefType.byReference(type.typedefReference,
        calculateBounds(type.typedefNode.typeParameters, object));
  }
  return type;
}

/// Calculates bounds to be provided as type arguments in place of missing type
/// arguments on raw types with the given type parameters.
///
/// See the [description]
/// (https://github.com/dart-lang/sdk/blob/master/docs/language/informal/instantiate-to-bound.md)
/// of the algorithm for details.
List<DartType> calculateBounds(
    List<TypeParameter> typeParameters, Class object) {
  List<DartType> bounds = new List<DartType>(typeParameters.length);
  for (int i = 0; i < typeParameters.length; i++) {
    DartType bound = typeParameters[i].bound;
    if (bound == null) {
      bound = const DynamicType();
    } else if (bound is InterfaceType && bound.classNode == object) {
      DartType defaultType = typeParameters[i].defaultType;
      if (!(defaultType is InterfaceType && defaultType.classNode == object)) {
        bound = const DynamicType();
      }
    }
    bounds[i] = bound;
  }

  TypeVariableGraph graph = new TypeVariableGraph(typeParameters, bounds);
  List<List<int>> stronglyConnected = computeStrongComponents(graph);
  for (List<int> component in stronglyConnected) {
    Map<TypeParameter, DartType> upperBounds = <TypeParameter, DartType>{};
    Map<TypeParameter, DartType> lowerBounds = <TypeParameter, DartType>{};
    for (int typeParameterIndex in component) {
      upperBounds[typeParameters[typeParameterIndex]] = const DynamicType();
      lowerBounds[typeParameters[typeParameterIndex]] = const BottomType();
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
    lowerBounds[typeParameters[i]] = const BottomType();
    Substitution substitution =
        Substitution.fromUpperAndLowerBounds(upperBounds, lowerBounds);
    for (int j = 0; j < typeParameters.length; j++) {
      bounds[j] = substitution.substituteType(bounds[j]);
    }
  }

  return bounds;
}

class TypeArgumentIssue {
  // The type argument that violated the bound.
  final DartType argument;

  // The type parameter with the bound that was violated.
  final TypeParameter typeParameter;

  // The enclosing type of the issue, that is, the one with [typeParameter].
  final DartType enclosingType;

  TypeArgumentIssue(this.argument, this.typeParameter, this.enclosingType);
}

// TODO(dmitryas):  Remove [typedefInstantiations] when type arguments passed to
// typedefs are preserved in the Kernel output.
List<TypeArgumentIssue> findTypeArgumentIssues(
    DartType type, TypeEnvironment typeEnvironment,
    {bool allowSuperBounded = false}) {
  List<TypeParameter> variables;
  List<DartType> arguments;
  List<TypeArgumentIssue> typedefRhsResult;

  if (type is FunctionType && type.typedefType != null) {
    // [type] is a function type that is an application of a parametrized
    // typedef.  We need to check both the l.h.s. and the r.h.s. of the
    // definition in that case.  For details, see [link]
    // (https://github.com/dart-lang/sdk/blob/master/docs/language/informal/super-bounded-types.md).
    FunctionType functionType = type;
    FunctionType cloned = new FunctionType(
        functionType.positionalParameters, functionType.returnType,
        namedParameters: functionType.namedParameters,
        typeParameters: functionType.typeParameters,
        requiredParameterCount: functionType.requiredParameterCount,
        typedefType: null);
    typedefRhsResult = findTypeArgumentIssues(cloned, typeEnvironment,
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
      result.addAll(findTypeArgumentIssues(parameter.bound, typeEnvironment,
              allowSuperBounded: true) ??
          const <TypeArgumentIssue>[]);
    }
    for (DartType formal in type.positionalParameters) {
      result.addAll(findTypeArgumentIssues(formal, typeEnvironment,
              allowSuperBounded: true) ??
          const <TypeArgumentIssue>[]);
    }
    for (NamedType named in type.namedParameters) {
      result.addAll(findTypeArgumentIssues(named.type, typeEnvironment,
              allowSuperBounded: true) ??
          const <TypeArgumentIssue>[]);
    }
    result.addAll(findTypeArgumentIssues(type.returnType, typeEnvironment,
            allowSuperBounded: true) ??
        const <TypeArgumentIssue>[]);
    return result.isEmpty ? null : result;
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
      result.add(new TypeArgumentIssue(argument, variables[i], type));
    } else if (!typeEnvironment.isSubtypeOf(
        argument, substitute(variables[i].bound, substitutionMap))) {
      result ??= <TypeArgumentIssue>[];
      result.add(new TypeArgumentIssue(argument, variables[i], type));
    }

    List<TypeArgumentIssue> issues = findTypeArgumentIssues(
        argument, typeEnvironment,
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
  type = convertSuperBoundedToRegularBounded(typeEnvironment, type);
  List<DartType> argumentsToReport = arguments.toList();
  if (type is InterfaceType) {
    variables = type.classNode.typeParameters;
    arguments = type.typeArguments;
  } else if (type is TypedefType) {
    variables = type.typedefNode.typeParameters;
    arguments = type.typeArguments;
  }
  substitutionMap =
      new Map<TypeParameter, DartType>.fromIterables(variables, arguments);
  for (int i = 0; i < arguments.length; ++i) {
    DartType argument = arguments[i];
    if (argument is FunctionType && argument.typeParameters.length > 0) {
      // Generic function types aren't allowed as type arguments either.
      result ??= <TypeArgumentIssue>[];
      result
          .add(new TypeArgumentIssue(argumentsToReport[i], variables[i], type));
    } else if (!typeEnvironment.isSubtypeOf(
        argument, substitute(variables[i].bound, substitutionMap))) {
      result ??= <TypeArgumentIssue>[];
      result
          .add(new TypeArgumentIssue(argumentsToReport[i], variables[i], type));
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

// TODO(dmitryas):  Remove [typedefInstantiations] when type arguments passed to
// typedefs are preserved in the Kernel output.
List<TypeArgumentIssue> findTypeArgumentIssuesForInvocation(
    List<TypeParameter> parameters,
    List<DartType> arguments,
    TypeEnvironment typeEnvironment,
    {Map<FunctionType, List<DartType>> typedefInstantiations}) {
  assert(arguments.length == parameters.length);
  List<TypeArgumentIssue> result;
  var substitutionMap = <TypeParameter, DartType>{};
  for (int i = 0; i < arguments.length; ++i) {
    substitutionMap[parameters[i]] = arguments[i];
  }
  for (int i = 0; i < arguments.length; ++i) {
    DartType argument = arguments[i];
    if (argument is TypeParameterType && argument.promotedBound != null) {
      result ??= <TypeArgumentIssue>[];
      result.add(new TypeArgumentIssue(argument, parameters[i], null));
    } else if (argument is FunctionType && argument.typeParameters.length > 0) {
      // Generic function types aren't allowed as type arguments either.
      result ??= <TypeArgumentIssue>[];
      result.add(new TypeArgumentIssue(argument, parameters[i], null));
    } else if (!typeEnvironment.isSubtypeOf(
        argument, substitute(parameters[i].bound, substitutionMap))) {
      result ??= <TypeArgumentIssue>[];
      result.add(new TypeArgumentIssue(argument, parameters[i], null));
    }

    List<TypeArgumentIssue> issues = findTypeArgumentIssues(
        argument, typeEnvironment,
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
DartType convertSuperBoundedToRegularBounded(
    TypeEnvironment typeEnvironment, DartType type,
    {bool isCovariant = true}) {
  if ((type is DynamicType ||
          type is VoidType ||
          isObject(typeEnvironment, type)) &&
      isCovariant) {
    return const BottomType();
  } else if ((type is BottomType || isNull(typeEnvironment, type)) &&
      !isCovariant) {
    return typeEnvironment.objectType;
  } else if (type is InterfaceType && type.classNode.typeParameters != null) {
    List<DartType> replacedTypeArguments =
        new List<DartType>(type.typeArguments.length);
    for (int i = 0; i < replacedTypeArguments.length; i++) {
      replacedTypeArguments[i] = convertSuperBoundedToRegularBounded(
          typeEnvironment, type.typeArguments[i],
          isCovariant: isCovariant);
    }
    return new InterfaceType(type.classNode, replacedTypeArguments);
  } else if (type is TypedefType && type.typedefNode.typeParameters != null) {
    List<DartType> replacedTypeArguments =
        new List<DartType>(type.typeArguments.length);
    for (int i = 0; i < replacedTypeArguments.length; i++) {
      replacedTypeArguments[i] = convertSuperBoundedToRegularBounded(
          typeEnvironment, type.typeArguments[i],
          isCovariant: isCovariant);
    }
    return new TypedefType(type.typedefNode, replacedTypeArguments);
  } else if (type is FunctionType) {
    var replacedReturnType = convertSuperBoundedToRegularBounded(
        typeEnvironment, type.returnType,
        isCovariant: isCovariant);
    var replacedPositionalParameters =
        new List<DartType>(type.positionalParameters.length);
    for (int i = 0; i < replacedPositionalParameters.length; i++) {
      replacedPositionalParameters[i] = convertSuperBoundedToRegularBounded(
          typeEnvironment, type.positionalParameters[i],
          isCovariant: !isCovariant);
    }
    var replacedNamedParameters =
        new List<NamedType>(type.namedParameters.length);
    for (int i = 0; i < replacedNamedParameters.length; i++) {
      replacedNamedParameters[i] = new NamedType(
          type.namedParameters[i].name,
          convertSuperBoundedToRegularBounded(
              typeEnvironment, type.namedParameters[i].type,
              isCovariant: !isCovariant));
    }
    return new FunctionType(replacedPositionalParameters, replacedReturnType,
        namedParameters: replacedNamedParameters,
        typeParameters: type.typeParameters,
        requiredParameterCount: type.requiredParameterCount,
        typedefType: type.typedefType);
  }
  return type;
}

bool isObject(TypeEnvironment typeEnvironment, DartType type) {
  return type is InterfaceType &&
      type.classNode == typeEnvironment.objectType.classNode;
}

bool isNull(TypeEnvironment typeEnvironment, DartType type) {
  return type is InterfaceType &&
      type.classNode == typeEnvironment.nullType.classNode;
}

// Value set for variance of a type parameter X in a type term T.
class Variance {
  // Used when X does not occur free in T.
  static const int unrelated = 0;

  // Used when X occurs free in T, and U <: V implies [U/X]T <: [V/X]T.
  static const int covariant = 1;

  // Used when X occurs free in T, and U <: V implies [V/X]T <: [U/X]T.
  static const int contravariant = 2;

  // Used when there exists a pair U and V such that U <: V, but [U/X]T and
  // [V/X]T are incomparable.
  static const int invariant = 3;

  // Variance values form a lattice where [unrelated] is the top, [invariant]
  // is the bottom, and [covariant] and [contravariant] are incomparable.
  // [meet] calculates the meet of two elements of such lattice.  It can be
  // used, for example, to calculate the variance of a typedef type parameter
  // if it's encountered on the r.h.s. of the typedef multiple times.
  static int meet(int a, int b) => a | b;

  // Combines variances of X in T and Y in S into variance of X in [Y/T]S.
  //
  // Consider the following examples:
  //
  // * variance of X in Function(X) is [contravariant], variance of Y in List<Y>
  // is [covariant], so variance of X in List<Function(X)> is [contravariant];
  //
  // * variance of X in List<X> is [covariant], variance of Y in Function(Y) is
  // [contravariant], so variance of X in Function(List<X>) is [contravariant];
  //
  // * variance of X in Function(X) is [contravariant], variance of Y in
  // Function(Y) is [contravariant], so variance of X in Function(Function(X))
  // is [covariant];
  //
  // * let the following be declared:
  //
  //     typedef F<Z> = Function();
  //
  // then variance of X in F<X> is [unrelated], variance of Y in List<Y> is
  // [covariant], so variance of X in List<F<X>> is [unrelated];
  //
  // * let the following be declared:
  //
  //     typedef G<Z> = Z Function(Z);
  //
  // then variance of X in List<X> is [covariant], variance of Y in G<Y> is
  // [invariant], so variance of `X` in `G<List<X>>` is [invariant].
  static int combine(int a, int b) {
    if (a == unrelated || b == unrelated) return unrelated;
    if (a == invariant || b == invariant) return invariant;
    return a == b ? covariant : contravariant;
  }
}
