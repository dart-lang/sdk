// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../constants/values.dart' show ConstantValue, PrimitiveConstantValue;
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/types.dart' show DartType;
import '../js_model/js_world.dart';
import '../serialization/serialization.dart';
import '../universe/member_hierarchy.dart';
import '../universe/record_shape.dart';
import '../universe/selector.dart';
import '../universe/world_builder.dart';
import '../universe/use.dart';
import '../world.dart';
import 'abstract_value_domain.dart';
import 'abstract_value_strategy.dart';

class TrivialAbstractValue implements AbstractValue {
  const TrivialAbstractValue();

  @override
  String toString() => '?';
}

class TrivialAbstractValueDomain with AbstractValueDomain {
  const TrivialAbstractValueDomain();

  @override
  AbstractValue get internalTopType => const TrivialAbstractValue();

  @override
  AbstractValue get dynamicType => const TrivialAbstractValue();

  @override
  void writeAbstractValueToDataSink(
    DataSinkWriter sink,
    AbstractValue? value,
  ) {}

  @override
  AbstractValue readAbstractValueFromDataSource(DataSourceReader source) =>
      const TrivialAbstractValue();

  @override
  String getCompactText(AbstractValue value) => '?';

  @override
  AbstractBool isFixedLengthJsIndexable(AbstractValue value) =>
      AbstractBool.maybe;

  @override
  AbstractBool isJsIndexableAndIterable(AbstractValue value) =>
      AbstractBool.maybe;

  @override
  AbstractBool isJsIndexable(AbstractValue value) => AbstractBool.maybe;

  @override
  MemberEntity? locateSingleMember(AbstractValue receiver, Selector selector) =>
      null;

  @override
  AbstractBool isIn(AbstractValue subset, AbstractValue superset) =>
      AbstractBool.maybe;

  @override
  AbstractBool needsNoSuchMethodHandling(
    AbstractValue receiver,
    Selector selector,
  ) => AbstractBool.maybe;

  @override
  AbstractBool isTargetingMember(
    AbstractValue receiver,
    MemberEntity member,
    Name name,
  ) => AbstractBool.maybe;

  @override
  AbstractValue computeReceiver(Iterable<MemberEntity> members) =>
      const TrivialAbstractValue();

  @override
  PrimitiveConstantValue? getPrimitiveValue(AbstractValue value) => null;

  @override
  AbstractValue createPrimitiveValue(
    AbstractValue originalValue,
    PrimitiveConstantValue value,
  ) => const TrivialAbstractValue();

  @override
  bool isPrimitiveValue(AbstractValue value) => false;

  @override
  MemberEntity? getAllocationElement(AbstractValue value) => null;

  @override
  Object? getAllocationNode(AbstractValue value) => null;

  @override
  AbstractValue getGeneralization(AbstractValue? value) =>
      const TrivialAbstractValue();

  @override
  bool isSpecializationOf(
    AbstractValue specialization,
    AbstractValue generalization,
  ) => false;

  @override
  AbstractValue getDictionaryValueForKey(AbstractValue value, String key) {
    throw UnsupportedError(
      "TrivialAbstractValueDomain.getDictionaryValueForKey",
    );
  }

  @override
  bool containsDictionaryKey(AbstractValue value, String key) {
    throw UnsupportedError("TrivialAbstractValueDomain.containsDictionaryKey");
  }

  @override
  AbstractValue createDictionaryValue(
    AbstractValue? originalValue,
    Object? allocationNode,
    MemberEntity? allocationElement,
    AbstractValue key,
    AbstractValue value,
    Map<String, AbstractValue> mappings,
  ) => const TrivialAbstractValue();

  @override
  bool isDictionary(AbstractValue value) => false;

  @override
  AbstractValue createRecordValue(
    RecordShape shape,
    List<AbstractValue> types,
  ) => const TrivialAbstractValue();

  @override
  bool isRecord(AbstractValue value) => false;

  @override
  bool recordHasGetter(AbstractValue value, String getterName) => false;

  @override
  AbstractValue getGetterTypeInRecord(AbstractValue value, String getterName) =>
      TrivialAbstractValue();

  @override
  AbstractValue getMapValueType(AbstractValue value) {
    throw UnsupportedError("TrivialAbstractValueDomain.getMapValueType");
  }

  @override
  AbstractValue getMapKeyType(AbstractValue value) {
    throw UnsupportedError("TrivialAbstractValueDomain.getMapKeyType");
  }

  @override
  AbstractValue createMapValue(
    AbstractValue? originalValue,
    Object? allocationNode,
    MemberEntity? allocationElement,
    AbstractValue key,
    AbstractValue value,
  ) => const TrivialAbstractValue();

  @override
  bool isMap(AbstractValue value) => false;

  @override
  AbstractValue getSetElementType(AbstractValue value) {
    throw UnsupportedError("TrivialAbstractValueDomain.getSetElementType");
  }

  @override
  AbstractValue createSetValue(
    AbstractValue? originalValue,
    Object? allocationNode,
    MemberEntity? allocationElement,
    AbstractValue elementType,
  ) => const TrivialAbstractValue();

  @override
  bool isSet(AbstractValue value) => false;

  @override
  int? getContainerLength(AbstractValue value) => null;

  @override
  AbstractValue getContainerElementType(AbstractValue value) {
    throw UnsupportedError(
      "TrivialAbstractValueDomain.getContainerElementType",
    );
  }

  @override
  AbstractValue createContainerValue(
    AbstractValue? originalValue,
    Object? allocationNode,
    MemberEntity? allocationElement,
    AbstractValue elementType,
    int? length,
  ) => const TrivialAbstractValue();

  @override
  bool isContainer(AbstractValue value) => false;

  @override
  AbstractValue computeAbstractValueForConstant(ConstantValue value) =>
      const TrivialAbstractValue();

  @override
  AbstractValue? getAbstractValueForNativeMethodParameterType(DartType type) =>
      null;

  @override
  AbstractBool containsAll(AbstractValue a) => AbstractBool.maybe;

  @override
  AbstractBool areDisjoint(AbstractValue a, AbstractValue b) =>
      AbstractBool.maybe;

  @override
  AbstractValue intersection(AbstractValue a, AbstractValue b) =>
      const TrivialAbstractValue();

  @override
  AbstractValue unionOfMany(Iterable<AbstractValue> values) =>
      const TrivialAbstractValue();

  @override
  AbstractValue union(AbstractValue a, AbstractValue b) =>
      const TrivialAbstractValue();

  @override
  AbstractBool isPrimitiveOrNull(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isStringOrNull(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isString(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isBooleanOrNull(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isBoolean(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isTruthy(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isNumberOrNull(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isNumber(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isIntegerOrNull(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isPositiveIntegerOrNull(AbstractValue value) =>
      AbstractBool.maybe;

  @override
  AbstractBool isPositiveInteger(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isUInt31(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isUInt32(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isInteger(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isInterceptor(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isPrimitiveString(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isArray(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isGrowableArray(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isModifiableArray(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isMutableIndexable(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isIndexablePrimitive(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isPrimitiveBoolean(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isPrimitiveNumber(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isPrimitive(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isNull(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isLateSentinel(AbstractValue value) => AbstractBool.maybe;

  @override
  ClassEntity? getExactClass(AbstractValue value) => null;

  @override
  AbstractBool isExact(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isEmpty(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isInstanceOf(AbstractValue value, ClassEntity cls) =>
      AbstractBool.maybe;

  @override
  AbstractBool containsOnlyType(AbstractValue value, ClassEntity cls) =>
      AbstractBool.maybe;

  @override
  AbstractBool containsType(AbstractValue value, ClassEntity cls) =>
      AbstractBool.maybe;

  @override
  AbstractValue includeNull(AbstractValue value) =>
      const TrivialAbstractValue();

  @override
  AbstractValue excludeNull(AbstractValue value) =>
      const TrivialAbstractValue();

  @override
  AbstractValue includeLateSentinel(AbstractValue value) =>
      const TrivialAbstractValue();

  @override
  AbstractValue excludeLateSentinel(AbstractValue value) =>
      const TrivialAbstractValue();

  @override
  AbstractBool couldBeTypedArray(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractBool isTypedArray(AbstractValue value) => AbstractBool.maybe;

  @override
  AbstractValue createNullableSubtype(ClassEntity cls) =>
      const TrivialAbstractValue();

  @override
  AbstractValue createNonNullSubtype(ClassEntity cls) =>
      const TrivialAbstractValue();

  @override
  AbstractValue createNonNullSubclass(ClassEntity cls) =>
      const TrivialAbstractValue();

  @override
  AbstractValue createNullableExact(ClassEntity cls) =>
      const TrivialAbstractValue();

  @override
  AbstractValue createNonNullExact(ClassEntity cls) =>
      const TrivialAbstractValue();

  @override
  AbstractValueWithPrecision createFromStaticType(DartType type) {
    return const AbstractValueWithPrecision(TrivialAbstractValue(), false);
  }

  @override
  Iterable<DynamicCallTarget> findRootsOfTargets(
    covariant TrivialAbstractValue receiver,
    Selector selector,
    MemberHierarchyBuilder memberHierarchyBuilder,
  ) => const [];

  @override
  bool isInvalidRefinement(AbstractValue before, AbstractValue after) => true;

  @override
  AbstractValue get asyncStarStreamType => const TrivialAbstractValue();

  @override
  AbstractValue get asyncFutureType => const TrivialAbstractValue();

  @override
  AbstractValue get syncStarIterableType => const TrivialAbstractValue();

  @override
  AbstractValue get emptyType => const TrivialAbstractValue();

  @override
  AbstractValue get constMapType => const TrivialAbstractValue();

  @override
  AbstractValue get constSetType => const TrivialAbstractValue();

  @override
  AbstractValue get constListType => const TrivialAbstractValue();

  @override
  AbstractValue get positiveIntType => const TrivialAbstractValue();

  @override
  AbstractValue get uint32Type => const TrivialAbstractValue();

  @override
  AbstractValue get uint31Type => const TrivialAbstractValue();

  @override
  AbstractValue get fixedListType => const TrivialAbstractValue();

  @override
  AbstractValue get growableListType => const TrivialAbstractValue();

  @override
  AbstractValue get mutableArrayType => const TrivialAbstractValue();

  @override
  AbstractValue get nullType => const TrivialAbstractValue();

  @override
  AbstractValue get nonNullType => const TrivialAbstractValue();

  @override
  AbstractValue get lateSentinelType => const TrivialAbstractValue();

  @override
  AbstractValue get mapType => const TrivialAbstractValue();

  @override
  AbstractValue get setType => const TrivialAbstractValue();

  @override
  AbstractValue get listType => const TrivialAbstractValue();

  @override
  AbstractValue get stringType => const TrivialAbstractValue();

  @override
  AbstractValue get numType => const TrivialAbstractValue();

  @override
  AbstractValue get numNotIntType => const TrivialAbstractValue();

  @override
  AbstractValue get intType => const TrivialAbstractValue();

  @override
  AbstractValue get boolType => const TrivialAbstractValue();

  @override
  AbstractValue get functionType => const TrivialAbstractValue();

  @override
  AbstractValue get recordType => const TrivialAbstractValue();

  @override
  AbstractValue get typeType => const TrivialAbstractValue();
}

class TrivialAbstractValueStrategy
    implements AbstractValueStrategy<TrivialAbstractValueDomain> {
  const TrivialAbstractValueStrategy();

  @override
  TrivialAbstractValueDomain createDomain(JClosedWorld closedWorld) {
    return const TrivialAbstractValueDomain();
  }

  @override
  SelectorConstraintsStrategy createSelectorStrategy(
    TrivialAbstractValueDomain domain,
  ) {
    return const TrivialSelectorStrategy();
  }
}

class TrivialSelectorStrategy implements SelectorConstraintsStrategy {
  const TrivialSelectorStrategy();

  @override
  UniverseSelectorConstraints createSelectorConstraints(
    Selector selector,
    Object? initialConstraint,
  ) {
    return const TrivialUniverseSelectorConstraints();
  }

  @override
  bool appliedUnnamed(
    DynamicUse dynamicUse,
    MemberEntity member,
    covariant JClosedWorld world,
  ) {
    return dynamicUse.selector.appliesUnnamed(member);
  }
}

class TrivialUniverseSelectorConstraints
    implements UniverseSelectorConstraints {
  const TrivialUniverseSelectorConstraints();

  @override
  bool addReceiverConstraint(Object? constraint) => false;

  @override
  bool needsNoSuchMethodHandling(Selector selector, World world) => true;

  @override
  bool canHit(MemberEntity element, Name name, World world) => true;

  @override
  String toString() => 'TrivialUniverseSelectorConstraints:$hashCode';
}
