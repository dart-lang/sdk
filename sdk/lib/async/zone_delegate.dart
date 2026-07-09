// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'dart:async';

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
abstract final class ZoneDelegate {
  // Invoke the [HandleUncaughtErrorHandler] of the zone with a current zone.
  void handleUncaughtError(Zone zone, Object error, StackTrace stackTrace);

  // Invokes the [RunHandler] of the zone with a current zone.
  R run<R>(Zone zone, R f());

  // Invokes the [RunUnaryHandler] of the zone with a current zone.
  R runUnary<R, T>(Zone zone, R f(T arg), T arg);

  // Invokes the [RunBinaryHandler] of the zone with a current zone.
  R runBinary<R, T1, T2>(Zone zone, R f(T1 arg1, T2 arg2), T1 arg1, T2 arg2);

  // Invokes the [RegisterCallbackHandler] of the zone with a current zone.
  ZoneCallback<R> registerCallback<R>(Zone zone, R f());

  // Invokes the [RegisterUnaryHandler] of the zone with a current zone.
  ZoneUnaryCallback<R, T> registerUnaryCallback<R, T>(Zone zone, R f(T arg));

  // Invokes the [RegisterBinaryHandler] of the zone with a current zone.
  ZoneBinaryCallback<R, T1, T2> registerBinaryCallback<R, T1, T2>(
    Zone zone,
    R f(T1 arg1, T2 arg2),
  );

  // Invokes the [ErrorCallbackHandler] of the zone with a current zone.
  AsyncError? errorCallback(Zone zone, Object error, StackTrace? stackTrace);

  // Invokes the [ScheduleMicrotaskHandler] of the zone with a current zone.
  void scheduleMicrotask(Zone zone, void f());

  // Invokes the [CreateTimerHandler] of the zone with a current zone.
  Timer createTimer(Zone zone, Duration duration, void f());

  // Invokes the [CreatePeriodicTimerHandler] of the zone with a current zone.
  Timer createPeriodicTimer(Zone zone, Duration period, void f(Timer timer));

  // Invokes the [PrintHandler] of the zone with a current zone.
  void print(Zone zone, String line);

  // Invokes the [ForkHandler] of the zone with a current zone.
  Zone fork(Zone zone, ZoneSpecification? specification, Map? zoneValues);
}

base class _ZoneDelegate implements ZoneDelegate {
  final _Zone _delegationTarget;

  _ZoneDelegate(this._delegationTarget);

  void handleUncaughtError(Zone zone, Object error, StackTrace stackTrace) {
    _delegationTarget._processUncaughtError(zone, error, stackTrace);
  }

  R run<R>(Zone zone, R f()) {
    var implementation = _delegationTarget._run;
    var implZone = implementation.zone;
    return implementation.function(implZone, implZone._parentDelegate, zone, f);
  }

  R runUnary<R, T>(Zone zone, R f(T arg), T arg) {
    var implementation = _delegationTarget._runUnary;
    var implZone = implementation.zone;
    return implementation.function(
      implZone,
      implZone._parentDelegate,
      zone,
      f,
      arg,
    );
  }

  R runBinary<R, T1, T2>(Zone zone, R f(T1 arg1, T2 arg2), T1 arg1, T2 arg2) {
    var implementation = _delegationTarget._runBinary;
    var implZone = implementation.zone;
    return implementation.function(
      implZone,
      implZone._parentDelegate,
      zone,
      f,
      arg1,
      arg2,
    );
  }

  ZoneCallback<R> registerCallback<R>(Zone zone, R f()) {
    var implementation = _delegationTarget._registerCallback;
    var implZone = implementation.zone;
    return implementation.function(implZone, implZone._parentDelegate, zone, f);
  }

  ZoneUnaryCallback<R, T> registerUnaryCallback<R, T>(Zone zone, R f(T arg)) {
    var implementation = _delegationTarget._registerUnaryCallback;
    var implZone = implementation.zone;
    return implementation.function(implZone, implZone._parentDelegate, zone, f);
  }

  ZoneBinaryCallback<R, T1, T2> registerBinaryCallback<R, T1, T2>(
    Zone zone,
    R f(T1 arg1, T2 arg2),
  ) {
    var implementation = _delegationTarget._registerBinaryCallback;
    var implZone = implementation.zone;
    return implementation.function(implZone, implZone._parentDelegate, zone, f);
  }

  AsyncError? errorCallback(Zone zone, Object error, StackTrace? stackTrace) {
    var implementation = _delegationTarget._errorCallback;
    var implZone = implementation.zone;
    if (identical(implZone, _rootZone)) return null;
    return implementation.function(
      implZone,
      implZone._parentDelegate,
      zone,
      error,
      stackTrace,
    );
  }

  void scheduleMicrotask(Zone zone, f()) {
    var implementation = _delegationTarget._scheduleMicrotask;
    var implZone = implementation.zone;
    implementation.function(implZone, implZone._parentDelegate, zone, f);
  }

  Timer createTimer(Zone zone, Duration duration, void f()) {
    var implementation = _delegationTarget._createTimer;
    var implZone = implementation.zone;
    return implementation.function(
      implZone,
      implZone._parentDelegate,
      zone,
      duration,
      f,
    );
  }

  Timer createPeriodicTimer(Zone zone, Duration period, void f(Timer timer)) {
    var implementation = _delegationTarget._createPeriodicTimer;
    var implZone = implementation.zone;
    return implementation.function(
      implZone,
      implZone._parentDelegate,
      zone,
      period,
      f,
    );
  }

  void print(Zone zone, String line) {
    var implementation = _delegationTarget._print;
    var implZone = implementation.zone;
    implementation.function(implZone, implZone._parentDelegate, zone, line);
  }

  Zone fork(
    Zone zone,
    ZoneSpecification? specification,
    Map<Object?, Object?>? zoneValues,
  ) {
    var implementation = _delegationTarget._fork;
    var implZone = implementation.zone;
    return implementation.function(
      implZone,
      implZone._parentDelegate,
      zone,
      specification,
      zoneValues,
    );
  }
}
