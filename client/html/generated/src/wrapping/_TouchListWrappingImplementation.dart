// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TouchListWrappingImplementation extends DOMWrapperBase implements TouchList {
  TouchListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

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

  int indexOf(Touch element, int startIndex) {
    return _Lists.indexOf(this, element, startIndex, this.length);
  }

  int lastIndexOf(Touch element, int startIndex) {
    return _Lists.lastIndexOf(this, element, startIndex);
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

  bool isEmpty() {
    return length == 0;
  }

  Iterator<Touch> iterator() {
    return new _FixedSizeListIterator<Touch>(this);
  }

  Touch item(int index) {
    return LevelDom.wrapTouch(_ptr.item(index));
  }

  String get typeName() { return "TouchList"; }
}
