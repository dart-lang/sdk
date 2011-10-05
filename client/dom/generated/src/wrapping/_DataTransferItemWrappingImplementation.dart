// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DataTransferItemWrappingImplementation extends DOMWrapperBase implements DataTransferItem {
  _DataTransferItemWrappingImplementation() : super() {}

  static create__DataTransferItemWrappingImplementation() native {
    return new _DataTransferItemWrappingImplementation();
  }

  String get kind() { return _get__DataTransferItem_kind(this); }
  static String _get__DataTransferItem_kind(var _this) native;

  String get type() { return _get__DataTransferItem_type(this); }
  static String _get__DataTransferItem_type(var _this) native;

  Blob getAsFile() {
    return _getAsFile(this);
  }
  static Blob _getAsFile(receiver) native;

  void getAsString(StringCallback callback = null) {
    if (callback === null) {
      _getAsString(this);
      return;
    } else {
      _getAsString_2(this, callback);
      return;
    }
  }
  static void _getAsString(receiver) native;
  static void _getAsString_2(receiver, callback) native;

  String get typeName() { return "DataTransferItem"; }
}
