// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

class _List<E> extends FixedLengthListBase<E> {
  factory _List(length) native "List_allocate";

  E operator [](int index) native "List_getIndexed";

  void operator []=(int index, E value) native "List_setIndexed";

  int get length native "List_getLength";

  List _slice(int start, int count, bool needsTypeArgument) {
    if (count <= 64) {
      final result = needsTypeArgument ? new _List<E>(count) : new _List(count);
      for (int i = 0; i < result.length; i++) {
        result[i] = this[start + i];
      }
      return result;
    } else {
      return _sliceInternal(start, count, needsTypeArgument);
    }
  }

  List _sliceInternal(int start, int count, bool needsTypeArgument)
      native "List_slice";

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
    if (identical(this, iterable)) {
      Lists.copy(this, skipCount, this, start, length);
    } else if (ClassID.getID(iterable) == ClassID.cidArray) {
      final _List<E> iterableAsList = iterable;
      Lists.copy(iterableAsList, skipCount, this, start, length);
    } else if (iterable is List<E>) {
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

  List<E> sublist(int start, [int end]) {
    end = RangeError.checkValidRange(start, end, this.length);
    int length = end - start;
    if (length == 0) return <E>[];
    var result = new _GrowableList<E>.withData(_slice(start, length, false));
    result._setLength(length);
    return result;
  }

  // Iterable interface.

  void forEach(f(E element)) {
    final length = this.length;
    for (int i = 0; i < length; i++) {
      f(this[i]);
    }
  }

  Iterator<E> get iterator {
    return new _FixedSizeArrayIterator<E>(this);
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

  List<E> toList({bool growable: true}) {
    var length = this.length;
    if (length > 0) {
      var result = _slice(0, length, !growable);
      if (growable) {
        result = new _GrowableList<E>.withData(result).._setLength(length);
      }
      return result;
    }
    // _GrowableList.withData must not be called with empty list.
    return growable ? <E>[] : new List<E>(0);
  }
}

// This is essentially the same class as _List, but it does not
// permit any modification of array elements from Dart code. We use
// this class for arrays constructed from Dart array literals.
// TODO(hausner): We should consider the trade-offs between two
// classes (and inline cache misses) versus a field in the native
// implementation (checks when modifying). We should keep watching
// the inline cache misses.
class _ImmutableList<E> extends UnmodifiableListBase<E> {
  factory _ImmutableList._uninstantiable() {
    throw new UnsupportedError(
        "ImmutableArray can only be allocated by the VM");
  }

  factory _ImmutableList._from(List from, int offset, int length)
      native "ImmutableList_from";

  E operator [](int index) native "List_getIndexed";

  int get length native "List_getLength";

  List<E> sublist(int start, [int end]) {
    end = RangeError.checkValidRange(start, end, this.length);
    int length = end - start;
    if (length == 0) return <E>[];
    List list = new _List(length);
    for (int i = 0; i < length; i++) {
      list[i] = this[start + i];
    }
    var result = new _GrowableList<E>.withData(list);
    result._setLength(length);
    return result;
  }

  // Collection interface.

  void forEach(f(E element)) {
    final length = this.length;
    for (int i = 0; i < length; i++) {
      f(this[i]);
    }
  }

  Iterator<E> get iterator {
    return new _FixedSizeArrayIterator<E>(this);
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

  List<E> toList({bool growable: true}) {
    var length = this.length;
    if (length > 0) {
      List list = growable ? new _List(length) : new _List<E>(length);
      for (int i = 0; i < length; i++) {
        list[i] = this[i];
      }
      if (!growable) return list;
      var result = new _GrowableList<E>.withData(list);
      result._setLength(length);
      return result;
    }
    return growable ? <E>[] : new _List<E>(0);
  }
}

// Iterator for arrays with fixed size.
class _FixedSizeArrayIterator<E> implements Iterator<E> {
  final List<E> _array;
  final int _length; // Cache array length for faster access.
  int _index;
  E _current;

  _FixedSizeArrayIterator(List array)
      : _array = array,
        _length = array.length,
        _index = 0 {
    assert(array is _List || array is _ImmutableList);
  }

  E get current => _current;

  bool moveNext() {
    if (_index >= _length) {
      _current = null;
      return false;
    }
    _current = _array[_index];
    _index++;
    return true;
  }
}
