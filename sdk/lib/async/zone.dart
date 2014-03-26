// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

typedef dynamic ZoneCallback();
typedef dynamic ZoneUnaryCallback(arg);
typedef dynamic ZoneBinaryCallback(arg1, arg2);

typedef dynamic HandleUncaughtErrorHandler(
    Zone self, ZoneDelegate parent, Zone zone, error, StackTrace stackTrace);
typedef dynamic RunHandler(Zone self, ZoneDelegate parent, Zone zone, f());
typedef dynamic RunUnaryHandler(
    Zone self, ZoneDelegate parent, Zone zone, f(arg), arg);
typedef dynamic RunBinaryHandler(
    Zone self, ZoneDelegate parent, Zone zone, f(arg1, arg2), arg1, arg2);
typedef ZoneCallback RegisterCallbackHandler(
    Zone self, ZoneDelegate parent, Zone zone, f());
typedef ZoneUnaryCallback RegisterUnaryCallbackHandler(
    Zone self, ZoneDelegate parent, Zone zone, f(arg));
typedef ZoneBinaryCallback RegisterBinaryCallbackHandler(
    Zone self, ZoneDelegate parent, Zone zone, f(arg1, arg2));
typedef void ScheduleMicrotaskHandler(
    Zone self, ZoneDelegate parent, Zone zone, f());
typedef Timer CreateTimerHandler(
    Zone self, ZoneDelegate parent, Zone zone, Duration duration, void f());
typedef Timer CreatePeriodicTimerHandler(
    Zone self, ZoneDelegate parent, Zone zone,
    Duration period, void f(Timer timer));
typedef void PrintHandler(
    Zone self, ZoneDelegate parent, Zone zone, String line);
typedef Zone ForkHandler(Zone self, ZoneDelegate parent, Zone zone,
                         ZoneSpecification specification,
                         Map zoneValues);

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
    dynamic handleUncaughtError(Zone self, ZoneDelegate parent, Zone zone,
                                error, StackTrace stackTrace),
    dynamic run(Zone self, ZoneDelegate parent, Zone zone, f()),
    dynamic runUnary(
        Zone self, ZoneDelegate parent, Zone zone, f(arg), arg),
    dynamic runBinary(Zone self, ZoneDelegate parent, Zone zone,
                      f(arg1, arg2), arg1, arg2),
    ZoneCallback registerCallback(
        Zone self, ZoneDelegate parent, Zone zone, f()),
    ZoneUnaryCallback registerUnaryCallback(
        Zone self, ZoneDelegate parent, Zone zone, f(arg)),
    ZoneBinaryCallback registerBinaryCallback(
        Zone self, ZoneDelegate parent, Zone zone, f(arg1, arg2)),
    void scheduleMicrotask(
        Zone self, ZoneDelegate parent, Zone zone, f()),
    Timer createTimer(Zone self, ZoneDelegate parent, Zone zone,
                      Duration duration, void f()),
    Timer createPeriodicTimer(Zone self, ZoneDelegate parent, Zone zone,
                              Duration period, void f(Timer timer)),
    void print(Zone self, ZoneDelegate parent, Zone zone, String line),
    Zone fork(Zone self, ZoneDelegate parent, Zone zone,
              ZoneSpecification specification, Map zoneValues)
  }) = _ZoneSpecification;

  /**
   * Creates a specification from [other] with the provided handlers overriding
   * the ones in [other].
   */
  factory ZoneSpecification.from(ZoneSpecification other, {
    dynamic handleUncaughtError(Zone self, ZoneDelegate parent, Zone zone,
                                error, StackTrace stackTrace): null,
    dynamic run(Zone self, ZoneDelegate parent, Zone zone, f()): null,
    dynamic runUnary(
        Zone self, ZoneDelegate parent, Zone zone, f(arg), arg): null,
    dynamic runBinary(Zone self, ZoneDelegate parent, Zone zone,
                      f(arg1, arg2), arg1, arg2): null,
    ZoneCallback registerCallback(
        Zone self, ZoneDelegate parent, Zone zone, f()): null,
    ZoneUnaryCallback registerUnaryCallback(
        Zone self, ZoneDelegate parent, Zone zone, f(arg)): null,
    ZoneBinaryCallback registerBinaryCallback(
        Zone self, ZoneDelegate parent, Zone zone, f(arg1, arg2)): null,
    void scheduleMicrotask(
        Zone self, ZoneDelegate parent, Zone zone, f()): null,
    Timer createTimer(Zone self, ZoneDelegate parent, Zone zone,
                      Duration duration, void f()): null,
    Timer createPeriodicTimer(Zone self, ZoneDelegate parent, Zone zone,
                              Duration period, void f(Timer timer)): null,
    void print(Zone self, ZoneDelegate parent, Zone zone, String line): null,
    Zone fork(Zone self, ZoneDelegate parent, Zone zone,
              ZoneSpecification specification,
              Map zoneValues): null
  }) {
    return new ZoneSpecification(
      handleUncaughtError: handleUncaughtError != null
                           ? handleUncaughtError
                           : other.handleUncaughtError,
      run: run != null ? run : other.run,
      runUnary: runUnary != null ? runUnary : other.runUnary,
      runBinary: runBinary != null ? runBinary : other.runBinary,
      registerCallback: registerCallback != null
                        ? registerCallback
                        : other.registerCallback,
      registerUnaryCallback: registerUnaryCallback != null
                         ? registerUnaryCallback
                         : other.registerUnaryCallback,
      registerBinaryCallback: registerBinaryCallback != null
                         ? registerBinaryCallback
                         : other.registerBinaryCallback,
      scheduleMicrotask: scheduleMicrotask != null
                         ? scheduleMicrotask
                         : other.scheduleMicrotask,
      createTimer : createTimer != null ? createTimer : other.createTimer,
      createPeriodicTimer: createPeriodicTimer != null
                           ? createPeriodicTimer
                           : other.createPeriodicTimer,
      print : print != null ? print : other.print,
      fork: fork != null ? fork : other.fork);
  }

  HandleUncaughtErrorHandler get handleUncaughtError;
  RunHandler get run;
  RunUnaryHandler get runUnary;
  RunBinaryHandler get runBinary;
  RegisterCallbackHandler get registerCallback;
  RegisterUnaryCallbackHandler get registerUnaryCallback;
  RegisterBinaryCallbackHandler get registerBinaryCallback;
  ScheduleMicrotaskHandler get scheduleMicrotask;
  CreateTimerHandler get createTimer;
  CreatePeriodicTimerHandler get createPeriodicTimer;
  PrintHandler get print;
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
    this.runBinary: null,
    this.registerCallback: null,
    this.registerUnaryCallback: null,
    this.registerBinaryCallback: null,
    this.scheduleMicrotask: null,
    this.createTimer: null,
    this.createPeriodicTimer: null,
    this.print: null,
    this.fork: null
  });

  // TODO(13406): Enable types when dart2js supports it.
  final /*HandleUncaughtErrorHandler*/ handleUncaughtError;
  final /*RunHandler*/ run;
  final /*RunUnaryHandler*/ runUnary;
  final /*RunBinaryHandler*/ runBinary;
  final /*RegisterCallbackHandler*/ registerCallback;
  final /*RegisterUnaryCallbackHandler*/ registerUnaryCallback;
  final /*RegisterBinaryCallbackHandler*/ registerBinaryCallback;
  final /*ScheduleMicrotaskHandler*/ scheduleMicrotask;
  final /*CreateTimerHandler*/ createTimer;
  final /*CreatePeriodicTimerHandler*/ createPeriodicTimer;
  final /*PrintHandler*/ print;
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

  dynamic handleUncaughtError(Zone zone, error, StackTrace stackTrace);
  dynamic run(Zone zone, f());
  dynamic runUnary(Zone zone, f(arg), arg);
  dynamic runBinary(Zone zone, f(arg1, arg2), arg1, arg2);
  ZoneCallback registerCallback(Zone zone, f());
  ZoneUnaryCallback registerUnaryCallback(Zone zone, f(arg));
  ZoneBinaryCallback registerBinaryCallback(Zone zone, f(arg1, arg2));
  void scheduleMicrotask(Zone zone, f());
  Timer createTimer(Zone zone, Duration duration, void f());
  Timer createPeriodicTimer(Zone zone, Duration period, void f(Timer timer));
  void print(Zone zone, String line);
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

  dynamic handleUncaughtError(error, StackTrace stackTrace);

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
   *
   * The new zone will have behavior like the current zone, except where
   * overridden by functions in [specification].
   *
   * The new zone will have the same stored values (accessed through
   * `operator []`) as this zone, but updated with the keys and values
   * in [zoneValues]. If a key is in both this zone's values and in
   * `zoneValues`, the new zone will use the value from `zoneValues``.
   */
  Zone fork({ ZoneSpecification specification,
              Map zoneValues });

  /**
   * Executes the given function [f] in this zone.
   */
  dynamic run(f());

  /**
   * Executes the given callback [f] with argument [arg] in this zone.
   */
  dynamic runUnary(f(arg), var arg);

  /**
   * Executes the given callback [f] with argument [arg1] and [arg2] in this
   * zone.
   */
  dynamic runBinary(f(arg1, arg2), var arg1, var arg2);

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

  /**
   * Executes the given callback [f] in this zone.
   *
   * Same as [runBinary] but catches uncaught errors and gives them to
   * [handleUncaughtError].
   */
  dynamic runBinaryGuarded(f(arg1, arg2), var arg1, var arg2);

  /**
   * Registers the given callback in this zone.
   *
   * It is good practice to register asynchronous or delayed callbacks before
   * invoking [run]. This gives the zone a chance to wrap the callback and
   * to store information with the callback. For example, a zone may decide
   * to store the stack trace (at the time of the registration) with the
   * callback.
   *
   * Returns a potentially new callback that should be used in place of the
   * given [callback].
   */
  ZoneCallback registerCallback(callback());

  /**
   * Registers the given callback in this zone.
   *
   * Similar to [registerCallback] but with a unary callback.
   */
  ZoneUnaryCallback registerUnaryCallback(callback(arg));

  /**
   * Registers the given callback in this zone.
   *
   * Similar to [registerCallback] but with a unary callback.
   */
  ZoneBinaryCallback registerBinaryCallback(callback(arg1, arg2));

  /**
   *  Equivalent to:
   *
   *      ZoneCallback registered = registerCallback(f);
   *      if (runGuarded) return () => this.runGuarded(registered);
   *      return () => this.run(registered);
   *
   */
  ZoneCallback bindCallback(f(), { bool runGuarded: true });

  /**
   *  Equivalent to:
   *
   *      ZoneCallback registered = registerUnaryCallback(f);
   *      if (runGuarded) return (arg) => this.runUnaryGuarded(registered, arg);
   *      return (arg) => thin.runUnary(registered, arg);
   */
  ZoneUnaryCallback bindUnaryCallback(f(arg), { bool runGuarded: true });

  /**
   *  Equivalent to:
   *
   *      ZoneCallback registered = registerBinaryCallback(f);
   *      if (runGuarded) {
   *        return (arg1, arg2) => this.runBinaryGuarded(registered, arg);
   *      }
   *      return (arg1, arg2) => thin.runBinary(registered, arg1, arg2);
   */
  ZoneBinaryCallback bindBinaryCallback(
      f(arg1, arg2), { bool runGuarded: true });

  /**
   * Runs [f] asynchronously in this zone.
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
   * Prints the given [line].
   */
  void print(String line);

  /**
   * The error zone is the one that is responsible for dealing with uncaught
   * errors. Errors are not allowed to cross zones with different error-zones.
   */
  Zone get _errorZone;

  /**
   * Call to enter the Zone.
   *
   * The previous current zone is returned.
   */
  static Zone _enter(Zone zone) {
    assert(zone != null);
    assert(!identical(zone, _current));
    Zone previous = _current;
    _current = zone;
    return previous;
  }

  /**
   * Call to leave the Zone.
   *
   * The previous Zone must be provided as `previous`.
   */
  static void _leave(Zone previous) {
    assert(previous != null);
    Zone._current = previous;
  }

  /**
   * Retrieves the zone-value associated with [key].
   *
   * If this zone does not contain the value looks up the same key in the
   * parent zone. If the [key] is not found returns `null`.
   *
   * Any object can be used as key, as long as it has compatible `operator ==`
   * and `hashCode` implementations.
   * By controlling access to the key, a zone can grant or deny access to the
   * zone value.
   */
  operator [](Object key);
}

class _ZoneDelegate implements ZoneDelegate {
  final _BaseZone _degelationTarget;

  Zone get _zone => _degelationTarget;

  const _ZoneDelegate(this._degelationTarget);

  dynamic handleUncaughtError(Zone zone, error, StackTrace stackTrace) {
    _BaseZone parent = _degelationTarget;
    while (parent._specification.handleUncaughtError == null) {
      parent = parent.parent;
    }
    return (parent._specification.handleUncaughtError)(
        parent, new _ZoneDelegate(parent.parent), zone, error, stackTrace);
  }

  dynamic run(Zone zone, f()) {
    _BaseZone parent = _degelationTarget;
    while (parent._specification.run == null) {
      parent = parent.parent;
    }
    return (parent._specification.run)(
        parent, new _ZoneDelegate(parent.parent), zone, f);
  }

  dynamic runUnary(Zone zone, f(arg), arg) {
    _BaseZone parent = _degelationTarget;
    while (parent._specification.runUnary == null) {
      parent = parent.parent;
    }
    return (parent._specification.runUnary)(
        parent, new _ZoneDelegate(parent.parent), zone, f, arg);
  }

  dynamic runBinary(Zone zone, f(arg1, arg2), arg1, arg2) {
    _BaseZone parent = _degelationTarget;
    while (parent._specification.runBinary == null) {
      parent = parent.parent;
    }
    return (parent._specification.runBinary)(
        parent, new _ZoneDelegate(parent.parent), zone, f, arg1, arg2);
  }

  ZoneCallback registerCallback(Zone zone, f()) {
    _BaseZone parent = _degelationTarget;
    while (parent._specification.registerCallback == null) {
      parent = parent.parent;
    }
    return (parent._specification.registerCallback)(
        parent, new _ZoneDelegate(parent.parent), zone, f);
  }

  ZoneUnaryCallback registerUnaryCallback(Zone zone, f(arg)) {
    _BaseZone parent = _degelationTarget;
    while (parent._specification.registerUnaryCallback == null) {
      parent = parent.parent;
    }
    return (parent._specification.registerUnaryCallback)(
        parent, new _ZoneDelegate(parent.parent), zone, f);
  }

  ZoneBinaryCallback registerBinaryCallback(Zone zone, f(arg1, arg2)) {
    _BaseZone parent = _degelationTarget;
    while (parent._specification.registerBinaryCallback == null) {
      parent = parent.parent;
    }
    return (parent._specification.registerBinaryCallback)(
        parent, new _ZoneDelegate(parent.parent), zone, f);
  }

  void scheduleMicrotask(Zone zone, f()) {
    _BaseZone parent = _degelationTarget;
    while (parent._specification.scheduleMicrotask == null) {
      parent = parent.parent;
    }
    _ZoneDelegate grandParent = new _ZoneDelegate(parent.parent);
    Function scheduleMicrotask = parent._specification.scheduleMicrotask;
    scheduleMicrotask(parent, grandParent, zone, f);
  }

  Timer createTimer(Zone zone, Duration duration, void f()) {
    _BaseZone parent = _degelationTarget;
    while (parent._specification.createTimer == null) {
      parent = parent.parent;
    }
    return (parent._specification.createTimer)(
        parent, new _ZoneDelegate(parent.parent), zone, duration, f);
  }

  Timer createPeriodicTimer(Zone zone, Duration period, void f(Timer timer)) {
    _BaseZone parent = _degelationTarget;
    while (parent._specification.createPeriodicTimer == null) {
      parent = parent.parent;
    }
    return (parent._specification.createPeriodicTimer)(
        parent, new _ZoneDelegate(parent.parent), zone, period, f);
  }

  void print(Zone zone, String line) {
    _BaseZone parent = _degelationTarget;
    while (parent._specification.print == null) {
      parent = parent.parent;
    }
    (parent._specification.print)(
        parent, new _ZoneDelegate(parent.parent), zone, line);
  }

  Zone fork(Zone zone, ZoneSpecification specification,
            Map zoneValues) {
    _BaseZone parent = _degelationTarget;
    while (parent._specification.fork == null) {
      parent = parent.parent;
    }
    _ZoneDelegate grandParent = new _ZoneDelegate(parent.parent);
    return (parent._specification.fork)(
        parent, grandParent, zone, specification, zoneValues);
  }
}


/**
 * Base class for Zone implementations.
 */
abstract class _BaseZone implements Zone {
  const _BaseZone();

  /// The parent zone.
  _BaseZone get parent;
  /// The zone's handlers.
  ZoneSpecification get _specification;
  /**
   * The closest error-handling zone.
   *
   * Returns `this` if `this` has an error-handler. Otherwise returns the
   * parent's error-zone.
   */
  Zone get _errorZone;

  bool inSameErrorZone(Zone otherZone) => _errorZone == otherZone._errorZone;

  dynamic runGuarded(f()) {
    try {
      return run(f);
    } catch (e, s) {
      return handleUncaughtError(e, s);
    }
  }

  dynamic runUnaryGuarded(f(arg), arg) {
    try {
      return runUnary(f, arg);
    } catch (e, s) {
      return handleUncaughtError(e, s);
    }
  }

  dynamic runBinaryGuarded(f(arg1, arg2), arg1, arg2) {
    try {
      return runBinary(f, arg1, arg2);
    } catch (e, s) {
      return handleUncaughtError(e, s);
    }
  }

  ZoneCallback bindCallback(f(), { bool runGuarded: true }) {
    ZoneCallback registered = registerCallback(f);
    if (runGuarded) {
      return () => this.runGuarded(registered);
    } else {
      return () => this.run(registered);
    }
  }

  ZoneUnaryCallback bindUnaryCallback(f(arg), { bool runGuarded: true }) {
    ZoneUnaryCallback registered = registerUnaryCallback(f);
    if (runGuarded) {
      return (arg) => this.runUnaryGuarded(registered, arg);
    } else {
      return (arg) => this.runUnary(registered, arg);
    }
  }

  ZoneBinaryCallback bindBinaryCallback(
      f(arg1, arg2), { bool runGuarded: true }) {
    ZoneBinaryCallback registered = registerBinaryCallback(f);
    if (runGuarded) {
      return (arg1, arg2) => this.runBinaryGuarded(registered, arg1, arg2);
    } else {
      return (arg1, arg2) => this.runBinary(registered, arg1, arg2);
    }
  }
}


/**
 * Default implementation of a [Zone].
 */
class _CustomizedZone extends _BaseZone {
  final _BaseZone parent;
  final ZoneSpecification _specification;

  /// The zone's value map.
  final Map _map;

  const _CustomizedZone(this.parent, this._specification, this._map);

  Zone get _errorZone {
    if (_specification.handleUncaughtError != null) return this;
    return parent._errorZone;
  }

  operator [](Object key) {
    var result = _map[key];
    if (result != null || _map.containsKey(key)) return result;
    // If we are not the root zone look up in the parent zone.
    if (parent != null) return parent[key];
    assert(this == Zone.ROOT);
    return null;
  }

  // Methods that can be customized by the zone specification.

  dynamic handleUncaughtError(error, StackTrace stackTrace) {
    return new _ZoneDelegate(this).handleUncaughtError(this, error, stackTrace);
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

  dynamic runBinary(f(arg1, arg2), arg1, arg2) {
    return new _ZoneDelegate(this).runBinary(this, f, arg1, arg2);
  }

  ZoneCallback registerCallback(f()) {
    return new _ZoneDelegate(this).registerCallback(this, f);
  }

  ZoneUnaryCallback registerUnaryCallback(f(arg)) {
    return new _ZoneDelegate(this).registerUnaryCallback(this, f);
  }

  ZoneBinaryCallback registerBinaryCallback(f(arg1, arg2)) {
    return new _ZoneDelegate(this).registerBinaryCallback(this, f);
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

  void print(String line) {
    new _ZoneDelegate(this).print(this, line);
  }
}

void _rootHandleUncaughtError(
    Zone self, ZoneDelegate parent, Zone zone, error, StackTrace stackTrace) {
  self.run(() {
    _scheduleAsyncCallback(() {
      print("Uncaught Error: ${error}");
      var trace = stackTrace;
      if (trace == null && error is Error) trace = error.stackTrace;
      if (trace != null) {
        print("Stack Trace: \n$trace\n");
      }
      throw error;
    });
  });
}

dynamic _rootRun(Zone self, ZoneDelegate parent, Zone zone, f()) {
  if (Zone._current == zone) return f();

  Zone old = Zone._enter(zone);
  try {
    return f();
  } finally {
    Zone._leave(old);
  }
}

dynamic _rootRunUnary(Zone self, ZoneDelegate parent, Zone zone, f(arg), arg) {
  if (Zone._current == zone) return f(arg);

  Zone old = Zone._enter(zone);
  try {
    return f(arg);
  } finally {
    Zone._leave(old);
  }
}

dynamic _rootRunBinary(Zone self, ZoneDelegate parent, Zone zone,
                       f(arg1, arg2), arg1, arg2) {
  if (Zone._current == zone) return f(arg1, arg2);

  Zone old = Zone._enter(zone);
  try {
    return f(arg1, arg2);
  } finally {
    Zone._leave(old);
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

ZoneBinaryCallback _rootRegisterBinaryCallback(
    Zone self, ZoneDelegate parent, Zone zone, f(arg1, arg2)) {
  return f;
}

void _rootScheduleMicrotask(Zone self, ZoneDelegate parent, Zone zone, f()) {
  if (Zone.ROOT != zone) {
    f = zone.bindCallback(f);
  }
  _scheduleAsyncCallback(f);
}

Timer _rootCreateTimer(Zone self, ZoneDelegate parent, Zone zone,
                       Duration duration, void callback()) {
  if (Zone.ROOT != zone) {
    callback = zone.bindCallback(callback);
  }
  return _createTimer(duration, callback);
}

Timer _rootCreatePeriodicTimer(
    Zone self, ZoneDelegate parent, Zone zone,
    Duration duration, void callback(Timer timer)) {
  if (Zone.ROOT != zone) {
    callback = zone.bindUnaryCallback(callback);
  }
  return _createPeriodicTimer(duration, callback);
}

void _rootPrint(Zone self, ZoneDelegate parent, Zone zone, String line) {
  printToConsole(line);
}

void _printToZone(String line) {
  Zone.current.print(line);
}

Zone _rootFork(Zone self, ZoneDelegate parent, Zone zone,
               ZoneSpecification specification,
               Map zoneValues) {
  // TODO(floitsch): it would be nice if we could get rid of this hack.
  // Change the static zoneOrDirectPrint function to go through zones
  // from now on.
  printToZone = _printToZone;

  if (specification == null) {
    specification = const ZoneSpecification();
  } else if (specification is! _ZoneSpecification) {
    throw new ArgumentError("ZoneSpecifications must be instantiated"
        " with the provided constructor.");
  }
  Map copiedMap = new HashMap();
  if (zoneValues != null) {
    zoneValues.forEach((key, value) {
      copiedMap[key] = value;
    });
  }
  return new _CustomizedZone(zone, specification, copiedMap);
}

class _RootZoneSpecification implements ZoneSpecification {
  const _RootZoneSpecification();

  HandleUncaughtErrorHandler get handleUncaughtError =>
      _rootHandleUncaughtError;
  RunHandler get run => _rootRun;
  RunUnaryHandler get runUnary => _rootRunUnary;
  RunBinaryHandler get runBinary => _rootRunBinary;
  RegisterCallbackHandler get registerCallback => _rootRegisterCallback;
  RegisterUnaryCallbackHandler get registerUnaryCallback =>
      _rootRegisterUnaryCallback;
  RegisterBinaryCallbackHandler get registerBinaryCallback =>
      _rootRegisterBinaryCallback;
  ScheduleMicrotaskHandler get scheduleMicrotask => _rootScheduleMicrotask;
  CreateTimerHandler get createTimer => _rootCreateTimer;
  CreatePeriodicTimerHandler get createPeriodicTimer =>
      _rootCreatePeriodicTimer;
  PrintHandler get print => _rootPrint;
  ForkHandler get fork => _rootFork;
}

class _RootZone extends _BaseZone {
  const _RootZone();

  Zone get parent => null;
  ZoneSpecification get _specification => const _RootZoneSpecification();
  Zone get _errorZone => this;

  bool inSameErrorZone(Zone otherZone) => otherZone._errorZone == this;

  operator [](Object key) => null;

  // Methods that can be customized by the zone specification.

  dynamic handleUncaughtError(error, StackTrace stackTrace) =>
      _rootHandleUncaughtError(this, null, this, error, stackTrace);

  Zone fork({ZoneSpecification specification, Map zoneValues}) =>
      _rootFork(this, null, this, specification, zoneValues);

  dynamic run(f()) => _rootRun(this, null, this, f);

  dynamic runUnary(f(arg), arg) => _rootRunUnary(this, null, this, f, arg);

  dynamic runBinary(f(arg1, arg2), arg1, arg2) =>
      _rootRunBinary(this, null, this, f, arg1, arg2);

  ZoneCallback registerCallback(f()) =>
      _rootRegisterCallback(this, null, this, f);

  ZoneUnaryCallback registerUnaryCallback(f(arg)) =>
      _rootRegisterUnaryCallback(this, null, this, f);

  ZoneBinaryCallback registerBinaryCallback(f(arg1, arg2)) =>
      _rootRegisterBinaryCallback(this, null, this, f);

  void scheduleMicrotask(void f()) {
    _rootScheduleMicrotask(this, null, this, f);
  }

  Timer createTimer(Duration duration, void f()) =>
      _rootCreateTimer(this, null, this, duration, f);

  Timer createPeriodicTimer(Duration duration, void f(Timer timer)) =>
      _rootCreatePeriodicTimer(this, null, this, duration, f);

  void print(String line) => _rootPrint(this, null, this, line);
}

const _ROOT_ZONE = const _RootZone();


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
 *     runZoned(() {
 *       future = future.then((_) { throw "error in first error-zone"; });
 *       runZoned(() {
 *         future = future.catchError((e) { print("Never reached!"); });
 *       }, onError: (e) { print("unused error handler"); });
 *     }, onError: (e) { print("catches error of first error-zone."); });
 *
 * Example:
 *
 *     runZoned(() {
 *       new Future(() { throw "asynchronous error"; });
 *     }, onError: print);  // Will print "asynchronous error".
 */
dynamic runZoned(body(),
                 { Map zoneValues,
                   ZoneSpecification zoneSpecification,
                   Function onError }) {
  HandleUncaughtErrorHandler errorHandler;
  if (onError != null) {
    errorHandler = (Zone self, ZoneDelegate parent, Zone zone,
                    error, StackTrace stackTrace) {
      try {
        if (onError is ZoneBinaryCallback) {
          return self.parent.runBinary(onError, error, stackTrace);
        }
        return self.parent.runUnary(onError, error);
      } catch(e, s) {
        if (identical(e, error)) {
          return parent.handleUncaughtError(zone, error, stackTrace);
        } else {
          return parent.handleUncaughtError(zone, e, s);
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
