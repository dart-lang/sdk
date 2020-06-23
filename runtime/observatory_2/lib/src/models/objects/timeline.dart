// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class TimelineRecorder {
  String get name;
}

abstract class TimelineStream {
  String get name;
  bool get isRecorded;
}

abstract class TimelineProfile {
  String get name;
  Iterable<TimelineStream> get streams;
}

abstract class TimelineFlags {
  TimelineRecorder get recorder;
  Iterable<TimelineStream> get streams;
  Iterable<TimelineProfile> get profiles;
}
