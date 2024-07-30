// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file implements a "mini type system" that's similar to full Dart types,
// but light weight enough to be suitable for unit testing of code in the
// `_fe_analyzer_shared` package.

import 'package:_fe_analyzer_shared/src/type_inference/nullability_suffix.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';

/// Surrounds [s] with parentheses if [condition] is `true`, otherwise returns
/// [s] unchanged.
String _parenthesizeIf(bool condition, String s) => condition ? '($s)' : s;

/// Representation of the type `dynamic` suitable for unit testing of code in
/// the `_fe_analyzer_shared` package.
class DynamicType extends _SpecialSimpleType implements SharedDynamicType {
  static final instance = DynamicType._();

  DynamicType._()
      : super._('dynamic', nullabilitySuffix: NullabilitySuffix.none);

  @override
  Type withNullability(NullabilitySuffix suffix) => this;
}

/// Representation of a function type suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
///
/// Optional parameters, named parameters, and type parameters are not (yet)
/// supported.
class FunctionType extends Type {
  /// The return type.
  final Type returnType;

  /// A list of the types of positional parameters.
  final List<Type> positionalParameters;

  FunctionType(this.returnType, this.positionalParameters,
      {super.nullabilitySuffix = NullabilitySuffix.none})
      : super._();

  @override
  Type? closureWithRespectToUnknown({required bool covariant}) {
    Type? newReturnType =
        returnType.closureWithRespectToUnknown(covariant: covariant);
    List<Type>? newPositionalParameters =
        positionalParameters.closureWithRespectToUnknown(covariant: !covariant);
    if (newReturnType == null && newPositionalParameters == null) {
      return null;
    }
    return FunctionType(newReturnType ?? returnType,
        newPositionalParameters ?? positionalParameters,
        nullabilitySuffix: nullabilitySuffix);
  }

  @override
  Type? recursivelyDemote({required bool covariant}) {
    Type? newReturnType = returnType.recursivelyDemote(covariant: covariant);
    List<Type>? newPositionalParameters =
        positionalParameters.recursivelyDemote(covariant: !covariant);
    if (newReturnType == null && newPositionalParameters == null) {
      return null;
    }
    return FunctionType(newReturnType ?? returnType,
        newPositionalParameters ?? positionalParameters,
        nullabilitySuffix: nullabilitySuffix);
  }

  @override
  Type withNullability(NullabilitySuffix suffix) =>
      FunctionType(returnType, positionalParameters, nullabilitySuffix: suffix);

  @override
  String _toStringWithoutSuffix({required bool parenthesizeIfComplex}) =>
      _parenthesizeIf(parenthesizeIfComplex,
          '$returnType Function(${positionalParameters.join(', ')})');
}

/// Representation of the type `FutureOr<T>` suitable for unit testing of code
/// in the `_fe_analyzer_shared` package.
class FutureOrType extends PrimaryType {
  FutureOrType(Type typeArgument,
      {super.nullabilitySuffix = NullabilitySuffix.none})
      : super._withSpecialName('FutureOr', args: [typeArgument]);

  Type get typeArgument => args.single;

  @override
  Type? closureWithRespectToUnknown({required bool covariant}) {
    Type? newArg =
        typeArgument.closureWithRespectToUnknown(covariant: covariant);
    if (newArg == null) return null;
    return FutureOrType(newArg, nullabilitySuffix: nullabilitySuffix);
  }

  @override
  Type? recursivelyDemote({required bool covariant}) {
    Type? newArg = typeArgument.recursivelyDemote(covariant: covariant);
    if (newArg == null) return null;
    return FutureOrType(newArg, nullabilitySuffix: nullabilitySuffix);
  }

  @override
  Type withNullability(NullabilitySuffix suffix) =>
      FutureOrType(typeArgument, nullabilitySuffix: suffix);
}

/// Representation of an invalid type suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
class InvalidType extends _SpecialSimpleType implements SharedInvalidType {
  static final instance = InvalidType._();

  InvalidType._() : super._('error', nullabilitySuffix: NullabilitySuffix.none);

  @override
  Type withNullability(NullabilitySuffix suffix) => this;
}

class NamedType implements SharedNamedType<Type> {
  @override
  final String name;

  @override
  final Type type;

  NamedType({required this.name, required this.type});
}

/// Representation of the type `Never` suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
class NeverType extends _SpecialSimpleType {
  static final instance = NeverType._();

  NeverType._({super.nullabilitySuffix = NullabilitySuffix.none})
      : super._('Never');

  @override
  Type withNullability(NullabilitySuffix suffix) =>
      NeverType._(nullabilitySuffix: suffix);
}

/// Representation of the type `Null` suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
class NullType extends _SpecialSimpleType {
  static final instance = NullType._();

  NullType._() : super._('Null', nullabilitySuffix: NullabilitySuffix.none);

  @override
  Type withNullability(NullabilitySuffix suffix) => this;
}

/// Exception thrown if a type fails to parse properly.
class ParseError extends Error {
  final String message;

  ParseError(this.message);

  @override
  String toString() => message;
}

/// Representation of a primary type suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.  A primary type is either an interface type
/// with zero or more type parameters (e.g. `double`, or `Map<int, String>`), a
/// reference to a type parameter, or one of the special types whose name is a
/// single word (e.g. `dynamic`).
class PrimaryType extends Type {
  /// Names of primary types not originating from a class, a mixin, or an enum.
  static const List<String> namedNonInterfaceTypes = [
    'dynamic',
    'error',
    'FutureOr',
    'Never',
    'Null',
    'void'
  ];

  /// The name of the type.
  final String name;

  /// The type arguments, or `const []` if there are no type arguments.
  final List<Type> args;

  PrimaryType(this.name,
      {this.args = const [], super.nullabilitySuffix = NullabilitySuffix.none})
      : super._() {
    if (namedNonInterfaceTypes.contains(name)) {
      throw StateError('Tried to create a PrimaryType with special name $name');
    }
  }

  PrimaryType._withSpecialName(this.name,
      {this.args = const [], super.nullabilitySuffix = NullabilitySuffix.none})
      : super._() {
    if (!namedNonInterfaceTypes.contains(name)) {
      throw StateError(
          'Tried to use PrimaryType._withSpecialName with non-special name '
          '$name');
    }
  }

  bool get isInterfaceType => !namedNonInterfaceTypes.contains(name);

  @override
  Type? closureWithRespectToUnknown({required bool covariant}) {
    List<Type>? newArgs =
        args.closureWithRespectToUnknown(covariant: covariant);
    if (newArgs == null) return null;
    return PrimaryType(name,
        args: newArgs, nullabilitySuffix: nullabilitySuffix);
  }

  @override
  Type? recursivelyDemote({required bool covariant}) {
    List<Type>? newArgs = args.recursivelyDemote(covariant: covariant);
    if (newArgs == null) return null;
    return PrimaryType(name,
        args: newArgs, nullabilitySuffix: nullabilitySuffix);
  }

  @override
  Type withNullability(NullabilitySuffix suffix) =>
      PrimaryType(name, args: args, nullabilitySuffix: suffix);

  @override
  String _toStringWithoutSuffix({required bool parenthesizeIfComplex}) =>
      args.isEmpty ? name : '$name<${args.join(', ')}>';
}

/// Representation of a promoted type parameter type suitable for unit testing
/// of code in the `_fe_analyzer_shared` package.  A promoted type parameter is
/// often written using the syntax `a&b`, where `a` is the type parameter and
/// `b` is what it's promoted to.  For example, `T&int` represents the type
/// parameter `T`, promoted to `int`.
class PromotedTypeVariableType extends Type {
  final Type innerType;

  final Type promotion;

  PromotedTypeVariableType(this.innerType, this.promotion,
      {super.nullabilitySuffix = NullabilitySuffix.none})
      : super._();

  @override
  Type? closureWithRespectToUnknown({required bool covariant}) {
    var newPromotion =
        promotion.closureWithRespectToUnknown(covariant: covariant);
    if (newPromotion == null) return null;
    return PromotedTypeVariableType(innerType, newPromotion,
        nullabilitySuffix: nullabilitySuffix);
  }

  @override
  Type? recursivelyDemote({required bool covariant}) =>
      (covariant ? innerType : NeverType.instance)
          .withNullability(nullabilitySuffix);

  @override
  Type withNullability(NullabilitySuffix suffix) =>
      PromotedTypeVariableType(innerType, promotion, nullabilitySuffix: suffix);

  @override
  String _toStringWithoutSuffix({required bool parenthesizeIfComplex}) =>
      _parenthesizeIf(
          parenthesizeIfComplex,
          '${innerType.toString(parenthesizeIfComplex: true)}&'
          '${promotion.toString(parenthesizeIfComplex: true)}');
}

class RecordType extends Type implements SharedRecordType<Type> {
  @override
  final List<Type> positionalTypes;

  @override
  final List<NamedType> namedTypes;

  RecordType({
    required this.positionalTypes,
    required this.namedTypes,
    super.nullabilitySuffix = NullabilitySuffix.none,
  }) : super._();

  @override
  Type? closureWithRespectToUnknown({required bool covariant}) {
    List<Type>? newPositional;
    for (var i = 0; i < positionalTypes.length; i++) {
      var newType =
          positionalTypes[i].closureWithRespectToUnknown(covariant: covariant);
      if (newType != null) {
        newPositional ??= positionalTypes.toList();
        newPositional[i] = newType;
      }
    }

    List<NamedType>? newNamed =
        _closureWithRespectToUnknownNamed(covariant: covariant);

    if (newPositional == null && newNamed == null) {
      return null;
    }
    return RecordType(
      positionalTypes: newPositional ?? positionalTypes,
      namedTypes: newNamed ?? namedTypes,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  @override
  Type? recursivelyDemote({required bool covariant}) {
    List<Type>? newPositional;
    for (var i = 0; i < positionalTypes.length; i++) {
      var newType = positionalTypes[i].recursivelyDemote(covariant: covariant);
      if (newType != null) {
        newPositional ??= positionalTypes.toList();
        newPositional[i] = newType;
      }
    }

    List<NamedType>? newNamed = _recursivelyDemoteNamed(covariant: covariant);

    if (newPositional == null && newNamed == null) {
      return null;
    }
    return RecordType(
      positionalTypes: newPositional ?? positionalTypes,
      namedTypes: newNamed ?? namedTypes,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  @override
  Type withNullability(NullabilitySuffix suffix) => RecordType(
      positionalTypes: positionalTypes,
      namedTypes: namedTypes,
      nullabilitySuffix: suffix);

  List<NamedType>? _closureWithRespectToUnknownNamed(
      {required bool covariant}) {
    List<NamedType>? newNamed;
    for (var i = 0; i < namedTypes.length; i++) {
      var namedType = namedTypes[i];
      var newType =
          namedType.type.closureWithRespectToUnknown(covariant: covariant);
      if (newType != null) {
        (newNamed ??= namedTypes.toList())[i] =
            NamedType(name: namedType.name, type: newType);
      }
    }
    return newNamed;
  }

  List<NamedType>? _recursivelyDemoteNamed({required bool covariant}) {
    List<NamedType>? newNamed;
    for (var i = 0; i < namedTypes.length; i++) {
      var namedType = namedTypes[i];
      var newType = namedType.type.recursivelyDemote(covariant: covariant);
      if (newType != null) {
        (newNamed ??= namedTypes.toList())[i] =
            NamedType(name: namedType.name, type: newType);
      }
    }
    return newNamed;
  }

  @override
  String _toStringWithoutSuffix({required bool parenthesizeIfComplex}) {
    var positionalStr = positionalTypes.join(', ');
    var namedStr = namedTypes.map((e) => '${e.type} ${e.name}').join(', ');
    if (namedStr.isNotEmpty) {
      return positionalTypes.isNotEmpty
          ? '($positionalStr, {$namedStr})'
          : '({$namedStr})';
    } else {
      return positionalTypes.length == 1
          ? '($positionalStr,)'
          : '($positionalStr)';
    }
  }
}

/// Representation of a type suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
///
/// Note that we don't want code in `_fe_analyzer_shared` to inadvertently
/// compare types using `==` (or to store types in sets/maps, which can trigger
/// `==` to be used to compare them); this could cause bugs by causing
/// alternative spellings of the same type to be treated differently (e.g.
/// `FutureOr<int?>?` should be treated equivalently to `FutureOr<int?>`).  To
/// help ensure this, both `==` and `hashCode` throw exceptions by default.  To
/// defeat this behavior (e.g. so that a type can be passed to `expect`, use
/// [Type.withComparisonsAllowed].
abstract class Type implements SharedType {
  @override
  final NullabilitySuffix nullabilitySuffix;

  factory Type(String typeStr) => _TypeParser.parse(typeStr);

  const Type._({this.nullabilitySuffix = NullabilitySuffix.none});

  @override
  int get hashCode => type.hashCode;

  String get type => toString();

  @override
  bool operator ==(Object other) => other is Type && this.type == other.type;

  /// Finds the nearest type that doesn't involve the unknown type (`_`).
  ///
  /// If [covariant] is `true`, a supertype will be returned (replacing `_` with
  /// `Object?`); otherwise a subtype will be returned (replacing `_` with
  /// `Never`).
  Type? closureWithRespectToUnknown({required bool covariant});

  @override
  String getDisplayString() => type;

  @override
  bool isStructurallyEqualTo(SharedType other) => '$this' == '$other';

  /// Finds the nearest type that doesn't involve any type parameter promotion.
  /// If `covariant` is `true`, a supertype will be returned (replacing promoted
  /// type parameters with their unpromoted counterparts); otherwise a subtype
  /// will be returned (replacing promoted type parameters with `Never`).
  ///
  /// Returns `null` if this type is already free from type promotion.
  Type? recursivelyDemote({required bool covariant});

  /// Returns a string representation of this type.
  ///
  /// If [parenthesizeIfComplex] is `true`, then the result will be surrounded
  /// by parenthesis if it takes any of the following forms:
  /// - A type with a trailing `?` or `*`
  /// - A function type (e.g. `void Function()`)
  /// - A promoted type variable type (e.g. `T&int`)
  @override
  String toString({bool parenthesizeIfComplex = false}) =>
      switch (nullabilitySuffix) {
        NullabilitySuffix.question => _parenthesizeIf(
            parenthesizeIfComplex,
            '${_toStringWithoutSuffix(parenthesizeIfComplex: true)}'
            '?'),
        NullabilitySuffix.star => _parenthesizeIf(
            parenthesizeIfComplex,
            '${_toStringWithoutSuffix(parenthesizeIfComplex: true)}'
            '*'),
        NullabilitySuffix.none =>
          _toStringWithoutSuffix(parenthesizeIfComplex: parenthesizeIfComplex),
      };

  /// Returns a modifies version of this type, with the nullability suffix
  /// changed to [suffix].
  ///
  /// For types that don't accept a nullability suffix (`dynamic`, InvalidType,
  /// `Null`, `_`, and `void`), the type is returned unchanged.
  Type withNullability(NullabilitySuffix suffix);

  /// Returns a string representation of the portion of this string that
  /// precedes the nullability suffix.
  ///
  /// If [parenthesizeIfComplex] is `true`, then the result will be surrounded
  /// by parenthesis if it takes any of the following forms:
  /// - A function type (e.g. `void Function()`)
  /// - A promoted type variable type (e.g. `T&int`)
  String _toStringWithoutSuffix({required bool parenthesizeIfComplex});
}

class TypeSchema {
  final Type _type;

  TypeSchema(String typeString) : _type = Type(typeString);

  TypeSchema.fromType(this._type);

  String get typeString => _type.type;

  Type toType() => _type;
}

class TypeSystem {
  static final Map<String, List<Type> Function(List<Type>)>
      _coreSuperInterfaceTemplates = {
    'bool': (_) => [Type('Object')],
    'double': (_) => [Type('num'), Type('Object')],
    'Future': (_) => [Type('Object')],
    'int': (_) => [Type('num'), Type('Object')],
    'Iterable': (_) => [Type('Object')],
    'List': (args) => [PrimaryType('Iterable', args: args), Type('Object')],
    'Map': (_) => [Type('Object')],
    'Object': (_) => [],
    'num': (_) => [Type('Object')],
    'String': (_) => [Type('Object')],
  };

  static final _objectQuestionType = Type('Object?');

  static final _objectType = Type('Object');

  final Map<String, Type> _typeVarBounds = {};

  final Map<String, List<Type> Function(List<Type>)> _superInterfaceTemplates =
      Map.of(_coreSuperInterfaceTemplates);

  void addSuperInterfaces(
      String className, List<Type> Function(List<Type>) template) {
    _superInterfaceTemplates[className] = template;
  }

  void addTypeVariable(String name, {String? bound}) {
    _typeVarBounds[name] = Type(bound ?? 'Object?');
  }

  Type factor(Type t, Type s) {
    // If T <: S then Never
    if (isSubtype(t, s)) return NeverType.instance;

    // Else if T is R? and Null <: S then factor(R, S)
    if (t.nullabilitySuffix == NullabilitySuffix.question &&
        isSubtype(NullType.instance, s)) {
      return factor(t.withNullability(NullabilitySuffix.none), s);
    }

    // Else if T is R? then factor(R, S)?
    if (t.nullabilitySuffix == NullabilitySuffix.question) {
      return factor(t.withNullability(NullabilitySuffix.none), s)
          .withNullability(NullabilitySuffix.question);
    }

    // Else if T is R* and Null <: S then factor(R, S)
    if (t.nullabilitySuffix == NullabilitySuffix.star &&
        isSubtype(NullType.instance, s)) {
      return factor(t.withNullability(NullabilitySuffix.none), s);
    }

    // Else if T is R* then factor(R, S)*
    if (t.nullabilitySuffix == NullabilitySuffix.star) {
      return factor(t.withNullability(NullabilitySuffix.none), s)
          .withNullability(NullabilitySuffix.star);
    }

    // Else if T is FutureOr<R> and Future<R> <: S then factor(R, S)
    if (t is FutureOrType) {
      var r = t.typeArgument;
      if (isSubtype(PrimaryType('Future', args: [r]), s)) return factor(r, s);
    }

    // Else if T is FutureOr<R> and R <: S then factor(Future<R>, S)
    if (t is FutureOrType) {
      var r = t.typeArgument;
      if (isSubtype(r, s)) return factor(PrimaryType('Future', args: [r]), s);
    }

    // Else T
    return t;
  }

  bool isSubtype(Type t0, Type t1) {
    // Reflexivity: if T0 and T1 are the same type then T0 <: T1
    //
    // - Note that this check is necessary as the base case for primitive types,
    //   and type variables but not for composite types.  We only check it for
    //   types with a single name and no type arguments (this covers both
    //   primitive types and type variables).
    if (t0 is PrimaryType &&
        t0.nullabilitySuffix == NullabilitySuffix.none &&
        t0.args.isEmpty &&
        t1 is PrimaryType &&
        t1.nullabilitySuffix == NullabilitySuffix.none &&
        t1.args.isEmpty &&
        t0.name == t1.name) {
      return true;
    }

    // Unknown types (note: this is not in the spec, but necessary because there
    // are circumstances where we do subtype tests between types and type
    // schemas): if T0 or T1 is the unknown type then T0 <: T1.
    if (t0 is UnknownType || t1 is UnknownType) return true;

    // Right Top: if T1 is a top type (i.e. dynamic, or void, or Object?) then
    // T0 <: T1
    if (_isTop(t1)) return true;

    // Left Top: if T0 is dynamic or void then T0 <: T1 if Object? <: T1
    if (t0 is DynamicType || t0 is InvalidType || t0 is VoidType) {
      return isSubtype(_objectQuestionType, t1);
    }

    // Left Bottom: if T0 is Never then T0 <: T1
    if (t0 is NeverType && t0.nullabilitySuffix == NullabilitySuffix.none) {
      return true;
    }

    // Right Object: if T1 is Object then:
    if (t1 is PrimaryType &&
        t1.nullabilitySuffix == NullabilitySuffix.none &&
        t1.args.isEmpty &&
        t1.name == 'Object') {
      // - if T0 is an unpromoted type variable with bound B then T0 <: T1 iff
      //   B <: Object
      if (t0 is PrimaryType &&
          t0.nullabilitySuffix == NullabilitySuffix.none &&
          _isTypeVar(t0)) {
        return isSubtype(_typeVarBound(t0), _objectType);
      }

      // - if T0 is a promoted type variable X & S then T0 <: T1 iff S <: Object
      if (t0 is PromotedTypeVariableType &&
          t0.nullabilitySuffix == NullabilitySuffix.none) {
        return isSubtype(t0.promotion, _objectType);
      }

      // - if T0 is FutureOr<S> for some S, then T0 <: T1 iff S <: Object.
      if (t0 is FutureOrType &&
          t0.nullabilitySuffix == NullabilitySuffix.none) {
        return isSubtype(t0.typeArgument, _objectType);
      }

      // - if T0 is S* for any S, then T0 <: T1 iff S <: T1
      if (t0.nullabilitySuffix == NullabilitySuffix.star) {
        return isSubtype(t0.withNullability(NullabilitySuffix.none), t1);
      }

      // - if T0 is Null, dynamic, void, or S? for any S, then the subtyping
      //   does not hold (per above, the result of the subtyping query is
      //   false).
      if (t0 is NullType ||
          t0 is DynamicType ||
          t0 is InvalidType ||
          t0 is VoidType ||
          t0.nullabilitySuffix == NullabilitySuffix.question) {
        return false;
      }

      // - Otherwise T0 <: T1 is true.
      return true;
    }

    // Left Null: if T0 is Null then:
    if (t0 is NullType) {
      // - if T1 is a type variable (promoted or not) the query is false
      if (_isTypeVar(t1)) return false;

      // - If T1 is FutureOr<S> for some S, then the query is true iff
      //   Null <: S.
      if (t1 is FutureOrType &&
          t1.nullabilitySuffix == NullabilitySuffix.none) {
        return isSubtype(NullType.instance, t1.typeArgument);
      }

      // - If T1 is Null, S? or S* for some S, then the query is true.
      if (t1 is NullType ||
          t1.nullabilitySuffix == NullabilitySuffix.question ||
          t1.nullabilitySuffix == NullabilitySuffix.star) {
        return true;
      }

      // - Otherwise, the query is false
      return false;
    }

    // Left Legacy: if T0 is S0* then:
    if (t0.nullabilitySuffix == NullabilitySuffix.star) {
      // - T0 <: T1 iff S0 <: T1.
      return isSubtype(t0.withNullability(NullabilitySuffix.none), t1);
    }

    // Right Legacy: if T1 is S1* then:
    if (t1.nullabilitySuffix == NullabilitySuffix.star) {
      // - T0 <: T1 iff T0 <: S1?.
      return isSubtype(t0, t1.withNullability(NullabilitySuffix.question));
    }

    // Left FutureOr: if T0 is FutureOr<S0> then:
    if (t0 is FutureOrType && t0.nullabilitySuffix == NullabilitySuffix.none) {
      var s0 = t0.typeArgument;

      // - T0 <: T1 iff Future<S0> <: T1 and S0 <: T1
      return isSubtype(PrimaryType('Future', args: [s0]), t1) &&
          isSubtype(s0, t1);
    }

    // Left Nullable: if T0 is S0? then:
    if (t0.nullabilitySuffix == NullabilitySuffix.question) {
      // - T0 <: T1 iff S0 <: T1 and Null <: T1
      return isSubtype(t0.withNullability(NullabilitySuffix.none), t1) &&
          isSubtype(NullType.instance, t1);
    }

    // Type Variable Reflexivity 1: if T0 is a type variable X0 or a promoted
    // type variables X0 & S0 and T1 is X0 then:
    if (_isTypeVar(t0) &&
        t1 is PrimaryType &&
        t1.nullabilitySuffix == NullabilitySuffix.none &&
        t1.args.isEmpty &&
        _typeVarName(t0) == t1.name) {
      // - T0 <: T1
      return true;
    }

    // Type Variable Reflexivity 2: if T0 is a type variable X0 or a promoted
    // type variables X0 & S0 and T1 is X0 & S1 then:
    if (_isTypeVar(t0) &&
        t1 is PromotedTypeVariableType &&
        t1.nullabilitySuffix == NullabilitySuffix.none &&
        _typeVarName(t0) == _typeVarName(t1)) {
      // - T0 <: T1 iff T0 <: S1.
      return isSubtype(t0, t1.promotion);
    }

    // Right Promoted Variable: if T1 is a promoted type variable X1 & S1 then:
    if (t1 is PromotedTypeVariableType &&
        t1.nullabilitySuffix == NullabilitySuffix.none) {
      // - T0 <: T1 iff T0 <: X1 and T0 <: S1
      return isSubtype(t0, t1.innerType) && isSubtype(t0, t1.promotion);
    }

    // Right FutureOr: if T1 is FutureOr<S1> then:
    if (t1 is FutureOrType && t1.nullabilitySuffix == NullabilitySuffix.none) {
      var s1 = t1.typeArgument;

      // - T0 <: T1 iff any of the following hold:
      return
          //   - either T0 <: Future<S1>
          isSubtype(t0, PrimaryType('Future', args: [s1])) ||
              //   - or T0 <: S1
              isSubtype(t0, s1) ||
              //   - or T0 is X0 and X0 has bound S0 and S0 <: T1
              t0 is PrimaryType &&
                  _isTypeVar(t0) &&
                  isSubtype(_typeVarBound(t0), t1) ||
              //   - or T0 is X0 & S0 and S0 <: T1
              t0 is PromotedTypeVariableType && isSubtype(t0.promotion, t1);
    }

    // Right Nullable: if T1 is S1? then:
    if (t1.nullabilitySuffix == NullabilitySuffix.question) {
      var s1 = t1.withNullability(NullabilitySuffix.none);

      // - T0 <: T1 iff any of the following hold:
      return
          //   - either T0 <: S1
          isSubtype(t0, s1) ||
              //   - or T0 <: Null
              isSubtype(t0, NullType.instance) ||
              //   - or T0 is X0 and X0 has bound S0 and S0 <: T1
              t0 is PrimaryType &&
                  _isTypeVar(t0) &&
                  isSubtype(_typeVarBound(t0), t1) ||
              //   - or T0 is X0 & S0 and S0 <: T1
              t0 is PromotedTypeVariableType && isSubtype(t0.promotion, t1);
    }

    // Left Promoted Variable: T0 is a promoted type variable X0 & S0
    if (t0 is PromotedTypeVariableType) {
      // - and S0 <: T1
      if (isSubtype(t0.promotion, t1)) return true;
    }

    // Left Type Variable Bound: T0 is a type variable X0 with bound B0
    if (t0 is PrimaryType && _isTypeVar(t0)) {
      // - and B0 <: T1
      if (isSubtype(_typeVarBound(t0), t1)) return true;
    }

    // Function Type/Function: T0 is a function type and T1 is Function
    if (t0 is FunctionType &&
        t1 is PrimaryType &&
        t1.args.isEmpty &&
        t1.name == 'Function') {
      return true;
    }

    // Record Type/Record: T0 is a record type and T1 is Record
    if (t0 is RecordType &&
        t1 is PrimaryType &&
        t1.args.isEmpty &&
        t1.name == 'Record') {
      return true;
    }

    bool isInterfaceCompositionalitySubtype() {
      // Interface Compositionality: T0 is an interface type C0<S0, ..., Sk> and
      // T1 is C0<U0, ..., Uk>
      if (t0 is! PrimaryType ||
          t1 is! PrimaryType ||
          t0.args.length != t1.args.length ||
          t0.name != t1.name) {
        return false;
      }
      // - and each Si <: Ui
      for (int i = 0; i < t0.args.length; i++) {
        if (!isSubtype(t0.args[i], t1.args[i])) {
          return false;
        }
      }
      return true;
    }

    if (isInterfaceCompositionalitySubtype()) return true;

    // Super-Interface: T0 is an interface type with super-interfaces S0,...Sn
    bool isSuperInterfaceSubtype() {
      if (t0 is! PrimaryType || _isTypeVar(t0)) return false;
      var superInterfaceTemplate = _superInterfaceTemplates[t0.name];
      if (superInterfaceTemplate == null) {
        assert(false, 'Superinterfaces for $t0 not known');
        return false;
      }
      var superInterfaces = superInterfaceTemplate(t0.args);

      // - and Si <: T1 for some i
      for (var superInterface in superInterfaces) {
        if (isSubtype(superInterface, t1)) return true;
      }
      return false;
    }

    if (isSuperInterfaceSubtype()) return true;

    bool isPositionalFunctionSubtype() {
      // Positional Function Types: T0 is U0 Function<X0 extends B00, ...,
      // Xk extends B0k>(V0 x0, ..., Vn xn, [Vn+1 xn+1, ..., Vm xm])
      if (t0 is! FunctionType) return false;
      var n = t0.positionalParameters.length;
      // (Note: we don't support optional parameters)
      var m = n;

      // - and T1 is U1 Function<Y0 extends B10, ..., Yk extends B1k>(S0 y0,
      //   ..., Sp yp, [Sp+1 yp+1, ..., Sq yq])
      if (t1 is! FunctionType) return false;
      var p = t1.positionalParameters.length;
      var q = p;

      // - and p >= n
      if (p < n) return false;

      // - and m >= q
      if (m < q) return false;

      // (Note: no substitution is needed in the code below; we don't support
      // type arguments on function types)

      // - and Si[Z0/Y0, ..., Zk/Yk] <: Vi[Z0/X0, ..., Zk/Xk] for i in 0...q
      for (int i = 0; i < q; i++) {
        if (!isSubtype(
            t1.positionalParameters[i], t0.positionalParameters[i])) {
          return false;
        }
      }

      // - and U0[Z0/X0, ..., Zk/Xk] <: U1[Z0/Y0, ..., Zk/Yk]
      if (!isSubtype(t0.returnType, t1.returnType)) return false;

      // - and B0i[Z0/X0, ..., Zk/Xk] === B1i[Z0/Y0, ..., Zk/Yk] for i in 0...k
      // - where the Zi are fresh type variables with bounds B0i[Z0/X0, ...,
      //   Zk/Xk]
      // (No check needed here since we don't support type arguments on function
      // types)
      return true;
    }

    if (isPositionalFunctionSubtype()) return true;

    bool isNamedFunctionSubtype() {
      // Named Function Types: T0 is U0 Function<X0 extends B00, ..., Xk extends
      // B0k>(V0 x0, ..., Vn xn, {r0n+1 Vn+1 xn+1, ..., r0m Vm xm}) where r0j is
      // empty or required for j in n+1...m
      //
      // - and T1 is U1 Function<Y0 extends B10, ..., Yk extends B1k>(S0 y0,
      //   ..., Sn yn, {r1n+1 Sn+1 yn+1, ..., r1q Sq yq}) where r1j is empty or
      //   required for j in n+1...q
      // - and {yn+1, ... , yq} subsetof {xn+1, ... , xm}
      // - and Si[Z0/Y0, ..., Zk/Yk] <: Vi[Z0/X0, ..., Zk/Xk] for i in 0...n
      // - and Si[Z0/Y0, ..., Zk/Yk] <: Tj[Z0/X0, ..., Zk/Xk] for i in n+1...q,
      //   yj = xi
      // - and for each j such that r0j is required, then there exists an i in
      //   n+1...q such that xj = yi, and r1i is required
      // - and U0[Z0/X0, ..., Zk/Xk] <: U1[Z0/Y0, ..., Zk/Yk]
      // - and B0i[Z0/X0, ..., Zk/Xk] === B1i[Z0/Y0, ..., Zk/Yk] for i in 0...k
      // - where the Zi are fresh type variables with bounds B0i[Z0/X0, ...,
      //   Zk/Xk]

      // Note: nothing to do here; we don't support named arguments on function
      // types.
      return false;
    }

    if (isNamedFunctionSubtype()) return true;

    // Record Types: T0 is (V0, ..., Vn, {Vn+1 dn+1, ..., Vm dm})
    //
    // - and T1 is (S0, ..., Sn, {Sn+1 dn+1, ..., Sm dm})
    // - and Vi <: Si for i in 0...m
    bool isRecordSubtype() {
      if (t0 is! RecordType || t1 is! RecordType) return false;
      if (t0.positionalTypes.length != t1.positionalTypes.length) return false;
      for (int i = 0; i < t0.positionalTypes.length; i++) {
        if (!isSubtype(t0.positionalTypes[i], t1.positionalTypes[i])) {
          return false;
        }
      }
      if (t0.namedTypes.length != t1.namedTypes.length) return false;
      var t1NamedMap = {
        for (var NamedType(:name, :type) in t1.namedTypes) name: type
      };
      for (var NamedType(:name, type: vi) in t0.namedTypes) {
        var si = t1NamedMap[name];
        if (si == null) return false;
        if (!isSubtype(vi, si)) return false;
      }
      return true;
    }

    if (isRecordSubtype()) return true;

    return false;
  }

  bool _isTop(Type t) {
    if (t is PrimaryType) {
      return t is DynamicType || t is InvalidType || t is VoidType;
    } else if (t.nullabilitySuffix == NullabilitySuffix.question) {
      return t is PrimaryType && t.args.isEmpty && t.name == 'Object';
    }
    return false;
  }

  bool _isTypeVar(Type t) {
    if (t is PromotedTypeVariableType &&
        t.nullabilitySuffix == NullabilitySuffix.none) {
      assert(_isTypeVar(t.innerType));
      return true;
    } else if (t is PrimaryType &&
        t.nullabilitySuffix == NullabilitySuffix.none &&
        t.args.isEmpty) {
      return _typeVarBounds.containsKey(t.name);
    } else {
      return false;
    }
  }

  Type _typeVarBound(Type t) => _typeVarBounds[_typeVarName(t)]!;

  String _typeVarName(Type t) {
    assert(_isTypeVar(t));
    if (t is PromotedTypeVariableType &&
        t.nullabilitySuffix == NullabilitySuffix.none) {
      return _typeVarName(t.innerType);
    } else {
      return (t as PrimaryType).name;
    }
  }
}

/// Representation of the unknown type suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
class UnknownType extends Type implements SharedUnknownType {
  const UnknownType({super.nullabilitySuffix = NullabilitySuffix.none})
      : super._();

  @override
  Type? closureWithRespectToUnknown({required bool covariant}) =>
      covariant ? Type('Object?') : NeverType.instance;

  @override
  Type? recursivelyDemote({required bool covariant}) => null;

  @override
  Type withNullability(NullabilitySuffix suffix) =>
      UnknownType(nullabilitySuffix: suffix);

  @override
  String _toStringWithoutSuffix({required bool parenthesizeIfComplex}) => '_';
}

/// Representation of the type `void` suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
class VoidType extends _SpecialSimpleType implements SharedVoidType {
  static final instance = VoidType._();

  VoidType._() : super._('void', nullabilitySuffix: NullabilitySuffix.none);

  @override
  Type withNullability(NullabilitySuffix suffix) => this;
}

/// Shared implementation of the types `void`, `dynamic`, `null`, `Never`, and
/// the invalid type.
///
/// These types share the property that they are special cases of [PrimaryType]
/// that don't need special functionality for the [closureWithRespectToUnknown]
/// and [recursivelyDemote] methods.
abstract class _SpecialSimpleType extends PrimaryType {
  _SpecialSimpleType._(super.name,
      {super.nullabilitySuffix = NullabilitySuffix.none})
      : super._withSpecialName();

  @override
  Type? closureWithRespectToUnknown({required bool covariant}) => null;

  @override
  Type? recursivelyDemote({required bool covariant}) => null;
}

class _TypeParser {
  static final _typeTokenizationRegexp =
      RegExp(_identifierPattern + r'|\(|\)|<|>|,|\?|\*|&|{|}');

  static const _identifierPattern = '[_a-zA-Z][_a-zA-Z0-9]*';

  static final _identifierRegexp = RegExp(_identifierPattern);

  final String _typeStr;

  final List<String> _tokens;

  int _i = 0;

  _TypeParser._(this._typeStr, this._tokens);

  String get _currentToken => _tokens[_i];

  void _next() {
    _i++;
  }

  Never _parseFailure(String message) {
    throw ParseError(
        'Error parsing type `$_typeStr` at token $_currentToken: $message');
  }

  List<NamedType> _parseRecordTypeNamedFields() {
    assert(_currentToken == '{');
    _next();
    var namedTypes = <NamedType>[];
    while (_currentToken != '}') {
      var type = _parseType();
      var name = _currentToken;
      if (_identifierRegexp.matchAsPrefix(name) == null) {
        _parseFailure('Expected an identifier');
      }
      namedTypes.add(NamedType(name: name, type: type));
      _next();
      if (_currentToken == ',') {
        _next();
        continue;
      }
      if (_currentToken == '}') {
        break;
      }
      _parseFailure('Expected `}` or `,`');
    }
    if (namedTypes.isEmpty) {
      _parseFailure('Must have at least one named type between {}');
    }
    _next();
    return namedTypes;
  }

  Type _parseRecordTypeRest(List<Type> positionalTypes) {
    List<NamedType>? namedTypes;
    while (_currentToken != ')') {
      if (_currentToken == '{') {
        namedTypes = _parseRecordTypeNamedFields();
        if (_currentToken != ')') {
          _parseFailure('Expected `)`');
        }
        break;
      }
      positionalTypes.add(_parseType());
      if (_currentToken == ',') {
        _next();
        continue;
      }
      if (_currentToken == ')') {
        break;
      }
      _parseFailure('Expected `)` or `,`');
    }
    _next();
    return RecordType(
        positionalTypes: positionalTypes, namedTypes: namedTypes ?? const []);
  }

  Type? _parseSuffix(Type type) {
    if (_currentToken == '?') {
      _next();
      return type.withNullability(NullabilitySuffix.question);
    } else if (_currentToken == '*') {
      _next();
      return type.withNullability(NullabilitySuffix.star);
    } else if (_currentToken == '&') {
      _next();
      var promotion = _parseUnsuffixedType();
      return PromotedTypeVariableType(type, promotion);
    } else if (_currentToken == 'Function') {
      _next();
      if (_currentToken != '(') {
        _parseFailure('Expected `(`');
      }
      _next();
      var parameterTypes = <Type>[];
      if (_currentToken != ')') {
        while (true) {
          parameterTypes.add(_parseType());
          if (_currentToken == ')') break;
          if (_currentToken != ',') {
            _parseFailure('Expected `,` or `)`');
          }
          _next();
        }
      }
      _next();
      return FunctionType(type, parameterTypes);
    } else {
      return null;
    }
  }

  Type _parseType() {
    // We currently accept the following grammar for types:
    //   type := unsuffixedType nullability suffix*
    //   unsuffixedType := identifier typeArgs?
    //                   | `_`
    //                   | `(` type `)`
    //                   | `(` recordTypeFields `,` recordTypeNamedFields `)`
    //                   | `(` recordTypeFields `,`? `)`
    //                   | `(` recordTypeNamedFields? `)`
    //   recordTypeFields := type (`,` type)*
    //   recordTypeNamedFields := `{` recordTypeNamedField
    //                            (`,` recordTypeNamedField)* `,`? `}`
    //   recordTypeNamedField := type identifier
    //   typeArgs := `<` type (`,` type)* `>`
    //   nullability := (`?` | `*`)?
    //   suffix := `Function` `(` type (`,` type)* `)`
    //           | `?`
    //           | `*`
    //           | `&` unsuffixedType
    // TODO(paulberry): support more syntax if needed
    var result = _parseUnsuffixedType();
    while (true) {
      var newResult = _parseSuffix(result);
      if (newResult == null) break;
      result = newResult;
    }
    return result;
  }

  Type _parseUnsuffixedType() {
    if (_currentToken == '_') {
      _next();
      return const UnknownType();
    }
    if (_currentToken == '(') {
      _next();
      if (_currentToken == ')' || _currentToken == '{') {
        return _parseRecordTypeRest([]);
      }
      var type = _parseType();
      if (_currentToken == ',') {
        _next();
        return _parseRecordTypeRest([type]);
      }
      if (_currentToken != ')') {
        _parseFailure('Expected `)` or `,`');
      }
      _next();
      return type;
    }
    var typeName = _currentToken;
    if (_identifierRegexp.matchAsPrefix(typeName) == null) {
      _parseFailure('Expected an identifier, `_`, or `(`');
    }
    _next();
    List<Type> typeArgs;
    if (_currentToken == '<') {
      _next();
      typeArgs = [];
      while (true) {
        typeArgs.add(_parseType());
        if (_currentToken == '>') break;
        if (_currentToken != ',') {
          _parseFailure('Expected `,` or `>`');
        }
        _next();
      }
      _next();
    } else {
      typeArgs = const [];
    }
    if (typeName == 'dynamic') {
      if (typeArgs.isNotEmpty) {
        throw ParseError('`dynamic` does not accept type arguments');
      }
      return DynamicType.instance;
    } else if (typeName == 'error') {
      if (typeArgs.isNotEmpty) {
        throw ParseError('`error` does not accept type arguments');
      }
      return InvalidType.instance;
    } else if (typeName == 'FutureOr') {
      if (typeArgs.length != 1) {
        throw ParseError('`FutureOr` requires exactly one type argument');
      }
      return FutureOrType(typeArgs.single);
    } else if (typeName == 'Never') {
      if (typeArgs.isNotEmpty) {
        throw ParseError('`Never` does not accept type arguments');
      }
      return NeverType.instance;
    } else if (typeName == 'Null') {
      if (typeArgs.isNotEmpty) {
        throw ParseError('`Null` does not accept type arguments');
      }
      return NullType.instance;
    } else if (typeName == 'void') {
      if (typeArgs.isNotEmpty) {
        throw ParseError('`void` does not accept type arguments');
      }
      return VoidType.instance;
    } else {
      return PrimaryType(typeName, args: typeArgs);
    }
  }

  static Type parse(String typeStr) {
    var parser = _TypeParser._(typeStr, _tokenizeTypeStr(typeStr));
    var result = parser._parseType();
    if (parser._currentToken != '<END>') {
      throw ParseError('Extra tokens after parsing type `$typeStr`: '
          '${parser._tokens.sublist(parser._i, parser._tokens.length - 1)}');
    }
    return result;
  }

  static List<String> _tokenizeTypeStr(String typeStr) {
    var result = <String>[];
    int lastMatchEnd = 0;
    for (var match in _typeTokenizationRegexp.allMatches(typeStr)) {
      var extraChars = typeStr.substring(lastMatchEnd, match.start).trim();
      if (extraChars.isNotEmpty) {
        throw ParseError(
            'Unrecognized character(s) in type `$typeStr`: $extraChars');
      }
      result.add(typeStr.substring(match.start, match.end));
      lastMatchEnd = match.end;
    }
    var extraChars = typeStr.substring(lastMatchEnd).trim();
    if (extraChars.isNotEmpty) {
      throw ParseError(
          'Unrecognized character(s) in type `$typeStr`: $extraChars');
    }
    result.add('<END>');
    return result;
  }
}

extension on List<Type> {
  /// Calls [Type.closureWithRespectToUnknown] to translate every list member
  /// into a type that doesn't involve the unknown type (`_`).  If no type would
  /// be changed by this operation, returns `null`.
  List<Type>? closureWithRespectToUnknown({required bool covariant}) {
    List<Type>? newList;
    for (int i = 0; i < length; i++) {
      Type type = this[i];
      Type? newType = type.closureWithRespectToUnknown(covariant: covariant);
      if (newList == null) {
        if (newType == null) continue;
        newList = sublist(0, i);
      }
      newList.add(newType ?? type);
    }
    return newList;
  }

  /// Calls [Type.recursivelyDemote] to translate every list member into a type
  /// that doesn't involve any type promotion.  If no type would be changed by
  /// this operation, returns `null`.
  List<Type>? recursivelyDemote({required bool covariant}) {
    List<Type>? newList;
    for (int i = 0; i < length; i++) {
      Type type = this[i];
      Type? newType = type.recursivelyDemote(covariant: covariant);
      if (newList == null) {
        if (newType == null) continue;
        newList = sublist(0, i);
      }
      newList.add(newType ?? type);
    }
    return newList;
  }
}
