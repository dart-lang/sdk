// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CharacterDataWrappingImplementation extends _NodeWrappingImplementation implements CharacterData {
  _CharacterDataWrappingImplementation() : super() {}

  static create__CharacterDataWrappingImplementation() native {
    return new _CharacterDataWrappingImplementation();
  }

  String get data() { return _get__CharacterData_data(this); }
  static String _get__CharacterData_data(var _this) native;

  void set data(String value) { _set__CharacterData_data(this, value); }
  static void _set__CharacterData_data(var _this, String value) native;

  int get length() { return _get__CharacterData_length(this); }
  static int _get__CharacterData_length(var _this) native;

  void appendData(String data) {
    _appendData(this, data);
    return;
  }
  static void _appendData(receiver, data) native;

  void deleteData(int offset, int length) {
    _deleteData(this, offset, length);
    return;
  }
  static void _deleteData(receiver, offset, length) native;

  void insertData(int offset, String data) {
    _insertData(this, offset, data);
    return;
  }
  static void _insertData(receiver, offset, data) native;

  void replaceData(int offset, int length, String data) {
    _replaceData(this, offset, length, data);
    return;
  }
  static void _replaceData(receiver, offset, length, data) native;

  String substringData(int offset, int length) {
    return _substringData(this, offset, length);
  }
  static String _substringData(receiver, offset, length) native;

  String get typeName() { return "CharacterData"; }
}
