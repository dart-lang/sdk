// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DataTransferItemsWrappingImplementation extends DOMWrapperBase implements DataTransferItems {
  _DataTransferItemsWrappingImplementation() : super() {}

  static create__DataTransferItemsWrappingImplementation() native {
    return new _DataTransferItemsWrappingImplementation();
  }

  int get length() { return _get__DataTransferItems_length(this); }
  static int _get__DataTransferItems_length(var _this) native;

  void add(String data, String type) {
    _add(this, data, type);
    return;
  }
  static void _add(receiver, data, type) native;

  void clear() {
    _clear(this);
    return;
  }
  static void _clear(receiver) native;

  DataTransferItem item(int index) {
    return _item(this, index);
  }
  static DataTransferItem _item(receiver, index) native;

  String get typeName() { return "DataTransferItems"; }
}
