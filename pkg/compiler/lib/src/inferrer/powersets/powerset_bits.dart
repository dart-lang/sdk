// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common_elements.dart' show CommonElements;
import '../../constants/values.dart';
import '../../elements/entities.dart';
import '../../elements/names.dart';
import '../../elements/types.dart';
import '../../ir/static_type.dart';
import '../../universe/selector.dart';
import '../../world.dart';
import '../abstract_value_domain.dart';

/// This class is used to store bits information about class entities.
class ClassInfo {
  final int exactBits;
  final int strictSubtypeBits;
  final int strictSubclassBits;

  const ClassInfo(
      this.exactBits, this.strictSubtypeBits, this.strictSubclassBits);
}

/// This class is used as an API by the powerset abstract value domain to help
/// implement some queries. It stores the bitmasks as integers and has the
/// advantage that the operations needed are relatively fast. This will pack
/// multiple powerset domains into a single integer.
class PowersetBitsDomain {
  final JClosedWorld _closedWorld;
  final Map<ClassEntity, ClassInfo> _storedClassInfo = {};

  static const int _trueIndex = 0;
  static const int _falseIndex = 1;
  static const int _nullIndex = 2;
  static const int _otherIndex = 3;

  static const int _maxIndex = _otherIndex;

  static const List<int> _singletonIndices = [
    _trueIndex,
    _falseIndex,
    _nullIndex,
  ];

  static const List<String> _bitNames = ['true', 'false', 'null', 'other'];

  PowersetBitsDomain(this._closedWorld);

  CommonElements get commonElements => _closedWorld.commonElements;

  DartTypes get dartTypes => _closedWorld.dartTypes;

  int get trueMask => 1 << _trueIndex;
  int get falseMask => 1 << _falseIndex;
  int get nullMask => 1 << _nullIndex;
  int get otherMask => 1 << _otherIndex;
  int get boolMask => trueMask | falseMask;
  int get boolOrNullMask => boolMask | nullMask;
  int get nullOrOtherMask => nullMask | otherMask;
  int get boolNullOtherMask => boolOrNullMask | otherMask;
  int get preciseMask => _singletonIndices.fold(
      powersetBottom, (mask, index) => mask | 1 << index);

  int get powersetBottom => 0;
  int get powersetTop => (1 << _maxIndex + 1) - 1;

  bool isPotentiallyBoolean(int value) => (value & boolMask) != 0;
  bool isPotentiallyNull(int value) => (value & nullMask) != 0;
  bool isPotentiallyOther(int value) => (value & otherMask) != 0;

  bool isDefinitelyTrue(int value) => value == trueMask;
  bool isDefinitelyFalse(int value) => value == falseMask;
  bool isDefinitelyNull(int value) => value == nullMask;
  bool isSingleton(int value) =>
      isDefinitelyTrue(value) ||
      isDefinitelyFalse(value) ||
      isDefinitelyNull(value);

  /// Returns `true` if only singleton bits are set and `false` otherwise.
  bool isPrecise(int value) => value & ~preciseMask == 0;

  AbstractBool isOther(int value) =>
      AbstractBool.maybeOrFalse(isPotentiallyOther(value));

  AbstractBool isIn(int subset, int superset) {
    if (union(subset, superset) == superset) {
      if (isPrecise(superset)) return AbstractBool.True;
    } else {
      if (isPrecise(subset)) return AbstractBool.False;
    }
    return AbstractBool.Maybe;
  }

  /// Returns a descriptive string for [bits]
  static String toText(int bits, {bool omitIfTop = false}) {
    int boolDomainMask = (1 << _maxIndex + 1) - 1;
    return _toTextDomain(bits, boolDomainMask, omitIfTop);
  }

  /// Returns a descriptive string for a subset of [bits] defined by
  /// [domainMask]. If [omitIfTop] is `true` and all the bits in the
  /// [domainMask] are set, an empty string is returned.
  static String _toTextDomain(int bits, int domainMask, bool omitIfTop) {
    bits &= domainMask;
    if (bits == domainMask && omitIfTop) return '';
    final sb = StringBuffer();
    sb.write('{');
    String comma = '';
    while (bits != 0) {
      int lowestBit = bits & ~(bits - 1);
      int index = lowestBit.bitLength - 1;
      sb.write(comma);
      sb.write(_bitNames[index]);
      comma = ',';
      bits &= ~lowestBit;
    }
    sb.write('}');
    return '$sb';
  }

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

  AbstractBool areDisjoint(int a, int b) {
    int overlap = intersection(a, b);
    if (overlap == powersetBottom) return AbstractBool.True;
    if (isPrecise(overlap)) return AbstractBool.False;
    return AbstractBool.Maybe;
  }

  int intersection(int a, int b) {
    return a & b;
  }

  int union(int a, int b) {
    return a | b;
  }

  AbstractBool isPrimitiveOrNull(int value) => isPrimitive(excludeNull(value));

  AbstractBool isStringOrNull(int value) => isString(excludeNull(value));

  AbstractBool isString(int value) => isOther(value);

  AbstractBool isBooleanOrNull(int value) => isBoolean(excludeNull(value));

  AbstractBool isBoolean(int value) {
    if (!isPotentiallyBoolean(value)) return AbstractBool.False;
    if (value & ~boolMask == 0) return AbstractBool.True;
    return AbstractBool.Maybe;
  }

  AbstractBool isTruthy(int value) {
    if (value & ~trueMask == 0) return AbstractBool.True;
    if (value & ~(falseMask | nullMask) == 0) return AbstractBool.False;
    return AbstractBool.Maybe;
  }

  AbstractBool isDoubleOrNull(int value) => isDouble(excludeNull(value));

  AbstractBool isDouble(int value) => isOther(value);

  AbstractBool isNumberOrNull(int value) => isNumber(excludeNull(value));

  AbstractBool isNumber(int value) => isOther(value);

  AbstractBool isIntegerOrNull(int value) => isInteger(excludeNull(value));

  AbstractBool isPositiveIntegerOrNull(int value) =>
      isPositiveInteger(excludeNull(value));

  AbstractBool isPositiveInteger(int value) => isOther(value);

  AbstractBool isUInt31(int value) => isOther(value);

  AbstractBool isUInt32(int value) => isOther(value);

  AbstractBool isInteger(int value) => isOther(value);

  AbstractBool isInterceptor(int value) => AbstractBool.Maybe;

  AbstractBool isPrimitiveString(int value) => isOther(value);

  AbstractBool isArray(int value) => isOther(value);

  AbstractBool isMutableIndexable(int value) => isOther(value);

  AbstractBool isMutableArray(int value) => isOther(value);

  AbstractBool isExtendableArray(int value) => isOther(value);

  AbstractBool isFixedArray(int value) => isOther(value);

  AbstractBool isIndexablePrimitive(int value) => isOther(value);

  AbstractBool isPrimitiveArray(int value) => isOther(value);

  AbstractBool isPrimitiveBoolean(int value) {
    if (isDefinitelyTrue(value) || isDefinitelyFalse(value)) {
      return AbstractBool.True;
    }
    if (!isPotentiallyBoolean(value)) return AbstractBool.False;
    return AbstractBool.Maybe;
  }

  AbstractBool isPrimitiveNumber(int value) => isOther(value);

  AbstractBool isPrimitive(int value) =>
      AbstractBool.trueOrMaybe(isSingleton(value));

  AbstractBool isNull(int value) => isDefinitelyNull(value)
      ? AbstractBool.True
      : (isPotentiallyNull(value) ? AbstractBool.Maybe : AbstractBool.False);

  AbstractBool isExactOrNull(int value) => AbstractBool.Maybe;

  AbstractBool isExact(int value) => AbstractBool.Maybe;

  AbstractBool isEmpty(int value) {
    if (value == powersetBottom) return AbstractBool.True;
    if (isPrecise(value)) return AbstractBool.False;
    return AbstractBool.Maybe;
  }

  AbstractBool isInstanceOf(int value, ClassEntity cls) => AbstractBool.Maybe;

  AbstractBool isInstanceOfOrNull(int value, ClassEntity cls) =>
      AbstractBool.Maybe;

  AbstractBool containsAll(int value) =>
      AbstractBool.maybeOrFalse(value == powersetTop);

  AbstractBool containsOnlyType(int value, ClassEntity cls) =>
      AbstractBool.Maybe;

  AbstractBool containsType(int value, ClassEntity cls) => AbstractBool.Maybe;

  int includeNull(int value) {
    return value | nullMask;
  }

  int excludeNull(int value) {
    return value & ~nullMask;
  }

  AbstractBool couldBeTypedArray(int value) => isOther(value);

  AbstractBool isTypedArray(int value) => AbstractBool.Maybe;

  bool _isBoolSubtype(ClassEntity cls) {
    return cls == commonElements.jsBoolClass || cls == commonElements.boolClass;
  }

  bool _isNullSubtype(ClassEntity cls) {
    return cls == commonElements.jsNullClass || cls == commonElements.nullClass;
  }

  // This function checks if cls is one of those classes other than bool or null
  // that are live by default in a program.
  bool _isLiveByDefault(ClassEntity cls) {
    return cls == commonElements.intClass ||
        cls == commonElements.numClass ||
        cls == commonElements.doubleClass ||
        cls == commonElements.stringClass;
  }

  ClassInfo _computeClassInfo(ClassEntity cls) {
    ClassInfo classInfo = _storedClassInfo[cls];
    if (classInfo != null) {
      return classInfo;
    }

    // Bool and Null are handled specially because the powerset bits
    // contain information about values being bool or null.
    if (_isNullSubtype(cls)) {
      classInfo = ClassInfo(nullMask, powersetBottom, powersetBottom);
      _storedClassInfo[cls] = classInfo;
      return classInfo;
    }
    if (_isBoolSubtype(cls)) {
      classInfo = ClassInfo(boolMask, powersetBottom, powersetBottom);
      _storedClassInfo[cls] = classInfo;
      return classInfo;
    }

    // If cls is instantiated or live by default the 'other' bit should be set to 1.
    int exactBits = powersetBottom;
    if (_isLiveByDefault(cls) ||
        _closedWorld.classHierarchy.isInstantiated(cls)) {
      exactBits = otherMask;
    }

    int strictSubtypeBits = powersetBottom;
    for (ClassEntity strictSubtype
        in _closedWorld.classHierarchy.strictSubtypesOf(cls)) {
      // Currently null is a subtype of Object in the class hierarchy but we don't
      // want to consider it as a subtype of a nonnull class
      if (!_isNullSubtype(strictSubtype)) {
        strictSubtypeBits |= _computeClassInfo(strictSubtype).exactBits;
      }
    }

    int strictSubclassBits = powersetBottom;
    for (ClassEntity strictSubclass
        in _closedWorld.classHierarchy.strictSubclassesOf(cls)) {
      // Currently null is a subtype of Object in the class hierarchy but we don't
      // want to consider it as a subtype of a nonnull class
      if (!_isNullSubtype(strictSubclass)) {
        strictSubclassBits |= _computeClassInfo(strictSubclass).exactBits;
      }
    }

    classInfo = ClassInfo(exactBits, strictSubtypeBits, strictSubclassBits);
    _storedClassInfo[cls] = classInfo;
    return classInfo;
  }

  int createNullableSubtype(ClassEntity cls) {
    return includeNull(createNonNullSubtype(cls));
  }

  int createNonNullSubtype(ClassEntity cls) {
    ClassInfo classInfo = _computeClassInfo(cls);
    return classInfo.exactBits | classInfo.strictSubtypeBits;
  }

  int createNonNullSubclass(ClassEntity cls) {
    ClassInfo classInfo = _computeClassInfo(cls);
    return classInfo.exactBits | classInfo.strictSubclassBits;
  }

  int createNullableExact(ClassEntity cls) {
    return includeNull(createNonNullExact(cls));
  }

  int createNonNullExact(ClassEntity cls) {
    ClassInfo classInfo = _computeClassInfo(cls);
    return classInfo.exactBits;
  }

  int createFromStaticType(DartType type,
      {ClassRelation classRelation = ClassRelation.subtype, bool nullable}) {
    assert(nullable != null);

    if ((classRelation == ClassRelation.subtype ||
            classRelation == ClassRelation.thisExpression) &&
        dartTypes.isTopType(type)) {
      // A cone of a top type includes all values. This would be 'precise' if we
      // tracked that.
      return dynamicType;
    }

    if (type is NullableType) {
      assert(dartTypes.useNullSafety);
      return _createFromStaticType(type.baseType, classRelation, true);
    }

    if (type is LegacyType) {
      assert(dartTypes.useNullSafety);
      DartType baseType = type.baseType;
      if (baseType is NeverType) {
        // Never* is same as Null, for both 'is' and 'as'.
        return nullMask;
      }

      // Object* is a top type for both 'is' and 'as'. This is handled in the
      // 'cone of top type' case above.

      return _createFromStaticType(baseType, classRelation, nullable);
    }

    if (dartTypes.useLegacySubtyping) {
      // In legacy and weak mode, `String` is nullable depending on context.
      return _createFromStaticType(type, classRelation, nullable);
    } else {
      // In strong mode nullability comes from explicit NullableType.
      return _createFromStaticType(type, classRelation, false);
    }
  }

  int _createFromStaticType(
      DartType type, ClassRelation classRelation, bool nullable) {
    assert(nullable != null);

    int finish(int value, bool isPrecise) {
      // [isPrecise] is ignored since we only treat singleton partitions as
      // precise.
      // TODO(sra): Each bit that represents more that one concrete value could
      // have an 'isPrecise' bit.
      return nullable ? includeNull(value) : value;
    }

    bool isPrecise = true;
    while (type is TypeVariableType) {
      TypeVariableType typeVariable = type;
      type = _closedWorld.elementEnvironment
          .getTypeVariableBound(typeVariable.element);
      classRelation = ClassRelation.subtype;
      isPrecise = false;
      if (type is NullableType) {
        // <A extends B?, B extends num>  ...  null is A --> can be `true`.
        // <A extends B, B extends num?>  ...  null is A --> can be `true`.
        nullable = true;
        type = type.withoutNullability;
      }
    }

    if ((classRelation == ClassRelation.thisExpression ||
            classRelation == ClassRelation.subtype) &&
        dartTypes.isTopType(type)) {
      // A cone of a top type includes all values. Since we already tested this
      // in [createFromStaticType], we get here only for type parameter bounds.
      return finish(dynamicType, isPrecise);
    }

    if (type is InterfaceType) {
      ClassEntity cls = type.element;
      List<DartType> arguments = type.typeArguments;
      if (isPrecise && arguments.isNotEmpty) {
        // Can we ignore the type arguments?
        //
        // For legacy covariance, if the interface type is a generic interface
        // type and is maximal (i.e. instantiated to bounds), the typemask,
        // which is based on the class element, is still precise. We check
        // against Top for the parameter arguments since we don't have a
        // convenient check for instantation to bounds.
        //
        // TODO(sra): Check arguments against bounds.
        // TODO(sra): Handle other variances.
        List<Variance> variances = dartTypes.getTypeVariableVariances(cls);
        for (int i = 0; i < arguments.length; i++) {
          Variance variance = variances[i];
          DartType argument = arguments[i];
          if (variance == Variance.legacyCovariant &&
              dartTypes.isTopType(argument)) {
            continue;
          }
          isPrecise = false;
        }
      }
      switch (classRelation) {
        case ClassRelation.exact:
          return finish(createNonNullExact(cls), isPrecise);
        case ClassRelation.thisExpression:
          if (!_closedWorld.isUsedAsMixin(cls)) {
            return finish(createNonNullSubclass(cls), isPrecise);
          }
          break;
        case ClassRelation.subtype:
          break;
      }
      return finish(createNonNullSubtype(cls), isPrecise);
    }

    if (type is FunctionType) {
      return finish(createNonNullSubtype(commonElements.functionClass), false);
    }

    if (type is NeverType) {
      return finish(emptyType, isPrecise);
    }

    return finish(dynamicType, false);
  }

  int get dynamicType => powersetTop;

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
