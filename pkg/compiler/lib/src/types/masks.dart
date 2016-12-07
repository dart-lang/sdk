// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library masks;

import '../common.dart';
import '../common/backend_api.dart' show BackendClasses;
import '../compiler.dart' show Compiler;
import '../constants/values.dart' show PrimitiveConstantValue;
import '../elements/elements.dart';
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

  TypeMask get dynamicType => _dynamicType ??=
      new TypeMask.subclass(closedWorld.coreClasses.objectClass, closedWorld);

  TypeMask get nonNullType => _nonNullType ??= new TypeMask.nonNullSubclass(
      closedWorld.coreClasses.objectClass, closedWorld);

  TypeMask get intType => _intType ??= new TypeMask.nonNullSubclass(
      backendClasses.intImplementation, closedWorld);

  TypeMask get uint32Type => _uint32Type ??= new TypeMask.nonNullSubclass(
      backendClasses.uint32Implementation, closedWorld);

  TypeMask get uint31Type => _uint31Type ??= new TypeMask.nonNullExact(
      backendClasses.uint31Implementation, closedWorld);

  TypeMask get positiveIntType =>
      _positiveIntType ??= new TypeMask.nonNullSubclass(
          backendClasses.positiveIntImplementation, closedWorld);

  TypeMask get doubleType => _doubleType ??= new TypeMask.nonNullExact(
      backendClasses.doubleImplementation, closedWorld);

  TypeMask get numType => _numType ??= new TypeMask.nonNullSubclass(
      backendClasses.numImplementation, closedWorld);

  TypeMask get boolType => _boolType ??=
      new TypeMask.nonNullExact(backendClasses.boolImplementation, closedWorld);

  TypeMask get functionType => _functionType ??= new TypeMask.nonNullSubtype(
      backendClasses.functionImplementation, closedWorld);

  TypeMask get listType => _listType ??=
      new TypeMask.nonNullExact(backendClasses.listImplementation, closedWorld);

  TypeMask get constListType => _constListType ??= new TypeMask.nonNullExact(
      backendClasses.constListImplementation, closedWorld);

  TypeMask get fixedListType => _fixedListType ??= new TypeMask.nonNullExact(
      backendClasses.fixedListImplementation, closedWorld);

  TypeMask get growableListType =>
      _growableListType ??= new TypeMask.nonNullExact(
          backendClasses.growableListImplementation, closedWorld);

  TypeMask get mapType => _mapType ??= new TypeMask.nonNullSubtype(
      backendClasses.mapImplementation, closedWorld);

  TypeMask get constMapType => _constMapType ??= new TypeMask.nonNullSubtype(
      backendClasses.constMapImplementation, closedWorld);

  TypeMask get stringType => _stringType ??= new TypeMask.nonNullExact(
      backendClasses.stringImplementation, closedWorld);

  TypeMask get typeType => _typeType ??=
      new TypeMask.nonNullExact(backendClasses.typeImplementation, closedWorld);

  TypeMask get syncStarIterableType =>
      _syncStarIterableType ??= new TypeMask.nonNullExact(
          backendClasses.syncStarIterableImplementation, closedWorld);

  TypeMask get asyncFutureType =>
      _asyncFutureType ??= new TypeMask.nonNullExact(
          backendClasses.asyncFutureImplementation, closedWorld);

  TypeMask get asyncStarStreamType =>
      _asyncStarStreamType ??= new TypeMask.nonNullExact(
          backendClasses.asyncStarStreamImplementation, closedWorld);

  // TODO(johnniwinther): Assert that the null type has been resolved.
  TypeMask get nullType => _nullType ??= const TypeMask.empty();
}
