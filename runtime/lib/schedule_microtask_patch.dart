// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "async_patch.dart";

@patch
class _AsyncRun {
  @patch
  static void _scheduleImmediate(void callback()) {
    if (_ScheduleImmediate._closure == null) {
      throw new UnsupportedError("Microtasks are not supported");
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
