// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'key.dart';
import 'path.dart';
import 'shape.dart';

/// The main pattern for matching shapes and destructuring.
///
/// It has a shape which determines the values it contains. The shape may be
/// [Shape.nullableObject] to indicate that it doesn't filter by shape.
///
/// It may also contain zero or more named properties. The pattern then only
/// matches values where the property values are matched by the corresponding
/// property patterns.
class SingleSpace {
  static final SingleSpace empty = new SingleSpace(Shape.neverShape);

  /// The shape of the values the pattern matches.
  final Shape shape;

  /// Any property subpatterns the pattern matches.
  final Map<Key, Space> properties;

  /// Additional properties for map/list semantics.
  final Map<Key, Space> additionalProperties;

  new(
    this.shape, {
    this.properties = const {},
    this.additionalProperties = const {},
  });

  @override
  late final int hashCode = Object.hash(
    shape,
    Object.hashAllUnordered(properties.keys),
    Object.hashAllUnordered(properties.values),
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SingleSpace) return false;
    if (shape != other.shape) return false;
    if (properties.length != other.properties.length) return false;
    if (properties.isNotEmpty) {
      for (MapEntry<Key, Space> entry in properties.entries) {
        if (entry.value != other.properties[entry.key]) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  String toString() {
    return shape.spaceToText(properties, additionalProperties);
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
  new empty(this.path) : singleSpaces = [SingleSpace.empty];

  new(
    Path path,
    Shape shape, {
    Map<Key, Space> properties = const {},
    Map<Key, Space> additionalProperties = const {},
  }) : this._(path, [
         new SingleSpace(
           shape,
           properties: properties,
           additionalProperties: additionalProperties,
         ),
       ]);

  new _(this.path, this.singleSpaces);

  factory fromSingleSpaces(Path path, List<SingleSpace> singleSpaces) {
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
      if (singleSpacesList[0].shape == Shape.nullShape &&
          singleSpacesList[0].properties.isEmpty &&
          singleSpacesList[1].properties.isEmpty) {
        singleSpacesList = [
          new SingleSpace(singleSpacesList[1].shape.nullable),
        ];
      } else if (singleSpacesList[1].shape == Shape.nullShape &&
          singleSpacesList[1].properties.isEmpty &&
          singleSpacesList[0].properties.isEmpty) {
        singleSpacesList = [
          new SingleSpace(singleSpacesList[0].shape.nullable),
        ];
      }
    }
    return new Space._(path, singleSpacesList);
  }

  Space union(Space other) {
    return new Space.fromSingleSpaces(path, [
      ...singleSpaces,
      ...other.singleSpaces,
    ]);
  }

  @override
  String toString() => singleSpaces.join('|');
}
