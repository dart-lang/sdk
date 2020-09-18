// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.abstract_value_domain;

import '../constants/values.dart' show ConstantValue, PrimitiveConstantValue;
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/types.dart' show DartType;
import '../ir/static_type.dart';
import '../serialization/serialization.dart';
import '../universe/selector.dart';
import '../universe/world_builder.dart';
import '../world.dart';

/// Enum-like values used for reporting known and unknown truth values.
class AbstractBool {
  final bool _value;

  const AbstractBool._(this._value);

  bool get isDefinitelyTrue => _value == true;

  bool get isPotentiallyTrue => _value != false;

  bool get isDefinitelyFalse => _value == false;

  bool get isPotentiallyFalse => _value != true;

  /// A value of `Abstract.True` is used when the property is known _always_ to
  /// be true.
  static const AbstractBool True = const AbstractBool._(true);

  /// A value of `Abstract.False` is used when the property is known _never_ to
  /// be true.
  static const AbstractBool False = const AbstractBool._(false);

  /// A value of `Abstract.Maybe` is used when the property might or might not
  /// be true.
  static const AbstractBool Maybe = const AbstractBool._(null);

  static AbstractBool trueOrMaybe(bool value) => value ? True : Maybe;

  static AbstractBool trueOrFalse(bool value) => value ? True : False;

  static AbstractBool maybeOrFalse(bool value) => value ? Maybe : False;

  static AbstractBool strengthen(AbstractBool a, AbstractBool b) {
    //TODO(coam): Assert arguments a and b are consistent
    return a.isDefinitelyTrue ? True : (a.isDefinitelyFalse ? False : b);
  }

  AbstractBool operator &(AbstractBool other) {
    if (isDefinitelyTrue) return other;
    if (other.isDefinitelyTrue) return this;
    if (isDefinitelyFalse || other.isDefinitelyFalse) return False;
    return Maybe;
  }

  AbstractBool operator |(AbstractBool other) {
    if (isDefinitelyFalse) return other;
    if (other.isDefinitelyFalse) return this;
    if (isDefinitelyTrue || other.isDefinitelyTrue) return True;
    return Maybe;
  }

  AbstractBool operator ~() {
    if (isDefinitelyTrue) return AbstractBool.False;
    if (isDefinitelyFalse) return AbstractBool.True;
    return AbstractBool.Maybe;
  }

  @override
  String toString() =>
      'AbstractBool.${_value == null ? 'Maybe' : (_value ? 'True' : 'False')}';
}

/// Strategy for the abstraction of runtime values used by the global type
/// inference.
abstract class AbstractValueStrategy {
  /// Creates the abstract value domain for [closedWorld].
  AbstractValueDomain createDomain(JClosedWorld closedWorld);

  /// Creates the [SelectorConstraintsStrategy] used by the backend enqueuer.
  SelectorConstraintsStrategy createSelectorStrategy();
}

/// A value in an abstraction of runtime values.
abstract class AbstractValue {}

/// A pair of an AbstractValue and a precision flag. See
/// [AbstractValueDomain.createFromStaticType] for semantics of [isPrecise].
class AbstractValueWithPrecision {
  final AbstractValue abstractValue;
  final bool isPrecise;

  const AbstractValueWithPrecision(this.abstractValue, this.isPrecise);

  @override
  String toString() =>
      'AbstractValueWithPrecision($abstractValue, isPrecise: $isPrecise)';
}

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

  /// The [AbstractValue] that represents a non-null subtype of `Set` at
  /// runtime.
  AbstractValue get setType;

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

  /// The [AbstractValue] that represents the union of [growableListType] and
  /// [fixedListType], i.e. JavaScript arrays that may have their elements
  /// assigned.
  AbstractValue get mutableArrayType;

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

  /// The [AbstractValue] that represents a non-null constant set literal at
  /// runtime.
  AbstractValue get constSetType;

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

  /// Returns an [AbstractValue] and a precision flag.
  ///
  /// Creates an [AbstractValue] corresponding to an expression of the given
  /// static [type] and [classRelation], and an `isPrecise` flag that is `true`
  /// if the [AbstractValue] precisely represents the [type], or `false` if the
  /// [AbstractValue] is an approximation.
  ///
  /// If `isPrecise` is `true`, then the abstract value is equivalent to [type].
  ///
  /// If `isPrecise` is `false` then the abstract value contains all types in
  /// [type] but might contain more. Two different Dart types can have the same
  /// approximation, so care must be taken not to make subtype judgements from
  /// imprecise abstract values.
  ///
  /// The type `T` where `T` is a type parameter would be modelled by an
  /// imprecise abstract value type since we don't know how `T` is
  /// instantiated. It might be approximated by the bound of `T`.  `List<T>`
  /// where `T` is a type parameter would be modelled as imprecise for the same
  /// reason.
  ///
  /// If the abstract value domain does not track generic type parameters (e.g.
  /// the current implementation of type-masks), then `List<int>` would need to
  /// be modelled by an imprecise abstract value. `List<dynamic>` might be the
  /// imprecise approximation.
  ///
  /// In the context of a run-time type check, an imprecise abstract value can
  /// be used to compute an output type by narrowing the input type, but only a
  /// precise abstract value could be used to remove the check on the basis of
  /// the input's abstract type. The check can only be removed with additional
  /// reasoning, for example, that a dominating check uses the same type
  /// expression.
  ///
  /// [nullable] determines if the type in weak or legacy mode should be
  /// interpreted as nullable. This is passed as `false` for is-tests and `true`
  /// for as-checks and other contexts (e.g. parameter checks).
  AbstractValueWithPrecision createFromStaticType(DartType type,
      {ClassRelation classRelation = ClassRelation.subtype, bool nullable});

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

  /// Returns an [AbstractBool] that describes whether [value] is a native typed
  /// array or `null` at runtime.
  AbstractBool isTypedArray(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] could be a native
  /// typed array at runtime.
  AbstractBool couldBeTypedArray(covariant AbstractValue value);

  /// Returns the version of the abstract [value] that excludes `null`.
  AbstractValue excludeNull(covariant AbstractValue value);

  /// Returns the version of the abstract [value] that includes `null`.
  AbstractValue includeNull(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] contains
  /// instances of [cls] at runtime.
  AbstractBool containsType(covariant AbstractValue value, ClassEntity cls);

  /// Returns an [AbstractBool] that describes whether [value] only contains
  /// subtypes of [cls] or `null` at runtime.
  AbstractBool containsOnlyType(covariant AbstractValue value, ClassEntity cls);

  /// Returns an [AbstractBool] that describes whether [value] is an instance of
  /// [cls] or `null` at runtime.
  // TODO(johnniwinther): Merge this with [isInstanceOf].
  AbstractBool isInstanceOfOrNull(
      covariant AbstractValue value, ClassEntity cls);

  /// Returns an [AbstractBool] that describes whether [value] is known to be an
  /// instance of [cls] at runtime.
  AbstractBool isInstanceOf(AbstractValue value, ClassEntity cls);

  /// Returns an [AbstractBool] that describes whether [value] is empty set of
  /// runtime values.
  AbstractBool isEmpty(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is a non-null
  /// exact class at runtime.
  AbstractBool isExact(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is an exact class
  /// or `null` at runtime.
  AbstractBool isExactOrNull(covariant AbstractValue value);

  /// Returns the [ClassEntity] if this [value] is a non-null instance of an
  /// exact class at runtime, and `null` otherwise.
  ClassEntity getExactClass(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is `null` at
  /// runtime.
  AbstractBool isNull(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is a JavaScript
  /// bool, number, string, array or `null` at runtime.
  AbstractBool isPrimitive(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is a JavaScript
  /// number at runtime.
  AbstractBool isPrimitiveNumber(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is a JavaScript
  /// bool at runtime.
  AbstractBool isPrimitiveBoolean(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is a JavaScript
  /// array at runtime.
  AbstractBool isPrimitiveArray(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is a JavaScript
  /// string, array, native HTML list or `null` at runtime.
  AbstractBool isIndexablePrimitive(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is a fixed-size
  /// or constant JavaScript array or `null` at runtime.
  AbstractBool isFixedArray(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is a growable
  /// JavaScript array or `null` at runtime.
  AbstractBool isExtendableArray(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is a mutable
  /// JavaScript array or `null` at runtime.
  AbstractBool isMutableArray(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is a mutable
  /// JavaScript array, native HTML list or `null` at runtime.
  AbstractBool isMutableIndexable(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is a JavaScript
  /// array or `null` at runtime.
  AbstractBool isArray(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is a JavaScript
  /// string at runtime.
  AbstractBool isPrimitiveString(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is an interceptor
  /// at runtime.
  AbstractBool isInterceptor(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is a non-null
  /// integer value at runtime.
  AbstractBool isInteger(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is a non-null 32
  /// bit unsigned integer value at runtime.
  AbstractBool isUInt32(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is a non-null 31
  /// bit unsigned integer value at runtime.
  AbstractBool isUInt31(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is a non-null
  /// unsigned integer value at runtime.
  AbstractBool isPositiveInteger(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is an unsigned
  /// integer value or `null` at runtime.
  AbstractBool isPositiveIntegerOrNull(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is an integer
  /// value or `null` at runtime.
  AbstractBool isIntegerOrNull(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is a non-null
  /// JavaScript number at runtime.
  AbstractBool isNumber(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is a JavaScript
  /// number or `null` at runtime.
  AbstractBool isNumberOrNull(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is a non-integer
  /// number at runtime.
  AbstractBool isDouble(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is a non-integer
  /// number or `null` at runtime.
  AbstractBool isDoubleOrNull(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is a JavaScript
  /// bool at runtime.
  AbstractBool isBoolean(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is a JavaScript
  /// bool or `null` at runtime.
  AbstractBool isBooleanOrNull(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is a JavaScript
  /// string at runtime.
  AbstractBool isString(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] is a JavaScript
  /// string or `null` at runtime.
  AbstractBool isStringOrNull(covariant AbstractValue value);

  /// Returns an [AbstractBool] that describes whether [value] a JavaScript
  /// primitive, possible `null`.
  AbstractBool isPrimitiveOrNull(covariant AbstractValue value);

  /// Return an [AbstractBool] that describes whether [value] is a JavaScript
  /// 'truthy' value at runtime. This is effectively symbolically evaluating the
  /// abstract value as a JavaScript condition.
  AbstractBool isTruthy(covariant AbstractValue value);

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

  /// Returns an [AbstractBool] that describes whether [a] and [b] have no
  /// runtime values in common.
  AbstractBool areDisjoint(
      covariant AbstractValue a, covariant AbstractValue b);

  /// Returns an [AbstractBool] that describes whether [a] contains all non-null
  /// runtime values.
  AbstractBool containsAll(covariant AbstractValue a);

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

  /// Returns `true` if [value] represents a set value at runtime.
  bool isSet(covariant AbstractValue value);

  /// Creates a set value specialization of [originalValue] with the inferred
  /// [elementType] runtime value.
  ///
  /// The [allocationNode] is used to identify this particular set allocation.
  /// The [allocationElement] is used only for debugging.
  AbstractValue createSetValue(
      AbstractValue originalValue,
      Object allocationNode,
      MemberEntity allocationElement,
      AbstractValue elementType);

  /// Returns the element type of [value] if it represents a set value at
  /// runtime. Returns [dynamicType] otherwise.
  AbstractValue getSetElementType(AbstractValue value);

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

  /// Returns an [AbstractBool] that describes whether [member] is a potential
  /// target when being invoked on a [receiver]. [name] is used to ensure
  /// library privacy is taken into account.
  AbstractBool isTargetingMember(
      AbstractValue receiver, MemberEntity member, Name name);

  /// Returns an [AbstractBool] that describes whether [selector] invoked on a
  /// [receiver] can hit a [noSuchMethod].
  AbstractBool needsNoSuchMethodHandling(
      AbstractValue receiver, Selector selector);

  /// Returns the [AbstractValue] for the [parameterType] of a native
  /// method. May return `null`, for example, if [parameterType] is not modelled
  /// precisely by an [AbstractValue].
  AbstractValue getAbstractValueForNativeMethodParameterType(DartType type);

  /// Returns an [AbstractBool] that describes if the set of runtime values of
  /// [subset] are known to all be in the set of runtime values of [superset].
  AbstractBool isIn(AbstractValue subset, AbstractValue superset);

  /// Returns the [MemberEntity] that is known to always be hit at runtime
  /// [receiver].
  ///
  /// Returns `null` if 0 or more than 1 member can be hit at runtime.
  MemberEntity locateSingleMember(AbstractValue receiver, Selector selector);

  /// Returns an [AbstractBool] that describes if [value] is known to be an
  /// indexable JavaScript value at runtime.
  AbstractBool isJsIndexable(covariant AbstractValue value);

  /// RReturns an [AbstractBool] that describes if [value] is known to be an
  /// indexable or iterable JavaScript value at runtime.
  ///
  /// JavaScript arrays are both indexable and iterable whereas JavaScript
  /// strings are indexable but not iterable.
  AbstractBool isJsIndexableAndIterable(AbstractValue value);

  /// Returns an [AbstractBool] that describes if [value] is known to be a
  /// JavaScript indexable of fixed length.
  AbstractBool isFixedLengthJsIndexable(AbstractValue value);

  /// Returns compact a textual representation for [value] used for debugging.
  String getCompactText(AbstractValue value);

  /// Deserializes an [AbstractValue] for this domain from [source].
  AbstractValue readAbstractValueFromDataSource(DataSource source);

  /// Serializes this [value] for this domain to [sink].
  void writeAbstractValueToDataSink(DataSink sink, AbstractValue value);
}
