// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _BlobWrappingImplementation extends DOMWrapperBase implements Blob {
  _BlobWrappingImplementation() : super() {}

  static create__BlobWrappingImplementation() native {
    return new _BlobWrappingImplementation();
  }

  int get size() { return _get__Blob_size(this); }
  static int _get__Blob_size(var _this) native;

  String get type() { return _get__Blob_type(this); }
  static String _get__Blob_type(var _this) native;

  String get typeName() { return "Blob"; }
}
