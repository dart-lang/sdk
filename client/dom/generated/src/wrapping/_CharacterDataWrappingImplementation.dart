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

  void appendData(String data = null) {
    if (data === null) {
      _appendData(this);
      return;
    } else {
      _appendData_2(this, data);
      return;
    }
  }
  static void _appendData(receiver) native;
  static void _appendData_2(receiver, data) native;

  void deleteData(int offset = null, int length = null) {
    if (offset === null) {
      if (length === null) {
        _deleteData(this);
        return;
      }
    } else {
      if (length === null) {
        _deleteData_2(this, offset);
        return;
      } else {
        _deleteData_3(this, offset, length);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _deleteData(receiver) native;
  static void _deleteData_2(receiver, offset) native;
  static void _deleteData_3(receiver, offset, length) native;

  void insertData(int offset = null, String data = null) {
    if (offset === null) {
      if (data === null) {
        _insertData(this);
        return;
      }
    } else {
      if (data === null) {
        _insertData_2(this, offset);
        return;
      } else {
        _insertData_3(this, offset, data);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _insertData(receiver) native;
  static void _insertData_2(receiver, offset) native;
  static void _insertData_3(receiver, offset, data) native;

  void replaceData(int offset = null, int length = null, String data = null) {
    if (offset === null) {
      if (length === null) {
        if (data === null) {
          _replaceData(this);
          return;
        }
      }
    } else {
      if (length === null) {
        if (data === null) {
          _replaceData_2(this, offset);
          return;
        }
      } else {
        if (data === null) {
          _replaceData_3(this, offset, length);
          return;
        } else {
          _replaceData_4(this, offset, length, data);
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _replaceData(receiver) native;
  static void _replaceData_2(receiver, offset) native;
  static void _replaceData_3(receiver, offset, length) native;
  static void _replaceData_4(receiver, offset, length, data) native;

  String substringData(int offset = null, int length = null) {
    if (offset === null) {
      if (length === null) {
        return _substringData(this);
      }
    } else {
      if (length === null) {
        return _substringData_2(this, offset);
      } else {
        return _substringData_3(this, offset, length);
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static String _substringData(receiver) native;
  static String _substringData_2(receiver, offset) native;
  static String _substringData_3(receiver, offset, length) native;

  String get typeName() { return "CharacterData"; }
}
