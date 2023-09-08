// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:kernel/ast.dart';

import 'package:kernel/src/find_type_visitor.dart';

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
  switch (type) {
    case NamedTypeBuilder(
        :TypeDeclarationBuilder? declaration,
        :List<TypeBuilder>? arguments
      ):
      assert(declaration != null);
      if (declaration is TypeVariableBuilder) {
        if (declaration == variable) {
          return Variance.covariant;
        } else {
          return Variance.unrelated;
        }
      } else if (declaration is ClassBuilder) {
        int result = Variance.unrelated;
        if (arguments != null) {
          for (int i = 0; i < arguments.length; ++i) {
            result = Variance.meet(
                result,
                Variance.combine(
                    declaration.cls.typeParameters[i].variance,
                    computeTypeVariableBuilderVariance(
                        variable, arguments[i], libraryBuilder)));
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
      return Variance.unrelated;
    case FunctionTypeBuilder(
        :List<TypeVariableBuilder>? typeVariables,
        :List<ParameterBuilder>? formals,
        :TypeBuilder returnType
      ):
      int result = Variance.unrelated;
      if (returnType is! OmittedTypeBuilder) {
        result = Variance.meet(
            result,
            computeTypeVariableBuilderVariance(
                variable, returnType, libraryBuilder));
      }
      if (typeVariables != null) {
        for (TypeVariableBuilder typeVariable in typeVariables) {
          // If [variable] is referenced in the bound at all, it makes the
          // variance of [variable] in the entire type invariant.  The
          // invocation of [computeVariance] below is made to simply figure out
          // if [variable] occurs in the bound.
          if (typeVariable.bound != null &&
              computeTypeVariableBuilderVariance(
                      variable, typeVariable.bound!, libraryBuilder) !=
                  Variance.unrelated) {
            result = Variance.invariant;
          }
        }
      }
      if (formals != null) {
        for (ParameterBuilder formal in formals) {
          result = Variance.meet(
              result,
              Variance.combine(
                  Variance.contravariant,
                  computeTypeVariableBuilderVariance(
                      variable, formal.type, libraryBuilder)));
        }
      }
      return result;
    case RecordTypeBuilder(
        :List<RecordTypeFieldBuilder>? positionalFields,
        :List<RecordTypeFieldBuilder>? namedFields
      ):
      int result = Variance.unrelated;
      if (positionalFields != null) {
        for (RecordTypeFieldBuilder field in positionalFields) {
          result = Variance.meet(
              result,
              computeTypeVariableBuilderVariance(
                  variable, field.type, libraryBuilder));
        }
      }
      if (namedFields != null) {
        for (RecordTypeFieldBuilder field in namedFields) {
          result = Variance.meet(
              result,
              computeTypeVariableBuilderVariance(
                  variable, field.type, libraryBuilder));
        }
      }
      return result;
    case FixedTypeBuilder():
    case InvalidTypeBuilder():
    case OmittedTypeBuilder():
    case null:
      return Variance.unrelated;
  }
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
  switch (type) {
    case NamedTypeBuilder():
      return _substituteNamedTypeBuilder(type, upperSubstitution,
          lowerSubstitution, unboundTypes, unboundTypeVariables,
          variance: variance);

    case FunctionTypeBuilder():
      return _substituteFunctionTypeBuilder(type, upperSubstitution,
          lowerSubstitution, unboundTypes, unboundTypeVariables,
          variance: variance);

    case RecordTypeBuilder():
      return _substituteRecordTypeBuilder(type, upperSubstitution,
          lowerSubstitution, unboundTypes, unboundTypeVariables,
          variance: variance);

    case OmittedTypeBuilder():
    case FixedTypeBuilder():
    case InvalidTypeBuilder():
      return type;
  }
}

TypeBuilder _substituteNamedTypeBuilder(
    NamedTypeBuilder type,
    Map<TypeVariableBuilder, TypeBuilder> upperSubstitution,
    Map<TypeVariableBuilder, TypeBuilder> lowerSubstitution,
    List<TypeBuilder> unboundTypes,
    List<TypeVariableBuilder> unboundTypeVariables,
    {final int variance = Variance.covariant}) {
  TypeDeclarationBuilder? declaration = type.declaration;
  List<TypeBuilder>? arguments = type.arguments;

  if (declaration is TypeVariableBuilder) {
    if (variance == Variance.contravariant) {
      TypeBuilder? replacement = lowerSubstitution[declaration];
      if (replacement != null) {
        return replacement.withNullabilityBuilder(
            combineNullabilityBuildersForSubstitution(
                replacement.nullabilityBuilder, type.nullabilityBuilder));
      }
      return type;
    }
    TypeBuilder? replacement = upperSubstitution[declaration];
    if (replacement != null) {
      return replacement.withNullabilityBuilder(
          combineNullabilityBuildersForSubstitution(
              replacement.nullabilityBuilder, type.nullabilityBuilder));
    }
    return type;
  }
  if (arguments == null || arguments.length == 0) {
    return type;
  }
  List<TypeBuilder>? newArguments;
  if (declaration == null) {
    assert(
        identical(upperSubstitution, lowerSubstitution),
        "Can only handle unbound named type builders identical "
        "`upperSubstitution` and `lowerSubstitution`.");
    for (int i = 0; i < arguments.length; ++i) {
      TypeBuilder substitutedArgument = substituteRange(
          arguments[i],
          upperSubstitution,
          lowerSubstitution,
          unboundTypes,
          unboundTypeVariables,
          variance: variance);
      if (substitutedArgument != arguments[i]) {
        newArguments ??= arguments.toList();
        newArguments[i] = substitutedArgument;
      }
    }
  } else if (declaration is ClassBuilder) {
    for (int i = 0; i < arguments.length; ++i) {
      TypeBuilder substitutedArgument = substituteRange(
          arguments[i],
          upperSubstitution,
          lowerSubstitution,
          unboundTypes,
          unboundTypeVariables,
          variance: variance);
      if (substitutedArgument != arguments[i]) {
        newArguments ??= arguments.toList();
        newArguments[i] = substitutedArgument;
      }
    }
  } else if (declaration is ExtensionTypeDeclarationBuilder) {
    for (int i = 0; i < arguments.length; ++i) {
      TypeBuilder substitutedArgument = substituteRange(
          arguments[i],
          upperSubstitution,
          lowerSubstitution,
          unboundTypes,
          unboundTypeVariables,
          variance: variance);
      if (substitutedArgument != arguments[i]) {
        newArguments ??= arguments.toList();
        newArguments[i] = substitutedArgument;
      }
    }
  } else if (declaration is TypeAliasBuilder) {
    for (int i = 0; i < arguments.length; ++i) {
      TypeVariableBuilder variable = declaration.typeVariables![i];
      TypeBuilder substitutedArgument = substituteRange(
          arguments[i],
          upperSubstitution,
          lowerSubstitution,
          unboundTypes,
          unboundTypeVariables,
          variance: Variance.combine(variance, variable.variance));
      if (substitutedArgument != arguments[i]) {
        newArguments ??= arguments.toList();
        newArguments[i] = substitutedArgument;
      }
    }
  } else if (declaration is InvalidTypeDeclarationBuilder) {
    // Don't substitute.
  } else {
    assert(false, "Unexpected named type builder declaration: $declaration.");
  }
  if (newArguments != null) {
    NamedTypeBuilder newTypeBuilder = type.withArguments(newArguments);
    if (declaration == null) {
      unboundTypes.add(newTypeBuilder);
    }
    return newTypeBuilder;
  }
  return type;
}

TypeBuilder _substituteFunctionTypeBuilder(
    FunctionTypeBuilder type,
    Map<TypeVariableBuilder, TypeBuilder> upperSubstitution,
    Map<TypeVariableBuilder, TypeBuilder> lowerSubstitution,
    List<TypeBuilder> unboundTypes,
    List<TypeVariableBuilder> unboundTypeVariables,
    {final int variance = Variance.covariant}) {
  List<TypeVariableBuilder>? typeVariables = type.typeVariables;
  List<ParameterBuilder>? formals = type.formals;
  TypeBuilder returnType = type.returnType;

  List<TypeVariableBuilder>? newTypeVariables;
  if (typeVariables != null) {
    newTypeVariables = new List<TypeVariableBuilder>.filled(
        typeVariables.length, dummyTypeVariableBuilder);
  }
  List<ParameterBuilder>? newFormals;
  TypeBuilder newReturnType;
  bool changed = false;

  Map<TypeVariableBuilder, TypeBuilder>? functionTypeUpperSubstitution;
  Map<TypeVariableBuilder, TypeBuilder>? functionTypeLowerSubstitution;
  if (typeVariables != null) {
    for (int i = 0; i < newTypeVariables!.length; i++) {
      TypeVariableBuilder variable = typeVariables[i];
      TypeBuilder? bound;
      if (variable.bound != null) {
        bound = substituteRange(variable.bound!, upperSubstitution,
            lowerSubstitution, unboundTypes, unboundTypeVariables,
            variance: Variance.invariant);
      }
      if (bound != variable.bound) {
        TypeVariableBuilder newTypeVariableBuilder = newTypeVariables[i] =
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
                new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
                    newTypeVariableBuilder, const NullabilityBuilder.omitted(),
                    instanceTypeVariableAccess:
                        InstanceTypeVariableAccessState.Unexpected);
        changed = true;
      } else {
        newTypeVariables[i] = variable;
      }
    }
  }
  if (formals != null) {
    newFormals = new List<ParameterBuilder>.filled(
        formals.length, dummyFormalParameterBuilder);
    for (int i = 0; i < formals.length; i++) {
      ParameterBuilder formal = formals[i];
      TypeBuilder parameterType = substituteRange(
          formal.type,
          functionTypeUpperSubstitution ?? upperSubstitution,
          functionTypeLowerSubstitution ?? lowerSubstitution,
          unboundTypes,
          unboundTypeVariables,
          variance: Variance.combine(variance, Variance.contravariant));
      if (parameterType != formal.type) {
        newFormals[i] = new FunctionTypeParameterBuilder(
            formal.metadata, formal.kind, parameterType, formal.name);
        changed = true;
      } else {
        newFormals[i] = formal;
      }
    }
  }
  newReturnType = substituteRange(
      returnType,
      functionTypeUpperSubstitution ?? upperSubstitution,
      functionTypeLowerSubstitution ?? lowerSubstitution,
      unboundTypes,
      unboundTypeVariables,
      variance: variance);
  changed = changed || newReturnType != returnType;

  if (changed) {
    return new FunctionTypeBuilderImpl(newReturnType, newTypeVariables,
        newFormals, type.nullabilityBuilder, type.fileUri, type.charOffset);
  }
  return type;
}

TypeBuilder _substituteRecordTypeBuilder(
    RecordTypeBuilder type,
    Map<TypeVariableBuilder, TypeBuilder> upperSubstitution,
    Map<TypeVariableBuilder, TypeBuilder> lowerSubstitution,
    List<TypeBuilder> unboundTypes,
    List<TypeVariableBuilder> unboundTypeVariables,
    {final int variance = Variance.covariant}) {
  List<RecordTypeFieldBuilder>? positionalFields = type.positionalFields;
  List<RecordTypeFieldBuilder>? namedFields = type.namedFields;

  bool changed = false;
  List<RecordTypeFieldBuilder>? newPositionalFields = positionalFields != null
      ? new List<RecordTypeFieldBuilder>.of(positionalFields)
      : null;
  List<RecordTypeFieldBuilder>? newNamedFields = namedFields != null
      ? new List<RecordTypeFieldBuilder>.of(namedFields)
      : null;
  if (newPositionalFields != null) {
    for (int i = 0; i < newPositionalFields.length; i++) {
      RecordTypeFieldBuilder positionalFieldBuilder = newPositionalFields[i];
      TypeBuilder positionalFieldType = substituteRange(
          positionalFieldBuilder.type,
          upperSubstitution,
          lowerSubstitution,
          unboundTypes,
          unboundTypeVariables,
          variance: variance);
      if (positionalFieldType != positionalFieldBuilder.type) {
        newPositionalFields[i] = new RecordTypeFieldBuilder(
            positionalFieldBuilder.metadata,
            positionalFieldType,
            positionalFieldBuilder.name,
            positionalFieldBuilder.charOffset);
        changed = true;
      }
    }
  }
  if (newNamedFields != null) {
    for (int i = 0; i < newNamedFields.length; i++) {
      RecordTypeFieldBuilder namedFieldBuilder = newNamedFields[i];
      TypeBuilder namedFieldType = substituteRange(
          namedFieldBuilder.type,
          upperSubstitution,
          lowerSubstitution,
          unboundTypes,
          unboundTypeVariables,
          variance: variance);
      if (namedFieldType != namedFieldBuilder.type) {
        newNamedFields[i] = new RecordTypeFieldBuilder(
            namedFieldBuilder.metadata,
            namedFieldType,
            namedFieldBuilder.name,
            namedFieldBuilder.charOffset);
        changed = true;
      }
    }
  }

  if (changed) {
    return new RecordTypeBuilderImpl(newPositionalFields, newNamedFields,
        type.nullabilityBuilder, type.fileUri, type.charOffset);
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
      switch (type) {
        case NamedTypeBuilder(
            :TypeDeclarationBuilder? declaration,
            :List<TypeBuilder>? arguments
          ):
          if (declaration is TypeVariableBuilder &&
              this.variables.contains(declaration)) {
            edges[variableIndices[declaration]!].add(index);
          }
          if (arguments != null) {
            for (TypeBuilder argument in arguments) {
              collectReferencesFrom(index, argument);
            }
          }
        case FunctionTypeBuilder(
            :List<TypeVariableBuilder>? typeVariables,
            :List<ParameterBuilder>? formals,
            :TypeBuilder returnType
          ):
          if (typeVariables != null) {
            for (TypeVariableBuilder typeVariable in typeVariables) {
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
  switch (type) {
    case NamedTypeBuilder(
        :TypeDeclarationBuilder? declaration,
        :List<TypeBuilder>? arguments
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
        :List<TypeVariableBuilder>? typeVariables,
        :List<ParameterBuilder>? formals,
        :TypeBuilder returnType
      ):
      uses.addAll(findVariableUsesInType(variable, returnType));
      if (typeVariables != null) {
        for (TypeVariableBuilder dependentVariable in typeVariables) {
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
  switch (type) {
    case NamedTypeBuilder(
        :TypeDeclarationBuilder? declaration,
        :List<TypeBuilder>? arguments
      ):
      if (arguments == null) {
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
          List<TypeParameter> typeParameters =
              declaration.typedef.typeParameters;
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
        for (TypeBuilder argument in arguments) {
          typesAndDependencies
              .addAll(findRawTypesWithInboundReferences(argument));
        }
      }
    case FunctionTypeBuilder(
        :List<TypeVariableBuilder>? typeVariables,
        :List<ParameterBuilder>? formals,
        :TypeBuilder returnType
      ):
      typesAndDependencies
          .addAll(findRawTypesWithInboundReferences(returnType));
      if (typeVariables != null) {
        for (TypeVariableBuilder variable in typeVariables) {
          if (variable.bound != null) {
            typesAndDependencies
                .addAll(findRawTypesWithInboundReferences(variable.bound));
          }
          if (variable.defaultType != null) {
            typesAndDependencies.addAll(
                findRawTypesWithInboundReferences(variable.defaultType));
          }
        }
      }
      if (formals != null) {
        for (ParameterBuilder formal in formals) {
          typesAndDependencies
              .addAll(findRawTypesWithInboundReferences(formal.type));
        }
      }
    case RecordTypeBuilder(
        :List<RecordTypeFieldBuilder>? positionalFields,
        :List<RecordTypeFieldBuilder>? namedFields
      ):
      if (positionalFields != null) {
        for (RecordTypeFieldBuilder field in positionalFields) {
          typesAndDependencies
              .addAll(findRawTypesWithInboundReferences(field.type));
        }
      }
      if (namedFields != null) {
        for (RecordTypeFieldBuilder field in namedFields) {
          typesAndDependencies
              .addAll(findRawTypesWithInboundReferences(field.type));
        }
      }
    case FixedTypeBuilder():
    case InvalidTypeBuilder():
    case OmittedTypeBuilder():
    case null:
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

  switch (start) {
    case NamedTypeBuilder(
        :TypeDeclarationBuilder? declaration,
        :List<TypeBuilder>? arguments
      ):
      void visitTypeVariables(List<TypeVariableBuilder>? typeVariables) {
        if (typeVariables == null) return;

        for (TypeVariableBuilder variable in typeVariables) {
          if (variable.bound != null) {
            for (List<RawTypeCycleElement> path
                in findRawTypePathsToDeclaration(
                    variable.bound, end, visited)) {
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
          if (declaration is ClassBuilder) {
            visitTypeVariables(declaration.typeVariables);
          } else if (declaration is TypeAliasBuilder) {
            visitTypeVariables(declaration.typeVariables);
            if (declaration.type is FunctionTypeBuilder) {
              FunctionTypeBuilder type =
                  declaration.type as FunctionTypeBuilder;
              visitTypeVariables(type.typeVariables);
            }
          } else if (declaration is ExtensionBuilder) {
            visitTypeVariables(declaration.typeParameters);
          } else if (declaration is ExtensionTypeDeclarationBuilder) {
            visitTypeVariables(declaration.typeParameters);
          } else if (declaration is TypeVariableBuilder) {
            // Do nothing. The type variable is handled by its parent
            // declaration.
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
        for (TypeBuilder argument in arguments) {
          paths.addAll(findRawTypePathsToDeclaration(argument, end, visited));
        }
      }
    case FunctionTypeBuilder(
        :List<TypeVariableBuilder>? typeVariables,
        :List<ParameterBuilder>? formals,
        :TypeBuilder returnType
      ):
      paths.addAll(findRawTypePathsToDeclaration(returnType, end, visited));
      if (typeVariables != null) {
        for (TypeVariableBuilder variable in typeVariables) {
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
  switch (type) {
    case FunctionTypeBuilder(
        :List<TypeVariableBuilder>? typeVariables,
        :List<ParameterBuilder>? formals,
        :TypeBuilder returnType
      ):
      if (typeVariables != null && typeVariables.length > 0) {
        result.add(type);

        for (TypeVariableBuilder typeVariable in typeVariables) {
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
    case NamedTypeBuilder(:List<TypeBuilder>? arguments):
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
