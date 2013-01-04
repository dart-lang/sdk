// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Returns a [MirrorSystem] for the current isolate.
 */
patch MirrorSystem currentMirrorSystem() {
  return _Mirrors.currentMirrorSystem();
}

/**
 * Creates a [MirrorSystem] for the isolate which is listening on
 * the [SendPort].
 */
patch Future<MirrorSystem> mirrorSystemOf(SendPort port) {
  return _Mirrors.mirrorSystemOf(port);
}

/**
 * Returns an [InstanceMirror] for some Dart language object.
 *
 * This only works if this mirror system is associated with the
 * current running isolate.
 */
patch InstanceMirror reflect(Object reflectee) {
  return _Mirrors.reflect(reflectee);
}
