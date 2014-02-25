// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of polymer;

/// Invoke [callback] in [wait], unless the job is re-registered,
/// which resets the timer. For example:
///
///     _myJob = runJob(_myJob, callback, const Duration(milliseconds: 100));
///
/// Returns a job handle which can be used to re-register a job.
// Dart note: renamed to runJob to avoid conflict with instance member "job".
_Job _runJob(_Job job, void callback(), Duration wait) {
  if (job != null) {
    job.stop();
  } else {
    job = new _Job();
  }
  job.go(callback, wait);
  return job;
}

// Public in Polymer.js but private as not sure it's the correct API for Dart.
// Switch to Timer when 14414 is addressed.
class _Job {
  Function _callback;
  Timer _timer;

  void go(void callback(), Duration wait) {
    this._callback = callback;
    _timer = new Timer(wait, complete);
  }

  void stop() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
  }

  void complete() {
    if (_timer != null) {
      stop();
      _callback();
    }
  }
}
