// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/src/replacement_visitor.dart';

import '../ast.dart';

import '../type_algebra.dart' show Substitution, substitute;

import '../type_environment.dart' show SubtypeCheckMode, TypeEnvironment;

import '../util/graph.dart' show Graph, computeStrongComponents;

import 'legacy_erasure.dart';

class TypeVariableGraph extends Graph<int> {
  @override
  late List<int> vertices;
  List<TypeParameter> typeParameters;
  List<DartType> bounds;

  // `edges[i]` is the list of indices of type variables that reference the type
  // variable with the index `i` in their bounds.
  late List<List<int>> edges;

  TypeVariableGraph(this.typeParameters, this.bounds) {
    assert(typeParameters.length == bounds.length);

    vertices = new List<int>.filled(
        typeParameters.length,
        // Dummy value.
        -1);
    Map<TypeParameter, int> typeParameterIndices = <TypeParameter, int>{};
    edges = new List<List<int>>.filled(
        typeParameters.length,
        // Dummy value.
        const []);
    for (int i = 0; i < vertices.length; i++) {
      vertices[i] = i;
      typeParameterIndices[typeParameters[i]] = i;
      edges[i] = <int>[];
    }

    for (int i = 0; i < vertices.length; i++) {
      OccurrenceCollectorVisitor collector =
          new OccurrenceCollectorVisitor(typeParameters.toSet());
      collector.visit(bounds[i]);
      for (TypeParameter typeParameter in collector.occurred) {
        edges[typeParameterIndices[typeParameter]!].add(i);
      }
    }
  }

  @override
  Iterable<int> neighborsOf(int index) {
    return edges[index];
  }
}

class OccurrenceCollectorVisitor implements DartTypeVisitor<void> {
  final Set<TypeParameter> typeParameters;
  Set<TypeParameter> occurred = new Set<TypeParameter>();

  OccurrenceCollectorVisitor(this.typeParameters);

  void visit(DartType node) => node.accept(this);

  void visitNamedType(NamedType node) {
    node.type.accept(this);
  }

  @override
  void visitInvalidType(InvalidType node) {}

  @override
  void visitDynamicType(DynamicType node) {}

  @override
  void visitVoidType(VoidType node) {}

  @override
  void visitExtensionType(ExtensionType node) {
    for (DartType argument in node.typeArguments) {
      argument.accept(this);
    }
  }

  @override
  void visitFutureOrType(FutureOrType node) {
    node.typeArgument.accept(this);
  }

  @override
  void visitIntersectionType(IntersectionType node) {
    node.left.accept(this);
    node.right.accept(this);
  }

  @override
  void visitNeverType(NeverType node) {}

  @override
  void visitNullType(NullType node) {}

  @override
  void visitInterfaceType(InterfaceType node) {
    for (DartType argument in node.typeArguments) {
      argument.accept(this);
    }
  }

  @override
  void visitRecordType(RecordType node) {
    for (DartType positional in node.positional) {
      positional.accept(this);
    }
    for (NamedType named in node.named) {
      named.type.accept(this);
    }
  }

  @override
  void visitTypedefType(TypedefType node) {
    for (DartType argument in node.typeArguments) {
      argument.accept(this);
    }
  }

  @override
  void visitFunctionType(FunctionType node) {
    for (TypeParameter typeParameter in node.typeParameters) {
      typeParameter.bound.accept(this);
      typeParameter.defaultType.accept(this);
    }
    for (DartType parameter in node.positionalParameters) {
      parameter.accept(this);
    }
    for (NamedType namedParameter in node.namedParameters) {
      namedParameter.type.accept(this);
    }
    node.returnType.accept(this);
  }

  @override
  void visitTypeParameterType(TypeParameterType node) {
    if (typeParameters.contains(node.parameter)) {
      occurred.add(node.parameter);
    }
  }

  @override
  void defaultDartType(DartType node) {}
}

DartType instantiateToBounds(DartType type, Class objectClass,
    {required bool isNonNullableByDefault}) {
  if (type is InterfaceType) {
    if (type.typeArguments.isEmpty) return type;
    for (DartType typeArgument in type.typeArguments) {
      // If at least one of the arguments is not dynamic, we assume that the
      // type is not raw and does not need instantiation of its type parameters
      // to their bounds.
      if (typeArgument is! DynamicType) {
        return type;
      }
    }
    return new InterfaceType.byReference(
        type.classReference,
        type.nullability,
        calculateBounds(type.classNode.typeParameters, objectClass,
            isNonNullableByDefault: isNonNullableByDefault));
  }
  if (type is TypedefType) {
    if (type.typeArguments.isEmpty) return type;
    for (DartType typeArgument in type.typeArguments) {
      if (typeArgument is! DynamicType) {
        return type;
      }
    }
    return new TypedefType.byReference(
        type.typedefReference,
        type.nullability,
        calculateBounds(type.typedefNode.typeParameters, objectClass,
            isNonNullableByDefault: isNonNullableByDefault));
  }
  return type;
}

/// Calculates bounds to be provided as type arguments in place of missing type
/// arguments on raw types with the given type parameters.
///
/// See the [description]
/// (https://github.com/dart-lang/sdk/blob/master/docs/language/informal/instantiate-to-bound.md)
/// of the algorithm for details.
List<DartType> calculateBounds(
    List<TypeParameter> typeParameters, Class objectClass,
    {required bool isNonNullableByDefault}) {
  return calculateBoundsInternal(typeParameters, objectClass,
      isNonNullableByDefault: isNonNullableByDefault);
}

List<DartType> calculateBoundsInternal(
    List<TypeParameter> typeParameters, Class objectClass,
    {required bool isNonNullableByDefault}) {
  List<DartType> bounds =
      new List<DartType>.filled(typeParameters.length, dummyDartType);
  for (int i = 0; i < typeParameters.length; i++) {
    DartType bound = typeParameters[i].bound;
    bool isContravariant = typeParameters[i].variance == Variance.contravariant;
    if (identical(bound, TypeParameter.unsetBoundSentinel)) {
      bound = isNonNullableByDefault && isContravariant
          ? const NeverType.nonNullable()
          : const DynamicType();
    } else if (bound is InterfaceType &&
        bound.classReference == objectClass.reference) {
      DartType defaultType = typeParameters[i].defaultType;
      if (!(defaultType is InterfaceType &&
          defaultType.classNode == objectClass)) {
        bound = isNonNullableByDefault && isContravariant
            ? const NeverType.nonNullable()
            : const DynamicType();
      }
    }
    bounds[i] = bound;
  }

  TypeVariableGraph graph = new TypeVariableGraph(typeParameters, bounds);
  List<List<int>> stronglyConnected = computeStrongComponents(graph);
  final DartType topType = const DynamicType();
  final DartType bottomType = isNonNullableByDefault
      ? const NeverType.nonNullable()
      : const NeverType.legacy();
  for (List<int> component in stronglyConnected) {
    Map<TypeParameter, DartType> upperBounds = <TypeParameter, DartType>{};
    Map<TypeParameter, DartType> lowerBounds = <TypeParameter, DartType>{};
    for (int typeParameterIndex in component) {
      upperBounds[typeParameters[typeParameterIndex]] = topType;
      lowerBounds[typeParameters[typeParameterIndex]] = bottomType;
    }
    Substitution substitution =
        Substitution.fromUpperAndLowerBounds(upperBounds, lowerBounds);
    for (int typeParameterIndex in component) {
      bounds[typeParameterIndex] = substitution.substituteType(
          bounds[typeParameterIndex],
          contravariant: typeParameters[typeParameterIndex].variance ==
              Variance.contravariant);
    }
  }

  for (int i = 0; i < typeParameters.length; i++) {
    Map<TypeParameter, DartType> upperBounds = <TypeParameter, DartType>{};
    Map<TypeParameter, DartType> lowerBounds = <TypeParameter, DartType>{};
    upperBounds[typeParameters[i]] = bounds[i];
    lowerBounds[typeParameters[i]] = bottomType;
    Substitution substitution =
        Substitution.fromUpperAndLowerBounds(upperBounds, lowerBounds);
    for (int j = 0; j < typeParameters.length; j++) {
      bounds[j] = substitution.substituteType(bounds[j],
          contravariant: typeParameters[j].variance == Variance.contravariant);
    }
  }

  return bounds;
}

class TypeArgumentIssue {
  /// The index for type argument within the passed type arguments.
  final int index;

  /// The type argument that violated the bound.
  final DartType argument;

  /// The type parameter with the bound that was violated.
  final TypeParameter typeParameter;

  /// The enclosing type of the issue, that is, the one with [typeParameter].
  final DartType? enclosingType;

  /// The type computed from [enclosingType] for the super-boundness check.
  ///
  /// This field can be null.  [invertedType] is supposed to enhance error
  /// messages, providing the auxiliary type for super-boundness checks for the
  /// user.  It is set to null if it's not helpful, for example, if
  /// [enclosingType] is well-bounded or is strictly required to be
  /// regular-bounded, so the super-boundness check is skipped.  It is set to
  /// null also if the inversion didn't change the type at all, and it's not
  /// helpful to show the same type to the user.
  DartType? invertedType;

  final bool isGenericTypeAsArgumentIssue;

  TypeArgumentIssue(
      this.index, this.argument, this.typeParameter, this.enclosingType,
      {this.invertedType, this.isGenericTypeAsArgumentIssue = false});

  @override
  int get hashCode {
    int hash = 0x3fffffff & index;
    hash = 0x3fffffff & (hash * 31 + (hash ^ argument.hashCode));
    hash = 0x3fffffff & (hash * 31 + (hash ^ typeParameter.hashCode));
    hash = 0x3fffffff & (hash * 31 + (hash ^ enclosingType.hashCode));
    return hash;
  }

  @override
  bool operator ==(Object other) {
    assert(other is TypeArgumentIssue);
    return other is TypeArgumentIssue &&
        index == other.index &&
        argument == other.argument &&
        typeParameter == other.typeParameter &&
        enclosingType == other.enclosingType;
  }

  @override
  String toString() {
    return "TypeArgumentIssue(index=${index}, argument=${argument}, "
        "typeParameter=${typeParameter}, enclosingType=${enclosingType}";
  }
}

// Finds type arguments that don't follow the rules of well-boundedness.
//
// [bottomType] should be either Null or Never, depending on what should be
// taken for the bottom type at the call site.  The bottom type is used in the
// checks for super-boundedness for construction of the auxiliary type.  For
// details see Dart Language Specification, Section 14.3.2 The Instantiation to
// Bound Algorithm.
List<TypeArgumentIssue> findTypeArgumentIssues(DartType type,
    TypeEnvironment typeEnvironment, SubtypeCheckMode subtypeCheckMode,
    {required bool allowSuperBounded,
    required bool isNonNullableByDefault,
    required bool areGenericArgumentsAllowed}) {
  List<TypeParameter> variables = const <TypeParameter>[];
  List<DartType> arguments = const <DartType>[];
  List<TypeArgumentIssue> typedefRhsResult = const <TypeArgumentIssue>[];

  if (type is InterfaceType) {
    variables = type.classNode.typeParameters;
    arguments = type.typeArguments;
  } else if (type is TypedefType) {
    variables = type.typedefNode.typeParameters;
    arguments = type.typeArguments;
  } else if (type is ExtensionType) {
    variables = type.extensionTypeDeclaration.typeParameters;
    arguments = type.typeArguments;
    // Extension types are never allowed to be super-bounded.
    allowSuperBounded = false;
  } else if (type is FunctionType) {
    List<TypeArgumentIssue> result = <TypeArgumentIssue>[];

    for (DartType formal in type.positionalParameters) {
      result.addAll(findTypeArgumentIssues(
          formal, typeEnvironment, subtypeCheckMode,
          allowSuperBounded: true,
          isNonNullableByDefault: isNonNullableByDefault,
          areGenericArgumentsAllowed: areGenericArgumentsAllowed));
    }

    for (NamedType named in type.namedParameters) {
      result.addAll(findTypeArgumentIssues(
          named.type, typeEnvironment, subtypeCheckMode,
          allowSuperBounded: true,
          isNonNullableByDefault: isNonNullableByDefault,
          areGenericArgumentsAllowed: areGenericArgumentsAllowed));
    }

    result.addAll(findTypeArgumentIssues(
        type.returnType, typeEnvironment, subtypeCheckMode,
        allowSuperBounded: true,
        isNonNullableByDefault: isNonNullableByDefault,
        areGenericArgumentsAllowed: areGenericArgumentsAllowed));

    return result;
  } else if (type is FutureOrType) {
    variables = typeEnvironment.coreTypes.futureClass.typeParameters;
    arguments = <DartType>[type.typeArgument];
  } else {
    assert(type is DynamicType ||
        type is VoidType ||
        type is IntersectionType ||
        type is TypeParameterType ||
        type is NeverType ||
        type is NullType);
    return const <TypeArgumentIssue>[];
  }

  if (variables.isEmpty) {
    return typedefRhsResult.isNotEmpty
        ? typedefRhsResult
        : const <TypeArgumentIssue>[];
  }

  List<TypeArgumentIssue> result = <TypeArgumentIssue>[];
  List<TypeArgumentIssue> argumentsResult = <TypeArgumentIssue>[];

  Map<TypeParameter, DartType> substitutionMap =
      new Map<TypeParameter, DartType>.fromIterables(variables, arguments);
  for (int i = 0; i < arguments.length; ++i) {
    DartType argument = arguments[i];
    if (!areGenericArgumentsAllowed && isGenericFunctionTypeOrAlias(argument)) {
      // Generic function types aren't allowed as type arguments either.
      result.add(new TypeArgumentIssue(i, argument, variables[i], type,
          isGenericTypeAsArgumentIssue: true));
    } else if (variables[i].bound is! InvalidType) {
      DartType bound = substitute(variables[i].bound, substitutionMap);
      if (!isNonNullableByDefault) {
        bound = legacyErasure(bound);
      }
      if (!typeEnvironment.isSubtypeOf(argument, bound, subtypeCheckMode)) {
        result.add(new TypeArgumentIssue(i, argument, variables[i], type));
      }
    } else {
      // The bound is InvalidType so it's not checked, because an error was
      // reported already at the time of the creation of InvalidType.
    }
  }
  result.addAll(argumentsResult);
  result.addAll(typedefRhsResult);

  // [type] is regular-bounded.
  if (result.isEmpty) return const <TypeArgumentIssue>[];
  if (!allowSuperBounded) return result;

  bool isCorrectSuperBounded = true;
  DartType? invertedType = convertSuperBoundedToRegularBounded(
      typeEnvironment, type,
      isNonNullableByDefault: isNonNullableByDefault);

  // The auxiliary type is the same as [type].  At this point we know that
  // [type] is not regular-bounded, which means that the inverted type is also
  // not regular-bounded.  These two judgments together allow us to conclude
  // that [type] is not well-bounded.
  if (invertedType == null) return result;

  if (invertedType is InterfaceType) {
    variables = invertedType.classNode.typeParameters;
    arguments = invertedType.typeArguments;
  } else if (invertedType is TypedefType) {
    variables = invertedType.typedefNode.typeParameters;
    arguments = invertedType.typeArguments;
  } else if (invertedType is FutureOrType) {
    variables = typeEnvironment.coreTypes.futureClass.typeParameters;
    arguments = <DartType>[invertedType.typeArgument];
  }
  substitutionMap =
      new Map<TypeParameter, DartType>.fromIterables(variables, arguments);
  for (int i = 0; i < arguments.length; ++i) {
    DartType argument = arguments[i];
    // TODO(johnniwinther): Should we check this even when generic functions
    // as type arguments is allowed?
    if (isGenericFunctionTypeOrAlias(argument)) {
      // Generic function types aren't allowed as type arguments either.
      isCorrectSuperBounded = false;
    } else if (!typeEnvironment.isSubtypeOf(argument,
        substitute(variables[i].bound, substitutionMap), subtypeCheckMode)) {
      isCorrectSuperBounded = false;
    }
  }
  if (argumentsResult.isNotEmpty) {
    isCorrectSuperBounded = false;
  }
  if (typedefRhsResult.isNotEmpty) {
    isCorrectSuperBounded = false;
  }

  // The inverted type is regular-bounded, which means that [type] is
  // well-bounded.
  if (isCorrectSuperBounded) return const <TypeArgumentIssue>[];

  // The inverted type isn't regular-bounded, but it's different from [type].
  // In this case we'll provide the programmer with the inverted type as a hint,
  // in case they were going for a super-bounded type and will benefit from that
  // information correcting the program.
  for (TypeArgumentIssue issue in result) {
    issue.invertedType = invertedType;
  }
  return result;
}

// Finds type arguments that don't follow the rules of well-boundness.
//
// [bottomType] should be either Null or Never, depending on what should be
// taken for the bottom type at the call site.  The bottom type is used in the
// checks for super-boundness for construction of the auxiliary type.  For
// details see Dart Language Specification, Section 14.3.2 The Instantiation to
// Bound Algorithm.
List<TypeArgumentIssue> findTypeArgumentIssuesForInvocation(
    List<TypeParameter> parameters,
    List<DartType> arguments,
    TypeEnvironment typeEnvironment,
    SubtypeCheckMode subtypeCheckMode,
    DartType bottomType,
    {required bool isNonNullableByDefault,
    required bool areGenericArgumentsAllowed}) {
  assert(arguments.length == parameters.length);
  assert(bottomType == const NeverType.nonNullable() || bottomType is NullType);

  List<TypeArgumentIssue> result = <TypeArgumentIssue>[];
  Map<TypeParameter, DartType> substitutionMap = <TypeParameter, DartType>{};
  for (int i = 0; i < arguments.length; ++i) {
    substitutionMap[parameters[i]] = arguments[i];
  }
  for (int i = 0; i < arguments.length; ++i) {
    DartType argument = arguments[i];
    if (argument is IntersectionType) {
      // TODO(cstefantsova): Consider recognizing this case with a flag on the
      // issue object.
      result.add(new TypeArgumentIssue(i, argument, parameters[i], null));
    } else if (!areGenericArgumentsAllowed &&
        isGenericFunctionTypeOrAlias(argument)) {
      // Generic function types aren't allowed as type arguments either.
      result.add(new TypeArgumentIssue(i, argument, parameters[i], null,
          isGenericTypeAsArgumentIssue: true));
    } else if (parameters[i].bound is! InvalidType) {
      DartType bound = substitute(parameters[i].bound, substitutionMap);
      if (!isNonNullableByDefault) {
        bound = legacyErasure(bound);
      }
      if (!typeEnvironment.isSubtypeOf(argument, bound, subtypeCheckMode)) {
        result.add(new TypeArgumentIssue(i, argument, parameters[i], null));
      }
    }
  }
  return result;
}

String getGenericTypeName(DartType type) {
  if (type is InterfaceType) {
    return type.classNode.name;
  } else if (type is TypedefType) {
    return type.typedefNode.name;
  }
  return type.toString();
}

/// Replaces all covariant occurrences of `dynamic`, `Object`, and `void` with
/// [BottomType] and all contravariant occurrences of `Null` and [BottomType]
/// with `Object`.  Returns null if the converted type is the same as [type].
DartType? convertSuperBoundedToRegularBounded(
    TypeEnvironment typeEnvironment, DartType type,
    {int variance = Variance.covariant, required bool isNonNullableByDefault}) {
  return type.accept1(
      new _SuperBoundedTypeInverter(typeEnvironment,
          isNonNullableByDefault: isNonNullableByDefault),
      variance);
}

class _SuperBoundedTypeInverter extends ReplacementVisitor {
  final TypeEnvironment typeEnvironment;
  final bool isNonNullableByDefault;
  bool isOutermost = true;

  _SuperBoundedTypeInverter(this.typeEnvironment,
      {required this.isNonNullableByDefault});

  bool flipTop(int variance) {
    return isNonNullableByDefault
        ? variance != Variance.contravariant
        : variance == Variance.covariant;
  }

  bool flipBottom(int variance) {
    return isNonNullableByDefault
        ? variance == Variance.contravariant
        : variance != Variance.covariant;
  }

  DartType get topType {
    return isNonNullableByDefault
        ? typeEnvironment.coreTypes.objectNullableRawType
        : const DynamicType();
  }

  DartType get bottomType {
    return isNonNullableByDefault
        ? const NeverType.nonNullable()
        : const NullType();
  }

  bool isTop(DartType node) {
    if (isNonNullableByDefault) {
      return typeEnvironment.coreTypes.isTop(node);
    } else {
      return node is DynamicType ||
          node is VoidType ||
          node is InterfaceType &&
              node.classNode == typeEnvironment.coreTypes.objectClass;
    }
  }

  bool isBottom(DartType node) {
    if (isNonNullableByDefault) {
      return typeEnvironment.coreTypes.isBottom(node);
    } else {
      return node is NullType;
    }
  }

  @override
  DartType? visitDynamicType(DynamicType node, int variance) {
    // dynamic is always a top type.
    assert(isTop(node));
    if (flipTop(variance)) {
      return bottomType;
    } else {
      return null;
    }
  }

  @override
  DartType? visitVoidType(VoidType node, int variance) {
    // void is always a top type.
    assert(isTop(node));
    if (flipTop(variance)) {
      return bottomType;
    } else {
      return null;
    }
  }

  @override
  DartType? visitInterfaceType(InterfaceType node, int variance) {
    isOutermost = false;
    // Check for Object-based top types.
    if (isTop(node) && flipTop(variance)) {
      return bottomType;
    } else {
      return super.visitInterfaceType(node, variance);
    }
  }

  @override
  DartType? visitRecordType(RecordType node, int variance) {
    isOutermost = false;
    return super.visitRecordType(node, variance);
  }

  @override
  DartType? visitFutureOrType(FutureOrType node, int variance) {
    isOutermost = false;
    // Check FutureOr-based top types.
    if (isTop(node) && flipTop(variance)) {
      return bottomType;
    } else {
      return super.visitFutureOrType(node, variance);
    }
  }

  @override
  DartType? visitNullType(NullType node, int variance) {
    // Null isn't a bottom type in NNBD.
    if (isBottom(node) && flipBottom(variance)) {
      return topType;
    } else {
      return null;
    }
  }

  @override
  DartType? visitNeverType(NeverType node, int variance) {
    // Depending on the variance, Never may not be a bottom type.
    if (isBottom(node) && flipBottom(variance)) {
      return topType;
    } else {
      return null;
    }
  }

  @override
  DartType? visitTypeParameterType(TypeParameterType node, int variance) {
    // Types such as X extends Never are bottom types.
    if (isBottom(node) && flipBottom(variance)) {
      return topType;
    } else {
      return null;
    }
  }

  @override
  DartType? visitIntersectionType(IntersectionType node, int variance) {
    // Types such as X & Never are bottom types.
    if (isBottom(node) && flipBottom(variance)) {
      return topType;
    } else {
      return null;
    }
  }

  // TypedefTypes receive special treatment because the variance of their
  // arguments' positions depend on the opt-in status of the library.
  @override
  DartType? visitTypedefType(TypedefType node, int variance) {
    if (!isNonNullableByDefault && !isOutermost) {
      return node.unalias.accept1(this, variance);
    }
    isOutermost = false;
    Nullability? newNullability = visitNullability(node);
    List<DartType>? newTypeArguments = null;
    for (int i = 0; i < node.typeArguments.length; i++) {
      // The implementation of instantiate-to-bound in legacy mode ignored the
      // variance of type parameters of the typedef.  This behavior is preserved
      // here in passing the 'variance' parameter unchanged in for legacy
      // libraries.
      DartType? newTypeArgument = node.typeArguments[i].accept1(
          this,
          isNonNullableByDefault
              ? Variance.combine(
                  variance, node.typedefNode.typeParameters[i].variance)
              : variance);
      if (newTypeArgument != null) {
        newTypeArguments ??= new List<DartType>.of(node.typeArguments);
        newTypeArguments[i] = newTypeArgument;
      }
    }
    return createTypedef(node, newNullability, newTypeArguments);
  }

  @override
  DartType? visitFunctionType(FunctionType node, int variance) {
    isOutermost = false;
    return super.visitFunctionType(node, variance);
  }
}

int computeVariance(TypeParameter typeParameter, DartType type,
    {Map<TypeParameter, Map<DartType, int>>? computedVariances}) {
  computedVariances ??= new Map<TypeParameter, Map<DartType, int>>.identity();
  Map<DartType, int> variancesFromTypeParameter =
      computedVariances[typeParameter] ??= new Map<DartType, int>.identity();

  int? variance = variancesFromTypeParameter[type];
  if (variance != null) return variance;
  variancesFromTypeParameter[type] = VarianceCalculator._visitMarker;

  return variancesFromTypeParameter[type] =
      type.accept1(new VarianceCalculator(typeParameter), computedVariances);
}

class VarianceCalculator
    implements DartTypeVisitor1<int, Map<TypeParameter, Map<DartType, int>>> {
  final TypeParameter typeParameter;

  static const int _visitMarker = -2;

  VarianceCalculator(this.typeParameter);

  @override
  int defaultDartType(
      DartType node, Map<TypeParameter, Map<DartType, int>> computedVariances) {
    throw new StateError("Unhandled ${node.runtimeType} "
        "when computing variance of a type parameter.");
  }

  @override
  int visitTypeParameterType(TypeParameterType node,
      Map<TypeParameter, Map<DartType, int>> computedVariances) {
    if (node.parameter == typeParameter) return Variance.covariant;
    return Variance.unrelated;
  }

  @override
  int visitIntersectionType(IntersectionType node,
      Map<TypeParameter, Map<DartType, int>> computedVariances) {
    if (node.left.parameter == typeParameter) return Variance.covariant;
    return Variance.unrelated;
  }

  @override
  int visitInterfaceType(InterfaceType node,
      Map<TypeParameter, Map<DartType, int>> computedVariances) {
    int result = Variance.unrelated;
    for (int i = 0; i < node.typeArguments.length; ++i) {
      result = Variance.meet(
          result,
          Variance.combine(
              node.classNode.typeParameters[i].variance,
              computeVariance(typeParameter, node.typeArguments[i],
                  computedVariances: computedVariances)));
    }
    return result;
  }

  @override
  int visitExtensionType(ExtensionType node,
      Map<TypeParameter, Map<DartType, int>> computedVariances) {
    int result = Variance.unrelated;
    for (int i = 0; i < node.typeArguments.length; ++i) {
      result = Variance.meet(
          result,
          Variance.combine(
              node.extensionTypeDeclaration.typeParameters[i].variance,
              computeVariance(typeParameter, node.typeArguments[i],
                  computedVariances: computedVariances)));
    }
    return result;
  }

  @override
  int visitFutureOrType(FutureOrType node,
      Map<TypeParameter, Map<DartType, int>> computedVariances) {
    return computeVariance(typeParameter, node.typeArgument,
        computedVariances: computedVariances);
  }

  @override
  int visitTypedefType(TypedefType node,
      Map<TypeParameter, Map<DartType, int>> computedVariances) {
    int result = Variance.unrelated;
    for (int i = 0; i < node.typeArguments.length; ++i) {
      Typedef typedefNode = node.typedefNode;
      TypeParameter typedefTypeParameter = typedefNode.typeParameters[i];
      if (computedVariances.containsKey(typedefTypeParameter) &&
          computedVariances[typedefTypeParameter]![typedefNode.type] ==
              _visitMarker) {
        throw new StateError("The typedef '${node.typedefNode.name}' "
            "has a reference to itself.");
      }

      result = Variance.meet(
          result,
          Variance.combine(
              computeVariance(typeParameter, node.typeArguments[i],
                  computedVariances: computedVariances),
              computeVariance(typedefTypeParameter, typedefNode.type!,
                  computedVariances: computedVariances)));
    }
    return result;
  }

  @override
  int visitFunctionType(FunctionType node,
      Map<TypeParameter, Map<DartType, int>> computedVariances) {
    int result = Variance.unrelated;
    result = Variance.meet(
        result,
        computeVariance(typeParameter, node.returnType,
            computedVariances: computedVariances));
    for (TypeParameter functionTypeParameter in node.typeParameters) {
      // If [typeParameter] is referenced in the bound at all, it makes the
      // variance of [typeParameter] in the entire type invariant.  The
      // invocation of the visitor below is made to simply figure out if
      // [typeParameter] occurs in the bound.
      if (computeVariance(typeParameter, functionTypeParameter.bound,
              computedVariances: computedVariances) !=
          Variance.unrelated) {
        result = Variance.invariant;
      }
    }
    for (DartType positionalType in node.positionalParameters) {
      result = Variance.meet(
          result,
          Variance.combine(
              Variance.contravariant,
              computeVariance(typeParameter, positionalType,
                  computedVariances: computedVariances)));
    }
    for (NamedType namedType in node.namedParameters) {
      result = Variance.meet(
          result,
          Variance.combine(
              Variance.contravariant,
              computeVariance(typeParameter, namedType.type,
                  computedVariances: computedVariances)));
    }
    return result;
  }

  @override
  int visitRecordType(RecordType node,
      Map<TypeParameter, Map<DartType, int>> computedVariances) {
    int result = Variance.unrelated;
    for (DartType positionalType in node.positional) {
      result = Variance.meet(
          result,
          computeVariance(typeParameter, positionalType,
              computedVariances: computedVariances));
    }
    for (NamedType namedType in node.named) {
      result = Variance.meet(
          result,
          computeVariance(typeParameter, namedType.type,
              computedVariances: computedVariances));
    }
    return result;
  }

  @override
  int visitNeverType(NeverType node,
      Map<TypeParameter, Map<DartType, int>> computedVariances) {
    return Variance.unrelated;
  }

  @override
  int visitNullType(
      NullType node, Map<TypeParameter, Map<DartType, int>> computedVariances) {
    return Variance.unrelated;
  }

  @override
  int visitVoidType(
      VoidType node, Map<TypeParameter, Map<DartType, int>> computedVariances) {
    return Variance.unrelated;
  }

  @override
  int visitDynamicType(DynamicType node,
      Map<TypeParameter, Map<DartType, int>> computedVariances) {
    return Variance.unrelated;
  }

  @override
  int visitInvalidType(InvalidType node,
      Map<TypeParameter, Map<DartType, int>> computedVariances) {
    return Variance.unrelated;
  }
}

bool isGenericFunctionTypeOrAlias(DartType type) {
  if (type is TypedefType) type = type.unalias;
  return type is FunctionType && type.typeParameters.isNotEmpty;
}

bool hasGenericFunctionTypeAsTypeArgument(DartType type) {
  return type.accept1(
      const _HasGenericFunctionTypeAsTypeArgumentVisitor(), false);
}

class _HasGenericFunctionTypeAsTypeArgumentVisitor
    extends DartTypeVisitor1<bool, bool> {
  const _HasGenericFunctionTypeAsTypeArgumentVisitor();

  @override
  bool defaultDartType(DartType node, bool isTypeArgument) => false;

  @override
  bool visitFunctionType(FunctionType node, bool isTypeArgument) {
    if (isTypeArgument && node.typeParameters.isNotEmpty) {
      return true;
    }
    // TODO(johnniwinther): Should deeply nested generic function types be
    //  disallowed?
    if (node.returnType.accept1(this, false)) return true;
    for (DartType parameterType in node.positionalParameters) {
      if (parameterType.accept1(this, false)) return true;
    }
    for (NamedType namedParameterType in node.namedParameters) {
      if (namedParameterType.type.accept1(this, false)) return true;
    }
    return false;
  }

  @override
  bool visitInterfaceType(InterfaceType node, bool isTypeArgument) {
    for (DartType typeArgument in node.typeArguments) {
      if (typeArgument.accept1(this, true)) return true;
    }
    return false;
  }

  @override
  bool visitTypedefType(TypedefType node, bool isTypeArgument) {
    for (DartType typeArgument in node.typeArguments) {
      if (typeArgument.accept1(this, true)) return true;
    }
    return false;
  }
}
