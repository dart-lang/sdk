// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A VM patch of the stopwatch part of dart:core.

patch class StopwatchImplementation {
  // Returns the current clock tick.
  /* patch */ static int _now() native "Stopwatch_now";

  // Returns the frequency of clock ticks in Hz.
  /* patch */ static int _frequency() native "Stopwatch_frequency";
}
