// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.type_algebra;

import 'ast.dart';
import 'core_types.dart';
import 'src/replacement_visitor.dart';

/// Returns all free type variables in [type].
///
/// Returns the set of all [TypeParameter]s that are referred to by a
/// [TypeParameterType] in [type] that are not bound to an enclosing
/// [FunctionType].
Set<TypeParameter> allFreeTypeVariables(DartType type) {
  _AllFreeTypeVariablesVisitor visitor = new _AllFreeTypeVariablesVisitor();
  visitor.visit(type);
  return visitor.freeTypeVariables;
}

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
  Map<TypeParameter, DartType> result = <TypeParameter, DartType>{};
  for (TypeParameter parameter in host.typeParameters) {
    result[parameter] = const DynamicType();
  }
  for (TypeParameter parameter in host.typeParameters) {
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
DartType? substituteDeep(
    DartType type, Map<TypeParameter, DartType> substitution) {
  if (substitution.isEmpty) return type;
  _DeepTypeSubstitutor substitutor = new _DeepTypeSubstitutor(substitution);
  DartType result = substitutor.visit(type);
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
    {bool Function(DartType type, bool Function(DartType type) recursor)?
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

/// Returns `true` if [type] contains any free type variables
///
/// Returns `true` if [type] contains a [TypeParameterType] that doesn't refer
/// to an enclosing generic [FunctionType] within [type].
bool containsFreeTypeVariables(DartType type,
    {Set<TypeParameter>? boundVariables}) {
  return new _FreeTypeVariableVisitor(boundVariables: boundVariables)
      .visit(type);
}

/// Generates a fresh copy of the given type parameters, with their bounds
/// substituted to reference the new parameters.
///
/// The returned object contains the fresh type parameter list as well as a
/// mapping to be used for replacing other types to use the new type parameters.
FreshTypeParameters getFreshTypeParameters(List<TypeParameter> typeParameters) {
  List<TypeParameter> freshParameters = new List<TypeParameter>.generate(
      typeParameters.length,
      (i) => new TypeParameter(typeParameters[i].name)
        ..flags = typeParameters[i].flags,
      growable: true);
  List<DartType> freshTypeArguments =
      new List<DartType>.generate(typeParameters.length, (int i) {
    return new TypeParameterType.forAlphaRenaming(
        typeParameters[i], freshParameters[i]);
  }, growable: true);
  Substitution substitution =
      Substitution.fromPairs(typeParameters, freshTypeArguments);
  for (int i = 0; i < typeParameters.length; ++i) {
    TypeParameter typeParameter = typeParameters[i];
    TypeParameter freshTypeParameter = freshParameters[i];

    freshTypeParameter.bound = substitution.substituteType(typeParameter.bound);
    freshTypeParameter.defaultType =
        substitution.substituteType(typeParameter.defaultType);
    freshTypeParameter.variance =
        typeParameter.isLegacyCovariant ? null : typeParameter.variance;
    // Annotations on a type parameter are specific to the declaration of the
    // type parameter, rather than the type parameter as such, and therefore
    // should not be copied here.
  }
  return new FreshTypeParameters(
      freshParameters, freshTypeArguments, substitution);
}

class FreshTypeParameters {
  /// The newly created type parameters.
  final List<TypeParameter> freshTypeParameters;

  /// List of [TypeParameterType]s for [TypeParameter].
  final List<DartType> freshTypeArguments;

  /// Substitution from the original type parameters to [freshTypeArguments].
  final Substitution substitution;

  FreshTypeParameters(
      this.freshTypeParameters, this.freshTypeArguments, this.substitution);

  FunctionType applyToFunctionType(FunctionType type) {
    return new FunctionType(type.positionalParameters.map(substitute).toList(),
        substitute(type.returnType), type.nullability,
        namedParameters: type.namedParameters.map(substituteNamed).toList(),
        typeParameters: freshTypeParameters,
        requiredParameterCount: type.requiredParameterCount);
  }

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

  bool get isEmpty => identical(this, empty);

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

  /// Substitutes the type parameters on the inline class of [type] with the
  /// type arguments provided in [type].
  static Substitution fromInlineType(InlineType type) {
    if (type.typeArguments.isEmpty) return _NullSubstitution.instance;
    return fromMap(new Map<TypeParameter, DartType>.fromIterables(
        type.inlineClass.typeParameters, type.typeArguments));
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
    Map<TypeParameter, DartType> upper = <TypeParameter, DartType>{};
    for (TypeParameter parameter in class_.typeParameters) {
      upper[parameter] = const DynamicType();
    }
    for (TypeParameter parameter in class_.typeParameters) {
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
  /// searched for occurrences of `G`.
  static Substitution combine(Substitution first, Substitution second) {
    if (first == _NullSubstitution.instance) return second;
    if (second == _NullSubstitution.instance) return first;
    return new _CombinedSubstitution(first, second);
  }

  /// Returns the substitution for [parameter]
  DartType? getSubstitute(TypeParameter parameter, bool upperBound);

  DartType substituteType(DartType node, {bool contravariant = false}) {
    return new _TopSubstitutor(this, contravariant).visit(node);
  }

  Supertype substituteSupertype(Supertype node) {
    return new _TopSubstitutor(this, false).visitSupertype(node);
  }
}

class _AllFreeTypeVariablesVisitor implements DartTypeVisitor<void> {
  final Set<TypeParameter> boundVariables = {};

  final Set<TypeParameter> freeTypeVariables = {};

  void visit(DartType node) => node.accept(this);

  @override
  bool defaultDartType(DartType node) {
    throw new UnsupportedError("Unsupported type $node (${node.runtimeType}).");
  }

  @override
  void visitNeverType(NeverType node) {}
  @override
  void visitNullType(NullType node) {}
  @override
  void visitInvalidType(InvalidType node) {}
  @override
  void visitDynamicType(DynamicType node) {}
  @override
  void visitVoidType(VoidType node) {}

  @override
  void visitInterfaceType(InterfaceType node) {
    for (DartType typeArgument in node.typeArguments) {
      typeArgument.accept(this);
    }
  }

  @override
  void visitExtensionType(ExtensionType node) {
    for (DartType typeArgument in node.typeArguments) {
      typeArgument.accept(this);
    }
  }

  @override
  void visitInlineType(InlineType node) {
    for (DartType typeArgument in node.typeArguments) {
      typeArgument.accept(this);
    }
  }

  @override
  void visitFutureOrType(FutureOrType node) {
    node.typeArgument.accept(this);
  }

  @override
  void visitTypedefType(TypedefType node) {
    for (DartType typeArgument in node.typeArguments) {
      typeArgument.accept(this);
    }
  }

  @override
  void visitFunctionType(FunctionType node) {
    boundVariables.addAll(node.typeParameters);
    for (TypeParameter typeParameter in node.typeParameters) {
      typeParameter.bound.accept(this);
      typeParameter.defaultType.accept(this);
    }
    for (DartType positionalParameter in node.positionalParameters) {
      positionalParameter.accept(this);
    }
    for (NamedType namedParameter in node.namedParameters) {
      namedParameter.type.accept(this);
    }
    node.returnType.accept(this);
    boundVariables.removeAll(node.typeParameters);
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
  void visitTypeParameterType(TypeParameterType node) {
    if (!boundVariables.contains(node.parameter)) {
      freeTypeVariables.add(node.parameter);
    }
  }

  @override
  void visitIntersectionType(IntersectionType node) {
    node.left.accept(this);
    node.right.accept(this);
  }
}

class _NullSubstitution extends Substitution {
  static const _NullSubstitution instance = const _NullSubstitution();

  const _NullSubstitution();

  @override
  DartType getSubstitute(TypeParameter parameter, bool upperBound) {
    return new TypeParameterType.forAlphaRenaming(parameter, parameter);
  }

  @override
  DartType substituteType(DartType node, {bool contravariant = false}) => node;

  @override
  Supertype substituteSupertype(Supertype node) => node;

  @override
  String toString() => "Substitution.empty";
}

class _MapSubstitution extends Substitution {
  final Map<TypeParameter, DartType> upper;
  final Map<TypeParameter, DartType> lower;

  _MapSubstitution(this.upper, this.lower);

  @override
  DartType? getSubstitute(TypeParameter parameter, bool upperBound) {
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

  @override
  DartType? lookup(TypeParameter parameter, bool upperBound) {
    return substitution.getSubstitute(parameter, upperBound);
  }

  @override
  TypeParameter freshTypeParameter(TypeParameter node) {
    throw 'Create a fresh environment first';
  }
}

class _ClassBottomSubstitution extends Substitution {
  final Class class_;

  _ClassBottomSubstitution(this.class_);

  @override
  DartType? getSubstitute(TypeParameter parameter, bool upperBound) {
    if (parameter.parent == class_) {
      return upperBound ? const NeverType.nonNullable() : const DynamicType();
    }
    return null;
  }
}

class _CombinedSubstitution extends Substitution {
  final Substitution first, second;

  _CombinedSubstitution(this.first, this.second);

  @override
  DartType? getSubstitute(TypeParameter parameter, bool upperBound) {
    return first.getSubstitute(parameter, upperBound) ??
        second.getSubstitute(parameter, upperBound);
  }
}

typedef bool TypeParameterFilter(TypeParameter P);

class _FilteredSubstitution extends Substitution {
  final Substitution base;
  final TypeParameterFilter filterFn;

  _FilteredSubstitution(this.base, this.filterFn);

  @override
  DartType? getSubstitute(TypeParameter parameter, bool upperBound) {
    return filterFn(parameter)
        ? base.getSubstitute(parameter, upperBound)
        : _NullSubstitution.instance.getSubstitute(parameter, upperBound);
  }
}

class _InnerTypeSubstitutor extends _TypeSubstitutor {
  final Map<TypeParameter, DartType> substitution = <TypeParameter, DartType>{};

  _InnerTypeSubstitutor(_TypeSubstitutor? outer) : super(outer);

  @override
  DartType? lookup(TypeParameter parameter, bool upperBound) {
    return substitution[parameter];
  }

  @override
  TypeParameter freshTypeParameter(TypeParameter node) {
    assert(
        !substitution.containsKey(node),
        "Function type variables cannot be substituted while still attached "
        "to the function. Perform substitution on "
        "`FunctionType.withoutTypeParameters` instead.");

    TypeParameter fresh = new TypeParameter(node.name)..flags = node.flags;
    TypeParameterType typeParameterType = substitution[node] =
        new TypeParameterType.forAlphaRenaming(node, fresh);
    fresh.bound = visit(node.bound);
    // ignore: unnecessary_null_comparison
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
/// `Nullability.undetermined`.  The table elements marked with N/A denote the
/// cases that should yield a type error before the substitution is performed.
///
/// a is nonNullable:
/// DartDocTest(
///   combineNullabilitiesForSubstitution(
///     Nullability.nonNullable, Nullability.nonNullable),
///   Nullability.nonNullable
/// )
/// DartDocTest(
///   combineNullabilitiesForSubstitution(
///     Nullability.nonNullable, Nullability.nullable),
///   Nullability.nullable
/// )
/// DartDocTest(
///   combineNullabilitiesForSubstitution(
///     Nullability.nonNullable, Nullability.legacy),
///   Nullability.legacy
/// )
/// DartDocTest(
///   combineNullabilitiesForSubstitution(
///     Nullability.nonNullable, Nullability.undetermined),
///   Nullability.nonNullable
/// )
///
/// a is nullable:
/// DartDocTest(
///   combineNullabilitiesForSubstitution(
///     Nullability.nullable, Nullability.nullable),
///   Nullability.nullable
/// )
/// DartDocTest(
///   combineNullabilitiesForSubstitution(
///     Nullability.nullable, Nullability.legacy),
///   Nullability.nullable
/// )
/// DartDocTest(
///   combineNullabilitiesForSubstitution(
///     Nullability.nullable, Nullability.undetermined),
///   Nullability.nullable
/// )
///
/// a is legacy:
/// DartDocTest(
///   combineNullabilitiesForSubstitution(
///     Nullability.legacy, Nullability.nonNullable),
///   Nullability.legacy
/// )
/// DartDocTest(
///   combineNullabilitiesForSubstitution(
///     Nullability.legacy, Nullability.nullable),
///   Nullability.nullable
/// )
/// DartDocTest(
///   combineNullabilitiesForSubstitution(
///     Nullability.legacy, Nullability.legacy),
///   Nullability.legacy
/// )
/// DartDocTest(
///   combineNullabilitiesForSubstitution(
///     Nullability.legacy, Nullability.undetermined),
///   Nullability.legacy
/// )
///
/// a is undetermined:
/// DartDocTest(
///   combineNullabilitiesForSubstitution(
///     Nullability.undetermined, Nullability.nullable),
///   Nullability.nullable
/// )
/// DartDocTest(
///   combineNullabilitiesForSubstitution(
///     Nullability.undetermined, Nullability.legacy),
///   Nullability.legacy
/// )
/// DartDocTest(
///   combineNullabilitiesForSubstitution(
///     Nullability.undetermined, Nullability.undetermined),
///   Nullability.undetermined
/// )
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

abstract class _TypeSubstitutor implements DartTypeVisitor<DartType> {
  final _TypeSubstitutor? outer;
  bool covariantContext = true;

  _TypeSubstitutor(this.outer)
      : covariantContext = outer == null ? true : outer.covariantContext;

  DartType? lookup(TypeParameter parameter, bool upperBound);

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
    List<DartType> typeArguments = node.typeArguments.map(visit).toList();
    if (useCounter == before) return node;
    return new Supertype(node.classNode, typeArguments);
  }

  NamedType visitNamedType(NamedType node) {
    int before = useCounter;
    DartType type = visit(node.type);
    if (useCounter == before) return node;
    return new NamedType(node.name, type, isRequired: node.isRequired);
  }

  DartType visit(DartType node) => node.accept(this);

  @override
  DartType defaultDartType(DartType node) => node;
  @override
  DartType visitInvalidType(InvalidType node) => node;
  @override
  DartType visitDynamicType(DynamicType node) => node;
  @override
  DartType visitVoidType(VoidType node) => node;
  @override
  DartType visitNeverType(NeverType node) => node;
  @override
  DartType visitNullType(NullType node) => node;

  @override
  DartType visitInterfaceType(InterfaceType node) {
    if (node.typeArguments.isEmpty) return node;
    int before = useCounter;
    List<DartType> typeArguments = node.typeArguments.map(visit).toList();
    if (useCounter == before) return node;
    return new InterfaceType.byReference(
        node.classReference, node.nullability, typeArguments);
  }

  @override
  DartType visitExtensionType(ExtensionType node) {
    if (node.typeArguments.isEmpty) return node;
    int before = useCounter;
    List<DartType> typeArguments = node.typeArguments.map(visit).toList();
    if (useCounter == before) return node;
    return new ExtensionType(node.extension, node.nullability, typeArguments);
  }

  @override
  DartType visitInlineType(InlineType node) {
    if (node.typeArguments.isEmpty) return node;
    int before = useCounter;
    List<DartType> typeArguments = node.typeArguments.map(visit).toList();
    if (useCounter == before) return node;
    return new InlineType(node.inlineClass, node.nullability, typeArguments);
  }

  @override
  DartType visitRecordType(RecordType node) {
    int before = useCounter;
    List<DartType> positional = node.positional.map(visit).toList();
    List<NamedType> named = node.named.map(visitNamedType).toList();
    if (useCounter == before) return node;
    return new RecordType(positional, named, node.nullability);
  }

  @override
  DartType visitFutureOrType(FutureOrType node) {
    int before = useCounter;
    DartType typeArgument = node.typeArgument.accept(this);
    if (useCounter == before) return node;

    // The top-level nullability of a FutureOr should remain the same, with the
    // exception of the case of [Nullability.undetermined].  In that case it
    // remains undetermined if the nullability of [typeArgument] is
    // undetermined, and otherwise it should become [Nullability.nonNullable].
    Nullability nullability;
    if (node.declaredNullability == Nullability.undetermined) {
      if (typeArgument.nullability == Nullability.undetermined) {
        nullability = Nullability.undetermined;
      } else {
        nullability = Nullability.nonNullable;
      }
    } else {
      nullability = node.declaredNullability;
    }
    return new FutureOrType(typeArgument, nullability);
  }

  @override
  DartType visitTypedefType(TypedefType node) {
    if (node.typeArguments.isEmpty) return node;
    int before = useCounter;
    List<DartType> typeArguments = node.typeArguments.map(visit).toList();
    if (useCounter == before) return node;
    return new TypedefType(node.typedefNode, node.nullability, typeArguments);
  }

  List<TypeParameter> freshTypeParameters(List<TypeParameter> parameters) {
    if (parameters.isEmpty) return const <TypeParameter>[];
    return parameters.map(freshTypeParameter).toList();
  }

  TypeParameter freshTypeParameter(TypeParameter node);

  @override
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
    _TypeSubstitutor inner =
        node.typeParameters.isEmpty ? this : newInnerEnvironment();
    int before = this.useCounter;
    // Invert the variance when translating parameters.
    inner.invertVariance();
    List<TypeParameter> typeParameters =
        inner.freshTypeParameters(node.typeParameters);
    List<DartType> positionalParameters = node.positionalParameters.isEmpty
        ? const <DartType>[]
        : node.positionalParameters.map(inner.visit).toList();
    List<NamedType> namedParameters = node.namedParameters.isEmpty
        ? const <NamedType>[]
        : node.namedParameters.map(inner.visitNamedType).toList();
    inner.invertVariance();
    DartType returnType = inner.visit(node.returnType);
    if (this.useCounter == before) return node;
    return new FunctionType(positionalParameters, returnType, node.nullability,
        namedParameters: namedParameters,
        typeParameters: typeParameters,
        requiredParameterCount: node.requiredParameterCount);
  }

  void bumpCountersUntil(_TypeSubstitutor target) {
    _TypeSubstitutor? node = this;
    while (node != target) {
      ++node!.useCounter;
      node = node.outer;
    }
    ++target.useCounter;
  }

  DartType? getSubstitute(TypeParameter variable) {
    _TypeSubstitutor? environment = this;
    while (environment != null) {
      DartType? replacement = environment.lookup(variable, covariantContext);
      if (replacement != null) {
        bumpCountersUntil(environment);
        return replacement;
      }
      environment = environment.outer;
    }
    return null;
  }

  @override
  DartType visitTypeParameterType(TypeParameterType node) {
    DartType? replacement = getSubstitute(node.parameter);
    if (replacement is InvalidType) return replacement;
    if (replacement != null) {
      return replacement.withDeclaredNullability(
          combineNullabilitiesForSubstitution(
              replacement.nullability, node.nullability));
    }
    return node;
  }

  @override
  DartType visitIntersectionType(IntersectionType node) {
    return node.left.accept(this);
  }
}

class _DeepTypeSubstitutor extends _InnerTypeSubstitutor {
  int depth = 0;
  bool isInfinite = false;

  _DeepTypeSubstitutor(Map<TypeParameter, DartType> substitution,
      [_DeepTypeSubstitutor? outer])
      : super(outer) {
    this.substitution.addAll(substitution);
  }

  @override
  _DeepTypeSubstitutor newInnerEnvironment() {
    return new _DeepTypeSubstitutor(<TypeParameter, DartType>{}, this);
  }

  @override
  DartType visitTypeParameterType(TypeParameterType node) {
    DartType? replacement = getSubstitute(node.parameter);
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

class _OccurrenceVisitor implements DartTypeVisitor<bool> {
  final Set<TypeParameter> variables;

  /// Helper function invoked on unknown implementers of [DartType].
  ///
  /// Its arguments are the unhandled type and the function that can be invoked
  /// from within the handler on parts of the unknown type to recursively call
  /// the visitor.  If not set, an exception is thrown then an unhandled
  /// implementer of [DartType] is encountered.
  final bool Function(DartType node, bool Function(DartType node) recursor)?
      unhandledTypeHandler;

  _OccurrenceVisitor(this.variables, {this.unhandledTypeHandler});

  bool visit(DartType node) => node.accept(this);

  bool visitNamedType(NamedType node) {
    return visit(node.type);
  }

  @override
  bool defaultDartType(DartType node) {
    if (unhandledTypeHandler == null) {
      throw new UnsupportedError("Unsupported type '${node.runtimeType}'.");
    } else {
      return unhandledTypeHandler!(node, visit);
    }
  }

  @override
  bool visitNeverType(NeverType node) => false;
  @override
  bool visitNullType(NullType node) => false;
  @override
  bool visitInvalidType(InvalidType node) => false;
  @override
  bool visitDynamicType(DynamicType node) => false;
  @override
  bool visitVoidType(VoidType node) => false;

  @override
  bool visitInterfaceType(InterfaceType node) {
    return node.typeArguments.any(visit);
  }

  @override
  bool visitExtensionType(ExtensionType node) {
    return node.typeArguments.any(visit);
  }

  @override
  bool visitInlineType(InlineType node) {
    return node.typeArguments.any(visit);
  }

  @override
  bool visitFutureOrType(FutureOrType node) {
    return visit(node.typeArgument);
  }

  @override
  bool visitTypedefType(TypedefType node) {
    return node.typeArguments.any(visit);
  }

  @override
  bool visitFunctionType(FunctionType node) {
    return node.typeParameters.any(handleTypeParameter) ||
        node.positionalParameters.any(visit) ||
        node.namedParameters.any(visitNamedType) ||
        visit(node.returnType);
  }

  @override
  bool visitRecordType(RecordType node) {
    return node.positional.any(visit) || node.named.any(visitNamedType);
  }

  @override
  bool visitTypeParameterType(TypeParameterType node) {
    return variables.contains(node.parameter);
  }

  @override
  bool visitIntersectionType(IntersectionType node) {
    return visit(node.left) || visit(node.right);
  }

  bool handleTypeParameter(TypeParameter node) {
    assert(!variables.contains(node));
    if (node.bound.accept(this)) return true;
    // ignore: unnecessary_null_comparison
    if (node.defaultType == null) return false;
    return node.defaultType.accept(this);
  }
}

class _FreeFunctionTypeVariableVisitor implements DartTypeVisitor<bool> {
  final Set<TypeParameter> variables = new Set<TypeParameter>();

  _FreeFunctionTypeVariableVisitor();

  bool visit(DartType node) => node.accept(this);

  @override
  bool defaultDartType(DartType node) {
    throw new UnsupportedError("Unsupported type $node (${node.runtimeType}).");
  }

  bool visitNamedType(NamedType node) {
    return visit(node.type);
  }

  @override
  bool visitNeverType(NeverType node) => false;
  @override
  bool visitNullType(NullType node) => false;
  @override
  bool visitInvalidType(InvalidType node) => false;
  @override
  bool visitDynamicType(DynamicType node) => false;
  @override
  bool visitVoidType(VoidType node) => false;

  @override
  bool visitInterfaceType(InterfaceType node) {
    return node.typeArguments.any(visit);
  }

  @override
  bool visitExtensionType(ExtensionType node) {
    return node.typeArguments.any(visit);
  }

  @override
  bool visitInlineType(InlineType node) {
    return node.typeArguments.any(visit);
  }

  @override
  bool visitFutureOrType(FutureOrType node) {
    return visit(node.typeArgument);
  }

  @override
  bool visitTypedefType(TypedefType node) {
    return node.typeArguments.any(visit);
  }

  @override
  bool visitFunctionType(FunctionType node) {
    variables.addAll(node.typeParameters);
    bool result = node.typeParameters.any(handleTypeParameter) ||
        node.positionalParameters.any(visit) ||
        node.namedParameters.any(visitNamedType) ||
        visit(node.returnType);
    variables.removeAll(node.typeParameters);
    return result;
  }

  @override
  bool visitRecordType(RecordType node) {
    return node.positional.any(visit) || node.named.any(visitNamedType);
  }

  @override
  bool visitTypeParameterType(TypeParameterType node) {
    return node.parameter.parent == null && !variables.contains(node.parameter);
  }

  @override
  bool visitIntersectionType(IntersectionType node) {
    return visit(node.left) || visit(node.right);
  }

  bool handleTypeParameter(TypeParameter node) {
    assert(variables.contains(node));
    if (node.bound.accept(this)) return true;
    // ignore: unnecessary_null_comparison
    if (node.defaultType == null) return false;
    return node.defaultType.accept(this);
  }
}

class _FreeTypeVariableVisitor implements DartTypeVisitor<bool> {
  final Set<TypeParameter> boundVariables;

  _FreeTypeVariableVisitor({Set<TypeParameter>? boundVariables})
      : this.boundVariables = boundVariables ?? <TypeParameter>{};

  bool visit(DartType node) => node.accept(this);

  @override
  bool defaultDartType(DartType node) {
    throw new UnsupportedError("Unsupported type $node (${node.runtimeType}.");
  }

  bool visitNamedType(NamedType node) {
    return visit(node.type);
  }

  @override
  bool visitNeverType(NeverType node) => false;
  @override
  bool visitNullType(NullType node) => false;
  @override
  bool visitInvalidType(InvalidType node) => false;
  @override
  bool visitDynamicType(DynamicType node) => false;
  @override
  bool visitVoidType(VoidType node) => false;

  @override
  bool visitInterfaceType(InterfaceType node) {
    return node.typeArguments.any(visit);
  }

  @override
  bool visitExtensionType(ExtensionType node) {
    return node.typeArguments.any(visit);
  }

  @override
  bool visitInlineType(InlineType node) {
    return node.typeArguments.any(visit);
  }

  @override
  bool visitFutureOrType(FutureOrType node) {
    return visit(node.typeArgument);
  }

  @override
  bool visitTypedefType(TypedefType node) {
    return node.typeArguments.any(visit);
  }

  @override
  bool visitFunctionType(FunctionType node) {
    boundVariables.addAll(node.typeParameters);
    bool result = node.typeParameters.any(handleTypeParameter) ||
        node.positionalParameters.any(visit) ||
        node.namedParameters.any(visitNamedType) ||
        visit(node.returnType);
    boundVariables.removeAll(node.typeParameters);
    return result;
  }

  @override
  bool visitRecordType(RecordType node) {
    return node.positional.any(visit) || node.named.any(visitNamedType);
  }

  @override
  bool visitTypeParameterType(TypeParameterType node) {
    return !boundVariables.contains(node.parameter);
  }

  @override
  bool visitIntersectionType(IntersectionType node) {
    return visit(node.left) && visit(node.right);
  }

  bool handleTypeParameter(TypeParameter node) {
    assert(boundVariables.contains(node));
    if (node.bound.accept(this)) return true;
    // ignore: unnecessary_null_comparison
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
bool isPrimitiveDartType(DartType type) {
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
  bool visitDynamicType(DynamicType node) => true;

  @override
  bool visitFunctionType(FunctionType node) {
    // Function types are never primitive because they at least include the
    // return types as their parts.
    return false;
  }

  @override
  bool visitRecordType(RecordType node) {
    return node.positional.isNotEmpty || node.named.isNotEmpty;
  }

  @override
  bool visitFutureOrType(FutureOrType node) => false;

  @override
  bool visitInterfaceType(InterfaceType node) {
    return node.typeArguments.isEmpty;
  }

  @override
  bool visitExtensionType(ExtensionType node) {
    return node.typeArguments.isEmpty;
  }

  @override
  bool visitInlineType(InlineType node) {
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
  bool visitNullType(NullType node) => true;

  @override
  bool visitTypeParameterType(TypeParameterType node) => true;

  @override
  bool visitIntersectionType(IntersectionType node) => false;

  @override
  bool visitTypedefType(TypedefType node) {
    return node.typeArguments.isEmpty;
  }

  @override
  bool visitVoidType(VoidType node) => true;
}

/// Removes the application of ? or * from the type.
///
/// Some types are nullable even without the application of the nullable type
/// constructor at the top level, for example, Null or FutureOr<int?>.
// TODO(cstefantsova): Remove [coreTypes] parameter when NullType is landed.
DartType unwrapNullabilityConstructor(DartType type, CoreTypes coreTypes) {
  return type.accept1(const _NullabilityConstructorUnwrapper(), coreTypes);
}

/// Implementation of [unwrapNullabilityConstructor] as a visitor.
///
/// Implementing the function as a visitor makes the necessity of supporting a
/// new implementation of [DartType] visible at compile time.
// TODO(cstefantsova): Remove CoreTypes as the second argument when NullType is
// landed.
class _NullabilityConstructorUnwrapper
    implements DartTypeVisitor1<DartType, CoreTypes> {
  const _NullabilityConstructorUnwrapper();

  @override
  DartType defaultDartType(DartType node, CoreTypes coreTypes) {
    throw new UnsupportedError("Unsupported operation: "
        "_NullabilityConstructorUnwrapper(${node.runtimeType})");
  }

  @override
  DartType visitDynamicType(DynamicType node, CoreTypes coreTypes) => node;

  @override
  DartType visitFunctionType(FunctionType node, CoreTypes coreTypes) {
    return node.withDeclaredNullability(Nullability.nonNullable);
  }

  @override
  DartType visitRecordType(RecordType node, CoreTypes coreTypes) {
    return node.withDeclaredNullability(Nullability.nonNullable);
  }

  @override
  DartType visitFutureOrType(FutureOrType node, CoreTypes coreTypes) {
    return node.withDeclaredNullability(Nullability.nonNullable);
  }

  @override
  DartType visitInterfaceType(InterfaceType node, CoreTypes coreTypes) {
    return node.withDeclaredNullability(Nullability.nonNullable);
  }

  @override
  DartType visitExtensionType(ExtensionType node, CoreTypes coreTypes) {
    return node.withDeclaredNullability(Nullability.nonNullable);
  }

  @override
  DartType visitInlineType(InlineType node, CoreTypes coreTypes) {
    return node.withDeclaredNullability(Nullability.nonNullable);
  }

  @override
  DartType visitInvalidType(InvalidType node, CoreTypes coreTypes) => node;

  @override
  DartType visitNeverType(NeverType node, CoreTypes coreTypes) {
    return node.withDeclaredNullability(Nullability.nonNullable);
  }

  @override
  DartType visitNullType(NullType node, CoreTypes coreTypes) => node;

  @override
  DartType visitTypeParameterType(TypeParameterType node, CoreTypes coreTypes) {
    return node.withDeclaredNullability(
        TypeParameterType.computeNullabilityFromBound(node.parameter));
  }

  @override
  DartType visitIntersectionType(IntersectionType node, CoreTypes coreTypes) {
    // Intersection types don't have their own nullabilities.
    return node;
  }

  @override
  DartType visitTypedefType(TypedefType node, CoreTypes coreTypes) {
    return node.withDeclaredNullability(Nullability.nonNullable);
  }

  @override
  DartType visitVoidType(VoidType node, CoreTypes coreTypes) => node;
}

abstract class NullabilityAwareTypeVariableEliminatorBase
    extends ReplacementVisitor {
  final DartType bottomType;
  final DartType topType;
  final DartType topFunctionType;
  late bool _isLeastClosure;

  NullabilityAwareTypeVariableEliminatorBase(
      {required this.bottomType,
      required this.topType,
      required this.topFunctionType})
      :
        // ignore: unnecessary_null_comparison
        assert(bottomType != null),
        // ignore: unnecessary_null_comparison
        assert(topType != null),
        // ignore: unnecessary_null_comparison
        assert(topFunctionType != null);

  bool containsTypeVariablesToEliminate(DartType type);

  bool isTypeVariableToEliminate(TypeParameter typeParameter);

  /// Returns a subtype of [type] for all variables to be eliminated.
  DartType eliminateToLeast(DartType type) {
    _isLeastClosure = true;
    return type.accept1(this, Variance.covariant) ?? type;
  }

  /// Returns a supertype of [type] for all variables to be eliminated.
  DartType eliminateToGreatest(DartType type) {
    _isLeastClosure = false;
    return type.accept1(this, Variance.covariant) ?? type;
  }

  DartType getTypeParameterReplacement(int variance) {
    bool isCovariant = variance == Variance.covariant;
    return _isLeastClosure && isCovariant || (!_isLeastClosure && !isCovariant)
        ? bottomType
        : topType;
  }

  DartType getFunctionReplacement(int variance) {
    bool isCovariant = variance == Variance.covariant;
    return _isLeastClosure && isCovariant || (!_isLeastClosure && !isCovariant)
        ? bottomType
        : topFunctionType;
  }

  @override
  DartType? visitFunctionType(FunctionType node, int variance) {
    // - if `S` is
    //   `T Function<X0 extends B0, ...., Xk extends Bk>(T0 x0, ...., Tn xn,
    //       [Tn+1 xn+1, ..., Tm xm])`
    //   or `T Function<X0 extends B0, ...., Xk extends Bk>(T0 x0, ...., Tn xn,
    //       {Tn+1 xn+1, ..., Tm xm})`
    //   and `L` contains any free type variables from any of the `Bi`:
    //  - The least closure of `S` with respect to `L` is `Never`
    //  - The greatest closure of `S` with respect to `L` is `Function`
    if (node.typeParameters.isNotEmpty) {
      for (TypeParameter typeParameter in node.typeParameters) {
        if (containsTypeVariablesToEliminate(typeParameter.bound)) {
          return getFunctionReplacement(variance);
        }
      }
    }
    return super.visitFunctionType(node, variance);
  }

  @override
  DartType? visitTypeParameterType(TypeParameterType node, int variance) {
    if (isTypeVariableToEliminate(node.parameter)) {
      return getTypeParameterReplacement(variance);
    }
    return super.visitTypeParameterType(node, variance);
  }
}

/// Eliminates specified free type parameters in a type.
///
/// Use this class when only a specific subset of unbound variables in a type
/// should be substituted with one of [bottomType], [topType], or
/// [topFunctionType].  For example, running a
/// `NullabilityAwareTypeVariableEliminatorBase({T}, Never, Object?,
/// Function).eliminateToLeast` on type `T Function<S>(S s, R r)` will return
/// `Never Function<S>(S s, R r)`.
///
/// The algorithm for elimination of type variables is described in
/// https://github.com/dart-lang/language/pull/957
class NullabilityAwareTypeVariableEliminator
    extends NullabilityAwareTypeVariableEliminatorBase {
  final Set<TypeParameter> eliminationTargets;
  final bool Function(DartType type, bool Function(DartType type) recursor)?
      unhandledTypeHandler;

  NullabilityAwareTypeVariableEliminator(
      {required this.eliminationTargets,
      required DartType bottomType,
      required DartType topType,
      required DartType topFunctionType,
      this.unhandledTypeHandler})
      // ignore: unnecessary_null_comparison
      : assert(eliminationTargets != null),
        // ignore: unnecessary_null_comparison
        assert(bottomType != null),
        // ignore: unnecessary_null_comparison
        assert(topType != null),
        // ignore: unnecessary_null_comparison
        assert(topFunctionType != null),
        super(
            bottomType: bottomType,
            topType: topType,
            topFunctionType: topFunctionType);

  @override
  bool containsTypeVariablesToEliminate(DartType type) {
    return containsTypeVariable(type, eliminationTargets,
        unhandledTypeHandler: unhandledTypeHandler);
  }

  @override
  bool isTypeVariableToEliminate(TypeParameter typeParameter) {
    return eliminationTargets.contains(typeParameter);
  }
}

/// Eliminates all free type parameters in a type.
///
/// Use this class when all unbound variables in a type should be substituted
/// with one of [bottomType], [topType], or [topFunctionType].  For example,
/// running a `NullabilityAwareFreeTypeVariableEliminator(Never, Object?,
/// Function).eliminateToLeast` on type `T Function<S>(S s, R r)` will return
/// `Never Function<S>(S s, Object? r)`.
///
/// The algorithm for elimination of type variables is described in
/// https://github.com/dart-lang/language/pull/957
class NullabilityAwareFreeTypeVariableEliminator
    extends NullabilityAwareTypeVariableEliminatorBase {
  Set<TypeParameter> _boundVariables = <TypeParameter>{};

  NullabilityAwareFreeTypeVariableEliminator(
      {required DartType bottomType,
      required DartType topType,
      required DartType topFunctionType})
      :
        // ignore: unnecessary_null_comparison
        assert(bottomType != null),
        // ignore: unnecessary_null_comparison
        assert(topType != null),
        // ignore: unnecessary_null_comparison
        assert(topFunctionType != null),
        super(
            bottomType: bottomType,
            topType: topType,
            topFunctionType: topFunctionType);

  @override
  DartType? visitFunctionType(FunctionType node, int variance) {
    if (node.typeParameters.isNotEmpty) {
      _boundVariables.addAll(node.typeParameters);
      DartType? result = super.visitFunctionType(node, variance);
      _boundVariables.removeAll(node.typeParameters);
      return result;
    } else {
      return super.visitFunctionType(node, variance);
    }
  }

  @override
  bool containsTypeVariablesToEliminate(DartType type) {
    return containsFreeTypeVariables(type, boundVariables: _boundVariables);
  }

  @override
  bool isTypeVariableToEliminate(TypeParameter typeParameter) {
    return !_boundVariables.contains(typeParameter);
  }
}

/// Computes [type] as if declared without nullability markers.
///
/// For example, int? and int* are considered applications of the nullable and
/// the legacy type constructors to type int correspondingly.
/// [computeTypeWithoutNullabilityMarker] peels off these type constructors,
/// returning the non-nullable version of type int.  In case of
/// [TypeParameterType]s, the result may be either [Nullability.nonNullable] or
/// [Nullability.undetermined], depending on the bound.
DartType computeTypeWithoutNullabilityMarker(DartType type,
    {required bool isNonNullableByDefault}) {
  // ignore: unnecessary_null_comparison
  assert(isNonNullableByDefault != null);

  if (type is TypeParameterType) {
    // The default nullability for library is used when there are no
    // nullability markers on the type.
    return new TypeParameterType(
        type.parameter,
        _defaultNullabilityForTypeParameterType(type.parameter,
            isNonNullableByDefault: isNonNullableByDefault));
  } else if (type is IntersectionType) {
    // Intersection types can't be arguments to the nullable and the legacy
    // type constructors, so nothing can be peeled off.
    return type;
  } else if (type is NullType) {
    return type;
  } else {
    // For most types, peeling off the nullability constructors means that
    // they become non-nullable.
    return type.withDeclaredNullability(Nullability.nonNullable);
  }
}

/// Returns true if [type] is declared without nullability markers.
///
/// An example of the nullable type constructor application is T? where T is a
/// type parameter.  Some examples of types declared without nullability markers
/// are T% and S, where T and S are type parameters such that T extends Object?
/// and S extends Object.
bool isTypeParameterTypeWithoutNullabilityMarker(TypeParameterType type,
    {required bool isNonNullableByDefault}) {
  // ignore: unnecessary_null_comparison
  assert(isNonNullableByDefault != null);

  // The default nullability for library is used when there are no nullability
  // markers on the type.
  return type.declaredNullability ==
      _defaultNullabilityForTypeParameterType(type.parameter,
          isNonNullableByDefault: isNonNullableByDefault);
}

bool isTypeWithoutNullabilityMarker(DartType type,
    {required bool isNonNullableByDefault}) {
  // ignore: unnecessary_null_comparison
  assert(isNonNullableByDefault != null);
  return !type.accept(new _NullabilityMarkerDetector(isNonNullableByDefault));
}

class _NullabilityMarkerDetector implements DartTypeVisitor<bool> {
  final bool isNonNullableByDefault;

  const _NullabilityMarkerDetector(this.isNonNullableByDefault);

  @override
  bool defaultDartType(DartType node) {
    throw new UnsupportedError("Unsupported operation: "
        "_NullabilityMarkerDetector(${node.runtimeType})");
  }

  @override
  bool visitDynamicType(DynamicType node) => false;

  @override
  bool visitFunctionType(FunctionType node) {
    assert(node.declaredNullability != Nullability.undetermined);
    return node.declaredNullability == Nullability.nullable ||
        node.declaredNullability == Nullability.legacy;
  }

  @override
  bool visitRecordType(RecordType node) {
    assert(node.declaredNullability != Nullability.undetermined);
    return node.declaredNullability == Nullability.nullable ||
        node.declaredNullability == Nullability.legacy;
  }

  @override
  bool visitFutureOrType(FutureOrType node) {
    if (node.declaredNullability == Nullability.nullable ||
        node.declaredNullability == Nullability.legacy) {
      return true;
    }
    return false;
  }

  @override
  bool visitInterfaceType(InterfaceType node) {
    assert(node.declaredNullability != Nullability.undetermined);
    return node.declaredNullability == Nullability.nullable ||
        node.declaredNullability == Nullability.legacy;
  }

  @override
  bool visitExtensionType(ExtensionType node) {
    assert(node.declaredNullability != Nullability.undetermined);
    return node.declaredNullability == Nullability.nullable ||
        node.declaredNullability == Nullability.legacy;
  }

  @override
  bool visitInlineType(InlineType node) {
    assert(node.declaredNullability != Nullability.undetermined);
    return node.declaredNullability == Nullability.nullable ||
        node.declaredNullability == Nullability.legacy;
  }

  @override
  bool visitInvalidType(InvalidType node) => false;

  @override
  bool visitNeverType(NeverType node) {
    assert(node.declaredNullability != Nullability.undetermined);
    return node.declaredNullability == Nullability.nullable ||
        node.declaredNullability == Nullability.legacy;
  }

  @override
  bool visitNullType(NullType node) => false;

  @override
  bool visitTypeParameterType(TypeParameterType node) {
    return !isTypeParameterTypeWithoutNullabilityMarker(node,
        isNonNullableByDefault: isNonNullableByDefault);
  }

  @override
  bool visitIntersectionType(IntersectionType node) => false;

  @override
  bool visitTypedefType(TypedefType node) {
    assert(node.declaredNullability != Nullability.undetermined);
    return node.declaredNullability == Nullability.nullable ||
        node.declaredNullability == Nullability.legacy;
  }

  @override
  bool visitVoidType(VoidType node) => false;
}

/// Returns true if [type] is an application of the nullable type constructor.
///
/// A type is considered an application of the nullable type constructor if it
/// was declared with the ? marker.  Some examples of such types are int?,
/// String?, Object?, and T? where T is a type parameter.  Types dynamic, void,
/// and Null are nullable, but aren't considered applications of the nullable
/// type constructor.
bool isNullableTypeConstructorApplication(DartType type) {
  if (type is IntersectionType) {
    // Promoted types are never considered applications of ?.
    return false;
  }
  return type.declaredNullability == Nullability.nullable &&
      type is! DynamicType &&
      type is! VoidType &&
      type is! NullType;
}

/// Returns true if [type] is an application of the legacy type constructor.
///
/// A type is considered an application of the legacy type constructor if it was
/// declared within a legacy library and is not one of exempt types, such as
/// dynamic or void.
bool isLegacyTypeConstructorApplication(DartType type,
    {required bool isNonNullableByDefault}) {
  // ignore: unnecessary_null_comparison
  assert(isNonNullableByDefault != null);

  if (type is TypeParameterType) {
    // The legacy nullability is considered an application of the legacy
    // nullability constructor if it doesn't match the default nullability
    // of the type-parameter type for the library.
    return type.declaredNullability == Nullability.legacy &&
        !isTypeParameterTypeWithoutNullabilityMarker(type,
            isNonNullableByDefault: isNonNullableByDefault);
  } else if (type is InvalidType) {
    return false;
  } else {
    return type.declaredNullability == Nullability.legacy;
  }
}

Nullability _defaultNullabilityForTypeParameterType(TypeParameter parameter,
    {required bool isNonNullableByDefault}) {
  // ignore: unnecessary_null_comparison
  assert(isNonNullableByDefault != null);
  return isNonNullableByDefault
      ? TypeParameterType.computeNullabilityFromBound(parameter)
      : Nullability.legacy;
}

/// Recalculates and updates nullabilities of the bounds in [typeParameters].
///
/// The procedure is intended to be used on type parameters that are in the
/// scope of another declaration with type parameters. After a substitution
/// involving the outer type parameters is performed, some potentially nullable
/// bounds of the inner parameters can change to non-nullable. Since type
/// parameters can depend on each other, the occurrences of those with changed
/// nullabilities need to be updated in the bounds of the entire type parameter
/// set.
void updateBoundNullabilities(List<TypeParameter> typeParameters) {
  if (typeParameters.isEmpty) return;
  List<bool> visited =
      new List<bool>.filled(typeParameters.length, false, growable: false);
  for (int parameterIndex = 0;
      parameterIndex < typeParameters.length;
      parameterIndex++) {
    _updateBoundNullabilities(typeParameters, visited, parameterIndex);
  }
}

void _updateBoundNullabilities(
    List<TypeParameter> typeParameters, List<bool> visited, int startIndex) {
  if (visited[startIndex]) return;
  visited[startIndex] = true;

  TypeParameter parameter = typeParameters[startIndex];
  DartType bound = parameter.bound;
  while (bound is FutureOrType) {
    bound = bound.typeArgument;
  }
  if (bound is TypeParameterType) {
    int nextIndex = typeParameters.indexOf(bound.parameter);
    if (nextIndex != -1) {
      _updateBoundNullabilities(typeParameters, visited, nextIndex);
      Nullability updatedNullability =
          TypeParameterType.computeNullabilityFromBound(
              typeParameters[nextIndex]);
      if (bound.declaredNullability != updatedNullability) {
        parameter.bound = _updateNestedFutureOrNullability(
            parameter.bound, updatedNullability);
      }
    }
  }
}

DartType _updateNestedFutureOrNullability(
    DartType typeToUpdate, Nullability updatedNullability) {
  if (typeToUpdate is FutureOrType) {
    return new FutureOrType(
        _updateNestedFutureOrNullability(
            typeToUpdate.typeArgument, updatedNullability),
        typeToUpdate.declaredNullability);
  } else {
    return typeToUpdate.withDeclaredNullability(updatedNullability);
  }
}
