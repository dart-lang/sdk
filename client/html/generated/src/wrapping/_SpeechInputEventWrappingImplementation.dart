// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SpeechInputEventWrappingImplementation extends EventWrappingImplementation implements SpeechInputEvent {
  SpeechInputEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  SpeechInputResultList get results() { return LevelDom.wrapSpeechInputResultList(_ptr.results); }
}
