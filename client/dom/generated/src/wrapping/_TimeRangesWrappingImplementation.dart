// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _TimeRangesWrappingImplementation extends DOMWrapperBase implements TimeRanges {
  _TimeRangesWrappingImplementation() : super() {}

  static create__TimeRangesWrappingImplementation() native {
    return new _TimeRangesWrappingImplementation();
  }

  int get length() { return _get__TimeRanges_length(this); }
  static int _get__TimeRanges_length(var _this) native;

  num end(int index) {
    return _end(this, index);
  }
  static num _end(receiver, index) native;

  num start(int index) {
    return _start(this, index);
  }
  static num _start(receiver, index) native;

  String get typeName() { return "TimeRanges"; }
}
