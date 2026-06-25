// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'dart:async';

// A pair of zone and value for each configurable override of [_Zone].
// Not reusing the same class or superclass with a type parameter to avoid any
// overhead from generics.
// (Not using records because a planned later change will need the
// zone to be mutable.)

final class _ZoneRun {
  final _Zone zone;
  final RunHandler function;
  const _ZoneRun(this.zone, this.function);
}

final class _ZoneRunUnary {
  final _Zone zone;
  final RunUnaryHandler function;
  const _ZoneRunUnary(this.zone, this.function);
}

final class _ZoneRunBinary {
  final _Zone zone;
  final RunBinaryHandler function;
  const _ZoneRunBinary(this.zone, this.function);
}

final class _ZoneRegisterCallback {
  final _Zone zone;
  final RegisterCallbackHandler function;
  const _ZoneRegisterCallback(this.zone, this.function);
}

final class _ZoneRegisterUnaryCallback {
  final _Zone zone;
  final RegisterUnaryCallbackHandler function;
  const _ZoneRegisterUnaryCallback(this.zone, this.function);
}

final class _ZoneRegisterBinaryCallback {
  final _Zone zone;
  final RegisterBinaryCallbackHandler function;
  const _ZoneRegisterBinaryCallback(this.zone, this.function);
}

final class _ZoneErrorCallback {
  final _Zone zone;
  final ErrorCallbackHandler function;
  const _ZoneErrorCallback(this.zone, this.function);
}

final class _ZoneScheduleMicrotask {
  final _Zone zone;
  final ScheduleMicrotaskHandler function;
  const _ZoneScheduleMicrotask(this.zone, this.function);
}

final class _ZoneCreateTimer {
  final _Zone zone;
  final CreateTimerHandler function;
  const _ZoneCreateTimer(this.zone, this.function);
}

final class _ZoneCreatePeriodicTimer {
  final _Zone zone;
  final CreatePeriodicTimerHandler function;
  const _ZoneCreatePeriodicTimer(this.zone, this.function);
}

final class _ZonePrint {
  final _Zone zone;
  final PrintHandler function;
  const _ZonePrint(this.zone, this.function);
}

final class _ZoneFork {
  final _Zone zone;
  final ForkHandler function;
  const _ZoneFork(this.zone, this.function);
}

final class _ZoneHandleUncaughtError {
  final _Zone zone;
  final HandleUncaughtErrorHandler function;
  const _ZoneHandleUncaughtError(this.zone, this.function);
}

final class _ZoneValues {
  final _Zone zone;
  final Map<Object?, Object?> map;
  const _ZoneValues(this.zone, this.map);
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

  _ZoneRun get _run;
  _ZoneRunUnary get _runUnary;
  _ZoneRunBinary get _runBinary;
  _ZoneRegisterCallback get _registerCallback;
  _ZoneRegisterUnaryCallback get _registerUnaryCallback;
  _ZoneRegisterBinaryCallback get _registerBinaryCallback;
  _ZoneErrorCallback get _errorCallback;
  _ZoneScheduleMicrotask get _scheduleMicrotask;
  _ZoneCreateTimer get _createTimer;
  _ZoneCreatePeriodicTimer get _createPeriodicTimer;
  _ZonePrint get _print;
  _ZoneFork get _fork;
  _ZoneHandleUncaughtError get _handleUncaughtError;
  _ZoneValues get _zoneValues;

  // Parent zone. Only `null` for the root zone.
  _Zone? get parent;
  ZoneDelegate get _delegate;
  ZoneDelegate get _parentDelegate;

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
    _Zone parentZone = implZone.parent!; // Not null for non-root zones.
    _Zone currentZone = Zone._current;
    try {
      Zone._current = parentZone;
      implementation.function(
        implZone,
        implZone._parentDelegate,
        zone,
        error,
        stackTrace,
      );
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
  _ZoneRun _run;
  _ZoneRunUnary _runUnary;
  _ZoneRunBinary _runBinary;
  _ZoneRegisterCallback _registerCallback;
  _ZoneRegisterUnaryCallback _registerUnaryCallback;
  _ZoneRegisterBinaryCallback _registerBinaryCallback;
  _ZoneErrorCallback _errorCallback;
  _ZoneScheduleMicrotask _scheduleMicrotask;
  _ZoneCreateTimer _createTimer;
  _ZoneCreatePeriodicTimer _createPeriodicTimer;
  _ZonePrint _print;
  _ZoneFork _fork;
  _ZoneHandleUncaughtError _handleUncaughtError;

  /// The zone's scoped value declaration map.
  ///
  /// Its [_ZoneValues.map] is always a mutable [HashMap].
  _ZoneValues _zoneValues;

  // A cached delegate to this zone.
  ZoneDelegate? _delegateCache;

  /// The parent zone.
  final _Zone parent;

  ZoneDelegate get _delegate => _delegateCache ??= _ZoneDelegate(this);
  ZoneDelegate get _parentDelegate => parent._delegate;

  _CustomZone(
    this.parent,
    ZoneSpecification? specification,
    Map<Object?, Object?>? variables,
  ) : _run = parent._run,
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
      _handleUncaughtError = parent._handleUncaughtError,
      _zoneValues = parent._zoneValues {
    // The root zone will have implementations of all parts of the
    // specification, so it will never try to access the (null) parent.
    // All other zones have a non-null parent.
    if (specification != null) {
      if (specification.run case var run?) {
        _run = _ZoneRun(this, run);
      }
      if (specification.runUnary case var runUnary?) {
        _runUnary = _ZoneRunUnary(this, runUnary);
      }
      if (specification.runBinary case var runBinary?) {
        _runBinary = _ZoneRunBinary(this, runBinary);
      }
      if (specification.registerCallback case var registerCallback?) {
        _registerCallback = _ZoneRegisterCallback(this, registerCallback);
      }
      if (specification.registerUnaryCallback case var registerUnaryCallback?) {
        _registerUnaryCallback = _ZoneRegisterUnaryCallback(
          this,
          registerUnaryCallback,
        );
      }
      if (specification.registerBinaryCallback
          case var registerBinaryCallback?) {
        _registerBinaryCallback = _ZoneRegisterBinaryCallback(
          this,
          registerBinaryCallback,
        );
      }
      if (specification.errorCallback case var errorCallback?) {
        _errorCallback = _ZoneErrorCallback(this, errorCallback);
      }
      if (specification.scheduleMicrotask case var scheduleMicrotask?) {
        _scheduleMicrotask = _ZoneScheduleMicrotask(this, scheduleMicrotask);
      }
      if (specification.createTimer case var createTimer?) {
        _createTimer = _ZoneCreateTimer(this, createTimer);
      }
      if (specification.createPeriodicTimer case var createPeriodicTimer?) {
        _createPeriodicTimer = _ZoneCreatePeriodicTimer(
          this,
          createPeriodicTimer,
        );
      }
      if (specification.print case var print?) {
        _print = _ZonePrint(this, print);
        printToZone = _printToZone;
      }
      if (specification.fork case var fork?) {
        _fork = _ZoneFork(this, fork);
      }
      if (specification.handleUncaughtError case var handleUncaughtError?) {
        _handleUncaughtError = _ZoneHandleUncaughtError(
          this,
          handleUncaughtError,
        );
      }
    }
    if (variables != null) {
      _zoneValues = _ZoneValues(this, variables);
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
    var variables = _zoneValues;
    if (identical(variables, _RootZone._rootValues)) return null;
    var map = variables.map;
    var result = map[key];
    return (result != null || map.containsKey(key))
        ? result
        : _recursiveLookup(variables, key);
  }

  Object? _recursiveLookup(_ZoneValues variables, Object? key) {
    Object? result;
    var cursor = variables;
    while (true) {
      cursor = cursor.zone.parent!._zoneValues;
      if (identical(cursor, _RootZone._rootValues)) break;
      var map = cursor.map;
      result = map[key];
      if (result != null || map.containsKey(key)) {
        // Update original entry where the key was first looked up,
        // so later lookups on the same zone finds the value immediately.
        variables.map[key] = result;
        break;
      }
    }
    return result;
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
    var zone = implementation.zone;
    return implementation.function(
      zone,
      zone._parentDelegate,
      this,
      specification,
      zoneValues,
    );
  }

  R run<R>(R f()) {
    var implementation = this._run;
    var zone = implementation.zone;
    return implementation.function(zone, zone._parentDelegate, this, f);
  }

  R runUnary<R, T>(R f(T arg), T arg) {
    var implementation = this._runUnary;
    var zone = implementation.zone;
    return implementation.function(zone, zone._parentDelegate, this, f, arg);
  }

  R runBinary<R, T1, T2>(R f(T1 arg1, T2 arg2), T1 arg1, T2 arg2) {
    var implementation = this._runBinary;
    var zone = implementation.zone;
    return implementation.function(
      zone,
      zone._parentDelegate,
      this,
      f,
      arg1,
      arg2,
    );
  }

  ZoneCallback<R> registerCallback<R>(R callback()) {
    var implementation = this._registerCallback;
    var zone = implementation.zone;
    return implementation.function(zone, zone._parentDelegate, this, callback);
  }

  ZoneUnaryCallback<R, T> registerUnaryCallback<R, T>(R callback(T arg)) {
    var implementation = this._registerUnaryCallback;
    var zone = implementation.zone;
    return implementation.function(zone, zone._parentDelegate, this, callback);
  }

  ZoneBinaryCallback<R, T1, T2> registerBinaryCallback<R, T1, T2>(
    R callback(T1 arg1, T2 arg2),
  ) {
    var implementation = this._registerBinaryCallback;
    var zone = implementation.zone;
    return implementation.function(zone, zone._parentDelegate, this, callback);
  }

  AsyncError? errorCallback(Object error, StackTrace? stackTrace) {
    var implementation = this._errorCallback;
    var zone = implementation.zone;
    if (identical(zone, _rootZone)) return null;
    return implementation.function(
      zone,
      zone._parentDelegate,
      this,
      error,
      stackTrace,
    );
  }

  void scheduleMicrotask(void f()) {
    var implementation = this._scheduleMicrotask;
    var zone = implementation.zone;
    return implementation.function(zone, zone._parentDelegate, this, f);
  }

  Timer createTimer(Duration duration, void f()) {
    var implementation = this._createTimer;
    var zone = implementation.zone;
    return implementation.function(
      zone,
      zone._parentDelegate,
      this,
      duration,
      f,
    );
  }

  Timer createPeriodicTimer(Duration duration, void f(Timer timer)) {
    var implementation = this._createPeriodicTimer;
    var zone = implementation.zone;
    return implementation.function(
      zone,
      zone._parentDelegate,
      this,
      duration,
      f,
    );
  }

  void print(String line) {
    var implementation = this._print;
    var zone = implementation.zone;
    return implementation.function(zone, zone._parentDelegate, this, line);
  }
}

base class _RootZone extends _Zone {
  static const _rootValues = _ZoneValues(_rootZone, <Object?, Object?>{});

  const _RootZone();

  _ZoneRun get _run => const _ZoneRun(_rootZone, _rootRun);
  _ZoneRunUnary get _runUnary => const _ZoneRunUnary(_rootZone, _rootRunUnary);
  _ZoneRunBinary get _runBinary =>
      const _ZoneRunBinary(_rootZone, _rootRunBinary);
  _ZoneRegisterCallback get _registerCallback =>
      const _ZoneRegisterCallback(_rootZone, _rootRegisterCallback);
  _ZoneRegisterUnaryCallback get _registerUnaryCallback =>
      const _ZoneRegisterUnaryCallback(_rootZone, _rootRegisterUnaryCallback);
  _ZoneRegisterBinaryCallback get _registerBinaryCallback =>
      const _ZoneRegisterBinaryCallback(_rootZone, _rootRegisterBinaryCallback);
  _ZoneErrorCallback get _errorCallback =>
      const _ZoneErrorCallback(_rootZone, _rootErrorCallback);
  _ZoneScheduleMicrotask get _scheduleMicrotask =>
      const _ZoneScheduleMicrotask(_rootZone, _rootScheduleMicrotask);
  _ZoneCreateTimer get _createTimer =>
      const _ZoneCreateTimer(_rootZone, _rootCreateTimer);
  _ZoneCreatePeriodicTimer get _createPeriodicTimer =>
      const _ZoneCreatePeriodicTimer(_rootZone, _rootCreatePeriodicTimer);
  _ZonePrint get _print => const _ZonePrint(_rootZone, _rootPrint);
  _ZoneFork get _fork => const _ZoneFork(_rootZone, _rootFork);
  _ZoneHandleUncaughtError get _handleUncaughtError =>
      const _ZoneHandleUncaughtError(_rootZone, _rootHandleUncaughtError);
  _ZoneValues get _zoneValues => _rootValues;

  // The parent zone.
  _Zone? get parent => null;

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
