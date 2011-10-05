// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MediaListWrappingImplementation extends DOMWrapperBase implements MediaList {
  _MediaListWrappingImplementation() : super() {}

  static create__MediaListWrappingImplementation() native {
    return new _MediaListWrappingImplementation();
  }

  int get length() { return _get__MediaList_length(this); }
  static int _get__MediaList_length(var _this) native;

  String get mediaText() { return _get__MediaList_mediaText(this); }
  static String _get__MediaList_mediaText(var _this) native;

  void set mediaText(String value) { _set__MediaList_mediaText(this, value); }
  static void _set__MediaList_mediaText(var _this, String value) native;

  String operator[](int index) {
    return item(index);
  }

  void operator[]=(int index, String value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  void add(String value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addLast(String value) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void addAll(Collection<String> collection) {
    throw new UnsupportedOperationException("Cannot add to immutable List.");
  }

  void sort(int compare(String a, String b)) {
    throw new UnsupportedOperationException("Cannot sort immutable List.");
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
    throw new UnsupportedOperationException("Cannot clear immutable List.");
  }

  String removeLast() {
    throw new UnsupportedOperationException("Cannot removeLast on immutable List.");
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

  void appendMedium(String newMedium = null) {
    if (newMedium === null) {
      _appendMedium(this);
      return;
    } else {
      _appendMedium_2(this, newMedium);
      return;
    }
  }
  static void _appendMedium(receiver) native;
  static void _appendMedium_2(receiver, newMedium) native;

  void deleteMedium(String oldMedium = null) {
    if (oldMedium === null) {
      _deleteMedium(this);
      return;
    } else {
      _deleteMedium_2(this, oldMedium);
      return;
    }
  }
  static void _deleteMedium(receiver) native;
  static void _deleteMedium_2(receiver, oldMedium) native;

  String item(int index = null) {
    if (index === null) {
      return _item(this);
    } else {
      return _item_2(this, index);
    }
  }
  static String _item(receiver) native;
  static String _item_2(receiver, index) native;

  String get typeName() { return "MediaList"; }
}
