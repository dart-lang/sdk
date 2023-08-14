// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../types.dart';

/// [StaticType] for the `bool` type.
class BoolStaticType<Type extends Object> extends TypeBasedStaticType<Type> {
  BoolStaticType(super.typeOperations, super.fieldLookup, super.type)
      : super(isImplicitlyNullable: false);

  @override
  bool get isSealed => true;

  late StaticType trueType = new _BoolValueStaticType<Type>(
      _typeOperations, _fieldLookup, _type, true);

  late StaticType falseType = new _BoolValueStaticType<Type>(
      _typeOperations, _fieldLookup, _type, false);

  @override
  Iterable<StaticType> getSubtypes(Set<Key> keysOfInterest) =>
      [trueType, falseType];
}

/// [StaticType] for an object restricted to a single boolean value (either
/// `true` or `false`).
class _BoolValueStaticType<Type extends Object>
    extends ValueStaticType<Type, bool> {
  final bool _value;

  _BoolValueStaticType(TypeOperations<Type> typeOperations,
      FieldLookup<Type> fieldLookup, Type type, this._value)
      : super(typeOperations, fieldLookup, type,
            new IdentityRestriction<bool>(_value), '$_value');

  @override
  void valueToDart(DartTemplateBuffer buffer) {
    buffer.writeBoolValue(_value);
  }
}
