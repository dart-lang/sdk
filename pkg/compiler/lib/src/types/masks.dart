// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library masks;

import '../common.dart';
import '../common/backend_api.dart' show Backend;
import '../compiler.dart' show Compiler;
import '../constants/values.dart' show PrimitiveConstantValue;
import '../elements/elements.dart';
import '../inferrer/type_graph_inferrer.dart' show TypeGraphInferrer;
import '../tree/tree.dart';
import '../universe/selector.dart' show Selector;
import '../universe/universe.dart'
    show
        ReceiverConstraint,
        UniverseSelectorConstraints,
        SelectorConstraintsStrategy;
import '../util/util.dart';
import '../world.dart' show ClosedWorld, ClosedWorld;
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
  final Compiler compiler;

  CommonMasks(this.compiler);

  ClosedWorld get closedWorld => compiler.closedWorld;

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
      compiler.backend.intImplementation, closedWorld);

  TypeMask get uint32Type => _uint32Type ??= new TypeMask.nonNullSubclass(
      compiler.backend.uint32Implementation, closedWorld);

  TypeMask get uint31Type => _uint31Type ??= new TypeMask.nonNullExact(
      compiler.backend.uint31Implementation, closedWorld);

  TypeMask get positiveIntType =>
      _positiveIntType ??= new TypeMask.nonNullSubclass(
          compiler.backend.positiveIntImplementation, closedWorld);

  TypeMask get doubleType => _doubleType ??= new TypeMask.nonNullExact(
      compiler.backend.doubleImplementation, closedWorld);

  TypeMask get numType => _numType ??= new TypeMask.nonNullSubclass(
      compiler.backend.numImplementation, closedWorld);

  TypeMask get boolType => _boolType ??= new TypeMask.nonNullExact(
      compiler.backend.boolImplementation, closedWorld);

  TypeMask get functionType => _functionType ??= new TypeMask.nonNullSubtype(
      compiler.backend.functionImplementation, closedWorld);

  TypeMask get listType => _listType ??= new TypeMask.nonNullExact(
      compiler.backend.listImplementation, closedWorld);

  TypeMask get constListType => _constListType ??= new TypeMask.nonNullExact(
      compiler.backend.constListImplementation, closedWorld);

  TypeMask get fixedListType => _fixedListType ??= new TypeMask.nonNullExact(
      compiler.backend.fixedListImplementation, closedWorld);

  TypeMask get growableListType =>
      _growableListType ??= new TypeMask.nonNullExact(
          compiler.backend.growableListImplementation, closedWorld);

  TypeMask get mapType => _mapType ??= new TypeMask.nonNullSubtype(
      compiler.backend.mapImplementation, closedWorld);

  TypeMask get constMapType => _constMapType ??= new TypeMask.nonNullSubtype(
      compiler.backend.constMapImplementation, closedWorld);

  TypeMask get stringType => _stringType ??= new TypeMask.nonNullExact(
      compiler.backend.stringImplementation, closedWorld);

  TypeMask get typeType => _typeType ??= new TypeMask.nonNullExact(
      compiler.backend.typeImplementation, closedWorld);

  TypeMask get syncStarIterableType =>
      _syncStarIterableType ??= new TypeMask.nonNullExact(
          compiler.backend.syncStarIterableImplementation, closedWorld);

  TypeMask get asyncFutureType =>
      _asyncFutureType ??= new TypeMask.nonNullExact(
          compiler.backend.asyncFutureImplementation, closedWorld);

  TypeMask get asyncStarStreamType =>
      _asyncStarStreamType ??= new TypeMask.nonNullExact(
          compiler.backend.asyncStarStreamImplementation, closedWorld);

  // TODO(johnniwinther): Assert that the null type has been resolved.
  TypeMask get nullType => _nullType ??= const TypeMask.empty();
}
