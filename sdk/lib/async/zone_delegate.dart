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
final class ZoneDelegate {
  // TODO: Make this an extension type on `Zone` if ever possible,
  // to avoid the cyclic dependencies.

  ZoneDelegate._();

  /// The zone this delegate delegates to.
  ///
  /// Is mutable to allow a zone to refer to its delegate, and a delegate
  /// to refer back to its zone. Is overwritten when the zone has been created.
  /// The root zone, which is `const`, has its delegate stored outside
  /// the zone.
  ///
  /// Uses root zone as dummy value to avoid being nullable.
  Zone _zone = _rootZone;

  // Invoke the [HandleUncaughtErrorHandler] of the zone with a current zone.
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  void handleUncaughtError(Zone zone, Object error, StackTrace stackTrace) {
    _zone._handleUncaughtErrorZoned(zone, error, stackTrace);
  }

  // Invokes the [RunHandler] of the zone with a current zone.
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  R run<R>(Zone zone, R Function() action) => _zone._runZoned<R>(zone, action);

  // Invokes the [RunUnaryHandler] of the zone with a current zone.
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  R runUnary<R, T>(Zone zone, R Function(T) action, T argument) =>
      _zone._runUnaryZoned<R, T>(zone, action, argument);

  // Invokes the [RunBinaryHandler] of the zone with a current zone.
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  R runBinary<R, T1, T2>(
    Zone zone,
    R Function(T1, T2) action,
    T1 argument1,
    T2 argument2,
  ) => _zone._runBinaryZoned<R, T1, T2>(zone, action, argument1, argument2);

  // Invokes the [RegisterCallbackHandler] of the zone with a current zone.
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  ZoneCallback<R> registerCallback<R>(Zone zone, R Function() callback) =>
      _zone._registerCallbackZoned<R>(zone, callback);

  // Invokes the [RegisterUnaryHandler] of the zone with a current zone.
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  ZoneUnaryCallback<R, T> registerUnaryCallback<R, T>(
    Zone zone,
    R Function(T) callback,
  ) => _zone._registerUnaryCallbackZoned<R, T>(zone, callback);

  // Invokes the [RegisterBinaryHandler] of the zone with a current zone.
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  ZoneBinaryCallback<R, T1, T2> registerBinaryCallback<R, T1, T2>(
    Zone zone,
    R Function(T1, T2) callback,
  ) => _zone._registerBinaryCallbackZoned<R, T1, T2>(zone, callback);

  // Invokes the [ErrorCallbackHandler] of the zone with a current zone.
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  AsyncError? errorCallback(Zone zone, Object error, StackTrace? stackTrace) =>
      _zone._errorCallbackZoned(zone, error, stackTrace);

  // Invokes the [ScheduleMicrotaskHandler] of the zone with a current zone.
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  void scheduleMicrotask(Zone zone, void Function() callback) {
    _zone._scheduleMicrotaskZoned(zone, callback);
  }

  // Invokes the [CreateTimerHandler] of the zone with a current zone.
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  Timer createTimer(Zone zone, Duration duration, void Function() callback) =>
      _zone._createTimerZoned(zone, duration, callback);

  // Invokes the [CreatePeriodicTimerHandler] of the zone with a current zone.
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  Timer createPeriodicTimer(
    Zone zone,
    Duration period,
    void Function(Timer) callback,
  ) => _zone._createPeriodicTimerZoned(zone, period, callback);

  // Invokes the [PrintHandler] of the zone with a current zone.
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  void print(Zone zone, String line) {
    _zone._printZoned(zone, line);
  }

  // Invokes the [ForkHandler] of the zone with a current zone.
  @pragma('dart2js:prefer-inline')
  @pragma('dart2wasm:prefer-inline')
  @pragma('vm:prefer-inline')
  Zone fork(Zone zone, ZoneSpecification? specification, Map? zoneValues) =>
      _zone._forkZoned(zone, specification, zoneValues);
}
