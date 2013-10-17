// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class _AsyncRun {
  /* patch */ static void _scheduleImmediate(void callback()) {
    if (_ScheduleImmediate._closure == null) {
      // TODO(9001): don't default to using the Timer to enqueue the immediate
      //             callback.
      _createTimer(Duration.ZERO, callback);
      return;
    }
    _ScheduleImmediate._closure(callback);
  }
}

typedef void _ScheduleImmediateClosure(void callback());

class _ScheduleImmediate {
  static _ScheduleImmediateClosure _closure;
}

void _setScheduleImmediateClosure(_ScheduleImmediateClosure closure) {
  _ScheduleImmediate._closure = closure;
}
