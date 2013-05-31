// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The Dart TypedData library.
library dart.typed_data;

import 'dart:collection';
import 'dart:_collection-dev';
import 'dart:_js_helper' show Creates, JavaScriptIndexingBehavior, JSName, Null, Returns;
import 'dart:_foreign_helper' show JS;

// TODO(10691): migrate to ListMixin.
class _Lists {

  /**
   * Returns the index in the array [a] of the given [element], starting
   * the search at index [startIndex] to [endIndex] (exclusive).
   * Returns -1 if [element] is not found.
   */
  static int indexOf(List a,
                     Object element,
                     int startIndex,
                     int endIndex) {
    if (startIndex >= a.length) {
      return -1;
    }
    if (startIndex < 0) {
      startIndex = 0;
    }
    for (int i = startIndex; i < endIndex; i++) {
      if (a[i] == element) {
        return i;
      }
    }
    return -1;
  }

  /**
   * Returns the last index in the array [a] of the given [element], starting
   * the search at index [startIndex] to 0.
   * Returns -1 if [element] is not found.
   */
  static int lastIndexOf(List a, Object element, int startIndex) {
    if (startIndex < 0) {
      return -1;
    }
    if (startIndex >= a.length) {
      startIndex = a.length - 1;
    }
    for (int i = startIndex; i >= 0; i--) {
      if (a[i] == element) {
        return i;
      }
    }
    return -1;
  }

  /**
   * Returns a sub list copy of this list, from [start] to
   * [end] ([end] not inclusive).
   * Returns an empty list if [length] is 0.
   * It is an error if indices are not valid for the list, or
   * if [end] is before [start].
   */
  static List getRange(List a, int start, int end, List accumulator) {
    if (start < 0) throw new RangeError.value(start);
    if (end < start) throw new RangeError.value(end);
    if (end > a.length) throw new RangeError.value(end);
    for (int i = start; i < end; i++) {
      accumulator.add(a[i]);
    }
    return accumulator;
  }
}
/**
 * Describes endianness to be used when accessing a sequence of bytes.
 */
class Endianness {
  const Endianness(this._littleEndian);

  static const Endianness BIG_ENDIAN = const Endianness(false);
  static const Endianness LITTLE_ENDIAN = const Endianness(true);
  static final Endianness HOST_ENDIAN =
    (new ByteData.view(new Int16List.fromList([1]).buffer)).getInt8(0) == 1 ?
    LITTLE_ENDIAN : BIG_ENDIAN;

  final bool _littleEndian;
}

class ByteBuffer native "ArrayBuffer" {
  @JSName('byteLength')
  final int lengthInBytes;
}

class TypedData native "ArrayBufferView" {
  @Creates('ByteBuffer')
  @Returns('ByteBuffer|Null')
  final ByteBuffer buffer;

  @JSName('byteLength')
  final int lengthInBytes;

  @JSName('byteOffset')
  final int offsetInBytes;

  @JSName('BYTES_PER_ELEMENT')
  final int elementSizeInBytes;

  void _invalidIndex(int index, int length) {
    if (index < 0 || index >= length) {
      throw new RangeError.range(index, 0, length);
    } else {
      throw new ArgumentError('Invalid list index $index');
    }
  }

  void _checkBounds(int index, int length) {
    if (JS('bool', '(# >>> 0 != #)', index, index) || index >= length) {
      _invalidIndex(index, length);
    }
  }
}

class ByteData extends TypedData native "DataView" {
  factory ByteData(int length) =>
      _TypedArrayFactoryProvider.createByteData(length);

  factory ByteData.view(ByteBuffer buffer, [int byteOffset, int byteLength]) =>
      _TypedArrayFactoryProvider.createByteData_fromBuffer(
          buffer, byteOffset, byteLength);

  num getFloat32(int byteOffset, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _getFloat32(byteOffset, endian._littleEndian);

  @JSName('getFloat32')
  @Returns('num')
  num _getFloat32(int byteOffset, [bool littleEndian]) native;

  num getFloat64(int byteOffset, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _getFloat64(byteOffset, endian._littleEndian);

  @JSName('getFloat64')
  @Returns('num')
  num _getFloat64(int byteOffset, [bool littleEndian]) native;

  int getInt16(int byteOffset, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _getInt16(byteOffset, endian._littleEndian);

  @JSName('getInt16')
  @Returns('int')
  int _getInt16(int byteOffset, [bool littleEndian]) native;

  int getInt32(int byteOffset, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _getInt32(byteOffset, endian._littleEndian);

  @JSName('getInt32')
  @Returns('int')
  int _getInt32(int byteOffset, [bool littleEndian]) native;

  int getInt64(int byteOffset, [Endianness endian=Endianness.BIG_ENDIAN]) {
    throw new UnsupportedError("Int64 accessor not supported by dart2js.");
  }

  int getInt8(int byteOffset) native;

  int getUint16(int byteOffset, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _getUint16(byteOffset, endian._littleEndian);

  @JSName('getUint16')
  @Returns('int')
  int _getUint16(int byteOffset, [bool littleEndian]) native;

  int getUint32(int byteOffset, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _getUint32(byteOffset, endian._littleEndian);

  @JSName('getUint32')
  @Returns('int')
  int _getUint32(int byteOffset, [bool littleEndian]) native;

  int getUint64(int byteOffset, [Endianness endian=Endianness.BIG_ENDIAN]) {
    throw new UnsupportedError("Uint64 accessor not supported by dart2js.");
  }

  int getUint8(int byteOffset) native;

  void setFloat32(int byteOffset, num value, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _setFloat32(byteOffset, value, endian._littleEndian);

  @JSName('setFloat32')
  void _setFloat32(int byteOffset, num value, [bool littleEndian]) native;

  void setFloat64(int byteOffset, num value, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _setFloat64(byteOffset, value, endian._littleEndian);

  @JSName('setFloat64')
  void _setFloat64(int byteOffset, num value, [bool littleEndian]) native;

  void setInt16(int byteOffset, int value, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _setInt16(byteOffset, value, endian._littleEndian);

  @JSName('setInt16')
  void _setInt16(int byteOffset, int value, [bool littleEndian]) native;

  void setInt32(int byteOffset, int value, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _setInt32(byteOffset, value, endian._littleEndian);

  @JSName('setInt32')
  void _setInt32(int byteOffset, int value, [bool littleEndian]) native;

  void setInt64(int byteOffset, int value, [Endianness endian=Endianness.BIG_ENDIAN]) {
    throw new UnsupportedError("Int64 accessor not supported by dart2js.");
  }

  void setInt8(int byteOffset, int value) native;

  void setUint16(int byteOffset, int value, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _setUint16(byteOffset, value, endian._littleEndian);

  @JSName('setUint16')
  void _setUint16(int byteOffset, int value, [bool littleEndian]) native;

  void setUint32(int byteOffset, int value, [Endianness endian=Endianness.BIG_ENDIAN]) =>
      _setUint32(byteOffset, value, endian._littleEndian);

  @JSName('setUint32')
  void _setUint32(int byteOffset, int value, [bool littleEndian]) native;

  void setUint64(int byteOffset, int value, [Endianness endian=Endianness.BIG_ENDIAN]) {
    throw new UnsupportedError("Uint64 accessor not supported by dart2js.");
  }

  void setUint8(int byteOffset, int value) native;
}

class Float32List extends TypedData implements JavaScriptIndexingBehavior, List<double> native "Float32Array" {
  factory Float32List(int length) =>
    _TypedArrayFactoryProvider.createFloat32List(length);

  factory Float32List.fromList(List<num> list) =>
    _TypedArrayFactoryProvider.createFloat32List_fromList(list);

  factory Float32List.view(ByteBuffer buffer, [int byteOffset, int length]) =>
    _TypedArrayFactoryProvider.createFloat32List_fromBuffer(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 4;

  int get length => JS("int", "#.length", this);

  num operator[](int index) {
    _checkBounds(index, length);
    return JS("num", "#[#]", this, index);
  }

  void operator[]=(int index, num value) {
    _checkBounds(index, length);
    JS("void", "#[#] = #", this, index, value);
  }
  // -- start List<num> mixins.
  // num is the element type.

  // From Iterable<num>:

  Iterator<num> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new ListIterator<num>(this);
  }

  num reduce(num combine(num value, num element)) {
    return IterableMixinWorkaround.reduce(this, combine);
  }

  dynamic fold(dynamic initialValue,
               dynamic combine(dynamic previousValue, num element)) {
    return IterableMixinWorkaround.fold(this, initialValue, combine);
  }

  bool contains(num element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(num element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator = ""]) =>
      IterableMixinWorkaround.joinList(this, separator);

  Iterable map(f(num element)) =>
      IterableMixinWorkaround.mapList(this, f);

  Iterable<num> where(bool f(num element)) =>
      IterableMixinWorkaround.where(this, f);

  Iterable expand(Iterable f(num element)) =>
      IterableMixinWorkaround.expand(this, f);

  bool every(bool f(num element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(num element)) => IterableMixinWorkaround.any(this, f);

  List<num> toList({ bool growable: true }) =>
      new List<num>.from(this, growable: growable);

  Set<num> toSet() => new Set<num>.from(this);

  bool get isEmpty => this.length == 0;

  bool get isNotEmpty => !isEmpty;

  Iterable<num> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<num> takeWhile(bool test(num value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  Iterable<num> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<num> skipWhile(bool test(num value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  num firstWhere(bool test(num value), { num orElse() }) {
    return IterableMixinWorkaround.firstWhere(this, test, orElse);
  }

  num lastWhere(bool test(num value), {num orElse()}) {
    return IterableMixinWorkaround.lastWhereList(this, test, orElse);
  }

  num singleWhere(bool test(num value)) {
    return IterableMixinWorkaround.singleWhere(this, test);
  }

  num elementAt(int index) {
    return this[index];
  }

  // From Collection<num>:

  void add(num value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<num> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<num>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  Iterable<num> get reversed {
    return IterableMixinWorkaround.reversedList(this);
  }

  void sort([int compare(num a, num b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(num element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(num element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  num get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  num get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  num get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  void insert(int index, num element) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void insertAll(int index, Iterable<num> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void setAll(int index, Iterable<num> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  num removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  num removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeWhere(bool test(num element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainWhere(bool test(num element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int end, Iterable<num> iterable, [int skipCount=0]) {
    IterableMixinWorkaround.setRangeList(this, start, end, iterable, skipCount);
  }

  void removeRange(int start, int end) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void replaceRange(int start, int end, Iterable<num> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  void fillRange(int start, int end, [num fillValue]) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  Iterable<num> getRange(int start, int end) =>
    IterableMixinWorkaround.getRangeList(this, start, end);

  List<num> sublist(int start, [int end]) {
    if (end == null) end = length;
    return _Lists.getRange(this, start, end, <num>[]);
  }

  Map<int, num> asMap() =>
    IterableMixinWorkaround.asMapList(this);

  String toString() {
    StringBuffer buffer = new StringBuffer('[');
    buffer.writeAll(this, ', ');
    buffer.write(']');
    return buffer.toString();
  }

  // -- end List<num> mixins.
}

class Float64List extends TypedData implements JavaScriptIndexingBehavior, List<double> native "Float64Array" {

  factory Float64List(int length) =>
    _TypedArrayFactoryProvider.createFloat64List(length);

  factory Float64List.fromList(List<num> list) =>
    _TypedArrayFactoryProvider.createFloat64List_fromList(list);

  factory Float64List.view(ByteBuffer buffer, [int byteOffset, int length]) =>
    _TypedArrayFactoryProvider.createFloat64List_fromBuffer(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 8;

  int get length => JS("int", "#.length", this);

  num operator[](int index) {
    _checkBounds(index, length);
    return JS("num", "#[#]", this, index);
  }

  void operator[]=(int index, num value) {
    _checkBounds(index, length);
    JS("void", "#[#] = #", this, index, value);
  }
  // -- start List<num> mixins.
  // num is the element type.

  // From Iterable<num>:

  Iterator<num> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new ListIterator<num>(this);
  }

  num reduce(num combine(num value, num element)) {
    return IterableMixinWorkaround.reduce(this, combine);
  }

  dynamic fold(dynamic initialValue,
               dynamic combine(dynamic previousValue, num element)) {
    return IterableMixinWorkaround.fold(this, initialValue, combine);
  }

  bool contains(num element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(num element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator = ""]) =>
      IterableMixinWorkaround.joinList(this, separator);

  Iterable map(f(num element)) =>
      IterableMixinWorkaround.mapList(this, f);

  Iterable<num> where(bool f(num element)) =>
      IterableMixinWorkaround.where(this, f);

  Iterable expand(Iterable f(num element)) =>
      IterableMixinWorkaround.expand(this, f);

  bool every(bool f(num element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(num element)) => IterableMixinWorkaround.any(this, f);

  List<num> toList({ bool growable: true }) =>
      new List<num>.from(this, growable: growable);

  Set<num> toSet() => new Set<num>.from(this);

  bool get isEmpty => this.length == 0;

  bool get isNotEmpty => !isEmpty;

  Iterable<num> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<num> takeWhile(bool test(num value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  Iterable<num> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<num> skipWhile(bool test(num value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  num firstWhere(bool test(num value), { num orElse() }) {
    return IterableMixinWorkaround.firstWhere(this, test, orElse);
  }

  num lastWhere(bool test(num value), {num orElse()}) {
    return IterableMixinWorkaround.lastWhereList(this, test, orElse);
  }

  num singleWhere(bool test(num value)) {
    return IterableMixinWorkaround.singleWhere(this, test);
  }

  num elementAt(int index) {
    return this[index];
  }

  // From Collection<num>:

  void add(num value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<num> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<num>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  Iterable<num> get reversed {
    return IterableMixinWorkaround.reversedList(this);
  }

  void sort([int compare(num a, num b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(num element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(num element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  num get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  num get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  num get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  void insert(int index, num element) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void insertAll(int index, Iterable<num> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void setAll(int index, Iterable<num> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  num removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  num removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeWhere(bool test(num element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainWhere(bool test(num element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int end, Iterable<num> iterable, [int skipCount=0]) {
    IterableMixinWorkaround.setRangeList(this, start, end, iterable, skipCount);
  }

  void removeRange(int start, int end) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void replaceRange(int start, int end, Iterable<num> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  void fillRange(int start, int end, [num fillValue]) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  Iterable<num> getRange(int start, int end) =>
    IterableMixinWorkaround.getRangeList(this, start, end);

  List<num> sublist(int start, [int end]) {
    if (end == null) end = length;
    return _Lists.getRange(this, start, end, <num>[]);
  }

  Map<int, num> asMap() =>
    IterableMixinWorkaround.asMapList(this);

  String toString() {
    StringBuffer buffer = new StringBuffer('[');
    buffer.writeAll(this, ', ');
    buffer.write(']');
    return buffer.toString();
  }

  // -- end List<num> mixins.
}

class Int16List extends TypedData implements JavaScriptIndexingBehavior, List<int> native "Int16Array" {

  factory Int16List(int length) =>
    _TypedArrayFactoryProvider.createInt16List(length);

  factory Int16List.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createInt16List_fromList(list);

  factory Int16List.view(ByteBuffer buffer, [int byteOffset, int length]) =>
    _TypedArrayFactoryProvider.createInt16List_fromBuffer(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 2;

  int get length => JS("int", "#.length", this);

  int operator[](int index) {
    _checkBounds(index, length);
    return JS("int", "#[#]", this, index);
  }

  void operator[]=(int index, int value) {
    _checkBounds(index, length);
    JS("void", "#[#] = #", this, index, value);
  }
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new ListIterator<int>(this);
  }

  int reduce(int combine(int value, int element)) {
    return IterableMixinWorkaround.reduce(this, combine);
  }

  dynamic fold(dynamic initialValue,
               dynamic combine(dynamic previousValue, int element)) {
    return IterableMixinWorkaround.fold(this, initialValue, combine);
  }

  bool contains(int element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(int element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator = ""]) =>
      IterableMixinWorkaround.joinList(this, separator);

  Iterable map(f(int element)) =>
      IterableMixinWorkaround.mapList(this, f);

  Iterable<int> where(bool f(int element)) =>
      IterableMixinWorkaround.where(this, f);

  Iterable expand(Iterable f(int element)) =>
      IterableMixinWorkaround.expand(this, f);

  bool every(bool f(int element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(int element)) => IterableMixinWorkaround.any(this, f);

  List<int> toList({ bool growable: true }) =>
      new List<int>.from(this, growable: growable);

  Set<int> toSet() => new Set<int>.from(this);

  bool get isEmpty => this.length == 0;

  bool get isNotEmpty => !isEmpty;

  Iterable<int> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<int> takeWhile(bool test(int value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  Iterable<int> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<int> skipWhile(bool test(int value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  int firstWhere(bool test(int value), { int orElse() }) {
    return IterableMixinWorkaround.firstWhere(this, test, orElse);
  }

  int lastWhere(bool test(int value), {int orElse()}) {
    return IterableMixinWorkaround.lastWhereList(this, test, orElse);
  }

  int singleWhere(bool test(int value)) {
    return IterableMixinWorkaround.singleWhere(this, test);
  }

  int elementAt(int index) {
    return this[index];
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<int> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<int>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  Iterable<int> get reversed {
    return IterableMixinWorkaround.reversedList(this);
  }

  void sort([int compare(int a, int b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  int get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  int get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  void insert(int index, int element) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void insertAll(int index, Iterable<int> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void setAll(int index, Iterable<int> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  int removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  int removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeWhere(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainWhere(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int end, Iterable<int> iterable, [int skipCount=0]) {
    IterableMixinWorkaround.setRangeList(this, start, end, iterable, skipCount);
  }

  void removeRange(int start, int end) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void replaceRange(int start, int end, Iterable<int> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  void fillRange(int start, int end, [int fillValue]) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  Iterable<int> getRange(int start, int end) =>
    IterableMixinWorkaround.getRangeList(this, start, end);

  List<int> sublist(int start, [int end]) {
    if (end == null) end = length;
    return _Lists.getRange(this, start, end, <int>[]);
  }

  Map<int, int> asMap() =>
    IterableMixinWorkaround.asMapList(this);

  String toString() {
    StringBuffer buffer = new StringBuffer('[');
    buffer.writeAll(this, ', ');
    buffer.write(']');
    return buffer.toString();
  }

  // -- end List<int> mixins.
}

class Int32List extends TypedData implements JavaScriptIndexingBehavior, List<int> native "Int32Array" {

  factory Int32List(int length) =>
    _TypedArrayFactoryProvider.createInt32List(length);

  factory Int32List.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createInt32List_fromList(list);

  factory Int32List.view(ByteBuffer buffer, [int byteOffset, int length]) =>
    _TypedArrayFactoryProvider.createInt32List_fromBuffer(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 4;

  int get length => JS("int", "#.length", this);

  int operator[](int index) {
    _checkBounds(index, length);
    return JS("int", "#[#]", this, index);
  }

  void operator[]=(int index, int value) {
    _checkBounds(index, length);
    JS("void", "#[#] = #", this, index, value);
  }
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new ListIterator<int>(this);
  }

  int reduce(int combine(int value, int element)) {
    return IterableMixinWorkaround.reduce(this, combine);
  }

  dynamic fold(dynamic initialValue,
               dynamic combine(dynamic previousValue, int element)) {
    return IterableMixinWorkaround.fold(this, initialValue, combine);
  }

  bool contains(int element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(int element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator = ""]) =>
      IterableMixinWorkaround.joinList(this, separator);

  Iterable map(f(int element)) =>
      IterableMixinWorkaround.mapList(this, f);

  Iterable<int> where(bool f(int element)) =>
      IterableMixinWorkaround.where(this, f);

  Iterable expand(Iterable f(int element)) =>
      IterableMixinWorkaround.expand(this, f);

  bool every(bool f(int element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(int element)) => IterableMixinWorkaround.any(this, f);

  List<int> toList({ bool growable: true }) =>
      new List<int>.from(this, growable: growable);

  Set<int> toSet() => new Set<int>.from(this);

  bool get isEmpty => this.length == 0;

  bool get isNotEmpty => !isEmpty;

  Iterable<int> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<int> takeWhile(bool test(int value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  Iterable<int> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<int> skipWhile(bool test(int value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  int firstWhere(bool test(int value), { int orElse() }) {
    return IterableMixinWorkaround.firstWhere(this, test, orElse);
  }

  int lastWhere(bool test(int value), {int orElse()}) {
    return IterableMixinWorkaround.lastWhereList(this, test, orElse);
  }

  int singleWhere(bool test(int value)) {
    return IterableMixinWorkaround.singleWhere(this, test);
  }

  int elementAt(int index) {
    return this[index];
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<int> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<int>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  Iterable<int> get reversed {
    return IterableMixinWorkaround.reversedList(this);
  }

  void sort([int compare(int a, int b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  int get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  int get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  void insert(int index, int element) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void insertAll(int index, Iterable<int> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void setAll(int index, Iterable<int> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  int removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  int removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeWhere(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainWhere(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int end, Iterable<int> iterable, [int skipCount=0]) {
    IterableMixinWorkaround.setRangeList(this, start, end, iterable, skipCount);
  }

  void removeRange(int start, int end) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void replaceRange(int start, int end, Iterable<int> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  void fillRange(int start, int end, [int fillValue]) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  Iterable<int> getRange(int start, int end) =>
    IterableMixinWorkaround.getRangeList(this, start, end);

  List<int> sublist(int start, [int end]) {
    if (end == null) end = length;
    return _Lists.getRange(this, start, end, <int>[]);
  }

  Map<int, int> asMap() =>
    IterableMixinWorkaround.asMapList(this);

  String toString() {
    StringBuffer buffer = new StringBuffer('[');
    buffer.writeAll(this, ', ');
    buffer.write(']');
    return buffer.toString();
  }

  // -- end List<int> mixins.
}

class Int8List extends TypedData implements JavaScriptIndexingBehavior, List<int> native "Int8Array" {

  factory Int8List(int length) =>
    _TypedArrayFactoryProvider.createInt8List(length);

  factory Int8List.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createInt8List_fromList(list);

  factory Int8List.view(ByteBuffer buffer, [int byteOffset, int length]) =>
    _TypedArrayFactoryProvider.createInt8List_fromBuffer(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 1;

  int get length => JS("int", "#.length", this);

  int operator[](int index) {
    _checkBounds(index, length);
    return JS("int", "#[#]", this, index);
  }

  void operator[]=(int index, int value) {
    _checkBounds(index, length);
    JS("void", "#[#] = #", this, index, value);
  }
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new ListIterator<int>(this);
  }

  int reduce(int combine(int value, int element)) {
    return IterableMixinWorkaround.reduce(this, combine);
  }

  dynamic fold(dynamic initialValue,
               dynamic combine(dynamic previousValue, int element)) {
    return IterableMixinWorkaround.fold(this, initialValue, combine);
  }

  bool contains(int element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(int element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator = ""]) =>
      IterableMixinWorkaround.joinList(this, separator);

  Iterable map(f(int element)) =>
      IterableMixinWorkaround.mapList(this, f);

  Iterable<int> where(bool f(int element)) =>
      IterableMixinWorkaround.where(this, f);

  Iterable expand(Iterable f(int element)) =>
      IterableMixinWorkaround.expand(this, f);

  bool every(bool f(int element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(int element)) => IterableMixinWorkaround.any(this, f);

  List<int> toList({ bool growable: true }) =>
      new List<int>.from(this, growable: growable);

  Set<int> toSet() => new Set<int>.from(this);

  bool get isEmpty => this.length == 0;

  bool get isNotEmpty => !isEmpty;

  Iterable<int> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<int> takeWhile(bool test(int value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  Iterable<int> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<int> skipWhile(bool test(int value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  int firstWhere(bool test(int value), { int orElse() }) {
    return IterableMixinWorkaround.firstWhere(this, test, orElse);
  }

  int lastWhere(bool test(int value), {int orElse()}) {
    return IterableMixinWorkaround.lastWhereList(this, test, orElse);
  }

  int singleWhere(bool test(int value)) {
    return IterableMixinWorkaround.singleWhere(this, test);
  }

  int elementAt(int index) {
    return this[index];
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<int> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<int>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  Iterable<int> get reversed {
    return IterableMixinWorkaround.reversedList(this);
  }

  void sort([int compare(int a, int b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  int get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  int get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  void insert(int index, int element) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void insertAll(int index, Iterable<int> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void setAll(int index, Iterable<int> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  int removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  int removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeWhere(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainWhere(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int end, Iterable<int> iterable, [int skipCount=0]) {
    IterableMixinWorkaround.setRangeList(this, start, end, iterable, skipCount);
  }

  void removeRange(int start, int end) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void replaceRange(int start, int end, Iterable<int> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  void fillRange(int start, int end, [int fillValue]) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  Iterable<int> getRange(int start, int end) =>
    IterableMixinWorkaround.getRangeList(this, start, end);

  List<int> sublist(int start, [int end]) {
    if (end == null) end = length;
    return _Lists.getRange(this, start, end, <int>[]);
  }

  Map<int, int> asMap() =>
    IterableMixinWorkaround.asMapList(this);

  String toString() {
    StringBuffer buffer = new StringBuffer('[');
    buffer.writeAll(this, ', ');
    buffer.write(']');
    return buffer.toString();
  }

  // -- end List<int> mixins.
}

class Uint16List extends TypedData implements JavaScriptIndexingBehavior, List<int> native "Uint16Array" {

  factory Uint16List(int length) =>
    _TypedArrayFactoryProvider.createUint16List(length);

  factory Uint16List.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createUint16List_fromList(list);

  factory Uint16List.view(ByteBuffer buffer, [int byteOffset, int length]) =>
    _TypedArrayFactoryProvider.createUint16List_fromBuffer(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 2;

  int get length => JS("int", "#.length", this);

  int operator[](int index) {
    _checkBounds(index, length);
    return JS("int", "#[#]", this, index);
  }

  void operator[]=(int index, int value) {
    _checkBounds(index, length);
    JS("void", "#[#] = #", this, index, value);
  }
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new ListIterator<int>(this);
  }

  int reduce(int combine(int value, int element)) {
    return IterableMixinWorkaround.reduce(this, combine);
  }

  dynamic fold(dynamic initialValue,
               dynamic combine(dynamic previousValue, int element)) {
    return IterableMixinWorkaround.fold(this, initialValue, combine);
  }

  bool contains(int element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(int element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator = ""]) =>
      IterableMixinWorkaround.joinList(this, separator);

  Iterable map(f(int element)) =>
      IterableMixinWorkaround.mapList(this, f);

  Iterable<int> where(bool f(int element)) =>
      IterableMixinWorkaround.where(this, f);

  Iterable expand(Iterable f(int element)) =>
      IterableMixinWorkaround.expand(this, f);

  bool every(bool f(int element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(int element)) => IterableMixinWorkaround.any(this, f);

  List<int> toList({ bool growable: true }) =>
      new List<int>.from(this, growable: growable);

  Set<int> toSet() => new Set<int>.from(this);

  bool get isEmpty => this.length == 0;

  bool get isNotEmpty => !isEmpty;

  Iterable<int> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<int> takeWhile(bool test(int value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  Iterable<int> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<int> skipWhile(bool test(int value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  int firstWhere(bool test(int value), { int orElse() }) {
    return IterableMixinWorkaround.firstWhere(this, test, orElse);
  }

  int lastWhere(bool test(int value), {int orElse()}) {
    return IterableMixinWorkaround.lastWhereList(this, test, orElse);
  }

  int singleWhere(bool test(int value)) {
    return IterableMixinWorkaround.singleWhere(this, test);
  }

  int elementAt(int index) {
    return this[index];
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<int> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<int>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  Iterable<int> get reversed {
    return IterableMixinWorkaround.reversedList(this);
  }

  void sort([int compare(int a, int b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  int get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  int get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  void insert(int index, int element) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void insertAll(int index, Iterable<int> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void setAll(int index, Iterable<int> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  int removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  int removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeWhere(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainWhere(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int end, Iterable<int> iterable, [int skipCount=0]) {
    IterableMixinWorkaround.setRangeList(this, start, end, iterable, skipCount);
  }

  void removeRange(int start, int end) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void replaceRange(int start, int end, Iterable<int> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  void fillRange(int start, int end, [int fillValue]) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  Iterable<int> getRange(int start, int end) =>
    IterableMixinWorkaround.getRangeList(this, start, end);

  List<int> sublist(int start, [int end]) {
    if (end == null) end = length;
    return _Lists.getRange(this, start, end, <int>[]);
  }

  Map<int, int> asMap() =>
    IterableMixinWorkaround.asMapList(this);

  String toString() {
    StringBuffer buffer = new StringBuffer('[');
    buffer.writeAll(this, ', ');
    buffer.write(']');
    return buffer.toString();
  }

  // -- end List<int> mixins.
}

class Uint32List extends TypedData implements JavaScriptIndexingBehavior, List<int> native "Uint32Array" {

  factory Uint32List(int length) =>
    _TypedArrayFactoryProvider.createUint32List(length);

  factory Uint32List.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createUint32List_fromList(list);

  factory Uint32List.view(ByteBuffer buffer, [int byteOffset, int length]) =>
    _TypedArrayFactoryProvider.createUint32List_fromBuffer(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 4;

  int get length => JS("int", "#.length", this);

  int operator[](int index) {
    _checkBounds(index, length);
    return JS("int", "#[#]", this, index);
  }

  void operator[]=(int index, int value) {
    _checkBounds(index, length);
    JS("void", "#[#] = #", this, index, value);
  }
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new ListIterator<int>(this);
  }

  int reduce(int combine(int value, int element)) {
    return IterableMixinWorkaround.reduce(this, combine);
  }

  dynamic fold(dynamic initialValue,
               dynamic combine(dynamic previousValue, int element)) {
    return IterableMixinWorkaround.fold(this, initialValue, combine);
  }

  bool contains(int element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(int element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator = ""]) =>
      IterableMixinWorkaround.joinList(this, separator);

  Iterable map(f(int element)) =>
      IterableMixinWorkaround.mapList(this, f);

  Iterable<int> where(bool f(int element)) =>
      IterableMixinWorkaround.where(this, f);

  Iterable expand(Iterable f(int element)) =>
      IterableMixinWorkaround.expand(this, f);

  bool every(bool f(int element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(int element)) => IterableMixinWorkaround.any(this, f);

  List<int> toList({ bool growable: true }) =>
      new List<int>.from(this, growable: growable);

  Set<int> toSet() => new Set<int>.from(this);

  bool get isEmpty => this.length == 0;

  bool get isNotEmpty => !isEmpty;

  Iterable<int> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<int> takeWhile(bool test(int value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  Iterable<int> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<int> skipWhile(bool test(int value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  int firstWhere(bool test(int value), { int orElse() }) {
    return IterableMixinWorkaround.firstWhere(this, test, orElse);
  }

  int lastWhere(bool test(int value), {int orElse()}) {
    return IterableMixinWorkaround.lastWhereList(this, test, orElse);
  }

  int singleWhere(bool test(int value)) {
    return IterableMixinWorkaround.singleWhere(this, test);
  }

  int elementAt(int index) {
    return this[index];
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<int> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<int>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  Iterable<int> get reversed {
    return IterableMixinWorkaround.reversedList(this);
  }

  void sort([int compare(int a, int b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  int get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  int get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  void insert(int index, int element) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void insertAll(int index, Iterable<int> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void setAll(int index, Iterable<int> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  int removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  int removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeWhere(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainWhere(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int end, Iterable<int> iterable, [int skipCount=0]) {
    IterableMixinWorkaround.setRangeList(this, start, end, iterable, skipCount);
  }

  void removeRange(int start, int end) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void replaceRange(int start, int end, Iterable<int> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  void fillRange(int start, int end, [int fillValue]) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  Iterable<int> getRange(int start, int end) =>
    IterableMixinWorkaround.getRangeList(this, start, end);

  List<int> sublist(int start, [int end]) {
    if (end == null) end = length;
    return _Lists.getRange(this, start, end, <int>[]);
  }

  Map<int, int> asMap() =>
    IterableMixinWorkaround.asMapList(this);

  String toString() {
    StringBuffer buffer = new StringBuffer('[');
    buffer.writeAll(this, ', ');
    buffer.write(']');
    return buffer.toString();
  }

  // -- end List<int> mixins.
}

class Uint8ClampedList extends Uint8List implements JavaScriptIndexingBehavior, List<int> native "Uint8ClampedArray" {

  factory Uint8ClampedList(int length) =>
    _TypedArrayFactoryProvider.createUint8ClampedList(length);

  factory Uint8ClampedList.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createUint8ClampedList_fromList(list);

  factory Uint8ClampedList.view(ByteBuffer buffer, [int byteOffset, int length]) =>
    _TypedArrayFactoryProvider.createUint8ClampedList_fromBuffer(buffer, byteOffset, length);

  // Use implementation from Uint8Array.
  // final int length;

  int operator[](int index) {
    _checkBounds(index, length);
    return JS("int", "#[#]", this, index);
  }

  void operator[]=(int index, int value) {
    _checkBounds(index, length);
    JS("void", "#[#] = #", this, index, value);
  }
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new ListIterator<int>(this);
  }

  int reduce(int combine(int value, int element)) {
    return IterableMixinWorkaround.reduce(this, combine);
  }

  dynamic fold(dynamic initialValue,
               dynamic combine(dynamic previousValue, int element)) {
    return IterableMixinWorkaround.fold(this, initialValue, combine);
  }

  bool contains(int element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(int element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator = ""]) =>
      IterableMixinWorkaround.joinList(this, separator);

  Iterable map(f(int element)) =>
      IterableMixinWorkaround.mapList(this, f);

  Iterable<int> where(bool f(int element)) =>
      IterableMixinWorkaround.where(this, f);

  Iterable expand(Iterable f(int element)) =>
      IterableMixinWorkaround.expand(this, f);

  bool every(bool f(int element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(int element)) => IterableMixinWorkaround.any(this, f);

  List<int> toList({ bool growable: true }) =>
      new List<int>.from(this, growable: growable);

  Set<int> toSet() => new Set<int>.from(this);

  bool get isEmpty => this.length == 0;

  bool get isNotEmpty => !isEmpty;

  Iterable<int> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<int> takeWhile(bool test(int value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  Iterable<int> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<int> skipWhile(bool test(int value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  int firstWhere(bool test(int value), { int orElse() }) {
    return IterableMixinWorkaround.firstWhere(this, test, orElse);
  }

  int lastWhere(bool test(int value), {int orElse()}) {
    return IterableMixinWorkaround.lastWhereList(this, test, orElse);
  }

  int singleWhere(bool test(int value)) {
    return IterableMixinWorkaround.singleWhere(this, test);
  }

  int elementAt(int index) {
    return this[index];
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<int> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<int>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  Iterable<int> get reversed {
    return IterableMixinWorkaround.reversedList(this);
  }

  void sort([int compare(int a, int b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  int get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  int get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  void insert(int index, int element) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void insertAll(int index, Iterable<int> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void setAll(int index, Iterable<int> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  int removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  int removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeWhere(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainWhere(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int end, Iterable<int> iterable, [int skipCount=0]) {
    IterableMixinWorkaround.setRangeList(this, start, end, iterable, skipCount);
  }

  void removeRange(int start, int end) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void replaceRange(int start, int end, Iterable<int> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  void fillRange(int start, int end, [int fillValue]) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  Iterable<int> getRange(int start, int end) =>
    IterableMixinWorkaround.getRangeList(this, start, end);

  List<int> sublist(int start, [int end]) {
    if (end == null) end = length;
    return _Lists.getRange(this, start, end, <int>[]);
  }

  Map<int, int> asMap() =>
    IterableMixinWorkaround.asMapList(this);

  String toString() {
    StringBuffer buffer = new StringBuffer('[');
    buffer.writeAll(this, ', ');
    buffer.write(']');
    return buffer.toString();
  }

  // -- end List<int> mixins.
}

class Uint8List extends TypedData implements JavaScriptIndexingBehavior, List<int> native "Uint8Array" {

  factory Uint8List(int length) =>
    _TypedArrayFactoryProvider.createUint8List(length);

  factory Uint8List.fromList(List<int> list) =>
    _TypedArrayFactoryProvider.createUint8List_fromList(list);

  factory Uint8List.view(ByteBuffer buffer, [int byteOffset, int length]) =>
    _TypedArrayFactoryProvider.createUint8List_fromBuffer(buffer, byteOffset, length);

  static const int BYTES_PER_ELEMENT = 1;

  int get length => JS("int", "#.length", this);

  int operator[](int index) {
    _checkBounds(index, length);
    return JS("int", "#[#]", this, index);
  }

  void operator[]=(int index, int value) {
    _checkBounds(index, length);
    JS("void", "#[#] = #", this, index, value);
  }
  // -- start List<int> mixins.
  // int is the element type.

  // From Iterable<int>:

  Iterator<int> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new ListIterator<int>(this);
  }

  int reduce(int combine(int value, int element)) {
    return IterableMixinWorkaround.reduce(this, combine);
  }

  dynamic fold(dynamic initialValue,
               dynamic combine(dynamic previousValue, int element)) {
    return IterableMixinWorkaround.fold(this, initialValue, combine);
  }

  bool contains(int element) => IterableMixinWorkaround.contains(this, element);

  void forEach(void f(int element)) => IterableMixinWorkaround.forEach(this, f);

  String join([String separator = ""]) =>
      IterableMixinWorkaround.joinList(this, separator);

  Iterable map(f(int element)) =>
      IterableMixinWorkaround.mapList(this, f);

  Iterable<int> where(bool f(int element)) =>
      IterableMixinWorkaround.where(this, f);

  Iterable expand(Iterable f(int element)) =>
      IterableMixinWorkaround.expand(this, f);

  bool every(bool f(int element)) => IterableMixinWorkaround.every(this, f);

  bool any(bool f(int element)) => IterableMixinWorkaround.any(this, f);

  List<int> toList({ bool growable: true }) =>
      new List<int>.from(this, growable: growable);

  Set<int> toSet() => new Set<int>.from(this);

  bool get isEmpty => this.length == 0;

  bool get isNotEmpty => !isEmpty;

  Iterable<int> take(int n) => IterableMixinWorkaround.takeList(this, n);

  Iterable<int> takeWhile(bool test(int value)) {
    return IterableMixinWorkaround.takeWhile(this, test);
  }

  Iterable<int> skip(int n) => IterableMixinWorkaround.skipList(this, n);

  Iterable<int> skipWhile(bool test(int value)) {
    return IterableMixinWorkaround.skipWhile(this, test);
  }

  int firstWhere(bool test(int value), { int orElse() }) {
    return IterableMixinWorkaround.firstWhere(this, test, orElse);
  }

  int lastWhere(bool test(int value), {int orElse()}) {
    return IterableMixinWorkaround.lastWhereList(this, test, orElse);
  }

  int singleWhere(bool test(int value)) {
    return IterableMixinWorkaround.singleWhere(this, test);
  }

  int elementAt(int index) {
    return this[index];
  }

  // From Collection<int>:

  void add(int value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<int> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<int>:
  void set length(int value) {
    throw new UnsupportedError("Cannot resize immutable List.");
  }

  void clear() {
    throw new UnsupportedError("Cannot clear immutable List.");
  }

  Iterable<int> get reversed {
    return IterableMixinWorkaround.reversedList(this);
  }

  void sort([int compare(int a, int b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  int indexOf(int element, [int start = 0]) =>
      _Lists.indexOf(this, element, start, this.length);

  int lastIndexOf(int element, [int start]) {
    if (start == null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int get first {
    if (this.length > 0) return this[0];
    throw new StateError("No elements");
  }

  int get last {
    if (this.length > 0) return this[this.length - 1];
    throw new StateError("No elements");
  }

  int get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  void insert(int index, int element) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void insertAll(int index, Iterable<int> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void setAll(int index, Iterable<int> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  int removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  int removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeWhere(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainWhere(bool test(int element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int end, Iterable<int> iterable, [int skipCount=0]) {
    IterableMixinWorkaround.setRangeList(this, start, end, iterable, skipCount);
  }

  void removeRange(int start, int end) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void replaceRange(int start, int end, Iterable<int> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  void fillRange(int start, int end, [int fillValue]) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  Iterable<int> getRange(int start, int end) =>
    IterableMixinWorkaround.getRangeList(this, start, end);

  List<int> sublist(int start, [int end]) {
    if (end == null) end = length;
    return _Lists.getRange(this, start, end, <int>[]);
  }

  Map<int, int> asMap() =>
    IterableMixinWorkaround.asMapList(this);

  String toString() {
    StringBuffer buffer = new StringBuffer('[');
    buffer.writeAll(this, ', ');
    buffer.write(']');
    return buffer.toString();
  }

  // -- end List<int> mixins.
}


class Int64List extends TypedData implements JavaScriptIndexingBehavior, List<int> {
  factory Int64List(int length) {
    throw new UnsupportedError("Int64List not supported by dart2js.");
  }

  factory Int64List.fromList(List<int> list) {
    throw new UnsupportedError("Int64List not supported by dart2js.");
  }

  factory Int64List.view(ByteBuffer buffer, [int byteOffset, int length]) {
    throw new UnsupportedError("Int64List not supported by dart2js.");
  }

  static const int BYTES_PER_ELEMENT = 8;
}


class Uint64List extends TypedData implements JavaScriptIndexingBehavior, List<int> {
  factory Uint64List(int length) {
    throw new UnsupportedError("Uint64List not supported by dart2js.");
  }

  factory Uint64List.fromList(List<int> list) {
    throw new UnsupportedError("Uint64List not supported by dart2js.");
  }

  factory Uint64List.view(ByteBuffer buffer, [int byteOffset, int length]) {
    throw new UnsupportedError("Uint64List not supported by dart2js.");
  }

  static const int BYTES_PER_ELEMENT = 8;
}


abstract class Float32x4List implements List<Float32x4>, TypedData {
  factory Float32x4List(int length) {
    throw new UnsupportedError("Float32x4List not supported by dart2js.");
  }

  factory Float32x4List.view(ByteBuffer buffer,
                             [int offsetInBytes = 0, int length]) {
    throw new UnsupportedError("Float32x4List not supported by dart2js.");
  }

  static const int BYTES_PER_ELEMENT = 16;
}


abstract class Float32x4 {
  factory Float32x4(double x, double y, double z, double w) {
    throw new UnsupportedError("Float32x4 not supported by dart2js.");
  }
  factory Float32x4.splat(double v) {
    throw new UnsupportedError("Float32x4 not supported by dart2js.");
  }
  factory Float32x4.zero() {
    throw new UnsupportedError("Float32x4 not supported by dart2js.");
  }
}


abstract class Uint32x4 {
  factory Uint32x4(int x, int y, int z, int w) {
    throw new UnsupportedError("Uint32x4 not supported by dart2js.");
  }
  factory Uint32x4.bool(bool x, bool y, bool z, bool w) {
    throw new UnsupportedError("Uint32x4 not supported by dart2js.");
  }
}


// TODO(vsm): Eliminate this class and just inline into above.
class _TypedArrayFactoryProvider {
  static ByteData createByteData(int length) => _B8(length);
  static ByteData createByteData_fromBuffer(ByteBuffer buffer,
                                  [int byteOffset = 0, int length]) {
    if (length == null) return _B8_2(buffer, byteOffset);
    return _B8_3(buffer, byteOffset, length);
  }

  static Float32List createFloat32List(int length) => _F32(length);
  static Float32List createFloat32List_fromList(List<num> list) =>
      _F32(ensureNative(list));
  static Float32List createFloat32List_fromBuffer(ByteBuffer buffer,
                                  [int byteOffset = 0, int length]) {
    if (length == null) return _F32_2(buffer, byteOffset);
    return _F32_3(buffer, byteOffset, length);
  }

  static Float64List createFloat64List(int length) => _F64(length);
  static Float64List createFloat64List_fromList(List<num> list) =>
      _F64(ensureNative(list));
  static Float64List createFloat64List_fromBuffer(ByteBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _F64_2(buffer, byteOffset);
    return _F64_3(buffer, byteOffset, length);
  }

  static Int8List createInt8List(int length) => _I8(length);
  static Int8List createInt8List_fromList(List<num> list) =>
      _I8(ensureNative(list));
  static Int8List createInt8List_fromBuffer(ByteBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _I8_2(buffer, byteOffset);
    return _I8_3(buffer, byteOffset, length);
  }

  static Int16List createInt16List(int length) => _I16(length);
  static Int16List createInt16List_fromList(List<num> list) =>
      _I16(ensureNative(list));
  static Int16List createInt16List_fromBuffer(ByteBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _I16_2(buffer, byteOffset);
    return _I16_3(buffer, byteOffset, length);
  }

  static Int32List createInt32List(int length) => _I32(length);
  static Int32List createInt32List_fromList(List<num> list) =>
      _I32(ensureNative(list));
  static Int32List createInt32List_fromBuffer(ByteBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _I32_2(buffer, byteOffset);
    return _I32_3(buffer, byteOffset, length);
  }

  static Uint8List createUint8List(int length) => _U8(length);
  static Uint8List createUint8List_fromList(List<num> list) =>
      _U8(ensureNative(list));
  static Uint8List createUint8List_fromBuffer(ByteBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _U8_2(buffer, byteOffset);
    return _U8_3(buffer, byteOffset, length);
  }

  static Uint16List createUint16List(int length) => _U16(length);
  static Uint16List createUint16List_fromList(List<num> list) =>
      _U16(ensureNative(list));
  static Uint16List createUint16List_fromBuffer(ByteBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _U16_2(buffer, byteOffset);
    return _U16_3(buffer, byteOffset, length);
  }

  static Uint32List createUint32List(int length) => _U32(length);
  static Uint32List createUint32List_fromList(List<num> list) =>
      _U32(ensureNative(list));
  static Uint32List createUint32List_fromBuffer(ByteBuffer buffer,
      [int byteOffset = 0, int length]) {
    if (length == null) return _U32_2(buffer, byteOffset);
    return _U32_3(buffer, byteOffset, length);
  }

  static Uint8ClampedList createUint8ClampedList(int length) => _U8C(length);
  static Uint8ClampedList createUint8ClampedList_fromList(List<num> list) =>
      _U8C(ensureNative(list));
  static Uint8ClampedList createUint8ClampedList_fromBuffer(
        ByteBuffer buffer, [int byteOffset = 0, int length]) {
    if (length == null) return _U8C_2(buffer, byteOffset);
    return _U8C_3(buffer, byteOffset, length);
  }

  static ByteData _B8(arg) =>
      JS('ByteData', 'new DataView(new ArrayBuffer(#))', arg);
  static Float32List _F32(arg) =>
      JS('Float32List', 'new Float32Array(#)', arg);
  static Float64List _F64(arg) =>
      JS('Float64List', 'new Float64Array(#)', arg);
  static Int8List _I8(arg) =>
      JS('Int8List', 'new Int8Array(#)', arg);
  static Int16List _I16(arg) =>
      JS('Int16List', 'new Int16Array(#)', arg);
  static Int32List _I32(arg) =>
      JS('Int32List', 'new Int32Array(#)', arg);
  static Uint8List _U8(arg) =>
      JS('Uint8List', 'new Uint8Array(#)', arg);
  static Uint16List _U16(arg) =>
      JS('Uint16List', 'new Uint16Array(#)', arg);
  static Uint32List _U32(arg) =>
      JS('Uint32List', 'new Uint32Array(#)', arg);
  static Uint8ClampedList _U8C(arg) =>
      JS('Uint8ClampedList', 'new Uint8ClampedArray(#)', arg);

  static ByteData _B8_2(arg1, arg2) =>
      JS('ByteData', 'new DataView(#, #)', arg1, arg2);
  static Float32List _F32_2(arg1, arg2) =>
      JS('Float32List', 'new Float32Array(#, #)', arg1, arg2);
  static Float64List _F64_2(arg1, arg2) =>
      JS('Float64List', 'new Float64Array(#, #)', arg1, arg2);
  static Int8List _I8_2(arg1, arg2) =>
      JS('Int8List', 'new Int8Array(#, #)', arg1, arg2);
  static Int16List _I16_2(arg1, arg2) =>
      JS('Int16List', 'new Int16Array(#, #)', arg1, arg2);
  static Int32List _I32_2(arg1, arg2) =>
      JS('Int32List', 'new Int32Array(#, #)', arg1, arg2);
  static Uint8List _U8_2(arg1, arg2) =>
      JS('Uint8List', 'new Uint8Array(#, #)', arg1, arg2);
  static Uint16List _U16_2(arg1, arg2) =>
      JS('Uint16List', 'new Uint16Array(#, #)', arg1, arg2);
  static Uint32List _U32_2(arg1, arg2) =>
      JS('Uint32List', 'new Uint32Array(#, #)', arg1, arg2);
  static Uint8ClampedList _U8C_2(arg1, arg2) =>
      JS('Uint8ClampedList', 'new Uint8ClampedArray(#, #)', arg1, arg2);

  static ByteData _B8_3(arg1, arg2, arg3) =>
      JS('ByteData', 'new DataView(#, #, #)', arg1, arg2, arg3);
  static Float32List _F32_3(arg1, arg2, arg3) =>
      JS('Float32List', 'new Float32Array(#, #, #)', arg1, arg2, arg3);
  static Float64List _F64_3(arg1, arg2, arg3) =>
      JS('Float64List', 'new Float64Array(#, #, #)', arg1, arg2, arg3);
  static Int8List _I8_3(arg1, arg2, arg3) =>
      JS('Int8List', 'new Int8Array(#, #, #)', arg1, arg2, arg3);
  static Int16List _I16_3(arg1, arg2, arg3) =>
      JS('Int16List', 'new Int16Array(#, #, #)', arg1, arg2, arg3);
  static Int32List _I32_3(arg1, arg2, arg3) =>
      JS('Int32List', 'new Int32Array(#, #, #)', arg1, arg2, arg3);
  static Uint8List _U8_3(arg1, arg2, arg3) =>
      JS('Uint8List', 'new Uint8Array(#, #, #)', arg1, arg2, arg3);
  static Uint16List _U16_3(arg1, arg2, arg3) =>
      JS('Uint16List', 'new Uint16Array(#, #, #)', arg1, arg2, arg3);
  static Uint32List _U32_3(arg1, arg2, arg3) =>
      JS('Uint32List', 'new Uint32Array(#, #, #)', arg1, arg2, arg3);
  static Uint8ClampedList _U8C_3(arg1, arg2, arg3) =>
      JS('Uint8ClampedList', 'new Uint8ClampedArray(#, #, #)', arg1, arg2, arg3);


  // Ensures that [list] is a JavaScript Array or a typed array.  If necessary,
  // copies the list.
  static ensureNative(List list) => list;  // TODO: make sure.
}
