// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SpeechInputResultWrappingImplementation extends DOMWrapperBase implements SpeechInputResult {
  _SpeechInputResultWrappingImplementation() : super() {}

  static create__SpeechInputResultWrappingImplementation() native {
    return new _SpeechInputResultWrappingImplementation();
  }

  num get confidence() { return _get__SpeechInputResult_confidence(this); }
  static num _get__SpeechInputResult_confidence(var _this) native;

  String get utterance() { return _get__SpeechInputResult_utterance(this); }
  static String _get__SpeechInputResult_utterance(var _this) native;

  String get typeName() { return "SpeechInputResult"; }
}
