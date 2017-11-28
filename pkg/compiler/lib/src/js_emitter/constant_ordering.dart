// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.constant_ordering;

import '../constants/values.dart';
import '../elements/elements.dart' show Elements;
import '../elements/entities.dart'
    show Entity, ClassEntity, FieldEntity, MemberEntity, TypedefEntity;
import '../elements/resolution_types.dart'
    show
        GenericType,
        ResolutionDartType,
        ResolutionFunctionType,
        ResolutionTypeKind;
import '../elements/types.dart';
import '../js_backend/js_backend.dart' show SyntheticConstantKind;
import 'sorter.dart' show Sorter;

/// A canonical but arbitrary ordering of constants. The ordering is 'stable'
/// under perturbation of the source.
abstract class ConstantOrdering {
  factory ConstantOrdering(Sorter sorter) = _ConstantOrdering;

  int compare(ConstantValue a, ConstantValue b);
}

class _ConstantOrdering
    implements ConstantOrdering, ConstantValueVisitor<int, ConstantValue> {
  final Sorter _sorter;
  _DartTypeOrdering _dartTypeOrdering;
  _ConstantOrdering(this._sorter) {
    _dartTypeOrdering = new _DartTypeOrdering(this);
  }

  int compare(ConstantValue a, ConstantValue b) => compareValues(a, b);

  int compareValues(ConstantValue a, ConstantValue b) {
    if (identical(a, b)) return 0;
    int r = _KindVisitor.kind(a).compareTo(_KindVisitor.kind(b));
    if (r != 0) return r;
    return a.accept(this, b);
  }

  static int compareNullable<T>(int compare(T a, T b), T a, T b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    return compare(a, b);
  }

  static int compareLists<S, T>(int compare(S a, T b), List<S> a, List<T> b) {
    int r = a.length.compareTo(b.length);
    if (r != 0) return r;
    for (int i = 0; i < a.length; i++) {
      r = compare(a[i], b[i]);
      if (r != 0) return r;
    }
    return 0;
  }

  static int compareElements(Entity a, Entity b) {
    int r = a.name.compareTo(b.name);
    if (r != 0) return r;
    return Elements.compareByPosition(a, b);
  }

  int compareClasses(ClassEntity a, ClassEntity b) {
    int r = a.name.compareTo(b.name);
    if (r != 0) return r;
    return _sorter.compareClassesByLocation(a, b);
  }

  int compareMembers(MemberEntity a, MemberEntity b) {
    int r = a.name.compareTo(b.name);
    if (r != 0) return r;
    return _sorter.compareMembersByLocation(a, b);
  }

  int compareTypedefs(TypedefEntity a, TypedefEntity b) {
    int r = a.name.compareTo(b.name);
    if (r != 0) return r;
    return _sorter.compareTypedefsByLocation(a, b);
  }

  static int _compareResolutionDartTypes(
      ResolutionDartType a, ResolutionDartType b) {
    if (a == b) return 0;
    int r = a.kind.index.compareTo(b.kind.index);
    if (r != 0) return r;
    r = compareNullable(compareElements, a.element, b.element);
    if (r != 0) return r;

    if (a is GenericType) {
      GenericType aGeneric = a;
      GenericType bGeneric = b;
      r = compareLists(_compareResolutionDartTypes, aGeneric.typeArguments,
          bGeneric.typeArguments);
      if (r != 0) return r;
    }
    if (a is ResolutionFunctionType && b is ResolutionFunctionType) {
      int r = compareLists(
          _compareResolutionDartTypes, a.parameterTypes, b.parameterTypes);
      if (r != 0) return r;
      r = compareLists(_compareResolutionDartTypes, a.optionalParameterTypes,
          b.optionalParameterTypes);
      if (r != 0) return r;
      r = _ConstantOrdering.compareLists((String a, String b) => a.compareTo(b),
          a.namedParameters, b.namedParameters);
      if (r != 0) return r;
      r = compareLists(_compareResolutionDartTypes, a.namedParameterTypes,
          b.namedParameterTypes);
      if (r != 0) return r;
      return _compareResolutionDartTypes(a.returnType, b.returnType);
    }

    throw 'unexpected compareDartTypes  $a  $b';
  }

  int compareDartTypes(DartType a, DartType b) {
    if (a is ResolutionDartType && b is ResolutionDartType) {
      // TODO(redemption): Remove this path.
      return _compareResolutionDartTypes(a, b);
    }
    return _dartTypeOrdering.compare(a, b);
  }

  int visitFunction(FunctionConstantValue a, FunctionConstantValue b) {
    return compareMembers(a.element, b.element);
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
    String aString = a.primitiveValue;
    String bString = b.primitiveValue;
    return aString.compareTo(bString);
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

    // TODO(sra): Avoid all these tear-offs.
    List<FieldEntity> aFields = a.fields.keys.toList()..sort(compareMembers);
    List<FieldEntity> bFields = b.fields.keys.toList()..sort(compareMembers);

    r = compareLists(compareMembers, aFields, bFields);
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
    return compareClasses(a.cls, b.cls);
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
    // TODO(sra): What kind of Entity is `prefix`?
    return compareElements(a.import, b.import);
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

/// Visitor for distinguishing types by kind.
class _DartTypeKindVisitor extends DartTypeVisitor<int, Null> {
  const _DartTypeKindVisitor();

  static int kind(DartType type) {
    assert(_usesLegacyOrder);
    return type.accept(const _DartTypeKindVisitor(), null);
  }

  int visitVoidType(covariant VoidType type, _) => 6;
  int visitTypeVariableType(covariant TypeVariableType type, _) => 3;
  int visitFunctionType(covariant FunctionType type, _) => 0;
  int visitInterfaceType(covariant InterfaceType type, _) => 1;
  int visitTypedefType(covariant TypedefType type, _) => 2;
  int visitDynamicType(covariant DynamicType type, _) => 5;

  // Check that the ordering of different kinds of type is consistent with
  // ResolutionDartTypes.
  // TODO(redemption): Remove this check.
  static bool _usesLegacyOrder = () {
    var v = const _DartTypeKindVisitor();
    assert(
        v.visitFunctionType(null, null) == ResolutionTypeKind.FUNCTION.index);
    assert(
        v.visitInterfaceType(null, null) == ResolutionTypeKind.INTERFACE.index);
    assert(v.visitTypedefType(null, null) == ResolutionTypeKind.TYPEDEF.index);
    assert(v.visitTypeVariableType(null, null) ==
        ResolutionTypeKind.TYPE_VARIABLE.index);
    // There is no analogue of ResolutionTypeKind.MALFORMED_TYPE.
    assert(v.visitDynamicType(null, null) == ResolutionTypeKind.DYNAMIC.index);
    assert(v.visitVoidType(null, null) == ResolutionTypeKind.VOID.index);
    return true;
  }();
}

class _DartTypeOrdering extends DartTypeVisitor<int, DartType> {
  final _ConstantOrdering _constantOrdering;
  DartType _root;
  _DartTypeOrdering(this._constantOrdering);

  int compare(DartType a, DartType b) {
    if (a == b) return 0;
    int r =
        _DartTypeKindVisitor.kind(a).compareTo(_DartTypeKindVisitor.kind(b));
    if (r != 0) return r;
    _root = a;
    r = a.accept(this, b);
    _root = null;
    return r;
  }

  int visitVoidType(covariant VoidType type, covariant VoidType other) {
    throw new UnsupportedError('Unreachable');
  }

  int visitTypeVariableType(
      covariant TypeVariableType type, covariant TypeVariableType other) {
    throw new UnsupportedError(
        "Type variables are not expected in constants: '$type' in '$_root'");
  }

  int visitFunctionType(
      covariant FunctionType type, covariant FunctionType other) {
    int r = _compareTypeArguments(type.parameterTypes, other.parameterTypes);
    if (r != 0) return r;
    r = _compareTypeArguments(
        type.optionalParameterTypes, other.optionalParameterTypes);
    if (r != 0) return r;
    r = _ConstantOrdering.compareLists((String a, String b) => a.compareTo(b),
        type.namedParameters, other.namedParameters);
    if (r != 0) return r;
    r = _compareTypeArguments(
        type.namedParameterTypes, other.namedParameterTypes);
    if (r != 0) return r;
    return compare(type.returnType, other.returnType);
  }

  int visitInterfaceType(
      covariant InterfaceType type, covariant InterfaceType other) {
    int r = _constantOrdering.compareClasses(type.element, other.element);
    if (r != 0) return r;
    return _compareTypeArguments(type.typeArguments, other.typeArguments);
  }

  int visitTypedefType(
      covariant TypedefType type, covariant TypedefType other) {
    int r = _constantOrdering.compareTypedefs(type.element, other.element);
    if (r != 0) return r;
    return _compareTypeArguments(type.typeArguments, other.typeArguments);
  }

  int visitDynamicType(
      covariant DynamicType type, covariant DynamicType other) {
    throw new UnsupportedError('Unreachable');
  }

  int _compareTypeArguments(
      List<DartType> aArguments, List<DartType> bArguments) {
    return _ConstantOrdering.compareLists(compare, aArguments, bArguments);
  }
}
