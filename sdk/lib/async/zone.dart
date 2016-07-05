// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

typedef R ZoneCallback<R>();
typedef R ZoneUnaryCallback<R, T>(T arg);
typedef R ZoneBinaryCallback<R, T1, T2>(T1 arg1, T2 arg2);

/// *Experimental*. Might disappear without warning.
typedef T TaskCreate<T, S extends TaskSpecification>(
    S specification, Zone zone);
/// *Experimental*. Might disappear without warning.
typedef void TaskRun<T, A>(T task, A arg);


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
/// *Experimental*. Might disappear without warning.
/*ABUSE*/
typedef T CreateTaskHandler<T, S extends TaskSpecification>(
    Zone self, ZoneDelegate parent, Zone zone,
    TaskCreate<T, S> create, S taskSpecification);
/// *Experimental*. Might disappear without warning.
/*ABUSE*/
typedef void RunTaskHandler<T, A>(Zone self, ZoneDelegate parent, Zone zone,
    TaskRun<T, A> run, T task, A arg);
typedef void ScheduleMicrotaskHandler(
    Zone self, ZoneDelegate parent, Zone zone, void f());
typedef void PrintHandler(
    Zone self, ZoneDelegate parent, Zone zone, String line);
typedef Zone ForkHandler(Zone self, ZoneDelegate parent, Zone zone,
                         ZoneSpecification specification,
                         Map zoneValues);

// The following typedef declarations are used by functionality which
// will be removed and replaced by tasksif the task experiment is successful.
typedef Timer CreateTimerHandler(
    Zone self, ZoneDelegate parent, Zone zone, Duration duration, void f());
typedef Timer CreatePeriodicTimerHandler(
    Zone self, ZoneDelegate parent, Zone zone,
    Duration period, void f(Timer timer));

/** Pair of error and stack trace. Returned by [Zone.errorCallback]. */
class AsyncError implements Error {
  final Object error;
  final StackTrace stackTrace;

  AsyncError(this.error, this.stackTrace);

  String toString() => '$error';
}

/**
 * A task specification contains the necessary information to create a task.
 *
 * See [Zone.createTask] for how a specification is used to create a task.
 *
 * Task specifications should be public and it should be possible to create
 * new instances as a user. That is, custom zones should be able to replace
 * an existing specification with a modified one.
 *
 * *Experimental*. This class might disappear without warning.
 */
abstract class TaskSpecification {
  /**
   * Description of the task.
   *
   * This string is unused by the root-zone, but might be used for debugging,
   * and testing. As such, it should be relatively unique in its category.
   *
   * As a general guideline we recommend: "package-name.library.action".
   */
  String get name;

  /**
   * Whether the scheduled task triggers at most once.
   *
   * If the task is not a one-shot task, it may need to be canceled to prevent
   * further iterations of the task.
   */
  bool get isOneShot;
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
   *
   * The task-related parameters ([createTask] and [runTask]) are experimental
   * and might be removed without warning.
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
      CreateTaskHandler createTask,
      RunTaskHandler runTask,
      // TODO(floitsch): mark as deprecated once tasks are non-experimental.
      CreateTimerHandler createTimer,
      // TODO(floitsch): mark as deprecated once tasks are non-experimental.
      CreatePeriodicTimerHandler createPeriodicTimer,
      PrintHandler print,
      ForkHandler fork
  }) = _ZoneSpecification;

  /**
   * Creates a specification from [other] with the provided handlers overriding
   * the ones in [other].
   *
   * The task-related parameters ([createTask] and [runTask]) are experimental
   * and might be removed without warning.
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
      CreateTaskHandler createTask: null,
      RunTaskHandler runTask: null,
      // TODO(floitsch): mark as deprecated once tasks are non-experimental.
      CreateTimerHandler createTimer: null,
      // TODO(floitsch): mark as deprecated once tasks are non-experimental.
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

      createTask: createTask ?? other.createTask,
      runTask: runTask ?? other.runTask,
      print : print ?? other.print,
      fork: fork ?? other.fork,
      scheduleMicrotask: scheduleMicrotask ?? other.scheduleMicrotask,
      createTimer : createTimer ?? other.createTimer,
      createPeriodicTimer: createPeriodicTimer ?? other.createPeriodicTimer);
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
  /// *Experimental*. Might disappear without warning.
  CreateTaskHandler get createTask;
  /// *Experimental*. Might disappear without warning.
  RunTaskHandler get runTask;
  PrintHandler get print;
  ForkHandler get fork;

  // TODO(floitsch): deprecate once tasks are non-experimental.
  CreateTimerHandler get createTimer;
  // TODO(floitsch): deprecate once tasks are non-experimental.
  CreatePeriodicTimerHandler get createPeriodicTimer;
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
    this.createTask: null,
    this.runTask: null,
    this.print: null,
    this.fork: null,
    // TODO(floitsch): deprecate once tasks are non-experimental.
    this.createTimer: null,
    // TODO(floitsch): deprecate once tasks are non-experimental.
    this.createPeriodicTimer: null
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
  final CreateTaskHandler createTask;
  final RunTaskHandler runTask;
  final PrintHandler print;
  final ForkHandler fork;

  // TODO(floitsch): deprecate once tasks are non-experimental.
  final CreateTimerHandler createTimer;
  // TODO(floitsch): deprecate once tasks are non-experimental.
  final CreatePeriodicTimerHandler createPeriodicTimer;
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

  /// *Experimental*. Might disappear without notice.
  Object/*=T*/ createTask/*<T, S extends TaskSpecification>*/(
      Zone zone, TaskCreate/*<T, S>*/ create,
      TaskSpecification/*=S*/ specification);
  /// *Experimental*. Might disappear without notice.
  void runTask/*<T, A>*/(
      Zone zone, TaskRun/*<T, A>*/ run, Object/*=T*/ task,
      Object/*=A*/ argument);

  void print(Zone zone, String line);
  Zone fork(Zone zone, ZoneSpecification specification, Map zoneValues);

  // TODO(floitsch): deprecate once tasks are non-experimental.
  Timer createTimer(Zone zone, Duration duration, void f());
  // TODO(floitsch): deprecate once tasks are non-experimental.
  Timer createPeriodicTimer(Zone zone, Duration period, void f(Timer timer));
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
   * Creates a task in the current zone.
   *
   * A task represents an asynchronous operation or process that reports back
   * through the event loop.
   *
   * This function allows the zone to intercept the initialization of the
   * task while the [runTask] function is invoked when the task reports back.
   *
   * By default, in the root zone, the [create] function is invoked with the
   * [specification] as argument. It returns a task object which is used for all
   * future interactions between the zone and the task. The object is
   * a unique instance representing the task. It is generally returned to
   * whoever initiated the task.
   * For example, the HTML library uses the returned [StreamSubscription] as
   * task object when users register an event listener.
   *
   * Tasks are created when the program starts an operation that reports back
   * through the event loop. For example, a timer or an HTTP request both
   * return through the event loop and are therefore tasks.
   *
   * If the [create] function is not invoked (because a custom zone has
   * replaced or intercepted it), then the operation is *not* started. This
   * means that a custom zone can intercept tasks, like HTTP requests.
   *
   * A task goes through the following steps:
   * - a user invokes a library function that should eventually return through
   *   the event loop.
   * - the library function creates a [TaskSpecification] that contains the
   *   necessary information to start the operation, and invokes
   *   `Zone.current.createTask` with the specification and a [create] closure.
   *   The closure, when invoked, uses the specification to start the operation
   *   (usually by interacting with the underlying system, or as a native
   *   extension), and returns a task object that identifies the running task.
   * - custom zones handle the request and (unless completely intercepted and
   *   aborted), end up calling the root zone's [createTask] which runs the
   *   provided `create` closure, which may have been replaced at this point.
   * - later, the asynchronous operation returns through the event loop.
   *   It invokes [Zone.runTask] on the zone in which the task should run
   *   (and which was originally passed to the `create` function by
   *   `createTask`). The [runTask] function receives the
   *   task object, a `run` function and an argument. As before, custom zones
   *   may intercept this call. Eventually (unless aborted), the `run` function
   *   is invoked. This last step may happen multiple times for tasks that are
   *   not oneshot tasks (see [ZoneSpecification.isOneShot]).
   *
   * Custom zones may replace the [specification] with a different one, thus
   * modifying the task parameters. An operation that wishes to be an
   * interceptable task must publicly specify the types that intercepting code
   * sees:
   * - The specification type (extending [TaskSpecification]) which holds the
   *   information available when intercepting the `createTask` call.
   * - The task object type, returned by `createTask` and [create]. This object
   *   may simply be typed as [Object].
   * - The argument type, if [runTask] takes a meaningful argument.
   *
   * *Experimental*. Might disappear without notice.
   */
  Object/*=T*/ createTask/*<T, S extends TaskSpecification>*/(
      /*=T*/ create(TaskSpecification/*=S*/ specification, Zone zone),
      TaskSpecification/*=S*/ specification);

  /**
   * Runs a task callback.
   *
   * This function is invoked when an operation, started through [createTask],
   * generates an event.
   *
   * Generally, tasks schedule Dart code in the global event loop when the
   * [createTask] function is invoked. Since the
   * event loop does not expect any return value from the code it runs, the
   * [runTask] function is a void function.
   *
   * The [task] object must be the same as the one created with [createTask].
   *
   * It is good practice that task operations provide a meaningful [argument],
   * so that custom zones can interact with it. They might want to log or
   * replace the argument before calling the [run] function.
   *
   * See [createTask].
   *
   * *Experimental*. Might disappear without notice.
   */
  void runTask/*<T, A>*/(
      /*=T*/ run(/*=T*/ task, /*=A*/ argument), Object/*=T*/ task,
      Object/*=A*/ argument);

  /**
   * Creates a Timer where the callback is executed in this zone.
   */
  // TODO(floitsch): deprecate once tasks are non-experimental.
  Timer createTimer(Duration duration, void callback());

  /**
   * Creates a periodic Timer where the callback is executed in this zone.
   */
  // TODO(floitsch): deprecate once tasks are non-experimental.
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
        as dynamic/*=ZoneCallback<R>*/;
  }

  ZoneUnaryCallback/*<R, T>*/ registerUnaryCallback/*<R, T>*/(
      Zone zone, /*=R*/ f(/*=T*/ arg)) {
    var implementation = _delegationTarget._registerUnaryCallback;
    _Zone implZone = implementation.zone;
    RegisterUnaryCallbackHandler handler = implementation.function;
    // TODO(floitsch): make this a generic method call on '<R, T>' once it's
    // supported. Remove the unnecessary cast.
    return handler(implZone, _parentDelegate(implZone), zone, f)
        as dynamic/*=ZoneUnaryCallback<R, T>*/;
  }

  ZoneBinaryCallback/*<R, T1, T2>*/ registerBinaryCallback/*<R, T1, T2>*/(
      Zone zone, /*=R*/ f(/*=T1*/ arg1, /*=T2*/ arg2)) {
    var implementation = _delegationTarget._registerBinaryCallback;
    _Zone implZone = implementation.zone;
    RegisterBinaryCallbackHandler handler = implementation.function;
    // TODO(floitsch): make this a generic method call on '<R, T1, T2>' once
    // it's supported. Remove the unnecessary cast.
    return handler(implZone, _parentDelegate(implZone), zone, f)
        as dynamic/*=ZoneBinaryCallback<R, T1, T2>*/;
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

  Object/*=T*/ createTask/*<T, S extends TaskSpecification>*/(
      Zone zone, TaskCreate/*<T, S>*/ create, TaskSpecification/*=S*/ specification) {
    var implementation = _delegationTarget._createTask;
    _Zone implZone = implementation.zone;
    // TODO(floitsch): make the handler call a generic method call on '<T, S>'
    // once it's supported. Remove the unnecessary cast.
    var handler =
        implementation.function as CreateTaskHandler/*<T, S>*/;
    return handler(
        implZone, _parentDelegate(implZone), zone, create, specification);
  }

  void runTask/*<T, A>*/(Zone zone, TaskRun run, Object /*=T*/ task,
      Object /*=A*/ argument) {
    var implementation = _delegationTarget._runTask;
    _Zone implZone = implementation.zone;
    RunTaskHandler handler = implementation.function;
    // TODO(floitsch): make this a generic call on '<T, A>'.
    handler(implZone, _parentDelegate(implZone), zone, run, task, argument);
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

  // TODO(floitsch): deprecate once tasks are non-experimental.
  Timer createTimer(Zone zone, Duration duration, void f()) {
    var implementation = _delegationTarget._createTimer;
    _Zone implZone = implementation.zone;
    CreateTimerHandler handler = implementation.function;
    return handler(implZone, _parentDelegate(implZone), zone, duration, f);
  }

  // TODO(floitsch): deprecate once tasks are non-experimental.
  Timer createPeriodicTimer(Zone zone, Duration period, void f(Timer timer)) {
    var implementation = _delegationTarget._createPeriodicTimer;
    _Zone implZone = implementation.zone;
    CreatePeriodicTimerHandler handler = implementation.function;
    return handler(implZone, _parentDelegate(implZone), zone, period, f);
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
  _ZoneFunction<CreateTaskHandler> get _createTask;
  _ZoneFunction<RunTaskHandler> get _runTask;
  _ZoneFunction<PrintHandler> get _print;
  _ZoneFunction<ForkHandler> get _fork;
  _ZoneFunction<HandleUncaughtErrorHandler> get _handleUncaughtError;

  // TODO(floitsch): deprecate once tasks are non-experimental.
  _ZoneFunction<CreateTimerHandler> get _createTimer;
  // TODO(floitsch): deprecate once tasks are non-experimental.
  _ZoneFunction<CreatePeriodicTimerHandler> get _createPeriodicTimer;

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
  _ZoneFunction<CreateTaskHandler> _createTask;
  _ZoneFunction<RunTaskHandler> _runTask;
  _ZoneFunction<PrintHandler> _print;
  _ZoneFunction<ForkHandler> _fork;
  _ZoneFunction<HandleUncaughtErrorHandler> _handleUncaughtError;

  // TODO(floitsch): deprecate once tasks are non-experimental.
  _ZoneFunction<CreateTimerHandler> _createTimer;
  // TODO(floitsch): deprecate once tasks are non-experimental.
  _ZoneFunction<CreatePeriodicTimerHandler> _createPeriodicTimer;

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
    _createTask = (specification.createTask != null)
        ? new _ZoneFunction<CreateTaskHandler>(
            this, specification.createTask)
        : parent._createTask;
    _runTask = (specification.runTask != null)
        ? new _ZoneFunction<RunTaskHandler>(
            this, specification.runTask)
        : parent._runTask;
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

    // Deprecated fields, once tasks are non-experimental.
    _createTimer = (specification.createTimer != null)
        ? new _ZoneFunction<CreateTimerHandler>(
            this, specification.createTimer)
        : parent._createTimer;
    _createPeriodicTimer = (specification.createPeriodicTimer != null)
        ? new _ZoneFunction<CreatePeriodicTimerHandler>(
            this, specification.createPeriodicTimer)
        : parent._createPeriodicTimer;
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
        as dynamic/*=ZoneCallback<R>*/;
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
        as dynamic/*=ZoneUnaryCallback<R, T>*/;
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
        as dynamic/*=ZoneBinaryCallback<R, T1, T2>*/;
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
    handler(implementation.zone, parentDelegate, this, f);
  }

  Object/*=T*/ createTask/*<T, S extends TaskSpecification>*/(
      TaskCreate/*<T, S>*/ create, TaskSpecification/*=S*/ specification) {
    var implementation = this._createTask;
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    // TODO(floitsch): make the handler call a generic method call on '<T, S>'
    // once it's supported. Remove the unnecessary cast.
    var handler =
        implementation.function as CreateTaskHandler/*<T, S>*/;
    return handler(
        implementation.zone, parentDelegate, this, create, specification);
  }

  void runTask/*<T, A>*/(
      TaskRun/*<T, A>*/ run, Object/*=T*/ task, Object/*=A*/ arg1) {
    var implementation = this._runTask;
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    RunTaskHandler handler = implementation.function;
    // TODO(floitsch): make this a generic method call on '<T, A>' once it's
    // supported.
    handler(implementation.zone, parentDelegate, this, run, task, arg1);
  }

  void print(String line) {
    var implementation = this._print;
    assert(implementation != null);
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    PrintHandler handler = implementation.function;
    return handler(implementation.zone, parentDelegate, this, line);
  }

  // TODO(floitsch): deprecate once tasks are non-experimental.
  Timer createTimer(Duration duration, void f()) {
    var implementation = this._createTimer;
    assert(implementation != null);
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    CreateTimerHandler handler = implementation.function;
    return handler(implementation.zone, parentDelegate, this, duration, f);
  }

  // TODO(floitsch): deprecate once tasks are non-experimental.
  Timer createPeriodicTimer(Duration duration, void f(Timer timer)) {
    var implementation = this._createPeriodicTimer;
    assert(implementation != null);
    ZoneDelegate parentDelegate = _parentDelegate(implementation.zone);
    CreatePeriodicTimerHandler handler = implementation.function;
    return handler(
        implementation.zone, parentDelegate, this, duration, f);
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

Object/*=T*/ _rootCreateTask/*<T, S extends TaskSpecification>*/(
    Zone self, ZoneDelegate parent, Zone zone,
    TaskCreate/*<T, S>*/ create, TaskSpecification/*=S*/ specification) {
  return create(specification, zone);
}

void _rootRunTask/*<T, A>*/(
    Zone self, ZoneDelegate parent, Zone zone, TaskRun run/*<T, A>*/,
    Object/*=T*/ task, Object/*=A*/ arg) {
  if (Zone._current == zone) {
    run(task, arg);
    return;
  }

  Zone old = Zone._enter(zone);
  try {
    run(task, arg);
  } catch (e, s) {
    zone.handleUncaughtError/*<dynamic>*/(e, s);
  } finally {
    Zone._leave(old);
  }
}

Timer _rootCreateTimer(Zone self, ZoneDelegate parent, Zone zone,
                       Duration duration, void callback()) {
  return new Timer._task(zone, duration, callback);
}

Timer _rootCreatePeriodicTimer(
    Zone self, ZoneDelegate parent, Zone zone,
    Duration duration, void callback(Timer timer)) {
  return new Timer._periodicTask(zone, duration, callback);
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
  _ZoneFunction<CreateTaskHandler> get _createTask =>
      const _ZoneFunction<CreateTaskHandler>(_ROOT_ZONE, _rootCreateTask);
  _ZoneFunction<RunTaskHandler> get _runTask =>
      const _ZoneFunction<RunTaskHandler>(_ROOT_ZONE, _rootRunTask);
  _ZoneFunction<PrintHandler> get _print =>
      const _ZoneFunction<PrintHandler>(_ROOT_ZONE, _rootPrint);
  _ZoneFunction<ForkHandler> get _fork =>
      const _ZoneFunction<ForkHandler>(_ROOT_ZONE, _rootFork);
  _ZoneFunction<HandleUncaughtErrorHandler> get _handleUncaughtError =>
      const _ZoneFunction<HandleUncaughtErrorHandler>(
          _ROOT_ZONE, _rootHandleUncaughtError);

  // TODO(floitsch): deprecate once tasks are non-experimental.
  _ZoneFunction<CreateTimerHandler> get _createTimer =>
      const _ZoneFunction<CreateTimerHandler>(_ROOT_ZONE, _rootCreateTimer);
  // TODO(floitsch): deprecate once tasks are non-experimental.
  _ZoneFunction<CreatePeriodicTimerHandler> get _createPeriodicTimer =>
      const _ZoneFunction<CreatePeriodicTimerHandler>(
          _ROOT_ZONE, _rootCreatePeriodicTimer);

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

  Object/*=T*/ createTask/*<T, S extends TaskSpecification>*/(
      TaskCreate/*<T, S>*/ create, TaskSpecification/*=S*/ specification) {
    return _rootCreateTask/*<T, S>*/(null, null, this, create, specification);
  }

  void runTask/*<T, A>*/(
      TaskRun/*<T, A>*/ run, Object/*=T*/ task, Object/*=A*/ arg) {
    _rootRunTask/*<T, A>*/(null, null, this, run, task, arg);
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
