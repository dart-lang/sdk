// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class HeapSnapshotLoadingProgressEvent
    implements M.HeapSnapshotLoadingProgressEvent {
  final HeapSnapshotLoadingProgress progress;
  HeapSnapshotLoadingProgressEvent(this.progress);
}

class HeapSnapshotLoadingProgress extends M.HeapSnapshotLoadingProgress {
  StreamController<HeapSnapshotLoadingProgressEvent> _onProgress =
      new StreamController<HeapSnapshotLoadingProgressEvent>.broadcast();
  Stream<HeapSnapshotLoadingProgressEvent> get onProgress => _onProgress.stream;

  final S.Isolate isolate;
  final M.HeapSnapshotRoots roots;
  final bool gc;

  M.HeapSnapshotLoadingStatus _status = M.HeapSnapshotLoadingStatus.fetching;
  String _stepDescription = '';
  double _progress = 0.0;
  final Stopwatch _fetchingTime = new Stopwatch();
  final Stopwatch _loadingTime = new Stopwatch();
  HeapSnapshot _snapshot;

  M.HeapSnapshotLoadingStatus get status => _status;
  String get stepDescription => _stepDescription;
  double get progress => _progress;
  Duration get fetchingTime => _fetchingTime.elapsed;
  Duration get loadingTime => _loadingTime.elapsed;
  HeapSnapshot get snapshot => _snapshot;

  HeapSnapshotLoadingProgress(this.isolate, this.roots, this.gc) {
    _run();
  }

  Future _run() async {
    _fetchingTime.start();
    try {
      _status = M.HeapSnapshotLoadingStatus.fetching;
      _triggerOnProgress();

      await isolate.getClassRefs();

      final stream = isolate.fetchHeapSnapshot(roots, gc);

      stream.listen((status) {
        if (status is List) {
          _progress = status[0] * 100.0 / status[1];
          _stepDescription = 'Receiving snapshot chunk ${status[0] + 1}'
              ' of ${status[1]}...';
          _triggerOnProgress();
        }
      });

      final response = await stream.last;

      _fetchingTime.stop();
      _loadingTime.start();
      _status = M.HeapSnapshotLoadingStatus.loading;
      _stepDescription = '';
      _triggerOnProgress();

      HeapSnapshot snapshot = new HeapSnapshot();

      Stream<List> progress = snapshot.loadProgress(isolate, response);
      progress.listen((value) {
        _stepDescription = value[0];
        _progress = value[1];
        _triggerOnProgress();
      });

      await progress.drain();

      _snapshot = snapshot;

      _loadingTime.stop();
      _status = M.HeapSnapshotLoadingStatus.loaded;
      _triggerOnProgress();
    } finally {
      _onProgress.close();
    }
  }

  void _triggerOnProgress() {
    _onProgress.add(new HeapSnapshotLoadingProgressEvent(this));
  }

  void reuse() {
    _onProgress =
        new StreamController<HeapSnapshotLoadingProgressEvent>.broadcast();
    (() async {
      _triggerOnProgress();
      _onProgress.close();
    }());
  }
}

class HeapSnapshotRepository implements M.HeapSnapshotRepository {
  Stream<HeapSnapshotLoadingProgressEvent> get(
      M.IsolateRef i,
      {M.HeapSnapshotRoots roots: M.HeapSnapshotRoots.vm,
      bool gc: false}) {
    S.Isolate isolate = i as S.Isolate;
    assert(isolate != null);
    assert(gc != null);
    return new HeapSnapshotLoadingProgress(isolate, roots, gc).onProgress;
  }
}
