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

class WrappedAbstractValue implements AbstractValue {
  final AbstractValue _abstractValue;
  const WrappedAbstractValue(this._abstractValue);

  @override
  bool operator ==(var other) {
    if (identical(this, other)) return true;
    if (other is! WrappedAbstractValue) return false;
    WrappedAbstractValue otherWrapped = other;
    return other is WrappedAbstractValue &&
        _abstractValue == otherWrapped._abstractValue;
  }

  @override
  int get hashCode {
    return _abstractValue.hashCode;
  }

  @override
  String toString() => _abstractValue.toString();
}

AbstractValue unwrapOrNull(WrappedAbstractValue wrapped) {
  return wrapped == null ? null : wrapped._abstractValue;
}

WrappedAbstractValue wrapOrNull(AbstractValue abstractValue) {
  return abstractValue == null ? null : WrappedAbstractValue(abstractValue);
}

class WrappedAbstractValueDomain implements AbstractValueDomain {
  final AbstractValueDomain _abstractValueDomain;
  const WrappedAbstractValueDomain(this._abstractValueDomain);

  @override
  AbstractValue get dynamicType =>
      WrappedAbstractValue(_abstractValueDomain.dynamicType);

  @override
  void writeAbstractValueToDataSink(
      DataSink sink, covariant WrappedAbstractValue value) {
    _abstractValueDomain.writeAbstractValueToDataSink(
        sink, value._abstractValue);
  }

  @override
  AbstractValue readAbstractValueFromDataSource(DataSource source) =>
      WrappedAbstractValue(
          _abstractValueDomain.readAbstractValueFromDataSource(source));

  @override
  String getCompactText(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.getCompactText(value._abstractValue);

  @override
  AbstractBool isFixedLengthJsIndexable(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isFixedLengthJsIndexable(value._abstractValue);

  @override
  AbstractBool isJsIndexableAndIterable(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isJsIndexableAndIterable(value._abstractValue);

  @override
  AbstractBool isJsIndexable(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isJsIndexable(value._abstractValue);

  @override
  MemberEntity locateSingleMember(
          covariant WrappedAbstractValue receiver, Selector selector) =>
      _abstractValueDomain.locateSingleMember(
          receiver._abstractValue, selector);

  @override
  AbstractBool isIn(covariant WrappedAbstractValue subset,
          covariant WrappedAbstractValue superset) =>
      _abstractValueDomain.isIn(subset._abstractValue, superset._abstractValue);

  @override
  AbstractBool needsNoSuchMethodHandling(
          covariant WrappedAbstractValue receiver, Selector selector) =>
      _abstractValueDomain.needsNoSuchMethodHandling(
          receiver._abstractValue, selector);

  @override
  AbstractBool isTargetingMember(covariant WrappedAbstractValue receiver,
          MemberEntity member, Name name) =>
      _abstractValueDomain.isTargetingMember(
          receiver._abstractValue, member, name);

  @override
  AbstractValue computeReceiver(Iterable<MemberEntity> members) =>
      WrappedAbstractValue(_abstractValueDomain.computeReceiver(members));

  @override
  PrimitiveConstantValue getPrimitiveValue(
          covariant WrappedAbstractValue value) =>
      _abstractValueDomain.getPrimitiveValue(value._abstractValue);

  @override
  AbstractValue createPrimitiveValue(
          covariant WrappedAbstractValue originalValue,
          PrimitiveConstantValue value) =>
      WrappedAbstractValue(_abstractValueDomain.createPrimitiveValue(
          originalValue._abstractValue, value));

  @override
  bool isPrimitiveValue(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isPrimitiveValue(value._abstractValue);

  @override
  MemberEntity getAllocationElement(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.getAllocationElement(value._abstractValue);

  @override
  Object getAllocationNode(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.getAllocationNode(value._abstractValue);

  @override
  AbstractValue getGeneralization(covariant WrappedAbstractValue value) =>
      WrappedAbstractValue(
          _abstractValueDomain.getGeneralization(unwrapOrNull(value)));

  @override
  bool isSpecializationOf(covariant WrappedAbstractValue specialization,
          covariant WrappedAbstractValue generalization) =>
      _abstractValueDomain.isSpecializationOf(
          specialization._abstractValue, generalization._abstractValue);

  @override
  AbstractValue getDictionaryValueForKey(
          covariant WrappedAbstractValue value, String key) =>
      WrappedAbstractValue(_abstractValueDomain.getDictionaryValueForKey(
          value._abstractValue, key));

  @override
  bool containsDictionaryKey(
          covariant WrappedAbstractValue value, String key) =>
      _abstractValueDomain.containsDictionaryKey(value._abstractValue, key);

  @override
  AbstractValue createDictionaryValue(
      covariant WrappedAbstractValue originalValue,
      Object allocationNode,
      MemberEntity allocationElement,
      covariant WrappedAbstractValue key,
      covariant WrappedAbstractValue value,
      covariant Map<String, AbstractValue> mappings) {
    return WrappedAbstractValue(_abstractValueDomain.createDictionaryValue(
        originalValue._abstractValue,
        allocationNode,
        allocationElement,
        key._abstractValue,
        value._abstractValue, {
      for (var entry in mappings.entries)
        entry.key: (entry.value as WrappedAbstractValue)._abstractValue
    }));
  }

  @override
  bool isDictionary(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isDictionary(value._abstractValue);

  @override
  AbstractValue getMapValueType(covariant WrappedAbstractValue value) =>
      WrappedAbstractValue(
          _abstractValueDomain.getMapValueType(value._abstractValue));

  @override
  AbstractValue getMapKeyType(covariant WrappedAbstractValue value) =>
      WrappedAbstractValue(
          _abstractValueDomain.getMapKeyType(value._abstractValue));

  @override
  AbstractValue createMapValue(
          covariant WrappedAbstractValue originalValue,
          Object allocationNode,
          MemberEntity allocationElement,
          covariant WrappedAbstractValue key,
          covariant WrappedAbstractValue value) =>
      WrappedAbstractValue(_abstractValueDomain.createMapValue(
          originalValue._abstractValue,
          allocationNode,
          allocationElement,
          key._abstractValue,
          value._abstractValue));

  @override
  bool isMap(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isMap(value._abstractValue);

  @override
  AbstractValue getSetElementType(covariant WrappedAbstractValue value) =>
      WrappedAbstractValue(
          _abstractValueDomain.getSetElementType(value._abstractValue));

  @override
  AbstractValue createSetValue(
          covariant WrappedAbstractValue originalValue,
          Object allocationNode,
          MemberEntity allocationElement,
          covariant WrappedAbstractValue elementType) =>
      WrappedAbstractValue(_abstractValueDomain.createSetValue(
          originalValue._abstractValue,
          allocationNode,
          allocationElement,
          elementType._abstractValue));

  @override
  bool isSet(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isSet(value._abstractValue);

  @override
  int getContainerLength(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.getContainerLength(value._abstractValue);

  @override
  AbstractValue getContainerElementType(covariant WrappedAbstractValue value) =>
      WrappedAbstractValue(
          _abstractValueDomain.getContainerElementType(value._abstractValue));

  @override
  AbstractValue createContainerValue(
          covariant WrappedAbstractValue originalValue,
          Object allocationNode,
          MemberEntity allocationElement,
          covariant WrappedAbstractValue elementType,
          int length) =>
      WrappedAbstractValue(_abstractValueDomain.createContainerValue(
          originalValue._abstractValue,
          allocationNode,
          allocationElement,
          elementType._abstractValue,
          length));

  @override
  bool isContainer(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isContainer(value._abstractValue);

  @override
  AbstractValue computeAbstractValueForConstant(
          covariant ConstantValue value) =>
      WrappedAbstractValue(
          _abstractValueDomain.computeAbstractValueForConstant(value));

  @override
  AbstractValue getAbstractValueForNativeMethodParameterType(DartType type) {
    return wrapOrNull(_abstractValueDomain
        .getAbstractValueForNativeMethodParameterType(type));
  }

  @override
  AbstractBool containsAll(covariant WrappedAbstractValue a) =>
      _abstractValueDomain.containsAll(a._abstractValue);

  @override
  AbstractBool areDisjoint(
          covariant WrappedAbstractValue a, covariant WrappedAbstractValue b) =>
      _abstractValueDomain.areDisjoint(a._abstractValue, b._abstractValue);

  @override
  AbstractValue intersection(
          covariant WrappedAbstractValue a, covariant WrappedAbstractValue b) =>
      WrappedAbstractValue(_abstractValueDomain.intersection(
          a._abstractValue, b._abstractValue));

  @override
  AbstractValue unionOfMany(covariant Iterable<AbstractValue> values) {
    List<AbstractValue> unwrapped_Values = values
        .map((element) => (element as WrappedAbstractValue)._abstractValue)
        .toList();
    return WrappedAbstractValue(
        _abstractValueDomain.unionOfMany(unwrapped_Values));
  }

  @override
  AbstractValue union(
          covariant WrappedAbstractValue a, covariant WrappedAbstractValue b) =>
      WrappedAbstractValue(
          _abstractValueDomain.union(a._abstractValue, b._abstractValue));

  @override
  AbstractBool isPrimitiveOrNull(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isPrimitiveOrNull(value._abstractValue);

  @override
  AbstractBool isStringOrNull(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isStringOrNull(value._abstractValue);

  @override
  AbstractBool isString(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isString(value._abstractValue);

  @override
  AbstractBool isBooleanOrNull(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isBooleanOrNull(value._abstractValue);

  @override
  AbstractBool isBoolean(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isBoolean(value._abstractValue);

  @override
  AbstractBool isTruthy(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isTruthy(value._abstractValue);

  @override
  AbstractBool isDoubleOrNull(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isDoubleOrNull(value._abstractValue);

  @override
  AbstractBool isDouble(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isDouble(value._abstractValue);

  @override
  AbstractBool isNumberOrNull(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isNumberOrNull(value._abstractValue);

  @override
  AbstractBool isNumber(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isNumber(value._abstractValue);

  @override
  AbstractBool isIntegerOrNull(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isIntegerOrNull(value._abstractValue);

  @override
  AbstractBool isPositiveIntegerOrNull(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isPositiveIntegerOrNull(value._abstractValue);

  @override
  AbstractBool isPositiveInteger(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isPositiveInteger(value._abstractValue);

  @override
  AbstractBool isUInt31(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isUInt31(value._abstractValue);

  @override
  AbstractBool isUInt32(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isUInt32(value._abstractValue);

  @override
  AbstractBool isInteger(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isInteger(value._abstractValue);

  @override
  AbstractBool isInterceptor(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isInterceptor(value._abstractValue);

  @override
  AbstractBool isPrimitiveString(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isPrimitiveString(value._abstractValue);

  @override
  AbstractBool isArray(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isArray(value._abstractValue);

  @override
  AbstractBool isMutableIndexable(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isMutableIndexable(value._abstractValue);

  @override
  AbstractBool isMutableArray(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isMutableArray(value._abstractValue);

  @override
  AbstractBool isExtendableArray(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isExtendableArray(value._abstractValue);

  @override
  AbstractBool isFixedArray(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isFixedArray(value._abstractValue);

  @override
  AbstractBool isIndexablePrimitive(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isIndexablePrimitive(value._abstractValue);

  @override
  AbstractBool isPrimitiveArray(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isPrimitiveArray(value._abstractValue);

  @override
  AbstractBool isPrimitiveBoolean(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isPrimitiveBoolean(value._abstractValue);

  @override
  AbstractBool isPrimitiveNumber(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isPrimitiveNumber(value._abstractValue);

  @override
  AbstractBool isPrimitive(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isPrimitive(value._abstractValue);

  @override
  AbstractBool isNull(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isNull(value._abstractValue);

  @override
  ClassEntity getExactClass(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.getExactClass(value._abstractValue);

  @override
  AbstractBool isExactOrNull(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isExactOrNull(value._abstractValue);

  @override
  AbstractBool isExact(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isExact(value._abstractValue);

  @override
  AbstractBool isEmpty(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isEmpty(value._abstractValue);

  @override
  AbstractBool isInstanceOf(
          covariant WrappedAbstractValue value, ClassEntity cls) =>
      _abstractValueDomain.isInstanceOf(value._abstractValue, cls);

  @override
  AbstractBool isInstanceOfOrNull(
          covariant WrappedAbstractValue value, ClassEntity cls) =>
      _abstractValueDomain.isInstanceOfOrNull(value._abstractValue, cls);

  @override
  AbstractBool containsOnlyType(
          covariant WrappedAbstractValue value, ClassEntity cls) =>
      _abstractValueDomain.containsOnlyType(value._abstractValue, cls);

  @override
  AbstractBool containsType(
          covariant WrappedAbstractValue value, ClassEntity cls) =>
      _abstractValueDomain.containsType(value._abstractValue, cls);

  @override
  AbstractValue includeNull(covariant WrappedAbstractValue value) =>
      WrappedAbstractValue(
          _abstractValueDomain.includeNull(value._abstractValue));

  @override
  AbstractValue excludeNull(covariant WrappedAbstractValue value) =>
      WrappedAbstractValue(
          _abstractValueDomain.excludeNull(value._abstractValue));

  @override
  AbstractBool couldBeTypedArray(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.couldBeTypedArray(value._abstractValue);

  @override
  AbstractBool isTypedArray(covariant WrappedAbstractValue value) =>
      _abstractValueDomain.isTypedArray(value._abstractValue);

  @override
  AbstractValue createNullableSubtype(ClassEntity cls) =>
      WrappedAbstractValue(_abstractValueDomain.createNullableSubtype(cls));

  @override
  AbstractValue createNonNullSubtype(ClassEntity cls) =>
      WrappedAbstractValue(_abstractValueDomain.createNonNullSubtype(cls));

  @override
  AbstractValue createNonNullSubclass(ClassEntity cls) =>
      WrappedAbstractValue(_abstractValueDomain.createNonNullSubclass(cls));

  @override
  AbstractValue createNullableExact(ClassEntity cls) =>
      WrappedAbstractValue(_abstractValueDomain.createNullableExact(cls));

  @override
  AbstractValue createNonNullExact(ClassEntity cls) =>
      WrappedAbstractValue(_abstractValueDomain.createNonNullExact(cls));

  @override
  AbstractValueWithPrecision createFromStaticType(DartType type,
      {ClassRelation classRelation = ClassRelation.subtype, bool nullable}) {
    var unwrapped = _abstractValueDomain.createFromStaticType(type,
        classRelation: classRelation, nullable: nullable);
    return AbstractValueWithPrecision(
        WrappedAbstractValue(unwrapped.abstractValue), unwrapped.isPrecise);
  }

  @override
  AbstractValue get asyncStarStreamType =>
      WrappedAbstractValue(_abstractValueDomain.asyncStarStreamType);

  @override
  AbstractValue get asyncFutureType =>
      WrappedAbstractValue(_abstractValueDomain.asyncFutureType);

  @override
  AbstractValue get syncStarIterableType =>
      WrappedAbstractValue(_abstractValueDomain.syncStarIterableType);

  @override
  AbstractValue get emptyType =>
      WrappedAbstractValue(_abstractValueDomain.emptyType);

  @override
  AbstractValue get constMapType =>
      WrappedAbstractValue(_abstractValueDomain.constMapType);

  @override
  AbstractValue get constSetType =>
      WrappedAbstractValue(_abstractValueDomain.constSetType);

  @override
  AbstractValue get constListType =>
      WrappedAbstractValue(_abstractValueDomain.constListType);

  @override
  AbstractValue get positiveIntType =>
      WrappedAbstractValue(_abstractValueDomain.positiveIntType);

  @override
  AbstractValue get uint32Type =>
      WrappedAbstractValue(_abstractValueDomain.uint32Type);

  @override
  AbstractValue get uint31Type =>
      WrappedAbstractValue(_abstractValueDomain.uint31Type);

  @override
  AbstractValue get fixedListType =>
      WrappedAbstractValue(_abstractValueDomain.fixedListType);

  @override
  AbstractValue get growableListType =>
      WrappedAbstractValue(_abstractValueDomain.growableListType);

  @override
  AbstractValue get mutableArrayType =>
      WrappedAbstractValue(_abstractValueDomain.mutableArrayType);

  @override
  AbstractValue get nullType =>
      WrappedAbstractValue(_abstractValueDomain.nullType);

  @override
  AbstractValue get nonNullType =>
      WrappedAbstractValue(_abstractValueDomain.nonNullType);

  @override
  AbstractValue get mapType =>
      WrappedAbstractValue(_abstractValueDomain.mapType);

  @override
  AbstractValue get setType =>
      WrappedAbstractValue(_abstractValueDomain.setType);

  @override
  AbstractValue get listType =>
      WrappedAbstractValue(_abstractValueDomain.listType);

  @override
  AbstractValue get stringType =>
      WrappedAbstractValue(_abstractValueDomain.stringType);

  @override
  AbstractValue get numType =>
      WrappedAbstractValue(_abstractValueDomain.numType);

  @override
  AbstractValue get doubleType =>
      WrappedAbstractValue(_abstractValueDomain.doubleType);

  @override
  AbstractValue get intType =>
      WrappedAbstractValue(_abstractValueDomain.intType);

  @override
  AbstractValue get boolType =>
      WrappedAbstractValue(_abstractValueDomain.boolType);

  @override
  AbstractValue get functionType =>
      WrappedAbstractValue(_abstractValueDomain.functionType);

  @override
  AbstractValue get typeType =>
      WrappedAbstractValue(_abstractValueDomain.typeType);
}

class WrappedAbstractValueStrategy implements AbstractValueStrategy {
  final AbstractValueStrategy _abstractValueStrategy;
  const WrappedAbstractValueStrategy(this._abstractValueStrategy);

  @override
  AbstractValueDomain createDomain(JClosedWorld closedWorld) {
    return WrappedAbstractValueDomain(
        _abstractValueStrategy.createDomain(closedWorld));
  }

  @override
  SelectorConstraintsStrategy createSelectorStrategy() {
    return WrappedSelectorStrategy(
        _abstractValueStrategy.createSelectorStrategy());
  }
}

class WrappedSelectorStrategy implements SelectorConstraintsStrategy {
  final SelectorConstraintsStrategy _selectorConstraintsStrategy;
  const WrappedSelectorStrategy(this._selectorConstraintsStrategy);

  @override
  UniverseSelectorConstraints createSelectorConstraints(
      Selector selector, Object initialConstraint) {
    return WrappedUniverseSelectorConstraints(
        _selectorConstraintsStrategy.createSelectorConstraints(
            selector,
            initialConstraint == null
                ? null
                : (initialConstraint as WrappedAbstractValue)._abstractValue));
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

class WrappedUniverseSelectorConstraints
    implements UniverseSelectorConstraints {
  final UniverseSelectorConstraints _universeSelectorConstraints;
  const WrappedUniverseSelectorConstraints(this._universeSelectorConstraints);

  @override
  bool addReceiverConstraint(Object constraint) =>
      _universeSelectorConstraints.addReceiverConstraint(constraint == null
          ? null
          : (constraint as WrappedAbstractValue)._abstractValue);

  @override
  bool needsNoSuchMethodHandling(Selector selector, World world) =>
      _universeSelectorConstraints.needsNoSuchMethodHandling(selector, world);

  @override
  bool canHit(MemberEntity element, Name name, World world) =>
      _universeSelectorConstraints.canHit(element, name, world);

  @override
  String toString() => 'WrappedUniverseSelectorConstraints:$hashCode';
}
