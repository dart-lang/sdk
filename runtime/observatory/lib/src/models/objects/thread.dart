// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

enum ThreadKind {
  unknownTask,
  mutatorTask,
  compilerTask,
  sweeperTask,
  markerTask,
  finalizerTask
}

abstract class Thread {
  /// The id associated with the thread on creation.
  String get id;

  /// The task type associated with the thread.
  ThreadKind get kind;

  /// The maximum amount of memory in bytes allocated by a thread at a given
  /// time throughout the entire life of the thread.
  int get memoryHighWatermark;

  /// A list of all the zones held by the thread.
  Iterable<Zone> get zones;
}
