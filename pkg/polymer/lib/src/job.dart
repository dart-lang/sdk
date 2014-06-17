// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of polymer;

/// Like [Timer] but can be restarted, and if no duration is supplied uses
/// [window.requestAnimationFrame] instead of a 0-duration timer.
// TODO(jmesserly): need to find a better name here. Also this feels more like a
// system level API, but doesn't map exactly to any of our other primitives.
class PolymerJob {
  Function _callback;
  Timer _timer;
  int _id; // for requestAnimationFrame

  PolymerJob._();

  bool get isScheduled => _timer != null || _id != null;

  /// Starts the job. If the job is already running, it will [stop] first.
  void start(void callback(), [Duration wait]) {
    stop();
    _callback = callback;
    if (wait == null) {
      _id = window.requestAnimationFrame((_) => complete());
    } else {
      _timer = new Timer(wait, complete);
    }
  }

  /// Stops the job. It can be restarted by calling [start] with a new callback.
  void stop() {
    if (_id != null) {
      window.cancelAnimationFrame(_id);
      _id = null;
    }
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
  }

  /// Synchronously completes the job.
  void complete() {
    if (isScheduled) {
      stop();
      _callback();
    }
  }
}
