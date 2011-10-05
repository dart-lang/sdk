// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _FileReaderSyncWrappingImplementation extends DOMWrapperBase implements FileReaderSync {
  _FileReaderSyncWrappingImplementation() : super() {}

  static create__FileReaderSyncWrappingImplementation() native {
    return new _FileReaderSyncWrappingImplementation();
  }

  ArrayBuffer readAsArrayBuffer(Blob blob) {
    return _readAsArrayBuffer(this, blob);
  }
  static ArrayBuffer _readAsArrayBuffer(receiver, blob) native;

  String readAsBinaryString(Blob blob) {
    return _readAsBinaryString(this, blob);
  }
  static String _readAsBinaryString(receiver, blob) native;

  String readAsDataURL(Blob blob) {
    return _readAsDataURL(this, blob);
  }
  static String _readAsDataURL(receiver, blob) native;

  String readAsText(Blob blob, String encoding = null) {
    if (encoding === null) {
      return _readAsText(this, blob);
    } else {
      return _readAsText_2(this, blob, encoding);
    }
  }
  static String _readAsText(receiver, blob) native;
  static String _readAsText_2(receiver, blob, encoding) native;

  String get typeName() { return "FileReaderSync"; }
}
