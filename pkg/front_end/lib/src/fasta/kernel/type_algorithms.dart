// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart'
    show
        BottomType,
        DartType,
        DartTypeVisitor,
        DynamicType,
        FunctionType,
        FutureOrType,
        InterfaceType,
        InvalidType,
        NamedType,
        NeverType,
        NullType,
        TypeParameter,
        TypeParameterType,
        TypedefType,
        Variance,
        VoidType;

import 'package:kernel/type_algebra.dart' show containsTypeVariable;

import 'package:kernel/util/graph.dart' show Graph, computeStrongComponents;

import '../builder/class_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/function_type_builder.dart';
import '../builder/invalid_type_declaration_builder.dart';
import '../builder/library_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/type_alias_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_declaration_builder.dart';
import '../builder/type_variable_builder.dart';

import '../dill/dill_class_builder.dart' show DillClassBuilder;

import '../dill/dill_type_alias_builder.dart' show DillTypeAliasBuilder;

import '../fasta_codes.dart'
    show
        LocatedMessage,
        templateBoundIssueViaCycleNonSimplicity,
        templateBoundIssueViaLoopNonSimplicity,
        templateBoundIssueViaRawTypeWithNonSimpleBounds,
        templateCyclicTypedef,
        templateNonSimpleBoundViaReference,
        templateNonSimpleBoundViaVariable;

export 'package:kernel/ast.dart' show Variance;

/// Initial value for "variance" that is to be computed by the compiler.
const int pendingVariance = -1;

// Computes the variance of a variable in a type.  The function can be run
// before the types are resolved to compute variances of typedefs' type
// variables.  For that case if the type has its declaration set to null and its
// name matches that of the variable, it's interpreted as an occurrence of a
// type variable.
int computeTypeVariableBuilderVariance(TypeVariableBuilder variable,
    TypeBuilder type, LibraryBuilder libraryBuilder) {
  if (type is NamedTypeBuilder) {
    assert(type.declaration != null);
    TypeDeclarationBuilder declaration = type.declaration;
    if (declaration is TypeVariableBuilder) {
      if (declaration == variable) {
        return Variance.covariant;
      } else {
        return Variance.unrelated;
      }
    } else {
      if (declaration is ClassBuilder) {
        int result = Variance.unrelated;
        if (type.arguments != null) {
          for (int i = 0; i < type.arguments.length; ++i) {
            result = Variance.meet(
                result,
                Variance.combine(
                    declaration.cls.typeParameters[i].variance,
                    computeTypeVariableBuilderVariance(
                        variable, type.arguments[i], libraryBuilder)));
          }
        }
        return result;
      } else if (declaration is TypeAliasBuilder) {
        int result = Variance.unrelated;

        if (type.arguments != null) {
          for (int i = 0; i < type.arguments.length; ++i) {
            const int visitMarker = -2;

            int declarationTypeVariableVariance = declaration.varianceAt(i);
            if (declarationTypeVariableVariance == pendingVariance) {
              assert(!declaration.fromDill);
              TypeVariableBuilder declarationTypeVariable =
                  declaration.typeVariables[i];
              declarationTypeVariable.variance = visitMarker;
              int computedVariance = computeTypeVariableBuilderVariance(
                  declarationTypeVariable, declaration.type, libraryBuilder);
              declarationTypeVariableVariance =
                  declarationTypeVariable.variance = computedVariance;
            } else if (declarationTypeVariableVariance == visitMarker) {
              assert(!declaration.fromDill);
              TypeVariableBuilder declarationTypeVariable =
                  declaration.typeVariables[i];
              libraryBuilder.addProblem(
                  templateCyclicTypedef.withArguments(declaration.name),
                  declaration.charOffset,
                  declaration.name.length,
                  declaration.fileUri);
              // Use [Variance.unrelated] for recovery.  The type with the
              // cyclic dependency will be replaced with an [InvalidType]
              // elsewhere.
              declarationTypeVariableVariance =
                  declarationTypeVariable.variance = Variance.unrelated;
            }

            result = Variance.meet(
                result,
                Variance.combine(
                    computeTypeVariableBuilderVariance(
                        variable, type.arguments[i], libraryBuilder),
                    declarationTypeVariableVariance));
          }
        }
        return result;
      }
    }
  } else if (type is FunctionTypeBuilder) {
    int result = Variance.unrelated;
    if (type.returnType != null) {
      result = Variance.meet(
          result,
          computeTypeVariableBuilderVariance(
              variable, type.returnType, libraryBuilder));
    }
    if (type.typeVariables != null) {
      for (TypeVariableBuilder typeVariable in type.typeVariables) {
        // If [variable] is referenced in the bound at all, it makes the
        // variance of [variable] in the entire type invariant.  The invocation
        // of [computeVariance] below is made to simply figure out if [variable]
        // occurs in the bound.
        if (typeVariable.bound != null &&
            computeTypeVariableBuilderVariance(
                    variable, typeVariable.bound, libraryBuilder) !=
                Variance.unrelated) {
          result = Variance.invariant;
        }
      }
    }
    if (type.formals != null) {
      for (FormalParameterBuilder formal in type.formals) {
        result = Variance.meet(
            result,
            Variance.combine(
                Variance.contravariant,
                computeTypeVariableBuilderVariance(
                    variable, formal.type, libraryBuilder)));
      }
    }
    return result;
  }
  return Variance.unrelated;
}

/// Combines syntactic nullabilities on types for performing type substitution.
///
/// The syntactic substitution should preserve a `?` if it was either on the
/// type parameter occurrence or on the type argument replacing it.
NullabilityBuilder combineNullabilityBuildersForSubstitution(
    NullabilityBuilder a, NullabilityBuilder b) {
  assert(
      (identical(a, const NullabilityBuilder.nullable()) ||
              identical(a, const NullabilityBuilder.omitted())) &&
          (identical(b, const NullabilityBuilder.nullable()) ||
              identical(b, const NullabilityBuilder.omitted())),
      "Both arguments to combineNullabilityBuildersForSubstitution "
      "should be identical to either 'const NullabilityBuilder.nullable()' or "
      "'const NullabilityBuilder.omitted()'.");

  if (identical(a, const NullabilityBuilder.nullable()) ||
      identical(b, const NullabilityBuilder.nullable())) {
    return const NullabilityBuilder.nullable();
  }

  return const NullabilityBuilder.omitted();
}

TypeBuilder substituteRange(
    TypeBuilder type,
    Map<TypeVariableBuilder, TypeBuilder> upperSubstitution,
    Map<TypeVariableBuilder, TypeBuilder> lowerSubstitution,
    List<TypeBuilder> unboundTypes,
    List<TypeVariableBuilder> unboundTypeVariables,
    {final int variance = Variance.covariant}) {
  if (type is NamedTypeBuilder) {
    if (type.declaration is TypeVariableBuilder) {
      if (variance == Variance.contravariant) {
        TypeBuilder replacement = lowerSubstitution[type.declaration];
        if (replacement != null) {
          return replacement.withNullabilityBuilder(
              combineNullabilityBuildersForSubstitution(
                  replacement.nullabilityBuilder, type.nullabilityBuilder));
        }
        return type;
      }
      TypeBuilder replacement = upperSubstitution[type.declaration];
      if (replacement != null) {
        return replacement.withNullabilityBuilder(
            combineNullabilityBuildersForSubstitution(
                replacement.nullabilityBuilder, type.nullabilityBuilder));
      }
      return type;
    }
    if (type.arguments == null || type.arguments.length == 0) {
      return type;
    }
    List<TypeBuilder> arguments;
    TypeDeclarationBuilder declaration = type.declaration;
    if (declaration == null) {
      assert(unboundTypes != null,
          "Can not handle unbound named type builders without `unboundTypes`.");
      assert(
          unboundTypeVariables != null,
          "Can not handle unbound named type builders without "
          "`unboundTypeVariables`.");
      assert(
          identical(upperSubstitution, lowerSubstitution),
          "Can only handle unbound named type builders identical "
          "`upperSubstitution` and `lowerSubstitution`.");
      for (int i = 0; i < type.arguments.length; ++i) {
        TypeBuilder substitutedArgument = substituteRange(
            type.arguments[i],
            upperSubstitution,
            lowerSubstitution,
            unboundTypes,
            unboundTypeVariables,
            variance: variance);
        if (substitutedArgument != type.arguments[i]) {
          arguments ??= type.arguments.toList();
          arguments[i] = substitutedArgument;
        }
      }
    } else if (declaration is ClassBuilder) {
      for (int i = 0; i < type.arguments.length; ++i) {
        TypeBuilder substitutedArgument = substituteRange(
            type.arguments[i],
            upperSubstitution,
            lowerSubstitution,
            unboundTypes,
            unboundTypeVariables,
            variance: variance);
        if (substitutedArgument != type.arguments[i]) {
          arguments ??= type.arguments.toList();
          arguments[i] = substitutedArgument;
        }
      }
    } else if (declaration is TypeAliasBuilder) {
      for (int i = 0; i < type.arguments.length; ++i) {
        TypeVariableBuilder variable = declaration.typeVariables[i];
        TypeBuilder substitutedArgument = substituteRange(
            type.arguments[i],
            upperSubstitution,
            lowerSubstitution,
            unboundTypes,
            unboundTypeVariables,
            variance: Variance.combine(variance, variable.variance));
        if (substitutedArgument != type.arguments[i]) {
          arguments ??= type.arguments.toList();
          arguments[i] = substitutedArgument;
        }
      }
    } else if (declaration is InvalidTypeDeclarationBuilder) {
      // Don't substitute.
    } else {
      assert(false, "Unexpected named type builder declaration: $declaration.");
    }
    if (arguments != null) {
      NamedTypeBuilder newTypeBuilder = new NamedTypeBuilder(type.name,
          type.nullabilityBuilder, arguments, type.fileUri, type.charOffset);
      if (declaration != null) {
        newTypeBuilder.bind(declaration);
      } else {
        unboundTypes.add(newTypeBuilder);
      }
      return newTypeBuilder;
    }
    return type;
  } else if (type is FunctionTypeBuilder) {
    List<TypeVariableBuilder> variables;
    if (type.typeVariables != null) {
      variables =
          new List<TypeVariableBuilder>.filled(type.typeVariables.length, null);
    }
    List<FormalParameterBuilder> formals;
    if (type.formals != null) {
      formals =
          new List<FormalParameterBuilder>.filled(type.formals.length, null);
    }
    TypeBuilder returnType;
    bool changed = false;

    Map<TypeVariableBuilder, TypeBuilder> functionTypeUpperSubstitution;
    Map<TypeVariableBuilder, TypeBuilder> functionTypeLowerSubstitution;
    if (type.typeVariables != null) {
      for (int i = 0; i < variables.length; i++) {
        TypeVariableBuilder variable = type.typeVariables[i];
        TypeBuilder bound = substituteRange(variable.bound, upperSubstitution,
            lowerSubstitution, unboundTypes, unboundTypeVariables,
            variance: Variance.invariant);
        if (bound != variable.bound) {
          TypeVariableBuilder newTypeVariableBuilder = variables[i] =
              new TypeVariableBuilder(
                  variable.name, variable.parent, variable.charOffset,
                  bound: bound);
          unboundTypeVariables.add(newTypeVariableBuilder);
          if (functionTypeUpperSubstitution == null) {
            functionTypeUpperSubstitution = {}..addAll(upperSubstitution);
            functionTypeLowerSubstitution = {}..addAll(lowerSubstitution);
          }
          functionTypeUpperSubstitution[variable] =
              functionTypeLowerSubstitution[variable] =
                  new NamedTypeBuilder.fromTypeDeclarationBuilder(
                      newTypeVariableBuilder,
                      const NullabilityBuilder.omitted());
          changed = true;
        } else {
          variables[i] = variable;
        }
      }
    }
    if (type.formals != null) {
      for (int i = 0; i < formals.length; i++) {
        FormalParameterBuilder formal = type.formals[i];
        TypeBuilder parameterType = substituteRange(
            formal.type,
            functionTypeUpperSubstitution ?? upperSubstitution,
            functionTypeLowerSubstitution ?? lowerSubstitution,
            unboundTypes,
            unboundTypeVariables,
            variance: Variance.combine(variance, Variance.contravariant));
        if (parameterType != formal.type) {
          formals[i] = new FormalParameterBuilder(
              formal.metadata,
              formal.modifiers,
              parameterType,
              formal.name,
              formal.parent,
              formal.charOffset,
              fileUri: formal.fileUri,
              isExtensionThis: formal.isExtensionThis);
          changed = true;
        } else {
          formals[i] = formal;
        }
      }
    }
    returnType = substituteRange(
        type.returnType,
        functionTypeUpperSubstitution ?? upperSubstitution,
        functionTypeLowerSubstitution ?? lowerSubstitution,
        unboundTypes,
        unboundTypeVariables,
        variance: variance);
    changed = changed || returnType != type.returnType;

    if (changed) {
      return new FunctionTypeBuilder(returnType, variables, formals,
          type.nullabilityBuilder, type.fileUri, type.charOffset);
    }
    return type;
  }
  return type;
}

TypeBuilder substitute(
    TypeBuilder type, Map<TypeVariableBuilder, TypeBuilder> substitution,
    {List<TypeBuilder> unboundTypes,
    List<TypeVariableBuilder> unboundTypeVariables}) {
  return substituteRange(
      type, substitution, substitution, unboundTypes, unboundTypeVariables,
      variance: Variance.covariant);
}

/// Calculates bounds to be provided as type arguments in place of missing type
/// arguments on raw types with the given type parameters.
///
/// See the [description]
/// (https://github.com/dart-lang/sdk/blob/master/docs/language/informal/instantiate-to-bound.md)
/// of the algorithm for details.
List<TypeBuilder> calculateBounds(List<TypeVariableBuilder> variables,
    TypeBuilder dynamicType, TypeBuilder bottomType, ClassBuilder objectClass) {
  List<TypeBuilder> bounds =
      new List<TypeBuilder>.filled(variables.length, null);

  for (int i = 0; i < variables.length; i++) {
    bounds[i] = variables[i].bound ?? dynamicType;
  }

  TypeVariablesGraph graph = new TypeVariablesGraph(variables, bounds);
  List<List<int>> stronglyConnected = computeStrongComponents(graph);
  for (List<int> component in stronglyConnected) {
    Map<TypeVariableBuilder, TypeBuilder> dynamicSubstitution =
        <TypeVariableBuilder, TypeBuilder>{};
    Map<TypeVariableBuilder, TypeBuilder> nullSubstitution =
        <TypeVariableBuilder, TypeBuilder>{};
    for (int variableIndex in component) {
      dynamicSubstitution[variables[variableIndex]] = dynamicType;
      nullSubstitution[variables[variableIndex]] = bottomType;
    }
    for (int variableIndex in component) {
      TypeVariableBuilder variable = variables[variableIndex];
      bounds[variableIndex] = substituteRange(bounds[variableIndex],
          dynamicSubstitution, nullSubstitution, null, null,
          variance: variable.variance);
    }
  }

  for (int i = 0; i < variables.length; i++) {
    Map<TypeVariableBuilder, TypeBuilder> substitution =
        <TypeVariableBuilder, TypeBuilder>{};
    Map<TypeVariableBuilder, TypeBuilder> nullSubstitution =
        <TypeVariableBuilder, TypeBuilder>{};
    substitution[variables[i]] = bounds[i];
    nullSubstitution[variables[i]] = bottomType;
    for (int j = 0; j < variables.length; j++) {
      TypeVariableBuilder variable = variables[j];
      bounds[j] = substituteRange(
          bounds[j], substitution, nullSubstitution, null, null,
          variance: variable.variance);
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

    vertices = new List<int>.filled(variables.length, null);
    Map<TypeVariableBuilder, int> variableIndices =
        <TypeVariableBuilder, int>{};
    edges = new List<List<int>>.filled(variables.length, null);
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
List<NamedTypeBuilder> findVariableUsesInType(
  TypeVariableBuilder variable,
  TypeBuilder type,
) {
  List<NamedTypeBuilder> uses = <NamedTypeBuilder>[];
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
      for (TypeVariableBuilder dependentVariable in type.typeVariables) {
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
      for (FormalParameterBuilder formal in type.formals) {
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
List<Object> findInboundReferences(List<TypeVariableBuilder> variables) {
  List<Object> variablesAndDependencies = <Object>[];
  for (TypeVariableBuilder dependent in variables) {
    List<NamedTypeBuilder> dependencies = <NamedTypeBuilder>[];
    for (TypeVariableBuilder dependence in variables) {
      List<NamedTypeBuilder> uses =
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
  List<Object> typesAndDependencies = <Object>[];
  if (type is NamedTypeBuilder) {
    if (type.arguments == null) {
      TypeDeclarationBuilder declaration = type.declaration;
      if (declaration is DillClassBuilder) {
        bool hasInbound = false;
        List<TypeParameter> typeParameters = declaration.cls.typeParameters;
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
      } else if (declaration is DillTypeAliasBuilder) {
        bool hasInbound = false;
        List<TypeParameter> typeParameters = declaration.typedef.typeParameters;
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
      } else if (declaration is ClassBuilder &&
          declaration.typeVariables != null) {
        List<Object> dependencies =
            findInboundReferences(declaration.typeVariables);
        if (dependencies.length != 0) {
          typesAndDependencies.add(type);
          typesAndDependencies.add(dependencies);
        }
      } else if (declaration is TypeAliasBuilder) {
        if (declaration.typeVariables != null) {
          List<Object> dependencies =
              findInboundReferences(declaration.typeVariables);
          if (dependencies.length != 0) {
            typesAndDependencies.add(type);
            typesAndDependencies.add(dependencies);
          }
        }
        if (declaration.type is FunctionTypeBuilder) {
          FunctionTypeBuilder type = declaration.type;
          if (type.typeVariables != null) {
            List<Object> dependencies =
                findInboundReferences(type.typeVariables);
            if (dependencies.length != 0) {
              typesAndDependencies.add(type);
              typesAndDependencies.add(dependencies);
            }
          }
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
      for (TypeVariableBuilder variable in type.typeVariables) {
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
      for (FormalParameterBuilder formal in type.formals) {
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
List<Object> getInboundReferenceIssues(List<TypeVariableBuilder> variables) {
  List<Object> issues = <Object>[];
  for (TypeVariableBuilder variable in variables) {
    if (variable.bound != null) {
      List<Object> rawTypesAndMutualDependencies =
          findRawTypesWithInboundReferences(variable.bound);
      for (int i = 0; i < rawTypesAndMutualDependencies.length; i += 2) {
        NamedTypeBuilder type = rawTypesAndMutualDependencies[i];
        List<Object> variablesAndDependencies =
            rawTypesAndMutualDependencies[i + 1];
        for (int j = 0; j < variablesAndDependencies.length; j += 2) {
          TypeVariableBuilder dependent = variablesAndDependencies[j];
          List<NamedTypeBuilder> dependencies = variablesAndDependencies[j + 1];
          for (NamedTypeBuilder dependency in dependencies) {
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
    TypeBuilder start, TypeDeclarationBuilder end,
    [Set<TypeDeclarationBuilder> visited]) {
  visited ??= new Set<TypeDeclarationBuilder>.identity();
  List<List<Object>> paths = <List<Object>>[];
  if (start is NamedTypeBuilder) {
    TypeDeclarationBuilder declaration = start.declaration;
    if (start.arguments == null) {
      if (start.declaration == end) {
        paths.add(<Object>[start]);
      } else if (visited.add(start.declaration)) {
        if (declaration is ClassBuilder && declaration.typeVariables != null) {
          for (TypeVariableBuilder variable in declaration.typeVariables) {
            if (variable.bound != null) {
              for (List<Object> path in findRawTypePathsToDeclaration(
                  variable.bound, end, visited)) {
                paths.add(<Object>[start, variable]..addAll(path));
              }
            }
          }
        } else if (declaration is TypeAliasBuilder) {
          if (declaration.typeVariables != null) {
            for (TypeVariableBuilder variable in declaration.typeVariables) {
              if (variable.bound != null) {
                for (List<Object> dependencyPath
                    in findRawTypePathsToDeclaration(
                        variable.bound, end, visited)) {
                  paths.add(<Object>[start, variable]..addAll(dependencyPath));
                }
              }
            }
          }
          if (declaration.type is FunctionTypeBuilder) {
            FunctionTypeBuilder type = declaration.type;
            if (type.typeVariables != null) {
              for (TypeVariableBuilder variable in type.typeVariables) {
                if (variable.bound != null) {
                  for (List<Object> dependencyPath
                      in findRawTypePathsToDeclaration(
                          variable.bound, end, visited)) {
                    paths
                        .add(<Object>[start, variable]..addAll(dependencyPath));
                  }
                }
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
      for (TypeVariableBuilder variable in start.typeVariables) {
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
      for (FormalParameterBuilder formal in start.formals) {
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
List<List<Object>> findRawTypeCycles(TypeDeclarationBuilder declaration) {
  List<List<Object>> cycles = <List<Object>>[];
  if (declaration is ClassBuilder && declaration.typeVariables != null) {
    for (TypeVariableBuilder variable in declaration.typeVariables) {
      if (variable.bound != null) {
        for (List<Object> path
            in findRawTypePathsToDeclaration(variable.bound, declaration)) {
          cycles.add(<Object>[variable]..addAll(path));
        }
      }
    }
  } else if (declaration is TypeAliasBuilder) {
    if (declaration.typeVariables != null) {
      for (TypeVariableBuilder variable in declaration.typeVariables) {
        if (variable.bound != null) {
          for (List<Object> dependencyPath
              in findRawTypePathsToDeclaration(variable.bound, declaration)) {
            cycles.add(<Object>[variable]..addAll(dependencyPath));
          }
        }
      }
    }
    if (declaration.type is FunctionTypeBuilder) {
      FunctionTypeBuilder type = declaration.type;
      if (type.typeVariables != null) {
        for (TypeVariableBuilder variable in type.typeVariables) {
          if (variable.bound != null) {
            for (List<Object> dependencyPath
                in findRawTypePathsToDeclaration(variable.bound, declaration)) {
              cycles.add(<Object>[variable]..addAll(dependencyPath));
            }
          }
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
    TypeDeclarationBuilder declaration, List<List<Object>> cycles) {
  List<Object> issues = <Object>[];
  for (List<Object> cycle in cycles) {
    if (cycle.length == 2) {
      // Loop.
      TypeVariableBuilder variable = cycle[0];
      NamedTypeBuilder type = cycle[1];
      issues.add(variable);
      issues.add(templateBoundIssueViaLoopNonSimplicity
          .withArguments(type.declaration.name));
      issues.add(null); // Context.
    } else {
      List<LocatedMessage> context = <LocatedMessage>[];
      for (int i = 0; i < cycle.length; i += 2) {
        TypeVariableBuilder variable = cycle[i];
        NamedTypeBuilder type = cycle[i + 1];
        context.add(templateNonSimpleBoundViaReference
            .withArguments(type.declaration.name)
            .withLocation(
                variable.fileUri, variable.charOffset, variable.name.length));
      }
      NamedTypeBuilder firstEncounteredType = cycle[1];

      issues.add(declaration);
      issues.add(templateBoundIssueViaCycleNonSimplicity.withArguments(
          declaration.name, firstEncounteredType.declaration.name));
      issues.add(context);
    }
  }
  return issues;
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
    List<TypeVariableBuilder> variables) {
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
    TypeDeclarationBuilder declaration,
    {bool performErrorRecovery: true}) {
  List<Object> issues = <Object>[];
  if (declaration is ClassBuilder && declaration.typeVariables != null) {
    issues.addAll(getInboundReferenceIssues(declaration.typeVariables));
  } else if (declaration is TypeAliasBuilder &&
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
        NamedTypeBuilder type = cycle[i];
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
  List<Object> rawTypeCyclesAsIssues =
      convertRawTypeCyclesIntoIssues(declaration, cyclesToReport);
  issues.addAll(rawTypeCyclesAsIssues);

  if (performErrorRecovery) {
    breakCycles(cyclesToReport);
  }

  return issues;
}

/// Break raw generic type [cycles] as error recovery.
///
/// The [cycles] are expected to be in the format specified for the return value
/// of [findRawTypeCycles].
void breakCycles(List<List<Object>> cycles) {
  for (List<Object> cycle in cycles) {
    TypeVariableBuilder variable = cycle[0];
    variable.bound = null;
  }
}

void findGenericFunctionTypes(TypeBuilder type, {List<TypeBuilder> result}) {
  result ??= <TypeBuilder>[];
  if (type is FunctionTypeBuilder) {
    if (type.typeVariables != null && type.typeVariables.length > 0) {
      result.add(type);

      for (TypeVariableBuilder typeVariable in type.typeVariables) {
        findGenericFunctionTypes(typeVariable.bound, result: result);
        findGenericFunctionTypes(typeVariable.defaultType, result: result);
      }
    }
    findGenericFunctionTypes(type.returnType, result: result);
    if (type.formals != null) {
      for (FormalParameterBuilder formal in type.formals) {
        findGenericFunctionTypes(formal.type, result: result);
      }
    }
  } else if (type is NamedTypeBuilder && type.arguments != null) {
    for (TypeBuilder argument in type.arguments) {
      findGenericFunctionTypes(argument, result: result);
    }
  }
}

/// Returns true if [type] contains any type variables whatsoever. This should
/// only be used for working around transitional issues.
// TODO(ahe): Remove this method.
bool hasAnyTypeVariables(DartType type) {
  return type.accept(const TypeVariableSearch());
}

/// Don't use this directly, use [hasAnyTypeVariables] instead. But don't use
/// that either.
// TODO(ahe): Remove this class.
class TypeVariableSearch implements DartTypeVisitor<bool> {
  const TypeVariableSearch();

  bool defaultDartType(DartType node) => throw "unsupported";

  bool anyTypeVariables(List<DartType> types) {
    for (DartType type in types) {
      if (type.accept(this)) return true;
    }
    return false;
  }

  bool visitInvalidType(InvalidType node) => false;

  bool visitDynamicType(DynamicType node) => false;

  bool visitVoidType(VoidType node) => false;

  bool visitBottomType(BottomType node) => false;

  bool visitNeverType(NeverType node) => false;

  bool visitNullType(NullType node) => false;

  bool visitInterfaceType(InterfaceType node) {
    return anyTypeVariables(node.typeArguments);
  }

  bool visitFutureOrType(FutureOrType node) {
    return node.typeArgument.accept(this);
  }

  bool visitFunctionType(FunctionType node) {
    if (anyTypeVariables(node.positionalParameters)) return true;
    for (TypeParameter variable in node.typeParameters) {
      if (variable.bound.accept(this)) return true;
    }
    for (NamedType type in node.namedParameters) {
      if (type.type.accept(this)) return true;
    }
    return false;
  }

  bool visitTypeParameterType(TypeParameterType node) => true;

  bool visitTypedefType(TypedefType node) {
    return anyTypeVariables(node.typeArguments);
  }
}
