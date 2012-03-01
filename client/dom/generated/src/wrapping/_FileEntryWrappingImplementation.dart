// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _FileEntryWrappingImplementation extends _EntryWrappingImplementation implements FileEntry {
  _FileEntryWrappingImplementation() : super() {}

  static create__FileEntryWrappingImplementation() native {
    return new _FileEntryWrappingImplementation();
  }

  void createWriter(FileWriterCallback successCallback, [ErrorCallback errorCallback = null]) {
    if (errorCallback === null) {
      _createWriter(this, successCallback);
      return;
    } else {
      _createWriter_2(this, successCallback, errorCallback);
      return;
    }
  }
  static void _createWriter(receiver, successCallback) native;
  static void _createWriter_2(receiver, successCallback, errorCallback) native;

  void file(FileCallback successCallback, [ErrorCallback errorCallback = null]) {
    if (errorCallback === null) {
      _file(this, successCallback);
      return;
    } else {
      _file_2(this, successCallback, errorCallback);
      return;
    }
  }
  static void _file(receiver, successCallback) native;
  static void _file_2(receiver, successCallback, errorCallback) native;

  String get typeName() { return "FileEntry"; }
}
