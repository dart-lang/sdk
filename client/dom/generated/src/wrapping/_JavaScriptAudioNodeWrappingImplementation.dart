// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _JavaScriptAudioNodeWrappingImplementation extends _AudioNodeWrappingImplementation implements JavaScriptAudioNode {
  _JavaScriptAudioNodeWrappingImplementation() : super() {}

  static create__JavaScriptAudioNodeWrappingImplementation() native {
    return new _JavaScriptAudioNodeWrappingImplementation();
  }

  int get bufferSize() { return _get_bufferSize(this); }
  static int _get_bufferSize(var _this) native;

  String get typeName() { return "JavaScriptAudioNode"; }
}
