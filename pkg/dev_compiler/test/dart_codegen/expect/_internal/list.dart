part of dart._internal;
 abstract class FixedLengthListMixin<E> {void set length(int newLength) {
  throw new UnsupportedError("Cannot change the length of a fixed-length list");
  }
 void add(E value) {
  throw new UnsupportedError("Cannot add to a fixed-length list");
  }
 void insert(int index, E value) {
  throw new UnsupportedError("Cannot add to a fixed-length list");
  }
 void insertAll(int at, Iterable<E> iterable) {
  throw new UnsupportedError("Cannot add to a fixed-length list");
  }
 void addAll(Iterable<E> iterable) {
  throw new UnsupportedError("Cannot add to a fixed-length list");
  }
 bool remove(Object element) {
  throw new UnsupportedError("Cannot remove from a fixed-length list");
  }
 void removeWhere(bool test(E element)) {
  throw new UnsupportedError("Cannot remove from a fixed-length list");
  }
 void retainWhere(bool test(E element)) {
  throw new UnsupportedError("Cannot remove from a fixed-length list");
  }
 void clear() {
  throw new UnsupportedError("Cannot clear a fixed-length list");
  }
 E removeAt(int index) {
  throw new UnsupportedError("Cannot remove from a fixed-length list");
  }
 E removeLast() {
  throw new UnsupportedError("Cannot remove from a fixed-length list");
  }
 void removeRange(int start, int end) {
  throw new UnsupportedError("Cannot remove from a fixed-length list");
  }
 void replaceRange(int start, int end, Iterable<E> iterable) {
  throw new UnsupportedError("Cannot remove from a fixed-length list");
  }
}
 abstract class UnmodifiableListMixin<E> implements List<E> {void operator []=(int index, E value) {
throw new UnsupportedError("Cannot modify an unmodifiable list");
}
 void set length(int newLength) {
throw new UnsupportedError("Cannot change the length of an unmodifiable list");
}
 void setAll(int at, Iterable<E> iterable) {
throw new UnsupportedError("Cannot modify an unmodifiable list");
}
 void add(E value) {
throw new UnsupportedError("Cannot add to an unmodifiable list");
}
 E insert(int index, E value) {
throw new UnsupportedError("Cannot add to an unmodifiable list");
}
 void insertAll(int at, Iterable<E> iterable) {
throw new UnsupportedError("Cannot add to an unmodifiable list");
}
 void addAll(Iterable<E> iterable) {
throw new UnsupportedError("Cannot add to an unmodifiable list");
}
 bool remove(Object element) {
throw new UnsupportedError("Cannot remove from an unmodifiable list");
}
 void removeWhere(bool test(E element)) {
throw new UnsupportedError("Cannot remove from an unmodifiable list");
}
 void retainWhere(bool test(E element)) {
throw new UnsupportedError("Cannot remove from an unmodifiable list");
}
 void sort([Comparator<E> compare]) {
throw new UnsupportedError("Cannot modify an unmodifiable list");
}
 void shuffle([Random random]) {
throw new UnsupportedError("Cannot modify an unmodifiable list");
}
 void clear() {
throw new UnsupportedError("Cannot clear an unmodifiable list");
}
 E removeAt(int index) {
throw new UnsupportedError("Cannot remove from an unmodifiable list");
}
 E removeLast() {
throw new UnsupportedError("Cannot remove from an unmodifiable list");
}
 void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
throw new UnsupportedError("Cannot modify an unmodifiable list");
}
 void removeRange(int start, int end) {
throw new UnsupportedError("Cannot remove from an unmodifiable list");
}
 void replaceRange(int start, int end, Iterable<E> iterable) {
throw new UnsupportedError("Cannot remove from an unmodifiable list");
}
 void fillRange(int start, int end, [E fillValue]) {
throw new UnsupportedError("Cannot modify an unmodifiable list");
}
}
 abstract class FixedLengthListBase<E> = ListBase<E> with FixedLengthListMixin<E>;
 abstract class UnmodifiableListBase<E> = ListBase<E> with UnmodifiableListMixin<E>;
 class _ListIndicesIterable extends ListIterable<int> {List _backedList;
 _ListIndicesIterable(this._backedList);
 int get length => _backedList.length;
 int elementAt(int index) {
RangeError.checkValidIndex(index, this);
 return index;
}
}
 class ListMapView<E> implements Map<int, E> {List<E> _values;
 ListMapView(this._values);
 E operator [](int key) => ((__x22) => DDC$RT.cast(__x22, dynamic, E, "CastGeneral", """line 251, column 29 of dart:_internal/list.dart: """, __x22 is E, false))(containsKey(key) ? _values[key] : null);
 int get length => _values.length;
 Iterable<E> get values => new SubListIterable<E>(_values, 0, null);
 Iterable<int> get keys => new _ListIndicesIterable(_values);
 bool get isEmpty => _values.isEmpty;
 bool get isNotEmpty => _values.isNotEmpty;
 bool containsValue(Object value) => _values.contains(value);
 bool containsKey(int key) => key is int && key >= 0 && key < length;
 void forEach(void f(int key, E value)) {
int length = _values.length;
 for (int i = 0; i < length; i++) {
f(i, _values[i]);
 if (length != _values.length) {
throw new ConcurrentModificationError(_values);
}
}
}
 void operator []=(int key, E value) {
throw new UnsupportedError("Cannot modify an unmodifiable map");
}
 E putIfAbsent(int key, E ifAbsent()) {
throw new UnsupportedError("Cannot modify an unmodifiable map");
}
 E remove(int key) {
throw new UnsupportedError("Cannot modify an unmodifiable map");
}
 void clear() {
throw new UnsupportedError("Cannot modify an unmodifiable map");
}
 void addAll(Map<int, E> other) {
throw new UnsupportedError("Cannot modify an unmodifiable map");
}
 String toString() => Maps.mapToString(this);
}
 class ReversedListIterable<E> extends ListIterable<E> {Iterable<E> _source;
 ReversedListIterable(this._source);
 int get length => _source.length;
 E elementAt(int index) => _source.elementAt(_source.length - 1 - index);
}
 abstract class UnmodifiableListError {static UnsupportedError add() => new UnsupportedError("Cannot add to unmodifiable List");
 static UnsupportedError change() => new UnsupportedError("Cannot change the content of an unmodifiable List");
 static UnsupportedError length() => new UnsupportedError("Cannot change length of unmodifiable List");
 static UnsupportedError remove() => new UnsupportedError("Cannot remove from unmodifiable List");
}
 abstract class NonGrowableListError {static UnsupportedError add() => new UnsupportedError("Cannot add to non-growable List");
 static UnsupportedError length() => new UnsupportedError("Cannot change length of non-growable List");
 static UnsupportedError remove() => new UnsupportedError("Cannot remove from non-growable List");
}
 external List makeListFixedLength(List growableList) ;
