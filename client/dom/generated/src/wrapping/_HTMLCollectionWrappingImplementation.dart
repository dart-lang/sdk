// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLCollectionWrappingImplementation extends DOMWrapperBase implements HTMLCollection {
  _HTMLCollectionWrappingImplementation() : super() {}

  static create__HTMLCollectionWrappingImplementation() native {
    return new _HTMLCollectionWrappingImplementation();
  }

  int get length() { return _get_length(this); }
  static int _get_length(var _this) native;

  Node operator[](int index) {
    return item(index);
  }

  void operator[]=(int index, Node value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  void add(Node value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(Node value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<Node> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void sort(int compare(Node a, Node b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
  }

  void copyFrom(List<Object> src, int srcStart, int dstStart, int count) {
    throw new UnsupportedOperationException("This object is immutable.");
  }

  int indexOf(Node element, [int start = 0]) {
    return _Lists.indexOf(this, element, start, this.length);
  }

  int lastIndexOf(Node element, [int start = null]) {
    if (start === null) start = length - 1;
    return _Lists.lastIndexOf(this, element, start);
  }

  int clear() {
    throw new UnsupportedOperationException("Cannot clear immutable List.");
  }

  Node removeLast() {
    throw new UnsupportedOperationException("Cannot removeLast on immutable List.");
  }

  Node last() {
    return this[length - 1];
  }

  void forEach(void f(Node element)) {
    _Collections.forEach(this, f);
  }

  Collection<Node> filter(bool f(Node element)) {
    return _Collections.filter(this, new List<Node>(), f);
  }

  bool every(bool f(Node element)) {
    return _Collections.every(this, f);
  }

  bool some(bool f(Node element)) {
    return _Collections.some(this, f);
  }

  void setRange(int start, int length, List<Node> from, [int startFrom]) {
    throw new UnsupportedOperationException("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int length) {
    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");
  }

  void insertRange(int start, int length, [Node initialValue]) {
    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");
  }

  List<Node> getRange(int start, int length) {
    throw new NotImplementedException();
  }

  bool isEmpty() {
    return length == 0;
  }

  Iterator<Node> iterator() {
    return new _FixedSizeListIterator<Node>(this);
  }

  Node item(int index) {
    return _item(this, index);
  }
  static Node _item(receiver, index) native;

  Node namedItem(String name) {
    return _namedItem(this, name);
  }
  static Node _namedItem(receiver, name) native;

  String get typeName() { return "HTMLCollection"; }
}
