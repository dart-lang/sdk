// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DataTransferItemListWrappingImplementation extends DOMWrapperBase implements DataTransferItemList {
  _DataTransferItemListWrappingImplementation() : super() {}

  static create__DataTransferItemListWrappingImplementation() native {
    return new _DataTransferItemListWrappingImplementation();
  }

  int get length() { return _get_length(this); }
  static int _get_length(var _this) native;

  void add(var data_OR_file, [String type = null]) {
    if (data_OR_file is File) {
      if (type === null) {
        _add(this, data_OR_file);
        return;
      }
    } else {
      if (data_OR_file is String) {
        _add_2(this, data_OR_file, type);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _add(receiver, data_OR_file) native;
  static void _add_2(receiver, data_OR_file, type) native;

  void clear() {
    _clear(this);
    return;
  }
  static void _clear(receiver) native;

  DataTransferItem item(int index) {
    return _item(this, index);
  }
  static DataTransferItem _item(receiver, index) native;

  String get typeName() { return "DataTransferItemList"; }
}
