// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart' show TypeParameter;

import 'package:kernel/type_algebra.dart' show containsTypeVariable;

import 'package:kernel/util/graph.dart' show Graph, computeStrongComponents;

import 'kernel_builder.dart'
    show
        ClassBuilder,
        FormalParameterBuilder,
        FunctionTypeAliasBuilder,
        FunctionTypeBuilder,
        KernelClassBuilder,
        KernelFormalParameterBuilder,
        KernelFunctionTypeBuilder,
        KernelNamedTypeBuilder,
        KernelTypeBuilder,
        KernelTypeVariableBuilder,
        NamedTypeBuilder,
        TypeBuilder,
        TypeDeclarationBuilder,
        TypeVariableBuilder;

import '../dill/dill_class_builder.dart' show DillClassBuilder;

import '../dill/dill_typedef_builder.dart' show DillFunctionTypeAliasBuilder;

import '../fasta_codes.dart'
    show
        LocatedMessage,
        templateBoundIssueViaCycleNonSimplicity,
        templateBoundIssueViaLoopNonSimplicity,
        templateBoundIssueViaRawTypeWithNonSimpleBounds,
        templateNonSimpleBoundViaReference,
        templateNonSimpleBoundViaVariable;

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
      return new KernelNamedTypeBuilder(
          type.outlineListener, type.charOffset, type.name, arguments)
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
      return new KernelFunctionTypeBuilder(type.outlineListener,
          type.charOffset, returnType, variables, formals);
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

/// Finds all type builders for [variable] in [type].
///
/// Returns list of the found type builders.
List<NamedTypeBuilder<TypeBuilder, Object>> findVariableUsesInType(
  TypeVariableBuilder<TypeBuilder, Object> variable,
  TypeBuilder type,
) {
  var uses = <NamedTypeBuilder<TypeBuilder, Object>>[];
  if (type is NamedTypeBuilder) {
    if (type.declaration == variable) {
      uses.add(type);
    } else {
      if (type.arguments != null) {
        for (TypeBuilder argument in type.arguments) {
          uses.addAll(findVariableUsesInType(variable, argument));
        }
      }
    }
  } else if (type is FunctionTypeBuilder) {
    uses.addAll(findVariableUsesInType(variable, type.returnType));
    if (type.typeVariables != null) {
      for (TypeVariableBuilder<TypeBuilder, Object> dependentVariable
          in type.typeVariables) {
        if (dependentVariable.bound != null) {
          uses.addAll(
              findVariableUsesInType(variable, dependentVariable.bound));
        }
        if (dependentVariable.defaultType != null) {
          uses.addAll(
              findVariableUsesInType(variable, dependentVariable.defaultType));
        }
      }
    }
    if (type.formals != null) {
      for (FormalParameterBuilder<TypeBuilder> formal in type.formals) {
        uses.addAll(findVariableUsesInType(variable, formal.type));
      }
    }
  }
  return uses;
}

/// Finds those of [variables] that reference other [variables] in their bounds.
///
/// Returns flattened list of pairs.  The first element in the pair is the type
/// variable builder from [variables] that references other [variables] in its
/// bound.  The second element in the pair is the list of found references
/// represented as type builders.
List<Object> findInboundReferences(
    List<TypeVariableBuilder<TypeBuilder, Object>> variables) {
  var variablesAndDependencies = <Object>[];
  for (TypeVariableBuilder<TypeBuilder, Object> dependent in variables) {
    var dependencies = <NamedTypeBuilder<TypeBuilder, Object>>[];
    for (TypeVariableBuilder<TypeBuilder, Object> dependence in variables) {
      List<NamedTypeBuilder<TypeBuilder, Object>> uses =
          findVariableUsesInType(dependence, dependent.bound);
      if (uses.length != 0) {
        dependencies.addAll(uses);
      }
    }
    if (dependencies.length != 0) {
      variablesAndDependencies.add(dependent);
      variablesAndDependencies.add(dependencies);
    }
  }
  return variablesAndDependencies;
}

/// Finds raw generic types in [type] with inbound references in type variables.
///
/// Returns flattened list of pairs.  The first element in the pair is the found
/// raw generic type.  The second element in the pair is the list of type
/// variables of that type with inbound references in the format specified in
/// [findInboundReferences].
List<Object> findRawTypesWithInboundReferences(TypeBuilder type) {
  var typesAndDependencies = <Object>[];
  if (type is NamedTypeBuilder<TypeBuilder, Object>) {
    if (type.arguments == null) {
      TypeDeclarationBuilder<TypeBuilder, Object> declaration =
          type.declaration;
      if (declaration is DillClassBuilder) {
        bool hasInbound = false;
        List<TypeParameter> typeParameters = declaration.target.typeParameters;
        for (int i = 0; i < typeParameters.length && !hasInbound; ++i) {
          if (containsTypeVariable(
              typeParameters[i].bound, typeParameters.toSet())) {
            hasInbound = true;
          }
        }
        if (hasInbound) {
          typesAndDependencies.add(type);
          typesAndDependencies.add(const <Object>[]);
        }
      } else if (declaration is DillFunctionTypeAliasBuilder) {
        bool hasInbound = false;
        List<TypeParameter> typeParameters = declaration.target.typeParameters;
        for (int i = 0; i < typeParameters.length && !hasInbound; ++i) {
          if (containsTypeVariable(
              typeParameters[i].bound, typeParameters.toSet())) {
            hasInbound = true;
          }
        }
        if (hasInbound) {
          typesAndDependencies.add(type);
          typesAndDependencies.add(const <Object>[]);
        }
      } else if (declaration is ClassBuilder<TypeBuilder, Object> &&
          declaration.typeVariables != null) {
        List<Object> dependencies =
            findInboundReferences(declaration.typeVariables);
        if (dependencies.length != 0) {
          typesAndDependencies.add(type);
          typesAndDependencies.add(dependencies);
        }
      } else if (declaration is FunctionTypeAliasBuilder<TypeBuilder, Object> &&
          declaration.typeVariables != null) {
        List<Object> dependencies =
            findInboundReferences(declaration.typeVariables);
        if (dependencies.length != 0) {
          typesAndDependencies.add(type);
          typesAndDependencies.add(dependencies);
        }
      }
    } else {
      for (TypeBuilder argument in type.arguments) {
        typesAndDependencies
            .addAll(findRawTypesWithInboundReferences(argument));
      }
    }
  } else if (type is FunctionTypeBuilder) {
    typesAndDependencies
        .addAll(findRawTypesWithInboundReferences(type.returnType));
    if (type.typeVariables != null) {
      for (TypeVariableBuilder<TypeBuilder, Object> variable
          in type.typeVariables) {
        if (variable.bound != null) {
          typesAndDependencies
              .addAll(findRawTypesWithInboundReferences(variable.bound));
        }
        if (variable.defaultType != null) {
          typesAndDependencies
              .addAll(findRawTypesWithInboundReferences(variable.defaultType));
        }
      }
    }
    if (type.formals != null) {
      for (FormalParameterBuilder<TypeBuilder> formal in type.formals) {
        typesAndDependencies
            .addAll(findRawTypesWithInboundReferences(formal.type));
      }
    }
  }
  return typesAndDependencies;
}

/// Finds issues by raw generic types with inbound references in type variables.
///
/// Returns flattened list of triplets.  The first element of the triplet is the
/// [TypeDeclarationBuilder] for the type variable from [variables] that has raw
/// generic types with inbound references in its bound.  The second element of
/// the triplet is the error message.  The third element is the context.
List<Object> getInboundReferenceIssues(
    List<TypeVariableBuilder<TypeBuilder, Object>> variables) {
  var issues = <Object>[];
  for (TypeVariableBuilder<TypeBuilder, Object> variable in variables) {
    if (variable.bound != null) {
      List<Object> rawTypesAndMutualDependencies =
          findRawTypesWithInboundReferences(variable.bound);
      for (int i = 0; i < rawTypesAndMutualDependencies.length; i += 2) {
        NamedTypeBuilder<TypeBuilder, Object> type =
            rawTypesAndMutualDependencies[i];
        List<Object> variablesAndDependencies =
            rawTypesAndMutualDependencies[i + 1];
        for (int j = 0; j < variablesAndDependencies.length; j += 2) {
          TypeVariableBuilder<TypeBuilder, Object> dependent =
              variablesAndDependencies[j];
          List<NamedTypeBuilder<TypeBuilder, Object>> dependencies =
              variablesAndDependencies[j + 1];
          for (NamedTypeBuilder<TypeBuilder, Object> dependency
              in dependencies) {
            issues.add(variable);
            issues.add(templateBoundIssueViaRawTypeWithNonSimpleBounds
                .withArguments(type.declaration.name));
            issues.add(<LocatedMessage>[
              templateNonSimpleBoundViaVariable
                  .withArguments(dependency.declaration.name)
                  .withLocation(dependent.fileUri, dependent.charOffset,
                      dependent.name.length)
            ]);
          }
        }
        if (variablesAndDependencies.length == 0) {
          // The inbound references are in a compiled declaration in a .dill.
          issues.add(variable);
          issues.add(templateBoundIssueViaRawTypeWithNonSimpleBounds
              .withArguments(type.declaration.name));
          issues.add(const <LocatedMessage>[]);
        }
      }
    }
  }
  return issues;
}

/// Finds raw type paths starting from those in [start] and ending with [end].
///
/// Returns list of found paths.  Each path is represented as a list of
/// alternating builders of the raw generic types from the path and builders of
/// type variables of the immediately preceding types that contain the reference
/// to the next raw generic type in the path.  The list ends with the type
/// builder for [end].
///
/// The reason for putting the type variables into the paths as well as for
/// using type for [start], and not the corresponding type declaration,
/// is better error reporting.
List<List<Object>> findRawTypePathsToDeclaration(
    TypeBuilder start, TypeDeclarationBuilder<TypeBuilder, Object> end,
    [Set<TypeDeclarationBuilder<TypeBuilder, Object>> visited]) {
  visited ??= new Set<TypeDeclarationBuilder<TypeBuilder, Object>>.identity();
  var paths = <List<Object>>[];
  if (start is NamedTypeBuilder<TypeBuilder, Object>) {
    TypeDeclarationBuilder<TypeBuilder, Object> declaration = start.declaration;
    if (start.arguments == null) {
      if (start.declaration == end) {
        paths.add(<Object>[start]);
      } else if (visited.add(start.declaration)) {
        if (declaration is ClassBuilder<TypeBuilder, Object> &&
            declaration.typeVariables != null) {
          for (TypeVariableBuilder<TypeBuilder, Object> variable
              in declaration.typeVariables) {
            if (variable.bound != null) {
              for (List<Object> path in findRawTypePathsToDeclaration(
                  variable.bound, end, visited)) {
                paths.add(<Object>[start, variable]..addAll(path));
              }
            }
          }
        } else if (declaration
                is FunctionTypeAliasBuilder<TypeBuilder, Object> &&
            declaration.typeVariables != null) {
          for (TypeVariableBuilder<TypeBuilder, Object> variable
              in declaration.typeVariables) {
            if (variable.bound != null) {
              for (List<Object> dependencyPath in findRawTypePathsToDeclaration(
                  variable.bound, end, visited)) {
                paths.add(<Object>[start, variable]..addAll(dependencyPath));
              }
            }
          }
        }
        visited.remove(start.declaration);
      }
    } else {
      for (TypeBuilder argument in start.arguments) {
        paths.addAll(findRawTypePathsToDeclaration(argument, end, visited));
      }
    }
  } else if (start is FunctionTypeBuilder) {
    paths.addAll(findRawTypePathsToDeclaration(start.returnType, end, visited));
    if (start.typeVariables != null) {
      for (TypeVariableBuilder<TypeBuilder, Object> variable
          in start.typeVariables) {
        if (variable.bound != null) {
          paths.addAll(
              findRawTypePathsToDeclaration(variable.bound, end, visited));
        }
        if (variable.defaultType != null) {
          paths.addAll(findRawTypePathsToDeclaration(
              variable.defaultType, end, visited));
        }
      }
    }
    if (start.formals != null) {
      for (FormalParameterBuilder<TypeBuilder> formal in start.formals) {
        paths.addAll(findRawTypePathsToDeclaration(formal.type, end, visited));
      }
    }
  }
  return paths;
}

/// Finds raw generic type cycles ending and starting with [declaration].
///
/// Returns list of found cycles.  Each cycle is represented as a list of
/// alternating raw generic types from the cycle and type variables of the
/// immediately preceding type that reference the next type in the cycle.  The
/// cycle starts with a type variable from [declaration] and ends with a type
/// that has [declaration] as its declaration.
///
/// The reason for putting the type variables into the cycles is better error
/// reporting.
List<List<Object>> findRawTypeCycles(
    TypeDeclarationBuilder<TypeBuilder, Object> declaration) {
  var cycles = <List<Object>>[];
  if (declaration is ClassBuilder<TypeBuilder, Object> &&
      declaration.typeVariables != null) {
    for (TypeVariableBuilder<TypeBuilder, Object> variable
        in declaration.typeVariables) {
      if (variable.bound != null) {
        for (List<Object> path
            in findRawTypePathsToDeclaration(variable.bound, declaration)) {
          cycles.add(<Object>[variable]..addAll(path));
        }
      }
    }
  } else if (declaration is FunctionTypeAliasBuilder<TypeBuilder, Object> &&
      declaration.typeVariables != null) {
    for (TypeVariableBuilder<TypeBuilder, Object> variable
        in declaration.typeVariables) {
      if (variable.bound != null) {
        for (List<Object> dependencyPath
            in findRawTypePathsToDeclaration(variable.bound, declaration)) {
          cycles.add(<Object>[variable]..addAll(dependencyPath));
        }
      }
    }
  }
  return cycles;
}

/// Converts raw generic type [cycles] for [declaration] into reportable issues.
///
/// The [cycles] are expected to be in the format specified for the return value
/// of [findRawTypeCycles].
///
/// Returns flattened list of triplets.  The first element of the triplet is the
/// [TypeDeclarationBuilder] for the type variable from [variables] that has raw
/// generic types with inbound references in its bound.  The second element of
/// the triplet is the error message.  The third element is the context.
List<Object> convertRawTypeCyclesIntoIssues(
    TypeDeclarationBuilder<TypeBuilder, Object> declaration,
    List<List<Object>> cycles) {
  List<Object> issues = <Object>[];
  for (List<Object> cycle in cycles) {
    if (cycle.length == 2) {
      // Loop.
      TypeVariableBuilder<TypeBuilder, Object> variable = cycle[0];
      NamedTypeBuilder<TypeBuilder, Object> type = cycle[1];
      issues.add(variable);
      issues.add(templateBoundIssueViaLoopNonSimplicity
          .withArguments(type.declaration.name));
      issues.add(null); // Context.
    } else {
      var context = <LocatedMessage>[];
      for (int i = 0; i < cycle.length; i += 2) {
        TypeVariableBuilder<TypeBuilder, Object> variable = cycle[i];
        NamedTypeBuilder<TypeBuilder, Object> type = cycle[i + 1];
        context.add(templateNonSimpleBoundViaReference
            .withArguments(type.declaration.name)
            .withLocation(
                variable.fileUri, variable.charOffset, variable.name.length));
      }
      NamedTypeBuilder<TypeBuilder, Object> firstEncounteredType = cycle[1];

      issues.add(declaration);
      issues.add(templateBoundIssueViaCycleNonSimplicity.withArguments(
          declaration.name, firstEncounteredType.declaration.name));
      issues.add(context);
    }
  }
  return issues;
}

/// Finds issues by cycles of raw generic types containing [declaration].
///
/// Returns flattened list of triplets according to the format specified by
/// [convertRawTypeCyclesIntoIssues].
List<Object> getRawTypeCycleIssues(
    TypeDeclarationBuilder<TypeBuilder, Object> declaration) {
  return convertRawTypeCyclesIntoIssues(
      declaration, findRawTypeCycles(declaration));
}

/// Finds non-simplicity issues for the given set of [variables].
///
/// The issues are those caused by raw types with inbound references in the
/// bounds of their type variables.
///
/// Returns flattened list of triplets, each triplet representing an issue.  The
/// first element in the triplet is the type declaration that has the issue.
/// The second element in the triplet is the error message.  The third element
/// in the triplet is the context.
List<Object> getNonSimplicityIssuesForTypeVariables(
    List<TypeVariableBuilder<TypeBuilder, Object>> variables) {
  if (variables == null) return <Object>[];
  return getInboundReferenceIssues(variables);
}

/// Finds non-simplicity issues for the given [declaration].
///
/// The issues are those caused by raw types with inbound references in the
/// bounds of type variables from [declaration] and by cycles of raw types
/// containing [declaration].
///
/// Returns flattened list of triplets, each triplet representing an issue.  The
/// first element in the triplet is the type declaration that has the issue.
/// The second element in the triplet is the error message.  The third element
/// in the triplet is the context.
List<Object> getNonSimplicityIssuesForDeclaration(
    TypeDeclarationBuilder<TypeBuilder, Object> declaration) {
  var issues = <Object>[];
  if (declaration is ClassBuilder<TypeBuilder, Object> &&
      declaration.typeVariables != null) {
    issues.addAll(getInboundReferenceIssues(declaration.typeVariables));
  } else if (declaration is FunctionTypeAliasBuilder<TypeBuilder, Object> &&
      declaration.typeVariables != null) {
    issues.addAll(getInboundReferenceIssues(declaration.typeVariables));
  }
  List<List<Object>> cyclesToReport = <List<Object>>[];
  for (List<Object> cycle in findRawTypeCycles(declaration)) {
    // To avoid reporting the same error for each element of the cycle, we only
    // do so if it comes the first in the lexicographical order.  Note that
    // one-element cycles shouldn't be checked, as they are loops.
    if (cycle.length == 2) {
      cyclesToReport.add(cycle);
    } else {
      String declarationPathAndName =
          "${declaration.fileUri}:${declaration.name}";
      String lexMinPathAndName = null;
      for (int i = 1; i < cycle.length; i += 2) {
        NamedTypeBuilder<TypeBuilder, Object> type = cycle[i];
        String pathAndName =
            "${type.declaration.fileUri}:${type.declaration.name}";
        if (lexMinPathAndName == null ||
            lexMinPathAndName.compareTo(pathAndName) > 0) {
          lexMinPathAndName = pathAndName;
        }
      }
      if (declarationPathAndName == lexMinPathAndName) {
        cyclesToReport.add(cycle);
      }
    }
  }
  issues.addAll(convertRawTypeCyclesIntoIssues(declaration, cyclesToReport));
  return issues;
}

void findGenericFunctionTypes(TypeBuilder type, {List<TypeBuilder> result}) {
  result ??= <TypeBuilder>[];
  if (type is FunctionTypeBuilder) {
    if (type.typeVariables != null && type.typeVariables.length > 0) {
      result.add(type);

      for (TypeVariableBuilder<TypeBuilder, Object> typeVariable
          in type.typeVariables) {
        findGenericFunctionTypes(typeVariable.bound, result: result);
        findGenericFunctionTypes(typeVariable.defaultType, result: result);
      }
    }
    findGenericFunctionTypes(type.returnType, result: result);
    if (type.formals != null) {
      for (FormalParameterBuilder<TypeBuilder> formal in type.formals) {
        findGenericFunctionTypes(formal.type, result: result);
      }
    }
  } else if (type is NamedTypeBuilder<TypeBuilder, Object> &&
      type.arguments != null) {
    for (TypeBuilder argument in type.arguments) {
      findGenericFunctionTypes(argument, result: result);
    }
  }
}
