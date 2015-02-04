part of dart.collection;

abstract class _HashSetBase<E> extends SetBase<E> {
  Set<E> difference(Set<Object> other) {
    Set<E> result = _newSet();
    for (var element in this) {
      if (!other.contains(element)) result.add(DDC$RT.cast(element, dynamic, E,
          "CastGeneral",
          """line 17, column 48 of dart:collection/hash_set.dart: """,
          element is E, false));
    }
    return result;
  }
  Set<E> intersection(Set<Object> other) {
    Set<E> result = _newSet();
    for (var element in this) {
      if (other.contains(element)) result.add(DDC$RT.cast(element, dynamic, E,
          "CastGeneral",
          """line 25, column 47 of dart:collection/hash_set.dart: """,
          element is E, false));
    }
    return result;
  }
  Set<E> _newSet();
  Set<E> toSet() => _newSet()..addAll(this);
}
abstract class HashSet<E> implements Set<E> {
  external factory HashSet({bool equals(E e1, E e2), int hashCode(E e),
      bool isValidKey(potentialKey)});
  external factory HashSet.identity();
  factory HashSet.from(Iterable elements) {
    HashSet<E> result = new HashSet<E>();
    for (E e in elements) result.add(e);
    return result;
  }
  Iterator<E> get iterator;
}
