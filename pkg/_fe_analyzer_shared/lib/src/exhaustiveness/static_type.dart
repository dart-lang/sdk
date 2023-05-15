// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart_template_buffer.dart';
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
  Map<Key, StaticType> get fields;

  /// Returns the static type for the [name] in this static type, or `null` if
  /// no such key exists.
  ///
  /// This is used to support implicit on the constant [StaticType]s
  /// [nullableObject], [nonNullableObject], [nullType] and [neverType].
  StaticType? getPropertyType(ObjectPropertyLookup fieldLookup, Key key);

  /// Returns the static type for the [key] in this static type, or `null` if
  /// no such key exists.
  ///
  /// This is used to model keys in map patterns, and indices and ranges in list
  /// patterns.
  StaticType? getAdditionalPropertyType(Key key);

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

  /// Return `true` if this type is implicitly nullable.
  ///
  /// This is used to omit the '?' for the [name] in the [NullableStaticType].
  bool get isImplicitlyNullable;

  /// Returns the name of this static type.
  ///
  /// This is used for printing [Space]s.
  String get name;

  /// Writes the name of this static type to [buffer].
  void typeToDart(DartTemplateBuffer buffer);

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
  /// type and the provided [spaceProperties] and [additionalSpaceProperties].
  String spaceToText(Map<Key, Space> spaceProperties,
      Map<Key, Space> additionalSpaceProperties);

  /// Write this [witness] with the [witnessFields] as a pattern into [buffer]
  /// using this [StaticType] to determine the syntax.
  ///
  /// If [forCorrection] is true, [witnessFields] that fully cover their static
  /// type are omitted if possible.
  void witnessToDart(DartTemplateBuffer buffer, PropertyWitness witness,
      Map<Key, PropertyWitness> witnessFields,
      {required bool forCorrection});
}

mixin _ObjectFieldMixin on _BaseStaticType {
  @override
  StaticType? getPropertyType(ObjectPropertyLookup fieldLookup, Key key) {
    return fields[key] ?? fieldLookup.getObjectFieldType(key);
  }
}

abstract class _BaseStaticType implements StaticType {
  const _BaseStaticType();

  @override
  bool get isRecord => false;

  @override
  Map<Key, StaticType> get fields => const {};

  @override
  StaticType? getPropertyType(ObjectPropertyLookup fieldLookup, Key key) {
    return fields[key];
  }

  @override
  StaticType? getAdditionalPropertyType(Key key) => null;

  @override
  Iterable<StaticType> getSubtypes(Set<Key> keysOfInterest) => const [];

  @override
  bool isSubtypeOf(StaticType other) {
    if (this == other) return true;

    // All types are subtypes of Object?.
    if (other == StaticType.nullableObject) return true;

    if (other is WrappedStaticType) {
      return isSubtypeOf(other.wrappedType) && isSubtypeOf(other.impliedType);
    }

    return false;
  }

  @override
  String spaceToText(Map<Key, Space> spaceProperties,
      Map<Key, Space> additionalSpaceProperties) {
    assert(additionalSpaceProperties.isEmpty,
        "Additional fields not supported in ${runtimeType}.");
    if (this == StaticType.nullableObject && spaceProperties.isEmpty) {
      return '()';
    }
    if (this == StaticType.neverType && spaceProperties.isEmpty) return '∅';

    // If there are no fields, just show the type.
    if (spaceProperties.isEmpty) return name;

    StringBuffer buffer = new StringBuffer();
    buffer.write(name);

    buffer.write('(');
    bool first = true;

    spaceProperties.forEach((Key key, Space space) {
      if (!first) buffer.write(', ');
      if (key is ExtensionKey) {
        buffer.write('${key.receiverType}.${key.name}: $space (${key.type})');
      } else {
        buffer.write('${key.name}: $space');
      }
      first = false;
    });

    buffer.write(')');
    return buffer.toString();
  }

  @override
  void witnessToDart(DartTemplateBuffer buffer, PropertyWitness witness,
      Map<Key, PropertyWitness> witnessFields,
      {required bool forCorrection}) {
    if (this == StaticType.nullableObject && witnessFields.isEmpty) {
      buffer.write('_');
    } else if (this == StaticType.nullType && witnessFields.isEmpty) {
      buffer.write('null');
    } else {
      typeToDart(buffer);
      buffer.write('(');
      String comma = '';
      for (MapEntry<Key, PropertyWitness> entry in witnessFields.entries) {
        Key key = entry.key;
        PropertyWitness witness = entry.value;
        buffer.write(comma);
        comma = ', ';
        buffer.write(key.name);
        buffer.write(': ');
        witness.witnessToDart(buffer, forCorrection: forCorrection);
      }
      buffer.write(')');
    }
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
    return super.isSubtypeOf(other) || other == StaticType.nullableObject;
  }

  @override
  String get name => 'Object';

  @override
  StaticType get nullable => StaticType.nullableObject;

  @override
  StaticType get nonNullable => this;

  @override
  bool get isImplicitlyNullable => false;

  @override
  void typeToDart(DartTemplateBuffer buffer) {
    buffer.writeCoreType(name);
  }
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

  @override
  bool get isImplicitlyNullable => false;

  @override
  void typeToDart(DartTemplateBuffer buffer) {
    buffer.writeCoreType(name);
  }
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
  bool get isImplicitlyNullable => true;

  @override
  String get name => 'Null';

  @override
  void typeToDart(DartTemplateBuffer buffer) {
    buffer.writeCoreType(name);
  }
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
    if (super.isSubtypeOf(other)) {
      return true;
    }
    // A nullable type is a subtype if the underlying type and Null both are.
    return this == other ||
        other is NullableStaticType && underlying.isSubtypeOf(other.underlying);
  }

  @override
  String get name =>
      underlying.isImplicitlyNullable ? underlying.name : '${underlying.name}?';

  @override
  bool get isImplicitlyNullable => true;

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

  @override
  void typeToDart(DartTemplateBuffer buffer) {
    underlying.typeToDart(buffer);
    if (!underlying.isImplicitlyNullable) {
      buffer.write('?');
    }
  }
}

abstract class NonNullableStaticType extends _BaseStaticType {
  @override
  late final StaticType nullable = new NullableStaticType(this);

  @override
  StaticType get nonNullable => this;

  @override
  bool isSubtypeOf(StaticType other) {
    if (super.isSubtypeOf(other)) return true;

    // All non-nullable types are subtypes of Object.
    if (other == StaticType.nonNullableObject) return true;

    // A non-nullable type is a subtype of the underlying type of a nullable
    // type.
    if (other is NullableStaticType) {
      return isSubtypeOf(other.underlying);
    }

    return isSubtypeOfInternal(other);
  }

  bool isSubtypeOfInternal(StaticType other);

  @override
  String toString() => name;
}

/// Static type the behaves like [wrappedType] but is also a subtype of
/// [impliedType].
class WrappedStaticType extends _BaseStaticType {
  final StaticType wrappedType;
  final StaticType impliedType;

  WrappedStaticType(this.wrappedType, this.impliedType);

  @override
  Map<Key, StaticType> get fields => wrappedType.fields;

  @override
  StaticType? getPropertyType(ObjectPropertyLookup fieldLookup, Key key) {
    return wrappedType.getPropertyType(fieldLookup, key);
  }

  @override
  bool get isRecord => wrappedType.isRecord;

  @override
  bool get isSealed => wrappedType.isSealed;

  @override
  String get name => wrappedType.name;

  @override
  bool get isImplicitlyNullable => wrappedType.isImplicitlyNullable;

  @override
  Iterable<StaticType> getSubtypes(Set<Key> keysOfInterest) {
    StaticType wrappedType = this.wrappedType;
    StaticType impliedType = this.impliedType;
    if (wrappedType is NullableStaticType &&
        impliedType is NullableStaticType) {
      // With nullable types we need to avoid carrying the nullable implied type
      // into the non-nullable subtype since it otherwise wouldn't allow for
      // matching the non-nullable aspect of the wrapped type with the
      // non-nullable implied type.
      //
      // For instance
      //
      //     method<O>(O? object) => switch (object) {
      //         O object => 0,
      //         null => 1,
      //       };
      //
      // Here the static type of `O?` is `WrappedStaticType(Object?, O?)` which
      // allows for matching both by the bound `Object?` and the exact type
      // variable type `O?`. If we split this into the subtypes
      // `WrappedStaticType(Object, O?)` and `WrappedStaticType(null, O?)` then
      // we miss that `O object` covers the non-nullable aspect, since `O` is
      // neither a super type of `Object` nor `O?`.
      return [
        new WrappedStaticType(wrappedType.underlying, impliedType.underlying),
        StaticType.nullType
      ];
    }
    return wrappedType
        .getSubtypes(keysOfInterest)
        .map((e) => new WrappedStaticType(e, impliedType));
  }

  @override
  bool isSubtypeOf(StaticType other) {
    if (super.isSubtypeOf(other)) return true;

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

  @override
  void witnessToDart(DartTemplateBuffer buffer, PropertyWitness witness,
      Map<Key, PropertyWitness> witnessFields,
      {required bool forCorrection}) {
    return wrappedType.witnessToDart(buffer, witness, witnessFields,
        forCorrection: forCorrection);
  }

  @override
  late final StaticType nonNullable = wrappedType.nonNullable == wrappedType &&
          impliedType.nonNullable == impliedType
      ? this
      : new WrappedStaticType(wrappedType.nonNullable, impliedType.nonNullable);

  @override
  late final StaticType nullable =
      wrappedType.nullable == wrappedType && impliedType.nullable == impliedType
          ? this
          : new WrappedStaticType(wrappedType.nullable, impliedType.nullable);

  @override
  void typeToDart(DartTemplateBuffer buffer) {
    wrappedType.typeToDart(buffer);
  }
}

/// Interface for accessing the members defined on `Object`.
abstract class ObjectPropertyLookup {
  /// Returns the [StaticType] for the member with the given [key] defined on
  /// `Object`, or `null` none exists.
  StaticType? getObjectFieldType(Key key);
}
