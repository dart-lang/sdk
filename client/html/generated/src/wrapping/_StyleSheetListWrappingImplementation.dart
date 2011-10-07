// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class StyleSheetListWrappingImplementation extends DOMWrapperBase implements StyleSheetList {
  StyleSheetListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  StyleSheet operator[](int index) {
    return item(index);
  }

  void operator[]=(int index, StyleSheet value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable Array.");
  }

  void add(StyleSheet value) {
    throw new UnsupportedOperationException("Cannot add to immutable Array.");
  }

  void addLast(StyleSheet value) {
    throw new UnsupportedOperationException("Cannot add to immutable Array.");
  }

  void addAll(Collection<StyleSheet> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable Array.");
  }

  void sort(int compare(StyleSheet a, StyleSheet b)) {
    throw new UnsupportedOperationException("Cannot sort immutable Array.");
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw new UnsupportedOperationException("This object is immutable.");
  }

  void setRange(int start, int length, List from, [int startFrom = 0]) {
    throw const NotImplementedException();
  }

  void removeRange(int start, int length) {
    throw const NotImplementedException();
  }

  void insertRange(int start, int length, [initialValue = null]) {
    throw const NotImplementedException();
  }

  List getRange(int start, int length) {
    throw const NotImplementedException();
  }

  int indexOf(StyleSheet element, int startIndex) {
    return _Lists.indexOf(this, element, startIndex, this.length);
  }

  int lastIndexOf(StyleSheet element, int startIndex) {
    return _Lists.lastIndexOf(this, element, startIndex);
  }

  int clear() {
    throw new UnsupportedOperationException("Cannot clear immutable Array.");
  }

  StyleSheet removeLast() {
    throw new UnsupportedOperationException("Cannot removeLast on immutable Array.");
  }

  StyleSheet last() {
    return this[length - 1];
  }

  void forEach(void f(StyleSheet element)) {
    _Collections.forEach(this, f);
  }

  Collection<StyleSheet> filter(bool f(StyleSheet element)) {
    return _Collections.filter(this, new List<StyleSheet>(), f);
  }

  bool every(bool f(StyleSheet element)) {
    return _Collections.every(this, f);
  }

  bool some(bool f(StyleSheet element)) {
    return _Collections.some(this, f);
  }

  bool isEmpty() {
    return length == 0;
  }

  Iterator<StyleSheet> iterator() {
    return new _FixedSizeListIterator<StyleSheet>(this);
  }

  StyleSheet item(int index) {
    return LevelDom.wrapStyleSheet(_ptr.item(index));
  }

  String get typeName() { return "StyleSheetList"; }
}
