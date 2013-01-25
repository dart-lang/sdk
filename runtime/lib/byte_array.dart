// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class Int8List {
  /* patch */ factory Int8List(int length) {
    return new _Int8Array(length);
  }

  /* patch */ factory Int8List.transferable(int length) {
    return _newTransferable(length);
  }

  /* patch */ factory Int8List.view(ByteArray array,
                                    [int start = 0, int length]) {
    return new _Int8ArrayView(array, start, length);
  }

  static _ExternalInt8Array _newTransferable(int length)
      native "Int8List_newTransferable";
}


patch class Uint8List {
  /* patch */ factory Uint8List(int length) {
    return new _Uint8Array(length);
  }

  /* patch */ factory Uint8List.transferable(int length) {
    return _newTransferable(length);
  }

  /* patch */ factory Uint8List.view(ByteArray array,
                                     [int start = 0, int length]) {
    return new _Uint8ArrayView(array, start, length);
  }

  static _ExternalUint8Array _newTransferable(int length)
      native "Uint8List_newTransferable";
}


patch class Uint8ClampedList {
  /* patch */ factory Uint8ClampedList(int length) {
    return new _Uint8ClampedArray(length);
  }

  /* patch */ factory Uint8ClampedList.transferable(int length) {
    return _newTransferable(length);
  }

  /* patch */ factory Uint8ClampedList.view(ByteArray array,
                                            [int start = 0, int length]) {
    return new _Uint8ClampedArrayView(array, start, length);
  }

  static _ExternalUint8ClampedArray _newTransferable(int length)
      native "Uint8ClampedList_newTransferable";
}


patch class Int16List {
  /* patch */ factory Int16List(int length) {
    return new _Int16Array(length);
  }

  /* patch */ factory Int16List.transferable(int length) {
    return _newTransferable(length);
  }

  /* patch */ factory Int16List.view(ByteArray array,
                                     [int start = 0, int length]) {
    return new _Int16ArrayView(array, start, length);
  }

  static _ExternalInt16Array _newTransferable(int length)
      native "Int16List_newTransferable";
}


patch class Uint16List {
  /* patch */ factory Uint16List(int length) {
    return new _Uint16Array(length);
  }

  /* patch */ factory Uint16List.transferable(int length) {
    return _newTransferable(length);
  }

  /* patch */ factory Uint16List.view(ByteArray array,
                                      [int start = 0, int length]) {
    return new _Uint16ArrayView(array, start, length);
  }

  static _ExternalUint16Array _newTransferable(int length)
      native "Uint16List_newTransferable";
}


patch class Int32List {
  /* patch */ factory Int32List(int length) {
    return new _Int32Array(length);
  }

  /* patch */ factory Int32List.transferable(int length) {
    return _newTransferable(length);
  }

  /* patch */ factory Int32List.view(ByteArray array,
                                     [int start = 0, int length]) {
    return new _Int32ArrayView(array, start, length);
  }

  static _ExternalInt32Array _newTransferable(int length)
      native "Int32List_newTransferable";
}


patch class Uint32List {
  /* patch */ factory Uint32List(int length) {
    return new _Uint32Array(length);
  }

  /* patch */ factory Uint32List.transferable(int length) {
    return _newTransferable(length);
  }

  /* patch */ factory Uint32List.view(ByteArray array,
                                      [int start = 0, int length]) {
    return new _Uint32ArrayView(array, start, length);
  }

  static _ExternalUint32Array _newTransferable(int length)
      native "Uint32List_newTransferable";
}


patch class Int64List {
  /* patch */ factory Int64List(int length) {
    return new _Int64Array(length);
  }

  /* patch */ factory Int64List.transferable(int length) {
    return _newTransferable(length);
  }

  /* patch */ factory Int64List.view(ByteArray array,
                                     [int start = 0, int length]) {
    return new _Int64ArrayView(array, start, length);
  }

  static _ExternalInt64Array _newTransferable(int length)
      native "Int64List_newTransferable";
}


patch class Uint64List {
  /* patch */ factory Uint64List(int length) {
    return new _Uint64Array(length);
  }

  /* patch */ factory Uint64List.transferable(int length) {
    return _newTransferable(length);
  }

  /* patch */ factory Uint64List.view(ByteArray array,
                                      [int start = 0, int length]) {
    return new _Uint64ArrayView(array, start, length);
  }

  static _ExternalUint64Array _newTransferable(int length)
      native "Uint64List_newTransferable";
}


patch class Float32List {
  /* patch */ factory Float32List(int length) {
    return new _Float32Array(length);
  }

  /* patch */ factory Float32List.transferable(int length) {
    return _newTransferable(length);
  }

  /* patch */ factory Float32List.view(ByteArray array,
                                       [int start = 0, int length]) {
    return new _Float32ArrayView(array, start, length);
  }

  static _ExternalFloat32Array _newTransferable(int length)
      native "Float32List_newTransferable";
}


patch class Float64List {
  /* patch */ factory Float64List(int length) {
    return new _Float64Array(length);
  }

  /* patch */ factory Float64List.transferable(int length) {
    return _newTransferable(length);
  }

  /* patch */ factory Float64List.view(ByteArray array,
                                       [int start = 0, int length]) {
    return new _Float64ArrayView(array, start, length);
  }

  static _ExternalFloat64Array _newTransferable(int length)
      native "Float64List_newTransferable";
}


abstract class _ByteArrayBase {
  int lengthInBytes();

  int bytesPerElement();

  operator[](int index);

  // Methods implementing the Collection interface.

  bool contains(element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(element)) {
    var len = this.length;
    for (var i = 0; i < len; i++) {
      f(this[i]);
    }
  }

  List mappedBy(f(int element)) {
    return IterableMixinWorkaround.mappedByList(this, f);
  }

  String join([String separator]) {
    return IterableMixinWorkaround.join(this, separator);
  }

  dynamic reduce(dynamic initialValue,
                 dynamic combine(dynamic initialValue, element)) {
    return IterableMixinWorkaround.reduce(this, initialValue, combine);
  }

  Collection where(bool f(element)) {
    return IterableMixinWorkaround.where(this, f);
  }

  List<int> take(int n) {
    return IterableMixinWorkaround.takeList(this, n);
  }

  Iterable<int> takeWhile(bool test(int value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  List<int> skip(int n) {
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

  int get length {
    return _length();
  }

  // Methods implementing the List interface.

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

  int min([int compare(int a, int b)]) => IterableMixinWorkaround.min(this, compare);

  int max([int compare(int a, int b)]) => IterableMixinWorkaround.max(this, compare);

  void removeRange(int start, int length) {
    throw new UnsupportedError(
        "Cannot remove from a non-extendable array");
  }

  void insertRange(int start, int length, [initialValue]) {
    throw new UnsupportedError(
        "Cannot add to a non-extendable array");
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.length;
    }
    _rangeCheck(this.length, start, length);
    return new _ByteArrayView(this,
                              start * this.bytesPerElement(),
                              length * this.bytesPerElement());
  }

  List<int> toList() {
    return new List<int>.from(this);
  }

  Set<int> toSet() {
    return new Set<int>.from(this);
  }

  int _length() native "ByteArray_getLength";

  void _setRange(int startInBytes, int lengthInBytes,
                 _ByteArrayBase from, int startFromInBytes)
      native "ByteArray_setRange";

  int _getInt8(int byteOffset) native "ByteArray_getInt8";
  int _setInt8(int byteOffset, int value) native "ByteArray_setInt8";

  int _getUint8(int byteOffset) native "ByteArray_getUint8";
  int _setUint8(int byteOffset, int value) native "ByteArray_setUint8";

  int _getInt16(int byteOffset) native "ByteArray_getInt16";
  int _setInt16(int byteOffset, int value) native "ByteArray_setInt16";

  int _getUint16(int byteOffset) native "ByteArray_getUint16";
  int _setUint16(int byteOffset, int value) native "ByteArray_setUint16";

  int _getInt32(int byteOffset) native "ByteArray_getInt32";
  int _setInt32(int byteOffset, int value) native "ByteArray_setInt32";

  int _getUint32(int byteOffset) native "ByteArray_getUint32";
  int _setUint32(int byteOffset, int value) native "ByteArray_setUint32";

  int _getInt64(int byteOffset) native "ByteArray_getInt64";
  int _setInt64(int byteOffset, int value) native "ByteArray_setInt64";

  int _getUint64(int byteOffset) native "ByteArray_getUint64";
  int _setUint64(int byteOffset, int value) native "ByteArray_setUint64";

  double _getFloat32(int byteOffset) native "ByteArray_getFloat32";
  int _setFloat32(int byteOffset, double value) native "ByteArray_setFloat32";

  double _getFloat64(int byteOffset) native "ByteArray_getFloat64";
  int _setFloat64(int byteOffset, double value) native "ByteArray_setFloat64";
}


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


int _requireInteger(object) {
  if (object is int) {
    return object;
  }
  throw new ArgumentError("$object is not an integer");
}


int _requireIntegerOrNull(object, value) {
  if (object is int) {
    return object;
  }
  if (object == null) {
    return _requireInteger(value);
  }
  throw new ArgumentError("$object is not an integer or null");
}


class _Int8Array extends _ByteArrayBase implements Int8List {
  factory _Int8Array(int length) {
    return _new(length);
  }

  factory _Int8Array.view(ByteArray array, [int start = 0, int length]) {
    if (length == null) {
      length = array.lengthInBytes();
    }
    return new _Int8ArrayView(array, start, length);
  }

  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toInt8(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Int8Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 1;

  static _Int8Array _new(int length) native "Int8Array_new";

  int _getIndexed(int index) native "Int8Array_getIndexed";
  int _setIndexed(int index, int value) native "Int8Array_setIndexed";
}


class _Uint8Array extends _ByteArrayBase implements Uint8List {
  factory _Uint8Array(int length) {
    return _new(length);
  }

  factory _Uint8Array.view(ByteArray array, [int start = 0, int length]) {
    if (length == null) {
      length = array.lengthInBytes();
    }
    return new _Uint8ArrayView(array, start, length);
  }

  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toUint8(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Uint8Array || from is _ExternalUint8Array ||
        from is _Uint8ClampedArray || from is _ExternalUint8ClampedArray) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 1;

  static _Uint8Array _new(int length) native "Uint8Array_new";

  int _getIndexed(int index) native "Uint8Array_getIndexed";
  int _setIndexed(int index, int value) native "Uint8Array_setIndexed";
}


class _Uint8ClampedArray extends _ByteArrayBase implements Uint8ClampedList {
  factory _Uint8ClampedArray(int length) {
    return _new(length);
  }

  factory _Uint8ClampedArray.view(ByteArray array,
                                 [int start = 0, int length]) {
    if (length == null) {
      length = array.lengthInBytes();
    }
    return new _Uint8ClampedArrayView(array, start, length);
  }

  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toClampedUint8(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Uint8Array || from is _ExternalUint8Array ||
        from is _Uint8ClampedArray || from is _ExternalUint8ClampedArray) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 1;

  static _Uint8ClampedArray _new(int length) native "Uint8ClampedArray_new";

  int _getIndexed(int index) native "Uint8ClampedArray_getIndexed";
  int _setIndexed(int index, int value) native "Uint8ClampedArray_setIndexed";
}


class _Int16Array extends _ByteArrayBase implements Int16List {
  factory _Int16Array(int length) {
    return _new(length);
  }

  factory _Int16Array.view(ByteArray array, [int start = 0, int length]) {
    if (length == null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Int16ArrayView(array, start, length);
  }

  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toInt16(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Int16Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 2;

  static _Int16Array _new(int length) native "Int16Array_new";

  int _getIndexed(int index) native "Int16Array_getIndexed";
  int _setIndexed(int index, int value) native "Int16Array_setIndexed";
}


class _Uint16Array extends _ByteArrayBase implements Uint16List {
  factory _Uint16Array(int length) {
    return _new(length);
  }

  factory _Uint16Array.view(ByteArray array, [int start = 0, int length]) {
    if (length == null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Uint16ArrayView(array, start, length);
  }

  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toUint16(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Uint16Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 2;

  static _Uint16Array _new(int length) native "Uint16Array_new";

  int _getIndexed(int index) native "Uint16Array_getIndexed";
  int _setIndexed(int index, int value) native "Uint16Array_setIndexed";
}


class _Int32Array extends _ByteArrayBase implements Int32List {
  factory _Int32Array(int length) {
    return _new(length);
  }

  factory _Int32Array.view(ByteArray array, [int start = 0, int length]) {
    if (length == null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Int32ArrayView(array, start, length);
  }

  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toInt32(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Int32Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 4;

  static _Int32Array _new(int length) native "Int32Array_new";


  int _getIndexed(int index) native "Int32Array_getIndexed";
  int _setIndexed(int index, int value) native "Int32Array_setIndexed";
}


class _Uint32Array extends _ByteArrayBase implements Uint32List {
  factory _Uint32Array(int length) {
    return _new(length);
  }

  factory _Uint32Array.view(ByteArray array, [int start = 0, int length]) {
    if (length == null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Uint32ArrayView(array, start, length);
  }

  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toUint32(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Uint32Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 4;

  static _Uint32Array _new(int length) native "Uint32Array_new";

  int _getIndexed(int index) native "Uint32Array_getIndexed";
  int _setIndexed(int index, int value) native "Uint32Array_setIndexed";
}


class _Int64Array extends _ByteArrayBase implements Int64List {
  factory _Int64Array(int length) {
    return _new(length);
  }

  factory _Int64Array.view(ByteArray array, [int start = 0, int length]) {
    if (length == null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Int64ArrayView(array, start, length);
  }

  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toInt64(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Int64Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 8;

  static _Int64Array _new(int length) native "Int64Array_new";

  int _getIndexed(int index) native "Int64Array_getIndexed";
  int _setIndexed(int index, int value) native "Int64Array_setIndexed";
}


class _Uint64Array extends _ByteArrayBase implements Uint64List {
  factory _Uint64Array(int length) {
    return _new(length);
  }

  factory _Uint64Array.view(ByteArray array, [int start = 0, int length]) {
    if (length == null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Uint64ArrayView(array, start, length);
  }

  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toUint64(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _Uint64Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 8;

  static _Uint64Array _new(int length) native "Uint64Array_new";

  int _getIndexed(int index) native "Uint64Array_getIndexed";
  int _setIndexed(int index, int value) native "Uint64Array_setIndexed";
}


class _Float32Array extends _ByteArrayBase implements Float32List {
  factory _Float32Array(int length) {
    return _new(length);
  }

  factory _Float32Array.view(ByteArray array, [int start = 0, int length]) {
    if (length == null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Float32ArrayView(array, start, length);
  }

  double operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, double value) {
    _setIndexed(index, value);
  }

  Iterator<double> get iterator {
    return new _ByteArrayIterator<double>(this);
  }

  List<double> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<double> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<double> from, [int startFrom = 0]) {
    if (from is _Float32Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 4;

  static _Float32Array _new(int length) native "Float32Array_new";

  double _getIndexed(int index) native "Float32Array_getIndexed";
  int _setIndexed(int index, double value) native "Float32Array_setIndexed";
}


class _Float64Array extends _ByteArrayBase implements Float64List {
  factory _Float64Array(int length) {
    return _new(length);
  }

  factory _Float64Array.view(ByteArray array, [int start = 0, int length]) {
    if (length == null) {
      length = (array.lengthInBytes() - start) ~/ _BYTES_PER_ELEMENT;
    }
    return new _Float64ArrayView(array, start, length);
  }

  double operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, double value) {
    _setIndexed(index, value);
  }

  Iterator<double> get iterator {
    return new _ByteArrayIterator<double>(this);
  }

  List<double> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<double> result = _new(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<double> from, [int startFrom = 0]) {
    if (from is _Float64Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 8;

  static _Float64Array _new(int length) native "Float64Array_new";

  double _getIndexed(int index) native "Float64Array_getIndexed";
  int _setIndexed(int index, double value) native "Float64Array_setIndexed";
}


class _ExternalInt8Array extends _ByteArrayBase implements Int8List {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toInt8(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Int8List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalInt8Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 1;

  int _getIndexed(int index) native "ExternalInt8Array_getIndexed";
  int _setIndexed(int index, int value) native "ExternalInt8Array_setIndexed";
}


class _ExternalUint8Array extends _ByteArrayBase implements Uint8List {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toUint8(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Uint8List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalUint8Array || from is _Uint8Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 1;

  int _getIndexed(int index) native "ExternalUint8Array_getIndexed";
  int _setIndexed(int index, int value) native "ExternalUint8Array_setIndexed";
}


class _ExternalUint8ClampedArray
  extends _ByteArrayBase implements Uint8ClampedList {

  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toClampedUint8(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Uint8ClampedList(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalUint8ClampedArray || from is _Uint8ClampedArray) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 1;

  int _getIndexed(int index) native "ExternalUint8ClampedArray_getIndexed";
  int _setIndexed(int index, int value) native "ExternalUint8ClampedArray_setIndexed";
}


class _ExternalInt16Array extends _ByteArrayBase implements Int16List {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toInt16(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Int16List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalInt16Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 2;

  int _getIndexed(int index) native "ExternalInt16Array_getIndexed";
  int _setIndexed(int index, int value) native "ExternalInt16Array_setIndexed";
}


class _ExternalUint16Array extends _ByteArrayBase implements Uint16List {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toUint16(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Uint16List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalUint16Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 2;

  int _getIndexed(int index)
      native "ExternalUint16Array_getIndexed";
  int _setIndexed(int index, int value)
      native "ExternalUint16Array_setIndexed";
}


class _ExternalInt32Array extends _ByteArrayBase implements Int32List {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toInt32(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Int32List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalInt32Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 4;

  int _getIndexed(int index)
      native "ExternalInt32Array_getIndexed";
  int _setIndexed(int index, int value)
      native "ExternalInt32Array_setIndexed";
}


class _ExternalUint32Array extends _ByteArrayBase implements Uint32List {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toUint32(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Uint32List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalUint32Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 4;

  int _getIndexed(int index)
      native "ExternalUint32Array_getIndexed";
  int _setIndexed(int index, int value)
      native "ExternalUint32Array_setIndexed";
}


class _ExternalInt64Array extends _ByteArrayBase implements Int64List {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toInt64(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Int64List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalInt64Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 8;

  int _getIndexed(int index)
      native "ExternalInt64Array_getIndexed";
  int _setIndexed(int index, int value)
      native "ExternalInt64Array_setIndexed";
}


class _ExternalUint64Array extends _ByteArrayBase implements Uint64List {
  int operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, int value) {
    _setIndexed(index, _toUint64(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
  }

  List<int> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<int> result = new Uint64List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<int> from, [int startFrom = 0]) {
    if (from is _ExternalUint64Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 8;

  int _getIndexed(int index)
      native "ExternalUint64Array_getIndexed";
  int _setIndexed(int index, int value)
      native "ExternalUint64Array_setIndexed";
}


class _ExternalFloat32Array extends _ByteArrayBase implements Float32List {
  double operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, double value) {
    _setIndexed(index, value);
  }

  Iterator<double> get iterator {
    return new _ByteArrayIterator<double>(this);
  }

  List<double> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<double> result = new Float32List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<double> from, [int startFrom = 0]) {
    if (from is _ExternalFloat32Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 4;

  double _getIndexed(int index)
      native "ExternalFloat32Array_getIndexed";
  int _setIndexed(int index, double value)
      native "ExternalFloat32Array_setIndexed";
}


class _ExternalFloat64Array extends _ByteArrayBase implements Float64List {
  double operator[](int index) {
    return _getIndexed(index);
  }

  int operator[]=(int index, double value) {
    _setIndexed(index, value);
  }

  Iterator<double> get iterator {
    return new _ByteArrayIterator<double>(this);
  }

  List<double> getRange(int start, int length) {
    _rangeCheck(this.length, start, length);
    List<double> result = new Float64List(length);
    result.setRange(0, length, this, start);
    return result;
  }

  void setRange(int start, int length, List<double> from, [int startFrom = 0]) {
    if (from is _ExternalFloat64Array) {
      _setRange(start * _BYTES_PER_ELEMENT,
                length * _BYTES_PER_ELEMENT,
                from,
                startFrom * _BYTES_PER_ELEMENT);
    } else {
      Arrays.copy(from, startFrom, this, start, length);
    }
  }

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return _length() * _BYTES_PER_ELEMENT;
  }

  static const int _BYTES_PER_ELEMENT = 8;

  double _getIndexed(int index)
      native "ExternalFloat64Array_getIndexed";
  int _setIndexed(int index, double value)
      native "ExternalFloat64Array_setIndexed";
}


class _ByteArrayIterator<E> implements Iterator<E> {
  final List<E> _array;
  final int _length;
  int _position;
  E _current;

  _ByteArrayIterator(List array)
      : _array = array, _length = array.length, _position = -1 {
    assert(array is _ByteArrayBase || array is _ByteArrayViewBase);
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


class _ByteArrayView implements ByteArray {
  _ByteArrayView(this._array, this._offset, this._length) {
    _rangeCheck(_array.lengthInBytes(), _offset, _length);
  }

  int lengthInBytes() {
    return _length;
  }

  ByteArray subByteArray([int start = 0, int length]) {
    if (start is! int) throw new ArgumentError("start is not an int");
    if (length == null) {
      length = this.lengthInBytes() - start;
    } else if (length is! int) {
      throw new ArgumentError("length is not an int");
    }
    return new _ByteArrayView(_array, _offset + start, length);
  }

  int getInt8(int byteOffset) {
    return _array._getInt8(_offset + byteOffset);
  }
  int setInt8(int byteOffset, int value) {
    return _array._setInt8(_offset + byteOffset, value);
  }

  int getUint8(int byteOffset) {
    return _array._getUint8(_offset + byteOffset);
  }
  int setUint8(int byteOffset, int value) {
    return _array._setUint8(_offset + byteOffset, value);
  }

  int getInt16(int byteOffset) {
    return _array._getInt16(_offset + byteOffset);
  }
  int setInt16(int byteOffset, int value) {
    return _array._setInt16(_offset + byteOffset, value);
  }

  int getUint16(int byteOffset) {
    return _array._getUint16(_offset + byteOffset);
  }
  int setUint16(int byteOffset, int value) {
    return _array._setUint16(_offset + byteOffset, value);
  }

  int getInt32(int byteOffset) {
    return _array._getInt32(_offset + byteOffset);
  }
  int setInt32(int byteOffset, int value) {
    return _array._setInt32(_offset + byteOffset, value);
  }

  int getUint32(int byteOffset) {
    return _array._getUint32(_offset + byteOffset);
  }
  int setUint32(int byteOffset, int value) {
    return _array._setUint32(_offset + byteOffset, value);
  }

  int getInt64(int byteOffset) {
    return _array._getInt64(_offset + byteOffset);
  }
  int setInt64(int byteOffset, int value) {
    return _array._setInt64(_offset + byteOffset, value);
  }

  int getUint64(int byteOffset) {
    return _array._getUint64(_offset + byteOffset);
  }
  int setUint64(int byteOffset, int value) {
    return _array._setUint64(_offset + byteOffset, value);
  }

  double getFloat32(int byteOffset) {
    return _array._getFloat32(_offset + byteOffset);
  }
  int setFloat32(int byteOffset, double value) {
    return _array._setFloat32(_offset + byteOffset, value);
  }

  double getFloat64(int byteOffset) {
    return _array._getFloat64(_offset + byteOffset);
  }
  int setFloat64(int byteOffset, double value) {
    return _array._setFloat64(_offset + byteOffset, value);
  }

  final _ByteArrayBase _array;
  final int _offset;
  final int _length;
}


// TODO(floitsch): extending the collection adds extra cost (because of type
// parameters). Consider copying the functions from Collection into this class
// and just implementing Collection<int>.
class _ByteArrayViewBase extends Collection<int> {
  _ByteArrayViewBase(this._array, this._offset, this.length);

  num operator[](int index);

  // Methods implementing the Collection interface.

  void forEach(void f(element)) {
    var len = this.length;
    for (var i = 0; i < len; i++) {
      f(this[i]);
    }
  }

  bool get isEmpty {
    return this.length == 0;
  }

  // Methods implementing the List interface.

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

  int removeAt(int index) {
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

  void removeRange(int start, int length) {
    throw new UnsupportedError(
        "Cannot remove from a non-extendable array");
  }

  void insertRange(int start, int length, [initialValue]) {
    throw new UnsupportedError(
        "Cannot add to a non-extendable array");
  }

  final ByteArray _array;
  final int _offset;
  final int length;
}


class _Int8ArrayView extends _ByteArrayViewBase implements Int8List {
  _Int8ArrayView(ByteArray array, [int offsetInBytes = 0, int _length])
    : super(array, _requireInteger(offsetInBytes),
      _requireIntegerOrNull(
        _length,
        ((array.lengthInBytes() - offsetInBytes) ~/ _BYTES_PER_ELEMENT))) {
    _rangeCheck(array.lengthInBytes(), _offset, length * _BYTES_PER_ELEMENT);
  }

  int operator[](int index) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    return _array.getInt8(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    _array.setInt8(_offset + (index * _BYTES_PER_ELEMENT), _toInt8(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
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

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(this.length, start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static const int _BYTES_PER_ELEMENT = 1;
}


class _Uint8ArrayView extends _ByteArrayViewBase implements Uint8List {
  _Uint8ArrayView(ByteArray array, [int offsetInBytes = 0, int _length])
    : super(array, _requireInteger(offsetInBytes),
      _requireIntegerOrNull(
        _length,
        ((array.lengthInBytes() - offsetInBytes) ~/ _BYTES_PER_ELEMENT))) {
    _rangeCheck(array.lengthInBytes(), _offset, length * _BYTES_PER_ELEMENT);
  }

  int operator[](int index) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    return _array.getUint8(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    _array.setUint8(_offset + (index * _BYTES_PER_ELEMENT), _toUint8(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
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

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(this.length, start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static const int _BYTES_PER_ELEMENT = 1;
}


class _Int16ArrayView extends _ByteArrayViewBase implements Int16List {
  _Int16ArrayView(ByteArray array, [int offsetInBytes = 0, int _length])
    : super(array, _requireInteger(offsetInBytes),
      _requireIntegerOrNull(
        _length,
        ((array.lengthInBytes() - offsetInBytes) ~/ _BYTES_PER_ELEMENT))) {
    _rangeCheck(array.lengthInBytes(), _offset, length * _BYTES_PER_ELEMENT);
  }

  int operator[](int index) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    return _array.getInt16(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    _array.setInt16(_offset + (index * _BYTES_PER_ELEMENT), _toInt16(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
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

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(this.length, start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static const int _BYTES_PER_ELEMENT = 2;
}


class _Uint16ArrayView extends _ByteArrayViewBase implements Uint16List {
  _Uint16ArrayView(ByteArray array, [int offsetInBytes = 0, int _length])
    : super(array, _requireInteger(offsetInBytes),
      _requireIntegerOrNull(
        _length,
        ((array.lengthInBytes() - offsetInBytes) ~/ _BYTES_PER_ELEMENT))) {
    _rangeCheck(array.lengthInBytes(), _offset, length * _BYTES_PER_ELEMENT);
  }

  int operator[](int index) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    return _array.getUint16(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    _array.setUint16(_offset + (index * _BYTES_PER_ELEMENT), _toUint16(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
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

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(this.length, start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static const int _BYTES_PER_ELEMENT = 2;
}


class _Int32ArrayView extends _ByteArrayViewBase implements Int32List {
  _Int32ArrayView(ByteArray array, [int offsetInBytes = 0, int _length])
    : super(array, _requireInteger(offsetInBytes),
      _requireIntegerOrNull(
        _length,
        ((array.lengthInBytes() - offsetInBytes) ~/ _BYTES_PER_ELEMENT))) {
    _rangeCheck(array.lengthInBytes(), _offset, length * _BYTES_PER_ELEMENT);
  }

  int operator[](int index) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    return _array.getInt32(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    _array.setInt32(_offset + (index * _BYTES_PER_ELEMENT), _toInt32(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
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

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(this.length, start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static const int _BYTES_PER_ELEMENT = 4;
}


class _Uint32ArrayView extends _ByteArrayViewBase implements Uint32List {
  _Uint32ArrayView(ByteArray array, [int offsetInBytes = 0, int _length])
    : super(array, _requireInteger(offsetInBytes),
      _requireIntegerOrNull(
        _length,
        ((array.lengthInBytes() - offsetInBytes) ~/ _BYTES_PER_ELEMENT))) {
    _rangeCheck(array.lengthInBytes(), _offset, length * _BYTES_PER_ELEMENT);
  }

  int operator[](int index) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    return _array.getUint32(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    _array.setUint32(_offset + (index * _BYTES_PER_ELEMENT), _toUint32(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
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

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(this.length, start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static const int _BYTES_PER_ELEMENT = 4;
}


class _Int64ArrayView extends _ByteArrayViewBase implements Int64List {
  _Int64ArrayView(ByteArray array, [int offsetInBytes = 0, int _length])
    : super(array, _requireInteger(offsetInBytes),
      _requireIntegerOrNull(
        _length,
        ((array.lengthInBytes() - offsetInBytes) ~/ _BYTES_PER_ELEMENT))) {
    _rangeCheck(array.lengthInBytes(), _offset, length * _BYTES_PER_ELEMENT);
  }

  int operator[](int index) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    return _array.getInt64(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    _array.setInt64(_offset + (index * _BYTES_PER_ELEMENT), _toInt64(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
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

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(this.length, start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static const int _BYTES_PER_ELEMENT = 8;
}


class _Uint64ArrayView extends _ByteArrayViewBase implements Uint64List {
  _Uint64ArrayView(ByteArray array, [int offsetInBytes = 0, int _length])
    : super(array, _requireInteger(offsetInBytes),
      _requireIntegerOrNull(
        _length,
        ((array.lengthInBytes() - offsetInBytes) ~/ _BYTES_PER_ELEMENT))) {
    _rangeCheck(array.lengthInBytes(), _offset, length * _BYTES_PER_ELEMENT);
  }

  int operator[](int index) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    return _array.getUint64(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    _array.setUint64(_offset + (index * _BYTES_PER_ELEMENT), _toUint64(value));
  }

  Iterator<int> get iterator {
    return new _ByteArrayIterator<int>(this);
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

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(this.length, start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static const int _BYTES_PER_ELEMENT = 8;
}


class _Float32ArrayView extends _ByteArrayViewBase implements Float32List {
  _Float32ArrayView(ByteArray array, [int offsetInBytes = 0, int _length])
    : super(array, _requireInteger(offsetInBytes),
      _requireIntegerOrNull(
        _length,
        ((array.lengthInBytes() - offsetInBytes) ~/ _BYTES_PER_ELEMENT))) {
    _rangeCheck(array.lengthInBytes(), _offset, length * _BYTES_PER_ELEMENT);
  }

  double operator[](int index) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    return _array.getFloat32(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, double value) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    _array.setFloat32(_offset + (index * _BYTES_PER_ELEMENT), value);
  }

  Iterator<double> get iterator {
    return new _ByteArrayIterator<double>(this);
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

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(this.length, start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static const int _BYTES_PER_ELEMENT = 4;
}


class _Float64ArrayView extends _ByteArrayViewBase implements Float64List {
  _Float64ArrayView(ByteArray array, [int offsetInBytes = 0, int _length])
    : super(array, _requireInteger(offsetInBytes),
      _requireIntegerOrNull(
        _length,
        ((array.lengthInBytes() - offsetInBytes) ~/ _BYTES_PER_ELEMENT))) {
    _rangeCheck(array.lengthInBytes(), _offset, length * _BYTES_PER_ELEMENT);
  }

  double operator[](int index) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    return _array.getFloat64(_offset + (index * _BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, double value) {
    if (index < 0 || index >= length) {
      String message = "$index must be in the range [0..$length)";
      throw new RangeError(message);
    }
    _array.setFloat64(_offset + (index * _BYTES_PER_ELEMENT), value);
  }

  Iterator<double> get iterator {
    return new _ByteArrayIterator<double>(this);
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

  String toString() {
    return Collections.collectionToString(this);
  }

  int bytesPerElement() {
    return _BYTES_PER_ELEMENT;
  }

  int lengthInBytes() {
    return length * _BYTES_PER_ELEMENT;
  }

  ByteArray asByteArray([int start = 0, int length]) {
    if (length == null) {
      length = this.lengthInBytes();
    }
    _rangeCheck(this.length, start, length);
    return _array.subByteArray(_offset + start, length);
  }

  static const int _BYTES_PER_ELEMENT = 8;
}
