// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of models;

enum HeapSnapshotLoadingStatus { fetching, loading, loaded }

bool isHeapSnapshotProgressRunning(HeapSnapshotLoadingStatus status) {
  switch (status) {
    case HeapSnapshotLoadingStatus.fetching:
    case HeapSnapshotLoadingStatus.loading:
      return true;
    default:
      return false;
  }
}

abstract class HeapSnapshotLoadingProgressEvent {
  HeapSnapshotLoadingProgress get progress;
}

abstract class HeapSnapshotLoadingProgress {
  HeapSnapshotLoadingStatus get status;
  String get stepDescription;
  double get progress;
  Duration get fetchingTime;
  Duration get loadingTime;
  HeapSnapshot get snapshot;
}

abstract class HeapSnapshotRepository {
  Stream<HeapSnapshotLoadingProgressEvent> get(
      IsolateRef isolate,
      {HeapSnapshotRoots roots: HeapSnapshotRoots.vm,
      bool gc: false});
}
