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
  bool get isFunction => _testID(ClassID.cidFunctionType);
  bool get isGenericFunction => _testID(ClassID.cidGenericFunctionType);

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

/// Because Interface type parameters are fundamentally different from Generic
/// function type parameters, we are keeping these classes separate for the time
/// being.
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

@pragma("wasm:entry-point")
class _GenericFunctionTypeParameterType extends _Type {
  final int environmentIndex;

  const _GenericFunctionTypeParameterType(
      super.isDeclaredNullable, this.environmentIndex);

  @override
  _Type get _asNonNullable =>
      throw 'Type parameter should have been substituted already..';

  @override
  _Type get _asNullable =>
      throw 'Type parameter should have been substituted already.';

  @override
  String toString() => 'G$environmentIndex';
}

@pragma("wasm:entry-point")
class _FutureOrType extends _Type {
  final _Type typeArgument;

  @pragma("wasm:entry-point")
  const _FutureOrType(super.isDeclaredNullable, this.typeArgument);

  _InterfaceType get asFuture =>
      _InterfaceType(ClassID.cid_Future, isDeclaredNullable, [typeArgument]);

  @override
  _Type get _asNonNullable => _FutureOrType(false, typeArgument);

  @override
  _Type get _asNullable => _FutureOrType(true, typeArgument);

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
  final _Type returnType;
  final List<_Type> positionalParameters;
  final int requiredParameterCount;
  final List<_NamedParameter> namedParameters;

  @pragma("wasm:entry-point")
  const _FunctionType(
      this.returnType,
      this.positionalParameters,
      this.requiredParameterCount,
      this.namedParameters,
      super.isDeclaredNullable);

  @override
  _Type get _asNonNullable => _FunctionType(returnType, positionalParameters,
      requiredParameterCount, namedParameters, false);

  @override
  _Type get _asNullable => _FunctionType(returnType, positionalParameters,
      requiredParameterCount, namedParameters, true);

  bool operator ==(Object o) {
    if (!(super == o)) return false;
    _FunctionType other = unsafeCast<_FunctionType>(o);
    if (isDeclaredNullable != other.isDeclaredNullable) return false;
    if (returnType != other.returnType) ;
    if (positionalParameters.length != other.positionalParameters.length) {
      return false;
    }
    if (requiredParameterCount != other.requiredParameterCount) return false;
    if (namedParameters.length != other.namedParameters.length) return false;
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
    s.write(" Function(");
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

// TODO(joshualitt): Implement. This should probably extend _FunctionType.
class _GenericFunctionType extends _Type {
  @pragma("wasm:entry-point")
  const _GenericFunctionType(super.isDeclaredNullable);

  @override
  _Type get _asNonNullable => throw 'unimplemented';

  @override
  _Type get _asNullable => throw 'unimplemented';

  @override
  String toString() => 'GenericFunctionType';
}

external List<List<int>> _getTypeRulesSupers();
external List<List<List<_Type>>> _getTypeRulesSubstitutions();
external List<String> _getTypeNames();

class _Environment {
  List<List<_Type>> scopes = [];

  _Environment();

  factory _Environment.from(List<_Type> initialScope) {
    final env = _Environment();
    env.push(initialScope);
    return env;
  }

  void push(List<_Type> scope) => scopes.add(scope);

  void pop() => scopes.removeLast();

  _Type _substituteTypeParameter(bool declaredNullable, _Type type) {
    // If the type parameter is non-nullable, or the substitution type is
    // nullable, then just return the substitution type. Otherwise, we return
    // [type] as nullable.
    // Note: This will throw if the required nullability is impossible to
    // generate.
    if (!declaredNullable || type.isDeclaredNullable) {
      return type;
    }
    return type.asNullable;
  }

  _Type lookup(_InterfaceTypeParameterType typeParameter) {
    // Lookup `InterfaceType` parameters in the top environment.
    // TODO(joshualitt): When we implement generic functions be sure to keep the
    // environments distinct.
    return _substituteTypeParameter(typeParameter.isDeclaredNullable,
        scopes.last[typeParameter.environmentIndex]);
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

  bool isSpecificInterfaceType(_Type t, int classId) {
    if (!t.isInterface) return false;
    _InterfaceType type = t.as<_InterfaceType>();
    return type.classId == classId;
  }

  bool isObjectQuestionType(_Type t) => isObjectType(t) && t.isDeclaredNullable;

  bool isObjectType(_Type t) => isSpecificInterfaceType(t, ClassID.cidObject);

  bool isTopType(_Type type) {
    return isObjectQuestionType(type) || type.isDynamic || type.isVoid;
  }

  bool isBottomType(_Type type) {
    return type.isNever;
  }

  bool isFunctionType(_Type t) =>
      isSpecificInterfaceType(t, ClassID.cidFunction) ||
      isSpecificInterfaceType(t, ClassID.cid_Function);

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

    List<_Type> substitutions = typeRulesSubstitutions[sId][sSuperIndexOfT];

    // If we have empty type arguments then create a list of dynamic type
    // arguments.
    List<_Type> sTypeArguments = s.typeArguments;
    if (substitutions.isNotEmpty && sTypeArguments.isEmpty) {
      sTypeArguments = List<_Type>.generate(
          substitutions.length, (int index) => const _DynamicType(),
          growable: false);
    }

    // If [sEnv] is null, then create a new environment. Otherwise, we are doing
    // a recursive type check, so extend the existing environment with [s]'s
    // type arguments.
    if (sEnv == null) {
      sEnv = _Environment.from(sTypeArguments);
    } else {
      sEnv.push(sTypeArguments);
    }
    bool result =
        areTypeArgumentsSubtypes(substitutions, sEnv, t.typeArguments, tEnv);
    sEnv.pop();
    return result;
  }

  bool isFunctionSubtype(_FunctionType s, _Environment? sEnv, _FunctionType t,
      _Environment? tEnv) {
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
      return isSubtype(
          sEnv!.lookup(s.as<_InterfaceTypeParameterType>()), sEnv, t, tEnv);
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
      // `s` is neither null nor declared nullable so return false if `t` is
      // truly `null`.
      if (t.isNull) return false;
      return isSubtype(s, sEnv, t.asNonNullable, tEnv);
    }

    // Left Promoted Variable does not apply at runtime.

    // Left Type Variable Bound 2:
    // TODO(joshualitt): Implement case.

    // Function Type / Function:
    if ((s.isFunction || s.isGenericFunction) && isFunctionType(t)) {
      return true;
    }

    // Positional Function Types + Named Function Types:
    if (s.isGenericFunction && t.isGenericFunction) {
      // TODO(joshualitt): Implement case.
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
}

_TypeUniverse _typeUniverse = _TypeUniverse.create();

@pragma("wasm:entry-point")
bool _isSubtype(Object? s, _Type t) {
  return _typeUniverse.isSubtype(s._runtimeType, null, t, null);
}
