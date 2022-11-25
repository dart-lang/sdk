// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'core_patch.dart';

// Representation of runtime types. Code in this file should avoid using `is` or
// `as` entirely to avoid a dependency on any inline type checks.

// TODO(joshualitt): Once we have RTI fully working, we'd like to explore
// implementing [isSubtype] using inheritance.
// TODO(joshualitt): We can cache the results of a number of functions in this
// file:
//   * [_Type.asNonNullable]
//   * [_FutureOrType.asFuture].
// TODO(joshualitt): Make `Function` a canonical type.
abstract class _Type implements Type {
  final bool isDeclaredNullable;

  const _Type(this.isDeclaredNullable);

  bool _testID(int value) => ClassID.getID(this) == value;
  bool get isNever => _testID(ClassID.cidNeverType);
  bool get isDynamic => _testID(ClassID.cidDynamicType);
  bool get isVoid => _testID(ClassID.cidVoidType);
  bool get isNull => _testID(ClassID.cidNullType);
  bool get isFutureOr => _testID(ClassID.cidFutureOrType);
  bool get isInterface => _testID(ClassID.cidInterfaceType);
  bool get isInterfaceTypeParameterType =>
      _testID(ClassID.cidInterfaceTypeParameterType);
  bool get isFunctionTypeParameterType =>
      _testID(ClassID.cidFunctionTypeParameterType);
  bool get isFunction => _testID(ClassID.cidFunctionType);

  T as<T>() => unsafeCast<T>(this);

  _Type get asNonNullable => isDeclaredNullable ? _asNonNullable : this;
  _Type get asNullable => isDeclaredNullable ? this : _asNullable;

  _Type get _asNonNullable;
  _Type get _asNullable;

  @override
  bool operator ==(Object other) => ClassID.getID(this) == ClassID.getID(other);

  @override
  int get hashCode => mix64(ClassID.getID(this));
}

@pragma("wasm:entry-point")
class _NeverType extends _Type {
  @pragma("wasm:entry-point")
  const _NeverType() : super(false);

  @override
  _Type get _asNonNullable => this;

  /// Never? normalizes to Null.
  @override
  _Type get _asNullable => const _NullType();

  @override
  String toString() => 'Never';
}

@pragma("wasm:entry-point")
class _DynamicType extends _Type {
  @pragma("wasm:entry-point")
  const _DynamicType() : super(true);

  @override
  _Type get _asNonNullable => throw '`dynamic` type is always nullable.';

  @override
  _Type get _asNullable => this;

  @override
  String toString() => 'dynamic';
}

@pragma("wasm:entry-point")
class _VoidType extends _Type {
  @pragma("wasm:entry-point")
  const _VoidType() : super(true);

  @override
  _Type get _asNonNullable => throw '`void` type is always nullable.';

  @override
  _Type get _asNullable => this;

  @override
  String toString() => 'void';
}

@pragma("wasm:entry-point")
class _NullType extends _Type {
  @pragma("wasm:entry-point")
  const _NullType() : super(true);

  @override
  _Type get _asNonNullable => const _NeverType();

  @override
  _Type get _asNullable => this;

  @override
  String toString() => 'Null';
}

/// Reference to a type parameter of an interface type.
///
/// This type is only used in the representation of the supertype type parameter
/// mapping and never occurs in runtime types.
@pragma("wasm:entry-point")
class _InterfaceTypeParameterType extends _Type {
  final int environmentIndex;

  @pragma("wasm:entry-point")
  const _InterfaceTypeParameterType(
      super.isDeclaredNullable, this.environmentIndex);

  @override
  _Type get _asNonNullable =>
      throw 'Type parameter should have been substituted already.';

  @override
  _Type get _asNullable =>
      throw 'Type parameter should have been substituted already.';

  @override
  String toString() => 'T$environmentIndex';
}

/// Reference to a type parameter of a function type.
///
/// This type only occurs inside generic function types.
@pragma("wasm:entry-point")
class _FunctionTypeParameterType extends _Type {
  /// The nesting depth of the function type declaring this type parameter,
  /// i.e. the number of function types it is embedded inside.
  final int depth;

  /// The index of this type parameter in the function type's list of type
  /// parameters.
  final int index;

  @pragma("wasm:entry-point")
  const _FunctionTypeParameterType(
      super.isDeclaredNullable, this.depth, this.index);

  @override
  _Type get _asNonNullable => _FunctionTypeParameterType(false, depth, index);

  @override
  _Type get _asNullable => _FunctionTypeParameterType(true, depth, index);

  @override
  bool operator ==(Object o) {
    if (!(super == o)) return false;
    _FunctionTypeParameterType other =
        unsafeCast<_FunctionTypeParameterType>(o);
    return depth == other.depth && index == other.index;
  }

  @override
  int get hashCode {
    int hash = super.hashCode;
    hash = mix64(hash ^ (isDeclaredNullable ? 1 : 0));
    hash = mix64(hash ^ depth.hashCode);
    return mix64(hash ^ index.hashCode);
  }

  // TODO(askesc): Distinguish the depth of function type parameters.
  @override
  String toString() => 'X$index';
}

@pragma("wasm:entry-point")
class _FutureOrType extends _Type {
  final _Type typeArgument;

  @pragma("wasm:entry-point")
  const _FutureOrType(super.isDeclaredNullable, this.typeArgument);

  _InterfaceType get asFuture =>
      _InterfaceType(ClassID.cidFuture, isDeclaredNullable, [typeArgument]);

  // Removing a `?` from a type should not require additional normalization.
  @override
  _Type get _asNonNullable => _FutureOrType(false, typeArgument);

  @override
  _Type get _asNullable =>
      _TypeUniverse.createNormalizedFutureOrType(true, typeArgument);

  @override
  bool operator ==(Object o) {
    if (!(super == o)) return false;
    _FutureOrType other = unsafeCast<_FutureOrType>(o);
    if (isDeclaredNullable != other.isDeclaredNullable) return false;
    return typeArgument == other.typeArgument;
  }

  @override
  int get hashCode {
    int hash = super.hashCode;
    hash = mix64(hash ^ (isDeclaredNullable ? 1 : 0));
    return mix64(hash ^ typeArgument.hashCode);
  }

  @override
  String toString() {
    StringBuffer s = StringBuffer();
    s.write("FutureOr");
    s.write("<");
    s.write(typeArgument);
    s.write(">");
    if (isDeclaredNullable) s.write("?");
    return s.toString();
  }
}

class _InterfaceType extends _Type {
  final int classId;
  final List<_Type> typeArguments;

  @pragma("wasm:entry-point")
  const _InterfaceType(this.classId, super.isDeclaredNullable,
      [this.typeArguments = const []]);

  @override
  _Type get _asNonNullable => _InterfaceType(classId, false, typeArguments);

  @override
  _Type get _asNullable => _InterfaceType(classId, true, typeArguments);

  @override
  bool operator ==(Object o) {
    if (!(super == o)) return false;
    _InterfaceType other = unsafeCast<_InterfaceType>(o);
    if (classId != other.classId) return false;
    if (isDeclaredNullable != other.isDeclaredNullable) return false;
    assert(typeArguments.length == other.typeArguments.length);
    for (int i = 0; i < typeArguments.length; i++) {
      if (typeArguments[i] != other.typeArguments[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    int hash = super.hashCode;
    hash = mix64(hash ^ classId);
    hash = mix64(hash ^ (isDeclaredNullable ? 1 : 0));
    for (int i = 0; i < typeArguments.length; i++) {
      hash = mix64(hash ^ typeArguments[i].hashCode);
    }
    return hash;
  }

  @override
  String toString() {
    StringBuffer s = StringBuffer();
    s.write(_getTypeNames()[classId]);
    if (typeArguments.isNotEmpty) {
      s.write("<");
      for (int i = 0; i < typeArguments.length; i++) {
        if (i > 0) s.write(", ");
        s.write(typeArguments[i]);
      }
      s.write(">");
    }
    if (isDeclaredNullable) s.write("?");
    return s.toString();
  }
}

class _NamedParameter {
  final String name;
  final _Type type;
  final bool isRequired;

  @pragma("wasm:entry-point")
  const _NamedParameter(this.name, this.type, this.isRequired);

  @override
  bool operator ==(Object o) {
    if (ClassID.getID(this) != ClassID.getID(o)) return false;
    _NamedParameter other = unsafeCast<_NamedParameter>(o);
    return this.name == other.name &&
        this.type == other.type &&
        isRequired == other.isRequired;
  }

  @override
  int get hashCode {
    int hash = mix64(ClassID.getID(this));
    hash = mix64(hash ^ name.hashCode);
    hash = mix64(hash ^ type.hashCode);
    return mix64(hash ^ (isRequired ? 1 : 0));
  }

  @override
  String toString() {
    StringBuffer s = StringBuffer();
    if (isRequired) s.write('required ');
    s.write(type);
    s.write(' ');
    s.write(name);
    return s.toString();
  }
}

class _FunctionType extends _Type {
  final List<_Type> typeParameterBounds;
  final _Type returnType;
  final List<_Type> positionalParameters;
  final int requiredParameterCount;
  final List<_NamedParameter> namedParameters;

  @pragma("wasm:entry-point")
  const _FunctionType(
      this.typeParameterBounds,
      this.returnType,
      this.positionalParameters,
      this.requiredParameterCount,
      this.namedParameters,
      super.isDeclaredNullable);

  @override
  _Type get _asNonNullable => _FunctionType(typeParameterBounds, returnType,
      positionalParameters, requiredParameterCount, namedParameters, false);

  @override
  _Type get _asNullable => _FunctionType(typeParameterBounds, returnType,
      positionalParameters, requiredParameterCount, namedParameters, true);

  bool operator ==(Object o) {
    if (!(super == o)) return false;
    _FunctionType other = unsafeCast<_FunctionType>(o);
    if (isDeclaredNullable != other.isDeclaredNullable) return false;
    if (typeParameterBounds.length != other.typeParameterBounds.length) {
      return false;
    }
    if (returnType != other.returnType) return false;
    if (positionalParameters.length != other.positionalParameters.length) {
      return false;
    }
    if (requiredParameterCount != other.requiredParameterCount) return false;
    if (namedParameters.length != other.namedParameters.length) return false;
    for (int i = 0; i < typeParameterBounds.length; i++) {
      if (typeParameterBounds[i] != other.typeParameterBounds[i]) return false;
    }
    for (int i = 0; i < positionalParameters.length; i++) {
      if (positionalParameters[i] != other.positionalParameters[i]) {
        return false;
      }
    }
    for (int i = 0; i < namedParameters.length; i++) {
      if (namedParameters[i] != other.namedParameters[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    int hash = super.hashCode;
    for (int i = 0; i < typeParameterBounds.length; i++) {
      hash = mix64(hash ^ typeParameterBounds[i].hashCode);
    }
    hash = mix64(hash ^ (isDeclaredNullable ? 1 : 0));
    hash = mix64(hash ^ returnType.hashCode);
    for (int i = 0; i < positionalParameters.length; i++) {
      hash = mix64(hash ^ positionalParameters[i].hashCode);
    }
    hash = mix64(hash ^ requiredParameterCount);
    for (int i = 0; i < namedParameters.length; i++) {
      hash = mix64(hash ^ namedParameters[i].hashCode);
    }
    return hash;
  }

  @override
  String toString() {
    StringBuffer s = StringBuffer();
    s.write(returnType);
    s.write(" Function");
    if (typeParameterBounds.isNotEmpty) {
      s.write("<");
      for (int i = 0; i < typeParameterBounds.length; i++) {
        if (i > 0) s.write(", ");
        // TODO(askesc): Distinguish the depth of function type parameters.
        s.write("X$i extends ");
        s.write(typeParameterBounds[i]);
      }
      s.write(">");
    }
    s.write("(");
    for (int i = 0; i < positionalParameters.length; i++) {
      if (i > 0) s.write(", ");
      if (i == requiredParameterCount) s.write("[");
      s.write(positionalParameters[i]);
    }
    if (requiredParameterCount < positionalParameters.length) s.write("]");
    if (namedParameters.isNotEmpty) {
      if (positionalParameters.isNotEmpty) s.write(", ");
      s.write("{");
      for (int i = 0; i < namedParameters.length; i++) {
        if (i > 0) s.write(", ");
        s.write(namedParameters[i]);
      }
      s.write("}");
    }
    s.write(")");
    if (isDeclaredNullable) s.write("?");
    return s.toString();
  }
}

external List<List<int>> _getTypeRulesSupers();
external List<List<List<_Type>>> _getTypeRulesSubstitutions();
external List<String> _getTypeNames();

/// Type parameter environment used while comparing function types.
///
/// In the case of nested function types, the environment refers to the
/// innermost function type and has a reference to the enclosing function type
/// environment.
class _Environment {
  /// The environment of the enclosing function type, or `null` if this is the
  /// outermost function type.
  final _Environment? parent;

  /// The type parameter bounds of the current function type.
  final List<_Type> bounds;

  /// The nesting depth of the current function type.
  final int depth;

  _Environment(this.parent, this.bounds)
      : depth = parent == null ? 0 : parent.depth + 1;

  /// Look up the bound of a function type parameter in the environment.
  _Type lookup(_FunctionTypeParameterType param) {
    _Environment env = this;
    while (env.depth != param.depth) {
      env = env.parent!;
    }
    return env.bounds[param.index];
  }
}

class _TypeUniverse {
  /// 'Map' of classId to the transitive set of super classes it implements.
  final List<List<int>> typeRulesSupers;

  /// 'Map' of classId, and super offset(from [typeRulesSupers]) to a list of
  /// type substitutions.
  final List<List<List<_Type>>> typeRulesSubstitutions;

  const _TypeUniverse._(this.typeRulesSupers, this.typeRulesSubstitutions);

  factory _TypeUniverse.create() {
    return _TypeUniverse._(_getTypeRulesSupers(), _getTypeRulesSubstitutions());
  }

  static bool isSpecificInterfaceType(_Type t, int classId) {
    if (!t.isInterface) return false;
    _InterfaceType type = t.as<_InterfaceType>();
    return type.classId == classId;
  }

  static bool isObjectQuestionType(_Type t) =>
      isObjectType(t) && t.isDeclaredNullable;

  static bool isObjectType(_Type t) =>
      isSpecificInterfaceType(t, ClassID.cidObject);

  static bool isTopType(_Type type) {
    return isObjectQuestionType(type) || type.isDynamic || type.isVoid;
  }

  static bool isBottomType(_Type type) {
    return type.isNever;
  }

  static bool isFunctionType(_Type t) =>
      isSpecificInterfaceType(t, ClassID.cidFunction) ||
      isSpecificInterfaceType(t, ClassID.cid_Function);

  static _Type substituteTypeParameter(
      _InterfaceTypeParameterType typeParameter, List<_Type> substitutions) {
    // If the type parameter is non-nullable, or the substitution type is
    // nullable, then just return the substitution type. Otherwise, we return
    // [type] as nullable.
    // Note: This will throw if the required nullability is impossible to
    // generate.
    _Type substitution = substitutions[typeParameter.environmentIndex];
    if (typeParameter.isDeclaredNullable) return substitution.asNullable;
    return substitution;
  }

  static _Type substituteTypeArgument(_Type type, List<_Type> substitutions) {
    if (type.isNever || type.isDynamic || type.isVoid || type.isNull) {
      return type;
    } else if (type.isFutureOr) {
      return createNormalizedFutureOrType(
          type.isDeclaredNullable,
          substituteTypeArgument(
              type.as<_FutureOrType>().typeArgument, substitutions));
    } else if (type.isInterface) {
      _InterfaceType interfaceType = type.as<_InterfaceType>();
      return _InterfaceType(
          interfaceType.classId,
          interfaceType.isDeclaredNullable,
          interfaceType.typeArguments
              .map((type) => substituteTypeArgument(type, substitutions))
              .toList());
    } else if (type.isInterfaceTypeParameterType) {
      return substituteTypeParameter(
          type.as<_InterfaceTypeParameterType>(), substitutions);
    } else if (type.isFunction) {
      _FunctionType functionType = type.as<_FunctionType>();
      return _FunctionType(
          functionType.typeParameterBounds
              .map((type) => substituteTypeArgument(type, substitutions))
              .toList(),
          substituteTypeArgument(functionType.returnType, substitutions),
          functionType.positionalParameters
              .map((type) => substituteTypeArgument(type, substitutions))
              .toList(),
          functionType.requiredParameterCount,
          functionType.namedParameters
              .map((named) => _NamedParameter(
                  named.name,
                  substituteTypeArgument(named.type, substitutions),
                  named.isRequired))
              .toList(),
          functionType.isDeclaredNullable);
    } else {
      throw 'Type argument substitution not supported for $type';
    }
  }

  static List<_Type> substituteTypeArguments(
          List<_Type> types, List<_Type> substitutions) =>
      List<_Type>.generate(types.length,
          (int index) => substituteTypeArgument(types[index], substitutions),
          growable: false);

  static _Type createNormalizedFutureOrType(
      bool isDeclaredNullable, _Type typeArgument) {
    if (isTopType(typeArgument) || isObjectType(typeArgument)) {
      return typeArgument;
    } else if (typeArgument.isNever) {
      return _InterfaceType(
          ClassID.cidFuture, isDeclaredNullable, [const _NeverType()]);
    } else if (typeArgument.isNull) {
      return _InterfaceType(ClassID.cidFuture, true, [const _NullType()]);
    }

    bool declaredNullability =
        typeArgument.isDeclaredNullable ? false : isDeclaredNullable;
    return _FutureOrType(declaredNullability, typeArgument);
  }

  bool areTypeArgumentsSubtypes(List<_Type> sArgs, _Environment? sEnv,
      List<_Type> tArgs, _Environment? tEnv) {
    assert(sArgs.length == tArgs.length);
    for (int i = 0; i < sArgs.length; i++) {
      if (!isSubtype(sArgs[i], sEnv, tArgs[i], tEnv)) {
        return false;
      }
    }
    return true;
  }

  bool isInterfaceSubtype(_InterfaceType s, _Environment? sEnv,
      _InterfaceType t, _Environment? tEnv) {
    int sId = s.classId;
    int tId = t.classId;

    // If we have the same class, simply compare type arguments.
    if (sId == tId) {
      return areTypeArgumentsSubtypes(
          s.typeArguments, sEnv, t.typeArguments, tEnv);
    }

    // Otherwise, check if [s] is a subtype of [t], and if it is then compare
    // [s]'s type substitutions with [t]'s type arguments.
    List<int> sSupers = typeRulesSupers[sId];
    if (sSupers.isEmpty) return false;
    int sSuperIndexOfT = sSupers.indexOf(tId);
    if (sSuperIndexOfT == -1) return false;
    assert(sSuperIndexOfT < typeRulesSubstitutions[sId].length);

    // Return early if we don't have have to check type arguments.
    List<_Type> sTypeArguments = s.typeArguments;
    List<_Type> substitutions = typeRulesSubstitutions[sId][sSuperIndexOfT];
    if (substitutions.isEmpty && sTypeArguments.isEmpty) {
      return true;
    }

    // If we have empty type arguments then create a list of dynamic type
    // arguments.
    if (substitutions.isNotEmpty && sTypeArguments.isEmpty) {
      sTypeArguments = List<_Type>.generate(
          substitutions.length, (int index) => const _DynamicType(),
          growable: false);
    }

    // Finally substitute arguments. We must do this upfront so we can normalize
    // the type.
    // TODO(joshualitt): This process is expensive so we should cache the
    // result.
    List<_Type> substituted =
        substituteTypeArguments(substitutions, sTypeArguments);
    return areTypeArgumentsSubtypes(substituted, sEnv, t.typeArguments, tEnv);
  }

  bool isFunctionSubtype(_FunctionType s, _Environment? sEnv, _FunctionType t,
      _Environment? tEnv) {
    // Set up environments
    sEnv = _Environment(sEnv, s.typeParameterBounds);
    tEnv = _Environment(tEnv, t.typeParameterBounds);

    // Check that [s] and [t] have the same number of type parameters and that
    // their bounds are equivalent.
    int sTypeParameterCount = s.typeParameterBounds.length;
    int tTypeParameterCount = t.typeParameterBounds.length;
    if (sTypeParameterCount != tTypeParameterCount) return false;
    for (int i = 0; i < sTypeParameterCount; i++) {
      if (!areEquivalent(
          s.typeParameterBounds[i], sEnv, t.typeParameterBounds[i], tEnv)) {
        return false;
      }
    }

    if (!isSubtype(s.returnType, sEnv, t.returnType, tEnv)) return false;

    // Check [s] does not have more required positional arguments than [t].
    int sRequiredCount = s.requiredParameterCount;
    int tRequiredCount = t.requiredParameterCount;
    if (sRequiredCount > tRequiredCount) {
      return false;
    }

    // Check [s] has enough required and optional positional arguments to
    // potentially be a valid subtype of [t].
    List<_Type> sPositional = s.positionalParameters;
    List<_Type> tPositional = t.positionalParameters;
    int sPositionalLength = sPositional.length;
    int tPositionalLength = tPositional.length;
    if (sPositionalLength < tPositionalLength) {
      return false;
    }

    // Check all [t] positional arguments are subtypes of [s] positional
    // arguments.
    for (int i = 0; i < tPositionalLength; i++) {
      _Type sParameter = sPositional[i];
      _Type tParameter = tPositional[i];
      if (!isSubtype(tParameter, tEnv, sParameter, sEnv)) {
        return false;
      }
    }

    // Check that [t]'s named arguments are subtypes of [s]'s named arguments.
    // This logic assumes the named arguments are stored in sorted order.
    List<_NamedParameter> sNamed = s.namedParameters;
    List<_NamedParameter> tNamed = t.namedParameters;
    int sNamedLength = sNamed.length;
    int tNamedLength = tNamed.length;
    int sIndex = 0;
    for (int tIndex = 0; tIndex < tNamedLength; tIndex++) {
      _NamedParameter tNamedParameter = tNamed[tIndex];
      String tName = tNamedParameter.name;
      while (true) {
        if (sIndex >= sNamedLength) return false;
        _NamedParameter sNamedParameter = sNamed[sIndex];
        String sName = sNamedParameter.name;
        sIndex++;
        int sNameComparedToTName = sName.compareTo(tName);
        if (sNameComparedToTName > 0) return false;
        bool sIsRequired = sNamedParameter.isRequired;
        if (sNameComparedToTName < 0) {
          if (sIsRequired) return false;
          continue;
        }
        bool tIsRequired = tNamedParameter.isRequired;
        if (sIsRequired && !tIsRequired) return false;
        if (!isSubtype(
            tNamedParameter.type, tEnv, sNamedParameter.type, sEnv)) {
          return false;
        }
        break;
      }
    }
    while (sIndex < sNamedLength) {
      if (sNamed[sIndex].isRequired) return false;
      sIndex++;
    }
    return true;
  }

  // Subtype check based off of sdk/lib/_internal/js_runtime/lib/rti.dart.
  // Returns true if [s] is a subtype of [t], false otherwise.
  bool isSubtype(_Type s, _Environment? sEnv, _Type t, _Environment? tEnv) {
    // Reflexivity:
    if (identical(s, t)) return true;

    // Right Top:
    if (isTopType(t)) return true;

    // Left Top:
    if (isTopType(s)) return false;

    // Left Bottom:
    if (isBottomType(s)) return true;

    // Left Type Variable Bound 1:
    // TODO(joshualitt): Implement for generic function type parameters.
    if (s.isInterfaceTypeParameterType) {
      throw 'Unbound type parameter $s';
    }

    // Left Null:
    if (s.isNull) {
      return (t.isFutureOr &&
              isSubtype(s, sEnv, t.as<_FutureOrType>().typeArgument, tEnv)) ||
          t.isDeclaredNullable;
    }

    // Right Object:
    if (isObjectType(t)) {
      if (s.isFutureOr) {
        return isSubtype(s.as<_FutureOrType>().typeArgument, sEnv, t, tEnv);
      }
      return !s.isDeclaredNullable;
    }

    // Left FutureOr:
    if (s.isFutureOr) {
      _FutureOrType sFutureOr = s.as<_FutureOrType>();
      if (!isSubtype(sFutureOr.typeArgument, sEnv, t, tEnv)) {
        return false;
      }
      return isSubtype(sFutureOr.asFuture, sEnv, t, tEnv);
    }

    // Left Nullable:
    if (s.isDeclaredNullable) {
      return isSubtype(const _NullType(), sEnv, t, tEnv) &&
          isSubtype(s.asNonNullable, sEnv, t, tEnv);
    }

    // Type Variable Reflexivity 1 is subsumed by Reflexivity and therefore
    // elided.
    // Type Variable Reflexivity 2 does not apply at runtime.
    // Right Promoted Variable does not apply at runtime.

    // Right FutureOr:
    if (t.isFutureOr) {
      _FutureOrType tFutureOr = t.as<_FutureOrType>();
      if (isSubtype(s, sEnv, tFutureOr.typeArgument, tEnv)) {
        return true;
      }
      return isSubtype(s, sEnv, tFutureOr.asFuture, tEnv);
    }

    // Right Nullable:
    if (t.isDeclaredNullable) {
      return isSubtype(s, sEnv, t.asNonNullable, tEnv);
    }

    // Left Promoted Variable does not apply at runtime.

    if (s.isFunctionTypeParameterType) {
      // A function type parameter type is a subtype of another function type
      // parameter type if they refer to the same type parameter.
      if (s == t) return true;
      // Otherwise, compare the bound to the other type.
      final sTypeParam = s.as<_FunctionTypeParameterType>();
      return isSubtype(sEnv!.lookup(sTypeParam), sEnv, t, tEnv);
    }

    // Function Type / Function:
    if (s.isFunction && isFunctionType(t)) {
      return true;
    }

    if (s.isFunction && t.isFunction) {
      return isFunctionSubtype(
          s.as<_FunctionType>(), sEnv, t.as<_FunctionType>(), tEnv);
    }

    // Interface Compositionality + Super-Interface:
    if (s.isInterface &&
        t.isInterface &&
        isInterfaceSubtype(
            s.as<_InterfaceType>(), sEnv, t.as<_InterfaceType>(), tEnv)) {
      return true;
    }

    return false;
  }

  // Check whether two types are both subtypes of each other.
  bool areEquivalent(_Type s, _Environment? sEnv, _Type t, _Environment? tEnv) {
    return isSubtype(s, sEnv, t, tEnv) && isSubtype(t, tEnv, s, sEnv);
  }
}

_TypeUniverse _typeUniverse = _TypeUniverse.create();

@pragma("wasm:entry-point")
bool _isSubtype(Object? s, _Type t) {
  return _typeUniverse.isSubtype(s._runtimeType, null, t, null);
}
