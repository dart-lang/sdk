// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ClipboardWrappingImplementation extends DOMWrapperBase implements Clipboard {
  ClipboardWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get dropEffect() { return _ptr.dropEffect; }

  void set dropEffect(String value) { _ptr.dropEffect = value; }

  String get effectAllowed() { return _ptr.effectAllowed; }

  void set effectAllowed(String value) { _ptr.effectAllowed = value; }

  FileList get files() { return LevelDom.wrapFileList(_ptr.files); }

  DataTransferItemList get items() { return LevelDom.wrapDataTransferItemList(_ptr.items); }

  List get types() { return _ptr.types; }

  void clearData([String type]) {
    if (type === null) {
      _ptr.clearData();
      return;
    } else {
      _ptr.clearData(type);
      return;
    }
  }

  void getData(String type) {
    _ptr.getData(type);
    return;
  }

  bool setData(String type, String data) {
    return _ptr.setData(type, data);
  }

  void setDragImage(ImageElement image, int x, int y) {
    _ptr.setDragImage(LevelDom.unwrap(image), x, y);
    return;
  }
}
