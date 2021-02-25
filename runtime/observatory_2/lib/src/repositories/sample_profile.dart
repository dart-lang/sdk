// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

class SampleProfileLoadingProgressEvent
    implements M.SampleProfileLoadingProgressEvent {
  final SampleProfileLoadingProgress progress;
  SampleProfileLoadingProgressEvent(this.progress);
}

class SampleProfileLoadingProgress extends M.SampleProfileLoadingProgress {
  StreamController<SampleProfileLoadingProgressEvent> _onProgress =
      StreamController<SampleProfileLoadingProgressEvent>.broadcast();
  Stream<SampleProfileLoadingProgressEvent> get onProgress =>
      _onProgress.stream;

  final S.ServiceObjectOwner owner;
  final S.Class cls;
  final M.SampleProfileTag tag;
  final bool clear;
  final M.SampleProfileType type;

  M.SampleProfileLoadingStatus _status = M.SampleProfileLoadingStatus.fetching;
  double _progress = 0.0;
  final _fetchingTime = Stopwatch();
  final _loadingTime = Stopwatch();
  SampleProfile _profile;

  M.SampleProfileLoadingStatus get status => _status;
  double get progress => _progress;
  Duration get fetchingTime => _fetchingTime.elapsed;
  Duration get loadingTime => _loadingTime.elapsed;
  SampleProfile get profile => _profile;

  SampleProfileLoadingProgress(this.owner, this.tag, this.clear,
      {this.type: M.SampleProfileType.cpu, this.cls}) {
    _run();
  }

  Future _run() async {
    _fetchingTime.start();
    try {
      if (clear && (type == M.SampleProfileType.cpu)) {
        await owner.invokeRpc('clearCpuSamples', {});
      }

      var response;
      if (type == M.SampleProfileType.cpu) {
        response = cls != null
            ? await cls.getAllocationSamples()
            : await owner.invokeRpc('getCpuSamples', {'_code': true});
      } else if (type == M.SampleProfileType.memory) {
        assert(owner is M.VM);
        response = await owner
            .invokeRpc('_getNativeAllocationSamples', {'_code': true});
      } else {
        throw Exception('Unknown M.SampleProfileType: $type');
      }

      _fetchingTime.stop();
      _loadingTime.start();
      _status = M.SampleProfileLoadingStatus.loading;
      _triggerOnProgress();

      SampleProfile profile = SampleProfile();
      Stream<double> progress = profile.loadProgress(owner, response);
      progress.listen((value) {
        _progress = value;
        _triggerOnProgress();
      });

      await progress.drain();

      profile.tagOrder = tag;
      profile.buildFunctionCallerAndCallees();
      _profile = profile;

      _loadingTime.stop();
      _status = M.SampleProfileLoadingStatus.loaded;
      _triggerOnProgress();
    } catch (e) {
      if (e is S.ServerRpcException) {
        if (e.code == S.ServerRpcException.kFeatureDisabled) {
          _status = M.SampleProfileLoadingStatus.disabled;
          _triggerOnProgress();
        }
      }
      rethrow;
    } finally {
      _onProgress.close();
    }
  }

  void _triggerOnProgress() {
    _onProgress.add(SampleProfileLoadingProgressEvent(this));
  }

  void reuse(M.SampleProfileTag t) {
    _profile.tagOrder = t;
    final onProgress =
        StreamController<SampleProfileLoadingProgressEvent>.broadcast();
    Timer.run(() {
      onProgress.add(SampleProfileLoadingProgressEvent(this));
      onProgress.close();
    });
    _onProgress = onProgress;
  }
}

class IsolateSampleProfileRepository
    implements M.IsolateSampleProfileRepository {
  SampleProfileLoadingProgress _last;

  Stream<SampleProfileLoadingProgressEvent> get(
      M.IsolateRef i, M.SampleProfileTag t,
      {bool clear: false, bool forceFetch: false}) {
    assert(clear != null);
    assert(forceFetch != null);
    S.Isolate isolate = i as S.Isolate;
    assert(isolate != null);
    if ((_last != null) && !clear && !forceFetch && (_last.owner == isolate)) {
      _last.reuse(t);
    } else {
      _last = SampleProfileLoadingProgress(isolate, t, clear);
    }
    return _last.onProgress;
  }
}

class ClassSampleProfileRepository implements M.ClassSampleProfileRepository {
  Stream<SampleProfileLoadingProgressEvent> get(
      covariant M.Isolate i, M.ClassRef c, M.SampleProfileTag t,
      {bool clear: false, bool forceFetch: false}) {
    S.Isolate isolate = i as S.Isolate;
    S.Class cls = c as S.Class;
    assert(isolate != null);
    assert(cls != null);
    return SampleProfileLoadingProgress(isolate, t, false, cls: cls).onProgress;
  }

  Future enable(M.IsolateRef i, M.ClassRef c) {
    S.Class cls = c as S.Class;
    assert(cls != null);
    return cls.setTraceAllocations(true);
  }

  Future disable(M.IsolateRef i, M.ClassRef c) {
    S.Class cls = c as S.Class;
    assert(cls != null);
    return cls.setTraceAllocations(false);
  }
}

class NativeMemorySampleProfileRepository
    implements M.NativeMemorySampleProfileRepository {
  SampleProfileLoadingProgress _last;

  Stream<SampleProfileLoadingProgressEvent> get(M.VM vm, M.SampleProfileTag t,
      {bool forceFetch: false, bool clear: false}) {
    assert(forceFetch != null);
    S.VM owner = vm as S.VM;
    assert(owner != null);

    if ((_last != null) && (_last.profile != null) && !forceFetch) {
      _last.reuse(t);
    } else {
      _last = SampleProfileLoadingProgress(owner, t, false,
          type: M.SampleProfileType.memory);
    }
    return _last.onProgress;
  }
}
