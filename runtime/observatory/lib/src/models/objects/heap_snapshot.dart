// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class HeapSnapshot {
  DateTime get timestamp;
  int get objects;
  int get references;
  int get size;
  HeapSnapshotDominatorNode get dominatorTree;
  Iterable<HeapSnapshotClassReferences> get classReferences;
}

abstract class HeapSnapshotDominatorNode {
  int get shallowSize;
  int get retainedSize;
  Future<ObjectRef> get object;
  Iterable<HeapSnapshotDominatorNode> get children;
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
