// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _OfflineAudioCompletionEventWrappingImplementation extends _EventWrappingImplementation implements OfflineAudioCompletionEvent {
  _OfflineAudioCompletionEventWrappingImplementation() : super() {}

  static create__OfflineAudioCompletionEventWrappingImplementation() native {
    return new _OfflineAudioCompletionEventWrappingImplementation();
  }

  AudioBuffer get renderedBuffer() { return _get_renderedBuffer(this); }
  static AudioBuffer _get_renderedBuffer(var _this) native;

  String get typeName() { return "OfflineAudioCompletionEvent"; }
}
