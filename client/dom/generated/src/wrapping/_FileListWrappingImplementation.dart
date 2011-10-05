// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _FileListWrappingImplementation extends DOMWrapperBase implements FileList {
  _FileListWrappingImplementation() : super() {}

  static create__FileListWrappingImplementation() native {
    return new _FileListWrappingImplementation();
  }

  int get length() { return _get__FileList_length(this); }
  static int _get__FileList_length(var _this) native;

  File item(int index) {
    return _item(this, index);
  }
  static File _item(receiver, index) native;

  String get typeName() { return "FileList"; }
}
