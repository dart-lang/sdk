// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mocks;

class HeapSnapshotMock implements M.HeapSnapshot {
  final DateTime timestamp;
  final int objects;
  final int references;
  final int size;
  final M.HeapSnapshotDominatorNode dominatorTree;
  final M.HeapSnapshotMergedDominatorNode mergedDominatorTree = null;
  final Iterable<M.HeapSnapshotClassReferences> classReferences;
  final Iterable<M.HeapSnapshotOwnershipClass> ownershipClasses;

  const HeapSnapshotMock(
      {this.timestamp,
      this.objects: 0,
      this.references: 0,
      this.size: 0,
      this.dominatorTree: const HeapSnapshotDominatorNodeMock(),
      this.classReferences: const [],
      this.ownershipClasses: const []});
}

class HeapSnapshotDominatorNodeMock implements M.HeapSnapshotDominatorNode {
  final int shallowSize;
  final int retainedSize;
  final bool isStack = false;
  final Future<M.ObjectRef> object;
  final Iterable<M.HeapSnapshotDominatorNode> children;

  const HeapSnapshotDominatorNodeMock(
      {this.shallowSize: 1,
      this.retainedSize: 1,
      this.object,
      this.children: const []});
}

class HeapSnapshotClassReferencesMock implements M.HeapSnapshotClassReferences {
  final M.ClassRef clazz;
  final int instances;
  final int shallowSize;
  final int retainedSize;
  final Iterable<M.HeapSnapshotClassInbound> inbounds;
  final Iterable<M.HeapSnapshotClassOutbound> outbounds;

  const HeapSnapshotClassReferencesMock(
      {this.clazz: const ClassRefMock(),
      this.instances: 1,
      this.shallowSize: 1,
      this.retainedSize: 2,
      this.inbounds: const [],
      this.outbounds: const []});
}

class HeapSnapshotClassInboundMock implements M.HeapSnapshotClassInbound {
  final M.ClassRef source;
  final int count;
  final int shallowSize;
  final int retainedSize;

  const HeapSnapshotClassInboundMock(
      {this.source: const ClassRefMock(),
      this.count: 1,
      this.shallowSize: 1,
      this.retainedSize: 2});
}

class HeapSnapshotClassOutboundMock implements M.HeapSnapshotClassOutbound {
  final M.ClassRef target;
  final int count;
  final int shallowSize;
  final int retainedSize;
  const HeapSnapshotClassOutboundMock(
      {this.target: const ClassRefMock(),
      this.count: 1,
      this.shallowSize: 1,
      this.retainedSize: 2});
}
