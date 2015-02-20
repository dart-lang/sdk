part of dart.collection;

abstract class LinkedHashSet<E> implements HashSet<E> {
  @patch factory LinkedHashSet({bool equals(E e1, E e2), int hashCode(E e),
      bool isValidKey(potentialKey)}) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return new _LinkedHashSet<E>();
        }
        hashCode = _defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return new _LinkedIdentityHashSet<E>();
        }
        if (equals == null) {
          equals = _defaultEquals;
        }
      }
    } else {
      if (hashCode == null) {
        hashCode = _defaultHashCode;
      }
      if (equals == null) {
        equals = _defaultEquals;
      }
    }
    return new _LinkedCustomHashSet<E>(equals, hashCode, isValidKey);
  }
  @patch factory LinkedHashSet.identity() = _LinkedIdentityHashSet<E>;
  factory LinkedHashSet.from(Iterable<E> elements) {
    LinkedHashSet<E> result = new LinkedHashSet<E>();
    for (final E element in elements) {
      result.add(element);
    }
    return result;
  }
  void forEach(void action(E element));
  Iterator<E> get iterator;
}
