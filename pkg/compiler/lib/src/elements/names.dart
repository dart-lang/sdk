// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.elements.names;

import 'package:front_end/src/api_unstable/dart2js.dart' show $_;

/// A [Name] represents the abstraction of a Dart identifier which takes privacy
/// and setter into account.
// TODO(johnniwinther): Try to share logic with [Selector].
abstract class Name {
  /// Create a [Name] for an identifier [text]. If [text] begins with '_' a
  /// private name with respect to library [uri] is created. If [isSetter] is
  /// `true` the created name represents the setter name 'text='.
  factory Name(String text, Uri? uri, {bool isSetter = false}) {
    if (isPrivateName(text)) {
      return PrivateName(text, uri!, isSetter: isSetter);
    }
    return PublicName(text, isSetter: isSetter);
  }

  /// The text of the name without prefixed library name or suffixed '=' if
  /// applicable.
  String get text;

  /// Is `true` if this name represents the name of a setter.
  bool get isSetter;

  /// Returns the getter name corresponding to this name. If this name is a
  /// setter name 'v=' then the name 'v' is returned, otherwise the name itself
  /// is returned.
  Name get getter;

  /// Returns the setter name corresponding to this name. If this name is a
  /// getter name 'v' then the name 'v=' is returned, otherwise the name itself
  /// is returned.
  Name get setter;

  /// Returns `true` if an entity of this name is accessible from library
  /// [element].
  bool isAccessibleFrom(Uri uri);

  /// Returns `true` if this name is private.
  bool get isPrivate;

  /// Returns `true` if this name is the same as [other] not taking the library
  /// privacy into account.
  bool isSimilarTo(Name other);
  int get similarHashCode;

  /// Returns `true` if this name has the name [text] and [library] as [other].
  ///
  /// This is similar to `==` but doesn't take `isSetter` into account.
  bool matches(Name other);

  /// If this name is private, returns the [Uri] for the library from which the
  /// name originates. Otherwise, returns `null`.
  // TODO(sra): Should this rather throw for public names?
  Uri? get uri;

  /// Returns `true` when [s] is private if used as an identifier.
  static bool isPrivateName(String s) => !s.isEmpty && s.codeUnitAt(0) == $_;

  /// Returns `true` when [s] is public if used as an identifier.
  static bool isPublicName(String s) => !isPrivateName(s);
}

class PublicName implements Name {
  @override
  final String text;
  @override
  final bool isSetter;

  const PublicName(this.text, {this.isSetter = false});

  @override
  Name get getter => isSetter ? PublicName(text) : this;

  @override
  Name get setter => isSetter ? this : PublicName(text, isSetter: true);

  @override
  bool isAccessibleFrom(Uri uri) => true;

  @override
  bool get isPrivate => false;

  @override
  int get hashCode => similarHashCode;

  @override
  bool operator ==(other) {
    if (other is! PublicName) return false;
    return isSimilarTo(other);
  }

  @override
  bool isSimilarTo(Name other) =>
      text == other.text && isSetter == other.isSetter;
  @override
  int get similarHashCode => text.hashCode + 11 * isSetter.hashCode;

  @override
  bool matches(Name other) => text == other.text;

  @override
  Uri? get uri => null;

  @override
  String toString() => isSetter ? '$text=' : text;
}

class PrivateName extends PublicName {
  @override
  final Uri uri;

  PrivateName(super.text, this.uri, {super.isSetter});

  @override
  Name get getter => isSetter ? PrivateName(text, uri) : this;

  @override
  Name get setter {
    return isSetter ? this : PrivateName(text, uri, isSetter: true);
  }

  @override
  bool isAccessibleFrom(Uri uri) => this.uri == uri;

  @override
  bool get isPrivate => true;

  @override
  int get hashCode => super.hashCode + 13 * uri.hashCode;

  @override
  bool operator ==(other) {
    if (other is! PrivateName) return false;
    return super == (other) && uri == other.uri;
  }

  @override
  bool matches(Name other) => super.matches(other) && uri == other.uri;

  @override
  String toString() => '${uri}#${super.toString()}';
}
