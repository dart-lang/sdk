// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

//import 'dart:_internal' show ClassID;

// Representation of runtime types. Code in this file should avoid using `is` or
// `as` entirely to avoid a dependency on any inline type checks.

// TODO(joshualitt): Once we have RTI fully working, we'd like to explore
// implementing [isSubtype] using inheritance.
abstract class _Type implements Type {
  const _Type();

  bool _testID(int value) => ClassID.getID(this) == value;
  bool get isNever => _testID(ClassID.cidNeverType);
  bool get isDynamic => _testID(ClassID.cidDynamicType);
  bool get isVoid => _testID(ClassID.cidVoidType);
  bool get isFutureOr => _testID(ClassID.cidFutureOrType);
  bool get isInterface => _testID(ClassID.cidInterfaceType);
  bool get isFunction => _testID(ClassID.cidFunctionType);
  bool get isGenericFunctionType => _testID(ClassID.cidGenericFunctionType);
  bool get isNullable => false;

  T as<T>() => unsafeCast<T>(this);

  @override
  bool operator ==(Object other) => ClassID.getID(this) == ClassID.getID(other);

  @override
  int get hashCode => mix64(ClassID.getID(this));
}

@pragma("wasm:entry-point")
class _NeverType extends _Type {
  @override
  String toString() => 'Never';
}

@pragma("wasm:entry-point")
class _DynamicType extends _Type {
  @override
  String toString() => 'dynamic';
}

@pragma("wasm:entry-point")
class _VoidType extends _Type {
  @override
  String toString() => 'void';
}

@pragma("wasm:entry-point")
class _NullType extends _Type {
  @override
  String toString() => 'Null';
}

@pragma("wasm:entry-point")
class _FutureOrType extends _Type {
  // TODO(joshualitt): Implement.
  @override
  String toString() => 'FutureOr';
}

class _InterfaceType extends _Type {
  final int classId;
  final bool declaredNullable;
  final List<_Type> typeArguments;

  @pragma("wasm:entry-point")
  const _InterfaceType(this.classId, this.declaredNullable,
      [this.typeArguments = const []]);

  bool get isNullable => declaredNullable;

  @override
  bool operator ==(Object o) {
    if (!(super == (o))) return false;
    _InterfaceType other = unsafeCast<_InterfaceType>(o);
    if (classId != other.classId) return false;
    if (isNullable != other.isNullable) return false;
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
    hash = mix64(hash ^ (isNullable ? 1 : 0));
    for (int i = 0; i < typeArguments.length; i++) {
      hash = mix64(hash ^ typeArguments[i].hashCode);
    }
    return hash;
  }

  @override
  String toString() {
    StringBuffer s = StringBuffer();
    s.write("Interface");
    s.write(classId);
    if (typeArguments.isNotEmpty) {
      s.write("<");
      for (int i = 0; i < typeArguments.length; i++) {
        if (i > 0) s.write(",");
        s.write(typeArguments[i]);
      }
      s.write(">");
    }
    if (isNullable) s.write("?");
    return s.toString();
  }
}

@pragma("wasm:entry-point")
class _FunctionType extends _Type {
  // TODO(joshualitt): Implement.
  @override
  String toString() => 'FunctionType';
}

@pragma("wasm:entry-point")
class _GenericFunctionType extends _FunctionType {
  // TODO(joshualitt): Implement.
  @override
  String toString() => 'GenericFunctionType';
}

external Map<int, List<int>> _getSubtypeMap();

class _TypeUniverse {
  /// 'Map' of classId to range of subclasses.
  final Map<int, List<int>> _subtypeMap;

  const _TypeUniverse._(this._subtypeMap);

  factory _TypeUniverse.create() {
    return _TypeUniverse._(_getSubtypeMap());
  }

  bool isObjectQuestionType(_Type t) {
    if (!t.isInterface) return false;
    _InterfaceType type = t.as<_InterfaceType>();
    return type.classId == ClassID.cidObject && type.isNullable;
  }

  bool isTopType(_Type type) {
    return isObjectQuestionType(type) || type.isDynamic || type.isVoid;
  }

  bool isBottomType(_Type type) {
    return type.isNever;
  }

  bool isInterfaceSubtype(_InterfaceType s, _InterfaceType t) {
    int sId = s.classId;
    int tId = t.classId;
    if (sId == tId) {
      assert(s.typeArguments.length == t.typeArguments.length);
      for (int i = 0; i < s.typeArguments.length; i++) {
        if (!isSubtype(s.typeArguments[i], t.typeArguments[i])) {
          return false;
        }
      }
      return true;
    }
    List<int>? subtypes = _subtypeMap[tId];
    if (subtypes == null) return false;
    if (!subtypes.contains(sId)) return false;
    // TODO(joshualitt): Compare type arguments.
    return true;
  }

  // Subtype check based off of sdk/lib/_internal/js_runtime/lib/rti.dart.
  // Returns true if [s] is a subtype of [t], false otherwise.
  bool isSubtype(_Type s, _Type t) {
    // Reflexivity:
    if (identical(s, t)) return true;

    // Right Top:
    if (isTopType(t)) return true;

    // Left Top:
    if (isTopType(s)) return false;

    // Left Bottom:
    if (isBottomType(s)) return true;

    // TODO(joshualitt): Implement missing cases.
    // Left type variable bound 1:
    // Left Null:
    // Right Object:
    // Left FuturOr:
    // Left Nullable:
    // Do we need to handle at runtime
    //   Type Variable Reflexivity 1 && 2
    //   Right Promoted Variable
    // Right FutureOr:
    // Right Nullable:
    // Do we need to handle at runtime:
    //   Left Promoted Variable
    // Left Type Variable Bound 2:
    // Function Type / Function:
    // Positional Function Types + Named Function Types:

    // Interface Compositionality + Super-Interface:
    if (s.isInterface &&
        t.isInterface &&
        isInterfaceSubtype(s.as<_InterfaceType>(), t.as<_InterfaceType>())) {
      return true;
    }
    return false;
  }
}

_TypeUniverse _typeUniverse = _TypeUniverse.create();

@pragma("wasm:entry-point")
bool _isSubtype(Object? s, _Type t) {
  return _typeUniverse.isSubtype(unsafeCast<_Type>(s.runtimeType), t);
}
