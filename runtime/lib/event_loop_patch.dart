// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class _AsyncRun {
  /* patch */ static void _enqueueImmediate(void callback()) {
    // TODO(9001): don't use the Timer to enqueue the immediate callback.
    Timer.run(callback);
  }
}
