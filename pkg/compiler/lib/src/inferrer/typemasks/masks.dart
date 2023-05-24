// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library masks;

import 'package:kernel/ast.dart' as ir;

import '../../common.dart';
import '../../common/elements.dart' show CommonElements;
import '../../common/metrics.dart';
import '../../common/names.dart';
import '../../constants/values.dart';
import '../../elements/entities.dart';
import '../../elements/names.dart';
import '../../elements/types.dart';
import '../../ir/static_type.dart';
import '../../js_model/js_world.dart' show JClosedWorld;
import '../../serialization/serialization.dart';
import '../../universe/class_hierarchy.dart';
import '../../universe/member_hierarchy.dart';
import '../../universe/record_shape.dart';
import '../../universe/selector.dart' show Selector;
import '../../universe/use.dart' show DynamicUse;
import '../../universe/world_builder.dart'
    show UniverseSelectorConstraints, SelectorConstraintsStrategy;
import '../../util/util.dart';
import '../abstract_value_domain.dart';
import '../abstract_value_strategy.dart';
import 'constants.dart';

part 'container_type_mask.dart';
part 'dictionary_type_mask.dart';
part 'flat_type_mask.dart';
part 'forwarding_type_mask.dart';
part 'map_type_mask.dart';
part 'record_type_mask.dart';
part 'set_type_mask.dart';
part 'type_mask.dart';
part 'union_type_mask.dart';
part 'value_type_mask.dart';

class CommonMasks with AbstractValueDomain {
  // TODO(sigmund): once we split out the backend common elements, depend
  // directly on those instead.
  final JClosedWorld _closedWorld;

  CommonMasks(this._closedWorld);

  CommonElements get commonElements => _closedWorld.commonElements;
  DartTypes get dartTypes => _closedWorld.dartTypes;

  final Map<TypeMask, Map<TypeMask, TypeMask>> _intersectionCache = {};

  /// Cache of [FlatTypeMask]s grouped by the possible values of the
  /// `FlatTypeMask.flags` property.
  final List<Map<ClassEntity?, TypeMask>?> _canonicalizedTypeMasks =
      List.filled(
          _FlatTypeMaskKind.values.length << FlatTypeMask._USED_INDICES, null);

  /// Return the cached mask for [base] with the given flags, or
  /// calls [createMask] to create the mask and cache it.
  T getCachedMask<T extends TypeMask>(
      ClassEntity? base, int flags, T createMask()) {
    // `null` is a valid base so we allow it as a key in the map.
    final Map<ClassEntity?, TypeMask> cachedMasks =
        _canonicalizedTypeMasks[flags] ??= {};
    return cachedMasks.putIfAbsent(base, createMask) as T;
  }

  @override
  late final TypeMask internalTopType = TypeMask.subclass(
      _closedWorld.commonElements.objectClass, _closedWorld,
      hasLateSentinel: true);

  @override
  late final TypeMask dynamicType =
      TypeMask.subclass(_closedWorld.commonElements.objectClass, _closedWorld);

  @override
  late final TypeMask nonNullType = TypeMask.nonNullSubclass(
      _closedWorld.commonElements.objectClass, _closedWorld);

  @override
  late final TypeMask intType =
      TypeMask.nonNullSubclass(commonElements.jsIntClass, _closedWorld);

  @override
  late final TypeMask uint32Type =
      TypeMask.nonNullSubclass(commonElements.jsUInt32Class, _closedWorld);

  @override
  late final TypeMask uint31Type =
      TypeMask.nonNullExact(commonElements.jsUInt31Class, _closedWorld);

  @override
  late final TypeMask positiveIntType =
      TypeMask.nonNullSubclass(commonElements.jsPositiveIntClass, _closedWorld);

  @override
  late final TypeMask numNotIntType =
      TypeMask.nonNullExact(commonElements.jsNumNotIntClass, _closedWorld);

  @override
  late final TypeMask numType =
      TypeMask.nonNullSubclass(commonElements.jsNumberClass, _closedWorld);

  @override
  late final TypeMask boolType =
      TypeMask.nonNullExact(commonElements.jsBoolClass, _closedWorld);

  @override
  late final TypeMask functionType =
      TypeMask.nonNullSubtype(commonElements.functionClass, _closedWorld);

  @override
  // TODO(50701): Use:
  //
  //     TypeMask.nonNullSubtype(commonElements.recordClass, _closedWorld);
  //
  // This will require either (1) open reasoning on the as-yet undefined
  // subtypes of Record or (2) several live subtypes of Record. Everything
  // 'works' for the similar interface `Function` because there are multiple
  // live subclasses of `Closure`.
  late final TypeMask recordType = dynamicType;

  @override
  late final TypeMask listType =
      TypeMask.nonNullSubtype(commonElements.jsArrayClass, _closedWorld);

  @override
  late final TypeMask constListType = TypeMask.nonNullExact(
      commonElements.jsUnmodifiableArrayClass, _closedWorld);

  @override
  late final TypeMask fixedListType =
      TypeMask.nonNullExact(commonElements.jsFixedArrayClass, _closedWorld);

  @override
  late final TypeMask growableListType = TypeMask.nonNullExact(
      commonElements.jsExtendableArrayClass, _closedWorld);

  @override
  late final TypeMask setType =
      TypeMask.nonNullSubtype(commonElements.setLiteralClass, _closedWorld);

  @override
  late final TypeMask constSetType = TypeMask.nonNullSubtype(
      commonElements.constSetLiteralClass, _closedWorld);

  @override
  late final TypeMask mapType =
      TypeMask.nonNullSubtype(commonElements.mapLiteralClass, _closedWorld);

  @override
  late final TypeMask constMapType = TypeMask.nonNullSubtype(
      commonElements.constMapLiteralClass, _closedWorld);

  @override
  late final TypeMask stringType =
      TypeMask.nonNullExact(commonElements.jsStringClass, _closedWorld);

  @override
  late final TypeMask typeType =
      TypeMask.nonNullExact(commonElements.typeLiteralClass, _closedWorld);

  @override
  late final TypeMask syncStarIterableType =
      TypeMask.nonNullExact(commonElements.syncStarIterable, _closedWorld);

  @override
  late final TypeMask asyncFutureType =
      TypeMask.nonNullExact(commonElements.futureImplementation, _closedWorld);

  @override
  late final TypeMask asyncStarStreamType =
      TypeMask.nonNullExact(commonElements.controllerStream, _closedWorld);

  // TODO(johnniwinther): Assert that the null type has been resolved.
  @override
  late final TypeMask nullType = TypeMask.empty();

  @override
  TypeMask get lateSentinelType => TypeMask.nonNullEmpty(hasLateSentinel: true);

  @override
  TypeMask get emptyType => TypeMask.nonNullEmpty();

  late final TypeMask indexablePrimitiveType =
      TypeMask.nonNullSubtype(commonElements.jsIndexableClass, _closedWorld);

  late final TypeMask readableArrayType =
      TypeMask.nonNullSubclass(commonElements.jsArrayClass, _closedWorld);

  @override
  late final TypeMask mutableArrayType = TypeMask.nonNullSubclass(
      commonElements.jsMutableArrayClass, _closedWorld);

  late final TypeMask unmodifiableArrayType = TypeMask.nonNullExact(
      commonElements.jsUnmodifiableArrayClass, _closedWorld);

  late final TypeMask interceptorType =
      TypeMask.nonNullSubclass(commonElements.jsInterceptorClass, _closedWorld);

  @override
  AbstractBool isTypedArray(TypeMask mask) {
    // Just checking for `TypedData` is not sufficient, as it is an abstract
    // class any user-defined class can implement. So we also check for the
    // interface `JavaScriptIndexingBehavior`.
    ClassEntity typedDataClass = _closedWorld.commonElements.typedDataClass;
    return AbstractBool.trueOrMaybe(
        _closedWorld.classHierarchy.isInstantiated(typedDataClass) &&
            mask.satisfies(typedDataClass, _closedWorld) &&
            mask.satisfies(
                _closedWorld.commonElements.jsIndexingBehaviorInterface,
                _closedWorld));
  }

  @override
  AbstractBool couldBeTypedArray(TypeMask mask) {
    bool intersects(TypeMask type1, TypeMask type2) =>
        !type1.intersection(type2, this).isEmpty;
    // TODO(herhut): Maybe cache the TypeMask for typedDataClass and
    //               jsIndexingBehaviourInterface.
    ClassEntity typedDataClass = _closedWorld.commonElements.typedDataClass;
    return AbstractBool.maybeOrFalse(
        _closedWorld.classHierarchy.isInstantiated(typedDataClass) &&
            intersects(mask, TypeMask.subtype(typedDataClass, _closedWorld)) &&
            intersects(
                mask,
                TypeMask.subtype(
                    _closedWorld.commonElements.jsIndexingBehaviorInterface,
                    _closedWorld)));
  }

  @override
  TypeMask createNonNullExact(ClassEntity cls) {
    return TypeMask.nonNullExact(cls, _closedWorld);
  }

  @override
  TypeMask createNullableExact(ClassEntity cls) {
    return TypeMask.exact(cls, _closedWorld);
  }

  @override
  TypeMask createNonNullSubclass(ClassEntity cls) {
    return TypeMask.nonNullSubclass(cls, _closedWorld);
  }

  @override
  TypeMask createNonNullSubtype(ClassEntity cls) {
    return TypeMask.nonNullSubtype(cls, _closedWorld);
  }

  @override
  TypeMask createNullableSubtype(ClassEntity cls) {
    return TypeMask.subtype(cls, _closedWorld);
  }

  @override
  AbstractValueWithPrecision createFromStaticType(DartType type,
      {ClassRelation classRelation = ClassRelation.subtype,
      required bool nullable}) {
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
        // convenient check for instantiation to bounds.
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

    if (type is RecordType) {
      final types = <TypeMask>[];
      final shape = type.shape;
      final fields = type.fields;
      for (final field in fields) {
        final fieldType = createFromStaticType(field, nullable: nullable);
        types.add(fieldType.abstractValue as TypeMask);
        isPrecise &= fieldType.isPrecise;
      }
      return finish(
          RecordTypeMask.createRecord(this, types, shape,
              isNullable: nullable, hasLateSentinel: false),
          isPrecise);
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
  TypeMask excludeLateSentinel(TypeMask mask) =>
      mask.withFlags(hasLateSentinel: false);

  @override
  TypeMask includeLateSentinel(TypeMask mask) =>
      mask.withFlags(hasLateSentinel: true);

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
    final typeMask = (cls == commonElements.nullClass)
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
  AbstractBool isExact(TypeMask value) => AbstractBool.trueOrMaybe(
      value.isExact && !value.isNullable && !value.hasLateSentinel);

  @override
  ClassEntity? getExactClass(TypeMask mask) {
    return mask.singleClass(_closedWorld);
  }

  @override
  bool isPrimitiveValue(TypeMask value) => value is ValueTypeMask;

  @override
  PrimitiveConstantValue? getPrimitiveValue(TypeMask mask) {
    if (mask is ValueTypeMask) {
      return mask.value;
    }
    return null;
  }

  @override
  AbstractValue createPrimitiveValue(
      covariant TypeMask originalValue, PrimitiveConstantValue value) {
    return ValueTypeMask(originalValue, value);
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

  @override
  AbstractBool isLateSentinel(TypeMask value) => value.isLateSentinel;

  @override
  AbstractBool isPrimitive(TypeMask value) {
    return AbstractBool.maybeOrFalse(_canBePrimitiveNumber(value) ||
        _canBePrimitiveArray(value) ||
        _canBePrimitiveBoolean(value) ||
        _canBePrimitiveString(value) ||
        value.isNull);
  }

  @override
  AbstractBool isPrimitiveNumber(TypeMask value) =>
      AbstractBool.maybeOrFalse(_canBePrimitiveNumber(value));

  bool _canBePrimitiveNumber(TypeMask value) {
    // TODO(sra): It should be possible to test only jsNumNotIntClass and
    // jsUInt31Class, since all others are superclasses of these two.
    return _containsType(value, commonElements.jsNumberClass) ||
        _containsType(value, commonElements.jsIntClass) ||
        _containsType(value, commonElements.jsPositiveIntClass) ||
        _containsType(value, commonElements.jsUInt32Class) ||
        _containsType(value, commonElements.jsUInt31Class) ||
        _containsType(value, commonElements.jsNumNotIntClass);
  }

  @override
  AbstractBool isPrimitiveBoolean(TypeMask value) =>
      AbstractBool.maybeOrFalse(_canBePrimitiveBoolean(value));

  bool _canBePrimitiveBoolean(TypeMask value) {
    return _containsType(value, commonElements.jsBoolClass);
  }

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
    return AbstractBool.trueOrMaybe(value.containsOnlyInt(_closedWorld) &&
        !value.isNullable &&
        !value.hasLateSentinel);
  }

  @override
  AbstractBool isUInt32(TypeMask value) {
    return AbstractBool.trueOrMaybe(!value.isNullable &&
        !value.hasLateSentinel &&
        _isInstanceOfOrNull(value, commonElements.jsUInt32Class));
  }

  @override
  AbstractBool isUInt31(TypeMask value) {
    return AbstractBool.trueOrMaybe(!value.isNullable &&
        !value.hasLateSentinel &&
        _isInstanceOfOrNull(value, commonElements.jsUInt31Class));
  }

  @override
  AbstractBool isPositiveInteger(TypeMask value) {
    return AbstractBool.trueOrMaybe(!value.isNullable &&
        !value.hasLateSentinel &&
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
    return AbstractBool.trueOrMaybe(value.containsOnlyNum(_closedWorld) &&
        !value.isNullable &&
        !value.hasLateSentinel);
  }

  @override
  AbstractBool isNumberOrNull(TypeMask value) =>
      AbstractBool.trueOrMaybe(_isNumberOrNull(value));

  bool _isNumberOrNull(TypeMask value) {
    return value.containsOnlyNum(_closedWorld);
  }

  @override
  AbstractBool isBoolean(TypeMask value) {
    return AbstractBool.trueOrMaybe(value.containsOnlyBool(_closedWorld) &&
        !value.isNullable &&
        !value.hasLateSentinel);
  }

  @override
  AbstractBool isBooleanOrNull(TypeMask value) =>
      AbstractBool.trueOrMaybe(_isBooleanOrNull(value));

  bool _isBooleanOrNull(TypeMask value) {
    return value.containsOnlyBool(_closedWorld);
  }

  @override
  AbstractBool isTruthy(TypeMask value) {
    if (value is ValueTypeMask && !value.isNullable && !value.hasLateSentinel) {
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
    return AbstractBool.trueOrMaybe(value.containsOnlyString(_closedWorld) &&
        !value.isNullable &&
        !value.hasLateSentinel);
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
        value.isNull;
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
    return value is MapTypeMask ? value.valueType : dynamicType;
  }

  @override
  AbstractValue getContainerElementType(AbstractValue value) {
    return value is ContainerTypeMask ? value.elementType : dynamicType;
  }

  @override
  int? getContainerLength(AbstractValue value) {
    return value is ContainerTypeMask ? value.length : null;
  }

  @override
  AbstractValue createContainerValue(
      covariant TypeMask forwardTo,
      covariant ir.Node? allocationNode,
      MemberEntity? allocationElement,
      covariant TypeMask elementType,
      int? length) {
    return ContainerTypeMask(
        forwardTo, allocationNode, allocationElement, elementType, length);
  }

  @override
  AbstractValue unionOfMany(Iterable<AbstractValue> values) {
    var result = TypeMask.nonNullEmpty();
    for (final value in values) {
      result = result.union(value as TypeMask, this);
    }
    return result;
  }

  @override
  AbstractValue computeReceiver(Iterable<MemberEntity> members) {
    assert(_closedWorld.classHierarchy
        .hasAnyStrictSubclass(_closedWorld.commonElements.objectClass));
    return TypeMask.unionOf(
        members.expand((MemberEntity element) {
          final cls = element.enclosingClass!;
          return [cls]..addAll(_closedWorld.mixinUsesOf(cls));
        }).map((cls) {
          if (_closedWorld.commonElements.jsNullClass == cls) {
            return TypeMask.empty();
          } else if (_closedWorld.classHierarchy.isInstantiated(cls)) {
            return TypeMask.nonNullSubclass(cls, _closedWorld);
          } else {
            // TODO(johnniwinther): Avoid the need for this case.
            return TypeMask.empty();
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
  MemberEntity? locateSingleMember(
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
    if (mask is ContainerTypeMask && mask.length != null) {
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
  bool isMap(TypeMask value) => value is MapTypeMask;

  @override
  bool isSet(TypeMask value) => value is SetTypeMask;

  @override
  bool isContainer(TypeMask value) => value is ContainerTypeMask;

  @override
  bool isDictionary(TypeMask value) => value is DictionaryTypeMask;

  @override
  bool containsDictionaryKey(AbstractValue value, String key) {
    return value is DictionaryTypeMask && value.containsKey(key);
  }

  @override
  AbstractValue getDictionaryValueForKey(AbstractValue value, String key) {
    final result =
        value is DictionaryTypeMask ? value.getValueForKey(key) : null;
    return result ?? dynamicType;
  }

  @override
  AbstractValue createMapValue(
      covariant TypeMask forwardTo,
      covariant ir.Node? allocationNode,
      MemberEntity? allocationElement,
      covariant TypeMask key,
      covariant TypeMask value) {
    return MapTypeMask(
        forwardTo, allocationNode, allocationElement, key, value);
  }

  @override
  AbstractValue createDictionaryValue(
      covariant TypeMask forwardTo,
      covariant ir.Node? allocationNode,
      MemberEntity? allocationElement,
      covariant TypeMask key,
      covariant TypeMask value,
      Map<String, AbstractValue> mappings) {
    return DictionaryTypeMask(forwardTo, allocationNode, allocationElement, key,
        value, Map.from(mappings));
  }

  @override
  AbstractValue createRecordValue(
      RecordShape shape, List<AbstractValue> types) {
    return RecordTypeMask.createRecord(
        this, List.from(types, growable: false), shape);
  }

  @override
  bool isRecord(TypeMask value) {
    return value is RecordTypeMask;
  }

  @override
  bool recordHasGetter(AbstractValue value, String field) {
    return value is RecordTypeMask && value.shape.nameMatchesGetter(field);
  }

  @override
  AbstractValue getGetterTypeInRecord(AbstractValue value, String getterName) {
    if (value is RecordTypeMask) {
      final getterIndex = value.shape.indexOfGetterName(getterName);
      // Generated code can sometimes contain record accesses for invalid
      // getters.
      if (getterIndex >= 0) {
        return value.types[getterIndex];
      }
    }
    return dynamicType;
  }

  @override
  AbstractValue createSetValue(
      covariant TypeMask forwardTo,
      covariant ir.Node? allocationNode,
      MemberEntity? allocationElement,
      covariant TypeMask elementType) {
    return SetTypeMask(
        forwardTo, allocationNode, allocationElement, elementType);
  }

  @override
  AbstractValue getSetElementType(AbstractValue value) {
    final result = value is SetTypeMask ? value.elementType : null;
    return result ?? dynamicType;
  }

  @override
  bool isSpecializationOf(
      AbstractValue specialization, AbstractValue generalization) {
    return specialization is ForwardingTypeMask &&
        specialization.forwardTo == generalization;
  }

  @override
  Object? getAllocationNode(AbstractValue value) {
    return value is AllocationTypeMask ? value.allocationNode : null;
  }

  @override
  MemberEntity? getAllocationElement(AbstractValue value) {
    return value is AllocationTypeMask ? value.allocationElement : null;
  }

  @override
  AbstractValue? getGeneralization(AbstractValue? value) {
    return value is AllocationTypeMask ? value.forwardTo : null;
  }

  @override
  AbstractValue? getAbstractValueForNativeMethodParameterType(DartType type) {
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
  String getCompactText(covariant TypeMask value) {
    return formatType(dartTypes, value);
  }

  @override
  Iterable<DynamicCallTarget> findRootsOfTargets(covariant TypeMask receiver,
      Selector selector, MemberHierarchyBuilder memberHierarchyBuilder) {
    return receiver.findRootsOfTargets(
        selector, memberHierarchyBuilder, _closedWorld);
  }

  @override
  bool isValidRefinement(covariant TypeMask before, covariant TypeMask after) {
    // Consider a typegraph node which simply outputs the union of its inputs,
    // and suppose such a node has K inputs with types: A, B, C, and D. The
    // union would flatten to a common supertype, e.g. `Object`. However, a
    // refinement pass might widen C and D such that they now have the
    // same type, E. The union now no longer needs flattening and is instead
    // A | B | E, which is narrower than `Object` rather than wider.
    //
    // The violation of monotonicity described above can cause the type of a
    // given typegraph node to not converge when it is part of a graph cycle
    // (e.g. mutually recursive functions). The nodes in a cycle can end up
    // oscillating between the wider and narrower type if the refinement
    // ordering does not allow any one type to fully propagate through the
    // cycle. It would be expensive to detect when we are in this scenario and
    // handle it explicitly so instead we take the conservative approach and
    // always use the wider type.
    //
    // We could assert that every refine must be a widening
    // (i.e. omit UnionTypeMask type check). But since it is only the behavior
    // of UnionTypeMask that can lead to a narrowing, we save work by only doing
    // the subtype check when a UnionTypeMask is involved.
    return after is! UnionTypeMask || before.isInMask(after, _closedWorld);
  }

  @override
  TypeMask readAbstractValueFromDataSource(DataSourceReader source) {
    return source
        .readCached<TypeMask>(() => TypeMask.readFromDataSource(source, this));
  }

  @override
  void writeAbstractValueToDataSink(
      DataSinkWriter sink, covariant TypeMask value) {
    sink.writeCached<TypeMask>(
        value, (TypeMask value) => value.writeToDataSink(sink));
  }

  @override
  Metrics get metrics => _metrics;
  final _metrics = _CommonMaskMetrics();

  @override
  void finalizeMetrics() {
    _metrics.intersectionCacheTop.add(_intersectionCache.length);
    _metrics.intersectionCacheTotal
        .add(_intersectionCache.values.fold(0, (p, e) => p + e.length));
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
    if (type.isEmpty) return 'Empty';
    if (type.isEmptyOrFlagged) {
      return [
        if (type.isNullable) 'Null',
        if (type.hasLateSentinel) '\$',
      ].join('');
    }
    String nullFlag = type.isNullable ? '?' : '';
    String subFlag = type.isExact
        ? ''
        : type.isSubclass
            ? '+'
            : '*';
    String sentinelFlag = type.hasLateSentinel ? '\$' : '';
    return '${type.base!.name}$nullFlag$subFlag$sentinelFlag';
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

class _CommonMaskMetrics implements Metrics {
  final intersectionCacheTop = CountMetric('count.intersectionCacheTop');
  final intersectionCacheTotal = CountMetric('count.intersectionCacheTotal');

  @override
  String get namespace => 'CommonMasks';

  @override
  Iterable<Metric> get primary => const [];

  @override
  Iterable<Metric> get secondary =>
      [intersectionCacheTop, intersectionCacheTotal];
}
