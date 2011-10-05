// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class LocalMediaStreamWrappingImplementation extends MediaStreamWrappingImplementation implements LocalMediaStream {
  LocalMediaStreamWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  void stop() {
    _ptr.stop();
    return;
  }

  String get typeName() { return "LocalMediaStream"; }
}
