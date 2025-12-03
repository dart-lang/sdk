// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'dart:async';

class _ZoneFunction<T extends Function> {
  final _Zone zone;
  final T function;
  const _ZoneFunction(this.zone, this.function);
}

/// A zone represents an environment that remains stable across asynchronous
/// calls.
///
/// All code is executed in the context of a zone,
/// available to the code as [Zone.current].
/// The initial `main` function runs in the context of
/// the default zone ([Zone.root]).
/// Code can be run in a different zone using either
///  [runZoned] or [runZonedGuarded] to create a new zone and run code in it,
/// or [Zone.run] to run code in the context of an existing zone
/// which may have been created earlier using [Zone.fork].
///
/// Developers can create a new zone that overrides some of the functionality of
/// an existing zone. For example, custom zones can replace or modify the
/// behavior of `print`, timers, microtasks or how uncaught errors are handled.
///
/// The [Zone] class is not subclassable, but users can provide custom zones by
/// forking an existing zone (usually [Zone.current]) with a [ZoneSpecification].
/// This is similar to creating a new class that extends the base `Zone` class
/// and that overrides some methods, except without actually creating a new
/// class. Instead the overriding methods are provided as functions that
/// explicitly take the equivalent of their own class, the "super" class and the
/// `this` object as parameters.
///
/// Asynchronous callbacks always run in the context of the zone where they were
/// scheduled. This is implemented using two steps:
/// 1. the callback is first registered using one of [registerCallback],
///   [registerUnaryCallback], or [registerBinaryCallback]. This allows the zone
///   to record that a callback exists and potentially modify it (by returning a
///   different callback). The code doing the registration (e.g., `Future.then`)
///   also remembers the current zone so that it can later run the callback in
///   that zone.
/// 2. At a later point the registered callback is run in the remembered zone,
///    using one of [run], [runUnary] or [runBinary].
///
/// This is all handled internally by the platform code and most users don't need
/// to worry about it. However, developers of new asynchronous operations,
/// provided by the underlying system, must follow the protocol to be zone
/// compatible.
///
/// For convenience, zones provide [bindCallback] (and the corresponding
/// [bindUnaryCallback] and [bindBinaryCallback]) to make it easier to respect
/// the zone contract: these functions first invoke the corresponding `register`
/// functions and then wrap the returned function so that it runs in the current
/// zone when it is later asynchronously invoked.
///
/// Similarly, zones provide [bindCallbackGuarded] (and the corresponding
/// [bindUnaryCallbackGuarded] and [bindBinaryCallbackGuarded]), when the
/// callback should be invoked through [Zone.runGuarded].
@vmIsolateUnsendable
abstract final class Zone {
  // Private constructor so that it is not possible instantiate a Zone class.
  Zone._();

  /// The root zone.
  ///
  /// All isolate entry functions (`main` or spawned functions) start running in
  /// the root zone (that is, [Zone.current] is identical to [Zone.root] when the
  /// entry function is called). If no custom zone is created, the rest of the
  /// program always runs in the root zone.
  ///
  /// The root zone implements the default behavior of all zone operations.
  /// Many methods, like [registerCallback] do the bare minimum required of the
  /// function, and are only provided as a hook for custom zones. Others, like
  /// [scheduleMicrotask], interact with the underlying system to implement the
  /// desired behavior.
  static const Zone root = _rootZone;

  /// The currently running zone.
  static _Zone _current = _rootZone;

  /// The zone that is currently active.
  static Zone get current => _current;

  /// Handles uncaught asynchronous errors.
  ///
  /// There are two kind of asynchronous errors that are handled by this
  /// function:
  /// 1. Uncaught errors that were thrown in asynchronous callbacks, for example,
  ///   a `throw` in the function passed to [Timer.run].
  /// 2. Asynchronous errors that are pushed through [Future] and [Stream]
  ///   chains, but for which nobody registered an error handler.
  ///   Most asynchronous classes, like [Future] or [Stream] push errors to their
  ///   listeners. Errors are propagated this way until either a listener handles
  ///   the error (for example with [Future.catchError]), or no listener is
  ///   available anymore. In the latter case, futures and streams invoke the
  ///   zone's [handleUncaughtError].
  ///
  /// By default, when handled by the root zone, uncaught asynchronous errors are
  /// treated like uncaught synchronous exceptions.
  void handleUncaughtError(Object error, StackTrace stackTrace);

  /// The parent zone of the this zone.
  ///
  /// Is `null` if `this` is the [root] zone.
  ///
  /// Zones are created by [fork] on an existing zone, or by [runZoned] which
  /// forks the [current] zone. The new zone's parent zone is the zone it was
  /// forked from.
  Zone? get parent;

  /// The error zone is responsible for dealing with uncaught errors.
  ///
  /// This is the closest parent zone of this zone that provides a
  /// [handleUncaughtError] method.
  ///
  /// Asynchronous errors in futures never cross zone boundaries
  /// between zones with different error handlers.
  ///
  /// Example:
  /// ```dart
  /// import 'dart:async';
  ///
  /// main() {
  ///   var future;
  ///   runZonedGuarded(() {
  ///     // The asynchronous error is caught by the custom zone which prints
  ///     // 'asynchronous error'.
  ///     future = Future.error("asynchronous error");
  ///   }, (error) { print(error); });  // Creates a zone with an error handler.
  ///   // The following `catchError` handler is never invoked, because the
  ///   // custom zone created by the call to `runZonedGuarded` provides an
  ///   // error handler.
  ///   future.catchError((error) { throw "is never reached"; });
  /// }
  /// ```
  ///
  /// Note that errors cannot enter a child zone with a different error handler
  /// either:
  /// ```dart
  /// import 'dart:async';
  ///
  /// main() {
  ///   runZonedGuarded(() {
  ///     // The following asynchronous error is *not* caught by the `catchError`
  ///     // in the nested zone, since errors are not to cross zone boundaries
  ///     // with different error handlers.
  ///     // Instead the error is handled by the current error handler,
  ///     // printing "Caught by outer zone: asynchronous error".
  ///     var future = Future.error("asynchronous error");
  ///     runZonedGuarded(() {
  ///       future.catchError((e) { throw "is never reached"; });
  ///     }, (error, stack) { throw "is never reached"; });
  ///   }, (error, stack) { print("Caught by outer zone: $error"); });
  /// }
  /// ```
  Zone get errorZone;

  /// Whether this zone and [otherZone] are in the same error zone.
  ///
  /// Two zones are in the same error zone if they have the same [errorZone].
  bool inSameErrorZone(Zone otherZone);

  /// Creates a new zone as a child zone of this zone.
  ///
  /// The new zone uses the closures in the given [specification] to override
  /// the parent zone's behavior. All specification entries that are `null`
  /// inherit the behavior from the parent zone (`this`).
  ///
  /// The new zone inherits the stored values (accessed through [operator []])
  /// of this zone and updates them with values from [zoneValues], which either
  /// adds new values or overrides existing ones.
  ///
  /// Note that the fork operation is interceptable. A zone can thus change
  /// the zone specification (or zone values), giving the parent zone full
  /// control over the child zone.
  Zone fork({
    ZoneSpecification? specification,
    Map<Object?, Object?>? zoneValues,
  });

  /// Executes [action] in this zone.
  ///
  /// By default (as implemented in the [root] zone), runs [action]
  /// with [current] set to this zone.
  ///
  /// If [action] throws, the synchronous exception is not caught by the zone's
  /// error handler. Use [runGuarded] to achieve that.
  ///
  /// Since the root zone is the only zone that can modify the value of
  /// [current], custom zones intercepting run should always delegate to their
  /// parent zone. They may take actions before and after the call.
  R run<R>(R action());

  /// Executes the given [action] with [argument] in this zone.
  ///
  /// As [run] except that [action] is called with one [argument] instead of
  /// none.
  R runUnary<R, T>(R action(T argument), T argument);

  /// Executes the given [action] with [argument1] and [argument2] in this
  /// zone.
  ///
  /// As [run] except that [action] is called with two arguments instead of none.
  R runBinary<R, T1, T2>(
    R action(T1 argument1, T2 argument2),
    T1 argument1,
    T2 argument2,
  );

  /// Executes the given [action] in this zone and catches synchronous
  /// errors.
  ///
  /// This function is equivalent to:
  /// ```dart
  /// try {
  ///   this.run(action);
  /// } catch (e, s) {
  ///   this.handleUncaughtError(e, s);
  /// }
  /// ```
  ///
  /// See [run].
  void runGuarded(void action());

  /// Executes the given [action] with [argument] in this zone and
  /// catches synchronous errors.
  ///
  /// See [runGuarded].
  void runUnaryGuarded<T>(void action(T argument), T argument);

  /// Executes the given [action] with [argument1] and [argument2] in this
  /// zone and catches synchronous errors.
  ///
  /// See [runGuarded].
  void runBinaryGuarded<T1, T2>(
    void action(T1 argument1, T2 argument2),
    T1 argument1,
    T2 argument2,
  );

  /// Registers the given callback in this zone.
  ///
  /// When implementing an asynchronous primitive that uses callbacks, the
  /// callback must be registered using [registerCallback] at the point where the
  /// user provides the callback. This allows zones to record other information
  /// that they need at the same time, perhaps even wrapping the callback, so
  /// that the callback is prepared when it is later run in the same zones
  /// (using [run]). For example, a zone may decide
  /// to store the stack trace (at the time of the registration) with the
  /// callback.
  ///
  /// Returns the callback that should be used in place of the provided
  /// [callback]. Frequently zones simply return the original callback.
  ///
  /// Custom zones may intercept this operation. The default implementation in
  /// [Zone.root] returns the original callback unchanged.
  ZoneCallback<R> registerCallback<R>(R callback());

  /// Registers the given callback in this zone.
  ///
  /// Similar to [registerCallback] but with a unary callback.
  ZoneUnaryCallback<R, T> registerUnaryCallback<R, T>(R callback(T arg));

  /// Registers the given callback in this zone.
  ///
  /// Similar to [registerCallback] but with a binary callback.
  ZoneBinaryCallback<R, T1, T2> registerBinaryCallback<R, T1, T2>(
    R callback(T1 arg1, T2 arg2),
  );

  /// Registers the provided [callback] and returns a function that will
  /// execute in this zone.
  ///
  /// Equivalent to:
  /// ```dart
  /// ZoneCallback registered = this.registerCallback(callback);
  /// return () => this.run(registered);
  /// ```
  ZoneCallback<R> bindCallback<R>(R callback());

  /// Registers the provided [callback] and returns a function that will
  /// execute in this zone.
  ///
  /// Equivalent to:
  /// ```dart
  /// ZoneCallback registered = this.registerUnaryCallback(callback);
  /// return (arg) => this.runUnary(registered, arg);
  /// ```
  ZoneUnaryCallback<R, T> bindUnaryCallback<R, T>(R callback(T argument));

  /// Registers the provided [callback] and returns a function that will
  /// execute in this zone.
  ///
  /// Equivalent to:
  /// ```dart
  /// ZoneCallback registered = registerBinaryCallback(callback);
  /// return (arg1, arg2) => this.runBinary(registered, arg1, arg2);
  /// ```
  ZoneBinaryCallback<R, T1, T2> bindBinaryCallback<R, T1, T2>(
    R callback(T1 argument1, T2 argument2),
  );

  /// Registers the provided [callback] and returns a function that will
  /// execute in this zone.
  ///
  /// When the function executes, errors are caught and treated as uncaught
  /// errors.
  ///
  /// Equivalent to:
  /// ```dart
  /// ZoneCallback registered = this.registerCallback(callback);
  /// return () => this.runGuarded(registered);
  /// ```
  void Function() bindCallbackGuarded(void Function() callback);

  /// Registers the provided [callback] and returns a function that will
  /// execute in this zone.
  ///
  /// When the function executes, errors are caught and treated as uncaught
  /// errors.
  ///
  /// Equivalent to:
  /// ```dart
  /// ZoneCallback registered = this.registerUnaryCallback(callback);
  /// return (arg) => this.runUnaryGuarded(registered, arg);
  /// ```
  void Function(T) bindUnaryCallbackGuarded<T>(void callback(T argument));

  ///  Registers the provided [callback] and returns a function that will
  ///  execute in this zone.
  ///
  ///  Equivalent to:
  /// ```dart
  ///  ZoneCallback registered = registerBinaryCallback(callback);
  ///  return (arg1, arg2) => this.runBinaryGuarded(registered, arg1, arg2);
  /// ```
  void Function(T1, T2) bindBinaryCallbackGuarded<T1, T2>(
    void callback(T1 argument1, T2 argument2),
  );

  /// Intercepts errors when added programmatically to a [Future] or [Stream].
  ///
  /// When calling [Completer.completeError], [StreamController.addError],
  /// or some [Future] constructors, the current zone is allowed to intercept
  /// and replace the error.
  ///
  /// Future constructors invoke this function when the error is received
  /// directly, for example with [Future.error], or when the error is caught
  /// synchronously, for example with [Future.sync].
  ///
  /// There is no guarantee that an error is only sent through [errorCallback]
  /// once. Libraries that use intermediate controllers or completers might
  /// end up invoking [errorCallback] multiple times.
  ///
  /// Returns `null` if no replacement is desired. Otherwise returns an instance
  /// of [AsyncError] holding the new pair of error and stack trace.
  ///
  /// Custom zones may intercept this operation.
  ///
  /// Implementations of a new asynchronous primitive that converts synchronous
  /// errors to asynchronous errors rarely need to invoke [errorCallback], since
  /// errors are usually reported through future completers or stream
  /// controllers.
  AsyncError? errorCallback(Object error, StackTrace? stackTrace);

  /// Runs [callback] asynchronously in this zone.
  ///
  /// The global `scheduleMicrotask` delegates to the [current] zone's
  /// [scheduleMicrotask]. The root zone's implementation interacts with the
  /// underlying system to schedule the given callback as a microtask.
  ///
  /// Custom zones may intercept this operation (for example to wrap the given
  /// [callback]), or to implement their own microtask scheduler.
  /// In the latter case, they will usually still use the parent zone's
  /// [ZoneDelegate.scheduleMicrotask] to attach themselves to the existing
  /// event loop.
  void scheduleMicrotask(void Function() callback);

  /// Creates a [Timer] where the callback is executed in this zone.
  Timer createTimer(Duration duration, void Function() callback);

  /// Creates a periodic [Timer] where the callback is executed in this zone.
  Timer createPeriodicTimer(Duration period, void callback(Timer timer));

  /// Prints the given [line].
  ///
  /// The global `print` function delegates to the current zone's [print]
  /// function which makes it possible to intercept printing.
  ///
  /// Example:
  /// ```dart
  /// import 'dart:async';
  ///
  /// main() {
  ///   runZoned(() {
  ///     // Ends up printing: "Intercepted: in zone".
  ///     print("in zone");
  ///   }, zoneSpecification: new ZoneSpecification(
  ///       print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
  ///     parent.print(zone, "Intercepted: $line");
  ///   }));
  /// }
  /// ```
  void print(String line);

  /// Call to enter the [Zone].
  ///
  /// The previous current zone is returned.
  static _Zone _enter(_Zone zone) {
    assert(!identical(zone, _current));
    _Zone previous = _current;
    _current = zone;
    return previous;
  }

  /// Call to leave the [Zone].
  ///
  /// The previous [Zone] must be provided as `previous`.
  static void _leave(_Zone previous) {
    assert(previous != null);
    Zone._current = previous;
  }

  /// Retrieves the zone-value associated with [key].
  ///
  /// If this zone does not contain the value looks up the same key in the
  /// parent zone. If the [key] is not found returns `null`.
  ///
  /// Any object can be used as key, as long as it has compatible `operator ==`
  /// and `hashCode` implementations.
  /// By controlling access to the key, a zone can grant or deny access to the
  /// zone value.
  dynamic operator [](Object? key);
}

/// Base class for Zone implementations.
abstract base class _Zone implements Zone {
  const _Zone();

  // TODO(floitsch): the types of the `_ZoneFunction`s should have a type for
  // all fields.
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
  // Parent zone. Only `null` for the root zone.
  _Zone? get parent;
  ZoneDelegate get _delegate;
  ZoneDelegate get _parentDelegate;
  Map<Object?, Object?> get _map;

  bool inSameErrorZone(Zone otherZone) {
    return identical(this, otherZone) ||
        identical(errorZone, otherZone.errorZone);
  }

  void _processUncaughtError(Zone zone, Object error, StackTrace stackTrace) {
    var implementation = _handleUncaughtError;
    _Zone implZone = implementation.zone;
    if (identical(implZone, _rootZone)) {
      _rootHandleError(error, stackTrace);
      return;
    }
    HandleUncaughtErrorHandler handler = implementation.function;
    ZoneDelegate parentDelegate = implZone._parentDelegate;
    _Zone parentZone = implZone.parent!; // Not null for non-root zones.
    _Zone currentZone = Zone._current;
    try {
      Zone._current = parentZone;
      handler(implZone, parentDelegate, zone, error, stackTrace);
      Zone._current = currentZone;
    } catch (e, s) {
      Zone._current = currentZone;
      parentZone._processUncaughtError(
        implZone,
        e,
        identical(error, e) ? stackTrace : s,
      );
    }
  }
}

base class _CustomZone extends _Zone {
  // The actual zone and implementation of each of these
  // inheritable zone functions.
  // TODO(floitsch): the types of the `_ZoneFunction`s should have a type for
  // all fields, but we can't use generic function types as type arguments.
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
  ZoneDelegate? _delegateCache;

  /// The parent zone.
  final _Zone parent;

  /// The zone's scoped value declaration map.
  ///
  /// This is always a [HashMap].
  final Map<Object?, Object?> _map;

  ZoneDelegate get _delegate => _delegateCache ??= _ZoneDelegate(this);
  ZoneDelegate get _parentDelegate => parent._delegate;

  _CustomZone(this.parent, ZoneSpecification specification, this._map)
    : _run = parent._run,
      _runUnary = parent._runUnary,
      _runBinary = parent._runBinary,
      _registerCallback = parent._registerCallback,
      _registerUnaryCallback = parent._registerUnaryCallback,
      _registerBinaryCallback = parent._registerBinaryCallback,
      _errorCallback = parent._errorCallback,
      _scheduleMicrotask = parent._scheduleMicrotask,
      _createTimer = parent._createTimer,
      _createPeriodicTimer = parent._createPeriodicTimer,
      _print = parent._print,
      _fork = parent._fork,
      _handleUncaughtError = parent._handleUncaughtError {
    // The root zone will have implementations of all parts of the
    // specification, so it will never try to access the (null) parent.
    // All other zones have a non-null parent.
    var run = specification.run;
    if (run != null) {
      _run = _ZoneFunction<RunHandler>(this, run);
    }
    var runUnary = specification.runUnary;
    if (runUnary != null) {
      _runUnary = _ZoneFunction<RunUnaryHandler>(this, runUnary);
    }
    var runBinary = specification.runBinary;
    if (runBinary != null) {
      _runBinary = _ZoneFunction<RunBinaryHandler>(this, runBinary);
    }
    var registerCallback = specification.registerCallback;
    if (registerCallback != null) {
      _registerCallback = _ZoneFunction<RegisterCallbackHandler>(
        this,
        registerCallback,
      );
    }
    var registerUnaryCallback = specification.registerUnaryCallback;
    if (registerUnaryCallback != null) {
      _registerUnaryCallback = _ZoneFunction<RegisterUnaryCallbackHandler>(
        this,
        registerUnaryCallback,
      );
    }
    var registerBinaryCallback = specification.registerBinaryCallback;
    if (registerBinaryCallback != null) {
      _registerBinaryCallback = _ZoneFunction<RegisterBinaryCallbackHandler>(
        this,
        registerBinaryCallback,
      );
    }
    var errorCallback = specification.errorCallback;
    if (errorCallback != null) {
      _errorCallback = _ZoneFunction<ErrorCallbackHandler>(this, errorCallback);
    }
    var scheduleMicrotask = specification.scheduleMicrotask;
    if (scheduleMicrotask != null) {
      _scheduleMicrotask = _ZoneFunction<ScheduleMicrotaskHandler>(
        this,
        scheduleMicrotask,
      );
    }
    var createTimer = specification.createTimer;
    if (createTimer != null) {
      _createTimer = _ZoneFunction<CreateTimerHandler>(this, createTimer);
    }
    var createPeriodicTimer = specification.createPeriodicTimer;
    if (createPeriodicTimer != null) {
      _createPeriodicTimer = _ZoneFunction<CreatePeriodicTimerHandler>(
        this,
        createPeriodicTimer,
      );
    }
    var print = specification.print;
    if (print != null) {
      _print = _ZoneFunction<PrintHandler>(this, print);
    }
    var fork = specification.fork;
    if (fork != null) {
      _fork = _ZoneFunction<ForkHandler>(this, fork);
    }
    var handleUncaughtError = specification.handleUncaughtError;
    if (handleUncaughtError != null) {
      _handleUncaughtError = _ZoneFunction<HandleUncaughtErrorHandler>(
        this,
        handleUncaughtError,
      );
    }
  }

  /// The closest error-handling zone.
  ///
  /// Returns this zone if it has an error-handler. Otherwise returns the
  /// parent's error-zone.
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
    R f(T1 arg1, T2 arg2),
  ) {
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
    void f(T1 arg1, T2 arg2),
  ) {
    var registered = registerBinaryCallback(f);
    return (arg1, arg2) => this.runBinaryGuarded(registered, arg1, arg2);
  }

  dynamic operator [](Object? key) {
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

  void handleUncaughtError(Object error, StackTrace stackTrace) {
    _processUncaughtError(this, error, stackTrace);
  }

  Zone fork({
    ZoneSpecification? specification,
    Map<Object?, Object?>? zoneValues,
  }) {
    var implementation = this._fork;
    ZoneDelegate parentDelegate = implementation.zone._parentDelegate;
    ForkHandler handler = implementation.function;
    return handler(
      implementation.zone,
      parentDelegate,
      this,
      specification,
      zoneValues,
    );
  }

  R run<R>(R f()) {
    var implementation = this._run;
    ZoneDelegate parentDelegate = implementation.zone._parentDelegate;
    var handler = implementation.function as RunHandler;
    return handler(implementation.zone, parentDelegate, this, f);
  }

  R runUnary<R, T>(R f(T arg), T arg) {
    var implementation = this._runUnary;
    ZoneDelegate parentDelegate = implementation.zone._parentDelegate;
    var handler = implementation.function as RunUnaryHandler;
    return handler(implementation.zone, parentDelegate, this, f, arg);
  }

  R runBinary<R, T1, T2>(R f(T1 arg1, T2 arg2), T1 arg1, T2 arg2) {
    var implementation = this._runBinary;
    ZoneDelegate parentDelegate = implementation.zone._parentDelegate;
    var handler = implementation.function as RunBinaryHandler;
    return handler(implementation.zone, parentDelegate, this, f, arg1, arg2);
  }

  ZoneCallback<R> registerCallback<R>(R callback()) {
    var implementation = this._registerCallback;
    ZoneDelegate parentDelegate = implementation.zone._parentDelegate;
    var handler = implementation.function as RegisterCallbackHandler;
    return handler(implementation.zone, parentDelegate, this, callback);
  }

  ZoneUnaryCallback<R, T> registerUnaryCallback<R, T>(R callback(T arg)) {
    var implementation = this._registerUnaryCallback;
    ZoneDelegate parentDelegate = implementation.zone._parentDelegate;
    var handler = implementation.function as RegisterUnaryCallbackHandler;
    return handler(implementation.zone, parentDelegate, this, callback);
  }

  ZoneBinaryCallback<R, T1, T2> registerBinaryCallback<R, T1, T2>(
    R callback(T1 arg1, T2 arg2),
  ) {
    var implementation = this._registerBinaryCallback;
    ZoneDelegate parentDelegate = implementation.zone._parentDelegate;
    var handler = implementation.function as RegisterBinaryCallbackHandler;
    return handler(implementation.zone, parentDelegate, this, callback);
  }

  AsyncError? errorCallback(Object error, StackTrace? stackTrace) {
    var implementation = this._errorCallback;
    final _Zone implementationZone = implementation.zone;
    if (identical(implementationZone, _rootZone)) return null;
    final ZoneDelegate parentDelegate = implementationZone._parentDelegate;
    ErrorCallbackHandler handler = implementation.function;
    return handler(implementationZone, parentDelegate, this, error, stackTrace);
  }

  void scheduleMicrotask(void f()) {
    var implementation = this._scheduleMicrotask;
    ZoneDelegate parentDelegate = implementation.zone._parentDelegate;
    ScheduleMicrotaskHandler handler = implementation.function;
    return handler(implementation.zone, parentDelegate, this, f);
  }

  Timer createTimer(Duration duration, void f()) {
    var implementation = this._createTimer;
    ZoneDelegate parentDelegate = implementation.zone._parentDelegate;
    CreateTimerHandler handler = implementation.function;
    return handler(implementation.zone, parentDelegate, this, duration, f);
  }

  Timer createPeriodicTimer(Duration duration, void f(Timer timer)) {
    var implementation = this._createPeriodicTimer;
    ZoneDelegate parentDelegate = implementation.zone._parentDelegate;
    CreatePeriodicTimerHandler handler = implementation.function;
    return handler(implementation.zone, parentDelegate, this, duration, f);
  }

  void print(String line) {
    var implementation = this._print;
    ZoneDelegate parentDelegate = implementation.zone._parentDelegate;
    PrintHandler handler = implementation.function;
    return handler(implementation.zone, parentDelegate, this, line);
  }
}

base class _RootZone extends _Zone {
  const _RootZone();

  _ZoneFunction<RunHandler> get _run =>
      const _ZoneFunction<RunHandler>(_rootZone, _rootRun);
  _ZoneFunction<RunUnaryHandler> get _runUnary =>
      const _ZoneFunction<RunUnaryHandler>(_rootZone, _rootRunUnary);
  _ZoneFunction<RunBinaryHandler> get _runBinary =>
      const _ZoneFunction<RunBinaryHandler>(_rootZone, _rootRunBinary);
  _ZoneFunction<RegisterCallbackHandler> get _registerCallback =>
      const _ZoneFunction<RegisterCallbackHandler>(
        _rootZone,
        _rootRegisterCallback,
      );
  _ZoneFunction<RegisterUnaryCallbackHandler> get _registerUnaryCallback =>
      const _ZoneFunction<RegisterUnaryCallbackHandler>(
        _rootZone,
        _rootRegisterUnaryCallback,
      );
  _ZoneFunction<RegisterBinaryCallbackHandler> get _registerBinaryCallback =>
      const _ZoneFunction<RegisterBinaryCallbackHandler>(
        _rootZone,
        _rootRegisterBinaryCallback,
      );
  _ZoneFunction<ErrorCallbackHandler> get _errorCallback =>
      const _ZoneFunction<ErrorCallbackHandler>(_rootZone, _rootErrorCallback);
  _ZoneFunction<ScheduleMicrotaskHandler> get _scheduleMicrotask =>
      const _ZoneFunction<ScheduleMicrotaskHandler>(
        _rootZone,
        _rootScheduleMicrotask,
      );
  _ZoneFunction<CreateTimerHandler> get _createTimer =>
      const _ZoneFunction<CreateTimerHandler>(_rootZone, _rootCreateTimer);
  _ZoneFunction<CreatePeriodicTimerHandler> get _createPeriodicTimer =>
      const _ZoneFunction<CreatePeriodicTimerHandler>(
        _rootZone,
        _rootCreatePeriodicTimer,
      );
  _ZoneFunction<PrintHandler> get _print =>
      const _ZoneFunction<PrintHandler>(_rootZone, _rootPrint);
  _ZoneFunction<ForkHandler> get _fork =>
      const _ZoneFunction<ForkHandler>(_rootZone, _rootFork);
  _ZoneFunction<HandleUncaughtErrorHandler> get _handleUncaughtError =>
      const _ZoneFunction<HandleUncaughtErrorHandler>(
        _rootZone,
        _rootHandleUncaughtError,
      );

  // The parent zone.
  _Zone? get parent => null;

  /// The zone's scoped value declaration map.
  ///
  /// This is always a [HashMap].
  Map<Object?, Object?> get _map => _rootMap;

  static final _rootMap = HashMap();

  static ZoneDelegate? _rootDelegate;

  ZoneDelegate get _delegate => _rootDelegate ??= _ZoneDelegate(this);
  // It's a lie, but the root zone never uses the parent delegate.
  ZoneDelegate get _parentDelegate => _delegate;

  /// The closest error-handling zone.
  ///
  /// Returns `this` if `this` has an error-handler. Otherwise returns the
  /// parent's error-zone.
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
    R f(T1 arg1, T2 arg2),
  ) {
    return (arg1, arg2) => this.runBinary<R, T1, T2>(f, arg1, arg2);
  }

  void Function() bindCallbackGuarded(void f()) {
    return () => this.runGuarded(f);
  }

  void Function(T) bindUnaryCallbackGuarded<T>(void f(T arg)) {
    return (arg) => this.runUnaryGuarded(f, arg);
  }

  void Function(T1, T2) bindBinaryCallbackGuarded<T1, T2>(
    void f(T1 arg1, T2 arg2),
  ) {
    return (arg1, arg2) => this.runBinaryGuarded(f, arg1, arg2);
  }

  dynamic operator [](Object? key) => null;

  // Methods that can be customized by the zone specification.

  void handleUncaughtError(Object error, StackTrace stackTrace) {
    _rootHandleError(error, stackTrace);
  }

  Zone fork({
    ZoneSpecification? specification,
    Map<Object?, Object?>? zoneValues,
  }) {
    return _rootFork(null, null, this, specification, zoneValues);
  }

  R run<R>(R f()) {
    if (identical(Zone._current, _rootZone)) return f();
    return _rootRun(null, null, this, f);
  }

  @pragma('vm:invisible')
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
    R f(T1 arg1, T2 arg2),
  ) => f;

  AsyncError? errorCallback(Object error, StackTrace? stackTrace) => null;

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
