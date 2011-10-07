// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CharacterDataWrappingImplementation extends NodeWrappingImplementation implements CharacterData {
  CharacterDataWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get data() { return _ptr.data; }

  void set data(String value) { _ptr.data = value; }

  int get length() { return _ptr.length; }

  void appendData(String data) {
    _ptr.appendData(data);
    return;
  }

  void deleteData(int offset, int length) {
    _ptr.deleteData(offset, length);
    return;
  }

  void insertData(int offset, String data) {
    _ptr.insertData(offset, data);
    return;
  }

  void replaceData(int offset, int length, String data) {
    _ptr.replaceData(offset, length, data);
    return;
  }

  String substringData(int offset, int length) {
    return _ptr.substringData(offset, length);
  }
}
