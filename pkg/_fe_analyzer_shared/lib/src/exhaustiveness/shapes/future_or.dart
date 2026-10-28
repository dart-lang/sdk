// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../types.dart';

/// [Shape] for the values of a `FutureOr<T>` type for some type `T`.
///
/// This is a sealed shape where the subshapes are the shape for `T` and the
/// shape for `Future<T>`.
class FutureOrShape<Type extends Object> extends TypeBasedShape<Type> {
  /// The shape for `T`.
  final Shape _typeArgumentShape;

  /// The shape for `Future<T>`.
  final Shape _futureShape;

  new(
    super.typeOperations,
    super.propertyLookup,
    super.type,
    this._typeArgumentShape,
    this._futureShape, {
    required super.isImplicitlyNullable,
  });

  @override
  bool get isSealed => true;

  @override
  Iterable<Shape> getSubshapes(Set<Key> keysOfInterest) => [
    _typeArgumentShape,
    _futureShape,
  ];
}
