// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MemoryInfoWrappingImplementation extends DOMWrapperBase implements MemoryInfo {
  _MemoryInfoWrappingImplementation() : super() {}

  static create__MemoryInfoWrappingImplementation() native {
    return new _MemoryInfoWrappingImplementation();
  }

  int get jsHeapSizeLimit() { return _get__MemoryInfo_jsHeapSizeLimit(this); }
  static int _get__MemoryInfo_jsHeapSizeLimit(var _this) native;

  int get totalJSHeapSize() { return _get__MemoryInfo_totalJSHeapSize(this); }
  static int _get__MemoryInfo_totalJSHeapSize(var _this) native;

  int get usedJSHeapSize() { return _get__MemoryInfo_usedJSHeapSize(this); }
  static int _get__MemoryInfo_usedJSHeapSize(var _this) native;

  String get typeName() { return "MemoryInfo"; }
}
