class DOMType extends DOMWrapperBase {
  // FIXME: Remove if/when Dart supports OLS for all objects.
  var dartObjectLocalStorage;

  String get typeName() {
    throw new UnsupportedOperationException("typeName must be overridden.");
  }
}

class ListBase<E> extends DOMType implements List<E> {
  ListBase();

  void forEach(void f(E element)) => Collections.forEach(this, f);
  Collection<E> filter(bool f(E element)) => Collections.filter(this, [], f);
  bool every(bool f(E element)) => Collections.every(this, f);
  bool some(bool f(E element)) => Collections.some(this, f);
  bool isEmpty() => Collections.isEmpty(this);

  void sort(int compare(E a, E b)) {
    throw 'Unsupported yet';
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    Arrays.copy(src, srcStart, this, dstStart, count);
  }

  int indexOf(E element, int startIndex) {
    // FIXME: switch to dart:coreimpl when de'Array'ed.
    if (startIndex >= length) {
      return -1;
    }
    if (startIndex < 0) {
      startIndex = 0;
    }
    for (int i = startIndex; i < length; i++) {
      if (this[i] == element) {
        return i;
      }
    }
    return -1;
  }

  int lastIndexOf(E element, int startIndex) {
    // FIXME: switch to dart:coreimpl when de'Array'ed.
    if (startIndex < 0) {
      return -1;
    }
    if (startIndex >= length) {
      startIndex = length - 1;
    }
    for (int i = startIndex; i >= 0; i--) {
      if (this[i] == element) {
        return i;
      }
    }
    return -1;
  }

  E last() => this[length - 1];

  // FIXME: implement those.
  void setRange(int start, int length, List<E> from, [int startFrom]) {
    throw const NotImplementedException();
  }
  void removeRange(int start, int length) {
    throw const NotImplementedException();
  }
  void insertRange(int start, int length, [E initialValue]) {
    throw const NotImplementedException();
  }
  List<E> getRange(int start, int length) {
    throw const NotImplementedException();
  }

  Iterator<E> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new _FixedSizeListIterator<E>(this);
  }
}

// FIXME: switch to one from dart:coreimpl when DartVM is de'Array'ed.
// Iterator for lists with fixed size.
class _FixedSizeListIterator<E> implements Iterator<E> {
  _FixedSizeListIterator(List list)
      : _list = list, _length = list.length, _pos = 0 {
  }

  bool hasNext() => _length > _pos;

  E next() {
    if (!hasNext()) {
      throw const NoMoreElementsException();
    }
    return _list[_pos++];
  }

  final List<E> _list;
  final int _length;  // Cache array length for faster access.
  int _pos;
}

class MapBase<K, V> extends DOMType implements Map<K, V> {
  MapBase();

  bool containsValue(V value) => Maps.containsValue(this, value);
  bool containsKey(K key) => Maps.containsKey(this, key);
  V putIfAbsent(K key, V ifAbsent()) => Maps.putIfAbsent(this, key, ifAbsent);
  clear() => Maps.clear(this);
  forEach(void f(K key, V value)) => Maps.forEach(this, f);
  Collection<V> getValues() => Maps.getValues(this);
  int get length() => Maps.length(this);
  bool isEmpty() => Maps.isEmpty(this);

  V operator [](K key) {
    throw 'Must be implemented';
  }

  operator []=(K key, V value) {
    throw 'Immutable collection';
  }

  V remove(K key) {
    throw 'Immutable collection';
  }

  Collection<K> getKeys() {
    throw 'Must be implemented';
  }
}
