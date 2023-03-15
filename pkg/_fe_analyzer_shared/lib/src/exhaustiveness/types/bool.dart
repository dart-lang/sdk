// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../types.dart';

/// [StaticType] for the `bool` type.
class BoolStaticType<Type extends Object> extends TypeBasedStaticType<Type> {
  BoolStaticType(super.typeOperations, super.fieldLookup, super.type);

  @override
  bool get isSealed => true;

  late StaticType trueType =
      new RestrictedStaticType<Type, IdentityRestriction<bool>>(_typeOperations,
          _fieldLookup, _type, const IdentityRestriction<bool>(true), 'true');

  late StaticType falseType =
      new RestrictedStaticType<Type, IdentityRestriction<bool>>(_typeOperations,
          _fieldLookup, _type, const IdentityRestriction<bool>(false), 'false');

  @override
  Iterable<StaticType> getSubtypes(Set<Key> keysOfInterest) =>
      [trueType, falseType];
}
