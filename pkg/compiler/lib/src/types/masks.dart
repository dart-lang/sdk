// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library masks;

import '../common.dart';
import '../common/backend_api.dart' show BackendClasses;
import '../constants/values.dart' show PrimitiveConstantValue;
import '../elements/entities.dart';
import '../inferrer/type_graph_inferrer.dart' show TypeGraphInferrer;
import '../tree/tree.dart';
import '../universe/selector.dart' show Selector;
import '../universe/world_builder.dart'
    show
        ReceiverConstraint,
        UniverseSelectorConstraints,
        SelectorConstraintsStrategy;
import '../util/util.dart';
import '../world.dart' show ClassQuery, ClosedWorld;
import 'abstract_value_domain.dart' show AbstractValue;

part 'container_type_mask.dart';
part 'dictionary_type_mask.dart';
part 'flat_type_mask.dart';
part 'forwarding_type_mask.dart';
part 'map_type_mask.dart';
part 'type_mask.dart';
part 'union_type_mask.dart';
part 'value_type_mask.dart';

class CommonMasks {
  // TODO(sigmund): once we split out the backend common elements, depend
  // directly on those instead.
  final ClosedWorld closedWorld;

  CommonMasks(this.closedWorld);

  BackendClasses get backendClasses => closedWorld.backendClasses;

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
  TypeMask _fixedArrayType;
  TypeMask _extendableArrayType;
  TypeMask _unmodifiableArrayType;
  TypeMask _interceptorType;

  TypeMask get dynamicType => _dynamicType ??= new TypeMask.subclass(
      closedWorld.commonElements.objectClass, closedWorld);

  TypeMask get nonNullType => _nonNullType ??= new TypeMask.nonNullSubclass(
      closedWorld.commonElements.objectClass, closedWorld);

  TypeMask get intType => _intType ??=
      new TypeMask.nonNullSubclass(backendClasses.intClass, closedWorld);

  TypeMask get uint32Type => _uint32Type ??=
      new TypeMask.nonNullSubclass(backendClasses.uint32Class, closedWorld);

  TypeMask get uint31Type => _uint31Type ??=
      new TypeMask.nonNullExact(backendClasses.uint31Class, closedWorld);

  TypeMask get positiveIntType =>
      _positiveIntType ??= new TypeMask.nonNullSubclass(
          backendClasses.positiveIntClass, closedWorld);

  TypeMask get doubleType => _doubleType ??=
      new TypeMask.nonNullExact(backendClasses.doubleClass, closedWorld);

  TypeMask get numType => _numType ??=
      new TypeMask.nonNullSubclass(backendClasses.numClass, closedWorld);

  TypeMask get boolType => _boolType ??=
      new TypeMask.nonNullExact(backendClasses.boolClass, closedWorld);

  TypeMask get functionType => _functionType ??=
      new TypeMask.nonNullSubtype(backendClasses.functionClass, closedWorld);

  TypeMask get listType => _listType ??=
      new TypeMask.nonNullExact(backendClasses.listClass, closedWorld);

  TypeMask get constListType => _constListType ??=
      new TypeMask.nonNullExact(backendClasses.constListClass, closedWorld);

  TypeMask get fixedListType => _fixedListType ??=
      new TypeMask.nonNullExact(backendClasses.fixedListClass, closedWorld);

  TypeMask get growableListType => _growableListType ??=
      new TypeMask.nonNullExact(backendClasses.growableListClass, closedWorld);

  TypeMask get mapType => _mapType ??=
      new TypeMask.nonNullSubtype(backendClasses.mapClass, closedWorld);

  TypeMask get constMapType => _constMapType ??=
      new TypeMask.nonNullSubtype(backendClasses.constMapClass, closedWorld);

  TypeMask get stringType => _stringType ??=
      new TypeMask.nonNullExact(backendClasses.stringClass, closedWorld);

  TypeMask get typeType => _typeType ??=
      new TypeMask.nonNullExact(backendClasses.typeClass, closedWorld);

  TypeMask get syncStarIterableType =>
      _syncStarIterableType ??= new TypeMask.nonNullExact(
          backendClasses.syncStarIterableClass, closedWorld);

  TypeMask get asyncFutureType => _asyncFutureType ??=
      new TypeMask.nonNullExact(backendClasses.asyncFutureClass, closedWorld);

  TypeMask get asyncStarStreamType =>
      _asyncStarStreamType ??= new TypeMask.nonNullExact(
          backendClasses.asyncStarStreamClass, closedWorld);

  // TODO(johnniwinther): Assert that the null type has been resolved.
  TypeMask get nullType => _nullType ??= const TypeMask.empty();

  TypeMask get emptyType => const TypeMask.nonNullEmpty();

  TypeMask get indexablePrimitiveType => _indexablePrimitiveType ??=
      new TypeMask.nonNullSubtype(backendClasses.indexableClass, closedWorld);

  TypeMask get readableArrayType => _readableArrayType ??=
      new TypeMask.nonNullSubclass(backendClasses.listClass, closedWorld);

  TypeMask get mutableArrayType =>
      _mutableArrayType ??= new TypeMask.nonNullSubclass(
          backendClasses.mutableListClass, closedWorld);

  TypeMask get fixedArrayType => _fixedArrayType ??=
      new TypeMask.nonNullExact(backendClasses.fixedListClass, closedWorld);

  TypeMask get extendableArrayType => _extendableArrayType ??=
      new TypeMask.nonNullExact(backendClasses.growableListClass, closedWorld);

  TypeMask get unmodifiableArrayType => _unmodifiableArrayType ??=
      new TypeMask.nonNullExact(backendClasses.constListClass, closedWorld);

  TypeMask get interceptorType =>
      _interceptorType ??= new TypeMask.nonNullSubclass(
          backendClasses.interceptorClass, closedWorld);

  bool isTypedArray(TypeMask mask) {
    // Just checking for [:TypedData:] is not sufficient, as it is an
    // abstract class any user-defined class can implement. So we also
    // check for the interface [JavaScriptIndexingBehavior].
    ClassEntity typedDataClass = closedWorld.commonElements.typedDataClass;
    return typedDataClass != null &&
        closedWorld.isInstantiated(typedDataClass) &&
        mask.satisfies(typedDataClass, closedWorld) &&
        mask.satisfies(
            closedWorld.backendClasses.indexingBehaviorClass, closedWorld);
  }

  bool couldBeTypedArray(TypeMask mask) {
    bool intersects(TypeMask type1, TypeMask type2) =>
        !type1.intersection(type2, closedWorld).isEmpty;
    // TODO(herhut): Maybe cache the TypeMask for typedDataClass and
    //               jsIndexingBehaviourInterface.
    ClassEntity typedDataClass = closedWorld.commonElements.typedDataClass;
    return typedDataClass != null &&
        closedWorld.isInstantiated(typedDataClass) &&
        intersects(mask, new TypeMask.subtype(typedDataClass, closedWorld)) &&
        intersects(
            mask,
            new TypeMask.subtype(
                closedWorld.backendClasses.indexingBehaviorClass, closedWorld));
  }

  TypeMask createNonNullExact(ClassEntity cls) {
    return new TypeMask.nonNullExact(cls, closedWorld);
  }

  TypeMask createNonNullSubtype(ClassEntity cls) {
    return new TypeMask.nonNullSubtype(cls, closedWorld);
  }
}
