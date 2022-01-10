/// An abstraction of the JS types

// @dart = 2.9

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

  /// The JS `typeof` value, if unambiguous.
  String get primitiveTypeOf => null;

  static const jsBoolean = JSBoolean();
  static const jsNumber = JSNumber();
  static const jsNull = JSNull();
  static const jsObject = JSObject();
  static const jsString = JSString();
  static const jsUnknown = JSUnknown();
  // TODO(jmesserly): add JSFunction that maps to Dart's `Function` type.
}

/// Inhabited by booleans (including JSBool), null, and undefined
class JSBoolean extends JSType {
  const JSBoolean();
  @override
  bool get isPrimitive => true;
  @override
  bool get isPrimitiveInJS => true;
  @override
  bool get isFalsey => true;
  @override
  String get primitiveTypeOf => 'boolean';
}

/// Inhabited by numbers, null, and undefined
/// In practice, this is 4 types: num, int, double, and _interceptors.JSNumber.
///
/// _interceptors.JSNumber is the type that actually "implements" all numbers,
/// hence it's a subtype of int and double (and num).
/// It's defined in our "dart:_interceptors".
class JSNumber extends JSType {
  const JSNumber();
  @override
  bool get isPrimitive => true;
  @override
  bool get isPrimitiveInJS => true;
  @override
  bool get isFalsey => true;
  @override
  String get primitiveTypeOf => 'number';
}

/// Inhabited by null and undefined
class JSNull extends JSType {
  const JSNull();
  @override
  bool get isPrimitive => false;
  @override
  bool get isPrimitiveInJS => false;
  @override
  bool get isFalsey => true;
}

/// Inhabited by objects, null, and undefined
class JSObject extends JSType {
  const JSObject();
  @override
  bool get isPrimitive => false;
  @override
  bool get isPrimitiveInJS => false;
  @override
  bool get isFalsey => false;
}

/// Inhabited by strings (including JSString), null, and undefined
class JSString extends JSType {
  const JSString();
  @override
  bool get isPrimitive => true;
  @override
  bool get isPrimitiveInJS => false;
  @override
  bool get isFalsey => true;
  @override
  String get primitiveTypeOf => 'string';
}

/// Inhabitance not statically known
class JSUnknown extends JSType {
  const JSUnknown();
  @override
  bool get isPrimitive => false;
  @override
  bool get isPrimitiveInJS => false;
  @override
  bool get isFalsey => true;
}

abstract class SharedJSTypeRep<DartType> {
  JSType typeFor(DartType type);

  bool isNumber(DartType type) => typeFor(type) is JSNumber;

  bool isBoolean(DartType type) => typeFor(type) is JSBoolean;

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
