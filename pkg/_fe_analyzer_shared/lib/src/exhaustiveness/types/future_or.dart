// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../types.dart';

/// [StaticType] for a `FutureOr<T>` type for some type `T`.
///
/// This is a sealed type where the subtypes for are `T` and `Future<T>`.
class FutureOrStaticType<Type extends Object>
    extends TypeBasedStaticType<Type> {
  /// The type for `T`.
  final StaticType _typeArgument;

  /// The type for `Future<T>`.
  final StaticType _futureType;

  FutureOrStaticType(super.typeOperations, super.fieldLookup, super.type,
      this._typeArgument, this._futureType,
      {required super.isImplicitlyNullable});

  @override
  bool get isSealed => true;

  @override
  Iterable<StaticType> getSubtypes(Set<Key> keysOfInterest) =>
      [_typeArgument, _futureType];
}
