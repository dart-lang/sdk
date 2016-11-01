// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of mocks;

class HeapSnapshotLoadingProgressEventMock
    implements M.HeapSnapshotLoadingProgressEvent {
  final M.HeapSnapshotLoadingProgress progress;

  const HeapSnapshotLoadingProgressEventMock(
      {this.progress: const HeapSnapshotLoadingProgressMock()});
}

class HeapSnapshotLoadingProgressMock implements M.HeapSnapshotLoadingProgress {
  final M.HeapSnapshotLoadingStatus status;
  final String stepDescription;
  final double progress;
  final Duration fetchingTime;
  final Duration loadingTime;
  final M.HeapSnapshot snapshot;

  const HeapSnapshotLoadingProgressMock({
      this.status : M.HeapSnapshotLoadingStatus.fetching, this.progress: 0.0,
      this.stepDescription: '', this.fetchingTime, this.loadingTime,
      this.snapshot});
}

typedef Stream<M.HeapSnapshotLoadingProgressEvent>
    HeapSnapshotRepositoryMockCallback(M.IsolateRef cls, bool gc);

class HeapSnapshotRepositoryMock
    implements M.HeapSnapshotRepository {
  final HeapSnapshotRepositoryMockCallback _get;

  Stream<M.HeapSnapshotLoadingProgressEvent> get(M.IsolateRef isolate,
                                               {bool gc: false}) {
    if (_get != null) {
      return _get(isolate, gc);
    }
    return null;
  }

  HeapSnapshotRepositoryMock(
      {HeapSnapshotRepositoryMockCallback getter})
    : _get = getter;
}
