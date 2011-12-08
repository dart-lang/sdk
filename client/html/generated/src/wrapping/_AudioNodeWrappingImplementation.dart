// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AudioNodeWrappingImplementation extends DOMWrapperBase implements AudioNode {
  AudioNodeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  AudioContext get context() { return LevelDom.wrapAudioContext(_ptr.context); }

  int get numberOfInputs() { return _ptr.numberOfInputs; }

  int get numberOfOutputs() { return _ptr.numberOfOutputs; }

  void connect(AudioNode destination, [int output, int input]) {
    if (output === null) {
      if (input === null) {
        _ptr.connect(LevelDom.unwrap(destination));
        return;
      }
    } else {
      if (input === null) {
        _ptr.connect(LevelDom.unwrap(destination), output);
        return;
      } else {
        _ptr.connect(LevelDom.unwrap(destination), output, input);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void disconnect([int output]) {
    if (output === null) {
      _ptr.disconnect();
      return;
    } else {
      _ptr.disconnect(output);
      return;
    }
  }
}
