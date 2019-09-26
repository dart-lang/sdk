// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:analyzer/src/summary2/function_type_builder.dart';
import 'package:analyzer/src/summary2/named_type_builder.dart';

/// Generates a fresh copy of the given type parameters, with their bounds
/// substituted to reference the new parameters.
///
/// The returned object contains the fresh type parameter list as well as a
/// mapping to be used for replacing other types to use the new type parameters.
FreshTypeParameters getFreshTypeParameters(
    List<TypeParameterElement> typeParameters) {
  var freshParameters = new List<TypeParameterElementImpl>.generate(
    typeParameters.length,
    (i) => new TypeParameterElementImpl(typeParameters[i].name, -1),
    growable: true,
  );

  var map = <TypeParameterElement, DartType>{};
  for (int i = 0; i < typeParameters.length; ++i) {
    map[typeParameters[i]] = new TypeParameterTypeImpl(freshParameters[i]);
  }

  var substitution = Substitution.fromMap(map);

  for (int i = 0; i < typeParameters.length; ++i) {
    var bound = typeParameters[i].bound;
    if (bound != null) {
      var newBound = substitution.substituteType(bound);
      freshParameters[i].bound = newBound;
    }
  }

  return new FreshTypeParameters(freshParameters, substitution);
}

/// Returns a type where all occurrences of the given type parameters have been
/// replaced with the corresponding types.
///
/// This will copy only the sub-terms of [type] that contain substituted
/// variables; all other [DartType] objects will be reused.
///
/// In particular, if no type parameters were substituted, this is guaranteed
/// to return the [type] instance (not a copy), so the caller may use
/// [identical] to efficiently check if a distinct type was created.
DartType substitute(
  DartType type,
  Map<TypeParameterElement, DartType> substitution,
) {
  if (substitution.isEmpty) {
    return type;
  }
  return Substitution.fromMap(substitution).substituteType(type);
}

class FreshTypeParameters {
  final List<TypeParameterElement> freshTypeParameters;
  final Substitution substitution;

  FreshTypeParameters(this.freshTypeParameters, this.substitution);

  FunctionType applyToFunctionType(FunctionType type) {
    return new FunctionTypeImpl.synthetic(
      substitute(type.returnType),
      freshTypeParameters,
      type.parameters.map((parameter) {
        return ParameterElementImpl.synthetic(
          parameter.name,
          substitute(parameter.type),
          // ignore: deprecated_member_use_from_same_package
          parameter.parameterKind,
        );
      }).toList(),
    );
  }

  DartType substitute(DartType type) => substitution.substituteType(type);
}

/// Substitution that is based on the [map].
abstract class MapSubstitution extends Substitution {
  const MapSubstitution();

  Map<TypeParameterElement, DartType> get map;
}

abstract class Substitution {
  static const Substitution empty = _NullSubstitution.instance;

  const Substitution();

  DartType getSubstitute(TypeParameterElement parameter, bool upperBound);

  DartType substituteType(DartType type, {bool contravariant: false}) {
    return new _TopSubstitutor(this, contravariant).visit(type);
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

  /// Substitutes the type parameters on the class of [type] with the
  /// type arguments provided in [type].
  static Substitution fromInterfaceType(InterfaceType type) {
    if (type.typeArguments.isEmpty) {
      return _NullSubstitution.instance;
    }
    return fromPairs(type.element.typeParameters, type.typeArguments);
  }

  /// Substitutes each parameter to the type it maps to in [map].
  static MapSubstitution fromMap(Map<TypeParameterElement, DartType> map) {
    if (map.isEmpty) {
      return _NullSubstitution.instance;
    }
    return new _MapSubstitution(map);
  }

  /// Substitutes the Nth parameter in [parameters] with the Nth type in
  /// [types].
  static Substitution fromPairs(
    List<TypeParameterElement> parameters,
    List<DartType> types,
  ) {
    assert(parameters.length == types.length);
    if (parameters.isEmpty) {
      return _NullSubstitution.instance;
    }
    return fromMap(
      new Map<TypeParameterElement, DartType>.fromIterables(
        parameters,
        types,
      ),
    );
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
    Map<TypeParameterElement, DartType> upper,
    Map<TypeParameterElement, DartType> lower,
  ) {
    if (upper.isEmpty && lower.isEmpty) {
      return _NullSubstitution.instance;
    }
    return new _UpperLowerBoundsSubstitution(upper, lower);
  }
}

class _CombinedSubstitution extends Substitution {
  final Substitution first;
  final Substitution second;

  _CombinedSubstitution(this.first, this.second);

  @override
  DartType getSubstitute(TypeParameterElement parameter, bool upperBound) {
    return first.getSubstitute(parameter, upperBound) ??
        second.getSubstitute(parameter, upperBound);
  }
}

class _FreshTypeParametersSubstitutor extends _TypeSubstitutor {
  final Map<TypeParameterElement, DartType> substitution = {};

  _FreshTypeParametersSubstitutor(_TypeSubstitutor outer) : super(outer);

  @override
  List<TypeParameterElement> freshTypeParameters(
      List<TypeParameterElement> elements) {
    if (elements.isEmpty) {
      return const <TypeParameterElement>[];
    }

    var freshElements = List<TypeParameterElement>(elements.length);
    for (var i = 0; i < elements.length; i++) {
      var element = elements[i];
      var freshElement = TypeParameterElementImpl(element.name, -1);
      freshElements[i] = freshElement;
      var freshType = TypeParameterTypeImpl(freshElement);
      freshElement.type = freshType;
      substitution[element] = freshType;
    }

    for (var i = 0; i < freshElements.length; i++) {
      var element = elements[i];
      if (element.bound != null) {
        TypeParameterElementImpl freshElement = freshElements[i];
        freshElement.bound = visit(element.bound);
      }
    }

    return freshElements;
  }

  DartType lookup(TypeParameterElement parameter, bool upperBound) {
    return substitution[parameter];
  }
}

class _MapSubstitution extends MapSubstitution {
  final Map<TypeParameterElement, DartType> map;

  _MapSubstitution(this.map);

  DartType getSubstitute(TypeParameterElement parameter, bool upperBound) {
    return map[parameter];
  }

  @override
  String toString() => '_MapSubstitution($map)';
}

class _NullSubstitution extends MapSubstitution {
  static const _NullSubstitution instance = const _NullSubstitution();

  const _NullSubstitution();

  @override
  Map<TypeParameterElement, DartType> get map => const {};

  DartType getSubstitute(TypeParameterElement parameter, bool upperBound) {
    return new TypeParameterTypeImpl(parameter);
  }

  @override
  DartType substituteType(DartType type, {bool contravariant: false}) => type;

  @override
  String toString() => "Substitution.empty";
}

class _TopSubstitutor extends _TypeSubstitutor {
  final Substitution substitution;

  _TopSubstitutor(this.substitution, bool contravariant) : super(null) {
    if (contravariant) {
      invertVariance();
    }
  }

  List<TypeParameterElement> freshTypeParameters(
      List<TypeParameterElement> parameters) {
    throw 'Create a fresh environment first';
  }

  @override
  DartType lookup(TypeParameterElement parameter, bool upperBound) {
    return substitution.getSubstitute(parameter, upperBound);
  }
}

abstract class _TypeSubstitutor extends DartTypeVisitor<DartType> {
  final _TypeSubstitutor outer;
  bool covariantContext = true;

  /// The number of times a variable from this environment has been used in
  /// a substitution.
  ///
  /// There is a strict requirement that we must return the same instance for
  /// types that were not altered by the substitution.  This counter lets us
  /// check quickly if anything happened in a substitution.
  int useCounter = 0;

  _TypeSubstitutor(this.outer) {
    covariantContext = outer == null ? true : outer.covariantContext;
  }

  void bumpCountersUntil(_TypeSubstitutor target) {
    var substitutor = this;
    while (substitutor != target) {
      substitutor.useCounter++;
      substitutor = substitutor.outer;
    }
    target.useCounter++;
  }

  List<TypeParameterElement> freshTypeParameters(
      List<TypeParameterElement> elements);

  DartType getSubstitute(TypeParameterElement parameter) {
    var environment = this;
    while (environment != null) {
      var replacement = environment.lookup(parameter, covariantContext);
      if (replacement != null) {
        bumpCountersUntil(environment);
        return replacement;
      }
      environment = environment.outer;
    }
    return null;
  }

  void invertVariance() {
    covariantContext = !covariantContext;
  }

  DartType lookup(TypeParameterElement parameter, bool upperBound);

  _FreshTypeParametersSubstitutor newInnerEnvironment() {
    return new _FreshTypeParametersSubstitutor(this);
  }

  DartType visit(DartType type) {
    return DartTypeVisitor.visit(type, this);
  }

  @override
  DartType visitBottomType(BottomTypeImpl type) => type;

  @override
  DartType visitDynamicType(DynamicTypeImpl type) => type;

  @override
  DartType visitFunctionType(FunctionType type) {
    // This is a bit tricky because we have to generate fresh type parameters
    // in order to change the bounds.  At the same time, if the function type
    // was unaltered, we have to return the [type] object (not a copy!).
    // Substituting a type for a fresh type variable should not be confused
    // with a "real" substitution.
    //
    // Create an inner environment to generate fresh type parameters.  The use
    // counter on the inner environment tells if the fresh type parameters have
    // any uses, but does not tell if the resulting function type is distinct.
    // Our own use counter will get incremented if something from our
    // environment has been used inside the function.
    int before = this.useCounter;

    var inner = this;
    var typeFormals = type.typeFormals;
    if (typeFormals.isNotEmpty) {
      inner = newInnerEnvironment();
      typeFormals = inner.freshTypeParameters(typeFormals);
    }

    // Invert the variance when translating parameters.
    inner.invertVariance();

    var parameters = type.parameters.map((parameter) {
      var type = inner.visit(parameter.type);
      return _parameterElement(parameter, type);
    }).toList();

    inner.invertVariance();

    var returnType = inner.visit(type.returnType);
    var typeArguments = type.typeArguments.map(visit).toList();

    if (this.useCounter == before) return type;

    return FunctionTypeImpl.synthetic(returnType, typeFormals, parameters,
        element: type.element, typeArguments: typeArguments);
  }

  @override
  DartType visitFunctionTypeBuilder(FunctionTypeBuilder type) {
    // This is a bit tricky because we have to generate fresh type parameters
    // in order to change the bounds.  At the same time, if the function type
    // was unaltered, we have to return the [type] object (not a copy!).
    // Substituting a type for a fresh type variable should not be confused
    // with a "real" substitution.
    //
    // Create an inner environment to generate fresh type parameters.  The use
    // counter on the inner environment tells if the fresh type parameters have
    // any uses, but does not tell if the resulting function type is distinct.
    // Our own use counter will get incremented if something from our
    // environment has been used inside the function.
    int before = this.useCounter;

    var inner = this;
    var typeFormals = type.typeFormals;
    if (typeFormals.isNotEmpty) {
      inner = newInnerEnvironment();
      typeFormals = inner.freshTypeParameters(typeFormals);
    }

    // Invert the variance when translating parameters.
    inner.invertVariance();

    var parameters = type.parameters.map((parameter) {
      var type = inner.visit(parameter.type);
      return _parameterElement(parameter, type);
    }).toList();

    inner.invertVariance();

    var returnType = inner.visit(type.returnType);

    if (this.useCounter == before) return type;

    return FunctionTypeBuilder(
      typeFormals,
      parameters,
      returnType,
      type.nullabilitySuffix,
    );
  }

  @override
  DartType visitInterfaceType(InterfaceType type) {
    if (type.typeArguments.isEmpty) {
      return type;
    }

    int before = useCounter;
    var typeArguments = type.typeArguments.map(visit).toList();
    if (useCounter == before) {
      return type;
    }

    return new InterfaceTypeImpl.explicit(type.element, typeArguments,
        nullabilitySuffix: (type as TypeImpl).nullabilitySuffix);
  }

  @override
  DartType visitNamedTypeBuilder(NamedTypeBuilder type) {
    if (type.arguments.isEmpty) {
      return type;
    }

    int before = useCounter;
    var arguments = type.arguments.map(visit).toList();
    if (useCounter == before) {
      return type;
    }

    return new NamedTypeBuilder(
      type.element,
      arguments,
      type.nullabilitySuffix,
    );
  }

  @override
  DartType visitTypeParameterType(TypeParameterType type) {
    return getSubstitute(type.element) ?? type;
  }

  @override
  DartType visitUnknownInferredType(UnknownInferredType type) => type;

  @override
  DartType visitVoidType(VoidType type) => type;

  static ParameterElementImpl _parameterElement(
    ParameterElement parameter,
    DartType type,
  ) {
    var result = ParameterElementImpl.synthetic(
      parameter.name,
      type,
      // ignore: deprecated_member_use_from_same_package
      parameter.parameterKind,
    );
    result.isExplicitlyCovariant = parameter.isCovariant;
    return result;
  }
}

class _UpperLowerBoundsSubstitution extends Substitution {
  final Map<TypeParameterElement, DartType> upper;
  final Map<TypeParameterElement, DartType> lower;

  _UpperLowerBoundsSubstitution(this.upper, this.lower);

  DartType getSubstitute(TypeParameterElement parameter, bool upperBound) {
    return upperBound ? upper[parameter] : lower[parameter];
  }

  @override
  String toString() => '_UpperLowerBoundsSubstitution($upper, $lower)';
}
