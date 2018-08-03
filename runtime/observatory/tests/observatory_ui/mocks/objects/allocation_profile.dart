// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of mocks;

class AllocationProfileMock implements M.AllocationProfile {
  final DateTime lastServiceGC;
  final DateTime lastAccumulatorReset;
  final M.HeapSpace newSpace;
  final M.HeapSpace oldSpace;
  final Iterable<M.ClassHeapStats> members;

  const AllocationProfileMock(
      {this.lastServiceGC,
      this.lastAccumulatorReset,
      this.newSpace: const HeapSpaceMock(),
      this.oldSpace: const HeapSpaceMock(),
      this.members: const []});
}

class ClassHeapStatsMock implements M.ClassHeapStats {
  final M.ClassRef clazz;
  final String displayName;
  final M.Allocations newSpace;
  final M.Allocations oldSpace;
  final int promotedInstances;
  final int promotedBytes;

  const ClassHeapStatsMock(
      {this.clazz: const ClassRefMock(),
      this.displayName: null,
      this.newSpace: const AllocationsMock(),
      this.oldSpace: const AllocationsMock(),
      this.promotedInstances: 0,
      this.promotedBytes: 0});
}

class AllocationsMock implements M.Allocations {
  final M.AllocationCount accumulated;
  final M.AllocationCount current;

  const AllocationsMock(
      {this.accumulated: const AllocationCountMock(),
      this.current: const AllocationCountMock()});
}

class AllocationCountMock implements M.AllocationCount {
  final int instances;
  final int bytes;

  const AllocationCountMock({this.instances: 0, this.bytes: 0});
}
