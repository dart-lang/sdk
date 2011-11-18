// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MemoryInfoWrappingImplementation extends DOMWrapperBase implements MemoryInfo {
  _MemoryInfoWrappingImplementation() : super() {}

  static create__MemoryInfoWrappingImplementation() native {
    return new _MemoryInfoWrappingImplementation();
  }

  int get jsHeapSizeLimit() { return _get_jsHeapSizeLimit(this); }
  static int _get_jsHeapSizeLimit(var _this) native;

  int get totalJSHeapSize() { return _get_totalJSHeapSize(this); }
  static int _get_totalJSHeapSize(var _this) native;

  int get usedJSHeapSize() { return _get_usedJSHeapSize(this); }
  static int _get_usedJSHeapSize(var _this) native;

  String get typeName() { return "MemoryInfo"; }
}
