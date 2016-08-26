// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

part of models;

enum SampleProfileTag {
  userVM,
  userOnly,
  vmUser,
  vmOnly,
  none
}

enum SampleProfileLoadingStatus {
  disabled,
  fetching,
  loading,
  loaded
}

bool isSampleProcessRunning(SampleProfileLoadingStatus status) {
  switch (status) {
    case SampleProfileLoadingStatus.fetching:
    case SampleProfileLoadingStatus.loading:
      return true;
    default:
      return false;
  }
}

abstract class SampleProfileLoadingProgressEvent {
  SampleProfileLoadingProgress get progress;
}

abstract class SampleProfileLoadingProgress {
  SampleProfileLoadingStatus get status;
  double get progress;
  Duration get fetchingTime;
  Duration get loadingTime;
  SampleProfile get profile;
}

abstract class ClassSampleProfileRepository {
  Stream<SampleProfileLoadingProgressEvent> get(ClassRef cls,
      SampleProfileTag tag, {bool clear: false});
}

abstract class IsolateSampleProfileRepository {
  Stream<SampleProfileLoadingProgressEvent> get(IsolateRef cls,
      SampleProfileTag tag, {bool clear: false, bool forceFetch: false});
}
