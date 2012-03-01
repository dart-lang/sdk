
class _StyleSheetListImpl extends _DOMTypeBase implements StyleSheetList {
  _StyleSheetListImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  StyleSheet operator[](int index) => _wrap(_ptr[index]);


  void operator[]=(int index, StyleSheet value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  void add(StyleSheet value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(StyleSheet value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<StyleSheet> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void sort(int compare(StyleSheet a, StyleSheet b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw new UnsupportedOperationException("This object is immutable.");
  }

  int indexOf(StyleSheet element, [int start = 0]) {
    return _Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(StyleSheet element, [int start = null]) {
    if (start === null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int clear() {
    throw new UnsupportedOperationException("Cannot clear immutable List.");
  }

  StyleSheet removeLast() {
    throw new UnsupportedOperationException("Cannot removeLast on immutable List.");
  }

  StyleSheet last() {
    return this[length - 1];
  }

  void forEach(void f(StyleSheet element)) {
    _Collections.forEach(this, f);
  }

  Collection map(f(StyleSheet element)) {
    return _Collections.map(this, [], f);
  }

  Collection<StyleSheet> filter(bool f(StyleSheet element)) {
    return _Collections.filter(this, new List<StyleSheet>(), f);
  }

  bool every(bool f(StyleSheet element)) {
    return _Collections.every(this, f);
  }

  bool some(bool f(StyleSheet element)) {
    return _Collections.some(this, f);
  }

  void setRange(int start, int length, List<StyleSheet> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int length, [StyleSheet initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }

  List<StyleSheet> getRange(int start, int length) {
    throw new NotImplementedException();
  }

  bool isEmpty() {
    return length == 0;
  }

  Iterator<StyleSheet> iterator() {
    return new _FixedSizeListIterator<StyleSheet>(this);
  }

  StyleSheet item(int index) {
    return _wrap(_ptr.item(_unwrap(index)));
  }
}
