// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'key.dart';
import 'path.dart';
import 'static_type.dart';

/// The main pattern for matching types and destructuring.
///
/// It has a type which determines the type of values it contains. The type may
/// be [StaticType.nullableObject] to indicate that it doesn't filter by type.
///
/// It may also contain zero or more named fields. The pattern then only matches
/// values where the field values are matched by the corresponding field
/// patterns.
class SingleSpace {
  static final SingleSpace empty = new SingleSpace(StaticType.neverType);

  /// The type of values the pattern matches.
  final StaticType type;

  /// Any field subpatterns the pattern matches.
  final Map<String, Space> fields;

  /// Additional fields for map/list semantics.
  final Map<Key, Space> additionalFields;

  SingleSpace(this.type,
      {this.fields = const {}, this.additionalFields = const {}});

  @override
  late final int hashCode = Object.hash(
      type,
      Object.hashAllUnordered(fields.keys),
      Object.hashAllUnordered(fields.values));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SingleSpace) return false;
    if (type != other.type) return false;
    if (fields.length != other.fields.length) return false;
    if (fields.isNotEmpty) {
      for (MapEntry<String, Space> entry in fields.entries) {
        if (entry.value != other.fields[entry.key]) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  String toString() {
    return type.spaceToText(fields, additionalFields);
  }
}

/// A set of runtime values encoded as a union of [SingleSpace]s.
///
/// This is used to support logical-or patterns without having to eagerly
/// expand the subpatterns in the parent context.
class Space {
  /// The path of getters that led from the original matched value to value
  /// matched by this pattern. Used to generate a human-readable witness.
  final Path path;

  final List<SingleSpace> singleSpaces;

  /// Create an empty space.
  Space.empty(this.path) : singleSpaces = [SingleSpace.empty];

  Space(Path path, StaticType type,
      {Map<String, Space> fields = const {},
      Map<Key, Space> additionalFields = const {}})
      : this._(path, [
          new SingleSpace(type,
              fields: fields, additionalFields: additionalFields)
        ]);

  Space._(this.path, this.singleSpaces);

  factory Space.fromSingleSpaces(Path path, List<SingleSpace> singleSpaces) {
    Set<SingleSpace> singleSpacesSet = {};

    for (SingleSpace singleSpace in singleSpaces) {
      // Discard empty space.
      if (singleSpace == SingleSpace.empty) {
        continue;
      }

      singleSpacesSet.add(singleSpace);
    }

    List<SingleSpace> singleSpacesList = singleSpacesSet.toList();
    if (singleSpacesSet.isEmpty) {
      singleSpacesList.add(SingleSpace.empty);
    } else if (singleSpacesList.length == 2) {
      if (singleSpacesList[0].type == StaticType.nullType &&
          singleSpacesList[0].fields.isEmpty &&
          singleSpacesList[1].fields.isEmpty) {
        singleSpacesList = [new SingleSpace(singleSpacesList[1].type.nullable)];
      } else if (singleSpacesList[1].type == StaticType.nullType &&
          singleSpacesList[1].fields.isEmpty &&
          singleSpacesList[0].fields.isEmpty) {
        singleSpacesList = [new SingleSpace(singleSpacesList[0].type.nullable)];
      }
    }
    return new Space._(path, singleSpacesList);
  }

  Space union(Space other) {
    return new Space.fromSingleSpaces(
        path, [...singleSpaces, ...other.singleSpaces]);
  }

  @override
  String toString() => singleSpaces.join('|');
}
