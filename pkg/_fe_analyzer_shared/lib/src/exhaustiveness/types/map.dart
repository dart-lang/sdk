// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../types.dart';

/// [StaticType] for a map pattern type using a [MapTypeRestriction] for its
/// uniqueness.
class MapPatternStaticType<Type extends Object>
    extends RestrictedStaticType<Type, MapTypeRestriction<Type>> {
  MapPatternStaticType(super.typeOperations, super.fieldLookup, super.type,
      super.restriction, super.name);

  @override
  String spaceToText(Map<Key, Space> spaceProperties,
      Map<Key, Space> additionalSpaceProperties) {
    StringBuffer buffer = new StringBuffer();
    buffer.write(restriction.typeArgumentsText);
    buffer.write('{');

    bool first = true;
    additionalSpaceProperties.forEach((Key key, Space space) {
      if (!first) buffer.write(', ');
      buffer.write('$key: $space');
      first = false;
    });

    buffer.write('}');
    return buffer.toString();
  }

  @override
  void witnessToDart(DartTemplateBuffer buffer, PropertyWitness witness,
      Map<Key, PropertyWitness> witnessFields,
      {required bool forCorrection}) {
    buffer.write('{');
    String comma = '';
    for (MapKey key in restriction.keys) {
      buffer.write(comma);
      buffer.write(key.valueAsText);
      buffer.write(': ');
      PropertyWitness? witness = witnessFields[key];
      if (witness != null) {
        witness.witnessToDart(buffer, forCorrection: forCorrection);
      } else {
        buffer.write('_');
      }
      comma = ', ';
    }
    buffer.write('}');

    // If we have restrictions on the record type we create an and pattern.
    String additionalStart = ' && Object(';
    String additionalEnd = '';
    comma = '';
    for (MapEntry<Key, PropertyWitness> entry in witnessFields.entries) {
      Key key = entry.key;
      if (key is! MapKey) {
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

/// Restriction object used for creating a unique [MapPatternStaticType] for a
/// map pattern.
///
/// The uniqueness is defined by the key and value types, the key values of
/// the map pattern, and whether the map pattern has a rest element.
///
/// This identity ensures that we can detect overlap between map patterns with
/// the same set of keys.
class MapTypeRestriction<Type extends Object> implements Restriction<Type> {
  final Type keyType;
  final Type valueType;
  final Set<MapKey> keys;
  final String typeArgumentsText;

  MapTypeRestriction(
      this.keyType, this.valueType, this.keys, this.typeArgumentsText);

  @override
  late final int hashCode =
      Object.hash(keyType, valueType, Object.hashAllUnordered(keys));

  @override
  bool get isUnrestricted {
    // The map pattern containing only a rest pattern covers the whole type.
    return keys.isEmpty;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MapTypeRestriction<Type>) return false;
    if (keyType != other.keyType || valueType != other.valueType) {
      return false;
    }
    if (keys.length != other.keys.length) return false;
    return keys.containsAll(other.keys);
  }

  @override
  bool isSubtypeOf(TypeOperations<Type> typeOperations, Restriction other) {
    if (other.isUnrestricted) return true;
    if (other is! MapTypeRestriction<Type>) return false;
    if (!typeOperations.isSubtypeOf(keyType, other.keyType)) return false;
    if (!typeOperations.isSubtypeOf(valueType, other.valueType)) return false;
    return keys.containsAll(other.keys);
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(typeArgumentsText);
    sb.write('{');
    String comma = '';
    for (MapKey key in keys) {
      sb.write(comma);
      sb.write(key);
      sb.write(': ()');
      comma = ', ';
    }
    sb.write('}');
    return sb.toString();
  }
}
