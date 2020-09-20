// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../constants/values.dart' show ConstantValue, PrimitiveConstantValue;
import '../../elements/entities.dart';
import '../../elements/names.dart';
import '../../elements/types.dart' show DartType;
import '../../ir/static_type.dart';
import '../../serialization/serialization.dart';
import '../../universe/selector.dart';
import '../../universe/world_builder.dart';
import '../../universe/use.dart';
import '../../world.dart';
import '../abstract_value_domain.dart';
import 'powerset_bits.dart';

class PowersetValue implements AbstractValue {
  final AbstractValue _abstractValue;
  final int _powersetBits;
  PowersetValue(this._abstractValue, this._powersetBits);

  AbstractValue get abstractValue => _abstractValue;
  int get powersetBits => _powersetBits;

  @override
  bool operator ==(var other) {
    if (identical(this, other)) return true;
    if (other is! PowersetValue) return false;
    PowersetValue otherPowerset = other;
    return other is PowersetValue &&
        _abstractValue == otherPowerset._abstractValue &&
        _powersetBits == otherPowerset._powersetBits;
  }

  @override
  int get hashCode {
    return _abstractValue.hashCode * _powersetBits.hashCode;
  }

  @override
  String toString() =>
      '${PowersetBitsDomain.toText(_powersetBits, omitIfTop: true)}'
      '${_abstractValue}';
}

AbstractValue unwrapOrNull(PowersetValue powerset) {
  return powerset == null ? null : powerset._abstractValue;
}

PowersetValue wrapOrNull(AbstractValue abstractValue, int powersetBits) {
  return abstractValue == null
      ? null
      : PowersetValue(abstractValue, powersetBits);
}

class PowersetDomain implements AbstractValueDomain {
  final AbstractValueDomain _abstractValueDomain;
  final PowersetBitsDomain _powersetBitsDomain;

  const PowersetDomain(this._abstractValueDomain, this._powersetBitsDomain);

  PowersetBitsDomain get powersetBitsDomain => _powersetBitsDomain;

  @override
  AbstractValue get dynamicType {
    AbstractValue abstractValue = _abstractValueDomain.dynamicType;
    return PowersetValue(abstractValue, _powersetBitsDomain.powersetTop);
  }

  //TODO(coam)
  @override
  void writeAbstractValueToDataSink(
      DataSink sink, covariant PowersetValue value) {
    _abstractValueDomain.writeAbstractValueToDataSink(
        sink, value._abstractValue);
  }

  //TODO(coam)
  @override
  AbstractValue readAbstractValueFromDataSource(DataSource source) {
    int powersetBits = _powersetBitsDomain.powersetTop;
    AbstractValue abstractValue =
        _abstractValueDomain.readAbstractValueFromDataSource(source);
    return PowersetValue(abstractValue, powersetBits);
  }

  //TODO(coam)
  @override
  String getCompactText(covariant PowersetValue value) =>
      _abstractValueDomain.getCompactText(value._abstractValue);

  @override
  AbstractBool isFixedLengthJsIndexable(covariant PowersetValue value) =>
      _powersetBitsDomain.isOther(value._powersetBits).isDefinitelyFalse
          ? AbstractBool.False
          : _abstractValueDomain.isFixedLengthJsIndexable(value._abstractValue);

  @override
  AbstractBool isJsIndexableAndIterable(covariant PowersetValue value) =>
      _powersetBitsDomain.isOther(value._powersetBits).isDefinitelyFalse
          ? AbstractBool.False
          : _abstractValueDomain.isJsIndexableAndIterable(value._abstractValue);

  @override
  AbstractBool isJsIndexable(covariant PowersetValue value) =>
      _powersetBitsDomain.isOther(value._powersetBits).isDefinitelyFalse
          ? AbstractBool.False
          : _abstractValueDomain.isJsIndexable(value._abstractValue);

  @override
  MemberEntity locateSingleMember(
          covariant PowersetValue receiver, Selector selector) =>
      _abstractValueDomain.locateSingleMember(
          receiver._abstractValue, selector);

  @override
  AbstractBool isIn(
          covariant PowersetValue subset, covariant PowersetValue superset) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isIn(
              subset._powersetBits, superset._powersetBits),
          _abstractValueDomain.isIn(
              subset._abstractValue, superset._abstractValue));

  @override
  AbstractBool needsNoSuchMethodHandling(
          covariant PowersetValue receiver, Selector selector) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.needsNoSuchMethodHandling(
              receiver._powersetBits, selector),
          _abstractValueDomain.needsNoSuchMethodHandling(
              receiver._abstractValue, selector));

  @override
  AbstractBool isTargetingMember(
          covariant PowersetValue receiver, MemberEntity member, Name name) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isTargetingMember(
              receiver._powersetBits, member, name),
          _abstractValueDomain.isTargetingMember(
              receiver._abstractValue, member, name));

  @override
  AbstractValue computeReceiver(Iterable<MemberEntity> members) {
    int powersetBits = _powersetBitsDomain.computeReceiver(members);
    AbstractValue abstractValue = _abstractValueDomain.computeReceiver(members);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  PrimitiveConstantValue getPrimitiveValue(covariant PowersetValue value) =>
      _powersetBitsDomain.getPrimitiveValue(value.powersetBits) ??
      _abstractValueDomain.getPrimitiveValue(value._abstractValue);

  @override
  AbstractValue createPrimitiveValue(
      covariant PowersetValue originalValue, PrimitiveConstantValue value) {
    int powersetBits = _powersetBitsDomain.createPrimitiveValue(value);
    AbstractValue abstractValue = _abstractValueDomain.createPrimitiveValue(
        originalValue._abstractValue, value);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  bool isPrimitiveValue(covariant PowersetValue value) =>
      _powersetBitsDomain.isPrimitiveValue(value.powersetBits) ||
      _abstractValueDomain.isPrimitiveValue(value._abstractValue);

  @override
  MemberEntity getAllocationElement(covariant PowersetValue value) =>
      _abstractValueDomain.getAllocationElement(value._abstractValue);

  @override
  Object getAllocationNode(covariant PowersetValue value) =>
      _abstractValueDomain.getAllocationNode(value._abstractValue);

  @override
  AbstractValue getGeneralization(covariant PowersetValue value) {
    int powersetBits = _powersetBitsDomain.powersetTop;
    AbstractValue abstractValue =
        _abstractValueDomain.getGeneralization(unwrapOrNull(value));
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  bool isSpecializationOf(covariant PowersetValue specialization,
          covariant PowersetValue generalization) =>
      _abstractValueDomain.isSpecializationOf(
          specialization._abstractValue, generalization._abstractValue);

  @override
  AbstractValue getDictionaryValueForKey(
      covariant PowersetValue value, String key) {
    if (_powersetBitsDomain.isOther(value._powersetBits).isDefinitelyFalse) {
      return dynamicType;
    }
    AbstractValue abstractValue = _abstractValueDomain.getDictionaryValueForKey(
        value._abstractValue, key);
    return PowersetValue(abstractValue, _powersetBitsDomain.powersetTop);
  }

  @override
  bool containsDictionaryKey(covariant PowersetValue value, String key) =>
      _powersetBitsDomain.isOther(value._powersetBits).isPotentiallyTrue &&
      _abstractValueDomain.containsDictionaryKey(value._abstractValue, key);

  @override
  AbstractValue createDictionaryValue(
      covariant PowersetValue originalValue,
      Object allocationNode,
      MemberEntity allocationElement,
      covariant PowersetValue key,
      covariant PowersetValue value,
      covariant Map<String, AbstractValue> mappings) {
    int powersetBits = originalValue._powersetBits;
    AbstractValue abstractValue = _abstractValueDomain.createDictionaryValue(
        originalValue._abstractValue,
        allocationNode,
        allocationElement,
        key._abstractValue,
        value._abstractValue, {
      for (var entry in mappings.entries)
        entry.key: (entry.value as PowersetValue)._abstractValue
    });
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  bool isDictionary(covariant PowersetValue value) =>
      _powersetBitsDomain.isOther(value._powersetBits).isPotentiallyTrue &&
      _abstractValueDomain.isDictionary(value._abstractValue);

  @override
  AbstractValue getMapValueType(covariant PowersetValue value) {
    if (_powersetBitsDomain.isOther(value._powersetBits).isDefinitelyFalse) {
      return dynamicType;
    }
    AbstractValue abstractValue =
        _abstractValueDomain.getMapValueType(value._abstractValue);
    return PowersetValue(abstractValue, _powersetBitsDomain.powersetTop);
  }

  @override
  AbstractValue getMapKeyType(covariant PowersetValue value) {
    if (_powersetBitsDomain.isOther(value._powersetBits).isDefinitelyFalse) {
      return dynamicType;
    }
    AbstractValue abstractValue =
        _abstractValueDomain.getMapValueType(value._abstractValue);
    return PowersetValue(abstractValue, _powersetBitsDomain.powersetTop);
  }

  @override
  AbstractValue createMapValue(
      covariant PowersetValue originalValue,
      Object allocationNode,
      MemberEntity allocationElement,
      covariant PowersetValue key,
      covariant PowersetValue value) {
    int powersetBits = originalValue._powersetBits;
    AbstractValue abstractValue = _abstractValueDomain.createMapValue(
        originalValue._abstractValue,
        allocationNode,
        allocationElement,
        key._abstractValue,
        value._abstractValue);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  bool isMap(covariant PowersetValue value) =>
      _powersetBitsDomain.isOther(value._powersetBits).isPotentiallyTrue &&
      _abstractValueDomain.isMap(value._abstractValue);

  @override
  AbstractValue getSetElementType(covariant PowersetValue value) {
    if (_powersetBitsDomain.isOther(value._powersetBits).isDefinitelyFalse) {
      return dynamicType;
    }
    AbstractValue abstractValue =
        _abstractValueDomain.getSetElementType(value._abstractValue);
    return PowersetValue(abstractValue, _powersetBitsDomain.powersetTop);
  }

  @override
  AbstractValue createSetValue(
      covariant PowersetValue originalValue,
      Object allocationNode,
      MemberEntity allocationElement,
      covariant PowersetValue elementType) {
    int powersetBits = originalValue._powersetBits;
    AbstractValue abstractValue = _abstractValueDomain.createSetValue(
        originalValue._abstractValue,
        allocationNode,
        allocationElement,
        elementType._abstractValue);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  bool isSet(covariant PowersetValue value) =>
      _powersetBitsDomain.isOther(value._powersetBits).isPotentiallyTrue &&
      _abstractValueDomain.isSet(value._abstractValue);

  @override
  int getContainerLength(covariant PowersetValue value) =>
      _powersetBitsDomain.isOther(value._powersetBits).isDefinitelyFalse
          ? null
          : _abstractValueDomain.getContainerLength(value._abstractValue);

  @override
  AbstractValue getContainerElementType(covariant PowersetValue value) {
    if (_powersetBitsDomain.isOther(value._powersetBits).isDefinitelyFalse) {
      return dynamicType;
    }
    AbstractValue abstractValue =
        _abstractValueDomain.getContainerElementType(value._abstractValue);
    return PowersetValue(abstractValue, _powersetBitsDomain.powersetTop);
  }

  @override
  AbstractValue createContainerValue(
      covariant PowersetValue originalValue,
      Object allocationNode,
      MemberEntity allocationElement,
      covariant PowersetValue elementType,
      int length) {
    int powersetBits = originalValue._powersetBits;
    AbstractValue abstractValue = _abstractValueDomain.createContainerValue(
        originalValue._abstractValue,
        allocationNode,
        allocationElement,
        elementType._abstractValue,
        length);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  bool isContainer(covariant PowersetValue value) =>
      _powersetBitsDomain.isOther(value._powersetBits).isPotentiallyTrue &&
      _abstractValueDomain.isContainer(value._abstractValue);

  // TODO(coam): this can be more precise if we build a ConstantValue visitor
  // that can tell us information about the bits given a ConstantValue
  @override
  AbstractValue computeAbstractValueForConstant(covariant ConstantValue value) {
    int powersetBits =
        _powersetBitsDomain.computeAbstractValueForConstant(value);
    AbstractValue abstractValue =
        _abstractValueDomain.computeAbstractValueForConstant(value);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractValue getAbstractValueForNativeMethodParameterType(DartType type) {
    int powersetBits = _powersetBitsDomain.powersetTop;
    AbstractValue abstractValue =
        _abstractValueDomain.getAbstractValueForNativeMethodParameterType(type);
    return wrapOrNull(abstractValue, powersetBits);
  }

  @override
  AbstractBool containsAll(covariant PowersetValue a) =>
      AbstractBool.strengthen(_powersetBitsDomain.containsAll(a._powersetBits),
          _abstractValueDomain.containsAll(a._abstractValue));

  @override
  AbstractBool areDisjoint(
          covariant PowersetValue a, covariant PowersetValue b) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.areDisjoint(a._powersetBits, b._powersetBits),
          _abstractValueDomain.areDisjoint(a._abstractValue, b._abstractValue));

  @override
  AbstractValue intersection(
      covariant PowersetValue a, covariant PowersetValue b) {
    int powersetBits =
        _powersetBitsDomain.intersection(a._powersetBits, b._powersetBits);
    AbstractValue abstractValue =
        _abstractValueDomain.intersection(a._abstractValue, b._abstractValue);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractValue unionOfMany(covariant Iterable<AbstractValue> values) {
    PowersetValue result = PowersetValue(
        _abstractValueDomain.emptyType, _powersetBitsDomain.powersetBottom);
    for (PowersetValue value in values) {
      result = union(result, value);
    }
    return result;
  }

  @override
  AbstractValue union(covariant PowersetValue a, covariant PowersetValue b) {
    int powersetBits =
        _powersetBitsDomain.union(a._powersetBits, b._powersetBits);
    AbstractValue abstractValue =
        _abstractValueDomain.union(a._abstractValue, b._abstractValue);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractBool isPrimitiveOrNull(covariant PowersetValue value) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isPrimitiveOrNull(value._powersetBits),
          _abstractValueDomain.isPrimitiveOrNull(value._abstractValue));

  @override
  AbstractBool isStringOrNull(covariant PowersetValue value) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isStringOrNull(value._powersetBits),
          _abstractValueDomain.isStringOrNull(value._abstractValue));

  @override
  AbstractBool isString(covariant PowersetValue value) =>
      AbstractBool.strengthen(_powersetBitsDomain.isString(value._powersetBits),
          _abstractValueDomain.isString(value._abstractValue));

  @override
  AbstractBool isBooleanOrNull(covariant PowersetValue value) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isBooleanOrNull(value._powersetBits),
          _abstractValueDomain.isBooleanOrNull(value._abstractValue));

  @override
  AbstractBool isBoolean(covariant PowersetValue value) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isBoolean(value._powersetBits),
          _abstractValueDomain.isBoolean(value._abstractValue));

  @override
  AbstractBool isTruthy(covariant PowersetValue value) =>
      AbstractBool.strengthen(_powersetBitsDomain.isTruthy(value._powersetBits),
          _abstractValueDomain.isTruthy(value._abstractValue));

  @override
  AbstractBool isDoubleOrNull(covariant PowersetValue value) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isDoubleOrNull(value._powersetBits),
          _abstractValueDomain.isDoubleOrNull(value._abstractValue));

  @override
  AbstractBool isDouble(covariant PowersetValue value) =>
      AbstractBool.strengthen(_powersetBitsDomain.isDouble(value._powersetBits),
          _abstractValueDomain.isDouble(value._abstractValue));

  @override
  AbstractBool isNumberOrNull(covariant PowersetValue value) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isNumberOrNull(value._powersetBits),
          _abstractValueDomain.isNumberOrNull(value._abstractValue));

  @override
  AbstractBool isNumber(covariant PowersetValue value) =>
      AbstractBool.strengthen(_powersetBitsDomain.isNumber(value._powersetBits),
          _abstractValueDomain.isNumber(value._abstractValue));

  @override
  AbstractBool isIntegerOrNull(covariant PowersetValue value) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isIntegerOrNull(value._powersetBits),
          _abstractValueDomain.isIntegerOrNull(value._abstractValue));

  @override
  AbstractBool isPositiveIntegerOrNull(covariant PowersetValue value) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isPositiveIntegerOrNull(value._powersetBits),
          _abstractValueDomain.isPositiveIntegerOrNull(value._abstractValue));

  @override
  AbstractBool isPositiveInteger(covariant PowersetValue value) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isPositiveInteger(value._powersetBits),
          _abstractValueDomain.isPositiveInteger(value._abstractValue));

  @override
  AbstractBool isUInt31(covariant PowersetValue value) =>
      AbstractBool.strengthen(_powersetBitsDomain.isUInt31(value._powersetBits),
          _abstractValueDomain.isUInt31(value._abstractValue));

  @override
  AbstractBool isUInt32(covariant PowersetValue value) =>
      AbstractBool.strengthen(_powersetBitsDomain.isUInt32(value._powersetBits),
          _abstractValueDomain.isUInt32(value._abstractValue));

  @override
  AbstractBool isInteger(covariant PowersetValue value) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isInteger(value._powersetBits),
          _abstractValueDomain.isInteger(value._abstractValue));

  @override
  AbstractBool isInterceptor(covariant PowersetValue value) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isInterceptor(value._powersetBits),
          _abstractValueDomain.isInterceptor(value._abstractValue));

  @override
  AbstractBool isPrimitiveString(covariant PowersetValue value) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isPrimitiveString(value._powersetBits),
          _abstractValueDomain.isPrimitiveString(value._abstractValue));

  @override
  AbstractBool isArray(covariant PowersetValue value) =>
      AbstractBool.strengthen(_powersetBitsDomain.isArray(value._powersetBits),
          _abstractValueDomain.isArray(value._abstractValue));

  @override
  AbstractBool isMutableIndexable(covariant PowersetValue value) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isMutableIndexable(value._powersetBits),
          _abstractValueDomain.isMutableIndexable(value._abstractValue));

  @override
  AbstractBool isMutableArray(covariant PowersetValue value) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isMutableArray(value._powersetBits),
          _abstractValueDomain.isMutableArray(value._abstractValue));

  @override
  AbstractBool isExtendableArray(covariant PowersetValue value) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isExtendableArray(value._powersetBits),
          _abstractValueDomain.isExtendableArray(value._abstractValue));

  @override
  AbstractBool isFixedArray(covariant PowersetValue value) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isFixedArray(value._powersetBits),
          _abstractValueDomain.isFixedArray(value._abstractValue));

  @override
  AbstractBool isIndexablePrimitive(covariant PowersetValue value) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isIndexablePrimitive(value._powersetBits),
          _abstractValueDomain.isIndexablePrimitive(value._abstractValue));

  @override
  AbstractBool isPrimitiveArray(covariant PowersetValue value) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isPrimitiveArray(value._powersetBits),
          _abstractValueDomain.isPrimitiveArray(value._abstractValue));

  @override
  AbstractBool isPrimitiveBoolean(covariant PowersetValue value) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isPrimitiveBoolean(value._powersetBits),
          _abstractValueDomain.isPrimitiveBoolean(value._abstractValue));

  @override
  AbstractBool isPrimitiveNumber(covariant PowersetValue value) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isPrimitiveNumber(value._powersetBits),
          _abstractValueDomain.isPrimitiveNumber(value._abstractValue));

  @override
  AbstractBool isPrimitive(covariant PowersetValue value) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isPrimitive(value._powersetBits),
          _abstractValueDomain.isPrimitive(value._abstractValue));

  @override
  AbstractBool isNull(covariant PowersetValue value) => AbstractBool.strengthen(
      _powersetBitsDomain.isNull(value._powersetBits),
      _abstractValueDomain.isNull(value._abstractValue));

  @override
  ClassEntity getExactClass(covariant PowersetValue value) =>
      _abstractValueDomain.getExactClass(value._abstractValue);

  @override
  AbstractBool isExactOrNull(covariant PowersetValue value) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isExactOrNull(value._powersetBits),
          _abstractValueDomain.isExactOrNull(value._abstractValue));

  @override
  AbstractBool isExact(covariant PowersetValue value) =>
      AbstractBool.strengthen(_powersetBitsDomain.isExact(value._powersetBits),
          _abstractValueDomain.isExact(value._abstractValue));

  @override
  AbstractBool isEmpty(covariant PowersetValue value) =>
      AbstractBool.strengthen(_powersetBitsDomain.isEmpty(value._powersetBits),
          _abstractValueDomain.isEmpty(value._abstractValue));

  @override
  AbstractBool isInstanceOf(covariant PowersetValue value, ClassEntity cls) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isInstanceOf(value._powersetBits, cls),
          _abstractValueDomain.isInstanceOf(value._abstractValue, cls));

  @override
  AbstractBool isInstanceOfOrNull(
          covariant PowersetValue value, ClassEntity cls) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isInstanceOfOrNull(value._powersetBits, cls),
          _abstractValueDomain.isInstanceOfOrNull(value._abstractValue, cls));

  @override
  AbstractBool containsOnlyType(
          covariant PowersetValue value, ClassEntity cls) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.containsOnlyType(value._powersetBits, cls),
          _abstractValueDomain.containsOnlyType(value._abstractValue, cls));

  @override
  AbstractBool containsType(covariant PowersetValue value, ClassEntity cls) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.containsType(value._powersetBits, cls),
          _abstractValueDomain.containsType(value._abstractValue, cls));

  @override
  AbstractValue includeNull(covariant PowersetValue value) {
    int powersetBits = _powersetBitsDomain.includeNull(value._powersetBits);
    AbstractValue abstractValue =
        _abstractValueDomain.includeNull(value._abstractValue);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractValue excludeNull(covariant PowersetValue value) {
    int powersetBits = _powersetBitsDomain.excludeNull(value._powersetBits);
    AbstractValue abstractValue =
        _abstractValueDomain.excludeNull(value._abstractValue);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractBool couldBeTypedArray(covariant PowersetValue value) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.couldBeTypedArray(value._powersetBits),
          _abstractValueDomain.couldBeTypedArray(value._abstractValue));

  @override
  AbstractBool isTypedArray(covariant PowersetValue value) =>
      AbstractBool.strengthen(
          _powersetBitsDomain.isTypedArray(value._powersetBits),
          _abstractValueDomain.isTypedArray(value._abstractValue));

  @override
  AbstractValue createNullableSubtype(ClassEntity cls) {
    int powersetBits = _powersetBitsDomain.createNullableSubtype(cls);
    AbstractValue abstractValue =
        _abstractValueDomain.createNullableSubtype(cls);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractValue createNonNullSubtype(ClassEntity cls) {
    int powersetBits = _powersetBitsDomain.createNonNullSubtype(cls);
    AbstractValue abstractValue =
        _abstractValueDomain.createNonNullSubtype(cls);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractValue createNonNullSubclass(ClassEntity cls) {
    int powersetBits = _powersetBitsDomain.createNonNullSubclass(cls);
    AbstractValue abstractValue =
        _abstractValueDomain.createNonNullSubclass(cls);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractValue createNullableExact(ClassEntity cls) {
    int powersetBits = _powersetBitsDomain.createNullableExact(cls);
    AbstractValue abstractValue = _abstractValueDomain.createNullableExact(cls);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractValue createNonNullExact(ClassEntity cls) {
    int powersetBits = _powersetBitsDomain.createNonNullExact(cls);
    AbstractValue abstractValue = _abstractValueDomain.createNonNullExact(cls);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractValueWithPrecision createFromStaticType(DartType type,
      {ClassRelation classRelation = ClassRelation.subtype, bool nullable}) {
    int powersetBits = _powersetBitsDomain.createFromStaticType(type,
        classRelation: classRelation, nullable: nullable);
    var unwrapped = _abstractValueDomain.createFromStaticType(type,
        classRelation: classRelation, nullable: nullable);
    return AbstractValueWithPrecision(
        PowersetValue(unwrapped.abstractValue, powersetBits),
        unwrapped.isPrecise);
  }

  @override
  AbstractValue get asyncStarStreamType => PowersetValue(
      _abstractValueDomain.asyncStarStreamType,
      _powersetBitsDomain.asyncStarStreamType);

  @override
  AbstractValue get asyncFutureType => PowersetValue(
      _abstractValueDomain.asyncFutureType,
      _powersetBitsDomain.asyncFutureType);

  @override
  AbstractValue get syncStarIterableType => PowersetValue(
      _abstractValueDomain.syncStarIterableType,
      _powersetBitsDomain.syncStarIterableType);

  @override
  AbstractValue get emptyType => PowersetValue(
      _abstractValueDomain.emptyType, _powersetBitsDomain.emptyType);

  @override
  AbstractValue get constMapType => PowersetValue(
      _abstractValueDomain.constMapType, _powersetBitsDomain.constMapType);

  @override
  AbstractValue get constSetType => PowersetValue(
      _abstractValueDomain.constSetType, _powersetBitsDomain.constSetType);

  @override
  AbstractValue get constListType => PowersetValue(
      _abstractValueDomain.constListType, _powersetBitsDomain.constListType);

  @override
  AbstractValue get positiveIntType => PowersetValue(
      _abstractValueDomain.positiveIntType,
      _powersetBitsDomain.positiveIntType);

  @override
  AbstractValue get uint32Type => PowersetValue(
      _abstractValueDomain.uint32Type, _powersetBitsDomain.uint32Type);

  @override
  AbstractValue get uint31Type => PowersetValue(
      _abstractValueDomain.uint31Type, _powersetBitsDomain.uint31Type);

  @override
  AbstractValue get fixedListType => PowersetValue(
      _abstractValueDomain.fixedListType, _powersetBitsDomain.fixedListType);

  @override
  AbstractValue get growableListType => PowersetValue(
      _abstractValueDomain.growableListType,
      _powersetBitsDomain.growableListType);

  @override
  AbstractValue get mutableArrayType => PowersetValue(
      _abstractValueDomain.mutableArrayType,
      _powersetBitsDomain.mutableArrayType);

  @override
  AbstractValue get nullType => PowersetValue(
      _abstractValueDomain.nullType, _powersetBitsDomain.nullType);

  @override
  AbstractValue get nonNullType => PowersetValue(
      _abstractValueDomain.nonNullType, _powersetBitsDomain.nonNullType);

  @override
  AbstractValue get mapType =>
      PowersetValue(_abstractValueDomain.mapType, _powersetBitsDomain.mapType);

  @override
  AbstractValue get setType =>
      PowersetValue(_abstractValueDomain.setType, _powersetBitsDomain.setType);

  @override
  AbstractValue get listType => PowersetValue(
      _abstractValueDomain.listType, _powersetBitsDomain.listType);

  @override
  AbstractValue get stringType => PowersetValue(
      _abstractValueDomain.stringType, _powersetBitsDomain.stringType);

  @override
  AbstractValue get numType =>
      PowersetValue(_abstractValueDomain.numType, _powersetBitsDomain.numType);

  @override
  AbstractValue get doubleType => PowersetValue(
      _abstractValueDomain.doubleType, _powersetBitsDomain.doubleType);

  @override
  AbstractValue get intType =>
      PowersetValue(_abstractValueDomain.intType, _powersetBitsDomain.intType);

  @override
  AbstractValue get boolType => PowersetValue(
      _abstractValueDomain.boolType, _powersetBitsDomain.boolType);

  @override
  AbstractValue get functionType => PowersetValue(
      _abstractValueDomain.functionType, _powersetBitsDomain.functionType);

  @override
  AbstractValue get typeType => PowersetValue(
      _abstractValueDomain.typeType, _powersetBitsDomain.typeType);
}

class PowersetStrategy implements AbstractValueStrategy {
  final AbstractValueStrategy _abstractValueStrategy;
  const PowersetStrategy(this._abstractValueStrategy);

  @override
  AbstractValueDomain createDomain(JClosedWorld closedWorld) {
    return PowersetDomain(_abstractValueStrategy.createDomain(closedWorld),
        PowersetBitsDomain(closedWorld));
  }

  @override
  SelectorConstraintsStrategy createSelectorStrategy() {
    return PowersetsSelectorStrategy(
        _abstractValueStrategy.createSelectorStrategy());
  }
}

class PowersetsSelectorStrategy implements SelectorConstraintsStrategy {
  final SelectorConstraintsStrategy _selectorConstraintsStrategy;
  const PowersetsSelectorStrategy(this._selectorConstraintsStrategy);

  @override
  UniverseSelectorConstraints createSelectorConstraints(
      Selector selector, Object initialConstraint) {
    return PowersetsUniverseSelectorConstraints(
        _selectorConstraintsStrategy.createSelectorConstraints(
            selector,
            initialConstraint == null
                ? null
                : (initialConstraint as PowersetValue)._abstractValue));
  }

  @override
  bool appliedUnnamed(DynamicUse dynamicUse, MemberEntity member,
      covariant JClosedWorld world) {
    return _selectorConstraintsStrategy.appliedUnnamed(
        dynamicUse.withReceiverConstraint(
            unwrapOrNull(dynamicUse.receiverConstraint)),
        member,
        world);
  }
}

class PowersetsUniverseSelectorConstraints
    implements UniverseSelectorConstraints {
  final UniverseSelectorConstraints _universeSelectorConstraints;
  const PowersetsUniverseSelectorConstraints(this._universeSelectorConstraints);

  @override
  bool addReceiverConstraint(Object constraint) =>
      _universeSelectorConstraints.addReceiverConstraint(constraint == null
          ? null
          : (constraint as PowersetValue)._abstractValue);

  @override
  bool needsNoSuchMethodHandling(Selector selector, World world) =>
      _universeSelectorConstraints.needsNoSuchMethodHandling(selector, world);

  @override
  bool canHit(MemberEntity element, Name name, World world) =>
      _universeSelectorConstraints.canHit(element, name, world);

  @override
  String toString() => 'PowersetsUniverseSelectorConstraints:$hashCode';
}
