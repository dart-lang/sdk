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
List<TypeBuilder> calculateBounds(List<TypeParameterBuilder> parameters,
    TypeBuilder dynamicType, TypeBuilder bottomType,
    {required List<StructuralParameterBuilder> unboundTypeParameters}) {
  List<TypeBuilder> bounds = new List<TypeBuilder>.generate(
      parameters.length, (int i) => parameters[i].bound ?? dynamicType,
      growable: false);

  TypeParametersGraph graph = new TypeParametersGraph(parameters, bounds);
  List<List<int>> stronglyConnected = computeStrongComponents(graph);
  for (List<int> component in stronglyConnected) {
    Map<TypeParameterBuilder, TypeBuilder> dynamicSubstitution =
        <TypeParameterBuilder, TypeBuilder>{};
    Map<TypeParameterBuilder, TypeBuilder> nullSubstitution =
        <TypeParameterBuilder, TypeBuilder>{};
    for (int parameterIndex in component) {
      dynamicSubstitution[parameters[parameterIndex]] = dynamicType;
      nullSubstitution[parameters[parameterIndex]] = bottomType;
    }
    for (int parameterIndex in component) {
      TypeParameterBuilder parameter = parameters[parameterIndex];
      bounds[parameterIndex] = bounds[parameterIndex].substituteRange(
              dynamicSubstitution, nullSubstitution, unboundTypeParameters,
              variance: parameter.variance) ??
          bounds[parameterIndex];
    }
  }

  for (int i = 0; i < parameters.length; i++) {
    Map<TypeParameterBuilder, TypeBuilder> substitution =
        <TypeParameterBuilder, TypeBuilder>{};
    Map<TypeParameterBuilder, TypeBuilder> nullSubstitution =
        <TypeParameterBuilder, TypeBuilder>{};
    substitution[parameters[i]] = bounds[i];
    nullSubstitution[parameters[i]] = bottomType;
    for (int j = 0; j < parameters.length; j++) {
      TypeParameterBuilder parameter = parameters[j];
      bounds[j] = bounds[j].substituteRange(
              substitution, nullSubstitution, unboundTypeParameters,
              variance: parameter.variance) ??
          bounds[j];
    }
  }

  return bounds;
}

/// Graph of mutual dependencies of type parameters from the same declaration.
/// Type parameters are represented by their indices in the corresponding
/// declaration.
class TypeParametersGraph implements Graph<int> {
  @override
  late List<int> vertices;
  List<TypeParameterBuilder> parameters;
  List<TypeBuilder> bounds;

  // `edges[i]` is the list of indices of type parameters that reference the
  // type parameter with the index `i` in their bounds.
  late List<List<int>> edges;

  TypeParametersGraph(this.parameters, this.bounds) {
    assert(parameters.length == bounds.length);

    vertices = new List<int>.generate(parameters.length, (int i) => i,
        growable: false);
    Map<TypeParameterBuilder, int> parameterIndices =
        <TypeParameterBuilder, int>{};
    edges = new List<List<int>>.generate(parameters.length, (int i) {
      parameterIndices[parameters[i]] = i;
      return <int>[];
    }, growable: false);
    for (int i = 0; i < vertices.length; i++) {
      bounds[i].collectReferencesFrom(parameterIndices, edges, i);
    }
  }

  /// Returns indices of type parameters that depend on the type parameter with
  /// [index].
  @override
  Iterable<int> neighborsOf(int index) {
    return edges[index];
  }
}

/// Finds all type builders for [parameter] in [type].
///
/// Returns list of the found type builders.
List<NamedTypeBuilder> findParameterUsesInType(
    TypeParameterBuilder parameter, TypeBuilder? type) {
  List<NamedTypeBuilder> uses = <NamedTypeBuilder>[];
  switch (type) {
    case NamedTypeBuilder(
        :TypeDeclarationBuilder? declaration,
        typeArguments: List<TypeBuilder>? arguments
      ):
      if (declaration == parameter) {
        uses.add(type);
      } else {
        if (arguments != null) {
          for (TypeBuilder argument in arguments) {
            uses.addAll(findParameterUsesInType(parameter, argument));
          }
        }
      }
      break;
    case FunctionTypeBuilder(
        // Coverage-ignore(suite): Not run.
        :List<StructuralParameterBuilder>? typeParameters,
        // Coverage-ignore(suite): Not run.
        :List<ParameterBuilder>? formals,
        // Coverage-ignore(suite): Not run.
        :TypeBuilder returnType
      ):
      // Coverage-ignore(suite): Not run.
      uses.addAll(findParameterUsesInType(parameter, returnType));
      if (typeParameters != null) {
        // Coverage-ignore-block(suite): Not run.
        for (StructuralParameterBuilder dependentParameter in typeParameters) {
          if (dependentParameter.bound != null) {
            uses.addAll(
                findParameterUsesInType(parameter, dependentParameter.bound));
          }
          if (dependentParameter.defaultType != null) {
            uses.addAll(findParameterUsesInType(
                parameter, dependentParameter.defaultType));
          }
        }
      }
      if (formals != null) {
        // Coverage-ignore-block(suite): Not run.
        for (ParameterBuilder formal in formals) {
          uses.addAll(findParameterUsesInType(parameter, formal.type));
        }
      }
    case RecordTypeBuilder(
        :List<RecordTypeFieldBuilder>? positionalFields,
        :List<RecordTypeFieldBuilder>? namedFields
      ):
      if (positionalFields != null) {
        for (RecordTypeFieldBuilder field in positionalFields) {
          uses.addAll(findParameterUsesInType(parameter, field.type));
        }
      }
      if (namedFields != null) {
        // Coverage-ignore-block(suite): Not run.
        for (RecordTypeFieldBuilder field in namedFields) {
          uses.addAll(findParameterUsesInType(parameter, field.type));
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
  /// Type parameter that references other type parameters in its bound.
  final TypeParameterBuilder typeVariableBuilder;

  /// The references to other type parameters.
  final List<TypeBuilder> dependencies;

  InBoundReferences(this.typeVariableBuilder, this.dependencies);
}

/// Finds those of [parameters] that reference other [parameters] in their
/// bounds.
List<InBoundReferences> findInboundReferences(
    List<TypeParameterBuilder> parameters) {
  List<InBoundReferences> parametersAndDependencies = [];
  for (TypeParameterBuilder dependent in parameters) {
    TypeBuilder? dependentBound = dependent.bound;
    List<NamedTypeBuilder> dependencies = <NamedTypeBuilder>[];
    for (TypeParameterBuilder dependence in parameters) {
      List<NamedTypeBuilder> uses =
          findParameterUsesInType(dependence, dependentBound);
      if (uses.length != 0) {
        dependencies.addAll(uses);
      }
    }
    if (dependencies.length != 0) {
      parametersAndDependencies
          .add(new InBoundReferences(dependent, dependencies));
    }
  }
  return parametersAndDependencies;
}

class TypeWithInBoundReferences {
  /// A [typeBuilder] of a raw generic type.
  final TypeBuilder typeBuilder;

  /// Type parameters of the declaration of [typeBuilder] that reference these
  /// type parameters in their bounds.
  final List<InBoundReferences> inBoundReferences;

  TypeWithInBoundReferences(this.typeBuilder, this.inBoundReferences);
}

/// Finds issues by raw generic types with inbound references in type
/// parameters.
List<NonSimplicityIssue> getInboundReferenceIssues(
    List<TypeParameterBuilder>? parameters) {
  if (parameters == null) return <NonSimplicityIssue>[];

  List<NonSimplicityIssue> issues = <NonSimplicityIssue>[];
  for (TypeParameterBuilder parameter in parameters) {
    TypeBuilder? parameterBound = parameter.bound;
    if (parameterBound != null) {
      List<TypeWithInBoundReferences> rawTypesAndMutualDependencies =
          parameterBound.findRawTypesWithInboundReferences();
      for (int i = 0; i < rawTypesAndMutualDependencies.length; i++) {
        TypeBuilder type = rawTypesAndMutualDependencies[i].typeBuilder;
        List<InBoundReferences> parametersAndDependencies =
            rawTypesAndMutualDependencies[i].inBoundReferences;
        for (int j = 0; j < parametersAndDependencies.length; j++) {
          TypeParameterBuilder dependent =
              parametersAndDependencies[j].typeVariableBuilder;
          List<TypeBuilder> dependencies =
              parametersAndDependencies[j].dependencies;
          for (TypeBuilder dependency in dependencies) {
            issues.add(new NonSimplicityIssue(
                parameter,
                templateBoundIssueViaRawTypeWithNonSimpleBounds
                    .withArguments(type.declaration!.name),
                <LocatedMessage>[
                  templateNonSimpleBoundViaVariable
                      .withArguments(dependency.declaration!.name)
                      .withLocation(dependent.fileUri!, dependent.fileOffset,
                          dependent.name.length)
                ]));
          }
        }
        if (parametersAndDependencies.length == 0) {
          // The inbound references are in a compiled declaration in a .dill.
          issues.add(new NonSimplicityIssue(
              parameter,
              templateBoundIssueViaRawTypeWithNonSimpleBounds
                  .withArguments(type.declaration!.name),
              const <LocatedMessage>[]));
        }
      }
    }
  }
  return issues;
}

/// Finds raw non-simple types in bounds of type parameters in [typeBuilder].
List<NonSimplicityIssue> getInboundReferenceIssuesInType(
    TypeBuilder? typeBuilder) {
  List<FunctionTypeBuilder> genericFunctionTypeBuilders =
      <FunctionTypeBuilder>[];
  findUnaliasedGenericFunctionTypes(typeBuilder,
      result: genericFunctionTypeBuilders);
  List<NonSimplicityIssue> issues = <NonSimplicityIssue>[];
  for (FunctionTypeBuilder genericFunctionTypeBuilder
      in genericFunctionTypeBuilders) {
    List<StructuralParameterBuilder> typeParameters =
        genericFunctionTypeBuilder.typeParameters!;
    issues.addAll(getInboundReferenceIssues(typeParameters));
  }
  return issues;
}

/// Finds raw type paths starting from those in [start] and ending with [end].
///
/// Returns list of found paths consisting of [RawTypeCycleElement]s. The list
/// ends with the type builder for [end].
///
/// The reason for putting the type parameters into the paths as well as for
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
      void visitTypeParameters(List<TypeParameterBuilder>? typeParameters) {
        if (typeParameters == null) return;

        for (TypeParameterBuilder typeParameter in typeParameters) {
          TypeBuilder? parameterBound = typeParameter.bound;
          if (parameterBound != null) {
            for (List<RawTypeCycleElement> path
                in findRawTypePathsToDeclaration(
                    parameterBound, end, visited)) {
              if (path.isNotEmpty) {
                paths.add(<RawTypeCycleElement>[
                  new RawTypeCycleElement(start, null)
                ]..addAll(path..first.typeParameterBuilder = typeParameter));
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
              visitTypeParameters(declaration.typeParameters);
            case TypeAliasBuilder():
              visitTypeParameters(declaration.typeParameters);
              if (declaration.type is FunctionTypeBuilder) {
                FunctionTypeBuilder type =
                    declaration.type as FunctionTypeBuilder;
                visitTypeParameters(type.typeParameters);
              }
            case ExtensionBuilder():
              // Coverage-ignore(suite): Not run.
              visitTypeParameters(declaration.typeParameters);
            case ExtensionTypeDeclarationBuilder():
              visitTypeParameters(declaration.typeParameters);
            case NominalParameterBuilder():
              // Do nothing. The type parameter is handled by its parent
              // declaration.
              break;
            case StructuralParameterBuilder():
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
        :List<StructuralParameterBuilder>? typeParameters,
        :List<ParameterBuilder>? formals,
        :TypeBuilder returnType
      ):
      paths.addAll(findRawTypePathsToDeclaration(returnType, end, visited));
      if (typeParameters != null) {
        for (StructuralParameterBuilder parameter in typeParameters) {
          if (parameter.bound != null) {
            paths.addAll(
                findRawTypePathsToDeclaration(parameter.bound, end, visited));
          }
          if (parameter.defaultType != null) {
            // Coverage-ignore-block(suite): Not run.
            paths.addAll(findRawTypePathsToDeclaration(
                parameter.defaultType, end, visited));
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

List<List<RawTypeCycleElement>> _findRawTypeCyclesFromTypeParameters(
    TypeDeclarationBuilder declaration,
    List<TypeParameterBuilder>? typeParameters) {
  if (typeParameters == null) {
    return const [];
  }

  List<List<RawTypeCycleElement>> cycles = <List<RawTypeCycleElement>>[];
  for (TypeParameterBuilder parameter in typeParameters) {
    TypeBuilder? parameterBound = parameter.bound;
    if (parameterBound != null) {
      for (List<RawTypeCycleElement> dependencyPath
          in findRawTypePathsToDeclaration(parameterBound, declaration)) {
        if (dependencyPath.isNotEmpty) {
          dependencyPath.first.typeParameterBuilder = parameter;
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
/// cycle starts with a type parameter from [declaration] and ends with a type
/// that has [declaration] as its declaration.
///
/// The reason for putting the type parameters into the cycles is better error
/// reporting.
List<List<RawTypeCycleElement>> findRawTypeCycles(
    TypeDeclarationBuilder declaration) {
  if (declaration is SourceClassBuilder) {
    return _findRawTypeCyclesFromTypeParameters(
        declaration, declaration.typeParameters);
  } else if (declaration is SourceTypeAliasBuilder) {
    List<List<RawTypeCycleElement>> cycles = <List<RawTypeCycleElement>>[];
    cycles.addAll(_findRawTypeCyclesFromTypeParameters(
        declaration, declaration.typeParameters));
    if (declaration.type is FunctionTypeBuilder) {
      FunctionTypeBuilder type = declaration.type as FunctionTypeBuilder;
      cycles.addAll(_findRawTypeCyclesFromTypeParameters(
          declaration, type.typeParameters));
      return cycles;
    }
  } else if (declaration is SourceExtensionBuilder) {
    return _findRawTypeCyclesFromTypeParameters(
        declaration, declaration.typeParameters);
  } else if (declaration is SourceExtensionTypeDeclarationBuilder) {
    return _findRawTypeCyclesFromTypeParameters(
        declaration, declaration.typeParameters);
  } else {
    unhandled('$declaration (${declaration.runtimeType})', 'findRawTypeCycles',
        declaration.fileOffset, declaration.fileUri);
  }
  return const [];
}

/// Converts raw generic type [cycles] for [declaration] into reportable issues.
///
/// The [cycles] are expected to be in the format specified for the return value
/// of [findRawTypeCycles].
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
                cycleElement.typeParameterBuilder!.fileUri!,
                cycleElement.typeParameterBuilder!.fileOffset,
                cycleElement.typeParameterBuilder!.name.length));
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

/// Finds non-simplicity issues for the given set of [parameters].
///
/// The issues are those caused by raw types with inbound references in the
/// bounds of their type parameters.
List<NonSimplicityIssue> getNonSimplicityIssuesForTypeParameters(
    List<NominalParameterBuilder>? parameters) {
  if (parameters == null) return <NonSimplicityIssue>[];
  return getInboundReferenceIssues(parameters);
}

/// Finds non-simplicity issues for the given [declaration].
///
/// The issues are those caused by raw types with inbound references in the
/// bounds of type parameters from [declaration] and by cycles of raw types
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
    issues.addAll(getInboundReferenceIssues(declaration.typeParameters));
  } else if (declaration is SourceTypeAliasBuilder) {
    issues.addAll(getInboundReferenceIssues(declaration.typeParameters));
  } else if (declaration is SourceExtensionBuilder) {
    issues.addAll(getInboundReferenceIssues(declaration.typeParameters));
  } else if (declaration is SourceExtensionTypeDeclarationBuilder) {
    issues.addAll(getInboundReferenceIssues(declaration.typeParameters));
  } else {
    unhandled(
        '$declaration (${declaration.runtimeType})',
        'getNonSimplicityIssuesForDeclaration',
        declaration.fileOffset,
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
      cycle.first.typeParameterBuilder?.bound = null;
    }
  }
}

/// Finds generic function type sub-terms in [type].
void findUnaliasedGenericFunctionTypes(TypeBuilder? type,
    {required List<FunctionTypeBuilder> result}) {
  switch (type) {
    case FunctionTypeBuilder(
        typeParameters: List<StructuralParameterBuilder>? typeParameters,
        :List<ParameterBuilder>? formals,
        :TypeBuilder returnType
      ):
      if (typeParameters != null && typeParameters.length > 0) {
        result.add(type);

        for (StructuralParameterBuilder typeParameter in typeParameters) {
          findUnaliasedGenericFunctionTypes(typeParameter.bound,
              result: result);
          findUnaliasedGenericFunctionTypes(typeParameter.defaultType,
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

/// Returns true if [type] contains any type parameters whatsoever. This should
/// only be used for working around transitional issues.
// TODO(ahe): Remove this method.
bool hasAnyTypeParameters(DartType type) {
  return type.accept(const TypeParameterSearch());
}

/// Don't use this directly, use [hasAnyTypeParameters] instead. But don't use
/// that either.
// TODO(ahe): Remove this class.
class TypeParameterSearch extends FindTypeVisitor {
  const TypeParameterSearch();

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
/// type parameters in-between them is recorded for better error reporting. An
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

  /// The type parameter that connects [type] to the next element in the
  /// non-simple raw type cycle.
  TypeParameterBuilder? typeParameterBuilder;

  RawTypeCycleElement(this.type, this.typeParameterBuilder);
}
