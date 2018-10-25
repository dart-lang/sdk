// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart'
    show
        BottomType,
        DartType,
        DynamicType,
        FunctionType,
        InterfaceType,
        NamedType,
        TypeParameter,
        TypedefType,
        VoidType;

import '../type_algebra.dart' show substitute;

import '../type_environment.dart' show TypeEnvironment;

// TODO(dmitryas):  Remove [typedefInstantiations] when type arguments passed
// to typedefs are preserved in the Kernel output.
List<Object> findBoundViolations(DartType type, TypeEnvironment typeEnvironment,
    {bool allowSuperBounded = false,
    Map<FunctionType, List<DartType>> typedefInstantiations}) {
  List<TypeParameter> variables;
  List<DartType> arguments;
  List<Object> typedefRhsResult;

  if (typedefInstantiations != null &&
      typedefInstantiations.containsKey(type)) {
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
        typedefReference: null);
    typedefRhsResult = findBoundViolations(cloned, typeEnvironment,
        allowSuperBounded: true, typedefInstantiations: typedefInstantiations);
    type = new TypedefType(functionType.typedef, typedefInstantiations[type]);
  }

  if (type is InterfaceType) {
    variables = type.classNode.typeParameters;
    arguments = type.typeArguments;
  } else if (type is TypedefType) {
    variables = type.typedefNode.typeParameters;
    arguments = type.typeArguments;
  } else if (type is FunctionType) {
    List<Object> result = <Object>[];
    for (TypeParameter parameter in type.typeParameters) {
      result.addAll(findBoundViolations(parameter.bound, typeEnvironment,
              allowSuperBounded: true,
              typedefInstantiations: typedefInstantiations) ??
          const <Object>[]);
    }
    for (DartType formal in type.positionalParameters) {
      result.addAll(findBoundViolations(formal, typeEnvironment,
              allowSuperBounded: true,
              typedefInstantiations: typedefInstantiations) ??
          const <Object>[]);
    }
    for (NamedType named in type.namedParameters) {
      result.addAll(findBoundViolations(named.type, typeEnvironment,
              allowSuperBounded: true,
              typedefInstantiations: typedefInstantiations) ??
          const <Object>[]);
    }
    result.addAll(findBoundViolations(type.returnType, typeEnvironment,
            allowSuperBounded: true,
            typedefInstantiations: typedefInstantiations) ??
        const <Object>[]);
    return result.isEmpty ? null : result;
  } else {
    return null;
  }

  if (variables == null) return null;

  List<Object> result;
  List<Object> argumentsResult;

  Map<TypeParameter, DartType> substitutionMap =
      new Map<TypeParameter, DartType>.fromIterables(variables, arguments);
  for (int i = 0; i < arguments.length; ++i) {
    DartType argument = arguments[i];
    if (argument is FunctionType && argument.typeParameters.length > 0) {
      // Generic function types aren't allowed as type arguments either.
      result ??= <Object>[];
      result.add(argument);
      result.add(variables[i]);
      result.add(type);
    } else if (!typeEnvironment.isSubtypeOf(
        argument, substitute(variables[i].bound, substitutionMap))) {
      result ??= <Object>[];
      result.add(argument);
      result.add(variables[i]);
      result.add(type);
    }

    List<Object> violations = findBoundViolations(argument, typeEnvironment,
        allowSuperBounded: true, typedefInstantiations: typedefInstantiations);
    if (violations != null) {
      argumentsResult ??= <Object>[];
      argumentsResult.addAll(violations);
    }
  }
  if (argumentsResult != null) {
    result ??= <Object>[];
    result.addAll(argumentsResult);
  }
  if (typedefRhsResult != null) {
    result ??= <Object>[];
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
      result ??= <Object>[];
      result.add(argumentsToReport[i]);
      result.add(variables[i]);
      result.add(type);
    } else if (!typeEnvironment.isSubtypeOf(
        argument, substitute(variables[i].bound, substitutionMap))) {
      result ??= <Object>[];
      result.add(argumentsToReport[i]);
      result.add(variables[i]);
      result.add(type);
    }
  }
  if (argumentsResult != null) {
    result ??= <Object>[];
    result.addAll(argumentsResult);
  }
  if (typedefRhsResult != null) {
    result ??= <Object>[];
    result.addAll(typedefRhsResult);
  }
  return result;
}

// TODO(dmitryas):  Remove [typedefInstantiations] when type arguments passed
// to typedefs are preserved in the Kernel output.
List<Object> findBoundViolationsElementwise(List<TypeParameter> parameters,
    List<DartType> arguments, TypeEnvironment typeEnvironment,
    {Map<FunctionType, List<DartType>> typedefInstantiations}) {
  assert(arguments.length == parameters.length);
  List<Object> result;
  var substitutionMap = <TypeParameter, DartType>{};
  for (int i = 0; i < arguments.length; ++i) {
    substitutionMap[parameters[i]] = arguments[i];
  }
  for (int i = 0; i < arguments.length; ++i) {
    DartType argument = arguments[i];
    if (argument is FunctionType && argument.typeParameters.length > 0) {
      // Generic function types aren't allowed as type arguments either.
      result ??= <Object>[];
      result.add(argument);
      result.add(parameters[i]);
      result.add(null);
    } else if (!typeEnvironment.isSubtypeOf(
        argument, substitute(parameters[i].bound, substitutionMap))) {
      result ??= <Object>[];
      result.add(argument);
      result.add(parameters[i]);
      result.add(null);
    }

    List<Object> violations = findBoundViolations(argument, typeEnvironment,
        allowSuperBounded: true, typedefInstantiations: typedefInstantiations);
    if (violations != null) {
      result ??= <Object>[];
      result.addAll(violations);
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
        typedefReference: type.typedefReference);
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
