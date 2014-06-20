// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// TODO(srdjan): Use shared array implementation.
class _List<E> implements List<E> {
  static final int _classId = ClassID.getID(new _List(0));

  factory _List(length) native "List_allocate";

  E operator [](int index) native "List_getIndexed";

  void operator []=(int index, E value) native "List_setIndexed";

  String toString() {
    return ListBase.listToString(this);
  }

  int get length native "List_getLength";

  void _copyFromObjectArray(_List src,
                            int srcStart,
                            int dstStart,
                            int count)
      native "List_copyFromObjectArray";

  void insert(int index, E element) {
    throw NonGrowableListError.add();
  }

  void insertAll(int index, Iterable<E> iterable) {
    throw NonGrowableListError.add();
  }

  void setAll(int index, Iterable<E> iterable) {
    IterableMixinWorkaround.setAllList(this, index, iterable);
  }

  E removeAt(int index) {
    throw NonGrowableListError.remove();
  }

  bool remove(Object element) {
    throw NonGrowableListError.remove();
  }

  void removeWhere(bool test(E element)) {
    throw NonGrowableListError.remove();
  }

  void retainWhere(bool test(E element)) {
    throw NonGrowableListError.remove();
  }

  Iterable<E> getRange(int start, [int end]) {
    return IterableMixinWorkaround.getRangeList(this, start, end);
  }

  // List interface.
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    if (start < 0 || start > this.length) {
      throw new RangeError.range(start, 0, this.length);
    }
    if (end < start || end > this.length) {
      throw new RangeError.range(end, start, this.length);
    }
    int length = end - start;
    if (length == 0) return;

    if (iterable is _List) {
      _copyFromObjectArray(iterable, skipCount, start, length);
    } else {
      if (iterable is List) {
        Lists.copy(iterable, skipCount, this, start, length);
      } else {
        Iterator it = iterable.iterator;
        while (skipCount > 0) {
          if (!it.moveNext()) return;
          skipCount--;
        }
        for (int i = start; i < end; i++) {
          if (!it.moveNext()) return;
          this[i] = it.current;
        }
      }
    }
  }

  void removeRange(int start, int end) {
    throw NonGrowableListError.remove();
  }

  void replaceRange(int start, int end, Iterable<E> iterable) {
    throw NonGrowableListError.remove();
  }

  void fillRange(int start, int end, [E fillValue]) {
    IterableMixinWorkaround.fillRangeList(this, start, end, fillValue);
  }

  List<E> sublist(int start, [int end]) {
    Lists.indicesCheck(this, start, end);
    if (end == null) end = this.length;
    int length = end - start;
    if (start == end) return [];
    List list = new _GrowableList<E>.withCapacity(length);
    list.length = length;
    Lists.copy(this, start, list, 0, length);
    return list;
  }

  // Iterable interface.

  bool contains(Object element) {
    return IterableMixinWorkaround.contains(this, element);
  }

  void forEach(f(E element)) {
    IterableMixinWorkaround.forEach(this, f);
  }

  String join([String separator = ""]) {
    return IterableMixinWorkaround.joinList(this, separator);
  }

  Iterable map(f(E element)) {
    return IterableMixinWorkaround.mapList(this, f);
  }

  E reduce(E combine(E value, E element)) {
    return IterableMixinWorkaround.reduce(this, combine);
  }

  fold(initialValue, combine(previousValue, E element)) {
    return IterableMixinWorkaround.fold(this, initialValue, combine);
  }

  Iterable<E> where(bool f(E element)) {
    return IterableMixinWorkaround.where(this, f);
  }

  Iterable expand(Iterable f(E element)) {
    return IterableMixinWorkaround.expand(this, f);
  }

  Iterable<E> take(int n) {
    return IterableMixinWorkaround.takeList(this, n);
  }

  Iterable<E> takeWhile(bool test(E value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  Iterable<E> skip(int n) {
    return IterableMixinWorkaround.skipList(this, n);
  }

  Iterable<E> skipWhile(bool test(E value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  bool every(bool f(E element)) {
    return IterableMixinWorkaround.every(this, f);
  }

  bool any(bool f(E element)) {
    return IterableMixinWorkaround.any(this, f);
  }

  E firstWhere(bool test(E value), {E orElse()}) {
    return IterableMixinWorkaround.firstWhere(this, test, orElse);
  }

  E lastWhere(bool test(E value), {E orElse()}) {
    return IterableMixinWorkaround.lastWhereList(this, test, orElse);
  }

  E singleWhere(bool test(E value)) {
    return IterableMixinWorkaround.singleWhere(this, test);
  }

  E elementAt(int index) {
    return this[index];
  }

  bool get isEmpty {
    return this.length == 0;
  }

  bool get isNotEmpty => !isEmpty;

  Iterable<E> get reversed => IterableMixinWorkaround.reversedList(this);

  void sort([int compare(E a, E b)]) {
    IterableMixinWorkaround.sortList(this, compare);
  }

  void shuffle([Random random]) {
    IterableMixinWorkaround.shuffleList(this, random);
  }

  int indexOf(Object element, [int start = 0]) {
    return Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(Object element, [int start = null]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  Iterator<E> get iterator {
    return new _FixedSizeArrayIterator<E>(this);
  }

  void add(E element) {
    throw NonGrowableListError.add();
  }

  void addAll(Iterable<E> iterable) {
    throw NonGrowableListError.add();
  }

  void clear() {
    throw NonGrowableListError.remove();
  }

  void set length(int length) {
    throw NonGrowableListError.length();
  }

  E removeLast() {
    throw NonGrowableListError.remove();
  }

  E get first {
    if (length > 0) return this[0];
    throw IterableElementError.noElement();
  }

  E get last {
    if (length > 0) return this[length - 1];
    throw IterableElementError.noElement();
  }

  E get single {
    if (length == 1) return this[0];
    if (length == 0) throw IterableElementError.noElement();
    throw IterableElementError.tooMany();
  }

  List<E> toList({ bool growable: true}) {
    return new List<E>.from(this, growable: growable);
  }

  Set<E> toSet() {
    return new Set<E>.from(this);
  }

  Map<int, E> asMap() {
    return IterableMixinWorkaround.asMapList(this);
  }
}


// This is essentially the same class as _List, but it does not
// permit any modification of array elements from Dart code. We use
// this class for arrays constructed from Dart array literals.
// TODO(hausner): We should consider the trade-offs between two
// classes (and inline cache misses) versus a field in the native
// implementation (checks when modifying). We should keep watching
// the inline cache misses.
class _ImmutableList<E> implements List<E> {
  static final int _classId = ClassID.getID(const []);

  factory _ImmutableList._uninstantiable() {
    throw new UnsupportedError(
        "ImmutableArray can only be allocated by the VM");
  }

  factory _ImmutableList._from(List from, int offset, int length)
      native "ImmutableList_from";

  E operator [](int index) native "List_getIndexed";

  void operator []=(int index, E value) {
    throw UnmodifiableListError.change();
  }

  int get length native "List_getLength";

  void insert(int index, E element) {
    throw UnmodifiableListError.add();
  }

  void insertAll(int index, Iterable<E> iterable) {
    throw UnmodifiableListError.add();
  }

  void setAll(int index, Iterable<E> iterable) {
    throw UnmodifiableListError.change();
  }

  E removeAt(int index) {
    throw UnmodifiableListError.remove();
  }

  bool remove(Object element) {
    throw UnmodifiableListError.remove();
  }

  void removeWhere(bool test(E element)) {
    throw UnmodifiableListError.remove();
  }

  void retainWhere(bool test(E element)) {
    throw UnmodifiableListError.remove();
  }

  void copyFrom(List src, int srcStart, int dstStart, int count) {
    throw UnmodifiableListError.change();
  }

  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    throw UnmodifiableListError.change();
  }

  void removeRange(int start, int end) {
    throw UnmodifiableListError.remove();
  }

  void fillRange(int start, int end, [E fillValue]) {
    throw UnmodifiableListError.change();
  }

  void replaceRange(int start, int end, Iterable<E> iterable) {
    throw UnmodifiableListError.change();
  }

  List<E> sublist(int start, [int end]) {
    Lists.indicesCheck(this, start, end);
    if (end == null) end = this.length;
    int length = end - start;
    if (start == end) return [];
    List list = new List<E>();
    list.length = length;
    Lists.copy(this, start, list, 0, length);
    return list;
  }

  Iterable<E> getRange(int start, int end) {
    return IterableMixinWorkaround.getRangeList(this, start, end);
  }

  // Collection interface.

  bool contains(Object element) {
    return IterableMixinWorkaround.contains(this, element);
  }

  void forEach(f(E element)) {
    IterableMixinWorkaround.forEach(this, f);
  }

  Iterable map(f(E element)) {
    return IterableMixinWorkaround.mapList(this, f);
  }

  String join([String separator = ""]) {
    return IterableMixinWorkaround.joinList(this, separator);
  }

  E reduce(E combine(E value, E element)) {
    return IterableMixinWorkaround.reduce(this, combine);
  }

  fold(initialValue, combine(previousValue, E element)) {
    return IterableMixinWorkaround.fold(this, initialValue, combine);
  }

  Iterable<E> where(bool f(E element)) {
    return IterableMixinWorkaround.where(this, f);
  }

  Iterable expand(Iterable f(E element)) {
    return IterableMixinWorkaround.expand(this, f);
  }

  Iterable<E> take(int n) {
    return IterableMixinWorkaround.takeList(this, n);
  }

  Iterable<E> takeWhile(bool test(E value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  Iterable<E> skip(int n) {
    return IterableMixinWorkaround.skipList(this, n);
  }

  Iterable<E> skipWhile(bool test(E value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  bool every(bool f(E element)) {
    return IterableMixinWorkaround.every(this, f);
  }

  bool any(bool f(E element)) {
    return IterableMixinWorkaround.any(this, f);
  }

  E firstWhere(bool test(E value), {E orElse()}) {
    return IterableMixinWorkaround.firstWhere(this, test, orElse);
  }

  E lastWhere(bool test(E value), {E orElse()}) {
    return IterableMixinWorkaround.lastWhereList(this, test, orElse);
  }

  E singleWhere(bool test(E value)) {
    return IterableMixinWorkaround.singleWhere(this, test);
  }

  E elementAt(int index) {
    return this[index];
  }

  bool get isEmpty {
    return this.length == 0;
  }

  bool get isNotEmpty => !isEmpty;

  Iterable<E> get reversed => IterableMixinWorkaround.reversedList(this);

  void sort([int compare(E a, E b)]) {
    throw UnmodifiableListError.change();
  }

  void shuffle([Random random]) {
    throw UnmodifiableListError.change();
  }

  String toString() {
    return ListBase.listToString(this);
  }

  int indexOf(Object element, [int start = 0]) {
    return Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(Object element, [int start = null]) {
    if (start == null) start = length - 1;
    return Lists.lastIndexOf(this, element, start);
  }

  Iterator<E> get iterator {
    return new _FixedSizeArrayIterator<E>(this);
  }

  void add(E element) {
    throw UnmodifiableListError.add();
  }

  void addAll(Iterable<E> elements) {
    throw UnmodifiableListError.add();
  }

  void clear() {
    throw UnmodifiableListError.remove();
  }

  void set length(int length) {
    throw UnmodifiableListError.length();
  }

  E removeLast() {
    throw UnmodifiableListError.remove();
  }

  E get first {
    if (length > 0) return this[0];
    throw IterableElementError.noElement();
  }

  E get last {
    if (length > 0) return this[length - 1];
    throw IterableElementError.noElement();
  }

  E get single {
    if (length == 1) return this[0];
    if (length == 0) throw IterableElementError.noElement();
    throw IterableElementError.tooMany();
  }

  List<E> toList({ bool growable: true }) {
    return new List<E>.from(this, growable: growable);
  }

  Set<E> toSet() {
    return new Set<E>.from(this);
  }

  Map<int, E> asMap() {
    return IterableMixinWorkaround.asMapList(this);
  }
}


// Iterator for arrays with fixed size.
class _FixedSizeArrayIterator<E> implements Iterator<E> {
  final List<E> _array;
  final int _length;  // Cache array length for faster access.
  int _position;
  E _current;

  _FixedSizeArrayIterator(List array)
      : _array = array, _length = array.length, _position = -1 {
    assert(array is _List || array is _ImmutableList);
  }

  bool moveNext() {
    int nextPosition = _position + 1;
    if (nextPosition < _length) {
      _current = _array[nextPosition];
      _position = nextPosition;
      return true;
    }
    _position = _length;
    _current = null;
    return false;
  }

  E get current {
    return _current;
  }
}
