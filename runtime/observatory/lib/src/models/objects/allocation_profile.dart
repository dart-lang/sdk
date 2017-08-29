// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of models;

abstract class AllocationProfile {
  DateTime get lastServiceGC;
  DateTime get lastAccumulatorReset;
  HeapSpace get newSpace;
  HeapSpace get oldSpace;
  Iterable<ClassHeapStats> get members;
}

abstract class ClassHeapStats {
  /// [Optional] at least one between clazz and displayName should be non null
  ClassRef get clazz;

  /// [Optional] at least one between clazz and displayName should be non null
  String get displayName;
  Allocations get newSpace;
  Allocations get oldSpace;
  int get promotedInstances;
  int get promotedBytes;
}

abstract class Allocations {
  AllocationCount get accumulated;
  AllocationCount get current;
}

abstract class AllocationCount {
  int get instances;
  int get bytes;
}
