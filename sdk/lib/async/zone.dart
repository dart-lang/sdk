// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

typedef R ZoneCallback<R>();
typedef R ZoneUnaryCallback<R, T>(T arg);
typedef R ZoneBinaryCallback<R, T1, T2>(T1 arg1, T2 arg2);

typedef HandleUncaughtErrorHandler = void Function(Zone self,
    ZoneDelegate parent, Zone zone, Object error, StackTrace stackTrace);
typedef RunHandler = R Function<R>(
    Zone self, ZoneDelegate parent, Zone zone, R Function() f);
typedef RunUnaryHandler = R Function<R, T>(
    Zone self, ZoneDelegate parent, Zone zone, R Function(T arg) f, T arg);
typedef RunBinaryHandler = R Function<R, T1, T2>(Zone self, ZoneDelegate parent,
    Zone zone, R Function(T1 arg1, T2 arg2) f, T1 arg1, T2 arg2);
typedef RegisterCallbackHandler = ZoneCallback<R> Function<R>(
    Zone self, ZoneDelegate parent, Zone zone, R Function() f);
typedef RegisterUnaryCallbackHandler = ZoneUnaryCallback<R, T> Function<R, T>(
    Zone self, ZoneDelegate parent, Zone zone, R Function(T arg) f);
typedef RegisterBinaryCallbackHandler
    = ZoneBinaryCallback<R, T1, T2> Function<R, T1, T2>(Zone self,
        ZoneDelegate parent, Zone zone, R Function(T1 arg1, T2 arg2) f);
typedef AsyncError ErrorCallbackHandler(Zone self, ZoneDelegate parent,
    Zone zone, Object error, StackTrace stackTrace);
typedef void ScheduleMicrotaskHandler(
    Zone self, ZoneDelegate parent, Zone zone, void f());
typedef Timer CreateTimerHandler(
    Zone self, ZoneDelegate parent, Zone zone, Duration duration, void f());
typedef Timer CreatePeriodicTimerHandler(Zone self, ZoneDelegate parent,
    Zone zone, Duration period, void f(Timer timer));
typedef void PrintHandler(
    Zone self, ZoneDelegate parent, Zone zone, String line);
typedef Zone ForkHandler(Zone self, ZoneDelegate parent, Zone zone,
    ZoneSpecification specification, Map zoneValues);

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
  const factory ZoneSpecification(
      {HandleUncaughtErrorHandler handleUncaughtError,
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
      ForkHandler fork}) = _ZoneSpecification;

  /**
   * Creates a specification from [other] with the provided handlers overriding
   * the ones in [other].
   */
  factory ZoneSpecification.from(ZoneSpecification other,
      {HandleUncaughtErrorHandler handleUncaughtError: null,
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
      ForkHandler fork: null}) {
    return new ZoneSpecification(
        handleUncaughtError: handleUncaughtError ?? other.handleUncaughtError,
        run: run ?? other.run,
        runUnary: runUnary ?? other.runUnary,
        runBinary: runBinary ?? other.runBinary,
        registerCallback: registerCallback ?? other.registerCallback,
        registerUnaryCallback:
            registerUnaryCallback ?? other.registerUnaryCallback,
        registerBinaryCallback:
            registerBinaryCallback ?? other.registerBinaryCallback,
        errorCallback: errorCallback ?? other.errorCallback,
        scheduleMicrotask: scheduleMicrotask ?? other.scheduleMicrotask,
        createTimer: createTimer ?? other.createTimer,
        createPeriodicTimer: createPeriodicTimer ?? other.createPeriodicTimer,
        print: print ?? other.print,
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
  const _ZoneSpecification(
      {this.handleUncaughtError: null,
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
      this.fork: null});

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
 * An adapted view of the parent zone.
 *
 * This class allows the implementation of a zone method to invoke methods on
 * the parent zone while retaining knowledge of the originating zone.
 *
 * Custom zones (created through [Zone.fork] or [runZoned]) can provide
 * implementations of most methods of zones. This is similar to overriding
 * methods on [Zone], except that this mechanism doesn't require subclassing.
 *
 * A custom zone function (provided through a [ZoneSpecification]) typically
 * records or wraps its parameters and then delegates the operation to its
 * parent zone using the provided [ZoneDelegate].
 *
 * While zones have access to their parent zone (through [Zone.parent]) it is
 * recommended to call the methods on the provided parent delegate for two
 * reasons:
 * 1. the delegate methods take an additional `zone` argument which is the
 *   zone the action has been initiated in.
 * 2. delegate calls are more efficient, since the implementation knows how
 *   to skip zones that would just delegate to their parents.
 */
abstract class ZoneDelegate {
  void handleUncaughtError(Zone zone, error, StackTrace stackTrace);
  R run<R>(Zone zone, R f());
  R runUnary<R, T>(Zone zone, R f(T arg), T arg);
  R runBinary<R, T1, T2>(Zone zone, R f(T1 arg1, T2 arg2), T1 arg1, T2 arg2);
  ZoneCallback<R> registerCallback<R>(Zone zone, R f());
  ZoneUnaryCallback<R, T> registerUnaryCallback<R, T>(Zone zone, R f(T arg));
  ZoneBinaryCallback<R, T1, T2> registerBinaryCallback<R, T1, T2>(
      Zone zone, R f(T1 arg1, T2 arg2));
  AsyncError errorCallback(Zone zone, Object error, StackTrace stackTrace);
  void scheduleMicrotask(Zone zone, void f());
  Timer createTimer(Zone zone, Duration duration, void f());
  Timer createPeriodicTimer(Zone zone, Duration period, void f(Timer timer));
  void print(Zone zone, String line);
  Zone fork(Zone zone, ZoneSpecification specification, Map zoneValues);
}

/**
 * A zone represents an environment that remains stable across asynchronous
 * calls.
 *
 * Code is always executed in the context of a zone, available as
 * [Zone.current]. The initial `main` function runs in the context of the
 * default zone ([Zone.root]). Code can be run in a different zone using either
 * [runZoned], to create a new zone, or [Zone.run] to run code in the context of
 * an existing zone likely created using [Zone.fork].
 *
 * Developers can create a new zone that overrides some of the functionality of
 * an existing zone. For example, custom zones can replace of modify the
 * behavior of `print`, timers, microtasks or how uncaught errors are handled.
 *
 * The [Zone] class is not subclassable, but users can provide custom zones by
 * forking an existing zone (usually [Zone.current]) with a [ZoneSpecification].
 * This is similar to creating a new class that extends the base `Zone` class
 * and that overrides some methods, except without actually creating a new
 * class. Instead the overriding methods are provided as functions that
 * explicitly take the equivalent of their own class, the "super" class and the
 * `this` object as parameters.
 *
 * Asynchronous callbacks always run in the context of the zone where they were
 * scheduled. This is implemented using two steps:
 * 1. the callback is first registered using one of [registerCallback],
 *   [registerUnaryCallback], or [registerBinaryCallback]. This allows the zone
 *   to record that a callback exists and potentially modify it (by returning a
 *   different callback). The code doing the registration (e.g., `Future.then`)
 *   also remembers the current zone so that it can later run the callback in
 *   that zone.
 * 2. At a later point the registered callback is run in the remembered zone.
 *
 * This is all handled internally by the platform code and most users don't need
 * to worry about it. However, developers of new asynchronous operations,
 * provided by the underlying system or through native extensions, must follow
 * the protocol to be zone compatible.
 *
 * For convenience, zones provide [bindCallback] (and the corresponding
 * [bindUnaryCallback] and [bindBinaryCallback]) to make it easier to respect
 * the zone contract: these functions first invoke the corresponding `register`
 * functions and then wrap the returned function so that it runs in the current
 * zone when it is later asynchronously invoked.
 *
 * Similarly, zones provide [bindCallbackGuarded] (and the corresponding
 * [bindUnaryCallbackGuarded] and [bindBinaryCallbackGuarded]), when the
 * callback should be invoked through [Zone.runGuarded].
 */
abstract class Zone {
  // Private constructor so that it is not possible instantiate a Zone class.
  Zone._();

  /**
   * The root zone.
   *
   * All isolate entry functions (`main` or spawned functions) start running in
   * the root zone (that is, [Zone.current] is identical to [Zone.root] when the
   * entry function is called). If no custom zone is created, the rest of the
   * program always runs in the root zone.
   *
   * The root zone implements the default behavior of all zone operations.
   * Many methods, like [registerCallback] do the bare minimum required of the
   * function, and are only provided as a hook for custom zones. Others, like
   * [scheduleMicrotask], interact with the underlying system to implement the
   * desired behavior.
   */
  static const Zone root = _rootZone;
  @Deprecated("Use root instead")
  static const Zone ROOT = root;

  /** The currently running zone. */
  static Zone _current = _rootZone;

  /** The zone that is currently active. */
  static Zone get current => _current;

  /**
   * Handles uncaught asynchronous errors.
   *
   * There are two kind of asynchronous errors that are handled by this
   * function:
   * 1. Uncaught errors that were thrown in asynchronous callbacks, for example,
   *   a `throw` in the function passed to [Timer.run].
   * 2. Asynchronous errors that are pushed through [Future] and [Stream]
   *   chains, but for which no child registered an error handler.
   *   Most asynchronous classes, like [Future] or [Stream] push errors to their
   *   listeners. Errors are propagated this way until either a listener handles
   *   the error (for example with [Future.catchError]), or no listener is
   *   available anymore. In the latter case, futures and streams invoke the
   *   zone's [handleUncaughtError].
   *
   * By default, when handled by the root zone, uncaught asynchronous errors are
   * treated like uncaught synchronous exceptions.
   */
  void handleUncaughtError(error, StackTrace stackTrace);

  /**
   * The parent zone of the this zone.
   *
   * Is `null` if `this` is the [root] zone.
   *
   * Zones are created by [fork] on an existing zone, or by [runZoned] which
   * forks the [current] zone. The new zone's parent zone is the zone it was
   * forked from.
   */
  Zone get parent;

  /**
   * The error zone is the one that is responsible for dealing with uncaught
   * errors.
   *
   * This is the closest parent zone of this zone that provides a
   * [handleUncaughtError] method.
   *
   * Asynchronous errors never cross zone boundaries between zones with
   * different error handlers.
   *
   * Example:
   * ```
   * import 'dart:async';
   *
   * main() {
   *   var future;
   *   runZoned(() {
   *     // The asynchronous error is caught by the custom zone which prints
   *     // 'asynchronous error'.
   *     future = new Future.error("asynchronous error");
   *   }, onError: (e) { print(e); });  // Creates a zone with an error handler.
   *   // The following `catchError` handler is never invoked, because the
   *   // custom zone created by the call to `runZoned` provides an
   *   // error handler.
   *   future.catchError((e) { throw "is never reached"; });
   * }
   * ```
   *
   * Note that errors cannot enter a child zone with a different error handler
   * either:
   * ```
   * import 'dart:async';
   *
   * main() {
   *   runZoned(() {
   *     // The following asynchronous error is *not* caught by the `catchError`
   *     // in the nested zone, since errors are not to cross zone boundaries
   *     // with different error handlers.
   *     // Instead the error is handled by the current error handler,
   *     // printing "Caught by outer zone: asynchronous error".
   *     var future = new Future.error("asynchronous error");
   *     runZoned(() {
   *       future.catchError((e) { throw "is never reached"; });
   *     }, onError: (e) { throw "is never reached"; });
   *   }, onError: (e) { print("Caught by outer zone: $e"); });
   * }
   * ```
   */
  Zone get errorZone;

  /**
   * Returns true if `this` and [otherZone] are in the same error zone.
   *
   * Two zones are in the same error zone if they have the same [errorZone].
   */
  bool inSameErrorZone(Zone otherZone);

  /**
   * Creates a new zone as a child of `this`.
   *
   * The new zone uses the closures in the given [specification] to override
   * the current's zone behavior. All specification entries that are `null`
   * inherit the behavior from the parent zone (`this`).
   *
   * The new zone inherits the stored values (accessed through [[]])
   * of this zone and updates them with values from [zoneValues], which either
   * adds new values or overrides existing ones.
   *
   * Note that the fork operation is interceptible. A zone can thus change
   * the zone specification (or zone values), giving the forking zone full
   * control over the child zone.
   */
  Zone fork({ZoneSpecification specification, Map zoneValues});

  /**
   * Executes [action] in this zone.
   *
   * By default (as implemented in the [root] zone), runs [action]
   * with [current] set to this zone.
   *
   * If [action] throws, the synchronous exception is not caught by the zone's
   * error handler. Use [runGuarded] to achieve that.
   *
   * Since the root zone is the only zone that can modify the value of
   * [current], custom zones intercepting run should always delegate to their
   * parent zone. They may take actions before and after the call.
   */
  R run<R>(R action());

  /**
   * Executes the given [action] with [argument] in this zone.
   *
   * As [run] except that [action] is called with one [argument] instead of
   * none.
   */
  R runUnary<R, T>(R action(T argument), T argument);

  /**
   * Executes the given [action] with [argument1] and [argument2] in this
   * zone.
   *
   * As [run] except that [action] is called with two arguments instead of none.
   */
  R runBinary<R, T1, T2>(
      R action(T1 argument1, T2 argument2), T1 argument1, T2 argument2);

  /**
   * Executes the given [action] in this zone and catches synchronous
   * errors.
   *
   * This function is equivalent to:
   * ```
   * try {
   *   this.run(action);
   * } catch (e, s) {
   *   this.handleUncaughtError(e, s);
   * }
   * ```
   *
   * See [run].
   */
  void runGuarded(void action());

  /**
   * Executes the given [action] with [argument] in this zone and
   * catches synchronous errors.
   *
   * See [runGuarded].
   */
  void runUnaryGuarded<T>(void action(T argument), T argument);

  /**
   * Executes the given [action] with [argument1] and [argument2] in this
   * zone and catches synchronous errors.
   *
   * See [runGuarded].
   */
  void runBinaryGuarded<T1, T2>(
      void action(T1 argument1, T2 argument2), T1 argument1, T2 argument2);

  /**
   * Registers the given callback in this zone.
   *
   * When implementing an asynchronous primitive that uses callbacks, the
   * callback must be registered using [registerCallback] at the point where the
   * user provides the callback. This allows zones to record other information
   * that they need at the same time, perhaps even wrapping the callback, so
   * that the callback is prepared when it is later run in the same zones
   * (using [run]). For example, a zone may decide
   * to store the stack trace (at the time of the registration) with the
   * callback.
   *
   * Returns the callback that should be used in place of the provided
   * [callback]. Frequently zones simply return the original callback.
   *
   * Custom zones may intercept this operation. The default implementation in
   * [Zone.root] returns the original callback unchanged.
   */
  ZoneCallback<R> registerCallback<R>(R callback());

  /**
   * Registers the given callback in this zone.
   *
   * Similar to [registerCallback] but with a unary callback.
   */
  ZoneUnaryCallback<R, T> registerUnaryCallback<R, T>(R callback(T arg));

  /**
   * Registers the given callback in this zone.
   *
   * Similar to [registerCallback] but with a unary callback.
   */
  ZoneBinaryCallback<R, T1, T2> registerBinaryCallback<R, T1, T2>(
      R callback(T1 arg1, T2 arg2));

  /**
   *  Registers the provided [callback] and returns a function that will
   *  execute in this zone.
   *
   *  Equivalent to:
   *
   *      ZoneCallback registered = this.registerCallback(callback);
   *      return () => this.run(registered);
   *
   */
  ZoneCallback<R> bindCallback<R>(R callback());

  /**
   *  Registers the provided [callback] and returns a function that will
   *  execute in this zone.
   *
   *  Equivalent to:
   *
   *      ZoneCallback registered = this.registerUnaryCallback(callback);
   *      return (arg) => thin.runUnary(registered, arg);
   */
  ZoneUnaryCallback<R, T> bindUnaryCallback<R, T>(R callback(T argument));

  /**
   *  Registers the provided [callback] and returns a function that will
   *  execute in this zone.
   *
   *  Equivalent to:
   *
   *      ZoneCallback registered = registerBinaryCallback(callback);
   *      return (arg1, arg2) => thin.runBinary(registered, arg1, arg2);
   */
  ZoneBinaryCallback<R, T1, T2> bindBinaryCallback<R, T1, T2>(
      R callback(T1 argument1, T2 argument2));

  /**
   * Registers the provided [callback] and returns a function that will
   * execute in this zone.
   *
   * When the function executes, errors are caught and treated as uncaught
   * errors.
   *
   * Equivalent to:
   *
   *     ZoneCallback registered = this.registerCallback(callback);
   *     return () => this.runGuarded(registered);
   *
   */
  void Function() bindCallbackGuarded(void callback());

  /**
   * Registers the provided [callback] and returns a function that will
   * execute in this zone.
   *
   * When the function executes, errors are caught and treated as uncaught
   * errors.
   *
   * Equivalent to:
   *
   *     ZoneCallback registered = this.registerUnaryCallback(callback);
   *     return (arg) => this.runUnaryGuarded(registered, arg);
   */
  void Function(T) bindUnaryCallbackGuarded<T>(void callback(T argument));

  /**
   *  Registers the provided [callback] and returns a function that will
   *  execute in this zone.
   *
   *  Equivalent to:
   *
   *      ZoneCallback registered = registerBinaryCallback(callback);
   *      return (arg1, arg2) => this.runBinaryGuarded(registered, arg1, arg2);
   */
  void Function(T1, T2) bindBinaryCallbackGuarded<T1, T2>(
      void callback(T1 argument1, T2 argument2));

  /**
   * Intercepts errors when added programmatically to a `Future` or `Stream`.
   *
   * When calling [Completer.completeError], [StreamController.addError],
   * or some [Future] constructors, the current zone is allowed to intercept
   * and replace the error.
   *
   * Future constructors invoke this function when the error is received
   * directly, for example with [Future.error], or when the error is caught
   * synchronously, for example with [Future.sync].
   *
   * There is no guarantee that an error is only sent through [errorCallback]
   * once. Libraries that use intermediate controllers or completers might
   * end up invoking [errorCallback] multiple times.
   *
   * Returns `null` if no replacement is desired. Otherwise returns an instance
   * of [AsyncError] holding the new pair of error and stack trace.
   *
   * Although not recommended, the returned instance may have its `error` member
   * ([AsyncError.error]) be equal to `null` in which case the error should be
   * replaced by a [NullThrownError].
   *
   * Custom zones may intercept this operation.
   *
   * Implementations of a new asynchronous primitive that converts synchronous
   * errors to asynchronous errors rarely need to invoke [errorCallback], since
   * errors are usually reported through future completers or stream
   * controllers.
   */
  AsyncError errorCallback(Object error, StackTrace stackTrace);

  /**
   * Runs [callback] asynchronously in this zone.
   *
   * The global `scheduleMicrotask` delegates to the current zone's
   * [scheduleMicrotask]. The root zone's implementation interacts with the
   * underlying system to schedule the given callback as a microtask.
   *
   * Custom zones may intercept this operation (for example to wrap the given
   * [callback]).
   */
  void scheduleMicrotask(void callback());

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
   *
   * The global `print` function delegates to the current zone's [print]
   * function which makes it possible to intercept printing.
   *
   * Example:
   * ```
   * import 'dart:async';
   *
   * main() {
   *   runZoned(() {
   *     // Ends up printing: "Intercepted: in zone".
   *     print("in zone");
   *   }, zoneSpecification: new ZoneSpecification(
   *       print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
   *     parent.print(zone, "Intercepted: $line");
   *   }));
   * }
   * ```
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

  void handleUncaughtError(Zone zone, error, StackTrace stackTrace) {
    var implementation = _delegationTarget._handleUncaughtError;
    _Zone implZone = implementation.zone;
    HandleUncaughtErrorHandler handler = implementation.function;
    return handler(
        implZone, _parentDelegate(implZone), zone, error, stackTrace);
  }

  R run<R>(Zone zone, R f()) {
    var implementation = _delegationTarget._run;
    _Zone implZone = implementation.zone;
    RunHandler handler = implementation.function;
    return handler(implZone, _parentDelegate(implZone), zone, f);
  }

  R runUnary<R, T>(Zone zone, R f(T arg), T arg) {
    var implementation = _delegationTarget._runUnary;
    _Zone implZone = implementation.zone;
    RunUnaryHandler handler = implementation.function;
    return handler(implZone, _parentDelegate(implZone), zone, f, arg);
  }

  R runBinary<R, T1, T2>(Zone zone, R f(T1 arg1, T2 arg2), T1 arg1, T2 arg2) {
    var implementation = _delegationTarget._runBinary;
    _Zone implZone = implementation.zone;
    RunBinaryHandler handler = implementation.function;
    return handler(implZone, _parentDelegate(implZone), zone, f, arg1, arg2);
  }

  ZoneCallback<R> registerCallback<R>(Zone zone, R f()) {
    var implementation = _delegationTarget._registerCallback;
    _Zone implZone = implementation.zone;
    RegisterCallbackHandler handler = implementation.function;
    return handler(implZone, _parentDelegate(implZone), zone, f);
  }

  ZoneUnaryCallback<R, T> registerUnaryCallback<R, T>(Zone zone, R f(T arg)) {
    var implementation = _delegationTarget._registerUnaryCallback;
    _Zone implZone = implementation.zone;
    RegisterUnaryCallbackHandler handler = implementation.function;
    return handler(implZone, _parentDelegate(implZone), zone, f);
  }

  ZoneBinaryCallback<R, T1, T2> registerBinaryCallback<R, T1, T2>(
      Zone zone, R f(T1 arg1, T2 arg2)) {
    var implementation = _delegationTarget._registerBinaryCallback;
    _Zone implZone = implementation.zone;
    RegisterBinaryCallbackHandler handler = implementation.function;
    return handler(implZone, _parentDelegate(implZone), zone, f);
  }

  AsyncError errorCallback(Zone zone, Object error, StackTrace stackTrace) {
    var implementation = _delegationTarget._errorCallback;
    _Zone implZone = implementation.zone;
    if (identical(implZone, _rootZone)) return null;
    ErrorCallbackHandler handler = implementation.function;
    return handler(
        implZone, _parentDelegate(implZone), zone, error, stackTrace);
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

  Zone fork(Zone zone, ZoneSpecification specification, Map zoneValues) {
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

  // TODO(floitsch): the types of the `_ZoneFunction`s should have a type for
  // all fields.
  _ZoneFunction<Function> get _run;
  _ZoneFunction<Function> get _runUnary;
  _ZoneFunction<Function> get _runBinary;
  _ZoneFunction<Function> get _registerCallback;
  _ZoneFunction<Function> get _registerUnaryCallback;
  _ZoneFunction<Function> get _registerBinaryCallback;
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
  // TODO(floitsch): the types of the `_ZoneFunction`s should have a type for
  // all fields.
  _ZoneFunction<Function> _run;
  _ZoneFunction<Function> _runUnary;
  _ZoneFunction<Function> _runBinary;
  _ZoneFunction<Function> _registerCallback;
  _ZoneFunction<Function> _registerUnaryCallback;
  _ZoneFunction<Function> _registerBinaryCallback;
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
        ? new _ZoneFunction<Function>(this, specification.run)
        : parent._run;
    _runUnary = (specification.runUnary != null)
        ? new _ZoneFunction<Function>(this, specification.runUnary)
        : parent._runUnary;
    _runBinary = (specification.runBinary != null)
        ? new _ZoneFunction<Function>(this, specification.runBinary)
        : parent._runBinary;
    _registerCallback = (specification.registerCallback != null)
        ? new _ZoneFunction<Function>(this, specification.registerCallback)
        : parent._registerCallback;
    _registerUnaryCallback = (specification.registerUnaryCallback != null)
        ? new _ZoneFunction<Function>(this, specification.registerUnaryCallback)
        : parent._registerUnaryCallback;
    _registerBinaryCallback = (specification.registerBinaryCallback != null)
        ? new _ZoneFunction<Function>(
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

  void runGuarded(void f()) {
    try {
      run(f);
    } catch (e, s) {
      handleUncaughtError(e, s);
    }
  }

  void runUnaryGuarded<T>(void f(T arg), T arg) {
    try {
      runUnary(f, arg);
    } catch (e, s) {
      handleUncaughtError(e, s);
    }
  }

  void runBinaryGuarded<T1, T2>(void f(T1 arg1, T2 arg2), T1 arg1, T2 arg2) {
    try {
      runBinary(f, arg1, arg2);
    } catch (e, s) {
      handleUncaughtError(e, s);
    }
  }

  ZoneCallback<R> bindCallback<R>(R f()) {
    var registered = registerCallback(f);
    return () => this.run(registered);
  }

  ZoneUnaryCallback<R, T> bindUnaryCallback<R, T>(R f(T arg)) {
    var registered = registerUnaryCallback(f);
    return (arg) => this.runUnary(registered, arg);
  }

  ZoneBinaryCallback<R, T1, T2> bindBinaryCallback<R, T1, T2>(
      R f(T1 arg1, T2 arg2)) {
    var registered = registerBinaryCallback(f);
    return (arg1, arg2) => this.runBinary(registered, arg1, arg2);
  }

  void Function() bindCallbackGuarded(void f()) {
    var registered = registerCallback(f);
    return () => this.runGuarded(registered);
  }

  void Function(T) bindUnaryCallbackGuarded<T>(void f(T arg)) {
    var registered = registerUnaryCallback(f);
    return (arg) => this.runUnaryGuarded(registered, arg);
  }

  void Function(T1, T2) bindBinaryCallbackGuarded<T1, T2>(
      void f(T1 arg1, T2 arg2)) {
    var registered = registerBinaryCallback(f);
    return (arg1, arg2) => this.runBinaryGuarded(registered, arg1, arg2);
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
    assert(this == _rootZone);
    return null;
  }

  // Methods that can be customized by the zone specification.

  void handleUncaughtError(error, StackTrace stackTrace) {
    var implementation = this._handleUncaughtError;
    assert(implementation != null);
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    HandleUncaughtErrorHandler handler = implementation.function;
    return handler(
        implementation.zone, parentDelegate, this, error, stackTrace);
  }

  Zone fork({ZoneSpecification specification, Map zoneValues}) {
    var implementation = this._fork;
    assert(implementation != null);
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    ForkHandler handler = implementation.function;
    return handler(
        implementation.zone, parentDelegate, this, specification, zoneValues);
  }

  R run<R>(R f()) {
    var implementation = this._run;
    assert(implementation != null);
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    RunHandler handler = implementation.function;
    return handler(implementation.zone, parentDelegate, this, f);
  }

  R runUnary<R, T>(R f(T arg), T arg) {
    var implementation = this._runUnary;
    assert(implementation != null);
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    RunUnaryHandler handler = implementation.function;
    return handler(implementation.zone, parentDelegate, this, f, arg);
  }

  R runBinary<R, T1, T2>(R f(T1 arg1, T2 arg2), T1 arg1, T2 arg2) {
    var implementation = this._runBinary;
    assert(implementation != null);
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    RunBinaryHandler handler = implementation.function;
    return handler(implementation.zone, parentDelegate, this, f, arg1, arg2);
  }

  ZoneCallback<R> registerCallback<R>(R callback()) {
    var implementation = this._registerCallback;
    assert(implementation != null);
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    RegisterCallbackHandler handler = implementation.function;
    return handler(implementation.zone, parentDelegate, this, callback);
  }

  ZoneUnaryCallback<R, T> registerUnaryCallback<R, T>(R callback(T arg)) {
    var implementation = this._registerUnaryCallback;
    assert(implementation != null);
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    RegisterUnaryCallbackHandler handler = implementation.function;
    return handler(implementation.zone, parentDelegate, this, callback);
  }

  ZoneBinaryCallback<R, T1, T2> registerBinaryCallback<R, T1, T2>(
      R callback(T1 arg1, T2 arg2)) {
    var implementation = this._registerBinaryCallback;
    assert(implementation != null);
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    RegisterBinaryCallbackHandler handler = implementation.function;
    return handler(implementation.zone, parentDelegate, this, callback);
  }

  AsyncError errorCallback(Object error, StackTrace stackTrace) {
    var implementation = this._errorCallback;
    assert(implementation != null);
    final Zone implementationZone = implementation.zone;
    if (identical(implementationZone, _rootZone)) return null;
    final ZoneDelegate parentDelegate = _parentDelegate(implementationZone);
    ErrorCallbackHandler handler = implementation.function;
    return handler(implementationZone, parentDelegate, this, error, stackTrace);
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
    return handler(implementation.zone, parentDelegate, this, duration, f);
  }

  void print(String line) {
    var implementation = this._print;
    assert(implementation != null);
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    PrintHandler handler = implementation.function;
    return handler(implementation.zone, parentDelegate, this, line);
  }
}

void _rootHandleUncaughtError(
    Zone self, ZoneDelegate parent, Zone zone, error, StackTrace stackTrace) {
  _schedulePriorityAsyncCallback(() {
    if (error == null) error = new NullThrownError();
    if (stackTrace == null) throw error;
    _rethrow(error, stackTrace);
  });
}

external void _rethrow(Object error, StackTrace stackTrace);

R _rootRun<R>(Zone self, ZoneDelegate parent, Zone zone, R f()) {
  if (Zone._current == zone) return f();

  Zone old = Zone._enter(zone);
  try {
    return f();
  } finally {
    Zone._leave(old);
  }
}

R _rootRunUnary<R, T>(
    Zone self, ZoneDelegate parent, Zone zone, R f(T arg), T arg) {
  if (Zone._current == zone) return f(arg);

  Zone old = Zone._enter(zone);
  try {
    return f(arg);
  } finally {
    Zone._leave(old);
  }
}

R _rootRunBinary<R, T1, T2>(Zone self, ZoneDelegate parent, Zone zone,
    R f(T1 arg1, T2 arg2), T1 arg1, T2 arg2) {
  if (Zone._current == zone) return f(arg1, arg2);

  Zone old = Zone._enter(zone);
  try {
    return f(arg1, arg2);
  } finally {
    Zone._leave(old);
  }
}

ZoneCallback<R> _rootRegisterCallback<R>(
    Zone self, ZoneDelegate parent, Zone zone, R f()) {
  return f;
}

ZoneUnaryCallback<R, T> _rootRegisterUnaryCallback<R, T>(
    Zone self, ZoneDelegate parent, Zone zone, R f(T arg)) {
  return f;
}

ZoneBinaryCallback<R, T1, T2> _rootRegisterBinaryCallback<R, T1, T2>(
    Zone self, ZoneDelegate parent, Zone zone, R f(T1 arg1, T2 arg2)) {
  return f;
}

AsyncError _rootErrorCallback(Zone self, ZoneDelegate parent, Zone zone,
        Object error, StackTrace stackTrace) =>
    null;

void _rootScheduleMicrotask(
    Zone self, ZoneDelegate parent, Zone zone, void f()) {
  if (!identical(_rootZone, zone)) {
    bool hasErrorHandler = !_rootZone.inSameErrorZone(zone);
    if (hasErrorHandler) {
      f = zone.bindCallbackGuarded(f);
    } else {
      f = zone.bindCallback(f);
    }
    // Use root zone as event zone if the function is already bound.
    zone = _rootZone;
  }
  _scheduleAsyncCallback(f);
}

Timer _rootCreateTimer(Zone self, ZoneDelegate parent, Zone zone,
    Duration duration, void callback()) {
  if (!identical(_rootZone, zone)) {
    callback = zone.bindCallback(callback);
  }
  return Timer._createTimer(duration, callback);
}

Timer _rootCreatePeriodicTimer(Zone self, ZoneDelegate parent, Zone zone,
    Duration duration, void callback(Timer timer)) {
  if (!identical(_rootZone, zone)) {
    // TODO(floitsch): the return type should be 'void'.
    callback = zone.bindUnaryCallback<dynamic, Timer>(callback);
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
    ZoneSpecification specification, Map zoneValues) {
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

  _ZoneFunction<Function> get _run =>
      const _ZoneFunction<Function>(_rootZone, _rootRun);
  _ZoneFunction<Function> get _runUnary =>
      const _ZoneFunction<Function>(_rootZone, _rootRunUnary);
  _ZoneFunction<Function> get _runBinary =>
      const _ZoneFunction<Function>(_rootZone, _rootRunBinary);
  _ZoneFunction<Function> get _registerCallback =>
      const _ZoneFunction<Function>(_rootZone, _rootRegisterCallback);
  _ZoneFunction<Function> get _registerUnaryCallback =>
      const _ZoneFunction<Function>(_rootZone, _rootRegisterUnaryCallback);
  _ZoneFunction<Function> get _registerBinaryCallback =>
      const _ZoneFunction<Function>(_rootZone, _rootRegisterBinaryCallback);
  _ZoneFunction<ErrorCallbackHandler> get _errorCallback =>
      const _ZoneFunction<ErrorCallbackHandler>(_rootZone, _rootErrorCallback);
  _ZoneFunction<ScheduleMicrotaskHandler> get _scheduleMicrotask =>
      const _ZoneFunction<ScheduleMicrotaskHandler>(
          _rootZone, _rootScheduleMicrotask);
  _ZoneFunction<CreateTimerHandler> get _createTimer =>
      const _ZoneFunction<CreateTimerHandler>(_rootZone, _rootCreateTimer);
  _ZoneFunction<CreatePeriodicTimerHandler> get _createPeriodicTimer =>
      const _ZoneFunction<CreatePeriodicTimerHandler>(
          _rootZone, _rootCreatePeriodicTimer);
  _ZoneFunction<PrintHandler> get _print =>
      const _ZoneFunction<PrintHandler>(_rootZone, _rootPrint);
  _ZoneFunction<ForkHandler> get _fork =>
      const _ZoneFunction<ForkHandler>(_rootZone, _rootFork);
  _ZoneFunction<HandleUncaughtErrorHandler> get _handleUncaughtError =>
      const _ZoneFunction<HandleUncaughtErrorHandler>(
          _rootZone, _rootHandleUncaughtError);

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

  void runGuarded(void f()) {
    try {
      if (identical(_rootZone, Zone._current)) {
        f();
        return;
      }
      _rootRun(null, null, this, f);
    } catch (e, s) {
      handleUncaughtError(e, s);
    }
  }

  void runUnaryGuarded<T>(void f(T arg), T arg) {
    try {
      if (identical(_rootZone, Zone._current)) {
        f(arg);
        return;
      }
      _rootRunUnary(null, null, this, f, arg);
    } catch (e, s) {
      handleUncaughtError(e, s);
    }
  }

  void runBinaryGuarded<T1, T2>(void f(T1 arg1, T2 arg2), T1 arg1, T2 arg2) {
    try {
      if (identical(_rootZone, Zone._current)) {
        f(arg1, arg2);
        return;
      }
      _rootRunBinary(null, null, this, f, arg1, arg2);
    } catch (e, s) {
      handleUncaughtError(e, s);
    }
  }

  ZoneCallback<R> bindCallback<R>(R f()) {
    return () => this.run<R>(f);
  }

  ZoneUnaryCallback<R, T> bindUnaryCallback<R, T>(R f(T arg)) {
    return (arg) => this.runUnary<R, T>(f, arg);
  }

  ZoneBinaryCallback<R, T1, T2> bindBinaryCallback<R, T1, T2>(
      R f(T1 arg1, T2 arg2)) {
    return (arg1, arg2) => this.runBinary<R, T1, T2>(f, arg1, arg2);
  }

  void Function() bindCallbackGuarded(void f()) {
    return () => this.runGuarded(f);
  }

  void Function(T) bindUnaryCallbackGuarded<T>(void f(T arg)) {
    return (arg) => this.runUnaryGuarded(f, arg);
  }

  void Function(T1, T2) bindBinaryCallbackGuarded<T1, T2>(
      void f(T1 arg1, T2 arg2)) {
    return (arg1, arg2) => this.runBinaryGuarded(f, arg1, arg2);
  }

  operator [](Object key) => null;

  // Methods that can be customized by the zone specification.

  void handleUncaughtError(error, StackTrace stackTrace) {
    _rootHandleUncaughtError(null, null, this, error, stackTrace);
  }

  Zone fork({ZoneSpecification specification, Map zoneValues}) {
    return _rootFork(null, null, this, specification, zoneValues);
  }

  R run<R>(R f()) {
    if (identical(Zone._current, _rootZone)) return f();
    return _rootRun(null, null, this, f);
  }

  R runUnary<R, T>(R f(T arg), T arg) {
    if (identical(Zone._current, _rootZone)) return f(arg);
    return _rootRunUnary(null, null, this, f, arg);
  }

  R runBinary<R, T1, T2>(R f(T1 arg1, T2 arg2), T1 arg1, T2 arg2) {
    if (identical(Zone._current, _rootZone)) return f(arg1, arg2);
    return _rootRunBinary(null, null, this, f, arg1, arg2);
  }

  ZoneCallback<R> registerCallback<R>(R f()) => f;

  ZoneUnaryCallback<R, T> registerUnaryCallback<R, T>(R f(T arg)) => f;

  ZoneBinaryCallback<R, T1, T2> registerBinaryCallback<R, T1, T2>(
          R f(T1 arg1, T2 arg2)) =>
      f;

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

const _rootZone = const _RootZone();

/**
 * Runs [body] in its own zone.
 *
 * Returns the result of invoking [body].
 *
 * If [onError] is non-null the zone is considered an error zone. All uncaught
 * errors, synchronous or asynchronous, in the zone are caught and handled
 * by the callback. When the error is synchronous, throwing in the [onError]
 * handler, leads to a synchronous exception.
 *
 * Returns `null` when [body] threw, and a provided [onError] function completed
 * without throwing.
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
R runZoned<R>(R body(),
    {Map zoneValues, ZoneSpecification zoneSpecification, Function onError}) {
  // TODO(floitsch): the return type should be `void` here.
  if (onError != null &&
      onError is! ZoneBinaryCallback<dynamic, Object, StackTrace> &&
      onError is! ZoneUnaryCallback<dynamic, Object>) {
    throw new ArgumentError("onError callback must take an Object (the error), "
        "or an Object (the error) and a StackTrace");
  }
  HandleUncaughtErrorHandler errorHandler;
  if (onError != null) {
    errorHandler = (Zone self, ZoneDelegate parent, Zone zone, error,
        StackTrace stackTrace) {
      try {
        if (onError is void Function(Object, StackTrace)) {
          self.parent.runBinary(onError, error, stackTrace);
          return;
        }
        assert(onError is void Function(Object));
        self.parent.runUnary(onError, error);
      } catch (e, s) {
        if (identical(e, error)) {
          parent.handleUncaughtError(zone, error, stackTrace);
        } else {
          parent.handleUncaughtError(zone, e, s);
        }
      }
    };
  }
  if (zoneSpecification == null) {
    zoneSpecification =
        new ZoneSpecification(handleUncaughtError: errorHandler);
  } else if (errorHandler != null) {
    zoneSpecification = new ZoneSpecification.from(zoneSpecification,
        handleUncaughtError: errorHandler);
  }
  Zone zone = Zone.current
      .fork(specification: zoneSpecification, zoneValues: zoneValues);
  if (onError != null) {
    try {
      return zone.run(body);
    } catch (e, stackTrace) {
      if (onError is ZoneBinaryCallback<R, Object, StackTrace>) {
        zone.runBinary(onError, e, stackTrace);
        return null;
      }
      assert(onError is ZoneUnaryCallback<R, Object>);
      zone.runUnary(onError, e);
      return null;
    }
  } else {
    return zone.run(body);
  }
}
