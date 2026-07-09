// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library;

import 'package:collection/collection.dart';
import 'package:js_shared/variance.dart';
import 'package:kernel/ast.dart' as ir;

import '../../common.dart';
import '../../common/elements.dart' show CommonElements;
import '../../common/metrics.dart';
import '../../common/names.dart';
import '../../constants/values.dart';
import '../../elements/entities.dart';
import '../../elements/names.dart';
import '../../elements/types.dart';
import '../../js_model/js_world.dart' show JClosedWorld;
import '../../serialization/serialization.dart';
import '../../universe/class_hierarchy.dart';
import '../../universe/member_hierarchy.dart';
import '../../universe/record_shape.dart';
import '../../universe/selector.dart' show Selector;
import '../../universe/use.dart' show DynamicUse;
import '../../universe/world_builder.dart'
    show UniverseSelectorConstraints, SelectorConstraintsStrategy;
import '../../util/bitset.dart';
import '../../util/enumset.dart';
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
  final JClosedWorld closedWorld;
  final _PowersetCache _powersetCache;

  CommonMasks(this.closedWorld) : _powersetCache = _PowersetCache(closedWorld);

  ClassHierarchy get classHierarchy => closedWorld.classHierarchy;
  CommonElements get commonElements => closedWorld.commonElements;
  DartTypes get dartTypes => closedWorld.dartTypes;

  final Map<TypeMask, Map<TypeMask, TypeMask>> _intersectionCache = {};

  final Map<(ClassEntity?, _Flags), FlatTypeMask> _canonicalizedTypeMasks = {};

  /// Return the cached mask for [base] with the given flags, or calls
  /// [createMask] to create the mask and cache it.
  FlatTypeMask _getCachedMask(
    ClassEntity? base,
    _Flags flags,
    FlatTypeMask Function() createMask,
  ) => _canonicalizedTypeMasks.putIfAbsent((base, flags), createMask);

  @override
  late final TypeMask internalTopType = TypeMask.subclass(
    closedWorld.commonElements.objectClass,
    this,
    hasLateSentinel: true,
  );

  @override
  late final TypeMask dynamicType = TypeMask.subclass(
    closedWorld.commonElements.objectClass,
    this,
  );

  @override
  late final TypeMask nonNullType = TypeMask.nonNullSubclass(
    closedWorld.commonElements.objectClass,
    this,
  );

  @override
  late final TypeMask intType = TypeMask.nonNullSubclass(
    commonElements.jsIntClass,
    this,
  );

  @override
  late final TypeMask uint32Type = TypeMask.nonNullSubclass(
    commonElements.jsUInt32Class,
    this,
  );

  @override
  late final TypeMask uint31Type = TypeMask.nonNullExact(
    commonElements.jsUInt31Class,
    this,
  );

  @override
  late final TypeMask positiveIntType = TypeMask.nonNullSubclass(
    commonElements.jsPositiveIntClass,
    this,
  );

  @override
  late final TypeMask numNotIntType = TypeMask.nonNullExact(
    commonElements.jsNumNotIntClass,
    this,
  );

  @override
  late final TypeMask numType = TypeMask.nonNullSubclass(
    commonElements.jsNumberClass,
    this,
  );

  @override
  late final TypeMask boolType = TypeMask.nonNullExact(
    commonElements.jsBoolClass,
    this,
  );

  @override
  late final TypeMask functionType = TypeMask.nonNullSubtype(
    commonElements.functionClass,
    this,
  );

  // TODO(50701): Use:
  //
  //     TypeMask.nonNullSubtype(commonElements.recordClass, _closedWorld);
  //
  // This will require either (1) open reasoning on the as-yet undefined
  // subtypes of Record or (2) several live subtypes of Record. Everything
  // 'works' for the similar interface `Function` because there are multiple
  // live subclasses of `Closure`.
  @override
  late final TypeMask recordType = nonNullType;

  @override
  late final TypeMask listType = TypeMask.nonNullSubtype(
    commonElements.jsArrayClass,
    this,
  );

  @override
  late final TypeMask constListType = TypeMask.nonNullExact(
    commonElements.jsUnmodifiableArrayClass,
    this,
  );

  @override
  late final TypeMask fixedListType = TypeMask.nonNullExact(
    commonElements.jsFixedArrayClass,
    this,
  );

  @override
  late final TypeMask growableListType = TypeMask.nonNullExact(
    commonElements.jsExtendableArrayClass,
    this,
  );

  @override
  late final TypeMask setType = TypeMask.nonNullSubtype(
    commonElements.setLiteralClass,
    this,
  );

  @override
  late final TypeMask constSetType = TypeMask.nonNullSubtype(
    commonElements.constSetLiteralClass,
    this,
  );

  @override
  late final TypeMask mapType = TypeMask.nonNullSubtype(
    commonElements.mapLiteralClass,
    this,
  );

  @override
  late final TypeMask constMapType = TypeMask.nonNullSubtype(
    commonElements.constMapLiteralClass,
    this,
  );

  @override
  late final TypeMask stringType = TypeMask.nonNullExact(
    commonElements.jsStringClass,
    this,
  );

  @override
  late final TypeMask typeType = TypeMask.nonNullExact(
    commonElements.typeLiteralClass,
    this,
  );

  @override
  late final TypeMask syncStarIterableType = TypeMask.nonNullExact(
    commonElements.syncStarIterable,
    this,
  );

  @override
  late final TypeMask asyncFutureType = TypeMask.nonNullExact(
    commonElements.futureImplementation,
    this,
  );

  @override
  late final TypeMask asyncStarStreamType = TypeMask.nonNullExact(
    commonElements.controllerStream,
    this,
  );

  @override
  late final TypeMask nullType = TypeMask.empty(this);

  @override
  TypeMask get lateSentinelType =>
      TypeMask.nonNullEmpty(this, hasLateSentinel: true);

  @override
  TypeMask get emptyType => TypeMask.nonNullEmpty(this);

  late final TypeMask readableArrayType = TypeMask.nonNullSubclass(
    commonElements.jsArrayClass,
    this,
  );

  @override
  late final TypeMask mutableArrayType = TypeMask.nonNullSubclass(
    commonElements.jsMutableArrayClass,
    this,
  );

  late final TypeMask unmodifiableArrayType = TypeMask.nonNullExact(
    commonElements.jsUnmodifiableArrayClass,
    this,
  );

  late final TypeMask interceptorType = TypeMask.nonNullSubclass(
    commonElements.jsInterceptorClass,
    this,
  );

  @override
  AbstractBool isTypedArray(TypeMask mask) {
    // Just checking for `TypedData` is not sufficient, as it is an abstract
    // class any user-defined class can implement. So we also check for the
    // interface `JavaScriptIndexingBehavior`.
    ClassEntity typedDataClass = closedWorld.commonElements.typedDataClass;
    return AbstractBool.trueOrMaybe(
      closedWorld.classHierarchy.isInstantiated(typedDataClass) &&
          mask.satisfies(typedDataClass, closedWorld) &&
          mask.satisfies(
            closedWorld.commonElements.jsIndexingBehaviorInterface,
            closedWorld,
          ),
    );
  }

  @override
  AbstractBool couldBeTypedArray(TypeMask mask) {
    bool intersects(TypeMask type1, TypeMask type2) =>
        !type1.intersection(type2, this).isEmpty;
    // TODO(herhut): Maybe cache the TypeMask for typedDataClass and
    //               jsIndexingBehaviourInterface.
    ClassEntity typedDataClass = closedWorld.commonElements.typedDataClass;
    return AbstractBool.maybeOrFalse(
      closedWorld.classHierarchy.isInstantiated(typedDataClass) &&
          intersects(mask, TypeMask.subtype(typedDataClass, this)) &&
          intersects(
            mask,
            TypeMask.subtype(
              closedWorld.commonElements.jsIndexingBehaviorInterface,
              this,
            ),
          ),
    );
  }

  @override
  TypeMask createNonNullExact(ClassEntity cls) {
    return TypeMask.nonNullExact(cls, this);
  }

  @override
  TypeMask createNullableExact(ClassEntity cls) {
    return TypeMask.exact(cls, this);
  }

  @override
  TypeMask createNonNullSubclass(ClassEntity cls) {
    return TypeMask.nonNullSubclass(cls, this);
  }

  @override
  TypeMask createNonNullSubtype(ClassEntity cls) {
    return TypeMask.nonNullSubtype(cls, this);
  }

  @override
  TypeMask createNullableSubtype(ClassEntity cls) {
    return TypeMask.subtype(cls, this);
  }

  @override
  AbstractValueWithPrecision createFromStaticType(DartType type) {
    if (dartTypes.isTopType(type)) {
      // A cone of a top type includes all values.
      return AbstractValueWithPrecision(dynamicType, true);
    }

    if (type is NullableType) {
      return _createFromStaticType(type.baseType, true);
    }

    return _createFromStaticType(type, false);
  }

  AbstractValueWithPrecision _createFromStaticType(
    DartType type,
    bool nullable,
  ) {
    AbstractValueWithPrecision finish(TypeMask value, bool isPrecise) {
      return AbstractValueWithPrecision(
        nullable ? value.nullable(this) : value,
        isPrecise,
      );
    }

    bool isPrecise = true;
    while (type is TypeVariableType) {
      TypeVariableType typeVariable = type;
      type = closedWorld.elementEnvironment.getTypeVariableBound(
        typeVariable.element,
      );
      isPrecise = false;
      if (type is NullableType) {
        // <A extends B?, B extends num>  ...  null is A --> can be `true`.
        // <A extends B, B extends num?>  ...  null is A --> can be `true`.
        nullable = true;
        type = type.withoutNullability;
      }
    }

    if (dartTypes.isTopType(type)) {
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
      return finish(TypeMask.nonNullSubtype(cls, this), isPrecise);
    }

    if (type is FunctionType) {
      return finish(
        TypeMask.nonNullSubtype(commonElements.functionClass, this),
        false,
      );
    }

    if (type is RecordType) {
      final types = <TypeMask>[];
      final shape = type.shape;
      final fields = type.fields;
      for (final field in fields) {
        final fieldType = createFromStaticType(field);
        types.add(fieldType.abstractValue as TypeMask);
        isPrecise &= fieldType.isPrecise;
      }
      return finish(
        RecordTypeMask.createRecord(this, types, shape, isNullable: nullable),
        isPrecise,
      );
    }

    if (type is NeverType) {
      return finish(emptyType, isPrecise);
    }

    return AbstractValueWithPrecision(dynamicType, false);
  }

  @override
  TypeMask excludeNull(TypeMask mask) => mask.nonNullable(this);

  @override
  TypeMask includeNull(TypeMask mask) => mask.nullable(this);

  @override
  TypeMask excludeLateSentinel(TypeMask mask) => mask.withoutLateSentinel(this);

  @override
  TypeMask includeLateSentinel(TypeMask mask) => mask.withLateSentinel(this);

  @override
  AbstractBool containsType(TypeMask typeMask, ClassEntity cls) {
    return AbstractBool.trueOrFalse(_containsType(typeMask, cls));
  }

  bool _containsType(TypeMask typeMask, ClassEntity cls) {
    return closedWorld.classHierarchy.isInstantiated(cls) &&
        typeMask.contains(cls, closedWorld);
  }

  @override
  AbstractBool containsOnlyType(TypeMask typeMask, ClassEntity cls) {
    return AbstractBool.trueOrMaybe(_containsOnlyType(typeMask, cls));
  }

  bool _containsOnlyType(TypeMask typeMask, ClassEntity cls) {
    return closedWorld.classHierarchy.isInstantiated(cls) &&
        typeMask.containsOnly(cls);
  }

  bool _isInstanceOfOrNull(TypeMask typeMask, ClassEntity cls) {
    return closedWorld.isImplemented(cls) &&
        typeMask.satisfies(cls, closedWorld);
  }

  @override
  AbstractBool isInstanceOf(
    covariant TypeMask expressionMask,
    ClassEntity cls,
  ) {
    final typeMask = (cls == commonElements.nullClass)
        ? nullType
        : createNonNullSubtype(cls);
    if (expressionMask.union(typeMask, this) == typeMask) {
      return AbstractBool.true_;
    } else if (expressionMask.isDisjoint(typeMask, closedWorld)) {
      return AbstractBool.false_;
    } else {
      return AbstractBool.maybe;
    }
  }

  @override
  AbstractBool isEmpty(TypeMask value) =>
      AbstractBool.trueOrMaybe(value.isEmpty);

  @override
  AbstractBool isExact(TypeMask value) => AbstractBool.trueOrMaybe(
    value.isExact && !value.isNullable && !value.hasLateSentinel,
  );

  @override
  ClassEntity? getExactClass(TypeMask mask) {
    return mask.singleClass(closedWorld);
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
    covariant TypeMask originalValue,
    PrimitiveConstantValue value,
  ) {
    return ValueTypeMask(originalValue, value);
  }

  @override
  AbstractBool isNull(TypeMask value) {
    if (value.isNull) {
      return AbstractBool.true_;
    } else if (value.isNullable) {
      return AbstractBool.maybe;
    } else {
      return AbstractBool.false_;
    }
  }

  @override
  AbstractBool isLateSentinel(TypeMask value) => value.isLateSentinel;

  @override
  AbstractBool isPrimitive(TypeMask value) {
    return AbstractBool.maybeOrFalse(
      _canBePrimitiveNumber(value) ||
          _canBePrimitiveArray(value) ||
          _canBePrimitiveBoolean(value) ||
          _canBePrimitiveString(value) ||
          value.isNull,
    );
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
      AbstractBool.trueOrMaybe(value.containsOnlyString(closedWorld)) |
      isJsIndexable(value);

  @override
  AbstractBool isMutableIndexable(TypeMask value) {
    final powerset = value.powerset;

    if (_indexableDomain.containsSingle(
      powerset,
      TypeMaskIndexableProperty.mutableIndexable,
    )) {
      return AbstractBool.true_;
    }

    if (!_indexableDomain.contains(
      powerset,
      TypeMaskIndexableProperty.mutableIndexable,
    )) {
      return AbstractBool.false_;
    }

    return AbstractBool.maybe;
  }

  @override
  AbstractBool isModifiableArray(TypeMask value) {
    final powerset = value.powerset;

    if (_arrayDomain.containsOnly(
      powerset,
      TypeMaskArrayProperty._modifiableEnumSet,
    )) {
      return AbstractBool.true_;
    }

    if (_arrayDomain.containsOnly(
      powerset,
      TypeMaskArrayProperty._unmodifiableEnumSet,
    )) {
      return AbstractBool.false_;
    }

    return AbstractBool.maybe;
  }

  @override
  AbstractBool isGrowableArray(TypeMask value) {
    final powerset = value.powerset;

    if (_arrayDomain.containsOnly(
      powerset,
      TypeMaskArrayProperty._growableEnumSet,
    )) {
      return AbstractBool.true_;
    }

    if (_arrayDomain.containsOnly(
      powerset,
      TypeMaskArrayProperty._fixedLengthEnumSet,
    )) {
      return AbstractBool.false_;
    }

    return AbstractBool.maybe;
  }

  @override
  AbstractBool isArray(TypeMask value) {
    return AbstractBool.trueOrMaybe(
      _isInstanceOfOrNull(value, commonElements.jsArrayClass),
    );
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
      value.containsOnlyInt(closedWorld) &&
          !value.isNullable &&
          !value.hasLateSentinel,
    );
  }

  @override
  AbstractBool isUInt32(TypeMask value) {
    return AbstractBool.trueOrMaybe(
      !value.isNullable &&
          !value.hasLateSentinel &&
          _isInstanceOfOrNull(value, commonElements.jsUInt32Class),
    );
  }

  @override
  AbstractBool isUInt31(TypeMask value) {
    return AbstractBool.trueOrMaybe(
      !value.isNullable &&
          !value.hasLateSentinel &&
          _isInstanceOfOrNull(value, commonElements.jsUInt31Class),
    );
  }

  @override
  AbstractBool isPositiveInteger(TypeMask value) {
    return AbstractBool.trueOrMaybe(
      !value.isNullable &&
          !value.hasLateSentinel &&
          _isInstanceOfOrNull(value, commonElements.jsPositiveIntClass),
    );
  }

  @override
  AbstractBool isPositiveIntegerOrNull(TypeMask value) {
    return AbstractBool.trueOrMaybe(
      _isInstanceOfOrNull(value, commonElements.jsPositiveIntClass),
    );
  }

  @override
  AbstractBool isIntegerOrNull(TypeMask value) {
    return AbstractBool.trueOrMaybe(value.containsOnlyInt(closedWorld));
  }

  @override
  AbstractBool isNumber(TypeMask value) {
    return AbstractBool.trueOrMaybe(
      value.containsOnlyNum(closedWorld) &&
          !value.isNullable &&
          !value.hasLateSentinel,
    );
  }

  @override
  AbstractBool isNumberOrNull(TypeMask value) =>
      AbstractBool.trueOrMaybe(_isNumberOrNull(value));

  bool _isNumberOrNull(TypeMask value) {
    return value.containsOnlyNum(closedWorld);
  }

  @override
  AbstractBool isBoolean(TypeMask value) {
    return AbstractBool.trueOrMaybe(
      value.containsOnlyBool(closedWorld) &&
          !value.isNullable &&
          !value.hasLateSentinel,
    );
  }

  @override
  AbstractBool isBooleanOrNull(TypeMask value) =>
      AbstractBool.trueOrMaybe(_isBooleanOrNull(value));

  bool _isBooleanOrNull(TypeMask value) {
    return value.containsOnlyBool(closedWorld);
  }

  @override
  AbstractBool isTruthy(TypeMask value) {
    if (value is ValueTypeMask && !value.isNullable && !value.hasLateSentinel) {
      PrimitiveConstantValue constant = value.value;
      if (constant is BoolConstantValue) {
        return constant.boolValue ? AbstractBool.true_ : AbstractBool.false_;
      }
    }
    // TODO(sra): Non-intercepted types are generally JavaScript falsy values.
    return AbstractBool.maybe;
  }

  @override
  AbstractBool isString(TypeMask value) {
    return AbstractBool.trueOrMaybe(
      value.containsOnlyString(closedWorld) &&
          !value.isNullable &&
          !value.hasLateSentinel,
    );
  }

  @override
  AbstractBool isStringOrNull(TypeMask value) {
    return AbstractBool.trueOrMaybe(value.containsOnlyString(closedWorld));
  }

  @override
  AbstractBool isPrimitiveOrNull(TypeMask value) =>
      AbstractBool.trueOrMaybe(_isPrimitiveOrNull(value));

  bool _isIndexable(TypeMask value) => !_indexableDomain.contains(
    value.powerset,
    TypeMaskIndexableProperty.notIndexable,
  );

  bool _isIndexablePrimitive(TypeMask value) =>
      value.containsOnlyString(closedWorld) || _isIndexable(value);

  bool _isPrimitiveOrNull(TypeMask value) =>
      _isIndexablePrimitive(value) ||
      _isNumberOrNull(value) ||
      _isBooleanOrNull(value) ||
      value.isNull;

  @override
  TypeMask union(TypeMask a, TypeMask b) => a.union(b, this);

  @override
  TypeMask intersection(TypeMask a, TypeMask b) => a.intersection(b, this);

  @override
  AbstractBool areDisjoint(TypeMask a, TypeMask b) =>
      AbstractBool.trueOrMaybe(a.isDisjoint(b, closedWorld));

  @override
  AbstractBool containsAll(TypeMask a) =>
      AbstractBool.maybeOrFalse(a.containsAll(closedWorld));

  @override
  AbstractValue computeAbstractValueForConstant(ConstantValue value) {
    return computeTypeMask(this, value);
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
    int? length,
  ) {
    return ContainerTypeMask(
      forwardTo,
      allocationNode,
      allocationElement,
      elementType,
      length,
    );
  }

  @override
  AbstractValue unionOfMany(Iterable<AbstractValue> values) {
    var result = TypeMask.nonNullEmpty(this);
    for (final value in values) {
      result = result.union(value as TypeMask, this);
    }
    return result;
  }

  @override
  AbstractValue computeReceiver(Iterable<MemberEntity> members) {
    assert(
      closedWorld.classHierarchy.hasAnyStrictSubclass(
        closedWorld.commonElements.objectClass,
      ),
    );
    return TypeMask.unionOf(
      members
          .expand((MemberEntity element) {
            final cls = element.enclosingClass!;
            return [cls, ...closedWorld.mixinUsesOf(cls)];
          })
          .map((cls) {
            if (closedWorld.commonElements.jsNullClass == cls) {
              return TypeMask.empty(this);
            } else if (closedWorld.classHierarchy.isInstantiated(cls)) {
              return TypeMask.nonNullSubclass(cls, this);
            } else {
              // TODO(johnniwinther): Avoid the need for this case.
              return TypeMask.empty(this);
            }
          }),
      this,
    );
  }

  @override
  AbstractBool isTargetingMember(
    covariant TypeMask receiver,
    MemberEntity member,
    Name name,
  ) {
    return AbstractBool.maybeOrFalse(receiver.canHit(member, name, this));
  }

  @override
  AbstractBool needsNoSuchMethodHandling(
    covariant TypeMask receiver,
    Selector selector,
  ) {
    return AbstractBool.trueOrFalse(
      receiver.needsNoSuchMethodHandling(selector, closedWorld),
    );
  }

  @override
  AbstractBool isIn(covariant TypeMask subset, covariant TypeMask superset) {
    return AbstractBool.trueOrMaybe(subset.isInMask(superset, this));
  }

  @override
  MemberEntity? locateSingleMember(
    covariant TypeMask receiver,
    Selector selector,
  ) {
    return receiver.locateSingleMember(selector, this);
  }

  @override
  AbstractBool isJsIndexable(TypeMask mask) {
    final powerset = mask.powerset;

    if (_isIndexable(mask)) return AbstractBool.true_;

    if (_indexableDomain.containsSingle(
      powerset,
      TypeMaskIndexableProperty.notIndexable,
    )) {
      return AbstractBool.false_;
    }

    return AbstractBool.maybe;
  }

  @override
  AbstractBool isJsIndexableAndIterable(covariant TypeMask mask) {
    return AbstractBool.trueOrMaybe(
      _isIndexable(mask) &&
          // String is indexable but not iterable.
          !mask.satisfies(
            closedWorld.commonElements.jsStringClass,
            closedWorld,
          ),
    );
  }

  @override
  AbstractBool isFixedLengthJsIndexable(covariant TypeMask mask) {
    if (mask is ContainerTypeMask && mask.length != null) {
      // A container on which we have inferred the length.
      return AbstractBool.true_;
    }
    // TODO(sra): Recognize any combination of fixed length indexables.
    if (_arrayDomain.containsOnly(
          mask.powerset,
          TypeMaskArrayProperty._fixedLengthEnumSet,
        ) ||
        mask.containsOnlyString(closedWorld) ||
        isTypedArray(mask).isDefinitelyTrue) {
      return AbstractBool.true_;
    }
    return AbstractBool.maybe;
  }

  @override
  AbstractBool isInterceptor(TypeMask value) {
    final powerset = value.powerset;

    if (!_interceptorDomain.contains(
      powerset,
      TypeMaskInterceptorProperty.interceptor,
    )) {
      return AbstractBool.false_;
    }

    if (!_interceptorDomain.contains(
      powerset,
      TypeMaskInterceptorProperty.notInterceptor,
    )) {
      return AbstractBool.true_;
    }

    return AbstractBool.maybe;
  }

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
    final result = value is DictionaryTypeMask
        ? value.getValueForKey(key)
        : null;
    return result ?? dynamicType;
  }

  @override
  AbstractValue createMapValue(
    covariant TypeMask forwardTo,
    covariant ir.Node? allocationNode,
    MemberEntity? allocationElement,
    covariant TypeMask key,
    covariant TypeMask value,
  ) {
    return MapTypeMask(
      forwardTo,
      allocationNode,
      allocationElement,
      key,
      value,
    );
  }

  @override
  AbstractValue createDictionaryValue(
    covariant TypeMask forwardTo,
    covariant ir.Node? allocationNode,
    MemberEntity? allocationElement,
    covariant TypeMask key,
    covariant TypeMask value,
    Map<String, AbstractValue> mappings,
  ) {
    return DictionaryTypeMask(
      forwardTo,
      allocationNode,
      allocationElement,
      key,
      value,
      Map.from(mappings),
    );
  }

  @override
  AbstractValue createRecordValue(
    RecordShape shape,
    List<AbstractValue> types,
  ) {
    return RecordTypeMask.createRecord(
      this,
      List.from(types, growable: false),
      shape,
    );
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
    covariant TypeMask elementType,
  ) {
    return SetTypeMask(
      forwardTo,
      allocationNode,
      allocationElement,
      elementType,
    );
  }

  @override
  AbstractValue getSetElementType(AbstractValue value) {
    final result = value is SetTypeMask ? value.elementType : null;
    return result ?? dynamicType;
  }

  @override
  bool isSpecializationOf(
    AbstractValue specialization,
    AbstractValue generalization,
  ) {
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
  Iterable<DynamicCallTarget> findRootsOfTargets(
    covariant TypeMask receiver,
    Selector selector,
    MemberHierarchyBuilder memberHierarchyBuilder,
  ) {
    return receiver.findRootsOfTargets(
      selector,
      memberHierarchyBuilder,
      closedWorld,
    );
  }

  @override
  bool isInvalidRefinement(
    covariant TypeMask before,
    covariant TypeMask after,
  ) {
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
    //
    // Note: [UnionTypeMask.isInMask] can return false negatives. We have to
    // ensure we take the conservative action when we get a false negative and
    // treat those as valid refinements. Invoking `after.isInMask` instead of
    // `!before.isInMask` ensures that the false negatives are handled
    // correctly.
    return after is UnionTypeMask && after.isInMask(before, this);
  }

  @override
  TypeMask readAbstractValueFromDataSource(DataSourceReader source) {
    return source.readIndexed<TypeMask>(
      () => TypeMask.readFromDataSource(source, this),
    );
  }

  @override
  void writeAbstractValueToDataSink(
    DataSinkWriter sink,
    covariant TypeMask value,
  ) {
    sink.writeIndexed<TypeMask>(
      value,
      (TypeMask value) => value.writeToDataSink(sink),
    );
  }

  @override
  Metrics get metrics => _metrics;
  final _metrics = _CommonMaskMetrics();

  @override
  void finalizeMetrics() {
    _metrics.intersectionCacheTop.add(_intersectionCache.length);
    _metrics.intersectionCacheTotal.add(
      _intersectionCache.values.fold(0, (p, e) => p + e.length),
    );
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
    if (type.isEmptyOrSpecial) {
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
  Iterable<Metric> get secondary => [
    intersectionCacheTop,
    intersectionCacheTotal,
  ];
}
