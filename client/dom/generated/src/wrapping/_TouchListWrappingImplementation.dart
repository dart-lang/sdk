// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _TouchListWrappingImplementation extends DOMWrapperBase implements TouchList {
  _TouchListWrappingImplementation() : super() {}

  static create__TouchListWrappingImplementation() native {
    return new _TouchListWrappingImplementation();
  }

  int get length() { return _get_length(this); }
  static int _get_length(var _this) native;

  Touch operator[](int index) {
    return item(index);
  }

  void operator[]=(int index, Touch value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  void add(Touch value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(Touch value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<Touch> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void sort(int compare(Touch a, Touch b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw new UnsupportedOperationException("This object is immutable.");
  }

  int indexOf(Touch element, [int start = 0]) {
    return _Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(Touch element, [int start = null]) {
    if (start === null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int clear() {
    throw new UnsupportedOperationException("Cannot clear immutable List.");
  }

  Touch removeLast() {
    throw new UnsupportedOperationException("Cannot removeLast on immutable List.");
  }

  Touch last() {
    return this[length - 1];
  }

  void forEach(void f(Touch element)) {
    _Collections.forEach(this, f);
  }

  Collection<Touch> filter(bool f(Touch element)) {
    return _Collections.filter(this, new List<Touch>(), f);
  }

  bool every(bool f(Touch element)) {
    return _Collections.every(this, f);
  }

  bool some(bool f(Touch element)) {
    return _Collections.some(this, f);
  }

  void setRange(int start, int length, List<Touch> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int length, [Touch initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }

  List<Touch> getRange(int start, int length) {
    throw new NotImplementedException();
  }

  bool isEmpty() {
    return length == 0;
  }

  Iterator<Touch> iterator() {
    return new _FixedSizeListIterator<Touch>(this);
  }

  Touch item(int index) {
    return _item(this, index);
  }
  static Touch _item(receiver, index) native;

  String get typeName() { return "TouchList"; }
}
