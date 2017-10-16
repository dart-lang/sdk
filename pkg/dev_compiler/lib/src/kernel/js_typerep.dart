// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/kernel.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_environment.dart';

/// An abstraction of the JS types
abstract class JSType {
  const JSType();

  /// True if this type is built-in to JS, and we use the values unwrapped.
  /// For these types we generate a calling convention via static
  /// "extension methods". This allows types to be extended without adding
  /// extensions directly on the prototype.
  bool get isPrimitive;

  /// Is this type known to be definitively primitive
  /// (using the JS notion of primitive)
  bool get isPrimitiveInJS;

  /// Can a non-null element of this type potentially be interpreted
  /// as false in JS.
  bool get isFalsey;

  static const jsBoolean = const JSBoolean();
  static const jsNumber = const JSNumber();
  static const jsNull = const JSNull();
  static const jsObject = const JSObject();
  static const jsString = const JSString();
  static const jsUnknown = const JSUnknown();
}

/// Inhabited by booleans (including JSBool), null, and undefined
class JSBoolean extends JSType {
  const JSBoolean();
  bool get isPrimitive => true;
  bool get isPrimitiveInJS => true;
  bool get isFalsey => true;
}

/// Inhabited by numbers, null, and undefined
/// In practice, this is 4 types: num, int, double, and _interceptors.JSNumber.
///
/// _interceptors.JSNumber is the type that actually "implements" all numbers,
/// hence it's a subtype of int and double (and num).
/// It's defined in our "dart:_interceptors".
class JSNumber extends JSType {
  const JSNumber();
  bool get isPrimitive => true;
  bool get isPrimitiveInJS => true;
  bool get isFalsey => true;
}

/// Inhabited by null and undefined
class JSNull extends JSType {
  const JSNull();
  bool get isPrimitive => false;
  bool get isPrimitiveInJS => false;
  bool get isFalsey => true;
}

/// Inhabited by objects, null, and undefined
class JSObject extends JSType {
  const JSObject();
  bool get isPrimitive => false;
  bool get isPrimitiveInJS => false;
  bool get isFalsey => false;
}

/// Inhabited by strings (including JSString), null, and undefined
class JSString extends JSType {
  const JSString();
  bool get isPrimitive => true;
  bool get isPrimitiveInJS => false;
  bool get isFalsey => true;
}

/// Inhabitance not statically known
class JSUnknown extends JSType {
  const JSUnknown();
  bool get isPrimitive => false;
  bool get isPrimitiveInJS => false;
  bool get isFalsey => true;
}

class JSTypeRep {
  final TypeEnvironment rules;
  final CoreTypes types;

  JSTypeRep(this.rules, this.types);

  JSType typeFor(DartType type) {
    while (type is TypeParameterType) {
      type = (type as TypeParameterType).parameter.bound;
    }
    if (type == null) return JSType.jsUnknown;
    // Note that this should be changed if Dart gets non-nullable types
    if (type == const BottomType()) return JSType.jsNull;

    if (type is InterfaceType) {
      var c = type.classNode;
      if (c == types.nullClass) return JSType.jsNull;
      if (c == types.numClass ||
          c == types.intClass ||
          c == types.doubleClass) {
        return JSType.jsNumber;
      }
      if (c == types.boolClass.rawType) return JSType.jsBoolean;
      if (c == types.stringClass.rawType) return JSType.jsString;
      if (c == types.objectClass) return JSType.jsUnknown;
      if (c == types.futureOrClass) {
        var argumentRep = typeFor(type.typeArguments[0]);
        if (argumentRep is JSObject || argumentRep is JSNull) {
          return JSType.jsObject;
        }
        return JSType.jsUnknown;
      }
    }
    if (type == const DynamicType() || type == const VoidType()) {
      return JSType.jsUnknown;
    }
    return JSType.jsObject;
  }

  /// If the type [t] is [int] or [double], or a type parameter
  /// bounded by [int], [double] or [num] returns [num].
  /// Otherwise returns [t].
  DartType canonicalizeNumTypes(DartType t) =>
      isNumber(t) ? types.nullClass.rawType : t;

  bool isNumber(DartType type) => typeFor(type) is JSNumber;

  /// Is this type known to be represented as Object or Null in JS.
  bool isObjectOrNull(DartType t) {
    var rep = typeFor(t);
    return rep is JSObject || rep is JSNull;
  }

  bool isUnknown(DartType t) => typeFor(t) is JSUnknown;

  bool isPrimitive(DartType t) => typeFor(t).isPrimitive;

  bool isPrimitiveInJS(DartType t) => typeFor(t).isPrimitiveInJS;

  bool binaryOperationIsPrimitive(DartType leftT, DartType rightT) =>
      isPrimitiveInJS(leftT) && isPrimitiveInJS(rightT);

  bool unaryOperationIsPrimitive(DartType t) => isPrimitiveInJS(t);

  /// True if the JS double equals (`==`) comparison on the representation
  /// of these two types could potentially cause a conversion.
  bool equalityMayConvert(DartType t0, DartType t1) => !equalOrNull(t0, t1);

  // Are t0 and t1 known to either be represented by the same type
  // or else one or both of them is represented by Null
  bool equalOrNull(DartType t0, DartType t1) {
    var rep0 = typeFor(t0);
    var rep1 = typeFor(t1);
    if (rep0 is JSNull || rep1 is JSNull) return true;
    return rep0 == rep1 && rep0 is! JSUnknown;
  }
}
