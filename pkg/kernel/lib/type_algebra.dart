// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.type_algebra;

import 'ast.dart';

/// Returns a type where all occurrences of the given type parameters have been
/// replaced with the corresponding types.
///
/// This will copy only the subterms of [type] that contain substituted
/// variables; all other [DartType] objects will be reused.
///
/// In particular, if no variables were substituted, this is guaranteed to
/// return the [type] instance (not a copy), so the caller may use [identical]
/// to efficiently check if a distinct type was created.
DartType substitute(DartType type, Map<TypeParameter, DartType> substitution) {
  if (substitution.isEmpty) return type;
  return Substitution.fromMap(substitution).substituteType(type);
}

/// Returns a mapping from the type parameters declared on the class of [type]
/// to the actual type arguments provided in [type].
///
/// This can be passed as argument to [substitute].
Map<TypeParameter, DartType> getSubstitutionMap(Supertype type) {
  return type.typeArguments.isEmpty
      ? const <TypeParameter, DartType>{}
      : new Map<TypeParameter, DartType>.fromIterables(
          type.classNode.typeParameters, type.typeArguments);
}

Map<TypeParameter, DartType> getUpperBoundSubstitutionMap(Class host) {
  if (host.typeParameters.isEmpty) return const <TypeParameter, DartType>{};
  var result = <TypeParameter, DartType>{};
  for (var parameter in host.typeParameters) {
    result[parameter] = const DynamicType();
  }
  for (var parameter in host.typeParameters) {
    result[parameter] = substitute(parameter.bound, result);
  }
  return result;
}

/// Like [substitute], except when a type in the [substitution] map references
/// another substituted type variable, the mapping for that type is recursively
/// inserted.
///
/// For example `Set<G>` substituted with `{T -> String, G -> List<T>}` results
/// in `Set<List<String>>`.
///
/// Returns `null` if the substitution map contains a cycle reachable from a
/// type variable in [type] (the resulting type would be infinite).
///
/// The [substitution] map will be mutated so that the right-hand sides may
/// be remapped to the deeply substituted type, but only for the keys that are
/// reachable from [type].
///
/// As with [substitute], this is guaranteed to return the same instance if no
/// substitution was performed.
DartType substituteDeep(
    DartType type, Map<TypeParameter, DartType> substitution) {
  if (substitution.isEmpty) return type;
  var substitutor = new _DeepTypeSubstitutor(substitution);
  var result = substitutor.visit(type);
  return substitutor.isInfinite ? null : result;
}

/// Returns true if [type] contains a reference to any of the given [variables].
///
/// [unhandledTypeHandler] is a helper function invoked on unknown implementers
/// of [DartType].  Its arguments are the unhandled type and the function that
/// can be invoked from within the handler on parts of the unknown type to
/// recursively call the visitor.  If not passed, an exception is thrown then an
/// unhandled implementer of [DartType] is encountered.
///
/// It is an error to call this with a [type] that contains a [FunctionType]
/// that declares one of the parameters in [variables].
bool containsTypeVariable(DartType type, Set<TypeParameter> variables,
    {bool Function(DartType type, bool Function(DartType type) recursor)
        unhandledTypeHandler}) {
  if (variables.isEmpty) return false;
  return new _OccurrenceVisitor(variables,
          unhandledTypeHandler: unhandledTypeHandler)
      .visit(type);
}

/// Returns `true` if [type] contains any free type variables, that is, type
/// variable for function types whose function type is part of [type].
bool containsFreeFunctionTypeVariables(DartType type) {
  return new _FreeFunctionTypeVariableVisitor().visit(type);
}

/// Given a set of type variables, finds a substitution of those variables such
/// that the two given types becomes equal, or returns `null` if no such
/// substitution exists.
///
/// For example, unifying `List<T>` with `List<String>`, where `T` is a
/// quantified variable, yields the substitution `T = String`.
///
/// If successful, this equation holds:
///
///     substitute(type1, substitution) == substitute(type2, substitution)
///
/// The unification can fail for two reasons:
/// - incompatible types, e.g. `List<T>` cannot be unified with `Set<T>`.
/// - infinite types: e.g. `T` cannot be unified with `List<T>` because it
///   would create the infinite type `List<List<List<...>>>`.
Map<TypeParameter, DartType> unifyTypes(
    DartType type1, DartType type2, Set<TypeParameter> quantifiedVariables) {
  var unifier = new _TypeUnification(type1, type2, quantifiedVariables);
  return unifier.success ? unifier.substitution : null;
}

/// Generates a fresh copy of the given type parameters, with their bounds
/// substituted to reference the new parameters.
///
/// The returned object contains the fresh type parameter list as well as a
/// mapping to be used for replacing other types to use the new type parameters.
FreshTypeParameters getFreshTypeParameters(List<TypeParameter> typeParameters) {
  var freshParameters = new List<TypeParameter>.generate(
      typeParameters.length, (i) => new TypeParameter(typeParameters[i].name),
      growable: true);
  var map = <TypeParameter, DartType>{};
  for (int i = 0; i < typeParameters.length; ++i) {
    map[typeParameters[i]] = new TypeParameterType.forAlphaRenaming(
        typeParameters[i], freshParameters[i]);
  }
  for (int i = 0; i < typeParameters.length; ++i) {
    TypeParameter typeParameter = typeParameters[i];
    TypeParameter freshTypeParameter = freshParameters[i];

    freshTypeParameter.bound = substitute(typeParameter.bound, map);
    freshTypeParameter.defaultType = typeParameter.defaultType != null
        ? substitute(typeParameter.defaultType, map)
        : null;
    freshTypeParameter.variance =
        typeParameter.isLegacyCovariant ? null : typeParameter.variance;
    // Annotations on a type parameter are specific to the declaration of the
    // type parameter, rather than the type parameter as such, and therefore
    // should not be copied here.
  }
  return new FreshTypeParameters(freshParameters, Substitution.fromMap(map));
}

class FreshTypeParameters {
  final List<TypeParameter> freshTypeParameters;
  final Substitution substitution;

  FreshTypeParameters(this.freshTypeParameters, this.substitution);

  FunctionType applyToFunctionType(FunctionType type) => new FunctionType(
      type.positionalParameters.map(substitute).toList(),
      substitute(type.returnType),
      type.nullability,
      namedParameters: type.namedParameters.map(substituteNamed).toList(),
      typeParameters: freshTypeParameters,
      requiredParameterCount: type.requiredParameterCount,
      typedefType:
          type.typedefType == null ? null : substitute(type.typedefType));

  DartType substitute(DartType type) => substitution.substituteType(type);

  NamedType substituteNamed(NamedType type) =>
      new NamedType(type.name, substitute(type.type),
          isRequired: type.isRequired);

  Supertype substituteSuper(Supertype type) {
    return substitution.substituteSupertype(type);
  }
}

// ------------------------------------------------------------------------
//                              IMPLEMENTATION
// ------------------------------------------------------------------------

abstract class Substitution {
  const Substitution();

  static const Substitution empty = _NullSubstitution.instance;

  /// Substitutes each parameter to the type it maps to in [map].
  static Substitution fromMap(Map<TypeParameter, DartType> map) {
    if (map.isEmpty) return _NullSubstitution.instance;
    return new _MapSubstitution(map, map);
  }

  static Substitution filtered(Substitution sub, TypeParameterFilter filter) {
    return new _FilteredSubstitution(sub, filter);
  }

  /// Substitutes all occurrences of the given type parameters with the
  /// corresponding upper or lower bound, depending on the variance of the
  /// context where it occurs.
  ///
  /// For example the type `(T) => T` with the bounds `bottom <: T <: num`
  /// becomes `(bottom) => num` (in this example, `num` is the upper bound,
  /// and `bottom` is the lower bound).
  ///
  /// This is a way to obtain an upper bound for a type while eliminating all
  /// references to certain type variables.
  static Substitution fromUpperAndLowerBounds(
      Map<TypeParameter, DartType> upper, Map<TypeParameter, DartType> lower) {
    if (upper.isEmpty && lower.isEmpty) return _NullSubstitution.instance;
    return new _MapSubstitution(upper, lower);
  }

  /// Substitutes the type parameters on the class of [supertype] with the
  /// type arguments provided in [supertype].
  static Substitution fromSupertype(Supertype supertype) {
    if (supertype.typeArguments.isEmpty) return _NullSubstitution.instance;
    return fromMap(new Map<TypeParameter, DartType>.fromIterables(
        supertype.classNode.typeParameters, supertype.typeArguments));
  }

  /// Substitutes the type parameters on the class of [type] with the
  /// type arguments provided in [type].
  static Substitution fromInterfaceType(InterfaceType type) {
    if (type.typeArguments.isEmpty) return _NullSubstitution.instance;
    return fromMap(new Map<TypeParameter, DartType>.fromIterables(
        type.classNode.typeParameters, type.typeArguments));
  }

  /// Substitutes the type parameters on the typedef of [type] with the
  /// type arguments provided in [type].
  static Substitution fromTypedefType(TypedefType type) {
    if (type.typeArguments.isEmpty) return _NullSubstitution.instance;
    return fromMap(new Map<TypeParameter, DartType>.fromIterables(
        type.typedefNode.typeParameters, type.typeArguments));
  }

  /// Substitutes the Nth parameter in [parameters] with the Nth type in
  /// [types].
  static Substitution fromPairs(
      List<TypeParameter> parameters, List<DartType> types) {
    // TODO(asgerf): Investigate if it is more efficient to implement
    // substitution based on parallel pairwise lists instead of Maps.
    assert(parameters.length == types.length);
    if (parameters.isEmpty) return _NullSubstitution.instance;
    return fromMap(
        new Map<TypeParameter, DartType>.fromIterables(parameters, types));
  }

  /// Substitutes the type parameters on the class with bottom or dynamic,
  /// depending on the covariance of its use.
  static Substitution bottomForClass(Class class_) {
    if (class_.typeParameters.isEmpty) return _NullSubstitution.instance;
    return new _ClassBottomSubstitution(class_);
  }

  /// Substitutes covariant uses of [class_]'s type parameters with the upper
  /// bound of that type parameter.  Recursive references in the bound have
  /// been replaced by dynamic.
  static Substitution upperBoundForClass(Class class_) {
    if (class_.typeParameters.isEmpty) return _NullSubstitution.instance;
    var upper = <TypeParameter, DartType>{};
    for (var parameter in class_.typeParameters) {
      upper[parameter] = const DynamicType();
    }
    for (var parameter in class_.typeParameters) {
      upper[parameter] = substitute(parameter.bound, upper);
    }
    return fromUpperAndLowerBounds(upper, {});
  }

  /// Substitutes both variables from [first] and [second], favoring those from
  /// [first] if they overlap.
  ///
  /// Neither substitution is applied to the results of the other, so this does
  /// *not* correspond to a sequence of two substitutions. For example,
  /// combining `{T -> List<G>}` with `{G -> String}` does not correspond to
  /// `{T -> List<String>}` because the result from substituting `T` is not
  /// searched for occurences of `G`.
  static Substitution combine(Substitution first, Substitution second) {
    if (first == _NullSubstitution.instance) return second;
    if (second == _NullSubstitution.instance) return first;
    return new _CombinedSubstitution(first, second);
  }

  DartType getSubstitute(TypeParameter parameter, bool upperBound);

  DartType substituteType(DartType node, {bool contravariant: false}) {
    return new _TopSubstitutor(this, contravariant).visit(node);
  }

  Supertype substituteSupertype(Supertype node) {
    return new _TopSubstitutor(this, false).visitSupertype(node);
  }
}

class _NullSubstitution extends Substitution {
  static const _NullSubstitution instance = const _NullSubstitution();

  const _NullSubstitution();

  DartType getSubstitute(TypeParameter parameter, bool upperBound) {
    return new TypeParameterType.forAlphaRenaming(parameter, parameter);
  }

  @override
  DartType substituteType(DartType node, {bool contravariant: false}) => node;

  @override
  Supertype substituteSupertype(Supertype node) => node;

  @override
  String toString() => "Substitution.empty";
}

class _MapSubstitution extends Substitution {
  final Map<TypeParameter, DartType> upper;
  final Map<TypeParameter, DartType> lower;

  _MapSubstitution(this.upper, this.lower);

  DartType getSubstitute(TypeParameter parameter, bool upperBound) {
    return upperBound ? upper[parameter] : lower[parameter];
  }

  @override
  String toString() => "_MapSubstitution($upper, $lower)";
}

class _TopSubstitutor extends _TypeSubstitutor {
  final Substitution substitution;

  _TopSubstitutor(this.substitution, bool contravariant) : super(null) {
    if (contravariant) {
      invertVariance();
    }
  }

  DartType lookup(TypeParameter parameter, bool upperBound) {
    return substitution.getSubstitute(parameter, upperBound);
  }

  TypeParameter freshTypeParameter(TypeParameter node) {
    throw 'Create a fresh environment first';
  }
}

class _ClassBottomSubstitution extends Substitution {
  final Class class_;

  _ClassBottomSubstitution(this.class_);

  DartType getSubstitute(TypeParameter parameter, bool upperBound) {
    if (parameter.parent == class_) {
      return upperBound ? const BottomType() : const DynamicType();
    }
    return null;
  }
}

class _CombinedSubstitution extends Substitution {
  final Substitution first, second;

  _CombinedSubstitution(this.first, this.second);

  DartType getSubstitute(TypeParameter parameter, bool upperBound) {
    return first.getSubstitute(parameter, upperBound) ??
        second.getSubstitute(parameter, upperBound);
  }
}

typedef bool TypeParameterFilter(TypeParameter P);

class _FilteredSubstitution extends Substitution {
  final Substitution base;
  final TypeParameterFilter filterFn;

  _FilteredSubstitution(this.base, this.filterFn);

  DartType getSubstitute(TypeParameter parameter, bool upperBound) {
    return filterFn(parameter)
        ? base.getSubstitute(parameter, upperBound)
        : _NullSubstitution.instance.getSubstitute(parameter, upperBound);
  }
}

class _InnerTypeSubstitutor extends _TypeSubstitutor {
  final Map<TypeParameter, DartType> substitution = <TypeParameter, DartType>{};

  _InnerTypeSubstitutor(_TypeSubstitutor outer) : super(outer);

  DartType lookup(TypeParameter parameter, bool upperBound) {
    return substitution[parameter];
  }

  TypeParameter freshTypeParameter(TypeParameter node) {
    TypeParameter fresh = new TypeParameter(node.name);
    TypeParameterType typeParameterType = substitution[node] =
        new TypeParameterType.forAlphaRenaming(node, fresh);
    fresh.bound = visit(node.bound);
    if (node.defaultType != null) {
      fresh.defaultType = visit(node.defaultType);
    }
    // If the bound was changed from substituting the bound we need to update
    // implicit nullability to be based on the new bound. If the bound wasn't
    // changed the computation below results in the same nullability.
    //
    // If the type variable occurred in the bound then the bound was
    // of the form `Foo<...T..>` or `FutureOr<T>` and the nullability therefore
    // has not changed.
    typeParameterType.declaredNullability =
        TypeParameterType.computeNullabilityFromBound(fresh);
    return fresh;
  }
}

/// Combines nullabilities of types during type substitution.
///
/// In a type substitution, for example, when `int` is substituted for `T` in
/// `List<T?>`, the nullability of the occurrence of the type parameter should
/// be combined with the nullability of the type that is being substituted for
/// that type parameter.  In the example above it's the nullability of `T?`
/// and `int`.  The function computes the nullability for the replacement as
/// per the following table:
///
/// |  a  \  b  |  !  |  ?  |  *  |  %  |
/// |-----------|-----|-----|-----|-----|
/// |     !     |  !  |  ?  |  *  |  !  |
/// |     ?     | N/A |  ?  |  ?  |  ?  |
/// |     *     |  *  |  ?  |  *  |  *  |
/// |     %     | N/A |  ?  |  *  |  %  |
///
/// Here `!` denotes `Nullability.nonNullable`, `?` denotes
/// `Nullability.nullable`, `*` denotes `Nullability.legacy`, and `%` denotes
/// `Nullability.neither`.  The table elements marked with N/A denote the
/// cases that should yield a type error before the substitution is performed.
Nullability combineNullabilitiesForSubstitution(Nullability a, Nullability b) {
  // In the table above we may extend the function given by it, replacing N/A
  // with whatever is easier to implement.  In this implementation, we extend
  // the table function as follows:
  //
  // |  a  \  b  |  !  |  ?  |  *  |  %  |
  // |-----------|-----|-----|-----|-----|
  // |     !     |  !  |  ?  |  *  |  !  |
  // |     ?     |  ?  |  ?  |  ?  |  ?  |
  // |     *     |  *  |  ?  |  *  |  *  |
  // |     %     |  %  |  ?  |  *  |  %  |
  //

  if (a == Nullability.nullable || b == Nullability.nullable) {
    return Nullability.nullable;
  }

  if (a == Nullability.legacy || b == Nullability.legacy) {
    return Nullability.legacy;
  }

  return a;
}

abstract class _TypeSubstitutor extends DartTypeVisitor<DartType> {
  final _TypeSubstitutor outer;
  bool covariantContext = true;

  _TypeSubstitutor(this.outer) {
    covariantContext = outer == null ? true : outer.covariantContext;
  }

  DartType lookup(TypeParameter parameter, bool upperBound);

  /// The number of times a variable from this environment has been used in
  /// a substitution.
  ///
  /// There is a strict requirement that we must return the same instance for
  /// types that were not altered by the substitution.  This counter lets us
  /// check quickly if anything happened in a substitution.
  int useCounter = 0;

  _InnerTypeSubstitutor newInnerEnvironment() {
    return new _InnerTypeSubstitutor(this);
  }

  void invertVariance() {
    covariantContext = !covariantContext;
  }

  Supertype visitSupertype(Supertype node) {
    if (node.typeArguments.isEmpty) return node;
    int before = useCounter;
    var typeArguments = node.typeArguments.map(visit).toList();
    if (useCounter == before) return node;
    return new Supertype(node.classNode, typeArguments);
  }

  NamedType visitNamedType(NamedType node) {
    int before = useCounter;
    var type = visit(node.type);
    if (useCounter == before) return node;
    return new NamedType(node.name, type, isRequired: node.isRequired);
  }

  DartType visit(DartType node) => node.accept(this);

  DartType defaultDartType(DartType node) => node;
  DartType visitInvalidType(InvalidType node) => node;
  DartType visitDynamicType(DynamicType node) => node;
  DartType visitVoidType(VoidType node) => node;
  DartType visitBottomType(BottomType node) => node;
  DartType visitNeverType(NeverType node) => node;

  DartType visitInterfaceType(InterfaceType node) {
    if (node.typeArguments.isEmpty) return node;
    int before = useCounter;
    var typeArguments = node.typeArguments.map(visit).toList();
    if (useCounter == before) return node;
    return new InterfaceType(node.classNode, node.nullability, typeArguments);
  }

  DartType visitFutureOrType(FutureOrType node) {
    int before = useCounter;
    DartType typeArgument = node.typeArgument.accept(this);
    if (useCounter == before) return node;
    return new FutureOrType(typeArgument, node.declaredNullability);
  }

  DartType visitTypedefType(TypedefType node) {
    if (node.typeArguments.isEmpty) return node;
    int before = useCounter;
    var typeArguments = node.typeArguments.map(visit).toList();
    if (useCounter == before) return node;
    return new TypedefType(node.typedefNode, node.nullability, typeArguments);
  }

  List<TypeParameter> freshTypeParameters(List<TypeParameter> parameters) {
    if (parameters.isEmpty) return const <TypeParameter>[];
    return parameters.map(freshTypeParameter).toList();
  }

  TypeParameter freshTypeParameter(TypeParameter node);

  DartType visitFunctionType(FunctionType node) {
    // This is a bit tricky because we have to generate fresh type parameters
    // in order to change the bounds.  At the same time, if the function type
    // was unaltered, we have to return the [node] object (not a copy!).
    // Substituting a type for a fresh type variable should not be confused with
    // a "real" substitution.
    //
    // Create an inner environment to generate fresh type parameters.  The use
    // counter on the inner environment tells if the fresh type parameters have
    // any uses, but does not tell if the resulting function type is distinct.
    // Our own use counter will get incremented if something from our
    // environment has been used inside the function.
    assert(
        node.typeParameters.every((TypeParameter parameter) =>
            lookup(parameter, true) == null &&
            lookup(parameter, false) == null),
        "Function type variables cannot be substituted while still attached "
        "to the function. Perform substitution on "
        "`FunctionType.withoutTypeParameters` instead.");
    var inner = node.typeParameters.isEmpty ? this : newInnerEnvironment();
    int before = this.useCounter;
    // Invert the variance when translating parameters.
    inner.invertVariance();
    var typeParameters = inner.freshTypeParameters(node.typeParameters);
    var positionalParameters = node.positionalParameters.isEmpty
        ? const <DartType>[]
        : node.positionalParameters.map(inner.visit).toList();
    var namedParameters = node.namedParameters.isEmpty
        ? const <NamedType>[]
        : node.namedParameters.map(inner.visitNamedType).toList();
    inner.invertVariance();
    var returnType = inner.visit(node.returnType);
    DartType typedefType =
        node.typedefType == null ? null : inner.visit(node.typedefType);
    if (this.useCounter == before) return node;
    return new FunctionType(positionalParameters, returnType, node.nullability,
        namedParameters: namedParameters,
        typeParameters: typeParameters,
        requiredParameterCount: node.requiredParameterCount,
        typedefType: typedefType);
  }

  void bumpCountersUntil(_TypeSubstitutor target) {
    var node = this;
    while (node != target) {
      ++node.useCounter;
      node = node.outer;
    }
    ++target.useCounter;
  }

  DartType getSubstitute(TypeParameter variable) {
    var environment = this;
    while (environment != null) {
      DartType replacement = environment.lookup(variable, covariantContext);
      if (replacement != null) {
        bumpCountersUntil(environment);
        return replacement;
      }
      environment = environment.outer;
    }
    return null;
  }

  DartType visitTypeParameterType(TypeParameterType node) {
    DartType replacement = getSubstitute(node.parameter);
    if (replacement is InvalidType) return replacement;
    if (replacement != null) {
      return replacement.withDeclaredNullability(
          combineNullabilitiesForSubstitution(
              replacement.nullability, node.nullability));
    }
    return node;
  }
}

class _DeepTypeSubstitutor extends _InnerTypeSubstitutor {
  int depth = 0;
  bool isInfinite = false;

  _DeepTypeSubstitutor(Map<TypeParameter, DartType> substitution,
      [_DeepTypeSubstitutor outer])
      : super(outer) {
    this.substitution.addAll(substitution);
  }

  @override
  _DeepTypeSubstitutor newInnerEnvironment() {
    return new _DeepTypeSubstitutor(<TypeParameter, DartType>{}, this);
  }

  @override
  DartType visitTypeParameterType(TypeParameterType node) {
    DartType replacement = getSubstitute(node.parameter);
    if (replacement == null) return node;
    if (isInfinite) return replacement;
    ++depth;
    if (depth > substitution.length) {
      isInfinite = true;
      --depth;
      return replacement;
    } else {
      replacement = visit(replacement);
      // Update type to the fully fleshed-out type.
      substitution[node.parameter] = replacement;
      --depth;
      return replacement;
    }
  }
}

class _TypeUnification {
  // Acyclic invariant: There are no cycles in the map, that is, all types can
  //   be resolved to finite types by substituting all contained type variables.
  //
  // The acyclic invariant holds everywhere except during cycle detection.
  //
  // It is not checked that the substitution satisfies the bound on the type
  // parameter.
  final Map<TypeParameter, DartType> substitution = <TypeParameter, DartType>{};

  /// Variables that may be assigned freely in order to obtain unification.
  ///
  /// These are sometimes referred to as existentially quantified variables.
  final Set<TypeParameter> quantifiedVariables;

  /// Variables that are bound by a function type inside one of the types.
  /// These may not occur in a substitution, because these variables are not in
  /// scope at the existentially quantified variables.
  ///
  /// For example, suppose we are trying to satisfy the equation:
  ///
  ///     ∃S. <E>(E, S) => E  =  <E>(E, E) => E
  ///
  /// That is, we must choose `S` such that the generic function type
  /// `<E>(E, S) => E` becomes `<E>(E, E) => E`.  Choosing `S = E` is not a
  /// valid solution, because `E` is not in scope where `S` is quantified.
  /// The two function types cannot be unified.
  final Set<TypeParameter> _universallyQuantifiedVariables =
      new Set<TypeParameter>();

  bool success = true;

  _TypeUnification(DartType type1, DartType type2, this.quantifiedVariables) {
    _unify(type1, type2);
    if (success && substitution.length >= 2) {
      for (var key in substitution.keys) {
        substitution[key] = substituteDeep(substitution[key], substitution);
      }
    }
  }

  DartType _substituteHead(TypeParameterType type) {
    for (int i = 0; i <= substitution.length; ++i) {
      DartType nextType = substitution[type.parameter];
      if (nextType == null) return type;
      if (nextType is TypeParameterType) {
        type = nextType;
      } else {
        return nextType;
      }
    }
    // The cycle should have been found by _trySubstitution when the cycle
    // was created.
    throw 'Unexpected cycle found during unification';
  }

  bool _unify(DartType type1, DartType type2) {
    if (!success) return false;
    type1 = type1 is TypeParameterType ? _substituteHead(type1) : type1;
    type2 = type2 is TypeParameterType ? _substituteHead(type2) : type2;
    if (type1 is DynamicType && type2 is DynamicType) return true;
    if (type1 is VoidType && type2 is VoidType) return true;
    if (type1 is InvalidType && type2 is InvalidType) return true;
    if (type1 is BottomType && type2 is BottomType) return true;
    if (type1 is InterfaceType && type2 is InterfaceType) {
      if (type1.classNode != type2.classNode ||
          type1.nullability != type2.nullability) {
        return _fail();
      }
      assert(type1.typeArguments.length == type2.typeArguments.length);
      for (int i = 0; i < type1.typeArguments.length; ++i) {
        if (!_unify(type1.typeArguments[i], type2.typeArguments[i])) {
          return false;
        }
      }
      return true;
    }
    if (type1 is FunctionType && type2 is FunctionType) {
      if (type1.typeParameters.length != type2.typeParameters.length ||
          type1.positionalParameters.length !=
              type2.positionalParameters.length ||
          type1.namedParameters.length != type2.namedParameters.length ||
          type1.requiredParameterCount != type2.requiredParameterCount ||
          type1.nullability != type2.nullability) {
        return _fail();
      }
      // When unifying two generic functions, transform the equation like this:
      //
      //    ∃S. <E>(fn1) = <T>(fn2)
      //      ==>
      //    ∃S. ∀G. fn1[G/E] = fn2[G/T]
      //
      // That is, assume some fixed identical choice of type parameters for both
      // functions and try to unify the instantiated function types.
      assert(!type1.typeParameters.any(quantifiedVariables.contains));
      assert(!type2.typeParameters.any(quantifiedVariables.contains));
      var leftInstance = <TypeParameter, DartType>{};
      var rightInstance = <TypeParameter, DartType>{};
      for (int i = 0; i < type1.typeParameters.length; ++i) {
        var instantiator = new TypeParameter(type1.typeParameters[i].name);
        var instantiatorType = new TypeParameterType.forAlphaRenaming(
            type1.typeParameters[i], instantiator);
        leftInstance[type1.typeParameters[i]] = instantiatorType;
        rightInstance[type2.typeParameters[i]] = instantiatorType;
        _universallyQuantifiedVariables.add(instantiator);
      }
      for (int i = 0; i < type1.typeParameters.length; ++i) {
        var left = substitute(type1.typeParameters[i].bound, leftInstance);
        var right = substitute(type2.typeParameters[i].bound, rightInstance);
        if (!_unify(left, right)) return false;
      }
      for (int i = 0; i < type1.positionalParameters.length; ++i) {
        var left = substitute(type1.positionalParameters[i], leftInstance);
        var right = substitute(type2.positionalParameters[i], rightInstance);
        if (!_unify(left, right)) return false;
      }
      for (int i = 0; i < type1.namedParameters.length; ++i) {
        if (type1.namedParameters[i].name != type2.namedParameters[i].name) {
          return false;
        }
        var left = substitute(type1.namedParameters[i].type, leftInstance);
        var right = substitute(type2.namedParameters[i].type, rightInstance);
        if (!_unify(left, right)) return false;
      }
      var leftReturn = substitute(type1.returnType, leftInstance);
      var rightReturn = substitute(type2.returnType, rightInstance);
      if (!_unify(leftReturn, rightReturn)) return false;
      return true;
    }
    if (type1 is TypeParameterType &&
        type2 is TypeParameterType &&
        type1.parameter == type2.parameter &&
        type1.declaredNullability == type2.declaredNullability) {
      return true;
    }
    if (type1 is TypeParameterType &&
        quantifiedVariables.contains(type1.parameter)) {
      return _trySubstitution(type1.parameter, type2);
    }
    if (type2 is TypeParameterType &&
        quantifiedVariables.contains(type2.parameter)) {
      return _trySubstitution(type2.parameter, type1);
    }
    return _fail();
  }

  bool _trySubstitution(TypeParameter variable, DartType type) {
    if (containsTypeVariable(type, _universallyQuantifiedVariables)) {
      return _fail();
    }
    // Set the plain substitution first and then generate the deep
    // substitution to detect cycles.
    substitution[variable] = type;
    DartType deepSubstitute = substituteDeep(type, substitution);
    if (deepSubstitute == null) return _fail();
    substitution[variable] = deepSubstitute;
    return true;
  }

  bool _fail() {
    return success = false;
  }
}

class _OccurrenceVisitor implements DartTypeVisitor<bool> {
  final Set<TypeParameter> variables;

  /// Helper function invoked on unknown implementers of [DartType].
  ///
  /// Its arguments are the unhandled type and the function that can be invoked
  /// from within the handler on parts of the unknown type to recursively call
  /// the visitor.  If not set, an exception is thrown then an unhandled
  /// implementer of [DartType] is encountered.
  final bool Function(DartType node, bool Function(DartType node) recursor)
      unhandledTypeHandler;

  _OccurrenceVisitor(this.variables, {this.unhandledTypeHandler});

  bool visit(DartType node) => node.accept(this);

  bool visitNamedType(NamedType node) {
    return visit(node.type);
  }

  bool defaultDartType(DartType node) {
    if (unhandledTypeHandler == null) {
      throw new UnsupportedError("Unsupported type '${node.runtimeType}'.");
    } else {
      return unhandledTypeHandler(node, visit);
    }
  }

  bool visitBottomType(BottomType node) => false;
  bool visitNeverType(NeverType node) => false;
  bool visitInvalidType(InvalidType node) => false;
  bool visitDynamicType(DynamicType node) => false;
  bool visitVoidType(VoidType node) => false;

  bool visitInterfaceType(InterfaceType node) {
    return node.typeArguments.any(visit);
  }

  bool visitFutureOrType(FutureOrType node) {
    return visit(node.typeArgument);
  }

  bool visitTypedefType(TypedefType node) {
    return node.typeArguments.any(visit);
  }

  bool visitFunctionType(FunctionType node) {
    return node.typeParameters.any(handleTypeParameter) ||
        node.positionalParameters.any(visit) ||
        node.namedParameters.any(visitNamedType) ||
        visit(node.returnType);
  }

  bool visitTypeParameterType(TypeParameterType node) {
    return variables == null || variables.contains(node.parameter);
  }

  bool handleTypeParameter(TypeParameter node) {
    assert(!variables.contains(node));
    if (node.bound.accept(this)) return true;
    if (node.defaultType == null) return false;
    return node.defaultType.accept(this);
  }
}

class _FreeFunctionTypeVariableVisitor implements DartTypeVisitor<bool> {
  final Set<TypeParameter> variables = new Set<TypeParameter>();

  _FreeFunctionTypeVariableVisitor();

  bool visit(DartType node) => node.accept(this);

  bool defaultDartType(DartType node) {
    throw new UnsupportedError("Unsupported type $node (${node.runtimeType}.");
  }

  bool visitNamedType(NamedType node) {
    return visit(node.type);
  }

  bool visitBottomType(BottomType node) => false;
  bool visitNeverType(NeverType node) => false;
  bool visitInvalidType(InvalidType node) => false;
  bool visitDynamicType(DynamicType node) => false;
  bool visitVoidType(VoidType node) => false;

  bool visitInterfaceType(InterfaceType node) {
    return node.typeArguments.any(visit);
  }

  bool visitFutureOrType(FutureOrType node) {
    return visit(node.typeArgument);
  }

  bool visitTypedefType(TypedefType node) {
    return node.typeArguments.any(visit);
  }

  bool visitFunctionType(FunctionType node) {
    variables.addAll(node.typeParameters);
    bool result = node.typeParameters.any(handleTypeParameter) ||
        node.positionalParameters.any(visit) ||
        node.namedParameters.any(visitNamedType) ||
        visit(node.returnType);
    variables.removeAll(node.typeParameters);
    return result;
  }

  bool visitTypeParameterType(TypeParameterType node) {
    return node.parameter.parent == null && !variables.contains(node.parameter);
  }

  bool handleTypeParameter(TypeParameter node) {
    assert(variables.contains(node));
    if (node.bound.accept(this)) return true;
    if (node.defaultType == null) return false;
    return node.defaultType.accept(this);
  }
}

Nullability uniteNullabilities(Nullability a, Nullability b) {
  if (a == Nullability.nullable || b == Nullability.nullable) {
    return Nullability.nullable;
  }
  if (a == Nullability.legacy || b == Nullability.legacy) {
    return Nullability.legacy;
  }
  if (a == Nullability.undetermined || b == Nullability.undetermined) {
    return Nullability.undetermined;
  }
  return Nullability.nonNullable;
}

Nullability intersectNullabilities(Nullability a, Nullability b) {
  if (a == Nullability.nonNullable || b == Nullability.nonNullable) {
    return Nullability.nonNullable;
  }
  if (a == Nullability.undetermined || b == Nullability.undetermined) {
    return Nullability.undetermined;
  }
  if (a == Nullability.legacy || b == Nullability.legacy) {
    return Nullability.legacy;
  }
  return Nullability.nullable;
}

/// Tells if a [DartType] is primitive or not.
///
/// This is useful in recursive algorithms over types where the primitive types
/// are the base cases of the recursion.  According to the visitor a primitive
/// type is any [DartType] that doesn't include other [DartType]s as its parts.
/// The nullability attributes don't affect the primitiveness of a type.
bool isPrimitiveDartType(DartType type,
    {bool Function(DartType unhandledType) unhandledTypeHandler}) {
  return type.accept(const _PrimitiveTypeVerifier());
}

/// Visitors that implements the algorithm of [isPrimitiveDartType].
///
/// The visitor is shallow, that is, it doesn't recurse over the given type due
/// to its purpose.  The reason for having a visitor is to make the need for an
/// update visible when a new implementer of [DartType] is introduced in Kernel.
class _PrimitiveTypeVerifier implements DartTypeVisitor<bool> {
  const _PrimitiveTypeVerifier();

  @override
  bool defaultDartType(DartType node) {
    throw new UnsupportedError(
        "Unsupported operation: _PrimitiveTypeVerifier(${node.runtimeType})");
  }

  @override
  bool visitBottomType(BottomType node) => true;

  @override
  bool visitDynamicType(DynamicType node) => true;

  @override
  bool visitFunctionType(FunctionType node) {
    // Function types are never primitive because they at least include the
    // return types as their parts.
    return false;
  }

  @override
  bool visitFutureOrType(FutureOrType node) => false;

  @override
  bool visitInterfaceType(InterfaceType node) {
    return node.typeArguments.isEmpty;
  }

  @override
  bool visitInvalidType(InvalidType node) {
    throw new UnsupportedError(
        "Unsupported operation: _PrimitiveTypeVerifier(InvalidType).");
  }

  @override
  bool visitNeverType(NeverType node) => true;

  @override
  bool visitTypeParameterType(TypeParameterType node) {
    return node.promotedBound == null;
  }

  @override
  bool visitTypedefType(TypedefType node) {
    return node.typeArguments.isEmpty;
  }

  @override
  bool visitVoidType(VoidType node) => true;
}
