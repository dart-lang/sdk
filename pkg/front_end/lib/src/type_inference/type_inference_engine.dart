// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis_operations.dart';
import 'package:_fe_analyzer_shared/src/type_inference/assigned_variables.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer_operations.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_constraint.dart'
    as shared;
import 'package:_fe_analyzer_shared/src/types/shared_type.dart' hide Variance;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchy, ClassHierarchyBase;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/src/norm.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../base/scope.dart';
import '../kernel/benchmarker.dart' show Benchmarker;
import '../kernel/exhaustiveness.dart';
import '../kernel/hierarchy/hierarchy_builder.dart' show ClassHierarchyBuilder;
import '../kernel/hierarchy/members_builder.dart' show ClassMembersBuilder;
import '../kernel/implicit_field_type.dart';
import '../kernel/internal_ast.dart';
import '../kernel/kernel_helper.dart';
import '../source/source_library_builder.dart'
    show FieldNonPromotabilityInfo, SourceLibraryBuilder;
import 'factor_type.dart';
import 'type_constraint_gatherer.dart';
import 'type_inferrer.dart';
import 'type_schema.dart';
import 'type_schema_elimination.dart' as type_schema_elimination;
import 'type_schema_environment.dart';

/// Visitor to check whether a given type mentions any of a class's type
/// parameters in a non-covariant fashion.
class IncludesTypeParametersNonCovariantly implements DartTypeVisitor<bool> {
  Variance _variance;

  final List<TypeParameter> _typeParametersToSearchFor;

  IncludesTypeParametersNonCovariantly(
    this._typeParametersToSearchFor, {
    required Variance initialVariance,
  }) : _variance = initialVariance;

  @override
  bool visitAuxiliaryType(AuxiliaryType node) {
    throw new UnsupportedError(
      "Unsupported auxiliary type ${node} (${node.runtimeType}).",
    );
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
    Variance oldVariance = _variance;
    _variance = Variance.invariant;
    for (StructuralParameter parameter in node.typeParameters) {
      if (parameter.bound.accept(this)) return true;
    }
    _variance = Variance.contravariant.combine(oldVariance);
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
    Variance oldVariance = _variance;
    for (int i = 0; i < node.typeArguments.length; i++) {
      _variance = node.classNode.typeParameters[i].variance.combine(
        oldVariance,
      );
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
  // Coverage-ignore(suite): Not run.
  bool visitTypedefType(TypedefType node) {
    return node.unalias.accept(this);
  }

  @override
  bool visitTypeParameterType(TypeParameterType node) {
    return !_variance.greaterThanOrEqual(node.parameter.variance) &&
        _typeParametersToSearchFor.contains(node.parameter);
  }

  @override
  bool visitStructuralParameterType(StructuralParameterType node) {
    return false;
  }

  @override
  // Coverage-ignore(suite): Not run.
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
  /// need to be inferred and redirecting factories whose target needs to be
  /// inferred.
  final Map<Member, InferableMember> toBeInferred = {};

  /// A map containing constructors and redirecting factories in the process of
  /// being inferred.
  ///
  /// This is used to detect cyclic inference dependencies.
  final Map<Member, InferableMember> beingInferred = {};

  // TODO(johnniwinther): Unify [toBeInferred] and [typeDependencies] and
  // ensure that these are called for all member accesses.
  final Map<Member, TypeDependency> typeDependencies = {};

  final Map<DartType, DartType> typeCacheNonNullable =
      new Map<DartType, DartType>.identity();
  final Map<DartType, DartType> typeCacheNullable =
      new Map<DartType, DartType>.identity();
  final Map<DartType, DartType> typeCacheLegacy =
      new Map<DartType, DartType>.identity();

  /// Creates a type inferrer for use inside of a method body declared in a file
  /// with the given [uri].
  TypeInferrer createTypeInferrer({
    required InterfaceType? thisType,
    required SourceLibraryBuilder libraryBuilder,
    required LookupScope extensionScope,
    InferenceDataForTesting? dataForTesting,
  });

  /// Performs the third phase of top level inference, which is to visit all
  /// constructors still needing inference and infer the types of their
  /// initializing formals from the corresponding fields.
  void finishTopLevelInitializingFormals() {
    // Field types have all been inferred so we don't need to guard against
    // cyclic dependency.
    for (InferableMember inferableMember in toBeInferred.values.toList()) {
      inferableMember.inferMemberTypes(hierarchyBuilder);
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
    assert(!isTypeInferencePrepared, "Top level inference already prepared.");
    this.coreTypes = coreTypes;
    this.typeSchemaEnvironment = new TypeSchemaEnvironment(
      coreTypes,
      hierarchy,
    );
    isTypeInferencePrepared = true;
  }

  static Member? resolveInferenceNode(
    Member? member,
    ClassHierarchyBase hierarchy,
  ) {
    // TODO(johnniwinther): Can we remove this now?
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
  Procedure get listAddAll => _listAddAll ??= coreTypes.index.getProcedure(
    'dart:core',
    'List',
    'addAll',
  );

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
  Procedure get mapEntries => _mapEntries ??= coreTypes.index.getProcedure(
    'dart:core',
    'Map',
    'get:entries',
  );

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
  Field get mapEntryValue => _mapEntryValue ??= coreTypes.index.getField(
    'dart:core',
    'MapEntry',
    'value',
  );

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

  TypeInferenceEngineImpl({this.benchmarker});

  @override
  TypeInferrer createTypeInferrer({
    required InterfaceType? thisType,
    required SourceLibraryBuilder libraryBuilder,
    required LookupScope extensionScope,
    InferenceDataForTesting? dataForTesting,
  }) {
    AssignedVariables<TreeNode, VariableDeclaration> assignedVariables;
    if (dataForTesting != null) {
      // Coverage-ignore-block(suite): Not run.
      assignedVariables = dataForTesting.flowAnalysisResult.assignedVariables =
          new AssignedVariablesForTesting<TreeNode, VariableDeclaration>();
    } else {
      assignedVariables =
          new AssignedVariables<TreeNode, VariableDeclaration>();
    }
    if (benchmarker == null) {
      return new TypeInferrerImpl(
        this,
        thisType,
        libraryBuilder,
        extensionScope,
        assignedVariables,
        dataForTesting,
      );
    }
    // Coverage-ignore(suite): Not run.
    return new TypeInferrerImplBenchmarked(
      this,
      thisType,
      libraryBuilder,
      extensionScope,
      assignedVariables,
      dataForTesting,
      benchmarker!,
    );
  }
}

// TODO(cstefantsova): Merge with [TypeInferenceResultForTesting].
class InferenceDataForTesting
    extends
        shared.TypeConstraintGenerationDataForTesting<
          VariableDeclaration,
          TreeNode
        > {
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

/// CFE-specific implementation of [FlowAnalysisOperations].
class OperationsCfe
    with
        TypeAnalyzerOperationsMixin<
          VariableDeclaration,
          TypeDeclarationType,
          TypeDeclaration,
          TreeNode
        >
    implements
        TypeAnalyzerOperations<
          VariableDeclaration,
          TypeDeclarationType,
          TypeDeclaration,
          TreeNode
        > {
  final TypeEnvironment typeEnvironment;

  /// Information about which fields are promotable in this library.
  ///
  /// If field promotion is disabled for the current library, this field is
  /// still populated, so that [whyPropertyIsNotPromotable] can figure out
  /// whether enabling field promotion would cause a field to be promotable.
  ///
  /// The value is `null` if the current source library builder is for an
  /// augmentation library (augmentation libraries don't support field
  /// promotion).
  final FieldNonPromotabilityInfo? fieldNonPromotabilityInfo;

  final Map<DartType, DartType> typeCacheNonNullable;
  final Map<DartType, DartType> typeCacheNullable;
  final Map<DartType, DartType> typeCacheLegacy;

  OperationsCfe(
    this.typeEnvironment, {
    required this.fieldNonPromotabilityInfo,
    required this.typeCacheNonNullable,
    required this.typeCacheNullable,
    required this.typeCacheLegacy,
  });

  @override
  SharedTypeView get boolType {
    return new SharedTypeView(
      typeEnvironment.coreTypes.boolRawType(Nullability.nonNullable),
    );
  }

  @override
  SharedTypeView get doubleType {
    throw new UnimplementedError('TODO(paulberry)');
  }

  @override
  SharedTypeView get dynamicType {
    return new SharedTypeView(const DynamicType());
  }

  @override
  SharedTypeView get errorType {
    return new SharedTypeView(const InvalidType());
  }

  @override
  SharedTypeView get intType {
    throw new UnimplementedError('TODO(paulberry)');
  }

  @override
  SharedTypeView get neverType {
    return new SharedTypeView(const NeverType.nonNullable());
  }

  @override
  SharedTypeView get nullType {
    return new SharedTypeView(const NullType());
  }

  @override
  SharedTypeView get objectQuestionType {
    return new SharedTypeView(typeEnvironment.coreTypes.objectNullableRawType);
  }

  @override
  SharedTypeView get objectType {
    return new SharedTypeView(
      typeEnvironment.coreTypes.objectNonNullableRawType,
    );
  }

  @override
  SharedTypeSchemaView get unknownType {
    return new SharedTypeSchemaView(const UnknownType());
  }

  @override
  TypeClassification classifyType(SharedTypeView? type) {
    DartType? unwrapped = type?.unwrapTypeView();
    if (unwrapped == null) {
      // Note: this can happen during top-level inference.
      return TypeClassification.potentiallyNullable;
    } else if (isSubtypeOfInternal(
      unwrapped,
      typeEnvironment.coreTypes.objectNonNullableRawType,
    )) {
      return TypeClassification.nonNullable;
    } else if (isSubtypeOfInternal(unwrapped, const NullType())) {
      return TypeClassification.nullOrEquivalent;
    } else {
      return TypeClassification.potentiallyNullable;
    }
  }

  @override
  SharedTypeView factor(SharedTypeView from, SharedTypeView what) {
    return new SharedTypeView(
      factorType(typeEnvironment, from.unwrapTypeView(), what.unwrapTypeView()),
    );
  }

  @override
  bool isAlwaysExhaustiveType(SharedTypeView type) {
    return computeIsAlwaysExhaustiveType(
      type.unwrapTypeView(),
      typeEnvironment.coreTypes,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool isExtensionTypeInternal(DartType type) => type is ExtensionType;

  @override
  bool isFinal(VariableDeclaration variable) {
    return variable.isFinal;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool isInterfaceTypeInternal(DartType type) {
    return type is InterfaceType;
  }

  @override
  bool isBottomType(SharedTypeView type) {
    return typeEnvironment.coreTypes.isBottom(type.unwrapTypeView());
  }

  @override
  bool isInvalidType(SharedTypeView type) {
    return type.unwrapTypeView<DartType>() is InvalidType;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool isObject(SharedTypeView type) {
    DartType unwrappedType = type.unwrapTypeView();
    return unwrappedType is InterfaceType &&
        unwrappedType.classNode == typeEnvironment.objectClass &&
        unwrappedType.nullability == Nullability.nonNullable;
  }

  @override
  bool isPropertyPromotable(covariant Member property) {
    FieldNonPromotabilityInfo? fieldNonPromotabilityInfo =
        this.fieldNonPromotabilityInfo;
    if (fieldNonPromotabilityInfo == null) {
      // This only happens when compiling augmentation libraries. Augmentation
      // libraries don't support field promotion.
      return false;
    }
    if (property is Procedure) {
      if (property.stubKind == ProcedureStubKind.RepresentationField) {
        // Representation fields are promotable if they're non-public.
        return property.name.isPrivate;
      }
      if (!property.isAccessor) {
        // We don't promote methods.
        return false;
      }
    }
    String name = property.name.text;
    if (!name.startsWith('_')) return false;
    return fieldNonPromotabilityInfo.fieldNameInfo[name] == null;
  }

  @override
  PropertyNonPromotabilityReason? whyPropertyIsNotPromotable(
    covariant Member property,
  ) {
    FieldNonPromotabilityInfo? fieldNonPromotabilityInfo =
        this.fieldNonPromotabilityInfo;
    if (fieldNonPromotabilityInfo == null) {
      // This only happens when compiling augmentation libraries. Augmentation
      // libraries don't support field promotion.
      return null;
    }
    return fieldNonPromotabilityInfo.individualPropertyReasons[property];
  }

  @override
  bool isSubtypeOfInternal(DartType leftType, DartType rightType) {
    return typeEnvironment.isSubtypeOf(leftType, rightType);
  }

  @override
  SharedTypeView promoteToNonNull(SharedTypeView type) {
    DartType unwrappedType = type.unwrapTypeView();
    if (unwrappedType.nullability == Nullability.nonNullable) {
      return type;
    }
    DartType? cached = typeCacheNonNullable[unwrappedType];
    if (cached != null) {
      return new SharedTypeView(cached);
    }
    DartType result = unwrappedType.toNonNull();
    typeCacheNonNullable[unwrappedType] = result;
    return new SharedTypeView(result);
  }

  @override
  SharedTypeView variableType(covariant VariableDeclarationImpl variable) {
    // When late variables get lowered, their type is changed, but the
    // original type is stored in `VariableDeclarationImpl.lateType`, so we
    // use that if it exists.
    return new SharedTypeView(variable.lateType ?? variable.type);
  }

  @override
  bool isTypeParameterType(SharedTypeView type) {
    return type.unwrapTypeView<DartType>() is TypeParameterType ||
        type.unwrapTypeView<DartType>() is IntersectionType;
  }

  @override
  SharedTypeView tryPromoteToType(SharedTypeView to, SharedTypeView from) {
    DartType unwrappedTo = to.unwrapTypeView();
    DartType unwrappedFrom = from.unwrapTypeView();
    if (isSubtypeOfInternal(unwrappedTo, unwrappedFrom)) {
      return to;
    }
    if (unwrappedFrom is TypeParameterType) {
      if (isSubtypeOfInternal(unwrappedTo, unwrappedFrom.bound)) {
        if (to.unwrapTypeView<DartType>().nullability != Nullability.nullable) {
          // We treat promotions of the form `x is T`, where `T` is not
          // nullable, as a two-step promotions equivalent to
          // `x != null && x is T`.
          return new SharedTypeView(
            new IntersectionType(
              unwrappedFrom.withDeclaredNullability(
                unwrappedFrom.parameter.computeNullabilityFromBound(),
              ),
              unwrappedTo,
            ),
          );
        } else {
          return new SharedTypeView(
            new IntersectionType(unwrappedFrom, unwrappedTo),
          );
        }
      }
    }
    if (unwrappedFrom is IntersectionType) {
      if (isSubtypeOfInternal(unwrappedTo, unwrappedFrom.right)) {
        return new SharedTypeView(
          new IntersectionType(unwrappedFrom.left, unwrappedTo),
        );
      }
    }
    return new SharedTypeView(unwrappedFrom);
  }

  @override
  DartType glbInternal(DartType type1, DartType type2) {
    return typeEnvironment.getStandardLowerBound(type1, type2);
  }

  @override
  bool isAssignableTo(SharedTypeView fromType, SharedTypeView toType) {
    if (fromType is DynamicType) return true;
    return typeEnvironment
        .performSubtypeCheck(fromType.unwrapTypeView(), toType.unwrapTypeView())
        .isSuccess();
  }

  @override
  DartType? matchFutureOrInternal(DartType type) {
    if (type is! FutureOrType) {
      return null;
    } else {
      return type.typeArgument;
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool isTypeSchemaSatisfied({
    required SharedTypeSchemaView typeSchema,
    required SharedTypeView type,
  }) {
    return isSubtypeOfInternal(
      type.unwrapTypeView(),
      typeSchema.unwrapTypeSchemaView(),
    );
  }

  @override
  bool isVariableFinal(VariableDeclaration node) {
    return node.isFinal;
  }

  @override
  SharedTypeSchemaView iterableTypeSchema(
    SharedTypeSchemaView elementTypeSchema,
  ) {
    return new SharedTypeSchemaView(
      new InterfaceType(
        typeEnvironment.coreTypes.iterableClass,
        Nullability.nonNullable,
        <DartType>[elementTypeSchema.unwrapTypeSchemaView()],
      ),
    );
  }

  @override
  DartType listTypeInternal(DartType elementType) {
    return new InterfaceType(
      typeEnvironment.coreTypes.listClass,
      Nullability.nonNullable,
      <DartType>[elementType],
    );
  }

  @override
  DartType lubInternal(DartType type1, DartType type2) {
    return typeEnvironment.getStandardUpperBound(type1, type2);
  }

  @override
  DartType makeNullableInternal(DartType type) {
    if (type is NullType || type is NeverType) {
      return const NullType();
    }
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

  @override
  DartType mapTypeInternal({
    required DartType keyType,
    required DartType valueType,
  }) {
    return new InterfaceType(
      typeEnvironment.coreTypes.mapClass,
      Nullability.nonNullable,
      <DartType>[keyType, valueType],
    );
  }

  @override
  SharedTypeView? matchListType(SharedTypeView type) {
    DartType unwrappedType = type.unwrapTypeView();
    if (unwrappedType is TypeDeclarationType) {
      List<DartType>? typeArguments = typeEnvironment
          .getTypeArgumentsAsInstanceOf(
            unwrappedType,
            typeEnvironment.coreTypes.listClass,
          );
      if (typeArguments == null || typeArguments.length != 1) {
        return null;
      } else {
        return new SharedTypeView(typeArguments.single);
      }
    } else {
      return null;
    }
  }

  @override
  ({SharedTypeView keyType, SharedTypeView valueType})? matchMapType(
    SharedTypeView type,
  ) {
    DartType unwrappedType = type.unwrapTypeView();
    if (unwrappedType is! TypeDeclarationType) {
      return null;
    } else {
      TypeDeclarationType? mapType = typeEnvironment.getTypeAsInstanceOf(
        unwrappedType,
        typeEnvironment.coreTypes.mapClass,
        typeEnvironment.coreTypes,
      );
      if (mapType == null) {
        return null;
      } else {
        return (
          keyType: new SharedTypeView(mapType.typeArguments[0]),
          valueType: new SharedTypeView(mapType.typeArguments[1]),
        );
      }
    }
  }

  @override
  SharedTypeView? matchStreamType(SharedTypeView type) {
    DartType unwrappedType = type.unwrapTypeView();
    if (unwrappedType is TypeDeclarationType) {
      List<DartType>? typeArguments = typeEnvironment
          .getTypeArgumentsAsInstanceOf(
            unwrappedType,
            typeEnvironment.coreTypes.streamClass,
          );
      if (typeArguments == null || typeArguments.length != 1) {
        return null;
      } else {
        return new SharedTypeView(typeArguments.single);
      }
    } else {
      return null;
    }
  }

  @override
  SharedTypeView normalize(SharedTypeView type) {
    return new SharedTypeView(
      norm(typeEnvironment.coreTypes, type.unwrapTypeView()),
    );
  }

  @override
  DartType? matchIterableTypeInternal(DartType type) {
    if (type is! TypeDeclarationType) {
      return null;
    } else {
      TypeDeclarationType? interfaceType = typeEnvironment.getTypeAsInstanceOf(
        type,
        typeEnvironment.coreTypes.iterableClass,
        typeEnvironment.coreTypes,
      );
      if (interfaceType == null) {
        return null;
      } else {
        return interfaceType.typeArguments.single;
      }
    }
  }

  @override
  DartType recordTypeInternal({
    required List<SharedType> positional,
    required List<(String, SharedType)> named,
  }) {
    List<NamedType> namedFields = [];
    for (var (name, type) in named) {
      namedFields.add(new NamedType(name, type as DartType));
    }
    namedFields.sort((f1, f2) => f1.name.compareTo(f2.name));
    return new RecordType(
      positional.cast<DartType>(),
      namedFields,
      Nullability.nonNullable,
    );
  }

  @override
  SharedTypeSchemaView streamTypeSchema(
    SharedTypeSchemaView elementTypeSchema,
  ) {
    return new SharedTypeSchemaView(
      new InterfaceType(
        typeEnvironment.coreTypes.streamClass,
        Nullability.nonNullable,
        <DartType>[elementTypeSchema.unwrapTypeSchemaView()],
      ),
    );
  }

  @override
  SharedTypeView extensionTypeErasure(SharedTypeView type) {
    return new SharedTypeView(
      type.unwrapTypeView<DartType>().extensionTypeErasure,
    );
  }

  @override
  SharedTypeSchemaView typeToSchema(SharedTypeView type) {
    return new SharedTypeSchemaView(type.unwrapTypeView());
  }

  @override
  // Coverage-ignore(suite): Not run.
  TypeDeclarationKind? getTypeDeclarationKindInternal(DartType type) {
    if (type is TypeDeclarationType) {
      switch (type) {
        case InterfaceType():
          return TypeDeclarationKind.interfaceDeclaration;
        case ExtensionType():
          return TypeDeclarationKind.extensionTypeDeclaration;
      }
    } else {
      return null;
    }
  }

  @override
  StructuralParameter? matchInferableParameterInternal(DartType type) {
    if (type is StructuralParameterType) {
      return type.parameter;
    } else {
      return null;
    }
  }

  @override
  InterfaceType futureTypeInternal(DartType argumentType) {
    return new InterfaceType(
      typeEnvironment.coreTypes.futureClass,
      Nullability.nonNullable,
      <DartType>[argumentType],
    );
  }

  @override
  TypeDeclarationMatchResult<TypeDeclarationType, TypeDeclaration>?
  matchTypeDeclarationTypeInternal(DartType type) {
    if (type is TypeDeclarationType) {
      switch (type) {
        case InterfaceType(:List<DartType> typeArguments, :Class classNode):
          return new TypeDeclarationMatchResult(
            typeDeclarationKind: TypeDeclarationKind.interfaceDeclaration,
            typeDeclaration: classNode,
            typeDeclarationType: type,
            typeArguments: typeArguments,
          );
        case ExtensionType(
          :List<DartType> typeArguments,
          :ExtensionTypeDeclaration extensionTypeDeclaration,
        ):
          return new TypeDeclarationMatchResult(
            typeDeclarationKind: TypeDeclarationKind.extensionTypeDeclaration,
            typeDeclaration: extensionTypeDeclaration,
            typeDeclarationType: type,
            typeArguments: typeArguments,
          );
      }
    } else {
      return null;
    }
  }

  @override
  Variance getTypeParameterVariance(
    TypeDeclaration typeDeclaration,
    int parameterIndex,
  ) {
    return typeDeclaration.typeParameters[parameterIndex].variance;
  }

  @override
  bool isDartCoreFunctionInternal(DartType type) {
    return type == typeEnvironment.coreTypes.functionNonNullableRawType;
  }

  @override
  bool isDartCoreRecordInternal(DartType type) {
    return type == typeEnvironment.coreTypes.recordNonNullableRawType;
  }

  @override
  DartType greatestClosureOfTypeInternal(
    DartType type,
    List<SharedTypeParameter> typeParametersToEliminate,
  ) {
    return new FreeTypeParameterEliminator(
      coreTypes: typeEnvironment.coreTypes,
    ).eliminateToGreatest(type);
  }

  @override
  DartType leastClosureOfTypeInternal(
    DartType type,
    List<SharedTypeParameter> typeParametersToEliminate,
  ) {
    return new FreeTypeParameterEliminator(
      coreTypes: typeEnvironment.coreTypes,
    ).eliminateToLeast(type);
  }

  @override
  DartType? matchTypeParameterBoundInternal(DartType type) {
    if (type.isQuestionType) {
      return null;
    }
    if (type is TypeParameterType) {
      return type.parameter.bound;
    } else if (type is StructuralParameterType) {
      // Coverage-ignore-block(suite): Not run.
      return type.parameter.bound;
    } else if (type is IntersectionType) {
      return type.right;
    } else {
      return null;
    }
  }

  @override
  bool isNonNullableInternal(DartType type) {
    return type.nullability == Nullability.nonNullable;
  }

  @override
  bool isNullableInternal(DartType type) {
    return type.nullability == Nullability.nullable;
  }

  @override
  TypeConstraintGenerator<
    VariableDeclaration,
    TypeDeclarationType,
    TypeDeclaration,
    TreeNode
  >
  createTypeConstraintGenerator({
    required covariant TypeInferenceResultForTesting?
    typeConstraintGenerationDataForTesting,
    required List<SharedTypeParameterView> typeParametersToInfer,
    required covariant OperationsCfe typeAnalyzerOperations,
    required bool inferenceUsingBoundsIsEnabled,
  }) {
    // TODO(cstefantsova): Pass [typeConstraintGenerationDataForTesting] when
    // [InferenceDataForTesting] is merged with [TypeInferenceResultForTesting].
    return new TypeConstraintGatherer(
      typeAnalyzerOperations.typeEnvironment as TypeSchemaEnvironment,
      typeParametersToInfer.cast<StructuralParameter>(),
      typeOperations: typeAnalyzerOperations,
      inferenceResultForTesting: null,
      inferenceUsingBoundsIsEnabled: inferenceUsingBoundsIsEnabled,
    );
  }

  @override
  bool isKnownType(SharedTypeSchemaView typeSchema) {
    return isKnown(typeSchema.unwrapTypeSchemaView());
  }

  @override
  SharedTypeView greatestClosureOfSchema(
    SharedTypeSchemaView schema, {
    SharedTypeView? topType,
  }) {
    return new SharedTypeView(
      type_schema_elimination.greatestClosure(
        schema.unwrapTypeSchemaView(),
        topType:
            topType?.unwrapTypeView() ??
            typeEnvironment.coreTypes.objectNullableRawType,
      ),
    );
  }

  @override
  SharedTypeView leastClosureOfSchema(SharedTypeSchemaView schema) {
    return new SharedTypeView(
      type_schema_elimination.leastClosure(
        schema.unwrapTypeSchemaView(),
        coreTypes: typeEnvironment.coreTypes,
      ),
    );
  }

  @override
  bool isBoundOmitted(covariant StructuralParameter structuralParameter) {
    // If the bound was omitted by the programmer, the Kernel representation for
    // the parameter will look similar to the following:
    //
    //     T extends Object = dynamic
    //
    // Note that it's not possible to receive [Object] as [TypeParameter.bound]
    // and `dynamic` as [TypeParameter.defaultType] from the front end in any
    // other way.
    DartType bound = structuralParameter.bound;
    return bound is InterfaceType &&
        identical(
          bound.classReference,
          typeEnvironment.coreTypes.objectClass.reference,
        ) &&
        structuralParameter.defaultType is DynamicType;
  }

  @override
  DartType substituteTypeFromIterables(
    covariant DartType typeToSubstitute,
    List<SharedTypeParameter> typeParameters,
    List<SharedType> types,
  ) {
    return new FunctionTypeInstantiator.fromIterables(
      typeParameters.cast(),
      types.cast(),
    ).substitute(typeToSubstitute);
  }
}

/// Type inference results used for testing.
class TypeInferenceResultForTesting
    extends
        shared.TypeConstraintGenerationDataForTesting<
          VariableDeclaration,
          TreeNode
        > {
  final Map<TreeNode, List<DartType>> inferredTypeArguments = {};
  final Map<TreeNode, DartType> inferredVariableTypes = {};
}

abstract class InferableMember {
  Member get member;

  void inferMemberTypes(ClassHierarchyBase classHierarchy);

  void reportCyclicDependency();
}
