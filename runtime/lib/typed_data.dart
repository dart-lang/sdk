// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// patch classes for Int8List ..... Float64List and ByteData implementations.

patch class Int8List {
  /* patch */ factory Int8List(int length) {
    return new _Int8Array(length);
  }

  /* patch */ factory Int8List.fromList(List<int> elements) {
    var result = new _Int8Array(elements.length);
    for (int i = 0; i < elements.length; i++) {
      result[i] = elements[i];
    }
    return result;
  }

  /* patch */ factory Int8List.view(ByteBuffer buffer,
                                    [int offsetInBytes = 0, int length]) {
    return new _Int8ArrayView(buffer, offsetInBytes, length);
  }
}


patch class Uint8List {
  /* patch */ factory Uint8List(int length) {
    return new _Uint8Array(length);
  }

  /* patch */ factory Uint8List.fromList(List<int> elements) {
    var result = new _Uint8Array(elements.length);
    for (int i = 0; i < elements.length; i++) {
      result[i] = elements[i];
    }
    return result;
  }

  /* patch */ factory Uint8List.view(ByteBuffer buffer,
                                     [int offsetInBytes = 0, int length]) {
    return new _Uint8ArrayView(buffer, offsetInBytes, length);
  }
}


patch class Uint8ClampedList {
  /* patch */ factory Uint8ClampedList(int length) {
    return new _Uint8ClampedArray(length);
  }

  /* patch */ factory Uint8ClampedList.fromList(List<int> elements) {
    var result = new _Uint8ClampedArray(elements.length);
    for (int i = 0; i < elements.length; i++) {
      result[i] = elements[i];
    }
    return result;
  }

  /* patch */ factory Uint8ClampedList.view(ByteBuffer buffer,
                                            [int offsetInBytes = 0,
                                             int length]) {
    return new _Uint8ClampedArrayView(buffer, offsetInBytes, length);
  }
}


patch class Int16List {
  /* patch */ factory Int16List(int length) {
    return new _Int16Array(length);
  }

  /* patch */ factory Int16List.fromList(List<int> elements) {
    var result = new _Int16Array(elements.length);
    for (int i = 0; i < elements.length; i++) {
      result[i] = elements[i];
    }
    return result;
  }

  /* patch */ factory Int16List.view(ByteBuffer buffer,
                                     [int offsetInBytes = 0, int length]) {
    return new _Int16ArrayView(buffer, offsetInBytes, length);
  }
}


patch class Uint16List {
  /* patch */ factory Uint16List(int length) {
    return new _Uint16Array(length);
  }

  /* patch */ factory Uint16List.fromList(List<int> elements) {
    var result = new _Uint16Array(elements.length);
    for (int i = 0; i < elements.length; i++) {
      result[i] = elements[i];
    }
    return result;
  }

  /* patch */ factory Uint16List.view(ByteBuffer buffer,
                                      [int offsetInBytes = 0, int length]) {
    return new _Uint16ArrayView(buffer, offsetInBytes, length);
  }
}


patch class Int32List {
  /* patch */ factory Int32List(int length) {
    return new _Int32Array(length);
  }

  /* patch */ factory Int32List.fromList(List<int> elements) {
    var result = new _Int32Array(elements.length);
    for (int i = 0; i < elements.length; i++) {
      result[i] = elements[i];
    }
    return result;
  }

  /* patch */ factory Int32List.view(ByteBuffer buffer,
                                     [int offsetInBytes = 0, int length]) {
    return new _Int32ArrayView(buffer, offsetInBytes, length);
  }
}


patch class Uint32List {
  /* patch */ factory Uint32List(int length) {
    return new _Uint32Array(length);
  }

  /* patch */ factory Uint32List.fromList(List<int> elements) {
    var result = new _Uint32Array(elements.length);
    for (int i = 0; i < elements.length; i++) {
      result[i] = elements[i];
    }
    return result;
  }

  /* patch */ factory Uint32List.view(ByteBuffer buffer,
                                      [int offsetInBytes = 0, int length]) {
    return new _Uint32ArrayView(buffer, offsetInBytes, length);
  }
}


patch class Int64List {
  /* patch */ factory Int64List(int length) {
    return new _Int64Array(length);
  }

  /* patch */ factory Int64List.fromList(List<int> elements) {
    var result = new _Int64Array(elements.length);
    for (int i = 0; i < elements.length; i++) {
      result[i] = elements[i];
    }
    return result;
  }

  /* patch */ factory Int64List.view(ByteBuffer buffer,
                                     [int offsetInBytes = 0, int length]) {
    return new _Int64ArrayView(buffer, offsetInBytes, length);
  }
}


patch class Uint64List {
  /* patch */ factory Uint64List(int length) {
    return new _Uint64Array(length);
  }

  /* patch */ factory Uint64List.fromList(List<int> elements) {
    var result = new _Uint64Array(elements.length);
    for (int i = 0; i < elements.length; i++) {
      result[i] = elements[i];
    }
    return result;
  }

  /* patch */ factory Uint64List.view(ByteBuffer buffer,
                                      [int offsetInBytes = 0, int length]) {
    return new _Uint64ArrayView(buffer, offsetInBytes, length);
  }
}


patch class Float32List {
  /* patch */ factory Float32List(int length) {
    return new _Float32Array(length);
  }

  /* patch */ factory Float32List.fromList(List<double> elements) {
    var result = new _Float32Array(elements.length);
    for (int i = 0; i < elements.length; i++) {
      result[i] = elements[i];
    }
    return result;
  }

  /* patch */ factory Float32List.view(ByteBuffer buffer,
                                       [int offsetInBytes = 0, int length]) {
    return new _Float32ArrayView(buffer, offsetInBytes, length);
  }
}


patch class Float64List {
  /* patch */ factory Float64List(int length) {
    return new _Float64Array(length);
  }

  /* patch */ factory Float64List.fromList(List<double> elements) {
    var result = new _Float64Array(elements.length);
    for (int i = 0; i < elements.length; i++) {
      result[i] = elements[i];
    }
    return result;
  }

  /* patch */ factory Float64List.view(ByteBuffer buffer,
                                       [int offsetInBytes = 0, int length]) {
    return new _Float64ArrayView(buffer, offsetInBytes, length);
  }
}

patch class Float32x4List {
  /* patch */ factory Float32x4List(int length) {
    return new _Float32x4Array(length);
  }

  /* patch */ factory Float32x4List.view(ByteBuffer buffer,
                                         [int offsetInBytes = 0, int length]) {
    return new _Float32x4ArrayView(buffer, offsetInBytes, length);
  }
}


patch class Float32x4 {
  /* patch */ factory Float32x4(double x, double y, double z, double w) {
    return new _Float32x4(x, y, z, w);
  }
  /* patch */ factory Float32x4.splat(double v) {
    return new _Float32x4.splat(v);
  }
  /* patch */ factory Float32x4.zero() {
    return new _Float32x4.zero();
  }
}


patch class Uint32x4 {
  /* patch */ factory Uint32x4(int x, int y, int z, int w) {
    return new _Uint32x4(x, y, z, w);
  }
  /* patch */ factory Uint32x4.bool(bool x, bool y, bool z, bool w) {
    return new _Uint32x4.bool(x, y, z, w);
  }
}


patch class ByteData {
  /* patch */ factory ByteData(int length) {
    var list = new _Uint8Array(length);
    return new _ByteDataView(list.buffer, 0, length);
  }

  /* patch */ factory ByteData.view(ByteBuffer buffer,
                                    [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = buffer.lengthInBytes - offsetInBytes;
    }
    return new _ByteDataView(buffer, offsetInBytes, length);
  }
}


// Based class for _TypedList that provides common methods for implementing
// the collection and list interfaces.

abstract class _TypedListBase {

  // Method(s) implementing the Collection interface.
  bool contains(element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(num element)) {
    var len = this.length;
    for (var i = 0; i < len; i++) {
      f(this[i]);
    }
  }

  Iterable map(f(num element)) {
    return IterableMixinWorkaround.mapList(this, f);
  }

  String join([String separator = ""]) {
    return IterableMixinWorkaround.join(this, separator);
  }

  num reduce(dynamic combine(num value, num element)) {
    return IterableMixinWorkaround.reduce(this, combine);
  }

  dynamic fold(dynamic initialValue,
               dynamic combine(dynamic initialValue, num element)) {
    return IterableMixinWorkaround.fold(this, initialValue, combine);
  }

  Iterable where(bool f(num element)) {
    return IterableMixinWorkaround.where(this, f);
  }

  Iterable expand(Iterable f(num element)) {
    return IterableMixinWorkaround.expand(this, f);
  }

  Iterable take(int n) {
    return IterableMixinWorkaround.takeList(this, n);
  }

  Iterable takeWhile(bool test(num element)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  Iterable skip(int n) {
    return IterableMixinWorkaround.skipList(this, n);
  }

  Iterable skipWhile(bool test(num element)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  bool every(bool f(num element)) {
    return IterableMixinWorkaround.every(this, f);
  }

  bool any(bool f(num element)) {
    return IterableMixinWorkaround.any(this, f);
  }

  num firstWhere(bool test(num element), {orElse()}) {
    return IterableMixinWorkaround.firstWhere(this, test, orElse);
  }

  num lastWhere(bool test(num element), {orElse()}) {
    return IterableMixinWorkaround.lastWhereList(this, test, orElse);
  }

  num singleWhere(bool test(num element)) {
    return IterableMixinWorkaround.singleWhere(this, test);
  }

  Iterable<num> get reversed {
    return IterableMixinWorkaround.reversedList(this);
  }

  num elementAt(int index) {
    return this[index];
  }

  bool get isEmpty {
    return this.length == 0;
  }

  bool get isNotEmpty => !isEmpty;

  // Method(s) implementing the List interface.

  set length(newLength) {
    throw new UnsupportedError(
        "Cannot resize a non-extendable array");
  }

  void add(value) {
    throw new UnsupportedError(
        "Cannot add to a non-extendable array");
  }

  void addAll(Iterable value) {
    throw new UnsupportedError(
        "Cannot add to a non-extendable array");
  }

  void insert(int index, value) {
    throw new UnsupportedError(
        "Cannot insert into a non-extendable array");
  }

  void insertAll(int index, Iterable values) {
    throw new UnsupportedError(
        "Cannot insert into a non-extendable array");
  }

  void sort([int compare(num a, num b)]) {
    return IterableMixinWorkaround.sortList(this, compare);
  }

  int indexOf(element, [int start = 0]) {
    return IterableMixinWorkaround.indexOfList(this, element, start);
  }

  int lastIndexOf(element, [int start = null]) {
    return IterableMixinWorkaround.lastIndexOfList(this, element, start);
  }

  void clear() {
    throw new UnsupportedError(
        "Cannot remove from a non-extendable array");
  }

  int removeLast() {
    throw new UnsupportedError(
        "Cannot remove from a non-extendable array");
  }

  bool remove(Object element) {
    throw new UnsupportedError(
        "Cannot remove from a non-extendable array");
  }

  bool removeAt(int index) {
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

  void removeWhere(bool test(element)) {
    throw new UnsupportedError(
        "Cannot remove from a non-extendable array");
  }

  void retainWhere(bool test(element)) {
    throw new UnsupportedError(
        "Cannot remove from a non-extendable array");
  }

  num get first {
    if (length > 0) return this[0];
    throw new StateError("No elements");
  }

  num get last {
    if (length > 0) return this[length - 1];
    throw new StateError("No elements");
  }

  num get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  void removeRange(int start, int end) {
    throw new UnsupportedError(
        "Cannot remove from a non-extendable array");
  }

  void replaceRange(int start, int end, Iterable iterable) {
    throw new UnsupportedError(
        "Cannot remove from a non-extendable array");
  }

  List toList({bool growable: true}) {
    return new List.from(this, growable: growable);
  }

  Set toSet() {
    return new Set.from(this);
  }

  Map<int, num> asMap() {
    return IterableMixinWorkaround.asMapList(this);
  }

  List sublist(int start, [int end]) {
    if (end == null) end = length;
    int length = end - start;
    _rangeCheck(this.length, start, length);
    List result = _createList(length);
    result.setRange(0, length, this, start);
    return result;
  }

  Iterable getRange(int start, [int end]) {
    return IterableMixinWorkaround.getRangeList(this, start, end);
  }

  void setRange(int start, int end, Iterable iterable, [int skipCount = 0]) {
    if (!_setRange(start, end - start, iterable, skipCount)) {
      IterableMixinWorkaround.setRangeList(this, start,
                                           end, iterable, skipCount);
    }
  }

  void setAll(int index, Iterable iterable) {
    IterableMixinWorkaround.setAllList(this, index, iterable);
  }

  void fillRange(int start, int end, [num fillValue]) {
    IterableMixinWorkaround.fillRangeList(this, start, end, fillValue);
  }


  // Method(s) implementing Object interface.

  String toString() {
    return IterableMixinWorkaround.toStringIterable(this, '[', ']');
  }


  // Internal utility methods.

  bool _setRange(int start, int length, Iterable from, int startFrom)
      native "TypedData_setRange";
}


abstract class _TypedList extends _TypedListBase implements ByteBuffer {
  // Default method implementing parts of the TypedData interface.
  int get offsetInBytes {
    return 0;
  }

  int get lengthInBytes {
    return length * elementSizeInBytes;
  }

  ByteBuffer get buffer {
    return this;
  }


  // Methods implementing the collection interface.

  int get length native "TypedData_length";


  // Internal utility methods.

  int _getInt8(int offsetInBytes) native "TypedData_GetInt8";
  void _setInt8(int offsetInBytes, int value) native "TypedData_SetInt8";

  int _getUint8(int offsetInBytes) native "TypedData_GetUint8";
  void _setUint8(int offsetInBytes, int value) native "TypedData_SetUint8";

  int _getInt16(int offsetInBytes) native "TypedData_GetInt16";
  void _setInt16(int offsetInBytes, int value) native "TypedData_SetInt16";

  int _getUint16(int offsetInBytes) native "TypedData_GetUint16";
  void _setUint16(int offsetInBytes, int value) native "TypedData_SetUint16";

  int _getInt32(int offsetInBytes) native "TypedData_GetInt32";
  void _setInt32(int offsetInBytes, int value) native "TypedData_SetInt32";

  int _getUint32(int offsetInBytes) native "TypedData_GetUint32";
  void _setUint32(int offsetInBytes, int value) native "TypedData_SetUint32";

  int _getInt64(int offsetInBytes) native "TypedData_GetInt64";
  void _setInt64(int offsetInBytes, int value) native "TypedData_SetInt64";

  int _getUint64(int offsetInBytes) native "TypedData_GetUint64";
  void _setUint64(int offsetInBytes, int value) native "TypedData_SetUint64";

  double _getFloat32(int offsetInBytes) native "TypedData_GetFloat32";
  void _setFloat32(int offsetInBytes, double value)
      native "TypedData_SetFloat32";

  double _getFloat64(int offsetInBytes) native "TypedData_GetFloat64";
  void _setFloat64(int offsetInBytes, double value)
      native "TypedData_SetFloat64";

  Float32x4 _getFloat32x4(int offsetInBytes) native "TypedData_GetFloat32x4";
  void _setFloat32x4(int offsetInBytes, Float32x4 value)
      native "TypedData_SetFloat32x4";
}


class _Int8Array extends _TypedList implements Int8List {
  // Factory constructors.

  factory _Int8Array(int length) {
    return _new(length);
  }

  factory _Int8Array.view(ByteBuffer buffer,
                          [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = buffer.lengthInBytes - offsetInBytes;
    }
    return new _Int8ArrayView(buffer, offsetInBytes, length);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getInt8(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setInt8(index, _toInt8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Int8List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Int8Array _createList(int length) {
    return _new(length);
  }

  static _Int8Array _new(int length) native "TypedData_Int8Array_new";
}


class _Uint8Array extends _TypedList implements Uint8List {
  // Factory constructors.

  factory _Uint8Array(int length) {
    return _new(length);
  }

  factory _Uint8Array.view(ByteBuffer buffer,
                           [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = buffer.lengthInBytes - offsetInBytes;
    }
    return new _Uint8ArrayView(buffer, offsetInBytes, length);
  }


  // Methods implementing List interface.
  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getUint8(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setUint8(index, _toUint8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Methods implementing TypedData interface.
  int get elementSizeInBytes {
    return Uint8List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Uint8Array _createList(int length) {
    return _new(length);
  }

  static _Uint8Array _new(int length) native "TypedData_Uint8Array_new";
}


class _Uint8ClampedArray extends _TypedList implements Uint8ClampedList {
  // Factory constructors.

  factory _Uint8ClampedArray(int length) {
    return _new(length);
  }

  factory _Uint8ClampedArray.view(ByteBuffer buffer,
                                  [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = buffer.lengthInBytes - offsetInBytes;
    }
    return new _Uint8ClampedArrayView(buffer, offsetInBytes, length);
  }


  // Methods implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getUint8(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setUint8(index, _toClampedUint8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Methods implementing TypedData interface.
  int get elementSizeInBytes {
    return Uint8List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Uint8ClampedArray _createList(int length) {
    return _new(length);
  }

  static _Uint8ClampedArray _new(int length)
      native "TypedData_Uint8ClampedArray_new";
}


class _Int16Array extends _TypedList implements Int16List {
  // Factory constructors.

  factory _Int16Array(int length) {
    return _new(length);
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
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedInt16(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedInt16(index, _toInt16(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Int16List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Int16Array _createList(int length) {
    return _new(length);
  }

  int _getIndexedInt16(int index) {
    return _getInt16(index * Int16List.BYTES_PER_ELEMENT);
  }

  void _setIndexedInt16(int index, int value) {
    _setInt16(index * Int16List.BYTES_PER_ELEMENT, value);
  }

  static _Int16Array _new(int length) native "TypedData_Int16Array_new";
}


class _Uint16Array extends _TypedList implements Uint16List {
  // Factory constructors.

  factory _Uint16Array(int length) {
    return _new(length);
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
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedUint16(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedUint16(index, _toUint16(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Uint16List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Uint16Array _createList(int length) {
    return _new(length);
  }

  int _getIndexedUint16(int index) {
    return _getUint16(index * Uint16List.BYTES_PER_ELEMENT);
  }

  void _setIndexedUint16(int index, int value) {
    _setUint16(index * Uint16List.BYTES_PER_ELEMENT, value);
  }

  static _Uint16Array _new(int length) native "TypedData_Uint16Array_new";
}


class _Int32Array extends _TypedList implements Int32List {
  // Factory constructors.

  factory _Int32Array(int length) {
    return _new(length);
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
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedInt32(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedInt32(index, _toInt32(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Int32List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Int32Array _createList(int length) {
    return _new(length);
  }

  int _getIndexedInt32(int index) {
    return _getInt32(index * Int32List.BYTES_PER_ELEMENT);
  }

  void _setIndexedInt32(int index, int value) {
    _setInt32(index * Int32List.BYTES_PER_ELEMENT, value);
  }

  static _Int32Array _new(int length) native "TypedData_Int32Array_new";
}


class _Uint32Array extends _TypedList implements Uint32List {
  // Factory constructors.

  factory _Uint32Array(int length) {
    return _new(length);
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
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedUint32(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedUint32(index, _toUint32(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Uint32List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Uint32Array _createList(int length) {
    return _new(length);
  }

  int _getIndexedUint32(int index) {
    return _getUint32(index * Uint32List.BYTES_PER_ELEMENT);
  }

  void _setIndexedUint32(int index, int value) {
    _setInt32(index * Uint32List.BYTES_PER_ELEMENT, value);
  }

  static _Uint32Array _new(int length) native "TypedData_Uint32Array_new";
}


class _Int64Array extends _TypedList implements Int64List {
  // Factory constructors.

  factory _Int64Array(int length) {
    return _new(length);
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
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedInt64(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedInt64(index, _toInt64(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Int64List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Int64Array _createList(int length) {
    return _new(length);
  }

  int _getIndexedInt64(int index) {
    return _getInt64(index * Int64List.BYTES_PER_ELEMENT);
  }

  void _setIndexedInt64(int index, int value) {
    _setInt64(index * Int64List.BYTES_PER_ELEMENT, value);
  }

  static _Int64Array _new(int length) native "TypedData_Int64Array_new";
}


class _Uint64Array extends _TypedList implements Uint64List {
  // Factory constructors.

  factory _Uint64Array(int length) {
    return _new(length);
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
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedUint64(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedUint64(index, _toUint64(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Uint64List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Uint64Array _createList(int length) {
    return _new(length);
  }

  int _getIndexedUint64(int index) {
    return _getUint64(index * Uint64List.BYTES_PER_ELEMENT);
  }

  void _setIndexedUint64(int index, int value) {
    _setUint64(index * Uint64List.BYTES_PER_ELEMENT, value);
  }

  static _Uint64Array _new(int length) native "TypedData_Uint64Array_new";
}


class _Float32Array extends _TypedList implements Float32List {
  // Factory constructors.

  factory _Float32Array(int length) {
    return _new(length);
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
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedFloat32(index);
  }

  void operator[]=(int index, double value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedFloat32(index, value);
  }

  Iterator<double> get iterator {
    return new _TypedListIterator<double>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Float32List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Float32Array _createList(int length) {
    return _new(length);
  }

  double _getIndexedFloat32(int index) {
    return _getFloat32(index * Float32List.BYTES_PER_ELEMENT);
  }

  void _setIndexedFloat32(int index, double value) {
    _setFloat32(index * Float32List.BYTES_PER_ELEMENT, value);
  }

  static _Float32Array _new(int length) native "TypedData_Float32Array_new";
}


class _Float64Array extends _TypedList implements Float64List {
  // Factory constructors.

  factory _Float64Array(int length) {
    return _new(length);
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
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedFloat64(index);
  }

  void operator[]=(int index, double value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedFloat64(index, value);
  }

  Iterator<double> get iterator {
    return new _TypedListIterator<double>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Float64List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Float64Array _createList(int length) {
    return _new(length);
  }

  double _getIndexedFloat64(int index) {
    return _getFloat64(index * Float64List.BYTES_PER_ELEMENT);
  }

  void _setIndexedFloat64(int index, double value) {
    _setFloat64(index * Float64List.BYTES_PER_ELEMENT, value);
  }

  static _Float64Array _new(int length) native "TypedData_Float64Array_new";
}

class _Float32x4Array extends _TypedList implements Float32x4List {
  // Factory constructors.

  factory _Float32x4Array(int length) {
    return _new(length);
  }

  factory _Float32x4Array.view(ByteBuffer buffer,
                               [int offsetInBytes = 0, int length]) {
    if (length == null) {
      length = (buffer.lengthInBytes - offsetInBytes) ~/
               Float32x4List.BYTES_PER_ELEMENT;
    }
    return new _Float32x4ArrayView(buffer, offsetInBytes, length);
  }


  Float32x4 operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedFloat32x4(index);
  }

  void operator[]=(int index, Float32x4 value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedFloat32x4(index, value);
  }

  Iterator<Float32x4> get iterator {
    return new _TypedListIterator<Float32x4>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Float32x4List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  _Float32x4Array _createList(int length) {
    return _new(length);
  }

  Float32x4 _getIndexedFloat32x4(int index) {
    return _getFloat32x4(index * Float32x4List.BYTES_PER_ELEMENT);
  }

  void _setIndexedFloat32x4(int index, Float32x4 value) {
    _setFloat32x4(index * Float32x4List.BYTES_PER_ELEMENT, value);
  }

  static _Float32x4Array _new(int length) native "TypedData_Float32x4Array_new";
}


class _ExternalInt8Array extends _TypedList implements Int8List {
  // Factory constructors.

  factory _ExternalInt8Array(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.
  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getInt8(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setInt8(index, value);
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Int8List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Int8List _createList(int length) {
    return new Int8List(length);
  }

  static _ExternalInt8Array _new(int length) native
      "ExternalTypedData_Int8Array_new";
}


class _ExternalUint8Array extends _TypedList implements Uint8List {
  // Factory constructors.

  factory _ExternalUint8Array(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getUint8(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setUint8(index, _toUint8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Uint8List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Uint8List _createList(int length) {
    return new Uint8List(length);
  }

  static _ExternalUint8Array _new(int length) native
      "ExternalTypedData_Uint8Array_new";
}


class _ExternalUint8ClampedArray extends _TypedList implements Uint8ClampedList {
  // Factory constructors.

  factory _ExternalUint8ClampedArray(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getUint8(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setUint8(index, _toClampedUint8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Uint8List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Uint8ClampedList _createList(int length) {
    return new Uint8ClampedList(length);
  }

  static _ExternalUint8ClampedArray _new(int length) native
      "ExternalTypedData_Uint8ClampedArray_new";
}


class _ExternalInt16Array extends _TypedList implements Int16List {
  // Factory constructors.

  factory _ExternalInt16Array(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedInt16(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedInt16(index, _toInt16(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Int16List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Int16List _createList(int length) {
    return new Int16List(length);
  }

  int _getIndexedInt16(int index) {
    return _getInt16(index * Int16List.BYTES_PER_ELEMENT);
  }

  void _setIndexedInt16(int index, int value) {
    _setInt16(index * Int16List.BYTES_PER_ELEMENT, value);
  }

  static _ExternalInt16Array _new(int length) native
      "ExternalTypedData_Int16Array_new";
}


class _ExternalUint16Array extends _TypedList implements Uint16List {
  // Factory constructors.

  factory _ExternalUint16Array(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedUint16(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedUint16(index, _toUint16(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Uint16List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Uint16List _createList(int length) {
    return new Uint16List(length);
  }

  int _getIndexedUint16(int index) {
    return _getUint16(index * Uint16List.BYTES_PER_ELEMENT);
  }

  void _setIndexedUint16(int index, int value) {
    _setUint16(index * Uint16List.BYTES_PER_ELEMENT, value);
  }

  static _ExternalUint16Array _new(int length) native
      "ExternalTypedData_Uint16Array_new";
}


class _ExternalInt32Array extends _TypedList implements Int32List {
  // Factory constructors.

  factory _ExternalInt32Array(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedInt32(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedInt32(index, _toInt32(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Int32List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Int32List _createList(int length) {
    return new Int32List(length);
  }

  int _getIndexedInt32(int index) {
    return _getInt32(index * Int32List.BYTES_PER_ELEMENT);
  }

  void _setIndexedInt32(int index, int value) {
    _setInt32(index * Int32List.BYTES_PER_ELEMENT, value);
  }

  static _ExternalInt32Array _new(int length) native
      "ExternalTypedData_Int32Array_new";
}


class _ExternalUint32Array extends _TypedList implements Uint32List {
  // Factory constructors.

  factory _ExternalUint32Array(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedUint32(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedUint32(index, _toUint32(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Uint32List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Uint32List _createList(int length) {
    return new Uint32List(length);
  }

  int _getIndexedUint32(int index) {
    return _getUint32(index * Uint32List.BYTES_PER_ELEMENT);
  }

  void _setIndexedUint32(int index, int value) {
    _setInt32(index * Uint32List.BYTES_PER_ELEMENT, value);
  }

  static _ExternalUint32Array _new(int length) native
      "ExternalTypedData_Uint32Array_new";
}


class _ExternalInt64Array extends _TypedList implements Int64List {
  // Factory constructors.

  factory _ExternalInt64Array(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedInt64(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedInt64(index, _toInt64(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Int64List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Int64List _createList(int length) {
    return new Int64List(length);
  }

  int _getIndexedInt64(int index) {
    return _getInt64(index * Int64List.BYTES_PER_ELEMENT);
  }

  void _setIndexedInt64(int index, int value) {
    _setInt64(index * Int64List.BYTES_PER_ELEMENT, value);
  }

  static _ExternalInt64Array _new(int length) native
      "ExternalTypedData_Int64Array_new";
}


class _ExternalUint64Array extends _TypedList implements Uint64List {
  // Factory constructors.

  factory _ExternalUint64Array(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedUint64(index);
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedUint64(index, _toUint64(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Uint64List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Uint64List _createList(int length) {
    return new Uint64List(length);
  }

  int _getIndexedUint64(int index) {
    return _getUint64(index * Uint64List.BYTES_PER_ELEMENT);
  }

  void _setIndexedUint64(int index, int value) {
    _setUint64(index * Uint64List.BYTES_PER_ELEMENT, value);
  }

  static _ExternalUint64Array _new(int length) native
      "ExternalTypedData_Uint64Array_new";
}


class _ExternalFloat32Array extends _TypedList implements Float32List {
  // Factory constructors.

  factory _ExternalFloat32Array(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.

  double operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedFloat32(index);
  }

  void operator[]=(int index, double value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedFloat32(index, value);
  }

  Iterator<double> get iterator {
    return new _TypedListIterator<double>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Float32List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Float32List _createList(int length) {
    return new Float32List(length);
  }

  double _getIndexedFloat32(int index) {
    return _getFloat32(index * Float32List.BYTES_PER_ELEMENT);
  }

  void _setIndexedFloat32(int index, double value) {
    _setFloat32(index * Float32List.BYTES_PER_ELEMENT, value);
  }

  static _ExternalFloat32Array _new(int length) native
      "ExternalTypedData_Float32Array_new";
}


class _ExternalFloat64Array extends _TypedList implements Float64List {
  // Factory constructors.

  factory _ExternalFloat64Array(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.

  double operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedFloat64(index);
  }

  void operator[]=(int index, double value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedFloat64(index, value);
  }

  Iterator<double> get iterator {
    return new _TypedListIterator<double>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Float64List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Float64List _createList(int length) {
    return new Float64List(length);
  }

  double _getIndexedFloat64(int index) {
    return _getFloat64(index * Float64List.BYTES_PER_ELEMENT);
  }

  void _setIndexedFloat64(int index, double value) {
    _setFloat64(index * Float64List.BYTES_PER_ELEMENT, value);
  }

  static _ExternalFloat64Array _new(int length) native
      "ExternalTypedData_Float64Array_new";
}


class _ExternalFloat32x4Array extends _TypedList implements Float32x4List {
  // Factory constructors.

  factory _ExternalFloat32x4Array(int length) {
    return _new(length);
  }


  // Method(s) implementing the List interface.

  Float32x4 operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _getIndexedFloat32x4(index);
  }

  void operator[]=(int index, Float32x4 value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _setIndexedFloat32x4(index, value);
  }

  Iterator<Float32x4> get iterator {
    return new _TypedListIterator<Float32x4>(this);
  }


  // Method(s) implementing the TypedData interface.

  int get elementSizeInBytes {
    return Float32x4List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Float32x4List _createList(int length) {
    return new Float32x4List(length);
  }

  Float32x4 _getIndexedFloat32x4(int index) {
    return _getFloat32x4(index * Float32x4List.BYTES_PER_ELEMENT);
  }

  void _setIndexedFloat32x4(int index, Float32x4 value) {
    _setFloat32x4(index * Float32x4List.BYTES_PER_ELEMENT, value);
  }

  static _ExternalFloat32x4Array _new(int length) native
      "ExternalTypedData_Float32x4Array_new";
}


class _Float32x4 implements Float32x4 {
  factory _Float32x4(double x, double y, double z, double w)
      native "Float32x4_fromDoubles";
  factory _Float32x4.splat(double v) native "Float32x4_splat";
  factory _Float32x4.zero() native "Float32x4_zero";
  Float32x4 operator +(Float32x4 other) {
    return _add(other);
  }
  Float32x4 _add(Float32x4 other) native "Float32x4_add";
  Float32x4 operator -() {
    return _negate();
  }
  Float32x4 _negate() native "Float32x4_negate";
  Float32x4 operator -(Float32x4 other) {
    return _sub(other);
  }
  Float32x4 _sub(Float32x4 other) native "Float32x4_sub";
  Float32x4 operator *(Float32x4 other) {
    return _mul(other);
  }
  Float32x4 _mul(Float32x4 other) native "Float32x4_mul";
  Float32x4 operator /(Float32x4 other) {
    return _div(other);
  }
  Float32x4 _div(Float32x4 other) native "Float32x4_div";
  Uint32x4 lessThan(Float32x4 other) {
    return _cmplt(other);
  }
  Uint32x4 _cmplt(Float32x4 other) native "Float32x4_cmplt";
  Uint32x4 lessThanOrEqual(Float32x4 other) {
    return _cmplte(other);
  }
  Uint32x4 _cmplte(Float32x4 other) native "Float32x4_cmplte";
  Uint32x4 greaterThan(Float32x4 other) {
    return _cmpgt(other);
  }
  Uint32x4 _cmpgt(Float32x4 other) native "Float32x4_cmpgt";
  Uint32x4 greaterThanOrEqual(Float32x4 other) {
    return _cmpgte(other);
  }
  Uint32x4 _cmpgte(Float32x4 other) native "Float32x4_cmpgte";
  Uint32x4 equal(Float32x4 other) {
    return _cmpequal(other);
  }
  Uint32x4 _cmpequal(Float32x4 other)
      native "Float32x4_cmpequal";
  Uint32x4 notEqual(Float32x4 other) {
    return _cmpnequal(other);
  }
  Uint32x4 _cmpnequal(Float32x4 other)
      native "Float32x4_cmpnequal";
  Float32x4 scale(double s) {
    return _scale(s);
  }
  Float32x4 _scale(double s) native "Float32x4_scale";
  Float32x4 abs() {
    return _abs();
  }
  Float32x4 _abs() native "Float32x4_abs";
  Float32x4 clamp(Float32x4 lowerLimit,
                         Float32x4 upperLimit) {
    return _clamp(lowerLimit, upperLimit);
  }
  Float32x4 _clamp(Float32x4 lowerLimit,
                          Float32x4 upperLimit)
      native "Float32x4_clamp";
  double get x native "Float32x4_getX";
  double get y native "Float32x4_getY";
  double get z native "Float32x4_getZ";
  double get w native "Float32x4_getW";
  Float32x4 get xxxx => _shuffle(0x0);
  Float32x4 get xxxy => _shuffle(0x40);
  Float32x4 get xxxz => _shuffle(0x80);
  Float32x4 get xxxw => _shuffle(0xC0);
  Float32x4 get xxyx => _shuffle(0x10);
  Float32x4 get xxyy => _shuffle(0x50);
  Float32x4 get xxyz => _shuffle(0x90);
  Float32x4 get xxyw => _shuffle(0xD0);
  Float32x4 get xxzx => _shuffle(0x20);
  Float32x4 get xxzy => _shuffle(0x60);
  Float32x4 get xxzz => _shuffle(0xA0);
  Float32x4 get xxzw => _shuffle(0xE0);
  Float32x4 get xxwx => _shuffle(0x30);
  Float32x4 get xxwy => _shuffle(0x70);
  Float32x4 get xxwz => _shuffle(0xB0);
  Float32x4 get xxww => _shuffle(0xF0);
  Float32x4 get xyxx => _shuffle(0x4);
  Float32x4 get xyxy => _shuffle(0x44);
  Float32x4 get xyxz => _shuffle(0x84);
  Float32x4 get xyxw => _shuffle(0xC4);
  Float32x4 get xyyx => _shuffle(0x14);
  Float32x4 get xyyy => _shuffle(0x54);
  Float32x4 get xyyz => _shuffle(0x94);
  Float32x4 get xyyw => _shuffle(0xD4);
  Float32x4 get xyzx => _shuffle(0x24);
  Float32x4 get xyzy => _shuffle(0x64);
  Float32x4 get xyzz => _shuffle(0xA4);
  Float32x4 get xyzw => _shuffle(0xE4);
  Float32x4 get xywx => _shuffle(0x34);
  Float32x4 get xywy => _shuffle(0x74);
  Float32x4 get xywz => _shuffle(0xB4);
  Float32x4 get xyww => _shuffle(0xF4);
  Float32x4 get xzxx => _shuffle(0x8);
  Float32x4 get xzxy => _shuffle(0x48);
  Float32x4 get xzxz => _shuffle(0x88);
  Float32x4 get xzxw => _shuffle(0xC8);
  Float32x4 get xzyx => _shuffle(0x18);
  Float32x4 get xzyy => _shuffle(0x58);
  Float32x4 get xzyz => _shuffle(0x98);
  Float32x4 get xzyw => _shuffle(0xD8);
  Float32x4 get xzzx => _shuffle(0x28);
  Float32x4 get xzzy => _shuffle(0x68);
  Float32x4 get xzzz => _shuffle(0xA8);
  Float32x4 get xzzw => _shuffle(0xE8);
  Float32x4 get xzwx => _shuffle(0x38);
  Float32x4 get xzwy => _shuffle(0x78);
  Float32x4 get xzwz => _shuffle(0xB8);
  Float32x4 get xzww => _shuffle(0xF8);
  Float32x4 get xwxx => _shuffle(0xC);
  Float32x4 get xwxy => _shuffle(0x4C);
  Float32x4 get xwxz => _shuffle(0x8C);
  Float32x4 get xwxw => _shuffle(0xCC);
  Float32x4 get xwyx => _shuffle(0x1C);
  Float32x4 get xwyy => _shuffle(0x5C);
  Float32x4 get xwyz => _shuffle(0x9C);
  Float32x4 get xwyw => _shuffle(0xDC);
  Float32x4 get xwzx => _shuffle(0x2C);
  Float32x4 get xwzy => _shuffle(0x6C);
  Float32x4 get xwzz => _shuffle(0xAC);
  Float32x4 get xwzw => _shuffle(0xEC);
  Float32x4 get xwwx => _shuffle(0x3C);
  Float32x4 get xwwy => _shuffle(0x7C);
  Float32x4 get xwwz => _shuffle(0xBC);
  Float32x4 get xwww => _shuffle(0xFC);
  Float32x4 get yxxx => _shuffle(0x1);
  Float32x4 get yxxy => _shuffle(0x41);
  Float32x4 get yxxz => _shuffle(0x81);
  Float32x4 get yxxw => _shuffle(0xC1);
  Float32x4 get yxyx => _shuffle(0x11);
  Float32x4 get yxyy => _shuffle(0x51);
  Float32x4 get yxyz => _shuffle(0x91);
  Float32x4 get yxyw => _shuffle(0xD1);
  Float32x4 get yxzx => _shuffle(0x21);
  Float32x4 get yxzy => _shuffle(0x61);
  Float32x4 get yxzz => _shuffle(0xA1);
  Float32x4 get yxzw => _shuffle(0xE1);
  Float32x4 get yxwx => _shuffle(0x31);
  Float32x4 get yxwy => _shuffle(0x71);
  Float32x4 get yxwz => _shuffle(0xB1);
  Float32x4 get yxww => _shuffle(0xF1);
  Float32x4 get yyxx => _shuffle(0x5);
  Float32x4 get yyxy => _shuffle(0x45);
  Float32x4 get yyxz => _shuffle(0x85);
  Float32x4 get yyxw => _shuffle(0xC5);
  Float32x4 get yyyx => _shuffle(0x15);
  Float32x4 get yyyy => _shuffle(0x55);
  Float32x4 get yyyz => _shuffle(0x95);
  Float32x4 get yyyw => _shuffle(0xD5);
  Float32x4 get yyzx => _shuffle(0x25);
  Float32x4 get yyzy => _shuffle(0x65);
  Float32x4 get yyzz => _shuffle(0xA5);
  Float32x4 get yyzw => _shuffle(0xE5);
  Float32x4 get yywx => _shuffle(0x35);
  Float32x4 get yywy => _shuffle(0x75);
  Float32x4 get yywz => _shuffle(0xB5);
  Float32x4 get yyww => _shuffle(0xF5);
  Float32x4 get yzxx => _shuffle(0x9);
  Float32x4 get yzxy => _shuffle(0x49);
  Float32x4 get yzxz => _shuffle(0x89);
  Float32x4 get yzxw => _shuffle(0xC9);
  Float32x4 get yzyx => _shuffle(0x19);
  Float32x4 get yzyy => _shuffle(0x59);
  Float32x4 get yzyz => _shuffle(0x99);
  Float32x4 get yzyw => _shuffle(0xD9);
  Float32x4 get yzzx => _shuffle(0x29);
  Float32x4 get yzzy => _shuffle(0x69);
  Float32x4 get yzzz => _shuffle(0xA9);
  Float32x4 get yzzw => _shuffle(0xE9);
  Float32x4 get yzwx => _shuffle(0x39);
  Float32x4 get yzwy => _shuffle(0x79);
  Float32x4 get yzwz => _shuffle(0xB9);
  Float32x4 get yzww => _shuffle(0xF9);
  Float32x4 get ywxx => _shuffle(0xD);
  Float32x4 get ywxy => _shuffle(0x4D);
  Float32x4 get ywxz => _shuffle(0x8D);
  Float32x4 get ywxw => _shuffle(0xCD);
  Float32x4 get ywyx => _shuffle(0x1D);
  Float32x4 get ywyy => _shuffle(0x5D);
  Float32x4 get ywyz => _shuffle(0x9D);
  Float32x4 get ywyw => _shuffle(0xDD);
  Float32x4 get ywzx => _shuffle(0x2D);
  Float32x4 get ywzy => _shuffle(0x6D);
  Float32x4 get ywzz => _shuffle(0xAD);
  Float32x4 get ywzw => _shuffle(0xED);
  Float32x4 get ywwx => _shuffle(0x3D);
  Float32x4 get ywwy => _shuffle(0x7D);
  Float32x4 get ywwz => _shuffle(0xBD);
  Float32x4 get ywww => _shuffle(0xFD);
  Float32x4 get zxxx => _shuffle(0x2);
  Float32x4 get zxxy => _shuffle(0x42);
  Float32x4 get zxxz => _shuffle(0x82);
  Float32x4 get zxxw => _shuffle(0xC2);
  Float32x4 get zxyx => _shuffle(0x12);
  Float32x4 get zxyy => _shuffle(0x52);
  Float32x4 get zxyz => _shuffle(0x92);
  Float32x4 get zxyw => _shuffle(0xD2);
  Float32x4 get zxzx => _shuffle(0x22);
  Float32x4 get zxzy => _shuffle(0x62);
  Float32x4 get zxzz => _shuffle(0xA2);
  Float32x4 get zxzw => _shuffle(0xE2);
  Float32x4 get zxwx => _shuffle(0x32);
  Float32x4 get zxwy => _shuffle(0x72);
  Float32x4 get zxwz => _shuffle(0xB2);
  Float32x4 get zxww => _shuffle(0xF2);
  Float32x4 get zyxx => _shuffle(0x6);
  Float32x4 get zyxy => _shuffle(0x46);
  Float32x4 get zyxz => _shuffle(0x86);
  Float32x4 get zyxw => _shuffle(0xC6);
  Float32x4 get zyyx => _shuffle(0x16);
  Float32x4 get zyyy => _shuffle(0x56);
  Float32x4 get zyyz => _shuffle(0x96);
  Float32x4 get zyyw => _shuffle(0xD6);
  Float32x4 get zyzx => _shuffle(0x26);
  Float32x4 get zyzy => _shuffle(0x66);
  Float32x4 get zyzz => _shuffle(0xA6);
  Float32x4 get zyzw => _shuffle(0xE6);
  Float32x4 get zywx => _shuffle(0x36);
  Float32x4 get zywy => _shuffle(0x76);
  Float32x4 get zywz => _shuffle(0xB6);
  Float32x4 get zyww => _shuffle(0xF6);
  Float32x4 get zzxx => _shuffle(0xA);
  Float32x4 get zzxy => _shuffle(0x4A);
  Float32x4 get zzxz => _shuffle(0x8A);
  Float32x4 get zzxw => _shuffle(0xCA);
  Float32x4 get zzyx => _shuffle(0x1A);
  Float32x4 get zzyy => _shuffle(0x5A);
  Float32x4 get zzyz => _shuffle(0x9A);
  Float32x4 get zzyw => _shuffle(0xDA);
  Float32x4 get zzzx => _shuffle(0x2A);
  Float32x4 get zzzy => _shuffle(0x6A);
  Float32x4 get zzzz => _shuffle(0xAA);
  Float32x4 get zzzw => _shuffle(0xEA);
  Float32x4 get zzwx => _shuffle(0x3A);
  Float32x4 get zzwy => _shuffle(0x7A);
  Float32x4 get zzwz => _shuffle(0xBA);
  Float32x4 get zzww => _shuffle(0xFA);
  Float32x4 get zwxx => _shuffle(0xE);
  Float32x4 get zwxy => _shuffle(0x4E);
  Float32x4 get zwxz => _shuffle(0x8E);
  Float32x4 get zwxw => _shuffle(0xCE);
  Float32x4 get zwyx => _shuffle(0x1E);
  Float32x4 get zwyy => _shuffle(0x5E);
  Float32x4 get zwyz => _shuffle(0x9E);
  Float32x4 get zwyw => _shuffle(0xDE);
  Float32x4 get zwzx => _shuffle(0x2E);
  Float32x4 get zwzy => _shuffle(0x6E);
  Float32x4 get zwzz => _shuffle(0xAE);
  Float32x4 get zwzw => _shuffle(0xEE);
  Float32x4 get zwwx => _shuffle(0x3E);
  Float32x4 get zwwy => _shuffle(0x7E);
  Float32x4 get zwwz => _shuffle(0xBE);
  Float32x4 get zwww => _shuffle(0xFE);
  Float32x4 get wxxx => _shuffle(0x3);
  Float32x4 get wxxy => _shuffle(0x43);
  Float32x4 get wxxz => _shuffle(0x83);
  Float32x4 get wxxw => _shuffle(0xC3);
  Float32x4 get wxyx => _shuffle(0x13);
  Float32x4 get wxyy => _shuffle(0x53);
  Float32x4 get wxyz => _shuffle(0x93);
  Float32x4 get wxyw => _shuffle(0xD3);
  Float32x4 get wxzx => _shuffle(0x23);
  Float32x4 get wxzy => _shuffle(0x63);
  Float32x4 get wxzz => _shuffle(0xA3);
  Float32x4 get wxzw => _shuffle(0xE3);
  Float32x4 get wxwx => _shuffle(0x33);
  Float32x4 get wxwy => _shuffle(0x73);
  Float32x4 get wxwz => _shuffle(0xB3);
  Float32x4 get wxww => _shuffle(0xF3);
  Float32x4 get wyxx => _shuffle(0x7);
  Float32x4 get wyxy => _shuffle(0x47);
  Float32x4 get wyxz => _shuffle(0x87);
  Float32x4 get wyxw => _shuffle(0xC7);
  Float32x4 get wyyx => _shuffle(0x17);
  Float32x4 get wyyy => _shuffle(0x57);
  Float32x4 get wyyz => _shuffle(0x97);
  Float32x4 get wyyw => _shuffle(0xD7);
  Float32x4 get wyzx => _shuffle(0x27);
  Float32x4 get wyzy => _shuffle(0x67);
  Float32x4 get wyzz => _shuffle(0xA7);
  Float32x4 get wyzw => _shuffle(0xE7);
  Float32x4 get wywx => _shuffle(0x37);
  Float32x4 get wywy => _shuffle(0x77);
  Float32x4 get wywz => _shuffle(0xB7);
  Float32x4 get wyww => _shuffle(0xF7);
  Float32x4 get wzxx => _shuffle(0xB);
  Float32x4 get wzxy => _shuffle(0x4B);
  Float32x4 get wzxz => _shuffle(0x8B);
  Float32x4 get wzxw => _shuffle(0xCB);
  Float32x4 get wzyx => _shuffle(0x1B);
  Float32x4 get wzyy => _shuffle(0x5B);
  Float32x4 get wzyz => _shuffle(0x9B);
  Float32x4 get wzyw => _shuffle(0xDB);
  Float32x4 get wzzx => _shuffle(0x2B);
  Float32x4 get wzzy => _shuffle(0x6B);
  Float32x4 get wzzz => _shuffle(0xAB);
  Float32x4 get wzzw => _shuffle(0xEB);
  Float32x4 get wzwx => _shuffle(0x3B);
  Float32x4 get wzwy => _shuffle(0x7B);
  Float32x4 get wzwz => _shuffle(0xBB);
  Float32x4 get wzww => _shuffle(0xFB);
  Float32x4 get wwxx => _shuffle(0xF);
  Float32x4 get wwxy => _shuffle(0x4F);
  Float32x4 get wwxz => _shuffle(0x8F);
  Float32x4 get wwxw => _shuffle(0xCF);
  Float32x4 get wwyx => _shuffle(0x1F);
  Float32x4 get wwyy => _shuffle(0x5F);
  Float32x4 get wwyz => _shuffle(0x9F);
  Float32x4 get wwyw => _shuffle(0xDF);
  Float32x4 get wwzx => _shuffle(0x2F);
  Float32x4 get wwzy => _shuffle(0x6F);
  Float32x4 get wwzz => _shuffle(0xAF);
  Float32x4 get wwzw => _shuffle(0xEF);
  Float32x4 get wwwx => _shuffle(0x3F);
  Float32x4 get wwwy => _shuffle(0x7F);
  Float32x4 get wwwz => _shuffle(0xBF);
  Float32x4 get wwww => _shuffle(0xFF);
  Float32x4 _shuffle(int mask) native "Float32x4_shuffle";

  Float32x4 withZWInXY(Float32x4 other) native "Float32x4_withZWInXY";
  Float32x4 interleaveXY(Float32x4 other) native "Float32x4_interleaveXY";
  Float32x4 interleaveZW(Float32x4 other) native "Float32x4_interleaveZW";
  Float32x4 interleaveXYPairs(Float32x4 other)
      native "Float32x4_interleaveXYPairs";
  Float32x4 interleaveZWPairs(Float32x4 other)
      native "Float32x4_interleaveZWPairs";

  Float32x4 withX(double x) native "Float32x4_setX";
  Float32x4 withY(double y) native "Float32x4_setY";
  Float32x4 withZ(double z) native "Float32x4_setZ";
  Float32x4 withW(double w) native "Float32x4_setW";
  Float32x4 min(Float32x4 other) {
    return _min(other);
  }
  Float32x4 _min(Float32x4 other) native "Float32x4_min";
  Float32x4 max(Float32x4 other) {
    return _max(other);
  }
  Float32x4 _max(Float32x4 other) native "Float32x4_max";
  Float32x4 sqrt() {
    return _sqrt();
  }
  Float32x4 _sqrt() native "Float32x4_sqrt";
  Float32x4 reciprocal() {
    return _reciprocal();
  }
  Float32x4 _reciprocal() native "Float32x4_reciprocal";
  Float32x4 reciprocalSqrt() {
    return _reciprocalSqrt();
  }
  Float32x4 _reciprocalSqrt() native "Float32x4_reciprocalSqrt";
  Uint32x4 toUint32x4() {
      return _toUint32x4();
  }
  Uint32x4 _toUint32x4() native "Float32x4_toUint32x4";
}


class _Uint32x4 implements Uint32x4 {
  factory _Uint32x4(int x, int y, int z, int w)
      native "Uint32x4_fromInts";
  factory _Uint32x4.bool(bool x, bool y, bool z, bool w)
      native "Uint32x4_fromBools";
  Uint32x4 operator |(Uint32x4 other) {
    return _or(other);
  }
  Uint32x4 _or(Uint32x4 other) native "Uint32x4_or";
  Uint32x4 operator &(Uint32x4 other) {
    return _and(other);
  }
  Uint32x4 _and(Uint32x4 other) native "Uint32x4_and";
  Uint32x4 operator ^(Uint32x4 other) {
    return _xor(other);
  }
  Uint32x4 _xor(Uint32x4 other) native "Uint32x4_xor";
  int get x native "Uint32x4_getX";
  int get y native "Uint32x4_getY";
  int get z native "Uint32x4_getZ";
  int get w native "Uint32x4_getW";
  Uint32x4 withX(int x) native "Uint32x4_setX";
  Uint32x4 withY(int y) native "Uint32x4_setY";
  Uint32x4 withZ(int z) native "Uint32x4_setZ";
  Uint32x4 withW(int w) native "Uint32x4_setW";
  bool get flagX native "Uint32x4_getFlagX";
  bool get flagY native "Uint32x4_getFlagY";
  bool get flagZ native "Uint32x4_getFlagZ";
  bool get flagW native "Uint32x4_getFlagW";
  Uint32x4 withFlagX(bool x) native "Uint32x4_setFlagX";
  Uint32x4 withFlagY(bool y) native "Uint32x4_setFlagY";
  Uint32x4 withFlagZ(bool z) native "Uint32x4_setFlagZ";
  Uint32x4 withFlagW(bool w) native "Uint32x4_setFlagW";
  Float32x4 select(Float32x4 trueValue,
                          Float32x4 falseValue) {
    return _select(trueValue, falseValue);
  }
  Float32x4 _select(Float32x4 trueValue,
                           Float32x4 falseValue)
      native "Uint32x4_select";
  Float32x4 toFloat32x4() {
      return _toFloat32x4();
  }
  Float32x4 _toFloat32x4() native "Uint32x4_toFloat32x4";
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
    : _typedData = _buffer,  // This assignment is type safe.
      offsetInBytes = _offset,
      length = _length {
  }


  // Method(s) implementing the TypedData interface.

  int get lengthInBytes {
    return length * elementSizeInBytes;
  }

  ByteBuffer get buffer {
    return _typedData.buffer;
  }

  final TypedData _typedData;
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
                _offsetInBytes,
                length * Int8List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _typedData._getInt8(offsetInBytes +
                               (index * Int8List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setInt8(offsetInBytes + (index * Int8List.BYTES_PER_ELEMENT),
                        _toInt8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Int8List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Int8List _createList(int length) {
    return new Int8List(length);
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
                _offsetInBytes,
                length * Uint8List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  int operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _typedData._getUint8(offsetInBytes +
                                (index * Uint8List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setUint8(offsetInBytes + (index * Uint8List.BYTES_PER_ELEMENT),
                         _toUint8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Uint8List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Uint8List _createList(int length) {
    return new Uint8List(length);
  }
}


class _Uint8ClampedArrayView extends _TypedListView implements Uint8ClampedList {
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
      _throwRangeError(index, length);
    }
    return _typedData._getUint8(offsetInBytes +
                                (index * Uint8List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setUint8(offsetInBytes + (index * Uint8List.BYTES_PER_ELEMENT),
                         _toClampedUint8(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Uint8List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Uint8ClampedList _createList(int length) {
    return new Uint8ClampedList(length);
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
      _throwRangeError(index, length);
    }
    return _typedData._getInt16(offsetInBytes +
                                (index * Int16List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setInt16(offsetInBytes + (index * Int16List.BYTES_PER_ELEMENT),
                         _toInt16(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Int16List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Int16List _createList(int length) {
    return new Int16List(length);
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
      _throwRangeError(index, length);
    }
    return _typedData._getUint16(offsetInBytes +
                                 (index * Uint16List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setUint16(offsetInBytes + (index * Uint16List.BYTES_PER_ELEMENT),
                          _toUint16(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Uint16List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Uint16List _createList(int length) {
    return new Uint16List(length);
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
      _throwRangeError(index, length);
    }
    return _typedData._getInt32(offsetInBytes +
                                (index * Int32List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setInt32(offsetInBytes + (index * Int32List.BYTES_PER_ELEMENT),
                         _toInt32(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Int32List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Int32List _createList(int length) {
    return new Int32List(length);
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
      _throwRangeError(index, length);
    }
    return _typedData._getUint32(offsetInBytes +
                                 (index * Uint32List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setUint32(offsetInBytes + (index * Uint32List.BYTES_PER_ELEMENT),
                          _toUint32(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Uint32List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Uint32List _createList(int length) {
    return new Uint32List(length);
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
      _throwRangeError(index, length);
    }
    return _typedData._getInt64(offsetInBytes +
                                (index * Int64List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setInt64(offsetInBytes + (index * Int64List.BYTES_PER_ELEMENT),
                         _toInt64(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Int64List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Int64List _createList(int length) {
    return new Int64List(length);
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
      _throwRangeError(index, length);
    }
    return _typedData._getUint64(offsetInBytes +
                                 (index * Uint64List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, int value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setUint64(offsetInBytes + (index * Uint64List.BYTES_PER_ELEMENT),
                          _toUint64(value));
  }

  Iterator<int> get iterator {
    return new _TypedListIterator<int>(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Uint64List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Uint64List _createList(int length) {
    return new Uint64List(length);
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
      _throwRangeError(index, length);
    }
    return _typedData._getFloat32(offsetInBytes +
                                  (index * Float32List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, double value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setFloat32(offsetInBytes +
                           (index * Float32List.BYTES_PER_ELEMENT), value);
  }

  Iterator<double> get iterator {
    return new _TypedListIterator<double>(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Float32List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Float32List _createList(int length) {
    return new Float32List(length);
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
      _throwRangeError(index, length);
    }
    return _typedData._getFloat64(offsetInBytes +
                                  (index * Float64List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, double value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setFloat64(offsetInBytes +
                          (index * Float64List.BYTES_PER_ELEMENT), value);
  }

  Iterator<double> get iterator {
    return new _TypedListIterator<double>(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Float64List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Float64List _createList(int length) {
    return new Float64List(length);
  }
}


class _Float32x4ArrayView extends _TypedListView implements Float32x4List {
  // Constructor.
  _Float32x4ArrayView(ByteBuffer buffer, [int _offsetInBytes = 0, int _length])
    : super(buffer, _offsetInBytes,
            _defaultIfNull(_length,
                           ((buffer.lengthInBytes - _offsetInBytes) ~/
                            Float32x4List.BYTES_PER_ELEMENT))) {
    _rangeCheck(buffer.lengthInBytes,
                offsetInBytes,
                length * Float32x4List.BYTES_PER_ELEMENT);
  }


  // Method(s) implementing List interface.

  Float32x4 operator[](int index) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    return _typedData._getFloat32x4(offsetInBytes +
                                  (index * Float32x4List.BYTES_PER_ELEMENT));
  }

  void operator[]=(int index, Float32x4 value) {
    if (index < 0 || index >= length) {
      _throwRangeError(index, length);
    }
    _typedData._setFloat32x4(offsetInBytes +
                             (index * Float32x4List.BYTES_PER_ELEMENT), value);
  }

  Iterator<Float32x4> get iterator {
    return new _TypedListIterator<Float32x4>(this);
  }


  // Method(s) implementing TypedData interface.

  int get elementSizeInBytes {
    return Float32x4List.BYTES_PER_ELEMENT;
  }


  // Internal utility methods.

  Float32x4List _createList(int length) {
    return new Float32x4List(length);
  }
}


class _ByteDataView implements ByteData {
  _ByteDataView(ByteBuffer _buffer, int _offsetInBytes, int _lengthInBytes)
    : _typedData = _buffer,  // _buffer is guaranteed to be a TypedData here.
      _offset = _offsetInBytes,
      length = _lengthInBytes {
    _rangeCheck(_buffer.lengthInBytes, _offset, length);
  }


  // Method(s) implementing TypedData interface.

  ByteBuffer get buffer {
    return _typedData.buffer;
  }

  int get lengthInBytes {
    return length;
  }

  int get offsetInBytes {
    return _offset;
  }

  // Method(s) implementing ByteData interface.

  int getInt8(int byteOffset) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    return _typedData._getInt8(_offset + byteOffset);
  }
  void setInt8(int byteOffset, int value) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    _typedData._setInt8(_offset + byteOffset, _toInt8(value));
  }

  int getUint8(int byteOffset) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    return _typedData._getUint8(_offset + byteOffset);
  }
  void setUint8(int byteOffset, int value) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    _typedData._setUint8(_offset + byteOffset, _toUint8(value));
  }

  int getInt16(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    var result = _typedData._getInt16(_offset + byteOffset);
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      return result;
    }
    return _toEndianInt16(result, endian._littleEndian);
  }
  void setInt16(int byteOffset,
                int value,
                [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    var set_value = _toInt16(value);
    if (!identical(endian, Endianness.HOST_ENDIAN)) {
      set_value = _toEndianInt16(set_value, endian._littleEndian);
    }
    _typedData._setInt16(_offset + byteOffset, set_value);
  }

  int getUint16(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    var result = _typedData._getUint16(_offset + byteOffset);
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      return result;
    }
    return _toEndianUint16(result, endian._littleEndian);
  }
  void setUint16(int byteOffset,
                 int value,
                 [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    var set_value = _toUint16(value);
    if (!identical(endian, Endianness.HOST_ENDIAN)) {
      set_value = _toEndianUint16(set_value, endian._littleEndian);
    }
    _typedData._setUint16(_offset + byteOffset, set_value);
  }

  int getInt32(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    var result = _typedData._getInt32(_offset + byteOffset);
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      return result;
    }
    return _toEndianInt32(result, endian._littleEndian);
  }
  void setInt32(int byteOffset,
                int value,
                [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    var set_value = _toInt32(value);
    if (!identical(endian, Endianness.HOST_ENDIAN)) {
      set_value = _toEndianInt32(set_value, endian._littleEndian);
    }
    _typedData._setInt32(_offset + byteOffset, set_value);
  }

  int getUint32(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    var result = _typedData._getUint32(_offset + byteOffset);
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      return result;
    }
    return _toEndianUint32(result, endian._littleEndian);
  }
  void setUint32(int byteOffset,
                 int value,
                 [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    var set_value = _toUint32(value);
    if (!identical(endian, Endianness.HOST_ENDIAN)) {
      set_value = _toEndianUint32(set_value, endian._littleEndian);
    }
    _typedData._setUint32(_offset + byteOffset, set_value);
  }

  int getInt64(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    var result = _typedData._getInt64(_offset + byteOffset);
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      return result;
    }
    return _toEndianInt64(result, endian._littleEndian);
  }
  void setInt64(int byteOffset,
                int value,
                [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    var set_value = _toInt64(value);
    if (!identical(endian, Endianness.HOST_ENDIAN)) {
      set_value = _toEndianInt64(set_value, endian._littleEndian);
    }
    _typedData._setInt64(_offset + byteOffset, set_value);
  }

  int getUint64(int byteOffset, [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    var result = _typedData._getUint64(_offset + byteOffset);
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      return result;
    }
    return _toEndianUint64(result, endian._littleEndian);
  }
  void setUint64(int byteOffset,
                 int value,
                 [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    var set_value = _toUint64(value);
    if (!identical(endian, Endianness.HOST_ENDIAN)) {
      set_value = _toEndianUint64(set_value, endian._littleEndian);
    }
    _typedData._setUint64(_offset + byteOffset, set_value);
  }

  double getFloat32(int byteOffset,
                    [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    var result = _typedData._getFloat32(_offset + byteOffset);
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      return result;
    }
    return _toEndianFloat32(result, endian._littleEndian);
  }
  void setFloat32(int byteOffset,
                  double value,
                  [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    var set_value = value;
    if (!identical(endian, Endianness.HOST_ENDIAN)) {
      set_value = _toEndianFloat32(set_value, endian._littleEndian);
    }
    _typedData._setFloat32(_offset + byteOffset, set_value);
  }

  double getFloat64(int byteOffset,
                    [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    var result = _typedData._getFloat64(_offset + byteOffset);
    if (identical(endian, Endianness.HOST_ENDIAN)) {
      return result;
    }
    return _toEndianFloat64(result, endian._littleEndian);
  }
  void setFloat64(int byteOffset,
                  double value,
                  [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    var set_value = value;
    if (!identical(endian, Endianness.HOST_ENDIAN)) {
      set_value = _toEndianFloat64(set_value, endian._littleEndian);
    }
    _typedData._setFloat64(_offset + byteOffset, set_value);
  }

  Float32x4 getFloat32x4(int byteOffset,
                         [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    // TODO(johnmccutchan) : Need to resolve this for endianity.
    return _typedData._getFloat32x4(_offset + byteOffset);
  }
  void setFloat32x4(int byteOffset,
                    Float32x4 value,
                    [Endianness endian = Endianness.BIG_ENDIAN]) {
    if (byteOffset < 0 || byteOffset >= length) {
      _throwRangeError(byteOffset, length);
    }
    // TODO(johnmccutchan) : Need to resolve this for endianity.
    _typedData._setFloat32x4(_offset + byteOffset, value);

  }


  // Internal utility methods.

  static int _toEndianInt16(int host_value, bool little_endian)
      native "ByteData_ToEndianInt16";
  static int _toEndianUint16(int host_value, bool little_endian)
      native "ByteData_ToEndianUint16";
  static int _toEndianInt32(int host_value, bool little_endian)
      native "ByteData_ToEndianInt32";
  static int _toEndianUint32(int host_value, bool little_endian)
      native "ByteData_ToEndianUint32";
  static int _toEndianInt64(int host_value, bool little_endian)
      native "ByteData_ToEndianInt64";
  static int _toEndianUint64(int host_value, bool little_endian)
      native "ByteData_ToEndianUint64";
  static double _toEndianFloat32(double host_value, bool little_endian)
      native "ByteData_ToEndianFloat32";
  static double _toEndianFloat64(double host_value, bool little_endian)
      native "ByteData_ToEndianFloat64";


  final TypedData _typedData;
  final int _offset;
  final int length;
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
  return object;
}


void _throwRangeError(int index, int length) {
  String message = "$index must be in the range [0..$length)";
  throw new RangeError(message);
}
