// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of elements;

/// A [Name] represents the abstraction of a Dart identifier which takes privacy
/// and setter into account.
// TODO(johnniwinther): Try to share logic with [Selector].
abstract class Name {
  /// Create a [Name] for an identifier [text]. If [text] begins with '_' a
  /// private name with respect to [library] is created. If [isSetter] is `true`
  /// the created name represents the setter name 'text='.
  factory Name(String text, LibraryElement library, {bool isSetter: false}) {
    if (isPrivateName(text)) {
      return new PrivateName(text, library, isSetter: isSetter);
    }
    return new PublicName(text, isSetter: isSetter);
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

  /// Returns the seeter name corresponding to this name. If this name is a
  /// getter name 'v' then the name 'v=' is returned, otherwsie the name itself
  /// is returned.
  Name get setter;

  /// Returns `true` if an entity of this name is accessible from library
  /// [element].
  bool isAccessibleFrom(LibraryElement element);

  /// Returns `true` if this name is private.
  bool get isPrivate;

  /// Returns `true` if this name is the same as [other] not taking the library
  /// privacy into account.
  bool isSimilarTo(Name other);
}

class PublicName implements Name {
  final String text;
  final bool isSetter;

  const PublicName(this.text, {this.isSetter: false});

  Name get getter => isSetter ? new PublicName(text) : this;

  Name get setter => isSetter ? this : new PublicName(text, isSetter: true);

  bool isAccessibleFrom(LibraryElement element) => true;

  bool get isPrivate => false;

  int get hashCode => text.hashCode + 11 * isSetter.hashCode;

  bool operator ==(other) {
    if (other is! PublicName) return false;
    return isSimilarTo(other);
  }

  bool isSimilarTo(Name other) =>
      text == other.text && isSetter == other.isSetter;

  String toString() => isSetter ? '$text=' : text;
}

class PrivateName extends PublicName {
  final LibraryElement library;

  PrivateName(String text, this.library, {bool isSetter: false})
      : super(text, isSetter: isSetter);

  Name get getter => isSetter ? new PrivateName(text, library) : this;

  Name get setter {
    return isSetter ? this : new PrivateName(text, library, isSetter: true);
  }

  bool isAccessibleFrom(LibraryElement element) => library == element;

  bool get isPrivate => true;

  int get hashCode => super.hashCode + 13 * library.hashCode;

  bool operator ==(other) {
    if (other is! PrivateName) return false;
    return super==(other) && library == other.library;
  }

  String toString() => '${library.getLibraryName()}#${super.toString()}';
}
