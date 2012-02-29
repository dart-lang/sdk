// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _EntryWrappingImplementation extends DOMWrapperBase implements Entry {
  _EntryWrappingImplementation() : super() {}

  static create__EntryWrappingImplementation() native {
    return new _EntryWrappingImplementation();
  }

  DOMFileSystem get filesystem() { return _get_filesystem(this); }
  static DOMFileSystem _get_filesystem(var _this) native;

  String get fullPath() { return _get_fullPath(this); }
  static String _get_fullPath(var _this) native;

  bool get isDirectory() { return _get_isDirectory(this); }
  static bool _get_isDirectory(var _this) native;

  bool get isFile() { return _get_isFile(this); }
  static bool _get_isFile(var _this) native;

  String get name() { return _get_name(this); }
  static String _get_name(var _this) native;

  void copyTo(DirectoryEntry parent, [String name = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) {
    _copyTo(this, parent, name, successCallback, errorCallback);
    return;
  }
  static void _copyTo(receiver, parent, name, successCallback, errorCallback) native;

  void getMetadata(MetadataCallback successCallback, [ErrorCallback errorCallback = null]) {
    _getMetadata(this, successCallback, errorCallback);
    return;
  }
  static void _getMetadata(receiver, successCallback, errorCallback) native;

  void getParent([EntryCallback successCallback = null, ErrorCallback errorCallback = null]) {
    _getParent(this, successCallback, errorCallback);
    return;
  }
  static void _getParent(receiver, successCallback, errorCallback) native;

  void moveTo(DirectoryEntry parent, [String name = null, EntryCallback successCallback = null, ErrorCallback errorCallback = null]) {
    _moveTo(this, parent, name, successCallback, errorCallback);
    return;
  }
  static void _moveTo(receiver, parent, name, successCallback, errorCallback) native;

  void remove(VoidCallback successCallback, [ErrorCallback errorCallback = null]) {
    _remove(this, successCallback, errorCallback);
    return;
  }
  static void _remove(receiver, successCallback, errorCallback) native;

  String toURL() {
    return _toURL(this);
  }
  static String _toURL(receiver) native;

  String get typeName() { return "Entry"; }
}
