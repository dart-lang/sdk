// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _NamedNodeMapWrappingImplementation extends DOMWrapperBase implements NamedNodeMap {
  _NamedNodeMapWrappingImplementation() : super() {}

  static create__NamedNodeMapWrappingImplementation() native {
    return new _NamedNodeMapWrappingImplementation();
  }

  int get length() { return _get__NamedNodeMap_length(this); }
  static int _get__NamedNodeMap_length(var _this) native;

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

  int indexOf(Node element, int startIndex) {
    return _Lists.indexOf(this, element, startIndex, this.length);
  }

  int lastIndexOf(Node element, int startIndex) {
    return _Lists.lastIndexOf(this, element, startIndex);
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

  bool isEmpty() {
    return length == 0;
  }

  Iterator<Node> iterator() {
    return new _FixedSizeListIterator<Node>(this);
  }

  Node getNamedItem([String name = null]) {
    if (name === null) {
      return _getNamedItem(this);
    } else {
      return _getNamedItem_2(this, name);
    }
  }
  static Node _getNamedItem(receiver) native;
  static Node _getNamedItem_2(receiver, name) native;

  Node getNamedItemNS([String namespaceURI = null, String localName = null]) {
    if (namespaceURI === null) {
      if (localName === null) {
        return _getNamedItemNS(this);
      }
    } else {
      if (localName === null) {
        return _getNamedItemNS_2(this, namespaceURI);
      } else {
        return _getNamedItemNS_3(this, namespaceURI, localName);
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static Node _getNamedItemNS(receiver) native;
  static Node _getNamedItemNS_2(receiver, namespaceURI) native;
  static Node _getNamedItemNS_3(receiver, namespaceURI, localName) native;

  Node item([int index = null]) {
    if (index === null) {
      return _item(this);
    } else {
      return _item_2(this, index);
    }
  }
  static Node _item(receiver) native;
  static Node _item_2(receiver, index) native;

  Node removeNamedItem([String name = null]) {
    if (name === null) {
      return _removeNamedItem(this);
    } else {
      return _removeNamedItem_2(this, name);
    }
  }
  static Node _removeNamedItem(receiver) native;
  static Node _removeNamedItem_2(receiver, name) native;

  Node removeNamedItemNS([String namespaceURI = null, String localName = null]) {
    if (namespaceURI === null) {
      if (localName === null) {
        return _removeNamedItemNS(this);
      }
    } else {
      if (localName === null) {
        return _removeNamedItemNS_2(this, namespaceURI);
      } else {
        return _removeNamedItemNS_3(this, namespaceURI, localName);
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static Node _removeNamedItemNS(receiver) native;
  static Node _removeNamedItemNS_2(receiver, namespaceURI) native;
  static Node _removeNamedItemNS_3(receiver, namespaceURI, localName) native;

  Node setNamedItem([Node node = null]) {
    if (node === null) {
      return _setNamedItem(this);
    } else {
      return _setNamedItem_2(this, node);
    }
  }
  static Node _setNamedItem(receiver) native;
  static Node _setNamedItem_2(receiver, node) native;

  Node setNamedItemNS([Node node = null]) {
    if (node === null) {
      return _setNamedItemNS(this);
    } else {
      return _setNamedItemNS_2(this, node);
    }
  }
  static Node _setNamedItemNS(receiver) native;
  static Node _setNamedItemNS_2(receiver, node) native;

  String get typeName() { return "NamedNodeMap"; }
}
