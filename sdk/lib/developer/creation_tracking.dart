// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.developer;

/// Annotation to mark a class for instance creation tracking.
///
/// When a class is annotated with `@trackCreationLocations`, the compiler will
/// instrument its constructors to track the source code location where they
/// are called.
const Object trackCreationLocations = _TrackCreationLocations();

class _TrackCreationLocations {
  const _TrackCreationLocations();
}

/// Interface for classes that track the source code location their
/// constructor was called from.
abstract class _HasCreationLocation {
  /// The location where the constructor was called.
  CreationLocation? _location;
}

/// A tuple with file, line, and column number, for displaying human-readable
/// file locations.
class CreationLocation {
  const CreationLocation({
    required this.file,
    required this.line,
    required this.column,
    this.name,
  });

  /// File path of the location.
  final String file;

  /// 1-based line number.
  final int line;

  /// 1-based column number.
  final int column;

  /// Optional name of the parameter or function at this location.
  final String? name;

  /// Returns the creation location of [object].
  ///
  /// The provided object must be an instance of a class annotated with [trackCreationLocations].
  static CreationLocation? of(Object? object) {
    if (object is _HasCreationLocation) {
      return object._location;
    }
    return null;
  }

  /// Returns a JSON representation of this location.
  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'file': file,
      'line': line,
      'column': column,
      'name': name,
    };
  }

  @override
  String toString() =>
      <String>[if (name != null) name!, file, '$line', '$column'].join(':');
}
