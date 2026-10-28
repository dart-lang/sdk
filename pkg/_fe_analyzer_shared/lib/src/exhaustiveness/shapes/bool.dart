// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../types.dart';

/// [Shape] for both boolean values.
class BoolShape<Type extends Object> extends TypeBasedShape<Type> {
  new(super.typeOperations, super.propertyLookup, super.type)
    : super(isImplicitlyNullable: false);

  @override
  bool get isSealed => true;

  late Shape trueShape = new _BoolValueShape<Type>(
    _typeOperations,
    _propertyLookup,
    _type,
    true,
  );

  late Shape falseShape = new _BoolValueShape<Type>(
    _typeOperations,
    _propertyLookup,
    _type,
    false,
  );

  @override
  Iterable<Shape> getSubshapes(Set<Key> keysOfInterest) => [
    trueShape,
    falseShape,
  ];
}

/// [Shape] for an object restricted to a single boolean value (either
/// `true` or `false`).
class _BoolValueShape<Type extends Object> extends ValueShape<Type, bool> {
  final bool _value;

  new(
    TypeOperations<Type> typeOperations,
    PropertyLookup<Type> propertyLookup,
    Type type,
    this._value,
  ) : super(
        typeOperations,
        propertyLookup,
        type,
        new IdentityRestriction<bool>(_value),
        '$_value',
      );

  @override
  void valueToDart(DartTemplateBuffer buffer) {
    buffer.writeBoolValue(_value);
  }
}
