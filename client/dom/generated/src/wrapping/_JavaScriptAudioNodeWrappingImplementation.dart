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

  EventListener get onaudioprocess() { return _get_onaudioprocess(this); }
  static EventListener _get_onaudioprocess(var _this) native;

  void set onaudioprocess(EventListener value) { _set_onaudioprocess(this, value); }
  static void _set_onaudioprocess(var _this, EventListener value) native;

  String get typeName() { return "JavaScriptAudioNode"; }
}
