// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _AudioNodeWrappingImplementation extends DOMWrapperBase implements AudioNode {
  _AudioNodeWrappingImplementation() : super() {}

  static create__AudioNodeWrappingImplementation() native {
    return new _AudioNodeWrappingImplementation();
  }

  AudioContext get context() { return _get_context(this); }
  static AudioContext _get_context(var _this) native;

  int get numberOfInputs() { return _get_numberOfInputs(this); }
  static int _get_numberOfInputs(var _this) native;

  int get numberOfOutputs() { return _get_numberOfOutputs(this); }
  static int _get_numberOfOutputs(var _this) native;

  void connect(AudioNode destination, [int output = null, int input = null]) {
    if (output === null) {
      if (input === null) {
        _connect(this, destination);
        return;
      }
    } else {
      if (input === null) {
        _connect_2(this, destination, output);
        return;
      } else {
        _connect_3(this, destination, output, input);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _connect(receiver, destination) native;
  static void _connect_2(receiver, destination, output) native;
  static void _connect_3(receiver, destination, output, input) native;

  void disconnect([int output = null]) {
    if (output === null) {
      _disconnect(this);
      return;
    } else {
      _disconnect_2(this, output);
      return;
    }
  }
  static void _disconnect(receiver) native;
  static void _disconnect_2(receiver, output) native;

  String get typeName() { return "AudioNode"; }
}
