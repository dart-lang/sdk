// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart_template_buffer.dart';
import 'key.dart';
import 'space.dart';
import 'witness.dart';

/// A [Shape] represents a set of runtime values, defined by their outer
/// structure. This is closely related to Dart types, but is subtly different,
/// and is derived from how pattern matching is performed at runtime.
///
/// Shapes can be divided into two basic kinds: sealed and atomic. The sealed
/// shapes can be exhausted both by themselves and by splitting them into a set
/// of subshapes, where it is known that the union of the runtime values of the
/// subshapes is a superset of, preferably equal to, the runtime values of the
/// sealed shape. The atomic shapes can only be exhausted by themselves.
///
/// In the following, `Kind(parameter:Type,...)` describes a kind of shape and
/// the parameters that define it, and `Kind(argument,...)` describes the
/// specific shape of that kind for the given arguments. For instance,
/// `BoolValue(value:bool)` describes the shapes for boolean values and
/// `BoolValue(true)` describes the shape for the value `true`.
///
/// The sealed shapes are
///
///   * `Nullable(underlying:Shape)` for any non-null shape. This splits into
///     the `Null` shape and the `underlying` shape.
///   * `Enum(t:Type)` for any enum type `t`. This splits into the set of
///     `EnumValue(value:Constant)`s for each enum element `value` of the enum
///     type `t`.
///   * `Bool` for the bool type. This splits into the `BoolValue(true)` and
///     `BoolValue(false)` for the `true` and `false` values, respectively.
///   * `FutureOr(typeArgument:Shape,future:Shape)` for any `FutureOr<T>` type,
///     where `typeArgument` is the shape for the values of type `T` and
///     `future` is the shape for the values of type `Future<T>`. This splits
///     into `typeArgument` and `future`.
///   * `Sealed(t:Type)` for any sealed class type `t`. This splits into the
///     shapes for the immediate subtypes of `t`.
///   * `List(t:Type)` for any list type `t`. This can be split into an infinite
///     number of `ListPattern(t:Type,count:int,hasRest:bool)` subshapes, one
///     for each number of elements, both exact and at least. For instance,
///     `[_, _]` and `[_, _, ...]` for exactly 2 and at least 2 elements.
///     Practically, when performing exhaustiveness, the set of subshapes is
///     determined by the cases in the switch expression or statement. For
///     instance for
///
///         method(List<int> l) => switch (l) {
///           [] => 0,
///           [_] => 1,
///           [_, _, ...] => 2,
///         };
///
///     `List(List<int>)` is split into the subshapes
///     `ListPattern(List<int>, 0, false)`,
///     `ListPattern(List<int>, 1, false)`, and
///     `ListPattern(List<int>, 2, true)`.
///   * `Wrapped(wrapped:Shape,implied:Shape)` is a special shape created for
///     instance for value sets based on type variables. For these we can
///     exhaust through the `implied` shape, which is derived from the type
///     variable, and through the `wrapped` shape, which is derived from the
///     type variable bound. The `Wrapped` shape is considered sealed iff the
///     `wrapped` shape is sealed, in which case it splits into
///     `Wrapped(s, implied)` for each subshape `s` of `wrapped`. For instance
///     if we have
///
///         method<T extends num>(T t) => switch (t) { ... }
///
///     then we can exhaust with the type variable, `T _`, the bound, `num()`,
///     and the subshapes of the bound, `int()` and `double()`.
///
///     The `Wrapped` shape is also used for the subshapes of `Enum` and
///     `Sealed` shapes, since for generic types, the type of an enum element
///     or subclass is not necessarily a subtype of the enum or sealed class
///     type. For instance if we have
///
///         sealed class A<T> {}
///         class B extends A<int> {}
///         method<T>(A<T> a) => switch (a) { ... }
///
///     then `B` is not a subtype of `A<T>`, so the subshape of `Sealed(A<T>)`
///     for `B` is `Wrapped(Atomic(B), Sealed(A<T>))`.
///
/// The atomic shapes are
///
///   * `Null` for the value `null`.
///   * `Never` for the empty value set.
///   * `Object` for all non-null values. The shape for all values is
///     `Nullable(Object)`.
///   * `EnumValue(value:Constant)` for any enum element `value`.
///   * `BoolValue(value:bool)` for the values `true` and `false`. This is used
///     as a subshape for the `Bool` shape.
///   * `Value(value:Constant)` for any other constant `value` with primitive
///     equality, like `0` or `'foo'`.
///   * `Unknown` for a value set that cannot be represented precisely by the
///     other shapes, like the value of a constant without primitive equality.
///     Each `Unknown` shape is unique, which ensures that it cannot be used to
///     exhaust any other shape.
///   * `Record(positional:int,named:Set<String>)` for any record type with
///     the given number of `positional` fields and the given set of `named`
///     fields. Note that the record shape does not contain the types of the
///     fields, only the structure. The content of the fields is modelled by
///     the exhaustiveness checking through properties of a [SingleSpace],
///     similar to how fields of an object pattern are modelled.
///   * `ListPattern(t:Type,count:int,hasRest:bool)` for the list pattern
///     matching of type `t` with `count` required elements and `hasRest` for
///     whether it has a rest pattern.
///   * `MapPattern(t:Type,keys:Set<Key>)` for the map pattern matching of type
///     `t` with the given `keys`. While a map is not a sealed shape,
///     exhaustiveness still handles explicit map patterns as their own shapes
///     in order to support checking for unreachable cases.
///   * `Atomic(t:Type)` for any other type `t`.
// TODO(johnniwinther): Change [RecordShape] to match the description of
// `Record` above. Currently [RecordShape] is sometimes wrongfully based on the
// full record type, including the types of the fields, and not only on its
// structure. See language issue #4249.
abstract class Shape {
  /// Built-in top shape for all values.
  static const Shape nullableObject = const NullableShape(nonNullableObject);

  /// Built-in shape for all non-null values.
  static const Shape nonNullableObject = const _NonNullableObject();

  /// Built-in shape for the `null` value.
  static const Shape nullShape = const _NullShape(neverShape);

  /// Built-in shape for the empty value set.
  static const Shape neverShape = const _NeverShape();

  /// The shapes of the properties this shape exposes for record destructuring.
  ///
  /// Includes inherited properties.
  Map<Key, Shape> get properties;

  /// Returns the shape for the property with the given [key] in this shape, or
  /// `null` if no such property exists.
  ///
  /// This is used to support implicit properties on the constant [Shape]s
  /// [nullableObject], [nonNullableObject], [nullShape] and [neverShape].
  Shape? getPropertyShape(ObjectPropertyLookup propertyLookup, Key key);

  /// Returns the shape for the property with the given [key] in this shape, or
  /// `null` if no such property exists.
  ///
  /// This is used to model keys in map patterns, and indices and ranges in list
  /// patterns.
  Shape? getAdditionalPropertyShape(Key key);

  /// Returns `true` if this shape is a subshape of [other], taking the
  /// nullability and subtyping relation into account.
  bool isSubshapeOf(Shape other);

  /// Whether this shape is sealed. A sealed shape is implicitly abstract and
  /// has a closed set of known subshapes. This means that every instance of the
  /// shape must be an instance of one of those subshapes. Conversely, if an
  /// instance is *not* an instance of one of those subshapes, it must not be an
  /// instance of this shape.
  ///
  /// Note that subshapes of a sealed shape do not themselves have to be sealed.
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

  /// Returns `true` if this is a private shape.
  ///
  /// This is used to determine whether a missing pattern part is not accessible
  /// due to being private.
  bool get isPrivate;

  /// Returns `true` if this is a subshape of `Enum`.
  ///
  /// This is used along with [isPrivate] to determine whether we should suggest
  /// enum values as missing pattern parts or only a default case.
  bool get isEnumSubshape;

  /// Returns the library URI for this shape, or `null`.
  Uri? get libraryUri;

  /// Returns `true` if this is a record shape.
  ///
  /// This is only used for printing the shape as part of a [Witness].
  bool get isRecord;

  /// Return `true` if this shape is implicitly nullable.
  ///
  /// This is used to omit the '?' for the [name] in the [NullableShape].
  bool get isImplicitlyNullable;

  /// Returns the name of this shape.
  ///
  /// This is used for printing [Space]s.
  String get name;

  /// Writes the name of this shape to [buffer].
  void shapeToDart(DartTemplateBuffer buffer);

  /// Returns the nullable shape corresponding to this shape.
  Shape get nullable;

  /// Returns the non-nullable shape corresponding to this shape.
  Shape get nonNullable;

  /// The immediate subshapes of this shape.
  ///
  /// The [keysOfInterest] are the keys used in one of the case rows. This is
  /// used to select how a `List` shape should be divided into subshapes that
  /// should be used for testing the exhaustiveness of a list.
  Iterable<Shape> getSubshapes(Set<Key> keysOfInterest);

  /// Returns a textual representation of a single space consisting of this
  /// shape and the provided [spaceProperties] and [additionalSpaceProperties].
  String spaceToText(
    Map<Key, Space> spaceProperties,
    Map<Key, Space> additionalSpaceProperties,
  );

  /// Write this [witness] with the [witnessProperties] as a pattern into
  /// [buffer] using this [Shape] to determine the syntax.
  ///
  /// If [forCorrection] is true, [witnessProperties] that fully cover their
  /// shape are omitted if possible.
  void witnessToDart(
    DartTemplateBuffer buffer,
    PropertyWitness witness,
    Map<Key, PropertyWitness> witnessProperties, {
    required bool forCorrection,
  });

  /// Returns `true` if this shape is accessible as determined by
  /// [accessibility].
  Future<bool> isAccessible(DartAccessibility accessibility);
}

mixin _ObjectPropertyMixin on _BaseShape {
  @override
  Shape? getPropertyShape(ObjectPropertyLookup propertyLookup, Key key) {
    return properties[key] ?? propertyLookup.getObjectPropertyShape(key);
  }
}

abstract class _BaseShape implements Shape {
  const new();

  @override
  bool get isRecord => false;

  @override
  Map<Key, Shape> get properties => const {};

  @override
  Shape? getPropertyShape(ObjectPropertyLookup propertyLookup, Key key) {
    return properties[key];
  }

  @override
  Shape? getAdditionalPropertyShape(Key key) => null;

  @override
  Iterable<Shape> getSubshapes(Set<Key> keysOfInterest) => const [];

  @override
  bool isSubshapeOf(Shape other) {
    if (this == other) return true;

    // All shapes are subshapes of Object?.
    if (other == Shape.nullableObject) return true;

    if (other is WrappedShape) {
      return isSubshapeOf(other.wrappedShape) &&
          isSubshapeOf(other.impliedShape);
    }

    return false;
  }

  @override
  String spaceToText(
    Map<Key, Space> spaceProperties,
    Map<Key, Space> additionalSpaceProperties,
  ) {
    assert(
      additionalSpaceProperties.isEmpty,
      "Additional properties not supported in ${runtimeType}.",
    );
    if (this == Shape.nullableObject && spaceProperties.isEmpty) {
      return '()';
    }
    if (this == Shape.neverShape && spaceProperties.isEmpty) return '∅';

    // If there are no properties, just show the name.
    if (spaceProperties.isEmpty) return name;

    StringBuffer buffer = new StringBuffer();
    buffer.write(name);

    buffer.write('(');
    bool first = true;

    spaceProperties.forEach((Key key, Space space) {
      if (!first) buffer.write(', ');
      if (key is ExtensionKey) {
        buffer.write('${key.receiverShape}.${key.name}: $space (${key.shape})');
      } else {
        buffer.write('${key.name}: $space');
      }
      first = false;
    });

    buffer.write(')');
    return buffer.toString();
  }

  @override
  void witnessToDart(
    DartTemplateBuffer buffer,
    PropertyWitness witness,
    Map<Key, PropertyWitness> witnessProperties, {
    required bool forCorrection,
  }) {
    if (this == Shape.nullableObject && witnessProperties.isEmpty) {
      buffer.write('_');
    } else if (this == Shape.nullShape && witnessProperties.isEmpty) {
      buffer.write('null');
    } else {
      shapeToDart(buffer);
      buffer.write('(');
      String comma = '';
      for (MapEntry<Key, PropertyWitness> entry in witnessProperties.entries) {
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
  Future<bool> isAccessible(DartAccessibility accessibility) =>
      new Future.value(true);

  @override
  String toString() => name;
}

class _NonNullableObject extends _BaseShape with _ObjectPropertyMixin {
  const new();

  @override
  bool get isSealed => false;

  @override
  bool isSubshapeOf(Shape other) {
    // `Object` is a subshape of itself and `Object?`.
    return super.isSubshapeOf(other) || other == Shape.nullableObject;
  }

  @override
  String get name => 'Object';

  @override
  Shape get nullable => Shape.nullableObject;

  @override
  Shape get nonNullable => this;

  @override
  bool get isImplicitlyNullable => false;

  @override
  void shapeToDart(DartTemplateBuffer buffer) {
    buffer.writeCoreType(name);
  }

  @override
  bool get isEnumSubshape => false;

  @override
  Uri? get libraryUri => null;

  @override
  bool get isPrivate => false;
}

class _NeverShape extends _BaseShape with _ObjectPropertyMixin {
  const new();

  @override
  bool get isSealed => false;

  @override
  bool isSubshapeOf(Shape other) {
    // Never is a subshape of all shapes.
    return true;
  }

  @override
  String get name => 'Never';

  @override
  Shape get nullable => Shape.nullShape;

  @override
  Shape get nonNullable => this;

  @override
  bool get isImplicitlyNullable => false;

  @override
  void shapeToDart(DartTemplateBuffer buffer) {
    buffer.writeCoreType(name);
  }

  @override
  bool get isEnumSubshape => false;

  @override
  Uri? get libraryUri => null;

  @override
  bool get isPrivate => false;
}

class _NullShape extends NullableShape with _ObjectPropertyMixin {
  const new(super.underlying);

  @override
  bool get isSealed {
    // Avoid splitting into [Shape.nullShape] and [Shape.neverShape].
    return false;
  }

  @override
  Iterable<Shape> getSubshapes(Set<Key> keysOfInterest) {
    // Avoid splitting into [Shape.nullShape] and [Shape.neverShape].
    return const [];
  }

  @override
  bool get isImplicitlyNullable => true;

  @override
  String get name => 'Null';

  @override
  void shapeToDart(DartTemplateBuffer buffer) {
    buffer.writeCoreType(name);
  }
}

/// The shape representing the union of the `null` value and a set of non-null
/// values from the [underlying] shape.
class NullableShape extends _BaseShape with _ObjectPropertyMixin {
  final Shape underlying;

  const new(this.underlying);

  @override
  bool get isSealed => true;

  @override
  Iterable<Shape> getSubshapes(Set<Key> keysOfInterest) => [
    underlying,
    Shape.nullShape,
  ];

  @override
  bool isSubshapeOf(Shape other) {
    if (super.isSubshapeOf(other)) {
      return true;
    }
    // A nullable shape is a subshape if the underlying shape and Null both are.
    return this == other ||
        other is NullableShape && underlying.isSubshapeOf(other.underlying);
  }

  @override
  String get name =>
      underlying.isImplicitlyNullable ? underlying.name : '${underlying.name}?';

  @override
  bool get isImplicitlyNullable => true;

  @override
  Shape get nullable => this;

  @override
  Shape get nonNullable => underlying;

  @override
  int get hashCode => underlying.hashCode * 11;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    return other is NullableShape && underlying == other.underlying;
  }

  @override
  void shapeToDart(DartTemplateBuffer buffer) {
    underlying.shapeToDart(buffer);
    if (!underlying.isImplicitlyNullable) {
      buffer.write('?');
    }
  }

  @override
  Future<bool> isAccessible(DartAccessibility accessibility) =>
      underlying.isAccessible(accessibility);

  @override
  bool get isEnumSubshape => underlying.isEnumSubshape;

  @override
  Uri? get libraryUri => underlying.libraryUri;

  @override
  bool get isPrivate => name.startsWith('_');
}

/// Base class for [Shape]s representing a set of non-null values.
abstract class NonNullableShape extends _BaseShape {
  @override
  late final Shape nullable = new NullableShape(this);

  @override
  Shape get nonNullable => this;

  @override
  bool isSubshapeOf(Shape other) {
    if (super.isSubshapeOf(other)) return true;

    // All non-nullable shapes are subshapes of Object.
    if (other == Shape.nonNullableObject) return true;

    // A non-nullable shape is a subshape of the underlying shape of a nullable
    // shape.
    if (other is NullableShape) {
      return isSubshapeOf(other.underlying);
    }

    return isSubshapeOfInternal(other);
  }

  bool isSubshapeOfInternal(Shape other);

  @override
  String toString() => name;
}

/// [Shape] that behaves like [wrappedShape] but is also a subshape of
/// [impliedShape].
class WrappedShape extends _BaseShape {
  final Shape wrappedShape;
  final Shape impliedShape;

  new(this.wrappedShape, this.impliedShape);

  @override
  Map<Key, Shape> get properties => wrappedShape.properties;

  @override
  Shape? getPropertyShape(ObjectPropertyLookup propertyLookup, Key key) {
    return wrappedShape.getPropertyShape(propertyLookup, key);
  }

  @override
  bool get isRecord => wrappedShape.isRecord;

  @override
  bool get isSealed => wrappedShape.isSealed;

  @override
  String get name => wrappedShape.name;

  @override
  bool get isImplicitlyNullable => wrappedShape.isImplicitlyNullable;

  @override
  Iterable<Shape> getSubshapes(Set<Key> keysOfInterest) {
    Shape wrappedShape = this.wrappedShape;
    Shape impliedShape = this.impliedShape;
    if (wrappedShape is NullableShape && impliedShape is NullableShape) {
      // With nullable shapes we need to avoid carrying the nullable implied
      // shape into the non-nullable subshape since it otherwise wouldn't allow
      // for matching the non-nullable aspect of the wrapped shape with the
      // non-nullable implied shape.
      //
      // For instance
      //
      //     method<O>(O? object) => switch (object) {
      //         O object => 0,
      //         null => 1,
      //       };
      //
      // Here the shape for `O?` is `WrappedShape(Object?, O?)` which allows
      // for matching both by the bound `Object?` and the exact type variable
      // type `O?`. If we split this into the subshapes
      // `WrappedShape(Object, O?)` and `WrappedShape(null, O?)` then we miss
      // that `O object` covers the non-nullable aspect, since `O` is neither a
      // super type of `Object` nor `O?`.
      return [
        new WrappedShape(wrappedShape.underlying, impliedShape.underlying),
        Shape.nullShape,
      ];
    }
    return wrappedShape
        .getSubshapes(keysOfInterest)
        .map((e) => new WrappedShape(e, impliedShape));
  }

  @override
  bool isSubshapeOf(Shape other) {
    if (super.isSubshapeOf(other)) return true;

    return wrappedShape.isSubshapeOf(other) || impliedShape.isSubshapeOf(other);
  }

  @override
  int get hashCode => Object.hash(wrappedShape, impliedShape);

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    return other is WrappedShape &&
        wrappedShape == other.wrappedShape &&
        impliedShape == other.impliedShape;
  }

  @override
  void witnessToDart(
    DartTemplateBuffer buffer,
    PropertyWitness witness,
    Map<Key, PropertyWitness> witnessProperties, {
    required bool forCorrection,
  }) {
    return wrappedShape.witnessToDart(
      buffer,
      witness,
      witnessProperties,
      forCorrection: forCorrection,
    );
  }

  @override
  Future<bool> isAccessible(DartAccessibility accessibility) =>
      wrappedShape.isAccessible(accessibility);

  @override
  late final Shape nonNullable =
      wrappedShape.nonNullable == wrappedShape &&
          impliedShape.nonNullable == impliedShape
      ? this
      : new WrappedShape(wrappedShape.nonNullable, impliedShape.nonNullable);

  @override
  late final Shape nullable =
      wrappedShape.nullable == wrappedShape &&
          impliedShape.nullable == impliedShape
      ? this
      : new WrappedShape(wrappedShape.nullable, impliedShape.nullable);

  @override
  void shapeToDart(DartTemplateBuffer buffer) {
    wrappedShape.shapeToDart(buffer);
  }

  @override
  bool get isEnumSubshape => wrappedShape.isEnumSubshape;

  @override
  Uri? get libraryUri => wrappedShape.libraryUri;

  @override
  bool get isPrivate => wrappedShape.isPrivate;
}

/// Interface for accessing the members defined on `Object`.
abstract class ObjectPropertyLookup {
  /// Returns the [Shape] for the property with the given [key] defined on
  /// `Object`, or `null` none exists.
  Shape? getObjectPropertyShape(Key key);
}
