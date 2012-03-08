// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DOMURLWrappingImplementation extends DOMWrapperBase implements DOMURL {
  _DOMURLWrappingImplementation() : super() {}

  static create__DOMURLWrappingImplementation() native {
    return new _DOMURLWrappingImplementation();
  }

  String createObjectURL(var blob_OR_stream) {
    if (blob_OR_stream is MediaStream) {
      return _createObjectURL(this, blob_OR_stream);
    } else {
      if (blob_OR_stream is Blob) {
        return _createObjectURL_2(this, blob_OR_stream);
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static String _createObjectURL(receiver, blob_OR_stream) native;
  static String _createObjectURL_2(receiver, blob_OR_stream) native;

  void revokeObjectURL(String url) {
    _revokeObjectURL(this, url);
    return;
  }
  static void _revokeObjectURL(receiver, url) native;

  String get typeName() { return "DOMURL"; }
}
