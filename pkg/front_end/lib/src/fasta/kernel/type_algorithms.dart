// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'kernel_builder.dart'
    show
        TypeBuilder,
        TypeVariableBuilder,
        KernelFormalParameterBuilder,
        KernelTypeBuilder,
        KernelNamedTypeBuilder,
        KernelTypeVariableBuilder,
        KernelClassBuilder,
        KernelFunctionTypeBuilder,
        NamedTypeBuilder,
        FormalParameterBuilder,
        FunctionTypeBuilder;

import 'package:kernel/util/graph.dart' show Graph, computeStrongComponents;

KernelTypeBuilder substituteRange(
    KernelTypeBuilder type,
    Map<TypeVariableBuilder, KernelTypeBuilder> upperSubstitution,
    Map<TypeVariableBuilder, KernelTypeBuilder> lowerSubstitution,
    {bool isCovariant = true}) {
  if (type is KernelNamedTypeBuilder) {
    if (type.declaration is KernelTypeVariableBuilder) {
      if (isCovariant) {
        return upperSubstitution[type.declaration] ?? type;
      }
      return lowerSubstitution[type.declaration] ?? type;
    }
    if (type.arguments == null || type.arguments.length == 0) {
      return type;
    }
    List<TypeBuilder> arguments;
    for (int i = 0; i < type.arguments.length; i++) {
      TypeBuilder substitutedArgument = substituteRange(
          type.arguments[i], upperSubstitution, lowerSubstitution,
          isCovariant: isCovariant);
      if (substitutedArgument != type.arguments[i]) {
        arguments ??= type.arguments.toList();
        arguments[i] = substitutedArgument;
      }
    }
    if (arguments != null) {
      return new KernelNamedTypeBuilder(type.name, arguments)
        ..bind(type.declaration);
    }
    return type;
  }

  if (type is KernelFunctionTypeBuilder) {
    List<KernelTypeVariableBuilder> variables;
    if (type.typeVariables != null) {
      variables =
          new List<KernelTypeVariableBuilder>(type.typeVariables.length);
    }
    List<KernelFormalParameterBuilder> formals;
    if (type.formals != null) {
      formals = new List<KernelFormalParameterBuilder>(type.formals.length);
    }
    KernelTypeBuilder returnType;
    bool changed = false;

    if (type.typeVariables != null) {
      for (int i = 0; i < variables.length; i++) {
        KernelTypeVariableBuilder variable = type.typeVariables[i];
        KernelTypeBuilder bound = substituteRange(
            variable.bound, upperSubstitution, lowerSubstitution,
            isCovariant: isCovariant);
        if (bound != variable.bound) {
          variables[i] = new KernelTypeVariableBuilder(
              variable.name, variable.parent, variable.charOffset, bound);
          changed = true;
        } else {
          variables[i] = variable;
        }
      }
    }

    if (type.formals != null) {
      for (int i = 0; i < formals.length; i++) {
        KernelFormalParameterBuilder formal = type.formals[i];
        KernelTypeBuilder parameterType = substituteRange(
            formal.type, upperSubstitution, lowerSubstitution,
            isCovariant: !isCovariant);
        if (parameterType != formal.type) {
          formals[i] = new KernelFormalParameterBuilder(
              formal.metadata,
              formal.modifiers,
              parameterType,
              formal.name,
              formal.hasThis,
              formal.parent,
              formal.charOffset);
          changed = true;
        } else {
          formals[i] = formal;
        }
      }
    }

    returnType = substituteRange(
        type.returnType, upperSubstitution, lowerSubstitution,
        isCovariant: true);
    if (returnType != type.returnType) {
      changed = true;
    }

    if (changed) {
      return new KernelFunctionTypeBuilder(returnType, variables, formals);
    }

    return type;
  }
  return type;
}

KernelTypeBuilder substitute(KernelTypeBuilder type,
    Map<TypeVariableBuilder, KernelTypeBuilder> substitution) {
  return substituteRange(type, substitution, substitution, isCovariant: true);
}

/// Calculates bounds to be provided as type arguments in place of missing type
/// arguments on raw types with the given type parameters.
///
/// See the [description]
/// (https://github.com/dart-lang/sdk/blob/master/docs/language/informal/instantiate-to-bound.md)
/// of the algorithm for details.
List<KernelTypeBuilder> calculateBounds(
    List<TypeVariableBuilder> variables,
    KernelTypeBuilder dynamicType,
    KernelTypeBuilder bottomType,
    KernelClassBuilder objectClass) {
  List<KernelTypeBuilder> bounds =
      new List<KernelTypeBuilder>(variables.length);

  for (int i = 0; i < variables.length; i++) {
    bounds[i] = variables[i].bound ?? dynamicType;
  }

  TypeVariablesGraph graph = new TypeVariablesGraph(variables, bounds);
  List<List<int>> stronglyConnected = computeStrongComponents(graph);
  for (List<int> component in stronglyConnected) {
    Map<TypeVariableBuilder, KernelTypeBuilder> dynamicSubstitution =
        <TypeVariableBuilder, KernelTypeBuilder>{};
    Map<TypeVariableBuilder, KernelTypeBuilder> nullSubstitution =
        <TypeVariableBuilder, KernelTypeBuilder>{};
    for (int variableIndex in component) {
      dynamicSubstitution[variables[variableIndex]] = dynamicType;
      nullSubstitution[variables[variableIndex]] = bottomType;
    }
    for (int variableIndex in component) {
      bounds[variableIndex] = substituteRange(
          bounds[variableIndex], dynamicSubstitution, nullSubstitution,
          isCovariant: true);
    }
  }

  for (int i = 0; i < variables.length; i++) {
    Map<TypeVariableBuilder, KernelTypeBuilder> substitution =
        <TypeVariableBuilder, KernelTypeBuilder>{};
    Map<TypeVariableBuilder, KernelTypeBuilder> nullSubstitution =
        <TypeVariableBuilder, KernelTypeBuilder>{};
    substitution[variables[i]] = bounds[i];
    nullSubstitution[variables[i]] = bottomType;
    for (int j = 0; j < variables.length; j++) {
      bounds[j] = substituteRange(bounds[j], substitution, nullSubstitution,
          isCovariant: true);
    }
  }

  return bounds;
}

/// Graph of mutual dependencies of type variables from the same declaration.
/// Type variables are represented by their indices in the corresponding
/// declaration.
class TypeVariablesGraph implements Graph<int> {
  List<int> vertices;
  List<TypeVariableBuilder> variables;
  List<TypeBuilder> bounds;

  // `edges[i]` is the list of indices of type variables that reference the type
  // variable with the index `i` in their bounds.
  List<List<int>> edges;

  TypeVariablesGraph(this.variables, this.bounds) {
    assert(variables.length == bounds.length);

    vertices = new List<int>(variables.length);
    Map<TypeVariableBuilder, int> variableIndices =
        <TypeVariableBuilder, int>{};
    edges = new List<List<int>>(variables.length);
    for (int i = 0; i < vertices.length; i++) {
      vertices[i] = i;
      variableIndices[variables[i]] = i;
      edges[i] = <int>[];
    }

    void collectReferencesFrom(int index, TypeBuilder type) {
      if (type is NamedTypeBuilder) {
        if (type.declaration is TypeVariableBuilder &&
            this.variables.contains(type.declaration)) {
          edges[variableIndices[type.declaration]].add(index);
        }
        if (type.arguments != null) {
          for (TypeBuilder argument in type.arguments) {
            collectReferencesFrom(index, argument);
          }
        }
      } else if (type is FunctionTypeBuilder) {
        if (type.typeVariables != null) {
          for (TypeVariableBuilder typeVariable in type.typeVariables) {
            collectReferencesFrom(index, typeVariable.bound);
          }
        }
        if (type.formals != null) {
          for (FormalParameterBuilder parameter in type.formals) {
            collectReferencesFrom(index, parameter.type);
          }
        }
        collectReferencesFrom(index, type.returnType);
      }
    }

    for (int i = 0; i < vertices.length; i++) {
      collectReferencesFrom(i, bounds[i]);
    }
  }

  /// Returns indices of type variables that depend on the type variable with
  /// [index].
  Iterable<int> neighborsOf(int index) {
    return edges[index];
  }
}
