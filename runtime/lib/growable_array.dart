// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _GrowableList<T> extends ListBase<T> {

  void insert(int index, T element) {
    if ((index < 0) || (index > length)) {
      throw new RangeError.range(index, 0, length);
    }
    if (index == this.length) {
      add(element);
      return;
    }
    int oldLength = this.length;
    // We are modifying the length just below the is-check. Without the check
    // Array.copy could throw an exception, leaving the list in a bad state
    // (with a length that has been increased, but without a new element).
    if (index is! int) throw new ArgumentError(index);
    this.length++;
    Lists.copy(this, index, this, index + 1, oldLength - index);
    this[index] = element;
  }

  T removeAt(int index) {
    var result = this[index];
    int newLength = this.length - 1;
    Lists.copy(this, index + 1, this, index, newLength - index);
    this.length = newLength;
    return result;
  }

  bool remove(Object element) {
    for (int i = 0; i < this.length; i++) {
      if (this[i] == element) {
        removeAt(i);
        return true;
      }
    }
    return false;
  }

  void insertAll(int index, Iterable<T> iterable) {
    if (index < 0 || index > length) {
      throw new RangeError.range(index, 0, length);
    }
    // TODO(floitsch): we can probably detect more cases.
    if (iterable is! List && iterable is! Set && iterable is! SubListIterable) {
      iterable = iterable.toList();
    }
    int insertionLength = iterable.length;
    // There might be errors after the length change, in which case the list
    // will end up being modified but the operation not complete. Unless we
    // always go through a "toList" we can't really avoid that.
    this.length += insertionLength;
    setRange(index + insertionLength, this.length, this, index);
    setAll(index, iterable);
  }

  void setAll(int index, Iterable<T> iterable) {
    if (iterable is List) {
      setRange(index, index + iterable.length, iterable);
    } else {
      for (T element in iterable) {
        this[index++] = element;
      }
    }
  }

  void removeRange(int start, int end) {
    Lists.indicesCheck(this, start, end);
    Lists.copy(this, end, this, start, this.length - end);
    this.length = this.length - (end - start);
  }

  List<T> sublist(int start, [int end]) {
    Lists.indicesCheck(this, start, end);
    if (end == null) end = this.length;
    int length = end - start;
    if (length == 0) return <T>[];
    List list = new _List(length);
    for (int i = 0; i < length; i++) {
      list[i] = this[start + i];
    }
    var result = new _GrowableList<T>.withData(list);
    result._setLength(length);
    return result;
  }

  static const int _kDefaultCapacity = 2;

  factory _GrowableList(int length) {
    var data = new _List((length == 0) ? _kDefaultCapacity : length);
    var result = new _GrowableList<T>.withData(data);
    if (length > 0) {
      result._setLength(length);
    }
    return result;
  }

  factory _GrowableList.withCapacity(int capacity) {
    var data = new _List((capacity == 0)? _kDefaultCapacity : capacity);
    return new _GrowableList<T>.withData(data);
  }

  factory _GrowableList.from(Iterable<T> other) {
    List<T> result = new _GrowableList<T>();
    result.addAll(other);
    return result;
  }

  factory _GrowableList.withData(_List data)
    native "GrowableList_allocate";

  int get length native "GrowableList_getLength";

  int get _capacity native "GrowableList_getCapacity";

  void set length(int new_length) {
    if (new_length > _capacity) {
      _grow(new_length);
    } else {
      for (int i = new_length; i < length; i++) {
        this[i] = null;
      }
    }
    _setLength(new_length);
  }

  void _setLength(int new_length) native "GrowableList_setLength";

  void _setData(_List array) native "GrowableList_setData";

  T operator [](int index) native "GrowableList_getIndexed";

  void operator []=(int index, T value) native "GrowableList_setIndexed";

  // The length of this growable array. It is always less than or equal to the
  // length of the object array, which itself is always greater than 0, so that
  // grow() does not have to check for a zero length object array before
  // doubling its size.
  void add(T value) {
    var len = length;
    if (len == _capacity) {
      _grow(len * 2);
    }
    _setLength(len + 1);
    this[len] = value;
  }

  void addAll(Iterable<T> iterable) {
    var len = length;
    if (iterable is EfficientLength) {
      var cap = _capacity;
      // Pregrow if we know iterable.length.
      var iterLen = iterable.length;
      var newLen = len + iterLen;
      if (newLen > cap) {
        do {
          cap *= 2;
        } while (newLen > cap);
        _grow(cap);
      }
    }
    Iterator it = iterable.iterator;
    if (!it.moveNext()) return;
    do {
      while (len < _capacity) {
        int newLen = len + 1;
        this._setLength(newLen);
        this[len] = it.current;
        if (!it.moveNext()) return;
        if (this.length != newLen) throw new ConcurrentModificationError(this);
        len = newLen;
      }
      _grow(_capacity * 2);
    } while (true);
  }

  T removeLast() {
    var len = length - 1;
    var elem = this[len];
    this[len] = null;
    _setLength(len);
    return elem;
  }

  T get first {
    if (length > 0) return this[0];
    throw IterableElementError.noElement();
  }

  T get last {
    if (length > 0) return this[length - 1];
    throw IterableElementError.noElement();
  }

  T get single {
    if (length == 1) return this[0];
    if (length == 0) throw IterableElementError.noElement();
    throw IterableElementError.tooMany();;
  }

  void _grow(int new_length) {
    var new_data = new _List(new_length);
    for (int i = 0; i < length; i++) {
      new_data[i] = this[i];
    }
    _setData(new_data);
  }

  // Iterable interface.

  void forEach(f(T element)) {
    int initialLength = length;
    for (int i = 0; i < length; i++) {
      f(this[i]);
      if (length != initialLength) throw new ConcurrentModificationError(this);
    }
  }

  String join([String separator = ""]) {
    final int length = this.length;
    if (length == 0) return "";
    if (length == 1) return "${this[0]}";
    if (separator.isNotEmpty) return _joinWithSeparator(separator);
    var i = 0;
    var codeUnitCount = 0;
    while (i < length) {
      final element = this[i];
      final int cid = ClassID.getID(element);
      // While list contains one-byte strings.
      if (ClassID.cidOneByteString == cid) {
        codeUnitCount += element.length;
        i++;
        // Loop back while strings are one-byte strings.
        continue;
      }
      // Otherwise, never loop back to the outer loop, and
      // handle the remaining strings below.

      // Loop while elements are strings,
      final int firstNonOneByteStringLimit = i;
      var nextElement = element;
      while (nextElement is String) {
        i++;
        if (i == length) {
          return _StringBase._concatRangeNative(this, 0, length);
        }
        nextElement = this[i];
      }

      // Not all elements are strings, so allocate a new backing array.
      final list = new _List(length);
      for (int copyIndex = 0; copyIndex < i; copyIndex++) {
        list[copyIndex] = this[copyIndex];
      }
      // Is non-zero if list contains a non-onebyte string.
      var onebyteCanary = i - firstNonOneByteStringLimit;
      while (true) {
        final String elementString = "$nextElement";
        onebyteCanary |=
            (ClassID.getID(elementString) ^ ClassID.cidOneByteString);
        list[i] = elementString;
        codeUnitCount += elementString.length;
        i++;
        if (i == length) break;
        nextElement = this[i];
      }
      if (onebyteCanary == 0) {
        // All elements returned a one-byte string from toString.
        return _OneByteString._concatAll(list, codeUnitCount);
      }
      return _StringBase._concatRangeNative(list, 0, length);
    }
    // All elements were one-byte strings.
    return _OneByteString._concatAll(this, codeUnitCount);
  }

  String _joinWithSeparator(String separator) {
    StringBuffer buffer = new StringBuffer();
    buffer.write(this[0]);
    for (int i = 1; i < this.length; i++) {
      buffer.write(separator);
      buffer.write(this[i]);
    }
    return buffer.toString();
  }

  T elementAt(int index) {
    return this[index];
  }

  bool get isEmpty {
    return this.length == 0;
  }

  bool get isNotEmpty => !isEmpty;

  void clear() {
    this.length = 0;
  }

  String toString() => ListBase.listToString(this);

  Iterator<T> get iterator {
    return new ListIterator<T>(this);
  }

  List<T> toList({ bool growable: true }) {
    var length = this.length;
    if (length > 0) {
      List list = growable ? new _List(length) : new _List<T>(length);
      for (int i = 0; i < length; i++) {
        list[i] = this[i];
      }
      if (!growable) return list;
      var result = new _GrowableList<T>.withData(list);
      result._setLength(length);
      return result;
    }
    return growable ? <T>[] : new List<T>(0);
  }

  Set<T> toSet() {
    return new Set<T>.from(this);
  }
}
