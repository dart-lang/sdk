// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The class [Clock] provides access to a monotonically incrementing clock
 * device.
 */
class Clock {

  /**
   * Returns the current clock tick.
   */
  static int now() => Primitives.dateNow();

  /**
   * Returns the frequency of clock ticks in Hz.
   */
  static int frequency() => 1000;
}
