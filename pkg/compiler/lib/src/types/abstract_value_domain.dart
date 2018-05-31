// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.abstract_value_domain;

import '../constants/values.dart' show ConstantValue, PrimitiveConstantValue;
import '../elements/entities.dart';
import '../universe/selector.dart';

enum AbstractBool { True, False, Maybe }

/// A value in an abstraction of runtime values.
abstract class AbstractValue {}

/// A system that implements an abstraction over runtime values.
abstract class AbstractValueDomain {
  /// The [AbstractValue] that represents an unknown runtime value.
  AbstractValue get dynamicType;

  /// The [AbstractValue] that represents a non-null subtype of `Type` at
  /// runtime.
  AbstractValue get typeType;

  /// The [AbstractValue] that represents a non-null subtype of `Function` at
  /// runtime.
  AbstractValue get functionType;

  /// The [AbstractValue] that represents a non-null subtype of `bool` at
  /// runtime.
  AbstractValue get boolType;

  /// The [AbstractValue] that represents a non-null subtype of `int` at
  /// runtime.
  AbstractValue get intType;

  /// The [AbstractValue] that represents a non-null subtype of `double` at
  /// runtime.
  AbstractValue get doubleType;

  /// The [AbstractValue] that represents a non-null subtype of `num` at
  /// runtime.
  AbstractValue get numType;

  /// The [AbstractValue] that represents a non-null subtype of `String` at
  /// runtime.
  AbstractValue get stringType;

  /// The [AbstractValue] that represents a non-null subtype of `List` at
  /// runtime.
  AbstractValue get listType;

  /// The [AbstractValue] that represents a non-null subtype of `Map` at
  /// runtime.
  AbstractValue get mapType;

  /// The [AbstractValue] that represents a non-null value at runtime.
  AbstractValue get nonNullType;

  /// The [AbstractValue] that represents the `null` at runtime.
  AbstractValue get nullType;

  /// The [AbstractValue] that represents a non-null growable JavaScript array
  /// at runtime.
  AbstractValue get growableListType;

  /// The [AbstractValue] that represents a non-null fixed size JavaScript array
  /// at runtime.
  AbstractValue get fixedListType;

  /// The [AbstractValue] that represents a non-null 31-bit unsigned integer at
  /// runtime.
  AbstractValue get uint31Type;

  /// The [AbstractValue] that represents a non-null 32-bit unsigned integer at
  /// runtime.
  AbstractValue get uint32Type;

  /// The [AbstractValue] that represents a non-null unsigned integer at
  /// runtime.
  AbstractValue get positiveIntType;

  /// The [AbstractValue] that represents a non-null constant list literal at
  /// runtime.
  AbstractValue get constListType;

  /// The [AbstractValue] that represents a non-null constant map literal at
  /// runtime.
  AbstractValue get constMapType;

  /// The [AbstractValue] that represents the empty set of runtime values.
  AbstractValue get emptyType;

  /// The [AbstractValue] that represents a non-null instance at runtime of the
  /// `Iterable` class used for the `sync*` implementation.
  AbstractValue get syncStarIterableType;

  /// The [AbstractValue] that represents a non-null instance at runtime of the
  /// `Future` class used for the `async` implementation.
  AbstractValue get asyncFutureType;

  /// The [AbstractValue] that represents a non-null instance at runtime of the
  /// `Stream` class used for the `async*` implementation.
  AbstractValue get asyncStarStreamType;

  /// Creates an [AbstractValue] for a non-null exact instance of [cls].
  AbstractValue createNonNullExact(ClassEntity cls);

  /// Creates an [AbstractValue] for a potentially null exact instance of [cls].
  AbstractValue createNullableExact(ClassEntity cls);

  /// Creates an [AbstractValue] for a non-null instance that extends [cls].
  AbstractValue createNonNullSubclass(ClassEntity cls);

  /// Creates an [AbstractValue] for a non-null instance that implements [cls].
  AbstractValue createNonNullSubtype(ClassEntity cls);

  /// Creates an [AbstractValue] for a potentially null instance that implements
  /// [cls].
  AbstractValue createNullableSubtype(ClassEntity cls);

  /// Returns `true` if [value] is a native typed array or `null` at runtime.
  bool isTypedArray(covariant AbstractValue value);

  /// Returns `true` if [value] could be a native typed array at runtime.
  bool couldBeTypedArray(covariant AbstractValue value);

  /// Returns the version of the abstract [value] that excludes `null`.
  AbstractValue excludeNull(covariant AbstractValue value);

  /// Returns the version of the abstract [value] that includes `null`.
  AbstractValue includeNull(covariant AbstractValue value);

  /// Returns `true` if [value] contains instances of [cls] at runtime.
  bool containsType(covariant AbstractValue value, ClassEntity cls);

  /// Returns `true` if [value] only contains subtypes of [cls] or `null` at
  /// runtime.
  bool containsOnlyType(covariant AbstractValue value, ClassEntity cls);

  /// Returns `true` if [value] is an instance of [cls] or `null` at runtime.
  // TODO(johnniwinther): Merge this with [isInstanceOf].
  bool isInstanceOfOrNull(covariant AbstractValue value, ClassEntity cls);

  /// Returns an [AbstractBool] that describes how [value] is known to be an
  /// instance of [cls] at runtime.
  ///
  /// If the returned value is `Abstract.True`, [value] is known _always_ to be
  /// an instance of [cls]. If the returned value is `Abstract.False`, [value]
  /// is known _never_ to be an instance of [cls]. If the returned value is
  /// `Abstract.Maybe` [value] might or might not be an instance of [cls] at
  /// runtime.
  AbstractBool isInstanceOf(AbstractValue value, ClassEntity cls);

  /// Returns `true` if [value] is empty set of runtime values.
  bool isEmpty(covariant AbstractValue value);

  /// Returns `true` if [value] is a non-null exact class at runtime.
  bool isExact(covariant AbstractValue value);

  /// Returns `true` if [value] is an exact class or `null` at runtime.
  bool isExactOrNull(covariant AbstractValue value);

  /// Returns the [ClassEntity] if this [value] is a non-null instance of an
  /// exact class at runtime, and `null` otherwise.
  ClassEntity getExactClass(covariant AbstractValue value);

  /// Returns `true` if [value] can be `null` at runtime.
  bool canBeNull(covariant AbstractValue value);

  /// Returns `true` if [value] is `null` at runtime.
  bool isNull(covariant AbstractValue value);

  /// Returns `true` if [value] could be a JavaScript bool, number, string,
  /// array or `null` at runtime.
  bool canBePrimitive(covariant AbstractValue value);

  /// Returns `true` if [value] could be a JavaScript number at runtime.
  bool canBePrimitiveNumber(covariant AbstractValue value);

  /// Returns `true` if [value] could be a JavaScript bool at runtime.
  bool canBePrimitiveBoolean(covariant AbstractValue value);

  /// Returns `true` if [value] could be a JavaScript array at runtime.
  bool canBePrimitiveArray(covariant AbstractValue value);

  /// Returns `true` if [value] is a JavaScript string, array, native HTML list
  /// or `null` at runtime.
  bool isIndexablePrimitive(covariant AbstractValue value);

  /// Returns `true` if [value] is a fixed-size or constant JavaScript array or
  /// `null` at
  /// runtime.
  bool isFixedArray(covariant AbstractValue value);

  /// Returns `true` if [value] is a growable JavaScript array or `null` at
  /// runtime.
  bool isExtendableArray(covariant AbstractValue value);

  /// Returns `true` if [value] is a mutable JavaScript array or `null` at
  /// runtime.
  bool isMutableArray(covariant AbstractValue value);

  /// Returns `true` if [value] is a mutable JavaScript array, native HTML list
  /// or `null` at runtime.
  bool isMutableIndexable(covariant AbstractValue value);

  /// Returns `true` if [value] is a JavaScript array or `null` at runtime.
  bool isArray(covariant AbstractValue value);

  /// Returns `true` if [value] could be a JavaScript string at runtime.
  bool canBePrimitiveString(covariant AbstractValue value);

  /// Return `true` if [value] could be an interceptor at runtime.
  bool canBeInterceptor(covariant AbstractValue value);

  /// Returns `true` if [value] is a non-null integer value at runtime.
  bool isInteger(covariant AbstractValue value);

  /// Returns `true` if [value] is a non-null 32 bit unsigned integer value at
  /// runtime.
  bool isUInt32(covariant AbstractValue value);

  /// Returns `true` if [value] is a non-null 31 bit unsigned integer value at
  /// runtime.
  bool isUInt31(covariant AbstractValue value);

  /// Returns `true` if [value] is a non-null unsigned integer value at runtime.
  bool isPositiveInteger(covariant AbstractValue value);

  /// Returns `true` if [value] is an unsigned integer value or `null` at
  /// runtime.
  bool isPositiveIntegerOrNull(covariant AbstractValue value);

  /// Returns `true` if [value] is an integer value or `null` at runtime.
  bool isIntegerOrNull(covariant AbstractValue value);

  /// Returns `true` if [value] is a non-null JavaScript number at runtime.
  bool isNumber(covariant AbstractValue value);

  /// Returns `true` if [value] is a JavaScript number or `null` at runtime.
  bool isNumberOrNull(covariant AbstractValue value);

  /// Returns `true` if [value] is a non-integer number at runtime.
  bool isDouble(covariant AbstractValue value);

  /// Returns `true` if [value] is a non-integer number or `null` at runtime.
  bool isDoubleOrNull(covariant AbstractValue value);

  /// Returns `true` if [value] is a JavaScript bool at runtime.
  bool isBoolean(covariant AbstractValue value);

  /// Returns `true` if [value] is a JavaScript bool or `null` at runtime.
  bool isBooleanOrNull(covariant AbstractValue value);

  /// Returns `true` if [value] is a JavaScript string at runtime.
  bool isString(covariant AbstractValue value);

  /// Returns `true` if [value] is a JavaScript string or `null` at runtime.
  bool isStringOrNull(covariant AbstractValue value);

  /// Returns `true` if [value] a non-null JavaScript primitive or `null`?
  // TODO(johnniwinther): This should probably not return true on `null`,
  // investigate.
  bool isPrimitive(covariant AbstractValue value);

  /// Returns `true` if [value] a JavaScript primitive, possible `null`.
  bool isPrimitiveOrNull(covariant AbstractValue value);

  /// Returns [AbstractValue] for the runtime values contained in either [a] or
  /// [b].
  AbstractValue union(covariant AbstractValue a, covariant AbstractValue b);

  /// Returns [AbstractValue] for the runtime values contained in at least one
  /// of [values].
  AbstractValue unionOfMany(Iterable<AbstractValue> values);

  /// Returns [AbstractValue] for the runtime values that [a] and [b] have in
  /// common.
  AbstractValue intersection(
      covariant AbstractValue a, covariant AbstractValue b);

  /// Returns `true` if [a] and [b] have no runtime values in common.
  bool areDisjoint(covariant AbstractValue a, covariant AbstractValue b);

  /// Returns `true` if [a] contains all non-null runtime values.
  bool containsAll(covariant AbstractValue a);

  /// Computes the [AbstractValue] corresponding to the constant [value].
  AbstractValue computeAbstractValueForConstant(ConstantValue value);

  /// Returns `true` if [value] represents a container value at runtime.
  bool isContainer(covariant AbstractValue value);

  /// Creates a container value specialization of [originalValue] with the
  /// inferred [element] runtime value and inferred runtime [length].
  ///
  /// The [allocationNode] is used to identify this particular map allocation.
  /// The [allocationElement] is used only for debugging.
  AbstractValue createContainerValue(
      AbstractValue originalValue,
      Object allocationNode,
      MemberEntity allocationElement,
      AbstractValue elementType,
      int length);

  /// Returns the element type of [value] if it represents a container value
  /// at runtime. Returns [dynamicType] otherwise.
  AbstractValue getContainerElementType(AbstractValue value);

  /// Return the known length of [value] if it represents a container value
  /// at runtime. Returns `null` if the length is unknown or if [value] doesn't
  /// represent a container value at runtime.
  int getContainerLength(AbstractValue value);

  /// Returns `true` if [value] represents a map value at runtime.
  bool isMap(covariant AbstractValue value);

  /// Creates a map value specialization of [originalValue] with the inferred
  /// [key] and [value] runtime values.
  ///
  /// The [allocationNode] is used to identify this particular map allocation.
  /// The [allocationElement] is used only for debugging.
  AbstractValue createMapValue(
      AbstractValue originalValue,
      Object allocationNode,
      MemberEntity allocationElement,
      AbstractValue key,
      AbstractValue value);

  /// Returns the key type of [value] if it represents a map value at runtime.
  /// Returns [dynamicType] otherwise.
  AbstractValue getMapKeyType(AbstractValue value);

  /// Returns the value type of [value] if it represents a map value at runtime.
  /// Returns [dynamicType] otherwise.
  AbstractValue getMapValueType(AbstractValue value);

  /// Returns `true` if [value] represents a dictionary value, that is, a map
  /// with strings as keys, at runtime.
  bool isDictionary(covariant AbstractValue value);

  /// Creates a dictionary value specialization of [originalValue] with the
  /// inferred [key] and [value] runtime values.
  ///
  /// The [allocationNode] is used to identify this particular map allocation.
  /// The [allocationElement] is used only for debugging.
  AbstractValue createDictionaryValue(
      AbstractValue originalValue,
      Object allocationNode,
      MemberEntity allocationElement,
      AbstractValue key,
      AbstractValue value,
      Map<String, AbstractValue> mappings);

  /// Returns `true` if [value] is a dictionary value which contains [key] as
  /// a key.
  bool containsDictionaryKey(AbstractValue value, String key);

  /// Returns the value type for [key] in [value] if it represents a dictionary
  /// value at runtime. Returns [dynamicType] otherwise.
  AbstractValue getDictionaryValueForKey(AbstractValue value, String key);

  /// Returns `true` if [specialization] is a specialization of
  /// [generalization].
  ///
  /// Specializations are created through [createPrimitiveValue],
  /// [createMapValue], [createDictionaryValue] and [createContainerValue].
  bool isSpecializationOf(
      AbstractValue specialization, AbstractValue generalization);

  /// Returns the value of which [value] is a specialization. Return `null` if
  /// [value] is not a specialization.
  ///
  /// Specializations are created through [createPrimitiveValue],
  /// [createMapValue], [createDictionaryValue] and [createContainerValue].
  AbstractValue getGeneralization(AbstractValue value);

  /// Return the object identifying the allocation of [value] if it is an
  /// allocation based specialization. Otherwise returns `null`.
  ///
  /// Allocation based specializations are created through [createMapValue],
  /// [createDictionaryValue] and [createContainerValue]
  Object getAllocationNode(AbstractValue value);

  /// Return the allocation element of [value] if it is an allocation based
  /// specialization. Otherwise returns `null`.
  ///
  /// Allocation based specializations are created through [createMapValue],
  /// [createDictionaryValue] and [createContainerValue]
  MemberEntity getAllocationElement(AbstractValue value);

  /// Returns `true` if [value] a known primitive JavaScript value at runtime.
  bool isPrimitiveValue(covariant AbstractValue value);

  /// Creates a primitive value specialization of [originalValue] with the
  /// inferred primitive constant [value].
  AbstractValue createPrimitiveValue(
      AbstractValue originalValue, PrimitiveConstantValue value);

  /// Returns the primitive JavaScript value of [value] if it represents a
  /// primitive JavaScript value at runtime, value at runtime. Returns `null`
  /// otherwise.
  PrimitiveConstantValue getPrimitiveValue(covariant AbstractValue value);

  /// Compute the type of all potential receivers of the set of live [members].
  AbstractValue computeReceiver(Iterable<MemberEntity> members);

  /// Returns whether [member] is a potential target when being
  /// invoked on a [receiver]. [selector] is used to ensure library privacy is
  /// taken into account.
  bool canHit(AbstractValue receiver, MemberEntity member, Selector selector);

  /// Returns whether [selector] invoked on a [receiver] can hit a
  /// [noSuchMethod].
  bool needsNoSuchMethodHandling(AbstractValue receiver, Selector selector);

  /// Returns `true` if the set of runtime values of [subset] are all in the set
  /// of runtime values of [superset].
  bool contains(AbstractValue superset, AbstractValue subset);

  /// Returns `true` if the set of runtime values of [subset] are all in the set
  /// of runtime values of [superset].
  bool isIn(AbstractValue subset, AbstractValue superset);

  /// Returns the [MemberEntity] that is known to always be hit at runtime
  /// [receiver].
  ///
  /// Returns `null` if 0 or more than 1 member can be hit at runtime.
  MemberEntity locateSingleMember(AbstractValue receiver, Selector selector);

  /// Returns `true` if [value] is an indexable JavaScript value at runtime.
  bool isJsIndexable(covariant AbstractValue value);

  /// Returns `true` if [value] is an indexable and iterable JavaScript value at
  /// runtime.
  ///
  /// JavaScript arrays are both indexable and iterable whereas JavaScript
  /// strings are indexable but not iterable.
  bool isJsIndexableAndIterable(AbstractValue value);

  /// Returns `true` if [value] is an JavaScript indexable of fixed length.
  bool isFixedLengthJsIndexable(AbstractValue value);

  /// Returns compact a textual representation for [value] used for debugging.
  String getCompactText(AbstractValue value);
}
