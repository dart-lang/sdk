// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Root-zone and its implementation of zone features.
part of 'dart:async';

const _Zone _rootZone = _RootZone();

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
  _schedulePriorityAsyncCallback(() {
    Error.throwWithStackTrace(error, stackTrace);
  });
}

R _rootRun<R>(Zone? self, ZoneDelegate? parent, Zone zone, R f()) {
  if (identical(Zone._current, zone)) return f();

  if (zone is! _Zone) {
    throw ArgumentError.value(zone, "zone", "Can only run in platform zones");
  }

  _Zone old = Zone._enter(zone);
  try {
    return f();
  } finally {
    Zone._leave(old);
  }
}

R _rootRunUnary<R, T>(
  Zone? self,
  ZoneDelegate? parent,
  Zone zone,
  R f(T arg),
  T arg,
) {
  if (identical(Zone._current, zone)) return f(arg);

  if (zone is! _Zone) {
    throw ArgumentError.value(zone, "zone", "Can only run in platform zones");
  }

  _Zone old = Zone._enter(zone);
  try {
    return f(arg);
  } finally {
    Zone._leave(old);
  }
}

R _rootRunBinary<R, T1, T2>(
  Zone? self,
  ZoneDelegate? parent,
  Zone zone,
  R f(T1 arg1, T2 arg2),
  T1 arg1,
  T2 arg2,
) {
  if (identical(Zone._current, zone)) return f(arg1, arg2);

  if (zone is! _Zone) {
    throw ArgumentError.value(zone, "zone", "Can only run in platform zones");
  }

  _Zone old = Zone._enter(zone);
  try {
    return f(arg1, arg2);
  } finally {
    Zone._leave(old);
  }
}

ZoneCallback<R> _rootRegisterCallback<R>(
  Zone self,
  ZoneDelegate parent,
  Zone zone,
  R f(),
) {
  return f;
}

ZoneUnaryCallback<R, T> _rootRegisterUnaryCallback<R, T>(
  Zone self,
  ZoneDelegate parent,
  Zone zone,
  R f(T arg),
) {
  return f;
}

ZoneBinaryCallback<R, T1, T2> _rootRegisterBinaryCallback<R, T1, T2>(
  Zone self,
  ZoneDelegate parent,
  Zone zone,
  R f(T1 arg1, T2 arg2),
) {
  return f;
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
  void f(),
) {
  if (!identical(_rootZone, zone)) {
    bool hasErrorHandler = !_rootZone.inSameErrorZone(zone);
    if (hasErrorHandler) {
      f = zone.bindCallbackGuarded(f);
    } else {
      f = zone.bindCallback(f);
    }
  }
  _scheduleAsyncCallback(f);
}

Timer _rootCreateTimer(
  Zone self,
  ZoneDelegate parent,
  Zone zone,
  Duration duration,
  void Function() callback,
) {
  if (!identical(_rootZone, zone)) {
    callback = zone.bindCallback(callback);
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
    callback = zone.bindUnaryCallback<void, Timer>(callback);
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
  if (zone is! _Zone) {
    throw ArgumentError.value(zone, "zone", "Can only fork a platform zone");
  }
  // TODO(floitsch): it would be nice if we could get rid of this hack.
  // Change the static zoneOrDirectPrint function to go through zones
  // from now on.
  printToZone = _printToZone;

  if (specification == null) {
    specification = const ZoneSpecification();
  } else if (specification is! _ZoneSpecification) {
    specification = ZoneSpecification.from(specification);
  }
  Map<Object?, Object?> valueMap;
  if (zoneValues == null) {
    valueMap = zone._map;
  } else {
    valueMap = HashMap<Object?, Object?>.from(zoneValues);
  }
  if (specification == null)
    throw "unreachable"; // TODO(lrn): Remove when type promotion works.
  return _CustomZone(zone, specification, valueMap);
}
