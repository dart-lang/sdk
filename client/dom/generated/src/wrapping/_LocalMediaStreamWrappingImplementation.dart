// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _LocalMediaStreamWrappingImplementation extends _MediaStreamWrappingImplementation implements LocalMediaStream {
  _LocalMediaStreamWrappingImplementation() : super() {}

  static create__LocalMediaStreamWrappingImplementation() native {
    return new _LocalMediaStreamWrappingImplementation();
  }

  void stop() {
    _stop(this);
    return;
  }
  static void _stop(receiver) native;

  String get typeName() { return "LocalMediaStream"; }
}
