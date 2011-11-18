// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _XMLHttpRequestProgressEventWrappingImplementation extends _ProgressEventWrappingImplementation implements XMLHttpRequestProgressEvent {
  _XMLHttpRequestProgressEventWrappingImplementation() : super() {}

  static create__XMLHttpRequestProgressEventWrappingImplementation() native {
    return new _XMLHttpRequestProgressEventWrappingImplementation();
  }

  int get position() { return _get_position(this); }
  static int _get_position(var _this) native;

  int get totalSize() { return _get_totalSize(this); }
  static int _get_totalSize(var _this) native;

  String get typeName() { return "XMLHttpRequestProgressEvent"; }
}
