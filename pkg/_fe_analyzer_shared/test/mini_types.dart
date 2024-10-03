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
class DynamicType extends _SpecialSimpleType
    implements SharedDynamicTypeStructure<Type> {
  static final instance = DynamicType._();

  DynamicType._()
      : super._(TypeRegistry.dynamic_,
            nullabilitySuffix: NullabilitySuffix.none);

  @override
  Type withNullability(NullabilitySuffix suffix) => this;
}

/// Representation of a function type suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
///
/// Type parameters are not (yet) supported.
class FunctionType extends Type
    implements
        SharedFunctionTypeStructure<Type, Never, NamedFunctionParameter> {
  @override
  final Type returnType;

  /// A list of the types of positional parameters.
  final List<Type> positionalParameters;

  @override
  final int requiredPositionalParameterCount;

  /// A list of the named parameters, sorted by name.
  final List<NamedFunctionParameter> namedParameters;

  FunctionType(this.returnType, this.positionalParameters,
      {int? requiredPositionalParameterCount,
      this.namedParameters = const [],
      super.nullabilitySuffix = NullabilitySuffix.none})
      : requiredPositionalParameterCount =
            requiredPositionalParameterCount ?? positionalParameters.length,
        super._() {
    for (var i = 1; i < namedParameters.length; i++) {
      assert(namedParameters[i - 1].name.compareTo(namedParameters[i].name) < 0,
          'namedParameters not properly sorted');
    }
  }

  @override
  List<Type> get positionalParameterTypes => positionalParameters;

  @override
  List<NamedFunctionParameter> get sortedNamedParameters => namedParameters;

  @override
  List<Never> get typeFormals => const [];

  @override
  Type? closureWithRespectToUnknown({required bool covariant}) {
    Type? newReturnType =
        returnType.closureWithRespectToUnknown(covariant: covariant);
    List<Type>? newPositionalParameters =
        positionalParameters.closureWithRespectToUnknown(covariant: !covariant);
    List<NamedFunctionParameter>? newNamedParameters =
        namedParameters.closureWithRespectToUnknown(covariant: !covariant);
    if (newReturnType == null &&
        newPositionalParameters == null &&
        newNamedParameters == null) {
      return null;
    }
    return FunctionType(newReturnType ?? returnType,
        newPositionalParameters ?? positionalParameters,
        requiredPositionalParameterCount: requiredPositionalParameterCount,
        namedParameters: newNamedParameters ?? namedParameters,
        nullabilitySuffix: nullabilitySuffix);
  }

  @override
  Type? recursivelyDemote({required bool covariant}) {
    Type? newReturnType = returnType.recursivelyDemote(covariant: covariant);
    List<Type>? newPositionalParameters =
        positionalParameters.recursivelyDemote(covariant: !covariant);
    List<NamedFunctionParameter>? newNamedParameters =
        namedParameters.recursivelyDemote(covariant: !covariant);
    if (newReturnType == null &&
        newPositionalParameters == null &&
        newNamedParameters == null) {
      return null;
    }
    return FunctionType(newReturnType ?? returnType,
        newPositionalParameters ?? positionalParameters,
        requiredPositionalParameterCount: requiredPositionalParameterCount,
        namedParameters: newNamedParameters ?? namedParameters,
        nullabilitySuffix: nullabilitySuffix);
  }

  @override
  Type withNullability(NullabilitySuffix suffix) =>
      FunctionType(returnType, positionalParameters,
          requiredPositionalParameterCount: requiredPositionalParameterCount,
          namedParameters: namedParameters,
          nullabilitySuffix: suffix);

  @override
  String _toStringWithoutSuffix({required bool parenthesizeIfComplex}) {
    var parameters = <Object>[
      ...positionalParameters.sublist(0, requiredPositionalParameterCount)
    ];
    if (requiredPositionalParameterCount < positionalParameters.length) {
      var optionalPositionalParameters =
          positionalParameters.sublist(requiredPositionalParameterCount);
      parameters.add('[${optionalPositionalParameters.join(', ')}]');
    }
    if (namedParameters.isNotEmpty) {
      parameters.add('{${namedParameters.join(', ')}}');
    }
    return _parenthesizeIf(parenthesizeIfComplex,
        '$returnType Function(${parameters.join(', ')})');
  }
}

/// Representation of the type `FutureOr<T>` suitable for unit testing of code
/// in the `_fe_analyzer_shared` package.
class FutureOrType extends PrimaryType {
  FutureOrType(Type typeArgument,
      {super.nullabilitySuffix = NullabilitySuffix.none})
      : super._special(TypeRegistry.futureOr, args: [typeArgument]);

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

/// A type name that represents an ordinary interface type.
class InterfaceTypeName extends TypeNameInfo {
  InterfaceTypeName._(super.name);
}

/// Representation of an invalid type suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
class InvalidType extends _SpecialSimpleType
    implements SharedInvalidTypeStructure<Type> {
  static final instance = InvalidType._();

  InvalidType._()
      : super._(TypeRegistry.error_, nullabilitySuffix: NullabilitySuffix.none);

  @override
  Type withNullability(NullabilitySuffix suffix) => this;
}

/// A named parameter of a function type.
class NamedFunctionParameter extends NamedType
    implements SharedNamedFunctionParameterStructure<Type> {
  @override
  final bool isRequired;

  NamedFunctionParameter(
      {required this.isRequired, required super.name, required super.type});

  @override
  String toString() => [if (isRequired) 'required', type, name].join(' ');
}

class NamedType implements SharedNamedTypeStructure<Type> {
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
      : super._(TypeRegistry.never);

  @override
  Type withNullability(NullabilitySuffix suffix) =>
      NeverType._(nullabilitySuffix: suffix);
}

/// Representation of the type `Null` suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
class NullType extends _SpecialSimpleType {
  static final instance = NullType._();

  NullType._()
      : super._(TypeRegistry.null_, nullabilitySuffix: NullabilitySuffix.none);

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
/// with zero or more type parameters (e.g. `double`, or `Map<int, String>`) or
/// one of the special types whose name is a single word (e.g. `dynamic`).
class PrimaryType extends Type {
  /// Information about the type name.
  final TypeNameInfo nameInfo;

  /// The type arguments, or `const []` if there are no type arguments.
  final List<Type> args;

  PrimaryType(InterfaceTypeName nameInfo,
      {List<Type> args = const [],
      NullabilitySuffix nullabilitySuffix = NullabilitySuffix.none})
      : this._(nameInfo, args: args, nullabilitySuffix: nullabilitySuffix);

  PrimaryType._(this.nameInfo,
      {this.args = const [], super.nullabilitySuffix = NullabilitySuffix.none})
      : super._();

  PrimaryType._special(SpecialTypeName nameInfo,
      {List<Type> args = const [],
      NullabilitySuffix nullabilitySuffix = NullabilitySuffix.none})
      : this._(nameInfo, args: args, nullabilitySuffix: nullabilitySuffix);

  bool get isInterfaceType {
    return nameInfo is InterfaceTypeName;
  }

  /// The name of the type.
  String get name => nameInfo.name;

  @override
  Type? closureWithRespectToUnknown({required bool covariant}) {
    List<Type>? newArgs =
        args.closureWithRespectToUnknown(covariant: covariant);
    if (newArgs == null) return null;
    return PrimaryType._(nameInfo,
        args: newArgs, nullabilitySuffix: nullabilitySuffix);
  }

  @override
  Type? recursivelyDemote({required bool covariant}) {
    List<Type>? newArgs = args.recursivelyDemote(covariant: covariant);
    if (newArgs == null) return null;
    return PrimaryType._(nameInfo,
        args: newArgs, nullabilitySuffix: nullabilitySuffix);
  }

  @override
  Type withNullability(NullabilitySuffix suffix) =>
      PrimaryType._(nameInfo, args: args, nullabilitySuffix: suffix);

  @override
  String _toStringWithoutSuffix({required bool parenthesizeIfComplex}) =>
      args.isEmpty ? name : '$name<${args.join(', ')}>';
}

class RecordType extends Type implements SharedRecordTypeStructure<Type> {
  @override
  final List<Type> positionalTypes;

  @override
  final List<NamedType> namedTypes;

  RecordType({
    required this.positionalTypes,
    required this.namedTypes,
    super.nullabilitySuffix = NullabilitySuffix.none,
  }) : super._() {
    for (var i = 1; i < namedTypes.length; i++) {
      assert(namedTypes[i - 1].name.compareTo(namedTypes[i].name) < 0,
          'namedTypes not properly sorted');
    }
  }

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

/// A type name that represents one of Dart's built-in "special" types, such as:
/// - `dynamic`
/// - `error` (to represent an invalid type)
/// - `FutureOr`
/// - `Never`
/// - `Null`
/// - `void`
class SpecialTypeName extends TypeNameInfo {
  SpecialTypeName._(super.name);
}

/// Representation of a type suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
abstract class Type implements SharedTypeStructure<Type> {
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
  bool isStructurallyEqualTo(SharedTypeStructure other) => '$this' == '$other';

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

/// Information about a single type name recognized by the [Type] parser.
sealed class TypeNameInfo {
  final String name;

  TypeNameInfo(this.name);
}

/// A type name that represents a type variable.
class TypeParameter extends TypeNameInfo
    implements SharedTypeParameterStructure<Type> {
  /// The type variable's bound. Defaults to `Object?`.
  Type bound;

  TypeParameter._(super.name) : bound = Type('Object?');

  @override
  String get displayName => name;

  @override
  String toString() => name;
}

/// Representation of a type parameter type suitable for unit testing of code in
/// the `_fe_analyzer_shared` package. A type parameter type might be promoted,
/// in which case it is often written using the syntax `a&b`, where `a` is the
/// type parameter and `b` is what it's promoted to.  For example, `T&int`
/// represents the type parameter `T`, promoted to `int`.
class TypeParameterType extends Type {
  /// The type parameter this type is based on.
  final TypeParameter typeParameter;

  /// If non-null, the promoted type.
  final Type? promotion;

  TypeParameterType(this.typeParameter,
      {this.promotion,
      NullabilitySuffix super.nullabilitySuffix = NullabilitySuffix.none})
      : super._();

  /// The type parameter's bound.
  Type get bound => typeParameter.bound;

  @override
  Type? closureWithRespectToUnknown({required bool covariant}) {
    var newPromotion =
        promotion?.closureWithRespectToUnknown(covariant: covariant);
    if (newPromotion == null) return null;
    return TypeParameterType(typeParameter,
        promotion: newPromotion, nullabilitySuffix: nullabilitySuffix);
  }

  @override
  Type? recursivelyDemote({required bool covariant}) {
    if (!covariant) {
      return NeverType.instance.withNullability(nullabilitySuffix);
    } else if (promotion == null) {
      return null;
    } else {
      return TypeParameterType(typeParameter,
          nullabilitySuffix: nullabilitySuffix);
    }
  }

  @override
  Type withNullability(NullabilitySuffix suffix) =>
      TypeParameterType(typeParameter,
          promotion: promotion, nullabilitySuffix: suffix);

  @override
  String _toStringWithoutSuffix({required bool parenthesizeIfComplex}) {
    if (promotion case var promotion?) {
      return _parenthesizeIf(
          parenthesizeIfComplex,
          '${typeParameter.name}&'
          '${promotion.toString(parenthesizeIfComplex: true)}');
    } else {
      return typeParameter.name;
    }
  }
}

/// Container for static methods that can be used to customize the "mini types"
/// representation used in `_fe_analyzer_shared` unit tests.
///
/// Thanks to Dart's scoping rules, it's possible for a single identifier to
/// represent an interface type in some contexts, a special type like `Null` in
/// other contexts, and a type parameter name in other contexts. But allowing a
/// single name to have multiple meanings isn't useful in `_fe_analyzer_shared`
/// unit tests, and opens up greater risk of confusion. Therefore, the "mini
/// types" representation does not permit it; every test must register each type
/// name it intends to use, specifying its meaning, before using that name in a
/// call to the [Type] constructor. This registration can happen either within
/// the test itself or in a callback passed to `setUp`.
abstract final class TypeRegistry {
  /// Type names that have been registered using [_add].
  static Map<String, TypeNameInfo>? _typeNameInfoMap;

  /// The [TypeNameInfo] object representing the special type `dynamic`.
  static final dynamic_ = SpecialTypeName._('dynamic');

  /// The [TypeNameInfo] object representing the special type `error`.
  static final error_ = SpecialTypeName._('error');

  /// The [TypeNameInfo] object representing the interface type `Future`.
  static final future = InterfaceTypeName._('Future');

  /// The [TypeNameInfo] object representing the special type `FutureOr`.
  static final futureOr = SpecialTypeName._('FutureOr');

  /// The [TypeNameInfo] object representing the interface type `Iterable`.
  static final iterable = InterfaceTypeName._('Iterable');

  /// The [TypeNameInfo] object representing the interface type `List`.
  static final list = InterfaceTypeName._('List');

  /// The [TypeNameInfo] object representing the interface type `Map`.
  static final map = InterfaceTypeName._('Map');

  /// The [TypeNameInfo] object representing the special type `Never`.
  static final never = SpecialTypeName._('Never');

  /// The [TypeNameInfo] object representing the special type `Null`.
  static final null_ = SpecialTypeName._('Null');

  /// The [TypeNameInfo] object representing the interface type `Stream`.
  static final stream = InterfaceTypeName._('Stream');

  /// The [TypeNameInfo] object representing the special type `void`.
  static final void_ = SpecialTypeName._('void');

  /// Gets [_typeNameInfoMap], throwing an exception if it has not been
  /// initialized.
  static Map<String, TypeNameInfo> get _typeNameInfoMapOrThrow =>
      _typeNameInfoMap ??
      (throw StateError(
          'TypeRegistry not initialized (call `TypeRegistry.init` from a test '
          '`setUp` callback)'));

  factory TypeRegistry._() => throw StateError('Do not construct');

  /// Registers [name] as the name of an ordinary interface type.
  static InterfaceTypeName addInterfaceTypeName(String name) {
    var interfaceTypeName = InterfaceTypeName._(name);
    _add(interfaceTypeName);
    return interfaceTypeName;
  }

  /// Registers [name] as the name of a type parameter.
  static TypeParameter addTypeParameter(String name) {
    var typeParameter = TypeParameter._(name);
    _add(typeParameter);
    return typeParameter;
  }

  /// Initializes the "mini type" infrastructure.
  ///
  /// This method must be called from a `setUp` callback before any unit test
  /// that makes use of mini types.
  static void init() {
    assert(StackTrace.current.toString().contains('runSetUps'),
        'Should be called from a test `setUp` method');
    if (_typeNameInfoMap != null) {
      throw StateError(
          'init() already called. Did you forget to call uninit() from '
          '`tearDown`?');
    }
    _typeNameInfoMap = {};
    // Set up some common built-in type names.
    addInterfaceTypeName('bool');
    addInterfaceTypeName('double');
    _add(dynamic_);
    _add(error_);
    _add(future);
    _add(futureOr);
    addInterfaceTypeName('int');
    _add(iterable);
    _add(list);
    _add(map);
    _add(never);
    _add(null_);
    addInterfaceTypeName('num');
    addInterfaceTypeName('Object');
    _add(stream);
    addInterfaceTypeName('String');
    _add(void_);
  }

  /// Retrieves the [TypeNameInfo] corresponding to [name].
  static TypeNameInfo lookup(String name) =>
      _typeNameInfoMapOrThrow[name] ??
      (throw StateError(
          'Unknown type name $name (use `TypeRegistry.add...` first)'));

  /// Un-does the operation of [init], rendering the "mini type" infrastructure
  /// unusable.
  ///
  /// This method should be called from a `tearDown` callback, complementing the
  /// call to [init] in a `setUp` callback.
  static void uninit() {
    // Note: don't complain if `_typeNameInfoMap` is `null`, because we don't
    // want to produce confusing failure messages if a test runs into trouble
    // while trying to initialize itself.
    _typeNameInfoMap = null;
  }

  /// Registers [info] as information about a type name.
  static void _add(TypeNameInfo info) {
    var name = info.name;
    var infoMap = _typeNameInfoMapOrThrow;
    if (infoMap.containsKey(name)) {
      throw StateError('Type name $name already registered');
    }
    infoMap[name] = info;
  }
}

class TypeSystem {
  static final Map<String, List<Type> Function(List<Type>)>
      _coreSuperInterfaceTemplates = {
    'bool': (_) => [Type('Object')],
    'double': (_) => [Type('num'), Type('Object')],
    'Future': (_) => [Type('Object')],
    'int': (_) => [Type('num'), Type('Object')],
    'Iterable': (_) => [Type('Object')],
    'List': (args) =>
        [PrimaryType(TypeRegistry.iterable, args: args), Type('Object')],
    'Map': (_) => [Type('Object')],
    'Object': (_) => [],
    'num': (_) => [Type('Object')],
    'String': (_) => [Type('Object')],
  };

  static final _objectQuestionType = Type('Object?');

  static final _objectType = Type('Object');

  final Map<String, List<Type> Function(List<Type>)> _superInterfaceTemplates =
      Map.of(_coreSuperInterfaceTemplates);

  void addSuperInterfaces(
      String className, List<Type> Function(List<Type>) template) {
    _superInterfaceTemplates[className] = template;
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
      if (isSubtype(PrimaryType(TypeRegistry.future, args: [r]), s)) {
        return factor(r, s);
      }
    }

    // Else if T is FutureOr<R> and R <: S then factor(Future<R>, S)
    if (t is FutureOrType) {
      var r = t.typeArgument;
      if (isSubtype(r, s)) {
        return factor(PrimaryType(TypeRegistry.future, args: [r]), s);
      }
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
    switch ((t0, t1)) {
      case (
            PrimaryType(
              nameInfo: var t0Info,
              nullabilitySuffix: NullabilitySuffix.none,
              args: []
            ),
            PrimaryType(
              nameInfo: var t1Info,
              nullabilitySuffix: NullabilitySuffix.none,
              args: []
            )
          )
          when t0Info == t1Info:
      case (
            TypeParameterType(
              typeParameter: var x0,
              promotion: null,
              nullabilitySuffix: NullabilitySuffix.none
            ),
            TypeParameterType(
              typeParameter: var x1,
              promotion: null,
              nullabilitySuffix: NullabilitySuffix.none
            )
          )
          when x0 == x1:
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
      if (t0
          case TypeParameterType(
            bound: var b,
            promotion: null,
            nullabilitySuffix: NullabilitySuffix.none
          )) {
        return isSubtype(b, _objectType);
      }

      // - if T0 is a promoted type variable X & S then T0 <: T1 iff S <: Object
      if (t0
          case TypeParameterType(
            promotion: var s?,
            nullabilitySuffix: NullabilitySuffix.none
          )) {
        return isSubtype(s, _objectType);
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
      if (t1
          case TypeParameterType(nullabilitySuffix: NullabilitySuffix.none)) {
        return false;
      }

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
      return isSubtype(PrimaryType(TypeRegistry.future, args: [s0]), t1) &&
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
    if ((t0, t1)
        case (
          TypeParameterType(
            typeParameter: var x0,
            nullabilitySuffix: NullabilitySuffix.none
          ),
          TypeParameterType(
            typeParameter: var x1,
            promotion: null,
            nullabilitySuffix: NullabilitySuffix.none
          )
        ) when x0 == x1) {
      // - T0 <: T1
      return true;
    }

    // Type Variable Reflexivity 2: if T0 is a type variable X0 or a promoted
    // type variables X0 & S0 and T1 is X0 & S1 then:
    if ((t0, t1)
        case (
          TypeParameterType(
            typeParameter: var x0,
            nullabilitySuffix: NullabilitySuffix.none
          ),
          TypeParameterType(
            typeParameter: var x1,
            promotion: var s1?,
            nullabilitySuffix: NullabilitySuffix.none
          )
        ) when x0 == x1) {
      // - T0 <: T1 iff T0 <: S1.
      return isSubtype(t0, s1);
    }

    // Right Promoted Variable: if T1 is a promoted type variable X1 & S1 then:
    if (t1
        case TypeParameterType(
          typeParameter: var x1,
          promotion: var s1?,
          nullabilitySuffix: NullabilitySuffix.none
        )) {
      // - T0 <: T1 iff T0 <: X1 and T0 <: S1
      return isSubtype(t0, TypeParameterType(x1)) && isSubtype(t0, s1);
    }

    // Right FutureOr: if T1 is FutureOr<S1> then:
    if (t1 is FutureOrType && t1.nullabilitySuffix == NullabilitySuffix.none) {
      var s1 = t1.typeArgument;

      // - T0 <: T1 iff any of the following hold:
      //   - either T0 <: Future<S1>
      if (isSubtype(t0, PrimaryType(TypeRegistry.future, args: [s1]))) {
        return true;
      }
      //   - or T0 <: S1
      if (isSubtype(t0, s1)) return true;
      //   - or T0 is X0 and X0 has bound S0 and S0 <: T1
      if (t0 case TypeParameterType(bound: var s0, promotion: null)
          when isSubtype(s0, t1)) {
        return true;
      }
      //   - or T0 is X0 & S0 and S0 <: T1
      if (t0 case TypeParameterType(promotion: var s0?)
          when isSubtype(s0, t1)) {
        return true;
      }
      return false;
    }

    // Right Nullable: if T1 is S1? then:
    if (t1.nullabilitySuffix == NullabilitySuffix.question) {
      var s1 = t1.withNullability(NullabilitySuffix.none);

      // - T0 <: T1 iff any of the following hold:
      //   - either T0 <: S1
      if (isSubtype(t0, s1)) return true;
      //   - or T0 <: Null
      if (isSubtype(t0, NullType.instance)) return true;
      //   - or T0 is X0 and X0 has bound S0 and S0 <: T1
      if (t0 case TypeParameterType(bound: var s0, promotion: null)
          when isSubtype(s0, t1)) {
        return true;
      }
      //   - or T0 is X0 & S0 and S0 <: T1
      if (t0 case TypeParameterType(promotion: var s0?)
          when isSubtype(s0, t1)) {
        return true;
      }
      return false;
    }

    // Left Promoted Variable: T0 is a promoted type variable X0 & S0
    if (t0 case TypeParameterType(promotion: var s0?)) {
      // - and S0 <: T1
      if (isSubtype(s0, t1)) return true;
    }

    // Left Type Variable Bound: T0 is a type variable X0 with bound B0
    if (t0 case TypeParameterType(bound: var b0, promotion: null)) {
      // - and B0 <: T1
      if (isSubtype(b0, t1)) return true;
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
      if (t0 is! PrimaryType) return false;
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
      if (t0 is! FunctionType || t0.namedParameters.isNotEmpty) return false;
      var n = t0.requiredPositionalParameterCount;
      var m = t0.positionalParameters.length;

      // - and T1 is U1 Function<Y0 extends B10, ..., Yk extends B1k>(S0 y0,
      //   ..., Sp yp, [Sp+1 yp+1, ..., Sq yq])
      if (t1 is! FunctionType || t1.namedParameters.isNotEmpty) return false;
      var p = t1.requiredPositionalParameterCount;
      var q = t1.positionalParameters.length;

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
      if (t0 is! FunctionType) return false;
      var n = t0.positionalParameters.length;
      if (t0.requiredPositionalParameterCount != n) return false;

      // - and T1 is U1 Function<Y0 extends B10, ..., Yk extends B1k>(S0 y0,
      //   ..., Sn yn, {r1n+1 Sn+1 yn+1, ..., r1q Sq yq}) where r1j is empty or
      //   required for j in n+1...q
      if (t1 is! FunctionType ||
          t1.positionalParameters.length != n ||
          t1.requiredPositionalParameterCount != n) {
        return false;
      }

      // - and {yn+1, ... , yq} subsetof {xn+1, ... , xm}
      var t1IndexToT0Index = <int>[];
      for (var i = 0, j = 0;
          i < t0.namedParameters.length || j < t1.namedParameters.length;) {
        if (i >= t0.namedParameters.length) break;
        if (j >= t1.namedParameters.length) return false;
        switch (
            t0.namedParameters[i].name.compareTo(t1.namedParameters[j].name)) {
          case < 0:
            i++;
          case > 0:
            return false;
          default: // == 0
            t1IndexToT0Index.add(i);
            i++;
            j++;
        }
      }

      // (Note: no substitution is needed in the code below; we don't support
      // type arguments on function types)

      // - and Si[Z0/Y0, ..., Zk/Yk] <: Vi[Z0/X0, ..., Zk/Xk] for i in 0...n
      for (var i = 0; i < n; i++) {
        if (!isSubtype(
            t1.positionalParameters[i], t0.positionalParameters[i])) {
          return false;
        }
      }

      // - and Si[Z0/Y0, ..., Zk/Yk] <: Tj[Z0/X0, ..., Zk/Xk] for i in n+1...q,
      //   yj = xi
      for (var j = 0; j < t1IndexToT0Index.length; j++) {
        var i = t1IndexToT0Index[j];
        if (!isSubtype(
            t1.namedParameters[j].type, t0.namedParameters[i].type)) {
          return false;
        }
      }

      // - and for each j such that r0j is required, then there exists an i in
      //   n+1...q such that xj = yi, and r1i is required
      for (var j = 0; j < t1IndexToT0Index.length; j++) {
        var i = t1IndexToT0Index[j];
        if (t1.namedParameters[j].isRequired &&
            !t0.namedParameters[i].isRequired) {
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
}

/// Representation of the unknown type suitable for unit testing of code in the
/// `_fe_analyzer_shared` package.
class UnknownType extends Type implements SharedUnknownTypeStructure<Type> {
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
class VoidType extends _SpecialSimpleType
    implements SharedVoidTypeStructure<Type> {
  static final instance = VoidType._();

  VoidType._()
      : super._(TypeRegistry.void_, nullabilitySuffix: NullabilitySuffix.none);

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
  _SpecialSimpleType._(super.nameInfo,
      {super.nullabilitySuffix = NullabilitySuffix.none})
      : super._special();

  @override
  Type? closureWithRespectToUnknown({required bool covariant}) => null;

  @override
  Type? recursivelyDemote({required bool covariant}) => null;
}

class _TypeParser {
  static final _typeTokenizationRegexp =
      RegExp(_identifierPattern + r'|\(|\)|<|>|,|\?|\*|&|{|}|\[|\]');

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

  List<NamedFunctionParameter> _parseNamedFunctionParameters() {
    assert(_currentToken == '{');
    _next();
    var namedParameters = <NamedFunctionParameter>[];
    while (true) {
      var isRequired = _currentToken == 'required';
      if (isRequired) {
        _next();
      }
      var type = _parseType();
      var name = _currentToken;
      if (_identifierRegexp.matchAsPrefix(name) == null) {
        _parseFailure('Expected an identifier');
      }
      namedParameters.add(NamedFunctionParameter(
          name: name, type: type, isRequired: isRequired));
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
    _next();
    namedParameters.sort((a, b) => a.name.compareTo(b.name));
    return namedParameters;
  }

  void _parseOptionalFunctionParameters(List<Type> positionalParameterTypes) {
    assert(_currentToken == '[');
    _next();
    while (true) {
      var type = _parseType();
      positionalParameterTypes.add(type);
      if (_currentToken == ',') {
        _next();
        continue;
      }
      if (_currentToken == ']') {
        break;
      }
      _parseFailure('Expected `]` or `,`');
    }
    _next();
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
    namedTypes.sort((a, b) => a.name.compareTo(b.name));
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
      if (type case TypeParameterType(promotion: null)) {
        _next();
        var promotion = _parseUnsuffixedType();
        return TypeParameterType(type.typeParameter, promotion: promotion);
      } else {
        _parseFailure(
            'The type to the left of & must be an unpromoted type parameter');
      }
    } else if (_currentToken == 'Function') {
      _next();
      if (_currentToken != '(') {
        _parseFailure('Expected `(`');
      }
      _next();
      var positionalParameterTypes = <Type>[];
      List<NamedFunctionParameter>? namedFunctionParameters;
      int? requiredPositionalParameterCount;
      if (_currentToken != ')') {
        while (true) {
          if (_currentToken == '{') {
            namedFunctionParameters = _parseNamedFunctionParameters();
            if (_currentToken != ')') {
              _parseFailure('Expected `)`');
            }
            break;
          } else if (_currentToken == '[') {
            requiredPositionalParameterCount = positionalParameterTypes.length;
            _parseOptionalFunctionParameters(positionalParameterTypes);
            if (_currentToken != ')') {
              _parseFailure('Expected `)`');
            }
            break;
          }
          positionalParameterTypes.add(_parseType());
          if (_currentToken == ')') break;
          if (_currentToken != ',') {
            _parseFailure('Expected `,` or `)`');
          }
          _next();
        }
      }
      _next();
      return FunctionType(type, positionalParameterTypes,
          requiredPositionalParameterCount: requiredPositionalParameterCount ??
              positionalParameterTypes.length,
          namedParameters: namedFunctionParameters ?? const []);
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
    //           | `Function` `(` (type `,`)* namedFunctionParameters `)`
    //           | `Function` `(` (type `,`)* optionalFunctionParameters `)`
    //           | `?`
    //           | `*`
    //           | `&` unsuffixedType
    //   namedFunctionParameters := `{` namedFunctionParameter
    //                              (`,` namedFunctionParameter)* `}`
    //   namedFunctionParameter := `required`? type identifier
    //   optionalFunctionParameters := `[` type (`,` type)* `]`
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
    var nameInfo = TypeRegistry.lookup(typeName);
    switch (nameInfo) {
      case TypeParameter():
        if (typeArgs.isNotEmpty) {
          throw ParseError('Type parameter types do not accept type arguments');
        }
        return TypeParameterType(nameInfo);
      case InterfaceTypeName():
        return PrimaryType(nameInfo, args: typeArgs);
      case SpecialTypeName():
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
          throw UnimplementedError('Unknown special type name: $typeName');
        }
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

extension on List<NamedFunctionParameter> {
  /// Calls [Type.closureWithRespectToUnknown] to translate every list member
  /// into a type that doesn't involve the unknown type (`_`).  If no type would
  /// be changed by this operation, returns `null`.
  List<NamedFunctionParameter>? closureWithRespectToUnknown(
      {required bool covariant}) {
    List<NamedFunctionParameter>? newList;
    for (int i = 0; i < length; i++) {
      NamedFunctionParameter namedFunctionParameter = this[i];
      Type? newType = namedFunctionParameter.type
          .closureWithRespectToUnknown(covariant: covariant);
      if (newList == null) {
        if (newType == null) continue;
        newList = sublist(0, i);
      }
      newList.add(newType == null
          ? namedFunctionParameter
          : NamedFunctionParameter(
              isRequired: namedFunctionParameter.isRequired,
              name: namedFunctionParameter.name,
              type: newType));
    }
    return newList;
  }

  /// Calls [Type.recursivelyDemote] to translate every list member into a type
  /// that doesn't involve any type promotion.  If no type would be changed by
  /// this operation, returns `null`.
  List<NamedFunctionParameter>? recursivelyDemote({required bool covariant}) {
    List<NamedFunctionParameter>? newList;
    for (int i = 0; i < length; i++) {
      NamedFunctionParameter namedFunctionParameter = this[i];
      Type? newType =
          namedFunctionParameter.type.recursivelyDemote(covariant: covariant);
      if (newList == null) {
        if (newType == null) continue;
        newList = sublist(0, i);
      }
      newList.add(newType == null
          ? namedFunctionParameter
          : NamedFunctionParameter(
              isRequired: namedFunctionParameter.isRequired,
              name: namedFunctionParameter.name,
              type: newType));
    }
    return newList;
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
