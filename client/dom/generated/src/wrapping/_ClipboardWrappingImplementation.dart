// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _ClipboardWrappingImplementation extends DOMWrapperBase implements Clipboard {
  _ClipboardWrappingImplementation() : super() {}

  static create__ClipboardWrappingImplementation() native {
    return new _ClipboardWrappingImplementation();
  }

  String get dropEffect() { return _get__Clipboard_dropEffect(this); }
  static String _get__Clipboard_dropEffect(var _this) native;

  void set dropEffect(String value) { _set__Clipboard_dropEffect(this, value); }
  static void _set__Clipboard_dropEffect(var _this, String value) native;

  String get effectAllowed() { return _get__Clipboard_effectAllowed(this); }
  static String _get__Clipboard_effectAllowed(var _this) native;

  void set effectAllowed(String value) { _set__Clipboard_effectAllowed(this, value); }
  static void _set__Clipboard_effectAllowed(var _this, String value) native;

  FileList get files() { return _get__Clipboard_files(this); }
  static FileList _get__Clipboard_files(var _this) native;

  DataTransferItems get items() { return _get__Clipboard_items(this); }
  static DataTransferItems _get__Clipboard_items(var _this) native;

  void clearData([String type = null]) {
    if (type === null) {
      _clearData(this);
      return;
    } else {
      _clearData_2(this, type);
      return;
    }
  }
  static void _clearData(receiver) native;
  static void _clearData_2(receiver, type) native;

  void getData(String type) {
    _getData(this, type);
    return;
  }
  static void _getData(receiver, type) native;

  bool setData(String type, String data) {
    return _setData(this, type, data);
  }
  static bool _setData(receiver, type, data) native;

  void setDragImage(HTMLImageElement image, int x, int y) {
    _setDragImage(this, image, x, y);
    return;
  }
  static void _setDragImage(receiver, image, x, y) native;

  String get typeName() { return "Clipboard"; }
}
