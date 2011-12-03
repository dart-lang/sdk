// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _AudioDestinationNodeWrappingImplementation extends _AudioNodeWrappingImplementation implements AudioDestinationNode {
  _AudioDestinationNodeWrappingImplementation() : super() {}

  static create__AudioDestinationNodeWrappingImplementation() native {
    return new _AudioDestinationNodeWrappingImplementation();
  }

  int get numberOfChannels() { return _get_numberOfChannels(this); }
  static int _get_numberOfChannels(var _this) native;

  String get typeName() { return "AudioDestinationNode"; }
}
