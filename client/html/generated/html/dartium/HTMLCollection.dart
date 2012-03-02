
class _HTMLCollectionImpl extends _DOMTypeBase implements HTMLCollection {
  _HTMLCollectionImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  Node operator[](int index) => _wrap(_ptr[index]);


  void operator[]=(int index, Node value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  void add(Node value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(Node value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<Node> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void sort(int compare(Node a, Node b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw new UnsupportedOperationException("This object is immutable.");
  }

  int indexOf(Node element, [int start = 0]) {
    return _Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(Node element, [int start = null]) {
    if (start === null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int clear() {
    throw new UnsupportedOperationException("Cannot clear immutable List.");
  }

  Node removeLast() {
    throw new UnsupportedOperationException("Cannot removeLast on immutable List.");
  }

  Node last() {
    return this[length - 1];
  }

  void forEach(void f(Node element)) {
    _Collections.forEach(this, f);
  }

  Collection map(f(Node element)) {
    return _Collections.map(this, [], f);
  }

  Collection<Node> filter(bool f(Node element)) {
    return _Collections.filter(this, new List<Node>(), f);
  }

  bool every(bool f(Node element)) {
    return _Collections.every(this, f);
  }

  bool some(bool f(Node element)) {
    return _Collections.some(this, f);
  }

  void setRange(int start, int length, List<Node> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int length, [Node initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }

  List<Node> getRange(int start, int length) {
    throw new NotImplementedException();
  }

  bool isEmpty() {
    return length == 0;
  }

  Iterator<Node> iterator() {
    return new _FixedSizeListIterator<Node>(this);
  }

  Node item(int index) {
    return _wrap(_ptr.item(_unwrap(index)));
  }

  Node namedItem(String name) {
    return _wrap(_ptr.namedItem(_unwrap(name)));
  }
}
