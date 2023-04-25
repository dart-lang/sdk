// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../types.dart';

/// [StaticType] for a list type which can be divided into subtypes of
/// [ListPatternStaticType].
///
/// This is used to support exhaustiveness checking for list types by
/// contextually dividing the list into relevant cases for checking.
///
/// For instance, the exhaustiveness can be achieved by a single pattern
///
///     case [...]:
///
/// or by two disjoint patterns:
///
///     case []:
///     case [_, ...]:
///
/// When checking for exhaustiveness, witness candidates are created and tested
/// against the available cases. This means that the chosen candidates must be
/// matched by at least one case or the candidate is considered a witness of
/// non-exhaustiveness.
///
/// Looking at the first example, we could choose `[...]`, the list of
/// arbitrary size, as a candidate. This works for the first example, since the
/// case `[...]` matches the list of arbitrary size. But if we tried to use this
/// on the second example it would fail, since neither `[]` nor `[_, ...]` fully
/// matches the list of arbitrary size.
///
/// A solution could be to choose candidates `[]` and `[_, ...]`, the empty list
/// and the list of 1 or more elements. This would work for the first example,
/// since `[...]` matches both the empty list and the list of 1 or more
/// elements. It also works for the second example, since `[]` matches the empty
/// list and `[_, ...]` matches the list of 1 or more elements.
///
/// But now comes a third way of exhaustively matching a list:
///
///     case []:
///     case [_]:
///     case [_, _, ...]:
///
/// and our candidates no longer work, since while `[]` does match the empty
/// list, neither `[_]` nor `[_, _, ...]` matches the list of 1 or more
/// elements.
///
/// This shows us that there can be no fixed set of witness candidates that we
/// can use to match a list type.
///
/// What we do instead, is to create the set of witness candidates based on the
/// cases that should match it. We find the maximal number, n, of fixed, i.e.
/// non-rest, elements in the cases, and then create the lists of sizes 0 to n-1
/// and the list of n or more elements as the witness candidates.
class ListTypeStaticType<Type extends Object>
    extends TypeBasedStaticType<Type> {
  ListTypeStaticType(super.typeOperations, super.fieldLookup, super.type)
      : super(isImplicitlyNullable: false);

  @override
  bool get isSealed => true;

  @override
  Iterable<StaticType> getSubtypes(Set<Key> keysOfInterest) {
    int maxHeadSize = 0;
    int maxTailSize = 0;
    for (Key key in keysOfInterest) {
      if (key is HeadKey) {
        if (key.index >= maxHeadSize) {
          maxHeadSize = key.index + 1;
        }
      } else if (key is TailKey) {
        if (key.index >= maxTailSize) {
          maxTailSize = key.index + 1;
        }
      }
    }
    int maxSize = maxHeadSize + maxTailSize;
    List<StaticType> subtypes = [];
    Type elementType = _typeOperations.getListElementType(_type)!;
    String typeArgumentText;
    if (_typeOperations.isDynamic(elementType)) {
      typeArgumentText = '';
    } else {
      typeArgumentText = '<${_typeOperations.typeToString(elementType)}>';
    }
    for (int size = 0; size < maxSize; size++) {
      ListTypeRestriction<Type> identity = new ListTypeRestriction(
          elementType, typeArgumentText,
          size: size, hasRest: false);
      subtypes.add(new ListPatternStaticType<Type>(
          _typeOperations, _fieldLookup, _type, identity, identity.toString()));
    }
    ListTypeRestriction<Type> identity = new ListTypeRestriction(
        elementType, typeArgumentText,
        size: maxSize, hasRest: true);
    subtypes.add(new ListPatternStaticType<Type>(
        _typeOperations, _fieldLookup, _type, identity, identity.toString()));
    return subtypes;
  }
}

/// [StaticType] for a list pattern type using a [ListTypeRestriction] for its
/// uniqueness.
class ListPatternStaticType<Type extends Object>
    extends RestrictedStaticType<Type, ListTypeRestriction<Type>> {
  ListPatternStaticType(super.typeOperations, super.fieldLookup, super.type,
      super.restriction, super.name);

  @override
  String spaceToText(Map<Key, Space> spaceProperties,
      Map<Key, Space> additionalSpaceProperties) {
    StringBuffer buffer = new StringBuffer();
    buffer.write(restriction.typeArgumentText);
    buffer.write('[');

    bool first = true;
    additionalSpaceProperties.forEach((Key key, Space space) {
      if (!first) buffer.write(', ');
      if (key is RestKey) {
        buffer.write('...');
      }
      buffer.write(space);
      first = false;
    });

    buffer.write(']');
    return buffer.toString();
  }

  @override
  void witnessToDart(DartTemplateBuffer buffer, PropertyWitness witness,
      Map<Key, PropertyWitness> witnessFields,
      {required bool forCorrection}) {
    int maxHeadSize = 0;
    int maxTailSize = 0;
    PropertyWitness? restWitness;
    for (MapEntry<Key, PropertyWitness> entry in witnessFields.entries) {
      Key key = entry.key;
      if (key is HeadKey && key.index >= maxHeadSize) {
        maxHeadSize = key.index + 1;
      } else if (key is TailKey && key.index >= maxHeadSize) {
        maxTailSize = key.index + 1;
      } else if (key is RestKey) {
        // TODO(johnniwinther): Can the rest key have head/tail sizes that don't
        // match the found max head/tail sizes?
        restWitness = entry.value;
      }
    }
    if (maxHeadSize + maxTailSize < restriction.size) {
      maxHeadSize = restriction.size - maxTailSize;
    }
    buffer.write('[');
    String comma = '';
    for (int index = 0; index < maxHeadSize; index++) {
      buffer.write(comma);
      Key key = new HeadKey(index);
      PropertyWitness? witness = witnessFields[key];
      if (witness != null) {
        witness.witnessToDart(buffer, forCorrection: forCorrection);
      } else {
        buffer.write('_');
      }
      comma = ', ';
    }
    if (restriction.hasRest) {
      buffer.write(comma);
      buffer.write('...');
      if (restWitness != null) {
        restWitness.witnessToDart(buffer, forCorrection: forCorrection);
      }
      comma = ', ';
    }
    for (int index = maxTailSize - 1; index >= 0; index--) {
      buffer.write(comma);
      Key key = new TailKey(index);
      PropertyWitness? witness = witnessFields[key];
      if (witness != null) {
        witness.witnessToDart(buffer, forCorrection: forCorrection);
      } else {
        buffer.write('_');
      }
      comma = ', ';
    }
    buffer.write(']');

    // If we have restrictions on the record type we create an and pattern.
    String additionalStart = ' && Object(';
    String additionalEnd = '';
    comma = '';
    for (MapEntry<Key, PropertyWitness> entry in witnessFields.entries) {
      Key key = entry.key;
      if (key is! ListKey) {
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

/// Restriction object used for creating a unique [ListPatternStaticType] for a
/// list pattern.
///
/// The uniqueness is defined by the element type, the number of elements at the
/// start of the list, whether the list pattern has a rest element, and the
/// number elements at the end of the list, after the rest element.
class ListTypeRestriction<Type extends Object> implements Restriction<Type> {
  final Type elementType;
  final int size;
  final bool hasRest;
  final String typeArgumentText;

  ListTypeRestriction(this.elementType, this.typeArgumentText,
      {required this.size, required this.hasRest});

  @override
  late final int hashCode = Object.hash(elementType, size, hasRest);

  @override
  bool get isUnrestricted {
    // The map pattern containing only a rest pattern covers the whole type.
    return hasRest && size == 0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ListTypeRestriction<Type> &&
        elementType == other.elementType &&
        size == other.size &&
        hasRest == other.hasRest;
  }

  @override
  bool isSubtypeOf(TypeOperations<Type> typeOperations, Restriction other) {
    if (other.isUnrestricted) return true;
    if (other is! ListTypeRestriction<Type>) return false;
    if (!typeOperations.isSubtypeOf(elementType, other.elementType)) {
      return false;
    }
    if (other.hasRest) {
      return size >= other.size;
    } else if (hasRest) {
      return false;
    } else {
      return size == other.size;
    }
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(typeArgumentText);
    sb.write('[');
    String comma = '';
    for (int i = 0; i < size; i++) {
      sb.write(comma);
      sb.write('()');
      comma = ', ';
    }
    if (hasRest) {
      sb.write(comma);
      sb.write('...');
      comma = ', ';
    }
    sb.write(']');
    return sb.toString();
  }
}
