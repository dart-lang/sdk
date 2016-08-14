// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of mocks;

class SampleProfileLoadingProgressEventMock
    implements M.SampleProfileLoadingProgressEvent {
  final M.SampleProfileLoadingProgress progress;
  SampleProfileLoadingProgressEventMock({this.progress});
}

class SampleProfileLoadingProgressMock
    implements M.SampleProfileLoadingProgress {
  final M.SampleProfileLoadingStatus status;
  final double progress;
  final Duration fetchingTime;
  final Duration loadingTime;
  final M.SampleProfile profile;

  const SampleProfileLoadingProgressMock({
      this.status: M.SampleProfileLoadingStatus.disabled,
      this.progress: 0.0,
      this.fetchingTime: const Duration(),
      this.loadingTime: const Duration(),
      this.profile
    });
}

typedef Stream<M.SampleProfileLoadingProgressEvent>
    ClassSampleProfileRepositoryMockCallback(M.ClassRef cls,
        M.SampleProfileTag tag, bool clear);

class ClassSampleProfileRepositoryMock
    implements M.ClassSampleProfileRepository {
  final ClassSampleProfileRepositoryMockCallback _get;

  Stream<M.SampleProfileLoadingProgressEvent> get(M.ClassRef cls,
      M.SampleProfileTag tag, {bool clear: false}) {
    if (_get != null) {
      return _get(cls, tag, clear);
    }
    return null;
  }

  ClassSampleProfileRepositoryMock(
      {ClassSampleProfileRepositoryMockCallback getter})
    : _get = getter;
}

typedef Stream<M.SampleProfileLoadingProgressEvent>
    IsolateampleProfileRepositoryMockCallback(M.IsolateRef cls,
        M.SampleProfileTag tag, bool clear, bool forceFetch);

class IsolateSampleProfileRepositoryMock
    implements M.IsolateSampleProfileRepository {
  final IsolateampleProfileRepositoryMockCallback _get;

  Stream<M.SampleProfileLoadingProgressEvent> get(M.IsolateRef isolate,
      M.SampleProfileTag tag, {bool clear: false, bool forceFetch: false}) {
    if (_get != null) {
      return _get(isolate, tag, clear, forceFetch);
    }
    return null;
  }

  IsolateSampleProfileRepositoryMock(
      {IsolateampleProfileRepositoryMockCallback getter})
    : _get = getter;
}
