// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _MediaElementAudioSourceNodeWrappingImplementation extends _AudioSourceNodeWrappingImplementation implements MediaElementAudioSourceNode {
  _MediaElementAudioSourceNodeWrappingImplementation() : super() {}

  static create__MediaElementAudioSourceNodeWrappingImplementation() native {
    return new _MediaElementAudioSourceNodeWrappingImplementation();
  }

  HTMLMediaElement get mediaElement() { return _get_mediaElement(this); }
  static HTMLMediaElement _get_mediaElement(var _this) native;

  String get typeName() { return "MediaElementAudioSourceNode"; }
}
