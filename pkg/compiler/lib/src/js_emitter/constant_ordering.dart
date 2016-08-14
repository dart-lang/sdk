// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.constant_ordering;

import '../constants/values.dart';
import '../dart_types.dart';
import '../elements/elements.dart' show Element, Elements, FieldElement;
import '../js_backend/js_backend.dart' show SyntheticConstantKind;
import '../tree/dartstring.dart' show DartString;

/// A canonical but arbrary ordering of constants. The ordering is 'stable'
/// under perturbation of the source.
int deepCompareConstants(ConstantValue a, ConstantValue b) {
  return _CompareVisitor.compareValues(a, b);
}

class _CompareVisitor implements ConstantValueVisitor<int, ConstantValue> {
  const _CompareVisitor();

  static int compareValues(ConstantValue a, ConstantValue b) {
    if (identical(a, b)) return 0;
    int r = _KindVisitor.kind(a).compareTo(_KindVisitor.kind(b));
    if (r != 0) return r;
    r = a.accept(const _CompareVisitor(), b);
    return r;
  }

  static int compareNullable(int compare(a, b), a, b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    return compare(a, b);
  }

  static int compareLists(int compare(a, b), List a, List b) {
    int r = a.length.compareTo(b.length);
    if (r != 0) return r;
    for (int i = 0; i < a.length; i++) {
      r = compare(a[i], b[i]);
      if (r != 0) return r;
    }
    return 0;
  }

  static int compareElements(Element a, Element b) {
    int r = a.name.compareTo(b.name);
    if (r != 0) return r;
    return Elements.compareByPosition(a, b);
  }

  static int compareDartTypes(DartType a, DartType b) {
    if (a == b) return 0;
    int r = a.kind.index.compareTo(b.kind.index);
    if (r != 0) return r;
    r = compareNullable(compareElements, a.element, b.element);
    if (r != 0) return r;

    if (a is GenericType) {
      GenericType aGeneric = a;
      GenericType bGeneric = b;
      r = compareLists(
          compareDartTypes, aGeneric.typeArguments, bGeneric.typeArguments);
      if (r != 0) return r;
    }
    throw 'unexpected compareDartTypes  $a  $b';
  }

  int visitFunction(FunctionConstantValue a, FunctionConstantValue b) {
    return compareElements(a.element, b.element);
  }

  int visitNull(NullConstantValue a, NullConstantValue b) {
    return 0;
  }

  int visitNonConstant(NonConstantValue a, NonConstantValue b) {
    return 0;
  }

  int visitInt(IntConstantValue a, IntConstantValue b) {
    return a.primitiveValue.compareTo(b.primitiveValue);
  }

  int visitDouble(DoubleConstantValue a, DoubleConstantValue b) {
    return a.primitiveValue.compareTo(b.primitiveValue);
  }

  int visitBool(BoolConstantValue a, BoolConstantValue b) {
    int aInt = a.primitiveValue ? 1 : 0;
    int bInt = b.primitiveValue ? 1 : 0;
    return aInt.compareTo(bInt);
  }

  int visitString(StringConstantValue a, StringConstantValue b) {
    DartString aString = a.primitiveValue;
    DartString bString = b.primitiveValue;
    int r = aString.length.compareTo(bString.length);
    if (r != 0) return r;
    return aString.slowToString().compareTo(bString.slowToString());
  }

  int visitList(ListConstantValue a, ListConstantValue b) {
    int r = compareLists(compareValues, a.entries, b.entries);
    if (r != 0) return r;
    return compareDartTypes(a.type, b.type);
  }

  int visitMap(MapConstantValue a, MapConstantValue b) {
    int r = compareLists(compareValues, a.keys, b.keys);
    if (r != 0) return r;
    r = compareLists(compareValues, a.values, b.values);
    if (r != 0) return r;
    return compareDartTypes(a.type, b.type);
  }

  int visitConstructed(ConstructedConstantValue a, ConstructedConstantValue b) {
    int r = compareDartTypes(a.type, b.type);
    if (r != 0) return r;

    List<FieldElement> aFields = a.fields.keys.toList()..sort(compareElements);
    List<FieldElement> bFields = b.fields.keys.toList()..sort(compareElements);

    r = compareLists(compareElements, aFields, bFields);
    if (r != 0) return r;

    return compareLists(
        compareValues,
        aFields.map((field) => a.fields[field]).toList(),
        aFields.map((field) => b.fields[field]).toList());
  }

  int visitType(TypeConstantValue a, TypeConstantValue b) {
    int r = compareDartTypes(a.representedType, b.representedType);
    if (r != 0) return r;
    return compareDartTypes(a.type, b.type);
  }

  int visitInterceptor(InterceptorConstantValue a, InterceptorConstantValue b) {
    return compareDartTypes(a.dispatchedType, b.dispatchedType);
  }

  int visitSynthetic(SyntheticConstantValue a, SyntheticConstantValue b) {
    // [SyntheticConstantValue]s have abstract fields that are set only by
    // convention.  Lucky for us, they do not occur as top level constant, only
    // as elements of a few constants.  If this becomes a source of instability,
    // we will need to add a total ordering on JavaScript ASTs including
    // deferred elements.
    SyntheticConstantKind aKind = a.valueKind;
    SyntheticConstantKind bKind = b.valueKind;
    int r = aKind.index - bKind.index;
    if (r != 0) return r;
    switch (aKind) {
      case SyntheticConstantKind.DUMMY_INTERCEPTOR:
      case SyntheticConstantKind.EMPTY_VALUE:
        // Never emitted.
        return 0;

      case SyntheticConstantKind.TYPEVARIABLE_REFERENCE:
        // An opaque deferred JS AST reference to a type in reflection data.
        return 0;
      case SyntheticConstantKind.NAME:
        // An opaque deferred JS AST reference to a name.
        return 0;
      default:
        // Should not happen.
        throw 'unexpected SyntheticConstantKind $aKind';
    }
  }

  int visitDeferred(DeferredConstantValue a, DeferredConstantValue b) {
    int r = compareValues(a.referenced, b.referenced);
    if (r != 0) return r;
    return compareElements(a.prefix, b.prefix);
  }
}

class _KindVisitor implements ConstantValueVisitor<int, Null> {
  const _KindVisitor();

  static const int FUNCTION = 1;
  static const int NULL = 2;
  static const int INT = 3;
  static const int DOUBLE = 4;
  static const int BOOL = 5;
  static const int STRING = 6;
  static const int LIST = 7;
  static const int MAP = 8;
  static const int CONSTRUCTED = 9;
  static const int TYPE = 10;
  static const int INTERCEPTOR = 11;
  static const int SYNTHETIC = 12;
  static const int DEFERRED = 13;
  static const int NONCONSTANT = 13;

  static int kind(ConstantValue constant) =>
      constant.accept(const _KindVisitor(), null);

  int visitFunction(FunctionConstantValue a, _) => FUNCTION;
  int visitNull(NullConstantValue a, _) => NULL;
  int visitNonConstant(NonConstantValue a, _) => NONCONSTANT;
  int visitInt(IntConstantValue a, _) => INT;
  int visitDouble(DoubleConstantValue a, _) => DOUBLE;
  int visitBool(BoolConstantValue a, _) => BOOL;
  int visitString(StringConstantValue a, _) => STRING;
  int visitList(ListConstantValue a, _) => LIST;
  int visitMap(MapConstantValue a, _) => MAP;
  int visitConstructed(ConstructedConstantValue a, _) => CONSTRUCTED;
  int visitType(TypeConstantValue a, _) => TYPE;
  int visitInterceptor(InterceptorConstantValue a, _) => INTERCEPTOR;
  int visitSynthetic(SyntheticConstantValue a, _) => SYNTHETIC;
  int visitDeferred(DeferredConstantValue a, _) => DEFERRED;
}
