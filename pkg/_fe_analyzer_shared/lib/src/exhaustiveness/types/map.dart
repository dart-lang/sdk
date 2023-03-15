// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../types.dart';

/// [StaticType] for a map pattern type using a [MapTypeIdentity] for its
/// uniqueness.
class MapPatternStaticType<Type extends Object>
    extends RestrictedStaticType<Type, MapTypeIdentity<Type>> {
  MapPatternStaticType(super.typeOperations, super.fieldLookup, super.type,
      super.restriction, super.name);

  @override
  String spaceToText(
      Map<String, Space> spaceFields, Map<Key, Space> additionalSpaceFields) {
    StringBuffer buffer = new StringBuffer();
    buffer.write(restriction.typeArgumentsText);
    buffer.write('{');

    bool first = true;
    additionalSpaceFields.forEach((Key key, Space space) {
      if (!first) buffer.write(', ');
      buffer.write('$key: $space');
      first = false;
    });
    if (restriction.hasRest) {
      if (!first) buffer.write(', ');
      buffer.write('...');
    }

    buffer.write('}');
    return buffer.toString();
  }
}

/// Identity object used for creating a unique [MapPatternStaticType] for a
/// map pattern.
///
/// The uniqueness is defined by the key and value types, the key values of
/// the map pattern, and whether the map pattern has a rest element.
///
/// This identity ensures that we can detect overlap between map patterns with
/// the same set of keys.
class MapTypeIdentity<Type extends Object> implements Restriction<Type> {
  final Type keyType;
  final Type valueType;
  final Set<MapKey> keys;
  final bool hasRest;
  final String typeArgumentsText;

  MapTypeIdentity(
      this.keyType, this.valueType, this.keys, this.typeArgumentsText,
      {required this.hasRest});

  @override
  late final int hashCode =
      Object.hash(keyType, valueType, Object.hashAllUnordered(keys), hasRest);

  @override
  bool get isUnrestricted {
    // The map pattern containing only a rest pattern covers the whole type.
    return hasRest && keys.isEmpty;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MapTypeIdentity<Type>) return false;
    if (keyType != other.keyType ||
        valueType != other.valueType ||
        hasRest != other.hasRest) {
      return false;
    }
    if (keys.length != other.keys.length) return false;
    return keys.containsAll(other.keys);
  }

  @override
  bool isSubtypeOf(TypeOperations<Type> typeOperations, Restriction other) {
    if (other.isUnrestricted) return true;
    if (other is! MapTypeIdentity<Type>) return false;
    if (!typeOperations.isSubtypeOf(keyType, other.keyType)) return false;
    if (!typeOperations.isSubtypeOf(valueType, other.valueType)) return false;
    if (other.hasRest) {
      return keys.containsAll(other.keys);
    } else if (hasRest) {
      return false;
    } else {
      return keys.length == other.keys.length && keys.containsAll(other.keys);
    }
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
    if (hasRest) {
      sb.write(comma);
      sb.write('...');
      comma = ', ';
    }
    sb.write('}');
    return sb.toString();
  }
}
