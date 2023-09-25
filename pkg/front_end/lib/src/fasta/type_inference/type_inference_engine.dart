// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/type_inference/assigned_variables.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_operations.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchy, ClassHierarchyBase;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/src/norm.dart';
import 'package:kernel/type_environment.dart';

import '../../base/instrumentation.dart' show Instrumentation;
import '../kernel/benchmarker.dart' show Benchmarker;
import '../kernel/hierarchy/hierarchy_builder.dart' show ClassHierarchyBuilder;
import '../kernel/hierarchy/members_builder.dart' show ClassMembersBuilder;
import '../kernel/implicit_field_type.dart';
import '../kernel/internal_ast.dart';
import '../kernel/kernel_helper.dart';
import '../source/source_constructor_builder.dart';
import '../source/source_library_builder.dart' show SourceLibraryBuilder;
import 'factor_type.dart';
import 'type_inferrer.dart';
import 'type_schema_environment.dart' show TypeSchemaEnvironment;

/// Visitor to check whether a given type mentions any of a class's type
/// parameters in a non-covariant fashion.
class IncludesTypeParametersNonCovariantly implements DartTypeVisitor<bool> {
  int _variance;

  final List<TypeParameter> _typeParametersToSearchFor;

  IncludesTypeParametersNonCovariantly(this._typeParametersToSearchFor,
      {required int initialVariance})
      : _variance = initialVariance;

  @override
  bool visitAuxiliaryType(AuxiliaryType node) {
    throw new UnsupportedError(
        "Unsupported auxiliary type ${node} (${node.runtimeType}).");
  }

  @override
  bool visitDynamicType(DynamicType node) => false;

  @override
  bool visitExtensionType(ExtensionType node) => false;

  @override
  bool visitNeverType(NeverType node) => false;

  @override
  bool visitInvalidType(InvalidType node) => false;

  @override
  bool visitNullType(NullType node) => false;

  @override
  bool visitVoidType(VoidType node) => false;

  @override
  bool visitFunctionType(FunctionType node) {
    if (node.returnType.accept(this)) return true;
    int oldVariance = _variance;
    _variance = Variance.invariant;
    for (StructuralParameter parameter in node.typeParameters) {
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
  bool visitRecordType(RecordType node) {
    for (DartType parameter in node.positional) {
      if (parameter.accept(this)) return true;
    }
    for (NamedType parameter in node.named) {
      if (parameter.type.accept(this)) return true;
    }
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

  @override
  bool visitStructuralParameterType(StructuralParameterType node) {
    return false;
  }

  @override
  bool visitIntersectionType(IntersectionType node) {
    return node.left.accept(this);
  }
}

/// Keeps track of the global state for the type inference that occurs outside
/// of method bodies and initializers.
///
/// This class describes the interface for use by clients of type inference
/// (e.g. DietListener).  Derived classes should derive from
/// [TypeInferenceEngineImpl].
abstract class TypeInferenceEngine {
  late ClassHierarchyBuilder hierarchyBuilder;

  late ClassMembersBuilder membersBuilder;

  late CoreTypes coreTypes;

  /// Indicates whether the "prepare" phase of type inference is complete.
  bool isTypeInferencePrepared = false;

  late TypeSchemaEnvironment typeSchemaEnvironment;

  /// A map containing constructors with initializing formals whose types
  /// need to be inferred.
  ///
  /// This is represented as a map from a constructor to its library
  /// builder because the builder is used to report errors due to cyclic
  /// inference dependencies.
  final Map<Member, SourceConstructorBuilder> toBeInferred = {};

  /// A map containing constructors in the process of being inferred.
  ///
  /// This is used to detect cyclic inference dependencies.  It is represented
  /// as a map from a constructor to its library builder because the builder
  /// is used to report errors.
  final Map<Member, SourceConstructorBuilder> beingInferred = {};

  final Map<Member, TypeDependency> typeDependencies = {};

  final Instrumentation? instrumentation;

  final Map<DartType, DartType> typeCacheNonNullable =
      new Map<DartType, DartType>.identity();
  final Map<DartType, DartType> typeCacheNullable =
      new Map<DartType, DartType>.identity();
  final Map<DartType, DartType> typeCacheLegacy =
      new Map<DartType, DartType>.identity();

  TypeInferenceEngine(this.instrumentation);

  /// Creates a type inferrer for use inside of a method body declared in a file
  /// with the given [uri].
  TypeInferrer createLocalTypeInferrer(Uri uri, InterfaceType? thisType,
      SourceLibraryBuilder library, InferenceDataForTesting? dataForTesting);

  /// Creates a [TypeInferrer] object which is ready to perform type inference
  /// on the given [field].
  TypeInferrer createTopLevelTypeInferrer(Uri uri, InterfaceType? thisType,
      SourceLibraryBuilder library, InferenceDataForTesting? dataForTesting);

  /// Performs the third phase of top level inference, which is to visit all
  /// constructors still needing inference and infer the types of their
  /// initializing formals from the corresponding fields.
  void finishTopLevelInitializingFormals() {
    // Field types have all been inferred so we don't need to guard against
    // cyclic dependency.
    for (SourceConstructorBuilder builder in toBeInferred.values) {
      builder.inferFormalTypes(hierarchyBuilder);
    }
    toBeInferred.clear();
    for (TypeDependency typeDependency in typeDependencies.values) {
      typeDependency.copyInferred();
    }
    typeDependencies.clear();
  }

  /// Gets ready to do top level type inference for the component having the
  /// given [hierarchy], using the given [coreTypes].
  void prepareTopLevel(CoreTypes coreTypes, ClassHierarchy hierarchy) {
    this.coreTypes = coreTypes;
    this.typeSchemaEnvironment =
        new TypeSchemaEnvironment(coreTypes, hierarchy);
  }

  static Member? resolveInferenceNode(
      Member? member, ClassHierarchyBase hierarchy) {
    if (member is Field) {
      DartType type = member.type;
      if (type is InferredType) {
        type.inferType(hierarchy);
      }
    }
    return member;
  }

  Procedure? _addMethod;

  /// Returns the [Procedure] for the [Set.add] method.
  ///
  /// This is used for lowering set literals for targets that don't support the
  /// [SetLiteral] node.
  Procedure get setAddMethod => _addMethod ??= _findAddMethod();

  Procedure _findAddMethod() {
    return coreTypes.index.getProcedure('dart:core', 'Set', 'add');
  }

  FunctionType? _addMethodFunctionType;

  /// Returns the [FunctionType] for the [Set.add] method.
  ///
  /// This is used for lowering set literals for targets that don't support the
  /// [SetLiteral] node.
  FunctionType get setAddMethodFunctionType =>
      _addMethodFunctionType ??= setAddMethod.getterType as FunctionType;

  Procedure? _listAdd;
  Procedure get listAdd =>
      _listAdd ??= coreTypes.index.getProcedure('dart:core', 'List', 'add');

  FunctionType? _listAddFunctionType;
  FunctionType get listAddFunctionType =>
      _listAddFunctionType ??= listAdd.getterType as FunctionType;

  Procedure? _listAddAll;
  Procedure get listAddAll => _listAddAll ??=
      coreTypes.index.getProcedure('dart:core', 'List', 'addAll');

  FunctionType? _listAddAllFunctionType;
  FunctionType get listAddAllFunctionType =>
      _listAddAllFunctionType ??= listAddAll.getterType as FunctionType;

  Procedure? _listOf;
  Procedure get listOf =>
      _listOf ??= coreTypes.index.getProcedure('dart:core', 'List', 'of');

  Procedure? _setFactory;
  Procedure get setFactory => _setFactory ??= _findSetFactory(coreTypes, '');

  Procedure? _setAdd;
  Procedure get setAdd =>
      _setAdd ??= coreTypes.index.getProcedure('dart:core', 'Set', 'add');

  FunctionType? _setAddFunctionType;
  FunctionType get setAddFunctionType =>
      _setAddFunctionType ??= setAdd.getterType as FunctionType;

  Procedure? _setAddAll;
  Procedure get setAddAll =>
      _setAddAll ??= coreTypes.index.getProcedure('dart:core', 'Set', 'addAll');

  FunctionType? _setAddAllFunctionType;
  FunctionType get setAddAllFunctionType =>
      _setAddAllFunctionType ??= setAddAll.getterType as FunctionType;

  Procedure? _setOf;
  Procedure get setOf => _setOf ??= _findSetFactory(coreTypes, 'of');

  Procedure? _mapEntries;
  Procedure get mapEntries => _mapEntries ??=
      coreTypes.index.getProcedure('dart:core', 'Map', 'get:entries');

  Procedure? _mapPut;
  Procedure get mapPut =>
      _mapPut ??= coreTypes.index.getProcedure('dart:core', 'Map', '[]=');

  FunctionType? _mapPutFunctionType;
  FunctionType get mapPutFunctionType =>
      _mapPutFunctionType ??= mapPut.getterType as FunctionType;

  Class? _mapEntryClass;
  Class get mapEntryClass =>
      _mapEntryClass ??= coreTypes.index.getClass('dart:core', 'MapEntry');

  Field? _mapEntryKey;
  Field get mapEntryKey =>
      _mapEntryKey ??= coreTypes.index.getField('dart:core', 'MapEntry', 'key');

  Field? _mapEntryValue;
  Field get mapEntryValue => _mapEntryValue ??=
      coreTypes.index.getField('dart:core', 'MapEntry', 'value');

  Procedure? _mapAddAll;
  Procedure get mapAddAll =>
      _mapAddAll ??= coreTypes.index.getProcedure('dart:core', 'Map', 'addAll');

  FunctionType? _mapAddAllFunctionType;
  FunctionType get mapAddAllFunctionType =>
      _mapAddAllFunctionType ??= mapAddAll.getterType as FunctionType;

  Procedure? _mapOf;
  Procedure get mapOf => _mapOf ??= _findMapFactory(coreTypes, 'of');

  static Procedure _findSetFactory(CoreTypes coreTypes, String name) {
    Procedure factory = coreTypes.index.getProcedure('dart:core', 'Set', name);
    RedirectingFactoryTarget redirectingFactoryTarget =
        factory.function.redirectingFactoryTarget!;
    return redirectingFactoryTarget.target as Procedure;
  }

  static Procedure _findMapFactory(CoreTypes coreTypes, String name) {
    Procedure factory = coreTypes.index.getProcedure('dart:core', 'Map', name);
    RedirectingFactoryTarget redirectingFactoryTarget =
        factory.function.redirectingFactoryTarget!;
    return redirectingFactoryTarget.target as Procedure;
  }
}

/// Concrete implementation of [TypeInferenceEngine] specialized to work with
/// kernel objects.
class TypeInferenceEngineImpl extends TypeInferenceEngine {
  final Benchmarker? benchmarker;
  final FunctionType unknownFunctionNonNullable =
      new FunctionType(const [], const DynamicType(), Nullability.nonNullable);
  final FunctionType unknownFunctionLegacy =
      new FunctionType(const [], const DynamicType(), Nullability.legacy);

  TypeInferenceEngineImpl(Instrumentation? instrumentation, this.benchmarker)
      : super(instrumentation);

  @override
  TypeInferrer createLocalTypeInferrer(Uri uri, InterfaceType? thisType,
      SourceLibraryBuilder library, InferenceDataForTesting? dataForTesting) {
    AssignedVariables<TreeNode, VariableDeclaration> assignedVariables;
    if (dataForTesting != null) {
      assignedVariables = dataForTesting.flowAnalysisResult.assignedVariables =
          new AssignedVariablesForTesting<TreeNode, VariableDeclaration>();
    } else {
      assignedVariables =
          new AssignedVariables<TreeNode, VariableDeclaration>();
    }
    if (benchmarker == null) {
      return new TypeInferrerImpl(
          this,
          uri,
          false,
          thisType,
          library,
          assignedVariables,
          dataForTesting,
          unknownFunctionNonNullable,
          unknownFunctionLegacy);
    }
    return new TypeInferrerImplBenchmarked(
        this,
        uri,
        false,
        thisType,
        library,
        assignedVariables,
        dataForTesting,
        benchmarker!,
        unknownFunctionNonNullable,
        unknownFunctionLegacy);
  }

  @override
  TypeInferrer createTopLevelTypeInferrer(Uri uri, InterfaceType? thisType,
      SourceLibraryBuilder library, InferenceDataForTesting? dataForTesting) {
    AssignedVariables<TreeNode, VariableDeclaration> assignedVariables;
    if (dataForTesting != null) {
      assignedVariables = dataForTesting.flowAnalysisResult.assignedVariables =
          new AssignedVariablesForTesting<TreeNode, VariableDeclaration>();
    } else {
      assignedVariables =
          new AssignedVariables<TreeNode, VariableDeclaration>();
    }
    if (benchmarker == null) {
      return new TypeInferrerImpl(
          this,
          uri,
          true,
          thisType,
          library,
          assignedVariables,
          dataForTesting,
          unknownFunctionNonNullable,
          unknownFunctionLegacy);
    }
    return new TypeInferrerImplBenchmarked(
        this,
        uri,
        true,
        thisType,
        library,
        assignedVariables,
        dataForTesting,
        benchmarker!,
        unknownFunctionNonNullable,
        unknownFunctionLegacy);
  }
}

class InferenceDataForTesting {
  final FlowAnalysisResult flowAnalysisResult = new FlowAnalysisResult();

  final TypeInferenceResultForTesting typeInferenceResult =
      new TypeInferenceResultForTesting();
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
  AssignedVariablesForTesting<TreeNode, VariableDeclaration>? assignedVariables;

  /// For each expression that led to an error because it was not promoted, a
  /// string describing the reason it was not promoted.
  final Map<TreeNode, String> nonPromotionReasons = {};

  /// For each auxiliary AST node pointed to by a non-promotion reason, a string
  /// describing the non-promotion reason pointing to it.
  final Map<TreeNode, String> nonPromotionReasonTargets = {};
}

/// CFE-specific implementation of [TypeOperations].
class OperationsCfe
    with TypeOperations<DartType>
    implements Operations<VariableDeclaration, DartType> {
  final TypeEnvironment typeEnvironment;

  final Nullability nullability;

  /// If `null`, field promotion is disabled for this library.  If not `null`,
  /// field promotion is enabled for this library and this is the set of private
  /// field names for which promotion is blocked due to the presence of a
  /// non-final field or a concrete getter.
  final Set<String>? unpromotablePrivateFieldNames;

  final Map<DartType, DartType> typeCacheNonNullable;
  final Map<DartType, DartType> typeCacheNullable;
  final Map<DartType, DartType> typeCacheLegacy;

  OperationsCfe(this.typeEnvironment,
      {required this.nullability,
      this.unpromotablePrivateFieldNames,
      required this.typeCacheNonNullable,
      required this.typeCacheNullable,
      required this.typeCacheLegacy});

  @override
  DartType get boolType => typeEnvironment.coreTypes.boolRawType(nullability);

  @override
  TypeClassification classifyType(DartType? type) {
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

  @override
  bool isPropertyPromotable(covariant Member property) {
    Set<String>? unpromotablePrivateFieldNames =
        this.unpromotablePrivateFieldNames;
    if (unpromotablePrivateFieldNames == null) return false;
    if (property is Procedure) {
      if (property.isAbstractFieldAccessor || property.isLoweredLateField) {
        // Property was declared as a field; it was lowered to a getter or
        // getter/setter pair. So for field promotion purposes treat it as a
        // field.
      } else {
        // We don't promote methods or explicit getters.
        return false;
      }
    }
    String name = property.name.text;
    if (!name.startsWith('_')) return false;
    return !unpromotablePrivateFieldNames.contains(name);
  }

  // TODO(cstefantsova): Consider checking for mutual subtypes instead of ==.
  @override
  bool isSameType(DartType type1, DartType type2) => type1 == type2;

  @override
  bool isSubtypeOf(DartType leftType, DartType rightType) {
    return typeEnvironment.isSubtypeOf(
        leftType, rightType, SubtypeCheckMode.withNullabilities);
  }

  @override
  DartType promoteToNonNull(DartType type) {
    if (type.nullability == Nullability.nonNullable) {
      return type;
    }
    DartType? cached = typeCacheNonNullable[type];
    if (cached != null) {
      return cached;
    }
    DartType result = type.toNonNull();
    typeCacheNonNullable[type] = result;
    return result;
  }

  DartType getNullableType(DartType type) {
    // Note that the [IntersectionType.withDeclaredNullability] is special so
    // we don't trust it.
    if (type.declaredNullability == Nullability.nullable &&
        type is! IntersectionType) {
      return type;
    }
    DartType? cached = typeCacheNullable[type];
    if (cached != null) {
      return cached;
    }
    DartType result = type.withDeclaredNullability(Nullability.nullable);
    typeCacheNullable[type] = result;
    return result;
  }

  DartType getLegacyType(DartType type) {
    // Note that the [IntersectionType.withDeclaredNullability] is special so
    // we don't trust it.
    if (type.declaredNullability == Nullability.legacy &&
        type is! IntersectionType) {
      return type;
    }
    DartType? cached = typeCacheLegacy[type];
    if (cached != null) {
      return cached;
    }
    DartType result = type.withDeclaredNullability(Nullability.legacy);
    typeCacheLegacy[type] = result;
    return result;
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
  bool isTypeParameterType(DartType type) {
    return type is TypeParameterType || type is IntersectionType;
  }

  @override
  DartType tryPromoteToType(DartType to, DartType from) {
    if (isSubtypeOf(to, from)) {
      return to;
    }
    if (from is TypeParameterType) {
      if (isSubtypeOf(to, from.bound)) {
        if (to.nullability != Nullability.nullable) {
          // We treat promotions of the form `x is T`, where `T` is not
          // nullable, as a two-step promotions equivalent to
          // `x != null && x is T`.
          return new IntersectionType(
              from.withDeclaredNullability(
                  TypeParameterType.computeNullabilityFromBound(
                      from.parameter)),
              to);
        } else {
          return new IntersectionType(from, to);
        }
      }
    }
    if (from is IntersectionType) {
      if (isSubtypeOf(to, from.right)) {
        return new IntersectionType(from.left, to);
      }
    }
    return from;
  }

  @override
  DartType glb(DartType type1, DartType type2) {
    return typeEnvironment.getStandardLowerBound(type1, type2,
        isNonNullableByDefault: true);
  }

  @override
  bool isAssignableTo(DartType fromType, DartType toType) {
    if (nullability == Nullability.nonNullable) {
      if (fromType is DynamicType) return true;
      return typeEnvironment
          .performNullabilityAwareSubtypeCheck(fromType, toType)
          .isSubtypeWhenUsingNullabilities();
    } else {
      return typeEnvironment
          .performNullabilityAwareSubtypeCheck(fromType, toType)
          .orSubtypeCheckFor(toType, fromType, typeEnvironment)
          .isSubtypeWhenIgnoringNullabilities();
    }
  }

  @override
  bool isDynamic(DartType type) => type is DynamicType;

  @override
  bool isError(DartType type) => type is InvalidType;

  @override
  DartType lub(DartType type1, DartType type2) {
    return typeEnvironment.getStandardUpperBound(type1, type2,
        isNonNullableByDefault: true);
  }

  @override
  DartType makeNullable(DartType type) {
    return type.withDeclaredNullability(Nullability.nullable);
  }

  @override
  DartType? matchListType(DartType type) {
    if (type is InterfaceType) {
      List<DartType>? typeArguments =
          typeEnvironment.getTypeArgumentsAsInstanceOf(
              type, typeEnvironment.coreTypes.listClass);
      if (typeArguments == null || typeArguments.length != 1) {
        return null;
      } else {
        return typeArguments.single;
      }
    } else {
      return null;
    }
  }

  @override
  MapPatternTypeArguments<DartType>? matchMapType(DartType type) {
    if (type is! InterfaceType) {
      return null;
    } else {
      InterfaceType? mapType = typeEnvironment.getTypeAsInstanceOf(
          type, typeEnvironment.coreTypes.mapClass, typeEnvironment.coreTypes,
          isNonNullableByDefault: nullability == Nullability.nonNullable);
      if (mapType == null) {
        return null;
      } else {
        return new MapPatternTypeArguments<DartType>(
            keyType: mapType.typeArguments[0],
            valueType: mapType.typeArguments[1]);
      }
    }
  }

  @override
  DartType? matchStreamType(DartType type) {
    if (type is InterfaceType) {
      List<DartType>? typeArguments =
          typeEnvironment.getTypeArgumentsAsInstanceOf(
              type, typeEnvironment.coreTypes.streamClass);
      if (typeArguments == null || typeArguments.length != 1) {
        return null;
      } else {
        return typeArguments.single;
      }
    } else {
      return null;
    }
  }

  @override
  bool areStructurallyEqual(DartType type1, DartType type2) {
    // TODO(cstefantsova): Use the actual algorithm for structural equality.
    return type1 == type2;
  }

  @override
  DartType normalize(DartType type) {
    return norm(typeEnvironment.coreTypes, type);
  }

  @override
  DartType? matchIterableType(DartType type) {
    if (type is! InterfaceType) {
      return null;
    } else {
      InterfaceType? interfaceType = typeEnvironment.getTypeAsInstanceOf(type,
          typeEnvironment.coreTypes.iterableClass, typeEnvironment.coreTypes,
          isNonNullableByDefault: nullability == Nullability.nonNullable);
      if (interfaceType == null) {
        return null;
      } else {
        return interfaceType.typeArguments.single;
      }
    }
  }
}

/// Type inference results used for testing.
class TypeInferenceResultForTesting {
  final Map<TreeNode, List<DartType>> inferredTypeArguments = {};
  final Map<TreeNode, DartType> inferredVariableTypes = {};
}
