
class _Float64ArrayJs extends _ArrayBufferViewJs implements Float64Array, List<num> native "*Float64Array" {

  factory Float64Array(int length) =>  _construct_Float64Array(length);

  factory Float64Array.fromList(List<num> list) => _construct_Float64Array(list);

  factory Float64Array.fromBuffer(ArrayBuffer buffer) => _construct_Float64Array(buffer);

  static _construct_Float64Array(arg) native 'return new Float64Array(arg);';

  static final int BYTES_PER_ELEMENT = 8;

  final int length;

  num operator[](int index) native "return this[index];";

  void operator[]=(int index, num value) native "this[index] = value";
  // -- start List<num> mixins.
  // num is the element type.

  // From Iterable<num>:

  Iterator<num> iterator() {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new _FixedSizeListIterator<num>(this);
  }

  // From Collection<num>:

  void add(num value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(num value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<num> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void forEach(void f(num element)) => _Collections.forEach(this, f);

  Collection map(f(num element)) => _Collections.map(this, [], f);

  Collection<num> filter(bool f(num element)) =>
     _Collections.filter(this, <num>[], f);

  bool every(bool f(num element)) => _Collections.every(this, f);

  bool some(bool f(num element)) => _Collections.some(this, f);

  bool isEmpty() => this.length == 0;

  // From List<num>:

  void sort(int compare(num a, num b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  int indexOf(num element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(num element, [int start = 0]) =>
      _Lists.lastIndexOf(this, element, start);

  num last() => this[length - 1];

  // FIXME: implement thesee.
  void setRange(int start, int length, List<num> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }
  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }
  void insertRange(int start, int length, [num initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }
  List<num> getRange(int start, int length) =>
      _Lists.getRange(this, start, length, <num>[]);

  // -- end List<num> mixins.

  void setElements(Object array, [int offset = null]) native;

  _Float64ArrayJs subarray(int start, [int end = null]) native;
}
