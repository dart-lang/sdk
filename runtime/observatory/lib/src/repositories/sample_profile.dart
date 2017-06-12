// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of repositories;

String _tagToString(M.SampleProfileTag tag) {
  switch (tag) {
    case M.SampleProfileTag.userVM:
      return 'UserVM';
    case M.SampleProfileTag.userOnly:
      return 'UserOnly';
    case M.SampleProfileTag.vmUser:
      return 'VMUser';
    case M.SampleProfileTag.vmOnly:
      return 'VMOnly';
    case M.SampleProfileTag.none:
      return 'None';
  }
  throw new Exception('Unknown SampleProfileTag: $tag');
}

class SampleProfileLoadingProgressEvent
    implements M.SampleProfileLoadingProgressEvent {
  final SampleProfileLoadingProgress progress;
  SampleProfileLoadingProgressEvent(this.progress);
}

class SampleProfileLoadingProgress extends M.SampleProfileLoadingProgress {
  StreamController<SampleProfileLoadingProgressEvent> _onProgress =
      new StreamController<SampleProfileLoadingProgressEvent>.broadcast();
  Stream<SampleProfileLoadingProgressEvent> get onProgress =>
      _onProgress.stream;

  final M.ServiceObjectOwner owner;
  final S.Class cls;
  final M.SampleProfileTag tag;
  final bool clear;
  final M.SampleProfileType type;

  M.SampleProfileLoadingStatus _status = M.SampleProfileLoadingStatus.fetching;
  double _progress = 0.0;
  final Stopwatch _fetchingTime = new Stopwatch();
  final Stopwatch _loadingTime = new Stopwatch();
  CpuProfile _profile;

  M.SampleProfileLoadingStatus get status => _status;
  double get progress => _progress;
  Duration get fetchingTime => _fetchingTime.elapsed;
  Duration get loadingTime => _loadingTime.elapsed;
  CpuProfile get profile => _profile;

  SampleProfileLoadingProgress(this.owner, this.tag, this.clear,
      {this.type: M.SampleProfileType.cpu, this.cls}) {
    _run();
  }

  Future _run() async {
    _fetchingTime.start();
    try {
      if (clear && (type == M.SampleProfileType.cpu)) {
        await owner.invokeRpc('_clearCpuProfile', {});
      }

      var response;
      if (type == M.SampleProfileType.cpu) {
        response = cls != null
            ? await cls.getAllocationSamples(_tagToString(tag))
            : await owner
                .invokeRpc('_getCpuProfile', {'tags': _tagToString(tag)});
      } else if (type == M.SampleProfileType.memory) {
        assert(owner is M.VM);
        response = await owner.invokeRpc(
            '_getNativeAllocationSamples', {'tags': _tagToString(tag)});
      } else {
        throw new Exception('Unknown M.SampleProfileType: $type');
      }

      _fetchingTime.stop();
      _loadingTime.start();
      _status = M.SampleProfileLoadingStatus.loading;
      _triggerOnProgress();

      CpuProfile profile = new CpuProfile();

      Stream<double> progress = profile.loadProgress(owner, response);
      progress.listen((value) {
        _progress = value;
        _triggerOnProgress();
      });

      await progress.drain();

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
    _onProgress.add(new SampleProfileLoadingProgressEvent(this));
  }

  void reuse() {
    _onProgress =
        new StreamController<SampleProfileLoadingProgressEvent>.broadcast();
    (() async {
      _triggerOnProgress();
      _onProgress.close();
    }());
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
      _last.reuse();
    } else {
      _last = new SampleProfileLoadingProgress(isolate, t, clear);
    }
    return _last.onProgress;
  }
}

class ClassSampleProfileRepository implements M.ClassSampleProfileRepository {
  Stream<SampleProfileLoadingProgressEvent> get(
      M.Isolate i, M.ClassRef c, M.SampleProfileTag t) {
    S.Isolate isolate = i as S.Isolate;
    S.Class cls = c as S.Class;
    assert(isolate != null);
    assert(cls != null);
    return new SampleProfileLoadingProgress(isolate, t, false, cls: cls)
        .onProgress;
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
    if ((_last != null) && !forceFetch) {
      _last.reuse();
    } else {
      _last = new SampleProfileLoadingProgress(vm, t, false,
          type: M.SampleProfileType.memory);
    }
    return _last.onProgress;
  }
}
