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
  Zone zone;
  final RunHandler function;
  _ZoneRun(this.function) : zone = _rootZone;
}

final class _ZoneRunUnary {
  Zone zone;
  final RunUnaryHandler function;
  _ZoneRunUnary(this.function) : zone = _rootZone;
}

final class _ZoneRunBinary {
  Zone zone;
  final RunBinaryHandler function;
  _ZoneRunBinary(this.function) : zone = _rootZone;
}

final class _ZoneRegisterCallback {
  Zone zone;
  final RegisterCallbackHandler function;
  _ZoneRegisterCallback(this.function) : zone = _rootZone;
}

final class _ZoneRegisterUnaryCallback {
  Zone zone;
  final RegisterUnaryCallbackHandler function;
  _ZoneRegisterUnaryCallback(this.function) : zone = _rootZone;
}

final class _ZoneRegisterBinaryCallback {
  Zone zone;
  final RegisterBinaryCallbackHandler function;
  _ZoneRegisterBinaryCallback(this.function) : zone = _rootZone;
}

final class _ZoneErrorCallback {
  Zone zone;
  final ErrorCallbackHandler function;
  _ZoneErrorCallback(this.function) : zone = _rootZone;
}

final class _ZoneScheduleMicrotask {
  Zone zone;
  final ScheduleMicrotaskHandler function;
  _ZoneScheduleMicrotask(this.function) : zone = _rootZone;
}

final class _ZoneCreateTimer {
  Zone zone;
  final CreateTimerHandler function;
  _ZoneCreateTimer(this.function) : zone = _rootZone;
}

final class _ZoneCreatePeriodicTimer {
  Zone zone;
  final CreatePeriodicTimerHandler function;
  _ZoneCreatePeriodicTimer(this.function) : zone = _rootZone;
}

final class _ZonePrint {
  Zone zone;
  final PrintHandler function;
  _ZonePrint(this.function) : zone = _rootZone;
}

final class _ZoneFork {
  Zone zone;
  final ForkHandler function;
  _ZoneFork(this.function) : zone = _rootZone;
}

final class _ZoneHandleUncaughtError {
  Zone zone;
  final HandleUncaughtErrorHandler function;
  _ZoneHandleUncaughtError(this.function) : zone = _rootZone;
}

final class _ZoneValues {
  Zone zone;
  final Map<Object?, Object?> map;
  _ZoneValues(this.map) : zone = _rootZone;
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
final class Zone {
  /// Parent zone. Is only `null` for the root zone.
  final Zone? _parent;

  /// Cached delegate for this zone.
  ///
  /// Is `null` for the root zone, use `._delegate ?? _rootDelegate`
  /// if a delegate is needed.
  final ZoneDelegate? _delegate;

  // Potentially inherited zone configurations.

  final _ZoneRun? _runFunction;
  final _ZoneRunUnary? _runUnaryFunction;
  final _ZoneRunBinary? _runBinaryFunction;
  final _ZoneRegisterCallback? _registerCallbackFunction;
  final _ZoneRegisterUnaryCallback? _registerUnaryCallbackFunction;
  final _ZoneRegisterBinaryCallback? _registerBinaryCallbackFunction;
  final _ZoneErrorCallback? _errorCallbackFunction;
  final _ZoneScheduleMicrotask? _scheduleMicrotaskFunction;
  final _ZoneCreateTimer? _createTimerFunction;
  final _ZoneCreatePeriodicTimer? _createPeriodicTimerFunction;
  final _ZonePrint? _printFunction;
  final _ZoneFork? _forkFunction;
  final _ZoneHandleUncaughtError? _handleUncaughtErrorFunction;
  final _ZoneValues? _zoneValues;

  const Zone._root()
    : _parent = null,
      _delegate = null,
      _runFunction = null,
      _runUnaryFunction = null,
      _runBinaryFunction = null,
      _registerCallbackFunction = null,
      _registerUnaryCallbackFunction = null,
      _registerBinaryCallbackFunction = null,
      _errorCallbackFunction = null,
      _scheduleMicrotaskFunction = null,
      _createTimerFunction = null,
      _createPeriodicTimerFunction = null,
      _printFunction = null,
      _forkFunction = null,
      _handleUncaughtErrorFunction = null,
      _zoneValues = null;

  /// Creates non-root zone.
  ///
  /// Is called by `fork` with a `ZoneSpecification`.
  /// The [Zone._withoutSpecification] works the same
  /// as this function where all the zone function arguments
  /// are `null`.
  ///
  /// The `*Override` zone functions are new zone values
  /// introduced by this zone. They will be updated to have
  /// their `.zone` be this zone when the constructor gets
  /// access to `this`.
  /// If an override is `null`, the zone value is set to the
  /// parent's value.
  Zone._withSpecification(
    Zone this._parent,
    ZoneDelegate delegate,
    _ZoneRun? runOverride,
    _ZoneRunUnary? runUnaryOverride,
    _ZoneRunBinary? runBinaryOverride,
    _ZoneRegisterCallback? registerCallbackOverride,
    _ZoneRegisterUnaryCallback? registerUnaryCallbackOverride,
    _ZoneRegisterBinaryCallback? registerBinaryCallbackOverride,
    _ZoneErrorCallback? errorCallbackOverride,
    _ZoneScheduleMicrotask? scheduleMicrotaskOverride,
    _ZoneCreateTimer? createTimerOverride,
    _ZoneCreatePeriodicTimer? createPeriodicTimerOverride,
    _ZonePrint? printOverride,
    _ZoneFork? forkOverride,
    _ZoneHandleUncaughtError? handleUncaughtErrorOverride,
    _ZoneValues? zoneValuesOverride,
  ) : _delegate = delegate,
      _runFunction = runOverride ?? _parent._runFunction,
      _runUnaryFunction = runUnaryOverride ?? _parent._runUnaryFunction,
      _runBinaryFunction = runBinaryOverride ?? _parent._runBinaryFunction,
      _registerCallbackFunction =
          registerCallbackOverride ?? _parent._registerCallbackFunction,
      _registerUnaryCallbackFunction =
          registerUnaryCallbackOverride ??
          _parent._registerUnaryCallbackFunction,
      _registerBinaryCallbackFunction =
          registerBinaryCallbackOverride ??
          _parent._registerBinaryCallbackFunction,
      _errorCallbackFunction =
          errorCallbackOverride ?? _parent._errorCallbackFunction,
      _scheduleMicrotaskFunction =
          scheduleMicrotaskOverride ?? _parent._scheduleMicrotaskFunction,
      _createTimerFunction =
          createTimerOverride ?? _parent._createTimerFunction,
      _createPeriodicTimerFunction =
          createPeriodicTimerOverride ?? _parent._createPeriodicTimerFunction,
      _printFunction = printOverride ?? _parent._printFunction,
      _forkFunction = forkOverride ?? _parent._forkFunction,
      _handleUncaughtErrorFunction =
          handleUncaughtErrorOverride ?? _parent._handleUncaughtErrorFunction,
      _zoneValues = zoneValuesOverride ?? _parent._zoneValues {
    // All new zone functions belong to this zone.
    delegate._zone = this;
    runOverride?.zone = this;
    runUnaryOverride?.zone = this;
    runBinaryOverride?.zone = this;
    registerCallbackOverride?.zone = this;
    registerUnaryCallbackOverride?.zone = this;
    registerBinaryCallbackOverride?.zone = this;
    errorCallbackOverride?.zone = this;
    scheduleMicrotaskOverride?.zone = this;
    createTimerOverride?.zone = this;
    createPeriodicTimerOverride?.zone = this;
    if (printOverride != null) {
      printOverride.zone = this;
      printToZone = _printToZone;
    }
    forkOverride?.zone = this;
    handleUncaughtErrorOverride?.zone = this;
    zoneValuesOverride?.zone = this;
  }

  /// Like [Zone._withSpecification] where all override function arguments are `null`.
  Zone._withoutSpecification(
    Zone this._parent,
    ZoneDelegate delegate,
    _ZoneValues? zoneValuesOverride,
  ) : _delegate = delegate,
      _runFunction = _parent._runFunction,
      _runUnaryFunction = _parent._runUnaryFunction,
      _runBinaryFunction = _parent._runBinaryFunction,
      _registerCallbackFunction = _parent._registerCallbackFunction,
      _registerUnaryCallbackFunction = _parent._registerUnaryCallbackFunction,
      _registerBinaryCallbackFunction = _parent._registerBinaryCallbackFunction,
      _errorCallbackFunction = _parent._errorCallbackFunction,
      _scheduleMicrotaskFunction = _parent._scheduleMicrotaskFunction,
      _createTimerFunction = _parent._createTimerFunction,
      _createPeriodicTimerFunction = _parent._createPeriodicTimerFunction,
      _printFunction = _parent._printFunction,
      _forkFunction = _parent._forkFunction,
      _handleUncaughtErrorFunction = _parent._handleUncaughtErrorFunction,
      _zoneValues = zoneValuesOverride ?? _parent._zoneValues {
    delegate._zone = this;
    zoneValuesOverride?.zone = this;
  }

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
  static Zone _current = _rootZone;

  /// The zone that is currently active.
  static Zone get current => _current;

  /// The parent zone of the this zone.
  ///
  /// Is `null` if `this` is the [root] zone.
  ///
  /// Zones are created by [fork] on an existing zone, or by [runZoned] which
  /// forks the [current] zone. The new zone's parent zone is the zone it was
  /// forked from.
  Zone? get parent => _parent;

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
  Zone get errorZone => _handleUncaughtErrorFunction?.zone ?? _rootZone;

  /// Whether this zone and [otherZone] are in the same error zone.
  ///
  /// Two zones are in the same error zone if they have the same [errorZone].
  bool inSameErrorZone(Zone otherZone) => identical(
    _handleUncaughtErrorFunction,
    otherZone._handleUncaughtErrorFunction,
  );

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
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  void handleUncaughtError(Object error, StackTrace stackTrace) {
    _handleUncaughtErrorZoned(this, error, stackTrace);
  }

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
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  Zone fork({
    ZoneSpecification? specification,
    Map<Object?, Object?>? zoneValues,
  }) => _forkZoned(this, specification, zoneValues);

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
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  R run<R>(R action()) => _runZoned<R>(this, action);

  /// Executes the given [action] with [argument] in this zone.
  ///
  /// As [run] except that [action] is called with one [argument] instead of
  /// none.
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  R runUnary<R, T>(R action(T argument), T argument) =>
      _runUnaryZoned<R, T>(this, action, argument);

  /// Executes the given [action] with [argument1] and [argument2] in this
  /// zone.
  ///
  /// As [run] except that [action] is called with two arguments instead of none.
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  R runBinary<R, T1, T2>(
    R action(T1 argument1, T2 argument2),
    T1 argument1,
    T2 argument2,
  ) => _runBinaryZoned<R, T1, T2>(this, action, argument1, argument2);

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
  void runGuarded(void Function() action) {
    try {
      return _runZoned<void>(this, action);
    } catch (e, s) {
      _handleUncaughtErrorZoned(this, e, s);
    }
  }

  /// Executes the given [action] with [argument] in this zone and
  /// catches synchronous errors.
  ///
  /// See [runGuarded].
  void runUnaryGuarded<T>(void Function(T) action, T argument) {
    try {
      return _runUnaryZoned<void, T>(this, action, argument);
    } catch (e, s) {
      _handleUncaughtErrorZoned(this, e, s);
    }
  }

  /// Executes the given [action] with [argument1] and [argument2] in this
  /// zone and catches synchronous errors.
  ///
  /// See [runGuarded].
  void runBinaryGuarded<T1, T2>(
    void Function(T1, T2) action,
    T1 argument1,
    T2 argument2,
  ) {
    try {
      return _runBinaryZoned<void, T1, T2>(this, action, argument1, argument2);
    } catch (e, s) {
      _handleUncaughtErrorZoned(this, e, s);
    }
  }

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
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  ZoneCallback<R> registerCallback<R>(R Function() callback) =>
      _registerCallbackZoned<R>(this, callback);

  /// Registers the given callback in this zone.
  ///
  /// Similar to [registerCallback] but with a unary callback.
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  ZoneUnaryCallback<R, T> registerUnaryCallback<R, T>(R Function(T) callback) =>
      _registerUnaryCallbackZoned<R, T>(this, callback);

  /// Registers the given callback in this zone.
  ///
  /// Similar to [registerCallback] but with a binary callback.
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  ZoneBinaryCallback<R, T1, T2> registerBinaryCallback<R, T1, T2>(
    R Function(T1, T2) callback,
  ) => _registerBinaryCallbackZoned<R, T1, T2>(this, callback);

  /// Registers the provided [callback] and returns a function that will
  /// execute in this zone.
  ///
  /// Equivalent to:
  /// ```dart
  /// ZoneCallback registered = this.registerCallback(callback);
  /// return () => this.run(registered);
  /// ```
  ZoneCallback<R> bindCallback<R>(R Function() callback) {
    var registered = _registerCallbackZoned(this, callback);
    return () => _runZoned(this, registered);
  }

  /// Registers the provided [callback] and returns a function that will
  /// execute in this zone.
  ///
  /// Equivalent to:
  /// ```dart
  /// ZoneCallback registered = this.registerUnaryCallback(callback);
  /// return (arg) => this.runUnary(registered, arg);
  /// ```
  ZoneUnaryCallback<R, T> bindUnaryCallback<R, T>(R Function(T) callback) {
    var registered = _registerUnaryCallbackZoned(this, callback);
    return (T argument) => _runUnaryZoned(this, registered, argument);
  }

  /// Registers the provided [callback] and returns a function that will
  /// execute in this zone.
  ///
  /// Equivalent to:
  /// ```dart
  /// ZoneCallback registered = registerBinaryCallback(callback);
  /// return (arg1, arg2) => this.runBinary(registered, arg1, arg2);
  /// ```
  ZoneBinaryCallback<R, T1, T2> bindBinaryCallback<R, T1, T2>(
    R Function(T1, T2) callback,
  ) {
    var registered = _registerBinaryCallbackZoned(this, callback);
    return (T1 argument1, T2 argument2) =>
        _runBinaryZoned(this, registered, argument1, argument2);
  }

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
  void Function() bindCallbackGuarded(void Function() callback) {
    var registered = _registerCallbackZoned(this, callback);
    return () => runGuarded(registered);
  }

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
  void Function(T) bindUnaryCallbackGuarded<T>(void Function(T) callback) {
    var registered = _registerUnaryCallbackZoned(this, callback);
    return (T argument) => runUnaryGuarded(registered, argument);
  }

  ///  Registers the provided [callback] and returns a function that will
  ///  execute in this zone.
  ///
  ///  Equivalent to:
  /// ```dart
  ///  ZoneCallback registered = registerBinaryCallback(callback);
  ///  return (arg1, arg2) => this.runBinaryGuarded(registered, arg1, arg2);
  /// ```
  void Function(T1, T2) bindBinaryCallbackGuarded<T1, T2>(
    void Function(T1, T2) callback,
  ) {
    var registered = _registerBinaryCallbackZoned(this, callback);
    return (T1 argument1, T2 argument2) =>
        runBinaryGuarded(registered, argument1, argument2);
  }

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
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  AsyncError? errorCallback(Object error, StackTrace? stackTrace) =>
      _errorCallbackZoned(this, error, stackTrace);

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
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  void scheduleMicrotask(void Function() callback) =>
      _scheduleMicrotaskZoned(this, callback);

  /// Creates a [Timer] where the callback is executed in this zone.
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  Timer createTimer(Duration duration, void Function() callback) =>
      _createTimerZoned(this, duration, callback);

  /// Creates a periodic [Timer] where the callback is executed in this zone.
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  Timer createPeriodicTimer(
    Duration period,
    void Function(Timer timer) callback,
  ) => _createPeriodicTimerZoned(this, period, callback);

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
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  void print(String line) {
    _printZoned(this, line);
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
  dynamic operator [](Object? key) {
    var variables = _zoneValues;
    while (variables != null) {
      var map = variables.map;
      var value = map[key];
      if (value != null || map.containsKey(key)) return value;
      variables = variables.zone._parent?._zoneValues;
    }
    return null;
  }

  /// The parent delegate of this zone.
  ///
  /// The parent delegate of the root zone is the root delegate,
  /// which is not technically correct, but it's also never
  /// asked for, and it keeps the type non-nullable.
  ///
  /// A parent delegate is only used when calling a user-installed
  /// zone function handler, which only happens for user-created zones.
  ZoneDelegate get _parentDelegate => _parent?._delegate ?? _rootDelegate;

  @pragma("vm:invisible")
  void _handleUncaughtErrorZoned(
    Zone zone,
    Object error,
    StackTrace stackTrace,
  ) {
    var implementation = _handleUncaughtErrorFunction;
    if (implementation == null) {
      _rootHandleUncaughtError(error, stackTrace);
      return;
    }
    var implZone = implementation.zone;
    // Is not root zone, then `implementation` would have been `null`.
    var parentZone = implZone._parent!; // Not null for non-root zones.
    var currentZone = Zone._current;
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
      parentZone._handleUncaughtErrorZoned(
        implZone,
        e,
        identical(error, e) ? stackTrace : s,
      );
    }
  }

  // The actual implementation of the overridden methods.

  @pragma("vm:invisible")
  Zone _forkZoned(
    Zone zone,
    ZoneSpecification? specification,
    Map<Object?, Object?>? zoneValues,
  ) {
    var implementation = _forkFunction;
    if (implementation == null) {
      return _rootFork(zone, specification, zoneValues);
    }
    Zone implZone = implementation.zone;
    return implementation.function(
      implZone,
      implZone._parentDelegate,
      zone,
      specification,
      zoneValues,
    );
  }

  @pragma("vm:invisible")
  R _runZoned<R>(Zone zone, R Function() callback) {
    var implementation = this._runFunction;
    if (implementation == null) {
      if (identical(_current, zone)) {
        return callback();
      }
      var oldZone = _current;
      _current = zone;
      try {
        return callback();
      } finally {
        _current = oldZone;
      }
    }
    var implZone = implementation.zone;
    return implementation.function(
      implZone,
      implZone._parentDelegate,
      zone,
      callback,
    );
  }

  @pragma("vm:invisible")
  R _runUnaryZoned<R, T>(Zone zone, R Function(T) callback, T argument) {
    var implementation = this._runUnaryFunction;
    if (implementation == null) {
      if (identical(_current, zone)) {
        return callback(argument);
      }
      var oldZone = _current;
      _current = zone;
      try {
        return callback(argument);
      } finally {
        _current = oldZone;
      }
    }
    var implZone = implementation.zone;
    return implementation.function(
      implZone,
      implZone._parentDelegate,
      zone,
      callback,
      argument,
    );
  }

  @pragma("vm:invisible")
  R _runBinaryZoned<R, T1, T2>(
    Zone zone,
    R Function(T1, T2) callback,
    T1 argument1,
    T2 argument2,
  ) {
    var implementation = this._runBinaryFunction;
    if (implementation == null) {
      if (identical(_current, zone)) {
        return callback(argument1, argument2);
      }
      var oldZone = _current;
      _current = zone;
      try {
        return callback(argument1, argument2);
      } finally {
        _current = oldZone;
      }
    }
    var implZone = implementation.zone;
    return implementation.function(
      implZone,
      implZone._parentDelegate,
      zone,
      callback,
      argument1,
      argument2,
    );
  }

  @pragma("vm:invisible")
  ZoneCallback<R> _registerCallbackZoned<R>(Zone zone, R callback()) {
    var implementation = this._registerCallbackFunction;
    if (implementation == null) {
      return callback;
    }
    var implZone = implementation.zone;
    return implementation.function(
      implZone,
      implZone._parentDelegate,
      zone,
      callback,
    );
  }

  @pragma("vm:invisible")
  ZoneUnaryCallback<R, T> _registerUnaryCallbackZoned<R, T>(
    Zone zone,
    R callback(T arg),
  ) {
    var implementation = this._registerUnaryCallbackFunction;
    if (implementation == null) {
      return callback;
    }
    var implZone = implementation.zone;
    return implementation.function(
      implZone,
      implZone._parentDelegate,
      zone,
      callback,
    );
  }

  @pragma("vm:invisible")
  ZoneBinaryCallback<R, T1, T2> _registerBinaryCallbackZoned<R, T1, T2>(
    Zone zone,
    R callback(T1 arg1, T2 arg2),
  ) {
    var implementation = this._registerBinaryCallbackFunction;
    if (implementation == null) return callback;
    var implZone = implementation.zone;
    return implementation.function(
      implZone,
      implZone._parentDelegate,
      zone,
      callback,
    );
  }

  @pragma("vm:invisible")
  AsyncError? _errorCallbackZoned(
    Zone zone,
    Object error,
    StackTrace? stackTrace,
  ) {
    var implementation = this._errorCallbackFunction;
    if (implementation == null) {
      return null;
    }
    var implZone = implementation.zone;
    return implementation.function(
      implZone,
      implZone._parentDelegate,
      zone,
      error,
      stackTrace,
    );
  }

  @pragma("vm:invisible")
  void _scheduleMicrotaskZoned(Zone zone, void Function() callback) {
    var implementation = this._scheduleMicrotaskFunction;
    if (implementation == null) {
      _rootScheduleMicrotask(zone, callback);
      return;
    }
    var implZone = implementation.zone;
    implementation.function(implZone, implZone._parentDelegate, zone, callback);
  }

  @pragma("vm:invisible")
  Timer _createTimerZoned(
    Zone zone,
    Duration duration,
    void Function() callback,
  ) {
    var implementation = this._createTimerFunction;
    if (implementation == null) {
      return _rootCreateTimer(zone, duration, callback);
    }
    var implZone = implementation.zone;
    return implementation.function(
      implZone,
      implZone._parentDelegate,
      zone,
      duration,
      callback,
    );
  }

  @pragma("vm:invisible")
  Timer _createPeriodicTimerZoned(
    Zone zone,
    Duration duration,
    void Function(Timer timer) callback,
  ) {
    var implementation = this._createPeriodicTimerFunction;
    if (implementation == null) {
      return _rootCreatePeriodicTimer(zone, duration, callback);
    }
    var implZone = implementation.zone;
    return implementation.function(
      implZone,
      implZone._parentDelegate,
      zone,
      duration,
      callback,
    );
  }

  @pragma("vm:invisible")
  void _printZoned(Zone zone, String line) {
    var implementation = this._printFunction;
    if (implementation == null) {
      printToConsole(line); // Root zone print behavior.
      return;
    }
    var implZone = implementation.zone;
    implementation.function(implZone, implZone._parentDelegate, zone, line);
  }
}
