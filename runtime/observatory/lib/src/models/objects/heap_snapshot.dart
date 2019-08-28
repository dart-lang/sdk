// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class HeapSnapshot {
  DateTime get timestamp;
  int get size;
  SnapshotObject get root;
  HeapSnapshotMergedDominatorNode get mergedDominatorTree;
  Iterable<SnapshotClass> get classes;
  List<ByteData> get chunks;
}

abstract class HeapSnapshotMergedDominatorNode {
  int get instanceCount;
  int get shallowSize;
  int get retainedSize;
  SnapshotClass get klass;
  Iterable<HeapSnapshotMergedDominatorNode> get children;
}
