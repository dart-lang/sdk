// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(paulberry,rnystrom): Generics.

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

  /// Returns the name of this static type.
  ///
  /// This is used for printing [Space]s.
  String get name;

  /// Returns the nullable static type corresponding to this type.
  StaticType get nullable;

  /// The immediate subtypes of this type.
  Iterable<StaticType> get subtypes;
}

abstract class _BaseStaticType implements StaticType {
  const _BaseStaticType();

  @override
  Map<String, StaticType> get fields => const {};

  @override
  Iterable<StaticType> get subtypes => const [];

  @override
  String toString() => name;
}

class _NonNullableObject extends _BaseStaticType {
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
}

class _NeverType extends _BaseStaticType {
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
}

class _NullType extends NullableStaticType {
  const _NullType(super.underlying);

  @override
  bool get isSealed {
    // Avoid splitting into [nullType] and [neverType].
    return false;
  }

  @override
  Iterable<StaticType> get subtypes {
    // Avoid splitting into [nullType] and [neverType].
    return const [];
  }

  @override
  String get name => 'Null';
}

class StaticTypeImpl extends NonNullableStaticType {
  @override
  final String name;

  @override
  final bool isSealed;

  final Map<String, StaticType> _fields;

  final List<StaticType> _supertypes = [];

  final List<StaticTypeImpl> _subtypes = [];

  StaticTypeImpl(this.name,
      {this.isSealed = false,
      List<StaticTypeImpl>? inherits,
      Map<String, StaticType> fields = const {}})
      : _fields = fields {
    if (inherits != null) {
      for (StaticTypeImpl type in inherits) {
        _supertypes.add(type);
        type._subtypes.add(this);
      }
    } else {
      _supertypes.add(StaticType.nonNullableObject);
    }

    int sealed = 0;
    for (StaticType supertype in _supertypes) {
      if (supertype.isSealed) sealed++;
    }

    // We don't allow a sealed type's subtypes to be shared with some other
    // sibling supertype, as in D here:
    //
    //   (A) (B)
    //   / \ / \
    //  C   D   E
    //
    // We could remove this restriction but doing so will require
    // expandTypes() to be more complex. In the example here, if we subtract
    // E from A, the result should be C|D. That requires knowing that B should
    // be expanded, which expandTypes() doesn't currently handle.
    if (sealed > 1) {
      throw new ArgumentError('Can only have one sealed supertype.');
    }
  }

  @override
  Map<String, StaticType> get fields {
    return {
      for (StaticType supertype in _supertypes) ...supertype.fields,
      ..._fields
    };
  }

  @override
  Iterable<StaticType> get subtypes => _subtypes;

  @override
  bool isSubtypeOfInternal(StaticType other) {
    for (StaticType supertype in _supertypes) {
      if (supertype.isSubtypeOf(other)) return true;
    }

    return false;
  }
}

class NullableStaticType extends _BaseStaticType {
  final StaticType underlying;

  const NullableStaticType(this.underlying);

  @override
  bool get isSealed => true;

  @override
  Iterable<StaticType> get subtypes => [underlying, StaticType.nullType];

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
}

abstract class NonNullableStaticType extends _BaseStaticType {
  @override
  late final StaticType nullable = new NullableStaticType(this);

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

    return isSubtypeOfInternal(other);
  }

  bool isSubtypeOfInternal(StaticType other);

  @override
  String toString() => name;
}
