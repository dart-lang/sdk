// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Base implementations of [Set].
part of dart.collection;

/// Mixin implementation of [Set].
///
/// This class provides a base implementation of a `Set` that depends only
/// on the abstract members: [add], [contains], [lookup], [remove],
/// [iterator], [length] and [toSet].
///
/// Some of the methods assume that `toSet` creates a modifiable set.
/// If using this mixin for an unmodifiable set,
/// where `toSet` should return an unmodifiable set,
/// it's necessary to reimplement
/// [retainAll], [union], [intersection] and [difference].
///
/// Implementations of `Set` using this mixin should consider also implementing
/// `clear` in constant time. The default implementation works by removing every
/// element.
abstract class SetMixin<E> implements Set<E> {
  // This class reimplements all of [IterableMixin].
  // If/when Dart mixins get more powerful, we should just create a single
  // Mixin class from IterableMixin and the new methods of this class.

  bool add(E value);

  bool contains(Object? element);

  E? lookup(Object? element);

  bool remove(Object? value);

  Iterator<E> get iterator;

  Set<E> toSet();

  int get length;

  bool get isEmpty => length == 0;

  bool get isNotEmpty => length != 0;

  Set<R> cast<R>() => Set.castFrom<E, R>(this);
  Iterable<E> followedBy(Iterable<E> other) =>
      FollowedByIterable<E>.firstEfficient(this, other);

  Iterable<T> whereType<T>() => WhereTypeIterable<T>(this);

  void clear() {
    removeAll(toList());
  }

  void addAll(Iterable<E> elements) {
    for (E element in elements) add(element);
  }

  void removeAll(Iterable<Object?> elements) {
    for (Object? element in elements) remove(element);
  }

  void retainAll(Iterable<Object?> elements) {
    // Create a copy of the set, remove all of elements from the copy,
    // then remove all remaining elements in copy from this.
    Set<E> toRemove = toSet();
    for (Object? o in elements) {
      toRemove.remove(o);
    }
    removeAll(toRemove);
  }

  void removeWhere(bool test(E element)) {
    List<Object?> toRemove = [];
    for (E element in this) {
      if (test(element)) toRemove.add(element);
    }
    removeAll(toRemove);
  }

  void retainWhere(bool test(E element)) {
    List<Object?> toRemove = [];
    for (E element in this) {
      if (!test(element)) toRemove.add(element);
    }
    removeAll(toRemove);
  }

  bool containsAll(Iterable<Object?> other) {
    for (var o in other) {
      if (!contains(o)) return false;
    }
    return true;
  }

  Set<E> union(Set<E> other) {
    return toSet()..addAll(other);
  }

  Set<E> intersection(Set<Object?> other) {
    Set<E> result = toSet();
    for (E element in this) {
      if (!other.contains(element)) result.remove(element);
    }
    return result;
  }

  Set<E> difference(Set<Object?> other) {
    Set<E> result = toSet();
    for (E element in this) {
      if (other.contains(element)) result.remove(element);
    }
    return result;
  }

  List<E> toList({bool growable = true}) =>
      List<E>.of(this, growable: growable);

  Iterable<T> map<T>(T f(E element)) =>
      EfficientLengthMappedIterable<E, T>(this, f);

  E get single {
    if (length > 1) throw IterableElementError.tooMany();
    Iterator<E> it = iterator;
    if (!it.moveNext()) throw IterableElementError.noElement();
    E result = it.current;
    return result;
  }

  String toString() => IterableBase.iterableToFullString(this, '{', '}');

  // Copied from IterableMixin.
  // Should be inherited if we had multi-level mixins.

  Iterable<E> where(bool f(E element)) => WhereIterable<E>(this, f);

  Iterable<T> expand<T>(Iterable<T> f(E element)) =>
      ExpandIterable<E, T>(this, f);

  void forEach(void f(E element)) {
    for (E element in this) f(element);
  }

  E reduce(E combine(E value, E element)) {
    Iterator<E> iterator = this.iterator;
    if (!iterator.moveNext()) {
      throw IterableElementError.noElement();
    }
    E value = iterator.current;
    while (iterator.moveNext()) {
      value = combine(value, iterator.current);
    }
    return value;
  }

  T fold<T>(T initialValue, T combine(T previousValue, E element)) {
    var value = initialValue;
    for (E element in this) value = combine(value, element);
    return value;
  }

  bool every(bool f(E element)) {
    for (E element in this) {
      if (!f(element)) return false;
    }
    return true;
  }

  String join([String separator = ""]) {
    Iterator<E> iterator = this.iterator;
    if (!iterator.moveNext()) return "";
    StringBuffer buffer = StringBuffer();
    if (separator == null || separator == "") {
      do {
        buffer.write(iterator.current);
      } while (iterator.moveNext());
    } else {
      buffer.write(iterator.current);
      while (iterator.moveNext()) {
        buffer.write(separator);
        buffer.write(iterator.current);
      }
    }
    return buffer.toString();
  }

  bool any(bool test(E element)) {
    for (E element in this) {
      if (test(element)) return true;
    }
    return false;
  }

  Iterable<E> take(int n) {
    return TakeIterable<E>(this, n);
  }

  Iterable<E> takeWhile(bool test(E value)) {
    return TakeWhileIterable<E>(this, test);
  }

  Iterable<E> skip(int n) {
    return SkipIterable<E>(this, n);
  }

  Iterable<E> skipWhile(bool test(E value)) {
    return SkipWhileIterable<E>(this, test);
  }

  E get first {
    Iterator<E> it = iterator;
    if (!it.moveNext()) {
      throw IterableElementError.noElement();
    }
    return it.current;
  }

  E get last {
    Iterator<E> it = iterator;
    if (!it.moveNext()) {
      throw IterableElementError.noElement();
    }
    E result;
    do {
      result = it.current;
    } while (it.moveNext());
    return result;
  }

  E firstWhere(bool test(E value), {E Function()? orElse}) {
    for (E element in this) {
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E lastWhere(bool test(E value), {E Function()? orElse}) {
    late E result;
    bool foundMatching = false;
    for (E element in this) {
      if (test(element)) {
        result = element;
        foundMatching = true;
      }
    }
    if (foundMatching) return result;
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E singleWhere(bool test(E value), {E Function()? orElse}) {
    late E result;
    bool foundMatching = false;
    for (E element in this) {
      if (test(element)) {
        if (foundMatching) {
          throw IterableElementError.tooMany();
        }
        result = element;
        foundMatching = true;
      }
    }
    if (foundMatching) return result;
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E elementAt(int index) {
    ArgumentError.checkNotNull(index, "index");
    RangeError.checkNotNegative(index, "index");
    int elementIndex = 0;
    for (E element in this) {
      if (index == elementIndex) return element;
      elementIndex++;
    }
    throw RangeError.index(index, this, "index", null, elementIndex);
  }
}

/// Base implementation of [Set].
///
/// This class provides a base implementation of a `Set` that depends only
/// on the abstract members: [add], [contains], [lookup], [remove],
/// [iterator], [length] and [toSet].
///
/// Some of the methods assume that `toSet` creates a modifiable set.
/// If using this base class for an unmodifiable set,
/// where `toSet` should return an unmodifiable set,
/// it's necessary to reimplement
/// [retainAll], [union], [intersection] and [difference].
///
/// Implementations of `Set` using this base should consider also implementing
/// `clear` in constant time. The default implementation works by removing every
/// element.
abstract class SetBase<E> extends Object with SetMixin<E> {
  /// Converts a [Set] to a [String].
  ///
  /// Converts [set] to a string by converting each element to a string (by
  /// calling [Object.toString]), joining them with ", ", and wrapping the
  /// result in "{" and "}".
  ///
  /// Handles circular references where converting one of the elements
  /// to a string ends up converting [set] to a string again.
  static String setToString(Set set) =>
      IterableBase.iterableToFullString(set, '{', '}');
}

/// Common internal implementation of some [Set] methods.
// TODO(35548): Make this mix-in SetMixin, by adding `with SetMixin<E>`
// and removing the copied members below,
// when analyzer supports const constructors for mixin applications.
abstract class _SetBase<E> implements Set<E> {
  // The following two methods override the ones in SetBase.
  // It's possible to be more efficient if we have a way to create an empty
  // set of the correct type.
  const _SetBase();

  Set<E> _newSet();

  Set<R> _newSimilarSet<R>();

  Set<R> cast<R>() => Set.castFrom<E, R>(this, newSet: _newSimilarSet);

  Set<E> difference(Set<Object?> other) {
    Set<E> result = _newSet();
    for (var element in this) {
      if (!other.contains(element)) result.add(element);
    }
    return result;
  }

  Set<E> intersection(Set<Object?> other) {
    Set<E> result = _newSet();
    for (var element in this) {
      if (other.contains(element)) result.add(element);
    }
    return result;
  }

  // Subclasses can optimize this further.
  Set<E> toSet() => _newSet()..addAll(this);

  /// TODO(35548): Remove the following declarations again when the analyzer
  /// supports mixins with const constructors, and mix in `SetMixin` instead.

  bool get isEmpty => length == 0;

  bool get isNotEmpty => length != 0;

  Iterable<E> followedBy(Iterable<E> other) =>
      FollowedByIterable<E>.firstEfficient(this, other);

  Iterable<T> whereType<T>() => WhereTypeIterable<T>(this);

  void clear() {
    removeAll(toList());
  }

  void addAll(Iterable<E> elements) {
    for (E element in elements) add(element);
  }

  void removeAll(Iterable<Object?> elements) {
    for (Object? element in elements) remove(element);
  }

  void retainAll(Iterable<Object?> elements) {
    // Create a copy of the set, remove all of elements from the copy,
    // then remove all remaining elements in copy from this.
    Set<E> toRemove = toSet();
    for (Object? o in elements) {
      toRemove.remove(o);
    }
    removeAll(toRemove);
  }

  void removeWhere(bool test(E element)) {
    List<Object?> toRemove = [];
    for (E element in this) {
      if (test(element)) toRemove.add(element);
    }
    removeAll(toRemove);
  }

  void retainWhere(bool test(E element)) {
    List<Object?> toRemove = [];
    for (E element in this) {
      if (!test(element)) toRemove.add(element);
    }
    removeAll(toRemove);
  }

  bool containsAll(Iterable<Object?> other) {
    for (Object? o in other) {
      if (!contains(o)) return false;
    }
    return true;
  }

  Set<E> union(Set<E> other) {
    return toSet()..addAll(other);
  }

  List<E> toList({bool growable = true}) =>
      List<E>.of(this, growable: growable);

  Iterable<T> map<T>(T f(E element)) =>
      EfficientLengthMappedIterable<E, T>(this, f);

  E get single {
    if (length > 1) throw IterableElementError.tooMany();
    Iterator<E> it = iterator;
    if (!it.moveNext()) throw IterableElementError.noElement();
    E result = it.current;
    return result;
  }

  String toString() => IterableBase.iterableToFullString(this, '{', '}');

  Iterable<E> where(bool f(E element)) => WhereIterable<E>(this, f);

  Iterable<T> expand<T>(Iterable<T> f(E element)) =>
      ExpandIterable<E, T>(this, f);

  void forEach(void f(E element)) {
    for (E element in this) f(element);
  }

  E reduce(E combine(E value, E element)) {
    Iterator<E> iterator = this.iterator;
    if (!iterator.moveNext()) {
      throw IterableElementError.noElement();
    }
    E value = iterator.current;
    while (iterator.moveNext()) {
      value = combine(value, iterator.current);
    }
    return value;
  }

  T fold<T>(T initialValue, T combine(T previousValue, E element)) {
    var value = initialValue;
    for (E element in this) value = combine(value, element);
    return value;
  }

  bool every(bool f(E element)) {
    for (E element in this) {
      if (!f(element)) return false;
    }
    return true;
  }

  String join([String separator = ""]) {
    Iterator<E> iterator = this.iterator;
    if (!iterator.moveNext()) return "";
    StringBuffer buffer = StringBuffer();
    if (separator == null || separator == "") {
      do {
        buffer.write(iterator.current);
      } while (iterator.moveNext());
    } else {
      buffer.write(iterator.current);
      while (iterator.moveNext()) {
        buffer.write(separator);
        buffer.write(iterator.current);
      }
    }
    return buffer.toString();
  }

  bool any(bool test(E element)) {
    for (E element in this) {
      if (test(element)) return true;
    }
    return false;
  }

  Iterable<E> take(int n) {
    return TakeIterable<E>(this, n);
  }

  Iterable<E> takeWhile(bool test(E value)) {
    return TakeWhileIterable<E>(this, test);
  }

  Iterable<E> skip(int n) {
    return SkipIterable<E>(this, n);
  }

  Iterable<E> skipWhile(bool test(E value)) {
    return SkipWhileIterable<E>(this, test);
  }

  E get first {
    Iterator<E> it = iterator;
    if (!it.moveNext()) {
      throw IterableElementError.noElement();
    }
    return it.current;
  }

  E get last {
    Iterator<E> it = iterator;
    if (!it.moveNext()) {
      throw IterableElementError.noElement();
    }
    E result;
    do {
      result = it.current;
    } while (it.moveNext());
    return result;
  }

  E firstWhere(bool test(E value), {E Function()? orElse}) {
    for (E element in this) {
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E lastWhere(bool test(E value), {E Function()? orElse}) {
    late E result;
    bool foundMatching = false;
    for (E element in this) {
      if (test(element)) {
        result = element;
        foundMatching = true;
      }
    }
    if (foundMatching) return result;
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E singleWhere(bool test(E value), {E Function()? orElse}) {
    late E result;
    bool foundMatching = false;
    for (E element in this) {
      if (test(element)) {
        if (foundMatching) {
          throw IterableElementError.tooMany();
        }
        result = element;
        foundMatching = true;
      }
    }
    if (foundMatching) return result;
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  E elementAt(int index) {
    ArgumentError.checkNotNull(index, "index");
    RangeError.checkNotNegative(index, "index");
    int elementIndex = 0;
    for (E element in this) {
      if (index == elementIndex) return element;
      elementIndex++;
    }
    throw RangeError.index(index, this, "index", null, elementIndex);
  }
}

/// Class used to implement const sets.
class _UnmodifiableSet<E> extends _SetBase<E> {
  final Map<E, Null> _map;

  const _UnmodifiableSet(this._map);

  Set<E> _newSet() => LinkedHashSet<E>();

  Set<R> _newSimilarSet<R>() => LinkedHashSet<R>();

  // Lookups use map methods.

  bool contains(Object? element) => _map.containsKey(element);

  Iterator<E> get iterator => _map.keys.iterator;

  int get length => _map.length;

  E? lookup(Object? element) {
    for (var key in _map.keys) {
      if (key == element) return key;
    }
    return null;
  }

  // Mutating methods throw.

  bool add(E value) {
    throw UnsupportedError("Cannot change unmodifiable set");
  }

  void clear() {
    throw UnsupportedError("Cannot change unmodifiable set");
  }

  void addAll(Iterable<E> elements) {
    throw UnsupportedError("Cannot change unmodifiable set");
  }

  void removeAll(Iterable<Object?> elements) {
    throw UnsupportedError("Cannot change unmodifiable set");
  }

  void retainAll(Iterable<Object?> elements) {
    throw UnsupportedError("Cannot change unmodifiable set");
  }

  void removeWhere(bool test(E element)) {
    throw UnsupportedError("Cannot change unmodifiable set");
  }

  void retainWhere(bool test(E element)) {
    throw UnsupportedError("Cannot change unmodifiable set");
  }

  bool remove(Object? value) {
    throw UnsupportedError("Cannot change unmodifiable set");
  }
}
