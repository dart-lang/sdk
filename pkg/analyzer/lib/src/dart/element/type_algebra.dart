// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';
import 'package:analyzer/src/summary2/function_type_builder.dart';
import 'package:analyzer/src/summary2/named_type_builder.dart';
import 'package:analyzer/src/summary2/record_type_builder.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';

/// Generates a fresh copy of the given type parameters, with their bounds
/// substituted to reference the new parameters.
///
/// The returned object contains the fresh type parameter list as well as a
/// mapping to be used for replacing other types to use the new type parameters.
FreshTypeParameters getFreshTypeParameters(
  List<TypeParameterElement> typeParameters,
) {
  var freshParameters = List<TypeParameterElementImpl>.generate(
    typeParameters.length,
    (i) => typeParameters[i].freshCopy(),
    growable: false,
  );

  var map = <TypeParameterElement, DartType>{};
  for (int i = 0; i < typeParameters.length; ++i) {
    map[typeParameters[i]] = TypeParameterTypeImpl(
      element: freshParameters[i],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  var substitution = Substitution.fromMap(map);

  for (int i = 0; i < typeParameters.length; ++i) {
    // TODO(kallentu): : Clean up TypeParameterElementImpl casting once
    // variance is added to the interface.
    var typeParameter = typeParameters[i] as TypeParameterElementImpl;
    if (!typeParameter.isLegacyCovariant) {
      freshParameters[i].variance = typeParameter.variance;
    }

    var bound = typeParameter.bound;
    if (bound != null) {
      var newBound = substitution.substituteType(bound);
      freshParameters[i].bound = newBound;
    }
  }

  return FreshTypeParameters(freshParameters, substitution);
}

/// Given a generic function [type] of a class member (so that it does not
/// carry its element and type arguments), substitute its type parameters with
/// the [newTypeParameters] in the formal parameters and return type.
FunctionTypeImpl replaceTypeParameters(
  FunctionTypeImpl type,
  List<TypeParameterElementImpl> newTypeParameters,
) {
  assert(newTypeParameters.length == type.typeParameters.length);
  if (newTypeParameters.isEmpty) {
    return type;
  }

  var typeArguments = newTypeParameters
      .map((e) => e.instantiate(nullabilitySuffix: NullabilitySuffix.none))
      .toList();
  var substitution = Substitution.fromPairs2(
    type.typeParameters,
    typeArguments,
  );

  InternalFormalParameterElement transformParameter(
    InternalFormalParameterElement p,
  ) {
    var type = substitution.substituteType(p.type);
    return p.copyWith(type: type);
  }

  return FunctionTypeImpl.v2(
    typeParameters: newTypeParameters,
    formalParameters: type.formalParameters.map(transformParameter).toList(),
    returnType: substitution.substituteType(type.returnType),
    nullabilitySuffix: type.nullabilitySuffix,
  );
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

///  1. Substituting T=X! into T! yields X!
///  3. Substituting T=X? into T! yields X?
///  7. Substituting T=X! into T? yields X?
///  9. Substituting T=X? into T? yields X?
NullabilitySuffix uniteNullabilities(NullabilitySuffix a, NullabilitySuffix b) {
  if (a == NullabilitySuffix.question || b == NullabilitySuffix.question) {
    return NullabilitySuffix.question;
  }
  return NullabilitySuffix.none;
}

class FreshTypeParameters {
  final List<TypeParameterElementImpl> freshTypeParameters;
  final Substitution substitution;

  FreshTypeParameters(this.freshTypeParameters, this.substitution);

  FunctionTypeImpl applyToFunctionType(FunctionTypeImpl type) {
    return FunctionTypeImpl.v2(
      typeParameters: freshTypeParameters,
      formalParameters: type.formalParameters.map((parameter) {
        var type = substitute(parameter.type);
        return parameter.copyWith(type: type);
      }).toFixedList(),
      returnType: substitute(type.returnType),
      nullabilitySuffix: type.nullabilitySuffix,
    );
  }

  TypeImpl substitute(DartType type) => substitution.substituteType(type);
}

/// Substitution that is based on the [map].
abstract class MapSubstitution extends Substitution {
  const MapSubstitution();

  Map<TypeParameterElement, DartType> get map;
}

abstract class Substitution {
  static const MapSubstitution empty = _NullSubstitution.instance;

  const Substitution();

  DartType? getSubstitute(TypeParameterElement parameter, bool upperBound);

  FunctionTypeImpl mapFunctionType(FunctionType type) {
    return substituteType(type) as FunctionTypeImpl;
  }

  InterfaceTypeImpl mapInterfaceType(InterfaceType type) {
    return substituteType(type) as InterfaceTypeImpl;
  }

  Iterable<InterfaceTypeImpl> mapInterfaceTypes(Iterable<InterfaceType> types) {
    return types.map(mapInterfaceType);
  }

  TypeImpl substituteType(DartType type, {bool contravariant = false}) {
    var visitor = _TopSubstitutor(this, contravariant);
    return type.accept(visitor);
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
    return _CombinedSubstitution(first, second);
  }

  /// Substitutes the type parameters on the class of [type] with the
  /// type arguments provided in [type].
  static MapSubstitution fromInterfaceType(InterfaceType type) {
    if (type.typeArguments.isEmpty) {
      return _NullSubstitution.instance;
    }
    return fromPairs2(type.element.typeParameters, type.typeArguments);
  }

  /// Substitutes each parameter to the type it maps to in [map].
  static MapSubstitution fromMap(Map<TypeParameterElement, DartType> map) {
    if (map.isEmpty) {
      return _NullSubstitution.instance;
    }
    return _MapSubstitution(map.map((key, value) => MapEntry(key, value)));
  }

  /// Substitutes the Nth parameter in [parameters] with the Nth type in
  /// [types].
  static MapSubstitution fromPairs(
    List<TypeParameterFragmentImpl> parameters,
    List<DartType> types,
  ) {
    return fromPairs2(parameters.map((p) => p.asElement2).toFixedList(), types);
  }

  /// Substitutes the Nth parameter in [parameters] with the Nth type in
  /// [types].
  static MapSubstitution fromPairs2(
    List<TypeParameterElement> parameters,
    List<DartType> types,
  ) {
    assert(parameters.length == types.length);
    if (parameters.isEmpty) {
      return _NullSubstitution.instance;
    }
    return fromMap(
      Map<TypeParameterElement, DartType>.fromIterables(parameters, types),
    );
  }
}

class _CombinedSubstitution extends Substitution {
  final Substitution first;
  final Substitution second;

  _CombinedSubstitution(this.first, this.second);

  @override
  DartType? getSubstitute(TypeParameterElement parameter, bool upperBound) {
    return first.getSubstitute(parameter, upperBound) ??
        second.getSubstitute(parameter, upperBound);
  }
}

class _FreshTypeParametersSubstitutor extends _TypeSubstitutor {
  final Map<TypeParameterElement, DartType> substitution = {};

  _FreshTypeParametersSubstitutor(_TypeSubstitutor super.outer);

  @override
  List<TypeParameterElementImpl> freshTypeParameters(
    List<TypeParameterElementImpl> elements,
  ) {
    if (elements.isEmpty) {
      return const <TypeParameterElementImpl>[];
    }

    var freshElements = List.generate(elements.length, (index) {
      var element = elements[index];
      var freshElement = element.freshCopy();
      var freshType = freshElement.instantiate(
        nullabilitySuffix: NullabilitySuffix.none,
      );
      substitution[element] = freshType;
      if (!element.isLegacyCovariant) {
        freshElement.variance = element.variance;
      }
      return freshElement;
    }, growable: false);

    for (var i = 0; i < freshElements.length; i++) {
      var element = elements[i];
      var bound = element.bound;
      if (bound != null) {
        var freshElement = freshElements[i];
        freshElement.bound = bound.accept(this) as TypeImpl?;
      }
    }

    return freshElements;
  }

  @override
  DartType? lookup(TypeParameterElement parameter, bool upperBound) {
    return substitution[parameter];
  }
}

class _MapSubstitution extends MapSubstitution {
  @override
  final Map<TypeParameterElement, DartType> map;

  _MapSubstitution(this.map);

  @override
  DartType? getSubstitute(TypeParameterElement parameter, bool upperBound) {
    return map[parameter];
  }

  @override
  String toString() => '_MapSubstitution($map)';
}

class _NullSubstitution extends MapSubstitution {
  static const _NullSubstitution instance = _NullSubstitution();

  const _NullSubstitution();

  @override
  Map<TypeParameterElement, DartType> get map => const {};

  @override
  DartType getSubstitute(TypeParameterElement parameter, bool upperBound) {
    return TypeParameterTypeImpl(
      element: parameter as TypeParameterElementImpl,
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  @override
  TypeImpl substituteType(DartType type, {bool contravariant = false}) =>
      type as TypeImpl;

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

  @override
  List<TypeParameterElementImpl> freshTypeParameters(
    List<TypeParameterElementImpl> parameters,
  ) {
    throw 'Create a fresh environment first';
  }

  @override
  DartType? lookup(TypeParameterElement parameter, bool upperBound) {
    return substitution.getSubstitute(parameter, upperBound);
  }
}

abstract class _TypeSubstitutor
    implements
        TypeVisitor<TypeImpl>,
        InferenceTypeVisitor<TypeImpl>,
        LinkingTypeVisitor<TypeImpl> {
  final _TypeSubstitutor? outer;
  bool covariantContext = true;

  /// The number of times a variable from this environment has been used in
  /// a substitution.
  ///
  /// There is a strict requirement that we must return the same instance for
  /// types that were not altered by the substitution.  This counter lets us
  /// check quickly if anything happened in a substitution.
  int useCounter = 0;

  _TypeSubstitutor(this.outer) {
    covariantContext = outer == null || outer!.covariantContext;
  }

  void bumpCountersUntil(_TypeSubstitutor target) {
    var substitutor = this;
    while (substitutor != target) {
      substitutor.useCounter++;
      substitutor = substitutor.outer!;
    }
    target.useCounter++;
  }

  List<TypeParameterElementImpl> freshTypeParameters(
    List<TypeParameterElementImpl> elements,
  );

  DartType? getSubstitute(TypeParameterElement parameter) {
    _TypeSubstitutor? environment = this;
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

  DartType? lookup(TypeParameterElement parameter, bool upperBound);

  _FreshTypeParametersSubstitutor newInnerEnvironment() {
    return _FreshTypeParametersSubstitutor(this);
  }

  @override
  TypeImpl visitDynamicType(covariant DynamicTypeImpl type) => type;

  @override
  TypeImpl visitFunctionType(covariant FunctionTypeImpl type) {
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
    int before = useCounter;

    var inner = this;
    var typeFormals = type.typeParameters;
    if (typeFormals.isNotEmpty) {
      inner = newInnerEnvironment();
      typeFormals = inner.freshTypeParameters(typeFormals);
    }

    // Invert the variance when translating parameters.
    inner.invertVariance();

    var parameters = type.formalParameters.map((parameter) {
      var type = parameter.type.accept(inner);
      return parameter.copyWith(type: type);
    }).toFixedList();

    inner.invertVariance();

    var returnType = type.returnType.accept(inner);
    var alias = _mapAlias(type.alias);

    if (useCounter == before) return type;

    return FunctionTypeImpl.v2(
      typeParameters: typeFormals,
      formalParameters: parameters,
      returnType: returnType,
      nullabilitySuffix: type.nullabilitySuffix,
      alias: alias,
    );
  }

  @override
  TypeImpl visitFunctionTypeBuilder(FunctionTypeBuilder type) {
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
    int before = useCounter;

    var inner = this;
    var typeParameters = type.typeParameters;
    if (typeParameters.isNotEmpty) {
      inner = newInnerEnvironment();
      typeParameters = inner
          .freshTypeParameters(typeParameters)
          .cast<TypeParameterElementImpl>()
          .toFixedList();
    }

    // Invert the variance when translating parameters.
    inner.invertVariance();

    var formalParameters = type.formalParameters.map((formalParameter) {
      var type = formalParameter.type.accept(inner);
      return formalParameter.copyWith(type: type);
    }).toFixedList();

    inner.invertVariance();

    var returnType = type.returnType.accept(inner);

    if (useCounter == before) return type;

    return FunctionTypeBuilder(
      typeParameters: typeParameters,
      formalParameters: formalParameters,
      returnType: returnType,
      nullabilitySuffix: type.nullabilitySuffix,
    );
  }

  @override
  TypeImpl visitInterfaceType(covariant InterfaceTypeImpl type) {
    if (type.typeArguments.isEmpty && type.alias == null) {
      return type;
    }

    int before = useCounter;
    var typeArguments = _mapList(type.typeArguments);
    var alias = _mapAlias(type.alias);
    if (useCounter == before) {
      return type;
    }

    return InterfaceTypeImpl(
      element: type.element,
      typeArguments: typeArguments,
      nullabilitySuffix: type.nullabilitySuffix,
      alias: alias,
    );
  }

  @override
  TypeImpl visitInvalidType(covariant InvalidTypeImpl type) => type;

  @override
  TypeImpl visitNamedTypeBuilder(NamedTypeBuilder type) {
    if (type.arguments.isEmpty) {
      return type;
    }

    int before = useCounter;
    var arguments = _mapList(type.arguments);
    if (useCounter == before) {
      return type;
    }

    return NamedTypeBuilder(
      linker: type.linker,
      typeSystem: type.typeSystem,
      element: type.element,
      arguments: arguments,
      nullabilitySuffix: type.nullabilitySuffix,
    );
  }

  @override
  TypeImpl visitNeverType(covariant NeverTypeImpl type) => type;

  @override
  TypeImpl visitRecordType(covariant RecordTypeImpl type) {
    var before = useCounter;

    var positionalFields = type.positionalFields.map((field) {
      return RecordTypePositionalFieldImpl(type: field.type.accept(this));
    }).toList();

    var namedFields = type.namedFields.map((field) {
      return RecordTypeNamedFieldImpl(
        name: field.name,
        type: field.type.accept(this),
      );
    }).toList();

    var alias = _mapAlias(type.alias);
    if (useCounter == before) {
      return type;
    }

    return RecordTypeImpl(
      positionalFields: positionalFields,
      namedFields: namedFields,
      nullabilitySuffix: type.nullabilitySuffix,
      alias: alias,
    );
  }

  @override
  TypeImpl visitRecordTypeBuilder(RecordTypeBuilder type) {
    // TODO(scheglov): implement visitRecordTypeBuilder
    throw UnimplementedError();
  }

  @override
  TypeImpl visitTypeParameterType(covariant TypeParameterTypeImpl type) {
    var argument = getSubstitute(type.element);
    if (argument == null) {
      return type;
    }

    var parameterSuffix = type.nullabilitySuffix;
    var argumentSuffix = argument.nullabilitySuffix;
    var nullability = uniteNullabilities(parameterSuffix, argumentSuffix);
    return (argument as TypeImpl).withNullability(nullability);
  }

  @override
  TypeImpl visitUnknownInferredType(UnknownInferredType type) => type;

  @override
  TypeImpl visitVoidType(covariant VoidTypeImpl type) => type;

  InstantiatedTypeAliasElementImpl? _mapAlias(
    InstantiatedTypeAliasElementImpl? alias,
  ) {
    if (alias == null) {
      return null;
    }
    return InstantiatedTypeAliasElementImpl(
      element: alias.element,
      typeArguments: _mapList(alias.typeArguments),
    );
  }

  List<TypeImpl> _mapList(List<TypeImpl> types) {
    return types.map((e) => e.accept(this)).toFixedList();
  }
}
