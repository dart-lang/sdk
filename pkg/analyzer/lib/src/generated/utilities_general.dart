// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.utilities_general;

import 'dart:async';
import 'dart:collection';
import 'dart:developer' show UserTag;

export 'package:front_end/src/base/jenkins_smi_hash.dart' show JenkinsSmiHash;

/**
 * Test if the given [value] is `false` or the string "false" (case-insensitive).
 */
bool isFalse(Object value) =>
    value is bool ? !value : toLowerCase(value) == 'false';

/**
 * Test if the given [value] is `true` or the string "true" (case-insensitive).
 */
bool isTrue(Object value) =>
    value is bool ? value : toLowerCase(value) == 'true';

/**
 * Safely convert the given [value] to a bool value, or return `null` if the
 * value could not be converted.
 */
bool toBool(Object value) {
  if (value is bool) {
    return value;
  }
  String string = toLowerCase(value);
  if (string == 'true') {
    return true;
  }
  if (string == 'false') {
    return false;
  }
  return null;
}

/**
 * Safely convert this [value] to lower case, returning `null` if [value] is
 * null.
 */
String toLowerCase(Object value) => value?.toString()?.toLowerCase();

/**
 * Safely convert this [value] to upper case, returning `null` if [value] is
 * null.
 */
String toUpperCase(Object value) => value?.toString()?.toUpperCase();

/**
 * A simple limited queue.
 */
class LimitedQueue<E> extends ListQueue<E> {
  final int limit;

  /**
   * Create a queue with [limit] items.
   */
  LimitedQueue(this.limit);

  @override
  void add(E o) {
    super.add(o);
    while (length > limit) {
      remove(first);
    }
  }
}

/**
 * Helper class for gathering performance statistics.  This class is modeled on
 * the UserTag class in dart:developer so that it can interoperate easily with
 * it.
 */
abstract class PerformanceTag {
  /**
   * Return a list of all [PerformanceTag]s which have been created.
   */
  static List<PerformanceTag> get all => _PerformanceTagImpl.all.toList();

  /**
   * Return the current [PerformanceTag] for the isolate.
   */
  static PerformanceTag get current => _PerformanceTagImpl.current;

  /**
   * Return the [PerformanceTag] that is initially current.  This is intended
   * to track time when the system is performing unknown operations.
   */
  static PerformanceTag get unknown => _PerformanceTagImpl.unknown;

  /**
   * Create a [PerformanceTag] having the given [label].  A [UserTag] will also
   * be created, having the same [label], so that performance information can
   * be queried using the observatory.
   */
  factory PerformanceTag(String label) = _PerformanceTagImpl;

  /**
   * Return the total number of milliseconds that this [PerformanceTag] has
   * been the current [PerformanceTag] for the isolate.
   *
   * This call is safe even if this [PerformanceTag] is current.
   */
  int get elapsedMs;

  /**
   * Return the label for this [PerformanceTag].
   */
  String get label;

  /**
   * Create a child tag of the current tag. The new tag's name will include the
   * parent's name.
   */
  PerformanceTag createChild(String childTagName);

  /**
   * Make this the current tag for the isolate, and return the previous tag.
   */
  PerformanceTag makeCurrent();

  /**
   * Make this the current tag for the isolate, run [f], and restore the
   * previous tag. Returns the result of invoking [f].
   */
  E makeCurrentWhile<E>(E f());

  /**
   * Make this the current tag for the isolate, run [f], and restore the
   * previous tag. Returns the result of invoking [f].
   */
  Future<E> makeCurrentWhileAsync<E>(Future<E> f());

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
  static _PerformanceTagImpl current = unknown;

  static final _PerformanceTagImpl unknown = new _PerformanceTagImpl('unknown');

  /**
   * A list of all performance tags that have been created so far.
   */
  static List<_PerformanceTagImpl> all = <_PerformanceTagImpl>[];

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
      : userTag = new UserTag(label),
        stopwatch = new Stopwatch() {
    all.add(this);
  }

  @override
  int get elapsedMs => stopwatch.elapsedMilliseconds;

  @override
  String get label => userTag.label;

  @override
  PerformanceTag createChild(String childTagName) {
    return new _PerformanceTagImpl('$label.$childTagName');
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

  E makeCurrentWhile<E>(E f()) {
    PerformanceTag prevTag = makeCurrent();
    try {
      return f();
    } finally {
      prevTag.makeCurrent();
    }
  }

  @override
  Future<E> makeCurrentWhileAsync<E>(Future<E> f()) async {
    PerformanceTag prevTag = makeCurrent();
    try {
      return await f();
    } finally {
      prevTag.makeCurrent();
    }
  }
}
