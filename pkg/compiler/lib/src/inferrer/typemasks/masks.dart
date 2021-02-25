// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library masks;

import 'package:kernel/ast.dart' as ir;

import '../../common.dart';
import '../../common_elements.dart' show CommonElements;
import '../../constants/values.dart';
import '../../elements/entities.dart';
import '../../elements/names.dart';
import '../../elements/types.dart';
import '../../ir/static_type.dart';
import '../../serialization/serialization.dart';
import '../../universe/class_hierarchy.dart';
import '../../universe/selector.dart' show Selector;
import '../../universe/use.dart' show DynamicUse;
import '../../universe/world_builder.dart'
    show UniverseSelectorConstraints, SelectorConstraintsStrategy;
import '../../util/util.dart';
import '../../world.dart' show JClosedWorld;
import '../abstract_value_domain.dart';
import '../type_graph_inferrer.dart' show TypeGraphInferrer;
import 'constants.dart';

part 'container_type_mask.dart';
part 'dictionary_type_mask.dart';
part 'flat_type_mask.dart';
part 'forwarding_type_mask.dart';
part 'map_type_mask.dart';
part 'set_type_mask.dart';
part 'type_mask.dart';
part 'union_type_mask.dart';
part 'value_type_mask.dart';

class CommonMasks implements AbstractValueDomain {
  // TODO(sigmund): once we split out the backend common elements, depend
  // directly on those instead.
  final JClosedWorld _closedWorld;

  CommonMasks(this._closedWorld);

  CommonElements get commonElements => _closedWorld.commonElements;
  DartTypes get dartTypes => _closedWorld.dartTypes;

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
  TypeMask _setType;
  TypeMask _constSetType;
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
      new TypeMask.nonNullSubtype(commonElements.jsArrayClass, _closedWorld);

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
  TypeMask get setType => _setType ??=
      new TypeMask.nonNullSubtype(commonElements.setLiteralClass, _closedWorld);

  @override
  TypeMask get constSetType => _constSetType ??= new TypeMask.nonNullSubtype(
      commonElements.constSetLiteralClass, _closedWorld);

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

  @override
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
  AbstractBool isTypedArray(TypeMask mask) {
    // Just checking for `TypedData` is not sufficient, as it is an abstract
    // class any user-defined class can implement. So we also check for the
    // interface `JavaScriptIndexingBehavior`.
    ClassEntity typedDataClass = _closedWorld.commonElements.typedDataClass;
    return AbstractBool.trueOrMaybe(typedDataClass != null &&
        _closedWorld.classHierarchy.isInstantiated(typedDataClass) &&
        mask.satisfies(typedDataClass, _closedWorld) &&
        mask.satisfies(_closedWorld.commonElements.jsIndexingBehaviorInterface,
            _closedWorld));
  }

  @override
  AbstractBool couldBeTypedArray(TypeMask mask) {
    bool intersects(TypeMask type1, TypeMask type2) =>
        !type1.intersection(type2, this).isEmpty;
    // TODO(herhut): Maybe cache the TypeMask for typedDataClass and
    //               jsIndexingBehaviourInterface.
    ClassEntity typedDataClass = _closedWorld.commonElements.typedDataClass;
    return AbstractBool.maybeOrFalse(typedDataClass != null &&
        _closedWorld.classHierarchy.isInstantiated(typedDataClass) &&
        intersects(mask, new TypeMask.subtype(typedDataClass, _closedWorld)) &&
        intersects(
            mask,
            new TypeMask.subtype(
                _closedWorld.commonElements.jsIndexingBehaviorInterface,
                _closedWorld)));
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
  AbstractValueWithPrecision createFromStaticType(DartType type,
      {ClassRelation classRelation = ClassRelation.subtype, bool nullable}) {
    assert(nullable != null);

    if ((classRelation == ClassRelation.subtype ||
            classRelation == ClassRelation.thisExpression) &&
        dartTypes.isTopType(type)) {
      // A cone of a top type includes all values.
      return AbstractValueWithPrecision(dynamicType, true);
    }

    if (type is NullableType) {
      return _createFromStaticType(type.baseType, classRelation, true);
    }

    if (type is LegacyType) {
      DartType baseType = type.baseType;
      if (baseType is NeverType) {
        // Never* is same as Null, for both 'is' and 'as'.
        return AbstractValueWithPrecision(nullType, true);
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

  AbstractValueWithPrecision _createFromStaticType(
      DartType type, ClassRelation classRelation, bool nullable) {
    assert(nullable != null);

    AbstractValueWithPrecision finish(TypeMask value, bool isPrecise) {
      return AbstractValueWithPrecision(
          nullable ? value.nullable() : value, isPrecise);
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
      return AbstractValueWithPrecision(dynamicType, isPrecise);
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
          return finish(TypeMask.nonNullExact(cls, _closedWorld), isPrecise);
        case ClassRelation.thisExpression:
          if (!_closedWorld.isUsedAsMixin(cls)) {
            return finish(
                TypeMask.nonNullSubclass(cls, _closedWorld), isPrecise);
          }
          break;
        case ClassRelation.subtype:
          break;
      }
      return finish(TypeMask.nonNullSubtype(cls, _closedWorld), isPrecise);
    }

    if (type is FunctionType) {
      return finish(
          TypeMask.nonNullSubtype(commonElements.functionClass, _closedWorld),
          false);
    }

    if (type is NeverType) {
      return finish(emptyType, isPrecise);
    }

    return AbstractValueWithPrecision(dynamicType, false);
  }

  @override
  TypeMask excludeNull(TypeMask mask) => mask.nonNullable();

  @override
  TypeMask includeNull(TypeMask mask) => mask.nullable();

  @override
  AbstractBool containsType(TypeMask typeMask, ClassEntity cls) {
    return AbstractBool.trueOrFalse(_containsType(typeMask, cls));
  }

  bool _containsType(TypeMask typeMask, ClassEntity cls) {
    return _closedWorld.classHierarchy.isInstantiated(cls) &&
        typeMask.contains(cls, _closedWorld);
  }

  @override
  AbstractBool containsOnlyType(TypeMask typeMask, ClassEntity cls) {
    return AbstractBool.trueOrMaybe(_containsOnlyType(typeMask, cls));
  }

  bool _containsOnlyType(TypeMask typeMask, ClassEntity cls) {
    return _closedWorld.classHierarchy.isInstantiated(cls) &&
        typeMask.containsOnly(cls);
  }

  @override
  AbstractBool isInstanceOfOrNull(TypeMask typeMask, ClassEntity cls) =>
      AbstractBool.trueOrMaybe(_isInstanceOfOrNull(typeMask, cls));

  bool _isInstanceOfOrNull(TypeMask typeMask, ClassEntity cls) {
    return _closedWorld.isImplemented(cls) &&
        typeMask.satisfies(cls, _closedWorld);
  }

  @override
  AbstractBool isInstanceOf(
      covariant TypeMask expressionMask, ClassEntity cls) {
    AbstractValue typeMask = (cls == commonElements.nullClass)
        ? nullType
        : createNonNullSubtype(cls);
    if (expressionMask.union(typeMask, this) == typeMask) {
      return AbstractBool.True;
    } else if (expressionMask.isDisjoint(typeMask, _closedWorld)) {
      return AbstractBool.False;
    } else {
      return AbstractBool.Maybe;
    }
  }

  @override
  AbstractBool isEmpty(TypeMask value) =>
      AbstractBool.trueOrMaybe(value.isEmpty);

  @override
  AbstractBool isExact(TypeMask value) =>
      AbstractBool.trueOrMaybe(value.isExact && !value.isNullable);

  @override
  AbstractBool isExactOrNull(TypeMask value) =>
      AbstractBool.trueOrMaybe(value.isExact || _isNull(value));

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
  AbstractBool isNull(TypeMask value) {
    if (value.isNull) {
      return AbstractBool.True;
    } else if (value.isNullable) {
      return AbstractBool.Maybe;
    } else {
      return AbstractBool.False;
    }
  }

  bool _isNull(TypeMask value) => value.isNull;

  @override
  AbstractBool isPrimitive(TypeMask value) {
    return AbstractBool.maybeOrFalse(_canBePrimitiveNumber(value) ||
        _canBePrimitiveArray(value) ||
        _canBePrimitiveBoolean(value) ||
        _canBePrimitiveString(value) ||
        _isNull(value));
  }

  @override
  AbstractBool isPrimitiveNumber(TypeMask value) =>
      AbstractBool.maybeOrFalse(_canBePrimitiveNumber(value));

  bool _canBePrimitiveNumber(TypeMask value) {
    // TODO(sra): It should be possible to test only jsDoubleClass and
    // jsUInt31Class, since all others are superclasses of these two.
    return _containsType(value, commonElements.jsNumberClass) ||
        _containsType(value, commonElements.jsIntClass) ||
        _containsType(value, commonElements.jsPositiveIntClass) ||
        _containsType(value, commonElements.jsUInt32Class) ||
        _containsType(value, commonElements.jsUInt31Class) ||
        _containsType(value, commonElements.jsDoubleClass);
  }

  @override
  AbstractBool isPrimitiveBoolean(TypeMask value) =>
      AbstractBool.maybeOrFalse(_canBePrimitiveBoolean(value));

  bool _canBePrimitiveBoolean(TypeMask value) {
    return _containsType(value, commonElements.jsBoolClass);
  }

  @override
  AbstractBool isPrimitiveArray(TypeMask value) =>
      AbstractBool.maybeOrFalse(_canBePrimitiveArray(value));

  bool _canBePrimitiveArray(TypeMask value) {
    return _containsType(value, commonElements.jsArrayClass) ||
        _containsType(value, commonElements.jsFixedArrayClass) ||
        _containsType(value, commonElements.jsExtendableArrayClass) ||
        _containsType(value, commonElements.jsUnmodifiableArrayClass);
  }

  @override
  AbstractBool isIndexablePrimitive(TypeMask value) =>
      AbstractBool.trueOrMaybe(_isIndexablePrimitive(value));

  bool _isIndexablePrimitive(TypeMask value) {
    return value.containsOnlyString(_closedWorld) ||
        _isInstanceOfOrNull(value, commonElements.jsIndexableClass);
  }

  @override
  AbstractBool isFixedArray(TypeMask value) {
    // TODO(sra): Recognize the union of these types as well.
    return AbstractBool.trueOrMaybe(
        _containsOnlyType(value, commonElements.jsFixedArrayClass) ||
            _containsOnlyType(value, commonElements.jsUnmodifiableArrayClass));
  }

  @override
  AbstractBool isExtendableArray(TypeMask value) {
    return AbstractBool.trueOrMaybe(
        _containsOnlyType(value, commonElements.jsExtendableArrayClass));
  }

  @override
  AbstractBool isMutableArray(TypeMask value) {
    return AbstractBool.trueOrMaybe(
        _isInstanceOfOrNull(value, commonElements.jsMutableArrayClass));
  }

  @override
  AbstractBool isMutableIndexable(TypeMask value) {
    return AbstractBool.trueOrMaybe(
        _isInstanceOfOrNull(value, commonElements.jsMutableIndexableClass));
  }

  @override
  AbstractBool isArray(TypeMask value) {
    return AbstractBool.trueOrMaybe(
        _isInstanceOfOrNull(value, commonElements.jsArrayClass));
  }

  @override
  AbstractBool isPrimitiveString(TypeMask value) =>
      AbstractBool.maybeOrFalse(_canBePrimitiveString(value));

  bool _canBePrimitiveString(TypeMask value) {
    return _containsType(value, commonElements.jsStringClass);
  }

  @override
  AbstractBool isInteger(TypeMask value) {
    return AbstractBool.trueOrMaybe(
        value.containsOnlyInt(_closedWorld) && !value.isNullable);
  }

  @override
  AbstractBool isUInt32(TypeMask value) {
    return AbstractBool.trueOrMaybe(!value.isNullable &&
        _isInstanceOfOrNull(value, commonElements.jsUInt32Class));
  }

  @override
  AbstractBool isUInt31(TypeMask value) {
    return AbstractBool.trueOrMaybe(!value.isNullable &&
        _isInstanceOfOrNull(value, commonElements.jsUInt31Class));
  }

  @override
  AbstractBool isPositiveInteger(TypeMask value) {
    return AbstractBool.trueOrMaybe(!value.isNullable &&
        _isInstanceOfOrNull(value, commonElements.jsPositiveIntClass));
  }

  @override
  AbstractBool isPositiveIntegerOrNull(TypeMask value) {
    return AbstractBool.trueOrMaybe(
        _isInstanceOfOrNull(value, commonElements.jsPositiveIntClass));
  }

  @override
  AbstractBool isIntegerOrNull(TypeMask value) {
    return AbstractBool.trueOrMaybe(value.containsOnlyInt(_closedWorld));
  }

  @override
  AbstractBool isNumber(TypeMask value) {
    return AbstractBool.trueOrMaybe(
        value.containsOnlyNum(_closedWorld) && !value.isNullable);
  }

  @override
  AbstractBool isNumberOrNull(TypeMask value) =>
      AbstractBool.trueOrMaybe(_isNumberOrNull(value));

  bool _isNumberOrNull(TypeMask value) {
    return value.containsOnlyNum(_closedWorld);
  }

  @override
  AbstractBool isDouble(TypeMask value) {
    return AbstractBool.trueOrMaybe(
        value.containsOnlyDouble(_closedWorld) && !value.isNullable);
  }

  @override
  AbstractBool isDoubleOrNull(TypeMask value) {
    return AbstractBool.trueOrMaybe(value.containsOnlyDouble(_closedWorld));
  }

  @override
  AbstractBool isBoolean(TypeMask value) {
    return AbstractBool.trueOrMaybe(
        value.containsOnlyBool(_closedWorld) && !value.isNullable);
  }

  @override
  AbstractBool isBooleanOrNull(TypeMask value) =>
      AbstractBool.trueOrMaybe(_isBooleanOrNull(value));

  bool _isBooleanOrNull(TypeMask value) {
    return value.containsOnlyBool(_closedWorld);
  }

  @override
  AbstractBool isTruthy(TypeMask value) {
    if (value is ValueTypeMask && !value.isNullable) {
      PrimitiveConstantValue constant = value.value;
      if (constant is BoolConstantValue) {
        return constant.boolValue ? AbstractBool.True : AbstractBool.False;
      }
    }
    // TODO(sra): Non-intercepted types are generally JavaScript falsy values.
    return AbstractBool.Maybe;
  }

  @override
  AbstractBool isString(TypeMask value) {
    return AbstractBool.trueOrMaybe(
        value.containsOnlyString(_closedWorld) && !value.isNullable);
  }

  @override
  AbstractBool isStringOrNull(TypeMask value) {
    return AbstractBool.trueOrMaybe(value.containsOnlyString(_closedWorld));
  }

  @override
  AbstractBool isPrimitiveOrNull(TypeMask value) =>
      AbstractBool.trueOrMaybe(_isPrimitiveOrNull(value));

  bool _isPrimitiveOrNull(TypeMask value) {
    return _isIndexablePrimitive(value) ||
        _isNumberOrNull(value) ||
        _isBooleanOrNull(value) ||
        _isNull(value);
  }

  @override
  TypeMask union(TypeMask a, TypeMask b) => a.union(b, this);

  @override
  TypeMask intersection(TypeMask a, TypeMask b) => a.intersection(b, this);

  @override
  AbstractBool areDisjoint(TypeMask a, TypeMask b) =>
      AbstractBool.trueOrMaybe(a.isDisjoint(b, _closedWorld));

  @override
  AbstractBool containsAll(TypeMask a) =>
      AbstractBool.maybeOrFalse(a.containsAll(_closedWorld));

  @override
  AbstractValue computeAbstractValueForConstant(ConstantValue value) {
    return computeTypeMask(this, _closedWorld, value);
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
      result = result.union(value, this);
    }
    return result;
  }

  @override
  AbstractValue computeReceiver(Iterable<MemberEntity> members) {
    assert(_closedWorld.classHierarchy
        .hasAnyStrictSubclass(_closedWorld.commonElements.objectClass));
    return new TypeMask.unionOf(
        members.expand((MemberEntity element) {
          ClassEntity cls = element.enclosingClass;
          return [cls]..addAll(_closedWorld.mixinUsesOf(cls));
        }).map((cls) {
          if (_closedWorld.commonElements.jsNullClass == cls) {
            return const TypeMask.empty();
          } else if (_closedWorld.classHierarchy.isInstantiated(cls)) {
            return new TypeMask.nonNullSubclass(cls, _closedWorld);
          } else {
            // TODO(johnniwinther): Avoid the need for this case.
            return const TypeMask.empty();
          }
        }),
        this);
  }

  @override
  AbstractBool isTargetingMember(
      covariant TypeMask receiver, MemberEntity member, Name name) {
    return AbstractBool.maybeOrFalse(
        receiver.canHit(member, name, _closedWorld));
  }

  @override
  AbstractBool needsNoSuchMethodHandling(
      covariant TypeMask receiver, Selector selector) {
    return AbstractBool.trueOrFalse(
        receiver.needsNoSuchMethodHandling(selector, _closedWorld));
  }

  @override
  AbstractBool isIn(covariant TypeMask subset, covariant TypeMask superset) {
    return AbstractBool.trueOrMaybe(subset.isInMask(superset, _closedWorld));
  }

  @override
  MemberEntity locateSingleMember(
      covariant TypeMask receiver, Selector selector) {
    return receiver.locateSingleMember(selector, this);
  }

  @override
  AbstractBool isJsIndexable(TypeMask mask) {
    return AbstractBool.trueOrMaybe(mask.satisfies(
        _closedWorld.commonElements.jsIndexableClass, _closedWorld));
  }

  @override
  AbstractBool isJsIndexableAndIterable(covariant TypeMask mask) {
    return AbstractBool.trueOrMaybe(mask.satisfies(
            _closedWorld.commonElements.jsIndexableClass, _closedWorld) &&
        // String is indexable but not iterable.
        !mask.satisfies(
            _closedWorld.commonElements.jsStringClass, _closedWorld));
  }

  @override
  AbstractBool isFixedLengthJsIndexable(covariant TypeMask mask) {
    if (mask.isContainer && (mask as ContainerTypeMask).length != null) {
      // A container on which we have inferred the length.
      return AbstractBool.True;
    }
    // TODO(sra): Recognize any combination of fixed length indexables.
    if (mask.containsOnly(_closedWorld.commonElements.jsFixedArrayClass) ||
        mask.containsOnly(
            _closedWorld.commonElements.jsUnmodifiableArrayClass) ||
        mask.containsOnlyString(_closedWorld) ||
        isTypedArray(mask).isDefinitelyTrue) {
      return AbstractBool.True;
    }
    return AbstractBool.Maybe;
  }

  @override
  AbstractBool isInterceptor(TypeMask value) {
    // TODO(39874): Remove cache when [TypeMask.isDisjoint] is faster.
    var result = _isInterceptorCache[value];
    if (result == null) {
      result = _isInterceptorCacheSecondChance[value] ?? _isInterceptor(value);
      if (_isInterceptorCache.length >= _kIsInterceptorCacheLimit) {
        _isInterceptorCacheSecondChance = _isInterceptorCache;
        _isInterceptorCache = {};
      }
      _isInterceptorCache[value] = result;
    }
    return result;
  }

  AbstractBool _isInterceptor(TypeMask value) {
    return AbstractBool.maybeOrFalse(
        !interceptorType.isDisjoint(value, _closedWorld));
  }

  static const _kIsInterceptorCacheLimit = 500;
  Map<TypeMask, AbstractBool> _isInterceptorCache = {};
  Map<TypeMask, AbstractBool> _isInterceptorCacheSecondChance = {};

  @override
  bool isMap(TypeMask value) {
    return value.isMap;
  }

  @override
  bool isSet(TypeMask value) {
    return value.isSet;
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
  AbstractValue createSetValue(AbstractValue forwardTo, Object allocationNode,
      MemberEntity allocationElement, AbstractValue elementType) {
    return new SetTypeMask(
        forwardTo, allocationNode, allocationElement, elementType);
  }

  @override
  AbstractValue getSetElementType(AbstractValue value) {
    if (value is SetTypeMask) {
      return value.elementType ?? dynamicType;
    }
    return dynamicType;
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
  AbstractValue getAbstractValueForNativeMethodParameterType(DartType type) {
    if (type is InterfaceType) {
      if (type.typeArguments.isNotEmpty) return null;
      // TODO(sra): Consider using a strengthened type check to avoid passing
      // `null` to primitive types since the native methods usually have
      // non-nullable primitive parameter types.
      return createNullableSubtype(type.element);
    }
    if (type is DynamicType) return dynamicType;
    // TODO(sra): Convert other [DartType]s to [AbstractValue]s
    return null;
  }

  @override
  String getCompactText(AbstractValue value) {
    return formatType(dartTypes, value);
  }

  @override
  TypeMask readAbstractValueFromDataSource(DataSource source) {
    return source.readCached<TypeMask>(
        () => new TypeMask.readFromDataSource(source, this));
  }

  @override
  void writeAbstractValueToDataSink(DataSink sink, covariant TypeMask value) {
    sink.writeCached<TypeMask>(
        value, (TypeMask value) => value.writeToDataSink(sink));
  }
}

/// Convert the given TypeMask to a compact string format.
///
/// The default format is too verbose for the graph format since long strings
/// create oblong nodes that obstruct the graph layout.
String formatType(DartTypes dartTypes, TypeMask type) {
  if (type is FlatTypeMask) {
    // TODO(asgerf): Disambiguate classes whose name is not unique. Using the
    //     library name for all classes is not a good idea, since library names
    //     can be really long and mess up the layout.
    // Capitalize Null to emphasize that it's the null type mask and not
    // a null value we accidentally printed out.
    if (type.isEmptyOrNull) return type.isNullable ? 'Null' : 'Empty';
    String nullFlag = type.isNullable ? '?' : '';
    String subFlag = type.isExact
        ? ''
        : type.isSubclass
            ? '+'
            : '*';
    return '${type.base.name}$nullFlag$subFlag';
  }
  if (type is UnionTypeMask) {
    return type.disjointMasks.map((m) => formatType(dartTypes, m)).join(' | ');
  }
  if (type is ContainerTypeMask) {
    String container = formatType(dartTypes, type.forwardTo);
    String member = formatType(dartTypes, type.elementType);
    return '$container<$member>';
  }
  if (type is MapTypeMask) {
    String container = formatType(dartTypes, type.forwardTo);
    String key = formatType(dartTypes, type.keyType);
    String value = formatType(dartTypes, type.valueType);
    return '$container<$key,$value>';
  }
  if (type is ValueTypeMask) {
    String baseType = formatType(dartTypes, type.forwardTo);
    String value = type.value.toStructuredText(dartTypes);
    return '$baseType=$value';
  }
  return '$type'; // Fall back on toString if not supported here.
}
