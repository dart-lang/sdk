// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WebKitBlobBuilderWrappingImplementation extends DOMWrapperBase implements WebKitBlobBuilder {
  _WebKitBlobBuilderWrappingImplementation() : super() {}

  static create__WebKitBlobBuilderWrappingImplementation() native {
    return new _WebKitBlobBuilderWrappingImplementation();
  }

  void append(var blob_OR_value, String endings = null) {
    if (blob_OR_value is Blob) {
      if (endings === null) {
        _append(this, blob_OR_value);
        return;
      }
    } else {
      if (blob_OR_value is String) {
        if (endings === null) {
          _append_2(this, blob_OR_value);
          return;
        } else {
          _append_3(this, blob_OR_value, endings);
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _append(receiver, blob_OR_value) native;
  static void _append_2(receiver, blob_OR_value) native;
  static void _append_3(receiver, blob_OR_value, endings) native;

  Blob getBlob(String contentType = null) {
    if (contentType === null) {
      return _getBlob(this);
    } else {
      return _getBlob_2(this, contentType);
    }
  }
  static Blob _getBlob(receiver) native;
  static Blob _getBlob_2(receiver, contentType) native;

  String get typeName() { return "WebKitBlobBuilder"; }
}
