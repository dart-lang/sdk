// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("dart:mirrors");

import "dart:isolate";

part "../../../mirrors/mirrors.dart";

/**
 * Stub class for the mirror system.
 */
class _Mirrors {
  static MirrorSystem currentMirrorSystem() {
    throw new UnsupportedOperationException("MirrorSystem not implemented");
  }

  static Future<MirrorSystem> mirrorSystemOf(SendPort port) {
    throw new UnsupportedOperationException("MirrorSystem not implemented");
  }

  static InstanceMirror reflect(Object reflectee) {
    throw new UnsupportedOperationException("MirrorSystem not implemented");
  }
}
