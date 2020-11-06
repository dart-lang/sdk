// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:front_end/src/fasta/kernel/internal_ast.dart';

import 'package:kernel/ast.dart'
    show
        Constructor,
        DartType,
        DartTypeVisitor,
        Field,
        FunctionType,
        FutureOrType,
        InterfaceType,
        Member,
        NamedType,
        NeverType,
        NullType,
        Nullability,
        Statement,
        TreeNode,
        TypeParameter,
        TypeParameterType,
        TypedefType,
        VariableDeclaration,
        Variance;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/type_environment.dart';

import '../../base/instrumentation.dart' show Instrumentation;

import '../builder/constructor_builder.dart';

import '../kernel/forest.dart';

import '../kernel/kernel_builder.dart'
    show ClassHierarchyBuilder, ImplicitFieldType;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import 'factor_type.dart';

import 'type_inferrer.dart';

import 'type_schema_environment.dart' show TypeSchemaEnvironment;

/// Visitor to check whether a given type mentions any of a class's type
/// parameters in a non-covariant fashion.
class IncludesTypeParametersNonCovariantly extends DartTypeVisitor<bool> {
  int _variance;

  final List<TypeParameter> _typeParametersToSearchFor;

  IncludesTypeParametersNonCovariantly(this._typeParametersToSearchFor,
      {int initialVariance})
      : _variance = initialVariance;

  @override
  bool defaultDartType(DartType node) => false;

  @override
  bool visitFunctionType(FunctionType node) {
    if (node.returnType.accept(this)) return true;
    int oldVariance = _variance;
    _variance = Variance.invariant;
    for (TypeParameter parameter in node.typeParameters) {
      if (parameter.bound.accept(this)) return true;
    }
    _variance = Variance.combine(Variance.contravariant, oldVariance);
    for (DartType parameter in node.positionalParameters) {
      if (parameter.accept(this)) return true;
    }
    for (NamedType parameter in node.namedParameters) {
      if (parameter.type.accept(this)) return true;
    }
    _variance = oldVariance;
    return false;
  }

  @override
  bool visitInterfaceType(InterfaceType node) {
    int oldVariance = _variance;
    for (int i = 0; i < node.typeArguments.length; i++) {
      _variance = Variance.combine(
          node.classNode.typeParameters[i].variance, oldVariance);
      if (node.typeArguments[i].accept(this)) return true;
    }
    _variance = oldVariance;
    return false;
  }

  @override
  bool visitFutureOrType(FutureOrType node) {
    return node.typeArgument.accept(this);
  }

  @override
  bool visitTypedefType(TypedefType node) {
    return node.unalias.accept(this);
  }

  @override
  bool visitTypeParameterType(TypeParameterType node) {
    return !Variance.greaterThanOrEqual(_variance, node.parameter.variance) &&
        _typeParametersToSearchFor.contains(node.parameter);
  }
}

/// Keeps track of the global state for the type inference that occurs outside
/// of method bodies and initializers.
///
/// This class describes the interface for use by clients of type inference
/// (e.g. DietListener).  Derived classes should derive from
/// [TypeInferenceEngineImpl].
abstract class TypeInferenceEngine {
  ClassHierarchy classHierarchy;

  ClassHierarchyBuilder hierarchyBuilder;

  CoreTypes coreTypes;

  // TODO(johnniwinther): Shared this with the BodyBuilder.
  final Forest forest = const Forest();

  /// Indicates whether the "prepare" phase of type inference is complete.
  bool isTypeInferencePrepared = false;

  TypeSchemaEnvironment typeSchemaEnvironment;

  /// A map containing constructors with initializing formals whose types
  /// need to be inferred.
  ///
  /// This is represented as a map from a constructor to its library
  /// builder because the builder is used to report errors due to cyclic
  /// inference dependencies.
  final Map<Constructor, ConstructorBuilder> toBeInferred = {};

  /// A map containing constructors in the process of being inferred.
  ///
  /// This is used to detect cyclic inference dependencies.  It is represented
  /// as a map from a constructor to its library builder because the builder
  /// is used to report errors.
  final Map<Constructor, ConstructorBuilder> beingInferred = {};

  final Instrumentation instrumentation;

  TypeInferenceEngine(this.instrumentation);

  /// Creates a type inferrer for use inside of a method body declared in a file
  /// with the given [uri].
  TypeInferrer createLocalTypeInferrer(Uri uri, InterfaceType thisType,
      SourceLibraryBuilder library, InferenceDataForTesting dataForTesting);

  /// Creates a [TypeInferrer] object which is ready to perform type inference
  /// on the given [field].
  TypeInferrer createTopLevelTypeInferrer(Uri uri, InterfaceType thisType,
      SourceLibraryBuilder library, InferenceDataForTesting dataForTesting);

  /// Performs the third phase of top level inference, which is to visit all
  /// constructors still needing inference and infer the types of their
  /// initializing formals from the corresponding fields.
  void finishTopLevelInitializingFormals() {
    // Field types have all been inferred so we don't need to guard against
    // cyclic dependency.
    toBeInferred.values.forEach((ConstructorBuilder builder) {
      builder.inferFormalTypes();
    });
    toBeInferred.clear();
  }

  /// Gets ready to do top level type inference for the component having the
  /// given [hierarchy], using the given [coreTypes].
  void prepareTopLevel(CoreTypes coreTypes, ClassHierarchy hierarchy) {
    this.coreTypes = coreTypes;
    this.classHierarchy = hierarchy;
    this.typeSchemaEnvironment =
        new TypeSchemaEnvironment(coreTypes, hierarchy);
  }

  static Member resolveInferenceNode(Member member) {
    if (member is Field) {
      DartType type = member.type;
      if (type is ImplicitFieldType) {
        type.inferType();
      }
    }
    return member;
  }
}

/// Concrete implementation of [TypeInferenceEngine] specialized to work with
/// kernel objects.
class TypeInferenceEngineImpl extends TypeInferenceEngine {
  TypeInferenceEngineImpl(Instrumentation instrumentation)
      : super(instrumentation);

  @override
  TypeInferrer createLocalTypeInferrer(Uri uri, InterfaceType thisType,
      SourceLibraryBuilder library, InferenceDataForTesting dataForTesting) {
    AssignedVariables<TreeNode, VariableDeclaration> assignedVariables;
    if (dataForTesting != null) {
      assignedVariables = dataForTesting.flowAnalysisResult.assignedVariables =
          new AssignedVariablesForTesting<TreeNode, VariableDeclaration>();
    } else {
      assignedVariables =
          new AssignedVariables<TreeNode, VariableDeclaration>();
    }
    return new TypeInferrerImpl(
        this, uri, false, thisType, library, assignedVariables, dataForTesting);
  }

  @override
  TypeInferrer createTopLevelTypeInferrer(Uri uri, InterfaceType thisType,
      SourceLibraryBuilder library, InferenceDataForTesting dataForTesting) {
    AssignedVariables<TreeNode, VariableDeclaration> assignedVariables;
    if (dataForTesting != null) {
      assignedVariables = dataForTesting.flowAnalysisResult.assignedVariables =
          new AssignedVariablesForTesting<TreeNode, VariableDeclaration>();
    } else {
      assignedVariables =
          new AssignedVariables<TreeNode, VariableDeclaration>();
    }
    return new TypeInferrerImpl(
        this, uri, true, thisType, library, assignedVariables, dataForTesting);
  }
}

class InferenceDataForTesting {
  final FlowAnalysisResult flowAnalysisResult = new FlowAnalysisResult();
}

/// The result of performing flow analysis on a unit.
class FlowAnalysisResult {
  /// The list of nodes, [Expression]s or [Statement]s, that cannot be reached,
  /// for example because a previous statement always exits.
  final List<TreeNode> unreachableNodes = [];

  /// The list of function bodies that don't complete, for example because
  /// there is a `return` statement at the end of the function body block.
  final List<TreeNode> functionBodiesThatDontComplete = [];

  /// The list of [Expression]s representing variable accesses that occur before
  /// the corresponding variable has been definitely assigned.
  final List<TreeNode> potentiallyUnassignedNodes = [];

  /// The list of [Expression]s representing variable accesses that occur when
  /// the corresponding variable has been definitely unassigned.
  final List<TreeNode> definitelyUnassignedNodes = [];

  /// The assigned variables information that computed for the member.
  AssignedVariablesForTesting<TreeNode, VariableDeclaration> assignedVariables;
}

/// CFE-specific implementation of [TypeOperations].
class TypeOperationsCfe extends TypeOperations<VariableDeclaration, DartType> {
  final TypeEnvironment typeEnvironment;

  TypeOperationsCfe(this.typeEnvironment);

  @override
  TypeClassification classifyType(DartType type) {
    if (type == null) {
      // Note: this can happen during top-level inference.
      return TypeClassification.potentiallyNullable;
    } else if (isSubtypeOf(
        type, typeEnvironment.coreTypes.objectNonNullableRawType)) {
      return TypeClassification.nonNullable;
    } else if (isSubtypeOf(type, const NullType())) {
      return TypeClassification.nullOrEquivalent;
    } else {
      return TypeClassification.potentiallyNullable;
    }
  }

  @override
  DartType factor(DartType from, DartType what) {
    return factorType(typeEnvironment, from, what);
  }

  @override
  bool isNever(DartType type) {
    return typeEnvironment.coreTypes.isBottom(type);
  }

  // TODO(dmitryas): Consider checking for mutual subtypes instead of ==.
  @override
  bool isSameType(DartType type1, DartType type2) => type1 == type2;

  @override
  bool isSubtypeOf(DartType leftType, DartType rightType) {
    return typeEnvironment.isSubtypeOf(
        leftType, rightType, SubtypeCheckMode.withNullabilities);
  }

  @override
  DartType promoteToNonNull(DartType type) {
    if (type is TypeParameterType &&
        type.declaredNullability != Nullability.nullable) {
      DartType bound =
          type.bound.withDeclaredNullability(Nullability.nonNullable);
      if (bound != type.bound) {
        return new TypeParameterType(
            type.parameter, type.declaredNullability, bound);
      }
      return type;
    } else if (type is NullType) {
      return const NeverType(Nullability.nonNullable);
    }
    return type.withDeclaredNullability(Nullability.nonNullable);
  }

  @override
  DartType variableType(VariableDeclaration variable) {
    if (variable is VariableDeclarationImpl) {
      // When late variables get lowered, their type is changed, but the
      // original type is stored in `VariableDeclarationImpl.lateType`, so we
      // use that if it exists.
      return variable.lateType ?? variable.type;
    }
    return variable.type;
  }

  @override
  DartType tryPromoteToType(DartType to, DartType from) {
    if (isSubtypeOf(to, from)) {
      return to;
    }
    if (from is TypeParameterType) {
      if (isSubtypeOf(to, from.promotedBound ?? from.bound)) {
        return new TypeParameterType.intersection(
            from.parameter, from.nullability, to);
      }
    }
    return from;
  }
}
