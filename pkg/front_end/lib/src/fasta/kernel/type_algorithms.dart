// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart';

import 'package:kernel/type_algebra.dart' show containsTypeVariable;

import 'package:kernel/util/graph.dart' show Graph, computeStrongComponents;

import '../builder/builtin_type_declaration_builder.dart';
import '../builder/class_builder.dart';
import '../builder/extension_builder.dart';
import '../builder/extension_type_declaration_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/function_type_builder.dart';
import '../builder/invalid_type_declaration_builder.dart';
import '../builder/library_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../builder/record_type_builder.dart';
import '../builder/type_alias_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_declaration_builder.dart';
import '../builder/type_variable_builder.dart';

import '../dill/dill_class_builder.dart' show DillClassBuilder;

import '../dill/dill_type_alias_builder.dart' show DillTypeAliasBuilder;

import '../fasta_codes.dart'
    show
        LocatedMessage,
        Message,
        templateBoundIssueViaCycleNonSimplicity,
        templateBoundIssueViaLoopNonSimplicity,
        templateBoundIssueViaRawTypeWithNonSimpleBounds,
        templateCyclicTypedef,
        templateNonSimpleBoundViaReference,
        templateNonSimpleBoundViaVariable;

import '../kernel/utils.dart';

import '../problems.dart';
import '../source/source_class_builder.dart';
import '../source/source_extension_builder.dart';
import '../source/source_extension_type_declaration_builder.dart';
import '../source/source_type_alias_builder.dart';

/// Initial value for "variance" that is to be computed by the compiler.
const int pendingVariance = -1;

// Computes the variance of a variable in a type.  The function can be run
// before the types are resolved to compute variances of typedefs' type
// variables.  For that case if the type has its declaration set to null and its
// name matches that of the variable, it's interpreted as an occurrence of a
// type variable.
int computeTypeVariableBuilderVariance(TypeVariableBuilder variable,
    TypeBuilder? type, LibraryBuilder libraryBuilder) {
  if (type is NamedTypeBuilder) {
    assert(type.declaration != null);
    TypeDeclarationBuilder? declaration = type.declaration;
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
          for (int i = 0; i < type.arguments!.length; ++i) {
            result = Variance.meet(
                result,
                Variance.combine(
                    declaration.cls.typeParameters[i].variance,
                    computeTypeVariableBuilderVariance(
                        variable, type.arguments![i], libraryBuilder)));
          }
        }
        return result;
      } else if (declaration is TypeAliasBuilder) {
        int result = Variance.unrelated;

        if (type.arguments != null) {
          for (int i = 0; i < type.arguments!.length; ++i) {
            const int visitMarker = -2;

            int declarationTypeVariableVariance = declaration.varianceAt(i);
            if (declarationTypeVariableVariance == pendingVariance) {
              assert(!declaration.fromDill);
              TypeVariableBuilder declarationTypeVariable =
                  declaration.typeVariables![i];
              declarationTypeVariable.variance = visitMarker;
              int computedVariance = computeTypeVariableBuilderVariance(
                  declarationTypeVariable, declaration.type, libraryBuilder);
              declarationTypeVariableVariance =
                  declarationTypeVariable.variance = computedVariance;
            } else if (declarationTypeVariableVariance == visitMarker) {
              assert(!declaration.fromDill);
              TypeVariableBuilder declarationTypeVariable =
                  declaration.typeVariables![i];
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
                        variable, type.arguments![i], libraryBuilder),
                    declarationTypeVariableVariance));
          }
        }
        return result;
      }
    }
  } else if (type is FunctionTypeBuilder) {
    int result = Variance.unrelated;
    if (type.returnType is! OmittedTypeBuilder) {
      result = Variance.meet(
          result,
          computeTypeVariableBuilderVariance(
              variable, type.returnType, libraryBuilder));
    }
    if (type.typeVariables != null) {
      for (TypeVariableBuilder typeVariable in type.typeVariables!) {
        // If [variable] is referenced in the bound at all, it makes the
        // variance of [variable] in the entire type invariant.  The invocation
        // of [computeVariance] below is made to simply figure out if [variable]
        // occurs in the bound.
        if (typeVariable.bound != null &&
            computeTypeVariableBuilderVariance(
                    variable, typeVariable.bound!, libraryBuilder) !=
                Variance.unrelated) {
          result = Variance.invariant;
        }
      }
    }
    if (type.formals != null) {
      for (ParameterBuilder formal in type.formals!) {
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
  if (identical(a, const NullabilityBuilder.inherent()) &&
      identical(b, const NullabilityBuilder.inherent())) {
    return const NullabilityBuilder.inherent();
  }
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
        TypeBuilder? replacement = lowerSubstitution[type.declaration];
        if (replacement != null) {
          return replacement.withNullabilityBuilder(
              combineNullabilityBuildersForSubstitution(
                  replacement.nullabilityBuilder, type.nullabilityBuilder));
        }
        return type;
      }
      TypeBuilder? replacement = upperSubstitution[type.declaration];
      if (replacement != null) {
        return replacement.withNullabilityBuilder(
            combineNullabilityBuildersForSubstitution(
                replacement.nullabilityBuilder, type.nullabilityBuilder));
      }
      return type;
    }
    if (type.arguments == null || type.arguments!.length == 0) {
      return type;
    }
    List<TypeBuilder>? arguments;
    TypeDeclarationBuilder? declaration = type.declaration;
    if (declaration == null) {
      assert(
          identical(upperSubstitution, lowerSubstitution),
          "Can only handle unbound named type builders identical "
          "`upperSubstitution` and `lowerSubstitution`.");
      for (int i = 0; i < type.arguments!.length; ++i) {
        TypeBuilder substitutedArgument = substituteRange(
            type.arguments![i],
            upperSubstitution,
            lowerSubstitution,
            unboundTypes,
            unboundTypeVariables,
            variance: variance);
        if (substitutedArgument != type.arguments![i]) {
          arguments ??= type.arguments!.toList();
          arguments[i] = substitutedArgument;
        }
      }
    } else if (declaration is ClassBuilder) {
      for (int i = 0; i < type.arguments!.length; ++i) {
        TypeBuilder substitutedArgument = substituteRange(
            type.arguments![i],
            upperSubstitution,
            lowerSubstitution,
            unboundTypes,
            unboundTypeVariables,
            variance: variance);
        if (substitutedArgument != type.arguments![i]) {
          arguments ??= type.arguments!.toList();
          arguments[i] = substitutedArgument;
        }
      }
    } else if (declaration is ExtensionTypeDeclarationBuilder) {
      for (int i = 0; i < type.arguments!.length; ++i) {
        TypeBuilder substitutedArgument = substituteRange(
            type.arguments![i],
            upperSubstitution,
            lowerSubstitution,
            unboundTypes,
            unboundTypeVariables,
            variance: variance);
        if (substitutedArgument != type.arguments![i]) {
          arguments ??= type.arguments!.toList();
          arguments[i] = substitutedArgument;
        }
      }
    } else if (declaration is TypeAliasBuilder) {
      for (int i = 0; i < type.arguments!.length; ++i) {
        TypeVariableBuilder variable = declaration.typeVariables![i];
        TypeBuilder substitutedArgument = substituteRange(
            type.arguments![i],
            upperSubstitution,
            lowerSubstitution,
            unboundTypes,
            unboundTypeVariables,
            variance: Variance.combine(variance, variable.variance));
        if (substitutedArgument != type.arguments![i]) {
          arguments ??= type.arguments!.toList();
          arguments[i] = substitutedArgument;
        }
      }
    } else if (declaration is InvalidTypeDeclarationBuilder) {
      // Don't substitute.
    } else {
      assert(false, "Unexpected named type builder declaration: $declaration.");
    }
    if (arguments != null) {
      NamedTypeBuilder newTypeBuilder = type.withArguments(arguments);
      if (declaration == null) {
        unboundTypes.add(newTypeBuilder);
      }
      return newTypeBuilder;
    }
    return type;
  } else if (type is FunctionTypeBuilder) {
    List<TypeVariableBuilder>? variables;
    if (type.typeVariables != null) {
      variables = new List<TypeVariableBuilder>.filled(
          type.typeVariables!.length, dummyTypeVariableBuilder);
    }
    List<ParameterBuilder>? formals;
    if (type.formals != null) {
      formals = new List<ParameterBuilder>.filled(
          type.formals!.length, dummyFormalParameterBuilder);
    }
    TypeBuilder? returnType;
    bool changed = false;

    Map<TypeVariableBuilder, TypeBuilder>? functionTypeUpperSubstitution;
    Map<TypeVariableBuilder, TypeBuilder>? functionTypeLowerSubstitution;
    if (type.typeVariables != null) {
      for (int i = 0; i < variables!.length; i++) {
        TypeVariableBuilder variable = type.typeVariables![i];
        TypeBuilder? bound;
        if (variable.bound != null) {
          bound = substituteRange(variable.bound!, upperSubstitution,
              lowerSubstitution, unboundTypes, unboundTypeVariables,
              variance: Variance.invariant);
        }
        if (bound != variable.bound) {
          TypeVariableBuilder newTypeVariableBuilder = variables[i] =
              new TypeVariableBuilder(variable.name, variable.parent,
                  variable.charOffset, variable.fileUri,
                  bound: bound, kind: TypeVariableKind.function);
          unboundTypeVariables.add(newTypeVariableBuilder);
          if (functionTypeUpperSubstitution == null) {
            functionTypeUpperSubstitution = {}..addAll(upperSubstitution);
            functionTypeLowerSubstitution = {}..addAll(lowerSubstitution);
          }
          functionTypeUpperSubstitution[variable] =
              functionTypeLowerSubstitution![variable] =
                  new NamedTypeBuilder.fromTypeDeclarationBuilder(
                      newTypeVariableBuilder,
                      const NullabilityBuilder.omitted(),
                      instanceTypeVariableAccess:
                          InstanceTypeVariableAccessState.Unexpected);
          changed = true;
        } else {
          variables[i] = variable;
        }
      }
    }
    if (type.formals != null) {
      for (int i = 0; i < formals!.length; i++) {
        ParameterBuilder formal = type.formals![i];
        TypeBuilder parameterType = substituteRange(
            formal.type,
            functionTypeUpperSubstitution ?? upperSubstitution,
            functionTypeLowerSubstitution ?? lowerSubstitution,
            unboundTypes,
            unboundTypeVariables,
            variance: Variance.combine(variance, Variance.contravariant));
        if (parameterType != formal.type) {
          formals[i] = new FunctionTypeParameterBuilder(
              formal.metadata, formal.kind, parameterType, formal.name);
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
  } else if (type is RecordTypeBuilder) {
    bool changed = false;

    List<RecordTypeFieldBuilder>? positional = type.positionalFields != null
        ? new List<RecordTypeFieldBuilder>.of(type.positionalFields!)
        : null;
    List<RecordTypeFieldBuilder>? named = type.namedFields != null
        ? new List<RecordTypeFieldBuilder>.of(type.namedFields!)
        : null;
    if (positional != null) {
      for (int i = 0; i < positional.length; i++) {
        RecordTypeFieldBuilder positionalFieldBuilder = positional[i];
        TypeBuilder positionalFieldType = substituteRange(
            positionalFieldBuilder.type,
            upperSubstitution,
            lowerSubstitution,
            unboundTypes,
            unboundTypeVariables,
            variance: variance);
        if (positionalFieldType != positionalFieldBuilder.type) {
          positional[i] = new RecordTypeFieldBuilder(
              positionalFieldBuilder.metadata,
              positionalFieldType,
              positionalFieldBuilder.name,
              positionalFieldBuilder.charOffset);
          changed = true;
        }
      }
    }
    if (named != null) {
      for (int i = 0; i < named.length; i++) {
        RecordTypeFieldBuilder namedFieldBuilder = named[i];
        TypeBuilder namedFieldType = substituteRange(
            namedFieldBuilder.type,
            upperSubstitution,
            lowerSubstitution,
            unboundTypes,
            unboundTypeVariables,
            variance: variance);
        if (namedFieldType != namedFieldBuilder.type) {
          named[i] = new RecordTypeFieldBuilder(
              namedFieldBuilder.metadata,
              namedFieldType,
              namedFieldBuilder.name,
              namedFieldBuilder.charOffset);
          changed = true;
        }
      }
    }

    if (changed) {
      return new RecordTypeBuilder(positional, named, type.nullabilityBuilder,
          type.fileUri, type.charOffset);
    }
    return type;
  }
  return type;
}

TypeBuilder substitute(
    TypeBuilder type, Map<TypeVariableBuilder, TypeBuilder> substitution,
    {required List<TypeBuilder> unboundTypes,
    required List<TypeVariableBuilder> unboundTypeVariables}) {
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
    TypeBuilder dynamicType, TypeBuilder bottomType,
    {required List<TypeBuilder> unboundTypes,
    required List<TypeVariableBuilder> unboundTypeVariables}) {
  List<TypeBuilder> bounds = new List<TypeBuilder>.generate(
      variables.length, (int i) => variables[i].bound ?? dynamicType,
      growable: false);

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
      bounds[variableIndex] = substituteRange(
          bounds[variableIndex],
          dynamicSubstitution,
          nullSubstitution,
          unboundTypes,
          unboundTypeVariables,
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
      bounds[j] = substituteRange(bounds[j], substitution, nullSubstitution,
          unboundTypes, unboundTypeVariables,
          variance: variable.variance);
    }
  }

  return bounds;
}

/// Graph of mutual dependencies of type variables from the same declaration.
/// Type variables are represented by their indices in the corresponding
/// declaration.
class TypeVariablesGraph implements Graph<int> {
  @override
  late List<int> vertices;
  List<TypeVariableBuilder> variables;
  List<TypeBuilder> bounds;

  // `edges[i]` is the list of indices of type variables that reference the type
  // variable with the index `i` in their bounds.
  late List<List<int>> edges;

  TypeVariablesGraph(this.variables, this.bounds) {
    assert(variables.length == bounds.length);

    vertices =
        new List<int>.generate(variables.length, (int i) => i, growable: false);
    Map<TypeVariableBuilder, int> variableIndices =
        <TypeVariableBuilder, int>{};
    edges = new List<List<int>>.generate(variables.length, (int i) {
      variableIndices[variables[i]] = i;
      return <int>[];
    }, growable: false);

    void collectReferencesFrom(int index, TypeBuilder? type) {
      if (type is NamedTypeBuilder) {
        if (type.declaration is TypeVariableBuilder &&
            this.variables.contains(type.declaration)) {
          edges[variableIndices[type.declaration]!].add(index);
        }
        if (type.arguments != null) {
          for (TypeBuilder argument in type.arguments!) {
            collectReferencesFrom(index, argument);
          }
        }
      } else if (type is FunctionTypeBuilder) {
        if (type.typeVariables != null) {
          for (TypeVariableBuilder typeVariable in type.typeVariables!) {
            collectReferencesFrom(index, typeVariable.bound);
          }
        }
        if (type.formals != null) {
          for (ParameterBuilder parameter in type.formals!) {
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
  @override
  Iterable<int> neighborsOf(int index) {
    return edges[index];
  }
}

/// Finds all type builders for [variable] in [type].
///
/// Returns list of the found type builders.
List<NamedTypeBuilder> findVariableUsesInType(
  TypeVariableBuilder variable,
  TypeBuilder? type,
) {
  List<NamedTypeBuilder> uses = <NamedTypeBuilder>[];
  if (type is NamedTypeBuilder) {
    if (type.declaration == variable) {
      uses.add(type);
    } else {
      if (type.arguments != null) {
        for (TypeBuilder argument in type.arguments!) {
          uses.addAll(findVariableUsesInType(variable, argument));
        }
      }
    }
  } else if (type is FunctionTypeBuilder) {
    uses.addAll(findVariableUsesInType(variable, type.returnType));
    if (type.typeVariables != null) {
      for (TypeVariableBuilder dependentVariable in type.typeVariables!) {
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
      for (ParameterBuilder formal in type.formals!) {
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
List<Object> findRawTypesWithInboundReferences(TypeBuilder? type) {
  List<Object> typesAndDependencies = <Object>[];
  if (type is NamedTypeBuilder) {
    if (type.arguments == null) {
      TypeDeclarationBuilder? declaration = type.declaration;
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
            findInboundReferences(declaration.typeVariables!);
        if (dependencies.length != 0) {
          typesAndDependencies.add(type);
          typesAndDependencies.add(dependencies);
        }
      } else if (declaration is ExtensionTypeDeclarationBuilder &&
          declaration.typeParameters != null) {
        List<Object> dependencies =
            findInboundReferences(declaration.typeParameters!);
        if (dependencies.length != 0) {
          typesAndDependencies.add(type);
          typesAndDependencies.add(dependencies);
        }
      } else if (declaration is TypeAliasBuilder) {
        if (declaration.typeVariables != null) {
          List<Object> dependencies =
              findInboundReferences(declaration.typeVariables!);
          if (dependencies.length != 0) {
            typesAndDependencies.add(type);
            typesAndDependencies.add(dependencies);
          }
        }
        if (declaration.type is FunctionTypeBuilder) {
          FunctionTypeBuilder type = declaration.type as FunctionTypeBuilder;
          if (type.typeVariables != null) {
            List<Object> dependencies =
                findInboundReferences(type.typeVariables!);
            if (dependencies.length != 0) {
              typesAndDependencies.add(type);
              typesAndDependencies.add(dependencies);
            }
          }
        }
      }
    } else {
      for (TypeBuilder argument in type.arguments!) {
        typesAndDependencies
            .addAll(findRawTypesWithInboundReferences(argument));
      }
    }
  } else if (type is FunctionTypeBuilder) {
    typesAndDependencies
        .addAll(findRawTypesWithInboundReferences(type.returnType));
    if (type.typeVariables != null) {
      for (TypeVariableBuilder variable in type.typeVariables!) {
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
      for (ParameterBuilder formal in type.formals!) {
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
List<NonSimplicityIssue> getInboundReferenceIssues(
    List<TypeVariableBuilder>? variables) {
  if (variables == null) return <NonSimplicityIssue>[];

  List<NonSimplicityIssue> issues = <NonSimplicityIssue>[];
  for (TypeVariableBuilder variable in variables) {
    if (variable.bound != null) {
      List<Object> rawTypesAndMutualDependencies =
          findRawTypesWithInboundReferences(variable.bound);
      for (int i = 0; i < rawTypesAndMutualDependencies.length; i += 2) {
        NamedTypeBuilder type =
            rawTypesAndMutualDependencies[i] as NamedTypeBuilder;
        List<Object> variablesAndDependencies =
            rawTypesAndMutualDependencies[i + 1] as List<Object>;
        for (int j = 0; j < variablesAndDependencies.length; j += 2) {
          TypeVariableBuilder dependent =
              variablesAndDependencies[j] as TypeVariableBuilder;
          List<NamedTypeBuilder> dependencies =
              variablesAndDependencies[j + 1] as List<NamedTypeBuilder>;
          for (NamedTypeBuilder dependency in dependencies) {
            issues.add(new NonSimplicityIssue(
                variable,
                templateBoundIssueViaRawTypeWithNonSimpleBounds
                    .withArguments(type.declaration!.name),
                <LocatedMessage>[
                  templateNonSimpleBoundViaVariable
                      .withArguments(dependency.declaration!.name)
                      .withLocation(dependent.fileUri!, dependent.charOffset,
                          dependent.name.length)
                ]));
          }
        }
        if (variablesAndDependencies.length == 0) {
          // The inbound references are in a compiled declaration in a .dill.
          issues.add(new NonSimplicityIssue(
              variable,
              templateBoundIssueViaRawTypeWithNonSimpleBounds
                  .withArguments(type.declaration!.name),
              const <LocatedMessage>[]));
        }
      }
    }
  }
  return issues;
}

/// Finds raw non-simple types in bounds of type variables in [typeBuilder].
///
/// Returns flattened list of triplets.  The first element of the triplet is the
/// [TypeDeclarationBuilder] for the type variable from [variables] that has raw
/// generic types with inbound references in its bound.  The second element of
/// the triplet is the error message.  The third element is the context.
List<NonSimplicityIssue> getInboundReferenceIssuesInType(
    TypeBuilder? typeBuilder) {
  List<FunctionTypeBuilder> genericFunctionTypeBuilders =
      <FunctionTypeBuilder>[];
  findUnaliasedGenericFunctionTypes(typeBuilder,
      result: genericFunctionTypeBuilders);
  List<NonSimplicityIssue> issues = <NonSimplicityIssue>[];
  for (FunctionTypeBuilder genericFunctionTypeBuilder
      in genericFunctionTypeBuilders) {
    List<TypeVariableBuilder> typeVariables =
        genericFunctionTypeBuilder.typeVariables!;
    issues.addAll(getInboundReferenceIssues(typeVariables));
  }
  return issues;
}

/// Finds raw type paths starting from those in [start] and ending with [end].
///
/// Returns list of found paths consisting of [RawTypeCycleElement]s. The list
/// ends with the type builder for [end].
///
/// The reason for putting the type variables into the paths as well as for
/// using type for [start], and not the corresponding type declaration,
/// is better error reporting.
List<List<RawTypeCycleElement>> findRawTypePathsToDeclaration(
    TypeBuilder? start, TypeDeclarationBuilder end,
    [Set<TypeDeclarationBuilder>? visited]) {
  visited ??= new Set<TypeDeclarationBuilder>.identity();
  List<List<RawTypeCycleElement>> paths = <List<RawTypeCycleElement>>[];

  if (start is NamedTypeBuilder) {
    void visitTypeVariables(List<TypeVariableBuilder>? typeVariables) {
      if (typeVariables == null) return;

      for (TypeVariableBuilder variable in typeVariables) {
        if (variable.bound != null) {
          for (List<RawTypeCycleElement> path
              in findRawTypePathsToDeclaration(variable.bound, end, visited)) {
            if (path.isNotEmpty) {
              paths.add(<RawTypeCycleElement>[
                new RawTypeCycleElement(start, null)
              ]..addAll(path..first.typeVariable = variable));
            }
          }
        }
      }
    }

    if (start.arguments == null) {
      TypeDeclarationBuilder? declaration = start.declaration;
      if (declaration == end) {
        paths.add(<RawTypeCycleElement>[new RawTypeCycleElement(start, null)]);
      } else if (visited.add(start.declaration!)) {
        if (declaration is ClassBuilder) {
          visitTypeVariables(declaration.typeVariables);
        } else if (declaration is TypeAliasBuilder) {
          visitTypeVariables(declaration.typeVariables);
          if (declaration.type is FunctionTypeBuilder) {
            FunctionTypeBuilder type = declaration.type as FunctionTypeBuilder;
            visitTypeVariables(type.typeVariables);
          }
        } else if (declaration is ExtensionBuilder) {
          visitTypeVariables(declaration.typeParameters);
        } else if (declaration is ExtensionTypeDeclarationBuilder) {
          visitTypeVariables(declaration.typeParameters);
        } else if (declaration is TypeVariableBuilder) {
          // Do nothing. The type variable is handled by its parent declaration.
        } else if (declaration is BuiltinTypeDeclarationBuilder) {
          // Do nothing.
        } else if (declaration is InvalidTypeDeclarationBuilder) {
          // Do nothing.
        } else {
          unhandled(
              '$declaration (${declaration.runtimeType})',
              'findRawTypePathsToDeclaration',
              declaration?.charOffset ?? -1,
              declaration?.fileUri);
        }
        visited.remove(declaration);
      }
    } else {
      for (TypeBuilder argument in start.arguments!) {
        paths.addAll(findRawTypePathsToDeclaration(argument, end, visited));
      }
    }
  } else if (start is FunctionTypeBuilder) {
    paths.addAll(findRawTypePathsToDeclaration(start.returnType, end, visited));
    if (start.typeVariables != null) {
      for (TypeVariableBuilder variable in start.typeVariables!) {
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
      for (ParameterBuilder formal in start.formals!) {
        paths.addAll(findRawTypePathsToDeclaration(formal.type, end, visited));
      }
    }
  }
  return paths;
}

List<List<RawTypeCycleElement>> _findRawTypeCyclesFromTypeVariables(
    TypeDeclarationBuilder declaration,
    List<TypeVariableBuilder>? typeVariables) {
  if (typeVariables == null) {
    return const [];
  }

  List<List<RawTypeCycleElement>> cycles = <List<RawTypeCycleElement>>[];
  for (TypeVariableBuilder variable in typeVariables) {
    if (variable.bound != null) {
      for (List<RawTypeCycleElement> dependencyPath
          in findRawTypePathsToDeclaration(variable.bound, declaration)) {
        if (dependencyPath.isNotEmpty) {
          dependencyPath.first.typeVariable = variable;
          cycles.add(dependencyPath);
        }
      }
    }
  }
  return cycles;
}

/// Finds raw generic type cycles ending and starting with [declaration].
///
/// Returns list of found cycles consisting of [RawTypeCycleElement]s. The
/// cycle starts with a type variable from [declaration] and ends with a type
/// that has [declaration] as its declaration.
///
/// The reason for putting the type variables into the cycles is better error
/// reporting.
List<List<RawTypeCycleElement>> findRawTypeCycles(
    TypeDeclarationBuilder declaration) {
  if (declaration is SourceClassBuilder) {
    return _findRawTypeCyclesFromTypeVariables(
        declaration, declaration.typeVariables);
  } else if (declaration is SourceTypeAliasBuilder) {
    List<List<RawTypeCycleElement>> cycles = <List<RawTypeCycleElement>>[];
    cycles.addAll(_findRawTypeCyclesFromTypeVariables(
        declaration, declaration.typeVariables));
    if (declaration.type is FunctionTypeBuilder) {
      FunctionTypeBuilder type = declaration.type as FunctionTypeBuilder;
      cycles.addAll(
          _findRawTypeCyclesFromTypeVariables(declaration, type.typeVariables));
      return cycles;
    }
  } else if (declaration is SourceExtensionBuilder) {
    return _findRawTypeCyclesFromTypeVariables(
        declaration, declaration.typeParameters);
  } else if (declaration is SourceExtensionTypeDeclarationBuilder) {
    return _findRawTypeCyclesFromTypeVariables(
        declaration, declaration.typeParameters);
  } else {
    unhandled('$declaration (${declaration.runtimeType})', 'findRawTypeCycles',
        declaration.charOffset, declaration.fileUri);
  }
  return const [];
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
List<NonSimplicityIssue> convertRawTypeCyclesIntoIssues(
    TypeDeclarationBuilder declaration,
    List<List<RawTypeCycleElement>> cycles) {
  List<NonSimplicityIssue> issues = <NonSimplicityIssue>[];
  for (List<RawTypeCycleElement> cycle in cycles) {
    if (cycle.length == 1) {
      // Loop.
      issues.add(new NonSimplicityIssue(
          cycle.single.typeVariable!,
          templateBoundIssueViaLoopNonSimplicity
              .withArguments(cycle.single.type.declaration!.name),
          null));
    } else if (cycle.isNotEmpty) {
      assert(cycle.length > 1);
      List<LocatedMessage> context = <LocatedMessage>[];
      for (RawTypeCycleElement cycleElement in cycle) {
        context.add(templateNonSimpleBoundViaReference
            .withArguments(cycleElement.type.declaration!.name)
            .withLocation(
                cycleElement.typeVariable!.fileUri!,
                cycleElement.typeVariable!.charOffset,
                cycleElement.typeVariable!.name.length));
      }

      issues.add(new NonSimplicityIssue(
          declaration,
          templateBoundIssueViaCycleNonSimplicity.withArguments(
              declaration.name, cycle.first.type.declaration!.name),
          context));
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
List<NonSimplicityIssue> getNonSimplicityIssuesForTypeVariables(
    List<TypeVariableBuilder>? variables) {
  if (variables == null) return <NonSimplicityIssue>[];
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
List<NonSimplicityIssue> getNonSimplicityIssuesForDeclaration(
    TypeDeclarationBuilder declaration,
    {bool performErrorRecovery = true}) {
  List<NonSimplicityIssue> issues = <NonSimplicityIssue>[];
  if (declaration is SourceClassBuilder) {
    issues.addAll(getInboundReferenceIssues(declaration.typeVariables));
  } else if (declaration is SourceTypeAliasBuilder) {
    issues.addAll(getInboundReferenceIssues(declaration.typeVariables));
  } else if (declaration is SourceExtensionBuilder) {
    issues.addAll(getInboundReferenceIssues(declaration.typeParameters));
  } else if (declaration is SourceExtensionTypeDeclarationBuilder) {
    issues.addAll(getInboundReferenceIssues(declaration.typeParameters));
  } else {
    unhandled(
        '$declaration (${declaration.runtimeType})',
        'getNonSimplicityIssuesForDeclaration',
        declaration.charOffset,
        declaration.fileUri);
  }
  List<List<RawTypeCycleElement>> cyclesToReport =
      <List<RawTypeCycleElement>>[];
  for (List<RawTypeCycleElement> cycle in findRawTypeCycles(declaration)) {
    // To avoid reporting the same error for each element of the cycle, we only
    // do so if it comes the first in the lexicographical order.  Note that
    // one-element cycles shouldn't be checked, as they are loops.
    if (cycle.length == 1) {
      cyclesToReport.add(cycle);
    } else {
      String declarationPathAndName =
          "${declaration.fileUri}:${declaration.name}";
      String? lexMinPathAndName = null;
      for (RawTypeCycleElement cycleElement in cycle) {
        String pathAndName = "${cycleElement.type.declaration!.fileUri}:"
            "${cycleElement.type.declaration!.name}";
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
  List<NonSimplicityIssue> rawTypeCyclesAsIssues =
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
void breakCycles(List<List<RawTypeCycleElement>> cycles) {
  for (List<RawTypeCycleElement> cycle in cycles) {
    if (cycle.isNotEmpty) {
      cycle.first.typeVariable!.bound = null;
    }
  }
}

/// Finds generic function type sub-terms in [type].
void findUnaliasedGenericFunctionTypes(TypeBuilder? type,
    {required List<FunctionTypeBuilder> result}) {
  if (type is FunctionTypeBuilder) {
    if (type.typeVariables != null && type.typeVariables!.length > 0) {
      result.add(type);

      for (TypeVariableBuilder typeVariable in type.typeVariables!) {
        findUnaliasedGenericFunctionTypes(typeVariable.bound, result: result);
        findUnaliasedGenericFunctionTypes(typeVariable.defaultType,
            result: result);
      }
    }
    findUnaliasedGenericFunctionTypes(type.returnType, result: result);
    if (type.formals != null) {
      for (ParameterBuilder formal in type.formals!) {
        findUnaliasedGenericFunctionTypes(formal.type, result: result);
      }
    }
  } else if (type is NamedTypeBuilder) {
    if (type.arguments != null) {
      for (TypeBuilder argument in type.arguments!) {
        findUnaliasedGenericFunctionTypes(argument, result: result);
      }
    }
  }
}

/// Finds generic function type sub-terms in [type] including the aliased ones.
void findGenericFunctionTypes(TypeBuilder? type,
    {required List<TypeBuilder> result}) {
  if (type is FunctionTypeBuilder) {
    if (type.typeVariables != null && type.typeVariables!.length > 0) {
      result.add(type);

      for (TypeVariableBuilder typeVariable in type.typeVariables!) {
        findGenericFunctionTypes(typeVariable.bound, result: result);
        findGenericFunctionTypes(typeVariable.defaultType, result: result);
      }
    }
    findGenericFunctionTypes(type.returnType, result: result);
    if (type.formals != null) {
      for (ParameterBuilder formal in type.formals!) {
        findGenericFunctionTypes(formal.type, result: result);
      }
    }
  } else if (type is NamedTypeBuilder) {
    if (type.arguments != null) {
      for (TypeBuilder argument in type.arguments!) {
        findGenericFunctionTypes(argument, result: result);
      }
    }

    TypeDeclarationBuilder? declaration = type.declaration;
    // TODO(cstefantsova): Unalias beyond the first layer for the check.
    if (declaration is TypeAliasBuilder) {
      TypeBuilder? rhsType = declaration.type;
      if (rhsType is FunctionTypeBuilder &&
          rhsType.typeVariables != null &&
          rhsType.typeVariables!.isNotEmpty) {
        result.add(type);
      }
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

  @override
  bool defaultDartType(DartType node) => throw "unsupported";

  bool anyTypeVariables(List<DartType> types) {
    for (DartType type in types) {
      if (type.accept(this)) return true;
    }
    return false;
  }

  @override
  bool visitInvalidType(InvalidType node) => false;

  @override
  bool visitDynamicType(DynamicType node) => false;

  @override
  bool visitVoidType(VoidType node) => false;

  @override
  bool visitNeverType(NeverType node) => false;

  @override
  bool visitNullType(NullType node) => false;

  @override
  bool visitInterfaceType(InterfaceType node) {
    return anyTypeVariables(node.typeArguments);
  }

  @override
  bool visitExtensionType(ExtensionType node) {
    return anyTypeVariables(node.typeArguments);
  }

  @override
  bool visitFutureOrType(FutureOrType node) {
    return node.typeArgument.accept(this);
  }

  @override
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

  @override
  bool visitTypeParameterType(TypeParameterType node) => true;

  @override
  bool visitIntersectionType(IntersectionType node) {
    // The left-hand side of an [IntersectionType] is always a
    // [TypeParameterType].
    // ignore: unnecessary_type_check
    assert(node.left is TypeParameterType);
    return true;
  }

  @override
  bool visitTypedefType(TypedefType node) {
    return anyTypeVariables(node.typeArguments);
  }

  @override
  bool visitRecordType(RecordType node) {
    if (anyTypeVariables(node.positional)) return true;
    for (NamedType namedType in node.named) {
      if (namedType.type.accept(this)) return true;
    }
    return false;
  }
}

/// A representation of a found non-simplicity issue in bounds
///
/// The following are the examples of generic declarations with non-simple
/// bounds:
///
///   // `A` has a non-simple bound.
///   class A<X extends A<X>> {}
///
///   // Error: A type with non-simple bounds is used raw in another bound.
///   class B<Y extends A> {}
///
///   // Error: Checking if a type has non-simple bounds leads back to the type,
///   // so the process is infinite. In that case, the type is deemed as having
///   // non-simple bounds.
///   class C<U extends D> {} // `C` has a non-simple bound.
///   class D<V extends C> {} // `D` has a non-simple bound.
///
/// See section 15.3.1 Auxiliary Concepts for Instantiation to Bound.
class NonSimplicityIssue {
  /// The generic declaration that has a non-simplicity issue.
  final TypeDeclarationBuilder declaration;

  /// The non-simplicity error message.
  final Message message;

  /// The context for the error message, containing the locations of all of the
  /// elements from the cycle.
  final List<LocatedMessage>? context;

  NonSimplicityIssue(this.declaration, this.message, this.context);
}

/// Represents an element of a non-simple raw type cycle
///
/// Such cycles appear when the process of checking if a type has a non-simple
/// bound leads back to that type. The cycle that goes through other types and
/// type variables in-between them is recorded for better error reporting. An
/// example of such cycle is the following:
///
///   // Error: Checking if a type has non-simple bounds leads back to the type,
///   // so the process is infinite. In that case, the type is deemed as having
///   // non-simple bounds.
///   class C<U extends D> {} // `C` has a non-simple bound.
///   class D<V extends C> {} // `D` has a non-simple bound.
///
/// See section 15.3.1 Auxiliary Concepts for Instantiation to Bound.
class RawTypeCycleElement {
  /// The type that is on a non-simple raw type cycle.
  final TypeBuilder type;

  /// The type variable that connects [type] to the next element in the
  /// non-simple raw type cycle.
  TypeVariableBuilder? typeVariable;

  RawTypeCycleElement(this.type, this.typeVariable);
}
