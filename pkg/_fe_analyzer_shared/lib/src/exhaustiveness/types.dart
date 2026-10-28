// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart_template_buffer.dart';
import 'key.dart';
import 'shape.dart';
import 'shared.dart';
import 'space.dart';
import 'witness.dart';

part 'shapes/bool.dart';
part 'shapes/enum.dart';
part 'shapes/future_or.dart';
part 'shapes/list.dart';
part 'shapes/map.dart';
part 'shapes/record.dart';
part 'shapes/sealed.dart';

/// [Shape] based on a non-nullable [Type].
///
/// All [Shape] implementations in this library are based on [Type] through
/// this class. Additionally, the `shape.dart` library has fixed [Shape]
/// implementations for `Object`, `Null`, `Never` and nullable shapes.
// TODO(johnniwinther): Extract an `AtomicShape` from this class and make this
// abstract base.
class TypeBasedShape<Type extends Object> extends NonNullableShape {
  final TypeOperations<Type> _typeOperations;
  final PropertyLookup<Type> _propertyLookup;
  final Type _type;
  @override
  final bool isImplicitlyNullable;

  new(
    this._typeOperations,
    this._propertyLookup,
    this._type, {
    required this.isImplicitlyNullable,
  });

  @override
  Map<Key, Shape> get properties => _propertyLookup.getPropertyShapes(_type);

  @override
  Shape? getAdditionalPropertyShape(Key key) =>
      _propertyLookup.getAdditionalPropertyShape(_type, key);

  /// Returns a [Restriction] value for shapes that determines subshapes of
  /// the [_type]. For instance individual elements of an enum.
  Restriction get restriction => const Unrestricted();

  @override
  bool isSubshapeOfInternal(Shape other) {
    return other is TypeBasedShape<Type> &&
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
    return other is TypeBasedShape<Type> &&
        _type == other._type &&
        restriction == other.restriction;
  }

  Type get typeForTesting => _type;

  @override
  void witnessToDart(
    DartTemplateBuffer buffer,
    PropertyWitness witness,
    Map<Key, PropertyWitness> witnessProperties, {
    required bool forCorrection,
  }) {
    if (!_typeOperations.hasSimpleName(_type)) {
      buffer.write(name);
      buffer.write(' _');

      // If we have restrictions on the shape we create an and-pattern.
      String additionalStart = ' && Object(';
      String additionalEnd = '';
      String comma = '';
      for (MapEntry<Key, PropertyWitness> entry in witnessProperties.entries) {
        Key key = entry.key;
        if (key is! ListKey) {
          buffer.write(additionalStart);
          additionalStart = '';
          additionalEnd = ')';
          buffer.write(comma);
          comma = ', ';

          buffer.write(key.name);
          buffer.write(': ');
          PropertyWitness property = entry.value;
          property.witnessToDart(buffer, forCorrection: forCorrection);
        }
      }
      buffer.write(additionalEnd);
    } else {
      super.witnessToDart(
        buffer,
        witness,
        witnessProperties,
        forCorrection: forCorrection,
      );
    }
  }

  @override
  void shapeToDart(DartTemplateBuffer buffer) {
    buffer.writeGeneralType(_type, name);
  }

  @override
  Future<bool> isAccessible(DartAccessibility accessibility) {
    return accessibility.isTypeAccessible(_type, name);
  }

  @override
  bool get isEnumSubshape => _typeOperations.isEnum(_type);

  @override
  Uri? get libraryUri => _typeOperations.libraryUri(_type);

  @override
  bool get isPrivate => name.startsWith('_');
}

/// [Shape] for an object restricted by its [restriction].
abstract class RestrictedShape<
  Type extends Object,
  Identity extends Restriction
>
    extends TypeBasedShape<Type> {
  @override
  final Identity restriction;

  @override
  final String name;

  new(
    super.typeOperations,
    super.propertyLookup,
    super.type,
    this.restriction,
    this.name,
  ) : super(isImplicitlyNullable: false);
}

/// [Shape] for an object restricted to a single value, where that value is
/// a general-purpose value (not a boolean or an enum).
class GeneralValueShape<Type extends Object, T extends Object>
    extends ValueShape<Type, T> {
  final T _value;

  @override
  void valueToDart(DartTemplateBuffer buffer) {
    buffer.writeGeneralConstantValue(_value, name);
  }

  new(
    super.typeOperations,
    super.propertyLookup,
    super.type,
    super.restriction,
    super.name,
    this._value,
  );
}

/// [Shape] for an object restricted to a single value.
abstract class ValueShape<Type extends Object, T extends Object>
    extends RestrictedShape<Type, IdentityRestriction<T>> {
  void valueToDart(DartTemplateBuffer buffer);

  new(
    super.typeOperations,
    super.propertyLookup,
    super.type,
    super.restriction,
    super.name,
  );

  @override
  void witnessToDart(
    DartTemplateBuffer buffer,
    PropertyWitness witness,
    Map<Key, PropertyWitness> witnessProperties, {
    required bool forCorrection,
  }) {
    valueToDart(buffer);

    // If we have restrictions on the value we create an and pattern.
    String additionalStart = ' && Object(';
    String additionalEnd = '';
    String comma = '';
    for (MapEntry<Key, PropertyWitness> entry in witnessProperties.entries) {
      Key key = entry.key;
      if (key is! RecordKey) {
        buffer.write(additionalStart);
        additionalStart = '';
        additionalEnd = ')';
        buffer.write(comma);
        comma = ', ';

        buffer.write(key.name);
        buffer.write(': ');
        PropertyWitness field = entry.value;
        field.witnessToDart(buffer, forCorrection: forCorrection);
      }
    }
    buffer.write(additionalEnd);
  }
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
  const new();

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

  const new(this.identity);

  @override
  bool get isUnrestricted => false;

  @override
  bool isSubtypeOf(TypeOperations<Object> typeOperations, Restriction other) =>
      other.isUnrestricted ||
      other is IdentityRestriction<Identity> && identity == other.identity;
}
