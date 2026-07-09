// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library catch_errors;

import 'dart:async';

/// Runs [body] inside [runZonedGuarded].
///
/// Runs [body] when the returned stream is listened to.
/// Emits all errors, synchronous and asynchronous,
/// as events on the returned stream.
///
/// **Notice**: The stream never closes. The caller should stop
/// listening when they're convinced there will be no later error events.
Stream<Object> catchErrors(void Function() body) {
  var controller = StreamController<Object>();
  controller.onListen = () {
    runZonedGuarded(body, (e, s) {
      controller.add(e);
    });
  };
  return controller.stream;
}

/// Runs [body] inside [runZoneGuarded], [Zone.runGuarded] or [Zone.run].
///
/// If [onScheduleMicrotask] is provided, a custom zone is created
/// with a [Zone.scheduleMicrotask] which calls [onScheduleMicrotask] with
/// the provided callback.
///
/// If [onError] is provided, it's used as argument to [runZonedGuarded]
/// or as error handler of the custom zone, and the `body` is then run
/// using `runGuarded`.
R? runZonedScheduleMicrotask<R>(
  R body(), {
  void Function(void Function() callback)? onScheduleMicrotask,
  Function? onError,
}) {
  if (onScheduleMicrotask == null) {
    return runZonedGuarded(body, onError as void Function(Object, StackTrace));
  }
  HandleUncaughtErrorHandler? errorHandler;
  if (onError != null) {
    errorHandler =
        (
          Zone self,
          ZoneDelegate parent,
          Zone zone,
          error,
          StackTrace stackTrace,
        ) {
          try {
            return self.parent!.runUnary(
              onError as void Function(Object),
              error,
            );
          } catch (e, s) {
            if (identical(e, error)) {
              return parent.handleUncaughtError(zone, error, stackTrace);
            } else {
              return parent.handleUncaughtError(zone, e, s);
            }
          }
        };
  }
  ScheduleMicrotaskHandler? asyncHandler;
  if (onScheduleMicrotask != null) {
    void handle(Zone self, ZoneDelegate parent, Zone zone, Function() f) {
      self.parent!.runUnary(onScheduleMicrotask, () => zone.runGuarded(f));
    }

    asyncHandler = handle;
  }
  ZoneSpecification specification = ZoneSpecification(
    handleUncaughtError: errorHandler,
    scheduleMicrotask: asyncHandler,
  );
  if (onError != null) {
    return runZoned<R>(body, zoneSpecification: specification);
  } else {
    Zone zone = Zone.current.fork(specification: specification);
    return zone.run<R>(body);
  }
}
