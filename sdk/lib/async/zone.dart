// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

typedef R ZoneCallback<R>();
typedef R ZoneUnaryCallback<R, T>(T arg);
typedef R ZoneBinaryCallback<R, T1, T2>(T1 arg1, T2 arg2);

// TODO(floitsch): we are abusing generic typedefs as typedefs for generic
// functions.
/*ABUSE*/
typedef R HandleUncaughtErrorHandler<R>(
    Zone self, ZoneDelegate parent, Zone zone, error, StackTrace stackTrace);
/*ABUSE*/
typedef R RunHandler<R>(Zone self, ZoneDelegate parent, Zone zone, R f());
/*ABUSE*/
typedef R RunUnaryHandler<R, T>(
    Zone self, ZoneDelegate parent, Zone zone, R f(T arg), T arg);
/*ABUSE*/
typedef R RunBinaryHandler<R, T1, T2>(
    Zone self, ZoneDelegate parent, Zone zone,
    R f(T1 arg1, T2 arg2), T1 arg1, T2 arg2);
/*ABUSE*/
typedef ZoneCallback<R> RegisterCallbackHandler<R>(
    Zone self, ZoneDelegate parent, Zone zone, R f());
/*ABUSE*/
typedef ZoneUnaryCallback<R, T> RegisterUnaryCallbackHandler<R, T>(
    Zone self, ZoneDelegate parent, Zone zone, R f(T arg));
/*ABUSE*/
typedef ZoneBinaryCallback<R, T1, T2> RegisterBinaryCallbackHandler<R, T1, T2>(
    Zone self, ZoneDelegate parent, Zone zone, R f(T1 arg1, T2 arg2));
typedef AsyncError ErrorCallbackHandler(Zone self, ZoneDelegate parent,
    Zone zone, Object error, StackTrace stackTrace);
typedef void ScheduleMicrotaskHandler(
    Zone self, ZoneDelegate parent, Zone zone, void f());
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

/** Pair of error and stack trace. Returned by [Zone.errorCallback]. */
class AsyncError implements Error {
  final Object error;
  final StackTrace stackTrace;

  AsyncError(this.error, this.stackTrace);

  String toString() => '$error';
}


class _ZoneFunction<T extends Function> {
  final _Zone zone;
  final T function;
  const _ZoneFunction(this.zone, this.function);
}

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
      HandleUncaughtErrorHandler handleUncaughtError,
      RunHandler run,
      RunUnaryHandler runUnary,
      RunBinaryHandler runBinary,
      RegisterCallbackHandler registerCallback,
      RegisterUnaryCallbackHandler registerUnaryCallback,
      RegisterBinaryCallbackHandler registerBinaryCallback,
      ErrorCallbackHandler errorCallback,
      ScheduleMicrotaskHandler scheduleMicrotask,
      CreateTimerHandler createTimer,
      CreatePeriodicTimerHandler createPeriodicTimer,
      PrintHandler print,
      ForkHandler fork
  }) = _ZoneSpecification;

  /**
   * Creates a specification from [other] with the provided handlers overriding
   * the ones in [other].
   */
  factory ZoneSpecification.from(ZoneSpecification other, {
      HandleUncaughtErrorHandler handleUncaughtError: null,
      RunHandler run: null,
      RunUnaryHandler runUnary: null,
      RunBinaryHandler runBinary: null,
      RegisterCallbackHandler registerCallback: null,
      RegisterUnaryCallbackHandler registerUnaryCallback: null,
      RegisterBinaryCallbackHandler registerBinaryCallback: null,
      ErrorCallbackHandler errorCallback: null,
      ScheduleMicrotaskHandler scheduleMicrotask: null,
      CreateTimerHandler createTimer: null,
      CreatePeriodicTimerHandler createPeriodicTimer: null,
      PrintHandler print: null,
      ForkHandler fork: null
  }) {
    return new ZoneSpecification(
      handleUncaughtError: handleUncaughtError ?? other.handleUncaughtError,
      run: run ?? other.run,
      runUnary: runUnary ?? other.runUnary,
      runBinary: runBinary ?? other.runBinary,
      registerCallback: registerCallback ?? other.registerCallback,
      registerUnaryCallback: registerUnaryCallback ??
                             other.registerUnaryCallback,
      registerBinaryCallback: registerBinaryCallback ??
                              other.registerBinaryCallback,
      errorCallback: errorCallback ?? other.errorCallback,
      scheduleMicrotask: scheduleMicrotask ?? other.scheduleMicrotask,
      createTimer : createTimer ?? other.createTimer,
      createPeriodicTimer: createPeriodicTimer ?? other.createPeriodicTimer,
      print : print ?? other.print,
      fork: fork ?? other.fork);
  }

  HandleUncaughtErrorHandler get handleUncaughtError;
  RunHandler get run;
  RunUnaryHandler get runUnary;
  RunBinaryHandler get runBinary;
  RegisterCallbackHandler get registerCallback;
  RegisterUnaryCallbackHandler get registerUnaryCallback;
  RegisterBinaryCallbackHandler get registerBinaryCallback;
  ErrorCallbackHandler get errorCallback;
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
    this.errorCallback: null,
    this.scheduleMicrotask: null,
    this.createTimer: null,
    this.createPeriodicTimer: null,
    this.print: null,
    this.fork: null
  });

  final HandleUncaughtErrorHandler handleUncaughtError;
  final RunHandler run;
  final RunUnaryHandler runUnary;
  final RunBinaryHandler runBinary;
  final RegisterCallbackHandler registerCallback;
  final RegisterUnaryCallbackHandler registerUnaryCallback;
  final RegisterBinaryCallbackHandler registerBinaryCallback;
  final ErrorCallbackHandler errorCallback;
  final ScheduleMicrotaskHandler scheduleMicrotask;
  final CreateTimerHandler createTimer;
  final CreatePeriodicTimerHandler createPeriodicTimer;
  final PrintHandler print;
  final ForkHandler fork;
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
  /*=R*/ handleUncaughtError/*<R>*/(
      Zone zone, error, StackTrace stackTrace);
  /*=R*/ run/*<R>*/(Zone zone, /*=R*/ f());
  /*=R*/ runUnary/*<R, T>*/(Zone zone, /*=R*/ f(/*=T*/ arg), /*=T*/ arg);
  /*=R*/ runBinary/*<R, T1, T2>*/(Zone zone,
      /*=R*/ f(/*=T1*/ arg1, /*=T2*/ arg2), /*=T1*/ arg1, /*=T2*/ arg2);
  ZoneCallback/*<R>*/ registerCallback/*<R>*/(Zone zone, /*=R*/ f());
  ZoneUnaryCallback/*<R, T>*/ registerUnaryCallback/*<R, T>*/(
      Zone zone, /*=R*/ f(/*=T*/ arg));
  ZoneBinaryCallback/*<R, T1, T2>*/ registerBinaryCallback/*<R, T1, T2>*/(
      Zone zone, /*=R*/ f(/*=T1*/ arg1, /*=T2*/ arg2));
  AsyncError errorCallback(Zone zone, Object error, StackTrace stackTrace);
  void scheduleMicrotask(Zone zone, void f());
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

  /** The root zone that is implicitly created. */
  static const Zone ROOT = _ROOT_ZONE;

  /** The currently running zone. */
  static Zone _current = _ROOT_ZONE;

  static Zone get current => _current;

  /*=R*/ handleUncaughtError/*<R>*/(error, StackTrace stackTrace);

  /**
   * Returns the parent zone.
   *
   * Returns `null` if `this` is the [ROOT] zone.
   */
  Zone get parent;

  /**
   * The error zone is the one that is responsible for dealing with uncaught
   * errors.
   * Errors are not allowed to cross between zones with different error-zones.
   *
   * This is the closest parent or ancestor zone of this zone that has a custom
   * [handleUncaughtError] method.
   */
  Zone get errorZone;

  /**
   * Returns true if `this` and [otherZone] are in the same error zone.
   *
   * Two zones are in the same error zone if they inherit their
   * [handleUncaughtError] callback from the same [errorZone].
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
  /*=R*/ run/*<R>*/(/*=R*/ f());

  /**
   * Executes the given callback [f] with argument [arg] in this zone.
   */
  /*=R*/ runUnary/*<R, T>*/(/*=R*/ f(/*=T*/ arg), /*=T*/ arg);

  /**
   * Executes the given callback [f] with argument [arg1] and [arg2] in this
   * zone.
   */
  /*=R*/ runBinary/*<R, T1, T2>*/(
      /*=R*/ f(/*=T1*/ arg1, /*=T2*/ arg2), /*=T1*/ arg1, /*=T2*/ arg2);

  /**
   * Executes the given function [f] in this zone.
   *
   * Same as [run] but catches uncaught errors and gives them to
   * [handleUncaughtError].
   */
  /*=R*/ runGuarded/*<R>*/(/*=R*/ f());

  /**
   * Executes the given callback [f] in this zone.
   *
   * Same as [runUnary] but catches uncaught errors and gives them to
   * [handleUncaughtError].
   */
  /*=R*/ runUnaryGuarded/*<R, T>*/(/*=R*/ f(/*=T*/ arg), /*=T*/ arg);

  /**
   * Executes the given callback [f] in this zone.
   *
   * Same as [runBinary] but catches uncaught errors and gives them to
   * [handleUncaughtError].
   */
  /*=R*/ runBinaryGuarded/*<R, T1, T2>*/(
      /*=R*/ f(/*=T1*/ arg1, /*=T2*/ arg2), /*=T1*/ arg1, /*=T2*/ arg2);

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
  ZoneCallback/*<R>*/ registerCallback/*<R>*/(/*=R*/ callback());

  /**
   * Registers the given callback in this zone.
   *
   * Similar to [registerCallback] but with a unary callback.
   */
  ZoneUnaryCallback/*<R, T>*/ registerUnaryCallback/*<R, T>*/(
      /*=R*/ callback(/*=T*/ arg));

  /**
   * Registers the given callback in this zone.
   *
   * Similar to [registerCallback] but with a unary callback.
   */
  ZoneBinaryCallback/*<R, T1, T2>*/ registerBinaryCallback/*<R, T1, T2>*/(
      /*=R*/ callback(/*=T1*/ arg1, /*=T2*/ arg2));

  /**
   *  Equivalent to:
   *
   *      ZoneCallback registered = registerCallback(f);
   *      if (runGuarded) return () => this.runGuarded(registered);
   *      return () => this.run(registered);
   *
   */
  ZoneCallback/*<R>*/ bindCallback/*<R>*/(
      /*=R*/ f(), { bool runGuarded: true });

  /**
   *  Equivalent to:
   *
   *      ZoneCallback registered = registerUnaryCallback(f);
   *      if (runGuarded) return (arg) => this.runUnaryGuarded(registered, arg);
   *      return (arg) => thin.runUnary(registered, arg);
   */
  ZoneUnaryCallback/*<R, T>*/ bindUnaryCallback/*<R, T>*/(
      /*=R*/ f(/*=T*/ arg), { bool runGuarded: true });

  /**
   *  Equivalent to:
   *
   *      ZoneCallback registered = registerBinaryCallback(f);
   *      if (runGuarded) {
   *        return (arg1, arg2) => this.runBinaryGuarded(registered, arg);
   *      }
   *      return (arg1, arg2) => thin.runBinary(registered, arg1, arg2);
   */
  ZoneBinaryCallback/*<R, T1, T2>*/ bindBinaryCallback/*<R, T1, T2>*/(
      /*=R*/ f(/*=T1*/ arg1, /*=T2*/ arg2), { bool runGuarded: true });

  /**
   * Intercepts errors when added programmatically to a `Future` or `Stream`.
   *
   * When caling [Completer.completeError], [Stream.addError],
   * or [Future] constructors that take an error or a callback that may throw,
   * the current zone is allowed to intercept and replace the error.
   *
   * When other libraries use intermediate controllers or completers, such
   * calls may contain errors that have already been processed.
   *
   * Return `null` if no replacement is desired.
   * The original error is used unchanged in that case.
   * Otherwise return an instance of [AsyncError] holding
   * the new pair of error and stack trace.
   * If the [AsyncError.error] is `null`, it is replaced by a [NullThrownError].
   */
  AsyncError errorCallback(Object error, StackTrace stackTrace);

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

ZoneDelegate _parentDelegate(_Zone zone) {
  if (zone.parent == null) return null;
  return zone.parent._delegate;
}

class _ZoneDelegate implements ZoneDelegate {
  final _Zone _delegationTarget;

  _ZoneDelegate(this._delegationTarget);

  /*=R*/ handleUncaughtError/*<R>*/(
      Zone zone, error, StackTrace stackTrace) {
    var implementation = _delegationTarget._handleUncaughtError;
    _Zone implZone = implementation.zone;
    HandleUncaughtErrorHandler handler = implementation.function;
    // TODO(floitsch): make this a generic method call on '<R>' once it's
    // supported. Remove the unnecessary cast.
    return handler(
        implZone, _parentDelegate(implZone), zone, error, stackTrace)
        as Object/*=R*/;
  }

  /*=R*/ run/*<R>*/(Zone zone, /*=R*/ f()) {
    var implementation = _delegationTarget._run;
    _Zone implZone = implementation.zone;
    RunHandler handler = implementation.function;
    // TODO(floitsch): make this a generic method call on '<R>' once it's
    // supported. Remove the unnecessary cast.
    return handler(implZone, _parentDelegate(implZone), zone, f)
        as Object/*=R*/;
  }

  /*=R*/ runUnary/*<R, T>*/(Zone zone, /*=R*/ f(/*=T*/ arg), /*=T*/ arg) {
    var implementation = _delegationTarget._runUnary;
    _Zone implZone = implementation.zone;
    RunUnaryHandler handler = implementation.function;
    // TODO(floitsch): make this a generic method call on '<R, T>' once it's
    // supported. Remove the unnecessary cast.
    return handler(
        implZone, _parentDelegate(implZone), zone, f, arg) as Object/*=R*/;
  }

  /*=R*/ runBinary/*<R, T1, T2>*/(Zone zone,
      /*=R*/ f(/*=T1*/ arg1, /*=T2*/ arg2), /*=T1*/ arg1, /*=T2*/ arg2) {
    var implementation = _delegationTarget._runBinary;
    _Zone implZone = implementation.zone;
    RunBinaryHandler handler = implementation.function;
    // TODO(floitsch): make this a generic method call on '<R, T1, T2>' once
    // it's supported. Remove the unnecessary cast.
    return handler(
        implZone, _parentDelegate(implZone), zone, f, arg1, arg2)
        as Object/*=R*/;
  }

  ZoneCallback/*<R>*/ registerCallback/*<R>*/(Zone zone, /*=R*/ f()) {
    var implementation = _delegationTarget._registerCallback;
    _Zone implZone = implementation.zone;
    RegisterCallbackHandler handler = implementation.function;
    // TODO(floitsch): make this a generic method call on '<R>' once it's
    // supported. Remove the unnecessary cast.
    return handler(implZone, _parentDelegate(implZone), zone, f)
        as Object/*=ZoneCallback<R>*/;
  }

  ZoneUnaryCallback/*<R, T>*/ registerUnaryCallback/*<R, T>*/(
      Zone zone, /*=R*/ f(/*=T*/ arg)) {
    var implementation = _delegationTarget._registerUnaryCallback;
    _Zone implZone = implementation.zone;
    RegisterUnaryCallbackHandler handler = implementation.function;
    // TODO(floitsch): make this a generic method call on '<R, T>' once it's
    // supported. Remove the unnecessary cast.
    return handler(implZone, _parentDelegate(implZone), zone, f)
        as Object/*=ZoneUnaryCallback<R, T>*/;
  }

  ZoneBinaryCallback/*<R, T1, T2>*/ registerBinaryCallback/*<R, T1, T2>*/(
      Zone zone, /*=R*/ f(/*=T1*/ arg1, /*=T2*/ arg2)) {
    var implementation = _delegationTarget._registerBinaryCallback;
    _Zone implZone = implementation.zone;
    RegisterBinaryCallbackHandler handler = implementation.function;
    // TODO(floitsch): make this a generic method call on '<R, T1, T2>' once
    // it's supported. Remove the unnecessary cast.
    return handler(implZone, _parentDelegate(implZone), zone, f)
        as Object/*=ZoneBinaryCallback<R, T1, T2>*/;
  }

  AsyncError errorCallback(Zone zone, Object error, StackTrace stackTrace) {
    var implementation = _delegationTarget._errorCallback;
    _Zone implZone = implementation.zone;
    if (identical(implZone, _ROOT_ZONE)) return null;
    ErrorCallbackHandler handler = implementation.function;
    return handler(implZone, _parentDelegate(implZone), zone,
                   error, stackTrace);
  }

  void scheduleMicrotask(Zone zone, f()) {
    var implementation = _delegationTarget._scheduleMicrotask;
    _Zone implZone = implementation.zone;
    ScheduleMicrotaskHandler handler = implementation.function;
    handler(implZone, _parentDelegate(implZone), zone, f);
  }

  Timer createTimer(Zone zone, Duration duration, void f()) {
    var implementation = _delegationTarget._createTimer;
    _Zone implZone = implementation.zone;
    CreateTimerHandler handler = implementation.function;
    return handler(implZone, _parentDelegate(implZone), zone, duration, f);
  }

  Timer createPeriodicTimer(Zone zone, Duration period, void f(Timer timer)) {
    var implementation = _delegationTarget._createPeriodicTimer;
    _Zone implZone = implementation.zone;
    CreatePeriodicTimerHandler handler = implementation.function;
    return handler(implZone, _parentDelegate(implZone), zone, period, f);
  }

  void print(Zone zone, String line) {
    var implementation = _delegationTarget._print;
    _Zone implZone = implementation.zone;
    PrintHandler handler = implementation.function;
    handler(implZone, _parentDelegate(implZone), zone, line);
  }

  Zone fork(Zone zone, ZoneSpecification specification,
            Map zoneValues) {
    var implementation = _delegationTarget._fork;
    _Zone implZone = implementation.zone;
    ForkHandler handler = implementation.function;
    return handler(
        implZone, _parentDelegate(implZone), zone, specification, zoneValues);
  }
}


/**
 * Base class for Zone implementations.
 */
abstract class _Zone implements Zone {
  const _Zone();

  _ZoneFunction<RunHandler> get _run;
  _ZoneFunction<RunUnaryHandler> get _runUnary;
  _ZoneFunction<RunBinaryHandler> get _runBinary;
  _ZoneFunction<RegisterCallbackHandler> get _registerCallback;
  _ZoneFunction<RegisterUnaryCallbackHandler> get _registerUnaryCallback;
  _ZoneFunction<RegisterBinaryCallbackHandler> get _registerBinaryCallback;
  _ZoneFunction<ErrorCallbackHandler> get _errorCallback;
  _ZoneFunction<ScheduleMicrotaskHandler> get _scheduleMicrotask;
  _ZoneFunction<CreateTimerHandler> get _createTimer;
  _ZoneFunction<CreatePeriodicTimerHandler> get _createPeriodicTimer;
  _ZoneFunction<PrintHandler> get _print;
  _ZoneFunction<ForkHandler> get _fork;
  _ZoneFunction<HandleUncaughtErrorHandler> get _handleUncaughtError;
  _Zone get parent;
  ZoneDelegate get _delegate;
  Map get _map;

  bool inSameErrorZone(Zone otherZone) {
    return identical(this, otherZone) ||
           identical(errorZone, otherZone.errorZone);
  }
}

class _CustomZone extends _Zone {
  // The actual zone and implementation of each of these
  // inheritable zone functions.
  _ZoneFunction<RunHandler> _run;
  _ZoneFunction<RunUnaryHandler> _runUnary;
  _ZoneFunction<RunBinaryHandler> _runBinary;
  _ZoneFunction<RegisterCallbackHandler> _registerCallback;
  _ZoneFunction<RegisterUnaryCallbackHandler> _registerUnaryCallback;
  _ZoneFunction<RegisterBinaryCallbackHandler> _registerBinaryCallback;
  _ZoneFunction<ErrorCallbackHandler> _errorCallback;
  _ZoneFunction<ScheduleMicrotaskHandler> _scheduleMicrotask;
  _ZoneFunction<CreateTimerHandler> _createTimer;
  _ZoneFunction<CreatePeriodicTimerHandler> _createPeriodicTimer;
  _ZoneFunction<PrintHandler> _print;
  _ZoneFunction<ForkHandler> _fork;
  _ZoneFunction<HandleUncaughtErrorHandler> _handleUncaughtError;

  // A cached delegate to this zone.
  ZoneDelegate _delegateCache;

  /// The parent zone.
  final _Zone parent;

  /// The zone's scoped value declaration map.
  ///
  /// This is always a [HashMap].
  final Map _map;

  ZoneDelegate get _delegate {
    if (_delegateCache != null) return _delegateCache;
    _delegateCache = new _ZoneDelegate(this);
    return _delegateCache;
  }

  _CustomZone(this.parent, ZoneSpecification specification, this._map) {
    // The root zone will have implementations of all parts of the
    // specification, so it will never try to access the (null) parent.
    // All other zones have a non-null parent.
    _run = (specification.run != null)
        ? new _ZoneFunction<RunHandler>(this, specification.run)
        : parent._run;
    _runUnary = (specification.runUnary != null)
        ? new _ZoneFunction<RunUnaryHandler>(this, specification.runUnary)
        : parent._runUnary;
    _runBinary = (specification.runBinary != null)
        ? new _ZoneFunction<RunBinaryHandler>(this, specification.runBinary)
        : parent._runBinary;
    _registerCallback = (specification.registerCallback != null)
        ? new _ZoneFunction<RegisterCallbackHandler>(
            this, specification.registerCallback)
        : parent._registerCallback;
    _registerUnaryCallback = (specification.registerUnaryCallback != null)
        ? new _ZoneFunction<RegisterUnaryCallbackHandler>(
            this, specification.registerUnaryCallback)
        : parent._registerUnaryCallback;
    _registerBinaryCallback = (specification.registerBinaryCallback != null)
        ? new _ZoneFunction<RegisterBinaryCallbackHandler>(
            this, specification.registerBinaryCallback)
        : parent._registerBinaryCallback;
    _errorCallback = (specification.errorCallback != null)
        ? new _ZoneFunction<ErrorCallbackHandler>(
            this, specification.errorCallback)
        : parent._errorCallback;
    _scheduleMicrotask = (specification.scheduleMicrotask != null)
        ? new _ZoneFunction<ScheduleMicrotaskHandler>(
            this, specification.scheduleMicrotask)
        : parent._scheduleMicrotask;
    _createTimer = (specification.createTimer != null)
        ? new _ZoneFunction<CreateTimerHandler>(this, specification.createTimer)
        : parent._createTimer;
    _createPeriodicTimer = (specification.createPeriodicTimer != null)
        ? new _ZoneFunction<CreatePeriodicTimerHandler>(
            this, specification.createPeriodicTimer)
        : parent._createPeriodicTimer;
    _print = (specification.print != null)
        ? new _ZoneFunction<PrintHandler>(this, specification.print)
        : parent._print;
    _fork = (specification.fork != null)
        ? new _ZoneFunction<ForkHandler>(this, specification.fork)
        : parent._fork;
    _handleUncaughtError = (specification.handleUncaughtError != null)
        ? new _ZoneFunction<HandleUncaughtErrorHandler>(
            this, specification.handleUncaughtError)
        : parent._handleUncaughtError;
  }

  /**
   * The closest error-handling zone.
   *
   * Returns `this` if `this` has an error-handler. Otherwise returns the
   * parent's error-zone.
   */
  Zone get errorZone => _handleUncaughtError.zone;

  /*=R*/ runGuarded/*<R>*/(/*=R*/ f()) {
    try {
      return run(f);
    } catch (e, s) {
      return handleUncaughtError(e, s);
    }
  }

  /*=R*/ runUnaryGuarded/*<R, T>*/(/*=R*/ f(/*=T*/ arg), /*=T*/ arg) {
    try {
      return runUnary(f, arg);
    } catch (e, s) {
      return handleUncaughtError(e, s);
    }
  }

  /*=R*/ runBinaryGuarded/*<R, T1, T2>*/(
      /*=R*/ f(/*=T1*/ arg1, /*=T2*/ arg2), /*=T1*/ arg1, /*=T2*/ arg2) {
    try {
      return runBinary(f, arg1, arg2);
    } catch (e, s) {
      return handleUncaughtError(e, s);
    }
  }

  ZoneCallback/*<R>*/ bindCallback/*<R>*/(
      /*=R*/ f(), { bool runGuarded: true }) {
    var registered = registerCallback(f);
    if (runGuarded) {
      return () => this.runGuarded(registered);
    } else {
      return () => this.run(registered);
    }
  }

  ZoneUnaryCallback/*<R, T>*/ bindUnaryCallback/*<R, T>*/(
      /*=R*/ f(/*=T*/ arg), { bool runGuarded: true }) {
    var registered = registerUnaryCallback(f);
    if (runGuarded) {
      return (arg) => this.runUnaryGuarded(registered, arg);
    } else {
      return (arg) => this.runUnary(registered, arg);
    }
  }

  ZoneBinaryCallback/*<R, T1, T2>*/ bindBinaryCallback/*<R, T1, T2>*/(
      /*=R*/ f(/*=T1*/ arg1, /*=T2*/ arg2), { bool runGuarded: true }) {
    var registered = registerBinaryCallback(f);
    if (runGuarded) {
      return (arg1, arg2) => this.runBinaryGuarded(registered, arg1, arg2);
    } else {
      return (arg1, arg2) => this.runBinary(registered, arg1, arg2);
    }
  }

  operator [](Object key) {
    var result = _map[key];
    if (result != null || _map.containsKey(key)) return result;
    // If we are not the root zone, look up in the parent zone.
    if (parent != null) {
      // We do not optimize for repeatedly looking up a key which isn't
      // there. That would require storing the key and keeping it alive.
      // Copying the key/value from the parent does not keep any new values
      // alive.
      var value = parent[key];
      if (value != null) {
        _map[key] = value;
      }
      return value;
    }
    assert(this == _ROOT_ZONE);
    return null;
  }

  // Methods that can be customized by the zone specification.

  /*=R*/ handleUncaughtError/*<R>*/(error, StackTrace stackTrace) {
    var implementation = this._handleUncaughtError;
    assert(implementation != null);
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    HandleUncaughtErrorHandler handler = implementation.function;
    // TODO(floitsch): make this a generic method call on '<R>' once it's
    // supported. Remove the unnecessary cast.
    return handler(
        implementation.zone, parentDelegate, this, error, stackTrace)
        as Object/*=R*/;
  }

  Zone fork({ZoneSpecification specification, Map zoneValues}) {
    var implementation = this._fork;
    assert(implementation != null);
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    ForkHandler handler = implementation.function;
    return handler(implementation.zone, parentDelegate, this,
                   specification, zoneValues);
  }

  /*=R*/ run/*<R>*/(/*=R*/ f()) {
    var implementation = this._run;
    assert(implementation != null);
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    RunHandler handler = implementation.function;
    // TODO(floitsch): make this a generic method call on '<R>' once it's
    // supported. Remove the unnecessary cast.
    return handler(implementation.zone, parentDelegate, this, f)
        as Object/*=R*/;
  }

  /*=R*/ runUnary/*<R, T>*/(/*=R*/ f(/*=T*/ arg), /*=T*/ arg) {
    var implementation = this._runUnary;
    assert(implementation != null);
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    RunUnaryHandler handler = implementation.function;
    // TODO(floitsch): make this a generic method call on '<R, T>' once it's
    // supported. Remove the unnecessary cast.
    return handler(implementation.zone, parentDelegate, this, f, arg)
        as Object/*=R*/;
  }

  /*=R*/ runBinary/*<R, T1, T2>*/(
      /*=R*/ f(/*=T1*/ arg1, /*=T2*/ arg2), /*=T1*/ arg1, /*=T2*/ arg2) {
    var implementation = this._runBinary;
    assert(implementation != null);
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    RunBinaryHandler handler = implementation.function;
    // TODO(floitsch): make this a generic method call on '<R, T1, T2>' once
    // it's supported. Remove the unnecessary cast.
    return handler(
        implementation.zone, parentDelegate, this, f, arg1, arg2)
        as Object/*=R*/;
  }

  ZoneCallback/*<R>*/ registerCallback/*<R>*/(/*=R*/ callback()) {
    var implementation = this._registerCallback;
    assert(implementation != null);
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    RegisterCallbackHandler handler = implementation.function;
    // TODO(floitsch): make this a generic method call on '<R>' once it's
    // supported. Remove the unnecessary cast.
    return handler(implementation.zone, parentDelegate, this, callback)
        as Object/*=ZoneCallback<R>*/;
  }

  ZoneUnaryCallback/*<R, T>*/ registerUnaryCallback/*<R, T>*/(
      /*=R*/ callback(/*=T*/ arg)) {
    var implementation = this._registerUnaryCallback;
    assert(implementation != null);
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    RegisterUnaryCallbackHandler handler = implementation.function;
    // TODO(floitsch): make this a generic method call on '<R, T>' once it's
    // supported. Remove the unnecessary cast.
    return handler(implementation.zone, parentDelegate, this, callback)
        as Object/*=ZoneUnaryCallback<R, T>*/;
  }

  ZoneBinaryCallback/*<R, T1, T2>*/ registerBinaryCallback/*<R, T1, T2>*/(
      /*=R*/ callback(/*=T1*/ arg1, /*=T2*/ arg2)) {
    var implementation = this._registerBinaryCallback;
    assert(implementation != null);
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    RegisterBinaryCallbackHandler handler = implementation.function;
    // TODO(floitsch): make this a generic method call on '<R, T1, T2>' once
    // it's supported. Remove the unnecessary cast.
    return handler(implementation.zone, parentDelegate, this, callback)
        as Object/*=ZoneBinaryCallback<R, T1, T2>*/;
  }

  AsyncError errorCallback(Object error, StackTrace stackTrace) {
    var implementation = this._errorCallback;
    assert(implementation != null);
    final Zone implementationZone = implementation.zone;
    if (identical(implementationZone, _ROOT_ZONE)) return null;
    final ZoneDelegate parentDelegate = _parentDelegate(implementationZone);
    ErrorCallbackHandler handler = implementation.function;
    return handler(
        implementationZone, parentDelegate, this, error, stackTrace);
  }

  void scheduleMicrotask(void f()) {
    var implementation = this._scheduleMicrotask;
    assert(implementation != null);
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    ScheduleMicrotaskHandler handler = implementation.function;
    return handler(implementation.zone, parentDelegate, this, f);
  }

  Timer createTimer(Duration duration, void f()) {
    var implementation = this._createTimer;
    assert(implementation != null);
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    CreateTimerHandler handler = implementation.function;
    return handler(implementation.zone, parentDelegate, this, duration, f);
  }

  Timer createPeriodicTimer(Duration duration, void f(Timer timer)) {
    var implementation = this._createPeriodicTimer;
    assert(implementation != null);
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    CreatePeriodicTimerHandler handler = implementation.function;
    return handler(
        implementation.zone, parentDelegate, this, duration, f);
  }

  void print(String line) {
    var implementation = this._print;
    assert(implementation != null);
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    PrintHandler handler = implementation.function;
    return handler(implementation.zone, parentDelegate, this, line);
  }
}

/*=R*/ _rootHandleUncaughtError/*<R>*/(
    Zone self, ZoneDelegate parent, Zone zone, error, StackTrace stackTrace) {
  _schedulePriorityAsyncCallback(() {
    if (error == null) error = new NullThrownError();
    if (stackTrace == null) throw error;
    _rethrow(error, stackTrace);
  });
}

external void _rethrow(Object error, StackTrace stackTrace);

/*=R*/ _rootRun/*<R>*/(Zone self, ZoneDelegate parent, Zone zone, /*=R*/ f()) {
  if (Zone._current == zone) return f();

  Zone old = Zone._enter(zone);
  try {
    return f();
  } finally {
    Zone._leave(old);
  }
}

/*=R*/ _rootRunUnary/*<R, T>*/(Zone self, ZoneDelegate parent, Zone zone,
    /*=R*/ f(/*=T*/ arg), /*=T*/ arg) {
  if (Zone._current == zone) return f(arg);

  Zone old = Zone._enter(zone);
  try {
    return f(arg);
  } finally {
    Zone._leave(old);
  }
}

/*=R*/ _rootRunBinary/*<R, T1, T2>*/(Zone self, ZoneDelegate parent, Zone zone,
    /*=R*/ f(/*=T1*/ arg1, /*=T2*/ arg2), /*=T1*/ arg1, /*=T2*/ arg2) {
  if (Zone._current == zone) return f(arg1, arg2);

  Zone old = Zone._enter(zone);
  try {
    return f(arg1, arg2);
  } finally {
    Zone._leave(old);
  }
}

ZoneCallback/*<R>*/ _rootRegisterCallback/*<R>*/(
    Zone self, ZoneDelegate parent, Zone zone, /*=R*/ f()) {
  return f;
}

ZoneUnaryCallback/*<R, T>*/ _rootRegisterUnaryCallback/*<R, T>*/(
    Zone self, ZoneDelegate parent, Zone zone, /*=R*/ f(/*=T*/ arg)) {
  return f;
}

ZoneBinaryCallback/*<R, T1, T2>*/ _rootRegisterBinaryCallback/*<R, T1, T2>*/(
    Zone self, ZoneDelegate parent, Zone zone,
    /*=R*/ f(/*=T1*/ arg1, /*=T2*/ arg2)) {
  return f;
}

AsyncError _rootErrorCallback(Zone self, ZoneDelegate parent, Zone zone,
                              Object error, StackTrace stackTrace) => null;

void _rootScheduleMicrotask(Zone self, ZoneDelegate parent, Zone zone, f()) {
  if (!identical(_ROOT_ZONE, zone)) {
    bool hasErrorHandler = !_ROOT_ZONE.inSameErrorZone(zone);
    f = zone.bindCallback(f, runGuarded: hasErrorHandler);
    // Use root zone as event zone if the function is already bound.
    zone = _ROOT_ZONE;
  }
  _scheduleAsyncCallback(f);
}

Timer _rootCreateTimer(Zone self, ZoneDelegate parent, Zone zone,
                       Duration duration, void callback()) {
  if (!identical(_ROOT_ZONE, zone)) {
    callback = zone.bindCallback(callback);
  }
  return Timer._createTimer(duration, callback);
}

Timer _rootCreatePeriodicTimer(
    Zone self, ZoneDelegate parent, Zone zone,
    Duration duration, void callback(Timer timer)) {
  if (!identical(_ROOT_ZONE, zone)) {
    // TODO(floitsch): the return type should be 'void'.
    callback = zone.bindUnaryCallback/*<dynamic, Timer>*/(callback);
  }
  return Timer._createPeriodicTimer(duration, callback);
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
  Map valueMap;
  if (zoneValues == null) {
    if (zone is _Zone) {
      valueMap = zone._map;
    } else {
      valueMap = new HashMap();
    }
  } else {
    valueMap = new HashMap.from(zoneValues);
  }
  return new _CustomZone(zone, specification, valueMap);
}

class _RootZone extends _Zone {
  const _RootZone();

  _ZoneFunction<RunHandler> get _run =>
      const _ZoneFunction<RunHandler>(_ROOT_ZONE, _rootRun);
  _ZoneFunction<RunUnaryHandler> get _runUnary =>
      const _ZoneFunction<RunUnaryHandler>(_ROOT_ZONE, _rootRunUnary);
  _ZoneFunction<RunBinaryHandler> get _runBinary =>
      const _ZoneFunction<RunBinaryHandler>(_ROOT_ZONE, _rootRunBinary);
  _ZoneFunction<RegisterCallbackHandler> get _registerCallback =>
      const _ZoneFunction<RegisterCallbackHandler>(
          _ROOT_ZONE, _rootRegisterCallback);
  _ZoneFunction<RegisterUnaryCallbackHandler> get _registerUnaryCallback =>
      const _ZoneFunction<RegisterUnaryCallbackHandler>(
          _ROOT_ZONE, _rootRegisterUnaryCallback);
  _ZoneFunction<RegisterBinaryCallbackHandler> get _registerBinaryCallback =>
      const _ZoneFunction<RegisterBinaryCallbackHandler>(
          _ROOT_ZONE, _rootRegisterBinaryCallback);
  _ZoneFunction<ErrorCallbackHandler> get _errorCallback =>
      const _ZoneFunction<ErrorCallbackHandler>(_ROOT_ZONE, _rootErrorCallback);
  _ZoneFunction<ScheduleMicrotaskHandler> get _scheduleMicrotask =>
      const _ZoneFunction<ScheduleMicrotaskHandler>(
          _ROOT_ZONE, _rootScheduleMicrotask);
  _ZoneFunction<CreateTimerHandler> get _createTimer =>
      const _ZoneFunction<CreateTimerHandler>(_ROOT_ZONE, _rootCreateTimer);
  _ZoneFunction<CreatePeriodicTimerHandler> get _createPeriodicTimer =>
      const _ZoneFunction<CreatePeriodicTimerHandler>(_ROOT_ZONE, _rootCreatePeriodicTimer);
  _ZoneFunction<PrintHandler> get _print =>
      const _ZoneFunction<PrintHandler>(_ROOT_ZONE, _rootPrint);
  _ZoneFunction<ForkHandler> get _fork =>
      const _ZoneFunction<ForkHandler>(_ROOT_ZONE, _rootFork);
  _ZoneFunction<HandleUncaughtErrorHandler> get _handleUncaughtError =>
      const _ZoneFunction<HandleUncaughtErrorHandler>(
          _ROOT_ZONE, _rootHandleUncaughtError);

  // The parent zone.
  _Zone get parent => null;

  /// The zone's scoped value declaration map.
  ///
  /// This is always a [HashMap].
  Map get _map => _rootMap;

  static Map _rootMap = new HashMap();

  static ZoneDelegate _rootDelegate;

  ZoneDelegate get _delegate {
    if (_rootDelegate != null) return _rootDelegate;
    return _rootDelegate = new _ZoneDelegate(this);
  }

  /**
   * The closest error-handling zone.
   *
   * Returns `this` if `this` has an error-handler. Otherwise returns the
   * parent's error-zone.
   */
  Zone get errorZone => this;

  // Zone interface.

  /*=R*/ runGuarded/*<R>*/(/*=R*/ f()) {
    try {
      if (identical(_ROOT_ZONE, Zone._current)) {
        return f();
      }
      return _rootRun/*<R>*/(null, null, this, f);
    } catch (e, s) {
      return handleUncaughtError/*<R>*/(e, s);
    }
  }

  /*=R*/ runUnaryGuarded/*<R, T>*/(/*=R*/ f(/*=T*/ arg), /*=T*/ arg) {
    try {
      if (identical(_ROOT_ZONE, Zone._current)) {
        return f(arg);
      }
      return _rootRunUnary/*<R, T>*/(null, null, this, f, arg);
    } catch (e, s) {
      return handleUncaughtError/*<R>*/(e, s);
    }
  }

  /*=R*/ runBinaryGuarded/*<R, T1, T2>*/(
      /*=R*/ f(/*=T1*/ arg1, /*=T2*/ arg2), /*=T1*/ arg1, /*=T2*/ arg2) {
    try {
      if (identical(_ROOT_ZONE, Zone._current)) {
        return f(arg1, arg2);
      }
      return _rootRunBinary/*<R, T1, T2>*/(null, null, this, f, arg1, arg2);
    } catch (e, s) {
      return handleUncaughtError/*<R>*/(e, s);
    }
  }

  ZoneCallback/*<R>*/ bindCallback/*<R>*/(
      /*=R*/ f(), { bool runGuarded: true }) {
    if (runGuarded) {
      return () => this.runGuarded/*<R>*/(f);
    } else {
      return () => this.run/*<R>*/(f);
    }
  }

  ZoneUnaryCallback/*<R, T>*/ bindUnaryCallback/*<R, T>*/(
      /*=R*/ f(/*=T*/ arg), { bool runGuarded: true }) {
    if (runGuarded) {
      return (arg) => this.runUnaryGuarded/*<R, T>*/(f, arg);
    } else {
      return (arg) => this.runUnary/*<R, T>*/(f, arg);
    }
  }

  ZoneBinaryCallback/*<R, T1, T2>*/ bindBinaryCallback/*<R, T1, T2>*/(
      /*=R*/ f(/*=T1*/ arg1, /*=T2*/ arg2), { bool runGuarded: true }) {
    if (runGuarded) {
      return (arg1, arg2) =>
          this.runBinaryGuarded/*<R, T1, T2>*/(f, arg1, arg2);
    } else {
      return (arg1, arg2) => this.runBinary/*<R, T1, T2>*/(f, arg1, arg2);
    }
  }

  operator [](Object key) => null;

  // Methods that can be customized by the zone specification.

  /*=R*/ handleUncaughtError/*<R>*/(error, StackTrace stackTrace) {
    return _rootHandleUncaughtError(null, null, this, error, stackTrace);
  }

  Zone fork({ZoneSpecification specification, Map zoneValues}) {
    return _rootFork(null, null, this, specification, zoneValues);
  }

  /*=R*/ run/*<R>*/(/*=R*/ f()) {
    if (identical(Zone._current, _ROOT_ZONE)) return f();
    return _rootRun(null, null, this, f);
  }

  /*=R*/ runUnary/*<R, T>*/(/*=R*/ f(/*=T*/ arg), /*=T*/ arg) {
    if (identical(Zone._current, _ROOT_ZONE)) return f(arg);
    return _rootRunUnary(null, null, this, f, arg);
  }

  /*=R*/ runBinary/*<R, T1, T2>*/(
      /*=R*/ f(/*=T1*/ arg1, /*=T2*/ arg2), /*=T1*/ arg1, /*=T2*/ arg2) {
    if (identical(Zone._current, _ROOT_ZONE)) return f(arg1, arg2);
    return _rootRunBinary(null, null, this, f, arg1, arg2);
  }

  ZoneCallback/*<R>*/ registerCallback/*<R>*/(/*=R*/ f()) => f;

  ZoneUnaryCallback/*<R, T>*/ registerUnaryCallback/*<R, T>*/(
      /*=R*/ f(/*=T*/ arg)) => f;

  ZoneBinaryCallback/*<R, T1, T2>*/ registerBinaryCallback/*<R, T1, T2>*/(
      /*=R*/ f(/*=T1*/ arg1, /*=T2*/ arg2)) => f;

  AsyncError errorCallback(Object error, StackTrace stackTrace) => null;

  void scheduleMicrotask(void f()) {
    _rootScheduleMicrotask(null, null, this, f);
  }

  Timer createTimer(Duration duration, void f()) {
    return Timer._createTimer(duration, f);
  }

  Timer createPeriodicTimer(Duration duration, void f(Timer timer)) {
    return Timer._createPeriodicTimer(duration, f);
  }

  void print(String line) {
    printToConsole(line);
  }
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
/*=R*/ runZoned/*<R>*/(/*=R*/ body(),
                 { Map zoneValues,
                   ZoneSpecification zoneSpecification,
                   Function onError }) {
  HandleUncaughtErrorHandler errorHandler;
  if (onError != null) {
    errorHandler = (Zone self, ZoneDelegate parent, Zone zone,
                    error, StackTrace stackTrace) {
      try {
        if (onError is ZoneBinaryCallback<dynamic/*=R*/, dynamic, StackTrace>) {
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
