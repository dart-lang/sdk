// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SpeechInputResultListWrappingImplementation extends DOMWrapperBase implements SpeechInputResultList {
  _SpeechInputResultListWrappingImplementation() : super() {}

  static create__SpeechInputResultListWrappingImplementation() native {
    return new _SpeechInputResultListWrappingImplementation();
  }

  int get length() { return _get__SpeechInputResultList_length(this); }
  static int _get__SpeechInputResultList_length(var _this) native;

  SpeechInputResult item(int index) {
    return _item(this, index);
  }
  static SpeechInputResult _item(receiver, index) native;

  String get typeName() { return "SpeechInputResultList"; }
}
