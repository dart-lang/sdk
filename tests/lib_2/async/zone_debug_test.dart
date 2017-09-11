// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:async';

/**
 * We represent the current stack trace by an integer. From time to time we
 * increment the variable. This corresponds to a new stack trace.
 */
int stackTrace = 0;
List restoredStackTrace = [];

List events = [];

dynamic Function() debugZoneRegisterCallback(
    Zone self, ZoneDelegate parent, Zone origin, f()) {
  List savedTrace = [stackTrace]..addAll(restoredStackTrace);
  return parent.registerCallback(origin, () {
    restoredStackTrace = savedTrace;
    return f();
  });
}

dynamic Function(dynamic) debugZoneRegisterUnaryCallback(
    Zone self, ZoneDelegate parent, Zone origin, f(arg)) {
  List savedTrace = [stackTrace]..addAll(restoredStackTrace);
  return parent.registerUnaryCallback(origin, (arg) {
    restoredStackTrace = savedTrace;
    return f(arg);
  });
}

debugZoneRun(Zone self, ZoneDelegate parent, Zone origin, f()) {
  stackTrace++;
  restoredStackTrace = [];
  return parent.run(origin, f);
}

debugZoneRunUnary(Zone self, ZoneDelegate parent, Zone origin, f(arg), arg) {
  stackTrace++;
  restoredStackTrace = [];
  return parent.runUnary(origin, f, arg);
}

List expectedDebugTrace;

debugUncaughtHandler(
    Zone self, ZoneDelegate parent, Zone origin, error, StackTrace stackTrace) {
  events.add("handling uncaught error $error");
  Expect.listEquals(expectedDebugTrace, restoredStackTrace);
  // Suppress the error and don't propagate to parent.
}

const DEBUG_SPECIFICATION = const ZoneSpecification(
    registerCallback: debugZoneRegisterCallback,
    registerUnaryCallback: debugZoneRegisterUnaryCallback,
    run: debugZoneRun,
    runUnary: debugZoneRunUnary,
    handleUncaughtError: debugUncaughtHandler);

main() {
  Completer done = new Completer();

  // runGuarded calls run, captures the synchronous error (if any) and
  // gives that one to handleUncaughtError.

  Expect.identical(Zone.ROOT, Zone.current);
  Zone forked;
  forked = Zone.current.fork(specification: DEBUG_SPECIFICATION);

  asyncStart();

  int openTests = 0;

  openTests++;
  forked.run(() {
    int forkTrace = stackTrace;
    scheduleMicrotask(() {
      int scheduleMicrotaskTrace = stackTrace;
      scheduleMicrotask(() {
        expectedDebugTrace = [scheduleMicrotaskTrace, forkTrace];
        openTests--;
        if (openTests == 0) {
          done.complete();
        }
        throw "foo";
      });
      expectedDebugTrace = [forkTrace];
      throw "bar";
    });
  });

  Expect.listEquals([], restoredStackTrace);
  Zone forked2 = forked.fork();
  Zone forked3 = forked2.fork();
  int fork2Trace;
  int fork3Trace;
  var f2;
  var globalTrace = stackTrace;
  var f = forked3.bindCallback<dynamic>(() {
    Expect.identical(forked3, Zone.current);
    fork2Trace = stackTrace;
    f2 = forked2.bindCallback<dynamic>(() {
      Expect.identical(forked2, Zone.current);
      Expect.listEquals([fork2Trace, globalTrace], restoredStackTrace);
      fork3Trace = stackTrace;
      openTests--;
      if (openTests == 0) {
        done.complete();
      }
      scheduleMicrotask(() {
        expectedDebugTrace = [fork3Trace, fork2Trace, globalTrace];
        throw "gee";
      });
    }, runGuarded: false);
  }, runGuarded: false);
  openTests++;
  f();
  f2();

  done.future.whenComplete(() {
    // We don't really care for the order.
    events.sort();
    Expect.listEquals([
      "handling uncaught error bar",
      "handling uncaught error foo",
      "handling uncaught error gee"
    ], events);
    asyncEnd();
  });
}
