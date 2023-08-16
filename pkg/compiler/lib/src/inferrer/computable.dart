// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../constants/values.dart' show ConstantValue, PrimitiveConstantValue;
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/types.dart' show DartType;
import '../ir/static_type.dart';
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

class ComputableAbstractValue implements AbstractValue {
  final AbstractValue? _wrappedValue;
  const ComputableAbstractValue(this._wrappedValue);

  bool get isComputed => _wrappedValue != null;
  bool get isUncomputed => _wrappedValue == null;

  AbstractValue _unwrapOrThrow() => isUncomputed
      ? throw StateError("Uncomputed abstract value")
      : _wrappedValue!;

  AbstractValue _unwrapOrEmpty(AbstractValueDomain wrappedDomain) =>
      isUncomputed ? wrappedDomain.emptyType : _wrappedValue!;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is ComputableAbstractValue) {
      return _wrappedValue == other._wrappedValue;
    }
    return false;
  }

  @override
  int get hashCode => _wrappedValue.hashCode;

  @override
  String toString() =>
      isUncomputed ? "[uncomputed]" : _wrappedValue!.toString();
}

class ComputableAbstractValueDomain with AbstractValueDomain {
  final AbstractValueDomain _wrappedDomain;
  const ComputableAbstractValueDomain(this._wrappedDomain);

  AbstractValue _unwrap(ComputableAbstractValue value) =>
      value._unwrapOrEmpty(_wrappedDomain);

  AbstractValue? _unwrapOrNull(ComputableAbstractValue? value) =>
      value?._unwrapOrEmpty(_wrappedDomain);

  @override
  AbstractValue get uncomputedType => const ComputableAbstractValue(null);

  @override
  AbstractValue get internalTopType =>
      ComputableAbstractValue(_wrappedDomain.internalTopType);

  @override
  AbstractValue get dynamicType =>
      ComputableAbstractValue(_wrappedDomain.dynamicType);

  @override
  AbstractValue get typeType =>
      ComputableAbstractValue(_wrappedDomain.typeType);

  @override
  AbstractValue get functionType =>
      ComputableAbstractValue(_wrappedDomain.functionType);

  @override
  AbstractValue get recordType =>
      ComputableAbstractValue(_wrappedDomain.recordType);

  @override
  AbstractValue get boolType =>
      ComputableAbstractValue(_wrappedDomain.boolType);

  @override
  AbstractValue get intType => ComputableAbstractValue(_wrappedDomain.intType);

  @override
  AbstractValue get numNotIntType =>
      ComputableAbstractValue(_wrappedDomain.numNotIntType);

  @override
  AbstractValue get numType => ComputableAbstractValue(_wrappedDomain.numType);

  @override
  AbstractValue get stringType =>
      ComputableAbstractValue(_wrappedDomain.stringType);

  @override
  AbstractValue get listType =>
      ComputableAbstractValue(_wrappedDomain.listType);

  @override
  AbstractValue get setType => ComputableAbstractValue(_wrappedDomain.setType);

  @override
  AbstractValue get mapType => ComputableAbstractValue(_wrappedDomain.mapType);

  @override
  AbstractValue get nonNullType =>
      ComputableAbstractValue(_wrappedDomain.nonNullType);

  @override
  AbstractValue get nullType =>
      ComputableAbstractValue(_wrappedDomain.nullType);

  @override
  AbstractValue get lateSentinelType =>
      ComputableAbstractValue(_wrappedDomain.lateSentinelType);

  @override
  AbstractValue get growableListType =>
      ComputableAbstractValue(_wrappedDomain.growableListType);

  @override
  AbstractValue get fixedListType =>
      ComputableAbstractValue(_wrappedDomain.fixedListType);

  @override
  AbstractValue get mutableArrayType =>
      ComputableAbstractValue(_wrappedDomain.mutableArrayType);

  @override
  AbstractValue get uint31Type =>
      ComputableAbstractValue(_wrappedDomain.uint31Type);

  @override
  AbstractValue get uint32Type =>
      ComputableAbstractValue(_wrappedDomain.uint32Type);

  @override
  AbstractValue get positiveIntType =>
      ComputableAbstractValue(_wrappedDomain.positiveIntType);

  @override
  AbstractValue get constListType =>
      ComputableAbstractValue(_wrappedDomain.constListType);

  @override
  AbstractValue get constSetType =>
      ComputableAbstractValue(_wrappedDomain.constSetType);

  @override
  AbstractValue get constMapType =>
      ComputableAbstractValue(_wrappedDomain.constMapType);

  @override
  AbstractValue get emptyType =>
      ComputableAbstractValue(_wrappedDomain.emptyType);

  @override
  AbstractValue get syncStarIterableType =>
      ComputableAbstractValue(_wrappedDomain.syncStarIterableType);

  @override
  AbstractValue get asyncFutureType =>
      ComputableAbstractValue(_wrappedDomain.asyncFutureType);

  @override
  AbstractValue get asyncStarStreamType =>
      ComputableAbstractValue(_wrappedDomain.asyncStarStreamType);

  @override
  AbstractValueWithPrecision createFromStaticType(DartType type,
      {ClassRelation classRelation = ClassRelation.subtype,
      required bool nullable}) {
    final unwrapped = _wrappedDomain.createFromStaticType(type,
        classRelation: classRelation, nullable: nullable);
    return AbstractValueWithPrecision(
        ComputableAbstractValue(unwrapped.abstractValue), unwrapped.isPrecise);
  }

  @override
  AbstractValue createNonNullExact(ClassEntity cls) =>
      ComputableAbstractValue(_wrappedDomain.createNonNullExact(cls));

  @override
  AbstractValue createNullableExact(ClassEntity cls) =>
      ComputableAbstractValue(_wrappedDomain.createNullableExact(cls));

  @override
  AbstractValue createNonNullSubclass(ClassEntity cls) =>
      ComputableAbstractValue(_wrappedDomain.createNonNullSubclass(cls));

  @override
  AbstractValue createNonNullSubtype(ClassEntity cls) =>
      ComputableAbstractValue(_wrappedDomain.createNonNullSubtype(cls));

  @override
  AbstractValue createNullableSubtype(ClassEntity cls) =>
      ComputableAbstractValue(_wrappedDomain.createNullableSubtype(cls));

  @override
  AbstractBool isTypedArray(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isTypedArray(_unwrap(value));

  @override
  AbstractBool couldBeTypedArray(covariant ComputableAbstractValue value) =>
      _wrappedDomain.couldBeTypedArray(_unwrap(value));

  @override
  AbstractValue excludeNull(covariant ComputableAbstractValue value) =>
      ComputableAbstractValue(_wrappedDomain.excludeNull(_unwrap(value)));

  @override
  AbstractValue includeNull(covariant ComputableAbstractValue value) =>
      ComputableAbstractValue(_wrappedDomain.includeNull(_unwrap(value)));

  @override
  AbstractValue excludeLateSentinel(covariant ComputableAbstractValue value) =>
      ComputableAbstractValue(
          _wrappedDomain.excludeLateSentinel(_unwrap(value)));

  @override
  AbstractValue includeLateSentinel(covariant ComputableAbstractValue value) =>
      ComputableAbstractValue(
          _wrappedDomain.includeLateSentinel(_unwrap(value)));

  @override
  AbstractBool containsType(
          covariant ComputableAbstractValue value, ClassEntity cls) =>
      _wrappedDomain.containsType(_unwrap(value), cls);

  @override
  AbstractBool containsOnlyType(
          covariant ComputableAbstractValue value, ClassEntity cls) =>
      _wrappedDomain.containsOnlyType(_unwrap(value), cls);

  @override
  AbstractBool isInstanceOfOrNull(
          covariant ComputableAbstractValue value, ClassEntity cls) =>
      _wrappedDomain.isInstanceOfOrNull(_unwrap(value), cls);

  @override
  AbstractBool isInstanceOf(
          covariant ComputableAbstractValue value, ClassEntity cls) =>
      _wrappedDomain.isInstanceOf(_unwrap(value), cls);

  @override
  AbstractBool isEmpty(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isEmpty(_unwrap(value));

  @override
  AbstractBool isExact(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isExact(_unwrap(value));

  @override
  ClassEntity? getExactClass(covariant ComputableAbstractValue value) =>
      _wrappedDomain.getExactClass(_unwrap(value));

  @override
  AbstractBool isNull(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isNull(_unwrap(value));

  @override
  AbstractBool isLateSentinel(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isLateSentinel(_unwrap(value));

  @override
  AbstractBool isPrimitive(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isPrimitive(_unwrap(value));

  @override
  AbstractBool isPrimitiveNumber(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isPrimitiveNumber(_unwrap(value));

  @override
  AbstractBool isPrimitiveBoolean(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isPrimitiveBoolean(_unwrap(value));

  @override
  AbstractBool isIndexablePrimitive(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isIndexablePrimitive(_unwrap(value));

  @override
  AbstractBool isFixedArray(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isFixedArray(_unwrap(value));

  @override
  AbstractBool isExtendableArray(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isExtendableArray(_unwrap(value));

  @override
  AbstractBool isMutableArray(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isMutableArray(_unwrap(value));

  @override
  AbstractBool isMutableIndexable(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isMutableIndexable(_unwrap(value));

  @override
  AbstractBool isArray(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isArray(_unwrap(value));

  @override
  AbstractBool isPrimitiveString(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isPrimitiveString(_unwrap(value));

  @override
  AbstractBool isInterceptor(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isInterceptor(_unwrap(value));

  @override
  AbstractBool isInteger(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isInteger(_unwrap(value));

  @override
  AbstractBool isUInt32(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isUInt32(_unwrap(value));

  @override
  AbstractBool isUInt31(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isUInt31(_unwrap(value));

  @override
  AbstractBool isPositiveInteger(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isPositiveInteger(_unwrap(value));

  @override
  AbstractBool isPositiveIntegerOrNull(
          covariant ComputableAbstractValue value) =>
      _wrappedDomain.isPositiveIntegerOrNull(_unwrap(value));

  @override
  AbstractBool isIntegerOrNull(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isIntegerOrNull(_unwrap(value));

  @override
  AbstractBool isNumber(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isNumber(_unwrap(value));

  @override
  AbstractBool isNumberOrNull(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isNumberOrNull(_unwrap(value));

  @override
  AbstractBool isBoolean(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isBoolean(_unwrap(value));

  @override
  AbstractBool isBooleanOrNull(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isBooleanOrNull(_unwrap(value));

  @override
  AbstractBool isString(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isString(_unwrap(value));

  @override
  AbstractBool isStringOrNull(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isStringOrNull(_unwrap(value));

  @override
  AbstractBool isPrimitiveOrNull(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isPrimitiveOrNull(_unwrap(value));

  @override
  AbstractBool isTruthy(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isTruthy(_unwrap(value));

  @override
  AbstractValue union(covariant ComputableAbstractValue a,
          covariant ComputableAbstractValue b) =>
      ComputableAbstractValue(_wrappedDomain.union(_unwrap(a), _unwrap(b)));

  @override
  AbstractValue unionOfMany(covariant Iterable<AbstractValue> values) =>
      ComputableAbstractValue(_wrappedDomain.unionOfMany(values.map(
          (AbstractValue value) => _unwrap(value as ComputableAbstractValue))));

  @override
  AbstractValue intersection(covariant ComputableAbstractValue a,
          covariant ComputableAbstractValue b) =>
      ComputableAbstractValue(
          _wrappedDomain.intersection(_unwrap(a), _unwrap(b)));

  @override
  AbstractBool areDisjoint(covariant ComputableAbstractValue a,
          covariant ComputableAbstractValue b) =>
      _wrappedDomain.areDisjoint(_unwrap(a), _unwrap(b));

  @override
  AbstractBool containsAll(covariant ComputableAbstractValue a) =>
      _wrappedDomain.containsAll(_unwrap(a));

  @override
  AbstractValue computeAbstractValueForConstant(
          covariant ConstantValue value) =>
      ComputableAbstractValue(
          _wrappedDomain.computeAbstractValueForConstant(value));

  @override
  bool isContainer(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isContainer(_unwrap(value));

  @override
  AbstractValue createContainerValue(
          covariant ComputableAbstractValue? originalValue,
          Object? allocationNode,
          MemberEntity? allocationElement,
          covariant ComputableAbstractValue elementType,
          int? length) =>
      ComputableAbstractValue(_wrappedDomain.createContainerValue(
          _unwrapOrNull(originalValue),
          allocationNode,
          allocationElement,
          _unwrap(elementType),
          length));

  @override
  AbstractValue getContainerElementType(
          covariant ComputableAbstractValue value) =>
      ComputableAbstractValue(
          _wrappedDomain.getContainerElementType(_unwrap(value)));

  @override
  int? getContainerLength(covariant ComputableAbstractValue value) =>
      _wrappedDomain.getContainerLength(_unwrap(value));

  @override
  bool isSet(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isSet(_unwrap(value));

  @override
  AbstractValue createSetValue(
          covariant ComputableAbstractValue? originalValue,
          Object? allocationNode,
          MemberEntity? allocationElement,
          covariant ComputableAbstractValue elementType) =>
      ComputableAbstractValue(_wrappedDomain.createSetValue(
          _unwrapOrNull(originalValue),
          allocationNode,
          allocationElement,
          _unwrap(elementType)));

  @override
  AbstractValue getSetElementType(covariant ComputableAbstractValue value) =>
      ComputableAbstractValue(_wrappedDomain.getSetElementType(_unwrap(value)));

  @override
  bool isMap(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isMap(_unwrap(value));

  @override
  AbstractValue createMapValue(
          covariant ComputableAbstractValue? originalValue,
          Object? allocationNode,
          MemberEntity? allocationElement,
          covariant ComputableAbstractValue key,
          covariant ComputableAbstractValue value) =>
      ComputableAbstractValue(_wrappedDomain.createMapValue(
          _unwrapOrNull(originalValue),
          allocationNode,
          allocationElement,
          _unwrap(key),
          _unwrap(value)));

  @override
  AbstractValue getMapKeyType(covariant ComputableAbstractValue value) =>
      ComputableAbstractValue(_wrappedDomain.getMapKeyType(_unwrap(value)));

  @override
  AbstractValue getMapValueType(covariant ComputableAbstractValue value) =>
      ComputableAbstractValue(_wrappedDomain.getMapValueType(_unwrap(value)));

  @override
  bool isDictionary(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isDictionary(_unwrap(value));

  @override
  AbstractValue createDictionaryValue(
          covariant ComputableAbstractValue? originalValue,
          Object? allocationNode,
          MemberEntity? allocationElement,
          covariant ComputableAbstractValue key,
          covariant ComputableAbstractValue value,
          covariant Map<String, AbstractValue> mappings) =>
      ComputableAbstractValue(_wrappedDomain.createDictionaryValue(
          _unwrapOrNull(originalValue),
          allocationNode,
          allocationElement,
          _unwrap(key),
          _unwrap(value), {
        for (final entry in mappings.entries)
          entry.key: _unwrap(entry.value as ComputableAbstractValue)
      }));

  @override
  bool containsDictionaryKey(
          covariant ComputableAbstractValue value, String key) =>
      value.isComputed &&
      _wrappedDomain.containsDictionaryKey(value._wrappedValue!, key);

  @override
  AbstractValue getDictionaryValueForKey(
          covariant ComputableAbstractValue value, String key) =>
      ComputableAbstractValue(
          _wrappedDomain.getDictionaryValueForKey(_unwrap(value), key));

  @override
  AbstractValue createRecordValue(
      RecordShape shape, List<AbstractValue> types) {
    AbstractValue abstractValue = _wrappedDomain.createRecordValue(
        shape,
        types
            .map((e) => _unwrap(e as ComputableAbstractValue))
            .toList(growable: false));
    return ComputableAbstractValue(abstractValue);
  }

  @override
  bool isRecord(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isRecord(_unwrap(value));

  @override
  bool recordHasGetter(
          covariant ComputableAbstractValue value, String getterName) =>
      _wrappedDomain.recordHasGetter(_unwrap(value), getterName);

  @override
  AbstractValue getGetterTypeInRecord(
          covariant ComputableAbstractValue value, String getterName) =>
      _wrappedDomain.getGetterTypeInRecord(_unwrap(value), getterName);

  @override
  bool isSpecializationOf(covariant ComputableAbstractValue specialization,
          covariant ComputableAbstractValue generalization) =>
      _wrappedDomain.isSpecializationOf(
          _unwrap(specialization), _unwrap(generalization));

  @override
  AbstractValue? getGeneralization(covariant ComputableAbstractValue? value) {
    final generalization =
        _wrappedDomain.getGeneralization(_unwrapOrNull(value));
    if (generalization == null) return null;
    return ComputableAbstractValue(generalization);
  }

  @override
  Object? getAllocationNode(covariant ComputableAbstractValue value) =>
      _wrappedDomain.getAllocationNode(_unwrap(value));

  @override
  MemberEntity? getAllocationElement(covariant ComputableAbstractValue value) =>
      _wrappedDomain.getAllocationElement(_unwrap(value));

  @override
  bool isPrimitiveValue(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isPrimitiveValue(_unwrap(value));

  @override
  AbstractValue createPrimitiveValue(
          covariant ComputableAbstractValue originalValue,
          PrimitiveConstantValue value) =>
      ComputableAbstractValue(
          _wrappedDomain.createPrimitiveValue(_unwrap(originalValue), value));

  @override
  PrimitiveConstantValue? getPrimitiveValue(
          covariant ComputableAbstractValue value) =>
      _wrappedDomain.getPrimitiveValue(_unwrap(value));

  @override
  AbstractValue computeReceiver(Iterable<MemberEntity> members) =>
      ComputableAbstractValue(_wrappedDomain.computeReceiver(members));

  @override
  AbstractBool isTargetingMember(covariant ComputableAbstractValue receiver,
          MemberEntity member, Name name) =>
      _wrappedDomain.isTargetingMember(_unwrap(receiver), member, name);

  @override
  AbstractBool needsNoSuchMethodHandling(
          covariant ComputableAbstractValue receiver, Selector selector) =>
      _wrappedDomain.needsNoSuchMethodHandling(_unwrap(receiver), selector);

  @override
  AbstractValue? getAbstractValueForNativeMethodParameterType(DartType type) {
    final value =
        _wrappedDomain.getAbstractValueForNativeMethodParameterType(type);
    if (value == null) return null;
    return ComputableAbstractValue(value);
  }

  @override
  AbstractBool isIn(covariant ComputableAbstractValue subset,
          covariant ComputableAbstractValue superset) =>
      _wrappedDomain.isIn(_unwrap(subset), _unwrap(superset));

  @override
  MemberEntity? locateSingleMember(
          covariant ComputableAbstractValue receiver, Selector selector) =>
      _wrappedDomain.locateSingleMember(_unwrap(receiver), selector);

  @override
  AbstractBool isJsIndexable(covariant ComputableAbstractValue value) =>
      _wrappedDomain.isJsIndexable(_unwrap(value));

  @override
  AbstractBool isJsIndexableAndIterable(
          covariant ComputableAbstractValue value) =>
      _wrappedDomain.isJsIndexableAndIterable(_unwrap(value));

  @override
  AbstractBool isFixedLengthJsIndexable(
          covariant ComputableAbstractValue value) =>
      _wrappedDomain.isFixedLengthJsIndexable(_unwrap(value));

  @override
  Iterable<DynamicCallTarget> findRootsOfTargets(
      covariant ComputableAbstractValue receiver,
      Selector selector,
      MemberHierarchyBuilder memberHierarchyBuilder) {
    return _wrappedDomain.findRootsOfTargets(
        _unwrap(receiver), selector, memberHierarchyBuilder);
  }

  @override
  bool isInvalidRefinement(covariant ComputableAbstractValue before,
      covariant ComputableAbstractValue after) {
    return _wrappedDomain.isInvalidRefinement(_unwrap(before), _unwrap(after));
  }

  @override
  String getCompactText(covariant ComputableAbstractValue value) =>
      _wrappedDomain.getCompactText(_unwrap(value));

  @override
  AbstractValue readAbstractValueFromDataSource(DataSourceReader source) =>
      ComputableAbstractValue(
          _wrappedDomain.readAbstractValueFromDataSource(source));

  @override
  void writeAbstractValueToDataSink(
      DataSinkWriter sink, covariant ComputableAbstractValue value) {
    _wrappedDomain.writeAbstractValueToDataSink(sink, _unwrap(value));
  }
}

class ComputableAbstractValueStrategy implements AbstractValueStrategy {
  final AbstractValueStrategy _wrappedStrategy;

  const ComputableAbstractValueStrategy(this._wrappedStrategy);

  @override
  AbstractValueDomain createDomain(JClosedWorld closedWorld) =>
      ComputableAbstractValueDomain(_wrappedStrategy.createDomain(closedWorld));

  @override
  SelectorConstraintsStrategy createSelectorStrategy() =>
      ComputableSelectorStrategy(_wrappedStrategy.createSelectorStrategy());
}

class ComputableSelectorStrategy implements SelectorConstraintsStrategy {
  final SelectorConstraintsStrategy _wrappedStrategy;

  const ComputableSelectorStrategy(this._wrappedStrategy);

  // There should be no uncomputed values at this point, so throw instead of
  // requiring a domain.
  AbstractValue? _unwrap(ComputableAbstractValue? value) =>
      value?._unwrapOrThrow();

  @override
  UniverseSelectorConstraints createSelectorConstraints(
          Selector selector, Object? initialConstraint) =>
      ComputableUniverseSelectorConstraints(
          _wrappedStrategy.createSelectorConstraints(
              selector, _unwrap(initialConstraint as ComputableAbstractValue)));

  @override
  bool appliedUnnamed(DynamicUse dynamicUse, MemberEntity member,
          covariant JClosedWorld world) =>
      _wrappedStrategy.appliedUnnamed(
          dynamicUse.withReceiverConstraint(_unwrap(
              dynamicUse.receiverConstraint as ComputableAbstractValue)),
          member,
          world);
}

class ComputableUniverseSelectorConstraints
    implements UniverseSelectorConstraints {
  final UniverseSelectorConstraints _universeSelectorConstraints;

  const ComputableUniverseSelectorConstraints(
      this._universeSelectorConstraints);

  // There should be no uncomputed values at this point, so throw instead of
  // requiring a domain.
  AbstractValue? _unwrap(ComputableAbstractValue? value) =>
      value?._unwrapOrThrow();

  @override
  bool addReceiverConstraint(covariant ComputableAbstractValue constraint) =>
      _universeSelectorConstraints.addReceiverConstraint(_unwrap(constraint));

  @override
  bool needsNoSuchMethodHandling(Selector selector, World world) =>
      _universeSelectorConstraints.needsNoSuchMethodHandling(selector, world);

  @override
  bool canHit(MemberEntity element, Name name, World world) =>
      _universeSelectorConstraints.canHit(element, name, world);

  @override
  String toString() => 'ComputableUniverseSelectorConstraints:$hashCode';
}
