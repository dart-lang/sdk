// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/src/find_type_visitor.dart';
import 'package:kernel/util/graph.dart' show Graph, computeStrongComponents;

import '../base/problems.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/record_type_builder.dart';
import '../builder/type_builder.dart';
import '../codes/cfe_codes.dart'
    show
        LocatedMessage,
        Message,
        templateBoundIssueViaCycleNonSimplicity,
        templateBoundIssueViaLoopNonSimplicity,
        templateBoundIssueViaRawTypeWithNonSimpleBounds,
        templateNonSimpleBoundViaReference,
        templateNonSimpleBoundViaVariable;
import '../source/source_class_builder.dart';
import '../source/source_extension_builder.dart';
import '../source/source_extension_type_declaration_builder.dart';
import '../source/source_type_alias_builder.dart';

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

/// Calculates bounds to be provided as type arguments in place of missing type
/// arguments on raw types with the given type parameters.
///
/// See the [description]
/// (https://github.com/dart-lang/sdk/blob/master/docs/language/informal/instantiate-to-bound.md)
/// of the algorithm for details.
List<TypeBuilder> calculateBounds(List<TypeVariableBuilder> variables,
    TypeBuilder dynamicType, TypeBuilder bottomType,
    {required List<TypeBuilder> unboundTypes,
    required List<StructuralVariableBuilder> unboundTypeVariables}) {
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
      bounds[variableIndex] = bounds[variableIndex].substituteRange(
              dynamicSubstitution,
              nullSubstitution,
              unboundTypes,
              unboundTypeVariables,
              variance: variable.variance) ??
          bounds[variableIndex];
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
      bounds[j] = bounds[j].substituteRange(substitution, nullSubstitution,
              unboundTypes, unboundTypeVariables,
              variance: variable.variance) ??
          bounds[j];
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

    /*void collectReferencesFrom(int index, TypeBuilder? type) {
      switch (type) {
        case NamedTypeBuilder(
            :TypeDeclarationBuilder? declaration,
            typeArguments: List<TypeBuilder>? arguments
          ):
          if (declaration is NominalVariableBuilder &&
              this.variables.contains(declaration)) {
            edges[variableIndices[declaration]!].add(index);
          }
          if (arguments != null) {
            for (TypeBuilder argument in arguments) {
              collectReferencesFrom(index, argument);
            }
          }
        case FunctionTypeBuilder(
            :List<StructuralVariableBuilder>? typeVariables,
            :List<ParameterBuilder>? formals,
            :TypeBuilder returnType
          ):
          if (typeVariables != null) {
            for (StructuralVariableBuilder typeVariable in typeVariables) {
              collectReferencesFrom(index, typeVariable.bound);
            }
          }
          if (formals != null) {
            for (ParameterBuilder parameter in formals) {
              collectReferencesFrom(index, parameter.type);
            }
          }
          collectReferencesFrom(index, returnType);
        case RecordTypeBuilder(
            :List<RecordTypeFieldBuilder>? positionalFields,
            :List<RecordTypeFieldBuilder>? namedFields
          ):
          if (positionalFields != null) {
            for (RecordTypeFieldBuilder field in positionalFields) {
              collectReferencesFrom(index, field.type);
            }
          }
          if (namedFields != null) {
            for (RecordTypeFieldBuilder field in namedFields) {
              collectReferencesFrom(index, field.type);
            }
          }
        case FixedTypeBuilder():
        case InvalidTypeBuilder():
        case OmittedTypeBuilder():
        case null:
      }
    }*/

    for (int i = 0; i < vertices.length; i++) {
      bounds[i].collectReferencesFrom(variableIndices, edges, i);
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
    TypeVariableBuilder variable, TypeBuilder? type) {
  List<NamedTypeBuilder> uses = <NamedTypeBuilder>[];
  switch (type) {
    case NamedTypeBuilder(
        :TypeDeclarationBuilder? declaration,
        typeArguments: List<TypeBuilder>? arguments
      ):
      if (declaration == variable) {
        uses.add(type);
      } else {
        if (arguments != null) {
          for (TypeBuilder argument in arguments) {
            uses.addAll(findVariableUsesInType(variable, argument));
          }
        }
      }
      break;
    case FunctionTypeBuilder(
        // Coverage-ignore(suite): Not run.
        :List<StructuralVariableBuilder>? typeVariables,
        // Coverage-ignore(suite): Not run.
        :List<ParameterBuilder>? formals,
        // Coverage-ignore(suite): Not run.
        :TypeBuilder returnType
      ):
      // Coverage-ignore(suite): Not run.
      uses.addAll(findVariableUsesInType(variable, returnType));
      if (typeVariables != null) {
        // Coverage-ignore-block(suite): Not run.
        for (StructuralVariableBuilder dependentVariable in typeVariables) {
          if (dependentVariable.bound != null) {
            uses.addAll(
                findVariableUsesInType(variable, dependentVariable.bound));
          }
          if (dependentVariable.defaultType != null) {
            uses.addAll(findVariableUsesInType(
                variable, dependentVariable.defaultType));
          }
        }
      }
      if (formals != null) {
        // Coverage-ignore-block(suite): Not run.
        for (ParameterBuilder formal in formals) {
          uses.addAll(findVariableUsesInType(variable, formal.type));
        }
      }
    case RecordTypeBuilder(
        :List<RecordTypeFieldBuilder>? positionalFields,
        :List<RecordTypeFieldBuilder>? namedFields
      ):
      if (positionalFields != null) {
        for (RecordTypeFieldBuilder field in positionalFields) {
          uses.addAll(findVariableUsesInType(variable, field.type));
        }
      }
      if (namedFields != null) {
        // Coverage-ignore-block(suite): Not run.
        for (RecordTypeFieldBuilder field in namedFields) {
          uses.addAll(findVariableUsesInType(variable, field.type));
        }
      }
    case FixedTypeBuilder():
    case InvalidTypeBuilder():
    case OmittedTypeBuilder():
    case null:
  }
  return uses;
}

class InBoundReferences {
  /// Type variable that references other type variables in its bound.
  final TypeVariableBuilder typeVariableBuilder;

  /// The references to other type variables.
  final List<TypeBuilder> dependencies;

  InBoundReferences(this.typeVariableBuilder, this.dependencies);
}

/// Finds those of [variables] that reference other [variables] in their bounds.
List<InBoundReferences> findInboundReferences(
    List<TypeVariableBuilder> variables) {
  List<InBoundReferences> variablesAndDependencies = [];
  for (TypeVariableBuilder dependent in variables) {
    TypeBuilder? dependentBound = dependent.bound;
    List<NamedTypeBuilder> dependencies = <NamedTypeBuilder>[];
    for (TypeVariableBuilder dependence in variables) {
      List<NamedTypeBuilder> uses =
          findVariableUsesInType(dependence, dependentBound);
      if (uses.length != 0) {
        dependencies.addAll(uses);
      }
    }
    if (dependencies.length != 0) {
      variablesAndDependencies
          .add(new InBoundReferences(dependent, dependencies));
    }
  }
  return variablesAndDependencies;
}

class TypeWithInBoundReferences {
  /// A [typeBuilder] of a raw generic type.
  final TypeBuilder typeBuilder;

  /// Type variables of the declaration of [typeBuilder] that reference these
  /// type variables in their bounds.
  final List<InBoundReferences> inBoundReferences;

  TypeWithInBoundReferences(this.typeBuilder, this.inBoundReferences);
}

/// Finds issues by raw generic types with inbound references in type variables.
List<NonSimplicityIssue> getInboundReferenceIssues(
    List<TypeVariableBuilder>? variables) {
  if (variables == null) return <NonSimplicityIssue>[];

  List<NonSimplicityIssue> issues = <NonSimplicityIssue>[];
  for (TypeVariableBuilder variable in variables) {
    TypeBuilder? variableBound = variable.bound;
    if (variableBound != null) {
      List<TypeWithInBoundReferences> rawTypesAndMutualDependencies =
          variableBound.findRawTypesWithInboundReferences();
      for (int i = 0; i < rawTypesAndMutualDependencies.length; i++) {
        TypeBuilder type = rawTypesAndMutualDependencies[i].typeBuilder;
        List<InBoundReferences> variablesAndDependencies =
            rawTypesAndMutualDependencies[i].inBoundReferences;
        for (int j = 0; j < variablesAndDependencies.length; j++) {
          TypeVariableBuilder dependent =
              variablesAndDependencies[j].typeVariableBuilder;
          List<TypeBuilder> dependencies =
              variablesAndDependencies[j].dependencies;
          for (TypeBuilder dependency in dependencies) {
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
    List<StructuralVariableBuilder> typeVariables =
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

  switch (start) {
    case NamedTypeBuilder(
        :TypeDeclarationBuilder? declaration,
        typeArguments: List<TypeBuilder>? arguments
      ):
      void visitTypeVariables(List<TypeVariableBuilder>? typeVariables) {
        if (typeVariables == null) return;

        for (TypeVariableBuilder variable in typeVariables) {
          TypeBuilder? variableBound = variable.bound;
          if (variableBound != null) {
            for (List<RawTypeCycleElement> path
                in findRawTypePathsToDeclaration(variableBound, end, visited)) {
              if (path.isNotEmpty) {
                paths.add(<RawTypeCycleElement>[
                  new RawTypeCycleElement(start, null)
                ]..addAll(path..first.typeVariable = variable));
              }
            }
          }
        }
      }

      if (arguments == null) {
        if (declaration == end) {
          paths
              .add(<RawTypeCycleElement>[new RawTypeCycleElement(start, null)]);
        } else if (visited.add(start.declaration!)) {
          switch (declaration) {
            case ClassBuilder():
              visitTypeVariables(declaration.typeVariables);
            case TypeAliasBuilder():
              visitTypeVariables(declaration.typeVariables);
              if (declaration.type is FunctionTypeBuilder) {
                FunctionTypeBuilder type =
                    declaration.type as FunctionTypeBuilder;
                visitTypeVariables(type.typeVariables);
              }
            case ExtensionBuilder():
              // Coverage-ignore(suite): Not run.
              visitTypeVariables(declaration.typeParameters);
            case ExtensionTypeDeclarationBuilder():
              visitTypeVariables(declaration.typeParameters);
            case NominalVariableBuilder():
              // Do nothing. The type variable is handled by its parent
              // declaration.
              break;
            case StructuralVariableBuilder():
              // Do nothing.
              break;
            case InvalidTypeDeclarationBuilder():
              // Do nothing.
              break;
            case BuiltinTypeDeclarationBuilder():
              // Do nothing.
              break;
            // Coverage-ignore(suite): Not run.
            // TODO(johnniwinther): How should we handle this case?
            case OmittedTypeDeclarationBuilder():
            case null:
              // Do nothing.
              break;
          }
          visited.remove(declaration);
        }
      } else {
        for (TypeBuilder argument in arguments) {
          paths.addAll(findRawTypePathsToDeclaration(argument, end, visited));
        }
      }
    case FunctionTypeBuilder(
        :List<StructuralVariableBuilder>? typeVariables,
        :List<ParameterBuilder>? formals,
        :TypeBuilder returnType
      ):
      paths.addAll(findRawTypePathsToDeclaration(returnType, end, visited));
      if (typeVariables != null) {
        for (StructuralVariableBuilder variable in typeVariables) {
          if (variable.bound != null) {
            paths.addAll(
                findRawTypePathsToDeclaration(variable.bound, end, visited));
          }
          if (variable.defaultType != null) {
            // Coverage-ignore-block(suite): Not run.
            paths.addAll(findRawTypePathsToDeclaration(
                variable.defaultType, end, visited));
          }
        }
      }
      if (formals != null) {
        for (ParameterBuilder formal in formals) {
          paths
              .addAll(findRawTypePathsToDeclaration(formal.type, end, visited));
        }
      }
    case RecordTypeBuilder(
        :List<RecordTypeFieldBuilder>? positionalFields,
        :List<RecordTypeFieldBuilder>? namedFields
      ):
      if (positionalFields != null) {
        for (RecordTypeFieldBuilder field in positionalFields) {
          paths.addAll(findRawTypePathsToDeclaration(field.type, end, visited));
        }
      }
      if (namedFields != null) {
        for (RecordTypeFieldBuilder field in namedFields) {
          paths.addAll(findRawTypePathsToDeclaration(field.type, end, visited));
        }
      }
    case FixedTypeBuilder():
    case InvalidTypeBuilder():
    case OmittedTypeBuilder():
    case null:
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
    TypeBuilder? variableBound = variable.bound;
    if (variableBound != null) {
      for (List<RawTypeCycleElement> dependencyPath
          in findRawTypePathsToDeclaration(variableBound, declaration)) {
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
          declaration,
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
    List<NominalVariableBuilder>? variables) {
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
      cycle.first.typeVariable?.bound = null;
    }
  }
}

/// Finds generic function type sub-terms in [type].
void findUnaliasedGenericFunctionTypes(TypeBuilder? type,
    {required List<FunctionTypeBuilder> result}) {
  switch (type) {
    case FunctionTypeBuilder(
        :List<StructuralVariableBuilder>? typeVariables,
        :List<ParameterBuilder>? formals,
        :TypeBuilder returnType
      ):
      if (typeVariables != null && typeVariables.length > 0) {
        result.add(type);

        for (StructuralVariableBuilder typeVariable in typeVariables) {
          findUnaliasedGenericFunctionTypes(typeVariable.bound, result: result);
          findUnaliasedGenericFunctionTypes(typeVariable.defaultType,
              result: result);
        }
      }
      findUnaliasedGenericFunctionTypes(returnType, result: result);
      if (formals != null) {
        for (ParameterBuilder formal in formals) {
          findUnaliasedGenericFunctionTypes(formal.type, result: result);
        }
      }
    case NamedTypeBuilder(typeArguments: List<TypeBuilder>? arguments):
      if (arguments != null) {
        for (TypeBuilder argument in arguments) {
          findUnaliasedGenericFunctionTypes(argument, result: result);
        }
      }
    case RecordTypeBuilder(
        :List<RecordTypeFieldBuilder>? positionalFields,
        :List<RecordTypeFieldBuilder>? namedFields
      ):
      if (positionalFields != null) {
        for (RecordTypeFieldBuilder field in positionalFields) {
          findUnaliasedGenericFunctionTypes(field.type, result: result);
        }
      }
      if (namedFields != null) {
        for (RecordTypeFieldBuilder field in namedFields) {
          findUnaliasedGenericFunctionTypes(field.type, result: result);
        }
      }
    case FixedTypeBuilder():
    case InvalidTypeBuilder():
    case OmittedTypeBuilder():
    case null:
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
class TypeVariableSearch extends FindTypeVisitor {
  const TypeVariableSearch();

  @override
  bool visitTypeParameterType(TypeParameterType node) => true;

  @override
  bool visitStructuralParameterType(StructuralParameterType node) {
    return true;
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

  RawTypeCycleElement(this.type, this.typeVariable)
      : assert(typeVariable is NominalVariableBuilder? ||
            // Coverage-ignore(suite): Not run.
            typeVariable is StructuralVariableBuilder?);
}
