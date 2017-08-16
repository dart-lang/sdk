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

  const SampleProfileLoadingProgressMock(
      {this.status: M.SampleProfileLoadingStatus.disabled,
      this.progress: 0.0,
      this.fetchingTime: const Duration(),
      this.loadingTime: const Duration(),
      this.profile});
}

typedef Stream<
    M
        .SampleProfileLoadingProgressEvent> ClassSampleProfileRepositoryMockCallback(
    M.Isolate isolate,
    M.ClassRef cls,
    M.SampleProfileTag tag,
    bool clear,
    bool forceFetch);
typedef Future ClassSampleProfileRepositoryMockToggleCallback(
    M.Isolate isolate, M.ClassRef cls);

class ClassSampleProfileRepositoryMock
    implements M.ClassSampleProfileRepository {
  final ClassSampleProfileRepositoryMockCallback _get;
  final ClassSampleProfileRepositoryMockToggleCallback _enable;
  final ClassSampleProfileRepositoryMockToggleCallback _disable;

  Stream<M.SampleProfileLoadingProgressEvent> get(
      M.Isolate isolate, M.ClassRef cls, M.SampleProfileTag tag,
      {bool clear: false, bool forceFetch: false}) {
    if (_get != null) {
      return _get(isolate, cls, tag, clear, forceFetch);
    }
    return null;
  }

  Future enable(M.Isolate isolate, M.ClassRef cls) {
    if (_enable != null) {
      return _enable(isolate, cls);
    }
    return new Future.value();
  }

  Future disable(M.Isolate isolate, M.ClassRef cls) {
    if (_disable != null) {
      return _disable(isolate, cls);
    }
    return new Future.value();
  }

  ClassSampleProfileRepositoryMock(
      {ClassSampleProfileRepositoryMockCallback getter,
      ClassSampleProfileRepositoryMockToggleCallback enable,
      ClassSampleProfileRepositoryMockToggleCallback disable})
      : _get = getter,
        _enable = enable,
        _disable = disable;
}

typedef Stream<
    M
        .SampleProfileLoadingProgressEvent> IsolateampleProfileRepositoryMockCallback(
    M.IsolateRef cls, M.SampleProfileTag tag, bool clear, bool forceFetch);

class IsolateSampleProfileRepositoryMock
    implements M.IsolateSampleProfileRepository {
  final IsolateampleProfileRepositoryMockCallback _get;

  Stream<M.SampleProfileLoadingProgressEvent> get(
      M.IsolateRef isolate, M.SampleProfileTag tag,
      {bool clear: false, bool forceFetch: false}) {
    if (_get != null) {
      return _get(isolate, tag, clear, forceFetch);
    }
    return null;
  }

  IsolateSampleProfileRepositoryMock(
      {IsolateampleProfileRepositoryMockCallback getter})
      : _get = getter;
}
