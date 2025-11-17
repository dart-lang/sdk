// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'dart:async';

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
abstract final class ZoneSpecification {
  /// Creates a specification with the provided handlers.
  ///
  /// If the [handleUncaughtError] is provided, the new zone will be a new
  /// "error zone" which will prevent errors from flowing into other
  /// error zones (see [Zone.errorZone], [Zone.inSameErrorZone]).
  const factory ZoneSpecification({
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
  }) = _ZoneSpecification;

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
  HandleUncaughtErrorHandler? get handleUncaughtError;

  /// A custom [Zone.run] implementation for a new zone.
  RunHandler? get run;

  /// A custom [Zone.runUnary] implementation for a new zone.
  RunUnaryHandler? get runUnary;

  /// A custom [Zone.runBinary] implementation for a new zone.
  RunBinaryHandler? get runBinary;

  /// A custom [Zone.registerCallback] implementation for a new zone.
  RegisterCallbackHandler? get registerCallback;

  /// A custom [Zone.registerUnaryCallback] implementation for a new zone.
  RegisterUnaryCallbackHandler? get registerUnaryCallback;

  /// A custom [Zone.registerBinaryCallback] implementation for a new zone.
  RegisterBinaryCallbackHandler? get registerBinaryCallback;

  /// A custom [Zone.errorCallback] implementation for a new zone.
  ErrorCallbackHandler? get errorCallback;

  /// A custom [Zone.scheduleMicrotask] implementation for a new zone.
  ScheduleMicrotaskHandler? get scheduleMicrotask;

  /// A custom [Zone.createTimer] implementation for a new zone.
  CreateTimerHandler? get createTimer;

  /// A custom [Zone.createPeriodicTimer] implementation for a new zone.
  CreatePeriodicTimerHandler? get createPeriodicTimer;

  /// A custom [Zone.print] implementation for a new zone.
  PrintHandler? get print;

  /// A custom [Zone.handleUncaughtError] implementation for a new zone.
  ForkHandler? get fork;
}

/// Internal [ZoneSpecification] class.
///
/// The implementation wants to rely on the fact that the getters cannot change
/// dynamically. We thus require users to go through the redirecting
/// [ZoneSpecification] constructor which instantiates this class.
base class _ZoneSpecification implements ZoneSpecification {
  const _ZoneSpecification({
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

  final HandleUncaughtErrorHandler? handleUncaughtError;
  final RunHandler? run;
  final RunUnaryHandler? runUnary;
  final RunBinaryHandler? runBinary;
  final RegisterCallbackHandler? registerCallback;
  final RegisterUnaryCallbackHandler? registerUnaryCallback;
  final RegisterBinaryCallbackHandler? registerBinaryCallback;
  final ErrorCallbackHandler? errorCallback;
  final ScheduleMicrotaskHandler? scheduleMicrotask;
  final CreateTimerHandler? createTimer;
  final CreatePeriodicTimerHandler? createPeriodicTimer;
  final PrintHandler? print;
  final ForkHandler? fork;
}

// Names and documentation for the functions of a ZoneSpecification.

/// The type of a custom [Zone.handleUncaughtError] implementation function.
///
/// A function used as [ZoneSpecification.handleUncaughtError]
/// to specialize the behavior of a new zone.
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
/// A function used as [ZoneSpecification.run]
/// to specialize the behavior of a new zone.
///
/// Receives the [Zone] that the handler was registered on as [self],
/// a delegate forwarding to the handlers of [self]'s parent zone as [parent],
/// and the current zone where the error was uncaught as [zone],
/// which will have [self] as a parent zone.
///
/// The function [f] is the function which was passed to the
/// [Zone.run] of [zone].
///
/// The default behavior of [Zone.run] is
/// to call [f] in the current zone, [zone].
/// A custom handler can do things before, after or instead of
/// calling [f].
///
/// The function must only access zone-related functionality through
/// [self], [parent] or [zone].
/// It should not depend on the current zone ([Zone.current]).
typedef RunHandler =
    R Function<R>(Zone self, ZoneDelegate parent, Zone zone, R Function() f);

/// The type of a custom [Zone.runUnary] implementation function.
///
/// A function used as [ZoneSpecification.runUnary]
/// to specialize the behavior of a new zone.
///
/// Receives the [Zone] that the handler was registered on as [self],
/// a delegate forwarding to the handlers of [self]'s parent zone as [parent],
/// and the current zone where the error was uncaught as [zone],
/// which will have [self] as a parent zone.
///
/// The function [f] and value [arg] are the function and argument
/// which was passed to the [Zone.runUnary] of [zone].
///
/// The default behavior of [Zone.runUnary] is
/// to call [f] with argument [arg] in the current zone, [zone].
/// A custom handler can do things before, after or instead of
/// calling [f].
///
/// The function must only access zone-related functionality through
/// [self], [parent] or [zone].
/// It should not depend on the current zone ([Zone.current]).
typedef RunUnaryHandler =
    R Function<R, T>(
      Zone self,
      ZoneDelegate parent,
      Zone zone,
      R Function(T arg) f,
      T arg,
    );

/// The type of a custom [Zone.runBinary] implementation function.
///
/// A function used as [ZoneSpecification.runBinary]
/// to specialize the behavior of a new zone.
///
/// Receives the [Zone] that the handler was registered on as [self],
/// a delegate forwarding to the handlers of [self]'s parent zone as [parent],
/// and the current zone where the error was uncaught as [zone],
/// which will have [self] as a parent zone.
///
/// The function [f] and values [arg1] and [arg2] are the function and arguments
/// which was passed to the [Zone.runBinary] of [zone].
///
/// The default behavior of [Zone.runUnary] is
/// to call [f] with arguments [arg1] and [arg2] in the current zone, [zone].
/// A custom handler can do things before, after or instead of
/// calling [f].
///
/// The function must only access zone-related functionality through
/// [self], [parent] or [zone].
/// It should not depend on the current zone ([Zone.current]).
typedef RunBinaryHandler =
    R Function<R, T1, T2>(
      Zone self,
      ZoneDelegate parent,
      Zone zone,
      R Function(T1 arg1, T2 arg2) f,
      T1 arg1,
      T2 arg2,
    );

/// The type of a custom [Zone.registerCallback] implementation function.
///
/// A function used as [ZoneSpecification.registerCallback]
/// to specialize the behavior of a new zone.
///
/// Receives the [Zone] that the handler was registered on as [self],
/// a delegate forwarding to the handlers of [self]'s parent zone as [parent],
/// and the current zone where the error was uncaught as [zone],
/// which will have [self] as a parent zone.
///
/// The function [f] is the function which was passed to the
/// [Zone.registerCallback] of [zone].
///
/// The handler should return either the function [f]
/// or another function replacing [f],
/// typically by wrapping [f] in a function
/// which does something extra before and after invoking [f]
///
/// The function must only access zone-related functionality through
/// [self], [parent] or [zone].
/// It should not depend on the current zone ([Zone.current]).
typedef RegisterCallbackHandler =
    ZoneCallback<R> Function<R>(
      Zone self,
      ZoneDelegate parent,
      Zone zone,
      R Function() f,
    );

/// The type of a custom [Zone.registerUnaryCallback] implementation function.
///
/// A function used as [ZoneSpecification.registerUnaryCallback]
/// to specialize the behavior of a new zone.
///
/// Receives the [Zone] that the handler was registered on as [self],
/// a delegate forwarding to the handlers of [self]'s parent zone as [parent],
/// and the current zone where the error was uncaught as [zone],
/// which will have [self] as a parent zone.
///
/// The function [f] is the function which was passed to the
/// which was passed to the [Zone.registerUnaryCallback] of [zone].
///
/// The handler should return either the function [f]
/// or another function replacing [f],
/// typically by wrapping [f] in a function
/// which does something extra before and after invoking [f]
///
/// The function must only access zone-related functionality through
/// [self], [parent] or [zone].
/// It should not depend on the current zone ([Zone.current]).
typedef RegisterUnaryCallbackHandler =
    ZoneUnaryCallback<R, T> Function<R, T>(
      Zone self,
      ZoneDelegate parent,
      Zone zone,
      R Function(T arg) f,
    );

/// The type of a custom [Zone.registerBinaryCallback] implementation function.
///
/// A function used as [ZoneSpecification.registerBinaryCallback]
/// to specialize the behavior of a new zone.
///
/// Receives the [Zone] that the handler was registered on as [self],
/// a delegate forwarding to the handlers of [self]'s parent zone as [parent],
/// and the current zone where the error was uncaught as [zone],
/// which will have [self] as a parent zone.
///
/// The function [f] is the function which was passed to the
/// which was passed to the [Zone.registerBinaryCallback] of [zone].
///
/// The handler should return either the function [f]
/// or another function replacing [f],
/// typically by wrapping [f] in a function
/// which does something extra before and after invoking [f]
typedef RegisterBinaryCallbackHandler =
    ZoneBinaryCallback<R, T1, T2> Function<R, T1, T2>(
      Zone self,
      ZoneDelegate parent,
      Zone zone,
      R Function(T1 arg1, T2 arg2) f,
    );

/// The type of a custom [Zone.errorCallback] implementation function.
///
/// A function used as [ZoneSpecification.errorCallback]
/// to specialize the behavior of a new zone.
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
///   return parent.errorCallback(zone, error, stackTrace) ??
///       AsyncError(error, stackTrace);
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
/// A function used as [ZoneSpecification.scheduleMicrotask]
/// to specialize the behavior of a new zone.
///
/// Receives the [Zone] that the handler was registered on as [self],
/// a delegate forwarding to the handlers of [self]'s parent zone as [parent],
/// and the current zone where the error was uncaught as [zone],
/// which will have [self] as a parent zone.
///
/// The function [f] is the function which was
/// passed to [Zone.scheduleMicrotask] of [zone].
///
/// The custom handler can choose to replace the function [f]
/// with one that does something before, after or instead of calling [f],
/// and then call `parent.scheduleMicrotask(zone, replacement)`.
/// or it can implement its own microtask scheduling queue, which typically
/// still depends on `parent.scheduleMicrotask` to as a way to get started.
///
/// The function must only access zone-related functionality through
/// [self], [parent] or [zone].
/// It should not depend on the current zone ([Zone.current]).
typedef ScheduleMicrotaskHandler =
    void Function(Zone self, ZoneDelegate parent, Zone zone, void Function() f);

/// The type of a custom [Zone.createTimer] implementation function.
///
/// A function used as [ZoneSpecification.createTimer]
/// to specialize the behavior of a new zone.
///
/// Receives the [Zone] that the handler was registered on as [self],
/// a delegate forwarding to the handlers of [self]'s parent zone as [parent],
/// and the current zone where the error was uncaught as [zone],
/// which will have [self] as a parent zone.
///
/// The callback function [f] and [duration] are the ones which were
/// passed to [Zone.createTimer] of [zone]
/// (possibly through the [Timer] constructor).
///
/// The custom handler can choose to replace the function [f]
/// with one that does something before, after or instead of calling [f],
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
      void Function() f,
    );

/// The type of a custom [Zone.createPeriodicTimer] implementation function.
///
/// A function used as [ZoneSpecification.createPeriodicTimer]
/// to specialize the behavior of a new zone.
///
/// Receives the [Zone] that the handler was registered on as [self],
/// a delegate forwarding to the handlers of [self]'s parent zone as [parent],
/// and the current zone where the error was uncaught as [zone],
/// which will have [self] as a parent zone.
///
/// The callback function [f] and [period] are the ones which were
/// passed to [Zone.createPeriodicTimer] of [zone]
/// (possibly through the [Timer.periodic] constructor).
///
/// The custom handler can choose to replace the function [f]
/// with one that does something before, after or instead of calling [f],
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
      void Function(Timer timer) f,
    );

/// The type of a custom [Zone.print] implementation function.
///
/// A function used as [ZoneSpecification.print]
/// to specialize the behavior of a new zone.
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
/// A function used as [ZoneSpecification.fork]
/// to specialize the behavior of a new zone.
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
