// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.utilities.general;

import 'dart:profiler';

/**
 * Helper class for gathering performance statistics.  This class is modeled on
 * the UserTag class in dart:profiler so that it can interoperate easily with
 * it.
 */
abstract class PerformanceTag {
  /**
   * Return the [PerformanceTag] that is initially current.  This is intended
   * to track time when the system is performing unknown operations.
   */
  static PerformanceTag get UNKNOWN => _PerformanceTagImpl.UNKNOWN;

  /**
   * Return the current [PerformanceTag] for the isolate.
   */
  static PerformanceTag get current => _PerformanceTagImpl.current;

  /**
   * Create a [PerformanceTag] having the given [label].  A [UserTag] will also
   * be created, having the same [label], so that performance information can
   * be queried using the observatory.
   */
  factory PerformanceTag(String label) = _PerformanceTagImpl;

  /**
   * Return the label for this [PerformanceTag].
   */
  String get label;

  /**
   * Return a list of all [PerformanceTag]s which have been created.
   */
  static List<PerformanceTag> get all => _PerformanceTagImpl.all.toList();

  /**
   * Return the total number of milliseconds that this [PerformanceTag] has
   * been the current [PerformanceTag] for the isolate.
   *
   * This call is safe even if this [PerformanceTag] is current.
   */
  int get elapsedMs;

  /**
   * Make this the current tag for the isolate, and return the previous tag.
   */
  PerformanceTag makeCurrent();

  /**
   * Reset the total time tracked by all [PerformanceTag]s to zero.
   */
  static void reset() {
    for (_PerformanceTagImpl tag in _PerformanceTagImpl.all) {
      tag.stopwatch.reset();
    }
  }
}

class _PerformanceTagImpl implements PerformanceTag {
  /**
   * The current performance tag for the isolate.
   */
  static _PerformanceTagImpl current = UNKNOWN;

  static final _PerformanceTagImpl UNKNOWN = new _PerformanceTagImpl('unknown');

  /**
   * A list of all performance tags that have been created so far.
   */
  static List<_PerformanceTagImpl> all = <_PerformanceTagImpl>[];

  @override
  String get label => userTag.label;

  /**
   * The [UserTag] associated with this [PerformanceTag].
   */
  final UserTag userTag;

  /**
   * Stopwatch tracking the amount of time this [PerformanceTag] has been the
   * current tag for the isolate.
   */
  final Stopwatch stopwatch;

  _PerformanceTagImpl(String label)
      : userTag = new UserTag(label), stopwatch = new Stopwatch() {
    all.add(this);
  }

  @override
  PerformanceTag makeCurrent() {
    if (identical(this, current)) {
      return current;
    }
    _PerformanceTagImpl previous = current;
    previous.stopwatch.stop();
    stopwatch.start();
    current = this;
    userTag.makeCurrent();
    return previous;
  }

  @override
  int get elapsedMs => stopwatch.elapsedMilliseconds;
}
