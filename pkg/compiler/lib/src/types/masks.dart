// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library masks;

import '../common.dart';
import '../common_elements.dart' show CommonElements;
import '../constants/values.dart' show PrimitiveConstantValue;
import '../elements/entities.dart';
import '../inferrer/type_graph_inferrer.dart' show TypeGraphInferrer;
import '../universe/selector.dart' show Selector;
import '../universe/world_builder.dart'
    show
        ReceiverConstraint,
        UniverseSelectorConstraints,
        SelectorConstraintsStrategy;
import '../util/util.dart';
import '../world.dart' show ClassQuery, ClosedWorld;
import 'abstract_value_domain.dart';

part 'container_type_mask.dart';
part 'dictionary_type_mask.dart';
part 'flat_type_mask.dart';
part 'forwarding_type_mask.dart';
part 'map_type_mask.dart';
part 'type_mask.dart';
part 'union_type_mask.dart';
part 'value_type_mask.dart';

class CommonMasks implements AbstractValueDomain {
  // TODO(sigmund): once we split out the backend common elements, depend
  // directly on those instead.
  final ClosedWorld _closedWorld;

  CommonMasks(this._closedWorld);

  CommonElements get commonElements => _closedWorld.commonElements;

  TypeMask _dynamicType;
  TypeMask _nonNullType;
  TypeMask _nullType;
  TypeMask _intType;
  TypeMask _uint32Type;
  TypeMask _uint31Type;
  TypeMask _positiveIntType;
  TypeMask _doubleType;
  TypeMask _numType;
  TypeMask _boolType;
  TypeMask _functionType;
  TypeMask _listType;
  TypeMask _constListType;
  TypeMask _fixedListType;
  TypeMask _growableListType;
  TypeMask _mapType;
  TypeMask _constMapType;
  TypeMask _stringType;
  TypeMask _typeType;
  TypeMask _syncStarIterableType;
  TypeMask _asyncFutureType;
  TypeMask _asyncStarStreamType;
  TypeMask _indexablePrimitiveType;
  TypeMask _readableArrayType;
  TypeMask _mutableArrayType;
  TypeMask _fixedArrayType;
  TypeMask _unmodifiableArrayType;
  TypeMask _interceptorType;

  TypeMask get dynamicType => _dynamicType ??= new TypeMask.subclass(
      _closedWorld.commonElements.objectClass, _closedWorld);

  TypeMask get nonNullType => _nonNullType ??= new TypeMask.nonNullSubclass(
      _closedWorld.commonElements.objectClass, _closedWorld);

  TypeMask get intType => _intType ??=
      new TypeMask.nonNullSubclass(commonElements.jsIntClass, _closedWorld);

  TypeMask get uint32Type => _uint32Type ??=
      new TypeMask.nonNullSubclass(commonElements.jsUInt32Class, _closedWorld);

  TypeMask get uint31Type => _uint31Type ??=
      new TypeMask.nonNullExact(commonElements.jsUInt31Class, _closedWorld);

  TypeMask get positiveIntType =>
      _positiveIntType ??= new TypeMask.nonNullSubclass(
          commonElements.jsPositiveIntClass, _closedWorld);

  TypeMask get doubleType => _doubleType ??=
      new TypeMask.nonNullExact(commonElements.jsDoubleClass, _closedWorld);

  TypeMask get numType => _numType ??=
      new TypeMask.nonNullSubclass(commonElements.jsNumberClass, _closedWorld);

  TypeMask get boolType => _boolType ??=
      new TypeMask.nonNullExact(commonElements.jsBoolClass, _closedWorld);

  TypeMask get functionType => _functionType ??=
      new TypeMask.nonNullSubtype(commonElements.functionClass, _closedWorld);

  TypeMask get listType => _listType ??=
      new TypeMask.nonNullExact(commonElements.jsArrayClass, _closedWorld);

  TypeMask get constListType => _constListType ??= new TypeMask.nonNullExact(
      commonElements.jsUnmodifiableArrayClass, _closedWorld);

  TypeMask get fixedListType => _fixedListType ??=
      new TypeMask.nonNullExact(commonElements.jsFixedArrayClass, _closedWorld);

  TypeMask get growableListType =>
      _growableListType ??= new TypeMask.nonNullExact(
          commonElements.jsExtendableArrayClass, _closedWorld);

  TypeMask get mapType => _mapType ??=
      new TypeMask.nonNullSubtype(commonElements.mapLiteralClass, _closedWorld);

  TypeMask get constMapType => _constMapType ??= new TypeMask.nonNullSubtype(
      commonElements.constMapLiteralClass, _closedWorld);

  TypeMask get stringType => _stringType ??=
      new TypeMask.nonNullExact(commonElements.jsStringClass, _closedWorld);

  TypeMask get typeType => _typeType ??=
      new TypeMask.nonNullExact(commonElements.typeLiteralClass, _closedWorld);

  TypeMask get syncStarIterableType => _syncStarIterableType ??=
      new TypeMask.nonNullExact(commonElements.syncStarIterable, _closedWorld);

  TypeMask get asyncFutureType =>
      _asyncFutureType ??= new TypeMask.nonNullExact(
          commonElements.futureImplementation, _closedWorld);

  TypeMask get asyncStarStreamType => _asyncStarStreamType ??=
      new TypeMask.nonNullExact(commonElements.controllerStream, _closedWorld);

  // TODO(johnniwinther): Assert that the null type has been resolved.
  TypeMask get nullType => _nullType ??= const TypeMask.empty();

  TypeMask get emptyType => const TypeMask.nonNullEmpty();

  TypeMask get indexablePrimitiveType =>
      _indexablePrimitiveType ??= new TypeMask.nonNullSubtype(
          commonElements.jsIndexableClass, _closedWorld);

  TypeMask get readableArrayType => _readableArrayType ??=
      new TypeMask.nonNullSubclass(commonElements.jsArrayClass, _closedWorld);

  TypeMask get mutableArrayType =>
      _mutableArrayType ??= new TypeMask.nonNullSubclass(
          commonElements.jsMutableArrayClass, _closedWorld);

  TypeMask get fixedArrayType => _fixedArrayType ??=
      new TypeMask.nonNullExact(commonElements.jsFixedArrayClass, _closedWorld);

  TypeMask get unmodifiableArrayType =>
      _unmodifiableArrayType ??= new TypeMask.nonNullExact(
          commonElements.jsUnmodifiableArrayClass, _closedWorld);

  TypeMask get interceptorType =>
      _interceptorType ??= new TypeMask.nonNullSubclass(
          commonElements.jsInterceptorClass, _closedWorld);

  bool isTypedArray(TypeMask mask) {
    // Just checking for `TypedData` is not sufficient, as it is an abstract
    // class any user-defined class can implement. So we also check for the
    // interface `JavaScriptIndexingBehavior`.
    ClassEntity typedDataClass = _closedWorld.commonElements.typedDataClass;
    return typedDataClass != null &&
        _closedWorld.isInstantiated(typedDataClass) &&
        mask.satisfies(typedDataClass, _closedWorld) &&
        mask.satisfies(_closedWorld.commonElements.jsIndexingBehaviorInterface,
            _closedWorld);
  }

  bool couldBeTypedArray(TypeMask mask) {
    bool intersects(TypeMask type1, TypeMask type2) =>
        !type1.intersection(type2, _closedWorld).isEmpty;
    // TODO(herhut): Maybe cache the TypeMask for typedDataClass and
    //               jsIndexingBehaviourInterface.
    ClassEntity typedDataClass = _closedWorld.commonElements.typedDataClass;
    return typedDataClass != null &&
        _closedWorld.isInstantiated(typedDataClass) &&
        intersects(mask, new TypeMask.subtype(typedDataClass, _closedWorld)) &&
        intersects(
            mask,
            new TypeMask.subtype(
                _closedWorld.commonElements.jsIndexingBehaviorInterface,
                _closedWorld));
  }

  TypeMask createNonNullExact(ClassEntity cls) {
    return new TypeMask.nonNullExact(cls, _closedWorld);
  }

  TypeMask createNonNullSubtype(ClassEntity cls) {
    return new TypeMask.nonNullSubtype(cls, _closedWorld);
  }

  TypeMask excludeNull(TypeMask mask) => mask.nonNullable();

  @override
  TypeMask includeNull(TypeMask mask) => mask.nullable();

  bool containsType(TypeMask typeMask, ClassEntity cls) {
    return _closedWorld.isInstantiated(cls) &&
        typeMask.contains(cls, _closedWorld);
  }

  bool containsOnlyType(TypeMask typeMask, ClassEntity cls) {
    return _closedWorld.isInstantiated(cls) && typeMask.containsOnly(cls);
  }

  bool isInstanceOf(TypeMask typeMask, ClassEntity cls) {
    return _closedWorld.isImplemented(cls) &&
        typeMask.satisfies(cls, _closedWorld);
  }

  bool isEmpty(TypeMask value) => value.isEmpty;

  bool isExact(TypeMask value) => value.isExact || isNull(value);

  bool isValue(TypeMask value) => value.isValue;

  bool canBeNull(TypeMask value) => value.isNullable;

  bool isNull(TypeMask value) => value.isNull;

  bool canBePrimitive(TypeMask value) {
    return canBePrimitiveNumber(value) ||
        canBePrimitiveArray(value) ||
        canBePrimitiveBoolean(value) ||
        canBePrimitiveString(value) ||
        isNull(value);
  }

  bool canBePrimitiveNumber(TypeMask value) {
    // TODO(sra): It should be possible to test only jsDoubleClass and
    // jsUInt31Class, since all others are superclasses of these two.
    return containsType(value, commonElements.jsNumberClass) ||
        containsType(value, commonElements.jsIntClass) ||
        containsType(value, commonElements.jsPositiveIntClass) ||
        containsType(value, commonElements.jsUInt32Class) ||
        containsType(value, commonElements.jsUInt31Class) ||
        containsType(value, commonElements.jsDoubleClass);
  }

  bool canBePrimitiveBoolean(TypeMask value) {
    return containsType(value, commonElements.jsBoolClass);
  }

  bool canBePrimitiveArray(TypeMask value) {
    return containsType(value, commonElements.jsArrayClass) ||
        containsType(value, commonElements.jsFixedArrayClass) ||
        containsType(value, commonElements.jsExtendableArrayClass) ||
        containsType(value, commonElements.jsUnmodifiableArrayClass);
  }

  bool isIndexablePrimitive(TypeMask value) {
    return value.containsOnlyString(_closedWorld) ||
        isInstanceOf(value, commonElements.jsIndexableClass);
  }

  bool isFixedArray(TypeMask value) {
    // TODO(sra): Recognize the union of these types as well.
    return containsOnlyType(value, commonElements.jsFixedArrayClass) ||
        containsOnlyType(value, commonElements.jsUnmodifiableArrayClass);
  }

  bool isExtendableArray(TypeMask value) {
    return containsOnlyType(value, commonElements.jsExtendableArrayClass);
  }

  bool isMutableArray(TypeMask value) {
    return isInstanceOf(value, commonElements.jsMutableArrayClass);
  }

  bool isReadableArray(TypeMask value) {
    return isInstanceOf(value, commonElements.jsArrayClass);
  }

  bool isMutableIndexable(TypeMask value) {
    return isInstanceOf(value, commonElements.jsMutableIndexableClass);
  }

  bool isArray(TypeMask value) => isReadableArray(value);

  bool canBePrimitiveString(TypeMask value) {
    return containsType(value, commonElements.jsStringClass);
  }

  bool isInteger(TypeMask value) {
    return value.containsOnlyInt(_closedWorld) && !value.isNullable;
  }

  bool isUInt32(TypeMask value) {
    return !value.isNullable &&
        isInstanceOf(value, commonElements.jsUInt32Class);
  }

  bool isUInt31(TypeMask value) {
    return !value.isNullable &&
        isInstanceOf(value, commonElements.jsUInt31Class);
  }

  bool isPositiveInteger(TypeMask value) {
    return !value.isNullable &&
        isInstanceOf(value, commonElements.jsPositiveIntClass);
  }

  bool isPositiveIntegerOrNull(TypeMask value) {
    return isInstanceOf(value, commonElements.jsPositiveIntClass);
  }

  bool isIntegerOrNull(TypeMask value) {
    return value.containsOnlyInt(_closedWorld);
  }

  bool isNumber(TypeMask value) {
    return value.containsOnlyNum(_closedWorld) && !value.isNullable;
  }

  bool isNumberOrNull(TypeMask value) {
    return value.containsOnlyNum(_closedWorld);
  }

  bool isDouble(TypeMask value) {
    return value.containsOnlyDouble(_closedWorld) && !value.isNullable;
  }

  bool isDoubleOrNull(TypeMask value) {
    return value.containsOnlyDouble(_closedWorld);
  }

  bool isBoolean(TypeMask value) {
    return value.containsOnlyBool(_closedWorld) && !value.isNullable;
  }

  bool isBooleanOrNull(TypeMask value) {
    return value.containsOnlyBool(_closedWorld);
  }

  bool isString(TypeMask value) {
    return value.containsOnlyString(_closedWorld) && !value.isNullable;
  }

  bool isStringOrNull(TypeMask value) {
    return value.containsOnlyString(_closedWorld);
  }

  bool isPrimitive(TypeMask value) {
    return (isPrimitiveOrNull(value) && !value.isNullable) || isNull(value);
  }

  bool isPrimitiveOrNull(TypeMask value) {
    return isIndexablePrimitive(value) ||
        isNumberOrNull(value) ||
        isBooleanOrNull(value) ||
        isNull(value);
  }

  TypeMask union(TypeMask a, TypeMask b) => a.union(b, _closedWorld);

  TypeMask intersection(TypeMask a, TypeMask b) =>
      a.intersection(b, _closedWorld);

  bool areDisjoint(TypeMask a, TypeMask b) => a.isDisjoint(b, _closedWorld);

  bool containsAll(TypeMask a) => a.containsAll(_closedWorld);
}
