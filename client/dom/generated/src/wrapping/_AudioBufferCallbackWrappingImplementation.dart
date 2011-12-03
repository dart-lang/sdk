// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _AudioBufferCallbackWrappingImplementation extends DOMWrapperBase implements AudioBufferCallback {
  _AudioBufferCallbackWrappingImplementation() : super() {}

  static create__AudioBufferCallbackWrappingImplementation() native {
    return new _AudioBufferCallbackWrappingImplementation();
  }

  bool handleEvent(AudioBuffer audioBuffer) {
    return _handleEvent(this, audioBuffer);
  }
  static bool _handleEvent(receiver, audioBuffer) native;

  String get typeName() { return "AudioBufferCallback"; }
}
