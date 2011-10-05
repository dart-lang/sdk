// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SpeechInputEventWrappingImplementation extends _EventWrappingImplementation implements SpeechInputEvent {
  _SpeechInputEventWrappingImplementation() : super() {}

  static create__SpeechInputEventWrappingImplementation() native {
    return new _SpeechInputEventWrappingImplementation();
  }

  SpeechInputResultList get results() { return _get__SpeechInputEvent_results(this); }
  static SpeechInputResultList _get__SpeechInputEvent_results(var _this) native;

  String get typeName() { return "SpeechInputEvent"; }
}
