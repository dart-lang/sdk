library catch_errors;

import 'dart:async';

<<<<<<< HEAD
Stream catchErrors(dynamic body()) {
=======
Stream catchErrors(void body()) {
>>>>>>> Migrated test block 170 to Dart 2.0.
  StreamController controller;

  bool onError(e, st) {
    controller.add(e);
    return true;
  }

  void onListen() {
    runZoned(body, onError: onError);
  }

  controller = new StreamController(onListen: onListen);
  return controller.stream;
}

runZonedScheduleMicrotask(body(),
    {void onScheduleMicrotask(void callback()), Function onError}) {
  if (onScheduleMicrotask == null) {
    return runZoned(body, onError: onError);
  }
  HandleUncaughtErrorHandler errorHandler;
  if (onError != null) {
    errorHandler = (Zone self, ZoneDelegate parent, Zone zone, error,
        StackTrace stackTrace) {
      try {
        return self.parent.runUnary(onError, error);
      } catch (e, s) {
        if (identical(e, error)) {
          return parent.handleUncaughtError(zone, error, stackTrace);
        } else {
          return parent.handleUncaughtError(zone, e, s);
        }
      }
    };
  }
  ScheduleMicrotaskHandler asyncHandler;
  if (onScheduleMicrotask != null) {
    asyncHandler = (Zone self, ZoneDelegate parent, Zone zone, f()) {
      self.parent.runUnary(onScheduleMicrotask, () => zone.runGuarded(f));
    };
  }
  ZoneSpecification specification = new ZoneSpecification(
      handleUncaughtError: errorHandler, scheduleMicrotask: asyncHandler);
  Zone zone = Zone.current.fork(specification: specification);
  if (onError != null) {
    return zone.runGuarded(body);
  } else {
    return zone.run(body);
  }
}
