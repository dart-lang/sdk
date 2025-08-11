// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Represents a unique identifier for a code element, such as a class, method,
/// or field, within a Dart program.
///
/// An [Identifier] is used to pinpoint a specific element based on its
/// location and name. It consists of:
///
/// - `importUri`: The URI of the library where the element is defined.
/// - `parent`: The name of the parent element (e.g., the class name for a
///   method or field). This is optional, as not all elements have parents (e.g.
///   top-level functions).
/// - `name`: The name of the element itself.
class Identifier {
  /// The URI of the library where the element is defined.
  ///
  /// This is given in the form of its package import uri, so that it is OS- and
  /// user independent.
  final String importUri;

  /// The name of the parent element (e.g., the class name for a method or
  /// field). This is optional, as not all elements have parents (e.g. top-level
  /// functions).
  final String? scope;

  /// The name of the element itself.
  final String name;

  /// Creates an [Identifier] object.
  ///
  /// [importUri] is the URI of the library where the element is defined.
  /// [scope] is the optional name of the parent element.
  /// [name] is the name of the element.
  const Identifier({required this.importUri, this.scope, required this.name});

  static const String _uriKey = 'uri';
  static const String _scopeKey = 'scope';
  static const String _nameKey = 'name';

  /// Creates an [Identifier] object from its JSON representation.
  factory Identifier.fromJson(Map<String, Object?> json) => Identifier(
    importUri: json[_uriKey] as String,
    scope: json[_scopeKey] as String?,
    name: json[_nameKey] as String,
  );

  /// Converts this [Identifier] object to a JSON representation.
  Map<String, Object?> toJson() => {
    _uriKey: importUri,
    if (scope != null) _scopeKey: scope,
    _nameKey: name,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Identifier &&
        other.importUri == importUri &&
        other.scope == scope &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(importUri, scope, name);
}
