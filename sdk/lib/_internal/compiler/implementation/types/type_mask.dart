// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of types;

/**
 * A type mask represents a set of contained classes, but the
 * operations on it are not guaranteed to be precise and they may
 * yield conservative answers that contain too many classes.
 */
abstract class TypeMask {
  factory TypeMask(ClassElement base, int kind, bool isNullable)
      => new FlatTypeMask(base, kind, isNullable);

  const factory TypeMask.empty() = FlatTypeMask.empty;

  factory TypeMask.exact(ClassElement base)
      => new FlatTypeMask.exact(base);
  factory TypeMask.subclass(ClassElement base)
      => new FlatTypeMask.subclass(base);
  factory TypeMask.subtype(ClassElement base)
      => new FlatTypeMask.subtype(base);

  const factory TypeMask.nonNullEmpty() = FlatTypeMask.nonNullEmpty;
  factory TypeMask.nonNullExact(ClassElement base)
      => new FlatTypeMask.nonNullExact(base);
  factory TypeMask.nonNullSubclass(ClassElement base)
      => new FlatTypeMask.nonNullSubclass(base);
  factory TypeMask.nonNullSubtype(ClassElement base)
      => new FlatTypeMask.nonNullSubtype(base);

  factory TypeMask.unionOf(Iterable<TypeMask> masks, Compiler compiler) {
    return UnionTypeMask.unionOf(masks, compiler);
  }

  /**
   * Returns a nullable variant of [this] type mask.
   */
  TypeMask nullable();

  /**
   * Returns a non-nullable variant of [this] type mask.
   */
  TypeMask nonNullable();

  bool get isEmpty;
  bool get isNullable;
  bool get isExact;

  bool get isUnion;
  bool get isContainer;
  bool get isMap;
  bool get isDictionary;
  bool get isForwarding;
  bool get isValue;

  bool containsOnlyInt(Compiler compiler);
  bool containsOnlyDouble(Compiler compiler);
  bool containsOnlyNum(Compiler compiler);
  bool containsOnlyBool(Compiler compiler);
  bool containsOnlyString(Compiler compiler);
  bool containsOnly(ClassElement element);

  /**
   * Returns whether this type mask is a subtype of [other].
   */
  bool isInMask(TypeMask other, Compiler compiler);

  /**
   * Returns whether [other] is a subtype of this type mask.
   */
  bool containsMask(TypeMask other, Compiler compiler);

  /**
   * Returns whether this type mask is an instance of [cls].
   */
  bool satisfies(ClassElement cls, Compiler compiler);

  /**
   * Returns whether or not this type mask contains the given type.
   */
  bool contains(ClassElement type, Compiler compiler);

  /**
   * Returns whether or not this type mask contains all types.
   */
  bool containsAll(Compiler compiler);

  /**
   * Returns the [ClassElement] if this type represents a single class,
   * otherwise returns `null`.  This method is conservative.
   */
  ClassElement singleClass(Compiler compiler);

  /**
   * Returns a type mask representing the union of [this] and [other].
   */
  TypeMask union(TypeMask other, Compiler compiler);

  /**
   * Returns a type mask representing the intersection of [this] and [other].
   */
  TypeMask intersection(TypeMask other, Compiler compiler);

  /**
   * Returns whether this [TypeMask] applied to [selector] can hit a
   * [noSuchMethod].
   */
  bool needsNoSuchMethodHandling(Selector selector, World world);

  /**
   * Returns whether [element] is a potential target when being
   * invoked on this type mask. [selector] is used to ensure library
   * privacy is taken into account.
   */
  bool canHit(Element element, Selector selector, World world);

  /**
   * Returns the [element] that is known to always be hit at runtime
   * on this mask. Returns null if there is none.
   */
  Element locateSingleElement(Selector selector, Compiler compiler);
}
