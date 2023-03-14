// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'key.dart';
import 'shared.dart';
import 'space.dart';
import 'static_type.dart';

part 'types/bool.dart';
part 'types/enum.dart';
part 'types/future_or.dart';
part 'types/list.dart';
part 'types/map.dart';
part 'types/record.dart';
part 'types/sealed.dart';

/// [StaticType] based on a non-nullable [Type].
///
/// All [StaticType] implementation in this library are based on [Type] through
/// this class. Additionally, the `static_type.dart` library has fixed
/// [StaticType] implementations for `Object`, `Null`, `Never` and nullable
/// types.
class TypeBasedStaticType<Type extends Object> extends NonNullableStaticType {
  final TypeOperations<Type> _typeOperations;
  final FieldLookup<Type> _fieldLookup;
  final Type _type;

  TypeBasedStaticType(this._typeOperations, this._fieldLookup, this._type);

  @override
  Map<String, StaticType> get fields => _fieldLookup.getFieldTypes(_type);

  @override
  StaticType? getAdditionalField(Key key) =>
      _fieldLookup.getAdditionalFieldType(_type, key);

  /// Returns a [Restriction] value for static types the determines subtypes of
  /// the [_type]. For instance individual elements of an enum.
  Restriction get restriction => const Unrestricted();

  @override
  bool isSubtypeOfInternal(StaticType other) {
    return other is TypeBasedStaticType<Type> &&
        _typeOperations.isSubtypeOf(_type, other._type) &&
        restriction.isSubtypeOf(_typeOperations, other.restriction);
  }

  @override
  bool get isSealed => false;

  @override
  String get name => _typeOperations.typeToString(_type);

  @override
  int get hashCode => Object.hash(_type, restriction);

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    return other is TypeBasedStaticType<Type> &&
        _type == other._type &&
        restriction == other.restriction;
  }

  Type get typeForTesting => _type;
}

/// [StaticType] for an object restricted by its [restriction].
class RestrictedStaticType<Type extends Object, Identity extends Restriction>
    extends TypeBasedStaticType<Type> {
  @override
  final Identity restriction;

  @override
  final String name;

  RestrictedStaticType(super.typeOperations, super.fieldLookup, super.type,
      this.restriction, this.name);
}

/// Interface for a restriction within a subtype relation.
///
/// This is used for instance to model enum values within an enum type and
/// map patterns within a map type.
abstract class Restriction<Type extends Object> {
  /// Returns `true` if this [Restriction] covers the whole type.
  bool get isUnrestricted;

  /// Returns `true` if this restriction is a subtype of [other].
  bool isSubtypeOf(TypeOperations<Type> typeOperations, Restriction other);
}

/// The unrestricted [Restriction] that covers all values of a type.
class Unrestricted implements Restriction<Object> {
  const Unrestricted();

  @override
  bool get isUnrestricted => true;

  @override
  bool isSubtypeOf(TypeOperations<Object> typeOperations, Restriction other) =>
      other.isUnrestricted;
}

/// [Restriction] based a unique [identity] value.
class IdentityRestriction<Identity extends Object>
    implements Restriction<Object> {
  final Identity identity;

  const IdentityRestriction(this.identity);

  @override
  bool get isUnrestricted => false;

  @override
  bool isSubtypeOf(TypeOperations<Object> typeOperations, Restriction other) =>
      other.isUnrestricted ||
      other is IdentityRestriction<Identity> && identity == other.identity;
}
