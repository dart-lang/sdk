// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.constant_ordering;

import '../constants/values.dart';
import '../elements/entities.dart' show ClassEntity, FieldEntity, MemberEntity;
import '../elements/types.dart';
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

  @override
  int compare(ConstantValue a, ConstantValue b) => compareValues(a, b);

  int compareValues(ConstantValue a, ConstantValue b) {
    if (identical(a, b)) return 0;
    int r = a.kind.index.compareTo(b.kind.index);
    if (r != 0) return r;
    return a.accept(this, b);
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

  int compareDartTypes(DartType a, DartType b) {
    return _dartTypeOrdering.compare(a, b);
  }

  @override
  int visitFunction(FunctionConstantValue a, FunctionConstantValue b) {
    return compareMembers(a.element, b.element);
  }

  @override
  int visitNull(NullConstantValue a, NullConstantValue b) {
    return 0;
  }

  @override
  int visitNonConstant(NonConstantValue a, NonConstantValue b) {
    return 0;
  }

  @override
  int visitInt(IntConstantValue a, IntConstantValue b) {
    return a.intValue.compareTo(b.intValue);
  }

  @override
  int visitDouble(DoubleConstantValue a, DoubleConstantValue b) {
    return a.doubleValue.compareTo(b.doubleValue);
  }

  @override
  int visitBool(BoolConstantValue a, BoolConstantValue b) {
    int aInt = a.boolValue ? 1 : 0;
    int bInt = b.boolValue ? 1 : 0;
    return aInt.compareTo(bInt);
  }

  @override
  int visitString(StringConstantValue a, StringConstantValue b) {
    String aString = a.stringValue;
    String bString = b.stringValue;
    return aString.compareTo(bString);
  }

  @override
  int visitList(ListConstantValue a, ListConstantValue b) {
    int r = compareLists(compareValues, a.entries, b.entries);
    if (r != 0) return r;
    return compareDartTypes(a.type, b.type);
  }

  @override
  int visitSet(SetConstantValue a, SetConstantValue b) {
    int r = compareLists(compareValues, a.values, b.values);
    if (r != 0) return r;
    return compareDartTypes(a.type, b.type);
  }

  @override
  int visitMap(MapConstantValue a, MapConstantValue b) {
    int r = compareLists(compareValues, a.keys, b.keys);
    if (r != 0) return r;
    r = compareLists(compareValues, a.values, b.values);
    if (r != 0) return r;
    return compareDartTypes(a.type, b.type);
  }

  @override
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

  @override
  int visitType(TypeConstantValue a, TypeConstantValue b) {
    int r = compareDartTypes(a.representedType, b.representedType);
    if (r != 0) return r;
    return compareDartTypes(a.type, b.type);
  }

  @override
  int visitInterceptor(InterceptorConstantValue a, InterceptorConstantValue b) {
    return compareClasses(a.cls, b.cls);
  }

  @override
  int visitDummyInterceptor(
      DummyInterceptorConstantValue a, DummyInterceptorConstantValue b) {
    // Never emitted.
    return 0;
  }

  @override
  int visitUnreachable(UnreachableConstantValue a, UnreachableConstantValue b) {
    // Never emitted.
    return 0;
  }

  @override
  int visitJsName(JsNameConstantValue a, JsNameConstantValue b) {
    // An opaque deferred JS AST reference to a name.
    return 0;
  }

  @override
  int visitDeferredGlobal(
      DeferredGlobalConstantValue a, DeferredGlobalConstantValue b) {
    int r = compareValues(a.referenced, b.referenced);
    if (r != 0) return r;
    return a.unit.compareTo(b.unit);
  }

  @override
  int visitInstantiation(
      InstantiationConstantValue a, InstantiationConstantValue b) {
    int r = compareValues(a.function, b.function);
    if (r != 0) return r;
    return compareLists(compareDartTypes, a.typeArguments, b.typeArguments);
  }
}

/// Visitor for distinguishing types by kind.
class _DartTypeKindVisitor implements DartTypeVisitor<int, Null> {
  const _DartTypeKindVisitor();

  static int kind(DartType type) {
    return const _DartTypeKindVisitor().visit(type);
  }

  @override
  int visit(DartType type, [_]) => type.accept(this, null);
  @override
  int visitFunctionType(FunctionType type, _) => 0;
  @override
  int visitInterfaceType(InterfaceType type, _) => 1;
  @override
  int visitFunctionTypeVariable(FunctionTypeVariable type, _) => 2;
  @override
  int visitTypeVariableType(TypeVariableType type, _) => 3;
  @override
  int visitNeverType(NeverType type, _) => 4;
  @override
  int visitDynamicType(DynamicType type, _) => 5;
  @override
  int visitVoidType(VoidType type, _) => 6;
  @override
  int visitAnyType(AnyType type, _) => 7;
  @override
  int visitErasedType(ErasedType type, _) => 8;
  @override
  int visitFutureOrType(FutureOrType type, _) => 9;
  @override
  int visitLegacyType(LegacyType type, _) => 10;
  @override
  int visitNullableType(NullableType type, _) => 11;
}

class _DartTypeOrdering extends DartTypeVisitor<int, DartType> {
  final _ConstantOrdering _constantOrdering;
  DartType _root;
  List<FunctionTypeVariable> _leftFunctionTypeVariables = [];
  List<FunctionTypeVariable> _rightFunctionTypeVariables = [];
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

  @override
  int visitLegacyType(covariant LegacyType type, covariant LegacyType other) =>
      compare(type.baseType, other.baseType);

  @override
  int visitNullableType(
          covariant NullableType type, covariant NullableType other) =>
      compare(type.baseType, other.baseType);

  @override
  int visitFutureOrType(
          covariant FutureOrType type, covariant FutureOrType other) =>
      compare(type.typeArgument, other.typeArgument);

  @override
  int visitNeverType(covariant NeverType type, covariant NeverType other) {
    throw UnsupportedError('Unreachable');
  }

  @override
  int visitVoidType(covariant VoidType type, covariant VoidType other) {
    throw new UnsupportedError('Unreachable');
  }

  @override
  int visitTypeVariableType(
      covariant TypeVariableType type, covariant TypeVariableType other) {
    throw new UnsupportedError(
        "Type variables are not expected in constants: '$type' in '$_root'");
  }

  @override
  int visitFunctionTypeVariable(covariant FunctionTypeVariable type,
      covariant FunctionTypeVariable other) {
    int leftIndex = _leftFunctionTypeVariables.indexOf(type);
    int rightIndex = _rightFunctionTypeVariables.indexOf(other);
    assert(leftIndex != -1);
    assert(rightIndex != -1);
    int r = leftIndex.compareTo(rightIndex);
    if (r != 0) return r;
    return compare(type.bound, other.bound);
  }

  @override
  int visitFunctionType(
      covariant FunctionType type, covariant FunctionType other) {
    int oldLeftLength = _leftFunctionTypeVariables.length;
    int oldRightLength = _rightFunctionTypeVariables.length;
    _leftFunctionTypeVariables.addAll(type.typeVariables);
    _rightFunctionTypeVariables.addAll(other.typeVariables);
    try {
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
    } finally {
      _leftFunctionTypeVariables.removeRange(
          oldLeftLength, _leftFunctionTypeVariables.length);
      _rightFunctionTypeVariables.removeRange(
          oldRightLength, _rightFunctionTypeVariables.length);
    }
  }

  @override
  int visitInterfaceType(
      covariant InterfaceType type, covariant InterfaceType other) {
    int r = _constantOrdering.compareClasses(type.element, other.element);
    if (r != 0) return r;
    return _compareTypeArguments(type.typeArguments, other.typeArguments);
  }

  @override
  int visitDynamicType(
      covariant DynamicType type, covariant DynamicType other) {
    throw new UnsupportedError('Unreachable');
  }

  @override
  int visitErasedType(covariant ErasedType type, covariant ErasedType other) {
    throw UnsupportedError('Unreachable');
  }

  @override
  int visitAnyType(covariant AnyType type, covariant AnyType other) {
    throw UnsupportedError('Unreachable');
  }

  int _compareTypeArguments(
      List<DartType> aArguments, List<DartType> bArguments) {
    return _ConstantOrdering.compareLists(compare, aArguments, bArguments);
  }
}
