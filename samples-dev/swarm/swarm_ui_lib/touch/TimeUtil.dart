// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of touch;

/**
 * Convenience methods for dealing with time.
 * In the future this could also provide an entry point to mock out time
 * calculation for tests.
 */
class TimeUtil {
  static int now() {
    return new DateTime.now().millisecondsSinceEpoch;
  }
}
