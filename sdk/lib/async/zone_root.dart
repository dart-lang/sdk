// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Root-zone and its implementation of zone features.
part of 'dart:async';

const Zone _rootZone = Zone._root();
final ZoneDelegate _rootDelegate = ZoneDelegate._();

void _rootHandleUncaughtError(Object error, StackTrace stackTrace) {
  _schedulePriorityAsyncCallback(() {
    Error.throwWithStackTrace(error, stackTrace);
  });
}

void _rootScheduleMicrotask(Zone zone, void Function() callback) {
  if (!identical(_rootZone, zone)) {
    bool hasErrorHandler = zone._handleUncaughtErrorFunction != null;
    if (hasErrorHandler) {
      callback = zone.bindCallbackGuarded(callback);
    } else {
      callback = zone.bindCallback(callback);
    }
  }
  _scheduleAsyncCallback(callback);
}

Timer _rootCreateTimer(Zone zone, Duration duration, void Function() callback) {
  if (!identical(_rootZone, zone)) {
    callback = zone.bindCallback<void>(
      callback,
    ); // Should be `bindCallbackGuarded`.
  }
  return Timer._createTimer(duration, callback);
}

Timer _rootCreatePeriodicTimer(
  Zone zone,
  Duration duration,
  void callback(Timer timer),
) {
  if (!identical(_rootZone, zone)) {
    callback = zone.bindUnaryCallback<void, Timer>(
      callback,
    ); // Should be `bindUnaryCallbackGuarded`.
  }
  return Timer._createPeriodicTimer(duration, callback);
}

void _printToZone(String line) {
  var currentZone = Zone._current;
  currentZone._printZoned(currentZone, line);
}

Zone _rootFork(
  Zone zone,
  ZoneSpecification? specification,
  Map<Object?, Object?>? zoneValues,
) {
  _ZoneValues? values;
  if (zoneValues != null) {
    // Makes sure to own the map.
    values = _ZoneValues(HashMap<Object?, Object?>.of(zoneValues));
  }
  if (specification != null) {
    var run = specification.run;
    var runUnary = specification.runUnary;
    var runBinary = specification.runBinary;
    var registerCallback = specification.registerCallback;
    var registerUnaryCallback = specification.registerUnaryCallback;
    var registerBinaryCallback = specification.registerBinaryCallback;
    var errorCallback = specification.errorCallback;
    var scheduleMicrotask = specification.scheduleMicrotask;
    var createTimer = specification.createTimer;
    var createPeriodicTimer = specification.createPeriodicTimer;
    var print = specification.print;
    var fork = specification.fork;
    var handleUncaughtError = specification.handleUncaughtError;

    return Zone._withSpecification(
      zone,
      ZoneDelegate._(),
      run == null ? null : _ZoneRun(run),
      runUnary == null ? null : _ZoneRunUnary(runUnary),
      runBinary == null ? null : _ZoneRunBinary(runBinary),
      registerCallback == null ? null : _ZoneRegisterCallback(registerCallback),
      registerUnaryCallback == null
          ? null
          : _ZoneRegisterUnaryCallback(registerUnaryCallback),
      registerBinaryCallback == null
          ? null
          : _ZoneRegisterBinaryCallback(registerBinaryCallback),
      errorCallback == null ? null : _ZoneErrorCallback(errorCallback),
      scheduleMicrotask == null
          ? null
          : _ZoneScheduleMicrotask(scheduleMicrotask),
      createTimer == null ? null : _ZoneCreateTimer(createTimer),
      createPeriodicTimer == null
          ? null
          : _ZoneCreatePeriodicTimer(createPeriodicTimer),
      print == null ? null : _ZonePrint(print),
      fork == null ? null : _ZoneFork(fork),
      handleUncaughtError == null
          ? null
          : _ZoneHandleUncaughtError(handleUncaughtError),
      values,
    );
  }
  return Zone._withoutSpecification(zone, ZoneDelegate._(), values);
}
