// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'key.dart';
import 'space.dart';
import 'witness.dart';

/// A static type in the type system.
abstract class StaticType {
  /// Built-in top type that all types are a subtype of.
  static const StaticType nullableObject =
      const NullableStaticType(nonNullableObject);

  /// Built-in top type that all types are a subtype of.
  static const StaticType nonNullableObject = const _NonNullableObject();

  /// Built-in `Null` type.
  static const StaticType nullType = const _NullType(neverType);

  /// Built-in `Never` type.
  static const StaticType neverType = const _NeverType();

  /// The static types of the fields this type exposes for record destructuring.
  ///
  /// Includes inherited fields.
  Map<String, StaticType> get fields;

  /// Returns the static type for the [name] in this static type, or `null` if
  /// no such key exists.
  ///
  /// This is used to support implicit on the constant [StaticType]s
  /// [nullableObject], [nonNullableObject], [nullType] and [neverType].
  StaticType? getField(ObjectFieldLookup fieldLookup, String name);

  /// Returns the static type for the [key] in this static type, or `null` if
  /// no such key exists.
  ///
  /// This is used to model keys in map patterns, and indices and ranges in list
  /// patterns.
  StaticType? getAdditionalField(Key key);

  /// Returns `true` if this static type is a subtype of [other], taking the
  /// nullability and subtyping relation into account.
  bool isSubtypeOf(StaticType other);

  /// Whether this type is sealed. A sealed type is implicitly abstract and has
  /// a closed set of known subtypes. This means that every instance of the
  /// type must be an instance of one of those subtypes. Conversely, if an
  /// instance is *not* an instance of one of those subtypes, that it must not
  /// be an instance of this type.
  ///
  /// Note that subtypes of a sealed type do not themselves have to be sealed.
  /// Consider:
  ///
  ///      (A)
  ///      / \
  ///     B   C
  ///
  /// Here, A is sealed and B and C are not. There may be many unknown
  /// subclasses of B and C, or classes implementing their interfaces. That
  /// doesn't interfere with exhaustiveness checking because it's still the
  /// case that any instance of A must be either a B or C *or some subtype of
  /// one of those two types*.
  bool get isSealed;

  /// Returns `true` if this is a record type.
  ///
  /// This is only used for print the type as part of a [Witness].
  bool get isRecord;

  /// Returns the name of this static type.
  ///
  /// This is used for printing [Space]s.
  String get name;

  /// Returns the nullable static type corresponding to this type.
  StaticType get nullable;

  /// Returns the non-nullable static type corresponding to this type.
  StaticType get nonNullable;

  /// The immediate subtypes of this type.
  ///
  /// The [keysOfInterest] of interest are the keys used in one of the case
  /// rows. This is used to select how a `List` type should be divided into
  /// subtypes that should be used for testing the exhaustiveness of a list.
  Iterable<StaticType> getSubtypes(Set<Key> keysOfInterest);

  /// Returns a textual representation of a single space consisting of this
  /// type and the provided [fields] and [additionalFields].
  String spaceToText(
      Map<String, Space> spaceFields, Map<Key, Space> additionalSpaceFields);
}

mixin _ObjectFieldMixin on _BaseStaticType {
  @override
  StaticType? getField(ObjectFieldLookup fieldLookup, String name) {
    return fields[name] ?? fieldLookup.getObjectFieldType(name);
  }
}

abstract class _BaseStaticType implements StaticType {
  const _BaseStaticType();

  @override
  bool get isRecord => false;

  @override
  Map<String, StaticType> get fields => const {};

  @override
  StaticType? getField(ObjectFieldLookup fieldLookup, String name) {
    return fields[name];
  }

  @override
  StaticType? getAdditionalField(Key key) => null;

  @override
  Iterable<StaticType> getSubtypes(Set<Key> keysOfInterest) => const [];

  @override
  String spaceToText(
      Map<String, Space> spaceFields, Map<Key, Space> additionalSpaceFields) {
    assert(additionalSpaceFields.isEmpty,
        "Additional fields not supported in ${runtimeType}.");
    if (this == StaticType.nullableObject && spaceFields.isEmpty) return '()';
    if (this == StaticType.neverType && spaceFields.isEmpty) return '∅';

    // If there are no fields, just show the type.
    if (spaceFields.isEmpty) return name;

    StringBuffer buffer = new StringBuffer();
    buffer.write(name);

    buffer.write('(');
    bool first = true;

    spaceFields.forEach((String name, Space space) {
      if (!first) buffer.write(', ');
      buffer.write('$name: $space');
      first = false;
    });

    buffer.write(')');
    return buffer.toString();
  }

  @override
  String toString() => name;
}

class _NonNullableObject extends _BaseStaticType with _ObjectFieldMixin {
  const _NonNullableObject();

  @override
  bool get isSealed => false;

  @override
  bool isSubtypeOf(StaticType other) {
    // Object? is a subtype of itself and Object?.
    return this == other || other == StaticType.nullableObject;
  }

  @override
  String get name => 'Object';

  @override
  StaticType get nullable => StaticType.nullableObject;

  @override
  StaticType get nonNullable => this;
}

class _NeverType extends _BaseStaticType with _ObjectFieldMixin {
  const _NeverType();

  @override
  bool get isSealed => false;

  @override
  bool isSubtypeOf(StaticType other) {
    // Never is a subtype of all types.
    return true;
  }

  @override
  String get name => 'Never';

  @override
  StaticType get nullable => StaticType.nullType;

  @override
  StaticType get nonNullable => this;
}

class _NullType extends NullableStaticType with _ObjectFieldMixin {
  const _NullType(super.underlying);

  @override
  bool get isSealed {
    // Avoid splitting into [nullType] and [neverType].
    return false;
  }

  @override
  Iterable<StaticType> getSubtypes(Set<Key> keysOfInterest) {
    // Avoid splitting into [nullType] and [neverType].
    return const [];
  }

  @override
  String get name => 'Null';
}

class NullableStaticType extends _BaseStaticType with _ObjectFieldMixin {
  final StaticType underlying;

  const NullableStaticType(this.underlying);

  @override
  bool get isSealed => true;

  @override
  Iterable<StaticType> getSubtypes(Set<Key> keysOfInterest) =>
      [underlying, StaticType.nullType];

  @override
  bool isSubtypeOf(StaticType other) {
    // A nullable type is a subtype if the underlying type and Null both are.
    return this == other ||
        other is NullableStaticType && underlying.isSubtypeOf(other.underlying);
  }

  @override
  String get name => '${underlying.name}?';

  @override
  StaticType get nullable => this;

  @override
  StaticType get nonNullable => underlying;

  @override
  int get hashCode => underlying.hashCode * 11;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    return other is NullableStaticType && underlying == other.underlying;
  }
}

abstract class NonNullableStaticType extends _BaseStaticType {
  @override
  late final StaticType nullable = new NullableStaticType(this);

  @override
  StaticType get nonNullable => this;

  @override
  bool isSubtypeOf(StaticType other) {
    if (this == other) return true;

    // All types are subtypes of Object?.
    if (other == StaticType.nullableObject) return true;

    // All non-nullable types are subtypes of Object.
    if (other == StaticType.nonNullableObject) return true;

    // A non-nullable type is a subtype of the underlying type of a nullable
    // type.
    if (other is NullableStaticType) {
      return isSubtypeOf(other.underlying);
    }

    if (isSubtypeOfInternal(other)) {
      return true;
    }

    if (other is WrappedStaticType) {
      return isSubtypeOf(other.wrappedType) && isSubtypeOf(other.impliedType);
    }

    return false;
  }

  bool isSubtypeOfInternal(StaticType other);

  @override
  String toString() => name;
}

/// Static type the behaves like [wrappedType] but is also a subtype of
/// [impliedType].
class WrappedStaticType extends NonNullableStaticType {
  final StaticType wrappedType;
  final StaticType impliedType;

  WrappedStaticType(this.wrappedType, this.impliedType);

  @override
  Map<String, StaticType> get fields => wrappedType.fields;

  @override
  bool get isRecord => wrappedType.isRecord;

  @override
  bool get isSealed => wrappedType.isSealed;

  @override
  String get name => wrappedType.name;

  @override
  Iterable<StaticType> getSubtypes(Set<Key> keysOfInterest) => wrappedType
      .getSubtypes(keysOfInterest)
      .map((e) => new WrappedStaticType(e, impliedType));

  @override
  bool isSubtypeOfInternal(StaticType other) {
    return wrappedType.isSubtypeOf(other) || impliedType.isSubtypeOf(other);
  }

  @override
  int get hashCode => Object.hash(wrappedType, impliedType);

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    return other is WrappedStaticType &&
        wrappedType == other.wrappedType &&
        impliedType == other.impliedType;
  }
}

/// Interface for accessing the members defined on `Object`.
abstract class ObjectFieldLookup {
  /// Returns the [StaticType] for the member [name] defined on `Object`, or
  /// `null` none exists.
  StaticType? getObjectFieldType(String name);
}
