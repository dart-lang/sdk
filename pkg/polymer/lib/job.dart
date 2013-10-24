// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.job;

import 'dart:async' show Timer;

/**
 * Invoke [callback] in [wait], unless the job is re-registered,
 * which resets the timer. For example:
 *
 *     _myJob = runJob(_myJob, callback, const Duration(milliseconds: 100));
 *
 * Returns a job handle which can be used to re-register a job.
 */
// Dart note: renamed to runJob to avoid conflict with instance member "job".
Job runJob(Job job, void callback(), Duration wait) {
  if (job != null) {
    job.stop();
  } else {
    job = new Job();
  }
  job.go(callback, wait);
  return job;
}

// TODO(jmesserly): it isn't clear to me what is supposed to be public API here.
// Or what name we should use. "Job" is awfully generic.
// (The type itself is not exported in Polymer.)
// Remove this type in favor of Timer?
class Job {
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
