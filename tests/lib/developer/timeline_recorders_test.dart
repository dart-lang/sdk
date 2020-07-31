// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// VMOptions=--timeline_streams=VM,Isolate,GC,Dart --timeline_recorder=endless
/// VMOptions=--timeline_streams=VM,Isolate,GC,Dart --timeline_recorder=ring
/// VMOptions=--timeline_streams=VM,Isolate,GC,Dart --timeline_recorder=startup
/// VMOptions=--timeline_streams=VM,Isolate,GC,Dart --timeline_recorder=systrace

import 'dart:developer';

void main() {
  Timeline.startSync('A');

  Timeline.instantSync('B');

  var task = new TimelineTask();
  task.start('C');
  task.instant('D');
  task.finish();

  Timeline.finishSync();
}
