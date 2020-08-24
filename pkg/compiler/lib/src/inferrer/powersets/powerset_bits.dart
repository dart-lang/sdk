// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common_elements.dart' show CommonElements;
import '../../constants/values.dart';
import '../../elements/entities.dart';
import '../../elements/names.dart';
import '../../elements/types.dart' show DartType, InterfaceType;
import '../../ir/static_type.dart';
import '../../universe/selector.dart';
import '../../world.dart';
import '../abstract_value_domain.dart';

class PowersetBitsDomain {
  // This class is used as an API by the powerset abstract value domain to help implement some queries.
  // It stores the bitmasks as integers and has the advantage that the operations needed
  // are relatively fast. This will pack multiple powerset domains into a single integer

  final JClosedWorld _closedWorld;

  static const int _trueIndex = 0;
  static const int _falseIndex = 1;
  static const int _nullIndex = 2;
  static const int _otherIndex = 3;

  const PowersetBitsDomain(this._closedWorld);

  CommonElements get commonElements => _closedWorld.commonElements;

  int get trueMask => 1 << _trueIndex;
  int get falseMask => 1 << _falseIndex;
  int get nullMask => 1 << _nullIndex;
  int get otherMask => 1 << _otherIndex;
  int get boolMask => trueMask | falseMask;
  int get boolOrNullMask => boolMask | nullMask;
  int get nullOrOtherMask => nullMask | otherMask;
  int get boolNullOtherMask => boolOrNullMask | otherMask;

  int get powersetBottom => 0;
  int get powersetTop => boolNullOtherMask;

  bool isPotentiallyBoolean(int value) => (value & boolMask) != 0;
  bool isPotentiallyOther(int value) => (value & otherMask) != 0;
  bool isPotentiallyNull(int value) => (value & nullMask) != 0;
  bool isPotentiallyBooleanOrNull(int value) => (value & boolOrNullMask) != 0;
  bool isPotentiallyNullOrOther(int value) => (value & nullOrOtherMask) != 0;

  bool isDefinitelyTrue(int value) => (value & boolNullOtherMask) == trueMask;
  bool isDefinitelyFalse(int value) => (value & boolNullOtherMask) == falseMask;
  bool isDefinitelyNull(int value) => (value & boolNullOtherMask) == nullMask;
  bool isSingleton(int value) =>
      isDefinitelyTrue(value) ||
      isDefinitelyFalse(value) ||
      isDefinitelyNull(value);

  AbstractBool isOther(int value) =>
      AbstractBool.maybeOrFalse(isPotentiallyOther(value));
  AbstractBool isNotOther(int value) =>
      AbstractBool.trueOrMaybe(!isPotentiallyOther(value));

  AbstractBool needsNoSuchMethodHandling(int receiver, Selector selector) =>
      AbstractBool.Maybe;

  AbstractBool isTargetingMember(
          int receiver, MemberEntity member, Name name) =>
      AbstractBool.Maybe;

  int computeReceiver(Iterable<MemberEntity> members) {
    return powersetTop;
  }

  // TODO(coam): This currently returns null if we are not sure if it's a primitive.
  // It could be improved because we can also tell when we're certain it's not a primitive.
  PrimitiveConstantValue getPrimitiveValue(int value) {
    if (isDefinitelyTrue(value)) {
      return TrueConstantValue();
    }
    if (isDefinitelyFalse(value)) {
      return FalseConstantValue();
    }
    if (isDefinitelyNull(value)) {
      return NullConstantValue();
    }
    return null;
  }

  int createPrimitiveValue(PrimitiveConstantValue value) {
    return computeAbstractValueForConstant(value);
  }

  // TODO(coam): Same as getPrimitiveValue above.
  bool isPrimitiveValue(int value) => isSingleton(value);

  int computeAbstractValueForConstant(ConstantValue value) {
    if (value.isTrue) {
      return trueMask;
    }
    if (value.isFalse) {
      return falseMask;
    }
    if (value.isNull) {
      return nullMask;
    }
    return otherMask;
  }

  AbstractBool areDisjoint(int a, int b) =>
      AbstractBool.trueOrMaybe(a & b == powersetBottom);

  int intersection(int a, int b) {
    return a & b;
  }

  int union(int a, int b) {
    return a | b;
  }

  AbstractBool isPrimitiveOrNull(int value) =>
      isPrimitive(value) | isNull(value);

  AbstractBool isStringOrNull(int value) => isString(value) | isNull(value);

  AbstractBool isString(int value) =>
      AbstractBool.maybeOrFalse(isPotentiallyOther(value));

  AbstractBool isBooleanOrNull(int value) => isBoolean(value) | isNull(value);

  AbstractBool isBoolean(int value) => isPotentiallyBoolean(value)
      ? AbstractBool.trueOrMaybe(!isPotentiallyNullOrOther(value))
      : AbstractBool.False;

  AbstractBool isDoubleOrNull(int value) => isDouble(value) | isNull(value);

  AbstractBool isDouble(int value) =>
      AbstractBool.maybeOrFalse(isPotentiallyOther(value));

  AbstractBool isNumberOrNull(int value) => isNumber(value) | isNull(value);

  AbstractBool isNumber(int value) =>
      AbstractBool.maybeOrFalse(isPotentiallyOther(value));

  AbstractBool isIntegerOrNull(int value) => isDouble(value) | isNull(value);

  AbstractBool isPositiveIntegerOrNull(int value) =>
      isPositiveInteger(value) | isNull(value);

  AbstractBool isPositiveInteger(int value) =>
      AbstractBool.maybeOrFalse(isPotentiallyOther(value));

  AbstractBool isUInt31(int value) =>
      AbstractBool.maybeOrFalse(isPotentiallyOther(value));

  AbstractBool isUInt32(int value) =>
      AbstractBool.maybeOrFalse(isPotentiallyOther(value));

  AbstractBool isInteger(int value) =>
      AbstractBool.maybeOrFalse(isPotentiallyOther(value));

  AbstractBool isInterceptor(int value) => AbstractBool.Maybe;

  AbstractBool isPrimitiveString(int value) =>
      AbstractBool.maybeOrFalse(isPotentiallyOther(value));

  AbstractBool isArray(int value) =>
      AbstractBool.maybeOrFalse(isPotentiallyOther(value));

  AbstractBool isMutableIndexable(int value) =>
      AbstractBool.maybeOrFalse(isPotentiallyOther(value));

  AbstractBool isMutableArray(int value) =>
      AbstractBool.maybeOrFalse(isPotentiallyOther(value));

  AbstractBool isExtendableArray(int value) =>
      AbstractBool.maybeOrFalse(isPotentiallyOther(value));

  AbstractBool isFixedArray(int value) =>
      AbstractBool.maybeOrFalse(isPotentiallyOther(value));

  AbstractBool isIndexablePrimitive(int value) =>
      AbstractBool.maybeOrFalse(isPotentiallyOther(value));

  AbstractBool isPrimitiveArray(int value) =>
      AbstractBool.maybeOrFalse(isPotentiallyOther(value));

  AbstractBool isPrimitiveBoolean(int value) => isPotentiallyBoolean(value)
      ? AbstractBool.trueOrMaybe(
          isDefinitelyTrue(value) || isDefinitelyFalse(value))
      : AbstractBool.False;

  AbstractBool isPrimitiveNumber(int value) =>
      AbstractBool.maybeOrFalse(isPotentiallyOther(value));

  AbstractBool isPrimitive(int value) =>
      AbstractBool.trueOrMaybe(isSingleton(value));

  AbstractBool isNull(int value) => isDefinitelyNull(value)
      ? AbstractBool.True
      : (isPotentiallyNull(value) ? AbstractBool.Maybe : AbstractBool.False);

  AbstractBool isExactOrNull(int value) => AbstractBool.Maybe;

  AbstractBool isExact(int value) => AbstractBool.Maybe;

  AbstractBool isEmpty(int value) =>
      AbstractBool.trueOrFalse(value == powersetBottom);

  AbstractBool isInstanceOf(int value, ClassEntity cls) => AbstractBool.Maybe;

  AbstractBool isInstanceOfOrNull(int value, ClassEntity cls) =>
      AbstractBool.Maybe;

  AbstractBool containsOnlyType(int value, ClassEntity cls) =>
      AbstractBool.Maybe;

  AbstractBool containsType(int value, ClassEntity cls) => AbstractBool.Maybe;

  int includeNull(int value) {
    return value | nullMask;
  }

  int excludeNull(int value) {
    return value & (powersetTop - nullMask);
  }

  AbstractBool couldBeTypedArray(int value) =>
      AbstractBool.maybeOrFalse(isPotentiallyOther(value));

  AbstractBool isTypedArray(int value) => AbstractBool.Maybe;

  bool isBoolSubtype(ClassEntity cls) {
    return cls == commonElements.jsBoolClass || cls == commonElements.boolClass;
  }

  int createNullableSubtype(ClassEntity cls) {
    if (isBoolSubtype(cls)) {
      return boolOrNullMask;
    }
    return nullOrOtherMask;
  }

  int createNonNullSubtype(ClassEntity cls) {
    if (isBoolSubtype(cls)) {
      return boolMask;
    }
    return otherMask;
  }

  int createNonNullSubclass(ClassEntity cls) {
    if (isBoolSubtype(cls)) {
      return boolMask;
    }
    return otherMask;
  }

  int createNullableExact(ClassEntity cls) {
    if (isBoolSubtype(cls)) {
      return boolOrNullMask;
    }
    return nullOrOtherMask;
  }

  int createNonNullExact(ClassEntity cls) {
    if (isBoolSubtype(cls)) {
      return boolMask;
    }
    return otherMask;
  }

  int createFromStaticType(DartType type,
      {ClassRelation classRelation = ClassRelation.subtype, bool nullable}) {
    // TODO(coam): This only works for bool
    int bits = otherMask;
    if (type is InterfaceType && isBoolSubtype(type.element)) {
      bits = boolMask;
    }
    if (nullable) {
      bits = bits | nullMask;
    }
    return bits;
  }

  int get asyncStarStreamType => powersetTop;

  int get asyncFutureType => powersetTop;

  int get syncStarIterableType => powersetTop;

  int get emptyType => powersetBottom;

  int get constMapType => otherMask;

  int get constSetType => otherMask;

  int get constListType => otherMask;

  int get positiveIntType => otherMask;

  int get uint32Type => otherMask;

  int get uint31Type => otherMask;

  int get fixedListType => otherMask;

  int get growableListType => otherMask;

  int get nullType => nullMask;

  int get nonNullType => otherMask;

  int get mapType => otherMask;

  int get setType => otherMask;

  int get listType => otherMask;

  int get stringType => otherMask;

  int get numType => otherMask;

  int get doubleType => otherMask;

  int get intType => otherMask;

  int get boolType => boolMask;

  int get functionType => otherMask;

  int get typeType => otherMask;
}
