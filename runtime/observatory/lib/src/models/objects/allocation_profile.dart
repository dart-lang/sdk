// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of models;

abstract class AllocationProfile {
  DateTime get lastServiceGC;
  DateTime get lastAccumulatorReset;
  HeapSpace get newSpace;
  HeapSpace get oldSpace;
  HeapSpace get totalSpace;
  Iterable<ClassHeapStats> get members;
}

abstract class ClassHeapStats {
  /// [Optional] at least one between clazz and displayName should be non null
  ClassRef get clazz;

  /// [Optional] at least one between clazz and displayName should be non null
  String get displayName;
  Allocations get newSpace;
  Allocations get oldSpace;
}

abstract class Allocations {
  int instances = 0;
  int internalSize = 0;
  int externalSize = 0;
  int size = 0;
}
