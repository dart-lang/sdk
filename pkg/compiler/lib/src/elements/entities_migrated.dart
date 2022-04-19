// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library entities.migrated;

import 'package:front_end/src/api_unstable/dart2js.dart' show AsyncModifier;

// TODO(48820): This was imported from `common.dart`.
import '../diagnostics/spannable.dart' show Spannable;

import 'names.dart';

/// Abstract interface for entities.
///
/// Implement this directly if the entity is not a Dart language entity.
/// Entities defined within the Dart language should implement [Element].
///
/// For instance, the JavaScript backend need to create synthetic variables for
/// calling intercepted classes and such variables do not correspond to an
/// entity in the Dart source code nor in the terminology of the Dart language
/// and should therefore implement [Entity] directly.
abstract class Entity implements Spannable {
  // Not all entities have names. Imports with no prefix and some local
  // variables are unnamed. Some entities have a name that is the empty string
  // (e.g. the default constructor).
  String? get name;
}

/// Stripped down super interface for library like entities.
///
/// Currently only [LibraryElement] but later also kernel based Dart classes
/// and/or Dart-in-JS classes.
abstract class LibraryEntity extends Entity {
  /// Return the canonical uri that identifies this library.
  Uri get canonicalUri;

  /// Returns whether or not this library has opted into null safety.
  bool get isNonNullableByDefault;
}

/// Stripped down super interface for import entities.
///
/// The [name] property corresponds to the prefix name, if any.
class ImportEntity {
  final String? name;

  /// The canonical URI of the library where this import occurs
  /// (where the import is declared).
  final Uri enclosingLibraryUri;

  /// Whether the import is a deferred import.
  final bool isDeferred;

  /// The target import URI.
  final Uri uri;

  ImportEntity(this.isDeferred, this.name, this.uri, this.enclosingLibraryUri);

  @override
  String toString() => 'import($name:${isDeferred ? ' deferred' : ''})';
}

/// Stripped down super interface for class like entities.
///
/// Currently only [ClassElement] but later also kernel based Dart classes
/// and/or Dart-in-JS classes.
abstract class ClassEntity extends Entity {
  /// If this is a normal class, the enclosing library for this class. If this
  /// is a closure class, the enclosing class of the closure for which it was
  /// created.
  LibraryEntity get library;

  /// Whether this is a synthesized class for a closurized method or local
  /// function.
  bool get isClosure;

  /// Whether this is an abstract class.
  bool get isAbstract;
}

/// Stripped down super interface for member like entities, that is,
/// constructors, methods, fields etc.
///
/// Currently only [MemberElement] but later also kernel based Dart members
/// and/or Dart-in-JS properties.
abstract class MemberEntity extends Entity {
  /// The [Name] of member which takes privacy and getter/setter naming into
  /// account.
  Name get memberName;

  /// Whether this is a member of a library.
  bool get isTopLevel;

  /// Whether this is a static member of a class.
  bool get isStatic;

  /// Whether this is an instance member of a class.
  bool get isInstanceMember;

  /// Whether this is a constructor.
  bool get isConstructor;

  /// Whether this is a field.
  bool get isField;

  /// Whether this is a normal method (neither constructor, getter or setter)
  /// or operator method.
  bool get isFunction;

  /// Whether this is a getter.
  bool get isGetter;

  /// Whether this is a setter.
  bool get isSetter;

  /// Whether this member is assignable, i.e. a non-final, non-const field.
  bool get isAssignable;

  /// Whether this member is constant, i.e. a constant field or constructor.
  bool get isConst;

  /// Whether this member is abstract, i.e. an abstract method, getter or
  /// setter.
  bool get isAbstract;

  /// The enclosing class if this is a constructor, instance member or
  /// static member of a class.
  ClassEntity? get enclosingClass;

  /// The enclosing library if this is a library member, otherwise the
  /// enclosing library of the [enclosingClass].
  LibraryEntity get library;
}

/// Stripped down super interface for field like entities.
///
/// Currently only [FieldElement] but later also kernel based Dart fields
/// and/or Dart-in-JS field-like properties.
abstract class FieldEntity extends MemberEntity {}

/// An entity that defines a local entity (memory slot) in generated code.
///
/// Parameters, local variables and local functions (can) define local entity
/// and thus implement [Local] through [LocalElement]. For non-element locals,
/// like `this` and boxes, specialized [Local] classes are created.
///
/// Type variables can introduce locals in factories and constructors
/// but since one type variable can introduce different locals in different
/// factories and constructors it is not itself a [Local] but instead
/// a non-element [Local] is created through a specialized class.
abstract class Local extends Entity {}

/// Enum for the synchronous/asynchronous function body modifiers.
class AsyncMarker {
  /// The default function body marker.
  static const AsyncMarker SYNC = AsyncMarker._(AsyncModifier.Sync);

  /// The `sync*` function body marker.
  static const AsyncMarker SYNC_STAR =
      AsyncMarker._(AsyncModifier.SyncStar, isYielding: true);

  /// The `async` function body marker.
  static const AsyncMarker ASYNC =
      AsyncMarker._(AsyncModifier.Async, isAsync: true);

  /// The `async*` function body marker.
  static const AsyncMarker ASYNC_STAR =
      AsyncMarker._(AsyncModifier.AsyncStar, isAsync: true, isYielding: true);

  /// Is `true` if this marker defines the function body to have an
  /// asynchronous result, that is, either a [Future] or a [Stream].
  final bool isAsync;

  /// Is `true` if this marker defines the function body to have a plural
  /// result, that is, either an [Iterable] or a [Stream].
  final bool isYielding;

  final AsyncModifier asyncParserState;

  const AsyncMarker._(this.asyncParserState,
      {this.isAsync = false, this.isYielding = false});

  @override
  String toString() {
    return '${isAsync ? 'async' : 'sync'}${isYielding ? '*' : ''}';
  }

  /// Canonical list of marker values.
  ///
  /// Added to make [AsyncMarker] enum-like.
  static const List<AsyncMarker> values = <AsyncMarker>[
    SYNC,
    SYNC_STAR,
    ASYNC,
    ASYNC_STAR
  ];

  /// Index to this marker within [values].
  ///
  /// Added to make [AsyncMarker] enum-like.
  int get index => values.indexOf(this);
}

/// Values for variance annotations.
/// This needs to be kept in sync with values of `Variance` in `dart:_rti`.
enum Variance { legacyCovariant, covariant, contravariant, invariant }
