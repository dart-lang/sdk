// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _BlobWrappingImplementation extends DOMWrapperBase implements Blob {
  _BlobWrappingImplementation() : super() {}

  static create__BlobWrappingImplementation() native {
    return new _BlobWrappingImplementation();
  }

  int get size() { return _get_size(this); }
  static int _get_size(var _this) native;

  String get type() { return _get_type(this); }
  static String _get_type(var _this) native;

  Blob webkitSlice([int start = null, int end = null, String contentType = null]) {
    if (start === null) {
      if (end === null) {
        if (contentType === null) {
          return _webkitSlice(this);
        }
      }
    } else {
      if (end === null) {
        if (contentType === null) {
          return _webkitSlice_2(this, start);
        }
      } else {
        if (contentType === null) {
          return _webkitSlice_3(this, start, end);
        } else {
          return _webkitSlice_4(this, start, end, contentType);
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static Blob _webkitSlice(receiver) native;
  static Blob _webkitSlice_2(receiver, start) native;
  static Blob _webkitSlice_3(receiver, start, end) native;
  static Blob _webkitSlice_4(receiver, start, end, contentType) native;

  String get typeName() { return "Blob"; }
}
