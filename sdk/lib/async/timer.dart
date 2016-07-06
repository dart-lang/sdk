// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

abstract class _TimerTask implements Timer {
  final Zone _zone;
  final Timer _nativeTimer;

  _TimerTask(this._nativeTimer, this._zone);

  void cancel() {
    _nativeTimer.cancel();
  }

  bool get isActive => _nativeTimer.isActive;
}

class _SingleShotTimerTask extends _TimerTask {
  // TODO(floitsch): the generic argument should be 'void'.
  final ZoneCallback<dynamic> _callback;

  _SingleShotTimerTask(Timer timer, this._callback, Zone zone)
      : super(timer, zone);
}

class _PeriodicTimerTask extends _TimerTask {
  // TODO(floitsch): the first generic argument should be 'void'.
  final ZoneUnaryCallback<dynamic, Timer> _callback;

  _PeriodicTimerTask(Timer timer, this._callback, Zone zone)
      : super(timer, zone);
}

/**
 * A task specification for a single-shot timer.
 *
 * *Experimental*. Might disappear without notice.
 */
class SingleShotTimerTaskSpecification implements TaskSpecification {
  static const String specificationName = "dart.async.timer";

  /** The duration after which the timer should invoke the [callback]. */
  final Duration duration;

  /** The callback that should be run when the timer triggers. */
  // TODO(floitsch): the generic argument should be void.
  final ZoneCallback<dynamic> callback;

  SingleShotTimerTaskSpecification(this.duration, void this.callback());

  @override
  String get name => specificationName;

  @override
  bool get isOneShot => true;
}

/**
 * A task specification for a periodic timer.
 *
 * *Experimental*. Might disappear without notice.
 */
class PeriodicTimerTaskSpecification implements TaskSpecification {
  static const String specificationName = "dart.async.periodic-timer";

  /** The interval at which the periodic timer should invoke the [callback]. */
  final Duration duration;

  /** The callback that should be run when the timer triggers. */
  // TODO(floitsch): the first generic argument should be void.
  final ZoneUnaryCallback<dynamic, Timer> callback;

  PeriodicTimerTaskSpecification(
      this.duration, void this.callback(Timer timer));

  @override
  String get name => specificationName;

  @override
  bool get isOneShot => false;
}

/**
 * A count-down timer that can be configured to fire once or repeatedly.
 *
 * The timer counts down from the specified duration to 0.
 * When the timer reaches 0, the timer invokes the specified callback function.
 * Use a periodic timer to repeatedly count down the same interval.
 *
 * A negative duration is treated the same as a duration of 0.
 * If the duration is statically known to be 0, consider using [run].
 *
 * Frequently the duration is either a constant or computed as in the
 * following example (taking advantage of the multiplication operator of
 * the [Duration] class):
 *
 *     const TIMEOUT = const Duration(seconds: 3);
 *     const ms = const Duration(milliseconds: 1);
 *
 *     startTimeout([int milliseconds]) {
 *       var duration = milliseconds == null ? TIMEOUT : ms * milliseconds;
 *       return new Timer(duration, handleTimeout);
 *     }
 *     ...
 *     void handleTimeout() {  // callback function
 *       ...
 *     }
 *
 * Note: If Dart code using Timer is compiled to JavaScript, the finest
 * granularity available in the browser is 4 milliseconds.
 *
 * See [Stopwatch] for measuring elapsed time.
 */
abstract class Timer {

  /**
   * Creates a new timer.
   *
   * The [callback] function is invoked after the given [duration].
   *
   */
  factory Timer(Duration duration, void callback()) {
    if (Zone.current == Zone.ROOT) {
      // No need to bind the callback. We know that the root's timer will
      // be invoked in the root zone.
      return Timer._createTimer(duration, callback);
    }
    return Zone.current.createTimer(duration, callback);
  }

  factory Timer._task(Zone zone, Duration duration, void callback()) {
    SingleShotTimerTaskSpecification specification =
        new SingleShotTimerTaskSpecification(duration, callback);
    return zone.createTask(_createSingleShotTimerTask, specification);
  }

  /**
   * Creates a new repeating timer.
   *
   * The [callback] is invoked repeatedly with [duration] intervals until
   * canceled with the [cancel] function.
   *
   * The exact timing depends on the underlying timer implementation.
   * No more than `n` callbacks will be made in `duration * n` time,
   * but the time between two consecutive callbacks
   * can be shorter and longer than `duration`.
   *
   * In particular, an implementation may schedule the next callback, e.g.,
   * a `duration` after either when the previous callback ended,
   * when the previous callback started, or when the previous callback was
   * scheduled for - even if the actual callback was delayed.
   */
  factory Timer.periodic(Duration duration,
      void callback(Timer timer)) {
    if (Zone.current == Zone.ROOT) {
      // No need to bind the callback. We know that the root's timer will
      // be invoked in the root zone.
      return Timer._createPeriodicTimer(duration, callback);
    }
    return Zone.current.createPeriodicTimer(duration, callback);
  }

  factory Timer._periodicTask(Zone zone, Duration duration,
      void callback(Timer timer)) {
    PeriodicTimerTaskSpecification specification =
        new PeriodicTimerTaskSpecification(duration, callback);
    return zone.createTask(_createPeriodicTimerTask, specification);
  }

  static Timer _createSingleShotTimerTask(
      SingleShotTimerTaskSpecification specification, Zone zone) {
    ZoneCallback registeredCallback = identical(_ROOT_ZONE, zone)
        ? specification.callback
        : zone.registerCallback(specification.callback);

    _TimerTask timerTask;

    Timer nativeTimer = Timer._createTimer(specification.duration, () {
      timerTask._zone.runTask(_runSingleShotCallback, timerTask, null);
    });

    timerTask = new _SingleShotTimerTask(nativeTimer, registeredCallback, zone);
    return timerTask;
  }

  static void _runSingleShotCallback(_SingleShotTimerTask timerTask, Object _) {
    timerTask._callback();
  }

  static Timer _createPeriodicTimerTask(
      PeriodicTimerTaskSpecification specification, Zone zone) {
    // TODO(floitsch): the return type should be 'void', and the type
    // should be inferred.
    ZoneUnaryCallback<dynamic, Timer> registeredCallback =
        identical(_ROOT_ZONE, zone)
        ? specification.callback
        : zone.registerUnaryCallback/*<dynamic, Timer>*/(
            specification.callback);

    _TimerTask timerTask;

    Timer nativeTimer =
        Timer._createPeriodicTimer(specification.duration, (Timer _) {
      timerTask._zone.runTask(_runPeriodicCallback, timerTask, null);
    });

    timerTask = new _PeriodicTimerTask(nativeTimer, registeredCallback, zone);
    return timerTask;
  }

  static void _runPeriodicCallback(_PeriodicTimerTask timerTask, Object _) {
    timerTask._callback(timerTask);
  }

  /**
   * Runs the given [callback] asynchronously as soon as possible.
   *
   * This function is equivalent to `new Timer(Duration.ZERO, callback)`.
   */
  static void run(void callback()) {
    new Timer(Duration.ZERO, callback);
  }

  /**
   * Cancels the timer.
   */
  void cancel();

  /**
   * Returns whether the timer is still active.
   *
   * A non-periodic timer is active if the callback has not been executed,
   * and the timer has not been canceled.
   *
   * A periodic timer is active if it has not been canceled.
   */
  bool get isActive;

  external static Timer _createTimer(Duration duration, void callback());
  external static Timer _createPeriodicTimer(Duration duration,
                                             void callback(Timer timer));
}

