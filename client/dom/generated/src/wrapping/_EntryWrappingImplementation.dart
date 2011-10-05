// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _EntryWrappingImplementation extends DOMWrapperBase implements Entry {
  _EntryWrappingImplementation() : super() {}

  static create__EntryWrappingImplementation() native {
    return new _EntryWrappingImplementation();
  }

  DOMFileSystem get filesystem() { return _get__Entry_filesystem(this); }
  static DOMFileSystem _get__Entry_filesystem(var _this) native;

  String get fullPath() { return _get__Entry_fullPath(this); }
  static String _get__Entry_fullPath(var _this) native;

  bool get isDirectory() { return _get__Entry_isDirectory(this); }
  static bool _get__Entry_isDirectory(var _this) native;

  bool get isFile() { return _get__Entry_isFile(this); }
  static bool _get__Entry_isFile(var _this) native;

  String get name() { return _get__Entry_name(this); }
  static String _get__Entry_name(var _this) native;

  void copyTo(DirectoryEntry parent, String name = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null) {
    if (name === null) {
      if (successCallback === null) {
        if (errorCallback === null) {
          _copyTo(this, parent);
          return;
        }
      }
    } else {
      if (successCallback === null) {
        if (errorCallback === null) {
          _copyTo_2(this, parent, name);
          return;
        }
      } else {
        if (errorCallback === null) {
          _copyTo_3(this, parent, name, successCallback);
          return;
        } else {
          _copyTo_4(this, parent, name, successCallback, errorCallback);
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _copyTo(receiver, parent) native;
  static void _copyTo_2(receiver, parent, name) native;
  static void _copyTo_3(receiver, parent, name, successCallback) native;
  static void _copyTo_4(receiver, parent, name, successCallback, errorCallback) native;

  void getMetadata(MetadataCallback successCallback = null, ErrorCallback errorCallback = null) {
    if (successCallback === null) {
      if (errorCallback === null) {
        _getMetadata(this);
        return;
      }
    } else {
      if (errorCallback === null) {
        _getMetadata_2(this, successCallback);
        return;
      } else {
        _getMetadata_3(this, successCallback, errorCallback);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _getMetadata(receiver) native;
  static void _getMetadata_2(receiver, successCallback) native;
  static void _getMetadata_3(receiver, successCallback, errorCallback) native;

  void getParent(EntryCallback successCallback = null, ErrorCallback errorCallback = null) {
    if (successCallback === null) {
      if (errorCallback === null) {
        _getParent(this);
        return;
      }
    } else {
      if (errorCallback === null) {
        _getParent_2(this, successCallback);
        return;
      } else {
        _getParent_3(this, successCallback, errorCallback);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _getParent(receiver) native;
  static void _getParent_2(receiver, successCallback) native;
  static void _getParent_3(receiver, successCallback, errorCallback) native;

  void moveTo(DirectoryEntry parent, String name = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null) {
    if (name === null) {
      if (successCallback === null) {
        if (errorCallback === null) {
          _moveTo(this, parent);
          return;
        }
      }
    } else {
      if (successCallback === null) {
        if (errorCallback === null) {
          _moveTo_2(this, parent, name);
          return;
        }
      } else {
        if (errorCallback === null) {
          _moveTo_3(this, parent, name, successCallback);
          return;
        } else {
          _moveTo_4(this, parent, name, successCallback, errorCallback);
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _moveTo(receiver, parent) native;
  static void _moveTo_2(receiver, parent, name) native;
  static void _moveTo_3(receiver, parent, name, successCallback) native;
  static void _moveTo_4(receiver, parent, name, successCallback, errorCallback) native;

  void remove(VoidCallback successCallback = null, ErrorCallback errorCallback = null) {
    if (successCallback === null) {
      if (errorCallback === null) {
        _remove(this);
        return;
      }
    } else {
      if (errorCallback === null) {
        _remove_2(this, successCallback);
        return;
      } else {
        _remove_3(this, successCallback, errorCallback);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _remove(receiver) native;
  static void _remove_2(receiver, successCallback) native;
  static void _remove_3(receiver, successCallback, errorCallback) native;

  String toURL() {
    return _toURL(this);
  }
  static String _toURL(receiver) native;

  String get typeName() { return "Entry"; }
}
