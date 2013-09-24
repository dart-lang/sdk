// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

typedef dynamic ZoneCallback();
typedef dynamic ZoneUnaryCallback(arg);

typedef dynamic HandleUncaughtErrorHandler(
    Zone self, ZoneDelegate parent, Zone zone, e);
typedef dynamic RunHandler(Zone self, ZoneDelegate parent, Zone zone, f());
typedef dynamic RunUnaryHandler(
    Zone self, ZoneDelegate parent, Zone zone, f(arg), arg);
typedef ZoneCallback RegisterCallbackHandler(
    Zone self, ZoneDelegate parent, Zone zone, f());
typedef ZoneUnaryCallback RegisterUnaryCallbackHandler(
    Zone self, ZoneDelegate parent, Zone zone, f(arg));
typedef void ScheduleMicrotaskHandler(
    Zone self, ZoneDelegate parent, Zone zone, f());
typedef Timer CreateTimerHandler(
    Zone self, ZoneDelegate parent, Zone zone, Duration duration, void f());
typedef Timer CreatePeriodicTimerHandler(
    Zone self, ZoneDelegate parent, Zone zone,
    Duration period, void f(Timer timer));
typedef Zone ForkHandler(Zone self, ZoneDelegate parent, Zone zone,
                         ZoneSpecification specification,
                         Map<Symbol, dynamic> zoneValues);

/**
 * This class provides the specification for a forked zone.
 *
 * When forking a new zone (see [Zone.fork]) one can override the default
 * behavior of the zone by providing callbacks. These callbacks must be
 * given in an instance of this class.
 *
 * Handlers have the same signature as the same-named methods on [Zone] but
 * receive three additional arguments:
 *
 *   1. the zone the handlers are attached to (the "self" zone).
 *   2. a [ZoneDelegate] to the parent zone.
 *   3. the zone that first received the request (before the request was
 *     bubbled up).
 *
 * Handlers can either stop propagation the request (by simply not calling the
 * parent handler), or forward to the parent zone, potentially modifying the
 * arguments on the way.
 */
abstract class ZoneSpecification {
  /**
   * Creates a specification with the provided handlers.
   */
  const factory ZoneSpecification({
    void handleUncaughtError(
        Zone self, ZoneDelegate parent, Zone zone, e): null,
    dynamic run(Zone self, ZoneDelegate parent, Zone zone, f()): null,
    dynamic runUnary(
        Zone self, ZoneDelegate parent, Zone zone, f(arg), arg): null,
    ZoneCallback registerCallback(
        Zone self, ZoneDelegate parent, Zone zone, f()): null,
    ZoneUnaryCallback registerUnaryCallback(
        Zone self, ZoneDelegate parent, Zone zone, f(arg)): null,
    void scheduleMicrotask(
        Zone self, ZoneDelegate parent, Zone zone, f()): null,
    Timer createTimer(Zone self, ZoneDelegate parent, Zone zone,
                      Duration duration, void f()): null,
    Timer createPeriodicTimer(Zone self, ZoneDelegate parent, Zone zone,
                              Duration period, void f(Timer timer)): null,
    Zone fork(Zone self, ZoneDelegate parent, Zone zone,
              ZoneSpecification specification, Map zoneValues): null
  }) = _ZoneSpecification;

  /**
   * Creates a specification from [other] with the provided handlers overriding
   * the ones in [other].
   */
  factory ZoneSpecification.from(ZoneSpecification other, {
    void handleUncaughtError(
        Zone self, ZoneDelegate parent, Zone zone, e): null,
    dynamic run(Zone self, ZoneDelegate parent, Zone zone, f()): null,
    dynamic runUnary(
        Zone self, ZoneDelegate parent, Zone zone, f(arg), arg): null,
    ZoneCallback registerCallback(
        Zone self, ZoneDelegate parent, Zone zone, f()): null,
    ZoneUnaryCallback registerUnaryCallback(
        Zone self, ZoneDelegate parent, Zone zone, f(arg)): null,
    void scheduleMicrotask(
        Zone self, ZoneDelegate parent, Zone zone, f()): null,
    Timer createTimer(Zone self, ZoneDelegate parent, Zone zone,
                      Duration duration, void f()): null,
    Timer createPeriodicTimer(Zone self, ZoneDelegate parent, Zone zone,
                              Duration period, void f(Timer timer)): null,
    Zone fork(Zone self, ZoneDelegate parent, Zone zone,
              ZoneSpecification specification,
              Map<Symbol, dynamic> zoneValues): null
  }) {
    return new ZoneSpecification(
      handleUncaughtError: handleUncaughtError != null
                           ? handleUncaughtError
                           : other.handleUncaughtError,
      run: run != null ? run : other.run,
      runUnary: runUnary != null ? runUnary : other.runUnary,
      registerCallback: registerCallback != null
                        ? registerCallback
                        : other.registerCallback,
      registerUnaryCallback: registerUnaryCallback != null
                         ? registerUnaryCallback
                         : other.registerUnaryCallback,
      scheduleMicrotask: scheduleMicrotask != null
                         ? scheduleMicrotask
                         : other.scheduleMicrotask,
      createTimer : createTimer != null ? createTimer : other.createTimer,
      createPeriodicTimer: createPeriodicTimer != null
                           ? createPeriodicTimer
                           : other.createPeriodicTimer,
      fork: fork != null ? fork : other.fork);
  }

  HandleUncaughtErrorHandler get handleUncaughtError;
  RunHandler get run;
  RunUnaryHandler get runUnary;
  RegisterCallbackHandler get registerCallback;
  RegisterUnaryCallbackHandler get registerUnaryCallback;
  ScheduleMicrotaskHandler get scheduleMicrotask;
  CreateTimerHandler get createTimer;
  CreatePeriodicTimerHandler get createPeriodicTimer;
  ForkHandler get fork;
}

/**
 * Internal [ZoneSpecification] class.
 *
 * The implementation wants to rely on the fact that the getters cannot change
 * dynamically. We thus require users to go through the redirecting
 * [ZoneSpecification] constructor which instantiates this class.
 */
class _ZoneSpecification implements ZoneSpecification {
  const _ZoneSpecification({
    this.handleUncaughtError: null,
    this.run: null,
    this.runUnary: null,
    this.registerCallback: null,
    this.registerUnaryCallback: null,
    this.scheduleMicrotask: null,
    this.createTimer: null,
    this.createPeriodicTimer: null,
    this.fork: null
  });

  // TODO(13406): Enable types when dart2js supports it.
  final /*HandleUncaughtErrorHandler*/ handleUncaughtError;
  final /*RunHandler*/ run;
  final /*RunUnaryHandler*/ runUnary;
  final /*RegisterCallbackHandler*/ registerCallback;
  final /*RegisterUnaryCallbackHandler*/ registerUnaryCallback;
  final /*ScheduleMicrotaskHandler*/ scheduleMicrotask;
  final /*CreateTimerHandler*/ createTimer;
  final /*CreatePeriodicTimerHandler*/ createPeriodicTimer;
  final /*ForkHandler*/ fork;
}

/**
 * This class wraps zones for delegation.
 *
 * When forwarding to parent zones one can't just invoke the parent zone's
 * exposed functions (like [Zone.run]), but one needs to provide more
 * information (like the zone the `run` was initiated). Zone callbacks thus
 * receive more information including this [ZoneDelegate] class. When delegating
 * to the parent zone one should go through the given instance instead of
 * directly invoking the parent zone.
 */
abstract class ZoneDelegate {
  /// The [Zone] this class wraps.
  Zone get _zone;

  dynamic handleUncaughtError(Zone zone, e);
  dynamic run(Zone zone, f());
  dynamic runUnary(Zone zone, f(arg), arg);
  ZoneCallback registerCallback(Zone zone, f());
  ZoneUnaryCallback registerUnaryCallback(Zone zone, f(arg));
  void scheduleMicrotask(Zone zone, f());
  Timer createTimer(Zone zone, Duration duration, void f());
  Timer createPeriodicTimer(Zone zone, Duration period, void f(Timer timer));
  Zone fork(Zone zone, ZoneSpecification specification, Map zoneValues);
}

/**
 * A Zone represents the asynchronous version of a dynamic extent. Asynchronous
 * callbacks are executed in the zone they have been queued in. For example,
 * the callback of a `future.then` is executed in the same zone as the one where
 * the `then` was invoked.
 */
abstract class Zone {
  // Private constructor so that it is not possible instantiate a Zone class.
  Zone._();

  /// The root zone that is implicitly created.
  static const Zone ROOT = _ROOT_ZONE;

  /// The currently running zone.
  static Zone _current = _ROOT_ZONE;

  static Zone get current => _current;

  dynamic handleUncaughtError(error);

  /**
   * Returns the parent zone.
   *
   * Returns `null` if `this` is the [ROOT] zone.
   */
  Zone get parent;

  /**
   * Returns true if `this` and [otherZone] are in the same error zone.
   *
   * Two zones are in the same error zone if they share the same
   * [handleUncaughtError] callback.
   */
  bool inSameErrorZone(Zone otherZone);

  /**
   * Creates a new zone as a child of `this`.
   */
  Zone fork({ ZoneSpecification specification,
              Map<Symbol, dynamic> zoneValues });

  /**
   * Executes the given function [f] in this zone.
   */
  dynamic run(f());

  /**
   * Executes the given callback [f] with argument [arg] in this zone.
   */
  dynamic runUnary(f(arg), var arg);

  /**
   * Executes the given function [f] in this zone.
   *
   * Same as [run] but catches uncaught errors and gives them to
   * [handleUncaughtError].
   */
  dynamic runGuarded(f());

  /**
   * Executes the given callback [f] in this zone.
   *
   * Same as [runUnary] but catches uncaught errors and gives them to
   * [handleUncaughtError].
   */
  dynamic runUnaryGuarded(f(arg), var arg);

  ZoneCallback registerCallback(f());
  ZoneUnaryCallback registerUnaryCallback(f(arg));

  /**
   *  Equivalent to:
   *
   *      ZoneCallback registered = registerCallback(f);
   *      return () => this.run(registered);
   */
  ZoneCallback bindCallback(f(), { bool runGuarded });
  /**
   *  Equivalent to:
   *
   *      ZoneCallback registered = registerCallback1(f);
   *      return (arg) => this.run1(registered, arg);
   */
  ZoneUnaryCallback bindUnaryCallback(f(arg), { bool runGuarded });

  /**
   * Runs [f] asynchronously.
   */
  void scheduleMicrotask(void f());

  /**
   * Creates a Timer where the callback is executed in this zone.
   */
  Timer createTimer(Duration duration, void callback());

  /**
   * Creates a periodic Timer where the callback is executed in this zone.
   */
  Timer createPeriodicTimer(Duration period, void callback(Timer timer));

  /**
   * The error zone is the one that is responsible for dealing with uncaught
   * errors. Errors are not allowed to cross zones with different error-zones.
   */
  Zone get _errorZone;

  /**
   * Retrieves the zone-value associated with [key].
   *
   * If this zone does not contain the value looks up the same key in the
   * parent zone. If the [key] is not found returns `null`.
   */
  operator[](Symbol key);
}

class _ZoneDelegate implements ZoneDelegate {
  final _CustomizedZone _degelationTarget;

  Zone get _zone => _degelationTarget;

  const _ZoneDelegate(this._degelationTarget);

  dynamic handleUncaughtError(Zone zone, e) {
    _CustomizedZone parent = _degelationTarget;
    while (parent._specification.handleUncaughtError == null) {
      parent = parent.parent;
    }
    return (parent._specification.handleUncaughtError)(
        parent, new _ZoneDelegate(parent.parent), zone, e);
  }

  dynamic run(Zone zone, f()) {
    _CustomizedZone parent = _degelationTarget;
    while (parent._specification.run == null) {
      parent = parent.parent;
    }
    return (parent._specification.run)(
        parent, new _ZoneDelegate(parent.parent), zone, f);
  }

  dynamic runUnary(Zone zone, f(arg), arg) {
    _CustomizedZone parent = _degelationTarget;
    while (parent._specification.runUnary == null) {
      parent = parent.parent;
    }
    return (parent._specification.runUnary)(
        parent, new _ZoneDelegate(parent.parent), zone, f, arg);
  }

  ZoneCallback registerCallback(Zone zone, f()) {
    _CustomizedZone parent = _degelationTarget;
    while (parent._specification.registerCallback == null) {
      parent = parent.parent;
    }
    return (parent._specification.registerCallback)(
        parent, new _ZoneDelegate(parent.parent), zone, f);
  }

  ZoneUnaryCallback registerUnaryCallback(Zone zone, f(arg)) {
    _CustomizedZone parent = _degelationTarget;
    while (parent._specification.registerUnaryCallback == null) {
      parent = parent.parent;
    }
    return (parent._specification.registerUnaryCallback)(
        parent, new _ZoneDelegate(parent.parent), zone, f);
  }

  void scheduleMicrotask(Zone zone, f()) {
    _CustomizedZone parent = _degelationTarget;
    while (parent._specification.scheduleMicrotask == null) {
      parent = parent.parent;
    }
    _ZoneDelegate grandParent = new _ZoneDelegate(parent.parent);
    (parent._specification.scheduleMicrotask)(parent, grandParent, zone, f);
  }

  Timer createTimer(Zone zone, Duration duration, void f()) {
    _CustomizedZone parent = _degelationTarget;
    while (parent._specification.createTimer == null) {
      parent = parent.parent;
    }
    return (parent._specification.createTimer)(
        parent, new _ZoneDelegate(parent.parent), zone, duration, f);
  }

  Timer createPeriodicTimer(Zone zone, Duration period, void f(Timer timer)) {
    _CustomizedZone parent = _degelationTarget;
    while (parent._specification.createPeriodicTimer == null) {
      parent = parent.parent;
    }
    return (parent._specification.createPeriodicTimer)(
        parent, new _ZoneDelegate(parent.parent), zone, period, f);
  }

  Zone fork(Zone zone, ZoneSpecification specification,
            Map<Symbol, dynamic> zoneValues) {
    _CustomizedZone parent = _degelationTarget;
    while (parent._specification.fork == null) {
      parent = parent.parent;
    }
    _ZoneDelegate grandParent = new _ZoneDelegate(parent.parent);
    return (parent._specification.fork)(
        parent, grandParent, zone, specification, zoneValues);
  }
}


/**
 * Default implementation of a [Zone].
 */
class _CustomizedZone implements Zone {
  /// The parent zone.
  final _CustomizedZone parent;
  /// The zone's handlers.
  final ZoneSpecification _specification;
  /// The zone's value map.
  final Map<Symbol, dynamic> _map;

  const _CustomizedZone(this.parent, this._specification, this._map);

  Zone get _errorZone {
    if (_specification.handleUncaughtError != null) return this;
    return parent._errorZone;
  }

  bool inSameErrorZone(Zone otherZone) => _errorZone == otherZone._errorZone;

  dynamic runGuarded(f()) {
    try {
      return run(f);
    } catch (e, s) {
      return handleUncaughtError(_asyncError(e, s));
    }
  }

  dynamic runUnaryGuarded(f(arg), arg) {
    try {
      return runUnary(f, arg);
    } catch (e, s) {
      return handleUncaughtError(_asyncError(e, s));
    }
  }

  ZoneCallback bindCallback(f(), { bool runGuarded }) {
    ZoneCallback registered = registerCallback(f);
    if (runGuarded) {
      return () => this.runGuarded(registered);
    } else {
      return () => this.run(registered);
    }
  }

  ZoneUnaryCallback bindUnaryCallback(f(arg), { bool runGuarded }) {
    ZoneUnaryCallback registered = registerUnaryCallback(f);
    if (runGuarded) {
      return (arg) => this.runUnaryGuarded(registered, arg);
    } else {
      return (arg) => this.runUnary(registered, arg);
    }
  }

  operator [](Symbol key) {
    var result = _map[key];
    if (result != null || _map.containsKey(key)) return result;
    // If we are not the root zone look up in the parent zone.
    if (parent != null) return parent[key];
    assert(this == Zone.ROOT);
    return null;
  }

  // Methods that can be customized by the zone specification.

  dynamic handleUncaughtError(error) {
    return new _ZoneDelegate(this).handleUncaughtError(this, error);
  }

  Zone fork({ZoneSpecification specification, Map zoneValues}) {
    return new _ZoneDelegate(this).fork(this, specification, zoneValues);
  }

  dynamic run(f()) {
    return new _ZoneDelegate(this).run(this, f);
  }

  dynamic runUnary(f(arg), arg) {
    return new _ZoneDelegate(this).runUnary(this, f, arg);
  }

  ZoneCallback registerCallback(f()) {
    return new _ZoneDelegate(this).registerCallback(this, f);
  }

  ZoneUnaryCallback registerUnaryCallback(f(arg)) {
    return new _ZoneDelegate(this).registerUnaryCallback(this, f);
  }

  void scheduleMicrotask(void f()) {
    new _ZoneDelegate(this).scheduleMicrotask(this, f);
  }

  Timer createTimer(Duration duration, void f()) {
    return new _ZoneDelegate(this).createTimer(this, duration, f);
  }

  Timer createPeriodicTimer(Duration duration, void f(Timer timer)) {
    return new _ZoneDelegate(this).createPeriodicTimer(this, duration, f);
  }
}

void _rootHandleUncaughtError(
    Zone self, ZoneDelegate parent, Zone zone, error) {
  _scheduleAsyncCallback(() {
    print("Uncaught Error: ${error}");
    var trace = getAttachedStackTrace(error);
    _attachStackTrace(error, null);
    if (trace != null) {
      print("Stack Trace:\n$trace\n");
    }
    throw error;
  });
}

dynamic _rootRun(Zone self, ZoneDelegate parent, Zone zone, f()) {
  if (Zone._current == zone) return f();

  Zone old = Zone._current;
  try {
    Zone._current = zone;
    return f();
  } finally {
    Zone._current = old;
  }
}

dynamic _rootRunUnary(Zone self, ZoneDelegate parent, Zone zone, f(arg), arg) {
  if (Zone._current == zone) return f(arg);

  Zone old = Zone._current;
  try {
    Zone._current = zone;
    return f(arg);
  } finally {
    Zone._current = old;
  }
}

ZoneCallback _rootRegisterCallback(
    Zone self, ZoneDelegate parent, Zone zone, f()) {
  return f;
}

ZoneUnaryCallback _rootRegisterUnaryCallback(
    Zone self, ZoneDelegate parent, Zone zone, f(arg)) {
  return f;
}

void _rootScheduleMicrotask(Zone self, ZoneDelegate parent, Zone zone, f()) {
  _scheduleAsyncCallback(f);
}

Timer _rootCreateTimer(Zone self, ZoneDelegate parent, Zone zone,
                       Duration duration, void callback()) {
  return _createTimer(duration, callback);
}

Timer _rootCreatePeriodicTimer(
    Zone self, ZoneDelegate parent, Zone zone,
    Duration duration, void callback(Timer timer)) {
  return _createPeriodicTimer(duration, callback);
}

Zone _rootFork(Zone self, ZoneDelegate parent, Zone zone,
               ZoneSpecification specification,
               Map<Symbol, dynamic> zoneValues) {
  if (specification == null) {
    specification = const ZoneSpecification();
  } else if (specification is! _ZoneSpecification) {
    throw new ArgumentError("ZoneSpecifications must be instantiated"
        " with the provided constructor.");
  }
  Map<Symbol, dynamic> copiedMap = new HashMap();
  if (zoneValues != null) {
    zoneValues.forEach((Symbol key, value) {
      if (key == null) {
        throw new ArgumentError("ZoneValue key must not be null");
      }
      copiedMap[key] = value;
    });
  }
  return new _CustomizedZone(zone, specification, copiedMap);
}

const _ROOT_SPECIFICATION = const ZoneSpecification(
  handleUncaughtError: _rootHandleUncaughtError,
  run: _rootRun,
  runUnary: _rootRunUnary,
  registerCallback: _rootRegisterCallback,
  registerUnaryCallback: _rootRegisterUnaryCallback,
  scheduleMicrotask: _rootScheduleMicrotask,
  createTimer: _rootCreateTimer,
  createPeriodicTimer: _rootCreatePeriodicTimer,
  fork: _rootFork
);

const _ROOT_ZONE =
    const _CustomizedZone(null, _ROOT_SPECIFICATION, const <Symbol, dynamic>{});


/**
 * Runs [body] in its own zone.
 *
 * If [onError] is non-null the zone is considered an error zone. All uncaught
 * errors, synchronous or asynchronous, in the zone are caught and handled
 * by the callback.
 *
 * Errors may never cross error-zone boundaries. This is intuitive for leaving
 * a zone, but it also applies for errors that would enter an error-zone.
 * Errors that try to cross error-zone boundaries are considered uncaught.
 *
 *     var future = new Future.value(499);
 *     runZonedExperimental(() {
 *       future = future.then((_) { throw "error in first error-zone"; });
 *       runZonedExperimental(() {
 *         future = future.catchError((e) { print("Never reached!"); });
 *       }, onError: (e) { print("unused error handler"); });
 *     }, onError: (e) { print("catches error of first error-zone."); });
 *
 * Example:
 *
 *     runZonedExperimental(() {
 *       new Future(() { throw "asynchronous error"; });
 *     }, onError: print);  // Will print "asynchronous error".
 */
dynamic runZoned(body(),
                 { Map<Symbol, dynamic> zoneValues,
                   ZoneSpecification zoneSpecification,
                   void onError(error) }) {
  HandleUncaughtErrorHandler errorHandler;
  if (onError != null) {
    errorHandler = (Zone self, ZoneDelegate parent, Zone zone, error) {
      try {
        return self.parent.runUnary(onError, error);
      } catch(e, s) {
        if (identical(e, error)) {
          return parent.handleUncaughtError(zone, error);
        } else {
          return parent.handleUncaughtError(zone, _asyncError(e, s));
        }
      }
    };
  }
  if (zoneSpecification == null) {
    zoneSpecification =
        new ZoneSpecification(handleUncaughtError: errorHandler);
  } else if (errorHandler != null) {
    zoneSpecification =
        new ZoneSpecification.from(zoneSpecification,
                                   handleUncaughtError: errorHandler);
  }
  Zone zone = Zone.current.fork(specification: zoneSpecification,
                                zoneValues: zoneValues);
  if (onError != null) {
    return zone.runGuarded(body);
  } else {
    return zone.run(body);
  }
}

/**
 * Deprecated. Use `runZoned` instead or create your own [ZoneSpecification].
 *
 * The [onRunAsync] handler (if non-null) is invoked when the [body] executes
 * [runAsync].  The handler is invoked in the outer zone and can therefore
 * execute [runAsync] without recursing. The given callback must be
 * executed eventually. Otherwise the nested zone will not complete. It must be
 * executed only once.
 *
 * The following example prints the stack trace whenever a callback is
 * registered using [runAsync] (which is also used by [Completer]s and
 * [StreamController]s.
 *
 *     printStackTrace() { try { throw 0; } catch(e, s) { print(s); } }
 *     runZonedExperimental(body, onRunAsync: (callback) {
 *       printStackTrace();
 *       runAsync(callback);
 *     });
 *
 * Note: the `onDone` handler is ignored.
 */
@deprecated
runZonedExperimental(body(),
                     { void onRunAsync(void callback()),
                       void onError(error),
                       void onDone() }) {
  if (onRunAsync == null) {
    return runZoned(body, onError: onError);
  }
  HandleUncaughtErrorHandler errorHandler;
  if (onError != null) {
    errorHandler = (Zone self, ZoneDelegate parent, Zone zone, error) {
      try {
        return self.parent.runUnary(onError, error);
      } catch(e, s) {
        if (identical(e, error)) {
          return parent.handleUncaughtError(zone, error);
        } else {
          return parent.handleUncaughtError(zone, _asyncError(e, s));
        }
      }
    };
  }
  ScheduleMicrotaskHandler asyncHandler;
  if (onRunAsync != null) {
    asyncHandler = (Zone self, ZoneDelegate parent, Zone zone, f()) {
      self.parent.runUnary(onRunAsync, () => zone.runGuarded(f));
    };
  }
  ZoneSpecification specification =
    new ZoneSpecification(handleUncaughtError: errorHandler,
                        scheduleMicrotask: asyncHandler);
  Zone zone = Zone.current.fork(specification: specification);
  if (onError != null) {
    return zone.runGuarded(body);
  } else {
    return zone.run(body);
  }
}
