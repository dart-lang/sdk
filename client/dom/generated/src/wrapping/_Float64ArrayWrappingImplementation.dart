// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _Float64ArrayWrappingImplementation extends _ArrayBufferViewWrappingImplementation implements Float64Array {
  _Float64ArrayWrappingImplementation() : super() {}

  static create__Float64ArrayWrappingImplementation() native {
    return new _Float64ArrayWrappingImplementation();
  }

  int get length() { return _get_length(this); }
  static int _get_length(var _this) native;

  num operator[](int index) { return _index(this, index); }
  static num _index(var _this, int index) native;

  void operator[]=(int index, num value) {
    return _set_index(this, index, value);
  }
  static _set_index(_this, index, value) native;

  void add(num value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(num value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<num> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void sort(int compare(num a, num b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw new UnsupportedOperationException("This object is immutable.");
  }

  int indexOf(num element, [int start = 0]) {
    return _Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(num element, [int start = null]) {
    if (start === null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int clear() {
    throw new UnsupportedOperationException("Cannot clear immutable List.");
  }

  num removeLast() {
    throw new UnsupportedOperationException("Cannot removeLast on immutable List.");
  }

  num last() {
    return this[length - 1];
  }

  void forEach(void f(num element)) {
    _Collections.forEach(this, f);
  }

  Collection<num> filter(bool f(num element)) {
    return _Collections.filter(this, new List<num>(), f);
  }

  bool every(bool f(num element)) {
    return _Collections.every(this, f);
  }

  bool some(bool f(num element)) {
    return _Collections.some(this, f);
  }

  void setRange(int start, int length, List<num> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int length, [num initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }

  List<num> getRange(int start, int length) {
    throw new NotImplementedException();
  }

  bool isEmpty() {
    return length == 0;
  }

  Iterator<num> iterator() {
    return new _FixedSizeListIterator<num>(this);
  }

  Float64Array subarray(int start, [int end = null]) {
    if (end === null) {
      return _subarray(this, start);
    } else {
      return _subarray_2(this, start, end);
    }
  }
  static Float64Array _subarray(receiver, start) native;
  static Float64Array _subarray_2(receiver, start, end) native;

  String get typeName() { return "Float64Array"; }
}
