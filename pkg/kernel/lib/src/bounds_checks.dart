// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart';
import '../type_algebra.dart';
import '../type_environment.dart' show SubtypeCheckMode, TypeEnvironment;
import '../util/graph.dart' show Graph, computeStrongComponents;
import 'replacement_visitor.dart';

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
    for (StructuralParameter typeParameter in node.typeParameters) {
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
  void visitAuxiliaryType(AuxiliaryType node) {
    throw new UnsupportedError(
        "Unsupported auxiliary type ${node} (${node.runtimeType}).");
  }

  @override
  void visitStructuralParameterType(StructuralParameterType node) {
    // TODO(cstefantsova): Should we have an occurrence visitor for
    // [StructuralParameter] objects.
  }
}

DartType instantiateToBounds(DartType type, Class objectClass) {
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
    return new InterfaceType.byReference(type.classReference, type.nullability,
        calculateBounds(type.classNode.typeParameters, objectClass));
  }
  if (type is TypedefType) {
    if (type.typeArguments.isEmpty) return type;
    for (DartType typeArgument in type.typeArguments) {
      if (typeArgument is! DynamicType) {
        return type;
      }
    }
    return new TypedefType.byReference(type.typedefReference, type.nullability,
        calculateBounds(type.typedefNode.typeParameters, objectClass));
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
    List<TypeParameter> typeParameters, Class objectClass) {
  List<DartType> bounds =
      new List<DartType>.filled(typeParameters.length, dummyDartType);
  for (int i = 0; i < typeParameters.length; i++) {
    DartType bound = typeParameters[i].bound;
    bool isContravariant = typeParameters[i].variance == Variance.contravariant;
    if (identical(bound, TypeParameter.unsetBoundSentinel)) {
      bound =
          isContravariant ? const NeverType.nonNullable() : const DynamicType();
    } else if (bound is InterfaceType &&
        bound.classReference == objectClass.reference) {
      DartType defaultType = typeParameters[i].defaultType;
      if (!(defaultType is InterfaceType &&
          defaultType.classNode == objectClass)) {
        bound = isContravariant
            ? const NeverType.nonNullable()
            : const DynamicType();
      }
    }
    bounds[i] = bound;
  }

  TypeVariableGraph graph = new TypeVariableGraph(typeParameters, bounds);
  List<List<int>> stronglyConnected = computeStrongComponents(graph);
  final DartType topType = const DynamicType();
  final DartType bottomType = const NeverType.nonNullable();
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
    required bool areGenericArgumentsAllowed}) {
  List<TypeParameter> variables;
  List<DartType> arguments;

  switch (type) {
    case InterfaceType(:var classNode, :var typeArguments):
      variables = classNode.typeParameters;
      arguments = typeArguments;
    case TypedefType(:var typedefNode, :var typeArguments):
      variables = typedefNode.typeParameters;
      arguments = typeArguments;
    case ExtensionType(:var extensionTypeDeclaration, :var typeArguments):
      variables = extensionTypeDeclaration.typeParameters;
      arguments = typeArguments;
      // Extension types are never allowed to be super-bounded.
      allowSuperBounded = false;
    case FunctionType(
        :var positionalParameters,
        :var namedParameters,
        :var returnType
      ):
      return <TypeArgumentIssue>[
        for (DartType formal in positionalParameters)
          ...findTypeArgumentIssues(formal, typeEnvironment, subtypeCheckMode,
              allowSuperBounded: true,
              areGenericArgumentsAllowed: areGenericArgumentsAllowed),
        for (NamedType named in namedParameters)
          ...findTypeArgumentIssues(
              named.type, typeEnvironment, subtypeCheckMode,
              allowSuperBounded: true,
              areGenericArgumentsAllowed: areGenericArgumentsAllowed),
        ...findTypeArgumentIssues(returnType, typeEnvironment, subtypeCheckMode,
            allowSuperBounded: true,
            areGenericArgumentsAllowed: areGenericArgumentsAllowed)
      ];
    case FutureOrType(:var typeArgument):
      variables = typeEnvironment.coreTypes.futureClass.typeParameters;
      arguments = <DartType>[typeArgument];
    case DynamicType():
    case VoidType():
    case IntersectionType():
    case TypeParameterType():
    case StructuralParameterType():
    case NeverType():
    case NullType():
    case RecordType():
      return const <TypeArgumentIssue>[];
    case AuxiliaryType():
      throw new StateError("AuxiliaryType");
    case InvalidType():
      // Assuming the error is reported elsewhere.
      throw const <TypeArgumentIssue>[];
  }

  if (variables.isEmpty) {
    return const <TypeArgumentIssue>[];
  }

  List<TypeArgumentIssue> result = <TypeArgumentIssue>[];

  Substitution substitution = Substitution.fromPairs(variables, arguments);
  for (int i = 0; i < arguments.length; ++i) {
    DartType argument = arguments[i];
    if (!areGenericArgumentsAllowed && isGenericFunctionTypeOrAlias(argument)) {
      // Generic function types aren't allowed as type arguments either.
      result.add(new TypeArgumentIssue(i, argument, variables[i], type,
          isGenericTypeAsArgumentIssue: true));
    } else if (variables[i].bound is! InvalidType) {
      DartType bound = substitution.substituteType(variables[i].bound);
      if (!typeEnvironment.isSubtypeOf(argument, bound, subtypeCheckMode)) {
        result.add(new TypeArgumentIssue(i, argument, variables[i], type));
      }
    } else {
      // The bound is InvalidType so it's not checked, because an error was
      // reported already at the time of the creation of InvalidType.
    }
  }

  // [type] is regular-bounded.
  if (result.isEmpty) return const <TypeArgumentIssue>[];
  if (!allowSuperBounded) return result;

  bool isCorrectSuperBounded = true;
  DartType? invertedType =
      convertSuperBoundedToRegularBounded(typeEnvironment, type);

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
  substitution = Substitution.fromPairs(variables, arguments);
  for (int i = 0; i < arguments.length; ++i) {
    DartType argument = arguments[i];
    // TODO(johnniwinther): Should we check this even when generic functions
    // as type arguments is allowed?
    if (isGenericFunctionTypeOrAlias(argument)) {
      // Generic function types aren't allowed as type arguments either.
      isCorrectSuperBounded = false;
    } else if (!typeEnvironment.isSubtypeOf(argument,
        substitution.substituteType(variables[i].bound), subtypeCheckMode)) {
      isCorrectSuperBounded = false;
    }
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
    {required bool areGenericArgumentsAllowed}) {
  assert(arguments.length == parameters.length);
  assert(bottomType == const NeverType.nonNullable() || bottomType is NullType);

  List<TypeArgumentIssue> result = <TypeArgumentIssue>[];
  Substitution substitution = Substitution.fromPairs(parameters, arguments);
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
      DartType bound = substitution.substituteType(parameters[i].bound);
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
    {Variance variance = Variance.covariant}) {
  return type.accept1(new _SuperBoundedTypeInverter(typeEnvironment), variance);
}

class _SuperBoundedTypeInverter extends ReplacementVisitor {
  final TypeEnvironment typeEnvironment;
  bool isOutermost = true;

  _SuperBoundedTypeInverter(this.typeEnvironment);

  bool flipTop(Variance variance) {
    return variance != Variance.contravariant;
  }

  bool flipBottom(Variance variance) {
    return variance == Variance.contravariant;
  }

  DartType get topType {
    return typeEnvironment.coreTypes.objectNullableRawType;
  }

  DartType get bottomType {
    return const NeverType.nonNullable();
  }

  bool isTop(DartType node) {
    return typeEnvironment.coreTypes.isTop(node);
  }

  bool isBottom(DartType node) {
    return typeEnvironment.coreTypes.isBottom(node);
  }

  @override
  DartType? visitDynamicType(DynamicType node, Variance variance) {
    // dynamic is always a top type.
    assert(isTop(node));
    if (flipTop(variance)) {
      return bottomType;
    } else {
      return null;
    }
  }

  @override
  DartType? visitVoidType(VoidType node, Variance variance) {
    // void is always a top type.
    assert(isTop(node));
    if (flipTop(variance)) {
      return bottomType;
    } else {
      return null;
    }
  }

  @override
  DartType? visitInterfaceType(InterfaceType node, Variance variance) {
    isOutermost = false;
    // Check for Object-based top types.
    if (isTop(node) && flipTop(variance)) {
      return bottomType;
    } else {
      return super.visitInterfaceType(node, variance);
    }
  }

  @override
  DartType? visitRecordType(RecordType node, Variance variance) {
    isOutermost = false;
    return super.visitRecordType(node, variance);
  }

  @override
  DartType? visitFutureOrType(FutureOrType node, Variance variance) {
    isOutermost = false;
    // Check FutureOr-based top types.
    if (isTop(node) && flipTop(variance)) {
      return bottomType;
    } else {
      return super.visitFutureOrType(node, variance);
    }
  }

  @override
  DartType? visitNullType(NullType node, Variance variance) {
    // Null isn't a bottom type in NNBD.
    if (isBottom(node) && flipBottom(variance)) {
      return topType;
    } else {
      return null;
    }
  }

  @override
  DartType? visitNeverType(NeverType node, Variance variance) {
    // Depending on the variance, Never may not be a bottom type.
    if (isBottom(node) && flipBottom(variance)) {
      return topType;
    } else {
      return null;
    }
  }

  @override
  DartType? visitTypeParameterType(TypeParameterType node, Variance variance) {
    // Types such as X extends Never are bottom types.
    if (isBottom(node) && flipBottom(variance)) {
      return topType;
    } else {
      return null;
    }
  }

  @override
  DartType? visitIntersectionType(IntersectionType node, Variance variance) {
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
  DartType? visitTypedefType(TypedefType node, Variance variance) {
    isOutermost = false;
    Nullability? newNullability = visitNullability(node);
    List<DartType>? newTypeArguments = null;
    for (int i = 0; i < node.typeArguments.length; i++) {
      // The implementation of instantiate-to-bound in legacy mode ignored the
      // variance of type parameters of the typedef.  This behavior is preserved
      // here in passing the 'variance' parameter unchanged in for legacy
      // libraries.
      DartType? newTypeArgument = node.typeArguments[i].accept1(
          this, variance.combine(node.typedefNode.typeParameters[i].variance));
      if (newTypeArgument != null) {
        newTypeArguments ??= new List<DartType>.of(node.typeArguments);
        newTypeArguments[i] = newTypeArgument;
      }
    }
    return createTypedef(node, newNullability, newTypeArguments);
  }

  @override
  DartType? visitFunctionType(FunctionType node, Variance variance) {
    isOutermost = false;
    return super.visitFunctionType(node, variance);
  }
}

Variance computeVariance(TypeParameter typeParameter, DartType type,
    {Map<TypeParameter, Map<DartType, VarianceCalculationValue>>?
        computedVariances}) {
  computedVariances ??= new Map<TypeParameter,
      Map<DartType, VarianceCalculationValue>>.identity();
  Map<DartType, VarianceCalculationValue> variancesFromTypeParameter =
      computedVariances[typeParameter] ??=
          new Map<DartType, VarianceCalculationValue>.identity();

  VarianceCalculationValue? varianceCalculationValue =
      variancesFromTypeParameter[type];
  if (varianceCalculationValue != null &&
      varianceCalculationValue.isCalculated) {
    return varianceCalculationValue.variance!;
  }
  variancesFromTypeParameter[type] = VarianceCalculationValue.inProgress;

  variancesFromTypeParameter[type] =
      type.accept1(new VarianceCalculator(typeParameter), computedVariances);
  return variancesFromTypeParameter[type]!.variance!;
}

enum VarianceCalculationValue {
  pending(null),
  inProgress(null),
  calculatedUnrelated(Variance.unrelated),
  calculatedCovariant(Variance.covariant),
  calculatedContravariant(Variance.contravariant),
  calculatedInvariant(Variance.invariant);

  final Variance? variance;

  const VarianceCalculationValue(this.variance);

  factory VarianceCalculationValue.fromVariance(Variance variance) =>
      switch (variance) {
        Variance.unrelated => VarianceCalculationValue.calculatedUnrelated,
        Variance.covariant => VarianceCalculationValue.calculatedCovariant,
        Variance.contravariant =>
          VarianceCalculationValue.calculatedContravariant,
        Variance.invariant => VarianceCalculationValue.calculatedInvariant,
      };

  bool get isCalculated => variance != null;
}

class VarianceCalculator
    implements
        DartTypeVisitor1<VarianceCalculationValue,
            Map<TypeParameter, Map<DartType, VarianceCalculationValue>>> {
  final TypeParameter typeParameter;

  VarianceCalculator(this.typeParameter);

  @override
  VarianceCalculationValue visitAuxiliaryType(
      AuxiliaryType node,
      Map<TypeParameter, Map<DartType, VarianceCalculationValue>>
          computedVariances) {
    throw new StateError("Unhandled ${node.runtimeType} "
        "when computing variance of a type parameter.");
  }

  @override
  VarianceCalculationValue visitTypeParameterType(
      TypeParameterType node,
      Map<TypeParameter, Map<DartType, VarianceCalculationValue>>
          computedVariances) {
    if (node.parameter == typeParameter) {
      return VarianceCalculationValue.calculatedCovariant;
    } else {
      return VarianceCalculationValue.calculatedUnrelated;
    }
  }

  @override
  VarianceCalculationValue visitStructuralParameterType(
      StructuralParameterType node,
      Map<TypeParameter, Map<DartType, VarianceCalculationValue>>
          computedVariances) {
    // TODO(cstefantsova): Implement this method.
    return VarianceCalculationValue.calculatedUnrelated;
  }

  @override
  VarianceCalculationValue visitIntersectionType(
      IntersectionType node,
      Map<TypeParameter, Map<DartType, VarianceCalculationValue>>
          computedVariances) {
    if (node.left.parameter == typeParameter) {
      return VarianceCalculationValue.calculatedCovariant;
    } else {
      return VarianceCalculationValue.calculatedUnrelated;
    }
  }

  @override
  VarianceCalculationValue visitInterfaceType(
      InterfaceType node,
      Map<TypeParameter, Map<DartType, VarianceCalculationValue>>
          computedVariances) {
    Variance result = Variance.unrelated;
    for (int i = 0; i < node.typeArguments.length; ++i) {
      result = result.meet(node.classNode.typeParameters[i].variance.combine(
          computeVariance(typeParameter, node.typeArguments[i],
              computedVariances: computedVariances)));
    }
    return new VarianceCalculationValue.fromVariance(result);
  }

  @override
  VarianceCalculationValue visitExtensionType(
      ExtensionType node,
      Map<TypeParameter, Map<DartType, VarianceCalculationValue>>
          computedVariances) {
    Variance result = Variance.unrelated;
    for (int i = 0; i < node.typeArguments.length; ++i) {
      result = result.meet(node
          .extensionTypeDeclaration.typeParameters[i].variance
          .combine(computeVariance(typeParameter, node.typeArguments[i],
              computedVariances: computedVariances)));
    }
    return new VarianceCalculationValue.fromVariance(result);
  }

  @override
  VarianceCalculationValue visitFutureOrType(
      FutureOrType node,
      Map<TypeParameter, Map<DartType, VarianceCalculationValue>>
          computedVariances) {
    return new VarianceCalculationValue.fromVariance(computeVariance(
        typeParameter, node.typeArgument,
        computedVariances: computedVariances));
  }

  @override
  VarianceCalculationValue visitTypedefType(
      TypedefType node,
      Map<TypeParameter, Map<DartType, VarianceCalculationValue>>
          computedVariances) {
    Variance result = Variance.unrelated;
    for (int i = 0; i < node.typeArguments.length; ++i) {
      Typedef typedefNode = node.typedefNode;
      TypeParameter typedefTypeParameter = typedefNode.typeParameters[i];
      if (computedVariances.containsKey(typedefTypeParameter) &&
          computedVariances[typedefTypeParameter]![typedefNode.type] ==
              VarianceCalculationValue.inProgress) {
        throw new StateError("The typedef '${node.typedefNode.name}' "
            "has a reference to itself.");
      }

      result = result.meet(computeVariance(typeParameter, node.typeArguments[i],
              computedVariances: computedVariances)
          .combine(computeVariance(typedefTypeParameter, typedefNode.type!,
              computedVariances: computedVariances)));
    }
    return new VarianceCalculationValue.fromVariance(result);
  }

  @override
  VarianceCalculationValue visitFunctionType(
      FunctionType node,
      Map<TypeParameter, Map<DartType, VarianceCalculationValue>>
          computedVariances) {
    Variance result = Variance.unrelated;
    result = result.meet(computeVariance(typeParameter, node.returnType,
        computedVariances: computedVariances));
    for (StructuralParameter functionTypeParameter in node.typeParameters) {
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
      result = result.meet(Variance.contravariant.combine(computeVariance(
          typeParameter, positionalType,
          computedVariances: computedVariances)));
    }
    for (NamedType namedType in node.namedParameters) {
      result = result.meet(Variance.contravariant.combine(computeVariance(
          typeParameter, namedType.type,
          computedVariances: computedVariances)));
    }
    return new VarianceCalculationValue.fromVariance(result);
  }

  @override
  VarianceCalculationValue visitRecordType(
      RecordType node,
      Map<TypeParameter, Map<DartType, VarianceCalculationValue>>
          computedVariances) {
    Variance result = Variance.unrelated;
    for (DartType positionalType in node.positional) {
      result = result.meet(computeVariance(typeParameter, positionalType,
          computedVariances: computedVariances));
    }
    for (NamedType namedType in node.named) {
      result = result.meet(computeVariance(typeParameter, namedType.type,
          computedVariances: computedVariances));
    }
    return new VarianceCalculationValue.fromVariance(result);
  }

  @override
  VarianceCalculationValue visitNeverType(
      NeverType node,
      Map<TypeParameter, Map<DartType, VarianceCalculationValue>>
          computedVariances) {
    return VarianceCalculationValue.calculatedUnrelated;
  }

  @override
  VarianceCalculationValue visitNullType(
      NullType node,
      Map<TypeParameter, Map<DartType, VarianceCalculationValue>>
          computedVariances) {
    return VarianceCalculationValue.calculatedUnrelated;
  }

  @override
  VarianceCalculationValue visitVoidType(
      VoidType node,
      Map<TypeParameter, Map<DartType, VarianceCalculationValue>>
          computedVariances) {
    return VarianceCalculationValue.calculatedUnrelated;
  }

  @override
  VarianceCalculationValue visitDynamicType(
      DynamicType node,
      Map<TypeParameter, Map<DartType, VarianceCalculationValue>>
          computedVariances) {
    return VarianceCalculationValue.calculatedUnrelated;
  }

  @override
  VarianceCalculationValue visitInvalidType(
      InvalidType node,
      Map<TypeParameter, Map<DartType, VarianceCalculationValue>>
          computedVariances) {
    return VarianceCalculationValue.calculatedUnrelated;
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
  bool visitAuxiliaryType(AuxiliaryType node, bool isTypeArgument) {
    throw new UnsupportedError(
        "Unsupported auxiliary type ${node} (${node.runtimeType}).");
  }

  @override
  bool visitFunctionType(FunctionType node, bool isTypeArgument) {
    if (isTypeArgument && node.typeParameters.isNotEmpty) {
      return true;
    }
    if (node.returnType.accept1(this, false)) return true;
    for (DartType parameterType in node.positionalParameters) {
      if (parameterType.accept1(this, false)) return true;
    }
    for (NamedType namedParameterType in node.namedParameters) {
      if (namedParameterType.type.accept1(this, false)) return true;
    }
    for (StructuralParameter typeParameter in node.typeParameters) {
      if (typeParameter.bound.accept1(this, false)) {
        return true;
      }
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

  @override
  bool visitExtensionType(ExtensionType node, bool isTypeArgument) {
    for (DartType typeArgument in node.typeArguments) {
      if (typeArgument.accept1(this, true)) return true;
    }
    return false;
  }

  @override
  bool visitDynamicType(DynamicType node, bool isTypeArgument) => false;

  @override
  bool visitFutureOrType(FutureOrType node, bool isTypeArgument) {
    return node.typeArgument.accept1(this, false);
  }

  @override
  bool visitIntersectionType(IntersectionType node, bool isTypeArgument) {
    return node.left.accept1(this, false) || node.right.accept1(this, false);
  }

  @override
  bool visitInvalidType(InvalidType node, bool isTypeArgument) => false;

  @override
  bool visitNeverType(NeverType node, bool isTypeArgument) => false;

  @override
  bool visitNullType(NullType node, bool isTypeArgument) => false;

  @override
  bool visitRecordType(RecordType node, bool isTypeArgument) {
    for (DartType parameterType in node.positional) {
      if (parameterType.accept1(this, false)) return true;
    }
    for (NamedType namedParameterType in node.named) {
      if (namedParameterType.type.accept1(this, false)) return true;
    }
    return false;
  }

  @override
  bool visitTypeParameterType(TypeParameterType node, bool isTypeArgument) {
    return false;
  }

  @override
  bool visitStructuralParameterType(
      StructuralParameterType node, bool isTypeArgument) {
    return false;
  }

  @override
  bool visitVoidType(VoidType node, bool isTypeArgument) => false;
}
