// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class MediaListWrappingImplementation extends DOMWrapperBase implements MediaList {
  MediaListWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get length() { return _ptr.length; }

  String get mediaText() { return _ptr.mediaText; }

  void set mediaText(String value) { _ptr.mediaText = value; }

  String operator[](int index) {
    return item(index);
  }

  void operator[]=(int index, String value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable Array.");
  }

  void add(String value) {
    throw new UnsupportedOperationException("Cannot add to immutable Array.");
  }

  void addLast(String value) {
    throw new UnsupportedOperationException("Cannot add to immutable Array.");
  }

  void addAll(Collection<String> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable Array.");
  }

  void sort(int compare(String a, String b)) {
    throw new UnsupportedOperationException("Cannot sort immutable Array.");
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw new UnsupportedOperationException("This object is immutable.");
  }

  int indexOf(String element, int startIndex) {
    return _Lists.indexOf(this, element, startIndex, this.length);
  }

  int lastIndexOf(String element, int startIndex) {
    return _Lists.lastIndexOf(this, element, startIndex);
  }

  int clear() {
    throw new UnsupportedOperationException("Cannot clear immutable Array.");
  }

  String removeLast() {
    throw new UnsupportedOperationException("Cannot removeLast on immutable Array.");
  }

  String last() {
    return this[length - 1];
  }

  void forEach(void f(String element)) {
    _Collections.forEach(this, f);
  }

  Collection<String> filter(bool f(String element)) {
    return _Collections.filter(this, new List<String>(), f);
  }

  bool every(bool f(String element)) {
    return _Collections.every(this, f);
  }

  bool some(bool f(String element)) {
    return _Collections.some(this, f);
  }

  bool isEmpty() {
    return length == 0;
  }

  Iterator<String> iterator() {
    return new _FixedSizeListIterator<String>(this);
  }

  void appendMedium(String newMedium) {
    _ptr.appendMedium(newMedium);
    return;
  }

  void deleteMedium(String oldMedium) {
    _ptr.deleteMedium(oldMedium);
    return;
  }

  String item(int index) {
    return _ptr.item(index);
  }

  String get typeName() { return "MediaList"; }
}
