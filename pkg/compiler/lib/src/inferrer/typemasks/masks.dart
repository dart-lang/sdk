// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library masks;

import '../../common.dart';
import '../../common_elements.dart' show CommonElements;
import '../../constants/values.dart' show ConstantValue, PrimitiveConstantValue;
import '../../elements/entities.dart';
import '../../types/abstract_value_domain.dart';
import '../../universe/selector.dart' show Selector;
import '../../universe/use.dart' show DynamicUse;
import '../../universe/world_builder.dart'
    show UniverseSelectorConstraints, SelectorConstraintsStrategy;
import '../../util/util.dart';
import '../../world.dart' show ClassQuery, ClosedWorld;
import '../type_graph_inferrer.dart' show TypeGraphInferrer;
import 'constants.dart';

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
  TypeMask _unmodifiableArrayType;
  TypeMask _interceptorType;

  /// Cache of [FlatTypeMask]s grouped by the 8 possible values of the
  /// `FlatTypeMask.flags` property.
  final List<Map<ClassEntity, TypeMask>> _canonicalizedTypeMasks =
      new List<Map<ClassEntity, TypeMask>>.filled(8, null);

  /// Return the cached mask for [base] with the given flags, or
  /// calls [createMask] to create the mask and cache it.
  TypeMask getCachedMask(ClassEntity base, int flags, TypeMask createMask()) {
    Map<ClassEntity, TypeMask> cachedMasks =
        _canonicalizedTypeMasks[flags] ??= <ClassEntity, TypeMask>{};
    return cachedMasks.putIfAbsent(base, createMask);
  }

  @override
  TypeMask get dynamicType => _dynamicType ??= new TypeMask.subclass(
      _closedWorld.commonElements.objectClass, _closedWorld);

  @override
  TypeMask get nonNullType => _nonNullType ??= new TypeMask.nonNullSubclass(
      _closedWorld.commonElements.objectClass, _closedWorld);

  @override
  TypeMask get intType => _intType ??=
      new TypeMask.nonNullSubclass(commonElements.jsIntClass, _closedWorld);

  @override
  TypeMask get uint32Type => _uint32Type ??=
      new TypeMask.nonNullSubclass(commonElements.jsUInt32Class, _closedWorld);

  @override
  TypeMask get uint31Type => _uint31Type ??=
      new TypeMask.nonNullExact(commonElements.jsUInt31Class, _closedWorld);

  @override
  TypeMask get positiveIntType =>
      _positiveIntType ??= new TypeMask.nonNullSubclass(
          commonElements.jsPositiveIntClass, _closedWorld);

  @override
  TypeMask get doubleType => _doubleType ??=
      new TypeMask.nonNullExact(commonElements.jsDoubleClass, _closedWorld);

  @override
  TypeMask get numType => _numType ??=
      new TypeMask.nonNullSubclass(commonElements.jsNumberClass, _closedWorld);

  @override
  TypeMask get boolType => _boolType ??=
      new TypeMask.nonNullExact(commonElements.jsBoolClass, _closedWorld);

  @override
  TypeMask get functionType => _functionType ??=
      new TypeMask.nonNullSubtype(commonElements.functionClass, _closedWorld);

  @override
  TypeMask get listType => _listType ??=
      new TypeMask.nonNullExact(commonElements.jsArrayClass, _closedWorld);

  @override
  TypeMask get constListType => _constListType ??= new TypeMask.nonNullExact(
      commonElements.jsUnmodifiableArrayClass, _closedWorld);

  @override
  TypeMask get fixedListType => _fixedListType ??=
      new TypeMask.nonNullExact(commonElements.jsFixedArrayClass, _closedWorld);

  @override
  TypeMask get growableListType =>
      _growableListType ??= new TypeMask.nonNullExact(
          commonElements.jsExtendableArrayClass, _closedWorld);

  @override
  TypeMask get mapType => _mapType ??=
      new TypeMask.nonNullSubtype(commonElements.mapLiteralClass, _closedWorld);

  @override
  TypeMask get constMapType => _constMapType ??= new TypeMask.nonNullSubtype(
      commonElements.constMapLiteralClass, _closedWorld);

  @override
  TypeMask get stringType => _stringType ??=
      new TypeMask.nonNullExact(commonElements.jsStringClass, _closedWorld);

  @override
  TypeMask get typeType => _typeType ??=
      new TypeMask.nonNullExact(commonElements.typeLiteralClass, _closedWorld);

  @override
  TypeMask get syncStarIterableType => _syncStarIterableType ??=
      new TypeMask.nonNullExact(commonElements.syncStarIterable, _closedWorld);

  @override
  TypeMask get asyncFutureType =>
      _asyncFutureType ??= new TypeMask.nonNullExact(
          commonElements.futureImplementation, _closedWorld);

  @override
  TypeMask get asyncStarStreamType => _asyncStarStreamType ??=
      new TypeMask.nonNullExact(commonElements.controllerStream, _closedWorld);

  // TODO(johnniwinther): Assert that the null type has been resolved.
  @override
  TypeMask get nullType => _nullType ??= const TypeMask.empty();

  @override
  TypeMask get emptyType => const TypeMask.nonNullEmpty();

  TypeMask get indexablePrimitiveType =>
      _indexablePrimitiveType ??= new TypeMask.nonNullSubtype(
          commonElements.jsIndexableClass, _closedWorld);

  TypeMask get readableArrayType => _readableArrayType ??=
      new TypeMask.nonNullSubclass(commonElements.jsArrayClass, _closedWorld);

  TypeMask get mutableArrayType =>
      _mutableArrayType ??= new TypeMask.nonNullSubclass(
          commonElements.jsMutableArrayClass, _closedWorld);

  TypeMask get unmodifiableArrayType =>
      _unmodifiableArrayType ??= new TypeMask.nonNullExact(
          commonElements.jsUnmodifiableArrayClass, _closedWorld);

  TypeMask get interceptorType =>
      _interceptorType ??= new TypeMask.nonNullSubclass(
          commonElements.jsInterceptorClass, _closedWorld);

  @override
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

  @override
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

  @override
  TypeMask createNonNullExact(ClassEntity cls) {
    return new TypeMask.nonNullExact(cls, _closedWorld);
  }

  @override
  TypeMask createNullableExact(ClassEntity cls) {
    return new TypeMask.exact(cls, _closedWorld);
  }

  @override
  TypeMask createNonNullSubclass(ClassEntity cls) {
    return new TypeMask.nonNullSubclass(cls, _closedWorld);
  }

  @override
  TypeMask createNonNullSubtype(ClassEntity cls) {
    return new TypeMask.nonNullSubtype(cls, _closedWorld);
  }

  @override
  TypeMask createNullableSubtype(ClassEntity cls) {
    return new TypeMask.subtype(cls, _closedWorld);
  }

  @override
  TypeMask excludeNull(TypeMask mask) => mask.nonNullable();

  @override
  TypeMask includeNull(TypeMask mask) => mask.nullable();

  @override
  bool containsType(TypeMask typeMask, ClassEntity cls) {
    return _closedWorld.isInstantiated(cls) &&
        typeMask.contains(cls, _closedWorld);
  }

  @override
  bool containsOnlyType(TypeMask typeMask, ClassEntity cls) {
    return _closedWorld.isInstantiated(cls) && typeMask.containsOnly(cls);
  }

  @override
  bool isInstanceOfOrNull(TypeMask typeMask, ClassEntity cls) {
    return _closedWorld.isImplemented(cls) &&
        typeMask.satisfies(cls, _closedWorld);
  }

  @override
  AbstractBool isInstanceOf(
      covariant TypeMask expressionMask, ClassEntity cls) {
    AbstractValue typeMask = (cls == commonElements.nullClass)
        ? createNullableSubtype(cls)
        : createNonNullSubtype(cls);
    if (expressionMask.union(typeMask, _closedWorld) == typeMask) {
      return AbstractBool.True;
    } else if (expressionMask.isDisjoint(typeMask, _closedWorld)) {
      return AbstractBool.False;
    } else {
      return AbstractBool.Maybe;
    }
  }

  @override
  bool isEmpty(TypeMask value) => value.isEmpty;

  @override
  bool isExact(TypeMask value) => value.isExact && !value.isNullable;

  @override
  bool isExactOrNull(TypeMask value) => value.isExact || isNull(value);

  @override
  ClassEntity getExactClass(TypeMask mask) {
    return mask.singleClass(_closedWorld);
  }

  @override
  bool isPrimitiveValue(TypeMask value) => value.isValue;

  @override
  PrimitiveConstantValue getPrimitiveValue(TypeMask mask) {
    if (mask.isValue) {
      ValueTypeMask valueMask = mask;
      return valueMask.value;
    }
    return null;
  }

  @override
  AbstractValue createPrimitiveValue(
      covariant TypeMask originalValue, PrimitiveConstantValue value) {
    return new ValueTypeMask(originalValue, value);
  }

  @override
  bool canBeNull(TypeMask value) => value.isNullable;

  @override
  bool isNull(TypeMask value) => value.isNull;

  @override
  bool canBePrimitive(TypeMask value) {
    return canBePrimitiveNumber(value) ||
        canBePrimitiveArray(value) ||
        canBePrimitiveBoolean(value) ||
        canBePrimitiveString(value) ||
        isNull(value);
  }

  @override
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

  @override
  bool canBePrimitiveBoolean(TypeMask value) {
    return containsType(value, commonElements.jsBoolClass);
  }

  @override
  bool canBePrimitiveArray(TypeMask value) {
    return containsType(value, commonElements.jsArrayClass) ||
        containsType(value, commonElements.jsFixedArrayClass) ||
        containsType(value, commonElements.jsExtendableArrayClass) ||
        containsType(value, commonElements.jsUnmodifiableArrayClass);
  }

  @override
  bool isIndexablePrimitive(TypeMask value) {
    return value.containsOnlyString(_closedWorld) ||
        isInstanceOfOrNull(value, commonElements.jsIndexableClass);
  }

  @override
  bool isFixedArray(TypeMask value) {
    // TODO(sra): Recognize the union of these types as well.
    return containsOnlyType(value, commonElements.jsFixedArrayClass) ||
        containsOnlyType(value, commonElements.jsUnmodifiableArrayClass);
  }

  @override
  bool isExtendableArray(TypeMask value) {
    return containsOnlyType(value, commonElements.jsExtendableArrayClass);
  }

  @override
  bool isMutableArray(TypeMask value) {
    return isInstanceOfOrNull(value, commonElements.jsMutableArrayClass);
  }

  @override
  bool isMutableIndexable(TypeMask value) {
    return isInstanceOfOrNull(value, commonElements.jsMutableIndexableClass);
  }

  @override
  bool isArray(TypeMask value) {
    return isInstanceOfOrNull(value, commonElements.jsArrayClass);
  }

  @override
  bool canBePrimitiveString(TypeMask value) {
    return containsType(value, commonElements.jsStringClass);
  }

  @override
  bool isInteger(TypeMask value) {
    return value.containsOnlyInt(_closedWorld) && !value.isNullable;
  }

  @override
  bool isUInt32(TypeMask value) {
    return !value.isNullable &&
        isInstanceOfOrNull(value, commonElements.jsUInt32Class);
  }

  @override
  bool isUInt31(TypeMask value) {
    return !value.isNullable &&
        isInstanceOfOrNull(value, commonElements.jsUInt31Class);
  }

  @override
  bool isPositiveInteger(TypeMask value) {
    return !value.isNullable &&
        isInstanceOfOrNull(value, commonElements.jsPositiveIntClass);
  }

  @override
  bool isPositiveIntegerOrNull(TypeMask value) {
    return isInstanceOfOrNull(value, commonElements.jsPositiveIntClass);
  }

  @override
  bool isIntegerOrNull(TypeMask value) {
    return value.containsOnlyInt(_closedWorld);
  }

  @override
  bool isNumber(TypeMask value) {
    return value.containsOnlyNum(_closedWorld) && !value.isNullable;
  }

  @override
  bool isNumberOrNull(TypeMask value) {
    return value.containsOnlyNum(_closedWorld);
  }

  @override
  bool isDouble(TypeMask value) {
    return value.containsOnlyDouble(_closedWorld) && !value.isNullable;
  }

  @override
  bool isDoubleOrNull(TypeMask value) {
    return value.containsOnlyDouble(_closedWorld);
  }

  @override
  bool isBoolean(TypeMask value) {
    return value.containsOnlyBool(_closedWorld) && !value.isNullable;
  }

  @override
  bool isBooleanOrNull(TypeMask value) {
    return value.containsOnlyBool(_closedWorld);
  }

  @override
  bool isString(TypeMask value) {
    return value.containsOnlyString(_closedWorld) && !value.isNullable;
  }

  @override
  bool isStringOrNull(TypeMask value) {
    return value.containsOnlyString(_closedWorld);
  }

  @override
  bool isPrimitive(TypeMask value) {
    return (isPrimitiveOrNull(value) && !value.isNullable) || isNull(value);
  }

  @override
  bool isPrimitiveOrNull(TypeMask value) {
    return isIndexablePrimitive(value) ||
        isNumberOrNull(value) ||
        isBooleanOrNull(value) ||
        isNull(value);
  }

  @override
  TypeMask union(TypeMask a, TypeMask b) => a.union(b, _closedWorld);

  @override
  TypeMask intersection(TypeMask a, TypeMask b) =>
      a.intersection(b, _closedWorld);

  @override
  bool areDisjoint(TypeMask a, TypeMask b) => a.isDisjoint(b, _closedWorld);

  @override
  bool containsAll(TypeMask a) => a.containsAll(_closedWorld);

  @override
  AbstractValue computeAbstractValueForConstant(ConstantValue value) {
    return computeTypeMask(_closedWorld, value);
  }

  @override
  AbstractValue getMapKeyType(AbstractValue value) {
    if (value is MapTypeMask) {
      return value.keyType;
    }
    return dynamicType;
  }

  @override
  AbstractValue getMapValueType(AbstractValue value) {
    if (value is MapTypeMask) {
      // TODO(johnniwinther): Assert the `value.valueType` is not null.
      return value.valueType ?? dynamicType;
    }
    return dynamicType;
  }

  @override
  AbstractValue getContainerElementType(AbstractValue value) {
    if (value is ContainerTypeMask) {
      return value.elementType ?? dynamicType;
    }
    return dynamicType;
  }

  @override
  int getContainerLength(AbstractValue value) {
    return value is ContainerTypeMask ? value.length : null;
  }

  @override
  AbstractValue createContainerValue(
      AbstractValue forwardTo,
      Object allocationNode,
      MemberEntity allocationElement,
      AbstractValue elementType,
      int length) {
    return new ContainerTypeMask(
        forwardTo, allocationNode, allocationElement, elementType, length);
  }

  @override
  AbstractValue unionOfMany(Iterable<AbstractValue> values) {
    TypeMask result = const TypeMask.nonNullEmpty();
    for (TypeMask value in values) {
      result = result.union(value, _closedWorld);
    }
    return result;
  }

  @override
  AbstractValue computeReceiver(Iterable<MemberEntity> members) {
    assert(_closedWorld
        .hasAnyStrictSubclass(_closedWorld.commonElements.objectClass));
    return new TypeMask.unionOf(
        members.expand((MemberEntity element) {
          ClassEntity cls = element.enclosingClass;
          return [cls]..addAll(_closedWorld.mixinUsesOf(cls));
        }).map((cls) {
          if (_closedWorld.commonElements.jsNullClass == cls) {
            return const TypeMask.empty();
          } else if (_closedWorld.isInstantiated(cls)) {
            return new TypeMask.nonNullSubclass(cls, _closedWorld);
          } else {
            // TODO(johnniwinther): Avoid the need for this case.
            return const TypeMask.empty();
          }
        }),
        _closedWorld);
  }

  @override
  bool canHit(
      covariant TypeMask receiver, MemberEntity member, Selector selector) {
    return receiver.canHit(member, selector, _closedWorld);
  }

  @override
  bool needsNoSuchMethodHandling(
      covariant TypeMask receiver, Selector selector) {
    return receiver.needsNoSuchMethodHandling(selector, _closedWorld);
  }

  @override
  bool contains(covariant TypeMask superset, covariant TypeMask subset) {
    return superset.containsMask(subset, _closedWorld);
  }

  @override
  bool isIn(covariant TypeMask subset, covariant TypeMask superset) {
    return subset.isInMask(superset, _closedWorld);
  }

  @override
  MemberEntity locateSingleMember(
      covariant TypeMask receiver, Selector selector) {
    return receiver.locateSingleMember(selector, _closedWorld);
  }

  @override
  bool isJsIndexable(TypeMask mask) {
    return mask.satisfies(
        _closedWorld.commonElements.jsIndexableClass, _closedWorld);
  }

  @override
  bool isJsIndexableAndIterable(covariant TypeMask mask) {
    return mask != null &&
        mask.satisfies(
            _closedWorld.commonElements.jsIndexableClass, _closedWorld) &&
        // String is indexable but not iterable.
        !mask.satisfies(
            _closedWorld.commonElements.jsStringClass, _closedWorld);
  }

  @override
  bool isFixedLengthJsIndexable(covariant TypeMask mask) {
    if (mask.isContainer && (mask as ContainerTypeMask).length != null) {
      // A container on which we have inferred the length.
      return true;
    }
    // TODO(sra): Recognize any combination of fixed length indexables.
    if (mask.containsOnly(_closedWorld.commonElements.jsFixedArrayClass) ||
        mask.containsOnly(
            _closedWorld.commonElements.jsUnmodifiableArrayClass) ||
        mask.containsOnlyString(_closedWorld) ||
        _closedWorld.abstractValueDomain.isTypedArray(mask)) {
      return true;
    }
    return false;
  }

  @override
  bool canBeInterceptor(TypeMask value) {
    return !interceptorType.isDisjoint(value, _closedWorld);
  }

  @override
  bool isMap(TypeMask value) {
    return value.isMap;
  }

  @override
  bool isContainer(TypeMask value) {
    return value.isContainer;
  }

  @override
  bool isDictionary(TypeMask value) {
    return value.isDictionary;
  }

  @override
  bool containsDictionaryKey(AbstractValue value, String key) {
    return value is DictionaryTypeMask && value.containsKey(key);
  }

  @override
  AbstractValue getDictionaryValueForKey(AbstractValue value, String key) {
    if (value is DictionaryTypeMask) return value.getValueForKey(key);
    return dynamicType;
  }

  @override
  AbstractValue createMapValue(AbstractValue forwardTo, Object allocationNode,
      MemberEntity allocationElement, AbstractValue key, AbstractValue value) {
    return new MapTypeMask(
        forwardTo, allocationNode, allocationElement, key, value);
  }

  @override
  AbstractValue createDictionaryValue(
      AbstractValue forwardTo,
      Object allocationNode,
      MemberEntity allocationElement,
      AbstractValue key,
      AbstractValue value,
      Map<String, AbstractValue> mappings) {
    return new DictionaryTypeMask(
        forwardTo, allocationNode, allocationElement, key, value, mappings);
  }

  @override
  bool isSpecializationOf(
      AbstractValue specialization, AbstractValue generalization) {
    return specialization is ForwardingTypeMask &&
        specialization.forwardTo == generalization;
  }

  @override
  Object getAllocationNode(AbstractValue value) {
    if (value is AllocationTypeMask) {
      return value.allocationNode;
    }
    return null;
  }

  @override
  MemberEntity getAllocationElement(AbstractValue value) {
    if (value is AllocationTypeMask) {
      return value.allocationElement;
    }
    return null;
  }

  @override
  AbstractValue getGeneralization(AbstractValue value) {
    if (value is AllocationTypeMask) {
      return value.forwardTo;
    }
    return null;
  }

  @override
  String getCompactText(AbstractValue value) {
    return formatType(value);
  }
}

/// Convert the given TypeMask to a compact string format.
///
/// The default format is too verbose for the graph format since long strings
/// create oblong nodes that obstruct the graph layout.
String formatType(TypeMask type) {
  if (type is FlatTypeMask) {
    // TODO(asgerf): Disambiguate classes whose name is not unique. Using the
    //     library name for all classes is not a good idea, since library names
    //     can be really long and mess up the layout.
    // Capitalize Null to emphasize that it's the null type mask and not
    // a null value we accidentally printed out.
    if (type.isEmptyOrNull) return type.isNullable ? 'Null' : 'Empty';
    String nullFlag = type.isNullable ? '?' : '';
    String subFlag = type.isExact ? '' : type.isSubclass ? '+' : '*';
    return '${type.base.name}$nullFlag$subFlag';
  }
  if (type is UnionTypeMask) {
    return type.disjointMasks.map(formatType).join(' | ');
  }
  if (type is ContainerTypeMask) {
    String container = formatType(type.forwardTo);
    String member = formatType(type.elementType);
    return '$container<$member>';
  }
  if (type is MapTypeMask) {
    String container = formatType(type.forwardTo);
    String key = formatType(type.keyType);
    String value = formatType(type.valueType);
    return '$container<$key,$value>';
  }
  if (type is ValueTypeMask) {
    String baseType = formatType(type.forwardTo);
    String value = type.value.toStructuredText();
    return '$baseType=$value';
  }
  return '$type'; // Fall back on toString if not supported here.
}
