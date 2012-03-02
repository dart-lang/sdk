// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DirectoryReaderWrappingImplementation extends DOMWrapperBase implements DirectoryReader {
  _DirectoryReaderWrappingImplementation() : super() {}

  static create__DirectoryReaderWrappingImplementation() native {
    return new _DirectoryReaderWrappingImplementation();
  }

  void readEntries(EntriesCallback successCallback, [ErrorCallback errorCallback = null]) {
    _readEntries(this, successCallback, errorCallback);
    return;
  }
  static void _readEntries(receiver, successCallback, errorCallback) native;

  String get typeName() { return "DirectoryReader"; }
}
