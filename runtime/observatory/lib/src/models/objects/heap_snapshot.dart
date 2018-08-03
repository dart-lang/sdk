// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

enum HeapSnapshotRoots { user, vm }

abstract class HeapSnapshot {
  DateTime get timestamp;
  int get objects;
  int get references;
  int get size;
  HeapSnapshotDominatorNode get dominatorTree;
  HeapSnapshotMergedDominatorNode get mergedDominatorTree;
  Iterable<HeapSnapshotClassReferences> get classReferences;
  Iterable<HeapSnapshotOwnershipClass> get ownershipClasses;
}

abstract class HeapSnapshotDominatorNode {
  int get shallowSize;
  int get retainedSize;
  bool get isStack;
  Future<ObjectRef> get object;
  Iterable<HeapSnapshotDominatorNode> get children;
}

abstract class HeapSnapshotMergedDominatorNode {
  int get instanceCount;
  int get shallowSize;
  int get retainedSize;
  bool get isStack;
  Future<ObjectRef> get klass;
  Iterable<HeapSnapshotMergedDominatorNode> get children;
}

abstract class HeapSnapshotClassReferences {
  ClassRef get clazz;
  int get instances;
  int get shallowSize;
  int get retainedSize;
  Iterable<HeapSnapshotClassInbound> get inbounds;
  Iterable<HeapSnapshotClassOutbound> get outbounds;
}

abstract class HeapSnapshotClassInbound {
  ClassRef get source;
  int get count;
  int get shallowSize;
  int get retainedSize;
}

abstract class HeapSnapshotClassOutbound {
  ClassRef get target;
  int get count;
  int get shallowSize;
  int get retainedSize;
}

abstract class HeapSnapshotOwnershipClass {
  ClassRef get clazz;
  int get size;
}
