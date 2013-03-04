// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(asiva): Remove this import of dart:scalarlist when we are ready to
// drop scalarlist and move this implementation as the default.
import "dart:scalarlist" as sl;

// patch classes for Int8List ..... Float64List and ByteData implementations.

patch class Int8List {
  /* patch */ factory Int8List(int length) {
    return new _Int8Array(length);
  }

  /* patch */ factory Int8List.transferable(int length) {
    return _newTransferable(length);
  }

  /* patch */ factory Int8List.view(ByteBuffer buffer,
                                    [int offsetInBytes = 0, int length]) {
    return new _Int8ArrayView(buffer, offsetInBytes, length);
  }

  static _ExternalInt8Array _newTransferable(int length) {
    return new _ExternalInt8Array(length);
  }
}


patch class Uint8List {
  /* patch */ factory Uint8List(int length) {
    return new _Uint8Array(length);
  }

  /* patch */ factory Uint8List.transferable(int length) {
    return _newTransferable(length);
  }

  /* patch */ factory Uint8List.view(ByteBuffer buffer,
                                     [int offsetInBytes = 0, int length]) {
    return new _Uint8ArrayView(buffer, offsetInBytes, length);
  }

  static _ExternalUint8Array _newTransferable(int length) {
    return new _ExternalUint8Array(length);
  }
}


patch class Uint8ClampedList {
  /* patch */ factory Uint8ClampedList(int length) {
    return new _Uint8ClampedArray(length);
  }

  /* patch */ factory Uint8ClampedList.transferable(int length) {
    return _newTransferable(length);
  }

  /* patch */ factory Uint8ClampedList.view(ByteBuffer buffer,
                                            [int offsetInBytes = 0,
                                             int length]) {
    return new _Uint8ClampedArrayView(buffer, offsetInBytes, length);
  }

  static _ExternalUint8ClampedArray _newTransferable(int length) {
    return new _ExternalUint8ClampedArray(length);
  }
}


patch class Int16List {
  /* patch */ factory Int16List(int length) {
    return new _Int16Array(length);
  }

  /* patch */ factory Int16List.transferable(int length) {
    return _newTransferable(length);
  }

  /* patch */ factory Int16List.view(ByteBuffer buffer,
                                     [int offsetInBytes = 0, int length]) {
    return new _Int16ArrayView(buffer, offsetInBytes, length);
  }

  static _ExternalInt16Array _newTransferable(int length) {
    return new _ExternalInt16Array(length);
  }
}


patch class Uint16List {
  /* patch */ factory Uint16List(int length) {
    return new _Uint16Array(length);
  }

  /* patch */ factory Uint16List.transferable(int length) {
    return _newTransferable(length);
  }

  /* patch */ factory Uint16List.view(ByteBuffer buffer,
                                      [int offsetInBytes = 0, int length]) {
    return new _Uint16ArrayView(buffer, offsetInBytes, length);
  }

  static _ExternalUint16Array _newTransferable(int length) {
    return new _ExternalUint16Array(length);
  }
}


patch class Int32List {
  /* patch */ factory Int32List(int length) {
    return new _Int32Array(length);
  }

  /* patch */ factory Int32List.transferable(int length) {
    return _newTransferable(length);
  }

  /* patch */ factory Int32List.view(ByteBuffer buffer,
                                     [int offsetInBytes = 0, int length]) {
    return new _Int32ArrayView(buffer, offsetInBytes, length);
  }

  static _ExternalInt32Array _newTransferable(int length) {
    return new _ExternalInt32Array(length);
  }
}


patch class Uint32List {
  /* patch */ factory Uint32List(int length) {
    return new _Uint32Array(length);
  }

  /* patch */ factory Uint32List.transferable(int length) {
    return _newTransferable(length);
  }

  /* patch */ factory Uint32List.view(ByteBuffer buffer,
                                      [int offsetInBytes = 0, int length]) {
    return new _Uint32ArrayView(buffer, offsetInBytes, length);
  }

  static _ExternalUint32Array _newTransferable(int length) {
    return new _ExternalUint32Array(length);
  }
}


patch class Int64List {
  /* patch */ factory Int64List(int length) {
    return new _Int64Array(length);
  }

  /* patch */ factory Int64List.transferable(int length) {
    return _newTransferable(length);
  }

  /* patch */ factory Int64List.view(ByteBuffer buffer,
                                     [int offsetInBytes = 0, int length]) {
    return new _Int64ArrayView(buffer, offsetInBytes, length);
  }

  static _ExternalInt64Array _newTransferable(int length) {
    return new _ExternalInt64Array(length);
  }
}


patch class Uint64List {
  /* patch */ factory Uint64List(int length) {
    return new _Uint64Array(length);
  }

  /* patch */ factory Uint64List.transferable(int length) {
    return _newTransferable(length);
  }

  /* patch */ factory Uint64List.view(ByteBuffer buffer,
                                      [int offsetInBytes = 0, int length]) {
    return new _Uint64ArrayView(buffer, offsetInBytes, length);
  }

  static _ExternalUint64Array _newTransferable(int length) {
    return new _ExternalUint64Array(length);
  }
}


patch class Float32List {
  /* patch */ factory Float32List(int length) {
    return new _Float32Array(length);
  }

  /* patch */ factory Float32List.transferable(int length) {
    return _newTransferable(length);
  }

  /* patch */ factory Float32List.view(ByteBuffer buffer,
                                       [int offsetInBytes = 0, int length]) {
    return new _Float32ArrayView(buffer, offsetInBytes, length);
  }

  static _ExternalFloat32Array _newTransferable(int length) {
    return new _ExternalFloat32Array(length);
  }
}


patch class Float64List {
  /* patch */ factory Float64List(int length) {
    return new _Float64Array(length);
  }

  /* patch */ factory Float64List.transferable(int length) {
    return _newTransferable(length);
  }

  /* patch */ factory Float64List.view(ByteBuffer buffer,
                                       [int offsetInBytes = 0, int length]) {
    return new _Float64ArrayView(buffer, offsetInBytes, length);
  }

  static _ExternalFloat64Array _newTransferable(int length) {
    return new _ExternalFloat64Array(length);
  }
}


patch class ByteData {
  /* patch */ factory ByteData(int length) {
    var list = new _Uint8Array(length);
    return new _ByteDataView(list.buffer);
  }

  /* patch */ factory ByteData.transferable(int length) {
    var list = new _Uint8Array.transferable(length);
    return new _ByteDataView(list.buffer);
  }

  /* patch */ factory ByteData.view(ByteBuffer buffer,
                                    [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = buffer.lengthInBytes;
    }
    return new _ByteDataView(buffer, offsetInBytes, length);
  }
}


// Based class for _TypedList that provides common methods for implementing
// the collection and list interfaces.

abstract class _TypedListBase {
  // Method(s) implementing the Collection interface.
  bool contains(element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(element)) {
    var len = this.length;
    for (var i = 0; i < len; i++) {
      f(this[i]);
    }
  }

  Iterable map(f(int element)) {
    return IterableMixinWorkaround.mapList(this, f);
  }

  String join([String separator]) {
    return IterableMixinWorkaround.join(this, separator);
  }

  dynamic reduce(dynamic initialValue,
                 dynamic combine(dynamic initialValue, element)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  Collection where(bool f(int element)) {
    return IterableMixinWorkaround.where(this, f);
  }

  Iterable expand(Iterable f(int element)) {
    return IterableMixinWorkaround.expand(this, f);
  }

  Iterable<int> take(int n) {
    return IterableMixinWorkaround.takeList(this, n);
  }

  Iterable<int> takeWhile(bool test(int value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  Iterable<int> skip(int n) {
    return IterableMixinWorkaround.skipList(this, n);
  }

  Iterable<int> skipWhile(bool test(int value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  bool every(bool f(element)) {
    return IterableMixinWorkaround.every(this, f);
  }

  bool any(bool f(element)) {
    return IterableMixinWorkaround.any(this, f);
  }

  int firstMatching(bool test(int value), {int orElse()}) {
    return IterableMixinWorkaround.firstMatching(this, test, orElse);
  }

  int lastMatching(bool test(int value), {int orElse()}) {
    return IterableMixinWorkaround.lastMatchingInList(this, test, orElse);
  }

  int singleMatching(bool test(int value)) {
    return IterableMixinWorkaround.singleMatching(this, test);
  }

  int elementAt(int index) {
    return this[index];
  }

  bool get isEmpty {
    return this.length == 0;
  }

  // Method(s) implementing the List interface.

  set length(newLength) {
    throw new UnsupportedError(
        "Cannot resize a non-extendable array");
  }

  void add(value) {
    throw new UnsupportedError(
        "Cannot add to a non-extendable array");
  }

  void addLast(value) {
    throw new UnsupportedError(
        "Cannot add to a non-extendable array");
  }

  void addAll(Iterable value) {
    throw new UnsupportedError(
        "Cannot add to a non-extendable array");
  }

  void sort([int compare(var a, var b)]) {
    return IterableMixinWorkaround.sortList(this, compare);
  }

  int indexOf(element, [int start = 0]) {
    return Arrays.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(element, [int start = null]) {
    if (start == null) start = length - 1;
    return Arrays.lastIndexOf(this, element, start);
  }

  void clear() {
    throw new UnsupportedError(
        "Cannot remove from a non-extendable array");
  }

  int removeLast() {
    throw new UnsupportedError(
        "Cannot remove from a non-extendable array");
  }

  void remove(Object element) {
    throw new UnsupportedError(
        "Cannot remove from a non-extendable array");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError(
        "Cannot remove from a non-extendable array");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError(
        "Cannot remove from a non-extendable array");
  }

  void removeMatching(bool test(int element)) {
    throw new UnsupportedError(
        "Cannot remove from a non-extendable array");
  }

  void retainMatching(bool test(int element)) {
    throw new UnsupportedError(
        "Cannot remove from a non-extendable array");
  }

  int get first {
    if (length > 0) return this[0];
    throw new StateError("No elements");
  }

  int get last {
    if (length > 0) return this[length - 1];
    throw new StateError("No elements");
  }

  int get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  int min([int compare(int a, int b)]) =>
    IterableMixinWorkaround.min(this, compare);

  int max([int compare(int a, int b)]) =>
    IterableMixinWorkaround.max(this, compare);

  void removeRange(int start, int length) {
    throw new UnsupportedError(
        "Cannot remove from a non-extendable array");
  }

  void insertRange(int start, int length, [initialValue]) {
    throw new UnsupportedError(
        "Cannot add to a non-extendable array");
  }

  List<int> toList() {
    return new List<int>.from(this);
  }

  Set<int> toSet() {
    return new Set<int>.from(this);
  }
}


abstract class _TypedList extends _TypedListBase implements ByteBuffer {
  // Default method implementing parts of the TypedData interface.
  int get offsetInBytes {
    return 0;
  }

  int get lengthInBytes {
    return _length() * elementSizeInBytes;
  }

  ByteBuffer get buffer {
    return this;
  }


  // Methods implementing the collection interface.

  int get length {
    return _length();
  }


  // Internal utility methods.

  int _length() {
    return _array.length;
  }

  sl.ByteArrayViewable _array;
}


class _Int8Array extends _TypedList implements Int8List {
  // Factory constructors.

  _Int8Array(int length) {
    _array = new sl.Int8List(length);
  }

  factory _Int8Array.view(ByteBuffer buffer,
                          [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = buffer.lengthInBytes;
    }
    return new _Int8ArrayView(buffer, offsetInBytes, length);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toInt8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    /**
    if (from is _Int8Array) {
      _setRange(start * Int8List.BYTES_PER_ELEMENT,
                length * Int8List.BYTES_PER_ELEMENT,
                from,
                startFrom * Int8List.BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
    */
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Int8List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  int _getIndexed(int index) {
    return _array[index];
  }
  void _setIndexed(int index, int value) {
    _array[index] = value;
  }
}


class _Uint8Array extends _TypedList implements Uint8List {
  // Factory constructors.

  _Uint8Array(int length) {
    _array = new sl.Uint8List(length);
  }

  factory _Uint8Array.view(ByteBuffer buffer,
                           [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = buffer.lengthInBytes;
    }
    return new _Uint8ArrayView(buffer, offsetInBytes, length);
  }

  // Methods implementing List interface.
  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toUint8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    /**
    if (from is _Uint8Array || from is _ExternalUint8Array ||
        from is _Uint8ClampedArray || from is _ExternalUint8ClampedArray) {
      _setRange(start * Uint8List.BYTES_PER_ELEMENT,
                length * Uint8List.BYTES_PER_ELEMENT,
                from,
                startFrom * Uint8List.BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
    */
    Arrays.copy(from, startFrom, this, start, length);
  }

  // Methods implementing Object interface.
  String toString() {
    return Collections.collectionToString(this);
  }

  // Methods implementing TypedData interface.
  int get elementSizeInBytes {
    return Uint8List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.

  int _getIndexed(int index) {
    return _array[index];
  }
  void _setIndexed(int index, int value) {
    _array[index] = value;
  }
}


class _Uint8ClampedArray extends _TypedList implements Uint8ClampedList {
  // Factory constructors.

  _Uint8ClampedArray(int length) {
    _array = new sl.Uint8ClampedList(length);
  }

  factory _Uint8ClampedArray.view(ByteBuffer buffer,
                                  [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = buffer.lengthInBytes;
    }
    return new _Uint8ClampedArrayView(buffer, offsetInBytes, length);
  }

  // Methods implementing List interface.
  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toClampedUint8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    /**
    if (from is _Uint8Array || from is _ExternalUint8Array ||
        from is _Uint8ClampedArray || from is _ExternalUint8ClampedArray) {
      _setRange(start * Uint8List.BYTES_PER_ELEMENT,
                length * Uint8List.BYTES_PER_ELEMENT,
                from,
                startFrom * Uint8List.BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
    */
    Arrays.copy(from, startFrom, this, start, length);
  }

  // Methods implementing Object interface.
  String toString() {
    return Collections.collectionToString(this);
  }

  // Methods implementing TypedData interface.
  int get elementSizeInBytes {
    return Uint8List.BYTES_PER_ELEMENT;
  }

  // Internal utility methods.

  int _getIndexed(int index) {
    return _array[index];
  }
  void _setIndexed(int index, int value) {
    _array[index] = value;
  }
}


class _Int16Array extends _TypedList implements Int16List {
  // Factory constructors.

  _Int16Array(int length) {
    _array = new sl.Int16List(length);
  }

  factory _Int16Array.view(ByteBuffer buffer,
                           [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (buffer.lengthInBytes - offsetInBytes) ~/
               Int16List.BYTES_PER_ELEMENT;
    }
    return new _Int16ArrayView(buffer, offsetInBytes, length);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toInt16(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    /**
    if (from is _Int16Array) {
      _setRange(start * Int16List.BYTES_PER_ELEMENT,
                length * Int16List.BYTES_PER_ELEMENT,
                from,
                startFrom * Int16List.BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
    */
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Int16List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  int _getIndexed(int index) {
    return _array[index];
  }
  void _setIndexed(int index, int value) {
    _array[index] = value;
  }
}


class _Uint16Array extends _TypedList implements Uint16List {
  // Factory constructors.

  _Uint16Array(int length) {
    _array = new sl.Uint16List(length);
  }

  factory _Uint16Array.view(ByteBuffer buffer,
                            [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (buffer.lengthInBytes - offsetInBytes) ~/
                Uint16List.BYTES_PER_ELEMENT;
    }
    return new _Uint16ArrayView(buffer, offsetInBytes, length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toUint16(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    /**
    if (from is _Uint16Array) {
      _setRange(start * Uint16List.BYTES_PER_ELEMENT,
                length * Uint16List.BYTES_PER_ELEMENT,
                from,
                startFrom * Uint16List.BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
    */
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing the Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Uint16List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  int _getIndexed(int index) {
    return _array[index];
  }
  void _setIndexed(int index, int value) {
    _array[index] = value;
  }
}


class _Int32Array extends _TypedList implements Int32List {
  // Factory constructors.

  _Int32Array(int length) {
    _array = new sl.Int32List(length);
  }

  factory _Int32Array.view(ByteBuffer buffer,
                           [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (buffer.lengthInBytes - offsetInBytes) ~/
                Int32List.BYTES_PER_ELEMENT;
    }
    return new _Int32ArrayView(buffer, offsetInBytes, length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toInt32(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    /**
    if (from is _Int32Array) {
      _setRange(start * Int32List.BYTES_PER_ELEMENT,
                length * Int32List.BYTES_PER_ELEMENT,
                from,
                startFrom * Int32List.BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
    */
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Int32List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  int _getIndexed(int index) {
    return _array[index];
  }
  void _setIndexed(int index, int value) {
    _array[index] = value;
  }
}


class _Uint32Array extends _TypedList implements Uint32List {
  // Factory constructors.

  _Uint32Array(int length) {
    _array = new sl.Uint32List(length);
  }

  factory _Uint32Array.view(ByteBuffer buffer,
                            [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (buffer.lengthInBytes - offsetInBytes) ~/
                Uint32List.BYTES_PER_ELEMENT;
    }
    return new _Uint32ArrayView(buffer, offsetInBytes, length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toUint32(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    /**
    if (from is _Uint32Array) {
      _setRange(start * Uint32List.BYTES_PER_ELEMENT,
                length * Uint32List.BYTES_PER_ELEMENT,
                from,
                startFrom * Uint32List.BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
    */
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing the Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Uint32List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  int _getIndexed(int index) {
    return _array[index];
  }
  void _setIndexed(int index, int value) {
    _array[index] = value;
  }
}


class _Int64Array extends _TypedList implements Int64List {
  // Factory constructors.

  _Int64Array(int length) {
    _array = new sl.Int64List(length);
  }

  factory _Int64Array.view(ByteBuffer buffer,
                           [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (buffer.lengthInBytes - offsetInBytes) ~/
                Int32List.BYTES_PER_ELEMENT;
    }
    return new _Int64ArrayView(buffer, offsetInBytes, length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toInt64(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    /**
    if (from is _Int64Array) {
      _setRange(start * Int64List.BYTES_PER_ELEMENT,
                length * Int64List.BYTES_PER_ELEMENT,
                from,
                startFrom * Int64List.BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
    */
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing the Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Int64List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  int _getIndexed(int index) {
    return _array[index];
  }
  void _setIndexed(int index, int value) {
    _array[index] = value;
  }
}


class _Uint64Array extends _TypedList implements Uint64List {
  // Factory constructors.

  _Uint64Array(int length) {
    _array = new sl.Uint64List(length);
  }

  factory _Uint64Array.view(ByteBuffer buffer,
                            [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (buffer.lengthInBytes - offsetInBytes) ~/
               Uint64List.BYTES_PER_ELEMENT;
    }
    return new _Uint64ArrayView(buffer, offsetInBytes, length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toUint64(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    /**
    if (from is _Uint64Array) {
      _setRange(start * Uint64List.BYTES_PER_ELEMENT,
                length * Uint64List.BYTES_PER_ELEMENT,
                from,
                startFrom * Uint64List.BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
    */
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing the Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Uint64List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  int _getIndexed(int index) {
    return _array[index];
  }
  void _setIndexed(int index, int value) {
    _array[index] = value;
  }
}


class _Float32Array extends _TypedList implements Float32List {
  // Factory constructors.

  _Float32Array(int length) {
    _array = new sl.Float32List(length);
  }

  factory _Float32Array.view(ByteBuffer buffer,
                             [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (buffer.lengthInBytes - offsetInBytes) ~/
               Float32List.BYTES_PER_ELEMENT;
    }
    return new _Float32ArrayView(buffer, offsetInBytes, length);
  }


  // Method(s) implementing the List interface.

  double operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, double value) {
    _setIndexed(index, value);
  }

  Iterator<double> get iterator {
    return new _TypedListIterator<double>(this);
  }

  List<double> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<double> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<double> from, [int startFrom = 0]) {
    /**
    if (from is _Float32Array) {
      _setRange(start * Float32List.BYTES_PER_ELEMENT,
                length * Float32List.BYTES_PER_ELEMENT,
                from,
                startFrom * Float32List.BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
    */
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing the Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Float32List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  double _getIndexed(int index) {
    return _array[index];
  }
  void _setIndexed(int index, double value) {
    _array[index] = value;
  }
}


class _Float64Array extends _TypedList implements Float64List {
  // Factory constructors.

  _Float64Array(int length) {
    _array = new sl.Float64List(length);
  }

  factory _Float64Array.view(ByteBuffer buffer,
                             [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (buffer.lengthInBytes - offsetInBytes) ~/
               Float64List.BYTES_PER_ELEMENT;
    }
    return new _Float64ArrayView(buffer, offsetInBytes, length);
  }


  // Method(s) implementing the List interface.

  double operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, double value) {
    _setIndexed(index, value);
  }

  Iterator<double> get iterator {
    return new _TypedListIterator<double>(this);
  }

  List<double> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<double> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<double> from, [int startFrom = 0]) {
    /**
    if (from is _Float64Array) {
      _setRange(start * Float64List.BYTES_PER_ELEMENT,
                length * Float64List.BYTES_PER_ELEMENT,
                from,
                startFrom * Float64List.BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
    */
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing the Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Float64List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  double _getIndexed(int index) {
    return _array[index];
  }
  void _setIndexed(int index, double value) {
    _array[index] = value;
  }
}


class _ExternalInt8Array extends _TypedList implements Int8List {
  // Factory constructors.

  _ExternalInt8Array(int length) {
    _array = new sl.Int8List.transferable(length);
  }


  // Method(s) implementing the List interface.
  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toInt8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Int8List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    /**
    if (from is _ExternalInt8Array) {
      _setRange(start * Int8List.BYTES_PER_ELEMENT,
                length * Int8List.BYTES_PER_ELEMENT,
                from,
                startFrom * Int8List.BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
    */
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing the Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Int8List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  int _getIndexed(int index) {
    return _array[index];
  }
  void _setIndexed(int index, int value) {
    _array[index] = value;
  }
}


class _ExternalUint8Array extends _TypedList implements Uint8List {
  // Factory constructors.

  _ExternalUint8Array(int length) {
    _array = new sl.Uint8List.transferable(length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toUint8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Uint8List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    /**
    if (from is _ExternalUint8Array || from is _Uint8Array) {
      _setRange(start * Uint8List.BYTES_PER_ELEMENT,
                length * Uint8List.BYTES_PER_ELEMENT,
                from,
                startFrom * Uint8List.BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
    */
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing the Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Uint8List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  int _getIndexed(int index) {
    return _array[index];
  }
  void _setIndexed(int index, int value) {
    _array[index] = value;
  }
}


class _ExternalUint8ClampedArray extends _TypedList implements Uint8ClampedList {
  // Factory constructors.

  _ExternalUint8ClampedArray(int length) {
    _array = new sl.Uint8ClampedList.transferable(length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toClampedUint8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Uint8ClampedList(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    /**
    if (from is _ExternalUint8ClampedArray || from is _Uint8ClampedArray) {
      _setRange(start * Uint8List.BYTES_PER_ELEMENT,
                length * Uint8List.BYTES_PER_ELEMENT,
                from,
                startFrom * Uint8List.BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
    */
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing the Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Uint8List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  int _getIndexed(int index) {
    return _array[index];
  }
  void _setIndexed(int index, int value) {
    _array[index] = value;
  }
}


class _ExternalInt16Array extends _TypedList implements Int16List {
  // Factory constructors.

  _ExternalInt16Array(int length) {
    _array = new sl.Int16List.transferable(length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toInt16(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Int16List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    /**
    if (from is _ExternalInt16Array) {
      _setRange(start * Int16List.BYTES_PER_ELEMENT,
                length * Int16List.BYTES_PER_ELEMENT,
                from,
                startFrom * Int16List.BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
    */
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing the Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Int16List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  int _getIndexed(int index) {
    return _array[index];
  }
  void _setIndexed(int index, int value) {
    _array[index] = value;
  }
}


class _ExternalUint16Array extends _TypedList implements Uint16List {
  // Factory constructors.

  _ExternalUint16Array(int length) {
    _array = new sl.Uint16List.transferable(length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toUint16(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Uint16List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    /**
    if (from is _ExternalUint16Array) {
      _setRange(start * Uint16List.BYTES_PER_ELEMENT,
                length * Uint16List.BYTES_PER_ELEMENT,
                from,
                startFrom * Uint16List.BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
    */
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing the Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Uint16List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  int _getIndexed(int index) {
    return _array[index];
  }
  void _setIndexed(int index, int value) {
    _array[index] = value;
  }
}


class _ExternalInt32Array extends _TypedList implements Int32List {
  // Factory constructors.
  
  _ExternalInt32Array(int length) {
    _array = new sl.Int32List.transferable(length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toInt32(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Int32List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    /**
    if (from is _ExternalInt32Array) {
      _setRange(start * Int32List.BYTES_PER_ELEMENT,
                length * Int32List.BYTES_PER_ELEMENT,
                from,
                startFrom * Int32List.BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
    */
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing the Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Int32List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  int _getIndexed(int index) {
    return _array[index];
  }
  void _setIndexed(int index, int value) {
    _array[index] = value;
  }
}


class _ExternalUint32Array extends _TypedList implements Uint32List {
  // Factory constructors.

  _ExternalUint32Array(int length) {
    _array = new sl.Uint32List.transferable(length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toUint32(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Uint32List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    /**
    if (from is _ExternalUint32Array) {
      _setRange(start * Uint32List.BYTES_PER_ELEMENT,
                length * Uint32List.BYTES_PER_ELEMENT,
                from,
                startFrom * Uint32List.BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
    */
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing the Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Uint32List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  int _getIndexed(int index) {
    return _array[index];
  }
  void _setIndexed(int index, int value) {
    _array[index] = value;
  }
}


class _ExternalInt64Array extends _TypedList implements Int64List {
  // Factory constructors.

  _ExternalInt64Array(int length) {
    _array = new sl.Int64List.transferable(length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toInt64(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Int64List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    /**
    if (from is _ExternalInt64Array) {
      _setRange(start * Int64List.BYTES_PER_ELEMENT,
                length * Int64List.BYTES_PER_ELEMENT,
                from,
                startFrom * Int64List.BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
    */
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing the Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Int64List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  int _getIndexed(int index) {
    return _array[index];
  }
  void _setIndexed(int index, int value) {
    _array[index] = value;
  }
}


class _ExternalUint64Array extends _TypedList implements Uint64List {
  // Factory constructors.

  _ExternalUint64Array(int length) {
    _array = new sl.Uint64List.transferable(length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, int value) {
    _setIndexed(index, _toUint64(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Uint64List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    /**
    if (from is _ExternalUint64Array) {
      _setRange(start * Uint64List.BYTES_PER_ELEMENT,
                length * Uint64List.BYTES_PER_ELEMENT,
                from,
                startFrom * Uint64List.BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
    */
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing the Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Uint64List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  int _getIndexed(int index) {
    return _array[index];
  }
  void _setIndexed(int index, int value) {
    _array[index] = value;
  }
}


class _ExternalFloat32Array extends _TypedList implements Float32List {
  // Factory constructors.

  _ExternalFloat32Array(int length) {
    _array = new sl.Float32List.transferable(length);
  }


  // Method(s) implementing the List interface.

  double operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, double value) {
    _setIndexed(index, value);
  }

  Iterator<double> get iterator {
    return new _TypedListIterator<double>(this);
  }

  List<double> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<double> result = new Float32List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<double> from, [int startFrom = 0]) {
    /**
    if (from is _ExternalFloat32Array) {
      _setRange(start * Float32List.BYTES_PER_ELEMENT,
                length * Float32List.BYTES_PER_ELEMENT,
                from,
                startFrom * Float32List.BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
    */
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing the Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Float32List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  double _getIndexed(int index) {
    return _array[index];
  }
  void _setIndexed(int index, double value) {
    _array[index] = value;
  }
}


class _ExternalFloat64Array extends _TypedList implements Float64List {
  // Factory constructors.

  _ExternalFloat64Array(int length) {
    _array = new sl.Float64List.transferable(length);
  }


  // Method(s) implementing the List interface.

  double operator[](int index) {
    return _getIndexed(index);
  }

  void operator[]=(int index, double value) {
    _setIndexed(index, value);
  }

  Iterator<double> get iterator {
    return new _TypedListIterator<double>(this);
  }

  List<double> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<double> result = new Float64List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<double> from, [int startFrom = 0]) {
    /**
    if (from is _ExternalFloat64Array) {
      _setRange(start * Float64List.BYTES_PER_ELEMENT,
                length * Float64List.BYTES_PER_ELEMENT,
                from,
                startFrom * Float64List.BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
    */
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing the Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Float64List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  double _getIndexed(int index) {
    return _array[index];
  }
  void _setIndexed(int index, double value) {
    _array[index] = value;
  }
}


class _TypedListIterator<E> implements Iterator<E> {
  final List<E> _array;
  final int _length;
  int _position;
  E _current;

  _TypedListIterator(List array)
      : _array = array, _length = array.length, _position = -1 {
    assert(array is _TypedList || array is _TypedListView);
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

  E get current => _current;
}


class _TypedListView extends _TypedListBase implements TypedData {
  _TypedListView(ByteBuffer _buffer, int _offset, int _length)
    : _typeddata = _buffer,  // This assignment is type safe.
      offsetInBytes = _offset,
      length = _length {
  }


  // Method(s) implementing the TypedData interface.

  int get lengthInBytes {
    return length * elementSizeInBytes;
  }

  ByteBuffer get buffer {
    return _typeddata.buffer;
  }

  final TypedData _typeddata;
  final int offsetInBytes;
  final int length;
}


class _Int8ArrayView extends _TypedListView implements Int8List {
  // Constructor.
  _Int8ArrayView(ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Int8List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                offsetInBytes,
                length * Int8List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    return _typeddata.getInt8(offsetInBytes +
                              (index * Int8List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    _typeddata.setInt8(offsetInBytes + (index * Int8List.BYTES_PER_ELEMENT),
                       _toInt8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Int8List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Int8List.BYTES_PER_ELEMENT;
  }
}


class _Uint8ArrayView extends _TypedListView implements Uint8List {
  // Constructor.
  _Uint8ArrayView(ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Uint8List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                offsetInBytes,
                length * Uint8List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    return _typeddata.getUint8(offsetInBytes +
                               (index * Uint8List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    _typeddata.setUint8(offsetInBytes + (index * Uint8List.BYTES_PER_ELEMENT),
                        _toUint8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Uint8List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Uint8List.BYTES_PER_ELEMENT;
  }
}


class _Uint8ClampedArrayView extends _TypedListView implements Uint8List {
  // Constructor.
  _Uint8ClampedArrayView(ByteBuffer buffer,
                         [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Uint8List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                offsetInBytes,
                length * Uint8List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    return _typeddata.getUint8(offsetInBytes +
                               (index * Uint8List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    _typeddata.setUint8(offsetInBytes + (index * Uint8List.BYTES_PER_ELEMENT),
                        _toClampedUint8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Uint8List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Uint8List.BYTES_PER_ELEMENT;
  }
}


class _Int16ArrayView extends _TypedListView implements Int16List {
  // Constructor.
  _Int16ArrayView(ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Int16List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                offsetInBytes,
                length * Int16List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    return _typeddata.getInt16(offsetInBytes +
                               (index * Int16List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    _typeddata.setInt16(offsetInBytes + (index * Int16List.BYTES_PER_ELEMENT),
                        _toInt16(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Int16List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Int16List.BYTES_PER_ELEMENT;
  }
}


class _Uint16ArrayView extends _TypedListView implements Uint16List {
  // Constructor.
  _Uint16ArrayView(ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Uint16List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                offsetInBytes,
                length * Uint16List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    return _typeddata.getUint16(offsetInBytes +
                                (index * Uint16List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    _typeddata.setUint16(offsetInBytes + (index * Uint16List.BYTES_PER_ELEMENT),
                         _toUint16(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Uint16List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Uint16List.BYTES_PER_ELEMENT;
  }
}


class _Int32ArrayView extends _TypedListView implements Int32List {
  // Constructor.
  _Int32ArrayView(ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Int32List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                offsetInBytes,
                length * Int32List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    return _typeddata.getInt32(offsetInBytes +
                               (index * Int32List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    _typeddata.setInt32(offsetInBytes + (index * Int32List.BYTES_PER_ELEMENT),
                        _toInt32(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Int32List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Int32List.BYTES_PER_ELEMENT;
  }
}


class _Uint32ArrayView extends _TypedListView implements Uint32List {
  // Constructor.
  _Uint32ArrayView(ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Uint32List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                offsetInBytes,
                length * Uint32List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    return _typeddata.getUint32(offsetInBytes +
                                (index * Uint32List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    _typeddata.setUint32(offsetInBytes + (index * Uint32List.BYTES_PER_ELEMENT),
                         _toUint32(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Uint32List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Uint32List.BYTES_PER_ELEMENT;
  }
}


class _Int64ArrayView extends _TypedListView implements Int64List {
  // Constructor.
  _Int64ArrayView(ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Int64List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                offsetInBytes,
                length * Int64List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    return _typeddata.getInt64(offsetInBytes +
                               (index * Int64List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    _typeddata.setInt64(offsetInBytes + (index * Int64List.BYTES_PER_ELEMENT),
                        _toInt64(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Int64List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Int64List.BYTES_PER_ELEMENT;
  }
}


class _Uint64ArrayView extends _TypedListView implements Uint64List {
  // Constructor.
  _Uint64ArrayView(ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Uint64List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                offsetInBytes,
                length * Uint64List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    return _typeddata.getUint64(offsetInBytes +
                                (index * Uint64List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    _typeddata.setUint64(offsetInBytes + (index * Uint64List.BYTES_PER_ELEMENT),
                         _toUint64(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Uint64List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Uint64List.BYTES_PER_ELEMENT;
  }
}


class _Float32ArrayView extends _TypedListView implements Float32List {
  // Constructor.
  _Float32ArrayView(ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Float32List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                offsetInBytes,
                length * Float32List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  double operator[](int index) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    return _typeddata.getFloat32(offsetInBytes +
                                 (index * Float32List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, double value) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    _typeddata.setFloat32(offsetInBytes +
                          (index * Float32List.BYTES_PER_ELEMENT), value);
  }

  Iterator<double> get iterator {
    return new _TypedListIterator<double>(this);
  }

  List<double> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<double> result = new Float32List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<double> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Float32List.BYTES_PER_ELEMENT;
  }
}


class _Float64ArrayView extends _TypedListView implements Float64List {
  // Constructor.
  _Float64ArrayView(ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Float64List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                offsetInBytes,
                length * Float64List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  double operator[](int index) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    return _typeddata.getFloat64(offsetInBytes +
                                 (index * Float64List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, double value) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    _typeddata.setFloat64(offsetInBytes +
                          (index * Float64List.BYTES_PER_ELEMENT), value);
  }

  Iterator<double> get iterator {
    return new _TypedListIterator<double>(this);
  }

  List<double> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<double> result = new Float64List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<double> from, [int startFrom = 0]) {
    Arrays.copy(from, startFrom, this, start, length);
  }


  // Method(s) implementing Object interface.

  String toString() {
    return Collections.collectionToString(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Float64List.BYTES_PER_ELEMENT;
  }
}


class _ByteDataView implements ByteData {
  _ByteDataView(ByteBuffer _buffer, int _offsetInBytes, int _lengthInBytes)
    : _typeddata = _buffer as TypedData,
      _offset = _offsetInBytes,
      _length = _lengthInBytes {
    _rangeCheck(_buffer.lengthInBytes, _offset, _length);
  }


  // Method(s) implementing TypedData interface.

  ByteBuffer get buffer {
    return _typeddata.buffer;
  }

  int get lengthInBytes {
    return _length;
  }

  int offsetInBytes() {
    return _offset;
  }

  // Method(s) implementing ByteData interface.

  int getInt8(int byteOffset) {
    return _typeddata._getInt8(_offset + byteOffset);
  }
  void setInt8(int byteOffset, int value) {
    _typeddata._setInt8(_offset + byteOffset, value);
  }

  int getUint8(int byteOffset) {
    return _typeddata._getUint8(_offset + byteOffset);
  }
  void setUint8(int byteOffset, int value) {
    _typeddata._setUint8(_offset + byteOffset, value);
  }

  int getInt16(int byteOffset) {
    return _typeddata._getInt16(_offset + byteOffset);
  }
  void setInt16(int byteOffset, int value) {
    _typeddata._setInt16(_offset + byteOffset, value);
  }

  int getUint16(int byteOffset) {
    return _typeddata._getUint16(_offset + byteOffset);
  }
  void setUint16(int byteOffset, int value) {
    _typeddata._setUint16(_offset + byteOffset, value);
  }

  int getInt32(int byteOffset) {
    return _typeddata._getInt32(_offset + byteOffset);
  }
  void setInt32(int byteOffset, int value) {
    _typeddata._setInt32(_offset + byteOffset, value);
  }

  int getUint32(int byteOffset) {
    return _typeddata._getUint32(_offset + byteOffset);
  }
  void setUint32(int byteOffset, int value) {
    _typedata._setUint32(_offset + byteOffset, value);
  }

  int getInt64(int byteOffset) {
    return _typedata._getInt64(_offset + byteOffset);
  }
  void setInt64(int byteOffset, int value) {
    _typedata._setInt64(_offset + byteOffset, value);
  }

  int getUint64(int byteOffset) {
    return _typedata._getUint64(_offset + byteOffset);
  }
  void setUint64(int byteOffset, int value) {
    _typedata._setUint64(_offset + byteOffset, value);
  }

  double getFloat32(int byteOffset) {
    return _typedata._getFloat32(_offset + byteOffset);
  }
  void setFloat32(int byteOffset, double value) {
    _typedata._setFloat32(_offset + byteOffset, value);
  }

  double getFloat64(int byteOffset) {
    return _typedata._getFloat64(_offset + byteOffset);
  }
  void setFloat64(int byteOffset, double value) {
    _typedata._setFloat64(_offset + byteOffset, value);
  }

  final TypedData _typeddata;
  final int _offset;
  final int _length;
}


// Top level utility methods.
int _toInt(int value, int mask) {
  value &= mask;
  if (value > (mask >> 1)) value -= mask + 1;
  return value;
}


int _toInt8(int value) {
  return _toInt(value, 0xFF);
}


int _toUint8(int value) {
  return value & 0xFF;
}


int _toClampedUint8(int value) {
  if (value < 0) return 0;
  if (value > 0xFF) return 0xFF;
  return value;
}


int _toInt16(int value) {
  return _toInt(value, 0xFFFF);
}


int _toUint16(int value) {
  return value & 0xFFFF;
}


int _toInt32(int value) {
  return _toInt(value, 0xFFFFFFFF);
}


int _toUint32(int value) {
  return value & 0xFFFFFFFF;
}


int _toInt64(int value) {
  return _toInt(value, 0xFFFFFFFFFFFFFFFF);
}


int _toUint64(int value) {
  return value & 0xFFFFFFFFFFFFFFFF;
}


void _rangeCheck(int listLength, int start, int length) {
  if (length < 0) {
    throw new RangeError.value(length);
  }
  if (start < 0) {
    throw new RangeError.value(start);
  }
  if (start + length > listLength) {
    throw new RangeError.value(start + length);
  }
}


int _defaultIfNull(object, value) {
  if (object == null) {
    return value;
  }
}
