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

class PowersetValue implements AbstractValue {
  final AbstractValue _abstractValue;
  final int _powersetBits;
  const PowersetValue(this._abstractValue, this._powersetBits);

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
      '[Powerset of ${_abstractValue.toString()} with bits ${_powersetBits}]';
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
  const PowersetDomain(this._abstractValueDomain);

  @override
  AbstractValue get dynamicType {
    int powersetBits = 0;
    AbstractValue abstractValue = _abstractValueDomain.dynamicType;
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  void writeAbstractValueToDataSink(
      DataSink sink, covariant PowersetValue value) {
    _abstractValueDomain.writeAbstractValueToDataSink(
        sink, value._abstractValue);
  }

  @override
  AbstractValue readAbstractValueFromDataSource(DataSource source) {
    int powersetBits = 0;
    AbstractValue abstractValue =
        _abstractValueDomain.readAbstractValueFromDataSource(source);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  String getCompactText(covariant PowersetValue value) =>
      _abstractValueDomain.getCompactText(value._abstractValue);

  @override
  AbstractBool isFixedLengthJsIndexable(covariant PowersetValue value) =>
      _abstractValueDomain.isFixedLengthJsIndexable(value._abstractValue);

  @override
  AbstractBool isJsIndexableAndIterable(covariant PowersetValue value) =>
      _abstractValueDomain.isJsIndexableAndIterable(unwrapOrNull(value));

  @override
  AbstractBool isJsIndexable(covariant PowersetValue value) =>
      _abstractValueDomain.isJsIndexable(value._abstractValue);

  @override
  MemberEntity locateSingleMember(
          covariant PowersetValue receiver, Selector selector) =>
      _abstractValueDomain.locateSingleMember(
          receiver._abstractValue, selector);

  @override
  AbstractBool isIn(
          covariant PowersetValue subset, covariant PowersetValue superset) =>
      _abstractValueDomain.isIn(subset._abstractValue, superset._abstractValue);

  @override
  AbstractBool needsNoSuchMethodHandling(
          covariant PowersetValue receiver, Selector selector) =>
      _abstractValueDomain.needsNoSuchMethodHandling(
          receiver._abstractValue, selector);

  @override
  AbstractBool isTargetingMember(
          covariant PowersetValue receiver, MemberEntity member, Name name) =>
      _abstractValueDomain.isTargetingMember(
          receiver._abstractValue, member, name);

  @override
  AbstractValue computeReceiver(Iterable<MemberEntity> members) {
    int powersetBits = 0;
    AbstractValue abstractValue = _abstractValueDomain.computeReceiver(members);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  PrimitiveConstantValue getPrimitiveValue(covariant PowersetValue value) =>
      _abstractValueDomain.getPrimitiveValue(value._abstractValue);

  @override
  AbstractValue createPrimitiveValue(
      covariant PowersetValue originalValue, PrimitiveConstantValue value) {
    int powersetBits = 0;
    AbstractValue abstractValue = _abstractValueDomain.createPrimitiveValue(
        originalValue._abstractValue, value);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  bool isPrimitiveValue(covariant PowersetValue value) =>
      _abstractValueDomain.isPrimitiveValue(value._abstractValue);

  @override
  MemberEntity getAllocationElement(covariant PowersetValue value) =>
      _abstractValueDomain.getAllocationElement(value._abstractValue);

  @override
  Object getAllocationNode(covariant PowersetValue value) =>
      _abstractValueDomain.getAllocationNode(value._abstractValue);

  @override
  AbstractValue getGeneralization(covariant PowersetValue value) {
    int powersetBits = 0;
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
    int powersetBits = 0;
    AbstractValue abstractValue = _abstractValueDomain.getDictionaryValueForKey(
        value._abstractValue, key);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  bool containsDictionaryKey(covariant PowersetValue value, String key) =>
      _abstractValueDomain.containsDictionaryKey(value._abstractValue, key);

  @override
  AbstractValue createDictionaryValue(
      covariant PowersetValue originalValue,
      Object allocationNode,
      MemberEntity allocationElement,
      covariant PowersetValue key,
      covariant PowersetValue value,
      covariant Map<String, AbstractValue> mappings) {
    int powersetBits = 0;
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
      _abstractValueDomain.isDictionary(value._abstractValue);

  @override
  AbstractValue getMapValueType(covariant PowersetValue value) {
    int powersetBits = 0;
    AbstractValue abstractValue =
        _abstractValueDomain.getMapValueType(value._abstractValue);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractValue getMapKeyType(covariant PowersetValue value) {
    int powersetBits = 0;
    AbstractValue abstractValue =
        _abstractValueDomain.getMapKeyType(value._abstractValue);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractValue createMapValue(
      covariant PowersetValue originalValue,
      Object allocationNode,
      MemberEntity allocationElement,
      covariant PowersetValue key,
      covariant PowersetValue value) {
    int powersetBits = 0;
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
      _abstractValueDomain.isMap(value._abstractValue);

  @override
  AbstractValue getSetElementType(covariant PowersetValue value) {
    int powersetBits = 0;
    AbstractValue abstractValue =
        _abstractValueDomain.getSetElementType(value._abstractValue);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractValue createSetValue(
      covariant PowersetValue originalValue,
      Object allocationNode,
      MemberEntity allocationElement,
      covariant PowersetValue elementType) {
    int powersetBits = 0;
    AbstractValue abstractValue = _abstractValueDomain.createSetValue(
        originalValue._abstractValue,
        allocationNode,
        allocationElement,
        elementType._abstractValue);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  bool isSet(covariant PowersetValue value) =>
      _abstractValueDomain.isSet(value._abstractValue);

  @override
  int getContainerLength(covariant PowersetValue value) =>
      _abstractValueDomain.getContainerLength(value._abstractValue);

  @override
  AbstractValue getContainerElementType(covariant PowersetValue value) {
    int powersetBits = 0;
    AbstractValue abstractValue =
        _abstractValueDomain.getContainerElementType(value._abstractValue);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractValue createContainerValue(
      covariant PowersetValue originalValue,
      Object allocationNode,
      MemberEntity allocationElement,
      covariant PowersetValue elementType,
      int length) {
    int powersetBits = 0;
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
      _abstractValueDomain.isContainer(value._abstractValue);

  @override
  AbstractValue computeAbstractValueForConstant(covariant ConstantValue value) {
    int powersetBits = 0;
    AbstractValue abstractValue =
        _abstractValueDomain.computeAbstractValueForConstant(value);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractValue getAbstractValueForNativeMethodParameterType(DartType type) {
    int powersetBits = 0;
    AbstractValue abstractValue =
        _abstractValueDomain.getAbstractValueForNativeMethodParameterType(type);
    return wrapOrNull(abstractValue, powersetBits);
  }

  @override
  AbstractBool containsAll(covariant PowersetValue a) =>
      _abstractValueDomain.containsAll(a._abstractValue);

  @override
  AbstractBool areDisjoint(
          covariant PowersetValue a, covariant PowersetValue b) =>
      _abstractValueDomain.areDisjoint(a._abstractValue, b._abstractValue);

  @override
  AbstractValue intersection(
      covariant PowersetValue a, covariant PowersetValue b) {
    int powersetBits = 0;
    AbstractValue abstractValue =
        _abstractValueDomain.intersection(a._abstractValue, b._abstractValue);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractValue unionOfMany(covariant Iterable<AbstractValue> values) {
    List<AbstractValue> unwrapped_Values = values
        .map((element) => (element as PowersetValue)._abstractValue)
        .toList();
    int powersetBits = 0;
    AbstractValue abstractValue =
        _abstractValueDomain.unionOfMany(unwrapped_Values);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractValue union(covariant PowersetValue a, covariant PowersetValue b) {
    int powersetBits = 0;
    AbstractValue abstractValue =
        _abstractValueDomain.union(a._abstractValue, b._abstractValue);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractBool isPrimitiveOrNull(covariant PowersetValue value) =>
      _abstractValueDomain.isPrimitiveOrNull(value._abstractValue);

  @override
  AbstractBool isStringOrNull(covariant PowersetValue value) =>
      _abstractValueDomain.isStringOrNull(value._abstractValue);

  @override
  AbstractBool isString(covariant PowersetValue value) =>
      _abstractValueDomain.isString(value._abstractValue);

  @override
  AbstractBool isBooleanOrNull(covariant PowersetValue value) =>
      _abstractValueDomain.isBooleanOrNull(value._abstractValue);

  @override
  AbstractBool isBoolean(covariant PowersetValue value) =>
      _abstractValueDomain.isBoolean(value._abstractValue);

  @override
  AbstractBool isDoubleOrNull(covariant PowersetValue value) =>
      _abstractValueDomain.isDoubleOrNull(value._abstractValue);

  @override
  AbstractBool isDouble(covariant PowersetValue value) =>
      _abstractValueDomain.isDouble(value._abstractValue);

  @override
  AbstractBool isNumberOrNull(covariant PowersetValue value) =>
      _abstractValueDomain.isNumberOrNull(value._abstractValue);

  @override
  AbstractBool isNumber(covariant PowersetValue value) =>
      _abstractValueDomain.isNumber(value._abstractValue);

  @override
  AbstractBool isIntegerOrNull(covariant PowersetValue value) =>
      _abstractValueDomain.isIntegerOrNull(value._abstractValue);

  @override
  AbstractBool isPositiveIntegerOrNull(covariant PowersetValue value) =>
      _abstractValueDomain.isPositiveIntegerOrNull(value._abstractValue);

  @override
  AbstractBool isPositiveInteger(covariant PowersetValue value) =>
      _abstractValueDomain.isPositiveInteger(value._abstractValue);

  @override
  AbstractBool isUInt31(covariant PowersetValue value) =>
      _abstractValueDomain.isUInt31(value._abstractValue);

  @override
  AbstractBool isUInt32(covariant PowersetValue value) =>
      _abstractValueDomain.isUInt32(value._abstractValue);

  @override
  AbstractBool isInteger(covariant PowersetValue value) =>
      _abstractValueDomain.isInteger(value._abstractValue);

  @override
  AbstractBool isInterceptor(covariant PowersetValue value) =>
      _abstractValueDomain.isInterceptor(value._abstractValue);

  @override
  AbstractBool isPrimitiveString(covariant PowersetValue value) =>
      _abstractValueDomain.isPrimitiveString(value._abstractValue);

  @override
  AbstractBool isArray(covariant PowersetValue value) =>
      _abstractValueDomain.isArray(value._abstractValue);

  @override
  AbstractBool isMutableIndexable(covariant PowersetValue value) =>
      _abstractValueDomain.isMutableIndexable(value._abstractValue);

  @override
  AbstractBool isMutableArray(covariant PowersetValue value) =>
      _abstractValueDomain.isMutableArray(value._abstractValue);

  @override
  AbstractBool isExtendableArray(covariant PowersetValue value) =>
      _abstractValueDomain.isExtendableArray(value._abstractValue);

  @override
  AbstractBool isFixedArray(covariant PowersetValue value) =>
      _abstractValueDomain.isFixedArray(value._abstractValue);

  @override
  AbstractBool isIndexablePrimitive(covariant PowersetValue value) =>
      _abstractValueDomain.isIndexablePrimitive(value._abstractValue);

  @override
  AbstractBool isPrimitiveArray(covariant PowersetValue value) =>
      _abstractValueDomain.isPrimitiveArray(value._abstractValue);

  @override
  AbstractBool isPrimitiveBoolean(covariant PowersetValue value) =>
      _abstractValueDomain.isPrimitiveBoolean(value._abstractValue);

  @override
  AbstractBool isPrimitiveNumber(covariant PowersetValue value) =>
      _abstractValueDomain.isPrimitiveNumber(value._abstractValue);

  @override
  AbstractBool isPrimitive(covariant PowersetValue value) =>
      _abstractValueDomain.isPrimitive(value._abstractValue);

  @override
  AbstractBool isNull(covariant PowersetValue value) =>
      _abstractValueDomain.isNull(value._abstractValue);

  @override
  ClassEntity getExactClass(covariant PowersetValue value) =>
      _abstractValueDomain.getExactClass(value._abstractValue);

  @override
  AbstractBool isExactOrNull(covariant PowersetValue value) =>
      _abstractValueDomain.isExactOrNull(value._abstractValue);

  @override
  AbstractBool isExact(covariant PowersetValue value) =>
      _abstractValueDomain.isExact(value._abstractValue);

  @override
  AbstractBool isEmpty(covariant PowersetValue value) =>
      _abstractValueDomain.isEmpty(value._abstractValue);

  @override
  AbstractBool isInstanceOf(covariant PowersetValue value, ClassEntity cls) =>
      _abstractValueDomain.isInstanceOf(value._abstractValue, cls);

  @override
  AbstractBool isInstanceOfOrNull(
          covariant PowersetValue value, ClassEntity cls) =>
      _abstractValueDomain.isInstanceOfOrNull(value._abstractValue, cls);

  @override
  AbstractBool containsOnlyType(
          covariant PowersetValue value, ClassEntity cls) =>
      _abstractValueDomain.containsOnlyType(value._abstractValue, cls);

  @override
  AbstractBool containsType(covariant PowersetValue value, ClassEntity cls) =>
      _abstractValueDomain.containsType(value._abstractValue, cls);

  @override
  AbstractValue includeNull(covariant PowersetValue value) {
    int powersetBits = 0;
    AbstractValue abstractValue =
        _abstractValueDomain.includeNull(value._abstractValue);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractValue excludeNull(covariant PowersetValue value) {
    int powersetBits = 0;
    AbstractValue abstractValue =
        _abstractValueDomain.excludeNull(value._abstractValue);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractBool couldBeTypedArray(covariant PowersetValue value) =>
      _abstractValueDomain.couldBeTypedArray(value._abstractValue);

  @override
  AbstractBool isTypedArray(covariant PowersetValue value) =>
      _abstractValueDomain.isTypedArray(value._abstractValue);

  @override
  AbstractValue createNullableSubtype(ClassEntity cls) {
    int powersetBits = 0;
    AbstractValue abstractValue =
        _abstractValueDomain.createNullableSubtype(cls);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractValue createNonNullSubtype(ClassEntity cls) {
    int powersetBits = 0;
    AbstractValue abstractValue =
        _abstractValueDomain.createNonNullSubtype(cls);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractValue createNonNullSubclass(ClassEntity cls) {
    int powersetBits = 0;
    AbstractValue abstractValue =
        _abstractValueDomain.createNonNullSubclass(cls);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractValue createNullableExact(ClassEntity cls) {
    int powersetBits = 0;
    AbstractValue abstractValue = _abstractValueDomain.createNullableExact(cls);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractValue createNonNullExact(ClassEntity cls) {
    int powersetBits = 0;
    AbstractValue abstractValue = _abstractValueDomain.createNonNullExact(cls);
    return PowersetValue(abstractValue, powersetBits);
  }

  @override
  AbstractValueWithPrecision createFromStaticType(DartType type,
      {ClassRelation classRelation = ClassRelation.subtype, bool nullable}) {
    int powersetBits = 0;
    var unwrapped = _abstractValueDomain.createFromStaticType(type,
        classRelation: classRelation, nullable: nullable);
    return AbstractValueWithPrecision(
        PowersetValue(unwrapped.abstractValue, powersetBits),
        unwrapped.isPrecise);
  }

  @override
  AbstractValue get asyncStarStreamType =>
      PowersetValue(_abstractValueDomain.asyncStarStreamType, 0);

  @override
  AbstractValue get asyncFutureType =>
      PowersetValue(_abstractValueDomain.asyncFutureType, 0);

  @override
  AbstractValue get syncStarIterableType =>
      PowersetValue(_abstractValueDomain.syncStarIterableType, 0);

  @override
  AbstractValue get emptyType =>
      PowersetValue(_abstractValueDomain.emptyType, 0);

  @override
  AbstractValue get constMapType =>
      PowersetValue(_abstractValueDomain.constMapType, 0);

  @override
  AbstractValue get constSetType =>
      PowersetValue(_abstractValueDomain.constSetType, 0);

  @override
  AbstractValue get constListType =>
      PowersetValue(_abstractValueDomain.constListType, 0);

  @override
  AbstractValue get positiveIntType =>
      PowersetValue(_abstractValueDomain.positiveIntType, 0);

  @override
  AbstractValue get uint32Type =>
      PowersetValue(_abstractValueDomain.uint32Type, 0);

  @override
  AbstractValue get uint31Type =>
      PowersetValue(_abstractValueDomain.uint31Type, 0);

  @override
  AbstractValue get fixedListType =>
      PowersetValue(_abstractValueDomain.fixedListType, 0);

  @override
  AbstractValue get growableListType =>
      PowersetValue(_abstractValueDomain.growableListType, 0);

  @override
  AbstractValue get nullType => PowersetValue(_abstractValueDomain.nullType, 0);

  @override
  AbstractValue get nonNullType =>
      PowersetValue(_abstractValueDomain.nonNullType, 0);

  @override
  AbstractValue get mapType => PowersetValue(_abstractValueDomain.mapType, 0);

  @override
  AbstractValue get setType => PowersetValue(_abstractValueDomain.setType, 0);

  @override
  AbstractValue get listType => PowersetValue(_abstractValueDomain.listType, 0);

  @override
  AbstractValue get stringType =>
      PowersetValue(_abstractValueDomain.stringType, 0);

  @override
  AbstractValue get numType => PowersetValue(_abstractValueDomain.numType, 0);

  @override
  AbstractValue get doubleType =>
      PowersetValue(_abstractValueDomain.doubleType, 0);

  @override
  AbstractValue get intType => PowersetValue(_abstractValueDomain.intType, 0);

  @override
  AbstractValue get boolType => PowersetValue(_abstractValueDomain.boolType, 0);

  @override
  AbstractValue get functionType =>
      PowersetValue(_abstractValueDomain.functionType, 0);

  @override
  AbstractValue get typeType => PowersetValue(_abstractValueDomain.typeType, 0);
}

class PowersetStrategy implements AbstractValueStrategy {
  final AbstractValueStrategy _abstractValueStrategy;
  const PowersetStrategy(this._abstractValueStrategy);

  @override
  AbstractValueDomain createDomain(JClosedWorld closedWorld) {
    return PowersetDomain(_abstractValueStrategy.createDomain(closedWorld));
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
