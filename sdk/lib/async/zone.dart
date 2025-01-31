// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

/// A zero argument function.
typedef ZoneCallback<R> = R Function();

/// A one argument function.
typedef ZoneUnaryCallback<R, T> = R Function(T);

/// A two argument function.
typedef ZoneBinaryCallback<R, T1, T2> = R Function(T1, T2);

/// The type of a custom [Zone.handleUncaughtError] implementation function.
///
/// Receives the [Zone] that the handler was registered on as [self],
/// a delegate forwarding to the handlers of [self]'s parent zone as [parent],
/// and the current zone where the error was uncaught as [zone],
/// which will have [self] as a parent zone.
///
/// The [error] and [stackTrace] are the error and stack trace that
/// was uncaught in [zone].
///
/// The function must only access zone-related functionality through
/// [self], [parent] or [zone].
/// It should not depend on the current zone ([Zone.current]).
///
/// If the uncaught error handler throws, the error will be passed
/// to `parent.handleUncaughtError`. If the thrown object is [error],
/// the throw is considered a re-throw and the original [stackTrace]
/// is retained. This allows an asynchronous error to leave the error zone.
typedef HandleUncaughtErrorHandler =
    void Function(
      Zone self,
      ZoneDelegate parent,
      Zone zone,
      Object error,
      StackTrace stackTrace,
    );

/// The type of a custom [Zone.run] implementation function.
///
/// Receives the [Zone] that the handler was registered on as [self],
/// a delegate forwarding to the handlers of [self]'s parent zone as [parent],
/// and the current zone where the error was uncaught as [zone],
/// which will have [self] as a parent zone.
///
/// The function [callback] is the function which was passed to the
/// [Zone.run] of [zone].
///
/// The default behavior of [Zone.run] is
/// to call [callback] in the current zone, [zone].
/// A custom handler can do things before, after or instead of
/// calling [callback].
///
/// The function must only access zone-related functionality through
/// [self], [parent] or [zone].
/// It should not depend on the current zone ([Zone.current]).
typedef RunHandler =
    R Function<R>(
      Zone self,
      ZoneDelegate parent,
      Zone zone,
      R Function() callback,
    );

/// The type of a custom [Zone.runUnary] implementation function.
///
/// Receives the [Zone] that the handler was registered on as [self],
/// a delegate forwarding to the handlers of [self]'s parent zone as [parent],
/// and the current zone where the error was uncaught as [zone],
/// which will have [self] as a parent zone.
///
/// The function [callback] and value [argument] are the function and argument
/// which was passed to the [Zone.runUnary] of [zone].
///
/// The default behavior of [Zone.runUnary] is
/// to call [callback] with argument [argument] in the current zone, [zone].
/// A custom handler can do things before, after or instead of
/// calling [callback].
///
/// The function must only access zone-related functionality through
/// [self], [parent] or [zone].
/// It should not depend on the current zone ([Zone.current]).
typedef RunUnaryHandler =
    R Function<R, T>(
      Zone self,
      ZoneDelegate parent,
      Zone zone,
      R Function(T argument) callback,
      T argument,
    );

/// The type of a custom [Zone.runBinary] implementation function.
///
/// Receives the [Zone] that the handler was registered on as [self],
/// a delegate forwarding to the handlers of [self]'s parent zone as [parent],
/// and the current zone where the error was uncaught as [zone],
/// which will have [self] as a parent zone.
///
/// The function [callback] and values [argument1] and [argument2] are the function and arguments
/// which was passed to the [Zone.runBinary] of [zone].
///
/// The default behavior of [Zone.runUnary] is
/// to call [callback] with arguments [argument1] and [argument2] in the current zone, [zone].
/// A custom handler can do things before, after or instead of
/// calling [callback].
///
/// The function must only access zone-related functionality through
/// [self], [parent] or [zone].
/// It should not depend on the current zone ([Zone.current]).
typedef RunBinaryHandler =
    R Function<R, T1, T2>(
      Zone self,
      ZoneDelegate parent,
      Zone zone,
      R Function(T1, T2) callback,
      T1 argument1,
      T2 argument2,
    );

/// The type of a custom [Zone.registerCallback] implementation function.
///
/// Receives the [Zone] that the handler was registered on as [self],
/// a delegate forwarding to the handlers of [self]'s parent zone as [parent],
/// and the current zone where the error was uncaught as [zone],
/// which will have [self] as a parent zone.
///
/// The function [callback] is the function which was passed to the
/// [Zone.registerCallback] of [zone].
///
/// The handler should return either the function [callback]
/// or another function replacing [callback],
/// typically by wrapping [callback] in a function
/// which does something extra before and after invoking [callback]
///
/// The function must only access zone-related functionality through
/// [self], [parent] or [zone].
/// It should not depend on the current zone ([Zone.current]).
typedef RegisterCallbackHandler =
    R Function() Function<R>(
      Zone self,
      ZoneDelegate parent,
      Zone zone,
      R Function() callback,
    );

/// The type of a custom [Zone.registerUnaryCallback] implementation function.
///
/// Receives the [Zone] that the handler was registered on as [self],
/// a delegate forwarding to the handlers of [self]'s parent zone as [parent],
/// and the current zone where the error was uncaught as [zone],
/// which will have [self] as a parent zone.
///
/// The function [callback] is the function which was passed to the
/// which was passed to the [Zone.registerUnaryCallback] of [zone].
///
/// The handler should return either the function [callback]
/// or another function replacing [callback],
/// typically by wrapping [callback] in a function
/// which does something extra before and after invoking [callback]
///
/// The function must only access zone-related functionality through
/// [self], [parent] or [zone].
/// It should not depend on the current zone ([Zone.current]).
typedef RegisterUnaryCallbackHandler =
    R Function(T) Function<R, T>(
      Zone self,
      ZoneDelegate parent,
      Zone zone,
      R Function(T argument) callback,
    );

/// The type of a custom [Zone.registerBinaryCallback] implementation function.
///
/// Receives the [Zone] that the handler was registered on as [self],
/// a delegate forwarding to the handlers of [self]'s parent zone as [parent],
/// and the current zone where the error was uncaught as [zone],
/// which will have [self] as a parent zone.
///
/// The function [callback] is the function which was passed to the
/// which was passed to the [Zone.registerBinaryCallback] of [zone].
///
/// The handler should return either the function [callback]
/// or another function replacing [callback],
/// typically by wrapping [callback] in a function
/// which does something extra before and after invoking [callback]
typedef RegisterBinaryCallbackHandler =
    R Function(T1, T2) Function<R, T1, T2>(
      Zone self,
      ZoneDelegate parent,
      Zone zone,
      R Function(T1, T2) callback,
    );

/// The type of a custom [Zone.errorCallback] implementation function.
///
/// The [error] and [stackTrace] are the error and stack trace
/// passed to [Zone.errorCallback] of [zone].
///
/// The function will be called when a synchronous error becomes an
/// asynchronous error, either by being caught, for example by a `Future.then`
/// callback throwing, or when used to create an asynchronous error
/// programmatically, for example using `Future.error` or `Completer.complete`.
///
/// If the function does not want to replace the error or stack trace,
/// it should just return `parent.errorCallback(zone, error, stackTrace)`,
/// giving the parent zone the chance to intercept.
///
/// If the function does want to replace the error and/or stack trace,
/// say with `error2` and `stackTrace2`, it should still allow the
/// parent zone to intercept those errors, for examples as:
/// ```dart
///   return parent.errorCallback(zone, error2, stackTrace2) ??
///       AsyncError(error2, stackTrace2);
/// ```
///
/// The function returns either `null` if the original error and stack trace
/// is unchanged, avoiding any allocation in the most common case,
/// or an [AsyncError] containing a replacement error and stack trace
/// which will be used in place of the originals as the asynchronous error.
///
/// The [self] [Zone] is the zone the handler was registered on,
/// the [parent] delegate forwards to the handlers of [self]'s parent zone,
/// and [zone] is the current zone where the error was uncaught,
/// which will have [self] as an ancestor zone.
///
/// The error callback handler **must not** throw.
///
/// The function must only access zone-related functionality through
/// [self], [parent] or [zone].
/// It should not depend on the current zone ([Zone.current]).
typedef ErrorCallbackHandler =
    AsyncError? Function(
      Zone self,
      ZoneDelegate parent,
      Zone zone,
      Object error,
      StackTrace? stackTrace,
    );

/// The type of a custom [Zone.scheduleMicrotask] implementation function.
///
/// Receives the [Zone] that the handler was registered on as [self],
/// a delegate forwarding to the handlers of [self]'s parent zone as [parent],
/// and the current zone where the error was uncaught as [zone],
/// which will have [self] as a parent zone.
///
/// The function [callback] is the function which was
/// passed to [Zone.scheduleMicrotask] of [zone].
///
/// The custom handler can choose to replace the function [callback]
/// with one that does something before, after or instead of calling [callback],
/// and then call `parent.scheduleMicrotask(zone, replacement)`.
/// or it can implement its own microtask scheduling queue, which typically
/// still depends on `parent.scheduleMicrotask` to as a way to get started.
///
/// The function must only access zone-related functionality through
/// [self], [parent] or [zone].
/// It should not depend on the current zone ([Zone.current]).
typedef ScheduleMicrotaskHandler =
    void Function(
      Zone self,
      ZoneDelegate parent,
      Zone zone,
      void Function() callback,
    );

/// The type of a custom [Zone.createTimer] implementation function.
///
/// Receives the [Zone] that the handler was registered on as [self],
/// a delegate forwarding to the handlers of [self]'s parent zone as [parent],
/// and the current zone where the error was uncaught as [zone],
/// which will have [self] as a parent zone.
///
/// The callback function [callback] and [duration] are the ones which were
/// passed to [Zone.createTimer] of [zone]
/// (possibly through the [Timer] constructor).
///
/// The custom handler can choose to replace the function [callback]
/// with one that does something before, after or instead of calling [callback],
/// and then call `parent.createTimer(zone, replacement)`.
/// or it can implement its own timer queue, which typically
/// still depends on `parent.createTimer` to as a way to get started.
///
/// The function should return a [Timer] object which can be used
/// to inspect and control the scheduled timer callback.
///
/// The function must only access zone-related functionality through
/// [self], [parent] or [zone].
/// It should not depend on the current zone ([Zone.current]).
typedef CreateTimerHandler =
    Timer Function(
      Zone self,
      ZoneDelegate parent,
      Zone zone,
      Duration duration,
      void Function() callback,
    );

/// The type of a custom [Zone.createPeriodicTimer] implementation function.
///
/// Receives the [Zone] that the handler was registered on as [self],
/// a delegate forwarding to the handlers of [self]'s parent zone as [parent],
/// and the current zone where the error was uncaught as [zone],
/// which will have [self] as a parent zone.
///
/// The callback function [callback] and [period] are the ones which were
/// passed to [Zone.createPeriodicTimer] of [zone]
/// (possibly through the [Timer.periodic] constructor).
///
/// The custom handler can choose to replace the function [callback]
/// with one that does something before, after or instead of calling [callback],
/// and then call `parent.createTimer(zone, replacement)`.
/// or it can implement its own timer queue, which typically
/// still depends on `parent.createTimer` to as a way to get started.
///
/// The function should return a [Timer] object which can be used
/// to inspect and control the scheduled timer callbacks.
///
/// The function must only access zone-related functionality through
/// [self], [parent] or [zone].
/// It should not depend on the current zone ([Zone.current]).
typedef CreatePeriodicTimerHandler =
    Timer Function(
      Zone self,
      ZoneDelegate parent,
      Zone zone,
      Duration period,
      void Function(Timer timer) callback,
    );

/// The type of a custom [Zone.print] implementation function.
///
/// Receives the [Zone] that the handler was registered on as [self],
/// a delegate forwarding to the handlers of [self]'s parent zone as [parent],
/// and the current zone where the error was uncaught as [zone],
/// which will have [self] as a parent zone.
///
/// The string [line] is the one which was passed to [Zone.print] of [zone],
/// (possibly through the global [print] function).
///
/// The custom handler can intercept print operations and
/// redirect them to other targets than the console.
///
/// The function must only access zone-related functionality through
/// [self], [parent] or [zone].
/// It should not depend on the current zone ([Zone.current]).
typedef PrintHandler =
    void Function(Zone self, ZoneDelegate parent, Zone zone, String line);

/// The type of a custom [Zone.fork] implementation function.
///
/// Receives the [Zone] that the handler was registered on as [self],
/// a delegate forwarding to the handlers of [self]'s parent zone as [parent],
/// and the current zone where the error was uncaught as [zone],
/// which will have [self] as a parent zone.
///
/// The handler should create a new zone with [zone] as its
/// immediate parent zone.
///
/// The [specification] and [zoneValues] are the ones which were
/// passed to [Zone.fork] of [zone]. They specify the custom zone
/// handlers and zone variables that the new zone should have.
///
/// The custom handler can change the specification or zone
/// values before calling `parent.fork(zone, specification, zoneValues)`,
/// but it has to call the [parent]'s [ZoneDelegate.fork] in order
/// to create a valid [Zone] object.
///
/// The function must only access zone-related functionality through
/// [self], [parent] or [zone].
/// It should not depend on the current zone ([Zone.current]).
typedef ForkHandler =
    Zone Function(
      Zone self,
      ZoneDelegate parent,
      Zone zone,
      ZoneSpecification? specification,
      Map<Object?, Object?>? zoneValues,
    );

class _ZoneFunction<T extends Function> {
  final Zone zone;
  final T function;
  const _ZoneFunction(this.zone, this.function);
}

/// A parameter object with custom zone function handlers for [Zone.fork].
///
/// A zone specification is a parameter object passed to [Zone.fork]
/// and any underlying [ForkHandler] custom implementations.
/// The individual handlers, if set to a non-null value,
/// will be the implementation of the corresponding [Zone] methods
/// for a forked zone created using this zone specification.
///
/// Handlers have the same signature as the same-named methods on [Zone],
/// but receive three additional arguments:
///
///   1. The zone the handlers are attached to (the "self" zone).
///      This is the zone created by [Zone.fork] where the handler is
///      passed as part of the zone delegation.
///   2. A [ZoneDelegate] to the parent zone.
///   3. The "current" zone at the time the request was made.
///      The self zone is always a parent zone of the current zone.
///
/// Handlers can either stop propagating the request (by simply not calling the
/// parent handler), or forward to the parent zone, potentially modifying the
/// arguments on the way.
final class ZoneSpecification {
  /// Creates a specification with the provided handlers.
  ///
  /// If the [handleUncaughtError] is provided, the new zone will be a new
  /// "error zone" which will prevent errors from flowing into other
  /// error zones (see [Zone.errorZone], [Zone.inSameErrorZone]).
  const ZoneSpecification({
    this.handleUncaughtError,
    this.run,
    this.runUnary,
    this.runBinary,
    this.registerCallback,
    this.registerUnaryCallback,
    this.registerBinaryCallback,
    this.errorCallback,
    this.scheduleMicrotask,
    this.createTimer,
    this.createPeriodicTimer,
    this.print,
    this.fork,
  });

  /// Creates a specification from [other] and provided handlers.
  ///
  /// The created zone specification has the handlers of [other]
  /// and any individually provided handlers.
  /// If a handler is provided both through [other] and individually,
  /// the individually provided handler overrides the one from [other].
  factory ZoneSpecification.from(
    ZoneSpecification other, {
    HandleUncaughtErrorHandler? handleUncaughtError,
    RunHandler? run,
    RunUnaryHandler? runUnary,
    RunBinaryHandler? runBinary,
    RegisterCallbackHandler? registerCallback,
    RegisterUnaryCallbackHandler? registerUnaryCallback,
    RegisterBinaryCallbackHandler? registerBinaryCallback,
    ErrorCallbackHandler? errorCallback,
    ScheduleMicrotaskHandler? scheduleMicrotask,
    CreateTimerHandler? createTimer,
    CreatePeriodicTimerHandler? createPeriodicTimer,
    PrintHandler? print,
    ForkHandler? fork,
  }) {
    return ZoneSpecification(
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
      fork: fork ?? other.fork,
    );
  }

  /// A custom [Zone.handleUncaughtError] implementation for a new zone.
  final HandleUncaughtErrorHandler? handleUncaughtError;

  /// A custom [Zone.run] implementation for a new zone.
  final RunHandler? run;

  /// A custom [Zone.runUnary] implementation for a new zone.
  final RunUnaryHandler? runUnary;

  /// A custom [Zone.runBinary] implementation for a new zone.
  final RunBinaryHandler? runBinary;

  /// A custom [Zone.registerCallback] implementation for a new zone.
  final RegisterCallbackHandler? registerCallback;

  /// A custom [Zone.registerUnaryCallback] implementation for a new zone.
  final RegisterUnaryCallbackHandler? registerUnaryCallback;

  /// A custom [Zone.registerBinaryCallback] implementation for a new zone.
  final RegisterBinaryCallbackHandler? registerBinaryCallback;

  /// A custom [Zone.errorCallback] implementation for a new zone.
  final ErrorCallbackHandler? errorCallback;

  /// A custom [Zone.scheduleMicrotask] implementation for a new zone.
  final ScheduleMicrotaskHandler? scheduleMicrotask;

  /// A custom [Zone.createTimer] implementation for a new zone.
  final CreateTimerHandler? createTimer;

  /// A custom [Zone.createPeriodicTimer] implementation for a new zone.
  final CreatePeriodicTimerHandler? createPeriodicTimer;

  /// A custom [Zone.print] implementation for a new zone.
  final PrintHandler? print;

  /// A custom [Zone.handleUncaughtError] implementation for a new zone.
  final ForkHandler? fork;
}

/// An adapted view of the parent zone.
///
/// This class allows the implementation of a zone method to invoke methods on
/// the parent zone while retaining knowledge of the originating zone.
///
/// Custom zones (created through [Zone.fork] or [runZoned]) can provide
/// implementations of most methods of zones. This is similar to overriding
/// methods on [Zone], except that this mechanism doesn't require subclassing.
///
/// A custom zone function (provided through a [ZoneSpecification]) typically
/// records or wraps its parameters and then delegates the operation to its
/// parent zone using the provided [ZoneDelegate].
///
/// While zones have access to their parent zone (through [Zone.parent]) it is
/// recommended to call the methods on the provided parent delegate for two
/// reasons:
/// 1. the delegate methods take an additional `zone` argument which is the
///   zone the action has been initiated in.
/// 2. delegate calls are more efficient, since the implementation knows how
///   to skip zones that would just delegate to their parents.
final class ZoneDelegate {
  const ZoneDelegate._(this._delegationTarget);

  final Zone _delegationTarget;

  // Invokes the [HandleUncaughtErrorHandler] of the zone with a current zone.
  void handleUncaughtError(Zone zone, Object error, StackTrace stackTrace) {
    _delegationTarget._processUncaughtError(zone, error, stackTrace);
  }

  // Invokes the [RunHandler] of the zone with a current zone.
  R run<R>(Zone zone, R Function() callback) {
    var implementation = _delegationTarget._run;
    Zone implZone = implementation.zone;
    var handler = implementation.function;
    return handler(implZone, implZone._parentDelegate, zone, callback);
  }

  // Invokes the [RunUnaryHandler] of the zone with a current zone.
  R runUnary<R, T>(Zone zone, R Function(T) callback, T argument) {
    var implementation = _delegationTarget._runUnary;
    Zone implZone = implementation.zone;
    var handler = implementation.function;
    return handler(
      implZone,
      implZone._parentDelegate,
      zone,
      callback,
      argument,
    );
  }

  // Invokes the [RunBinaryHandler] of the zone with a current zone.
  R runBinary<R, T1, T2>(
    Zone zone,
    R Function(T1, T2) callback,
    T1 argument1,
    T2 argument2,
  ) {
    var implementation = _delegationTarget._runBinary;
    Zone implZone = implementation.zone;
    var handler = implementation.function;
    return handler(
      implZone,
      implZone._parentDelegate,
      zone,
      callback,
      argument1,
      argument2,
    );
  }

  // Invokes the [RegisterCallbackHandler] of the zone with a current zone.
  R Function() registerCallback<R>(Zone zone, R Function() callback) {
    var implementation = _delegationTarget._registerCallback;
    Zone implZone = implementation.zone;
    if (identical(implZone, _rootZone)) return callback;
    var handler = implementation.function;
    return handler(implZone, implZone._parentDelegate, zone, callback);
  }

  // Invokes the [RegisterUnaryHandler] of the zone with a current zone.
  R Function(T) registerUnaryCallback<R, T>(Zone zone, R Function(T) callback) {
    var implementation = _delegationTarget._registerUnaryCallback;
    Zone implZone = implementation.zone;
    if (identical(implZone, _rootZone)) return callback;
    var handler = implementation.function;
    return handler(implZone, implZone._parentDelegate, zone, callback);
  }

  // Invokes the [RegisterBinaryHandler] of the zone with a current zone.
  R Function(T1, T2) registerBinaryCallback<R, T1, T2>(
    Zone zone,
    R Function(T1, T2) callback,
  ) {
    var implementation = _delegationTarget._registerBinaryCallback;
    Zone implZone = implementation.zone;
    if (identical(implZone, _rootZone)) return callback;
    var handler = implementation.function;
    return handler(implZone, implZone._parentDelegate, zone, callback);
  }

  // Invokes the [ErrorCallbackHandler] of the zone with a current zone.
  AsyncError? errorCallback(Zone zone, Object error, StackTrace? stackTrace) {
    var implementation = _delegationTarget._errorCallback;
    Zone implZone = implementation.zone;
    if (identical(implZone, _rootZone)) return null;
    ErrorCallbackHandler handler = implementation.function;
    return handler(implZone, implZone._parentDelegate, zone, error, stackTrace);
  }

  // Invokes the [ScheduleMicrotaskHandler] of the zone with a current zone.
  void scheduleMicrotask(Zone zone, Function() callback) {
    var implementation = _delegationTarget._scheduleMicrotask;
    Zone implZone = implementation.zone;
    ScheduleMicrotaskHandler handler = implementation.function;
    handler(implZone, implZone._parentDelegate, zone, callback);
  }

  // Invokes the [CreateTimerHandler] of the zone with a current zone.
  Timer createTimer(Zone zone, Duration duration, void Function() callback) {
    var implementation = _delegationTarget._createTimer;
    Zone implZone = implementation.zone;
    CreateTimerHandler handler = implementation.function;
    return handler(
      implZone,
      implZone._parentDelegate,
      zone,
      duration,
      callback,
    );
  }

  // Invokes the [CreatePeriodicTimerHandler] of the zone with a current zone.
  Timer createPeriodicTimer(
    Zone zone,
    Duration period,
    void Function(Timer timer) callback,
  ) {
    var implementation = _delegationTarget._createPeriodicTimer;
    Zone implZone = implementation.zone;
    CreatePeriodicTimerHandler handler = implementation.function;
    return handler(implZone, implZone._parentDelegate, zone, period, callback);
  }

  // Invokes the [PrintHandler] of the zone with a current zone.
  void print(Zone zone, String line) {
    var implementation = _delegationTarget._print;
    Zone implZone = implementation.zone;
    PrintHandler handler = implementation.function;
    handler(implZone, implZone._parentDelegate, zone, line);
  }

  // Invokes the [ForkHandler] of the zone with a current zone.
  Zone fork(
    Zone zone,
    ZoneSpecification? specification,
    Map<Object?, Object?>? zoneValues,
  ) {
    var implementation = _delegationTarget._fork;
    Zone implZone = implementation.zone;
    ForkHandler handler = implementation.function;
    return handler(
      implZone,
      implZone._parentDelegate,
      zone,
      specification,
      zoneValues,
    );
  }
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
/// Asynchronous callbacks should always run in the context of the zone where
/// they were created. This is implemented using two steps:
/// 1. the callback is first registered using one of [registerCallback],
///   [registerUnaryCallback], or [registerBinaryCallback]. This allows the zone
///   to record that a callback exists and potentially modify it (by returning a
///   different callback). The code doing the registration (e.g., `Future.then`)
///   also remembers the current zone so that it can later run the callback in
///   that zone.
/// 2. At a later point the registered callback is run in the remembered zone,
///    using one of [run], [runUnary] or [runBinary].
///
/// A function returned by one of the [registerCallback] family of functions
/// must *always* be run using the same zone's corresponding [run] function.
/// The returned function may assume that it is running in that particular
/// zone, and will fail if run outside of that zone.
///
/// This registration and running all handled internally by the platform code
/// when using the top-level functions like `scheduledMicrotask` or
/// constructors like [Timer.periodic], and most users don't need to worry
/// about it.
/// Developers creating custom zones should interact correctly with these
/// expectations, and developers of new asynchronous operations
/// must follow the protocol to interact correctly with custom zones.
///
/// For convenience, zones provide [bindCallback] (and the corresponding
/// [bindUnaryCallback] and [bindBinaryCallback]) to make it easier to respect
/// the zone contract: these functions first invoke the corresponding `register`
/// functions and then wrap the returned function so that it runs in the current
/// zone when it is later asynchronously invoked.
/// The function returned by one of these [bindCallback] operations
/// should not be run using the [Zone.run] functions.
///
/// Similarly, zones provide [bindCallbackGuarded] (and the corresponding
/// [bindUnaryCallbackGuarded] and [bindBinaryCallbackGuarded]), when the
/// callback should be invoked through [Zone.runGuarded].
@vmIsolateUnsendable
abstract final class Zone {
  // Private constructor so that it is not possible instantiate a Zone class.
  const Zone._();

  /// The root zone.
  ///
  /// All isolate entry functions (`main` or spawned functions) start running in
  /// the root zone (that is, [Zone.current] is identical to [Zone.root] when the
  /// entry function is called). If no custom zone is created, the rest of the
  /// program always runs in the root zone.
  ///
  /// The root zone implements the default behavior of all zone operations.
  /// Many methods, like [registerCallback] do the bare minimum required of the
  /// callback, and are only provided as a hook for custom zones. Others, like
  /// [scheduleMicrotask], interact with the underlying system to implement the
  /// desired behavior.
  static const Zone root = _rootZone;

  /// The currently running zone.
  static Zone _current = _rootZone;

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
  bool inSameErrorZone(Zone otherZone) {
    return identical(this, otherZone) ||
        identical(_handleUncaughtError, otherZone._handleUncaughtError);
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

  /// Registers the given [callback] in this zone.
  ///
  /// This informs the zone that the [callback] will later be run
  /// using this zone's [run] method. A custom zone can use this opportunity
  /// to record information available at the time of registration,
  /// for example the current stack trace, so that it can be made
  /// available again when the callback is run. Doing so allows a zone to bridge
  /// the asynchronous gap between a callback being created and being run.
  ///
  /// When implementing an asynchronous primitive that uses callbacks
  /// to be run at a later timer, the callback should be registered using
  /// [registerCallback] at the point where the user provides the callback,
  /// and then later run using [run] in the same zone.
  ///
  /// Custom zones may intercept this operation. The default implementation in
  /// [Zone.root] returns the original callback unchanged.
  ///
  /// Returns the callback that should be used in place of the provided
  /// [callback], which is often just the original callback function.
  ///
  /// The returned function should *only* be run using this zone's [run]
  /// function. The [callback] function may have been modified,
  /// by a custom [registerCallback] implementation, into a function that
  /// assumes that it runs in this zone. Such a function may fail
  /// if invoked directly from another zone, or even in the same
  /// zone without going through a corresponding custom [run] implementation.
  R Function() registerCallback<R>(R callback());

  /// Registers the given callback in this zone.
  ///
  /// Similar to [registerCallback] but with a unary callback.
  R Function(T) registerUnaryCallback<R, T>(R callback(T argument));

  /// Registers the given callback in this zone.
  ///
  /// Similar to [registerCallback] but with a binary callback.
  R Function(T1, T2) registerBinaryCallback<R, T1, T2>(
    R callback(T1 argument1, T2 argument2),
  );

  /// Registers the provided [callback] and returns a function that will
  /// execute in this zone.
  ///
  /// Equivalent to:
  /// ```dart
  /// ZoneCallback registered = this.registerCallback(callback);
  /// return () => this.run(registered);
  /// ```
  R Function() bindCallback<R>(R callback());

  /// Registers the provided [callback] and returns a function that will
  /// execute in this zone.
  ///
  /// Equivalent to:
  /// ```dart
  /// ZoneCallback registered = this.registerUnaryCallback(callback);
  /// return (argument) => this.runUnary(registered, argument);
  /// ```
  R Function(T) bindUnaryCallback<R, T>(R callback(T argument));

  /// Registers the provided [callback] and returns a function that will
  /// execute in this zone.
  ///
  /// Equivalent to:
  /// ```dart
  /// ZoneCallback registered = registerBinaryCallback(callback);
  /// return (argument1, argument2) =>
  ///     runBinary(registered, argument1, argument2);
  /// ```
  R Function(T1, T2) bindBinaryCallback<R, T1, T2>(
    R callback(T1 argument1, T2 argument2),
  );

  /// Registers the provided [callback] and returns a function that will
  /// execute in this zone.
  ///
  /// If the [callback] throws when run, the error is reported as an uncaught
  /// error in this zone.
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
  /// If the [callback] throws when run, the error is reported as an uncaught
  /// error in this zone.
  ///
  /// Equivalent to:
  /// ```dart
  /// ZoneCallback registered = this.registerUnaryCallback(callback);
  /// return (argument) => this.runUnaryGuarded(registered, argument);
  /// ```
  void Function(T) bindUnaryCallbackGuarded<T>(void callback(T argument));

  /// Registers the provided [callback] and returns a function that will
  /// execute in this zone.
  ///
  /// If the [callback] throws when run, the error is reported as an uncaught
  /// error in this zone.
  ///
  /// Equivalent to:
  /// ```dart
  /// ZoneCallback registered = registerBinaryCallback(callback);
  /// return (argument1, argument2) =>
  ///     runBinaryGuarded(registered, argument1, argument2);
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
  /// The default implementation of the [root] zone performs not replacement
  /// and always return `null`.
  ///
  /// Custom zones may intercept this operation.
  ///
  /// Implementations of a new asynchronous primitive that converts synchronous
  /// errors to asynchronous errors rarely need to invoke [errorCallback], since
  /// errors are usually reported through future completers or stream
  /// controllers, and are therefore already asynchronous errors.
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
  ///
  /// The default implementation does not register the callback in the current
  /// zone, the caller is expected to do that first if necessary, and will
  /// eventually run the callback using this zone's [run],
  /// and pass any thrown error to its [handleUncaughtError].
  void scheduleMicrotask(void Function() callback);

  /// Creates a [Timer] where the callback is executed in this zone.
  ///
  /// The [Timer.new] constructor delegates to this function
  /// of the [current] zone.
  ///
  /// The default implementation does not register the callback in the current
  /// zone, the caller is expected to do that first if necessary, and will
  /// eventually run the callback using this zone's [run],
  /// and pass any thrown error to its [handleUncaughtError].
  Timer createTimer(Duration duration, void Function() callback);

  /// Creates a periodic [Timer] where the callback is executed in this zone.
  ///
  /// The [Timer.periodic] constructor delegates to this function
  /// of the [current] zone.
  ///
  /// The default implementation does not register the callback in the current
  /// zone, the caller is expected to do that first if necessary, and will
  /// run each the callback for each timer tick using this zone's [runUnary],
  /// and pass any thrown error to its [handleUncaughtError].
  Timer createPeriodicTimer(Duration period, void callback(Timer timer));

  /// Prints the given [line].
  ///
  /// The global `print` function delegates to the current zone's [print]
  /// function, after converting its argument to a [String],
  /// which makes it possible to intercept printing.
  ///
  /// Example:
  /// ```dart
  /// import 'dart:async';
  ///
  /// void main() {
  ///   runZoned(() {
  ///     // Ends up printing: "Intercepted: in zone".
  ///     print("in zone");
  ///   }, zoneSpecification: ZoneSpecification(
  ///       print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
  ///     parent.print(zone, "Intercepted: $line");
  ///   }));
  /// }
  /// ```
  void print(String line);

  /// Call to enter the [Zone].
  ///
  /// The previous current zone is returned.
  static Zone _enter(Zone zone) {
    assert(!identical(zone, _current));
    Zone previous = _current;
    _current = zone;
    return previous;
  }

  /// Call to leave the [Zone].
  ///
  /// The previous [Zone] must be provided as `previous`.
  static void _leave(Zone previous) {
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

  Map<Object?, Object?>? get _map;

  // Internal implementation.
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

  ZoneDelegate get _delegate;
  ZoneDelegate get _parentDelegate;

  void _processUncaughtError(Zone zone, Object error, StackTrace stackTrace) {
    var implementation = _handleUncaughtError;
    Zone implZone = implementation.zone;
    if (identical(implZone, _rootZone)) {
      _rootHandleError(error, stackTrace);
      return;
    }
    HandleUncaughtErrorHandler handler = implementation.function;
    ZoneDelegate parentDelegate = implZone._parentDelegate;
    Zone parentZone = implZone.parent!; // Not null for non-root zones.
    Zone currentZone = Zone._current;
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

base class _CustomZone extends Zone {
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

  /// Remembers the first delegate created for the zone, so it can be reused for
  /// other sub-zones.
  ZoneDelegate? _delegateCache;

  /// The parent zone.
  final Zone parent;

  /// The zone's scoped value declaration map.
  ///
  /// This is always a [HashMap].
  final Map<Object?, Object?>? _map;

  /// Lazily created and cached delegate object.
  ///
  /// Only used if the zone has a function handler that is called.
  ZoneDelegate get _delegate => _delegateCache ??= ZoneDelegate._(this);
  // Shorthand.
  ZoneDelegate get _parentDelegate => parent._delegate;

  _CustomZone(this.parent, ZoneSpecification? specification, this._map)
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
      _handleUncaughtError = parent._handleUncaughtError,
      super._() {
    if (specification != null) {
      // The root zone will have implementations of all parts of the
      // specification, so it will never try to access the (null) parent.
      // All other zones have a non-null parent.
      if (specification.run case var run?) {
        _run = _ZoneFunction<RunHandler>(this, run);
      }
      if (specification.runUnary case var runUnary?) {
        _runUnary = _ZoneFunction<RunUnaryHandler>(this, runUnary);
      }
      if (specification.runBinary case var runBinary?) {
        _runBinary = _ZoneFunction<RunBinaryHandler>(this, runBinary);
      }
      if (specification.registerCallback case var registerCallback?) {
        _registerCallback = _ZoneFunction<RegisterCallbackHandler>(
          this,
          registerCallback,
        );
      }
      if (specification.registerUnaryCallback case var registerUnaryCallback?) {
        _registerUnaryCallback = _ZoneFunction<RegisterUnaryCallbackHandler>(
          this,
          registerUnaryCallback,
        );
      }
      if (specification.registerBinaryCallback
          case var registerBinaryCallback?) {
        _registerBinaryCallback = _ZoneFunction<RegisterBinaryCallbackHandler>(
          this,
          registerBinaryCallback,
        );
      }
      if (specification.errorCallback case var errorCallback?) {
        _errorCallback = _ZoneFunction<ErrorCallbackHandler>(
          this,
          errorCallback,
        );
      }
      if (specification.scheduleMicrotask case var scheduleMicrotask?) {
        _scheduleMicrotask = _ZoneFunction<ScheduleMicrotaskHandler>(
          this,
          scheduleMicrotask,
        );
      }
      if (specification.createTimer case var createTimer?) {
        _createTimer = _ZoneFunction<CreateTimerHandler>(this, createTimer);
      }
      if (specification.createPeriodicTimer case var createPeriodicTimer?) {
        _createPeriodicTimer = _ZoneFunction<CreatePeriodicTimerHandler>(
          this,
          createPeriodicTimer,
        );
      }
      if (specification.print case var print?) {
        _print = _ZoneFunction<PrintHandler>(this, print);
      }
      if (specification.fork case var fork?) {
        _fork = _ZoneFunction<ForkHandler>(this, fork);
      }
      if (specification.handleUncaughtError case var handleUncaughtError?) {
        _handleUncaughtError = _ZoneFunction<HandleUncaughtErrorHandler>(
          this,
          handleUncaughtError,
        );
      }
    }
  }

  /// The closest error-handling zone.
  ///
  /// This zone if it has an error-handler, otherwise the
  /// [parent] zone's error-zone.
  Zone get errorZone => _handleUncaughtError.zone;

  void runGuarded(void Function() callback) {
    _runGuardedInZone(this, callback);
  }

  void runUnaryGuarded<T>(void Function(T) callback, T argument) {
    _runUnaryGuardedInZone<T>(this, callback, argument);
  }

  void runBinaryGuarded<T1, T2>(
    void Function(T1, T2) callback,
    T1 argument1,
    T2 argument2,
  ) {
    _runBinaryGuardedInZone<T1, T2>(this, callback, argument1, argument2);
  }

  R Function() bindCallback<R>(R Function() callback) {
    var registered = registerCallback(callback);
    return () => this.run(registered);
  }

  R Function(T) bindUnaryCallback<R, T>(R Function(T) callback) {
    var registered = registerUnaryCallback(callback);
    return (T argument) => this.runUnary(registered, argument);
  }

  R Function(T1, T2) bindBinaryCallback<R, T1, T2>(
    R Function(T1, T2) callback,
  ) {
    var registered = registerBinaryCallback(callback);
    return (T1 argument1, T2 argument2) =>
        this.runBinary(registered, argument1, argument2);
  }

  void Function() bindCallbackGuarded(void Function() callback) =>
      _guardCallbackInZone(this, registerCallback(callback));

  void Function(T) bindUnaryCallbackGuarded<T>(void Function(T) callback) =>
      _guardUnaryCallbackInZone(this, registerUnaryCallback(callback));

  void Function(T1, T2) bindBinaryCallbackGuarded<T1, T2>(
    void Function(T1, T2) callback,
  ) => _guardBinaryCallbackInZone(this, registerBinaryCallback(callback));

  dynamic operator [](Object? key) {
    var map = _map;
    if (map == null) return null;
    var result = map[key];
    if (result != null || map.containsKey(key)) return result;
    // If we are not the root zone, look up in the parent zone.
    if (!identical(parent, _rootZone)) {
      // We do not optimize for repeatedly looking up a key which isn't
      // there. That would require storing the key and keeping it alive.
      // Copying the key/value from the parent does not keep any new values
      // alive.
      var value = parent[key];
      if (value != null) {
        map[key] = value;
      }
      return value;
    }
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
    var zone = implementation.zone;
    var parentDelegate = zone._parentDelegate;
    var handler = implementation.function;
    return handler(zone, parentDelegate, this, specification, zoneValues);
  }

  R run<R>(R Function() callback) {
    var implementation = this._run;
    var zone = implementation.zone;
    var parentDelegate = zone._parentDelegate;
    var handler = implementation.function;
    return handler(zone, parentDelegate, this, callback);
  }

  R runUnary<R, T>(R Function(T) callback, T argument) {
    var implementation = this._runUnary;
    var zone = implementation.zone;
    var parentDelegate = zone._parentDelegate;
    var handler = implementation.function;
    return handler(zone, parentDelegate, this, callback, argument);
  }

  R runBinary<R, T1, T2>(
    R Function(T1, T2) callback,
    T1 argument1,
    T2 argument2,
  ) {
    var implementation = this._runBinary;
    var zone = implementation.zone;
    var parentDelegate = zone._parentDelegate;
    var handler = implementation.function;
    return handler(zone, parentDelegate, this, callback, argument1, argument2);
  }

  R Function() registerCallback<R>(R callback()) {
    var implementation = this._registerCallback;
    var zone = implementation.zone;
    var parentDelegate = zone._parentDelegate;
    var handler = implementation.function;
    return handler(zone, parentDelegate, this, callback);
  }

  R Function(T) registerUnaryCallback<R, T>(R callback(T argument)) {
    var implementation = this._registerUnaryCallback;
    var zone = implementation.zone;
    var parentDelegate = zone._parentDelegate;
    var handler = implementation.function;
    return handler(zone, parentDelegate, this, callback);
  }

  R Function(T1, T2) registerBinaryCallback<R, T1, T2>(
    R callback(T1 argument1, T2 argument2),
  ) {
    var implementation = this._registerBinaryCallback;
    var zone = implementation.zone;
    var parentDelegate = zone._parentDelegate;
    var handler = implementation.function;
    return handler(zone, parentDelegate, this, callback);
  }

  AsyncError? errorCallback(Object error, StackTrace? stackTrace) {
    var implementation = this._errorCallback;
    var implementationZone = implementation.zone;
    if (identical(implementationZone, _rootZone)) return null;
    var parentDelegate = implementationZone._parentDelegate;
    var handler = implementation.function;
    return handler(implementationZone, parentDelegate, this, error, stackTrace);
  }

  void scheduleMicrotask(void Function() callback) {
    var implementation = this._scheduleMicrotask;
    var zone = implementation.zone;
    var parentDelegate = zone._parentDelegate;
    var handler = implementation.function;
    return handler(zone, parentDelegate, this, callback);
  }

  Timer createTimer(Duration duration, void Function() callback) {
    var implementation = this._createTimer;
    var zone = implementation.zone;
    var parentDelegate = zone._parentDelegate;
    var handler = implementation.function;
    return handler(zone, parentDelegate, this, duration, callback);
  }

  Timer createPeriodicTimer(
    Duration duration,
    void Function(Timer timer) callback,
  ) {
    var implementation = this._createPeriodicTimer;
    var zone = implementation.zone;
    var parentDelegate = zone._parentDelegate;
    var handler = implementation.function;
    return handler(zone, parentDelegate, this, duration, callback);
  }

  void print(String line) {
    var implementation = this._print;
    var zone = implementation.zone;
    var parentDelegate = zone._parentDelegate;
    var handler = implementation.function;
    return handler(zone, parentDelegate, this, line);
  }
}

void _rootHandleUncaughtError(
  Zone? self,
  ZoneDelegate? parent,
  Zone zone,
  Object error,
  StackTrace stackTrace,
) {
  _rootHandleError(error, stackTrace);
}

void _rootHandleError(Object error, StackTrace stackTrace) {
  _schedulePriorityAsyncCallback(_rootZone, () {
    Error.throwWithStackTrace(error, stackTrace);
  });
}

R _rootRun<R>(
  Zone? self,
  ZoneDelegate? parent,
  Zone zone,
  R Function() callback,
) {
  if (identical(Zone._current, zone)) return callback();

  var old = Zone._enter(zone);
  try {
    return callback();
  } finally {
    Zone._leave(old);
  }
}

R _rootRunUnary<R, T>(
  Zone? self,
  ZoneDelegate? parent,
  Zone zone,
  R Function(T) callback,
  T argument,
) {
  if (identical(Zone._current, zone)) return callback(argument);

  var old = Zone._enter(zone);
  try {
    return callback(argument);
  } finally {
    Zone._leave(old);
  }
}

R _rootRunBinary<R, T1, T2>(
  Zone? self,
  ZoneDelegate? parent,
  Zone zone,
  R Function(T1, T2) callback,
  T1 argument1,
  T2 argument2,
) {
  if (identical(Zone._current, zone)) return callback(argument1, argument2);

  var old = Zone._enter(zone);
  try {
    return callback(argument1, argument2);
  } finally {
    Zone._leave(old);
  }
}

R Function() _rootRegisterCallback<R>(
  Zone self,
  ZoneDelegate parent,
  Zone zone,
  R Function() callback,
) {
  return callback;
}

R Function(T) _rootRegisterUnaryCallback<R, T>(
  Zone self,
  ZoneDelegate parent,
  Zone zone,
  R Function(T) callback,
) {
  return callback;
}

R Function(T1, T2) _rootRegisterBinaryCallback<R, T1, T2>(
  Zone self,
  ZoneDelegate parent,
  Zone zone,
  R Function(T1, T2) callback,
) {
  return callback;
}

AsyncError? _rootErrorCallback(
  Zone self,
  ZoneDelegate parent,
  Zone zone,
  Object error,
  StackTrace? stackTrace,
) => null;

void _rootScheduleMicrotask(
  Zone? self,
  ZoneDelegate? parent,
  Zone zone,
  void Function() callback,
) {
  _scheduleAsyncCallback(zone, callback);
}

Timer _rootCreateTimer(
  Zone self,
  ZoneDelegate parent,
  Zone zone,
  Duration duration,
  void Function() callback,
) {
  // A timer callback will run in the root zone, and an uncaught error from that
  // will be reported just as if reported to the root zone.
  if (!identical(_rootZone, zone)) {
    callback = _guardCallbackInZone(zone, callback);
  }
  return Timer._createTimer(duration, callback);
}

Timer _rootCreatePeriodicTimer(
  Zone self,
  ZoneDelegate parent,
  Zone zone,
  Duration duration,
  void callback(Timer timer),
) {
  if (!identical(_rootZone, zone)) {
    callback = _guardUnaryCallbackInZone<Timer>(zone, callback);
  }
  return Timer._createPeriodicTimer(duration, callback);
}

void _rootPrint(Zone self, ZoneDelegate parent, Zone zone, String line) {
  printToConsole(line);
}

void _printToZone(String line) {
  Zone.current.print(line);
}

Zone _rootFork(
  Zone? self,
  ZoneDelegate? parent,
  Zone zone,
  ZoneSpecification? specification,
  Map<Object?, Object?>? zoneValues,
) {
  // TODO(floitsch): it would be nice if we could get rid of this hack.
  // Change the static zoneOrDirectPrint function to go through zones
  // from now on.
  printToZone = _printToZone;

  Map<Object?, Object?>? valueMap;
  if (zoneValues == null) {
    valueMap = zone._map;
  } else {
    valueMap = HashMap<Object?, Object?>.from(zoneValues);
  }
  return _CustomZone(zone, specification, valueMap);
}

base class _RootZone extends Zone {
  const _RootZone() : super._();

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

  Zone? get parent => null;

  static const _rootDelegate = const ZoneDelegate._(_rootZone);

  ZoneDelegate get _delegate => _rootDelegate;
  // It's a lie, but the root zone functions never uses the parent delegate.
  ZoneDelegate get _parentDelegate => _rootDelegate;

  Zone get errorZone => this;

  // Zone interface.
  // All other zones have a different behavior, and so does calling
  // the root zone as a parent delegate.

  void runGuarded(void Function() callback) {
    try {
      if (identical(_rootZone, Zone._current)) {
        callback();
      } else {
        _rootRun(null, null, this, callback);
      }
    } catch (e, s) {
      _rootHandleError(e, s);
    }
  }

  void runUnaryGuarded<T>(void Function(T) callback, T argument) {
    try {
      if (identical(_rootZone, Zone._current)) {
        callback(argument);
      } else {
        _rootRunUnary(null, null, this, callback, argument);
      }
    } catch (e, s) {
      _rootHandleError(e, s);
    }
  }

  void runBinaryGuarded<T1, T2>(
    void Function(T1, T2) callback,
    T1 argument1,
    T2 argument2,
  ) {
    try {
      if (identical(_rootZone, Zone._current)) {
        callback(argument1, argument2);
      } else {
        _rootRunBinary(null, null, this, callback, argument1, argument2);
      }
    } catch (e, s) {
      _rootHandleError(e, s);
    }
  }

  R Function() bindCallback<R>(R Function() callback) {
    return () => _rootZone.run<R>(callback);
  }

  R Function(T) bindUnaryCallback<R, T>(R Function(T) callback) {
    return (argument) => _rootZone.runUnary<R, T>(callback, argument);
  }

  R Function(T1, T2) bindBinaryCallback<R, T1, T2>(
    R Function(T1, T2) callback,
  ) {
    return (argument1, argument2) =>
        _rootZone.runBinary<R, T1, T2>(callback, argument1, argument2);
  }

  void Function() bindCallbackGuarded(void Function() callback) {
    return () => _rootZone.runGuarded(callback);
  }

  void Function(T) bindUnaryCallbackGuarded<T>(void Function(T) callback) {
    return (argument) => _rootZone.runUnaryGuarded(callback, argument);
  }

  void Function(T1, T2) bindBinaryCallbackGuarded<T1, T2>(
    void Function(T1, T2) callback,
  ) {
    return (argument1, argument2) =>
        _rootZone.runBinaryGuarded(callback, argument1, argument2);
  }

  dynamic operator [](Object? key) => null;
  Map<Object?, Object?>? get _map => null;

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

  R run<R>(R Function() callback) {
    if (identical(Zone._current, _rootZone)) return callback();
    return _rootRun(null, null, this, callback);
  }

  @pragma('vm:invisible')
  R runUnary<R, T>(R Function(T) callback, T argument) {
    if (identical(Zone._current, _rootZone)) return callback(argument);
    return _rootRunUnary(null, null, this, callback, argument);
  }

  R runBinary<R, T1, T2>(
    R Function(T1, T2) callback,
    T1 argument1,
    T2 argument2,
  ) {
    if (identical(Zone._current, _rootZone)) {
      return callback(argument1, argument2);
    }
    return _rootRunBinary(null, null, this, callback, argument1, argument2);
  }

  R Function() registerCallback<R>(R Function() callback) => callback;

  R Function(T) registerUnaryCallback<R, T>(R Function(T) callback) => callback;

  ZoneBinaryCallback<R, T1, T2> registerBinaryCallback<R, T1, T2>(
    R Function(T1, T2) callback,
  ) => callback;

  AsyncError? errorCallback(Object error, StackTrace? stackTrace) => null;

  void scheduleMicrotask(void Function() callback) {
    _rootScheduleMicrotask(null, null, this, callback);
  }

  Timer createTimer(Duration duration, void Function() callback) {
    return Timer._createTimer(duration, callback);
  }

  Timer createPeriodicTimer(
    Duration duration,
    void Function(Timer timer) callback,
  ) {
    return Timer._createPeriodicTimer(duration, callback);
  }

  void print(String line) {
    printToConsole(line);
  }
}

const Zone _rootZone = _RootZone();

/// Runs [body] in its own zone.
///
/// Creates a new zone using [Zone.fork] based on [zoneSpecification] and
/// [zoneValues], then runs [body] in that zone and returns the result.
///
/// Example use:
/// ```dart
/// var secret = "arglebargle"; // Or a random generated string.
/// var result = runZoned(
///     () async {
///       await Future.delayed(Duration(seconds: 5), () {
///         print("${Zone.current[#_secret]} glop glyf");
///       });
///     },
///     zoneValues: {#_secret: secret},
///     zoneSpecification:
///         ZoneSpecification(print: (Zone self, parent, zone, String value) {
///       if (value.contains(Zone.current[#_secret] as String)) {
///         value = "--censored--";
///       }
///       parent.print(zone, value);
///     }));
/// secret = ""; // Erase the evidence.
/// await result; // Wait for asynchronous computation to complete.
/// ```
/// The new zone intercepts `print` and stores a value under the private
/// symbol `#_secret`. The secret is available from the new [Zone] object,
/// which is the [Zone.current] for the body,
/// and is also the first, `self`, parameter to the `print` handler function.
///
/// If the [ZoneSpecification.handleUncaughtError] is set, or the deprecated
/// [onError] callback is passed, the created zone will be an _error zone_.
/// Asynchronous errors in futures never cross zone boundaries between zones
/// with a different [Zone.errorZone].
/// A consequence of that behavior can be that a [Future] which completes as an
/// error in the created zone will seem to never complete when used from a zone
/// that belongs to a different error zone.
/// Multiple attempts to use the future in a zone where the error is
/// inaccessible will cause the error to be reported *again* in it's original
/// error zone.
///
/// See [runZonedGuarded] in place of using the deprecated [onError] argument.
/// If [onError] is provided this function also tries to catch and handle
/// synchronous errors from [body], but may throw an error anyway returning
/// `null` if the generic argument [R] is not nullable.
R runZoned<R>(
  R body(), {
  Map<Object?, Object?>? zoneValues,
  ZoneSpecification? zoneSpecification,
  @Deprecated("Use runZonedGuarded instead") Function? onError,
}) {
  if (onError != null) {
    // TODO: Remove this when code has been migrated off using [onError].
    if (onError is! void Function(Object, StackTrace)) {
      if (onError is void Function(Object)) {
        var originalOnError = onError;
        onError = (Object error, StackTrace stack) => originalOnError(error);
      } else {
        throw ArgumentError.value(
          onError,
          "onError",
          "Must be Function(Object) or Function(Object, StackTrace)",
        );
      }
    }
    return runZonedGuarded(
          body,
          onError,
          zoneSpecification: zoneSpecification,
          zoneValues: zoneValues,
        )
        as R;
  }
  return _runZoned<R>(body, zoneValues, zoneSpecification);
}

/// Runs [body] in its own error zone.
///
/// Creates a new zone using [Zone.fork] based on [zoneSpecification] and
/// [zoneValues], then runs [body] in that zone and returns the result.
///
/// The [onError] function is used *both* to handle asynchronous errors
/// by overriding [ZoneSpecification.handleUncaughtError] in [zoneSpecification],
/// if any, *and* to handle errors thrown synchronously by the call to [body].
///
/// If an error occurs synchronously in [body],
/// then throwing in the [onError] handler
/// makes the call to `runZonedGuarded` throw that error,
/// and otherwise the call to `runZonedGuarded` returns `null`.
///
/// The created zone will always be an _error zone_.
/// Asynchronous errors in futures never cross zone boundaries between zones
/// with a different [Zone.errorZone].
/// A consequence of that behavior can be that a [Future] which completes as an
/// error in the created zone will seem to never complete when used from a zone
/// that belongs to a different error zone.
/// Multiple attempts to use the future in a zone where the error is
/// inaccessible will cause the error to be reported *again* in it's original
/// error zone.
@Since("2.8")
R? runZonedGuarded<R>(
  R body(),
  void onError(Object error, StackTrace stack), {
  Map<Object?, Object?>? zoneValues,
  ZoneSpecification? zoneSpecification,
}) {
  Zone parentZone = Zone._current;
  HandleUncaughtErrorHandler errorHandler = (
    Zone self,
    ZoneDelegate parent,
    Zone zone,
    Object error,
    StackTrace stackTrace,
  ) {
    try {
      parentZone.runBinary(onError, error, stackTrace);
    } catch (e, s) {
      if (identical(e, error)) {
        parent.handleUncaughtError(zone, error, stackTrace);
      } else {
        parent.handleUncaughtError(zone, e, s);
      }
    }
  };
  if (zoneSpecification == null) {
    zoneSpecification = ZoneSpecification(handleUncaughtError: errorHandler);
  } else {
    zoneSpecification = ZoneSpecification.from(
      zoneSpecification,
      handleUncaughtError: errorHandler,
    );
  }
  try {
    return _runZoned<R>(body, zoneValues, zoneSpecification);
  } catch (error, stackTrace) {
    onError(error, stackTrace);
  }
  return null;
}

/// Runs [body] in a new zone based on [zoneValues] and [specification].
R _runZoned<R>(
  R body(),
  Map<Object?, Object?>? zoneValues,
  ZoneSpecification? specification,
) => Zone.current
    .fork(specification: specification, zoneValues: zoneValues)
    .run<R>(body);

/// Wraps [callback] to be run in [zone], and with errors reported in zone.
void Function() _guardCallbackInZone(Zone zone, void Function() callback) =>
    () {
      _runGuardedInZone<void>(zone, callback);
    };

/// Wraps [callback] to be run in [zone], and with errors reported in zone.
void Function(P) _guardUnaryCallbackInZone<P>(
  Zone zone,
  void Function(P) callback,
) => (P argument) {
  _runUnaryGuardedInZone<P>(zone, callback, argument);
};

/// Wraps [callback] to be run in [zone], and with errors reported in zone.
void Function(P1, P2) _guardBinaryCallbackInZone<P1, P2>(
  Zone zone,
  void Function(P1, P2) callback,
) => (P1 argument1, P2 argument2) {
  _runBinaryGuardedInZone<P1, P2>(zone, callback, argument1, argument2);
};

void _runGuardedInZone<R>(Zone zone, void Function() callback) {
  try {
    zone.run<void>(callback);
  } catch (e, s) {
    _handleErrorWithCallback(zone, e, s);
  }
}

void _runUnaryGuardedInZone<P>(
  Zone zone,
  void Function(P) callback,
  P argument,
) {
  try {
    zone.runUnary<void, P>(callback, argument);
  } catch (e, s) {
    _handleErrorWithCallback(zone, e, s);
  }
}

void _runBinaryGuardedInZone<P1, P2>(
  Zone zone,
  void Function(P1, P2) callback,
  P1 argument1,
  P2 argument2,
) {
  try {
    zone.runBinary<void, P1, P2>(callback, argument1, argument2);
  } catch (e, s) {
    _handleErrorWithCallback(zone, e, s);
  }
}

void _handleErrorWithCallback(Zone zone, Object error, StackTrace stackTrace) {
  var replacement = zone.errorCallback(error, stackTrace);
  if (replacement != null) {
    error = replacement.error;
    stackTrace = replacement.stackTrace;
  }
  zone.handleUncaughtError(error, stackTrace);
}
