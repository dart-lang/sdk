
class _Float64ArrayImpl extends _ArrayBufferViewImpl implements Float64Array, List<num> {
  _Float64ArrayImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  num operator[](int index) => _wrap(_ptr[index]);


  void operator[]=(int index, num value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  void add(num value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(num value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<num> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void sort(int compare(num a, num b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw new UnsupportedOperationException("This object is immutable.");
  }

  int indexOf(num element, [int start = 0]) {
    return _Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(num element, [int start = null]) {
    if (start === null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int clear() {
    throw new UnsupportedOperationException("Cannot clear immutable List.");
  }

  num removeLast() {
    throw new UnsupportedOperationException("Cannot removeLast on immutable List.");
  }

  num last() {
    return this[length - 1];
  }

  void forEach(void f(num element)) {
    _Collections.forEach(this, f);
  }

  Collection map(f(num element)) {
    return _Collections.map(this, [], f);
  }

  Collection<num> filter(bool f(num element)) {
    return _Collections.filter(this, new List<num>(), f);
  }

  bool every(bool f(num element)) {
    return _Collections.every(this, f);
  }

  bool some(bool f(num element)) {
    return _Collections.some(this, f);
  }

  void setRange(int start, int length, List<num> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int length, [num initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }

  List<num> getRange(int start, int length) {
    throw new NotImplementedException();
  }

  bool isEmpty() {
    return length == 0;
  }

  Iterator<num> iterator() {
    return new _FixedSizeListIterator<num>(this);
  }

  void setElements(Object array, [int offset = null]) {
    if (offset === null) {
      _ptr.setElements(_unwrap(array));
      return;
    } else {
      _ptr.setElements(_unwrap(array), _unwrap(offset));
      return;
    }
  }

  Float64Array subarray(int start, [int end = null]) {
    if (end === null) {
      return _wrap(_ptr.subarray(_unwrap(start)));
    } else {
      return _wrap(_ptr.subarray(_unwrap(start), _unwrap(end)));
    }
  }
}
