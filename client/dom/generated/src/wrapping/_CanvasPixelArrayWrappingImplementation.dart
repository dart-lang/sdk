// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CanvasPixelArrayWrappingImplementation extends DOMWrapperBase implements CanvasPixelArray {
  _CanvasPixelArrayWrappingImplementation() : super() {}

  static create__CanvasPixelArrayWrappingImplementation() native {
    return new _CanvasPixelArrayWrappingImplementation();
  }

  int get length() { return _get__CanvasPixelArray_length(this); }
  static int _get__CanvasPixelArray_length(var _this) native;

  int operator[](int index) {
    return item(index);
  }

  void operator[]=(int index, int value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  void add(int value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(int value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<int> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void sort(int compare(int a, int b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw new UnsupportedOperationException("This object is immutable.");
  }

  int indexOf(int element, int startIndex) {
    return _Lists.indexOf(this, element, startIndex, this.length);
  }

  int lastIndexOf(int element, int startIndex) {
    return _Lists.lastIndexOf(this, element, startIndex);
  }

  int clear() {
    throw new UnsupportedOperationException("Cannot clear immutable List.");
  }

  int removeLast() {
    throw new UnsupportedOperationException("Cannot removeLast on immutable List.");
  }

  int last() {
    return this[length - 1];
  }

  void forEach(void f(int element)) {
    _Collections.forEach(this, f);
  }

  Collection<int> filter(bool f(int element)) {
    return _Collections.filter(this, new List<int>(), f);
  }

  bool every(bool f(int element)) {
    return _Collections.every(this, f);
  }

  bool some(bool f(int element)) {
    return _Collections.some(this, f);
  }

  bool isEmpty() {
    return length == 0;
  }

  Iterator<int> iterator() {
    return new _FixedSizeListIterator<int>(this);
  }

  int item(int index) {
    return _item(this, index);
  }
  static int _item(receiver, index) native;

  String get typeName() { return "CanvasPixelArray"; }
}
