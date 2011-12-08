// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DelayNodeWrappingImplementation extends _AudioNodeWrappingImplementation implements DelayNode {
  _DelayNodeWrappingImplementation() : super() {}

  static create__DelayNodeWrappingImplementation() native {
    return new _DelayNodeWrappingImplementation();
  }

  AudioParam get delayTime() { return _get_delayTime(this); }
  static AudioParam _get_delayTime(var _this) native;

  String get typeName() { return "DelayNode"; }
}
